import Phaser from "phaser";

type SceneConstructor = new () => Phaser.Scene;

const lazyLoaders: Record<string, () => Promise<SceneConstructor>> = {
  LaboratoryScene: async () => (await import("../scenes/LaboratoryScene")).LaboratoryScene,
  GreenhouseScene: async () => (await import("../scenes/GreenhouseScene")).GreenhouseScene,
  NumberFactoryScene: async () => (await import("../scenes/NumberFactoryScene")).NumberFactoryScene,
  WordArchiveScene: async () => (await import("../scenes/WordArchiveScene")).WordArchiveScene,
  CircuitPuzzleScene: async () => (await import("../scenes/CircuitPuzzleScene")).CircuitPuzzleScene,
  MathLockScene: async () => (await import("../scenes/MathLockScene")).MathLockScene,
  RobotCodingScene: async () => (await import("../scenes/RobotCodingScene")).RobotCodingScene,
  LeaderboardScene: async () => (await import("../scenes/LeaderboardScene")).LeaderboardScene,
  MathStudyScene: async () => (await import("../scenes/MathStudyScene")).MathStudyScene,
  PlayerReportScene: async () => (await import("../scenes/PlayerReportScene")).PlayerReportScene,
  TeacherDashboardScene: async () => (await import("../scenes/TeacherDashboardScene")).TeacherDashboardScene,
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
