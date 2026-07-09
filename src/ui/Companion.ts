import Phaser from "phaser";
import { settingsSystem } from "../core/SettingsSystem";
import { rewardSystem } from "../core/RewardSystem";

export type CompanionMood = "correct" | "wrong" | "combo";

/**
 * "Bit" — il compagno-mascotte del giocatore.
 *
 * Un piccolo drone amichevole disegnato con sole forme (nessun asset), che vive
 * in un angolo dello schermo e REAGISCE alle risposte: fa un saltello quando
 * indovini, si affloscia quando sbagli, esulta sulle combo. Serve a dare "vita"
 * al gioco senza toccare la logica delle scene: è pilotato dal singleton
 * {@link OutcomeFeedback}, che ogni esercizio già chiama.
 */
export class Companion {
  private rig: Phaser.GameObjects.Container;
  private light: Phaser.GameObjects.Arc;
  private leftEye: Phaser.GameObjects.Arc;
  private rightEye: Phaser.GameObjects.Arc;
  private idle?: Phaser.Tweens.Tween;
  private accent: number;

  constructor(private scene: Phaser.Scene, x: number, y: number) {
    // Colour reflects the cosmetic bought with earned energy (default cyan).
    this.accent = rewardSystem.colorForSlot("bot", 0x6be7d6);
    const root = scene.add.container(x, y).setScrollFactor(0).setDepth(9400);
    const rig = scene.add.container(0, 0);
    root.add(rig);
    this.rig = rig;

    rig.add(scene.add.ellipse(0, 30, 48, 12, 0x000000, 0.28));
    rig.add(scene.add.circle(0, 0, 23, 0x0a2430, 0.55)); // glow halo
    rig.add(scene.add.circle(0, 0, 21, 0x143a48, 0.98).setStrokeStyle(2, this.accent, 0.95));
    rig.add(scene.add.circle(0, -1, 14, 0x061620, 0.96)); // visor
    this.leftEye = scene.add.circle(-6, -2, 3.4, 0x8ff6ea, 1);
    this.rightEye = scene.add.circle(6, -2, 3.4, 0x8ff6ea, 1);
    rig.add(this.leftEye);
    rig.add(this.rightEye);
    rig.add(scene.add.rectangle(0, -22, 2, 10, this.accent, 0.9)); // antenna
    this.light = scene.add.circle(0, -28, 3.6, this.accent, 1);
    rig.add(this.light);

    const reduced = settingsSystem.effectsReduced();
    if (!reduced) {
      this.idle = scene.tweens.add({
        targets: rig,
        y: -4,
        duration: 1600,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1,
      });
      scene.tweens.add({
        targets: this.light,
        alpha: 0.4,
        duration: 900,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1,
      });
    }
  }

  react(mood: CompanionMood): void {
    if (!this.scene.sys?.isActive?.()) return;
    const reduced = settingsSystem.effectsReduced();
    const lightColor = mood === "wrong" ? 0xff7b6b : mood === "combo" ? 0xf6c85f : 0x7cf6a6;
    this.light.setFillStyle(lightColor, 1);
    const eyeColor = mood === "wrong" ? 0xffb0a8 : 0x8ff6ea;
    this.leftEye.setFillStyle(eyeColor, 1);
    this.rightEye.setFillStyle(eyeColor, 1);
    this.popEmoji(mood === "wrong" ? "😖" : mood === "combo" ? "🤩" : "😄");

    if (reduced) {
      this.scene.time.delayedCall(700, () => this.light.setFillStyle(this.accent, 1));
      return;
    }
    this.idle?.pause();
    this.rig.setScale(1).setAngle(0);

    if (mood === "wrong") {
      this.scene.tweens.add({ targets: this.rig, x: { from: -6, to: 6 }, duration: 60, yoyo: true, repeat: 4, ease: "Sine.easeInOut", onComplete: () => this.settle() });
      this.scene.tweens.add({ targets: this.rig, scaleY: 0.82, duration: 120, yoyo: true, ease: "Sine.easeInOut" });
    } else if (mood === "combo") {
      this.burst(lightColor);
      this.scene.tweens.add({ targets: this.rig, y: -26, scaleX: 1.18, scaleY: 1.18, angle: 360, duration: 460, ease: "Back.easeOut", yoyo: true, onComplete: () => this.settle() });
    } else {
      this.scene.tweens.add({ targets: this.rig, scaleY: 0.72, scaleX: 1.16, duration: 90, yoyo: true, ease: "Sine.easeOut" });
      this.scene.tweens.add({ targets: this.rig, y: -16, duration: 200, ease: "Back.easeOut", yoyo: true, onComplete: () => this.settle() });
    }
  }

  private settle(): void {
    this.rig.setAngle(0).setScale(1);
    this.scene.time.delayedCall(500, () => {
      if (this.scene.sys?.isActive?.()) this.light.setFillStyle(this.accent, 1);
    });
    this.idle?.resume();
  }

  private popEmoji(glyph: string): void {
    const emoji = this.scene.add.text(26, -22, glyph, { fontFamily: "Inter, Arial", fontSize: "22px" })
      .setScrollFactor(0).setDepth(9410).setOrigin(0.5).setAlpha(0);
    // position relative to the rig's world position
    const world = this.rig.parentContainer ?? this.rig;
    emoji.setPosition((world.x ?? 0) + 26, (world.y ?? 0) - 22);
    this.scene.tweens.add({
      targets: emoji,
      y: emoji.y - 26,
      alpha: { from: 0, to: 1 },
      duration: 220,
      ease: "Back.easeOut",
      yoyo: true,
      hold: 520,
      completeDelay: 60,
      onComplete: () => emoji.destroy(),
    });
  }

  private burst(color: number): void {
    const parent = this.rig.parentContainer;
    const cx = parent?.x ?? 0;
    const cy = parent?.y ?? 0;
    for (let i = 0; i < 12; i += 1) {
      const angle = Phaser.Math.FloatBetween(-Math.PI, Math.PI);
      const dist = Phaser.Math.Between(30, 80);
      const star = this.scene.add.circle(cx, cy, Phaser.Math.Between(2, 5), i % 2 === 0 ? color : 0x8ff6ea, 0.95)
        .setScrollFactor(0).setDepth(9405);
      this.scene.tweens.add({
        targets: star,
        x: cx + Math.cos(angle) * dist,
        y: cy + Math.sin(angle) * dist,
        alpha: 0,
        scale: 0.2,
        duration: Phaser.Math.Between(360, 640),
        ease: "Sine.easeOut",
        onComplete: () => star.destroy(),
      });
    }
  }
}
