import { describe, expect, it } from "vitest";
import { generateOutdoorAdventureRegion, generateOutdoorChunk, OUTDOOR_CHUNK_SIZE } from "../OutdoorChunkGenerator";
import { generateOutdoorAdventureMap, type OutdoorEncounterKind } from "../OutdoorAdventureGenerator";

describe("outdoor adventure generator", () => {
  it("generates a stable playable map from a seed", () => {
    const first = generateOutdoorAdventureMap("test-outdoor-seed");
    const second = generateOutdoorAdventureMap("test-outdoor-seed");

    expect(first).toEqual(second);
    expect(first.width).toBe(OUTDOOR_CHUNK_SIZE * 5);
    expect(first.height).toBe(OUTDOOR_CHUNK_SIZE * 5);
    expect(first.patches.length).toBe(25);
    expect(first.obstacles.length).toBeGreaterThan(300);
    expect(first.landmarks.length).toBeGreaterThanOrEqual(6);
    expect(first.treasures.length).toBeGreaterThanOrEqual(25);
    expect(first.encounters.length).toBeGreaterThanOrEqual(25);
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

  it("generates deterministic chunks that differ by coordinate", () => {
    const first = generateOutdoorChunk("chunk-seed", 3, -2);
    const second = generateOutdoorChunk("chunk-seed", 3, -2);
    const neighbor = generateOutdoorChunk("chunk-seed", 4, -2);

    expect(first).toEqual(second);
    expect(first).not.toEqual(neighbor);
    expect(first.id).toBe("chunk-3_-2");
    expect(first.patch.x).toBeGreaterThanOrEqual(3 * OUTDOOR_CHUNK_SIZE);
    expect(first.patch.y).toBeLessThanOrEqual(-2 * OUTDOOR_CHUNK_SIZE + OUTDOOR_CHUNK_SIZE);
  });

  it("can assemble larger regions without changing the chunk contract", () => {
    const small = generateOutdoorAdventureRegion("region-seed", 1, 1);
    const large = generateOutdoorAdventureRegion("region-seed", 2, 2);

    expect(small.patches.length).toBe(9);
    expect(large.patches.length).toBe(25);
    expect(large.width).toBeGreaterThan(small.width);
    expect(large.encounters.length).toBeGreaterThan(small.encounters.length);
    expect(new Set(large.encounters.map((encounter) => encounter.id)).size).toBe(large.encounters.length);
  });
});
