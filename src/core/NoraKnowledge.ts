import { theoryTopics, type TheorySubject, type TheoryTopic } from "../data/theoryCatalog";
import type { ProceduralPuzzleKind } from "../procedural/ProceduralTypes";

type PuzzleLike = {
  title?: string;
  learningPurpose?: string;
  conceptTags?: string[];
  curriculumTags?: string[];
  archetype?: string;
  challengeType?: string;
  challengeMode?: string;
  exerciseType?: string;
  faults?: string[];
  requiredRepairs?: string[];
  minigame?: { type?: string; prompts?: Array<{ concept?: string; type?: string }> };
};

const SUBJECT_BY_KIND: Record<ProceduralPuzzleKind, TheorySubject> = {
  language: "italiano",
  latin: "latino",
  circuit: "elettronica",
  math: "matematica",
  english: "inglese",
  robot: "coding",
  coding: "coding",
  music: "musica",
  physics: "fisica",
};

const DIRECT_TOPIC_BY_KEY: Partial<Record<string, string>> = {
  "math:frazioni": "frazioni",
  "math:percentuali": "percentuali",
  "math:proporzione": "rapporti-proporzioni",
  "math:potenze-radici": "radice-quadrata",
  "math:geometria": "quadrilateri",
  "math:statistica": "statistica",
  "math:probabilita": "probabilita",
  "math:equazione-primo-grado": "equazioni",
  "math:equazione-secondo-grado": "equazioni",
  "math:sistemi-lineari": "equazioni",
  "math:pre-algebra": "calcolo-letterale",
  "math:funzione-lineare": "funzioni-retta",
  "math:grafici-cartesiani": "funzioni-retta",
  "math:coordinate": "piano-cartesiano",
  "math:lettura-dati": "statistica",
  "math:calcolo-diretto": "numeri-naturali",
  "english:command": "inglese-comandi-operativi",
  "english:safety": "inglese-comandi-operativi",
  "english:sequence": "inglese-sequenze-condizioni",
  "english:condition": "inglese-sequenze-condizioni",
  "english:data-reading": "inglese-sequenze-condizioni",
  "circuit:open-switch": "circuito-chiuso-corrente",
  "circuit:missing-wire": "circuito-chiuso-corrente",
  "circuit:reversed-led": "circuiti-polarita-protezione",
  "circuit:missing-resistor": "circuiti-polarita-protezione",
  "circuit:wrong-resistor-value": "circuiti-polarita-protezione",
  "coding:trace-output": "coding-tracing-variabili",
  "coding:variable-state": "coding-tracing-variabili",
  "coding:loop-count": "coding-cicli-condizioni",
  "coding:conditional-branch": "coding-cicli-condizioni",
  "coding:boolean-logic": "coding-cicli-condizioni",
  "coding:debug-line": "coding-cicli-condizioni",
  "robot:route-planning": "robot-griglia-coordinate",
  "robot:minimal-route": "robot-griglia-coordinate",
  "robot:coordinate-routing": "robot-griglia-coordinate",
  "music:note-hunt": "musica-pentagramma-chiavi",
  "music:scale-step": "musica-pentagramma-chiavi",
  "music:rhythm-gap": "musica-ritmo-intervalli",
  "music:note-duration": "musica-ritmo-intervalli",
  "music:interval-jump": "musica-ritmo-intervalli",
  "physics:unit-check": "fisica-misure-unita",
  "physics:motion-graph": "fisica-moto-forze-energia",
  "physics:force-diagram": "fisica-moto-forze-energia",
  "physics:energy-transfer": "fisica-moto-forze-energia",
  "physics:wave-reading": "fisica-onde-ottica",
  "physics:optics-ray": "fisica-onde-ottica",
  "latin:declension": "latino-casi-declinazioni",
  "latin:case-function": "latino-casi-declinazioni",
  "latin:agreement": "latino-casi-declinazioni",
  "latin:conjugation": "latino-verbi-concordanza",
  "latin:verb-analysis": "latino-verbi-concordanza",
};

function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function puzzleKeys(kind: ProceduralPuzzleKind, puzzle?: PuzzleLike): string[] {
  if (!puzzle) return [];
  return [
    puzzle.archetype,
    puzzle.challengeType,
    puzzle.challengeMode,
    puzzle.exerciseType,
    puzzle.minigame?.type,
    ...(puzzle.requiredRepairs ?? []),
    ...(puzzle.faults ?? []),
    ...(puzzle.minigame?.prompts?.map((prompt) => prompt.type) ?? []),
  ]
    .filter((item): item is string => Boolean(item))
    .map((item) => `${kind}:${item}`);
}

function puzzleWords(puzzle?: PuzzleLike): string[] {
  if (!puzzle) return [];
  return [
    ...(puzzle.conceptTags ?? []),
    ...(puzzle.curriculumTags ?? []),
    puzzle.archetype,
    puzzle.challengeType,
    puzzle.challengeMode,
    puzzle.exerciseType,
    puzzle.minigame?.type,
    puzzle.title,
    puzzle.learningPurpose,
    ...(puzzle.minigame?.prompts?.flatMap((prompt) => [prompt.concept, prompt.type]) ?? []),
  ]
    .filter((item): item is string => Boolean(item))
    .flatMap((item) => normalize(item).split(/\s+/).filter(Boolean));
}

function scoreTopic(topic: TheoryTopic, words: Set<string>, kind: ProceduralPuzzleKind): number {
  let score = topic.linkedPuzzleKinds.includes(kind) ? 6 : 0;
  const haystack = [
    topic.id,
    topic.title,
    topic.area,
    ...topic.tags,
    topic.definition,
    ...topic.coreRules,
    ...topic.method,
  ].flatMap((item) => normalize(item).split(/\s+/).filter(Boolean));
  for (const word of haystack) {
    if (words.has(word)) score += word.length > 3 ? 2 : 1;
  }
  return score;
}

class NoraKnowledge {
  topics(): TheoryTopic[] {
    return theoryTopics;
  }

  topicsForSubject(subject: TheorySubject): TheoryTopic[] {
    return theoryTopics.filter((topic) => topic.subject === subject);
  }

  topicForCompetency(competencyId: string): TheoryTopic | undefined {
    const exact = theoryTopics.find((topic) => (topic.competencies ?? []).includes(competencyId));
    if (exact) return exact;
    const subject = competencyId.split(".")[0] as TheorySubject;
    return theoryTopics.find((topic) => topic.subject === subject);
  }

  weakestCompetencyTopic(scores: Record<string, number>): TheoryTopic | undefined {
    return Object.entries(scores)
      .filter(([, score]) => score > 0 && score < 65)
      .sort((a, b) => a[1] - b[1])
      .map(([id]) => this.topicForCompetency(id))
      .find((topic): topic is TheoryTopic => Boolean(topic));
  }

  topicById(id: string): TheoryTopic | undefined {
    return theoryTopics.find((topic) => topic.id === id);
  }

  subjectForKind(kind: ProceduralPuzzleKind): TheorySubject {
    return SUBJECT_BY_KIND[kind];
  }

  /** Direct-map targets that no longer resolve to a topic (must stay empty). */
  brokenDirectTargets(): string[] {
    return Array.from(new Set(Object.values(DIRECT_TOPIC_BY_KEY)))
      .filter((id): id is string => typeof id === "string" && !this.topicById(id));
  }

  topicForPuzzle(kind: ProceduralPuzzleKind, puzzle?: PuzzleLike): TheoryTopic | undefined {
    for (const key of puzzleKeys(kind, puzzle)) {
      const direct = DIRECT_TOPIC_BY_KEY[key];
      // Fall through to fuzzy matching if a mapping points at a missing card,
      // so a stale direct entry can never leave a puzzle without any theory.
      if (direct) {
        const topic = this.topicById(direct);
        if (topic) return topic;
      }
    }

    const subject = this.subjectForKind(kind);
    const candidates = this.topicsForSubject(subject);
    if (candidates.length === 0) return undefined;
    const words = new Set(puzzleWords(puzzle));
    if (words.size === 0) return candidates.find((topic) => topic.linkedPuzzleKinds.includes(kind)) ?? candidates[0];
    return [...candidates].sort((a, b) => scoreTopic(b, words, kind) - scoreTopic(a, words, kind))[0];
  }

  noraBrief(topic: TheoryTopic): string {
    const rule = topic.method[0] ?? topic.coreRules[0] ?? topic.definition;
    const watch = topic.watchOut[0] ? ` Attenzione: ${topic.watchOut[0]}` : "";
    return `${topic.noraExplanation} Metodo: ${rule}.${watch}`;
  }
}

export const noraKnowledge = new NoraKnowledge();
