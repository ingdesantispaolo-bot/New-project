import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";

export type OutcomeTone = "info" | "hint" | "success" | "warning" | "complete";

type OutcomeSpec = {
  color: number;
  textColor: string;
  label: string;
  icon: string;
  flashAlpha: number;
  shake?: { duration: number; intensity: number };
  particles: number;
};

const specs: Record<OutcomeTone, OutcomeSpec> = {
  info: {
    color: 0x6be7d6,
    textColor: "#d9eaf1",
    label: "Scansione",
    icon: "i",
    flashAlpha: 0.04,
    particles: 6,
  },
  hint: {
    color: 0xf6c85f,
    textColor: "#f7d37a",
    label: "Indizio",
    icon: "?",
    flashAlpha: 0.07,
    particles: 10,
  },
  success: {
    color: 0x6be7d6,
    textColor: "#9ff5e9",
    label: "Risposta corretta",
    icon: "✓",
    flashAlpha: 0.12,
    particles: 18,
  },
  warning: {
    color: 0xc94b55,
    textColor: "#ffb36b",
    label: "Risposta errata",
    icon: "!",
    flashAlpha: 0.16,
    shake: { duration: 180, intensity: 0.006 },
    particles: 14,
  },
  complete: {
    color: 0xf6c85f,
    textColor: "#f7d37a",
    label: "Missione completata",
    icon: "★",
    flashAlpha: 0.16,
    particles: 28,
  },
};

function hexToRgb(color: number): { r: number; g: number; b: number } {
  return {
    r: (color >> 16) & 255,
    g: (color >> 8) & 255,
    b: color & 255,
  };
}

class OutcomeFeedback {
  private lastEffectAt = 0;
  private lastTone?: OutcomeTone;

  play(scene: Phaser.Scene, tone: OutcomeTone, label?: string): void {
    const now = Date.now();
    const minGap = tone === "info" ? 360 : 140;
    if (this.lastTone === tone && now - this.lastEffectAt < minGap) {
      return;
    }
    this.lastTone = tone;
    this.lastEffectAt = now;

    const spec = specs[tone];
    const sounds = {
      info: "neutral",
      hint: "hint",
      success: "correct",
      warning: "wrong",
      complete: "complete",
    } as const;
    audioManager.playOutcome(sounds[tone]);
    const camera = scene.cameras.main;
    const rgb = hexToRgb(spec.color);
    camera.flash(180, rgb.r, rgb.g, rgb.b, false);
    if (spec.shake) {
      camera.shake(spec.shake.duration, spec.shake.intensity);
    }
    this.drawPulse(scene, spec);
    this.drawBanner(scene, spec, label);
    this.drawParticles(scene, spec, tone);
  }

  private drawPulse(scene: Phaser.Scene, spec: OutcomeSpec): void {
    const { width, height } = scene.scale;
    const pulse = scene.add.rectangle(width / 2, height / 2, width, height, spec.color, spec.flashAlpha)
      .setDepth(9500)
      .setScrollFactor(0);
    scene.tweens.add({
      targets: pulse,
      alpha: 0,
      duration: 420,
      ease: "Sine.easeOut",
      onComplete: () => pulse.destroy(),
    });
  }

  private drawBanner(scene: Phaser.Scene, spec: OutcomeSpec, detail?: string): void {
    const { width } = scene.scale;
    const hasDetail = Boolean(detail && detail.toLocaleLowerCase() !== spec.label.toLocaleLowerCase());
    const panelHeight = hasDetail ? 82 : 62;
    const container = scene.add.container(width / 2, 88).setDepth(9600).setScrollFactor(0);
    const shadow = scene.add.rectangle(4, 6, 500, panelHeight, 0x000000, 0.34);
    const panel = scene.add.rectangle(0, 0, 500, panelHeight, 0x061019, 0.97)
      .setStrokeStyle(3, spec.color, 0.96);
    const left = scene.add.rectangle(-244, 0, 8, panelHeight - 12, spec.color, 1);
    const iconRing = scene.add.circle(-208, 0, 20, spec.color, 0.18)
      .setStrokeStyle(2, spec.color, 0.95);
    const icon = scene.add.text(-208, -1, spec.icon, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: spec.textColor,
      fontStyle: "bold",
    }).setOrigin(0.5);
    const title = scene.add.text(-174, hasDetail ? -15 : 0, spec.label.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: spec.textColor,
      fontStyle: "bold",
    }).setOrigin(0, 0.5);
    container.add([shadow, panel, left, iconRing, icon, title]);
    if (hasDetail) {
      container.add(scene.add.text(-174, 14, detail!, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#d9eaf1",
        wordWrap: { width: 390, useAdvancedWrap: true },
      }).setOrigin(0, 0.5));
    }
    container.setAlpha(0);
    container.setY(64);
    scene.tweens.add({
      targets: container,
      y: 88,
      alpha: 1,
      duration: 170,
      ease: "Sine.easeOut",
      yoyo: true,
      hold: spec.label.startsWith("Risposta") ? 1600 : 1100,
      completeDelay: 180,
      onComplete: () => container.destroy(),
    });
  }

  private drawParticles(scene: Phaser.Scene, spec: OutcomeSpec, tone: OutcomeTone): void {
    const { width, height } = scene.scale;
    const originY = tone === "warning" ? height * 0.48 : height * 0.36;
    for (let i = 0; i < spec.particles; i += 1) {
      const angle = Phaser.Math.FloatBetween(-Math.PI, Math.PI);
      const distance = Phaser.Math.Between(34, tone === "complete" ? 180 : 118);
      const particle = scene.add.circle(width / 2, originY, Phaser.Math.Between(2, 5), spec.color, 0.86)
        .setDepth(9550)
        .setScrollFactor(0);
      scene.tweens.add({
        targets: particle,
        x: width / 2 + Math.cos(angle) * distance,
        y: originY + Math.sin(angle) * distance,
        alpha: 0,
        scale: 0.25,
        duration: Phaser.Math.Between(360, 720),
        ease: "Sine.easeOut",
        onComplete: () => particle.destroy(),
      });
    }
  }
}

export const outcomeFeedback = new OutcomeFeedback();
