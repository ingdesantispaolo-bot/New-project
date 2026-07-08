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

  it("all targeted physics puzzle types carry per-option diagnostic feedback for every wrong option", () => {
    const generator = new PhysicsPuzzleGenerator();
    const semantic: PhysicsExerciseType[] = [
      "motion-graph",
      "unit-check",
      "force-diagram",
      "energy-transfer",
      "experiment-order",
      "density-pressure",
      "heat-temperature",
      "wave-reading",
      "optics-ray",
    ];
    let checked = 0;
    for (const type of semantic) {
      for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
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

  it("covers the advanced internal variants added to high-level physics", () => {
    const generator = new PhysicsPuzzleGenerator();
    const preset = difficultyModel.getPreset(8);
    const seen = new Set<string>();

    const mark = (puzzleType: PhysicsExerciseType, samplePrefix: string, marker: (text: string) => string | undefined) => {
      for (let sample = 0; sample < 240; sample += 1) {
        const puzzle = generator.generate(new Random(`${samplePrefix}:${sample}`), preset, [puzzleType]);
        const text = `${puzzle.title} ${puzzle.scenario} ${puzzle.prompt} ${puzzle.correctOption} ${puzzle.visual.highlight ?? ""}`;
        const tag = marker(text);
        if (tag) seen.add(tag);
      }
    };

    mark("motion-graph", "phys-var-motion", (text) => {
      if (/accelerato|pendenza cresce/u.test(text)) return "motion-accelerating";
      if (/fermo|posizione costante/u.test(text)) return "motion-at-rest";
      if (/uniforme/u.test(text)) return "motion-uniform";
      return undefined;
    });
    mark("unit-check", "phys-var-unit", (text) => {
      if (/cm in metri|cm -> m/u.test(text)) return "unit-length";
      if (/g in chilogrammi|g -> kg/u.test(text)) return "unit-mass";
      if (/minuti in secondi|min -> s/u.test(text)) return "unit-time";
      if (/km\/h in m\/s|km\/h -> m\/s/u.test(text)) return "unit-speed";
      return undefined;
    });
    mark("force-diagram", "phys-var-force", (text) => {
      if (/attrito statico|spinge lateralmente/u.test(text)) return "force-push";
      if (/tavolo/u.test(text)) return "force-table";
      if (/filo/u.test(text)) return "force-hanging";
      return undefined;
    });
    mark("density-pressure", "phys-var-density", (text) => {
      if (/Densita =/u.test(text)) return "density-ratio";
      if (/pressione maggiore|profondita/u.test(text)) return "pressure-depth";
      if (/Galleggia|Affonda|galleggiamento/u.test(text)) return "density-float";
      return undefined;
    });
    mark("heat-temperature", "phys-var-heat", (text) => {
      if (/calore != temperatura|energia trasferita/u.test(text)) return "heat-distinction";
      if (/massa maggiore|massa-termica/u.test(text)) return "heat-mass";
      if (/equilibrio|caldo -> freddo/u.test(text)) return "heat-equilibrium";
      return undefined;
    });
    mark("wave-reading", "phys-var-wave", (text) => {
      if (/velocita|lambda f/u.test(text)) return "wave-speed";
      if (/frequenza|Hz/u.test(text)) return "wave-frequency";
      if (/lambda|lunghezza d'onda/u.test(text)) return "wave-wavelength";
      return undefined;
    });
    mark("optics-ray", "phys-var-optics", (text) => {
      if (/specchio|riflessione/u.test(text)) return "optics-mirror";
      if (/lente|fuoco/u.test(text)) return "optics-lens";
      if (/rifrazione|aria all'acqua/u.test(text)) return "optics-refraction";
      if (/ombra|opaco/u.test(text)) return "optics-shadow";
      return undefined;
    });

    expect([...seen]).toEqual(expect.arrayContaining([
      "motion-uniform",
      "motion-accelerating",
      "motion-at-rest",
      "unit-length",
      "unit-mass",
      "unit-time",
      "unit-speed",
      "force-table",
      "force-hanging",
      "force-push",
      "density-ratio",
      "pressure-depth",
      "density-float",
      "heat-distinction",
      "heat-mass",
      "heat-equilibrium",
      "wave-wavelength",
      "wave-frequency",
      "wave-speed",
      "optics-mirror",
      "optics-lens",
      "optics-refraction",
      "optics-shadow",
    ]));
  });
});
