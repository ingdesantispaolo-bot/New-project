import Phaser from "phaser";

type SceneConstructor = new () => Phaser.Scene;

const lazyLoaders: Record<string, () => Promise<SceneConstructor>> = {
  LaboratoryScene: async () => (await import("../scenes/LaboratoryScene")).LaboratoryScene,
  GreenhouseScene: async () => (await import("../scenes/GreenhouseScene")).GreenhouseScene,
  NumberFactoryScene: async () => (await import("../scenes/NumberFactoryScene")).NumberFactoryScene,
  WordArchiveScene: async () => (await import("../scenes/WordArchiveScene")).WordArchiveScene,
  AtlasScene: async () => (await import("../scenes/AtlasScene")).AtlasScene,
  SmartCityScene: async () => (await import("../scenes/SmartCityScene")).SmartCityScene,
  CircuitPuzzleScene: async () => (await import("../scenes/CircuitPuzzleScene")).CircuitPuzzleScene,
  MathLockScene: async () => (await import("../scenes/MathLockScene")).MathLockScene,
  RobotCodingScene: async () => (await import("../scenes/RobotCodingScene")).RobotCodingScene,
  LeaderboardScene: async () => (await import("../scenes/LeaderboardScene")).LeaderboardScene,
  MathStudyScene: async () => (await import("../scenes/MathStudyScene")).MathStudyScene,
  PlayerReportScene: async () => (await import("../scenes/PlayerReportScene")).PlayerReportScene,
  TeacherDashboardScene: async () => (await import("../scenes/TeacherDashboardScene")).TeacherDashboardScene,
  MasteryScene: async () => (await import("../scenes/MasteryScene")).MasteryScene,
  NoraScene: async () => (await import("../scenes/NoraScene")).NoraScene,
  AcademyScene: async () => (await import("../scenes/AcademyScene")).AcademyScene,
  BossScene: async () => (await import("../scenes/BossScene")).BossScene,
  CollectionScene: async () => (await import("../scenes/CollectionScene")).CollectionScene,
  LogicGymScene: async () => (await import("../scenes/LogicGymScene")).LogicGymScene,
  CodexScene: async () => (await import("../scenes/CodexScene")).CodexScene,
  ExplorableRoomScene: async () => (await import("../scenes/ExplorableRoomScene")).ExplorableRoomScene,
  DiarioScene: async () => (await import("../scenes/DiarioScene")).DiarioScene,
  FinaleScene: async () => (await import("../scenes/FinaleScene")).FinaleScene,
  RewardShopScene: async () => (await import("../scenes/RewardShopScene")).RewardShopScene,
  AvatarEquipmentScene: async () => (await import("../scenes/AvatarEquipmentScene")).AvatarEquipmentScene,
  OutdoorAdventureScene: async () => (await import("../scenes/OutdoorAdventureScene")).OutdoorAdventureScene,
  ProceduralMissionScene: async () => (await import("../scenes/ProceduralMissionScene")).ProceduralMissionScene,
};

export async function ensureScene(scene: Phaser.Scene, key: string): Promise<void> {
  if (scene.scene.manager.keys[key]) {
    return;
  }
  const loader = lazyLoaders[key];
  if (!loader) {
    return;
  }
  const SceneClass = await loader();
  scene.scene.add(key, SceneClass, false);
}

export function prefetchScene(scene: Phaser.Scene, key: string): void {
  if (scene.scene.manager.keys[key]) {
    return;
  }
  const schedule = typeof window !== "undefined" && "requestIdleCallback" in window
    ? (callback: () => void) => window.requestIdleCallback(callback, { timeout: 1200 })
    : (callback: () => void) => window.setTimeout(callback, 80);
  schedule(() => {
    ensureScene(scene, key).catch(() => {
      // Lazy preload is opportunistic; normal navigation will retry.
    });
  });
}

export function prefetchCoreScenes(scene: Phaser.Scene): void {
  ["ProceduralMissionScene", "PlayerReportScene", "LeaderboardScene", "MathStudyScene"].forEach((key) => prefetchScene(scene, key));
}

export async function startScene(scene: Phaser.Scene, key: string, data?: object): Promise<void> {
  await ensureScene(scene, key);
  scene.scene.start(key, data);
}
