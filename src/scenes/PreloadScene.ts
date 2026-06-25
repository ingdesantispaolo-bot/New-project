import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import academyPaintedBgUrl from "../assets/images/academy-painted-bg.webp";
import eliQuestAtlasUrl from "../assets/sprites/eli-quest-atlas.webp";
import eliQuestAtlasJsonUrl from "../assets/sprites/eli-quest-atlas.json?url";

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("PreloadScene");
  }

  preload(): void {
    this.load.image("bg-academy-painted", academyPaintedBgUrl);
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

    this.warmCriticalTextures();
    audioManager.preloadEssentialAudio();
    this.scene.start("MainMenuScene");
  }

  private warmCriticalTextures(): void {
    const keys = [
      "bg-academy-painted",
      "soft-glow",
      "holo-ring",
      "spark-core",
    ];
    const warmers = keys
      .filter((key) => this.textures.exists(key))
      .map((key, index) => this.add.image(-128 - index * 4, -128, key).setAlpha(0.01).setScale(0.05));
    if (this.textures.exists("eli-atlas")) {
      warmers.push(this.add.image(-180, -180, "eli-atlas", "particle-diamond").setAlpha(0.01).setScale(0.05));
      warmers.push(this.add.image(-188, -188, "eli-atlas", "robot-core").setAlpha(0.01).setScale(0.05));
    }
    this.time.delayedCall(120, () => {
      warmers.forEach((item) => item.destroy());
    });
  }
}
