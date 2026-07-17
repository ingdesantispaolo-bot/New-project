import type {
  OutdoorAdventureMap,
  OutdoorBiome,
  OutdoorBiomePatch,
  OutdoorEncounter,
  OutdoorEncounterKind,
  OutdoorLandmark,
  OutdoorObstacle,
  OutdoorProp,
  OutdoorTreasure,
} from "./OutdoorAdventureGenerator";

export const OUTDOOR_CHUNK_SIZE = 896;

export type OutdoorChunkCoord = {
  x: number;
  y: number;
};

export type OutdoorChunk = {
  id: string;
  chunkX: number;
  chunkY: number;
  worldX: number;
  worldY: number;
  size: number;
  biome: OutdoorBiome;
  patch: OutdoorBiomePatch;
  obstacles: OutdoorObstacle[];
  props: OutdoorProp[];
  landmarks: OutdoorLandmark[];
  treasures: OutdoorTreasure[];
  encounters: OutdoorEncounter[];
  pathPoints: Array<{ x: number; y: number }>;
};

const BIOME_STYLE: Record<OutdoorBiome, Omit<OutdoorBiomePatch, "x" | "y" | "w" | "h">> = {
  academy: { id: "academy", label: "Radura Accademia", color: 0x173b36, accent: 0x6be7d6 },
  ruins: { id: "ruins", label: "Rovine del Relitto", color: 0x2b2334, accent: 0xff8f6b },
  geo: { id: "geo", label: "Dorsale geografica", color: 0x1c3d2e, accent: 0x8fe0a4 },
  logic: { id: "logic", label: "Cratere logico", color: 0x1c3148, accent: 0x9f8cff },
  wild: { id: "wild", label: "Bosco variabile", color: 0x1b3f32, accent: 0x74f0c5 },
  crystal: { id: "crystal", label: "Nido cristallino", color: 0x222950, accent: 0xc7b8ff },
};

const ANCHOR_BIOMES = new Map<string, OutdoorBiome>([
  ["0,0", "academy"],
  ["1,0", "logic"],
  ["-1,0", "wild"],
  ["0,1", "geo"],
  ["1,1", "crystal"],
  ["-1,-1", "ruins"],
]);

function hashSeed(seed: string): number {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i += 1) {
    h ^= seed.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function rng(seed: string): () => number {
  let a = hashSeed(seed);
  return () => {
    a += 0x6d2b79f5;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick<T>(random: () => number, values: T[]): T {
  return values[Math.floor(random() * values.length)]!;
}

function between(random: () => number, min: number, max: number): number {
  return Math.round(min + random() * (max - min));
}

function key(chunkX: number, chunkY: number): string {
  return `${chunkX},${chunkY}`;
}

function localId(prefix: string, chunkX: number, chunkY: number, index: number): string {
  return `${prefix}-${chunkX}_${chunkY}-${index}`;
}

function worldPos(random: () => number, chunkX: number, chunkY: number, pad = 86): { x: number; y: number } {
  return {
    x: Math.round(chunkX * OUTDOOR_CHUNK_SIZE + pad + random() * (OUTDOOR_CHUNK_SIZE - pad * 2)),
    y: Math.round(chunkY * OUTDOOR_CHUNK_SIZE + pad + random() * (OUTDOOR_CHUNK_SIZE - pad * 2)),
  };
}

function chunkCenter(chunkX: number, chunkY: number): { x: number; y: number } {
  return {
    x: Math.round(chunkX * OUTDOOR_CHUNK_SIZE + OUTDOOR_CHUNK_SIZE / 2),
    y: Math.round(chunkY * OUTDOOR_CHUNK_SIZE + OUTDOOR_CHUNK_SIZE / 2),
  };
}

function biomeForChunk(seed: string, chunkX: number, chunkY: number): OutdoorBiome {
  const anchored = ANCHOR_BIOMES.get(key(chunkX, chunkY));
  if (anchored) return anchored;
  const random = rng(`${seed}:biome:${Math.floor(chunkX / 2)}:${Math.floor(chunkY / 2)}`);
  const distance = Math.hypot(chunkX, chunkY);
  const pool: OutdoorBiome[] = distance < 2.5
    ? ["academy", "logic", "wild", "geo", "ruins", "crystal"]
    : ["wild", "geo", "ruins", "logic", "crystal"];
  return pick(random, pool);
}

function obstacleKind(random: () => number, biome: OutdoorBiome): OutdoorObstacle["kind"] {
  if (biome === "academy") return pick(random, ["tree", "rock", "bush"]);
  if (biome === "ruins") return pick(random, ["ruin", "crystal", "rock", "pillar"]);
  if (biome === "wild") return pick(random, ["tree", "bush", "mushroom"]);
  if (biome === "crystal") return pick(random, ["crystal", "pillar", "rock"]);
  if (biome === "geo") return pick(random, ["rock", "tree", "bush"]);
  return pick(random, ["rock", "crystal", "pillar"]);
}

function obstacleColor(kind: OutdoorObstacle["kind"]): number {
  if (kind === "tree") return 0x235b3a;
  if (kind === "bush") return 0x2b6c45;
  if (kind === "mushroom") return 0x9f8cff;
  if (kind === "crystal") return 0x7ad7ff;
  if (kind === "ruin" || kind === "pillar") return 0x4b4252;
  return 0x46545c;
}

function propKind(random: () => number, biome: OutdoorBiome, index: number): OutdoorProp["kind"] {
  const signature: OutdoorProp["kind"] = biome === "academy"
    ? "camp"
    : biome === "geo"
      ? pick(random, ["river", "waterfall", "bridge"])
      : biome === "ruins"
        ? pick(random, ["tower", "arch", "statue"])
        : biome === "wild"
          ? pick(random, ["garden", "well", "river"])
          : biome === "crystal"
            ? pick(random, ["beacon", "arch", "garden"])
            : "lamp";
  if (index === 0) return signature;
  return pick(random, ["sign", "lamp", "river", "tower", "camp", "waterfall", "bridge", "statue", "beacon", "garden", "well", "arch"]);
}

function landmarkForChunk(random: () => number, biome: OutdoorBiome, chunkX: number, chunkY: number): Pick<OutdoorLandmark, "kind" | "label"> | undefined {
  if (chunkX === 0 && chunkY === 0) return { kind: "forge", label: "Forgia Esterna" };
  if (chunkX === 1 && chunkY === 0) return { kind: "logicSpire", label: "Spira Logica" };
  if (chunkX === 0 && chunkY === 1) return { kind: "atlasGate", label: "Porta dell'Atlante" };
  if (chunkX === -1 && chunkY === -1) return { kind: "ancientCore", label: "Nucleo Antico" };
  if (chunkX === -1 && chunkY === 0) return { kind: "skyTree", label: "Albero dei Percorsi" };
  if (chunkX === 1 && chunkY === 1) return { kind: "crystalNest", label: "Nido Prisma" };
  if (random() > 0.18) return undefined;
  if (biome === "geo") return { kind: "atlasGate", label: "Porta dell'Atlante" };
  if (biome === "logic") return { kind: "logicSpire", label: "Spira Logica" };
  if (biome === "ruins") return { kind: "ancientCore", label: "Nucleo Antico" };
  if (biome === "wild") return { kind: "skyTree", label: "Albero dei Percorsi" };
  if (biome === "crystal") return { kind: "crystalNest", label: "Nido Prisma" };
  return { kind: "forge", label: "Campo officina" };
}

function encounterPlans(random: () => number, biome: OutdoorBiome, chunkX: number, chunkY: number): Array<{ kind: OutdoorEncounterKind; label: string; enemy: string }> {
  const plans: Record<OutdoorBiome, Array<{ kind: OutdoorEncounterKind; label: string; enemy: string }>> = {
    academy: [
      { kind: "times", label: "Sentiero tabelline", enemy: "Drone Moltiplica" },
      { kind: "mental", label: "Sprint mentale", enemy: "Sentinella Rapida" },
    ],
    wild: [
      { kind: "times", label: "Radici dei prodotti", enemy: "Ramo Pattern" },
      { kind: "physicalGeo", label: "Sentiero natura", enemy: "Custode del Bosco" },
    ],
    logic: [
      { kind: "times", label: "Anello dei prodotti", enemy: "Modulo Pattern" },
      { kind: "mental", label: "Cratere dei calcoli", enemy: "Eco Numerico" },
    ],
    crystal: [
      { kind: "mental", label: "Specchi numerici", enemy: "Cristallo Rapido" },
      { kind: "guardian", label: "Nido prismatico", enemy: "Guardiano Prisma" },
    ],
    geo: [
      { kind: "capital", label: "Capitali e continenti", enemy: "Atlante Errante" },
      { kind: "physicalGeo", label: "Fiumi, laghi, montagne", enemy: "Custode delle Carte" },
    ],
    ruins: [
      { kind: "mental", label: "Rovine operative", enemy: "Guardia del Relitto" },
      { kind: "capital", label: "Rotte del mondo", enemy: "Navigatore Smarrito" },
      { kind: "guardian", label: "Cuore del Relitto", enemy: "Sentinella Antica" },
    ],
  };
  const count = chunkX === 0 && chunkY === 0 ? 2 : random() > 0.56 ? 2 : 1;
  return plans[biome].slice().sort(() => random() - 0.5).slice(0, count);
}

export function generateOutdoorChunk(seed: string, chunkX: number, chunkY: number): OutdoorChunk {
  const random = rng(`${seed}:chunk:${chunkX}:${chunkY}`);
  const biome = biomeForChunk(seed, chunkX, chunkY);
  const style = BIOME_STYLE[biome];
  const worldX = chunkX * OUTDOOR_CHUNK_SIZE;
  const worldY = chunkY * OUTDOOR_CHUNK_SIZE;
  const patch: OutdoorBiomePatch = {
    ...style,
    id: biome,
    label: style.label,
    x: worldX - between(random, 22, 54),
    y: worldY - between(random, 22, 54),
    w: OUTDOOR_CHUNK_SIZE + between(random, 44, 108),
    h: OUTDOOR_CHUNK_SIZE + between(random, 44, 108),
  };

  const obstacleCount = between(random, 15, 24);
  const obstacles: OutdoorObstacle[] = Array.from({ length: obstacleCount }, (_, index) => {
    const kind = obstacleKind(random, biome);
    const pos = worldPos(random, chunkX, chunkY, 72);
    return {
      id: localId("obs", chunkX, chunkY, index),
      x: pos.x,
      y: pos.y,
      r: between(random, 16, 42),
      kind,
      color: obstacleColor(kind),
    };
  });

  const propCount = between(random, 6, 11);
  const props: OutdoorProp[] = Array.from({ length: propCount }, (_, index) => {
    const pos = worldPos(random, chunkX, chunkY, 78);
    return {
      id: localId("prop", chunkX, chunkY, index),
      x: pos.x,
      y: pos.y,
      kind: propKind(random, biome, index),
      color: style.accent,
    };
  });

  const landmarkPlan = landmarkForChunk(random, biome, chunkX, chunkY);
  const landmarks: OutdoorLandmark[] = landmarkPlan
    ? [{
      id: localId("landmark", chunkX, chunkY, 0),
      ...worldPos(random, chunkX, chunkY, 180),
      biome,
      kind: landmarkPlan.kind,
      label: landmarkPlan.label,
      color: style.accent,
    }]
    : [];

  const encounters: OutdoorEncounter[] = encounterPlans(random, biome, chunkX, chunkY).map((plan, index) => {
    const distance = Math.hypot(chunkX, chunkY);
    const difficulty = plan.kind === "guardian" ? 4 + Math.min(3, Math.floor(distance / 2)) : 1 + Math.floor(random() * 3) + Math.min(2, Math.floor(distance / 4));
    return {
      id: localId("enc", chunkX, chunkY, index),
      ...worldPos(random, chunkX, chunkY, 132),
      biome,
      kind: plan.kind,
      label: plan.label,
      enemy: plan.enemy,
      difficulty,
      reward: plan.kind === "guardian" ? 72 + difficulty * 6 : 22 + difficulty * 8,
    };
  });

  const treasureCount = between(random, 1, 3);
  const treasures: OutdoorTreasure[] = Array.from({ length: treasureCount }, (_, index) => ({
    id: localId("treasure", chunkX, chunkY, index),
    ...worldPos(random, chunkX, chunkY, 120),
    biome,
    label: index === 0 && random() > 0.68 ? "scrigno raro" : random() > 0.52 ? "cassa energia" : "frammenti dispersi",
    rewardEnergy: between(random, 7, 24) + Math.min(18, Math.floor(Math.hypot(chunkX, chunkY) * 2)),
    rewardFragments: between(random, 2, 9) + (random() > 0.78 ? 4 : 0),
  }));

  const center = chunkCenter(chunkX, chunkY);
  const pathPoints = [
    { x: worldX, y: center.y },
    center,
    { x: worldX + OUTDOOR_CHUNK_SIZE, y: center.y },
    center,
    { x: center.x, y: worldY },
    center,
    { x: center.x, y: worldY + OUTDOOR_CHUNK_SIZE },
  ];

  return {
    id: `chunk-${chunkX}_${chunkY}`,
    chunkX,
    chunkY,
    worldX,
    worldY,
    size: OUTDOOR_CHUNK_SIZE,
    biome,
    patch,
    obstacles,
    props,
    landmarks,
    treasures,
    encounters,
    pathPoints,
  };
}

export function generateOutdoorAdventureRegion(seed: string, radiusX = 2, radiusY = 2): OutdoorAdventureMap {
  const chunks: OutdoorChunk[] = [];
  for (let y = -radiusY; y <= radiusY; y += 1) {
    for (let x = -radiusX; x <= radiusX; x += 1) {
      chunks.push(generateOutdoorChunk(seed, x, y));
    }
  }

  const minX = -radiusX * OUTDOOR_CHUNK_SIZE;
  const minY = -radiusY * OUTDOOR_CHUNK_SIZE;
  const offsetX = -minX;
  const offsetY = -minY;
  const shiftPoint = <T extends { x: number; y: number }>(item: T): T => ({ ...item, x: item.x + offsetX, y: item.y + offsetY });
  const shiftPatch = (patch: OutdoorBiomePatch): OutdoorBiomePatch => ({ ...patch, x: patch.x + offsetX, y: patch.y + offsetY });
  const shiftedChunks = chunks.map((chunk) => ({
    patch: shiftPatch(chunk.patch),
    obstacles: chunk.obstacles.map(shiftPoint),
    props: chunk.props.map(shiftPoint),
    landmarks: chunk.landmarks.map(shiftPoint),
    treasures: chunk.treasures.map(shiftPoint),
    encounters: chunk.encounters.map(shiftPoint),
    pathPoints: chunk.pathPoints.map(shiftPoint),
  }));
  const start = shiftPoint({ x: OUTDOOR_CHUNK_SIZE / 2, y: OUTDOOR_CHUNK_SIZE / 2 });
  const hub = shiftPoint(chunkCenter(0, 0));
  const centers = chunks
    .map((chunk) => shiftPoint(chunkCenter(chunk.chunkX, chunk.chunkY)))
    .sort((a, b) => Math.atan2(a.y - hub.y, a.x - hub.x) - Math.atan2(b.y - hub.y, b.x - hub.x));

  return {
    seed,
    width: (radiusX * 2 + 1) * OUTDOOR_CHUNK_SIZE,
    height: (radiusY * 2 + 1) * OUTDOOR_CHUNK_SIZE,
    start,
    patches: shiftedChunks.map((chunk) => chunk.patch),
    obstacles: shiftedChunks.flatMap((chunk) => chunk.obstacles).filter((obstacle) => Math.hypot(obstacle.x - start.x, obstacle.y - start.y) > 170),
    props: shiftedChunks.flatMap((chunk) => chunk.props),
    landmarks: shiftedChunks.flatMap((chunk) => chunk.landmarks),
    treasures: shiftedChunks.flatMap((chunk) => chunk.treasures),
    encounters: shiftedChunks.flatMap((chunk) => chunk.encounters),
    pathPoints: [start, hub, ...centers, hub],
  };
}
