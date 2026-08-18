export type ObjectiveStatus = "locked" | "active" | "complete";

export type MissionObjective = {
  id: string;
  label: string;
  description: string;
  requiredFlags?: string[];
  unlocksFlag?: string;
  competencies?: string[];
};

export type MissionReward = {
  badgeId: string;
  label: string;
  description: string;
};

export type MissionDefinition = {
  id: string;
  title: string;
  description: string;
  openingDialogueId: string;
  objectives: MissionObjective[];
  requiredItems: string[];
  puzzles: string[];
  dialogues: string[];
  competencies: string[];
  rewards: MissionReward[];
  nextMissionId?: string;
};
