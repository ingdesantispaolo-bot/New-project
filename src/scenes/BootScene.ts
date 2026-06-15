import Phaser from "phaser";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";

export class BootScene extends Phaser.Scene {
  constructor() {
    super("BootScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.scene.start("PreloadScene");
  }
}
