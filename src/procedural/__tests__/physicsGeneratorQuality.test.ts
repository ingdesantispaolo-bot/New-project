import { describe, expect, it } from "vitest";
import { difficultyModel } from "../DifficultyModel";
import { PhysicsPuzzleGenerator } from "../generators/PhysicsPuzzleGenerator";
import { proceduralDirector } from "../ProceduralDirector";
import { Random } from "../Random";
import { PhysicsPuzzleValidator } from "../validators/PhysicsPuzzleValidator";
import type { DifficultyLevel, PhysicsExerciseType } from "../ProceduralTypes";

describe("Physics generator quality", () => {
  it("generates valid didactic physics puzzles across all levels", () => {
    const generator = new PhysicsPuzzleGenerator();
    const validator = new PhysicsPuzzleValidator();
    const seenTypes = new Set<PhysicsExerciseType>();

    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (let sample = 0; sample < 24; sample += 1) {
        const puzzle = generator.generate(
          new Random(`physics-quality:${level}:${sample}`),
          difficultyModel.getPreset(level),
        );
        seenTypes.add(puzzle.exerciseType);
        expect(validator.validate(puzzle), `${puzzle.id} should be valid`).toBe(true);
        expect(puzzle.options).toContain(puzzle.correctOption);
        expect(new Set(puzzle.options).size).toBe(puzzle.options.length);
        expect(puzzle.methodSteps.length).toBeGreaterThanOrEqual(3);
        expect(puzzle.explanation.length).toBeGreaterThan(45);
        expect(puzzle.visual.labels.length).toBeGreaterThanOrEqual(2);
      }
    }

    expect([...seenTypes]).toEqual(expect.arrayContaining([
      "motion-graph",
      "unit-check",
      "force-diagram",
      "energy-transfer",
      "experiment-order",
      "density-pressure",
      "heat-temperature",
      "wave-reading",
      "optics-ray",
    ]));
  });

  it("builds a physics focus mission with staged physics challenges", () => {
    const mission = proceduralDirector.generateFreshMission(5, ["fisica"]);

    expect(mission.focusChallenges?.length).toBeGreaterThanOrEqual(4);
    expect(mission.focusChallenges?.every((challenge) => challenge.kind === "physics")).toBe(true);
    expect(mission.map.hotspots.some((hotspot) => hotspot.puzzleKind === "physics")).toBe(true);
    expect(mission.objectives.every((objective) => objective.competencies.some((item) => item.startsWith("fisica.")))).toBe(true);
  });
});
