import { describe, expect, it } from "vitest";
import {
  buildCleanSolveReward,
  CLEAN_SOLVE_TIME_BONUS_MS,
  cleanSolveCount,
  isCleanPuzzleSolve,
  puzzleKindLabel,
  puzzleSolveFeedback,
  puzzleCompetencyAward,
  remainingPuzzleLine,
  solvedPrincipleForKind,
} from "../../scenes/procedural/PuzzleSolveRules";
import type { ProceduralPuzzleScore, ProceduralRunSave } from "../ProceduralTypes";

function score(overrides: Partial<ProceduralPuzzleScore> = {}): ProceduralPuzzleScore {
  return {
    puzzleId: "math",
    domain: "matematica",
    startedAt: "2026-01-01T10:00:00.000Z",
    elapsedMs: 1_000,
    hintsUsed: 0,
    attempts: 1,
    basePoints: 0,
    difficultyBonus: 0,
    speedBonus: 0,
    focusBonus: 0,
    supportPenalty: 0,
    total: 0,
    feedback: "",
    ...overrides,
  };
}

function run(overrides: Partial<ProceduralRunSave> = {}): ProceduralRunSave {
  return {
    seed: "clean-solve-test",
    difficulty: 4,
    focus: ["matematica"],
    mode: "mission",
    mission: { objectives: [] } as unknown as ProceduralRunSave["mission"],
    hintsUsed: 0,
    solvedPuzzleIds: [],
    puzzleStats: {},
    score: { total: 0, byPuzzle: {}, byDomain: {} },
    lives: 2,
    maxLives: 3,
    timerState: "running",
    startedAt: "2026-01-01T10:00:00.000Z",
    ...overrides,
  };
}

describe("PuzzleSolveRules", () => {
  it("detects clean solves and computes competency award", () => {
    expect(isCleanPuzzleSolve(score())).toBe(true);
    expect(isCleanPuzzleSolve(score({ attempts: 2 }))).toBe(false);
    expect(isCleanPuzzleSolve(score({ hintsUsed: 1 }))).toBe(false);
    expect(puzzleCompetencyAward(4, 0)).toBe(18);
    expect(puzzleCompetencyAward(4, 10)).toBe(22);
  });

  it("builds puzzle labels, principles and solve feedback", () => {
    expect(puzzleKindLabel("math-quadratic-1")).toBe("matematica");
    expect(puzzleKindLabel("latin-case")).toBe("latino");
    expect(solvedPrincipleForKind("circuit")).toContain("percorso chiuso");
    expect(remainingPuzzleLine(["inglese", "coding"])).toBe("Restano: inglese, coding.");
    expect(remainingPuzzleLine([])).toBe("Percorso disciplinare completo: la porta finale è pronta.");
    expect(puzzleSolveFeedback("Nodo riparato.", "principio", 42, "12s", ["italiano"])).toBe(
      "Nodo riparato. Hai consolidato: principio +42 punti (12s). Restano: italiano.",
    );
  });

  it("counts clean puzzle stats only", () => {
    expect(cleanSolveCount(run({
      puzzleStats: {
        math: score(),
        coding: score({ puzzleId: "coding", attempts: 2 }),
        english: score({ puzzleId: "english", hintsUsed: 1 }),
      },
    }))).toBe(1);
  });

  it("adds time bonus from the later between now and deadline", () => {
    const deadlineAt = "2026-01-01T10:00:10.000Z";
    const reward = buildCleanSolveReward(run({ deadlineAt }), 3, new Date("2026-01-01T10:00:20.000Z").getTime());

    expect(reward.update.deadlineAt).toBe(new Date(new Date("2026-01-01T10:00:20.000Z").getTime() + CLEAN_SOLVE_TIME_BONUS_MS).toISOString());
    expect(reward.grantsLife).toBe(false);
  });

  it("grants one life on the third clean solve when not already full", () => {
    const reward = buildCleanSolveReward(run({
      puzzleStats: {
        math: score(),
        english: score({ puzzleId: "english" }),
        coding: score({ puzzleId: "coding" }),
      },
      lives: 2,
      maxLives: 3,
    }), 3, new Date("2026-01-01T10:00:00.000Z").getTime());

    expect(reward.cleanCount).toBe(3);
    expect(reward.grantsLife).toBe(true);
    expect(reward.update.lives).toBe(3);
    expect(reward.message).toContain("Tre diagnosi");
  });
});
