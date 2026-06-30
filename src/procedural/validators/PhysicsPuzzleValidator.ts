import type { GeneratedPhysicsPuzzle } from "../ProceduralTypes";

export class PhysicsPuzzleValidator {
  validate(puzzle: GeneratedPhysicsPuzzle): boolean {
    const optionSet = new Set(puzzle.options);
    return puzzle.title.trim().length > 8
      && puzzle.scenario.trim().length > 30
      && puzzle.prompt.trim().length > 20
      && puzzle.options.length >= 4
      && optionSet.size === puzzle.options.length
      && optionSet.has(puzzle.correctOption)
      && puzzle.explanation.trim().length > 45
      && puzzle.hints.length >= 2
      && puzzle.methodSteps.length >= 3
      && puzzle.conceptTags.length >= 2
      && puzzle.competencies.length >= 3
      && puzzle.visual.labels.length >= 2;
  }
}
