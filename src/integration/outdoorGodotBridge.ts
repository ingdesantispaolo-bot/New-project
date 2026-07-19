import type { SaveData } from "../types/gameTypes";
import { saveSystem } from "../core/SaveSystem";

export const OUTDOOR_BRIDGE_SCHEMA = 1;

// Incontro che Godot rimanda a Phaser perché venga giocato con il minigioco
// NORA esistente; al termine Phaser rientra in Godot ripristinando lo stato.
export type OutdoorPendingEncounter = {
  id: string;
  x: number;
  y: number;
  biome: string;
  kind: string;
  label: string;
  enemy: string;
  difficulty: number;
  reward: number;
};

// Stato per riprendere il mondo Godot dopo un rimbalzo (posizione e ora).
export type OutdoorResumeState = {
  playerX: number;
  playerY: number;
  dayClock: number;
};

export type OutdoorWorldRequest = {
  schemaVersion: typeof OUTDOOR_BRIDGE_SCHEMA;
  playerId: string;
  worldSeed: string;
  playerLevel: number;
  returnUrl?: string;
  resume?: OutdoorResumeState;
  avatar: { outfit: string; accessory: string; pet: string };
  outdoorState: {
    completedEncounterIds: string[];
    collectedTreasureIds: string[];
    clearedHazardIds: string[];
    fragments: number;
  };
};

export type OutdoorWorldResult = {
  schemaVersion: typeof OUTDOOR_BRIDGE_SCHEMA;
  energyEarned: number;
  fragmentsEarned: number;
  completedEncounterIds: string[];
  collectedTreasureIds: string[];
  guardianWins: number;
  unlockedRewards: string[];
  pendingEncounter?: OutdoorPendingEncounter;
  resume?: OutdoorResumeState;
};

export function createOutdoorWorldRequest(save: SaveData, playerLevel: number, returnUrl?: string, resume?: OutdoorResumeState): OutdoorWorldRequest {
  const outdoor = save.outdoorAdventure;
  return {
    schemaVersion: OUTDOOR_BRIDGE_SCHEMA,
    playerId: save.playerId ?? "local",
    worldSeed: `outdoor-${outdoor?.date ?? new Date().toISOString().slice(0, 10)}-${playerLevel}`,
    playerLevel,
    ...(returnUrl ? { returnUrl } : {}),
    ...(resume ? { resume } : {}),
    avatar: {
      outfit: save.rewards?.equipped?.outfit ?? "avatar-base",
      accessory: save.rewards?.equipped?.accessory ?? "",
      pet: save.rewards?.equipped?.pet ?? "",
    },
    outdoorState: {
      completedEncounterIds: [...(outdoor?.completedEncounterIds ?? [])],
      collectedTreasureIds: [...(outdoor?.collectedTreasureIds ?? [])],
      clearedHazardIds: [],
      fragments: outdoor?.fragments ?? 0,
    },
  };
}

export function openOutdoorGodot(url: string, request: OutdoorWorldRequest): void {
  window.__ELI_OUTDOOR_REQUEST__ = request;
  window.localStorage.setItem("eli-quest-outdoor-request", JSON.stringify(request));
  window.location.assign(url);
}

export function readOutdoorWorldResult(): OutdoorWorldResult | undefined {
  let stored: OutdoorWorldResult | null = null;
  try {
    stored = JSON.parse(window.localStorage.getItem("eli-quest-outdoor-result") ?? "null") as OutdoorWorldResult | null;
  } catch {
    window.localStorage.removeItem("eli-quest-outdoor-result");
  }
  const result = window.__ELI_OUTDOOR_RESULT__ ?? stored;
  if (!result || result.schemaVersion !== OUTDOOR_BRIDGE_SCHEMA) return undefined;
  return result;
}

export function consumeOutdoorWorldResult(): OutdoorWorldResult | undefined {
  const result = readOutdoorWorldResult();
  if (!result) return undefined;
  window.__ELI_OUTDOOR_RESULT__ = undefined;
  window.localStorage.removeItem("eli-quest-outdoor-result");
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
  return result;
}

declare global {
  interface Window {
    __ELI_OUTDOOR_REQUEST__?: OutdoorWorldRequest;
    __ELI_OUTDOOR_RESULT__?: OutdoorWorldResult;
  }
}
