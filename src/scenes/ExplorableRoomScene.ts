import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { campaignSystem } from "../core/CampaignSystem";
import { playerSystem } from "../core/PlayerSystem";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { storySystem } from "../core/StorySystem";
import { openDailyPanel, showDailyRewardToast } from "../ui/DailyPanel";
import { showStoryChoice } from "../ui/StoryChoiceOverlay";
import { getProceduralFocusPath } from "../data/procedural/focusPaths";
import { getMapArea, MAP_AREAS, type AreaConsoleSpec, type MapAreaDef } from "../data/procedural/mapAreas";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { RoomExplorer, type RoomConsole, type RoomConsoleState } from "./procedural/RoomExplorer";

/**
 * Hub esplorabile del Relitto. I ponti vivono in {@link MAP_AREAS} (dati puri) e
 * la logica di movimento in {@link RoomExplorer}; qui ogni console avvia un
 * allenamento procedurale sul focus scelto e i nodi di navigazione portano da
 * un ponte all'altro.
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
    // The hub is the game's front door: make sure profile and save are loaded
    // and advance the daily loop even if the player never opens the NORA panel.
    playerSystem.load();
    saveSystem.load();
    saveSystem.rolloverDaily();
    const dailyGranted = saveSystem.claimDailyIfComplete();
    const area = getMapArea(data?.areaId ?? this.areaId);
    this.areaId = area.id;
    this.cameras.main.setBackgroundColor(0x060f16);

    // Visible consequence: sector consoles the player has calibrated power up, and
    // the bridge integrity lights up the whole room.
    const trained = this.trainedFocuses();
    this.masteredCount = trained.size;
    // "libera" is the Spedizione portal, not a subject: it never counts toward
    // the bridge integrity (it can't be "mastered").
    const focusConsoles = area.consoles.filter((spec) => spec.focus && spec.focus !== "libera");
    const trainedCount = focusConsoles.filter((spec) => spec.focus && trained.has(spec.focus)).length;
    const masteryVitality = focusConsoles.length > 0 ? trainedCount / focusConsoles.length : 0;
    const restorationItemId = this.restorationItemId(area.id);
    const restoredByEnergy = restorationItemId ? saveSystem.data.inventory.includes(restorationItemId) : false;
    const vitality = Math.max(masteryVitality, restoredByEnergy ? 0.62 : 0);

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
      restorationItemId,
      onInteract: (console) => this.onInteract(console),
    });

    this.buildHud(area, vitality, trainedCount, focusConsoles.length, restoredByEnergy);
    this.cameras.main.fadeIn(220, 6, 15, 22);
    this.showAreaTitle(area, vitality);
    this.celebrateNewUnlocks();
    this.updateStoryProgress();
    if (dailyGranted > 0) {
      this.time.delayedCall(700, () => {
        if (!this.scene.isActive()) return;
        this.explorer?.markUi(showDailyRewardToast(this, dailyGranted));
      });
    }
    audioManager.play("scan");
  }

  private restorationItemId(areaId: string): string | undefined {
    const ids: Record<string, string> = {
      laboratorio: "decor-laboratorio",
      "serra-bio": "decor-serra",
      "cantiere-circuiti": "decor-circuiti",
      osservatorio: "decor-osservatorio",
      "sala-musica": "decor-musica",
      "archivio-biblioteca": "decor-archivio",
      "biblioteca-classica": "decor-biblioteca-classica",
    };
    return ids[areaId];
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

  /**
   * Keeps the story in sync with real progress on every deck entry: reveals the
   * Diario pages just earned (toast), and — back on the central deck — surfaces
   * the bivio that is due (energy routing, the Guardian, the finale). Pull-based:
   * nothing in the campaign flow needs to know StorySystem exists.
   */
  private updateStoryProgress(): void {
    storySystem.setPlayerIdProvider(() => playerSystem.getActivePlayer().id);
    const completedMissionIds = campaignSystem.getChapters()
      .filter((chapter) => chapter.status === "complete")
      .map((chapter) => chapter.missionId);
    const masteredFocuses = Array.from(
      new Set(
        Object.values(saveSystem.data.trainingRecords ?? {})
          .filter((record) => record.runs > 0)
          .map((record) => record.focus),
      ),
    );
    const revealed = storySystem.syncProgress({ completedMissionIds, masteredFocuses });
    const kind = this.areaId === "laboratorio" ? storySystem.pendingChoice() : null;

    if (kind) {
      this.time.delayedCall(900, () => {
        if (!this.scene.isActive() || this.overlayOpen || this.launching) return;
        this.overlayOpen = true;
        this.explorer?.pauseForOverlay();
        const prompt = storySystem.choicePrompt(kind, { masteredSubjects: this.masteredCount });
        const overlay = showStoryChoice(this, prompt, {
          onClose: () => {
            this.overlayOpen = false;
            this.explorer?.resume();
            // Refresh: the choice may have changed console/vitality state.
            this.scene.restart({ returnScene: this.returnScene, areaId: this.areaId });
          },
          onEnding: (endingId) => {
            void startScene(this, "FinaleScene", { ending: endingId, returnScene: "ExplorableRoomScene" });
          },
        });
        this.explorer?.markUi(overlay);
      });
      return;
    }

    if (revealed.length > 0) {
      this.time.delayedCall(700, () => {
        if (this.scene.isActive()) this.showDiarioToast(revealed.length, revealed[0].title);
      });
    }
  }

  /** "Nuova pagina nel Diario di Bordo" banner; tap to open the Diario. */
  private showDiarioToast(count: number, firstTitle: string): void {
    const label = count === 1
      ? `✦ Nuova pagina nel Diario · ${firstTitle}`
      : `✦ ${count} nuove pagine nel Diario di Bordo`;
    const toast = this.add.container(640, 150).setScrollFactor(0).setDepth(220).setAlpha(0);
    const bg = this.add.rectangle(0, 0, 560, 52, 0x07151d, 0.96).setStrokeStyle(2, 0xf6c85f, 0.9)
      .setInteractive({ useHandCursor: true });
    toast.add(bg);
    toast.add(this.add.text(0, -7, label, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    toast.add(this.add.text(0, 13, "tocca per aprire il Diario · o dal Pannello NORA", { fontFamily: "Inter, Arial", fontSize: "11px", color: "#9fb6c2" }).setOrigin(0.5));
    bg.on("pointerdown", () => { void startScene(this, "DiarioScene", { returnScene: "ExplorableRoomScene" }); });
    this.explorer?.markUi(toast);
    audioManager.play("panelOpen");
    this.tweens.add({
      targets: toast, alpha: 1, y: 162, duration: 320, ease: "Cubic.easeOut",
      onComplete: () => this.tweens.add({ targets: toast, alpha: 0, delay: 3400, duration: 600, onComplete: () => toast.destroy(true) }),
    });
  }

  /** One-time banner the first time a bridge mastery requirement is met. */
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
    card.add(this.add.text(0, -12, "✦ NUOVO PONTE SBLOCCATO ✦", {
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
    this.showError(`Blocco del Guardiano: padroneggia ${required} settori per aprire ${areaLabel} · ne hai ${this.masteredCount}.`);
  }

  /** Cartello d'ingresso: il nome del ponte appare e svanisce dolcemente. */
  private showAreaTitle(area: MapAreaDef, vitality = 0): void {
    const cx = this.scale.width / 2;
    const cy = this.scale.height / 2 - 60;
    const card = this.add.container(cx, cy + 12).setScrollFactor(0).setDepth(200).setAlpha(0);
    card.add(this.add.text(0, 0, area.label.toUpperCase(), {
      fontFamily: "Inter, Arial", fontSize: "42px", color: "#f5fbff", fontStyle: "bold", stroke: "#03121b", strokeThickness: 6,
    }).setOrigin(0.5));
    card.add(this.add.rectangle(0, 36, 260, 3, area.accent, 0.95));
    if (vitality >= 1) {
      card.add(this.add.text(0, 62, "✦ PONTE RIATTIVATO ✦", {
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

  private buildHud(area: MapAreaDef, vitality: number, trained: number, total: number, restoredByEnergy: boolean): void {
    const hint = this.add.text(24, 22, `${area.label} · cammina con WASD/frecce o tocca il ponte · E vicino a una console`, {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", backgroundColor: "rgba(4,18,28,0.8)", padding: { x: 10, y: 6 },
    }).setScrollFactor(0).setDepth(50);
    const back = new Button(this, 1180, 40, "NORA", () => this.scene.start(this.returnScene), { width: 180, height: 40, fontSize: 14, fill: 0x263743 })
      .setScrollFactor(0).setDepth(50);
    this.explorer?.markUi([hint, back, ...this.buildVitalityMeter(area, vitality, trained, total, restoredByEnergy)]);
    if (this.areaId === "laboratorio") {
      this.buildLabHud();
    }
  }

  /** Hub-only HUD: daily-loop chip and, for brand-new players, a Story nudge. */
  private buildLabHud(): void {
    const objectives = saveSystem.dailyObjectives();
    const done = objectives.filter((objective) => objective.done).length;
    const chip = new Button(this, 190, 68, `🔥 Serie ${saveSystem.dailyStreak}g · Giorno ${done}/${objectives.length} ▸`, () => {
      if (this.overlayOpen || this.launching) return;
      this.overlayOpen = true;
      this.explorer?.pauseForOverlay();
      const panel = openDailyPanel(this, {
        onClose: () => {
          this.overlayOpen = false;
          this.explorer?.resume();
        },
        onClaim: (granted) => {
          this.explorer?.markUi(showDailyRewardToast(this, granted));
          this.time.delayedCall(900, () => this.scene.restart({ returnScene: this.returnScene, areaId: this.areaId }));
        },
      });
      this.explorer?.markUi(panel);
    }, { width: 300, height: 34, fontSize: 12, fill: 0x2a1f3a, stroke: 0xf6c85f }).setScrollFactor(0).setDepth(50);
    this.explorer?.markUi(chip);

    if (campaignSystem.getProgress().completed === 0) {
      const nudge = this.add.text(640, 112, "NORA: «Inizia dal Relitto: è lì che la nave ricorda.»", {
        fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold",
        backgroundColor: "rgba(4,18,28,0.85)", padding: { x: 12, y: 6 },
      }).setOrigin(0.5).setScrollFactor(0).setDepth(50);
      this.explorer?.markUi(nudge);
      this.tweens.add({ targets: nudge, alpha: 0.55, duration: 1600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  /** Top-center meter: how alive the bridge is (fraction of sectors mastered). */
  private buildVitalityMeter(area: MapAreaDef, vitality: number, trained: number, total: number, restoredByEnergy: boolean): Phaser.GameObjects.GameObject[] {
    const cx = 640;
    const y = 80;
    const w = 300;
    const h = 12;
    const label = this.add.text(cx, y - 17, `INTEGRITÀ ${area.label.toUpperCase()}  ·  ${trained}/${total} console attive${restoredByEnergy ? " · energia ripristinata" : ""}`, {
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
    if (spec?.targetScene) {
      this.openSceneFromWorld(spec.targetScene);
      return;
    }
    if (!spec?.focus) {
      this.scene.start(this.returnScene);
      return;
    }
    this.openFocusPanel(console, spec.focus, spec.summary ?? "");
  }

  /** Opens a non-explorable scene (e.g. the Story) from a world console. */
  private openSceneFromWorld(sceneKey: string): void {
    if (this.launching) return;
    this.launching = true;
    this.explorer?.pauseForOverlay();
    audioManager.play("doorOpen");
    this.cameras.main.fadeOut(260, 3, 8, 12);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => {
      void startScene(this, sceneKey, { returnScene: "ExplorableRoomScene" }).catch(() => {
        this.launching = false;
        this.explorer?.resume();
        this.showError("Non sono riuscito ad aprire questa console. Riprova tra un istante.");
      });
    });
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
    const isLibera = focus === "libera";
    const path = getProceduralFocusPath([focus]);
    const resumable = isLibera ? saveSystem.getProceduralMissionRun() : saveSystem.getProceduralTrainingRun();
    const canResume = this.isResumable(resumable) && (isLibera || proceduralRunRules.focusFor(resumable) === focus);
    const panel = this.add.container(640, 360).setScrollFactor(0).setDepth(100);
    this.explorer?.markUi(panel);
    panel.add(this.add.rectangle(0, 0, 1280, 720, 0x02070b, 0.72).setInteractive());
    panel.add(this.add.rectangle(0, 0, 680, 380, 0x07151d, 0.99).setStrokeStyle(3, console.color, 0.9));
    panel.add(this.add.text(0, -138, `${console.glyph}  ${isLibera ? "Spedizione" : path.label}`, { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    panel.add(this.add.text(0, -88, path.title, {
      fontFamily: "Inter, Arial", fontSize: "17px", color: "#f7d37a", fontStyle: "bold", align: "center",
    }).setOrigin(0.5));
    panel.add(this.add.text(0, -20, `${summary}\n\n${path.stageHint}`, {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", align: "center", lineSpacing: 6, wordWrap: { width: 570 },
    }).setOrigin(0.5));
    panel.add(this.add.text(0, 78, isLibera
      ? "Una missione completa attraverso tutti i settori: riattiva ogni sistema, poi la porta finale controllerà il Relitto."
      : "Avvierò una stanza generata su questo focus, senza pressione: risolvi le console e registra il risultato.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", align: "center", wordWrap: { width: 540 },
    }).setOrigin(0.5));
    const closePanel = (): void => {
      panel.destroy(true);
      this.overlayOpen = false;
      this.explorer?.resume();
    };
    if (canResume && resumable) {
      const solved = resumable.solvedPuzzleIds.length;
      const total = Math.max(1, resumable.mission.objectives.length);
      panel.add(new Button(this, -212, 142, "Resta nella mappa", closePanel, { width: 196, height: 46, fontSize: 13, fill: 0x263743 }));
      panel.add(new Button(this, 6, 142, `Riprendi (${solved}/${total})`, () => {
        panel.destroy(true);
        this.resumeRun(resumable);
      }, { width: 200, height: 46, fontSize: 13, fill: 0x2a1f3a, stroke: 0xf6c85f }));
      panel.add(new Button(this, 222, 142, isLibera ? "Nuova Spedizione" : "Nuova calibrazione", () => {
        panel.destroy(true);
        this.startFocusTraining(focus);
      }, { width: 210, height: 46, fontSize: 13, fill: 0x173b36, stroke: console.color }));
    } else {
      panel.add(new Button(this, -150, 142, "Resta nella mappa", closePanel, { width: 240, height: 46, fill: 0x263743 }));
      panel.add(new Button(this, 166, 142, isLibera ? "Avvia la Spedizione" : "Avvia calibrazione", () => {
        panel.destroy(true);
        this.startFocusTraining(focus);
      }, { width: 268, height: 46, fill: 0x173b36, stroke: console.color }));
    }
  }

  /** A run can be resumed if it is not finished and (under pressure) has lives left. */
  private isResumable(run: ProceduralRunSave | undefined): run is ProceduralRunSave {
    if (!run || run.completedAt || run.failedAt) return false;
    const mode = proceduralRunRules.modeFor(run);
    if ((mode === "mission" || mode === "progressive") && (run.lives ?? proceduralRunRules.maxLives) <= 0) return false;
    return true;
  }

  private resumeRun(run: ProceduralRunSave): void {
    if (this.launching) return;
    this.launching = true;
    saveSystem.pauseActiveProceduralRun();
    saveSystem.setActiveProceduralRun(run);
    void startScene(this, "ProceduralMissionScene").catch(() => {
      this.launching = false;
      this.overlayOpen = false;
      this.explorer?.resume();
      this.showError("Non sono riuscito a riprendere la partita. Riprova tra un istante.");
    });
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
        this.showError("Non sono riuscito ad aprire la calibrazione. Riprova tra un istante.");
      });
    } catch {
      this.launching = false;
      this.overlayOpen = false;
      this.explorer?.resume();
      this.showError("Non sono riuscito a generare la calibrazione. Riprova con un nuovo seed.");
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
