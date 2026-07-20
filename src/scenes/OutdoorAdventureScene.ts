import Phaser from "phaser";
import { drawAccessoryVisual, drawOutfitBack, drawOutfitFront, drawPetVisual } from "../core/AvatarCosmeticVisuals";
import { audioManager } from "../core/AudioManager";
import { feedbackSystem } from "../core/FeedbackSystem";
import { rewardSystem, type Cosmetic } from "../core/RewardSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { settingsSystem } from "../core/SettingsSystem";
import { type OutdoorAdventureMap, type OutdoorBiome, type OutdoorEncounter, type OutdoorEncounterKind, type OutdoorLandmark, type OutdoorObstacle, type OutdoorProp, type OutdoorTreasure } from "../procedural/OutdoorAdventureGenerator";
import { generateOutdoorChunk, OUTDOOR_CHUNK_SIZE, type OutdoorChunk } from "../procedural/OutdoorChunkGenerator";
import { generateOutdoorHazardsForChunk, isOutdoorHazardActive, outdoorHazardDifficulty, outdoorHazardReward, OUTDOOR_PHASE_LABELS, phaseForOutdoorTime, type OutdoorDayPhase, type OutdoorHazard } from "../procedural/OutdoorDayNight";
import { Button } from "../ui/Button";
import { consumeOutdoorWorldResult, createOutdoorWorldRequest, openOutdoorGodot, type OutdoorResumeState, type OutdoorWorldResult } from "../integration/outdoorGodotBridge";
import { resolveOutdoorPresentation } from "../integration/outdoorAvatar";
import { godotOutdoorUrl, isGodotOutdoorAvailable } from "../integration/outdoorEntry";

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

const OUTDOOR_EXERCISE_ENERGY_COST = 3;

const BIOME_ACCENTS: Record<OutdoorBiome, number> = {
  academy: 0x6be7d6,
  ruins: 0xff8f6b,
  geo: 0x8fe0a4,
  logic: 0x9f8cff,
  wild: 0x74f0c5,
  crystal: 0xc7b8ff,
};

const BIOME_DETAIL_COLORS: Record<OutdoorBiome, [number, number, number]> = {
  academy: [0x6be7d6, 0x8fe0a4, 0xf6c85f],
  ruins: [0xff8f6b, 0x8a6c79, 0x4b4252],
  geo: [0x8fe0a4, 0x7ad7ff, 0x355f47],
  logic: [0x9f8cff, 0x6be7d6, 0x2e4f72],
  wild: [0x74f0c5, 0x2b6c45, 0xf6c85f],
  crystal: [0xc7b8ff, 0x7ad7ff, 0xffffff],
};

const BIOME_PAINTED_BACKDROPS: Record<OutdoorBiome, { key: string; alpha: number; tint?: number; veil: number }> = {
  academy: { key: "bg-academy-painted", alpha: 0.3, tint: 0xcffaf2, veil: 0x071018 },
  ruins: { key: "mission-electronics-bg", alpha: 0.28, tint: 0xffc0a0, veil: 0x100d14 },
  geo: { key: "mission-atlas-bg", alpha: 0.32, tint: 0xc6ffe8, veil: 0x071815 },
  logic: { key: "mission-coding-terminal-bg", alpha: 0.3, tint: 0xaed7ff, veil: 0x071221 },
  wild: { key: "bg-greenhouse-painted", alpha: 0.34, tint: 0xc8ffd7, veil: 0x071a12 },
  crystal: { key: "mission-bg-synthesis", alpha: 0.3, tint: 0xded5ff, veil: 0x090d22 },
};

const ENCOUNTER_GLYPHS: Record<OutdoorEncounterKind, string> = {
  times: "x",
  mental: "+",
  capital: "@",
  physicalGeo: "~",
  guardian: "!",
};

const ENCOUNTER_COLORS: Record<OutdoorEncounterKind, number> = {
  times: 0xf6c85f,
  mental: 0x6be7d6,
  capital: 0x8fe0a4,
  physicalGeo: 0x7ad7ff,
  guardian: 0xc7b8ff,
};

type OutdoorTreasureKind = "energy" | "fragments" | "rare";

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

type ActiveOutdoorHazard = {
  hazard: OutdoorHazard;
  node: Phaser.GameObjects.Container;
};

type CozyLandscapeKind = "roundTree" | "flowerPatch" | "fence" | "pond" | "signpost" | "bench" | "steppingStones" | "gardenBed";

export class OutdoorAdventureScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
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
  private hazardNodes = new Map<string, ActiveOutdoorHazard>();
  private clearedHazards = new Set<string>();
  private moveTarget?: { x: number; y: number };
  private moveTargetMarker?: Phaser.GameObjects.Container;
  private prompt!: Phaser.GameObjects.Container;
  private promptText!: Phaser.GameObjects.Text;
  private activeEncounter?: OutdoorEncounter;
  private activeTreasure?: OutdoorTreasure;
  private godotBounceResume?: OutdoorResumeState;
  private godotAvailable = false;
  private energyText?: Phaser.GameObjects.Text;
  private progressText?: Phaser.GameObjects.Text;
  private fragmentText?: Phaser.GameObjects.Text;
  private biomeText?: Phaser.GameObjects.Text;
  private coordText?: Phaser.GameObjects.Text;
  private radarLegendText?: Phaser.GameObjects.Text;
  private dayPhaseText?: Phaser.GameObjects.Text;
  private dayNightOverlay?: Phaser.GameObjects.Graphics;
  private radar?: Phaser.GameObjects.Graphics;
  private guideGraphics?: Phaser.GameObjects.Graphics;
  private guideText?: Phaser.GameObjects.Text;
  private currentBiome?: OutdoorBiome;
  private biomeBanner?: Phaser.GameObjects.Container;
  private ambientMotes: Phaser.GameObjects.GameObject[] = [];
  private atmosphereGraphics?: Phaser.GameObjects.Graphics;
  private dayCycleStartedAt = 0;
  private currentDayPhase: OutdoorDayPhase = "day";
  private lastHazardHitAt = 0;
  private lastAmbientSparkAt = 0;
  private lastTrailAt = 0;
  private petMood: "idle" | "treasure" | "correct" = "idle";
  private petMoodUntil = 0;
  private petNextChirpAt = 0;
  private readonly onE = (): void => this.tryInteract();
  private readonly onPointerDown = (pointer: Phaser.Input.Pointer): void => this.handlePointerMove(pointer);

  constructor() {
    super("OutdoorAdventureScene");
  }

  preload(): void {
    queueSceneAssets(this, "outdoorPainted", "outdoorWorld", "rewards");
  }

  create(data?: { returnScene?: string }): void {
    this.returnScene = data?.returnScene ?? "MainMenuScene";
    saveSystem.load();
    const godotResult = consumeOutdoorWorldResult();
    if (godotResult) this.applyGodotWorldResult(godotResult);
    const daySeed = new Date().toISOString().slice(0, 10);
    this.worldSeed = `outdoor-${daySeed}-${rewardSystem.playerLevel()}`;
    this.map = this.emptyOutdoorMap();
    this.completed = new Set(saveSystem.outdoorAdventure.completedEncounterIds);
    this.collectedTreasures = new Set(saveSystem.outdoorAdventure.collectedTreasureIds ?? []);
    this.cameras.main.setBounds(-VIRTUAL_WORLD_LIMIT, -VIRTUAL_WORLD_LIMIT, VIRTUAL_WORLD_LIMIT * 2, VIRTUAL_WORLD_LIMIT * 2);
    this.cameras.main.setBackgroundColor("#071018");
    this.dayCycleStartedAt = this.time.now;
    this.syncOutdoorChunks(true);
    this.buildAvatar();
    this.buildPrompt();
    this.buildDayNightLayer();
    this.drawHud();
    this.updateDayNightCycle(true);
    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D") as Record<string, Phaser.Input.Keyboard.Key>;
    this.input.keyboard!.on("keydown-E", this.onE);
    this.input.on("pointerdown", this.onPointerDown);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.input.keyboard?.off("keydown-E", this.onE);
      this.input.off("pointerdown", this.onPointerDown);
      audioManager.stopMusic();
    });
    this.cameras.main.startFollow(this.avatar, true, 0.12, 0.12);
    if (!settingsSystem.effectsReduced()) {
      this.cameras.main.fadeIn(520, 2, 7, 11);
    }
    audioManager.playMusic("labAmbience");
    audioManager.play("missionStart");
    void this.probeGodotAvailability();
    if (godotResult?.pendingEncounter) {
      // Rientro da Godot: gioca subito l'incontro rimandato, poi torna nel mondo.
      const pendingResult = godotResult;
      this.time.delayedCall(0, () => this.playPendingGodotEncounter(pendingResult));
    }
  }

  private playPendingGodotEncounter(result: OutdoorWorldResult): void {
    const pending = result.pendingEncounter;
    if (!pending) return;
    if (this.completed.has(pending.id)) {
      this.reopenGodot(result.resume);
      return;
    }
    const encounter: OutdoorEncounter = {
      id: pending.id,
      x: pending.x,
      y: pending.y,
      biome: pending.biome as OutdoorBiome,
      kind: pending.kind as OutdoorEncounterKind,
      label: pending.label,
      enemy: pending.enemy,
      difficulty: pending.difficulty,
      reward: pending.reward,
    };
    this.godotBounceResume = result.resume ?? { playerX: encounter.x, playerY: encounter.y, dayClock: 0 };
    this.startEncounter(encounter, true);
  }

  private applyGodotWorldResult(result: OutdoorWorldResult): void {
    const previousEncounters = new Set(saveSystem.outdoorAdventure.completedEncounterIds);
    const previousTreasures = new Set(saveSystem.outdoorAdventure.collectedTreasureIds ?? []);
    result.completedEncounterIds
      .filter((id) => !previousEncounters.has(id))
      .forEach((id) => saveSystem.recordOutdoorEncounter(id, true, 0));
    result.collectedTreasureIds
      .filter((id) => !previousTreasures.has(id))
      .forEach((id) => saveSystem.recordOutdoorTreasure(id, 0, 0));
    if (result.fragmentsEarned > 0) saveSystem.grantOutdoorFragments(result.fragmentsEarned);
    if (result.energyEarned > 0) saveSystem.addEnergy(result.energyEarned);
    if ((result.energySpent ?? 0) > 0) saveSystem.spendEnergy(result.energySpent ?? 0);
  }

  // Verifica una sola volta se esiste un export Godot Web reale (sonda condivisa
  // con l'ingresso unificato), così la mancanza del bundle non rompe il gioco.
  private async probeGodotAvailability(): Promise<void> {
    this.godotAvailable = await isGodotOutdoorAvailable();
  }

  private reopenGodot(resume?: OutdoorResumeState): boolean {
    if (!this.godotAvailable) {
      feedbackSystem.publish("Mondo Godot non ancora compilato: continui nel mondo Phaser.", "hint");
      return false;
    }
    const request = createOutdoorWorldRequest(saveSystem.data, rewardSystem.playerLevel(), window.location.href, resume, resolveOutdoorPresentation(rewardSystem.playerLevel()));
    openOutdoorGodot(godotOutdoorUrl(), request);
    return true;
  }

  update(_: number, delta: number): void {
    if (this.paused) return;
    this.updateDayNightCycle();
    this.updateMovement(delta / 1000);
    this.syncOutdoorChunks();
    this.updateHazards();
    this.updatePet();
    this.updatePrompt();
    this.updateObjectiveGuide();
    this.updateAmbientSparkles();
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
      [...this.hazardNodes.entries()]
        .filter(([, entry]) => entry.hazard.chunkId === active.chunk.id)
        .forEach(([hazardId]) => this.hazardNodes.delete(hazardId));
      if (active.chunk.encounters.some((encounter) => encounter.id === this.activeEncounter?.id)) this.activeEncounter = undefined;
      if (active.chunk.treasures.some((treasure) => treasure.id === this.activeTreasure?.id)) this.activeTreasure = undefined;
      active.objects.forEach((object) => this.destroyChunkObject(object));
      this.activeChunks.delete(id);
    }

    this.rebuildActiveMap();
    this.updateBiomePresence(chunkX, chunkY);
    this.refreshHud();
  }

  private updateBiomePresence(chunkX: number, chunkY: number): void {
    const active = this.activeChunks.get(this.chunkId(chunkX, chunkY));
    if (!active) return;
    if (active.chunk.biome !== this.currentBiome) {
      const previousBiome = this.currentBiome;
      this.currentBiome = active.chunk.biome;
      this.cameras.main.setBackgroundColor(this.biomeBackground(this.currentBiome));
      if (previousBiome && !settingsSystem.effectsReduced()) {
        const accent = BIOME_ACCENTS[this.currentBiome];
        this.cameras.main.flash(160, (accent >> 16) & 0xff, (accent >> 8) & 0xff, accent & 0xff, false);
      }
      this.showBiomeBanner(active.chunk);
      this.refreshAmbientMotes(active.chunk.biome);
      this.refreshAtmosphere(active.chunk.biome);
      this.playBiomeTransition(active.chunk.biome);
    }
  }

  private playBiomeTransition(biome: OutdoorBiome): void {
    const motifs: Record<OutdoorBiome, Array<{ frequency: number; durationMs: number }>> = {
      academy: [{ frequency: 392, durationMs: 90 }, { frequency: 523, durationMs: 120 }],
      ruins: [{ frequency: 196, durationMs: 130 }, { frequency: 247, durationMs: 150 }],
      geo: [{ frequency: 330, durationMs: 100 }, { frequency: 440, durationMs: 130 }],
      logic: [{ frequency: 262, durationMs: 80 }, { frequency: 524, durationMs: 80 }, { frequency: 659, durationMs: 110 }],
      wild: [{ frequency: 349, durationMs: 120 }, { frequency: 392, durationMs: 150 }],
      crystal: [{ frequency: 523, durationMs: 90 }, { frequency: 784, durationMs: 130 }],
    };
    audioManager.playToneSequence(motifs[biome]);
  }

  private biomeBackground(biome: OutdoorBiome): string {
    if (biome === "ruins") return "#100d14";
    if (biome === "geo") return "#071815";
    if (biome === "logic") return "#071221";
    if (biome === "wild") return "#071a12";
    if (biome === "crystal") return "#090d22";
    return "#071018";
  }

  private showBiomeBanner(chunk: OutdoorChunk): void {
    this.biomeBanner?.destroy(true);
    const accent = BIOME_ACCENTS[chunk.biome];
    const banner = this.add.container(640, 126).setDepth(180).setScrollFactor(0).setAlpha(0);
    banner.add(this.add.rectangle(0, 0, 420, 64, 0x061019, 0.88).setStrokeStyle(2, accent, 0.58));
    banner.add(this.add.rectangle(-202, -24, 5, 48, accent, 0.92));
    banner.add(this.add.text(-178, -18, BIOME_LABELS[chunk.biome], {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    banner.add(this.add.text(-178, 12, `zona ${chunk.chunkX}:${chunk.chunkY} · ${chunk.encounters.length} incontri vicini`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
      fontStyle: "bold",
    }));
    this.biomeBanner = banner;
    this.tweens.add({
      targets: banner,
      alpha: 1,
      y: 108,
      duration: 260,
      ease: "Cubic.easeOut",
      yoyo: true,
      hold: 1300,
      onComplete: () => {
        banner.destroy(true);
        if (this.biomeBanner === banner) this.biomeBanner = undefined;
      },
    });
  }

  private refreshAmbientMotes(biome: OutdoorBiome): void {
    this.ambientMotes.forEach((mote) => {
      this.tweens.killTweensOf(mote);
      mote.destroy();
    });
    this.ambientMotes = [];
    if (settingsSystem.effectsReduced() || !this.textures.exists("soft-glow")) return;
    const accent = BIOME_ACCENTS[biome];
    const count = biome === "crystal" ? 12 : biome === "wild" || biome === "geo" ? 9 : 7;
    for (let i = 0; i < count; i += 1) {
      const mote = this.add.image(Phaser.Math.Between(80, 1200), Phaser.Math.Between(112, 680), "soft-glow")
        .setTint(accent)
        .setAlpha(0.05)
        .setScale(Phaser.Math.FloatBetween(0.28, 0.72))
        .setDepth(58)
        .setScrollFactor(0);
      this.ambientMotes.push(mote);
      this.tweens.add({
        targets: mote,
        y: mote.y - Phaser.Math.Between(24, 76),
        x: mote.x + Phaser.Math.Between(-24, 24),
        alpha: Phaser.Math.FloatBetween(0.08, 0.16),
        duration: Phaser.Math.Between(2600, 4600),
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
        delay: i * 120,
      });
    }
  }

  private refreshAtmosphere(biome: OutdoorBiome): void {
    this.atmosphereGraphics?.clear();
    if (!this.atmosphereGraphics) {
      this.atmosphereGraphics = this.add.graphics().setScrollFactor(0).setDepth(56);
    }
    const accent = BIOME_ACCENTS[biome];
    const shadow = biome === "ruins" ? 0x2a1010 : biome === "crystal" ? 0x101444 : biome === "geo" || biome === "wild" ? 0x0d2b1d : 0x0b1d2b;
    this.atmosphereGraphics.fillStyle(shadow, 0.16);
    this.atmosphereGraphics.fillRect(0, 0, 1280, 720);
    this.atmosphereGraphics.fillStyle(0x000000, 0.18);
    this.atmosphereGraphics.fillRect(0, 0, 1280, 44);
    this.atmosphereGraphics.fillRect(0, 672, 1280, 48);
    this.atmosphereGraphics.fillStyle(accent, 0.035);
    for (let i = 0; i < 5; i += 1) {
      this.atmosphereGraphics.fillEllipse(160 + i * 260, 96 + (i % 2) * 504, 260, 58);
    }
  }

  private buildDayNightLayer(): void {
    this.dayNightOverlay = this.add.graphics().setScrollFactor(0).setDepth(59);
  }

  private updateDayNightCycle(force = false): void {
    const phase = phaseForOutdoorTime(this.time.now - this.dayCycleStartedAt);
    if (!force && phase === this.currentDayPhase) return;
    const previous = this.currentDayPhase;
    this.currentDayPhase = phase;
    this.refreshDayNightOverlay();
    this.refreshDayPhaseHud();
    this.refreshHazardVisibility();
    if (!force && previous !== phase) this.playDayPhaseCue(phase);
  }

  private refreshDayNightOverlay(): void {
    if (!this.dayNightOverlay) return;
    const overlay = this.dayNightOverlay;
    overlay.clear();
    const config: Record<OutdoorDayPhase, { color: number; alpha: number; horizon: number; stars: number }> = {
      day: { color: 0xfff1b8, alpha: 0.025, horizon: 0xf6c85f, stars: 0 },
      dusk: { color: 0x5e346d, alpha: 0.18, horizon: 0xff8f6b, stars: 10 },
      night: { color: 0x02071d, alpha: 0.42, horizon: 0x6b7dff, stars: 34 },
      dawn: { color: 0xb6f5ff, alpha: 0.1, horizon: 0x8fe0a4, stars: 5 },
    };
    const selected = config[this.currentDayPhase];
    overlay.fillStyle(selected.color, selected.alpha);
    overlay.fillRect(0, 0, 1280, 720);
    overlay.fillStyle(selected.horizon, this.currentDayPhase === "night" ? 0.08 : 0.11);
    overlay.fillEllipse(650, 696, 1160, 112);
    if (selected.stars <= 0) return;
    overlay.fillStyle(0xf5fbff, this.currentDayPhase === "night" ? 0.72 : 0.28);
    for (let index = 0; index < selected.stars; index += 1) {
      const x = 70 + ((index * 173) % 1140);
      const y = 72 + ((index * 89) % 420);
      const r = index % 5 === 0 ? 1.9 : 1.15;
      overlay.fillCircle(x, y, r);
    }
  }

  private refreshDayPhaseHud(): void {
    const risk = this.currentDayPhase === "night"
      ? "pericoli forti"
      : this.currentDayPhase === "dusk"
        ? "ombre in arrivo"
        : "pericoli lievi";
    const color = this.currentDayPhase === "night" ? "#c7b8ff" : this.currentDayPhase === "dusk" ? "#ffb48f" : "#f6c85f";
    this.dayPhaseText?.setText(`${OUTDOOR_PHASE_LABELS[this.currentDayPhase]} · ${risk}`);
    this.dayPhaseText?.setColor(color);
  }

  private playDayPhaseCue(phase: OutdoorDayPhase): void {
    const cues: Record<OutdoorDayPhase, Array<{ frequency: number; durationMs: number }>> = {
      day: [{ frequency: 523, durationMs: 100 }, { frequency: 659, durationMs: 120 }],
      dusk: [{ frequency: 330, durationMs: 120 }, { frequency: 247, durationMs: 160 }],
      night: [{ frequency: 196, durationMs: 180 }, { frequency: 147, durationMs: 220 }],
      dawn: [{ frequency: 392, durationMs: 100 }, { frequency: 523, durationMs: 130 }],
    };
    audioManager.playToneSequence(cues[phase]);
  }

  private updateAmbientSparkles(): void {
    if (!this.avatar || !this.currentBiome || settingsSystem.effectsReduced()) return;
    if (this.time.now - this.lastAmbientSparkAt < 420) return;
    this.lastAmbientSparkAt = this.time.now;
    const accent = BIOME_ACCENTS[this.currentBiome];
    const x = this.avatar.x + Phaser.Math.Between(-86, 86);
    const y = this.avatar.y + Phaser.Math.Between(-70, 56);
    const spark = this.add.circle(x, y, this.currentBiome === "crystal" ? 3.8 : 2.8, accent, 0.24).setDepth(6 + y / 10000);
    if (this.currentBiome === "logic") {
      spark.setStrokeStyle(1, 0x6be7d6, 0.46);
    } else if (this.currentBiome === "ruins") {
      spark.setFillStyle(0xff8f6b, 0.22);
    } else if (this.currentBiome === "geo") {
      spark.setStrokeStyle(1, 0x7ad7ff, 0.38);
    }
    this.tweens.add({
      targets: spark,
      y: y - Phaser.Math.Between(16, 42),
      x: x + Phaser.Math.Between(-18, 18),
      alpha: 0,
      scale: 1.8,
      duration: 900,
      ease: "Sine.easeOut",
      onComplete: () => spark.destroy(),
    });
  }

  private beginMapOverlay(depth: number): Phaser.GameObjects.Container {
    this.clearMoveTarget();
    this.cameras.main.stopFollow();
    this.cameras.main.setScroll(0, 0);
    return this.add.container(0, 0).setDepth(depth).setScrollFactor(0);
  }

  private closeMapOverlay(overlay: Phaser.GameObjects.Container, afterClose?: () => void): void {
    if (!overlay.active) return;
    overlay.destroy(true);
    this.paused = false;
    this.cameras.main.startFollow(this.avatar, true, 0.12, 0.12);
    afterClose?.();
  }

  private destroyChunkObject(object: Phaser.GameObjects.GameObject): void {
    this.tweens.killTweensOf(object);
    if (object instanceof Phaser.GameObjects.Container) {
      object.list.forEach((child) => this.tweens.killTweensOf(child));
    }
    object.destroy();
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
    this.drawPaintedChunkBase(chunk, objects);
    const g = this.add.graphics();
    g.setDepth(-16);
    objects.push(g);
    g.fillStyle(BIOME_PAINTED_BACKDROPS[chunk.biome].veil, 0.34);
    g.fillRect(chunk.worldX - 6, chunk.worldY - 6, chunk.size + 12, chunk.size + 12);
    this.drawPaintedTerrainWash(g, chunk);
    this.drawAtmosphericDepth(g, chunk);
    this.drawBiomeSilhouette(g, chunk);
    this.drawContinuousGroundTexture(g, chunk);
    this.drawBiomeGroundMotifs(g, chunk);
    const terrainBase = this.variedColor(chunk.patch.color, this.visualNoise(chunk.id, 901) * 0.14 - 0.07);
    g.fillStyle(terrainBase, 0.28);
    g.fillEllipse(chunk.worldX + chunk.size / 2, chunk.worldY + chunk.size / 2, chunk.size * 1.18, chunk.size * 1.06);
    g.fillStyle(terrainBase, 0.22);
    g.fillEllipse(chunk.patch.x + chunk.patch.w / 2, chunk.patch.y + chunk.patch.h / 2, chunk.patch.w * 1.08, chunk.patch.h * 1.02);
    this.drawPaintedPatchGlaze(g, chunk);
    this.drawBiomeEdges(g, chunk);
    this.drawTerrainDetails(g, chunk);
    this.drawCozyLandscape(chunk, objects);
    this.drawAmbientAccents(chunk, objects);
    objects.push(this.add.text(chunk.patch.x + 34, chunk.patch.y + 28, BIOME_LABELS[chunk.biome], {
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
    generateOutdoorHazardsForChunk(chunk, this.worldSeed).forEach((hazard) => this.drawHazard(hazard, objects));
    return objects;
  }

  private drawPaintedChunkBase(chunk: OutdoorChunk, objects: Phaser.GameObjects.GameObject[]): void {
    const backdrop = BIOME_PAINTED_BACKDROPS[chunk.biome];
    if (!this.textures.exists(backdrop.key)) return;
    const texture = this.textures.get(backdrop.key);
    const source = texture.getSourceImage() as { width?: number; height?: number };
    const sourceWidth = source.width ?? 1280;
    const sourceHeight = source.height ?? 720;
    const cropSize = Math.max(1, Math.min(sourceWidth, sourceHeight));
    const cropX = Math.round((sourceWidth - cropSize) * this.visualNoise(chunk.id, 1101));
    const cropY = Math.round((sourceHeight - cropSize) * this.visualNoise(chunk.id, 1102));
    const image = this.add.image(chunk.worldX + chunk.size / 2, chunk.worldY + chunk.size / 2, backdrop.key)
      .setDepth(-18)
      .setAlpha(backdrop.alpha)
      .setDisplaySize(chunk.size + 26, chunk.size + 26);
    image.setCrop(cropX, cropY, cropSize, cropSize);
    if (backdrop.tint !== undefined) image.setTint(backdrop.tint);
    objects.push(image);
  }

  private drawPaintedTerrainWash(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const accent = BIOME_ACCENTS[chunk.biome];
    const palette = BIOME_DETAIL_COLORS[chunk.biome];
    for (let i = 0; i < 18; i += 1) {
      const x = chunk.worldX - 160 + this.visualNoise(chunk.id, 1200 + i * 4) * (chunk.size + 320);
      const y = chunk.worldY - 150 + this.visualNoise(chunk.id, 1201 + i * 4) * (chunk.size + 300);
      const w = 300 + this.visualNoise(chunk.id, 1202 + i * 4) * 620;
      const h = 74 + this.visualNoise(chunk.id, 1203 + i * 4) * 180;
      const color = i % 3 === 0 ? accent : palette[i % palette.length]!;
      g.fillStyle(color, 0.028 + this.visualNoise(chunk.id, 1240 + i) * 0.032);
      g.fillEllipse(x, y, w, h);
    }
  }

  private drawAtmosphericDepth(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const x = chunk.worldX;
    const y = chunk.worldY;
    const s = chunk.size;
    const accent = BIOME_ACCENTS[chunk.biome];
    const backdrop = BIOME_PAINTED_BACKDROPS[chunk.biome];
    g.fillStyle(0xffffff, 0.026);
    g.fillEllipse(x + s * 0.32, y + s * 0.17, s * 0.78, s * 0.22);
    g.fillStyle(backdrop.veil, 0.12);
    g.fillEllipse(x + s * 0.62, y + s * 0.86, s * 1.2, s * 0.36);
    g.fillStyle(accent, 0.035);
    g.fillEllipse(x + s * (0.24 + this.visualNoise(chunk.id, 1260) * 0.5), y + s * 0.56, s * 0.54, s * 0.92);
    g.lineStyle(2, accent, 0.08);
    g.strokeEllipse(x + s * 0.5, y + s * 0.52, s * 0.96, s * 0.82);
  }

  private drawContinuousGroundTexture(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const palette = BIOME_DETAIL_COLORS[chunk.biome];
    const grid = 112;
    const startX = Math.floor((chunk.worldX - 96) / grid) * grid;
    const endX = chunk.worldX + chunk.size + 96;
    const startY = Math.floor((chunk.worldY - 96) / grid) * grid;
    const endY = chunk.worldY + chunk.size + 96;
    for (let x = startX; x <= endX; x += grid) {
      for (let y = startY; y <= endY; y += grid) {
        const n = this.visualNoise(`${this.worldSeed}:ground:${Math.floor(x / grid)}:${Math.floor(y / grid)}`, 7);
        const color = palette[Math.floor(n * palette.length) % palette.length]!;
        g.fillStyle(color, 0.035 + n * 0.035);
        if (n > 0.66) {
          g.fillEllipse(x + 28 + n * 42, y + 38, 120 + n * 90, 22 + n * 22);
        } else if (n > 0.34) {
          g.fillCircle(x + 38 + n * 36, y + 42 + n * 22, 2 + n * 4);
          g.fillCircle(x + 84, y + 78, 1.6 + n * 3);
        } else {
          g.lineStyle(1, color, 0.05);
          g.lineBetween(x + 16, y + 54, x + 102, y + 48 + n * 30);
        }
      }
    }
  }

  private drawBiomeGroundMotifs(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const palette = BIOME_DETAIL_COLORS[chunk.biome];
    const accent = BIOME_ACCENTS[chunk.biome];
    const x = chunk.worldX;
    const y = chunk.worldY;
    const s = chunk.size;
    if (chunk.biome === "logic") {
      g.lineStyle(2, accent, 0.13);
      for (let i = 0; i < 10; i += 1) {
        const sx = x + 76 + this.visualNoise(chunk.id, 2100 + i * 3) * (s - 152);
        const sy = y + 84 + this.visualNoise(chunk.id, 2101 + i * 3) * (s - 168);
        const w = 46 + this.visualNoise(chunk.id, 2102 + i * 3) * 92;
        g.lineBetween(sx, sy, sx + w, sy);
        g.lineBetween(sx + w, sy, sx + w, sy + 24);
        g.fillStyle(i % 2 === 0 ? 0x6be7d6 : 0xf6c85f, 0.18);
        g.fillCircle(sx + w, sy + 24, 4);
      }
      return;
    }
    if (chunk.biome === "geo") {
      g.lineStyle(2, 0x7ad7ff, 0.12);
      for (let i = 0; i < 7; i += 1) {
        const cx = x + 150 + this.visualNoise(chunk.id, 2140 + i) * (s - 300);
        const cy = y + 130 + i * 78;
        g.strokeEllipse(cx, cy, 360 - i * 24, 56 + i * 12);
      }
      g.lineStyle(5, 0x7ad7ff, 0.1);
      for (let i = 0; i < 3; i += 1) {
        const yy = y + 170 + this.visualNoise(chunk.id, 2160 + i) * (s - 340);
        g.lineBetween(x + 72, yy, x + s * 0.38, yy + 42);
        g.lineBetween(x + s * 0.38, yy + 42, x + s - 70, yy - 16);
      }
      return;
    }
    if (chunk.biome === "crystal") {
      for (let i = 0; i < 16; i += 1) {
        const px = x + 62 + this.visualNoise(chunk.id, 2180 + i * 3) * (s - 124);
        const py = y + 66 + this.visualNoise(chunk.id, 2181 + i * 3) * (s - 132);
        const h = 18 + this.visualNoise(chunk.id, 2182 + i * 3) * 42;
        g.fillStyle(palette[i % palette.length]!, 0.1);
        g.fillTriangle(px, py - h, px - h * 0.32, py + h * 0.2, px + h * 0.3, py + h * 0.2);
        g.lineStyle(1, 0xffffff, 0.12);
        g.strokeTriangle(px, py - h, px - h * 0.32, py + h * 0.2, px + h * 0.3, py + h * 0.2);
      }
      return;
    }
    if (chunk.biome === "ruins") {
      g.lineStyle(2, 0xff8f6b, 0.13);
      for (let i = 0; i < 12; i += 1) {
        const px = x + 72 + this.visualNoise(chunk.id, 2220 + i * 3) * (s - 144);
        const py = y + 78 + this.visualNoise(chunk.id, 2221 + i * 3) * (s - 156);
        const len = 32 + this.visualNoise(chunk.id, 2222 + i * 3) * 78;
        g.lineBetween(px, py, px + len * 0.38, py + 18);
        g.lineBetween(px + len * 0.38, py + 18, px + len, py - 8);
      }
      return;
    }
    if (chunk.biome === "wild") {
      for (let i = 0; i < 22; i += 1) {
        const px = x + 58 + this.visualNoise(chunk.id, 2260 + i * 3) * (s - 116);
        const py = y + 62 + this.visualNoise(chunk.id, 2261 + i * 3) * (s - 124);
        const color = palette[i % palette.length]!;
        g.fillStyle(color, 0.12);
        g.fillEllipse(px, py, 26, 8);
        g.fillEllipse(px + 12, py - 5, 20, 7);
      }
      return;
    }
    g.lineStyle(2, accent, 0.1);
    for (let i = 0; i < 9; i += 1) {
      const px = x + 82 + this.visualNoise(chunk.id, 2300 + i * 3) * (s - 164);
      const py = y + 86 + this.visualNoise(chunk.id, 2301 + i * 3) * (s - 172);
      g.strokeRoundedRect(px, py, 54 + this.visualNoise(chunk.id, 2302 + i * 3) * 78, 18, 8);
    }
  }

  private drawPaintedPatchGlaze(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const accent = BIOME_ACCENTS[chunk.biome];
    const x = chunk.worldX + 26;
    const y = chunk.worldY + 28;
    const w = chunk.size - 52;
    const h = chunk.size - 56;
    g.fillStyle(0xffffff, 0.035);
    g.fillEllipse(x + w * 0.44, y + h * 0.18, w * 0.78, Math.max(50, h * 0.2));
    g.fillStyle(0x02070b, 0.05);
    g.fillEllipse(x + w * 0.55, y + h * 0.78, w * 0.96, h * 0.28);
    g.lineStyle(3, accent, 0.08);
    for (let i = 0; i < 9; i += 1) {
      const yy = y + 58 + this.visualNoise(chunk.id, 1320 + i) * Math.max(1, h - 116);
      g.lineBetween(x + 48, yy, x + w - 48, yy + (this.visualNoise(chunk.id, 1330 + i) - 0.5) * 28);
    }
  }

  private drawBiomeSilhouette(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const x = chunk.worldX;
    const y = chunk.worldY;
    const s = chunk.size;
    const accent = BIOME_ACCENTS[chunk.biome];
    g.fillStyle(0x02070b, 0.18);
    g.lineStyle(3, accent, 0.12);
    if (chunk.biome === "academy") {
      for (let i = 0; i < 4; i += 1) {
        const px = x + 118 + i * 164;
        g.fillRoundedRect(px, y + 98, 34, 194, 12);
        g.strokeRoundedRect(px, y + 98, 34, 194, 12);
      }
      g.strokeCircle(x + s - 168, y + 170, 70);
      g.lineBetween(x + s - 238, y + 170, x + s - 98, y + 170);
      return;
    }
    if (chunk.biome === "logic") {
      for (let i = 0; i < 5; i += 1) {
        const px = x + 96 + i * 138;
        const h = 96 + this.visualNoise(chunk.id, 1500 + i) * 160;
        g.fillRect(px, y + s - 140 - h, 44, h);
        g.strokeRect(px, y + s - 140 - h, 44, h);
        g.fillCircle(px + 22, y + s - 154 - h, 7);
      }
      for (let i = 0; i < 6; i += 1) {
        const yy = y + 160 + i * 82;
        g.lineBetween(x + 90, yy, x + s - 90, yy + (i % 2 === 0 ? 34 : -24));
      }
      return;
    }
    if (chunk.biome === "geo") {
      g.fillTriangle(x + 82, y + s - 126, x + 254, y + 234, x + 420, y + s - 126);
      g.fillTriangle(x + 306, y + s - 120, x + 526, y + 188, x + 746, y + s - 120);
      g.strokeTriangle(x + 82, y + s - 126, x + 254, y + 234, x + 420, y + s - 126);
      g.strokeTriangle(x + 306, y + s - 120, x + 526, y + 188, x + 746, y + s - 120);
      for (let i = 0; i < 5; i += 1) {
        g.strokeEllipse(x + 452, y + 188 + i * 54, 420 - i * 42, 96 + i * 18);
      }
      return;
    }
    if (chunk.biome === "ruins") {
      for (let i = 0; i < 5; i += 1) {
        const px = x + 106 + i * 142;
        const h = 94 + this.visualNoise(chunk.id, 1540 + i) * 140;
        g.fillRect(px, y + s - 112 - h, 42, h);
        g.strokeRect(px, y + s - 112 - h, 42, h);
        if (i % 2 === 0) g.lineBetween(px - 12, y + s - 126 - h, px + 64, y + s - 94 - h);
      }
      g.strokeCircle(x + s - 170, y + 190, 58);
      g.lineBetween(x + s - 210, y + 230, x + s - 110, y + 124);
      return;
    }
    if (chunk.biome === "crystal") {
      for (let i = 0; i < 9; i += 1) {
        const px = x + 92 + this.visualNoise(chunk.id, 1580 + i) * (s - 184);
        const base = y + s - 96 - this.visualNoise(chunk.id, 1590 + i) * 210;
        const h = 92 + this.visualNoise(chunk.id, 1600 + i) * 160;
        g.fillTriangle(px, base, px - 32, base + h, px + 34, base + h);
        g.strokeTriangle(px, base, px - 32, base + h, px + 34, base + h);
      }
      return;
    }
    for (let i = 0; i < 7; i += 1) {
      const px = x + 90 + i * 112;
      const py = y + s - 124 - this.visualNoise(chunk.id, 1640 + i) * 80;
      g.fillRect(px, py - 94, 20, 120);
      g.fillCircle(px, py - 124, 66);
      g.strokeCircle(px, py - 124, 66);
    }
  }

  private drawPaths(g: Phaser.GameObjects.Graphics, points = this.map.pathPoints.length > 1 ? this.map.pathPoints : [this.map.start], landmarks = this.map.landmarks): void {
    g.lineStyle(56, 0x02070b, 0.16);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y + 10, points[i + 1]!.x, points[i + 1]!.y + 10);
    g.lineStyle(44, 0x132a33, 0.62);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y, points[i + 1]!.x, points[i + 1]!.y);
    g.lineStyle(16, 0x9ff5e9, 0.045);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y - 2, points[i + 1]!.x, points[i + 1]!.y - 2);
    g.lineStyle(4, 0xf6c85f, 0.2);
    for (let i = 0; i < points.length - 1; i += 1) g.lineBetween(points[i]!.x, points[i]!.y, points[i + 1]!.x, points[i + 1]!.y);
    const hub = points[1];
    if (!hub) return;
    g.lineStyle(22, 0x02070b, 0.12);
    landmarks.forEach((landmark) => g.lineBetween(hub.x, hub.y + 5, landmark.x, landmark.y + 5));
    g.lineStyle(18, 0x10242d, 0.36);
    landmarks.forEach((landmark) => g.lineBetween(hub.x, hub.y, landmark.x, landmark.y));
    g.lineStyle(2, 0x9ff5e9, 0.14);
    landmarks.forEach((landmark) => g.lineBetween(hub.x, hub.y, landmark.x, landmark.y));
  }

  private drawTerrainDetails(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const palette = BIOME_DETAIL_COLORS[chunk.biome];
    for (let i = 0; i < 58; i += 1) {
      const nx = this.visualNoise(chunk.id, i * 3);
      const ny = this.visualNoise(chunk.id, i * 3 + 1);
      const nv = this.visualNoise(chunk.id, i * 3 + 2);
      const x = chunk.worldX + 54 + nx * (chunk.size - 108);
      const y = chunk.worldY + 54 + ny * (chunk.size - 108);
      const color = palette[i % palette.length]!;
      g.fillStyle(color, chunk.biome === "crystal" ? 0.18 : 0.12);
      g.lineStyle(1, color, 0.16);
      if (chunk.biome === "logic") {
        g.strokeRect(x, y, 18 + nv * 38, 8 + nv * 18);
        if (i % 3 === 0) g.lineBetween(x - 18, y + 4, x + 32, y + 4);
      } else if (chunk.biome === "ruins") {
        g.lineBetween(x - 18, y, x - 4, y + 10);
        g.lineBetween(x - 4, y + 10, x + 20, y - 8);
      } else if (chunk.biome === "geo") {
        g.fillEllipse(x, y, 24 + nv * 42, 8 + nv * 12);
      } else if (chunk.biome === "crystal") {
        g.fillTriangle(x, y - 10, x - 8, y + 10, x + 8, y + 10);
      } else if (chunk.biome === "wild") {
        g.fillCircle(x, y, 3 + nv * 7);
        g.fillEllipse(x + 8, y - 4, 14, 5);
      } else {
        g.fillRoundedRect(x, y, 18 + nv * 26, 4 + nv * 8, 3);
      }
    }
  }

  private drawCozyLandscape(chunk: OutdoorChunk, objects: Phaser.GameObjects.GameObject[]): void {
    const count = 7 + Math.floor(this.visualNoise(chunk.id, 1740) * 5);
    for (let i = 0; i < count; i += 1) {
      const x = chunk.patch.x + 82 + this.visualNoise(chunk.id, 1750 + i * 5) * (chunk.patch.w - 164);
      const y = chunk.patch.y + 86 + this.visualNoise(chunk.id, 1751 + i * 5) * (chunk.patch.h - 172);
      if (!this.isCozySpotClear(chunk, x, y)) continue;
      const kind = this.cozyLandscapeKind(chunk, i);
      const scale = 0.78 + this.visualNoise(chunk.id, 1752 + i * 5) * 0.34;
      const c = this.add.container(x, y).setDepth(1.8 + y / 10000).setScale(scale);
      objects.push(c);
      this.drawCozyLandscapeItem(c, kind, chunk, i);
    }
  }

  private isCozySpotClear(chunk: OutdoorChunk, x: number, y: number): boolean {
    const busy = [
      ...chunk.landmarks.map((item) => ({ x: item.x, y: item.y, r: 140 })),
      ...chunk.treasures.map((item) => ({ x: item.x, y: item.y, r: 90 })),
      ...chunk.encounters.map((item) => ({ x: item.x, y: item.y, r: 96 })),
      ...chunk.obstacles.map((item) => ({ x: item.x, y: item.y, r: item.r + 54 })),
    ];
    return busy.every((item) => Math.hypot(item.x - x, item.y - y) > item.r);
  }

  private cozyLandscapeKind(chunk: OutdoorChunk, index: number): CozyLandscapeKind {
    const options: Record<OutdoorBiome, CozyLandscapeKind[]> = {
      academy: ["flowerPatch", "fence", "bench", "signpost", "gardenBed", "roundTree"],
      ruins: ["steppingStones", "signpost", "bench", "flowerPatch", "fence"],
      geo: ["pond", "steppingStones", "flowerPatch", "signpost", "roundTree", "bench"],
      logic: ["bench", "signpost", "gardenBed", "steppingStones", "fence"],
      wild: ["roundTree", "flowerPatch", "pond", "gardenBed", "fence", "steppingStones"],
      crystal: ["flowerPatch", "steppingStones", "pond", "signpost", "gardenBed"],
    };
    const list = options[chunk.biome];
    return list[Math.floor(this.visualNoise(chunk.id, 1780 + index) * list.length)]!;
  }

  private drawCozyLandscapeItem(container: Phaser.GameObjects.Container, kind: CozyLandscapeKind, chunk: OutdoorChunk, index: number): void {
    const accent = BIOME_ACCENTS[chunk.biome];
    const palette = BIOME_DETAIL_COLORS[chunk.biome];
    if (kind === "roundTree") {
      if (this.addOutdoorSprite(container, "out_tree_round", 96, 96, -8)) return;
      const trunk = chunk.biome === "crystal" ? 0x575078 : 0x6a4428;
      const leaf = chunk.biome === "academy" ? 0x2f8a72 : chunk.biome === "geo" ? 0x3b9d60 : chunk.biome === "wild" ? 0x287345 : accent;
      container.add(this.add.ellipse(0, 34, 68, 16, 0x000000, 0.18));
      container.add(this.add.rectangle(0, 15, 14, 42, trunk, 0.94));
      const crown = this.add.container(0, -14);
      container.add(crown);
      crown.add(this.add.circle(-20, 2, 25, leaf, 0.95).setStrokeStyle(2, 0xf5fbff, 0.09));
      crown.add(this.add.circle(5, -12, 31, this.variedColor(leaf, 0.08), 0.96).setStrokeStyle(2, 0xf5fbff, 0.1));
      crown.add(this.add.circle(24, 4, 23, this.variedColor(leaf, -0.07), 0.94));
      for (let i = 0; i < 3; i += 1) {
        crown.add(this.add.circle(-18 + i * 18, -10 + (i % 2) * 18, 4, i % 2 === 0 ? 0xf6c85f : 0xff8f6b, 0.76));
      }
      if (!settingsSystem.effectsReduced()) this.tweens.add({ targets: crown, y: -17, duration: 1800 + index * 90, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      return;
    }
    if (kind === "flowerPatch") {
      if (this.addOutdoorSprite(container, "out_flower_patch", 88, 58, 4, accent, 0.95)) return;
      container.add(this.add.ellipse(0, 12, 74, 30, chunk.biome === "crystal" ? 0x222950 : 0x14382b, 0.62).setStrokeStyle(1, accent, 0.18));
      for (let i = 0; i < 9; i += 1) {
        const x = -30 + (i % 5) * 15 + (i > 4 ? 8 : 0);
        const y = 5 + Math.floor(i / 5) * 12 + (i % 2) * 3;
        const color = palette[(i + index) % palette.length]!;
        container.add(this.add.line(0, 0, x, y + 8, x, y - 5, 0x8fe0a4, 0.34).setOrigin(0));
        container.add(this.add.circle(x, y - 6, 5, color, 0.88));
        container.add(this.add.circle(x, y - 6, 2, 0xf6c85f, 0.82));
      }
      return;
    }
    if (kind === "fence") {
      container.add(this.add.ellipse(0, 18, 110, 18, 0x000000, 0.12));
      for (let i = 0; i < 5; i += 1) {
        const x = -46 + i * 23;
        container.add(this.add.rectangle(x, 0, 7, 38, 0xf1c27a, 0.9).setStrokeStyle(1, 0x4a321d, 0.24));
        container.add(this.add.triangle(x, -25, -5, 0, 0, -8, 5, 0, 0xf6d99a, 0.9));
      }
      container.add(this.add.rectangle(0, -8, 104, 6, 0xf1c27a, 0.82));
      container.add(this.add.rectangle(0, 9, 104, 6, 0xd9a15f, 0.82));
      return;
    }
    if (kind === "pond") {
      if (this.addOutdoorSprite(container, "out_geo_pond", 104, 66, 6)) return;
      container.add(this.add.ellipse(0, 10, 100, 54, 0x123246, 0.86).setStrokeStyle(3, 0x7ad7ff, 0.34));
      container.add(this.add.ellipse(-8, 4, 72, 28, 0x2d9bbf, 0.26));
      container.add(this.add.ellipse(18, 13, 42, 14, 0x9ff5e9, 0.18));
      for (let i = 0; i < 4; i += 1) {
        container.add(this.add.ellipse(-48 + i * 31, 33 + (i % 2) * 3, 16, 8, 0x6c6575, 0.76));
      }
      container.add(this.add.line(0, 0, -38, -4, -25, -30, 0x8fe0a4, 0.42).setOrigin(0));
      container.add(this.add.line(0, 0, -30, -4, -14, -26, 0x8fe0a4, 0.34).setOrigin(0));
      return;
    }
    if (kind === "signpost") {
      container.add(this.add.ellipse(0, 28, 54, 12, 0x000000, 0.15));
      container.add(this.add.rectangle(0, 8, 8, 56, 0x6a4428, 0.94));
      container.add(this.add.rectangle(0, -18, 76, 30, 0xd9a15f, 0.94).setStrokeStyle(2, 0x4a321d, 0.34));
      container.add(this.add.triangle(45, -18, -3, -15, -3, 15, 18, 0, 0xd9a15f, 0.94).setStrokeStyle(1, 0x4a321d, 0.24));
      container.add(this.add.text(-6, -18, "?", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#173b36", fontStyle: "bold" }).setOrigin(0.5));
      return;
    }
    if (kind === "bench") {
      if (this.addOutdoorSprite(container, "out_bench_cozy", 96, 62, 5)) return;
      container.add(this.add.ellipse(0, 26, 86, 14, 0x000000, 0.16));
      container.add(this.add.rectangle(0, -6, 82, 11, 0xd9a15f, 0.94).setStrokeStyle(1, 0x4a321d, 0.22));
      container.add(this.add.rectangle(0, 9, 88, 11, 0xf1c27a, 0.92).setStrokeStyle(1, 0x4a321d, 0.2));
      container.add(this.add.rectangle(-28, 24, 7, 28, 0x4a321d, 0.84));
      container.add(this.add.rectangle(28, 24, 7, 28, 0x4a321d, 0.84));
      return;
    }
    if (kind === "steppingStones") {
      for (let i = 0; i < 6; i += 1) {
        const x = -42 + i * 17;
        const y = Math.sin(i * 0.9) * 10;
        container.add(this.add.ellipse(x, y, 21, 13, i % 2 === 0 ? 0x7f8790 : 0x6c6575, 0.78).setStrokeStyle(1, 0xdde9ef, 0.12));
      }
      return;
    }
    container.add(this.add.ellipse(0, 20, 92, 28, 0x000000, 0.13));
    container.add(this.add.rectangle(0, 4, 86, 38, chunk.biome === "logic" ? 0x10242d : 0x5a3a22, 0.9).setStrokeStyle(2, accent, 0.28));
    for (let row = 0; row < 3; row += 1) {
      const y = -8 + row * 12;
      container.add(this.add.line(0, 0, -36, y, 36, y, 0xf1c27a, 0.2).setOrigin(0));
      for (let i = 0; i < 4; i += 1) {
        const x = -27 + i * 18 + (row % 2) * 4;
        container.add(this.add.ellipse(x, y - 3, 13, 6, palette[(i + row) % palette.length]!, 0.58));
      }
    }
  }

  private drawAmbientAccents(chunk: OutdoorChunk, objects: Phaser.GameObjects.GameObject[]): void {
    const accent = BIOME_ACCENTS[chunk.biome];
    const count = 3 + Math.floor(this.visualNoise(chunk.id, 830) * 3);
    for (let i = 0; i < count; i += 1) {
      const x = chunk.patch.x + 82 + this.visualNoise(chunk.id, 840 + i * 4) * (chunk.patch.w - 164);
      const y = chunk.patch.y + 92 + this.visualNoise(chunk.id, 841 + i * 4) * (chunk.patch.h - 184);
      const scale = 0.78 + this.visualNoise(chunk.id, 842 + i * 4) * 0.36;
      const c = this.add.container(x, y).setDepth(3 + y / 10000).setScale(scale);
      objects.push(c);
      if (this.textures.exists("soft-glow")) {
        c.add(this.add.image(0, 0, "soft-glow").setTint(accent).setAlpha(0.08).setScale(0.55));
      }
      if (chunk.biome === "logic") {
        c.add(this.add.rectangle(0, 0, 46, 18, 0x061019, 0.72).setStrokeStyle(1, accent, 0.42));
        c.add(this.add.circle(-15, 0, 4, 0x6be7d6, 0.58));
        c.add(this.add.circle(0, 0, 3, 0xf6c85f, 0.5));
        c.add(this.add.line(0, 0, -15, 0, 18, 0, accent, 0.34).setOrigin(0));
      } else if (chunk.biome === "ruins") {
        c.add(this.add.rectangle(0, 8, 34, 12, 0x4b4252, 0.72).setStrokeStyle(1, 0xff8f6b, 0.24));
        c.add(this.add.line(0, 0, -16, -2, 18, -14, 0xff8f6b, 0.32).setOrigin(0));
        c.add(this.add.circle(8, -18, 4, 0xff8f6b, 0.28));
      } else if (chunk.biome === "geo") {
        c.add(this.add.arc(0, 0, 24, 14, 166, false, 0x7ad7ff, 0.03).setStrokeStyle(3, 0x7ad7ff, 0.36));
        c.add(this.add.triangle(-4, -8, -10, 4, -2, -16, 8, 4, accent, 0.58));
        c.add(this.add.circle(15, 7, 4, 0x8fe0a4, 0.34));
      } else if (chunk.biome === "wild") {
        c.add(this.add.ellipse(-8, 0, 28, 8, 0x74f0c5, 0.24));
        c.add(this.add.ellipse(9, -4, 24, 7, 0x8fe0a4, 0.22));
        c.add(this.add.circle(0, -14, 4, 0xf6c85f, 0.28));
      } else if (chunk.biome === "crystal") {
        c.add(this.add.triangle(-10, 10, -20, 14, -10, -18, 1, 14, accent, 0.36).setStrokeStyle(1, 0xffffff, 0.16));
        c.add(this.add.triangle(10, 8, 0, 14, 10, -22, 22, 14, 0x7ad7ff, 0.32).setStrokeStyle(1, 0xffffff, 0.14));
      } else {
        c.add(this.add.rectangle(0, 0, 36, 10, 0x173b36, 0.48).setStrokeStyle(1, accent, 0.32));
        c.add(this.add.circle(-16, 0, 4, accent, 0.54));
        c.add(this.add.circle(16, 0, 4, 0xf6c85f, 0.4));
      }
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({
          targets: c,
          alpha: 0.48,
          y: y - 3,
          duration: 1600 + i * 240,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut",
        });
      }
    }
  }

  private drawBiomeEdges(g: Phaser.GameObjects.Graphics, chunk: OutdoorChunk): void {
    const accent = chunk.patch.accent;
    const x = chunk.worldX;
    const y = chunk.worldY;
    const s = chunk.size;
    for (let i = 0; i < 9; i += 1) {
      const px = x - 80 + this.visualNoise(chunk.id, 520 + i * 3) * (s + 160);
      const py = y - 80 + this.visualNoise(chunk.id, 521 + i * 3) * (s + 160);
      const wide = 180 + this.visualNoise(chunk.id, 522 + i * 3) * 340;
      g.fillStyle(accent, 0.025 + this.visualNoise(chunk.id, 720 + i) * 0.035);
      g.fillEllipse(px, py, wide, 36 + this.visualNoise(chunk.id, 730 + i) * 82);
    }
    for (let i = 0; i < 18; i += 1) {
      const px = x + this.visualNoise(`${this.worldSeed}:speck:${chunk.chunkX}:${chunk.chunkY}`, 620 + i) * s;
      const py = y + this.visualNoise(`${this.worldSeed}:speck:${chunk.chunkY}:${chunk.chunkX}`, 640 + i) * s;
      g.fillStyle(accent, 0.08);
      g.fillCircle(px, py, 1.4 + this.visualNoise(chunk.id, 720 + i) * 3.2);
    }
  }

  private variedColor(color: number, amount: number): number {
    const r = Phaser.Math.Clamp(((color >> 16) & 0xff) + Math.round(255 * amount), 0, 255);
    const g = Phaser.Math.Clamp(((color >> 8) & 0xff) + Math.round(255 * amount), 0, 255);
    const b = Phaser.Math.Clamp((color & 0xff) + Math.round(255 * amount), 0, 255);
    return (r << 16) | (g << 8) | b;
  }

  private visualNoise(seed: string, index: number): number {
    let h = 2166136261;
    const value = `${seed}:${index}`;
    for (let i = 0; i < value.length; i += 1) {
      h ^= value.charCodeAt(i);
      h = Math.imul(h, 16777619);
    }
    h += 0x6d2b79f5;
    let t = h;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  private addAtlasProp(container: Phaser.GameObjects.Container, frame: string, width: number, height: number, y = 0, tint?: number, alpha = 1): Phaser.GameObjects.Image | undefined {
    if (!this.textures.exists("environment-props") || !this.textures.getFrame("environment-props", frame)) return undefined;
    const image = this.add.image(0, y, "environment-props", frame).setDisplaySize(width, height).setAlpha(alpha);
    if (tint !== undefined) image.setTint(tint);
    container.add(image);
    return image;
  }

  private addOutdoorSprite(container: Phaser.GameObjects.Container, frame: string, width: number, height: number, y = 0, tint?: number, alpha = 1): Phaser.GameObjects.Image | undefined {
    if (!this.textures.exists("outdoor-world") || !this.textures.getFrame("outdoor-world", frame)) return undefined;
    const image = this.add.image(0, y, "outdoor-world", frame).setDisplaySize(width, height).setAlpha(alpha);
    if (tint !== undefined) image.setTint(tint);
    container.add(image);
    return image;
  }

  private drawProp(prop: OutdoorProp, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(prop.x, prop.y).setDepth(2 + prop.y / 10000);
    objects?.push(c);
    if (prop.kind === "lamp" && this.addOutdoorSprite(c, "out_lamp_post", 46, 74, -13)) {
      c.add(this.add.circle(0, -38, 28, prop.color, 0.2));
      return;
    }
    if (prop.kind === "bridge" && this.addOutdoorSprite(c, "out_bridge_plank", 124, 58, 0)) {
      return;
    }
    if (prop.kind === "garden" && this.addOutdoorSprite(c, "out_flower_patch", 92, 60, 8, prop.color, 0.95)) {
      return;
    }
    if (prop.kind === "lamp" && this.addAtlasProp(c, "env_pillar_light", 42, 70, -12)) {
      c.add(this.add.circle(0, -34, 24, prop.color, 0.18));
      return;
    }
    if (prop.kind === "camp" && this.addAtlasProp(c, "env_crate_stack", 76, 54, 10)) {
      c.add(this.add.circle(30, 30, 8, 0xf6c85f, 0.86));
      return;
    }
    if (prop.kind === "tower" && this.addAtlasProp(c, "env_terminal_kiosk", 62, 76, -8)) {
      c.add(this.add.circle(0, -34, 18, prop.color, 0.16));
      return;
    }
    if (prop.kind === "bridge" && this.addAtlasProp(c, "env_railing", 118, 44, 0, 0xf1c27a, 0.92)) {
      return;
    }
    if (prop.kind === "statue" && this.addAtlasProp(c, "env_robot_decor", 66, 78, -8)) {
      c.add(this.add.rectangle(0, 34, 70, 14, 0x4b4252, 0.9).setStrokeStyle(2, prop.color, 0.42));
      return;
    }
    if (prop.kind === "beacon" && this.addAtlasProp(c, "env_holo_beacon", 76, 92, -6)) {
      c.add(this.add.circle(0, -8, 54, prop.color, 0.14));
      return;
    }
    if (prop.kind === "garden" && this.addAtlasProp(c, "env_planter", 86, 46, 10)) {
      c.add(this.add.circle(-28, -10, 10, prop.color, 0.34));
      c.add(this.add.circle(24, -12, 8, 0xf6c85f, 0.28));
      return;
    }
    if (prop.kind === "well" && this.addAtlasProp(c, "env_plant_pod", 66, 62, 6, prop.color, 0.88)) {
      c.add(this.add.circle(0, 4, 30, 0x10242d, 0.35).setStrokeStyle(2, prop.color, 0.58));
      return;
    }
    if (prop.kind === "arch" && this.addAtlasProp(c, "env_wall_corner", 84, 84, -4, prop.color, 0.82)) {
      return;
    }
    if (prop.kind === "sign" && this.addAtlasProp(c, "env_terminal_wall", 66, 48, 0)) {
      c.add(this.add.text(0, 2, "?", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
      return;
    }
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
      const pine = obstacle.r <= 36;
      if (this.addOutdoorSprite(c, pine ? "out_tree_pine" : "out_tree_round", obstacle.r * 2.12, pine ? obstacle.r * 2.62 : obstacle.r * 2.12, -obstacle.r * 0.12, undefined, 0.96)) {
        return;
      }
    }
    if (obstacle.kind === "rock" && this.addOutdoorSprite(c, "out_rock_moss", obstacle.r * 1.9, obstacle.r * 1.2, 0, obstacle.color, 0.9)) {
      return;
    }
    if (obstacle.kind === "crystal" && this.addOutdoorSprite(c, "out_crystal_cluster", obstacle.r * 2.2, obstacle.r * 2.2, -obstacle.r * 0.08, obstacle.color, 0.94)) {
      return;
    }
    if (obstacle.kind === "ruin" && this.addOutdoorSprite(c, "out_ruin_column", obstacle.r * 1.45, obstacle.r * 2.05, -obstacle.r * 0.12, obstacle.color, 0.9)) {
      return;
    }
    if (obstacle.kind === "bush" && this.addOutdoorSprite(c, "out_bush_bloom", obstacle.r * 2.1, obstacle.r * 1.45, 0, obstacle.color, 0.92)) {
      return;
    }
    if (obstacle.kind === "pillar" && this.addAtlasProp(c, "env_pillar_square", obstacle.r * 1.55, obstacle.r * 2.55, -obstacle.r * 0.25, 0xc7b8ff, 0.78)) {
      c.add(this.add.ellipse(0, obstacle.r * 1.1, obstacle.r * 1.8, obstacle.r * 0.42, 0x000000, 0.22));
      return;
    }
    if (obstacle.kind === "rock" && obstacle.r > 34 && this.addAtlasProp(c, "env_floor_vent", obstacle.r * 2.1, obstacle.r * 0.92, 0, obstacle.color, 0.62)) {
      c.add(this.add.ellipse(0, 0, obstacle.r * 1.5, obstacle.r * 1.05, obstacle.color, 0.48).setStrokeStyle(2, 0xdde9ef, 0.14));
      return;
    }
    if (obstacle.kind === "tree") {
      c.add(this.add.rectangle(0, obstacle.r * 0.45, obstacle.r * 0.5, obstacle.r, 0x4a321d, 1));
      c.add(this.add.circle(0, -obstacle.r * 0.25, obstacle.r, obstacle.color, 0.94).setStrokeStyle(2, 0x8fe0a4, 0.36));
      return;
    }
    if (obstacle.kind === "crystal") {
      this.drawPremiumCrystalCluster(c, obstacle.r, obstacle.color, 0x9ff5e9, 0.86);
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

  private drawPremiumCrystalCluster(container: Phaser.GameObjects.Container, radius: number, baseColor: number, accent = 0x7ad7ff, alpha = 0.9): void {
    const scale = radius / 30;
    container.add(this.add.ellipse(0, radius * 0.72, radius * 2.45, radius * 0.46, 0x000000, 0.24));
    if (this.textures.exists("soft-glow")) {
      container.add(this.add.image(0, -radius * 0.12, "soft-glow").setTint(accent).setAlpha(0.12 * alpha).setScale(scale * 1.15));
    } else {
      container.add(this.add.circle(0, -radius * 0.18, radius * 1.15, accent, 0.08 * alpha));
    }
    const shards = [
      { x: -radius * 0.56, y: radius * 0.42, w: radius * 0.36, h: radius * 1.28, color: baseColor, tone: 0.72 },
      { x: -radius * 0.1, y: radius * 0.48, w: radius * 0.48, h: radius * 1.75, color: accent, tone: 0.86 },
      { x: radius * 0.44, y: radius * 0.5, w: radius * 0.34, h: radius * 1.22, color: 0xc7b8ff, tone: 0.62 },
      { x: radius * 0.72, y: radius * 0.58, w: radius * 0.22, h: radius * 0.82, color: 0xf5fbff, tone: 0.36 },
    ];
    shards.forEach((shard, index) => {
      const crystal = this.add.triangle(shard.x, shard.y, -shard.w, 0, 0, -shard.h, shard.w, 0, shard.color, shard.tone * alpha)
        .setStrokeStyle(1, 0xffffff, (0.22 + index * 0.04) * alpha);
      container.add(crystal);
      container.add(this.add.line(0, 0, shard.x - shard.w * 0.18, shard.y - shard.h * 0.14, shard.x + shard.w * 0.08, shard.y - shard.h * 0.78, 0xffffff, 0.22 * alpha).setOrigin(0));
    });
    container.add(this.add.ellipse(0, radius * 0.5, radius * 1.75, radius * 0.22, accent, 0.16 * alpha).setStrokeStyle(1, 0xffffff, 0.12 * alpha));
  }

  private drawLandmark(landmark: OutdoorLandmark, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(landmark.x, landmark.y).setDepth(5 + landmark.y / 10000);
    objects?.push(c);
    const accent = landmark.color;
    c.add(this.add.ellipse(0, 44, 138, 32, 0x000000, 0.24));
    if (this.textures.exists("soft-glow")) {
      const glow = this.add.image(0, -8, "soft-glow").setTint(accent).setAlpha(0.2).setScale(3.2);
      c.add(glow);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: glow, alpha: 0.1, scale: 3.85, duration: 1600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    } else {
      c.add(this.add.circle(0, -10, 78, accent, 0.09));
    }
    if (landmark.kind === "forge") {
      c.add(this.add.rectangle(0, 14, 86, 72, 0x2a1f3a, 0.96).setStrokeStyle(3, accent, 0.75));
      c.add(this.add.triangle(0, -54, -56, -18, 56, -18, 0x4a321d, 0.94).setStrokeStyle(2, 0xf6c85f, 0.45));
      const lava = this.add.circle(0, 18, 18, 0xf6c85f, 0.75);
      c.add(lava);
      c.add(this.add.rectangle(-28, -4, 18, 54, 0x4b4252, 0.88).setStrokeStyle(2, 0xf6c85f, 0.28));
      c.add(this.add.circle(-28, -36, 10, 0xff8f6b, 0.32));
      this.decorateForgeLandmark(c, lava);
    } else if (landmark.kind === "atlasGate") {
      c.add(this.add.arc(0, -2, 58, 190, 350, false, accent, 0.9).setStrokeStyle(10, accent, 0.62));
      c.add(this.add.rectangle(-46, 18, 18, 92, 0x173b36, 0.96).setStrokeStyle(2, accent, 0.55));
      c.add(this.add.rectangle(46, 18, 18, 92, 0x173b36, 0.96).setStrokeStyle(2, accent, 0.55));
      c.add(this.add.circle(0, 12, 22, 0x145f78, 0.72).setStrokeStyle(2, 0x9ff5e9, 0.72));
      c.add(this.add.circle(0, 12, 42, 0x7ad7ff, 0.1).setStrokeStyle(2, 0x9ff5e9, 0.34));
      this.decorateAtlasLandmark(c, accent);
    } else if (landmark.kind === "logicSpire") {
      this.drawPremiumLogicSpire(c, accent);
      this.decorateLogicLandmark(c);
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
      this.drawPremiumCrystalCluster(c, 38, accent, 0x7ad7ff, 0.82);
      c.add(this.add.circle(0, -10, 20, 0xffffff, 0.42));
      this.decorateCrystalLandmark(c, accent);
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

  private drawPremiumLogicSpire(container: Phaser.GameObjects.Container, accent: number): void {
    container.add(this.add.ellipse(0, 48, 120, 28, 0x000000, 0.22));
    container.add(this.add.ellipse(0, 34, 112, 34, 0x101b30, 0.96).setStrokeStyle(2, accent, 0.42));
    container.add(this.add.rectangle(0, 30, 82, 18, 0x18283f, 0.96).setStrokeStyle(1, 0x6be7d6, 0.34));
    container.add(this.add.rectangle(-34, -6, 13, 78, 0x132451, 0.94).setStrokeStyle(1, accent, 0.42));
    container.add(this.add.rectangle(34, -6, 13, 78, 0x132451, 0.94).setStrokeStyle(1, accent, 0.42));
    container.add(this.add.rectangle(0, -14, 34, 104, 0x101b30, 0.98).setStrokeStyle(2, accent, 0.7));
    container.add(this.add.rectangle(0, -14, 10, 96, accent, 0.16));
    container.add(this.add.rectangle(0, -54, 72, 9, accent, 0.24).setStrokeStyle(1, 0xffffff, 0.18));
    container.add(this.add.circle(0, -78, 18, 0x061019, 0.96).setStrokeStyle(3, accent, 0.82));
    container.add(this.add.circle(0, -78, 7, 0xf5fbff, 0.78));
    const orbit = this.add.container(0, -78);
    orbit.add(this.add.arc(0, 0, 34, 0, 360, false, accent, 0.08).setStrokeStyle(2, accent, 0.34));
    orbit.add(this.add.circle(34, 0, 4, 0xf6c85f, 0.86));
    orbit.add(this.add.circle(-34, 0, 3, 0x6be7d6, 0.78));
    container.add(orbit);
    for (let i = 0; i < 3; i += 1) {
      const y = -34 + i * 28;
      container.add(this.add.line(0, 0, -45, y, -18, y + 8, 0x6be7d6, 0.32).setOrigin(0));
      container.add(this.add.line(0, 0, 18, y + 5, 47, y - 3, 0x9f8cff, 0.3).setOrigin(0));
    }
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: orbit, rotation: Math.PI * 2, duration: 5200, repeat: -1, ease: "Linear" });
    }
  }

  private decorateForgeLandmark(container: Phaser.GameObjects.Container, lava: Phaser.GameObjects.Arc): void {
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: lava, alpha: 0.42, scale: 1.18, duration: 780, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
    for (let i = 0; i < 3; i += 1) {
      const smoke = this.add.circle(-30 + i * 8, -48 - i * 4, 7 + i * 2, 0xdde9ef, 0.13);
      container.add(smoke);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({
          targets: smoke,
          y: smoke.y - 28,
          x: smoke.x + 6,
          alpha: 0,
          scale: 1.7,
          duration: 1600 + i * 280,
          repeat: -1,
          delay: i * 260,
          ease: "Sine.easeOut",
        });
      }
    }
  }

  private decorateAtlasLandmark(container: Phaser.GameObjects.Container, accent: number): void {
    const orbit = this.add.container(0, 12);
    container.add(orbit);
    orbit.add(this.add.circle(0, 0, 52, accent, 0.02).setStrokeStyle(2, accent, 0.34));
    for (let i = 0; i < 4; i += 1) {
      const angle = (Math.PI * 2 * i) / 4;
      orbit.add(this.add.circle(Math.cos(angle) * 52, Math.sin(angle) * 52, 4, i % 2 === 0 ? 0x9ff5e9 : 0xf6c85f, 0.9));
    }
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: orbit, rotation: Math.PI * 2, duration: 5200, repeat: -1, ease: "Linear" });
    }
  }

  private decorateLogicLandmark(container: Phaser.GameObjects.Container): void {
    for (let i = 0; i < 4; i += 1) {
      const y = -42 + i * 17;
      const line = this.add.line(0, 0, -58 + i * 6, y, 58 - i * 5, y, i % 2 === 0 ? 0x6be7d6 : 0x9f8cff, 0.38).setOrigin(0);
      const node = this.add.circle(-36 + i * 24, y, 4, 0xf5fbff, 0.62);
      container.add([line, node]);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: [line, node], alpha: 0.12, duration: 520 + i * 170, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    }
  }

  private decorateCrystalLandmark(container: Phaser.GameObjects.Container, accent: number): void {
    const orbit = this.add.container(0, -12);
    container.add(orbit);
    for (let i = 0; i < 5; i += 1) {
      const angle = (Math.PI * 2 * i) / 5;
      const x = Math.cos(angle) * 62;
      const y = Math.sin(angle) * 22;
      orbit.add(this.add.triangle(x, y, -6, 7, 0, -10, 6, 7, i % 2 === 0 ? accent : 0x7ad7ff, 0.72).setStrokeStyle(1, 0xffffff, 0.28));
    }
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: orbit, rotation: Math.PI * 2, duration: 6800, repeat: -1, ease: "Linear" });
    }
  }

  private drawTreasure(treasure: OutdoorTreasure, objects?: Phaser.GameObjects.GameObject[]): void {
    const c = this.add.container(treasure.x, treasure.y).setDepth(7 + treasure.y / 10000);
    objects?.push(c);
    const collected = this.collectedTreasures.has(treasure.id);
    const accent = this.biomeAccent(treasure.biome);
    const kind = this.treasureKind(treasure);
    c.add(this.add.ellipse(0, 24, 62, 16, 0x000000, 0.28));
    if (this.textures.exists("soft-glow")) {
      c.add(this.add.image(0, -4, "soft-glow").setTint(accent).setAlpha(collected ? 0.04 : 0.2).setScale(1.45));
    } else {
      c.add(this.add.circle(0, -4, 36, accent, collected ? 0.04 : 0.14));
    }
    const sprite = kind === "rare"
      ? this.addAtlasProp(c, "env_crate_stack", 62, 44, 2, undefined, 0.96)
      : kind === "energy"
        ? this.addAtlasProp(c, "env_holo_beacon", 48, 58, -6, accent, 0.86)
        : this.addAtlasProp(c, "env_plant_pod", 48, 42, 2, accent, 0.84);
    if (!sprite && kind === "rare") {
      c.add(this.add.rectangle(0, 0, 48, 30, 0x7a4b28, 0.96).setStrokeStyle(2, 0xf6c85f, 0.86));
      c.add(this.add.rectangle(0, -9, 52, 8, 0xf6c85f, 0.82));
      c.add(this.add.circle(0, 5, 5, 0xf5fbff, 0.86));
    } else if (!sprite && kind === "energy") {
      c.add(this.add.rectangle(0, 0, 42, 36, 0x173b36, 0.96).setStrokeStyle(2, 0x8fe0a4, 0.78));
      c.add(this.add.triangle(0, -16, -10, 8, 4, 4, -2, 18, 0xf6c85f, 0.92));
    } else if (!sprite) {
      c.add(this.add.circle(-12, 0, 10, 0xc7b8ff, 0.82));
      c.add(this.add.circle(2, -8, 12, accent, 0.78));
      c.add(this.add.circle(14, 4, 9, 0x9ff5e9, 0.78));
    }
    this.decorateTreasure(c, kind, accent, collected);
    const displayLabel = treasure.label.toLowerCase().includes("energia") ? "scrigno frammenti" : treasure.label;
    c.add(this.add.text(0, 36, collected ? "raccolto" : displayLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: collected ? "#6f8794" : "#f7d37a",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 120 },
    }).setOrigin(0.5, 0).setAlpha(collected ? 0.48 : 0.74));
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

  private treasureKind(treasure: OutdoorTreasure): OutdoorTreasureKind {
    const label = treasure.label.toLowerCase();
    if (label.includes("scrigno") || treasure.rewardFragments >= 10) return "rare";
    // Il campo legacy rewardEnergy resta nel contratto di parità, ma non
    // determina più l'aspetto né una ricompensa: i tesori danno frammenti.
    return "fragments";
  }

  private decorateTreasure(container: Phaser.GameObjects.Container, kind: OutdoorTreasureKind, accent: number, collected: boolean): void {
    const shineColor = kind === "energy" ? 0xf6c85f : kind === "rare" ? 0xffd27a : 0xc7b8ff;
    if (kind === "rare") {
      container.add(this.add.rectangle(0, -16, 56, 7, 0xf6c85f, 0.74));
      container.add(this.add.circle(0, 1, 5, 0xf5fbff, 0.9));
      container.add(this.add.triangle(-22, -24, -9, -12, -2, -28, 8, -12, 0xffd27a, 0.58));
      container.add(this.add.triangle(23, -22, 8, -12, 17, -30, 32, -12, 0xffffff, 0.38));
    } else if (kind === "energy") {
      container.add(this.add.triangle(0, -28, -12, 2, 3, -2, -4, 24, 0xf6c85f, 0.95).setStrokeStyle(1, 0xffffff, 0.28));
      container.add(this.add.circle(0, -3, 24, 0x8fe0a4, 0.08).setStrokeStyle(2, 0x8fe0a4, 0.38));
    } else {
      for (let i = 0; i < 5; i += 1) {
        const x = -20 + i * 10;
        const y = -6 + (i % 2) * 8;
        container.add(this.add.triangle(x, y, -5, 7, 0, -8, 5, 7, i % 2 === 0 ? accent : 0x9ff5e9, 0.8).setStrokeStyle(1, 0xffffff, 0.24));
      }
    }
    if (collected) return;
    const shimmer = this.add.line(0, 0, -26, -24, 26, -34, 0xffffff, 0.42).setOrigin(0);
    container.add(shimmer);
    const pulse = this.add.circle(0, -5, kind === "rare" ? 34 : 28, shineColor, 0.08).setStrokeStyle(1, shineColor, 0.32);
    container.add(pulse);
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: shimmer, alpha: 0.08, x: 8, duration: 720, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      this.tweens.add({ targets: pulse, scale: 1.28, alpha: 0.02, duration: 1180, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  private drawHazard(hazard: OutdoorHazard, objects?: Phaser.GameObjects.GameObject[]): void {
    const active = isOutdoorHazardActive(hazard, this.currentDayPhase);
    const accent = this.hazardColor(hazard);
    const c = this.add.container(hazard.x, hazard.y).setDepth(6.5 + hazard.y / 10000).setAlpha(active ? 0.88 : 0.18);
    objects?.push(c);
    const danger = hazard.activeIn === "night";
    c.add(this.add.ellipse(0, 28, danger ? 84 : 62, danger ? 20 : 14, 0x000000, danger ? 0.34 : 0.22));
    const aura = this.textures.exists("soft-glow")
      ? this.add.image(0, -4, "soft-glow").setTint(accent).setAlpha(danger ? 0.24 : 0.14).setScale(danger ? 1.45 : 1)
      : this.add.circle(0, -4, danger ? 42 : 28, accent, danger ? 0.18 : 0.1);
    c.add(aura);
    this.drawHazardCore(c, hazard, accent);
    const ring = this.add.circle(0, 0, danger ? 37 : 27, 0x000000, 0).setStrokeStyle(2, accent, danger ? 0.58 : 0.34);
    c.add(ring);
    c.add(this.add.text(0, danger ? 50 : 42, hazard.label, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: danger ? "#c7b8ff" : "#f7d37a",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 130 },
    }).setOrigin(0.5, 0));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: ring, scale: danger ? 1.32 : 1.18, alpha: danger ? 0.16 : 0.22, duration: danger ? 980 : 1360, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      this.tweens.add({ targets: aura, alpha: danger ? 0.38 : 0.2, scale: danger ? 1.75 : 1.16, duration: danger ? 1180 : 1550, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      if (danger) this.tweens.add({ targets: c, y: hazard.y - 7, duration: 1320, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
    this.hazardNodes.set(hazard.id, { hazard, node: c });
    c.setVisible(!this.clearedHazards.has(hazard.id));
  }

  private drawHazardCore(container: Phaser.GameObjects.Container, hazard: OutdoorHazard, accent: number): void {
    const atlasFrame = hazard.kind === "day-glare"
      ? "out_hazard_sun"
      : hazard.kind === "day-dust"
        ? "out_hazard_dust"
        : hazard.kind === "night-wisp"
          ? "out_hazard_wisp"
          : hazard.kind === "night-shadow"
            ? "out_hazard_shadow"
            : "out_crystal_cluster";
    if (this.addOutdoorSprite(container, atlasFrame, hazard.activeIn === "night" ? 62 : 52, hazard.activeIn === "night" ? 58 : 52, -4, undefined, 0.96)) {
      return;
    }
    if (hazard.kind === "day-glare") {
      container.add(this.add.circle(0, -2, 13, 0xf6c85f, 0.88).setStrokeStyle(2, 0xffffff, 0.42));
      for (let i = 0; i < 8; i += 1) {
        const angle = (Math.PI * 2 * i) / 8;
        container.add(this.add.line(0, 0, Math.cos(angle) * 18, -2 + Math.sin(angle) * 18, Math.cos(angle) * 29, -2 + Math.sin(angle) * 29, 0xf6c85f, 0.52).setOrigin(0));
      }
    } else if (hazard.kind === "day-dust") {
      for (let i = 0; i < 4; i += 1) {
        container.add(this.add.arc(0, -2, 14 + i * 6, 210 - i * 22, 350 - i * 14, false, accent, 0.04).setStrokeStyle(3, accent, 0.32));
      }
      container.add(this.add.circle(-10, 12, 4, 0xf6c85f, 0.54));
      container.add(this.add.circle(12, -14, 3, 0xffffff, 0.42));
    } else if (hazard.kind === "night-wisp") {
      container.add(this.add.circle(0, -2, 18, 0x132451, 0.92).setStrokeStyle(2, accent, 0.8));
      container.add(this.add.triangle(0, -24, -12, 8, 0, 22, 12, 8, accent, 0.7));
      container.add(this.add.circle(-6, -4, 4, 0xf5fbff, 0.78));
      container.add(this.add.circle(7, -7, 3, 0xf5fbff, 0.62));
    } else if (hazard.kind === "night-shadow") {
      container.add(this.add.ellipse(0, 0, 58, 38, 0x02070b, 0.96).setStrokeStyle(3, accent, 0.66));
      container.add(this.add.ellipse(0, -1, 34, 15, 0x45133d, 0.8));
      container.add(this.add.circle(0, -1, 5, 0xf5fbff, 0.88));
    } else {
      this.drawPremiumCrystalCluster(container, 22, accent, 0x7ad7ff, 0.78);
      container.add(this.add.circle(0, -5, 26, accent, 0.03).setStrokeStyle(2, accent, 0.28));
    }
  }

  private drawEncounter(encounter: OutdoorEncounter, objects?: Phaser.GameObjects.GameObject[]): void {
    const patch = this.map.patches.find((candidate) => candidate.id === encounter.biome);
    const accent = patch?.accent ?? 0x6be7d6;
    const c = this.add.container(encounter.x, encounter.y).setDepth(8 + encounter.y / 10000);
    objects?.push(c);
    const done = this.completed.has(encounter.id);
    if (!done && this.addOutdoorSprite(c, "out_marker_beacon", encounter.kind === "guardian" ? 58 : 42, encounter.kind === "guardian" ? 66 : 48, encounter.kind === "guardian" ? -8 : -5, accent, 0.82)) {
      const beaconGlow = this.add.circle(0, -8, encounter.kind === "guardian" ? 38 : 28, accent, 0.08);
      c.addAt(beaconGlow, 0);
    }
    c.add(this.add.circle(0, 0, encounter.kind === "guardian" ? 34 : 25, 0x061019, 0.94).setStrokeStyle(3, accent, 0.9));
    c.add(this.add.circle(0, 0, encounter.kind === "guardian" ? 17 : 11, accent, 0.78));
    const frame = encounter.kind === "guardian"
      ? "env_holo_beacon"
      : encounter.kind === "capital" || encounter.kind === "physicalGeo"
        ? "env_terminal_kiosk"
        : "env_repair_drone";
    const icon = this.addAtlasProp(c, frame, encounter.kind === "guardian" ? 52 : 38, encounter.kind === "guardian" ? 58 : 38, encounter.kind === "guardian" ? -4 : 0, accent, 0.72);
    icon?.setBlendMode(Phaser.BlendModes.ADD);
    this.drawEncounterIdentity(c, encounter.kind, ENCOUNTER_COLORS[encounter.kind] ?? accent, done);
    c.add(this.add.text(0, encounter.kind === "guardian" ? 2 : 0, ENCOUNTER_GLYPHS[encounter.kind], {
      fontFamily: "Inter, Arial",
      fontSize: encounter.kind === "guardian" ? "20px" : "15px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
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

  private drawEncounterIdentity(container: Phaser.GameObjects.Container, kind: OutdoorEncounterKind, accent: number, done: boolean): void {
    const motif = this.add.container(0, 0);
    container.add(motif);
    if (kind === "times") {
      motif.add(this.add.line(0, 0, -18, -18, 18, 18, accent, 0.82).setOrigin(0));
      motif.add(this.add.line(0, 0, 18, -18, -18, 18, accent, 0.82).setOrigin(0));
      for (const [x, y] of [[-22, -22], [22, -22], [-22, 22], [22, 22]]) {
        motif.add(this.add.circle(x, y, 4, 0xf5fbff, 0.78));
      }
    } else if (kind === "mental") {
      motif.add(this.add.triangle(0, -3, -9, -22, 8, -5, -3, -3, accent, 0.92));
      motif.add(this.add.triangle(0, 5, 8, -2, -8, 20, 1, 2, 0xf6c85f, 0.86));
      motif.add(this.add.arc(0, 0, 28, 205, 338, false, accent, 0.18).setStrokeStyle(4, accent, 0.34));
    } else if (kind === "capital") {
      motif.add(this.add.circle(0, 0, 21, 0x173b36, 0.68).setStrokeStyle(2, accent, 0.85));
      motif.add(this.add.ellipse(0, 0, 12, 39, accent, 0.02).setStrokeStyle(1, accent, 0.58));
      motif.add(this.add.ellipse(0, 0, 38, 12, accent, 0.02).setStrokeStyle(1, accent, 0.52));
      motif.add(this.add.circle(10, -8, 4, 0xf6c85f, 0.9));
    } else if (kind === "physicalGeo") {
      motif.add(this.add.triangle(-6, 5, -25, 20, -4, -20, 14, 20, 0x8fe0a4, 0.74).setStrokeStyle(1, 0xffffff, 0.22));
      motif.add(this.add.triangle(14, 8, -4, 21, 15, -13, 31, 21, accent, 0.6));
      motif.add(this.add.arc(-1, 14, 25, 10, 168, false, 0x7ad7ff, 0.02).setStrokeStyle(3, 0x7ad7ff, 0.74));
    } else {
      motif.add(this.add.circle(0, 0, 31, accent, 0.04).setStrokeStyle(2, accent, 0.42));
      motif.add(this.add.triangle(0, -31, -7, -14, 7, -14, accent, 0.82));
      motif.add(this.add.triangle(0, 31, -7, 14, 7, 14, accent, 0.82));
      motif.add(this.add.triangle(-31, 0, -14, -7, -14, 7, accent, 0.82));
      motif.add(this.add.triangle(31, 0, 14, -7, 14, 7, accent, 0.82));
    }
    if (!done && !settingsSystem.effectsReduced()) {
      this.tweens.add({
        targets: motif,
        rotation: kind === "guardian" || kind === "capital" ? Math.PI * 2 : 0.12,
        duration: kind === "guardian" || kind === "capital" ? 5400 : 900,
        yoyo: kind !== "guardian" && kind !== "capital",
        repeat: -1,
        ease: kind === "guardian" || kind === "capital" ? "Linear" : "Sine.easeInOut",
      });
    }
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
    this.addEquippedMicroAnimations(outfit, accessory, color);
    const petRoot = this.add.container(0, 0).setDepth(19);
    this.petCompanion = drawPetVisual(this, petRoot, pet, this.map.start.x - 48, this.map.start.y + 20, 1.05, false);
    if (this.petCompanion && !settingsSystem.effectsReduced()) {
      this.tweens.add({
        targets: this.petCompanion,
        angle: { from: -2, to: 2 },
        duration: 1250,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
      });
    }
  }

  private addEquippedMicroAnimations(outfit: Cosmetic | undefined, accessory: Cosmetic | undefined, color: number): void {
    if (settingsSystem.effectsReduced()) return;
    if (outfit) {
      const aura = this.add.ellipse(0, 16, 74, 104, color, 0.035).setStrokeStyle(2, color, 0.24);
      this.avatar.addAt(aura, 1);
      this.tweens.add({ targets: aura, alpha: 0.12, scale: 1.08, duration: 1500, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      if (outfit.id === "avatar-astral" || outfit.id === "avatar-aurora" || outfit.id === "avatar-nebula") {
        for (let i = 0; i < 4; i += 1) {
          const star = this.add.circle(-26 + i * 17, -44 + (i % 2) * 14, i % 2 === 0 ? 2 : 1.5, i % 2 === 0 ? 0xffffff : color, 0.78);
          this.avatar.add(star);
          this.tweens.add({
            targets: star,
            alpha: { from: 0.18, to: 0.9 },
            y: star.y - 5,
            duration: 860 + i * 180,
            yoyo: true,
            repeat: -1,
            ease: "Sine.easeInOut",
          });
        }
      }
    }
    if (!accessory) return;
    if (accessory.id === "accessory-jetpack") {
      [-34, 34].forEach((x, index) => {
        const flame = this.add.triangle(x, 52, -5, 0, 5, 0, 0, 18, 0xf6c85f, 0.7);
        this.avatar.add(flame);
        this.tweens.add({ targets: flame, alpha: 0.18, scaleY: 1.35, duration: 180 + index * 40, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      });
    } else if (accessory.id === "accessory-wings") {
      const left = this.add.triangle(-46, 5, 0, -10, -32, 0, -4, 18, accessory.color ?? 0xf6c85f, 0.18);
      const right = this.add.triangle(46, 5, 0, -10, 32, 0, 4, 18, accessory.color ?? 0xf6c85f, 0.18);
      this.avatar.add([left, right]);
      this.tweens.add({ targets: [left, right], alpha: 0.42, scaleY: 1.14, duration: 620, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    } else if (accessory.id === "accessory-halo" || accessory.id === "accessory-crown" || accessory.id === "accessory-compass") {
      const ping = this.add.circle(accessory.id === "accessory-compass" ? 25 : 0, accessory.id === "accessory-compass" ? -2 : -56, 18, 0x000000, 0)
        .setStrokeStyle(2, accessory.color ?? 0xf6c85f, 0.26);
      this.avatar.add(ping);
      this.tweens.add({ targets: ping, scale: 1.45, alpha: 0, duration: 1200, repeat: -1, ease: "Sine.easeOut" });
    }
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
    hud.add(this.add.rectangle(18, 16, 390, 122, 0x061019, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.42));
    hud.add(this.add.text(36, 28, "Mappa Esterna", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    hud.add(this.add.text(36, 58, "Tocca/clicca il terreno o usa WASD/frecce.", {
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
    this.dayPhaseText = this.add.text(36, 106, "Giorno chiaro · pericoli lievi", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.fragmentText = this.add.text(1040, 54, `${outdoor.fragments} frammenti`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7b8ff",
      fontStyle: "bold",
    }).setOrigin(1, 0);
    hud.add([this.progressText, this.dayPhaseText, this.fragmentText]);
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
    new Button(this, 650, 48, "Godot", () => this.openGodotOutdoor(), {
      width: 112,
      height: 42,
      fontSize: 13,
      fill: 0x17304a,
      stroke: 0x7ad7ff,
      soundKey: "panelOpen",
    }).setScrollFactor(0).setDepth(130);
    new Button(this, 1170, 48, this.returnScene === "ExplorableRoomScene" ? "Mondo" : "Menu", () => this.scene.start(this.returnScene), {
      width: 128,
      height: 42,
      fontSize: 14,
      fill: 0x263743,
    }).setScrollFactor(0).setDepth(130);
    this.radar = this.add.graphics().setScrollFactor(0).setDepth(126);
    this.biomeText = this.add.text(1128, 572, "Zona", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setScrollFactor(0).setDepth(128);
    this.coordText = this.add.text(1128, 588, "0:0", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9fb6c2",
      fontStyle: "bold",
    }).setScrollFactor(0).setDepth(128);
    this.radarLegendText = this.add.text(1128, 650, "incontri  tesori", {
      fontFamily: "Inter, Arial",
      fontSize: "8px",
      color: "#9fb6c2",
      fontStyle: "bold",
    }).setScrollFactor(0).setDepth(128);
    this.guideGraphics = this.add.graphics().setScrollFactor(0).setDepth(126);
    this.guideText = this.add.text(640, 656, "Esplora", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
    }).setOrigin(0.5).setScrollFactor(0).setDepth(128);
    this.updateRadar();
    this.updateObjectiveGuide();
  }

  private openGodotOutdoor(): void {
    this.reopenGodot();
  }

  private updateMovement(dt: number): void {
    let dx = (this.cursors.right.isDown || this.keys.D.isDown ? 1 : 0) - (this.cursors.left.isDown || this.keys.A.isDown ? 1 : 0);
    let dy = (this.cursors.down.isDown || this.keys.S.isDown ? 1 : 0) - (this.cursors.up.isDown || this.keys.W.isDown ? 1 : 0);
    if (dx !== 0 || dy !== 0) {
      this.clearMoveTarget();
    } else if (this.moveTarget) {
      const tx = this.moveTarget.x - this.avatar.x;
      const ty = this.moveTarget.y - this.avatar.y;
      const distance = Math.hypot(tx, ty);
      if (distance < 10) {
        this.clearMoveTarget();
      } else {
        dx = tx / distance;
        dy = ty / distance;
      }
    }
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
    const beforeX = this.avatar.x;
    const beforeY = this.avatar.y;
    if (this.isWalkable(nx, this.avatar.y)) this.avatar.x = nx;
    if (this.isWalkable(this.avatar.x, ny)) this.avatar.y = ny;
    if (this.moveTarget && Math.hypot(this.avatar.x - beforeX, this.avatar.y - beforeY) < 0.5) this.clearMoveTarget();
    this.avatar.setDepth(20 + this.avatar.y / 10000);
    this.facing = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "right" : "left") : (dy > 0 ? "down" : "up");
    this.avatarSprite?.anims.play(`outdoor-${this.facing}`, true);
    this.emitMovementTrail();
  }

  private handlePointerMove(pointer: Phaser.Input.Pointer): void {
    if (this.paused || pointer.button > 0) return;
    if (this.isScreenUiPoint(pointer.x, pointer.y)) return;
    const world = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
    if (!this.isWalkable(world.x, world.y)) {
      this.showMovePing(world.x, world.y, 0xff6b7a);
      return;
    }
    this.moveTarget = {
      x: Phaser.Math.Clamp(world.x, -VIRTUAL_WORLD_LIMIT + 42, VIRTUAL_WORLD_LIMIT - 42),
      y: Phaser.Math.Clamp(world.y, -VIRTUAL_WORLD_LIMIT + 54, VIRTUAL_WORLD_LIMIT - 54),
    };
    this.showMovePing(this.moveTarget.x, this.moveTarget.y, this.currentBiome ? BIOME_ACCENTS[this.currentBiome] : 0x6be7d6);
  }

  private isScreenUiPoint(x: number, y: number): boolean {
    return (y <= 142 && (x <= 430 || x >= 720)) || (x >= 1030 && y >= 520);
  }

  private showMovePing(x: number, y: number, color: number): void {
    this.clearMoveMarker();
    const c = this.add.container(x, y).setDepth(18 + y / 10000);
    c.add(this.add.circle(0, 0, 18, color, 0.08).setStrokeStyle(2, color, 0.7));
    c.add(this.add.circle(0, 0, 4, color, 0.9));
    this.moveTargetMarker = c;
    this.tweens.add({
      targets: c,
      scale: 1.28,
      alpha: 0.38,
      duration: 520,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }

  private clearMoveTarget(): void {
    this.moveTarget = undefined;
    this.clearMoveMarker();
  }

  private clearMoveMarker(): void {
    if (!this.moveTargetMarker) return;
    this.tweens.killTweensOf(this.moveTargetMarker);
    this.moveTargetMarker.destroy(true);
    this.moveTargetMarker = undefined;
  }

  private emitMovementTrail(): void {
    if (settingsSystem.effectsReduced() || this.time.now - this.lastTrailAt < 115) return;
    this.lastTrailAt = this.time.now;
    const accent = this.currentBiome ? BIOME_ACCENTS[this.currentBiome] : 0x6be7d6;
    const x = this.avatar.x + Phaser.Math.Between(-12, 12);
    const y = this.avatar.y + 34 + Phaser.Math.Between(-3, 4);
    const trail = this.textures.exists("soft-glow")
      ? this.add.image(x, y, "soft-glow").setTint(accent).setAlpha(0.16).setScale(0.5)
      : this.add.circle(x, y, 8, accent, 0.16);
    trail.setDepth(9 + y / 10000);
    this.tweens.add({
      targets: trail,
      alpha: 0,
      scale: 0.18,
      y: y + 8,
      duration: 460,
      ease: "Sine.easeOut",
      onComplete: () => trail.destroy(),
    });
  }

  private isWalkable(x: number, y: number): boolean {
    return !this.map.obstacles.some((obstacle) => Math.hypot(obstacle.x - x, obstacle.y - y) < obstacle.r + 26);
  }

  private refreshHazardVisibility(): void {
    for (const { hazard, node } of this.hazardNodes.values()) {
      const active = isOutdoorHazardActive(hazard, this.currentDayPhase);
      node.setVisible(!this.clearedHazards.has(hazard.id));
      node.setAlpha(active ? (hazard.activeIn === "night" ? 0.95 : 0.78) : 0.16);
    }
    this.updateRadar();
  }

  private updateHazards(): void {
    if (!this.avatar || this.time.now - this.lastHazardHitAt < 1800) return;
    for (const { hazard } of this.hazardNodes.values()) {
      if (this.clearedHazards.has(hazard.id) || !isOutdoorHazardActive(hazard, this.currentDayPhase)) continue;
      if (Math.hypot(hazard.x - this.avatar.x, hazard.y - this.avatar.y) <= hazard.r) {
        this.startHazardChallenge(hazard);
        return;
      }
    }
  }

  private startHazardChallenge(hazard: OutdoorHazard): void {
    if (this.paused || this.clearedHazards.has(hazard.id) || !isOutdoorHazardActive(hazard, this.currentDayPhase)) return;
    this.paused = true;
    this.lastHazardHitAt = this.time.now;
    this.prompt.setVisible(false);
    const difficulty = outdoorHazardDifficulty(hazard, this.currentDayPhase);
    const reward = outdoorHazardReward(hazard, this.currentDayPhase);
    const question = this.questionFor(hazard.encounterKind, difficulty);
    const accent = this.hazardColor(hazard);
    const night = hazard.activeIn === "night";
    audioManager.play(night ? "error" : "panelOpen");

    const overlay = this.beginMapOverlay(2100);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, night ? 0x01030e : 0x02070b, night ? 0.9 : 0.82).setInteractive());
    overlay.add(this.add.rectangle(640, 360, 720, 470, night ? 0x07101f : 0x07151d, 0.98).setStrokeStyle(2, accent, night ? 0.96 : 0.72));
    overlay.add(this.add.text(640, 142, night ? "Pericolo notturno" : "Pericolo diurno", {
      fontFamily: "Inter, Arial",
      fontSize: "32px",
      color: night ? "#c7b8ff" : "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(640, 180, `${OUTDOOR_PHASE_LABELS[this.currentDayPhase]} · ${hazard.label} · ${BIOME_LABELS[hazard.biome]}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9fb6c2",
      align: "center",
      wordWrap: { width: 600 },
    }).setOrigin(0.5));
    const icon = this.add.container(294, 312);
    overlay.add(icon);
    this.drawHazardCore(icon, hazard, accent);
    icon.setScale(night ? 1.8 : 1.45);
    if (!settingsSystem.effectsReduced()) this.tweens.add({ targets: icon, scale: night ? 2.02 : 1.62, duration: 820, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });

    const panel = this.add.container(0, 0);
    overlay.add(panel);
    let answered = false;
    const showResult = (correct: boolean): void => {
      panel.removeAll(true);
      if (correct) {
        this.clearedHazards.add(hazard.id);
        this.clearHazardNode(hazard);
        saveSystem.addEnergy(reward.energy);
        saveSystem.grantOutdoorFragments(reward.fragments);
        audioManager.play("success");
        this.reactPet("correct", hazard.biome);
      } else {
        audioManager.play("error");
        this.knockBackFromHazard(hazard);
        feedbackSystem.publish(question.explanation, "hint");
      }
      this.refreshHud();
      panel.add(this.add.text(640, 324, correct ? "Pericolo neutralizzato" : "Ripiega e riprova", {
        fontFamily: "Inter, Arial",
        fontSize: "25px",
        color: correct ? "#8ff6c0" : "#ffb48f",
        fontStyle: "bold",
      }).setOrigin(0.5));
      panel.add(this.add.text(640, 366, correct ? `+${reward.energy} energia · +${reward.fragments} frammenti` : question.explanation, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#f5fbff",
        align: "center",
        wordWrap: { width: 520 },
      }).setOrigin(0.5));
      const close = (): void => {
        this.closeMapOverlay(overlay);
        this.lastHazardHitAt = this.time.now;
      };
      panel.add(new Button(this, 640, 456, "Torna alla mappa", close, { width: 220, height: 46, fontSize: 15, fill: night ? 0x2a1f3a : 0x173b36, stroke: accent }));
      panel.add(this.add.text(640, 500, "Invio / Spazio per tornare alla mappa", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9fb6c2",
        fontStyle: "bold",
      }).setOrigin(0.5));
      this.input.keyboard?.once("keydown-ENTER", close);
      this.input.keyboard?.once("keydown-SPACE", close);
    };

    panel.add(this.add.text(640, 268, question.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 560 },
    }).setOrigin(0.5));
    panel.add(this.add.text(640, 316, night ? "Difficolta alta: la notte amplifica il pericolo." : "Difficolta leggera: passa il varco con calma.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: night ? "#c7b8ff" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    question.options.forEach((option, index) => {
      const x = 440 + (index % 2) * 400;
      const y = 386 + Math.floor(index / 2) * 62;
      panel.add(new Button(this, x, y, option, () => {
        if (answered) return;
        answered = true;
        showResult(option === question.correct);
      }, { width: 320, height: 46, fontSize: 14, fill: 0x173b36, stroke: accent }));
    });
  }

  private knockBackFromHazard(hazard: OutdoorHazard): void {
    const dx = this.avatar.x - hazard.x;
    const dy = this.avatar.y - hazard.y;
    const len = Math.hypot(dx, dy) || 1;
    const distance = hazard.activeIn === "night" ? 96 : 52;
    const nx = Phaser.Math.Clamp(this.avatar.x + (dx / len) * distance, -VIRTUAL_WORLD_LIMIT + 42, VIRTUAL_WORLD_LIMIT - 42);
    const ny = Phaser.Math.Clamp(this.avatar.y + (dy / len) * distance, -VIRTUAL_WORLD_LIMIT + 54, VIRTUAL_WORLD_LIMIT - 54);
    if (this.isWalkable(nx, ny)) {
      this.tweens.add({ targets: this.avatar, x: nx, y: ny, duration: 220, ease: "Cubic.easeOut" });
    }
  }

  private clearHazardNode(hazard: OutdoorHazard): void {
    const entry = this.hazardNodes.get(hazard.id);
    if (!entry) return;
    this.tweens.killTweensOf(entry.node);
    this.tweens.add({
      targets: entry.node,
      alpha: 0,
      scale: 0.35,
      duration: 280,
      ease: "Cubic.easeIn",
      onComplete: () => {
        entry.node.destroy(true);
        this.hazardNodes.delete(hazard.id);
      },
    });
  }

  private updatePet(): void {
    if (!this.petCompanion) return;
    if (this.petMood !== "idle" && this.time.now > this.petMoodUntil) {
      this.petMood = "idle";
    }
    const nearestTreasure = this.nearestUncollectedTreasure(170);
    const species = this.equippedPetSpecies();
    const baseDistance = this.petMood === "treasure"
      ? species === "dog" ? 72 : 62
      : this.petMood === "correct"
        ? species === "rabbit" ? 30 : 36
        : nearestTreasure
          ? species === "dog" ? 34 : 42
          : species === "cat" ? 58 : 48;
    const side = this.facing === "left" ? 1 : -1;
    const rhythm = species === "rabbit" ? 210 : species === "cat" ? 520 : 320;
    const orbit = Math.sin(this.time.now / (this.petMood === "correct" ? 170 : rhythm));
    const hop = species === "rabbit" ? Math.max(0, Math.sin(this.time.now / 115)) * -16 : 0;
    const catDrift = species === "cat" ? Math.sin(this.time.now / 740) * 18 : 0;
    const targetX = nearestTreasure && this.petMood === "idle"
      ? Phaser.Math.Linear(this.avatar.x + side * baseDistance, nearestTreasure.x, 0.18)
      : this.avatar.x + side * baseDistance + orbit * (this.petMood === "correct" ? 10 : 4) + catDrift;
    const targetY = this.avatar.y + 18 + Math.sin(this.time.now / 360) * 7 - (this.petMood === "correct" ? 18 : 0) + hop;
    const follow = this.petMood === "idle" ? species === "cat" ? 0.055 : 0.07 : species === "dog" ? 0.18 : 0.14;
    this.petCompanion.x = Phaser.Math.Linear(this.petCompanion.x, targetX, follow);
    this.petCompanion.y = Phaser.Math.Linear(this.petCompanion.y, targetY, follow);
    this.petCompanion.setScale(this.petMood === "correct" ? 1.16 : this.petMood === "treasure" ? 1.1 : 1.05);
    this.petCompanion.setDepth(19 + this.petCompanion.y / 10000);
    if (nearestTreasure && this.time.now > this.petNextChirpAt) {
      this.petNextChirpAt = this.time.now + 2600;
      this.petSpark(nearestTreasure.x, nearestTreasure.y, this.biomeAccent(nearestTreasure.biome));
    }
  }

  private equippedPetSpecies(): "dog" | "cat" | "rabbit" | "other" {
    const id = rewardSystem.equippedId("pet");
    if (id === "pet-dog") return "dog";
    if (id === "pet-cat") return "cat";
    if (id === "pet-rabbit") return "rabbit";
    return "other";
  }

  private nearestUncollectedTreasure(radius: number): OutdoorTreasure | undefined {
    let best: OutdoorTreasure | undefined;
    let bestDistance = radius;
    for (const treasure of this.map.treasures) {
      if (this.collectedTreasures.has(treasure.id)) continue;
      const distance = Math.hypot(treasure.x - this.avatar.x, treasure.y - this.avatar.y);
      if (distance < bestDistance) {
        best = treasure;
        bestDistance = distance;
      }
    }
    return best;
  }

  private reactPet(kind: "treasure" | "correct", biome: OutdoorBiome): void {
    if (!this.petCompanion || settingsSystem.effectsReduced()) return;
    this.petMood = kind;
    this.petMoodUntil = this.time.now + (kind === "treasure" ? 1800 : 950);
    const accent = this.biomeAccent(biome);
    this.tweens.killTweensOf(this.petCompanion);
    this.tweens.add({
      targets: this.petCompanion,
      scale: kind === "treasure" ? 1.34 : 1.28,
      angle: kind === "treasure" ? 18 : -16,
      duration: 150,
      yoyo: true,
      repeat: kind === "treasure" ? 2 : 1,
      ease: "Sine.easeInOut",
      onComplete: () => {
        this.tweens.add({ targets: this.petCompanion, angle: { from: -2, to: 2 }, duration: 1250, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      },
    });
    for (let i = 0; i < (kind === "treasure" ? 9 : 6); i += 1) {
      const angle = (Math.PI * 2 * i) / (kind === "treasure" ? 9 : 6);
      this.petSpark(this.petCompanion.x + Math.cos(angle) * 28, this.petCompanion.y + Math.sin(angle) * 20, i % 2 === 0 ? accent : 0xffffff);
    }
  }

  private petSpark(x: number, y: number, color: number): void {
    if (settingsSystem.effectsReduced()) return;
    const spark = this.textures.exists("soft-glow")
      ? this.add.image(x, y, "soft-glow").setTint(color).setAlpha(0.16).setScale(0.24)
      : this.add.circle(x, y, 5, color, 0.36);
    spark.setDepth(32 + y / 10000);
    this.tweens.add({
      targets: spark,
      y: y - 18,
      alpha: 0,
      scale: 0.08,
      duration: 520,
      ease: "Sine.easeOut",
      onComplete: () => spark.destroy(),
    });
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
        prompt = `E / clicca-tocca · ${nearest.enemy}`;
        best = distance;
      }
    }
    for (const treasure of this.map.treasures) {
      if (this.collectedTreasures.has(treasure.id)) continue;
      const distance = Math.hypot(treasure.x - this.avatar.x, treasure.y - this.avatar.y);
      if (distance < 82 && distance < best) {
        nearest = undefined;
        nearestTreasure = treasure;
        prompt = `E / clicca-tocca · ${treasure.label}`;
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
    this.clearMoveTarget();
    if (this.activeTreasure) {
      this.collectTreasure(this.activeTreasure);
      return;
    }
    if (this.activeEncounter) this.startEncounter(this.activeEncounter);
  }

  private collectTreasure(treasure: OutdoorTreasure): void {
    if (this.paused || this.collectedTreasures.has(treasure.id)) return;
    if (!saveSystem.recordOutdoorTreasure(treasure.id, 0, treasure.rewardFragments)) return;
    this.collectedTreasures.add(treasure.id);
    this.activeTreasure = undefined;
    this.prompt.setVisible(false);
    this.showTreasureBurst(treasure);
    this.reactPet("treasure", treasure.biome);
    const node = this.treasureNodes.get(treasure.id);
    if (node) {
      this.tweens.killTweensOf(node);
      this.animateTreasurePickup(node, treasure);
      this.treasureNodes.delete(treasure.id);
    }
    this.refreshHud();
    audioManager.play("success");
    feedbackSystem.publish(`Tesoro raccolto: +${treasure.rewardFragments} frammenti. L'energia si guadagna con gli esercizi.`, "success");
  }

  private animateTreasurePickup(node: Phaser.GameObjects.Container, treasure: OutdoorTreasure): void {
    for (const child of node.list) {
      this.tweens.killTweensOf(child);
    }
    if (settingsSystem.effectsReduced()) {
      node.destroy(true);
      return;
    }
    const kind = this.treasureKind(treasure);
    const accent = this.biomeAccent(treasure.biome);
    const lid = kind === "rare"
      ? this.add.rectangle(0, -24, 54, 8, 0xf6c85f, 0.88)
      : this.add.circle(0, -15, 16, kind === "energy" ? 0xf6c85f : accent, 0.24).setStrokeStyle(2, accent, 0.56);
    node.add(lid);
    this.tweens.add({
      targets: lid,
      y: lid.y - 22,
      angle: kind === "rare" ? -16 : 0,
      alpha: 0,
      duration: 360,
      ease: "Cubic.easeOut",
    });
    this.tweens.add({
      targets: node,
      scale: 1.22,
      alpha: 0,
      duration: 430,
      ease: "Cubic.easeIn",
      onComplete: () => node.destroy(true),
    });
  }

  private showTreasureBurst(treasure: OutdoorTreasure): void {
    if (settingsSystem.effectsReduced()) return;
    const accent = this.biomeAccent(treasure.biome);
    const kind = this.treasureKind(treasure);
    const count = kind === "rare" ? 18 : kind === "energy" ? 13 : 10;
    for (let i = 0; i < count; i += 1) {
      const angle = (Math.PI * 2 * i) / count;
      const color = kind === "energy" ? (i % 2 === 0 ? 0xf6c85f : 0x8fe0a4) : kind === "rare" ? (i % 3 === 0 ? 0xffffff : 0xffd27a) : (i % 2 === 0 ? accent : 0xc7b8ff);
      const spark = this.add.circle(treasure.x, treasure.y - 6, kind === "rare" ? 5 : 4, color, 0.9).setDepth(30 + treasure.y / 10000);
      this.tweens.add({
        targets: spark,
        x: treasure.x + Math.cos(angle) * Phaser.Math.Between(34, kind === "rare" ? 96 : 74),
        y: treasure.y - 6 + Math.sin(angle) * Phaser.Math.Between(24, kind === "rare" ? 78 : 62),
        alpha: 0,
        scale: 0.2,
        duration: kind === "rare" ? 720 : 540,
        ease: "Cubic.easeOut",
        onComplete: () => spark.destroy(),
      });
    }
  }

  private openBountyBoard(): void {
    if (this.paused) return;
    this.paused = true;
    const overlay = this.beginMapOverlay(2100);
    const close = (): void => {
      this.closeMapOverlay(overlay, () => this.refreshHud());
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
    overlay.add(this.add.text(346, 178, "Obiettivi giornalieri della mappa esterna: completali e reclama frammenti.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
      wordWrap: { width: 580 },
    }));
    bounties.forEach((bounty, index) => {
      this.drawBountyRow(overlay, bounty, claimed.has(bounty.id), 356, 224 + index * 76, () => {
        this.closeMapOverlay(overlay);
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
        fragments: 8,
      },
      {
        id: "streak-2",
        title: "Serie pulita",
        description: "Vinci due incontri consecutivi senza ritirata.",
        current: Math.min(outdoor.currentStreak, 2),
        target: 2,
        fragments: 8,
      },
      {
        id: "guardian-day",
        title: "Guardiano del giorno",
        description: "Sconfiggi il guardiano prismatico della mappa.",
        current: Math.min(outdoor.guardianWinsToday ?? 0, 1),
        target: 1,
        fragments: 16,
      },
      {
        id: "treasure-5",
        title: "Cercatore di tesori",
        description: "Raccogli cinque tesori nascosti nella mappa.",
        current: Math.min(this.collectedTreasures.size, 5),
        target: 5,
        fragments: 12,
      },
      {
        id: "daily-route-12",
        title: "Rotta lunga",
        description: "Supera dodici incontri esplorando più zone.",
        current: Math.min(this.completed.size, DAILY_ROUTE_TARGET),
        target: DAILY_ROUTE_TARGET,
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
    overlay.add(this.add.text(x + 390, y + 38, `+${bounty.fragments} frammenti`, {
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
      if (saveSystem.claimOutdoorBounty(bounty.id, 0, bounty.fragments)) {
        audioManager.play("shopPurchase");
        feedbackSystem.publish(`Bacheca: +${bounty.fragments} frammenti. L'energia si guadagna con gli esercizi.`, "success");
        this.refreshHud();
        refresh();
      }
    }, { width: 104, height: 34, fontSize: 12, fill: done ? 0x173b36 : 0x1a252e, stroke: done ? 0x8fe0a4 : 0x6a638d, soundKey: done ? "shopPurchase" : "shopLocked" }));
  }

  private openForge(): void {
    if (this.paused) return;
    this.paused = true;
    const overlay = this.beginMapOverlay(2100);
    const close = (): void => {
      this.closeMapOverlay(overlay, () => this.refreshHud());
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
        this.closeMapOverlay(overlay);
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

  private startEncounter(encounter: OutdoorEncounter, energyAlreadySpent = false): void {
    if (this.paused || this.completed.has(encounter.id)) return;
    if (!energyAlreadySpent && !saveSystem.spendEnergy(OUTDOOR_EXERCISE_ENERGY_COST)) {
      feedbackSystem.publish(`Energia insufficiente: servono ${OUTDOOR_EXERCISE_ENERGY_COST} energia per partecipare.`, "warning");
      return;
    }
    this.paused = true;
    this.prompt.setVisible(false);
    audioManager.play("missionStart");
    this.runCombat(encounter);
  }

  private runCombat(encounter: OutdoorEncounter): void {
    const overlay = this.beginMapOverlay(2000);
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
            this.reactPet("correct", encounter.biome);
            this.showCombatPetReaction(arena, encounter.biome);
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
    // L'energia arriva dalla riuscita dell'esercizio, mai dal semplice
    // ritrovamento di un oggetto o da una ritirata.
    const reward = victory ? Math.max(6, encounter.reward + correct * 10) : 0;
    const fragments = this.fragmentReward(encounter, correct, victory);
    const varietyBonuses = victory ? saveSystem.recordDailyEnergySubject(`Avventura ${this.subjectFor(encounter.kind)}`) : [];
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
    const close = (): void => {
      if (this.godotBounceResume) {
        // L'incontro veniva da Godot: torna nel mondo con l'esito applicato.
        const resume = this.godotBounceResume;
        this.godotBounceResume = undefined;
        if (this.reopenGodot(resume)) return;
        // Se il bundle Godot non è più disponibile, prosegui nel mondo Phaser.
      }
      this.closeMapOverlay(overlay, () => {
        feedbackSystem.publish(`Energia avventura guadagnata: +${reward + bonus}`, "success");
      });
    };
    overlay.add(new Button(this, 640, 436, "Torna alla mappa", close, {
      width: 220,
      height: 46,
      fontSize: 15,
      fill: 0x173b36,
      stroke: victory ? 0x2ed889 : 0xf6c85f,
    }));
    const hint = this.add.text(640, 482, "Invio / Spazio per tornare alla mappa", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9fb6c2",
      fontStyle: "bold",
    }).setOrigin(0.5);
    overlay.add(hint);
    const closeFromKeyboard = (): void => {
      if (!overlay.active) return;
      close();
    };
    this.input.keyboard?.once("keydown-ENTER", closeFromKeyboard);
    this.input.keyboard?.once("keydown-SPACE", closeFromKeyboard);
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

  private showCombatPetReaction(parent: Phaser.GameObjects.Container, biome: OutdoorBiome): void {
    if (settingsSystem.effectsReduced()) return;
    const accent = this.biomeAccent(biome);
    const burst = this.add.container(272, 302);
    parent.add(burst);
    if (this.textures.exists("soft-glow")) {
      burst.add(this.add.image(0, 0, "soft-glow").setTint(accent).setAlpha(0.22).setScale(0.7));
    }
    burst.add(this.add.circle(0, 0, 18, 0x000000, 0).setStrokeStyle(2, accent, 0.7));
    for (let i = 0; i < 7; i += 1) {
      const angle = (Math.PI * 2 * i) / 7;
      const spark = this.add.circle(0, 0, i % 2 === 0 ? 4 : 3, i % 2 === 0 ? accent : 0xffffff, 0.9);
      burst.add(spark);
      this.tweens.add({
        targets: spark,
        x: Math.cos(angle) * Phaser.Math.Between(26, 54),
        y: Math.sin(angle) * Phaser.Math.Between(18, 42),
        alpha: 0,
        duration: 520,
        ease: "Cubic.easeOut",
      });
    }
    this.tweens.add({
      targets: burst,
      y: burst.y - 16,
      alpha: 0,
      duration: 650,
      ease: "Sine.easeOut",
      onComplete: () => burst.destroy(true),
    });
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
    this.refreshDayPhaseHud();
    this.updateRadar();
  }

  private updateRadar(): void {
    if (!this.radar) return;
    const current = this.currentChunkCoords();
    const active = this.activeChunks.get(this.chunkId(current.x, current.y))?.chunk;
    const accent = active ? BIOME_ACCENTS[active.biome] : 0x6be7d6;
    const x0 = 1108;
    const y0 = 558;
    const size = 18;
    const gridX = x0 + 20;
    const gridY = y0 + 34;
    this.radar.clear();
    this.radar.fillStyle(0x061019, 0.66);
    this.radar.fillRoundedRect(x0, y0, 154, 106, 8);
    this.radar.lineStyle(1, accent, 0.42);
    this.radar.strokeRoundedRect(x0, y0, 154, 106, 8);
    for (const activeChunk of this.activeChunks.values()) {
      const dx = activeChunk.chunk.chunkX - current.x;
      const dy = activeChunk.chunk.chunkY - current.y;
      if (Math.abs(dx) > STREAM_RADIUS || Math.abs(dy) > STREAM_RADIUS) continue;
      const cellX = gridX + (dx + STREAM_RADIUS) * size;
      const cellY = gridY + (dy + STREAM_RADIUS) * size;
      const color = BIOME_ACCENTS[activeChunk.chunk.biome];
      this.radar.fillStyle(color, dx === 0 && dy === 0 ? 0.66 : 0.25);
      this.radar.fillRoundedRect(cellX, cellY, size - 4, size - 4, 4);
      if (activeChunk.chunk.encounters.some((encounter) => !this.completed.has(encounter.id))) {
        this.radar.fillStyle(0xf6c85f, 0.92);
        this.radar.fillCircle(cellX + size - 8, cellY + 5, 2.5);
      }
      if (activeChunk.chunk.treasures.some((treasure) => !this.collectedTreasures.has(treasure.id))) {
        this.radar.fillStyle(0xc7b8ff, 0.9);
        this.radar.fillCircle(cellX + 5, cellY + size - 8, 2.5);
      }
      if ([...this.hazardNodes.values()].some((entry) => entry.hazard.chunkId === activeChunk.chunk.id && !this.clearedHazards.has(entry.hazard.id) && isOutdoorHazardActive(entry.hazard, this.currentDayPhase))) {
        this.radar.fillStyle(this.currentDayPhase === "night" ? 0xff6b7a : 0xf6c85f, 0.86);
        this.radar.fillCircle(cellX + size - 8, cellY + size - 8, 2.5);
      }
    }
    this.radar.lineStyle(2, 0xf5fbff, 0.86);
    this.radar.strokeRoundedRect(gridX + STREAM_RADIUS * size - 1, gridY + STREAM_RADIUS * size - 1, size - 2, size - 2, 4);
    this.radar.fillStyle(0xf6c85f, 0.94);
    this.radar.fillCircle(x0 + 18, y0 + 92, 3);
    this.radar.fillStyle(0xc7b8ff, 0.9);
    this.radar.fillCircle(x0 + 65, y0 + 92, 3);
    this.radar.fillStyle(this.currentDayPhase === "night" ? 0xff6b7a : 0xf6c85f, 0.86);
    this.radar.fillCircle(x0 + 108, y0 + 92, 3);
    this.radar.lineStyle(1, 0x9fb6c2, 0.26);
    this.radar.lineBetween(x0 + 12, y0 + 100, x0 + 142, y0 + 100);
    this.biomeText?.setText(active ? BIOME_LABELS[active.biome] : "Zona");
    this.biomeText?.setColor(`#${accent.toString(16).padStart(6, "0")}`);
    this.coordText?.setText(`zona ${current.x}:${current.y}`);
    this.radarLegendText?.setText("sfide    tesori    rischi");
  }

  private updateObjectiveGuide(): void {
    if (!this.guideGraphics || !this.guideText || !this.avatar) return;
    const objective = this.nearestObjective();
    const x = 640;
    const y = 646;
    this.guideGraphics.clear();
    this.guideGraphics.fillStyle(0x061019, 0.78);
    this.guideGraphics.fillRoundedRect(x - 152, y - 26, 304, 58, 8);
    this.guideGraphics.lineStyle(1, 0x6be7d6, 0.28);
    this.guideGraphics.strokeRoundedRect(x - 152, y - 26, 304, 58, 8);
    if (!objective) {
      this.guideText.setText("Esplora nuove zone");
      this.guideText.setColor("#9fb6c2");
      this.guideGraphics.fillStyle(0x6be7d6, 0.18);
      this.guideGraphics.fillCircle(x - 118, y + 2, 12);
      return;
    }
    const angle = Math.atan2(objective.y - this.avatar.y, objective.x - this.avatar.x);
    const accent = BIOME_ACCENTS[objective.biome];
    const arrowX = x - 118;
    const arrowY = y + 2;
    const tipX = arrowX + Math.cos(angle) * 18;
    const tipY = arrowY + Math.sin(angle) * 18;
    const leftX = arrowX + Math.cos(angle + 2.35) * 10;
    const leftY = arrowY + Math.sin(angle + 2.35) * 10;
    const rightX = arrowX + Math.cos(angle - 2.35) * 10;
    const rightY = arrowY + Math.sin(angle - 2.35) * 10;
    this.guideGraphics.fillStyle(accent, 0.18);
    this.guideGraphics.fillCircle(arrowX, arrowY, 23);
    this.guideGraphics.fillStyle(accent, 0.95);
    this.guideGraphics.fillTriangle(tipX, tipY, leftX, leftY, rightX, rightY);
    this.guideGraphics.lineStyle(2, 0xf5fbff, 0.42);
    this.guideGraphics.lineBetween(arrowX, arrowY, tipX, tipY);
    this.guideText.setText(`${objective.label} · ${Math.max(1, Math.round(objective.distance / 90))} zone`);
    this.guideText.setColor(`#${accent.toString(16).padStart(6, "0")}`);
  }

  private nearestObjective(): { x: number; y: number; label: string; biome: OutdoorBiome; distance: number } | undefined {
    let best: { x: number; y: number; label: string; biome: OutdoorBiome; distance: number } | undefined;
    const consider = (x: number, y: number, label: string, biome: OutdoorBiome): void => {
      const distance = Math.hypot(x - this.avatar.x, y - this.avatar.y);
      if (!best || distance < best.distance) best = { x, y, label, biome, distance };
    };
    for (const encounter of this.map.encounters) {
      if (this.completed.has(encounter.id)) continue;
      consider(encounter.x, encounter.y, encounter.kind === "guardian" ? "Guardiano" : encounter.label, encounter.biome);
    }
    for (const treasure of this.map.treasures) {
      if (this.collectedTreasures.has(treasure.id)) continue;
      consider(treasure.x, treasure.y, treasure.label, treasure.biome);
    }
    return best;
  }

  private currentChunkCoords(): { x: number; y: number } {
    const source = this.avatar ?? { x: this.map.start.x, y: this.map.start.y };
    return {
      x: Math.floor(source.x / OUTDOOR_CHUNK_SIZE),
      y: Math.floor(source.y / OUTDOOR_CHUNK_SIZE),
    };
  }

  private playerShieldFor(encounter: OutdoorEncounter): number {
    let shield = encounter.kind === "guardian" ? 4 : 3;
    const outfit = rewardSystem.equippedId("avatar");
    const pet = rewardSystem.equippedId("pet");
    if (outfit === "avatar-captain" || outfit === "avatar-engineer") shield += 1;
    if (pet === "pet-guardiano" || pet === "pet-dog") shield += 1;
    return shield;
  }

  private playerDamageBonus(): number {
    let damage = 1;
    if (rewardSystem.equippedId("emblem") === "emblem-bolt") damage += 1;
    if (rewardSystem.equippedId("accessory") === "accessory-visor" && damage === 1) damage += 1;
    if (rewardSystem.equippedId("pet") === "pet-rabbit" && damage === 1) damage += 1;
    return damage;
  }

  private fragmentReward(encounter: OutdoorEncounter, correct: number, victory: boolean): number {
    const base = victory ? encounter.difficulty + (encounter.kind === "guardian" ? 4 : 1) : 1;
    const pet = rewardSystem.equippedId("pet");
    const codexBonus = pet === "pet-codex" ? 2 : 0;
    const catBonus = pet === "pet-cat" && victory ? 1 : 0;
    return Math.max(1, base + correct + codexBonus + catBonus);
  }

  private biomeAccent(biome: OutdoorBiome): number {
    return this.map.patches.find((patch) => patch.id === biome)?.accent ?? BIOME_ACCENTS[biome];
  }

  private hazardColor(hazard: OutdoorHazard): number {
    if (hazard.kind === "day-glare") return 0xf6c85f;
    if (hazard.kind === "day-dust") return 0xffb48f;
    if (hazard.kind === "night-wisp") return 0x7ad7ff;
    if (hazard.kind === "night-shadow") return 0xc7b8ff;
    return 0x9f8cff;
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
