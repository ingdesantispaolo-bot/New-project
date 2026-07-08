import type { GeneratedCircuitPuzzle } from "../ProceduralTypes";

export class CircuitPuzzleValidator {
  validate(puzzle: GeneratedCircuitPuzzle): boolean {
    const hasCoreNodes = ["battery", "switch", "resistor", "led", "return"].every((node) => puzzle.nodes.includes(node));
    const repairable = puzzle.faults.every((fault) => puzzle.requiredRepairs.includes(fault));
    const repairsAreUnique = new Set(puzzle.requiredRepairs).size === puzzle.requiredRepairs.length;
    const choicesAreUnique = new Set(puzzle.repairChoices ?? []).size === (puzzle.repairChoices?.length ?? 0);
    const hasDiagnostics = Boolean(puzzle.testerReadings?.length && puzzle.diagnosticPlan?.length && puzzle.learningPurpose);
    const hasPlausibleChoices = Boolean(
      puzzle.repairChoices?.length
      && puzzle.requiredRepairs.every((fault) => puzzle.repairChoices?.includes(fault))
      && puzzle.repairChoices.length > puzzle.requiredRepairs.length,
    );
    const componentChallengesAreValid = (puzzle.componentChallenges ?? []).every((challenge) => {
      const symbolChoices = new Set(challenge.symbolChoices);
      const functionChoices = new Set(challenge.functionChoices);
      return (
        challenge.componentId.length > 0
        && challenge.explanation.length > 30
        && challenge.visualHint.length > 8
        && challenge.symbolChoices.length >= 3
        && challenge.functionChoices.length >= 3
        && symbolChoices.size === challenge.symbolChoices.length
        && functionChoices.size === challenge.functionChoices.length
        && symbolChoices.has(challenge.correctSymbol)
        && functionChoices.has(challenge.correctFunction)
      );
    });
    return hasCoreNodes
      && repairable
      && repairsAreUnique
      && choicesAreUnique
      && puzzle.faults.length > 0
      && puzzle.hints.length >= puzzle.faults.length
      && hasDiagnostics
      && hasPlausibleChoices
      && componentChallengesAreValid;
  }
}
