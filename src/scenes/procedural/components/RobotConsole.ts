import type Phaser from "phaser";
import type { GeneratedRobotPuzzle, GridCommand } from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";
import { commandLabels } from "../ProceduralMissionDefs";

export type RobotConsoleModel = {
  title: string;
  instructions: string[];
  expectedMinimumCommands: number;
  solutionCommands: GridCommand[];
  successConditions: string[];
  conceptTags: string[];
  buggedCommands?: GridCommand[];
  debugBrief?: string;
  routeBrief?: string;
  visualFocus?: string;
  coordinateLabels?: boolean;
  planningPrompt?: string;
};

export type RobotConsolePanel = { x: number; y: number; w: number; h: number };

export type RobotConsoleLayout = {
  mapPanel: RobotConsolePanel;
  programPanel: RobotConsolePanel;
  objectivePanel: RobotConsolePanel;
  commandPanel: RobotConsolePanel;
};

export type RobotGridRenderResult = {
  origin: { x: number; y: number };
  cellSize: number;
  robotSprite: Phaser.GameObjects.Triangle;
  keyMarker: Phaser.GameObjects.Star;
};

export type RobotCommandHandlers = {
  onCommand: (command: GridCommand) => void;
  onExecute: () => void;
  onClear: () => void;
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
      routeBrief: puzzle.routeBrief,
      visualFocus: puzzle.visualFocus,
      coordinateLabels: puzzle.coordinateLabels,
      planningPrompt: puzzle.planningPrompt,
    };
  }

  static layout(): RobotConsoleLayout {
    return {
      mapPanel: { x: 52, y: 94, w: 462, h: 358 },
      programPanel: { x: 536, y: 94, w: 286, h: 358 },
      objectivePanel: { x: 844, y: 94, w: 304, h: 358 },
      commandPanel: { x: 52, y: 472, w: 1096, h: 150 },
    };
  }

  static addPanels(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, layout: RobotConsoleLayout): void {
    const panels = [layout.mapPanel, layout.programPanel, layout.objectivePanel];
    for (const panel of panels) {
      overlay.add(scene.add.rectangle(panel.x, panel.y, panel.w, panel.h, 0x07151d, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    }
    const commandPanel = layout.commandPanel;
    overlay.add(scene.add.rectangle(commandPanel.x, commandPanel.y, commandPanel.w, commandPanel.h, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.28));
  }

  static addMapHeader(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    panel: RobotConsolePanel,
    model: RobotConsoleModel,
    cols: number,
    rows: number,
  ): void {
    overlay.add(scene.add.text(panel.x + 18, panel.y + 14, "Mappa robot", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(panel.x + 18, panel.y + 38, `Focus: ${model.visualFocus ?? "sequenza"} | Griglia ${cols}x${rows}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
    }));
  }

  static addMapLegend(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, panel: RobotConsolePanel, facingLabel: string): void {
    overlay.add(scene.add.text(panel.x + 18, panel.y + panel.h - 54, [
      `Robot: ${facingLabel}`,
      "Stella = chiave | quadrato = uscita | rosso = ostacolo | viola = checkpoint",
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9aaab0",
      wordWrap: { width: panel.w - 36 },
      lineSpacing: 2,
    }));
  }

  static addGrid(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    panel: RobotConsolePanel,
    model: RobotConsoleModel,
    puzzle: GeneratedRobotPuzzle,
    robotRotationFor: (facing: GeneratedRobotPuzzle["start"]["facing"]) => number,
  ): RobotGridRenderResult {
    const cellSize = Math.min(
      42,
      Math.floor((panel.w - 82) / puzzle.cols),
      Math.floor((panel.h - 168) / puzzle.rows),
    );
    const gridW = cellSize * puzzle.cols;
    const gridH = cellSize * puzzle.rows;
    const origin = {
      x: panel.x + Math.floor((panel.w - gridW) / 2) + cellSize / 2 + (model.coordinateLabels ? 10 : 0),
      y: panel.y + 104 + cellSize / 2,
    };
    const cellX = (col: number): number => origin.x + col * cellSize;
    const cellY = (row: number): number => origin.y + row * cellSize;

    if (model.coordinateLabels) {
      for (let col = 0; col < puzzle.cols; col += 1) {
        overlay.add(scene.add.text(cellX(col), origin.y - cellSize * 0.78, `${col}`, {
          fontFamily: "Inter, Arial",
          fontSize: "9px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5));
      }
      for (let row = 0; row < puzzle.rows; row += 1) {
        overlay.add(scene.add.text(origin.x - cellSize * 0.78, cellY(row), `${row}`, {
          fontFamily: "Inter, Arial",
          fontSize: "9px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5));
      }
    }

    for (let row = 0; row < puzzle.rows; row += 1) {
      for (let col = 0; col < puzzle.cols; col += 1) {
        const blocked = puzzle.obstacles.some((cell) => cell.col === col && cell.row === row);
        const cell = scene.add.rectangle(
          cellX(col),
          cellY(row),
          cellSize - 4,
          cellSize - 4,
          blocked ? 0x4c2b38 : 0x132835,
          1,
        ).setStrokeStyle(1, blocked ? 0xc94b55 : 0x315766, 0.7);
        overlay.add(cell);
        if (!blocked && (col + row) % 2 === 0) {
          overlay.add(scene.add.rectangle(cellX(col), cellY(row), cellSize - 14, 2, 0x6be7d6, 0.08));
        }
      }
    }

    [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order).forEach((checkpoint) => {
      overlay.add(scene.add.circle(cellX(checkpoint.col), cellY(checkpoint.row), Math.max(9, cellSize * 0.28), 0x8a7cff, 0.72).setStrokeStyle(2, 0xf5fbff, 0.58));
      overlay.add(scene.add.text(cellX(checkpoint.col), cellY(checkpoint.row), checkpoint.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
    });

    const robotSprite = scene.add.triangle(
      cellX(puzzle.start.col),
      cellY(puzzle.start.row),
      0,
      -16,
      14,
      14,
      -14,
      14,
      0x6be7d6,
      1,
    );
    robotSprite.setStrokeStyle(2, 0xf5fbff, 0.8).setRotation(robotRotationFor(puzzle.start.facing));
    const keyMarker = scene.add.star(cellX(puzzle.key.col), cellY(puzzle.key.row), 5, 7, 16, 0xf6c85f, 1);
    const exitMarker = scene.add.rectangle(cellX(puzzle.exit.col), cellY(puzzle.exit.row), 24, 24, 0x9ff5e9, 0.45);
    overlay.add(robotSprite);
    overlay.add(keyMarker);
    overlay.add(exitMarker);

    return { origin, cellSize, robotSprite, keyMarker };
  }

  static addProgramPanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    panel: RobotConsolePanel,
    model: RobotConsoleModel,
    commands: GridCommand[],
    commandLimit: number,
  ): Phaser.GameObjects.Text {
    overlay.add(scene.add.text(panel.x + 18, panel.y + 14, "Programma", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(panel.x + 18, panel.y + 38, `${commands.length}/${commandLimit} comandi`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: commands.length > commandLimit ? "#ff8a8a" : "#f7d37a",
    }));
    const visibleCommands = commands.length
      ? this.formatCommands(commands, 14)
      : "(buffer vuoto)\nAggiungi comandi dalla barra in basso.";
    overlay.add(scene.add.rectangle(panel.x + 18, panel.y + 66, panel.w - 36, 176, 0x0b1f2b, 0.84).setOrigin(0).setStrokeStyle(1, 0x315766, 0.55));
    overlay.add(scene.add.text(panel.x + 32, panel.y + 80, visibleCommands, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#d9eaf1",
      wordWrap: { width: panel.w - 64 },
      lineSpacing: 2,
    }));
    const debugLine = model.buggedCommands
      ? `Log guasto:\n${this.formatCommands(model.buggedCommands, 7)}`
      : "";
    const statusText = scene.add.text(panel.x + 18, panel.y + 258, debugLine || "Stato: pronto. Esegui solo quando il piano e completo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: debugLine ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: panel.w - 36 },
      lineSpacing: 3,
    });
    overlay.add(statusText);
    return statusText;
  }

  static addObjectivePanel(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, panel: RobotConsolePanel, model: RobotConsoleModel): void {
    overlay.add(scene.add.text(panel.x + 18, panel.y + 14, "Obiettivo", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(panel.x + 18, panel.y + 40, model.routeBrief ?? model.instructions[0] ?? "Costruisci una sequenza valida per chiave e uscita.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: panel.w - 36 },
      lineSpacing: 3,
    }));
    overlay.add(scene.add.text(panel.x + 18, panel.y + 132, `Metodo: ${model.planningPrompt ?? "Simula mentalmente prima di eseguire."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: panel.w - 36 },
      lineSpacing: 3,
    }));
    overlay.add(scene.add.text(panel.x + 18, panel.y + 214, `Condizioni:\n${model.successConditions.slice(0, 4).map((condition) => `- ${condition}`).join("\n")}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c9dce6",
      wordWrap: { width: panel.w - 36 },
      lineSpacing: 3,
    }));
    overlay.add(scene.add.text(panel.x + 18, panel.y + panel.h - 40, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9ff5e9",
      wordWrap: { width: panel.w - 36 },
    }));
  }

  static addCommandHeader(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, panel: RobotConsolePanel): void {
    overlay.add(scene.add.text(panel.x + 18, panel.y + 14, "Comandi", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(panel.x + 112, panel.y + 16, "Avanza muove nella direzione della punta. Gira cambia solo direzione. Raccogli ed Esci funzionano solo sulla casella corretta.", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9aaab0",
      wordWrap: { width: 680 },
    }));
  }

  static addCommandControls(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, panel: RobotConsolePanel, handlers: RobotCommandHandlers): void {
    this.addCommandHeader(scene, overlay, panel);
    (["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "PICK_UP", "EXIT"] satisfies GridCommand[]).forEach((command, index) => {
      overlay.add(new Button(scene, panel.x + 132 + index * 158, panel.y + 76, commandLabels[command], () => handlers.onCommand(command), {
        width: 136,
        height: 38,
        fontSize: 12,
      }));
    });
    overlay.add(new Button(scene, panel.x + panel.w - 116, panel.y + 50, "Esegui", handlers.onExecute, {
      width: 172,
      height: 38,
      fill: 0x173b36,
      fontSize: 12,
    }));
    overlay.add(new Button(scene, panel.x + panel.w - 116, panel.y + 102, "Pulisci", handlers.onClear, {
      width: 172,
      height: 38,
      fill: 0x263743,
      fontSize: 12,
    }));
  }

  static formatCommands(commands: GridCommand[], limit = commands.length): string {
    const visible = commands.slice(0, limit).map((command, index) => `${index + 1}. ${commandLabels[command]}`);
    const hidden = commands.length > limit ? `\n... +${commands.length - limit}` : "";
    return `${visible.join("\n")}${hidden}`;
  }
}
