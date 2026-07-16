import type {
  DifficultyLevel,
  GeneratedMission,
  ProceduralPuzzleKind,
  ProceduralRunMode,
  ProceduralRunSave,
  ProceduralSpecialization,
  ProgressiveLevelResult,
} from "../../procedural/ProceduralTypes";

interface RunPressureParams {
  pressureEnabled: boolean;
  timeLimitMs?: number;
  maxLives: number;
}

export interface FreshProceduralRunParams extends RunPressureParams {
  mission: GeneratedMission;
  focus: string[];
  mode: ProceduralRunMode;
  createdAt: string;
}

export interface ReplacementProceduralRunParams extends FreshProceduralRunParams {
  legacyRun: ProceduralRunSave;
  progressiveLevelTimeLimitMs?: number;
}

export interface RunNormalizationParams extends RunPressureParams {
  run: ProceduralRunSave;
  mode: ProceduralRunMode;
}

export interface ProgressiveRunParams {
  level: DifficultyLevel;
  levelFocus: ProceduralSpecialization;
  mission: GeneratedMission;
  createdAt: string;
  timeLimitMs: number;
  previousResults: ProgressiveLevelResult[];
  maxLives: number;
  maxLevel?: DifficultyLevel;
}

const puzzleOrder: ProceduralPuzzleKind[] = ["language", "circuit", "math", "english", "robot", "coding", "music", "physics", "latin"];
const focusDomains: ProceduralSpecialization[] = ["matematica", "italiano", "inglese", "elettronica", "coding", "musica", "fisica", "latino"];

function puzzleKindFromId(id: string): ProceduralPuzzleKind {
  return puzzleOrder.find((candidate) => id === candidate || id.startsWith(`${candidate}-`)) ?? "language";
}

function runModeFor(run: Pick<ProceduralRunSave, "mode" | "focus">): ProceduralRunMode {
  if (run.mode) return run.mode;
  return run.focus.some((focus) => focusDomains.includes(focus as ProceduralSpecialization)) ? "training" : "mission";
}

function runFocusFor(run: Pick<ProceduralRunSave, "focus">): ProceduralSpecialization {
  return run.focus.find((focus): focus is ProceduralSpecialization => focusDomains.includes(focus as ProceduralSpecialization)) ?? "libera";
}

function emptyScore(): NonNullable<ProceduralRunSave["score"]> {
  return { total: 0, byPuzzle: {}, byDomain: {} };
}

function baseRun(params: FreshProceduralRunParams): ProceduralRunSave {
  return {
    seed: params.mission.seed,
    difficulty: params.mission.difficulty,
    focus: params.focus,
    mode: params.mode,
    mission: params.mission,
    hintsUsed: 0,
    solvedPuzzleIds: [],
    score: emptyScore(),
    puzzleStats: {},
    lives: params.pressureEnabled ? params.maxLives : undefined,
    maxLives: params.pressureEnabled ? params.maxLives : undefined,
    timeLimitMs: params.timeLimitMs,
    timerState: "preparing",
    createdAt: params.createdAt,
    activeElapsedMs: 0,
    startedAt: params.createdAt,
  };
}

export function buildFreshProceduralRun(params: FreshProceduralRunParams): ProceduralRunSave {
  return baseRun(params);
}

function hasObjective(run: ProceduralRunSave, kind: "music" | "coding" | "physics" | "latin"): boolean {
  return run.mission.objectives.some((objective) => puzzleKindFromId(objective.id.replace("procedural-", "")) === kind);
}

function hasHotspot(run: ProceduralRunSave, kind: "music" | "coding" | "physics" | "latin"): boolean {
  return run.mission.map.hotspots.some((hotspot) => {
    const id = hotspot.puzzleId ?? hotspot.id;
    return hotspot.puzzleKind === kind || id === kind || id.startsWith(`${kind}-`);
  });
}

function hasFocusSeries(run: ProceduralRunSave, kind: "music" | "coding" | "physics" | "latin"): boolean {
  return Boolean(
    run.mission.focusChallenges?.length
    && run.mission.focusChallenges.every((challenge) => challenge.kind === kind),
  );
}

export function runNeedsContentMigration(run: ProceduralRunSave): boolean {
  const mode = runModeFor(run);
  const focus = runFocusFor(run);
  const puzzles = run.mission.puzzles as Partial<ProceduralRunSave["mission"]["puzzles"]>;
  const hasMusicPuzzle = Boolean(puzzles.music);
  const hasModernMusicPuzzle = Boolean(puzzles.music?.answerMode);
  const hasMusicObjective = hasObjective(run, "music");
  const hasMusicHotspot = hasHotspot(run, "music");
  const hasMusicFocusSeries = hasFocusSeries(run, "music");
  const hasCodingPuzzle = Boolean(puzzles.coding);
  const hasCodingObjective = hasObjective(run, "coding");
  const hasCodingHotspot = hasHotspot(run, "coding");
  const hasCodingFocusSeries = hasFocusSeries(run, "coding");
  const hasPhysicsPuzzle = Boolean(puzzles.physics);
  const hasPhysicsObjective = hasObjective(run, "physics");
  const hasPhysicsHotspot = hasHotspot(run, "physics");
  const hasPhysicsFocusSeries = hasFocusSeries(run, "physics");
  const hasLatinPuzzle = Boolean(puzzles.latin);
  const hasLatinObjective = hasObjective(run, "latin");
  const hasLatinHotspot = hasHotspot(run, "latin");
  const hasLatinFocusSeries = hasFocusSeries(run, "latin");
  if (focus === "musica") {
    return !(hasMusicPuzzle && hasModernMusicPuzzle && hasMusicObjective && hasMusicHotspot && hasMusicFocusSeries);
  }
  if (focus === "coding") {
    return !(hasCodingPuzzle && hasCodingObjective && hasCodingHotspot && hasCodingFocusSeries);
  }
  if (focus === "fisica") {
    return !(hasPhysicsPuzzle && hasPhysicsObjective && hasPhysicsHotspot && hasPhysicsFocusSeries);
  }
  if (focus === "latino") {
    return !(hasLatinPuzzle && hasLatinObjective && hasLatinHotspot && hasLatinFocusSeries);
  }
  if (mode === "mission" || focus === "libera") {
    return !(
      hasMusicPuzzle && hasModernMusicPuzzle && hasMusicObjective && hasMusicHotspot
      && hasCodingPuzzle && hasCodingObjective && hasCodingHotspot
      && hasPhysicsPuzzle && hasPhysicsObjective && hasPhysicsHotspot
      && hasLatinPuzzle && hasLatinObjective && hasLatinHotspot
    );
  }
  return false;
}

export function buildReplacementProceduralRun(params: ReplacementProceduralRunParams): ProceduralRunSave {
  const replacement = baseRun(params);
  return {
    ...replacement,
    chapterMissionId: params.legacyRun.chapterMissionId,
    chapterExploreMissionId: params.legacyRun.chapterExploreMissionId,
    progressive: params.mode === "progressive"
      ? {
          currentLevel: params.legacyRun.progressive?.currentLevel ?? params.legacyRun.difficulty,
          unlockedLevel: params.legacyRun.progressive?.unlockedLevel ?? params.legacyRun.difficulty,
          maxLevel: params.legacyRun.progressive?.maxLevel ?? 8,
          levelStartedAt: params.createdAt,
          levelTimeLimitMs: params.progressiveLevelTimeLimitMs ?? params.timeLimitMs ?? 0,
          levelDeadlineAt: params.createdAt,
          results: params.legacyRun.progressive?.results ?? [],
        }
      : undefined,
  };
}

export function buildRunNormalizationUpdate(params: RunNormalizationParams): Partial<ProceduralRunSave> | undefined {
  const update: Partial<ProceduralRunSave> = {};
  if (params.mode === "progressive" && params.run.progressive) {
    const currentLevel = params.run.progressive.currentLevel;
    if (params.run.difficulty !== currentLevel) update.difficulty = currentLevel;
    if (params.run.progressive.levelTimeLimitMs !== params.timeLimitMs) {
      update.progressive = { ...params.run.progressive, levelTimeLimitMs: params.timeLimitMs! };
    }
  }
  if (params.run.mode !== params.mode) update.mode = params.mode;
  if (params.pressureEnabled) {
    if (params.run.maxLives === undefined) update.maxLives = params.maxLives;
    if (params.run.lives === undefined) update.lives = params.maxLives;
    if (!params.run.timeLimitMs) update.timeLimitMs = params.timeLimitMs;
  } else {
    update.lives = undefined;
    update.maxLives = undefined;
    update.timeLimitMs = undefined;
    update.deadlineAt = undefined;
    update.pausedRemainingMs = undefined;
  }
  if (!params.run.timerState || params.run.timerState === "paused") update.timerState = "ready";
  return Object.keys(update).length > 0 ? update : undefined;
}

export function buildProgressiveProceduralRun(params: ProgressiveRunParams): ProceduralRunSave {
  const highestUnlocked = params.previousResults.reduce<number>((max, result) => (
    result.completed ? Math.max(max, Math.min(8, result.level + 1)) : max
  ), params.level);
  return {
    seed: params.mission.seed,
    difficulty: params.level,
    focus: ["progressiva", params.levelFocus],
    mode: "progressive",
    mission: params.mission,
    hintsUsed: 0,
    solvedPuzzleIds: [],
    score: emptyScore(),
    puzzleStats: {},
    lives: params.maxLives,
    maxLives: params.maxLives,
    timeLimitMs: params.timeLimitMs,
    timerState: "preparing",
    createdAt: params.createdAt,
    activeElapsedMs: 0,
    startedAt: params.createdAt,
    progressive: {
      currentLevel: params.level,
      unlockedLevel: Math.min(8, Math.max(params.level, highestUnlocked)) as DifficultyLevel,
      maxLevel: params.maxLevel ?? 8,
      levelStartedAt: params.createdAt,
      levelTimeLimitMs: params.timeLimitMs,
      levelDeadlineAt: params.createdAt,
      results: params.previousResults,
    },
  };
}
