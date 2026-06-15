import type { GeneratedMathPuzzle } from "../ProceduralTypes";

export class MathSolver {
  isIntegerSolution(puzzle: GeneratedMathPuzzle): boolean {
    return Number.isInteger(puzzle.answer) && Number.isFinite(puzzle.answer);
  }
}
