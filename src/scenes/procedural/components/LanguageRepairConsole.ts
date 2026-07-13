import type Phaser from "phaser";
import type { GeneratedLanguagePuzzle } from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";

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

export type LanguageChoicePanelState = {
  selectedOption?: string;
  hintLabel: string;
};

export type LanguageChoicePanelHandlers = {
  onSelect(option: string): void;
  onOpenBuilder(): void;
  onConfirm(): void;
  onHint(): void;
};

export type LanguageBuilderPanelState = {
  shuffledWords: string[];
  placedIndices: number[];
};

export type LanguageBuilderPanelHandlers = {
  onToggleWord(index: number): void;
  onBack(): void;
  onConfirm(): void;
  onClear(): void;
};

export class LanguageRepairConsole {
  static fromPuzzle(puzzle: GeneratedLanguagePuzzle): LanguageRepairModel {
    return {
      title: puzzle.title,
      corrupted: puzzle.corrupted,
      instruction: "Scegli la riscrittura corretta senza cambiare il significato. Poi premi Conferma risposta.",
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

  static addBrief(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: LanguageRepairModel,
    activeHint?: string,
  ): void {
    overlay.add(scene.add.rectangle(316, 397, 520, 330, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(scene.add.text(76, 246, "Come decidere", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(76, 274, model.diagnosticSteps.slice(0, 3).map((step, index) => `${index + 1}. ${step}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 6,
    }));
    overlay.add(scene.add.text(76, 410, "Obiettivo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(76, 438, model.repairGoal, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    if (activeHint) {
      overlay.add(scene.add.text(76, 494, "Indizio attivo", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
        fontStyle: "bold",
      }));
      overlay.add(scene.add.text(76, 516, activeHint, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        wordWrap: { width: 456, useAdvancedWrap: true },
      }));
    }
  }

  static addChoicePanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: LanguageRepairModel,
    state: LanguageChoicePanelState,
    handlers: LanguageChoicePanelHandlers,
  ): void {
    overlay.add(scene.add.text(614, 294, "Scegli la frase corretta", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    model.options.forEach((option, index) => {
      const y = 330 + index * 48;
      const selected = state.selectedOption === option;
      overlay.add(new Button(scene, 866, y, `${selected ? "✓ " : ""}${option}`, () => handlers.onSelect(option), {
        width: 540,
        height: 40,
        fontSize: 11,
        wordWrapWidth: 506,
        fill: selected ? 0x174d42 : 0x263743,
        stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });
    overlay.add(new Button(scene, 470, 620, "✍ Componi la frase", handlers.onOpenBuilder, {
      width: 240,
      height: 40,
      fontSize: 13,
      fill: 0x2a3550,
      stroke: 0x9f8cff,
    }));
    overlay.add(new Button(scene, 738, 620, "Conferma risposta", handlers.onConfirm, {
      width: 240,
      height: 40,
      fontSize: 13,
      fill: 0x173b36,
      stroke: 0xf7d37a,
    }));
    overlay.add(new Button(scene, 1002, 620, state.hintLabel, handlers.onHint, {
      width: 230,
      height: 40,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  static addBuilderPanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    state: LanguageBuilderPanelState,
    handlers: LanguageBuilderPanelHandlers,
  ): void {
    overlay.add(scene.add.text(614, 286, "Ricostruisci il messaggio corretto: tocca le parole nell'ordine giusto.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 600 },
    }));

    const assembled = state.placedIndices.map((index) => state.shuffledWords[index]).join(" ");
    overlay.add(scene.add.rectangle(614, 330, 624, 64, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
    overlay.add(scene.add.text(628, 344, assembled.length > 0 ? assembled : "(tocca le tessere qui sotto)", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
      wordWrap: { width: 596 },
      lineSpacing: 3,
    }));

    let tileX = 614;
    let tileY = 414;
    state.shuffledWords.forEach((word, index) => {
      const placed = state.placedIndices.includes(index);
      const tileWidth = Math.max(54, word.length * 11 + 24);
      if (tileX + tileWidth > 1238) {
        tileX = 614;
        tileY += 48;
      }
      overlay.add(new Button(scene, tileX + tileWidth / 2, tileY + 18, word, () => handlers.onToggleWord(index), {
        width: tileWidth,
        height: 36,
        fontSize: 13,
        fill: placed ? 0x174d42 : 0x263743,
        stroke: placed ? 0xf7d37a : 0x6be7d6,
      }));
      tileX += tileWidth + 10;
    });

    overlay.add(new Button(scene, 470, 640, "Torna a scelta", handlers.onBack, {
      width: 220,
      height: 40,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(scene, 738, 640, "Verifica frase", handlers.onConfirm, {
      width: 240,
      height: 40,
      fontSize: 13,
      fill: 0x173b36,
      stroke: 0xf7d37a,
    }));
    overlay.add(new Button(scene, 1002, 640, "Svuota", handlers.onClear, {
      width: 150,
      height: 40,
      fontSize: 13,
      fill: 0x3a2525,
      stroke: 0xf6c85f,
    }));
  }
}
