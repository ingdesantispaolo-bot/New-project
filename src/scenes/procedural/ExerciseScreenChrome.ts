import Phaser from "phaser";
import { Button } from "../../ui/Button";
import { SceneChrome } from "../../ui/SceneChrome";

export type ExerciseScreenChromeOptions = {
  title: string;
  backgroundKey: string;
  onClose: () => void;
  addTheoryButton?: (overlay: Phaser.GameObjects.Container) => void;
};

export function createExerciseScreenChrome(scene: Phaser.Scene, options: ExerciseScreenChromeOptions): Phaser.GameObjects.Container {
  const overlay = scene.add.container(40, 0).setDepth(1200);
  SceneChrome.modalInputBlocker(scene, overlay, overlay.x, overlay.y);
  if (scene.textures.exists(options.backgroundKey)) {
    overlay.add(scene.add.image(600, 360, options.backgroundKey).setDisplaySize(1320, 742).setAlpha(0.34));
  }
  overlay.add(scene.add.rectangle(600, 360, 1280, 720, 0x02080d, 0.82));
  const grid = scene.add.graphics();
  grid.lineStyle(1, 0x6be7d6, 0.045);
  for (let x = -160; x < 1320; x += 72) {
    grid.lineBetween(x, 0, x - 128, 720);
  }
  for (let y = 92; y < 720; y += 58) {
    grid.lineBetween(-40, y, 1240, y + 10);
  }
  overlay.add(grid);
  overlay.add(scene.add.rectangle(600, 34, 1280, 68, 0x06131c, 0.92));
  overlay.add(scene.add.rectangle(600, 68, 1280, 2, 0x6be7d6, 0.42));
  overlay.add(scene.add.text(0, 14, options.title, {
    fontFamily: "Inter, Arial",
    fontSize: "28px",
    color: "#f5fbff",
    fontStyle: "bold",
    wordWrap: { width: 1080, useAdvancedWrap: true },
    shadow: { offsetX: 0, offsetY: 3, color: "#000000", blur: 6, fill: true },
  }));
  overlay.add(new Button(scene, 1184, 34, "X", options.onClose, {
    width: 56,
    height: 42,
    fontSize: 18,
    fill: 0x263743,
  }));
  options.addTheoryButton?.(overlay);
  return overlay;
}
