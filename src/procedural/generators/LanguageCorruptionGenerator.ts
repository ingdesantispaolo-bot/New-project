import { languageTemplates } from "../../data/procedural/languageTemplates";
import type { LanguageTemplate } from "../../data/procedural/languageTemplates";
import type {
  GeneratedLanguageMinigame,
  GeneratedLanguagePuzzle,
  LanguageMinigamePrompt,
  LanguageMinigameTile,
  LanguageMinigameType,
} from "../ProceduralTypes";
import type { Random } from "../Random";

type AgreementItem = {
  context: string;
  correct: string;
  distractors: string[];
  explanation: string;
  concept: string;
};

/** Subjects with their singular/plural article+noun and grammatical gender. */
const AGREEMENT_SUBJECTS = [
  { sg: "Il sensore", pl: "I sensori", gender: "m" },
  { sg: "La valvola", pl: "Le valvole", gender: "f" },
  { sg: "Il registro", pl: "I registri", gender: "m" },
  { sg: "La mappa", pl: "Le mappe", gender: "f" },
  { sg: "Il modulo", pl: "I moduli", gender: "m" },
  { sg: "La pompa", pl: "Le pompe", gender: "f" },
  { sg: "Il filtro", pl: "I filtri", gender: "m" },
  { sg: "La batteria", pl: "Le batterie", gender: "f" },
  { sg: "Il pannello", pl: "I pannelli", gender: "m" },
  { sg: "La sonda", pl: "Le sonde", gender: "f" },
] as const;

/** Regular -ato/-ito adjective roots (4 forms by adding o/a/i/e). */
const AGREEMENT_ADJ_ROOTS = [
  "calibrat", "pront", "salvat", "attivat", "isolat", "collegat",
  "aggiornat", "bloccat", "verificat", "configurat", "alimentat", "spent",
] as const;

/** Verbs with the forms needed to build reliable agreement distractors. */
const AGREEMENT_VERBS = [
  { sg3: "registra", pl3: "registrano", p1pl: "registriamo", part: "registrato", object: "il dato" },
  { sg3: "controlla", pl3: "controllano", p1pl: "controlliamo", part: "controllato", object: "il segnale" },
  { sg3: "apre", pl3: "aprono", p1pl: "apriamo", part: "aperto", object: "la porta" },
  { sg3: "invia", pl3: "inviano", p1pl: "inviamo", part: "inviato", object: "il rapporto" },
  { sg3: "blocca", pl3: "bloccano", p1pl: "blocchiamo", part: "bloccato", object: "il sistema" },
  { sg3: "conferma", pl3: "confermano", p1pl: "confermiamo", part: "confermato", object: "la misura" },
  { sg3: "salva", pl3: "salvano", p1pl: "salviamo", part: "salvato", object: "il log" },
  { sg3: "aggiorna", pl3: "aggiornano", p1pl: "aggiorniamo", part: "aggiornato", object: "la mappa" },
] as const;

type VerbMasteryItem = {
  context: string;
  correct: string;
  distractors: string[];
  explanation: string;
  concept: string;
  targetLabel: string;
  typed?: boolean;
  accepted?: string[];
};

function adjForm(root: string, gender: "m" | "f", plural: boolean): string {
  return root + (gender === "m" ? (plural ? "i" : "o") : (plural ? "e" : "a"));
}

/** Everyday subjects + adjectives for the lower levels (lighter reading load). */
const EVERYDAY_SUBJECTS = [
  { sg: "Il gatto", pl: "I gatti", gender: "m" },
  { sg: "La porta", pl: "Le porte", gender: "f" },
  { sg: "Il libro", pl: "I libri", gender: "m" },
  { sg: "La lampada", pl: "Le lampade", gender: "f" },
  { sg: "Il cane", pl: "I cani", gender: "m" },
  { sg: "La finestra", pl: "Le finestre", gender: "f" },
  { sg: "Il bicchiere", pl: "I bicchieri", gender: "m" },
  { sg: "La sedia", pl: "Le sedie", gender: "f" },
] as const;

const EVERYDAY_ADJ_ROOTS = ["pront", "apert", "chius", "pulit", "nuov", "acces", "spent", "rott"] as const;

type SubjectPool = readonly { sg: string; pl: string; gender: "m" | "f" }[];

/** Pattern B — "essere + aggettivo": exercises number AND gender agreement. */
function parametricEssereAdjItem(random: Random, subjects: SubjectPool, roots: readonly string[], everyday: boolean): AgreementItem {
  const subject = random.pick(subjects);
  const root = random.pick(roots);
  const plural = random.bool();
  const subjForm = plural ? subject.pl : subject.sg;
  const adjSingular = adjForm(root, subject.gender, false);
  const adjPlural = adjForm(root, subject.gender, true);
  const correct = `${plural ? "sono" : "è"} ${plural ? adjPlural : adjSingular}`;
  const distractors = [`è ${adjSingular}`, `è ${adjPlural}`, `sono ${adjSingular}`, `sono ${adjPlural}`]
    .filter((option) => option !== correct);
  return {
    context: `${subjForm} ___ ${everyday ? "in questo momento." : "secondo il registro."}`,
    correct,
    distractors,
    explanation: `Il soggetto è ${plural ? "plurale" : "singolare"} ${subject.gender === "m" ? "maschile" : "femminile"}: ${subjForm.toLowerCase()} ${correct}.`,
    concept: "accordo di numero e genere",
  };
}

/** Pattern A — "soggetto + verbo": exercises subject-verb number agreement. */
function parametricSubjectVerbItem(random: Random, subjects: SubjectPool): AgreementItem {
  const subject = random.pick(subjects);
  const verb = random.pick(AGREEMENT_VERBS);
  const plural = random.bool();
  const subjForm = plural ? subject.pl : subject.sg;
  const correct = plural ? verb.pl3 : verb.sg3;
  const distractors = [plural ? verb.sg3 : verb.pl3, verb.p1pl, verb.part];
  return {
    context: `${subjForm} ___ ${verb.object}.`,
    correct,
    distractors,
    explanation: `Il soggetto ${subjForm.toLowerCase()} è ${plural ? "plurale: terza persona plurale" : "singolare: terza persona singolare"} (${correct}).`,
    concept: "accordo soggetto-verbo",
  };
}

/**
 * Calibrates the lexical register by level: everyday vocabulary at the lower
 * levels (lighter reading load), technical contexts higher up.
 */
function parametricAgreementItem(random: Random, level: number): AgreementItem {
  if (level <= 3) {
    return parametricEssereAdjItem(random, EVERYDAY_SUBJECTS, EVERYDAY_ADJ_ROOTS, true);
  }
  return random.bool()
    ? parametricEssereAdjItem(random, AGREEMENT_SUBJECTS, AGREEMENT_ADJ_ROOTS, false)
    : parametricSubjectVerbItem(random, AGREEMENT_SUBJECTS);
}

/** Canonical form used to compare a typed answer against the accepted one. */
export function normalizeTypedAnswer(text: string): string {
  return text
    .trim()
    .toLocaleLowerCase("it")
    .replace(/\s+/g, " ")
    .replace(/[.,;:!?]+$/u, "")
    .trim();
}

export class LanguageCorruptionGenerator {
  generate(random: Random, difficultyLevel = 1, preferredTemplateIds: string[] = []): GeneratedLanguagePuzzle {
    const eligibleTemplates = languageTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const floor = Math.max(1, difficultyLevel - 2);
    const focusedTemplates = eligibleTemplates.filter((template) => (template.minDifficulty ?? 1) >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates;
    const preferredPool = preferredTemplateIds.length > 0
      ? (eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates).filter((template) => preferredTemplateIds.includes(template.id))
      : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const options = random.shuffle([template.repaired, ...template.distractors]);
    return this.buildPuzzle(template, options, difficultyLevel);
  }

  generateMinigame(
    random: Random,
    difficultyLevel = 1,
    preferredTypes: LanguageMinigameType[] = [],
  ): GeneratedLanguagePuzzle {
    const level = Math.max(1, Math.min(8, difficultyLevel));
    const type = preferredTypes.length > 0
      ? random.pick(preferredTypes)
      : random.pick<LanguageMinigameType>(["agreement-sprint", "connector-route", "intruder-hunt", "word-order", "lexicon-lab", "verb-mastery"]);
    const minigame = this.buildMinigame(random.fork(type), level, type);
    const first = minigame.prompts[0];
    const optionFeedback: Record<string, string> = {};
    let options: string[];
    let repaired: string;
    if (type === "word-order") {
      // Word-order tiles are single words, so derive the repair-tab choices from
      // the full sentence plus plausible wrong orderings instead.
      const sentence = first.solutionLabels.join(" ");
      const distractors = this.wordOrderSentenceDistractors(random.fork("wo-base"), first.solutionLabels);
      options = random.shuffle([sentence, ...distractors]);
      repaired = sentence;
      options.forEach((option) => {
        optionFeedback[option] = option === sentence
          ? "Ordine corretto: soggetto, verbo e complementi al posto giusto."
          : "Ordine errato: con le parole così il sistema non esegue il comando.";
      });
    } else {
      options = first.tiles.map((tile) => tile.label);
      repaired = first.solutionLabels[0];
      first.tiles.forEach((tile) => {
        optionFeedback[tile.label] = tile.feedback;
      });
    }
    return {
      id: `language-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      corrupted: first.context,
      repaired,
      options,
      diagnosticSteps: [
        `Leggi il compito: ${first.targetLabel}.`,
        "Non scegliere la frase che suona meglio: controlla la regola linguistica richiesta.",
        first.explanation,
      ],
      hints: [
        "Prima individua il soggetto o il nesso logico, poi guarda le opzioni.",
        "Scarta i distrattori che cambiano significato, genere, numero o rapporto causa-effetto.",
        "Se due risposte sembrano possibili, rileggi l'obiettivo operativo della console.",
      ],
      competencies: minigame.competencies,
      difficultyLabel: `Livello ${level} - sprint linguistico`,
      conceptTags: this.languageMinigameConcepts(type),
      learningPurpose: this.languageMinigamePurpose(type),
      repairGoal: "Stabilizzare molti micro-messaggi in 60 secondi senza provare a caso.",
      method: this.languageMinigameMethod(type),
      optionFeedback,
      minigame,
    };
  }

  private buildPuzzle(template: LanguageTemplate, options: string[], difficultyLevel: number): GeneratedLanguagePuzzle {
    const conceptTags = template.conceptTags ?? this.defaultConceptTags(template.id);
    const optionFeedback = this.buildOptionFeedback(template);
    return {
      id: `language-${template.id}`,
      title: template.title,
      corrupted: template.corrupted,
      repaired: template.repaired,
      options,
      diagnosticSteps: template.diagnosticSteps,
      hints: template.hints,
      competencies: this.competenciesFor(template.id),
      difficultyLabel: `Livello ${Math.max(1, Math.min(8, difficultyLevel))} - ${this.levelName(difficultyLevel)}`,
      conceptTags,
      learningPurpose: template.learningPurpose ?? `Allena ${conceptTags.join(", ")} dentro un messaggio tecnico da rendere eseguibile.`,
      repairGoal: template.repairGoal ?? "Trasforma il log corrotto in una frase chiara, corretta e utile al sistema.",
      method: template.method ?? "Trova soggetto e azione, controlla accordi e connettivi, poi verifica che il significato tecnico non cambi.",
      optionFeedback,
    };
  }

  fallback(random?: Random, difficultyLevel = 1): GeneratedLanguagePuzzle {
    const eligible = languageTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const template = random?.pick(eligible.length > 0 ? eligible : languageTemplates) ?? languageTemplates[0];
    const options = random?.shuffle([template.repaired, ...template.distractors]) ?? [template.repaired, ...template.distractors];
    return {
      ...this.buildPuzzle(template, options, difficultyLevel),
      id: `language-fallback-${template.id}-${random?.integer(1000, 9999) ?? 0}`,
    };
  }

  private buildMinigame(random: Random, level: number, type: LanguageMinigameType): GeneratedLanguageMinigame {
    const promptCount = 18 + level;
    const prompts: LanguageMinigamePrompt[] = [];
    const usedSignatures = new Set<string>();
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniqueMinigamePrompt(random, level, type, index, usedSignatures);
      prompts.push(prompt);
      usedSignatures.add(prompt.signature);
    }
    const titles: Record<LanguageMinigameType, string> = {
      "agreement-sprint": "Minigioco italiano: Concordanze lampo",
      "connector-route": "Minigioco italiano: Rotte dei connettivi",
      "intruder-hunt": "Minigioco italiano: Intruso nel log",
      "word-order": "Minigioco italiano: Ricomponi il comando",
      "lexicon-lab": "Minigioco italiano: Lessico preciso",
      "verb-mastery": "Minigioco italiano: Modi e tempi dei verbi",
    };
    const instructions: Record<LanguageMinigameType, string> = {
      "agreement-sprint": "clicca la forma che rende la frase corretta per genere, numero e verbo.",
      "connector-route": "clicca il connettivo che mantiene il rapporto logico tra le informazioni.",
      "intruder-hunt": "clicca il dettaglio inutile o contraddittorio rispetto allo scopo del log.",
      "word-order": "tocca le parole nell'ordine giusto per ricomporre il comando eseguibile.",
      "lexicon-lab": "clicca la parola più precisa per il contesto: tecnico, critico, narrativo o operativo.",
      "verb-mastery": "riconosci modo e tempo, oppure scrivi la forma verbale corretta in contesto.",
    };
    // Comprehension-heavy sprints (find the intruder, choose the precise word)
    // run in a calmer, longer "reflective" mode: more reading time, no speed
    // pressure — friendlier for slower readers / DSA.
    const reflective = type === "intruder-hunt" || type === "lexicon-lab";
    return {
      type,
      title: titles[type],
      durationMs: reflective ? 110_000 : 60_000,
      reflective,
      instructions: instructions[type],
      scoringRule: reflective
        ? "Modalità riflessiva: niente fretta. Leggi con calma, individua la regola, poi scegli."
        : "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. La velocità vale solo se resta precisa.",
      prompts,
      competencies: Array.from(new Set([
        "italiano.comprensione",
        "italiano.grammatica",
        "pensieroCritico",
        ...(type === "agreement-sprint" ? ["italiano.coesione"] : []),
        ...(type === "connector-route" ? ["italiano.coesione", "italiano.argomentazione"] : []),
        ...(type === "intruder-hunt" ? ["italiano.lessico", "italiano.scritturaBreve"] : []),
        ...(type === "word-order" ? ["italiano.coesione", "italiano.scritturaBreve"] : []),
        ...(type === "lexicon-lab" ? ["italiano.lessico", "italiano.scritturaBreve", "italiano.argomentazione"] : []),
        ...(type === "verb-mastery" ? ["italiano.verbi", "italiano.coesione", "italiano.scritturaBreve"] : []),
      ])),
    };
  }

  private uniqueMinigamePrompt(
    random: Random,
    level: number,
    type: LanguageMinigameType,
    index: number,
    usedSignatures: Set<string>,
  ): LanguageMinigamePrompt {
    let first: LanguageMinigamePrompt | undefined;
    for (let attempt = 0; attempt < 36; attempt += 1) {
      const prompt = this.buildMinigamePrompt(random, level, type, index + attempt);
      first ??= prompt;
      if (!usedSignatures.has(prompt.signature)) {
        return prompt;
      }
    }
    return first ?? this.buildMinigamePrompt(random, level, type, index + 99);
  }

  private buildMinigamePrompt(random: Random, level: number, type: LanguageMinigameType, index: number): LanguageMinigamePrompt {
    if (type === "agreement-sprint") return this.buildAgreementPrompt(random, level, index);
    if (type === "connector-route") return this.buildConnectorPrompt(random, level, index);
    if (type === "word-order") return this.buildWordOrderPrompt(random, level, index);
    if (type === "lexicon-lab") return this.buildLexiconPrompt(random, level, index);
    if (type === "verb-mastery") return this.buildVerbMasteryPrompt(random, level, index);
    return this.buildIntruderPrompt(random, level, index);
  }

  private buildAgreementPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = [
      {
        context: "I sensori della serra ___ prima dell'apertura.",
        correct: "sono calibrati",
        distractors: ["è calibrato", "sono calibrato", "è calibrati"],
        explanation: "Il soggetto è plurale maschile: i sensori sono calibrati.",
        concept: "accordo soggetto-verbo-aggettivo",
      },
      {
        context: "La valvola e il filtro ___ lo stesso registro.",
        correct: "condividono",
        distractors: ["condivide", "condivisa", "condividono stato"],
        explanation: "Due elementi formano un soggetto plurale: condividono.",
        concept: "soggetto composto",
      },
      {
        context: "L'energia residua non ___ abbastanza stabile.",
        correct: "è",
        distractors: ["sono", "ha", "anno"],
        explanation: "Energia è singolare: è stabile. Ha/anno cambiano funzione o ortografia.",
        concept: "verbo essere e omofoni",
      },
      {
        context: "Le istruzioni, se lette in ordine, ___ il percorso.",
        correct: "chiariscono",
        distractors: ["chiarisce", "chiarito", "chiariscono la"],
        explanation: "Il soggetto grammaticale è le istruzioni: terza plurale.",
        concept: "inciso tra soggetto e verbo",
      },
      {
        context: "Il dato che manca nei registri ___ la diagnosi incompleta.",
        correct: "rende",
        distractors: ["rendono", "renda", "rendono la"],
        explanation: "Il nucleo del soggetto è dato, non registri: il dato rende.",
        concept: "soggetto con relativa",
      },
      {
        context: "Nessuna delle porte laterali ___ ancora autorizzata.",
        correct: "è",
        distractors: ["sono", "hanno", "vengono"],
        explanation: "Nessuna è singolare: nessuna porta è autorizzata.",
        concept: "quantificatori singolari",
      },
      {
        context: "Il registro e la mappa ___ nella stessa cartella.",
        correct: "sono salvati",
        distractors: ["è salvato", "sono salvato", "è salvati"],
        explanation: "Registro e mappa formano un soggetto plurale: sono salvati.",
        concept: "accordo con soggetto composto",
      },
      {
        context: "Questa serie di avvisi ___ un controllo immediato.",
        correct: "richiede",
        distractors: ["richiedono", "richiesta", "richieda"],
        explanation: "Il nucleo del soggetto è serie, singolare: questa serie richiede.",
        concept: "nucleo del soggetto",
      },
      {
        context: "Il diario delle prove ___ tre fonti e una conclusione prudente.",
        correct: "confronta",
        distractors: ["confrontano", "confrontato", "confronta le"],
        explanation: "Il soggetto è diario, singolare: il diario confronta.",
        concept: "soggetto singolare con complemento plurale",
      },
      {
        context: "Le ipotesi senza prove non ___ il blocco del sistema.",
        correct: "spiegano",
        distractors: ["spiega", "spiegato", "spieghiamo"],
        explanation: "Il soggetto è ipotesi, plurale: spiegano.",
        concept: "accordo soggetto-verbo",
      },
      {
        context: "Una traccia e due misure ___ per aprire il rapporto.",
        correct: "bastano",
        distractors: ["basta", "bastato", "bastano la"],
        explanation: "Il soggetto contiene più elementi coordinati: una traccia e due misure bastano.",
        concept: "soggetto composto misto",
      },
    ];
    const advanced = [
      {
        context: "Il gruppo di segnali che arrivano dal nucleo ___ un'anomalia.",
        correct: "indica",
        distractors: ["indicano", "indichi", "indicate"],
        explanation: "Il soggetto è il gruppo, singolare; che arrivano è una relativa interna.",
        concept: "nucleo del soggetto",
      },
      {
        context: "Se la pressione e la temperatura non ___, il log resta in attesa.",
        correct: "coincidono",
        distractors: ["coincide", "coincisa", "coincidono il"],
        explanation: "Pressione e temperatura sono due elementi: coincidono.",
        concept: "accordo in subordinata condizionale",
      },
      {
        context: "La maggior parte dei moduli ___ pronta, ma alcuni sensori restano isolati.",
        correct: "è",
        distractors: ["sono", "hanno", "vengono"],
        explanation: "La maggior parte è un'espressione singolare: è pronta.",
        concept: "accordo con nome collettivo",
      },
    ];
    // Mostly parametric (hundreds of reliable variants → not memorisable),
    // mixed with the authored pool that covers special cases the parametric
    // generator cannot (collective nouns, quantifiers, relative clauses).
    const item: AgreementItem = random.bool(0.7)
      ? parametricAgreementItem(random, level)
      : random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Non regge: ${item.explanation}`)),
    ]);
    // ~40% of concordanze become a production exercise: the player types the
    // correct form instead of picking it (exercises italiano.scritturaBreve and
    // diversifies the interaction). Tiles stay as a valid fallback/wrapper.
    const typed = random.bool(0.4);
    return {
      id: `agreement-${index}`,
      type: "agreement-sprint",
      prompt: typed
        ? "Scrivi la forma grammaticale corretta che completa il log."
        : "Completa il log con la forma grammaticale che il sistema può eseguire.",
      context: item.context,
      targetLabel: typed ? "Scrivi la concordanza" : "Concordanza corretta",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `agreement-${item.context}-${item.correct}`,
      inputMode: typed ? "typed" : "tiles",
      acceptedAnswers: typed ? [normalizeTypedAnswer(item.correct)] : undefined,
    };
  }

  private buildConnectorPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = [
      {
        context: "Il tester segnala corto, ___ il pannello blocca l'accensione.",
        correct: "quindi",
        distractors: ["però", "mentre", "sebbene"],
        explanation: "Il secondo fatto è una conseguenza del primo: quindi.",
        concept: "causa-conseguenza",
      },
      {
        context: "Il LED è orientato bene, ___ resta spento perché manca la resistenza.",
        correct: "ma",
        distractors: ["infatti", "dunque", "quando"],
        explanation: "C'è un contrasto tra una parte corretta e il problema ancora presente.",
        concept: "contrasto",
      },
      {
        context: "Controlla il registro ___ aprire la porta.",
        correct: "prima di",
        distractors: ["dopo che", "nonostante", "perciò"],
        explanation: "Serve un vincolo temporale: il controllo avviene prima dell'apertura.",
        concept: "ordine temporale",
      },
      {
        context: "La console accetta il comando ___ il sensore conferma stabilità.",
        correct: "solo se",
        distractors: ["anche se", "mentre", "quindi"],
        explanation: "Solo se introduce una condizione necessaria.",
        concept: "condizione necessaria",
      },
      {
        context: "Il log cita molte luci decorative, ___ una sola indica il guasto.",
        correct: "tuttavia",
        distractors: ["perciò", "affinché", "poiché"],
        explanation: "Tuttavia segnala contrasto tra molti dettagli e il dato utile.",
        concept: "opposizione argomentativa",
      },
      {
        context: "La porta resta bloccata ___ il codice inserito non coincide con il registro.",
        correct: "perché",
        distractors: ["quindi", "mentre", "sebbene"],
        explanation: "Perché introduce la causa del blocco.",
        concept: "causa esplicita",
      },
      {
        context: "Il robot invia il segnale, ___ il nucleo registra l'arrivo.",
        correct: "poi",
        distractors: ["benché", "affinché", "perciò"],
        explanation: "Poi mantiene l'ordine temporale: prima il segnale, dopo la registrazione.",
        concept: "sequenza temporale",
      },
    ];
    const advanced = [
      {
        context: "Il robot non deve partire ___ la base non ha confermato la rotta.",
        correct: "finché",
        distractors: ["affinché", "poiché", "benché"],
        explanation: "Finché indica il limite temporale negativo: non partire fino alla conferma.",
        concept: "limite temporale",
      },
      {
        context: "Annota la fonte ___ il rapporto sia verificabile.",
        correct: "affinché",
        distractors: ["benché", "invece", "dunque"],
        explanation: "Affinché introduce lo scopo: rendere il rapporto verificabile.",
        concept: "finalità",
      },
      {
        context: "Il pannello non si riavvia ___ il tecnico non isola il corto.",
        correct: "finché",
        distractors: ["affinché", "inoltre", "tuttavia"],
        explanation: "Finché indica una condizione temporale: non avviene prima dell'isolamento.",
        concept: "vincolo temporale",
      },
      {
        context: "Il rapporto cita un'ipotesi, ___ non autorizza ancora lo spegnimento.",
        correct: "perciò",
        distractors: ["sebbene", "mentre", "affinché"],
        explanation: "Perciò introduce la conseguenza: l'ipotesi non basta per agire.",
        concept: "conseguenza argomentativa",
      },
      {
        context: "La misura è coerente, ___ manca una seconda fonte di controllo.",
        correct: "tuttavia",
        distractors: ["quindi", "perché", "affinché"],
        explanation: "Tuttavia segnala contrasto tra dato positivo e prova ancora mancante.",
        concept: "contrasto tra prova e limite",
      },
      {
        context: "Scrivi il passaggio in modo chiaro ___ un compagno possa ripeterlo.",
        correct: "affinché",
        distractors: ["però", "dunque", "finché"],
        explanation: "Affinché introduce lo scopo: permettere a un compagno di ripetere il passaggio.",
        concept: "scopo comunicativo",
      },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Connettivo non coerente: ${item.explanation}`)),
    ]);
    return {
      id: `connector-${index}`,
      type: "connector-route",
      prompt: "Scegli il connettivo che mantiene il rapporto logico tra le due parti.",
      context: item.context,
      targetLabel: "Nesso logico",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `connector-${item.context}-${item.correct}`,
    };
  }

  private buildIntruderPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = [
      {
        context: "Obiettivo: capire perché la porta resta chiusa.",
        useful: ["la serratura non riceve corrente", "il codice è stato accettato", "il circuito è ancora aperto"],
        intruder: "la cornice della porta è blu",
        explanation: "Il colore della cornice non spiega il blocco della porta.",
        concept: "informazioni utili e rumore",
      },
      {
        context: "Obiettivo: scrivere un rapporto sulle cause del guasto.",
        useful: ["il sensore B non risponde", "il log indica soglia superata", "la valvola si apre in ritardo"],
        intruder: "il banco degli attrezzi è vicino alla finestra",
        explanation: "La posizione del banco non è una causa del guasto.",
        concept: "causa e dettaglio irrilevante",
      },
      {
        context: "Obiettivo: ricostruire l'ordine degli eventi.",
        useful: ["prima il robot entra in base", "poi la valvola si apre", "infine il registro viene salvato"],
        intruder: "il robot ha una scocca verde",
        explanation: "Il colore del robot non aiuta a ricostruire la sequenza.",
        concept: "sequenza temporale",
      },
      {
        context: "Obiettivo: verificare se una fonte è affidabile.",
        useful: ["il dato è registrato dal tester", "la misura compare due volte", "l'orario del log è coerente"],
        intruder: "il messaggio usa un font elegante",
        explanation: "La grafica del font non dimostra affidabilità della fonte.",
        concept: "fonte e prova",
      },
      {
        context: "Obiettivo: capire quale istruzione eseguire subito.",
        useful: ["il comando dice prima controlla la valvola", "il timer scade tra un minuto", "il pannello segnala rischio basso"],
        intruder: "la valvola è disegnata con un'icona grande",
        explanation: "La dimensione dell'icona non decide quale azione eseguire.",
        concept: "priorità operativa",
      },
      {
        context: "Obiettivo: riscrivere un log chiaro per un compagno.",
        useful: ["indica il componente guasto", "spiega l'effetto osservato", "propone il prossimo controllo"],
        intruder: "usa tre aggettivi decorativi sulla stanza",
        explanation: "Gli aggettivi decorativi non aiutano un compagno a riparare il sistema.",
        concept: "chiarezza comunicativa",
      },
      {
        context: "Obiettivo: scegliere una conclusione proporzionata alle prove.",
        useful: ["due misure indicano lo stesso valore", "una fonte resta non verificata", "il rapporto segnala un dubbio"],
        intruder: "il terminale ha un bordo luminoso",
        explanation: "Il bordo luminoso non aumenta né riduce la forza delle prove.",
        concept: "conclusione proporzionata",
      },
      {
        context: "Obiettivo: capire quale frase guida davvero l'azione.",
        useful: ["prima scollega la batteria", "poi misura la continuità", "non toccare il ramo caldo"],
        intruder: "il messaggio è scritto in stampatello",
        explanation: "Lo stile grafico non modifica l'ordine operativo.",
        concept: "istruzione e aspetto grafico",
      },
    ];
    const advanced = [
      {
        context: "Obiettivo: distinguere tesi e prova nel rapporto.",
        useful: ["tesi: il blocco dipende dal sensore", "prova: il tester non legge continuità", "prova: la soglia resta fuori range"],
        intruder: "opinione: il sensore sembra antipatico",
        explanation: "Un'opinione non verificabile non è una prova.",
        concept: "tesi, prova, opinione",
      },
      {
        context: "Obiettivo: preparare una sintesi breve e precisa.",
        useful: ["causa principale: corto sul ramo B", "effetto: porta non certificata", "azione: isolare il corto"],
        intruder: "descrizione lunga delle luci del corridoio",
        explanation: "Una sintesi elimina dettagli decorativi che non cambiano causa, effetto o azione.",
        concept: "sintesi e pertinenza",
      },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      ...item.useful.map((label, choiceIndex) => this.languageTile(index + choiceIndex, label, false, "Dato utile: non eliminarlo, serve allo scopo del log.")),
      this.languageTile(index + 9, item.intruder, true, `Intruso corretto: ${item.explanation}`),
    ]);
    return {
      id: `intruder-${index}`,
      type: "intruder-hunt",
      prompt: "Clicca il dettaglio da eliminare: è inutile o non verificabile per l'obiettivo.",
      context: item.context,
      targetLabel: "Intruso testuale",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.intruder],
      explanation: item.explanation,
      concept: item.concept,
      signature: `intruder-${item.context}-${item.intruder}`,
    };
  }

  private buildLexiconPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = [
      {
        context: "Il tester non dimostra ancora il guasto: mostra solo una ___ da verificare.",
        correct: "ipotesi",
        distractors: ["certezza", "decorazione", "scorciatoia"],
        explanation: "Un dato parziale genera un'ipotesi, non una certezza.",
        concept: "ipotesi e prova",
      },
      {
        context: "Per rendere più preciso il sensore, il tecnico deve ___ la lettura.",
        correct: "calibrare",
        distractors: ["abbellire", "consumare", "raccontare"],
        explanation: "Calibrare significa regolare una misura; gli altri verbi non sono tecnici.",
        concept: "verbo tecnico",
      },
      {
        context: "Nel rapporto finale elimina i dettagli decorativi e conserva la ___.",
        correct: "sintesi",
        distractors: ["cornice", "voce", "distrazione"],
        explanation: "La sintesi conserva le informazioni essenziali.",
        concept: "sintesi informativa",
      },
      {
        context: "Una notizia senza origine controllabile non è una fonte: è una ___.",
        correct: "voce",
        distractors: ["prova", "misura", "verifica"],
        explanation: "Voce indica informazione non verificata; prova e verifica richiedono controllo.",
        concept: "fonte e attendibilità",
      },
      {
        context: "Se due dati si confermano a vicenda, la conclusione diventa più ___.",
        correct: "affidabile",
        distractors: ["vistosa", "frettolosa", "ornamentale"],
        explanation: "Affidabile riguarda la forza della conclusione, non l'aspetto.",
        concept: "lessico argomentativo",
      },
      {
        context: "Il messaggio non deve essere lungo: deve essere ___ per guidare l'azione.",
        correct: "chiaro",
        distractors: ["misterioso", "decorativo", "contraddittorio"],
        explanation: "Un comando operativo deve essere chiaro.",
        concept: "chiarezza comunicativa",
      },
      {
        context: "Quando un indizio non basta, serve un secondo ___ prima di decidere.",
        correct: "controllo",
        distractors: ["colore", "rumore", "titolo"],
        explanation: "Un controllo aggiunge verifica; colore, rumore e titolo non certificano.",
        concept: "verifica",
      },
      {
        context: "La frase 'forse il modulo è guasto' esprime un dubbio, non una ___.",
        correct: "diagnosi",
        distractors: ["domanda", "pausa", "immagine"],
        explanation: "La diagnosi richiede prove; forse segnala incertezza.",
        concept: "diagnosi e incertezza",
      },
    ];
    const advanced = [
      {
        context: "Il rapporto è convincente solo se distingue ___, prove e conclusione.",
        correct: "tesi",
        distractors: ["cornici", "rumori", "icone"],
        explanation: "La tesi è l'idea da sostenere con prove.",
        concept: "argomentazione",
      },
      {
        context: "Se il testo usa parole troppo generiche, il comando perde ___.",
        correct: "precisione",
        distractors: ["decorazione", "fretta", "colore"],
        explanation: "La precisione lessicale riduce ambiguità operative.",
        concept: "precisione lessicale",
      },
      {
        context: "Una conclusione corretta ma troppo forte rispetto ai dati è ___.",
        correct: "sproporzionata",
        distractors: ["verificata", "neutra", "leggibile"],
        explanation: "Sproporzionata significa non adeguata alla quantità di prove disponibili.",
        concept: "conclusione proporzionata",
      },
      {
        context: "Nel registro formale evita 'aggiusta': scegli un verbo più tecnico come ___.",
        correct: "ripristina",
        distractors: ["gioca", "colora", "indovina"],
        explanation: "Ripristina è adatto a un sistema tecnico; aggiusta è più generico.",
        concept: "registro formale",
      },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Lessico non adatto: ${item.explanation}`)),
    ]);
    return {
      id: `lexicon-${index}`,
      type: "lexicon-lab",
      prompt: "Scegli la parola più precisa per rendere il messaggio chiaro e utile.",
      context: item.context,
      targetLabel: "Lessico preciso",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `lexicon-${item.context}-${item.correct}`,
    };
  }

  private buildVerbMasteryPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const base: VerbMasteryItem[] = [
      {
        context: "Ieri Eli ___ il registro prima di uscire.",
        correct: "ha salvato",
        distractors: ["salva", "salverà", "salvava"],
        explanation: "Ieri indica un'azione conclusa nel passato: passato prossimo, indicativo.",
        concept: "indicativo passato prossimo",
        targetLabel: "Scegli il tempo adatto",
      },
      {
        context: "Ogni mattina il sensore ___ la temperatura.",
        correct: "misura",
        distractors: ["misurò", "misurerebbe", "misurando"],
        explanation: "Ogni mattina segnala un'azione abituale: presente indicativo.",
        concept: "indicativo presente",
        targetLabel: "Azione abituale",
      },
      {
        context: "Mentre il robot avanzava, la porta ___.",
        correct: "si apriva",
        distractors: ["si aprì", "si aprirà", "si apra"],
        explanation: "Mentre introduce un'azione in corso nel passato: imperfetto indicativo.",
        concept: "indicativo imperfetto",
        targetLabel: "Azione durativa nel passato",
      },
      {
        context: "Domani la squadra ___ il circuito.",
        correct: "controllerà",
        distractors: ["controllò", "controllava", "controlli"],
        explanation: "Domani indica futuro: futuro semplice indicativo.",
        concept: "indicativo futuro semplice",
        targetLabel: "Futuro",
      },
      {
        context: "La frase 'noi avevamo verificato i dati' usa quale modo e tempo?",
        correct: "indicativo trapassato prossimo",
        distractors: ["congiuntivo passato", "condizionale presente", "indicativo passato remoto"],
        explanation: "Avevamo + participio passato forma il trapassato prossimo dell'indicativo.",
        concept: "riconoscimento tempi composti",
        targetLabel: "Riconosci modo e tempo",
      },
      {
        context: "Scrivi la forma corretta: se il segnale è stabile, noi ___ la porta. (aprire, presente)",
        correct: "apriamo",
        distractors: ["apre", "apriremo", "apriremmo"],
        explanation: "Noi + presente indicativo del verbo aprire: apriamo.",
        concept: "coniugazione presente",
        targetLabel: "Scrivi la forma verbale",
        typed: true,
      },
    ];
    const intermediate: VerbMasteryItem[] = [
      {
        context: "Credo che il terminale ___ ancora acceso.",
        correct: "sia",
        distractors: ["è", "sarà", "sarebbe"],
        explanation: "Dopo credo che, quando esprimi dubbio o valutazione, serve il congiuntivo: sia.",
        concept: "congiuntivo presente",
        targetLabel: "Congiuntivo richiesto",
      },
      {
        context: "Se avessi più tempo, ___ meglio il rapporto.",
        correct: "controllerei",
        distractors: ["controllo", "controllai", "controllassi"],
        explanation: "Con se + congiuntivo imperfetto, la conseguenza usa il condizionale presente.",
        concept: "periodo ipotetico possibile/irreale",
        targetLabel: "Condizionale",
      },
      {
        context: "Prima che la porta si chiuda, ___ il codice.",
        correct: "inserisci",
        distractors: ["inserendo", "inserito", "inseriresti"],
        explanation: "È un comando diretto alla seconda persona: imperativo presente.",
        concept: "imperativo presente",
        targetLabel: "Comando",
      },
      {
        context: "Dopo ___ il fusibile, il tecnico riavviò il banco.",
        correct: "aver sostituito",
        distractors: ["sostituiva", "sostituisca", "sostituirebbe"],
        explanation: "Dopo + infinito composto indica un'azione precedente al riavvio.",
        concept: "infinito composto",
        targetLabel: "Forma implicita",
      },
      {
        context: "Scrivi la forma corretta: è necessario che voi ___ il dato. (verificare, congiuntivo presente)",
        correct: "verifichiate",
        distractors: ["verificate", "verificherete", "verificaste"],
        explanation: "È necessario che richiede congiuntivo; voi + verificare = verifichiate.",
        concept: "congiuntivo presente",
        targetLabel: "Scrivi il congiuntivo",
        typed: true,
      },
    ];
    const advanced: VerbMasteryItem[] = [
      {
        context: "Se il tecnico ___ il cavo, il corto non sarebbe continuato.",
        correct: "avesse isolato",
        distractors: ["isolava", "isolerebbe", "avrà isolato"],
        explanation: "Ipotesi non realizzata nel passato: congiuntivo trapassato nella subordinata.",
        concept: "congiuntivo trapassato",
        targetLabel: "Periodo ipotetico dell'irrealtà",
      },
      {
        context: "Il rapporto sarebbe stato valido se le fonti ___ indipendenti.",
        correct: "fossero state",
        distractors: ["sono state", "sarebbero state", "erano"],
        explanation: "Dopo se, nell'ipotesi irreale del passato, si usa il congiuntivo trapassato: fossero state.",
        concept: "concordanza dei modi",
        targetLabel: "Congiuntivo trapassato",
      },
      {
        context: "Il registro, ___ dal tecnico, fu archiviato nel nucleo.",
        correct: "verificato",
        distractors: ["verificando", "verificare", "verifichi"],
        explanation: "Verificato è participio passato con valore di frase implicita: registro che è stato verificato.",
        concept: "participio passato",
        targetLabel: "Forma implicita",
      },
      {
        context: "___ la soglia, il sistema invia un avviso.",
        correct: "Superata",
        distractors: ["Superando", "Superare", "Supererebbe"],
        explanation: "Superata la soglia equivale a quando la soglia è stata superata: participio passato assoluto.",
        concept: "participio assoluto",
        targetLabel: "Forma implicita avanzata",
      },
      {
        context: "Scrivi la forma corretta: se avessimo letto il log, noi ___ l'errore. (evitare, condizionale passato)",
        correct: "avremmo evitato",
        distractors: ["eviteremmo", "avessimo evitato", "evitavamo"],
        explanation: "La conseguenza non realizzata nel passato usa condizionale passato: avremmo evitato.",
        concept: "condizionale passato",
        targetLabel: "Scrivi il condizionale passato",
        typed: true,
      },
    ];
    const pool = level >= 6 ? [...base, ...intermediate, ...advanced] : level >= 4 ? [...base, ...intermediate] : base;
    const item = random.pick(pool);
    const typed = item.typed || (level >= 6 && random.bool(0.28));
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Non ancora: ${item.explanation}`)),
    ]);
    const accepted = item.accepted ?? [normalizeTypedAnswer(item.correct)];
    return {
      id: `verb-mastery-${index}`,
      type: "verb-mastery",
      prompt: typed
        ? "Scrivi la forma verbale richiesta: persona, modo e tempo devono combaciare."
        : "Scegli la forma verbale corretta o riconosci modo e tempo.",
      context: item.context,
      targetLabel: item.targetLabel,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `verb-${item.context}-${item.correct}-${typed ? "typed" : "tiles"}`,
      inputMode: typed ? "typed" : "tiles",
      acceptedAnswers: typed ? accepted : undefined,
    };
  }

  private languageTile(seed: number, label: string, isCorrect: boolean, feedback: string): LanguageMinigameTile {
    return {
      id: `lang-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
      label,
      isCorrect,
      feedback,
    };
  }

  private shuffleLanguageTiles(random: Random, tiles: LanguageMinigameTile[]): LanguageMinigameTile[] {
    return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
  }

  private buildWordOrderPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = [
      { sentence: "Il sensore nord invia i dati al terminale", concept: "ordine soggetto-verbo-complemento" },
      { sentence: "Il codice apre la porta del laboratorio", concept: "ordine soggetto-verbo-complemento" },
      { sentence: "Il robot raccoglie la chiave e raggiunge l'uscita", concept: "coordinazione di due azioni" },
      { sentence: "La valvola si chiude prima del riavvio", concept: "complemento di tempo in fondo" },
      { sentence: "Il nucleo si riavvia dopo il raffreddamento", concept: "complemento di tempo in fondo" },
      { sentence: "La fonte confermata guida la scelta finale", concept: "soggetto-verbo-complemento con aggettivo" },
      { sentence: "Il diario distingue prova ipotesi e opinione", concept: "elenco di informazioni critiche" },
      { sentence: "La squadra controlla il dato prima della chiusura", concept: "ordine temporale e complemento" },
    ];
    const advanced = [
      { sentence: "Il tecnico sostituisce il fusibile prima di alimentare il circuito", concept: "subordinata temporale finale" },
      { sentence: "Il sistema invia il rapporto dopo aver verificato i dati", concept: "subordinata temporale finale" },
      { sentence: "La pompa riduce la pressione quando la temperatura sale", concept: "subordinata di tempo con quando" },
      { sentence: "Il registro resta valido se la seconda fonte conferma la misura", concept: "subordinata condizionale" },
      { sentence: "Il rapporto è chiaro quando separa causa effetto e controllo", concept: "criterio di chiarezza" },
    ];
    const item = random.pick(level >= 4 ? [...pool, ...advanced] : pool);
    const words = item.sentence.split(/\s+/);
    const tiles = this.shuffleLanguageTiles(
      random,
      words.map((word, position) => this.languageTile(index * 100 + position, word, true, "Parola del comando: conta la sua posizione.")),
    );
    const explanation = "In italiano l'ordine soggetto-verbo-complemento rende il comando eseguibile: spostare le parole cambia o annulla il senso.";
    return {
      id: `word-order-${index}`,
      type: "word-order",
      prompt: "Ricomponi il comando: tocca le parole nell'ordine naturale.",
      context: `Comando andato in pezzi: ${random.shuffle([...words]).join(" · ")}`,
      targetLabel: "Ordine corretto",
      requiredSelectionCount: words.length,
      tiles,
      solutionLabels: words,
      explanation,
      concept: item.concept,
      signature: `word-order-${item.sentence}`,
    };
  }

  private wordOrderSentenceDistractors(random: Random, words: string[]): string[] {
    const correct = words.join(" ");
    const variants = new Set<string>();
    const swap = (source: string[], i: number, j: number): string => {
      const copy = [...source];
      [copy[i], copy[j]] = [copy[j], copy[i]];
      return copy.join(" ");
    };
    const candidates: string[] = [];
    if (words.length >= 2) candidates.push(swap(words, 0, 1));
    if (words.length >= 3) candidates.push(swap(words, words.length - 2, words.length - 1));
    candidates.push([words[words.length - 1], ...words.slice(0, words.length - 1)].join(" "));
    if (words.length >= 4) candidates.push(swap(words, 1, words.length - 1));
    candidates.forEach((candidate) => {
      if (candidate !== correct) variants.add(candidate);
    });
    // Top up with random shuffles if duplicates collapsed the set.
    let guard = 0;
    while (variants.size < 3 && guard < 20) {
      const shuffled = random.shuffle([...words]).join(" ");
      if (shuffled !== correct) variants.add(shuffled);
      guard += 1;
    }
    return [...variants].slice(0, 3);
  }

  private languageMinigameConcepts(type: LanguageMinigameType): string[] {
    if (type === "agreement-sprint") return ["accordo", "soggetto", "concordanza"];
    if (type === "connector-route") return ["connettivi", "logica del testo", "coesione"];
    if (type === "word-order") return ["ordine delle parole", "sintassi", "coesione"];
    if (type === "lexicon-lab") return ["lessico", "precisione", "registro"];
    if (type === "verb-mastery") return ["verbi", "modi", "tempi"];
    return ["comprensione", "informazioni utili", "pensiero critico"];
  }

  private languageMinigamePurpose(type: LanguageMinigameType): string {
    if (type === "agreement-sprint") return "Allena riconoscimento rapido di accordi, soggetti reali e forme verbali corrette.";
    if (type === "connector-route") return "Allena scelta dei connettivi in base a causa, contrasto, tempo, condizione e scopo.";
    if (type === "word-order") return "Allena la costruzione della frase: ordinare le parole per produrre un comando chiaro ed eseguibile.";
    if (type === "lexicon-lab") return "Allena vocabolario preciso: scegliere parole adatte a prova, ipotesi, fonte, sintesi e registro tecnico.";
    if (type === "verb-mastery") return "Allena padronanza dei verbi: riconoscere modo, tempo, persona e scegliere o produrre la forma corretta in contesto.";
    return "Allena lettura selettiva: separare dati utili, prove, opinioni e dettagli decorativi.";
  }

  private languageMinigameMethod(type: LanguageMinigameType): string {
    if (type === "agreement-sprint") return "Trova il soggetto, controlla singolare/plurale e verifica che verbo e aggettivo concordino.";
    if (type === "connector-route") return "Nomina il rapporto tra le due frasi: causa, conseguenza, contrasto, tempo, condizione o scopo.";
    if (type === "word-order") return "Parti dal soggetto, aggiungi il verbo, poi i complementi; metti il tempo o la condizione in fondo.";
    if (type === "lexicon-lab") return "Leggi lo scopo della frase e scegli la parola più precisa: non quella più familiare, ma quella che riduce ambiguità.";
    if (type === "verb-mastery") return "Trova indicatore temporale o reggenza, scegli modo e tempo, poi controlla persona e concordanza.";
    return "Rileggi l'obiettivo del log e tieni solo ciò che aiuta a rispondere a quell'obiettivo.";
  }

  private buildOptionFeedback(template: LanguageTemplate): Record<string, string> {
    const feedback: Record<string, string> = {};
    template.distractors.forEach((option, index) => {
      feedback[option] = template.distractorFeedback?.[option]
        ?? `Questa versione sembra plausibile, ma non supera il controllo ${index + 1}: ${template.diagnosticSteps[index % template.diagnosticSteps.length]} ${template.hints[index % template.hints.length]}`;
    });
    feedback[template.repaired] = "Riparazione coerente: grammatica, significato tecnico e ordine operativo restano allineati.";
    return feedback;
  }

  private defaultConceptTags(templateId: string): string[] {
    if (["single-generator", "north-sensor", "sealed-door", "unstable-log", "robot-report"].includes(templateId)) {
      return ["accordo", "soggetto", "coesione"];
    }
    if (["apostrophe-accent", "ha-a-control"].includes(templateId)) {
      return ["ortografia", "accenti", "apostrofi"];
    }
    if (["cause-effect-cooling", "useful-vs-noise"].includes(templateId)) {
      return ["causa-effetto", "connettivi", "informazioni utili"];
    }
    if (["pronoun-reference", "direct-indirect-pronouns"].includes(templateId)) {
      return ["pronomi", "riferimenti", "ambiguita"];
    }
    if (["relative-clause", "relative-cui"].includes(templateId)) {
      return ["frase relativa", "soggetto", "reggenza"];
    }
    if (templateId === "conditional-alert") {
      return ["negazione", "condizione", "sicurezza"];
    }
    if (["technical-summary", "sequence-before-after"].includes(templateId)) {
      return ["ordine logico", "sequenza", "coesione"];
    }
    if (["punctuation-safety"].includes(templateId)) {
      return ["punteggiatura", "condizione", "chiarezza"];
    }
    if (["source-reliability", "thesis-evidence"].includes(templateId)) {
      return ["pensiero critico", "tesi e prova", "fonte"];
    }
    if (["lexical-precision", "nominalization-precision", "register-formal"].includes(templateId)) {
      return ["lessico tecnico", "precisione", "significato"];
    }
    if (["passive-active"].includes(templateId)) {
      return ["forma passiva", "agente", "accordo"];
    }
    if (["reported-speech-log"].includes(templateId)) {
      return ["discorso indiretto", "reggenza", "soglia"];
    }
    if (["main-idea-summary"].includes(templateId)) {
      return ["sintesi", "informazioni utili", "causa-effetto"];
    }
    if (["period-hypothesis"].includes(templateId)) {
      return ["periodo ipotetico", "congiuntivo", "condizionale"];
    }
    if (["implicit-subject"].includes(templateId)) {
      return ["subordinata implicita", "soggetto", "chiarezza"];
    }
    return ["comprensione", "grammatica", "coerenza"];
  }

  private competenciesFor(templateId: string): string[] {
    const base = ["italiano.comprensione", "italiano.grammatica", "pensieroCritico"];
    if (["lexical-precision", "nominalization-precision", "register-formal", "useful-vs-noise"].includes(templateId)) {
      return [...base, "italiano.lessico"];
    }
    if (["main-idea-summary", "technical-summary", "source-reliability", "thesis-evidence"].includes(templateId)) {
      return [...base, "italiano.scritturaBreve", "italiano.argomentazione"];
    }
    if (["punctuation-safety", "apostrophe-accent", "ha-a-control"].includes(templateId)) {
      return [...base, "italiano.punteggiatura"];
    }
    if (["pronoun-reference", "direct-indirect-pronouns", "relative-clause", "relative-cui", "implicit-subject"].includes(templateId)) {
      return [...base, "italiano.coesione"];
    }
    return base;
  }

  private levelName(level: number): string {
    if (level <= 2) return "ortografia e accordi fondamentali";
    if (level <= 4) return "connettivi, pronomi e coerenza";
    if (level <= 6) return "frasi complesse e sintesi";
    return "argomentazione, registro e precisione";
  }
}
