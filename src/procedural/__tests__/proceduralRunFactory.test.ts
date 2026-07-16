import { describe, expect, it } from "vitest";
import {
  buildFreshProceduralRun,
  buildProgressiveProceduralRun,
  buildRunNormalizationUpdate,
  runNeedsContentMigration,
} from "../../scenes/procedural/ProceduralRunFactory";
import type {
  DifficultyLevel,
  GeneratedFocusChallenge,
  GeneratedMission,
  ProceduralPuzzleKind,
  ProceduralRunSave,
  ProgressiveLevelResult,
} from "../ProceduralTypes";

const createdAt = "2026-01-01T10:00:00.000Z";

function missionWithKinds(
  kinds: ProceduralPuzzleKind[],
  options: { modernMusic?: boolean; focusKind?: ProceduralPuzzleKind } = {},
): GeneratedMission {
  const puzzles: Record<string, unknown> = {};
  for (const kind of kinds) {
    puzzles[kind] = kind === "music" && options.modernMusic === false
      ? {}
      : kind === "music"
        ? { answerMode: "note" }
        : {};
  }
  return {
    id: "mission-test",
    seed: "mission-test-seed",
    difficulty: 4,
    title: "Missione test",
    intro: "Intro",
    objectives: kinds.map((kind) => ({
      id: `procedural-${kind}`,
      label: kind,
      description: kind,
      puzzleId: kind,
      required: true,
      competencies: [],
    })),
    map: {
      id: "room-test",
      title: "Room",
      roomCount: 1,
      hotspots: kinds.map((kind) => ({
        id: kind,
        label: kind,
        x: 100,
        y: 100,
        radius: 40,
        puzzleId: kind,
        puzzleKind: kind,
        description: kind,
      })),
    },
    puzzles: puzzles as GeneratedMission["puzzles"],
    focusChallenges: options.focusKind
      ? [{
          id: "focus-test",
          kind: options.focusKind,
          title: "Focus",
          description: "Focus",
          difficultyStep: 1,
          puzzle: {},
        } as GeneratedFocusChallenge]
      : undefined,
    rewards: [],
    competencies: [],
  };
}

function run(overrides: Partial<ProceduralRunSave> = {}): ProceduralRunSave {
  const mission = missionWithKinds(["music", "coding", "physics", "latin"]);
  return {
    seed: mission.seed,
    difficulty: mission.difficulty,
    focus: ["libera"],
    mode: "mission",
    mission,
    hintsUsed: 0,
    solvedPuzzleIds: [],
    score: { total: 0, byPuzzle: {}, byDomain: {} },
    puzzleStats: {},
    timerState: "ready",
    createdAt,
    activeElapsedMs: 0,
    startedAt: createdAt,
    ...overrides,
  };
}

describe("ProceduralRunFactory", () => {
  it("keeps modern multidisciplinary mission runs", () => {
    expect(runNeedsContentMigration(run())).toBe(false);
  });

  it("migrates old mission content missing modern music data", () => {
    const mission = missionWithKinds(["music", "coding", "physics", "latin"], { modernMusic: false });

    expect(runNeedsContentMigration(run({ mission }))).toBe(true);
  });

  it("requires focus challenge series for focused training content", () => {
    const withoutFocusSeries = run({
      focus: ["musica"],
      mode: "training",
      mission: missionWithKinds(["music"]),
    });
    const withFocusSeries = run({
      focus: ["musica"],
      mode: "training",
      mission: missionWithKinds(["music"], { focusKind: "music" }),
    });

    expect(runNeedsContentMigration(withoutFocusSeries)).toBe(true);
    expect(runNeedsContentMigration(withFocusSeries)).toBe(false);
  });

  it("builds fresh runs with or without pressure fields", () => {
    const mission = missionWithKinds(["music", "coding", "physics", "latin"]);
    const relaxed = buildFreshProceduralRun({
      mission,
      focus: ["libera"],
      mode: "mission",
      pressureEnabled: false,
      maxLives: 3,
      createdAt,
    });
    const pressured = buildFreshProceduralRun({
      mission,
      focus: ["libera"],
      mode: "mission",
      pressureEnabled: true,
      timeLimitMs: 180_000,
      maxLives: 3,
      createdAt,
    });

    expect(relaxed.lives).toBeUndefined();
    expect(relaxed.timeLimitMs).toBeUndefined();
    expect(pressured.lives).toBe(3);
    expect(pressured.maxLives).toBe(3);
    expect(pressured.timeLimitMs).toBe(180_000);
  });

  it("normalizes timer, pressure and progressive level fields", () => {
    const progressive = run({
      difficulty: 4,
      mode: "progressive",
      timerState: "paused",
      progressive: {
        currentLevel: 5,
        unlockedLevel: 5,
        maxLevel: 8,
        levelStartedAt: createdAt,
        levelTimeLimitMs: 100_000,
        levelDeadlineAt: createdAt,
        results: [],
      },
    });

    expect(buildRunNormalizationUpdate({
      run: progressive,
      mode: "progressive",
      pressureEnabled: true,
      timeLimitMs: 160_000,
      maxLives: 3,
    })).toMatchObject({
      difficulty: 5,
      lives: 3,
      maxLives: 3,
      timerState: "ready",
      progressive: { levelTimeLimitMs: 160_000 },
    });

    expect(buildRunNormalizationUpdate({
      run: run({ lives: 2, maxLives: 3, timeLimitMs: 100_000, deadlineAt: createdAt }),
      mode: "training",
      pressureEnabled: false,
      maxLives: 3,
    })).toMatchObject({
      lives: undefined,
      maxLives: undefined,
      timeLimitMs: undefined,
      deadlineAt: undefined,
    });
  });

  it("builds progressive runs and unlocks the next completed depth", () => {
    const previousResults: ProgressiveLevelResult[] = [{
      level: 3,
      completed: true,
      solvedCount: 4,
      requiredCount: 4,
      elapsedMs: 90_000,
      score: 120,
      outcome: "light-victory",
      completedAt: createdAt,
    }];

    const built = buildProgressiveProceduralRun({
      level: 3 as DifficultyLevel,
      levelFocus: "matematica",
      mission: missionWithKinds(["music", "coding", "physics", "latin"]),
      createdAt,
      timeLimitMs: 240_000,
      previousResults,
      maxLives: 3,
    });

    expect(built.mode).toBe("progressive");
    expect(built.focus).toEqual(["progressiva", "matematica"]);
    expect(built.progressive?.unlockedLevel).toBe(4);
    expect(built.progressive?.results).toBe(previousResults);
  });
});
