import { describe, expect, it } from "vitest";
import { MissionDependencyGraph } from "../../scenes/procedural/components/MissionDependencyGraph";
import { proceduralPuzzleOrder, type ProceduralPuzzleId } from "../../scenes/procedural/ProceduralMissionLayout";

describe("MissionDependencyGraph", () => {
  it("keeps the exit door blocked until coding is solved too", () => {
    const graph = new MissionDependencyGraph();
    const solvedEverythingExceptCoding = (node: ProceduralPuzzleId): boolean => node !== "coding";

    expect(graph.blockers("door", solvedEverythingExceptCoding)).toEqual(["coding"]);
    expect(graph.canOperate("door", solvedEverythingExceptCoding)).toBe(false);
    expect(graph.nextAction(solvedEverythingExceptCoding)).toBe("coding");
  });

  it("matches the official procedural puzzle order for door blockers", () => {
    const graph = new MissionDependencyGraph();
    const solvedNothing = (_node: ProceduralPuzzleId): boolean => false;

    expect(graph.blockers("door", solvedNothing)).toEqual(proceduralPuzzleOrder);
  });
});
