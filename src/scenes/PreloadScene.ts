import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { startScene } from "../core/SceneNavigator";
import academyPaintedBgUrl from "../assets/images/academy-painted-bg.webp";
import actionRoomBgUrl from "../assets/images/academy-action-room-bg.webp";
import serraBioBgUrl from "../assets/images/area-bio-ponte-primi.webp";
import cantiereCircuitiBgUrl from "../assets/images/area-reattore-primi.webp";
import osservatorioBgUrl from "../assets/images/area-ponte-comando-primi.webp";
import salaMusicaBgUrl from "../assets/images/area-motore-risonanza-primi.webp";
import archivioBibliotecaBgUrl from "../assets/images/area-data-core-primi.webp";
import bibliotecaClassicaBgUrl from "../assets/images/area-sala-glifi-primi.webp";
import eliQuestAtlasUrl from "../assets/sprites/eli-quest-atlas.webp";
import eliQuestAtlasJsonUrl from "../assets/sprites/eli-quest-atlas.json?url";
import eliRobotGirlSheetUrl from "../assets/sprites/eli-robot-girl-sheet.png";
import eliRobotGirlSheetJsonUrl from "../assets/sprites/eli-robot-girl-sheet.json?url";
import environmentPropsSheetUrl from "../assets/sprites/environment-props-sheet.png";
import environmentPropsSheetJsonUrl from "../assets/sprites/environment-props-sheet.json?url";

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("PreloadScene");
  }

  preload(): void {
    this.renderLoadingUi();
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
  }

  create(): void {
    const graphics = this.add.graphics();
    graphics.fillStyle(0x6be7d6, 1);
    graphics.fillCircle(16, 16, 16);
    graphics.generateTexture("soft-glow", 32, 32);
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

  private renderLoadingUi(): void {
    const { width, height } = this.scale;
    const centerX = width / 2;
    const centerY = height / 2;
    const barWidth = 420;
    const barHeight = 14;

    this.add.text(centerX, centerY - 46, "Eli Quest", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5);
    const statusText = this.add.text(centerX, centerY + 34, "Caricamento… 0%", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
    }).setOrigin(0.5);

    const barBg = this.add.graphics();
    barBg.fillStyle(0x0a1a24, 1);
    barBg.fillRoundedRect(centerX - barWidth / 2, centerY - barHeight / 2, barWidth, barHeight, 7);
    barBg.lineStyle(1, 0x244451, 1);
    barBg.strokeRoundedRect(centerX - barWidth / 2, centerY - barHeight / 2, barWidth, barHeight, 7);

    const barFill = this.add.graphics();
    this.load.on(Phaser.Loader.Events.PROGRESS, (value: number) => {
      barFill.clear();
      barFill.fillStyle(0x6be7d6, 1);
      const fillWidth = Math.max(barHeight, barWidth * value);
      barFill.fillRoundedRect(centerX - barWidth / 2, centerY - barHeight / 2, fillWidth, barHeight, 7);
      statusText.setText(`Caricamento… ${Math.round(value * 100)}%`);
    });
    this.load.once(Phaser.Loader.Events.COMPLETE, () => {
      barBg.destroy();
      barFill.destroy();
      statusText.destroy();
    });
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
    if (this.textures.exists("environment-props")) {
      warmers.push(this.add.image(-220, -180, "environment-props", "env_wall_straight").setAlpha(0.01).setScale(0.05));
      warmers.push(this.add.image(-228, -180, "environment-props", "env_planter").setAlpha(0.01).setScale(0.05));
    }
    this.time.delayedCall(120, () => {
      warmers.forEach((item) => item.destroy());
    });
  }
}
