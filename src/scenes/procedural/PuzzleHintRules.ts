export interface HintablePuzzle {
  hints: string[];
  pedagogy?: { hintLadder: Array<{ text: string }> };
}

export function puzzleHintTexts(puzzle: HintablePuzzle): string[] {
  const ladder = puzzle.pedagogy?.hintLadder?.map((item) => item.text).filter(Boolean) ?? [];
  return ladder.length > 0 ? ladder : puzzle.hints;
}

export function nextPedagogicHint(puzzle: HintablePuzzle, usedHints: number, fallback: string): string {
  const hints = puzzleHintTexts(puzzle);
  return hints[Math.min(usedHints, hints.length - 1)] ?? fallback;
}

export function hintButtonLabel(puzzle: HintablePuzzle, usedHints: number, label: string): string {
  const total = puzzleHintTexts(puzzle).length;
  const used = Math.min(usedHints, total);
  if (total === 0) return label;
  return used >= total ? "Indizi esauriti" : `${label} ${used + 1}/${total}`;
}
