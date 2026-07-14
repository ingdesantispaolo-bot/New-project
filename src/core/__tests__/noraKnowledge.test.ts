import { describe, expect, it } from "vitest";
import { theorySubjectOrder, theoryTopics } from "../../data/theoryCatalog";
import { noraKnowledge } from "../NoraKnowledge";
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

  it("uses direct concept mappings before broad subject fallback", () => {
    expect(noraKnowledge.topicForPuzzle("physics", { exerciseType: "wave-reading" })?.id).toBe("fisica-onde-ottica");
    expect(noraKnowledge.topicForPuzzle("circuit", { challengeType: "reversed-led" })?.id).toBe("circuiti-polarita-protezione");
    expect(noraKnowledge.topicForPuzzle("english", { challengeType: "condition" })?.id).toBe("inglese-sequenze-condizioni");
  });
});

