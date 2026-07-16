import { saveSystem } from "./SaveSystem";
import { REWARD_CATALOG, type Cosmetic, type CosmeticSlot } from "./RewardCatalog";

export type { Cosmetic, CosmeticSlot } from "./RewardCatalog";

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

class RewardSystem {
  get catalog(): Cosmetic[] {
    return REWARD_CATALOG;
  }

  bySlot(slot: CosmeticSlot): Cosmetic[] {
    return REWARD_CATALOG.filter((cosmetic) => cosmetic.slot === slot);
  }

  find(id: string): Cosmetic | undefined {
    return REWARD_CATALOG.find((cosmetic) => cosmetic.id === id);
  }

  energy(): number {
    return saveSystem.rewards.energy;
  }

  earned(): number {
    return saveSystem.rewards.earned;
  }

  playerLevel(): number {
    const trainingRuns = Object.values(saveSystem.data.trainingRecords ?? {})
      .reduce((sum, record) => sum + Math.max(0, record.runs), 0);
    const energyLift = Math.floor(this.earned() / 1000);
    const missionLift = saveSystem.data.completedMissionIds.length;
    const trainingLift = Math.floor(trainingRuns / 3);
    const gymLift = Math.floor(((saveSystem.data.logicGym?.level ?? 1) - 1) / 2);
    const collectionLift = Math.floor((saveSystem.data.collection?.discovered.length ?? 0) / 2);
    const shopLift = Math.floor(saveSystem.rewards.unlocked.length / 5);
    return clamp(1 + energyLift + missionLift + trainingLift + gymLift + collectionLift + shopLift, 1, 12);
  }

  owned(id: string): boolean {
    const cosmetic = this.find(id);
    return saveSystem.rewards.unlocked.includes(id)
      || Boolean((cosmetic?.slot === "upgrade" || cosmetic?.slot === "decor") && saveSystem.data.inventory.includes(id));
  }

  canUnlock(id: string): boolean {
    const cosmetic = this.find(id);
    return Boolean(cosmetic) && !this.owned(id) && this.playerLevel() >= (cosmetic!.minLevel ?? 1);
  }

  unavailableReason(id: string): string | undefined {
    const cosmetic = this.find(id);
    if (!cosmetic || this.owned(id)) return undefined;
    const minLevel = cosmetic.minLevel ?? 1;
    if (this.playerLevel() < minLevel) return `Liv. ${minLevel}`;
    if (saveSystem.rewards.energy < cosmetic.cost) return "Energia insuff.";
    return undefined;
  }

  canAfford(id: string): boolean {
    const cosmetic = this.find(id);
    return Boolean(cosmetic) && this.canUnlock(id) && saveSystem.rewards.energy >= cosmetic!.cost;
  }

  equippedId(slot: CosmeticSlot): string | undefined {
    return saveSystem.rewards.equipped[slot];
  }

  equipped(slot: CosmeticSlot): Cosmetic | undefined {
    const id = this.equippedId(slot);
    return id ? this.find(id) : undefined;
  }

  isEquipped(id: string): boolean {
    const cosmetic = this.find(id);
    if (cosmetic?.slot === "upgrade" || cosmetic?.slot === "decor") return this.owned(id);
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
    if (!cosmetic || !this.canAfford(id)) return false;
    const bought = saveSystem.purchaseCosmetic(id, cosmetic.cost);
    if (bought && (cosmetic.slot === "upgrade" || cosmetic.slot === "decor")) {
      saveSystem.addInventoryItem(id);
    } else if (bought) {
      saveSystem.equipCosmetic(cosmetic.slot, id);
    }
    return bought;
  }

  equip(id: string): void {
    const cosmetic = this.find(id);
    if (!cosmetic || !this.owned(id)) return;
    if (cosmetic.slot === "upgrade" || cosmetic.slot === "decor") return;
    saveSystem.equipCosmetic(cosmetic.slot, id);
  }

  unequip(slot: CosmeticSlot): void {
    if (slot === "upgrade" || slot === "decor") return;
    saveSystem.equipCosmetic(slot, "");
  }
}

export const rewardSystem = new RewardSystem();
