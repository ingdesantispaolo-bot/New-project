import { describe, expect, it } from "vitest";
import { difficultyModel } from "../DifficultyModel";
import type { CircuitFaultType } from "../ProceduralTypes";
import { Random } from "../Random";
import { CircuitFaultGenerator } from "../generators/CircuitFaultGenerator";
import { circuitMinigameTypeForLevel } from "../generators/CircuitMinigameGenerator";
import { repairLabels } from "../../scenes/procedural/ProceduralMissionDefs";

const generator = new CircuitFaultGenerator();

function generate(level: number, sample: number) {
  return generator.generate(new Random(`circuit-learning:${level}:${sample}`), difficultyModel.getPreset(level));
}

describe("circuit learning path", () => {
  it("starts from closed-path faults before LED protection or polarity", () => {
    const levelOneFaults = new Set<CircuitFaultType>();
    for (let sample = 0; sample < 40; sample += 1) {
      const puzzle = generate(1, sample);
      puzzle.faults.forEach((fault) => levelOneFaults.add(fault));
      expect(puzzle.faults).toHaveLength(1);
      expect(puzzle.faults.every((fault) => fault === "open-switch" || fault === "missing-wire")).toBe(true);
      expect((puzzle.componentChallenges ?? []).map((challenge) => challenge.componentId)).toEqual(["battery", "switch", "return"]);
      expect(puzzle.title.toLowerCase()).toContain("circuito base");
    }
    expect(levelOneFaults.size).toBeGreaterThan(1);
  });

  it("introduces resistor and LED before advanced components", () => {
    for (let sample = 0; sample < 30; sample += 1) {
      const levelTwo = generate(2, sample);
      const levelThree = generate(3, sample);
      expect((levelTwo.componentChallenges ?? []).map((challenge) => challenge.componentId)).toEqual(["resistor", "led"]);
      expect(levelTwo.faults.every((fault) => ["open-switch", "missing-wire", "missing-resistor"].includes(fault))).toBe(true);
      expect(levelThree.faults.every((fault) => ["open-switch", "missing-wire", "missing-resistor", "reversed-led", "wrong-resistor-value"].includes(fault))).toBe(true);
      expect(levelThree.faults).toHaveLength(1);
    }
  });

  it("keeps the first circuit minigame focused on component recognition", () => {
    for (let sample = 0; sample < 25; sample += 1) {
      expect(circuitMinigameTypeForLevel(new Random(`circuit-mini-path:${sample}`), 1)).toBe("component-id");
    }
  });

  it("keeps visual hints separate from component answer labels", () => {
    for (let level = 1; level <= 4; level += 1) {
      for (let sample = 0; sample < 20; sample += 1) {
        const puzzle = generate(level, sample);
        for (const challenge of puzzle.componentChallenges ?? []) {
          expect(challenge.visualHint.length).toBeGreaterThan(8);
          expect(challenge.symbolChoices).toContain(challenge.correctSymbol);
          expect(challenge.visualHint.toLocaleLowerCase("it")).not.toContain(challenge.correctSymbol.toLocaleLowerCase("it"));
        }
      }
    }
  });

  it("uses child-readable repair labels without abbreviations", () => {
    expect(Object.values(repairLabels).some((label) => /\bR\b|condens\.|switch/i.test(label))).toBe(false);
    expect(repairLabels["open-switch"]).toBe("Chiudi interruttore");
    expect(repairLabels["missing-resistor"]).toBe("Aggiungi resistenza");
  });
});
