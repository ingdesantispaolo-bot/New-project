import Phaser from "phaser";
import { audioManager, type SoundKey } from "../core/AudioManager";
import { settingsSystem } from "../core/SettingsSystem";

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

function normalizeButtonLabel(label: string): string {
  return label
    .replace(/[✓[\]·×]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}

function matchesAny(text: string, patterns: RegExp[]): boolean {
  return patterns.some((pattern) => pattern.test(text));
}

function inferButtonSoundKey(label: string): SoundKey {
  const normalized = normalizeButtonLabel(label);

  if (/^[1-8]$/.test(normalized)) return "levelSelect";

  // Uscita / chiusura: feedback breve e discendente, distinto dal reset.
  if (matchesAny(normalized, [
    /^(x|annulla|indietro|torna|menu|hub|chiudi|ho capito)$/,
    /^(torna a|pagina precedente|rivedi )/,
  ])) {
    return "cancel";
  }

  // Azioni distruttive / pulizia stato: devono sentirsi diverse da "annulla".
  if (/(reset|azzera|pulisci|svuota|clear|ripristina|ricomincia|riparti|riprova)/.test(normalized)) return "reset";

  // Aiuto e metacognizione: indizio, spiegazione e guida usano lo stesso richiamo morbido.
  if (/(indizio|aiuto|spiega|spiegazione|lente causale)/.test(normalized)) return "hint";

  // Audio/musica: pulsanti di ascolto e note devono anticipare l'evento sonoro.
  if (/(ascolta|suona|nota\s*[12]?|musica|pentagramma|ritmo|melodia|audio)/.test(normalized)) return "contextMusic";

  // Conferma/verifica: suono assertivo, utile prima del feedback corretto/errore.
  if (matchesAny(normalized, [
    /^(ok|conferma|verifica|certifica|consegna|controlla|test|testa|esegui|prova|registra)/,
    /(risposta|sequenza|ordine|rapporto|passaggio|componente)$/,
  ])) {
    return "confirm";
  }

  if (/(focus|calibra|calibrazione|allenati|allenamento)/.test(normalized)) return "focusSelect";
  if (/(missione|storia|capitolo|run procedurale|nuova stanza|sfida dell eco|affronta l eco)/.test(normalized)) return "missionStart";
  if (/^(avanti|sinistra|destra|gira|prendi|esci|forward|left|right|exit)$/.test(normalized)) return "contextCoding";

  // Navigazione narrativa o avanzamento run: passo energetico ma non trionfale.
  if (matchesAny(normalized, [
    /(livello successivo|profondità successiva|pagina successiva|continua|scalata|progressiva|impulso nora|protezione|\+30|carica)/,
    /^(inizia|riprendi|entra|conserva la carica)/,
  ])) {
    return "progressiveStep";
  }

  // Scansione/analisi: feedback tecnico per leggere dati o decodificare.
  if (/(leggi|scansiona|analizza|decodifica|sensori|tester|atlante)/.test(normalized)) return "scan";

  // Apertura pannelli informativi / collezioni.
  if (/(registro|diario|classifiche|report giocatore|galleria|albero|nora)/.test(normalized)) return "panelOpen";

  if (/(frase|parola|lessico|grammatica|sintesi|componi)/.test(normalized)) return "contextLanguage";
  if (/(inglese|english|bilingue)/.test(normalized)) return "contextEnglish";
  if (/(circuito|interruttore|switch|ramo|corrente|led|componente)/.test(normalized)) return "contextElectronics";
  if (/(robot|comando|algoritmo|coding|terminale)/.test(normalized)) return "contextCoding";
  if (/(grafico|calcolo|matematica|numero|nucleo|funzione)/.test(normalized)) return "contextMath";

  return "uiSelect";
}

export class Button extends Phaser.GameObjects.Container {
  private background: Phaser.GameObjects.Rectangle;
  private highlight: Phaser.GameObjects.Rectangle;
  private hitTarget: Phaser.GameObjects.Rectangle;
  private label: Phaser.GameObjects.Text;
  private readonly btnWidth: number;
  private readonly btnHeight: number;
  private readonly baseFontSize: number;
  private readonly wordWrapWidth: number;
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
    const coarsePointer = typeof window !== "undefined" && (window.matchMedia?.("(pointer: coarse)").matches ?? false);
    const hitWidth = coarsePointer ? Math.max(48, width) : width;
    const hitHeight = coarsePointer ? Math.max(48, height) : height;
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
    // Beveled depth: a soft top sheen (light) and a grounded base edge (dark).
    const sheen = scene.add.rectangle(0, -height / 4, width - 8, height / 2 - 4, 0xffffff, 0.05);
    const baseEdge = scene.add.rectangle(0, height / 2 - 2, width - 10, 2, 0x000000, 0.32);
    this.highlight = scene.add.rectangle(0, -height / 2 + 2, width - 10, 2, options.stroke ?? 0x6be7d6, 0.68);
    const requestedFontSize = options.fontSize ?? 20;
    const baseFontSize = settingsSystem.scaledFontSize(requestedFontSize);
    const text = scene.add
      .text(0, 0, label, {
        fontFamily: "Inter, Arial",
        fontSize: `${requestedFontSize}px`,
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
    this.label = text;
    this.btnWidth = width;
    this.btnHeight = height;
    this.baseFontSize = baseFontSize;
    this.wordWrapWidth = options.wordWrapWidth ?? width - 22;

    this.hitTarget = scene.add.rectangle(0, 0, hitWidth, hitHeight, 0x000000, 0.001).setOrigin(0.5);
    this.hitTarget.setInteractive();
    if (this.hitTarget.input) {
      this.hitTarget.input.cursor = "pointer";
    }

    this.add([shadow, this.background, sheen, this.highlight, baseEdge, text, this.hitTarget]);
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

  setLabel(label: string): this {
    this.label.setText(label);
    let fittedFontSize = this.baseFontSize;
    this.label.setFontSize(fittedFontSize);
    this.label.setWordWrapWidth(this.wordWrapWidth, true);
    while ((this.label.width > this.btnWidth - 16 || this.label.height > this.btnHeight - 10) && fittedFontSize > 10) {
      fittedFontSize -= 1;
      this.label.setFontSize(fittedFontSize);
      this.label.setWordWrapWidth(this.wordWrapWidth, true);
    }
    return this;
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
