import { describe, expect, it } from "vitest";
import { LatinGenerator } from "../generators/LatinGenerator";
import { Random } from "../Random";
import type { DifficultyLevel, LatinMinigameType } from "../ProceduralTypes";

const TYPES: LatinMinigameType[] = [
  "declension", "conjugation", "verb-analysis", "case-function",
  "agreement", "vocab-match", "translation", "syntax-clause",
];

describe("Latin generator quality", () => {
  it("always yields four unique tiles with exactly one correct across types and levels", () => {
    const generator = new LatinGenerator();
    const seen = new Set<LatinMinigameType>();

    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (const type of TYPES) {
        // syntax-clause is second-year only; force via preferred type from L5+.
        if (type === "syntax-clause" && level < 5) continue;
        for (let sample = 0; sample < 60; sample += 1) {
          const puzzle = generator.generateMinigame(new Random(`latin:${level}:${type}:${sample}`), level, [type]);
          const prompt = puzzle.minigame.prompts[0];
          seen.add(prompt.type);
          expect(prompt.tiles.length, `${prompt.id} tiles`).toBe(4);
          expect(new Set(prompt.tiles.map((tile) => tile.label)).size, `${prompt.id} unique`).toBe(4);
          const correct = prompt.tiles.filter((tile) => tile.isCorrect);
          expect(correct.length, `${prompt.id} one correct`).toBe(1);
          expect(prompt.solutionLabels).toContain(correct[0].label);
          expect(prompt.prompt.length).toBeGreaterThan(8);
          expect(puzzle.hints.length).toBeGreaterThanOrEqual(3);
        }
      }
    }

    expect([...seen].sort()).toEqual([...TYPES].sort());
  });

  it("keeps first-year runs within first-year content (no syntax-clause below L5)", () => {
    const generator = new LatinGenerator();
    for (let sample = 0; sample < 200; sample += 1) {
      const puzzle = generator.generateMinigame(new Random(`latin-tier1:${sample}`), 2);
      expect(puzzle.minigame.prompts[0].type).not.toBe("syntax-clause");
    }
  });
});
