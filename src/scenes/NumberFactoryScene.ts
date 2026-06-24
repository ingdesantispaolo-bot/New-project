import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { dialogueSystem } from "../core/DialogueSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import { exerciseVariantSystem } from "../core/ExerciseVariantSystem";
import type { FeedbackMessage } from "../core/FeedbackSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { mapLayoutSystem, type MapLayoutRect } from "../core/MapLayoutSystem";
import { missionEngine } from "../core/MissionEngine";
import { saveSystem } from "../core/SaveSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { tiledSceneRenderer } from "../core/TiledSceneRenderer";
import { numberMachines, type NumberMachineDefinition, type ProductionOrder } from "../data/numberFactory";
import { NumberFactorySimulator, type NumberMachine } from "../procedural/simulators/NumberFactorySimulator";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type MachineResult = {
  ok: boolean;
  value: number;
  message: string;
};

export class NumberFactoryScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getFactoryLayout();
  private readonly simulator = new NumberFactorySimulator();
  private productionOrders: ProductionOrder[] = exerciseVariantSystem.getProductionOrders();
  private orderIndex = 0;
  private currentValue = this.productionOrders[0].start;
  private expression = `${this.productionOrders[0].start}`;
  private steps: string[] = [];
  private machineHistoryIds: string[] = [];
  private completedOrderIds: string[] = [];
  private machineLayer?: Phaser.GameObjects.Container;
  private panelLayer?: Phaser.GameObjects.Container;
  private feedbackText?: Phaser.GameObjects.Text;
  private objectiveText?: Phaser.GameObjects.Text;
  private coreText?: Phaser.GameObjects.Text;

  constructor() {
    super("NumberFactoryScene");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.drawFactory();
    this.createHud();
    if (!this.restoreRun()) {
      this.resetCurrentOrder(false);
    }
    this.refreshScene();

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    if (!saveSystem.data.flags.mission3IntroSeen) {
      saveSystem.setFlag("mission3IntroSeen", true);
      new DialogueBox(this, dialogueSystem.format("mission3Opening"), () => {
        feedbackSystem.publish("Scansiona la linea: le macchine non sono domande, sono trasformazioni.", "info");
      });
    }
  }

  private drawFactory(): void {
    SceneChrome.drawTwoColumnMissionChrome(
      this,
      "factory",
      "La Fabbrica dei Numeri",
      "Scegli il percorso delle macchine. Ogni passaggio cambia il nucleo o controlla se può proseguire.",
      "Linea energia numerica",
    );
    VisualKit.cinematicDepth(this, "factory", 0.92);
    tiledSceneRenderer.renderBackdrop(this, "factory");

    const floor = this.add.graphics();
    floor.fillStyle(0x141820, 0.18);
    floor.fillRect(44, 146, 748, 474);
    floor.lineStyle(2, 0xf6c85f, 0.2);
    floor.strokeRect(44, 146, 748, 474);
    VisualKit.glowFrame(this, 36, 138, 764, 492, "factory");
    for (let y = 202; y < 600; y += 74) {
      floor.lineBetween(44, y, 792, y);
    }
    for (let x = 94; x < 790; x += 94) {
      floor.lineBetween(x, 146, x - 48, 620);
    }

    const belt = this.add.graphics();
    const conveyorTexture = this.textureKey("painted-factory-conveyor", "prop-factory-conveyor");
    if (conveyorTexture) {
      this.add.image(420, 361, conveyorTexture).setDisplaySize(680, 126).setAlpha(0.9);
    } else {
      belt.fillStyle(0x0b1018, 0.72);
      belt.fillRect(92, 332, 646, 58);
      belt.lineStyle(3, 0x53636a, 0.8);
      belt.strokeRect(92, 332, 646, 58);
      for (let x = 112; x < 720; x += 38) {
        belt.lineBetween(x, 332, x + 18, 390);
      }
    }
    this.drawFactoryAtmosphere();
    this.drawConveyorMotion();

    for (let index = 0; index < 12; index += 1) {
      const spark = this.add.image(Phaser.Math.Between(70, 760), Phaser.Math.Between(160, 580), "soft-glow");
      spark.setTint(index % 2 === 0 ? 0xf6c85f : 0x6be7d6).setAlpha(0.05).setScale(Phaser.Math.FloatBetween(0.4, 1.1));
      this.tweens.add({
        targets: spark,
        x: spark.x + Phaser.Math.Between(-22, 32),
        alpha: { from: 0.02, to: 0.16 },
        duration: Phaser.Math.Between(1400, 3600),
        yoyo: true,
        repeat: -1,
      });
    }
  }

  private drawConveyorMotion(): void {
    // Chevrons that scroll one segment then snap back; with evenly spaced
    // chevrons this reads as a continuously moving belt. Static if effects
    // are reduced (a single set of arrows still hints at flow direction).
    const beltLeft = 104;
    const beltRight = 726;
    const spacing = 46;
    const y = 361;
    const reduced = settingsSystem.effectsReduced();
    for (let startX = beltLeft; startX <= beltRight - spacing; startX += spacing) {
      const chevron = this.add.triangle(startX, y, 0, -7, 11, 0, 0, 7, 0xf6c85f, reduced ? 0.22 : 0.4)
        .setOrigin(0.5);
      if (!reduced) {
        this.tweens.add({
          targets: chevron,
          x: startX + spacing,
          duration: 760,
          ease: "Linear",
          repeat: -1,
        });
      }
    }
  }

  private drawFactoryAtmosphere(): void {
    const reduced = settingsSystem.effectsReduced();
    for (let index = 0; index < 9; index += 1) {
      const cx = 126 + index * 70;
      const roller = this.add.container(cx, 361);
      roller.add(this.add.circle(0, 0, 14, 0x53636a, 0.5).setStrokeStyle(2, 0xf6c85f, 0.16));
      // A spoke makes the rotation actually readable on a round roller.
      roller.add(this.add.rectangle(0, 0, 2, 22, 0xf6c85f, 0.4));
      roller.add(this.add.rectangle(0, 0, 22, 2, 0xf6c85f, 0.22));
      if (!reduced) {
        this.tweens.add({ targets: roller, rotation: Math.PI * 2, duration: 1600, repeat: -1, ease: "Linear" });
      }
    }
    for (let index = 0; index < 7; index += 1) {
      const steam = this.add.ellipse(112 + index * 98, 170 + (index % 3) * 22, 34, 76, 0xffffff, 0.035);
      this.tweens.add({
        targets: steam,
        y: steam.y - 42,
        alpha: { from: 0.015, to: 0.09 },
        scaleX: 1.6,
        duration: 2600 + index * 260,
        yoyo: true,
        repeat: -1,
      });
    }
    VisualKit.scanLine(this, 420, 356, 666, 108, "factory");
  }

  private createHud(): void {
    SceneChrome.consolePanel(this, 820, 130, 420, 126, "Ordine di produzione", "factory");
    this.objectiveText = this.add.text(842, 164, "", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#d9eaf1",
      wordWrap: { width: 370 },
      lineSpacing: 5,
    });

    this.feedbackText = SceneChrome.bottomLog(this, SceneChrome.twoColumnLayout.bottom, "");

    new Button(this, 1110, 58, "Diario", () => this.scene.start("JournalScene"), {
      width: 150,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
    new Button(this, 930, 58, "Hub", () => this.scene.start("HubScene"), {
      width: 132,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
  }

  private refreshScene(): void {
    this.machineLayer?.destroy(true);
    this.panelLayer?.destroy(true);
    this.machineLayer = this.add.container(0, 0);
    this.panelLayer = this.add.container(0, 0);
    this.drawMachines();
    this.drawControlPanel();
  }

  private drawMachines(): void {
    const positions = [
      { x: 150, y: 210 },
      { x: 330, y: 210 },
      { x: 510, y: 210 },
      { x: 690, y: 210 },
      { x: 150, y: 500 },
      { x: 330, y: 500 },
      { x: 510, y: 500 },
      { x: 690, y: 500 },
      { x: 420, y: 355 },
    ].map((fallback, index) => this.rect(`factory:machine:${index}`, fallback));

    numberMachines.forEach((machine, index) => {
      const pos = positions[index];
      const container = this.add.container(pos.x, pos.y);
      const isGate = machine.kind === "evenGate" || machine.kind === "multipleOfThreeGate";
      const isTransform = machine.kind === "transform";
      const color = isTransform ? 0x6be7d6 : isGate ? 0xf6c85f : 0x8aa6b0;
      const machineTexture = this.textureKey("painted-factory-machine", "prop-factory-machine");
      if (machineTexture) {
        container.add(this.add.image(0, 0, machineTexture).setDisplaySize(168, 126).setTint(color === 0x8aa6b0 ? 0xddefff : 0xffffff).setAlpha(0.95));
      } else {
        container.add(this.add.rectangle(8, 8, 142, 92, 0x000000, 0.32));
        container.add(this.add.rectangle(0, 0, 142, 92, 0x15202a, 0.84).setStrokeStyle(2, color, 0.72));
        container.add(this.add.rectangle(0, -42, 106, 8, color, 0.18));
        container.add(this.add.circle(-56, -34, 5, color, 0.48));
        container.add(this.add.circle(56, -34, 5, color, 0.48));
        container.add(this.add.circle(-56, 34, 5, color, 0.32));
        container.add(this.add.circle(56, 34, 5, color, 0.32));
        container.add(this.add.rectangle(0, 42, 122, 18, 0x0b1018, 0.82));
      }
      container.add(this.add.text(-58, -34, machine.label, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f5fbff",
        fontStyle: "bold",
      }));
      container.add(this.add.text(-42, -4, machine.expressionLabel, {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: isGate ? "#f7d37a" : "#9ff5e9",
        fontStyle: "bold",
      }));
      container.setSize(142, 92);
      const hitTarget = this.add.rectangle(0, 0, 142, 92, 0x000000, 0.001).setInteractive();
      if (hitTarget.input) hitTarget.input.cursor = "pointer";
      let armed = false;
      hitTarget
        .on("pointerover", () => {
          audioManager.play("scan");
          feedbackSystem.publish(`${machine.description} ${machine.hint}`, "info");
        })
        .on("pointerdown", () => {
          armed = true;
        })
        .on("pointerup", () => {
          if (!armed) return;
          armed = false;
          this.runMachine(machine);
        })
        .on("pointerupoutside", () => {
          armed = false;
        });
      container.add(hitTarget);
      this.machineLayer?.add(container);
    });

    const core = this.rect("factory:core", { x: 420, y: 355, width: 96, height: 96 });
    this.coreText = this.add.text(core.x - 34, core.y - 33, `${this.currentValue}`, {
      fontFamily: "Inter, Arial",
      fontSize: "48px",
      color: "#f6c85f",
      fontStyle: "bold",
      backgroundColor: "rgba(8, 19, 28, 0.72)",
      padding: { x: 24, y: 8 },
    });
    this.coreText.setOrigin(0.5);
    const coreTexture = this.textureKey("painted-factory-core", "prop-factory-core");
    this.machineLayer?.add(coreTexture
      ? this.add.image(core.x, core.y, coreTexture).setDisplaySize(140, 140).setAlpha(0.94)
      : this.add.image(core.x, core.y, "soft-glow").setTint(0xf6c85f).setAlpha(0.18).setScale(2.1));
    this.machineLayer?.add(this.coreText);
  }

  private drawControlPanel(): void {
    const order = this.getCurrentOrder();
    this.objectiveText?.setText(`${order.title}\n${order.narrative}\nNucleo ${order.start} -> obiettivo ${order.target}`);

    const panel = this.rect("factory:controlPanel", { x: 820, y: 280, width: 420, height: 340 });
    this.panelLayer?.add(SceneChrome.consolePanel(this, panel.x, panel.y, panel.width ?? 420, panel.height ?? 340, "Console di produzione", "factory"));
    this.panelLayer?.add(this.add.text(panel.x + 22, panel.y + 58, `Obiettivo: ${order.target}`, {
      fontFamily: "Inter, Arial",
      fontSize: "26px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    this.panelLayer?.add(this.add.text(panel.x + 22, panel.y + 96, `Valore attuale: ${this.currentValue}`, {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: this.currentValue === order.target ? "#9ff5e9" : "#f5fbff",
    }));
    this.panelLayer?.add(this.add.text(panel.x + 22, panel.y + 128, `Passaggi: ${this.steps.length}/${order.maxSteps}`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: this.steps.length > order.maxSteps ? "#ffb36b" : "#c9dce6",
    }));
    const requiredLabels = order.requiredMachineIds
      .map((machineId) => numberMachines.find((machine) => machine.id === machineId)?.label ?? machineId)
      .join(", ");
    this.panelLayer?.add(this.add.text(panel.x + 22, panel.y + 158, `Certifica: ${requiredLabels}`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
    }));
    this.panelLayer?.add(this.add.text(panel.x + 22, panel.y + 198, `Traccia: ${this.expression}`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      wordWrap: { width: 360 },
      lineSpacing: 5,
    }));
    this.panelLayer?.add(this.add.text(panel.x + 22, panel.y + 272, this.steps.length > 0 ? this.steps.join(" -> ") : "Nessuna macchina attraversata.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 5,
    }));

    const scan = this.rect("factory:scanLine", { x: 912, y: 590, width: 172 });
    this.panelLayer?.add(new Button(this, scan.x, scan.y, "Scansiona linea", () => this.inspectLine(), {
      width: scan.width,
      height: 44,
      fontSize: 15,
      fill: 0x142736,
    }));
    const reset = this.rect("factory:resetCore", { x: 1098, y: 590, width: 168 });
    this.panelLayer?.add(new Button(this, reset.x, reset.y, "Reset nucleo", () => this.resetCurrentOrder(true), {
      width: reset.width,
      height: 44,
      fontSize: 15,
      fill: 0x263743,
    }));
    const check = this.rect("factory:checkOrder", { x: 998, y: 646, width: 228 });
    this.panelLayer?.add(new Button(this, check.x, check.y, "Controlla ordine", () => this.checkOrder(), {
      width: check.width,
      height: 48,
      fontSize: 17,
      fill: 0x173b36,
    }));
  }

  private inspectLine(): void {
    if (!saveSystem.data.flags.numberMachinesInspected) {
      missionEngine.completeObjective("numberMachinesInspected", ["matematica.operazioni", "pensieroCritico"], 12);
    }
    audioManager.play("scan");
    feedbackSystem.publish(`${this.getCurrentOrder().clue} Ogni macchina lascia una traccia: usala per controllare l'errore.`, "hint");
    this.refreshScene();
  }

  private runMachine(machine: NumberMachineDefinition): void {
    if (!saveSystem.data.flags.numberMachinesInspected) {
      feedbackSystem.publish("Prima scansiona la linea: le macchine vanno capite prima di attraversarle.", "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 420, 356, 760, 470);
      return;
    }

    const order = this.getCurrentOrder();
    if (this.steps.length >= order.maxSteps) {
      feedbackSystem.publish("Il nucleo ha finito i passaggi disponibili. Reset o controllo dell'ordine.", "warning");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 420, 356, 760, 470);
      return;
    }

    const result = this.applyMachine(machine, this.currentValue);
    if (!result.ok) {
      feedbackSystem.publish(result.message, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 420, 356, 760, 470);
      VisualKit.particleBurst(this, 420, 355, "factory", "error");
      return;
    }

    this.currentValue = result.value;
    this.steps.push(machine.expressionLabel);
    this.machineHistoryIds.push(machine.id);
    this.expression = this.wrapExpression(this.expression, machine);
    this.persistRun();
    audioManager.play("panelOpen");
    if (this.coreText) {
      this.tweens.add({
        targets: this.coreText,
        scale: 1.22,
        duration: 120,
        yoyo: true,
      });
    }
    VisualKit.particleBurst(this, 420, 355, "factory", this.currentValue === order.target ? "success" : "warning");
    VisualKit.outcomeFlash(this, this.currentValue === order.target ? "success" : "warning", 420, 356, 760, 470);
    feedbackSystem.publish(result.message, this.currentValue === order.target ? "success" : "info");
    this.refreshScene();
  }

  private applyMachine(machine: NumberMachineDefinition, input: number): MachineResult {
    const result = this.simulator.run(input, [this.toSimulatorMachine(machine)]);
    const lastTrace = result.trace[result.trace.length - 1] ?? machine.description;
    if (!result.accepted) {
      return { ok: false, value: result.value, message: `${machine.label} blocca il nucleo: ${lastTrace}. Controlla il vincolo prima di proseguire.` };
    }
    return { ok: true, value: result.value, message: `${machine.label}: ${lastTrace}.` };
  }

  private toSimulatorMachine(machine: NumberMachineDefinition): NumberMachine {
    if (machine.kind === "evenGate") return { type: "only-even" };
    if (machine.kind === "multipleOfThreeGate") return { type: "only-multiple", value: 3 };
    if (machine.kind === "transform") return { type: "transform-2n-plus-1", value: machine.value ?? 1 };
    if (machine.kind === "add") return { type: "add", value: machine.value ?? 0 };
    if (machine.kind === "subtract") return { type: "subtract", value: machine.value ?? 0 };
    if (machine.kind === "multiply") return { type: "multiply", value: machine.value ?? 1 };
    return { type: "divide", value: machine.value ?? 1 };
  }

  private wrapExpression(expression: string, machine: NumberMachineDefinition): string {
    if (machine.kind === "add") {
      return `(${expression} + ${machine.value})`;
    }
    if (machine.kind === "subtract") {
      return `(${expression} - ${machine.value})`;
    }
    if (machine.kind === "multiply") {
      return `(${expression} x ${machine.value})`;
    }
    if (machine.kind === "divide") {
      return `(${expression} / ${machine.value})`;
    }
    if (machine.kind === "transform") {
      return `(2 x ${expression} + 1)`;
    }
    return `${expression} [${machine.expressionLabel}]`;
  }

  private checkOrder(): void {
    const order = this.getCurrentOrder();
    const missingRequiredMachines = order.requiredMachineIds.filter((machineId) => !this.machineHistoryIds.includes(machineId));
    if (this.currentValue !== order.target) {
      feedbackSystem.publish(
        `La linea produce ${this.currentValue}, ma l'ordine chiede ${order.target}. ${order.solutionHint}`,
        "hint",
      );
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 450, 440, 360);
      VisualKit.particleBurst(this, 998, 446, "factory", "error");
      return;
    }

    if (missingRequiredMachines.length > 0) {
      const labels = missingRequiredMachines
        .map((machineId) => numberMachines.find((machine) => machine.id === machineId)?.label ?? machineId)
        .join(", ");
      feedbackSystem.publish(
        `Il valore è corretto, ma l'ordine non è certificato: manca il passaggio su ${labels}. Nella fabbrica conta anche il controllo del percorso.`,
        "hint",
      );
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 450, 440, 360);
      VisualKit.particleBurst(this, 998, 446, "factory", "warning");
      return;
    }

    if (!saveSystem.data.flags.firstNumberOrderComplete) {
      missionEngine.completeObjective("firstNumberOrderComplete", [
        "matematica.calcolo",
        "matematica.logica",
        "coding.sequenze",
      ], 15);
    }

    if (!this.completedOrderIds.includes(order.id)) {
      this.completedOrderIds.push(order.id);
    }
    this.persistRun();
    audioManager.play("success");
    feedbackSystem.publish(`Ordine ${order.title} stabilizzato. La traccia mostra perché il percorso ha funzionato.`, "success");
    VisualKit.outcomeFlash(this, "success", 640, 360, 1120, 620);
    VisualKit.particleBurst(this, 420, 355, "factory", "success");

    if (this.completedOrderIds.length >= this.productionOrders.length) {
      missionEngine.completeObjective("numberFactoryStabilized", [
        "matematica.multipliDivisori",
        "matematica.espressioni",
        "matematica.controlloErrore",
        "problemSolving",
      ], 18);
      missionEngine.completeMissionThree(this.productionOrders.map((productionOrder) => productionOrder.title));
      saveSystem.setNumberFactoryRun(undefined);
      this.time.delayedCall(1100, () => this.scene.start("JournalScene"));
      return;
    }

    this.orderIndex += 1;
    this.persistRun();
    this.time.delayedCall(850, () => {
      this.resetCurrentOrder(false);
      this.refreshScene();
    });
  }

  private resetCurrentOrder(playSound: boolean): void {
    const order = this.getCurrentOrder();
    this.currentValue = order.start;
    this.expression = `${order.start}`;
    this.steps = [];
    this.machineHistoryIds = [];
    this.persistRun();
    if (playSound) {
      audioManager.play("click");
      feedbackSystem.publish("Nucleo riportato all'ingresso. La traccia è pulita.", "info");
    }
    this.refreshScene();
  }

  private getCurrentOrder(): ProductionOrder {
    return this.productionOrders[Math.min(this.orderIndex, this.productionOrders.length - 1)];
  }

  private restoreRun(): boolean {
    const run = saveSystem.data.numberFactoryRun;
    if (!run || run.orderIndex >= this.productionOrders.length) {
      return false;
    }
    this.orderIndex = run.orderIndex;
    this.currentValue = run.currentValue;
    this.expression = run.expression;
    this.steps = [...run.steps];
    this.machineHistoryIds = [...run.machineHistoryIds];
    this.completedOrderIds = [...run.completedOrderIds];
    return true;
  }

  private persistRun(): void {
    saveSystem.setNumberFactoryRun({
      orderIndex: this.orderIndex,
      currentValue: this.currentValue,
      expression: this.expression,
      steps: [...this.steps],
      machineHistoryIds: [...this.machineHistoryIds],
      completedOrderIds: [...this.completedOrderIds],
    });
  }

  private rect(id: string, fallback: MapLayoutRect): Required<Pick<MapLayoutRect, "x" | "y">> & MapLayoutRect {
    return { ...fallback, ...this.layout[id] } as Required<Pick<MapLayoutRect, "x" | "y">> & MapLayoutRect;
  }

  private textureKey(primary: string, fallback: string): string | undefined {
    if (this.textures.exists(primary)) return primary;
    if (this.textures.exists(fallback)) return fallback;
    return undefined;
  }

  private handleFeedback(message: FeedbackMessage): void {
    const colors = {
      info: "#d9eaf1",
      hint: "#f7d37a",
      success: "#9ff5e9",
      warning: "#ffb36b",
    };
    this.feedbackText?.setColor(colors[message.tone]).setText(message.text);
  }
}
