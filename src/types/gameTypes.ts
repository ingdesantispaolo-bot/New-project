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
  trainingRecords?: Record<string, TrainingRecord>;
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
