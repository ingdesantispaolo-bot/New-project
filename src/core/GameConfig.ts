import Phaser from "phaser";
import { BootScene } from "../scenes/BootScene";
import { CampaignScene } from "../scenes/CampaignScene";
import { CircuitPuzzleScene } from "../scenes/CircuitPuzzleScene";
import { GreenhouseScene } from "../scenes/GreenhouseScene";
import { HubScene } from "../scenes/HubScene";
import { JournalScene } from "../scenes/JournalScene";
import { LaboratoryScene } from "../scenes/LaboratoryScene";
import { MainMenuScene } from "../scenes/MainMenuScene";
import { MathLockScene } from "../scenes/MathLockScene";
import { NumberFactoryScene } from "../scenes/NumberFactoryScene";
import { PreloadScene } from "../scenes/PreloadScene";
import { RobotCodingScene } from "../scenes/RobotCodingScene";
import { SettingsScene } from "../scenes/SettingsScene";
import { WordArchiveScene } from "../scenes/WordArchiveScene";

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
    CampaignScene,
    HubScene,
    LaboratoryScene,
    GreenhouseScene,
    NumberFactoryScene,
    WordArchiveScene,
    CircuitPuzzleScene,
    MathLockScene,
    RobotCodingScene,
    JournalScene,
    SettingsScene,
  ],
};
