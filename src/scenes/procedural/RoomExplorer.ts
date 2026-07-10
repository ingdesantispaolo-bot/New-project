import Phaser from "phaser";
import { rewardSystem } from "../../core/RewardSystem";

export type RoomWall = { x: number; y: number; w: number; h: number };
export type RoomConsoleState = "active" | "resolved" | "failed" | "locked";

export type RoomConsole = {
  id: string;
  /** Frame id in the "mission-consoles" atlas (console_{assetId}_{active|resolved}). */
  assetId?: string;
  label: string;
  glyph: string;
  color: number;
  x: number;
  y: number;
  w: number;
  h: number;
  solved?: boolean;
  /** Visual/readiness state. `solved` is still accepted for older callers. */
  state?: RoomConsoleState;
  /** Opaque payload for the caller (e.g. the mission hotspot). */
  ref?: unknown;
  container?: Phaser.GameObjects.Container;
};

export type RoomExplorerConfig = {
  worldW: number;
  worldH: number;
  bgTexture?: string;
  walls: RoomWall[];
  consoles: RoomConsole[];
  onInteract: (console: RoomConsole) => void;
  /** Persist avatar position across scene restarts, keyed by this string. */
  seedKey?: string;
  avatarStart?: { x: number; y: number };
  /** Draw the decorative environment props (default true when atlas is loaded). */
  decorate?: boolean;
};

type Dir = "down" | "up" | "left" | "right";
const AVATAR_W = 46;
const AVATAR_H = 72;
const SPEED = 300;

/**
 * Stanza esplorabile riusabile: mondo più grande del viewport con telecamera che
 * segue l'avatar, collisioni, props e interazione di prossimità. Usata sia
 * dall'anteprima standalone sia dalla fase Esplora della missione (che passa gli
 * hotspot come `consoles` e `openHotspot` come `onInteract`).
 */
export class RoomExplorer {
  private static positions: Record<string, { x: number; y: number }> = {};

  private avatar!: Phaser.GameObjects.Container;
  private avatarSprite?: Phaser.GameObjects.Sprite;
  private avatarDir: Dir = "down";
  private walkPhase = 0;
  private avatarLegs: Phaser.GameObjects.Rectangle[] = [];
  private cursors: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys: Record<string, Phaser.Input.Keyboard.Key>;
  private moveTarget?: { x: number; y: number };
  private prompt!: Phaser.GameObjects.Container;
  private promptText!: Phaser.GameObjects.Text;
  private active?: RoomConsole;
  private paused = false;
  private readonly onE: () => void;
  private readonly onPointer: (pointer: Phaser.Input.Pointer) => void;

  constructor(private scene: Phaser.Scene, private cfg: RoomExplorerConfig) {
    scene.cameras.main.setBounds(0, 0, cfg.worldW, cfg.worldH);

    this.drawFloor();
    this.buildWalls();
    if (cfg.decorate ?? true) this.buildEnvironmentProps();
    this.buildConsoles();
    this.buildAvatar();
    this.buildPrompt();

    scene.cameras.main.startFollow(this.avatar, true, 0.12, 0.12);
    scene.cameras.main.setDeadzone(220, 160);

    this.cursors = scene.input.keyboard!.createCursorKeys();
    this.keys = scene.input.keyboard!.addKeys("W,A,S,D") as Record<string, Phaser.Input.Keyboard.Key>;
    this.onE = () => this.tryInteract();
    scene.input.keyboard!.on("keydown-E", this.onE);
    this.onPointer = (pointer) => {
      if (this.paused) return;
      const world = scene.cameras.main.getWorldPoint(pointer.x, pointer.y);
      if (this.active && this.pointInConsole(world.x, world.y, this.active)) {
        this.tryInteract();
        return;
      }
      this.moveTarget = { x: world.x, y: world.y };
    };
    scene.input.on("pointerdown", this.onPointer);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.teardown());
  }

  // --- world ---------------------------------------------------------------

  private drawFloor(): void {
    const { worldW, worldH, bgTexture } = this.cfg;
    if (bgTexture && this.scene.textures.exists(bgTexture)) {
      this.scene.add.image(0, 0, bgTexture).setOrigin(0, 0).setDisplaySize(worldW, worldH).setDepth(0);
      return;
    }
    const g = this.scene.add.graphics().setDepth(0);
    g.fillStyle(0x0a1a24, 1);
    g.fillRect(0, 0, worldW, worldH);
    g.lineStyle(1, 0x14323f, 0.6);
    for (let x = 0; x <= worldW; x += 88) g.lineBetween(x, 0, x, worldH);
    for (let y = 0; y <= worldH; y += 88) g.lineBetween(0, y, worldW, y);
  }

  private buildWalls(): void {
    const g = this.scene.add.graphics().setDepth(2);
    this.cfg.walls.forEach((w) => {
      g.fillStyle(0x0e2230, 0.55);
      g.fillRoundedRect(w.x, w.y, w.w, w.h, 8);
      g.lineStyle(2, 0x2a4d5e, 0.6);
      g.strokeRoundedRect(w.x, w.y, w.w, w.h, 8);
    });
  }

  private buildEnvironmentProps(): void {
    if (!this.scene.textures.exists("environment-props")) return;
    const { worldW } = this.cfg;
    const add = (frame: string, x: number, y: number, opt: { depth?: number; scale?: number; originY?: number; pulse?: boolean } = {}): void => {
      if (!this.scene.textures.getFrame("environment-props", frame)) return;
      const img = this.scene.add.image(x, y, "environment-props", frame)
        .setOrigin(0.5, opt.originY ?? 0.75).setScale(opt.scale ?? 1).setDepth((opt.depth ?? 3) + y / 10000);
      if (opt.pulse) this.scene.tweens.add({ targets: img, alpha: 0.72, duration: 1800, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    };
    add("env_pillar_square", 555, 590, { depth: 4, pulse: true });
    add("env_pillar_light", 1205, 590, { depth: 4, pulse: true });
    add("env_floor_cable", 675, 690, { depth: 1.6, originY: 0.5 });
    add("env_floor_cable", 1025, 720, { depth: 1.6, scale: 0.85, originY: 0.5 });
    add("env_floor_vent", 890, 580, { depth: 1.5, originY: 0.5, pulse: true });
    add("env_planter", 430, 150, { depth: 3 });
    add("env_plant_pod", 1515, 875, { depth: 4, pulse: true });
    add("env_terminal_wall", 155, 540, { depth: 4, pulse: true });
    add("env_terminal_kiosk", 1430, 700, { depth: 4, pulse: true });
    add("env_robot_decor", 555, 930, { depth: 4, scale: 0.9, pulse: true });
    add("env_holo_beacon", worldW / 2, 1000, { depth: 4, scale: 0.9, pulse: true });
  }

  private buildConsoles(): void {
    this.cfg.consoles.forEach((spot) => {
      const state = spot.state ?? (spot.solved ? "resolved" : "active");
      const stateMeta = this.consoleStateMeta(state, spot);
      const c = this.scene.add.container(spot.x, spot.y).setDepth(5);
      const frameState = state === "resolved" ? "resolved" : "active";
      const frame = `console_${spot.assetId ?? spot.id}_${frameState}`;
      const hasSprite = spot.assetId !== undefined
        && this.scene.textures.exists("mission-consoles")
        && Boolean(this.scene.textures.getFrame("mission-consoles", frame));
      if (hasSprite) {
        const sprite = this.scene.add.image(0, 0, "mission-consoles", frame).setOrigin(0.5);
        c.add(sprite);
        c.add(this.scene.add.circle(spot.w / 2 - 12, -spot.h / 2 + 18, 9, stateMeta.color, 0.96).setStrokeStyle(2, 0x03121b, 0.9));
        c.add(this.scene.add.text(0, spot.h / 2 + 12, spot.label.toUpperCase(), {
          fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1", fontStyle: "bold", stroke: "#03121b", strokeThickness: 4,
        }).setOrigin(0.5));
        if (state === "active") {
          this.scene.tweens.add({ targets: sprite, alpha: 0.9, duration: 1500, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
        }
      } else {
        c.add(this.scene.add.ellipse(0, spot.h / 2 - 8, spot.w * 1.05, 30, 0x000000, 0.32));
        c.add(this.scene.add.rectangle(0, 0, spot.w, spot.h, state === "locked" ? 0x101820 : 0x0c2130, 0.98).setStrokeStyle(3, stateMeta.color, 0.9));
        c.add(this.scene.add.rectangle(0, -spot.h / 2 + 8, spot.w - 16, 12, stateMeta.color, 0.9));
        c.add(this.scene.add.rectangle(0, -6, spot.w - 34, spot.h - 60, 0x03121b, 0.95).setStrokeStyle(1, spot.color, 0.5));
        c.add(this.scene.add.text(0, -6, spot.glyph, { fontFamily: "Inter, Arial", fontSize: "40px" }).setOrigin(0.5));
        c.add(this.scene.add.circle(spot.w / 2 - 14, -spot.h / 2 + 18, 8, stateMeta.color, 0.96).setStrokeStyle(2, 0x03121b, 0.9));
        c.add(this.scene.add.text(0, spot.h / 2 - 20, spot.label.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1", fontStyle: "bold" }).setOrigin(0.5));
      }
      if (state === "locked") c.setAlpha(0.58);
      else if (state === "failed") c.setAlpha(0.86);
      spot.container = c;
    });
  }

  private consoleStateMeta(state: RoomConsoleState, spot: RoomConsole): { color: number; prompt: string } {
    if (state === "resolved") return { color: 0x7cf6a6, prompt: `✓  ${spot.label}  ·  fatta` };
    if (state === "failed") return { color: 0xf6c85f, prompt: `!  ${spot.label}  ·  da rivedere` };
    if (state === "locked") return { color: 0x8aa2ad, prompt: `•  ${spot.label}  ·  bloccata` };
    return { color: spot.color, prompt: spot.id === "door" ? "▶  Uscita  ·  E / tocca" : `▶  ${spot.label}  ·  E / tocca` };
  }

  private buildAvatar(): void {
    const saved = this.cfg.seedKey ? RoomExplorer.positions[this.cfg.seedKey] : undefined;
    const start = saved ?? this.cfg.avatarStart ?? { x: this.cfg.worldW / 2, y: this.cfg.worldH / 2 + 120 };
    const accent = rewardSystem.colorForSlot("avatar", 0x6be7d6);
    const c = this.scene.add.container(start.x, start.y).setDepth(6);
    c.add(this.scene.add.ellipse(0, AVATAR_H / 2 + 4, AVATAR_W + 8, 16, 0x000000, 0.35));
    if (this.scene.textures.exists("eli-robot-girl")) {
      this.ensureAnimations();
      this.avatarSprite = this.scene.add.sprite(0, 0, "eli-robot-girl", "down_idle").setOrigin(0.5, 0.55);
      c.add(this.avatarSprite);
    } else {
      const legL = this.scene.add.rectangle(-10, AVATAR_H / 2 - 6, 12, 18, 0x123642).setStrokeStyle(1, accent, 0.7);
      const legR = this.scene.add.rectangle(10, AVATAR_H / 2 - 6, 12, 18, 0x123642).setStrokeStyle(1, accent, 0.7);
      this.avatarLegs = [legL, legR];
      c.add(legL); c.add(legR);
      c.add(this.scene.add.rectangle(0, 2, AVATAR_W, AVATAR_H - 26, 0x17475a, 1).setStrokeStyle(3, accent, 0.95));
      c.add(this.scene.add.circle(0, -AVATAR_H / 2 + 10, 17, 0x1b5468, 1).setStrokeStyle(3, accent, 0.95));
      c.add(this.scene.add.rectangle(3, -AVATAR_H / 2 + 10, 20, 12, 0x03121b, 1));
      c.add(this.scene.add.circle(8, -AVATAR_H / 2 + 10, 3, 0x8ff6ea, 1));
    }
    this.avatar = c;
  }

  private ensureAnimations(): void {
    (["down", "up", "left", "right"] as Dir[]).forEach((dir) => {
      const key = `eli-robot-girl-${dir}-walk`;
      if (this.scene.anims.exists(key)) return;
      this.scene.anims.create({
        key,
        frames: [1, 2, 3, 4].map((i) => ({ key: "eli-robot-girl", frame: `${dir}_walk${i}` })),
        frameRate: 8,
        repeat: -1,
      });
    });
  }

  private buildPrompt(): void {
    const c = this.scene.add.container(0, 0).setDepth(20).setVisible(false);
    c.add(this.scene.add.rectangle(0, 0, 286, 40, 0x061019, 0.96).setStrokeStyle(2, 0xf6c85f, 0.95));
    this.promptText = this.scene.add.text(0, 0, "", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5);
    c.add(this.promptText);
    this.prompt = c;
    this.scene.tweens.add({ targets: c, y: "-=6", duration: 700, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  // --- loop ----------------------------------------------------------------

  update(deltaMs: number, paused: boolean): void {
    this.paused = paused;
    if (paused) {
      this.prompt.setVisible(false);
      this.active = undefined;
      return;
    }
    const dt = deltaMs / 1000;
    let dx = (this.cursors.right.isDown || this.keys.D.isDown ? 1 : 0) - (this.cursors.left.isDown || this.keys.A.isDown ? 1 : 0);
    let dy = (this.cursors.down.isDown || this.keys.S.isDown ? 1 : 0) - (this.cursors.up.isDown || this.keys.W.isDown ? 1 : 0);
    if (dx !== 0 || dy !== 0) {
      this.moveTarget = undefined;
    } else if (this.moveTarget) {
      const tx = this.moveTarget.x - this.avatar.x;
      const ty = this.moveTarget.y - this.avatar.y;
      const dist = Math.hypot(tx, ty);
      if (dist < 6) this.moveTarget = undefined;
      else { dx = tx / dist; dy = ty / dist; }
    }
    const moving = dx !== 0 || dy !== 0;
    if (moving) {
      const len = Math.hypot(dx, dy) || 1;
      const step = SPEED * dt;
      this.moveWithCollision((dx / len) * step, (dy / len) * step);
      this.animateAvatar(dx, dy, dt, true);
      if (this.cfg.seedKey) RoomExplorer.positions[this.cfg.seedKey] = { x: this.avatar.x, y: this.avatar.y };
    } else {
      this.animateAvatar(0, 0, dt, false);
    }
    this.avatar.setDepth(6 + this.avatar.y / 1000);
    this.updateNearestConsole();
  }

  private animateAvatar(dx: number, dy: number, dt: number, moving: boolean): void {
    if (this.avatarSprite) {
      if (moving) {
        this.avatarDir = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "right" : "left") : (dy > 0 ? "down" : "up");
        const walkKey = `eli-robot-girl-${this.avatarDir}-walk`;
        if (this.avatarSprite.anims.currentAnim?.key !== walkKey || !this.avatarSprite.anims.isPlaying) this.avatarSprite.play(walkKey);
      } else {
        this.avatarSprite.stop();
        this.avatarSprite.setFrame(`${this.avatarDir}_idle`);
      }
      return;
    }
    if (moving) {
      this.walkPhase += dt * 10;
      const swing = Math.sin(this.walkPhase) * 5;
      if (this.avatarLegs[0]) this.avatarLegs[0].y = AVATAR_H / 2 - 6 + swing;
      if (this.avatarLegs[1]) this.avatarLegs[1].y = AVATAR_H / 2 - 6 - swing;
    } else if (this.avatarLegs[0]) {
      this.avatarLegs[0].y = AVATAR_H / 2 - 6;
      this.avatarLegs[1].y = AVATAR_H / 2 - 6;
    }
  }

  private moveWithCollision(mx: number, my: number): void {
    const feetH = 26;
    const halfW = AVATAR_W / 2;
    const free = (nx: number, ny: number): boolean => {
      const box = { x: nx - halfW, y: ny + AVATAR_H / 2 - feetH, w: AVATAR_W, h: feetH };
      return !this.cfg.walls.some((w) => box.x < w.x + w.w && box.x + box.w > w.x && box.y < w.y + w.h && box.y + box.h > w.y);
    };
    const nextX = Phaser.Math.Clamp(this.avatar.x + mx, halfW + 6, this.cfg.worldW - halfW - 6);
    if (free(nextX, this.avatar.y)) this.avatar.x = nextX;
    const nextY = Phaser.Math.Clamp(this.avatar.y + my, 30, this.cfg.worldH - 20);
    if (free(this.avatar.x, nextY)) this.avatar.y = nextY;
  }

  private pointInConsole(px: number, py: number, spot: RoomConsole): boolean {
    return Math.abs(px - spot.x) < spot.w / 2 + 40 && Math.abs(py - spot.y) < spot.h / 2 + 40;
  }

  private updateNearestConsole(): void {
    let best: RoomConsole | undefined;
    let bestDist = Infinity;
    for (const spot of this.cfg.consoles) {
      const d = Math.hypot(spot.x - this.avatar.x, (spot.y + spot.h / 2) - this.avatar.y);
      if (d < 120 && d < bestDist) { bestDist = d; best = spot; }
    }
    if (best !== this.active) {
      this.cfg.consoles.forEach((s) => s.container?.setScale(1));
      this.active = best;
      best?.container?.setScale(1.06);
    }
    if (best) {
      this.prompt.setVisible(true).setPosition(best.x, best.y - best.h / 2 - 34);
      this.promptText.setText(this.consoleStateMeta(best.state ?? (best.solved ? "resolved" : "active"), best).prompt);
    } else {
      this.prompt.setVisible(false);
    }
  }

  private tryInteract(): void {
    if (this.paused || !this.active) return;
    this.cfg.onInteract(this.active);
  }

  // --- public API ----------------------------------------------------------

  /** Freeze movement and reset the camera so fullscreen overlays render correctly. */
  pauseForOverlay(): void {
    this.paused = true;
    this.prompt.setVisible(false);
    const cam = this.scene.cameras.main;
    cam.stopFollow();
    cam.setScroll(0, 0);
  }

  resume(): void {
    this.paused = false;
    this.scene.cameras.main.startFollow(this.avatar, true, 0.12, 0.12);
  }

  teardown(): void {
    this.scene.input.keyboard?.off("keydown-E", this.onE);
    this.scene.input.off("pointerdown", this.onPointer);
  }
}
