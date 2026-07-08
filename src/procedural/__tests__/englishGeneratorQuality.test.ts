import { describe, expect, it } from "vitest";
import { englishTemplates } from "../../data/procedural/englishTemplates";
import { englishVocabularyEntries } from "../../data/procedural/englishVocabularyBank";
import { EnglishInstructionGenerator } from "../generators/EnglishInstructionGenerator";
import { LanguagePuzzleValidator } from "../validators/LanguagePuzzleValidator";
import type { EnglishMinigamePrompt, EnglishMinigameType } from "../ProceduralTypes";
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

const stripChoiceRole = (label: string): string =>
  label.replace(/^(azione|prova|risposta|motivo|correzione|diagnosi):\s*/i, "").trim();

const normalizeVisibleHint = (text: string): string =>
  text
    .normalize("NFKD")
    .toLocaleLowerCase("en")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9']+/g, " ")
    .trim();

const visibleHintContains = (haystack: string, needle: string): boolean => {
  if (needle.length < 2) return false;
  const haystackTokens = haystack.split(/\s+/).filter(Boolean);
  const needleTokens = needle.split(/\s+/).filter(Boolean);
  if (needleTokens.length === 0) return false;
  if (needleTokens.length === 1 && needle.length <= 3) {
    return haystackTokens.includes(needle);
  }
  return ` ${haystack} `.includes(` ${needle} `);
};

const glossaryLeaksSolution = (prompt: EnglishMinigamePrompt): string | undefined => {
  if (prompt.type === "sentence-build") return undefined;
  for (const entry of prompt.glossary) {
    const term = normalizeVisibleHint(entry.term);
    for (const label of prompt.solutionLabels) {
      const solution = normalizeVisibleHint(stripChoiceRole(label));
      if (visibleHintContains(term, solution) || visibleHintContains(solution, term)) {
        return `${entry.term} -> ${label}`;
      }
    }
  }
  return undefined;
};

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

  it("does not reveal minigame answers through visible glossary, data notes or grammar hints", () => {
    const generator = new EnglishInstructionGenerator();
    for (const type of TYPES) {
      for (let level = 1; level <= 8; level += 1) {
        for (let sample = 0; sample < 4; sample += 1) {
          const puzzle = generator.generateMinigame(new Random(`english-anti-leak:${type}:${level}:${sample}`), level, [type]);
          for (const prompt of puzzle.minigame?.prompts.slice(0, 16) ?? []) {
            expect(glossaryLeaksSolution(prompt), `${type} L${level} ${prompt.id}: glossary leak`).toBeUndefined();
            expect(prompt.dataPoints?.some((point) => Boolean(point.note)), `${type} L${level} ${prompt.id}: data note leak`).not.toBe(true);
            if (prompt.type === "grammar-fix") {
              expect(prompt.instruction, `${type} L${level} ${prompt.id}: parenthetical grammar hint`).not.toMatch(/\([^)]*\)/);
            }
          }
        }
      }
    }
  });

  it("keeps authored English data tables neutral instead of tagging the answer", () => {
    const bannedNote = /\b(below|above|safe|dimmer|brighter|inside|outside|safest|fastest|faster|same value|limit|threshold)\b/i;
    for (const template of englishTemplates) {
      for (const point of template.dataPoints ?? []) {
        expect(point.note ?? "", `${template.id}: ${point.label}`).not.toMatch(bannedNote);
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
