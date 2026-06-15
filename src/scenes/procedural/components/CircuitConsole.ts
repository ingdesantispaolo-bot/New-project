import type { CircuitFaultType, GeneratedCircuitPuzzle } from "../../../procedural/ProceduralTypes";

export type CircuitConsoleModel = {
  title: string;
  symptom: string;
  diagnosticQuestion: string;
  requiredChecks: string[];
  requiredRepairs: CircuitFaultType[];
  repairChoices: CircuitFaultType[];
  testerReadings: NonNullable<GeneratedCircuitPuzzle["testerReadings"]>;
  componentGuide: NonNullable<GeneratedCircuitPuzzle["componentGuide"]>;
  diagnosticPlan: string[];
  learningPurpose: string;
  difficultyLabel: string;
  conceptTags: string[];
  explanations: Partial<Record<CircuitFaultType, string>>;
};

export class CircuitConsole {
  static fromPuzzle(puzzle: GeneratedCircuitPuzzle): CircuitConsoleModel {
    return {
      title: puzzle.title,
      symptom: puzzle.symptom,
      diagnosticQuestion: puzzle.diagnosticQuestion ?? "Dove si interrompe il percorso della corrente?",
      requiredChecks: puzzle.observations,
      requiredRepairs: puzzle.requiredRepairs,
      repairChoices: puzzle.repairChoices ?? puzzle.requiredRepairs,
      testerReadings: puzzle.testerReadings ?? [],
      componentGuide: puzzle.componentGuide ?? [],
      diagnosticPlan: puzzle.diagnosticPlan ?? [
        "Segui il percorso della corrente.",
        "Confronta sintomo e letture del tester.",
        "Ripara solo la causa dimostrata.",
      ],
      learningPurpose: puzzle.learningPurpose ?? "Capire come un circuito diventa chiuso, stabile e sicuro.",
      difficultyLabel: puzzle.difficultyLabel ?? "Livello 1 - diagnosi guidata",
      conceptTags: puzzle.conceptTags ?? ["circuito chiuso", "tester"],
      explanations: puzzle.explanationByFault ?? {},
    };
  }
}
