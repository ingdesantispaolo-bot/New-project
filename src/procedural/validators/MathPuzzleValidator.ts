import type { GeneratedMathPuzzle } from "../ProceduralTypes";
import { MathSolver } from "../solvers/MathSolver";

export class MathPuzzleValidator {
  private solver = new MathSolver();

  validate(puzzle: GeneratedMathPuzzle): boolean {
    const answerIsInteger = Number.isInteger(puzzle.answer);
    const asksRounding = /arrotond/i.test(puzzle.prompt);
    const roundingIsExplicit = !asksRounding || /,5|superiore|inferiore|regola indicata|senza arrotondare/i.test(puzzle.prompt);
    const formatIsExplicit = /un solo numero intero|numero intero/i.test(puzzle.prompt);
    return (
      this.solver.isIntegerSolution(puzzle) &&
      answerIsInteger &&
      puzzle.answer >= 0 &&
      puzzle.answer <= 9999 &&
      puzzle.hints.length >= 2 &&
      puzzle.prompt.length > 20 &&
      roundingIsExplicit &&
      formatIsExplicit
    );
  }
}
