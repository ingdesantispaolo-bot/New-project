import { describe, expect, it } from "vitest";
import { englishTemplates } from "../../data/procedural/englishTemplates";
import { englishVocabularyEntries } from "../../data/procedural/englishVocabularyBank";
import { EnglishInstructionGenerator } from "../generators/EnglishInstructionGenerator";
import { LanguagePuzzleValidator } from "../validators/LanguagePuzzleValidator";
import type { EnglishMinigameType } from "../ProceduralTypes";
import { Random } from "../Random";

const TYPES: EnglishMinigameType[] = [
  "action-relay",
  "sequence-switchboard",
  "data-command-scan",
  "grammar-fix",
  "sentence-build",
  "vocab-lab",
  "translation-match",
  "reading-detective",
  "error-diagnosis",
  "dialogue-response",
];

describe("English generator quality", () => {
  it("uses a broad structured vocabulary bank for third-year middle school", () => {
    const categories = new Set(englishVocabularyEntries.map((entry) => entry.category));
    const terms = new Set(englishVocabularyEntries.map((entry) => `${entry.category}:${entry.term}`));
    const advancedTerms = englishVocabularyEntries.filter((entry) => entry.level >= 5);

    expect(englishVocabularyEntries.length).toBeGreaterThanOrEqual(1000);
    expect(categories.size).toBeGreaterThanOrEqual(18);
    expect(terms.size).toBe(englishVocabularyEntries.length);
    expect(advancedTerms.length).toBeGreaterThanOrEqual(40);
  });

  it("generates coherent minigame prompts for every English type", () => {
    const generator = new EnglishInstructionGenerator();
    const validator = new LanguagePuzzleValidator();
    for (const type of TYPES) {
      for (let level = 1; level <= 8; level += 1) {
        const puzzle = generator.generateMinigame(new Random(`english-quality:${type}:${level}`), level, [type]);
        const prompts = puzzle.minigame?.prompts ?? [];
        expect(prompts.length, `${type} L${level}: prompts`).toBeGreaterThan(0);
        expect(validator.validateEnglish(puzzle), `${type} L${level}: wrapper`).toBe(true);

        for (const prompt of prompts.slice(0, 12)) {
          const labels = prompt.tiles.map((tile) => tile.label);
          const correctLabels = prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.label);

          if (prompt.type !== "sentence-build") {
            expect(new Set(labels).size, `${type}: duplicate labels in ${prompt.id}`).toBe(labels.length);
          }
          expect(correctLabels.length, `${type}: correct count in ${prompt.id}`).toBe(prompt.requiredSelectionCount);
          expect(new Set(prompt.solutionLabels), `${type}: solution labels in ${prompt.id}`).toEqual(new Set(correctLabels));
          expect(labels.some((label) => /\berrat[oaie]\b/i.test(label)), `${type}: visible self-revealing label in ${prompt.id}`).toBe(false);
          expect(prompt.explanation.length, `${type}: explanation in ${prompt.id}`).toBeGreaterThanOrEqual(20);
          expect(prompt.glossary?.length ?? 0, `${type}: glossary in ${prompt.id}`).toBeGreaterThan(0);
        }
      }
    }
  });

  it("Action Relay asks for one meaning tile and one text-evidence tile", () => {
    const generator = new EnglishInstructionGenerator();
    for (let level = 1; level <= 8; level += 1) {
      const puzzle = generator.generateMinigame(new Random(`english-action-audit:${level}`), level, ["action-relay"]);
      const prompts = puzzle.minigame?.prompts ?? [];
      expect(prompts.length).toBeGreaterThan(0);

      for (const prompt of prompts.slice(0, 18)) {
        const correctLabels = prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.label);
        const actionTiles = prompt.tiles.filter((tile) => tile.label.startsWith("Azione:"));
        const evidenceTiles = prompt.tiles.filter((tile) => tile.label.startsWith("Prova:"));

        expect(prompt.requiredSelectionCount, prompt.instruction).toBe(2);
        expect(correctLabels.filter((label) => label.startsWith("Azione:")).length, prompt.instruction).toBe(1);
        expect(correctLabels.filter((label) => label.startsWith("Prova:")).length, prompt.instruction).toBe(1);
        expect(actionTiles.length, prompt.instruction).toBeGreaterThanOrEqual(3);
        expect(evidenceTiles.length, prompt.instruction).toBeGreaterThanOrEqual(3);
      }
    }
  });

  it("validates every authored English template with distinct explained choices", () => {
    const generator = new EnglishInstructionGenerator();
    const validator = new LanguagePuzzleValidator();
    for (const template of englishTemplates) {
      const level = Math.max(1, template.minDifficulty ?? 1);
      const puzzle = generator.generate(new Random(`english-template:${template.id}`), level, [template.id]);
      const labels = puzzle.choices.map((choice) => choice.label.trim().toLocaleLowerCase("en"));

      expect(validator.validateEnglish(puzzle), template.id).toBe(true);
      expect(new Set(labels).size, template.id).toBe(labels.length);
      expect(puzzle.choices.filter((choice) => choice.isCorrect), template.id).toHaveLength(1);
      for (const choice of puzzle.choices.filter((candidate) => !candidate.isCorrect)) {
        expect(choice.feedback.length, `${template.id}: ${choice.label}`).toBeGreaterThan(35);
      }
    }
  });

  it("keeps high-level English minigames varied enough for a full sprint", () => {
    const generator = new EnglishInstructionGenerator();
    for (const type of TYPES) {
      const puzzle = generator.generateMinigame(new Random(`english-variety:${type}`), 8, [type]);
      const prompts = puzzle.minigame?.prompts ?? [];
      expect(prompts.length, type).toBeGreaterThan(20);
      expect(new Set(prompts.map((prompt) => prompt.signature)).size, `${type} signatures`).toBe(prompts.length);
    }
  });

  it("new comprehension and communication minigames require answer plus reason/evidence", () => {
    const generator = new EnglishInstructionGenerator();
    for (const type of ["reading-detective", "error-diagnosis", "dialogue-response"] as const) {
      const concepts = new Set<string>();
      for (let i = 0; i < 12; i += 1) {
        const puzzle = generator.generateMinigame(new Random(`english-new:${type}:${i}`), 8, [type]);
        for (const prompt of puzzle.minigame?.prompts ?? []) {
          const correctLabels = prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.label);
          concepts.add(prompt.concept);
          expect(prompt.requiredSelectionCount, `${type}: ${prompt.id}`).toBe(2);
          expect(correctLabels, `${type}: ${prompt.id}`).toHaveLength(2);
          if (type === "reading-detective") {
            expect(correctLabels.some((label) => label.startsWith("Risposta:")), prompt.id).toBe(true);
            expect(correctLabels.some((label) => label.startsWith("Prova:")), prompt.id).toBe(true);
          }
          if (type === "error-diagnosis") {
            expect(correctLabels.some((label) => label.startsWith("Correzione:")), prompt.id).toBe(true);
            expect(correctLabels.some((label) => label.startsWith("Diagnosi:")), prompt.id).toBe(true);
          }
          if (type === "dialogue-response") {
            expect(correctLabels.some((label) => label.startsWith("Risposta:")), prompt.id).toBe(true);
            expect(correctLabels.some((label) => label.startsWith("Motivo:")), prompt.id).toBe(true);
          }
        }
      }
      expect(concepts.size, `${type} concept variety`).toBeGreaterThan(10);
    }
  });
});
