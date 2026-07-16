import { describe, expect, it } from "vitest";
import { theorySubjectOrder, theoryTopics } from "../../data/theoryCatalog";
import { competencies } from "../../data/competencies";
import { mathTemplates } from "../../data/procedural/mathTemplates";
import { noraKnowledge } from "../NoraKnowledge";
import { proceduralDirector } from "../../procedural/ProceduralDirector";
import { MathPuzzleGenerator } from "../../procedural/generators/MathPuzzleGenerator";
import { difficultyModel } from "../../procedural/DifficultyModel";
import { Random } from "../../procedural/Random";
import type { DifficultyLevel, ProceduralPuzzleKind } from "../../procedural/ProceduralTypes";

describe("NoraKnowledge", () => {
  it("has at least one theory topic for every trainable subject", () => {
    for (const subject of theorySubjectOrder) {
      expect(theoryTopics.some((topic) => topic.subject === subject), subject).toBe(true);
    }
  });

  it("resolves a topic for every procedural puzzle kind", () => {
    const kinds: ProceduralPuzzleKind[] = ["language", "latin", "circuit", "math", "english", "robot", "coding", "music", "physics"];
    for (const kind of kinds) {
      expect(noraKnowledge.topicForPuzzle(kind), kind).toBeDefined();
    }
  });

  it("keeps every topic linked to at least one puzzle kind", () => {
    for (const topic of theoryTopics) {
      expect(topic.linkedPuzzleKinds.length, topic.id).toBeGreaterThan(0);
    }
  });

  it("links every topic to known competencies", () => {
    const known = new Set(competencies.map((competency) => competency.id));
    for (const topic of theoryTopics) {
      expect((topic.competencies ?? []).filter((id) => !known.has(id)), topic.id).toEqual([]);
    }
  });

  it("uses direct concept mappings before broad subject fallback", () => {
    expect(noraKnowledge.topicForPuzzle("physics", { exerciseType: "wave-reading" })?.id).toBe("fisica-onde-ottica");
    expect(noraKnowledge.topicForPuzzle("circuit", { challengeType: "reversed-led" })?.id).toBe("circuiti-polarita-protezione");
    expect(noraKnowledge.topicForPuzzle("english", { challengeType: "condition" })?.id).toBe("inglese-sequenze-condizioni");
    // Newly mapped math archetypes must hit precise cards, not the fuzzy fallback.
    expect(noraKnowledge.topicForPuzzle("math", { archetype: "equazione-secondo-grado" })?.id).toBe("equazioni");
    expect(noraKnowledge.topicForPuzzle("math", { archetype: "funzione-lineare" })?.id).toBe("funzioni-retta");
  });

  it("has no dangling direct-map targets", () => {
    expect(noraKnowledge.brokenDirectTargets()).toEqual([]);
    expect(noraKnowledge.brokenCurriculumTargets()).toEqual([]);
  });

  it("maps every math template to a precise theory card via curriculumTags", () => {
    // Ogni esercizio matematico deve avere almeno un curriculumTag che risolve a
    // una scheda: così il primo-incontro mostra SEMPRE la teoria giusta, non una
    // scheda a caso dal fallback fuzzy.
    for (const template of mathTemplates) {
      const topic = noraKnowledge.topicForCurriculumTags(template.curriculumTags);
      expect(topic, `${template.id} (${(template.curriculumTags ?? []).join(", ")})`).toBeDefined();
    }
  });

  it("risolve la teoria per ogni concetto dei prompt dei minigiochi matematica", () => {
    // Un minigioco (es. fraction-lab) alterna prompt di concetti diversi: ogni
    // prompt deve poter mostrare la scheda GIUSTA dal suo `concept`.
    const generator = new MathPuzzleGenerator();
    const types = [
      "target-sum", "factor-hunt", "operation-chain", "number-sequence",
      "expression-build", "fraction-lab", "ratio-proportion", "geometry-measure", "data-probability",
    ] as const;
    for (const type of types) {
      for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const preset = difficultyModel.getPreset(level);
        for (let seed = 0; seed < 6; seed += 1) {
          const mini = generator.generateMinigame(new Random(`mini-${type}-${level}-${seed}`), preset, [type]).minigame;
          for (const prompt of mini?.prompts ?? []) {
            expect(
              noraKnowledge.topicForMinigameConcept(prompt.concept),
              `${type}/${prompt.concept}`,
            ).toBeDefined();
          }
        }
      }
    }
  });

  it("resolves the right card for cross-cutting archetypes (not just the archetype)", () => {
    // "vincolo" copre concetti diversi: la scheda dipende dai curriculumTags.
    expect(noraKnowledge.topicForPuzzle("math", { archetype: "vincolo", curriculumTags: ["mcm", "multipli"] })?.id).toBe("divisibilita");
    expect(noraKnowledge.topicForPuzzle("math", { archetype: "vincolo", curriculumTags: ["numeri relativi", "linea dei numeri"] })?.id).toBe("numeri-relativi");
    expect(noraKnowledge.topicForPuzzle("math", { archetype: "lettura-dati", curriculumTags: ["media", "dati"] })?.id).toBe("statistica");
    expect(noraKnowledge.topicForPuzzle("math", { archetype: "sequenza", curriculumTags: ["successioni numeriche"] })?.id).toBe("numeri-naturali");
  });

  it("never leaves a real generated puzzle without a theory card", () => {
    const mission = proceduralDirector.generateMission("THEORY-COVERAGE", 6, []);
    const byKind: Array<[ProceduralPuzzleKind, unknown]> = [
      ["math", mission.puzzles.math],
      ["robot", mission.puzzles.robot],
      ["circuit", mission.puzzles.circuit],
      ["coding", mission.puzzles.coding],
      ["language", mission.puzzles.language],
      ["english", mission.puzzles.english],
      ["music", mission.puzzles.music],
      ["physics", mission.puzzles.physics],
      ["latin", mission.puzzles.latin],
    ];
    for (const [kind, puzzle] of byKind) {
      expect(noraKnowledge.topicForPuzzle(kind, puzzle as never), kind).toBeDefined();
    }
  });

  it("can recommend a topic from a weak practiced competency", () => {
    expect(noraKnowledge.weakestCompetencyTopic({
      "matematica.calcolo": 80,
      "inglese.istruzioni": 24,
    })?.id).toBe("inglese-comandi-operativi");
  });
});
