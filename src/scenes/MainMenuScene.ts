import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { buildInfo } from "../core/BuildInfo";
import { campaignSystem } from "../core/CampaignSystem";
import { masterySystem } from "../core/MasterySystem";
import { noraCompanion } from "../core/NoraCompanion";
import { noraChip } from "../ui/NoraChip";
import { mapLayoutSystem, type MapLayoutRect } from "../core/MapLayoutSystem";
import { playerSystem } from "../core/PlayerSystem";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { progressionSystem } from "../core/ProgressionSystem";
import { rewardSystem } from "../core/RewardSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { prefetchCoreScenes, startScene } from "../core/SceneNavigator";
import { formatDuration, proceduralScoring } from "../core/ProceduralScoring";
import { difficultyModel } from "../procedural/DifficultyModel";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { progressiveMissionBuilder } from "../procedural/ProgressiveMissionBuilder";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization, ProgressiveLevelResult } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { VisualKit } from "../ui/VisualKit";

const focusOptions: Array<{ id: ProceduralSpecialization; label: string }> = [
  { id: "matematica", label: "Focus matematica" },
  { id: "italiano", label: "Focus italiano" },
  { id: "inglese", label: "Focus inglese" },
  { id: "elettronica", label: "Focus circuiti" },
  { id: "coding", label: "Focus coding" },
  { id: "musica", label: "Focus musica" },
  { id: "fisica", label: "Focus fisica" },
];

const TRAINING_DIFFICULTY_KEY = "eliQuest.trainingDifficulty";

export class MainMenuScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getMainMenuLayout();
  private selectedDifficulty?: DifficultyLevel;
  private userPickedDifficulty = false;
  private transitioning = false;
  private noraGreeted = false;
  private showLevelPicker = false;

  constructor() {
    super("MainMenuScene");
  }

  preload(): void {
    queueSceneAssets(this, "progressive");
  }

  create(): void {
    this.transitioning = false;
    playerSystem.load();
    saveSystem.load();
    this.selectedDifficulty ??= this.loadSelectedDifficulty();
    audioManager.stopMusic();
    this.drawBackground();
    const recommended = this.recommendedDifficulty();
    const selected = this.activeDifficulty();
    const missionRun = saveSystem.getProceduralMissionRun();
    const trainingRun = saveSystem.getProceduralTrainingRun();
    const progressiveRun = saveSystem.getProceduralProgressiveRun();

    // ===== HEADER (compatto) =====
    this.add.rectangle(82, 44, 4, 92, 0x6be7d6, 0.7).setOrigin(0);
    this.add.rectangle(82, 44, 4, 30, 0xf6c85f, 0.85).setOrigin(0);
    this.add.text(100, 40, "ELI QUEST", { fontFamily: "Inter, Arial", fontSize: "48px", color: "#f5fbff", fontStyle: "bold", shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 10, fill: true } });
    this.add.text(104, 98, "Accademia delle Missioni", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" });
    this.add.text(792, 46, `Giocatore: ${playerSystem.getActivePlayer().name}`, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f6c85f", fontStyle: "bold" });
    new Button(this, 1000, 80, "👤 Cambia / Nuovo giocatore", () => this.openMenuScene("PlayerReportScene", "Non sono riuscito ad aprire i giocatori. Riprova tra un istante."), {
      width: 246, height: 30, fontSize: 12, fill: 0x1f5a51, stroke: 0xf6c85f,
    });

    // Anello del ciclo "gioca → guadagni → spendi": energia sempre visibile + Bottega.
    const energyChip = this.add.container(500, 58);
    energyChip.add(this.add.rectangle(0, 0, 184, 38, 0x061019, 0.92).setStrokeStyle(2, 0xf6c85f, 0.85));
    energyChip.add(this.add.text(-74, 0, "⚡", { fontFamily: "Inter, Arial", fontSize: "20px" }).setOrigin(0, 0.5));
    energyChip.add(this.add.text(-44, -9, "ENERGIA", { fontFamily: "Inter, Arial", fontSize: "9px", color: "#9fb6c2", fontStyle: "bold" }).setOrigin(0, 0.5));
    energyChip.add(this.add.text(-44, 7, String(rewardSystem.energy()), { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0, 0.5));
    new Button(this, 700, 58, "🛍️ Bottega", () => this.openMenuScene("RewardShopScene", "Non sono riuscito ad aprire la Bottega. Riprova tra un istante."), {
      width: 150, height: 38, fontSize: 13, fill: 0x3a3220, stroke: 0xf6c85f,
    });

    const cardProgress = campaignSystem.getProgress();

    // ===== LA STORIA — il cuore del percorso =====
    const sx = 44;
    const sy = 140;
    const sw = 716;
    const sh = 466;
    this.add.rectangle(sx, sy, sw, sh, 0x0a1a26, 0.94).setOrigin(0).setStrokeStyle(2, 0xf6c85f, 0.6);
    this.add.rectangle(sx, sy, sw, 5, 0xf6c85f, 0.9).setOrigin(0);
    this.add.text(sx + 24, sy + 16, "📖 LA STORIA", { fontFamily: "Inter, Arial", fontSize: "20px", color: "#f6c85f", fontStyle: "bold" });
    this.add.text(sx + sw - 24, sy + 20, `Capitoli ${cardProgress.completed}/${cardProgress.total}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(1, 0);
    this.add.text(sx + 24, sy + 44, "Il tuo viaggio nell'Accademia. Tutto il resto (Palestra, sfide, esercizi) serve a renderlo più giocoso, impegnativo e riuscito.", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: sw - 48 }, lineSpacing: 3 });

    // Mappa dei capitoli (rail)
    const chapters = campaignSystem.getChapters();
    const railY = sy + 116;
    const step = (sw - 180) / Math.max(1, chapters.length - 1);
    this.add.rectangle(sx + 90, railY, sw - 180, 3, 0x294958, 0.7).setOrigin(0, 0.5);
    chapters.forEach((ch, index) => {
      const nx = sx + 90 + index * step;
      const done = ch.status === "complete";
      const isActive = ch.status === "active";
      const color = done ? 0x2ed889 : isActive ? 0xf6c85f : 0x304653;
      this.add.circle(nx, railY, isActive ? 19 : 15, color, done || isActive ? 0.95 : 0.5).setStrokeStyle(2, color, 0.9);
      this.add.text(nx, railY, done ? "✓" : isActive ? "▶" : ch.status === "locked" ? "🔒" : String(ch.number), {
        fontFamily: "Inter, Arial", fontSize: isActive ? "14px" : "12px", color: ch.status === "locked" ? "#7d9098" : "#06131c", fontStyle: "bold",
      }).setOrigin(0.5);
      this.add.text(nx, railY + 28, `Cap ${ch.number}`, { fontFamily: "Inter, Arial", fontSize: "9px", color: isActive ? "#f7d37a" : done ? "#9ff5a7" : "#7d9098" }).setOrigin(0.5);
    });

    // Capitolo attuale (fulcro) + azione principale
    if (campaignSystem.isCampaignComplete()) {
      this.add.text(sx + 24, sy + 212, "🎉 Storia completata!", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#9ff5a7", fontStyle: "bold" });
      this.add.text(sx + 24, sy + 250, "Hai riacceso tutta l'Accademia. Rivivi un capitolo o mettiti alla prova nella Palestra.", { fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", wordWrap: { width: sw - 48 }, lineSpacing: 5 });
      new Button(this, sx + 200, sy + 372, "Rivivi la Storia ▸", () => this.openMenuScene("CampaignScene", "Non sono riuscito ad aprire la storia. Riprova tra un istante."), {
        width: 320, height: 56, fill: 0x1f5a51, stroke: 0xf6c85f, fontSize: 18, soundKey: "missionStart",
      });
    } else {
      const active = campaignSystem.getActiveChapter();
      this.add.text(sx + 24, sy + 208, `Capitolo ${active.number} · ${active.title}`, { fontFamily: "Inter, Arial", fontSize: "23px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: sw - 48 } });
      this.add.text(sx + 24, sy + 244, active.location, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold" });
      this.add.text(sx + 24, sy + 268, active.synopsis, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", wordWrap: { width: sw - 48 }, lineSpacing: 5 });
      new Button(this, sx + 190, sy + 388, `▶ Continua il Capitolo ${active.number}`, () => this.openMenuScene("CampaignScene", "Non sono riuscito ad aprire la storia. Riprova tra un istante."), {
        width: 348, height: 58, fill: 0x1f5a51, stroke: 0xf6c85f, fontSize: 16, soundKey: "missionStart",
      });
      // Ponte Storia↔pratica: rinforza il punto debole reale, o prepara il capitolo.
      const weakest = masterySystem.weakestPracticedFocus();
      const bridgeFocus = weakest ?? progressionSystem.practiceFocusForChapter(active.number);
      if (bridgeFocus) {
        const label = `💪 ${weakest ? "Rinforza" : "Allena"} ${proceduralScoring.domainLabel(bridgeFocus)}`;
        new Button(this, sx + 560, sy + 388, label, () => this.startFocusTraining(bridgeFocus), {
          width: 196, height: 58, fill: 0x173b36, stroke: 0x6be7d6, fontSize: 12,
        });
      }
    }

    // ===== AL SERVIZIO DELLA STORIA — Palestra (contorno di supporto) =====
    // Kept clear of the bottom-left NORA chip zone (x < 490).
    const hasResume = this.isResumable(missionRun) || this.isResumable(progressiveRun) || this.isResumable(trainingRun);
    this.add.text(498, sy + sh + 8, "AL SERVIZIO DELLA STORIA — allenamento di supporto", { fontFamily: "Inter, Arial", fontSize: "11px", color: "#7d93a0", fontStyle: "bold", wordWrap: { width: 264 } });
    new Button(this, 630, sy + sh + 58, hasResume ? "🏋 Palestra — riprendi / allena" : "🏋 Palestra — allenati per la Storia", () => this.openPalestraDrawer(), {
      width: 264, height: 52, fill: 0x2a1f3a, stroke: 0xf6c85f, fontSize: 13, soundKey: "uiSelect",
    });

    if (!this.noraGreeted) {
      this.noraGreeted = true;
      this.time.delayedCall(600, () => noraChip.say(this, noraCompanion.greetingShort(playerSystem.getActivePlayer().name), "info"));
    }

    // ===== C) LA MIA ACCADEMIA: progressi & strumenti (secondari) =====
    VisualKit.glassPanel(this, 792, 110, 438, 288, "academy", 0.72);
    this.add.text(820, 128, "LA MIA ACCADEMIA", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9", fontStyle: "bold" });
    this.add.text(820, 154, "Progressi, diario, classifiche e strumenti.", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: 392 } });
    const tool = (cx: number, cy: number, label: string, sceneKey: string, fill = 0x263743, stroke?: number): void => {
      new Button(this, cx, cy, label, () => this.openMenuScene(sceneKey, `Non sono riuscito ad aprire ${label}. Riprova tra un istante.`), {
        width: 200, height: 40, fontSize: 13, fill, stroke,
      });
    };
    tool(908, 200, "🎓 La mia Accademia", "AcademyScene", 0x1f5a51, 0x70d68a);
    tool(1124, 200, "📓 Diario", "JournalScene");
    tool(908, 248, "🏆 Classifiche", "LeaderboardScene");
    tool(1124, 248, "👤 Giocatori & Registro", "PlayerReportScene");
    tool(908, 296, "📐 Atlante", "MathStudyScene");
    tool(1124, 296, "🤖 NORA", "NoraScene", 0x173b36, 0x9ff5e9);
    tool(908, 344, "👩‍🏫 Quadro Docente", "TeacherDashboardScene", 0x2a3550, 0x9f8cff);

    // ===== I TUOI PROGRESSI (rango, storia, difficoltà adattiva) =====
    const prog = progressionSystem.getProgression();
    VisualKit.glassPanel(this, 792, 412, 438, 276, "academy", 0.72);
    this.add.text(820, 420, "I TUOI PROGRESSI", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold" });
    this.add.text(820, 442, prog.rankTitle, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f6c85f", fontStyle: "bold" });
    this.add.text(820, 470, prog.rankDescription, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: 392 }, lineSpacing: 4 });
    this.add.text(820, 524, `Storia: ${cardProgress.completed}/${cardProgress.total} capitoli  ·  ${prog.nextUnlock}`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9ff5e9", wordWrap: { width: 392 }, lineSpacing: 3 });
    const noraMemories = noraCompanion.memories();
    const recoveredMemories = noraMemories.filter((memory) => memory.unlocked).length;
    this.add.text(820, 550, `💜 Ricordi di NORA: ${recoveredMemories}/${noraMemories.length}  ·  recuperali superando i capitoli`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#cdbfff", wordWrap: { width: 392 } });
    if (this.showLevelPicker) {
      this.add.text(820, 584, `Difficoltà di allenamenti e missioni rapide — ora ${selected}/8 (di norma è automatica):`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f6c85f", wordWrap: { width: 392 } });
      for (let level = 1; level <= 8; level += 1) {
        new Button(this, 828 + (level - 1) * 48, 642, String(level), () => this.selectDifficulty(level as DifficultyLevel), {
          width: 40, height: 34, fontSize: 13,
          fill: selected === level ? 0x1f5a51 : 0x142736,
          stroke: selected === level ? 0xf6c85f : 0x6be7d6,
        });
      }
    } else {
      this.add.text(820, 600, `Difficoltà di allenamenti e missioni: automatica (~${recommended}/8), si regola sui tuoi risultati.`, { fontFamily: "Inter, Arial", fontSize: "11px", color: "#7da2af", wordWrap: { width: 212 } });
      new Button(this, 1124, 616, "Scegli a mano ▸", () => { this.showLevelPicker = true; this.scene.restart(); }, {
        width: 156, height: 32, fontSize: 11, fill: 0x142736, stroke: 0x6be7d6,
      });
    }
    this.add.text(1210, 704, `build ${buildInfo.ref}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#7da2af",
    }).setOrigin(1, 0.5).setAlpha(0.8);
    new Button(this, 1230, 36, "⚙", () => this.openSettings(), {
      width: 48,
      height: 40,
      fill: 0x142736,
      stroke: 0x6be7d6,
      fontSize: 20,
      soundKey: "uiSelect",
    });

    VisualKit.vignette(this);
    placeHiddenAnomaly(this, "MainMenuScene");
    this.scheduleResponsivenessWarmup();
  }

  private openSettings(): void {
    if (this.transitioning) return;
    this.scene.pause();
    this.scene.launch("SettingsScene", { returnTo: this.scene.key });
  }

  private drawBackground(): void {
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    const portal = this.rect("menu:portal", { x: 998, y: 360, width: 360, height: 390 });
    this.add.circle(portal.x, portal.y, 118, 0x6be7d6, 0.035).setStrokeStyle(2, 0x6be7d6, 0.22);
    this.add.circle(portal.x, portal.y, 62, 0xf6c85f, 0.055).setStrokeStyle(1, 0xf6c85f, 0.18);
    this.tweens.add({
      targets: this.add.circle(portal.x, portal.y, 155, 0x6be7d6, 0.012).setStrokeStyle(1, 0x6be7d6, 0.12),
      scale: 1.08,
      alpha: 0.18,
      duration: 2800,
      yoyo: true,
      repeat: -1,
    });
  }

  private openMenuScene(sceneKey: string, errorMessage: string): void {
    if (this.transitioning) return;
    this.transitioning = true;
    this.setMenuButtonsEnabled(false);
    void startScene(this, sceneKey).catch(() => {
      this.transitioning = false;
      this.setMenuButtonsEnabled(true);
      this.showMenuError(errorMessage);
    });
  }

  private rect(id: string, fallback: MapLayoutRect): MapLayoutRect {
    return { ...fallback, ...this.layout[id] };
  }

  private startMissionGame(): void {
    if (this.transitioning) return;
    this.transitioning = true;
    const clearBusy = this.showBusy("Preparo una missione validata...");
    saveSystem.load();
    this.time.delayedCall(40, () => {
      try {
        saveSystem.pauseActiveProceduralRun();
        this.createProceduralRun("libera", this.activeDifficulty(), "mission");
        void startScene(this, "ProceduralMissionScene").catch(() => {
          clearBusy();
          this.transitioning = false;
          this.showMenuError("Non sono riuscito ad aprire la missione. Riprova tra un istante.");
        });
      } catch {
        clearBusy();
        this.transitioning = false;
        this.showMenuError("Non sono riuscito a preparare la missione. Riprova tra un istante.");
      }
    });
  }

  private resumeMissionGame(): void {
    if (this.transitioning) return;
    saveSystem.load();
    const run = saveSystem.getProceduralMissionRun();
    if (!this.isResumable(run)) {
      this.startMissionGame();
      return;
    }
    this.transitioning = true;
    this.setMenuButtonsEnabled(false);
    saveSystem.pauseActiveProceduralRun();
    saveSystem.setActiveProceduralRun(run);
    void startScene(this, "ProceduralMissionScene").catch(() => {
      this.transitioning = false;
      this.setMenuButtonsEnabled(true);
      this.showMenuError("Non sono riuscito a riprendere la missione. Riprova tra un istante.");
    });
  }

  private startFocusTraining(focus: ProceduralSpecialization): void {
    if (this.transitioning) return;
    saveSystem.load();
    const previousTraining = saveSystem.getProceduralTrainingRun();
    if (this.isSameFocus(previousTraining, focus) && this.isResumable(previousTraining)) {
      this.resumeFocusTraining();
      return;
    }
    this.transitioning = true;
    const clearBusy = this.showBusy("Costruisco il percorso focus...");
    this.time.delayedCall(40, () => {
      try {
        saveSystem.pauseActiveProceduralRun();
        // Subject-adaptive by default; an explicit 1-8 pick this session forces the level.
        const focusLevel = this.userPickedDifficulty ? this.activeDifficulty() : this.recommendedDifficultyForFocus(focus);
        this.createProceduralRun(focus, focusLevel, "training");
        void startScene(this, "ProceduralMissionScene").catch(() => {
          clearBusy();
          this.transitioning = false;
          this.showMenuError("Non sono riuscito ad aprire il focus. Riprova tra un istante.");
        });
      } catch {
        clearBusy();
        this.transitioning = false;
        this.showMenuError("Non sono riuscito a costruire il focus. Riprova con un altro seed.");
      }
    });
  }

  private resumeFocusTraining(): void {
    if (this.transitioning) return;
    saveSystem.load();
    const run = saveSystem.getProceduralTrainingRun();
    if (!this.isResumable(run)) {
      this.showMenuError("Non c'è un focus sospeso da riprendere.");
      return;
    }
    this.transitioning = true;
    this.setMenuButtonsEnabled(false);
    saveSystem.pauseActiveProceduralRun();
    saveSystem.setActiveProceduralRun(run);
    void startScene(this, "ProceduralMissionScene").catch(() => {
      this.transitioning = false;
      this.setMenuButtonsEnabled(true);
      this.showMenuError("Non sono riuscito a riprendere il focus. Riprova tra un istante.");
    });
  }

  private showScalataTower(): void {
    if (this.transitioning) return;
    saveSystem.load();
    const run = saveSystem.getProceduralProgressiveRun();
    const resumable = this.isResumable(run);
    const maxLives = run?.maxLives ?? proceduralRunRules.maxLives;
    const lives = run?.lives ?? maxLives;
    const score = run?.score?.total ?? 0;
    const currentLevel = run?.progressive?.currentLevel ?? 1;
    const unlocked = Math.max(currentLevel, run?.progressive?.unlockedLevel ?? currentLevel);
    const results = run?.progressive?.results ?? [];
    const completedLevels = new Set<number>(results.filter((result) => result.completed).map((result) => result.level));

    const modal = this.add.container(0, 0).setDepth(1500);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
    if (this.textures.exists("progressive-scalata-bg")) {
      modal.add(this.add.image(640, 360, "progressive-scalata-bg").setDisplaySize(1180, 648).setAlpha(0.5));
      modal.add(this.add.rectangle(640, 360, 1180, 648, 0x02070b, 0.44));
      modal.add(this.add.rectangle(640, 360, 1180, 648, 0x07151d, 0).setStrokeStyle(2, 0xff8f6b, 0.72));
    } else {
      modal.add(this.add.rectangle(640, 360, 1180, 648, 0x07151d, 0.99).setStrokeStyle(2, 0xff8f6b, 0.6));
    }
    modal.add(this.add.rectangle(108, 66, 5, 50, 0xff8f6b, 0.95).setOrigin(0));
    modal.add(this.add.text(120, 70, "La Scalata", { fontFamily: "Inter, Arial", fontSize: "38px", color: "#f5fbff", fontStyle: "bold" }));
    modal.add(this.add.rectangle(1180, 78, 188, 30, 0x1a0f0a, 0.85).setOrigin(1, 0).setStrokeStyle(2, 0xff8f6b, 0.85));
    modal.add(this.add.text(1086, 93, "🗼 PERCORSO SCALATA", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#ff8f6b", fontStyle: "bold" }).setOrigin(0.5));
    modal.add(this.add.text(122, 120, "Prove a difficoltà crescente, una dopo l'altra, senza pause. Sali più in alto che puoi: ogni livello vale di più.", {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", wordWrap: { width: 560 },
    }));

    // --- Tower (rungs 1..8, level 1 at the bottom) ---
    const towerX = 360;
    const baseY = 612;
    const gap = 62;
    const connector = this.add.graphics();
    connector.lineStyle(6, 0x294958, 0.7);
    connector.lineBetween(towerX, baseY, towerX, baseY - 7 * gap);
    modal.add(connector);
    for (let level = 1; level <= 8; level += 1) {
      const y = baseY - (level - 1) * gap;
      const done = completedLevels.has(level);
      const isCurrent = level === currentLevel;
      const locked = level > unlocked;
      const color = done ? 0x2ed889 : isCurrent ? 0xf6c85f : locked ? 0x2a3a44 : 0x2f6f64;
      modal.add(this.add.rectangle(towerX, y, isCurrent ? 320 : 280, isCurrent ? 40 : 34, color, locked ? 0.5 : 0.92)
        .setStrokeStyle(2, isCurrent ? 0xffe6a0 : color, 0.9));
      modal.add(this.add.text(towerX - 132, y - 9, `Livello ${level}`, {
        fontFamily: "Inter, Arial", fontSize: "15px", color: locked ? "#5d7782" : "#06131c", fontStyle: "bold",
      }));
      const mark = done ? "✓ superato" : isCurrent ? "▶ sei qui" : locked ? "bloccato" : "raggiunto";
      modal.add(this.add.text(towerX + 36, y - 8, mark, {
        fontFamily: "Inter, Arial", fontSize: "12px", color: locked ? "#5d7782" : "#06131c", fontStyle: "bold",
      }));
      if (isCurrent) {
        modal.add(this.add.circle(towerX + 150, y, 12, 0xf6c85f, 1).setStrokeStyle(2, 0xffe6a0, 0.9));
        modal.add(this.add.text(towerX + 150, y, "E", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#06131c", fontStyle: "bold" }).setOrigin(0.5));
      }
    }
    modal.add(this.add.text(towerX - 40, baseY + 30, "VETTA 8  ·  PARTENZA 1", { fontFamily: "Inter, Arial", fontSize: "11px", color: "#7da2af" }).setOrigin(0.5, 0));

    // --- Stats panel ---
    const statsX = 700;
    const statsY = 232;
    modal.add(this.add.rectangle(statsX, statsY, 470, 220, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.4));
    modal.add(this.add.text(statsX + 24, statsY + 20, `Livello attuale: ${currentLevel}/8`, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f6c85f", fontStyle: "bold" }));
    modal.add(this.add.text(statsX + 24, statsY + 54, `Record raggiunto: ${unlocked}/8`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9" }));
    modal.add(this.add.text(statsX + 24, statsY + 92, "Vite:", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#d9eaf1" }));
    for (let i = 0; i < maxLives; i += 1) {
      modal.add(this.add.text(statsX + 96 + i * 34, statsY + 88, i < lives ? "♥" : "♡", {
        fontFamily: "Inter, Arial", fontSize: "26px", color: i < lives ? "#ff6b6b" : "#4a5a64", fontStyle: "bold",
      }));
    }
    modal.add(this.add.text(statsX + 24, statsY + 132, `Punteggio: ${score}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9" }));
    modal.add(this.add.text(statsX + 24, statsY + 166, resumable
      ? "Riprendi da dove eri: la torre ricorda livello, vite e punti."
      : "Nessuna scalata in corso: parti dal livello 1.", {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0", wordWrap: { width: 420 },
    }));

    // --- Actions ---
    const close = (): void => modal.destroy(true);
    if (resumable && run) {
      modal.add(new Button(this, statsX + 130, 510, "Riprendi la scalata", () => { close(); this.resumeProgressiveMission(); }, {
        width: 300, height: 56, fill: 0x1f5a51, stroke: 0xf6c85f, fontSize: 18, soundKey: "progressiveStep",
      }));
      modal.add(new Button(this, statsX + 360, 510, "Azzera", () => { close(); this.confirmProgressiveReset(run); }, {
        width: 130, height: 56, fill: 0x3a2525, stroke: 0xf6c85f, fontSize: 14,
      }));
    } else {
      modal.add(new Button(this, statsX + 180, 510, "Inizia la scalata", () => { close(); this.startProgressiveMission(); }, {
        width: 380, height: 56, fill: 0x173b36, stroke: 0x6be7d6, fontSize: 18, soundKey: "progressiveStep",
      }));
    }
    modal.add(new Button(this, 180, 660, "Indietro", close, { width: 180, height: 46, fill: 0x263743 }));
  }

  /**
   * "Palestra": a supporting drawer gathering every practice mode (quick
   * adventure, the Tower, warm-up, per-subject drills). Framed as support for the
   * Story — none of these replace the campaign, they prepare and reinforce it.
   */
  private openPalestraDrawer(): void {
    if (this.transitioning) return;
    saveSystem.load();
    const missionRun = saveSystem.getProceduralMissionRun();
    const progressiveRun = saveSystem.getProceduralProgressiveRun();
    const trainingRun = saveSystem.getProceduralTrainingRun();
    const missionState = this.isResumable(missionRun)
      ? `In corso · ${missionRun?.solvedPuzzleIds.length ?? 0} risolte`
      : "Una stanza nuova pronta";
    const scalataState = this.isResumable(progressiveRun)
      ? `Piano ${progressiveRun?.progressive?.currentLevel ?? 1} · record ${progressiveRun?.progressive?.unlockedLevel ?? 1}`
      : "Parti dal piano 1";

    const modal = this.add.container(0, 0).setDepth(1500);
    const close = (): void => modal.destroy(true);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
    modal.add(this.add.rectangle(640, 360, 1120, 590, 0x07151d, 0.99).setStrokeStyle(2, 0xf6c85f, 0.6));
    modal.add(this.add.rectangle(110, 92, 5, 44, 0xf6c85f, 0.95).setOrigin(0));
    modal.add(this.add.text(124, 92, "🏋 Palestra", { fontFamily: "Inter, Arial", fontSize: "34px", color: "#f5fbff", fontStyle: "bold" }));
    modal.add(this.add.text(124, 138, "Allenamento di supporto: serve a prepararti e rinforzarti per la Storia. Nessuna di queste modalità la sostituisce — la rendono più giocosa, impegnativa e alla tua portata.", {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", wordWrap: { width: 1000 }, lineSpacing: 4,
    }));

    const card = (x: number, accent: number, icon: string, title: string, tag: string, state: string, action: () => void): void => {
      const w = 320;
      const h = 150;
      const topY = 300;
      const cx = x + w / 2;
      const cy = topY + h / 2;
      modal.add(this.add.rectangle(cx, cy, w, h, 0x0c1d2a, 0.95).setStrokeStyle(2, accent, 0.6));
      modal.add(this.add.rectangle(cx, topY + 3, w, 5, accent, 0.95));
      modal.add(this.add.text(x + 20, topY + 18, icon, { fontFamily: "Inter, Arial", fontSize: "30px", color: "#ffffff" }));
      modal.add(this.add.text(x + 64, topY + 24, title, { fontFamily: "Inter, Arial", fontSize: "19px", color: "#f5fbff", fontStyle: "bold" }));
      modal.add(this.add.text(x + 20, topY + 66, tag, { fontFamily: "Inter, Arial", fontSize: "12px", color: Phaser.Display.Color.IntegerToColor(accent).rgba, wordWrap: { width: w - 40 } }));
      modal.add(this.add.text(x + 20, topY + 98, state, { fontFamily: "Inter, Arial", fontSize: "11px", color: "#9aaab0", wordWrap: { width: w - 40 } }));
      const hit = this.add.rectangle(cx, cy, w, h, 0x000000, 0.001).setInteractive({ useHandCursor: true });
      hit.on("pointerover", () => hit.setScale(1.01)).on("pointerout", () => hit.setScale(1));
      hit.on("pointerup", () => { audioManager.play("missionStart"); close(); action(); });
      modal.add(hit);
    };
    card(150, 0x6be7d6, "🎯", "Avventura veloce", "una stanza nuova, gioco libero per esplorare", missionState, () => this.resumeMissionGame());
    card(490, 0xff8f6b, "🗼", "La Torre", "sfida infinita L1→8: il banco di prova dopo la Storia", scalataState, () => this.showScalataTower());
    card(830, 0xf6c85f, "🧠", "Riscaldamento", "scalda logica e memoria prima di un capitolo", "Palestra mentale", () => this.openMenuScene("LogicGymScene", "Non sono riuscito ad aprire il riscaldamento. Riprova tra un istante."));

    modal.add(this.add.text(150, 486, "Allenamento mirato per materia — il livello si adatta a te", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold" }));
    focusOptions.forEach((focus, index) => {
      const col = index % 4;
      const row = Math.floor(index / 4);
      modal.add(new Button(this, 236 + col * 150, 522 + row * 46, focus.label.replace("Focus ", ""), () => { close(); this.startFocusTraining(focus.id); }, {
        width: 142, height: 40, fontSize: 12,
        fill: this.isSameFocus(trainingRun, focus.id) ? 0x1f5a51 : 0x173b36,
        stroke: this.isSameFocus(trainingRun, focus.id) ? 0xf6c85f : 0x6be7d6,
      }));
    });

    modal.add(new Button(this, 268, 620, "📖 Codex", () => {
      close();
      this.openMenuScene("CodexScene", "Non sono riuscito ad aprire il Codex. Riprova tra un istante.");
    }, { width: 196, height: 44, fontSize: 14, fill: 0x1f4a44, stroke: 0x6be7d6 }));
    modal.add(new Button(this, 476, 620, "🕹️ Esplora", () => {
      close();
      this.openMenuScene("ExplorableRoomScene", "Non sono riuscito ad aprire l'anteprima. Riprova tra un istante.");
    }, { width: 190, height: 44, fontSize: 14, fill: 0x24344a, stroke: 0x7ad7ff }));
    modal.add(new Button(this, 700, 620, "🛍️ Bottega", () => {
      close();
      this.openMenuScene("RewardShopScene", "Non sono riuscito ad aprire la Bottega. Riprova tra un istante.");
    }, { width: 196, height: 44, fontSize: 14, fill: 0x3a3220, stroke: 0xf6c85f }));
    modal.add(this.add.text(132, 596, "Studio, anteprime e ricompense:", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9fb6c2" }));

    modal.add(new Button(this, 1010, 620, "Chiudi", close, { width: 180, height: 44, fill: 0x263743 }));
  }

  private startProgressiveMission(): void {
    if (this.transitioning) return;
    this.transitioning = true;
    const clearBusy = this.showBusy("Preparo la scalata progressiva...");
    saveSystem.load();
    this.time.delayedCall(40, () => {
      try {
        saveSystem.pauseActiveProceduralRun();
        this.createProgressiveRun(1, []);
        void startScene(this, "ProceduralMissionScene").catch(() => {
          clearBusy();
          this.transitioning = false;
          this.showMenuError("Non sono riuscito ad aprire la scalata. Riprova tra un istante.");
        });
      } catch {
        clearBusy();
        this.transitioning = false;
        this.showMenuError("Non sono riuscito a generare la scalata. Riprova con un nuovo seed.");
      }
    });
  }

  private resumeProgressiveMission(): void {
    if (this.transitioning) return;
    saveSystem.load();
    const run = saveSystem.getProceduralProgressiveRun();
    if (!this.isResumable(run)) {
      this.startProgressiveMission();
      return;
    }
    this.transitioning = true;
    this.setMenuButtonsEnabled(false);
    saveSystem.pauseActiveProceduralRun();
    saveSystem.setActiveProceduralRun(run);
    void startScene(this, "ProceduralMissionScene").catch(() => {
      this.transitioning = false;
      this.setMenuButtonsEnabled(true);
      this.showMenuError("Non sono riuscito a riprendere la scalata. Riprova tra un istante.");
    });
  }

  private confirmProgressiveReset(run: ProceduralRunSave): void {
    if (this.transitioning) return;
    this.setMenuButtonsEnabled(false);
    const currentLevel = run.progressive?.currentLevel ?? run.difficulty;
    const completedLevels = run.progressive?.results.filter((result) => result.completed).length ?? 0;
    const modal = this.add.container(0, 0).setDepth(1000);
    const blocker = this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.86).setInteractive();
    const panel = this.add.rectangle(640, 360, 590, 300, 0x07151d, 0.99).setStrokeStyle(2, 0xf6c85f, 0.78);
    const title = this.add.text(380, 238, "Ripartire dal livello 1?", {
      fontFamily: "Inter, Arial",
      fontSize: "27px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
    const detail = this.add.text(380, 292, `Scalata corrente: livello ${currentLevel}/8, livelli completati ${completedLevels}.\n\nVerranno azzerati soltanto progressi, risultati, punti e timer della scalata.`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 520 },
      lineSpacing: 6,
    });
    const cancel = new Button(this, 510, 454, "Annulla", () => {
      modal.destroy(true);
      this.setMenuButtonsEnabled(true);
    }, { width: 190, height: 50, fill: 0x263743, fontSize: 16 });
    const confirm = new Button(this, 770, 454, "Azzera e ricomincia", () => {
      modal.destroy(true);
      this.resetProgressiveMissionFromScratch();
    }, { width: 250, height: 50, fill: 0x3a2525, stroke: 0xf6c85f, fontSize: 16 });
    modal.add([blocker, panel, title, detail, cancel, confirm]);
  }

  private resetProgressiveMissionFromScratch(): void {
    if (this.transitioning) return;
    this.transitioning = true;
    const clearBusy = this.showBusy("Azzero la scalata e preparo il livello 1...");
    this.time.delayedCall(40, () => {
      try {
        this.createProgressiveRun(1, []);
        const resetRun = saveSystem.getProceduralProgressiveRun();
        if (!resetRun || resetRun.difficulty !== 1 || resetRun.progressive?.currentLevel !== 1 || resetRun.progressive.results.length !== 0) {
          throw new Error("Reset scalata non coerente");
        }
        saveSystem.setActiveProceduralRun(resetRun);
        void startScene(this, "ProceduralMissionScene").catch(() => {
          clearBusy();
          this.transitioning = false;
          this.showMenuError("Reset completato, ma non sono riuscito ad aprire il livello 1.");
        });
      } catch {
        clearBusy();
        this.transitioning = false;
        this.showMenuError("Non sono riuscito ad azzerare completamente la scalata.");
      }
    });
  }

  private showBusy(label: string): () => void {
    this.setMenuButtonsEnabled(false);
    const blocker = this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.28).setDepth(900);
    const panel = this.add.rectangle(640, 360, 430, 112, 0x09151f, 0.96).setStrokeStyle(2, 0x6be7d6, 0.65).setDepth(901);
    const text = this.add.text(640, 346, label, {
      fontFamily: "Inter, Arial",
      fontSize: "21px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5).setDepth(902);
    const detail = this.add.text(640, 382, "Seed, solver e validator stanno preparando contenuti risolvibili.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
    }).setOrigin(0.5).setDepth(902);
    blocker.setInteractive();
    this.tweens.add({ targets: [panel, text, detail], alpha: { from: 0.78, to: 1 }, duration: 180, yoyo: true, repeat: -1 });
    return () => {
      this.tweens.killTweensOf([panel, text, detail]);
      blocker.destroy();
      panel.destroy();
      text.destroy();
      detail.destroy();
      this.setMenuButtonsEnabled(true);
    };
  }

  private setMenuButtonsEnabled(enabled: boolean): void {
    this.children.list.forEach((child) => {
      if (child instanceof Button) {
        child.setEnabled(enabled);
      }
    });
  }

  private showMenuError(message: string): void {
    const panel = this.add.rectangle(640, 664, 560, 44, 0x1f1414, 0.94).setStrokeStyle(1, 0xff8f8f, 0.58).setDepth(850);
    const text = this.add.text(640, 664, message, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
    }).setOrigin(0.5).setDepth(851);
    this.time.delayedCall(2400, () => {
      panel.destroy();
      text.destroy();
    });
  }

  private createProceduralRun(
    focus: ProceduralSpecialization = "libera",
    difficulty: DifficultyLevel = this.activeDifficulty(),
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

  private createProgressiveRun(level: DifficultyLevel, previousResults: ProgressiveLevelResult[]): void {
    const levelFocus = progressiveMissionBuilder.focusForLevel(level);
    const base = proceduralDirector.generateFreshMission(level, [levelFocus]);
    const mission = progressiveMissionBuilder.buildLevelMission(base, level);
    const createdAt = new Date().toISOString();
    const objectiveCount = Math.max(1, mission.objectives.length);
    const timeLimitMs = progressiveMissionBuilder.timeLimitMs(level, objectiveCount);
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: level,
      focus: ["progressiva", levelFocus],
      mode: "progressive",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: proceduralRunRules.maxLives,
      maxLives: proceduralRunRules.maxLives,
      timeLimitMs,
      timerState: "preparing",
      createdAt,
      activeElapsedMs: 0,
      startedAt: createdAt,
      progressive: {
        currentLevel: level,
        unlockedLevel: level,
        maxLevel: 8,
        levelStartedAt: createdAt,
        levelTimeLimitMs: timeLimitMs,
        levelDeadlineAt: createdAt,
        results: previousResults,
      },
    };
    saveSystem.setProceduralRun(run);
  }

  private activeDifficulty(): DifficultyLevel {
    return this.selectedDifficulty ?? this.loadSelectedDifficulty();
  }

  private loadSelectedDifficulty(): DifficultyLevel {
    try {
      const stored = localStorage.getItem(TRAINING_DIFFICULTY_KEY);
      const playerStored = localStorage.getItem(this.trainingDifficultyKey());
      const effectiveStored = playerStored ?? stored;
      const parsed = Number(effectiveStored);
      if (Number.isFinite(parsed)) {
        return difficultyModel.normalize(parsed);
      }
    } catch {
      // localStorage can be unavailable in restricted browser contexts.
    }
    return this.recommendedDifficulty();
  }

  private selectDifficulty(level: DifficultyLevel): void {
    this.selectedDifficulty = level;
    this.userPickedDifficulty = true;
    try {
      localStorage.setItem(TRAINING_DIFFICULTY_KEY, String(level));
      localStorage.setItem(this.trainingDifficultyKey(), String(level));
    } catch {
      // The current scene state is still enough for this session.
    }
    this.scene.restart();
  }

  /**
   * Per-subject recommendation: anchors on the highest difficulty actually
   * practised in that focus and nudges ±1 from its recent grade. Falls back to
   * the global recommendation when the subject has no history yet.
   */
  private recommendedDifficultyForFocus(focus: ProceduralSpecialization): DifficultyLevel {
    const records = Object.values(saveSystem.data.trainingRecords ?? {}).filter(
      (record) => record.focus === focus && record.runs > 0,
    );
    if (records.length === 0) {
      return this.recommendedDifficulty();
    }
    const top = records.reduce((best, record) => (record.difficulty > best.difficulty ? record : best));
    const grade = top.lastGrade > 0 ? top.lastGrade : top.bestGrade;
    let level = top.difficulty;
    if (grade >= 8.5 && top.difficulty < 8) {
      level = top.difficulty + 1;
    } else if (grade > 0 && grade < 6.5 && top.difficulty > 1) {
      level = top.difficulty - 1;
    }
    return difficultyModel.normalize(level);
  }

  private recommendedDifficulty(): DifficultyLevel {
    const run = saveSystem.getProceduralMissionRun() ?? saveSystem.data.proceduralRun;
    if (!run) {
      return 1;
    }
    const report = playerSystem.playerReport();
    const recentCutoff = Date.now() - 30 * 24 * 60 * 60 * 1000;
    const recurringMistake = Math.max(0, ...Object.values(saveSystem.data.learningMemory ?? {})
      .filter((item) => new Date(item.lastAt).getTime() >= recentCutoff)
      .map((item) => item.count));
    const base = run.difficulty;
    if (report.globalGrade >= 8.5 && recurringMistake < 4) {
      return Math.min(8, base + 1) as DifficultyLevel;
    }
    if ((report.globalGrade > 0 && report.globalGrade < 6.5) || recurringMistake >= 7) {
      return Math.max(1, base - 1) as DifficultyLevel;
    }
    return base;
  }

  private isResumable(run: ProceduralRunSave | undefined): run is ProceduralRunSave {
    if (!run || run.completedAt || run.failedAt) {
      return false;
    }
    const mode = proceduralRunRules.modeFor(run);
    if ((mode === "mission" || mode === "progressive") && (run.lives ?? proceduralRunRules.maxLives) <= 0) {
      return false;
    }
    return true;
  }

  private isSameFocus(run: ProceduralRunSave | undefined, focus: ProceduralSpecialization): boolean {
    return this.isResumable(run) && proceduralRunRules.focusFor(run) === focus;
  }

  private resumeLabel(run: ProceduralRunSave | undefined, expectedMode: "mission" | "training" | "progressive"): string {
    if (!run) {
      if (expectedMode === "mission") return "nessuna missione salvata";
      if (expectedMode === "training") return "nessun focus sospeso";
      return "livello 1 non iniziato";
    }
    const mode = proceduralRunRules.modeFor(run);
    if (mode !== expectedMode) {
      return "nessun percorso compatibile";
    }
    if (run.completedAt) {
      return `${expectedMode === "training" ? "completato" : "completata"} - L${run.difficulty}`;
    }
    if (run.failedAt) {
      return `${expectedMode === "mission" ? "fallita" : "interrotto"} - puoi iniziare di nuovo`;
    }
    const solved = run.solvedPuzzleIds.length;
    const total = Math.max(1, run.mission.objectives.length);
    const focus = proceduralRunRules.focusFor(run);
    const subject = expectedMode === "training" ? ` ${proceduralScoring.domainLabel(focus)}` : expectedMode === "progressive" ? " progressiva" : "";
    const time = (expectedMode === "mission" || expectedMode === "progressive") && run.pausedRemainingMs
      ? ` | tempo in pausa ${formatDuration(run.pausedRemainingMs)}`
      : "";
    return `in pausa${subject} L${run.difficulty} | ${solved}/${total}${time}`;
  }

  private trainingDifficultyKey(): string {
    return `${TRAINING_DIFFICULTY_KEY}:${playerSystem.getActivePlayer().id}`;
  }

  private scheduleResponsivenessWarmup(): void {
    const warmup = (): void => {
      this.warmRuntimeTextures();
      prefetchCoreScenes(this);
      audioManager.preloadEssentialAudio();
      audioManager.preloadAmbientAudio();
    };
    if (typeof window !== "undefined" && "requestIdleCallback" in window) {
      window.requestIdleCallback(warmup, { timeout: 900 });
    } else {
      this.time.delayedCall(120, warmup);
    }
  }

  private warmRuntimeTextures(): void {
    const keys = [
      "bg-lab-painted",
      "bg-archive-painted",
      "bg-factory-painted",
      "bg-greenhouse-painted",
      "console-lab",
      "holo-ring",
      "soft-glow",
      "spark-core",
    ];
    const warmers = keys
      .filter((key) => this.textures.exists(key))
      .map((key, index) => this.add.image(-180 - index * 6, -180, key).setAlpha(0.01).setScale(0.04));
    if (this.textures.exists("eli-atlas")) {
      warmers.push(this.add.image(-260, -180, "eli-atlas", "particle-diamond").setAlpha(0.01).setScale(0.04));
      warmers.push(this.add.image(-270, -180, "eli-atlas", "robot-core").setAlpha(0.01).setScale(0.04));
    }
    this.time.delayedCall(180, () => warmers.forEach((item) => item.destroy()));
  }
}
