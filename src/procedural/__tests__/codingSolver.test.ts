import { describe, expect, it } from "vitest";
import { CodingPuzzleGenerator } from "../generators/CodingPuzzleGenerator";
import { PuzzleGenerator } from "../PuzzleGenerator";
import { CodingPuzzleValidator } from "../validators/CodingPuzzleValidator";
import { CodingSolver } from "../solvers/CodingSolver";
import { difficultyModel } from "../DifficultyModel";
import { Random } from "../Random";
import { ValidationEngine } from "../ValidationEngine";
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

const ALL_MINIGAME_TYPES: CodingMinigameType[] = [
  "sequence-builder",
  "state-tracer",
  "bug-hunt",
  "binary-bits",
  "logic-gate",
  "loop-output",
  "conditional-path",
  "algorithm-order",
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
  it("all choice-based minigame distractors name the specific mistake", () => {
    const diag = /ciclo|condizione|variabile|operatore|somma|sottra|moltiplic|ripeti|numero|azione|logica|and|or|not|causa|compens|corregg|stato|stampa|ramo|bit|binario|potenze|giro|feedback|valore|output|risposta giusta|ripercorri/i;
    let wrong = 0;
    let diagnostic = 0;
    for (const type of ALL_MINIGAME_TYPES.filter((item) => item !== "algorithm-order")) {
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
    expect(diagnostic / wrong).toBeGreaterThan(0.92);
  });
});

describe("Coding minigames are varied and structurally sound", () => {
  it("generates complete unique sessions for every minigame type", () => {
    const preset = difficultyModel.getPreset(8);
    for (const type of ALL_MINIGAME_TYPES) {
      const puzzle = gen.generateMinigame(new Random(`coding-structure:${type}`), preset, [type]);
      const prompts = puzzle.minigame?.prompts ?? [];
      expect(prompts.length, type).toBe(26);
      expect(new Set(prompts.map((prompt) => prompt.signature)).size, type).toBe(prompts.length);

      for (const prompt of prompts) {
        expect(prompt.codeLines.length, `${type}: ${prompt.id}`).toBeGreaterThanOrEqual(3);
        expect(prompt.question.length, `${type}: ${prompt.id}`).toBeGreaterThan(20);
        expect(prompt.explanation.length, `${type}: ${prompt.id}`).toBeGreaterThan(35);
        expect(new Set(prompt.tiles.map((tile) => tile.label)).size, `${type}: duplicate labels`).toBe(prompt.tiles.length);
        if (type === "algorithm-order") {
          expect(prompt.requiredSelectionCount, prompt.id).toBe(prompt.solutionLabels.length);
          expect(prompt.solutionLabels.length, prompt.id).toBeGreaterThanOrEqual(3);
          expect(new Set(prompt.solutionLabels).size, prompt.id).toBe(prompt.solutionLabels.length);
        } else {
          const correctTiles = prompt.tiles.filter((tile) => tile.isCorrect);
          expect(correctTiles.length, `${type}: ${prompt.id}`).toBe(1);
          expect(prompt.solutionLabels).toEqual([correctTiles[0].label]);
          expect(prompt.requiredSelectionCount).toBe(1);
          expect(prompt.tiles.length, `${type}: ${prompt.id}`).toBe(4);
        }
      }
    }
  });

  it("exposes advanced minigame types through the procedural focus progression", () => {
    const planner = new PuzzleGenerator(new ValidationEngine()) as unknown as { codingMinigameTypesForStep: (step: number) => CodingMinigameType[] };
    const latePool = planner.codingMinigameTypesForStep(4);
    expect(latePool).toEqual(expect.arrayContaining(["binary-bits", "logic-gate", "loop-output", "conditional-path", "algorithm-order"]));

    const advanced: CodingMinigameType[] = ["binary-bits", "logic-gate", "loop-output", "conditional-path", "algorithm-order"];
    for (const type of advanced) {
      const puzzle = gen.generateMinigame(new Random(`coding-advanced:${type}`), difficultyModel.getPreset(8), [type]);
      expect(puzzle.minigame?.type).toBe(type);
      expect(puzzle.minigame?.prompts.length).toBeGreaterThan(20);
    }
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
