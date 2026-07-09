import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization } from "../procedural/ProceduralTypes";

export type SceneKey =
  | "BootScene"
  | "PreloadScene"
  | "MainMenuScene"
  | "HubScene"
  | "LaboratoryScene"
  | "CircuitPuzzleScene"
  | "RobotCodingScene"
  | "MathLockScene"
  | "JournalScene"
  | "LeaderboardScene"
  | "PlayerReportScene"
  | "ProceduralMissionScene";

export type SaveData = {
  version: number;
  playerId?: string;
  activeMissionId: string;
  exerciseSeed: string;
  completedMissionIds: string[];
  inventory: string[];
  competencies: Record<string, number>;
  flags: Record<string, boolean>;
  journalEntries: JournalEntry[];
  proceduralRun?: ProceduralRunSave;
  proceduralMissionRun?: ProceduralRunSave;
  proceduralTrainingRun?: ProceduralRunSave;
  proceduralProgressiveRun?: ProceduralRunSave;
  trainingRecords?: Record<string, TrainingRecord>;
  learningMemory?: Record<string, { count: number; lastAt: string }>;
  /** Autonomous clean solves per mastery branch (first try, no hints). */
  masteryAutonomy?: Record<string, number>;
  /** NORA companion state: progress memory, tone preference, seen memories. */
  nora?: {
    masterySnapshot?: Record<string, { score: number; tier: number }>;
    tone?: "curiosa" | "coraggiosa" | "gentile";
    memoriesSeen?: string[];
  };
  /** The player's personalised home base. */
  academy?: {
    name?: string;
    emblem?: string;
  };
  /** Boss arc: how many times the Eco has been defeated (drives escalation + story). */
  eco?: {
    defeats: number;
  };
  /** Discovery pillar: ids of memory fragments the player has uncovered. */
  collection?: {
    discovered: string[];
  };
  /** Reward progression: energy earned by answering, spent on cosmetics. */
  rewards?: {
    /** Spendable balance. */
    energy: number;
    /** Lifetime earned (never decreases), for stats. */
    earned: number;
    /** Ids of cosmetics bought. */
    unlocked: string[];
    /** Equipped cosmetic id per slot (e.g. "bot" -> "bot-gold"). */
    equipped: Record<string, string>;
  };
  /** Logic & memory gym: best score reached per activity. */
  logicGym?: {
    best: Record<string, number>;
    level?: number;
    bestByLevel?: Record<string, Record<string, number>>;
  };
  greenhouseRun?: GreenhouseRunSave;
  numberFactoryRun?: NumberFactoryRunSave;
};

export type TrainingRecord = {
  key: string;
  focus: ProceduralSpecialization;
  difficulty: DifficultyLevel;
  bestTimeMs: number;
  bestGrade: number;
  bestScore: number;
  lastTimeMs: number;
  lastGrade: number;
  lastScore: number;
  runs: number;
  completedAt: string;
};

export type GreenhouseRunSave = {
  turn: number;
  selectedPlantId: string;
  adjustmentUsedThisTurn: boolean;
  plants: Array<{
    id: string;
    values: {
      water: number;
      light: number;
      temperature: number;
    };
    health: number;
    history: number[];
  }>;
};

export type NumberFactoryRunSave = {
  orderIndex: number;
  currentValue: number;
  expression: string;
  steps: string[];
  machineHistoryIds: string[];
  completedOrderIds: string[];
};

export type JournalEntry = {
  id: string;
  title: string;
  lines: string[];
  badges: string[];
  createdAt: string;
};

export type FeedbackTone = "info" | "hint" | "success" | "warning";

export type InteractiveHotspot = {
  id: string;
  label: string;
  x: number;
  y: number;
  radius: number;
  description: string;
};
