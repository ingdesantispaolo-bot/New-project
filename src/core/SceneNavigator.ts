import Phaser from "phaser";

type SceneConstructor = new () => Phaser.Scene;

const lazyLoaders: Record<string, () => Promise<SceneConstructor>> = {
  LeaderboardScene: async () => (await import("../scenes/LeaderboardScene")).LeaderboardScene,
  PlayerReportScene: async () => (await import("../scenes/PlayerReportScene")).PlayerReportScene,
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

export async function startScene(scene: Phaser.Scene, key: string): Promise<void> {
  await ensureScene(scene, key);
  scene.scene.start(key);
}
