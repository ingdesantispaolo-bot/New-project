import Phaser from "phaser";
import { drawAccessoryVisual, drawOutfitBack, drawOutfitFront, drawPetVisual } from "../../core/AvatarCosmeticVisuals";
import { rewardSystem } from "../../core/RewardSystem";
import type { GeneratedRoomHotspot } from "../../procedural/ProceduralTypes";

type ChromeRect = { x: number; y: number; width: number; height: number };
export type RoomConsolePoint = { hotspot: GeneratedRoomHotspot; x: number; y: number };
type Dir = "down" | "up" | "left" | "right";

const SPEED = 230; // px/s

/**
 * Avatar giocabile per la fase Esplora della missione: aggiunge AGENCY (cammini
 * con WASD/frecce e interagisci con E avvicinandoti a una console) SOPRA gli
 * hotspot cliccabili esistenti, che restano come fallback. Usa lo sprite reale
 * `eli-robot-girl` con ripiego a forme se l'atlante non è caricato.
 *
 * Footprint minimo nella scena missione: si crea in create() e si aggiorna da
 * un update(). L'interazione chiama lo stesso `onInteract` (= openHotspot).
 */
export class MissionRoomAvatar {
  /** Posizione persistita tra i restart della scena (per seed). */
  private static positions: Record<string, { x: number; y: number }> = {};

  private root: Phaser.GameObjects.Container;
  private sprite?: Phaser.GameObjects.Sprite;
  private cursors: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys: Record<string, Phaser.Input.Keyboard.Key>;
  private prompt: Phaser.GameObjects.Container;
  private promptText: Phaser.GameObjects.Text;
  private active?: RoomConsolePoint;
  private facing: Dir = "down";
  private paused = false;
  private readonly onE: () => void;

  constructor(
    private scene: Phaser.Scene,
    private stage: ChromeRect,
    private consoles: RoomConsolePoint[],
    private seedKey: string,
    private onInteract: (hotspot: GeneratedRoomHotspot) => void,
  ) {
    const saved = MissionRoomAvatar.positions[seedKey];
    const start = saved ?? { x: stage.x + stage.width / 2, y: stage.y + stage.height - 56 };
    this.root = this.buildAvatar(start.x, start.y);
    this.prompt = this.buildPrompt();
    this.promptText = this.prompt.getAt(1) as Phaser.GameObjects.Text;

    this.cursors = scene.input.keyboard!.createCursorKeys();
    this.keys = scene.input.keyboard!.addKeys("W,A,S,D") as Record<string, Phaser.Input.Keyboard.Key>;
    this.onE = () => this.tryInteract();
    scene.input.keyboard!.on("keydown-E", this.onE);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      scene.input.keyboard?.off("keydown-E", this.onE);
    });
  }

  private buildAvatar(x: number, y: number): Phaser.GameObjects.Container {
    const accent = rewardSystem.colorForSlot("avatar", 0x6be7d6);
    const outfit = rewardSystem.equipped("avatar");
    const accessory = rewardSystem.equipped("accessory");
    const pet = rewardSystem.equipped("pet");
    const c = this.scene.add.container(x, y).setDepth(60);
    c.add(this.scene.add.ellipse(0, 34, 40, 12, 0x000000, 0.34));
    drawPetVisual(this.scene, c, pet, -30, 24, 0.82);
    drawOutfitBack(this.scene, c, outfit, 0.72);
    if (this.scene.textures.exists("eli-robot-girl")) {
      this.ensureAnimations();
      this.sprite = this.scene.add.sprite(0, 0, "eli-robot-girl", "down_idle").setOrigin(0.5, 0.62).setScale(0.72).setTint(accent);
      c.add(this.sprite);
    } else {
      c.add(this.scene.add.rectangle(0, 0, 34, 40, 0x17475a, 1).setStrokeStyle(2, accent, 0.95));
      c.add(this.scene.add.circle(0, -22, 12, 0x1b5468, 1).setStrokeStyle(2, accent, 0.95));
      c.add(this.scene.add.circle(4, -22, 2.4, 0x8ff6ea, 1));
    }
    drawOutfitFront(this.scene, c, outfit, 0.72);
    drawAccessoryVisual(this.scene, c, accessory, 0.72);
    return c;
  }

  private ensureAnimations(): void {
    (["down", "up", "left", "right"] as Dir[]).forEach((dir) => {
      const key = `mrav-${dir}`;
      if (this.scene.anims.exists(key)) return;
      this.scene.anims.create({
        key,
        frames: [1, 2, 3, 4].map((i) => ({ key: "eli-robot-girl", frame: `${dir}_walk${i}` })),
        frameRate: 8,
        repeat: -1,
      });
    });
  }

  private buildPrompt(): Phaser.GameObjects.Container {
    const c = this.scene.add.container(0, 0).setDepth(70).setVisible(false);
    c.add(this.scene.add.rectangle(0, 0, 190, 34, 0x061019, 0.96).setStrokeStyle(2, 0xf6c85f, 0.95));
    c.add(this.scene.add.text(0, 0, "", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    this.scene.tweens.add({ targets: c, y: "-=5", duration: 700, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    return c;
  }

  /** Called from the scene's update loop. `paused` is true while an overlay is open. */
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
    const moving = dx !== 0 || dy !== 0;
    if (moving) {
      const len = Math.hypot(dx, dy) || 1;
      const step = SPEED * dt;
      const m = 20;
      this.root.x = Phaser.Math.Clamp(this.root.x + (dx / len) * step, this.stage.x + m, this.stage.x + this.stage.width - m);
      this.root.y = Phaser.Math.Clamp(this.root.y + (dy / len) * step, this.stage.y + m, this.stage.y + this.stage.height - m);
      this.setDirection(dx, dy);
      this.sprite?.anims.play(`mrav-${this.facing}`, true);
      MissionRoomAvatar.positions[this.seedKey] = { x: this.root.x, y: this.root.y };
    } else {
      this.sprite?.anims.stop();
      this.sprite?.setFrame(`${this.facing}_idle`);
    }
    this.updateProximity();
  }

  private setDirection(dx: number, dy: number): void {
    if (Math.abs(dx) > Math.abs(dy)) this.facing = dx > 0 ? "right" : "left";
    else this.facing = dy > 0 ? "down" : "up";
  }

  private updateProximity(): void {
    let best: RoomConsolePoint | undefined;
    let bestDist = Infinity;
    for (const spot of this.consoles) {
      const d = Math.hypot(spot.x - this.root.x, spot.y - this.root.y);
      if (d < 84 && d < bestDist) {
        bestDist = d;
        best = spot;
      }
    }
    this.active = best;
    if (best) {
      const isDoor = (best.hotspot.puzzleId ?? best.hotspot.id) === "door";
      this.prompt.setVisible(true).setPosition(best.x, best.y - 70);
      this.promptText.setText(isDoor ? "▶  Uscita  ·  E" : `▶  ${best.hotspot.label}  ·  E`);
    } else {
      this.prompt.setVisible(false);
    }
  }

  private tryInteract(): void {
    if (this.paused || !this.active) return;
    this.onInteract(this.active.hotspot);
  }
}
