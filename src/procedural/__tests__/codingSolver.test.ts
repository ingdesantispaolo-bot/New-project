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

describe("Coding minigame wrong-answer feedback is diagnostic", () => {
  it("sequence-builder and bug-hunt distractors name the specific mistake", () => {
    const diag = /ciclo|condizione|variabile|operatore|somma|sottra|moltiplic|ripeti|numero|azione|logica|and|or|causa|compens|corregg|stato|stampa|ramo|risposta giusta|ripercorri/i;
    let wrong = 0;
    let diagnostic = 0;
    for (const type of ["sequence-builder", "bug-hunt"] as CodingMinigameType[]) {
      for (let level = 3 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let i = 0; i < 10; i += 1) {
          const puzzle = gen.generateMinigame(new Random(`cd:${type}:${level}:${i}`), preset, [type]);
          for (const prompt of puzzle.minigame?.prompts ?? []) {
            for (const tile of prompt.tiles.filter((candidate) => !candidate.isCorrect)) {
              wrong += 1;
              if (diag.test(tile.feedback) && !/^Non basta/i.test(tile.feedback.trim())) diagnostic += 1;
            }
          }
        }
      }
    }
    expect(wrong).toBeGreaterThan(30);
    expect(diagnostic / wrong).toBeGreaterThan(0.85);
  });
});

describe("Coding console puzzles give per-option diagnostic feedback", () => {
  it("output/logic console puzzles explain most wrong options", () => {
    const types: Array<{ type: CodingChallengeType; minLevel: number }> = [
      { type: "trace-output", minLevel: 1 },
      { type: "variable-state", minLevel: 2 },
      { type: "loop-count", minLevel: 3 },
      { type: "conditional-branch", minLevel: 3 },
      { type: "boolean-logic", minLevel: 5 },
    ];
    let puzzles = 0;
    let wrong = 0;
    let covered = 0;
    for (const { type, minLevel } of types) {
      for (let level = minLevel as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let i = 0; i < 8; i += 1) {
          const puzzle = gen.generate(new Random(`cc:${type}:${level}:${i}`), preset, [type]);
          if (puzzle.challengeType !== type) continue;
          puzzles += 1;
          expect(puzzle.optionFeedback, puzzle.id).toBeDefined();
          for (const option of puzzle.options.filter((candidate) => candidate !== puzzle.correctOption)) {
            wrong += 1;
            if (puzzle.optionFeedback?.[option]) covered += 1;
          }
        }
      }
    }
    expect(puzzles).toBeGreaterThan(20);
    expect(covered / wrong).toBeGreaterThan(0.75);
  });
});
