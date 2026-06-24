import type { GeneratedMathPuzzle } from "../../../procedural/ProceduralTypes";

export type MathTerminalModel = {
  title: string;
  prompt: string;
  domainLabel: string;
  curriculumTags: string[];
  difficultyLabel: string;
  learningPurpose: string;
  mentalMathNote: string;
  strategy: string;
  scratchpadPrompt: string;
  theoryPrinciple: string;
  workedExample: string;
  expectedAnswer: number;
  minimumReasoningSteps: number;
};

const mathDomainLabels: Record<NonNullable<GeneratedMathPuzzle["archetype"]>, string> = {
  "calcolo-diretto": "Calcolo strategico",
  "ragionamento-inverso": "Ragionamento inverso",
  sequenza: "Sequenze e pattern",
  vincolo: "Vincoli numerici",
  "diagnosi-errore": "Controllo dell'errore",
  "lettura-dati": "Lettura dati",
  proporzione: "Rapporti e proporzioni",
  "pre-algebra": "Pre-algebra",
  frazioni: "Frazioni operative",
  percentuali: "Percentuali",
  geometria: "Geometria applicata",
  statistica: "Statistica di base",
  probabilita: "Probabilita",
  "potenze-radici": "Potenze e radici",
  "funzione-lineare": "Funzioni lineari",
  "sistemi-lineari": "Sistemi semplici",
  "equazione-primo-grado": "Equazioni di primo grado",
  "equazione-secondo-grado": "Equazioni di secondo grado",
  "grafici-cartesiani": "Officina dei grafici",
  coordinate: "Coordinate e griglie",
};

export class MathTerminal {
  static fromPuzzle(puzzle: GeneratedMathPuzzle): MathTerminalModel {
    return {
      title: puzzle.title,
      prompt: puzzle.prompt,
      domainLabel: mathDomainLabels[puzzle.archetype ?? "calcolo-diretto"],
      curriculumTags: puzzle.curriculumTags ?? [],
      difficultyLabel: puzzle.difficultyLabel ?? "Livello non classificato",
      learningPurpose: puzzle.learningPurpose ?? puzzle.pedagogy?.learningGoal ?? "Allenare ragionamento matematico applicato.",
      mentalMathNote: puzzle.calculationAid?.mentalMathNote ?? "Puoi calcolare a mente se vuoi, ma puoi anche usare carta e passaggi intermedi.",
      strategy: puzzle.calculationAid?.strategy ?? "Risolvi un passaggio alla volta e controlla il risultato prima di inserirlo.",
      scratchpadPrompt: puzzle.calculationAid?.scratchpadPrompt ?? "Scrivi i passaggi su un taccuino: il gioco valuta il ragionamento, non la memoria.",
      theoryPrinciple: puzzle.pedagogy?.explanation.principle ?? "Ogni esercizio nasconde una regola matematica da riconoscere e applicare.",
      workedExample: puzzle.pedagogy?.explanation.workedExample ?? puzzle.solutionSteps?.join(" -> ") ?? "",
      expectedAnswer: puzzle.answer,
      minimumReasoningSteps: Math.max(2, puzzle.solutionSteps?.length ?? 0),
    };
  }
}
