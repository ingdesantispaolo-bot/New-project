import { saveSystem } from "./SaveSystem";

export type CosmeticSlot = "bot" | "avatar" | "emblem";

export type Cosmetic = {
  id: string;
  slot: CosmeticSlot;
  name: string;
  description: string;
  cost: number;
  /** Colour applied to Bit / the avatar for colour cosmetics. */
  color?: number;
  /** Emblem glyph for the trophy slot. */
  glyph?: string;
};

/**
 * Reward economy: the energy earned by answering (see OutcomeFeedback) is a real
 * currency, spent here on cosmetics that actually change the game — Bit's colour,
 * the explorable-room avatar's colour, and academy emblems. Gives the practice
 * loop a tangible, persistent progression.
 */
const CATALOG: Cosmetic[] = [
  // --- Bit, il compagno ---------------------------------------------------
  { id: "bot-lime", slot: "bot", name: "Bit Lime", description: "Verde acido brillante per il tuo compagno.", cost: 120, color: 0x7cf6a6 },
  { id: "bot-gold", slot: "bot", name: "Bit Oro", description: "Un Bit dorato da campione.", cost: 260, color: 0xf6c85f },
  { id: "bot-violet", slot: "bot", name: "Bit Viola", description: "Look notturno viola-neon.", cost: 260, color: 0x9f8cff },
  { id: "bot-rose", slot: "bot", name: "Bit Rosa", description: "Rosa acceso, impossibile non notarlo.", cost: 480, color: 0xff7b9c },
  // --- Avatar della stanza ------------------------------------------------
  { id: "avatar-gold", slot: "avatar", name: "Tuta Oro", description: "Colore oro per l'esploratore.", cost: 220, color: 0xf6c85f },
  { id: "avatar-violet", slot: "avatar", name: "Tuta Viola", description: "Colore viola per l'esploratore.", cost: 220, color: 0x9f8cff },
  { id: "avatar-emerald", slot: "avatar", name: "Tuta Smeraldo", description: "Verde smeraldo brillante.", cost: 380, color: 0x2ed889 },
  { id: "avatar-crimson", slot: "avatar", name: "Tuta Cremisi", description: "Rosso deciso da veterano.", cost: 560, color: 0xc94b55 },
  // --- Emblemi (trofei da esporre) ----------------------------------------
  { id: "emblem-star", slot: "emblem", name: "Emblema Stella", description: "Un trofeo che dice: costanza.", cost: 400, glyph: "⭐" },
  { id: "emblem-bolt", slot: "emblem", name: "Emblema Fulmine", description: "Per chi va veloce e preciso.", cost: 720, glyph: "⚡" },
  { id: "emblem-crown", slot: "emblem", name: "Emblema Corona", description: "Il premio dei più costanti.", cost: 1200, glyph: "👑" },
];

class RewardSystem {
  get catalog(): Cosmetic[] {
    return CATALOG;
  }

  bySlot(slot: CosmeticSlot): Cosmetic[] {
    return CATALOG.filter((cosmetic) => cosmetic.slot === slot);
  }

  find(id: string): Cosmetic | undefined {
    return CATALOG.find((cosmetic) => cosmetic.id === id);
  }

  energy(): number {
    return saveSystem.rewards.energy;
  }

  earned(): number {
    return saveSystem.rewards.earned;
  }

  owned(id: string): boolean {
    return saveSystem.rewards.unlocked.includes(id);
  }

  canAfford(id: string): boolean {
    const cosmetic = this.find(id);
    return Boolean(cosmetic) && saveSystem.rewards.energy >= cosmetic!.cost;
  }

  equippedId(slot: CosmeticSlot): string | undefined {
    return saveSystem.rewards.equipped[slot];
  }

  isEquipped(id: string): boolean {
    const cosmetic = this.find(id);
    return Boolean(cosmetic) && saveSystem.rewards.equipped[cosmetic!.slot] === id;
  }

  /** Colour of the cosmetic equipped in a slot, or the fallback if none. */
  colorForSlot(slot: CosmeticSlot, fallback: number): number {
    const id = this.equippedId(slot);
    const cosmetic = id ? this.find(id) : undefined;
    return cosmetic?.color ?? fallback;
  }

  /** Buys and, on success, auto-equips the cosmetic. */
  purchase(id: string): boolean {
    const cosmetic = this.find(id);
    if (!cosmetic) return false;
    const bought = saveSystem.purchaseCosmetic(id, cosmetic.cost);
    if (bought) saveSystem.equipCosmetic(cosmetic.slot, id);
    return bought;
  }

  equip(id: string): void {
    const cosmetic = this.find(id);
    if (cosmetic) saveSystem.equipCosmetic(cosmetic.slot, id);
  }
}

export const rewardSystem = new RewardSystem();
