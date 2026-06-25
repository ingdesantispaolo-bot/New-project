import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { dialogueSystem } from "../core/DialogueSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import type { FeedbackMessage } from "../core/FeedbackSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { inventorySystem } from "../core/InventorySystem";
import { mapLayoutSystem } from "../core/MapLayoutSystem";
import { missionEngine } from "../core/MissionEngine";
import { propRenderer } from "../core/PropRenderer";
import { saveSystem } from "../core/SaveSystem";
import { exerciseVariantSystem } from "../core/ExerciseVariantSystem";
import { startScene } from "../core/SceneNavigator";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { laboratoryObjects, type LaboratoryObject } from "../data/laboratoryObjects";
import type { EnglishInstructionDefinition, GrammarRepairDefinition } from "../types/puzzleTypes";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { EliAvatar } from "../ui/EliAvatar";
import { Panel } from "../ui/Panel";
import { SceneChrome, type DeviceKind, type DeviceState } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

export class LaboratoryScene extends Phaser.Scene {
  private grammarRepairPuzzle: GrammarRepairDefinition = exerciseVariantSystem.getGrammarRepairPuzzle();
  private englishInstructionPuzzle: EnglishInstructionDefinition = exerciseVariantSystem.getEnglishInstructionPuzzle();
  private feedbackText?: Phaser.GameObjects.Text;
  private objectiveText?: Phaser.GameObjects.Text;
  private inventoryText?: Phaser.GameObjects.Text;
  private overlay?: Phaser.GameObjects.Container;
  private inspectionPanel?: Phaser.GameObjects.Container;
  private player?: EliAvatar;
  private hintCursor: Record<string, number> = {};
  private grammarAnalysisUnlocked = false;
  private grammarRepairAttempts = 0;
  private englishAnalysisUnlocked = false;
  private englishAttempts = 0;
  private readonly mapHotspots = mapLayoutSystem.getLaboratoryHotspots();

  constructor() {
    super("LaboratoryScene");
  }

  preload(): void {
    queueSceneAssets(this, "lab");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.drawLaboratory();
    this.createSceneProps();
    this.createPlayer();
    this.createHud();
    this.createHotspots();
    this.refreshHud();

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    if (!saveSystem.data.flags.introSeen) {
      saveSystem.setFlag("introSeen", true);
      new DialogueBox(this, dialogueSystem.format("mission1Opening"), () => {
        feedbackSystem.publish("Osserva prima di agire: la stanza ha già disegnato una pista.", "info");
        this.inspectObject(laboratoryObjects.find((object) => object.id === "floor-trace") ?? laboratoryObjects[0]);
      });
    } else {
      this.inspectObject(laboratoryObjects.find((object) => object.id === "floor-trace") ?? laboratoryObjects[0]);
    }
  }

  private drawLaboratory(): void {
    this.cameras.main.setBackgroundColor("#061019");
    VisualKit.background(this, "lab");
    VisualKit.cinematicDepth(this, "lab", 0.82);
    this.add.rectangle(180, 360, 320, 720, 0x061019, 0.86).setStrokeStyle(2, 0x1a3945, 0.78);
    this.add.rectangle(805, 360, 900, 650, 0x091722, 0.18).setStrokeStyle(2, 0x254958, 0.42);
    VisualKit.glowFrame(this, 356, 70, 884, 592, "lab");

    const wall = this.add.graphics();
    wall.fillStyle(0x0d1d27, 0.14);
    wall.fillRect(360, 84, 860, 454);
    wall.lineStyle(2, 0x243f4d, 0.38);
    wall.strokeRect(360, 84, 860, 454);
    wall.lineStyle(1, 0x315766, 0.18);
    for (let x = 390; x < 1200; x += 82) {
      wall.lineBetween(x, 84, x - 36, 538);
    }
    for (let y = 136; y < 520; y += 64) {
      wall.lineBetween(360, y, 1220, y);
    }

    this.add.rectangle(800, 618, 850, 160, 0x101b24, 0.28).setStrokeStyle(1, 0x294958, 0.44);
    for (let x = 390; x < 1210; x += 70) {
      this.add.line(x, 616, 0, 0, -34, 96, 0x233d48, 0.4).setOrigin(0);
    }

    this.drawMissionTrace();
    this.drawDoor();
    this.drawPanel();
    this.drawTerminal();
    this.drawRobot();
    this.drawAmbientObjects();
    this.drawAmbientAnimation();
    VisualKit.scanLine(this, 805, 366, 804, 540, "lab");
    VisualKit.vignette(this);
  }

  private drawMissionTrace(): void {
    const trace = this.add.graphics();
    trace.lineStyle(3, 0x6be7d6, 0.09);
    trace.beginPath();
    trace.moveTo(910, 502);
    trace.lineTo(470, 286);
    trace.lineTo(1072, 276);
    trace.lineTo(560, 500);
    trace.lineTo(760, 214);
    trace.strokePath();

    const pulse = this.add.graphics();
    pulse.lineStyle(2, 0xf6c85f, 0.26);
    pulse.strokeCircle(686, 590, 18);
    this.tweens.add({ targets: pulse, alpha: 0.18, duration: 1200, yoyo: true, repeat: -1 });
  }

  private drawDoor(): void {
    const open = missionEngine.canOpenFinalDoor();
    this.add.rectangle(760, 214, 298, 312, 0x000000, 0.22);
    this.add.rectangle(760, 214, 264, 278, open ? 0x123b37 : 0x111820, open ? 0.34 : 0.46).setStrokeStyle(4, open ? 0x6be7d6 : 0x4b6570, 0.78);
    this.add.image(760, 214, "holo-ring").setTint(open ? 0x6be7d6 : 0x53636a).setScale(2.4).setAlpha(open ? 0.42 : 0.18);
    this.add.rectangle(760, 214, 146, 204, open ? 0x163b38 : 0x080c12, open ? 0.36 : 0.62);
    this.add.text(706, 104, "PORTA 01", {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: open ? "#9ff5e9" : "#8c9da4",
      fontStyle: "bold",
    });
  }

  private drawPanel(): void {
    const fixed = saveSystem.data.flags.circuitFixed;
    this.add.rectangle(470, 286, 176, 138, 0x142837, 0.56).setStrokeStyle(2, fixed ? 0x9ff5e9 : 0x6be7d6, 0.68);
    this.add.rectangle(470, 266, 130, 52, fixed ? 0x1c6958 : 0x1d2e38, 0.64);
    this.add.text(414, 208, "PANNELLO", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9" });
    this.add.circle(528, 322, 9, fixed ? 0x8cffd7 : 0x405761, 1);
    VisualKit.statusLight(this, 412, 326, fixed ? 0x9ff5e9 : 0xffb36b, true);
  }

  private drawTerminal(): void {
    const powered = saveSystem.data.flags.circuitFixed;
    const solved = saveSystem.data.flags.mathLockSolved;
    this.add.rectangle(1072, 286, 218, 148, 0x102839, 0.5).setStrokeStyle(2, powered ? 0xf6c85f : 0x53636a, 0.48);
    this.add.rectangle(1072, 258, 154, 64, solved ? 0x173e38 : powered ? 0x142936 : 0x081018, 0.62);
    this.add.text(1004, 214, "TERMINALE", { fontFamily: "Inter, Arial", fontSize: "15px", color: powered ? "#f6c85f" : "#7d9098" });
    this.add.rectangle(1104, 486, 132, 66, 0x172833, 0.95).setStrokeStyle(1, 0x6be7d6, 0.35);
    this.add.circle(1066, 482, 18, saveSystem.data.flags.englishInstructionSolved ? 0x2ed889 : 0x39515c, 1);
    this.add.circle(1118, 482, 18, 0xc94b55, saveSystem.data.flags.englishInstructionSolved ? 0.32 : 0.95);
    VisualKit.hologramShard(this, 1168, 274, 64, 82, "lab").setAlpha(powered ? 0.88 : 0.24);
  }

  private drawRobot(): void {
    const active = saveSystem.data.flags.robotKeyRecovered;
    this.add.rectangle(560, 500, 112, 88, 0x182531, 0.52).setStrokeStyle(2, active ? 0xf6c85f : 0x6be7d6, 0.5);
    this.add.ellipse(560, 548, 136, 30, 0x000000, 0.25);
    const robotAsset = this.textures.exists("eli-atlas")
      ? this.add.image(542, 486, "eli-atlas", "robot-core").setScale(0.76).setTint(active ? 0xffffff : 0x7d9098).setAlpha(active ? 0.95 : 0.72)
      : this.add.circle(530, 456, 22, active ? 0x6be7d6 : 0x334650, 1);
    this.tweens.add({ targets: robotAsset, y: robotAsset.y - 5, duration: 1400, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    this.add.rectangle(560, 520, 76, 30, 0x0b1218, 0.82);
    this.add.text(506, 402, "ROBOT N-7", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#c9dce6" });
    VisualKit.statusLight(this, 594, 454, active ? 0xf6c85f : 0x405761, active);
  }

  private drawAmbientObjects(): void {
    this.add.rectangle(910, 500, 180, 84, 0x162733, 0.58).setStrokeStyle(1, 0x6be7d6, 0.52);
    this.add.rectangle(912, 501, 160, 64, 0x6be7d6, 0.025);
    this.add.text(846, 468, "MESSAGGIO", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9" });
    this.add.text(846, 492, saveSystem.data.flags.grammarFixed ? this.grammarRepairPuzzle.repaired : this.grammarRepairPuzzle.corrupted, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: saveSystem.data.flags.grammarFixed ? "#f5fbff" : "#f6c85f",
      wordWrap: { width: 132 },
      lineSpacing: 3,
    });

    this.add.rectangle(430, 514, 128, 70, 0x16242f, 0.5).setStrokeStyle(1, 0xffb36b, 0.46);
    this.add.rectangle(386, 502, 34, 8, 0xffb36b, 0.48);
    this.add.circle(452, 506, 8, 0x8aa6b0, 0.8);
    this.add.text(382, 496, "attrezzi", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a" });
    this.add.rectangle(1120, 486, 84, 84, 0x122934, 0.9).setStrokeStyle(1, 0x6be7d6, 0.45);
    this.add.circle(1120, 486, 20, 0x6be7d6, 0.2).setStrokeStyle(2, 0x6be7d6, 0.62);
    this.add.rectangle(1120, 180, 136, 78, 0x071018, 0.9).setStrokeStyle(2, 0x315766, 0.8);
    this.add.rectangle(820, 575, 112, 50, 0x152937, 0.95).setStrokeStyle(1, 0xf6c85f, 0.38);
    this.add.text(786, 560, "diario", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a" });
  }

  private drawAmbientAnimation(): void {
    for (let index = 0; index < 9; index += 1) {
      const light = this.add.rectangle(390 + index * 90, 126, 44, 5, index % 3 === 0 ? 0xf6c85f : 0x6be7d6, 0.24);
      this.tweens.add({
        targets: light,
        alpha: { from: 0.12, to: 0.5 },
        duration: 900 + index * 180,
        yoyo: true,
        repeat: -1,
      });
    }

    for (let index = 0; index < 16; index += 1) {
      const mote = this.add.image(Phaser.Math.Between(380, 1180), Phaser.Math.Between(150, 580), "soft-glow");
      mote.setTint(0x6be7d6).setAlpha(0.05).setScale(Phaser.Math.FloatBetween(0.25, 0.7));
      this.tweens.add({
        targets: mote,
        y: mote.y - Phaser.Math.Between(14, 34),
        alpha: { from: 0.02, to: 0.12 },
        duration: Phaser.Math.Between(2400, 5200),
        yoyo: true,
        repeat: -1,
      });
    }
  }

  private createPlayer(): void {
    this.player = new EliAvatar(this, 686, 608);
  }

  private createHud(): void {
    new Panel(this, 24, 18, 304, 108, "Missione");
    this.objectiveText = this.add.text(42, 52, "", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 268 },
      lineSpacing: 4,
    });

    new Panel(this, 24, 622, 304, 74, "Inventario");
    this.inventoryText = this.add.text(42, 654, "", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      wordWrap: { width: 264 },
    });

    this.feedbackText = this.add.text(370, 650, "", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f5fbff",
      backgroundColor: "rgba(8, 19, 28, 0.82)",
      padding: { x: 18, y: 12 },
      wordWrap: { width: 820 },
    });

    new Button(this, 1124, 70, "Diario", () => this.scene.start("JournalScene"), {
      width: 132,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
    new Button(this, 972, 70, "Hub", () => this.scene.start("HubScene"), {
      width: 132,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
  }

  private createHotspots(): void {
    laboratoryObjects.forEach((object) => {
      const layout = this.hotspotLayout(object);
      const complete = object.completedFlag ? saveSystem.data.flags[object.completedFlag] : false;
      const locked = !this.hasRequiredFlags(object);
      const state: DeviceState = complete ? "complete" : locked ? "locked" : this.isCurrentObject(object) ? "active" : "ready";
      const device = SceneChrome.deviceHotspot(
        this,
        layout.x,
        layout.y,
        this.deviceKindFor(object),
        object.label,
        state,
        () => this.moveToObject(object),
        Math.max(70, Math.min(104, layout.radius * 1.58)),
      );
      device
        .on("pointerover", () => {
          audioManager.play("scan");
        });
    });
  }

  private createSceneProps(): void {
    propRenderer.renderLaboratoryProps(
      this,
      laboratoryObjects,
      (object) => this.hotspotLayout(object),
      (object) => Boolean(object.completedFlag && saveSystem.data.flags[object.completedFlag]),
      (object) => !this.hasRequiredFlags(object),
    );
  }

  private deviceKindFor(object: LaboratoryObject): DeviceKind {
    if (object.action === "circuit") return "circuit";
    if (object.action === "terminal") return "terminal";
    if (object.action === "robot") return "robot";
    if (object.action === "door") return "door";
    if (object.action === "grammar") return "language";
    if (object.action === "journal") return "journal";
    if (object.id === "workbench") return "tools";
    if (object.id === "observation-window") return "window";
    if (object.id === "floor-trace") return "trace";
    return "core";
  }

  private isCurrentObject(object: LaboratoryObject): boolean {
    const active = missionEngine.getActiveMission().objectives.find((objective) => missionEngine.getObjectiveStatus(objective) === "active");
    if (!active) {
      return false;
    }
    if (active.id === "grammarFixed") return object.action === "grammar";
    if (active.id === "circuitFixed") return object.action === "circuit";
    if (active.id === "mathLockSolved") return object.action === "terminal";
    if (active.id === "robotKeyRecovered") return object.action === "robot";
    if (active.id === "doorOpened") return object.action === "door";
    return false;
  }

  private moveToObject(object: LaboratoryObject): void {
    audioManager.play("footstep");
    const layout = this.hotspotLayout(object);
    const targetY = Math.min(610, layout.y + layout.radius + 58);
    const arrive = () => {
      this.player?.playInteract();
      this.inspectObject(object);
      audioManager.play("scan");
    };
    if (this.player) {
      this.player.walkTo(layout.x, targetY, arrive);
    } else {
      arrive();
    }
  }

  private inspectObject(object: LaboratoryObject): void {
    this.clearInspectionPanel();
    const panel = this.add.container(24, 142);
    panel.add(this.add.rectangle(0, 0, 304, 468, 0x08131c, 0.96).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.42));
    panel.add(
      this.add.text(20, 18, object.label, {
        fontFamily: "Inter, Arial",
        fontSize: "20px",
        color: "#9ff5e9",
        fontStyle: "bold",
      }),
    );
    panel.add(
      this.add.text(20, 58, object.description, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#d9eaf1",
        wordWrap: { width: 264 },
        lineSpacing: 5,
      }),
    );

    const status = this.objectStatus(object);
    panel.add(
      this.add.text(20, 218, status, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: status.includes("completo") ? "#f7d37a" : "#c9dce6",
        wordWrap: { width: 264 },
        lineSpacing: 4,
      }),
    );

    const hintLine = this.nextHint(object, false);
    panel.add(
      this.add.text(20, 300, hintLine, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f7d37a",
        wordWrap: { width: 264 },
        lineSpacing: 4,
      }),
    );

    const actionButton = new Button(this, 152, 394, object.actionLabel, () => this.performObjectAction(object), {
      width: 252,
      height: 44,
      fontSize: 15,
      fill: this.hasRequiredFlags(object) ? 0x1f4b46 : 0x263743,
    });
    const hintButton = new Button(this, 152, 444, "Chiedi un indizio", () => {
      audioManager.play("hint");
      feedbackSystem.publish(this.nextHint(object, true), "hint");
    }, { width: 252, height: 40, fontSize: 14, fill: 0x142736 });
    panel.add(actionButton);
    panel.add(hintButton);

    this.inspectionPanel = panel;
    if (object.itemReward && this.hasRequiredFlags(object) && !inventorySystem.has(object.itemReward)) {
      inventorySystem.add(object.itemReward);
      this.refreshHud();
      feedbackSystem.publish(`Hai annotato: ${object.itemReward}. Potrebbe tornare utile.`, "info");
    }
  }

  private performObjectAction(object: LaboratoryObject): void {
    if (!this.hasRequiredFlags(object)) {
      feedbackSystem.publish(this.lockedMessage(object), "hint");
      audioManager.play("error");
      return;
    }

    if (object.action === "inspect") {
      feedbackSystem.publish(this.nextHint(object, true), "hint");
      audioManager.play("hint");
      return;
    }

    if (object.action === "journal") {
      this.scene.start("JournalScene");
      return;
    }

    if (object.action === "grammar") {
      this.openGrammarRepair();
      return;
    }

    if (object.action === "circuit") {
      audioManager.play("panelOpen");
      void startScene(this, "CircuitPuzzleScene");
      return;
    }

    if (object.action === "terminal") {
      audioManager.play("panelOpen");
      if (!saveSystem.data.flags.mathLockSolved) {
        void startScene(this, "MathLockScene");
        return;
      }
      if (!saveSystem.data.flags.englishInstructionSolved) {
        this.openEnglishInstruction();
        return;
      }
      feedbackSystem.publish("Il terminale conferma: codice e istruzione operativa acquisiti.", "success");
      return;
    }

    if (object.action === "robot") {
      void startScene(this, "RobotCodingScene");
      return;
    }

    if (object.action === "door") {
      if (!missionEngine.canOpenFinalDoor()) {
        feedbackSystem.publish("La porta controlla una condizione: codice corretto, circuito chiuso e chiave robot.", "hint");
        audioManager.play("error");
        return;
      }
      audioManager.play("doorOpen");
      missionEngine.completeObjective("doorOpened", ["problemSolving", "pensieroCritico"], 16);
      missionEngine.completeMissionOne();
      new DialogueBox(this, dialogueSystem.format("doorOpened"), () => this.scene.start("JournalScene"));
    }
  }

  private hotspotLayout(object: LaboratoryObject): { x: number; y: number; radius: number } {
    const layout = this.mapHotspots[object.id];
    return {
      x: layout?.x ?? object.x,
      y: layout?.y ?? object.y,
      radius: layout?.radius ?? object.radius,
    };
  }

  private hasRequiredFlags(object: LaboratoryObject): boolean {
    return (object.requiredFlags ?? []).every((flag) => saveSystem.data.flags[flag]);
  }

  private objectStatus(object: LaboratoryObject): string {
    if (object.completedFlag && saveSystem.data.flags[object.completedFlag]) {
      return "Stato: sistema completo. Puoi comunque rileggerlo per capire perché ha funzionato.";
    }
    if (!this.hasRequiredFlags(object)) {
      return `Stato: in attesa. ${this.lockedMessage(object)}`;
    }
    return "Stato: pronto. Hai abbastanza indizi per provare una mossa.";
  }

  private lockedMessage(object: LaboratoryObject): string {
    const missing = (object.requiredFlags ?? []).filter((flag) => !saveSystem.data.flags[flag]);
    if (missing.includes("grammarFixed")) {
      return "Il pannello non accetta comandi finché il messaggio corrotto non torna leggibile.";
    }
    if (missing.includes("circuitFixed")) {
      return "Il terminale non ha ancora energia stabile: segui prima il percorso del pannello.";
    }
    if (missing.includes("englishInstructionSolved")) {
      return "Il robot resta in blocco operativo: il terminale deve autorizzare il comando.";
    }
    if (missing.includes("robotKeyRecovered")) {
      return "La porta aspetta la chiave magnetica recuperata dal robot.";
    }
    return "Questo sistema dipende da un indizio precedente.";
  }

  private nextHint(object: LaboratoryObject, advance: boolean): string {
    const current = this.hintCursor[object.id] ?? 0;
    const hint = object.hints[Math.min(current, object.hints.length - 1)];
    if (advance) {
      this.hintCursor[object.id] = Math.min(current + 1, object.hints.length - 1);
    }
    return `Indizio: ${hint}`;
  }

  private openGrammarRepair(): void {
    if (saveSystem.data.flags.grammarFixed) {
      feedbackSystem.publish(`Il messaggio ora è leggibile: ${this.grammarRepairPuzzle.repaired}`, "success");
      return;
    }
    this.clearOverlay();
    const overlay = this.createExerciseScreen("Stabilizzatore linguistico");
    overlay.add(
      this.add.text(48, 94, `Segnale danneggiato: "${this.grammarRepairPuzzle.corrupted}"`, {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: "#f6c85f",
        wordWrap: { width: 1080, useAdvancedWrap: true },
      }),
    );
    overlay.add(
      this.add.text(48, 156, "Obiettivo: ricostruisci una frase chiara ed eseguibile. Prima individua soggetto, verbo e relazioni; poi scegli.", {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#d9eaf1",
        wordWrap: { width: 1080, useAdvancedWrap: true },
      }),
    );

    overlay.add(this.add.rectangle(48, 216, 522, 368, 0x102533, 0.94).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.34));
    overlay.add(this.add.text(72, 238, "Analisi del segnale", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const diagnosticText = this.grammarAnalysisUnlocked
      ? this.grammarRepairPuzzle.diagnosticSteps.map((step, index) => `${index + 1}. ${step}`).join("\n")
      : "Analisi bloccata: il sistema richiede una lettura dei gruppi prima di accettare una soluzione.";
    overlay.add(
      this.add.text(72, 278, diagnosticText, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: this.grammarAnalysisUnlocked ? "#9ff5e9" : "#c9dce6",
        wordWrap: { width: 470, useAdvancedWrap: true },
        lineSpacing: 7,
      }),
    );

    if (!this.grammarAnalysisUnlocked) {
      overlay.add(this.add.rectangle(602, 216, 550, 368, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
      overlay.add(this.add.text(632, 246, "Prima osserva, poi rispondi", {
        fontFamily: "Inter, Arial",
        fontSize: "20px",
        color: "#f7d37a",
        fontStyle: "bold",
      }));
      overlay.add(this.add.text(632, 294, "L'analisi separa le parti della frase e riduce le risposte a tentativo. Dopo la scansione compariranno qui le alternative.", {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#d9eaf1",
        wordWrap: { width: 490, useAdvancedWrap: true },
        lineSpacing: 6,
      }));
      overlay.add(
        new Button(this, 877, 500, "Analizza concordanze", () => {
          this.grammarAnalysisUnlocked = true;
          audioManager.play("scan");
          this.openGrammarRepair();
        }, { width: 360, height: 58, fontSize: 18, fill: 0x173b36 }),
      );
      this.overlay = overlay;
      return;
    }

    overlay.add(this.add.rectangle(602, 216, 550, 368, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(632, 238, "Scegli la frase stabilizzata", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    this.grammarRepairPuzzle.options.forEach((option, index) => {
      overlay.add(
        new Button(
          this,
          877,
          306 + index * 72,
          option,
          () => {
            if (option === this.grammarRepairPuzzle.repaired) {
              missionEngine.completeObjective("grammarFixed", ["italiano.comprensione", "italiano.grammatica"], 16);
              audioManager.play("success");
              VisualKit.outcomeFlash(this, "success", 640, 414, 820, 540);
              VisualKit.particleBurst(this, 640, 394, "lab", "success");
              this.clearOverlay();
              this.scene.restart();
              return;
            }
            this.grammarRepairAttempts += 1;
            const hint = this.grammarRepairPuzzle.hints[Math.min(this.grammarRepairAttempts - 1, this.grammarRepairPuzzle.hints.length - 1)];
            feedbackSystem.publish(`Il messaggio resta instabile. ${hint}`, "hint");
            audioManager.play("error");
            VisualKit.outcomeFlash(this, "warning", 640, 414, 820, 540);
            VisualKit.particleBurst(this, 640, 394, "lab", "warning");
            if (this.grammarRepairAttempts % this.grammarRepairPuzzle.maxAttemptsBeforeReview === 0) {
              this.grammarAnalysisUnlocked = false;
              this.clearOverlay();
              this.time.delayedCall(180, () => this.openGrammarRepair());
            }
          },
          { width: 490, height: 54, fontSize: 14, wordWrapWidth: 452 },
        ),
      );
    });
  }

  private openEnglishInstruction(): void {
    this.clearOverlay();
    const overlay = this.createExerciseScreen("Modulo operativo");
    overlay.add(
      this.add.text(48, 94, this.englishInstructionPuzzle.instruction, {
        fontFamily: "Inter, Arial",
        fontSize: "25px",
        color: "#f5fbff",
        wordWrap: { width: 1080, useAdvancedWrap: true },
      }),
    );
    overlay.add(
      this.add.text(48, 160, "Obiettivo: distingui preparazione, ordine temporale e divieto prima di scegliere l'azione.", {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#c9dce6",
        wordWrap: { width: 1080, useAdvancedWrap: true },
      }),
    );

    overlay.add(this.add.rectangle(48, 216, 522, 368, 0x102533, 0.94).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.34));
    overlay.add(this.add.text(72, 238, "Analisi dell'istruzione", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const diagnostic = this.englishAnalysisUnlocked
      ? this.englishInstructionPuzzle.diagnosticSteps.map((step, index) => `${index + 1}. ${step}`).join("\n")
      : "Analisi bloccata: individua prima verbo d'azione, ordine temporale e negazione.";
    overlay.add(
      this.add.text(72, 278, diagnostic, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: this.englishAnalysisUnlocked ? "#9ff5e9" : "#c9dce6",
        wordWrap: { width: 470, useAdvancedWrap: true },
        lineSpacing: 7,
      }),
    );

    if (!this.englishAnalysisUnlocked) {
      overlay.add(this.add.rectangle(602, 216, 550, 368, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
      overlay.add(this.add.text(632, 246, "Decodifica prima di agire", {
        fontFamily: "Inter, Arial",
        fontSize: "20px",
        color: "#f7d37a",
        fontStyle: "bold",
      }));
      overlay.add(this.add.text(632, 294, "La scansione evidenzia verbo, sequenza e negazione. Le azioni disponibili compariranno qui senza coprire il testo della consegna.", {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#d9eaf1",
        wordWrap: { width: 490, useAdvancedWrap: true },
        lineSpacing: 6,
      }));
      overlay.add(
        new Button(this, 877, 500, "Decodifica istruzione", () => {
          this.englishAnalysisUnlocked = true;
          audioManager.play("scan");
          this.openEnglishInstruction();
        }, { width: 360, height: 58, fontSize: 18, fill: 0x173b36 }),
      );
      this.overlay = overlay;
      return;
    }

    overlay.add(this.add.rectangle(602, 216, 550, 368, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(632, 238, "Scegli l'azione autorizzata", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    this.englishInstructionPuzzle.choices.forEach((choice, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const color = this.colorForEnglishChoice(choice.id);
      overlay.add(
        new Button(
          this,
          742 + col * 270,
          334 + row * 104,
          choice.label,
          () => {
            if (choice.isCorrect) {
              missionEngine.completeObjective("englishInstructionSolved", ["inglese.istruzioni", "pensieroCritico"], 15);
              audioManager.play("success");
              VisualKit.outcomeFlash(this, "success", 640, 404, 820, 520);
              VisualKit.particleBurst(this, 640, 392, "lab", "success");
              this.clearOverlay();
              this.scene.restart();
              return;
            }
            this.englishAttempts += 1;
            feedbackSystem.publish(`${choice.feedback} ${this.englishInstructionPuzzle.hint}`, "hint");
            audioManager.play("error");
            VisualKit.outcomeFlash(this, "error", 640, 404, 820, 520);
            VisualKit.particleBurst(this, 640, 392, "lab", "error");
            if (this.englishAttempts % this.englishInstructionPuzzle.maxAttemptsBeforeReview === 0) {
              this.englishAnalysisUnlocked = false;
              this.clearOverlay();
              this.time.delayedCall(180, () => this.openEnglishInstruction());
            }
          },
          { width: 238, height: 76, fill: color, hoverFill: color + 0x101010, fontSize: 15, wordWrapWidth: 210 },
        ),
      );
    });
  }

  private colorForEnglishChoice(choiceId: string): number {
    if (choiceId.includes("red")) {
      return 0x8c2632;
    }
    if (choiceId.includes("blue")) {
      return 0x23506f;
    }
    if (choiceId.includes("green")) {
      return 0x1f8c63;
    }
    return 0x263743;
  }

  private createExerciseScreen(title: string): Phaser.GameObjects.Container {
    const overlay = this.add.container(40, 0).setDepth(1200);
    SceneChrome.modalInputBlocker(this, overlay, overlay.x, overlay.y);
    if (this.textures.exists("bg-lab-painted")) {
      overlay.add(this.add.image(600, 360, "bg-lab-painted").setDisplaySize(1320, 742).setAlpha(0.34));
    }
    overlay.add(this.add.rectangle(600, 360, 1280, 720, 0x02080d, 0.82));
    const grid = this.add.graphics();
    grid.lineStyle(1, 0x6be7d6, 0.045);
    for (let x = -160; x < 1320; x += 72) {
      grid.lineBetween(x, 0, x - 128, 720);
    }
    for (let y = 92; y < 720; y += 58) {
      grid.lineBetween(-40, y, 1240, y + 10);
    }
    overlay.add(grid);
    overlay.add(this.add.rectangle(600, 34, 1280, 68, 0x06131c, 0.92));
    overlay.add(this.add.rectangle(600, 68, 1280, 2, 0x6be7d6, 0.42));
    overlay.add(this.add.text(0, 14, title, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 1080, useAdvancedWrap: true },
      shadow: { offsetX: 0, offsetY: 3, color: "#000000", blur: 6, fill: true },
    }));
    overlay.add(
      new Button(this, 1184, 34, "X", () => this.clearOverlay(), {
        width: 56,
        height: 42,
        fontSize: 18,
        fill: 0x263743,
      }),
    );
    this.overlay = overlay;
    return overlay;
  }

  private clearOverlay(): void {
    this.overlay?.destroy(true);
    this.overlay = undefined;
  }

  private clearInspectionPanel(): void {
    this.inspectionPanel?.destroy(true);
    this.inspectionPanel = undefined;
  }

  private refreshHud(): void {
    const mission = missionEngine.getActiveMission();
    const active = mission.objectives.find((objective) => missionEngine.getObjectiveStatus(objective) === "active");
    this.objectiveText?.setText(active ? `${active.label}\n${active.description}` : "La porta finale aspetta una verifica completa.");

    const inventory = inventorySystem.list();
    this.inventoryText?.setText(inventory.length > 0 ? inventory.join(", ") : "Nessun oggetto raccolto.");
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
