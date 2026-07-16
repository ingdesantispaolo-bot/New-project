import Phaser from "phaser";
import { Button } from "../../../ui/Button";
import { SceneChrome } from "../../../ui/SceneChrome";

export type SprintSummaryModalState = {
  title: string;
  passed: boolean;
  correct: number;
  wrong: number;
  accuracy: number;
  bestStreak: number;
  netScore: number;
  feedback: string;
  resolutionText: string;
  energyText?: string;
  actionLabel: string;
};

export type SprintSummaryModalHandlers = {
  onAction(modal: Phaser.GameObjects.Container): void;
};

export function addSprintSummaryModal(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  state: SprintSummaryModalState,
  handlers: SprintSummaryModalHandlers,
): Phaser.GameObjects.Container {
  const modal = scene.add.container(0, 0).setDepth(1300);
  SceneChrome.modalInputBlocker(scene, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
  modal.add(scene.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
  modal.add(scene.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
    .setStrokeStyle(2, state.passed ? 0x6be7d6 : 0xf7d37a, 0.76));
  modal.add(scene.add.text(230, 160, state.title, {
    fontFamily: "Inter, Arial",
    fontSize: "24px",
    color: state.passed ? "#9ff5e9" : "#f7d37a",
    fontStyle: "bold",
  }));
  modal.add(scene.add.text(230, 210, [
    `Risposte corrette: ${state.correct}`,
    `Errori: ${state.wrong}`,
    `Precisione: ${state.accuracy}%`,
    `Serie migliore: ${state.bestStreak}`,
    `Punti sprint: ${state.netScore}`,
  ].join("\n"), {
    fontFamily: "Inter, Arial",
    fontSize: "15px",
    color: "#f5fbff",
    lineSpacing: 7,
  }));
  modal.add(scene.add.rectangle(548, 212, 408, 128, 0x102533, 0.78).setOrigin(0)
    .setStrokeStyle(1, 0x6be7d6, 0.3));
  modal.add(scene.add.text(572, 234, state.feedback, {
    fontFamily: "Inter, Arial",
    fontSize: "14px",
    color: "#d9eaf1",
    wordWrap: { width: 354 },
    lineSpacing: 5,
  }));
  modal.add(scene.add.rectangle(230, 378, 740, 74, 0x0b1e2a, 0.82).setOrigin(0)
    .setStrokeStyle(1, 0xf7d37a, 0.36));
  modal.add(scene.add.text(254, 394, state.resolutionText, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#d9eaf1",
    wordWrap: { width: 690 },
    lineSpacing: 4,
  }));
  if (state.energyText) {
    modal.add(scene.add.text(254, 456, state.energyText, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 690 },
    }));
  }
  modal.add(new Button(scene, 612, 506, state.actionLabel, () => handlers.onAction(modal), {
    width: 270,
    height: 54,
    fill: state.passed ? 0x173b36 : 0x263743,
    stroke: state.passed ? 0x6be7d6 : 0xf7d37a,
    fontSize: 16,
  }));
  overlay.add(modal);
  return modal;
}
