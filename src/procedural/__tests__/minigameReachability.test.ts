import { describe, expect, it } from "vitest";
import { difficultyPresets } from "../../data/procedural/difficultyPresets";
import { LanguageCorruptionGenerator } from "../generators/LanguageCorruptionGenerator";
import { EnglishInstructionGenerator } from "../generators/EnglishInstructionGenerator";
import { CodingPuzzleGenerator } from "../generators/CodingPuzzleGenerator";
import { MathPuzzleGenerator } from "../generators/MathPuzzleGenerator";
import { MusicNoteGenerator } from "../generators/MusicNoteGenerator";
import { PhysicsPuzzleGenerator } from "../generators/PhysicsPuzzleGenerator";
import { circuitMinigameTypeForLevel } from "../generators/CircuitMinigameGenerator";
import { Random } from "../Random";
import type {
  CodingMinigameType,
  EnglishMinigameType,
  LanguageMinigameType,
  MathMinigameType,
  MusicMinigameType,
  PhysicsExerciseType,
} from "../ProceduralTypes";

// Every declared minigame type must be producible by its generator, so it can
// actually surface inside a mission (base console, focus series or scene sprint
// rotation). If a new type is added but never wired, this test fails.
const ALL = {
  math: ["target-sum", "factor-hunt", "operation-chain", "number-sequence", "expression-build", "fraction-lab", "ratio-proportion", "geometry-measure", "data-probability"] satisfies MathMinigameType[],
  coding: ["sequence-builder", "state-tracer", "bug-hunt", "binary-bits", "logic-gate", "loop-output", "conditional-path", "algorithm-order", "python-lab", "language-atlas"] satisfies CodingMinigameType[],
  circuit: ["component-id", "predict-led", "ohms-law", "series-parallel"],
  language: ["agreement-sprint", "connector-route", "intruder-hunt", "word-order", "lexicon-lab", "verb-mastery", "punctuation-fix", "argument-sort"] satisfies LanguageMinigameType[],
  english: ["action-relay", "sequence-switchboard", "data-command-scan", "grammar-fix", "sentence-build", "vocab-lab", "translation-match", "reading-detective", "error-diagnosis", "dialogue-response"] satisfies EnglishMinigameType[],
  music: ["note-hunt", "interval-jump", "rhythm-gap", "scale-step", "note-duration", "auditory-interval"] satisfies MusicMinigameType[],
  physics: ["motion-graph", "unit-check", "force-diagram", "energy-transfer", "experiment-order", "density-pressure", "heat-temperature", "wave-reading", "optics-ray"] satisfies PhysicsExerciseType[],
};

// `auditory-note` is intentionally excluded: naming an isolated pitch by ear
// needs absolute pitch. Ear training is done relatively (auditory-interval).
const INTENTIONALLY_EXCLUDED = new Set<string>(["auditory-note"]);

describe("minigame reachability", () => {
  it("every declared minigame type is producible by its generator across levels", () => {
    const lang = new LanguageCorruptionGenerator();
    const eng = new EnglishInstructionGenerator();
    const cod = new CodingPuzzleGenerator();
    const mat = new MathPuzzleGenerator();
    const mus = new MusicNoteGenerator();
    const phy = new PhysicsPuzzleGenerator();
    const seen: Record<keyof typeof ALL, Set<string>> = {
      math: new Set(), coding: new Set(), circuit: new Set(), language: new Set(), english: new Set(), music: new Set(), physics: new Set(),
    };

    for (let level = 1; level <= 8; level += 1) {
      const preset = difficultyPresets[level - 1];
      for (let s = 0; s < 300; s += 1) {
        const r = new Random(`reach:${level}:${s}`);
        const lt = lang.generateMinigame(r.fork("l"), level).minigame?.type;
        const et = eng.generateMinigame(r.fork("e"), level).minigame?.type;
        const ct = cod.generateMinigame(r.fork("c"), preset).minigame?.type;
        if (lt) seen.language.add(lt);
        if (et) seen.english.add(et);
        if (ct) seen.coding.add(ct);
        const mm = mat.generateMinigame(r.fork("m"), preset) as { minigame?: { prompts?: Array<{ type: string }> } };
        (mm.minigame?.prompts ?? []).forEach((p) => seen.math.add(p.type));
        seen.music.add(mus.generate(r.fork("u"), level as never).challengeMode);
        seen.physics.add(phy.generate(r.fork("p"), preset).exerciseType);
        seen.circuit.add(circuitMinigameTypeForLevel(r.fork("k"), level));
      }
    }

    for (const key of Object.keys(ALL) as Array<keyof typeof ALL>) {
      const missing = ALL[key].filter((t) => !INTENTIONALLY_EXCLUDED.has(t) && !seen[key].has(t));
      expect(missing, `${key} minigame types never produced by the generator`).toEqual([]);
    }
  }, 120_000);
});
