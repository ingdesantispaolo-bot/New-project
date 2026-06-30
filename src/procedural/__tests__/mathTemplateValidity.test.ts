import { describe, expect, it } from "vitest";
import { MathPuzzleGenerator } from "../generators/MathPuzzleGenerator";
import { MathPuzzleValidator } from "../validators/MathPuzzleValidator";
import { difficultyModel } from "../DifficultyModel";
import { Random } from "../Random";
import type { DifficultyLevel } from "../ProceduralTypes";
import type { mathTemplates } from "../../data/procedural/mathTemplates";

type Archetype = (typeof mathTemplates)[number]["archetype"];

const TEMPLATE_ARCHETYPES: Archetype[] = [
  "calcolo-diretto", "frazioni", "percentuali", "lettura-dati", "sequenza",
  "statistica", "vincolo", "proporzione", "geometria", "probabilita",
  "ragionamento-inverso", "pre-algebra", "potenze-radici", "diagnosi-errore", "sistemi-lineari",
];

describe("Math template puzzles are valid", () => {
  const gen = new MathPuzzleGenerator();
  const val = new MathPuzzleValidator();

  // Regression guard: the generic "response rule" once contained the word
  // "arrotondamento", which tripped the validator's rounding check and made
  // every template math puzzle invalid (so the scalata fell back to the
  // low-variety graph workshop). Every template puzzle must validate.
  it("validates 100% of template math at each difficulty", () => {
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      const preset = difficultyModel.getPreset(level);
      const total = 40;
      let valid = 0;
      for (let i = 0; i < total; i += 1) {
        const puzzle = gen.generate(new Random(`mtv:${level}:${i}`), preset, TEMPLATE_ARCHETYPES);
        if (val.validate(puzzle)) valid += 1;
      }
      expect(valid, `level ${level}`).toBe(total);
    }
  });

  it("produces integer answers within range", () => {
    const preset = difficultyModel.getPreset(5);
    for (let i = 0; i < 60; i += 1) {
      const puzzle = gen.generate(new Random(`range:${i}`), preset, TEMPLATE_ARCHETYPES);
      expect(Number.isInteger(puzzle.answer)).toBe(true);
      expect(puzzle.answer).toBeGreaterThanOrEqual(0);
      expect(puzzle.answer).toBeLessThanOrEqual(9999);
    }
  });
});
