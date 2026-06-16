import type { ProceduralPuzzleScore, ProceduralRunSave, ProceduralSpecialization } from "../procedural/ProceduralTypes";
import { formatDuration, proceduralScoring } from "./ProceduralScoring";
import { proceduralRunRules } from "./ProceduralRunRules";

const PLAYER_STORE_KEY = "eli-quest-players-v1";

export type ResultCategory = "exercise" | "mission" | "focus";

export type PlayerProfile = {
  id: string;
  name: string;
  createdAt: string;
  lastActiveAt: string;
};

export type PlayerResult = {
  id: string;
  sourceKey: string;
  playerId: string;
  playerName: string;
  category: ResultCategory;
  key: string;
  label: string;
  difficulty: number;
  score: number;
  elapsedMs: number;
  hintsUsed: number;
  attempts: number;
  completedAt: string;
  mode: "mission" | "training";
  seed: string;
  grade?: number;
  gradeLabel?: string;
};

type PlayerStore = {
  version: number;
  activePlayerId: string;
  players: PlayerProfile[];
  results: PlayerResult[];
};

export type PlayerReport = {
  player: PlayerProfile;
  resultCount: number;
  missionCount: number;
  focusCount: number;
  exerciseCount: number;
  totalScore: number;
  averageScore: number;
  bestMission?: PlayerResult;
  bestFocus?: PlayerResult;
  bestExercise?: PlayerResult;
  recent: PlayerResult[];
  strengths: Array<{ label: string; score: number }>;
  globalGrade: number;
  globalGradeLabel: string;
  missionGrade: number;
  trainingGrade: number;
  exerciseGrade: number;
  nextGoal: string;
  trainingStats: TrainingProgressStat[];
  subjectStats: SubjectProgressStat[];
};

export type TrainingProgressStat = {
  focus: ProceduralSpecialization;
  label: string;
  runs: number;
  bestGrade: number;
  averageGrade: number;
  lastGrade: number;
  bestTimeMs: number;
  averageTimeMs: number;
  bestScore: number;
  trend: "up" | "steady" | "down";
  nextGoal: string;
};

export type SubjectProgressStat = {
  key: string;
  label: string;
  exercises: number;
  bestGrade: number;
  averageGrade: number;
  lastGrade: number;
  bestTimeMs: number;
  averageScore: number;
  nextGoal: string;
};

const puzzleLabels: Record<string, string> = {
  language: "Italiano - riparazione messaggi",
  circuit: "Elettronica - diagnosi circuito",
  math: "Matematica - terminale numerico",
  english: "Inglese - comando operativo",
  robot: "Coding - robot su griglia",
  music: "Musica - lettura pentagramma",
};

const focusLabels: Record<string, string> = {
  libera: "Missione libera",
  matematica: "Focus matematica",
  italiano: "Focus italiano",
  inglese: "Focus inglese",
  elettronica: "Focus elettronica",
  coding: "Focus coding",
  musica: "Focus musica",
};

function nowIso(): string {
  return new Date().toISOString();
}

function createId(prefix: string): string {
  const entropy = new Uint32Array(1);
  if (globalThis.crypto?.getRandomValues) {
    globalThis.crypto.getRandomValues(entropy);
  } else {
    entropy[0] = Math.floor(Date.now() + Math.random() * 10000);
  }
  return `${prefix}-${Date.now().toString(36)}-${entropy[0].toString(36)}`;
}

function defaultStore(): PlayerStore {
  const createdAt = nowIso();
  const player: PlayerProfile = {
    id: createId("player"),
    name: "Giocatrice 1",
    createdAt,
    lastActiveAt: createdAt,
  };
  return {
    version: 1,
    activePlayerId: player.id,
    players: [player],
    results: [],
  };
}

function basePuzzleKey(puzzleId: string): string {
  return Object.keys(puzzleLabels).find((candidate) => puzzleId === candidate || puzzleId.startsWith(`${candidate}-`)) ?? puzzleId;
}

function sortedResults(results: PlayerResult[]): PlayerResult[] {
  return [...results].sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    if (b.difficulty !== a.difficulty) return b.difficulty - a.difficulty;
    if (a.elapsedMs !== b.elapsedMs) return a.elapsedMs - b.elapsedMs;
    return new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime();
  });
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function roundGrade(value: number): number {
  return Math.round(clamp(value, 0, 10) * 10) / 10;
}

function gradeLabel(grade: number): string {
  if (grade >= 9.4) return "eccellente";
  if (grade >= 8.4) return "molto buono";
  if (grade >= 7.4) return "buono";
  if (grade >= 6.4) return "discreto";
  if (grade > 0) return "da consolidare";
  return "non valutato";
}

function inferredGrade(result: Pick<PlayerResult, "category" | "difficulty" | "score" | "hintsUsed" | "attempts" | "elapsedMs" | "grade">): number {
  if (typeof result.grade === "number") return roundGrade(result.grade);
  const score = Number.isFinite(result.score) ? result.score : 0;
  const difficulty = Number.isFinite(result.difficulty) ? result.difficulty : 1;
  const hintsUsed = Number.isFinite(result.hintsUsed) ? result.hintsUsed : 0;
  const attempts = Number.isFinite(result.attempts) ? result.attempts : 1;
  const elapsedMs = Number.isFinite(result.elapsedMs) ? result.elapsedMs : 0;
  const scoreComponent = clamp(score / (result.category === "exercise" ? 38 : 150), 0, 4.2);
  const difficultyLift = (difficulty - 1) * 0.13;
  const supportPenalty = hintsUsed * 0.16 + Math.max(0, attempts - 1) * 0.1;
  const timePenalty = result.category === "exercise" ? clamp((elapsedMs / 1000 - 240) / 900, 0, 0.5) : 0;
  return roundGrade(5 + scoreComponent + difficultyLift - supportPenalty - timePenalty);
}

function average(values: number[]): number {
  return values.length > 0 ? values.reduce((sum, value) => sum + value, 0) / values.length : 0;
}

function averageGrade(results: PlayerResult[]): number {
  return roundGrade(average(results.map((result) => inferredGrade(result))));
}

function bestGrade(results: PlayerResult[]): number {
  return roundGrade(Math.max(0, ...results.map((result) => inferredGrade(result))));
}

function lastGrade(results: PlayerResult[]): number {
  const latest = [...results].sort((a, b) => new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime())[0];
  return latest ? inferredGrade(latest) : 0;
}

function weightedAverageGrade(results: PlayerResult[]): number {
  if (results.length === 0) return 0;
  const weighted = results.reduce<{ total: number; weight: number }>((acc, result) => {
    const weight = result.category === "mission" ? 1.45 : result.category === "focus" ? 1.2 : 0.55;
    acc.total += inferredGrade(result) * weight;
    acc.weight += weight;
    return acc;
  }, { total: 0, weight: 0 });
  return roundGrade(weighted.weight > 0 ? weighted.total / weighted.weight : 0);
}

function bestTime(results: PlayerResult[]): number {
  return results.length > 0 ? Math.min(...results.map((result) => result.elapsedMs)) : 0;
}

function trendFor(results: PlayerResult[]): "up" | "steady" | "down" {
  const chronological = [...results].sort((a, b) => new Date(a.completedAt).getTime() - new Date(b.completedAt).getTime());
  if (chronological.length < 4) return "steady";
  const recent = chronological.slice(-3).map((result) => inferredGrade(result));
  const previous = chronological.slice(Math.max(0, chronological.length - 6), chronological.length - 3).map((result) => inferredGrade(result));
  const delta = average(recent) - average(previous);
  if (delta >= 0.35) return "up";
  if (delta <= -0.35) return "down";
  return "steady";
}

function nextGoalFor(label: string, grade: number, bestTimeMs: number, runs: number): string {
  if (runs === 0) return `Completa un primo percorso di ${label.toLowerCase()}.`;
  if (grade < 6.4) return `Ripeti ${label.toLowerCase()} a un livello gestibile: punta a capire il metodo prima della velocita.`;
  if (grade < 8) return `Consolida ${label.toLowerCase()}: prova a ridurre indizi e tentativi inutili.`;
  if (bestTimeMs > 0) return `Sfida ${label.toLowerCase()}: mantieni almeno ${grade}/10 con un seed nuovo e tempo piu pulito.`;
  return `Aumenta difficolta in ${label.toLowerCase()} mantenendo precisione.`;
}

function scoreByDomain(scores: ProceduralPuzzleScore[]): Array<{ label: string; score: number }> {
  const totals = scores.reduce<Partial<Record<ProceduralSpecialization, number>>>((acc, score) => {
    acc[score.domain] = (acc[score.domain] ?? 0) + score.total;
    return acc;
  }, {});
  return Object.entries(totals)
    .map(([domain, score]) => ({ label: proceduralScoring.domainLabel(domain), score: score ?? 0 }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 5);
}

export class PlayerSystem {
  private store: PlayerStore = this.loadStore();

  load(): PlayerStore {
    this.store = this.loadStore();
    this.persist();
    return this.store;
  }

  get data(): PlayerStore {
    return this.store;
  }

  getPlayers(): PlayerProfile[] {
    return [...this.store.players].sort((a, b) => a.name.localeCompare(b.name));
  }

  getActivePlayer(): PlayerProfile {
    const player = this.store.players.find((item) => item.id === this.store.activePlayerId);
    if (player) return player;
    const fallback = this.store.players[0] ?? this.createPlayer("Giocatrice 1");
    this.store.activePlayerId = fallback.id;
    this.persist();
    return fallback;
  }

  createPlayer(name: string): PlayerProfile {
    const cleanName = this.cleanName(name);
    const createdAt = nowIso();
    const player: PlayerProfile = {
      id: createId("player"),
      name: cleanName,
      createdAt,
      lastActiveAt: createdAt,
    };
    this.store.players = [...this.store.players, player];
    this.store.activePlayerId = player.id;
    this.persist();
    return player;
  }

  setActivePlayer(playerId: string): void {
    const player = this.store.players.find((item) => item.id === playerId);
    if (!player) return;
    player.lastActiveAt = nowIso();
    this.store.activePlayerId = player.id;
    this.persist();
  }

  renameActivePlayer(name: string): void {
    const player = this.getActivePlayer();
    player.name = this.cleanName(name);
    player.lastActiveAt = nowIso();
    this.persist();
  }

  recordProceduralRun(run: ProceduralRunSave): void {
    if (!run.completedAt) return;
    const completedAt = run.completedAt;
    const active = this.getActivePlayer();
    const mode = proceduralRunRules.modeFor(run);
    const elapsedMs = Math.max(1000, new Date(completedAt).getTime() - new Date(run.startedAt).getTime());
    const puzzleScores = Object.values(run.puzzleStats ?? {});
    const attempts = puzzleScores.reduce((sum, score) => sum + Math.max(1, score.attempts), 0);
    const nextResults: PlayerResult[] = [];

    if (mode === "mission") {
      nextResults.push({
        id: createId("result"),
        sourceKey: `${active.id}:${run.seed}:${completedAt}:mission:${run.mission.id}`,
        playerId: active.id,
        playerName: active.name,
        category: "mission",
        key: run.mission.id,
        label: run.mission.title,
        difficulty: run.difficulty,
        score: run.score?.total ?? 0,
        elapsedMs,
        hintsUsed: run.hintsUsed,
        attempts,
        completedAt,
        mode,
        seed: run.seed,
        grade: inferredGrade({
          category: "mission",
          difficulty: run.difficulty,
          score: run.score?.total ?? 0,
          elapsedMs,
          hintsUsed: run.hintsUsed,
          attempts,
        }),
      });
    }

    if (mode === "training") {
      const focus = proceduralRunRules.focusFor(run);
      nextResults.push({
        id: createId("result"),
        sourceKey: `${active.id}:${run.seed}:${completedAt}:focus:${focus}`,
        playerId: active.id,
        playerName: active.name,
        category: "focus",
        key: focus,
        label: focusLabels[focus] ?? "Focus",
        difficulty: run.difficulty,
        score: run.trainingResult?.score ?? run.score?.total ?? 0,
        elapsedMs: run.trainingResult?.elapsedMs ?? elapsedMs,
        hintsUsed: run.hintsUsed,
        attempts,
        completedAt,
        mode,
        seed: run.seed,
        grade: run.trainingResult?.grade ?? inferredGrade({
          category: "focus",
          difficulty: run.difficulty,
          score: run.trainingResult?.score ?? run.score?.total ?? 0,
          elapsedMs: run.trainingResult?.elapsedMs ?? elapsedMs,
          hintsUsed: run.hintsUsed,
          attempts,
        }),
        gradeLabel: run.trainingResult?.gradeLabel,
      });
    }

    puzzleScores.forEach((score) => {
      const key = basePuzzleKey(score.puzzleId);
      nextResults.push({
        id: createId("result"),
        sourceKey: `${active.id}:${run.seed}:${completedAt}:exercise:${score.puzzleId}`,
        playerId: active.id,
        playerName: active.name,
        category: "exercise",
        key,
        label: puzzleLabels[key] ?? score.puzzleId,
        difficulty: run.difficulty,
        score: score.total,
        elapsedMs: score.elapsedMs,
        hintsUsed: score.hintsUsed,
        attempts: score.attempts,
        completedAt: score.completedAt ?? completedAt,
        mode,
        seed: run.seed,
        grade: inferredGrade({
          category: "exercise",
          difficulty: run.difficulty,
          score: score.total,
          elapsedMs: score.elapsedMs,
          hintsUsed: score.hintsUsed,
          attempts: score.attempts,
        }),
      });
    });

    nextResults.forEach((result) => {
      result.grade = inferredGrade(result);
      result.gradeLabel = result.gradeLabel ?? gradeLabel(result.grade);
    });

    const knownSources = new Set(this.store.results.map((result) => result.sourceKey));
    const uniqueNewResults = nextResults.filter((result) => !knownSources.has(result.sourceKey));
    if (uniqueNewResults.length === 0) return;

    active.lastActiveAt = nowIso();
    this.store.results = [...this.store.results, ...uniqueNewResults].slice(-2000);
    this.persist();
  }

  topResults(category: ResultCategory, key?: string, limit = 20): PlayerResult[] {
    return sortedResults(this.store.results.filter((result) => result.category === category && (!key || result.key === key))).slice(0, limit);
  }

  playerReport(playerId = this.getActivePlayer().id): PlayerReport {
    const player = this.store.players.find((item) => item.id === playerId) ?? this.getActivePlayer();
    const results = this.store.results.filter((result) => result.playerId === player.id);
    const missions = results.filter((result) => result.category === "mission");
    const focusRuns = results.filter((result) => result.category === "focus");
    const exercises = results.filter((result) => result.category === "exercise");
    const totalScore = results.reduce((sum, result) => sum + result.score, 0);
    const averageScore = results.length > 0 ? Math.round(totalScore / results.length) : 0;
    const globalGrade = weightedAverageGrade(results);
    const missionGrade = averageGrade(missions);
    const trainingGrade = averageGrade(focusRuns);
    const exerciseGrade = averageGrade(exercises);
    const trainingStats = this.trainingStatsFor(focusRuns);
    const subjectStats = this.subjectStatsFor(exercises);
    const weakestSubject = subjectStats
      .filter((item) => item.exercises > 0)
      .sort((a, b) => a.averageGrade - b.averageGrade)[0];
    const nextGoal = results.length === 0
      ? "Completa una missione o un focus: il registro iniziera a costruire una traiettoria personale."
      : weakestSubject && weakestSubject.averageGrade < 7.2
        ? `Obiettivo consigliato: rinforza ${weakestSubject.label.toLowerCase()} con un livello adatto e meno aiuti.`
        : globalGrade >= 8.5
          ? "Stai consolidando bene: prova una difficolta piu alta mantenendo precisione e spiegazione del metodo."
          : "Prossimo passo: scegli il focus con voto piu basso e ripeti con un nuovo seed.";
    const activePuzzleScores = Object.values(this.store.results
      .filter((result) => result.playerId === player.id && result.category === "exercise")
      .reduce<Record<string, ProceduralPuzzleScore>>((acc, result) => {
        acc[result.id] = {
          puzzleId: result.key,
          domain: result.key === "math"
            ? "matematica"
            : result.key === "language"
              ? "italiano"
              : result.key === "english"
                ? "inglese"
                : result.key === "circuit"
                  ? "elettronica"
                  : result.key === "robot"
                    ? "coding"
                    : "libera",
          startedAt: result.completedAt,
          completedAt: result.completedAt,
          elapsedMs: result.elapsedMs,
          hintsUsed: result.hintsUsed,
          attempts: result.attempts,
          basePoints: 0,
          difficultyBonus: 0,
          speedBonus: 0,
          focusBonus: 0,
          supportPenalty: 0,
          total: result.score,
          feedback: "",
        };
        return acc;
      }, {}));

    return {
      player,
      resultCount: results.length,
      missionCount: missions.length,
      focusCount: focusRuns.length,
      exerciseCount: exercises.length,
      totalScore,
      averageScore,
      bestMission: sortedResults(missions)[0],
      bestFocus: sortedResults(focusRuns)[0],
      bestExercise: sortedResults(exercises)[0],
      recent: [...results].sort((a, b) => new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime()).slice(0, 8),
      strengths: scoreByDomain(activePuzzleScores),
      globalGrade,
      globalGradeLabel: gradeLabel(globalGrade),
      missionGrade,
      trainingGrade,
      exerciseGrade,
      nextGoal,
      trainingStats,
      subjectStats,
    };
  }

  formatResult(result: PlayerResult): string {
    return `${result.playerName} | L${result.difficulty} | ${result.score} pt | ${formatDuration(result.elapsedMs)} | ${result.hintsUsed} indizi`;
  }

  private loadStore(): PlayerStore {
    try {
      const raw = localStorage.getItem(PLAYER_STORE_KEY);
      if (!raw) return defaultStore();
      const parsed = JSON.parse(raw) as PlayerStore;
      const fallback = defaultStore();
      const players = Array.isArray(parsed.players) && parsed.players.length > 0 ? parsed.players : fallback.players;
      const activePlayerId = players.some((player) => player.id === parsed.activePlayerId) ? parsed.activePlayerId : players[0].id;
      return {
        version: 1,
        activePlayerId,
        players,
        results: Array.isArray(parsed.results)
          ? parsed.results.map((result) => {
            const grade = inferredGrade(result);
            return {
              ...result,
              grade,
              gradeLabel: result.gradeLabel ?? gradeLabel(grade),
            };
          })
          : [],
      };
    } catch {
      return defaultStore();
    }
  }

  private persist(): void {
    try {
      localStorage.setItem(PLAYER_STORE_KEY, JSON.stringify(this.store));
    } catch {
      // Keep in-memory profiles alive when storage is restricted.
    }
  }

  private trainingStatsFor(focusRuns: PlayerResult[]): TrainingProgressStat[] {
    return Object.entries(focusLabels)
      .filter(([focus]) => focus !== "libera")
      .map(([focus, label]) => {
        const runs = focusRuns.filter((result) => result.key === focus);
        const avgGrade = averageGrade(runs);
        const best = sortedResults(runs)[0];
        return {
          focus: focus as ProceduralSpecialization,
          label,
          runs: runs.length,
          bestGrade: bestGrade(runs),
          averageGrade: avgGrade,
          lastGrade: lastGrade(runs),
          bestTimeMs: bestTime(runs),
          averageTimeMs: Math.round(average(runs.map((result) => result.elapsedMs))),
          bestScore: best?.score ?? 0,
          trend: trendFor(runs),
          nextGoal: nextGoalFor(label, avgGrade, bestTime(runs), runs.length),
        };
      });
  }

  private subjectStatsFor(exercises: PlayerResult[]): SubjectProgressStat[] {
    return Object.entries(puzzleLabels).map(([key, label]) => {
      const runs = exercises.filter((result) => result.key === key);
      const avgGrade = averageGrade(runs);
      return {
        key,
        label,
        exercises: runs.length,
        bestGrade: bestGrade(runs),
        averageGrade: avgGrade,
        lastGrade: lastGrade(runs),
        bestTimeMs: bestTime(runs),
        averageScore: Math.round(average(runs.map((result) => result.score))),
        nextGoal: nextGoalFor(label, avgGrade, bestTime(runs), runs.length),
      };
    });
  }

  private cleanName(name: string): string {
    const clean = name.trim().replace(/\s+/g, " ").slice(0, 24);
    return clean.length >= 2 ? clean : `Giocatrice ${this.store.players.length + 1}`;
  }
}

export const playerSystem = new PlayerSystem();
