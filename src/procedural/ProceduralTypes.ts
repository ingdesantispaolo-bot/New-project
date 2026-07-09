import type { MissionReward } from "../types/missionTypes";

export type DifficultyLevel = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8;

export type ProceduralSpecialization =
  | "libera"
  | "matematica"
  | "italiano"
  | "inglese"
  | "elettronica"
  | "coding"
  | "musica"
  | "fisica";

export type ProceduralPuzzleKind = "language" | "circuit" | "math" | "english" | "robot" | "coding" | "music" | "physics";
export type ProceduralRunMode = "mission" | "training" | "progressive";

export type PedagogicalFocus =
  | "osservazione"
  | "ipotesi"
  | "diagnosi"
  | "strategia"
  | "controllo-errore"
  | "metacognizione";

export type HintStep = {
  level: 1 | 2 | 3 | 4;
  kind: "osservazione" | "restrizione" | "principio" | "quasi-soluzione";
  text: string;
};

export type ExerciseExplanation = {
  principle: string;
  workedExample: string;
  transferPrompt: string;
};

export type CommonMistake = {
  id: string;
  pattern: string;
  feedback: string;
  repairPrompt: string;
};

export type ExercisePedagogy = {
  phase: "osserva" | "formula-ipotesi" | "verifica-correggi";
  learningGoal: string;
  difficultyReason: string;
  hintLadder: HintStep[];
  commonMistakes: CommonMistake[];
  explanation: ExerciseExplanation;
};

export type DifficultyPreset = {
  level: DifficultyLevel;
  roomCount: number;
  puzzleCount: number;
  mathComplexity: number;
  robotGrid: { cols: number; rows: number };
  robotObstacleCount: number;
  circuitComplexity: number;
  availableHints: number;
  maxAttemptsBeforeExplanation: number;
  distractorCount: number;
  noiseDataCount: number;
  requiredReasoningSteps: number;
  pedagogicalFocus: PedagogicalFocus[];
};

export type GeneratedObjective = {
  id: string;
  label: string;
  description: string;
  competencies: string[];
};

export type MathMinigameType =
  | "target-sum"
  | "factor-hunt"
  | "operation-chain"
  | "number-sequence"
  | "expression-build"
  | "fraction-lab"
  | "ratio-proportion"
  | "geometry-measure"
  | "data-probability";

export type MathMinigameTile = {
  id: string;
  label: string;
  value?: number;
  isCorrect: boolean;
  feedback: string;
};

export type MathGeometryVisual = {
  shape: "rectangle" | "triangle" | "box" | "right-triangle" | "circle";
  measure: "perimeter" | "area" | "volume" | "hypotenuse" | "circumference";
  unit: string;
  width?: number;
  height?: number;
  length?: number;
  depth?: number;
  base?: number;
  radius?: number;
  a?: number;
  b?: number;
  c?: number;
};

export type MathMinigamePrompt = {
  id: string;
  type: MathMinigameType;
  prompt: string;
  targetLabel: string;
  requiredSelectionCount: number;
  tiles: MathMinigameTile[];
  solutionLabels: string[];
  explanation: string;
  concept: string;
  /** Fixed operands for the "expression-build" (operator insertion) minigame. */
  numbers?: number[];
  /** Target value for the "expression-build" minigame. */
  target?: number;
  /** Optional visual metadata for geometry minigame diagrams. */
  geometryVisual?: MathGeometryVisual;
  signature: string;
};

export type GeneratedMathMinigame = {
  type: MathMinigameType;
  title: string;
  durationMs: number;
  instructions: string;
  scoringRule: string;
  prompts: MathMinigamePrompt[];
  competencies: string[];
};

export type EquationLabDegree = 1 | 2;
export type EquationLabVisual = "balance" | "inverse-steps" | "substitution" | "standard-form" | "discriminant" | "factorization" | "formula" | "parabola";

export type EquationLabStage = {
  id: string;
  title: string;
  prompt: string;
  options: string[];
  correctOption: string;
  explanation: string;
  visual: EquationLabVisual;
};

export type GeneratedEquationLab = {
  degree: EquationLabDegree;
  equation: string;
  coefficients: { a: number; b: number; c: number };
  roots: number[];
  discriminant?: number;
  principle: string;
  verification: string;
  stages: EquationLabStage[];
};

export type GraphWorkshopMode = "beacon-line" | "vertex-shift" | "root-gates" | "curve-match";
export type GraphFunctionKind = "linear" | "quadratic";
export type GraphParameterKey = "m" | "q" | "a" | "h" | "k";

export type GraphWorkshopParameter = {
  key: GraphParameterKey;
  label: string;
  meaning: string;
  min: number;
  max: number;
  step: number;
  target: number;
  initial: number;
};

export type GraphReadingStep = {
  key: string;
  label: string;
  prompt: string;
  correctValue: number;
  options: number[];
  explanation: string;
  parameterKey?: GraphParameterKey;
};

export type GeneratedGraphWorkshop = {
  mode: GraphWorkshopMode;
  functionKind: GraphFunctionKind;
  objective: string;
  targetFormula: string;
  principle: string;
  parameters: GraphWorkshopParameter[];
  readingSteps?: GraphReadingStep[];
  targetPoints: Array<{ x: number; y: number; label: string }>;
  showTargetCurve: boolean;
  xRange: [number, number];
  yRange: [number, number];
  successExplanation: string;
};

export type GeneratedMathPuzzle = {
  id: string;
  title: string;
  prompt: string;
  answer: number;
  hints: string[];
  competencies: string[];
  difficultyLevel?: DifficultyLevel;
  difficultyLabel?: string;
  learningPurpose?: string;
  calculationAid?: {
    mentalMathNote: string;
    strategy: string;
    scratchpadPrompt: string;
  };
  archetype?:
    | "calcolo-diretto"
    | "ragionamento-inverso"
    | "sequenza"
    | "vincolo"
    | "diagnosi-errore"
    | "lettura-dati"
    | "proporzione"
    | "pre-algebra"
    | "frazioni"
    | "percentuali"
    | "geometria"
    | "statistica"
    | "probabilita"
    | "potenze-radici"
    | "funzione-lineare"
    | "sistemi-lineari"
    | "equazione-primo-grado"
    | "equazione-secondo-grado"
    | "grafici-cartesiani"
    | "coordinate";
  curriculumTags?: string[];
  solutionSteps?: string[];
  pedagogy?: ExercisePedagogy;
  minigame?: GeneratedMathMinigame;
  equationLab?: GeneratedEquationLab;
  graphWorkshop?: GeneratedGraphWorkshop;
};

export type GridFacing = "N" | "E" | "S" | "W";
export type GridCommand = "MOVE_FORWARD" | "TURN_LEFT" | "TURN_RIGHT" | "PICK_UP" | "EXIT";
export type RobotChallengeType =
  | "route-planning"
  | "minimal-route"
  | "checkpoint-order"
  | "debug-program"
  | "pattern-routing"
  | "coordinate-routing"
  | "conditional-gate"
  | "loop-compression";

export type RobotCheckpoint = {
  col: number;
  row: number;
  label: string;
  order: number;
};

export type GeneratedRobotPuzzle = {
  id: string;
  title: string;
  instructions: string[];
  cols: number;
  rows: number;
  start: { col: number; row: number; facing: GridFacing };
  key: { col: number; row: number };
  exit: { col: number; row: number };
  obstacles: Array<{ col: number; row: number }>;
  solutionCommands: GridCommand[];
  hints: string[];
  competencies: string[];
  challengeType?: RobotChallengeType;
  checkpoints?: RobotCheckpoint[];
  buggedCommands?: GridCommand[];
  debugBrief?: string;
  successConditions?: string[];
  conceptTags?: string[];
  maxCommands?: number;
  requiredConcepts?: string[];
  routeBrief?: string;
  visualFocus?: string;
  coordinateLabels?: boolean;
  planningPrompt?: string;
  pedagogy?: ExercisePedagogy;
};

export type CodingChallengeType =
  | "trace-output"
  | "variable-state"
  | "loop-count"
  | "conditional-branch"
  | "boolean-logic"
  | "debug-line";

export type GeneratedCodingPuzzle = {
  id: string;
  title: string;
  challengeType: CodingChallengeType;
  difficultyLabel: string;
  scenario: string;
  codeLines: string[];
  question: string;
  options: string[];
  correctOption: string;
  hints: string[];
  conceptTags: string[];
  methodSteps: string[];
  learningPurpose: string;
  explanation: string;
  /** Per-option diagnostic feedback keyed by option text (console puzzles). */
  optionFeedback?: Record<string, string>;
  competencies: string[];
  maxSeconds?: number;
  pedagogy?: ExercisePedagogy;
  minigame?: GeneratedCodingMinigame;
};

export type CodingMinigameType =
  | "sequence-builder"
  | "state-tracer"
  | "bug-hunt"
  | "binary-bits"
  | "logic-gate"
  | "loop-output"
  | "conditional-path"
  | "algorithm-order"
  | "python-lab"
  | "language-atlas";

export type CodingMinigameTile = {
  id: string;
  label: string;
  isCorrect: boolean;
  feedback: string;
};

export type CodingMinigamePrompt = {
  id: string;
  type: CodingMinigameType;
  title: string;
  codeLines: string[];
  question: string;
  targetLabel: string;
  requiredSelectionCount: number;
  tiles: CodingMinigameTile[];
  solutionLabels: string[];
  explanation: string;
  concept: string;
  methodSteps: string[];
  signature: string;
};

export type GeneratedCodingMinigame = {
  type: CodingMinigameType;
  title: string;
  durationMs: number;
  instructions: string;
  scoringRule: string;
  prompts: CodingMinigamePrompt[];
  competencies: string[];
};

export type CircuitFaultType =
  | "missing-wire"
  | "open-switch"
  | "reversed-led"
  | "missing-resistor"
  | "disconnected-component"
  | "sensor-unpowered"
  | "capacitor-discharged"
  | "short-circuit"
  | "parallel-branch-open"
  | "wrong-resistor-value"
  | "relay-not-armed"
  | "loose-ground";

export type CircuitComponentInfo = {
  id: string;
  label: string;
  role: string;
  check: string;
  symbolName?: string;
  functionSummary?: string;
  symbolClue?: string;
  commonConfusion?: string;
};

export type CircuitComponentChallenge = {
  componentId: string;
  componentLabel: string;
  symbolQuestion: string;
  functionQuestion: string;
  correctSymbol: string;
  correctFunction: string;
  symbolChoices: string[];
  functionChoices: string[];
  visualHint: string;
  explanation: string;
};

export type GeneratedCircuitPuzzle = {
  id: string;
  title: string;
  symptom: string;
  observations: string[];
  nodes: string[];
  edges: Array<{ from: string; to: string }>;
  faults: CircuitFaultType[];
  requiredRepairs: CircuitFaultType[];
  hints: string[];
  competencies: string[];
  scenarioType?:
    | "percorso-aperto"
    | "corrente-instabile"
    | "polarita"
    | "multi-guasto"
    | "serie-parallelo"
    | "sensore-soglia"
    | "logica-rele"
    | "temporizzazione"
    | "corto-circuito";
  diagnosticQuestion?: string;
  testerReadings?: Array<{
    from: string;
    to: string;
    reading:
      | "continuita"
      | "interrotto"
      | "polarita-inversa"
      | "non-stabile"
      | "corto"
      | "tensione-bassa"
      | "soglia-fuori-range"
      | "carica-bassa";
    note: string;
  }>;
  explanationByFault?: Partial<Record<CircuitFaultType, string>>;
  componentGuide?: CircuitComponentInfo[];
  circuitGoal?: string;
  repairChoices?: CircuitFaultType[];
  diagnosticPlan?: string[];
  difficultyLabel?: string;
  learningPurpose?: string;
  conceptTags?: string[];
  componentChallenges?: CircuitComponentChallenge[];
  pedagogy?: ExercisePedagogy;
  minigame?: GeneratedCircuitMinigame;
};

export type CircuitMinigameType = "component-id" | "predict-led" | "ohms-law" | "series-parallel";

export type CircuitMinigameTile = {
  id: string;
  label: string;
  isCorrect: boolean;
  feedback: string;
};

/** Drawable schematic for a circuit minigame prompt, rendered by the scene. */
export type CircuitMinigameVisual =
  | { kind: "led-circuit"; switchClosed: boolean; ledForward: boolean; hasResistor: boolean; hasOpen: boolean; lit: boolean }
  | { kind: "component"; component: string };

export type CircuitMinigamePrompt = {
  id: string;
  type: CircuitMinigameType;
  title: string;
  diagramLines: string[];
  question: string;
  targetLabel: string;
  requiredSelectionCount: number;
  tiles: CircuitMinigameTile[];
  solutionLabels: string[];
  explanation: string;
  concept: string;
  methodSteps: string[];
  visual?: CircuitMinigameVisual;
  signature: string;
};

export type GeneratedCircuitMinigame = {
  type: CircuitMinigameType;
  title: string;
  durationMs: number;
  instructions: string;
  scoringRule: string;
  prompts: CircuitMinigamePrompt[];
  competencies: string[];
};

export type GeneratedLanguagePuzzle = {
  id: string;
  title: string;
  corrupted: string;
  repaired: string;
  options: string[];
  diagnosticSteps: string[];
  hints: string[];
  competencies: string[];
  difficultyLabel?: string;
  conceptTags?: string[];
  learningPurpose?: string;
  repairGoal?: string;
  method?: string;
  optionFeedback?: Record<string, string>;
  minigame?: GeneratedLanguageMinigame;
};

export type LanguageMinigameType = "agreement-sprint" | "connector-route" | "intruder-hunt" | "word-order" | "lexicon-lab" | "verb-mastery" | "punctuation-fix" | "argument-sort";

export type LanguageMinigameTile = {
  id: string;
  label: string;
  isCorrect: boolean;
  feedback: string;
};

export type LanguageMinigamePrompt = {
  id: string;
  type: LanguageMinigameType;
  prompt: string;
  context: string;
  targetLabel: string;
  requiredSelectionCount: number;
  tiles: LanguageMinigameTile[];
  solutionLabels: string[];
  explanation: string;
  concept: string;
  signature: string;
  /** "typed" turns the prompt into a production exercise (type the answer). */
  inputMode?: "tiles" | "typed";
  /** Normalised answers accepted when inputMode is "typed". */
  acceptedAnswers?: string[];
};

export type GeneratedLanguageMinigame = {
  type: LanguageMinigameType;
  title: string;
  durationMs: number;
  instructions: string;
  scoringRule: string;
  prompts: LanguageMinigamePrompt[];
  competencies: string[];
  /** Comprehension-heavy sprints run in a calmer, longer "reflective" mode. */
  reflective?: boolean;
};

export type EnglishChallengeType =
  | "command"
  | "safety"
  | "sequence"
  | "condition"
  | "data-reading"
  | "procedure-debug"
  | "vocabulary-in-context"
  | "translation-recognition"
  | "inference";

export type GeneratedEnglishPuzzle = {
  id: string;
  title: string;
  challengeType?: EnglishChallengeType;
  scenario?: string;
  taskPrompt?: string;
  instruction: string;
  sourceText?: string;
  dataPoints?: Array<{ label: string; value: string; note?: string }>;
  choices: Array<{
    id: string;
    label: string;
    isCorrect: boolean;
    feedback: string;
  }>;
  diagnosticSteps: string[];
  hints: string[];
  competencies: string[];
  difficultyLabel?: string;
  conceptTags?: string[];
  learningPurpose?: string;
  commandGoal?: string;
  method?: string;
  methodSteps?: string[];
  glossary?: Array<{ term: string; meaning: string }>;
  minigame?: GeneratedEnglishMinigame;
};

export type EnglishMinigameType =
  | "action-relay"
  | "sequence-switchboard"
  | "data-command-scan"
  | "grammar-fix"
  | "sentence-build"
  | "vocab-lab"
  | "translation-match"
  | "reading-detective"
  | "error-diagnosis"
  | "dialogue-response";

export type EnglishMinigameTile = {
  id: string;
  label: string;
  isCorrect: boolean;
  feedback: string;
};

export type EnglishMinigamePrompt = {
  id: string;
  type: EnglishMinigameType;
  instruction: string;
  context: string;
  targetLabel: string;
  requiredSelectionCount: number;
  tiles: EnglishMinigameTile[];
  solutionLabels: string[];
  explanation: string;
  concept: string;
  glossary: Array<{ term: string; meaning: string }>;
  dataPoints?: Array<{ label: string; value: string; note?: string }>;
  signature: string;
};

export type GeneratedEnglishMinigame = {
  type: EnglishMinigameType;
  title: string;
  durationMs: number;
  instructions: string;
  scoringRule: string;
  prompts: EnglishMinigamePrompt[];
  competencies: string[];
};

export type MusicClef = "treble" | "bass";
export type MusicNoteName = "Do" | "Re" | "Mi" | "Fa" | "Sol" | "La" | "Si";
export type MusicMinigameType =
  | "note-hunt"
  | "interval-jump"
  | "rhythm-gap"
  | "scale-step"
  | "note-duration"
  | "auditory-note"
  | "auditory-interval";

export type GeneratedMusicPuzzle = {
  id: string;
  title: string;
  challengeMode: MusicMinigameType;
  clef: MusicClef;
  noteName: MusicNoteName;
  octave: number;
  staffPosition: number;
  ledgerLines: number[];
  timeLimitMs: number;
  answerMode: "note-name" | "note-and-octave";
  secondaryNote?: {
    noteName: MusicNoteName;
    octave: number;
    staffPosition: number;
    ledgerLines: number[];
  };
  audioPrompt?: {
    kind: "single-note" | "interval";
    hiddenStaff: boolean;
    replayLabel: string;
  };
  rhythmPattern?: {
    beatsPerMeasure: number;
    missingBeats: number;
    cells: Array<{ label: string; beats: number; missing?: boolean }>;
  };
  choices: Array<{
    id: string;
    label: string;
    isCorrect: boolean;
    feedback: string;
  }>;
  hints: string[];
  competencies: string[];
  difficultyLabel: string;
  learningPurpose: string;
  method: string;
  methodSteps: string[];
  conceptTags: string[];
};

export type PhysicsExerciseType =
  | "motion-graph"
  | "unit-check"
  | "force-diagram"
  | "energy-transfer"
  | "experiment-order"
  | "density-pressure"
  | "heat-temperature"
  | "wave-reading"
  | "optics-ray";

export type PhysicsVisualKind =
  | "motion-graph"
  | "force-diagram"
  | "energy-flow"
  | "unit-card"
  | "experiment-steps"
  | "fluid-column"
  | "thermal-scale"
  | "wave"
  | "ray";

export type PhysicsVisualData = {
  kind: PhysicsVisualKind;
  title: string;
  labels: string[];
  values?: number[];
  highlight?: string;
};

export type GeneratedPhysicsPuzzle = {
  id: string;
  title: string;
  exerciseType: PhysicsExerciseType;
  difficultyLabel: string;
  scenario: string;
  prompt: string;
  options: string[];
  correctOption: string;
  hints: string[];
  conceptTags: string[];
  methodSteps: string[];
  learningPurpose: string;
  explanation: string;
  /** Per-option diagnostic feedback keyed by option text: names why a specific
   *  wrong choice is wrong (misconception), not just the correct answer. */
  optionFeedback?: Record<string, string>;
  competencies: string[];
  visual: PhysicsVisualData;
};

export type GeneratedRoomHotspot = {
  id: string;
  label: string;
  x: number;
  y: number;
  radius: number;
  puzzleId?: string;
  puzzleKind?: ProceduralPuzzleKind;
  description: string;
};

export type GeneratedRoomMap = {
  id: string;
  title: string;
  roomCount: number;
  hotspots: GeneratedRoomHotspot[];
};

export type GeneratedMission = {
  id: string;
  seed: string;
  difficulty: DifficultyLevel;
  title: string;
  intro: string;
  objectives: GeneratedObjective[];
  map: GeneratedRoomMap;
  puzzles: {
    math: GeneratedMathPuzzle;
    robot: GeneratedRobotPuzzle;
    circuit: GeneratedCircuitPuzzle;
    language: GeneratedLanguagePuzzle;
    english: GeneratedEnglishPuzzle;
    music: GeneratedMusicPuzzle;
    coding: GeneratedCodingPuzzle;
    physics: GeneratedPhysicsPuzzle;
  };
  focusChallenges?: GeneratedFocusChallenge[];
  rewards: MissionReward[];
  competencies: string[];
};

export type GeneratedFocusChallenge =
  | {
      id: string;
      kind: "math";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedMathPuzzle;
    }
  | {
      id: string;
      kind: "language";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedLanguagePuzzle;
    }
  | {
      id: string;
      kind: "english";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedEnglishPuzzle;
    }
  | {
      id: string;
      kind: "circuit";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedCircuitPuzzle;
    }
  | {
      id: string;
      kind: "robot";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedRobotPuzzle;
    }
  | {
      id: string;
      kind: "coding";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedCodingPuzzle;
    }
  | {
      id: string;
      kind: "music";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedMusicPuzzle;
    }
  | {
      id: string;
      kind: "physics";
      title: string;
      description: string;
      difficultyStep: number;
      puzzle: GeneratedPhysicsPuzzle;
    };

export type ProceduralPuzzleScore = {
  puzzleId: string;
  domain: ProceduralSpecialization;
  startedAt: string;
  completedAt?: string;
  elapsedMs: number;
  hintsUsed: number;
  attempts: number;
  basePoints: number;
  difficultyBonus: number;
  speedBonus: number;
  focusBonus: number;
  supportPenalty: number;
  total: number;
  feedback: string;
};

export type ProceduralScoreSummary = {
  total: number;
  byPuzzle: Record<string, number>;
  byDomain: Partial<Record<ProceduralSpecialization, number>>;
  lastAward?: ProceduralPuzzleScore;
};

export type TrainingRunResult = {
  focus: ProceduralSpecialization;
  difficulty: DifficultyLevel;
  elapsedMs: number;
  score: number;
  grade: number;
  gradeLabel: string;
  nextGoal: string;
  hintsUsed: number;
  completedAt: string;
  bestTimeMs?: number;
};

export type ProgressiveOutcomeTone =
  | "devastating-defeat"
  | "defeat"
  | "neutral"
  | "light-victory"
  | "grand-victory";

export type ProgressiveLevelResult = {
  level: DifficultyLevel;
  completed: boolean;
  solvedCount: number;
  requiredCount: number;
  elapsedMs: number;
  score: number;
  outcome: ProgressiveOutcomeTone;
  completedAt: string;
};

export type ProgressiveRunState = {
  currentLevel: DifficultyLevel;
  unlockedLevel: DifficultyLevel;
  maxLevel: DifficultyLevel;
  levelStartedAt: string;
  levelTimeLimitMs: number;
  levelDeadlineAt: string;
  results: ProgressiveLevelResult[];
};

export type ProceduralRunSave = {
  seed: string;
  difficulty: DifficultyLevel;
  focus: string[];
  mode?: ProceduralRunMode;
  mission: GeneratedMission;
  hintsUsed: number;
  noraChargesUsed?: number;
  noraLensUsed?: boolean;
  retryVariants?: Partial<Record<ProceduralPuzzleKind, number>>;
  solvedPuzzleIds: string[];
  failedPuzzleIds?: string[];
  puzzleStats?: Record<string, ProceduralPuzzleScore>;
  score?: ProceduralScoreSummary;
  lives?: number;
  maxLives?: number;
  timeLimitMs?: number;
  deadlineAt?: string;
  pausedRemainingMs?: number;
  timerState?: "preparing" | "ready" | "running" | "paused";
  createdAt?: string;
  activeElapsedMs?: number;
  failedAt?: string;
  trainingResult?: TrainingRunResult;
  progressive?: ProgressiveRunState;
  /**
   * When set, this run is a graded "Prova del Capitolo" (chapter trial): passing
   * it completes the given campaign mission and unlocks the next chapter; failing
   * it (out of the 3-error budget or time) sends the player back to the Story.
   */
  chapterMissionId?: string;
  /**
   * Low-pressure "Fase Esplora" for the chapter. It uses the same mission room
   * machinery but never unlocks the chapter: completion only enables the trial.
   */
  chapterExploreMissionId?: string;
  startedAt: string;
  completedAt?: string;
};
