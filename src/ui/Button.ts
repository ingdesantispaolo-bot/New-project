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
  private hitTarget: Phaser.GameObjects.Rectangle;

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
    const hitWidth = width;
    const hitHeight = height;
    const fill = options.fill ?? 0x173244;
    const hoverFill = options.hoverFill ?? 0x23556a;
    const supportsHover = typeof window === "undefined" || window.matchMedia?.("(hover: hover)").matches !== false;
    const actionDelayMs = options.actionDelayMs ?? 0;
    const cooldownMs = options.cooldownMs ?? 90;
    let lastClickAt = 0;
    let pressed = false;
    let pointerStartedInside = false;

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

    this.hitTarget = scene.add.rectangle(0, 0, hitWidth, hitHeight, 0x000000, 0.001);

    this.add([shadow, this.background, this.highlight, text, this.hitTarget]);
    this.setSize(hitWidth, hitHeight);
    this.setInteractive(
      new Phaser.Geom.Rectangle(-hitWidth / 2, -hitHeight / 2, hitWidth, hitHeight),
      Phaser.Geom.Rectangle.Contains,
    );
    if (this.input) {
      this.input.cursor = "pointer";
    }
    this
      .on("pointerover", () => {
        if (!supportsHover || pressed) return;
        this.background.setFillStyle(hoverFill, 1);
        this.highlight.setAlpha(1);
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setScale(1);
      })
      .on("pointerout", () => {
        if (pressed) return;
        this.background.setFillStyle(fill, 0.96);
        this.highlight.setAlpha(0.72);
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setScale(1);
      })
      .on("pointerdown", () => {
        const now = performance.now();
        if (now - lastClickAt < cooldownMs) return;
        lastClickAt = now;
        pressed = true;
        pointerStartedInside = true;
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setFillStyle(hoverFill, 1);
        this.highlight.setAlpha(1);
        this.background.setScale(1);
        audioManager.play("click");
      })
      .on("pointerup", () => {
        if (!pointerStartedInside) return;
        const runAction = () => {
          if (!this.scene || !this.active) return;
          onClick();
          pressed = false;
          pointerStartedInside = false;
          if (!this.scene || !this.active) return;
          scene.tweens.killTweensOf([this.background, this.highlight]);
          this.background.setScale(1);
          this.background.setFillStyle(fill, 0.96);
          this.highlight.setAlpha(0.72);
        };
        if (actionDelayMs <= 0) {
          runAction();
        } else {
          scene.time.delayedCall(actionDelayMs, runAction);
        }
      })
      .on("pointerupoutside", () => {
        pressed = false;
        pointerStartedInside = false;
        this.background.setFillStyle(fill, 0.96);
        this.highlight.setAlpha(0.72);
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setScale(1);
      });

    scene.add.existing(this);
  }
}
