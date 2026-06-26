import Phaser from "phaser";

export type DeviceKind =
  | "circuit"
  | "terminal"
  | "language"
  | "english"
  | "music"
  | "robot"
  | "door"
  | "journal"
  | "tools"
  | "window"
  | "core"
  | "trace";

export type DeviceState = "locked" | "ready" | "active" | "complete" | "failed";

export type DeviceHotspotOptions = {
  kind: DeviceKind;
  label: string;
  state: DeviceState;
  size?: number;
  onClick: () => void;
};

const colors = {
  panel2: 0x102533,
  cyan: 0x6be7d6,
  warm: 0xf6c85f,
  muted: 0x6b7d84,
  green: 0x2ed889,
  red: 0xe85b63,
};

function stopInputPropagation(args: unknown[]): void {
  const event = args[args.length - 1] as { stopPropagation?: () => void } | undefined;
  event?.stopPropagation?.();
}

export class DeviceHotspot extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, x: number, y: number, options: DeviceHotspotOptions) {
    super(scene, x, y);
    const size = options.size ?? 88;
    const tint = stateColor(options.state);
    const supportsHover = typeof window === "undefined" || window.matchMedia?.("(hover: hover)").matches !== false;
    let lastTapAt = 0;
    let pressed = false;
    let pointerStartedInside = false;
    let busy = false;
    let activePointerId: number | undefined;
    const glow = scene.add.image(0, 0, "soft-glow").setTint(tint).setAlpha(options.state === "active" ? 0.22 : options.state === "complete" ? 0.18 : options.state === "failed" ? 0.12 : 0.035).setScale(size / 64);
    const ring = scene.add.image(0, 0, "holo-ring").setTint(tint).setAlpha(options.state === "locked" ? 0.055 : options.state === "active" ? 0.46 : options.state === "failed" ? 0.24 : 0.13).setScale(size / 84);
    const glyph = drawDeviceGlyph(scene, options.kind, tint, options.state, size * 0.72);
    const marker = scene.add.circle(size * 0.28, -size * 0.24, Math.max(5, size * 0.07), tint, options.state === "locked" ? 0.4 : 0.92)
      .setStrokeStyle(1, 0xffffff, options.state === "locked" ? 0.12 : 0.34);
    const status = scene.add.container(0, -size * 0.56);
    const statusLabel = stateLabel(options.state);
    const statusWidth = statusLabel ? Math.max(50, statusLabel.length * 6 + 14) : 0;
    if (statusLabel) {
      status.add(scene.add.rectangle(0, 0, statusWidth, 18, 0x02070b, 0.78)
        .setStrokeStyle(1, tint, options.state === "locked" ? 0.18 : 0.42));
      status.add(scene.add.text(0, -6, statusLabel, {
        fontFamily: "Inter, Arial",
        fontSize: "9px",
        color: stateTextColor(options.state),
        fontStyle: "bold",
      }).setOrigin(0.5, 0));
    }
    status.setAlpha(statusLabel ? 1 : 0);
    const tag = scene.add.container(0, size * 0.58);
    const tagWidth = Math.max(116, options.label.length * 7);
    tag.add(scene.add.rectangle(0, 0, tagWidth, 22, 0x02070b, options.state === "active" ? 0.84 : 0.44)
      .setStrokeStyle(1, tint, options.state === "active" ? 0.28 : 0.08));
    tag.add(scene.add.text(0, -8, options.label, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: options.state === "locked" ? "#9aaab0" : options.state === "complete" ? "#d7ffdf" : "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5, 0));

    tag.setAlpha(options.state === "active" ? 1 : options.state === "locked" ? 0.52 : 0.66);
    const hitWidth = Math.max(size, tagWidth, statusWidth);
    const visualTop = Math.min(-size / 2, -size * 0.56 - 9);
    const visualBottom = Math.max(size / 2, size * 0.58 + 11);
    const hitHeight = visualBottom - visualTop;
    const hitPadding = 10;
    const hitArea = new Phaser.Geom.Rectangle(
      -hitWidth / 2 - hitPadding,
      visualTop - hitPadding,
      hitWidth + hitPadding * 2,
      hitHeight + hitPadding * 2,
    );
    const touchPlate = scene.add.rectangle(
      0,
      visualTop + hitHeight / 2,
      hitArea.width,
      hitArea.height,
      0x061019,
      0.01,
    ).setStrokeStyle(1, tint, options.state === "active" ? 0.18 : 0.06);
    touchPlate.setInteractive();
    if (touchPlate.input && options.state !== "locked") {
      touchPlate.input.cursor = "pointer";
    }

    const resetVisual = () => {
      pressed = false;
      pointerStartedInside = false;
      activePointerId = undefined;
      ring.setAlpha(options.state === "locked" ? 0.055 : options.state === "active" ? 0.46 : options.state === "failed" ? 0.24 : 0.13);
      glow.setAlpha(options.state === "active" ? 0.22 : options.state === "complete" ? 0.18 : options.state === "failed" ? 0.12 : 0.035);
      tag.setAlpha(options.state === "active" ? 1 : options.state === "locked" ? 0.52 : 0.66);
      scene.tweens.killTweensOf([glow, tag]);
      ring.setScale(size / 84);
    };

    this.add([touchPlate, glow, ring, glyph, marker, status, tag]);
    this.setSize(hitArea.width, hitArea.height);
    touchPlate.on("pointerover", (...args: unknown[]) => {
      stopInputPropagation(args);
      if (!supportsHover || pressed) return;
      if (options.state !== "locked") {
        ring.setAlpha(0.66);
        glow.setAlpha(0.26);
        tag.setAlpha(1);
        scene.tweens.killTweensOf([glow, tag]);
        ring.setScale((size / 84) * 1.05);
      }
    });
    touchPlate.on("pointerout", (...args: unknown[]) => {
      stopInputPropagation(args);
      if (pressed) return;
      ring.setAlpha(options.state === "locked" ? 0.055 : options.state === "active" ? 0.46 : options.state === "failed" ? 0.24 : 0.13);
      glow.setAlpha(options.state === "active" ? 0.22 : options.state === "complete" ? 0.18 : options.state === "failed" ? 0.12 : 0.035);
      tag.setAlpha(options.state === "active" ? 1 : options.state === "locked" ? 0.52 : 0.66);
      scene.tweens.killTweensOf([glow, tag]);
      ring.setScale(size / 84);
    });
    touchPlate.on("pointerdown", (...args: unknown[]) => {
      stopInputPropagation(args);
      if (busy) return;
      const pointer = args[0] as Phaser.Input.Pointer | undefined;
      if (!pointer) return;
      const now = performance.now();
      if (now - lastTapAt < 65) return;
      pressed = true;
      pointerStartedInside = true;
      activePointerId = pointer?.id;
      scene.tweens.killTweensOf([glow, tag]);
      ring.setAlpha(options.state === "locked" ? 0.12 : 0.74);
      glow.setAlpha(options.state === "locked" ? 0.08 : 0.3);
      tag.setAlpha(1);
      ring.setScale((size / 84) * 0.98);
    });
    touchPlate.on("pointerup", (...args: unknown[]) => {
      stopInputPropagation(args);
      if (busy) return;
      const pointer = args[0] as Phaser.Input.Pointer | undefined;
      if (!pointerStartedInside || activePointerId !== pointer?.id) {
        resetVisual();
        return;
      }
      busy = true;
      lastTapAt = performance.now();
      const runAction = () => {
        if (!this.scene || !this.active) {
          busy = false;
          return;
        }
        try {
          options.onClick();
        } finally {
          busy = false;
        }
        if (!this.scene || !this.active) return;
        scene.tweens.killTweensOf([glow, tag]);
        scene.tweens.add({ targets: ring, scale: size / 84, duration: 70 });
        resetVisual();
      };
      runAction();
    });
    touchPlate.on("pointerupoutside", (...args: unknown[]) => {
      stopInputPropagation(args);
      resetVisual();
    });

    if (options.state === "ready" || options.state === "active") {
      scene.tweens.add({
        targets: ring,
        rotation: Math.PI * 2,
        duration: options.state === "active" ? 2200 : 3600,
        repeat: -1,
      });
    }
    if (options.state === "complete") {
      scene.tweens.add({ targets: glow, alpha: 0.34, scale: size / 62, duration: 1200, yoyo: true, repeat: -1 });
    }
    scene.add.existing(this);
  }
}

function stateColor(state: DeviceState): number {
  if (state === "locked") return colors.muted;
  if (state === "complete") return colors.green;
  if (state === "failed") return colors.warm;
  if (state === "active") return colors.warm;
  return colors.cyan;
}

function stateTextColor(state: DeviceState): string {
  if (state === "locked") return "#9aaab0";
  if (state === "complete") return "#d7ffdf";
  if (state === "failed") return "#ffe4a6";
  if (state === "active") return "#ffd5d8";
  return "#9ff5e9";
}

function stateLabel(state: DeviceState): string {
  if (state === "locked") return "LOCK";
  if (state === "complete") return "COMPLETATA";
  if (state === "failed") return "FALLITA";
  if (state === "active") return "ATTIVA";
  return "";
}

function drawDeviceGlyph(
  scene: Phaser.Scene,
  kind: DeviceKind,
  color: number,
  state: DeviceState,
  size: number,
): Phaser.GameObjects.Container {
  const c = scene.add.container(0, 0);
  const g = scene.add.graphics();
  g.lineStyle(3, color, state === "locked" ? 0.42 : 0.88);
  const s = size / 88;
  if (kind === "circuit") {
    g.strokeRect(-24 * s, -14 * s, 48 * s, 28 * s);
    g.lineBetween(-36 * s, 0, -24 * s, 0);
    g.lineBetween(24 * s, 0, 36 * s, 0);
    g.strokeCircle(0, 0, 9 * s);
  } else if (kind === "terminal") {
    g.strokeRect(-28 * s, -20 * s, 56 * s, 36 * s);
    g.lineBetween(-18 * s, 24 * s, 18 * s, 24 * s);
    g.lineBetween(0, 16 * s, 0, 24 * s);
  } else if (kind === "language" || kind === "english") {
    g.strokeRect(-28 * s, -22 * s, 56 * s, 44 * s);
    g.lineBetween(-18 * s, -8 * s, 18 * s, -8 * s);
    g.lineBetween(-18 * s, 4 * s, 10 * s, 4 * s);
    g.lineBetween(-18 * s, 16 * s, 22 * s, 16 * s);
    if (kind === "english") g.strokeCircle(24 * s, -18 * s, 9 * s);
  } else if (kind === "music") {
    for (let index = 0; index < 5; index += 1) {
      const y = (-20 + index * 10) * s;
      g.lineBetween(-34 * s, y, 34 * s, y);
    }
    g.fillStyle(color, state === "locked" ? 0.34 : 0.84);
    g.fillEllipse(4 * s, 0, 16 * s, 11 * s);
    g.lineStyle(3, color, state === "locked" ? 0.42 : 0.88);
    g.lineBetween(12 * s, -2 * s, 12 * s, -32 * s);
    g.lineBetween(12 * s, -32 * s, 28 * s, -24 * s);
  } else if (kind === "robot") {
    g.strokeRoundedRect(-24 * s, -18 * s, 48 * s, 36 * s, 6 * s);
    g.strokeCircle(-10 * s, -2 * s, 4 * s);
    g.strokeCircle(10 * s, -2 * s, 4 * s);
    g.lineBetween(-18 * s, 22 * s, -30 * s, 30 * s);
    g.lineBetween(18 * s, 22 * s, 30 * s, 30 * s);
  } else if (kind === "door") {
    g.strokeRect(-20 * s, -28 * s, 40 * s, 56 * s);
    g.strokeCircle(8 * s, 0, 3 * s);
    g.strokeCircle(0, 0, 22 * s);
  } else if (kind === "tools") {
    g.lineBetween(-22 * s, 22 * s, 22 * s, -22 * s);
    g.strokeCircle(25 * s, -25 * s, 8 * s);
    g.lineBetween(-28 * s, -18 * s, 20 * s, 30 * s);
  } else if (kind === "journal") {
    g.strokeRect(-22 * s, -28 * s, 44 * s, 56 * s);
    g.lineBetween(-12 * s, -12 * s, 12 * s, -12 * s);
    g.lineBetween(-12 * s, 4 * s, 12 * s, 4 * s);
  } else if (kind === "window") {
    g.strokeRect(-28 * s, -20 * s, 56 * s, 40 * s);
    g.lineBetween(0, -20 * s, 0, 20 * s);
    g.lineBetween(-28 * s, 0, 28 * s, 0);
  } else if (kind === "trace") {
    g.beginPath();
    g.moveTo(-30 * s, 18 * s);
    g.lineTo(-8 * s, -8 * s);
    g.lineTo(12 * s, 10 * s);
    g.lineTo(30 * s, -18 * s);
    g.strokePath();
    g.strokeCircle(-30 * s, 18 * s, 4 * s);
    g.strokeCircle(30 * s, -18 * s, 4 * s);
  } else {
    g.strokeCircle(0, 0, 26 * s);
    g.strokeCircle(0, 0, 12 * s);
  }
  c.add(g);
  if (state === "complete") c.add(scene.add.circle(28 * s, -24 * s, 6 * s, colors.green, 0.95));
  if (state === "locked") c.add(scene.add.rectangle(0, 0, 58 * s, 4 * s, colors.muted, 0.48).setRotation(-0.7));
  return c;
}
