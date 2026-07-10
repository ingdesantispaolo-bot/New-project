import type Phaser from "phaser";
import type { CircuitComponentChallenge, CircuitFaultType, GeneratedCircuitPuzzle } from "../../../procedural/ProceduralTypes";

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
  componentChallenges: CircuitComponentChallenge[];
};

export type CircuitSidePanelState = {
  conceptLocked: boolean;
  inspected: boolean;
  conceptIndex: number;
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
      componentChallenges: puzzle.componentChallenges ?? [],
    };
  }

  static addSidePanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: CircuitConsoleModel,
    state: CircuitSidePanelState,
  ): void {
    const x = 844;
    const y = 226;
    overlay.add(scene.add.rectangle(x, y, 302, 232, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(scene.add.text(x + 18, y + 16, state.conceptLocked ? "Prima guarda i pezzi" : state.inspected ? "Letture tester" : "Metodo in 3 passi", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    if (state.conceptLocked) {
      overlay.add(scene.add.text(x + 18, y + 48, "Non riparare ancora. Prima rispondi al pezzo cerchiato; poi passerai al giro completo della corrente.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: 266, useAdvancedWrap: true },
        lineSpacing: 5,
      }));
      model.componentChallenges.slice(0, 3).forEach((challenge, index) => {
        const rowY = y + 116 + index * 34;
        const done = index < state.conceptIndex;
        const active = index === state.conceptIndex;
        const status = done ? "fatto" : active ? "ora" : "dopo";
        const label = done ? challenge.componentLabel : active ? "Pezzo cerchiato" : `Pezzo ${index + 1}`;
        const color = done ? 0x66f2a0 : active ? 0xf6c85f : 0x5c7480;
        overlay.add(scene.add.circle(x + 28, rowY + 7, 9, color, active ? 0.22 : 0.14).setStrokeStyle(1, color, done || active ? 0.78 : 0.45));
        overlay.add(scene.add.text(x + 25, rowY, String(index + 1), {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: done ? "#66f2a0" : active ? "#f7d37a" : "#8aa1ad",
          fontStyle: "bold",
        }).setOrigin(0.5, 0));
        overlay.add(scene.add.text(x + 48, rowY - 2, `${status}: ${label}`, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: done || active ? "#c7dce7" : "#8aa1ad",
          wordWrap: { width: 226, useAdvancedWrap: true },
          lineSpacing: 2,
        }));
      });
      return;
    }

    if (!state.inspected) {
      overlay.add(scene.add.text(x + 18, y + 48, "Ora che conosci i pezzi, usa il tester per controllare il giro. Non scegliere riparazioni a caso.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: 266, useAdvancedWrap: true },
        lineSpacing: 5,
      }));
      model.diagnosticPlan.slice(0, 3).forEach((step, index) => {
        const rowY = y + 116 + index * 34;
        overlay.add(scene.add.circle(x + 28, rowY + 7, 9, 0xf6c85f, 0.18).setStrokeStyle(1, 0xf6c85f, 0.7));
        overlay.add(scene.add.text(x + 25, rowY, String(index + 1), {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5, 0));
        overlay.add(scene.add.text(x + 48, rowY - 2, step, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#c7dce7",
          wordWrap: { width: 226, useAdvancedWrap: true },
          lineSpacing: 2,
        }));
      });
      return;
    }

    const readingLabels: Record<NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]["reading"], string> = {
      continuita: "continuità",
      interrotto: "interrotto",
      "polarita-inversa": "polarità inversa",
      "non-stabile": "non stabile",
      corto: "corto",
      "tensione-bassa": "tensione bassa",
      "soglia-fuori-range": "soglia fuori range",
      "carica-bassa": "carica bassa",
    };
    model.testerReadings.slice(0, 4).forEach((reading, index) => {
      const rowY = y + 50 + index * 39;
      overlay.add(scene.add.rectangle(x + 18, rowY - 4, 266, 34, 0x102533, 0.7).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.14));
      overlay.add(scene.add.text(x + 30, rowY, `${reading.from} -> ${reading.to}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#f5fbff",
        fontStyle: "bold",
        wordWrap: { width: 130 },
      }));
      overlay.add(scene.add.text(x + 162, rowY, readingLabels[reading.reading], {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: reading.reading === "continuita" ? "#9ff5e9" : "#f7d37a",
        fontStyle: "bold",
      }));
      overlay.add(scene.add.text(x + 30, rowY + 15, reading.note, {
        fontFamily: "Inter, Arial",
        fontSize: "9px",
        color: "#9aaab0",
        wordWrap: { width: 242 },
      }));
    });

    const guide = model.componentGuide.slice(0, 2).map((component) => `${component.label}: ${component.check}`).join("\n");
    overlay.add(scene.add.text(x + 18, y + 206, guide, {
      fontFamily: "Inter, Arial",
      fontSize: "9px",
      color: "#9aaab0",
      wordWrap: { width: 266 },
      lineSpacing: 2,
    }));
  }
}
