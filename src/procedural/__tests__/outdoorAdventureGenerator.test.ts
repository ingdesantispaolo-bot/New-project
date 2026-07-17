import { describe, expect, it } from "vitest";
import { generateOutdoorAdventureMap, type OutdoorEncounterKind } from "../OutdoorAdventureGenerator";

describe("outdoor adventure generator", () => {
  it("generates a stable playable map from a seed", () => {
    const first = generateOutdoorAdventureMap("test-outdoor-seed");
    const second = generateOutdoorAdventureMap("test-outdoor-seed");

    expect(first).toEqual(second);
    expect(first.width).toBeGreaterThan(1200);
    expect(first.height).toBeGreaterThan(900);
    expect(first.patches.length).toBe(6);
    expect(first.obstacles.length).toBeGreaterThan(80);
    expect(first.landmarks.length).toBe(6);
    expect(first.treasures.length).toBeGreaterThanOrEqual(12);
    expect(first.encounters.length).toBe(13);
    expect(first.pathPoints.length).toBeGreaterThan(first.patches.length);
  });

  it("covers the first outdoor learning loop", () => {
    const map = generateOutdoorAdventureMap("coverage-outdoor-seed");
    const kinds = new Set<OutdoorEncounterKind>(map.encounters.map((encounter) => encounter.kind));

    expect(kinds.has("times")).toBe(true);
    expect(kinds.has("mental")).toBe(true);
    expect(kinds.has("capital")).toBe(true);
    expect(kinds.has("physicalGeo")).toBe(true);
    expect(kinds.has("guardian")).toBe(true);
    expect(map.encounters.every((encounter) => encounter.reward > 0)).toBe(true);
    expect(map.landmarks.every((landmark) => map.patches.some((patch) => patch.id === landmark.biome))).toBe(true);
    expect(map.treasures.every((treasure) => treasure.rewardEnergy > 0 && treasure.rewardFragments > 0)).toBe(true);
  });
});
