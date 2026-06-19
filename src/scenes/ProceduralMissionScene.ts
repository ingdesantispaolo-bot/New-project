import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { competencyTracker } from "../core/CompetencyTracker";
import { feedbackSystem, type FeedbackMessage } from "../core/FeedbackSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import { mistakeAnalyzer } from "../core/MistakeAnalyzer";
import { missionEngine } from "../core/MissionEngine";
import { playerSystem } from "../core/PlayerSystem";
import { formatDuration, proceduralScoring } from "../core/ProceduralScoring";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { circuitFaultTemplates } from "../data/procedural/circuitTemplates";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { MusicNoteGenerator } from "../procedural/generators/MusicNoteGenerator";
import { progressiveMissionBuilder } from "../procedural/ProgressiveMissionBuilder";
import { Random } from "../procedural/Random";
import type {
  CircuitComponentChallenge,
  CircuitFaultType,
  DifficultyLevel,
  EnglishMinigamePrompt,
  GeneratedFocusChallenge,
  GeneratedCodingPuzzle,
  GeneratedCircuitPuzzle,
  GeneratedEnglishMinigame,
  GeneratedEnglishPuzzle,
  GeneratedLanguagePuzzle,
  GeneratedLanguageMinigame,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  GeneratedMusicPuzzle,
  GeneratedRobotPuzzle,
  GeneratedRoomHotspot,
  GridCommand,
  GridFacing,
  LanguageMinigamePrompt,
  MathMinigamePrompt,
  ProgressiveLevelResult,
  ProgressiveOutcomeTone,
  ProceduralPuzzleScore,
  ProceduralRunSave,
} from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { outcomeFeedback, type OutcomeTone } from "../ui/OutcomeFeedback";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";
import { CircuitConsole, type CircuitConsoleModel } from "./procedural/components/CircuitConsole";
import { LanguageRepairConsole, type LanguageRepairModel } from "./procedural/components/LanguageRepairConsole";
import { MathTerminal, type MathTerminalModel } from "./procedural/components/MathTerminal";
import { MissionDependencyGraph } from "./procedural/components/MissionDependencyGraph";
import { RobotConsole } from "./procedural/components/RobotConsole";
import { isProceduralPuzzleSolved, proceduralPuzzleOrder, proceduralRequiredPuzzleIds, puzzleKindFromId, type ProceduralPuzzleId } from "./procedural/ProceduralMissionLayout";
import { ProceduralMissionView } from "./procedural/ProceduralMissionView";

const commandLabels: Record<GridCommand, string> = {
  MOVE_FORWARD: "Avanza",
  TURN_LEFT: "Gira SX",
  TURN_RIGHT: "Gira DX",
  PICK_UP: "Raccogli",
  EXIT: "Esci",
};

const faultLabels: Record<CircuitFaultType, string> = Object.fromEntries(
  circuitFaultTemplates.map((fault) => [fault.type, fault.label]),
) as Record<CircuitFaultType, string>;

const repairLabels: Record<CircuitFaultType, string> = {
  "missing-wire": "Collega filo",
  "open-switch": "Chiudi switch",
  "reversed-led": "Inverti LED",
  "missing-resistor": "Inserisci R",
  "disconnected-component": "Ricollega",
  "sensor-unpowered": "Alimenta sensore",
  "capacitor-discharged": "Carica condens.",
  "short-circuit": "Isola corto",
  "parallel-branch-open": "Chiudi ramo B",
  "wrong-resistor-value": "Cambia valore R",
  "relay-not-armed": "Arma relè",
  "loose-ground": "Fissa massa",
};

type MusicTrainingSession = {
  puzzleId: string;
  random: Random;
  current: GeneratedMusicPuzzle;
  startedAt: number;
  durationMs: number;
  questionStartedAt: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  recentSignatures: string[];
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

type MathMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedMathPuzzle;
  game: GeneratedMathMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

type LanguageMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedLanguagePuzzle;
  game: GeneratedLanguageMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

type EnglishMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedEnglishPuzzle;
  game: GeneratedEnglishMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

export class ProceduralMissionScene extends Phaser.Scene {
  private run!: ProceduralRunSave;
  private dependencies = new MissionDependencyGraph();
  private feedbackText?: Phaser.GameObjects.Text;
  private objectiveText?: Phaser.GameObjects.Text;
  private progressText?: Phaser.GameObjects.Text;
  private overlay?: Phaser.GameObjects.Container;
  private activePuzzleId?: string;
  private activePuzzleKind?: ProceduralPuzzleId;
  private activeChallenge?: GeneratedFocusChallenge;
  private mathEntry = "";
  private mathStepIndex = 0;
  private mathSupportMessage = "";
  private mathSupportText?: Phaser.GameObjects.Text;
  private languageAnalyzed = false;
  private englishAnalyzed = false;
  private circuitInspected = false;
  private circuitConceptVerified = false;
  private circuitConceptIndex = 0;
  private circuitSymbolAnswer?: string;
  private circuitFunctionAnswer?: string;
  private selectedRepairs = new Set<CircuitFaultType>();
  private robotCommands: GridCommand[] = [];
  private robotExecuting = false;
  private robotSprite?: Phaser.GameObjects.Triangle;
  private robotKeyMarker?: Phaser.GameObjects.Star;
  private robotStatusText?: Phaser.GameObjects.Text;
  private robotOrigin = { x: 130, y: 118 };
  private robotCellSize = 48;
  private musicTimerEvent?: Phaser.Time.TimerEvent;
  private musicSession?: MusicTrainingSession;
  private readonly musicGenerator = new MusicNoteGenerator();
  private mathMinigameTimerEvent?: Phaser.Time.TimerEvent;
  private mathMinigameTimerText?: Phaser.GameObjects.Text;
  private mathMinigameSession?: MathMinigameSession;
  private languageMinigameTimerEvent?: Phaser.Time.TimerEvent;
  private languageMinigameTimerText?: Phaser.GameObjects.Text;
  private languageMinigameSession?: LanguageMinigameSession;
  private englishMinigameTimerEvent?: Phaser.Time.TimerEvent;
  private englishMinigameTimerText?: Phaser.GameObjects.Text;
  private englishMinigameSession?: EnglishMinigameSession;
  private missionFailureInProgress = false;
  private timeoutSolutionOpen = false;
  private progressiveOutcomeOpen = false;

  constructor() {
    super("ProceduralMissionScene");
  }

  create(): void {
    this.run = this.ensureRun();
    audioManager.playMusic("labAmbience");
    ProceduralMissionView.drawShell(this, this.run);
    const hud = ProceduralMissionView.createHud(
      this,
      this.run,
      () => this.regenerate(),
      () => {
        this.pauseRunIfLeaving();
        this.scene.start("MainMenuScene");
      },
    );
    this.objectiveText = hud.objectiveText;
    this.progressText = hud.progressText;
    this.feedbackText = hud.feedbackText;
    ProceduralMissionView.createHotspots(this, this.run, this.allPuzzlesSolved(), (hotspot) => this.openHotspot(hotspot));
    this.refreshObjective();
    this.time.addEvent({ delay: 1000, loop: true, callback: () => this.refreshObjective() });

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
      this.pauseRunIfLeaving();
    });

    feedbackSystem.publish(this.isProgressiveMode()
      ? `Scalata guidata avviata. La stanza aprira una console alla volta. Seed: ${this.run.seed}.`
      : `Stanza generata. Scegli una console da stabilizzare. Seed: ${this.run.seed}.`, "info");
    this.scheduleNextProgressivePuzzle(700);
  }

  private pauseRunIfLeaving(): void {
    const activeRun = saveSystem.data.proceduralRun;
    if (!activeRun || activeRun.completedAt || activeRun.failedAt) {
      return;
    }
    saveSystem.pauseActiveProceduralRun();
  }

  private runMode(): "mission" | "training" | "progressive" {
    return proceduralRunRules.modeFor(this.run);
  }

  private isProgressiveMode(): boolean {
    return this.runMode() === "progressive";
  }

  private isTimedMissionMode(): boolean {
    const mode = this.runMode();
    return mode === "mission" || mode === "progressive";
  }

  private isRunInteractionLocked(): boolean {
    return this.missionFailureInProgress
      || this.progressiveOutcomeOpen
      || Boolean(this.run.completedAt || this.run.failedAt);
  }

  private runWhenActive(delayMs: number, callback: () => void): Phaser.Time.TimerEvent {
    return this.time.delayedCall(delayMs, () => {
      if (!this.sys.isActive()) {
        return;
      }
      callback();
    });
  }

  private ensureRun(): ProceduralRunSave {
    if (saveSystem.data.proceduralRun && !saveSystem.data.proceduralRun.completedAt && !saveSystem.data.proceduralRun.failedAt) {
      const normalized = this.normalizeRunRules(saveSystem.data.proceduralRun);
      if (this.runNeedsContentMigration(normalized)) {
        return this.replaceLegacyRun(normalized);
      }
      return normalized;
    }
    const mission = proceduralDirector.generateFreshMission(2, ["libera"]);
    const startedAt = new Date().toISOString();
    const timeLimitMs = proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length));
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["libera"],
      mode: "mission",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: proceduralRunRules.maxLives,
      maxLives: proceduralRunRules.maxLives,
      timeLimitMs,
      deadlineAt: proceduralRunRules.deadlineFrom(startedAt, timeLimitMs),
      startedAt,
    };
    saveSystem.setProceduralRun(run);
    return run;
  }

  private runNeedsContentMigration(run: ProceduralRunSave): boolean {
    const mode = proceduralRunRules.modeFor(run);
    const focus = proceduralRunRules.focusFor(run);
    const puzzles = run.mission.puzzles as Partial<ProceduralRunSave["mission"]["puzzles"]>;
    const hasMusicPuzzle = Boolean(puzzles.music);
    const hasModernMusicPuzzle = Boolean(puzzles.music?.answerMode);
    const hasMusicObjective = run.mission.objectives.some((objective) => puzzleKindFromId(objective.id.replace("procedural-", "")) === "music");
    const hasMusicHotspot = run.mission.map.hotspots.some((hotspot) => {
      const id = hotspot.puzzleId ?? hotspot.id;
      return hotspot.puzzleKind === "music" || id === "music" || id.startsWith("music-");
    });
    const hasMusicFocusSeries = Boolean(
      run.mission.focusChallenges?.length
      && run.mission.focusChallenges.every((challenge) => challenge.kind === "music"),
    );
    const hasCodingPuzzle = Boolean(puzzles.coding);
    const hasCodingObjective = run.mission.objectives.some((objective) => puzzleKindFromId(objective.id.replace("procedural-", "")) === "coding");
    const hasCodingHotspot = run.mission.map.hotspots.some((hotspot) => {
      const id = hotspot.puzzleId ?? hotspot.id;
      return hotspot.puzzleKind === "coding" || id === "coding" || id.startsWith("coding-");
    });
    const hasCodingFocusSeries = Boolean(
      run.mission.focusChallenges?.length
      && run.mission.focusChallenges.every((challenge) => challenge.kind === "coding"),
    );
    if (focus === "musica") {
      return !(hasMusicPuzzle && hasModernMusicPuzzle && hasMusicObjective && hasMusicHotspot && hasMusicFocusSeries);
    }
    if (focus === "coding") {
      return !(hasCodingPuzzle && hasCodingObjective && hasCodingHotspot && hasCodingFocusSeries);
    }
    if (mode === "mission" || focus === "libera") {
      return !(hasMusicPuzzle && hasModernMusicPuzzle && hasMusicObjective && hasMusicHotspot);
    }
    return false;
  }

  private replaceLegacyRun(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    const focus = run.focus.length > 0 ? run.focus : [mode === "training" ? proceduralRunRules.focusFor(run) : "libera"];
    const baseMission = proceduralDirector.generateFreshMission(run.difficulty, focus);
    const mission = mode === "progressive"
      ? progressiveMissionBuilder.buildLevelMission(baseMission, run.progressive?.currentLevel ?? run.difficulty)
      : baseMission;
    const startedAt = new Date().toISOString();
    const timeLimitMs = mode === "progressive"
      ? progressiveMissionBuilder.timeLimitMs(run.progressive?.currentLevel ?? mission.difficulty, Math.max(1, mission.objectives.length))
      : mode === "mission"
        ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length))
        : undefined;
    const replacement: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus,
      mode,
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: mode === "mission" || mode === "progressive" ? proceduralRunRules.maxLives : undefined,
      maxLives: mode === "mission" || mode === "progressive" ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      deadlineAt: timeLimitMs ? proceduralRunRules.deadlineFrom(startedAt, timeLimitMs) : undefined,
      startedAt,
      progressive: mode === "progressive"
        ? {
            currentLevel: run.progressive?.currentLevel ?? run.difficulty,
            unlockedLevel: run.progressive?.unlockedLevel ?? run.difficulty,
            maxLevel: run.progressive?.maxLevel ?? 8,
            levelStartedAt: startedAt,
            levelTimeLimitMs: timeLimitMs ?? progressiveMissionBuilder.timeLimitMs(run.difficulty, Math.max(1, mission.objectives.length)),
            levelDeadlineAt: timeLimitMs ? proceduralRunRules.deadlineFrom(startedAt, timeLimitMs) : startedAt,
            results: run.progressive?.results ?? [],
          }
        : undefined,
    };
    saveSystem.setProceduralRun(replacement);
    return replacement;
  }

  private normalizeRunRules(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    if (mode === "training") {
      if (run.mode !== mode) {
        saveSystem.updateProceduralRun({ mode });
        return saveSystem.data.proceduralRun ?? { ...run, mode };
      }
      return run;
    }
    const timeLimitMs = run.timeLimitMs ?? (mode === "progressive"
      ? progressiveMissionBuilder.timeLimitMs(run.progressive?.currentLevel ?? run.difficulty, Math.max(1, run.mission.objectives.length))
      : proceduralRunRules.missionTimeLimitMs(run.difficulty, Math.max(1, run.mission.objectives.length)));
    const update: Partial<ProceduralRunSave> = {};
    if (run.mode !== mode) update.mode = mode;
    if (run.maxLives === undefined) update.maxLives = proceduralRunRules.maxLives;
    if (run.lives === undefined) update.lives = proceduralRunRules.maxLives;
    if (!run.timeLimitMs) update.timeLimitMs = timeLimitMs;
    if (run.pausedRemainingMs && !run.completedAt && !run.failedAt) {
      update.deadlineAt = new Date(Date.now() + Math.max(0, run.pausedRemainingMs)).toISOString();
      update.pausedRemainingMs = undefined;
    } else if (!run.deadlineAt) {
      update.deadlineAt = proceduralRunRules.deadlineFrom(run.startedAt, timeLimitMs);
    }
    if (Object.keys(update).length > 0) {
      saveSystem.updateProceduralRun(update);
      return saveSystem.data.proceduralRun ?? { ...run, ...update };
    }
    return run;
  }

  private regenerate(): void {
    if (this.isProgressiveMode()) {
      const progressive = this.run.progressive;
      this.startProgressiveLevel(progressive?.currentLevel ?? this.run.difficulty, progressive?.results ?? []);
      return;
    }
    const nextDifficulty = Math.min(8, this.run.difficulty + (this.run.completedAt ? 1 : 0)) as DifficultyLevel;
    const mission = proceduralDirector.generateFreshMission(nextDifficulty, this.run.focus);
    const mode = proceduralRunRules.modeFor(this.run);
    const startedAt = new Date().toISOString();
    const timeLimitMs = mode === "mission" ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length)) : undefined;
    saveSystem.setProceduralRun({
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: this.run.focus,
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
    });
    this.scene.restart();
  }

  private createProgressiveRun(level: DifficultyLevel, previousResults: ProgressiveLevelResult[]): ProceduralRunSave {
    const levelFocus = progressiveMissionBuilder.focusForLevel(level);
    const baseMission = proceduralDirector.generateFreshMission(level, [levelFocus]);
    const mission = progressiveMissionBuilder.buildLevelMission(baseMission, level);
    const startedAt = new Date().toISOString();
    const timeLimitMs = progressiveMissionBuilder.timeLimitMs(level, Math.max(1, mission.objectives.length));
    const highestUnlocked = previousResults.reduce<number>((max, result) => (
      result.completed ? Math.max(max, Math.min(8, result.level + 1)) : max
    ), level);
    return {
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
      deadlineAt: proceduralRunRules.deadlineFrom(startedAt, timeLimitMs),
      startedAt,
      progressive: {
        currentLevel: level,
        unlockedLevel: Math.min(8, Math.max(level, highestUnlocked)) as DifficultyLevel,
        maxLevel: 8,
        levelStartedAt: startedAt,
        levelTimeLimitMs: timeLimitMs,
        levelDeadlineAt: proceduralRunRules.deadlineFrom(startedAt, timeLimitMs),
        results: previousResults,
      },
    };
  }

  private startProgressiveLevel(level: DifficultyLevel, previousResults: ProgressiveLevelResult[]): void {
    saveSystem.setProceduralRun(this.createProgressiveRun(level, previousResults));
    this.scene.restart();
  }

  private parkProgressiveLevel(level: DifficultyLevel, previousResults: ProgressiveLevelResult[]): void {
    saveSystem.setProceduralRun(this.createProgressiveRun(level, previousResults));
    saveSystem.pauseActiveProceduralRun();
  }

  private openHotspot(hotspot: GeneratedRoomHotspot): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    audioManager.play("scan");
    if (hotspot.id === "door") {
      this.openDoor();
      return;
    }
    if (!hotspot.puzzleId) {
      feedbackSystem.publish(hotspot.description, "info");
      return;
    }
    const nextProgressivePuzzle = this.nextPendingProgressivePuzzleId();
    if (nextProgressivePuzzle && hotspot.puzzleId !== nextProgressivePuzzle) {
      feedbackSystem.publish(`Sequenza guidata: prima completa ${this.puzzleLabel(nextProgressivePuzzle)}.`, "hint");
      audioManager.playOutcome("hint");
      return;
    }
    if (this.isSolved(hotspot.puzzleId)) {
      feedbackSystem.publish(`${hotspot.label}: sistema già stabilizzato.`, "success");
      return;
    }
    if (this.isFailed(hotspot.puzzleId)) {
      feedbackSystem.publish(`${hotspot.label}: tentativo già chiuso. Apri la porta quando tutte le console sono risolte o registrate.`, "warning");
      return;
    }
    this.openPuzzleConsole(hotspot.puzzleId);
  }

  private openPuzzleConsole(puzzleId: string): void {
    const challenge = this.findFocusChallenge(puzzleId);
    const systemId = challenge?.kind ?? puzzleKindFromId(puzzleId);
    const handlers: Record<ProceduralPuzzleId, () => void> = {
      language: () => this.openLanguage(),
      circuit: () => this.openCircuit(),
      math: () => this.openMath(),
      english: () => this.openEnglish(),
      robot: () => this.openRobot(),
      coding: () => this.openCoding(),
      music: () => this.openMusic(),
    };
    if (proceduralPuzzleOrder.includes(systemId)) {
      if (this.activePuzzleId !== puzzleId) {
        this.resetTransientPuzzleState();
      }
      this.activePuzzleId = puzzleId;
      this.activePuzzleKind = systemId;
      this.activeChallenge = challenge;
      this.ensurePuzzleTimer(puzzleId);
      handlers[systemId]();
    }
  }

  private openLanguage(): void {
    const puzzle = this.currentLanguagePuzzle();
    if (puzzle.minigame) {
      this.openLanguageMinigame(puzzle);
      return;
    }
    const model = LanguageRepairConsole.fromPuzzle(puzzle, this.languageAnalyzed);
    const overlay = this.createOverlay(model.title, 660, { x: 40, y: 30, width: 1200 });
    LanguageRepairConsole.addHeader(this, overlay, model);
    this.addLanguageBrief(overlay, model);
    if (!this.languageAnalyzed) {
      overlay.add(new Button(this, 866, 586, "Analizza struttura", () => {
        this.languageAnalyzed = true;
        audioManager.playOutcome("neutral");
        outcomeFeedback.play(this, "info", "Analisi del segnale");
        feedbackSystem.publish(`Analisi avviata: ${model.method}`, "info");
        this.openLanguage();
      }, { width: 310, height: 52, fill: 0x173b36 }));
      return;
    }
    model.options.forEach((option, index) => {
      const y = 330 + index * 48;
      overlay.add(new Button(this, 866, y, option, () => {
        if (option === model.correctAnswer) {
          this.solvePuzzle(this.currentPuzzleId("language"), puzzle.competencies);
          return;
        }
        this.handleIncorrectAnswer(model.optionFeedback[option] ?? model.hints[Math.min(index, model.hints.length - 1)]);
      }, { width: 540, height: 40, fontSize: 11, wordWrapWidth: 506 }));
    });
    this.addMethodStrip(overlay, 56, 590, 520, "Metodo", [
      "soggetto reale",
      "accordi e connettivi",
      "significato operativo",
    ]);
    overlay.add(new Button(this, 866, 620, "Indizio mirato", () => {
      this.useHint(this.nextPedagogicHint(puzzle, model.hints[Math.min(this.run.hintsUsed, model.hints.length - 1)]));
      this.openLanguage();
    }, { width: 250, height: 40, fontSize: 13, fill: 0x263743 }));
  }

  private openLanguageMinigame(puzzle: GeneratedLanguagePuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("language");
    const session = this.ensureLanguageMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title);
    const prompt = this.currentLanguageMinigamePrompt(session);
    const remaining = this.languageMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 548, 432, "Laboratorio linguistico");
    overlay.add(this.add.text(60, 154, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "27px",
      color: "#f7d37a",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    this.drawLanguageMinigameVisualizer(overlay, prompt, 60, 210, 482, 210);
    overlay.add(this.add.text(60, 456, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 472 },
    }));
    overlay.add(this.add.text(60, 488, this.languageMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 476, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    this.addMathPanel(overlay, 604, 112, 648, 432, "Scelta rapida");
    overlay.add(this.add.text(636, 154, "60 secondi: leggi lo scopo, clicca la tessera migliore, conferma. Non vince chi prova: vince chi riconosce la regola.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 560 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(636, 214, prompt.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 560, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    const tileStartX = 784;
    const tileStartY = 340;
    prompt.tiles.forEach((tile, index) => {
      const selected = session.selectedIds.has(tile.id);
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(new Button(this, tileStartX + col * 258, tileStartY + row * 68, tile.label, () => this.toggleLanguageMinigameTile(tile.id), {
        width: 232,
        height: 52,
        fontSize: tile.label.length > 34 ? 10 : tile.label.length > 20 ? 12 : 16,
        wordWrapWidth: 210,
        fill: selected ? 0x174d42 : 0x263743,
        stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });

    this.addMathPanel(overlay, 28, 558, 1224, 130, "Ritmo e valutazione");
    this.languageMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(this.languageMinigameTimerText);
    overlay.add(this.add.text(260, 592, [
      `Corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie: ${session.streak}`,
      `Punti: ${session.netScore}`,
    ].join("   "), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 640 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(260, 636, session.feedback || puzzle.minigame.scoringRule, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: session.feedback ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 650, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 858, 640, "Pulisci scelta", () => this.clearLanguageMinigameSelection(), {
      width: 174,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1046, 640, "Conferma", () => this.confirmLanguageMinigamePrompt(), {
      width: 174,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 686, 640, "Indizio", () => this.useLanguageMinigameHint(), {
      width: 138,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.languageMinigameTimerEvent?.remove(false);
    this.languageMinigameTimerEvent = this.time.addEvent({
      delay: 250,
      loop: true,
      callback: () => this.refreshLanguageMinigameTimer(),
    });
    this.refreshLanguageMinigameTimer();
  }

  private ensureLanguageMinigameSession(
    puzzleId: string,
    puzzle: GeneratedLanguagePuzzle,
    game: GeneratedLanguageMinigame,
  ): LanguageMinigameSession {
    if (this.languageMinigameSession?.puzzleId === puzzleId && !this.languageMinigameSession.summaryOpen) {
      return this.languageMinigameSession;
    }
    this.languageMinigameSession = {
      puzzleId,
      puzzle,
      game,
      startedAt: Date.now(),
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      feedback: "Leggi prima l'obiettivo: accordo, connettivo o intruso. Poi conferma una sola tessera.",
      locked: false,
      summaryOpen: false,
    };
    return this.languageMinigameSession;
  }

  private drawLanguageMinigameVisualizer(
    overlay: Phaser.GameObjects.Container,
    prompt: LanguageMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const g = this.add.graphics();
    g.fillStyle(0x07151d, 0.78);
    g.fillRoundedRect(x, y, width, height, 12);
    g.lineStyle(2, 0x6be7d6, 0.3);
    g.strokeRoundedRect(x, y, width, height, 12);
    overlay.add(g);

    const accent = prompt.type === "agreement-sprint" ? 0x6be7d6 : prompt.type === "connector-route" ? 0xf6c85f : 0x9f8cff;
    overlay.add(this.add.rectangle(x + 26, y + 34, width - 52, 74, 0x102533, 0.8)
      .setOrigin(0)
      .setStrokeStyle(1, accent, 0.45));
    overlay.add(this.add.text(x + 44, y + 52, prompt.context, {
      fontFamily: "Inter, Arial",
      fontSize: prompt.context.length > 92 ? "13px" : "16px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: width - 88, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    if (prompt.type === "agreement-sprint") {
      overlay.add(this.add.text(x + 44, y + 142, "Segnale -> soggetto -> forma -> significato", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#9ff5e9",
        fontStyle: "bold",
      }));
    } else if (prompt.type === "connector-route") {
      overlay.add(this.add.text(x + 44, y + 142, "Dai un nome al rapporto: causa, contrasto, tempo, condizione o scopo.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f7d37a",
        wordWrap: { width: width - 88 },
      }));
    } else {
      overlay.add(this.add.text(x + 44, y + 142, "Tieni solo ciò che serve all'obiettivo. Un dettaglio vero può essere inutile.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#d8c9ff",
        wordWrap: { width: width - 88 },
      }));
    }
  }

  private currentLanguageMinigamePrompt(session: LanguageMinigameSession): LanguageMinigamePrompt {
    return session.game.prompts[session.promptIndex % session.game.prompts.length];
  }

  private languageMinigameElapsedMs(session: LanguageMinigameSession): number {
    return Math.max(0, Date.now() - session.startedAt);
  }

  private languageMinigameRemainingMs(session: LanguageMinigameSession): number {
    return Math.max(0, session.durationMs - this.languageMinigameElapsedMs(session));
  }

  private refreshLanguageMinigameTimer(): void {
    const session = this.languageMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    const remaining = this.languageMinigameRemainingMs(session);
    this.languageMinigameTimerText?.setText(`Tempo: ${formatDuration(remaining)}`);
    this.languageMinigameTimerText?.setColor(remaining <= 10_000 ? "#ff8f8f" : "#f7d37a");
    if (remaining <= 0) {
      this.finishLanguageMinigame();
    }
  }

  private toggleLanguageMinigameTile(tileId: string): void {
    const session = this.languageMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.selectedIds.add(tileId);
    audioManager.play("click");
    this.openLanguageMinigame(session.puzzle);
  }

  private clearLanguageMinigameSelection(): void {
    const session = this.languageMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.feedback = "Scelta pulita. Rileggi prima l'obiettivo della console, poi scegli.";
    this.openLanguageMinigame(session.puzzle);
  }

  private useLanguageMinigameHint(): void {
    const session = this.languageMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentLanguageMinigamePrompt(session);
    const hint = prompt.type === "agreement-sprint"
      ? "Trova il soggetto reale: a volte una frase relativa o un inciso distrae dal verbo corretto."
      : prompt.type === "connector-route"
        ? "Chiediti: la seconda parte spiega, contrasta, segue nel tempo o pone una condizione?"
        : "Confronta ogni dettaglio con l'obiettivo. Se non aiuta a rispondere, è rumore.";
    session.feedback = hint;
    this.useHint(hint);
    this.openLanguageMinigame(session.puzzle);
  }

  private confirmLanguageMinigamePrompt(): void {
    const session = this.languageMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (this.languageMinigameRemainingMs(session) <= 0) {
      this.finishLanguageMinigame();
      return;
    }
    const prompt = this.currentLanguageMinigamePrompt(session);
    if (session.selectedIds.size === 0) {
      session.feedback = "Prima seleziona una tessera. Il timer continua.";
      audioManager.playOutcome("hint");
      this.openLanguageMinigame(session.puzzle);
      return;
    }
    const selectedId = [...session.selectedIds][0];
    const selected = prompt.tiles.find((tile) => tile.id === selectedId);
    if (!selected?.isCorrect) {
      const message = `${selected?.feedback ?? "Scelta non coerente."} Soluzione: ${prompt.solutionLabels.join(", ")}. ${prompt.explanation}`;
      if (this.isTimedMissionMode()) {
        this.languageMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (7 + this.run.difficulty));
      session.feedback = message;
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      outcomeFeedback.play(this, "warning", "Rileggi il vincolo");
      this.advanceLanguageMinigamePrompt(760);
      return;
    }

    session.answered += 1;
    session.correct += 1;
    session.streak += 1;
    session.bestStreak = Math.max(session.bestStreak, session.streak);
    const award = 10 + this.run.difficulty * 2 + Math.min(12, session.streak * 2);
    session.netScore += award;
    session.feedback = `Corretta: ${prompt.explanation} +${award}`;
    session.locked = true;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceLanguageMinigamePrompt(420);
  }

  private advanceLanguageMinigamePrompt(delayMs: number): void {
    const session = this.languageMinigameSession;
    if (!session) {
      return;
    }
    this.runWhenActive(delayMs, () => {
      if (this.languageMinigameSession !== session || session.summaryOpen) {
        return;
      }
      if (this.languageMinigameRemainingMs(session) <= 0) {
        this.finishLanguageMinigame();
        return;
      }
      const previous = this.currentLanguageMinigamePrompt(session).signature;
      session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      if (this.currentLanguageMinigamePrompt(session).signature === previous) {
        session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      }
      session.selectedIds.clear();
      session.locked = false;
      this.openLanguageMinigame(session.puzzle);
    });
  }

  private finishLanguageMinigame(): void {
    const session = this.languageMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    session.locked = true;
    session.summaryOpen = true;
    this.languageMinigameTimerEvent?.remove(false);
    this.languageMinigameTimerEvent = undefined;
    audioManager.playOutcome("neutral");
    this.showLanguageMinigameSummary(session);
  }

  private languageMinigamePassed(session: LanguageMinigameSession): boolean {
    if (!this.isTimedMissionMode()) {
      return true;
    }
    const minCorrect = Math.max(5, Math.min(12, 4 + Math.ceil(this.run.difficulty * 0.75)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    return session.correct >= minCorrect && accuracy >= 0.62 && session.netScore > 0;
  }

  private languageMinigameFeedback(session: LanguageMinigameSession): string {
    if (session.answered === 0) {
      return "Nessuna risposta: serve leggere almeno un log e riconoscere la regola richiesta.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.9 && session.bestStreak >= 8) {
      return "Lettura rapida molto solida: hai riconosciuto forma, logica e pertinenza senza farti distrarre.";
    }
    if (accuracy >= 0.72) {
      return "Buon controllo: aumenta la velocità solo dopo aver nominato la regola del prompt.";
    }
    if (session.wrong >= session.correct) {
      return "Troppi tentativi: rileggi lo scopo e scegli solo quando sai spiegare perché le altre opzioni cadono.";
    }
    return "Allenamento utile: ora lavora sulle serie corrette, non solo sul singolo colpo.";
  }

  private showLanguageMinigameSummary(session: LanguageMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const passed = this.languageMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(this.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(this.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(this.add.text(230, 160, passed ? "Sprint italiano completato" : "Sprint italiano da consolidare", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: passed ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(230, 210, [
      `Risposte corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie migliore: ${session.bestStreak}`,
      `Punti sprint: ${session.netScore}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      lineSpacing: 7,
    }));
    modal.add(this.add.rectangle(548, 212, 408, 128, 0x102533, 0.78).setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(this.add.text(572, 234, this.languageMinigameFeedback(session), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 354 },
      lineSpacing: 5,
    }));
    modal.add(this.add.rectangle(230, 378, 740, 74, 0x0b1e2a, 0.82).setOrigin(0)
      .setStrokeStyle(1, 0xf7d37a, 0.36));
    modal.add(this.add.text(254, 394, (mode === "mission" || mode === "progressive")
      ? passed
        ? "La console italiana accetta il log: forma, coesione e pertinenza sono abbastanza stabili."
        : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
      : "Allenamento registrabile: contano rapidità, precisione, serie positiva e uso consapevole degli aiuti.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    modal.add(new Button(this, 612, 506, (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua", () => {
      modal.destroy(true);
      if (!passed && (mode === "mission" || mode === "progressive")) {
        this.loseMissionLife("sprint italiano sotto soglia: servono più risposte corrette con meno tentativi.");
        return;
      }
      this.completeLanguageMinigame(session);
    }, {
      width: 270,
      height: 54,
      fill: passed ? 0x173b36 : 0x263743,
      stroke: passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private completeLanguageMinigame(session: LanguageMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeLanguageMinigameScore(session);
    saveSystem.markProceduralPuzzleSolved(session.puzzleId);
    competencyTracker.award(session.game.competencies, 8 + this.run.difficulty * 2 + Math.min(12, Math.floor(score.total / 32)));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    this.languageMinigameSession = undefined;
    const solvedNode = puzzleKindFromId(session.puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    feedbackSystem.publish(
      `Sprint italiano registrato: ${session.correct} corrette, ${session.wrong} errori, serie ${session.bestStreak}. +${score.total} punti. ${remaining.length > 0 ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.` : "La porta finale è pronta."}`,
      "success",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Console italiana stabilizzata: il sistema completo è certificabile.");
      return;
    }
    if (this.isProgressiveMode()) {
      this.scheduleNextProgressivePuzzle(850);
      return;
    }
    this.runWhenActive(640, () => this.scene.restart());
  }

  private finalizeLanguageMinigameScore(session: LanguageMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
    const completedAt = new Date().toISOString();
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.languageMinigameElapsedMs(session)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    const basePoints = session.correct * (9 + run.difficulty);
    const difficultyBonus = session.correct * run.difficulty * 2;
    const speedBonus = Math.min(90, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 34));
    const focusBonus = run.focus.includes("italiano") || run.focus.some((item) => item.startsWith("italiano."))
      ? 20 + run.difficulty * 3
      : 0;
    const supportPenalty = (existing?.hintsUsed ?? 0) * 5 + session.wrong * (5 + run.difficulty);
    const total = Math.max(0, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);
    const score: ProceduralPuzzleScore = {
      puzzleId: session.puzzleId,
      domain: proceduralScoring.puzzleDomain(session.puzzleId),
      startedAt,
      completedAt,
      elapsedMs,
      hintsUsed: existing?.hintsUsed ?? 0,
      attempts: Math.max(1, existing?.attempts ?? 1),
      basePoints,
      difficultyBonus,
      speedBonus,
      focusBonus,
      supportPenalty,
      total,
      feedback: this.languageMinigameFeedback(session),
    };
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [session.puzzleId]: score,
      },
      score: proceduralScoring.addToSummary(run.score, score),
    });
    return score;
  }

  private languageMinigameMethodText(prompt: LanguageMinigamePrompt): string {
    if (prompt.type === "agreement-sprint") {
      return "Metodo: trova il soggetto reale, ignora incisi e relative, poi controlla verbo e aggettivo.";
    }
    if (prompt.type === "connector-route") {
      return "Metodo: dai un nome al rapporto logico prima di guardare i connettivi.";
    }
    return "Metodo: confronta ogni dettaglio con l'obiettivo. Se non aiuta diagnosi, sequenza, fonte o sintesi, è rumore.";
  }

  private openCircuit(): void {
    const puzzle = this.currentCircuitPuzzle();
    const model = CircuitConsole.fromPuzzle(puzzle);
    const overlay = this.createOverlay(model.title, 660, { x: 40, y: 30, width: 1200 });
    overlay.add(this.add.text(48, 72, model.difficultyLabel.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(48, 100, model.symptom, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f7d37a",
      wordWrap: { width: 800 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(456, 158, 816, 58, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.text(64, 138, "Scopo della diagnosi", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(64, 158, `${model.learningPurpose} Domanda: ${model.diagnosticQuestion}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 760 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(1010, 132, 304, 112, 0x07151d, 0.78).setStrokeStyle(1, 0x6be7d6, 0.18));
    overlay.add(this.add.text(876, 90, "Concetti osservati", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(876, 116, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 260 },
      lineSpacing: 3,
    }));

    this.drawCircuitDiagnostic(overlay);
    this.drawCircuitSidePanel(overlay, model);

    if (!this.circuitInspected) {
      overlay.add(new Button(this, 1010, 588, "Leggi tester", () => {
        this.circuitInspected = true;
        audioManager.playOutcome("neutral");
        feedbackSystem.publish("Tester collegato: ora collega ogni misura a una causa, senza tentare riparazioni a caso.", "info");
        this.openCircuit();
      }, { width: 250, height: 52, fill: 0x173b36 }));
      return;
    }

    if (model.componentChallenges.length > 0 && !this.circuitConceptVerified) {
      this.drawCircuitComponentChallenge(overlay, model);
      return;
    }

    overlay.add(this.add.rectangle(452, 488, 816, 46, 0x07151d, 0.74).setStrokeStyle(1, 0xf6c85f, 0.2));
    overlay.add(this.add.text(64, 474, "Interventi disponibili", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(64, 496, "Seleziona solo le riparazioni dimostrate dal tester. Una riparazione inutile riduce qualita, tempo e affidabilita del log.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 760 },
    }));

    model.repairChoices.forEach((fault, index) => {
      const selected = this.selectedRepairs.has(fault);
      const col = index % 4;
      const row = Math.floor(index / 4);
      overlay.add(new Button(this, 142 + col * 200, 548 + row * 44, `${selected ? "[x] " : ""}${repairLabels[fault]}`, () => {
        if (selected) {
          this.selectedRepairs.delete(fault);
        } else {
          this.selectedRepairs.add(fault);
        }
        audioManager.play("click");
        this.openCircuit();
      }, { width: 176, height: 38, fontSize: 11, fill: selected ? 0x173b36 : 0x142736 }));
    });
    overlay.add(new Button(this, 1010, 604, "Testa circuito", () => {
      const required = new Set(puzzle.requiredRepairs);
      const exact = this.selectedRepairs.size === required.size && [...this.selectedRepairs].every((fault) => required.has(fault));
      if (exact) {
        const explanation = puzzle.requiredRepairs
          .map((fault) => model.explanations[fault] ?? faultLabels[fault])
          .join(" ");
        this.animateCircuitTest(true, () => {
          feedbackSystem.publish(`Circuito certificato. ${explanation}`, "success");
          this.solvePuzzle(this.currentPuzzleId("circuit"), puzzle.competencies);
        });
        return;
      }
      const missing = puzzle.requiredRepairs.filter((fault) => !this.selectedRepairs.has(fault));
      const extra = [...this.selectedRepairs].filter((fault) => !required.has(fault));
      const message = missing.length > 0
        ? `Manca ancora una causa: ${faultLabels[missing[0]]}.`
        : `Hai aggiunto un intervento non necessario: ${faultLabels[extra[0]]}.`;
      this.animateCircuitTest(false, () => this.handleIncorrectAnswer(`${message} ${this.nextPedagogicHint(puzzle, puzzle.hints[0] ?? "Rileggi il tester e collega sintomo a causa.")}`));
    }, { width: 250, height: 52, fill: 0x173b36 }));
  }

  private drawCircuitSidePanel(overlay: Phaser.GameObjects.Container, model: CircuitConsoleModel): void {
    const x = 856;
    const y = 188;
    overlay.add(this.add.rectangle(x, y, 330, 268, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(x + 18, y + 16, this.circuitInspected ? "Letture tester" : "Metodo tecnico", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    if (!this.circuitInspected) {
      overlay.add(this.add.text(x + 18, y + 48, "Prima misura, poi ripara. Il tester serve a distinguere una causa reale da una prova casuale.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: 288 },
        lineSpacing: 5,
      }));
      model.diagnosticPlan.slice(0, 4).forEach((step, index) => {
        const rowY = y + 122 + index * 34;
        overlay.add(this.add.circle(x + 28, rowY + 7, 9, 0xf6c85f, 0.18).setStrokeStyle(1, 0xf6c85f, 0.7));
        overlay.add(this.add.text(x + 25, rowY, String(index + 1), {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5, 0));
        overlay.add(this.add.text(x + 48, rowY - 2, step, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#c7dce7",
          wordWrap: { width: 242 },
          lineSpacing: 2,
        }));
      });
      return;
    }

    const readingLabels: Record<NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]["reading"], string> = {
      continuita: "continuità",
      interrotto: "interrotto",
      "polarita-inversa": "polarità inversa",
      "non-stabile": "non stabile",
      corto: "corto",
      "tensione-bassa": "tensione bassa",
      "soglia-fuori-range": "soglia fuori range",
      "carica-bassa": "carica bassa",
    };
    model.testerReadings.slice(0, 5).forEach((reading, index) => {
      const rowY = y + 50 + index * 39;
      overlay.add(this.add.rectangle(x + 18, rowY - 4, 294, 34, 0x102533, 0.7).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.14));
      overlay.add(this.add.text(x + 30, rowY, `${reading.from} -> ${reading.to}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#f5fbff",
        fontStyle: "bold",
        wordWrap: { width: 130 },
      }));
      overlay.add(this.add.text(x + 162, rowY, readingLabels[reading.reading], {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: reading.reading === "continuita" ? "#9ff5e9" : "#f7d37a",
        fontStyle: "bold",
      }));
      overlay.add(this.add.text(x + 30, rowY + 15, reading.note, {
        fontFamily: "Inter, Arial",
        fontSize: "9px",
        color: "#9aaab0",
        wordWrap: { width: 270 },
      }));
    });

    const guide = model.componentGuide.slice(0, 2).map((component) => `${component.label}: ${component.check}`).join("\n");
    overlay.add(this.add.text(x + 18, y + 244, guide, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9aaab0",
      wordWrap: { width: 288 },
      lineSpacing: 2,
    }));
  }

  private drawCircuitComponentChallenge(overlay: Phaser.GameObjects.Container, model: CircuitConsoleModel): void {
    const challenge = model.componentChallenges[Math.min(this.circuitConceptIndex, model.componentChallenges.length - 1)];
    if (!challenge) {
      this.circuitConceptVerified = true;
      this.openCircuit();
      return;
    }
    const total = model.componentChallenges.length;
    overlay.add(this.add.rectangle(452, 488, 816, 46, 0x07151d, 0.74).setStrokeStyle(1, 0xf6c85f, 0.2));
    overlay.add(this.add.text(64, 474, `Verifica componenti ${this.circuitConceptIndex + 1}/${total}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(64, 496, "Il simbolo evidenziato nello schema va riconosciuto prima di riparare: nome e funzione devono essere coerenti.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 760 },
    }));

    overlay.add(this.add.rectangle(254, 578, 392, 124, 0x07151d, 0.88).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(78, 526, challenge.symbolQuestion, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 352 },
    }));
    challenge.symbolChoices.forEach((choice, index) => {
      const selected = this.circuitSymbolAnswer === choice;
      overlay.add(new Button(this, 174 + (index % 2) * 180, 562 + Math.floor(index / 2) * 44, choice, () => {
        this.circuitSymbolAnswer = choice;
        audioManager.play("click");
        this.openCircuit();
      }, {
        width: 166,
        height: 36,
        fontSize: 9,
        fill: selected ? 0x173b36 : 0x142736,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
      }));
    });

    overlay.add(this.add.rectangle(652, 586, 392, 140, 0x07151d, 0.88).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(476, 526, challenge.functionQuestion, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 352 },
    }));
    challenge.functionChoices.forEach((choice, index) => {
      const selected = this.circuitFunctionAnswer === choice;
      overlay.add(new Button(this, 652, 556 + index * 40, choice, () => {
        this.circuitFunctionAnswer = choice;
        audioManager.play("click");
        this.openCircuit();
      }, {
        width: 352,
        height: 34,
        fontSize: 8,
        fill: selected ? 0x173b36 : 0x142736,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
      }));
    });

    overlay.add(this.add.rectangle(1010, 536, 304, 116, 0x07151d, 0.82).setStrokeStyle(1, 0xf6c85f, 0.22));
    overlay.add(this.add.text(876, 496, "Regola della console", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(876, 520, "Non devi memorizzare a caso: guarda il simbolo, chiediti cosa fa nel giro della corrente, poi scegli l'intervento.", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#d9eaf1",
      wordWrap: { width: 268 },
      lineSpacing: 3,
    }));
    overlay.add(new Button(this, 1010, 616, "Conferma componente", () => this.confirmCircuitComponentChallenge(challenge, model), {
      width: 250,
      height: 44,
      fontSize: 13,
      fill: 0x173b36,
    }));
  }

  private confirmCircuitComponentChallenge(challenge: CircuitComponentChallenge, model: CircuitConsoleModel): void {
    if (!this.circuitSymbolAnswer || !this.circuitFunctionAnswer) {
      feedbackSystem.publish("Prima scegli sia il simbolo sia la funzione del componente evidenziato.", "hint");
      audioManager.playOutcome("hint");
      return;
    }
    const symbolOk = this.circuitSymbolAnswer === challenge.correctSymbol;
    const functionOk = this.circuitFunctionAnswer === challenge.correctFunction;
    if (symbolOk && functionOk) {
      audioManager.playOutcome("correct");
      outcomeFeedback.play(this, "success", challenge.componentLabel);
      feedbackSystem.publish(`Componente riconosciuto: ${challenge.explanation}`, "success");
      this.circuitConceptIndex += 1;
      this.circuitSymbolAnswer = undefined;
      this.circuitFunctionAnswer = undefined;
      if (this.circuitConceptIndex >= model.componentChallenges.length) {
        this.circuitConceptVerified = true;
        feedbackSystem.publish("Modulo componenti superato: ora scegli solo le riparazioni dimostrate dal tester.", "success");
      }
      this.openCircuit();
      return;
    }
    const problem = !symbolOk && !functionOk
      ? "simbolo e funzione non sono coerenti"
      : !symbolOk
        ? "il simbolo scelto non corrisponde a quello evidenziato"
        : "la funzione scelta non spiega il ruolo del componente";
    const message = `${problem}. ${challenge.explanation}`;
    const exited = this.handleIncorrectAnswer(message);
    if (!exited) {
      this.circuitSymbolAnswer = undefined;
      this.circuitFunctionAnswer = undefined;
      this.openCircuit();
    }
  }

  private formatTesterReadings(model: CircuitConsoleModel): string {
    const readingLabels: Record<NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]["reading"], string> = {
      continuita: "continuità",
      interrotto: "interrotto",
      "polarita-inversa": "polarità inversa",
      "non-stabile": "non stabile",
      corto: "corto",
      "tensione-bassa": "tensione bassa",
      "soglia-fuori-range": "soglia fuori range",
      "carica-bassa": "carica bassa",
    };
    const readings = model.testerReadings
      .slice(0, 5)
      .map((reading, index) => `${index + 1}. ${reading.from} -> ${reading.to}: ${readingLabels[reading.reading]}. ${reading.note}`)
      .join("\n");
    const plan = model.diagnosticPlan.map((step, index) => `${index + 1}) ${step}`).join("  ");
    const components = model.componentGuide
      .slice(0, 4)
      .map((component) => `${component.label}: ${component.check}`)
      .join(" | ");
    return `Letture tester\n${readings}\n\nPiano: ${plan}\nComponenti chiave: ${components}`;
  }

  private circuitConceptLocked(): boolean {
    const puzzle = this.currentCircuitPuzzle();
    return Boolean((puzzle.componentChallenges?.length ?? 0) > 0 && !this.circuitConceptVerified);
  }

  private currentCircuitComponentTargetId(): string | undefined {
    const challenges = this.currentCircuitPuzzle().componentChallenges ?? [];
    return challenges[Math.min(this.circuitConceptIndex, challenges.length - 1)]?.componentId;
  }

  private drawCircuitDiagnostic(overlay: Phaser.GameObjects.Container): void {
    const puzzle = this.currentCircuitPuzzle();
    const activeFaults = new Set(puzzle.requiredRepairs.filter((fault) => !this.selectedRepairs.has(fault)));
    const lit = this.circuitWouldLight();
    const conceptLocked = this.circuitConceptLocked();
    const targetComponentId = this.currentCircuitComponentTargetId();
    const wireColor = lit ? 0x6be7d6 : 0x425865;
    const y = 248;
    const bottomY = 330;
    const positions = {
      battery: 94,
      switch: 226,
      resistor: 370,
      led: 522,
      return: 668,
    };
    const componentCenters: Record<string, { x: number; y: number }> = {
      battery: { x: positions.battery, y },
      switch: { x: positions.switch, y },
      resistor: { x: positions.resistor, y },
      led: { x: positions.led, y },
      return: { x: positions.return, y },
      capacitor: { x: 226, y: 366 },
      sensor: { x: 590, y: 366 },
      branchLed: { x: 404, y: 366 },
      relay: { x: 190, y: 386 },
      motor: { x: 350, y: 386 },
      ground: { x: 590, y: 386 },
    };

    overlay.add(this.add.rectangle(400, 276, 704, 214, 0x081823, 0.9).setStrokeStyle(1, 0x6be7d6, 0.26));
    overlay.add(this.add.text(58, 184, "Schema del giro della corrente", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    const path = this.add.graphics();
    path.lineStyle(5, wireColor, lit ? 0.9 : 0.45);
    path.beginPath();
    path.moveTo(positions.battery + 24, y);
    path.lineTo(positions.switch - 38, y);
    path.moveTo(positions.switch + 42, y);
    path.lineTo(positions.resistor - 48, y);
    path.moveTo(positions.resistor + 52, y);
    path.lineTo(positions.led - 46, y);
    path.moveTo(positions.led + 46, y);
    path.lineTo(positions.return - 36, y);
    path.moveTo(positions.return + 28, y);
    path.lineTo(positions.return + 28, bottomY);
    path.lineTo(positions.battery - 28, bottomY);
    path.lineTo(positions.battery - 28, y);
    path.strokePath();
    overlay.add(path);

    if (activeFaults.has("missing-wire")) {
      const broken = this.add.graphics();
      broken.lineStyle(6, 0xffb36b, 0.9);
      broken.beginPath();
      broken.moveTo(positions.led + 58, y);
      broken.lineTo(positions.return - 46, y);
      broken.strokePath();
      broken.lineStyle(2, 0x07151d, 1);
      broken.beginPath();
      broken.moveTo(positions.return - 88, y - 16);
      broken.lineTo(positions.return - 70, y + 16);
      broken.moveTo(positions.return - 68, y - 16);
      broken.lineTo(positions.return - 50, y + 16);
      broken.strokePath();
      overlay.add(broken);
    }

    this.drawBatterySymbol(overlay, positions.battery, y, 0xf6c85f);
    this.drawSwitchSymbol(overlay, positions.switch, y, activeFaults.has("open-switch") ? 0xffb36b : 0x9ff5e9, !activeFaults.has("open-switch"), !conceptLocked);
    this.drawResistorSymbol(overlay, positions.resistor, y, activeFaults.has("missing-resistor") || activeFaults.has("wrong-resistor-value") ? 0xffb36b : 0x9ff5e9, activeFaults.has("missing-resistor"), !conceptLocked);
    this.drawLedSymbol(overlay, positions.led, y, activeFaults.has("reversed-led") ? 0xffb36b : 0x9ff5e9, activeFaults.has("reversed-led"), lit, !conceptLocked);
    this.drawReturnSymbol(overlay, positions.return, y, activeFaults.has("missing-wire") || activeFaults.has("loose-ground") || activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9);

    [
      { x: positions.battery, code: "Nodo A", label: "Batteria", text: "spinge la corrente dal + al -" },
      { x: positions.switch, code: "Nodo B", label: "Interruttore", text: "chiude o apre il percorso" },
      { x: positions.resistor, code: "Nodo C", label: "Resistenza", text: "protegge il LED limitando la corrente" },
      { x: positions.led, code: "Nodo D", label: "LED", text: "si accende solo nel verso giusto" },
      { x: positions.return, code: "Nodo E", label: "Ritorno", text: "riporta la corrente al -" },
    ].forEach((item, index) => {
      overlay.add(this.add.text(item.x, 292, conceptLocked ? item.code : item.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      overlay.add(this.add.text(item.x, 312, conceptLocked ? `simbolo ${index + 1}` : item.text, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#9aaab0",
        align: "center",
        wordWrap: { width: 116 },
      }).setOrigin(0.5, 0));
    });

    this.drawCurrentArrows(overlay, lit ? 0x8cffd7 : 0x5c7480, lit ? 0.85 : 0.35, [
      { x: 160, y, rotation: 0 },
      { x: 450, y, rotation: 0 },
      { x: 696, y: 292, rotation: Math.PI / 2 },
      { x: 330, y: bottomY, rotation: Math.PI },
    ]);

    if (puzzle.nodes.includes("capacitor")) {
      this.drawCapacitorSymbol(overlay, 226, 366, activeFaults.has("capacitor-discharged") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("sensor")) {
      this.drawSensorSymbol(overlay, 590, 366, activeFaults.has("sensor-unpowered") || activeFaults.has("disconnected-component") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("branchLed")) {
      this.drawBranchSymbol(overlay, 404, 366, activeFaults.has("parallel-branch-open") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("relay")) {
      this.drawRelaySymbol(overlay, 190, 386, activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("motor")) {
      this.drawMotorSymbol(overlay, 350, 386, activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("ground")) {
      this.drawGroundSymbol(overlay, 590, 386, activeFaults.has("loose-ground") || activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }

    if (conceptLocked && targetComponentId && componentCenters[targetComponentId]) {
      const center = componentCenters[targetComponentId];
      overlay.add(this.add.circle(center.x, center.y, 54, 0xf6c85f, 0.08).setStrokeStyle(3, 0xf6c85f, 0.88));
      overlay.add(this.add.text(center.x, center.y - 70, "simbolo evidenziato", {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#f7d37a",
        fontStyle: "bold",
      }).setOrigin(0.5));
    }
  }

  private drawCapacitorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.beginPath();
    g.moveTo(x - 46, y);
    g.lineTo(x - 14, y);
    g.moveTo(x - 14, y - 22);
    g.lineTo(x - 14, y + 22);
    g.moveTo(x + 14, y - 22);
    g.lineTo(x + 14, y + 22);
    g.moveTo(x + 14, y);
    g.lineTo(x + 46, y);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 30, showLabel ? "condensatore: accumula carica" : "simbolo opzionale", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawSensorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, showLabel = true): void {
    overlay.add(this.add.rectangle(x, y, 150, 38, 0x0d2531, 0.92).setStrokeStyle(2, color, 0.78));
    const g = this.add.graphics();
    g.lineStyle(2, color, 0.9);
    g.strokeCircle(x - 40, y, 10);
    g.beginPath();
    g.moveTo(x - 24, y);
    g.lineTo(x + 40, y);
    g.moveTo(x + 24, y - 8);
    g.lineTo(x + 40, y);
    g.lineTo(x + 24, y + 8);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 30, showLabel ? "sensore: misura e invia dati" : "simbolo opzionale", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawBranchSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.88);
    g.beginPath();
    g.moveTo(x - 58, y - 20);
    g.lineTo(x - 22, y - 20);
    g.lineTo(x + 22, y + 20);
    g.lineTo(x + 58, y + 20);
    g.moveTo(x - 58, y + 20);
    g.lineTo(x - 22, y + 20);
    g.lineTo(x + 22, y - 20);
    g.lineTo(x + 58, y - 20);
    g.strokePath();
    g.strokeCircle(x, y, 10);
    overlay.add(g);
    overlay.add(this.add.text(x, y + 34, showLabel ? "ramo parallelo: può guastarsi da solo" : "simbolo opzionale", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawRelaySymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.strokeRect(x - 50, y - 18, 44, 36);
    g.beginPath();
    g.moveTo(x - 2, y);
    g.lineTo(x + 46, y - 16);
    g.moveTo(x + 22, y + 18);
    g.lineTo(x + 52, y + 18);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 32, showLabel ? "relè: comando + potenza" : "simbolo opzionale", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawMotorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.strokeCircle(x, y, 22);
    g.beginPath();
    g.moveTo(x - 44, y);
    g.lineTo(x - 22, y);
    g.moveTo(x + 22, y);
    g.lineTo(x + 44, y);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y - 8, "M", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: color === 0xffb36b ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(x, y + 32, showLabel ? "motore: carico più esigente" : "simbolo opzionale", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawGroundSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.beginPath();
    g.moveTo(x, y - 30);
    g.lineTo(x, y);
    g.moveTo(x - 30, y);
    g.lineTo(x + 30, y);
    g.moveTo(x - 20, y + 10);
    g.lineTo(x + 20, y + 10);
    g.moveTo(x - 10, y + 20);
    g.lineTo(x + 10, y + 20);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 34, showLabel ? "massa: ritorno stabile" : "simbolo opzionale", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawBatterySymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.95);
    g.beginPath();
    g.moveTo(x - 22, y - 24);
    g.lineTo(x - 22, y + 24);
    g.moveTo(x + 4, y - 15);
    g.lineTo(x + 4, y + 15);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x - 38, y - 36, "+", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    overlay.add(this.add.text(x + 20, y - 36, "-", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
  }

  private drawSwitchSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, closed: boolean, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.95);
    g.strokeCircle(x - 30, y, 4);
    g.strokeCircle(x + 30, y, 4);
    g.beginPath();
    g.moveTo(x - 26, y);
    g.lineTo(x + 24, closed ? y : y - 24);
    g.strokePath();
    overlay.add(g);
    if (showLabel) {
      overlay.add(this.add.text(x, y + 28, closed ? "chiuso" : "aperto", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: closed ? "#9ff5e9" : "#f7d37a",
      }).setOrigin(0.5));
    }
  }

  private drawResistorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, missing: boolean, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, missing ? 0.45 : 0.95);
    g.beginPath();
    g.moveTo(x - 42, y);
    g.lineTo(x - 30, y);
    for (let i = 0; i < 6; i += 1) {
      g.lineTo(x - 20 + i * 8, y + (i % 2 === 0 ? -12 : 12));
    }
    g.lineTo(x + 32, y);
    g.lineTo(x + 44, y);
    g.strokePath();
    overlay.add(g);
    if (showLabel) {
      overlay.add(this.add.text(x, y + 30, missing ? "manca" : "220 ohm", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: missing ? "#f7d37a" : "#9ff5e9",
      }).setOrigin(0.5));
    }
  }

  private drawLedSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, reversed: boolean, lit: boolean, showLabel = true): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.95);
    g.beginPath();
    if (reversed) {
      g.moveTo(x + 24, y - 22);
      g.lineTo(x - 18, y);
      g.lineTo(x + 24, y + 22);
      g.closePath();
      g.moveTo(x - 24, y - 22);
      g.lineTo(x - 24, y + 22);
    } else {
      g.moveTo(x - 24, y - 22);
      g.lineTo(x + 18, y);
      g.lineTo(x - 24, y + 22);
      g.closePath();
      g.moveTo(x + 24, y - 22);
      g.lineTo(x + 24, y + 22);
    }
    g.strokePath();
    g.beginPath();
    g.moveTo(x + 18, y - 34);
    g.lineTo(x + 34, y - 50);
    g.moveTo(x + 28, y - 26);
    g.lineTo(x + 44, y - 42);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.circle(x + 64, y, 16, lit ? 0x8cffd7 : 0x243541, lit ? 0.95 : 0.78).setStrokeStyle(2, color, 0.7));
    if (showLabel) {
      overlay.add(this.add.text(x, y + 30, reversed ? "invertito" : lit ? "acceso" : "spento", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: reversed ? "#f7d37a" : lit ? "#9ff5e9" : "#9aaab0",
      }).setOrigin(0.5));
    }
  }

  private drawReturnSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.beginPath();
    g.moveTo(x - 28, y);
    g.lineTo(x + 28, y);
    g.moveTo(x, y);
    g.lineTo(x, y + 36);
    g.moveTo(x - 22, y + 36);
    g.lineTo(x + 22, y + 36);
    g.moveTo(x - 14, y + 46);
    g.lineTo(x + 14, y + 46);
    g.moveTo(x - 6, y + 56);
    g.lineTo(x + 6, y + 56);
    g.strokePath();
    overlay.add(g);
  }

  private drawCurrentArrows(
    overlay: Phaser.GameObjects.Container,
    color: number,
    alpha: number,
    arrows: Array<{ x: number; y: number; rotation: number }>,
  ): void {
    arrows.forEach((arrow) => {
      const tri = this.add.triangle(arrow.x, arrow.y, 0, -6, 14, 0, 0, 6, color, alpha)
        .setRotation(arrow.rotation)
        .setOrigin(0.5);
      overlay.add(tri);
    });
  }

  private circuitWouldLight(): boolean {
    const puzzle = this.currentCircuitPuzzle();
    const lightBlockingFaults = new Set<CircuitFaultType>([
      "missing-wire",
      "open-switch",
      "reversed-led",
      "short-circuit",
      "loose-ground",
    ]);
    return puzzle.requiredRepairs
      .filter((fault) => lightBlockingFaults.has(fault))
      .every((fault) => this.selectedRepairs.has(fault));
  }

  private animateCircuitTest(success: boolean, onComplete: () => void): void {
    const flash = this.add.rectangle(400, 302, 706, 238, success ? 0x6be7d6 : 0xc94b55, success ? 0.18 : 0.22);
    this.overlay?.add(flash);
    audioManager.play(success ? "circuitOn" : "error");
    this.tweens.add({
      targets: flash,
      alpha: 0,
      scale: 1.04,
      duration: 520,
      onComplete: () => {
        flash.destroy();
        onComplete();
      },
    });
  }

  private openMath(): void {
    const puzzle = this.currentMathPuzzle();
    if (puzzle.minigame) {
      this.openMathMinigame(puzzle);
      return;
    }
    const model = MathTerminal.fromPuzzle(puzzle);
    const overlay = this.createMathOverlay(model.title);

    this.addMathPanel(overlay, 28, 102, 378, 438, "Briefing matematico");
    overlay.add(this.add.text(54, 146, model.difficultyLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(54, 172, `Ambito: ${model.domainLabel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    if (model.curriculumTags.length > 0) {
      overlay.add(this.add.text(54, 196, `Concetti: ${model.curriculumTags.slice(0, 4).join(" · ")}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 326 },
      }));
    }
    overlay.add(this.add.text(54, 236, model.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 320, useAdvancedWrap: true },
      lineSpacing: 4,
    }));

    this.drawMathLogicVisualizer(overlay, puzzle, model, 430, 102, 500, 438);

    this.addMathPanel(overlay, 954, 102, 298, 438, "Console di risposta");
    overlay.add(this.add.text(982, 148, "Inserisci solo il valore finale quando hai una strategia chiara.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 242 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(1016, 216, "Risultato", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      fontStyle: "bold",
    }));
    overlay.add(this.add.rectangle(1102, 270, 156, 70, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.56));
    overlay.add(this.add.text(1040, 248, this.mathEntry.padEnd(4, "-"), {
      fontFamily: "Inter, Arial",
      fontSize: "42px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const keypadY = 348;
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"].forEach((key, index) => {
      overlay.add(new Button(this, 1024 + (index % 3) * 76, keypadY + Math.floor(index / 3) * 42, key, () => this.pressMathKey(key), {
        width: 58,
        height: 34,
        fontSize: 17,
        fill: key === "OK" ? 0x173b36 : 0x142736,
      }));
    });

    this.addMathPanel(overlay, 28, 556, 1224, 132, "Supporti intelligenti");
    overlay.add(this.add.text(54, 596, [
      `Scopo didattico: ${model.learningPurpose}`,
      `Metodo consigliato: ${model.strategy}`,
      model.mentalMathNote,
      `Appunti: ${model.scratchpadPrompt}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 620 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(990, 596, 478, 44, 0x07151d, 0.82).setStrokeStyle(1, 0xf6c85f, 0.28));
    this.mathSupportText = this.add.text(760, 580, this.mathSupportMessage || "Scegli un aiuto solo quando serve: ogni supporto guida il ragionamento e viene conteggiato nel punteggio.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.mathSupportMessage ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 460, useAdvancedWrap: true },
      lineSpacing: 3,
    });
    overlay.add(this.mathSupportText);
    overlay.add(new Button(this, 812, 660, "Indizio", () => this.showMathSupport(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])), {
      width: 150,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1000, 660, "Passo guidato", () => this.revealMathStep(puzzle), {
      width: 180,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1180, 660, "Teoria breve", () => this.revealMathTheory(model), {
      width: 170,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  private createMathOverlay(title: string): Phaser.GameObjects.Container {
    this.clearOverlay();
    const overlay = this.add.container(0, 0).setDepth(1200);
    SceneChrome.modalInputBlocker(this, overlay);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02080d, 0.96));
    if (this.textures.exists("bg-lab-painted")) {
      overlay.add(this.add.image(640, 360, "bg-lab-painted").setDisplaySize(1320, 742).setAlpha(0.32));
    }
    const grid = this.add.graphics();
    grid.lineStyle(1, 0x6be7d6, 0.06);
    for (let x = -100; x < 1380; x += 72) {
      grid.lineBetween(x, 0, x - 128, 720);
    }
    for (let y = 86; y < 720; y += 58) {
      grid.lineBetween(0, y, 1280, y + 10);
    }
    overlay.add(grid);
    overlay.add(this.add.rectangle(640, 52, 1280, 104, 0x06131c, 0.86));
    overlay.add(this.add.rectangle(640, 103, 1280, 2, 0x6be7d6, 0.34));
    overlay.add(this.add.text(36, 24, title, {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    overlay.add(this.add.text(38, 68, "Laboratorio matematico - mappa visiva del ragionamento", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
    }));
    overlay.add(new Button(this, 1224, 48, "X", () => this.closeOverlayFromUser(), {
      width: 56,
      height: 42,
      fontSize: 18,
      fill: 0x263743,
    }));
    this.overlay = overlay;
    return overlay;
  }

  private addMathPanel(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    height: number,
    title: string,
  ): void {
    overlay.add(VisualKit.glassPanel(this, x, y, width, height, "lab", 0.84));
    overlay.add(this.add.text(x + 24, y + 20, title, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
  }

  private drawMathLogicVisualizer(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    model: MathTerminalModel,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    this.addMathPanel(overlay, x, y, width, height, "Mappa visiva");
    overlay.add(this.add.text(x + 24, y + 58, "Leggi il problema come un sistema: dati -> regola -> trasformazione -> controllo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: width - 48 },
    }));

    const archetype = puzzle.archetype ?? "calcolo-diretto";
    if (archetype === "frazioni" || archetype === "percentuali" || archetype === "proporzione") {
      this.drawShareVisualizer(overlay, x, y, width, archetype);
    } else if (archetype === "geometria") {
      this.drawGeometryVisualizer(overlay, x, y, width, model.curriculumTags);
    } else if (archetype === "coordinate") {
      this.drawCoordinateVisualizer(overlay, x, y);
    } else if (archetype === "statistica" || archetype === "probabilita" || archetype === "lettura-dati") {
      this.drawDataVisualizer(overlay, x, y, archetype);
    } else if (
      archetype === "funzione-lineare"
      || archetype === "sistemi-lineari"
      || archetype === "pre-algebra"
      || archetype === "ragionamento-inverso"
      || archetype === "equazione-primo-grado"
    ) {
      this.drawAlgebraVisualizer(overlay, x, y, width, archetype);
    } else if (archetype === "sequenza" || archetype === "potenze-radici") {
      this.drawSequenceVisualizer(overlay, x, y, archetype);
    } else {
      this.drawOperationVisualizer(overlay, x, y, width);
    }

    this.drawMathReasoningRail(overlay, x + 42, y + height - 82, width - 84, [
      "Dati",
      "Regola",
      "Passaggi",
      "Verifica",
    ]);
  }

  private drawShareVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const barX = x + 68;
    const barY = y + 178;
    const segmentW = (width - 136) / 6;
    g.fillStyle(0x07151d, 0.9);
    g.fillRoundedRect(barX - 10, barY - 18, width - 116, 96, 10);
    for (let index = 0; index < 6; index += 1) {
      const color = index < 3 ? 0x6be7d6 : index < 5 ? 0xf6c85f : 0x315766;
      g.fillStyle(color, index < 5 ? 0.58 : 0.22);
      g.fillRoundedRect(barX + index * segmentW, barY, segmentW - 5, 34, 6);
      g.lineStyle(1, 0xffffff, 0.1);
      g.strokeRoundedRect(barX + index * segmentW, barY, segmentW - 5, 34, 6);
    }
    overlay.add(g);
    const label = archetype === "percentuali"
      ? "100% = intero, poi calcola la quota richiesta"
      : archetype === "proporzione"
        ? "Stesso rapporto, scala diversa"
        : "Quote dello stesso intero, poi resto";
    overlay.add(this.add.text(x + 72, y + 138, label, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 74, y + 232, "Non dividere il resto per errore: identifica prima l'intero iniziale.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 140 },
    }));
  }

  private drawGeometryVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    tags: string[],
  ): void {
    const g = this.add.graphics();
    const isPythagoras = tags.some((tag) => tag.toLowerCase().includes("pitagora"));
    g.lineStyle(3, 0x6be7d6, 0.85);
    g.fillStyle(0x07151d, 0.62);
    if (isPythagoras) {
      const ax = x + 126;
      const ay = y + 284;
      const bx = x + 126;
      const by = y + 148;
      const cx = x + 348;
      const cy = y + 284;
      g.fillTriangle(ax, ay, bx, by, cx, cy);
      g.strokeTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(2, 0xf6c85f, 0.78);
      g.lineBetween(bx, by, cx, cy);
      overlay.add(g);
      overlay.add(this.add.text(x + 164, y + 116, "Triangolo rettangolo: i due lati perpendicolari determinano la diagonale.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f7d37a",
        wordWrap: { width: width - 120 },
      }));
    } else {
      g.fillRoundedRect(x + 116, y + 146, 258, 146, 8);
      g.strokeRoundedRect(x + 116, y + 146, 258, 146, 8);
      g.lineStyle(2, 0xf6c85f, 0.7);
      g.strokeRoundedRect(x + 106, y + 136, 278, 166, 10);
      overlay.add(g);
      overlay.add(this.add.text(x + 144, y + 116, "Area = spazio interno. Perimetro = bordo esterno.", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f7d37a",
        fontStyle: "bold",
      }));
    }
    overlay.add(this.add.text(x + 88, y + 324, "Prima scegli la grandezza giusta, poi applica la formula. Area, perimetro e distanza non misurano la stessa cosa.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 116 },
    }));
  }

  private drawCoordinateVisualizer(overlay: Phaser.GameObjects.Container, x: number, y: number): void {
    const g = this.add.graphics();
    const originX = x + 142;
    const originY = y + 304;
    const cell = 32;
    g.lineStyle(1, 0x6be7d6, 0.16);
    for (let i = 0; i <= 7; i += 1) {
      g.lineBetween(originX, originY - i * cell, originX + 7 * cell, originY - i * cell);
      g.lineBetween(originX + i * cell, originY, originX + i * cell, originY - 7 * cell);
    }
    g.lineStyle(4, 0xf6c85f, 0.82);
    g.lineBetween(originX + cell, originY - cell, originX + 5 * cell, originY - cell);
    g.lineBetween(originX + 5 * cell, originY - cell, originX + 5 * cell, originY - 5 * cell);
    overlay.add(g);
    overlay.add(this.add.circle(originX + cell, originY - cell, 8, 0x6be7d6, 1));
    overlay.add(this.add.star(originX + 5 * cell, originY - 5 * cell, 5, 7, 16, 0xf6c85f, 1));
    overlay.add(this.add.text(x + 84, y + 124, "Conta spostamento orizzontale e verticale: niente diagonali.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
  }

  private drawDataVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const values = [54, 86, 128, 102, 168];
    values.forEach((value, index) => {
      g.fillStyle(index === 2 ? 0xf6c85f : 0x6be7d6, index === 2 ? 0.78 : 0.42);
      g.fillRoundedRect(x + 116 + index * 58, y + 304 - value, 34, value, 6);
    });
    g.lineStyle(2, 0x9aaab0, 0.42);
    g.lineBetween(x + 94, y + 304, x + 414, y + 304);
    overlay.add(g);
    const label = archetype === "probabilita"
      ? "Rapporto -> frequenza attesa"
      : "Dati -> misura stabile -> codice";
    overlay.add(this.add.text(x + 112, y + 126, label, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 98, y + 330, "Non scegliere il numero piu vistoso: controlla quale misura chiede il terminale.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 330 },
    }));
  }

  private drawAlgebraVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const cy = y + 224;
    const boxes = [
      {
        x: x + 90,
        label: archetype === "ragionamento-inverso"
          ? "Uscita"
          : archetype === "equazione-primo-grado"
            ? "Equilibrio"
            : "Ingresso x",
      },
      {
        x: x + 242,
        label: archetype === "sistemi-lineari"
          ? "Relazioni"
          : archetype === "equazione-primo-grado"
            ? "Operazioni inverse"
            : "Regola",
      },
      {
        x: x + 394,
        label: archetype === "ragionamento-inverso"
          ? "Ingresso"
          : archetype === "equazione-primo-grado"
            ? "x isolata"
            : "Uscita y",
      },
    ];
    g.lineStyle(3, 0x6be7d6, 0.6);
    g.lineBetween(boxes[0].x + 54, cy, boxes[1].x - 54, cy);
    g.lineBetween(boxes[1].x + 54, cy, boxes[2].x - 54, cy);
    overlay.add(g);
    boxes.forEach((box, index) => {
      overlay.add(this.add.rectangle(box.x, cy, 108, 72, index === 1 ? 0x173b36 : 0x07151d, 0.92).setStrokeStyle(2, index === 1 ? 0xf6c85f : 0x6be7d6, 0.68));
      overlay.add(this.add.text(box.x, cy, box.label, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f5fbff",
        align: "center",
        wordWrap: { width: 86 },
      }).setOrigin(0.5));
    });
    const caption = archetype === "sistemi-lineari"
      ? "Due informazioni insieme isolano le incognite."
      : archetype === "equazione-primo-grado"
        ? "Una bilancia resta vera solo se fai la stessa operazione su entrambi i lati."
        : "Una regola trasforma, l'operazione inversa ricostruisce.";
    overlay.add(this.add.text(x + 78, y + 126, caption, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 120 },
    }));
  }

  private drawSequenceVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const startX = x + 96;
    const startY = y + 286;
    const nodes = archetype === "potenze-radici" ? [0, 34, 82, 154] : [0, 42, 92, 156];
    g.lineStyle(3, 0x6be7d6, 0.48);
    nodes.forEach((rise, index) => {
      const px = startX + index * 94;
      const py = startY - rise;
      if (index > 0) {
        const prevX = startX + (index - 1) * 94;
        const prevY = startY - nodes[index - 1];
        g.lineBetween(prevX, prevY, px, py);
      }
    });
    overlay.add(g);
    nodes.forEach((rise, index) => {
      overlay.add(this.add.circle(startX + index * 94, startY - rise, 16, index === nodes.length - 1 ? 0xf6c85f : 0x6be7d6, 0.82));
    });
    overlay.add(this.add.text(x + 82, y + 126, archetype === "potenze-radici" ? "Crescita ripetuta: controlla quante volte applichi la stessa regola." : "Osserva i salti: il prossimo valore nasce dalla regola, non dal caso.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 360 },
    }));
  }

  private drawOperationVisualizer(overlay: Phaser.GameObjects.Container, x: number, y: number, width: number): void {
    const labels = ["Valore", "Operazione", "Intermedio", "Codice"];
    labels.forEach((label, index) => {
      const cx = x + 86 + index * 110;
      overlay.add(this.add.rectangle(cx, y + 224, 92, 62, index === labels.length - 1 ? 0x173b36 : 0x07151d, 0.92).setStrokeStyle(2, index === labels.length - 1 ? 0xf6c85f : 0x6be7d6, 0.56));
      overlay.add(this.add.text(cx, y + 224, label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        align: "center",
      }).setOrigin(0.5));
      if (index < labels.length - 1) {
        overlay.add(this.add.triangle(cx + 60, y + 224, 0, -7, 14, 0, 0, 7, 0x6be7d6, 0.72));
      }
    });
    overlay.add(this.add.text(x + 82, y + 126, "Trasforma un valore alla volta e conserva i risultati intermedi.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 120 },
    }));
  }

  private drawMathReasoningRail(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    labels: string[],
  ): void {
    const g = this.add.graphics();
    const gap = width / (labels.length - 1);
    g.lineStyle(2, 0x6be7d6, 0.32);
    g.lineBetween(x, y, x + width, y);
    overlay.add(g);
    labels.forEach((label, index) => {
      const cx = x + index * gap;
      overlay.add(this.add.circle(cx, y, 12, index === 0 ? 0xf6c85f : 0x6be7d6, 0.82));
      overlay.add(this.add.text(cx, y + 24, label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
      }).setOrigin(0.5));
    });
  }

  private revealMathStep(puzzle: GeneratedMathPuzzle): void {
    const steps = puzzle.solutionSteps ?? [];
    if (steps.length === 0) {
      this.showMathSupport("Scomponi il problema in dati, operazione richiesta e controllo finale.");
      return;
    }
    const index = Math.min(this.mathStepIndex, steps.length - 1);
    this.mathStepIndex = Math.min(index + 1, steps.length - 1);
    this.showMathSupport(`Passo guidato ${index + 1}/${steps.length}: ${steps[index]}`);
  }

  private revealMathTheory(model: MathTerminalModel): void {
    this.showMathSupport(`Teoria breve: ${model.theoryPrinciple} Strategia: ${model.strategy}`);
  }

  private showMathSupport(text: string): void {
    this.mathSupportMessage = text;
    this.useHint(text);
    this.mathSupportText?.setText(text).setColor("#f7d37a");
    if (this.mathSupportText) {
      this.tweens.add({
        targets: this.mathSupportText,
        alpha: { from: 0.35, to: 1 },
        duration: 180,
        ease: "Sine.easeOut",
      });
    }
  }

  private pressMathKey(key: string): void {
    const puzzle = this.currentMathPuzzle();
    if (key === "C") {
      this.mathEntry = "";
      this.openMath();
      return;
    }
    if (key === "OK") {
      const enteredValue = Number(this.mathEntry);
      if (enteredValue === puzzle.answer) {
        this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
        return;
      }
      this.mathEntry = "";
      this.mathSupportMessage = `Il valore ${Number.isFinite(enteredValue) ? enteredValue : "inserito"} non chiude il terminale. Controlla un passaggio intermedio, non provare numeri a caso. ${this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])}`;
      if (this.handleIncorrectAnswer(this.mathSupportMessage)) {
        return;
      }
      this.openMath();
      return;
    }
    if (this.mathEntry.length < 4) {
      this.mathEntry += key;
      this.openMath();
    }
  }

  private openMathMinigame(puzzle: GeneratedMathPuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("math");
    const session = this.ensureMathMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title);
    const prompt = this.currentMathMinigamePrompt(session);
    const remaining = this.mathMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 548, 432, "Arena punta-e-clicca");
    overlay.add(this.add.text(60, 156, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f7d37a",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    this.drawMathMinigameVisualizer(overlay, prompt, 64, 218, 460, 218);
    overlay.add(this.add.text(60, 468, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 472 },
    }));
    overlay.add(this.add.text(60, 496, this.mathMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 476, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    this.addMathPanel(overlay, 604, 112, 648, 432, "Obiettivo rapido");
    overlay.add(this.add.text(636, 156, "60 secondi di calcolo: osserva, scegli, conferma. Le tessere sbagliate penalizzano il punteggio.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 560 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(636, 212, prompt.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 560, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    const tileStartX = 700;
    const tileStartY = 334;
    prompt.tiles.forEach((tile, index) => {
      const selected = session.selectedIds.has(tile.id);
      const col = index % 3;
      const row = Math.floor(index / 3);
      overlay.add(new Button(this, tileStartX + col * 186, tileStartY + row * 64, tile.label, () => this.toggleMathMinigameTile(tile.id), {
        width: 164,
        height: 48,
        fontSize: tile.label.length > 12 ? 11 : 20,
        wordWrapWidth: 142,
        fill: selected ? 0x174d42 : 0x263743,
        stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });

    this.addMathPanel(overlay, 28, 558, 1224, 130, "Ritmo e valutazione");
    this.mathMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(this.mathMinigameTimerText);
    overlay.add(this.add.text(260, 592, [
      `Corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie: ${session.streak}`,
      `Punti: ${session.netScore}`,
    ].join("   "), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 640 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(260, 636, session.feedback || puzzle.minigame.scoringRule, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: session.feedback ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 650, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 858, 640, "Pulisci scelta", () => this.clearMathMinigameSelection(), {
      width: 174,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1046, 640, "Conferma", () => this.confirmMathMinigamePrompt(), {
      width: 174,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 686, 640, "Indizio", () => this.useMathMinigameHint(), {
      width: 138,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.mathMinigameTimerEvent?.remove(false);
    this.mathMinigameTimerEvent = this.time.addEvent({
      delay: 250,
      loop: true,
      callback: () => this.refreshMathMinigameTimer(),
    });
    this.refreshMathMinigameTimer();
  }

  private ensureMathMinigameSession(
    puzzleId: string,
    puzzle: GeneratedMathPuzzle,
    game: GeneratedMathMinigame,
  ): MathMinigameSession {
    if (this.mathMinigameSession?.puzzleId === puzzleId && !this.mathMinigameSession.summaryOpen) {
      return this.mathMinigameSession;
    }
    this.mathMinigameSession = {
      puzzleId,
      puzzle,
      game,
      startedAt: Date.now(),
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      feedback: "Scegli con metodo: una conferma sbagliata riduce il punteggio e in missione consuma una vita.",
      locked: false,
      summaryOpen: false,
    };
    return this.mathMinigameSession;
  }

  private drawMathMinigameVisualizer(
    overlay: Phaser.GameObjects.Container,
    prompt: MathMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const g = this.add.graphics();
    g.fillStyle(0x07151d, 0.74);
    g.fillRoundedRect(x, y, width, height, 12);
    g.lineStyle(2, 0x6be7d6, 0.3);
    g.strokeRoundedRect(x, y, width, height, 12);
    overlay.add(g);
    if (prompt.type === "target-sum") {
      const target = Number(prompt.targetLabel.replace(/\D+/g, ""));
      const pieces = prompt.tiles.map((tile) => tile.value ?? 0).filter((value) => value > 0);
      const scale = Math.max(1, target || pieces.reduce((sum, value) => sum + value, 0));
      pieces.forEach((value, index) => {
        const barWidth = Math.max(34, Math.round((value / scale) * (width - 116)));
        const yOffset = y + 34 + index * 24;
        g.fillStyle(0x6be7d6, 0.22);
        g.fillRoundedRect(x + 44, yOffset, barWidth, 14, 6);
        overlay.add(this.add.text(x + 54, yOffset + 4, `${value}`, {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#f5fbff",
          fontStyle: "bold",
        }));
      });
      overlay.add(this.add.text(x + 44, y + height - 46, "Le barre mostrano tutte le tessere, non la soluzione: scegli solo quelle che arrivano al totale.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: width - 88 },
      }));
      return;
    }
    if (prompt.type === "factor-hunt") {
      prompt.tiles.slice(0, 7).forEach((tile, index) => {
        const cx = x + 66 + (index % 4) * 96;
        const cy = y + 56 + Math.floor(index / 4) * 62;
        g.lineStyle(2, 0x6be7d6, 0.24);
        g.strokeCircle(cx, cy, 24);
        overlay.add(this.add.text(cx, cy, tile.label, {
          fontFamily: "Inter, Arial",
          fontSize: "17px",
          color: "#f5fbff",
          fontStyle: "bold",
        }).setOrigin(0.5));
      });
      overlay.add(this.add.text(x + 44, y + height - 52, "Non cercare solo numeri grandi: prova la divisione e controlla se resta qualcosa.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: width - 88 },
      }));
      return;
    }
    const labels = prompt.targetLabel.split("->").map((item) => item.trim());
    const start = labels[0] ?? "?";
    const target = labels[1] ?? "?";
    [start, "?", target].forEach((label, index) => {
      const cx = x + 86 + index * 150;
      overlay.add(this.add.rectangle(cx, y + 92, 84, 58, index === 1 ? 0x173b36 : 0x07151d, 0.9)
        .setStrokeStyle(2, index === 1 ? 0xf7d37a : 0x6be7d6, 0.64));
      overlay.add(this.add.text(cx, y + 92, label, {
        fontFamily: "Inter, Arial",
        fontSize: "24px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      if (index < 2) {
        overlay.add(this.add.triangle(cx + 76, y + 92, 0, -8, 18, 0, 0, 8, 0x6be7d6, 0.72));
      }
    });
    overlay.add(this.add.text(x + 44, y + height - 52, "Pensa alla macchina come a una catena: ogni operazione cambia il valore in ordine.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 88 },
    }));
  }

  private mathMinigameMethodText(prompt: MathMinigamePrompt): string {
    if (prompt.type === "target-sum") {
      return "Metodo: non sommare tutto. Cerca prima un addendo vicino al bersaglio, poi completa senza superare il totale.";
    }
    if (prompt.type === "factor-hunt") {
      return "Metodo: prova la divisione. Se il resto è zero, il numero rispetta il vincolo; altrimenti è un distrattore.";
    }
    return "Metodo: simula mentalmente la rotta da sinistra a destra. Una trasformazione plausibile non basta: deve arrivare esattamente all'uscita.";
  }

  private currentMathMinigamePrompt(session: MathMinigameSession): MathMinigamePrompt {
    return session.game.prompts[session.promptIndex % session.game.prompts.length];
  }

  private mathMinigameElapsedMs(session: MathMinigameSession): number {
    return Math.max(0, Date.now() - session.startedAt);
  }

  private mathMinigameRemainingMs(session: MathMinigameSession): number {
    return Math.max(0, session.durationMs - this.mathMinigameElapsedMs(session));
  }

  private refreshMathMinigameTimer(): void {
    const session = this.mathMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    const remaining = this.mathMinigameRemainingMs(session);
    this.mathMinigameTimerText?.setText(`Tempo: ${formatDuration(remaining)}`);
    this.mathMinigameTimerText?.setColor(remaining <= 10_000 ? "#ff8f8f" : "#f7d37a");
    if (remaining <= 0) {
      this.finishMathMinigame();
    }
  }

  private toggleMathMinigameTile(tileId: string): void {
    const session = this.mathMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentMathMinigamePrompt(session);
    if (prompt.requiredSelectionCount === 1 && !session.selectedIds.has(tileId)) {
      session.selectedIds.clear();
      session.selectedIds.add(tileId);
    } else if (session.selectedIds.has(tileId)) {
      session.selectedIds.delete(tileId);
    } else {
      session.selectedIds.add(tileId);
    }
    audioManager.play("click");
    this.openMathMinigame(session.puzzle);
  }

  private clearMathMinigameSelection(): void {
    const session = this.mathMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.feedback = "Scelta pulita. Ricomincia dalla regola, non dai pulsanti.";
    this.openMathMinigame(session.puzzle);
  }

  private useMathMinigameHint(): void {
    const session = this.mathMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentMathMinigamePrompt(session);
    const hint = prompt.type === "target-sum"
      ? "Scomponi il bersaglio: cerca prima una coppia o una terna che non superi il totale."
      : prompt.type === "factor-hunt"
        ? "Per multipli e divisori controlla il resto della divisione: resto zero significa tessera valida."
        : "Parti dal valore iniziale e simula la prima operazione prima di guardare la seconda.";
    session.feedback = hint;
    this.useHint(hint);
    this.openMathMinigame(session.puzzle);
  }

  private confirmMathMinigamePrompt(): void {
    const session = this.mathMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (this.mathMinigameRemainingMs(session) <= 0) {
      this.finishMathMinigame();
      return;
    }
    const prompt = this.currentMathMinigamePrompt(session);
    if (session.selectedIds.size === 0) {
      session.feedback = "Prima scegli una o più tessere, poi conferma. Il timer continua.";
      audioManager.playOutcome("hint");
      this.openMathMinigame(session.puzzle);
      return;
    }
    const correctIds = new Set(prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.id));
    const exactSelection = session.selectedIds.size === correctIds.size
      && [...session.selectedIds].every((id) => correctIds.has(id));
    if (!exactSelection) {
      const selectedLabels = prompt.tiles
        .filter((tile) => session.selectedIds.has(tile.id))
        .map((tile) => tile.label)
        .join(", ");
      const message = `Scelta non certificabile (${selectedLabels || "nessuna"}). Soluzione: ${prompt.solutionLabels.join(", ")}. ${prompt.explanation}`;
      if (this.isTimedMissionMode()) {
        this.mathMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (8 + this.run.difficulty));
      session.feedback = message;
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      outcomeFeedback.play(this, "warning", "Calcolo da rivedere");
      this.advanceMathMinigamePrompt(720);
      return;
    }

    session.answered += 1;
    session.correct += 1;
    session.streak += 1;
    session.bestStreak = Math.max(session.bestStreak, session.streak);
    const award = 10 + this.run.difficulty * 2 + Math.min(10, session.streak * 2);
    session.netScore += award;
    session.feedback = `Corretta: ${prompt.explanation} +${award}`;
    session.locked = true;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceMathMinigamePrompt(420);
  }

  private advanceMathMinigamePrompt(delayMs: number): void {
    const session = this.mathMinigameSession;
    if (!session) {
      return;
    }
    this.runWhenActive(delayMs, () => {
      if (this.mathMinigameSession !== session || session.summaryOpen) {
        return;
      }
      if (this.mathMinigameRemainingMs(session) <= 0) {
        this.finishMathMinigame();
        return;
      }
      const previous = this.currentMathMinigamePrompt(session).signature;
      session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      if (this.currentMathMinigamePrompt(session).signature === previous) {
        session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      }
      session.selectedIds.clear();
      session.locked = false;
      this.openMathMinigame(session.puzzle);
    });
  }

  private finishMathMinigame(): void {
    const session = this.mathMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    session.locked = true;
    session.summaryOpen = true;
    this.mathMinigameTimerEvent?.remove(false);
    this.mathMinigameTimerEvent = undefined;
    audioManager.playOutcome("neutral");
    this.showMathMinigameSummary(session);
  }

  private mathMinigamePassed(session: MathMinigameSession): boolean {
    if (!this.isTimedMissionMode()) {
      return true;
    }
    const minCorrect = Math.max(5, Math.min(12, 4 + Math.ceil(this.run.difficulty * 0.75)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    return session.correct >= minCorrect && accuracy >= 0.6 && session.netScore > 0;
  }

  private mathMinigameFeedback(session: MathMinigameSession): string {
    if (session.answered === 0) {
      return "Nessuna risposta: serve almeno iniziare a leggere la regola e selezionare tessere.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.9 && session.bestStreak >= 8) {
      return "Calcolo fluido: hai mantenuto velocità e controllo senza cadere nei distrattori.";
    }
    if (accuracy >= 0.7) {
      return "Buona precisione: prova a riconoscere prima il vincolo, poi aumenta la velocità.";
    }
    if (session.wrong >= session.correct) {
      return "Troppi tentativi: rallenta, formula la regola e conferma solo quando puoi spiegare la scelta.";
    }
    return "Allenamento utile: hai lavorato sul metodo, ora cerca serie più lunghe senza errori.";
  }

  private showMathMinigameSummary(session: MathMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const passed = this.mathMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(this.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(this.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(this.add.text(230, 160, passed ? "Sprint matematico completato" : "Sprint matematico da consolidare", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: passed ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(230, 210, [
      `Risposte corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie migliore: ${session.bestStreak}`,
      `Punti sprint: ${session.netScore}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      lineSpacing: 7,
    }));
    modal.add(this.add.rectangle(548, 212, 408, 128, 0x102533, 0.78).setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(this.add.text(572, 234, this.mathMinigameFeedback(session), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 354 },
      lineSpacing: 5,
    }));
    modal.add(this.add.rectangle(230, 378, 740, 74, 0x0b1e2a, 0.82).setOrigin(0)
      .setStrokeStyle(1, 0xf7d37a, 0.36));
    modal.add(this.add.text(254, 394, (mode === "mission" || mode === "progressive")
      ? passed
        ? "La console matematica accetta la sequenza rapida: calcolo, controllo e precisione sono sufficienti."
        : "La soglia minima non è stata raggiunta: perderai una vita, ma le console già completate restano stabili."
      : "Allenamento registrabile: migliorano tempo, precisione, serie positiva e consapevolezza degli errori.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    modal.add(new Button(this, 612, 506, (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua", () => {
      modal.destroy(true);
      if (!passed && (mode === "mission" || mode === "progressive")) {
        this.loseMissionLife("sprint matematico sotto soglia: servono più risposte corrette con meno tentativi.");
        return;
      }
      this.completeMathMinigame(session);
    }, {
      width: 270,
      height: 54,
      fill: passed ? 0x173b36 : 0x263743,
      stroke: passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private completeMathMinigame(session: MathMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeMathMinigameScore(session);
    saveSystem.markProceduralPuzzleSolved(session.puzzleId);
    competencyTracker.award(session.game.competencies, 8 + this.run.difficulty * 2 + Math.min(12, Math.floor(score.total / 32)));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    this.mathMinigameSession = undefined;
    const solvedNode = puzzleKindFromId(session.puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    feedbackSystem.publish(
      `Sprint matematico registrato: ${session.correct} corrette, ${session.wrong} errori, serie ${session.bestStreak}. +${score.total} punti. ${remaining.length > 0 ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.` : "La porta finale è pronta."}`,
      "success",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Console matematica stabilizzata: il sistema completo è certificabile.");
      return;
    }
    if (this.isProgressiveMode()) {
      this.scheduleNextProgressivePuzzle(850);
      return;
    }
    this.runWhenActive(640, () => this.scene.restart());
  }

  private finalizeMathMinigameScore(session: MathMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
    const completedAt = new Date().toISOString();
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.mathMinigameElapsedMs(session)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    const basePoints = session.correct * (10 + run.difficulty);
    const difficultyBonus = session.correct * run.difficulty * 2;
    const speedBonus = Math.min(110, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 36));
    const focusBonus = run.focus.includes("matematica") || run.focus.some((item) => item.startsWith("matematica."))
      ? 20 + run.difficulty * 3
      : 0;
    const hintsUsed = existing?.hintsUsed ?? 0;
    const supportPenalty = Math.min(160, session.wrong * (10 + run.difficulty) + hintsUsed * 8);
    const total = Math.max(0, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);
    const score: ProceduralPuzzleScore = {
      puzzleId: session.puzzleId,
      domain: "matematica",
      startedAt,
      completedAt,
      elapsedMs,
      hintsUsed,
      attempts: session.wrong,
      basePoints,
      difficultyBonus,
      speedBonus,
      focusBonus,
      supportPenalty,
      total,
      feedback: this.mathMinigameFeedback(session),
    };
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [session.puzzleId]: score,
      },
      score: proceduralScoring.addToSummary(run.score, score),
    });
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
    return score;
  }

  private openEnglish(): void {
    const puzzle = this.currentEnglishPuzzle();
    if (puzzle.minigame) {
      this.openEnglishMinigame(puzzle);
      return;
    }
    const overlay = this.createOverlay(puzzle.title, 642, { x: 40, y: 48, width: 1200 });
    const instructionSize = puzzle.instruction.length > 122 ? 16 : puzzle.instruction.length > 96 ? 18 : puzzle.instruction.length > 72 ? 20 : 22;
    overlay.add(this.add.text(56, 78, (puzzle.difficultyLabel ?? "Livello 1 - comandi e divieti").toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(56, 104, `${this.englishChallengeLabel(puzzle.challengeType)}${puzzle.scenario ? ` | ${puzzle.scenario}` : ""}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 1030 },
    }));
    overlay.add(this.add.text(56, 136, puzzle.instruction, {
      fontFamily: "Inter, Arial",
      fontSize: `${instructionSize}px`,
      color: "#f5fbff",
      wordWrap: { width: 1040 },
      lineSpacing: 4,
    }));
    this.drawEnglishChallengePanel(overlay, puzzle);
    this.drawEnglishSupportPanel(overlay, puzzle);
    this.drawEnglishReasoningPanel(overlay, puzzle);

    if (!this.englishAnalyzed) {
      overlay.add(new Button(this, 866, 574, "Decodifica comando", () => {
        this.englishAnalyzed = true;
        audioManager.playOutcome("neutral");
        outcomeFeedback.play(this, "info", "Comando decodificato");
        feedbackSystem.publish(`Decodifica avviata: ${puzzle.method ?? "cerca verbo, oggetto, condizione e divieto."}`, "info");
        this.openEnglish();
      }, { width: 310, height: 52, fill: 0x173b36 }));
      return;
    }
    puzzle.choices.forEach((choice, index) => {
      overlay.add(new Button(this, 866, 402 + index * 50, choice.label, () => {
        if (choice.isCorrect) {
          this.solvePuzzle(this.currentPuzzleId("english"), puzzle.competencies);
          return;
        }
        this.handleIncorrectAnswer(choice.feedback);
      }, { width: 540, height: 42, fontSize: 13, fill: 0x263743 }));
    });
    this.addMethodStrip(overlay, 56, 596, 520, "Metodo", puzzle.methodSteps ?? [
      "verbo d'azione",
      "oggetto e quantità",
      "condizione, limite o divieto",
    ]);
    overlay.add(new Button(this, 866, 620, "Indizio mirato", () => {
      this.useHint(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)]));
      this.openEnglish();
    }, { width: 250, height: 40, fontSize: 13, fill: 0x263743 }));
  }

  private openEnglishMinigame(puzzle: GeneratedEnglishPuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("english");
    const session = this.ensureEnglishMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title);
    const prompt = this.currentEnglishMinigamePrompt(session);
    const remaining = this.englishMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 560, 432, "Ponte operativo");
    overlay.add(this.add.text(60, 154, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "25px",
      color: "#f7d37a",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    this.drawEnglishMinigameVisualizer(overlay, prompt, 60, 204, 500, 226);
    overlay.add(this.add.text(60, 456, `Concept: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 488 },
    }));
    overlay.add(this.add.text(60, 486, this.englishMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 492, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    this.addMathPanel(overlay, 616, 112, 636, 432, "Decisione rapida");
    overlay.add(this.add.text(648, 154, "60 secondi: non tradurre parola per parola. Trova prima verbo, oggetto e vincolo; poi scegli l'azione sicura.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 548 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(648, 214, prompt.instruction, {
      fontFamily: "Inter, Arial",
      fontSize: prompt.instruction.length > 92 ? "17px" : "20px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 548, useAdvancedWrap: true },
      lineSpacing: 5,
    }));
    overlay.add(this.add.text(648, 290, prompt.glossary.slice(0, 4).map((entry) => `${entry.term}: ${entry.meaning}`).join("   "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 548, useAdvancedWrap: true },
    }));

    const tileStartX = 788;
    const tileStartY = 356;
    prompt.tiles.forEach((tile, index) => {
      const selected = session.selectedIds.has(tile.id);
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(new Button(this, tileStartX + col * 252, tileStartY + row * 68, tile.label, () => this.toggleEnglishMinigameTile(tile.id), {
        width: 226,
        height: 52,
        fontSize: tile.label.length > 32 ? 10 : tile.label.length > 22 ? 12 : 15,
        wordWrapWidth: 202,
        fill: selected ? 0x174d42 : 0x263743,
        stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });

    this.addMathPanel(overlay, 28, 558, 1224, 130, "Ritmo, precisione, punteggio");
    this.englishMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(this.englishMinigameTimerText);
    overlay.add(this.add.text(260, 592, [
      `Corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie: ${session.streak}`,
      `Punti: ${session.netScore}`,
    ].join("   "), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 640 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(260, 636, session.feedback || puzzle.minigame.scoringRule, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: session.feedback ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 650, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 858, 640, "Pulisci scelta", () => this.clearEnglishMinigameSelection(), {
      width: 174,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1046, 640, "Conferma", () => this.confirmEnglishMinigamePrompt(), {
      width: 174,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 686, 640, "Indizio", () => this.useEnglishMinigameHint(), {
      width: 138,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.englishMinigameTimerEvent?.remove(false);
    this.englishMinigameTimerEvent = this.time.addEvent({
      delay: 250,
      loop: true,
      callback: () => this.refreshEnglishMinigameTimer(),
    });
    this.refreshEnglishMinigameTimer();
  }

  private ensureEnglishMinigameSession(
    puzzleId: string,
    puzzle: GeneratedEnglishPuzzle,
    game: GeneratedEnglishMinigame,
  ): EnglishMinigameSession {
    if (this.englishMinigameSession?.puzzleId === puzzleId && !this.englishMinigameSession.summaryOpen) {
      return this.englishMinigameSession;
    }
    this.englishMinigameSession = {
      puzzleId,
      puzzle,
      game,
      startedAt: Date.now(),
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      feedback: "Leggi il comando come una procedura: action word -> object -> limiter/time word.",
      locked: false,
      summaryOpen: false,
    };
    return this.englishMinigameSession;
  }

  private drawEnglishMinigameVisualizer(
    overlay: Phaser.GameObjects.Container,
    prompt: EnglishMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const g = this.add.graphics();
    g.fillStyle(0x07151d, 0.8);
    g.fillRoundedRect(x, y, width, height, 12);
    g.lineStyle(2, 0x6be7d6, 0.3);
    g.strokeRoundedRect(x, y, width, height, 12);
    overlay.add(g);

    const accent = prompt.type === "action-relay" ? 0x6be7d6 : prompt.type === "sequence-switchboard" ? 0xf6c85f : 0x9f8cff;
    overlay.add(this.add.rectangle(x + 24, y + 28, width - 48, 82, 0x102533, 0.84)
      .setOrigin(0)
      .setStrokeStyle(1, accent, 0.45));
    overlay.add(this.add.text(x + 42, y + 46, prompt.context, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      wordWrap: { width: width - 84, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    if (prompt.dataPoints && prompt.dataPoints.length > 0) {
      prompt.dataPoints.slice(0, 4).forEach((point, index) => {
        const rowY = y + 128 + index * 24;
        overlay.add(this.add.rectangle(x + 42, rowY - 3, width - 84, 20, 0x0c2531, 0.9).setOrigin(0)
          .setStrokeStyle(1, 0x6be7d6, 0.18));
        overlay.add(this.add.text(x + 54, rowY, `${point.label}: ${point.value}${point.note ? ` | ${point.note}` : ""}`, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#d9eaf1",
          wordWrap: { width: width - 110 },
        }));
      });
      return;
    }
    const visualLine = prompt.type === "action-relay"
      ? "VERB -> OBJECT -> NOT / ONLY"
      : "TIME WORD -> FIRST EVENT -> SAFE ACTION";
    overlay.add(this.add.text(x + 42, y + 138, visualLine, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: prompt.type === "action-relay" ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 84 },
    }));
    overlay.add(this.add.text(x + 42, y + 176, prompt.type === "action-relay"
      ? "Non scegliere l'azione che riconosci prima: controlla se not, only o un aggettivo cambia l'oggetto."
      : "Before, after, until e unless cambiano quando un comando è permesso.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: width - 84, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
  }

  private currentEnglishMinigamePrompt(session: EnglishMinigameSession): EnglishMinigamePrompt {
    return session.game.prompts[session.promptIndex % session.game.prompts.length];
  }

  private englishMinigameElapsedMs(session: EnglishMinigameSession): number {
    return Math.max(0, Date.now() - session.startedAt);
  }

  private englishMinigameRemainingMs(session: EnglishMinigameSession): number {
    return Math.max(0, session.durationMs - this.englishMinigameElapsedMs(session));
  }

  private refreshEnglishMinigameTimer(): void {
    const session = this.englishMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    const remaining = this.englishMinigameRemainingMs(session);
    this.englishMinigameTimerText?.setText(`Tempo: ${formatDuration(remaining)}`);
    this.englishMinigameTimerText?.setColor(remaining <= 10_000 ? "#ff8f8f" : "#f7d37a");
    if (remaining <= 0) {
      this.finishEnglishMinigame();
    }
  }

  private toggleEnglishMinigameTile(tileId: string): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.selectedIds.add(tileId);
    audioManager.play("click");
    this.openEnglishMinigame(session.puzzle);
  }

  private clearEnglishMinigameSelection(): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.feedback = "Selection cleared. Read verb, object and limiter before choosing.";
    this.openEnglishMinigame(session.puzzle);
  }

  private useEnglishMinigameHint(): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentEnglishMinigamePrompt(session);
    const hint = prompt.type === "action-relay"
      ? "Cerca il verbo operativo, poi verifica se not, only, neither o l'aggettivo cambiano l'oggetto."
      : prompt.type === "sequence-switchboard"
        ? "Prima traduci la parola-tempo: before = prima, after = dopo, until = aspetta fino a, unless = salvo se."
        : "Guarda la soglia: below è sotto, above è sopra, between è dentro l'intervallo.";
    session.feedback = hint;
    this.useHint(hint);
    this.openEnglishMinigame(session.puzzle);
  }

  private confirmEnglishMinigamePrompt(): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (this.englishMinigameRemainingMs(session) <= 0) {
      this.finishEnglishMinigame();
      return;
    }
    const prompt = this.currentEnglishMinigamePrompt(session);
    if (session.selectedIds.size === 0) {
      session.feedback = "Select one tile first. The timer keeps running.";
      audioManager.playOutcome("hint");
      this.openEnglishMinigame(session.puzzle);
      return;
    }
    const selectedId = [...session.selectedIds][0];
    const selected = prompt.tiles.find((tile) => tile.id === selectedId);
    if (!selected?.isCorrect) {
      const message = `${selected?.feedback ?? "Unsafe action."} Solution: ${prompt.solutionLabels.join(", ")}. ${prompt.explanation}`;
      if (this.isTimedMissionMode()) {
        this.englishMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (8 + this.run.difficulty));
      session.feedback = message;
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      outcomeFeedback.play(this, "warning", "Rileggi il comando");
      this.advanceEnglishMinigamePrompt(760);
      return;
    }

    session.answered += 1;
    session.correct += 1;
    session.streak += 1;
    session.bestStreak = Math.max(session.bestStreak, session.streak);
    const award = 10 + this.run.difficulty * 2 + Math.min(12, session.streak * 2);
    session.netScore += award;
    session.feedback = `Correct: ${prompt.explanation} +${award}`;
    session.locked = true;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceEnglishMinigamePrompt(420);
  }

  private advanceEnglishMinigamePrompt(delayMs: number): void {
    const session = this.englishMinigameSession;
    if (!session) {
      return;
    }
    this.runWhenActive(delayMs, () => {
      if (this.englishMinigameSession !== session || session.summaryOpen) {
        return;
      }
      if (this.englishMinigameRemainingMs(session) <= 0) {
        this.finishEnglishMinigame();
        return;
      }
      const previous = this.currentEnglishMinigamePrompt(session).signature;
      session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      if (this.currentEnglishMinigamePrompt(session).signature === previous) {
        session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      }
      session.selectedIds.clear();
      session.locked = false;
      this.openEnglishMinigame(session.puzzle);
    });
  }

  private finishEnglishMinigame(): void {
    const session = this.englishMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    session.locked = true;
    session.summaryOpen = true;
    this.englishMinigameTimerEvent?.remove(false);
    this.englishMinigameTimerEvent = undefined;
    audioManager.playOutcome("neutral");
    this.showEnglishMinigameSummary(session);
  }

  private englishMinigamePassed(session: EnglishMinigameSession): boolean {
    if (!this.isTimedMissionMode()) {
      return true;
    }
    const minCorrect = Math.max(5, Math.min(12, 4 + Math.ceil(this.run.difficulty * 0.75)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    return session.correct >= minCorrect && accuracy >= 0.62 && session.netScore > 0;
  }

  private englishMinigameFeedback(session: EnglishMinigameSession): string {
    if (session.answered === 0) {
      return "No answers: start from action words and limiters, then choose.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.9 && session.bestStreak >= 8) {
      return "Ottimo inglese operativo: hai letto comandi, limiti e dati senza anticipare.";
    }
    if (accuracy >= 0.72) {
      return "Buona base: aumenta la velocità solo dopo aver riconosciuto la parola chiave.";
    }
    if (session.wrong >= session.correct) {
      return "Troppi tentativi: prima nomina il vincolo inglese, poi scegli l'azione.";
    }
    return "Allenamento utile: punta a serie pulite, non solo a risposte isolate.";
  }

  private showEnglishMinigameSummary(session: EnglishMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const passed = this.englishMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(this.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(this.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(this.add.text(230, 160, passed ? "Sprint inglese completato" : "Sprint inglese da consolidare", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: passed ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(230, 210, [
      `Risposte corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie migliore: ${session.bestStreak}`,
      `Punti sprint: ${session.netScore}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      lineSpacing: 7,
    }));
    modal.add(this.add.rectangle(548, 212, 408, 128, 0x102533, 0.78).setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(this.add.text(572, 234, this.englishMinigameFeedback(session), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 354 },
      lineSpacing: 5,
    }));
    modal.add(this.add.rectangle(230, 378, 740, 74, 0x0b1e2a, 0.82).setOrigin(0)
      .setStrokeStyle(1, 0xf7d37a, 0.36));
    modal.add(this.add.text(254, 394, (mode === "mission" || mode === "progressive")
      ? passed
        ? "La console inglese accetta il protocollo: azioni, condizioni e dati sono stati interpretati."
        : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
      : "Allenamento registrabile: il voto pesa rapidità, precisione, serie positiva e uso degli aiuti.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    modal.add(new Button(this, 612, 506, (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua", () => {
      modal.destroy(true);
      if (!passed && (mode === "mission" || mode === "progressive")) {
        this.loseMissionLife("sprint inglese sotto soglia: servono più comandi corretti con meno tentativi.");
        return;
      }
      this.completeEnglishMinigame(session);
    }, {
      width: 270,
      height: 54,
      fill: passed ? 0x173b36 : 0x263743,
      stroke: passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private completeEnglishMinigame(session: EnglishMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeEnglishMinigameScore(session);
    saveSystem.markProceduralPuzzleSolved(session.puzzleId);
    competencyTracker.award(session.game.competencies, 8 + this.run.difficulty * 2 + Math.min(12, Math.floor(score.total / 32)));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    this.englishMinigameSession = undefined;
    const solvedNode = puzzleKindFromId(session.puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    feedbackSystem.publish(
      `Sprint inglese registrato: ${session.correct} corrette, ${session.wrong} errori, serie ${session.bestStreak}. +${score.total} punti. ${remaining.length > 0 ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.` : "La porta finale è pronta."}`,
      "success",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Console inglese stabilizzata: il sistema completo è certificabile.");
      return;
    }
    if (this.isProgressiveMode()) {
      this.scheduleNextProgressivePuzzle(850);
      return;
    }
    this.runWhenActive(640, () => this.scene.restart());
  }

  private finalizeEnglishMinigameScore(session: EnglishMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
    const completedAt = new Date().toISOString();
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.englishMinigameElapsedMs(session)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    const basePoints = session.correct * (9 + run.difficulty);
    const difficultyBonus = session.correct * run.difficulty * 2;
    const speedBonus = Math.min(92, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 34));
    const focusBonus = run.focus.includes("inglese") || run.focus.some((item) => item.startsWith("inglese."))
      ? 20 + run.difficulty * 3
      : 0;
    const supportPenalty = (existing?.hintsUsed ?? 0) * 5 + session.wrong * (6 + run.difficulty);
    const total = Math.max(0, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);
    const score: ProceduralPuzzleScore = {
      puzzleId: session.puzzleId,
      domain: proceduralScoring.puzzleDomain(session.puzzleId),
      startedAt,
      completedAt,
      elapsedMs,
      hintsUsed: existing?.hintsUsed ?? 0,
      attempts: Math.max(1, existing?.attempts ?? 1),
      basePoints,
      difficultyBonus,
      speedBonus,
      focusBonus,
      supportPenalty,
      total,
      feedback: this.englishMinigameFeedback(session),
    };
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [session.puzzleId]: score,
      },
      score: proceduralScoring.addToSummary(run.score, score),
    });
    return score;
  }

  private englishMinigameMethodText(prompt: EnglishMinigamePrompt): string {
    if (prompt.type === "action-relay") {
      return "Method: find the action verb, then object, then not/only/neither. One small word can reverse the command.";
    }
    if (prompt.type === "sequence-switchboard") {
      return "Method: translate the time word first, then decide which event must happen before the safe action.";
    }
    return "Method: compare data with the threshold. Choose the action only after checking below, above, between or comparative.";
  }

  private openCoding(): void {
    const puzzle = this.currentCodingPuzzle();
    const overlay = this.createOverlay(puzzle.title, 660, { x: 40, y: 30, width: 1200 });

    const codePanel = { x: 56, y: 104, w: 500, h: 356 };
    const taskPanel = { x: 584, y: 104, w: 560, h: 356 };
    const footerPanel = { x: 56, y: 486, w: 1088, h: 116 };

    overlay.add(this.add.text(56, 72, puzzle.difficultyLabel.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(336, 72, `Tipo: ${this.codingChallengeLabel(puzzle.challengeType)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));

    overlay.add(this.add.rectangle(codePanel.x, codePanel.y, codePanel.w, codePanel.h, 0x07151d, 0.88).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.rectangle(taskPanel.x, taskPanel.y, taskPanel.w, taskPanel.h, 0x07151d, 0.88).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.rectangle(footerPanel.x, footerPanel.y, footerPanel.w, footerPanel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.28));

    overlay.add(this.add.text(codePanel.x + 20, codePanel.y + 18, "Programma da leggere", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(codePanel.x + 20, codePanel.y + 44, puzzle.scenario, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: codePanel.w - 40, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    const codeBoxY = codePanel.y + 104;
    overlay.add(this.add.rectangle(codePanel.x + 20, codeBoxY, codePanel.w - 40, 178, 0x0b1f2b, 0.94).setOrigin(0).setStrokeStyle(1, 0x315766, 0.58));
    puzzle.codeLines.forEach((line, index) => {
      const y = codeBoxY + 14 + index * 26;
      overlay.add(this.add.text(codePanel.x + 36, y, String(index + 1).padStart(2, "0"), {
        fontFamily: "Consolas, 'Courier New', monospace",
        fontSize: "12px",
        color: "#6f8793",
      }));
      overlay.add(this.add.text(codePanel.x + 78, y, line, {
        fontFamily: "Consolas, 'Courier New', monospace",
        fontSize: "14px",
        color: "#f5fbff",
        wordWrap: { width: codePanel.w - 118 },
      }));
    });

    overlay.add(this.add.text(codePanel.x + 20, codePanel.y + codePanel.h - 52, `Scopo: ${puzzle.learningPurpose}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: codePanel.w - 40, useAdvancedWrap: true },
      lineSpacing: 2,
    }));

    overlay.add(this.add.text(taskPanel.x + 20, taskPanel.y + 18, "Domanda operativa", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(taskPanel.x + 20, taskPanel.y + 48, puzzle.question, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f7d37a",
      wordWrap: { width: taskPanel.w - 40, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(taskPanel.x + 20, taskPanel.y + 106, puzzle.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      wordWrap: { width: taskPanel.w - 40 },
    }));

    puzzle.options.forEach((option, index) => {
      const optionY = taskPanel.y + 164 + index * 46;
      overlay.add(new Button(this, taskPanel.x + taskPanel.w / 2, optionY, option, () => {
        if (option === puzzle.correctOption) {
          this.solvePuzzle(this.currentPuzzleId("coding"), puzzle.competencies);
          return;
        }
        this.handleIncorrectAnswer(`${puzzle.explanation} La scelta "${option}" non rispetta il metodo: ${puzzle.methodSteps.join(" -> ")}.`);
      }, {
        width: taskPanel.w - 70,
        height: 38,
        fontSize: 11,
        wordWrapWidth: taskPanel.w - 108,
      }));
    });

    overlay.add(this.add.text(footerPanel.x + 22, footerPanel.y + 18, "Metodo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(footerPanel.x + 22, footerPanel.y + 42, puzzle.methodSteps.join("  ->  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 620, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(footerPanel.x + 700, footerPanel.y + 18, "Cosa osservare", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(footerPanel.x + 700, footerPanel.y + 42, puzzle.hints[0] ?? puzzle.learningPurpose, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 238, useAdvancedWrap: true },
      lineSpacing: 2,
    }));
    overlay.add(new Button(this, footerPanel.x + footerPanel.w - 110, footerPanel.y + 62, "Indizio", () => {
      this.useHint(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)]));
      this.openCoding();
    }, {
      width: 190,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  private drawEnglishChallengePanel(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(316, 288, 520, 170, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(76, 218, "Sfida", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 242, puzzle.taskPrompt ?? puzzle.commandGoal ?? "Trasforma l'istruzione inglese in una procedura sicura.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 462 },
      lineSpacing: 3,
    }));
    const source = puzzle.sourceText ? (puzzle.sourceText.length > 124 ? `${puzzle.sourceText.slice(0, 121)}...` : puzzle.sourceText) : undefined;
    if (source) {
      overlay.add(this.add.text(76, 296, source, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        wordWrap: { width: 462 },
        lineSpacing: 3,
      }));
    }
    overlay.add(this.add.text(76, source ? 348 : 328, `Scopo: ${puzzle.learningPurpose ?? "Allena inglese operativo dentro una decisione tecnica."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 462 },
      lineSpacing: 2,
    }));
  }

  private drawEnglishSupportPanel(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(866, 288, 540, 170, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(614, 218, "Parole chiave e dati", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(614, 242, (puzzle.conceptTags ?? []).slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 500 },
      lineSpacing: 3,
    }));

    const dataPoints = (puzzle.dataPoints ?? []).slice(0, 3);
    if (dataPoints.length > 0) {
      dataPoints.forEach((point, index) => {
        const y = 284 + index * 28;
        overlay.add(this.add.rectangle(618, y - 4, 494, 24, 0x132835, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
        overlay.add(this.add.text(630, y, `${point.label}: ${point.value}${point.note ? ` | ${point.note}` : ""}`, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#d9eaf1",
          wordWrap: { width: 470 },
        }));
      });
      return;
    }

    const glossary = (puzzle.glossary ?? []).slice(0, 5);
    glossary.forEach((item, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(this.add.text(626 + col * 236, 288 + row * 34, `${item.term}: ${item.meaning}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        wordWrap: { width: 216 },
        lineSpacing: 2,
      }));
    });
  }

  private drawEnglishReasoningPanel(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(316, 478, 520, 150, 0x07151d, 0.82).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.text(76, 414, this.englishAnalyzed ? "Ragionamento" : "Prima della risposta", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const text = this.englishAnalyzed
      ? puzzle.diagnosticSteps.slice(0, 4).map((step, index) => `${index + 1}. ${step}`).join("\n")
      : `Decodifica il comando: cerca verbo, oggetto, condizione e parole che limitano l'azione.\nMetodo: ${puzzle.method ?? "leggi prima l'azione, poi divieti e condizioni."}`;
    overlay.add(this.add.text(76, 440, text, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.englishAnalyzed ? "#9ff5e9" : "#d9eaf1",
      wordWrap: { width: 470 },
      lineSpacing: 5,
    }));
  }

  private openMusic(): void {
    const puzzleId = this.currentPuzzleId("music");
    const session = this.ensureMusicSession(puzzleId);
    const puzzle = session.current;
    const overlay = this.createOverlay("Osservatorio del Pentagramma", 660, { x: 32, y: 28, width: 1216 });
    this.drawMusicSessionHeader(overlay, puzzle, session);
    this.drawMusicStaff(overlay, puzzle, 350, 328);
    this.drawMusicSupport(overlay, puzzle, session);
    const timerText = this.add.text(922, 152, "", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5);
    overlay.add(timerText);
    this.startMusicSprintCountdown(puzzleId, timerText);

    puzzle.choices.forEach((choice, index) => {
      const x = 794 + (index % 2) * 244;
      const y = 418 + Math.floor(index / 2) * 72;
      overlay.add(new Button(this, x, y, choice.label, () => {
        if (session.locked || session.summaryOpen) {
          return;
        }
        if (this.musicSprintExpired(session)) {
          this.finishMusicSprint();
          return;
        }
        this.answerMusicSprint(choice.isCorrect, choice.feedback);
      }, {
        width: 218,
        height: 60,
        fontSize: puzzle.answerMode === "note-name" ? 22 : 15,
        fill: 0x263743,
        hoverFill: 0x23556a,
      }));
    });

    this.addMethodStrip(overlay, 56, 586, 550, "Metodo", puzzle.methodSteps);
    overlay.add(new Button(this, 918, 598, "Indizio di lettura", () => {
      this.useHint(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)]));
      this.openMusic();
    }, { width: 300, height: 46, fontSize: 14, fill: 0x263743 }));
  }

  private drawMusicSessionHeader(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMusicPuzzle,
    session: MusicTrainingSession,
  ): void {
    overlay.add(this.add.rectangle(608, 92, 1128, 84, 0x06131c, 0.64).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.text(56, 66, `${puzzle.difficultyLabel.toUpperCase()} | Sprint a tempo fisso: ${formatDuration(session.durationMs)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(56, 96, this.musicPromptText(puzzle), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 850 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(970, 70, `Corrette ${session.correct}  |  Errori ${session.wrong}  |  Serie ${session.streak}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
    const remainingRatio = Phaser.Math.Clamp(1 - this.musicSprintElapsedMs(session) / session.durationMs, 0, 1);
    overlay.add(this.add.rectangle(906, 112, 284, 10, 0x1b3140, 0.82).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.rectangle(906 - 142 + 142 * remainingRatio, 112, 284 * remainingRatio, 10, remainingRatio < 0.2 ? 0xff8a8a : 0x6be7d6, 0.88));
    overlay.add(this.add.text(970, 126, `Punti sprint: ${session.netScore}  |  Risposte: ${session.answered}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c7dce7",
    }).setOrigin(0.5));
  }

  private drawMusicStaff(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number): void {
    overlay.add(this.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
    overlay.add(this.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
    overlay.add(this.add.image(centerX, centerY, "soft-glow").setTint(0x6be7d6).setAlpha(0.08).setScale(4.2, 2.2));
    overlay.add(this.add.rectangle(centerX, centerY - 2, 536, 190, 0x02070b, 0.28).setStrokeStyle(1, 0xf7d37a, 0.12));
    overlay.add(this.add.text(centerX - 260, centerY - 142, puzzle.clef === "treble" ? "Chiave di violino" : "Chiave di basso", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const lineSpacing = 28;
    const staffLeft = centerX - 220;
    const staffRight = centerX + 232;
    const topY = centerY - 58;
    for (let index = 0; index < 5; index += 1) {
      const y = topY + index * lineSpacing;
      overlay.add(this.add.rectangle((staffLeft + staffRight) / 2, y, staffRight - staffLeft, 2, 0x9ff5e9, 0.86));
    }
    const guideY = puzzle.clef === "bass" ? topY + lineSpacing : topY + lineSpacing * 3;
    overlay.add(this.add.rectangle((staffLeft + staffRight) / 2, guideY, staffRight - staffLeft, 4, 0xf7d37a, 0.16));
    const clefAnchorY = puzzle.clef === "bass" ? topY + lineSpacing : topY + lineSpacing * 3;
    this.drawMusicClef(overlay, puzzle.clef, staffLeft + 46, clefAnchorY);
    const noteX = centerX + 96;
    const noteY = topY + puzzle.staffPosition * (lineSpacing / 2);
    puzzle.ledgerLines.forEach((position) => {
      const y = topY + position * (lineSpacing / 2);
      overlay.add(this.add.rectangle(noteX, y, 72, 2, 0xf7d37a, 0.88));
    });
    const note = this.add.ellipse(noteX, noteY, 34, 24, 0xf5fbff, 1).setRotation(-0.42).setStrokeStyle(2, 0xf7d37a, 0.9);
    overlay.add(note);
    overlay.add(this.add.rectangle(noteX + 18, noteY - 42, 3, 86, 0xf5fbff, 0.94));
    overlay.add(this.add.text(centerX - 260, centerY + 108, [
      `Posizione: ${puzzle.staffPosition % 2 === 0 ? "linea" : "spazio"}`,
      puzzle.ledgerLines.length > 0 ? `Linee addizionali: ${puzzle.ledgerLines.length}` : "Nessuna linea addizionale",
      puzzle.answerMode === "note-name" ? "Risposta: nome della nota" : "Risposta: nome nota + ottava",
    ].join("  |  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 520 },
    }));
    overlay.add(this.add.text(centerX - 260, centerY + 132, this.musicModeExplanation(puzzle), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 520 },
      lineSpacing: 2,
    }));
  }

  private drawMusicSupport(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, session: MusicTrainingSession): void {
    overlay.add(this.add.rectangle(916, 282, 508, 206, 0x07151d, 0.88).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(682, 196, "Come ragionare durante lo sprint", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(682, 224, `${puzzle.method}\n\n${session.feedback || "Non serve correre a caso: rispondi solo quando hai agganciato la chiave e contato linee/spazi."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 456 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(682, 310, `Scopo: ${puzzle.learningPurpose}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 456 },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(682, 366, puzzle.conceptTags.map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 456 },
    }));
  }

  private ensureMusicSession(puzzleId: string): MusicTrainingSession {
    if (this.musicSession?.puzzleId === puzzleId) {
      return this.musicSession;
    }
    const basePuzzle = this.currentMusicPuzzle();
    const random = new Random(`${this.run.seed}:${puzzleId}:music-drill`);
    const durationMs = this.musicSprintDurationMs(this.run.difficulty);
    this.musicSession = {
      puzzleId,
      random,
      current: basePuzzle,
      startedAt: Date.now(),
      durationMs,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      recentSignatures: [this.musicPuzzleSignature(basePuzzle)],
      feedback: "Obiettivo: più note corrette possibili nel tempo. Le risposte errate tolgono punti e interrompono la serie.",
      locked: false,
      summaryOpen: false,
      questionStartedAt: Date.now(),
    };
    return this.musicSession;
  }

  private answerMusicSprint(correct: boolean, feedback: string): void {
    const session = this.musicSession;
    const puzzleId = this.currentPuzzleId("music");
    if (!session || session.puzzleId !== puzzleId || session.locked || session.summaryOpen) {
      return;
    }
    session.locked = true;
    const points = this.musicAnswerPoints(session, correct);
    session.answered += 1;
    if (correct) {
      session.correct += 1;
      session.streak += 1;
      session.bestStreak = Math.max(session.bestStreak, session.streak);
      session.netScore += points;
      session.feedback = `+${points} punti. Serie attiva: ${session.streak}.`;
      audioManager.playOutcome("correct");
      outcomeFeedback.play(this, "success", `+${points}`);
    } else {
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore + points);
      session.feedback = `${feedback} ${points} punti: l'errore interrompe la serie, ma lo sprint continua.`;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      outcomeFeedback.play(this, "warning", `${points}`);
      if (this.isTimedMissionMode()) {
        this.loseMissionLife(`Sprint musicale: ${feedback}`);
        return;
      }
    }
    if (this.musicSprintExpired(session)) {
      this.finishMusicSprint();
      return;
    }
    this.runWhenActive(correct ? 95 : 240, () => this.advanceMusicSprintQuestion(session));
  }

  private advanceMusicSprintQuestion(session: MusicTrainingSession): void {
    if (this.musicSession !== session || session.summaryOpen || session.puzzleId !== this.currentPuzzleId("music")) {
      return;
    }
    session.current = this.nextMusicSprintPuzzle(session);
    session.questionStartedAt = Date.now();
    session.locked = false;
    this.openMusic();
  }

  private nextMusicSprintPuzzle(session: MusicTrainingSession): GeneratedMusicPuzzle {
    const level = Math.min(8, Math.max(1, this.run.difficulty + Math.floor(session.correct / 7))) as DifficultyLevel;
    const previous = this.musicPuzzleSignature(session.current);
    for (let attempt = 0; attempt < 14; attempt += 1) {
      const salt = session.random.integer(0, 999_999);
      const candidate = this.musicGenerator.generate(session.random.fork(`sprint-${session.answered}-${attempt}-${salt}`), level);
      const signature = this.musicPuzzleSignature(candidate);
      if (signature !== previous && !session.recentSignatures.slice(-2).includes(signature)) {
        session.recentSignatures.push(signature);
        session.recentSignatures = session.recentSignatures.slice(-4);
        return candidate;
      }
    }
    const fallback = this.musicGenerator.generate(session.random.fork(`fallback-${session.answered}`), level);
    session.recentSignatures.push(this.musicPuzzleSignature(fallback));
    session.recentSignatures = session.recentSignatures.slice(-4);
    return fallback;
  }

  private musicSprintDurationMs(level: DifficultyLevel): number {
    return 45_000 + Math.min(18_000, (level - 1) * 2_500);
  }

  private musicSprintElapsedMs(session: MusicTrainingSession): number {
    return Math.max(0, Date.now() - session.startedAt);
  }

  private musicSprintRemainingMs(session: MusicTrainingSession): number {
    return Math.max(0, session.durationMs - this.musicSprintElapsedMs(session));
  }

  private musicSprintExpired(session: MusicTrainingSession): boolean {
    return this.musicSprintRemainingMs(session) <= 0;
  }

  private musicPuzzleSignature(puzzle: GeneratedMusicPuzzle): string {
    return [
      puzzle.clef,
      puzzle.answerMode,
      puzzle.noteName,
      puzzle.octave,
      puzzle.staffPosition,
      puzzle.ledgerLines.join("."),
    ].join(":");
  }

  private musicAnswerPoints(session: MusicTrainingSession, correct: boolean): number {
    const level = this.run.difficulty;
    if (correct) {
      const nextStreak = session.streak + 1;
      const streakBonus = Math.min(12, Math.floor(nextStreak / 3) * 3);
      return 10 + level * 2 + streakBonus;
    }
    const randomClickPenalty = Math.min(8, Math.floor(session.streak / 2) * 2);
    return -(8 + level + randomClickPenalty);
  }

  private startMusicSprintCountdown(puzzleId: string, text: Phaser.GameObjects.Text): void {
    this.musicTimerEvent?.remove(false);
    const update = (): void => {
      const session = this.musicSession;
      if (!text.active || !session || session.puzzleId !== puzzleId || session.summaryOpen) {
        return;
      }
      const remaining = this.musicSprintRemainingMs(session);
      text.setText(`Tempo sprint: ${formatDuration(remaining)}`);
      text.setColor(remaining < 8_000 ? "#ff8a8a" : "#f7d37a");
      if (remaining <= 0) {
        this.musicTimerEvent?.remove(false);
        this.musicTimerEvent = undefined;
        this.finishMusicSprint();
      }
    };
    update();
    this.musicTimerEvent = this.time.addEvent({ delay: 120, loop: true, callback: update });
  }

  private finishMusicSprint(): void {
    const session = this.musicSession;
    if (!session || session.summaryOpen || this.isRunInteractionLocked()) {
      return;
    }
    if (this.checkMissionTimeout()) {
      return;
    }
    session.locked = true;
    session.summaryOpen = true;
    this.musicTimerEvent?.remove(false);
    this.musicTimerEvent = undefined;
    audioManager.playOutcome("neutral");
    this.showMusicSprintSummary(session);
  }

  private musicSprintPassed(session: MusicTrainingSession): boolean {
    if (!this.isTimedMissionMode()) {
      return true;
    }
    const minCorrect = Math.max(4, Math.min(10, 3 + Math.ceil(this.run.difficulty * 0.8)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    return session.correct >= minCorrect && accuracy >= 0.45 && session.netScore > 0;
  }

  private musicSprintFeedback(session: MusicTrainingSession): string {
    if (session.answered === 0) {
      return "Nessuna risposta registrata: serve almeno iniziare il riconoscimento delle note.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.86 && session.bestStreak >= 7) {
      return "Lettura fluida: riconosci chiave, posizione e nome con buona continuità.";
    }
    if (accuracy >= 0.68) {
      return "Buona base: la velocità cresce, ma alcune risposte mostrano che devi ricontare prima del click.";
    }
    if (session.wrong > session.correct) {
      return "Troppe risposte a tentativo: rallenta un attimo, aggancia la nota guida e poi conta linee e spazi.";
    }
    return "Allenamento utile: hai letto diverse note, ora punta a serie più lunghe senza errori.";
  }

  private showMusicSprintSummary(session: MusicTrainingSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const passed = this.musicSprintPassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const title = passed ? "Sprint musicale completato" : "Sprint musicale da consolidare";
    const mode = proceduralRunRules.modeFor(this.run);
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(this.add.rectangle(600, 334, 760, 356, 0x000000, 0.32));
    modal.add(this.add.rectangle(600, 320, 760, 356, 0x07151d, 0.98)
      .setStrokeStyle(2, passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(this.add.text(250, 168, title, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: passed ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(250, 216, [
      `Risposte corrette: ${session.correct}`,
      `Errori: ${session.wrong}`,
      `Precisione: ${accuracy}%`,
      `Serie migliore: ${session.bestStreak}`,
      `Punti sprint: ${session.netScore}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      lineSpacing: 7,
    }));
    modal.add(this.add.rectangle(560, 218, 390, 120, 0x102533, 0.78).setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(this.add.text(584, 240, this.musicSprintFeedback(session), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 340 },
      lineSpacing: 5,
    }));
    modal.add(this.add.rectangle(250, 378, 700, 72, 0x0b1e2a, 0.82).setOrigin(0)
      .setStrokeStyle(1, 0xf7d37a, 0.36));
    modal.add(this.add.text(274, 394, (mode === "mission" || mode === "progressive")
      ? passed
        ? "La console musicale è stabile: il sistema accetta il riconoscimento rapido delle note."
        : "In missione la console richiede una soglia minima: perderai una vita, ma potrai riprovare."
      : "Allenamento registrabile: il punteggio premia correttezza e serie, e penalizza gli errori casuali.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 650 },
      lineSpacing: 4,
    }));
    modal.add(new Button(this, 608, 506, (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua", () => {
      modal.destroy(true);
      if (!passed && (mode === "mission" || mode === "progressive")) {
        this.loseMissionLife("sprint musicale sotto soglia: servono più riconoscimenti corretti nel tempo dato.");
        return;
      }
      this.completeMusicSprint(session);
    }, {
      width: 260,
      height: 54,
      fill: passed ? 0x173b36 : 0x263743,
      stroke: passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private completeMusicSprint(session: MusicTrainingSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const puzzleId = session.puzzleId;
    const score = this.finalizeMusicSprintScore(session);
    saveSystem.markProceduralPuzzleSolved(puzzleId);
    const competencies = Array.from(new Set([
      "musica.pentagramma",
      "musica.letturaNote",
      "musica.chiaveViolino",
      "musica.chiaveBasso",
      ...session.current.competencies,
    ]));
    competencyTracker.award(competencies, 8 + this.run.difficulty * 2 + Math.min(10, Math.floor(score.total / 35)));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    this.musicSession = undefined;
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id));
    feedbackSystem.publish(
      `Sprint musicale registrato: ${session.correct} corrette, ${session.wrong} errori, serie migliore ${session.bestStreak}. +${score.total} punti. ${remaining.length > 0 ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.` : "La porta finale è pronta."}`,
      "success",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Sprint finale completato: tutte le console richieste sono stabili.");
      return;
    }
    if (this.isProgressiveMode()) {
      this.scheduleNextProgressivePuzzle(850);
      return;
    }
    this.runWhenActive(640, () => this.scene.restart());
  }

  private finalizeMusicSprintScore(session: MusicTrainingSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
    const completedAt = new Date().toISOString();
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.musicSprintElapsedMs(session)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    const basePoints = session.correct * (10 + run.difficulty);
    const difficultyBonus = session.correct * run.difficulty * 2;
    const speedBonus = Math.min(90, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 32));
    const focusBonus = run.focus.includes("musica") || run.focus.some((item) => item.startsWith("musica."))
      ? 20 + run.difficulty * 3
      : 0;
    const hintsUsed = existing?.hintsUsed ?? 0;
    const supportPenalty = Math.min(140, session.wrong * (9 + run.difficulty) + hintsUsed * 6);
    const total = Math.max(0, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);
    const score: ProceduralPuzzleScore = {
      puzzleId: session.puzzleId,
      domain: "musica",
      startedAt,
      completedAt,
      elapsedMs,
      hintsUsed,
      attempts: session.wrong,
      basePoints,
      difficultyBonus,
      speedBonus,
      focusBonus,
      supportPenalty,
      total,
      feedback: this.musicSprintFeedback(session),
    };
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [session.puzzleId]: score,
      },
      score: proceduralScoring.addToSummary(run.score, score),
    });
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
    return score;
  }

  private musicPromptText(puzzle: GeneratedMusicPuzzle): string {
    if (puzzle.answerMode === "note-name") {
      return "Obiettivo: riconosci il nome della nota il più rapidamente possibile. Guarda la chiave, trova la nota guida e conta linee/spazi.";
    }
    return "Obiettivo: riconosci nome e ottava. Il numero indica il registro: Do4 è il Do centrale; La4 è il La sopra il Do centrale.";
  }

  private musicModeExplanation(puzzle: GeneratedMusicPuzzle): string {
    if (puzzle.answerMode === "note-name") {
      return "Modalità rapida: conta la posizione e scegli solo il nome della nota. L'ottava verrà allenata nei livelli avanzati.";
    }
    return "Modalità avanzata: stesso nome in registri diversi non basta; controlla anche le linee addizionali per scegliere l'ottava.";
  }

  private musicSolutionLines(puzzle: GeneratedMusicPuzzle): string[] {
    const correct = puzzle.choices.find((choice) => choice.isCorrect)?.label ?? puzzle.noteName;
    const anchor = puzzle.clef === "treble"
      ? "chiave di violino: parti dal Sol sulla seconda linea"
      : "chiave di basso: parti dal Fa sulla quarta linea, tra i due puntini";
    const position = puzzle.staffPosition % 2 === 0 ? "linea" : "spazio";
    const ledger = puzzle.ledgerLines.length > 0
      ? `usa anche ${puzzle.ledgerLines.length} linea/e addizionale/i`
      : "resta dentro il pentagramma";
    return [
      `Risposta corretta: ${correct}.`,
      `Metodo: ${anchor}.`,
      `La nota si trova su ${position}; ${ledger}.`,
      puzzle.answerMode === "note-name"
        ? "In questo livello conta solo il nome della nota, non l'ottava."
        : "In questo livello devi controllare anche l'ottava, quindi le linee addizionali diventano decisive.",
    ];
  }

  private showTimeoutSolution(message: string, solutionLines: string[], onTrainingContinue?: () => void): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const width = 700;
    const height = 292;
    const x = 250;
    const y = 190;
    const mode = proceduralRunRules.modeFor(this.run);
    const isTimeout = message.toLowerCase().includes("tempo scaduto");
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.62);
    modal.add(this.add.rectangle(x + width / 2 + 10, y + height / 2 + 12, width, height, 0x000000, 0.34));
    modal.add(this.add.rectangle(x + width / 2, y + height / 2, width, height, 0x07151d, 0.97)
      .setStrokeStyle(2, 0xf7d37a, 0.72));
    modal.add(this.add.text(x + 30, y + 24, isTimeout ? "Tempo scaduto: soluzione guidata" : "Risposta da rivedere: soluzione guidata", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(x + 30, y + 62, message, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: width - 60 },
      lineSpacing: 4,
    }));
    modal.add(this.add.rectangle(x + 30, y + 118, width - 60, 96, 0x102533, 0.82)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(this.add.text(x + 48, y + 132, solutionLines.map((line, index) => `${index + 1}. ${line}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
      wordWrap: { width: width - 96 },
      lineSpacing: 5,
    }));
    modal.add(this.add.text(x + 30, y + 232, (mode === "mission" || mode === "progressive")
      ? "Quando premi, l'errore verrà registrato e perderai una vita. I sistemi già completati restano validi."
      : onTrainingContinue
        ? "Quando premi, passi alla nota successiva della sequenza. La soluzione appena vista resta parte dell'allenamento."
        : "Quando premi, torni alla sala e puoi riprovare l'esercizio con un nuovo timer.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 410 },
      lineSpacing: 3,
    }));
    modal.add(new Button(this, x + width - 126, y + height - 42, "Ho capito", () => {
      modal.destroy(true);
      this.timeoutSolutionOpen = false;
      if (mode === "mission" || mode === "progressive") {
        this.loseMissionLife(message);
        return;
      }
      if (onTrainingContinue) {
        feedbackSystem.publish(isTimeout
          ? "Tempo scaduto: soluzione letta. Continua con la nota successiva."
          : "Risposta rivista: continua con la nota successiva.",
        "warning");
        onTrainingContinue();
        return;
      }
      this.finalizeTrainingPuzzleFailure(isTimeout
        ? `Tempo scaduto: ${message}`
        : `Soluzione letta: ${message}`);
      feedbackSystem.publish(isTimeout
        ? "Tempo scaduto: soluzione letta. La prova è registrata e il focus prosegue."
        : "Soluzione letta. La prova è registrata e il focus prosegue.",
      "warning");
    }, {
      width: 174,
      height: 46,
      fill: 0x173b36,
      stroke: 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private drawMusicClef(overlay: Phaser.GameObjects.Container, clef: GeneratedMusicPuzzle["clef"], x: number, y: number): void {
    if (clef === "treble") {
      const symbol = this.add.text(x, y, "𝄞", {
        fontFamily: "Georgia, 'Times New Roman', serif",
        fontSize: "96px",
        color: "#f7d37a",
      }).setOrigin(0.5, 0.55);
      symbol.setY(y - 2);
      overlay.add(symbol);
      overlay.add(this.add.circle(x + 1, y, 4, 0xf5fbff, 0.85));
      return;
    }
    const g = this.add.graphics();
    g.lineStyle(4, 0xf7d37a, 0.92);
    g.beginPath();
    g.arc(x - 12, y, 34, Phaser.Math.DegToRad(248), Phaser.Math.DegToRad(88), false);
    g.strokePath();
    g.fillStyle(0xf7d37a, 0.95);
    g.fillCircle(x - 28, y, 8);
    g.fillCircle(x + 30, y - 14, 4);
    g.fillCircle(x + 30, y + 14, 4);
    overlay.add(g);
    overlay.add(this.add.circle(x - 28, y, 3, 0xf5fbff, 0.72));
  }

  private openRobot(): void {
    const puzzle = this.currentRobotPuzzle();
    const model = RobotConsole.fromPuzzle(puzzle);
    const overlay = this.createOverlay(model.title, 660, { x: 40, y: 30, width: 1200 });
    this.robotExecuting = false;

    const commandLimit = puzzle.maxCommands ?? puzzle.solutionCommands.length + 4;
    const mapPanel = { x: 52, y: 94, w: 462, h: 358 };
    const programPanel = { x: 536, y: 94, w: 286, h: 358 };
    const objectivePanel = { x: 844, y: 94, w: 304, h: 358 };
    const commandPanel = { x: 52, y: 472, w: 1096, h: 150 };

    overlay.add(this.add.rectangle(mapPanel.x, mapPanel.y, mapPanel.w, mapPanel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.rectangle(programPanel.x, programPanel.y, programPanel.w, programPanel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.rectangle(objectivePanel.x, objectivePanel.y, objectivePanel.w, objectivePanel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.rectangle(commandPanel.x, commandPanel.y, commandPanel.w, commandPanel.h, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.28));

    overlay.add(this.add.text(mapPanel.x + 18, mapPanel.y + 14, "Mappa robot", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(mapPanel.x + 18, mapPanel.y + 38, `Focus: ${model.visualFocus ?? "sequenza"} | Griglia ${puzzle.cols}x${puzzle.rows}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
    }));

    this.robotCellSize = Math.min(
      42,
      Math.floor((mapPanel.w - 82) / puzzle.cols),
      Math.floor((mapPanel.h - 168) / puzzle.rows),
    );
    const gridW = this.robotCellSize * puzzle.cols;
    const gridH = this.robotCellSize * puzzle.rows;
    this.robotOrigin = {
      x: mapPanel.x + Math.floor((mapPanel.w - gridW) / 2) + this.robotCellSize / 2 + (model.coordinateLabels ? 10 : 0),
      y: mapPanel.y + 104 + this.robotCellSize / 2,
    };

    if (model.coordinateLabels) {
      for (let col = 0; col < puzzle.cols; col += 1) {
        overlay.add(this.add.text(this.robotCellX(col), this.robotOrigin.y - this.robotCellSize * 0.78, `${col}`, {
          fontFamily: "Inter, Arial",
          fontSize: "9px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5));
      }
      for (let row = 0; row < puzzle.rows; row += 1) {
        overlay.add(this.add.text(this.robotOrigin.x - this.robotCellSize * 0.78, this.robotCellY(row), `${row}`, {
          fontFamily: "Inter, Arial",
          fontSize: "9px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5));
      }
    }

    overlay.add(this.add.text(mapPanel.x + 18, mapPanel.y + mapPanel.h - 54, [
      `Robot: ${this.facingLabel(puzzle.start.facing)}`,
      "Stella = chiave | quadrato = uscita | rosso = ostacolo | viola = checkpoint",
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9aaab0",
      wordWrap: { width: mapPanel.w - 36 },
      lineSpacing: 2,
    }));

    for (let row = 0; row < puzzle.rows; row += 1) {
      for (let col = 0; col < puzzle.cols; col += 1) {
        const blocked = puzzle.obstacles.some((cell) => cell.col === col && cell.row === row);
        const cell = this.add.rectangle(
          this.robotCellX(col),
          this.robotCellY(row),
          this.robotCellSize - 4,
          this.robotCellSize - 4,
          blocked ? 0x4c2b38 : 0x132835,
          1,
        ).setStrokeStyle(1, blocked ? 0xc94b55 : 0x315766, 0.7);
        overlay.add(cell);
        if (!blocked && (col + row) % 2 === 0) {
          overlay.add(this.add.rectangle(this.robotCellX(col), this.robotCellY(row), this.robotCellSize - 14, 2, 0x6be7d6, 0.08));
        }
      }
    }
    [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order).forEach((checkpoint) => {
      overlay.add(this.add.circle(this.robotCellX(checkpoint.col), this.robotCellY(checkpoint.row), Math.max(9, this.robotCellSize * 0.28), 0x8a7cff, 0.72).setStrokeStyle(2, 0xf5fbff, 0.58));
      overlay.add(this.add.text(this.robotCellX(checkpoint.col), this.robotCellY(checkpoint.row), checkpoint.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
    });
    this.robotSprite = this.add.triangle(
      this.robotCellX(puzzle.start.col),
      this.robotCellY(puzzle.start.row),
      0,
      -16,
      14,
      14,
      -14,
      14,
      0x6be7d6,
      1,
    );
    this.robotSprite.setStrokeStyle(2, 0xf5fbff, 0.8).setRotation(this.robotRotationFor(puzzle.start.facing));
    this.robotKeyMarker = this.add.star(this.robotCellX(puzzle.key.col), this.robotCellY(puzzle.key.row), 5, 7, 16, 0xf6c85f, 1);
    const exitMarker = this.add.rectangle(this.robotCellX(puzzle.exit.col), this.robotCellY(puzzle.exit.row), 24, 24, 0x9ff5e9, 0.45);
    overlay.add(this.robotSprite);
    overlay.add(this.robotKeyMarker);
    overlay.add(exitMarker);

    overlay.add(this.add.text(programPanel.x + 18, programPanel.y + 14, "Programma", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(programPanel.x + 18, programPanel.y + 38, `${this.robotCommands.length}/${commandLimit} comandi`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: this.robotCommands.length > commandLimit ? "#ff8a8a" : "#f7d37a",
    }));
    const visibleCommands = this.robotCommands.length
      ? this.formatRobotCommands(this.robotCommands, 14)
      : "(buffer vuoto)\nAggiungi comandi dalla barra in basso.";
    overlay.add(this.add.rectangle(programPanel.x + 18, programPanel.y + 66, programPanel.w - 36, 176, 0x0b1f2b, 0.84).setOrigin(0).setStrokeStyle(1, 0x315766, 0.55));
    overlay.add(this.add.text(programPanel.x + 32, programPanel.y + 80, visibleCommands, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#d9eaf1",
      wordWrap: { width: programPanel.w - 64 },
      lineSpacing: 2,
    }));
    const debugLine = model.buggedCommands
      ? `Log guasto:\n${this.formatRobotCommands(model.buggedCommands, 7)}`
      : "";
    this.robotStatusText = this.add.text(programPanel.x + 18, programPanel.y + 258, debugLine || "Stato: pronto. Esegui solo quando il piano e completo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: debugLine ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: programPanel.w - 36 },
      lineSpacing: 3,
    });
    overlay.add(this.robotStatusText);

    overlay.add(this.add.text(objectivePanel.x + 18, objectivePanel.y + 14, "Obiettivo", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(objectivePanel.x + 18, objectivePanel.y + 40, model.routeBrief ?? model.instructions[0] ?? "Costruisci una sequenza valida per chiave e uscita.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: objectivePanel.w - 36 },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(objectivePanel.x + 18, objectivePanel.y + 132, `Metodo: ${model.planningPrompt ?? "Simula mentalmente prima di eseguire."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: objectivePanel.w - 36 },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(objectivePanel.x + 18, objectivePanel.y + 214, `Condizioni:\n${model.successConditions.slice(0, 4).map((condition) => `- ${condition}`).join("\n")}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c9dce6",
      wordWrap: { width: objectivePanel.w - 36 },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(objectivePanel.x + 18, objectivePanel.y + objectivePanel.h - 40, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9ff5e9",
      wordWrap: { width: objectivePanel.w - 36 },
    }));

    overlay.add(this.add.text(commandPanel.x + 18, commandPanel.y + 14, "Comandi", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(commandPanel.x + 112, commandPanel.y + 16, "Avanza muove nella direzione della punta. Gira cambia solo direzione. Raccogli ed Esci funzionano solo sulla casella corretta.", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9aaab0",
      wordWrap: { width: 680 },
    }));
    (["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "PICK_UP", "EXIT"] satisfies GridCommand[]).forEach((command, index) => {
      overlay.add(new Button(this, commandPanel.x + 132 + index * 158, commandPanel.y + 76, commandLabels[command], () => {
        if (!this.robotExecuting && this.robotCommands.length < commandLimit) {
          this.robotCommands.push(command);
          this.openRobot();
        } else if (!this.robotExecuting) {
          this.useHint("Il buffer e pieno: non aggiungere tentativi. Simula il percorso e togli i comandi che non cambiano obiettivo.");
        }
      }, { width: 136, height: 38, fontSize: 12 }));
    });
    overlay.add(new Button(this, commandPanel.x + commandPanel.w - 116, commandPanel.y + 50, "Esegui", () => this.executeRobot(), { width: 172, height: 38, fill: 0x173b36, fontSize: 12 }));
    overlay.add(new Button(this, commandPanel.x + commandPanel.w - 116, commandPanel.y + 102, "Pulisci", () => {
      if (this.robotExecuting) {
        return;
      }
      this.robotCommands = [];
      this.openRobot();
    }, { width: 172, height: 38, fill: 0x263743, fontSize: 12 }));
  }

  private executeRobot(): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout() || this.robotExecuting || this.robotCommands.length === 0) {
      return;
    }
    const puzzle = this.currentRobotPuzzle();
    this.robotExecuting = true;
    let state = { ...puzzle.start };
    let hasKey = false;
    const checkpoints = [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order);
    let checkpointIndex = 0;
    const turn = (facing: GridFacing, direction: "L" | "R"): GridFacing => {
      const order: GridFacing[] = ["N", "E", "S", "W"];
      const offset = direction === "R" ? 1 : -1;
      return order[(order.indexOf(facing) + offset + order.length) % order.length];
    };

    const fail = (message: string, col = state.col, row = state.row): void => {
      this.robotExecuting = false;
      this.robotStatusText?.setColor("#f7d37a").setText(message);
      this.flashRobotCell(col, row, 0xc94b55);
      this.shakeRobot();
      this.handleIncorrectAnswer(message);
    };

    const runAt = (index: number): void => {
      if (!this.robotExecuting || !this.overlay || !this.robotSprite?.active) {
        return;
      }
      if (index >= this.robotCommands.length) {
        if (checkpointIndex < checkpoints.length) {
          fail(`Il programma si ferma prima del checkpoint ${checkpoints[checkpointIndex].label}: dividi la rotta in tappe e completa la prossima tappa.`);
          return;
        }
        fail(hasKey ? mistakeAnalyzer.robotFailureMessage({ kind: "not-exited" }, this.robotCommands) : mistakeAnalyzer.robotFailureMessage({ kind: "missing-key" }, this.robotCommands));
        return;
      }
      const command = this.robotCommands[index];
      this.robotStatusText?.setColor("#d9eaf1").setText(`Passo ${index + 1}: ${commandLabels[command]}`);
      if (command === "TURN_LEFT") {
        state.facing = turn(state.facing, "L");
        this.tweens.add({
          targets: this.robotSprite,
          rotation: this.robotRotationFor(state.facing),
          duration: 180,
          onComplete: () => this.runWhenActive(90, () => runAt(index + 1)),
        });
        return;
      } else if (command === "TURN_RIGHT") {
        state.facing = turn(state.facing, "R");
        this.tweens.add({
          targets: this.robotSprite,
          rotation: this.robotRotationFor(state.facing),
          duration: 180,
          onComplete: () => this.runWhenActive(90, () => runAt(index + 1)),
        });
        return;
      } else if (command === "MOVE_FORWARD") {
        const delta = { N: [0, -1], E: [1, 0], S: [0, 1], W: [-1, 0] }[state.facing];
        const next = { col: state.col + delta[0], row: state.row + delta[1], facing: state.facing };
        const blocked = next.col < 0 || next.row < 0 || next.col >= puzzle.cols || next.row >= puzzle.rows || puzzle.obstacles.some((cell) => cell.col === next.col && cell.row === next.row);
        if (blocked) {
          fail(mistakeAnalyzer.robotFailureMessage({ kind: "wall", commandIndex: index }, this.robotCommands), next.col, next.row);
          return;
        }
        state = next;
        const checkpoint = checkpoints[checkpointIndex];
        if (checkpoint && state.col === checkpoint.col && state.row === checkpoint.row) {
          checkpointIndex += 1;
          this.flashRobotCell(state.col, state.row, 0x8a7cff);
          this.robotStatusText?.setColor("#9ff5e9").setText(`Checkpoint ${checkpoint.label} validato. Prossimo sotto-obiettivo: ${checkpointIndex < checkpoints.length ? `checkpoint ${checkpoints[checkpointIndex].label}` : "chiave"}.`);
        }
        audioManager.play("footstep");
        this.tweens.add({
          targets: this.robotSprite,
          x: this.robotCellX(state.col),
          y: this.robotCellY(state.row),
          duration: 260,
          ease: "Sine.easeInOut",
          onComplete: () => this.runWhenActive(80, () => runAt(index + 1)),
        });
        return;
      } else if (command === "PICK_UP") {
        if (checkpointIndex < checkpoints.length) {
          fail(`Hai provato a raccogliere prima di validare il checkpoint ${checkpoints[checkpointIndex].label}. Il programma deve rispettare l'ordine dei sotto-obiettivi.`, state.col, state.row);
          return;
        }
        hasKey = state.col === puzzle.key.col && state.row === puzzle.key.row;
        if (!hasKey) {
          fail(mistakeAnalyzer.robotFailureMessage({ kind: "premature-pickup", commandIndex: index }, this.robotCommands));
          return;
        }
        audioManager.play("success");
        this.robotKeyMarker?.setAlpha(0.2).setScale(0.7);
        this.tweens.add({
          targets: this.robotSprite,
          scale: 1.24,
          duration: 130,
          yoyo: true,
          onComplete: () => this.runWhenActive(100, () => runAt(index + 1)),
        });
        return;
      } else if (command === "EXIT") {
        if (hasKey && checkpointIndex === checkpoints.length && state.col === puzzle.exit.col && state.row === puzzle.exit.row) {
          this.robotStatusText?.setColor("#9ff5e9").setText("Percorso confermato: chiave recuperata e uscita raggiunta.");
          this.flashRobotCell(state.col, state.row, 0x9ff5e9);
          audioManager.play("success");
          this.tweens.add({
            targets: this.robotSprite,
            scale: 1.35,
            alpha: 0.25,
            duration: 420,
            yoyo: true,
            onComplete: () => {
              if (this.robotExecuting && this.overlay && this.robotSprite?.active) {
                this.solvePuzzle(this.currentPuzzleId("robot"), puzzle.competencies);
              }
            },
          });
          return;
        }
        if (checkpointIndex < checkpoints.length) {
          fail(`La porta robot rifiuta il programma: manca il checkpoint ${checkpoints[checkpointIndex].label}.`);
          return;
        }
        fail(mistakeAnalyzer.robotFailureMessage(hasKey ? { kind: "not-exited" } : { kind: "missing-key" }, this.robotCommands));
        return;
      }
    };

    runAt(0);
  }

  private robotCellX(col: number): number {
    return this.robotOrigin.x + col * this.robotCellSize;
  }

  private robotCellY(row: number): number {
    return this.robotOrigin.y + row * this.robotCellSize;
  }

  private robotRotationFor(facing: GridFacing): number {
    return {
      N: 0,
      E: Math.PI / 2,
      S: Math.PI,
      W: -Math.PI / 2,
    }[facing];
  }

  private flashRobotCell(col: number, row: number, color: number): void {
    const puzzle = this.currentRobotPuzzle();
    const safeCol = Phaser.Math.Clamp(col, 0, puzzle.cols - 1);
    const safeRow = Phaser.Math.Clamp(row, 0, puzzle.rows - 1);
    const flash = this.add.rectangle(this.robotCellX(safeCol), this.robotCellY(safeRow), this.robotCellSize - 6, this.robotCellSize - 6, color, 0.32);
    this.overlay?.add(flash);
    this.tweens.add({
      targets: flash,
      alpha: 0,
      scale: 1.2,
      duration: 520,
      onComplete: () => flash.destroy(),
    });
  }

  private shakeRobot(): void {
    if (!this.robotSprite) {
      return;
    }
    const startX = this.robotSprite.x;
    this.tweens.add({
      targets: this.robotSprite,
      x: { from: startX - 8, to: startX + 8 },
      duration: 45,
      yoyo: true,
      repeat: 4,
      onComplete: () => {
        this.robotSprite?.setX(startX);
      },
    });
    audioManager.play("error");
  }

  private facingLabel(facing: GridFacing): string {
    return {
      N: "punta verso nord",
      E: "punta verso est",
      S: "punta verso sud",
      W: "punta verso ovest",
    }[facing];
  }

  private formatRobotCommands(commands: GridCommand[], limit = commands.length): string {
    const visible = commands.slice(0, limit).map((command, index) => `${index + 1}. ${commandLabels[command]}`);
    if (commands.length > limit) {
      visible.push(`... altri ${commands.length - limit}`);
    }
    return visible.join("\n");
  }

  private openDoor(): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const missing = this.requiredPuzzleIds().filter((id) => !this.isResolved(id));
    if (missing.length > 0) {
      feedbackSystem.publish(`La porta resta in attesa: manca ancora ${missing.map((id) => this.puzzleLabel(id)).join(", ")}.`, "hint");
      audioManager.playOutcome("wrong");
      return;
    }
    this.certifyCompletedRun("Tutte le console richieste sono stabili.");
  }

  private certifyCompletedRun(reason: string): void {
    if (this.isRunInteractionLocked()) {
      return;
    }
    if (this.isProgressiveMode()) {
      this.completeProgressiveLevel(true, reason);
      return;
    }
    const mode = proceduralRunRules.modeFor(this.run);
    audioManager.playOutcome("complete");
    outcomeFeedback.play(this, "complete", mode === "training" ? "Allenamento registrato" : "Missione completata");
    missionEngine.completeProceduralMission();
    this.run = saveSystem.data.proceduralRun ?? this.run;
    feedbackSystem.publish(
      mode === "training"
        ? "Allenamento completato. Il diario registra voto, miglior tempo e competenze del focus."
        : "Missione completata. Il diario registra seed, competenze, tempo e vite rimaste.",
      "success",
    );
    this.runWhenActive(900, () => this.scene.start("JournalScene"));
  }

  private solvePuzzle(puzzleId: string, competencies: string[]): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizePuzzleScore(puzzleId);
    saveSystem.markProceduralPuzzleSolved(puzzleId);
    competencyTracker.award(competencies, 10 + this.run.difficulty * 2 + (score.focusBonus > 0 ? 4 : 0));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    this.clearOverlay();
    const solvedNode = puzzleKindFromId(puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    const nextLine = remaining.length > 0
      ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.`
      : "Percorso disciplinare completo: la porta finale è pronta.";
    feedbackSystem.publish(`${this.dependencies.effectLine(solvedNode)} +${score.total} punti (${formatDuration(score.elapsedMs)}). ${score.feedback} ${nextLine}`, "success");
    if (remaining.length === 0) {
      this.certifyCompletedRun("Ultima console stabilizzata: il sistema completo e certificabile.");
      return;
    }
    if (this.isProgressiveMode()) {
      this.scheduleNextProgressivePuzzle(850);
      return;
    }
    this.runWhenActive(640, () => this.scene.restart());
  }

  private nextPendingProgressivePuzzleId(): string | undefined {
    if (!this.isProgressiveMode()) {
      return undefined;
    }
    return this.requiredPuzzleIds().find((id) => !this.isSolved(id));
  }

  private scheduleNextProgressivePuzzle(delayMs: number): void {
    if (!this.isProgressiveMode() || this.isRunInteractionLocked()) {
      return;
    }
    const nextPuzzleId = this.nextPendingProgressivePuzzleId();
    if (!nextPuzzleId) {
      return;
    }
    this.runWhenActive(delayMs, () => {
      if (this.isRunInteractionLocked() || this.checkMissionTimeout() || this.overlay) {
        return;
      }
      this.refreshObjective();
      feedbackSystem.publish(`Prossima console: ${this.puzzleLabel(nextPuzzleId)}. Rispondi con precisione: un errore costa una vita.`, "info");
      this.openPuzzleConsole(nextPuzzleId);
    });
  }

  private nextPedagogicHint(puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } }, fallback: string): string {
    const ladder = puzzle.pedagogy?.hintLadder;
    if (ladder && ladder.length > 0) {
      return ladder[Math.min(this.run.hintsUsed, ladder.length - 1)].text;
    }
    return fallback;
  }

  private useHint(text: string): void {
    this.recordPuzzleSupport();
    saveSystem.incrementProceduralHints();
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("hint");
    feedbackSystem.publish(`Indizio: ${text}`, "hint");
  }

  private handleIncorrectAnswer(message: string): boolean {
    if (this.isRunInteractionLocked()) {
      return true;
    }
    if (this.checkMissionTimeout()) {
      return true;
    }
    this.recordPuzzleMistake();
    if (this.isTimedMissionMode()) {
      this.loseMissionLife(message);
      return true;
    }
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Risposta da rivedere");
    this.finalizeTrainingPuzzleFailure(`Tentativo chiuso: ${message}`);
    return true;
  }

  private finalizeTrainingPuzzleFailure(message: string): void {
    if (this.runMode() !== "training") {
      feedbackSystem.publish(`Tentativo da rivedere: ${message}`, "warning");
      return;
    }
    const puzzleId = this.activePuzzleId;
    if (!puzzleId) {
      feedbackSystem.publish(`Tentativo da rivedere: ${message}`, "warning");
      return;
    }
    saveSystem.markProceduralPuzzleFailed(puzzleId);
    this.run = saveSystem.data.proceduralRun ?? this.run;
    this.discardActivePuzzleAttempt();
    this.clearOverlay();
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id));
    feedbackSystem.publish(
      `${message} La prova resta registrata come fallita: niente tentativi a caso. ${remaining.length > 0 ? `Restano ${remaining.length} console.` : "Apri la porta per il voto finale."}`,
      "warning",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Allenamento concluso: il registro include prove riuscite e fallite.");
      return;
    }
    this.runWhenActive(760, () => this.scene.restart());
  }

  private handlePuzzleTimeout(
    message: string,
    solutionLines: string[] = ["Soluzione: controlla il dato corretto e riparti dal metodo guidato."],
    onTrainingContinue?: () => void,
  ): void {
    if (this.timeoutSolutionOpen || this.isRunInteractionLocked()) {
      return;
    }
    if (this.checkMissionTimeout()) {
      return;
    }
    this.timeoutSolutionOpen = true;
    this.recordPuzzleMistake();
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", message.toLowerCase().includes("tempo scaduto") ? "Tempo scaduto" : "Da rivedere");
    this.showTimeoutSolution(message, solutionLines, onTrainingContinue);
  }

  private handleMusicMistake(message: string): void {
    if (this.isRunInteractionLocked()) {
      return;
    }
    if (this.checkMissionTimeout()) {
      return;
    }
    this.recordPuzzleMistake();
    if (this.isTimedMissionMode()) {
      this.loseMissionLife(message);
      return;
    }
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Riconta");
    feedbackSystem.publish(message, "warning");
  }

  private loseMissionLife(reason: string): void {
    if (this.isRunInteractionLocked()) {
      return;
    }
    const lives = this.run.lives ?? proceduralRunRules.maxLives;
    const nextLives = Math.max(0, lives - 1);
    if (nextLives <= 0) {
      if (this.isProgressiveMode()) {
        this.missionFailureInProgress = true;
        audioManager.playOutcome("wrong");
        this.discardActivePuzzleAttempt();
        this.clearOverlay();
        saveSystem.updateProceduralRun({ lives: 0 });
        this.run = saveSystem.data.proceduralRun ?? this.run;
        this.completeProgressiveLevel(false, reason);
        return;
      }
      this.failMissionNow(reason);
      return;
    }

    this.missionFailureInProgress = true;
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Vita persa");
    this.discardActivePuzzleAttempt();
    this.clearOverlay();

    if (nextLives > 0) {
      saveSystem.updateProceduralRun({
        lives: nextLives,
      });
      this.run = saveSystem.data.proceduralRun ?? this.run;
      feedbackSystem.publish(this.isProgressiveMode()
        ? `Tentativo fallito: ${reason} Restano ${nextLives}/${this.run.maxLives ?? proceduralRunRules.maxLives}. La scalata riapre automaticamente la prossima console non stabile.`
        : `Vita persa: ${reason} Restano ${nextLives}/${this.run.maxLives ?? proceduralRunRules.maxLives}. I sistemi già stabilizzati restano validi; scegli con attenzione la prossima console.`, "warning");
      this.runWhenActive(1050, () => this.scene.restart());
      return;
    }
  }

  private failMissionNow(reason: string): void {
    if (this.missionFailureInProgress && this.run.failedAt) {
      return;
    }
    this.missionFailureInProgress = true;
    const now = new Date().toISOString();
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Missione fallita");
    this.discardActivePuzzleAttempt();
    this.clearOverlay();
    saveSystem.updateProceduralRun({
      lives: 0,
      failedAt: now,
      pausedRemainingMs: undefined,
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
    feedbackSystem.publish(`Missione fallita: ${reason} Non ci sono piu condizioni utili per proseguire: ricomincia dal menu con una nuova missione.`, "warning");
    this.runWhenActive(1800, () => this.scene.start("MainMenuScene"));
  }

  private completeProgressiveLevel(success: boolean, reason: string): void {
    if (this.progressiveOutcomeOpen) {
      return;
    }
    const progressive = this.run.progressive;
    if (!progressive) {
      return;
    }
    this.progressiveOutcomeOpen = true;
    this.discardActivePuzzleAttempt();
    this.clearOverlay();
    const completedAt = new Date().toISOString();
    const required = this.requiredPuzzleIds();
    const solvedCount = required.filter((id) => this.isSolved(id)).length;
    const elapsedMs = Math.max(1000, new Date(completedAt).getTime() - new Date(progressive.levelStartedAt).getTime());
    const result: ProgressiveLevelResult = {
      level: progressive.currentLevel,
      completed: success,
      solvedCount,
      requiredCount: required.length,
      elapsedMs,
      score: this.run.score?.total ?? 0,
      outcome: this.assessProgressiveOutcome(success, solvedCount, required.length),
      completedAt,
    };
    const results = [...progressive.results.filter((item) => item.level !== result.level), result]
      .sort((a, b) => a.level - b.level);
    const unlockedLevel = success
      ? Math.min(progressive.maxLevel, Math.max(progressive.unlockedLevel, result.level + 1)) as DifficultyLevel
      : progressive.unlockedLevel;
    saveSystem.updateProceduralRun({
      progressive: {
        ...progressive,
        unlockedLevel,
        results,
      },
      lives: this.run.lives,
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
    const finalCompleted = success && result.level >= progressive.maxLevel;
    if (finalCompleted) {
      this.completeProgressiveRun(results);
    }
    this.showProgressiveOutcome(result, reason, results, finalCompleted);
    if (!finalCompleted) {
      const resumeLevel = success
        ? Math.min(progressive.maxLevel, result.level + 1) as DifficultyLevel
        : result.level;
      this.parkProgressiveLevel(resumeLevel, results);
    }
  }

  private assessProgressiveOutcome(
    success: boolean,
    solvedCount: number,
    requiredCount: number,
  ): ProgressiveOutcomeTone {
    const solvedRatio = requiredCount > 0 ? solvedCount / requiredCount : 0;
    if (!success) {
      if (solvedRatio <= 0.2 || (this.run.lives ?? 0) <= 0) return "devastating-defeat";
      if (solvedRatio < 0.7) return "defeat";
      return "neutral";
    }
    const remainingRatio = this.run.timeLimitMs
      ? Math.max(0, proceduralRunRules.remainingMs(this.run)) / this.run.timeLimitMs
      : 0;
    const attempts = Object.values(this.run.puzzleStats ?? {}).reduce((sum, score) => sum + score.attempts, 0);
    const cleanRun = this.run.hintsUsed === 0 && attempts <= requiredCount + 1;
    return remainingRatio >= 0.32 && cleanRun ? "grand-victory" : "light-victory";
  }

  private completeProgressiveRun(results: ProgressiveLevelResult[]): void {
    const completedAt = new Date().toISOString();
    const totalScore = results.reduce((sum, result) => sum + result.score, 0);
    const totalElapsed = results.reduce((sum, result) => sum + result.elapsedMs, 0);
    saveSystem.updateProceduralRun({
      completedAt,
      score: {
        ...(this.run.score ?? { byPuzzle: {}, byDomain: {} }),
        total: totalScore,
      },
    });
    const completedRun = saveSystem.data.proceduralRun ?? {
      ...this.run,
      completedAt,
      score: { ...(this.run.score ?? { byPuzzle: {}, byDomain: {} }), total: totalScore },
    };
    playerSystem.recordProceduralRun(completedRun);
    saveSystem.completeMission("mission-progressive-scalata");
    saveSystem.addJournalEntry({
      id: `progressive-summary-${completedRun.seed}`,
      title: "Scalata progressiva completata",
      lines: [
        "Eli ha attraversato le otto stanze riconfigurabili: ogni livello ha intrecciato discipline diverse con difficoltà crescente.",
        `Punteggio totale: ${totalScore}. Tempo complessivo sui livelli: ${formatDuration(totalElapsed)}.`,
        `Livelli superati: ${results.filter((result) => result.completed).length}/8. Indizi usati nell'ultimo livello: ${completedRun.hintsUsed}.`,
        "La porta del nucleo resta aperta: ora puoi ripetere la scalata per migliorare tempo, precisione e qualità delle decisioni.",
      ],
      badges: ["Scalatrice dell'Accademia", "Custode delle Discipline", "Stratega del Tempo"],
      createdAt: completedAt,
    });
    this.run = saveSystem.data.proceduralRun ?? completedRun;
  }

  private showProgressiveOutcome(
    result: ProgressiveLevelResult,
    reason: string,
    results: ProgressiveLevelResult[],
    finalCompleted: boolean,
  ): void {
    const palette: Record<ProgressiveOutcomeTone, { title: string; subtitle: string; tint: number; textColor: string }> = {
      "devastating-defeat": {
        title: "Brutta sconfitta",
        subtitle: "La stanza ha ceduto: serve ripartire dal metodo, non dalla velocità.",
        tint: 0xff6f6f,
        textColor: "#ffb0a8",
      },
      defeat: {
        title: "Sconfitta",
        subtitle: "Hai stabilizzato alcuni sistemi, ma il livello non è certificato.",
        tint: 0xffa15c,
        textColor: "#ffcb9a",
      },
      neutral: {
        title: "Esito neutro",
        subtitle: "Il ragionamento c'è, ma non basta ancora per sbloccare il livello successivo.",
        tint: 0xc9d6dd,
        textColor: "#d9eaf1",
      },
      "light-victory": {
        title: "Vittoria leggera",
        subtitle: "Livello superato: metodo corretto, margine migliorabile.",
        tint: 0x9ff5e9,
        textColor: "#9ff5e9",
      },
      "grand-victory": {
        title: "Vittoria grandiosa",
        subtitle: "Soluzione pulita e rapida: la stanza ha aperto un corridoio diretto.",
        tint: 0xf7d37a,
        textColor: "#f7d37a",
      },
    };
    const copy = palette[result.outcome];
    const maxLevel = this.run.progressive?.maxLevel ?? 8;
    const nextLevel = Math.min(maxLevel, result.level + 1) as DifficultyLevel;
    const overlay = this.add.container(0, 0).setDepth(1900);
    SceneChrome.modalInputBlocker(this, overlay, 0, 0, 0x02070b, 0.88);
    overlay.add(this.add.image(324, 360, `outcome-${result.outcome}`).setDisplaySize(438, 438).setAlpha(0.96));
    overlay.add(this.add.rectangle(324, 360, 466, 466, 0x000000, 0).setStrokeStyle(2, copy.tint, 0.46));
    overlay.add(this.add.rectangle(854, 360, 642, 466, 0x07151d, 0.96).setStrokeStyle(2, copy.tint, 0.72));
    overlay.add(this.add.text(568, 158, copy.title, {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: copy.textColor,
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(570, 210, copy.subtitle, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      wordWrap: { width: 560 },
      lineSpacing: 5,
    }));
    overlay.add(this.add.text(570, 270, [
      `Livello: ${result.level}/${maxLevel}`,
      `Console stabilizzate: ${result.solvedCount}/${result.requiredCount}`,
      `Tempo usato: ${formatDuration(result.elapsedMs)}`,
      `Punti livello: ${result.score}`,
      `Motivo: ${reason}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#d9eaf1",
      lineSpacing: 8,
      wordWrap: { width: 560 },
    }));
    const narrative = result.completed
      ? finalCompleted
        ? "NORA: nucleo stabilizzato. La scalata è completa, ma il registro resta pronto per una run migliore."
        : `NORA: livello ${result.level} certificato. Il livello ${nextLevel} è ora accessibile.`
      : "NORA: nessuna punizione cieca. Leggi il riepilogo, riprova con una strategia più precisa.";
    overlay.add(this.add.rectangle(570, 432, 568, 82, 0x102533, 0.82).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.34));
    overlay.add(this.add.text(594, 452, narrative, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      wordWrap: { width: 520 },
      lineSpacing: 4,
    }));
    if (finalCompleted) {
      overlay.add(new Button(this, 736, 608, "Diario", () => this.scene.start("JournalScene"), {
        width: 224,
        height: 54,
        fill: 0x173b36,
        stroke: 0xf7d37a,
        fontSize: 18,
      }));
    } else {
      overlay.add(new Button(this, 716, 608, result.completed ? "Livello successivo" : "Riprova livello", () => {
        this.progressiveOutcomeOpen = false;
        this.missionFailureInProgress = false;
        this.startProgressiveLevel(result.completed ? nextLevel : result.level, results);
      }, {
        width: 270,
        height: 54,
        fill: result.completed ? 0x173b36 : 0x263743,
        stroke: copy.tint,
        fontSize: 18,
      }));
    }
    overlay.add(new Button(this, 1010, 608, "Menu", () => {
      this.progressiveOutcomeOpen = false;
      this.missionFailureInProgress = false;
      if (!finalCompleted) {
        this.parkProgressiveLevel(result.completed ? nextLevel : result.level, results);
      }
      this.scene.start("MainMenuScene");
    }, {
      width: 206,
      height: 54,
      fill: 0x263743,
      stroke: 0x6be7d6,
      fontSize: 18,
    }));
    this.overlay = overlay;
    audioManager.playOutcome(result.completed ? "complete" : "wrong");
  }

  private isSolved(puzzleId: string): boolean {
    return isProceduralPuzzleSolved(puzzleId, this.run.solvedPuzzleIds);
  }

  private isFailed(puzzleId: string): boolean {
    return isProceduralPuzzleSolved(puzzleId, this.run.failedPuzzleIds ?? []);
  }

  private isResolved(puzzleId: string): boolean {
    return this.isSolved(puzzleId) || this.isFailed(puzzleId);
  }

  private allPuzzlesSolved(): boolean {
    const required = this.requiredPuzzleIds();
    return this.runMode() === "training"
      ? required.every((id) => this.isResolved(id))
      : required.every((id) => this.isSolved(id));
  }

  private refreshObjective(): void {
    if (this.checkMissionTimeout()) {
      return;
    }
    const pendingObjectives = this.run.mission.objectives.filter((objective) => !this.isResolved(objective.id.replace("procedural-", "")));
    const requiredCount = this.requiredPuzzleIds().length;
    const elapsed = this.run.completedAt
      ? new Date(this.run.completedAt).getTime() - new Date(this.run.startedAt).getTime()
      : Date.now() - new Date(this.run.startedAt).getTime();
    const mode = proceduralRunRules.modeFor(this.run);
    const focus = proceduralRunRules.focusFor(this.run);
    const recordKey = proceduralRunRules.trainingRecordKey(focus, this.run.difficulty);
    const record = saveSystem.data.trainingRecords?.[recordKey];
    const remainingMs = proceduralRunRules.remainingMs(this.run);
    const checklist = this.run.mission.objectives.map((objective) => {
      const puzzleId = objective.id.replace("procedural-", "");
      const state = this.isSolved(puzzleId) ? "[verde]" : this.isFailed(puzzleId) ? "[fallita]" : "[rosso]";
      return `${state} ${objective.label}`;
    }).join("\n");
    const solvedCount = this.requiredPuzzleIds().filter((id) => this.isSolved(id)).length;
    const failedCount = this.requiredPuzzleIds().filter((id) => this.isFailed(id)).length;
    const progressiveLevel = this.run.progressive?.currentLevel ?? this.run.difficulty;
    this.objectiveText?.setText(
      pendingObjectives.length > 0
        ? mode === "progressive"
          ? `Livello ${progressiveLevel}/8\n${checklist}\n\nSequenza automatica: la prossima console rossa si apre da sola. Ogni errore consuma una vita.`
          : mode === "mission"
          ? `Console della stanza\n${checklist}\n\nLa porta finale controlla solo il sistema completo.`
          : `Focus ${proceduralScoring.domainLabel(focus)}\n${checklist}\n\nMigliora voto: meno errori, meno aiuti, tempo piu basso.`
        : mode === "progressive"
          ? `Livello ${progressiveLevel} coerente.\n[verde] Porta di livello pronta.\n\nAprila per certificare la scalata.`
          : mode === "mission"
          ? `Tutti i sistemi sono coerenti.\n[verde] Porta finale pronta.\n\nAprila per chiudere il diario seed.`
          : `Allenamento completato.\n[verde] Porta pronta.\n\nAprila per registrare voto e miglior tempo.`,
    );
    this.progressText?.setText(
      mode === "mission" || mode === "progressive"
        ? `Console verdi: ${solvedCount}/${requiredCount}\nVite: ${this.run.lives ?? proceduralRunRules.maxLives}/${this.run.maxLives ?? proceduralRunRules.maxLives}\nTempo: ${formatDuration(Math.max(0, remainingMs))}\nPunti: ${this.run.score?.total ?? 0}`
        : `Riuscite: ${solvedCount}/${requiredCount}\nFallite: ${failedCount}\nIndizi: ${this.run.hintsUsed}\nTempo: ${formatDuration(elapsed)}\nRecord: ${record ? formatDuration(record.bestTimeMs) : "non ancora"}\nPunti: ${this.run.score?.total ?? 0}`,
    );
  }

  private checkMissionTimeout(): boolean {
    if (this.isRunInteractionLocked()) {
      return true;
    }
    const mode = proceduralRunRules.modeFor(this.run);
    if ((mode !== "mission" && mode !== "progressive") || this.run.completedAt || this.run.failedAt) {
      return false;
    }
    if (proceduralRunRules.remainingMs(this.run) > 0) {
      return false;
    }
    if (mode === "progressive") {
      this.completeProgressiveLevel(false, "Tempo esaurito.");
      return true;
    }
    this.failMissionNow("tempo esaurito: la missione ha finito il tempo disponibile.");
    return true;
  }

  private requiredPuzzleIds(): string[] {
    return proceduralRequiredPuzzleIds(this.run.mission.objectives);
  }

  private puzzleLabel(id: string): string {
    return {
      language: "italiano",
      circuit: "circuiti",
      math: "matematica",
      english: "inglese",
      robot: "coding",
      coding: "coding",
      music: "musica",
    }[puzzleKindFromId(id)];
  }

  private findFocusChallenge(id: string): GeneratedFocusChallenge | undefined {
    return this.run.mission.focusChallenges?.find((challenge) => challenge.id === id);
  }

  private currentPuzzleId(kind: ProceduralPuzzleId): string {
    return this.activePuzzleKind === kind ? this.activePuzzleId ?? kind : kind;
  }

  private currentLanguagePuzzle(): GeneratedLanguagePuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "language" ? challenge.puzzle : this.run.mission.puzzles.language;
  }

  private currentCircuitPuzzle(): GeneratedCircuitPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "circuit" ? challenge.puzzle : this.run.mission.puzzles.circuit;
  }

  private currentMathPuzzle(): GeneratedMathPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "math" ? challenge.puzzle : this.run.mission.puzzles.math;
  }

  private currentEnglishPuzzle(): GeneratedEnglishPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "english" ? challenge.puzzle : this.run.mission.puzzles.english;
  }

  private currentCodingPuzzle(): GeneratedCodingPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "coding" ? challenge.puzzle : this.run.mission.puzzles.coding;
  }

  private currentMusicPuzzle(): GeneratedMusicPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "music" ? challenge.puzzle : this.run.mission.puzzles.music;
  }

  private currentRobotPuzzle(): GeneratedRobotPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "robot" ? challenge.puzzle : this.run.mission.puzzles.robot;
  }

  private resetTransientPuzzleState(): void {
    this.mathEntry = "";
    this.mathStepIndex = 0;
    this.mathSupportMessage = "";
    this.mathSupportText = undefined;
    this.languageAnalyzed = false;
    this.englishAnalyzed = false;
    this.circuitInspected = false;
    this.circuitConceptVerified = false;
    this.circuitConceptIndex = 0;
    this.circuitSymbolAnswer = undefined;
    this.circuitFunctionAnswer = undefined;
    this.selectedRepairs.clear();
    this.robotCommands = [];
    this.robotExecuting = false;
    this.musicTimerEvent?.remove(false);
    this.musicTimerEvent = undefined;
    this.musicSession = undefined;
    this.mathMinigameTimerEvent?.remove(false);
    this.mathMinigameTimerEvent = undefined;
    this.mathMinigameTimerText = undefined;
    this.mathMinigameSession = undefined;
    this.languageMinigameTimerEvent?.remove(false);
    this.languageMinigameTimerEvent = undefined;
    this.languageMinigameTimerText = undefined;
    this.languageMinigameSession = undefined;
    this.englishMinigameTimerEvent?.remove(false);
    this.englishMinigameTimerEvent = undefined;
    this.englishMinigameTimerText = undefined;
    this.englishMinigameSession = undefined;
    this.timeoutSolutionOpen = false;
  }

  private discardActivePuzzleAttempt(): void {
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
  }

  private ensurePuzzleTimer(puzzleId: string): void {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const current = run.puzzleStats?.[puzzleId];
    if (current?.startedAt) {
      return;
    }
    const startedAt = new Date().toISOString();
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [puzzleId]: {
          puzzleId,
          domain: proceduralScoring.puzzleDomain(puzzleId),
          startedAt,
          elapsedMs: 0,
          hintsUsed: 0,
          attempts: 0,
          basePoints: 0,
          difficultyBonus: 0,
          speedBonus: 0,
          focusBonus: 0,
          supportPenalty: 0,
          total: 0,
          feedback: "Timer avviato.",
        },
      },
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private recordPuzzleSupport(): void {
    const puzzleId = this.activePuzzleId;
    const run = saveSystem.data.proceduralRun ?? this.run;
    if (!puzzleId || this.isSolved(puzzleId)) {
      return;
    }
    const current = run.puzzleStats?.[puzzleId];
    if (!current) {
      this.ensurePuzzleTimer(puzzleId);
    }
    const refreshed = saveSystem.data.proceduralRun ?? this.run;
    const stats = refreshed.puzzleStats?.[puzzleId];
    if (!stats) {
      return;
    }
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(refreshed.puzzleStats ?? {}),
        [puzzleId]: {
          ...stats,
          hintsUsed: stats.hintsUsed + 1,
        },
      },
    });
  }

  private recordPuzzleMistake(): void {
    const puzzleId = this.activePuzzleId;
    const run = saveSystem.data.proceduralRun ?? this.run;
    if (!puzzleId || this.isSolved(puzzleId)) {
      return;
    }
    const current = run.puzzleStats?.[puzzleId];
    if (!current) {
      this.ensurePuzzleTimer(puzzleId);
    }
    const refreshed = saveSystem.data.proceduralRun ?? this.run;
    const stats = refreshed.puzzleStats?.[puzzleId];
    if (!stats) {
      return;
    }
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(refreshed.puzzleStats ?? {}),
        [puzzleId]: {
          ...stats,
          attempts: stats.attempts + 1,
        },
      },
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private finalizePuzzleScore(puzzleId: string) {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const startedAt = run.puzzleStats?.[puzzleId]?.startedAt ?? new Date().toISOString();
    const existing = run.puzzleStats?.[puzzleId];
    const completedAt = new Date().toISOString();
    const score = proceduralScoring.calculate({
      puzzleId,
      difficulty: run.difficulty,
      focus: run.focus,
      startedAt,
      completedAt,
      hintsUsed: existing?.hintsUsed ?? 0,
      attempts: (existing?.attempts ?? 0) + 1,
    });
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [puzzleId]: score,
      },
      score: proceduralScoring.addToSummary(run.score, score),
    });
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
    return score;
  }

  private createOverlay(
    title: string,
    height: number,
    layout: { x?: number; y?: number; width?: number } = {},
  ): Phaser.GameObjects.Container {
    this.clearOverlay();
    const width = layout.width ?? 800;
    const defaultY = height > 660 ? 10 : 68;
    const overlay = this.add.container(layout.x ?? 240, layout.y ?? defaultY).setDepth(1200);
    SceneChrome.modalInputBlocker(this, overlay, overlay.x, overlay.y);
    overlay.add(SceneChrome.consolePanel(this, 0, 0, width, height, title, "lab"));
    overlay.add(new Button(this, width - 84, 40, "X", () => this.closeOverlayFromUser(), {
      width: 48,
      height: 40,
      fontSize: 18,
      fill: 0x263743,
    }));
    this.overlay = overlay;
    return overlay;
  }

  private addLanguageBrief(overlay: Phaser.GameObjects.Container, model: LanguageRepairModel): void {
    overlay.add(this.add.rectangle(316, 326, 520, 188, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(76, 246, "Obiettivo di riparazione", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 270, model.repairGoal, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(76, 342, `Scopo: ${model.learningPurpose}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 2,
    }));

    overlay.add(this.add.rectangle(866, 256, 540, 66, 0x07151d, 0.78).setStrokeStyle(1, 0x6be7d6, 0.2));
    overlay.add(this.add.text(614, 232, "Concetti allenati", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(614, 254, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 500, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    overlay.add(this.add.rectangle(316, 498, 520, 134, 0x07151d, 0.78).setStrokeStyle(1, 0xf6c85f, 0.24));
    overlay.add(this.add.text(76, 444, "Controllo di qualità", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 468, model.method, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
  }

  private addEnglishBrief(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(400, 256, 704, 164, 0x07151d, 0.86).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(62, 184, "Sfida", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(62, 204, puzzle.taskPrompt ?? puzzle.commandGoal ?? "Trasforma l'istruzione inglese in una procedura sicura e non ambigua.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 410 },
      lineSpacing: 3,
    }));
    if (puzzle.sourceText) {
      const sourceText = /^(log|broken log|source|fonte):/i.test(puzzle.sourceText)
        ? puzzle.sourceText
        : `Fonte: ${puzzle.sourceText}`;
      overlay.add(this.add.text(62, 254, sourceText, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        wordWrap: { width: 410 },
        lineSpacing: 3,
      }));
    }
    overlay.add(this.add.text(62, 318, `Scopo: ${puzzle.learningPurpose ?? "Allena inglese operativo dentro una decisione tecnica."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 642 },
    }));
    overlay.add(this.add.text(500, 184, (puzzle.conceptTags ?? ["action", "condition", "safety"]).slice(0, 3).map((tag) => `#${tag}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 226 },
      lineSpacing: 4,
    }));
    const dataPoints = (puzzle.dataPoints ?? []).slice(0, 3);
    dataPoints.forEach((point, index) => {
      const y = 232 + index * 30;
      overlay.add(this.add.rectangle(610, y, 250, 24, 0x132835, 0.9).setStrokeStyle(1, 0x6be7d6, 0.25));
      overlay.add(this.add.text(492, y - 8, `${point.label}: ${point.value}${point.note ? ` (${point.note})` : ""}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#d9eaf1",
        wordWrap: { width: 236 },
      }));
    });
    const glossary = (puzzle.glossary ?? []).slice(0, 4);
    if (glossary.length > 0 && dataPoints.length === 0) {
      overlay.add(this.add.text(500, 244, glossary.map((item) => `${item.term}: ${item.meaning}`).join("\n"), {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        wordWrap: { width: 238 },
        lineSpacing: 2,
      }));
    }
  }

  private englishChallengeLabel(type: GeneratedEnglishPuzzle["challengeType"]): string {
    return {
      command: "Comando",
      safety: "Sicurezza",
      sequence: "Sequenza",
      condition: "Condizione",
      "data-reading": "Dati",
      "procedure-debug": "Debug procedura",
      "vocabulary-in-context": "Lessico in contesto",
      inference: "Inferenza",
    }[type ?? "command"];
  }

  private codingChallengeLabel(type: GeneratedCodingPuzzle["challengeType"]): string {
    return {
      "trace-output": "tracing output",
      "variable-state": "stato variabili",
      "loop-count": "ciclo",
      "conditional-branch": "condizione",
      "boolean-logic": "logica booleana",
      "debug-line": "debug",
    }[type];
  }

  private addMethodStrip(overlay: Phaser.GameObjects.Container, x: number, y: number, width: number, title: string, steps: string[]): void {
    overlay.add(this.add.rectangle(x, y, width, 52, 0x07151d, 0.82).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.32));
    overlay.add(this.add.text(x + 12, y + 8, title, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 12, y + 27, steps.join("  ->  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 24 },
    }));
  }

  private clearOverlay(): void {
    this.musicTimerEvent?.remove(false);
    this.musicTimerEvent = undefined;
    this.mathMinigameTimerEvent?.remove(false);
    this.mathMinigameTimerEvent = undefined;
    this.mathMinigameTimerText = undefined;
    this.languageMinigameTimerEvent?.remove(false);
    this.languageMinigameTimerEvent = undefined;
    this.languageMinigameTimerText = undefined;
    this.englishMinigameTimerEvent?.remove(false);
    this.englishMinigameTimerEvent = undefined;
    this.englishMinigameTimerText = undefined;
    this.overlay?.destroy(true);
    this.overlay = undefined;
    this.mathSupportText = undefined;
  }

  private closeOverlayFromUser(): void {
    this.discardActivePuzzleAttempt();
    this.clearOverlay();
    feedbackSystem.publish("Console chiusa. Scegli tu quando riaprire una prova: la stanza non forza tentativi automatici.", "info");
  }

  private handleFeedback(message: FeedbackMessage): void {
    const colors = {
      info: "#d9eaf1",
      hint: "#f7d37a",
      success: "#9ff5e9",
      warning: "#ffb36b",
    };
    this.feedbackText?.setColor(colors[message.tone]).setText(message.text);
    if (message.tone !== "info") {
      outcomeFeedback.play(this, message.tone as OutcomeTone);
    }
  }
}
