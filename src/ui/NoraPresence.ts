import { settingsSystem } from "../core/SettingsSystem";
import Phaser from "phaser";
import { noraCompanion, type NoraMoodMemoryKey } from "../core/NoraCompanion";

export type NoraPresenceMood = "calm" | "thinking" | "happy" | "alert" | "hurt" | "guardian";
export type NoraPresenceTone = "info" | "success" | "warning";

const MOOD_COLORS: Record<NoraPresenceMood, number> = {
  calm: 0x9ff5e9,
  thinking: 0x7ad7ff,
  happy: 0x6be7d6,
  alert: 0xf6c85f,
  hurt: 0xff8f8f,
  guardian: 0xcdbfff,
};

const TONE_MOOD: Record<NoraPresenceTone, NoraPresenceMood> = {
  info: "calm",
  success: "happy",
  warning: "alert",
};

type PresenceMountOptions = {
  x?: number;
  y?: number;
  compact?: boolean;
  depth?: number;
};

class NoraPresenceInstance {
  private container: Phaser.GameObjects.Container;
  private aura: Phaser.GameObjects.Arc;
  private shell: Phaser.GameObjects.Arc;
  private core: Phaser.GameObjects.Arc;
  private ring: Phaser.GameObjects.Arc;
  private orbit: Phaser.GameObjects.Container;
  private orbitNodes: Phaser.GameObjects.Arc[];
  private signalTicks: Phaser.GameObjects.Rectangle[];
  private portrait?: Phaser.GameObjects.Image;
  private portraitMask?: Phaser.GameObjects.Graphics;
  private scanLine?: Phaser.GameObjects.Rectangle;
  private label: Phaser.GameObjects.Text;
  private bubble: Phaser.GameObjects.Container;
  private bubbleText: Phaser.GameObjects.Text;
  private mood: NoraPresenceMood = "calm";

  constructor(private scene: Phaser.Scene, options: PresenceMountOptions = {}) {
    const x = options.x ?? 38;
    const y = options.y ?? scene.scale.height - 96;
    const depth = options.depth ?? 9300;
    const compact = options.compact ?? false;
    this.container = scene.add.container(x, y).setDepth(depth).setScrollFactor(0);
    this.container.setAlpha(0);

    const radius = compact ? 25 : 31;
    this.aura = scene.add.circle(0, 0, radius + 16, MOOD_COLORS.calm, 0.07);
    this.shell = scene.add.circle(0, 0, radius, 0x07151d, 0.96)
      .setStrokeStyle(2, MOOD_COLORS.calm, 0.86);
    this.ring = scene.add.circle(0, 0, radius + 10, 0x000000, 0)
      .setStrokeStyle(2, MOOD_COLORS.calm, 0.24);
    this.orbit = scene.add.container(0, 0);
    this.orbitNodes = [0, 120, 240].map((degrees) => {
      const radians = Phaser.Math.DegToRad(degrees);
      const node = scene.add.circle(
        Math.cos(radians) * (radius + 10),
        Math.sin(radians) * (radius + 10),
        compact ? 2 : 2.5,
        MOOD_COLORS.calm,
        0.9,
      );
      this.orbit.add(node);
      return node;
    });
    this.signalTicks = [-1, 0, 1].map((offset) => scene.add.rectangle(
      offset * (compact ? 5 : 6),
      radius + 7,
      compact ? 2 : 3,
      compact ? 4 + (offset + 1) * 2 : 5 + (offset + 1) * 2,
      MOOD_COLORS.calm,
      0.66,
    ));

    if (scene.textures.exists("nora-presence-portrait-v2")) {
      const portraitSize = radius * 2 - 4;
      this.portrait = scene.add.image(0, 0, "nora-presence-portrait-v2").setDisplaySize(portraitSize, portraitSize);
      this.portraitMask = scene.make.graphics({ x: options.x ?? 38, y: options.y ?? scene.scale.height - 96 });
      this.portraitMask.fillStyle(0xffffff).fillCircle(0, 0, radius - 2);
      this.portrait.setMask(this.portraitMask.createGeometryMask());
      this.scanLine = scene.add.rectangle(0, -radius + 5, radius * 1.55, compact ? 2 : 3, 0xffffff, 0.18);
      this.scanLine.setMask(this.portraitMask.createGeometryMask());
    }

    this.core = scene.add.circle(0, 0, compact ? 4 : 5, 0xffffff, this.portrait ? 0.2 : 0.92);
    this.label = scene.add.text(0, radius + 14, "NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5);

    this.bubble = scene.add.container(44, -46).setAlpha(0);
    this.bubble.add(scene.add.rectangle(0, 0, compact ? 278 : 328, compact ? 72 : 84, 0x061019, 0.96)
      .setOrigin(0, 0.5)
      .setStrokeStyle(2, MOOD_COLORS.calm, 0.78));
    this.bubble.add(scene.add.rectangle(0, compact ? -36 : -42, compact ? 278 : 328, 4, MOOD_COLORS.calm, 0.9).setOrigin(0));
    this.bubbleText = scene.add.text(16, compact ? -24 : -30, "", {
      fontFamily: "Inter, Arial",
      fontSize: compact ? "11px" : "12px",
      color: "#eaf4f8",
      wordWrap: { width: compact ? 246 : 296, useAdvancedWrap: true },
      lineSpacing: 3,
    });
    this.bubble.add(this.bubbleText);

    this.container.add([
      this.aura,
      this.ring,
      this.orbit,
      this.shell,
      ...(this.portrait ? [this.portrait] : []),
      ...(this.scanLine ? [this.scanLine] : []),
      this.core,
      ...this.signalTicks,
      this.label,
      this.bubble,
    ]);

    const reduced = settingsSystem.effectsReduced();
    scene.tweens.add({ targets: this.container, alpha: 1, duration: reduced ? 80 : 320, ease: "Sine.easeOut" });
    if (!reduced) {
      scene.tweens.add({ targets: this.ring, scale: 1.18, alpha: 0.54, duration: 1600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      scene.tweens.add({ targets: this.core, scale: 1.22, alpha: 0.72, duration: 920, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      scene.tweens.add({ targets: this.orbit, angle: 360, duration: 12000, repeat: -1, ease: "Linear" });
      if (this.scanLine) {
        scene.tweens.add({ targets: this.scanLine, y: radius - 5, alpha: { from: 0.05, to: 0.26 }, duration: 2400, repeat: -1, ease: "Sine.easeInOut" });
      }
    }
  }

  setMood(mood: NoraPresenceMood): void {
    this.mood = mood;
    const color = MOOD_COLORS[mood];
    this.shell.setStrokeStyle(2, color, 0.88);
    this.ring.setStrokeStyle(2, color, mood === "guardian" ? 0.42 : 0.26);
    this.aura.setFillStyle(color, mood === "guardian" ? 0.16 : mood === "hurt" ? 0.04 : 0.08);
    this.core.setFillStyle(color, this.portrait ? 0.28 : 0.98);
    this.orbitNodes.forEach((node, index) => node.setFillStyle(color, mood === "hurt" ? 0.35 : 0.82 + index * 0.06));
    this.signalTicks.forEach((tick, index) => {
      tick.setFillStyle(color, mood === "hurt" ? 0.26 : 0.52 + index * 0.14);
      tick.setScale(1, mood === "alert" ? 1.45 : mood === "thinking" ? 1.16 : 1);
    });
    if (this.portrait) {
      this.portrait.setAlpha(mood === "hurt" ? 0.7 : 0.98);
      if (mood === "alert") this.portrait.setTint(0xffd98a);
      else if (mood === "hurt") this.portrait.setTint(0xffb0b0);
      else if (mood === "guardian") this.portrait.setTint(0xe5ddff);
      else this.portrait.clearTint();
    }
    this.label.setColor(mood === "hurt" ? "#ffb0a8" : mood === "guardian" ? "#cdbfff" : "#f6c85f");
  }

  speak(text: string, tone: NoraPresenceTone = "info", holdMs = 4200): void {
    noraCompanion.recordMood(this.moodForTone(tone));
    this.setMood(TONE_MOOD[tone]);
    const color = MOOD_COLORS[this.mood];
    const topBar = this.bubble.list[1] as Phaser.GameObjects.Rectangle;
    const panel = this.bubble.list[0] as Phaser.GameObjects.Rectangle;
    panel.setStrokeStyle(2, color, 0.78);
    topBar.setFillStyle(color, 0.9);
    this.bubbleText.setText(text);
    this.emitSignal(color, tone);
    this.scene.tweens.killTweensOf(this.bubble);
    this.bubble.setAlpha(0).setX(34);
    this.scene.tweens.add({ targets: this.bubble, alpha: 1, x: 44, duration: 180, ease: "Sine.easeOut" });
    this.scene.tweens.add({
      targets: this.bubble,
      alpha: 0,
      delay: holdMs,
      duration: 260,
      ease: "Sine.easeIn",
      onComplete: () => this.setMood("calm"),
    });
  }

  private emitSignal(color: number, tone: NoraPresenceTone): void {
    if (settingsSystem.effectsReduced()) return;
    const count = tone === "success" ? 8 : tone === "warning" ? 5 : 4;
    for (let index = 0; index < count; index += 1) {
      const angle = (Math.PI * 2 * index) / count + Math.PI / 10;
      const spark = this.scene.add.circle(
        this.container.x + Math.cos(angle) * 18,
        this.container.y + Math.sin(angle) * 18,
        tone === "success" ? 2.2 : 1.6,
        color,
        0.84,
      ).setDepth(this.container.depth - 1).setScrollFactor(0);
      this.scene.tweens.add({
        targets: spark,
        x: spark.x + Math.cos(angle) * (tone === "success" ? 42 : 28),
        y: spark.y + Math.sin(angle) * (tone === "success" ? 42 : 28),
        alpha: 0,
        scale: 0.4,
        duration: 520 + index * 45,
        ease: "Sine.easeOut",
        onComplete: () => spark.destroy(),
      });
    }
  }

  pulse(mood: NoraPresenceMood = "thinking"): void {
    this.setMood(mood);
    this.scene.tweens.add({
      targets: [this.shell, this.ring],
      scale: 1.16,
      duration: 180,
      yoyo: true,
      ease: "Sine.easeOut",
      onComplete: () => this.setMood("calm"),
    });
  }

  storyMoment(text: string, tone: NoraPresenceTone = "info", title = "NORA"): void {
    noraCompanion.recordMood(this.moodForTone(tone));
    const color = MOOD_COLORS[TONE_MOOD[tone]];
    const overlay = this.scene.add.container(0, 0).setDepth(9800).setScrollFactor(0);
    overlay.add(this.scene.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.72).setInteractive());
    overlay.add(this.scene.add.rectangle(640, 360, 760, 420, 0x061019, 0.96).setStrokeStyle(2, color, 0.86));
    overlay.add(this.scene.add.rectangle(640, 152, 760, 5, color, 0.92));

    const stage = noraCompanion.currentVisualStage();
    if (this.scene.textures.exists(stage.key)) {
      const portrait = this.scene.add.image(640, 292, stage.key).setDisplaySize(560, 250);
      overlay.add(portrait);
      overlay.add(this.scene.add.rectangle(640, 292, 560, 250, 0x02070b, 0.12).setStrokeStyle(1, color, 0.36));
      if (!settingsSystem.effectsReduced()) {
        this.scene.tweens.add({ targets: portrait, scaleX: portrait.scaleX * 1.018, scaleY: portrait.scaleY * 1.018, duration: 3600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    } else {
      const core = this.scene.add.circle(640, 286, 66, color, 0.96);
      const inner = this.scene.add.circle(640, 286, 22, 0xffffff, 0.92);
      const ring = this.scene.add.circle(640, 286, 100, 0x000000, 0).setStrokeStyle(4, color, 0.42);
      overlay.add([ring, core, inner]);
      if (!settingsSystem.effectsReduced()) {
        this.scene.tweens.add({ targets: ring, scale: 1.24, alpha: 0.7, duration: 1400, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    }

    overlay.add(this.scene.add.text(640, 170, title, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.scene.add.text(640, 438, text, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#eaf4f8",
      align: "center",
      wordWrap: { width: 660, useAdvancedWrap: true },
      lineSpacing: 6,
    }).setOrigin(0.5, 0));

    overlay.setAlpha(0);
    this.scene.tweens.add({ targets: overlay, alpha: 1, duration: 220, ease: "Sine.easeOut" });
    this.scene.time.delayedCall(5200, () => {
      this.scene.tweens.add({ targets: overlay, alpha: 0, duration: 420, ease: "Sine.easeIn", onComplete: () => overlay.destroy(true) });
    });
  }

  private moodForTone(tone: NoraPresenceTone): NoraMoodMemoryKey {
    if (tone === "success") return "bright";
    if (tone === "warning") return "worried";
    return "steady";
  }

  destroy(): void {
    this.portrait?.clearMask(true);
    this.scanLine?.clearMask(true);
    this.portraitMask?.destroy();
    this.container.destroy(true);
  }
}

class NoraPresenceController {
  private instances = new WeakMap<Phaser.Scene, NoraPresenceInstance>();

  mount(scene: Phaser.Scene, options: PresenceMountOptions = {}): NoraPresenceInstance {
    this.instances.get(scene)?.destroy();
    const instance = new NoraPresenceInstance(scene, options);
    this.instances.set(scene, instance);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.instances.get(scene)?.destroy();
      this.instances.delete(scene);
    });
    return instance;
  }

  speak(scene: Phaser.Scene, text: string, tone: NoraPresenceTone = "info", holdMs?: number): void {
    const instance = this.instances.get(scene) ?? this.mount(scene);
    instance.speak(text, tone, holdMs);
  }

  storyMoment(scene: Phaser.Scene, text: string, tone: NoraPresenceTone = "info", title?: string): void {
    const instance = this.instances.get(scene) ?? this.mount(scene);
    instance.storyMoment(text, tone, title);
  }

  pulse(scene: Phaser.Scene, mood: NoraPresenceMood = "thinking"): void {
    const instance = this.instances.get(scene) ?? this.mount(scene);
    instance.pulse(mood);
  }
}

export const noraPresence = new NoraPresenceController();
