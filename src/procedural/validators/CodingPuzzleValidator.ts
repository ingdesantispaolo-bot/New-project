import type { GeneratedCodingPuzzle } from "../ProceduralTypes";

export class CodingPuzzleValidator {
  validate(puzzle: GeneratedCodingPuzzle): boolean {
    const choices = new Set(puzzle.options);
    return puzzle.codeLines.length >= 3
      && puzzle.options.length >= 3
      && choices.size === puzzle.options.length
      && choices.has(puzzle.correctOption)
      && puzzle.question.trim().length > 20
      && puzzle.explanation.trim().length > 35
      && puzzle.hints.length >= 2
      && puzzle.competencies.length >= 2;
  }
}
