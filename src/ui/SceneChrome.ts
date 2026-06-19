import Phaser from "phaser";
import { DeviceHotspot } from "./DeviceHotspot";
import { VisualKit } from "./VisualKit";

export type ChromePalette = "academy" | "lab" | "greenhouse" | "factory" | "archive" | "circuit";

export type ChromeRect = {
  x: number;
  y: number;
  width: number;
  height: number;
};

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

export type SceneChromeLayout = {
  top: ChromeRect;
  left: ChromeRect;
  stage: ChromeRect;
  right: ChromeRect;
  bottom: ChromeRect;
};

const colors = {
  bg: 0x061019,
  panel: 0x08131c,
  panel2: 0x102533,
  cyan: 0x6be7d6,
  cyanSoft: 0x9ff5e9,
  warm: 0xf6c85f,
  muted: 0x6b7d84,
  red: 0xc94b55,
  green: 0x2ed889,
};

function stopInputPropagation(args: unknown[]): void {
  const event = args[args.length - 1] as { stopPropagation?: () => void } | undefined;
  event?.stopPropagation?.();
}

export class SceneChrome {
  static readonly layout: SceneChromeLayout = {
    top: { x: 24, y: 18, width: 1232, height: 82 },
    left: { x: 24, y: 118, width: 300, height: 504 },
    stage: { x: 348, y: 118, width: 636, height: 504 },
    right: { x: 1008, y: 118, width: 248, height: 504 },
    bottom: { x: 348, y: 640, width: 908, height: 56 },
  };

  static readonly twoColumnLayout: SceneChromeLayout = {
    top: { x: 52, y: 24, width: 1176, height: 82 },
    left: { x: 44, y: 128, width: 756, height: 496 },
    stage: { x: 44, y: 128, width: 756, height: 496 },
    right: { x: 820, y: 128, width: 420, height: 496 },
    bottom: { x: 56, y: 642, width: 760, height: 54 },
  };

  static drawMissionChrome(
    scene: Phaser.Scene,
    palette: ChromePalette,
    title: string,
    subtitle: string,
    stageTitle: string,
  ): SceneChromeLayout {
    const layout = this.layout;
    scene.cameras.main.setBackgroundColor("#061019");
    VisualKit.background(scene, palette);
    scene.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.18);

    VisualKit.glassPanel(scene, layout.top.x, layout.top.y, layout.top.width, layout.top.height, palette, 0.72);
    scene.add.text(layout.top.x + 22, layout.top.y + 14, title, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    scene.add.text(layout.top.x + 24, layout.top.y + 52, subtitle, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      wordWrap: { width: 1120 },
    });

    VisualKit.glassPanel(scene, layout.left.x, layout.left.y, layout.left.width, layout.left.height, palette, 0.9);
    VisualKit.glassPanel(scene, layout.stage.x, layout.stage.y, layout.stage.width, layout.stage.height, palette, 0.48);
    VisualKit.glowFrame(scene, layout.stage.x + 8, layout.stage.y + 8, layout.stage.width - 16, layout.stage.height - 16, palette);
    VisualKit.glassPanel(scene, layout.right.x, layout.right.y, layout.right.width, layout.right.height, palette, 0.86);
    VisualKit.glassPanel(scene, layout.bottom.x, layout.bottom.y, layout.bottom.width, layout.bottom.height, palette, 0.84);

    scene.add.text(layout.stage.x + 24, layout.stage.y + 18, stageTitle.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
      letterSpacing: 0,
    });
    this.drawStageGrid(scene, layout.stage);
    VisualKit.vignette(scene);
    return layout;
  }

  static drawTwoColumnMissionChrome(
    scene: Phaser.Scene,
    palette: ChromePalette,
    title: string,
    subtitle: string,
    stageTitle: string,
  ): SceneChromeLayout {
    const layout = this.twoColumnLayout;
    scene.cameras.main.setBackgroundColor("#061019");
    VisualKit.background(scene, palette);
    scene.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.2);

    VisualKit.glassPanel(scene, layout.top.x, layout.top.y, layout.top.width, layout.top.height, palette, 0.7);
    scene.add.text(layout.top.x + 22, layout.top.y + 12, title, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    scene.add.text(layout.top.x + 24, layout.top.y + 52, subtitle, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#c9dce6",
      wordWrap: { width: layout.top.width - 48 },
    });

    VisualKit.glassPanel(scene, layout.stage.x, layout.stage.y, layout.stage.width, layout.stage.height, palette, 0.34);
    VisualKit.glowFrame(scene, layout.stage.x - 8, layout.stage.y - 8, layout.stage.width + 16, layout.stage.height + 16, palette);
    VisualKit.glassPanel(scene, layout.right.x, layout.right.y, layout.right.width, layout.right.height, palette, 0.84);
    VisualKit.glassPanel(scene, layout.bottom.x, layout.bottom.y, layout.bottom.width, layout.bottom.height, palette, 0.86);
    scene.add.text(layout.stage.x + 22, layout.stage.y + 16, stageTitle.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.drawStageGrid(scene, layout.stage);
    VisualKit.vignette(scene);
    return layout;
  }

  static consolePanel(
    scene: Phaser.Scene,
    x: number,
    y: number,
    width: number,
    height: number,
    title: string,
    paletteName: ChromePalette = "academy",
  ): Phaser.GameObjects.Container {
    const panel = scene.add.container(x, y);
    const paletteAccent = paletteName === "factory"
      ? colors.warm
      : paletteName === "archive"
        ? 0x9f8cff
        : paletteName === "greenhouse"
          ? 0x70d68a
          : colors.cyan;
    const assetKey = `console-${paletteName === "circuit" ? "lab" : paletteName}`;
    if (scene.textures.exists(assetKey)) {
      panel.add(scene.add.image(width / 2 + 8, height / 2 + 10, assetKey).setDisplaySize(width, height).setTint(0x000000).setAlpha(0.24));
      panel.add(scene.add.image(width / 2, height / 2, assetKey).setDisplaySize(width, height));
    } else {
      panel.add(scene.add.rectangle(8, 10, width, height, 0x000000, 0.26).setOrigin(0));
      panel.add(scene.add.rectangle(0, 0, width, height, colors.panel, 0.94).setOrigin(0).setStrokeStyle(2, paletteAccent, 0.38));
      panel.add(scene.add.rectangle(0, 0, width, 4, paletteAccent, 0.54).setOrigin(0));
      panel.add(scene.add.rectangle(18, 42, width - 36, 1, 0xffffff, 0.08).setOrigin(0));
    }
    panel.add(scene.add.text(20, 16, title, {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: paletteName === "archive" ? "#cdbfff" : "#9ff5e9",
      fontStyle: "bold",
    }));
    const flare = scene.add.image(width - 28, 24, "soft-glow").setTint(paletteAccent).setAlpha(0.16).setScale(0.7);
    panel.add(flare);
    return panel;
  }

  static modalInputBlocker(
    scene: Phaser.Scene,
    container: Phaser.GameObjects.Container,
    originX = container.x,
    originY = container.y,
    fill = colors.bg,
    alpha = 0.001,
  ): Phaser.GameObjects.Rectangle {
    const blocker = scene.add.rectangle(640 - originX, 360 - originY, 1280, 720, fill, alpha)
      .setInteractive()
      .setDepth(-10000);
    blocker
      .on("pointerdown", (...args: unknown[]) => stopInputPropagation(args))
      .on("pointerup", (...args: unknown[]) => stopInputPropagation(args))
      .on("pointermove", (...args: unknown[]) => stopInputPropagation(args))
      .on("pointerover", (...args: unknown[]) => stopInputPropagation(args))
      .on("pointerout", (...args: unknown[]) => stopInputPropagation(args))
      .on("pointerupoutside", (...args: unknown[]) => stopInputPropagation(args));
    container.add(blocker);
    return blocker;
  }

  static section(scene: Phaser.Scene, rect: ChromeRect, title: string, yOffset = 18): Phaser.GameObjects.Text {
    scene.add.rectangle(rect.x + 16, rect.y + yOffset + 23, rect.width - 32, 1, 0x9ff5e9, 0.12);
    return scene.add.text(rect.x + 18, rect.y + yOffset, title, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
  }

  static deviceHotspot(
    scene: Phaser.Scene,
    x: number,
    y: number,
    kind: DeviceKind,
    label: string,
    state: DeviceState,
    onClick: () => void,
    size = 88,
  ): Phaser.GameObjects.Container {
    return new DeviceHotspot(scene, x, y, { kind, label, state, size, onClick });
  }

  static connectDevices(
    scene: Phaser.Scene,
    points: Array<{ x: number; y: number }>,
    activeCount: number,
    activeColor = colors.cyan,
    inactiveColor = 0x315766,
  ): void {
    const g = scene.add.graphics();
    points.forEach((point, index) => {
      if (index === points.length - 1) {
        return;
      }
      const next = points[index + 1];
      const active = index < activeCount;
      g.lineStyle(active ? 2 : 1, active ? activeColor : inactiveColor, active ? 0.16 : 0.045);
      g.lineBetween(point.x, point.y, next.x, next.y);
    });
  }

  static bottomLog(scene: Phaser.Scene, rect: ChromeRect, text: string, reservedRight = 40): Phaser.GameObjects.Text {
    return scene.add.text(rect.x + 20, rect.y + 16, text, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      wordWrap: { width: rect.width - reservedRight },
      lineSpacing: 3,
    });
  }

  private static drawStageGrid(scene: Phaser.Scene, rect: ChromeRect): void {
    const grid = scene.add.graphics();
    grid.lineStyle(1, 0x6be7d6, 0.08);
    for (let x = rect.x + 34; x < rect.x + rect.width - 16; x += 72) {
      grid.lineBetween(x, rect.y + 38, x - 38, rect.y + rect.height - 28);
    }
    for (let y = rect.y + 72; y < rect.y + rect.height - 24; y += 66) {
      grid.lineBetween(rect.x + 18, y, rect.x + rect.width - 18, y + 4);
    }
    scene.add.rectangle(rect.x + rect.width / 2, rect.y + rect.height / 2, rect.width - 46, rect.height - 56, 0x000000, 0)
      .setStrokeStyle(1, 0x9ff5e9, 0.12);
  }

  private static stateColor(state: DeviceState): number {
    if (state === "locked") return colors.muted;
    if (state === "complete") return colors.green;
    if (state === "failed") return colors.warm;
    if (state === "active") return colors.red;
    return colors.cyan;
  }

  private static drawDeviceGlyph(
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
      if (kind === "english") {
        g.strokeCircle(24 * s, -18 * s, 9 * s);
      }
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
    if (state === "complete") {
      c.add(scene.add.circle(28 * s, -24 * s, 6 * s, colors.green, 0.95));
    }
    if (state === "locked") {
      c.add(scene.add.rectangle(0, 0, 58 * s, 4 * s, colors.muted, 0.48).setRotation(-0.7));
    }
    return c;
  }
}
