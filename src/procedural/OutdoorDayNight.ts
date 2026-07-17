import type { OutdoorBiome, OutdoorEncounterKind } from "./OutdoorAdventureGenerator";
import type { OutdoorChunk } from "./OutdoorChunkGenerator";

export type OutdoorDayPhase = "day" | "dusk" | "night" | "dawn";
export type OutdoorHazardKind = "day-glare" | "day-dust" | "night-wisp" | "night-shadow" | "night-crystal";

export type OutdoorHazard = {
  id: string;
  chunkId: string;
  x: number;
  y: number;
  r: number;
  biome: OutdoorBiome;
  kind: OutdoorHazardKind;
  label: string;
  activeIn: "day" | "night";
  strength: number;
  encounterKind: OutdoorEncounterKind;
};

export const OUTDOOR_DAY_LENGTH_MS = 180_000;

export const OUTDOOR_PHASE_LABELS: Record<OutdoorDayPhase, string> = {
  day: "Giorno chiaro",
  dusk: "Crepuscolo",
  night: "Notte profonda",
  dawn: "Alba",
};

export const OUTDOOR_HAZARD_LABELS: Record<OutdoorHazardKind, string> = {
  "day-glare": "Riflesso caldo",
  "day-dust": "Turbine leggero",
  "night-wisp": "Fuoco fatuo",
  "night-shadow": "Ombra errante",
  "night-crystal": "Cristallo instabile",
};

const DAY_HAZARDS: Record<OutdoorBiome, OutdoorHazardKind[]> = {
  academy: ["day-glare", "day-dust"],
  ruins: ["day-dust", "day-glare"],
  geo: ["day-glare", "day-dust"],
  logic: ["day-glare", "day-dust"],
  wild: ["day-dust", "day-glare"],
  crystal: ["day-glare", "day-dust"],
};

const NIGHT_HAZARDS: Record<OutdoorBiome, OutdoorHazardKind[]> = {
  academy: ["night-wisp", "night-shadow"],
  ruins: ["night-shadow", "night-crystal"],
  geo: ["night-wisp", "night-shadow"],
  logic: ["night-crystal", "night-shadow"],
  wild: ["night-wisp", "night-shadow"],
  crystal: ["night-crystal", "night-wisp"],
};

const HAZARD_ENCOUNTERS: Record<OutdoorHazardKind, OutdoorEncounterKind> = {
  "day-glare": "mental",
  "day-dust": "times",
  "night-wisp": "capital",
  "night-shadow": "guardian",
  "night-crystal": "physicalGeo",
};

function hashSeed(seed: string): number {
  let h = 2166136261;
  for (let index = 0; index < seed.length; index += 1) {
    h ^= seed.charCodeAt(index);
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

export function phaseForOutdoorTime(elapsedMs: number, cycleMs = OUTDOOR_DAY_LENGTH_MS): OutdoorDayPhase {
  const normalized = (((elapsedMs % cycleMs) + cycleMs) % cycleMs) / cycleMs;
  if (normalized < 0.46) return "day";
  if (normalized < 0.58) return "dusk";
  if (normalized < 0.88) return "night";
  return "dawn";
}

export function isOutdoorHazardActive(hazard: Pick<OutdoorHazard, "activeIn">, phase: OutdoorDayPhase): boolean {
  if (hazard.activeIn === "night") return phase === "dusk" || phase === "night";
  return phase === "day" || phase === "dawn";
}

export function outdoorHazardDifficulty(hazard: Pick<OutdoorHazard, "activeIn" | "strength">, phase: OutdoorDayPhase): number {
  const phaseBonus = hazard.activeIn === "night" ? (phase === "night" ? 2 : 1) : 0;
  return hazard.strength + phaseBonus;
}

export function outdoorHazardReward(hazard: Pick<OutdoorHazard, "activeIn" | "strength">, phase: OutdoorDayPhase): { energy: number; fragments: number } {
  const difficulty = outdoorHazardDifficulty(hazard, phase);
  if (hazard.activeIn === "night") return { energy: 16 + difficulty * 6, fragments: 2 + hazard.strength };
  return { energy: 6 + difficulty * 3, fragments: 1 };
}

export function generateOutdoorHazardsForChunk(chunk: OutdoorChunk, worldSeed: string): OutdoorHazard[] {
  const random = rng(`${worldSeed}:hazards:${chunk.id}`);
  const hazards: OutdoorHazard[] = [];
  const pad = 118;
  const makeHazard = (slot: number, kind: OutdoorHazardKind, activeIn: "day" | "night", strength: number): OutdoorHazard => ({
    id: `hazard-${chunk.id}-${slot}-${kind}`,
    chunkId: chunk.id,
    x: between(random, chunk.patch.x + pad, chunk.patch.x + chunk.patch.w - pad),
    y: between(random, chunk.patch.y + pad, chunk.patch.y + chunk.patch.h - pad),
    r: activeIn === "night" ? 74 + strength * 8 : 54,
    biome: chunk.biome,
    kind,
    label: OUTDOOR_HAZARD_LABELS[kind],
    activeIn,
    strength,
    encounterKind: HAZARD_ENCOUNTERS[kind],
  });

  hazards.push(makeHazard(0, pick(random, DAY_HAZARDS[chunk.biome]), "day", 1));

  const nightCount = chunk.biome === "ruins" || chunk.biome === "crystal" ? 3 : 2;
  for (let index = 0; index < nightCount; index += 1) {
    const kind = pick(random, NIGHT_HAZARDS[chunk.biome]);
    hazards.push(makeHazard(index + 1, kind, "night", kind === "night-shadow" ? 3 : 2));
  }

  return hazards;
}
