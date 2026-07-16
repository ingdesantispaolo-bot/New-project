import type {
  DifficultyLevel,
  ProceduralRunSave,
  ProgressiveLevelResult,
  ProgressiveOutcomeTone,
} from "../../procedural/ProceduralTypes";
import type { JournalEntry } from "../../types/gameTypes";

export interface ProgressiveToolUnlock {
  id: string;
  label: string;
}

export interface ProgressiveLevelCompletion {
  result: ProgressiveLevelResult;
  results: ProgressiveLevelResult[];
  unlockedLevel: DifficultyLevel;
  finalCompleted: boolean;
  resumeLevel?: DifficultyLevel;
}

export function progressiveToolUnlockForLevel(level: DifficultyLevel): ProgressiveToolUnlock | undefined {
  const unlocks: Partial<Record<DifficultyLevel, ProgressiveToolUnlock>> = {
    1: { id: "nora-lens", label: "Lente causale: il primo indizio di ogni run è gratuito" },
    3: { id: "nora-reserve", label: "Riserva rapida: gli impulsi NORA si caricano più velocemente" },
    5: { id: "nora-shield", label: "Scudo rinforzato: una carica può recuperare due vite" },
    8: { id: "nora-prismatic-core", label: "Nucleo prismatico: certificazione permanente della scalata" },
  };
  return unlocks[level];
}

function progressiveRemainingMs(run: ProceduralRunSave): number {
  if (run.timerState === "preparing" || run.timerState === "ready") {
    return run.timeLimitMs ?? Number.POSITIVE_INFINITY;
  }
  if (run.timerState === "paused" && run.pausedRemainingMs !== undefined) {
    return run.pausedRemainingMs;
  }
  if (!run.deadlineAt) {
    return Number.POSITIVE_INFINITY;
  }
  return new Date(run.deadlineAt).getTime() - Date.now();
}

export function assessProgressiveOutcome(
  run: ProceduralRunSave,
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
  const remainingRatio = run.timeLimitMs
    ? Math.max(0, progressiveRemainingMs(run)) / run.timeLimitMs
    : 0;
  const attempts = Object.values(run.puzzleStats ?? {}).reduce((sum, score) => sum + score.attempts, 0);
  const cleanRun = run.hintsUsed === 0 && attempts <= requiredCount + 1;
  return remainingRatio >= 0.32 && cleanRun ? "grand-victory" : "light-victory";
}

export function buildProgressiveLevelCompletion(
  run: ProceduralRunSave,
  success: boolean,
  solvedCount: number,
  requiredCount: number,
  completedAt: string,
): ProgressiveLevelCompletion | undefined {
  const progressive = run.progressive;
  if (!progressive) {
    return undefined;
  }
  const elapsedMs = Math.max(1000, new Date(completedAt).getTime() - new Date(progressive.levelStartedAt).getTime());
  const result: ProgressiveLevelResult = {
    level: progressive.currentLevel,
    completed: success,
    solvedCount,
    requiredCount,
    elapsedMs,
    score: run.score?.total ?? 0,
    outcome: assessProgressiveOutcome(run, success, solvedCount, requiredCount),
    completedAt,
  };
  const results = [...progressive.results.filter((item) => item.level !== result.level), result]
    .sort((a, b) => a.level - b.level);
  const unlockedLevel = success
    ? Math.min(progressive.maxLevel, Math.max(progressive.unlockedLevel, result.level + 1)) as DifficultyLevel
    : progressive.unlockedLevel;
  const finalCompleted = success && result.level >= progressive.maxLevel;
  const resumeLevel = finalCompleted
    ? undefined
    : success
      ? Math.min(progressive.maxLevel, result.level + 1) as DifficultyLevel
      : result.level;
  return {
    result,
    results,
    unlockedLevel,
    finalCompleted,
    resumeLevel,
  };
}

export function progressiveTotalScore(results: ProgressiveLevelResult[]): number {
  return results.reduce((sum, result) => sum + result.score, 0);
}

export function progressiveTotalElapsedMs(results: ProgressiveLevelResult[]): number {
  return results.reduce((sum, result) => sum + result.elapsedMs, 0);
}

export function buildProgressiveRunCompletionUpdate(
  run: ProceduralRunSave,
  results: ProgressiveLevelResult[],
  completedAt: string,
): { completedAt: string; score: NonNullable<ProceduralRunSave["score"]> } {
  return {
    completedAt,
    score: {
      ...(run.score ?? { byPuzzle: {}, byDomain: {} }),
      total: progressiveTotalScore(results),
    },
  };
}

export function buildProgressiveJournalEntry(
  run: ProceduralRunSave,
  results: ProgressiveLevelResult[],
  completedAt: string,
  totalElapsedLabel: string,
): JournalEntry {
  const totalScore = progressiveTotalScore(results);
  return {
    id: `progressive-summary-${run.seed}`,
    title: "Scalata progressiva completata",
    lines: [
      "Eli ha attraversato le otto stanze riconfigurabili: ogni settore ha intrecciato sistemi diversi con profondità crescente.",
      `Punteggio totale: ${totalScore}. Tempo complessivo sulle profondità: ${totalElapsedLabel}.`,
      `Profondità superate: ${results.filter((result) => result.completed).length}/8. Indizi usati nell'ultimo settore: ${run.hintsUsed}.`,
      "La porta del nucleo resta aperta: ora puoi ripetere la scalata per migliorare tempo, precisione e qualità delle decisioni.",
    ],
    badges: ["Scalatrice dell'Accademia", "Custode delle Discipline", "Stratega del Tempo"],
    createdAt: completedAt,
  };
}
