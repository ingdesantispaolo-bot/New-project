import { describe, expect, it } from "vitest";
import { capDifficultyToSchoolYear, maxDifficultyForSchoolYear } from "../schoolLevel";
import { theoryTopics } from "../../data/theoryCatalog";
import { topicSchoolYear } from "../../data/topicSchoolYear";
import { topicPrerequisites } from "../../data/topicPrerequisites";
import { mathStudyPages } from "../../data/mathStudyPages";
import { italianStudyPages } from "../../data/italianStudyPages";

describe("schoolLevel — banda di difficoltà per anno", () => {
  it("tiene un profilo giovane nella sua fascia", () => {
    expect(maxDifficultyForSchoolYear(1)).toBe(3);
    expect(maxDifficultyForSchoolYear(2)).toBe(5);
    expect(maxDifficultyForSchoolYear(3)).toBe(8);
    expect(maxDifficultyForSchoolYear(undefined)).toBe(8);
  });

  it("applica il tetto senza scendere sotto 1", () => {
    expect(capDifficultyToSchoolYear(8, 1)).toBe(3); // prima media non va oltre 3
    expect(capDifficultyToSchoolYear(2, 1)).toBe(2); // sotto il tetto resta com'è
    expect(capDifficultyToSchoolYear(7, 2)).toBe(5);
    expect(capDifficultyToSchoolYear(8, undefined)).toBe(8); // senza anno, nessun tetto
    expect(capDifficultyToSchoolYear(0, 3)).toBe(1);
  });
});

describe("topicSchoolYear — tag anno scolastico", () => {
  it("assegna un anno (1-3) a ogni concetto del curricolo", () => {
    const ids = [...mathStudyPages, ...italianStudyPages].map((page) => page.id);
    for (const id of ids) {
      const year = topicSchoolYear[id];
      expect(year, `${id} senza anno`).toBeDefined();
      expect([1, 2, 3]).toContain(year);
    }
  });

  it("non introduce un concetto prima di un suo prerequisito (anno crescente)", () => {
    for (const [id, prereqs] of Object.entries(topicPrerequisites)) {
      const year = topicSchoolYear[id];
      if (year === undefined) continue;
      for (const prereqId of prereqs) {
        const prereqYear = topicSchoolYear[prereqId];
        if (prereqYear === undefined) continue;
        expect(
          prereqYear,
          `${prereqId} (${prereqYear}ª) è prerequisito di ${id} (${year}ª) ma verrebbe dopo`,
        ).toBeLessThanOrEqual(year);
      }
    }
  });

  it("collega l'anno al topic risolto nel catalogo", () => {
    expect(theoryTopics.find((topic) => topic.id === "frazioni")?.schoolYear).toBe(1);
    expect(theoryTopics.find((topic) => topic.id === "equazioni")?.schoolYear).toBe(3);
  });
});
