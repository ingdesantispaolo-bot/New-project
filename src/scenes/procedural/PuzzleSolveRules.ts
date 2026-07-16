import type { ProceduralPuzzleScore, ProceduralRunSave } from "../../procedural/ProceduralTypes";
import { puzzleKindFromId, type ProceduralPuzzleId } from "./ProceduralMissionLayout";

export const CLEAN_SOLVE_TIME_BONUS_MS = 18_000;

export interface CleanSolveReward {
  cleanCount: number;
  grantsLife: boolean;
  update: Partial<ProceduralRunSave>;
  message: string;
}

export function isCleanPuzzleSolve(score: Pick<ProceduralPuzzleScore, "attempts" | "hintsUsed">): boolean {
  return score.attempts <= 1 && score.hintsUsed === 0;
}

export function puzzleCompetencyAward(difficulty: number, focusBonus: number): number {
  return 10 + difficulty * 2 + (focusBonus > 0 ? 4 : 0);
}

export function puzzleKindLabel(id: string): string {
  return {
    language: "italiano",
    latin: "latino",
    circuit: "circuiti",
    math: "matematica",
    english: "inglese",
    robot: "coding",
    coding: "coding",
    music: "musica",
    physics: "fisica",
  }[puzzleKindFromId(id)];
}

export function solvedPrincipleForKind(kind: ProceduralPuzzleId): string {
  const defaults: Record<ProceduralPuzzleId, string> = {
    language: "il messaggio diventa eseguibile quando accordo e ordine delle parole dicono al sistema cosa fare.",
    latin: "la forma latina si riconosce collegando desinenza, funzione e traduzione nel contesto.",
    circuit: "il LED si accende solo se la corrente trova un percorso chiuso e il verso giusto.",
    math: "il codice nasce rispettando l'ordine dei passaggi: ogni operazione trasforma il valore precedente.",
    english: "la procedura sicura si estrae da condizioni, ordine e divieti, non traducendo tutto.",
    robot: "la rotta migliore è la sequenza minima: osserva ostacoli e direzione prima di muovere.",
    coding: "una sequenza corretta nasce leggendo l'effetto di ogni istruzione, un passo alla volta.",
    music: "l'altezza di una nota si legge dalla sua posizione sul pentagramma, data la chiave.",
    physics: "un fenomeno diventa prevedibile quando grandezze, unita, grafico e modello raccontano la stessa storia.",
  };
  return defaults[kind];
}

export function remainingPuzzleLine(remainingLabels: string[]): string {
  return remainingLabels.length > 0
    ? `Restano: ${remainingLabels.join(", ")}.`
    : "Percorso disciplinare completo: la porta finale è pronta.";
}

export function puzzleSolveFeedback(
  effectLine: string,
  principle: string,
  scoreTotal: number,
  elapsedLabel: string,
  remainingLabels: string[],
): string {
  return `${effectLine} Hai consolidato: ${principle} +${scoreTotal} punti (${elapsedLabel}). ${remainingPuzzleLine(remainingLabels)}`;
}

export function cleanSolveCount(run: Pick<ProceduralRunSave, "puzzleStats">): number {
  return Object.values(run.puzzleStats ?? {}).filter(isCleanPuzzleSolve).length;
}

export function buildCleanSolveReward(
  run: ProceduralRunSave,
  maxLivesFallback: number,
  nowMs = Date.now(),
): CleanSolveReward {
  const cleanCount = cleanSolveCount(run);
  const update: Partial<ProceduralRunSave> = {};
  if (run.deadlineAt) {
    const currentDeadline = new Date(run.deadlineAt).getTime();
    update.deadlineAt = new Date(Math.max(nowMs, currentDeadline) + CLEAN_SOLVE_TIME_BONUS_MS).toISOString();
  }
  const maxLives = run.maxLives ?? maxLivesFallback;
  const lives = run.lives ?? maxLives;
  const grantsLife = cleanCount === 3 && lives < maxLives;
  if (grantsLife) {
    update.lives = lives + 1;
  }
  return {
    cleanCount,
    grantsLife,
    update,
    message: grantsLife
      ? "Serie pulita! Tre diagnosi senza aiuti: ti restituisco una vita. Continua così."
      : "Soluzione autonoma: ti recupero qualche secondo. Il metodo paga.",
  };
}
