import Phaser from "phaser";
import { settingsSystem } from "../core/SettingsSystem";

// A small, non-blocking NORA speech chip (face + bubble) that slides in at the
// bottom-left, holds a line, then leaves. Gives the assistant a visible
// presence at key beats without blocking play.
class NoraChip {
  private current = new WeakMap<Phaser.Scene, Phaser.GameObjects.Container>();

  say(scene: Phaser.Scene, text: string, tone: "info" | "success" | "warning" = "info"): void {
    this.current.get(scene)?.destroy(true);

    const accent = tone === "success" ? 0x6be7d6 : tone === "warning" ? 0xf6c85f : 0x9ff5e9;
    const width = 470;
    const height = 86;
    const x = 28;
    const y = 612;

    const container = scene.add.container(x - 40, y).setDepth(9300).setScrollFactor(0).setAlpha(0);

    container.add(scene.add.rectangle(6, 8, width, height, 0x000000, 0.34).setOrigin(0));
    container.add(scene.add.rectangle(0, 0, width, height, 0x061019, 0.97).setOrigin(0).setStrokeStyle(2, accent, 0.9));
    container.add(scene.add.rectangle(0, 0, 5, height, accent, 1).setOrigin(0));

    // NORA "face": a calm core with an orbit ring.
    const faceX = 48;
    const faceY = height / 2;
    container.add(scene.add.circle(faceX, faceY, 26, 0x0c2630, 1).setStrokeStyle(2, accent, 0.8));
    const core = scene.add.circle(faceX, faceY, 11, accent, 0.95);
    container.add(core);
    container.add(scene.add.circle(faceX, faceY, 4, 0xffffff, 0.9));

    container.add(scene.add.text(86, 14, "NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f6c85f",
      fontStyle: "bold",
    }));
    container.add(scene.add.text(86, 34, text, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#eaf4f8",
      wordWrap: { width: width - 104, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    this.current.set(scene, container);

    const reduced = settingsSystem.effectsReduced();
    scene.tweens.add({
      targets: container,
      x,
      alpha: 1,
      duration: reduced ? 120 : 260,
      ease: "Back.easeOut",
    });
    if (!reduced) {
      scene.tweens.add({ targets: core, scale: 1.3, alpha: 0.7, duration: 720, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }

    scene.tweens.add({
      targets: container,
      alpha: 0,
      delay: 3600,
      duration: 360,
      ease: "Sine.easeIn",
      onComplete: () => {
        if (this.current.get(scene) === container) {
          this.current.delete(scene);
        }
        container.destroy(true);
      },
    });
  }
}

export const noraChip = new NoraChip();
