import type { ProceduralPuzzleId } from "./ProceduralMissionLayout";

export interface SprintCompletionCopy {
  summaryName: string;
  certification: string;
  bestStreakLabel?: string;
}

export interface SprintCompletionInput {
  solvedKind: ProceduralPuzzleId;
  correct: number;
  wrong: number;
  bestStreak: number;
  difficulty: number;
  scoreTotal: number;
  energySummary: string;
  remainingLabels: string[];
  copy: SprintCompletionCopy;
  maxScoreBonus?: number;
  scoreDivisor?: number;
}

export interface SprintCompletionOutcome {
  solvedKind: ProceduralPuzzleId;
  shouldRecordAutonomy: boolean;
  competencyAward: number;
  feedback: string;
  certification: string;
}

export function sprintCompetencyAward(
  difficulty: number,
  scoreTotal: number,
  maxScoreBonus = 12,
  scoreDivisor = 32,
): number {
  return 8 + difficulty * 2 + Math.min(maxScoreBonus, Math.floor(scoreTotal / scoreDivisor));
}

export function sprintShouldRecordAutonomy(correct: number, wrong: number): boolean {
  return wrong === 0 && correct > 0;
}

export function buildSprintCompletionOutcome(input: SprintCompletionInput): SprintCompletionOutcome {
  const remainingText = input.remainingLabels.length > 0
    ? `Restano: ${input.remainingLabels.join(", ")}.`
    : "La porta finale è pronta.";
  const bestStreakLabel = input.copy.bestStreakLabel ?? "serie";
  return {
    solvedKind: input.solvedKind,
    shouldRecordAutonomy: sprintShouldRecordAutonomy(input.correct, input.wrong),
    competencyAward: sprintCompetencyAward(
      input.difficulty,
      input.scoreTotal,
      input.maxScoreBonus,
      input.scoreDivisor,
    ),
    feedback: `${input.copy.summaryName} registrato: ${input.correct} corrette, ${input.wrong} errori, ${bestStreakLabel} ${input.bestStreak}. +${input.scoreTotal} punti. ${input.energySummary}. ${remainingText}`,
    certification: input.copy.certification,
  };
}
