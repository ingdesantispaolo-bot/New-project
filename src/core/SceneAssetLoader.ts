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
import missionCodingBgUrl from "../assets/images/mission-coding-bg.webp";
import missionCodingRobotBgUrl from "../assets/images/mission-coding-robot-bg.webp";
import missionCodingTerminalBgUrl from "../assets/images/mission-coding-terminal-bg.webp";
import missionElectronicsBgUrl from "../assets/images/mission-electronics-bg.webp";
import missionElectronicsBenchBgUrl from "../assets/images/mission-electronics-bench-bg.webp";
import missionElectronicsPowerBgUrl from "../assets/images/mission-electronics-power-bg.webp";
import missionEnglishBgUrl from "../assets/images/mission-english-bg.webp";
import missionEnglishControlBgUrl from "../assets/images/mission-english-control-bg.webp";
import missionEnglishRadioBgUrl from "../assets/images/mission-english-radio-bg.webp";
import missionItalianBgUrl from "../assets/images/mission-italian-bg.webp";
import missionItalianArchiveBgUrl from "../assets/images/mission-italian-archive-bg.webp";
import missionItalianLibraryBgUrl from "../assets/images/mission-italian-library-bg.webp";
import missionMathBgUrl from "../assets/images/mission-math-bg.webp";
import missionMathFactoryBgUrl from "../assets/images/mission-math-factory-bg.webp";
import missionMathGridBgUrl from "../assets/images/mission-math-grid-bg.webp";
import missionMusicBgUrl from "../assets/images/mission-music-bg.webp";
import missionMusicAudioBgUrl from "../assets/images/mission-music-audio-bg.webp";
import missionMusicStaffBgUrl from "../assets/images/mission-music-staff-bg.webp";
import missionSynthesisBgUrl from "../assets/images/mission-synthesis-bg.webp";
import storyAcademyHubBgUrl from "../assets/images/story-academy-hub-bg.webp";
import storyArchiveMemoryBgUrl from "../assets/images/story-archive-memory-bg.webp";
import storyGreenhouseRecoveryBgUrl from "../assets/images/story-greenhouse-recovery-bg.webp";
import storyLabBlackoutBgUrl from "../assets/images/story-lab-blackout-bg.webp";
import storyNumberFactoryBgUrl from "../assets/images/story-number-factory-bg.webp";
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
import outcomeDefeatUrl from "../assets/images/outcomes/outcome-defeat.webp";
import outcomeDevastatingDefeatUrl from "../assets/images/outcomes/outcome-devastating-defeat.webp";
import outcomeGrandVictoryUrl from "../assets/images/outcomes/outcome-grand-victory.webp";
import outcomeLightVictoryUrl from "../assets/images/outcomes/outcome-light-victory.webp";
import outcomeNeutralUrl from "../assets/images/outcomes/outcome-neutral.webp";

export type SceneAssetPack = "academy" | "lab" | "greenhouse" | "factory" | "archive" | "procedural" | "story";

const packs: Record<SceneAssetPack, Array<[string, string]>> = {
  academy: [["bg-academy-painted", academyPaintedBgUrl]],
  lab: [
    ["bg-lab-painted", labPaintedBgUrl], ["console-lab", labConsoleUrl],
    ["prop-circuit-panel", propCircuitPanelUrl], ["prop-door-lab", propDoorLabUrl],
    ["prop-floor-trace", propFloorTraceUrl], ["prop-journal", propJournalUrl],
    ["prop-message-console", propMessageConsoleUrl], ["prop-nora-core", propNoraCoreUrl],
    ["prop-robot-dock", propRobotDockUrl], ["prop-terminal", propTerminalUrl],
    ["prop-window", propWindowUrl], ["prop-workbench", propWorkbenchUrl],
    ["painted-circuit-panel", paintedCircuitPanelUrl], ["painted-door-lab", paintedDoorLabUrl],
    ["painted-journal", paintedJournalUrl], ["painted-message-console", paintedMessageConsoleUrl],
    ["painted-nora-core", paintedNoraCoreUrl], ["painted-robot-dock", paintedRobotDockUrl],
    ["painted-terminal", paintedTerminalUrl], ["painted-workbench", paintedWorkbenchUrl],
  ],
  greenhouse: [
    ["bg-greenhouse-painted", greenhousePaintedBgUrl], ["console-greenhouse", greenhouseConsoleUrl],
    ["painted-greenhouse-pod", paintedGreenhousePodUrl], ["painted-greenhouse-sensor", paintedGreenhouseSensorUrl],
    ["painted-greenhouse-valve", paintedGreenhouseValveUrl],
  ],
  factory: [
    ["bg-factory-painted", factoryPaintedBgUrl], ["console-factory", factoryConsoleUrl],
    ["painted-factory-conveyor", paintedFactoryConveyorUrl], ["painted-factory-core", paintedFactoryCoreUrl],
    ["painted-factory-machine", paintedFactoryMachineUrl],
  ],
  archive: [
    ["bg-archive-painted", archivePaintedBgUrl], ["console-archive", archiveConsoleUrl],
    ["painted-archive-desk", paintedArchiveDeskUrl], ["painted-archive-shelf", paintedArchiveShelfUrl],
    ["painted-archive-terminal", paintedArchiveTerminalUrl],
  ],
  story: [
    ["story-academy-hub-bg", storyAcademyHubBgUrl],
    ["story-archive-memory-bg", storyArchiveMemoryBgUrl],
    ["story-greenhouse-recovery-bg", storyGreenhouseRecoveryBgUrl],
    ["story-lab-blackout-bg", storyLabBlackoutBgUrl],
    ["story-number-factory-bg", storyNumberFactoryBgUrl],
  ],
  procedural: [
    ["bg-lab-painted", labPaintedBgUrl], ["console-lab", labConsoleUrl],
    ["mission-bg-coding", missionCodingBgUrl], ["mission-bg-electronics", missionElectronicsBgUrl],
    ["mission-bg-english", missionEnglishBgUrl], ["mission-bg-italian", missionItalianBgUrl],
    ["mission-bg-math", missionMathBgUrl], ["mission-bg-music", missionMusicBgUrl],
    ["mission-coding-robot-bg", missionCodingRobotBgUrl], ["mission-coding-terminal-bg", missionCodingTerminalBgUrl],
    ["mission-electronics-bench-bg", missionElectronicsBenchBgUrl], ["mission-electronics-power-bg", missionElectronicsPowerBgUrl],
    ["mission-english-control-bg", missionEnglishControlBgUrl], ["mission-english-radio-bg", missionEnglishRadioBgUrl],
    ["mission-italian-archive-bg", missionItalianArchiveBgUrl], ["mission-italian-library-bg", missionItalianLibraryBgUrl],
    ["mission-math-factory-bg", missionMathFactoryBgUrl], ["mission-math-grid-bg", missionMathGridBgUrl],
    ["mission-music-audio-bg", missionMusicAudioBgUrl], ["mission-music-staff-bg", missionMusicStaffBgUrl],
    ["mission-bg-synthesis", missionSynthesisBgUrl],
    ["outcome-defeat", outcomeDefeatUrl], ["outcome-devastating-defeat", outcomeDevastatingDefeatUrl],
    ["outcome-grand-victory", outcomeGrandVictoryUrl], ["outcome-light-victory", outcomeLightVictoryUrl],
    ["outcome-neutral", outcomeNeutralUrl],
  ],
};

export function queueSceneAssets(scene: Phaser.Scene, ...requestedPacks: SceneAssetPack[]): void {
  const entries = requestedPacks.flatMap((pack) => packs[pack]);
  const unique = new Map(entries);
  unique.forEach((url, key) => {
    if (!scene.textures.exists(key)) scene.load.image(key, url);
  });
}
