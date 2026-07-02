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
import logicGymFirewallBgUrl from "../assets/images/logic-gym-firewall-bg.png";
import missionAtlasBgUrl from "../assets/images/mission-atlas-bg.webp";
import progressiveScalataBgUrl from "../assets/images/progressive-scalata-bg.webp";
import storyAcademyHubBgUrl from "../assets/images/story-academy-hub-bg.webp";
import storyArchiveMemoryBgUrl from "../assets/images/story-archive-memory-bg.webp";
import storyChapter01IntroUrl from "../assets/images/story-chapter-01-intro.webp";
import storyChapter01OutroUrl from "../assets/images/story-chapter-01-outro.webp";
import storyChapter02IntroUrl from "../assets/images/story-chapter-02-intro.webp";
import storyChapter02OutroUrl from "../assets/images/story-chapter-02-outro.webp";
import storyChapter03IntroUrl from "../assets/images/story-chapter-03-intro.webp";
import storyChapter03OutroUrl from "../assets/images/story-chapter-03-outro.webp";
import storyChapter04IntroUrl from "../assets/images/story-chapter-04-intro.webp";
import storyChapter04OutroUrl from "../assets/images/story-chapter-04-outro.webp";
import storyChapter05IntroUrl from "../assets/images/story-chapter-05-intro.webp";
import storyChapter05OutroUrl from "../assets/images/story-chapter-05-outro.webp";
import storyChapter06IntroUrl from "../assets/images/story-chapter-06-intro.webp";
import storyChapter06OutroUrl from "../assets/images/story-chapter-06-outro.webp";
import storyClueArchiveRecordUrl from "../assets/images/story-clue-archive-record.webp";
import storyClueBlackoutSignalUrl from "../assets/images/story-clue-blackout-signal.webp";
import storyClueSabotageRouteUrl from "../assets/images/story-clue-sabotage-route.webp";
import storyGreenhouseRecoveryBgUrl from "../assets/images/story-greenhouse-recovery-bg.webp";
import storyLabBlackoutBgUrl from "../assets/images/story-lab-blackout-bg.webp";
import storyNumberFactoryBgUrl from "../assets/images/story-number-factory-bg.webp";
import storyNoraCoreAwakeningUrl from "../assets/images/story-nora-core-awakening.webp";
import storyNoraCoreDormantUrl from "../assets/images/story-nora-core-dormant.webp";
import storyNoraCoreGuardianUrl from "../assets/images/story-nora-core-guardian.webp";
import storyNoraCoreMemoryUrl from "../assets/images/story-nora-core-memory.webp";
import storyNoraCoreRestoredUrl from "../assets/images/story-nora-core-restored.webp";
import storyPhase00BlackoutBgUrl from "../assets/images/story-phase-00-blackout-bg.webp";
import storyPhase01EnergyBgUrl from "../assets/images/story-phase-01-energy-bg.webp";
import storyPhase02LifeBgUrl from "../assets/images/story-phase-02-life-bg.webp";
import storyPhase03ProductionBgUrl from "../assets/images/story-phase-03-production-bg.webp";
import storyPhase04RestoredBgUrl from "../assets/images/story-phase-04-restored-bg.webp";
import storyPhase05SignalBgUrl from "../assets/images/story-phase-05-signal-bg.webp";
import storyPhase06CityRestoredBgUrl from "../assets/images/story-phase-06-city-restored-bg.webp";
import storyTransitionExploreUrl from "../assets/images/story-transition-explore.webp";
import storyTransitionTrialUrl from "../assets/images/story-transition-trial.webp";
import paintedArchiveDeskUrl from "../assets/painted/props/painted-archive-desk.webp";
import paintedArchiveShelfUrl from "../assets/painted/props/painted-archive-shelf.webp";
import paintedArchiveTerminalUrl from "../assets/painted/props/painted-archive-terminal.webp";
import paintedFactoryConveyorUrl from "../assets/painted/props/painted-factory-conveyor.webp";
import paintedFactoryCoreUrl from "../assets/painted/props/painted-factory-core.webp";
import paintedFactoryMachineUrl from "../assets/painted/props/painted-factory-machine.webp";
import paintedGreenhousePodUrl from "../assets/painted/props/painted-greenhouse-pod.webp";
import paintedGreenhouseSensorUrl from "../assets/painted/props/painted-greenhouse-sensor.webp";
import paintedGreenhouseValveUrl from "../assets/painted/props/painted-greenhouse-valve.webp";
import outcomeDefeatUrl from "../assets/images/outcomes/outcome-defeat.webp";
import outcomeDevastatingDefeatUrl from "../assets/images/outcomes/outcome-devastating-defeat.webp";
import outcomeGrandVictoryUrl from "../assets/images/outcomes/outcome-grand-victory.webp";
import outcomeLightVictoryUrl from "../assets/images/outcomes/outcome-light-victory.webp";
import outcomeNeutralUrl from "../assets/images/outcomes/outcome-neutral.webp";

export type SceneAssetPack = "academy" | "lab" | "greenhouse" | "factory" | "archive" | "atlas" | "progressive" | "logicGym" | "procedural" | "story" | "storyBeats";

const packs: Record<SceneAssetPack, Array<[string, string]>> = {
  academy: [["bg-academy-painted", academyPaintedBgUrl]],
  lab: [
    ["bg-lab-painted", labPaintedBgUrl], ["console-lab", labConsoleUrl],
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
  atlas: [
    ["mission-atlas-bg", missionAtlasBgUrl],
  ],
  progressive: [
    ["progressive-scalata-bg", progressiveScalataBgUrl],
  ],
  logicGym: [
    ["logic-gym-firewall-bg", logicGymFirewallBgUrl],
  ],
  story: [
    ["story-academy-hub-bg", storyAcademyHubBgUrl],
    ["story-archive-memory-bg", storyArchiveMemoryBgUrl],
    ["story-clue-blackout-signal", storyClueBlackoutSignalUrl],
    ["story-clue-archive-record", storyClueArchiveRecordUrl],
    ["story-clue-sabotage-route", storyClueSabotageRouteUrl],
    ["story-greenhouse-recovery-bg", storyGreenhouseRecoveryBgUrl],
    ["story-lab-blackout-bg", storyLabBlackoutBgUrl],
    ["story-number-factory-bg", storyNumberFactoryBgUrl],
    ["story-nora-core-dormant", storyNoraCoreDormantUrl],
    ["story-nora-core-awakening", storyNoraCoreAwakeningUrl],
    ["story-nora-core-memory", storyNoraCoreMemoryUrl],
    ["story-nora-core-restored", storyNoraCoreRestoredUrl],
    ["story-nora-core-guardian", storyNoraCoreGuardianUrl],
    ["story-phase-00-blackout-bg", storyPhase00BlackoutBgUrl],
    ["story-phase-01-energy-bg", storyPhase01EnergyBgUrl],
    ["story-phase-02-life-bg", storyPhase02LifeBgUrl],
    ["story-phase-03-production-bg", storyPhase03ProductionBgUrl],
    ["story-phase-04-restored-bg", storyPhase04RestoredBgUrl],
    ["story-phase-05-signal-bg", storyPhase05SignalBgUrl],
    ["story-phase-06-city-restored-bg", storyPhase06CityRestoredBgUrl],
    ["story-transition-explore", storyTransitionExploreUrl],
    ["story-transition-trial", storyTransitionTrialUrl],
  ],
  storyBeats: [
    ["story-chapter-01-intro", storyChapter01IntroUrl], ["story-chapter-01-outro", storyChapter01OutroUrl],
    ["story-chapter-02-intro", storyChapter02IntroUrl], ["story-chapter-02-outro", storyChapter02OutroUrl],
    ["story-chapter-03-intro", storyChapter03IntroUrl], ["story-chapter-03-outro", storyChapter03OutroUrl],
    ["story-chapter-04-intro", storyChapter04IntroUrl], ["story-chapter-04-outro", storyChapter04OutroUrl],
    ["story-chapter-05-intro", storyChapter05IntroUrl], ["story-chapter-05-outro", storyChapter05OutroUrl],
    ["story-chapter-06-intro", storyChapter06IntroUrl], ["story-chapter-06-outro", storyChapter06OutroUrl],
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
