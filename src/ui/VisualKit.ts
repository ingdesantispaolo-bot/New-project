import Phaser from "phaser";
import { settingsSystem } from "../core/SettingsSystem";

type Palette = "academy" | "lab" | "greenhouse" | "factory" | "archive" | "circuit";

const palettes: Record<Palette, { bg: number; deep: number; accent: number; accent2: number; warm: number }> = {
  academy: { bg: 0x071018, deep: 0x0d1b26, accent: 0x6be7d6, accent2: 0x4c7dff, warm: 0xf6c85f },
  lab: { bg: 0x061019, deep: 0x0b1a24, accent: 0x6be7d6, accent2: 0x315766, warm: 0xf6c85f },
  greenhouse: { bg: 0x06130f, deep: 0x0b221f, accent: 0x70d68a, accent2: 0x4a8f68, warm: 0xf7d37a },
  factory: { bg: 0x0b0f14, deep: 0x211d17, accent: 0xf6c85f, accent2: 0x8aa6b0, warm: 0xffb36b },
  archive: { bg: 0x0a0d18, deep: 0x171925, accent: 0x9f8cff, accent2: 0x6be7d6, warm: 0xf7d37a },
  circuit: { bg: 0x071018, deep: 0x0d1b26, accent: 0x6be7d6, accent2: 0xf6c85f, warm: 0xffb36b },
};

const gradedCameras = new WeakSet<Phaser.Cameras.Scene2D.Camera>();

// Per-palette filmic grade tuning. Neutral = brightness 1, saturate 0, contrast 0.
const gradeProfiles: Record<Palette, { brightness: number; saturate: number; contrast: number; glow: number }> = {
  academy: { brightness: 1.03, saturate: 0.22, contrast: 0.16, glow: 0.9 },
  lab: { brightness: 1.02, saturate: 0.2, contrast: 0.18, glow: 1.0 },
  greenhouse: { brightness: 1.05, saturate: 0.26, contrast: 0.12, glow: 0.8 },
  factory: { brightness: 1.02, saturate: 0.18, contrast: 0.2, glow: 1.0 },
  archive: { brightness: 1.02, saturate: 0.22, contrast: 0.16, glow: 0.9 },
  circuit: { brightness: 1.03, saturate: 0.24, contrast: 0.18, glow: 1.1 },
};

export class VisualKit {
  /**
   * Phase 0 cinematic post-processing: a WebGL camera filter stack
   * (color grade + vignette + subtle bloom-like glow) that lifts perceived
   * quality across every scene without new art. Tiered by the graphics-quality
   * setting and a no-op on Canvas / "comfort".
   */
  static applyCinematicGrade(scene: Phaser.Scene, paletteName: Palette = "academy"): void {
    const quality = settingsSystem.getGraphicsQuality();
    if (quality === "comfort") {
      return;
    }
    if (scene.game.renderer.type !== Phaser.WEBGL) {
      return;
    }
    const camera = scene.cameras.main;
    const filters = (camera as { filters?: { internal?: Phaser.GameObjects.Components.FilterList } }).filters;
    if (!filters?.internal || gradedCameras.has(camera)) {
      return;
    }
    gradedCameras.add(camera);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => gradedCameras.delete(camera));

    const profile = gradeProfiles[paletteName];
    try {
      const cm = filters.internal.addColorMatrix().colorMatrix;
      cm.brightness(profile.brightness, true);
      cm.saturate(profile.saturate, true);
      cm.contrast(profile.contrast, true);
      if (quality === "high") {
        filters.internal.addGlow(0xffffff, profile.glow, 0, 1.1, false, 4, 8);
      }
    } catch {
      // Filters are a visual enhancement only; never break a scene over them.
      gradedCameras.delete(camera);
    }
  }

  static background(scene: Phaser.Scene, paletteName: Palette = "academy", backdropKey?: string): void {
    this.applyCinematicGrade(scene, paletteName);
    const palette = palettes[paletteName];
    const hazeAlpha: Record<Palette, number> = {
      academy: 0.3,
      archive: 0.3,
      circuit: 0.48,
      factory: 0.34,
      greenhouse: 0.24,
      lab: 0.34,
    };
    const gridAlpha: Record<Palette, number> = {
      academy: 0.06,
      archive: 0.08,
      circuit: 0.11,
      factory: 0.08,
      greenhouse: 0.07,
      lab: 0.07,
    };
    scene.add.rectangle(640, 360, 1280, 720, palette.bg, 1);
    this.paintedBackdrop(scene, paletteName, backdropKey);
    this.productionParallax(scene, paletteName);

    const haze = scene.add.graphics();
    haze.fillStyle(palette.deep, hazeAlpha[paletteName]);
    haze.fillRect(0, 0, 1280, 720);
    haze.fillStyle(palette.accent, 0.055);
    haze.fillCircle(250, 120, 320);
    haze.fillStyle(palette.warm, 0.04);
    haze.fillCircle(1010, 590, 390);
    haze.fillStyle(palette.accent2, 0.038);
    haze.fillCircle(960, 170, 270);
    haze.fillStyle(0xffffff, 0.035);
    haze.fillRect(0, 0, 1280, 82);

    const grid = scene.add.graphics();
    grid.lineStyle(1, palette.accent2, gridAlpha[paletteName]);
    for (let x = -120; x < 1400; x += 70) {
      grid.lineBetween(x, 0, x - 160, 720);
    }
    for (let y = 64; y < 720; y += 72) {
      grid.lineBetween(0, y, 1280, y + 16);
    }

    this.filmicGrade(scene, paletteName);
    if (settingsSystem.effectsReduced()) {
      // Calm, static backdrop: skip animated sweep and floating particles.
      this.cinematicReveal(scene, paletteName);
      return;
    }
    this.lightSweep(scene, paletteName);
    for (let index = 0; index < 42; index += 1) {
      const dot = this.atlasImage(
        scene,
        Phaser.Math.Between(36, 1244),
        Phaser.Math.Between(44, 676),
        index % 5 === 0 ? "particle-diamond" : "soft-flare",
        index % 5 === 0 ? "spark-core" : "soft-glow",
      );
      dot.setTint(index % 3 === 0 ? palette.warm : palette.accent);
      dot.setAlpha(Phaser.Math.FloatBetween(0.025, 0.12));
      dot.setScale(Phaser.Math.FloatBetween(0.08, 0.92));
      scene.tweens.add({
        targets: dot,
        y: dot.y + Phaser.Math.Between(-18, 18),
        alpha: { from: dot.alpha * 0.55, to: dot.alpha * 1.8 },
        duration: Phaser.Math.Between(2200, 5600),
        yoyo: true,
        repeat: -1,
      });
    }
    this.cinematicReveal(scene, paletteName);
  }

  private static atlasImage(
    scene: Phaser.Scene,
    x: number,
    y: number,
    frame: string,
    fallbackTexture: string,
  ): Phaser.GameObjects.Image {
    if (scene.textures.exists("eli-atlas")) {
      return scene.add.image(x, y, "eli-atlas", frame);
    }
    return scene.add.image(x, y, fallbackTexture);
  }

  private static paintedBackdrop(scene: Phaser.Scene, paletteName: Palette, preferredKey?: string): void {
    const backdropKeys: Partial<Record<Palette, string>> = {
      academy: "bg-academy-painted",
      archive: "bg-archive-painted",
      circuit: "bg-lab-painted",
      factory: "bg-factory-painted",
      greenhouse: "bg-greenhouse-painted",
      lab: "bg-lab-painted",
    };
    const key = preferredKey && scene.textures.exists(preferredKey) ? preferredKey : backdropKeys[paletteName];
    if (!key || !scene.textures.exists(key)) {
      return;
    }
    const image = scene.add.image(640, 360, key);
    image.setDisplaySize(1334, 750).setAlpha(paletteName === "circuit" ? 0.72 : 0.94);
    if (settingsSystem.effectsReduced()) {
      return;
    }
    scene.tweens.add({
      targets: image,
      scaleX: image.scaleX * 1.015,
      scaleY: image.scaleY * 1.015,
      duration: 16000,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
    this.pointerParallax(scene, image, paletteName === "greenhouse" ? 10 : 14);
  }

  private static pointerParallax(scene: Phaser.Scene, target: Phaser.GameObjects.Image, strength: number): void {
    if (!this.shouldUsePointerParallax()) {
      return;
    }
    let frame = 0;
    let nextX = target.x;
    let nextY = target.y;
    const onMove = (pointer: Phaser.Input.Pointer): void => {
      const dx = Phaser.Math.Clamp((pointer.x - 640) / 640, -1, 1);
      const dy = Phaser.Math.Clamp((pointer.y - 360) / 360, -1, 1);
      nextX = 640 - dx * strength;
      nextY = 360 - dy * strength * 0.72;
      if (frame !== 0) return;
      frame = window.requestAnimationFrame(() => {
        frame = 0;
        if (!target.scene || !target.active) return;
        target.x += (nextX - target.x) * 0.18;
        target.y += (nextY - target.y) * 0.18;
      });
    };
    scene.input.on("pointermove", onMove);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      scene.input.off("pointermove", onMove);
      if (frame !== 0) window.cancelAnimationFrame(frame);
    });
  }

  private static pointerParallaxTarget(scene: Phaser.Scene, target: Phaser.GameObjects.Components.Transform, strength: number): void {
    if (!this.shouldUsePointerParallax()) {
      return;
    }
    let frame = 0;
    const baseX = target.x;
    const baseY = target.y;
    let nextX = baseX;
    let nextY = baseY;
    const onMove = (pointer: Phaser.Input.Pointer): void => {
      const dx = Phaser.Math.Clamp((pointer.x - 640) / 640, -1, 1);
      const dy = Phaser.Math.Clamp((pointer.y - 360) / 360, -1, 1);
      nextX = baseX - dx * strength;
      nextY = baseY - dy * strength * 0.62;
      if (frame !== 0) return;
      frame = window.requestAnimationFrame(() => {
        frame = 0;
        target.x += (nextX - target.x) * 0.16;
        target.y += (nextY - target.y) * 0.16;
      });
    };
    scene.input.on("pointermove", onMove);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      scene.input.off("pointermove", onMove);
      if (frame !== 0) window.cancelAnimationFrame(frame);
    });
  }

  private static shouldUsePointerParallax(): boolean {
    if (typeof window === "undefined") {
      return false;
    }
    if (settingsSystem.effectsReduced()) {
      return false;
    }
    const coarsePointer = window.matchMedia?.("(pointer: coarse)").matches ?? false;
    const smallViewport = Math.min(window.innerWidth, window.innerHeight) < 760;
    return !coarsePointer && !smallViewport;
  }

  private static productionParallax(scene: Phaser.Scene, paletteName: Palette): void {
    const palette = palettes[paletteName];
    const far = scene.add.container(640, 360);
    const mid = scene.add.container(640, 360);
    const near = scene.add.container(640, 360);

    far.add(scene.add.rectangle(-420, -140, 360, 620, palette.accent2, 0.035).setRotation(-0.12));
    far.add(scene.add.rectangle(420, 80, 420, 560, palette.warm, 0.026).setRotation(0.18));
    for (let i = 0; i < 5; i += 1) {
      far.add(scene.add.circle(-520 + i * 260, -250 + (i % 2) * 96, 60 + i * 12, palette.accent, 0.025));
    }

    for (let index = 0; index < 4; index += 1) {
      const streak = this.atlasImage(scene, -450 + index * 300, -170 + index * 84, "lens-streak", "soft-glow");
      streak.setTint(index % 2 === 0 ? palette.accent : palette.warm).setAlpha(0.055).setScale(2.2, 1.1).setRotation(-0.18);
      mid.add(streak);
    }

    const foreground = scene.add.graphics();
    foreground.fillStyle(0x000000, 0.16);
    foreground.fillTriangle(-100, 370, 220, 370, 18, 250);
    foreground.fillTriangle(1060, 370, 1390, 370, 1210, 230);
    foreground.fillStyle(palette.deep, 0.18);
    foreground.fillRect(-640, 284, 1280, 92);
    near.add(foreground);

    this.pointerParallaxTarget(scene, far, 5);
    this.pointerParallaxTarget(scene, mid, 13);
    this.pointerParallaxTarget(scene, near, 22);
  }

  private static filmicGrade(scene: Phaser.Scene, paletteName: Palette): void {
    const palette = palettes[paletteName];
    scene.add.rectangle(640, 360, 1280, 720, palette.accent, 0.018).setBlendMode(Phaser.BlendModes.ADD);
    scene.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.18);
    const scan = scene.add.graphics();
    scan.lineStyle(1, 0xffffff, 0.018);
    for (let y = 0; y < 720; y += 6) {
      scan.lineBetween(0, y, 1280, y);
    }
  }

  static cinematicReveal(scene: Phaser.Scene, paletteName: Palette = "academy"): void {
    const palette = palettes[paletteName];
    const top = scene.add.rectangle(640, 0, 1280, 160, 0x000000, 0.72).setDepth(950);
    const bottom = scene.add.rectangle(640, 720, 1280, 160, 0x000000, 0.72).setDepth(950);
    const streak = this.atlasImage(scene, 120, 142, "lens-streak", "soft-glow")
      .setTint(palette.warm)
      .setAlpha(0.22)
      .setScale(2.4, 0.7)
      .setDepth(951);
    scene.tweens.add({ targets: top, y: -96, duration: 620, ease: "Sine.easeOut", onComplete: () => top.destroy() });
    scene.tweens.add({ targets: bottom, y: 816, duration: 620, ease: "Sine.easeOut", onComplete: () => bottom.destroy() });
    scene.tweens.add({
      targets: streak,
      x: 1180,
      alpha: 0,
      duration: 720,
      ease: "Sine.easeOut",
      onComplete: () => streak.destroy(),
    });
  }

  private static lightSweep(scene: Phaser.Scene, paletteName: Palette): void {
    const palette = palettes[paletteName];
    const sweep = scene.add.rectangle(-180, 360, 160, 820, palette.accent, 0.045);
    sweep.setRotation(-0.28);
    scene.tweens.add({
      targets: sweep,
      x: 1500,
      duration: 9000,
      repeat: -1,
      repeatDelay: 2600,
      ease: "Sine.easeInOut",
    });
  }

  static cinematicDepth(scene: Phaser.Scene, paletteName: Palette = "academy", intensity = 1): void {
    const palette = palettes[paletteName];
    const shadows = scene.add.graphics();
    shadows.fillStyle(0x000000, 0.18 * intensity);
    shadows.fillEllipse(-40, 710, 520, 150);
    shadows.fillEllipse(1320, 705, 620, 180);
    shadows.fillStyle(palette.deep, 0.18 * intensity);
    shadows.fillRect(0, 600, 1280, 120);

    const beamColor = paletteName === "factory" ? palette.warm : palette.accent;
    for (let index = 0; index < 3; index += 1) {
      const beam = scene.add.rectangle(220 + index * 360, 330, 70, 760, beamColor, 0.035 * intensity);
      beam.setRotation(-0.24 + index * 0.08);
      scene.tweens.add({
        targets: beam,
        alpha: { from: 0.018 * intensity, to: 0.07 * intensity },
        duration: 3400 + index * 700,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
      });
    }
  }

  static hologramShard(
    scene: Phaser.Scene,
    x: number,
    y: number,
    width: number,
    height: number,
    paletteName: Palette = "academy",
  ): Phaser.GameObjects.Container {
    const palette = palettes[paletteName];
    const shard = scene.add.container(x, y);
    shard.add(scene.add.rectangle(0, 0, width, height, palette.deep, 0.46).setStrokeStyle(1, palette.accent, 0.42));
    shard.add(scene.add.rectangle(0, -height * 0.26, width * 0.72, 2, palette.warm, 0.46));
    shard.add(scene.add.rectangle(0, height * 0.08, width * 0.64, 1, palette.accent, 0.32));
    shard.add(scene.add.rectangle(0, height * 0.24, width * 0.48, 1, palette.accent2, 0.28));
    scene.tweens.add({
      targets: shard,
      y: y - 8,
      alpha: { from: 0.58, to: 0.94 },
      duration: 2200 + Phaser.Math.Between(0, 1000),
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
    return shard;
  }

  static statusLight(scene: Phaser.Scene, x: number, y: number, color: number, active = true): Phaser.GameObjects.Container {
    const light = scene.add.container(x, y);
    light.add(scene.add.image(0, 0, "soft-glow").setTint(color).setAlpha(active ? 0.28 : 0.08).setScale(active ? 1.05 : 0.58));
    light.add(scene.add.circle(0, 0, 8, color, active ? 0.94 : 0.38).setStrokeStyle(1, 0xffffff, active ? 0.35 : 0.12));
    if (active) {
      scene.tweens.add({
        targets: light,
        scale: 1.18,
        alpha: 0.78,
        duration: 920,
        yoyo: true,
        repeat: -1,
      });
    }
    return light;
  }

  static scanLine(scene: Phaser.Scene, x: number, y: number, width: number, height: number, paletteName: Palette = "academy"): void {
    const palette = palettes[paletteName];
    const line = scene.add.rectangle(x, y - height / 2, width, 2, palette.accent, 0.42);
    scene.tweens.add({
      targets: line,
      y: y + height / 2,
      alpha: { from: 0.06, to: 0.46 },
      duration: 1800,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }

  static outcomeFlash(scene: Phaser.Scene, tone: "success" | "error" | "warning", x = 640, y = 360, width = 1280, height = 720): void {
    const color = tone === "success" ? 0x6be7d6 : tone === "warning" ? 0xf6c85f : 0xc94b55;
    const flash = scene.add.rectangle(x, y, width, height, color, tone === "success" ? 0.12 : 0.16);
    flash.setDepth(900);
    scene.tweens.add({
      targets: flash,
      alpha: 0,
      duration: tone === "success" ? 620 : 420,
      ease: "Sine.easeOut",
      onComplete: () => flash.destroy(),
    });
  }

  static shake(
    scene: Phaser.Scene,
    target: Phaser.GameObjects.Components.Transform | Phaser.GameObjects.Components.Transform[],
    strength = 8,
  ): void {
    const items = Array.isArray(target) ? target : [target];
    items.forEach((item) => {
      const startX = item.x;
      scene.tweens.add({
        targets: item,
        x: { from: startX - strength, to: startX + strength },
        duration: 42,
        yoyo: true,
        repeat: 4,
        onComplete: () => {
          item.x = startX;
        },
      });
    });
  }

  static particleBurst(scene: Phaser.Scene, x: number, y: number, paletteName: Palette = "academy", tone: "success" | "error" | "warning" = "success"): void {
    const palette = palettes[paletteName];
    const color = tone === "success" ? palette.accent : tone === "warning" ? palette.warm : 0xc94b55;
    for (let index = 0; index < 18; index += 1) {
      const particle = this.atlasImage(scene, x, y, index % 4 === 0 ? "particle-diamond" : "soft-flare", index % 4 === 0 ? "spark-core" : "soft-glow");
      particle.setTint(color).setAlpha(0.72).setScale(Phaser.Math.FloatBetween(0.08, 0.38)).setDepth(920);
      const angle = (Math.PI * 2 * index) / 18 + Phaser.Math.FloatBetween(-0.16, 0.16);
      const distance = Phaser.Math.Between(42, 116);
      scene.tweens.add({
        targets: particle,
        x: x + Math.cos(angle) * distance,
        y: y + Math.sin(angle) * distance,
        alpha: 0,
        scale: 0,
        duration: 560 + Phaser.Math.Between(0, 280),
        ease: "Sine.easeOut",
        onComplete: () => particle.destroy(),
      });
    }
  }

  /**
   * Shared "juice" reaction that makes an answer FELT, not just read.
   * - correct: a warm bloom + expanding ring + accent sparks at a focal point,
   *   as if the answer powered something on.
   * - wrong: a brief, gentle nudge (soft warm pulse + small shake), never harsh —
   *   "quasi, riprova", not a punishment.
   * Respects the reduced-effects setting.
   */
  static worldReact(
    scene: Phaser.Scene,
    outcome: "correct" | "wrong",
    options: {
      x?: number;
      y?: number;
      palette?: Palette;
      shakeTarget?: Phaser.GameObjects.Components.Transform | Phaser.GameObjects.Components.Transform[];
      /** Lighter reaction (no full-screen flash) — for fast per-answer sprints. */
      subtle?: boolean;
    } = {},
  ): void {
    const { x = 640, y = 360, palette = "academy", shakeTarget, subtle = false } = options;
    const reduced = settingsSystem.effectsReduced();
    if (outcome === "wrong") {
      if (!subtle) this.outcomeFlash(scene, "warning", x, y);
      if (shakeTarget && !reduced) this.shake(scene, shakeTarget, 5);
      return;
    }
    if (!subtle) this.outcomeFlash(scene, "success", x, y);
    this.particleBurst(scene, x, y, palette, "success");
    if (reduced) return;
    const accent = palettes[palette].accent;
    const ring = scene.add.circle(x, y, 26, accent, 0).setStrokeStyle(3, accent, 0.85).setDepth(921);
    scene.tweens.add({ targets: ring, scale: 6, alpha: { from: 0.85, to: 0 }, duration: 620, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    const bloom = scene.add.circle(x, y, 40, accent, 0.22).setDepth(919);
    scene.tweens.add({ targets: bloom, scale: 2.4, alpha: 0, duration: 520, ease: "Sine.easeOut", onComplete: () => bloom.destroy() });
  }

  static glassPanel(
    scene: Phaser.Scene,
    x: number,
    y: number,
    width: number,
    height: number,
    paletteName: Palette = "academy",
    alpha = 0.92,
  ): Phaser.GameObjects.Container {
    const palette = palettes[paletteName];
    const container = scene.add.container(x, y);
    container.add(scene.add.rectangle(12, 16, width, height, 0x000000, 0.34).setOrigin(0));
    container.add(scene.add.rectangle(0, 0, width, height, palette.deep, alpha).setOrigin(0).setStrokeStyle(1, palette.accent, 0.46));
    container.add(scene.add.rectangle(0, 0, width, height, 0xffffff, 0.025).setOrigin(0));
    container.add(scene.add.rectangle(0, 0, width, 3, palette.accent, 0.75).setOrigin(0));
    container.add(scene.add.rectangle(14, 14, width - 28, 1, 0xffffff, 0.08).setOrigin(0));
    container.add(scene.add.rectangle(width * 0.5, height - 3, width * 0.72, 2, palette.accent2, 0.22));
    const cornerScale = 0.42;
    [["tl", 18, 18, 0], ["tr", width - 18, 18, Math.PI / 2], ["br", width - 18, height - 18, Math.PI], ["bl", 18, height - 18, -Math.PI / 2]].forEach(([, cx, cy, rotation]) => {
      const corner = this.atlasImage(scene, Number(cx), Number(cy), "ui-corner", "holo-ring");
      corner.setTint(palette.accent).setAlpha(0.48).setScale(cornerScale).setRotation(Number(rotation));
      container.add(corner);
    });
    const flare = this.atlasImage(scene, width - 34, 22, "soft-flare", "soft-glow");
    flare.setTint(palette.warm).setAlpha(0.12).setScale(0.72);
    container.add(flare);
    return container;
  }

  static frame(scene: Phaser.Scene, x: number, y: number, width: number, height: number, paletteName: Palette = "academy"): void {
    const palette = palettes[paletteName];
    const g = scene.add.graphics();
    g.lineStyle(2, palette.accent, 0.5);
    g.strokeRect(x, y, width, height);
    g.lineStyle(4, palette.warm, 0.42);
    g.lineBetween(x, y, x + 58, y);
    g.lineBetween(x, y, x, y + 58);
    g.lineBetween(x + width, y + height, x + width - 58, y + height);
    g.lineBetween(x + width, y + height, x + width, y + height - 58);
  }

  static glowFrame(scene: Phaser.Scene, x: number, y: number, width: number, height: number, paletteName: Palette = "academy"): void {
    const palette = palettes[paletteName];
    scene.add.rectangle(x + width / 2, y + height / 2, width + 18, height + 18, palette.accent, 0.035).setStrokeStyle(6, palette.accent, 0.08);
    this.frame(scene, x, y, width, height, paletteName);
    scene.add.rectangle(x + width / 2, y + height / 2, width, height, 0x000000, 0).setStrokeStyle(1, 0xffffff, 0.12);
  }

  static holoLabel(scene: Phaser.Scene, x: number, y: number, label: string, paletteName: Palette = "academy"): Phaser.GameObjects.Container {
    const palette = palettes[paletteName];
    const container = scene.add.container(x, y);
    container.add(scene.add.rectangle(0, 0, 168, 38, palette.deep, 0.78).setStrokeStyle(1, palette.accent, 0.42));
    container.add(scene.add.rectangle(-58, -17, 42, 2, palette.warm, 0.72));
    container.add(scene.add.text(-64, -11, label, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    return container;
  }

  static vignette(scene: Phaser.Scene): void {
    scene.add.rectangle(640, 18, 1280, 36, 0x000000, 0.34);
    scene.add.rectangle(640, 702, 1280, 36, 0x000000, 0.34);
    scene.add.rectangle(14, 360, 28, 720, 0x000000, 0.3);
    scene.add.rectangle(1266, 360, 28, 720, 0x000000, 0.3);
    scene.add.rectangle(640, 360, 1280, 720, 0x000000, 0).setStrokeStyle(18, 0x000000, 0.18);
  }

  static sectionTitle(scene: Phaser.Scene, x: number, y: number, title: string, paletteName: Palette = "academy"): Phaser.GameObjects.Text {
    const palette = palettes[paletteName];
    scene.add.rectangle(x - 10, y + 16, 4, 30, palette.accent, 0.8);
    return scene.add.text(x, y, title, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
  }
}
