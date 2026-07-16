import type { ProceduralRunSave } from "../../procedural/ProceduralTypes";

export const CHAPTER_TRIAL_TIME_PENALTY_MS = 25_000;

export type LifeLossOutcome =
  | {
    kind: "progressive-failed";
    nextLives: 0;
    update: Partial<ProceduralRunSave>;
  }
  | {
    kind: "mission-failed";
    nextLives: 0;
  }
  | {
    kind: "life-lost";
    nextLives: number;
    update: Partial<ProceduralRunSave>;
    outcomeLabel: string;
    noraCue: "sabotage" | "lowLife" | "lifeLost";
    feedback: string;
    restartDelayMs: number;
  };

export interface LifeLossDecisionInput {
  run: ProceduralRunSave;
  reason: string;
  isProgressive: boolean;
  isChapterTrial: boolean;
  maxLivesFallback: number;
  timePenaltyMs?: number;
}

export function buildLifeLossOutcome(input: LifeLossDecisionInput): LifeLossOutcome {
  const maxLives = input.run.maxLives ?? input.maxLivesFallback;
  const lives = input.run.lives ?? maxLives;
  const nextLives = Math.max(0, lives - 1);
  if (nextLives <= 0) {
    return input.isProgressive
      ? { kind: "progressive-failed", nextLives: 0, update: { lives: 0 } }
      : { kind: "mission-failed", nextLives: 0 };
  }

  const timePenaltyMs = input.timePenaltyMs ?? CHAPTER_TRIAL_TIME_PENALTY_MS;
  const update: Partial<ProceduralRunSave> = { lives: nextLives };
  if (input.isChapterTrial && input.run.deadlineAt) {
    update.deadlineAt = new Date(new Date(input.run.deadlineAt).getTime() - timePenaltyMs).toISOString();
  }

  return {
    kind: "life-lost",
    nextLives,
    update,
    outcomeLabel: input.isChapterTrial ? "Il sabotatore avanza" : "Vita persa",
    noraCue: input.isChapterTrial ? "sabotage" : nextLives <= 1 ? "lowLife" : "lifeLost",
    feedback: input.isProgressive
      ? `Tentativo fallito: ${input.reason} Restano ${nextLives}/${maxLives}. La scalata riapre automaticamente la prossima console non stabile.`
      : input.isChapterTrial
        ? `Il sabotatore guadagna terreno (-${timePenaltyMs / 1000}s): ${input.reason} Ti restano ${nextLives} margini prima che vinca il round: una risposta pulita lo rallenta.`
        : `Vita persa: ${input.reason} Restano ${nextLives}/${maxLives}. I sistemi già stabilizzati restano validi; scegli con attenzione la prossima console.`,
    restartDelayMs: 2400,
  };
}

export function buildMissionFailureUpdate(failedAt: string): Partial<ProceduralRunSave> {
  return {
    lives: 0,
    failedAt,
    pausedRemainingMs: undefined,
  };
}

export function missionFailureFeedback(reason: string): string {
  return `Missione fallita: ${reason} Non ci sono piu condizioni utili per proseguire: ricomincia dal menu con una nuova missione.`;
}
