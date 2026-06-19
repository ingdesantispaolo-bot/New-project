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
import { tiledSceneRenderer } from "../core/TiledSceneRenderer";
import {
  greenhouseAdjustments,
  greenhouseMissionRules,
  type GreenhouseSensor,
  type GreenhouseValues,
  type PlantDefinition,
} from "../data/greenhouse";
import { GreenhouseSimulator, type GreenhouseAction, type PlantNeedProfile } from "../procedural/simulators/GreenhouseSimulator";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type PlantState = {
  definition: PlantDefinition;
  values: GreenhouseValues;
  health: number;
  history: number[];
};

const sensorLabels: Record<GreenhouseSensor, string> = {
  water: "Acqua",
  light: "Luce",
  temperature: "Temp",
};

export class GreenhouseScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getGreenhouseLayout();
  private readonly simulator = new GreenhouseSimulator();
  private plantDefinitions: PlantDefinition[] = exerciseVariantSystem.getGreenhousePlants();
  private plants: PlantState[] = [];
  private selectedPlantId = this.plantDefinitions[0].id;
  private turn = 1;
  private adjustmentUsedThisTurn = false;
  private plantLayer?: Phaser.GameObjects.Container;
  private dataLayer?: Phaser.GameObjects.Container;
  private feedbackText?: Phaser.GameObjects.Text;
  private objectiveText?: Phaser.GameObjects.Text;

  constructor() {
    super("GreenhouseScene");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.restoreOrCreateRun();

    this.drawGreenhouse();
    this.createHud();
    this.refreshScene();

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    if (!saveSystem.data.flags.mission2IntroSeen) {
      saveSystem.setFlag("mission2IntroSeen", true);
      new DialogueBox(this, dialogueSystem.format("mission2Opening"), () => {
        feedbackSystem.publish("La serra non chiede una risposta unica: ogni pianta ha bisogni diversi.", "info");
      });
    }
  }

  private restoreOrCreateRun(): void {
    const run = saveSystem.data.greenhouseRun;
    const validRun = run && run.plants.length === this.plantDefinitions.length;
    if (validRun) {
      this.turn = run.turn;
      this.selectedPlantId = run.selectedPlantId;
      this.adjustmentUsedThisTurn = run.adjustmentUsedThisTurn;
      this.plants = this.plantDefinitions.map((definition) => {
        const savedPlant = run.plants.find((plant) => plant.id === definition.id);
        return {
          definition,
          values: savedPlant ? { ...savedPlant.values } : { ...definition.startingValues },
          health: savedPlant?.health ?? Phaser.Math.Clamp(this.calculateHealth(definition, definition.startingValues) - 18, 0, 100),
          history: savedPlant?.history.length ? [...savedPlant.history] : [],
        };
      });
      this.plants.forEach((plant) => {
        if (plant.history.length === 0) {
          plant.history.push(plant.health);
        }
      });
      return;
    }

    this.plants = this.plantDefinitions.map((definition) => ({
      definition,
      values: { ...definition.startingValues },
      health: Phaser.Math.Clamp(this.calculateHealth(definition, definition.startingValues) - 18, 0, 100),
      history: [],
    }));
    this.plants.forEach((plant) => plant.history.push(plant.health));
    this.persistRun();
  }

  private drawGreenhouse(): void {
    SceneChrome.drawTwoColumnMissionChrome(
      this,
      "greenhouse",
      "La Serra Biologica",
      "Leggi i dati, fai una regolazione per turno, osserva le conseguenze.",
      "Serra automatizzata",
    );
    VisualKit.cinematicDepth(this, "greenhouse", 0.85);
    tiledSceneRenderer.renderBackdrop(this, "greenhouse");

    const glass = this.add.graphics();
    glass.fillStyle(0x0b221f, 0.22);
    glass.fillRect(48, 130, 744, 488);
    glass.lineStyle(2, 0x70d68a, 0.2);
    glass.strokeRect(48, 130, 744, 488);
    VisualKit.glowFrame(this, 38, 120, 764, 508, "greenhouse");
    this.drawGrowPodShells();
    for (let x = 96; x < 760; x += 88) {
      glass.lineBetween(x, 130, x - 80, 618);
    }
    for (let y = 190; y < 600; y += 78) {
      glass.lineBetween(48, y, 792, y);
    }

    this.add.rectangle(420, 594, 682, 54, 0x173027, 0.42).setStrokeStyle(1, 0x70d68a, 0.36);
    VisualKit.scanLine(this, 420, 374, 706, 450, "greenhouse");
    for (let index = 0; index < 18; index += 1) {
      const mote = this.add.image(Phaser.Math.Between(70, 760), Phaser.Math.Between(150, 570), "soft-glow");
      mote.setTint(0x70d68a).setAlpha(0.04).setScale(Phaser.Math.FloatBetween(0.35, 0.9));
      this.tweens.add({
        targets: mote,
        y: mote.y - Phaser.Math.Between(16, 42),
        alpha: { from: 0.03, to: 0.12 },
        duration: Phaser.Math.Between(2200, 5200),
        yoyo: true,
        repeat: -1,
      });
    }
  }

  private drawGrowPodShells(): void {
    const pods = [
      { x: 190, y: 400, w: 170, h: 286 },
      { x: 420, y: 392, w: 180, h: 302 },
      { x: 650, y: 404, w: 170, h: 286 },
    ];
    pods.forEach((pod, index) => {
      const podTexture = this.textureKey("painted-greenhouse-pod", "prop-greenhouse-pod");
      if (podTexture) {
        this.add.image(pod.x, pod.y - 4, podTexture).setDisplaySize(pod.w * 1.22, pod.h * 0.98).setAlpha(0.9);
      } else {
        this.add.ellipse(pod.x, pod.y - 106, pod.w, 38, 0xf7d37a, 0.1).setStrokeStyle(1, 0xf7d37a, 0.36);
        this.add.rectangle(pod.x, pod.y - 28, pod.w, pod.h, 0x9ff5e9, 0.025).setStrokeStyle(2, 0x70d68a, 0.22);
        this.add.ellipse(pod.x, pod.y + 116, pod.w, 34, 0x70d68a, 0.05).setStrokeStyle(1, 0x70d68a, 0.24);
      }
      const cone = this.add.triangle(pod.x, pod.y - 4, -72, -112, 72, -112, 0, 112, 0xf7d37a, 0.055);
      cone.setAlpha(0.04 + index * 0.012);
      this.tweens.add({
        targets: cone,
        alpha: { from: 0.025, to: 0.085 },
        duration: 1800 + index * 500,
        yoyo: true,
        repeat: -1,
      });
    });
  }

  private createHud(): void {
    SceneChrome.consolePanel(this, 820, 130, 420, 136, "Obiettivo", "greenhouse");
    this.objectiveText = this.add.text(842, 166, "", {
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
    this.plantLayer?.destroy(true);
    this.dataLayer?.destroy(true);
    this.plantLayer = this.add.container(0, 0);
    this.dataLayer = this.add.container(0, 0);
    this.drawPlants();
    this.drawDataPanel();
    this.updateObjective();
  }

  private drawPlants(): void {
    const positions = [0, 1, 2].map((index) => this.rect(`greenhouse:plant:${index}`, {
      x: 190 + index * 230,
      y: index === 1 ? 410 : index === 0 ? 420 : 424,
      width: index === 1 ? 180 : 170,
      height: index === 1 ? 302 : 286,
    }));

    this.plants.forEach((plant, index) => {
      const pos = positions[index];
      const selected = plant.definition.id === this.selectedPlantId;
      const saved = plant.health >= greenhouseMissionRules.savedHealth;
      const pot = this.add.container(pos.x, pos.y);
      pot.add(this.add.ellipse(0, 114, 174, 24, 0x000000, 0.28));
      pot.add(this.add.rectangle(0, 72, 148, 68, 0x51372c, 0.96).setStrokeStyle(2, selected ? 0xf6c85f : 0x8a5c46, 0.9));
      pot.add(this.add.rectangle(0, 38, 132, 28, 0x3a2a22, 0.98));
      pot.add(this.add.ellipse(0, 38, 132, 24, 0x2d211a, 1));
      pot.add(this.add.rectangle(0, 108, 166, 18, 0x19271f, 0.85));
      pot.add(VisualKit.statusLight(this, 60, -58, saved ? 0x70d68a : plant.health > 45 ? 0xf7d37a : 0xff8a66, selected));

      const stemColor = saved ? 0x70d68a : plant.health > 45 ? 0xa6bf63 : 0x85794a;
      pot.add(this.add.rectangle(0, -8, 10, 100, stemColor, 1));
      for (let leaf = 0; leaf < 7; leaf += 1) {
        const side = leaf % 2 === 0 ? -1 : 1;
        const y = -54 + leaf * 15;
        const leafShape = this.add.ellipse(side * (26 + leaf * 2), y, 68 - leaf * 4, 28, stemColor, plant.health > 35 ? 0.95 : 0.55);
        leafShape.setRotation(side * -0.42);
        pot.add(leafShape);
        pot.add(this.add.line(side * (24 + leaf * 2), y, 0, 0, side * 22, -4, 0xe6ffd5, plant.health > 45 ? 0.18 : 0.08));
      }

      pot.add(this.add.text(-72, 132, plant.definition.name, {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: selected ? "#f7d37a" : "#f5fbff",
        fontStyle: selected ? "bold" : "normal",
      }));
      pot.add(this.add.text(-70, 154, `Vitalità ${Math.round(plant.health)}%`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: saved ? "#9ff5e9" : "#d9eaf1",
      }));
      pot.setSize(180, 230);
      const hitTarget = this.add.rectangle(0, 35, 180, 250, 0x000000, 0.001).setInteractive();
      if (hitTarget.input) hitTarget.input.cursor = "pointer";
      let armed = false;
      hitTarget
        .on("pointerdown", () => {
          armed = true;
        })
        .on("pointerup", () => {
          if (!armed) return;
          armed = false;
          this.selectedPlantId = plant.definition.id;
          this.persistRun();
          audioManager.play("scan");
          this.refreshScene();
          feedbackSystem.publish(plant.definition.leafClues[Math.min(this.turn - 1, plant.definition.leafClues.length - 1)], "hint");
        })
        .on("pointerupoutside", () => {
          armed = false;
        });
      pot.add(hitTarget);
      this.plantLayer?.add(pot);

      if (selected) {
        const pulse = this.add.circle(pos.x, pos.y + 20, 106, 0xf6c85f, 0.06).setStrokeStyle(2, 0xf6c85f, 0.34);
        this.tweens.add({ targets: pulse, scale: 1.08, alpha: 0.55, duration: 980, yoyo: true, repeat: -1 });
        this.plantLayer?.add(pulse);
      }
    });
  }

  private drawDataPanel(): void {
    const selected = this.getSelectedPlant();
    const savedCount = this.countSavedPlants();
    const panel = this.rect("greenhouse:dataPanel", { x: 820, y: 288, width: 420, height: 326 });
    this.dataLayer?.add(SceneChrome.consolePanel(this, panel.x, panel.y, panel.width ?? 420, panel.height ?? 326, "Console bio-dati", "greenhouse"));
    const sensorTexture = this.textures.exists("painted-greenhouse-sensor") ? "painted-greenhouse-sensor" : undefined;
    if (sensorTexture) {
      this.dataLayer?.add(this.add.image(panel.x + 332, panel.y + 86, sensorTexture).setDisplaySize(96, 96).setAlpha(0.78));
    }
    this.dataLayer?.add(this.add.text(panel.x + 22, panel.y + 58, selected.definition.name, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    this.dataLayer?.add(this.add.text(panel.x + 22, panel.y + 92, selected.definition.scientificHint, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#c9dce6",
      wordWrap: { width: 372 },
      lineSpacing: 4,
    }));
    this.dataLayer?.add(this.add.text(panel.x + 22, panel.y + 146, `Lab note: ${selected.definition.englishNote}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      wordWrap: { width: 372 },
    }));

    this.drawSensorTable(selected);
    this.drawGraph(selected);
    this.drawControls(savedCount);
  }

  private drawSensorTable(plant: PlantState): void {
    const table = this.rect("greenhouse:sensorTable", { x: 842, y: 444, width: 330, height: 104 });
    const x = table.x;
    const y = table.y;
    this.dataLayer?.add(this.add.text(x, y, "Tabella dati", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    (["water", "light", "temperature"] as GreenhouseSensor[]).forEach((sensor, index) => {
      const rowY = y + 30 + index * 28;
      const value = Math.round(plant.values[sensor]);
      const ideal = plant.definition.idealValues[sensor];
      this.dataLayer?.add(this.add.text(x, rowY, sensorLabels[sensor], {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#d9eaf1",
      }));
      this.dataLayer?.add(this.add.text(x + 128, rowY, `${value}`, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: this.sensorIsHealthy(plant, sensor) ? "#9ff5e9" : "#f7d37a",
      }));
      this.dataLayer?.add(this.add.text(x + 210, rowY, `zona ${ideal}`, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#9aaab0",
      }));
    });
  }

  private drawGraph(plant: PlantState): void {
    const graphLayout = this.rect("greenhouse:graph", { x: 1018, y: 506, width: 168, height: 96 });
    const x = graphLayout.x;
    const y = graphLayout.y;
    const width = graphLayout.width ?? 168;
    const height = graphLayout.height ?? 96;
    this.dataLayer?.add(this.add.text(x, y - 62, "Grafico vitalità", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    this.dataLayer?.add(this.add.rectangle(x + width / 2, y, width, height, 0x071018, 0.8).setStrokeStyle(1, 0x315766, 0.8));
    const graph = this.add.graphics();
    graph.lineStyle(1, 0x315766, 0.6);
    for (let i = 0; i < 4; i += 1) {
      graph.lineBetween(x, y - height / 2 + i * (height / 3), x + width, y - height / 2 + i * (height / 3));
    }
    graph.lineStyle(3, 0xf6c85f, 0.95);
    const points = plant.history.map((health, index) => ({
      x: x + index * (width / Math.max(1, greenhouseMissionRules.maxTurns)),
      y: y + height / 2 - Phaser.Math.Clamp(health, 0, 100) * (height / 100),
    }));
    if (points.length > 0) {
      graph.beginPath();
      graph.moveTo(points[0].x, points[0].y);
      points.slice(1).forEach((point) => graph.lineTo(point.x, point.y));
      graph.strokePath();
      points.forEach((point) => graph.fillCircle(point.x, point.y, 4));
    }
    this.dataLayer?.add(graph);
  }

  private drawControls(savedCount: number): void {
    const valveTexture = this.textures.exists("painted-greenhouse-valve") ? "painted-greenhouse-valve" : undefined;
    if (valveTexture) {
      this.dataLayer?.add(this.add.image(744, 642, valveTexture).setDisplaySize(116, 82).setAlpha(0.78));
    }
    this.dataLayer?.add(this.add.text(76, 142, `Turno ${this.turn}/${greenhouseMissionRules.maxTurns}`, {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    this.dataLayer?.add(this.add.text(76, 172, `Piante salvate: ${savedCount}/${greenhouseMissionRules.plantsToSave}`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: savedCount >= greenhouseMissionRules.plantsToSave ? "#9ff5e9" : "#d9eaf1",
    }));

    greenhouseAdjustments.forEach((adjustment, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      this.dataLayer?.add(
        new Button(this, 894 + col * 112, 650 + row * 44, adjustment.label, () => this.adjustSelected(adjustment.sensor, adjustment.delta), {
          width: 98,
          height: 38,
          fontSize: 14,
          fill: this.adjustmentUsedThisTurn ? 0x263743 : 0x1f4b46,
        }),
      );
    });
    this.dataLayer?.add(
      new Button(this, 1098, 600, "Avanza turno", () => this.advanceTurn(), {
        width: 210,
        height: 44,
        fontSize: 17,
        fill: 0x173b36,
      }),
    );
    this.dataLayer?.add(
      new Button(this, 882, 600, "Leggi sensori", () => this.readSensors(), {
        width: 176,
        height: 44,
        fontSize: 16,
        fill: 0x142736,
      }),
    );
  }

  private readSensors(): void {
    if (!saveSystem.data.flags.plantSensorsRead) {
      missionEngine.completeObjective("plantSensorsRead", ["scienze.osservazione", "scienze.dati", "matematica.logica"], 14);
    }
    const plant = this.getSelectedPlant();
    audioManager.play("scan");
    feedbackSystem.publish(
      `${plant.definition.name}: acqua ${Math.round(plant.values.water)}, luce ${Math.round(plant.values.light)}, temperatura ${Math.round(plant.values.temperature)}. I numeri sono indizi, non comandi automatici.`,
      "info",
    );
    this.refreshScene();
  }

  private adjustSelected(sensor: GreenhouseSensor, delta: number): void {
    if (!saveSystem.data.flags.plantSensorsRead) {
      feedbackSystem.publish("Prima leggi i sensori: intervenire senza dati rischia di peggiorare la serra.", "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1010, 452, 420, 330);
      return;
    }
    if (this.adjustmentUsedThisTurn) {
      feedbackSystem.publish("Un solo intervento per turno: ora osserva la conseguenza prima di cambiare altro.", "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1010, 452, 420, 330);
      return;
    }

    const plant = this.getSelectedPlant();
    const beforeHealthy = this.sensorIsHealthy(plant, sensor);
    const next = this.simulator.applyAction(this.toProfile(plant.definition), { ...plant.values, health: plant.health }, { type: sensor, delta } as GreenhouseAction);
    plant.values = {
      water: this.clampSensor("water", next.water),
      light: this.clampSensor("light", next.light),
      temperature: this.clampSensor("temperature", next.temperature),
    };
    plant.health = next.health;
    this.adjustmentUsedThisTurn = true;
    this.persistRun();
    if (!saveSystem.data.flags.plantCareStarted) {
      missionEngine.completeObjective("plantCareStarted", ["scienze.sistemi", "scienze.dati", "problemSolving"], 12);
    }
    audioManager.play("panelOpen");
    const nowHealthy = this.sensorIsHealthy(plant, sensor);
    feedbackSystem.publish(this.adjustmentFeedback(plant, sensor), nowHealthy ? "success" : "hint");
    VisualKit.particleBurst(this, 190 + this.plants.indexOf(plant) * 230, 420, "greenhouse", nowHealthy ? "success" : beforeHealthy ? "warning" : "warning");
    VisualKit.outcomeFlash(this, nowHealthy ? "success" : "warning", 420, 390, 760, 500);
    this.refreshScene();
  }

  private advanceTurn(): void {
    if (!saveSystem.data.flags.plantSensorsRead) {
      feedbackSystem.publish("La serra registra un turno solo dopo una lettura dei sensori.", "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 640, 360, 960, 500);
      return;
    }

    this.plants.forEach((plant) => {
      const targetHealth = this.calculateHealth(plant.definition, plant.values);
      const drift = targetHealth >= greenhouseMissionRules.savedHealth ? 10 : -7;
      plant.health = Phaser.Math.Clamp(plant.health + (targetHealth - plant.health) * 0.34 + drift, 0, 100);
      plant.history.push(plant.health);
    });

    this.turn += 1;
    this.adjustmentUsedThisTurn = false;
    const saved = this.plants.filter((plant) => plant.health >= greenhouseMissionRules.savedHealth);
    if (saved.length >= greenhouseMissionRules.plantsToSave) {
      missionEngine.completeObjective("greenhouseStabilized", [
        "scienze.osservazione",
        "scienze.sistemi",
        "scienze.dati",
        "matematica.logica",
        "matematica.grafici",
        "inglese.scientifico",
        "problemSolving",
        "pensieroCritico",
      ], 18);
      audioManager.play("success");
      missionEngine.completeMissionTwo(saved.map((plant) => plant.definition.name));
      saveSystem.setGreenhouseRun(undefined);
      feedbackSystem.publish("La serra riapre le prese d'aria: tre piante hanno superato la soglia vitale.", "success");
      VisualKit.outcomeFlash(this, "success");
      [190, 420, 650].forEach((x) => VisualKit.particleBurst(this, x, 390, "greenhouse", "success"));
      this.time.delayedCall(1100, () => this.scene.start("JournalScene"));
      return;
    }

    if (this.turn > greenhouseMissionRules.maxTurns) {
      audioManager.play("error");
      feedbackSystem.publish(
        "La serra resta instabile. I dati del grafico mostrano quali piante hanno reagito meglio: puoi riprovare regolando una variabile alla volta.",
        "warning",
      );
      VisualKit.outcomeFlash(this, "error", 420, 390, 760, 500);
      this.turn = greenhouseMissionRules.maxTurns;
      this.adjustmentUsedThisTurn = false;
      this.persistRun();
      this.refreshScene();
      return;
    }

    audioManager.play("hint");
    feedbackSystem.publish(this.turnFeedback(), "info");
    VisualKit.outcomeFlash(this, "warning", 420, 390, 760, 500);
    this.persistRun();
    this.refreshScene();
  }

  private persistRun(): void {
    saveSystem.setGreenhouseRun({
      turn: this.turn,
      selectedPlantId: this.selectedPlantId,
      adjustmentUsedThisTurn: this.adjustmentUsedThisTurn,
      plants: this.plants.map((plant) => ({
        id: plant.definition.id,
        values: { ...plant.values },
        health: plant.health,
        history: [...plant.history],
      })),
    });
  }

  private calculateHealth(definition: PlantDefinition, values: GreenhouseValues): number {
    return Phaser.Math.Clamp(this.simulator.scorePlant(this.toProfile(definition), { ...values, health: 0 }), 8, 100);
  }

  private adjustmentFeedback(plant: PlantState, sensor: GreenhouseSensor): string {
    const value = Math.round(plant.values[sensor]);
    const ideal = plant.definition.idealValues[sensor];
    if (this.sensorIsHealthy(plant, sensor)) {
      return `${plant.definition.name}: ${sensorLabels[sensor].toLowerCase()} ${value}. Il valore si avvicina alla zona vitale indicata dai dati.`;
    }
    return `${plant.definition.name}: ${sensorLabels[sensor].toLowerCase()} ${value}. La zona utile è intorno a ${ideal}. ${this.simulator.explain(this.toProfile(plant.definition), { ...plant.values, health: plant.health })}`;
  }

  private toProfile(definition: PlantDefinition): PlantNeedProfile {
    return {
      id: definition.id,
      ideal: { ...definition.idealValues },
      tolerance: { ...definition.tolerance },
    };
  }

  private turnFeedback(): string {
    const weakest = [...this.plants].sort((a, b) => a.health - b.health)[0];
    const clue = weakest.definition.leafClues[Math.min(this.turn - 1, weakest.definition.leafClues.length - 1)];
    return `${weakest.definition.name} è ancora la più fragile. ${clue}`;
  }

  private sensorIsHealthy(plant: PlantState, sensor: GreenhouseSensor): boolean {
    return Math.abs(plant.values[sensor] - plant.definition.idealValues[sensor]) <= plant.definition.tolerance[sensor];
  }

  private clampSensor(sensor: GreenhouseSensor, value: number): number {
    if (sensor === "temperature") {
      return Phaser.Math.Clamp(value, 14, 34);
    }
    return Phaser.Math.Clamp(value, 0, 100);
  }

  private getSelectedPlant(): PlantState {
    return this.plants.find((plant) => plant.definition.id === this.selectedPlantId) ?? this.plants[0];
  }

  private countSavedPlants(): number {
    return this.plants.filter((plant) => plant.health >= greenhouseMissionRules.savedHealth).length;
  }

  private updateObjective(): void {
    const mission = missionEngine.getMission("mission-02-serra-biologica") ?? missionEngine.getActiveMission();
    const active = mission.objectives.find((objective) => missionEngine.getObjectiveStatus(objective) === "active");
    this.objectiveText?.setText(
      active
        ? `${active.label}\n${active.description}`
        : `Salva ${greenhouseMissionRules.plantsToSave} piante usando sensori, tabella e grafico.`,
    );
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
