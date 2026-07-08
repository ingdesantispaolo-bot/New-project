import { describe, expect, it } from "vitest";
import { MathPuzzleGenerator } from "../generators/MathPuzzleGenerator";
import { MathPuzzleValidator } from "../validators/MathPuzzleValidator";
import { difficultyModel } from "../DifficultyModel";
import { Random } from "../Random";
import type { DifficultyLevel, MathMinigamePrompt, MathMinigameType } from "../ProceduralTypes";
import type { mathTemplates } from "../../data/procedural/mathTemplates";

type Archetype = (typeof mathTemplates)[number]["archetype"];

const TEMPLATE_ARCHETYPES: Archetype[] = [
  "calcolo-diretto", "frazioni", "percentuali", "lettura-dati", "sequenza",
  "statistica", "vincolo", "proporzione", "geometria", "probabilita",
  "ragionamento-inverso", "pre-algebra", "potenze-radici", "diagnosi-errore", "sistemi-lineari",
];

const MINIGAME_TYPES: MathMinigameType[] = ["target-sum", "factor-hunt", "operation-chain", "number-sequence", "expression-build"];

function evaluateOperatorInsertion(numbers: number[], operators: string[]): number {
  const values = [...numbers];
  const ops = [...operators];
  for (let i = 0; i < ops.length;) {
    if (ops[i] === "×") {
      values.splice(i, 2, values[i] * values[i + 1]);
      ops.splice(i, 1);
    } else {
      i += 1;
    }
  }
  let result = values[0];
  for (let i = 0; i < ops.length; i += 1) {
    result = ops[i] === "+" ? result + values[i + 1] : result - values[i + 1];
  }
  return result;
}

function operatorSolutions(prompt: MathMinigamePrompt): string[][] {
  const numbers = prompt.numbers ?? [];
  const allowed = prompt.tiles.map((tile) => tile.label);
  const target = prompt.target ?? NaN;
  const solutions: string[][] = [];
  const scan = (operators: string[]): void => {
    if (operators.length === numbers.length - 1) {
      if (evaluateOperatorInsertion(numbers, operators) === target) {
        solutions.push(operators);
      }
      return;
    }
    allowed.forEach((operator) => scan([...operators, operator]));
  };
  scan([]);
  return solutions;
}

function expressionText(numbers: number[], operators: string[], target: number): string {
  return `${numbers.map((n, i) => i < operators.length ? `${n} ${operators[i]} ` : `${n}`).join("").trim()} = ${target}`;
}

function evaluateOperationRoute(start: number, label: string): number | undefined {
  const operations = new Map<string, { apply: (value: number) => number; valid?: (value: number) => boolean }>([
    ["+ 6", { apply: (value) => value + 6 }],
    ["- 4", { apply: (value) => value - 4 }],
    ["x 2", { apply: (value) => value * 2 }],
    ["x 3", { apply: (value) => value * 3 }],
    [": 2", { apply: (value) => value / 2, valid: (value) => value % 2 === 0 }],
    [": 3", { apply: (value) => value / 3, valid: (value) => value % 3 === 0 }],
  ]);
  let value = start;
  for (const part of label.split(" poi ").map((item) => item.trim())) {
    const operation = operations.get(part);
    if (!operation || (operation.valid && !operation.valid(value))) return undefined;
    value = operation.apply(value);
  }
  return value;
}

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

  it("requires graph beacon lines to be solved by reading q, dx, dy and m", () => {
    const val = new MathPuzzleValidator();
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      const preset = difficultyModel.getPreset(level);
      for (let sample = 0; sample < 30; sample += 1) {
        const puzzle = gen.generateGraphWorkshop(new Random(`graph-read:${level}:${sample}`), preset);
        const workshop = puzzle.graphWorkshop;
        if (workshop?.mode !== "beacon-line") continue;
        const steps = workshop.readingSteps ?? [];
        expect(val.validate(puzzle)).toBe(true);
        expect(["q", "dx", "dy", "m"].every((key) => steps.some((step) => step.key === key))).toBe(true);
        for (const step of steps) {
          expect(step.options).toHaveLength(4);
          expect(new Set(step.options).size).toBe(4);
          expect(step.options).toContain(step.correctValue);
          expect(step.explanation.length).toBeGreaterThan(18);
        }
      }
    }
  });
});

describe("Math minigame tiles give diagnostic wrong-answer feedback", () => {
  const gen = new MathPuzzleGenerator();

  it("wrong tiles explain the specific error, not a vague 'off target'", () => {
    const diag = /divisibile|resto|divide|addendo|somma|bersaglio|sequenza|regola|totale|non entra|multiplo|intero/i;
    const vague = /^(?:.*\bporta fuori bersaglio\.?|.*\bparte della somma\.?)$/i;
    let wrong = 0;
    let diagnostic = 0;
    for (const type of ["target-sum", "factor-hunt", "number-sequence"] as const) {
      for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let i = 0; i < 12; i += 1) {
          const puzzle = gen.generateMinigame(new Random(`md:${type}:${level}:${i}`), preset, [type]);
          for (const prompt of puzzle.minigame?.prompts ?? []) {
            for (const tile of prompt.tiles.filter((candidate) => !candidate.isCorrect)) {
              wrong += 1;
              if (diag.test(tile.feedback) && !vague.test(tile.feedback.trim())) diagnostic += 1;
            }
          }
        }
      }
    }
    expect(wrong).toBeGreaterThan(50);
    expect(diagnostic / wrong).toBeGreaterThan(0.9);
  });

  it("keeps every generated minigame session varied, complete and structurally solvable", () => {
    for (const type of MINIGAME_TYPES) {
      const preset = difficultyModel.getPreset(8);
      const puzzle = gen.generateMinigame(new Random(`mq:${type}`), preset, [type]);
      const prompts = puzzle.minigame?.prompts ?? [];
      expect(prompts.length, type).toBe(26);
      expect(new Set(prompts.map((prompt) => prompt.signature)).size, type).toBe(prompts.length);

      for (const prompt of prompts) {
        expect(prompt.tiles.length, `${type}: ${prompt.id}`).toBeGreaterThanOrEqual(type === "number-sequence" ? 4 : 3);
        expect(new Set(prompt.tiles.map((tile) => tile.label)).size, `${type}: duplicate tile labels in ${prompt.id}`).toBe(prompt.tiles.length);
        expect(prompt.explanation.length, `${type}: explanation in ${prompt.id}`).toBeGreaterThan(20);

        if (type !== "expression-build") {
          const correctLabels = prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.label);
          expect(correctLabels.length, `${type}: correct count in ${prompt.id}`).toBe(prompt.requiredSelectionCount);
          expect(new Set(prompt.solutionLabels), `${type}: solution labels in ${prompt.id}`).toEqual(new Set(correctLabels));
        } else {
          expect(prompt.numbers?.length, prompt.id).toBe(prompt.requiredSelectionCount + 1);
          expect(prompt.solutionLabels.length, prompt.id).toBe(1);
        }
      }
    }
  });

  it("does not offer equivalent wrong routes in operation-chain prompts", () => {
    const preset = difficultyModel.getPreset(8);
    for (let sample = 0; sample < 18; sample += 1) {
      const puzzle = gen.generateMinigame(new Random(`op-cert:${sample}`), preset, ["operation-chain"]);
      for (const prompt of puzzle.minigame?.prompts ?? []) {
        const [startRaw, targetRaw] = prompt.targetLabel.split("->").map((part) => Number(part.trim()));
        expect(Number.isFinite(startRaw), prompt.targetLabel).toBe(true);
        expect(Number.isFinite(targetRaw), prompt.targetLabel).toBe(true);
        for (const tile of prompt.tiles) {
          const result = evaluateOperationRoute(startRaw, tile.label);
          expect(result, `${prompt.id}: ${tile.label}`).not.toBeUndefined();
          expect(result === targetRaw, `${prompt.id}: ${tile.label}`).toBe(tile.isCorrect);
          if (!tile.isCorrect) {
            expect(tile.feedback, `${prompt.id}: ${tile.label}`).toContain(String(result));
          }
        }
      }
    }
  });

  it("builds expression prompts with one unique operator solution and readable solution text", () => {
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      const preset = difficultyModel.getPreset(level);
      for (let sample = 0; sample < 12; sample += 1) {
        const puzzle = gen.generateMinigame(new Random(`expr-cert:${level}:${sample}`), preset, ["expression-build"]);
        for (const prompt of puzzle.minigame?.prompts ?? []) {
          const solutions = operatorSolutions(prompt);
          expect(solutions.length, `${prompt.id}: ${prompt.prompt}`).toBe(1);
          expect(prompt.solutionLabels).toEqual([expressionText(prompt.numbers ?? [], solutions[0], prompt.target ?? NaN)]);
        }
      }
    }
  });

  it("uses a broad mix of sequence rules at high difficulty", () => {
    const preset = difficultyModel.getPreset(8);
    const categories = new Set<string>();
    for (let sample = 0; sample < 24; sample += 1) {
      const puzzle = gen.generateMinigame(new Random(`seq-var:${sample}`), preset, ["number-sequence"]);
      for (const prompt of puzzle.minigame?.prompts ?? []) {
        const text = prompt.explanation;
        if (/sottrae/u.test(text)) categories.add("descending");
        if (/alternano/u.test(text)) categories.add("alternating");
        if (/somma dei due precedenti/u.test(text)) categories.add("recursive");
        if (/raddoppia/u.test(text)) categories.add("double-plus");
        if (/quadrati/u.test(text)) categories.add("squares");
        if (/moltiplica/u.test(text)) categories.add("geometric");
        if (/aggiunge sempre/u.test(text)) categories.add("arithmetic");
        if (/passo crescente/u.test(text)) categories.add("growing-step");
      }
    }
    expect(categories.size).toBeGreaterThanOrEqual(7);
  });
});
