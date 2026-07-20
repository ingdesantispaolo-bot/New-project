import type { SaveData } from "../types/gameTypes";

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

// Cosmetici equipaggiati risolti in dati visivi (colori 0xRRGGBB) così Godot
// li rende senza conoscere il catalogo. Chiude il loop shopping ↔ avventura:
// ciò che compri nella bottega si vede addosso a Eli e nel pet che la segue.
export type OutdoorAvatarVisual = {
  bodyColor: number;
  accessory: { id: string; color: number } | null;
  pet: { id: string; kind: string; color: number } | null;
};

// Prossimo cosmetico-obiettivo mostrato nell'HUD Godot (goal-gradient): dà al
// giocatore un traguardo concreto verso cui raccogliere energia.
export type OutdoorNextReward = {
  name: string;
  cost: number;
  rarity: string;
};

// Dati di presentazione risolti da Phaser (cosmetici + economia) per l'HUD e
// l'avatar del mondo Godot. Raggruppati per non allungare la firma della
// richiesta e per tenere il resolver fuori dal bridge.
export type OutdoorPresentation = {
  avatarVisual?: OutdoorAvatarVisual;
  energy?: number;
  nextReward?: OutdoorNextReward | null;
};

export type OutdoorWorldRequest = {
  schemaVersion: typeof OUTDOOR_BRIDGE_SCHEMA;
  playerId: string;
  worldSeed: string;
  playerLevel: number;
  returnUrl?: string;
  resume?: OutdoorResumeState;
  avatar: { outfit: string; accessory: string; pet: string };
  avatarVisual?: OutdoorAvatarVisual;
  energy?: number;
  nextReward?: OutdoorNextReward;
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

export function createOutdoorWorldRequest(save: SaveData, playerLevel: number, returnUrl?: string, resume?: OutdoorResumeState, presentation?: OutdoorPresentation): OutdoorWorldRequest {
  const outdoor = save.outdoorAdventure;
  return {
    schemaVersion: OUTDOOR_BRIDGE_SCHEMA,
    playerId: save.playerId ?? "local",
    worldSeed: `outdoor-${outdoor?.date ?? new Date().toISOString().slice(0, 10)}-${playerLevel}`,
    playerLevel,
    ...(returnUrl ? { returnUrl } : {}),
    ...(resume ? { resume } : {}),
    ...(presentation?.avatarVisual ? { avatarVisual: presentation.avatarVisual } : {}),
    ...(presentation?.energy !== undefined ? { energy: presentation.energy } : {}),
    ...(presentation?.nextReward ? { nextReward: presentation.nextReward } : {}),
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
  // Never let a previous Godot session be consumed as the result of this one.
  window.__ELI_OUTDOOR_RESULT__ = undefined;
  window.localStorage.removeItem("eli-quest-outdoor-result");
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
  return result;
}

declare global {
  interface Window {
    __ELI_OUTDOOR_REQUEST__?: OutdoorWorldRequest;
    __ELI_OUTDOOR_RESULT__?: OutdoorWorldResult;
  }
}
