import { describe, expect, it } from "vitest";
import { theoryTopics } from "../theoryCatalog";
import { topicIntros } from "../topicIntros";
import { mathStudyPages } from "../mathStudyPages";
import { italianStudyPages } from "../italianStudyPages";

describe("topicIntros (primo incontro, registro prima media)", () => {
  it("copre OGNI concetto del catalogo con un intro dedicato (anche gli avanzati)", () => {
    // Requisito: spiegazione dettagliata da primo incontro per tutti gli argomenti,
    // dai numeri naturali fino a equazioni quadratiche, fisica delle onde e latino.
    const missing = theoryTopics.filter((topic) => !topic.intro).map((topic) => topic.id);
    expect(missing, `concetti senza intro: ${missing.join(", ")}`).toEqual([]);
  });

  it("copre ogni concetto di matematica e italiano con un intro dedicato", () => {
    const curriculumIds = [...mathStudyPages, ...italianStudyPages].map((page) => page.id);
    const missing = curriculumIds.filter((id) => !topicIntros[id]);
    expect(missing, `concetti senza intro: ${missing.join(", ")}`).toEqual([]);
  });

  it("copre la porta d'ingresso di ogni materia giocabile (primo concetto che un principiante incontra)", () => {
    // Concetti a bassa profondità delle materie non-matematica/italiano: sono i
    // primi che un profilo giovane (cap livello 3) incontra e devono essere gentili.
    const gateways = [
      "inglese-comandi-operativi",
      "circuito-chiuso-corrente",
      "coding-tracing-variabili",
      "robot-griglia-coordinate",
      "musica-pentagramma-chiavi",
      "fisica-misure-unita",
      "latino-casi-declinazioni",
    ];
    for (const id of gateways) {
      expect(topicIntros[id], `${id} senza intro`).toBeDefined();
      expect(theoryTopics.find((topic) => topic.id === id)?.intro, `${id} non agganciato al catalogo`).toBeDefined();
    }
  });

  it("non ha intro orfani (ogni chiave punta a un topic esistente)", () => {
    const topicIds = new Set(theoryTopics.map((topic) => topic.id));
    const orphans = Object.keys(topicIntros).filter((id) => !topicIds.has(id));
    expect(orphans, `intro orfani: ${orphans.join(", ")}`).toEqual([]);
  });

  it("collega l'intro al topic risolto nel catalogo", () => {
    const frazioni = theoryTopics.find((topic) => topic.id === "frazioni");
    expect(frazioni?.intro?.hook).toContain("pizza");
    expect(frazioni?.intro?.newWords).toBeTruthy();
    expect(frazioni?.intro?.guided).toBeTruthy();
  });

  it("tiene gli intro brevi e concreti (leggibili da un undicenne)", () => {
    for (const [id, intro] of Object.entries(topicIntros)) {
      expect(intro.hook.length, `${id} hook`).toBeGreaterThan(20);
      expect(intro.hook.length, `${id} hook troppo lungo`).toBeLessThan(320);
      expect(intro.guided.length, `${id} guided`).toBeGreaterThan(15);
    }
  });
});
