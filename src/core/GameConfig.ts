import Phaser from "phaser";
import { BootScene } from "../scenes/BootScene";
import { JournalScene } from "../scenes/JournalScene";
import { MainMenuScene } from "../scenes/MainMenuScene";
import { PreloadScene } from "../scenes/PreloadScene";

export const GAME_WIDTH = 1280;
export const GAME_HEIGHT = 720;

export const gameConfig: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: "app",
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  backgroundColor: "#071018",
  dom: {
    createContainer: true,
  },
  input: {
    activePointers: 3,
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    parent: "app",
    width: GAME_WIDTH,
    height: GAME_HEIGHT,
  },
  scene: [
    BootScene,
    PreloadScene,
    MainMenuScene,
    JournalScene,
  ],
};
