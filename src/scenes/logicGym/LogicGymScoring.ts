import type { LogicGymBonusResult } from "../../types/logicGymBonus";
import type { LogicGymBonusActivityKey } from "../../types/logicGymBonus";

export type TimedActivityScoreInput = {
  correct: number;
  total: number;
  bestCombo: number;
  timeBonus: number;
  level: number;
  comboWeight: number;
  levelWeight: number;
};

export type ActivityAwardInput = {
  correct: number;
  bestCombo: number;
  level: number;
  cap?: number;
};

export type MissionBonusStats = {
  correct: number;
  total: number;
  bestCombo: number;
};

export function accuracyPercent(correct: number, total: number): number {
  return Math.round((correct / Math.max(1, total)) * 100);
}

export function timedActivityScore(input: TimedActivityScoreInput): number {
  return accuracyPercent(input.correct, input.total)
    + input.bestCombo * input.comboWeight
    + input.timeBonus
    + input.level * input.levelWeight;
}

export function activityAward(input: ActivityAwardInput): number {
  return Math.min(input.cap ?? 24, 5 + input.correct + Math.floor(input.bestCombo / 2) + Math.floor(input.level / 2));
}

export function memoryEfficiencyScore(pairs: number, moves: number, level: number): { efficiency: number; score: number } {
  const perfectMoves = pairs;
  const efficiency = Math.max(0, Math.round((perfectMoves / Math.max(perfectMoves, moves)) * 100));
  return { efficiency, score: efficiency + level * 4 };
}

export function roundAccuracyScore(correct: number, total: number, level: number, levelWeight = 3): number {
  return accuracyPercent(correct, total) + level * levelWeight;
}

export function firewallScore(input: {
  correct: number;
  total: number;
  level: number;
  stability: number;
  bestStreak: number;
  errors: number;
}): number {
  return Math.max(0, accuracyPercent(input.correct, input.total) + input.level * 4 + input.stability + input.bestStreak * 3 - input.errors * 4);
}

export function missionBonusResult(input: {
  id: string;
  activityKey: LogicGymBonusActivityKey;
  label: string;
  level: number;
  score: number;
  summary: string;
  stats: MissionBonusStats;
}): LogicGymBonusResult {
  const accuracy = input.stats.total > 0 ? accuracyPercent(input.stats.correct, input.stats.total) : 0;
  const passed = input.stats.total > 0 && input.stats.correct >= Math.ceil(input.stats.total * 0.6) && accuracy >= 60;
  const perfect = input.stats.total > 0 && input.stats.correct === input.stats.total;
  const energyAward = passed ? Math.min(95, 32 + input.level * 4 + input.stats.bestCombo * 5 + (perfect ? 18 : 0)) : 0;
  const timeAwardMs = passed ? (perfect ? 20_000 : accuracy >= 80 ? 12_000 : 0) : 0;
  return {
    id: input.id,
    activityKey: input.activityKey,
    label: input.label,
    level: input.level,
    rounds: input.stats.total,
    correct: input.stats.correct,
    score: input.score,
    accuracy,
    passed,
    perfect,
    energyAward,
    timeAwardMs,
    summary: input.summary,
  };
}
