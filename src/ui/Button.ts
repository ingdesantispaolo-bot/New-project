import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";

export type ButtonOptions = {
  width?: number;
  height?: number;
  fill?: number;
  hoverFill?: number;
  stroke?: number;
  fontSize?: number;
  wordWrapWidth?: number;
  actionDelayMs?: number;
  cooldownMs?: number;
};

export class Button extends Phaser.GameObjects.Container {
  private background: Phaser.GameObjects.Rectangle;
  private highlight: Phaser.GameObjects.Rectangle;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    label: string,
    onClick: () => void,
    options: ButtonOptions = {},
  ) {
    super(scene, x, y);

    const width = options.width ?? 260;
    const height = options.height ?? 56;
    const fill = options.fill ?? 0x173244;
    const hoverFill = options.hoverFill ?? 0x23556a;
    const supportsHover = typeof window === "undefined" || window.matchMedia?.("(hover: hover)").matches !== false;
    const actionDelayMs = options.actionDelayMs ?? 0;
    const cooldownMs = options.cooldownMs ?? 90;
    let lastClickAt = 0;
    let pressed = false;

    const shadow = scene.add.rectangle(5, 7, width, height, 0x000000, 0.28);
    this.background = scene.add
      .rectangle(0, 0, width, height, fill, 0.96)
      .setStrokeStyle(2, options.stroke ?? 0x6be7d6, 0.72);
    this.highlight = scene.add.rectangle(0, -height / 2 + 2, width - 10, 2, options.stroke ?? 0x6be7d6, 0.68);
    const baseFontSize = options.fontSize ?? 20;
    const text = scene.add
      .text(0, 0, label, {
        fontFamily: "Inter, Arial",
        fontSize: `${baseFontSize}px`,
        color: "#f5fbff",
        align: "center",
        wordWrap: { width: options.wordWrapWidth ?? width - 22, useAdvancedWrap: true },
        shadow: { offsetX: 0, offsetY: 2, color: "#000000", blur: 4, fill: true },
      })
      .setOrigin(0.5);

    let fittedFontSize = baseFontSize;
    while ((text.width > width - 16 || text.height > height - 10) && fittedFontSize > 10) {
      fittedFontSize -= 1;
      text.setFontSize(fittedFontSize);
      text.setWordWrapWidth(options.wordWrapWidth ?? width - 22, true);
    }

    const hitZone = scene.add.zone(0, 0, Math.max(width, 56), Math.max(height, 52)).setOrigin(0.5);
    this.add([shadow, this.background, this.highlight, text, hitZone]);
    this.setSize(width, height);
    hitZone.setInteractive({ useHandCursor: true })
      .on("pointerover", () => {
        if (!supportsHover || pressed) return;
        this.background.setFillStyle(hoverFill, 1);
        this.highlight.setAlpha(1);
        scene.tweens.killTweensOf(this);
        this.setScale(1.012);
      })
      .on("pointerout", () => {
        if (pressed) return;
        this.background.setFillStyle(fill, 0.96);
        this.highlight.setAlpha(0.72);
        scene.tweens.killTweensOf(this);
        this.setScale(1);
      })
      .on("pointerdown", () => {
        const now = performance.now();
        if (now - lastClickAt < cooldownMs) return;
        lastClickAt = now;
        pressed = true;
        scene.tweens.killTweensOf(this);
        this.background.setFillStyle(hoverFill, 1);
        this.highlight.setAlpha(1);
        this.setScale(0.985);
        audioManager.play("click");
        const runAction = () => {
          if (!this.scene || !this.active) return;
          onClick();
          pressed = false;
          if (!this.scene || !this.active) return;
          scene.tweens.killTweensOf(this);
          scene.tweens.add({
            targets: this,
            scale: 1,
            duration: 60,
            onComplete: () => {
              if (!this.scene || !this.active) return;
              this.background.setFillStyle(fill, 0.96);
              this.highlight.setAlpha(0.72);
            },
          });
        };
        if (actionDelayMs <= 0) {
          runAction();
        } else {
          scene.time.delayedCall(actionDelayMs, runAction);
        }
      });

    scene.add.existing(this);
  }
}
