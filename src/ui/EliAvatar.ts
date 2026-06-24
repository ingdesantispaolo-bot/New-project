import Phaser from "phaser";
import { settingsSystem } from "../core/SettingsSystem";

/**
 * Layered, lightly animated avatar for Eli. Built from primitives so it needs
 * no spritesheet, but reads as a character: glow, head with visor, body,
 * antenna and a grounded shadow. Idle breathing + blinking give it life;
 * `playInteract` adds a small reaction on interaction. Respects reduced motion.
 */
export class EliAvatar extends Phaser.GameObjects.Container {
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly figure: Phaser.GameObjects.Container;
  private readonly visor: Phaser.GameObjects.Rectangle;
  private readonly antennaTip: Phaser.GameObjects.Arc;
  private idleTween?: Phaser.Tweens.Tween;
  private blinkEvent?: Phaser.Time.TimerEvent;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y);

    // Grounded contact shadow sits in scene space, slightly below the feet.
    this.shadow = scene.add.ellipse(0, 30, 58, 16, 0x000000, 0.32);
    this.add(this.shadow);

    // Soft aura behind the character.
    const glow = scene.textures.exists("eli-atlas")
      ? scene.add.image(0, -12, "eli-atlas", "soft-flare")
      : scene.add.image(0, -12, "soft-glow");
    glow.setTint(0xf6c85f).setAlpha(0.16).setScale(1.25);
    this.add(glow);

    // Everything that "breathes" lives in this inner container.
    this.figure = scene.add.container(0, 0);

    // Legs / base.
    this.figure.add(scene.add.triangle(0, 14, 0, -26, 24, 28, -24, 28, 0x2e7f75, 1).setStrokeStyle(2, 0x9ff5e9, 0.55));
    // Torso panel.
    this.figure.add(scene.add.rectangle(0, 21, 26, 22, 0x173b46, 0.85).setStrokeStyle(1, 0x9ff5e9, 0.4));
    this.figure.add(scene.add.rectangle(0, 18, 14, 3, 0x6be7d6, 0.7));
    // Arms.
    this.figure.add(scene.add.rectangle(-15, 12, 6, 18, 0x2e7f75, 1).setStrokeStyle(1, 0x9ff5e9, 0.4).setOrigin(0.5));
    this.figure.add(scene.add.rectangle(15, 12, 6, 18, 0x2e7f75, 1).setStrokeStyle(1, 0x9ff5e9, 0.4).setOrigin(0.5));
    // Head.
    this.figure.add(scene.add.circle(0, -20, 14, 0xf6c85f, 1).setStrokeStyle(2, 0xffe6a0, 0.8));
    // Visor — the expressive bit; collapses vertically to "blink".
    this.visor = scene.add.rectangle(0, -21, 18, 7, 0x0c1f29, 0.92).setStrokeStyle(1, 0x6be7d6, 0.7);
    this.figure.add(this.visor);
    this.figure.add(scene.add.rectangle(-4, -22, 4, 2, 0x6be7d6, 0.95));
    this.figure.add(scene.add.rectangle(5, -22, 3, 2, 0x9ff5e9, 0.9));
    // Antenna.
    this.figure.add(scene.add.rectangle(0, -34, 2, 10, 0xffe6a0, 0.8));
    this.antennaTip = scene.add.circle(0, -40, 3, 0x6be7d6, 1);
    this.figure.add(this.antennaTip);

    this.add(this.figure);

    scene.add.existing(this);
    this.startIdle();

    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.stopAnimations());
    scene.events.once(Phaser.Scenes.Events.DESTROY, () => this.stopAnimations());
  }

  private startIdle(): void {
    if (settingsSystem.effectsReduced()) {
      return;
    }
    const scene = this.scene;
    // Breathing bob.
    this.idleTween = scene.tweens.add({
      targets: this.figure,
      y: -4,
      duration: 1500,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
    // Antenna tip pulse.
    scene.tweens.add({
      targets: this.antennaTip,
      scale: 1.5,
      alpha: 0.7,
      duration: 900,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
    this.scheduleBlink();
  }

  private scheduleBlink(): void {
    this.blinkEvent = this.scene.time.delayedCall(Phaser.Math.Between(2200, 4200), () => {
      if (!this.scene || !this.active) return;
      this.scene.tweens.add({
        targets: this.visor,
        scaleY: 0.15,
        duration: 70,
        yoyo: true,
        ease: "Sine.easeOut",
      });
      this.scheduleBlink();
    });
  }

  /** Quick "look up / acknowledge" reaction, e.g. when inspecting an object. */
  playInteract(): void {
    if (settingsSystem.effectsReduced()) {
      this.antennaTip.setScale(1.6);
      this.scene.time.delayedCall(180, () => this.antennaTip.setScale(1));
      return;
    }
    this.scene.tweens.add({
      targets: this.figure,
      scaleX: 1.08,
      scaleY: 0.92,
      duration: 110,
      yoyo: true,
      ease: "Sine.easeOut",
    });
    this.scene.tweens.add({
      targets: this.antennaTip,
      scale: 2.1,
      duration: 140,
      yoyo: true,
      ease: "Back.easeOut",
    });
  }

  /** Moves Eli to a position with a small walk lean, then runs onArrive. */
  walkTo(x: number, y: number, onArrive?: () => void): void {
    const reduced = settingsSystem.effectsReduced();
    const lean = x < this.x ? 0.06 : x > this.x ? -0.06 : 0;
    if (!reduced && lean !== 0) {
      this.figure.setRotation(lean);
    }
    this.scene.tweens.add({
      targets: this,
      x,
      y,
      duration: reduced ? 220 : 360,
      ease: "Sine.easeInOut",
      onComplete: () => {
        this.figure.setRotation(0);
        onArrive?.();
      },
    });
  }

  private stopAnimations(): void {
    this.idleTween?.stop();
    this.blinkEvent?.remove(false);
  }
}
