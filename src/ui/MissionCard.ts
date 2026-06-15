import Phaser from "phaser";
import { progressionSystem } from "../core/ProgressionSystem";
import type { MissionDefinition } from "../types/missionTypes";

export class MissionCard extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, x: number, y: number, mission: MissionDefinition) {
    super(scene, x, y);
    const summary = progressionSystem.getMissionSummary(mission);
    this.add(scene.add.rectangle(0, 0, 420, 210, 0x0d1b26, 0.92).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.4));
    this.add(
      scene.add.text(22, 18, `${summary.chapter.act}: ${mission.title}`, {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: "#f7fbff",
        fontStyle: "bold",
        wordWrap: { width: 370 },
      }),
    );
    this.add(
      scene.add.text(22, 58, summary.chapter.coreQuestion, {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#f7d37a",
        wordWrap: { width: 370 },
        lineSpacing: 5,
      }),
    );
    this.add(scene.add.rectangle(22, 126, 300, 8, 0x142736, 0.9).setOrigin(0));
    this.add(scene.add.rectangle(22, 126, Math.max(8, summary.percent * 3), 8, 0x6be7d6, 0.92).setOrigin(0));
    this.add(
      scene.add.text(22, 146, `Ora: ${summary.activeObjectiveLabel}`, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#d9eaf1",
        wordWrap: { width: 360 },
      }),
    );
    this.add(
      scene.add.text(22, 180, `${summary.completedObjectives}/${summary.totalObjectives} sistemi coerenti`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#9ff5e9",
      }),
    );
    scene.add.existing(this);
  }
}
