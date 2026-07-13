import type {
  DifficultyLevel,
  GeneratedLatinMinigame,
  GeneratedLatinPuzzle,
  LatinMinigamePrompt,
  LatinMinigameTile,
  LatinMinigameType,
} from "../ProceduralTypes";
import type { Random } from "../Random";
import {
  LATIN_PERSONS,
  distinctiveCases,
  latinAdjective12,
  latinCaseFunctions,
  latinItemsForTier,
  latinNounForm,
  type LatinCase,
  type LatinNumber,
  type LatinTense,
  type LatinTier,
  type LatinVerb,
} from "../../data/procedural/latinCurriculum";

const TENSE_LABEL: Record<LatinTense, string> = {
  presente: "presente indicativo",
  imperfetto: "imperfetto indicativo",
  futuro: "futuro semplice",
  perfetto: "perfetto indicativo",
  "congiuntivo-presente": "congiuntivo presente",
  "presente-passivo": "presente indicativo passivo",
};

/**
 * Generatore di minigiochi di Latino per il biennio (liceo scientifico).
 * Restituisce un {@link GeneratedLatinPuzzle} con `minigame.prompts` a tessere,
 * come i generatori di italiano/inglese, così il rendering riusa lo stesso
 * schema a tre pannelli.
 */
export class LatinGenerator {
  generate(random: Random, difficultyLevel: DifficultyLevel = 1): GeneratedLatinPuzzle {
    return this.generateMinigame(random, difficultyLevel);
  }

  generateMinigame(random: Random, difficultyLevel = 1, preferredTypes: LatinMinigameType[] = []): GeneratedLatinPuzzle {
    const level = Math.max(1, Math.min(8, difficultyLevel));
    const tier: LatinTier = level >= 5 ? 2 : 1;
    const available: LatinMinigameType[] = tier >= 2
      ? ["declension", "conjugation", "verb-analysis", "case-function", "agreement", "vocab-match", "translation", "syntax-clause"]
      : ["declension", "conjugation", "verb-analysis", "case-function", "agreement", "vocab-match", "translation"];
    const requested = preferredTypes.filter((type) => available.includes(type) || preferredTypes.length === 1);
    const type = random.pick(requested.length > 0 ? requested : available);

    const prompt = this.buildPrompt(random.fork(type), type, tier);
    void level;
    const minigame: GeneratedLatinMinigame = {
      type,
      title: `Latino: ${prompt.targetLabel}`,
      durationMs: this.reflectiveType(type) ? 200_000 : 120_000,
      instructions: "leggi la voce latina, individua la regola e scegli la risposta corretta.",
      scoringRule: "Ragiona sulla forma prima di scegliere: caso, numero, tempo o funzione.",
      prompts: [prompt],
      competencies: prompt ? [this.competencyFor(type)] : [],
      reflective: this.reflectiveType(type),
    };
    return {
      id: `latin-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      prompt: prompt.prompt,
      hints: this.hintsFor(type),
      competencies: [this.competencyFor(type), "latino.traduzione"],
      difficultyLabel: `Anno ${tier} · ${prompt.targetLabel}`,
      conceptTags: [prompt.concept],
      learningPurpose: this.purposeFor(type),
      method: this.methodFor(type),
      minigame,
    };
  }

  private reflectiveType(type: LatinMinigameType): boolean {
    return type === "translation" || type === "syntax-clause";
  }

  private competencyFor(type: LatinMinigameType): string {
    switch (type) {
      case "declension": return "latino.declinazioni";
      case "conjugation": return "latino.coniugazioni";
      case "verb-analysis": return "latino.morfologiaVerbale";
      case "case-function": return "latino.casiFunzioni";
      case "agreement": return "latino.concordanza";
      case "vocab-match": return "latino.lessico";
      case "translation": return "latino.traduzione";
      case "syntax-clause": return "latino.sintassi";
    }
  }

  private buildPrompt(random: Random, type: LatinMinigameType, tier: LatinTier): LatinMinigamePrompt {
    switch (type) {
      case "declension": return this.buildDeclension(random, tier);
      case "conjugation": return this.buildConjugation(random, tier);
      case "verb-analysis": return this.buildVerbAnalysis(random, tier);
      case "case-function": return this.buildCaseFunction(random, tier);
      case "agreement": return this.buildAgreement(random, tier);
      case "vocab-match": return this.buildVocab(random, tier);
      case "translation": return this.buildTranslation(random, tier);
      case "syntax-clause": return this.buildSyntax(random);
    }
  }

  /** Tutte le forme caso×numero di un sostantivo (per distrattori plausibili). */
  private allNounForms(noun: Parameters<typeof latinNounForm>[0]): Array<{ form: string; kase: LatinCase; number: LatinNumber }> {
    const forms: Array<{ form: string; kase: LatinCase; number: LatinNumber }> = [];
    for (const number of ["singolare", "plurale"] as LatinNumber[]) {
      for (const kase of ["nominativo", "genitivo", "dativo", "accusativo", "ablativo", "vocativo"] as LatinCase[]) {
        forms.push({ form: latinNounForm(noun, kase, number), kase, number });
      }
    }
    return forms;
  }

  private tiles(random: Random, correct: string, correctFeedback: string, distractors: Array<{ label: string; feedback: string }>): LatinMinigameTile[] {
    const used = new Set<string>([correct]);
    const picked: Array<{ label: string; feedback: string }> = [];
    for (const distractor of distractors) {
      if (used.has(distractor.label)) continue;
      used.add(distractor.label);
      picked.push(distractor);
      if (picked.length === 3) break;
    }
    const all: LatinMinigameTile[] = [
      { id: "correct", label: correct, isCorrect: true, feedback: correctFeedback },
      ...picked.map((distractor, index) => ({ id: `distractor-${index}`, label: distractor.label, isCorrect: false, feedback: distractor.feedback })),
    ];
    return random.shuffle(all);
  }

  // ---- costruttori per tipo ----

  private buildDeclension(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const { nouns } = latinItemsForTier(tier);
    const noun = random.pick(nouns);
    const target = random.pick(distinctiveCases(noun));
    const correct = latinNounForm(noun, target.kase, target.number);
    const others = this.allNounForms(noun)
      .filter((slot) => slot.form !== correct)
      .map((slot) => ({ label: slot.form, feedback: `«${slot.form}» è ${slot.kase} ${slot.number}, non ${target.kase} ${target.number}.` }));
    return {
      id: `decl-${noun.nomSg}-${target.kase}-${target.number}`,
      type: "declension",
      prompt: `Qual è il ${target.kase} ${target.number} di «${noun.nomSg}»?`,
      context: `${noun.nomSg}, ${latinNounForm(noun, "genitivo", "singolare")} (${noun.it}) — declinazione: ${this.declLabel(noun.type)}`,
      targetLabel: "Le declinazioni",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, correct, `Esatto: «${correct}» è il ${target.kase} ${target.number}.`, random.shuffle(others)),
      solutionLabels: [correct],
      explanation: `Alla radice «${noun.stem}» si aggiunge la desinenza del ${target.kase} ${target.number} della ${this.declLabel(noun.type)}.`,
      concept: "morfologia nominale",
      signature: `decl-${noun.nomSg}-${target.kase}-${target.number}`,
      reference: "Ricorda: la desinenza dipende da declinazione, caso e numero.",
    };
  }

  private buildCaseFunction(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const functions = latinCaseFunctions.filter((entry) => entry.tier <= tier || tier >= 1);
    const target = random.pick(functions);
    const others = functions.filter((entry) => entry.kase !== target.kase)
      .map((entry) => ({ label: entry.funzione, feedback: `«${entry.funzione}» risponde a: ${entry.domanda}` }));
    return {
      id: `casefn-${target.kase}`,
      type: "case-function",
      prompt: `Che funzione logica ha, di norma, il ${target.kase}?`,
      context: `Caso: ${target.kase} — domanda tipica: ${target.domanda}`,
      targetLabel: "Funzioni dei casi",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, target.funzione, `Esatto: il ${target.kase} esprime il ${target.funzione}.`, random.shuffle(others)),
      solutionLabels: [target.funzione],
      explanation: `Il ${target.kase} risponde alla domanda: ${target.domanda}`,
      concept: "sintassi dei casi",
      signature: `casefn-${target.kase}`,
    };
  }

  private buildConjugation(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const { verbs } = latinItemsForTier(tier);
    const verb = random.pick(verbs);
    const tense = this.pickTense(random, verb, tier);
    const person = random.integer(0, 5);
    const forms = verb.forms[tense]!;
    const correct = forms[person];
    const others: Array<{ label: string; feedback: string }> = [];
    forms.forEach((form, index) => { if (index !== person && form !== correct) others.push({ label: form, feedback: `«${form}» è la ${LATIN_PERSONS[index]} persona, non la ${LATIN_PERSONS[person]}.` }); });
    return {
      id: `conj-${verb.lemma}-${tense}-${person}`,
      type: "conjugation",
      prompt: `${TENSE_LABEL[tense]}, ${LATIN_PERSONS[person]} di «${verb.lemma}» (${verb.it}): quale forma?`,
      context: `Verbo: ${verb.lemma} (${verb.it}) — ${this.conjLabel(verb)}`,
      targetLabel: "Il sistema verbale",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, correct, `Esatto: «${correct}» è la ${LATIN_PERSONS[person]} del ${TENSE_LABEL[tense]}.`, random.shuffle(others)),
      solutionLabels: [correct],
      explanation: `Nel ${TENSE_LABEL[tense]} la ${LATIN_PERSONS[person]} di «${verb.lemma}» è «${correct}».`,
      concept: "morfologia verbale",
      signature: `conj-${verb.lemma}-${tense}-${person}`,
    };
  }

  private buildVerbAnalysis(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const { verbs } = latinItemsForTier(tier);
    const verb = random.pick(verbs);
    const tense = this.pickTense(random, verb, tier);
    const person = random.integer(0, 5);
    const form = verb.forms[tense]![person];
    const correct = TENSE_LABEL[tense];
    const others = (Object.keys(verb.forms) as LatinTense[])
      .filter((other) => other !== tense)
      .map((other) => ({ label: TENSE_LABEL[other], feedback: `«${TENSE_LABEL[other]}» ha forme diverse (es. «${verb.forms[other]![person]}»).` }));
    return {
      id: `vanalysis-${verb.lemma}-${tense}-${person}`,
      type: "verb-analysis",
      prompt: `Che tempo/modo è «${form}» (da ${verb.lemma})?`,
      context: `Voce verbale: ${form} — verbo ${verb.lemma} (${verb.it})`,
      targetLabel: "Analisi verbale",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, correct, `Esatto: «${form}» è ${correct}.`, random.shuffle(others)),
      solutionLabels: [correct],
      explanation: `La desinenza e il tema di «${form}» indicano il ${correct}.`,
      concept: "analisi della voce verbale",
      signature: `vanalysis-${verb.lemma}-${tense}-${person}`,
    };
  }

  private buildAgreement(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const items = latinItemsForTier(tier);
    const noun = random.pick(items.nouns);
    const adjective = random.pick(items.adjectives.filter((entry) => entry.clazz === "1-2"));
    const target = random.pick(distinctiveCases(noun));
    const nounForm = latinNounForm(noun, target.kase, target.number);
    const correct = latinAdjective12(adjective.base, noun.gender, target.kase, target.number);
    // Pool ampio (generi × casi): maschile e neutro condividono molte desinenze,
    // quindi servono più candidati per avere sempre 3 distrattori distinti.
    const others: Array<{ label: string; feedback: string }> = [];
    const cases: LatinCase[] = ["nominativo", "genitivo", "dativo", "accusativo", "ablativo"];
    for (const gender of ["m", "f", "n"] as Array<"m" | "f" | "n">) {
      for (const number of ["singolare", "plurale"] as LatinNumber[]) {
        for (const kase of cases) {
          if (gender === noun.gender && kase === target.kase && number === target.number) continue;
          const wrong = latinAdjective12(adjective.base, gender, kase, number);
          const reason = gender !== noun.gender
            ? `«${wrong}» è di genere ${this.genderLabel(gender)}, ma «${noun.nomSg}» è ${this.genderLabel(noun.gender)}.`
            : `«${wrong}» è ${kase} ${number}, non concorda in caso/numero.`;
          others.push({ label: wrong, feedback: reason });
        }
      }
    }
    return {
      id: `agree-${noun.nomSg}-${adjective.base}-${target.kase}-${target.number}`,
      type: "agreement",
      prompt: `Quale forma di «${adjective.base}» (${adjective.it}) concorda con «${nounForm}»?`,
      context: `${nounForm} = ${noun.nomSg} al ${target.kase} ${target.number} (genere ${this.genderLabel(noun.gender)})`,
      targetLabel: "Concordanza",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, correct, `Esatto: «${correct}» concorda in genere, numero e caso.`, random.shuffle(others)),
      solutionLabels: [correct],
      explanation: `L'aggettivo concorda con il nome in genere (${this.genderLabel(noun.gender)}), numero (${target.number}) e caso (${target.kase}).`,
      concept: "concordanza aggettivo-sostantivo",
      signature: `agree-${noun.nomSg}-${adjective.base}-${target.kase}-${target.number}`,
    };
  }

  private buildVocab(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const { vocab } = latinItemsForTier(tier);
    const word = random.pick(vocab);
    const others = vocab.filter((entry) => entry.it !== word.it).map((entry) => ({ label: entry.it, feedback: `«${entry.it}» traduce «${entry.la}».` }));
    return {
      id: `vocab-${word.la}`,
      type: "vocab-match",
      prompt: `Che cosa significa «${word.la}»?`,
      context: `Vocabolo latino: ${word.la}`,
      targetLabel: "Lessico latino",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, word.it, `Esatto: «${word.la}» significa «${word.it}».`, random.shuffle(others)),
      solutionLabels: [word.it],
      explanation: `«${word.la}» = «${word.it}».`,
      concept: "lessico ad alta frequenza",
      signature: `vocab-${word.la}`,
    };
  }

  private buildTranslation(random: Random, tier: LatinTier): LatinMinigamePrompt {
    const { sentences } = latinItemsForTier(tier);
    const sentence = random.pick(sentences);
    const others = sentence.distrattori.map((label) => ({ label, feedback: "Controlla soggetto (nominativo), oggetto (accusativo) e numero del verbo." }));
    return {
      id: `transl-${sentence.la}`,
      type: "translation",
      prompt: "Quale traduzione è corretta?",
      context: sentence.la,
      targetLabel: "Traduzione",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, sentence.it, "Esatto: hai riconosciuto casi, funzioni e numero del verbo.", random.shuffle(others)),
      solutionLabels: [sentence.it],
      explanation: `«${sentence.la}» → «${sentence.it}». Individua prima soggetto e verbo, poi i complementi.`,
      concept: "traduzione dal latino",
      signature: `transl-${sentence.la}`,
    };
  }

  private buildSyntax(random: Random): LatinMinigamePrompt {
    const { clauses } = latinItemsForTier(2);
    const clause = random.pick(clauses);
    const others = clauses.filter((entry) => entry.tipo !== clause.tipo).map((entry) => ({ label: entry.tipo, feedback: `La ${entry.tipo} si riconosce da: ${entry.spia}.` }));
    return {
      id: `syntax-${clause.tipo}`,
      type: "syntax-clause",
      prompt: `Che tipo di proposizione è «${clause.la}»?`,
      context: `${clause.la}  (${clause.it})`,
      targetLabel: "Sintassi del periodo",
      requiredSelectionCount: 1,
      tiles: this.tiles(random, clause.tipo, `Esatto: è una ${clause.tipo} (spia: ${clause.spia}).`, random.shuffle(others)),
      solutionLabels: [clause.tipo],
      explanation: `La proposizione ${clause.tipo} si riconosce dalla spia «${clause.spia}».`,
      concept: "sintassi del periodo",
      signature: `syntax-${clause.tipo}`,
    };
  }

  // ---- helper ----

  private pickTense(random: Random, verb: LatinVerb, tier: LatinTier): LatinTense {
    const tenses = (Object.keys(verb.forms) as LatinTense[]).filter((tense) => (verb.tiers[tense] ?? 1) <= tier);
    return random.pick(tenses.length > 0 ? tenses : (Object.keys(verb.forms) as LatinTense[]));
  }

  private declLabel(type: string): string {
    if (type === "1") return "1ª declinazione";
    if (type.startsWith("2")) return "2ª declinazione";
    if (type.startsWith("3")) return "3ª declinazione";
    if (type === "4") return "4ª declinazione";
    return "5ª declinazione";
  }

  private conjLabel(verb: LatinVerb): string {
    return verb.conjugation === 0 ? "verbo sum (irregolare)" : `${verb.conjugation}ª coniugazione`;
  }

  private genderLabel(gender: "m" | "f" | "n"): string {
    return gender === "m" ? "maschile" : gender === "f" ? "femminile" : "neutro";
  }

  private hintsFor(type: LatinMinigameType): string[] {
    const common = "Analizza la desinenza: è lì che il latino segnala caso, numero, persona e tempo.";
    switch (type) {
      case "declension": return [common, "Individua la declinazione dal genitivo, poi applica la desinenza del caso richiesto.", "Radice + desinenza: non cambiare la radice."];
      case "conjugation": return [common, "Riconosci la coniugazione dalla vocale tematica, poi aggiungi la desinenza personale.", "Presente, imperfetto (-ba-) e futuro hanno segni diversi."];
      case "verb-analysis": return [common, "Cerca gli infissi: -ba- imperfetto, -bo/-bi- futuro (1ª-2ª), tema del perfetto per il perfetto.", "Il congiuntivo presente ha vocali -e-/-a-."];
      case "case-function": return ["Chiediti a quale domanda risponde il caso.", "Nominativo = soggetto, accusativo = oggetto, dativo = a chi.", "Genitivo = di chi/che cosa."];
      case "agreement": return ["L'aggettivo segue genere, numero e caso del nome, non la declinazione.", "Nome femminile 1ª → aggettivo in -a; neutro → in -um.", "Concorda, non copia la desinenza del nome."];
      case "vocab-match": return ["Cerca parole italiane derivate (es. bellum → bellico).", "Attento ai falsi amici.", "Ripassa il lessico ad alta frequenza."];
      case "translation": return ["Trova prima soggetto (nominativo) e verbo, poi i complementi.", "Controlla il numero del verbo: singolare o plurale?", "L'ordine latino è libero: guida i casi, non la posizione."];
      case "syntax-clause": return ["Parti dalla parola-spia (ut, cum, quod, dum).", "Controlla il modo del verbo: indicativo o congiuntivo?", "L'ablativo assoluto ha nome + participio in ablativo."];
    }
  }

  private purposeFor(type: LatinMinigameType): string {
    switch (type) {
      case "declension": return "Consolidare la morfologia nominale: riconoscere e formare i casi delle cinque declinazioni.";
      case "conjugation": return "Consolidare la morfologia verbale: formare i tempi delle quattro coniugazioni e di sum.";
      case "verb-analysis": return "Allenare l'analisi della voce verbale: tempo, modo e diatesi dalla forma.";
      case "case-function": return "Collegare il caso alla funzione logica nella frase.";
      case "agreement": return "Padroneggiare la concordanza tra aggettivo e sostantivo.";
      case "vocab-match": return "Ampliare il lessico latino di base ad alta frequenza.";
      case "translation": return "Comprendere e tradurre brevi frasi riconoscendo casi e funzioni.";
      case "syntax-clause": return "Riconoscere participio, ablativo assoluto e le principali subordinate.";
    }
  }

  private methodFor(type: LatinMinigameType): string {
    switch (type) {
      case "declension": return "Metodo: individua la declinazione (dal genitivo), isola la radice, applica la desinenza del caso e numero richiesti.";
      case "conjugation": return "Metodo: riconosci la coniugazione, scegli il tema (presente/perfetto), aggiungi il segno di tempo e la desinenza personale.";
      case "verb-analysis": return "Metodo: cerca gli infissi di tempo (-ba-, -bo-/-bi-) e la desinenza; il tema del perfetto segnala i tempi perfetti.";
      case "case-function": return "Metodo: chiediti a quale domanda risponde il caso, poi assegna la funzione logica.";
      case "agreement": return "Metodo: l'aggettivo concorda in genere, numero e caso con il nome; scegli la desinenza giusta per quel genere.";
      case "vocab-match": return "Metodo: sfrutta i derivati italiani e il contesto; diffida dei falsi amici.";
      case "translation": return "Metodo: individua soggetto (nominativo) e verbo, controlla il numero, poi colloca i complementi.";
      case "syntax-clause": return "Metodo: parti dalla parola-spia e dal modo del verbo per riconoscere il tipo di subordinata.";
    }
  }
}
