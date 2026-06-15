import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { mapLayoutSystem, type MapLayoutRect } from "../core/MapLayoutSystem";
import { playerSystem } from "../core/PlayerSystem";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { difficultyModel } from "../procedural/DifficultyModel";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

const focusOptions: Array<{ id: ProceduralSpecialization; label: string }> = [
  { id: "matematica", label: "Focus matematica" },
  { id: "italiano", label: "Focus italiano" },
  { id: "inglese", label: "Focus inglese" },
  { id: "elettronica", label: "Focus circuiti" },
  { id: "coding", label: "Focus coding" },
];

const TRAINING_DIFFICULTY_KEY = "eliQuest.trainingDifficulty";

export class MainMenuScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getMainMenuLayout();
  private selectedDifficulty?: DifficultyLevel;
  private transitioning = false;

  constructor() {
    super("MainMenuScene");
  }

  create(): void {
    saveSystem.load();
    playerSystem.load();
    this.selectedDifficulty ??= this.loadSelectedDifficulty();
    audioManager.playMusic("menuMusic");
    this.drawBackground();
    const recommended = this.recommendedDifficulty();
    const selected = this.activeDifficulty();

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

    const newMission = this.rect("menu:newMission", { x: 250, y: 374, width: 260 });
    new Button(this, newMission.x, newMission.y, "Nuova Missione", () => {
      this.startMissionGame();
    }, { width: newMission.width });
    const continueButton = this.rect("menu:continue", { x: 250, y: 448, width: 260 });
    new Button(this, continueButton.x, continueButton.y, "Continua", () => {
      saveSystem.load();
      void startScene(this, this.getContinueScene());
    }, { width: continueButton.width });
    const journal = this.rect("menu:journal", { x: 250, y: 522, width: 260 });
    new Button(this, journal.x, journal.y, "Diario Seed", () => this.scene.start("JournalScene"), { width: journal.width });
    const procedural = this.rect("menu:procedural", { x: 250, y: 596, width: 300 });
    new Button(this, procedural.x, procedural.y, "Missione Rapida", () => this.startMissionGame(), {
      width: procedural.width,
      fill: 0x173b36,
      fontSize: 18,
    });
    new Button(this, 552, 522, "Giocatori", () => {
      void startScene(this, "PlayerReportScene");
    }, {
      width: 206,
      height: 46,
      fill: 0x263743,
      fontSize: 16,
    });
    new Button(this, 552, 596, "Classifiche", () => {
      void startScene(this, "LeaderboardScene");
    }, {
      width: 206,
      height: 46,
      fill: 0x263743,
      fontSize: 16,
    });

    this.add.text(820, 166, "Allenamento focus", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(820, 204, "Scegli prima il livello, poi un focus. Qui non perdi vite: si misurano miglior tempo, voto finale e crescita della materia scelta.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#c7dce7",
      wordWrap: { width: 330 },
      lineSpacing: 5,
    });
    this.add.text(820, 266, `Livello selezionato: ${selected}/8 - ${difficultyModel.describe(selected)}.`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f6c85f",
      wordWrap: { width: 330 },
      lineSpacing: 4,
    });
    focusOptions.forEach((focus, index) => {
      const x = 908 + (index % 2) * 168;
      const y = 326 + Math.floor(index / 2) * 62;
      new Button(this, x, y, focus.label, () => {
        this.startFocusTraining(focus.id);
      }, {
        width: 150,
        height: 42,
        fill: focus.id === "libera" ? 0x263743 : 0x173b36,
        fontSize: 12,
      });
    });

    this.add.text(820, 510, "Livello allenamento", {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(820, 538, `Consigliato: ${recommended}/8. Puoi scegliere liberamente da 1 a 8; il valore resta salvato per i prossimi focus.`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 350 },
      lineSpacing: 4,
    });
    for (let level = 1; level <= 8; level += 1) {
      new Button(this, 842 + (level - 1) * 44, 606, String(level), () => {
        this.selectDifficulty(level as DifficultyLevel);
      }, {
        width: 34,
        height: 32,
        fill: selected === level ? 0x1f5a51 : 0x142736,
        stroke: selected === level ? 0xf6c85f : 0x6be7d6,
        fontSize: 14,
      });
    }

    this.add.text(884, 656, `Generazione controllata: seed, solver, validator | Livello scelto ${selected}/8`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#7da2af",
    });
    VisualKit.vignette(this);
  }

  private drawBackground(): void {
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    VisualKit.glassPanel(this, 820, 170, 360, 390, "academy", 0.5);
    VisualKit.frame(this, 790, 140, 420, 450, "academy");
    const portal = this.rect("menu:portal", { x: 998, y: 360, width: 360, height: 390 });
    this.add.circle(portal.x, portal.y, 118, 0x6be7d6, 0.08).setStrokeStyle(4, 0x6be7d6, 0.74);
    this.add.circle(portal.x, portal.y, 62, 0xf6c85f, 0.18).setStrokeStyle(2, 0xf6c85f, 0.46);
    this.add.rectangle(portal.x, portal.y, 250, 18, 0x6be7d6, 0.18);
    this.add.rectangle(portal.x, portal.y, 18, 250, 0xf6c85f, 0.12);
    this.tweens.add({
      targets: this.add.circle(portal.x, portal.y, 155, 0x6be7d6, 0.02).setStrokeStyle(1, 0x6be7d6, 0.24),
      scale: 1.08,
      alpha: 0.36,
      duration: 2400,
      yoyo: true,
      repeat: -1,
    });
  }

  private rect(id: string, fallback: MapLayoutRect): MapLayoutRect {
    return { ...fallback, ...this.layout[id] };
  }

  private getContinueScene(): string {
    if (!saveSystem.data.proceduralRun || saveSystem.data.proceduralRun.completedAt || saveSystem.data.proceduralRun.failedAt) {
      this.createProceduralRun("libera", this.activeDifficulty(), "mission");
    }
    return "ProceduralMissionScene";
  }

  private startMissionGame(): void {
    if (this.transitioning) return;
    this.transitioning = true;
    this.showBusy("Preparo una missione validata...");
    saveSystem.load();
    this.time.delayedCall(40, () => {
      this.createProceduralRun("libera", this.activeDifficulty(), "mission");
      void startScene(this, "ProceduralMissionScene");
    });
  }

  private startFocusTraining(focus: ProceduralSpecialization): void {
    if (this.transitioning) return;
    this.transitioning = true;
    this.showBusy("Costruisco il percorso focus...");
    saveSystem.load();
    this.time.delayedCall(40, () => {
      this.createProceduralRun(focus, this.activeDifficulty(), "training");
      void startScene(this, "ProceduralMissionScene");
    });
  }

  private showBusy(label: string): void {
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
  }

  private createProceduralRun(
    focus: ProceduralSpecialization = "libera",
    difficulty: DifficultyLevel = this.activeDifficulty(),
    mode: "mission" | "training" = focus === "libera" ? "mission" : "training",
  ): void {
    const focusList = focus === "libera" ? ["libera"] : [focus];
    const mission = proceduralDirector.generateFreshMission(difficulty, focusList);
    const startedAt = new Date().toISOString();
    const objectiveCount = Math.max(1, mission.objectives.length);
    const timeLimitMs = mode === "mission" ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, objectiveCount) : undefined;
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
      lives: mode === "mission" ? proceduralRunRules.maxLives : undefined,
      maxLives: mode === "mission" ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      deadlineAt: timeLimitMs ? proceduralRunRules.deadlineFrom(startedAt, timeLimitMs) : undefined,
      startedAt,
    };
    saveSystem.setProceduralRun(run);
  }

  private activeDifficulty(): DifficultyLevel {
    return this.selectedDifficulty ?? this.loadSelectedDifficulty();
  }

  private loadSelectedDifficulty(): DifficultyLevel {
    try {
      const stored = localStorage.getItem(TRAINING_DIFFICULTY_KEY);
      const parsed = Number(stored);
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
    try {
      localStorage.setItem(TRAINING_DIFFICULTY_KEY, String(level));
    } catch {
      // The current scene state is still enough for this session.
    }
    this.scene.restart();
  }

  private recommendedDifficulty(): DifficultyLevel {
    const run = saveSystem.data.proceduralRun;
    if (!run) {
      return 1;
    }
    return Math.min(8, run.completedAt ? run.difficulty + 1 : run.difficulty) as DifficultyLevel;
  }
}
