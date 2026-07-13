import { describe, expect, it } from "vitest";
import { MusicNoteGenerator } from "../generators/MusicNoteGenerator";
import { Random } from "../Random";
import { ChallengeQualityValidator } from "../validators/ChallengeQualityValidator";
import type { DifficultyLevel, MusicMinigameType } from "../ProceduralTypes";

const MODES: MusicMinigameType[] = [
  "note-hunt",
  "interval-jump",
  "auditory-interval",
  "rhythm-gap",
  "note-duration",
  "scale-step",
];

describe("Music generator quality", () => {
  it("always yields four unique choices with one correct across modes and levels", () => {
    const generator = new MusicNoteGenerator();
    const validator = new ChallengeQualityValidator();

    for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
      for (const mode of MODES) {
        for (let sample = 0; sample < 60; sample += 1) {
          const puzzle = generator.generate(new Random(`music-quality:${level}:${mode}:${sample}`), level, [mode]);
          const report = validator.validateMusic(puzzle);
          expect(report.reasons, `${puzzle.id} (${puzzle.challengeMode}) L${level}`).toEqual([]);
          expect(puzzle.choices.length).toBe(4);
          expect(new Set(puzzle.choices.map((c) => c.label)).size).toBe(4);
          expect(puzzle.choices.filter((c) => c.isCorrect).length).toBe(1);
        }
      }
    }
  });

  it("keeps auditory-interval valid even when the interval is a 'seconda' (regression)", () => {
    const generator = new MusicNoteGenerator();
    // Hammer the mode that previously dropped a distractor when a clamped step
    // collided with the correct interval, leaving only three choices.
    for (let sample = 0; sample < 400; sample += 1) {
      const puzzle = generator.generate(new Random(`music-audint:${sample}`), 4, ["auditory-interval"]);
      expect(puzzle.choices.length, puzzle.id).toBe(4);
      expect(new Set(puzzle.choices.map((c) => c.label)).size, puzzle.id).toBe(4);
      expect(puzzle.choices.filter((c) => c.isCorrect).length, puzzle.id).toBe(1);
    }
  });
});
