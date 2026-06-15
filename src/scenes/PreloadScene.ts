import Phaser from "phaser";
import academyPaintedBgUrl from "../assets/images/academy-painted-bg.webp";
import archivePaintedBgUrl from "../assets/images/archive-painted-bg.webp";
import archiveConsoleUrl from "../assets/images/console-archive.webp";
import factoryConsoleUrl from "../assets/images/console-factory.webp";
import greenhouseConsoleUrl from "../assets/images/console-greenhouse.webp";
import labConsoleUrl from "../assets/images/console-lab.webp";
import factoryPaintedBgUrl from "../assets/images/factory-painted-bg.webp";
import greenhousePaintedBgUrl from "../assets/images/greenhouse-painted-bg.webp";
import labPaintedBgUrl from "../assets/images/lab-painted-bg.webp";
import eliQuestAtlasUrl from "../assets/sprites/eli-quest-atlas.webp";
import eliQuestAtlasJsonUrl from "../assets/sprites/eli-quest-atlas.json?url";
import propCircuitPanelUrl from "../assets/props/prop-circuit-panel.webp";
import propDoorLabUrl from "../assets/props/prop-door-lab.webp";
import propFloorTraceUrl from "../assets/props/prop-floor-trace.webp";
import propJournalUrl from "../assets/props/prop-journal.webp";
import propMessageConsoleUrl from "../assets/props/prop-message-console.webp";
import propNoraCoreUrl from "../assets/props/prop-nora-core.webp";
import propRobotDockUrl from "../assets/props/prop-robot-dock.webp";
import propTerminalUrl from "../assets/props/prop-terminal.webp";
import propWindowUrl from "../assets/props/prop-window.webp";
import propWorkbenchUrl from "../assets/props/prop-workbench.webp";
import paintedCircuitPanelUrl from "../assets/painted/props/painted-circuit-panel.webp";
import paintedDoorLabUrl from "../assets/painted/props/painted-door-lab.webp";
import paintedArchiveDeskUrl from "../assets/painted/props/painted-archive-desk.webp";
import paintedArchiveShelfUrl from "../assets/painted/props/painted-archive-shelf.webp";
import paintedArchiveTerminalUrl from "../assets/painted/props/painted-archive-terminal.webp";
import paintedFactoryConveyorUrl from "../assets/painted/props/painted-factory-conveyor.webp";
import paintedFactoryCoreUrl from "../assets/painted/props/painted-factory-core.webp";
import paintedFactoryMachineUrl from "../assets/painted/props/painted-factory-machine.webp";
import paintedGreenhousePodUrl from "../assets/painted/props/painted-greenhouse-pod.webp";
import paintedGreenhouseSensorUrl from "../assets/painted/props/painted-greenhouse-sensor.webp";
import paintedGreenhouseValveUrl from "../assets/painted/props/painted-greenhouse-valve.webp";
import paintedJournalUrl from "../assets/painted/props/painted-journal.webp";
import paintedMessageConsoleUrl from "../assets/painted/props/painted-message-console.webp";
import paintedNoraCoreUrl from "../assets/painted/props/painted-nora-core.webp";
import paintedRobotDockUrl from "../assets/painted/props/painted-robot-dock.webp";
import paintedTerminalUrl from "../assets/painted/props/painted-terminal.webp";
import paintedWorkbenchUrl from "../assets/painted/props/painted-workbench.webp";

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("PreloadScene");
  }

  preload(): void {
    this.load.image("bg-academy-painted", academyPaintedBgUrl);
    this.load.image("bg-archive-painted", archivePaintedBgUrl);
    this.load.image("bg-factory-painted", factoryPaintedBgUrl);
    this.load.image("bg-greenhouse-painted", greenhousePaintedBgUrl);
    this.load.image("bg-lab-painted", labPaintedBgUrl);
    this.load.image("console-archive", archiveConsoleUrl);
    this.load.image("console-factory", factoryConsoleUrl);
    this.load.image("console-greenhouse", greenhouseConsoleUrl);
    this.load.image("console-lab", labConsoleUrl);
    this.load.image("prop-circuit-panel", propCircuitPanelUrl);
    this.load.image("prop-door-lab", propDoorLabUrl);
    this.load.image("prop-floor-trace", propFloorTraceUrl);
    this.load.image("prop-journal", propJournalUrl);
    this.load.image("prop-message-console", propMessageConsoleUrl);
    this.load.image("prop-nora-core", propNoraCoreUrl);
    this.load.image("prop-robot-dock", propRobotDockUrl);
    this.load.image("prop-terminal", propTerminalUrl);
    this.load.image("prop-window", propWindowUrl);
    this.load.image("prop-workbench", propWorkbenchUrl);
    this.load.image("painted-circuit-panel", paintedCircuitPanelUrl);
    this.load.image("painted-door-lab", paintedDoorLabUrl);
    this.load.image("painted-archive-desk", paintedArchiveDeskUrl);
    this.load.image("painted-archive-shelf", paintedArchiveShelfUrl);
    this.load.image("painted-archive-terminal", paintedArchiveTerminalUrl);
    this.load.image("painted-factory-conveyor", paintedFactoryConveyorUrl);
    this.load.image("painted-factory-core", paintedFactoryCoreUrl);
    this.load.image("painted-factory-machine", paintedFactoryMachineUrl);
    this.load.image("painted-greenhouse-pod", paintedGreenhousePodUrl);
    this.load.image("painted-greenhouse-sensor", paintedGreenhouseSensorUrl);
    this.load.image("painted-greenhouse-valve", paintedGreenhouseValveUrl);
    this.load.image("painted-journal", paintedJournalUrl);
    this.load.image("painted-message-console", paintedMessageConsoleUrl);
    this.load.image("painted-nora-core", paintedNoraCoreUrl);
    this.load.image("painted-robot-dock", paintedRobotDockUrl);
    this.load.image("painted-terminal", paintedTerminalUrl);
    this.load.image("painted-workbench", paintedWorkbenchUrl);
    this.load.atlas("eli-atlas", eliQuestAtlasUrl, eliQuestAtlasJsonUrl);
  }

  create(): void {
    const graphics = this.add.graphics();
    graphics.fillStyle(0x6be7d6, 1);
    graphics.fillCircle(16, 16, 16);
    graphics.generateTexture("soft-glow", 32, 32);
    graphics.clear();
    graphics.fillStyle(0xf6c85f, 1);
    graphics.fillTriangle(16, 0, 32, 32, 0, 32);
    graphics.generateTexture("robot-pointer", 32, 32);
    graphics.clear();
    graphics.lineStyle(2, 0x6be7d6, 0.8);
    graphics.strokeCircle(32, 32, 26);
    graphics.lineStyle(1, 0xf6c85f, 0.55);
    graphics.strokeCircle(32, 32, 12);
    graphics.generateTexture("holo-ring", 64, 64);
    graphics.clear();
    graphics.fillStyle(0xffffff, 1);
    graphics.fillCircle(8, 8, 8);
    graphics.generateTexture("spark-core", 16, 16);
    graphics.destroy();

    this.scene.start("MainMenuScene");
  }
}
