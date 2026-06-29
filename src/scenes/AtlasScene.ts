import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { dialogueSystem } from "../core/DialogueSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import type { FeedbackMessage } from "../core/FeedbackSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { missionEngine } from "../core/MissionEngine";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import {
  atlasBearings,
  atlasCoordinates,
  atlasGrid,
  atlasScaleProblem,
  atlasSourceCandidates,
  cardinalLabels,
  type AtlasSourceCandidate,
  type Cardinal,
} from "../data/atlas";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type AtlasMode = "bearings" | "coordinates" | "scale" | "triangulation";

const PALETTE = "academy" as const;

/** Screen unit vectors per cardinal (y grows downward, like the grid rows). */
const DIRECTION_VECTORS: Record<Cardinal, { dx: number; dy: number }> = {
  N: { dx: 0, dy: -1 },
  NE: { dx: 1, dy: -1 },
  E: { dx: 1, dy: 0 },
  SE: { dx: 1, dy: 1 },
  S: { dx: 0, dy: 1 },
  SW: { dx: -1, dy: 1 },
  W: { dx: -1, dy: 0 },
  NW: { dx: -1, dy: -1 },
};

const GRID = { x0: 96, y0: 214, cellW: 64, cellH: 48 };

export class AtlasScene extends Phaser.Scene {
  private mode: AtlasMode = "bearings";
  private readBearingIds = new Set<string>();
  private plottedStationIds = new Set<string>();
  private selectedBearingId = atlasBearings[0].id;
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
      atlasBearings.forEach((bearing) => this.readBearingIds.add(bearing.id));
    }
    if (saveSystem.data.flags.atlasCoordinatesPlotted) {
      atlasCoordinates.forEach((coordinate) => this.plottedStationIds.add(coordinate.id));
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
      width: 150,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
    new Button(this, 930, 58, "Storia", () => this.scene.start("CampaignScene"), {
      width: 132,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
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
    for (let col = 0; col <= atlasGrid.cols; col += 1) {
      const x = GRID.x0 + col * GRID.cellW;
      grid.lineBetween(x, GRID.y0, x, GRID.y0 + atlasGrid.rows * GRID.cellH);
    }
    for (let row = 0; row <= atlasGrid.rows; row += 1) {
      const y = GRID.y0 + row * GRID.cellH;
      grid.lineBetween(GRID.x0, y, GRID.x0 + atlasGrid.cols * GRID.cellW, y);
    }
    this.mapLayer?.add(grid);

    for (let col = 0; col < atlasGrid.cols; col += 1) {
      const center = this.cellCenter(col, 0);
      this.mapLayer?.add(this.add.text(center.x, GRID.y0 - 18, String(col), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#8fb6c6",
      }).setOrigin(0.5));
    }
    for (let row = 0; row < atlasGrid.rows; row += 1) {
      const center = this.cellCenter(0, row);
      this.mapLayer?.add(this.add.text(GRID.x0 - 16, center.y, String(row), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#8fb6c6",
      }).setOrigin(0.5));
    }
  }

  private drawPlottedStations(): void {
    atlasCoordinates.forEach((coordinate) => {
      if (!this.plottedStationIds.has(coordinate.id)) {
        return;
      }
      const center = this.cellCenter(coordinate.x, coordinate.y);
      this.mapLayer?.add(this.add.circle(center.x, center.y, 11, 0x6be7d6, 0.9).setStrokeStyle(2, 0xffffff, 0.7));
      this.mapLayer?.add(this.add.text(center.x + 14, center.y - 8, coordinate.station, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9ff5e9",
        fontStyle: "bold",
      }));
    });
  }

  private drawBearingRays(): void {
    const span = (atlasGrid.cols + atlasGrid.rows) * Math.max(GRID.cellW, GRID.cellH);
    atlasBearings.forEach((bearing) => {
      const coordinate = atlasCoordinates.find((entry) => entry.id === bearing.id);
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
    for (let col = 0; col < atlasGrid.cols; col += 1) {
      for (let row = 0; row < atlasGrid.rows; row += 1) {
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

  // --- Phase 1: bearings ----------------------------------------------------

  private drawBearingsPanel(): void {
    const bearing = atlasBearings.find((entry) => entry.id === this.selectedBearingId) ?? atlasBearings[0];
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Rilevamenti radio", PALETTE));

    atlasBearings.forEach((entry, index) => {
      const done = this.readBearingIds.has(entry.id);
      const focused = entry.id === bearing.id;
      this.panelLayer?.add(new Button(this, 1028, 332 + index * 34, `${done ? "✓" : "•"} ${entry.station}`, () => {
        this.selectedBearingId = entry.id;
        audioManager.play("click");
        this.refreshScene();
      }, {
        width: 354,
        height: 30,
        fontSize: 12,
        fill: focused ? 0x1f5a51 : done ? 0x173b36 : 0x20233a,
      }));
    });

    this.panelLayer?.add(this.add.text(842, 430, `📻 ${bearing.radioEnglish}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
      lineSpacing: 5,
    }));

    if (this.readBearingIds.has(bearing.id)) {
      this.panelLayer?.add(this.add.text(842, 524, `Direzione confermata: ${cardinalLabels[bearing.answer]}.`, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#9ff5e9",
        wordWrap: { width: 360 },
      }));
      return;
    }

    this.panelLayer?.add(this.add.text(842, 520, "In che direzione punta la sorgente?", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
    }));
    bearing.options.forEach((option, index) => {
      const col = index % 2;
      const rowIndex = Math.floor(index / 2);
      this.panelLayer?.add(new Button(this, 928 + col * 196, 564 + rowIndex * 40, cardinalLabels[option], () => this.tryBearing(bearing.id, option), {
        width: 184,
        height: 34,
        fontSize: 14,
        fill: 0x263743,
      }));
    });
  }

  private tryBearing(bearingId: string, choice: Cardinal): void {
    const bearing = atlasBearings.find((entry) => entry.id === bearingId);
    if (!bearing) {
      return;
    }
    if (choice !== bearing.answer) {
      feedbackSystem.publish(`Direzione errata. ${bearing.italianGloss}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 560, 430, 120);
      return;
    }
    this.readBearingIds.add(bearing.id);
    audioManager.play("success");
    feedbackSystem.publish(`${bearing.station}: sorgente a ${cardinalLabels[bearing.answer]}.`, "success");
    VisualKit.particleBurst(this, 1030, 540, PALETTE, "success");
    if (this.readBearingIds.size === atlasBearings.length) {
      missionEngine.completeObjective("atlasBearingsRead", ["geografia.orientamento", "inglese.istruzioni"], 16);
      this.mode = "coordinates";
    } else {
      const next = atlasBearings.find((entry) => !this.readBearingIds.has(entry.id));
      if (next) {
        this.selectedBearingId = next.id;
      }
    }
    this.refreshScene();
  }

  // --- Phase 2: coordinates -------------------------------------------------

  private drawCoordinatesPanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Posiziona le stazioni", PALETTE));
    this.panelLayer?.add(this.add.text(842, 322, "Clicca sulla griglia la cella di ogni stazione. Le coordinate sono (colonna, riga).", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    atlasCoordinates.forEach((coordinate, index) => {
      const done = this.plottedStationIds.has(coordinate.id);
      this.panelLayer?.add(this.add.text(842, 392 + index * 64, `${done ? "✓" : "•"} ${coordinate.station} — (${coordinate.x}, ${coordinate.y})`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: done ? "#9ff5e9" : "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: 360 },
      }));
      this.panelLayer?.add(this.add.text(842, 414 + index * 64, coordinate.clue, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 360 },
      }));
    });
  }

  private tryPlotStation(cx: number, cy: number): void {
    if (this.mode !== "coordinates") {
      return;
    }
    const target = atlasCoordinates.find((coordinate) => coordinate.x === cx && coordinate.y === cy && !this.plottedStationIds.has(coordinate.id));
    if (!target) {
      const already = atlasCoordinates.find((coordinate) => coordinate.x === cx && coordinate.y === cy);
      feedbackSystem.publish(already ? `${already.station} è già posizionata.` : `Cella (${cx}, ${cy}) vuota: rileggi le coordinate (colonna prima, riga dopo).`, "hint");
      audioManager.play("error");
      return;
    }
    this.plottedStationIds.add(target.id);
    audioManager.play("success");
    feedbackSystem.publish(`${target.station} posizionata in (${target.x}, ${target.y}).`, "success");
    const center = this.cellCenter(target.x, target.y);
    VisualKit.particleBurst(this, center.x, center.y, PALETTE, "success");
    if (this.plottedStationIds.size === atlasCoordinates.length) {
      missionEngine.completeObjective("atlasCoordinatesPlotted", ["matematica.coordinate", "pensieroCritico"], 16);
      this.mode = "scale";
    }
    this.refreshScene();
  }

  // --- Phase 3: scale -------------------------------------------------------

  private drawScalePanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Scala dell'atlante", PALETTE));
    this.panelLayer?.add(this.add.text(842, 322, atlasScaleProblem.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    this.panelLayer?.add(this.add.text(842, 440, `Scala: 1 cella = ${atlasScaleProblem.kmPerCell} km. Quanti km tra ${atlasScaleProblem.fromLabel} e ${atlasScaleProblem.toLabel}?`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    atlasScaleProblem.options.forEach((option, index) => {
      const col = index % 2;
      const rowIndex = Math.floor(index / 2);
      this.panelLayer?.add(new Button(this, 928 + col * 196, 540 + rowIndex * 42, `${option} km`, () => this.tryScale(option), {
        width: 184,
        height: 36,
        fontSize: 15,
        fill: 0x263743,
      }));
    });
  }

  private tryScale(choice: number): void {
    if (choice !== atlasScaleProblem.answerKm) {
      feedbackSystem.publish(`Non torna. ${atlasScaleProblem.hint}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 560, 430, 120);
      return;
    }
    missionEngine.completeObjective("atlasScaleSolved", ["geografia.scale", "matematica.proporzionalita"], 16);
    audioManager.play("success");
    feedbackSystem.publish(`${atlasScaleProblem.gridDistance} celle × ${atlasScaleProblem.kmPerCell} km = ${atlasScaleProblem.answerKm} km. Distanza confermata.`, "success");
    VisualKit.particleBurst(this, 1030, 540, PALETTE, "success");
    this.mode = "triangulation";
    this.refreshScene();
  }

  // --- Phase 4: triangulation ----------------------------------------------

  private drawTriangulationPanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Triangolazione", PALETTE));
    this.panelLayer?.add(this.add.text(842, 322, "Le tre linee partono dalle stazioni. Scegli il punto dove si incrociano tutte.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    atlasSourceCandidates.forEach((candidate, index) => {
      this.panelLayer?.add(new Button(this, 1028, 396 + index * 50, `${candidate.label} (${candidate.x}, ${candidate.y})`, () => this.tryTriangulate(candidate), {
        width: 354,
        height: 40,
        fontSize: 14,
        fill: 0x263743,
      }));
      const center = this.cellCenter(candidate.x, candidate.y);
      this.mapLayer?.add(this.add.star(center.x, center.y, 4, 5, 12, candidate.correct ? 0xf6c85f : 0x8aa6b0, 0.6));
    });
  }

  private tryTriangulate(candidate: AtlasSourceCandidate): void {
    if (!candidate.correct) {
      feedbackSystem.publish(`${candidate.label}: ${candidate.reason}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 480, 430, 280);
      return;
    }
    missionEngine.completeObjective("atlasSourceFound", ["problemSolving", "pensieroCritico"], 18);
    audioManager.play("success");
    feedbackSystem.publish(`${candidate.label}: ${candidate.reason}`, "success");
    const center = this.cellCenter(candidate.x, candidate.y);
    VisualKit.outcomeFlash(this, "success");
    VisualKit.particleBurst(this, center.x, center.y, PALETTE, "success");
    missionEngine.completeMissionFive(candidate.label);
    this.time.delayedCall(1000, () => this.scene.start("CampaignScene"));
  }

  private updateObjective(): void {
    const text: Record<AtlasMode, string> = {
      bearings: "Leggi i tre rilevamenti radio e traduci ogni direzione in inglese in un punto cardinale.",
      coordinates: "Posiziona le tre stazioni sulla griglia leggendo le coordinate (colonna, riga).",
      scale: "Usa la scala dell'atlante per convertire le celle in chilometri reali.",
      triangulation: "Trova la cella dove i tre rilevamenti si incrociano: è la sorgente del segnale.",
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
