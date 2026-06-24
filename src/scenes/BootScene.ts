import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { settingsSystem } from "../core/SettingsSystem";

export class BootScene extends Phaser.Scene {
  constructor() {
    super("BootScene");
  }

  create(): void {
    settingsSystem.load();
    audioManager.bindSettings();
    playerSystem.load();
    saveSystem.load();
    this.scene.start("PreloadScene");
  }
}
