import { proceduralScoring } from "../../core/ProceduralScoring";
import type { ProceduralPuzzleScore, ProceduralRunSave } from "../../procedural/ProceduralTypes";
import type {
  CodingMinigameSession,
  EnglishMinigameSession,
  LanguageMinigameSession,
  MathMinigameSession,
  MusicTrainingSession,
} from "./ProceduralMissionDefs";

type SprintScoreSession =
  | LanguageMinigameSession
  | MathMinigameSession
  | EnglishMinigameSession
  | CodingMinigameSession
  | MusicTrainingSession;

type AttemptsMode = "existing-or-one" | "wrong-count";

type SprintScoreConfig = {
  domain?: ProceduralPuzzleScore["domain"];
  baseOffset: number;
  speedCap: number;
  accuracyWeight: number;
  focusKeys: string[];
  attemptsMode: AttemptsMode;
  supportPenalty(hintsUsed: number, wrong: number, difficulty: ProceduralRunSave["difficulty"]): number;
};

function hasFocus(run: ProceduralRunSave, keys: string[]): boolean {
  return keys.some((key) => run.focus.includes(key) || run.focus.some((item) => item.startsWith(`${key}.`)));
}

function buildSprintScore(
  session: SprintScoreSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  elapsedMs: number,
  feedback: string,
  config: SprintScoreConfig,
): ProceduralPuzzleScore {
  const hintsUsed = existing?.hintsUsed ?? 0;
  const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
  const basePoints = session.correct * (config.baseOffset + run.difficulty);
  const difficultyBonus = session.correct * run.difficulty * 2;
  const speedBonus = Math.min(config.speedCap, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * config.accuracyWeight));
  const focusBonus = hasFocus(run, config.focusKeys) ? 20 + run.difficulty * 3 : 0;
  const supportPenalty = config.supportPenalty(hintsUsed, session.wrong, run.difficulty);
  const total = Math.max(0, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);
  return {
    puzzleId: session.puzzleId,
    domain: config.domain ?? proceduralScoring.puzzleDomain(session.puzzleId),
    startedAt: existing?.startedAt ?? new Date(session.startedAt).toISOString(),
    completedAt: new Date().toISOString(),
    elapsedMs,
    hintsUsed,
    attempts: config.attemptsMode === "wrong-count" ? session.wrong : Math.max(1, existing?.attempts ?? 1),
    basePoints,
    difficultyBonus,
    speedBonus,
    focusBonus,
    supportPenalty,
    total,
  feedback,
  };
}

export function buildScoreRunUpdate(run: ProceduralRunSave, score: ProceduralPuzzleScore): Pick<ProceduralRunSave, "puzzleStats" | "score"> {
  return {
    puzzleStats: {
      ...(run.puzzleStats ?? {}),
      [score.puzzleId]: score,
    },
    score: proceduralScoring.addToSummary(run.score, score),
  };
}

export function buildPuzzleTimerStartUpdate(
  run: ProceduralRunSave,
  puzzleId: string,
  startedAt = new Date().toISOString(),
): Pick<ProceduralRunSave, "puzzleStats"> {
  return {
    puzzleStats: {
      ...(run.puzzleStats ?? {}),
      [puzzleId]: {
        puzzleId,
        domain: proceduralScoring.puzzleDomain(puzzleId),
        startedAt,
        elapsedMs: 0,
        hintsUsed: 0,
        attempts: 0,
        basePoints: 0,
        difficultyBonus: 0,
        speedBonus: 0,
        focusBonus: 0,
        supportPenalty: 0,
        total: 0,
        feedback: "Timer avviato.",
      },
    },
  };
}

export function buildPuzzleStatPatchUpdate(
  run: ProceduralRunSave,
  puzzleId: string,
  patch: Partial<Pick<ProceduralPuzzleScore, "hintsUsed" | "attempts">>,
): Pick<ProceduralRunSave, "puzzleStats"> | undefined {
  const stats = run.puzzleStats?.[puzzleId];
  if (!stats) {
    return undefined;
  }
  return {
    puzzleStats: {
      ...(run.puzzleStats ?? {}),
      [puzzleId]: {
        ...stats,
        ...patch,
      },
    },
  };
}

export function buildStandardPuzzleScore(
  run: ProceduralRunSave,
  puzzleId: string,
  existing: ProceduralPuzzleScore | undefined,
  completedAt = new Date().toISOString(),
): ProceduralPuzzleScore {
  return proceduralScoring.calculate({
    puzzleId,
    difficulty: run.difficulty,
    focus: run.focus,
    startedAt: existing?.startedAt ?? new Date().toISOString(),
    completedAt,
    hintsUsed: existing?.hintsUsed ?? 0,
    attempts: (existing?.attempts ?? 0) + 1,
  });
}

export function buildLanguageMinigameScore(
  session: LanguageMinigameSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  elapsedMs: number,
  feedback: string,
): ProceduralPuzzleScore {
  return buildSprintScore(session, run, existing, elapsedMs, feedback, {
    baseOffset: 9,
    speedCap: 90,
    accuracyWeight: 34,
    focusKeys: ["italiano"],
    attemptsMode: "existing-or-one",
    supportPenalty: (hintsUsed, wrong, difficulty) => hintsUsed * 5 + wrong * (5 + difficulty),
  });
}

export function buildMathMinigameScore(
  session: MathMinigameSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  elapsedMs: number,
  feedback: string,
): ProceduralPuzzleScore {
  return buildSprintScore(session, run, existing, elapsedMs, feedback, {
    domain: "matematica",
    baseOffset: 10,
    speedCap: 110,
    accuracyWeight: 36,
    focusKeys: ["matematica"],
    attemptsMode: "wrong-count",
    supportPenalty: (hintsUsed, wrong, difficulty) => Math.min(160, wrong * (10 + difficulty) + hintsUsed * 8),
  });
}

export function buildEnglishMinigameScore(
  session: EnglishMinigameSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  elapsedMs: number,
  feedback: string,
): ProceduralPuzzleScore {
  return buildSprintScore(session, run, existing, elapsedMs, feedback, {
    baseOffset: 9,
    speedCap: 92,
    accuracyWeight: 34,
    focusKeys: ["inglese"],
    attemptsMode: "existing-or-one",
    supportPenalty: (hintsUsed, wrong, difficulty) => hintsUsed * 5 + wrong * (6 + difficulty),
  });
}

export function buildCodingMinigameScore(
  session: CodingMinigameSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  elapsedMs: number,
  feedback: string,
): ProceduralPuzzleScore {
  return buildSprintScore(session, run, existing, elapsedMs, feedback, {
    baseOffset: 10,
    speedCap: 100,
    accuracyWeight: 36,
    focusKeys: ["coding"],
    attemptsMode: "existing-or-one",
    supportPenalty: (hintsUsed, wrong, difficulty) => hintsUsed * 6 + wrong * (8 + difficulty),
  });
}

export function buildMusicSprintScore(
  session: MusicTrainingSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  elapsedMs: number,
  feedback: string,
): ProceduralPuzzleScore {
  return buildSprintScore(session, run, existing, elapsedMs, feedback, {
    domain: "musica",
    baseOffset: 10,
    speedCap: 90,
    accuracyWeight: 32,
    focusKeys: ["musica"],
    attemptsMode: "wrong-count",
    supportPenalty: (hintsUsed, wrong, difficulty) => Math.min(140, wrong * (9 + difficulty) + hintsUsed * 6),
  });
}
