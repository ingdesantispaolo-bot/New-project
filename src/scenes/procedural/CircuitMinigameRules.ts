import { proceduralScoring } from "../../core/ProceduralScoring";
import type {
  CircuitMinigamePrompt,
  DifficultyLevel,
  GeneratedCircuitMinigame,
  GeneratedCircuitPuzzle,
  ProceduralPuzzleScore,
  ProceduralRunSave,
} from "../../procedural/ProceduralTypes";
import type { CircuitMinigameSession } from "./ProceduralMissionDefs";

export function createCircuitMinigameSession(
  puzzleId: string,
  puzzle: GeneratedCircuitPuzzle,
  game: GeneratedCircuitMinigame,
  durationMs = game.durationMs,
): CircuitMinigameSession {
  return {
    puzzleId,
    puzzle,
    game,
    startedAt: 0,
    durationMs,
    promptIndex: 0,
    answered: 0,
    correct: 0,
    wrong: 0,
    streak: 0,
    bestStreak: 0,
    netScore: 0,
    selectedIds: new Set<string>(),
    feedback: "Leggi lo schema: componente, percorso, polarità o valori. Poi conferma una risposta.",
    locked: false,
    summaryOpen: false,
  };
}

export function currentCircuitMinigamePrompt(session: CircuitMinigameSession): CircuitMinigamePrompt {
  return session.game.prompts[session.promptIndex % session.game.prompts.length];
}

export function circuitMinigameElapsedMs(session: CircuitMinigameSession, now = Date.now()): number {
  return now - session.startedAt;
}

export function circuitMinigameRemainingMs(session: CircuitMinigameSession, now = Date.now()): number {
  return Math.max(0, session.durationMs - circuitMinigameElapsedMs(session, now));
}

export function circuitMinigameHint(prompt: CircuitMinigamePrompt): string {
  if (prompt.type === "component-id") {
    return "Collega il nome alla funzione: cosa fa quel componente nel circuito?";
  }
  if (prompt.type === "predict-led") {
    return "Il LED si accende solo se: interruttore chiuso, percorso continuo, polarità giusta e resistenza che protegge.";
  }
  if (prompt.type === "ohms-law") {
    return "Scrivi V = R × I e isola la grandezza richiesta prima di calcolare.";
  }
  return "In serie le resistenze si sommano; in parallelo la resistenza totale scende.";
}

export function circuitMinigameCorrectAward(session: CircuitMinigameSession, difficulty: DifficultyLevel): number {
  return 10 + difficulty * 2 + Math.min(12, session.streak * 2);
}

export function circuitMinigamePassed(
  session: CircuitMinigameSession,
  timedMissionMode: boolean,
  difficulty: DifficultyLevel,
): boolean {
  if (!timedMissionMode) {
    return true;
  }
  const minCorrect = Math.max(5, Math.min(12, 4 + Math.ceil(difficulty * 0.75)));
  const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
  return session.correct >= minCorrect && accuracy >= 0.62 && session.netScore > 0;
}

export function circuitMinigameFeedback(session: CircuitMinigameSession): string {
  if (session.answered === 0) {
    return "Nessuna risposta: leggi lo schema e decidi su componente, percorso o valori.";
  }
  const accuracy = session.correct / session.answered;
  if (accuracy >= 0.9 && session.bestStreak >= 8) {
    return "Ottimo: riconosci componenti, prevedi il LED e applichi la legge di Ohm con sicurezza.";
  }
  if (accuracy >= 0.72) {
    return "Buon lavoro: ora consolida la legge di Ohm e i collegamenti serie/parallelo.";
  }
  if (session.wrong >= session.correct) {
    return "Troppi tentativi: rallenta, leggi lo schema e ragiona su percorso e polarità.";
  }
  return "Calibrazione utile: punta a serie pulite e risposte spiegabili.";
}

export function buildCircuitMinigameScore(
  session: CircuitMinigameSession,
  run: ProceduralRunSave,
  existing: ProceduralPuzzleScore | undefined,
  now = new Date(),
): ProceduralPuzzleScore {
  const startedAt = existing?.startedAt ?? new Date(session.startedAt).toISOString();
  const completedAt = now.toISOString();
  const elapsedMs = Math.max(1_000, Math.min(session.durationMs, circuitMinigameElapsedMs(session, now.getTime())));
  const accuracy = session.answered > 0 ? session.correct / session.answered : 0;
  const basePoints = session.correct * (10 + run.difficulty);
  const difficultyBonus = session.correct * run.difficulty * 2;
  const speedBonus = Math.min(100, session.bestStreak * 6 + session.answered * 2 + Math.round(accuracy * 36));
  const focusBonus = run.focus.includes("elettronica") || run.focus.some((item) => item.startsWith("elettronica."))
    ? 20 + run.difficulty * 3
    : 0;
  const supportPenalty = (existing?.hintsUsed ?? 0) * 6 + session.wrong * (8 + run.difficulty);
  const total = Math.max(0, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);
  return {
    puzzleId: session.puzzleId,
    domain: proceduralScoring.puzzleDomain(session.puzzleId),
    startedAt,
    completedAt,
    elapsedMs,
    hintsUsed: existing?.hintsUsed ?? 0,
    attempts: Math.max(1, existing?.attempts ?? 1),
    basePoints,
    difficultyBonus,
    speedBonus,
    focusBonus,
    supportPenalty,
    total,
    feedback: circuitMinigameFeedback(session),
  };
}
