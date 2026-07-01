import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { DifficultyLevel, ProceduralRunSave } from "../procedural/ProceduralTypes";
import { proceduralRunRules } from "./ProceduralRunRules";

/**
 * "Prova del Capitolo" (Chapter Trial) — the graded gate of the Story.
 *
 * Each chapter challenges the student across ALL subjects/games at a fixed
 * difficulty level. To clear the chapter (and unlock the next) the student must
 * finish the trial with at most {@link CHAPTER_TRIAL_ERROR_BUDGET} total errors
 * and within the chapter's time budget. The trial reuses the existing "mission"
 * run machinery (mixed-subject "libera" mission, lives + timer) — see
 * {@link ProceduralMissionScene} for how a run with `chapterMissionId` is graded.
 */

/** Total mistakes allowed across the whole chapter before the trial fails. */
export const CHAPTER_TRIAL_ERROR_BUDGET = 3;

type TrialConfig = {
  /** Fixed difficulty (1-8) the whole trial runs at. */
  level: DifficultyLevel;
  /** Global time budget for the whole chapter, in minutes. */
  minutes: number;
};

/**
 * Calibration — gentle +1 ramp from L2 to L7 (confirmed design). L1 is left for
 * onboarding/practice, L8 for the endless Tower. Time budgets are generous but
 * apply pressure: harder chapters give more consoles yet slightly less air.
 */
const TRIALS: Record<string, TrialConfig> = {
  "mission-01-laboratorio-spento": { level: 2, minutes: 10 },
  "mission-02-serra-biologica": { level: 3, minutes: 10 },
  "mission-03-fabbrica-numeri": { level: 4, minutes: 12 },
  "mission-04-archivio-parole": { level: 5, minutes: 12 },
  "mission-05-atlante-perduto": { level: 6, minutes: 12 },
  "mission-06-citta-intelligente": { level: 7, minutes: 11 },
};

const DEFAULT_TRIAL: TrialConfig = { level: 2, minutes: 10 };

export function chapterTrialConfig(missionId: string): TrialConfig {
  return TRIALS[missionId] ?? DEFAULT_TRIAL;
}

export function chapterTrialLevel(missionId: string): DifficultyLevel {
  return chapterTrialConfig(missionId).level;
}

export function chapterTrialTimeMs(missionId: string): number {
  return chapterTrialConfig(missionId).minutes * 60_000;
}

export function chapterExploreLevel(missionId: string): DifficultyLevel {
  const level = chapterTrialLevel(missionId);
  return Math.max(1, level - 1) as DifficultyLevel;
}

/**
 * Builds the low-pressure "Fase Esplora" for a chapter. It prepares the same
 * mixed-subject territory as the trial, but removes lives and timer so the
 * student can understand the method before being evaluated.
 */
export function buildChapterExploreRun(missionId: string, attempt = 0): ProceduralRunSave {
  const level = chapterExploreLevel(missionId);
  const seed = `EXPLORE-${missionId}-${attempt}-${Date.now()}`;
  const mission = proceduralDirector.generateMission(seed, level, ["libera"]);
  const createdAt = new Date().toISOString();
  return {
    seed: mission.seed,
    difficulty: level,
    focus: ["libera"],
    mode: "mission",
    mission,
    hintsUsed: 0,
    solvedPuzzleIds: [],
    score: { total: 0, byPuzzle: {}, byDomain: {} },
    puzzleStats: {},
    timerState: "preparing",
    createdAt,
    activeElapsedMs: 0,
    startedAt: createdAt,
    chapterExploreMissionId: missionId,
  };
}

/**
 * Builds a fresh graded trial run for a chapter. Each `attempt` uses a new seed
 * so a retry after failure serves different-but-equivalent challenges (the trial
 * always restarts from scratch on failure — confirmed design).
 */
export function buildChapterTrialRun(missionId: string, attempt = 0): ProceduralRunSave {
  const config = chapterTrialConfig(missionId);
  const seed = `TRIAL-${missionId}-${attempt}-${Date.now()}`;
  const mission = proceduralDirector.generateMission(seed, config.level, ["libera"]);
  const createdAt = new Date().toISOString();
  return {
    seed: mission.seed,
    difficulty: config.level,
    focus: ["libera"],
    mode: "mission",
    mission,
    hintsUsed: 0,
    solvedPuzzleIds: [],
    score: { total: 0, byPuzzle: {}, byDomain: {} },
    puzzleStats: {},
    lives: proceduralRunRules.maxLives,
    maxLives: proceduralRunRules.maxLives,
    timeLimitMs: config.minutes * 60_000,
    timerState: "preparing",
    createdAt,
    activeElapsedMs: 0,
    startedAt: createdAt,
    chapterMissionId: missionId,
  };
}
