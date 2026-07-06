import { describe, expect, it } from "vitest";
import { languageTemplates } from "../../data/procedural/languageTemplates";
import { LanguageCorruptionGenerator, normalizeTypedAnswer } from "../generators/LanguageCorruptionGenerator";
import { LanguagePuzzleValidator } from "../validators/LanguagePuzzleValidator";
import { Random } from "../Random";
import type { DifficultyLevel, LanguageMinigameType } from "../ProceduralTypes";

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
    for (const type of ["agreement-sprint", "connector-route", "word-order", "verb-mastery", "punctuation-fix"] as const) {
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

  it("agreement distractors carry per-distractor diagnostic feedback (not a generic repeat)", () => {
    const diag = /numero|verbo|aggettivo|persona|participio|presente|passato|futuro|imperfetto|congiuntivo|condizionale|gerundio|terza|maschile|femminile/i;
    let prompts = 0;
    let diagnosticPrompts = 0;
    let wrongTiles = 0;
    let diagnosticTiles = 0;
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (let i = 0; i < 20; i += 1) {
        for (const prompt of gen.generateMinigame(new Random(`diag:${level}:${i}`), level, ["agreement-sprint"]).minigame?.prompts ?? []) {
          const wrong = prompt.tiles.filter((tile) => !tile.isCorrect);
          if (wrong.length === 0) continue;
          prompts += 1;
          wrongTiles += wrong.length;
          diagnosticTiles += wrong.filter((tile) => diag.test(tile.feedback)).length;
          const distinct = new Set(wrong.map((tile) => tile.feedback)).size === wrong.length;
          if (distinct && wrong.every((tile) => diag.test(tile.feedback))) diagnosticPrompts += 1;
        }
      }
    }
    // The parametric majority (~70%) gives distinct, error-naming feedback per tile.
    expect(diagnosticTiles / wrongTiles).toBeGreaterThan(0.6);
    expect(diagnosticPrompts / prompts).toBeGreaterThan(0.5);
  });

  it("no italian minigame is guessable by option length (no unique longest/shortest tell)", () => {
    // Across every tile-based italian minigame, the correct option must rarely be
    // the strict unique longest or shortest, so "pick the longest/shortest" is not
    // a winning strategy.
    for (const type of ["agreement-sprint", "connector-route", "lexicon-lab", "verb-mastery"] as const) {
      let n = 0;
      let uniqueLongest = 0;
      let uniqueShortest = 0;
      for (let i = 0; i < 240; i += 1) {
        const level = ((i % 8) + 1) as DifficultyLevel;
        for (const prompt of gen.generateMinigame(new Random(`itlen:${type}:${i}`), level, [type]).minigame?.prompts ?? []) {
          if (prompt.inputMode === "typed") continue;
          const correct = prompt.tiles.find((tile) => tile.isCorrect);
          if (!correct) continue;
          n += 1;
          const others = prompt.tiles.filter((tile) => !tile.isCorrect).map((tile) => tile.label.length);
          if (others.every((len) => correct.label.length > len)) uniqueLongest += 1;
          if (others.every((len) => correct.label.length < len)) uniqueShortest += 1;
        }
      }
      expect(n, type).toBeGreaterThan(200);
      expect(uniqueLongest / n, `${type} unique longest`).toBeLessThan(0.25);
      expect(uniqueShortest / n, `${type} unique shortest`).toBeLessThan(0.3);
    }
  });

  it("verb-mastery is not guessable by picking the longest option (no length tell)", () => {
    // Compound-tense correct answers used to be the longest option ~69% of the
    // time, letting a student pick the longest without knowing the tense. Guard
    // that the correct option is the strict longest well under half the time.
    let total = 0;
    let correctLongest = 0;
    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (let i = 0; i < 60; i += 1) {
        for (const prompt of gen.generateMinigame(new Random(`vlen:${level}:${i}`), level, ["verb-mastery"]).minigame?.prompts ?? []) {
          if (prompt.inputMode === "typed") continue;
          const correct = prompt.tiles.find((tile) => tile.isCorrect);
          if (!correct) continue;
          total += 1;
          const maxLen = Math.max(...prompt.tiles.map((tile) => tile.label.length));
          if (correct.label.length === maxLen) correctLongest += 1;
        }
      }
    }
    expect(total).toBeGreaterThan(200);
    expect(correctLongest / total).toBeLessThan(0.55);
  });

  it("verb-mastery names the tense/mode mistake per distractor", () => {
    const diag = /presente|passato|futuro|imperfetto|congiuntivo|condizionale|gerundio|participio|infinito|persona|indicativo|remoto|trapassato/i;
    let wrong = 0;
    let diagnostic = 0;
    for (const level of [2, 5, 7] as DifficultyLevel[]) {
      for (let i = 0; i < 30; i += 1) {
        for (const prompt of gen.generateMinigame(new Random(`vdiag:${level}:${i}`), level, ["verb-mastery"]).minigame?.prompts ?? []) {
          const w = prompt.tiles.filter((tile) => !tile.isCorrect);
          wrong += w.length;
          diagnostic += w.filter((tile) => diag.test(tile.feedback)).length;
        }
      }
    }
    expect(diagnostic / wrong).toBeGreaterThan(0.8);
  });

  it("validates every authored Italian template with distinct, explained choices", () => {
    for (const template of languageTemplates) {
      const level = Math.max(1, template.minDifficulty ?? 1) as DifficultyLevel;
      const puzzle = gen.generate(new Random(`template:${template.id}`), level, [template.id]);
      const normalized = puzzle.options.map((option) => normalizeTypedAnswer(option));
      expect(validator.validateItalian(puzzle), template.id).toBe(true);
      expect(new Set(normalized).size, template.id).toBe(normalized.length);
      for (const option of puzzle.options) {
        if (option === puzzle.repaired) continue;
        expect(puzzle.optionFeedback?.[option]?.length ?? 0, `${template.id}: ${option}`).toBeGreaterThan(35);
      }
    }
  });

  it("keeps every Italian minigame type structurally sound and varied at high level", () => {
    const types: LanguageMinigameType[] = [
      "agreement-sprint",
      "connector-route",
      "intruder-hunt",
      "word-order",
      "lexicon-lab",
      "verb-mastery",
      "punctuation-fix",
    ];
    for (const type of types) {
      const puzzle = gen.generateMinigame(new Random(`all-it:${type}`), 8, [type]);
      expect(validator.validateItalian(puzzle), type).toBe(true);
      const prompts = puzzle.minigame?.prompts ?? [];
      expect(prompts.length, type).toBeGreaterThan(20);
      expect(new Set(prompts.map((prompt) => prompt.signature)).size, `${type} signatures`).toBe(prompts.length);
      for (const prompt of prompts) {
        const labels = prompt.tiles.map((tile) => tile.label);
        expect(prompt.explanation.length, `${type}: ${prompt.context}`).toBeGreaterThan(35);
        expect(prompt.concept.length, `${type}: ${prompt.context}`).toBeGreaterThan(3);
        if (prompt.type === "word-order") {
          expect(prompt.solutionLabels.join(" ").length).toBeGreaterThan(12);
          expect(prompt.requiredSelectionCount).toBe(prompt.solutionLabels.length);
          expect(prompt.tiles.every((tile) => tile.isCorrect)).toBe(true);
        } else {
          expect(new Set(labels).size, `${type}: ${prompt.context}`).toBe(labels.length);
          const correctTiles = prompt.tiles.filter((tile) => tile.isCorrect);
          expect(correctTiles, `${type}: ${prompt.context}`).toHaveLength(1);
          expect(prompt.solutionLabels).toEqual([correctTiles[0].label]);
          for (const tile of prompt.tiles.filter((candidate) => !candidate.isCorrect)) {
            expect(tile.feedback.length, `${type}: ${tile.label}`).toBeGreaterThan(30);
          }
        }
        if (prompt.inputMode === "typed") {
          expect(prompt.acceptedAnswers).toContain(normalizeTypedAnswer(prompt.solutionLabels[0]));
        }
      }
    }
  });

  it("punctuation-fix covers accent, apostrophe and homophone traps without ambiguous correct forms", () => {
    const concepts = new Set<string>();
    let prompts = 0;
    for (let i = 0; i < 24; i += 1) {
      const game = gen.generateMinigame(new Random(`punct:${i}`), 8, ["punctuation-fix"]).minigame!;
      for (const prompt of game.prompts) {
        prompts += 1;
        concepts.add(prompt.concept);
        expect(prompt.tiles.filter((tile) => tile.isCorrect)).toHaveLength(1);
        expect(prompt.solutionLabels[0]).not.toMatch(/'\s/u);
        expect(prompt.solutionLabels[0]).not.toMatch(/\s'$/u);
        expect(prompt.explanation).toMatch(/accent|apostrof|verbo|congiunzione|pronome|preposizione|ausiliare|elide|troncamento/i);
      }
    }
    expect(prompts).toBeGreaterThan(400);
    expect([...concepts].some((concept) => concept.includes("è / e") || concept.includes("è verbo"))).toBe(true);
    expect([...concepts].some((concept) => concept.includes("ha / a") || concept.includes("ausiliare"))).toBe(true);
    expect([...concepts].some((concept) => concept.includes("po'") || concept.includes("apostrofo"))).toBe(true);
    expect([...concepts].some((concept) => concept.includes("perché") || concept.includes("finché"))).toBe(true);
  });
});
