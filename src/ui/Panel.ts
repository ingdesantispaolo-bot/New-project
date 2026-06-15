import Phaser from "phaser";

export class Panel extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, x: number, y: number, width: number, height: number, title?: string) {
    super(scene, x, y);
    const shadow = scene.add.rectangle(7, 9, width, height, 0x000000, 0.28).setOrigin(0);
    const background = scene.add
      .rectangle(0, 0, width, height, 0x0d1b26, 0.93)
      .setOrigin(0)
      .setStrokeStyle(2, 0x66d9cf, 0.38);
    const topLine = scene.add.rectangle(0, 0, width, 3, 0x66d9cf, 0.58).setOrigin(0);
    const innerLine = scene.add.rectangle(16, 42, width - 32, 1, 0xffffff, 0.07).setOrigin(0);
    this.add([shadow, background, topLine, innerLine]);

    if (title) {
      this.add(
        scene.add.text(18, 14, title, {
          fontFamily: "Inter, Arial",
          fontSize: "18px",
          color: "#9ff5e9",
          fontStyle: "bold",
          shadow: { offsetX: 0, offsetY: 2, color: "#000000", blur: 4, fill: true },
        }),
      );
    }

    scene.add.existing(this);
  }
}
