import type { CodingChallengeType, GeneratedCodingPuzzle } from "../ProceduralTypes";
import { CodingSolver } from "../solvers/CodingSolver";

/** Challenge types whose answer is the deterministic printed output of the code. */
const OUTPUT_TYPES: ReadonlySet<CodingChallengeType> = new Set<CodingChallengeType>([
  "trace-output",
  "variable-state",
  "loop-count",
  "conditional-branch",
  "boolean-logic",
]);

export class CodingPuzzleValidator {
  private readonly solver = new CodingSolver();

  validate(puzzle: GeneratedCodingPuzzle): boolean {
    const choices = new Set(puzzle.options);
    const structurallyValid = puzzle.codeLines.length >= 3
      && puzzle.options.length >= 4
      && choices.size === puzzle.options.length
      && choices.has(puzzle.correctOption)
      && puzzle.question.trim().length > 20
      && puzzle.explanation.trim().length > 35
      && puzzle.hints.length >= 2
      && puzzle.competencies.length >= 2;
    if (!structurallyValid) {
      return false;
    }

    // Semantic check: for "predict the output" puzzles, re-execute the code and
    // confirm the declared correct option is genuinely what the program prints.
    // (Minigame wrappers expose only their first prompt; their prompts are
    // validated separately by the test suite.)
    if (!puzzle.minigame && OUTPUT_TYPES.has(puzzle.challengeType)) {
      const computed = this.solver.run(puzzle.codeLines);
      return computed !== undefined && computed === puzzle.correctOption;
    }
    return true;
  }
}
