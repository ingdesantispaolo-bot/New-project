import { describe, expect, it } from "vitest";
import { generateOutdoorAdventureMap, type OutdoorEncounterKind } from "../OutdoorAdventureGenerator";

describe("outdoor adventure generator", () => {
  it("generates a stable playable map from a seed", () => {
    const first = generateOutdoorAdventureMap("test-outdoor-seed");
    const second = generateOutdoorAdventureMap("test-outdoor-seed");

    expect(first).toEqual(second);
    expect(first.width).toBeGreaterThan(1200);
    expect(first.height).toBeGreaterThan(900);
    expect(first.patches.length).toBe(4);
    expect(first.obstacles.length).toBeGreaterThan(30);
    expect(first.encounters.length).toBe(9);
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
  });
});
