import { describe, expect, it } from "vitest";
import {
  buildLifeLossOutcome,
  buildMissionFailureUpdate,
  CHAPTER_TRIAL_TIME_PENALTY_MS,
  missionFailureFeedback,
} from "../../scenes/procedural/MissionFailureRules";
import type { ProceduralRunSave } from "../ProceduralTypes";

function run(overrides: Partial<ProceduralRunSave> = {}): ProceduralRunSave {
  return {
    seed: "failure-test",
    difficulty: 4,
    focus: ["matematica"],
    mode: "mission",
    mission: { objectives: [] } as unknown as ProceduralRunSave["mission"],
    hintsUsed: 0,
    solvedPuzzleIds: [],
    puzzleStats: {},
    score: { total: 0, byPuzzle: {}, byDomain: {} },
    lives: 3,
    maxLives: 3,
    timerState: "running",
    startedAt: "2026-01-01T10:00:00.000Z",
    createdAt: "2026-01-01T10:00:00.000Z",
    ...overrides,
  };
}

describe("MissionFailureRules", () => {
  it("builds a normal life-loss update and feedback", () => {
    const outcome = buildLifeLossOutcome({
      run: run({ lives: 2 }),
      reason: "risposta errata",
      isProgressive: false,
      isChapterTrial: false,
      maxLivesFallback: 3,
    });

    expect(outcome.kind).toBe("life-lost");
    if (outcome.kind !== "life-lost") throw new Error("Expected life-lost outcome");
    expect(outcome.nextLives).toBe(1);
    expect(outcome.update).toEqual({ lives: 1 });
    expect(outcome.noraCue).toBe("lowLife");
    expect(outcome.feedback).toContain("Vita persa: risposta errata");
  });

  it("applies the chapter-trial time penalty when a life remains", () => {
    const deadlineAt = "2026-01-01T10:10:00.000Z";
    const outcome = buildLifeLossOutcome({
      run: run({ lives: 3, deadlineAt }),
      reason: "soglia superata",
      isProgressive: false,
      isChapterTrial: true,
      maxLivesFallback: 3,
    });

    expect(outcome.kind).toBe("life-lost");
    if (outcome.kind !== "life-lost") throw new Error("Expected life-lost outcome");
    expect(outcome.update.deadlineAt).toBe(new Date(new Date(deadlineAt).getTime() - CHAPTER_TRIAL_TIME_PENALTY_MS).toISOString());
    expect(outcome.outcomeLabel).toBe("Il sabotatore avanza");
    expect(outcome.noraCue).toBe("sabotage");
  });

  it("routes zero lives to the correct final failure path", () => {
    const missionOutcome = buildLifeLossOutcome({
      run: run({ lives: 1 }),
      reason: "ultima vita",
      isProgressive: false,
      isChapterTrial: false,
      maxLivesFallback: 3,
    });
    const progressiveOutcome = buildLifeLossOutcome({
      run: run({ lives: 1, mode: "progressive" }),
      reason: "ultima vita",
      isProgressive: true,
      isChapterTrial: false,
      maxLivesFallback: 3,
    });

    expect(missionOutcome.kind).toBe("mission-failed");
    expect(progressiveOutcome).toEqual({
      kind: "progressive-failed",
      nextLives: 0,
      update: { lives: 0 },
    });
  });

  it("builds the mission failure update and message", () => {
    expect(buildMissionFailureUpdate("2026-01-01T10:00:00.000Z")).toEqual({
      lives: 0,
      failedAt: "2026-01-01T10:00:00.000Z",
      pausedRemainingMs: undefined,
    });
    expect(missionFailureFeedback("tempo esaurito")).toContain("Missione fallita: tempo esaurito");
  });
});
