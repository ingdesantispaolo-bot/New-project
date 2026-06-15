import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { exerciseVariantSystem } from "../core/ExerciseVariantSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { inventorySystem } from "../core/InventorySystem";
import { mistakeAnalyzer } from "../core/MistakeAnalyzer";
import { missionEngine } from "../core/MissionEngine";
import type { RobotCommand, RobotPuzzleDefinition } from "../types/puzzleTypes";
import { Button } from "../ui/Button";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type Facing = "N" | "E" | "S" | "W";

const commandLabels: Record<RobotCommand, string> = {
  MOVE_FORWARD: "MOVE_FORWARD",
  TURN_LEFT: "TURN_LEFT",
  TURN_RIGHT: "TURN_RIGHT",
  PICK_UP: "PICK_UP",
};

export class RobotCodingScene extends Phaser.Scene {
  private robotPuzzle: RobotPuzzleDefinition = exerciseVariantSystem.getRobotPuzzle();
  private commands: RobotCommand[] = [];
  private commandText?: Phaser.GameObjects.Text;
  private statusText?: Phaser.GameObjects.Text;
  private robotSprite?: Phaser.GameObjects.Triangle;
  private robotGlow?: Phaser.GameObjects.Image;
  private robotShadow?: Phaser.GameObjects.Ellipse;
  private executionMarkers: Phaser.GameObjects.GameObject[] = [];
  private robotState = { ...this.robotPuzzle.grid.start };
  private executing = false;
  private readonly cellSize = 80;
  private readonly origin = { x: 330, y: 170 };

  constructor() {
    super("RobotCodingScene");
  }

  create(): void {
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    VisualKit.cinematicDepth(this, "academy", 0.78);
    this.drawScene();
    this.createControls();
    this.resetRobot();
    VisualKit.vignette(this);
  }

  private drawScene(): void {
    this.add.text(72, 44, "Robot N-7: recupero chiave", {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(74, 94, "Costruisci una sequenza, poi osserva cosa succede. Se sbaglia, correggi il programma.", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#c9dce6",
    });

    SceneChrome.consolePanel(this, 298, 138, 520, 420, "Griglia missione", "academy");
    VisualKit.glowFrame(this, 288, 128, 540, 440, "academy");
    VisualKit.scanLine(this, 558, 348, 486, 382, "academy");
    for (let row = 0; row < this.robotPuzzle.grid.rows; row += 1) {
      for (let col = 0; col < this.robotPuzzle.grid.cols; col += 1) {
        const x = this.origin.x + col * this.cellSize;
        const y = this.origin.y + row * this.cellSize;
        const obstacle = this.robotPuzzle.grid.obstacles.some((item) => item.col === col && item.row === row);
        this.add.rectangle(x + 4, y + 5, this.cellSize - 8, this.cellSize - 8, 0x000000, 0.18);
        this.add
          .rectangle(x, y, this.cellSize - 8, this.cellSize - 8, obstacle ? 0x4c2b38 : 0x132835, obstacle ? 0.88 : 0.64)
          .setStrokeStyle(1, obstacle ? 0xc94b55 : 0x315766, 0.7);
      }
    }

    const key = this.robotPuzzle.grid.key;
    this.add.image(this.cellX(key.col), this.cellY(key.row), "soft-glow").setTint(0xf6c85f).setAlpha(0.24).setScale(1.2);
    this.add.star(this.cellX(key.col), this.cellY(key.row), 5, 12, 28, 0xf6c85f, 1).setStrokeStyle(2, 0xffe6a0, 0.9);
    SceneChrome.consolePanel(this, 832, 140, 364, 420, "Buffer comandi", "academy");

    this.commandText = this.add.text(852, 196, "Sequenza:\n(vuota)", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f5fbff",
      wordWrap: { width: 330 },
      lineSpacing: 7,
    });
    this.statusText = this.add.text(852, 420, `Prima strategia: guarda la punta, immagina tre mosse, poi esegui. Budget utile: ${this.robotPuzzle.idealLength} comandi.`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#c9dce6",
      wordWrap: { width: 340 },
      lineSpacing: 6,
    });
    this.add.text(852, 514, "Debug: se N-7 urta, il comando evidenziato e il primo da correggere.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 340 },
      lineSpacing: 4,
    });
  }

  private createControls(): void {
    this.robotPuzzle.commands.forEach((command, index) => {
      new Button(this, 178 + index * 210, 646, commandLabels[command], () => this.addCommand(command), {
        width: 190,
        height: 48,
        fontSize: 15,
      });
    });

    new Button(this, 930, 646, "Esegui", () => this.execute(), {
      width: 150,
      height: 48,
      fill: 0x1f4b46,
    });
    new Button(this, 1100, 646, "Pulisci", () => this.clearCommands(), {
      width: 150,
      height: 48,
      fill: 0x263743,
    });
    new Button(this, 104, 646, "Indietro", () => this.scene.start("LaboratoryScene"), {
      width: 140,
      height: 48,
      fill: 0x263743,
    });
  }

  private resetRobot(): void {
    this.robotState = { ...this.robotPuzzle.grid.start };
    this.robotSprite?.destroy();
    this.robotGlow?.destroy();
    this.robotShadow?.destroy();
    this.robotShadow = this.add.ellipse(this.cellX(this.robotState.col), this.cellY(this.robotState.row) + 22, 54, 16, 0x000000, 0.28);
    this.robotGlow = this.add.image(this.cellX(this.robotState.col), this.cellY(this.robotState.row), "soft-glow");
    this.robotGlow.setTint(0x6be7d6).setAlpha(0.18).setScale(1.15);
    this.robotSprite = this.add.triangle(
      this.cellX(this.robotState.col),
      this.cellY(this.robotState.row),
      0,
      -28,
      24,
      22,
      -24,
      22,
      0x6be7d6,
      1,
    );
    this.robotSprite.setStrokeStyle(2, 0xf5fbff, 0.8);
    this.robotSprite.setRotation(this.rotationFor(this.robotState.facing));
  }

  private addCommand(command: RobotCommand): void {
    if (this.executing || this.commands.length >= this.robotPuzzle.idealLength) {
      if (!this.executing) {
        this.statusText?.setColor("#f7d37a").setText("Il buffer è pieno: prova a eseguire o pulisci la sequenza invece di aggiungere comandi a caso.");
        audioManager.play("error");
      }
      return;
    }
    this.commands.push(command);
    this.refreshCommands();
  }

  private clearCommands(): void {
    if (this.executing) {
      return;
    }
    this.commands = [];
    this.refreshCommands();
    this.resetRobot();
    this.statusText?.setColor("#c9dce6").setText("Sequenza cancellata. Il robot torna alla base.");
  }

  private execute(): void {
    if (this.executing || this.commands.length === 0) {
      return;
    }
    this.executing = true;
    this.clearExecutionMarkers();
    this.resetRobot();
    this.statusText?.setColor("#c9dce6").setText("Esecuzione in corso...");
    this.runCommandAt(0);
  }

  private runCommandAt(index: number): void {
    if (index >= this.commands.length) {
      this.finishExecution(false, mistakeAnalyzer.robotFailureMessage({ kind: "missing-key" }, this.commands));
      return;
    }

    const command = this.commands[index];
    this.highlightCommand(index);
    const result = this.applyCommand(command, index);
    if (!result.ok) {
      this.finishExecution(false, result.message);
      return;
    }

    const duration = command === "MOVE_FORWARD" ? 300 : 180;
    this.time.delayedCall(duration + 90, () => {
      if (command === "PICK_UP" && this.isOnKey()) {
        if (this.commands.length > this.robotPuzzle.idealLength) {
          this.finishExecution(false, mistakeAnalyzer.robotFailureMessage({ kind: "too-long", commandCount: this.commands.length, ideal: this.robotPuzzle.idealLength }, this.commands));
          return;
        }
        inventorySystem.add("chiave magnetica");
        missionEngine.completeObjective("robotKeyRecovered", ["coding.sequenze", "coding.debugging"], 18);
        audioManager.play("success");
        this.finishExecution(true, "Chiave recuperata. Il robot invia il consenso alla porta.");
        this.time.delayedCall(900, () => this.scene.start("LaboratoryScene"));
        return;
      }
      this.runCommandAt(index + 1);
    });
  }

  private applyCommand(command: RobotCommand, index: number): { ok: boolean; message: string } {
    if (command === "TURN_LEFT" || command === "TURN_RIGHT") {
      this.robotState.facing = this.turn(this.robotState.facing, command);
      this.tweens.add({
        targets: this.robotSprite,
        rotation: this.rotationFor(this.robotState.facing),
        duration: 160,
      });
      return { ok: true, message: "" };
    }

    if (command === "PICK_UP") {
      return this.isOnKey()
        ? { ok: true, message: "" }
        : { ok: false, message: mistakeAnalyzer.robotFailureMessage({ kind: "premature-pickup", commandIndex: index }, this.commands) };
    }

    const next = this.nextCell();
    if (
      next.col < 0 ||
      next.row < 0 ||
      next.col >= this.robotPuzzle.grid.cols ||
      next.row >= this.robotPuzzle.grid.rows ||
      this.robotPuzzle.grid.obstacles.some((item) => item.col === next.col && item.row === next.row)
    ) {
      feedbackSystem.robotWall();
      return { ok: false, message: mistakeAnalyzer.robotFailureMessage({ kind: "wall", commandIndex: index }, this.commands) };
    }

    this.robotState.col = next.col;
    this.robotState.row = next.row;
    this.markVisitedCell(next.col, next.row);
    this.tweens.add({
      targets: [this.robotSprite, this.robotGlow],
      x: this.cellX(next.col),
      y: this.cellY(next.row),
      duration: 300,
      ease: "Sine.easeInOut",
    });
    this.tweens.add({
      targets: this.robotShadow,
      x: this.cellX(next.col),
      y: this.cellY(next.row) + 22,
      duration: 300,
      ease: "Sine.easeInOut",
    });
    return { ok: true, message: "" };
  }

  private finishExecution(success: boolean, message: string): void {
    this.executing = false;
    this.statusText?.setColor(success ? "#9ff5e9" : "#f7d37a").setText(message);
    VisualKit.outcomeFlash(this, success ? "success" : "error", 558, 348, 560, 440);
    VisualKit.particleBurst(this, this.cellX(this.robotState.col), this.cellY(this.robotState.row), "academy", success ? "success" : "error");
    if (!success) {
      audioManager.play("error");
      const shakeTargets = [this.robotSprite, this.robotGlow].filter(
        (item): item is Phaser.GameObjects.Triangle | Phaser.GameObjects.Image => Boolean(item),
      );
      VisualKit.shake(this, shakeTargets, 8);
    }
  }

  private refreshCommands(): void {
    const lines = this.commands.length > 0 ? this.commands.map((command, index) => `${index + 1}. ${commandLabels[command]}`) : ["(vuota)"];
    this.commandText?.setText(`Sequenza:\n${lines.join("\n")}`);
  }

  private highlightCommand(index: number): void {
    const marker = this.add.rectangle(1014, 183 + index * 24, 320, 22, 0xf6c85f, 0.12).setStrokeStyle(1, 0xf6c85f, 0.28);
    this.executionMarkers.push(marker);
    this.tweens.add({
      targets: marker,
      alpha: 0,
      duration: 520,
      onComplete: () => marker.destroy(),
    });
  }

  private markVisitedCell(col: number, row: number): void {
    const marker = this.add.rectangle(this.cellX(col), this.cellY(row), this.cellSize - 22, this.cellSize - 22, 0x6be7d6, 0.12).setStrokeStyle(1, 0x6be7d6, 0.28);
    this.executionMarkers.push(marker);
  }

  private clearExecutionMarkers(): void {
    this.executionMarkers.forEach((marker) => marker.destroy());
    this.executionMarkers = [];
  }

  private nextCell(): { col: number; row: number } {
    const delta = {
      N: { col: 0, row: -1 },
      E: { col: 1, row: 0 },
      S: { col: 0, row: 1 },
      W: { col: -1, row: 0 },
    }[this.robotState.facing];
    return {
      col: this.robotState.col + delta.col,
      row: this.robotState.row + delta.row,
    };
  }

  private turn(facing: Facing, command: "TURN_LEFT" | "TURN_RIGHT"): Facing {
    const order: Facing[] = ["N", "E", "S", "W"];
    const offset = command === "TURN_RIGHT" ? 1 : -1;
    return order[(order.indexOf(facing) + offset + order.length) % order.length];
  }

  private isOnKey(): boolean {
    return this.robotState.col === this.robotPuzzle.grid.key.col && this.robotState.row === this.robotPuzzle.grid.key.row;
  }

  private rotationFor(facing: Facing): number {
    return {
      N: 0,
      E: Math.PI / 2,
      S: Math.PI,
      W: -Math.PI / 2,
    }[facing];
  }

  private cellX(col: number): number {
    return this.origin.x + col * this.cellSize;
  }

  private cellY(row: number): number {
    return this.origin.y + row * this.cellSize;
  }
}
