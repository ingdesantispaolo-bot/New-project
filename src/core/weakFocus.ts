/** Trainable focus subjects (excludes scienze/trasversali, which have no focus path). */
export const TRAINABLE_BRANCHES = new Set<string>([
  "matematica",
  "italiano",
  "inglese",
  "elettronica",
  "coding",
  "musica",
  "fisica",
  "latino",
]);

/**
 * Pure selection of the weakest practised trainable subject. Kept phaser-free so
 * it can be unit-tested in isolation; MasterySystem feeds it the live branches.
 */
export function selectWeakestFocus(branches: Array<{ id: string; score: number }>): string | undefined {
  const practised = branches.filter((branch) => TRAINABLE_BRANCHES.has(branch.id) && branch.score > 0);
  if (practised.length < 2) {
    return undefined;
  }
  return practised.reduce((min, branch) => (branch.score < min.score ? branch : min)).id;
}
