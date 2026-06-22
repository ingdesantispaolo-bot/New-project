import type Phaser from "phaser";
import type { GeneratedLanguagePuzzle } from "../../../procedural/ProceduralTypes";

export type LanguageRepairModel = {
  title: string;
  corrupted: string;
  instruction: string;
  options: string[];
  correctAnswer: string;
  diagnosticSteps: string[];
  hints: string[];
  difficultyLabel: string;
  conceptTags: string[];
  learningPurpose: string;
  repairGoal: string;
  method: string;
  optionFeedback: Record<string, string>;
};

export class LanguageRepairConsole {
  static fromPuzzle(puzzle: GeneratedLanguagePuzzle, analyzed: boolean): LanguageRepairModel {
    return {
      title: puzzle.title,
      corrupted: puzzle.corrupted,
      instruction: analyzed
        ? puzzle.diagnosticSteps.map((step, index) => `${index + 1}. ${step}`).join("\n")
        : "Prima stabilizza il segnale: cerca chi compie l'azione, poi controlla se verbo e nome concordano.",
      options: puzzle.options,
      correctAnswer: puzzle.repaired,
      diagnosticSteps: puzzle.diagnosticSteps,
      hints: puzzle.hints,
      difficultyLabel: puzzle.difficultyLabel ?? "Livello 1 - riparazione guidata",
      conceptTags: puzzle.conceptTags ?? ["comprensione", "grammatica", "coerenza"],
      learningPurpose: puzzle.learningPurpose ?? "Allena comprensione e grammatica dentro un messaggio tecnico da rendere eseguibile.",
      repairGoal: puzzle.repairGoal ?? "Ripara il messaggio senza cambiare il significato operativo.",
      method: puzzle.method ?? "Trova soggetto, verbo e connettivi; poi controlla che il comando resti eseguibile.",
      optionFeedback: puzzle.optionFeedback ?? {},
    };
  }

  static addHeader(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, model: LanguageRepairModel): void {
    overlay.add(scene.add.text(56, 76, model.difficultyLabel.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const corruptedSize = model.corrupted.length > 118 ? 14 : model.corrupted.length > 86 ? 15 : 17;
    overlay.add(scene.add.text(56, 106, `Segnale danneggiato: "${model.corrupted}"`, {
      fontFamily: "Inter, Arial",
      fontSize: `${corruptedSize}px`,
      color: "#f7d37a",
      wordWrap: { width: 1060, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.text(56, 172, model.instruction, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 1060, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
  }
}
