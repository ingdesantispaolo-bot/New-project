import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { buildChapterExploreRun, buildChapterTrialRun, chapterTrialLevel, chapterTrialTimeMs, CHAPTER_TRIAL_ERROR_BUDGET } from "../core/ChapterTrial";
import { markMissionComplete, markMissionExplored } from "../core/MissionCompletion";
import { noraContextEngine, type NoraContextBeat } from "../core/NoraContextEngine";
import { noraCompanion, type NoraMemory } from "../core/NoraCompanion";
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
import { startScene } from "../core/SceneNavigator";
import { noraVoice, type NoraBeat } from "../core/NoraVoice";
import { noraChip } from "../ui/NoraChip";
import { noraPresence } from "../ui/NoraPresence";
import { languageTemplates } from "../data/procedural/languageTemplates";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { difficultyModel } from "../procedural/DifficultyModel";
import { CircuitFaultGenerator } from "../procedural/generators/CircuitFaultGenerator";
import { CodingPuzzleGenerator } from "../procedural/generators/CodingPuzzleGenerator";
import { EnglishInstructionGenerator } from "../procedural/generators/EnglishInstructionGenerator";
import { LanguageCorruptionGenerator, normalizeTypedAnswer } from "../procedural/generators/LanguageCorruptionGenerator";
import { MathPuzzleGenerator } from "../procedural/generators/MathPuzzleGenerator";
import { MusicNoteGenerator } from "../procedural/generators/MusicNoteGenerator";
import { LatinGenerator } from "../procedural/generators/LatinGenerator";
import { PhysicsPuzzleGenerator } from "../procedural/generators/PhysicsPuzzleGenerator";
import { RobotGridGenerator } from "../procedural/generators/RobotGridGenerator";
import { progressiveMissionBuilder } from "../procedural/ProgressiveMissionBuilder";
import { Random } from "../procedural/Random";
import type {
  CircuitComponentChallenge,
  CircuitFaultType,
  CodingMinigamePrompt,
  CodingMinigameType,
  DifficultyLevel,
  EquationLabVisual,
  EnglishMinigamePrompt,
  GeneratedFocusChallenge,
  GeneratedGraphWorkshop,
  GeneratedCodingPuzzle,
  GeneratedCircuitPuzzle,
  GeneratedCodingMinigame,
  GeneratedEnglishMinigame,
  GeneratedEnglishPuzzle,
  GeneratedLanguagePuzzle,
  GeneratedLanguageMinigame,
  GeneratedLatinPuzzle,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  GeneratedMusicPuzzle,
  GeneratedPhysicsPuzzle,
  GeneratedRobotPuzzle,
  GeneratedRoomHotspot,
  GridCommand,
  GraphParameterKey,
  GraphReadingStep,
  EnglishMinigameType,
  LanguageMinigameType,
  LanguageMinigamePrompt,
  MathMinigamePrompt,
  MusicMinigameType,
  ProceduralBonusEventState,
  ProgressiveLevelResult,
  ProgressiveOutcomeTone,
  ProceduralPuzzleScore,
  ProceduralRunSave,
} from "../procedural/ProceduralTypes";
import type { LogicGymBonusActivityKey, LogicGymBonusResult } from "../types/logicGymBonus";
import { Button } from "../ui/Button";
import { outcomeFeedback, type OutcomeTone } from "../ui/OutcomeFeedback";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";
import { CircuitConsole, type CircuitConsoleModel } from "./procedural/components/CircuitConsole";
import { renderCodingSprintConsole } from "./procedural/components/CodingSprintConsole";
import { renderEnglishSprintConsole } from "./procedural/components/EnglishSprintConsole";
import { LanguageRepairConsole, type LanguageRepairModel } from "./procedural/components/LanguageRepairConsole";
import { MathTerminal } from "./procedural/components/MathTerminal";
import { MissionDependencyGraph } from "./procedural/components/MissionDependencyGraph";
import { MusicConsole } from "./procedural/components/MusicConsole";
import { PhysicsConsole } from "./procedural/components/PhysicsConsole";
import { EquationLabView } from "./procedural/components/EquationLabView";
import { GraphWorkshopView } from "./procedural/components/GraphWorkshopView";
import { RobotConsole, type RobotSprite } from "./procedural/components/RobotConsole";
import { addSprintSummaryModal } from "./procedural/components/SprintSummaryModal";
import {
  isProceduralHotspotSolved,
  isProceduralPuzzleSolved,
  proceduralHotspotKind,
  proceduralHotspotPosition,
  proceduralPuzzleOrder,
  proceduralRequiredPuzzleIds,
  puzzleKindFromId,
  sortProceduralHotspots,
  type ProceduralPuzzleId,
} from "./procedural/ProceduralMissionLayout";
import { ProceduralMissionView } from "./procedural/ProceduralMissionView";
import {
  buildFreshProceduralRun,
  buildProgressiveProceduralRun,
  buildReplacementProceduralRun,
  buildRunNormalizationUpdate,
  runNeedsContentMigration,
} from "./procedural/ProceduralRunFactory";
import { MissionRoomAvatar } from "./procedural/MissionRoomAvatar";
import { choiceTileFontSize, choiceTileLabel } from "./procedural/ChoiceTileText";
import { addMethodStrip, codingChallengeLabel, englishChallengeLabel, exerciseBackgroundKey } from "./procedural/ExerciseUiHelpers";
import { createExerciseScreenChrome } from "./procedural/ExerciseScreenChrome";
import { addNoraTheoryButton as addNoraTheoryButtonToOverlay, noraTheoryTopicFor as theoryTopicForPuzzle, showFirstEncounterPanel } from "./procedural/NoraTheoryPanel";
import {
  codingMinigameFeedback,
  codingMinigameHint,
  englishMinigameFeedback,
  englishMinigameHint,
  englishSelectionRequirementText,
} from "./procedural/SprintPromptText";
import { buildSprintCompletionOutcome, type SprintCompletionCopy } from "./procedural/SprintCompletionRules";
import {
  buildCodingMinigameScore,
  buildEnglishMinigameScore,
  buildLanguageMinigameScore,
  buildMathMinigameScore,
  buildPuzzleStatPatchUpdate,
  buildPuzzleTimerStartUpdate,
  buildScoreRunUpdate,
  buildStandardPuzzleScore,
  buildMusicSprintScore,
} from "./procedural/SprintScoreRules";
import {
  buildCircuitMinigameScore,
  circuitMinigameCorrectAward,
  circuitMinigameFeedback,
  circuitMinigameHint,
  circuitMinigamePassed,
  circuitMinigameRemainingMs,
  createCircuitMinigameSession,
  currentCircuitMinigamePrompt,
} from "./procedural/CircuitMinigameRules";
import {
  compactMissionBonusEvents,
  createMissionBonusOfferOverlay,
  missionBonusActivityTitle,
  missionBonusEventLimit,
  missionBonusRounds,
  normalizeMissionBonusEvents,
  selectMissionBonusActivity,
  shouldOfferMissionBonus,
} from "./procedural/MissionBonusEvents";
import {
  buildProgressiveJournalEntry,
  buildProgressiveLevelCompletion,
  buildProgressiveRunCompletionUpdate,
  progressiveTotalElapsedMs,
  progressiveToolUnlockForLevel,
} from "./procedural/ProgressiveRunRules";
import {
  buildLifeLossOutcome,
  buildMissionFailureUpdate,
  missionFailureFeedback,
} from "./procedural/MissionFailureRules";
import {
  chapterExploreCompletionFeedback,
  chapterTrialCompletionFeedback,
  doorMissingFeedback,
  ghostNoraLine,
  standardCompletionCopy,
} from "./procedural/MissionCompletionRules";
import {
  buildCleanSolveReward,
  isCleanPuzzleSolve,
  puzzleKindLabel,
  puzzleSolveFeedback,
  puzzleCompetencyAward,
  solvedPrincipleForKind,
} from "./procedural/PuzzleSolveRules";
import {
  hintButtonLabel,
  nextPedagogicHint,
  puzzleHintTexts,
} from "./procedural/PuzzleHintRules";
import {
  initialRobotExecutionState,
  robotFailureText,
  robotProgramEndFailure,
  sortedRobotCheckpoints,
  stepRobotCommand,
} from "./procedural/RobotExecutionRules";
import { RoomExplorer, type RoomConsole, type RoomWall } from "./procedural/RoomExplorer";
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
// Fresh nonce per started exercise session, so the same run/seed does not keep
// serving the identical sequence of prompts: each new sprint regenerates its
// content. Combines time and a counter to stay unique even within the same ms.
let exerciseVarietyCounter = 0;
function nextExerciseSalt(): string {
  exerciseVarietyCounter += 1;
  return `${Date.now().toString(36)}-${exerciseVarietyCounter.toString(36)}`;
}

interface SprintCompletionSessionLike {
  puzzleId: string;
  correct: number;
  wrong: number;
  bestStreak: number;
}

interface CompleteSprintMinigameOptions {
  session: SprintCompletionSessionLike;
  score: ProceduralPuzzleScore;
  competencies: string[];
  copy: SprintCompletionCopy;
  clearSession: () => void;
  restartDelayMs: number;
  maxScoreBonus?: number;
  scoreDivisor?: number;
  masteryBranchId?: string;
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
  private graphWorkshopReadingAnswers: Record<string, number> = {};
  private graphWorkshopApplied = false;
  private graphWorkshopMoves = 0;
  private activeHintText?: string;
  private activeHintPuzzleId?: string;
  private languageSelectedOption?: string;
  private latinSelectedLabel?: string;
  private englishSelectedChoiceId?: string;
  private circuitInspected = false;
  private circuitConceptVerified = false;
  private circuitConceptIndex = 0;
  private circuitSymbolAnswer?: string;
  private selectedRepairs = new Set<CircuitFaultType>();
  private robotCommands: GridCommand[] = [];
  private robotExecuting = false;
  private robotSprite?: RobotSprite;
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
  private pendingMissionBonusResult?: LogicGymBonusResult;
  private missionBonusResolvedThisCreate = false;

  constructor() {
    super("ProceduralMissionScene");
  }

  /** Walkable avatar for the Explore phase (agency layer over the hotspots). */
  private roomAvatar?: MissionRoomAvatar;
  /** Fullscreen explorable room (agency). Present when useExploreRoom() is on. */
  private explorer?: RoomExplorer;
  private wasOverlayOpen = false;

  init(data?: { autoOpenPuzzle?: ProceduralPuzzleId; missionBonusResult?: LogicGymBonusResult }): void {
    this.autoOpenPuzzle = data?.autoOpenPuzzle;
    this.pendingMissionBonusResult = data?.missionBonusResult;
    this.missionBonusResolvedThisCreate = false;
  }

  preload(): void {
    queueSceneAssets(this, "procedural", "story");
  }

  create(): void {
    this.resetSceneLifecycleState();
    this.run = this.ensureRun();
    audioManager.playMusic("labAmbience");
    VisualKit.applyCinematicGrade(this, "lab");
    noraPresence.mount(this, { x: 42, y: this.scale.height - 86, compact: true });
    const onRegenerate = () => this.isProgressiveMode() ? this.confirmProgressiveReset() : this.regenerate();
    const onHub = () => { this.pauseRunIfLeaving(); this.scene.start("MainMenuScene"); };
    const onNora = () => this.showNoraChargePanel();
    if (this.useExploreRoom()) {
      // Fullscreen explorable room + slim HUD (agency): walk to a console and
      // interact, instead of the click-only hotspot map.
      const chromeStart = this.children.list.length;
      const hud = ProceduralMissionView.createExploreChrome(this, this.run, onRegenerate, onHub, onNora);
      this.objectiveText = hud.objectiveText;
      this.progressText = hud.progressText;
      this.feedbackText = hud.feedbackText;
      const chromeObjects = this.children.list.slice(chromeStart);
      this.mountExploreRoom();
      // Route the slim HUD through the explorer's fixed UI camera so its buttons
      // stay clickable under the scrolling room camera.
      this.explorer?.markUi(chromeObjects);
    } else {
      ProceduralMissionView.drawShell(this, this.run);
      const hud = ProceduralMissionView.createHud(this, this.run, onRegenerate, onHub, onNora);
      this.objectiveText = hud.objectiveText;
      this.progressText = hud.progressText;
      this.feedbackText = hud.feedbackText;
      ProceduralMissionView.createHotspots(this, this.run, this.allPuzzlesSolved(), (hotspot) => this.openHotspot(hotspot));
      // Agency layer: a walkable avatar over the clickable hotspots (fallback).
      if (!this.isChapterTrial()) {
        const stageRect = SceneChrome.layout.stage;
        const consolePoints = sortProceduralHotspots(this.run.mission.map.hotspots)
          .map((hotspot) => ({ hotspot, ...proceduralHotspotPosition(hotspot, stageRect) }));
        this.roomAvatar = new MissionRoomAvatar(this, stageRect, consolePoints, this.run.seed, (hotspot) => this.openHotspot(hotspot));
      }
    }
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

    const bonusFeedback = this.consumeMissionBonusResult();
    feedbackSystem.publish(bonusFeedback ?? this.roomEntryFeedback(), bonusFeedback ? "success" : this.run.solvedPuzzleIds.length > 0 ? "success" : "info");
    // NORA greets once per run (the scene restarts between consoles, so gate by seed).
    if (this.noraGreetedSeed !== this.run.seed && this.run.solvedPuzzleIds.length === 0) {
      this.noraGreetedSeed = this.run.seed;
      this.time.delayedCall(520, () => this.noraSay("enter"));
    }
    this.time.delayedCall(80, () => this.showRunReadyOverlay());
    this.time.delayedCall(420, () => this.maybeShowMissionBonusOffer());
  }

  update(_time: number, delta: number): void {
    const overlayOpen = Boolean(this.overlay);
    this.roomAvatar?.update(delta, overlayOpen);
    if (this.explorer) {
      // On overlay open, reset the camera so fullscreen console overlays render
      // at screen coords; on close, resume following the avatar.
      if (overlayOpen && !this.wasOverlayOpen) this.explorer.pauseForOverlay();
      else if (!overlayOpen && this.wasOverlayOpen) this.explorer.resume();
      this.explorer.update(delta, overlayOpen);
    }
    this.wasOverlayOpen = overlayOpen;
  }

  /** Whether to render the fullscreen explorable room instead of the hotspot map. */
  private useExploreRoom(): boolean {
    return this.textures.exists("action-room-bg");
  }

  private mountExploreRoom(): void {
    this.explorer = new RoomExplorer(this, {
      worldW: 1760,
      worldH: 1120,
      bgTexture: "action-room-bg",
      walls: [
        { x: 0, y: 0, w: 1760, h: 40 },
        { x: 0, y: 1080, w: 1760, h: 40 },
        { x: 0, y: 0, w: 40, h: 1120 },
        { x: 1720, y: 0, w: 40, h: 1120 },
        { x: 520, y: 470, w: 70, h: 240 },
        { x: 1170, y: 470, w: 70, h: 240 },
      ] as RoomWall[],
      consoles: this.buildRoomConsoles(),
      seedKey: this.run.seed,
      onInteract: (console) => this.openHotspot(console.ref as GeneratedRoomHotspot),
    });
  }

  /** Maps the mission hotspots to console spots placed in the fullscreen world. */
  private buildRoomConsoles(): RoomConsole[] {
    const meta: Record<string, { asset?: string; glyph: string; color: number }> = {
      language: { asset: "italian", glyph: "✒️", color: 0x9f8cff },
      circuit: { asset: "electronics", glyph: "⚡", color: 0xf6c85f },
      math: { asset: "math", glyph: "➗", color: 0x6be7d6 },
      english: { asset: "english", glyph: "🌍", color: 0x7ad7ff },
      robot: { asset: "coding", glyph: "🤖", color: 0x7cf6a6 },
      coding: { asset: "coding", glyph: "💻", color: 0x7cf6a6 },
      music: { asset: "music", glyph: "🎵", color: 0xff9d5c },
      physics: { asset: "physics", glyph: "🔬", color: 0x7ad7ff },
      latin: { asset: "latin", glyph: "◇", color: 0xd8a24a },
    };
    const pool = [
      { x: 250, y: 250 }, { x: 710, y: 210 }, { x: 1180, y: 250 },
      { x: 900, y: 560 }, { x: 320, y: 840 }, { x: 760, y: 900 }, { x: 1180, y: 840 },
    ];
    const hotspots = sortProceduralHotspots(this.run.mission.map.hotspots);
    let poolIndex = 0;
    return hotspots.map((hotspot) => {
      const id = hotspot.puzzleId ?? hotspot.id;
      const isDoor = id === "door";
      const kind = proceduralHotspotKind(hotspot) ?? "";
      const m = meta[kind] ?? { glyph: "❔", color: 0x6be7d6 };
      const pos = isDoor ? { x: 1560, y: 560 } : (pool[poolIndex++ % pool.length]);
      const solved = isProceduralHotspotSolved(hotspot, this.run.solvedPuzzleIds);
      const failed = !isDoor && this.isFailed(id);
      return {
        id,
        assetId: isDoor ? "exit" : m.asset,
        label: hotspot.label,
        glyph: isDoor ? "🚪" : m.glyph,
        color: isDoor ? 0xffd75e : m.color,
        x: pos.x,
        y: pos.y,
        w: 120,
        h: 150,
        solved,
        state: isDoor ? (this.allPuzzlesSolved() ? "active" : "locked") : solved ? "resolved" : failed ? "failed" : "active",
        ref: hotspot,
      } satisfies RoomConsole;
    });
  }

  /** Speaks an in-character, context-aware NORA line for a beat. */
  private noraSay(beat: NoraBeat): void {
    const tone = beat === "victory" || beat === "solve" || beat === "streak" || beat === "bossDefeat" ? "success" : beat === "lifeLost" || beat === "lowLife" || beat === "defeat" || beat === "sabotage" ? "warning" : "info";
    const contextual = this.noraContextLine(beat);
    noraChip.say(this, contextual ?? noraVoice.line(beat), tone);
  }

  private noraContextLine(beat: NoraBeat): string | undefined {
    const contextBeat: Partial<Record<NoraBeat, NoraContextBeat>> = {
      enter: "enter",
      solve: "solve",
      streak: "streak",
      lifeLost: "mistake",
      lowLife: "lowLife",
      victory: "victory",
      defeat: "defeat",
      scaffold: "scaffold",
    };
    const mapped = contextBeat[beat];
    if (!mapped) return undefined;
    return noraContextEngine.line(mapped, {
      run: this.run,
      kind: this.activePuzzleKind,
      attempts: this.activePuzzleAttempts(),
      hintsUsed: this.activePuzzleHintsUsed(),
    });
  }

  /** Short, playful NORA beat on a streak milestone. */
  private cheerStreak(streak: number): void {
    if (streak === 3 || streak === 6 || streak === 10) {
      noraPresence.speak(this, noraContextEngine.line("streak", { run: this.run, kind: this.activePuzzleKind, streak }), "success");
    }
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
    if (this.explorer) {
      return this.isProgressiveMode()
        ? "Segui la console evidenziata."
        : "Scegli una console e premi E.";
    }
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
    return `NORA riconosce un punto da consolidare in ${puzzleKindLabel(kind)}: prima individua la prova, poi formula la risposta. La profondità resta stabile finché il metodo non diventa autonomo.`;
  }

  private availableNoraCharges(): number {
    const chargeStep = saveSystem.data.inventory.includes("nora-reserve") ? 1 : 2;
    const maxCharges = saveSystem.data.inventory.includes("nora-reserve") ? 3 : 2;
    const solvedEarned = Math.min(maxCharges, Math.floor(this.run.solvedPuzzleIds.length / chargeStep));
    const energyEarned = Math.min(maxCharges, Math.floor(outcomeFeedback.energyTotal(this) / (saveSystem.data.inventory.includes("nora-reserve") ? 160 : 220)));
    const earned = Math.max(solvedEarned, energyEarned);
    return Math.max(0, earned - (this.run.noraChargesUsed ?? 0));
  }

  private runEnergySummary(): string {
    return outcomeFeedback.energySummaryText(this);
  }

  energySubjectForFeedback(): string {
    if (this.languageMinigameSession) return "italiano";
    if (this.mathMinigameSession) return "matematica";
    if (this.englishMinigameSession) return "inglese";
    if (this.codingMinigameSession) return "coding";
    if (this.musicSession) return "musica";
    if (this.circuitMinigameSession) return "fisica";
    return "missioni procedurali";
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
    overlay.add(this.add.text(340, 252, "Hai collegato abbastanza sistemi o accumulato abbastanza energia-run da alimentare uno strumento di emergenza. Scegli un solo effetto.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 600 },
      lineSpacing: 5,
    }));
    const status = this.add.text(340, 456, `Cariche disponibili: ${this.availableNoraCharges()} · ${this.runEnergySummary()}`, {
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
    overlay.add(this.add.text(640, 244, resuming ? "Run in pausa" : trial ? "⚔️ Duello col Sabotatore" : explore ? "Fase Esplora" : "Console pronta", {
      fontFamily: "Inter, Arial",
      fontSize: trial ? "28px" : "32px",
      color: trial ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (trial && this.run.chapterMissionId) {
      const level = chapterTrialLevel(this.run.chapterMissionId);
      const minutes = Math.round(chapterTrialTimeMs(this.run.chapterMissionId) / 60_000);
      overlay.add(this.add.text(640, 282, `Profondità ${level}/8 · tutti i settori · ~${minutes} min · ogni errore gli dà terreno (−25s), ${CHAPTER_TRIAL_ERROR_BUDGET} margini`, {
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
    if (this.run.ghost) {
      overlay.add(this.add.text(640, 388, `⚔ Sfida fantasma: batti i ${this.run.ghost.targetScore} punti di ${this.run.ghost.playerName} — stessa stanza, stesso seed.`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f7d37a",
        fontStyle: "bold",
        align: "center",
        wordWrap: { width: 560 },
      }).setOrigin(0.5));
    }
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
    this.time.delayedCall(260, () => this.maybeShowMissionBonusOffer());
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

  private saveMissionBonusEvents(events: ProceduralBonusEventState): void {
    saveSystem.updateProceduralRun({ bonusEvents: compactMissionBonusEvents(events) });
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private consumeMissionBonusResult(): string | undefined {
    const result = this.pendingMissionBonusResult;
    if (!result) return undefined;
    this.pendingMissionBonusResult = undefined;
    this.missionBonusResolvedThisCreate = true;
    const events = normalizeMissionBonusEvents(this.run);
    this.saveMissionBonusEvents({
      ...events,
      offeredIds: [...events.offeredIds, result.id],
      resolvedIds: [...events.resolvedIds, result.id],
    });

    const rewardParts: string[] = [];
    if (result.passed && result.energyAward > 0) {
      outcomeFeedback.grantActivityBonus(this, result.energyAward, `frattura ${missionBonusActivityTitle(result.activityKey)}`);
      rewardParts.push(`+${result.energyAward} energia`);
    }
    if (result.passed && result.timeAwardMs > 0 && this.applyMissionBonusTime(result.timeAwardMs)) {
      rewardParts.push(`+${Math.round(result.timeAwardMs / 1000)}s timer`);
    }

    if (!result.passed) {
      return `Frattura energetica chiusa senza bonus: ${result.correct}/${result.rounds} corrette, precisione ${result.accuracy}%. Nessuna penalità applicata.`;
    }
    return `Frattura energetica superata: ${result.label}, ${result.correct}/${result.rounds} corrette, precisione ${result.accuracy}%. ${rewardParts.length > 0 ? `Ricompensa: ${rewardParts.join(" · ")}.` : "Ricompensa registrata."}`;
  }

  private applyMissionBonusTime(timeAwardMs: number): boolean {
    if (timeAwardMs <= 0 || !proceduralRunRules.pressureEnabledFor(this.run)) return false;
    if (this.run.pausedRemainingMs !== undefined || this.run.timerState === "paused") {
      const base = this.run.pausedRemainingMs ?? this.run.timeLimitMs ?? 0;
      saveSystem.updateProceduralRun({ pausedRemainingMs: base + timeAwardMs });
      this.run = saveSystem.data.proceduralRun ?? this.run;
      return true;
    }
    if (this.run.deadlineAt) {
      const currentDeadline = new Date(this.run.deadlineAt).getTime();
      saveSystem.updateProceduralRun({
        deadlineAt: new Date(Math.max(Date.now(), currentDeadline) + timeAwardMs).toISOString(),
      });
      this.run = saveSystem.data.proceduralRun ?? this.run;
      return true;
    }
    return false;
  }

  private maybeShowMissionBonusOffer(): void {
    if (this.missionBonusResolvedThisCreate || this.pendingMissionBonusResult || this.overlay) return;
    if (this.runMode() !== "mission" || this.isChapterExplore()) return;
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) return;
    const solvedCount = this.run.solvedPuzzleIds.length;
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id));
    if (solvedCount <= 0 || remaining.length === 0) return;

    const events = normalizeMissionBonusEvents(this.run);
    const maxEvents = missionBonusEventLimit(this.isChapterTrial());
    if (events.offeredIds.length >= maxEvents) return;
    const eventId = `${this.run.seed}:bonus:${solvedCount}`;
    if (
      events.offeredIds.includes(eventId)
      || events.resolvedIds.includes(eventId)
      || events.skippedIds.includes(eventId)
    ) {
      return;
    }
    if (!shouldOfferMissionBonus(eventId, solvedCount, events.offeredIds.length, this.run.difficulty, this.isChapterTrial())) return;
    const lastSolved = this.run.solvedPuzzleIds[this.run.solvedPuzzleIds.length - 1] ?? "";
    const activityKey = selectMissionBonusActivity(eventId, lastSolved);
    this.showMissionBonusOffer(eventId, activityKey);
  }

  private showMissionBonusOffer(eventId: string, activityKey: LogicGymBonusActivityKey): void {
    const events = normalizeMissionBonusEvents(this.run);
    this.saveMissionBonusEvents({ ...events, offeredIds: [...events.offeredIds, eventId] });
    const offeredCount = normalizeMissionBonusEvents(this.run).offeredIds.length;
    this.overlay = createMissionBonusOfferOverlay({
      scene: this,
      activityKey,
      difficulty: this.run.difficulty,
      offeredCount,
      maxEvents: missionBonusEventLimit(this.isChapterTrial()),
      onAccept: () => {
        audioManager.playOutcome("complete");
        saveSystem.pauseActiveProceduralRun();
        this.run = saveSystem.data.proceduralRun ?? this.run;
        this.clearOverlay();
        void startScene(this, "LogicGymScene", {
          mode: "missionBonus",
          activityKey,
          bonusId: eventId,
          level: this.run.difficulty,
          rounds: missionBonusRounds(activityKey, this.run.difficulty),
          returnScene: "ProceduralMissionScene",
        }).catch(() => {
          feedbackSystem.publish("Non sono riuscito ad aprire la frattura energetica. La missione resta in pausa e può riprendere.", "warning");
          this.showRunReadyOverlay(true);
        });
      },
      onSkip: () => {
        const current = normalizeMissionBonusEvents(this.run);
        this.saveMissionBonusEvents({ ...current, skippedIds: [...current.skippedIds, eventId] });
        audioManager.playOutcome("neutral");
        this.clearOverlay();
        feedbackSystem.publish("Frattura ignorata: nessun premio, nessuna penalità. La missione continua.", "info");
      },
    });
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
    this.sprintPauseStartedAt = undefined;
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
      if (runNeedsContentMigration(normalized)) {
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
    const run = buildFreshProceduralRun({
      mission,
      focus: ["libera"],
      mode: "mission",
      pressureEnabled,
      timeLimitMs,
      maxLives: proceduralRunRules.maxLives,
      createdAt,
    });
    saveSystem.setProceduralRun(run);
    return run;
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
    const replacement = buildReplacementProceduralRun({
      legacyRun: run,
      mission,
      focus,
      mode,
      pressureEnabled,
      timeLimitMs,
      maxLives: proceduralRunRules.maxLives,
      createdAt,
      progressiveLevelTimeLimitMs: timeLimitMs ?? progressiveMissionBuilder.timeLimitMs(run.difficulty, Math.max(1, mission.objectives.length)),
    });
    saveSystem.setProceduralRun(replacement);
    return replacement;
  }

  private normalizeRunRules(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    const pressureEnabled = proceduralRunRules.pressureEnabledFor(run);
    const timeLimitMs = pressureEnabled ? (run.timeLimitMs ?? (mode === "progressive"
      ? progressiveMissionBuilder.timeLimitMs(run.progressive?.currentLevel ?? run.difficulty, Math.max(1, run.mission.objectives.length))
      : proceduralRunRules.missionTimeLimitMs(run.difficulty, Math.max(1, run.mission.objectives.length)))) : undefined;
    const update = buildRunNormalizationUpdate({
      run,
      mode,
      pressureEnabled,
      timeLimitMs,
      maxLives: proceduralRunRules.maxLives,
    });
    if (update) {
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
    saveSystem.setProceduralRun(buildFreshProceduralRun({
      mission,
      focus: this.run.focus,
      mode,
      pressureEnabled,
      timeLimitMs,
      maxLives: proceduralRunRules.maxLives,
      createdAt,
    }));
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
    overlay.add(this.add.text(370, 282, `Sei alla profondità ${currentLevel}/8 e hai completato ${completedLevels} settori.\n\nIl reset elimina progressi, risultati, punti e tempo della scalata corrente. Missioni normali, focus e registro non vengono modificati.`, {
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
    overlay.add(new Button(this, 770, 476, "Riparti dalla profondità 1", () => {
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
    return buildProgressiveProceduralRun({
      level,
      levelFocus,
      mission,
      createdAt,
      timeLimitMs,
      previousResults,
      maxLives: proceduralRunRules.maxLives,
    });
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
      feedbackSystem.publish(`Sequenza guidata: prima completa ${puzzleKindLabel(nextProgressivePuzzle)}.`, "hint");
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
      latin: () => this.openLatin(),
      circuit: () => this.openCircuit(),
      math: () => this.openMath(),
      english: () => this.openEnglish(),
      robot: () => this.openRobot(),
      coding: () => this.openCoding(),
      music: () => this.openMusic(),
      physics: () => this.openPhysics(),
    };
    if (systemId === "latin" || proceduralPuzzleOrder.includes(systemId)) {
      if (this.activePuzzleId !== puzzleId) {
        this.resetTransientPuzzleState();
      }
      this.activePuzzleId = puzzleId;
      this.activePuzzleKind = systemId;
      this.activeChallenge = challenge;
      this.ensurePuzzleTimer(puzzleId);
      this.playPuzzleContextSound(systemId);
      handlers[systemId]();
      if (this.runMode() !== "training") {
        noraPresence.speak(this, noraContextEngine.line("open", { run: this.run, kind: systemId }), "info", 3600);
      } else {
        noraPresence.pulse(this, "thinking");
      }
      this.maybeIntroduceConcept(systemId);
      this.maybeAutoScaffold(systemId);
    }
  }

  /**
   * Apprendimento graduale: la prima volta che il giocatore incontra un
   * concetto, NORA apre da sola la scheda teorica (spiegazione, metodo,
   * esempio guidato) PRIMA di lasciarlo all'esercizio. Dalla seconda volta la
   * teoria resta a un tocco sul pulsante "Teoria NORA". Saltato nelle prove a
   * tempo con vite (lì si testa, non si impara) e nella Torre.
   */
  private maybeIntroduceConcept(kind: ProceduralPuzzleId): void {
    if (this.isTimedMissionMode() || this.isProgressiveMode() || this.isChapterTrial()) {
      return;
    }
    const topic = theoryTopicForPuzzle(kind, this.currentPuzzleForTheory(kind));
    if (!topic || saveSystem.isConceptIntroduced(topic.id)) {
      return;
    }
    saveSystem.markConceptIntroduced(topic.id);
    feedbackSystem.publish(`Concetto nuovo: «${topic.title}». NORA te lo spiega — poi tocca a te.`, "hint");
    this.runWhenActive(520, () => {
      if (this.activePuzzleKind !== kind || this.isRunInteractionLocked()) {
        return;
      }
      // Il timer dello sprint è già partito quando la console si è aperta: metti
      // in pausa il conteggio mentre lo studente legge la spiegazione, così il
      // tempo speso a IMPARARE non gli viene tolto dalla gara.
      this.pauseActiveSprintClocks();
      showFirstEncounterPanel(
        this,
        topic,
        (opened) => {
          this.resumeActiveSprintClocks();
          void startScene(this, "MathStudyScene", { pageId: opened.id }).catch(() => {
            feedbackSystem.publish("Non riesco ad aprire l'Atlante in questo momento: riprova tra un istante.", "warning");
          });
        },
        () => {
          this.resumeActiveSprintClocks();
          feedbackSystem.publish("Perfetto: ora tocca a te. Applica quello che hai appena visto.", "success");
        },
      );
    });
  }

  /** Sessioni a tempo attive (ne è aperta al più una alla volta). */
  private activeSprintSessions(): Array<{ startedAt: number; questionStartedAt?: number }> {
    return [
      this.mathMinigameSession,
      this.languageMinigameSession,
      this.englishMinigameSession,
      this.codingMinigameSession,
      this.circuitMinigameSession,
      this.musicSession,
    ].filter((session): session is NonNullable<typeof session> => Boolean(session));
  }

  private sprintPauseStartedAt?: number;

  private isSprintPaused(): boolean {
    return this.sprintPauseStartedAt !== undefined;
  }

  /** Congela il conteggio dello sprint (ricorda il momento della pausa). */
  private pauseActiveSprintClocks(): void {
    if (this.sprintPauseStartedAt !== undefined) return;
    this.sprintPauseStartedAt = Date.now();
  }

  /** Riprende lo sprint spostando in avanti startedAt della durata della pausa. */
  private resumeActiveSprintClocks(): void {
    if (this.sprintPauseStartedAt === undefined) return;
    const paused = Date.now() - this.sprintPauseStartedAt;
    this.sprintPauseStartedAt = undefined;
    if (paused <= 0) return;
    for (const session of this.activeSprintSessions()) {
      if (session.startedAt > 0) session.startedAt += paused;
      if (session.questionStartedAt !== undefined && session.questionStartedAt > 0) {
        session.questionStartedAt += paused;
      }
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
    noraPresence.speak(this, noraContextEngine.line("scaffold", { run: this.run, kind }), "info");
  }

  private currentPuzzleHintsFor(kind: ProceduralPuzzleId): string[] {
    switch (kind) {
      case "language": return puzzleHintTexts(this.currentLanguagePuzzle());
      case "latin": return puzzleHintTexts(this.currentLatinPuzzle());
      case "circuit": return puzzleHintTexts(this.currentCircuitPuzzle());
      case "math": return puzzleHintTexts(this.currentMathPuzzle());
      case "english": return puzzleHintTexts(this.currentEnglishPuzzle());
      case "robot": return puzzleHintTexts(this.currentRobotPuzzle());
      case "coding": return puzzleHintTexts(this.currentCodingPuzzle());
      case "music": return puzzleHintTexts(this.currentMusicPuzzle());
      case "physics": return puzzleHintTexts(this.currentPhysicsPuzzle());
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
    LanguageRepairConsole.addBrief(this, overlay, model, this.currentActiveHint());
    LanguageRepairConsole.addChoicePanel(this, overlay, model, {
      selectedOption: this.languageSelectedOption,
      hintLabel: hintButtonLabel(puzzle, this.activePuzzleHintsUsed(), "Indizio mirato"),
    }, {
      onSelect: (option) => {
        this.languageSelectedOption = option;
        this.openLanguage();
      },
      onOpenBuilder: () => this.openLanguageBuilder(puzzle, model),
      onConfirm: () => this.confirmLanguageReasoning(puzzle, model),
      onHint: () => {
        this.useContextualHint(puzzle);
        this.openLanguage();
      },
    });
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
    LanguageRepairConsole.addBrief(this, overlay, model, this.currentActiveHint());
    LanguageRepairConsole.addBuilderPanel(this, overlay, {
      shuffledWords: this.languageBuilderShuffled,
      placedIndices: this.languageBuilderPlaced,
    }, {
      onToggleWord: (index) => {
        if (this.languageBuilderPlaced.includes(index)) {
          this.languageBuilderPlaced = this.languageBuilderPlaced.filter((i) => i !== index);
        } else {
          this.languageBuilderPlaced.push(index);
        }
        audioManager.play("click");
        this.openLanguageBuilder(puzzle, model);
      },
      onBack: () => this.openLanguage(),
      onConfirm: () => this.confirmLanguageBuilder(puzzle, model),
      onClear: () => {
        this.languageBuilderPlaced = [];
        audioManager.play("cancel");
        this.openLanguageBuilder(puzzle, model);
      },
    });
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

  // ===== Latino (console a domanda singola: analizza la forma e scegli) =====
  private currentLatinPuzzle(): GeneratedLatinPuzzle {
    const challenge = this.activeChallenge;
    if (challenge?.kind === "latin") return challenge.puzzle;
    if (this.run.mission.puzzles.latin) return this.run.mission.puzzles.latin;
    return new LatinGenerator().generateMinigame(new Random(`${this.run.seed}:latin-fallback`), this.run.difficulty);
  }

  private openLatin(): void {
    const puzzle = this.currentLatinPuzzle();
    const prompt = puzzle.minigame.prompts[0];
    const overlay = this.createExerciseScreen(`Latino · ${prompt.targetLabel}`);

    this.addMathPanel(overlay, 28, 112, 548, 432, "1 · Leggi e analizza la forma");
    overlay.add(this.add.text(60, 152, prompt.targetLabel, { fontFamily: "Inter, Arial", fontSize: "26px", color: "#f7d37a", fontStyle: "bold" }));
    overlay.add(this.add.rectangle(60, 200, 484, 96, 0x102533, 0.9).setOrigin(0).setStrokeStyle(1, 0xd8a24a, 0.55));
    overlay.add(this.add.text(78, 214, prompt.context, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: 452 }, lineSpacing: 5 }));
    if (prompt.reference) {
      overlay.add(this.add.text(60, 316, prompt.reference, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", wordWrap: { width: 480 }, lineSpacing: 4 }));
    }
    overlay.add(this.add.text(60, 396, `Concetto: ${prompt.concept}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold", wordWrap: { width: 480 } }));
    const activeHint = this.currentActiveHint();
    if (activeHint) overlay.add(this.add.text(60, 430, activeHint, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", wordWrap: { width: 480 }, lineSpacing: 3 }));

    this.addMathPanel(overlay, 604, 112, 648, 432, "2 · Scegli la risposta");
    overlay.add(this.add.text(636, 152, "Leggi la domanda, clicca UNA tessera e premi Conferma.", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1", wordWrap: { width: 560 } }));
    overlay.add(this.add.text(636, 198, prompt.prompt, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: 560 }, lineSpacing: 5 }));
    const tileStartX = 784;
    const tileStartY = 338;
    prompt.tiles.forEach((tile, index) => {
      const selected = this.latinSelectedLabel === tile.label;
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(new Button(this, tileStartX + col * 258, tileStartY + row * 70, `${selected ? "✓ " : ""}${tile.label}`, () => {
        this.latinSelectedLabel = tile.label;
        audioManager.play("click");
        this.openLatin();
      }, {
        width: 236, height: 54, fontSize: tile.label.length > 22 ? 12 : 15, wordWrapWidth: 214,
        fill: selected ? 0x174d42 : 0x263743, stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });

    this.addMathPanel(overlay, 28, 558, 1224, 130, "3 · Conferma e controlla l'esito");
    overlay.add(this.add.text(64, 592, puzzle.difficultyLabel ?? "Latino", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold" }));
    overlay.add(this.add.text(64, 620, puzzle.method ?? "Analizza la desinenza, poi assegna caso, numero, tempo o funzione.", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0", wordWrap: { width: 680 } }));
    overlay.add(new Button(this, 1080, 640, "Conferma", () => this.confirmLatin(puzzle), { width: 220, height: 44, fontSize: 14, fill: 0x173b36 }));
    overlay.add(new Button(this, 820, 640, "Indizio", () => { this.useContextualHint(puzzle); this.openLatin(); }, { width: 180, height: 44, fontSize: 13, fill: 0x263743 }));
  }

  private confirmLatin(puzzle: GeneratedLatinPuzzle): void {
    const prompt = puzzle.minigame.prompts[0];
    const label = this.latinSelectedLabel;
    if (!label) {
      audioManager.playOutcome("hint");
      feedbackSystem.publish("Prima seleziona una risposta.", "hint");
      return;
    }
    const correctTile = prompt.tiles.find((tile) => tile.isCorrect)!;
    if (label === correctTile.label) {
      outcomeFeedback.answer(this, true, label, correctTile.label, prompt.explanation);
      this.latinSelectedLabel = undefined;
      this.solvePuzzle(this.currentPuzzleId("latin"), puzzle.competencies);
      return;
    }
    const wrongTile = prompt.tiles.find((tile) => tile.label === label);
    outcomeFeedback.answer(this, false, label, correctTile.label, wrongTile?.feedback ?? prompt.explanation);
    this.latinSelectedLabel = undefined;
    const exited = this.handleIncorrectAnswer(wrongTile?.feedback ?? puzzle.hints[0]);
    if (!exited) this.openLatin();
  }

  private openLanguageMinigame(puzzle: GeneratedLanguagePuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("language");
    const session = this.ensureLanguageMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const prompt = this.currentLanguageMinigamePrompt(session);
    const showCoach = this.shouldShowExerciseCoach("language");
    const overlay = this.createMathOverlay(`Italiano · ${prompt.targetLabel}`, this.compactExerciseSubtitle("language", puzzle.minigame.reflective
      ? "Italiano · modalità riflessiva: leggi con calma, poi scegli"
      : "Italiano · leggi la consegna, scegli una risposta, conferma"));
    const remaining = this.languageMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.addMathPanel(overlay, 28, 112, 548, 432, showCoach ? "1 · Leggi e individua la regola" : "Consegna");
    overlay.add(this.add.text(60, 154, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "27px",
      color: "#f7d37a",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    this.drawLanguageMinigameVisualizer(overlay, prompt, 60, 210, 482, 210, showCoach);
    overlay.add(this.add.text(60, showCoach ? 456 : 438, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 472 },
    }));

    const isOrdering = prompt.type === "word-order";
    const isTyped = prompt.inputMode === "typed";
    this.addMathPanel(overlay, 604, 112, 648, 432, showCoach ? (isOrdering ? "2 · Ricomponi il comando" : isTyped ? "2 · Scrivi la risposta" : "2 · Scegli una risposta") : (isTyped ? "Risposta" : prompt.targetLabel));
    if (showCoach) {
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
    }
    overlay.add(this.add.text(636, showCoach ? (isOrdering ? 192 : 214) : 164, prompt.prompt, {
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
      if (showCoach) {
        overlay.add(this.add.text(636, 420, "Scrivi con calma: conta numero e genere del soggetto.", {
          fontFamily: "Inter, Arial",
          fontSize: "13px",
          color: "#9aaab0",
          wordWrap: { width: 560 },
        }));
      }
    } else {
      const tileStartX = 784;
      const tileStartY = 340;
      prompt.tiles.forEach((tile, index) => {
        const selected = session.selectedIds.has(tile.id);
        const col = index % 2;
        const row = Math.floor(index / 2);
        overlay.add(new Button(this, tileStartX + col * 258, tileStartY + row * 68, choiceTileLabel(tile.label, selected), () => this.toggleLanguageMinigameTile(tile.id), {
          width: 232,
          height: 52,
          fontSize: choiceTileFontSize(tile.label, 16),
          wordWrapWidth: 210,
          fill: selected ? 0x174d42 : 0x263743,
          stroke: selected ? 0xf7d37a : 0x6be7d6,
        }));
      });
    }

    this.addMathPanel(overlay, 28, 558, 1224, 130, showCoach ? "3 · Conferma e controlla l'esito" : "Esito");
    this.languageMinigameTimerText = this.add.text(64, 604, `Tempo: ${formatDuration(remaining)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: remaining <= 10_000 && !puzzle.minigame.reflective ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(this.languageMinigameTimerText);
    overlay.add(this.add.text(260, 592, `Serie: ${session.streak}    ·    Punti: ${session.netScore}    ·    Precisione: ${accuracy}%`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 640 },
      lineSpacing: 4,
    }));
    if (showCoach || session.feedback) {
      overlay.add(this.add.text(260, 636, session.feedback || puzzle.minigame.scoringRule, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: session.feedback ? "#f7d37a" : "#9aaab0",
        wordWrap: { width: 390, useAdvancedWrap: true },
      }));
    }
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
    // Mix exercise types whenever this is NOT a focused italiano training run
    // (staged single-type). Story/libera missions therefore alternate accordi,
    // verbi/modi-tempi, connettivi, ortografia, lessico… instead of repeating one
    // authored sentence.
    const mixTypes = this.isProgressiveMode() || !this.run.focus.includes("italiano");
    const types = mixTypes ? this.progressiveLanguageSprintTypes(game.type) : [game.type];
    const freshPrompts = types.flatMap((type, index) =>
      generator.generateMinigame(random.fork(`mix-${type}-${index}`), this.run.difficulty, [type]).minigame?.prompts ?? [],
    );
    const variedGame = {
      ...game,
      title: mixTypes ? "Sprint italiano: percorso variato" : game.title,
      instructions: mixTypes
        ? "alterni accordi, verbi, connettivi, ortografia, lessico, intrusi e ordine delle parole: leggi l'obiettivo prima di cliccare."
        : game.instructions,
      prompts: random.shuffle(freshPrompts.length ? freshPrompts : game.prompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })),
    };
    const showCoach = this.shouldShowExerciseCoach("language");
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
      feedback: showCoach
        ? mixTypes
          ? "Percorso variato: ogni domanda può cambiare scopo. Prima leggi l'obiettivo, poi scegli."
          : "Leggi prima l'obiettivo: accordo, connettivo, intruso o ordine. Poi conferma."
        : "",
      locked: false,
      summaryOpen: false,
    };
    return this.languageMinigameSession;
  }

  private progressiveLanguageSprintTypes(baseType: LanguageMinigameType): LanguageMinigameType[] {
    const rotation: LanguageMinigameType[] = ["agreement-sprint", "verb-mastery", "punctuation-fix", "connector-route", "intruder-hunt", "word-order", "lexicon-lab"];
    return [baseType, ...rotation.filter((type) => type !== baseType)];
  }

  private drawLanguageMinigameVisualizer(
    overlay: Phaser.GameObjects.Container,
    prompt: LanguageMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
    showCoach = true,
  ): void {
    const g = this.add.graphics();
    g.fillStyle(0x07151d, 0.78);
    g.fillRoundedRect(x, y, width, height, 12);
    g.lineStyle(2, 0x6be7d6, 0.3);
    g.strokeRoundedRect(x, y, width, height, 12);
    overlay.add(g);

    const accent = prompt.type === "agreement-sprint" ? 0x6be7d6
      : prompt.type === "connector-route" ? 0xf6c85f
        : prompt.type === "verb-mastery" ? 0x70d68a
          : prompt.type === "punctuation-fix" ? 0xffb86b
            : 0x9f8cff;
    overlay.add(this.add.rectangle(x + 26, y + 34, width - 52, 74, 0x102533, 0.8)
      .setOrigin(0)
      .setStrokeStyle(1, accent, 0.45));
    overlay.add(this.add.text(x + 44, y + 52, prompt.context, {
      fontFamily: "Inter, Arial",
      fontSize: !showCoach ? (prompt.context.length > 92 ? "15px" : "18px") : prompt.context.length > 92 ? "13px" : "16px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: width - 88, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
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
    if (!session || session.summaryOpen || this.isSprintPaused()) {
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
          : prompt.type === "lexicon-lab"
            ? "Chiediti quale parola rende il messaggio più preciso: prova, ipotesi, diagnosi e opinione non sono sinonimi."
            : prompt.type === "punctuation-fix"
              ? "Nomina la funzione: verbo essere, congiunzione, pronome, troncamento o elisione. Poi scegli accento o apostrofo."
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
    VisualKit.worldReact(this, "correct", { subtle: true });
    this.cheerStreak(session.streak);
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
    return "Calibrazione utile: ora lavora sulle serie corrette, non solo sul singolo colpo.";
  }

  private showLanguageMinigameSummary(session: LanguageMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const passed = this.languageMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    addSprintSummaryModal(this, overlay, {
      title: passed ? "Sprint italiano completato" : "Sprint italiano da consolidare",
      passed,
      correct: session.correct,
      wrong: session.wrong,
      accuracy,
      bestStreak: session.bestStreak,
      netScore: session.netScore,
      feedback: this.languageMinigameFeedback(session),
      resolutionText: (mode === "mission" || mode === "progressive")
        ? passed
          ? "La console italiana accetta il log: forma, coesione e pertinenza sono abbastanza stabili."
          : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
        : "Calibrazione registrabile: contano rapidità, precisione, serie positiva e uso consapevole degli aiuti.",
      energyText: this.runEnergySummary(),
      actionLabel: (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua",
    }, {
      onAction: (modal) => {
        modal.destroy(true);
        if (!passed && (mode === "mission" || mode === "progressive")) {
          this.loseMissionLife("sprint italiano sotto soglia: servono più risposte corrette con meno tentativi.");
          return;
        }
        this.completeLanguageMinigame(session);
      },
    });
  }

  private completeSprintMinigameOutcome(options: CompleteSprintMinigameOptions): void {
    const { session, score } = options;
    const solvedKind = puzzleKindFromId(session.puzzleId);
    saveSystem.markProceduralPuzzleSolved(session.puzzleId);
    this.run = saveSystem.data.proceduralRun ?? this.run;
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedKind);
    const outcome = buildSprintCompletionOutcome({
      solvedKind,
      correct: session.correct,
      wrong: session.wrong,
      bestStreak: session.bestStreak,
      difficulty: this.run.difficulty,
      scoreTotal: score.total,
      energySummary: this.runEnergySummary(),
      remainingLabels: remaining.map(puzzleKindLabel),
      copy: options.copy,
      maxScoreBonus: options.maxScoreBonus,
      scoreDivisor: options.scoreDivisor,
    });
    if (outcome.shouldRecordAutonomy) {
      saveSystem.recordMasteryAutonomy(options.masteryBranchId ?? masterySystem.branchForPuzzleKind(outcome.solvedKind));
    }
    competencyTracker.award(options.competencies, outcome.competencyAward);
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${score.total}`);
    this.clearOverlay();
    options.clearSession();
    feedbackSystem.publish(outcome.feedback, "success");
    if (remaining.length === 0) {
      this.certifyCompletedRun(outcome.certification);
      return;
    }
    this.runWhenActive(options.restartDelayMs, () => this.scene.restart());
  }

  private completeLanguageMinigame(session: LanguageMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeLanguageMinigameScore(session);
    this.completeSprintMinigameOutcome({
      session,
      score,
      competencies: session.game.competencies,
      copy: {
        summaryName: "Sprint italiano",
        certification: "Console italiana stabilizzata: il sistema completo è certificabile.",
      },
      clearSession: () => {
        this.languageMinigameSession = undefined;
      },
      restartDelayMs: 1750,
    });
  }

  private finalizeLanguageMinigameScore(session: LanguageMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.languageMinigameElapsedMs(session)));
    const score = buildLanguageMinigameScore(session, run, existing, elapsedMs, this.languageMinigameFeedback(session));
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
    return score;
  }

  private openCircuit(): void {
    const puzzle = this.currentCircuitPuzzle();
    if (puzzle.minigame) {
      this.openCircuitMinigame(puzzle);
      return;
    }
    const model = CircuitConsole.fromPuzzle(puzzle);
    const conceptLocked = model.componentChallenges.length > 0 && !this.circuitConceptVerified;
    const overlay = this.createExerciseScreen(model.title);
    CircuitConsole.addIntro(this, overlay, model, {
      conceptLocked,
      showCoach: this.shouldShowExerciseCoach("circuit"),
    });

    this.drawCircuitDiagnostic(overlay, model);
    CircuitConsole.addSidePanel(this, overlay, model, {
      conceptLocked,
      inspected: this.circuitInspected,
      conceptIndex: this.circuitConceptIndex,
    });

    if (conceptLocked) {
      this.drawCircuitComponentChallenge(overlay, model);
      return;
    }

    if (!this.circuitInspected) {
      CircuitConsole.addTesterPrompt(this, overlay, {
        onInspect: () => {
          this.circuitInspected = true;
          audioManager.playOutcome("neutral");
          feedbackSystem.publish("Tester collegato: leggi una misura alla volta e cerca il primo tratto che non funziona.", "info");
          this.openCircuit();
        },
      });
      return;
    }

    CircuitConsole.addRepairPanel(this, overlay, model, {
      selectedRepairs: this.selectedRepairs,
    }, {
      onToggleRepair: (fault) => {
        const selected = this.selectedRepairs.has(fault);
        if (selected) {
          this.selectedRepairs.delete(fault);
        } else {
          this.selectedRepairs.add(fault);
        }
        audioManager.play("click");
        this.openCircuit();
      },
      onTestCircuit: () => {
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
          this.handleIncorrectAnswer(`${message} ${nextPedagogicHint(puzzle, this.activePuzzleHintsUsed(), puzzle.hints[0] ?? "Rileggi il tester e collega sintomo a causa.")}`);
        });
      },
    });
  }

  private drawCircuitComponentChallenge(overlay: Phaser.GameObjects.Container, model: CircuitConsoleModel): void {
    const challenge = model.componentChallenges[Math.min(this.circuitConceptIndex, model.componentChallenges.length - 1)];
    if (!challenge) {
      this.circuitConceptVerified = true;
      this.openCircuit();
      return;
    }
    CircuitConsole.addComponentChallenge(this, overlay, challenge, {
      conceptIndex: this.circuitConceptIndex,
      total: model.componentChallenges.length,
      selectedAnswer: this.circuitSymbolAnswer,
    }, {
      onSelect: (choice) => {
        this.circuitSymbolAnswer = choice;
        audioManager.play("click");
        this.openCircuit();
      },
      onConfirm: (selectedChallenge) => this.confirmCircuitComponentChallenge(selectedChallenge, model),
    });
  }

  private confirmCircuitComponentChallenge(challenge: CircuitComponentChallenge, model: CircuitConsoleModel): void {
    if (!this.circuitSymbolAnswer) {
      feedbackSystem.publish("Scegli il nome del pezzo cerchiato.", "hint");
      audioManager.playOutcome("hint");
      return;
    }
    const symbolOk = this.circuitSymbolAnswer === challenge.correctSymbol;
    const selectedAnswer = this.circuitSymbolAnswer;
    const correctAnswer = challenge.correctSymbol;
    if (symbolOk) {
      outcomeFeedback.answer(this, true, selectedAnswer, correctAnswer, challenge.explanation);
      audioManager.playOutcome("correct");
      outcomeFeedback.play(this, "success", challenge.componentLabel);
      feedbackSystem.publish(`Componente riconosciuto: ${challenge.explanation}`, "success");
      this.circuitConceptIndex += 1;
      this.circuitSymbolAnswer = undefined;
      if (this.circuitConceptIndex >= model.componentChallenges.length) {
        this.circuitConceptVerified = true;
        feedbackSystem.publish("Pezzi riconosciuti: ora puoi usare il tester e cercare dove si ferma il giro.", "success");
      }
      this.openCircuit();
      return;
    }
    const message = `Questo nome non corrisponde al pezzo cerchiato. ${challenge.explanation}`;
    outcomeFeedback.answer(this, false, selectedAnswer, correctAnswer, challenge.explanation);
    const exited = this.handleIncorrectAnswer(message);
    if (!exited) {
      this.circuitSymbolAnswer = undefined;
      this.openCircuit();
    }
  }

  private circuitConceptLocked(): boolean {
    const puzzle = this.currentCircuitPuzzle();
    return Boolean((puzzle.componentChallenges?.length ?? 0) > 0 && !this.circuitConceptVerified);
  }

  private currentCircuitComponentTargetId(): string | undefined {
    const challenges = this.currentCircuitPuzzle().componentChallenges ?? [];
    return challenges[Math.min(this.circuitConceptIndex, challenges.length - 1)]?.componentId;
  }

  private drawCircuitDiagnostic(overlay: Phaser.GameObjects.Container, model: CircuitConsoleModel): void {
    CircuitConsole.addDiagnostic(this, overlay, model, {
      activeFaults: new Set(model.requiredRepairs.filter((fault) => !this.selectedRepairs.has(fault))),
      conceptLocked: this.circuitConceptLocked(),
      lit: this.circuitWouldLight(),
      targetComponentId: this.currentCircuitComponentTargetId(),
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

    MathTerminal.addBriefing(this, overlay, model);
    MathTerminal.addLogicVisualizer(this, overlay, puzzle, model, 430, 102, 500, 438);
    MathTerminal.addAnswerConsole(this, overlay, { entry: this.mathEntry }, {
      onKey: (key) => this.pressMathKey(key),
    });
    this.mathSupportText = MathTerminal.addSupportPanel(this, overlay, model, {
      showCoach: this.shouldShowExerciseCoach("math"),
      supportMessage: this.mathSupportMessage,
    }, {
      onHint: () => this.showMathSupport(nextPedagogicHint(puzzle, this.activePuzzleHintsUsed(), puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])),
    });
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
    EquationLabView.draw(this, overlay, puzzle, stage.visual, 60, 274, 636, 246);

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

    const showCoach = this.shouldShowExerciseCoach("math");
    this.addMathPanel(overlay, 28, 572, 1224, 116, showCoach ? "Percorso e metodo" : "Percorso");
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
    overlay.add(this.add.text(760, 604, this.currentActiveHint() ?? (showCoach ? `Metodo: ${puzzle.calculationAid?.strategy ?? puzzle.hints[0]}` : "Spiegazione disponibile se serve."), {
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

  private openGraphWorkshop(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    this.ensureGraphWorkshopState(puzzle);
    const overlay = this.createMathOverlay(
      puzzle.title,
      "Officina dei Grafici · leggi i dati, costruisci l'equazione, verifica sul piano cartesiano",
    );
    const values = this.graphWorkshopValues;
    const needsReading = this.graphWorkshopNeedsReading(workshop);
    const readingComplete = !needsReading || this.graphWorkshopReadingComplete(workshop);
    const showActiveCurve = !needsReading || this.graphWorkshopApplied;

    this.addMathPanel(overlay, 28, 112, 840, 488, "Piano cartesiano interattivo");
    GraphWorkshopView.drawCartesian(this, overlay, workshop, values, 52, 154, 792, 414, showActiveCurve);

    this.addMathPanel(overlay, 892, 112, 360, 488, needsReading ? "Taccuino di lettura" : "Console dei parametri");
    overlay.add(this.add.text(920, 154, workshop.objective, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 304, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(920, 220, 304, 48, 0x06131c, 0.9).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.36));
    overlay.add(this.add.text(1072, 244, needsReading && !this.graphWorkshopApplied ? this.graphWorkshopNotebookFormula(workshop) : GraphWorkshopView.formula(workshop, values), {
      fontFamily: "Georgia, 'Times New Roman', serif",
      fontSize: "20px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (needsReading) {
      if (!readingComplete) {
        this.drawGraphReadingPanel(overlay, puzzle, workshop);
      } else if (!this.graphWorkshopApplied) {
        this.drawGraphApplyPanel(overlay, puzzle, workshop);
      } else {
        this.drawGraphLockedParameterPanel(overlay, workshop);
      }
    } else {
      overlay.add(this.add.text(920, 282, "Modifica un parametro alla volta, poi Certifica le proprietà esatte.", {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", wordWrap: { width: 304, useAdvancedWrap: true }, lineSpacing: 3, fontStyle: "bold",
      }));
      this.drawGraphParameterControls(overlay, puzzle, workshop, values);
    }

    this.addMathPanel(overlay, 28, 614, 1224, 74, "Missione grafica");
    overlay.add(this.add.text(54, 660, this.currentActiveHint() ?? GraphWorkshopView.readingMethod(workshop), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.currentActiveHint() ? "#f7d37a" : "#d9eaf1",
      wordWrap: { width: 650, useAdvancedWrap: true },
      lineSpacing: 3,
    }).setOrigin(0, 0.5));
    overlay.add(this.add.text(746, 650, needsReading ? this.graphWorkshopReadingStatus(workshop) : `Mosse: ${this.graphWorkshopMoves} · Par: ${GraphWorkshopView.par(workshop)}`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(new Button(this, 850, 650, needsReading ? "Rileggi" : "Ripristina", () => this.resetGraphWorkshop(puzzle), {
      width: 142, height: 42, fontSize: 12, fill: 0x263743, soundKey: "reset",
    }));
    overlay.add(new Button(this, 1004, 650, hintButtonLabel(puzzle, this.activePuzzleHintsUsed(), "Indizio"), () => {
      this.useContextualHint(puzzle);
      this.openGraphWorkshop(puzzle);
    }, { width: 142, height: 42, fontSize: 12, fill: 0x263743 }));
    const certify = new Button(this, 1168, 650, "Certifica", () => this.certifyGraphWorkshop(puzzle), {
      width: 150, height: 42, fontSize: 13, fill: 0x173b36, stroke: 0xf6c85f,
    });
    if (needsReading && !this.graphWorkshopApplied) {
      certify.setEnabled(false);
    }
    overlay.add(certify);
  }

  private drawGraphParameterControls(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    workshop: GeneratedGraphWorkshop,
    values: Partial<Record<GraphParameterKey, number>>,
  ): void {
    workshop.parameters.forEach((parameter, index) => {
      const rowY = 352 + index * 72;
      overlay.add(this.add.text(920, rowY - 30, `${parameter.label} · ${parameter.meaning}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9ff5e9",
        wordWrap: { width: 294, useAdvancedWrap: true },
      }));
      overlay.add(new Button(this, 952, rowY + 8, "-", () => this.adjustGraphParameter(puzzle, parameter.key, -parameter.step), {
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
    overlay.add(this.add.text(920, propertyY, GraphWorkshopView.properties(workshop, values), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c7dce7",
      wordWrap: { width: 304, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
  }

  private drawGraphReadingPanel(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    workshop: GeneratedGraphWorkshop,
  ): void {
    const steps = workshop.readingSteps ?? [];
    const current = this.currentGraphReadingStep(workshop);
    if (!current) return;
    overlay.add(this.add.text(920, 282, "Prima leggi i dati. La retta non si muove finche non hai ricavato i parametri.", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", wordWrap: { width: 304, useAdvancedWrap: true }, lineSpacing: 3, fontStyle: "bold",
    }));
    overlay.add(this.add.rectangle(920, 320, 304, 182, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(938, 336, current.label, {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#9ff5e9", fontStyle: "bold",
    }));
    overlay.add(this.add.text(938, 360, current.prompt, {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#d9eaf1", wordWrap: { width: 268, useAdvancedWrap: true }, lineSpacing: 3,
    }));
    current.options.forEach((option, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(new Button(this, 1000 + col * 144, 424 + row * 48, String(option), () => this.answerGraphReadingStep(puzzle, current, option), {
        width: 126, height: 38, fontSize: 14, fill: 0x173b36, stroke: 0x6be7d6, soundKey: "confirm",
      }));
    });

    overlay.add(this.add.text(920, 522, "Passaggi", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#9ff5e9", fontStyle: "bold",
    }));
    steps.forEach((step, index) => {
      const done = this.graphWorkshopReadingAnswers[step.key] === step.correctValue;
      overlay.add(this.add.text(920, 544 + index * 17, `${done ? "OK" : "--"} ${step.label.replace(/^\d+ · /, "")}${done ? ` = ${step.correctValue}` : ""}`, {
        fontFamily: "Inter, Arial", fontSize: "10px", color: done ? "#66f2a0" : "#8aa1ad", wordWrap: { width: 304, useAdvancedWrap: true },
      }));
    });
  }

  private drawGraphApplyPanel(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    workshop: GeneratedGraphWorkshop,
  ): void {
    overlay.add(this.add.text(920, 282, "Lettura completata. Ora disegna la retta dai parametri che hai ricavato.", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", wordWrap: { width: 304, useAdvancedWrap: true }, lineSpacing: 3, fontStyle: "bold",
    }));
    overlay.add(this.add.rectangle(920, 326, 304, 142, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    (workshop.readingSteps ?? []).forEach((step, index) => {
      overlay.add(this.add.text(940, 344 + index * 26, `${step.key} = ${step.correctValue}`, {
        fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1", fontStyle: step.parameterKey ? "bold" : undefined,
      }));
    });
    overlay.add(this.add.text(920, 492, `Equazione: ${workshop.targetFormula}`, {
      fontFamily: "Georgia, 'Times New Roman', serif", fontSize: "18px", color: "#f7d37a", fontStyle: "bold", wordWrap: { width: 304 },
    }));
    overlay.add(new Button(this, 1072, 558, "Disegna retta", () => this.applyGraphReadingToWorkshop(puzzle), {
      width: 246, height: 44, fontSize: 13, fill: 0x173b36, stroke: 0xf6c85f, soundKey: "contextMath",
    }));
  }

  private drawGraphLockedParameterPanel(
    overlay: Phaser.GameObjects.Container,
    workshop: GeneratedGraphWorkshop,
  ): void {
    overlay.add(this.add.text(920, 282, "Retta disegnata dai tuoi calcoli. Ora controlla sul piano: deve attraversare entrambi i beacon.", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", wordWrap: { width: 304, useAdvancedWrap: true }, lineSpacing: 3, fontStyle: "bold",
    }));
    workshop.parameters.forEach((parameter, index) => {
      const rowY = 356 + index * 68;
      overlay.add(this.add.text(920, rowY - 28, `${parameter.label} · ${parameter.meaning}`, {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#9ff5e9", wordWrap: { width: 294, useAdvancedWrap: true },
      }));
      overlay.add(this.add.rectangle(1072, rowY + 6, 240, 40, 0x102533, 0.94).setStrokeStyle(2, 0x6be7d6, 0.46));
      overlay.add(this.add.text(1072, rowY + 6, `${parameter.label} = ${parameter.target}`, {
        fontFamily: "Inter, Arial", fontSize: "19px", color: "#f5fbff", fontStyle: "bold",
      }).setOrigin(0.5));
    });
    overlay.add(this.add.text(920, 510, GraphWorkshopView.properties(workshop, this.graphWorkshopValues), {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#c7dce7", wordWrap: { width: 304, useAdvancedWrap: true }, lineSpacing: 3,
    }));
  }

  private graphWorkshopNeedsReading(workshop: GeneratedGraphWorkshop): boolean {
    return workshop.mode === "beacon-line" && (workshop.readingSteps?.length ?? 0) > 0;
  }

  private graphWorkshopReadingComplete(workshop: GeneratedGraphWorkshop): boolean {
    return (workshop.readingSteps ?? []).every((step) => this.graphWorkshopReadingAnswers[step.key] === step.correctValue);
  }

  private currentGraphReadingStep(workshop: GeneratedGraphWorkshop): GraphReadingStep | undefined {
    return (workshop.readingSteps ?? []).find((step) => this.graphWorkshopReadingAnswers[step.key] !== step.correctValue);
  }

  private graphWorkshopReadingStatus(workshop: GeneratedGraphWorkshop): string {
    const steps = workshop.readingSteps ?? [];
    const done = steps.filter((step) => this.graphWorkshopReadingAnswers[step.key] === step.correctValue).length;
    if (this.graphWorkshopApplied) return "Retta disegnata";
    if (done >= steps.length) return "Lettura completa";
    return `Passaggi: ${done}/${steps.length}`;
  }

  private graphWorkshopNotebookFormula(workshop: GeneratedGraphWorkshop): string {
    if (this.graphWorkshopReadingComplete(workshop)) {
      return workshop.targetFormula;
    }
    const m = this.graphWorkshopReadingAnswers.m;
    const q = this.graphWorkshopReadingAnswers.q;
    const mText = m === undefined ? "m" : String(m);
    const qText = q === undefined ? "+ q" : q >= 0 ? `+ ${q}` : `- ${Math.abs(q)}`;
    return `y = ${mText}x ${qText}`;
  }

  private answerGraphReadingStep(puzzle: GeneratedMathPuzzle, step: GraphReadingStep, value: number): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    const current = this.currentGraphReadingStep(workshop);
    if (!current || current.key !== step.key) {
      feedbackSystem.publish("Completa un passaggio alla volta: il taccuino segue l'ordine di lettura.", "hint");
      audioManager.playOutcome("hint");
      this.openGraphWorkshop(puzzle);
      return;
    }
    if (value === step.correctValue) {
      this.graphWorkshopReadingAnswers[step.key] = value;
      audioManager.playOutcome("correct");
      const complete = this.graphWorkshopReadingComplete(workshop);
      feedbackSystem.publish(complete ? "Lettura completata: ora puoi disegnare la retta dall'equazione." : `Passaggio corretto. ${step.explanation}`, "success");
      this.openGraphWorkshop(puzzle);
      return;
    }
    const selected = `${step.key} = ${value}`;
    const correct = `${step.key} = ${step.correctValue}`;
    outcomeFeedback.answer(this, false, selected, correct, step.explanation);
    const exited = this.handleIncorrectAnswer(`Rileggi il passaggio: ${step.explanation}`);
    if (!exited) this.openGraphWorkshop(puzzle);
  }

  private applyGraphReadingToWorkshop(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    if (!this.graphWorkshopReadingComplete(workshop)) {
      feedbackSystem.publish("Prima completa tutti i passaggi del taccuino.", "hint");
      audioManager.playOutcome("hint");
      this.openGraphWorkshop(puzzle);
      return;
    }
    this.graphWorkshopValues = Object.fromEntries(
      workshop.parameters.map((parameter) => [parameter.key, parameter.target]),
    ) as Partial<Record<GraphParameterKey, number>>;
    this.graphWorkshopApplied = true;
    audioManager.play("mathKey");
    feedbackSystem.publish("Retta disegnata dai parametri letti: ora controlla i beacon e certifica.", "success");
    this.openGraphWorkshop(puzzle);
  }

  private ensureGraphWorkshopState(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop || this.graphWorkshopPuzzleId === puzzle.id) return;
    this.graphWorkshopPuzzleId = puzzle.id;
    this.graphWorkshopValues = Object.fromEntries(
      workshop.parameters.map((parameter) => [parameter.key, parameter.initial]),
    ) as Partial<Record<GraphParameterKey, number>>;
    this.graphWorkshopReadingAnswers = {};
    this.graphWorkshopApplied = false;
    this.graphWorkshopMoves = 0;
  }

  private adjustGraphParameter(puzzle: GeneratedMathPuzzle, key: GraphParameterKey, delta: number): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    if (this.graphWorkshopNeedsReading(workshop)) {
      feedbackSystem.publish("In questa missione non si procede a tentativi: completa il taccuino e disegna la retta dai parametri letti.", "hint");
      audioManager.playOutcome("hint");
      return;
    }
    const parameter = workshop.parameters.find((item) => item.key === key);
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
    this.graphWorkshopReadingAnswers = {};
    this.graphWorkshopApplied = false;
    this.graphWorkshopMoves = 0;
    this.activeHintText = undefined;
    this.activeHintPuzzleId = undefined;
    this.openGraphWorkshop(puzzle);
  }

  private certifyGraphWorkshop(puzzle: GeneratedMathPuzzle): void {
    const workshop = puzzle.graphWorkshop;
    if (!workshop) return;
    if (this.graphWorkshopNeedsReading(workshop) && !this.graphWorkshopReadingComplete(workshop)) {
      feedbackSystem.publish("Prima completa il taccuino: q, dx, dy e m devono essere letti prima di certificare.", "hint");
      audioManager.playOutcome("hint");
      this.openGraphWorkshop(puzzle);
      return;
    }
    if (this.graphWorkshopNeedsReading(workshop) && !this.graphWorkshopApplied) {
      feedbackSystem.publish("Hai letto i parametri: ora premi Disegna retta e poi controlla il piano cartesiano.", "hint");
      audioManager.playOutcome("hint");
      this.openGraphWorkshop(puzzle);
      return;
    }
    const exact = workshop.parameters.every((parameter) => this.graphWorkshopValues[parameter.key] === parameter.target);
    const selected = GraphWorkshopView.formula(workshop, this.graphWorkshopValues);
    if (exact) {
      if (this.graphWorkshopNeedsReading(workshop)) {
        const explanation = `Lettura corretta: ${workshop.successExplanation}`;
        outcomeFeedback.answer(this, true, selected, workshop.targetFormula, explanation);
        feedbackSystem.publish(`Grafico certificato: hai ricavato q e m prima di disegnare. ${workshop.successExplanation}`, "success");
        this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
        return;
      }
      const par = GraphWorkshopView.par(workshop);
      const rating = this.graphWorkshopMoves <= par
        ? "★★★ calibrazione perfetta"
        : this.graphWorkshopMoves <= par + 3
          ? "★★☆ calibrazione precisa"
          : "★☆☆ grafico corretto";
      const readingNote = this.graphWorkshopMoves > par + 3 && workshop.mode === "beacon-line"
        ? " La prossima volta leggi m e q dai beacon (m = Δy/Δx, q = y in x=0): ci arrivi in poche mosse."
        : "";
      outcomeFeedback.answer(this, true, selected, workshop.targetFormula, `${rating}. ${workshop.successExplanation}${readingNote}`);
      feedbackSystem.publish(`Grafico certificato in ${this.graphWorkshopMoves} mosse (par ${par}). ${rating}. ${workshop.successExplanation}${readingNote}`, "success");
      this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
      return;
    }
    const diagnosis = GraphWorkshopView.diagnosis(workshop, this.graphWorkshopValues);
    outcomeFeedback.answer(this, false, selected, "Grafico con tutte le proprietà richieste", diagnosis);
    const exited = this.handleIncorrectAnswer(diagnosis);
    if (!exited) this.openGraphWorkshop(puzzle);
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
    this.addNoraTheoryButton(overlay, 1082, 48);
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
      this.mathSupportMessage = `Il valore ${Number.isFinite(enteredValue) ? enteredValue : "inserito"} non chiude il terminale. Controlla un passaggio intermedio, non provare numeri a caso. ${nextPedagogicHint(puzzle, this.activePuzzleHintsUsed(), puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])}`;
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
    const showCoach = this.shouldShowExerciseCoach("math");
    const overlay = this.createMathOverlay(puzzle.minigame.title, this.compactExerciseSubtitle("math", "Matematica · osserva il vincolo, seleziona le tessere, conferma"));
    const prompt = this.currentMathMinigamePrompt(session);
    const remaining = this.mathMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.mathMinigameTimerText = MathTerminal.addMinigamePrompt(this, overlay, prompt, {
      showCoach,
      selectedIds: session.selectedIds,
      remainingLabel: formatDuration(remaining),
      remainingDanger: remaining <= 10_000,
      streak: session.streak,
      netScore: session.netScore,
      accuracy,
      feedback: session.feedback,
      scoringRule: puzzle.minigame.scoringRule,
    }, {
      onToggleTile: (tileId) => this.toggleMathMinigameTile(tileId),
      onClearSelection: () => this.clearMathMinigameSelection(),
      onConfirm: () => this.confirmMathMinigamePrompt(),
      onHint: () => this.useMathMinigameHint(),
      onRenderVisualizer: (targetOverlay, targetPrompt, x, y, width, height) => {
        this.drawMathMinigameVisualizer(targetOverlay, targetPrompt, x, y, width, height);
      },
      onRenderExpressionBuilder: (targetOverlay, targetPrompt) => {
        this.renderMathExpressionBuilder(targetOverlay, session, targetPrompt);
      },
    });

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
    const showCoach = this.shouldShowExerciseCoach("math");
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
      feedback: showCoach ? "Scegli con metodo: una conferma sbagliata riduce il punteggio e in missione consuma una vita." : "",
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
    if (prompt.type === "geometry-measure" && prompt.geometryVisual) {
      this.drawGeometryMinigameVisual(overlay, g, prompt, x, y, width, height);
      return;
    }
    if (
      prompt.type === "fraction-lab"
      || prompt.type === "ratio-proportion"
      || prompt.type === "geometry-measure"
      || prompt.type === "data-probability"
      || prompt.type === "number-sequence"
      || prompt.type === "expression-build"
    ) {
      const visualSteps = prompt.type === "fraction-lab"
        ? ["totale", "parte", "%"]
        : prompt.type === "ratio-proportion"
          ? ["1 unita", "rapporto", "scala"]
          : prompt.type === "geometry-measure"
            ? ["figura", "formula", "unita"]
            : prompt.type === "data-probability"
              ? ["dati", "indice", "evento"]
              : prompt.type === "number-sequence"
                ? ["termini", "regola", "prossimo"]
                : ["numeri", "priorita", "target"];
      overlay.add(this.add.text(x + 34, y + 24, prompt.targetLabel, {
        fontFamily: "Inter, Arial",
        fontSize: "17px",
        color: "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: width - 68, useAdvancedWrap: true },
      }));
      visualSteps.forEach((label, index) => {
        const cx = x + 82 + index * 150;
        const cy = y + 104;
        g.fillStyle(index === 1 ? 0x173b36 : 0x0d2632, 0.92);
        g.fillRoundedRect(cx - 48, cy - 34, 96, 68, 10);
        g.lineStyle(2, index === 1 ? 0xf7d37a : 0x6be7d6, 0.58);
        g.strokeRoundedRect(cx - 48, cy - 34, 96, 68, 10);
        overlay.add(this.add.text(cx, cy, label, {
          fontFamily: "Inter, Arial",
          fontSize: label.length > 8 ? "12px" : "14px",
          color: "#f5fbff",
          fontStyle: "bold",
        }).setOrigin(0.5));
        if (index < visualSteps.length - 1) {
          overlay.add(this.add.triangle(cx + 68, cy, 0, -7, 16, 0, 0, 7, 0x6be7d6, 0.68));
        }
      });
      overlay.add(this.add.text(x + 44, y + height - 52, "Prima riconosci la famiglia della prova, poi fai un solo controllo numerico sulla risposta.", {
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

  private drawGeometryMinigameVisual(
    overlay: Phaser.GameObjects.Container,
    g: Phaser.GameObjects.Graphics,
    prompt: MathMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const visual = prompt.geometryVisual;
    if (!visual) return;
    const labelStyle = {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      fontStyle: "bold",
    };
    const noteStyle = {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 88 },
    };
    overlay.add(this.add.text(x + 34, y + 20, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 68, useAdvancedWrap: true },
    }));

    if (visual.shape === "rectangle") {
      const w = visual.width ?? 8;
      const h = visual.height ?? 5;
      const scale = Math.min(250 / w, 116 / h);
      const rw = Math.max(120, w * scale);
      const rh = Math.max(70, h * scale);
      const rx = x + 84;
      const ry = y + 78;
      g.fillStyle(visual.measure === "area" ? 0x1b6b5f : 0x0d2632, visual.measure === "area" ? 0.54 : 0.24);
      g.fillRoundedRect(rx, ry, rw, rh, 8);
      g.lineStyle(visual.measure === "perimeter" ? 5 : 3, visual.measure === "perimeter" ? 0xf7d37a : 0x6be7d6, 0.9);
      g.strokeRoundedRect(rx, ry, rw, rh, 8);
      overlay.add(this.add.text(rx + rw / 2, ry + rh + 22, `${w} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(rx + rw + 34, ry + rh / 2, `${h} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(x + 44, y + height - 50, visual.measure === "perimeter"
        ? "Bordo evidenziato: somma tutti i lati. P = 2 x (base + altezza)."
        : "Superficie evidenziata: conta l'interno. A = base x altezza.", noteStyle));
      return;
    }

    if (visual.shape === "triangle") {
      const base = visual.base ?? 8;
      const h = visual.height ?? 6;
      const ax = x + 94;
      const ay = y + 178;
      const bx = x + 344;
      const by = ay;
      const cx = x + 222;
      const cy = y + 74;
      g.fillStyle(0x1b6b5f, 0.46);
      g.fillTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(3, 0x6be7d6, 0.9);
      g.strokeTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(2, 0xf7d37a, 0.8);
      g.lineBetween(cx, cy, cx, ay);
      overlay.add(this.add.rectangle(cx + 8, ay - 8, 16, 16, 0x000000, 0).setStrokeStyle(1, 0xf7d37a, 0.7));
      overlay.add(this.add.text((ax + bx) / 2, ay + 22, `base ${base} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(cx + 48, (cy + ay) / 2, `h ${h} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(x + 44, y + height - 50, "Superficie triangolare: e meta del rettangolo con stessa base e altezza. A = base x altezza : 2.", noteStyle));
      return;
    }

    if (visual.shape === "box") {
      const l = visual.length ?? 6;
      const w = visual.width ?? 4;
      const h = visual.height ?? 3;
      const rx = x + 112;
      const ry = y + 88;
      const rw = 176;
      const rh = 82;
      const dx = 54;
      const dy = -34;
      g.fillStyle(0x1b6b5f, 0.36);
      g.fillRoundedRect(rx, ry, rw, rh, 6);
      g.lineStyle(3, 0x6be7d6, 0.85);
      g.strokeRoundedRect(rx, ry, rw, rh, 6);
      g.lineBetween(rx, ry, rx + dx, ry + dy);
      g.lineBetween(rx + rw, ry, rx + rw + dx, ry + dy);
      g.lineBetween(rx + rw, ry + rh, rx + rw + dx, ry + rh + dy);
      g.lineBetween(rx + dx, ry + dy, rx + rw + dx, ry + dy);
      g.lineBetween(rx + rw + dx, ry + dy, rx + rw + dx, ry + rh + dy);
      g.lineBetween(rx + rw + dx, ry + rh + dy, rx + rw, ry + rh);
      overlay.add(this.add.text(rx + rw / 2, ry + rh + 22, `${l} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(rx + rw + dx + 28, ry + rh / 2 + dy, `${h} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(rx + rw + dx / 2, ry + dy - 16, `${w} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(x + 44, y + height - 50, "Solido evidenziato: il volume usa tre dimensioni. V = lunghezza x larghezza x altezza.", noteStyle));
      return;
    }

    if (visual.shape === "right-triangle") {
      const a = visual.a ?? 3;
      const b = visual.b ?? 4;
      const c = visual.c ?? 5;
      const ax = x + 116;
      const ay = y + 176;
      const bx = x + 342;
      const by = ay;
      const cx = ax;
      const cy = y + 70;
      g.fillStyle(0x1b6b5f, 0.38);
      g.fillTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(3, 0x6be7d6, 0.86);
      g.strokeTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(5, 0xf7d37a, 0.9);
      g.lineBetween(cx, cy, bx, by);
      overlay.add(this.add.rectangle(ax + 10, ay - 10, 20, 20, 0x000000, 0).setStrokeStyle(1, 0xf7d37a, 0.8));
      overlay.add(this.add.text((ax + bx) / 2, ay + 22, `${b} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(ax - 34, (ay + cy) / 2, `${a} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text((cx + bx) / 2 + 18, (cy + by) / 2 - 18, `? = ${c} ${visual.unit}`, labelStyle).setOrigin(0.5));
      overlay.add(this.add.text(x + 44, y + height - 50, "Lato giallo: ipotenusa. Pitagora: c2 = a2 + b2, poi radice.", noteStyle));
      return;
    }

    const radius = visual.radius ?? 4;
    const cx = x + 224;
    const cy = y + 124;
    const r = 62;
    g.fillStyle(visual.measure === "area" ? 0x1b6b5f : 0x0d2632, visual.measure === "area" ? 0.5 : 0.24);
    g.fillCircle(cx, cy, r);
    g.lineStyle(visual.measure === "circumference" ? 5 : 3, visual.measure === "circumference" ? 0xf7d37a : 0x6be7d6, 0.9);
    g.strokeCircle(cx, cy, r);
    g.lineStyle(3, 0xf7d37a, 0.86);
    g.lineBetween(cx, cy, cx + r, cy);
    overlay.add(this.add.circle(cx, cy, 4, 0xf7d37a, 0.95));
    overlay.add(this.add.text(cx + r / 2, cy - 22, `r = ${radius} ${visual.unit}`, labelStyle).setOrigin(0.5));
    overlay.add(this.add.text(x + 44, y + height - 50, visual.measure === "area"
      ? "Superficie del cerchio: A = pi x r x r. Qui pi = 3."
      : "Bordo evidenziato: C = 2 x pi x r. Qui pi = 3.", noteStyle));
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
    if (!session || session.summaryOpen || this.isSprintPaused()) {
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
            : prompt.type === "fraction-lab"
              ? "Per frazioni e percentuali cerca il totale: 1/4 di 80 parte da 80 : 4, non da 1 + 4."
              : prompt.type === "ratio-proportion"
                ? "Riduci a una unita: prezzo per 1, dose per 1 persona, km per 1 cm. Poi ricostruisci la richiesta."
                : prompt.type === "geometry-measure"
                  ? "Disegna mentalmente la figura: perimetro = bordo, area = superficie, volume = spazio occupato."
                  : prompt.type === "data-probability"
                    ? "Leggi la parola chiave: media divide la somma, mediana prende il centro, probabilita usa favorevoli su possibili."
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
    VisualKit.worldReact(this, "correct", { subtle: true });
    this.cheerStreak(session.streak);
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
      // Insegnamento graduale: se la rotazione porta un concetto mai visto (es. da
      // "frazioni" a "percentuali" nello stesso sprint), NORA lo introduce prima —
      // l'orologio si ferma durante la spiegazione, così non costa tempo di gara.
      this.maybeIntroduceConcept("math");
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
    return "Calibrazione utile: hai lavorato sul metodo, ora cerca serie più lunghe senza errori.";
  }

  private showMathMinigameSummary(session: MathMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const passed = this.mathMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    MathTerminal.addMinigameSummary(this, overlay, {
      passed,
      correct: session.correct,
      wrong: session.wrong,
      accuracy,
      bestStreak: session.bestStreak,
      netScore: session.netScore,
      feedback: this.mathMinigameFeedback(session),
      resolutionText: (mode === "mission" || mode === "progressive")
        ? passed
          ? "La console matematica accetta la sequenza rapida: calcolo, controllo e precisione sono sufficienti."
          : "La soglia minima non è stata raggiunta: perderai una vita, ma le console già completate restano stabili."
        : "Calibrazione registrabile: migliorano tempo, precisione, serie positiva e consapevolezza degli errori.",
      energyText: this.runEnergySummary(),
      actionLabel: (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua",
    }, {
      onAction: (modal) => {
        modal.destroy(true);
        if (!passed && (mode === "mission" || mode === "progressive")) {
          this.loseMissionLife("sprint matematico sotto soglia: servono più risposte corrette con meno tentativi.");
          return;
        }
        this.completeMathMinigame(session);
      },
    });
  }

  private completeMathMinigame(session: MathMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeMathMinigameScore(session);
    this.completeSprintMinigameOutcome({
      session,
      score,
      competencies: session.game.competencies,
      copy: {
        summaryName: "Sprint matematico",
        certification: "Console matematica stabilizzata: il sistema completo è certificabile.",
      },
      clearSession: () => {
        this.mathMinigameSession = undefined;
      },
      restartDelayMs: 2200,
    });
  }

  private finalizeMathMinigameScore(session: MathMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.mathMinigameElapsedMs(session)));
    const score = buildMathMinigameScore(session, run, existing, elapsedMs, this.mathMinigameFeedback(session));
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
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
    overlay.add(this.add.text(56, 78, (puzzle.difficultyLabel ?? "Profondità 1 - comandi e divieti").toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(56, 104, `${englishChallengeLabel(puzzle.challengeType)}${puzzle.scenario ? ` | ${puzzle.scenario}` : ""}`, {
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
    overlay.add(new Button(this, 1002, 620, hintButtonLabel(puzzle, this.activePuzzleHintsUsed(), "Indizio mirato"), () => {
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
    const showCoach = this.shouldShowExerciseCoach("english");
    const overlay = this.createMathOverlay(puzzle.minigame.title, this.compactExerciseSubtitle("english", "Inglese · decodifica il comando, giustifica col vincolo, conferma"));
    const prompt = this.currentEnglishMinigamePrompt(session);
    const remaining = this.englishMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.englishMinigameTimerText = renderEnglishSprintConsole({
      scene: this,
      overlay,
      session,
      prompt,
      showCoach,
      remainingMs: remaining,
      accuracy,
      scoringRule: puzzle.minigame.scoringRule,
      addPanel: (x, y, width, height, title) => this.addMathPanel(overlay, x, y, width, height, title),
      onToggleTile: (tileId) => this.toggleEnglishMinigameTile(tileId),
      onToggleOrderTile: (tileId) => this.toggleEnglishOrderTile(tileId),
      onClearOrder: () => {
        session.orderedSelection = [];
        audioManager.play("cancel");
        this.openEnglishMinigame(session.puzzle);
      },
      onConfirm: () => this.confirmEnglishMinigamePrompt(),
      onHint: () => this.useEnglishMinigameHint(),
    }).timerText;

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
    // Mix types unless this is a focused inglese training run (staged single-type).
    const mixTypes = this.isProgressiveMode() || !this.run.focus.includes("inglese");
    const types = mixTypes ? this.progressiveEnglishSprintTypes(game.type) : [game.type];
    const freshPrompts = types.flatMap((type, index) =>
      generator.generateMinigame(random.fork(`mix-${type}-${index}`), this.run.difficulty, [type]).minigame?.prompts ?? [],
    );
    const variedGame = {
      ...game,
      title: mixTypes ? "Sprint inglese: percorso variato" : game.title,
      instructions: mixTypes
        ? "alterni azioni, sequenze, dati, grammatica, frase, traduzione, lettura, diagnosi e dialogo: trova prima lo scopo della domanda."
        : game.instructions,
      prompts: random.shuffle(freshPrompts.length ? freshPrompts : game.prompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })),
    };
    const showCoach = this.shouldShowExerciseCoach("english");
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
      feedback: showCoach
        ? mixTypes
          ? "Percorso variato: ogni comando può chiedere azione, ordine, dato, grammatica o traduzione. Leggi lo scopo prima della risposta."
          : "Leggi il comando come una procedura: action word -> object -> limiter/time word."
        : "",
      locked: false,
      summaryOpen: false,
    };
    return this.englishMinigameSession;
  }

  private progressiveEnglishSprintTypes(baseType: EnglishMinigameType): EnglishMinigameType[] {
    const rotation: EnglishMinigameType[] = ["action-relay", "sequence-switchboard", "data-command-scan", "grammar-fix", "sentence-build", "vocab-lab", "translation-match", "reading-detective", "error-diagnosis", "dialogue-response"];
    return [baseType, ...rotation.filter((type) => type !== baseType)];
  }

  private progressiveCodingSprintTypes(baseType: CodingMinigameType): CodingMinigameType[] {
    const rotation: CodingMinigameType[] = ["python-lab", "state-tracer", "language-atlas", "loop-output", "conditional-path", "bug-hunt", "logic-gate", "binary-bits", "sequence-builder", "algorithm-order"];
    return [baseType, ...rotation.filter((type) => type !== baseType)];
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
    if (!session || session.summaryOpen || this.isSprintPaused()) {
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

  private useEnglishMinigameHint(): void {
    const session = this.englishMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentEnglishMinigamePrompt(session);
    const hint = englishMinigameHint(prompt);
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
          ? `${englishSelectionRequirementText(prompt)} Il timer continua.`
          : "Select one tile first. The timer keeps running.";
        audioManager.playOutcome("hint");
        this.openEnglishMinigame(session.puzzle);
        return;
      }
      if (prompt.requiredSelectionCount > 1 && session.selectedIds.size < prompt.requiredSelectionCount) {
        session.feedback = englishSelectionRequirementText(prompt);
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
    VisualKit.worldReact(this, "correct", { subtle: true });
    this.cheerStreak(session.streak);
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

  private showEnglishMinigameSummary(session: EnglishMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const passed = this.englishMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    addSprintSummaryModal(this, overlay, {
      title: passed ? "Sprint inglese completato" : "Sprint inglese da consolidare",
      passed,
      correct: session.correct,
      wrong: session.wrong,
      accuracy,
      bestStreak: session.bestStreak,
      netScore: session.netScore,
      feedback: englishMinigameFeedback(session),
      resolutionText: (mode === "mission" || mode === "progressive")
        ? passed
          ? "La console inglese accetta il protocollo: azioni, condizioni e dati sono stati interpretati."
          : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
        : "Calibrazione registrabile: il voto pesa rapidità, precisione, serie positiva e uso degli aiuti.",
      energyText: this.runEnergySummary(),
      actionLabel: (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua",
    }, {
      onAction: (modal) => {
        modal.destroy(true);
        if (!passed && (mode === "mission" || mode === "progressive")) {
          this.loseMissionLife("sprint inglese sotto soglia: servono più comandi corretti con meno tentativi.");
          return;
        }
        this.completeEnglishMinigame(session);
      },
    });
  }

  private completeEnglishMinigame(session: EnglishMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeEnglishMinigameScore(session);
    this.completeSprintMinigameOutcome({
      session,
      score,
      competencies: session.game.competencies,
      copy: {
        summaryName: "Sprint inglese",
        certification: "Console inglese stabilizzata: il sistema completo è certificabile.",
      },
      clearSession: () => {
        this.englishMinigameSession = undefined;
      },
      restartDelayMs: 1750,
    });
  }

  private finalizeEnglishMinigameScore(session: EnglishMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.englishMinigameElapsedMs(session)));
    const score = buildEnglishMinigameScore(session, run, existing, elapsedMs, englishMinigameFeedback(session));
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
    return score;
  }

  private openCodingMinigame(puzzle: GeneratedCodingPuzzle): void {
    if (!puzzle.minigame) {
      return;
    }
    const puzzleId = this.currentPuzzleId("coding");
    const session = this.ensureCodingMinigameSession(puzzleId, puzzle, puzzle.minigame);
    const showCoach = this.shouldShowExerciseCoach("coding");
    const overlay = this.createMathOverlay(puzzle.minigame.title, this.compactExerciseSubtitle("coding", "Coding · simula il codice, scegli il blocco, conferma"));
    const prompt = this.currentCodingMinigamePrompt(session);
    const remaining = this.codingMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.codingMinigameTimerText = renderCodingSprintConsole({
      scene: this,
      overlay,
      session,
      prompt,
      showCoach,
      remainingMs: remaining,
      accuracy,
      scoringRule: puzzle.minigame.scoringRule,
      addPanel: (x, y, width, height, title) => this.addMathPanel(overlay, x, y, width, height, title),
      onToggleTile: (tileId) => this.toggleCodingMinigameTile(tileId),
      onToggleOrderTile: (tileId) => this.toggleCodingOrderTile(tileId),
      onClearOrder: () => {
        session.orderedSelection = [];
        audioManager.play("cancel");
        this.openCodingMinigame(session.puzzle);
      },
      onConfirm: () => this.confirmCodingMinigamePrompt(),
      onHint: () => this.useCodingMinigameHint(),
    }).timerText;

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
    const generator = new CodingPuzzleGenerator();
    const preset = difficultyModel.getPreset(this.run.difficulty);
    // Mix coding types unless this is a focused coding training run: the Story
    // then alternates Python lab, Atlante dei Linguaggi, tracing, logica, cicli…
    const mixTypes = this.isProgressiveMode() || !this.run.focus.includes("coding");
    const types = mixTypes ? this.progressiveCodingSprintTypes(game.type) : [game.type];
    const freshPrompts = types.flatMap((type, idx) =>
      generator.generateMinigame(random.fork(`mix-${type}-${idx}`), preset, [type]).minigame?.prompts ?? [],
    );
    const variedGame = {
      ...game,
      title: mixTypes ? "Sprint coding: percorso variato" : game.title,
      instructions: mixTypes
        ? "alterni Python vero, atlante dei linguaggi, tracing, logica, cicli e debug: leggi l'obiettivo prima di scegliere."
        : game.instructions,
      prompts: random.shuffle(freshPrompts.length ? freshPrompts : game.prompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })),
    };
    const showCoach = this.shouldShowExerciseCoach("coding");
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
      feedback: showCoach ? "Prima simula il codice: stato iniziale, trasformazione, risultato. Poi conferma." : "",
      locked: false,
      summaryOpen: false,
    };
    return this.codingMinigameSession;
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
    if (!session || session.summaryOpen || this.isSprintPaused()) {
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

  private useCodingMinigameHint(): void {
    const session = this.codingMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    const prompt = this.currentCodingMinigamePrompt(session);
    const hint = codingMinigameHint(prompt);
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
    VisualKit.worldReact(this, "correct", { subtle: true });
    this.cheerStreak(session.streak);
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

  private showCodingMinigameSummary(session: CodingMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const passed = this.codingMinigamePassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    addSprintSummaryModal(this, overlay, {
      title: passed ? "Sprint coding completato" : "Sprint coding da consolidare",
      passed,
      correct: session.correct,
      wrong: session.wrong,
      accuracy,
      bestStreak: session.bestStreak,
      netScore: session.netScore,
      feedback: codingMinigameFeedback(session),
      resolutionText: (mode === "mission" || mode === "progressive")
        ? passed
          ? "La console coding certifica il programma: sequenza, stato e correzione sono coerenti."
          : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
        : "Calibrazione registrabile: il voto pesa precisione, velocità, serie corretta e uso degli aiuti.",
      energyText: this.runEnergySummary(),
      actionLabel: (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua",
    }, {
      onAction: (modal) => {
        modal.destroy(true);
        if (!passed && (mode === "mission" || mode === "progressive")) {
          this.loseMissionLife("sprint coding sotto soglia: servono più simulazioni corrette con meno tentativi.");
          return;
        }
        this.completeCodingMinigame(session);
      },
    });
  }

  private completeCodingMinigame(session: CodingMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeCodingMinigameScore(session);
    this.completeSprintMinigameOutcome({
      session,
      score,
      competencies: session.game.competencies,
      copy: {
        summaryName: "Sprint coding",
        certification: "Console coding stabilizzata: il sistema completo è certificabile.",
      },
      clearSession: () => {
        this.codingMinigameSession = undefined;
      },
      restartDelayMs: 1750,
    });
  }

  private finalizeCodingMinigameScore(session: CodingMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, this.codingMinigameElapsedMs(session)));
    const score = buildCodingMinigameScore(session, run, existing, elapsedMs, codingMinigameFeedback(session));
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
    return score;
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
    overlay.add(this.add.text(336, 72, `Tipo: ${codingChallengeLabel(puzzle.challengeType)}`, {
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
    overlay.add(new Button(this, footerPanel.x + footerPanel.w - 110, footerPanel.y + 62, hintButtonLabel(puzzle, this.activePuzzleHintsUsed(), "Indizio"), () => {
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
    const showCoach = this.shouldShowExerciseCoach("physics");
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
    overlay.add(this.add.text(356, 74, `Tipo: ${PhysicsConsole.exerciseLabel(puzzle.exerciseType)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));

    overlay.add(this.add.rectangle(leftPanel.x, leftPanel.y, leftPanel.w, leftPanel.h, 0x07151d, 0.88).setOrigin(0).setStrokeStyle(1, 0x8fd3ff, 0.26));
    overlay.add(this.add.rectangle(rightPanel.x, rightPanel.y, rightPanel.w, rightPanel.h, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.rectangle(methodPanel.x, methodPanel.y, methodPanel.w, methodPanel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.25));

    overlay.add(this.add.text(leftPanel.x + 20, leftPanel.y + 18, showCoach ? "Fenomeno" : "Scenario", {
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
    PhysicsConsole.drawVisual(this, overlay, puzzle, leftPanel.x + 24, leftPanel.y + 126, leftPanel.w - 48, 214);
    overlay.add(this.add.text(leftPanel.x + 20, leftPanel.y + leftPanel.h - 42, puzzle.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#8fd3ff",
      wordWrap: { width: leftPanel.w - 40 },
    }));

    overlay.add(this.add.text(rightPanel.x + 20, rightPanel.y + 18, showCoach ? "Domanda" : "Scelte", {
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

    overlay.add(this.add.text(methodPanel.x + 22, methodPanel.y + 16, showCoach ? "Metodo" : "Controllo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    const activeHint = this.currentActiveHint();
    if (showCoach) {
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
      overlay.add(this.add.text(methodPanel.x + 712, methodPanel.y + 40, activeHint ?? puzzle.hints[0] ?? puzzle.learningPurpose, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9aaab0",
        wordWrap: { width: 238, useAdvancedWrap: true },
        lineSpacing: 2,
      }));
    } else if (activeHint) {
      overlay.add(this.add.text(methodPanel.x + 22, methodPanel.y + 40, `Indizio attivo: ${activeHint}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
        wordWrap: { width: 900, useAdvancedWrap: true },
        lineSpacing: 3,
      }));
    } else {
      overlay.add(this.add.text(methodPanel.x + 22, methodPanel.y + 40, "Scegli una risposta; il metodo resta disponibile tramite indizio.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 900, useAdvancedWrap: true },
        lineSpacing: 3,
      }));
    }
    overlay.add(new Button(this, methodPanel.x + methodPanel.w - 100, methodPanel.y + 48, hintButtonLabel(puzzle, this.activePuzzleHintsUsed(), "Indizio"), () => {
      this.useContextualHint(puzzle);
      this.openPhysics();
    }, {
      width: 178,
      height: 40,
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
        overlay.add(this.add.text(630, y, `${point.label}: ${point.value}`, {
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
    const showCoach = this.shouldShowExerciseCoach("music");
    const overlay = this.createExerciseScreen("Osservatorio del Pentagramma");
    const signature = MusicConsole.puzzleSignature(puzzle);
    if (MusicConsole.isAuditoryPuzzle(puzzle) && session.lastAutoPreviewSignature !== signature) {
      session.lastAutoPreviewSignature = signature;
      this.runWhenActive(280, () => {
        if (this.musicSession === session && session.current === puzzle && !session.locked && !session.summaryOpen) {
          MusicConsole.previewChallenge(puzzle);
        }
      });
    }
    MusicConsole.drawSprintScreen(this, overlay, puzzle, session, {
      showCoach,
      activeHint: this.currentActiveHint(),
      hintLabel: hintButtonLabel(puzzle, this.activePuzzleHintsUsed(), "Indizio"),
      onAnswer: (correct, feedback, selectedLabel) => this.answerMusicSprint(correct, feedback, selectedLabel),
      onExpired: () => this.finishMusicSprint(),
      onHint: () => {
        this.useContextualHint(puzzle);
        this.openMusic();
      },
      onStartCountdown: (timerText) => this.startMusicSprintCountdown(puzzleId, timerText),
    });
  }

  private ensureMusicSession(puzzleId: string): MusicTrainingSession {
    if (this.musicSession?.puzzleId === puzzleId) {
      return this.musicSession;
    }
    const basePuzzle = this.currentMusicPuzzle();
    const variant = this.run.retryVariants?.music ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:music-drill:${variant}:${nextExerciseSalt()}`);
    const durationMs = MusicConsole.sprintDurationMs(this.run.difficulty);
    const baseMode = basePuzzle.challengeMode ?? "note-hunt";
    const allModes: MusicMinigameType[] = ["note-hunt", "auditory-note", "interval-jump", "auditory-interval", "rhythm-gap", "scale-step", "note-duration"];
    const otherModes = random.shuffle<MusicMinigameType>(allModes.filter((mode) => mode !== baseMode));
    const showCoach = this.shouldShowExerciseCoach("music");
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
      recentSignatures: [MusicConsole.puzzleSignature(basePuzzle)],
      modeRotation: [baseMode, ...otherModes],
      modeIndex: 0,
      feedback: showCoach ? "Tre sfide a rotazione: nota, salto melodico e ritmo. Ragiona prima del clic: la serie premia precisione e varietà." : "",
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
    const points = MusicConsole.answerPoints(session, correct, this.run.difficulty);
    session.answered += 1;
    if (correct) {
      session.correct += 1;
      session.streak += 1;
      session.bestStreak = Math.max(session.bestStreak, session.streak);
      session.netScore += points;
      session.feedback = `+${points} punti. Serie attiva: ${session.streak}.`;
      audioManager.playOutcome("correct");
      outcomeFeedback.play(this, "success", `+${points}`);
      VisualKit.worldReact(this, "correct", { subtle: true });
      this.cheerStreak(session.streak);
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
    if (MusicConsole.sprintExpired(session)) {
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
    const previous = MusicConsole.puzzleSignature(session.current);
    session.modeIndex = (session.modeIndex + 1) % session.modeRotation.length;
    const nextMode = session.modeRotation[session.modeIndex];
    for (let attempt = 0; attempt < 14; attempt += 1) {
      const salt = session.random.integer(0, 999_999);
      const candidate = this.musicGenerator.generate(session.random.fork(`sprint-${session.answered}-${attempt}-${salt}`), level, [nextMode]);
      const signature = MusicConsole.puzzleSignature(candidate);
      if (signature !== previous && !session.recentSignatures.slice(-2).includes(signature)) {
        session.recentSignatures.push(signature);
        session.recentSignatures = session.recentSignatures.slice(-4);
        return candidate;
      }
    }
    const fallback = this.musicGenerator.generate(session.random.fork(`fallback-${session.answered}`), level, [nextMode]);
    session.recentSignatures.push(MusicConsole.puzzleSignature(fallback));
    session.recentSignatures = session.recentSignatures.slice(-4);
    return fallback;
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
      if (!text.active || !session || session.puzzleId !== puzzleId || session.summaryOpen || this.isSprintPaused()) {
        return;
      }
      const remaining = MusicConsole.sprintRemainingMs(session);
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

  private showMusicSprintSummary(session: MusicTrainingSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const passed = this.musicSprintPassed(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const title = passed ? "Sprint musicale completato" : "Sprint musicale da consolidare";
    const mode = proceduralRunRules.modeFor(this.run);
    addSprintSummaryModal(this, overlay, {
      title,
      passed,
      correct: session.correct,
      wrong: session.wrong,
      accuracy,
      bestStreak: session.bestStreak,
      netScore: session.netScore,
      feedback: MusicConsole.sprintFeedback(session),
      resolutionText: (mode === "mission" || mode === "progressive")
        ? passed
          ? "La console musicale è stabile: il sistema accetta il riconoscimento rapido delle note."
          : "In missione la console richiede una soglia minima: perderai una vita, ma potrai riprovare."
        : "Calibrazione registrabile: il punteggio premia correttezza e serie, e penalizza gli errori casuali.",
      energyText: this.runEnergySummary(),
      actionLabel: (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua",
    }, {
      onAction: (modal) => {
        modal.destroy(true);
        if (!passed && (mode === "mission" || mode === "progressive")) {
          this.loseMissionLife("sprint musicale sotto soglia: servono più riconoscimenti corretti nel tempo dato.");
          return;
        }
        this.completeMusicSprint(session);
      },
    });
  }

  private completeMusicSprint(session: MusicTrainingSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeMusicSprintScore(session);
    const competencies = Array.from(new Set([
      "musica.pentagramma",
      "musica.letturaNote",
      "musica.chiaveViolino",
      "musica.chiaveBasso",
      ...session.current.competencies,
    ]));
    this.completeSprintMinigameOutcome({
      session,
      score,
      competencies,
      copy: {
        summaryName: "Sprint musicale",
        certification: "Sprint finale completato: tutte le console richieste sono stabili.",
        bestStreakLabel: "serie migliore",
      },
      clearSession: () => {
        this.musicSession = undefined;
      },
      restartDelayMs: 2200,
      maxScoreBonus: 10,
      scoreDivisor: 35,
      masteryBranchId: "musica",
    });
  }

  private finalizeMusicSprintScore(session: MusicTrainingSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const elapsedMs = Math.max(1_000, Math.min(session.durationMs, MusicConsole.sprintElapsedMs(session)));
    const score = buildMusicSprintScore(session, run, existing, elapsedMs, MusicConsole.sprintFeedback(session));
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
    return score;
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
    const retryKind = this.activePuzzleKind;
    const retryPuzzleId = this.activePuzzleId;
    const canRetryVariant = !this.isTimedMissionMode() && !onTrainingContinue && Boolean(retryKind);
    modal.add(this.add.text(x + 30, y + 232, this.isTimedMissionMode()
      ? "Quando premi, l'errore verrà registrato e perderai una vita. I sistemi già completati restano validi."
      : onTrainingContinue
        ? "Quando premi, passi alla nota successiva della sequenza. La soluzione appena vista resta parte della calibrazione."
        : canRetryVariant
          ? "Riprova subito con una variante (stesso concetto, dati nuovi) per fissare il metodo, oppure registra e prosegui."
          : "Quando premi, torni alla sala e puoi riprovare la prova con un nuovo timer.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 410 },
      lineSpacing: 3,
    }));
    if (canRetryVariant && retryKind) {
      // Retrieval practice: dopo aver letto la soluzione, applicarla subito a
      // una variante fissa il metodo molto più del passare oltre.
      modal.add(new Button(this, x + 158, y + height - 42, "🔁 Riprova con variante", () => {
        modal.destroy(true);
        this.timeoutSolutionOpen = false;
        this.rotatePuzzleVariant(retryKind, retryPuzzleId);
        this.discardActivePuzzleAttempt();
        this.clearOverlay();
        feedbackSystem.publish("Nuova variante pronta: stesso concetto, dati diversi. Applica il metodo appena letto.", "info");
        this.runWhenActive(650, () => this.scene.restart({ autoOpenPuzzle: retryKind }));
      }, {
        width: 238,
        height: 46,
        fill: 0x1f4a44,
        stroke: 0x6be7d6,
        fontSize: 14,
      }));
    }
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

  private openRobot(): void {
    const puzzle = this.currentRobotPuzzle();
    const model = RobotConsole.fromPuzzle(puzzle);
    const overlay = this.createExerciseScreen(model.title);
    this.robotExecuting = false;

    const commandLimit = puzzle.maxCommands ?? puzzle.solutionCommands.length + 4;
    const { mapPanel, programPanel, objectivePanel, commandPanel } = RobotConsole.layout();
    RobotConsole.addPanels(this, overlay, { mapPanel, programPanel, objectivePanel, commandPanel });
    RobotConsole.addMapHeader(this, overlay, mapPanel, model, puzzle.cols, puzzle.rows);
    RobotConsole.addMapLegend(this, overlay, mapPanel, RobotConsole.facingLabel(puzzle.start.facing));
    const grid = RobotConsole.addGrid(this, overlay, mapPanel, model, puzzle);
    this.robotOrigin = grid.origin;
    this.robotCellSize = grid.cellSize;
    this.robotSprite = grid.robotSprite;
    this.robotKeyMarker = grid.keyMarker;

    this.robotStatusText = RobotConsole.addProgramPanel(this, overlay, programPanel, model, this.robotCommands, commandLimit);

    RobotConsole.addObjectivePanel(this, overlay, objectivePanel, model, this.shouldShowExerciseCoach("robot"));

    RobotConsole.addCommandControls(this, overlay, commandPanel, {
      onCommand: (command) => {
        if (!this.robotExecuting && this.robotCommands.length < commandLimit) {
          this.robotCommands.push(command);
          this.openRobot();
        } else if (!this.robotExecuting) {
          this.useHint("Il buffer e pieno: non aggiungere tentativi. Simula il percorso e togli i comandi che non cambiano obiettivo.");
        }
      },
      onExecute: () => this.executeRobot(),
      onClear: () => {
        if (this.robotExecuting) {
          return;
        }
        this.robotCommands = [];
        this.openRobot();
      },
    });
  }

  private executeRobot(): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout() || this.robotExecuting || this.robotCommands.length === 0) {
      return;
    }
    const puzzle = this.currentRobotPuzzle();
    this.robotExecuting = true;
    let state = initialRobotExecutionState(puzzle);
    const checkpoints = sortedRobotCheckpoints(puzzle);
    const fail = (message: string, col = state.col, row = state.row): void => {
      this.robotExecuting = false;
      this.robotStatusText?.setColor("#f7d37a").setText(message);
      RobotConsole.flashCell(this, this.overlay, this.robotOrigin, this.robotCellSize, puzzle, col, row, 0xc94b55);
      RobotConsole.shakeSprite(this, this.robotSprite);
      audioManager.play("error");
      this.handleIncorrectAnswer(message);
    };
    const failureMessage = (failure: ReturnType<typeof robotProgramEndFailure>): string => {
      const direct = robotFailureText(failure);
      if (direct) return direct;
      if (failure.kind === "wall") {
        return mistakeAnalyzer.robotFailureMessage({ kind: "wall", commandIndex: failure.commandIndex }, this.robotCommands);
      }
      if (failure.kind === "premature-pickup") {
        return mistakeAnalyzer.robotFailureMessage({ kind: "premature-pickup", commandIndex: failure.commandIndex }, this.robotCommands);
      }
      return mistakeAnalyzer.robotFailureMessage(failure.kind === "not-exited" ? { kind: "not-exited" } : { kind: "missing-key" }, this.robotCommands);
    };

    const runAt = (index: number): void => {
      if (!this.robotExecuting || !this.overlay || !this.robotSprite?.active) {
        return;
      }
      if (index >= this.robotCommands.length) {
        const failure = robotProgramEndFailure(checkpoints, state);
        fail(failureMessage(failure));
        return;
      }
      const command = this.robotCommands[index];
      this.robotStatusText?.setColor("#d9eaf1").setText(`Passo ${index + 1}: ${commandLabels[command]}`);
      const outcome = stepRobotCommand(puzzle, checkpoints, state, command, index);
      if (outcome.kind === "failed") {
        const failure = outcome.failure;
        fail(failureMessage(failure), "col" in failure ? failure.col : state.col, "row" in failure ? failure.row : state.row);
        return;
      }
      if (outcome.kind === "turned") {
        state = outcome.state;
        RobotConsole.setRobotFacing(this.robotSprite, state.facing);
        this.tweens.add({
          targets: this.robotSprite,
          scale: { from: 1.08, to: 1 },
          duration: 180,
          ease: "Sine.easeOut",
          onComplete: () => this.runWhenActive(90, () => runAt(index + 1)),
        });
        return;
      } else if (outcome.kind === "moved") {
        state = outcome.state;
        if (outcome.checkpoint) {
          RobotConsole.flashCell(this, this.overlay, this.robotOrigin, this.robotCellSize, puzzle, state.col, state.row, 0x8a7cff);
          this.robotStatusText?.setColor("#9ff5e9").setText(`Checkpoint ${outcome.checkpoint.label} validato. Prossimo sotto-obiettivo: ${outcome.nextCheckpoint ? `checkpoint ${outcome.nextCheckpoint.label}` : "chiave"}.`);
        }
        audioManager.play("footstep");
        if (this.overlay && this.robotSprite) {
          RobotConsole.addTrail(this, this.overlay, this.robotSprite);
        }
        this.tweens.add({
          targets: this.robotSprite,
          x: RobotConsole.cellX(this.robotOrigin, this.robotCellSize, state.col),
          y: RobotConsole.cellY(this.robotOrigin, this.robotCellSize, state.row),
          duration: 260,
          ease: "Sine.easeInOut",
          onComplete: () => this.runWhenActive(80, () => runAt(index + 1)),
        });
        return;
      } else if (outcome.kind === "picked") {
        state = outcome.state;
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
      } else if (outcome.kind === "exited") {
        state = outcome.state;
        this.robotStatusText?.setColor("#9ff5e9").setText("Percorso confermato: chiave recuperata e uscita raggiunta.");
        RobotConsole.flashCell(this, this.overlay, this.robotOrigin, this.robotCellSize, puzzle, state.col, state.row, 0x9ff5e9);
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
    };

    runAt(0);
  }

  private openDoor(): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const missing = this.requiredPuzzleIds().filter((id) => !this.isResolved(id));
    if (missing.length > 0) {
      feedbackSystem.publish(doorMissingFeedback(missing.map(puzzleKindLabel)), "hint");
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
      feedbackSystem.publish(chapterExploreCompletionFeedback(this.runEnergySummary()), "success");
      this.runWhenActive(1500, () => this.scene.start("CampaignScene"));
      return;
    }
    if (chapterMissionId) {
      // Winning the duel clears the chapter and unlocks the next one.
      audioManager.playOutcome("complete");
      outcomeFeedback.play(this, "complete", "Sabotatore respinto!");
      this.noraSay("bossDefeat");
      this.playLabRestoredFinale();
      const recoveredBefore = new Set(noraCompanion.memories().filter((memory) => memory.unlocked).map((memory) => memory.id));
      markMissionComplete(chapterMissionId);
      saveSystem.updateProceduralRun({ completedAt: new Date().toISOString() });
      this.run = saveSystem.data.proceduralRun ?? this.run;
      const recovered = noraCompanion.memories().find((memory) => memory.unlocked && !recoveredBefore.has(memory.id));
      noraPresence.storyMoment(this, "Il capitolo è salvo. Sento un ricordo avvicinarsi: non è più solo mio, Eli. Lo abbiamo riportato insieme.", "success", "NORA si ricompone");
      feedbackSystem.publish(chapterTrialCompletionFeedback(this.runEnergySummary()), "success");
      this.runWhenActive(3600, () => {
        if (recovered) this.showMemoryRecovered(recovered, () => this.scene.start("CampaignScene"));
        else this.scene.start("CampaignScene");
      });
      return;
    }
    const mode = proceduralRunRules.modeFor(this.run);
    const completionCopy = standardCompletionCopy(mode, this.runEnergySummary(), this.run.score?.total ?? 0, this.run.ghost);
    audioManager.playOutcome("complete");
    outcomeFeedback.play(this, "complete", completionCopy.outcomeLabel);
    if (mode !== "training") {
      this.noraSay("victory");
      noraPresence.storyMoment(this, "La stanza respira di nuovo. Io tengo la luce accesa; tu hai letto il sistema fino in fondo.", "success", "Sistema stabilizzato");
      this.playLabRestoredFinale();
    }
    missionEngine.completeProceduralMission();
    this.run = saveSystem.data.proceduralRun ?? this.run;
    const ghost = this.run.ghost;
    feedbackSystem.publish(completionCopy.feedback, "success");
    if (ghost) {
      noraPresence.speak(this, ghostNoraLine(this.run.score?.total ?? 0, ghost), "success", 4200);
    }
    this.runWhenActive(completionCopy.restartDelayMs, () => this.scene.start("JournalScene"));
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
    overlay.add(this.add.text(226, 112, `Porta di sintesi · Profondità ${level}/8`, {
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

  private solvePuzzle(puzzleId: string, competencies: string[]): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizePuzzleScore(puzzleId);
    saveSystem.markProceduralPuzzleSolved(puzzleId);
    competencyTracker.award(competencies, puzzleCompetencyAward(this.run.difficulty, score.focusBonus));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    const cleanSolve = isCleanPuzzleSolve(score);
    const solvedNode = puzzleKindFromId(puzzleId);
    const principle = solvedPrincipleForKind(solvedNode);
    this.playConsoleRestoredMoment(solvedNode);
    // Surface the learned principle prominently instead of only the score.
    outcomeFeedback.play(this, "success", `Principio: ${principle}`);
    if (cleanSolve) {
      saveSystem.recordMasteryAutonomy(masterySystem.branchForPuzzleKind(solvedNode));
      this.rewardCleanSolve();
    }
    this.clearOverlay();
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isResolved(id) && id !== solvedNode);
    feedbackSystem.publish(puzzleSolveFeedback(
      this.dependencies.effectLine(solvedNode),
      principle,
      score.total,
      formatDuration(score.elapsedMs),
      remaining.map(puzzleKindLabel),
    ), "success");
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
      latin: 0xd8c9ff,
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
    const reward = buildCleanSolveReward(this.run, proceduralRunRules.maxLives);
    if (Object.keys(reward.update).length > 0) {
      saveSystem.updateProceduralRun(reward.update);
      this.run = saveSystem.data.proceduralRun ?? this.run;
    }
    VisualKit.particleBurst(this, 640, 320, "circuit", "success");
    noraChip.say(this, reward.message, "success");
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
      feedbackSystem.publish(`Prossima console: ${puzzleKindLabel(nextPuzzleId)}. Rispondi con precisione: un errore costa una vita.`, "info");
      this.openPuzzleConsole(nextPuzzleId);
    });
  }

  private activePuzzleHintsUsed(): number {
    const puzzleId = this.activePuzzleId;
    if (!puzzleId) return 0;
    return (saveSystem.data.proceduralRun ?? this.run).puzzleStats?.[puzzleId]?.hintsUsed ?? 0;
  }

  private currentActiveHint(): string | undefined {
    return this.activeHintPuzzleId === this.activePuzzleId ? this.activeHintText : undefined;
  }

  private shouldShowExerciseCoach(kind: ProceduralPuzzleId): boolean {
    const branchId = masterySystem.branchForPuzzleKind(kind);
    const branch = masterySystem.getBranches().find((item) => item.id === branchId);
    if (!branch) return true;
    return branch.tier === 0 && branch.autonomy < 2;
  }

  private compactExerciseSubtitle(kind: ProceduralPuzzleId, learningSubtitle: string): string {
    if (this.shouldShowExerciseCoach(kind)) return learningSubtitle;
    return `${puzzleKindLabel(kind)} · modalità pratica`;
  }

  private useContextualHint(puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } }): void {
    const hints = puzzleHintTexts(puzzle);
    const used = this.activePuzzleHintsUsed();
    if (hints.length === 0 || used >= hints.length) {
      audioManager.playOutcome("hint");
      feedbackSystem.publish("Tutti gli indizi disponibili per questa prova sono già visibili.", "hint");
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
    noraPresence.speak(this, noraContextEngine.line("hint", { run: this.run, kind: this.activePuzzleKind }), "info", 3600);
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
    VisualKit.worldReact(this, "wrong");
    noraPresence.speak(this, noraContextEngine.line("mistake", { run: this.run, kind: this.activePuzzleKind, attempts }), "warning", 3900);
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
      this.certifyCompletedRun("Calibrazione conclusa: il registro include prove riuscite e fallite.");
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
    const failedKind = this.activePuzzleKind;
    const failedPuzzleId = this.activePuzzleId;
    const outcome = buildLifeLossOutcome({
      run: this.run,
      reason,
      isProgressive: this.isProgressiveMode(),
      isChapterTrial: this.isChapterTrial(),
      maxLivesFallback: proceduralRunRules.maxLives,
    });
    if (outcome.kind === "mission-failed") {
      this.failMissionNow(reason);
      return;
    }
    if (outcome.kind === "progressive-failed") {
      this.missionFailureInProgress = true;
      audioManager.playOutcome("wrong");
      this.discardActivePuzzleAttempt();
      this.clearOverlay();
      saveSystem.updateProceduralRun(outcome.update);
      this.run = saveSystem.data.proceduralRun ?? this.run;
      this.completeProgressiveLevel(false, reason);
      return;
    }

    if (failedKind) {
      this.rotatePuzzleVariant(failedKind, failedPuzzleId);
    }
    this.missionFailureInProgress = true;
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", outcome.outcomeLabel);
    this.noraSay(outcome.noraCue);
    this.discardActivePuzzleAttempt();
    this.clearOverlay();
    saveSystem.updateProceduralRun(outcome.update);
    this.run = saveSystem.data.proceduralRun ?? this.run;
    feedbackSystem.publish(outcome.feedback, "warning");
    this.runWhenActive(outcome.restartDelayMs, () => this.scene.restart());
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
          [kind]: kind === "latin" ? this.currentLatinPuzzle() : generated.puzzles[kind],
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
    saveSystem.updateProceduralRun(buildMissionFailureUpdate(now));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    feedbackSystem.publish(missionFailureFeedback(reason), "warning");
    this.showMissionFailure(reason);
  }

  /**
   * Celebratory reveal when a chapter win restores one of NORA's lost memories —
   * the intrinsic collection hook. Dismissing it continues to the Story.
   */
  private showMemoryRecovered(memory: NoraMemory, onContinue: () => void): void {
    const total = noraCompanion.memories().length;
    const recovered = noraCompanion.memories().filter((item) => item.unlocked).length;
    const modal = this.add.container(0, 0).setDepth(2100);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.86).setInteractive());
    modal.add(this.add.rectangle(640, 360, 760, 400, 0x0b0a1f, 0.99).setStrokeStyle(3, 0x9f8cff, 0.9));
    modal.add(this.add.rectangle(640, 360 - 200 + 4, 760, 6, 0x9f8cff, 0.95));
    VisualKit.particleBurst(this, 640, 232, "archive", "success");
    const stage = noraCompanion.currentVisualStage();
    if (this.textures.exists(stage.key)) {
      modal.add(this.add.image(640, 250, stage.key).setDisplaySize(360, 160).setAlpha(0.94));
      modal.add(this.add.rectangle(640, 250, 360, 160, 0x02070b, 0).setStrokeStyle(1, 0xcdbfff, 0.36));
    }
    modal.add(this.add.text(640, 178, "💜 RICORDO DI NORA RECUPERATO", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#cdbfff", fontStyle: "bold" }).setOrigin(0.5));
    modal.add(this.add.text(640, 338, memory.title, { fontFamily: "Inter, Arial", fontSize: "28px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: 680 }, align: "center" }).setOrigin(0.5, 0));
    modal.add(this.add.text(640, 386, `«${memory.text}»`, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#e6ddff", wordWrap: { width: 660 }, align: "center", lineSpacing: 5 }).setOrigin(0.5, 0));
    modal.add(this.add.text(640, 470, `Frammenti recuperati: ${recovered}/${total}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9f8cff", fontStyle: "bold" }).setOrigin(0.5));
    modal.add(new Button(this, 640, 512, "Continua ▸", () => { modal.destroy(true); onContinue(); }, {
      width: 300, height: 52, fill: 0x2a1f3a, stroke: 0x9f8cff, fontSize: 17, soundKey: "confirm",
    }));
    this.overlay = modal;
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
    overlay.add(this.add.text(568, 158, trial ? "Il Sabotatore ha vinto il round" : "Missione fallita", {
      fontFamily: "Inter, Arial",
      fontSize: trial ? "28px" : "34px",
      color: "#ffb0a8",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(570, 210, trial
      ? "Il tempo è scaduto e il sabotatore ha completato il sabotaggio del capitolo. Ma ora conosci le sue mosse: si torna sul ring per la rivincita."
      : "Le vite sono esaurite. La run è stata chiusa e non può essere ripresa.", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      wordWrap: { width: 550 },
      lineSpacing: 5,
    }));
    overlay.add(this.add.rectangle(570, 292, 568, 142, 0x102533, 0.82).setOrigin(0).setStrokeStyle(1, 0xc94b55, 0.38));
    overlay.add(this.add.text(594, 314, trial
      ? `Motivo: ${reason}\n\nConsiglio di NORA: prima della rivincita, calibra ${weakLabel ?? "il settore meno stabile"} nella Palestra — ogni risposta pulita gli toglie terreno.`
      : `Motivo: ${reason}\n\nI progressi di questa run restano nel registro. Ricomincia crea una missione nuova alla stessa profondità, con vite e timer ripristinati.`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 520 },
      lineSpacing: 5,
    }));
    overlay.add(new Button(this, 716, 568, trial ? "⚔️ Rivincita" : "Ricomincia", () => {
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
    const completion = buildProgressiveLevelCompletion(this.run, success, solvedCount, required.length, completedAt);
    if (!completion) {
      return;
    }
    if (success) this.unlockProgressiveTool(completion.result.level);
    saveSystem.updateProceduralRun({
      progressive: {
        ...progressive,
        unlockedLevel: completion.unlockedLevel,
        results: completion.results,
      },
      lives: this.run.lives,
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
    if (completion.finalCompleted) {
      this.completeProgressiveRun(completion.results);
    }
    this.showProgressiveOutcome(completion.result, reason, completion.results, completion.finalCompleted);
    if (!completion.finalCompleted && completion.resumeLevel) {
      this.parkProgressiveLevel(completion.resumeLevel, completion.results);
    }
  }

  private unlockProgressiveTool(level: DifficultyLevel): void {
    const unlock = progressiveToolUnlockForLevel(level);
    if (!unlock || saveSystem.data.inventory.includes(unlock.id)) return;
    saveSystem.addInventoryItem(unlock.id);
    feedbackSystem.publish(`Nuovo strumento NORA sbloccato — ${unlock.label}.`, "success");
  }

  private completeProgressiveRun(results: ProgressiveLevelResult[]): void {
    const completedAt = new Date().toISOString();
    const completionUpdate = buildProgressiveRunCompletionUpdate(this.run, results, completedAt);
    saveSystem.updateProceduralRun(completionUpdate);
    const completedRun = saveSystem.data.proceduralRun ?? {
      ...this.run,
      completedAt,
      score: completionUpdate.score,
    };
    playerSystem.recordProceduralRun(completedRun);
    saveSystem.completeMission("mission-progressive-scalata");
    saveSystem.addJournalEntry(buildProgressiveJournalEntry(
      completedRun,
      results,
      completedAt,
      formatDuration(progressiveTotalElapsedMs(results)),
    ));
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
        subtitle: "Hai stabilizzato alcuni sistemi, ma la profondità non è certificata.",
        tint: 0xffa15c,
        textColor: "#ffcb9a",
      },
      neutral: {
        title: "Esito neutro",
        subtitle: "Il ragionamento c'è, ma non basta ancora per sbloccare la profondità successiva.",
        tint: 0xc9d6dd,
        textColor: "#d9eaf1",
      },
      "light-victory": {
        title: "Vittoria leggera",
        subtitle: "Profondità superata: metodo corretto, margine migliorabile.",
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
      `Profondità: ${result.level}/${maxLevel}`,
      `Console stabilizzate: ${result.solvedCount}/${result.requiredCount}`,
      `Tempo usato: ${formatDuration(result.elapsedMs)}`,
      `Punti settore: ${result.score}`,
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
        : `NORA: profondità ${result.level} certificata. La profondità ${nextLevel} è ora accessibile.`
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
      overlay.add(new Button(this, 716, 608, result.completed ? "Profondità successiva" : "Riprova settore", () => {
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
      ? `Apri ${puzzleKindLabel(nextPuzzleId)} nella zona d'azione.`
      : mode === "progressive"
        ? "Apri la porta e collega i passaggi nell'ordine corretto."
        : mode === "training"
          ? "Apri la porta per registrare voto e miglior tempo."
          : "Apri la porta per chiudere la missione.";
    const contextLine = mode === "progressive"
      ? `Profondità ${progressiveLevel}/8: ${progressiveGoal}`
      : mode === "training"
        ? `Focus: ${proceduralScoring.domainLabel(focus)}`
        : this.run.chapterExploreMissionId
          ? "Fase Esplora: impara senza pressione."
          : this.run.chapterMissionId
            ? "Fase Prova: precisione e tempo contano."
            : "Missione: stabilizza il sistema completo.";
    const pressureEnabled = proceduralRunRules.pressureEnabledFor(this.run);
    const maxLives = this.run.maxLives ?? proceduralRunRules.maxLives;
    const lives = this.run.lives ?? maxLives;
    if (this.explorer) {
      const compactObjective = pendingObjectives.length > 0
        ? mode === "progressive"
          ? `${nextLabel}\nSi apre da sola.`
          : `${nextLabel}\nVai alla console e premi E.`
        : mode === "progressive"
          ? "Porta di sintesi\nCompleta il collegamento finale."
          : mode === "training"
            ? "Porta del registro\nPremi E per salvare."
            : "Porta finale\nPremi E per completare.";
      this.objectiveText?.setText(compactObjective);
      this.progressText?.setText(
        this.isChapterTrial()
          ? `Nodi ${solvedCount}/${requiredCount}\nTempo ${formatDuration(Math.max(0, remainingMs))} · Punti ${this.run.score?.total ?? 0}`
          : pressureEnabled
            ? `Fatte ${solvedCount}/${requiredCount}\nErrori ${lives}/${maxLives} · ${formatDuration(Math.max(0, remainingMs))}`
            : `Fatte ${solvedCount}/${requiredCount}\nTempo ${formatDuration(elapsed)}`,
      );
      return;
    }
    this.objectiveText?.setText(
      pendingObjectives.length > 0
        ? `${contextLine}\n\nORA\n${nextLabel}\n\nAZIONE\n${mode === "progressive" ? "La prossima console si apre da sola." : nextAction}`
        : mode === "progressive"
          ? `${contextLine}\n\nORA\nPorta di sintesi pronta.\n\nAZIONE\nCollega i settori per certificare la profondità.`
          : mode === "mission"
          ? `${contextLine}\n\nORA\nPorta finale pronta.\n\nAZIONE\nAprila per completare questa fase.`
          : `${contextLine}\n\nORA\nPorta del registro pronta.\n\nAZIONE\nAprila per salvare il risultato.`,
    );
    this.progressText?.setText(
      this.isChapterTrial()
        ? `Nodi disattivati: ${solvedCount}/${requiredCount}\nSabotatore: ${maxLives - lives}/${maxLives} avanzamenti\nTempo: ${formatDuration(Math.max(0, remainingMs))}\nPunti: ${this.run.score?.total ?? 0}`
        : pressureEnabled
        ? `Completate: ${solvedCount}/${requiredCount}\nErrori residui: ${lives}/${maxLives}\nTempo: ${formatDuration(Math.max(0, remainingMs))}\nPunti: ${this.run.score?.total ?? 0}`
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
      ? "il tempo è scaduto e il sabotatore ha completato il sabotaggio."
      : "tempo esaurito: la missione ha finito il tempo disponibile.");
    return true;
  }

  private requiredPuzzleIds(): string[] {
    return proceduralRequiredPuzzleIds(this.run.mission.objectives);
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
    const showCoach = this.shouldShowExerciseCoach("circuit");
    const overlay = this.createMathOverlay(puzzle.minigame.title, this.compactExerciseSubtitle("circuit", "Elettronica · leggi lo schema, scegli la risposta, conferma"));
    const prompt = currentCircuitMinigamePrompt(session);
    const remaining = circuitMinigameRemainingMs(session);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;

    this.circuitMinigameTimerText = CircuitConsole.addMinigamePrompt(this, overlay, prompt, {
      showCoach,
      selectedIds: session.selectedIds,
      remainingLabel: formatDuration(remaining),
      remainingDanger: remaining <= 10_000,
      streak: session.streak,
      netScore: session.netScore,
      accuracy,
      feedback: session.feedback,
      scoringRule: puzzle.minigame.scoringRule,
    }, {
      onToggleTile: (tileId) => this.toggleCircuitMinigameTile(tileId),
      onConfirm: () => this.confirmCircuitMinigamePrompt(),
      onHint: () => this.useCircuitMinigameHint(),
    });

    this.circuitMinigameTimerEvent?.remove(false);
    if (session.startedAt <= 0) session.startedAt = Date.now();
    this.circuitMinigameTimerEvent = this.time.addEvent({
      delay: 250,
      loop: true,
      callback: () => this.refreshCircuitMinigameTimer(),
    });
    this.refreshCircuitMinigameTimer();
  }

  private ensureCircuitMinigameSession(
    puzzleId: string,
    puzzle: GeneratedCircuitPuzzle,
    game: NonNullable<GeneratedCircuitPuzzle["minigame"]>,
  ): CircuitMinigameSession {
    if (this.circuitMinigameSession?.puzzleId === puzzleId && !this.circuitMinigameSession.summaryOpen) {
      return this.circuitMinigameSession;
    }
    const variant = this.run.retryVariants?.circuit ?? 0;
    const random = new Random(`${this.run.seed}:${puzzleId}:circuit:${variant}:${nextExerciseSalt()}`);
    const fresh = new CircuitFaultGenerator().generateMinigame(random, difficultyModel.getPreset(this.run.difficulty), [game.type]).minigame;
    const freshPrompts = fresh?.prompts?.length ? fresh.prompts : game.prompts;
    const variedGame = { ...game, prompts: random.shuffle(freshPrompts).map((prompt) => ({ ...prompt, tiles: random.shuffle(prompt.tiles) })) };
    this.circuitMinigameSession = createCircuitMinigameSession(puzzleId, puzzle, variedGame, game.durationMs);
    return this.circuitMinigameSession;
  }

  private refreshCircuitMinigameTimer(): void {
    const session = this.circuitMinigameSession;
    if (!session || session.summaryOpen || this.isSprintPaused()) {
      return;
    }
    const remaining = circuitMinigameRemainingMs(session);
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
    const prompt = currentCircuitMinigamePrompt(session);
    const hint = circuitMinigameHint(prompt);
    session.feedback = hint;
    this.useHint(hint);
    this.openCircuitMinigame(session.puzzle);
  }

  private confirmCircuitMinigamePrompt(): void {
    const session = this.circuitMinigameSession;
    if (!session || session.locked || session.summaryOpen) {
      return;
    }
    if (circuitMinigameRemainingMs(session) <= 0) {
      this.finishCircuitMinigame();
      return;
    }
    const prompt = currentCircuitMinigamePrompt(session);
    if (session.selectedIds.size === 0) {
      session.feedback = "Prima seleziona una risposta. Il timer continua.";
      audioManager.playOutcome("hint");
      this.openCircuitMinigame(session.puzzle);
      return;
    }
    const selected = prompt.tiles.find((tile) => tile.id === [...session.selectedIds][0]);
    // "Collega e si accende": energise the circuit so the student sees the real
    // behaviour (this also redraws the LED in its true lit state).
    if (prompt.visual?.kind === "led-circuit" && this.overlay) {
      const overlay = this.overlay;
      CircuitConsole.energizeMinigameCircuit(this, overlay, prompt.visual, () => this.overlay === overlay);
    }
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
      const showCircuitSolution = (): void => {
        this.showWrongSolution(selected?.label ?? "nessuna", prompt.solutionLabels.join(", "), this.diagnosticWrongExplanation(selected?.feedback, prompt.explanation), () => {
          session.startedAt += Date.now() - circuitPauseStart;
          this.advanceCircuitMinigamePrompt(0);
        });
      };
      // Let the "collega e si accende" animation play first, then explain why.
      if (prompt.visual?.kind === "led-circuit") this.runWhenActive(1200, showCircuitSolution);
      else showCircuitSolution();
      return;
    }

    session.answered += 1;
    session.correct += 1;
    session.streak += 1;
    session.bestStreak = Math.max(session.bestStreak, session.streak);
    const award = circuitMinigameCorrectAward(session, this.run.difficulty);
    session.netScore += award;
    session.feedback = `Corretto: ${prompt.explanation} +${award}`;
    session.locked = true;
    outcomeFeedback.answer(this, true, selected.label, prompt.solutionLabels.join(", "), prompt.explanation);
    audioManager.playOutcome("correct");
    outcomeFeedback.play(this, "success", `+${award}`);
    VisualKit.worldReact(this, "correct", { subtle: true, palette: "circuit" });
    this.cheerStreak(session.streak);
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
      if (circuitMinigameRemainingMs(session) <= 0) {
        this.finishCircuitMinigame();
        return;
      }
      const previous = currentCircuitMinigamePrompt(session).signature;
      session.promptIndex = (session.promptIndex + 1) % session.game.prompts.length;
      if (currentCircuitMinigamePrompt(session).signature === previous) {
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

  private showCircuitMinigameSummary(session: CircuitMinigameSession): void {
    const overlay = this.overlay ?? this.add.container(0, 0).setDepth(1200);
    const passed = circuitMinigamePassed(session, this.isTimedMissionMode(), this.run.difficulty);
    const accuracy = session.answered > 0 ? Math.round((session.correct / session.answered) * 100) : 0;
    const mode = proceduralRunRules.modeFor(this.run);
    CircuitConsole.addMinigameSummary(this, overlay, {
      passed,
      correct: session.correct,
      wrong: session.wrong,
      accuracy,
      bestStreak: session.bestStreak,
      netScore: session.netScore,
      feedback: circuitMinigameFeedback(session),
      resolutionText: (mode === "mission" || mode === "progressive")
        ? passed
          ? "La console elettronica certifica le tue risposte: componenti, percorso e valori sono coerenti."
          : "La soglia minima non è stata raggiunta: perderai una vita, ma il riepilogo mostra cosa ripassare."
        : "Calibrazione registrabile: il voto pesa precisione, velocità, serie corretta e uso degli aiuti.",
      energyText: this.runEnergySummary(),
      actionLabel: (mode === "mission" || mode === "progressive") && !passed ? "Ho capito" : "Registra e continua",
    }, {
      onAction: (modal) => {
        modal.destroy(true);
        if (!passed && (mode === "mission" || mode === "progressive")) {
          this.loseMissionLife("sprint circuiti sotto soglia: servono più risposte corrette con meno tentativi.");
          return;
        }
        this.completeCircuitMinigame(session);
      },
    });
  }

  private completeCircuitMinigame(session: CircuitMinigameSession): void {
    if (this.isRunInteractionLocked() || this.checkMissionTimeout()) {
      return;
    }
    const score = this.finalizeCircuitMinigameScore(session);
    this.completeSprintMinigameOutcome({
      session,
      score,
      competencies: session.game.competencies,
      copy: {
        summaryName: "Sprint circuiti",
        certification: "Console elettronica stabilizzata: il sistema completo è certificabile.",
      },
      clearSession: () => {
        this.circuitMinigameSession = undefined;
      },
      restartDelayMs: 1750,
    });
  }

  private finalizeCircuitMinigameScore(session: CircuitMinigameSession): ProceduralPuzzleScore {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[session.puzzleId];
    const score = buildCircuitMinigameScore(session, run, existing);
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
    return score;
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

  /**
   * Come currentMathPuzzle, ma se è aperto un minigioco a rotazione i cui prompt
   * cambiano concetto (frazioni → percentuali → decimali…), sovrascrive i
   * curriculumTags con il concetto del PROMPT corrente. Così la teoria (intro e
   * pulsante "Teoria NORA") corrisponde all'esercizio che lo studente ha davanti.
   */
  private mathPuzzleForTheory(): GeneratedMathPuzzle {
    const base = this.currentMathPuzzle();
    const session = this.mathMinigameSession;
    if (session && this.activePuzzleKind === "math" && !session.summaryOpen) {
      const concept = this.currentMathMinigamePrompt(session).concept;
      if (concept) {
        return { ...base, curriculumTags: [concept, ...(base.curriculumTags ?? [])] };
      }
    }
    return base;
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
    this.graphWorkshopReadingAnswers = {};
    this.graphWorkshopApplied = false;
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
    saveSystem.updateProceduralRun(buildPuzzleTimerStartUpdate(run, puzzleId));
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
    const update = buildPuzzleStatPatchUpdate(refreshed, puzzleId, { hintsUsed: stats.hintsUsed + 1 });
    if (update) {
      saveSystem.updateProceduralRun(update);
    }
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
    const update = buildPuzzleStatPatchUpdate(refreshed, puzzleId, { attempts: stats.attempts + 1 });
    if (update) {
      saveSystem.updateProceduralRun(update);
    }
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private finalizePuzzleScore(puzzleId: string) {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const existing = run.puzzleStats?.[puzzleId];
    const score = buildStandardPuzzleScore(run, puzzleId, existing);
    saveSystem.updateProceduralRun(buildScoreRunUpdate(run, score));
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
    return score;
  }

  private createExerciseScreen(title: string): Phaser.GameObjects.Container {
    this.clearOverlay();
    const overlay = createExerciseScreenChrome(this, {
      title,
      backgroundKey: exerciseBackgroundKey(this.activePuzzleKind),
      onClose: () => this.closeOverlayFromUser(),
      addTheoryButton: (container) => this.addNoraTheoryButton(container, 1066, 34),
    });
    this.overlay = overlay;
    return overlay;
  }

  private addNoraTheoryButton(overlay: Phaser.GameObjects.Container, x: number, y: number): void {
    const kind = this.activePuzzleKind;
    if (!kind) return;
    addNoraTheoryButtonToOverlay(this, overlay, kind, this.currentPuzzleForTheory(kind), x, y, (topic) => {
      // L'Atlante è una scena lazy: senza ensureScene lo start su chiave
      // non registrata non parte e lascia lo schermo nero.
      void startScene(this, "MathStudyScene", { pageId: topic.id }).catch(() => {
        feedbackSystem.publish("Non riesco ad aprire l'Atlante in questo momento: riprova tra un istante.", "warning");
      });
    });
  }

  private currentPuzzleForTheory(kind: ProceduralPuzzleId):
    | GeneratedLanguagePuzzle
    | GeneratedLatinPuzzle
    | GeneratedCircuitPuzzle
    | GeneratedMathPuzzle
    | GeneratedEnglishPuzzle
    | GeneratedRobotPuzzle
    | GeneratedCodingPuzzle
    | GeneratedMusicPuzzle
    | GeneratedPhysicsPuzzle {
    switch (kind) {
      case "language": return this.currentLanguagePuzzle();
      case "latin": return this.currentLatinPuzzle();
      case "circuit": return this.currentCircuitPuzzle();
      case "math": return this.mathPuzzleForTheory();
      case "english": return this.currentEnglishPuzzle();
      case "robot": return this.currentRobotPuzzle();
      case "coding": return this.currentCodingPuzzle();
      case "music": return this.currentMusicPuzzle();
      case "physics": return this.currentPhysicsPuzzle();
    }
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
