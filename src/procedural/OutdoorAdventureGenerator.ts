export type OutdoorBiome = "academy" | "ruins" | "geo" | "logic" | "wild" | "crystal";
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
  kind: "rock" | "tree" | "crystal" | "ruin" | "bush" | "pillar" | "mushroom";
  color: number;
};

export type OutdoorProp = {
  id: string;
  x: number;
  y: number;
  kind: "sign" | "lamp" | "river" | "tower" | "camp" | "waterfall" | "bridge" | "statue" | "beacon" | "garden" | "well" | "arch";
  color: number;
};

export type OutdoorLandmark = {
  id: string;
  x: number;
  y: number;
  biome: OutdoorBiome;
  kind: "forge" | "atlasGate" | "logicSpire" | "ancientCore" | "skyTree" | "crystalNest";
  label: string;
  color: number;
};

export type OutdoorTreasure = {
  id: string;
  x: number;
  y: number;
  biome: OutdoorBiome;
  label: string;
  rewardEnergy: number;
  rewardFragments: number;
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
  landmarks: OutdoorLandmark[];
  treasures: OutdoorTreasure[];
  encounters: OutdoorEncounter[];
  pathPoints: Array<{ x: number; y: number }>;
};

const BIOMES: Record<OutdoorBiome, Omit<OutdoorBiomePatch, "x" | "y" | "w" | "h">> = {
  academy: { id: "academy", label: "Radura Accademia", color: 0x173b36, accent: 0x6be7d6 },
  ruins: { id: "ruins", label: "Rovine del Relitto", color: 0x2b2334, accent: 0xff8f6b },
  geo: { id: "geo", label: "Dorsale geografica", color: 0x1c3d2e, accent: 0x8fe0a4 },
  logic: { id: "logic", label: "Cratere logico", color: 0x1c3148, accent: 0x9f8cff },
  wild: { id: "wild", label: "Bosco variabile", color: 0x1b3f32, accent: 0x74f0c5 },
  crystal: { id: "crystal", label: "Nido cristallino", color: 0x222950, accent: 0xc7b8ff },
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

function center(patch: OutdoorBiomePatch): { x: number; y: number } {
  return { x: Math.round(patch.x + patch.w / 2), y: Math.round(patch.y + patch.h / 2) };
}

function insidePatch(random: () => number, patch: OutdoorBiomePatch, pad = 100): { x: number; y: number } {
  return {
    x: Math.round(patch.x + pad + random() * Math.max(1, patch.w - pad * 2)),
    y: Math.round(patch.y + pad + random() * Math.max(1, patch.h - pad * 2)),
  };
}

export function generateOutdoorAdventureMap(seed: string): OutdoorAdventureMap {
  const random = rng(seed);
  const width = 3400;
  const height = 2380;
  const patches: OutdoorBiomePatch[] = [
    { ...BIOMES.academy, x: 140, y: 760, w: 780, h: 660 },
    { ...BIOMES.logic, x: 760, y: 260, w: 900, h: 760 },
    { ...BIOMES.ruins, x: 1730, y: 130, w: 970, h: 640 },
    { ...BIOMES.geo, x: 1860, y: 1240, w: 1040, h: 640 },
    { ...BIOMES.wild, x: 380, y: 1580, w: 900, h: 560 },
    { ...BIOMES.crystal, x: 2490, y: 690, w: 720, h: 700 },
  ].map((patch) => ({
    ...patch,
    x: Math.round(patch.x + jitter(random, 180)),
    y: Math.round(patch.y + jitter(random, 150)),
    w: Math.round(patch.w + jitter(random, 140)),
    h: Math.round(patch.h + jitter(random, 140)),
  }));

  const obstacles: OutdoorObstacle[] = [];
  const obstacleKinds: OutdoorObstacle["kind"][] = ["rock", "tree", "crystal", "ruin", "bush", "pillar", "mushroom"];
  for (let i = 0; i < 128; i += 1) {
    const patch = pick(random, patches);
    const kind = patch.id === "academy"
      ? pick(random, ["tree", "rock", "bush"] as OutdoorObstacle["kind"][])
      : patch.id === "ruins"
        ? pick(random, ["ruin", "crystal", "rock", "pillar"] as OutdoorObstacle["kind"][])
        : patch.id === "wild"
          ? pick(random, ["tree", "bush", "mushroom"] as OutdoorObstacle["kind"][])
          : patch.id === "crystal"
            ? pick(random, ["crystal", "pillar", "rock"] as OutdoorObstacle["kind"][])
            : pick(random, obstacleKinds);
    const pos = insidePatch(random, patch, 70);
    obstacles.push({
      id: `obs-${i}`,
      x: pos.x,
      y: pos.y,
      r: Math.round(16 + random() * 30),
      kind,
      color: kind === "tree" ? 0x235b3a : kind === "bush" ? 0x2b6c45 : kind === "mushroom" ? 0x9f8cff : kind === "crystal" ? 0x7ad7ff : kind === "ruin" || kind === "pillar" ? 0x4b4252 : 0x46545c,
    });
  }

  const propKinds: OutdoorProp["kind"][] = ["sign", "lamp", "river", "tower", "camp", "waterfall", "bridge", "statue", "beacon", "garden", "well", "arch"];
  const props: OutdoorProp[] = patches.flatMap((patch, patchIndex) => Array.from({ length: 9 + Math.floor(random() * 5) }, (_, i) => {
    const signature: OutdoorProp["kind"] = patch.id === "academy" ? "camp" : patch.id === "geo" ? pick(random, ["river", "waterfall", "bridge"]) : patch.id === "ruins" ? pick(random, ["tower", "arch", "statue"]) : patch.id === "wild" ? pick(random, ["garden", "well", "river"]) : patch.id === "crystal" ? pick(random, ["beacon", "arch", "garden"]) : "lamp";
    const kind = i === 0 ? signature : pick(random, propKinds);
    const pos = insidePatch(random, patch, 80);
    return {
      id: `prop-${patchIndex}-${i}`,
      x: pos.x,
      y: pos.y,
      kind,
      color: patch.accent,
    };
  }));

  const landmarkPlans: Array<{ biome: OutdoorBiome; kind: OutdoorLandmark["kind"]; label: string }> = [
    { biome: "academy", kind: "forge", label: "Forgia Esterna" },
    { biome: "geo", kind: "atlasGate", label: "Porta dell'Atlante" },
    { biome: "logic", kind: "logicSpire", label: "Spira Logica" },
    { biome: "ruins", kind: "ancientCore", label: "Nucleo Antico" },
    { biome: "wild", kind: "skyTree", label: "Albero dei Percorsi" },
    { biome: "crystal", kind: "crystalNest", label: "Nido Prisma" },
  ];
  const landmarks: OutdoorLandmark[] = landmarkPlans.map((plan, index) => {
    const patch = patches.find((candidate) => candidate.id === plan.biome)!;
    const pos = insidePatch(random, patch, 150);
    return { id: `landmark-${index}`, x: pos.x, y: pos.y, biome: plan.biome, kind: plan.kind, label: plan.label, color: patch.accent };
  });

  const encounterPlan: Array<{ biome: OutdoorBiome; kind: OutdoorEncounterKind; label: string; enemy: string }> = [
    { biome: "academy", kind: "times", label: "Sentiero tabelline", enemy: "Drone Moltiplica" },
    { biome: "academy", kind: "mental", label: "Sprint mentale", enemy: "Sentinella Rapida" },
    { biome: "wild", kind: "times", label: "Radici dei prodotti", enemy: "Ramo Pattern" },
    { biome: "wild", kind: "physicalGeo", label: "Sentiero natura", enemy: "Custode del Bosco" },
    { biome: "logic", kind: "times", label: "Anello dei prodotti", enemy: "Modulo Pattern" },
    { biome: "logic", kind: "mental", label: "Cratere dei calcoli", enemy: "Eco Numerico" },
    { biome: "crystal", kind: "mental", label: "Specchi numerici", enemy: "Cristallo Rapido" },
    { biome: "crystal", kind: "guardian", label: "Nido prismatico", enemy: "Guardiano Prisma" },
    { biome: "geo", kind: "capital", label: "Capitali e continenti", enemy: "Atlante Errante" },
    { biome: "geo", kind: "physicalGeo", label: "Fiumi, laghi, montagne", enemy: "Custode delle Carte" },
    { biome: "ruins", kind: "mental", label: "Rovine operative", enemy: "Guardia del Relitto" },
    { biome: "ruins", kind: "capital", label: "Rotte del mondo", enemy: "Navigatore Smarrito" },
    { biome: "ruins", kind: "guardian", label: "Cuore del Relitto", enemy: "Sentinella Antica" },
  ];

  const encounters = encounterPlan.map((plan, index) => {
    const patch = patches.find((candidate) => candidate.id === plan.biome)!;
    const difficulty = plan.kind === "guardian" ? 4 : 1 + Math.floor(random() * 3);
    const pos = insidePatch(random, patch, 120);
    return {
      id: `enc-${index}`,
      x: pos.x,
      y: pos.y,
      biome: plan.biome,
      kind: plan.kind,
      label: plan.label,
      enemy: plan.enemy,
      difficulty,
      reward: plan.kind === "guardian" ? 72 : 22 + difficulty * 8,
    };
  });

  const treasures: OutdoorTreasure[] = Array.from({ length: 14 }, (_, index) => {
    const patch = pick(random, patches);
    const pos = insidePatch(random, patch, 120);
    return {
      id: `treasure-${index}`,
      x: pos.x,
      y: pos.y,
      biome: patch.id,
      label: index % 4 === 0 ? "scrigno raro" : index % 3 === 0 ? "cassa energia" : "frammenti dispersi",
      rewardEnergy: index % 3 === 0 ? 18 + Math.floor(random() * 20) : 6 + Math.floor(random() * 12),
      rewardFragments: index % 4 === 0 ? 7 + Math.floor(random() * 7) : 2 + Math.floor(random() * 5),
    };
  });

  const patchCenters = patches.map(center);
  const hub = { x: Math.round(width * 0.47 + jitter(random, 140)), y: Math.round(height * 0.5 + jitter(random, 140)) };
  const pathPoints = [ { x: 310, y: 1120 }, hub, ...patchCenters.sort((a, b) => Math.atan2(a.y - hub.y, a.x - hub.x) - Math.atan2(b.y - hub.y, b.x - hub.x)), hub ];

  return {
    seed,
    width,
    height,
    start: { x: 310, y: 1120 },
    patches,
    obstacles: obstacles.filter((obstacle) => Math.hypot(obstacle.x - 310, obstacle.y - 1120) > 170),
    props,
    landmarks,
    treasures,
    encounters,
    pathPoints,
  };
}
