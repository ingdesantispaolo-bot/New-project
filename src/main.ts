import Phaser from "phaser";
import "./style.css";
import { gameConfig } from "./core/GameConfig";
import { ViewportSystem } from "./core/ViewportSystem";

ViewportSystem.install();
new Phaser.Game(gameConfig);
