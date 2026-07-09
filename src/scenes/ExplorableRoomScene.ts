import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { rewardSystem } from "../core/RewardSystem";
import { Button } from "../ui/Button";

/**
 * Stanza esplorabile — prototipo di "agency": invece di cliccare hotspot su una
 * schermata fissa, il giocatore MUOVE un avatar in una stanza più grande del
 * viewport (la telecamera lo segue) e INTERAGISCE avvicinandosi alle console.
 *
 * Grafica placeholder (sole forme) con proporzioni corrette e pensata per essere
 * sostituita dagli asset del collaboratore (pavimento, pareti, avatar, props)
 * senza cambiare la logica. L'apertura di una console passa da un callback
 * (`onInteract`), lo stesso seam che la missione già usa per aprire gli esercizi.
 */

type Wall = { x: number; y: number; w: number; h: number };
type AvatarDirection = "down" | "up" | "left" | "right";
type ConsoleSpot = {
  id: string;
  assetId: string;
  label: string;
  glyph: string;
  color: number;
  x: number;
  y: number;
  w: number;
  h: number;
  container?: Phaser.GameObjects.Container;
  done?: boolean;
};

// --- Proporzioni (studio) -------------------------------------------------
// Viewport 1280x720. Il MONDO è ~1.4x su ogni asse → vedi ~70% della stanza e
// la telecamera panoramica dà il senso di spazio. Griglia 88px. Avatar alto
// 72px (~0.8 tile: una persona su griglia da 1 tile). Console 120x150 (~1.7
// tile) → le macchine torreggiano leggermente sull'avatar. Così ci si sente
// "piccoli in una grande stanza": il "molto più grande" richiesto.
const WORLD_W = 1760;
const WORLD_H = 1120;
const TILE = 88;
const AVATAR_W = 46;
const AVATAR_H = 72;
const SPEED = 300; // px/s

export class ExplorableRoomScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
  private avatar!: Phaser.GameObjects.Container;
  private avatarSprite?: Phaser.GameObjects.Sprite;
  private avatarLegs: Phaser.GameObjects.Rectangle[] = [];
  private avatarDirection: AvatarDirection = "down";
  private facing = 1;
  private walkPhase = 0;
  private moveTarget?: { x: number; y: number };
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private walls: Wall[] = [];
  private consoles: ConsoleSpot[] = [];
  private prompt!: Phaser.GameObjects.Container;
  private promptText!: Phaser.GameObjects.Text;
  private activeConsole?: ConsoleSpot;
  private overlayOpen = false;
  private hintText!: Phaser.GameObjects.Text;

  constructor() {
    super("ExplorableRoomScene");
  }

  create(data?: { returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    this.cameras.main.setBounds(0, 0, WORLD_W, WORLD_H);
    this.cameras.main.setBackgroundColor(0x060f16);

    this.drawFloor();
    this.buildWalls();
    this.buildEnvironmentProps();
    this.buildConsoles();
    this.buildAvatar();
    this.buildPrompt();
    this.buildHud();

    this.cameras.main.startFollow(this.avatar, true, 0.12, 0.12);
    this.cameras.main.setDeadzone(220, 160);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,E") as Record<string, Phaser.Input.Keyboard.Key>;
    this.keys.E.on("down", () => this.tryInteract());

    // Click/tap: se tocchi una console vicina interagisci, altrimenti cammina lì.
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (this.overlayOpen) return;
      const world = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
      if (this.activeConsole && this.pointInConsole(world.x, world.y, this.activeConsole)) {
        this.tryInteract();
        return;
      }
      this.moveTarget = { x: world.x, y: world.y };
    });
    audioManager.play("scan");
  }

  // --- costruzione mondo ---------------------------------------------------

  private drawFloor(): void {
    // Sfondo-stanza dipinto (1760x1120 = mondo) se disponibile, altrimenti la
    // griglia placeholder.
    if (this.textures.exists("action-room-bg")) {
      this.add.image(0, 0, "action-room-bg").setOrigin(0, 0).setDisplaySize(WORLD_W, WORLD_H).setDepth(0);
      return;
    }
    const g = this.add.graphics().setDepth(0);
    g.fillStyle(0x0a1a24, 1);
    g.fillRect(0, 0, WORLD_W, WORLD_H);
    // piastrelle
    g.lineStyle(1, 0x14323f, 0.6);
    for (let x = 0; x <= WORLD_W; x += TILE) g.lineBetween(x, 0, x, WORLD_H);
    for (let y = 0; y <= WORLD_H; y += TILE) g.lineBetween(0, y, WORLD_W, y);
    // bagliore centrale morbido
    const glow = this.add.circle(WORLD_W / 2, WORLD_H / 2, 520, 0x123043, 0.25).setDepth(0);
    this.tweens.add({ targets: glow, alpha: 0.12, duration: 3200, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  private buildWalls(): void {
    const t = 40;
    this.walls = [
      { x: 0, y: 0, w: WORLD_W, h: t },
      { x: 0, y: WORLD_H - t, w: WORLD_W, h: t },
      { x: 0, y: 0, w: t, h: WORLD_H },
      { x: WORLD_W - t, y: 0, w: t, h: WORLD_H },
      // pilastri interni per dare struttura e testare le collisioni
      { x: 520, y: 470, w: 70, h: 240 },
      { x: 1170, y: 470, w: 70, h: 240 },
      { x: 810, y: 250, w: 150, h: 60 },
    ];
    const g = this.add.graphics().setDepth(2);
    this.walls.forEach((w) => {
      g.fillStyle(0x0e2230, 1);
      g.fillRoundedRect(w.x, w.y, w.w, w.h, 8);
      g.lineStyle(2, 0x2a4d5e, 0.9);
      g.strokeRoundedRect(w.x, w.y, w.w, w.h, 8);
    });
  }

  private buildEnvironmentProps(): void {
    if (!this.textures.exists("environment-props")) return;

    const addProp = (
      frame: string,
      x: number,
      y: number,
      options: { depth?: number; scale?: number; originY?: number; pulse?: boolean } = {},
    ): Phaser.GameObjects.Image | undefined => {
      if (!this.textures.getFrame("environment-props", frame)) return undefined;
      const image = this.add.image(x, y, "environment-props", frame)
        .setOrigin(0.5, options.originY ?? 0.75)
        .setScale(options.scale ?? 1)
        .setDepth((options.depth ?? 3) + y / 10000);
      if (options.pulse) {
        this.tweens.add({ targets: image, alpha: 0.72, duration: 1800, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
      return image;
    };

    // Pareti modulari: danno forma alla stanza senza cambiare le collisioni.
    addProp("env_wall_straight", 260, 92, { depth: 2, originY: 0.5 });
    addProp("env_wall_straight", 620, 92, { depth: 2, originY: 0.5 });
    addProp("env_wall_straight", 1040, 92, { depth: 2, originY: 0.5 });
    addProp("env_wall_straight", 1460, 92, { depth: 2, originY: 0.5 });
    addProp("env_wall_corner", 78, 118, { depth: 2, scale: 0.82, originY: 0.5 });
    addProp("env_wall_corner", WORLD_W - 78, 118, { depth: 2, scale: 0.82, originY: 0.5 });
    addProp("env_railing", 880, 300, { depth: 2.6, originY: 0.65 });

    // Ostacoli verticali: leggono come pilastri veri sopra i collider esistenti.
    addProp("env_pillar_square", 555, 590, { depth: 4, pulse: true });
    addProp("env_pillar_light", 1205, 590, { depth: 4, pulse: true });

    // Dettagli da pavimento, bassi e non invasivi.
    addProp("env_floor_cable", 675, 690, { depth: 1.6, originY: 0.5 });
    addProp("env_floor_cable", 1025, 720, { depth: 1.6, scale: 0.85, originY: 0.5 });
    addProp("env_floor_vent", 890, 580, { depth: 1.5, originY: 0.5, pulse: true });
    addProp("env_floor_vent", 1470, 360, { depth: 1.5, scale: 0.85, originY: 0.5 });

    // Vita ambientale: vegetazione, terminali secondari e piccoli robot decorativi.
    addProp("env_planter", 430, 150, { depth: 3 });
    addProp("env_plant_pod", 1515, 875, { depth: 4, pulse: true });
    addProp("env_terminal_wall", 155, 540, { depth: 4, pulse: true });
    addProp("env_terminal_kiosk", 1430, 700, { depth: 4, pulse: true });
    addProp("env_crate_stack", 1560, 965, { depth: 4 });
    addProp("env_robot_decor", 555, 930, { depth: 4, scale: 0.9, pulse: true });
    addProp("env_repair_drone", 1010, 920, { depth: 4, scale: 0.9, pulse: true });
    addProp("env_holo_beacon", WORLD_W / 2, 1000, { depth: 4, scale: 0.9, pulse: true });
  }

  private buildConsoles(): void {
    const defs: Array<Omit<ConsoleSpot, "w" | "h">> = [
      { id: "math", assetId: "math", label: "Matematica", glyph: "➗", color: 0x6be7d6, x: 250, y: 250 },
      { id: "italian", assetId: "italian", label: "Italiano", glyph: "✒️", color: 0x9f8cff, x: 710, y: 210 },
      { id: "english", assetId: "english", label: "Inglese", glyph: "🌍", color: 0x7ad7ff, x: 1180, y: 250 },
      { id: "coding", assetId: "coding", label: "Coding", glyph: "💻", color: 0x7cf6a6, x: 320, y: 840 },
      { id: "circuit", assetId: "electronics", label: "Elettronica", glyph: "⚡", color: 0xf6c85f, x: 1180, y: 840 },
      { id: "music", assetId: "music", label: "Musica", glyph: "🎵", color: 0xff9d5c, x: 760, y: 900 },
      { id: "door", assetId: "exit", label: "Uscita", glyph: "🚪", color: 0xffd75e, x: 1560, y: 560 },
    ];
    this.consoles = defs.map((d) => ({ ...d, w: 120, h: 150 }));
    this.consoles.forEach((spot) => {
      const c = this.add.container(spot.x, spot.y).setDepth(5);
      const frame = this.consoleFrame(spot);
      const hasSprite = this.textures.exists("mission-consoles") && Boolean(this.textures.getFrame("mission-consoles", frame));
      if (hasSprite) {
        const sprite = this.add.image(0, 0, "mission-consoles", frame).setOrigin(0.5);
        c.add(sprite);
        c.add(this.add.text(0, spot.h / 2 + 12, spot.label.toUpperCase(), {
          fontFamily: "Inter, Arial",
          fontSize: "13px",
          color: "#d9eaf1",
          fontStyle: "bold",
          stroke: "#03121b",
          strokeThickness: 4,
        }).setOrigin(0.5));
        this.tweens.add({ targets: sprite, alpha: 0.9, duration: 1500, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      } else {
        c.add(this.add.ellipse(0, spot.h / 2 - 8, spot.w * 1.05, 30, 0x000000, 0.32));
        c.add(this.add.rectangle(0, 0, spot.w, spot.h, 0x0c2130, 0.98).setStrokeStyle(3, spot.color, 0.9));
        c.add(this.add.rectangle(0, -spot.h / 2 + 8, spot.w - 16, 12, spot.color, 0.9)); // top light bar
        c.add(this.add.rectangle(0, -6, spot.w - 34, spot.h - 60, 0x03121b, 0.95).setStrokeStyle(1, spot.color, 0.5)); // screen
        c.add(this.add.text(0, -6, spot.glyph, { fontFamily: "Inter, Arial", fontSize: "40px" }).setOrigin(0.5));
        c.add(this.add.text(0, spot.h / 2 - 20, spot.label.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1", fontStyle: "bold" }).setOrigin(0.5));
        this.tweens.add({ targets: c.list[2], alpha: 0.5, duration: 1400, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
      spot.container = c;
    });
  }

  private consoleFrame(spot: ConsoleSpot): string {
    return `console_${spot.assetId}_${spot.done ? "resolved" : "active"}`;
  }

  private buildAvatar(): void {
    this.ensureAvatarAnimations();
    // Suit colour reflects the cosmetic bought with earned energy (default cyan).
    const accent = rewardSystem.colorForSlot("avatar", 0x6be7d6);
    const c = this.add.container(WORLD_W / 2, WORLD_H / 2 + 120).setDepth(6);
    c.add(this.add.ellipse(0, AVATAR_H / 2 + 4, AVATAR_W + 8, 16, 0x000000, 0.35)); // shadow
    if (this.textures.exists("eli-robot-girl")) {
      this.avatarSprite = this.add.sprite(0, 0, "eli-robot-girl", "down_idle").setOrigin(0.5, 0.55);
      c.add(this.avatarSprite);
      this.avatar = c;
      return;
    }
    const legL = this.add.rectangle(-10, AVATAR_H / 2 - 6, 12, 18, 0x123642).setStrokeStyle(1, accent, 0.7);
    const legR = this.add.rectangle(10, AVATAR_H / 2 - 6, 12, 18, 0x123642).setStrokeStyle(1, accent, 0.7);
    this.avatarLegs = [legL, legR];
    c.add(legL);
    c.add(legR);
    c.add(this.add.rectangle(0, 2, AVATAR_W, AVATAR_H - 26, 0x17475a, 1).setStrokeStyle(3, accent, 0.95)); // body
    c.add(this.add.circle(0, -AVATAR_H / 2 + 10, 17, 0x1b5468, 1).setStrokeStyle(3, accent, 0.95)); // head
    c.add(this.add.rectangle(3, -AVATAR_H / 2 + 10, 20, 12, 0x03121b, 1)); // visor
    c.add(this.add.circle(8, -AVATAR_H / 2 + 10, 3, 0x8ff6ea, 1)); // eye
    this.avatar = c;
  }

  private ensureAvatarAnimations(): void {
    if (!this.textures.exists("eli-robot-girl")) return;
    (["down", "up", "left", "right"] as AvatarDirection[]).forEach((direction) => {
      const key = `eli-robot-girl-${direction}-walk`;
      if (this.anims.exists(key)) return;
      this.anims.create({
        key,
        frames: [1, 2, 3, 4].map((index) => ({ key: "eli-robot-girl", frame: `${direction}_walk${index}` })),
        frameRate: 8,
        repeat: -1,
      });
    });
  }

  private buildPrompt(): void {
    const c = this.add.container(0, 0).setDepth(20).setVisible(false);
    c.add(this.add.rectangle(0, 0, 210, 40, 0x061019, 0.96).setStrokeStyle(2, 0xf6c85f, 0.95));
    this.promptText = this.add.text(0, 0, "", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5);
    c.add(this.promptText);
    this.prompt = c;
    this.tweens.add({ targets: c, y: "-=6", duration: 700, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  private buildHud(): void {
    this.hintText = this.add.text(24, 22, "Muoviti: WASD / frecce / tocca il pavimento · Avvicinati a una console e premi E (o toccala)", {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", backgroundColor: "rgba(4,18,28,0.8)", padding: { x: 10, y: 6 },
    }).setScrollFactor(0).setDepth(50);
    new Button(this, 1180, 40, "Indietro", () => this.scene.start(this.returnScene), { width: 150, height: 40, fontSize: 15, fill: 0x263743 })
      .setScrollFactor(0).setDepth(50);
  }

  // --- loop ----------------------------------------------------------------

  update(_time: number, delta: number): void {
    if (this.overlayOpen) return;
    const dt = delta / 1000;
    let dx = 0;
    let dy = 0;
    const left = this.cursors.left.isDown || this.keys.A.isDown;
    const right = this.cursors.right.isDown || this.keys.D.isDown;
    const up = this.cursors.up.isDown || this.keys.W.isDown;
    const down = this.cursors.down.isDown || this.keys.S.isDown;
    if (left || right || up || down) {
      this.moveTarget = undefined;
      dx = (right ? 1 : 0) - (left ? 1 : 0);
      dy = (down ? 1 : 0) - (up ? 1 : 0);
    } else if (this.moveTarget) {
      const tx = this.moveTarget.x - this.avatar.x;
      const ty = this.moveTarget.y - this.avatar.y;
      const dist = Math.hypot(tx, ty);
      if (dist < 6) {
        this.moveTarget = undefined;
      } else {
        dx = tx / dist;
        dy = ty / dist;
      }
    }

    const moving = dx !== 0 || dy !== 0;
    if (moving) {
      const len = Math.hypot(dx, dy) || 1;
      const step = SPEED * dt;
      this.moveWithCollision((dx / len) * step, (dy / len) * step);
      if (this.avatarSprite) {
        this.updateAvatarSprite(dx, dy, true);
      } else {
        if (dx !== 0) this.setFacing(dx > 0 ? 1 : -1);
        this.walkPhase += dt * 10;
        const swing = Math.sin(this.walkPhase) * 5;
        this.avatarLegs[0].y = AVATAR_H / 2 - 6 + swing;
        this.avatarLegs[1].y = AVATAR_H / 2 - 6 - swing;
        this.avatar.y += 0; // keep base; bob applied via body could be added later
      }
    } else {
      if (this.avatarSprite) {
        this.updateAvatarSprite(0, 0, false);
      } else {
        this.avatarLegs[0].y = AVATAR_H / 2 - 6;
        this.avatarLegs[1].y = AVATAR_H / 2 - 6;
      }
    }
    this.avatar.setDepth(6 + this.avatar.y / 1000);

    this.updateNearestConsole();
  }

  private setFacing(dir: number): void {
    if (dir === this.facing) return;
    this.facing = dir;
    this.avatar.setScale(dir, 1);
  }

  private updateAvatarSprite(dx: number, dy: number, moving: boolean): void {
    if (!this.avatarSprite) return;
    if (moving) {
      this.avatarDirection = Math.abs(dx) > Math.abs(dy)
        ? dx > 0 ? "right" : "left"
        : dy > 0 ? "down" : "up";
      const walkKey = `eli-robot-girl-${this.avatarDirection}-walk`;
      if (this.avatarSprite.anims.currentAnim?.key !== walkKey || !this.avatarSprite.anims.isPlaying) {
        this.avatarSprite.play(walkKey);
      }
      return;
    }
    this.avatarSprite.stop();
    this.avatarSprite.setFrame(`${this.avatarDirection}_idle`);
  }

  private moveWithCollision(mx: number, my: number): void {
    // avatar "piedi": una box in basso, per collidere coi muri come uno spazio 2D
    const feetH = 26;
    const halfW = AVATAR_W / 2;
    const tryAxis = (nx: number, ny: number): boolean => {
      const box = { x: nx - halfW, y: ny + AVATAR_H / 2 - feetH, w: AVATAR_W, h: feetH };
      return !this.walls.some((w) => this.aabb(box, w));
    };
    const nextX = Phaser.Math.Clamp(this.avatar.x + mx, halfW + 6, WORLD_W - halfW - 6);
    if (tryAxis(nextX, this.avatar.y)) this.avatar.x = nextX;
    const nextY = Phaser.Math.Clamp(this.avatar.y + my, 30, WORLD_H - 20);
    if (tryAxis(this.avatar.x, nextY)) this.avatar.y = nextY;
  }

  private aabb(a: Wall, b: Wall): boolean {
    return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
  }

  private pointInConsole(px: number, py: number, spot: ConsoleSpot): boolean {
    return Math.abs(px - spot.x) < spot.w / 2 + 40 && Math.abs(py - spot.y) < spot.h / 2 + 40;
  }

  private updateNearestConsole(): void {
    let best: ConsoleSpot | undefined;
    let bestDist = Infinity;
    for (const spot of this.consoles) {
      const d = Math.hypot(spot.x - this.avatar.x, (spot.y + spot.h / 2) - this.avatar.y);
      if (d < 120 && d < bestDist) {
        bestDist = d;
        best = spot;
      }
    }
    if (best !== this.activeConsole) {
      this.consoles.forEach((s) => s.container?.setScale(1));
      this.activeConsole = best;
      if (best) best.container?.setScale(1.06);
    }
    if (best) {
      this.prompt.setVisible(true).setPosition(best.x, best.y - best.h / 2 - 34);
      this.promptText.setText(best.id === "door" ? "▶  Esci  ·  E / tocca" : `▶  ${best.label}  ·  E / tocca`);
    } else {
      this.prompt.setVisible(false);
    }
  }

  // --- interazione ---------------------------------------------------------

  private tryInteract(): void {
    if (this.overlayOpen || !this.activeConsole) return;
    const spot = this.activeConsole;
    audioManager.play("panelOpen");
    if (spot.id === "door") {
      this.scene.start(this.returnScene);
      return;
    }
    this.openConsole(spot);
  }

  /**
   * Demo: mostra un pannello placeholder. Nell'integrazione reale, qui si chiama
   * il callback che apre l'esercizio della console (lo stesso `openHotspot`).
   */
  private openConsole(spot: ConsoleSpot): void {
    this.overlayOpen = true;
    const cam = this.cameras.main;
    const cx = cam.midPoint.x;
    const cy = cam.midPoint.y;
    const panel = this.add.container(cx, cy).setDepth(100);
    panel.add(this.add.rectangle(0, 0, 1280, 720, 0x02070b, 0.72).setInteractive());
    panel.add(this.add.rectangle(0, 0, 620, 320, 0x07151d, 0.99).setStrokeStyle(3, spot.color, 0.9));
    panel.add(this.add.text(0, -110, `${spot.glyph}  ${spot.label}`, { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    panel.add(this.add.text(0, -50, "Anteprima interazione di prossimità.\nNella missione qui si aprirebbe l'esercizio di questa console.", {
      fontFamily: "Inter, Arial", fontSize: "16px", color: "#c7dce7", align: "center", lineSpacing: 6,
    }).setOrigin(0.5));
    const close = new Button(this, 0, 96, "Chiudi e torna nella stanza", () => {
      panel.destroy(true);
      this.overlayOpen = false;
      spot.done = true;
    }, { width: 320, height: 46, fill: 0x173b36 });
    panel.add(close);
  }
}
