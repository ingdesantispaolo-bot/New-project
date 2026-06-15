import Phaser from "phaser";
import { saveSystem } from "../core/SaveSystem";

export class BootScene extends Phaser.Scene {
  constructor() {
    super("BootScene");
  }

  create(): void {
    saveSystem.load();
    this.scene.start("PreloadScene");
  }
}
