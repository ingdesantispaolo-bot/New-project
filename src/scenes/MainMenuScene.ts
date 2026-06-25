import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { buildInfo } from "../core/BuildInfo";
import { mapLayoutSystem, type MapLayoutRect } from "../core/MapLayoutSystem";
import { playerSystem } from "../core/PlayerSystem";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { prefetchCoreScenes, startScene } from "../core/SceneNavigator";
import { formatDuration, proceduralScoring } from "../core/ProceduralScoring";
import { difficultyModel } from "../procedural/DifficultyModel";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { progressiveMissionBuilder } from "../procedural/ProgressiveMissionBuilder";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization, ProgressiveLevelResult } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

const focusOptions: Array<{ id: ProceduralSpecialization; label: string }> = [
  { id: "matematica", label: "Focus matematica" },
  { id: "italiano", label: "Focus italiano" },
  { id: "inglese", label: "Focus inglese" },
  { id: "elettronica", label: "Focus circuiti" },
  { id: "coding", label: "Focus coding" },
  { id: "musica", label: "Focus musica" },
];

const TRAINING_DIFFICULTY_KEY = "eliQuest.trainingDifficulty";

export class MainMenuScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getMainMenuLayout();
  private selectedDifficulty?: DifficultyLevel;
  private userPickedDifficulty = false;
  private transitioning = false;

  constructor() {
    super("MainMenuScene");
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

    const title = this.rect("menu:title", { x: 96, y: 92 });
    const subtitle = this.rect("menu:subtitle", { x: 102, y: 172 });
    const copy = this.rect("menu:copy", { x: 102, y: 226, width: 620 });
    this.add.text(title.x, title.y, "ELI QUEST", {
      fontFamily: "Inter, Arial",
      fontSize: "76px",
      color: "#f5fbff",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 6, color: "#000000", blur: 12, fill: true },
    });
    this.add.text(subtitle.x, subtitle.y, "Accademia delle Missioni", {
      fontFamily: "Inter, Arial",
      fontSize: "26px",
      color: "#9ff5e9",
    });
    this.add.text(copy.x, copy.y, "Una stanza sempre diversa. Stesso metodo: osserva, formula un'ipotesi, prova con precisione.", {
      fontFamily: "Inter, Arial",
      fontSize: "21px",
      color: "#c7dce7",
      wordWrap: { width: copy.width ?? 620 },
      lineSpacing: 5,
    });
    this.add.text(102, 300, `Giocatore: ${playerSystem.getActivePlayer().name}`, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.text(102, 326, this.resumeCompactSummary(missionRun, trainingRun, progressiveRun), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 610 },
    });

    const newMission = this.rect("menu:newMission", { x: 250, y: 374, width: 260 });
    new Button(this, newMission.x, newMission.y, "La Storia", () => {
      this.openMenuScene("CampaignScene", "Non sono riuscito ad aprire la storia. Riprova tra un istante.");
    }, { width: newMission.width, fill: 0x1f5a51, stroke: 0xf6c85f, soundKey: "missionStart" });
    new Button(this, 552, 374, "Scalata", () => {
      this.showScalataTower();
    }, {
      width: this.isResumable(progressiveRun) ? 206 : 302,
      height: 46,
      fill: this.isResumable(progressiveRun) ? 0x1f5a51 : 0x173b36,
      stroke: this.isResumable(progressiveRun) ? 0xf6c85f : 0x6be7d6,
      fontSize: 16,
      soundKey: "progressiveStep",
    });
    if (this.isResumable(progressiveRun)) {
      new Button(this, 704, 374, "Reset", () => this.confirmProgressiveReset(progressiveRun), {
        width: 96,
        height: 46,
        fill: 0x3a2525,
        stroke: 0xf6c85f,
        fontSize: 11,
      });
    }
    const continueButton = this.rect("menu:continue", { x: 250, y: 448, width: 260 });
    new Button(this, continueButton.x, continueButton.y, this.isResumable(missionRun) ? "Riprendi Missione Rapida" : "Missione Rapida", () => {
      this.resumeMissionGame();
    }, {
      width: continueButton.width,
      fill: this.isResumable(missionRun) ? 0x1f5a51 : 0x263743,
      stroke: this.isResumable(missionRun) ? 0xf6c85f : 0x6be7d6,
    });
    new Button(this, 552, 448, "Atlante matematica", () => this.openMenuScene("MathStudyScene", "Non sono riuscito ad aprire l'atlante. Riprova tra un istante."), {
      width: 206,
      height: 46,
      fill: 0x263743,
      fontSize: 15,
    });
    const journal = this.rect("menu:journal", { x: 250, y: 522, width: 260 });
    new Button(this, journal.x, journal.y, "Diario Seed", () => this.openMenuScene("JournalScene", "Non sono riuscito ad aprire il diario. Riprova tra un istante."), { width: journal.width });
    const procedural = this.rect("menu:procedural", { x: 250, y: 596, width: 300 });
    new Button(this, procedural.x, procedural.y, "Quadro Docente / Genitore", () => this.openMenuScene("TeacherDashboardScene", "Non sono riuscito ad aprire il quadro docente. Riprova tra un istante."), {
      width: procedural.width,
      fill: 0x2a3550,
      stroke: 0x9f8cff,
      fontSize: 16,
    });
    new Button(this, 552, 522, "Registro", () => this.openMenuScene("PlayerReportScene", "Non sono riuscito ad aprire il registro. Riprova tra un istante."), {
      width: 206,
      height: 46,
      fill: 0x263743,
      fontSize: 16,
    });
    new Button(this, 552, 596, "Classifiche", () => this.openMenuScene("LeaderboardScene", "Non sono riuscito ad aprire le classifiche. Riprova tra un istante."), {
      width: 206,
      height: 46,
      fill: 0x263743,
      fontSize: 16,
    });

    VisualKit.glassPanel(this, 792, 128, 430, 500, "academy", 0.72);
    this.add.text(828, 164, "Allenamento focus", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(828, 202, "Scegli la materia: ogni percorso parte dal livello consigliato dai tuoi risultati. Tocca 1-8 per forzarlo. Qui non perdi vite: contano tempo, precisione e aiuti.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7dce7",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    });
    if (!this.userPickedDifficulty) {
      const abbrev: Partial<Record<ProceduralSpecialization, string>> = {
        matematica: "Mat", italiano: "Ita", inglese: "Ing", elettronica: "Cir", coding: "Cod", musica: "Mus",
      };
      const perFocus = focusOptions
        .map((focus) => `${abbrev[focus.id] ?? focus.label} L${this.recommendedDifficultyForFocus(focus.id)}`)
        .join(" · ");
      this.add.text(828, 246, `Consigliato per materia: ${perFocus}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9ff5e9",
        wordWrap: { width: 360 },
      });
    }
    this.add.text(828, 266, `Livello allenamento selezionato: ${selected}/8`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    if (this.isResumable(trainingRun)) {
      new Button(this, 1092, 272, "Riprendi focus", () => {
        this.resumeFocusTraining();
      }, {
        width: 170,
        height: 38,
        fill: 0x1f5a51,
        stroke: 0xf6c85f,
        fontSize: 13,
      });
    }
    this.add.text(828, 290, difficultyModel.describe(selected), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    });
    focusOptions.forEach((focus, index) => {
      const x = 884 + (index % 3) * 122;
      const y = 354 + Math.floor(index / 3) * 58;
      new Button(this, x, y, focus.label, () => {
        this.startFocusTraining(focus.id);
      }, {
        width: 114,
        height: 44,
        fill: this.isSameFocus(trainingRun, focus.id) ? 0x1f5a51 : 0x173b36,
        stroke: this.isSameFocus(trainingRun, focus.id) ? 0xf6c85f : 0x6be7d6,
        fontSize: 11,
      });
    });

    this.add.text(828, 520, "Livello allenamento", {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(828, 548, `Consigliato: ${recommended}/8. Puoi scegliere liberamente da 1 a 8.`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    });
    for (let level = 1; level <= 8; level += 1) {
      new Button(this, 852 + (level - 1) * 45, 598, String(level), () => {
        this.selectDifficulty(level as DifficultyLevel);
      }, {
        width: 38,
        height: 36,
        fill: selected === level ? 0x1f5a51 : 0x142736,
        stroke: selected === level ? 0xf6c85f : 0x6be7d6,
        fontSize: 14,
      });
    }

    this.add.text(828, 642, `Seed, solver e validator | Livello scelto ${selected}/8`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#7da2af",
      wordWrap: { width: 380 },
    });
    this.add.text(1210, 690, `build ${buildInfo.ref}`, {
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
    modal.add(this.add.rectangle(640, 360, 1180, 648, 0x07151d, 0.99).setStrokeStyle(2, 0x6be7d6, 0.6));
    modal.add(this.add.text(120, 70, "La Scalata", { fontFamily: "Inter, Arial", fontSize: "38px", color: "#f5fbff", fontStyle: "bold" }));
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

  private resumeCompactSummary(
    missionRun: ProceduralRunSave | undefined,
    trainingRun: ProceduralRunSave | undefined,
    progressiveRun: ProceduralRunSave | undefined,
  ): string {
    const parts: string[] = [];
    if (this.isResumable(missionRun)) {
      parts.push(`Missione L${missionRun.difficulty} ${missionRun.solvedPuzzleIds.length}/${missionRun.mission.objectives.length}`);
    }
    if (this.isResumable(progressiveRun)) {
      const level = progressiveRun.progressive?.currentLevel ?? progressiveRun.difficulty;
      parts.push(`Scalata L${level} ${progressiveRun.solvedPuzzleIds.length}/${progressiveRun.mission.objectives.length}`);
    }
    if (this.isResumable(trainingRun)) {
      parts.push(`Focus ${proceduralScoring.domainLabel(proceduralRunRules.focusFor(trainingRun))} L${trainingRun.difficulty}`);
    }
    if (parts.length === 0) {
      return "Nessun percorso sospeso: scegli missione, scalata o focus.";
    }
    const summary = `In pausa: ${parts.join("  |  ")}`;
    return summary.length > 84 ? "In pausa: percorsi salvati. Usa i pulsanti evidenziati per riprendere." : summary;
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
      "painted-circuit-panel",
      "painted-terminal",
      "painted-robot-dock",
      "painted-message-console",
      "painted-door-lab",
      "painted-nora-core",
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
