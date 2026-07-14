import { describe, expect, it } from "vitest";
import { theorySubjectOrder, theoryTopics } from "../../data/theoryCatalog";
import { competencies } from "../../data/competencies";
import { noraKnowledge } from "../NoraKnowledge";
import { proceduralDirector } from "../../procedural/ProceduralDirector";
import type { ProceduralPuzzleKind } from "../../procedural/ProceduralTypes";

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
