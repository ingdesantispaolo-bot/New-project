import { describe, expect, it } from "vitest";
import { englishVocabularyEntries } from "../../data/procedural/englishVocabularyBank";
import { EnglishInstructionGenerator } from "../generators/EnglishInstructionGenerator";
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
    for (const type of TYPES) {
      for (let level = 1; level <= 8; level += 1) {
        const puzzle = generator.generateMinigame(new Random(`english-quality:${type}:${level}`), level, [type]);
        const prompts = puzzle.minigame?.prompts ?? [];
        expect(prompts.length, `${type} L${level}: prompts`).toBeGreaterThan(0);

        for (const prompt of prompts.slice(0, 12)) {
          const labels = prompt.tiles.map((tile) => tile.label);
          const correctLabels = prompt.tiles.filter((tile) => tile.isCorrect).map((tile) => tile.label);

          expect(new Set(labels).size, `${type}: duplicate labels in ${prompt.id}`).toBe(labels.length);
          expect(correctLabels.length, `${type}: correct count in ${prompt.id}`).toBe(prompt.requiredSelectionCount);
          expect(new Set(prompt.solutionLabels), `${type}: solution labels in ${prompt.id}`).toEqual(new Set(correctLabels));
          expect(labels.some((label) => /\berrat[oaie]\b/i.test(label)), `${type}: visible self-revealing label in ${prompt.id}`).toBe(false);
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
});
