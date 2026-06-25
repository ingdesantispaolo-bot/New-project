import Phaser from "phaser";
import "./style.css";
import { gameConfig } from "./core/GameConfig";
import { ViewportSystem } from "./core/ViewportSystem";
import { ReadableTextSystem } from "./core/ReadableTextSystem";

ViewportSystem.install();
ReadableTextSystem.install();
new Phaser.Game(gameConfig);
