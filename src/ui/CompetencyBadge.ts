import Phaser from "phaser";

export class CompetencyBadge extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, x: number, y: number, label: string, score: number) {
    super(scene, x, y);
    this.add(scene.add.circle(0, 0, 16, score > 0 ? 0xf6c85f : 0x22323c, 1));
    this.add(
      scene.add.text(28, -11, `${label} ${score}`, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#f5fbff",
      }),
    );
    scene.add.existing(this);
  }
}
