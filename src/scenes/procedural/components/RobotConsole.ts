import type Phaser from "phaser";
import type { GeneratedRobotPuzzle, GridCommand, GridFacing } from "../../../procedural/ProceduralTypes";
import { settingsSystem } from "../../../core/SettingsSystem";
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

export type RobotSprite = Phaser.GameObjects.Container;

export type RobotGridRenderResult = {
  origin: { x: number; y: number };
  cellSize: number;
  robotSprite: RobotSprite;
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
    const addGridTile = (frame: string, x: number, y: number, fallback: () => Phaser.GameObjects.GameObject): void => {
      if (scene.textures.exists("robot-grid") && scene.textures.getFrame("robot-grid", frame)) {
        overlay.add(scene.add.image(x, y, "robot-grid", frame).setDisplaySize(cellSize - 4, cellSize - 4));
        return;
      }
      overlay.add(fallback());
    };

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
        addGridTile(blocked ? "grid-obstacle" : "grid-cell", cellX(col), cellY(row), () => scene.add.rectangle(
          cellX(col),
          cellY(row),
          cellSize - 4,
          cellSize - 4,
          blocked ? 0x4c2b38 : 0x132835,
          1,
        ).setStrokeStyle(1, blocked ? 0xc94b55 : 0x315766, 0.7));
        if (!blocked && (col + row) % 2 === 0) {
          overlay.add(scene.add.rectangle(cellX(col), cellY(row), cellSize - 14, 2, 0x6be7d6, 0.08));
        }
        if (blocked && !scene.textures.exists("robot-grid")) {
          overlay.add(scene.add.rectangle(cellX(col), cellY(row), cellSize - 12, 3, 0xff8a8a, 0.32).setRotation(-Math.PI / 4));
          overlay.add(scene.add.rectangle(cellX(col), cellY(row), cellSize - 12, 3, 0xff8a8a, 0.24).setRotation(Math.PI / 4));
        }
      }
    }

    addGridTile("grid-start", cellX(puzzle.start.col), cellY(puzzle.start.row), () => scene.add.circle(cellX(puzzle.start.col), cellY(puzzle.start.row), Math.max(13, cellSize * 0.36), 0x6be7d6, 0.12).setStrokeStyle(1, 0x6be7d6, 0.42));
    addGridTile("grid-exit", cellX(puzzle.exit.col), cellY(puzzle.exit.row), () => scene.add.rectangle(cellX(puzzle.exit.col), cellY(puzzle.exit.row), Math.max(20, cellSize * 0.6), Math.max(20, cellSize * 0.6), 0x9ff5e9, 0.32).setStrokeStyle(2, 0x9ff5e9, 0.72));
    overlay.add(scene.add.text(cellX(puzzle.exit.col), cellY(puzzle.exit.row), "E", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));

    [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order).forEach((checkpoint) => {
      addGridTile(checkpoint.label.startsWith("S") ? "grid-sensor" : "grid-checkpoint", cellX(checkpoint.col), cellY(checkpoint.row), () => scene.add.circle(cellX(checkpoint.col), cellY(checkpoint.row), Math.max(9, cellSize * 0.28), 0x8a7cff, 0.72).setStrokeStyle(2, 0xf5fbff, 0.58));
      overlay.add(scene.add.text(cellX(checkpoint.col), cellY(checkpoint.row), checkpoint.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
    });

    if (scene.textures.exists("robot-grid") && scene.textures.getFrame("robot-grid", "grid-key")) {
      overlay.add(scene.add.image(cellX(puzzle.key.col), cellY(puzzle.key.row), "robot-grid", "grid-key").setDisplaySize(cellSize - 4, cellSize - 4));
    }
    const keyMarker = scene.add.star(cellX(puzzle.key.col), cellY(puzzle.key.row), 5, 7, 16, 0xf6c85f, scene.textures.exists("robot-grid") ? 0 : 1);
    overlay.add(keyMarker);
    const robotSprite = this.createRobotSprite(scene, cellX(puzzle.start.col), cellY(puzzle.start.row), cellSize, puzzle.start.facing);
    overlay.add(robotSprite);

    return { origin, cellSize, robotSprite, keyMarker };
  }

  static createRobotSprite(
    scene: Phaser.Scene,
    x: number,
    y: number,
    cellSize: number,
    facing: GridFacing,
  ): RobotSprite {
    const robot = scene.add.container(x, y);
    robot.setSize(cellSize, cellSize);
    robot.add(scene.add.ellipse(0, cellSize * 0.3, cellSize * 0.72, cellSize * 0.18, 0x000000, 0.34));
    if (scene.textures.exists("soft-glow")) {
      robot.add(scene.add.image(0, 0, "soft-glow").setTint(0x6be7d6).setAlpha(0.16).setScale(cellSize / 36));
    }
    if (scene.textures.exists("eli-robot-girl")) {
      const body = scene.add.sprite(0, -cellSize * 0.04, "eli-robot-girl", this.facingFrame(facing))
        .setName("robot-body")
        .setOrigin(0.5, 0.58)
        .setScale(Math.min(0.46, (cellSize - 4) / 96));
      robot.add(body);
    } else {
      const body = scene.add.rectangle(0, 2, cellSize * 0.48, cellSize * 0.46, 0x17475a, 1).setStrokeStyle(2, 0x9ff5e9, 0.9);
      const head = scene.add.rectangle(0, -cellSize * 0.22, cellSize * 0.42, cellSize * 0.24, 0x1d5a6f, 1).setStrokeStyle(2, 0x9ff5e9, 0.86);
      const eye = scene.add.circle(cellSize * 0.08, -cellSize * 0.22, Math.max(2, cellSize * 0.06), 0x9ff5e9, 1);
      robot.add([body, head, eye]);
    }
    const heading = scene.add.triangle(0, -cellSize * 0.44, 0, -5, 5, 5, -5, 5, 0x6be7d6, 0.96)
      .setName("heading-indicator")
      .setStrokeStyle(1, 0xf5fbff, 0.7);
    robot.add(heading);
    this.setRobotFacing(robot, facing);
    return robot;
  }

  static setRobotFacing(robotSprite: RobotSprite | undefined, facing: GridFacing): void {
    if (!robotSprite?.active) {
      return;
    }
    const body = robotSprite.getByName("robot-body") as Phaser.GameObjects.Sprite | null;
    body?.setFrame(this.facingFrame(facing));
    const heading = robotSprite.getByName("heading-indicator") as Phaser.GameObjects.Triangle | null;
    heading?.setRotation(this.rotationFor(facing));
  }

  private static facingFrame(facing: GridFacing): string {
    return {
      N: "up_idle",
      E: "right_idle",
      S: "down_idle",
      W: "left_idle",
    }[facing];
  }

  static facingLabel(facing: GridFacing): string {
    return {
      N: "punta verso nord",
      E: "punta verso est",
      S: "punta verso sud",
      W: "punta verso ovest",
    }[facing];
  }

  static rotationFor(facing: GridFacing): number {
    return {
      N: 0,
      E: Math.PI / 2,
      S: Math.PI,
      W: -Math.PI / 2,
    }[facing];
  }

  static turn(facing: GridFacing, direction: "L" | "R"): GridFacing {
    const order: GridFacing[] = ["N", "E", "S", "W"];
    const offset = direction === "R" ? 1 : -1;
    return order[(order.indexOf(facing) + offset + order.length) % order.length];
  }

  static cellX(origin: { x: number }, cellSize: number, col: number): number {
    return origin.x + col * cellSize;
  }

  static cellY(origin: { y: number }, cellSize: number, row: number): number {
    return origin.y + row * cellSize;
  }

  static addTrail(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, robotSprite: RobotSprite): void {
    if (settingsSystem.effectsReduced()) {
      return;
    }
    const trail = scene.add.image(robotSprite.x, robotSprite.y, "soft-glow")
      .setTint(0x6be7d6)
      .setAlpha(0.4)
      .setScale(0.7);
    overlay.add(trail);
    scene.tweens.add({
      targets: trail,
      alpha: 0,
      scale: 0.3,
      duration: 320,
      ease: "Sine.easeOut",
      onComplete: () => trail.destroy(),
    });
  }

  static flashCell(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container | undefined,
    origin: { x: number; y: number },
    cellSize: number,
    puzzle: Pick<GeneratedRobotPuzzle, "cols" | "rows">,
    col: number,
    row: number,
    color: number,
  ): void {
    const safeCol = Math.max(0, Math.min(puzzle.cols - 1, col));
    const safeRow = Math.max(0, Math.min(puzzle.rows - 1, row));
    const flash = scene.add.rectangle(
      RobotConsole.cellX(origin, cellSize, safeCol),
      RobotConsole.cellY(origin, cellSize, safeRow),
      cellSize - 6,
      cellSize - 6,
      color,
      0.32,
    );
    overlay?.add(flash);
    scene.tweens.add({
      targets: flash,
      alpha: 0,
      scale: 1.2,
      duration: 520,
      onComplete: () => flash.destroy(),
    });
  }

  static shakeSprite(scene: Phaser.Scene, robotSprite: RobotSprite | undefined): void {
    if (!robotSprite) {
      return;
    }
    const startX = robotSprite.x;
    scene.tweens.add({
      targets: robotSprite,
      x: { from: startX - 8, to: startX + 8 },
      duration: 45,
      yoyo: true,
      repeat: 4,
      onComplete: () => {
        robotSprite.setX(startX);
      },
    });
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

  static addObjectivePanel(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, panel: RobotConsolePanel, model: RobotConsoleModel, showCoach = true): void {
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
    if (showCoach) {
      overlay.add(scene.add.text(panel.x + 18, panel.y + 132, `Metodo: ${model.planningPrompt ?? "Simula mentalmente prima di eseguire."}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f7d37a",
        wordWrap: { width: panel.w - 36 },
        lineSpacing: 3,
      }));
    }
    overlay.add(scene.add.text(panel.x + 18, panel.y + (showCoach ? 214 : 132), `Condizioni:\n${model.successConditions.slice(0, 4).map((condition) => `- ${condition}`).join("\n")}`, {
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
