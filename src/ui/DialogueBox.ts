import Phaser from "phaser";
import { Button } from "./Button";

export class DialogueBox extends Phaser.GameObjects.Container {
  private lineIndex = 0;
  private textObject: Phaser.GameObjects.Text;

  constructor(
    scene: Phaser.Scene,
    lines: string[],
    onComplete: () => void,
    x = 120,
    y = 500,
    width = 1040,
    height = 150,
  ) {
    super(scene, x, y);
    this.add(
      scene.add
        .rectangle(0, 0, width, height, 0x08131c, 0.94)
        .setOrigin(0)
        .setStrokeStyle(2, 0x6be7d6, 0.55),
    );
    this.textObject = scene.add.text(26, 24, lines[0] ?? "", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f4fbff",
      wordWrap: { width: width - 52 },
      lineSpacing: 6,
    });
    this.add(this.textObject);

    this.add(
      new Button(
        scene,
        width - 130,
        height - 36,
        "Avanti",
        () => {
          this.lineIndex += 1;
          if (this.lineIndex >= lines.length) {
            this.destroy();
            onComplete();
            return;
          }
          this.textObject.setText(lines[this.lineIndex]);
        },
        { width: 150, height: 42, fontSize: 16 },
      ),
    );

    scene.add.existing(this);
  }
}
