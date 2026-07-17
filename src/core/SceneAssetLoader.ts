import Phaser from "phaser";
import academyPaintedBgUrl from "../assets/images/academy-painted-bg.webp";
import academyHomeBgUrl from "../assets/images/academy-home-bg.webp";
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
import logicGymHubBgUrl from "../assets/images/logic-gym-hub-bg.webp";
import logicGymFirewallBgUrl from "../assets/images/logic-gym-firewall-bg.webp";
import noraRoomBgUrl from "../assets/images/nora-room-bg.webp";
import missionAtlasBgUrl from "../assets/images/mission-atlas-bg.webp";
import progressiveScalataBgUrl from "../assets/images/progressive-scalata-bg.webp";
import rewardShopBgUrl from "../assets/images/reward-shop-bg.webp";
import missionConsoleSheetUrl from "../assets/sprites/mission-console-sheet.png";
import missionConsoleSheetJsonUrl from "../assets/sprites/mission-console-sheet.json?url";
import robotGridSheetUrl from "../assets/sprites/robot-grid-sheet.png";
import robotGridSheetJsonUrl from "../assets/sprites/robot-grid-sheet.json?url";
import logicGymSheetUrl from "../assets/sprites/logic-gym-sheet.png";
import logicGymSheetJsonUrl from "../assets/sprites/logic-gym-sheet.json?url";
import rewardItemsSheetUrl from "../assets/sprites/reward-items-sheet.png";
import rewardItemsSheetJsonUrl from "../assets/sprites/reward-items-sheet.json?url";
import outdoorWorldSheetUrl from "../assets/sprites/outdoor-world-sheet.png";
import outdoorWorldSheetJsonUrl from "../assets/sprites/outdoor-world-sheet.json?url";
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
import storyPrimiDiarioBordoUrl from "../assets/images/story-primi-diario-bordo.webp";
import storyPrimiFinaleAccesaUrl from "../assets/images/story-primi-finale-accesa.webp";
import storyPrimiFinaleDormienteUrl from "../assets/images/story-primi-finale-dormiente.webp";
import storyPrimiFinaleEliUrl from "../assets/images/story-primi-finale-eli.webp";
import storyPrimiGuardianoAlleatoUrl from "../assets/images/story-primi-guardiano-alleato.webp";
import storyPrimiGuardianoBrokenUrl from "../assets/images/story-primi-guardiano-broken.webp";
import storyPrimiRelittoUrl from "../assets/images/story-primi-relitto.webp";
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

export type SceneAssetPack = "academy" | "academyHome" | "lab" | "greenhouse" | "factory" | "archive" | "atlas" | "progressive" | "logicGym" | "nora" | "outdoorPainted" | "outdoorWorld" | "procedural" | "robotGrid" | "shop" | "rewards" | "story" | "storyBeats";

type ImageEntry = { type: "image"; key: string; url: string };
type AtlasEntry = { type: "atlas"; key: string; textureUrl: string; atlasUrl: string };
type AssetEntry = ImageEntry | AtlasEntry;

const image = (key: string, url: string): ImageEntry => ({ type: "image", key, url });
const atlas = (key: string, textureUrl: string, atlasUrl: string): AtlasEntry => ({ type: "atlas", key, textureUrl, atlasUrl });

const packs: Record<SceneAssetPack, AssetEntry[]> = {
  academy: [image("bg-academy-painted", academyPaintedBgUrl)],
  academyHome: [image("academy-home-bg", academyHomeBgUrl)],
  lab: [
    image("bg-lab-painted", labPaintedBgUrl), image("console-lab", labConsoleUrl),
  ],
  greenhouse: [
    image("bg-greenhouse-painted", greenhousePaintedBgUrl), image("console-greenhouse", greenhouseConsoleUrl),
    image("painted-greenhouse-pod", paintedGreenhousePodUrl), image("painted-greenhouse-sensor", paintedGreenhouseSensorUrl),
    image("painted-greenhouse-valve", paintedGreenhouseValveUrl),
  ],
  factory: [
    image("bg-factory-painted", factoryPaintedBgUrl), image("console-factory", factoryConsoleUrl),
    image("painted-factory-conveyor", paintedFactoryConveyorUrl), image("painted-factory-core", paintedFactoryCoreUrl),
    image("painted-factory-machine", paintedFactoryMachineUrl),
  ],
  archive: [
    image("bg-archive-painted", archivePaintedBgUrl), image("console-archive", archiveConsoleUrl),
    image("painted-archive-desk", paintedArchiveDeskUrl), image("painted-archive-shelf", paintedArchiveShelfUrl),
    image("painted-archive-terminal", paintedArchiveTerminalUrl),
  ],
  atlas: [
    image("mission-atlas-bg", missionAtlasBgUrl),
  ],
  progressive: [
    image("progressive-scalata-bg", progressiveScalataBgUrl),
  ],
  logicGym: [
    image("logic-gym-hub-bg", logicGymHubBgUrl),
    image("logic-gym-firewall-bg", logicGymFirewallBgUrl),
    atlas("logic-gym", logicGymSheetUrl, logicGymSheetJsonUrl),
  ],
  nora: [
    image("nora-room-bg", noraRoomBgUrl),
  ],
  outdoorPainted: [
    image("bg-academy-painted", academyPaintedBgUrl),
    image("bg-greenhouse-painted", greenhousePaintedBgUrl),
    image("mission-atlas-bg", missionAtlasBgUrl),
    image("mission-coding-terminal-bg", missionCodingTerminalBgUrl),
    image("mission-electronics-bg", missionElectronicsBgUrl),
    image("mission-bg-synthesis", missionSynthesisBgUrl),
  ],
  outdoorWorld: [
    atlas("outdoor-world", outdoorWorldSheetUrl, outdoorWorldSheetJsonUrl),
  ],
  robotGrid: [
    atlas("robot-grid", robotGridSheetUrl, robotGridSheetJsonUrl),
  ],
  rewards: [
    atlas("reward-items", rewardItemsSheetUrl, rewardItemsSheetJsonUrl),
  ],
  shop: [
    image("reward-shop-bg", rewardShopBgUrl),
    atlas("reward-items", rewardItemsSheetUrl, rewardItemsSheetJsonUrl),
  ],
  story: [
    image("story-academy-hub-bg", storyAcademyHubBgUrl),
    image("story-archive-memory-bg", storyArchiveMemoryBgUrl),
    image("story-clue-blackout-signal", storyClueBlackoutSignalUrl),
    image("story-clue-archive-record", storyClueArchiveRecordUrl),
    image("story-clue-sabotage-route", storyClueSabotageRouteUrl),
    image("story-greenhouse-recovery-bg", storyGreenhouseRecoveryBgUrl),
    image("story-lab-blackout-bg", storyLabBlackoutBgUrl),
    image("story-number-factory-bg", storyNumberFactoryBgUrl),
    image("story-nora-core-dormant", storyNoraCoreDormantUrl),
    image("story-nora-core-awakening", storyNoraCoreAwakeningUrl),
    image("story-nora-core-memory", storyNoraCoreMemoryUrl),
    image("story-nora-core-restored", storyNoraCoreRestoredUrl),
    image("story-nora-core-guardian", storyNoraCoreGuardianUrl),
    image("story-phase-00-blackout-bg", storyPhase00BlackoutBgUrl),
    image("story-phase-01-energy-bg", storyPhase01EnergyBgUrl),
    image("story-phase-02-life-bg", storyPhase02LifeBgUrl),
    image("story-phase-03-production-bg", storyPhase03ProductionBgUrl),
    image("story-phase-04-restored-bg", storyPhase04RestoredBgUrl),
    image("story-phase-05-signal-bg", storyPhase05SignalBgUrl),
    image("story-phase-06-city-restored-bg", storyPhase06CityRestoredBgUrl),
    image("story-primi-relitto", storyPrimiRelittoUrl),
    image("story-primi-guardiano-broken", storyPrimiGuardianoBrokenUrl),
    image("story-primi-guardiano-alleato", storyPrimiGuardianoAlleatoUrl),
    image("story-primi-diario-bordo", storyPrimiDiarioBordoUrl),
    image("story-primi-finale-dormiente", storyPrimiFinaleDormienteUrl),
    image("story-primi-finale-accesa", storyPrimiFinaleAccesaUrl),
    image("story-primi-finale-eli", storyPrimiFinaleEliUrl),
    image("story-transition-explore", storyTransitionExploreUrl),
    image("story-transition-trial", storyTransitionTrialUrl),
  ],
  storyBeats: [
    image("story-chapter-01-intro", storyChapter01IntroUrl), image("story-chapter-01-outro", storyChapter01OutroUrl),
    image("story-chapter-02-intro", storyChapter02IntroUrl), image("story-chapter-02-outro", storyChapter02OutroUrl),
    image("story-chapter-03-intro", storyChapter03IntroUrl), image("story-chapter-03-outro", storyChapter03OutroUrl),
    image("story-chapter-04-intro", storyChapter04IntroUrl), image("story-chapter-04-outro", storyChapter04OutroUrl),
    image("story-chapter-05-intro", storyChapter05IntroUrl), image("story-chapter-05-outro", storyChapter05OutroUrl),
    image("story-chapter-06-intro", storyChapter06IntroUrl), image("story-chapter-06-outro", storyChapter06OutroUrl),
  ],
  procedural: [
    image("bg-lab-painted", labPaintedBgUrl), image("console-lab", labConsoleUrl),
    image("mission-bg-coding", missionCodingBgUrl), image("mission-bg-electronics", missionElectronicsBgUrl),
    image("mission-bg-english", missionEnglishBgUrl), image("mission-bg-italian", missionItalianBgUrl),
    image("mission-bg-math", missionMathBgUrl), image("mission-bg-music", missionMusicBgUrl),
    image("mission-coding-robot-bg", missionCodingRobotBgUrl), image("mission-coding-terminal-bg", missionCodingTerminalBgUrl),
    image("mission-electronics-bench-bg", missionElectronicsBenchBgUrl), image("mission-electronics-power-bg", missionElectronicsPowerBgUrl),
    image("mission-english-control-bg", missionEnglishControlBgUrl), image("mission-english-radio-bg", missionEnglishRadioBgUrl),
    image("mission-italian-archive-bg", missionItalianArchiveBgUrl), image("mission-italian-library-bg", missionItalianLibraryBgUrl),
    image("mission-math-factory-bg", missionMathFactoryBgUrl), image("mission-math-grid-bg", missionMathGridBgUrl),
    image("mission-music-audio-bg", missionMusicAudioBgUrl), image("mission-music-staff-bg", missionMusicStaffBgUrl),
    image("mission-bg-synthesis", missionSynthesisBgUrl),
    image("outcome-defeat", outcomeDefeatUrl), image("outcome-devastating-defeat", outcomeDevastatingDefeatUrl),
    image("outcome-grand-victory", outcomeGrandVictoryUrl), image("outcome-light-victory", outcomeLightVictoryUrl),
    image("outcome-neutral", outcomeNeutralUrl),
    atlas("mission-consoles", missionConsoleSheetUrl, missionConsoleSheetJsonUrl),
    atlas("robot-grid", robotGridSheetUrl, robotGridSheetJsonUrl),
  ],
};

export function queueSceneAssets(scene: Phaser.Scene, ...requestedPacks: SceneAssetPack[]): void {
  const entries = requestedPacks.flatMap((pack) => packs[pack]);
  const unique = new Map(entries.map((entry) => [entry.key, entry]));
  unique.forEach((entry) => {
    if (scene.textures.exists(entry.key)) return;
    if (entry.type === "image") {
      scene.load.image(entry.key, entry.url);
      return;
    }
    scene.load.atlas(entry.key, entry.textureUrl, entry.atlasUrl);
  });
}
