import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { buildChapterExploreRun, buildChapterTrialRun, chapterTrialLevel, chapterTrialTimeMs, CHAPTER_TRIAL_ERROR_BUDGET } from "../core/ChapterTrial";
import { markMissionComplete, markMissionExplored } from "../core/MissionCompletion";
import { competencyTracker } from "../core/CompetencyTracker";
import { exerciseDirector } from "../core/ExerciseDirector";
import { feedbackSystem, type FeedbackMessage } from "../core/FeedbackSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import { mistakeAnalyzer } from "../core/MistakeAnalyzer";
import { masterySystem } from "../core/MasterySystem";
import { missionEngine } from "../core/MissionEngine";
import { playerSystem } from "../core/PlayerSystem";
import { formatDuration, proceduralScoring } from "../core/ProceduralScoring";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { noraVoice, type NoraBeat } from "../core/NoraVoice";
import { noraChip } from "../ui/NoraChip";
import { languageTemplates } from "../data/procedural/languageTemplates";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { difficultyModel } from "../procedural/DifficultyModel";
import { CircuitFaultGenerator } from "../procedural/generators/CircuitFaultGenerator";
import { CodingPuzzleGenerator } from "../procedural/generators/CodingPuzzleGenerator";
import { EnglishInstructionGenerator } from "../procedural/generators/EnglishInstructionGenerator";
import { LanguageCorruptionGenerator, normalizeTypedAnswer } from "../procedural/generators/LanguageCorruptionGenerator";
import { MathPuzzleGenerator } from "../procedural/generators/MathPuzzleGenerator";
import { MusicNoteGenerator } from "../procedural/generators/MusicNoteGenerator";
import { PhysicsPuzzleGenerator } from "../procedural/generators/PhysicsPuzzleGenerator";
import { RobotGridGenerator } from "../procedural/generators/RobotGridGenerator";
import { progressiveMissionBuilder } from "../procedural/ProgressiveMissionBuilder";
import { Random } from "../procedural/Random";
import type {
  CircuitComponentChallenge,
  CircuitFaultType,
  CodingMinigamePrompt,
  DifficultyLevel,
  EquationLabVisual,
  EnglishMinigamePrompt,
  GeneratedFocusChallenge,
  GeneratedGraphWorkshop,
  GeneratedCodingPuzzle,
  CircuitMinigamePrompt,
  CircuitMinigameVisual,
  GeneratedCircuitMinigame,
  GeneratedCircuitPuzzle,
  GeneratedCodingMinigame,
  GeneratedEnglishMinigame,
  GeneratedEnglishPuzzle,
  GeneratedLanguagePuzzle,
  GeneratedLanguageMinigame,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  GeneratedMusicPuzzle,
  GeneratedPhysicsPuzzle,
  GeneratedRobotPuzzle,
  GeneratedRoomHotspot,
  GridCommand,
  GridFacing,
  GraphParameterKey,
  EnglishMinigameType,
  LanguageMinigameType,
  LanguageMinigamePrompt,
  MathMinigamePrompt,
  MusicMinigameType,
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
import {
  isProceduralPuzzleSolved,
  proceduralHotspotPosition,
  proceduralPuzzleOrder,
  proceduralRequiredPuzzleIds,
  puzzleKindFromId,
  sortProceduralHotspots,
  type ProceduralPuzzleId,
} from "./procedural/ProceduralMissionLayout";
import { ProceduralMissionView } from "./procedural/ProceduralMissionView";
import {
  commandLabels,
  faultLabels,
  repairLabels,
  type CircuitMinigameSession,
  type CodingMinigameSession,
  type EnglishMinigameSession,
  type LanguageMinigameSession,
  type MathMinigameSession,
  type MusicTrainingSession,
} from "./procedural/ProceduralMissionDefs";
import {
  drawBatterySymbol,
  drawBranchSymbol,
  drawCapacitorSymbol,
  drawCurrentArrows,
  drawGroundSymbol,
  drawLedSymbol,
  drawMotorSymbol,
  drawRelaySymbol,
  drawResistorSymbol,
  drawReturnSymbol,
  drawSensorSymbol,
  drawSwitchSymbol,
} from "./procedural/CircuitSymbols";

// Fresh nonce per started exercise session, so the same run/seed does not keep
// serving the identical sequence of prompts: each new sprint regenerates its
// content. Combines time and a counter to stay unique even within the same ms.
let exerciseVarietyCounter = 0;
function nextExerciseSalt(): string {
  exerciseVarietyCounter += 1;
  return `${Date.now().toString(36)}-${exerciseVarietyCounter.toString(36)}`;
}

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
  private mathSupportMessage = "";
  private mathSupportText?: Phaser.GameObjects.Text;
  private equationLabStageIndex = 0;
  private graphWorkshopPuzzleId?: string;
  private graphWorkshopValues: Partial<Record<GraphParameterKey, number>> = {};
  private graphWorkshopMoves = 0;
  private activeHintText?: string;
  private activeHintPuzzleId?: string;
  private languageSelectedOption?: string;
  private englishSelectedChoiceId?: string;
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
  private languageTypedInputEl?: HTMLInputElement;
  private englishMinigameTimerEvent?: Phaser.Time.TimerEvent;
  private englishMinigameTimerText?: Phaser.GameObjects.Text;
  private englishMinigameSession?: EnglishMinigameSession;
  private codingMinigameTimerEvent?: Phaser.Time.TimerEvent;
  private codingMinigameTimerText?: Phaser.GameObjects.Text;
  private codingMinigameSession?: CodingMinigameSession;
  private circuitMinigameTimerEvent?: Phaser.Time.TimerEvent;
  private circuitMinigameTimerText?: Phaser.GameObjects.Text;
  private circuitMinigameSession?: CircuitMinigameSession;
  private missionFailureInProgress = false;
  private timeoutSolutionOpen = false;
  private progressiveOutcomeOpen = false;
  private progressiveSynthesisAttempts = 0;
  private progressiveSynthesisOrder: number[] = [];
  private autoOpenPuzzle?: ProceduralPuzzleId;
  private noraGreetedSeed?: string;
  private runtimePausedAt?: number;
  private languageBuilderPuzzleId?: string;
  private languageBuilderShuffled: string[] = [];
  private languageBuilderPlaced: number[] = [];

  constructor() {
    super("ProceduralMissionScene");
  }

  init(data?: { autoOpenPuzzle?: ProceduralPuzzleId }): void {
    this.autoOpenPuzzle = data?.autoOpenPuzzle;
  }

  preload(): void {
    queueSceneAssets(this, "procedural");
  }

  create(): void {
    this.resetSceneLifecycleState();
    this.run = this.ensureRun();
    audioManager.playMusic("labAmbience");
    VisualKit.applyCinematicGrade(this, "lab");
    ProceduralMissionView.drawShell(this, this.run);
    const hud = ProceduralMissionView.createHud(
      this,
      this.run,
      () => this.isProgressiveMode() ? this.confirmProgressiveReset() : this.regenerate(),
      () => {
        this.pauseRunIfLeaving();
        this.scene.start("MainMenuScene");
      },
      () => this.showNoraChargePanel(),
    );
    this.objectiveText = hud.objectiveText;
    this.progressText = hud.progressText;
    this.feedbackText = hud.feedbackText;
    ProceduralMissionView.createHotspots(this, this.run, this.allPuzzlesSolved(), (hotspot) => this.openHotspot(hotspot));
    this.refreshObjective();
    this.time.addEvent({ delay: 1000, loop: true, callback: () => this.refreshObjective() });

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    EventBus.on(GameEvents.RuntimePauseRequested, this.handleRuntimePause, this);
    EventBus.on(GameEvents.RuntimeResumeRequested, this.handleRuntimeResume, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
      EventBus.off(GameEvents.RuntimePauseRequested, this.handleRuntimePause, this);
      EventBus.off(GameEvents.RuntimeResumeRequested, this.handleRuntimeResume, this);
      this.pauseRunIfLeaving();
    });

    feedbackSystem.publish(this.roomEntryFeedback(), this.run.solvedPuzzleIds.length > 0 ? "success" : "info");
    // NORA greets once per run (the scene restarts between consoles, so gate by seed).
    if (this.noraGreetedSeed !== this.run.seed && this.run.solvedPuzzleIds.length === 0) {
      this.noraGreetedSeed = this.run.seed;
      this.time.delayedCall(520, () => this.noraSay("enter"));
    }
    this.time.delayedCall(80, () => this.showRunReadyOverlay());
  }

  /** Speaks an in-character NORA line for a beat (story modes only). */
  private noraSay(beat: NoraBeat): void {
    if (this.runMode() === "training") {
      return;
    }
    const tone = beat === "victory" || beat === "solve" ? "success" : beat === "lifeLost" || beat === "lowLife" || beat === "defeat" ? "warning" : "info";
    noraChip.say(this, noraVoice.line(beat), tone);
  }

  private roomEntryFeedback(): string {
    const solved = this.run.solvedPuzzleIds.length;
    const total = Math.max(1, this.requiredPuzzleIds().length);
    const availableCharges = this.availableNoraCharges();
    if (solved >= total) {
      return "NORA: tutte le linee della stanza sono accese. Resta la certificazione finale del sistema.";
    }
    if (solved >= Math.ceil(total * 0.75)) {
      return `NORA: il nucleo risponde e la stanza è quasi stabile. ${total - solved} sistemi restano da collegare.${availableCharges > 0 ? " Hai un impulso NORA disponibile." : ""}`;
    }
    if (solved >= Math.ceil(total * 0.4)) {
      return `NORA: le prime riparazioni stanno cambiando l'ambiente; ora le tracce tra i sistemi sono più leggibili.${availableCharges > 0 ? " Hai guadagnato un impulso NORA." : ""}`;
    }
    if (solved > 0) {
      return `NORA: una parte della stanza è tornata attiva. Il cambiamento resterà visibile nella prossima diagnosi.`;
    }
    const adaptivePrompt = this.adaptiveMemoryPrompt();
    if (adaptivePrompt) return adaptivePrompt;
    return this.isProgressiveMode()
      ? `Scalata guidata avviata. La stanza aprirà una console alla volta. Seed: ${this.run.seed}.`
      : `Stanza generata. Scegli una console da stabilizzare. Seed: ${this.run.seed}.`;
  }

  private adaptiveMemoryPrompt(): string | undefined {
    const nextId = this.requiredPuzzleIds().find((id) => !this.isSolved(id));
    if (!nextId) return undefined;
    const kind = puzzleKindFromId(nextId);
    const count = saveSystem.data.learningMemory?.[`${kind}:concept`]?.count ?? 0;
    if (count < 3) return undefined;
    return `NORA riconosce un punto da consolidare in ${this.puzzleLabel(kind)}: prima individua la prova, poi formula la risposta. La difficoltà resta stabile finché il metodo non diventa autonomo.`;
  }

  private availableNoraCharges(): number {
    const chargeStep = saveSystem.data.inventory.includes("nora-reserve") ? 1 : 2;
    const earned = Math.min(2, Math.floor(this.run.solvedPuzzleIds.length / chargeStep));
    return Math.max(0, earned - (this.run.noraChargesUsed ?? 0));
  }

  private showNoraChargePanel(): void {
    if (this.overlay || this.availableNoraCharges() <= 0 || this.runMode() === "training") {
      return;
    }
    const overlay = this.add.container(0, 0).setDepth(1900);
    SceneChrome.modalInputBlocker(this, overlay, 0, 0, 0x02070b, 0.86);
    overlay.add(this.add.rectangle(640, 360, 680, 390, 0x07151d, 0.99).setStrokeStyle(2, 0xf6c85f, 0.82));
    overlay.add(this.add.text(340, 202, "Impulso NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(340, 252, "Hai collegato abbastanza sistemi da alimentare uno strumento di emergenza. Scegli un solo effetto.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 600 },
      lineSpacing: 5,
    }));
    const status = this.add.text(340, 456, `Cariche disponibili: ${this.availableNoraCharges()}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
    });
    overlay.add(status);
    let applied = false;
    const applyCharge = (effect: "time" | "life"): void => {
      if (applied || this.availableNoraCharges() <= 0) return;
      applied = true;
      const update: Partial<ProceduralRunSave> = { noraChargesUsed: (this.run.noraChargesUsed ?? 0) + 1 };
      if (effect === "time") {
        const currentDeadline = this.run.deadlineAt ? new Date(this.run.deadlineAt).getTime() : Date.now();
        update.deadlineAt = new Date(Math.max(Date.now(), currentDeadline) + 30_000).toISOString();
      } else {
        const restored = saveSystem.data.inventory.includes("nora-shield") ? 2 : 1;
        update.lives = Math.min(this.run.maxLives ?? proceduralRunRules.maxLives, (this.run.lives ?? proceduralRunRules.maxLives) + restored);
      }
      saveSystem.updateProceduralRun(update);
      this.run = saveSystem.data.proceduralRun ?? this.run;
      audioManager.playOutcome("complete");
      const lifeGain = saveSystem.data.inventory.includes("nora-shield") ? 2 : 1;
      outcomeFeedback.play(this, "complete", effect === "time" ? "+30 secondi" : `+${lifeGain} vita${lifeGain > 1 ? "e" : ""}`);
      status.setColor("#f7d37a").setText(effect === "time" ? "NORA ha stabilizzato il timer." : "NORA ha ricostruito una protezione.");
      this.runWhenActive(1200, () => this.scene.restart());
    };
    overlay.add(new Button(this, 500, 382, "Stabilizza tempo · +30 s", () => applyCharge("time"), {
      width: 270,
      height: 58,
      fill: 0x173b36,
      stroke: 0x6be7d6,
      fontSize: 15,
    }));
    const lifeButton = new Button(this, 790, 382, "Ricostruisci protezione · +1 vita", () => applyCharge("life"), {
      width: 270,
      height: 58,
      fill: 0x3a2525,
      stroke: 0xf6c85f,
      fontSize: 14,
    });
    lifeButton.setEnabled((this.run.lives ?? proceduralRunRules.maxLives) < (this.run.maxLives ?? proceduralRunRules.maxLives));
    overlay.add(lifeButton);
    overlay.add(new Button(this, 640, 510, "Conserva la carica", () => this.clearOverlay(), {
      width: 230,
      height: 44,
      fill: 0x263743,
      fontSize: 14,
    }));
    this.overlay = overlay;
  }

  private pauseRunIfLeaving(): void {
    const activeRun = saveSystem.data.proceduralRun;
    if (!activeRun || activeRun.completedAt || activeRun.failedAt) {
      return;
    }
    saveSystem.pauseActiveProceduralRun();
  }

  private handleRuntimePause(): void {
    if (!this.scene.isActive() || this.run.timerState !== "running") return;
    this.runtimePausedAt = Date.now();
    saveSystem.pauseActiveProceduralRun();
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private handleRuntimeResume(): void {
    if (!this.scene.isActive() || this.run.completedAt || this.run.failedAt) return;
    if (this.runtimePausedAt) {
      const pausedFor = Math.max(0, Date.now() - this.runtimePausedAt);
      [
        this.mathMinigameSession,
        this.languageMinigameSession,
        this.englishMinigameSession,
        this.codingMinigameSession,
        this.circuitMinigameSession,
        this.musicSession,
      ].forEach((session) => {
        if (session && session.startedAt > 0) session.startedAt += pausedFor;
      });
      if (this.musicSession && this.musicSession.questionStartedAt > 0) {
        this.musicSession.questionStartedAt += pausedFor;
      }
      this.runtimePausedAt = undefined;
    }
    if (this.run.timerState === "paused") {
      this.time.delayedCall(80, () => this.showRunReadyOverlay(true));
    }
  }

  private showRunReadyOverlay(resuming = false): void {
    if (!this.scene.isActive() || this.run.completedAt || this.run.failedAt || this.run.timerState === "running") return;
    this.clearOverlay();
    saveSystem.updateProceduralRun({ timerState: "ready", deadlineAt: undefined });
    this.run = saveSystem.data.proceduralRun ?? this.run;
    const pressure = proceduralRunRules.pressureEnabledFor(this.run);
    const overlay = this.add.container(0, 0).setDepth(2200);
    SceneChrome.modalInputBlocker(this, overlay, 0, 0, 0x02070b, 0.9);
    const trial = this.isChapterTrial();
    overlay.add(this.add.rectangle(640, 360, 650, 330, 0x07151d, 0.98).setStrokeStyle(2, pressure ? 0xf6c85f : 0x6be7d6, 0.78));
    const explore = this.isChapterExplore();
    overlay.add(this.add.text(640, 244, resuming ? "Run in pausa" : trial ? "Prova del Capitolo" : explore ? "Fase Esplora" : "Console pronta", {
      fontFamily: "Inter, Arial",
      fontSize: "32px",
      color: trial ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (trial && this.run.chapterMissionId) {
      const level = chapterTrialLevel(this.run.chapterMissionId);
      const minutes = Math.round(chapterTrialTimeMs(this.run.chapterMissionId) / 60_000);
      overlay.add(this.add.text(640, 282, `Livello ${level}/8 · tutte le materie · max ${CHAPTER_TRIAL_ERROR_BUDGET} errori · ~${minutes} min`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#9ff5e9",
        fontStyle: "bold",
      }).setOrigin(0.5));
    }
    overlay.add(this.add.text(640, trial ? 322 : 312, explore
      ? "Prima esplori il metodo: nessun conto alla rovescia, nessuna vita persa. Completa la stanza per rendere disponibile la Prova."
      : pressure
        ? "Il timer partirà solo quando premi Inizia. Caricamento e lettura di questa schermata non consumano tempo."
        : "Modalità rilassata: nessun conto alla rovescia e nessuna vita persa. Contano metodo, precisione e correzione.", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#d9eaf1",
      align: "center",
      wordWrap: { width: 540 },
      lineSpacing: 6,
    }).setOrigin(0.5));
    const startButton = new Button(this, 640, 438, resuming ? "Riprendi" : "Inizia", () => this.startPreparedRun(), {
      width: 280,
      height: 58,
      fill: 0x1f5a51,
      stroke: pressure ? 0xf6c85f : 0x6be7d6,
      fontSize: 19,
      soundKey: "missionStart",
    }).setDepth(2201);
    overlay.add(startButton);
    this.overlay = overlay;
  }

  private startPreparedRun(): void {
    const now = new Date().toISOString();
    const pressure = proceduralRunRules.pressureEnabledFor(this.run);
    const remaining = this.run.pausedRemainingMs ?? this.run.timeLimitMs;
    const progressive = this.run.progressive
      ? {
          ...this.run.progressive,
          levelStartedAt: now,
          levelDeadlineAt: pressure && remaining ? proceduralRunRules.deadlineFrom(now, remaining) : now,
        }
      : undefined;
    saveSystem.updateProceduralRun({
      timerState: "running",
      startedAt: now,
      deadlineAt: pressure && remaining ? proceduralRunRules.deadlineFrom(now, remaining) : undefined,
      pausedRemainingMs: undefined,
      progressive,
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
    this.clearOverlay();
    this.refreshObjective();
    this.scheduleNextProgressivePuzzle(700);
    if (this.autoOpenPuzzle && !this.isProgressiveMode()) {
      const puzzleId = this.requiredPuzzleIds().find((id) => puzzleKindFromId(id) === this.autoOpenPuzzle) ?? this.autoOpenPuzzle;
      this.time.delayedCall(420, () => this.openPuzzleConsole(puzzleId));
    }
  }

  private runMode(): "mission" | "training" | "progressive" {
    return proceduralRunRules.modeFor(this.run);
  }

  private isProgressiveMode(): boolean {
    return this.runMode() === "progressive";
  }

  private isTimedMissionMode(): boolean {
    return proceduralRunRules.pressureEnabledFor(this.run);
  }

  /** True while playing a graded "Prova del Capitolo" (chapter trial). */
  private isChapterTrial(): boolean {
    return Boolean(this.run.chapterMissionId);
  }

  /** True while playing the low-pressure chapter exploration. */
  private isChapterExplore(): boolean {
    return Boolean(this.run.chapterExploreMissionId);
  }

  /**
   * Mistakes tolerated on a single console before a life is lost. Chapter trials
   * are strict — every error costs a life, so the whole chapter allows at most
   * {@link proceduralRunRules.maxLives} errors before failing.
   */
  private mistakesBeforeLifeLoss(): number {
    return this.isChapterTrial() ? 1 : proceduralRunRules.mistakesBeforeLifeLoss(this.run.difficulty);
  }

  private isRunInteractionLocked(): boolean {
    return this.missionFailureInProgress
      || this.progressiveOutcomeOpen
      || this.run.timerState !== "running"
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

  private resetSceneLifecycleState(): void {
    // Phaser keeps the Scene instance across scene.restart(). Every lock and
    // transient reference must therefore be reset explicitly for the new run.
    this.missionFailureInProgress = false;
    this.progressiveOutcomeOpen = false;
    this.progressiveSynthesisAttempts = 0;
    this.progressiveSynthesisOrder = [];
    this.timeoutSolutionOpen = false;
    this.overlay = undefined;
    this.feedbackText = undefined;
    this.objectiveText = undefined;
    this.progressText = undefined;
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
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
    const createdAt = new Date().toISOString();
    const pressureEnabled = proceduralRunRules.pressureEnabledForMode("mission");
    const timeLimitMs = pressureEnabled
      ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length))
      : undefined;
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
      lives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      maxLives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      timerState: "preparing",
      createdAt,
      activeElapsedMs: 0,
      startedAt: createdAt,
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
    const hasPhysicsPuzzle = Boolean(puzzles.physics);
    const hasPhysicsObjective = run.mission.objectives.some((objective) => puzzleKindFromId(objective.id.replace("procedural-", "")) === "physics");
    const hasPhysicsHotspot = run.mission.map.hotspots.some((hotspot) => {
      const id = hotspot.puzzleId ?? hotspot.id;
      return hotspot.puzzleKind === "physics" || id === "physics" || id.startsWith("physics-");
    });
    const hasPhysicsFocusSeries = Boolean(
      run.mission.focusChallenges?.length
      && run.mission.focusChallenges.every((challenge) => challenge.kind === "physics"),
    );
    if (focus === "musica") {
      return !(hasMusicPuzzle && hasModernMusicPuzzle && hasMusicObjective && hasMusicHotspot && hasMusicFocusSeries);
    }
    if (focus === "coding") {
      return !(hasCodingPuzzle && hasCodingObjective && hasCodingHotspot && hasCodingFocusSeries);
    }
    if (focus === "fisica") {
      return !(hasPhysicsPuzzle && hasPhysicsObjective && hasPhysicsHotspot && hasPhysicsFocusSeries);
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
    const createdAt = new Date().toISOString();
    const pressureEnabled = proceduralRunRules.pressureEnabledFor(run);
    const timeLimitMs = mode === "progressive"
      ? progressiveMissionBuilder.timeLimitMs(run.progressive?.currentLevel ?? mission.difficulty, Math.max(1, mission.objectives.length))
      : run.chapterMissionId
        ? run.timeLimitMs
        : pressureEnabled
          ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length))
          : undefined;
    const replacement: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus,
      mode,
      mission,
      chapterMissionId: run.chapterMissionId,
      chapterExploreMissionId: run.chapterExploreMissionId,
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
      progressive: mode === "progressive"
        ? {
            currentLevel: run.progressive?.currentLevel ?? run.difficulty,
            unlockedLevel: run.progressive?.unlockedLevel ?? run.difficulty,
            maxLevel: run.progressive?.maxLevel ?? 8,
            levelStartedAt: createdAt,
            levelTimeLimitMs: timeLimitMs ?? progressiveMissionBuilder.timeLimitMs(run.difficulty, Math.max(1, mission.objectives.length)),
            levelDeadlineAt: createdAt,
            results: run.progressive?.results ?? [],
          }
        : undefined,
    };
    saveSystem.setProceduralRun(replacement);
    return replacement;
  }

  private normalizeRunRules(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    const pressureEnabled = proceduralRunRules.pressureEnabledFor(run);
    const timeLimitMs = pressureEnabled ? (run.timeLimitMs ?? (mode === "progressive"
      ? progressiveMissionBuilder.timeLimitMs(run.progressive?.currentLevel ?? run.difficulty, Math.max(1, run.mission.objectives.length))
      : proceduralRunRules.missionTimeLimitMs(run.difficulty, Math.max(1, run.mission.objectives.length)))) : undefined;
    const update: Partial<ProceduralRunSave> = {};
    if (mode === "progressive" && run.progressive) {
      const currentLevel = run.progressive.currentLevel;
      if (run.difficulty !== currentLevel) update.difficulty = currentLevel;
      if (run.progressive.levelTimeLimitMs !== timeLimitMs) {
        update.progressive = { ...run.progressive, levelTimeLimitMs: timeLimitMs! };
      }
    }
    if (run.mode !== mode) update.mode = mode;
    if (pressureEnabled) {
      if (run.maxLives === undefined) update.maxLives = proceduralRunRules.maxLives;
      if (run.lives === undefined) update.lives = proceduralRunRules.maxLives;
      if (!run.timeLimitMs) update.timeLimitMs = timeLimitMs;
    } else {
      update.lives = undefined;
      update.maxLives = undefined;
      update.timeLimitMs = undefined;
      update.deadlineAt = undefined;
      update.pausedRemainingMs = undefined;
    }
    if (!run.timerState || run.timerState === "paused") update.timerState = "ready";
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
    if (this.run.chapterMissionId) {
      // Chapter trials always restart from scratch at the same level (new seed).
      saveSystem.setProceduralRun(buildChapterTrialRun(this.run.chapterMissionId));
      this.scene.restart();
      return;
    }
    if (this.run.chapterExploreMissionId) {
      saveSystem.setProceduralRun(buildChapterExploreRun(this.run.chapterExploreMissionId));
      this.scene.restart();
      return;
    }
    const nextDifficulty = Math.min(8, this.run.difficulty + (this.run.completedAt ? 1 : 0)) as DifficultyLevel;
    const mission = proceduralDirector.generateFreshMission(nextDifficulty, this.run.focus);
    const mode = proceduralRunRules.modeFor(this.run);
    const createdAt = new Date().toISOString();
    const pressureEnabled = proceduralRunRules.pressureEnabledForMode(mode);
    const timeLimitMs = pressureEnabled ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length)) : undefined;
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
      lives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      maxLives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      timerState: "preparing",
      createdAt,
      activeElapsedMs: 0,
      startedAt: createdAt,
    });
    this.scene.restart();
  }

  private confirmProgressiveReset(): void {
    if (!this.isProgressiveMode() || this.overlay) {
      return;
    }
    const currentLevel = this.run.progressive?.currentLevel ?? this.run.difficulty;
    const completedLevels = this.run.progressive?.results.filter((result) => result.completed).length ?? 0;
    const overlay = this.add.container(0, 0).setDepth(1900);
    SceneChrome.modalInputBlocker(this, overlay, 0, 0, 0x02070b, 0.86);
    overlay.add(this.add.rectangle(640, 360, 620, 330, 0x07151d, 0.98).setStrokeStyle(2, 0xf6c85f, 0.78));
    overlay.add(this.add.text(370, 226, "Azzerare la scalata?", {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(370, 282, `Sei al livello ${currentLevel}/8 e hai completato ${completedLevels} livelli.\n\nIl reset elimina progressi, risultati, punti e tempo della scalata corrente. Missioni normali, focus e registro non vengono modificati.`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 540 },
      lineSpacing: 6,
    }));
    overlay.add(new Button(this, 510, 476, "Annulla", () => this.clearOverlay(), {
      width: 210,
      height: 52,
      fill: 0x263743,
      fontSize: 17,
    }));
    overlay.add(new Button(this, 770, 476, "Riparti dal livello 1", () => {
      this.clearOverlay();
      this.progressiveOutcomeOpen = false;
      this.missionFailureInProgress = false;
      this.startProgressiveLevel(1, []);
    }, {
      width: 270,
      height: 52,
      fill: 0x3a2525,
      stroke: 0xf6c85f,
      fontSize: 16,
    }));
    this.overlay = overlay;
  }

  private createProgressiveRun(level: DifficultyLevel, previousResults: ProgressiveLevelResult[]): ProceduralRunSave {
    const levelFocus = progressiveMissionBuilder.focusForLevel(level);
    const baseMission = proceduralDirector.generateFreshMission(level, [levelFocus]);
    const mission = progressiveMissionBuilder.buildLevelMission(baseMission, level);
    const createdAt = new Date().toISOString();
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
      timerState: "preparing",
      createdAt,
      activeElapsedMs: 0,
      startedAt: createdAt,
      progressive: {
        currentLevel: level,
        unlockedLevel: Math.min(8, Math.max(level, highestUnlocked)) as DifficultyLevel,
        maxLevel: 8,
        levelStartedAt: createdAt,
        levelTimeLimitMs: timeLimitMs,
        levelDeadlineAt: createdAt,
        results: previousResults,
      },
    };
  }

  private startProgressiveLevel(level: DifficultyLevel, previousResults: ProgressiveLevelResult[]): void {
    const nextRun = this.createProgressiveRun(level, previousResults);
    saveSystem.setProceduralRun(nextRun);
    const persisted = saveSystem.getProceduralProgressiveRun();
    if (!persisted || persisted.difficulty !== level || persisted.progressive?.currentLevel !== level) {
      saveSystem.setProceduralRun(nextRun);
    }
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
      physics: () => this.openPhysics(),
    };
    if (proceduralPuzzleOrder.includes(systemId)) {
      if (this.activePuzzleId !== puzzleId) {
        this.resetTransientPuzzleState();
      }
      this.activePuzzleId = puzzleId;
      this.activePuzzleKind = systemId;
      this.activeChallenge = challenge;
      this.ensurePuzzleTimer(puzzleId);
      this.playPuzzleContextSound(systemId);
      handlers[systemId]();
      this.maybeAutoScaffold(systemId);
    }
  }

  /**
   * Adaptive remediation: when a concept keeps producing the same kind of
   * mistake, NORA opens the first useful control automatically (without
   * spending an aid). Fulfils the promise made after repeated errors and turns
   * `learningMemory` from passive diagnostics into real personalisation.
   * Skipped in focus training, where autonomy is what's being measured.
   */
  private maybeAutoScaffold(kind: ProceduralPuzzleId): void {
    if (this.runMode() === "training") {
      return;
    }
    const count = saveSystem.data.learningMemory?.[`${kind}:concept`]?.count ?? 0;
    if (count < 3) {
      return;
    }
    if (this.activeHintText && this.activeHintPuzzleId === this.activePuzzleId) {
      return;
    }
    const hints = this.currentPuzzleHintsFor(kind);
    const first = hints[0];
    if (!first) {
      return;
    }
    // Scaffolding, not a spent aid: do not increment the hint counter.
    this.activeHintText = first;
    this.activeHintPuzzleId = this.activePuzzleId;
    audioManager.playOutcome("hint");
    feedbackSystem.publish(`NORA riconosce uno schema ricorrente e apre subito il controllo utile: ${first}`, "hint");
  }

  private currentPuzzleHintsFor(kind: ProceduralPuzzleId): string[] {
    switch (kind) {
      case "language": return this.puzzleHintTexts(this.currentLanguagePuzzle());
      case "circuit": return this.puzzleHintTexts(this.currentCircuitPuzzle());
      case "math": return this.puzzleHintTexts(this.currentMathPuzzle());
      case "english": return this.puzzleHintTexts(this.currentEnglishPuzzle());
      case "robot": return this.puzzleHintTexts(this.currentRobotPuzzle());
      case "coding": return this.puzzleHintTexts(this.currentCodingPuzzle());
      case "music": return this.puzzleHintTexts(this.currentMusicPuzzle());
      case "physics": return this.puzzleHintTexts(this.currentPhysicsPuzzle());
      default: return [];
    }
  }

  private playPuzzleContextSound(systemId: ProceduralPuzzleId): void {
    if (systemId === "math") audioManager.playContext("math");
    else if (systemId === "language") audioManager.playContext("language");
    else if (systemId === "english") audioManager.playContext("english");
    else if (systemId === "circuit") audioManager.playContext("electronics");
    else if (systemId === "coding" || systemId === "robot") audioManager.playContext("coding");
    else if (systemId === "music") audioManager.playContext("music");
    else if (systemId === "physics") audioManager.playContext("math");
  }

  private openLanguage(): void {
    const puzzle = this.currentLanguagePuzzle();
    if (puzzle.minigame) {
      this.openLanguageMinigame(puzzle);
      return;
    }
    const model = LanguageRepairConsole.fromPuzzle(puzzle);
    const overlay = this.createExerciseScreen(model.title);
    LanguageRepairConsole.addHeader(this, overlay, model);
    this.addLanguageBrief(overlay, model);
    overlay.add(this.add.text(614, 294, "Scegli la frase corretta", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    model.options.forEach((option, index) => {
      const y = 330 + index * 48;
      overlay.add(new Button(this, 866, y, `${this.languageSelectedOption === option ? "✓ " : ""}${option}`, () => {
        this.languageSelectedOption = option;
        this.openLanguage();
      }, {
        width: 540,
        height: 40,
        fontSize: 11,
        wordWrapWidth: 506,
        fill: this.languageSelectedOption === option ? 0x174d42 : 0x263743,
        stroke: this.languageSelectedOption === option ? 0xf7d37a : 0x6be7d6,
      }));
    });
    overlay.add(new Button(this, 470, 620, "✍ Componi la frase", () => {
      this.openLanguageBuilder(puzzle, model);
    }, { width: 240, height: 40, fontSize: 13, fill: 0x2a3550, stroke: 0x9f8cff }));
    overlay.add(new Button(this, 738, 620, "Conferma risposta", () => {
      this.confirmLanguageReasoning(puzzle, model);
    }, { width: 240, height: 40, fontSize: 13, fill: 0x173b36, stroke: 0xf7d37a }));
    overlay.add(new Button(this, 1002, 620, this.hintButtonLabel(puzzle, "Indizio mirato"), () => {
      this.useContextualHint(puzzle);
      this.openLanguage();
    }, { width: 230, height: 40, fontSize: 13, fill: 0x263743 }));
  }

  /**
   * Construction variant of the Italian repair: instead of choosing among full
   * sentences, the learner re-assembles the corrected message from shuffled
   * word tiles. Production beats recognition didactically and plays better.
   * Reuses the existing solve / mistake plumbing.
   */
  private openLanguageBuilder(puzzle: GeneratedLanguagePuzzle, model: LanguageRepairModel): void {
    const puzzleId = this.currentPuzzleId("language");
    if (this.languageBuilderPuzzleId !== puzzleId) {
      const tokens = model.correctAnswer.split(/\s+/).filter((token) => token.length > 0);
      const random = new Random(`${this.run.seed}:lang-build:${puzzleId}`);
      const order = tokens.map((_, index) => index);
      for (let i = order.length - 1; i > 0; i -= 1) {
        const j = random.integer(0, i);
        [order[i], order[j]] = [order[j], order[i]];
      }
      this.languageBuilderShuffled = order.map((index) => tokens[index]);
      this.languageBuilderPlaced = [];
      this.languageBuilderPuzzleId = puzzleId;
    }

    const overlay = this.createExerciseScreen(model.title);
    LanguageRepairConsole.addHeader(this, overlay, model);
    this.addLanguageBrief(overlay, model);
    overlay.add(this.add.text(614, 286, "Ricostruisci il messaggio corretto: tocca le parole nell'ordine giusto.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 600 },
    }));

    // Assembled answer row.
    const assembled = this.languageBuilderPlaced.map((index) => this.languageBuilderShuffled[index]).join(" ");
    overlay.add(this.add.rectangle(614, 330, 624, 64, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
    overlay.add(this.add.text(628, 344, assembled.length > 0 ? assembled : "(tocca le tessere qui sotto)", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
      wordWrap: { width: 596 },
      lineSpacing: 3,
    }));

    // Word tiles (unused ones are tappable to append).
    let tileX = 614;
    let tileY = 414;
    this.languageBuilderShuffled.forEach((word, index) => {
      const placed = this.languageBuilderPlaced.includes(index);
      const tileWidth = Math.max(54, word.length * 11 + 24);
      if (tileX + tileWidth > 1238) {
        tileX = 614;
        tileY += 48;
      }
      overlay.add(new Button(this, tileX + tileWidth / 2, tileY + 18, word, () => {
        if (this.languageBuilderPlaced.includes(index)) {
          this.languageBuilderPlaced = this.languageBuilderPlaced.filter((i) => i !== index);
        } else {
          this.languageBuilderPlaced.push(index);
        }
        audioManager.play("click");
        this.openLanguageBuilder(puzzle, model);
      }, {
        width: tileWidth,
        height: 36,
        fontSize: 13,
        fill: placed ? 0x174d42 : 0x263743,
        stroke: placed ? 0xf7d37a : 0x6be7d6,
      }));
      tileX += tileWidth + 10;
    });

    overlay.add(new Button(this, 470, 640, "Torna a scelta", () => {
      this.openLanguage();
    }, { width: 220, height: 40, fontSize: 13, fill: 0x263743 }));
    overlay.add(new Button(this, 738, 640, "Verifica frase", () => {
      this.confirmLanguageBuilder(puzzle, model);
    }, { width: 240, height: 40, fontSize: 13, fill: 0x173b36, stroke: 0xf7d37a }));
    overlay.add(new Button(this, 1002, 640, "Svuota", () => {
      this.languageBuilderPlaced = [];
      audioManager.play("cancel");
      this.openLanguageBuilder(puzzle, model);
    }, { width: 150, height: 40, fontSize: 13, fill: 0x3a2525, stroke: 0xf6c85f }));
  }

  private confirmLanguageBuilder(puzzle: GeneratedLanguagePuzzle, model: LanguageRepairModel): void {
    const assembled = this.languageBuilderPlaced.map((index) => this.languageBuilderShuffled[index]).join(" ").trim();
    if (assembled.length === 0) {
      audioManager.playOutcome("hint");
      feedbackSystem.publish("Tocca le parole per comporre la frase, poi verifica.", "hint");
      return;
    }
    if (assembled === model.correctAnswer.trim()) {
      outcomeFeedback.answer(this, true, assembled, model.correctAnswer, model.method);
      this.languageBuilderPuzzleId = undefined;
      this.solvePuzzle(this.currentPuzzleId("language"), puzzle.competencies);
      return;
    }
    outcomeFeedback.answer(this, false, assembled, model.correctAnswer, model.method);
    this.languageBuilderPlaced = [];
    const exited = this.handleIncorrectAnswer("L'ordine non rende ancora il messaggio eseguibile: rileggi soggetto, verbo e accordo.");
    if (!exited) this.openLanguageBuilder(puzzle, model);
  }

  private confirmLanguageReasoning(puzzle: GeneratedLanguagePuzzle, model: LanguageRepairModel): void {
    const option = this.languageSelectedOption;
    if (!option) {
      audioManager.playOutcome("hint");
      feedbackSystem.publish("Prima seleziona la frase corretta.", "hint");
      return;
    }
    if (option === model.correctAnswer) {
      outcomeFeedback.answer(this, true, option, model.correctAnswer, model.method);
      this.solvePuzzle(this.currentPuzzleId("language"), puzzle.competencies);
      return;
    }
    const optionIndex = model.options.indexOf(option);
    outcomeFeedback.answer(this, false, option, model.correctAnswer, model.optionFeedback[option] ?? model.method);
    this.languageSelectedOption = undefined;
    const exited = this.handleIncorrectAnswer(model.optionFeedback[option] ?? model.hints[Math.min(optionIndex, model.hints.length - 1)]);
    if (!exited) this.openLanguage();
  }

  private openLanguageMinigame(puzzle: GeneratedLanguagePuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("language");
    const session = this.ensureLanguageMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title, puzzle.minigame.reflective
      ? "Italiano · modalità riflessiva: leggi con calma, poi scegli"
      : "Italiano · leggi la consegna, scegli una risposta, conferma");
    const prompt = this.currentLanguageMinigamePrompt(session);
    const remaining = this.languageMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 548, 432, "1 · Leggi e individua la regola");
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

    const isOrdering = prompt.type === "word-order";
    const isTyped = prompt.inputMode === "typed";
    this.addMathPanel(overlay, 604, 112, 648, 432, isOrdering ? "2 · Ricomponi il comando" : isTyped ? "2 · Scrivi la risposta" : "2 · Scegli una risposta");
    overlay.add(this.add.text(636, 154, isOrdering
      ? "Tocca le parole nell'ordine giusto. Ritocca una parola messa per toglierla."
      : isTyped
        ? "Scrivi tu la forma corretta nel riquadro, poi premi Conferma."
        : "Come si gioca: leggi la domanda, clicca UNA tessera e premi Conferma.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 560 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(636, isOrdering ? 192 : 214, prompt.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: isOrdering ? "15px" : "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 560, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    this.languageTypedInputEl = undefined;
    if (isOrdering) {
      this.renderLanguageOrderingTiles(overlay, session, prompt);
    } else if (isTyped) {
      const input = document.createElement("input");
      input.type = "text";
      input.value = session.typedDraft ?? "";
      input.placeholder = "es. sono calibrati";
      input.autocomplete = "off";
      input.spellcheck = false;
      input.style.width = "520px";
      input.style.height = "52px";
      input.style.padding = "0 16px";
      input.style.fontSize = "22px";
      input.style.fontFamily = "Inter, Arial";
      input.style.color = "#f5fbff";
      input.style.background = "#08131c";
      input.style.border = "2px solid #6be7d6";
      input.style.borderRadius = "8px";
      input.style.outline = "none";
      input.oninput = () => { if (this.languageMinigameSession) this.languageMinigameSession.typedDraft = input.value; };
      input.onkeydown = (event) => { if (event.key === "Enter") this.confirmLanguageMinigamePrompt(); };
      this.languageTypedInputEl = input;
      overlay.add(this.add.dom(928, 360, input));
      overlay.add(this.add.text(636, 420, "Scrivi con calma: conta numero e genere del soggetto.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#9aaab0",
        wordWrap: { width: 560 },
      }));
    } else {
      const tileStartX = 784;
      const tileStartY = 340;
      prompt.tiles.forEach((tile, index) => {
        const selected = session.selectedIds.has(tile.id);
        const col = index % 2;
        const row = Math.floor(index / 2);
        overlay.add(new Button(this, tileStartX + col * 258, tileStartY + row * 68, `${selected ? "✓ " : ""}${tile.label}`, () => this.toggleLanguageMinigameTile(tile.id), {
          width: 232,
          height: 52,
          fontSize: tile.label.length > 34 ? 10 : tile.label.length > 20 ? 12 : 16,
          wordWrapWidth: 210,
          fill: selected ? 0x174d42 : 0x263743,
          stroke: selected ? 0xf7d37a : 0x6be7d6,
        }));
      });
    }

    this.addMathPanel(overlay, 28, 558, 1224, 130, "3 · Conferma e controlla l'esito");
    this.languageMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 && !puzzle.minigame.reflective ? "#ff8f8f" : "#f7d37a",
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
      wordWrap: { width: 390, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 1080, 640, "Conferma", () => this.confirmLanguageMinigamePrompt(), {
      width: 220,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 820, 640, "Indizio", () => this.useLanguageMinigameHint(), {
      width: 180,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.languageMinigameTimerEvent?.remove(false);
    if (session.startedAt <= 0) session.startedAt = Date.now();
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
    const variant = this.run.retryVariants?.language ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:language:${variant}:${nextExerciseSalt()}`);
    const generator = new LanguageCorruptionGenerator();
    const types = this.isProgressiveMode() ? this.progressiveLanguageSprintTypes(game.type) : [game.type];
    const freshPrompts = types.flatMap((type, index) =>
      generator.generateMinigame(random.fork(`mix-${type}-${index}`), this.run.difficulty, [type]).minigame?.prompts ?? [],
    );
    const variedGame = {
      ...game,
      title: this.isProgressiveMode() ? "Sprint italiano: percorso variato" : game.title,
      instructions: this.isProgressiveMode()
        ? "alterni accordi, verbi, connettivi, intrusi e ordine delle parole: leggi l'obiettivo prima di cliccare."
        : game.instructions,
      prompts: random.shuffle(freshPrompts.length ? freshPrompts : game.prompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })),
    };
    this.languageMinigameSession = {
      puzzleId,
      puzzle,
      game: variedGame,
      startedAt: 0,
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      orderedSelection: [],
      feedback: this.isProgressiveMode()
        ? "Scalata variata: ogni domanda può cambiare scopo. Prima leggi l'obiettivo, poi scegli."
        : "Leggi prima l'obiettivo: accordo, connettivo, intruso o ordine. Poi conferma.",
      locked: false,
      summaryOpen: false,
    };
    return this.languageMinigameSession;
  }

  private progressiveLanguageSprintTypes(baseType: LanguageMinigameType): LanguageMinigameType[] {
    const rotation: LanguageMinigameType[] = ["agreement-sprint", "verb-mastery", "connector-route", "intruder-hunt", "word-order", "lexicon-lab"];
    return [baseType, ...rotation.filter((type) => type !== baseType)];
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

    const accent = prompt.type === "agreement-sprint" ? 0x6be7d6 : prompt.type === "connector-route" ? 0xf6c85f : prompt.type === "verb-mastery" ? 0x70d68a : 0x9f8cff;
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
    } else if (prompt.type === "verb-mastery") {
      overlay.add(this.add.text(x + 44, y + 142, "Verbo -> persona -> modo -> tempo -> valore nella frase", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#9ff5a7",
        fontStyle: "bold",
        wordWrap: { width: width - 88 },
      }));
    } else if (prompt.type === "connector-route") {
      overlay.add(this.add.text(x + 44, y + 142, "Dai un nome al rapporto: causa, contrasto, tempo, condizione o scopo.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f7d37a",
        wordWrap: { width: width - 88 },
      }));
    } else if (prompt.type === "word-order") {
      overlay.add(this.add.text(x + 44, y + 142, "Ordina: soggetto -> verbo -> complementi. Il comando deve restare eseguibile.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#d8c9ff",
        wordWrap: { width: width - 88 },
      }));
    } else if (prompt.type === "lexicon-lab") {
      overlay.add(this.add.text(x + 44, y + 142, "Scegli la parola più precisa: prova, ipotesi, fonte, registro e scopo cambiano il lessico.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#d8c9ff",
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
    this.languageMinigameTimerText?.setColor(remaining <= 10_000 && !session.game.reflective ? "#ff8f8f" : "#f7d37a");
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

  private toggleLanguageOrderTile(tileId: string): void {
    const session = this.languageMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (session.orderedSelection.includes(tileId)) {
      session.orderedSelection = session.orderedSelection.filter((id) => id !== tileId);
    } else {
      session.orderedSelection.push(tileId);
    }
    audioManager.play("click");
    this.openLanguageMinigame(session.puzzle);
  }

  private renderLanguageOrderingTiles(
    overlay: Phaser.GameObjects.Container,
    session: LanguageMinigameSession,
    prompt: LanguageMinigamePrompt,
  ): void {
    const labelOf = (id: string): string => prompt.tiles.find((tile) => tile.id === id)?.label ?? "";
    const assembled = session.orderedSelection.map(labelOf).join(" ");
    overlay.add(this.add.rectangle(636, 228, 588, 56, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
    overlay.add(this.add.text(652, 242, assembled.length > 0 ? assembled : "(tocca le parole qui sotto)", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
      wordWrap: { width: 560 },
      lineSpacing: 3,
    }));

    let tileX = 636;
    let tileY = 306;
    prompt.tiles.forEach((tile) => {
      const placedIndex = session.orderedSelection.indexOf(tile.id);
      const placed = placedIndex >= 0;
      const labelText = placed ? `${placedIndex + 1}. ${tile.label}` : tile.label;
      const tileWidth = Math.max(58, labelText.length * 11 + 22);
      if (tileX + tileWidth > 1228) {
        tileX = 636;
        tileY += 52;
      }
      overlay.add(new Button(this, tileX + tileWidth / 2, tileY + 20, labelText, () => this.toggleLanguageOrderTile(tile.id), {
        width: tileWidth,
        height: 40,
        fontSize: 14,
        fill: placed ? 0x174d42 : 0x263743,
        stroke: placed ? 0xf7d37a : 0x6be7d6,
      }));
      tileX += tileWidth + 10;
    });

    overlay.add(new Button(this, 1150, 528, "Svuota", () => {
      session.orderedSelection = [];
      audioManager.play("cancel");
      this.openLanguageMinigame(session.puzzle);
    }, { width: 110, height: 34, fontSize: 12, fill: 0x3a2525, stroke: 0xf6c85f }));
  }

  private useLanguageMinigameHint(): void {
    const session = this.languageMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentLanguageMinigamePrompt(session);
    const hint = prompt.type === "agreement-sprint"
      ? "Trova il soggetto reale: a volte una frase relativa o un inciso distrae dal verbo corretto."
      : prompt.type === "verb-mastery"
        ? "Cerca parole-spia come ieri, domani, credo che, se, prima che: spesso decidono tempo e modo."
      : prompt.type === "connector-route"
        ? "Chiediti: la seconda parte spiega, contrasta, segue nel tempo o pone una condizione?"
        : prompt.type === "word-order"
          ? "Parti dal soggetto, poi il verbo, poi i complementi; il tempo o la condizione vanno in fondo."
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
    const ordering = prompt.type === "word-order";
    const typed = prompt.inputMode === "typed";
    const solutionDisplay = ordering ? prompt.solutionLabels.join(" ") : prompt.solutionLabels.join(", ");
    let isCorrect: boolean;
    let chosenLabel: string;
    let wrongFeedback: string;
    if (typed) {
      const draft = this.languageTypedInputEl?.value ?? session.typedDraft ?? "";
      if (normalizeTypedAnswer(draft).length === 0) {
        session.feedback = "Scrivi la forma corretta nel riquadro. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openLanguageMinigame(session.puzzle);
        return;
      }
      const accepted = prompt.acceptedAnswers ?? [normalizeTypedAnswer(prompt.solutionLabels[0])];
      isCorrect = accepted.includes(normalizeTypedAnswer(draft));
      chosenLabel = draft.trim();
      wrongFeedback = "La forma scritta non rispetta numero e genere richiesti.";
    } else if (ordering) {
      if (session.orderedSelection.length === 0) {
        session.feedback = "Tocca le parole per comporre il comando. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openLanguageMinigame(session.puzzle);
        return;
      }
      const assembled = session.orderedSelection.map((id) => prompt.tiles.find((tile) => tile.id === id)?.label ?? "");
      chosenLabel = assembled.join(" ");
      isCorrect = assembled.length === prompt.solutionLabels.length
        && assembled.every((word, position) => word === prompt.solutionLabels[position]);
      wrongFeedback = "L'ordine non rende ancora eseguibile il comando.";
    } else {
      if (session.selectedIds.size === 0) {
        session.feedback = "Prima seleziona una tessera. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openLanguageMinigame(session.puzzle);
        return;
      }
      const selected = prompt.tiles.find((tile) => tile.id === [...session.selectedIds][0]);
      isCorrect = Boolean(selected?.isCorrect);
      chosenLabel = selected?.label ?? "nessuna";
      wrongFeedback = selected?.feedback ?? "Scelta non coerente.";
    }
    if (!isCorrect) {
      if (this.isTimedMissionMode()) {
        const message = `${wrongFeedback} Soluzione: ${solutionDisplay}. ${prompt.explanation}`;
        outcomeFeedback.answer(this, false, chosenLabel, solutionDisplay, prompt.explanation);
        this.languageMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      // Allenamento: mostra la soluzione con la spiegazione in un pannello che resta
      // finché lo studente non preme "Continua" (timer in pausa durante la lettura).
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (7 + this.run.difficulty));
      session.feedback = "Leggi la soluzione, poi premi Continua.";
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      const languagePauseStart = Date.now();
      this.languageMinigameTimerEvent?.remove(false);
      // Diagnostic feedback: lead with what THIS wrong choice got wrong (the tile's
      // per-distractor note), not just a generic explanation of the right answer.
      const languageDiagnostic = this.diagnosticWrongExplanation(wrongFeedback, prompt.explanation);
      this.showWrongSolution(chosenLabel, solutionDisplay, languageDiagnostic, () => {
        session.startedAt += Date.now() - languagePauseStart;
        this.advanceLanguageMinigamePrompt(0);
      });
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
    outcomeFeedback.answer(this, true, chosenLabel, solutionDisplay, prompt.explanation);
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceLanguageMinigamePrompt(1900);
  }

  /**
   * Persistent wrong-answer panel: shows the correct solution and its explanation
   * and stays until the student presses "Continua" (it does not fade away). The
   * caller pauses the sprint timer while it is open.
   */
  private showWrongSolution(selectedLabel: string, solution: string, explanation: string, onContinue: () => void): void {
    const modal = this.add.container(0, 0).setDepth(9800);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.62).setInteractive());
    const cx = 640;
    const cy = 322;
    const w = 800;
    const h = 328;
    const left = cx - w / 2 + 34;
    modal.add(this.add.rectangle(cx, cy, w, h, 0x061019, 0.99).setStrokeStyle(3, 0xc94b55, 0.96));
    modal.add(this.add.rectangle(cx - w / 2 + 6, cy, 9, h - 16, 0xc94b55, 1));
    modal.add(this.add.circle(left + 6, cy - h / 2 + 30, 18, 0xc94b55, 0.2).setStrokeStyle(2, 0xc94b55, 1));
    modal.add(this.add.text(left + 6, cy - h / 2 + 29, "!", { fontFamily: "Inter, Arial", fontSize: "20px", color: "#ffb0a8", fontStyle: "bold" }).setOrigin(0.5));
    modal.add(this.add.text(left + 34, cy - h / 2 + 20, "RISPOSTA ERRATA", { fontFamily: "Inter, Arial", fontSize: "20px", color: "#ffb0a8", fontStyle: "bold" }));
    modal.add(this.add.text(left, cy - h / 2 + 58, `Hai scelto: ${selectedLabel}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", wordWrap: { width: w - 78, useAdvancedWrap: true } }));
    modal.add(this.add.text(left, cy - h / 2 + 92, `Risposta corretta: ${solution}`, { fontFamily: "Inter, Arial", fontSize: "17px", color: "#9ff5a7", fontStyle: "bold", wordWrap: { width: w - 78, useAdvancedWrap: true } }));
    modal.add(this.add.text(left, cy - h / 2 + 134, `Perché: ${explanation}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#d9eaf1", wordWrap: { width: w - 78, useAdvancedWrap: true }, lineSpacing: 6 }));
    modal.add(new Button(this, cx, cy + h / 2 - 34, "Ho capito, continua ▸", () => { modal.destroy(true); onContinue(); }, {
      width: 320, height: 52, fill: 0x173b36, stroke: 0x6be7d6, fontSize: 16, soundKey: "confirm",
    }));
  }

  private diagnosticWrongExplanation(wrongFeedback: string | undefined, correctExplanation: string): string {
    const generic = !wrongFeedback
      || /^(Scelta non coerente|Unsafe action|Word order is not correct yet)\.?$/i.test(wrongFeedback.trim());
    if (generic) {
      return correctExplanation;
    }
    return `${wrongFeedback}\nMetodo corretto: ${correctExplanation}`;
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
      session.orderedSelection = [];
      session.typedDraft = "";
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
    if (session.wrong === 0 && session.correct > 0) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(puzzleKindFromId(session.puzzleId)));
    }
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
      this.runWhenActive(1750, () => this.scene.restart());
      return;
    }
    this.runWhenActive(1750, () => this.scene.restart());
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
    if (prompt.type === "verb-mastery") {
      return "Metodo: individua verbo, persona, modo e tempo; poi controlla se il contesto chiede certezza, dubbio, comando o ipotesi.";
    }
    if (prompt.type === "word-order") {
      return "Metodo: soggetto, verbo, complementi; metti tempo o condizione in fondo. Rileggi se suona naturale.";
    }
    return "Metodo: confronta ogni dettaglio con l'obiettivo. Se non aiuta diagnosi, sequenza, fonte o sintesi, è rumore.";
  }

  private openCircuit(): void {
    const puzzle = this.currentCircuitPuzzle();
    if (puzzle.minigame) {
      this.openCircuitMinigame(puzzle);
      return;
    }
    const model = CircuitConsole.fromPuzzle(puzzle);
    const overlay = this.createExerciseScreen(model.title);
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
    overlay.add(this.add.rectangle(48, 132, 800, 76, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.text(66, 146, "Scopo della diagnosi", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(66, 170, `${model.learningPurpose} Domanda: ${model.diagnosticQuestion}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 764, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(868, 132, 278, 76, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.18));
    overlay.add(this.add.text(886, 146, "Concetti osservati", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(886, 170, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 242, useAdvancedWrap: true },
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
      const selectedLabel = [...this.selectedRepairs].map((fault) => repairLabels[fault]).join(", ") || "nessun intervento";
      const correctLabel = puzzle.requiredRepairs.map((fault) => repairLabels[fault]).join(", ");
      if (exact) {
        const explanation = puzzle.requiredRepairs
          .map((fault) => model.explanations[fault] ?? faultLabels[fault])
          .join(" ");
        this.animateCircuitTest(true, () => {
          outcomeFeedback.answer(this, true, selectedLabel, correctLabel, explanation);
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
      this.animateCircuitTest(false, () => {
        outcomeFeedback.answer(this, false, selectedLabel, correctLabel, message);
        this.handleIncorrectAnswer(`${message} ${this.nextPedagogicHint(puzzle, puzzle.hints[0] ?? "Rileggi il tester e collega sintomo a causa.")}`);
      });
    }, { width: 250, height: 52, fill: 0x173b36 }));
  }

  private drawCircuitSidePanel(overlay: Phaser.GameObjects.Container, model: CircuitConsoleModel): void {
    const x = 844;
    const y = 226;
    overlay.add(this.add.rectangle(x, y, 302, 232, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
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
        wordWrap: { width: 266, useAdvancedWrap: true },
        lineSpacing: 5,
      }));
      model.diagnosticPlan.slice(0, 3).forEach((step, index) => {
        const rowY = y + 116 + index * 34;
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
          wordWrap: { width: 226, useAdvancedWrap: true },
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
    model.testerReadings.slice(0, 4).forEach((reading, index) => {
      const rowY = y + 50 + index * 39;
      overlay.add(this.add.rectangle(x + 18, rowY - 4, 266, 34, 0x102533, 0.7).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.14));
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
        wordWrap: { width: 242 },
      }));
    });

    const guide = model.componentGuide.slice(0, 2).map((component) => `${component.label}: ${component.check}`).join("\n");
    overlay.add(this.add.text(x + 18, y + 206, guide, {
      fontFamily: "Inter, Arial",
      fontSize: "9px",
      color: "#9aaab0",
      wordWrap: { width: 266 },
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
    const selectedAnswer = `${this.circuitSymbolAnswer} · ${this.circuitFunctionAnswer}`;
    const correctAnswer = `${challenge.correctSymbol} · ${challenge.correctFunction}`;
    if (symbolOk && functionOk) {
      outcomeFeedback.answer(this, true, selectedAnswer, correctAnswer, challenge.explanation);
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
    outcomeFeedback.answer(this, false, selectedAnswer, correctAnswer, challenge.explanation);
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
    const y = 306;
    const bottomY = 396;
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
      capacitor: { x: 226, y: 424 },
      sensor: { x: 590, y: 424 },
      branchLed: { x: 404, y: 424 },
      relay: { x: 190, y: 426 },
      motor: { x: 350, y: 426 },
      ground: { x: 590, y: 426 },
    };

    overlay.add(this.add.rectangle(48, 226, 776, 232, 0x081823, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.26));
    overlay.add(this.add.text(66, 242, "Schema del giro della corrente", {
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

    drawBatterySymbol(this, overlay, positions.battery, y, 0xf6c85f);
    drawSwitchSymbol(this, overlay, positions.switch, y, activeFaults.has("open-switch") ? 0xffb36b : 0x9ff5e9, !activeFaults.has("open-switch"), !conceptLocked);
    drawResistorSymbol(this, overlay, positions.resistor, y, activeFaults.has("missing-resistor") || activeFaults.has("wrong-resistor-value") ? 0xffb36b : 0x9ff5e9, activeFaults.has("missing-resistor"), !conceptLocked);
    drawLedSymbol(this, overlay, positions.led, y, activeFaults.has("reversed-led") ? 0xffb36b : 0x9ff5e9, activeFaults.has("reversed-led"), lit, !conceptLocked);
    drawReturnSymbol(this, overlay, positions.return, y, activeFaults.has("missing-wire") || activeFaults.has("loose-ground") || activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9);

    [
      { x: positions.battery, code: "Nodo A", label: "Batteria", text: "spinge la corrente dal + al -" },
      { x: positions.switch, code: "Nodo B", label: "Interruttore", text: "chiude o apre il percorso" },
      { x: positions.resistor, code: "Nodo C", label: "Resistenza", text: "protegge il LED limitando la corrente" },
      { x: positions.led, code: "Nodo D", label: "LED", text: "si accende solo nel verso giusto" },
      { x: positions.return, code: "Nodo E", label: "Ritorno", text: "riporta la corrente al -" },
    ].forEach((item, index) => {
      overlay.add(this.add.text(item.x, 346, conceptLocked ? item.code : item.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      if (conceptLocked) {
        overlay.add(this.add.text(item.x, 370, `simbolo ${index + 1}`, {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#9aaab0",
          align: "center",
        }).setOrigin(0.5, 0));
      }
    });

    drawCurrentArrows(this, overlay, lit ? 0x8cffd7 : 0x5c7480, lit ? 0.85 : 0.35, [
      { x: 160, y, rotation: 0 },
      { x: 450, y, rotation: 0 },
      { x: 696, y: 346, rotation: Math.PI / 2 },
      { x: 330, y: bottomY, rotation: Math.PI },
    ]);

    if (puzzle.nodes.includes("capacitor")) {
      drawCapacitorSymbol(this, overlay, 226, 424, activeFaults.has("capacitor-discharged") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("sensor")) {
      drawSensorSymbol(this, overlay, 590, 424, activeFaults.has("sensor-unpowered") || activeFaults.has("disconnected-component") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("branchLed")) {
      drawBranchSymbol(this, overlay, 404, 424, activeFaults.has("parallel-branch-open") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("relay")) {
      drawRelaySymbol(this, overlay, 190, 426, activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("motor")) {
      drawMotorSymbol(this, overlay, 350, 426, activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
    }
    if (puzzle.nodes.includes("ground")) {
      drawGroundSymbol(this, overlay, 590, 426, activeFaults.has("loose-ground") || activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9, !conceptLocked);
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
    if (success) {
      VisualKit.particleBurst(this, 564, 302, "circuit", "success");
    } else {
      VisualKit.shake(this, flash, 6);
    }
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
    if (puzzle.equationLab) {
      this.openEquationLab(puzzle);
      return;
    }
    if (puzzle.graphWorkshop) {
      this.openGraphWorkshop(puzzle);
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
        soundKey: key === "OK" ? "confirm" : key === "C" ? "cancel" : "mathKey",
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
    overlay.add(new Button(this, 1080, 660, "Aiuto mirato", () => this.showMathSupport(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])), {
      width: 220,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  private openEquationLab(puzzle: GeneratedMathPuzzle): void {
    const lab = puzzle.equationLab;
    if (!lab) return;
    const stageIndex = Phaser.Math.Clamp(this.equationLabStageIndex, 0, lab.stages.length - 1);
    const stage = lab.stages[stageIndex];
    const subtitle = lab.degree === 1
      ? "Matematica · equivalenza, operazioni inverse e verifica"
      : "Matematica · coefficienti, discriminante, radici e parabola";
    const overlay = this.createMathOverlay(puzzle.title, subtitle);

    this.addMathPanel(overlay, 28, 112, 700, 442, `Spiegazione grafica · grado ${lab.degree}`);
    overlay.add(this.add.text(60, 154, lab.equation, {
      fontFamily: "Georgia, 'Times New Roman', serif",
      fontSize: "34px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(60, 202, lab.principle, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 632, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    this.drawEquationLabVisual(overlay, puzzle, stage.visual, 60, 274, 636, 246);

    this.addMathPanel(overlay, 752, 112, 500, 442, stage.title);
    overlay.add(this.add.text(784, 158, stage.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 436, useAdvancedWrap: true },
      lineSpacing: 5,
    }));
    overlay.add(this.add.text(784, 244, `Passaggio ${stageIndex + 1} di ${lab.stages.length}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const optionStartY = 300;
    stage.options.forEach((option, index) => {
      overlay.add(new Button(this, 1002, optionStartY + index * 58, option, () => {
        this.answerEquationLabStage(puzzle, option);
      }, {
        width: 430,
        height: 48,
        fontSize: option.length > 48 ? 10 : option.length > 30 ? 11 : 13,
        wordWrapWidth: 396,
        fill: 0x263743,
      }));
    });

    this.addMathPanel(overlay, 28, 572, 1224, 116, "Percorso e metodo");
    const progressWidth = 650;
    const stepGap = progressWidth / Math.max(1, lab.stages.length - 1);
    const progress = this.add.graphics();
    progress.lineStyle(4, 0x315766, 0.72);
    progress.lineBetween(72, 626, 72 + progressWidth, 626);
    if (stageIndex > 0) {
      progress.lineStyle(4, 0x6be7d6, 0.9);
      progress.lineBetween(72, 626, 72 + stepGap * stageIndex, 626);
    }
    overlay.add(progress);
    lab.stages.forEach((item, index) => {
      const x = 72 + stepGap * index;
      const completed = index < stageIndex;
      const active = index === stageIndex;
      overlay.add(this.add.circle(x, 626, active ? 13 : 10, completed ? 0x2ed889 : active ? 0xf6c85f : 0x315766, 0.96)
        .setStrokeStyle(2, active ? 0xf5fbff : 0x6be7d6, active ? 0.9 : 0.38));
      overlay.add(this.add.text(x, 650, `${index + 1}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: active ? "#f7d37a" : "#c7dce7",
        fontStyle: "bold",
      }).setOrigin(0.5));
    });
    overlay.add(this.add.text(760, 604, this.currentActiveHint() ?? `Metodo: ${puzzle.calculationAid?.strategy ?? puzzle.hints[0]}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.currentActiveHint() ? "#f7d37a" : "#d9eaf1",
      wordWrap: { width: 246, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
    overlay.add(new Button(this, 1128, 632, "Spiega il passaggio", () => {
      if (this.currentActiveHint() === stage.explanation) {
        feedbackSystem.publish(`Spiegazione già attiva: ${stage.explanation}`, "hint");
      } else {
        this.useHint(stage.explanation);
      }
      this.openEquationLab(puzzle);
    }, { width: 202, height: 42, fontSize: 12, fill: 0x263743 }));
  }

  private answerEquationLabStage(puzzle: GeneratedMathPuzzle, option: string): void {
    const lab = puzzle.equationLab;
    if (!lab) return;
    const stage = lab.stages[this.equationLabStageIndex];
    if (!stage) return;
    if (option !== stage.correctOption) {
      outcomeFeedback.answer(this, false, option, stage.correctOption, stage.explanation);
      const exited = this.handleIncorrectAnswer(`Passaggio da rivedere. ${stage.explanation}`);
      if (!exited) this.openEquationLab(puzzle);
      return;
    }
    outcomeFeedback.answer(this, true, option, stage.correctOption, stage.explanation);
    if (this.equationLabStageIndex >= lab.stages.length - 1) {
      this.equationLabStageIndex = 0;
      this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
      return;
    }
    this.equationLabStageIndex += 1;
    this.activeHintText = undefined;
    this.activeHintPuzzleId = undefined;
    audioManager.play("progressiveStep");
    feedbackSystem.publish(`Passaggio corretto. ${stage.explanation}`, "success");
    this.runWhenActive(1900, () => this.openEquationLab(puzzle));
  }

  private drawEquationLabVisual(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    visual: EquationLabVisual,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const lab = puzzle.equationLab;
    if (!lab) return;
    overlay.add(this.add.rectangle(x, y, width, height, 0x06131c, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.28));
    if (visual === "balance") {
      this.drawEquationBalance(overlay, lab.equation, x, y, width, height);
      return;
    }
    if (visual === "inverse-steps" || visual === "substitution") {
      this.drawEquationSteps(overlay, puzzle, visual, x, y, width, height);
      return;
    }
    if (visual === "parabola") {
      this.drawEquationParabola(overlay, puzzle, x, y, width, height);
      return;
    }
    this.drawQuadraticConcept(overlay, puzzle, visual, x, y, width, height);
  }

  private drawEquationBalance(
    overlay: Phaser.GameObjects.Container,
    equation: string,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const centerX = x + width / 2;
    const beamY = y + 116;
    const g = this.add.graphics();
    g.lineStyle(7, 0xf6c85f, 0.82);
    g.lineBetween(centerX - 218, beamY, centerX + 218, beamY);
    g.lineStyle(4, 0x6be7d6, 0.72);
    g.lineBetween(centerX, beamY, centerX, beamY + 76);
    g.lineBetween(centerX - 46, beamY + 92, centerX + 46, beamY + 92);
    g.lineBetween(centerX - 170, beamY, centerX - 200, beamY + 54);
    g.lineBetween(centerX + 170, beamY, centerX + 200, beamY + 54);
    overlay.add(g);
    overlay.add(this.add.rectangle(centerX - 200, beamY + 66, 250, 72, 0x102533, 0.94).setStrokeStyle(2, 0x6be7d6, 0.46));
    overlay.add(this.add.rectangle(centerX + 200, beamY + 66, 250, 72, 0x102533, 0.94).setStrokeStyle(2, 0x6be7d6, 0.46));
    const sides = equation.split("=");
    overlay.add(this.add.text(centerX - 200, beamY + 66, sides[0]?.trim() ?? equation, {
      fontFamily: "Georgia, serif", fontSize: "23px", color: "#f5fbff", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(centerX + 200, beamY + 66, sides[1]?.trim() ?? "", {
      fontFamily: "Georgia, serif", fontSize: "23px", color: "#f5fbff", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(centerX, y + 20, "Stessa operazione a sinistra e a destra", {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));
  }

  private drawEquationSteps(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    visual: EquationLabVisual,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const steps = puzzle.solutionSteps?.slice(0, 4) ?? [];
    const visible = visual === "substitution" ? [steps[steps.length - 1] ?? puzzle.equationLab?.verification ?? "Verifica"] : steps;
    const startY = visual === "substitution" ? y + 96 : y + 54;
    visible.forEach((step, index) => {
      const rowY = startY + index * 52;
      overlay.add(this.add.rectangle(x + 38, rowY, width - 76, 40, index === visible.length - 1 ? 0x173b36 : 0x102533, 0.9)
        .setOrigin(0, 0.5)
        .setStrokeStyle(1, index === visible.length - 1 ? 0xf6c85f : 0x6be7d6, 0.36));
      overlay.add(this.add.text(x + 58, rowY, step, {
        fontFamily: "Georgia, serif",
        fontSize: "16px",
        color: "#f5fbff",
        wordWrap: { width: width - 116 },
      }).setOrigin(0, 0.5));
      if (index < visible.length - 1) {
        overlay.add(this.add.triangle(x + width / 2, rowY + 30, 0, -4, 9, 5, -9, 5, 0x6be7d6, 0.68));
      }
    });
    if (visual === "substitution") {
      overlay.add(this.add.text(x + width / 2, y + 40, "Una soluzione è valida solo se rende veri entrambi i membri.", {
        fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold",
      }).setOrigin(0.5));
    }
  }

  private drawQuadraticConcept(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    visual: EquationLabVisual,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const lab = puzzle.equationLab;
    if (!lab) return;
    const { a, b, c } = lab.coefficients;
    if (visual === "standard-form") {
      [
        { label: "a · x²", value: `${a}x²`, color: 0x6be7d6 },
        { label: "b · x", value: `${b}x`, color: 0xf6c85f },
        { label: "c", value: `${c}`, color: 0x9f8cff },
      ].forEach((item, index) => {
        const cx = x + 114 + index * 204;
        overlay.add(this.add.rectangle(cx, y + 120, 164, 112, 0x102533, 0.92).setStrokeStyle(2, item.color, 0.62));
        overlay.add(this.add.text(cx, y + 92, item.label, {
          fontFamily: "Inter, Arial", fontSize: "13px", color: "#c7dce7",
        }).setOrigin(0.5));
        overlay.add(this.add.text(cx, y + 132, item.value, {
          fontFamily: "Georgia, serif", fontSize: "25px", color: "#f5fbff", fontStyle: "bold",
        }).setOrigin(0.5));
      });
      return;
    }
    if (visual === "discriminant") {
      const delta = lab.discriminant ?? 0;
      const parts = [`b²`, `− 4ac`, `Δ`];
      const values = [`(${b})² = ${b * b}`, `− 4·${a}·${c} = ${-4 * a * c}`, `${delta}`];
      parts.forEach((label, index) => {
        const cx = x + 112 + index * 206;
        overlay.add(this.add.rectangle(cx, y + 118, 172, 108, index === 2 ? 0x173b36 : 0x102533, 0.92)
          .setStrokeStyle(2, index === 2 ? 0xf6c85f : 0x6be7d6, 0.58));
        overlay.add(this.add.text(cx, y + 88, label, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
        overlay.add(this.add.text(cx, y + 132, values[index], { fontFamily: "Georgia, serif", fontSize: index === 2 ? "28px" : "17px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
      });
      return;
    }
    overlay.add(this.add.text(x + width / 2, y + 52, "Formula risolutiva", {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(x + width / 2, y + 116, "x =  (−b ± √Δ) / 2a", {
      fontFamily: "Georgia, serif", fontSize: "30px", color: "#f7d37a", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(x + width / 2, y + 174, lab.roots.length > 0
      ? `Soluzioni: ${lab.roots.map((root, index) => `x${lab.roots.length > 1 ? index + 1 : ""} = ${root}`).join("    ")}`
      : "Δ < 0: la radice quadrata non è reale", {
      fontFamily: "Inter, Arial", fontSize: "17px", color: "#f5fbff", fontStyle: "bold",
    }).setOrigin(0.5));
  }

  private drawEquationParabola(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const lab = puzzle.equationLab;
    if (!lab) return;
    const { a, b, c } = lab.coefficients;
    const roots = lab.roots;
    const vertexX = -b / (2 * a);
    const minX = Math.floor(Math.min(-2, vertexX - 5, ...(roots.length ? roots.map((root) => root - 2) : [0])));
    const maxX = Math.ceil(Math.max(6, vertexX + 5, ...(roots.length ? roots.map((root) => root + 2) : [4])));
    const samples = Array.from({ length: 81 }, (_, index) => minX + ((maxX - minX) * index) / 80);
    const values = samples.map((value) => a * value * value + b * value + c);
    const maxAbsY = Math.max(8, ...values.map((value) => Math.abs(value)));
    const graphLeft = x + 52;
    const graphRight = x + width - 34;
    const graphTop = y + 28;
    const graphBottom = y + height - 38;
    const mapX = (value: number) => graphLeft + ((value - minX) / (maxX - minX)) * (graphRight - graphLeft);
    const mapY = (value: number) => (graphTop + graphBottom) / 2 - (value / maxAbsY) * ((graphBottom - graphTop) * 0.46);
    const g = this.add.graphics();
    g.lineStyle(2, 0x6b7d84, 0.62);
    g.lineBetween(graphLeft, mapY(0), graphRight, mapY(0));
    if (minX <= 0 && maxX >= 0) g.lineBetween(mapX(0), graphTop, mapX(0), graphBottom);
    g.lineStyle(3, 0x6be7d6, 0.88);
    g.beginPath();
    samples.forEach((value, index) => {
      const px = mapX(value);
      const py = mapY(values[index]);
      if (index === 0) g.moveTo(px, py);
      else g.lineTo(px, py);
    });
    g.strokePath();
    overlay.add(g);
    roots.forEach((root) => {
      overlay.add(this.add.circle(mapX(root), mapY(0), 8, 0xf6c85f, 1).setStrokeStyle(2, 0xf5fbff, 0.8));
      overlay.add(this.add.text(mapX(root), mapY(0) + 16, `${root}`, {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", fontStyle: "bold",
      }).setOrigin(0.5, 0));
    });
    overlay.add(this.add.text(x + 18, y + 12, roots.length === 2
      ? "Due intersezioni con l'asse x"
      : roots.length === 1
        ? "Una tangenza con l'asse x"
        : "Nessuna intersezione con l'asse x", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold",
    }));
  }

  private openGraphWorkshop(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    this.ensureGraphWorkshopState(puzzle);
    const overlay = this.createMathOverlay(
      puzzle.title,
      "Officina dei Grafici · modifica i parametri, osserva la trasformazione, certifica le proprietà",
    );
    const values = this.graphWorkshopValues;

    this.addMathPanel(overlay, 28, 112, 840, 488, "Piano cartesiano interattivo");
    this.drawCartesianWorkshop(overlay, workshop, values, 52, 154, 792, 414);

    this.addMathPanel(overlay, 892, 112, 360, 488, "Console dei parametri");
    overlay.add(this.add.text(920, 154, workshop.objective, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 304, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(920, 220, 304, 48, 0x06131c, 0.9).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.36));
    overlay.add(this.add.text(1072, 244, this.graphWorkshopFormula(workshop, values), {
      fontFamily: "Georgia, 'Times New Roman', serif",
      fontSize: "20px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
    const matchedParameters = workshop.parameters.filter((parameter) => values[parameter.key] === parameter.target).length;
    const syncRatio = matchedParameters / workshop.parameters.length;
    overlay.add(this.add.text(920, 280, `Sincronizzazione ${Math.round(syncRatio * 100)}%`, {
      fontFamily: "Inter, Arial", fontSize: "11px", color: syncRatio === 1 ? "#9ff5e9" : "#c7dce7", fontStyle: "bold",
    }));
    overlay.add(this.add.rectangle(1072, 304, 304, 10, 0x132835, 0.9).setStrokeStyle(1, 0x6be7d6, 0.22));
    if (syncRatio > 0) {
      overlay.add(this.add.rectangle(920 + 152 * syncRatio, 304, 304 * syncRatio, 10, syncRatio === 1 ? 0x2ed889 : 0xf6c85f, 0.88));
    }

    workshop.parameters.forEach((parameter, index) => {
      const rowY = 352 + index * 72;
      overlay.add(this.add.text(920, rowY - 30, `${parameter.label} · ${parameter.meaning}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9ff5e9",
        wordWrap: { width: 294, useAdvancedWrap: true },
      }));
      overlay.add(new Button(this, 952, rowY + 8, "−", () => this.adjustGraphParameter(puzzle, parameter.key, -parameter.step), {
        width: 54, height: 42, fontSize: 22, fill: 0x263743, soundKey: "mathKey",
      }));
      overlay.add(this.add.rectangle(1072, rowY + 8, 142, 42, 0x102533, 0.94).setStrokeStyle(2, 0x6be7d6, 0.46));
      overlay.add(this.add.text(1072, rowY + 8, `${values[parameter.key] ?? parameter.initial}`, {
        fontFamily: "Inter, Arial", fontSize: "23px", color: "#f5fbff", fontStyle: "bold",
      }).setOrigin(0.5));
      overlay.add(new Button(this, 1192, rowY + 8, "+", () => this.adjustGraphParameter(puzzle, parameter.key, parameter.step), {
        width: 54, height: 42, fontSize: 22, fill: 0x263743, soundKey: "mathKey",
      }));
    });

    const propertyY = workshop.parameters.length === 2 ? 500 : 554;
    overlay.add(this.add.text(920, propertyY, this.graphWorkshopProperties(workshop, values), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c7dce7",
      wordWrap: { width: 304, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    this.addMathPanel(overlay, 28, 614, 1224, 74, "Missione grafica");
    overlay.add(this.add.text(54, 660, this.currentActiveHint() ?? workshop.principle, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.currentActiveHint() ? "#f7d37a" : "#d9eaf1",
      wordWrap: { width: 650, useAdvancedWrap: true },
      lineSpacing: 3,
    }).setOrigin(0, 0.5));
    overlay.add(this.add.text(746, 650, `Mosse: ${this.graphWorkshopMoves} · Par: ${this.graphWorkshopPar(workshop)}`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(new Button(this, 850, 650, "Ripristina", () => this.resetGraphWorkshop(puzzle), {
      width: 142, height: 42, fontSize: 12, fill: 0x263743, soundKey: "reset",
    }));
    overlay.add(new Button(this, 1004, 650, this.hintButtonLabel(puzzle, "Indizio"), () => {
      this.useContextualHint(puzzle);
      this.openGraphWorkshop(puzzle);
    }, { width: 142, height: 42, fontSize: 12, fill: 0x263743 }));
    overlay.add(new Button(this, 1168, 650, "Certifica", () => this.certifyGraphWorkshop(puzzle), {
      width: 150, height: 42, fontSize: 13, fill: 0x173b36, stroke: 0xf6c85f,
    }));
  }

  private ensureGraphWorkshopState(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop || this.graphWorkshopPuzzleId === puzzle.id) return;
    this.graphWorkshopPuzzleId = puzzle.id;
    this.graphWorkshopValues = Object.fromEntries(
      workshop.parameters.map((parameter) => [parameter.key, parameter.initial]),
    ) as Partial<Record<GraphParameterKey, number>>;
    this.graphWorkshopMoves = 0;
  }

  private adjustGraphParameter(puzzle: GeneratedMathPuzzle, key: GraphParameterKey, delta: number): void {
    const parameter = puzzle.graphWorkshop?.parameters.find((item) => item.key === key);
    if (!parameter) return;
    const current = this.graphWorkshopValues[key] ?? parameter.initial;
    let next = Phaser.Math.Clamp(current + delta, parameter.min, parameter.max);
    if (key === "a" && next === 0) {
      next = Phaser.Math.Clamp(next + Math.sign(delta || 1), parameter.min, parameter.max);
    }
    if (next === current) {
      audioManager.playOutcome("hint");
      return;
    }
    this.graphWorkshopValues[key] = next;
    this.graphWorkshopMoves += 1;
    audioManager.play("mathKey");
    this.openGraphWorkshop(puzzle);
  }

  private resetGraphWorkshop(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    this.graphWorkshopValues = Object.fromEntries(
      workshop.parameters.map((parameter) => [parameter.key, parameter.initial]),
    ) as Partial<Record<GraphParameterKey, number>>;
    this.graphWorkshopMoves = 0;
    this.activeHintText = undefined;
    this.activeHintPuzzleId = undefined;
    this.openGraphWorkshop(puzzle);
  }

  private certifyGraphWorkshop(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    const exact = workshop.parameters.every((parameter) => this.graphWorkshopValues[parameter.key] === parameter.target);
    const selected = this.graphWorkshopFormula(workshop, this.graphWorkshopValues);
    if (exact) {
      const par = this.graphWorkshopPar(workshop);
      const rating = this.graphWorkshopMoves <= par
        ? "★★★ calibrazione perfetta"
        : this.graphWorkshopMoves <= par + 3
          ? "★★☆ calibrazione precisa"
          : "★☆☆ grafico corretto";
      outcomeFeedback.answer(this, true, selected, workshop.targetFormula, `${rating}. ${workshop.successExplanation}`);
      feedbackSystem.publish(`Grafico certificato in ${this.graphWorkshopMoves} mosse (par ${par}). ${rating}. ${workshop.successExplanation}`, "success");
      this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
      return;
    }
    const diagnosis = this.graphWorkshopDiagnosis(workshop, this.graphWorkshopValues);
    outcomeFeedback.answer(this, false, selected, "Grafico con tutte le proprietà richieste", diagnosis);
    const exited = this.handleIncorrectAnswer(diagnosis);
    if (!exited) this.openGraphWorkshop(puzzle);
  }

  private graphWorkshopPar(workshop: GeneratedGraphWorkshop): number {
    return workshop.parameters.reduce(
      (total, parameter) => {
        const raw = Math.abs(parameter.target - parameter.initial) / parameter.step;
        const skipsZero = parameter.key === "a" && parameter.target * parameter.initial < 0;
        return total + raw - (skipsZero ? 1 : 0);
      },
      0,
    );
  }

  private graphWorkshopFormula(
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
  ): string {
    if (workshop.functionKind === "linear") {
      const m = values.m ?? 0;
      const q = values.q ?? 0;
      if (m === 0) return `y = ${q}`;
      const slope = m === 0 ? "0" : m === 1 ? "x" : m === -1 ? "−x" : `${m}x`;
      const intercept = q === 0 ? "" : q > 0 ? ` + ${q}` : ` − ${Math.abs(q)}`;
      return `y = ${slope}${intercept}`;
    }
    const a = values.a ?? 1;
    const h = values.h ?? 0;
    const k = values.k ?? 0;
    const leading = a === 1 ? "" : a === -1 ? "−" : `${a}`;
    const horizontal = h === 0 ? "x" : h > 0 ? `(x − ${h})` : `(x + ${Math.abs(h)})`;
    const vertical = k === 0 ? "" : k > 0 ? ` + ${k}` : ` − ${Math.abs(k)}`;
    return `y = ${leading}${horizontal}²${vertical}`;
  }

  private graphWorkshopProperties(
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
  ): string {
    if (workshop.functionKind === "linear") {
      const m = values.m ?? 0;
      const q = values.q ?? 0;
      return `Lettura attuale\n• retta ${m > 0 ? "crescente" : m < 0 ? "decrescente" : "orizzontale"}\n• intercetta asse y: (0, ${q})`;
    }
    const a = values.a ?? 1;
    const h = values.h ?? 0;
    const k = values.k ?? 0;
    const discriminantLike = -k / a;
    const roots = discriminantLike >= 0 ? Math.sqrt(discriminantLike) : undefined;
    const rootText = roots === undefined
      ? "nessuna intersezione reale"
      : Number.isInteger(roots)
        ? `radici: ${h - roots}, ${h + roots}`
        : "intersezioni non intere";
    return `Lettura attuale\n• apertura ${a > 0 ? "verso l'alto" : "verso il basso"}\n• vertice V(${h}, ${k})\n• ${rootText}`;
  }

  private graphWorkshopDiagnosis(
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
  ): string {
    const wrong = workshop.parameters.filter((parameter) => values[parameter.key] !== parameter.target);
    if (workshop.functionKind === "linear") {
      const slopeWrong = wrong.some((parameter) => parameter.key === "m");
      const interceptWrong = wrong.some((parameter) => parameter.key === "q");
      if (slopeWrong && interceptWrong) return "La retta ha ancora inclinazione e altezza errate. Allinea prima la pendenza, poi traslala con q.";
      if (slopeWrong) return "La retta può attraversare un beacon, ma la pendenza non permette di attraversare anche l'altro. Correggi m.";
      if (interceptWrong) return "L'inclinazione è corretta, ma l'intera retta è traslata troppo in alto o in basso. Correggi q.";
    }
    const aWrong = wrong.some((parameter) => parameter.key === "a");
    const hWrong = wrong.some((parameter) => parameter.key === "h");
    const kWrong = wrong.some((parameter) => parameter.key === "k");
    if (hWrong) return "L'asse di simmetria non passa ancora per il punto medio richiesto. Regola h prima degli altri parametri.";
    if (kWrong) return "La posizione orizzontale è coerente, ma il vertice è alla quota sbagliata. Regola k.";
    if (aWrong) return "Vertice e asse sono corretti, ma verso o apertura non coincidono. Regola a.";
    return "Il grafico è vicino al bersaglio, ma non soddisfa ancora tutti i vincoli esatti.";
  }

  private drawCartesianWorkshop(
    overlay: Phaser.GameObjects.Container,
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    overlay.add(this.add.rectangle(x, y, width, height, 0x02090e, 0.94).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.34));
    const [minX, maxX] = workshop.xRange;
    const [minY, maxY] = workshop.yRange;
    const left = x + 48;
    const right = x + width - 24;
    const top = y + 24;
    const bottom = y + height - 42;
    const mapX = (value: number) => left + ((value - minX) / (maxX - minX)) * (right - left);
    const mapY = (value: number) => bottom - ((value - minY) / (maxY - minY)) * (bottom - top);
    const g = this.add.graphics();

    for (let gx = Math.ceil(minX); gx <= Math.floor(maxX); gx += 1) {
      const px = mapX(gx);
      g.lineStyle(gx === 0 ? 3 : 1, gx === 0 ? 0x9ff5e9 : 0x315766, gx === 0 ? 0.68 : 0.28);
      g.lineBetween(px, top, px, bottom);
      if (gx !== 0 && gx % 2 === 0) {
        overlay.add(this.add.text(px, bottom + 10, `${gx}`, {
          fontFamily: "Inter, Arial", fontSize: "9px", color: "#78909b",
        }).setOrigin(0.5));
      }
    }
    for (let gy = Math.ceil(minY); gy <= Math.floor(maxY); gy += 1) {
      const py = mapY(gy);
      g.lineStyle(gy === 0 ? 3 : 1, gy === 0 ? 0x9ff5e9 : 0x315766, gy === 0 ? 0.68 : 0.28);
      g.lineBetween(left, py, right, py);
      if (gy !== 0 && gy % 2 === 0) {
        overlay.add(this.add.text(left - 10, py, `${gy}`, {
          fontFamily: "Inter, Arial", fontSize: "9px", color: "#78909b",
        }).setOrigin(1, 0.5));
      }
    }
    overlay.add(g);
    overlay.add(this.add.text(right + 8, mapY(0), "x", {
      fontFamily: "Georgia, serif", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0, 0.5));
    overlay.add(this.add.text(mapX(0), top - 14, "y", {
      fontFamily: "Georgia, serif", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));

    const targetValues = Object.fromEntries(
      workshop.parameters.map((parameter) => [parameter.key, parameter.target]),
    ) as Partial<Record<GraphParameterKey, number>>;
    if (workshop.showTargetCurve) {
      this.drawWorkshopCurve(overlay, workshop, targetValues, mapX, mapY, minX, maxX, minY, maxY, 0xf6c85f, 0.52, true);
    }
    this.drawWorkshopCurve(overlay, workshop, values, mapX, mapY, minX, maxX, minY, maxY, 0x6be7d6, 0.96, false);

    workshop.targetPoints.forEach((point) => {
      const currentY = this.evaluateWorkshop(workshop, values, point.x);
      const reached = point.label === "V"
        ? (values.h ?? 0) === point.x && (values.k ?? 0) === point.y
        : Math.abs(currentY - point.y) < 0.0001;
      const color = reached ? 0x2ed889 : 0xf6c85f;
      overlay.add(this.add.circle(mapX(point.x), mapY(point.y), 16, color, 0.1).setStrokeStyle(3, color, 0.92));
      overlay.add(this.add.circle(mapX(point.x), mapY(point.y), 5, color, 1));
      overlay.add(this.add.text(mapX(point.x) + 14, mapY(point.y) - 22, `${point.label}(${point.x}, ${point.y})`, {
        fontFamily: "Inter, Arial", fontSize: "11px", color: reached ? "#9ff5e9" : "#f7d37a", fontStyle: "bold",
      }));
    });

    if (workshop.functionKind === "quadratic") {
      const h = values.h ?? 0;
      const k = values.k ?? 0;
      if (h >= minX && h <= maxX && k >= minY && k <= maxY) {
        overlay.add(this.add.circle(mapX(h), mapY(k), 7, 0x9f8cff, 1).setStrokeStyle(2, 0xf5fbff, 0.72));
        overlay.add(this.add.text(mapX(h) + 10, mapY(k) + 8, `V(${h}, ${k})`, {
          fontFamily: "Inter, Arial", fontSize: "10px", color: "#d8c9ff", fontStyle: "bold",
        }));
      }
    }

    overlay.add(this.add.rectangle(x + width - 226, y + 18, 198, workshop.showTargetCurve ? 58 : 38, 0x07151d, 0.84)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.2));
    overlay.add(this.add.text(x + width - 210, y + 28, "— curva attiva", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#9ff5e9",
    }));
    if (workshop.showTargetCurve) {
      overlay.add(this.add.text(x + width - 210, y + 48, "┄ traccia bersaglio", {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a",
      }));
    }
  }

  private drawWorkshopCurve(
    overlay: Phaser.GameObjects.Container,
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
    mapX: (value: number) => number,
    mapY: (value: number) => number,
    minX: number,
    maxX: number,
    minY: number,
    maxY: number,
    color: number,
    alpha: number,
    dashed: boolean,
  ): void {
    const curve = this.add.graphics();
    curve.lineStyle(dashed ? 3 : 4, color, alpha);
    const samples = 180;
    let previous: { x: number; y: number } | undefined;
    for (let index = 0; index <= samples; index += 1) {
      const graphX = minX + ((maxX - minX) * index) / samples;
      const graphY = this.evaluateWorkshop(workshop, values, graphX);
      const inside = graphY >= minY && graphY <= maxY;
      const point = { x: mapX(graphX), y: mapY(graphY) };
      if (inside && previous && (!dashed || Math.floor(index / 5) % 2 === 0)) {
        curve.lineBetween(previous.x, previous.y, point.x, point.y);
      }
      previous = inside ? point : undefined;
    }
    overlay.add(curve);
  }

  private evaluateWorkshop(
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
    x: number,
  ): number {
    if (workshop.functionKind === "linear") {
      return (values.m ?? 0) * x + (values.q ?? 0);
    }
    return (values.a ?? 1) * (x - (values.h ?? 0)) ** 2 + (values.k ?? 0);
  }

  private createMathOverlay(title: string, subtitle = "Matematica · osserva il problema, applica il metodo, verifica"): Phaser.GameObjects.Container {
    this.clearOverlay();
    const overlay = this.add.container(0, 0).setDepth(1200);
    SceneChrome.modalInputBlocker(this, overlay);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02080d, 0.96));
    const backgroundKey = this.textures.exists("mission-bg-math") ? "mission-bg-math" : "bg-lab-painted";
    if (this.textures.exists(backgroundKey)) {
      overlay.add(this.add.image(640, 360, backgroundKey).setDisplaySize(1320, 742).setAlpha(0.32));
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
    overlay.add(this.add.text(38, 68, subtitle, {
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
        outcomeFeedback.answer(this, true, String(enteredValue), String(puzzle.answer), puzzle.solutionSteps?.join(" → "));
        this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
        return;
      }
      this.mathEntry = "";
      this.mathSupportMessage = `Il valore ${Number.isFinite(enteredValue) ? enteredValue : "inserito"} non chiude il terminale. Controlla un passaggio intermedio, non provare numeri a caso. ${this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])}`;
      outcomeFeedback.answer(this, false, Number.isFinite(enteredValue) ? String(enteredValue) : "valore non valido", String(puzzle.answer), puzzle.solutionSteps?.join(" → "));
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
    const overlay = this.createMathOverlay(puzzle.minigame.title, "Matematica · osserva il vincolo, seleziona le tessere, conferma");
    const prompt = this.currentMathMinigamePrompt(session);
    const remaining = this.mathMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 548, 432, "1 · Osserva dati e obiettivo");
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

    this.addMathPanel(overlay, 604, 112, 648, 432, "2 · Seleziona la soluzione");
    overlay.add(this.add.text(636, 156, "Come si gioca: scegli UNA O PIÙ tessere richieste dalla domanda, poi premi Conferma.", {
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

    if (prompt.type === "expression-build") {
      this.renderMathExpressionBuilder(overlay, session, prompt);
    } else {
      const tileStartX = 700;
      const tileStartY = 334;
      prompt.tiles.forEach((tile, index) => {
        const selected = session.selectedIds.has(tile.id);
        const col = index % 3;
        const row = Math.floor(index / 3);
        overlay.add(new Button(this, tileStartX + col * 186, tileStartY + row * 64, `${selected ? "✓ " : ""}${tile.label}`, () => this.toggleMathMinigameTile(tile.id), {
          width: 164,
          height: 48,
          fontSize: tile.label.length > 12 ? 11 : 20,
          wordWrapWidth: 142,
          fill: selected ? 0x174d42 : 0x263743,
          stroke: selected ? 0xf7d37a : 0x6be7d6,
        }));
      });
    }

    this.addMathPanel(overlay, 28, 558, 1224, 130, "3 · Conferma e controlla l'esito");
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
      wordWrap: { width: 390, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 916, 640, "Pulisci scelta", () => this.clearMathMinigameSelection(), {
      width: 174,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1102, 640, "Conferma", () => this.confirmMathMinigamePrompt(), {
      width: 174,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 736, 640, "Indizio", () => this.useMathMinigameHint(), {
      width: 138,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.mathMinigameTimerEvent?.remove(false);
    if (session.startedAt <= 0) session.startedAt = Date.now();
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
    const variant = this.run.retryVariants?.math ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:math:${variant}:${nextExerciseSalt()}`);
    const fresh = new MathPuzzleGenerator().generateMinigame(random, difficultyModel.getPreset(this.run.difficulty), [game.type]).minigame;
    const freshPrompts = fresh?.prompts?.length ? fresh.prompts : game.prompts;
    const variedGame = { ...game, prompts: random.shuffle(freshPrompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })) };
    this.mathMinigameSession = {
      puzzleId,
      puzzle,
      game: variedGame,
      startedAt: 0,
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      orderedSelection: [],
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
    if (prompt.type === "number-sequence") {
      return "Metodo: confronta termini vicini. Cerca una differenza fissa, un rapporto fisso o un passo che cresce.";
    }
    if (prompt.type === "expression-build") {
      return "Metodo: la moltiplicazione si calcola prima di somma e sottrazione. Prova un operatore alla volta verso il bersaglio.";
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
    session.orderedSelection = [];
    session.feedback = "Scelta pulita. Ricomincia dalla regola, non dai pulsanti.";
    this.openMathMinigame(session.puzzle);
  }

  private appendMathOperator(op: string): void {
    const session = this.mathMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentMathMinigamePrompt(session);
    if (session.orderedSelection.length >= prompt.requiredSelectionCount) {
      return;
    }
    session.orderedSelection.push(op);
    audioManager.play("click");
    this.openMathMinigame(session.puzzle);
  }

  private evaluateOperatorInsertion(numbers: number[], operators: string[]): number {
    const values = [...numbers];
    const ops = [...operators];
    for (let i = 0; i < ops.length;) {
      if (ops[i] === "×") {
        values.splice(i, 2, values[i] * values[i + 1]);
        ops.splice(i, 1);
      } else {
        i += 1;
      }
    }
    let result = values[0];
    for (let i = 0; i < ops.length; i += 1) {
      result = ops[i] === "+" ? result + values[i + 1] : result - values[i + 1];
    }
    return result;
  }

  private renderMathExpressionBuilder(
    overlay: Phaser.GameObjects.Container,
    session: MathMinigameSession,
    prompt: MathMinigamePrompt,
  ): void {
    const numbers = prompt.numbers ?? [];
    const ops = session.orderedSelection;
    const parts: string[] = [];
    numbers.forEach((value, position) => {
      parts.push(String(value));
      if (position < numbers.length - 1) {
        parts.push(ops[position] ?? "▢");
      }
    });
    const preview = `${parts.join(" ")}  =  ${ops.length === numbers.length - 1 ? this.evaluateOperatorInsertion(numbers, ops) : "?"}`;
    overlay.add(this.add.rectangle(700, 300, 540, 60, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
    overlay.add(this.add.text(720, 318, preview, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(700, 372, `Bersaglio: ${prompt.target ?? "?"}`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f6c85f",
      fontStyle: "bold",
    }));

    prompt.tiles.forEach((tile, index) => {
      overlay.add(new Button(this, 740 + index * 150, 446, tile.label, () => this.appendMathOperator(tile.label), {
        width: 120,
        height: 64,
        fontSize: 30,
        fill: 0x263743,
        stroke: 0x6be7d6,
      }));
    });
    overlay.add(new Button(this, 1148, 446, "← Cancella", () => {
      session.orderedSelection = session.orderedSelection.slice(0, -1);
      audioManager.play("cancel");
      this.openMathMinigame(session.puzzle);
    }, { width: 150, height: 48, fontSize: 14, fill: 0x3a2525, stroke: 0xf6c85f }));
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
        : prompt.type === "number-sequence"
          ? "Calcola la differenza (o il rapporto) tra termini vicini: la regola spesso si ripete."
          : prompt.type === "expression-build"
            ? "Ricorda che la moltiplicazione si calcola prima di somma e sottrazione: provala per avvicinarti al bersaglio."
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
    let exactSelection: boolean;
    let selectedLabels: string;
    let mathWrongFeedback: string | undefined;
    if (prompt.type === "expression-build") {
      const numbers = prompt.numbers ?? [];
      if (session.orderedSelection.length < prompt.requiredSelectionCount) {
        session.feedback = "Inserisci tutti gli operatori tra i numeri, poi conferma. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openMathMinigame(session.puzzle);
        return;
      }
      const value = this.evaluateOperatorInsertion(numbers, session.orderedSelection);
      selectedLabels = numbers.map((n, i) => i < session.orderedSelection.length ? `${n} ${session.orderedSelection[i]} ` : `${n}`).join("").trim();
      exactSelection = value === (prompt.target ?? NaN);
      if (!exactSelection) {
        mathWrongFeedback = `Con questi operatori ottieni ${value}, ma il bersaglio è ${prompt.target}. Rivedi l'ordine delle operazioni.`;
      }
    } else {
      if (session.selectedIds.size === 0) {
        session.feedback = "Prima scegli una o più tessere, poi conferma. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openMathMinigame(session.puzzle);
        return;
      }
      const correctIds = new Set(prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.id));
      selectedLabels = prompt.tiles
        .filter((tile) => session.selectedIds.has(tile.id))
        .map((tile) => tile.label)
        .join(", ");
      exactSelection = session.selectedIds.size === correctIds.size
        && [...session.selectedIds].every((id) => correctIds.has(id));
      if (!exactSelection) {
        // Diagnose the actual mistake: a wrongly-included tile (with its reason),
        // or a selection that is short/over on the count of correct tiles.
        const wrongIncluded = prompt.tiles.find((tile) => session.selectedIds.has(tile.id) && !tile.isCorrect);
        mathWrongFeedback = wrongIncluded
          ? `Hai incluso «${wrongIncluded.label}»: ${wrongIncluded.feedback}`
          : `Selezione incompleta: servono esattamente le ${correctIds.size} tessere giuste (${prompt.solutionLabels.join(", ")}), né una in più né una in meno.`;
      }
    }
    if (!exactSelection) {
      if (this.isTimedMissionMode()) {
        const message = `Scelta non certificabile (${selectedLabels || "nessuna"}). ${mathWrongFeedback ?? ""} Soluzione: ${prompt.solutionLabels.join(", ")}. ${prompt.explanation}`;
        outcomeFeedback.answer(this, false, selectedLabels || "nessuna", prompt.solutionLabels.join(", "), prompt.explanation);
        this.mathMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      // Allenamento: pannello persistente con soluzione + spiegazione fino a "Continua".
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (8 + this.run.difficulty));
      session.feedback = "Leggi la soluzione, poi premi Continua.";
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      const mathPauseStart = Date.now();
      this.mathMinigameTimerEvent?.remove(false);
      this.showWrongSolution(selectedLabels || "nessuna", prompt.solutionLabels.join(", "), this.diagnosticWrongExplanation(mathWrongFeedback, prompt.explanation), () => {
        session.startedAt += Date.now() - mathPauseStart;
        this.advanceMathMinigamePrompt(0);
      });
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
    outcomeFeedback.answer(this, true, selectedLabels, prompt.solutionLabels.join(", "), prompt.explanation);
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceMathMinigamePrompt(1900);
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
      session.orderedSelection = [];
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
    if (session.wrong === 0 && session.correct > 0) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(puzzleKindFromId(session.puzzleId)));
    }
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
      this.runWhenActive(2200, () => this.scene.restart());
      return;
    }
    this.runWhenActive(2200, () => this.scene.restart());
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
    const overlay = this.createExerciseScreen(puzzle.title);
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
    puzzle.choices.forEach((choice, index) => {
      overlay.add(new Button(this, 866, 402 + index * 50, `${this.englishSelectedChoiceId === choice.id ? "✓ " : ""}${choice.label}`, () => {
        this.englishSelectedChoiceId = choice.id;
        this.openEnglish();
      }, {
        width: 540,
        height: 42,
        fontSize: 13,
        fill: this.englishSelectedChoiceId === choice.id ? 0x174d42 : 0x263743,
        stroke: this.englishSelectedChoiceId === choice.id ? 0xf7d37a : 0x6be7d6,
      }));
    });
    overlay.add(new Button(this, 738, 620, "Conferma risposta", () => {
      this.confirmEnglishReasoning(puzzle);
    }, { width: 240, height: 40, fontSize: 13, fill: 0x173b36, stroke: 0xf7d37a }));
    overlay.add(new Button(this, 1002, 620, this.hintButtonLabel(puzzle, "Indizio mirato"), () => {
      this.useContextualHint(puzzle);
      this.openEnglish();
    }, { width: 230, height: 40, fontSize: 13, fill: 0x263743 }));
  }

  private confirmEnglishReasoning(puzzle: GeneratedEnglishPuzzle): void {
    const choice = puzzle.choices.find((item) => item.id === this.englishSelectedChoiceId);
    if (!choice) {
      audioManager.playOutcome("hint");
      feedbackSystem.publish("Prima seleziona l'azione corretta.", "hint");
      return;
    }
    if (choice.isCorrect) {
      outcomeFeedback.answer(this, true, choice.label, choice.label, puzzle.method);
      this.solvePuzzle(this.currentPuzzleId("english"), puzzle.competencies);
      return;
    }
    this.englishSelectedChoiceId = undefined;
    outcomeFeedback.answer(this, false, choice.label, puzzle.choices.find((item) => item.isCorrect)?.label ?? "Azione corretta", choice.feedback);
    const exited = this.handleIncorrectAnswer(choice.feedback);
    if (!exited) this.openEnglish();
  }

  private openEnglishMinigame(puzzle: GeneratedEnglishPuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("english");
    const session = this.ensureEnglishMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title, "Inglese · decodifica il comando, giustifica col vincolo, conferma");
    const prompt = this.currentEnglishMinigamePrompt(session);
    const remaining = this.englishMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 560, 432, "1 · Leggi il comando operativo");
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

    const isOrdering = prompt.type === "sentence-build";
    const isTranslation = prompt.type === "translation-match";
    this.addMathPanel(overlay, 616, 112, 636, 432, isOrdering ? "2 · Build the sentence" : isTranslation ? "2 · Riconosci la traduzione" : prompt.requiredSelectionCount > 1 ? "2 · Decodifica e prova" : "2 · Scegli un'azione");
    overlay.add(this.add.text(648, 154, isOrdering
      ? "Tocca le parole nell'ordine giusto. Ritocca una parola per toglierla."
      : isTranslation
        ? "Leggi il termine inglese, scegli la traduzione italiana corretta e premi Conferma."
        : prompt.requiredSelectionCount > 1
          ? `Scegli ${prompt.requiredSelectionCount} tessere: il significato operativo e la prova linguistica.`
          : "Come si gioca: trova verbo, oggetto e vincolo; clicca UNA risposta e premi Conferma.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 548 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(648, isOrdering ? 190 : 214, prompt.instruction, {
      fontFamily: "Inter, Arial",
      fontSize: prompt.instruction.length > 92 ? "17px" : "20px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 548, useAdvancedWrap: true },
      lineSpacing: 5,
    }));
    overlay.add(this.add.text(648, isOrdering ? 224 : 290, prompt.glossary.slice(0, 4).map((entry) => `${entry.term}: ${entry.meaning}`).join("   "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 548, useAdvancedWrap: true },
    }));

    if (isOrdering) {
      this.renderEnglishOrderingTiles(overlay, session, prompt);
    } else {
      const multiSelect = prompt.requiredSelectionCount > 1;
      const tileStartX = multiSelect ? 792 : 788;
      const tileStartY = 356;
      const tileWidth = multiSelect ? 274 : 226;
      const colSpacing = multiSelect ? 304 : 252;
      const tileHeight = multiSelect ? 58 : 52;
      prompt.tiles.forEach((tile, index) => {
        const selected = session.selectedIds.has(tile.id);
        const col = index % 2;
        const row = Math.floor(index / 2);
        overlay.add(new Button(this, tileStartX + col * colSpacing, tileStartY + row * 68, `${selected ? "✓ " : ""}${tile.label}`, () => this.toggleEnglishMinigameTile(tile.id), {
          width: tileWidth,
          height: tileHeight,
          fontSize: tile.label.length > 42 ? 11 : tile.label.length > 28 ? 12 : 15,
          wordWrapWidth: tileWidth - 28,
          fill: selected ? 0x174d42 : 0x263743,
          stroke: selected ? 0xf7d37a : 0x6be7d6,
        }));
      });
    }

    this.addMathPanel(overlay, 28, 558, 1224, 130, "3 · Conferma e controlla l'esito");
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
      wordWrap: { width: 390, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 1080, 640, "Conferma", () => this.confirmEnglishMinigamePrompt(), {
      width: 220,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 820, 640, "Indizio", () => this.useEnglishMinigameHint(), {
      width: 180,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.englishMinigameTimerEvent?.remove(false);
    if (session.startedAt <= 0) session.startedAt = Date.now();
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
    const variant = this.run.retryVariants?.english ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:english:${variant}:${nextExerciseSalt()}`);
    const generator = new EnglishInstructionGenerator();
    const types = this.isProgressiveMode() ? this.progressiveEnglishSprintTypes(game.type) : [game.type];
    const freshPrompts = types.flatMap((type, index) =>
      generator.generateMinigame(random.fork(`mix-${type}-${index}`), this.run.difficulty, [type]).minigame?.prompts ?? [],
    );
    const variedGame = {
      ...game,
      title: this.isProgressiveMode() ? "Sprint inglese: percorso variato" : game.title,
      instructions: this.isProgressiveMode()
        ? "alterni azioni, sequenze, dati, grammatica, frase e traduzione: trova prima lo scopo della domanda."
        : game.instructions,
      prompts: random.shuffle(freshPrompts.length ? freshPrompts : game.prompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })),
    };
    this.englishMinigameSession = {
      puzzleId,
      puzzle,
      game: variedGame,
      startedAt: 0,
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      orderedSelection: [],
      feedback: this.isProgressiveMode()
        ? "Scalata variata: ogni comando può chiedere azione, ordine, dato, grammatica o traduzione. Leggi lo scopo prima della risposta."
        : "Leggi il comando come una procedura: action word -> object -> limiter/time word.",
      locked: false,
      summaryOpen: false,
    };
    return this.englishMinigameSession;
  }

  private progressiveEnglishSprintTypes(baseType: EnglishMinigameType): EnglishMinigameType[] {
    const rotation: EnglishMinigameType[] = ["action-relay", "sequence-switchboard", "data-command-scan", "grammar-fix", "sentence-build", "vocab-lab", "translation-match"];
    return [baseType, ...rotation.filter((type) => type !== baseType)];
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
      ? "VERB -> OBJECT -> EVIDENCE"
      : prompt.type === "grammar-fix"
        ? "SIGNAL WORD -> RULE -> FORM"
        : prompt.type === "sentence-build"
          ? "SUBJECT -> VERB -> REST"
          : prompt.type === "vocab-lab"
            ? "CONTEXT -> MEANING -> BEST WORD"
            : prompt.type === "translation-match"
              ? "ENGLISH TERM -> ITALIAN MEANING -> CHECK"
          : "TIME WORD -> FIRST EVENT -> SAFE ACTION";
    overlay.add(this.add.text(x + 42, y + 138, visualLine, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: prompt.type === "action-relay" ? "#9ff5e9" : (prompt.type === "grammar-fix" || prompt.type === "vocab-lab" || prompt.type === "translation-match") ? "#d8c9ff" : "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 84 },
    }));
    overlay.add(this.add.text(x + 42, y + 176, prompt.type === "action-relay"
      ? "Scegli il significato operativo e la prova nel testo: verbo, oggetto e limitatore devono combaciare."
      : prompt.type === "grammar-fix"
        ? "Cerca il segnale grammaticale: tempo, quantità, comparativo, modale o preposizione."
        : prompt.type === "sentence-build"
          ? "Costruisci una frase inglese stabile: ordine naturale, o ausiliare prima del soggetto nelle domande."
          : prompt.type === "vocab-lab"
            ? "Non tradurre a orecchio: scegli la parola che rispetta contesto, registro e significato tecnico."
            : prompt.type === "translation-match"
              ? "Riconosci la traduzione corretta: attenzione ai falsi amici e alle parole troppo simili."
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
    const prompt = this.currentEnglishMinigamePrompt(session);
    if (prompt.requiredSelectionCount <= 1) {
      session.selectedIds.clear();
      session.selectedIds.add(tileId);
    } else if (session.selectedIds.has(tileId)) {
      session.selectedIds.delete(tileId);
    } else {
      if (session.selectedIds.size >= prompt.requiredSelectionCount) {
        session.selectedIds.delete([...session.selectedIds][0]);
      }
      session.selectedIds.add(tileId);
    }
    audioManager.play("click");
    this.openEnglishMinigame(session.puzzle);
  }

  private toggleEnglishOrderTile(tileId: string): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (session.orderedSelection.includes(tileId)) {
      session.orderedSelection = session.orderedSelection.filter((id) => id !== tileId);
    } else {
      session.orderedSelection.push(tileId);
    }
    audioManager.play("click");
    this.openEnglishMinigame(session.puzzle);
  }

  private renderEnglishOrderingTiles(
    overlay: Phaser.GameObjects.Container,
    session: EnglishMinigameSession,
    prompt: EnglishMinigamePrompt,
  ): void {
    const labelOf = (id: string): string => prompt.tiles.find((tile) => tile.id === id)?.label ?? "";
    const assembled = session.orderedSelection.map(labelOf).join(" ");
    overlay.add(this.add.rectangle(648, 262, 572, 56, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
    overlay.add(this.add.text(664, 276, assembled.length > 0 ? assembled : "(tap the words below)", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
      wordWrap: { width: 544 },
      lineSpacing: 3,
    }));

    let tileX = 648;
    let tileY = 338;
    prompt.tiles.forEach((tile) => {
      const placedIndex = session.orderedSelection.indexOf(tile.id);
      const placed = placedIndex >= 0;
      const labelText = placed ? `${placedIndex + 1}. ${tile.label}` : tile.label;
      const tileWidth = Math.max(56, labelText.length * 11 + 22);
      if (tileX + tileWidth > 1232) {
        tileX = 648;
        tileY += 50;
      }
      overlay.add(new Button(this, tileX + tileWidth / 2, tileY + 20, labelText, () => this.toggleEnglishOrderTile(tile.id), {
        width: tileWidth,
        height: 40,
        fontSize: 14,
        fill: placed ? 0x174d42 : 0x263743,
        stroke: placed ? 0xf7d37a : 0x6be7d6,
      }));
      tileX += tileWidth + 10;
    });

    overlay.add(new Button(this, 1150, 520, "Clear", () => {
      session.orderedSelection = [];
      audioManager.play("cancel");
      this.openEnglishMinigame(session.puzzle);
    }, { width: 110, height: 34, fontSize: 12, fill: 0x3a2525, stroke: 0xf6c85f }));
  }

  private useEnglishMinigameHint(): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentEnglishMinigamePrompt(session);
    const hint = prompt.type === "action-relay"
      ? "Servono due scelte: una dice cosa fare, l'altra cita il vincolo inglese che lo dimostra."
      : prompt.type === "sequence-switchboard"
        ? "Prima traduci la parola-tempo: before = prima, after = dopo, until = aspetta fino a, unless = salvo se."
        : prompt.type === "grammar-fix"
          ? "Trova il segnale nella frase (every day, now, yesterday, than, must, on, any...) e scegli la forma che lo rispetta."
          : prompt.type === "sentence-build"
            ? "Parti dal soggetto, poi il verbo; nelle domande l'ausiliare (do/does/did) va prima del soggetto."
            : prompt.type === "vocab-lab"
              ? "Leggi il contesto: la parola giusta deve rispettare significato tecnico, registro e falsi amici."
              : prompt.type === "translation-match"
                ? "Prima traduci mentalmente il termine inglese, poi elimina le opzioni italiane che sono falsi amici o categorie diverse."
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
    const ordering = prompt.type === "sentence-build";
    const solutionDisplay = ordering ? prompt.solutionLabels.join(" ") : prompt.solutionLabels.join(", ");
    let isCorrect: boolean;
    let chosenLabel: string;
    let wrongFeedback: string;
    if (ordering) {
      if (session.orderedSelection.length === 0) {
        session.feedback = "Tap the words to build the sentence. The timer keeps running.";
        audioManager.playOutcome("hint");
        this.openEnglishMinigame(session.puzzle);
        return;
      }
      const assembled = session.orderedSelection.map((id) => prompt.tiles.find((tile) => tile.id === id)?.label ?? "");
      chosenLabel = assembled.join(" ");
      isCorrect = assembled.length === prompt.solutionLabels.length
        && assembled.every((word, position) => word === prompt.solutionLabels[position]);
      wrongFeedback = "Word order is not correct yet.";
    } else {
      if (session.selectedIds.size === 0) {
        session.feedback = prompt.requiredSelectionCount > 1
          ? `Select ${prompt.requiredSelectionCount} tiles first. The timer keeps running.`
          : "Select one tile first. The timer keeps running.";
        audioManager.playOutcome("hint");
        this.openEnglishMinigame(session.puzzle);
        return;
      }
      if (prompt.requiredSelectionCount > 1 && session.selectedIds.size < prompt.requiredSelectionCount) {
        session.feedback = `Select ${prompt.requiredSelectionCount} tiles: meaning and evidence.`;
        audioManager.playOutcome("hint");
        this.openEnglishMinigame(session.puzzle);
        return;
      }
      const selectedTiles = prompt.tiles.filter((tile) => session.selectedIds.has(tile.id));
      const correctIds = new Set(prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.id));
      isCorrect = selectedTiles.length === correctIds.size
        && selectedTiles.every((tile) => correctIds.has(tile.id));
      chosenLabel = selectedTiles.map((tile) => tile.label).join(" + ") || "no answer";
      wrongFeedback = selectedTiles.find((tile) => !tile.isCorrect)?.feedback ?? "Unsafe action.";
    }
    if (!isCorrect) {
      if (this.isTimedMissionMode()) {
        const message = `${wrongFeedback} Solution: ${solutionDisplay}. ${prompt.explanation}`;
        outcomeFeedback.answer(this, false, chosenLabel, solutionDisplay, prompt.explanation);
        this.englishMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      // Allenamento: pannello persistente con soluzione + spiegazione fino a "Continua".
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (8 + this.run.difficulty));
      session.feedback = "Leggi la soluzione, poi premi Continua.";
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      const englishPauseStart = Date.now();
      this.englishMinigameTimerEvent?.remove(false);
      this.showWrongSolution(chosenLabel, solutionDisplay, this.diagnosticWrongExplanation(wrongFeedback, prompt.explanation), () => {
        session.startedAt += Date.now() - englishPauseStart;
        this.advanceEnglishMinigamePrompt(0);
      });
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
    outcomeFeedback.answer(this, true, chosenLabel, solutionDisplay, prompt.explanation);
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceEnglishMinigamePrompt(1900);
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
      session.orderedSelection = [];
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
    if (session.wrong === 0 && session.correct > 0) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(puzzleKindFromId(session.puzzleId)));
    }
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
      this.runWhenActive(1750, () => this.scene.restart());
      return;
    }
    this.runWhenActive(1750, () => this.scene.restart());
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
    if (prompt.type === "grammar-fix") {
      return "Metodo: trova il segnale (every day, now, yesterday, than, must, on, any) e scegli la forma grammaticale che lo rispetta.";
    }
    if (prompt.type === "sentence-build") {
      return "Metodo: soggetto + verbo + resto; nelle domande l'ausiliare (do/does/did) va prima del soggetto.";
    }
    return "Method: compare data with the threshold. Choose the action only after checking below, above, between or comparative.";
  }

  private openCodingMinigame(puzzle: GeneratedCodingPuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("coding");
    const session = this.ensureCodingMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title, "Coding · simula il codice, scegli il blocco, conferma");
    const prompt = this.currentCodingMinigamePrompt(session);
    const remaining = this.codingMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 582, 432, "1 · Leggi e simula il codice");
    overlay.add(this.add.text(60, 154, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "25px",
      color: "#f7d37a",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    this.drawCodingMinigameCodePanel(overlay, prompt, 60, 206, 522, 228);
    overlay.add(this.add.text(60, 458, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 500 },
    }));
    overlay.add(this.add.text(60, 488, this.codingMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 506, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    const isOrdering = prompt.type === "algorithm-order";
    this.addMathPanel(overlay, 636, 112, 616, 432, isOrdering ? "2 · Ordina i passi" : "2 · Scegli il blocco mancante");
    overlay.add(this.add.text(668, 154, isOrdering
      ? "Tocca i passi nell'ordine giusto. Ritocca un passo per toglierlo."
      : "Come si gioca: segui il codice a sinistra, clicca UNA risposta e premi Conferma.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 532 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(668, isOrdering ? 188 : 210, prompt.question, {
      fontFamily: "Inter, Arial",
      fontSize: prompt.question.length > 92 ? "16px" : "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 532, useAdvancedWrap: true },
      lineSpacing: 5,
    }));
    if (isOrdering) {
      this.renderCodingOrderingTiles(overlay, session, prompt);
    } else {
      overlay.add(this.add.text(668, 288, prompt.methodSteps.join("  ->  "), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
        wordWrap: { width: 532, useAdvancedWrap: true },
      }));
      const tileStartX = 802;
      const tileStartY = 356;
      prompt.tiles.forEach((tile, index) => {
        const selected = session.selectedIds.has(tile.id);
        const col = index % 2;
        const row = Math.floor(index / 2);
        overlay.add(new Button(this, tileStartX + col * 244, tileStartY + row * 68, `${selected ? "✓ " : ""}${tile.label}`, () => this.toggleCodingMinigameTile(tile.id), {
          width: 218,
          height: 52,
          fontSize: tile.label.length > 34 ? 10 : tile.label.length > 22 ? 12 : 15,
          wordWrapWidth: 198,
          fill: selected ? 0x174d42 : 0x263743,
          stroke: selected ? 0xf7d37a : 0x6be7d6,
        }));
      });
    }

    this.addMathPanel(overlay, 28, 558, 1224, 130, "3 · Conferma e controlla l'esito");
    this.codingMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(this.codingMinigameTimerText);
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
      wordWrap: { width: 390, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 1080, 640, "Conferma", () => this.confirmCodingMinigamePrompt(), {
      width: 220,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 820, 640, "Indizio", () => this.useCodingMinigameHint(), {
      width: 180,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.codingMinigameTimerEvent?.remove(false);
    if (session.startedAt <= 0) session.startedAt = Date.now();
    this.codingMinigameTimerEvent = this.time.addEvent({
      delay: 250,
      loop: true,
      callback: () => this.refreshCodingMinigameTimer(),
    });
    this.refreshCodingMinigameTimer();
  }

  private ensureCodingMinigameSession(
    puzzleId: string,
    puzzle: GeneratedCodingPuzzle,
    game: GeneratedCodingMinigame,
  ): CodingMinigameSession {
    if (this.codingMinigameSession?.puzzleId === puzzleId && !this.codingMinigameSession.summaryOpen) {
      return this.codingMinigameSession;
    }
    const variant = this.run.retryVariants?.coding ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:coding:${variant}:${nextExerciseSalt()}`);
    const fresh = new CodingPuzzleGenerator().generateMinigame(random, difficultyModel.getPreset(this.run.difficulty), [game.type]).minigame;
    const freshPrompts = fresh?.prompts?.length ? fresh.prompts : game.prompts;
    const variedGame = { ...game, prompts: random.shuffle(freshPrompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })) };
    this.codingMinigameSession = {
      puzzleId,
      puzzle,
      game: variedGame,
      startedAt: 0,
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      orderedSelection: [],
      feedback: "Prima simula il codice: stato iniziale, trasformazione, risultato. Poi conferma.",
      locked: false,
      summaryOpen: false,
    };
    return this.codingMinigameSession;
  }

  private drawCodingMinigameCodePanel(
    overlay: Phaser.GameObjects.Container,
    prompt: CodingMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const g = this.add.graphics();
    g.fillStyle(0x07151d, 0.84);
    g.fillRoundedRect(x, y, width, height, 12);
    g.lineStyle(2, 0x6be7d6, 0.3);
    g.strokeRoundedRect(x, y, width, height, 12);
    overlay.add(g);
    overlay.add(this.add.text(x + 24, y + 18, prompt.title, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const codeY = y + 52;
    overlay.add(this.add.rectangle(x + 24, codeY, width - 48, Math.min(142, height - 82), 0x0b1f2b, 0.94).setOrigin(0)
      .setStrokeStyle(1, 0x315766, 0.58));
    prompt.codeLines.slice(0, 6).forEach((line, index) => {
      const rowY = codeY + 14 + index * 22;
      overlay.add(this.add.text(x + 40, rowY, String(index + 1).padStart(2, "0"), {
        fontFamily: "Consolas, 'Courier New', monospace",
        fontSize: "11px",
        color: "#6f8793",
      }));
      overlay.add(this.add.text(x + 76, rowY, line, {
        fontFamily: "Consolas, 'Courier New', monospace",
        fontSize: "13px",
        color: line.includes("?") ? "#f7d37a" : "#f5fbff",
        wordWrap: { width: width - 116 },
      }));
    });
  }

  private currentCodingMinigamePrompt(session: CodingMinigameSession): CodingMinigamePrompt {
    return session.game.prompts[session.promptIndex % session.game.prompts.length];
  }

  private codingMinigameElapsedMs(session: CodingMinigameSession): number {
    return Math.max(0, Date.now() - session.startedAt);
  }

  private codingMinigameRemainingMs(session: CodingMinigameSession): number {
    return Math.max(0, session.durationMs - this.codingMinigameElapsedMs(session));
  }

  private refreshCodingMinigameTimer(): void {
    const session = this.codingMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    const remaining = this.codingMinigameRemainingMs(session);
    this.codingMinigameTimerText?.setText(`Tempo: ${formatDuration(remaining)}`);
    this.codingMinigameTimerText?.setColor(remaining <= 10_000 ? "#ff8f8f" : "#f7d37a");
    if (remaining <= 0) {
      this.finishCodingMinigame();
    }
  }

  private toggleCodingMinigameTile(tileId: string): void {
    const session = this.codingMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.selectedIds.add(tileId);
    audioManager.play("click");
    this.openCodingMinigame(session.puzzle);
  }

  private toggleCodingOrderTile(tileId: string): void {
    const session = this.codingMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (session.orderedSelection.includes(tileId)) {
      session.orderedSelection = session.orderedSelection.filter((id) => id !== tileId);
    } else {
      session.orderedSelection.push(tileId);
    }
    audioManager.play("click");
    this.openCodingMinigame(session.puzzle);
  }

  private renderCodingOrderingTiles(
    overlay: Phaser.GameObjects.Container,
    session: CodingMinigameSession,
    prompt: CodingMinigamePrompt,
  ): void {
    const labelOf = (id: string): string => prompt.tiles.find((tile) => tile.id === id)?.label ?? "";
    const assembled = session.orderedSelection.map((id, position) => `${position + 1}. ${labelOf(id)}`).join("\n");
    overlay.add(this.add.rectangle(668, 232, 556, 150, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
    overlay.add(this.add.text(684, 244, assembled.length > 0 ? assembled : "(tocca i passi qui sotto)", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
      wordWrap: { width: 528 },
      lineSpacing: 4,
    }));

    let tileY = 398;
    prompt.tiles.forEach((tile) => {
      const placedIndex = session.orderedSelection.indexOf(tile.id);
      const placed = placedIndex >= 0;
      const labelText = placed ? `${placedIndex + 1}. ${tile.label}` : tile.label;
      overlay.add(new Button(this, 914, tileY, labelText, () => this.toggleCodingOrderTile(tile.id), {
        width: 556,
        height: 32,
        fontSize: 12,
        wordWrapWidth: 528,
        fill: placed ? 0x174d42 : 0x263743,
        stroke: placed ? 0xf7d37a : 0x6be7d6,
      }));
      tileY += 38;
    });

    overlay.add(new Button(this, 1150, 520, "Svuota", () => {
      session.orderedSelection = [];
      audioManager.play("cancel");
      this.openCodingMinigame(session.puzzle);
    }, { width: 110, height: 30, fontSize: 12, fill: 0x3a2525, stroke: 0xf6c85f }));
  }

  private useCodingMinigameHint(): void {
    const session = this.codingMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentCodingMinigamePrompt(session);
    const hint = prompt.type === "sequence-builder"
      ? "Chiediti quale istruzione cambia lo stato verso l'obiettivo senza alterare altre variabili."
      : prompt.type === "state-tracer"
        ? "Fai una mini-tabella: dopo ogni riga scrivi solo i valori cambiati."
        : prompt.type === "binary-bits"
          ? "Ogni bit, da destra, vale 1, 2, 4, 8, 16...: somma le potenze di 2 dove c'è un 1."
          : prompt.type === "logic-gate"
            ? "AND vuole tutti veri; OR almeno uno vero; NOT inverte. Valuta una porta alla volta."
            : prompt.type === "loop-output"
              ? "Esegui il ciclo a mano: scrivi il valore della variabile dopo ogni giro."
              : prompt.type === "conditional-path"
                ? "Controlla le condizioni in ordine: si esegue il primo ramo che risulta vero."
                : prompt.type === "algorithm-order"
                  ? "Parti dall'obiettivo: qual è il primo passo indispensabile? Poi concatena in ordine."
                  : "Nel debug non compensare l'errore: cerca la prima riga che viola il requisito.";
    session.feedback = hint;
    this.useHint(hint);
    this.openCodingMinigame(session.puzzle);
  }

  private confirmCodingMinigamePrompt(): void {
    const session = this.codingMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (this.codingMinigameRemainingMs(session) <= 0) {
      this.finishCodingMinigame();
      return;
    }
    const prompt = this.currentCodingMinigamePrompt(session);
    const ordering = prompt.type === "algorithm-order";
    const solutionDisplay = ordering ? prompt.solutionLabels.join(" → ") : prompt.solutionLabels.join(", ");
    let isCorrect: boolean;
    let chosenLabel: string;
    let wrongFeedback: string;
    if (ordering) {
      if (session.orderedSelection.length === 0) {
        session.feedback = "Tocca i passi per comporre l'algoritmo. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openCodingMinigame(session.puzzle);
        return;
      }
      const assembled = session.orderedSelection.map((id) => prompt.tiles.find((tile) => tile.id === id)?.label ?? "");
      chosenLabel = assembled.join(" → ");
      isCorrect = assembled.length === prompt.solutionLabels.length
        && assembled.every((step, position) => step === prompt.solutionLabels[position]);
      wrongFeedback = "L'ordine dei passi non è ancora corretto.";
    } else {
      if (session.selectedIds.size === 0) {
        session.feedback = "Prima seleziona una tessera. Il timer continua.";
        audioManager.playOutcome("hint");
        this.openCodingMinigame(session.puzzle);
        return;
      }
      const selected = prompt.tiles.find((tile) => tile.id === [...session.selectedIds][0]);
      isCorrect = Boolean(selected?.isCorrect);
      chosenLabel = selected?.label ?? "nessuna";
      wrongFeedback = selected?.feedback ?? "Scelta non coerente.";
    }
    if (!isCorrect) {
      if (this.isTimedMissionMode()) {
        const message = `${wrongFeedback} Soluzione: ${solutionDisplay}. ${prompt.explanation}`;
        outcomeFeedback.answer(this, false, chosenLabel, solutionDisplay, prompt.explanation);
        this.codingMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      // Allenamento: pannello persistente con soluzione + spiegazione fino a "Continua".
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (8 + this.run.difficulty));
      session.feedback = "Leggi la soluzione, poi premi Continua.";
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      const codingPauseStart = Date.now();
      this.codingMinigameTimerEvent?.remove(false);
      this.showWrongSolution(chosenLabel, solutionDisplay, this.diagnosticWrongExplanation(wrongFeedback, prompt.explanation), () => {
        session.startedAt += Date.now() - codingPauseStart;
        this.advanceCodingMinigamePrompt(0);
      });
      return;
    }

    session.answered += 1;
    session.correct += 1;
    session.streak += 1;
    session.bestStreak = Math.max(session.bestStreak, session.streak);
    const award = 10 + this.run.difficulty * 2 + Math.min(12, session.streak * 2);
    session.netScore += award;
    session.feedback = `Corretto: ${prompt.explanation} +${award}`;
    session.locked = true;
    outcomeFeedback.answer(this, true, chosenLabel, solutionDisplay, prompt.explanation);
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceCodingMinigamePrompt(1900);
  }

  private advanceCodingMinigamePrompt(delayMs: number): void {
    const session = this.codingMinigameSession;
    if (!session) {
      return;
    }
    this.runWhenActive(delayMs, () => {
      if (this.codingMinigameSession !== session || session.summaryOpen) {
        return;
      }
      if (this.codingMinigameRemainingMs(session) <= 0) {
        this.finishCodingMinigame();
        return;
      }
      const previous = this.currentCodingMinigamePrompt(session).signature;
      session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      if (this.currentCodingMinigamePrompt(session).signature === previous) {
        session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      }
      session.selectedIds.clear();
      session.orderedSelection = [];
      session.locked = false;
      this.openCodingMinigame(session.puzzle);
    });
  }

  private finishCodingMinigame(): void {
    const session = this.codingMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    session.locked = true;
    session.summaryOpen = true;
    this.codingMinigameTimerEvent?.remove(false);
    this.codingMinigameTimerEvent = undefined;
    audioManager.playOutcome("neutral");
    this.showCodingMinigameSummary(session);
  }

  private codingMinigamePassed(session: CodingMinigameSession): boolean {
    if (!this.isTimedMissionMode()) {
      return true;
    }
    const minCorrect = Math.max(5, Math.min(12, 4 + Math.ceil(this.run.difficulty * 0.75)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    return session.correct >= minCorrect && accuracy >= 0.62 && session.netScore > 0;
  }

  private codingMinigameFeedback(session: CodingMinigameSession): string {
    if (session.answered === 0) {
      return "Nessuna risposta: nel coding devi simulare almeno un programma prima di decidere.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.9 && session.bestStreak >= 8) {
      return "Ottimo controllo mentale: hai seguito stato, sequenza e bug senza tentativi ciechi.";
    }
    if (accuracy >= 0.72) {
      return "Buon tracing: ora prova ad anticipare il risultato usando tabelle più compatte.";
    }
    if (session.wrong >= session.correct) {
      return "Troppi tentativi: rallenta, simula una riga alla volta e scegli solo quando sai spiegare.";
    }
    return "Allenamento utile: punta a serie pulite e correzioni minime.";
  }

  private showCodingMinigameSummary(session: CodingMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const passed = this.codingMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(this.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(this.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(this.add.text(230, 160, passed ? "Sprint coding completato" : "Sprint coding da consolidare", {
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
    modal.add(this.add.text(572, 234, this.codingMinigameFeedback(session), {
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
        ? "La console coding certifica il programma: sequenza, stato e correzione sono coerenti."
        : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
      : "Allenamento registrabile: il voto pesa precisione, velocità, serie corretta e uso degli aiuti.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    modal.add(new Button(this, 612, 506, (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua", () => {
      modal.destroy(true);
      if (!passed && (mode === "mission" || mode === "progressive")) {
        this.loseMissionLife("sprint coding sotto soglia: servono più simulazioni corrette con meno tentativi.");
        return;
      }
      this.completeCodingMinigame(session);
    }, {
      width: 270,
      height: 54,
      fill: passed ? 0x173b36 : 0x263743,
      stroke: passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private completeCodingMinigame(session: CodingMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeCodingMinigameScore(session);
    if (session.wrong === 0 && session.correct > 0) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(puzzleKindFromId(session.puzzleId)));
    }
    saveSystem.markProceduralPuzzleSolved(session.puzzleId);
    competencyTracker.award(session.game.competencies, 8 + this.run.difficulty * 2 + Math.min(12, Math.floor(score.total / 32)));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    this.codingMinigameSession = undefined;
    const solvedNode = puzzleKindFromId(session.puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    feedbackSystem.publish(
      `Sprint coding registrato: ${session.correct} corrette, ${session.wrong} errori, serie ${session.bestStreak}. +${score.total} punti. ${remaining.length > 0 ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.` : "La porta finale è pronta."}`,
      "success",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Console coding stabilizzata: il sistema completo è certificabile.");
      return;
    }
    if (this.isProgressiveMode()) {
      this.runWhenActive(1750, () => this.scene.restart());
      return;
    }
    this.runWhenActive(1750, () => this.scene.restart());
  }

  private finalizeCodingMinigameScore(session: CodingMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
    const completedAt = new Date().toISOString();
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.codingMinigameElapsedMs(session)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    const basePoints = session.correct * (10 + run.difficulty);
    const difficultyBonus = session.correct * run.difficulty * 2;
    const speedBonus = Math.min(100, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 36));
    const focusBonus = run.focus.includes("coding") || run.focus.some((item) => item.startsWith("coding."))
      ? 20 + run.difficulty * 3
      : 0;
    const supportPenalty = (existing?.hintsUsed ?? 0) * 6 + session.wrong * (8 + run.difficulty);
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
      feedback: this.codingMinigameFeedback(session),
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

  private codingMinigameMethodText(prompt: CodingMinigamePrompt): string {
    if (prompt.type === "sequence-builder") {
      return "Metodo: leggi obiettivo e stato attuale; scegli solo il blocco che avvicina al risultato senza effetti collaterali.";
    }
    if (prompt.type === "state-tracer") {
      return "Metodo: usa una tabella mentale. Ogni assegnazione cambia il valore a sinistra dell'uguale.";
    }
    if (prompt.type === "binary-bits") {
      return "Metodo: ogni bit da destra vale 1, 2, 4, 8, 16...; somma le potenze di 2 dove c'è un 1.";
    }
    if (prompt.type === "logic-gate") {
      return "Metodo: valuta una porta alla volta. AND vuole tutti veri, OR almeno uno vero, NOT inverte.";
    }
    if (prompt.type === "loop-output") {
      return "Metodo: esegui il ciclo a mano e scrivi il valore della variabile dopo ogni iterazione.";
    }
    if (prompt.type === "conditional-path") {
      return "Metodo: valuta le condizioni in ordine; si esegue il primo ramo che risulta vero.";
    }
    if (prompt.type === "algorithm-order") {
      return "Metodo: parti dall'obiettivo, scegli il primo passo necessario, poi concatena i passi in ordine.";
    }
    return "Metodo: calcola cosa dovrebbe succedere, poi trova la prima riga che rompe la regola.";
  }

  private openCoding(): void {
    const puzzle = this.currentCodingPuzzle();
    if (puzzle.minigame) {
      this.openCodingMinigame(puzzle);
      return;
    }
    const overlay = this.createExerciseScreen(puzzle.title);

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
          outcomeFeedback.answer(this, true, option, puzzle.correctOption, puzzle.explanation);
          this.solvePuzzle(this.currentPuzzleId("coding"), puzzle.competencies);
          return;
        }
        const optionWhy = puzzle.optionFeedback?.[option];
        outcomeFeedback.answer(this, false, option, puzzle.correctOption, optionWhy ?? puzzle.explanation);
        this.handleIncorrectAnswer(optionWhy
          ? `${optionWhy} Metodo corretto: ${puzzle.methodSteps.join(" -> ")}.`
          : `${puzzle.explanation} La scelta "${option}" non rispetta il metodo: ${puzzle.methodSteps.join(" -> ")}.`);
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
    overlay.add(this.add.text(footerPanel.x + 700, footerPanel.y + 42, this.currentActiveHint() ?? puzzle.hints[0] ?? puzzle.learningPurpose, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 238, useAdvancedWrap: true },
      lineSpacing: 2,
    }));
    overlay.add(new Button(this, footerPanel.x + footerPanel.w - 110, footerPanel.y + 62, this.hintButtonLabel(puzzle, "Indizio"), () => {
      this.useContextualHint(puzzle);
      this.openCoding();
    }, {
      width: 190,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  private openPhysics(): void {
    const puzzle = this.currentPhysicsPuzzle();
    const overlay = this.createExerciseScreen(puzzle.title);

    const leftPanel = { x: 56, y: 104, w: 510, h: 392 };
    const rightPanel = { x: 594, y: 104, w: 550, h: 392 };
    const methodPanel = { x: 56, y: 522, w: 1088, h: 92 };

    overlay.add(this.add.text(56, 74, puzzle.difficultyLabel.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(356, 74, `Tipo: ${this.physicsExerciseLabel(puzzle.exerciseType)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));

    overlay.add(this.add.rectangle(leftPanel.x, leftPanel.y, leftPanel.w, leftPanel.h, 0x07151d, 0.88).setOrigin(0).setStrokeStyle(1, 0x8fd3ff, 0.26));
    overlay.add(this.add.rectangle(rightPanel.x, rightPanel.y, rightPanel.w, rightPanel.h, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.rectangle(methodPanel.x, methodPanel.y, methodPanel.w, methodPanel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.25));

    overlay.add(this.add.text(leftPanel.x + 20, leftPanel.y + 18, "Fenomeno", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(leftPanel.x + 20, leftPanel.y + 42, puzzle.scenario, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: leftPanel.w - 40, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    this.drawPhysicsVisual(overlay, puzzle, leftPanel.x + 24, leftPanel.y + 126, leftPanel.w - 48, 214);
    overlay.add(this.add.text(leftPanel.x + 20, leftPanel.y + leftPanel.h - 42, puzzle.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#8fd3ff",
      wordWrap: { width: leftPanel.w - 40 },
    }));

    overlay.add(this.add.text(rightPanel.x + 20, rightPanel.y + 18, "Domanda", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(rightPanel.x + 20, rightPanel.y + 46, puzzle.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      wordWrap: { width: rightPanel.w - 40, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    puzzle.options.forEach((option, index) => {
      const x = rightPanel.x + rightPanel.w / 2;
      const y = rightPanel.y + 162 + index * 52;
      overlay.add(new Button(this, x, y, option, () => {
        if (option === puzzle.correctOption) {
          outcomeFeedback.answer(this, true, option, puzzle.correctOption, puzzle.explanation);
          this.solvePuzzle(this.currentPuzzleId("physics"), puzzle.competencies);
          return;
        }
        const optionWhy = puzzle.optionFeedback?.[option];
        outcomeFeedback.answer(this, false, option, puzzle.correctOption, optionWhy ?? puzzle.explanation);
        this.handleIncorrectAnswer(optionWhy
          ? `${optionWhy} Metodo corretto: ${puzzle.methodSteps.join(" -> ")}.`
          : `${puzzle.explanation} La scelta "${option}" non rispetta il metodo: ${puzzle.methodSteps.join(" -> ")}.`);
      }, {
        width: rightPanel.w - 72,
        height: 42,
        fontSize: 11,
        wordWrapWidth: rightPanel.w - 114,
      }));
    });

    overlay.add(this.add.text(methodPanel.x + 22, methodPanel.y + 16, "Metodo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(methodPanel.x + 22, methodPanel.y + 40, puzzle.methodSteps.join("  ->  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 638, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(methodPanel.x + 712, methodPanel.y + 16, "Controllo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(methodPanel.x + 712, methodPanel.y + 40, this.currentActiveHint() ?? puzzle.hints[0] ?? puzzle.learningPurpose, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 238, useAdvancedWrap: true },
      lineSpacing: 2,
    }));
    overlay.add(new Button(this, methodPanel.x + methodPanel.w - 100, methodPanel.y + 48, this.hintButtonLabel(puzzle, "Indizio"), () => {
      this.useContextualHint(puzzle);
      this.openPhysics();
    }, {
      width: 178,
      height: 40,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  private drawPhysicsVisual(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedPhysicsPuzzle,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    overlay.add(this.add.rectangle(x, y, width, height, 0x0b1f2b, 0.88).setOrigin(0).setStrokeStyle(1, 0x8fd3ff, 0.34));
    overlay.add(this.add.text(x + 14, y + 12, puzzle.visual.title.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#8fd3ff",
      fontStyle: "bold",
    }));
    const g = this.add.graphics();
    overlay.add(g);
    const cx = x + width / 2;
    const cy = y + height / 2 + 18;
    g.lineStyle(2, 0x8fd3ff, 0.56);

    if (puzzle.visual.kind === "motion-graph") {
      const left = x + 54;
      const bottom = y + height - 42;
      g.lineBetween(left, bottom, x + width - 36, bottom);
      g.lineBetween(left, bottom, left, y + 48);
      const values = puzzle.visual.values ?? [0, 1, 2, 3, 4];
      g.lineStyle(3, 0xf6c85f, 0.86);
      values.forEach((value, index) => {
        const px = left + index * ((width - 106) / Math.max(1, values.length - 1));
        const py = bottom - Math.min(height - 100, value * 11);
        g.fillStyle(0xf6c85f, 0.92);
        g.fillCircle(px, py, 5);
        if (index > 0) {
          const prevValue = values[index - 1];
          const prevX = left + (index - 1) * ((width - 106) / Math.max(1, values.length - 1));
          const prevY = bottom - Math.min(height - 100, prevValue * 11);
          g.lineBetween(prevX, prevY, px, py);
        }
      });
    } else if (puzzle.visual.kind === "force-diagram") {
      g.fillStyle(0x1b3d4e, 0.92);
      g.fillRoundedRect(cx - 44, cy - 26, 88, 52, 6);
      g.lineStyle(4, 0xf6c85f, 0.9);
      g.lineBetween(cx, cy - 30, cx, cy - 82);
      g.lineBetween(cx, cy + 30, cx, cy + 84);
      g.fillTriangle(cx, cy - 88, cx - 8, cy - 72, cx + 8, cy - 72);
      g.fillTriangle(cx, cy + 90, cx - 8, cy + 74, cx + 8, cy + 74);
    } else if (puzzle.visual.kind === "energy-flow" || puzzle.visual.kind === "experiment-steps") {
      puzzle.visual.labels.slice(0, 4).forEach((label, index, labels) => {
        const px = x + 62 + index * ((width - 124) / Math.max(1, labels.length - 1));
        g.fillStyle(index % 2 ? 0x153545 : 0x1f5a51, 0.9);
        g.fillRoundedRect(px - 44, cy - 30, 88, 60, 8);
        if (index < labels.length - 1) {
          g.lineStyle(2, 0xf6c85f, 0.72);
          g.lineBetween(px + 48, cy, px + ((width - 124) / Math.max(1, labels.length - 1)) - 48, cy);
        }
      });
    } else if (puzzle.visual.kind === "wave") {
      g.lineStyle(3, 0x8fd3ff, 0.9);
      const startX = x + 42;
      const midY = cy;
      let prevX = startX;
      let prevY = midY;
      for (let step = 0; step <= 96; step += 1) {
        const px = startX + step * ((width - 84) / 96);
        const py = midY + Math.sin(step / 7) * 42;
        if (step > 0) g.lineBetween(prevX, prevY, px, py);
        prevX = px;
        prevY = py;
      }
    } else if (puzzle.visual.kind === "ray") {
      g.lineStyle(3, 0xf6c85f, 0.9);
      g.lineBetween(x + 58, cy + 44, cx, cy);
      g.lineBetween(cx, cy, x + width - 58, cy - 44);
      g.lineStyle(2, 0x8fd3ff, 0.48);
      g.lineBetween(cx, cy - 76, cx, cy + 76);
      g.strokeCircle(cx, cy, 42);
    } else {
      const values = puzzle.visual.values ?? [1, 2, 3];
      values.slice(0, 4).forEach((value, index) => {
        const barH = Math.min(height - 92, Math.max(24, Number(value) * 18));
        const px = x + 78 + index * 82;
        g.fillStyle(index % 2 ? 0xf6c85f : 0x8fd3ff, 0.62);
        g.fillRoundedRect(px, y + height - 42 - barH, 44, barH, 5);
      });
    }

    puzzle.visual.labels.slice(0, 4).forEach((label, index) => {
      overlay.add(this.add.text(x + 18 + index * 112, y + height - 24, label, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: index % 2 ? "#f7d37a" : "#d9eaf1",
        wordWrap: { width: 104 },
      }));
    });
    if (puzzle.visual.highlight) {
      overlay.add(this.add.text(x + width - 154, y + 12, puzzle.visual.highlight, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: 136 },
      }));
    }
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
    const activeHint = this.currentActiveHint();
    overlay.add(this.add.text(76, 414, activeHint ? "Indizio attivo" : "Come decidere", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const text = activeHint ?? puzzle.diagnosticSteps.slice(0, 3).map((step, index) => `${index + 1}. ${step}`).join("\n");
    overlay.add(this.add.text(76, 440, text, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 470 },
      lineSpacing: 5,
    }));
  }

  private openMusic(): void {
    const puzzleId = this.currentPuzzleId("music");
    const session = this.ensureMusicSession(puzzleId);
    const puzzle = session.current;
    const overlay = this.createExerciseScreen("Osservatorio del Pentagramma");
    this.drawMusicSessionHeader(overlay, puzzle, session);
    this.drawMusicStaff(overlay, puzzle, 350, 328);
    this.drawMusicSupport(overlay, puzzle, session);
    const signature = this.musicPuzzleSignature(puzzle);
    if (this.isAuditoryMusicPuzzle(puzzle) && session.lastAutoPreviewSignature !== signature) {
      session.lastAutoPreviewSignature = signature;
      this.runWhenActive(280, () => {
        if (this.musicSession === session && session.current === puzzle && !session.locked && !session.summaryOpen) {
          this.previewMusicChallenge(puzzle);
        }
      });
    }
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
        this.answerMusicSprint(choice.isCorrect, choice.feedback, choice.label);
      }, {
        width: 218,
        height: 60,
        fontSize: ["note-hunt", "auditory-note"].includes(puzzle.challengeMode ?? "note-hunt") && puzzle.answerMode === "note-name" ? 22 : 14,
        fill: 0x263743,
        hoverFill: 0x23556a,
      }));
    });

    this.addMethodStrip(overlay, 56, 586, 550, "Metodo", puzzle.methodSteps);
    overlay.add(new Button(this, 778, 598, puzzle.audioPrompt?.replayLabel ?? "Ascolta sfida", () => this.previewMusicChallenge(puzzle), {
      width: 220, height: 46, fontSize: 14, fill: 0x173b36,
    }));
    if (puzzle.challengeMode === "interval-jump" && puzzle.secondaryNote) {
      overlay.add(new Button(this, 778, 650, "Nota 1", () => this.playMusicNote(puzzle.noteName, puzzle.octave), {
        width: 104, height: 38, fontSize: 12, fill: 0x263743,
      }));
      overlay.add(new Button(this, 894, 650, "Nota 2", () => this.playMusicNote(puzzle.secondaryNote!.noteName, puzzle.secondaryNote!.octave), {
        width: 104, height: 38, fontSize: 12, fill: 0x263743,
      }));
    } else if (puzzle.challengeMode === "note-hunt" || puzzle.challengeMode === "scale-step") {
      overlay.add(new Button(this, 778, 650, "Suona nota", () => this.playMusicNote(puzzle.noteName, puzzle.octave), {
        width: 220, height: 38, fontSize: 12, fill: 0x263743,
      }));
    }
    overlay.add(new Button(this, 1040, 598, this.hintButtonLabel(puzzle, "Indizio"), () => {
      this.useContextualHint(puzzle);
      this.openMusic();
    }, { width: 240, height: 46, fontSize: 14, fill: 0x263743 }));
  }

  private previewMusicChallenge(puzzle: GeneratedMusicPuzzle): void {
    if ((puzzle.challengeMode === "rhythm-gap" || puzzle.challengeMode === "note-duration") && puzzle.rhythmPattern) {
      audioManager.playToneSequence(puzzle.rhythmPattern.cells.map((cell) => ({
        frequency: cell.missing ? 0 : 740,
        durationMs: Math.max(130, cell.beats * 260),
      })));
      return;
    }
    const tones = [{ note: puzzle.noteName, octave: puzzle.octave }];
    if (puzzle.challengeMode === "interval-jump" && puzzle.secondaryNote) {
      tones.push({ note: puzzle.secondaryNote.noteName, octave: puzzle.secondaryNote.octave });
    }
    audioManager.playToneSequence(tones.map((tone) => ({ frequency: this.musicFrequency(tone.note, tone.octave), durationMs: 480 })));
  }

  private playMusicNote(note: GeneratedMusicPuzzle["noteName"], octave: number): void {
    audioManager.playToneSequence([{ frequency: this.musicFrequency(note, octave), durationMs: 540 }]);
  }

  private isAuditoryMusicPuzzle(puzzle: GeneratedMusicPuzzle): boolean {
    return puzzle.challengeMode === "auditory-note" || puzzle.challengeMode === "auditory-interval" || puzzle.audioPrompt?.hiddenStaff === true;
  }

  private musicFrequency(note: GeneratedMusicPuzzle["noteName"], octave: number): number {
    const semitone = { Do: 0, Re: 2, Mi: 4, Fa: 5, Sol: 7, La: 9, Si: 11 }[note];
    const midi = (octave + 1) * 12 + semitone;
    return 440 * 2 ** ((midi - 69) / 12);
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
    if (this.isAuditoryMusicPuzzle(puzzle)) {
      this.drawMusicListeningBoard(overlay, puzzle, centerX, centerY);
      return;
    }
    if ((puzzle.challengeMode ?? "note-hunt") === "rhythm-gap" && puzzle.rhythmPattern) {
      this.drawMusicRhythmBoard(overlay, puzzle, centerX, centerY);
      return;
    }
    if (puzzle.challengeMode === "note-duration" && puzzle.rhythmPattern) {
      this.drawMusicDurationBoard(overlay, puzzle, centerX, centerY);
      return;
    }
    overlay.add(this.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
    overlay.add(this.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
    overlay.add(this.add.image(centerX, centerY, "soft-glow").setTint(0x6be7d6).setAlpha(0.08).setScale(4.2, 2.2));
    overlay.add(this.add.rectangle(centerX, centerY - 2, 536, 190, 0x02070b, 0.28).setStrokeStyle(1, 0xf7d37a, 0.12));
    overlay.add(this.add.text(centerX - 260, centerY - 142, `${puzzle.challengeMode === "interval-jump" ? "Salto melodico" : puzzle.challengeMode === "scale-step" ? "Gradi della scala" : "Caccia alla nota"} · ${puzzle.clef === "treble" ? "chiave di violino" : "chiave di basso"}`, {
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
    const isInterval = puzzle.challengeMode === "interval-jump" && puzzle.secondaryNote;
    const noteX = isInterval ? centerX + 20 : centerX + 96;
    this.drawPitchNote(overlay, noteX, topY, lineSpacing, puzzle.staffPosition, puzzle.ledgerLines, 0xf5fbff);
    if (isInterval && puzzle.secondaryNote) {
      const secondX = centerX + 178;
      this.drawPitchNote(overlay, secondX, topY, lineSpacing, puzzle.secondaryNote.staffPosition, puzzle.secondaryNote.ledgerLines, 0xf7d37a);
      const arrowY = centerY + 76;
      overlay.add(this.add.rectangle((noteX + secondX) / 2, arrowY, secondX - noteX - 32, 3, 0x6be7d6, 0.76));
      overlay.add(this.add.triangle(secondX - 12, arrowY, 0, -7, 14, 0, 0, 7, 0x6be7d6, 0.9));
      overlay.add(this.add.text(noteX, centerY + 88, "1", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
      overlay.add(this.add.text(secondX, centerY + 88, "2", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    }
    overlay.add(this.add.text(centerX - 260, centerY + 108, [
      isInterval ? "Confronta nota 1 e nota 2" : `Posizione: ${puzzle.staffPosition % 2 === 0 ? "linea" : "spazio"}`,
      isInterval ? "Risposta: direzione + intervallo" : puzzle.ledgerLines.length > 0 ? `Linee addizionali: ${puzzle.ledgerLines.length}` : "Nessuna linea addizionale",
      isInterval ? "Conta i passaggi linea-spazio" : puzzle.answerMode === "note-name" ? "Risposta: nome della nota" : "Risposta: nome nota + ottava",
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

  private drawPitchNote(
    overlay: Phaser.GameObjects.Container,
    x: number,
    topY: number,
    lineSpacing: number,
    staffPosition: number,
    ledgerLines: number[],
    color: number,
  ): void {
    const y = topY + staffPosition * (lineSpacing / 2);
    ledgerLines.forEach((position) => {
      overlay.add(this.add.rectangle(x, topY + position * (lineSpacing / 2), 72, 2, 0xf7d37a, 0.88));
    });
    overlay.add(this.add.ellipse(x, y, 34, 24, color, 1).setRotation(-0.42).setStrokeStyle(2, 0xf7d37a, 0.9));
    overlay.add(this.add.rectangle(x + 18, y - 42, 3, 86, color, 0.94));
  }

  private drawMusicRhythmBoard(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number): void {
    const pattern = puzzle.rhythmPattern!;
    overlay.add(this.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
    overlay.add(this.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
    overlay.add(this.add.text(centerX - 260, centerY - 142, `Battito mancante · battuta da ${pattern.beatsPerMeasure}`, {
      fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9", fontStyle: "bold",
    }));
    overlay.add(this.add.text(centerX - 260, centerY - 108, "Completa la casella ? senza superare la battuta.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1",
    }));
    const gap = Math.min(112, 474 / pattern.cells.length);
    const startX = centerX - ((pattern.cells.length - 1) * gap) / 2;
    pattern.cells.forEach((cell, index) => {
      const x = startX + index * gap;
      overlay.add(this.add.rectangle(x, centerY - 6, gap - 12, 120, cell.missing ? 0x253b46 : 0x102a35, 0.96)
        .setStrokeStyle(2, cell.missing ? 0xf7d37a : 0x6be7d6, 0.8));
      overlay.add(this.add.text(x, centerY - 18, cell.missing ? "?" : cell.label, {
        fontFamily: "Georgia, 'Times New Roman', serif", fontSize: cell.missing ? "48px" : "54px", color: cell.missing ? "#f7d37a" : "#f5fbff", fontStyle: "bold",
      }).setOrigin(0.5));
      overlay.add(this.add.text(x, centerY + 42, cell.missing ? "manca" : `${cell.beats}`, {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#9aaab0",
      }).setOrigin(0.5));
    });
    overlay.add(this.add.text(centerX - 260, centerY + 108, "Legenda: ♪ = ½   ♩ = 1   𝅗𝅥 = 2   𝅝 = 4 battiti", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a",
    }));
    overlay.add(this.add.text(centerX - 260, centerY + 136, `Totale richiesto: ${pattern.beatsPerMeasure} battiti. Somma le figure visibili e trova la differenza.`, {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#9aaab0", wordWrap: { width: 520 },
    }));
  }

  private drawMusicDurationBoard(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number): void {
    const cells = puzzle.rhythmPattern?.cells ?? [];
    overlay.add(this.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
    overlay.add(this.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
    overlay.add(this.add.text(centerX - 260, centerY - 142, "Valore delle figure · durata relativa", {
      fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9", fontStyle: "bold",
    }));
    overlay.add(this.add.text(centerX - 260, centerY - 112, "Più lunga è la barra, più dura la figura.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1",
    }));
    const rowHeight = Math.min(56, 240 / Math.max(1, cells.length));
    const maxBeats = 4;
    cells.forEach((cell, index) => {
      const y = centerY - 70 + index * rowHeight;
      const barWidth = Math.max(28, (cell.beats / maxBeats) * 360);
      overlay.add(this.add.text(centerX - 250, y, cell.label, {
        fontFamily: "Inter, Arial", fontSize: "15px", color: "#f5fbff", fontStyle: "bold",
      }).setOrigin(0, 0.5));
      overlay.add(this.add.rectangle(centerX - 70, y, barWidth, rowHeight - 16, 0x1f5a51, 0.95)
        .setOrigin(0, 0.5).setStrokeStyle(2, 0x6be7d6, 0.8));
      overlay.add(this.add.text(centerX - 70 + barWidth + 10, y, cell.beats === 0.5 ? "½" : `${cell.beats}`, {
        fontFamily: "Inter, Arial", fontSize: "13px", color: "#9aaab0",
      }).setOrigin(0, 0.5));
    });
    overlay.add(this.add.text(centerX - 260, centerY + 128, "Semibreve 4 · Minima 2 · Semiminima 1 · Croma ½ (ogni figura vale metà della precedente).", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", wordWrap: { width: 520 },
    }));
  }

  private drawMusicListeningBoard(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number): void {
    const isInterval = puzzle.challengeMode === "auditory-interval" && puzzle.secondaryNote;
    overlay.add(this.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
    overlay.add(this.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.94).setStrokeStyle(2, 0xf7d37a, 0.34));
    overlay.add(this.add.image(centerX, centerY, "soft-glow").setTint(0xf7d37a).setAlpha(0.1).setScale(4.4, 2.3));
    overlay.add(this.add.text(centerX - 260, centerY - 142, isInterval ? "Ascolto intervallo · pentagramma nascosto" : "Ascolto nota · pentagramma nascosto", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(centerX - 260, centerY - 112, isInterval
      ? "Ascolta le due note: devi riconoscere direzione e distanza del salto."
      : "Ascolta il suono: devi riconoscere il nome della nota senza guardare la posizione.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 520 },
    }));

    const g = this.add.graphics();
    const waveLeft = centerX - 236;
    const waveTop = centerY - 34;
    const waveWidth = 472;
    const centerLine = waveTop + 58;
    g.lineStyle(2, 0x6be7d6, 0.82);
    g.beginPath();
    for (let step = 0; step <= 96; step += 1) {
      const x = waveLeft + (step / 96) * waveWidth;
      const phrase = isInterval && step > 48 ? 1.48 : 1;
      const y = centerLine + Math.sin(step * 0.36 * phrase) * (18 + 6 * Math.sin(step * 0.09));
      if (step === 0) g.moveTo(x, y);
      else g.lineTo(x, y);
    }
    g.strokePath();
    g.lineStyle(1, 0xf7d37a, 0.2);
    for (let guide = 0; guide < 5; guide += 1) {
      const y = waveTop + 8 + guide * 26;
      g.strokeLineShape(new Phaser.Geom.Line(waveLeft, y, waveLeft + waveWidth, y));
    }
    overlay.add(g);

    const badgeY = centerY + 76;
    overlay.add(this.add.rectangle(centerX - 120, badgeY, 190, 54, 0x102a35, 0.94).setStrokeStyle(1, 0x6be7d6, 0.54));
    overlay.add(this.add.text(centerX - 120, badgeY, isInterval ? "1ª nota" : "suono singolo", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (isInterval) {
      overlay.add(this.add.rectangle(centerX + 120, badgeY, 190, 54, 0x102a35, 0.94).setStrokeStyle(1, 0xf7d37a, 0.58));
      overlay.add(this.add.text(centerX + 120, badgeY, "2ª nota", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      overlay.add(this.add.triangle(centerX, badgeY, -10, -7, 12, 0, -10, 7, 0xf7d37a, 0.9));
    }
    overlay.add(this.add.text(centerX - 260, centerY + 126, isInterval
      ? "Metodo: prima direzione (sale/scende), poi ampiezza. Riascolta per confermare, non per tentare."
      : "Metodo: colloca mentalmente l'altezza nella scala Do-Re-Mi-Fa-Sol-La-Si, poi scegli.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 520 },
      lineSpacing: 3,
    }));
  }

  private drawMusicSupport(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, session: MusicTrainingSession): void {
    overlay.add(this.add.rectangle(916, 282, 508, 206, 0x07151d, 0.88).setStrokeStyle(1, 0x6be7d6, 0.24));
    const supportTitle = puzzle.challengeMode === "rhythm-gap"
      ? "2 · Completa la battuta"
      : this.isAuditoryMusicPuzzle(puzzle)
        ? "2 · Ascolta e riconosci"
      : puzzle.challengeMode === "interval-jump"
        ? "2 · Segui il movimento"
        : "2 · Scegli solo dopo aver contato";
    overlay.add(this.add.text(682, 196, supportTitle, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const visibleHint = this.currentActiveHint();
    overlay.add(this.add.text(682, 224, `${puzzle.method}\n\n${visibleHint ? `INDIZIO ATTIVO: ${visibleHint}` : session.feedback || "Non serve correre a caso: rispondi solo quando hai agganciato la chiave e contato linee/spazi."}`, {
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
    const variant = this.run.retryVariants?.music ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:music-drill:${variant}:${nextExerciseSalt()}`);
    const durationMs = this.musicSprintDurationMs(this.run.difficulty);
    const baseMode = basePuzzle.challengeMode ?? "note-hunt";
    const allModes: MusicMinigameType[] = ["note-hunt", "auditory-note", "interval-jump", "auditory-interval", "rhythm-gap", "scale-step", "note-duration"];
    const otherModes = random.shuffle<MusicMinigameType>(allModes.filter((mode) => mode !== baseMode));
    this.musicSession = {
      puzzleId,
      random,
      current: basePuzzle,
      startedAt: 0,
      durationMs,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      recentSignatures: [this.musicPuzzleSignature(basePuzzle)],
      modeRotation: [baseMode, ...otherModes],
      modeIndex: 0,
      feedback: "Tre sfide a rotazione: nota, salto melodico e ritmo. Ragiona prima del clic: la serie premia precisione e varietà.",
      locked: false,
      summaryOpen: false,
      questionStartedAt: 0,
    };
    return this.musicSession;
  }

  private answerMusicSprint(correct: boolean, feedback: string, selectedLabel: string): void {
    const session = this.musicSession;
    const puzzleId = this.currentPuzzleId("music");
    if (!session || session.puzzleId !== puzzleId || session.locked || session.summaryOpen) {
      return;
    }
    session.locked = true;
    const correctLabel = session.current.choices.find((choice) => choice.isCorrect)?.label ?? "soluzione indicata";
    outcomeFeedback.answer(this, correct, selectedLabel, correctLabel, feedback);
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
    this.runWhenActive(correct ? 1900 : 2400, () => this.advanceMusicSprintQuestion(session));
  }

  private advanceMusicSprintQuestion(session: MusicTrainingSession): void {
    if (this.musicSession !== session || session.summaryOpen || session.puzzleId !== this.currentPuzzleId("music")) {
      return;
    }
    session.current = this.nextMusicSprintPuzzle(session);
    this.activeHintText = undefined;
    this.activeHintPuzzleId = undefined;
    session.questionStartedAt = Date.now();
    session.locked = false;
    this.openMusic();
  }

  private nextMusicSprintPuzzle(session: MusicTrainingSession): GeneratedMusicPuzzle {
    const level = Math.min(8, Math.max(1, this.run.difficulty + Math.floor(session.correct / 7))) as DifficultyLevel;
    const previous = this.musicPuzzleSignature(session.current);
    session.modeIndex = (session.modeIndex + 1) % session.modeRotation.length;
    const nextMode = session.modeRotation[session.modeIndex];
    for (let attempt = 0; attempt < 14; attempt += 1) {
      const salt = session.random.integer(0, 999_999);
      const candidate = this.musicGenerator.generate(session.random.fork(`sprint-${session.answered}-${attempt}-${salt}`), level, [nextMode]);
      const signature = this.musicPuzzleSignature(candidate);
      if (signature !== previous && !session.recentSignatures.slice(-2).includes(signature)) {
        session.recentSignatures.push(signature);
        session.recentSignatures = session.recentSignatures.slice(-4);
        return candidate;
      }
    }
    const fallback = this.musicGenerator.generate(session.random.fork(`fallback-${session.answered}`), level, [nextMode]);
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
      puzzle.challengeMode ?? "note-hunt",
      puzzle.clef,
      puzzle.answerMode,
      puzzle.noteName,
      puzzle.octave,
      puzzle.staffPosition,
      puzzle.ledgerLines.join("."),
      puzzle.secondaryNote ? `${puzzle.secondaryNote.noteName}${puzzle.secondaryNote.octave}:${puzzle.secondaryNote.staffPosition}` : "",
      puzzle.rhythmPattern ? `${puzzle.rhythmPattern.beatsPerMeasure}:${puzzle.rhythmPattern.cells.map((cell) => `${cell.beats}${cell.missing ? "?" : ""}`).join("-")}` : "",
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
    const currentSession = this.musicSession;
    if (currentSession && currentSession.startedAt <= 0) {
      currentSession.startedAt = Date.now();
      currentSession.questionStartedAt = currentSession.startedAt;
    }
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
    if (session.wrong === 0 && session.correct > 0) {
      saveSystem.recordMasteryAutonomy("musica");
    }
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
      this.runWhenActive(2200, () => this.scene.restart());
      return;
    }
    this.runWhenActive(2200, () => this.scene.restart());
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
    if (puzzle.challengeMode === "auditory-note") {
      return "Orecchio musicale: ascolta la nota e scegli il nome corretto. Il pentagramma è nascosto per allenare il riconoscimento dal suono.";
    }
    if (puzzle.challengeMode === "auditory-interval") {
      return "Orecchio musicale: ascolta due note in sequenza e scegli se la seconda sale/scende e di quale intervallo.";
    }
    if (puzzle.challengeMode === "interval-jump") {
      return "Salto melodico: la nota 2 sale o scende? Conta la distanza e scegli direzione + intervallo.";
    }
    if (puzzle.challengeMode === "rhythm-gap") {
      return `Battito mancante: completa la battuta da ${puzzle.rhythmPattern?.beatsPerMeasure ?? 4} contando il valore delle figure.`;
    }
    if (puzzle.challengeMode === "scale-step") {
      return "Gradi della scala: leggi la nota mostrata e scegli quella che la segue (o precede) nella scala Do-Re-Mi-Fa-Sol-La-Si.";
    }
    if (puzzle.challengeMode === "note-duration") {
      return "Valore delle figure: confronta le durate delle figure musicali e rispondi alla domanda.";
    }
    if (puzzle.answerMode === "note-name") {
      return "Obiettivo: riconosci il nome della nota il più rapidamente possibile. Guarda la chiave, trova la nota guida e conta linee/spazi.";
    }
    return "Obiettivo: riconosci nome e ottava. Il numero indica il registro: Do4 è il Do centrale; La4 è il La sopra il Do centrale.";
  }

  private musicModeExplanation(puzzle: GeneratedMusicPuzzle): string {
    if (puzzle.challengeMode === "auditory-note") {
      return "Modalità ascolto: il suono sostituisce il pentagramma. Prima colloca l'altezza, poi scegli il nome.";
    }
    if (puzzle.challengeMode === "auditory-interval") {
      return "Modalità intervallo a orecchio: non serve vedere le note; devi percepire direzione e ampiezza del salto.";
    }
    if (puzzle.challengeMode === "interval-jump") {
      return "Modalità melodia: prima stabilisci la direzione, poi conta i gradi includendo nota iniziale e finale.";
    }
    if (puzzle.challengeMode === "rhythm-gap") {
      return "Modalità ritmo: ogni figura occupa una durata; la battuta è completa solo quando la somma coincide con il metro.";
    }
    if (puzzle.challengeMode === "scale-step") {
      return "Modalità scala: la successione dei gradi è Do-Re-Mi-Fa-Sol-La-Si e poi ricomincia. Muoviti di un grado dalla nota mostrata.";
    }
    if (puzzle.challengeMode === "note-duration") {
      return "Modalità durate: ogni figura vale la metà della precedente (semibreve 4, minima 2, semiminima 1, croma ½).";
    }
    if (puzzle.answerMode === "note-name") {
      return "Modalità rapida: conta la posizione e scegli solo il nome della nota. L'ottava verrà allenata nei livelli avanzati.";
    }
    return "Modalità avanzata: stesso nome in registri diversi non basta; controlla anche le linee addizionali per scegliere l'ottava.";
  }

  private musicSolutionLines(puzzle: GeneratedMusicPuzzle): string[] {
    const correct = puzzle.choices.find((choice) => choice.isCorrect)?.label ?? puzzle.noteName;
    if (puzzle.challengeMode === "auditory-note") {
      return [
        `Risposta corretta: ${correct}.`,
        `La nota ascoltata era ${puzzle.noteName}${puzzle.octave}.`,
        "Strategia: confronta mentalmente se il suono è più grave o più acuto rispetto ai riferimenti Do-Re-Mi-Fa-Sol-La-Si.",
        puzzle.method,
      ];
    }
    if (puzzle.challengeMode === "auditory-interval" && puzzle.secondaryNote) {
      return [
        `Risposta corretta: ${correct}.`,
        `Hai ascoltato ${puzzle.noteName}${puzzle.octave} seguito da ${puzzle.secondaryNote.noteName}${puzzle.secondaryNote.octave}.`,
        "Prima riconosci la direzione del secondo suono, poi stima la distanza del salto.",
        puzzle.method,
      ];
    }
    if (puzzle.challengeMode === "rhythm-gap" && puzzle.rhythmPattern) {
      const visible = puzzle.rhythmPattern.beatsPerMeasure - puzzle.rhythmPattern.missingBeats;
      return [
        `Risposta corretta: ${correct}.`,
        `Le figure visibili totalizzano ${visible} battiti.`,
        `${puzzle.rhythmPattern.beatsPerMeasure} - ${visible} = ${puzzle.rhythmPattern.missingBeats}.`,
        "La figura scelta completa la battuta senza superarla.",
      ];
    }
    if (puzzle.challengeMode === "interval-jump" && puzzle.secondaryNote) {
      return [
        `Risposta corretta: ${correct}.`,
        `Prima nota: ${puzzle.noteName}${puzzle.octave}; seconda: ${puzzle.secondaryNote.noteName}${puzzle.secondaryNote.octave}.`,
        "Confronta l'altezza per la direzione e conta i nomi per la distanza.",
        puzzle.method,
      ];
    }
    const correctAny = puzzle.choices.find((choice) => choice.isCorrect)?.label ?? puzzle.noteName;
    if (puzzle.challengeMode === "note-duration") {
      return [
        `Risposta corretta: ${correctAny}.`,
        "Valori: semibreve 4, minima 2, semiminima 1, croma ½ movimento.",
        "Ogni figura dura la metà della precedente.",
        puzzle.method,
      ];
    }
    if (puzzle.challengeMode === "scale-step") {
      return [
        `Risposta corretta: ${correctAny}.`,
        `Nota mostrata: ${puzzle.noteName}.`,
        "Successione dei gradi: Do Re Mi Fa Sol La Si, poi di nuovo Do.",
        puzzle.method,
      ];
    }
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
    modal.add(this.add.text(x + 30, y + 232, this.isTimedMissionMode()
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
      if (this.isTimedMissionMode()) {
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
    const overlay = this.createExerciseScreen(model.title);
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
        this.spawnRobotTrail();
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

  private spawnRobotTrail(): void {
    if (settingsSystem.effectsReduced() || !this.robotSprite || !this.overlay) {
      return;
    }
    const trail = this.add.image(this.robotSprite.x, this.robotSprite.y, "soft-glow")
      .setTint(0x6be7d6)
      .setAlpha(0.4)
      .setScale(0.7);
    this.overlay.add(trail);
    this.tweens.add({
      targets: trail,
      alpha: 0,
      scale: 0.3,
      duration: 320,
      ease: "Sine.easeOut",
      onComplete: () => trail.destroy(),
    });
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
      this.showProgressiveSynthesis(reason);
      return;
    }
    const chapterMissionId = this.run.chapterMissionId;
    const chapterExploreMissionId = this.run.chapterExploreMissionId;
    if (chapterExploreMissionId) {
      audioManager.playOutcome("complete");
      outcomeFeedback.play(this, "complete", "Esplora completata");
      this.noraSay("solve");
      this.playLabRestoredFinale();
      markMissionExplored(chapterExploreMissionId);
      saveSystem.updateProceduralRun({ completedAt: new Date().toISOString() });
      this.run = saveSystem.data.proceduralRun ?? this.run;
      feedbackSystem.publish(
        "Fase Esplora completata: hai visto il metodo senza pressione. Ora la Prova del Capitolo e disponibile nella Storia.",
        "success",
      );
      this.runWhenActive(1500, () => this.scene.start("CampaignScene"));
      return;
    }
    if (chapterMissionId) {
      // Passing the graded trial clears the chapter and unlocks the next one.
      audioManager.playOutcome("complete");
      outcomeFeedback.play(this, "complete", "Prova del Capitolo superata");
      this.noraSay("victory");
      this.playLabRestoredFinale();
      markMissionComplete(chapterMissionId);
      saveSystem.updateProceduralRun({ completedAt: new Date().toISOString() });
      this.run = saveSystem.data.proceduralRun ?? this.run;
      feedbackSystem.publish(
        "Prova del Capitolo superata: tutte le materie battute entro gli errori e il tempo. Capitolo sbloccato!",
        "success",
      );
      this.runWhenActive(1700, () => this.scene.start("CampaignScene"));
      return;
    }
    const mode = proceduralRunRules.modeFor(this.run);
    audioManager.playOutcome("complete");
    outcomeFeedback.play(this, "complete", mode === "training" ? "Allenamento registrato" : "Missione completata");
    if (mode !== "training") {
      this.noraSay("victory");
      this.playLabRestoredFinale();
    }
    missionEngine.completeProceduralMission();
    this.run = saveSystem.data.proceduralRun ?? this.run;
    feedbackSystem.publish(
      mode === "training"
        ? "Allenamento completato. Il diario registra voto, miglior tempo e competenze del focus."
        : "Missione completata. Il diario registra seed, competenze, tempo e vite rimaste.",
      "success",
    );
    this.runWhenActive(mode === "training" ? 900 : 1700, () => this.scene.start("JournalScene"));
  }

  /**
   * Climactic "the lab powers back on" sequence: a warm bloom, expanding rings
   * and ordered sparks across the room — the visible payoff of restoring every
   * system. Lighter (no rings) when effects are reduced.
   */
  private playLabRestoredFinale(): void {
    const reduced = settingsSystem.effectsReduced();
    const bloom = this.add.rectangle(640, 360, 1280, 720, 0x6be7d6, 0).setDepth(940);
    this.tweens.add({
      targets: bloom,
      alpha: { from: 0.28, to: 0 },
      duration: 1200,
      ease: "Sine.easeOut",
      onComplete: () => bloom.destroy(),
    });
    [220, 460, 640, 820, 1060].forEach((x, index) => {
      this.runWhenActive(index * 120, () => VisualKit.particleBurst(this, x, 320, "circuit", "success"));
    });
    if (reduced) {
      return;
    }
    for (let i = 0; i < 3; i += 1) {
      const ring = this.add.circle(640, 360, 40, 0xf6c85f, 0).setStrokeStyle(3, 0xf6c85f, 0.7).setDepth(941);
      this.tweens.add({
        targets: ring,
        scale: 9 + i * 2,
        alpha: { from: 0.7, to: 0 },
        delay: i * 160,
        duration: 900,
        ease: "Sine.easeOut",
        onComplete: () => ring.destroy(),
      });
    }
  }

  private showProgressiveSynthesis(reason: string): void {
    if (this.overlay || !this.isProgressiveMode()) {
      return;
    }
    const level = this.run.progressive?.currentLevel ?? this.run.difficulty;
    const blueprint = progressiveMissionBuilder.blueprintForLevel(level);
    const seedOffset = [...this.run.seed].reduce<number>((sum, char) => sum + char.charCodeAt(0), Number(level));
    const stepIndexes = [0, 1, 2];
    const offset = seedOffset % stepIndexes.length;
    const shuffledIndexes = [...stepIndexes.slice(offset), ...stepIndexes.slice(0, offset)];
    const overlay = this.add.container(0, 0).setDepth(1900);
    SceneChrome.modalInputBlocker(this, overlay, 0, 0, 0x02070b, 0.9);
    overlay.add(this.add.rectangle(640, 360, 900, 560, 0x07151d, 0.98).setStrokeStyle(2, 0xf6c85f, 0.82));
    overlay.add(this.add.text(226, 112, `Porta di sintesi · Livello ${level}/8`, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(226, 162, blueprint.goal, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      wordWrap: { width: 820 },
    }));
    overlay.add(this.add.text(226, 210, blueprint.synthesisPrompt, {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 820 },
      lineSpacing: 5,
    }));
    overlay.add(this.add.rectangle(640, 306, 790, 64, 0x102533, 0.86).setStrokeStyle(1, 0xf6c85f, 0.38));
    overlay.add(this.add.text(254, 288, this.progressiveSynthesisOrder.length > 0
      ? this.progressiveSynthesisOrder.map((index, position) => `${position + 1}. ${blueprint.synthesisSteps[index]}`).join("  →  ")
      : "Costruisci qui la sequenza: scegli i tre passaggi nell'ordine corretto.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: this.progressiveSynthesisOrder.length > 0 ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 760 },
    }));
    const status = this.add.text(226, 528, "La porta valuta una procedura costruita, non il riconoscimento di una frase.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7dce7",
      wordWrap: { width: 820 },
      lineSpacing: 4,
    });
    overlay.add(status);
    let validating = false;
    shuffledIndexes.forEach((stepIndex, index) => {
      const alreadySelected = this.progressiveSynthesisOrder.includes(stepIndex);
      overlay.add(new Button(this, 640, 374 + index * 54, blueprint.synthesisSteps[stepIndex], () => {
        if (validating || alreadySelected) return;
        this.progressiveSynthesisOrder.push(stepIndex);
        this.clearOverlay();
        this.showProgressiveSynthesis(reason);
      }, {
        width: 790,
        height: 42,
        fill: alreadySelected ? 0x174d42 : 0x263743,
        stroke: alreadySelected ? 0xf7d37a : 0x6be7d6,
        fontSize: 14,
        wordWrapWidth: 750,
      }));
    });
    overlay.add(new Button(this, 392, 562, "Azzera ordine", () => {
      if (validating) return;
      this.progressiveSynthesisOrder = [];
      this.clearOverlay();
      this.showProgressiveSynthesis(reason);
    }, { width: 210, height: 42, fill: 0x263743, fontSize: 13 }));
    overlay.add(new Button(this, 824, 562, "Verifica sequenza", () => {
      if (validating) return;
      if (this.progressiveSynthesisOrder.length < blueprint.synthesisSteps.length) {
        status.setColor("#ffb36b").setText("La sequenza è incompleta: usa tutti e tre i passaggi prima della verifica.");
        return;
      }
      const correct = this.progressiveSynthesisOrder.every((step, index) => step === index);
      if (correct) {
        audioManager.playOutcome("complete");
        outcomeFeedback.play(this, "complete", "Sintesi certificata");
        feedbackSystem.publish(blueprint.synthesisExplanation, "success");
        this.progressiveSynthesisOrder = [];
        this.clearOverlay();
        this.completeProgressiveLevel(true, `${reason} ${blueprint.synthesisExplanation}`);
        return;
      }
      this.progressiveSynthesisAttempts += 1;
      validating = true;
      saveSystem.recordLearningMistake("progressive:synthesis-order");
      this.progressiveSynthesisOrder = [];
      audioManager.playOutcome("wrong");
      outcomeFeedback.play(this, "warning", "Ordine da ricostruire");
      if (this.progressiveSynthesisAttempts >= 2) {
        this.clearOverlay();
        this.loseMissionLife(`Sintesi non certificata. ${blueprint.synthesisExplanation}`);
        return;
      }
      status.setColor("#ffb36b").setText(`${blueprint.synthesisExplanation} Ricostruisci l'ordine senza perdere una vita.`);
      this.runWhenActive(1200, () => {
        if (!this.overlay) return;
        this.clearOverlay();
        this.showProgressiveSynthesis(reason);
      });
    }, { width: 260, height: 42, fill: 0x173b36, stroke: 0xf6c85f, fontSize: 14 }));
    this.overlay = overlay;
  }

  /**
   * The principle consolidated by completing a console — closes the
   * "discovery → explanation" loop the pedagogy asks for, surfaced at the
   * moment of success rather than only as a score.
   */
  private solvedPrinciple(kind: ProceduralPuzzleId): string {
    const defaults: Record<ProceduralPuzzleId, string> = {
      language: "il messaggio diventa eseguibile quando accordo e ordine delle parole dicono al sistema cosa fare.",
      circuit: "il LED si accende solo se la corrente trova un percorso chiuso e il verso giusto.",
      math: "il codice nasce rispettando l'ordine dei passaggi: ogni operazione trasforma il valore precedente.",
      english: "la procedura sicura si estrae da condizioni, ordine e divieti, non traducendo tutto.",
      robot: "la rotta migliore è la sequenza minima: osserva ostacoli e direzione prima di muovere.",
      coding: "una sequenza corretta nasce leggendo l'effetto di ogni istruzione, un passo alla volta.",
      music: "l'altezza di una nota si legge dalla sua posizione sul pentagramma, data la chiave.",
      physics: "un fenomeno diventa prevedibile quando grandezze, unita, grafico e modello raccontano la stessa storia.",
    };
    return defaults[kind];
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
    const cleanSolve = score.attempts <= 1 && score.hintsUsed === 0;
    const solvedNode = puzzleKindFromId(puzzleId);
    const principle = this.solvedPrinciple(solvedNode);
    this.playConsoleRestoredMoment(solvedNode);
    // Surface the learned principle prominently instead of only the score.
    outcomeFeedback.play(this, "success", `Principio: ${principle}`);
    if (cleanSolve) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(solvedNode));
      this.rewardCleanSolve();
    }
    this.clearOverlay();
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    const nextLine = remaining.length > 0
      ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.`
      : "Percorso disciplinare completo: la porta finale è pronta.";
    feedbackSystem.publish(`${this.dependencies.effectLine(solvedNode)} Hai consolidato: ${principle} +${score.total} punti (${formatDuration(score.elapsedMs)}). ${nextLine}`, "success");
    if (remaining.length === 0) {
      this.certifyCompletedRun("Ultima console stabilizzata: il sistema completo e certificabile.");
      return;
    }
    this.noraSay("solve");
    if (this.isProgressiveMode()) {
      // Redraw the room so the repaired console and the restored path remain
      // visible before the next system opens.
      this.runWhenActive(2200, () => this.scene.restart());
      return;
    }
    this.runWhenActive(2200, () => this.scene.restart());
  }

  private playConsoleRestoredMoment(kind: ProceduralPuzzleId): void {
    const hotspot = sortProceduralHotspots(this.run.mission.map.hotspots).find((item) => {
      const id = item.puzzleId ?? item.id;
      return item.puzzleKind === kind || puzzleKindFromId(id) === kind;
    });
    const stage = SceneChrome.layout.stage;
    const point = hotspot
      ? proceduralHotspotPosition(hotspot, stage)
      : { x: stage.x + stage.width / 2, y: stage.y + stage.height / 2 };
    const colors: Record<ProceduralPuzzleId, number> = {
      language: 0x9f8cff,
      circuit: 0xf6c85f,
      math: 0x6be7d6,
      english: 0x70d68a,
      robot: 0xff8f6b,
      coding: 0x6bb6ff,
      music: 0xffb6f2,
      physics: 0x8cffd7,
    };
    const color = colors[kind];
    const wash = this.add.rectangle(stage.x + stage.width / 2, stage.y + stage.height / 2, stage.width - 34, stage.height - 34, color, 0.12)
      .setDepth(920);
    this.tweens.add({ targets: wash, alpha: 0, duration: 900, ease: "Sine.easeOut", onComplete: () => wash.destroy() });
    const beam = this.add.line(0, 0, point.x, point.y, stage.x + stage.width / 2, stage.y + 48, color, 0.58)
      .setOrigin(0)
      .setLineWidth(3)
      .setDepth(922);
    this.tweens.add({ targets: beam, alpha: 0, duration: 760, ease: "Sine.easeOut", onComplete: () => beam.destroy() });
    for (let index = 0; index < 3; index += 1) {
      const ring = this.add.circle(point.x, point.y, 18 + index * 8, color, 0)
        .setStrokeStyle(3, color, 0.72 - index * 0.16)
        .setDepth(923);
      this.tweens.add({
        targets: ring,
        scale: 2.7 + index * 0.35,
        alpha: { from: 0.86, to: 0 },
        delay: index * 90,
        duration: 760,
        ease: "Sine.easeOut",
        onComplete: () => ring.destroy(),
      });
    }
    VisualKit.particleBurst(this, point.x, point.y, "circuit", "success");
  }

  /**
   * Rewards aid-free, first-try solves in story modes: a small time bonus each
   * time, and a restored life when the run reaches three clean solves. Turns
   * good method (autonomy) into a tangible, fun perk without punishing anyone.
   */
  private rewardCleanSolve(): void {
    if (this.runMode() === "training") {
      return;
    }
    const cleanCount = Object.values(this.run.puzzleStats ?? {}).filter(
      (stat) => stat.attempts <= 1 && stat.hintsUsed === 0,
    ).length;

    const update: Partial<ProceduralRunSave> = {};
    if (this.run.deadlineAt) {
      const currentDeadline = new Date(this.run.deadlineAt).getTime();
      update.deadlineAt = new Date(Math.max(Date.now(), currentDeadline) + 18_000).toISOString();
    }
    const maxLives = this.run.maxLives ?? proceduralRunRules.maxLives;
    const lives = this.run.lives ?? maxLives;
    const grantsLife = cleanCount === 3 && lives < maxLives;
    if (grantsLife) {
      update.lives = lives + 1;
    }
    if (Object.keys(update).length > 0) {
      saveSystem.updateProceduralRun(update);
      this.run = saveSystem.data.proceduralRun ?? this.run;
    }
    VisualKit.particleBurst(this, 640, 320, "circuit", "success");
    noraChip.say(
      this,
      grantsLife
        ? "Serie pulita! Tre diagnosi senza aiuti: ti restituisco una vita. Continua così."
        : "Soluzione autonoma: ti recupero qualche secondo. Il metodo paga.",
      "success",
    );
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

  private puzzleHintTexts(puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } }): string[] {
    const ladder = puzzle.pedagogy?.hintLadder?.map((item) => item.text).filter(Boolean) ?? [];
    return ladder.length > 0 ? ladder : puzzle.hints;
  }

  private activePuzzleHintsUsed(): number {
    const puzzleId = this.activePuzzleId;
    if (!puzzleId) return 0;
    return (saveSystem.data.proceduralRun ?? this.run).puzzleStats?.[puzzleId]?.hintsUsed ?? 0;
  }

  private currentActiveHint(): string | undefined {
    return this.activeHintPuzzleId === this.activePuzzleId ? this.activeHintText : undefined;
  }

  private nextPedagogicHint(puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } }, fallback: string): string {
    const hints = this.puzzleHintTexts(puzzle);
    return hints[Math.min(this.activePuzzleHintsUsed(), hints.length - 1)] ?? fallback;
  }

  private hintButtonLabel(
    puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } },
    label: string,
  ): string {
    const total = this.puzzleHintTexts(puzzle).length;
    const used = Math.min(this.activePuzzleHintsUsed(), total);
    if (total === 0) return label;
    return used >= total ? "Indizi esauriti" : `${label} ${used + 1}/${total}`;
  }

  private useContextualHint(puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } }): void {
    const hints = this.puzzleHintTexts(puzzle);
    const used = this.activePuzzleHintsUsed();
    if (hints.length === 0 || used >= hints.length) {
      audioManager.playOutcome("hint");
      feedbackSystem.publish("Tutti gli indizi disponibili per questo esercizio sono già visibili.", "hint");
      return;
    }
    this.useHint(hints[used]);
  }

  private useHint(text: string): void {
    this.recordPuzzleSupport();
    const freeLens = saveSystem.data.inventory.includes("nora-lens") && !this.run.noraLensUsed;
    if (freeLens) {
      saveSystem.updateProceduralRun({ noraLensUsed: true });
    } else {
      saveSystem.incrementProceduralHints();
    }
    this.run = saveSystem.data.proceduralRun ?? this.run;
    this.activeHintText = text;
    this.activeHintPuzzleId = this.activePuzzleId;
    audioManager.playOutcome("hint");
    feedbackSystem.publish(`${freeLens ? "Lente causale NORA" : "Indizio"}: ${text}${freeLens ? " La prima analisi della run non consuma aiuti." : ""}`, "hint");
  }

  private handleIncorrectAnswer(message: string): boolean {
    if (this.isRunInteractionLocked()) {
      return true;
    }
    if (this.checkMissionTimeout()) {
      return true;
    }
    this.recordPuzzleMistake();
    const category = `${this.activePuzzleKind ?? "unknown"}:${message.toLowerCase().includes("prova") ? "evidence" : "concept"}`;
    const memoryCount = saveSystem.recordLearningMistake(category);
    const attempts = this.activePuzzleAttempts();
    if (this.isTimedMissionMode() && attempts >= this.mistakesBeforeLifeLoss()) {
      this.loseMissionLife(message);
      return true;
    }
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", attempts === 1 ? "Osserva e correggi" : "Riprova con metodo");
    feedbackSystem.publish(
      `${message} ${attempts === 1
        ? "Il primo errore è una diagnosi: correggi la scelta senza perdere la prova."
        : "Usa il feedback per modificare un solo passaggio alla volta."}${memoryCount >= 3 ? " NORA ha riconosciuto questo schema: nella prossima prova mostrerà prima il controllo utile." : ""}`,
      "warning",
    );
    return false;
  }

  private activePuzzleAttempts(): number {
    const puzzleId = this.activePuzzleId;
    if (!puzzleId) return 0;
    return (saveSystem.data.proceduralRun ?? this.run).puzzleStats?.[puzzleId]?.attempts ?? 0;
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
    this.runWhenActive(1750, () => this.scene.restart());
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
    if (this.isTimedMissionMode() && this.activePuzzleAttempts() >= this.mistakesBeforeLifeLoss()) {
      this.loseMissionLife(message);
      return;
    }
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Ascolta, riconta, correggi");
    feedbackSystem.publish(`${message} Puoi correggere il primo errore senza perdere la prova.`, "warning");
  }

  private loseMissionLife(reason: string): void {
    if (this.isRunInteractionLocked()) {
      return;
    }
    const lives = this.run.lives ?? proceduralRunRules.maxLives;
    const nextLives = Math.max(0, lives - 1);
    const failedKind = this.activePuzzleKind;
    const failedPuzzleId = this.activePuzzleId;
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

    if (failedKind) {
      this.rotatePuzzleVariant(failedKind, failedPuzzleId);
    }
    this.missionFailureInProgress = true;
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Vita persa");
    this.noraSay(nextLives <= 1 ? "lowLife" : "lifeLost");
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
      this.runWhenActive(2400, () => this.scene.restart());
      return;
    }
  }

  private rotatePuzzleVariant(kind: ProceduralPuzzleId, puzzleId?: string): void {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const nextVariant = (run.retryVariants?.[kind] ?? 0) + 1;
    const variantSeed = `${run.seed}-RETRY-${kind}-${nextVariant}`;
    const generated = proceduralDirector.generateMission(variantSeed, run.difficulty, run.focus);
    const puzzleStats = { ...(run.puzzleStats ?? {}) };
    if (puzzleId && puzzleStats[puzzleId]) {
      puzzleStats[puzzleId] = {
        ...puzzleStats[puzzleId],
        startedAt: new Date().toISOString(),
        completedAt: undefined,
        elapsedMs: 0,
        attempts: 0,
        total: 0,
        feedback: "Nuova variante generata dopo il tentativo precedente.",
      };
    }
    saveSystem.updateProceduralRun({
      mission: {
        ...run.mission,
        puzzles: {
          ...run.mission.puzzles,
          [kind]: generated.puzzles[kind],
        },
      },
      retryVariants: {
        ...(run.retryVariants ?? {}),
        [kind]: nextVariant,
      },
      puzzleStats,
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private failMissionNow(reason: string): void {
    if (this.missionFailureInProgress && this.run.failedAt) {
      return;
    }
    this.missionFailureInProgress = true;
    const now = new Date().toISOString();
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Missione fallita");
    this.noraSay("defeat");
    this.discardActivePuzzleAttempt();
    this.clearOverlay();
    saveSystem.updateProceduralRun({
      lives: 0,
      failedAt: now,
      pausedRemainingMs: undefined,
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
    feedbackSystem.publish(`Missione fallita: ${reason} Non ci sono piu condizioni utili per proseguire: ricomincia dal menu con una nuova missione.`, "warning");
    this.showMissionFailure(reason);
  }

  private showMissionFailure(reason: string): void {
    const trial = this.isChapterTrial();
    const weak = masterySystem.weakestPracticedFocus();
    const weakLabel = weak ? proceduralScoring.domainLabel(weak) : undefined;
    const overlay = this.add.container(0, 0).setDepth(1900);
    SceneChrome.modalInputBlocker(this, overlay, 0, 0, 0x02070b, 0.9);
    overlay.add(this.add.image(324, 360, "outcome-defeat").setDisplaySize(438, 438).setAlpha(0.96));
    overlay.add(this.add.rectangle(324, 360, 466, 466, 0x000000, 0).setStrokeStyle(2, 0xc94b55, 0.56));
    overlay.add(this.add.rectangle(854, 360, 642, 466, 0x07151d, 0.97).setStrokeStyle(2, 0xc94b55, 0.78));
    overlay.add(this.add.text(568, 158, trial ? "Prova non superata" : "Missione fallita", {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#ffb0a8",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(570, 218, trial
      ? "Hai esaurito i 3 errori (o il tempo) della Prova del Capitolo. Nessun capitolo si sblocca finché non la superi tutta: la Prova riparte da capo."
      : "Le vite sono esaurite. La run è stata chiusa e non può essere ripresa.", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f5fbff",
      wordWrap: { width: 550 },
      lineSpacing: 5,
    }));
    overlay.add(this.add.rectangle(570, 292, 568, 142, 0x102533, 0.82).setOrigin(0).setStrokeStyle(1, 0xc94b55, 0.38));
    overlay.add(this.add.text(594, 316, trial
      ? `Motivo: ${reason}\n\nConsiglio di NORA: prima di riprovare, allena ${weakLabel ?? "la materia in cui sei meno sicura"} nella Palestra. Poi torna qui più pronta.`
      : `Motivo: ${reason}\n\nI progressi di questa run restano nel registro. Ricomincia crea una missione nuova allo stesso livello, con vite e timer ripristinati.`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 520 },
      lineSpacing: 5,
    }));
    overlay.add(new Button(this, 716, 568, trial ? "Riprova la Prova" : "Ricomincia", () => {
      this.missionFailureInProgress = false;
      this.clearOverlay();
      this.regenerate();
    }, {
      width: 270,
      height: 56,
      fill: 0x173b36,
      stroke: 0x9ff5e9,
      fontSize: 18,
    }));
    overlay.add(new Button(this, 1010, 568, trial ? "Torna alla Storia" : "Menu", () => {
      this.missionFailureInProgress = false;
      this.clearOverlay();
      this.scene.start(trial ? "CampaignScene" : "MainMenuScene");
    }, {
      width: 206,
      height: 56,
      fill: 0x263743,
      stroke: 0x6be7d6,
      fontSize: 18,
    }));
    this.overlay = overlay;
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
    if (success) this.unlockProgressiveTool(result.level);
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

  private unlockProgressiveTool(level: DifficultyLevel): void {
    const unlocks: Partial<Record<DifficultyLevel, { id: string; label: string }>> = {
      1: { id: "nora-lens", label: "Lente causale: il primo indizio di ogni run è gratuito" },
      3: { id: "nora-reserve", label: "Riserva rapida: gli impulsi NORA si caricano più velocemente" },
      5: { id: "nora-shield", label: "Scudo rinforzato: una carica può recuperare due vite" },
      8: { id: "nora-prismatic-core", label: "Nucleo prismatico: certificazione permanente della scalata" },
    };
    const unlock = unlocks[level];
    if (!unlock || saveSystem.data.inventory.includes(unlock.id)) return;
    saveSystem.addInventoryItem(unlock.id);
    feedbackSystem.publish(`Nuovo strumento NORA sbloccato — ${unlock.label}.`, "success");
  }

  private assessProgressiveOutcome(
    success: boolean,
    solvedCount: number,
    requiredCount: number,
  ): ProgressiveOutcomeTone {
    const solvedRatio = requiredCount > 0 ? solvedCount / requiredCount : 0;
    if (!success) {
      if (solvedRatio <= 0.2) return "devastating-defeat";
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
    const elapsed = proceduralRunRules.elapsedMs(
      this.run,
      this.run.completedAt ? new Date(this.run.completedAt).getTime() : Date.now(),
    );
    const mode = proceduralRunRules.modeFor(this.run);
    const focus = proceduralRunRules.focusFor(this.run);
    const recordKey = proceduralRunRules.trainingRecordKey(focus, this.run.difficulty);
    const record = saveSystem.data.trainingRecords?.[recordKey];
    const remainingMs = proceduralRunRules.remainingMs(this.run);
    const solvedCount = this.requiredPuzzleIds().filter((id) => this.isSolved(id)).length;
    const failedCount = this.requiredPuzzleIds().filter((id) => this.isFailed(id)).length;
    const progressiveLevel = this.run.progressive?.currentLevel ?? this.run.difficulty;
    const progressiveGoal = mode === "progressive"
      ? progressiveMissionBuilder.blueprintForLevel(progressiveLevel).goal
      : "";
    const nextObjective = pendingObjectives[0];
    const nextPuzzleId = nextObjective?.id.replace("procedural-", "");
    const nextLabel = nextObjective
      ? `${nextObjective.label}`
      : mode === "progressive"
        ? "Porta di sintesi"
        : mode === "training"
          ? "Porta del registro"
          : "Porta finale";
    const nextAction = nextPuzzleId
      ? `Apri ${this.puzzleLabel(nextPuzzleId)} nella zona d'azione.`
      : mode === "progressive"
        ? "Apri la porta e collega i passaggi nell'ordine corretto."
        : mode === "training"
          ? "Apri la porta per registrare voto e miglior tempo."
          : "Apri la porta per chiudere la missione.";
    const contextLine = mode === "progressive"
      ? `Livello ${progressiveLevel}/8: ${progressiveGoal}`
      : mode === "training"
        ? `Focus: ${proceduralScoring.domainLabel(focus)}`
        : this.run.chapterExploreMissionId
          ? "Fase Esplora: impara senza pressione."
          : this.run.chapterMissionId
            ? "Fase Prova: precisione e tempo contano."
            : "Missione: stabilizza il sistema completo.";
    this.objectiveText?.setText(
      pendingObjectives.length > 0
        ? `${contextLine}\n\nORA\n${nextLabel}\n\nAZIONE\n${mode === "progressive" ? "La prossima console si apre da sola." : nextAction}`
        : mode === "progressive"
          ? `${contextLine}\n\nORA\nPorta di sintesi pronta.\n\nAZIONE\nCollega le discipline per certificare il livello.`
          : mode === "mission"
          ? `${contextLine}\n\nORA\nPorta finale pronta.\n\nAZIONE\nAprila per completare questa fase.`
          : `${contextLine}\n\nORA\nPorta del registro pronta.\n\nAZIONE\nAprila per salvare il risultato.`,
    );
    const pressureEnabled = proceduralRunRules.pressureEnabledFor(this.run);
    this.progressText?.setText(
      pressureEnabled
        ? `Completate: ${solvedCount}/${requiredCount}\nErrori residui: ${this.run.lives ?? proceduralRunRules.maxLives}/${this.run.maxLives ?? proceduralRunRules.maxLives}\nTempo: ${formatDuration(Math.max(0, remainingMs))}\nPunti: ${this.run.score?.total ?? 0}`
        : `Completate: ${solvedCount}/${requiredCount}\nDa rivedere: ${failedCount}\nIndizi: ${this.run.hintsUsed}\nTempo: ${formatDuration(elapsed)}\n${mode === "mission" ? "Pressione: no" : `Record: ${record ? formatDuration(record.bestTimeMs) : "non ancora"}`}`,
    );
  }

  private checkMissionTimeout(): boolean {
    if (this.isRunInteractionLocked()) {
      return true;
    }
    if (!proceduralRunRules.pressureEnabledFor(this.run) || this.run.timerState !== "running" || this.run.completedAt || this.run.failedAt) {
      return false;
    }
    if (proceduralRunRules.remainingMs(this.run) > 0) {
      return false;
    }
    if (this.isProgressiveMode()) {
      this.completeProgressiveLevel(false, "Tempo esaurito.");
      return true;
    }
    this.failMissionNow(this.isChapterTrial()
      ? "tempo esaurito: la Prova del Capitolo ha finito il tempo disponibile."
      : "tempo esaurito: la missione ha finito il tempo disponibile.");
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
      physics: "fisica",
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
    const puzzle = challenge?.kind === "language" ? challenge.puzzle : this.run.mission.puzzles.language;
    if (puzzle.id === "language-fallback") {
      return new LanguageCorruptionGenerator().generate(
        new Random(`${this.run.seed}:replace-legacy-language-fallback`),
        this.run.difficulty,
      );
    }
    const template = languageTemplates.find((candidate) => `language-${candidate.id}` === puzzle.id);
    if (!template || (puzzle.corrupted === template.corrupted && puzzle.repaired === template.repaired)) {
      return puzzle;
    }

    const correctIndex = Math.max(0, puzzle.options.indexOf(puzzle.repaired));
    const options = [...template.distractors];
    options.splice(Math.min(correctIndex, options.length), 0, template.repaired);
    const optionFeedback: Record<string, string> = {
      [template.repaired]: "Riscrittura corretta: grammatica e rapporto logico sono coerenti.",
    };
    template.distractors.forEach((option, index) => {
      optionFeedback[option] = template.distractorFeedback?.[option]
        ?? `${template.diagnosticSteps[index % template.diagnosticSteps.length]} ${template.hints[index % template.hints.length]}`;
    });
    return {
      ...puzzle,
      title: template.title,
      corrupted: template.corrupted,
      repaired: template.repaired,
      options,
      diagnosticSteps: template.diagnosticSteps,
      hints: template.hints,
      conceptTags: template.conceptTags ?? puzzle.conceptTags,
      learningPurpose: template.learningPurpose ?? puzzle.learningPurpose,
      repairGoal: template.repairGoal ?? puzzle.repairGoal,
      method: template.method ?? puzzle.method,
      optionFeedback,
    };
  }

  // --- Circuit minigame (quick electronics sprint) -------------------------

  private openCircuitMinigame(puzzle: GeneratedCircuitPuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("circuit");
    const session = this.ensureCircuitMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const overlay = this.createMathOverlay(puzzle.minigame.title, "Elettronica · leggi lo schema, scegli la risposta, conferma");
    const prompt = this.currentCircuitMinigamePrompt(session);
    const remaining = this.circuitMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 560, 432, "1 · Leggi lo schema");
    overlay.add(this.add.text(60, 154, prompt.title, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.rectangle(60, 200, 500, 196, 0x07151d, 0.85).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.3));
    if (prompt.visual) {
      this.drawCircuitMinigameSchematic(overlay, prompt.visual, prompt.diagramLines);
    } else {
      overlay.add(this.add.text(80, 218, prompt.diagramLines.join("\n"), {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#9ff5e9",
        lineSpacing: 8,
        wordWrap: { width: 460 },
      }));
    }
    overlay.add(this.add.text(60, 470, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 500 },
    }));
    overlay.add(this.add.text(60, 498, this.circuitMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 506, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    this.addMathPanel(overlay, 616, 112, 636, 432, "2 · Scegli la risposta");
    overlay.add(this.add.text(648, 154, "Come si gioca: leggi lo schema, clicca UNA risposta e premi Conferma.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 548 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(648, 210, prompt.question, {
      fontFamily: "Inter, Arial",
      fontSize: prompt.question.length > 92 ? "16px" : "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 548, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    const tileStartX = 802;
    const tileStartY = 320;
    prompt.tiles.forEach((tile, index) => {
      const selected = session.selectedIds.has(tile.id);
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(new Button(this, tileStartX + col * 244, tileStartY + row * 70, `${selected ? "✓ " : ""}${tile.label}`, () => this.toggleCircuitMinigameTile(tile.id), {
        width: 226,
        height: 54,
        fontSize: tile.label.length > 26 ? 11 : tile.label.length > 16 ? 13 : 16,
        wordWrapWidth: 204,
        fill: selected ? 0x174d42 : 0x263743,
        stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });

    this.addMathPanel(overlay, 28, 558, 1224, 130, "3 · Conferma e controlla l'esito");
    this.circuitMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(this.circuitMinigameTimerText);
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
      wordWrap: { width: 390, useAdvancedWrap: true },
    }));
    overlay.add(new Button(this, 1080, 640, "Conferma", () => this.confirmCircuitMinigamePrompt(), {
      width: 220,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(this, 820, 640, "Indizio", () => this.useCircuitMinigameHint(), {
      width: 180,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    this.circuitMinigameTimerEvent?.remove(false);
    if (session.startedAt <= 0) session.startedAt = Date.now();
    this.circuitMinigameTimerEvent = this.time.addEvent({
      delay: 250,
      loop: true,
      callback: () => this.refreshCircuitMinigameTimer(),
    });
    this.refreshCircuitMinigameTimer();
  }

  private drawCircuitMinigameSchematic(
    overlay: Phaser.GameObjects.Container,
    visual: CircuitMinigameVisual,
    captionLines: string[],
  ): void {
    if (visual.kind === "component") {
      overlay.add(this.add.text(80, 214, "Osserva il simbolo:", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#9aaab0",
      }));
      const cx = 310;
      const cy = 312;
      const color = 0x9ff5e9;
      switch (visual.component) {
        case "battery": drawBatterySymbol(this, overlay, cx, cy, 0xf6c85f); break;
        case "switch": drawSwitchSymbol(this, overlay, cx, cy, color, true, false); break;
        case "resistor": drawResistorSymbol(this, overlay, cx, cy, color, false, false); break;
        case "led": drawLedSymbol(this, overlay, cx, cy, color, false, false, false); break;
        case "capacitor": drawCapacitorSymbol(this, overlay, cx, cy, color, false); break;
        case "sensor": drawSensorSymbol(this, overlay, cx, cy, color, false); break;
        case "relay": drawRelaySymbol(this, overlay, cx, cy, color, false); break;
        case "motor": drawMotorSymbol(this, overlay, cx, cy, color, false); break;
        case "ground": drawGroundSymbol(this, overlay, cx, cy, color, false); break;
        default: break;
      }
      return;
    }

    // led-circuit: a small horizontal schematic the learner must read.
    const y = 296;
    const wire = this.add.graphics();
    wire.lineStyle(3, 0x6be7d6, 0.5);
    wire.lineBetween(78, y, 542, y);
    overlay.add(wire);
    drawBatterySymbol(this, overlay, 116, y, 0xf6c85f);
    drawSwitchSymbol(this, overlay, 212, y, visual.switchClosed ? 0x9ff5e9 : 0xffb36b, visual.switchClosed, false);
    drawResistorSymbol(this, overlay, 312, y, visual.hasResistor ? 0x9ff5e9 : 0xffb36b, !visual.hasResistor, false);
    drawLedSymbol(this, overlay, 402, y, visual.ledForward ? 0x9ff5e9 : 0xffb36b, !visual.ledForward, visual.lit, false);
    drawReturnSymbol(this, overlay, 520, y, 0x9ff5e9);
    if (visual.hasOpen) {
      const gap = this.add.graphics();
      gap.lineStyle(4, 0xff6b6b, 0.95);
      gap.lineBetween(455, y - 14, 475, y + 14);
      gap.lineBetween(475, y - 14, 455, y + 14);
      overlay.add(gap);
    }
    overlay.add(this.add.text(80, 360, captionLines.join("  ·  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 460 },
      lineSpacing: 3,
    }));
  }

  private ensureCircuitMinigameSession(
    puzzleId: string,
    puzzle: GeneratedCircuitPuzzle,
    game: GeneratedCircuitMinigame,
  ): CircuitMinigameSession {
    if (this.circuitMinigameSession?.puzzleId === puzzleId && !this.circuitMinigameSession.summaryOpen) {
      return this.circuitMinigameSession;
    }
    const variant = this.run.retryVariants?.circuit ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:circuit:${variant}:${nextExerciseSalt()}`);
    const fresh = new CircuitFaultGenerator().generateMinigame(random, difficultyModel.getPreset(this.run.difficulty), [game.type]).minigame;
    const freshPrompts = fresh?.prompts?.length ? fresh.prompts : game.prompts;
    const variedGame = { ...game, prompts: random.shuffle(freshPrompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })) };
    this.circuitMinigameSession = {
      puzzleId,
      puzzle,
      game: variedGame,
      startedAt: 0,
      durationMs: game.durationMs,
      promptIndex: 0,
      answered: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      bestStreak: 0,
      netScore: 0,
      selectedIds: new Set<string>(),
      feedback: "Leggi lo schema: componente, percorso, polarità o valori. Poi conferma una risposta.",
      locked: false,
      summaryOpen: false,
    };
    return this.circuitMinigameSession;
  }

  private currentCircuitMinigamePrompt(session: CircuitMinigameSession): CircuitMinigamePrompt {
    return session.game.prompts[session.promptIndex % session.game.prompts.length];
  }

  private circuitMinigameElapsedMs(session: CircuitMinigameSession): number {
    return Date.now() - session.startedAt;
  }

  private circuitMinigameRemainingMs(session: CircuitMinigameSession): number {
    return Math.max(0, session.durationMs - this.circuitMinigameElapsedMs(session));
  }

  private refreshCircuitMinigameTimer(): void {
    const session = this.circuitMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    const remaining = this.circuitMinigameRemainingMs(session);
    this.circuitMinigameTimerText?.setText(`Tempo: ${formatDuration(remaining)}`);
    this.circuitMinigameTimerText?.setColor(remaining <= 10_000 ? "#ff8f8f" : "#f7d37a");
    if (remaining <= 0) {
      this.finishCircuitMinigame();
    }
  }

  private toggleCircuitMinigameTile(tileId: string): void {
    const session = this.circuitMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    session.selectedIds.clear();
    session.selectedIds.add(tileId);
    audioManager.play("click");
    this.openCircuitMinigame(session.puzzle);
  }

  private useCircuitMinigameHint(): void {
    const session = this.circuitMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentCircuitMinigamePrompt(session);
    const hint = prompt.type === "component-id"
      ? "Collega il nome alla funzione: cosa fa quel componente nel circuito?"
      : prompt.type === "predict-led"
        ? "Il LED si accende solo se: interruttore chiuso, percorso continuo, polarità giusta e resistenza che protegge."
        : prompt.type === "ohms-law"
          ? "Scrivi V = R × I e isola la grandezza richiesta prima di calcolare."
          : "In serie le resistenze si sommano; in parallelo la resistenza totale scende.";
    session.feedback = hint;
    this.useHint(hint);
    this.openCircuitMinigame(session.puzzle);
  }

  private confirmCircuitMinigamePrompt(): void {
    const session = this.circuitMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (this.circuitMinigameRemainingMs(session) <= 0) {
      this.finishCircuitMinigame();
      return;
    }
    const prompt = this.currentCircuitMinigamePrompt(session);
    if (session.selectedIds.size === 0) {
      session.feedback = "Prima seleziona una risposta. Il timer continua.";
      audioManager.playOutcome("hint");
      this.openCircuitMinigame(session.puzzle);
      return;
    }
    const selected = prompt.tiles.find((tile) => tile.id === [...session.selectedIds][0]);
    if (!selected?.isCorrect) {
      if (this.isTimedMissionMode()) {
        const message = `${selected?.feedback ?? "Scelta non coerente."} Soluzione: ${prompt.solutionLabels.join(", ")}. ${prompt.explanation}`;
        outcomeFeedback.answer(this, false, selected?.label ?? "nessuna", prompt.solutionLabels.join(", "), prompt.explanation);
        this.circuitMinigameSession = undefined;
        this.handleIncorrectAnswer(message);
        return;
      }
      // Allenamento: pannello persistente con soluzione + spiegazione fino a "Continua".
      session.answered += 1;
      session.wrong += 1;
      session.streak = 0;
      session.netScore = Math.max(0, session.netScore - (8 + this.run.difficulty));
      session.feedback = "Leggi la soluzione, poi premi Continua.";
      session.locked = true;
      this.recordPuzzleMistake();
      audioManager.playOutcome("wrong");
      const circuitPauseStart = Date.now();
      this.circuitMinigameTimerEvent?.remove(false);
      this.showWrongSolution(selected?.label ?? "nessuna", prompt.solutionLabels.join(", "), this.diagnosticWrongExplanation(selected?.feedback, prompt.explanation), () => {
        session.startedAt += Date.now() - circuitPauseStart;
        this.advanceCircuitMinigamePrompt(0);
      });
      return;
    }

    session.answered += 1;
    session.correct += 1;
    session.streak += 1;
    session.bestStreak = Math.max(session.bestStreak, session.streak);
    const award = 10 + this.run.difficulty * 2 + Math.min(12, session.streak * 2);
    session.netScore += award;
    session.feedback = `Corretto: ${prompt.explanation} +${award}`;
    session.locked = true;
    outcomeFeedback.answer(this, true, selected.label, prompt.solutionLabels.join(", "), prompt.explanation);
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    this.advanceCircuitMinigamePrompt(1900);
  }

  private advanceCircuitMinigamePrompt(delayMs: number): void {
    const session = this.circuitMinigameSession;
    if (!session) {
      return;
    }
    this.runWhenActive(delayMs, () => {
      if (this.circuitMinigameSession !== session || session.summaryOpen) {
        return;
      }
      if (this.circuitMinigameRemainingMs(session) <= 0) {
        this.finishCircuitMinigame();
        return;
      }
      const previous = this.currentCircuitMinigamePrompt(session).signature;
      session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      if (this.currentCircuitMinigamePrompt(session).signature === previous) {
        session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      }
      session.selectedIds.clear();
      session.locked = false;
      this.openCircuitMinigame(session.puzzle);
    });
  }

  private finishCircuitMinigame(): void {
    const session = this.circuitMinigameSession;
    if (!session || session.summaryOpen) {
      return;
    }
    session.locked = true;
    session.summaryOpen = true;
    this.circuitMinigameTimerEvent?.remove(false);
    this.circuitMinigameTimerEvent = undefined;
    audioManager.playOutcome("neutral");
    this.showCircuitMinigameSummary(session);
  }

  private circuitMinigamePassed(session: CircuitMinigameSession): boolean {
    if (!this.isTimedMissionMode()) {
      return true;
    }
    const minCorrect = Math.max(5, Math.min(12, 4 + Math.ceil(this.run.difficulty * 0.75)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    return session.correct >= minCorrect && accuracy >= 0.62 && session.netScore > 0;
  }

  private circuitMinigameFeedback(session: CircuitMinigameSession): string {
    if (session.answered === 0) {
      return "Nessuna risposta: leggi lo schema e decidi su componente, percorso o valori.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.9 && session.bestStreak >= 8) {
      return "Ottimo: riconosci componenti, prevedi il LED e applichi la legge di Ohm con sicurezza.";
    }
    if (accuracy >= 0.72) {
      return "Buon lavoro: ora consolida la legge di Ohm e i collegamenti serie/parallelo.";
    }
    if (session.wrong >= session.correct) {
      return "Troppi tentativi: rallenta, leggi lo schema e ragiona su percorso e polarità.";
    }
    return "Allenamento utile: punta a serie pulite e risposte spiegabili.";
  }

  private showCircuitMinigameSummary(session: CircuitMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const modal = this.add.container(0, 0).setDepth(1300);
    const passed = this.circuitMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    SceneChrome.modalInputBlocker(this, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(this.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(this.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(this.add.text(230, 160, passed ? "Sprint circuiti completato" : "Sprint circuiti da consolidare", {
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
    modal.add(this.add.text(572, 234, this.circuitMinigameFeedback(session), {
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
        ? "La console elettronica certifica le tue risposte: componenti, percorso e valori sono coerenti."
        : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
      : "Allenamento registrabile: il voto pesa precisione, velocità, serie corretta e uso degli aiuti.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    modal.add(new Button(this, 612, 506, (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua", () => {
      modal.destroy(true);
      if (!passed && (mode === "mission" || mode === "progressive")) {
        this.loseMissionLife("sprint circuiti sotto soglia: servono più risposte corrette con meno tentativi.");
        return;
      }
      this.completeCircuitMinigame(session);
    }, {
      width: 270,
      height: 54,
      fill: passed ? 0x173b36 : 0x263743,
      stroke: passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
  }

  private completeCircuitMinigame(session: CircuitMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeCircuitMinigameScore(session);
    if (session.wrong === 0 && session.correct > 0) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(puzzleKindFromId(session.puzzleId)));
    }
    saveSystem.markProceduralPuzzleSolved(session.puzzleId);
    competencyTracker.award(session.game.competencies, 8 + this.run.difficulty * 2 + Math.min(12, Math.floor(score.total / 32)));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    this.circuitMinigameSession = undefined;
    const solvedNode = puzzleKindFromId(session.puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    feedbackSystem.publish(
      `Sprint circuiti registrato: ${session.correct} corrette, ${session.wrong} errori, serie ${session.bestStreak}. +${score.total} punti. ${remaining.length > 0 ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.` : "La porta finale è pronta."}`,
      "success",
    );
    if (remaining.length === 0) {
      this.certifyCompletedRun("Console elettronica stabilizzata: il sistema completo è certificabile.");
      return;
    }
    this.runWhenActive(1750, () => this.scene.restart());
  }

  private finalizeCircuitMinigameScore(session: CircuitMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
    const completedAt = new Date().toISOString();
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.circuitMinigameElapsedMs(session)));
    const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
    const basePoints = session.correct * (10 + run.difficulty);
    const difficultyBonus = session.correct * run.difficulty * 2;
    const speedBonus = Math.min(100, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 36));
    const focusBonus = run.focus.includes("elettronica") || run.focus.some((item) => item.startsWith("elettronica."))
      ? 20 + run.difficulty * 3
      : 0;
    const supportPenalty = (existing?.hintsUsed ?? 0) * 6 + session.wrong * (8 + run.difficulty);
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
      feedback: this.circuitMinigameFeedback(session),
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

  private circuitMinigameMethodText(prompt: CircuitMinigamePrompt): string {
    if (prompt.type === "component-id") {
      return "Metodo: associa nome, simbolo e funzione. Ogni componente ha un ruolo preciso nel circuito.";
    }
    if (prompt.type === "predict-led") {
      return "Metodo: percorso chiuso? polarità giusta? resistenza che protegge? Solo allora il LED si accende.";
    }
    if (prompt.type === "ohms-law") {
      return "Metodo: V = R × I. Scrivi la formula, isola la grandezza richiesta, poi calcola.";
    }
    return "Metodo: in serie le resistenze si sommano; in parallelo la totale scende e passa più corrente.";
  }

  private currentCircuitPuzzle(): GeneratedCircuitPuzzle {
    const challenge = this.activeChallenge;
    const puzzle = challenge?.kind === "circuit" ? challenge.puzzle : this.run.mission.puzzles.circuit;
    if (puzzle.id !== "circuit-fallback") return puzzle;
    const preset = difficultyModel.getPreset(this.run.difficulty);
    return exerciseDirector.enrichCircuit(
      new CircuitFaultGenerator().generate(new Random(`${this.run.seed}:replace-legacy-circuit-fallback`), preset),
      this.run.difficulty,
    );
  }

  private currentMathPuzzle(): GeneratedMathPuzzle {
    const challenge = this.activeChallenge;
    const puzzle = challenge?.kind === "math" ? challenge.puzzle : this.run.mission.puzzles.math;
    if (puzzle.id !== "math-fallback") return puzzle;
    const variant = this.run.retryVariants?.math ?? 0;
    const generated = new MathPuzzleGenerator().generate(
      new Random(`${this.run.seed}:replace-legacy-math-fallback:${variant}`),
      difficultyModel.getPreset(this.run.difficulty),
    );
    return exerciseDirector.enrichMath(generated, this.run.difficulty);
  }

  private currentEnglishPuzzle(): GeneratedEnglishPuzzle {
    const challenge = this.activeChallenge;
    const puzzle = challenge?.kind === "english" ? challenge.puzzle : this.run.mission.puzzles.english;
    if (puzzle.id !== "english-fallback") return puzzle;
    return new EnglishInstructionGenerator().generate(
      new Random(`${this.run.seed}:replace-legacy-english-fallback`),
      this.run.difficulty,
    );
  }

  private currentCodingPuzzle(): GeneratedCodingPuzzle {
    const challenge = this.activeChallenge;
    const puzzle = challenge?.kind === "coding" ? challenge.puzzle : this.run.mission.puzzles.coding;
    const legacyStaticFallback = puzzle.id === "coding-trace-output"
      && puzzle.codeLines[0] === "energia = 2"
      && puzzle.codeLines[1] === "energia = energia + 6"
      && puzzle.codeLines[2] === "energia = energia * 2";
    if (!legacyStaticFallback) return puzzle;
    return new CodingPuzzleGenerator().generate(
      new Random(`${this.run.seed}:replace-legacy-coding-fallback`),
      difficultyModel.getPreset(this.run.difficulty),
    );
  }

  private currentMusicPuzzle(): GeneratedMusicPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "music" ? challenge.puzzle : this.run.mission.puzzles.music;
  }

  private currentPhysicsPuzzle(): GeneratedPhysicsPuzzle {
    const challenge = this.activeChallenge;
    const puzzle = challenge?.kind === "physics" ? challenge.puzzle : this.run.mission.puzzles.physics;
    if (puzzle) return puzzle;
    return new PhysicsPuzzleGenerator().generate(
      new Random(`${this.run.seed}:replace-legacy-physics-missing`),
      difficultyModel.getPreset(this.run.difficulty),
    );
  }

  private currentRobotPuzzle(): GeneratedRobotPuzzle {
    const challenge = this.activeChallenge;
    const puzzle = challenge?.kind === "robot" ? challenge.puzzle : this.run.mission.puzzles.robot;
    if (!puzzle.id.startsWith("robot-grid-fallback-") || puzzle.id.endsWith("-base") || puzzle.id.endsWith("-mirror")) return puzzle;
    const preset = difficultyModel.getPreset(this.run.difficulty);
    return exerciseDirector.enrichRobot(
      new RobotGridGenerator().generate(
        new Random(`${this.run.seed}:replace-legacy-robot-fallback`),
        preset,
        puzzle.challengeType,
      ),
      this.run.difficulty,
    );
  }

  private resetTransientPuzzleState(): void {
    this.mathEntry = "";
    this.mathSupportMessage = "";
    this.mathSupportText = undefined;
    this.equationLabStageIndex = 0;
    this.graphWorkshopPuzzleId = undefined;
    this.graphWorkshopValues = {};
    this.graphWorkshopMoves = 0;
    this.activeHintText = undefined;
    this.activeHintPuzzleId = undefined;
    this.languageSelectedOption = undefined;
    this.languageBuilderPuzzleId = undefined;
    this.languageBuilderShuffled = [];
    this.languageBuilderPlaced = [];
    this.englishSelectedChoiceId = undefined;
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
    this.codingMinigameTimerEvent?.remove(false);
    this.codingMinigameTimerEvent = undefined;
    this.codingMinigameTimerText = undefined;
    this.codingMinigameSession = undefined;
    this.circuitMinigameTimerEvent?.remove(false);
    this.circuitMinigameTimerEvent = undefined;
    this.circuitMinigameTimerText = undefined;
    this.circuitMinigameSession = undefined;
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

  private createExerciseScreen(title: string): Phaser.GameObjects.Container {
    this.clearOverlay();
    const overlay = this.add.container(40, 0).setDepth(1200);
    SceneChrome.modalInputBlocker(this, overlay, overlay.x, overlay.y);
    const backgroundKey = this.exerciseBackgroundKey();
    if (this.textures.exists(backgroundKey)) {
      overlay.add(this.add.image(600, 360, backgroundKey).setDisplaySize(1320, 742).setAlpha(0.34));
    }
    overlay.add(this.add.rectangle(600, 360, 1280, 720, 0x02080d, 0.82));
    const grid = this.add.graphics();
    grid.lineStyle(1, 0x6be7d6, 0.045);
    for (let x = -160; x < 1320; x += 72) {
      grid.lineBetween(x, 0, x - 128, 720);
    }
    for (let y = 92; y < 720; y += 58) {
      grid.lineBetween(-40, y, 1240, y + 10);
    }
    overlay.add(grid);
    overlay.add(this.add.rectangle(600, 34, 1280, 68, 0x06131c, 0.92));
    overlay.add(this.add.rectangle(600, 68, 1280, 2, 0x6be7d6, 0.42));
    overlay.add(this.add.text(0, 14, title, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 1080, useAdvancedWrap: true },
      shadow: { offsetX: 0, offsetY: 3, color: "#000000", blur: 6, fill: true },
    }));
    overlay.add(new Button(this, 1184, 34, "X", () => this.closeOverlayFromUser(), {
      width: 56,
      height: 42,
      fontSize: 18,
      fill: 0x263743,
    }));
    this.overlay = overlay;
    return overlay;
  }

  private exerciseBackgroundKey(): string {
    const kind = this.activePuzzleKind ?? "coding";
    return {
      language: "mission-bg-italian",
      circuit: "mission-bg-electronics",
      math: "mission-bg-math",
      english: "mission-bg-english",
      robot: "mission-bg-coding",
      coding: "mission-bg-coding",
      music: "mission-bg-music",
      physics: "mission-bg-synthesis",
    }[kind];
  }

  private addLanguageBrief(overlay: Phaser.GameObjects.Container, model: LanguageRepairModel): void {
    overlay.add(this.add.rectangle(316, 397, 520, 330, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(76, 246, "Come decidere", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 274, model.diagnosticSteps.slice(0, 3).map((step, index) => `${index + 1}. ${step}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 6,
    }));
    overlay.add(this.add.text(76, 410, "Obiettivo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 438, model.repairGoal, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    const activeHint = this.currentActiveHint();
    if (activeHint) {
      overlay.add(this.add.text(76, 494, "Indizio attivo", {
        fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", fontStyle: "bold",
      }));
      overlay.add(this.add.text(76, 516, activeHint, {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#d9eaf1", wordWrap: { width: 456, useAdvancedWrap: true },
      }));
    }
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
      "translation-recognition": "Traduzione lessicale",
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

  private physicsExerciseLabel(type: GeneratedPhysicsPuzzle["exerciseType"]): string {
    return {
      "motion-graph": "grafico del moto",
      "unit-check": "unita e misure",
      "force-diagram": "diagramma forze",
      "energy-transfer": "energia",
      "experiment-order": "metodo sperimentale",
      "density-pressure": "densita e pressione",
      "heat-temperature": "calore e temperatura",
      "wave-reading": "onde",
      "optics-ray": "ottica geometrica",
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
    this.codingMinigameTimerEvent?.remove(false);
    this.codingMinigameTimerEvent = undefined;
    this.codingMinigameTimerText = undefined;
    this.circuitMinigameTimerEvent?.remove(false);
    this.circuitMinigameTimerEvent = undefined;
    this.circuitMinigameTimerText = undefined;
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
