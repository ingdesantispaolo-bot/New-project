import Phaser from "phaser";

export type DeviceKind =
  | "circuit"
  | "terminal"
  | "language"
  | "english"
  | "robot"
  | "door"
  | "journal"
  | "tools"
  | "window"
  | "core"
  | "trace";

export type DeviceState = "locked" | "ready" | "active" | "complete";

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
};

export class DeviceHotspot extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, x: number, y: number, options: DeviceHotspotOptions) {
    super(scene, x, y);
    const size = options.size ?? 88;
    const tint = stateColor(options.state);
    const supportsHover = typeof window === "undefined" || window.matchMedia?.("(hover: hover)").matches !== false;
    let lastTapAt = 0;
    let pressed = false;
    const glow = scene.add.image(0, 0, "soft-glow").setTint(tint).setAlpha(options.state === "active" ? 0.18 : options.state === "complete" ? 0.16 : 0.04).setScale(size / 58);
    const ring = scene.add.image(0, 0, "holo-ring").setTint(tint).setAlpha(options.state === "locked" ? 0.08 : options.state === "active" ? 0.4 : 0.18).setScale(size / 78);
    const glyph = drawDeviceGlyph(scene, options.kind, tint, options.state, size * 0.72);
    const marker = scene.add.circle(size * 0.28, -size * 0.24, Math.max(5, size * 0.07), tint, options.state === "locked" ? 0.4 : 0.92)
      .setStrokeStyle(1, 0xffffff, options.state === "locked" ? 0.12 : 0.34);
    const status = scene.add.container(0, -size * 0.56);
    const statusLabel = stateLabel(options.state);
    status.add(scene.add.rectangle(0, 0, Math.max(54, statusLabel.length * 6 + 14), 18, 0x02070b, 0.7)
      .setStrokeStyle(1, tint, options.state === "locked" ? 0.18 : 0.42));
    status.add(scene.add.text(0, -6, statusLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "9px",
      color: options.state === "locked" ? "#9aaab0" : options.state === "complete" ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5, 0));
    const tag = scene.add.container(0, size * 0.58);
    tag.add(scene.add.rectangle(0, 0, Math.max(116, options.label.length * 7), 22, 0x02070b, options.state === "active" ? 0.78 : 0.52));
    tag.add(scene.add.text(0, -8, options.label, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: options.state === "locked" ? "#9aaab0" : options.state === "complete" ? "#f7d37a" : "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5, 0));

    tag.setAlpha(options.state === "active" ? 1 : 0.76);
    const hitZone = scene.add.zone(0, 0, Math.max(size, 76), Math.max(size, 76) * 1.18).setOrigin(0.5);
    this.add([glow, ring, glyph, marker, status, tag, hitZone]);
    const hitSize = Math.max(size, 76);
    this.setSize(hitSize, hitSize);
    hitZone.setInteractive({ useHandCursor: options.state !== "locked" });
    hitZone.on("pointerover", () => {
      if (!supportsHover || pressed) return;
      if (options.state !== "locked") {
        ring.setAlpha(0.66);
        glow.setAlpha(0.26);
        tag.setAlpha(1);
        scene.tweens.killTweensOf(this);
        this.setScale(1.035);
      }
    });
    hitZone.on("pointerout", () => {
      if (pressed) return;
      ring.setAlpha(options.state === "locked" ? 0.08 : options.state === "active" ? 0.4 : 0.18);
      glow.setAlpha(options.state === "active" ? 0.18 : options.state === "complete" ? 0.16 : 0.04);
      tag.setAlpha(options.state === "active" ? 1 : 0.76);
      scene.tweens.killTweensOf(this);
      this.setScale(1);
    });
    hitZone.on("pointerdown", () => {
      const now = performance.now();
      if (now - lastTapAt < 180) return;
      lastTapAt = now;
      pressed = true;
      scene.tweens.killTweensOf(this);
      ring.setAlpha(options.state === "locked" ? 0.12 : 0.74);
      glow.setAlpha(options.state === "locked" ? 0.08 : 0.3);
      tag.setAlpha(1);
      this.setScale(0.985);
      const runAction = () => {
        if (!this.scene || !this.active) return;
        options.onClick();
        pressed = false;
        if (!this.scene || !this.active) return;
        scene.tweens.killTweensOf(this);
        scene.tweens.add({ targets: this, scale: 1, duration: 70 });
      };
      runAction();
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
  if (state === "complete") return colors.warm;
  if (state === "active") return colors.green;
  return colors.cyan;
}

function stateLabel(state: DeviceState): string {
  if (state === "locked") return "BLOCCATA";
  if (state === "complete") return "OK";
  if (state === "active") return "DA FARE";
  return "APRI";
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
  if (state === "complete") c.add(scene.add.circle(28 * s, -24 * s, 6 * s, colors.warm, 0.95));
  if (state === "locked") c.add(scene.add.rectangle(0, 0, 58 * s, 4 * s, colors.muted, 0.48).setRotation(-0.7));
  return c;
}
