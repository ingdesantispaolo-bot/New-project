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

// Risoluzione deterministica per concetto: i curriculumTags di un esercizio
// indicano il concetto preciso (l'archetipo è ambiguo — "vincolo" copre mcm,
// numeri relativi, disequazioni…). Si scorre la lista dei tag e si prende il
// primo che ha una scheda, così ogni esercizio mostra SEMPRE la teoria giusta.
const TOPIC_BY_CURRICULUM_TAG: Partial<Record<string, string>> = {
  // Numeri e calcolo
  "calcolo ordinato": "numeri-naturali",
  operazioni: "numeri-naturali",
  "operazione inversa": "numeri-naturali",
  "controllo del calcolo": "numeri-naturali",
  "calcolo con vincolo": "numeri-naturali",
  "successioni numeriche": "numeri-naturali",
  regolarita: "numeri-naturali",
  "ordine delle operazioni": "potenze-espressioni",
  parentesi: "potenze-espressioni",
  "potenze di 2": "potenze-espressioni",
  "crescita esponenziale": "potenze-espressioni",
  "potenze di dieci": "potenze-espressioni",
  "notazione scientifica": "potenze-espressioni",
  "ordine di grandezza": "potenze-espressioni",
  divisibilita: "divisibilita",
  mcm: "divisibilita",
  mcd: "divisibilita",
  multipli: "divisibilita",
  divisori: "divisibilita",
  "numeri pari": "divisibilita",
  "ripartizione senza resto": "divisibilita",
  sincronizzazione: "divisibilita",
  frazioni: "frazioni",
  "frazioni successive": "frazioni",
  "frazione di una quantita": "frazioni",
  "complemento all intero": "frazioni",
  "quadrati perfetti": "radice-quadrata",
  "radice quadrata": "radice-quadrata",
  "numeri relativi": "numeri-relativi",
  "linea dei numeri": "numeri-relativi",
  // Rapporti, percentuali, proporzionalità
  rapporti: "rapporti-proporzioni",
  proporzioni: "rapporti-proporzioni",
  "quota per unita": "rapporti-proporzioni",
  scale: "rapporti-proporzioni",
  "scalare una ricetta": "rapporti-proporzioni",
  percentuali: "percentuali",
  "aumento percentuale": "percentuali",
  "percentuali inverse": "percentuali",
  "percentuale di una quantita": "percentuali",
  velocita: "proporzionalita",
  similitudine: "similitudine",
  "fattore di scala": "similitudine",
  // Misure
  "unita di misura": "misure",
  // Geometria (parola-forma specifica prima di "area", che è ambigua)
  rettangoli: "quadrilateri",
  rettangolo: "quadrilateri",
  quadrato: "quadrilateri",
  parallelogramma: "quadrilateri",
  rombo: "quadrilateri",
  trapezio: "quadrilateri",
  perimetro: "quadrilateri",
  "geometria composta": "quadrilateri",
  triangolo: "triangoli",
  triangoli: "triangoli",
  angoli: "angoli-rette",
  "teorema di pitagora": "pitagora",
  cerchio: "cerchio",
  volume: "solidi",
  // Piano cartesiano
  "piano cartesiano": "piano-cartesiano",
  "coordinate negative": "piano-cartesiano",
  // Relazioni e funzioni
  "funzioni lineari": "funzioni-retta",
  incognita: "equazioni",
  "equazioni di primo grado": "equazioni",
  "equazioni con frazioni": "equazioni",
  "sistemi lineari": "equazioni",
  disequazioni: "equazioni",
  // Dati e previsioni
  media: "statistica",
  mediana: "statistica",
  frequenze: "statistica",
  dati: "statistica",
  probabilita: "probabilita",
  "probabilita composta": "probabilita",
  // Concetti dei singoli prompt dei minigiochi matematica (chiavi già normalizzate:
  // niente accenti/apostrofi/virgole). Servono a risolvere la teoria PER PROMPT,
  // perché un minigioco (es. fraction-lab) alterna concetti diversi.
  "scomposizione di una somma": "numeri-naturali",
  "somma a tre addendi con controllo intermedio": "numeri-naturali",
  "trasformazione singola": "numeri-naturali",
  "due trasformazioni ordinate": "numeri-naturali",
  "sequenze numeriche": "numeri-naturali",
  "multipli e divisibilita": "divisibilita",
  "divisori e controllo del resto": "divisibilita",
  "frazione come operatore su una quantita": "frazioni",
  "equivalenza fra frazioni e percentuali": "percentuali",
  "numero decimale e percentuale equivalente": "percentuali",
  "rapporto unitario in un acquisto quotidiano": "rapporti-proporzioni",
  "scala grafica e proporzione diretta": "rapporti-proporzioni",
  "proporzionalita diretta in una ricetta": "proporzionalita",
  "proporzionalita inversa in un lavoro condiviso": "proporzionalita",
  "rapporto tra spazio tempo e velocita": "proporzionalita",
  "media aritmetica": "statistica",
  "mediana di una serie ordinata": "statistica",
  "moda come valore piu frequente": "statistica",
  "campo di variazione": "statistica",
  "probabilita classica in percentuale": "probabilita",
  "probabilita dell evento complementare": "probabilita",
  "area del triangolo come meta del rettangolo": "triangoli",
  "perimetro come somma dei lati": "quadrilateri",
  "area del rettangolo": "quadrilateri",
  "area del cerchio con pi greco approssimato": "cerchio",
  "circonferenza con pi greco approssimato": "cerchio",
  "teorema di pitagora in un triangolo rettangolo": "pitagora",
  "volume del parallelepipedo": "solidi",
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

  /** Topic del singolo prompt di un minigioco, dal suo `concept`. */
  topicForMinigameConcept(concept: string | undefined): TheoryTopic | undefined {
    if (!concept) return undefined;
    return this.topicForCurriculumTags([concept]);
  }

  /** Topic esplicito dai curriculumTags dell'esercizio (il segnale più preciso). */
  topicForCurriculumTags(tags: string[] | undefined): TheoryTopic | undefined {
    for (const tag of tags ?? []) {
      const mapped = TOPIC_BY_CURRICULUM_TAG[normalize(tag)];
      if (mapped) {
        const topic = this.topicById(mapped);
        if (topic) return topic;
      }
    }
    return undefined;
  }

  /** Direct/curriculum-tag targets that no longer resolve (must stay empty). */
  brokenCurriculumTargets(): string[] {
    return Array.from(new Set(Object.values(TOPIC_BY_CURRICULUM_TAG)))
      .filter((id): id is string => typeof id === "string" && !this.topicById(id));
  }

  topicForPuzzle(kind: ProceduralPuzzleKind, puzzle?: PuzzleLike): TheoryTopic | undefined {
    // 1) curriculumTags: il concetto esatto dell'esercizio (batte l'archetipo,
    // che è ambiguo). Garantisce che la scheda mostrata sia quella giusta.
    const byTag = this.topicForCurriculumTags(puzzle?.curriculumTags);
    if (byTag) return byTag;

    // 2) mappa diretta per archetipo/guasto/tipo-sfida (materie non-matematica).
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
