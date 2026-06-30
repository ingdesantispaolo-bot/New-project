import { describe, expect, it } from "vitest";
import { LanguageCorruptionGenerator, normalizeTypedAnswer } from "../generators/LanguageCorruptionGenerator";
import { LanguagePuzzleValidator } from "../validators/LanguagePuzzleValidator";
import { Random } from "../Random";
import type { DifficultyLevel } from "../ProceduralTypes";

const gen = new LanguageCorruptionGenerator();
const validator = new LanguagePuzzleValidator();

describe("Agreement (concordanza) minigame", () => {
  it("every prompt has exactly one correct answer and four distinct options", () => {
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (let i = 0; i < 20; i += 1) {
        const puzzle = gen.generateMinigame(new Random(`agr:${level}:${i}`), level, ["agreement-sprint"]);
        for (const prompt of puzzle.minigame?.prompts ?? []) {
          const labels = prompt.tiles.map((tile) => tile.label);
          const correctTiles = prompt.tiles.filter((tile) => tile.isCorrect);
          expect(labels.length, prompt.context).toBe(4);
          expect(new Set(labels).size, `distinct: ${labels.join(" | ")}`).toBe(4);
          expect(correctTiles).toHaveLength(1);
          expect(prompt.solutionLabels).toEqual([correctTiles[0].label]);
        }
        // The wrapped puzzle (first prompt) must pass the Italian validator.
        expect(validator.validateItalian(puzzle), `L${level} #${i}`).toBe(true);
      }
    }
  });

  it("produces typed production prompts whose accepted answer matches the solution", () => {
    let typedCount = 0;
    for (let i = 0; i < 30; i += 1) {
      const puzzle = gen.generateMinigame(new Random(`typed:${i}`), 5, ["agreement-sprint"]);
      for (const prompt of puzzle.minigame?.prompts ?? []) {
        if (prompt.inputMode !== "typed") continue;
        typedCount += 1;
        expect(prompt.acceptedAnswers).toBeDefined();
        // The declared correct answer must be accepted (case/spacing-insensitive).
        expect(prompt.acceptedAnswers).toContain(normalizeTypedAnswer(prompt.solutionLabels[0]));
        expect(prompt.acceptedAnswers).toContain(normalizeTypedAnswer(`  ${prompt.solutionLabels[0].toUpperCase()}. `));
      }
    }
    expect(typedCount).toBeGreaterThan(10);
  });

  it("normalizes typed answers (case, spacing, trailing punctuation)", () => {
    expect(normalizeTypedAnswer("  Sono   Calibrati. ")).toBe("sono calibrati");
    expect(normalizeTypedAnswer("È STABILE")).toBe("è stabile");
  });

  it("uses everyday vocabulary at low levels and technical at high levels (register by level)", () => {
    const everyday = /\b(gatt|porta|porte|libr|lampad|can[ei]|finestr|bicchier|sedi)/i;
    const technical = /\b(sensor|valvol|registr|modul|pomp|filtr|batteri|pannell|sond)/i;
    let lowEveryday = 0;
    let lowTotal = 0;
    let highTechnical = 0;
    let highTotal = 0;
    for (let i = 0; i < 20; i += 1) {
      for (const p of gen.generateMinigame(new Random(`low:${i}`), 1, ["agreement-sprint"]).minigame?.prompts ?? []) {
        lowTotal += 1;
        if (everyday.test(p.context)) lowEveryday += 1;
      }
      for (const p of gen.generateMinigame(new Random(`high:${i}`), 8, ["agreement-sprint"]).minigame?.prompts ?? []) {
        highTotal += 1;
        if (technical.test(p.context)) highTechnical += 1;
      }
    }
    expect(lowEveryday / lowTotal).toBeGreaterThan(0.4);
    expect(highTechnical / highTotal).toBeGreaterThan(0.4);
  });

  it("runs comprehension minigames in reflective (longer, calmer) mode", () => {
    for (const type of ["intruder-hunt", "lexicon-lab"] as const) {
      const game = gen.generateMinigame(new Random(`refl:${type}`), 5, [type]).minigame!;
      expect(game.reflective).toBe(true);
      expect(game.durationMs).toBeGreaterThan(60_000);
    }
    for (const type of ["agreement-sprint", "connector-route", "word-order", "verb-mastery"] as const) {
      const game = gen.generateMinigame(new Random(`spr:${type}`), 5, [type]).minigame!;
      expect(game.reflective ?? false).toBe(false);
      expect(game.durationMs).toBe(60_000);
    }
  });

  it("covers verb modes and tenses with valid recognition and production prompts", () => {
    const concepts = new Set<string>();
    let typedCount = 0;
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (let i = 0; i < 24; i += 1) {
        const puzzle = gen.generateMinigame(new Random(`verb:${level}:${i}`), level, ["verb-mastery"]);
        expect(validator.validateItalian(puzzle), `verb wrapper L${level} #${i}`).toBe(true);
        for (const prompt of puzzle.minigame?.prompts ?? []) {
          const labels = prompt.tiles.map((tile) => tile.label);
          concepts.add(prompt.concept);
          expect(labels).toContain(prompt.solutionLabels[0]);
          expect(new Set(labels).size, prompt.context).toBe(labels.length);
          expect(prompt.tiles.filter((tile) => tile.isCorrect)).toHaveLength(1);
          if (prompt.inputMode === "typed") {
            typedCount += 1;
            expect(prompt.acceptedAnswers).toContain(normalizeTypedAnswer(prompt.solutionLabels[0]));
          }
        }
      }
    }
    expect(typedCount).toBeGreaterThan(20);
    expect([...concepts]).toEqual(expect.arrayContaining([
      "indicativo presente",
      "indicativo passato prossimo",
      "congiuntivo presente",
      "condizionale passato",
      "participio passato",
    ]));
  });

  it("generates hundreds of distinct items (parametric variety, not memorisable)", () => {
    const signatures = new Set<string>();
    for (let i = 0; i < 40; i += 1) {
      const puzzle = gen.generateMinigame(new Random(`var:${i}`), 8, ["agreement-sprint"]);
      for (const prompt of puzzle.minigame?.prompts ?? []) {
        signatures.add(prompt.signature);
      }
    }
    expect(signatures.size).toBeGreaterThan(150);
  });
});
