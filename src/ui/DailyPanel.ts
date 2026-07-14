import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { saveSystem } from "../core/SaveSystem";
import { Button } from "./Button";

type DailyPanelOptions = {
  /** Called after the player claims the completed-day bonus (granted > 0). */
  onClaim?: (granted: number) => void;
  /** Called whenever the panel closes (claim or dismiss). */
  onClose?: () => void;
};

/**
 * "Missione del giorno" modal, shared between the main menu and the explorable
 * hub. Callers on a scrolling camera must route the returned container to their
 * UI camera (markUi).
 */
export function openDailyPanel(scene: Phaser.Scene, options: DailyPanelOptions = {}): Phaser.GameObjects.Container {
  const objectives = saveSystem.dailyObjectives();
  const streak = saveSystem.dailyStreak;
  const allDone = objectives.every((objective) => objective.done);
  const claimed = saveSystem.data.daily?.claimed ?? false;
  const rewardAmount = saveSystem.dailyRewardAmount();
  const subjectsToday = saveSystem.data.daily?.energySubjects?.length ?? 0;

  const modal = scene.add.container(0, 0).setDepth(1500);
  const close = (): void => {
    modal.destroy(true);
    options.onClose?.();
  };
  modal.add(scene.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
  modal.add(scene.add.rectangle(640, 360, 720, 476, 0x07151d, 0.99).setStrokeStyle(2, 0xf6c85f, 0.6));
  modal.add(scene.add.rectangle(300, 170, 5, 44, 0xf6c85f, 0.95).setOrigin(0));
  modal.add(scene.add.text(316, 170, "🔥 Missione del giorno", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }));
  modal.add(scene.add.text(316, 214, `Serie di ${streak} ${streak === 1 ? "giorno" : "giorni"} · varietà oggi: ${subjectsToday} attività · torna domani per non perderla.`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }));

  objectives.forEach((objective, index) => {
    const y = 272 + index * 62;
    modal.add(scene.add.rectangle(640, y, 640, 52, objective.done ? 0x123a2f : 0x0c1d2a, 0.95).setStrokeStyle(2, objective.done ? 0x2ed889 : 0x304653, 0.75));
    modal.add(scene.add.text(346, y, objective.done ? "✓" : "○", { fontFamily: "Inter, Arial", fontSize: "24px", color: objective.done ? "#2ed889" : "#6b7d84", fontStyle: "bold" }).setOrigin(0, 0.5));
    modal.add(scene.add.text(392, y - 9, objective.label, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0, 0.5));
    modal.add(scene.add.text(392, y + 12, `Progresso: ${objective.current}/${objective.target}`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0" }).setOrigin(0, 0.5));
  });

  const rewardY = 272 + objectives.length * 62 + 18;
  const rewardText = claimed
    ? `✦ Ricompensa del giorno ritirata: +${rewardAmount} ⚡`
    : allDone
      ? `✦ Obiettivi completati! Ritira +${rewardAmount} ⚡`
      : `Completa tutti gli obiettivi per +${rewardAmount} ⚡`;
  modal.add(scene.add.text(640, rewardY, rewardText, { fontFamily: "Inter, Arial", fontSize: "14px", color: allDone || claimed ? "#f7d37a" : "#9fb6c2", fontStyle: "bold" }).setOrigin(0.5));
  modal.add(scene.add.text(640, rewardY + 22, "Bonus varietà automatici: +15 per una nuova attività, poi soglie a 3/5/7 attività nel giorno.", {
    fontFamily: "Inter, Arial",
    fontSize: "11px",
    color: "#9fb6c2",
  }).setOrigin(0.5));
  if (allDone && !claimed) {
    modal.add(new Button(scene, 640, rewardY + 58, `Ritira +${rewardAmount} ⚡`, () => {
      const granted = saveSystem.claimDailyIfComplete();
      close();
      if (granted > 0) {
        options.onClaim?.(granted);
      }
    }, { width: 220, height: 44, fill: 0x3a3220, stroke: 0xf6c85f, fontSize: 14 }));
  } else {
    modal.add(new Button(scene, 640, rewardY + 58, "Ho capito", close, { width: 200, height: 44, fill: 0x263743 }));
  }
  return modal;
}

/** Celebratory toast for the daily bonus; same shared-camera caveat as the panel. */
export function showDailyRewardToast(scene: Phaser.Scene, amount: number): Phaser.GameObjects.Container {
  const toast = scene.add.container(640, 150).setDepth(1600).setAlpha(0);
  toast.add(scene.add.rectangle(0, 0, 440, 54, 0x07151d, 0.96).setStrokeStyle(2, 0xf6c85f, 0.9));
  toast.add(scene.add.text(0, 0, `✦ Missione del giorno completata!  +${amount} ⚡`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
  audioManager.play("panelOpen");
  scene.tweens.add({
    targets: toast, alpha: 1, y: 162, duration: 300, ease: "Cubic.easeOut",
    onComplete: () => scene.tweens.add({ targets: toast, alpha: 0, delay: 2600, duration: 600, onComplete: () => toast.destroy(true) }),
  });
  return toast;
}
