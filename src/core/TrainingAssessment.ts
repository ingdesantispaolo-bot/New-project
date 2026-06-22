import type { ProceduralRunSave, TrainingRunResult } from "../procedural/ProceduralTypes";
import { proceduralRunRules } from "./ProceduralRunRules";

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function gradeLabel(grade: number): string {
  if (grade >= 9.5) return "eccellente";
  if (grade >= 8.5) return "molto buono";
  if (grade >= 7.5) return "buono";
  if (grade >= 6.5) return "discreto";
  return "da consolidare";
}

function nextTrainingGoal(grade: number, speedRatio: number, hintsUsed: number, attempts: number, requiredCount: number, difficulty: number): string {
  if (attempts > requiredCount + 1) {
    return "Riprova spiegando prima il metodo: osserva il dato chiave, scegli una strategia, poi verifica.";
  }
  if (hintsUsed > 1) {
    return "Riprova usando al massimo un indizio: l'obiettivo e riconoscere il principio senza dipendere dagli aiuti.";
  }
  if (grade < 6.5) {
    return "Consolida lo stesso livello: punta a precisione e passaggi ordinati prima di aumentare difficolta.";
  }
  if (grade >= 8.5 && difficulty < 8) {
    return `Passa al livello ${difficulty + 1}: hai margine per vincoli piu stretti.`;
  }
  return "Sfida consigliata: ripeti con un nuovo seed e cerca una soluzione piu pulita.";
}

export function assessTrainingRun(run: ProceduralRunSave, completedAt: string): TrainingRunResult {
  const focus = proceduralRunRules.focusFor(run);
  const elapsedMs = Math.max(0, new Date(completedAt).getTime() - new Date(run.startedAt).getTime());
  const requiredCount = Math.max(1, run.mission.objectives.length || run.solvedPuzzleIds.length || 1);
  const targetMs = requiredCount * (86 + run.difficulty * 12) * 1000;
  const speedRatio = elapsedMs / targetMs;
  const solvedRatio = Math.min(1, run.solvedPuzzleIds.length / requiredCount);
  const stats = Object.values(run.puzzleStats ?? {});
  const attempts = stats.reduce((total, stat) => total + stat.attempts, 0);
  const attemptPenalty = Math.max(0, attempts - requiredCount) * 0.18;
  const hintPenalty = run.hintsUsed * 0.22;
  // Fluency can add a small bonus, but careful reasoning is never penalized.
  const speedAdjustment = speedRatio <= 0.7 ? 0.35 : speedRatio <= 1 ? 0.18 : 0;
  const difficultyBonus = (run.difficulty - 1) * 0.08;
  const rawGrade = 6 + solvedRatio * 2.4 + speedAdjustment + difficultyBonus - hintPenalty - attemptPenalty;
  const grade = Math.round(clamp(rawGrade, 4, 10) * 10) / 10;
  return {
    focus,
    difficulty: run.difficulty,
    elapsedMs,
    score: run.score?.total ?? 0,
    grade,
    gradeLabel: gradeLabel(grade),
    nextGoal: nextTrainingGoal(grade, speedRatio, run.hintsUsed, attempts, requiredCount, run.difficulty),
    hintsUsed: run.hintsUsed,
    completedAt,
  };
}
