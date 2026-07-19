import { describe, expect, it } from "vitest";
import { createOutdoorWorldRequest } from "../outdoorGodotBridge";

describe("Godot outdoor bridge", () => {
  it("creates a versioned request from the canonical save state", () => {
    const request = createOutdoorWorldRequest({
      playerId: "p1",
      playerLevel: 3,
      rewards: { energy: 10, earned: 30, unlocked: [], equipped: { outfit: "outfit-1" } },
      outdoorAdventure: {
        date: "2026-07-19",
        completedEncounterIds: ["enc-0_0-0"],
        collectedTreasureIds: ["treasure-0_0-0"],
        fragments: 12,
        guardianWins: 0,
        bestStreak: 1,
        currentStreak: 1,
      },
    } as never, 3, "/academy");

    expect(request.schemaVersion).toBe(1);
    expect(request.worldSeed).toBe("outdoor-2026-07-19-3");
    expect(request.returnUrl).toBe("/academy");
    expect(request.outdoorState.completedEncounterIds).toEqual(["enc-0_0-0"]);
  });
});
