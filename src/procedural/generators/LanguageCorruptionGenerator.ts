import { languageTemplates } from "../../data/procedural/languageTemplates";
import type { LanguageTemplate } from "../../data/procedural/languageTemplates";
import {
  italianVocabularyByMaxLevel,
  italianVocabularyCategoryLabels,
  italianVocabularyEntries,
  type ItalianVocabularyEntry,
} from "../../data/procedural/italianVocabularyBank";
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
  /** Per-distractor diagnostic feedback (parallel to `distractors`): names the
   *  specific mistake made by choosing that option, not just the right answer. */
  distractorFeedback?: string[];
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
  { sg: "Il cavo", pl: "I cavi", gender: "m" },
  { sg: "La scheda", pl: "Le schede", gender: "f" },
  { sg: "Il circuito", pl: "I circuiti", gender: "m" },
  { sg: "La misura", pl: "Le misure", gender: "f" },
  { sg: "Il valore", pl: "I valori", gender: "m" },
  { sg: "La fonte", pl: "Le fonti", gender: "f" },
  { sg: "Il rapporto", pl: "I rapporti", gender: "m" },
  { sg: "La procedura", pl: "Le procedure", gender: "f" },
  { sg: "Il messaggio", pl: "I messaggi", gender: "m" },
  { sg: "La console", pl: "Le console", gender: "f" },
  { sg: "Il terminale", pl: "I terminali", gender: "m" },
  { sg: "La sequenza", pl: "Le sequenze", gender: "f" },
  { sg: "Il fusibile", pl: "I fusibili", gender: "m" },
  { sg: "La soglia", pl: "Le soglie", gender: "f" },
  { sg: "Il grafico", pl: "I grafici", gender: "m" },
  { sg: "La tabella", pl: "Le tabelle", gender: "f" },
  { sg: "Il dato", pl: "I dati", gender: "m" },
  { sg: "La prova", pl: "Le prove", gender: "f" },
  { sg: "Il controllo", pl: "I controlli", gender: "m" },
  { sg: "La diagnosi", pl: "Le diagnosi", gender: "f" },
] as const;

/** Regular -ato/-ito adjective roots (4 forms by adding o/a/i/e). */
const AGREEMENT_ADJ_ROOTS = [
  "calibrat", "pront", "salvat", "attivat", "isolat", "collegat",
  "aggiornat", "bloccat", "verificat", "configurat", "alimentat", "spent",
  "controllat", "confermat", "ordinat", "segnalat", "protett", "riparat",
  "corrett", "sicurat", "validat", "registrat", "copiat", "completat",
  "ridott", "aumentat", "misurat", "conservat", "sincronizzat", "stabilizzat",
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
  { sg3: "misura", pl3: "misurano", p1pl: "misuriamo", part: "misurato", object: "la temperatura" },
  { sg3: "confronta", pl3: "confrontano", p1pl: "confrontiamo", part: "confrontato", object: "le fonti" },
  { sg3: "segnala", pl3: "segnalano", p1pl: "segnaliamo", part: "segnalato", object: "l'anomalia" },
  { sg3: "riduce", pl3: "riducono", p1pl: "riduciamo", part: "ridotto", object: "il rischio" },
  { sg3: "aumenta", pl3: "aumentano", p1pl: "aumentiamo", part: "aumentato", object: "la precisione" },
  { sg3: "protegge", pl3: "proteggono", p1pl: "proteggiamo", part: "protetto", object: "il circuito" },
  { sg3: "riavvia", pl3: "riavviano", p1pl: "riavviamo", part: "riavviato", object: "il sistema" },
  { sg3: "ripara", pl3: "riparano", p1pl: "ripariamo", part: "riparato", object: "il guasto" },
  { sg3: "isola", pl3: "isolano", p1pl: "isoliamo", part: "isolato", object: "il ramo difettoso" },
  { sg3: "valida", pl3: "validano", p1pl: "validiamo", part: "validato", object: "il risultato" },
  { sg3: "ordina", pl3: "ordinano", p1pl: "ordiniamo", part: "ordinato", object: "la sequenza" },
  { sg3: "descrive", pl3: "descrivono", p1pl: "descriviamo", part: "descritto", object: "la causa" },
  { sg3: "riassume", pl3: "riassumono", p1pl: "riassumiamo", part: "riassunto", object: "il rapporto" },
  { sg3: "distingue", pl3: "distinguono", p1pl: "distinguiamo", part: "distinto", object: "fatto e opinione" },
  { sg3: "conserva", pl3: "conservano", p1pl: "conserviamo", part: "conservato", object: "la copia" },
  { sg3: "sincronizza", pl3: "sincronizzano", p1pl: "sincronizziamo", part: "sincronizzato", object: "l'orario" },
] as const;

type VerbMasteryItem = {
  context: string;
  correct: string;
  distractors: string[];
  distractorFeedback?: string[];
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
  { sg: "Il quaderno", pl: "I quaderni", gender: "m" },
  { sg: "La matita", pl: "Le matite", gender: "f" },
  { sg: "Il telefono", pl: "I telefoni", gender: "m" },
  { sg: "La cartella", pl: "Le cartelle", gender: "f" },
  { sg: "Il tavolo", pl: "I tavoli", gender: "m" },
  { sg: "La cucina", pl: "Le cucine", gender: "f" },
  { sg: "Il cassetto", pl: "I cassetti", gender: "m" },
  { sg: "La borsa", pl: "Le borse", gender: "f" },
  { sg: "Il biglietto", pl: "I biglietti", gender: "m" },
  { sg: "La bottiglia", pl: "Le bottiglie", gender: "f" },
  { sg: "Il piatto", pl: "I piatti", gender: "m" },
  { sg: "La scarpa", pl: "Le scarpe", gender: "f" },
  { sg: "Il messaggio", pl: "I messaggi", gender: "m" },
  { sg: "La domanda", pl: "Le domande", gender: "f" },
  { sg: "Il compito", pl: "I compiti", gender: "m" },
  { sg: "La risposta", pl: "Le risposte", gender: "f" },
  { sg: "Il panino", pl: "I panini", gender: "m" },
  { sg: "La merenda", pl: "Le merende", gender: "f" },
  { sg: "Il treno", pl: "I treni", gender: "m" },
  { sg: "La fermata", pl: "Le fermate", gender: "f" },
  { sg: "Il parco", pl: "I parchi", gender: "m" },
  { sg: "La strada", pl: "Le strade", gender: "f" },
  { sg: "Il gioco", pl: "I giochi", gender: "m" },
  { sg: "La canzone", pl: "Le canzoni", gender: "f" },
  { sg: "Il documento", pl: "I documenti", gender: "m" },
  { sg: "La password", pl: "Le password", gender: "f" },
  { sg: "Il vicino", pl: "I vicini", gender: "m" },
  { sg: "La squadra", pl: "Le squadre", gender: "f" },
  { sg: "Il prezzo", pl: "I prezzi", gender: "m" },
  { sg: "La ricevuta", pl: "Le ricevute", gender: "f" },
  { sg: "Il disegno", pl: "I disegni", gender: "m" },
  { sg: "La storia", pl: "Le storie", gender: "f" },
] as const;

const EVERYDAY_ADJ_ROOTS = [
  "pront", "apert", "chius", "pulit", "nuov", "acces", "spent", "rott",
  "ordinat", "bagnat", "asciutt", "pien", "vuot", "liber", "occupat",
  "calm", "fredd", "cald", "sicur", "comod", "corrett", "sbagliat",
  "lent", "rapid", "colorat", "segnat", "copiat", "salvat", "trovat",
] as const;

type SubjectPool = readonly { sg: string; pl: string; gender: "m" | "f" }[];

/** Pattern B — "essere + aggettivo": exercises number AND gender agreement. */
function parametricEssereAdjItem(random: Random, subjects: SubjectPool, roots: readonly string[], everyday: boolean): AgreementItem {
  const subject = random.pick(subjects);
  const root = random.pick(roots);
  const plural = random.bool();
  const subjForm = plural ? subject.pl : subject.sg;
  const adjSingular = adjForm(root, subject.gender, false);
  const adjPlural = adjForm(root, subject.gender, true);
  const correctVerb = plural ? "sono" : "è";
  const correctAdj = plural ? adjPlural : adjSingular;
  const correct = `${correctVerb} ${correctAdj}`;
  const numberWord = plural ? "plurale" : "singolare";
  const genderWord = subject.gender === "m" ? "maschile" : "femminile";
  const adjEnding = subject.gender === "m" ? (plural ? "-i" : "-o") : (plural ? "-e" : "-a");
  const options = [
    { label: `è ${adjSingular}`, verbPlural: false, adjPlural: false },
    { label: `è ${adjPlural}`, verbPlural: false, adjPlural: true },
    { label: `sono ${adjSingular}`, verbPlural: true, adjPlural: false },
    { label: `sono ${adjPlural}`, verbPlural: true, adjPlural: true },
  ].filter((option) => option.label !== correct);
  const distractors = options.map((option) => option.label);
  const distractorFeedback = options.map((option) => {
    const verbWrong = option.verbPlural !== plural;
    const adjWrong = option.adjPlural !== plural;
    const chosenVerb = option.verbPlural ? "sono" : "è";
    const chosenAdj = option.adjPlural ? adjPlural : adjSingular;
    if (verbWrong && adjWrong) {
      return `Doppio errore di numero: «${subjForm.toLowerCase()}» è ${numberWord}, quindi «${correct}» (verbo «${correctVerb}» e aggettivo in ${adjEnding}), non «${option.label}».`;
    }
    if (verbWrong) {
      return `Sbagli il verbo: il soggetto è ${numberWord}, serve «${correctVerb}» non «${chosenVerb}» (l'aggettivo «${chosenAdj}» andava bene).`;
    }
    return `Sbagli l'aggettivo: con un soggetto ${numberWord} ${genderWord} serve «${correctAdj}» (${adjEnding}), non «${chosenAdj}».`;
  });
  return {
    context: `${subjForm} ___ ${everyday ? "in questo momento." : "secondo il registro."}`,
    correct,
    distractors,
    distractorFeedback,
    explanation: `Il soggetto è ${numberWord} ${genderWord}: ${subjForm.toLowerCase()} ${correct}.`,
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
  const numberWord = plural ? "plurale" : "singolare";
  const wrongNumberVerb = plural ? verb.sg3 : verb.pl3;
  const distractors = [wrongNumberVerb, verb.p1pl, verb.part];
  const distractorFeedback = [
    `Sbagli il numero: «${subjForm.toLowerCase()}» è ${numberWord}, quindi terza persona ${numberWord} «${correct}», non «${wrongNumberVerb}».`,
    `Sbagli la persona: «${verb.p1pl}» è prima persona plurale (noi). Qui il soggetto è «${subjForm.toLowerCase()}» (terza persona): serve «${correct}».`,
    `«${verb.part}» è il participio passato: da solo non regge la frase né concorda col soggetto. La voce giusta è «${correct}».`,
  ];
  return {
    context: `${subjForm} ___ ${verb.object}.`,
    correct,
    distractors,
    distractorFeedback,
    explanation: `Il soggetto ${subjForm.toLowerCase()} è ${numberWord}: terza persona ${numberWord} «${correct}».`,
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
    // Full eligible pool at every level: levels grade difficulty, not the mix of
    // exercise archetypes.
    const eligibleTemplates = languageTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const pool = eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates;
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
      : random.pick<LanguageMinigameType>(["agreement-sprint", "connector-route", "intruder-hunt", "word-order", "lexicon-lab", "verb-mastery", "punctuation-fix", "argument-sort"]);
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
      "punctuation-fix": "Minigioco italiano: Accenti e apostrofi",
      "argument-sort": "Minigioco italiano: Fatti, opinioni e prove",
    };
    const instructions: Record<LanguageMinigameType, string> = {
      "agreement-sprint": "clicca la forma che rende la frase corretta per genere, numero e verbo.",
      "connector-route": "clicca il connettivo che mantiene il rapporto logico tra le informazioni.",
      "intruder-hunt": "clicca il dettaglio inutile o contraddittorio rispetto allo scopo del log.",
      "word-order": "tocca le parole nell'ordine giusto per ricomporre il comando eseguibile.",
      "lexicon-lab": "clicca la parola più precisa per il contesto: tecnico, critico, narrativo o operativo.",
      "verb-mastery": "riconosci modo e tempo, oppure scrivi la forma verbale corretta in contesto.",
      "punctuation-fix": "clicca la forma scritta correttamente: accenti e apostrofi al posto giusto.",
      "argument-sort": "classifica l'affermazione: fatto, opinione, ipotesi o prova.",
    };
    // Comprehension-heavy sprints (find the intruder, choose the precise word)
    // run in a calmer, longer "reflective" mode: more reading time, no speed
    // pressure — friendlier for slower readers / DSA.
    const reflective = type === "intruder-hunt" || type === "lexicon-lab" || type === "argument-sort";
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
        ...(type === "punctuation-fix" ? ["italiano.punteggiatura", "italiano.grammatica"] : []),
        ...(type === "argument-sort" ? ["italiano.argomentazione", "italiano.comprensione", "pensieroCritico"] : []),
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
    if (type === "punctuation-fix") return this.buildPunctuationPrompt(random, level, index);
    if (type === "argument-sort") return this.buildArgumentPrompt(random, level, index);
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
        context: "L'elenco dei moduli ___ pronto, ma alcuni sensori restano isolati.",
        correct: "è",
        distractors: ["sono", "hanno", "vengono"],
        explanation: "Il nucleo del soggetto è elenco, singolare maschile: l'elenco è pronto.",
        concept: "nucleo del soggetto con complemento plurale",
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
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, item.distractorFeedback?.[choiceIndex] ?? `Non regge: ${item.explanation}`)),
    ]);
    // Agreement stays a SELECTION exercise (tiles): the concord axis is fixed
    // by the distractors, but the tense is not, so a typed answer would be
    // under-determined ("l'elenco ___ pronto" admits è/era/sarà). Production
    // writing is covered — unambiguously — by verb-mastery, whose typed items
    // always state infinitive + mood/tense.
    return {
      id: `agreement-${index}`,
      type: "agreement-sprint",
      prompt: "Completa il log con la forma grammaticale che il sistema può eseguire.",
      context: item.context,
      targetLabel: "Concordanza corretta",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `agreement-${item.context}-${item.correct}`,
      inputMode: "tiles",
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
        distractors: ["infatti", "dunque", "e"],
        explanation: "C'è un contrasto tra una parte corretta e il problema ancora presente.",
        concept: "contrasto",
      },
      {
        context: "Controlla il registro ___ aprire la porta.",
        correct: "prima di",
        distractors: ["invece di", "senza", "pur di"],
        explanation: "Serve un vincolo temporale: il controllo avviene prima dell'apertura (non al posto di, non senza, non a ogni costo).",
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
        context: "Prima il robot invia il segnale, ___ il nucleo registra l'arrivo.",
        correct: "poi",
        distractors: ["benché", "affinché", "invece"],
        explanation: "Con «prima» all'inizio serve «poi»: è una sequenza temporale, prima il segnale, dopo la registrazione.",
        concept: "sequenza temporale",
      },
      {
        context: "Il sensore non risponde, ___ controlla prima il cavo dati.",
        correct: "perciò",
        distractors: ["tuttavia", "sebbene", "mentre"],
        explanation: "Perciò introduce una conseguenza operativa: il mancato segnale porta al controllo del cavo.",
        concept: "conseguenza operativa",
      },
      {
        context: "Il fusibile è integro, ___ il banco resta senza energia.",
        correct: "eppure",
        distractors: ["quindi", "poiché", "affinché"],
        explanation: "Eppure segnala contrasto tra un controllo positivo e un problema ancora presente.",
        concept: "contrasto inatteso",
      },
      {
        context: "Registra la misura ___ la confronti con il valore precedente.",
        correct: "prima che",
        distractors: ["perché", "benché", "quindi"],
        explanation: "Prima che indica che la registrazione deve precedere il confronto.",
        concept: "anteriorità",
      },
      {
        context: "La squadra può procedere ___ il supervisore conferma il rapporto.",
        correct: "quando",
        distractors: ["perciò", "sebbene", "invece"],
        explanation: "Quando introduce il momento/condizione in cui l'azione diventa possibile.",
        concept: "tempo-condizione",
      },
      {
        context: "Il dato è utile, ___ non basta da solo a chiudere l'indagine.",
        correct: "ma",
        distractors: ["infatti", "dunque", "perché"],
        explanation: "Ma limita la forza del dato: è utile, però non sufficiente.",
        concept: "limitazione argomentativa",
      },
      {
        context: "Il registro mostra due errori; ___, la fonte resta da verificare.",
        correct: "inoltre",
        distractors: ["invece", "benché", "affinché"],
        explanation: "Inoltre aggiunge una seconda informazione allo stesso ragionamento.",
        concept: "aggiunta",
      },
      {
        context: "Non premere Conferma ___ hai riletto il messaggio.",
        correct: "finché non",
        distractors: ["perché non", "sebbene", "affinché"],
        explanation: "Finché non indica il limite: aspetta fino al completamento della rilettura.",
        concept: "limite temporale con negazione",
      },
      {
        context: "Il testo cita una prova, ___ la conclusione è ancora troppo forte.",
        correct: "però",
        distractors: ["quindi", "poiché", "infatti"],
        explanation: "Però segnala che la prova esiste ma non sostiene una conclusione così forte.",
        concept: "concessione e limite",
      },
      {
        context: "Il modulo salva il log ___ la rete torna disponibile.",
        correct: "appena",
        distractors: ["benché", "perciò", "invece"],
        explanation: "Appena indica il momento immediatamente successivo al ritorno della rete.",
        concept: "successione immediata",
      },
      {
        context: "Il messaggio è breve ___ contiene tutti i dati essenziali.",
        correct: "e",
        distractors: ["perché", "sebbene", "affinché"],
        explanation: "E coordina due qualità compatibili: brevità e completezza essenziale.",
        concept: "coordinazione",
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
      {
        context: "La fonte è autorevole; ___, il dato va confrontato con una seconda misura.",
        correct: "nonostante ciò",
        distractors: ["per questo", "affinché", "finché"],
        explanation: "Nonostante ciò introduce una cautela che resta valida anche davanti a una fonte autorevole.",
        concept: "concessione argomentativa",
      },
      {
        context: "Il log non dimostra il guasto, ___ suggerisce dove cercarlo.",
        correct: "bensì",
        distractors: ["quindi", "poiché", "mentre"],
        explanation: "Bensì corregge l'interpretazione: non prova definitiva, ma indicazione di ricerca.",
        concept: "correzione argomentativa",
      },
      {
        context: "La porta si apre ___ il codice è valido e la chiave è presente.",
        correct: "a condizione che",
        distractors: ["benché", "perciò", "invece"],
        explanation: "A condizione che introduce i requisiti necessari all'apertura.",
        concept: "condizione complessa",
      },
      {
        context: "Il rapporto separa fatti e opinioni, ___ il lettore può controllare le prove.",
        correct: "così",
        distractors: ["sebbene", "finché", "invece"],
        explanation: "Così introduce il risultato del modo in cui il rapporto è scritto.",
        concept: "risultato",
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
        intruder: "il tecnico indossa dei guanti nuovi",
        explanation: "Cosa indossa il tecnico non ha alcun legame con il blocco della porta.",
        concept: "informazione utile e dettaglio scollegato",
      },
      {
        context: "Obiettivo: scrivere un rapporto sulle cause del guasto.",
        useful: ["il sensore B non risponde", "il log indica soglia superata", "la valvola si apre in ritardo"],
        intruder: "il guasto è capitato di lunedì",
        explanation: "Il giorno in cui è successo è una coincidenza, non una causa del guasto.",
        concept: "causa vera vs coincidenza",
      },
      {
        context: "Obiettivo: ricostruire l'ordine degli eventi.",
        useful: ["prima il robot entra in base", "poi la valvola si apre", "infine il registro viene salvato"],
        intruder: "il robot pesa dodici chili",
        explanation: "Il peso del robot è un dato vero ma non serve a ordinare gli eventi.",
        concept: "sequenza temporale",
      },
      {
        context: "Obiettivo: verificare se una fonte è affidabile.",
        useful: ["il dato è registrato dal tester", "la misura compare due volte", "l'orario del log è coerente"],
        intruder: "a prima vista sembra una fonte seria",
        explanation: "Un'impressione non dimostra l'affidabilità: servono dati verificabili, non sensazioni.",
        concept: "prova verificabile vs impressione",
      },
      {
        context: "Obiettivo: capire quale istruzione eseguire subito.",
        useful: ["il comando dice prima controlla la valvola", "il timer scade tra un minuto", "il pannello segnala rischio basso"],
        intruder: "il pannello è di un modello recente",
        explanation: "Il modello del pannello non decide quale azione fare per prima.",
        concept: "priorità operativa",
      },
      {
        context: "Obiettivo: riscrivere un log chiaro per un compagno.",
        useful: ["indica il componente guasto", "spiega l'effetto osservato", "propone il prossimo controllo"],
        intruder: "aggiunge tre aggettivi decorativi sulla stanza",
        explanation: "Gli aggettivi decorativi allungano il testo ma non aiutano un compagno a riparare il sistema.",
        concept: "sintesi e chiarezza",
      },
      {
        context: "Obiettivo: scegliere una conclusione proporzionata alle prove.",
        useful: ["due misure indicano lo stesso valore", "una fonte resta non verificata", "il rapporto segnala un dubbio"],
        intruder: "il rapporto è stato scritto in fretta",
        explanation: "Quanto in fretta è stato scritto non cambia la forza delle prove raccolte.",
        concept: "forza delle prove vs modo di scrivere",
      },
      {
        context: "Obiettivo: capire quale frase guida davvero l'azione.",
        useful: ["prima scollega la batteria", "poi misura la continuità", "non toccare il ramo caldo"],
        intruder: "secondo me questo circuito è mal progettato",
        explanation: "È un'opinione personale: non dà un ordine da eseguire come le altre frasi.",
        concept: "istruzione vs opinione",
      },
      {
        context: "Obiettivo: trovare la causa più probabile del blackout.",
        useful: ["il ramo B non riceve corrente", "il fusibile del ramo B è interrotto", "gli altri rami restano attivi"],
        intruder: "la stanza è stata pulita ieri",
        explanation: "La pulizia della stanza non spiega perché solo il ramo B resta senza corrente.",
        concept: "causa pertinente",
      },
      {
        context: "Obiettivo: scegliere una prova verificabile.",
        useful: ["il tester segna zero volt", "la misura è stata ripetuta", "il valore compare nel registro"],
        intruder: "Nora sembra molto sicura",
        explanation: "La sicurezza percepita di Nora non è una prova verificabile.",
        concept: "prova vs fiducia",
      },
      {
        context: "Obiettivo: scrivere una consegna breve.",
        useful: ["spegni il banco", "attendi dieci secondi", "riavvia il modulo"],
        intruder: "il banco è grande e lucido",
        explanation: "L'aspetto del banco non serve alla consegna operativa.",
        concept: "istruzione vs descrizione",
      },
      {
        context: "Obiettivo: controllare se una sintesi è completa.",
        useful: ["cita la causa", "indica l'effetto", "propone il prossimo passo"],
        intruder: "ripete tre volte lo stesso dato",
        explanation: "Ripetere lo stesso dato non aggiunge completezza: allunga soltanto la sintesi.",
        concept: "completezza vs ripetizione",
      },
      {
        context: "Obiettivo: distinguere fatto e interpretazione.",
        useful: ["fatto: il LED resta spento", "fatto: il cavo è scollegato", "interpretazione: manca alimentazione"],
        intruder: "fatto: secondo me il LED è timido",
        explanation: "Secondo me introduce un'opinione, quindi non può essere etichettata come fatto.",
        concept: "fatto vs opinione",
      },
      {
        context: "Obiettivo: mantenere una sequenza causale.",
        useful: ["causa: corto sul ramo B", "effetto: fusibile interrotto", "azione: sostituire il fusibile"],
        intruder: "azione: sostituire il diario",
        explanation: "Il diario non appartiene alla catena tecnica corto-fusibile-riparazione.",
        concept: "catena causa-effetto-azione",
      },
      {
        context: "Obiettivo: valutare una conclusione prudente.",
        useful: ["una misura è coerente", "manca una seconda fonte", "la conclusione resta provvisoria"],
        intruder: "il caso è sicuramente chiuso",
        explanation: "Sicuramente chiuso è troppo forte se manca una seconda fonte.",
        concept: "prudenza argomentativa",
      },
      {
        context: "Obiettivo: preparare un rapporto per un compagno.",
        useful: ["usa termini precisi", "ordina i passaggi", "segnala i dubbi"],
        intruder: "sceglie parole difficili per sembrare esperto",
        explanation: "Parole difficili non migliorano il rapporto se non aumentano precisione e chiarezza.",
        concept: "registro e chiarezza",
      },
      {
        context: "Obiettivo: isolare il dato che cambia la decisione.",
        useful: ["la soglia è superata", "il timer sta per scadere", "la porta è ancora bloccata"],
        intruder: "il simbolo della soglia è colorato in giallo",
        explanation: "Il colore del simbolo non cambia la decisione se il valore della soglia è già noto.",
        concept: "dato decisivo vs aspetto",
      },
      {
        context: "Obiettivo: verificare la coerenza di un testo.",
        useful: ["prima dice che la porta è chiusa", "poi dice che nessuno l'ha aperta", "infine ordina di cercare la chiave"],
        intruder: "però afferma che la porta è già aperta",
        explanation: "Dire che la porta è già aperta contraddice la situazione descritta dagli altri dati.",
        concept: "contraddizione",
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
      {
        context: "Obiettivo: riconoscere un'inferenza sostenuta dal testo.",
        useful: ["il log dice che la batteria è scarica", "la porta richiede alimentazione", "inferenza: serve ricaricare la batteria"],
        intruder: "inferenza: la serratura è rotta per forza",
        explanation: "La serratura potrebbe essere sana: il testo sostiene il problema di alimentazione, non una rottura certa.",
        concept: "inferenza proporzionata",
      },
      {
        context: "Obiettivo: distinguere concessione e smentita.",
        useful: ["il registro è quasi completo", "manca una firma", "quindi non è ancora valido"],
        intruder: "il registro è completo senza limiti",
        explanation: "Dire completo senza limiti cancella il dato della firma mancante.",
        concept: "concessione e limite",
      },
      {
        context: "Obiettivo: controllare la pertinenza delle prove.",
        useful: ["la prova misura lo stesso sensore", "la prova è recente", "la prova è ripetibile"],
        intruder: "la prova è scritta con un titolo elegante",
        explanation: "Un titolo elegante non rende una prova più pertinente o controllabile.",
        concept: "pertinenza della prova",
      },
      {
        context: "Obiettivo: scegliere una formulazione non ambigua.",
        useful: ["indica chi compie l'azione", "nomina l'oggetto controllato", "specifica quando eseguire il comando"],
        intruder: "usa il pronome 'lo' senza referente chiaro",
        explanation: "Un pronome senza referente chiaro rende il comando ambiguo.",
        concept: "referente del pronome",
      },
      {
        context: "Obiettivo: valutare il registro del rapporto.",
        useful: ["usa termini tecnici necessari", "evita espressioni colloquiali", "mantiene frasi brevi"],
        intruder: "aggiunge 'fa casino' come diagnosi ufficiale",
        explanation: "Fa casino è colloquiale e impreciso: non appartiene a un rapporto tecnico.",
        concept: "registro formale",
      },
      {
        context: "Obiettivo: distinguere causa e condizione.",
        useful: ["causa: il cavo è interrotto", "condizione: riavvia solo dopo la sostituzione", "effetto: il banco resta spento"],
        intruder: "causa: riavvia solo dopo la sostituzione",
        explanation: "Riavvia solo dopo la sostituzione è una condizione operativa, non la causa del guasto.",
        concept: "causa vs condizione",
      },
      {
        context: "Obiettivo: preparare una scaletta logica.",
        useful: ["osservazione iniziale", "ipotesi da verificare", "controllo finale"],
        intruder: "conclusione definitiva prima delle prove",
        explanation: "La conclusione definitiva non può precedere le prove in una scaletta logica.",
        concept: "ordine argomentativo",
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

  private buildPunctuationPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = [
      { context: "Il sensore ___ spento e non risponde.", correct: "è", distractors: ["e", "é", "hè"], explanation: "«è» è il verbo essere (accento grave); «e» senza accento è la congiunzione.", concept: "è / e" },
      { context: "Spiega ___ la porta resta bloccata.", correct: "perché", distractors: ["perchè", "perche", "per ché"], explanation: "«perché» vuole l'accento acuto sulla e (é) e si scrive unito.", concept: "accento acuto: perché" },
      { context: "Aspetta un ___ e riprova la misura.", correct: "po'", distractors: ["pò", "po", "pó"], explanation: "«po'» abbrevia «poco»: vuole l'apostrofo, non l'accento (mai «pò»).", concept: "apostrofo: po'" },
      { context: "___ il valore corretto della soglia?", correct: "Qual è", distractors: ["Qual'è", "Qual é", "Qual'e"], explanation: "«qual è» si scrive senza apostrofo: «qual» è un troncamento, non un'elisione; «è» usa l'accento grave.", concept: "qual è (no apostrofo)" },
      { context: "___ un errore nel registro dei dati.", correct: "C'è", distractors: ["Ce", "C'e", "Cè"], explanation: "«c'è» = ci + è (esserci): apostrofo più accento.", concept: "c'è / ce" },
      { context: "Serve ___ misura per confermare.", correct: "un'altra", distractors: ["un altra", "un' altra", "un altro"], explanation: "Davanti a nome femminile che inizia per vocale si usa «un'altra»: apostrofo senza spazio.", concept: "un'altra" },
      { context: "È arrivato ___ del tecnico.", correct: "un amico", distractors: ["un'amico", "uno amico", "un' amico"], explanation: "Davanti a nome maschile «un» non vuole mai l'apostrofo, nemmeno prima di vocale.", concept: "un maschile (no apostrofo)" },
      { context: "Con questa resistenza passa ___ corrente.", correct: "più", distractors: ["piu", "piú", "pui"], explanation: "«Più» ha l'accento grave sulla u; senza accento la forma è ortograficamente scorretta.", concept: "accento: più" },
      { context: "Apri ___ delle parole.", correct: "l'archivio", distractors: ["lo archivio", "il archivio", "l' archivio"], explanation: "Davanti a vocale l'articolo si elide: «l'archivio», con apostrofo senza spazio.", concept: "elisione: l'" },
      { context: "Rispondi ___ se il dato è coerente.", correct: "sì", distractors: ["si", "sí", "sî"], explanation: "«sì» (affermazione) vuole l'accento; «si» senza accento è il pronome.", concept: "sì / si" },
      { context: "Il tecnico è ___ con la diagnosi.", correct: "d'accordo", distractors: ["daccordo", "di accordo", "d accordo"], explanation: "«d'accordo» si scrive con l'apostrofo, in un'unica espressione.", concept: "d'accordo" },
      { context: "Controlla ___ il sensore risponde.", correct: "se", distractors: ["sé", "s'è", "sè"], explanation: "«se» condizionale non vuole accento; «sé» con accento è il pronome (se stesso).", concept: "se / sé" },
      { context: "Il modulo ___ già inviato il rapporto.", correct: "ha", distractors: ["a", "à", "ah"], explanation: "«ha» è voce del verbo avere e accompagna il participio «inviato»; «a» è preposizione.", concept: "ha / a" },
      { context: "Collega il cavo ___ massa.", correct: "a", distractors: ["ha", "à", "ah"], explanation: "«a massa» indica collegamento/direzione: qui serve la preposizione «a», non il verbo «ha».", concept: "a / ha" },
      { context: "Il tecnico ___ controllato il fusibile.", correct: "ha", distractors: ["a", "à", "hà"], explanation: "Nei tempi composti serve l'ausiliare «ha» senza accento.", concept: "ausiliare avere" },
      { context: "La prova ___ utile, però non decisiva.", correct: "è", distractors: ["e", "é", "he"], explanation: "«è» è verbo essere con accento grave; «e» unisce due parole o frasi.", concept: "è / e" },
      { context: "Il log è chiaro ___ breve.", correct: "e", distractors: ["è", "é", "eh"], explanation: "Qui «e» collega due aggettivi; non è il verbo essere.", concept: "e congiunzione" },
      { context: "Nora ___ accorta dell'errore.", correct: "s'è", distractors: ["se", "sé", "sè"], explanation: "«s'è accorta» unisce si + è: servono apostrofo e accento.", concept: "s'è" },
      { context: "Tieni il cavo vicino a ___, non al bordo caldo.", correct: "sé", distractors: ["se", "s'è", "sè"], explanation: "«sé» pronome tonico vuole l'accento; «se» introduce una condizione.", concept: "sé pronome" },
      { context: "Il rapporto ___ stato salvato nel diario.", correct: "è", distractors: ["e", "é", "ha"], explanation: "Nel passivo «è stato salvato» usa il verbo essere con accento grave.", concept: "è ausiliare" },
      { context: "La squadra lavora ___ evitare altri errori.", correct: "per", distractors: ["per'", "pèr", "perché"], explanation: "Qui «per» introduce lo scopo con l'infinito; non richiede accento né apostrofo.", concept: "per / perché" },
      { context: "Rileggi il testo, ___ correggi l'accento.", correct: "poi", distractors: ["po'", "pòi", "pói"], explanation: "«poi» è un avverbio di tempo e non vuole apostrofo; «po'» significa «poco».", concept: "poi / po'" },
    ];
    const advanced = [
      { context: "Non so ___ fonte scegliere tra le due.", correct: "quale", distractors: ["qual'e", "qual è", "qualè"], explanation: "Davanti a consonante si usa la forma intera «quale»; il troncamento «qual» si usa in «qual è».", concept: "quale / qual è" },
      { context: "Fai ___ come dice il manuale.", correct: "così", distractors: ["cosi", "cosí", "co'sì"], explanation: "«Così» ha l'accento grave sulla i; non vuole apostrofo né accento acuto.", concept: "accento: così" },
      { context: "Non spegnere ___ il codice non è confermato.", correct: "finché", distractors: ["finchè", "finche", "fin ché"], explanation: "«finché» (come «perché») vuole l'accento acuto: é.", concept: "accento acuto: finché" },
      { context: "Il dato ___ registrato ieri sera.", correct: "è stato", distractors: ["e stato", "è statto", "é stato"], explanation: "«è stato» usa il verbo essere con accento grave: «è».", concept: "è (ausiliare)" },
      { context: "Il sistema non sa ___ scegliere tra le due fonti.", correct: "quale", distractors: ["qual'è", "qual è", "qualè"], explanation: "Qui non segue «è»: serve «quale» intero, senza apostrofo né accento.", concept: "quale" },
      { context: "___ il dato non torna, segnala l'anomalia.", correct: "Se", distractors: ["Sé", "S'è", "Sè"], explanation: "«Se» introduce una condizione e non vuole accento.", concept: "se condizionale" },
      { context: "Il tecnico ___ né rumore né odore di bruciato.", correct: "non sente", distractors: ["non sentè", "non sé nte", "non sente'"], explanation: "«Sente» non vuole accenti o apostrofi; «né» invece è già accentato per negare entrambi gli elementi.", concept: "forme senza accento" },
      { context: "Non c'è ___ da aggiungere al rapporto.", correct: "nulla", distractors: ["nullà", "nul la", "null'a"], explanation: "«Nulla» non vuole accento né apostrofo.", concept: "parole non accentate" },
      { context: "La console ___: «controlla il log».", correct: "dice", distractors: ["dicè", "di ce", "dice'"], explanation: "«Dice» è una forma piana e non si accentua.", concept: "accenti non necessari" },
      { context: "Il valore ___ alto va verificato di nuovo.", correct: "più", distractors: ["piu", "piú", "pìu"], explanation: "«Più» usa l'accento grave sulla u; l'accento acuto o l'assenza di accento non sono corretti.", concept: "accento grave: più" },
      { context: "___ un'ipotesi, non una prova.", correct: "È", distractors: ["E", "É", "He"], explanation: "A inizio frase «È» è verbo essere e richiede accento grave.", concept: "È maiuscola" },
      { context: "Il comando ___ pronto, ma manca la conferma.", correct: "è", distractors: ["e", "é", "eh"], explanation: "Qui serve il verbo essere: «è pronto».", concept: "è verbo" },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Forma sbagliata. ${item.explanation}`)),
    ]);
    return {
      id: `punctuation-${index}`,
      type: "punctuation-fix",
      prompt: "Scegli la forma scritta correttamente: accenti e apostrofi al posto giusto.",
      context: item.context,
      targetLabel: "Ortografia corretta",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `punctuation-${item.context}-${item.correct}`,
    };
  }

  private argumentTypeHint(type: string): string {
    if (type === "Fatto") return "Un fatto è un dato osservabile e verificabile, non un giudizio né una supposizione.";
    if (type === "Opinione") return "Un'opinione è un giudizio personale (spesso «secondo me», «bello», «migliore»).";
    if (type === "Ipotesi") return "Un'ipotesi è una spiegazione possibile ancora da verificare (spesso «forse», «potrebbe»).";
    return "Una prova è un dato verificato usato per sostenere una conclusione.";
  }

  private buildArgumentPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const TYPES = ["Fatto", "Opinione", "Ipotesi", "Prova"] as const;
    const pool: Array<{ statement: string; type: (typeof TYPES)[number]; explanation: string }> = [
      { statement: "Il sensore segna 24 gradi.", type: "Fatto", explanation: "È una misura osservabile e verificabile: un fatto." },
      { statement: "La porta è chiusa a chiave.", type: "Fatto", explanation: "È uno stato osservabile e controllabile: un fatto." },
      { statement: "Il registro contiene dieci voci.", type: "Fatto", explanation: "È un dato che chiunque può contare e verificare: un fatto." },
      { statement: "Secondo me questo è il sensore migliore.", type: "Opinione", explanation: "«Secondo me» e «migliore» esprimono un giudizio personale, non un dato." },
      { statement: "Il laboratorio è troppo disordinato.", type: "Opinione", explanation: "«Troppo disordinato» è una valutazione personale: un'opinione." },
      { statement: "Penso che il robot sia simpatico.", type: "Opinione", explanation: "«Penso che… simpatico» è un giudizio soggettivo: un'opinione." },
      { statement: "Forse il guasto dipende dalla batteria.", type: "Ipotesi", explanation: "«Forse» segnala una spiegazione possibile, ancora da verificare: un'ipotesi." },
      { statement: "Il circuito potrebbe essere interrotto.", type: "Ipotesi", explanation: "«Potrebbe» indica una possibilità da controllare: un'ipotesi." },
      { statement: "Probabilmente il codice inserito è sbagliato.", type: "Ipotesi", explanation: "«Probabilmente» introduce una supposizione da verificare: un'ipotesi." },
      { statement: "Il tester non legge continuità, quindi il circuito è interrotto.", type: "Prova", explanation: "Un dato verificato («non legge continuità») che sostiene una conclusione: una prova." },
      { statement: "Due misure danno lo stesso valore: il dato è affidabile.", type: "Prova", explanation: "Il fatto ripetuto viene usato per sostenere una conclusione: è una prova." },
      { statement: "Il log mostra la soglia superata: ecco la causa dell'allarme.", type: "Prova", explanation: "Un dato del log usato per spiegare l'allarme: una prova." },
    ];
    const advanced: typeof pool = [
      { statement: "A mio parere il rapporto è scritto male.", type: "Opinione", explanation: "«A mio parere… male» è un giudizio personale: un'opinione." },
      { statement: "Il campione pesa 30 grammi sulla bilancia.", type: "Fatto", explanation: "È una misura letta sullo strumento: un fatto." },
      { statement: "Le due telecamere mostrano la stessa scena, quindi la ricostruzione è coerente.", type: "Prova", explanation: "Due dati concordi sostengono la conclusione: una prova." },
      { statement: "Il guasto potrebbe dipendere dall'umidità: va controllato.", type: "Ipotesi", explanation: "«Potrebbe… va controllato» propone una causa da verificare: un'ipotesi." },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(
      random,
      TYPES.map((typeLabel, i) => this.languageTile(index + i, typeLabel, typeLabel === item.type,
        typeLabel === item.type ? `Corretto: ${item.explanation}` : `Non è ${typeLabel.toLowerCase()}. ${this.argumentTypeHint(typeLabel)}`)),
    );
    return {
      id: `argument-${index}`,
      type: "argument-sort",
      prompt: "Che tipo di affermazione è? Classificala: fatto, opinione, ipotesi o prova.",
      context: item.statement,
      targetLabel: "Tipo di affermazione",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.type],
      explanation: item.explanation,
      concept: `argomentazione: ${item.type.toLowerCase()}`,
      signature: `argument-${item.statement}`,
    };
  }

  private buildLexiconPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    if (random.bool(0.72)) {
      return this.buildVocabularyBankLexiconPrompt(random, level, index);
    }
    const pool = [
      {
        context: "Il tester non dimostra ancora il guasto: mostra solo una ___ da verificare.",
        correct: "ipotesi",
        distractors: ["certezza", "prova", "conclusione"],
        explanation: "Un dato parziale genera un'ipotesi da verificare, non una certezza o una prova già stabilita.",
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
        distractors: ["misterioso", "vago", "contraddittorio"],
        explanation: "Un comando operativo deve essere chiaro; vago o contraddittorio non guidano l'azione.",
        concept: "chiarezza comunicativa",
      },
      {
        context: "Quando un indizio non basta, serve un secondo ___ prima di decidere.",
        correct: "controllo",
        distractors: ["tentativo", "parere", "rumore"],
        explanation: "Un controllo aggiunge verifica; un altro tentativo o un parere non certificano il dato.",
        concept: "verifica",
      },
      {
        context: "La frase 'forse il modulo è guasto' esprime un dubbio, non una ___.",
        correct: "diagnosi",
        distractors: ["domanda", "pausa", "immagine"],
        explanation: "La diagnosi richiede prove; forse segnala incertezza.",
        concept: "diagnosi e incertezza",
      },
      {
        context: "Se una frase può avere due significati, il testo è ___.",
        correct: "ambiguo",
        distractors: ["preciso", "verificato", "definitivo"],
        explanation: "Ambiguo significa che permette più interpretazioni; un messaggio operativo deve evitarlo.",
        concept: "ambiguità",
      },
      {
        context: "Un dato controllato due volte diventa più ___.",
        correct: "attendibile",
        distractors: ["decorativo", "rumoroso", "casuale"],
        explanation: "Attendibile indica che ci si può fidare di più della misura.",
        concept: "attendibilità",
      },
      {
        context: "La frase 'secondo me funziona' è una ___, non una prova.",
        correct: "opinione",
        distractors: ["misura", "fonte", "procedura"],
        explanation: "Secondo me introduce un'opinione personale; una prova richiede un dato controllabile.",
        concept: "opinione vs prova",
      },
      {
        context: "Quando il testo dice cosa fare per primo, indica una ___.",
        correct: "priorità",
        distractors: ["decorazione", "citazione", "pausa"],
        explanation: "Priorità indica ciò che viene prima nelle decisioni o nelle azioni.",
        concept: "priorità operativa",
      },
      {
        context: "Un rapporto breve che conserva solo le informazioni essenziali è una ___.",
        correct: "sintesi",
        distractors: ["ripetizione", "distrazione", "cornice"],
        explanation: "La sintesi riduce il testo senza perdere il nucleo informativo.",
        concept: "sintesi",
      },
      {
        context: "Se due frasi si smentiscono a vicenda, il messaggio è ___.",
        correct: "contraddittorio",
        distractors: ["coerente", "misurabile", "ordinato"],
        explanation: "Contraddittorio significa che contiene informazioni incompatibili.",
        concept: "contraddizione",
      },
      {
        context: "Nel diario, la persona o il documento da cui arriva un'informazione è la ___.",
        correct: "fonte",
        distractors: ["cornice", "soglia", "pausa"],
        explanation: "La fonte è l'origine dell'informazione; serve per valutarne l'affidabilità.",
        concept: "fonte",
      },
      {
        context: "Una spiegazione che indica il motivo di un evento ne segnala la ___.",
        correct: "causa",
        distractors: ["decorazione", "abitudine", "forma"],
        explanation: "La causa risponde alla domanda perché è successo.",
        concept: "causa",
      },
      {
        context: "La conseguenza osservabile di un guasto è il suo ___.",
        correct: "effetto",
        distractors: ["parere", "colore", "titolo"],
        explanation: "L'effetto è ciò che accade a causa del guasto.",
        concept: "causa-effetto",
      },
      {
        context: "Quando un comando può essere eseguito senza dubbi, è ___.",
        correct: "univoco",
        distractors: ["vago", "ornamentale", "casuale"],
        explanation: "Univoco significa con un solo significato possibile.",
        concept: "precisione del comando",
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
        distractors: ["verificata", "approssimativa", "leggibile"],
        explanation: "Sproporzionata significa non adeguata alla quantità di prove disponibili.",
        concept: "conclusione proporzionata",
      },
      {
        context: "Nel registro formale evita 'aggiusta': scegli un verbo più tecnico come ___.",
        correct: "ripristina",
        distractors: ["personalizza", "manipola", "colora"],
        explanation: "Ripristina è adatto a un sistema tecnico; personalizza o manipola cambiano il significato dell'azione.",
        concept: "registro formale",
      },
      {
        context: "Una conclusione che ammette un limite senza cancellare il dato è ___.",
        correct: "prudente",
        distractors: ["assoluta", "decorativa", "contraria"],
        explanation: "Prudente indica una conclusione proporzionata alle prove disponibili.",
        concept: "grado di certezza",
      },
      {
        context: "Se una parola riprende un nome già citato, funziona come ___ testuale.",
        correct: "coesione",
        distractors: ["rumore", "ipotesi", "soglia"],
        explanation: "La coesione collega parti del testo tramite pronomi, riprese e connettivi.",
        concept: "coesione testuale",
      },
      {
        context: "Un termine tecnico usato al posto di una parola generica aumenta la ___.",
        correct: "specificità",
        distractors: ["confusione", "decorazione", "fretta"],
        explanation: "Specificità significa che il lessico descrive con precisione l'oggetto o l'azione.",
        concept: "specificità lessicale",
      },
      {
        context: "Dire 'potrebbe essere guasto' invece di 'è guasto' riduce il grado di ___.",
        correct: "certezza",
        distractors: ["punteggiatura", "ordine", "registro"],
        explanation: "Potrebbe segnala incertezza: la conclusione è meno certa e richiede verifica.",
        concept: "modalità e certezza",
      },
      {
        context: "Una prova che riguarda davvero la tesi è ___.",
        correct: "pertinente",
        distractors: ["vistosa", "casuale", "ornamentale"],
        explanation: "Pertinente significa collegata allo scopo dell'argomentazione.",
        concept: "pertinenza",
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

  private buildVocabularyBankLexiconPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const pool = italianVocabularyByMaxLevel(level);
    const item = random.pick(pool.length > 0 ? pool : italianVocabularyEntries);
    const distractors = this.italianVocabularyDistractors(random, item, level);
    const category = italianVocabularyCategoryLabels[item.category];
    const scenario = this.italianVocabularyScenario(item);
    const explanation = `La parola precisa è «${item.term}»: indica ${item.clue}. Il contesto è ${category}, quindi non basta una parola simile o più generica.`;
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.term, true, `Corretto: ${explanation}`),
      ...distractors.map((entry, choiceIndex) => this.languageTile(
        index + choiceIndex + 1,
        entry.term,
        false,
        `Lessico non adatto: «${entry.term}» indica ${entry.clue}; qui l'indizio chiede ${item.clue}.`,
      )),
    ]);
    return {
      id: `lexicon-bank-${index}`,
      type: "lexicon-lab",
      prompt: "Scegli la parola italiana più precisa per una situazione reale.",
      context: `Scenario: ${scenario} Indizio: ${item.clue}.`,
      targetLabel: "Parola precisa",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.term],
      explanation,
      concept: `${category} · ${item.wordClass}`,
      signature: `lexicon-bank-${item.id}`,
    };
  }

  private italianVocabularyDistractors(random: Random, item: ItalianVocabularyEntry, level: number): ItalianVocabularyEntry[] {
    const labelOf = (entry: ItalianVocabularyEntry) => entry.term.trim().toLocaleLowerCase("it");
    const used = new Set<string>([labelOf(item)]);
    const pool = italianVocabularyByMaxLevel(level).filter((entry) => entry.id !== item.id);
    const tiers = [
      pool.filter((entry) => entry.category === item.category && entry.wordClass === item.wordClass),
      pool.filter((entry) => entry.wordClass === item.wordClass),
      italianVocabularyEntries.filter((entry) => entry.id !== item.id),
    ];
    const result: ItalianVocabularyEntry[] = [];
    for (const tier of tiers) {
      const close = random.shuffle(tier)
        .filter((entry) => !used.has(labelOf(entry)))
        .sort((a, b) => Math.abs(a.term.length - item.term.length) - Math.abs(b.term.length - item.term.length));
      for (const entry of close) {
        const label = labelOf(entry);
        if (used.has(label)) continue;
        used.add(label);
        result.push(entry);
        if (result.length >= 3) return result;
      }
    }
    return result;
  }

  private italianVocabularyScenario(item: ItalianVocabularyEntry): string {
    const scenarios: Record<ItalianVocabularyEntry["category"], string> = {
      "casa-famiglia": "stai organizzando una cosa di casa e devi usare il nome giusto, non una parola vaga.",
      "scuola-studio": "un compagno ti chiede di spiegare un'attività scolastica in modo chiaro.",
      "cibo-spesa": "devi leggere una lista o uno scontrino senza confondere prodotto, prezzo e quantità.",
      "tempo-meteo": "stai pianificando la giornata e una parola di tempo cambia la decisione.",
      "viaggi-luoghi": "devi dare un'indicazione utile a chi deve arrivare nel posto corretto.",
      "corpo-salute": "devi descrivere un sintomo o una precauzione senza esagerare.",
      "emozioni-relazioni": "devi scegliere una parola rispettosa per descrivere una situazione tra persone.",
      "digitale-media": "stai scrivendo un messaggio o proteggendo un file: serve il termine preciso.",
      "lavoro-comunita": "devi capire un avviso pubblico o una responsabilità condivisa.",
      "sport-tempo-libero": "stai raccontando un gioco, un hobby o una gara con parole concrete.",
      "natura-ambiente": "devi descrivere ambiente, risorse o raccolta differenziata in modo corretto.",
      "pensiero-linguaggio": "devi distinguere prove, opinioni, cause e conclusioni in un testo.",
    };
    return scenarios[item.category];
  }

  private buildVerbMasteryPrompt(random: Random, level: number, index: number): LanguageMinigamePrompt {
    const base: VerbMasteryItem[] = [
      {
        context: "Ieri Eli ___ il registro prima di uscire.",
        correct: "ha salvato",
        distractors: ["aveva salvato", "ha salvata", "salvava"],
        distractorFeedback: [
          "«aveva salvato» è trapassato prossimo: indica un'azione precedente a un'altra nel passato. Con «ieri» da solo basta il passato prossimo «ha salvato».",
          "«ha salvata» sbaglia il participio: con l'ausiliare «avere» e l'oggetto dopo il verbo, il participio resta invariato, «ha salvato».",
          "«salvava» è imperfetto (azione ripetuta o in corso): qui l'azione è puntuale e conclusa, «ha salvato».",
        ],
        explanation: "Ieri indica un'azione conclusa nel passato: passato prossimo, indicativo.",
        concept: "indicativo passato prossimo",
        targetLabel: "Scegli il tempo adatto",
      },
      {
        context: "Ogni mattina il sensore ___ la temperatura.",
        correct: "misura",
        distractors: ["misurò", "misurerebbe", "misurando"],
        distractorFeedback: [
          "«misurò» è passato remoto (un fatto concluso e lontano): «ogni mattina» è abituale, serve il presente «misura».",
          "«misurerebbe» è condizionale (un'ipotesi): qui è un fatto abituale reale, «misura».",
          "«misurando» è gerundio: da solo non regge la frase. Serve il presente «misura».",
        ],
        explanation: "Ogni mattina segnala un'azione abituale: presente indicativo.",
        concept: "indicativo presente",
        targetLabel: "Azione abituale",
      },
      {
        context: "Mentre il robot avanzava, la porta ___.",
        correct: "si apriva",
        distractors: ["si aprì", "si aprirà", "si apra"],
        distractorFeedback: [
          "«si aprì» è passato remoto puntuale: con «mentre… avanzava» serve un'azione in corso, l'imperfetto «si apriva».",
          "«si aprirà» è futuro: il contesto è al passato, serve l'imperfetto «si apriva».",
          "«si apra» è congiuntivo: qui racconti un fatto reale al passato, serve l'indicativo imperfetto «si apriva».",
        ],
        explanation: "Mentre introduce un'azione in corso nel passato: imperfetto indicativo.",
        concept: "indicativo imperfetto",
        targetLabel: "Azione durativa nel passato",
      },
      {
        context: "Domani la squadra ___ il circuito.",
        correct: "controllerà",
        distractors: ["controllò", "controllava", "controlli"],
        distractorFeedback: [
          "«controllò» è passato remoto: «domani» indica futuro, serve «controllerà».",
          "«controllava» è imperfetto (passato): «domani» è futuro, serve «controllerà».",
          "«controlli» non è futuro (è congiuntivo/presente): con «domani» serve il futuro «controllerà».",
        ],
        explanation: "Domani indica futuro: futuro semplice indicativo.",
        concept: "indicativo futuro semplice",
        targetLabel: "Futuro",
      },
      {
        context: "La frase 'noi avevamo verificato i dati' usa quale modo e tempo?",
        correct: "indicativo trapassato prossimo",
        distractors: ["congiuntivo trapassato", "indicativo trapassato remoto", "indicativo passato remoto"],
        distractorFeedback: [
          "No: «avevamo verificato» ha l'ausiliare all'imperfetto indicativo, non al congiuntivo (che sarebbe «avessimo verificato»). È indicativo trapassato prossimo.",
          "No: il trapassato remoto usa l'ausiliare al passato remoto («ebbero verificato»); qui l'ausiliare è all'imperfetto («avevamo»), quindi trapassato prossimo.",
          "No: il passato remoto è una forma semplice (verificammo). Qui l'ausiliare all'imperfetto forma il trapassato prossimo.",
        ],
        explanation: "Avevamo + participio passato forma il trapassato prossimo dell'indicativo.",
        concept: "riconoscimento tempi composti",
        targetLabel: "Riconosci modo e tempo",
      },
      {
        context: "Scrivi la forma corretta: se il segnale è stabile, noi ___ la porta. (aprire, presente)",
        correct: "apriamo",
        distractors: ["apre", "apriremo", "apriremmo"],
        distractorFeedback: [
          "«apre» è terza persona singolare (lui/lei). Il soggetto è «noi»: «apriamo».",
          "«apriremo» è futuro: la consegna chiede il presente, «apriamo».",
          "«apriremmo» è condizionale: serve il presente indicativo «apriamo».",
        ],
        explanation: "Noi + presente indicativo del verbo aprire: apriamo.",
        concept: "coniugazione presente",
        targetLabel: "Scrivi la forma verbale",
        typed: true,
      },
      {
        context: "Adesso il tecnico ___ il cavo difettoso.",
        correct: "sostituisce",
        distractors: ["sostituiva", "sostituirà", "sostituito"],
        distractorFeedback: [
          "«sostituiva» è imperfetto: «adesso» richiede il presente «sostituisce».",
          "«sostituirà» è futuro: il contesto dice che l'azione avviene adesso.",
          "«sostituito» è participio passato: da solo non regge la frase.",
        ],
        explanation: "Adesso indica presente: terza persona singolare «sostituisce».",
        concept: "indicativo presente",
        targetLabel: "Azione presente",
      },
      {
        context: "Poco fa la console ___ un avviso.",
        correct: "ha mostrato",
        distractors: ["mostrava", "mostrerà", "mostrando"],
        distractorFeedback: [
          "«mostrava» è imperfetto: poco fa indica un evento concluso, «ha mostrato».",
          "«mostrerà» è futuro: il fatto è già avvenuto.",
          "«mostrando» è gerundio e non completa la frase come predicato.",
        ],
        explanation: "Poco fa segnala passato vicino concluso: passato prossimo.",
        concept: "indicativo passato prossimo",
        targetLabel: "Passato vicino",
      },
      {
        context: "Da bambino, Eli ___ spesso il diario delle missioni.",
        correct: "leggeva",
        distractors: ["lesse", "leggerà", "legga"],
        distractorFeedback: [
          "«lesse» è passato remoto puntuale: «spesso» richiede l'imperfetto abituale «leggeva».",
          "«leggerà» è futuro: il contesto è nel passato.",
          "«legga» è congiuntivo: qui si racconta un'abitudine reale.",
        ],
        explanation: "Spesso nel passato indica abitudine: imperfetto indicativo.",
        concept: "indicativo imperfetto",
        targetLabel: "Abitudine nel passato",
      },
      {
        context: "Fra un minuto il sistema ___ il controllo.",
        correct: "ripeterà",
        distractors: ["ripeté", "ripeteva", "ripeta"],
        distractorFeedback: [
          "«ripeté» è passato remoto: fra un minuto indica futuro.",
          "«ripeteva» è imperfetto: non indica un'azione futura.",
          "«ripeta» è congiuntivo/imperativo formale, non futuro semplice.",
        ],
        explanation: "Fra un minuto indica futuro: «ripeterà».",
        concept: "indicativo futuro semplice",
        targetLabel: "Futuro vicino",
      },
      {
        context: "La frase 'voi avete controllato il log' usa quale tempo?",
        correct: "passato prossimo",
        distractors: ["trapassato prossimo", "futuro anteriore", "imperfetto"],
        distractorFeedback: [
          "Il trapassato prossimo sarebbe «avevate controllato»: qui c'è «avete controllato».",
          "Il futuro anteriore sarebbe «avrete controllato»: qui l'ausiliare è al presente.",
          "L'imperfetto sarebbe «controllavate»: qui c'è un tempo composto.",
        ],
        explanation: "Avete + participio passato forma il passato prossimo.",
        concept: "riconoscimento tempi composti",
        targetLabel: "Riconosci il tempo",
      },
      {
        context: "Scrivi la forma corretta: tu ___ il codice nel registro. (scrivere, presente)",
        correct: "scrivi",
        distractors: ["scrive", "scriverai", "scrivesti"],
        distractorFeedback: [
          "«scrive» è terza persona singolare; con tu serve «scrivi».",
          "«scriverai» è futuro, ma la consegna chiede il presente.",
          "«scrivesti» è passato remoto, non presente.",
        ],
        explanation: "Tu + presente indicativo di scrivere: scrivi.",
        concept: "coniugazione presente",
        targetLabel: "Scrivi la forma verbale",
        typed: true,
      },
      {
        context: "Scrivi la forma corretta: loro ___ la misura. (ripetere, presente)",
        correct: "ripetono",
        distractors: ["ripete", "ripetiamo", "ripeteranno"],
        distractorFeedback: [
          "«ripete» è terza singolare; loro richiede «ripetono».",
          "«ripetiamo» è prima persona plurale (noi).",
          "«ripeteranno» è futuro; la consegna chiede il presente.",
        ],
        explanation: "Loro + presente indicativo di ripetere: ripetono.",
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
        distractors: ["essere sostituito", "sostituisca", "sostituirebbe"],
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
      {
        context: "È possibile che il sensore ___ un falso allarme.",
        correct: "segnali",
        distractors: ["segnala", "segnalò", "segnalerà"],
        explanation: "È possibile che richiede il congiuntivo presente: segnali.",
        concept: "congiuntivo presente",
        targetLabel: "Possibilità",
      },
      {
        context: "Vorrei che tu ___ la fonte prima di confermare.",
        correct: "controllassi",
        distractors: ["controllavi", "controlli", "controllerai"],
        explanation: "Vorrei che richiede congiuntivo imperfetto: controllassi.",
        concept: "congiuntivo imperfetto",
        targetLabel: "Desiderio",
      },
      {
        context: "Se il dato fosse stabile, noi ___ la procedura.",
        correct: "avvieremmo",
        distractors: ["avviamo", "avviassimo", "avvieremo"],
        explanation: "Con se + congiuntivo imperfetto, la conseguenza usa il condizionale presente.",
        concept: "condizionale presente",
        targetLabel: "Conseguenza ipotetica",
      },
      {
        context: "Prima di uscire, ___ il registro.",
        correct: "salva",
        distractors: ["salvando", "salvato", "salveresti"],
        explanation: "È un comando diretto alla seconda persona: imperativo «salva».",
        concept: "imperativo presente",
        targetLabel: "Comando diretto",
      },
      {
        context: "Dopo ___ il log, Eli corresse il rapporto.",
        correct: "aver letto",
        distractors: ["leggerebbe", "avesse letto", "leggendo"],
        explanation: "Dopo + infinito composto indica un'azione precedente: aver letto.",
        concept: "infinito composto",
        targetLabel: "Azione precedente",
      },
      {
        context: "Scrivi la forma corretta: dubito che loro ___ la causa. (capire, congiuntivo presente)",
        correct: "capiscano",
        distractors: ["capiscono", "capiranno", "capivano"],
        explanation: "Dubitare richiede il congiuntivo: loro capiscano.",
        concept: "congiuntivo presente",
        targetLabel: "Scrivi il congiuntivo",
        typed: true,
      },
      {
        context: "Scrivi la forma corretta: se potessi, io ___ il test. (rifare, condizionale presente)",
        correct: "rifarei",
        distractors: ["rifaccio", "rifacessi", "rifarò"],
        explanation: "La conseguenza ipotetica usa il condizionale presente: rifarei.",
        concept: "condizionale presente",
        targetLabel: "Scrivi il condizionale",
        typed: true,
      },
    ];
    const advanced: VerbMasteryItem[] = [
      {
        context: "Se il tecnico ___ il cavo, il corto non sarebbe continuato.",
        correct: "avesse isolato",
        distractors: ["avrebbe isolato", "isolerebbe", "avrà isolato"],
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
      {
        context: "Se la fonte ___ stata verificata, il rapporto sarebbe più solido.",
        correct: "fosse",
        distractors: ["sarebbe", "è", "sarà"],
        explanation: "Nella subordinata con se dell'ipotesi irreale serve il congiuntivo imperfetto: fosse stata.",
        concept: "congiuntivo imperfetto",
        targetLabel: "Periodo ipotetico",
      },
      {
        context: "Il dato, ___ due volte, può entrare nella sintesi.",
        correct: "controllato",
        distractors: ["controllando", "controllare", "controlli"],
        explanation: "Controllato è participio passato con valore passivo: dato che è stato controllato.",
        concept: "participio passato",
        targetLabel: "Forma implicita",
      },
      {
        context: "___ il rapporto, il supervisore autorizzò il riavvio.",
        correct: "Letto",
        distractors: ["Leggendo", "Leggere", "Leggerebbe"],
        explanation: "Letto il rapporto equivale a dopo che il rapporto fu letto: participio assoluto.",
        concept: "participio assoluto",
        targetLabel: "Forma implicita avanzata",
      },
      {
        context: "Scrivi la forma corretta: se il log fosse stato chiaro, tu ___ prima. (capire, condizionale passato)",
        correct: "avresti capito",
        distractors: ["capiresti", "avessi capito", "capivi"],
        explanation: "La conseguenza non realizzata nel passato usa il condizionale passato: avresti capito.",
        concept: "condizionale passato",
        targetLabel: "Scrivi il condizionale passato",
        typed: true,
      },
      {
        context: "Scrivi la forma corretta: temevo che il modulo ___ energia. (perdere, congiuntivo imperfetto)",
        correct: "perdesse",
        distractors: ["perde", "perderà", "perderebbe"],
        explanation: "Temevo che richiede il congiuntivo imperfetto: perdesse.",
        concept: "congiuntivo imperfetto",
        targetLabel: "Scrivi il congiuntivo imperfetto",
        typed: true,
      },
    ];
    const pool = level >= 6 ? [...base, ...intermediate, ...advanced] : level >= 4 ? [...base, ...intermediate] : base;
    const item = random.pick(pool);
    // Typed (production) ONLY for items authored with an explicit cue in the
    // context — "Scrivi la forma corretta: … (infinito, modo/tempo)" — so the
    // answer is uniquely determined. Items written for tile selection (no cue)
    // would be ambiguous if typed, so they stay as tiles.
    const typed = item.typed === true;
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, item.distractorFeedback?.[choiceIndex] ?? `Modo/tempo non adatto: qui serve ${item.concept} → «${item.correct}». ${item.explanation}`)),
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
      { sentence: "Il tecnico isola il cavo danneggiato", concept: "soggetto-verbo-complemento con aggettivo" },
      { sentence: "La console mostra il messaggio corretto", concept: "soggetto-verbo-complemento" },
      { sentence: "Il rapporto collega causa ed effetto", concept: "coesione logica" },
      { sentence: "La chiave apre il vano sicuro", concept: "soggetto-verbo-oggetto" },
      { sentence: "Il tester conferma la misura stabile", concept: "soggetto-verbo-complemento con aggettivo" },
      { sentence: "La squadra elimina il dettaglio inutile", concept: "lessico e pertinenza" },
      { sentence: "Il registro conserva solo prove verificabili", concept: "ordine naturale con quantificatore" },
      { sentence: "Nora segnala una fonte non verificata", concept: "soggetto-verbo-complemento esteso" },
      { sentence: "Il modulo invia un avviso prudente", concept: "registro e precisione" },
      { sentence: "La frase separa fatto e opinione", concept: "pensiero critico" },
      { sentence: "Il sensore misura la temperatura ogni minuto", concept: "complemento di tempo in fondo" },
      { sentence: "La porta resta chiusa senza conferma", concept: "predicato nominale e complemento" },
    ];
    const advanced = [
      { sentence: "Il tecnico sostituisce il fusibile prima di alimentare il circuito", concept: "subordinata temporale finale" },
      { sentence: "Il sistema invia il rapporto dopo aver verificato i dati", concept: "subordinata temporale finale" },
      { sentence: "La pompa riduce la pressione quando la temperatura sale", concept: "subordinata di tempo con quando" },
      { sentence: "Il registro resta valido se la seconda fonte conferma la misura", concept: "subordinata condizionale" },
      { sentence: "Il rapporto è chiaro quando separa causa effetto e controllo", concept: "criterio di chiarezza" },
      { sentence: "La conclusione resta provvisoria finché manca una seconda prova", concept: "subordinata temporale con finché" },
      { sentence: "Il tecnico annota la fonte affinché il rapporto sia verificabile", concept: "subordinata finale" },
      { sentence: "La squadra non procede se il tester segnala corto", concept: "condizione negativa" },
      { sentence: "Il diario diventa utile quando elimina i dettagli decorativi", concept: "subordinata di tempo e criterio" },
      { sentence: "La prova sostiene la tesi solo se è pertinente", concept: "condizione argomentativa" },
      { sentence: "Il sistema blocca l'avvio perché manca la chiave", concept: "causa esplicita" },
      { sentence: "Il rapporto distingue i fatti dalle interpretazioni personali", concept: "complemento di separazione" },
      { sentence: "La console accetta il comando dopo la verifica finale", concept: "sequenza temporale" },
    ];
    const item = random.bool(0.62)
      ? this.parametricItalianWordOrderItem(random, level)
      : random.pick(level >= 4 ? [...pool, ...advanced] : pool);
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

  private parametricItalianWordOrderItem(random: Random, level: number): { sentence: string; concept: string } {
    const everyday = [
      { subject: "La squadra", verb: "controlla", object: "la lista", tail: "prima della partenza", concept: "sequenza quotidiana" },
      { subject: "Il compagno", verb: "spiega", object: "il passaggio", tail: "con un esempio semplice", concept: "chiarezza nello studio" },
      { subject: "La famiglia", verb: "prepara", object: "la cena", tail: "dopo la spesa", concept: "ordine temporale quotidiano" },
      { subject: "Il telefono", verb: "mostra", object: "una notifica", tail: "durante la lezione", concept: "soggetto-verbo-complemento" },
      { subject: "La biblioteca", verb: "apre", object: "la sala studio", tail: "alle tre", concept: "informazione di orario" },
      { subject: "Il vicino", verb: "restituisce", object: "la chiave", tail: "prima di uscire", concept: "azione e tempo" },
      { subject: "La farmacia", verb: "consegna", object: "la medicina", tail: "con lo scontrino", concept: "azione e complemento" },
      { subject: "Il treno", verb: "raggiunge", object: "la stazione", tail: "senza ritardo", concept: "spostamento e modo" },
      { subject: "La palestra", verb: "organizza", object: "un allenamento", tail: "per la squadra", concept: "scopo e destinatario" },
      { subject: "Il parco", verb: "offre", object: "uno spazio tranquillo", tail: "dopo la scuola", concept: "descrizione utile" },
      { subject: "La ricetta", verb: "indica", object: "gli ingredienti", tail: "in ordine", concept: "ordine informativo" },
      { subject: "Il messaggio", verb: "chiarisce", object: "l'appuntamento", tail: "senza ambiguità", concept: "precisione comunicativa" },
      { subject: "La pioggia", verb: "ritarda", object: "la partita", tail: "di pochi minuti", concept: "causa quotidiana" },
      { subject: "Il quaderno", verb: "conserva", object: "gli appunti", tail: "della verifica", concept: "studio e memoria" },
      { subject: "La mappa", verb: "mostra", object: "il percorso", tail: "fino alla biblioteca", concept: "indicazione di luogo" },
      { subject: "Il prezzo", verb: "cambia", object: "la scelta", tail: "durante la spesa", concept: "causa e decisione" },
    ];
    const complex = [
      "Se il messaggio è ambiguo la squadra chiede una spiegazione",
      "Quando la fonte è incerta il rapporto resta provvisorio",
      "Prima di confermare la risposta rileggi la domanda",
      "Dopo la verifica il compagno corregge gli errori principali",
      "Per arrivare puntuale controlla l'orario prima di uscire",
      "Se il prezzo aumenta confronta un prodotto simile",
      "Quando il tempo peggiora la classe sposta l'attività in palestra",
      "Prima di condividere una foto chiedi il permesso",
      "Dopo aver studiato la regola prova un esempio nuovo",
      "Se una frase sembra falsa cerca una prova verificabile",
      "Quando un amico sbaglia offri una correzione gentile",
      "Prima di comprare un oggetto controlla prezzo e qualità",
    ].map((sentence) => ({ sentence, concept: "subordinata in contesto reale" }));
    const proverbs = [
      "Meglio tardi che mai",
      "Sbagliando si impara",
      "L'unione fa la forza",
      "Chi va piano arriva lontano",
      "Il tempo è denaro",
      "Patti chiari mantengono lunga l'amicizia",
      "Non è tutto oro quel che luccica",
      "A buon intenditor bastano poche parole",
      "Meglio prevenire che curare",
      "Volere è potere",
    ].map((sentence) => ({ sentence, concept: "proverbio comune e ordine stabile" }));
    if (level >= 5 && random.bool(0.24)) {
      return random.pick(proverbs);
    }
    if (level >= 4 && random.bool(0.46)) {
      return random.pick(complex);
    }
    if (random.bool(0.18)) {
      const item = random.pick(everyday);
      return {
        sentence: `${item.subject} ${item.verb} ${item.object} ${item.tail}`,
        concept: item.concept,
      };
    }
    const humanSubjects = ["Il compagno", "La studentessa", "La squadra", "Il vicino", "La famiglia", "Il responsabile", "La classe", "Il tecnico", "L'amica", "Il gruppo"] as const;
    const humanActions = [
      { verb: "controlla", object: "la lista", concept: "controllo quotidiano" },
      { verb: "prepara", object: "la cartella", concept: "organizzazione personale" },
      { verb: "confronta", object: "due prezzi", concept: "confronto nella spesa" },
      { verb: "chiede", object: "un'indicazione", concept: "richiesta comunicativa" },
      { verb: "salva", object: "il documento", concept: "azione digitale" },
      { verb: "corregge", object: "la risposta", concept: "studio e revisione" },
      { verb: "ascolta", object: "la spiegazione", concept: "comprensione orale" },
      { verb: "condivide", object: "il compito", concept: "collaborazione" },
      { verb: "riassume", object: "il capitolo", concept: "sintesi" },
      { verb: "rispetta", object: "la regola", concept: "convivenza" },
      { verb: "prenota", object: "la visita", concept: "salute e organizzazione" },
      { verb: "compra", object: "il biglietto", concept: "spostamento quotidiano" },
    ] as const;
    const humanTails = ["prima di uscire", "dopo la lezione", "con calma", "senza fretta", "per aiutare il gruppo", "entro la scadenza", "durante la pausa", "nel quaderno", "sul telefono", "prima della verifica"] as const;
    const infoFrames = [
      { subject: "Il messaggio", verb: "chiarisce", object: "l'appuntamento" },
      { subject: "La mappa", verb: "mostra", object: "il percorso" },
      { subject: "Il diario", verb: "ricorda", object: "la scadenza" },
      { subject: "La ricetta", verb: "elenca", object: "gli ingredienti" },
      { subject: "L'orario", verb: "indica", object: "la partenza" },
      { subject: "Il rapporto", verb: "distingue", object: "fatti e opinioni" },
      { subject: "La notifica", verb: "segnala", object: "il ritardo" },
      { subject: "La fonte", verb: "conferma", object: "la notizia" },
      { subject: "Il grafico", verb: "mostra", object: "l'aumento" },
      { subject: "La tabella", verb: "confronta", object: "i dati" },
    ] as const;
    const infoTails = ["in modo chiaro", "con precisione", "senza dettagli inutili", "prima della decisione", "per tutti", "nel punto giusto", "con un esempio", "senza contraddizioni"] as const;
    const placeFrames = [
      { subject: "La biblioteca", verb: "apre", object: "la sala studio" },
      { subject: "La farmacia", verb: "consegna", object: "la medicina" },
      { subject: "Il supermercato", verb: "espone", object: "l'offerta" },
      { subject: "La palestra", verb: "organizza", object: "l'allenamento" },
      { subject: "La stazione", verb: "annuncia", object: "il binario" },
      { subject: "Il parco", verb: "offre", object: "uno spazio tranquillo" },
      { subject: "Il municipio", verb: "pubblica", object: "l'avviso" },
      { subject: "La scuola", verb: "prepara", object: "l'incontro" },
    ] as const;
    const placeTails = ["nel pomeriggio", "alle tre", "per la comunità", "senza ritardo", "durante la settimana", "prima della chiusura", "con un cartello chiaro", "per gli studenti"] as const;
    if (random.bool(0.42)) {
      const action = random.pick(humanActions);
      return {
        sentence: `${random.pick(humanSubjects)} ${action.verb} ${action.object} ${random.pick(humanTails)}`,
        concept: action.concept,
      };
    }
    if (random.bool(0.55)) {
      const frame = random.pick(infoFrames);
      return {
        sentence: `${frame.subject} ${frame.verb} ${frame.object} ${random.pick(infoTails)}`,
        concept: "informazione chiara in contesto reale",
      };
    }
    const frame = random.pick(placeFrames);
    return {
      sentence: `${frame.subject} ${frame.verb} ${frame.object} ${random.pick(placeTails)}`,
      concept: "luogo pubblico e informazione utile",
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
    if (type === "punctuation-fix") return ["accenti", "apostrofi", "ortografia"];
    if (type === "argument-sort") return ["fatto e opinione", "ipotesi e prova", "pensiero critico"];
    return ["comprensione", "informazioni utili", "pensiero critico"];
  }

  private languageMinigamePurpose(type: LanguageMinigameType): string {
    if (type === "agreement-sprint") return "Allena riconoscimento rapido di accordi, soggetti reali e forme verbali corrette.";
    if (type === "connector-route") return "Allena scelta dei connettivi in base a causa, contrasto, tempo, condizione e scopo.";
    if (type === "word-order") return "Allena la costruzione della frase: ordinare le parole per produrre un comando chiaro ed eseguibile.";
    if (type === "lexicon-lab") return "Allena vocabolario preciso: scegliere parole adatte a prova, ipotesi, fonte, sintesi e registro tecnico.";
    if (type === "verb-mastery") return "Allena padronanza dei verbi: riconoscere modo, tempo, persona e scegliere o produrre la forma corretta in contesto.";
    if (type === "punctuation-fix") return "Allena ortografia: accento (è/perché/più), apostrofo (po'/un'/l'/d'accordo) e omofoni (c'è, sì/si, se/sé).";
    if (type === "argument-sort") return "Allena il pensiero critico: distinguere fatti verificabili, opinioni personali, ipotesi da controllare e prove che sostengono una conclusione.";
    return "Allena lettura selettiva: separare dati utili, prove, opinioni e dettagli decorativi.";
  }

  private languageMinigameMethod(type: LanguageMinigameType): string {
    if (type === "agreement-sprint") return "Trova il soggetto, controlla singolare/plurale e verifica che verbo e aggettivo concordino.";
    if (type === "connector-route") return "Nomina il rapporto tra le due frasi: causa, conseguenza, contrasto, tempo, condizione o scopo.";
    if (type === "word-order") return "Parti dal soggetto, aggiungi il verbo, poi i complementi; metti il tempo o la condizione in fondo.";
    if (type === "lexicon-lab") return "Leggi lo scopo della frase e scegli la parola più precisa: non quella più familiare, ma quella che riduce ambiguità.";
    if (type === "verb-mastery") return "Trova indicatore temporale o reggenza, scegli modo e tempo, poi controlla persona e concordanza.";
    if (type === "punctuation-fix") return "Chiediti che parola è: verbo essere → è; troncamento → apostrofo (po', un'); congiunzione/pronome → senza accento o con accento secondo la regola.";
    if (type === "argument-sort") return "Chiediti: è misurabile e verificabile (fatto)? è un giudizio personale (opinione)? è una supposizione da verificare (ipotesi)? è un dato che sostiene una conclusione (prova)?";
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
