import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { startScene } from "../core/SceneNavigator";
import academyPaintedBgUrl from "../assets/images/academy-painted-bg.webp";
import actionRoomBgUrl from "../assets/images/academy-action-room-bg.png";
import serraBioBgUrl from "../assets/images/area-bio-ponte-primi.png";
import cantiereCircuitiBgUrl from "../assets/images/area-reattore-primi.png";
import osservatorioBgUrl from "../assets/images/area-ponte-comando-primi.png";
import salaMusicaBgUrl from "../assets/images/area-motore-risonanza-primi.png";
import archivioBibliotecaBgUrl from "../assets/images/area-data-core-primi.png";
import bibliotecaClassicaBgUrl from "../assets/images/area-sala-glifi-primi.png";
import eliQuestAtlasUrl from "../assets/sprites/eli-quest-atlas.webp";
import eliQuestAtlasJsonUrl from "../assets/sprites/eli-quest-atlas.json?url";
import eliRobotGirlSheetUrl from "../assets/sprites/eli-robot-girl-sheet.png";
import eliRobotGirlSheetJsonUrl from "../assets/sprites/eli-robot-girl-sheet.json?url";
import environmentPropsSheetUrl from "../assets/sprites/environment-props-sheet.png";
import environmentPropsSheetJsonUrl from "../assets/sprites/environment-props-sheet.json?url";
import missionConsoleSheetUrl from "../assets/sprites/mission-console-sheet.png";
import missionConsoleSheetJsonUrl from "../assets/sprites/mission-console-sheet.json?url";

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("PreloadScene");
  }

  preload(): void {
    this.load.image("bg-academy-painted", academyPaintedBgUrl);
    this.load.image("action-room-bg", actionRoomBgUrl);
    this.load.image("area-serra-bio", serraBioBgUrl);
    this.load.image("area-cantiere-circuiti", cantiereCircuitiBgUrl);
    this.load.image("area-osservatorio", osservatorioBgUrl);
    this.load.image("area-sala-musica", salaMusicaBgUrl);
    this.load.image("area-archivio-biblioteca", archivioBibliotecaBgUrl);
    this.load.image("area-biblioteca-classica", bibliotecaClassicaBgUrl);
    this.load.atlas("eli-atlas", eliQuestAtlasUrl, eliQuestAtlasJsonUrl);
    this.load.atlas("eli-robot-girl", eliRobotGirlSheetUrl, eliRobotGirlSheetJsonUrl);
    this.load.atlas("environment-props", environmentPropsSheetUrl, environmentPropsSheetJsonUrl);
    this.load.atlas("mission-consoles", missionConsoleSheetUrl, missionConsoleSheetJsonUrl);
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
    // The explorable world IS the main menu: the session opens inside the
    // central deck of the Relitto. The button-based menu stays reachable via NORA.
    void startScene(this, "ExplorableRoomScene").catch(() => this.scene.start("MainMenuScene"));
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
    if (this.textures.exists("eli-robot-girl")) {
      warmers.push(this.add.image(-196, -180, "eli-robot-girl", "down_idle").setAlpha(0.01).setScale(0.05));
    }
    if (this.textures.exists("mission-consoles")) {
      warmers.push(this.add.image(-204, -180, "mission-consoles", "console_math_active").setAlpha(0.01).setScale(0.05));
      warmers.push(this.add.image(-212, -180, "mission-consoles", "console_exit_resolved").setAlpha(0.01).setScale(0.05));
    }
    if (this.textures.exists("environment-props")) {
      warmers.push(this.add.image(-220, -180, "environment-props", "env_wall_straight").setAlpha(0.01).setScale(0.05));
      warmers.push(this.add.image(-228, -180, "environment-props", "env_planter").setAlpha(0.01).setScale(0.05));
    }
    this.time.delayedCall(120, () => {
      warmers.forEach((item) => item.destroy());
    });
  }
}
