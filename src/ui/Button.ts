import Phaser from "phaser";
import { audioManager, type SoundKey } from "../core/AudioManager";

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
  soundKey?: SoundKey;
};

function stopInputPropagation(args: unknown[]): void {
  const event = args[args.length - 1] as { stopPropagation?: () => void } | undefined;
  event?.stopPropagation?.();
}

function inferButtonSoundKey(label: string): SoundKey {
  const normalized = label
    .replace(/[✓[\]·×]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();

  if (/^[1-8]$/.test(normalized)) return "levelSelect";
  if (/^(ok|conferma|conferma risposta|verifica|verifica sequenza|test finale|testa circuito|controlla|controlla ordine|esegui|registra|registra e continua)/.test(normalized)) {
    return "confirm";
  }
  if (/^(x|annulla|indietro|menu|hub|pulisci|pulisci scelta|azzera ordine|conserva|ho capito)/.test(normalized)) {
    return "cancel";
  }
  if (/(reset|azzera|ricomincia|riparti|riprova)/.test(normalized)) return "reset";
  if (/(livello successivo|scalata|progressiva|impulso nora|protezione|\+30)/.test(normalized)) return "progressiveStep";
  if (/(focus|allenati)/.test(normalized)) return "focusSelect";
  if (/(missione|nuova missione|avvia missione|missione rapida|riprendi missione)/.test(normalized)) return "missionStart";
  if (/(indizio|aiuto)/.test(normalized)) return "hint";
  if (/(ascolta|musica)/.test(normalized)) return "contextMusic";
  if (/(leggi|scansiona|analizza|decodifica|atlante|registro|diario|classifiche|report)/.test(normalized)) return "panelOpen";
  return "uiSelect";
}

export class Button extends Phaser.GameObjects.Container {
  private background: Phaser.GameObjects.Rectangle;
  private highlight: Phaser.GameObjects.Rectangle;
  private hitTarget: Phaser.GameObjects.Rectangle;
  private readonly fill: number;
  private enabled = true;
  private busy = false;

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
    this.fill = fill;
    const supportsHover = typeof window === "undefined" || window.matchMedia?.("(hover: hover)").matches !== false;
    const actionDelayMs = options.actionDelayMs ?? 0;
    const cooldownMs = options.cooldownMs ?? 45;
    const soundKey = options.soundKey ?? inferButtonSoundKey(label);
    let lastClickAt = 0;
    let pressed = false;
    let pointerStartedInside = false;
    let activePointerId: number | undefined;

    const resetVisual = () => {
      pressed = false;
      pointerStartedInside = false;
      activePointerId = undefined;
      scene.tweens.killTweensOf([this.background, this.highlight]);
      this.background.setScale(1);
      this.background.setFillStyle(fill, this.enabled ? 0.96 : 0.78);
      this.highlight.setAlpha(this.enabled ? 0.72 : 0.26);
    };

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

    this.hitTarget = scene.add.rectangle(0, 0, hitWidth, hitHeight, 0x000000, 0.001).setOrigin(0.5);
    this.hitTarget.setInteractive();
    if (this.hitTarget.input) {
      this.hitTarget.input.cursor = "pointer";
    }

    this.add([shadow, this.background, this.highlight, text, this.hitTarget]);
    this.setSize(hitWidth, hitHeight);
    this.hitTarget
      .on("pointerover", (...args: unknown[]) => {
        stopInputPropagation(args);
        if (!this.enabled) return;
        if (!supportsHover || pressed) return;
        this.background.setFillStyle(hoverFill, 1);
        this.highlight.setAlpha(1);
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setScale(1);
      })
      .on("pointerout", (...args: unknown[]) => {
        stopInputPropagation(args);
        if (!this.enabled) return;
        if (pressed) return;
        this.background.setFillStyle(fill, 0.96);
        this.highlight.setAlpha(0.72);
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setScale(1);
      })
      .on("pointerdown", (...args: unknown[]) => {
        stopInputPropagation(args);
        if (!this.enabled || this.busy) return;
        const pointer = args[0] as Phaser.Input.Pointer | undefined;
        if (!pointer) return;
        const now = performance.now();
        if (now - lastClickAt < cooldownMs) return;
        pressed = true;
        pointerStartedInside = true;
        activePointerId = pointer?.id;
        scene.tweens.killTweensOf([this.background, this.highlight]);
        this.background.setFillStyle(hoverFill, 1);
        this.highlight.setAlpha(1);
        this.background.setScale(1);
        audioManager.play(soundKey);
      })
      .on("pointerup", (...args: unknown[]) => {
        stopInputPropagation(args);
        if (!this.enabled || this.busy) return;
        const pointer = args[0] as Phaser.Input.Pointer | undefined;
        if (!pointerStartedInside || activePointerId !== pointer?.id) {
          resetVisual();
          return;
        }
        this.busy = true;
        const runAction = () => {
          if (!this.scene || !this.active) {
            this.busy = false;
            return;
          }
          lastClickAt = performance.now();
          try {
            onClick();
          } finally {
            this.busy = false;
          }
          if (!this.scene || !this.active) return;
          resetVisual();
        };
        if (actionDelayMs <= 0) {
          runAction();
        } else {
          scene.time.delayedCall(actionDelayMs, runAction);
        }
      })
      .on("pointerupoutside", (...args: unknown[]) => {
        stopInputPropagation(args);
        if (!this.enabled) return;
        resetVisual();
      });

    scene.add.existing(this);
  }

  setEnabled(enabled: boolean): this {
    this.enabled = enabled;
    this.busy = false;
    if (enabled) {
      this.hitTarget.setInteractive();
      if (this.hitTarget.input) {
        this.hitTarget.input.cursor = "pointer";
      }
      this.setAlpha(1);
      this.background.setFillStyle(this.fill, 0.96);
      this.highlight.setAlpha(0.72);
    } else {
      this.hitTarget.disableInteractive();
      this.setAlpha(0.5);
      this.background.setFillStyle(this.fill, 0.78);
      this.highlight.setAlpha(0.26);
    }
    return this;
  }
}
