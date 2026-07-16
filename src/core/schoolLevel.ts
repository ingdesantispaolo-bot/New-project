import type { DifficultyLevel } from "../procedural/ProceduralTypes";

/** Anno della scuola secondaria di primo grado (scuola media). */
export type SchoolYear = 1 | 2 | 3;

export const schoolYearLabel: Record<SchoolYear, string> = {
  1: "1ª media",
  2: "2ª media",
  3: "3ª media",
};

/**
 * Profondità massima adatta a un anno scolastico. Un profilo di prima media non
 * viene spinto sui livelli 7-8 ("Ponte verso le superiori"), dove comparirebbero
 * concetti (equazioni, numeri relativi, funzioni) non ancora affrontati in classe.
 * Un profilo senza anno impostato non ha tetto: l'adattività resta libera.
 */
export function maxDifficultyForSchoolYear(year: SchoolYear | undefined): DifficultyLevel {
  if (year === 1) return 3;
  if (year === 2) return 5;
  return 8;
}

/** Applica il tetto dell'anno a una profondità, senza mai scendere sotto 1. */
export function capDifficultyToSchoolYear(level: number, year: SchoolYear | undefined): DifficultyLevel {
  const max = maxDifficultyForSchoolYear(year);
  return Math.max(1, Math.min(max, Math.round(level))) as DifficultyLevel;
}
