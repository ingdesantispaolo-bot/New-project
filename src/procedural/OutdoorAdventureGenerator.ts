export type OutdoorBiome = "academy" | "ruins" | "geo" | "logic";
export type OutdoorEncounterKind = "times" | "mental" | "capital" | "physicalGeo" | "guardian";

export type OutdoorBiomePatch = {
  id: OutdoorBiome;
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  color: number;
  accent: number;
};

export type OutdoorObstacle = {
  id: string;
  x: number;
  y: number;
  r: number;
  kind: "rock" | "tree" | "crystal" | "ruin";
  color: number;
};

export type OutdoorProp = {
  id: string;
  x: number;
  y: number;
  kind: "sign" | "lamp" | "river" | "tower" | "camp";
  color: number;
};

export type OutdoorEncounter = {
  id: string;
  x: number;
  y: number;
  biome: OutdoorBiome;
  kind: OutdoorEncounterKind;
  label: string;
  enemy: string;
  difficulty: number;
  reward: number;
};

export type OutdoorAdventureMap = {
  seed: string;
  width: number;
  height: number;
  start: { x: number; y: number };
  patches: OutdoorBiomePatch[];
  obstacles: OutdoorObstacle[];
  props: OutdoorProp[];
  encounters: OutdoorEncounter[];
};

const BIOMES: Record<OutdoorBiome, Omit<OutdoorBiomePatch, "x" | "y" | "w" | "h">> = {
  academy: { id: "academy", label: "Radura Accademia", color: 0x173b36, accent: 0x6be7d6 },
  ruins: { id: "ruins", label: "Rovine del Relitto", color: 0x2b2334, accent: 0xff8f6b },
  geo: { id: "geo", label: "Dorsale geografica", color: 0x1c3d2e, accent: 0x8fe0a4 },
  logic: { id: "logic", label: "Cratere logico", color: 0x1c3148, accent: 0x9f8cff },
};

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

function jitter(random: () => number, amount: number): number {
  return (random() - 0.5) * amount;
}

export function generateOutdoorAdventureMap(seed: string): OutdoorAdventureMap {
  const random = rng(seed);
  const width = 2240;
  const height = 1540;
  const patches: OutdoorBiomePatch[] = [
    { ...BIOMES.academy, x: 120, y: 390, w: 760, h: 650 },
    { ...BIOMES.ruins, x: 1010, y: 120, w: 930, h: 560 },
    { ...BIOMES.geo, x: 980, y: 850, w: 1040, h: 520 },
    { ...BIOMES.logic, x: 520, y: 230, w: 880, h: 900 },
  ].map((patch) => ({
    ...patch,
    x: Math.round(patch.x + jitter(random, 70)),
    y: Math.round(patch.y + jitter(random, 60)),
    w: Math.round(patch.w + jitter(random, 80)),
    h: Math.round(patch.h + jitter(random, 80)),
  }));

  const obstacles: OutdoorObstacle[] = [];
  const obstacleKinds: OutdoorObstacle["kind"][] = ["rock", "tree", "crystal", "ruin"];
  for (let i = 0; i < 54; i += 1) {
    const patch = pick(random, patches);
    const kind = patch.id === "academy" ? pick(random, ["tree", "rock"] as OutdoorObstacle["kind"][]) : patch.id === "ruins" ? pick(random, ["ruin", "crystal", "rock"] as OutdoorObstacle["kind"][]) : pick(random, obstacleKinds);
    obstacles.push({
      id: `obs-${i}`,
      x: Math.round(patch.x + 70 + random() * (patch.w - 140)),
      y: Math.round(patch.y + 70 + random() * (patch.h - 140)),
      r: Math.round(20 + random() * 24),
      kind,
      color: kind === "tree" ? 0x235b3a : kind === "crystal" ? 0x7ad7ff : kind === "ruin" ? 0x4b4252 : 0x46545c,
    });
  }

  const propKinds: OutdoorProp["kind"][] = ["sign", "lamp", "river", "tower", "camp"];
  const props: OutdoorProp[] = patches.flatMap((patch, patchIndex) => Array.from({ length: 5 }, (_, i) => {
    const kind = i === 0 ? (patch.id === "academy" ? "camp" : patch.id === "geo" ? "river" : patch.id === "ruins" ? "tower" : "lamp") : pick(random, propKinds);
    return {
      id: `prop-${patchIndex}-${i}`,
      x: Math.round(patch.x + 80 + random() * (patch.w - 160)),
      y: Math.round(patch.y + 80 + random() * (patch.h - 160)),
      kind,
      color: patch.accent,
    };
  }));

  const encounterPlan: Array<{ biome: OutdoorBiome; kind: OutdoorEncounterKind; label: string; enemy: string }> = [
    { biome: "academy", kind: "times", label: "Sentiero tabelline", enemy: "Drone Moltiplica" },
    { biome: "academy", kind: "mental", label: "Sprint mentale", enemy: "Sentinella Rapida" },
    { biome: "logic", kind: "times", label: "Anello dei prodotti", enemy: "Modulo Pattern" },
    { biome: "logic", kind: "mental", label: "Cratere dei calcoli", enemy: "Eco Numerico" },
    { biome: "geo", kind: "capital", label: "Capitali e continenti", enemy: "Atlante Errante" },
    { biome: "geo", kind: "physicalGeo", label: "Fiumi, laghi, montagne", enemy: "Custode delle Carte" },
    { biome: "ruins", kind: "mental", label: "Rovine operative", enemy: "Guardia del Relitto" },
    { biome: "ruins", kind: "capital", label: "Rotte del mondo", enemy: "Navigatore Smarrito" },
    { biome: "logic", kind: "guardian", label: "Guardiano esterno", enemy: "Guardiano Prisma" },
  ];

  const encounters = encounterPlan.map((plan, index) => {
    const patch = patches.find((candidate) => candidate.id === plan.biome)!;
    const difficulty = plan.kind === "guardian" ? 4 : 1 + Math.floor(random() * 3);
    return {
      id: `enc-${index}`,
      x: Math.round(patch.x + 110 + random() * (patch.w - 220)),
      y: Math.round(patch.y + 110 + random() * (patch.h - 220)),
      biome: plan.biome,
      kind: plan.kind,
      label: plan.label,
      enemy: plan.enemy,
      difficulty,
      reward: plan.kind === "guardian" ? 72 : 22 + difficulty * 8,
    };
  });

  return {
    seed,
    width,
    height,
    start: { x: 310, y: 780 },
    patches,
    obstacles: obstacles.filter((obstacle) => Math.hypot(obstacle.x - 310, obstacle.y - 780) > 150),
    props,
    encounters,
  };
}
