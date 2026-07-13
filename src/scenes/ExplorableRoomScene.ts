import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { getProceduralFocusPath } from "../data/procedural/focusPaths";
import { getMapArea, MAP_AREAS, type AreaConsoleSpec, type MapAreaDef } from "../data/procedural/mapAreas";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { RoomExplorer, type RoomConsole, type RoomConsoleState } from "./procedural/RoomExplorer";

/**
 * Hub esplorabile del mondo. Le aree vivono in {@link MAP_AREAS} (dati puri) e
 * la logica di movimento in {@link RoomExplorer}; qui ogni console avvia un
 * allenamento procedurale sul focus scelto e i nodi di navigazione portano da
 * un'area all'altra.
 */
export class ExplorableRoomScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
  private areaId = "laboratorio";
  private explorer?: RoomExplorer;
  private overlayOpen = false;
  private launching = false;
  private masteredCount = 0;

  constructor() {
    super("ExplorableRoomScene");
  }

  create(data?: { returnScene?: string; areaId?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    this.overlayOpen = false;
    this.launching = false;
    const area = getMapArea(data?.areaId ?? this.areaId);
    this.areaId = area.id;
    this.cameras.main.setBackgroundColor(0x060f16);

    // Visible consequence: subject consoles the player has trained power up, and
    // the area's "vitality" (fraction mastered) lights up the whole room.
    const trained = this.trainedFocuses();
    this.masteredCount = trained.size;
    const focusConsoles = area.consoles.filter((spec) => spec.focus);
    const trainedCount = focusConsoles.filter((spec) => spec.focus && trained.has(spec.focus)).length;
    const vitality = focusConsoles.length > 0 ? trainedCount / focusConsoles.length : 0;

    const consoles: RoomConsole[] = area.consoles.map((spec) => ({
      id: spec.id,
      assetId: spec.assetId,
      label: spec.label,
      glyph: spec.glyph,
      color: spec.color,
      x: spec.x,
      y: spec.y,
      w: spec.w,
      h: spec.h,
      state: this.consoleState(spec, trained),
      ref: spec,
    }));

    this.explorer = new RoomExplorer(this, {
      worldW: area.worldW,
      worldH: area.worldH,
      bgTexture: area.bgTexture,
      floorColor: area.floorColor,
      decorate: area.decorate,
      walls: area.walls,
      consoles,
      seedKey: `area-${area.id}`,
      minimap: true,
      vitality,
      accentColor: area.accent,
      onInteract: (console) => this.onInteract(console),
    });

    this.buildHud(area, vitality, trainedCount, focusConsoles.length);
    this.cameras.main.fadeIn(220, 6, 15, 22);
    this.showAreaTitle(area, vitality);
    this.celebrateNewUnlocks();
    audioManager.play("scan");
  }

  /** Focuses the player has trained at least once (persisted training records). */
  private trainedFocuses(): Set<string> {
    const set = new Set<string>();
    for (const record of Object.values(saveSystem.data.trainingRecords ?? {})) {
      if (record.runs > 0) set.add(record.focus);
    }
    return set;
  }

  /** Locked for gated portals, powered for mastered subjects, active otherwise. */
  private consoleState(spec: AreaConsoleSpec, trained: Set<string>): RoomConsoleState {
    if (spec.targetArea) {
      const required = getMapArea(spec.targetArea).unlock ?? 0;
      return this.masteredCount < required ? "locked" : "active";
    }
    if (spec.focus && trained.has(spec.focus)) return "resolved";
    return "active";
  }

  /** One-time banner the first time an area's mastery requirement is met. */
  private celebrateNewUnlocks(): void {
    const freshly: MapAreaDef[] = [];
    for (const area of Object.values(MAP_AREAS)) {
      const required = area.unlock ?? 0;
      if (required <= 0) continue;
      const flag = `area-unlocked-${area.id}`;
      if (this.masteredCount >= required && !saveSystem.data.flags[flag]) {
        saveSystem.setFlag(flag);
        freshly.push(area);
      }
    }
    if (freshly.length > 0) {
      this.time.delayedCall(1900, () => this.showUnlockBanner(freshly[0]));
    }
  }

  private showUnlockBanner(area: MapAreaDef): void {
    if (!this.scene.isActive()) return;
    const cx = this.scale.width / 2;
    const cy = 150;
    const card = this.add.container(cx, cy - 10).setScrollFactor(0).setDepth(210).setAlpha(0);
    card.add(this.add.rectangle(0, 0, 520, 60, 0x07151d, 0.94).setStrokeStyle(2, area.accent, 0.95));
    card.add(this.add.text(0, -12, "✦ NUOVA AREA SBLOCCATA ✦", {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold",
    }).setOrigin(0.5));
    card.add(this.add.text(0, 12, area.label.toUpperCase(), {
      fontFamily: "Inter, Arial", fontSize: "20px", color: "#f5fbff", fontStyle: "bold",
    }).setOrigin(0.5));
    this.explorer?.markUi(card);
    audioManager.play("panelOpen");
    this.tweens.add({
      targets: card, alpha: 1, y: cy, duration: 320, ease: "Cubic.easeOut",
      onComplete: () => this.tweens.add({ targets: card, alpha: 0, delay: 2200, duration: 600, onComplete: () => card.destroy(true) }),
    });
  }

  private showLockedMessage(areaLabel: string, required: number): void {
    audioManager.play("scan");
    this.showError(`🔒 ${areaLabel}: padroneggia ${required} materie per sbloccarla · ne hai ${this.masteredCount}.`);
  }

  /** Cartello d'ingresso: il nome dell'area appare e svanisce dolcemente. */
  private showAreaTitle(area: MapAreaDef, vitality = 0): void {
    const cx = this.scale.width / 2;
    const cy = this.scale.height / 2 - 60;
    const card = this.add.container(cx, cy + 12).setScrollFactor(0).setDepth(200).setAlpha(0);
    card.add(this.add.text(0, 0, area.label.toUpperCase(), {
      fontFamily: "Inter, Arial", fontSize: "42px", color: "#f5fbff", fontStyle: "bold", stroke: "#03121b", strokeThickness: 6,
    }).setOrigin(0.5));
    card.add(this.add.rectangle(0, 36, 260, 3, area.accent, 0.95));
    if (vitality >= 1) {
      card.add(this.add.text(0, 62, "✦ AREA RIGENERATA ✦", {
        fontFamily: "Inter, Arial", fontSize: "18px", color: "#f7d37a", fontStyle: "bold", stroke: "#03121b", strokeThickness: 4,
      }).setOrigin(0.5));
    }
    this.explorer?.markUi(card);
    this.tweens.add({
      targets: card, alpha: 1, y: cy, duration: 320, ease: "Cubic.easeOut",
      onComplete: () => this.tweens.add({ targets: card, alpha: 0, delay: 1000, duration: 520, onComplete: () => card.destroy(true) }),
    });
  }

  update(_time: number, delta: number): void {
    this.explorer?.update(delta, this.overlayOpen);
  }

  private buildHud(area: MapAreaDef, vitality: number, trained: number, total: number): void {
    const hint = this.add.text(24, 22, `${area.label} · cammina con WASD/frecce o tocca il pavimento · E vicino a una console`, {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", backgroundColor: "rgba(4,18,28,0.8)", padding: { x: 10, y: 6 },
    }).setScrollFactor(0).setDepth(50);
    const back = new Button(this, 1180, 40, "Indietro", () => this.scene.start(this.returnScene), { width: 150, height: 40, fontSize: 15, fill: 0x263743 })
      .setScrollFactor(0).setDepth(50);
    this.explorer?.markUi([hint, back, ...this.buildVitalityMeter(area, vitality, trained, total)]);
  }

  /** Top-center meter: how alive the area is (fraction of subjects mastered). */
  private buildVitalityMeter(area: MapAreaDef, vitality: number, trained: number, total: number): Phaser.GameObjects.GameObject[] {
    const cx = 640;
    const y = 80;
    const w = 300;
    const h = 12;
    const label = this.add.text(cx, y - 17, `⚡ VITALITÀ ${area.label.toUpperCase()}  ·  ${trained}/${total} console attive`, {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", fontStyle: "bold",
    }).setOrigin(0.5).setScrollFactor(0).setDepth(50);
    const track = this.add.rectangle(cx, y, w, h, 0x07151d, 0.9).setStrokeStyle(1, area.accent, 0.5).setScrollFactor(0).setDepth(50);
    const fill = this.add.rectangle(cx - w / 2 + 2, y, Math.max(2, (w - 4) * vitality), h - 4, area.accent, 0.95)
      .setOrigin(0, 0.5).setScrollFactor(0).setDepth(51);
    const pct = this.add.text(cx + w / 2 + 12, y, `${Math.round(vitality * 100)}%`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: vitality >= 1 ? "#f7d37a" : "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0, 0.5).setScrollFactor(0).setDepth(50);
    if (vitality > 0) {
      this.tweens.add({ targets: fill, alpha: 0.7, duration: 1400, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
    return [label, track, fill, pct];
  }

  private onInteract(console: RoomConsole): void {
    if (this.overlayOpen || this.launching) return;
    const spec = console.ref as AreaConsoleSpec | undefined;
    audioManager.play("panelOpen");
    if (spec?.targetArea) {
      const target = getMapArea(spec.targetArea);
      const required = target.unlock ?? 0;
      if (this.masteredCount < required) {
        this.showLockedMessage(target.label, required);
        return;
      }
      this.travelTo(spec.targetArea);
      return;
    }
    if (!spec?.focus) {
      this.scene.start(this.returnScene);
      return;
    }
    this.openFocusPanel(console, spec.focus, spec.summary ?? "");
  }

  private travelTo(areaId: string): void {
    this.explorer?.pauseForOverlay();
    this.overlayOpen = true;
    this.cameras.main.fadeOut(220, 3, 8, 12);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => {
      this.scene.restart({ returnScene: this.returnScene, areaId });
    });
  }

  private openFocusPanel(console: RoomConsole, focus: ProceduralSpecialization, summary: string): void {
    this.overlayOpen = true;
    this.explorer?.pauseForOverlay();
    const path = getProceduralFocusPath([focus]);
    const panel = this.add.container(640, 360).setScrollFactor(0).setDepth(100);
    this.explorer?.markUi(panel);
    panel.add(this.add.rectangle(0, 0, 1280, 720, 0x02070b, 0.72).setInteractive());
    panel.add(this.add.rectangle(0, 0, 680, 380, 0x07151d, 0.99).setStrokeStyle(3, console.color, 0.9));
    panel.add(this.add.text(0, -138, `${console.glyph}  ${path.label}`, { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    panel.add(this.add.text(0, -88, path.title, {
      fontFamily: "Inter, Arial", fontSize: "17px", color: "#f7d37a", fontStyle: "bold", align: "center",
    }).setOrigin(0.5));
    panel.add(this.add.text(0, -20, `${summary}\n\n${path.stageHint}`, {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", align: "center", lineSpacing: 6, wordWrap: { width: 570 },
    }).setOrigin(0.5));
    panel.add(this.add.text(0, 78, "Avvierò una stanza generata su questo focus, senza pressione: risolvi le console e registra il risultato.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", align: "center", wordWrap: { width: 540 },
    }).setOrigin(0.5));
    panel.add(new Button(this, -150, 142, "Resta nella mappa", () => {
      panel.destroy(true);
      this.overlayOpen = false;
      this.explorer?.resume();
    }, { width: 240, height: 46, fill: 0x263743 }));
    panel.add(new Button(this, 166, 142, "Avvia allenamento", () => {
      panel.destroy(true);
      this.startFocusTraining(focus);
    }, { width: 268, height: 46, fill: 0x173b36, stroke: console.color }));
  }

  private startFocusTraining(focus: ProceduralSpecialization): void {
    if (this.launching) return;
    this.launching = true;
    try {
      saveSystem.load();
      saveSystem.pauseActiveProceduralRun();
      this.createProceduralRun(focus, this.mapDifficulty(), focus === "libera" ? "mission" : "training");
      void startScene(this, "ProceduralMissionScene").catch(() => {
        this.launching = false;
        this.overlayOpen = false;
        this.explorer?.resume();
        this.showError("Non sono riuscito ad aprire l'allenamento. Riprova tra un istante.");
      });
    } catch {
      this.launching = false;
      this.overlayOpen = false;
      this.explorer?.resume();
      this.showError("Non sono riuscito a generare l'allenamento. Riprova con un nuovo seed.");
    }
  }

  private mapDifficulty(): DifficultyLevel {
    const run = saveSystem.getProceduralTrainingRun() ?? saveSystem.getProceduralMissionRun() ?? saveSystem.data.proceduralRun;
    return Phaser.Math.Clamp(Math.round(run?.difficulty ?? 2), 1, 8) as DifficultyLevel;
  }

  private createProceduralRun(
    focus: ProceduralSpecialization = "libera",
    difficulty: DifficultyLevel = this.mapDifficulty(),
    mode: "mission" | "training" = focus === "libera" ? "mission" : "training",
  ): void {
    const focusList = focus === "libera" ? ["libera"] : [focus];
    const mission = proceduralDirector.generateFreshMission(difficulty, focusList);
    const createdAt = new Date().toISOString();
    const objectiveCount = Math.max(1, mission.objectives.length);
    const pressureEnabled = proceduralRunRules.pressureEnabledForMode(mode);
    const timeLimitMs = pressureEnabled ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, objectiveCount) : undefined;
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: focusList,
      mode,
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      maxLives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      timerState: "preparing",
      createdAt,
      activeElapsedMs: 0,
      startedAt: createdAt,
    };
    saveSystem.setProceduralRun(run);
  }

  private showError(message: string): void {
    const panel = this.add.rectangle(640, 664, 620, 46, 0x1f1414, 0.94).setStrokeStyle(1, 0xff8f8f, 0.58).setScrollFactor(0).setDepth(120);
    const text = this.add.text(640, 664, message, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
    }).setOrigin(0.5).setScrollFactor(0).setDepth(121);
    this.explorer?.markUi([panel, text]);
    this.time.delayedCall(2400, () => {
      panel.destroy();
      text.destroy();
    });
  }
}
