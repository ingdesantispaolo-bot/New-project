import Phaser from "phaser";
import { drawAccessoryVisual, drawOutfitBack, drawOutfitFront, drawPetVisual } from "../core/AvatarCosmeticVisuals";
import { audioManager } from "../core/AudioManager";
import { feedbackSystem } from "../core/FeedbackSystem";
import { rewardSystem, type Cosmetic } from "../core/RewardSystem";
import { saveSystem } from "../core/SaveSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { generateOutdoorAdventureMap, type OutdoorAdventureMap, type OutdoorBiome, type OutdoorEncounter, type OutdoorEncounterKind, type OutdoorObstacle, type OutdoorProp } from "../procedural/OutdoorAdventureGenerator";
import { Button } from "../ui/Button";

type Dir = "down" | "up" | "left" | "right";

type CombatQuestion = {
  prompt: string;
  options: string[];
  correct: string;
  explanation: string;
  subject: string;
};

const BIOME_LABELS: Record<OutdoorBiome, string> = {
  academy: "Radura Accademia",
  ruins: "Rovine",
  geo: "Geografia",
  logic: "Logica",
};

export class OutdoorAdventureScene extends Phaser.Scene {
  private map!: OutdoorAdventureMap;
  private avatar!: Phaser.GameObjects.Container;
  private avatarSprite?: Phaser.GameObjects.Sprite;
  private petCompanion?: Phaser.GameObjects.Container;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private facing: Dir = "down";
  private paused = false;
  private completed = new Set<string>();
  private encounterNodes = new Map<string, Phaser.GameObjects.Container>();
  private prompt!: Phaser.GameObjects.Container;
  private promptText!: Phaser.GameObjects.Text;
  private activeEncounter?: OutdoorEncounter;
  private readonly onE = (): void => this.tryInteract();

  constructor() {
    super("OutdoorAdventureScene");
  }

  create(): void {
    const daySeed = new Date().toISOString().slice(0, 10);
    this.map = generateOutdoorAdventureMap(`outdoor-${daySeed}-${rewardSystem.playerLevel()}`);
    this.cameras.main.setBounds(0, 0, this.map.width, this.map.height);
    this.cameras.main.setBackgroundColor("#071018");
    this.drawWorld();
    this.buildAvatar();
    this.buildPrompt();
    this.drawHud();
    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D") as Record<string, Phaser.Input.Keyboard.Key>;
    this.input.keyboard!.on("keydown-E", this.onE);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.input.keyboard?.off("keydown-E", this.onE));
    this.cameras.main.startFollow(this.avatar, true, 0.12, 0.12);
    audioManager.play("missionStart");
  }

  update(_: number, delta: number): void {
    if (this.paused) return;
    this.updateMovement(delta / 1000);
    this.updatePet();
    this.updatePrompt();
  }

  private drawWorld(): void {
    const g = this.add.graphics();
    g.fillStyle(0x071018, 1);
    g.fillRect(0, 0, this.map.width, this.map.height);
    for (let x = 0; x < this.map.width; x += 96) {
      for (let y = 0; y < this.map.height; y += 96) {
        const tint = (x / 96 + y / 96) % 2 === 0 ? 0x0a1820 : 0x08131b;
        g.fillStyle(tint, 0.75);
        g.fillRect(x, y, 96, 96);
      }
    }
    this.map.patches.forEach((patch) => {
      g.fillStyle(patch.color, 0.74);
      g.fillRoundedRect(patch.x, patch.y, patch.w, patch.h, 52);
      g.lineStyle(3, patch.accent, 0.32);
      g.strokeRoundedRect(patch.x, patch.y, patch.w, patch.h, 52);
      this.add.text(patch.x + 34, patch.y + 28, patch.label, {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setAlpha(0.76);
    });
    this.drawPaths(g);
    this.map.props.forEach((prop) => this.drawProp(prop));
    this.map.obstacles.forEach((obstacle) => this.drawObstacle(obstacle));
    this.map.encounters.forEach((encounter) => this.drawEncounter(encounter));
  }

  private drawPaths(g: Phaser.GameObjects.Graphics): void {
    const points = [
      this.map.start,
      { x: 790, y: 760 },
      { x: 1120, y: 560 },
      { x: 1540, y: 400 },
      { x: 1680, y: 1030 },
      { x: 1110, y: 1010 },
      { x: 790, y: 760 },
    ];
    g.lineStyle(42, 0x132a33, 0.72);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y, points[i + 1]!.x, points[i + 1]!.y);
    g.lineStyle(4, 0xf6c85f, 0.18);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y, points[i + 1]!.x, points[i + 1]!.y);
  }

  private drawProp(prop: OutdoorProp): void {
    const c = this.add.container(prop.x, prop.y).setDepth(2 + prop.y / 10000);
    if (prop.kind === "river") {
      c.add(this.add.ellipse(0, 0, 132, 34, 0x145f78, 0.72).setStrokeStyle(2, 0x7ad7ff, 0.48));
      return;
    }
    if (prop.kind === "tower") {
      c.add(this.add.rectangle(0, -18, 42, 72, 0x211927, 0.94).setStrokeStyle(2, prop.color, 0.7));
      c.add(this.add.triangle(0, -66, -30, -34, 30, -34, 0x39273b, 0.94).setStrokeStyle(2, prop.color, 0.6));
      return;
    }
    if (prop.kind === "camp") {
      c.add(this.add.triangle(0, -18, -28, 34, 28, 34, 0x173b36, 0.9).setStrokeStyle(2, prop.color, 0.7));
      c.add(this.add.circle(0, 38, 8, 0xf6c85f, 0.9));
      return;
    }
    if (prop.kind === "lamp") {
      c.add(this.add.rectangle(0, 0, 8, 58, 0x273844, 0.9));
      c.add(this.add.circle(0, -34, 14, prop.color, 0.28).setStrokeStyle(2, prop.color, 0.72));
      return;
    }
    c.add(this.add.rectangle(0, 0, 58, 34, 0x0c1d2a, 0.94).setStrokeStyle(2, prop.color, 0.74));
    c.add(this.add.text(0, 0, "?", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
  }

  private drawObstacle(obstacle: OutdoorObstacle): void {
    const c = this.add.container(obstacle.x, obstacle.y).setDepth(3 + obstacle.y / 10000);
    if (obstacle.kind === "tree") {
      c.add(this.add.rectangle(0, obstacle.r * 0.45, obstacle.r * 0.5, obstacle.r, 0x4a321d, 1));
      c.add(this.add.circle(0, -obstacle.r * 0.25, obstacle.r, obstacle.color, 0.94).setStrokeStyle(2, 0x8fe0a4, 0.36));
      return;
    }
    if (obstacle.kind === "crystal") {
      c.add(this.add.triangle(0, 0, -obstacle.r, obstacle.r, 0, -obstacle.r * 1.35, obstacle.r, obstacle.r, obstacle.color, 0.88).setStrokeStyle(2, 0x9ff5e9, 0.58));
      return;
    }
    if (obstacle.kind === "ruin") {
      c.add(this.add.rectangle(0, 0, obstacle.r * 1.6, obstacle.r * 1.1, obstacle.color, 0.92).setStrokeStyle(2, 0xff8f6b, 0.38));
      c.add(this.add.rectangle(-obstacle.r * 0.35, -obstacle.r * 0.8, obstacle.r * 0.46, obstacle.r * 0.9, obstacle.color, 0.8));
      return;
    }
    c.add(this.add.ellipse(0, 0, obstacle.r * 1.7, obstacle.r * 1.25, obstacle.color, 0.96).setStrokeStyle(2, 0xdde9ef, 0.18));
  }

  private drawEncounter(encounter: OutdoorEncounter): void {
    const patch = this.map.patches.find((candidate) => candidate.id === encounter.biome);
    const accent = patch?.accent ?? 0x6be7d6;
    const c = this.add.container(encounter.x, encounter.y).setDepth(8 + encounter.y / 10000);
    c.add(this.add.circle(0, 0, encounter.kind === "guardian" ? 34 : 25, 0x061019, 0.94).setStrokeStyle(3, accent, 0.9));
    c.add(this.add.circle(0, 0, encounter.kind === "guardian" ? 17 : 11, accent, 0.78));
    c.add(this.add.text(0, 48, encounter.label, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 142 },
    }).setOrigin(0.5, 0));
    const hit = this.add.circle(0, 0, 48, 0x000000, 0.001).setInteractive({ useHandCursor: true });
    hit.on("pointerup", () => this.startEncounter(encounter));
    c.add(hit);
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: c, y: encounter.y - 8, duration: 1400 + encounter.difficulty * 120, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
    this.encounterNodes.set(encounter.id, c);
  }

  private buildAvatar(): void {
    const outfit = rewardSystem.equipped("avatar");
    const accessory = rewardSystem.equipped("accessory");
    const pet = rewardSystem.equipped("pet");
    const color = rewardSystem.colorForSlot("avatar", 0x6be7d6);
    this.avatar = this.add.container(this.map.start.x, this.map.start.y).setDepth(20);
    this.avatar.add(this.add.ellipse(0, 38, 52, 16, 0x000000, 0.35));
    drawOutfitBack(this, this.avatar, outfit, 0.92);
    if (this.textures.exists("eli-robot-girl")) {
      this.ensureAnimations();
      this.avatarSprite = this.add.sprite(0, 0, "eli-robot-girl", "down_idle").setOrigin(0.5, 0.55).setTint(color);
      this.avatar.add(this.avatarSprite);
    } else {
      this.avatar.add(this.add.rectangle(0, 2, 46, 54, 0x17475a, 1).setStrokeStyle(3, color, 0.95));
      this.avatar.add(this.add.circle(0, -36, 18, 0x1b5468, 1).setStrokeStyle(3, color, 0.95));
    }
    drawOutfitFront(this, this.avatar, outfit, 0.92);
    drawAccessoryVisual(this, this.avatar, accessory, 0.92);
    const petRoot = this.add.container(0, 0).setDepth(19);
    this.petCompanion = drawPetVisual(this, petRoot, pet, this.map.start.x - 48, this.map.start.y + 20, 1.05, false);
  }

  private ensureAnimations(): void {
    (["down", "up", "left", "right"] as Dir[]).forEach((dir) => {
      const key = `outdoor-${dir}`;
      if (this.anims.exists(key)) return;
      this.anims.create({
        key,
        frames: [1, 2, 3, 4].map((i) => ({ key: "eli-robot-girl", frame: `${dir}_walk${i}` })),
        frameRate: 8,
        repeat: -1,
      });
    });
  }

  private buildPrompt(): void {
    this.prompt = this.add.container(0, 0).setDepth(60).setVisible(false);
    this.prompt.add(this.add.rectangle(0, 0, 252, 38, 0x061019, 0.96).setStrokeStyle(2, 0xf6c85f, 0.92));
    this.promptText = this.add.text(0, 0, "", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5);
    this.prompt.add(this.promptText);
  }

  private drawHud(): void {
    const hud = this.add.container(0, 0).setDepth(120).setScrollFactor(0);
    hud.add(this.add.rectangle(18, 16, 360, 78, 0x061019, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.42));
    hud.add(this.add.text(36, 28, "Mappa Esterna", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    hud.add(this.add.text(36, 58, "Esplora, sfida i guardiani, usa equip e pet.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
    }));
    hud.add(this.add.text(1040, 24, `${rewardSystem.energy()} ⚡`, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(1, 0));
    new Button(this, 1170, 48, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 128,
      height: 42,
      fontSize: 14,
      fill: 0x263743,
    }).setScrollFactor(0).setDepth(130);
  }

  private updateMovement(dt: number): void {
    let dx = (this.cursors.right.isDown || this.keys.D.isDown ? 1 : 0) - (this.cursors.left.isDown || this.keys.A.isDown ? 1 : 0);
    let dy = (this.cursors.down.isDown || this.keys.S.isDown ? 1 : 0) - (this.cursors.up.isDown || this.keys.W.isDown ? 1 : 0);
    const moving = dx !== 0 || dy !== 0;
    if (!moving) {
      this.avatarSprite?.anims.stop();
      this.avatarSprite?.setFrame(`${this.facing}_idle`);
      return;
    }
    const len = Math.hypot(dx, dy) || 1;
    dx /= len;
    dy /= len;
    const speed = rewardSystem.equippedId("accessory") === "accessory-jetpack" ? 300 : 260;
    const nx = Phaser.Math.Clamp(this.avatar.x + dx * speed * dt, 42, this.map.width - 42);
    const ny = Phaser.Math.Clamp(this.avatar.y + dy * speed * dt, 54, this.map.height - 54);
    if (this.isWalkable(nx, this.avatar.y)) this.avatar.x = nx;
    if (this.isWalkable(this.avatar.x, ny)) this.avatar.y = ny;
    this.avatar.setDepth(20 + this.avatar.y / 10000);
    this.facing = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "right" : "left") : (dy > 0 ? "down" : "up");
    this.avatarSprite?.anims.play(`outdoor-${this.facing}`, true);
  }

  private isWalkable(x: number, y: number): boolean {
    return !this.map.obstacles.some((obstacle) => Math.hypot(obstacle.x - x, obstacle.y - y) < obstacle.r + 26);
  }

  private updatePet(): void {
    if (!this.petCompanion) return;
    const targetX = this.avatar.x - (this.facing === "left" ? -48 : 48);
    const targetY = this.avatar.y + 18 + Math.sin(this.time.now / 360) * 7;
    this.petCompanion.x = Phaser.Math.Linear(this.petCompanion.x, targetX, 0.07);
    this.petCompanion.y = Phaser.Math.Linear(this.petCompanion.y, targetY, 0.07);
    this.petCompanion.setDepth(19 + this.petCompanion.y / 10000);
  }

  private updatePrompt(): void {
    let nearest: OutdoorEncounter | undefined;
    let best = Infinity;
    for (const encounter of this.map.encounters) {
      if (this.completed.has(encounter.id)) continue;
      const distance = Math.hypot(encounter.x - this.avatar.x, encounter.y - this.avatar.y);
      if (distance < 92 && distance < best) {
        nearest = encounter;
        best = distance;
      }
    }
    this.activeEncounter = nearest;
    if (!nearest) {
      this.prompt.setVisible(false);
      return;
    }
    this.prompt.setPosition(nearest.x, nearest.y - 72).setVisible(true);
    this.promptText.setText(`E / clicca · ${nearest.enemy}`);
  }

  private tryInteract(): void {
    if (this.paused || !this.activeEncounter) return;
    this.startEncounter(this.activeEncounter);
  }

  private startEncounter(encounter: OutdoorEncounter): void {
    if (this.paused || this.completed.has(encounter.id)) return;
    this.paused = true;
    this.prompt.setVisible(false);
    audioManager.play("missionStart");
    this.runCombat(encounter);
  }

  private runCombat(encounter: OutdoorEncounter): void {
    const overlay = this.add.container(0, 0).setDepth(2000).setScrollFactor(0);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.88).setInteractive());
    overlay.add(this.add.rectangle(640, 360, 780, 560, 0x07151d, 0.98).setStrokeStyle(2, this.biomeAccent(encounter.biome), 0.82));
    overlay.add(this.add.text(640, 116, encounter.enemy, {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(640, 154, `${BIOME_LABELS[encounter.biome]} · ${encounter.label}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9fb6c2",
    }).setOrigin(0.5));
    const arena = this.add.container(0, 0);
    overlay.add(arena);
    this.drawCombatAvatar(arena, 360, 266);
    this.drawEnemy(arena, encounter, 920, 266);

    let round = 0;
    let correct = 0;
    let playerShield = 3;
    let enemyShield = encounter.kind === "guardian" ? 4 : 3;
    const panel = this.add.container(0, 0);
    overlay.add(panel);
    const renderRound = (): void => {
      panel.removeAll(true);
      if (round >= 3 || playerShield <= 0 || enemyShield <= 0) {
        this.finishCombat(overlay, encounter, correct, enemyShield <= 0 || correct >= 2);
        return;
      }
      const question = this.questionFor(encounter.kind, encounter.difficulty + round);
      panel.add(this.add.text(640, 346, `Scudo ${playerShield} · Guardiano ${enemyShield} · Colpo ${round + 1}/3`, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f6c85f",
        fontStyle: "bold",
      }).setOrigin(0.5));
      panel.add(this.add.text(640, 384, question.prompt, {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: "#f5fbff",
        fontStyle: "bold",
        align: "center",
        wordWrap: { width: 680 },
      }).setOrigin(0.5));
      question.options.forEach((option, index) => {
        const x = 430 + (index % 2) * 420;
        const y = 470 + Math.floor(index / 2) * 66;
        panel.add(new Button(this, x, y, option, () => {
          if (option === question.correct) {
            correct += 1;
            enemyShield -= 1 + (rewardSystem.equippedId("emblem") === "emblem-bolt" ? 1 : 0);
            audioManager.play("success");
            this.flashStrike(arena, 360, 266, 920, 266, 0xf6c85f);
          } else {
            playerShield -= 1;
            audioManager.play("error");
            feedbackSystem.publish(question.explanation, "hint");
            this.flashStrike(arena, 920, 266, 360, 266, 0xff6b7a);
          }
          round += 1;
          this.time.delayedCall(360, renderRound);
        }, { width: 330, height: 48, fontSize: 14, fill: 0x173b36, stroke: this.biomeAccent(encounter.biome) }));
      });
    };
    renderRound();
  }

  private finishCombat(overlay: Phaser.GameObjects.Container, encounter: OutdoorEncounter, correct: number, victory: boolean): void {
    const reward = Math.max(6, (victory ? encounter.reward : 8) + correct * 10);
    const varietyBonuses = saveSystem.recordDailyEnergySubject(`Avventura ${this.subjectFor(encounter.kind)}`);
    const bonus = varietyBonuses.reduce((sum, item) => sum + item.amount, 0);
    saveSystem.addEnergy(reward + bonus);
    this.completed.add(encounter.id);
    this.markEncounterDone(encounter);
    overlay.removeAll(true);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
    overlay.add(this.add.rectangle(640, 360, 560, 360, 0x07151d, 0.98).setStrokeStyle(2, victory ? 0x2ed889 : 0xf6c85f, 0.9));
    overlay.add(this.add.text(640, 260, victory ? "Guardiano superato" : "Ritirata strategica", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: victory ? "#8ff6c0" : "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(640, 316, `${correct}/3 colpi precisi · +${reward + bonus} energia`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (bonus > 0) {
      overlay.add(this.add.text(640, 350, varietyBonuses.map((item) => `+${item.amount} ${item.label}`).join(" · "), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9ff5e9",
        align: "center",
        wordWrap: { width: 440 },
      }).setOrigin(0.5));
    }
    overlay.add(new Button(this, 640, 436, "Torna alla mappa", () => {
      overlay.destroy(true);
      this.paused = false;
      feedbackSystem.publish(`Energia avventura guadagnata: +${reward + bonus}`, "success");
    }, { width: 220, height: 46, fontSize: 15, fill: 0x173b36, stroke: victory ? 0x2ed889 : 0xf6c85f }));
  }

  private drawCombatAvatar(parent: Phaser.GameObjects.Container, x: number, y: number): void {
    const c = this.add.container(x, y);
    const outfit = rewardSystem.equipped("avatar");
    const accessory = rewardSystem.equipped("accessory");
    const color = rewardSystem.colorForSlot("avatar", 0x6be7d6);
    c.add(this.add.ellipse(0, 54, 112, 22, 0x000000, 0.32));
    drawOutfitBack(this, c, outfit, 1.55, 12);
    if (this.textures.exists("eli-robot-girl")) {
      c.add(this.add.sprite(0, 12, "eli-robot-girl", "right_idle").setOrigin(0.5, 0.56).setScale(1.55).setTint(color));
    }
    drawOutfitFront(this, c, outfit, 1.55, 12);
    drawAccessoryVisual(this, c, accessory, 1.55, 12);
    drawPetVisual(this, c, rewardSystem.equipped("pet"), -88, 36, 1.35, !settingsSystem.effectsReduced());
    parent.add(c);
  }

  private drawEnemy(parent: Phaser.GameObjects.Container, encounter: OutdoorEncounter, x: number, y: number): void {
    const accent = this.biomeAccent(encounter.biome);
    const c = this.add.container(x, y);
    c.add(this.add.ellipse(0, 58, 126, 24, 0x000000, 0.3));
    c.add(this.add.circle(0, 0, encounter.kind === "guardian" ? 58 : 46, 0x061019, 0.98).setStrokeStyle(4, accent, 0.92));
    c.add(this.add.circle(-16, -8, 6, accent, 0.95));
    c.add(this.add.circle(16, -8, 6, accent, 0.95));
    c.add(this.add.rectangle(0, 20, 46, 8, accent, 0.75));
    c.add(this.add.text(0, 82, encounter.enemy, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    parent.add(c);
  }

  private flashStrike(parent: Phaser.GameObjects.Container, fromX: number, fromY: number, toX: number, toY: number, color: number): void {
    const line = this.add.line(0, 0, fromX, fromY, toX, toY, color, 0.95).setOrigin(0);
    parent.add(line);
    this.tweens.add({ targets: line, alpha: 0, duration: 280, onComplete: () => line.destroy() });
  }

  private markEncounterDone(encounter: OutdoorEncounter): void {
    const node = this.encounterNodes.get(encounter.id);
    if (!node) return;
    node.setAlpha(0.32);
    node.disableInteractive();
  }

  private biomeAccent(biome: OutdoorBiome): number {
    return this.map.patches.find((patch) => patch.id === biome)?.accent ?? 0x6be7d6;
  }

  private subjectFor(kind: OutdoorEncounterKind): string {
    if (kind === "times") return "tabelline";
    if (kind === "mental") return "calcolo";
    if (kind === "capital") return "geografia";
    if (kind === "physicalGeo") return "geografia fisica";
    return "guardiano";
  }

  private questionFor(kind: OutdoorEncounterKind, difficulty: number): CombatQuestion {
    const effective = kind === "guardian" ? Phaser.Math.RND.pick(["times", "mental", "capital", "physicalGeo"] as OutdoorEncounterKind[]) : kind;
    if (effective === "times") return this.timesQuestion(difficulty);
    if (effective === "mental") return this.mentalQuestion(difficulty);
    if (effective === "capital") return this.capitalQuestion();
    return this.physicalGeoQuestion();
  }

  private timesQuestion(difficulty: number): CombatQuestion {
    const max = Phaser.Math.Clamp(7 + difficulty * 2, 8, 12);
    const a = Phaser.Math.Between(2, max);
    const b = Phaser.Math.Between(2, max);
    return this.numericQuestion(`Quanto fa ${a} × ${b}?`, a * b, "Moltiplica una riga per volta: se serve scomponi uno dei due fattori.", "tabelline");
  }

  private mentalQuestion(difficulty: number): CombatQuestion {
    const a = Phaser.Math.Between(18, 45 + difficulty * 8);
    const b = Phaser.Math.Between(6, 24 + difficulty * 4);
    const c = Phaser.Math.Between(2, 9);
    const answer = a + b - c;
    return this.numericQuestion(`Calcolo mentale: ${a} + ${b} - ${c}`, answer, "Somma prima i blocchi facili, poi togli l'ultimo numero.", "calcolo mentale");
  }

  private numericQuestion(prompt: string, answer: number, explanation: string, subject: string): CombatQuestion {
    const options = [answer, answer + Phaser.Math.Between(2, 7), Math.max(0, answer - Phaser.Math.Between(2, 7)), answer + Phaser.Math.Between(8, 14)]
      .map(String)
      .filter((value, index, arr) => arr.indexOf(value) === index);
    while (options.length < 4) options.push(String(answer + Phaser.Math.Between(15, 24)));
    return { prompt, options: Phaser.Utils.Array.Shuffle(options), correct: String(answer), explanation, subject };
  }

  private capitalQuestion(): CombatQuestion {
    const data = Phaser.Math.RND.pick([
      ["Francia", "Parigi", "Europa"],
      ["Spagna", "Madrid", "Europa"],
      ["Egitto", "Il Cairo", "Africa"],
      ["Giappone", "Tokyo", "Asia"],
      ["Brasile", "Brasilia", "America del Sud"],
      ["Canada", "Ottawa", "America del Nord"],
      ["Australia", "Canberra", "Oceania"],
    ]);
    const askContinent = Phaser.Math.Between(0, 1) === 1;
    if (askContinent) {
      const options = Phaser.Utils.Array.Shuffle(["Europa", "Africa", "Asia", "America del Nord", "America del Sud", "Oceania"]).slice(0, 4);
      if (!options.includes(data[2])) options[0] = data[2];
      return { prompt: `In quale continente si trova ${data[0]}?`, options: Phaser.Utils.Array.Shuffle(options), correct: data[2], explanation: "Prima localizza lo Stato sulla mappa mentale, poi scegli il continente.", subject: "geografia" };
    }
    const options = Phaser.Utils.Array.Shuffle(["Parigi", "Madrid", "Il Cairo", "Tokyo", "Brasilia", "Ottawa", "Canberra"]).slice(0, 4);
    if (!options.includes(data[1])) options[0] = data[1];
    return { prompt: `Qual è la capitale di ${data[0]}?`, options: Phaser.Utils.Array.Shuffle(options), correct: data[1], explanation: "Capitale e Stato formano una coppia: cerca quella stabile, non la città più famosa a caso.", subject: "geografia" };
  }

  private physicalGeoQuestion(): CombatQuestion {
    const data = Phaser.Math.RND.pick([
      ["Nilo", "fiume", "Il Nilo è un fiume."],
      ["Himalaya", "catena montuosa", "L'Himalaya è una catena montuosa."],
      ["Mediterraneo", "mare", "Il Mediterraneo è un mare."],
      ["Sahara", "deserto", "Il Sahara è un deserto."],
      ["Vittoria", "lago", "Il Lago Vittoria è un lago."],
      ["Ande", "catena montuosa", "Le Ande sono una catena montuosa."],
    ]);
    const options = Phaser.Utils.Array.Shuffle(["fiume", "lago", "mare", "deserto", "catena montuosa"]).slice(0, 4);
    if (!options.includes(data[1])) options[0] = data[1];
    return { prompt: `Che elemento geografico è ${data[0]}?`, options: Phaser.Utils.Array.Shuffle(options), correct: data[1], explanation: data[2], subject: "geografia fisica" };
  }
}
