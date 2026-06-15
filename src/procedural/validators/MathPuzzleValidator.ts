import type { GeneratedMathPuzzle } from "../ProceduralTypes";
import { MathSolver } from "../solvers/MathSolver";

export class MathPuzzleValidator {
  private solver = new MathSolver();

  validate(puzzle: GeneratedMathPuzzle): boolean {
    return (
      this.solver.isIntegerSolution(puzzle) &&
      puzzle.answer >= 0 &&
      puzzle.answer <= 9999 &&
      puzzle.hints.length >= 2 &&
      puzzle.prompt.length > 20
    );
  }
}
