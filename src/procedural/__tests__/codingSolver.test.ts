import { describe, expect, it } from "vitest";
import { CodingPuzzleGenerator } from "../generators/CodingPuzzleGenerator";
import { CodingPuzzleValidator } from "../validators/CodingPuzzleValidator";
import { CodingSolver } from "../solvers/CodingSolver";
import { difficultyModel } from "../DifficultyModel";
import { Random } from "../Random";
import type { CodingChallengeType, CodingMinigameType, DifficultyLevel } from "../ProceduralTypes";

const solver = new CodingSolver();
const gen = new CodingPuzzleGenerator();
const validator = new CodingPuzzleValidator();

const OUTPUT_TYPES: Array<{ type: CodingChallengeType; minLevel: number }> = [
  { type: "trace-output", minLevel: 1 },
  { type: "variable-state", minLevel: 2 },
  { type: "loop-count", minLevel: 3 },
  { type: "conditional-branch", minLevel: 3 },
  { type: "boolean-logic", minLevel: 5 },
];

describe("CodingSolver agrees with generated single puzzles", () => {
  it("computes the declared answer for every output-type puzzle", () => {
    for (const { type, minLevel } of OUTPUT_TYPES) {
      for (let level = minLevel as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let i = 0; i < 40; i += 1) {
          const puzzle = gen.generate(new Random(`cs:${type}:${level}:${i}`), preset, [type]);
          const result = solver.run(puzzle.codeLines);
          expect(result, `${type} L${level} #${i}\n${puzzle.codeLines.join("\n")}`).toBe(puzzle.correctOption);
        }
      }
    }
  });

  it("every output-type single puzzle passes validation (4 distinct options + semantic)", () => {
    for (const { type, minLevel } of OUTPUT_TYPES) {
      for (let level = minLevel as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let i = 0; i < 40; i += 1) {
          const puzzle = gen.generate(new Random(`cv:${type}:${level}:${i}`), preset, [type]);
          expect(puzzle.options.length, `${type} L${level} #${i}`).toBe(4);
          expect(validator.validate(puzzle), `${type} L${level} #${i}`).toBe(true);
        }
      }
    }
  });
});

describe("CodingSolver agrees with generated minigame prompts", () => {
  const outputMinigames: CodingMinigameType[] = ["state-tracer", "loop-output", "conditional-path"];
  it("computes the declared answer for every output-type minigame prompt", () => {
    for (const type of outputMinigames) {
      for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let i = 0; i < 12; i += 1) {
          const puzzle = gen.generateMinigame(new Random(`cm:${type}:${level}:${i}`), preset, [type]);
          for (const prompt of puzzle.minigame?.prompts ?? []) {
            const result = solver.run(prompt.codeLines);
            expect(result, `${type} L${level}\n${prompt.codeLines.join("\n")}`).toBe(prompt.solutionLabels[0]);
          }
        }
      }
    }
  });
});

describe("CodingSolver returns undefined for non-output puzzles", () => {
  it("does not pretend to solve a fix-choice (sequence-builder) puzzle", () => {
    const preset = difficultyModel.getPreset(4);
    const puzzle = gen.generateMinigame(new Random("seq:1"), preset, ["sequence-builder"]);
    const firstPrompt = puzzle.minigame!.prompts[0];
    expect(solver.run(firstPrompt.codeLines)).toBeUndefined();
  });
});
