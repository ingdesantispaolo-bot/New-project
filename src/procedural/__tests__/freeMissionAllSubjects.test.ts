import { describe, expect, it } from "vitest";
import { ProceduralDirector } from "../ProceduralDirector";
import { proceduralPuzzleOrder, proceduralHotspotKey } from "../../scenes/procedural/ProceduralMissionLayout";

// The free mission ("libera") is a grand tour of every subject: it must expose a
// console for each of the nine disciplines plus the exit door, and the door must
// require all of them. Regression guard for the "tutte le materie" design.
describe("Free mission covers every subject", () => {
  const director = new ProceduralDirector();

  it("exposes all nine subject consoles plus the exit door across seeds and levels", () => {
    for (const level of [1, 3, 5, 8] as const) {
      for (const seed of ["ELI-A", "ELI-B", "ELI-C"]) {
        const mission = director.generateMission(seed, level, []);
        const puzzleKeys = new Set(
          mission.map.hotspots
            .map((hotspot) => proceduralHotspotKey(hotspot))
            .filter((key): key is NonNullable<typeof key> => Boolean(key) && key !== "door"),
        );

        for (const kind of proceduralPuzzleOrder) {
          expect(puzzleKeys.has(kind), `seed ${seed} L${level} missing ${kind} console`).toBe(true);
        }
        expect(mission.map.hotspots.some((hotspot) => hotspot.id === "door")).toBe(true);

        // Every subject console must be backed by a required objective so the door
        // gate actually waits for all of them.
        const objectiveKinds = new Set(
          mission.objectives.map((objective) => objective.id.replace("procedural-", "")),
        );
        for (const kind of proceduralPuzzleOrder) {
          expect(objectiveKinds.has(kind), `seed ${seed} L${level} missing ${kind} objective`).toBe(true);
        }
      }
    }
  });
});
