import { describe, expect, it } from "vitest";
import rewardItemsAtlas from "../../assets/sprites/reward-items-sheet.json";
import { REWARD_CATALOG, type CosmeticSlot } from "../RewardCatalog";

describe("reward catalog", () => {
  it("uses stable unique ids with positive costs", () => {
    const ids = REWARD_CATALOG.map((item) => item.id);
    const invalidCosts = REWARD_CATALOG.filter((item) => item.cost <= 0).map((item) => item.id);

    expect(new Set(ids).size).toBe(ids.length);
    expect(invalidCosts).toEqual([]);
  });

  it("keeps every visible shop slot populated", () => {
    const slots: CosmeticSlot[] = ["bot", "avatar", "accessory", "pet", "emblem", "upgrade", "decor"];
    const emptySlots = slots.filter((slot) => REWARD_CATALOG.filter((item) => item.slot === slot).length === 0);

    expect(emptySlots).toEqual([]);
  });

  it("keeps pet rewards aspirational and level-gated", () => {
    const weakPets = REWARD_CATALOG.filter((item) => item.slot === "pet")
      .filter((item) => item.cost < 1500 || (item.minLevel ?? 1) < 4)
      .map((item) => item.id);

    expect(weakPets).toEqual([]);
  });

  it("includes recognizable animal companions with meaningful progression costs", () => {
    const animalPets = ["pet-dog", "pet-cat", "pet-rabbit"];
    const missing = animalPets.filter((id) => !REWARD_CATALOG.some((item) => item.id === id && item.slot === "pet"));
    const tooCheap = REWARD_CATALOG
      .filter((item) => animalPets.includes(item.id))
      .filter((item) => item.cost < 1500 || (item.minLevel ?? 1) < 4)
      .map((item) => item.id);

    expect(missing).toEqual([]);
    expect(tooCheap).toEqual([]);
  });

  it("keeps passive reward cards visually identifiable", () => {
    const passiveSlots: CosmeticSlot[] = ["upgrade", "decor"];
    const missingGlyphs = REWARD_CATALOG
      .filter((item) => passiveSlots.includes(item.slot) && !item.glyph)
      .map((item) => item.id);

    expect(missingGlyphs).toEqual([]);
  });

  it("has one atlas frame for every shop item", () => {
    const frames = rewardItemsAtlas.frames as Record<string, unknown>;
    const missingFrames = REWARD_CATALOG
      .filter((item) => !frames[item.id])
      .map((item) => item.id);

    expect(missingFrames).toEqual([]);
  });
});
