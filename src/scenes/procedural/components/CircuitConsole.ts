import type Phaser from "phaser";
import type {
  CircuitComponentChallenge,
  CircuitFaultType,
  CircuitMinigamePrompt,
  CircuitMinigameVisual,
  GeneratedCircuitPuzzle,
} from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";
import { SceneChrome } from "../../../ui/SceneChrome";
import {
  drawBatterySymbol,
  drawBranchSymbol,
  drawCapacitorSymbol,
  drawCurrentArrows,
  drawGroundSymbol,
  drawLedSymbol,
  drawMotorSymbol,
  drawRelaySymbol,
  drawResistorSymbol,
  drawReturnSymbol,
  drawSensorSymbol,
  drawSwitchSymbol,
} from "../CircuitSymbols";
import { repairLabels } from "../ProceduralMissionDefs";

export type CircuitConsoleModel = {
  title: string;
  symptom: string;
  nodes: string[];
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

export type CircuitIntroState = {
  conceptLocked: boolean;
  showCoach?: boolean;
};

export type CircuitComponentChallengeState = {
  conceptIndex: number;
  total: number;
  selectedAnswer?: string;
};

export type CircuitComponentChallengeHandlers = {
  onSelect(choice: string): void;
  onConfirm(challenge: CircuitComponentChallenge): void;
};

export type CircuitDiagnosticState = {
  activeFaults: Set<CircuitFaultType>;
  conceptLocked: boolean;
  lit: boolean;
  targetComponentId?: string;
};

export type CircuitRepairPanelState = {
  selectedRepairs: Set<CircuitFaultType>;
};

export type CircuitRepairPanelHandlers = {
  onToggleRepair(fault: CircuitFaultType): void;
  onTestCircuit(): void;
};

export type CircuitTesterPromptHandlers = {
  onInspect(): void;
};

export type CircuitMinigamePromptState = {
  showCoach: boolean;
  selectedIds: Set<string>;
  remainingLabel: string;
  remainingDanger: boolean;
  streak: number;
  netScore: number;
  accuracy: number;
  feedback: string;
  scoringRule: string;
};

export type CircuitMinigamePromptHandlers = {
  onToggleTile(tileId: string): void;
  onConfirm(): void;
  onHint(): void;
};

export type CircuitMinigameSummaryState = {
  passed: boolean;
  correct: number;
  wrong: number;
  accuracy: number;
  bestStreak: number;
  netScore: number;
  feedback: string;
  resolutionText: string;
  energyText?: string;
  actionLabel: string;
};

export type CircuitMinigameSummaryHandlers = {
  onAction(modal: Phaser.GameObjects.Container): void;
};

export class CircuitConsole {
  static fromPuzzle(puzzle: GeneratedCircuitPuzzle): CircuitConsoleModel {
    return {
      title: puzzle.title,
      symptom: puzzle.symptom,
      nodes: puzzle.nodes,
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
      difficultyLabel: puzzle.difficultyLabel ?? "Profondità 1 - diagnosi guidata",
      conceptTags: puzzle.conceptTags ?? ["circuito chiuso", "tester"],
      explanations: puzzle.explanationByFault ?? {},
      componentChallenges: puzzle.componentChallenges ?? [],
    };
  }

  static addIntro(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: CircuitConsoleModel,
    state: CircuitIntroState,
  ): void {
    const showCoach = state.showCoach ?? true;
    const learningText = !showCoach
      ? `Domanda guida: ${model.diagnosticQuestion}`
      : state.conceptLocked
      ? `${model.learningPurpose} Ora impara un pezzo alla volta. Obiettivo finale: trovare dove si ferma il giro della corrente.`
      : `${model.learningPurpose} Domanda guida: ${model.diagnosticQuestion}`;

    overlay.add(scene.add.text(48, 72, model.difficultyLabel.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(48, 100, model.symptom, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f7d37a",
      wordWrap: { width: 800 },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.rectangle(48, 132, 800, 76, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(scene.add.text(66, 146, showCoach ? "Cosa impari" : "Obiettivo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(66, 170, learningText, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 764, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.rectangle(868, 132, 278, 76, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.18));
    overlay.add(scene.add.text(886, 146, "Parole chiave", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(886, 170, model.conceptTags.slice(0, 5).join("  |  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 242, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
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

  static addDiagnostic(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: CircuitConsoleModel,
    state: CircuitDiagnosticState,
  ): void {
    const wireColor = state.lit ? 0x6be7d6 : 0x425865;
    const y = 306;
    const bottomY = 396;
    const positions = {
      battery: 94,
      switch: 226,
      resistor: 370,
      led: 522,
      return: 668,
    };
    const componentCenters: Record<string, { x: number; y: number }> = {
      battery: { x: positions.battery, y },
      switch: { x: positions.switch, y },
      resistor: { x: positions.resistor, y },
      led: { x: positions.led, y },
      return: { x: positions.return, y },
      capacitor: { x: 226, y: 424 },
      sensor: { x: 590, y: 424 },
      branchLed: { x: 404, y: 424 },
      relay: { x: 190, y: 426 },
      motor: { x: 350, y: 426 },
      ground: { x: 590, y: 426 },
    };

    overlay.add(scene.add.rectangle(48, 226, 776, 232, 0x081823, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.26));
    overlay.add(scene.add.text(66, 242, state.conceptLocked ? "Prima osservazione: guarda il pezzo cerchiato" : "Segui il giro: dal + della batteria fino al -", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    const path = scene.add.graphics();
    path.lineStyle(5, wireColor, state.lit ? 0.9 : 0.45);
    path.beginPath();
    path.moveTo(positions.battery + 24, y);
    path.lineTo(positions.switch - 38, y);
    path.moveTo(positions.switch + 42, y);
    path.lineTo(positions.resistor - 48, y);
    path.moveTo(positions.resistor + 52, y);
    path.lineTo(positions.led - 46, y);
    path.moveTo(positions.led + 46, y);
    path.lineTo(positions.return - 36, y);
    path.moveTo(positions.return + 28, y);
    path.lineTo(positions.return + 28, bottomY);
    path.lineTo(positions.battery - 28, bottomY);
    path.lineTo(positions.battery - 28, y);
    path.strokePath();
    overlay.add(path);

    if (state.activeFaults.has("missing-wire")) {
      const broken = scene.add.graphics();
      broken.lineStyle(6, 0xffb36b, 0.9);
      broken.beginPath();
      broken.moveTo(positions.led + 58, y);
      broken.lineTo(positions.return - 46, y);
      broken.strokePath();
      broken.lineStyle(2, 0x07151d, 1);
      broken.beginPath();
      broken.moveTo(positions.return - 88, y - 16);
      broken.lineTo(positions.return - 70, y + 16);
      broken.moveTo(positions.return - 68, y - 16);
      broken.lineTo(positions.return - 50, y + 16);
      broken.strokePath();
      overlay.add(broken);
    }

    drawBatterySymbol(scene, overlay, positions.battery, y, 0xf6c85f);
    drawSwitchSymbol(scene, overlay, positions.switch, y, state.activeFaults.has("open-switch") ? 0xffb36b : 0x9ff5e9, !state.activeFaults.has("open-switch"), !state.conceptLocked);
    drawResistorSymbol(scene, overlay, positions.resistor, y, state.activeFaults.has("missing-resistor") || state.activeFaults.has("wrong-resistor-value") ? 0xffb36b : 0x9ff5e9, state.activeFaults.has("missing-resistor"), !state.conceptLocked);
    drawLedSymbol(scene, overlay, positions.led, y, state.activeFaults.has("reversed-led") ? 0xffb36b : 0x9ff5e9, state.activeFaults.has("reversed-led"), state.lit, !state.conceptLocked);
    drawReturnSymbol(scene, overlay, positions.return, y, state.activeFaults.has("missing-wire") || state.activeFaults.has("loose-ground") || state.activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9);

    [
      { id: "battery", x: positions.battery, label: "1 Batteria", text: "dà la spinta" },
      { id: "switch", x: positions.switch, label: "2 Interruttore", text: "apre o chiude" },
      { id: "resistor", x: positions.resistor, label: "3 Resistenza", text: "protegge il LED" },
      { id: "led", x: positions.led, label: "4 LED", text: "fa luce" },
      { id: "return", x: positions.return, label: "5 Ritorno", text: "torna al -" },
    ].forEach((item, index) => {
      const target = state.conceptLocked && item.id === state.targetComponentId;
      overlay.add(scene.add.text(item.x, 346, state.conceptLocked ? (target ? "Guarda qui" : `Pezzo ${index + 1}`) : item.label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      if (state.conceptLocked) {
        overlay.add(scene.add.text(item.x, 370, target ? "scegli il nome" : "più tardi", {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: target ? "#f7d37a" : "#9aaab0",
          align: "center",
        }).setOrigin(0.5, 0));
      } else {
        overlay.add(scene.add.text(item.x, 364, item.text, {
          fontFamily: "Inter, Arial",
          fontSize: "9px",
          color: "#9aaab0",
          align: "center",
          wordWrap: { width: 92 },
        }).setOrigin(0.5, 0));
      }
    });

    drawCurrentArrows(scene, overlay, state.lit ? 0x8cffd7 : 0x5c7480, state.lit ? 0.85 : 0.35, [
      { x: 160, y, rotation: 0 },
      { x: 450, y, rotation: 0 },
      { x: 696, y: 346, rotation: Math.PI / 2 },
      { x: 330, y: bottomY, rotation: Math.PI },
    ]);

    if (model.nodes.includes("capacitor")) {
      drawCapacitorSymbol(scene, overlay, 226, 424, state.activeFaults.has("capacitor-discharged") ? 0xffb36b : 0x9ff5e9, !state.conceptLocked);
    }
    if (model.nodes.includes("sensor")) {
      drawSensorSymbol(scene, overlay, 590, 424, state.activeFaults.has("sensor-unpowered") || state.activeFaults.has("disconnected-component") ? 0xffb36b : 0x9ff5e9, !state.conceptLocked);
    }
    if (model.nodes.includes("branchLed")) {
      drawBranchSymbol(scene, overlay, 404, 424, state.activeFaults.has("parallel-branch-open") ? 0xffb36b : 0x9ff5e9, !state.conceptLocked);
    }
    if (model.nodes.includes("relay")) {
      drawRelaySymbol(scene, overlay, 190, 426, state.activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9, !state.conceptLocked);
    }
    if (model.nodes.includes("motor")) {
      drawMotorSymbol(scene, overlay, 350, 426, state.activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9, !state.conceptLocked);
    }
    if (model.nodes.includes("ground")) {
      drawGroundSymbol(scene, overlay, 590, 426, state.activeFaults.has("loose-ground") || state.activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9, !state.conceptLocked);
    }

    if (state.conceptLocked && state.targetComponentId && componentCenters[state.targetComponentId]) {
      const center = componentCenters[state.targetComponentId];
      overlay.add(scene.add.circle(center.x, center.y, 54, 0xf6c85f, 0.08).setStrokeStyle(3, 0xf6c85f, 0.88));
      overlay.add(scene.add.text(center.x, center.y - 70, "guarda qui", {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#f7d37a",
        fontStyle: "bold",
      }).setOrigin(0.5));
    }
  }

  static addRepairPanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: CircuitConsoleModel,
    state: CircuitRepairPanelState,
    handlers: CircuitRepairPanelHandlers,
  ): void {
    overlay.add(scene.add.rectangle(452, 488, 816, 46, 0x07151d, 0.74).setStrokeStyle(1, 0xf6c85f, 0.2));
    overlay.add(scene.add.text(64, 474, "Interventi disponibili", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(64, 496, "Scegli solo la riparazione che il tester ha dimostrato. Se aggiungi pezzi a caso, il circuito non è davvero capito.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 760 },
    }));

    model.repairChoices.forEach((fault, index) => {
      const selected = state.selectedRepairs.has(fault);
      const col = index % 4;
      const row = Math.floor(index / 4);
      overlay.add(new Button(scene, 142 + col * 200, 548 + row * 44, `${selected ? "[x] " : ""}${repairLabels[fault]}`, () => handlers.onToggleRepair(fault), {
        width: 176,
        height: 38,
        fontSize: 11,
        fill: selected ? 0x173b36 : 0x142736,
      }));
    });

    overlay.add(new Button(scene, 1010, 604, "Testa circuito", handlers.onTestCircuit, {
      width: 250,
      height: 52,
      fill: 0x173b36,
    }));
  }

  static addTesterPrompt(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    handlers: CircuitTesterPromptHandlers,
  ): void {
    overlay.add(new Button(scene, 1010, 588, "Usa tester", handlers.onInspect, {
      width: 250,
      height: 52,
      fill: 0x173b36,
    }));
  }

  static addMinigamePrompt(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    prompt: CircuitMinigamePrompt,
    state: CircuitMinigamePromptState,
    handlers: CircuitMinigamePromptHandlers,
  ): Phaser.GameObjects.Text {
    this.addPanel(scene, overlay, 28, 112, 560, 432, state.showCoach ? "1 · Leggi lo schema" : "Schema");
    overlay.add(scene.add.text(60, 154, prompt.title, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.rectangle(60, 200, 500, 196, 0x07151d, 0.85).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.3));
    if (prompt.visual) {
      this.addMinigameSchematic(scene, overlay, prompt.visual, prompt.diagramLines);
    } else {
      overlay.add(scene.add.text(80, 218, prompt.diagramLines.join("\n"), {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#9ff5e9",
        lineSpacing: 8,
        wordWrap: { width: 460 },
      }));
    }
    overlay.add(scene.add.text(60, 470, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 500 },
    }));
    if (state.showCoach) {
      overlay.add(scene.add.text(60, 498, this.minigameMethodText(prompt), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 506, useAdvancedWrap: true },
        lineSpacing: 3,
      }));
    }

    this.addPanel(scene, overlay, 616, 112, 636, 432, state.showCoach ? "2 · Scegli la risposta" : "Scelte");
    if (state.showCoach) {
      overlay.add(scene.add.text(648, 154, "Come si gioca: leggi lo schema, clicca UNA risposta e premi Conferma.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#d9eaf1",
        wordWrap: { width: 548 },
        lineSpacing: 4,
      }));
    }
    overlay.add(scene.add.text(648, state.showCoach ? 210 : 164, prompt.question, {
      fontFamily: "Inter, Arial",
      fontSize: prompt.question.length > 92 ? "16px" : "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 548, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    const tileStartX = 802;
    const tileStartY = 320;
    prompt.tiles.forEach((tile, index) => {
      const selected = state.selectedIds.has(tile.id);
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(new Button(scene, tileStartX + col * 244, tileStartY + row * 70, `${selected ? "✓ " : ""}${tile.label}`, () => handlers.onToggleTile(tile.id), {
        width: 226,
        height: 54,
        fontSize: tile.label.length > 26 ? 11 : tile.label.length > 16 ? 13 : 16,
        wordWrapWidth: 204,
        fill: selected ? 0x174d42 : 0x263743,
        stroke: selected ? 0xf7d37a : 0x6be7d6,
      }));
    });

    this.addPanel(scene, overlay, 28, 558, 1224, 130, state.showCoach ? "3 · Conferma e controlla l'esito" : "Esito");
    const timerText = scene.add.text(64, 604, `Tempo: ${state.remainingLabel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: state.remainingDanger ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(timerText);
    overlay.add(scene.add.text(260, 592, `Serie: ${state.streak}    ·    Punti: ${state.netScore}    ·    Precisione: ${state.accuracy}%`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 640 },
      lineSpacing: 4,
    }));
    if (state.showCoach || state.feedback) {
      overlay.add(scene.add.text(260, 636, state.feedback || state.scoringRule, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: state.feedback ? "#f7d37a" : "#9aaab0",
        wordWrap: { width: 390, useAdvancedWrap: true },
      }));
    }
    overlay.add(new Button(scene, 1080, 640, "Conferma", handlers.onConfirm, {
      width: 220,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(scene, 820, 640, "Indizio", handlers.onHint, {
      width: 180,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    return timerText;
  }

  static addMinigameSummary(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    state: CircuitMinigameSummaryState,
    handlers: CircuitMinigameSummaryHandlers,
  ): Phaser.GameObjects.Container {
    const modal = scene.add.container(0, 0).setDepth(1300);
    SceneChrome.modalInputBlocker(scene, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(scene.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(scene.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, state.passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(scene.add.text(230, 160, state.passed ? "Sprint circuiti completato" : "Sprint circuiti da consolidare", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: state.passed ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(scene.add.text(230, 210, [
      `Risposte corrette: ${state.correct}`,
      `Errori: ${state.wrong}`,
      `Precisione: ${state.accuracy}%`,
      `Serie migliore: ${state.bestStreak}`,
      `Punti sprint: ${state.netScore}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      lineSpacing: 7,
    }));
    modal.add(scene.add.rectangle(548, 212, 408, 128, 0x102533, 0.78).setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(scene.add.text(572, 234, state.feedback, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 354 },
      lineSpacing: 5,
    }));
    modal.add(scene.add.rectangle(230, 378, 740, 74, 0x0b1e2a, 0.82).setOrigin(0)
      .setStrokeStyle(1, 0xf7d37a, 0.36));
    modal.add(scene.add.text(254, 394, state.resolutionText, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    if (state.energyText) {
      modal.add(scene.add.text(254, 456, state.energyText, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: 690 },
      }));
    }
    modal.add(new Button(scene, 612, 506, state.actionLabel, () => handlers.onAction(modal), {
      width: 270,
      height: 54,
      fill: state.passed ? 0x173b36 : 0x263743,
      stroke: state.passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
    return modal;
  }

  static addMinigameSchematic(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    visual: CircuitMinigameVisual,
    captionLines: string[],
    energized = false,
  ): void {
    if (visual.kind === "component") {
      overlay.add(scene.add.text(80, 214, "Osserva il simbolo:", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#9aaab0",
      }));
      const cx = 310;
      const cy = 312;
      const color = 0x9ff5e9;
      switch (visual.component) {
        case "battery": drawBatterySymbol(scene, overlay, cx, cy, 0xf6c85f); break;
        case "switch": drawSwitchSymbol(scene, overlay, cx, cy, color, true, false); break;
        case "resistor": drawResistorSymbol(scene, overlay, cx, cy, color, false, false); break;
        case "led": drawLedSymbol(scene, overlay, cx, cy, color, false, false, false); break;
        case "capacitor": drawCapacitorSymbol(scene, overlay, cx, cy, color, false); break;
        case "sensor": drawSensorSymbol(scene, overlay, cx, cy, color, false); break;
        case "relay": drawRelaySymbol(scene, overlay, cx, cy, color, false); break;
        case "motor": drawMotorSymbol(scene, overlay, cx, cy, color, false); break;
        case "ground": drawGroundSymbol(scene, overlay, cx, cy, color, false); break;
        default: break;
      }
      return;
    }

    const y = 296;
    const wire = scene.add.graphics();
    wire.lineStyle(3, 0x6be7d6, 0.5);
    wire.lineBetween(78, y, 542, y);
    overlay.add(wire);
    drawBatterySymbol(scene, overlay, 116, y, 0xf6c85f);
    drawSwitchSymbol(scene, overlay, 212, y, visual.switchClosed ? 0x9ff5e9 : 0xffb36b, visual.switchClosed, false);
    drawResistorSymbol(scene, overlay, 312, y, visual.hasResistor ? 0x9ff5e9 : 0xffb36b, !visual.hasResistor, false);
    // The LED glow is the outcome to predict, so it is revealed only after confirm.
    drawLedSymbol(scene, overlay, 402, y, visual.ledForward ? 0x9ff5e9 : 0xffb36b, !visual.ledForward, energized && visual.lit, false);
    drawReturnSymbol(scene, overlay, 520, y, 0x9ff5e9);
    if (visual.hasOpen) {
      const gap = scene.add.graphics();
      gap.lineStyle(4, 0xff6b6b, 0.95);
      gap.lineBetween(455, y - 14, 475, y + 14);
      gap.lineBetween(475, y - 14, 455, y + 14);
      overlay.add(gap);
    }
    overlay.add(scene.add.text(80, 360, captionLines.join("  ·  "), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 460 },
      lineSpacing: 3,
    }));
    if (!energized) {
      overlay.add(scene.add.text(80, 386, "Conferma per alimentare il circuito e vedere cosa fa il LED.", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f7d37a",
      }));
    }
  }

  static addComponentChallenge(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    challenge: CircuitComponentChallenge,
    state: CircuitComponentChallengeState,
    handlers: CircuitComponentChallengeHandlers,
  ): void {
    const visualHint = this.componentVisualHint(challenge);
    overlay.add(scene.add.rectangle(452, 488, 816, 46, 0x07151d, 0.74).setStrokeStyle(1, 0xf6c85f, 0.2));
    overlay.add(scene.add.text(64, 474, `Impara i pezzi ${state.conceptIndex + 1}/${state.total}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(64, 496, "Guarda solo il pezzo cerchiato. Scegli il suo nome, poi il gioco ti spiega a cosa serve.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 760 },
    }));

    overlay.add(scene.add.rectangle(330, 606, 532, 184, 0x07151d, 0.9).setStrokeStyle(1, 0x6be7d6, 0.26));
    overlay.add(scene.add.text(88, 526, "Una sola domanda", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(88, 546, challenge.symbolQuestion, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 480 },
    }));
    challenge.symbolChoices.forEach((choice, index) => {
      const selected = state.selectedAnswer === choice;
      overlay.add(new Button(scene, 330, 588 + index * 42, choice, () => handlers.onSelect(choice), {
        width: 470,
        height: 36,
        fontSize: 10,
        fill: selected ? 0x173b36 : 0x142736,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
      }));
    });

    overlay.add(scene.add.rectangle(800, 606, 324, 184, 0x07151d, 0.82).setStrokeStyle(1, 0xf6c85f, 0.22));
    overlay.add(scene.add.text(656, 526, "Indizio visivo", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(656, 552, visualHint, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#d9eaf1",
      wordWrap: { width: 288, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.text(656, 644, "Dopo la risposta vedrai il lavoro del pezzo nel circuito.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 268 },
    }));

    overlay.add(new Button(scene, 1058, 616, "Conferma", () => handlers.onConfirm(challenge), {
      width: 206,
      height: 48,
      fontSize: 13,
      fill: 0x173b36,
    }));
  }

  private static componentVisualHint(challenge: CircuitComponentChallenge): string {
    const hint = challenge.visualHint.trim();
    return hint ? `Cerca questa forma: ${hint}.` : "Guarda la forma del simbolo cerchiato e confrontala con le tre risposte.";
  }

  private static minigameMethodText(prompt: CircuitMinigamePrompt): string {
    switch (prompt.type) {
      case "component-id":
        return "Metodo: guarda simbolo e funzione. Non scegliere dal nome piu' familiare: scegli il pezzo che farebbe quel lavoro nel circuito.";
      case "predict-led":
        return "Metodo: segui corrente, interruttore, resistenza e verso del LED. Se il percorso e' aperto o il LED e' girato, non si accende.";
      case "ohms-law":
        return "Metodo: applica V = I x R. Prima identifica le unita', poi calcola il valore mancante.";
      case "series-parallel":
        return "Metodo: in serie la corrente ha un solo percorso; in parallelo i rami condividono la tensione e le correnti si dividono.";
      default:
        return "Metodo: leggi lo schema, elimina le risposte impossibili e scegli l'effetto coerente.";
    }
  }

  private static addPanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    height: number,
    title: string,
  ): void {
    overlay.add(scene.add.rectangle(x, y, width, height, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(scene.add.text(x + 18, y + 14, title, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
  }
}
