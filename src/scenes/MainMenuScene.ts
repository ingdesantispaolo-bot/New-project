import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { buildInfo } from "../core/BuildInfo";
import { campaignSystem } from "../core/CampaignSystem";
import { noraCompanion } from "../core/NoraCompanion";
import { noraChip } from "../ui/NoraChip";
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
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
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
  private noraGreeted = false;

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
    // Neon accent rule framing the hero header.
    this.add.image(86, 168, "soft-glow").setTint(0x6be7d6).setAlpha(0.12).setScale(1.5);
    this.add.rectangle(82, 96, 4, 150, 0x6be7d6, 0.7).setOrigin(0);
    this.add.rectangle(82, 96, 4, 40, 0xf6c85f, 0.85).setOrigin(0);
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

    // --- PERCORSI DI GIOCO: tre carte distinte e caratterizzate ---
    this.add.text(44, 352, "SCEGLI IL TUO PERCORSO", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    const cardY = 376;
    const cardProgress = campaignSystem.getProgress();
    const storyState = campaignSystem.isCampaignComplete()
      ? "Storia completata ✓"
      : `Capitolo ${campaignSystem.getActiveChapter().number}/${cardProgress.total}`;
    const missionState = this.isResumable(missionRun)
      ? `In corso · ${missionRun?.solvedPuzzleIds.length ?? 0} console risolte`
      : "Nuova stanza pronta";
    const scalataState = this.isResumable(progressiveRun)
      ? `Piano ${progressiveRun?.progressive?.currentLevel ?? progressiveRun?.difficulty ?? 1} · record ${progressiveRun?.progressive?.unlockedLevel ?? 1}`
      : "Parti dal piano 1";

    const cw = 232;
    const ch = 158;
    const pathCard = (
      x: number,
      accent: number,
      icon: string,
      cardTitle: string,
      tag: string,
      desc: string,
      state: string,
      primary: string,
      action: () => void,
      reset?: () => void,
    ): void => {
      const card = this.add.container(x, cardY);
      const accentHex = Phaser.Display.Color.IntegerToColor(accent).rgba;
      const border = this.add.rectangle(0, 0, cw, ch, 0x0c1d2a, 0.92).setOrigin(0).setStrokeStyle(2, accent, 0.55);
      const bar = this.add.rectangle(0, 0, cw, 5, accent, 0.95).setOrigin(0);
      const iconText = this.add.text(16, 12, icon, { fontFamily: "Inter, Arial", fontSize: "30px", color: "#ffffff" });
      const titleText = this.add.text(58, 14, cardTitle, { fontFamily: "Inter, Arial", fontSize: "19px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: cw - 66 } });
      const tagText = this.add.text(58, 42, tag, { fontFamily: "Inter, Arial", fontSize: "10px", color: accentHex, fontStyle: "bold" });
      const descText = this.add.text(16, 64, desc, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: cw - 32 }, lineSpacing: 2 });
      const stateChip = this.add.rectangle(16, 98, cw - 32, 22, 0x07151d, 0.7).setOrigin(0).setStrokeStyle(1, accent, 0.25);
      const stateText = this.add.text(26, 102, state, { fontFamily: "Inter, Arial", fontSize: "11px", color: accentHex, fontStyle: "bold", wordWrap: { width: cw - 52 } });
      const cta = this.add.rectangle(cw / 2, 142, cw - 28, 30, accent, 0.16).setStrokeStyle(1.5, accent, 0.8);
      const ctaText = this.add.text(cw / 2, 142, `${primary}  ▸`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5);
      const hit = this.add.rectangle(cw / 2, ch / 2, cw, ch, 0x000000, 0.001).setInteractive({ useHandCursor: true });
      card.add([border, bar, iconText, titleText, tagText, descText, stateChip, stateText, cta, ctaText, hit]);

      let pressed = false;
      const setHover = (on: boolean): void => {
        border.setStrokeStyle(on ? 3 : 2, accent, on ? 1 : 0.55);
        cta.setFillStyle(accent, on ? 0.3 : 0.16);
        this.tweens.killTweensOf(card);
        this.tweens.add({ targets: card, scaleX: on ? 1.02 : 1, scaleY: on ? 1.02 : 1, duration: 120 });
      };
      hit.on("pointerover", () => setHover(true))
        .on("pointerout", () => { pressed = false; setHover(false); })
        .on("pointerdown", () => { pressed = true; })
        .on("pointerup", () => { if (pressed) { audioManager.play("missionStart"); action(); } pressed = false; })
        .on("pointerupoutside", () => { pressed = false; });

      if (reset) {
        const rx = cw - 39;
        const ry = 22;
        const resetBtn = this.add.rectangle(rx, ry, 58, 22, 0x3a2525, 0.92).setStrokeStyle(1, 0xf6c85f, 0.6).setInteractive({ useHandCursor: true });
        const resetTxt = this.add.text(rx, ry, "Reset", { fontFamily: "Inter, Arial", fontSize: "10px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5);
        resetBtn.on("pointerup", () => { audioManager.play("uiSelect"); reset(); });
        card.add([resetBtn, resetTxt]);
      }
    };

    pathCard(44, 0xf6c85f, "📖", "La Storia", "STORIA · NARRATIVA",
      "Segui la trama di NORA, capitolo dopo capitolo.", storyState,
      "Entra", () => this.openMenuScene("CampaignScene", "Non sono riuscito ad aprire la storia. Riprova tra un istante."));
    pathCard(292, 0x6be7d6, "🎯", "Missione Rapida", "PROCEDURALE · LIBERA",
      "Una stanza nuova ogni volta, in ordine libero.", missionState,
      this.isResumable(missionRun) ? "Riprendi" : "Gioca", () => this.resumeMissionGame());
    pathCard(540, 0xff8f6b, "🗼", "Scalata", "SFIDA · A LIVELLI",
      "Sali di livello con punti e vite, senza fine.", scalataState,
      this.isResumable(progressiveRun) ? "Riprendi" : "Sali", () => this.showScalataTower(),
      this.isResumable(progressiveRun) ? () => this.confirmProgressiveReset(progressiveRun) : undefined);

    // --- STRUMENTI & PROGRESSI: chiaramente separati dai percorsi ---
    this.add.text(44, 556, "STRUMENTI & PROGRESSI", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#7d93a0",
      fontStyle: "bold",
    });
    const tool = (cx: number, cy: number, label: string, sceneKey: string, fill = 0x263743, stroke?: number): void => {
      new Button(this, cx, cy, label, () => this.openMenuScene(sceneKey, `Non sono riuscito ad aprire ${label}. Riprova tra un istante.`), {
        width: 172,
        height: 40,
        fontSize: 13,
        fill,
        stroke,
      });
    };
    tool(130, 584, "La tua Accademia", "AcademyScene", 0x1f5a51, 0x70d68a);
    tool(314, 584, "Atlante", "MathStudyScene");
    tool(498, 584, "🧠 Palestra Mente", "LogicGymScene", 0x2a1f3a, 0xf6c85f);
    tool(682, 584, "NORA", "NoraScene", 0x173b36, 0x9ff5e9);
    tool(130, 632, "Registro", "PlayerReportScene");
    tool(314, 632, "Classifiche", "LeaderboardScene");
    tool(498, 632, "Diario", "JournalScene");
    tool(682, 632, "Quadro Docente", "TeacherDashboardScene", 0x2a3550, 0x9f8cff);

    if (!this.noraGreeted) {
      this.noraGreeted = true;
      this.time.delayedCall(600, () => noraChip.say(this, noraCompanion.greetingShort(playerSystem.getActivePlayer().name), "info"));
    }

    VisualKit.glassPanel(this, 792, 128, 430, 560, "academy", 0.72);
    this.add.text(828, 150, "🎓 Allenamento", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(1208, 156, "PERCORSO · PER MATERIA", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(1, 0);
    this.add.text(828, 192, "Percorso di esercizio: nessuna vita in gioco, contano precisione, tempo e aiuti. Scegli la materia; il livello parte dai tuoi risultati (1-8).", {
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
      this.add.text(828, 254, `Consigliato per materia: ${perFocus}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9ff5e9",
        wordWrap: { width: 340 },
        lineSpacing: 2,
      });
    }
    this.add.text(828, 306, `Livello selezionato: ${selected}/8`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    if (this.isResumable(trainingRun)) {
      new Button(this, 1102, 314, "Riprendi focus", () => {
        this.resumeFocusTraining();
      }, {
        width: 158,
        height: 38,
        fill: 0x1f5a51,
        stroke: 0xf6c85f,
        fontSize: 13,
      });
    }
    this.add.text(828, 334, difficultyModel.describe(selected), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    });
    focusOptions.forEach((focus, index) => {
      const x = 884 + (index % 3) * 122;
      const y = 416 + Math.floor(index / 3) * 58;
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

    this.add.text(828, 562, "Livello allenamento", {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(828, 590, `Consigliato: ${recommended}/8. Puoi scegliere liberamente da 1 a 8.`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    });
    for (let level = 1; level <= 8; level += 1) {
      new Button(this, 852 + (level - 1) * 45, 640, String(level), () => {
        this.selectDifficulty(level as DifficultyLevel);
      }, {
        width: 38,
        height: 36,
        fill: selected === level ? 0x1f5a51 : 0x142736,
        stroke: selected === level ? 0xf6c85f : 0x6be7d6,
        fontSize: 14,
      });
    }

    this.add.text(828, 684, `Seed, solver e validator | Livello scelto ${selected}/8`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#7da2af",
      wordWrap: { width: 380 },
    });
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
    modal.add(this.add.rectangle(640, 360, 1180, 648, 0x07151d, 0.99).setStrokeStyle(2, 0xff8f6b, 0.6));
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
