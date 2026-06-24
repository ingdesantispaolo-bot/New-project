import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { settingsSystem } from "../core/SettingsSystem";

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
  private streak = 0;
  private answerCards = new WeakMap<Phaser.Scene, Phaser.GameObjects.Container>();

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

    if (tone === "success") {
      this.streak += 1;
      if (this.streak >= 3) {
        this.celebrateStreak(scene, this.streak);
      }
    } else if (tone === "warning" || tone === "complete") {
      this.streak = 0;
    }
  }

  /** Resets the running combo, e.g. when a new exercise session begins. */
  resetStreak(): void {
    this.streak = 0;
  }

  /** Rewards consecutive correct answers with an escalating combo flourish. */
  private celebrateStreak(scene: Phaser.Scene, streak: number): void {
    const { width } = scene.scale;
    const message =
      streak >= 8 ? `SERIE x${streak} · INARRESTABILE!` :
      streak >= 5 ? `SERIE x${streak} · OTTIMA!` :
      `SERIE x${streak}!`;
    const reduced = settingsSystem.effectsReduced();

    const label = scene.add.text(width / 2, 150, message, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f7d37a",
      fontStyle: "bold",
      stroke: "#3a2a08",
      strokeThickness: 5,
      shadow: { offsetX: 0, offsetY: 3, color: "#000000", blur: 8, fill: true },
    }).setOrigin(0.5).setDepth(9700).setScrollFactor(0).setScale(reduced ? 1 : 0.4).setAlpha(0);

    scene.tweens.add({
      targets: label,
      scale: 1,
      alpha: 1,
      duration: reduced ? 120 : 260,
      ease: "Back.easeOut",
      hold: 760,
      yoyo: true,
      completeDelay: 120,
      onComplete: () => label.destroy(),
    });

    if (!reduced) {
      const count = Math.min(34, 14 + streak * 2);
      for (let i = 0; i < count; i += 1) {
        const angle = Phaser.Math.FloatBetween(-Math.PI, Math.PI);
        const distance = Phaser.Math.Between(60, 200);
        const star = scene.add.circle(width / 2, 150, Phaser.Math.Between(2, 6), i % 2 === 0 ? 0xf7d37a : 0x6be7d6, 0.92)
          .setDepth(9690).setScrollFactor(0);
        scene.tweens.add({
          targets: star,
          x: width / 2 + Math.cos(angle) * distance,
          y: 150 + Math.sin(angle) * distance,
          alpha: 0,
          scale: 0.2,
          duration: Phaser.Math.Between(420, 820),
          ease: "Sine.easeOut",
          onComplete: () => star.destroy(),
        });
      }
    }

    // Short ascending arpeggio whose top note climbs with the streak.
    const base = 523;
    const top = base * (1 + Math.min(streak, 8) * 0.08);
    audioManager.playToneSequence([
      { frequency: base, durationMs: 90 },
      { frequency: base * 1.26, durationMs: 90 },
      { frequency: top, durationMs: 140 },
    ]);
  }

  answer(
    scene: Phaser.Scene,
    correct: boolean,
    selectedAnswer: string,
    correctAnswer: string,
    explanation?: string,
  ): void {
    this.answerCards.get(scene)?.destroy(true);
    const compact = (value: string, limit: number): string => value.length > limit ? `${value.slice(0, limit - 1).trimEnd()}…` : value;
    const selectedText = compact(selectedAnswer || "nessuna risposta", 105);
    const correctText = compact(correctAnswer, 120);
    const explanationText = explanation ? compact(explanation, 180) : undefined;
    const { width } = scene.scale;
    const color = correct ? 0x2ed889 : 0xc94b55;
    const textColor = correct ? "#9ff5e9" : "#ffb0a8";
    const container = scene.add.container(width / 2, 184).setDepth(9750).setScrollFactor(0);
    const panelHeight = explanationText ? 154 : 126;
    container.add(scene.add.rectangle(6, 8, 720, panelHeight, 0x000000, 0.38));
    container.add(scene.add.rectangle(0, 0, 720, panelHeight, 0x061019, 0.98).setStrokeStyle(3, color, 0.98));
    container.add(scene.add.rectangle(-352, 0, 9, panelHeight - 14, color, 1));
    container.add(scene.add.circle(-316, -panelHeight / 2 + 34, 20, color, 0.2).setStrokeStyle(2, color, 1));
    container.add(scene.add.text(-316, -panelHeight / 2 + 33, correct ? "✓" : "!", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: textColor,
      fontStyle: "bold",
    }).setOrigin(0.5));
    container.add(scene.add.text(-282, -panelHeight / 2 + 22, correct ? "RISPOSTA ESATTA" : "RISPOSTA ERRATA", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: textColor,
      fontStyle: "bold",
    }));
    container.add(scene.add.text(-282, -panelHeight / 2 + 50, `Hai scelto: ${selectedText}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7dce7",
      wordWrap: { width: 610, useAdvancedWrap: true },
    }));
    container.add(scene.add.text(-282, -panelHeight / 2 + 76, `${correct ? "Conferma" : "Risposta corretta"}: ${correctText}`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 610, useAdvancedWrap: true },
    }));
    if (explanationText) {
      container.add(scene.add.text(-282, -panelHeight / 2 + 108, explanationText, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 610, useAdvancedWrap: true },
      }));
    }
    container.setAlpha(0).setY(158);
    this.answerCards.set(scene, container);
    scene.tweens.add({
      targets: container,
      y: 184,
      alpha: 1,
      duration: 180,
      ease: "Sine.easeOut",
      yoyo: true,
      hold: correct ? 1600 : 2100,
      completeDelay: 160,
      onComplete: () => {
        if (this.answerCards.get(scene) === container) this.answerCards.delete(scene);
        container.destroy(true);
      },
    });
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
