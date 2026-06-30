import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { dialogueSystem } from "../core/DialogueSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import { exerciseVariantSystem } from "../core/ExerciseVariantSystem";
import type { FeedbackMessage } from "../core/FeedbackSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { missionEngine } from "../core/MissionEngine";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import {
  cardinalLabels,
  compassLabels,
  DIRECTION_VECTORS,
  type Cardinal,
} from "../data/atlas";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type AtlasMode = "bearings" | "coordinates" | "scale" | "triangulation";

const PALETTE = "academy" as const;
const GRID = { x0: 96, y0: 214, cellW: 64, cellH: 48 };

/** Right-panel compass: screen offsets per direction around the centre. */
const COMPASS: Array<{ dir: Cardinal; dx: number; dy: number }> = [
  { dir: "NW", dx: -78, dy: -38 }, { dir: "N", dx: 0, dy: -38 }, { dir: "NE", dx: 78, dy: -38 },
  { dir: "W", dx: -78, dy: 0 }, { dir: "E", dx: 78, dy: 0 },
  { dir: "SW", dx: -78, dy: 38 }, { dir: "S", dx: 0, dy: 38 }, { dir: "SE", dx: 78, dy: 38 },
];

export class AtlasScene extends Phaser.Scene {
  private variant = exerciseVariantSystem.getAtlasVariant();
  private bearings = this.variant.bearings;
  private coordinates = this.variant.coordinates;
  private scaleProblem = this.variant.scale;
  private source = this.variant.source;
  private mode: AtlasMode = "bearings";
  private readBearingIds = new Set<string>();
  private plottedStationIds = new Set<string>();
  private selectedBearingId = this.variant.bearings[0].id;
  private mapLayer?: Phaser.GameObjects.Container;
  private panelLayer?: Phaser.GameObjects.Container;
  private objectiveText?: Phaser.GameObjects.Text;
  private feedbackText?: Phaser.GameObjects.Text;

  constructor() {
    super("AtlasScene");
  }

  preload(): void {
    queueSceneAssets(this, "academy", "story");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.restoreFlags();
    this.mode = this.resolveMode();
    this.drawAtlas();
    this.createHud();
    this.refreshScene();

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    if (!saveSystem.data.flags.mission5IntroSeen) {
      saveSystem.setFlag("mission5IntroSeen", true);
      new DialogueBox(this, dialogueSystem.format("mission5Opening"), () => {
        feedbackSystem.publish("Tre stazioni, tre direzioni: dove si incrociano c'è la sorgente.", "info");
      });
    }
  }

  private restoreFlags(): void {
    if (saveSystem.data.flags.atlasBearingsRead) {
      this.bearings.forEach((bearing) => this.readBearingIds.add(bearing.id));
    }
    if (saveSystem.data.flags.atlasCoordinatesPlotted) {
      this.coordinates.forEach((coordinate) => this.plottedStationIds.add(coordinate.id));
    }
  }

  private resolveMode(): AtlasMode {
    if (!saveSystem.data.flags.atlasBearingsRead) {
      return "bearings";
    }
    if (!saveSystem.data.flags.atlasCoordinatesPlotted) {
      return "coordinates";
    }
    if (!saveSystem.data.flags.atlasScaleSolved) {
      return "scale";
    }
    return "triangulation";
  }

  private drawAtlas(): void {
    VisualKit.applyCinematicGrade(this, PALETTE);
    SceneChrome.drawTwoColumnMissionChrome(
      this,
      PALETTE,
      "L'Atlante Perduto",
      "Triangola l'origine del segnale: rilevamenti, coordinate, scala e incrocio.",
      "Tavolo cartografico",
      "story-academy-hub-bg",
    );
  }

  private createHud(): void {
    SceneChrome.consolePanel(this, 820, 130, 420, 132, "Sistema cartografico", PALETTE);
    this.objectiveText = this.add.text(842, 184, "", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 388 },
      lineSpacing: 4,
    });
    this.feedbackText = SceneChrome.bottomLog(this, SceneChrome.twoColumnLayout.bottom, "");

    new Button(this, 1110, 58, "Diario", () => this.scene.start("JournalScene"), {
      width: 150, height: 44, fontSize: 16, fill: 0x142736,
    });
    new Button(this, 930, 58, "Storia", () => this.scene.start("CampaignScene"), {
      width: 132, height: 44, fontSize: 16, fill: 0x142736,
    });
  }

  // --- Grid helpers ---------------------------------------------------------

  private cellCenter(x: number, y: number): { x: number; y: number } {
    return {
      x: GRID.x0 + x * GRID.cellW + GRID.cellW / 2,
      y: GRID.y0 + y * GRID.cellH + GRID.cellH / 2,
    };
  }

  private refreshScene(): void {
    this.mapLayer?.destroy(true);
    this.panelLayer?.destroy(true);
    this.mapLayer = this.add.container(0, 0);
    this.panelLayer = this.add.container(0, 0);

    this.drawGrid();
    this.drawPlottedStations();
    if (this.mode === "triangulation") {
      this.drawBearingRays();
      this.drawCellPickers((cx, cy) => this.tryTriangulate(cx, cy));
    }

    if (this.mode === "bearings") {
      this.drawBearingsPanel();
    } else if (this.mode === "coordinates") {
      this.drawCoordinatesPanel();
      this.drawCellPickers((cx, cy) => this.tryPlotStation(cx, cy));
    } else if (this.mode === "scale") {
      this.drawScalePanel();
    } else {
      this.drawTriangulationPanel();
    }
    this.updateObjective();
  }

  private drawGrid(): void {
    const grid = this.add.graphics();
    grid.lineStyle(1, 0x4c7dff, 0.28);
    for (let col = 0; col <= this.variant.grid.cols; col += 1) {
      const x = GRID.x0 + col * GRID.cellW;
      grid.lineBetween(x, GRID.y0, x, GRID.y0 + this.variant.grid.rows * GRID.cellH);
    }
    for (let row = 0; row <= this.variant.grid.rows; row += 1) {
      const y = GRID.y0 + row * GRID.cellH;
      grid.lineBetween(GRID.x0, y, GRID.x0 + this.variant.grid.cols * GRID.cellW, y);
    }
    this.mapLayer?.add(grid);

    for (let col = 0; col < this.variant.grid.cols; col += 1) {
      const center = this.cellCenter(col, 0);
      this.mapLayer?.add(this.add.text(center.x, GRID.y0 - 18, String(col), {
        fontFamily: "Inter, Arial", fontSize: "12px", color: "#8fb6c6",
      }).setOrigin(0.5));
    }
    for (let row = 0; row < this.variant.grid.rows; row += 1) {
      const center = this.cellCenter(0, row);
      this.mapLayer?.add(this.add.text(GRID.x0 - 16, center.y, String(row), {
        fontFamily: "Inter, Arial", fontSize: "12px", color: "#8fb6c6",
      }).setOrigin(0.5));
    }
  }

  private drawPlottedStations(): void {
    this.coordinates.forEach((coordinate) => {
      if (!this.plottedStationIds.has(coordinate.id)) {
        return;
      }
      const center = this.cellCenter(coordinate.x, coordinate.y);
      this.mapLayer?.add(this.add.circle(center.x, center.y, 11, 0x6be7d6, 0.9).setStrokeStyle(2, 0xffffff, 0.7));
      this.mapLayer?.add(this.add.text(center.x + 14, center.y - 8, coordinate.station, {
        fontFamily: "Inter, Arial", fontSize: "12px", color: "#9ff5e9", fontStyle: "bold",
      }));
    });
  }

  private drawBearingRays(): void {
    const span = (this.variant.grid.cols + this.variant.grid.rows) * Math.max(GRID.cellW, GRID.cellH);
    this.bearings.forEach((bearing) => {
      const coordinate = this.coordinates.find((entry) => entry.id === bearing.id);
      if (!coordinate) {
        return;
      }
      const start = this.cellCenter(coordinate.x, coordinate.y);
      const vector = DIRECTION_VECTORS[bearing.answer];
      const ray = this.add.graphics();
      ray.lineStyle(2, 0xf6c85f, 0.5);
      ray.lineBetween(start.x, start.y, start.x + vector.dx * span, start.y + vector.dy * span);
      this.mapLayer?.add(ray);
    });
  }

  private drawCellPickers(onPick: (cx: number, cy: number) => void): void {
    for (let col = 0; col < this.variant.grid.cols; col += 1) {
      for (let row = 0; row < this.variant.grid.rows; row += 1) {
        const center = this.cellCenter(col, row);
        const hit = this.add.rectangle(center.x, center.y, GRID.cellW, GRID.cellH, 0xffffff, 0.001).setInteractive();
        if (hit.input) {
          hit.input.cursor = "pointer";
        }
        hit.on("pointerup", () => onPick(col, row));
        this.mapLayer?.add(hit);
      }
    }
  }

  // --- Phase 1: bearings (8-way compass) ------------------------------------

  private drawBearingsPanel(): void {
    const bearing = this.bearings.find((entry) => entry.id === this.selectedBearingId) ?? this.bearings[0];
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Rilevamenti radio", PALETTE));

    this.bearings.forEach((entry, index) => {
      const done = this.readBearingIds.has(entry.id);
      const focused = entry.id === bearing.id;
      this.panelLayer?.add(new Button(this, 1028, 332 + index * 32, `${done ? "✓" : "•"} ${entry.station}`, () => {
        this.selectedBearingId = entry.id;
        audioManager.play("click");
        this.refreshScene();
      }, {
        width: 354, height: 28, fontSize: 12,
        fill: focused ? 0x1f5a51 : done ? 0x173b36 : 0x20233a,
      }));
    });

    this.panelLayer?.add(this.add.text(842, 432, `📻 ${bearing.radioEnglish}`, {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#f7d37a", wordWrap: { width: 360 }, lineSpacing: 4,
    }));

    if (this.readBearingIds.has(bearing.id)) {
      this.panelLayer?.add(this.add.text(842, 500, `Direzione confermata: ${cardinalLabels[bearing.answer]}.`, {
        fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", wordWrap: { width: 360 },
      }));
      return;
    }

    this.panelLayer?.add(this.add.text(842, 482, "Tocca la direzione sulla bussola:", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1",
    }));
    // Compass centre marker.
    this.panelLayer?.add(this.add.circle(1030, 546, 14, 0x0d1b26, 0.9).setStrokeStyle(1, 0x6be7d6, 0.4));
    this.panelLayer?.add(this.add.text(1030, 546, "🧭", { fontFamily: "Inter, Arial", fontSize: "14px" }).setOrigin(0.5));
    COMPASS.forEach(({ dir, dx, dy }) => {
      this.panelLayer?.add(new Button(this, 1030 + dx, 546 + dy, compassLabels[dir], () => this.tryBearing(bearing.id, dir), {
        width: 66, height: 30, fontSize: 14, fill: 0x263743,
      }));
    });
  }

  private tryBearing(bearingId: string, choice: Cardinal): void {
    const bearing = this.bearings.find((entry) => entry.id === bearingId);
    if (!bearing) {
      return;
    }
    if (choice !== bearing.answer) {
      feedbackSystem.publish(`Direzione errata. ${bearing.italianGloss}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 546, 360, 150);
      return;
    }
    this.readBearingIds.add(bearing.id);
    audioManager.play("success");
    feedbackSystem.publish(`${bearing.station}: sorgente a ${cardinalLabels[bearing.answer]}.`, "success");
    VisualKit.particleBurst(this, 1030, 520, PALETTE, "success");
    if (this.readBearingIds.size === this.bearings.length) {
      missionEngine.completeObjective("atlasBearingsRead", ["geografia.orientamento", "inglese.istruzioni"], 16);
      this.mode = "coordinates";
    } else {
      const next = this.bearings.find((entry) => !this.readBearingIds.has(entry.id));
      if (next) {
        this.selectedBearingId = next.id;
      }
    }
    this.refreshScene();
  }

  // --- Phase 2: coordinates (click to plot) ---------------------------------

  private drawCoordinatesPanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Posiziona le stazioni", PALETTE));
    this.panelLayer?.add(this.add.text(842, 322, "Clicca sulla griglia la cella di ogni stazione. Le coordinate sono (colonna, riga).", {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#d9eaf1", wordWrap: { width: 360 }, lineSpacing: 4,
    }));
    this.coordinates.forEach((coordinate, index) => {
      const done = this.plottedStationIds.has(coordinate.id);
      this.panelLayer?.add(this.add.text(842, 392 + index * 64, `${done ? "✓" : "•"} ${coordinate.station} — (${coordinate.x}, ${coordinate.y})`, {
        fontFamily: "Inter, Arial", fontSize: "14px", color: done ? "#9ff5e9" : "#f7d37a", fontStyle: "bold", wordWrap: { width: 360 },
      }));
      this.panelLayer?.add(this.add.text(842, 414 + index * 64, coordinate.clue, {
        fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0", wordWrap: { width: 360 },
      }));
    });
  }

  private tryPlotStation(cx: number, cy: number): void {
    if (this.mode !== "coordinates") {
      return;
    }
    const target = this.coordinates.find((coordinate) => coordinate.x === cx && coordinate.y === cy && !this.plottedStationIds.has(coordinate.id));
    if (!target) {
      const already = this.coordinates.find((coordinate) => coordinate.x === cx && coordinate.y === cy);
      feedbackSystem.publish(already ? `${already.station} è già posizionata.` : `Cella (${cx}, ${cy}) vuota: rileggi le coordinate (colonna prima, riga dopo).`, "hint");
      audioManager.play("error");
      return;
    }
    this.plottedStationIds.add(target.id);
    audioManager.play("success");
    feedbackSystem.publish(`${target.station} posizionata in (${target.x}, ${target.y}).`, "success");
    const center = this.cellCenter(target.x, target.y);
    VisualKit.particleBurst(this, center.x, center.y, PALETTE, "success");
    if (this.plottedStationIds.size === this.coordinates.length) {
      missionEngine.completeObjective("atlasCoordinatesPlotted", ["matematica.coordinate", "pensieroCritico"], 16);
      this.mode = "scale";
    }
    this.refreshScene();
  }

  // --- Phase 3: scale (typed answer) ----------------------------------------

  private drawScalePanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Scala dell'atlante", PALETTE));
    this.panelLayer?.add(this.add.text(842, 318, this.scaleProblem.prompt, {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#d9eaf1", wordWrap: { width: 360 }, lineSpacing: 4,
    }));
    this.panelLayer?.add(this.add.text(842, 404, `Scala: 1 cella = ${this.scaleProblem.kmPerCell} km. Quanti km tra ${this.scaleProblem.fromLabel} e ${this.scaleProblem.toLabel}?`, {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#f7d37a", wordWrap: { width: 360 }, lineSpacing: 4,
    }));

    const input = document.createElement("input");
    input.type = "number";
    input.inputMode = "numeric";
    input.placeholder = "km";
    input.style.width = "150px";
    input.style.height = "40px";
    input.style.textAlign = "center";
    input.style.border = "1px solid rgba(107, 231, 214, 0.7)";
    input.style.borderRadius = "6px";
    input.style.background = "#08131c";
    input.style.color = "#f5fbff";
    input.style.font = "20px Inter, Arial";
    input.style.outline = "none";
    const dom = this.add.dom(1000, 500, input);
    this.panelLayer?.add(dom);
    this.panelLayer?.add(this.add.text(1086, 492, "km", {
      fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9",
    }));

    this.panelLayer?.add(new Button(this, 1030, 558, "Calcola", () => this.tryScale(input.value), {
      width: 220, height: 42, fontSize: 16, fill: 0x173b36,
    }));
    this.panelLayer?.add(this.add.text(842, 596, "Conta le celle tra i due punti e moltiplica per la scala.", {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0", wordWrap: { width: 360 },
    }));
  }

  private tryScale(raw: string): void {
    const value = Number.parseInt(raw, 10);
    if (!Number.isFinite(value)) {
      feedbackSystem.publish("Scrivi un numero in km, poi premi Calcola.", "hint");
      audioManager.play("error");
      return;
    }
    if (value !== this.scaleProblem.answerKm) {
      feedbackSystem.publish(`Non torna. ${this.scaleProblem.hint}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 500, 430, 150);
      return;
    }
    missionEngine.completeObjective("atlasScaleSolved", ["geografia.scale", "matematica.proporzionalita"], 16);
    audioManager.play("success");
    feedbackSystem.publish(`${this.scaleProblem.gridDistance} celle × ${this.scaleProblem.kmPerCell} km = ${this.scaleProblem.answerKm} km. Distanza confermata.`, "success");
    VisualKit.particleBurst(this, 1030, 500, PALETTE, "success");
    this.mode = "triangulation";
    this.refreshScene();
  }

  // --- Phase 4: triangulation (click the convergence cell) ------------------

  private drawTriangulationPanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Triangolazione", PALETTE));
    this.panelLayer?.add(this.add.text(842, 322, "Le tre linee partono dalle stazioni. Clicca sulla griglia la cella dove si incrociano tutte e tre.", {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#d9eaf1", wordWrap: { width: 360 }, lineSpacing: 4,
    }));
    this.panelLayer?.add(this.add.text(842, 408, "La sorgente è l'unico punto attraversato da tutti e tre i rilevamenti.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9aaab0", wordWrap: { width: 360 }, lineSpacing: 4,
    }));
  }

  /** How many of the three bearing rays pass through cell (cx, cy). */
  private raysThrough(cx: number, cy: number): number {
    return this.bearings.reduce((count, bearing) => {
      const station = this.coordinates.find((entry) => entry.id === bearing.id);
      if (!station) {
        return count;
      }
      const vector = DIRECTION_VECTORS[bearing.answer];
      const dx = cx - station.x;
      const dy = cy - station.y;
      if (dx === 0 && dy === 0) {
        return count;
      }
      const collinear = dx * vector.dy - dy * vector.dx === 0;
      const forward = dx * vector.dx + dy * vector.dy > 0;
      return collinear && forward ? count + 1 : count;
    }, 0);
  }

  private tryTriangulate(cx: number, cy: number): void {
    if (cx !== this.source.x || cy !== this.source.y) {
      const hits = this.raysThrough(cx, cy);
      feedbackSystem.publish(`Qui passano ${hits} rilevamenti su 3. La sorgente è dove passano tutti e tre.`, "hint");
      audioManager.play("error");
      const miss = this.cellCenter(cx, cy);
      VisualKit.outcomeFlash(this, "warning", miss.x, miss.y, GRID.cellW * 1.4, GRID.cellH * 1.4);
      return;
    }
    missionEngine.completeObjective("atlasSourceFound", ["problemSolving", "pensieroCritico"], 18);
    audioManager.play("success");
    const center = this.cellCenter(cx, cy);
    feedbackSystem.publish(`Sorgente individuata in (${cx}, ${cy}): le tre linee si incrociano qui.`, "success");
    VisualKit.outcomeFlash(this, "success");
    VisualKit.particleBurst(this, center.x, center.y, PALETTE, "success");
    missionEngine.completeMissionFive(`l'avamposto in (${cx}, ${cy})`);
    this.time.delayedCall(1000, () => this.scene.start("CampaignScene"));
  }

  private updateObjective(): void {
    const text: Record<AtlasMode, string> = {
      bearings: "Leggi i tre rilevamenti radio e indica ogni direzione sulla bussola a 8 punti.",
      coordinates: "Posiziona le tre stazioni sulla griglia leggendo le coordinate (colonna, riga).",
      scale: "Calcola la distanza reale in km usando la scala dell'atlante e scrivila.",
      triangulation: "Clicca la cella dove i tre rilevamenti si incrociano: è la sorgente del segnale.",
    };
    this.objectiveText?.setText(text[this.mode]);
  }

  private handleFeedback(message: FeedbackMessage): void {
    const colors = {
      info: "#d9eaf1",
      hint: "#f7d37a",
      success: "#9ff5e9",
      warning: "#ffb36b",
    };
    this.feedbackText?.setColor(colors[message.tone]).setText(message.text);
  }
}
