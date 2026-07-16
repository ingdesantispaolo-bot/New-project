import { describe, expect, it } from "vitest";
import {
  buildProgressiveJournalEntry,
  buildProgressiveLevelCompletion,
  buildProgressiveRunCompletionUpdate,
  progressiveToolUnlockForLevel,
} from "../../scenes/procedural/ProgressiveRunRules";
import type { DifficultyLevel, ProceduralRunSave, ProgressiveLevelResult } from "../ProceduralTypes";

function runAtLevel(
  level: DifficultyLevel,
  previousResults: ProgressiveLevelResult[] = [],
  overrides: Partial<ProceduralRunSave> = {},
): ProceduralRunSave {
  const startedAt = "2026-01-01T10:00:00.000Z";
  return {
    seed: `progressive-test-${level}`,
    difficulty: level,
    focus: ["progressiva", "matematica"],
    mode: "progressive",
    mission: { objectives: [] } as unknown as ProceduralRunSave["mission"],
    hintsUsed: 0,
    solvedPuzzleIds: [],
    puzzleStats: {},
    score: { total: 42, byPuzzle: {}, byDomain: {} },
    lives: 3,
    maxLives: 3,
    timeLimitMs: 120_000,
    timerState: "ready",
    createdAt: startedAt,
    activeElapsedMs: 0,
    startedAt,
    progressive: {
      currentLevel: level,
      unlockedLevel: level,
      maxLevel: 8,
      levelStartedAt: startedAt,
      levelTimeLimitMs: 120_000,
      levelDeadlineAt: startedAt,
      results: previousResults,
    },
    ...overrides,
  };
}

describe("ProgressiveRunRules", () => {
  it("advances a completed level and replaces older results for the same level", () => {
    const olderLevelResult: ProgressiveLevelResult = {
      level: 3,
      completed: false,
      solvedCount: 1,
      requiredCount: 4,
      elapsedMs: 10_000,
      score: 5,
      outcome: "defeat",
      completedAt: "2026-01-01T10:01:00.000Z",
    };
    const run = runAtLevel(3, [olderLevelResult]);

    const completion = buildProgressiveLevelCompletion(run, true, 4, 4, "2026-01-01T10:02:00.000Z");

    expect(completion?.result.completed).toBe(true);
    expect(completion?.result.outcome).toBe("grand-victory");
    expect(completion?.results).toHaveLength(1);
    expect(completion?.unlockedLevel).toBe(4);
    expect(completion?.resumeLevel).toBe(4);
    expect(completion?.finalCompleted).toBe(false);
  });

  it("keeps the current level after a failed depth", () => {
    const run = runAtLevel(5);

    const completion = buildProgressiveLevelCompletion(run, false, 1, 5, "2026-01-01T10:03:00.000Z");

    expect(completion?.result.outcome).toBe("devastating-defeat");
    expect(completion?.unlockedLevel).toBe(5);
    expect(completion?.resumeLevel).toBe(5);
    expect(completion?.finalCompleted).toBe(false);
  });

  it("builds final run update and journal summary from all level results", () => {
    const run = runAtLevel(8);
    const results: ProgressiveLevelResult[] = [
      {
        level: 1,
        completed: true,
        solvedCount: 3,
        requiredCount: 3,
        elapsedMs: 2_000,
        score: 12,
        outcome: "light-victory",
        completedAt: "2026-01-01T10:01:00.000Z",
      },
      {
        level: 8,
        completed: true,
        solvedCount: 5,
        requiredCount: 5,
        elapsedMs: 3_000,
        score: 30,
        outcome: "grand-victory",
        completedAt: "2026-01-01T10:02:00.000Z",
      },
    ];

    const update = buildProgressiveRunCompletionUpdate(run, results, "2026-01-01T10:04:00.000Z");
    const entry = buildProgressiveJournalEntry({ ...run, ...update }, results, "2026-01-01T10:04:00.000Z", "5s");

    expect(update.completedAt).toBe("2026-01-01T10:04:00.000Z");
    expect(update.score.total).toBe(42);
    expect(entry.id).toBe("progressive-summary-progressive-test-8");
    expect(entry.lines[1]).toContain("Punteggio totale: 42");
    expect(entry.badges).toContain("Custode delle Discipline");
  });

  it("declares the expected NORA tool unlocks", () => {
    expect(progressiveToolUnlockForLevel(1)?.id).toBe("nora-lens");
    expect(progressiveToolUnlockForLevel(5)?.id).toBe("nora-shield");
    expect(progressiveToolUnlockForLevel(2)).toBeUndefined();
  });
});
