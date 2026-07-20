import { rewardSystem, type Cosmetic } from "../core/RewardSystem";
import { saveSystem } from "../core/SaveSystem";
import type { OutdoorAvatarVisual, OutdoorNextReward, OutdoorPresentation } from "./outdoorGodotBridge";

// Colori di ripiego coerenti con l'accento del player Godot.
const DEFAULT_BODY = 0x6be7d6;
const DEFAULT_ACCESSORY = 0x9ff5e9;
const DEFAULT_PET = 0xf6c85f;

/**
 * Risolve i cosmetici equipaggiati (bottega) in dati visivi per il mondo Godot.
 * Tenuto fuori dal bridge per non accoppiarlo a rewardSystem: le scene lo
 * chiamano e passano il risultato a `createOutdoorWorldRequest`.
 */
export function resolveOutdoorAvatarVisual(): OutdoorAvatarVisual {
  const bodyColor = rewardSystem.colorForSlot("avatar", DEFAULT_BODY);
  const accessory = rewardSystem.equipped("accessory");
  const pet = rewardSystem.equipped("pet");
  return {
    bodyColor,
    accessory: accessory ? { id: accessory.id, color: accessory.color ?? DEFAULT_ACCESSORY } : null,
    pet: pet ? { id: pet.id, kind: pet.id.replace(/^pet-/, ""), color: pet.color ?? DEFAULT_PET } : null,
  };
}

function rarityLabel(cosmetic: Cosmetic): string {
  if ((cosmetic.minLevel ?? 0) >= 8 || cosmetic.cost >= 3000) return "leggendario";
  if ((cosmetic.minLevel ?? 0) >= 6 || cosmetic.cost >= 1200) return "epico";
  if ((cosmetic.minLevel ?? 0) >= 4 || cosmetic.cost >= 500) return "raro";
  return "comune";
}

/**
 * Prossimo cosmetico-obiettivo per l'HUD: il più economico non ancora posseduto
 * e alla portata di livello che il giocatore non può ancora permettersi (gap da
 * colmare = motivazione). Se può già comprare tutto ciò che gli manca, punta al
 * più economico ("puoi comprarlo!").
 */
export function resolveOutdoorNextReward(playerLevel: number): OutdoorNextReward | null {
  const owned = new Set(saveSystem.rewards.unlocked);
  const energy = rewardSystem.energy();
  const candidates = rewardSystem.catalog
    .filter((cosmetic) => !owned.has(cosmetic.id) && (cosmetic.minLevel ?? 0) <= playerLevel)
    .sort((a, b) => a.cost - b.cost);
  if (candidates.length === 0) return null;
  const target = candidates.find((cosmetic) => cosmetic.cost > energy) ?? candidates[0]!;
  return { name: target.name, cost: target.cost, rarity: rarityLabel(target) };
}

/** Pacchetto di presentazione (avatar + economia) passato al mondo Godot. */
export function resolveOutdoorPresentation(playerLevel: number): OutdoorPresentation {
  return {
    avatarVisual: resolveOutdoorAvatarVisual(),
    energy: rewardSystem.energy(),
    nextReward: resolveOutdoorNextReward(playerLevel),
  };
}
