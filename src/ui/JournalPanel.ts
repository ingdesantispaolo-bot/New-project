import Phaser from "phaser";
import type { JournalEntry } from "../types/gameTypes";

export class JournalPanel extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, x: number, y: number, entry: JournalEntry) {
    super(scene, x, y);
    const width = 840;
    const height = 510;
    this.add(scene.add.rectangle(0, 0, width, height, 0x0c1821, 0.94).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.5));
    this.add(scene.add.rectangle(0, 0, width, 68, 0x12313a, 0.62).setOrigin(0));
    this.add(scene.add.circle(34, 34, 14, 0x9ff5e9, 0.95));
    this.add(scene.add.circle(34, 34, 24, 0x9ff5e9, 0.16));
    this.add(
      scene.add.text(62, 20, entry.title, {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: "#f5fbff",
        fontStyle: "bold",
        wordWrap: { width: 740 },
      }),
    );

    let lineY = 90;
    entry.lines.forEach((line, index) => {
      const isSeed = line.startsWith("Seed:");
      const isStory = index === entry.lines.length - 1;
      const text = scene.add.text(34, lineY, isSeed ? line : `${index + 1}. ${line}`, {
        fontFamily: "Inter, Arial",
        fontSize: isSeed ? "15px" : "16px",
        color: isSeed ? "#f7d37a" : isStory ? "#9ff5e9" : "#d9eaf1",
        wordWrap: { width: 760, useAdvancedWrap: true },
        lineSpacing: 3,
      });
      this.add(text);
      lineY += text.height + 12;
    });

    const badgesY = Math.max(lineY + 12, 368);
    this.add(
      scene.add.text(28, badgesY, "Badge narrativi", {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: "#9ff5e9",
        fontStyle: "bold",
      }),
    );

    entry.badges.forEach((badge, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const badgeY = badgesY + 42 + row * 34;
      this.add(scene.add.rectangle(34 + col * 360, badgeY + 10, 320, 28, 0x1a3542, 0.95).setOrigin(0, 0.5).setStrokeStyle(1, 0x6be7d6, 0.22));
      this.add(
        scene.add.text(48 + col * 360, badgeY, badge, {
          fontFamily: "Inter, Arial",
          fontSize: "16px",
          color: "#f7d37a",
          wordWrap: { width: 288 },
        }),
      );
    });

    scene.add.existing(this);
  }
}
