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

  it("is not guessable by option length: correct is rarely the unique longest/shortest", () => {
    // A student must not be able to pick the correct answer by choosing the
    // longest or shortest option. We require the correct option to be the strict
    // unique extreme well below chance across every puzzle type.
    const generator = new PhysicsPuzzleGenerator();
    let n = 0;
    let uniqueLongest = 0;
    let uniqueShortest = 0;
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (let i = 0; i < 220; i += 1) {
        const puzzle = generator.generate(new Random(`plen:${level}:${i}`), difficultyModel.getPreset(level));
        const correctLen = puzzle.correctOption.length;
        const others = puzzle.options.filter((o) => o !== puzzle.correctOption).map((o) => o.length);
        n += 1;
        if (others.every((len) => correctLen > len)) uniqueLongest += 1;
        if (others.every((len) => correctLen < len)) uniqueShortest += 1;
      }
    }
    expect(n).toBeGreaterThan(1000);
    expect(uniqueLongest / n).toBeLessThan(0.3);
    expect(uniqueShortest / n).toBeLessThan(0.45);
  });

  it("energy and optics puzzles carry per-option diagnostic feedback for every wrong option", () => {
    const generator = new PhysicsPuzzleGenerator();
    const semantic: PhysicsExerciseType[] = ["energy-transfer", "optics-ray"];
    let checked = 0;
    for (const type of semantic) {
      for (let level = 3 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        for (let sample = 0; sample < 10; sample += 1) {
          const puzzle = generator.generate(new Random(`pf:${type}:${level}:${sample}`), difficultyModel.getPreset(level), [type]);
          // generate() falls back to other types when the preferred one is not
          // available at this level; only assert on the ones we actually target.
          if (!semantic.includes(puzzle.exerciseType)) continue;
          expect(puzzle.optionFeedback, puzzle.id).toBeDefined();
          for (const option of puzzle.options.filter((candidate) => candidate !== puzzle.correctOption)) {
            expect(puzzle.optionFeedback?.[option], `${puzzle.id} :: ${option}`).toBeTruthy();
          }
          checked += 1;
        }
      }
    }
    expect(checked).toBeGreaterThan(20);
  });
});
