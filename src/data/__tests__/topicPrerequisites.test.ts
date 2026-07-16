import { describe, expect, it } from "vitest";
import { theoryTopics } from "../theoryCatalog";
import { topicPrerequisites } from "../topicPrerequisites";
import { mathTemplates } from "../procedural/mathTemplates";
import { noraKnowledge } from "../../core/NoraKnowledge";

function topicById(id: string) {
  return theoryTopics.find((topic) => topic.id === id);
}

describe("topicPrerequisites (grafo di apprendimento)", () => {
  it("referenzia solo concetti esistenti", () => {
    const ids = new Set(theoryTopics.map((topic) => topic.id));
    for (const [id, prereqs] of Object.entries(topicPrerequisites)) {
      expect(ids.has(id), `topic sconosciuto: ${id}`).toBe(true);
      for (const prereq of prereqs) {
        expect(ids.has(prereq), `prerequisito sconosciuto: ${prereq} (in ${id})`).toBe(true);
      }
    }
  });

  it("è aciclico (nessun concetto dipende da se stesso a catena)", () => {
    const visiting = new Set<string>();
    const done = new Set<string>();
    const path: string[] = [];
    const visit = (id: string): void => {
      if (done.has(id)) return;
      expect(visiting.has(id), `ciclo: ${[...path, id].join(" -> ")}`).toBe(false);
      visiting.add(id);
      path.push(id);
      for (const prereq of topicPrerequisites[id] ?? []) visit(prereq);
      path.pop();
      visiting.delete(id);
      done.add(id);
    };
    for (const id of Object.keys(topicPrerequisites)) visit(id);
  });

  it("introduce ogni prerequisito a una profondità ≤ del concetto che lo usa", () => {
    for (const [id, prereqs] of Object.entries(topicPrerequisites)) {
      const topic = topicById(id);
      if (!topic) continue;
      for (const prereqId of prereqs) {
        const prereq = topicById(prereqId);
        if (!prereq) continue;
        expect(
          prereq.levelRange[0],
          `${prereqId} (fascia da ${prereq.levelRange[0]}) è prerequisito di ${id} (fascia da ${topic.levelRange[0]}) ma inizia più tardi`,
        ).toBeLessThanOrEqual(topic.levelRange[0]);
      }
    }
  });

  it("allinea la teoria agli esercizi: nessun esercizio precede la fascia del suo concetto", () => {
    // Per ogni template matematico, la scheda risolta dai suoi curriculumTags deve
    // essere già disponibile alla profondità in cui l'esercizio può comparire.
    for (const template of mathTemplates) {
      const topic = noraKnowledge.topicForCurriculumTags(template.curriculumTags);
      expect(topic, `${template.id} senza scheda`).toBeDefined();
      if (!topic) continue;
      expect(
        topic.levelRange[0],
        `${template.id} (mc ${template.minComplexity}) → ${topic.id} (fascia da ${topic.levelRange[0]}): l'esercizio arriva prima della teoria`,
      ).toBeLessThanOrEqual(template.minComplexity);
    }
  });
});
