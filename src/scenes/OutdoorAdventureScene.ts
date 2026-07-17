import Phaser from "phaser";
import { drawAccessoryVisual, drawOutfitBack, drawOutfitFront, drawPetVisual } from "../core/AvatarCosmeticVisuals";
import { audioManager } from "../core/AudioManager";
import { feedbackSystem } from "../core/FeedbackSystem";
import { rewardSystem, type Cosmetic } from "../core/RewardSystem";
import { saveSystem } from "../core/SaveSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { type OutdoorAdventureMap, type OutdoorBiome, type OutdoorEncounter, type OutdoorEncounterKind, type OutdoorLandmark, type OutdoorObstacle, type OutdoorProp, type OutdoorTreasure } from "../procedural/OutdoorAdventureGenerator";
import { generateOutdoorChunk, OUTDOOR_CHUNK_SIZE, type OutdoorChunk } from "../procedural/OutdoorChunkGenerator";
import { Button } from "../ui/Button";

type Dir = "down" | "up" | "left" | "right";

type CombatQuestion = {
  prompt: string;
  options: string[];
  correct: string;
  explanation: string;
  subject: string;
};

type OutdoorBounty = {
  id: string;
  title: string;
  description: string;
  current: number;
  target: number;
  energy: number;
  fragments: number;
};

const BIOME_LABELS: Record<OutdoorBiome, string> = {
  academy: "Radura Accademia",
  ruins: "Rovine",
  geo: "Geografia",
  logic: "Logica",
  wild: "Bosco variabile",
  crystal: "Nido cristallino",
};

const BIOME_ACCENTS: Record<OutdoorBiome, number> = {
  academy: 0x6be7d6,
  ruins: 0xff8f6b,
  geo: 0x8fe0a4,
  logic: 0x9f8cff,
  wild: 0x74f0c5,
  crystal: 0xc7b8ff,
};

const FORGE_REWARDS: Array<{ id: string; fragmentCost: number; guardianWins?: number }> = [
  { id: "accessory-halo", fragmentCost: 45 },
  { id: "avatar-shadow", fragmentCost: 80, guardianWins: 1 },
  { id: "pet-luma", fragmentCost: 110, guardianWins: 1 },
  { id: "avatar-astral", fragmentCost: 145, guardianWins: 2 },
  { id: "pet-codex", fragmentCost: 190, guardianWins: 3 },
];

const STREAM_RADIUS = 2;
const VIRTUAL_WORLD_LIMIT = OUTDOOR_CHUNK_SIZE * 512;
const DAILY_ROUTE_TARGET = 12;

type ActiveOutdoorChunk = {
  chunk: OutdoorChunk;
  objects: Phaser.GameObjects.GameObject[];
};

export class OutdoorAdventureScene extends Phaser.Scene {
  private map!: OutdoorAdventureMap;
  private worldSeed = "";
  private avatar!: Phaser.GameObjects.Container;
  private avatarSprite?: Phaser.GameObjects.Sprite;
  private petCompanion?: Phaser.GameObjects.Container;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private facing: Dir = "down";
  private paused = false;
  private completed = new Set<string>();
  private collectedTreasures = new Set<string>();
  private activeChunks = new Map<string, ActiveOutdoorChunk>();
  private currentChunkId = "";
  private encounterNodes = new Map<string, Phaser.GameObjects.Container>();
  private treasureNodes = new Map<string, Phaser.GameObjects.Container>();
  private prompt!: Phaser.GameObjects.Container;
  private promptText!: Phaser.GameObjects.Text;
  private activeEncounter?: OutdoorEncounter;
  private activeTreasure?: OutdoorTreasure;
  private energyText?: Phaser.GameObjects.Text;
  private progressText?: Phaser.GameObjects.Text;
  private fragmentText?: Phaser.GameObjects.Text;
  private readonly onE = (): void => this.tryInteract();

  constructor() {
    super("OutdoorAdventureScene");
  }

  create(): void {
    saveSystem.load();
    const daySeed = new Date().toISOString().slice(0, 10);
    this.worldSeed = `outdoor-${daySeed}-${rewardSystem.playerLevel()}`;
    this.map = this.emptyOutdoorMap();
    this.completed = new Set(saveSystem.outdoorAdventure.completedEncounterIds);
    this.collectedTreasures = new Set(saveSystem.outdoorAdventure.collectedTreasureIds ?? []);
    this.cameras.main.setBounds(-VIRTUAL_WORLD_LIMIT, -VIRTUAL_WORLD_LIMIT, VIRTUAL_WORLD_LIMIT * 2, VIRTUAL_WORLD_LIMIT * 2);
    this.cameras.main.setBackgroundColor("#071018");
    this.syncOutdoorChunks(true);
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
    this.syncOutdoorChunks();
    this.updatePet();
    this.updatePrompt();
  }

  private emptyOutdoorMap(): OutdoorAdventureMap {
    return {
      seed: this.worldSeed,
      width: VIRTUAL_WORLD_LIMIT * 2,
      height: VIRTUAL_WORLD_LIMIT * 2,
      start: { x: OUTDOOR_CHUNK_SIZE / 2, y: OUTDOOR_CHUNK_SIZE / 2 },
      patches: [],
      obstacles: [],
      props: [],
      landmarks: [],
      treasures: [],
      encounters: [],
      pathPoints: [],
    };
  }

  private chunkId(chunkX: number, chunkY: number): string {
    return `${chunkX},${chunkY}`;
  }

  private syncOutdoorChunks(force = false): void {
    const origin = this.avatar ? { x: this.avatar.x, y: this.avatar.y } : this.map.start;
    const chunkX = Math.floor(origin.x / OUTDOOR_CHUNK_SIZE);
    const chunkY = Math.floor(origin.y / OUTDOOR_CHUNK_SIZE);
    const centerId = this.chunkId(chunkX, chunkY);
    if (!force && centerId === this.currentChunkId) return;
    this.currentChunkId = centerId;

    const wanted = new Set<string>();
    for (let y = chunkY - STREAM_RADIUS; y <= chunkY + STREAM_RADIUS; y += 1) {
      for (let x = chunkX - STREAM_RADIUS; x <= chunkX + STREAM_RADIUS; x += 1) {
        wanted.add(this.chunkId(x, y));
        if (!this.activeChunks.has(this.chunkId(x, y))) {
          const chunk = generateOutdoorChunk(this.worldSeed, x, y);
          const objects = this.drawChunk(chunk);
          this.activeChunks.set(this.chunkId(x, y), { chunk, objects });
        }
      }
    }

    for (const [id, active] of this.activeChunks.entries()) {
      if (wanted.has(id)) continue;
      active.chunk.encounters.forEach((encounter) => this.encounterNodes.delete(encounter.id));
      active.chunk.treasures.forEach((treasure) => this.treasureNodes.delete(treasure.id));
      if (active.chunk.encounters.some((encounter) => encounter.id === this.activeEncounter?.id)) this.activeEncounter = undefined;
      if (active.chunk.treasures.some((treasure) => treasure.id === this.activeTreasure?.id)) this.activeTreasure = undefined;
      active.objects.forEach((object) => {
        this.tweens.killTweensOf(object);
        object.destroy();
      });
      this.activeChunks.delete(id);
    }

    this.rebuildActiveMap();
    this.refreshHud();
  }

  private rebuildActiveMap(): void {
    const chunks = [...this.activeChunks.values()].map((active) => active.chunk);
    this.map = {
      ...this.emptyOutdoorMap(),
      patches: chunks.map((chunk) => chunk.patch),
      obstacles: chunks.flatMap((chunk) => chunk.obstacles).filter((obstacle) => Math.hypot(obstacle.x - this.map.start.x, obstacle.y - this.map.start.y) > 170),
      props: chunks.flatMap((chunk) => chunk.props),
      landmarks: chunks.flatMap((chunk) => chunk.landmarks),
      treasures: chunks.flatMap((chunk) => chunk.treasures),
      encounters: chunks.flatMap((chunk) => chunk.encounters),
      pathPoints: chunks.flatMap((chunk) => chunk.pathPoints),
    };
  }

  private drawChunk(chunk: OutdoorChunk): Phaser.GameObjects.GameObject[] {
    const objects: Phaser.GameObjects.GameObject[] = [];
    const g = this.add.graphics();
    objects.push(g);
    g.fillStyle(0x071018, 1);
    g.fillRect(chunk.worldX, chunk.worldY, chunk.size, chunk.size);
    for (let x = chunk.worldX; x < chunk.worldX + chunk.size; x += 96) {
      for (let y = chunk.worldY; y < chunk.worldY + chunk.size; y += 96) {
        const tint = (x / 96 + y / 96) % 2 === 0 ? 0x0a1820 : 0x08131b;
        g.fillStyle(tint, 0.75);
        g.fillRect(x, y, 96, 96);
      }
    }
    g.lineStyle(2, 0x244451, 0.36);
    g.strokeRect(chunk.worldX + 3, chunk.worldY + 3, chunk.size - 6, chunk.size - 6);
    g.fillStyle(chunk.patch.color, 0.74);
    g.fillRoundedRect(chunk.patch.x, chunk.patch.y, chunk.patch.w, chunk.patch.h, 52);
    g.lineStyle(3, chunk.patch.accent, 0.32);
    g.strokeRoundedRect(chunk.patch.x, chunk.patch.y, chunk.patch.w, chunk.patch.h, 52);
    objects.push(this.add.text(chunk.patch.x + 34, chunk.patch.y + 28, chunk.patch.label, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setAlpha(0.76));
    this.drawPaths(g, chunk.pathPoints, chunk.landmarks);
    chunk.props.forEach((prop) => this.drawProp(prop, objects));
    chunk.obstacles.forEach((obstacle) => this.drawObstacle(obstacle, objects));
    chunk.landmarks.forEach((landmark) => this.drawLandmark(landmark, objects));
    chunk.treasures.forEach((treasure) => this.drawTreasure(treasure, objects));
    chunk.encounters.forEach((encounter) => this.drawEncounter(encounter, objects));
    return objects;
  }

  private drawPaths(g: Phaser.GameObjects.Graphics, points = this.map.pathPoints.length > 1 ? this.map.pathPoints : [this.map.start], landmarks = this.map.landmarks): void {
    g.lineStyle(42, 0x132a33, 0.72);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y, points[i + 1]!.x, points[i + 1]!.y);
    g.lineStyle(4, 0xf6c85f, 0.18);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y, points[i + 1]!.x, points[i + 1]!.y);
    const hub = points[1];
    if (!hub) return;
    g.lineStyle(18, 0x10242d, 0.42);
    landmarks.forEach((landmark) => g.lineBetween(hub.x, hub.y, landmark.x, landmark.y));
    g.lineStyle(2, 0x9ff5e9, 0.14);
    landmarks.forEach((landmark) => g.lineBetween(hub.x, hub.y, landmark.x, landmark.y));
  }

  private drawProp(prop: OutdoorProp, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(prop.x, prop.y).setDepth(2 + prop.y / 10000);
    objects?.push(c);
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
    if (prop.kind === "waterfall") {
      c.add(this.add.rectangle(0, -14, 34, 86, 0x145f78, 0.68).setStrokeStyle(2, 0x7ad7ff, 0.62));
      c.add(this.add.ellipse(0, 38, 74, 22, 0x9ff5e9, 0.32));
      c.add(this.add.line(0, 0, -10, -46, -6, 24, 0xffffff, 0.32).setOrigin(0));
      c.add(this.add.line(0, 0, 9, -42, 5, 28, 0xffffff, 0.26).setOrigin(0));
      return;
    }
    if (prop.kind === "bridge") {
      c.add(this.add.rectangle(0, 0, 102, 26, 0x5a3a22, 0.92).setStrokeStyle(2, prop.color, 0.58));
      for (let x = -36; x <= 36; x += 18) c.add(this.add.rectangle(x, 0, 4, 30, 0xf1c27a, 0.55));
      return;
    }
    if (prop.kind === "statue") {
      c.add(this.add.rectangle(0, 24, 58, 16, 0x4b4252, 0.94).setStrokeStyle(2, prop.color, 0.46));
      c.add(this.add.rectangle(0, -8, 30, 58, 0x6c6575, 0.9));
      c.add(this.add.circle(0, -44, 18, 0x6c6575, 0.92).setStrokeStyle(2, prop.color, 0.5));
      return;
    }
    if (prop.kind === "beacon") {
      c.add(this.add.triangle(0, 6, -24, 46, 0, -56, 24, 46, prop.color, 0.84).setStrokeStyle(2, 0xffffff, 0.36));
      c.add(this.add.circle(0, -8, 42, prop.color, 0.12));
      c.add(this.add.circle(0, -8, 12, 0xffffff, 0.74));
      return;
    }
    if (prop.kind === "garden") {
      c.add(this.add.ellipse(0, 12, 86, 46, 0x14382b, 0.9).setStrokeStyle(2, prop.color, 0.42));
      for (let i = 0; i < 7; i += 1) {
        const angle = (Math.PI * 2 * i) / 7;
        c.add(this.add.circle(Math.cos(angle) * 25, 10 + Math.sin(angle) * 12, 7, i % 2 === 0 ? prop.color : 0xf6c85f, 0.78));
      }
      return;
    }
    if (prop.kind === "well") {
      c.add(this.add.circle(0, 10, 28, 0x10242d, 0.96).setStrokeStyle(3, prop.color, 0.64));
      c.add(this.add.arc(0, -2, 34, 205, 335, false, prop.color, 0.78).setStrokeStyle(5, prop.color, 0.78));
      return;
    }
    if (prop.kind === "arch") {
      c.add(this.add.rectangle(-24, 10, 14, 70, 0x4b4252, 0.94).setStrokeStyle(1, prop.color, 0.45));
      c.add(this.add.rectangle(24, 10, 14, 70, 0x4b4252, 0.94).setStrokeStyle(1, prop.color, 0.45));
      c.add(this.add.arc(0, -22, 32, 190, 350, false, prop.color, 0.88).setStrokeStyle(7, prop.color, 0.74));
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

  private drawObstacle(obstacle: OutdoorObstacle, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(obstacle.x, obstacle.y).setDepth(3 + obstacle.y / 10000);
    objects?.push(c);
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
    if (obstacle.kind === "bush") {
      c.add(this.add.circle(-obstacle.r * 0.45, 0, obstacle.r * 0.62, obstacle.color, 0.92));
      c.add(this.add.circle(0, -obstacle.r * 0.22, obstacle.r * 0.72, obstacle.color, 0.92).setStrokeStyle(2, 0x8fe0a4, 0.24));
      c.add(this.add.circle(obstacle.r * 0.45, 0, obstacle.r * 0.62, obstacle.color, 0.92));
      return;
    }
    if (obstacle.kind === "pillar") {
      c.add(this.add.rectangle(0, 0, obstacle.r * 0.9, obstacle.r * 2.2, obstacle.color, 0.92).setStrokeStyle(2, 0xc7b8ff, 0.34));
      c.add(this.add.rectangle(0, -obstacle.r * 1.2, obstacle.r * 1.35, obstacle.r * 0.32, 0x6c6575, 0.88));
      c.add(this.add.rectangle(0, obstacle.r * 1.2, obstacle.r * 1.45, obstacle.r * 0.34, 0x6c6575, 0.86));
      return;
    }
    if (obstacle.kind === "mushroom") {
      c.add(this.add.rectangle(0, obstacle.r * 0.28, obstacle.r * 0.44, obstacle.r * 0.96, 0xf1d9b7, 0.94));
      c.add(this.add.ellipse(0, -obstacle.r * 0.24, obstacle.r * 1.8, obstacle.r, obstacle.color, 0.9).setStrokeStyle(2, 0xffffff, 0.28));
      c.add(this.add.circle(-obstacle.r * 0.32, -obstacle.r * 0.34, obstacle.r * 0.13, 0xffffff, 0.78));
      c.add(this.add.circle(obstacle.r * 0.28, -obstacle.r * 0.18, obstacle.r * 0.11, 0xffffff, 0.7));
      return;
    }
    c.add(this.add.ellipse(0, 0, obstacle.r * 1.7, obstacle.r * 1.25, obstacle.color, 0.96).setStrokeStyle(2, 0xdde9ef, 0.18));
  }

  private drawLandmark(landmark: OutdoorLandmark, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(landmark.x, landmark.y).setDepth(5 + landmark.y / 10000);
    objects?.push(c);
    const accent = landmark.color;
    c.add(this.add.ellipse(0, 44, 138, 32, 0x000000, 0.24));
    c.add(this.add.circle(0, -10, 78, accent, 0.09));
    if (landmark.kind === "forge") {
      c.add(this.add.rectangle(0, 14, 86, 72, 0x2a1f3a, 0.96).setStrokeStyle(3, accent, 0.75));
      c.add(this.add.triangle(0, -54, -56, -18, 56, -18, 0x4a321d, 0.94).setStrokeStyle(2, 0xf6c85f, 0.45));
      c.add(this.add.circle(0, 18, 18, 0xf6c85f, 0.75));
    } else if (landmark.kind === "atlasGate") {
      c.add(this.add.arc(0, -2, 58, 190, 350, false, accent, 0.9).setStrokeStyle(10, accent, 0.62));
      c.add(this.add.rectangle(-46, 18, 18, 92, 0x173b36, 0.96).setStrokeStyle(2, accent, 0.55));
      c.add(this.add.rectangle(46, 18, 18, 92, 0x173b36, 0.96).setStrokeStyle(2, accent, 0.55));
      c.add(this.add.circle(0, 12, 22, 0x145f78, 0.72).setStrokeStyle(2, 0x9ff5e9, 0.72));
    } else if (landmark.kind === "logicSpire") {
      c.add(this.add.triangle(0, 40, -46, 48, 0, -82, 46, 48, 0x1c3148, 0.96).setStrokeStyle(3, accent, 0.82));
      c.add(this.add.rectangle(0, -10, 64, 12, accent, 0.36));
      c.add(this.add.circle(0, -48, 16, accent, 0.84));
    } else if (landmark.kind === "ancientCore") {
      c.add(this.add.rectangle(0, 18, 120, 48, 0x4b4252, 0.94).setStrokeStyle(3, accent, 0.55));
      c.add(this.add.circle(0, -24, 42, 0x061019, 0.96).setStrokeStyle(4, accent, 0.82));
      c.add(this.add.circle(0, -24, 14, accent, 0.88));
    } else if (landmark.kind === "skyTree") {
      c.add(this.add.rectangle(0, 26, 28, 110, 0x5a3a22, 0.96));
      c.add(this.add.circle(-34, -42, 42, 0x235b3a, 0.94).setStrokeStyle(2, accent, 0.34));
      c.add(this.add.circle(18, -54, 52, 0x2b6c45, 0.95).setStrokeStyle(2, accent, 0.34));
      c.add(this.add.circle(42, -18, 38, 0x1c7d51, 0.88));
    } else {
      c.add(this.add.ellipse(0, 20, 118, 48, 0x222950, 0.96).setStrokeStyle(3, accent, 0.82));
      c.add(this.add.triangle(-26, -10, -46, 38, -26, -82, -4, 38, accent, 0.72));
      c.add(this.add.triangle(24, -2, 2, 44, 24, -72, 48, 44, 0x7ad7ff, 0.64));
      c.add(this.add.circle(0, -10, 20, 0xffffff, 0.42));
    }
    c.add(this.add.text(0, 86, landmark.label, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 160 },
    }).setOrigin(0.5, 0));
  }

  private drawTreasure(treasure: OutdoorTreasure, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(treasure.x, treasure.y).setDepth(7 + treasure.y / 10000);
    objects?.push(c);
    const collected = this.collectedTreasures.has(treasure.id);
    const accent = this.biomeAccent(treasure.biome);
    c.add(this.add.ellipse(0, 24, 62, 16, 0x000000, 0.28));
    c.add(this.add.circle(0, -4, 36, accent, collected ? 0.04 : 0.14));
    if (treasure.label.includes("scrigno")) {
      c.add(this.add.rectangle(0, 0, 48, 30, 0x7a4b28, 0.96).setStrokeStyle(2, 0xf6c85f, 0.86));
      c.add(this.add.rectangle(0, -9, 52, 8, 0xf6c85f, 0.82));
      c.add(this.add.circle(0, 5, 5, 0xf5fbff, 0.86));
    } else if (treasure.label.includes("energia")) {
      c.add(this.add.rectangle(0, 0, 42, 36, 0x173b36, 0.96).setStrokeStyle(2, 0x8fe0a4, 0.78));
      c.add(this.add.triangle(0, -16, -10, 8, 4, 4, -2, 18, 0xf6c85f, 0.92));
    } else {
      c.add(this.add.circle(-12, 0, 10, 0xc7b8ff, 0.82));
      c.add(this.add.circle(2, -8, 12, accent, 0.78));
      c.add(this.add.circle(14, 4, 9, 0x9ff5e9, 0.78));
    }
    c.add(this.add.text(0, 36, collected ? "raccolto" : treasure.label, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: collected ? "#6f8794" : "#f7d37a",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 120 },
    }).setOrigin(0.5, 0));
    if (collected) {
      c.setAlpha(0.32);
    } else {
      const hit = this.add.circle(0, 0, 44, 0x000000, 0.001).setInteractive({ useHandCursor: true });
      hit.on("pointerup", () => this.collectTreasure(treasure));
      c.add(hit);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: c, y: treasure.y - 5, duration: 1350, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    }
    this.treasureNodes.set(treasure.id, c);
  }

  private drawEncounter(encounter: OutdoorEncounter, objects?: Phaser.GameObjects.GameObject[]): void {
    const patch = this.map.patches.find((candidate) => candidate.id === encounter.biome);
    const accent = patch?.accent ?? 0x6be7d6;
    const c = this.add.container(encounter.x, encounter.y).setDepth(8 + encounter.y / 10000);
    objects?.push(c);
    const done = this.completed.has(encounter.id);
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
    if (done) {
      c.add(this.add.text(0, 0, "OK", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#8ff6c0",
        fontStyle: "bold",
      }).setOrigin(0.5));
      c.setAlpha(0.36);
    } else {
      const hit = this.add.circle(0, 0, 48, 0x000000, 0.001).setInteractive({ useHandCursor: true });
      hit.on("pointerup", () => this.startEncounter(encounter));
      c.add(hit);
    }
    if (!done && !settingsSystem.effectsReduced()) {
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
    hud.add(this.add.rectangle(18, 16, 360, 96, 0x061019, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.42));
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
    const outdoor = saveSystem.outdoorAdventure;
    this.energyText = this.add.text(1040, 24, `${rewardSystem.energy()} ⚡`, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(1, 0);
    hud.add(this.energyText);
    this.progressText = this.add.text(36, 84, `${this.completed.size} incontri · ${this.collectedTreasures.size} tesori · ${this.activeChunks.size} zone · serie ${outdoor.currentStreak}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.fragmentText = this.add.text(1040, 54, `${outdoor.fragments} frammenti`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7b8ff",
      fontStyle: "bold",
    }).setOrigin(1, 0);
    hud.add([this.progressText, this.fragmentText]);
    new Button(this, 776, 48, "Bacheca", () => this.openBountyBoard(), {
      width: 126,
      height: 42,
      fontSize: 13,
      fill: 0x173b36,
      stroke: 0x8fe0a4,
      soundKey: "panelOpen",
    }).setScrollFactor(0).setDepth(130);
    new Button(this, 920, 48, "Forgia", () => this.openForge(), {
      width: 112,
      height: 42,
      fontSize: 13,
      fill: 0x2a1f3a,
      stroke: 0xc7b8ff,
      soundKey: "panelOpen",
    }).setScrollFactor(0).setDepth(130);
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
    const nx = Phaser.Math.Clamp(this.avatar.x + dx * speed * dt, -VIRTUAL_WORLD_LIMIT + 42, VIRTUAL_WORLD_LIMIT - 42);
    const ny = Phaser.Math.Clamp(this.avatar.y + dy * speed * dt, -VIRTUAL_WORLD_LIMIT + 54, VIRTUAL_WORLD_LIMIT - 54);
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
    let nearestTreasure: OutdoorTreasure | undefined;
    let prompt = "";
    let best = Infinity;
    for (const encounter of this.map.encounters) {
      if (this.completed.has(encounter.id)) continue;
      const distance = Math.hypot(encounter.x - this.avatar.x, encounter.y - this.avatar.y);
      if (distance < 92 && distance < best) {
        nearest = encounter;
        nearestTreasure = undefined;
        prompt = `E / clicca · ${nearest.enemy}`;
        best = distance;
      }
    }
    for (const treasure of this.map.treasures) {
      if (this.collectedTreasures.has(treasure.id)) continue;
      const distance = Math.hypot(treasure.x - this.avatar.x, treasure.y - this.avatar.y);
      if (distance < 82 && distance < best) {
        nearest = undefined;
        nearestTreasure = treasure;
        prompt = `E / clicca · ${treasure.label}`;
        best = distance;
      }
    }
    this.activeEncounter = nearest;
    this.activeTreasure = nearestTreasure;
    if (!nearest && !nearestTreasure) {
      this.prompt.setVisible(false);
      return;
    }
    const target = nearest ?? nearestTreasure!;
    this.prompt.setPosition(target.x, target.y - 72).setVisible(true);
    this.promptText.setText(prompt);
  }

  private tryInteract(): void {
    if (this.paused) return;
    if (this.activeTreasure) {
      this.collectTreasure(this.activeTreasure);
      return;
    }
    if (this.activeEncounter) this.startEncounter(this.activeEncounter);
  }

  private collectTreasure(treasure: OutdoorTreasure): void {
    if (this.paused || this.collectedTreasures.has(treasure.id)) return;
    if (!saveSystem.recordOutdoorTreasure(treasure.id, treasure.rewardEnergy, treasure.rewardFragments)) return;
    this.collectedTreasures.add(treasure.id);
    this.activeTreasure = undefined;
    this.prompt.setVisible(false);
    const node = this.treasureNodes.get(treasure.id);
    if (node) {
      this.tweens.killTweensOf(node);
      node.destroy(true);
      this.treasureNodes.delete(treasure.id);
    }
    this.refreshHud();
    audioManager.play("success");
    feedbackSystem.publish(`Tesoro raccolto: +${treasure.rewardEnergy} energia, +${treasure.rewardFragments} frammenti.`, "success");
  }

  private openBountyBoard(): void {
    if (this.paused) return;
    this.paused = true;
    const overlay = this.add.container(0, 0).setDepth(2100).setScrollFactor(0);
    const close = (): void => {
      overlay.destroy(true);
      this.paused = false;
      this.refreshHud();
    };
    const outdoor = saveSystem.outdoorAdventure;
    const claimed = new Set(outdoor.claimedBountyIds ?? []);
    const bounties = this.outdoorBounties();
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
    overlay.add(this.add.rectangle(640, 360, 760, 560, 0x07151d, 0.98).setStrokeStyle(2, 0x8fe0a4, 0.82));
    overlay.add(this.add.rectangle(326, 138, 5, 44, 0x8fe0a4, 0.95).setOrigin(0));
    overlay.add(this.add.text(344, 136, "Bacheca Avventura", {
      fontFamily: "Inter, Arial",
      fontSize: "31px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(346, 178, "Obiettivi giornalieri della mappa esterna: completali e reclama energia + frammenti.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
      wordWrap: { width: 580 },
    }));
    bounties.forEach((bounty, index) => {
      this.drawBountyRow(overlay, bounty, claimed.has(bounty.id), 356, 224 + index * 76, () => {
        overlay.destroy(true);
        this.paused = false;
        this.openBountyBoard();
      });
    });
    overlay.add(new Button(this, 640, 632, "Chiudi", close, {
      width: 180,
      height: 44,
      fill: 0x263743,
    }));
  }

  private outdoorBounties(): OutdoorBounty[] {
    const outdoor = saveSystem.outdoorAdventure;
    return [
      {
        id: "clear-3",
        title: "Ricognizione esterna",
        description: "Supera tre incontri sulla mappa di oggi.",
        current: Math.min(this.completed.size, 3),
        target: 3,
        energy: 35,
        fragments: 8,
      },
      {
        id: "streak-2",
        title: "Serie pulita",
        description: "Vinci due incontri consecutivi senza ritirata.",
        current: Math.min(outdoor.currentStreak, 2),
        target: 2,
        energy: 30,
        fragments: 8,
      },
      {
        id: "guardian-day",
        title: "Guardiano del giorno",
        description: "Sconfiggi il guardiano prismatico della mappa.",
        current: Math.min(outdoor.guardianWinsToday ?? 0, 1),
        target: 1,
        energy: 60,
        fragments: 16,
      },
      {
        id: "treasure-5",
        title: "Cercatore di tesori",
        description: "Raccogli cinque tesori nascosti nella mappa.",
        current: Math.min(this.collectedTreasures.size, 5),
        target: 5,
        energy: 45,
        fragments: 12,
      },
      {
        id: "daily-route-12",
        title: "Rotta lunga",
        description: "Supera dodici incontri esplorando più zone.",
        current: Math.min(this.completed.size, DAILY_ROUTE_TARGET),
        target: DAILY_ROUTE_TARGET,
        energy: 95,
        fragments: 24,
      },
    ];
  }

  private drawBountyRow(overlay: Phaser.GameObjects.Container, bounty: OutdoorBounty, claimed: boolean, x: number, y: number, refresh: () => void): void {
    const done = bounty.current >= bounty.target;
    overlay.add(this.add.rectangle(x, y, 568, 66, 0x0c1d2a, 0.95).setOrigin(0).setStrokeStyle(2, claimed ? 0x2ed889 : done ? 0xf6c85f : 0x244451, claimed ? 0.9 : 0.66));
    overlay.add(this.add.rectangle(x, y, 4, 66, claimed ? 0x2ed889 : done ? 0xf6c85f : 0x8fe0a4, 0.95).setOrigin(0));
    overlay.add(this.add.text(x + 20, y + 10, bounty.title, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 20, y + 34, bounty.description, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9fb6c2",
      wordWrap: { width: 330 },
    }));
    overlay.add(this.add.text(x + 390, y + 12, `${bounty.current}/${bounty.target}`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: done ? "#f6c85f" : "#9fb6c2",
      fontStyle: "bold",
    }).setOrigin(0.5, 0));
    overlay.add(this.add.text(x + 390, y + 38, `+${bounty.energy} ⚡  +${bounty.fragments} fram.`, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#c7b8ff",
      fontStyle: "bold",
    }).setOrigin(0.5, 0));
    if (claimed) {
      overlay.add(this.add.text(x + 508, y + 33, "Reclamato", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#8ff6c0",
        fontStyle: "bold",
      }).setOrigin(0.5));
      return;
    }
    overlay.add(new Button(this, x + 508, y + 33, done ? "Reclama" : "In corso", () => {
      if (!done) {
        feedbackSystem.publish("Obiettivo non ancora completato.", "hint");
        return;
      }
      if (saveSystem.claimOutdoorBounty(bounty.id, bounty.energy, bounty.fragments)) {
        audioManager.play("shopPurchase");
        feedbackSystem.publish(`Bacheca: +${bounty.energy} energia e +${bounty.fragments} frammenti.`, "success");
        this.refreshHud();
        refresh();
      }
    }, { width: 104, height: 34, fontSize: 12, fill: done ? 0x173b36 : 0x1a252e, stroke: done ? 0x8fe0a4 : 0x6a638d, soundKey: done ? "shopPurchase" : "shopLocked" }));
  }

  private openForge(): void {
    if (this.paused) return;
    this.paused = true;
    const overlay = this.add.container(0, 0).setDepth(2100).setScrollFactor(0);
    const close = (): void => {
      overlay.destroy(true);
      this.paused = false;
      this.refreshHud();
    };
    const outdoor = saveSystem.outdoorAdventure;
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
    overlay.add(this.add.rectangle(640, 360, 760, 584, 0x07151d, 0.98).setStrokeStyle(2, 0xc7b8ff, 0.82));
    overlay.add(this.add.rectangle(286, 102, 5, 46, 0xc7b8ff, 0.95).setOrigin(0));
    overlay.add(this.add.text(304, 102, "Forgia dei Frammenti", {
      fontFamily: "Inter, Arial",
      fontSize: "32px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(306, 144, `${outdoor.fragments} frammenti disponibili · guardiani vinti ${outdoor.guardianWins}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7b8ff",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(304, 170, "Ricompense rare della Mappa Esterna: si sbloccano con frammenti e restano equipaggiabili nell'Armadio.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
      wordWrap: { width: 640 },
    }));

    FORGE_REWARDS.forEach((entry, index) => {
      const item = rewardSystem.find(entry.id);
      if (!item) return;
      this.drawForgeCard(overlay, item, entry.fragmentCost, entry.guardianWins ?? 0, 316, 220 + index * 74, () => {
        overlay.destroy(true);
        this.paused = false;
        this.openForge();
      });
    });
    overlay.add(new Button(this, 640, 650, "Chiudi", close, {
      width: 180,
      height: 44,
      fill: 0x263743,
    }));
  }

  private drawForgeCard(
    overlay: Phaser.GameObjects.Container,
    item: Cosmetic,
    fragmentCost: number,
    guardianWins: number,
    x: number,
    y: number,
    refresh: () => void,
  ): void {
    const outdoor = saveSystem.outdoorAdventure;
    const owned = rewardSystem.owned(item.id);
    const levelOk = rewardSystem.playerLevel() >= (item.minLevel ?? 1);
    const guardianOk = outdoor.guardianWins >= guardianWins;
    const fragmentsOk = outdoor.fragments >= fragmentCost;
    const canForge = !owned && levelOk && guardianOk && fragmentsOk;
    const accent = item.color ?? 0xc7b8ff;
    overlay.add(this.add.rectangle(x, y, 648, 62, 0x0c1d2a, 0.95).setOrigin(0).setStrokeStyle(2, owned ? 0x2ed889 : accent, owned ? 0.86 : 0.54));
    overlay.add(this.add.rectangle(x, y, 4, 62, owned ? 0x2ed889 : accent, 0.94).setOrigin(0));
    this.drawForgeIcon(overlay, item, x + 36, y + 31);
    overlay.add(this.add.text(x + 76, y + 12, item.name, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 76, y + 36, item.description, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9fb6c2",
      wordWrap: { width: 340 },
    }));
    const req = [
      `${fragmentCost} frammenti`,
      item.minLevel ? `Liv. ${item.minLevel}` : "",
      guardianWins > 0 ? `${guardianWins} guardiani` : "",
    ].filter(Boolean).join(" · ");
    overlay.add(this.add.text(x + 468, y + 12, req, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#c7b8ff",
      fontStyle: "bold",
      align: "right",
      wordWrap: { width: 142 },
    }).setOrigin(1, 0));
    if (owned) {
      overlay.add(new Button(this, x + 560, y + 31, rewardSystem.isEquipped(item.id) ? "In uso" : "Equip", () => {
        rewardSystem.equip(item.id);
        audioManager.play(item.slot === "pet" ? "petEquip" : "shopEquip");
        refresh();
      }, { width: 112, height: 34, fontSize: 12, fill: 0x173b36, stroke: 0x2ed889 }));
      return;
    }
    const label = !levelOk ? `Liv. ${item.minLevel}` : !guardianOk ? "Guardiani" : !fragmentsOk ? "Frammenti" : "Forgiare";
    overlay.add(new Button(this, x + 560, y + 31, label, () => {
      if (!canForge) {
        feedbackSystem.publish("La Forgia richiede più frammenti, livello o guardiani superati.", "warning");
        return;
      }
      if (!saveSystem.spendOutdoorFragments(fragmentCost)) return;
      rewardSystem.unlockReward(item.id);
      this.refreshHud();
      this.showForgeReveal(item, refresh);
    }, { width: 112, height: 34, fontSize: 12, fill: canForge ? 0x2a1f3a : 0x1a252e, stroke: canForge ? 0xc7b8ff : 0x6a638d, soundKey: canForge ? "shopPurchase" : "shopLocked" }));
  }

  private drawForgeIcon(layer: Phaser.GameObjects.Container, item: Cosmetic, x: number, y: number): void {
    if (this.textures.exists("reward-items") && this.textures.getFrame("reward-items", item.id)) {
      layer.add(this.add.image(x, y, "reward-items", item.id).setDisplaySize(44, 44));
      return;
    }
    layer.add(this.add.circle(x, y, 22, 0x061019, 0.95).setStrokeStyle(2, item.color ?? 0xc7b8ff, 0.9));
    layer.add(this.add.text(x, y - 1, item.glyph ?? "*", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
  }

  private showForgeReveal(item: Cosmetic, onClose: () => void): void {
    const reveal = this.add.container(0, 0).setDepth(2300).setScrollFactor(0);
    reveal.add(this.add.rectangle(640, 360, 1280, 720, 0x010407, 0.92).setInteractive());
    reveal.add(this.add.rectangle(640, 360, 520, 430, 0x07151d, 0.98).setStrokeStyle(3, item.color ?? 0xffd75e, 0.92));
    reveal.add(this.add.text(640, 202, "FORGIATURA COMPLETA", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: "#ffd75e",
      fontStyle: "bold",
    }).setOrigin(0.5));
    reveal.add(this.add.text(640, 238, item.name, {
      fontFamily: "Inter, Arial",
      fontSize: "32px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (this.textures.exists("soft-glow")) {
      reveal.add(this.add.image(640, 342, "soft-glow").setTint(item.color ?? 0xffd75e).setAlpha(0.28).setScale(2));
    }
    this.drawForgeIcon(reveal, item, 640, 342);
    reveal.add(this.add.text(640, 420, "L'oggetto è stato sbloccato ed equipaggiato. Lo ritrovi anche nell'Armadio Avatar.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#cfe3ec",
      align: "center",
      wordWrap: { width: 410 },
    }).setOrigin(0.5));
    if (!settingsSystem.effectsReduced()) {
      for (let i = 0; i < 14; i += 1) {
        const angle = (Math.PI * 2 * i) / 14;
        const spark = this.add.circle(640, 342, 4, i % 2 === 0 ? item.color ?? 0xffd75e : 0xffffff, 0.9);
        reveal.add(spark);
        this.tweens.add({
          targets: spark,
          x: 640 + Math.cos(angle) * Phaser.Math.Between(88, 156),
          y: 342 + Math.sin(angle) * Phaser.Math.Between(70, 128),
          alpha: 0,
          duration: 760,
          ease: "Cubic.easeOut",
        });
      }
    }
    reveal.add(new Button(this, 640, 520, "Torna alla Forgia", () => {
      reveal.destroy(true);
      onClose();
    }, { width: 210, height: 44, fontSize: 14, fill: 0x173b36, stroke: item.color ?? 0xffd75e }));
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
    let playerShield = this.playerShieldFor(encounter);
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
            enemyShield -= this.playerDamageBonus();
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
    const fragments = this.fragmentReward(encounter, correct, victory);
    const varietyBonuses = saveSystem.recordDailyEnergySubject(`Avventura ${this.subjectFor(encounter.kind)}`);
    const bonus = varietyBonuses.reduce((sum, item) => sum + item.amount, 0);
    saveSystem.addEnergy(reward + bonus);
    const outdoor = saveSystem.recordOutdoorEncounter(encounter.id, victory, fragments, encounter.kind === "guardian");
    this.completed.add(encounter.id);
    this.markEncounterDone(encounter);
    this.refreshHud();
    overlay.removeAll(true);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.9).setInteractive());
    overlay.add(this.add.rectangle(640, 360, 560, 360, 0x07151d, 0.98).setStrokeStyle(2, victory ? 0x2ed889 : 0xf6c85f, 0.9));
    overlay.add(this.add.text(640, 260, victory ? "Guardiano superato" : "Ritirata strategica", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: victory ? "#8ff6c0" : "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(640, 316, `${correct}/3 colpi precisi · +${reward + bonus} energia · +${fragments} frammenti`, {
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
    overlay.add(this.add.text(640, 382, `Avventura oggi: ${outdoor.completedEncounterIds.length} incontri · serie migliore ${outdoor.bestStreak} · guardiani ${outdoor.guardianWins}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7b8ff",
      align: "center",
      wordWrap: { width: 470 },
    }).setOrigin(0.5));
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

  private refreshHud(): void {
    const outdoor = saveSystem.outdoorAdventure;
    this.energyText?.setText(`${rewardSystem.energy()} ⚡`);
    this.progressText?.setText(`${this.completed.size} incontri · ${this.collectedTreasures.size} tesori · ${this.activeChunks.size} zone · serie ${outdoor.currentStreak}`);
    this.fragmentText?.setText(`${outdoor.fragments} frammenti`);
  }

  private playerShieldFor(encounter: OutdoorEncounter): number {
    let shield = encounter.kind === "guardian" ? 4 : 3;
    const outfit = rewardSystem.equippedId("avatar");
    const pet = rewardSystem.equippedId("pet");
    if (outfit === "avatar-captain" || outfit === "avatar-engineer") shield += 1;
    if (pet === "pet-guardiano") shield += 1;
    return shield;
  }

  private playerDamageBonus(): number {
    let damage = 1;
    if (rewardSystem.equippedId("emblem") === "emblem-bolt") damage += 1;
    if (rewardSystem.equippedId("accessory") === "accessory-visor" && damage === 1) damage += 1;
    return damage;
  }

  private fragmentReward(encounter: OutdoorEncounter, correct: number, victory: boolean): number {
    const base = victory ? encounter.difficulty + (encounter.kind === "guardian" ? 4 : 1) : 1;
    const codexBonus = rewardSystem.equippedId("pet") === "pet-codex" ? 2 : 0;
    return Math.max(1, base + correct + codexBonus);
  }

  private biomeAccent(biome: OutdoorBiome): number {
    return this.map.patches.find((patch) => patch.id === biome)?.accent ?? BIOME_ACCENTS[biome];
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
