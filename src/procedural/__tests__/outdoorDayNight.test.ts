import { describe, expect, it } from "vitest";
import { generateOutdoorChunk } from "../OutdoorChunkGenerator";
import { generateOutdoorHazardsForChunk, isOutdoorHazardActive, outdoorHazardDifficulty, outdoorHazardReward, phaseForOutdoorTime } from "../OutdoorDayNight";

describe("outdoor day night cycle", () => {
  it("maps elapsed time to stable outdoor phases", () => {
    expect(phaseForOutdoorTime(0, 1000)).toBe("day");
    expect(phaseForOutdoorTime(500, 1000)).toBe("dusk");
    expect(phaseForOutdoorTime(700, 1000)).toBe("night");
    expect(phaseForOutdoorTime(930, 1000)).toBe("dawn");
  });

  it("generates light day hazards and stronger night hazards per chunk", () => {
    const chunk = generateOutdoorChunk("hazard-seed", 1, -1);
    const first = generateOutdoorHazardsForChunk(chunk, "hazard-seed");
    const second = generateOutdoorHazardsForChunk(chunk, "hazard-seed");

    expect(first).toEqual(second);
    expect(first.some((hazard) => hazard.activeIn === "day")).toBe(true);
    expect(first.filter((hazard) => hazard.activeIn === "night").length).toBeGreaterThanOrEqual(2);
    expect(first.every((hazard) => hazard.x >= chunk.patch.x && hazard.x <= chunk.patch.x + chunk.patch.w)).toBe(true);
    expect(first.every((hazard) => hazard.y >= chunk.patch.y && hazard.y <= chunk.patch.y + chunk.patch.h)).toBe(true);
  });

  it("activates and rewards hazards according to the current phase", () => {
    const chunk = generateOutdoorChunk("phase-hazard-seed", 0, 0);
    const hazards = generateOutdoorHazardsForChunk(chunk, "phase-hazard-seed");
    const dayHazard = hazards.find((hazard) => hazard.activeIn === "day")!;
    const nightHazard = hazards.find((hazard) => hazard.activeIn === "night")!;

    expect(isOutdoorHazardActive(dayHazard, "day")).toBe(true);
    expect(isOutdoorHazardActive(dayHazard, "night")).toBe(false);
    expect(isOutdoorHazardActive(nightHazard, "night")).toBe(true);
    expect(isOutdoorHazardActive(nightHazard, "day")).toBe(false);
    expect(outdoorHazardDifficulty(nightHazard, "night")).toBeGreaterThan(outdoorHazardDifficulty(dayHazard, "day"));
    expect(outdoorHazardReward(nightHazard, "night").energy).toBeGreaterThan(outdoorHazardReward(dayHazard, "day").energy);
  });
});
