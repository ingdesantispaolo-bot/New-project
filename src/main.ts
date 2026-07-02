import Phaser from "phaser";
import "./style.css";
import { gameConfig } from "./core/GameConfig";
import { ViewportSystem } from "./core/ViewportSystem";
import { ReadableTextSystem } from "./core/ReadableTextSystem";

ViewportSystem.install();
ReadableTextSystem.install();
const game = new Phaser.Game(gameConfig);

declare global {
  interface Window {
    __ELI_QUEST_GAME__?: Phaser.Game;
  }
}

if (import.meta.env.DEV) {
  window.__ELI_QUEST_GAME__ = game;
}
