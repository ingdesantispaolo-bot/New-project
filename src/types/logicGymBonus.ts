export type LogicGymBonusActivityKey = "tables" | "mental" | "geo" | "geoPhysical";

export type LogicGymBonusResult = {
  id: string;
  activityKey: LogicGymBonusActivityKey;
  label: string;
  level: number;
  rounds: number;
  correct: number;
  score: number;
  accuracy: number;
  passed: boolean;
  perfect: boolean;
  energyAward: number;
  timeAwardMs: number;
  summary: string;
};

export type LogicGymSceneData = {
  mode?: "missionBonus";
  activityKey?: LogicGymBonusActivityKey;
  bonusId?: string;
  level?: number;
  rounds?: number;
  returnScene?: string;
};
