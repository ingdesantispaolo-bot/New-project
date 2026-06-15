import type { GeneratedRobotPuzzle, GridCommand } from "../../../procedural/ProceduralTypes";

export type RobotConsoleModel = {
  title: string;
  instructions: string[];
  expectedMinimumCommands: number;
  solutionCommands: GridCommand[];
  successConditions: string[];
  conceptTags: string[];
  buggedCommands?: GridCommand[];
  debugBrief?: string;
};

export class RobotConsole {
  static fromPuzzle(puzzle: GeneratedRobotPuzzle): RobotConsoleModel {
    return {
      title: puzzle.title,
      instructions: puzzle.instructions,
      expectedMinimumCommands: Math.max(5, puzzle.solutionCommands.length - 1),
      solutionCommands: puzzle.solutionCommands,
      successConditions: puzzle.successConditions ?? [
        "Raccogli la chiave dalla stessa casella della stella.",
        "Raggiungi il quadrato di uscita e usa Esci.",
      ],
      conceptTags: puzzle.conceptTags ?? puzzle.requiredConcepts ?? [],
      buggedCommands: puzzle.buggedCommands,
      debugBrief: puzzle.debugBrief,
    };
  }
}
