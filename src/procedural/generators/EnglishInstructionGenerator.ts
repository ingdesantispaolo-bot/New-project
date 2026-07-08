import { englishTemplates, type EnglishTemplate } from "../../data/procedural/englishTemplates";
import {
  englishVocabularyByMaxLevel,
  englishVocabularyCategoryLabels,
  englishVocabularyEntries,
  type EnglishVocabularyEntry,
} from "../../data/procedural/englishVocabularyBank";
import type {
  EnglishChallengeType,
  EnglishMinigamePrompt,
  EnglishMinigameTile,
  EnglishMinigameType,
  GeneratedEnglishMinigame,
  GeneratedEnglishPuzzle,
} from "../ProceduralTypes";
import { Random } from "../Random";

export class EnglishInstructionGenerator {
  generate(random: Random, difficultyLevel = 1, preferredTemplateIds: string[] = []): GeneratedEnglishPuzzle {
    // Levels grade difficulty, not exercise type: keep the full eligible pool at
    // every level so the mix of archetypes stays varied instead of collapsing to
    // the hardest band.
    const eligibleTemplates = englishTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const pool = eligibleTemplates.length > 0 ? eligibleTemplates : englishTemplates;
    const preferredPool = preferredTemplateIds.length > 0
      ? (eligibleTemplates.length > 0 ? eligibleTemplates : englishTemplates).filter((template) => preferredTemplateIds.includes(template.id))
      : [];
    const template = this.specializeTemplate(random.pick(preferredPool.length > 0 ? preferredPool : pool), random.fork("english-template"), difficultyLevel);
    const choices = random.shuffle([
      {
        id: `${template.id}-correct`,
        label: template.correctLabel,
        isCorrect: true,
        feedback: template.correctFeedback ?? "Sequenza operativa corretta: verbo, oggetto e condizione sono stati interpretati senza ambiguità.",
      },
      ...template.distractors.map((distractor, index) => ({
        id: `${template.id}-distractor-${index}`,
        label: distractor.label,
        isCorrect: false,
        feedback: distractor.feedback,
      })),
    ]);
    return this.buildPuzzle(template, choices, difficultyLevel);
  }

  generateMinigame(
    random: Random,
    difficultyLevel = 1,
    preferredTypes: EnglishMinigameType[] = [],
  ): GeneratedEnglishPuzzle {
    const level = Math.max(1, Math.min(8, difficultyLevel));
    const type = preferredTypes.length > 0
      ? random.pick(preferredTypes)
      : random.pick<EnglishMinigameType>([
        "action-relay",
        "sequence-switchboard",
        "data-command-scan",
        "grammar-fix",
        "sentence-build",
        "vocab-lab",
        "translation-match",
        "reading-detective",
        "error-diagnosis",
        "dialogue-response",
      ]);
    const minigame = this.buildMinigame(random.fork(type), level, type);
    const first = minigame.prompts[0];
    let choices: GeneratedEnglishPuzzle["choices"];
    if (type === "sentence-build") {
      // Word tiles are single words, so the repair-tab choices come from the
      // full sentence plus plausible wrong orderings.
      const sentence = first.solutionLabels.join(" ");
      const distractors = this.englishSentenceDistractors(random.fork("sb-base"), first.solutionLabels);
      choices = random.shuffle([sentence, ...distractors]).map((label, choiceIndex) => ({
        id: `sentence-build-choice-${choiceIndex}`,
        label,
        isCorrect: label === sentence,
        feedback: label === sentence
          ? "Correct order: subject, verb, then the rest of the sentence reads naturally."
          : "Wrong order: with the words like this the English sentence is not correct.",
      }));
    } else {
      choices = first.tiles.map((tile) => ({
        id: tile.id,
        label: tile.label,
        isCorrect: tile.isCorrect,
        feedback: tile.feedback,
      }));
    }
    const challengeType: EnglishChallengeType =
      type === "data-command-scan" ? "data-reading"
        : type === "sequence-switchboard" ? "sequence"
          : type === "grammar-fix" || type === "error-diagnosis" ? "vocabulary-in-context"
            : type === "vocab-lab" ? "vocabulary-in-context"
              : type === "translation-match" ? "translation-recognition"
                : type === "reading-detective" || type === "dialogue-response" ? "inference"
                : "command";
    return {
      id: `english-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      challengeType,
      scenario: "Training rapido del ponte operativo",
      taskPrompt: first.targetLabel,
      instruction: first.instruction,
      sourceText: first.context,
      dataPoints: first.dataPoints,
      choices,
      diagnosticSteps: [
        `Task: ${first.targetLabel}.`,
        "Find the action word, then check object, limiters and time words.",
        first.explanation,
      ],
      hints: [
        "Cerca prima il verbo: press, open, take, insert, wait, choose.",
        "Poi controlla le parole che cambiano tutto: not, only, before, after, until, below, above.",
        "Se ci sono dati, confrontali con la soglia prima di scegliere l'azione.",
      ],
      competencies: minigame.competencies,
      difficultyLabel: `Livello ${level} - sprint inglese operativo`,
      conceptTags: this.englishMinigameConcepts(type),
      learningPurpose: this.englishMinigamePurpose(type),
      commandGoal: "Trasformare molti micro-comandi inglesi in azioni sicure entro 60 secondi.",
      method: this.englishMinigameMethod(type),
      methodSteps: this.englishMinigameMethodSteps(type),
      glossary: first.glossary,
      minigame,
    };
  }

  private buildPuzzle(template: EnglishTemplate, choices: GeneratedEnglishPuzzle["choices"], difficultyLevel: number): GeneratedEnglishPuzzle {
    const conceptTags = template.conceptTags ?? this.defaultConceptTags(template.id);
    return {
      id: `english-${template.id}`,
      title: template.title ?? "Istruzione operativa esterna",
      challengeType: template.challengeType,
      scenario: template.scenario,
      taskPrompt: template.taskPrompt,
      instruction: template.instruction,
      sourceText: template.sourceText,
      dataPoints: template.dataPoints,
      choices,
      diagnosticSteps: template.diagnosticSteps,
      hints: template.hints ?? this.defaultHints(template.id),
      competencies: this.competenciesFor(template.id),
      difficultyLabel: `Livello ${Math.max(1, Math.min(8, difficultyLevel))} - ${this.levelName(difficultyLevel)}`,
      conceptTags,
      learningPurpose: template.learningPurpose ?? `Allena inglese operativo: ${conceptTags.join(", ")} in un comando da eseguire.`,
      commandGoal: template.commandGoal ?? "Trasforma l'istruzione inglese in una procedura sicura e non ambigua.",
      method: template.method ?? this.defaultMethod(template.challengeType),
      methodSteps: template.methodSteps ?? this.defaultMethodSteps(template.challengeType),
      glossary: template.glossary ?? this.defaultGlossary(template),
    };
  }

  private buildMinigame(random: Random, level: number, type: EnglishMinigameType): GeneratedEnglishMinigame {
    const promptCount = 18 + level;
    const prompts: EnglishMinigamePrompt[] = [];
    const usedSignatures = new Set<string>();
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniqueMinigamePrompt(random, level, type, index, usedSignatures);
      prompts.push(prompt);
      usedSignatures.add(prompt.signature);
    }
    const titles: Record<EnglishMinigameType, string> = {
      "action-relay": "Minigioco inglese: Action Relay",
      "sequence-switchboard": "Minigioco inglese: Sequence Switchboard",
      "data-command-scan": "Minigioco inglese: Data Command Scan",
      "grammar-fix": "Minigioco inglese: Grammar Fix",
      "sentence-build": "Minigioco inglese: Sentence Builder",
      "vocab-lab": "Minigioco inglese: Vocabulary Lab",
      "translation-match": "Minigioco inglese: Translation Match",
      "reading-detective": "Minigioco inglese: Reading Detective",
      "error-diagnosis": "Minigioco inglese: Error Diagnosis",
      "dialogue-response": "Minigioco inglese: Dialogue Response",
    };
    const instructions: Record<EnglishMinigameType, string> = {
      "action-relay": "clicca l'azione corretta leggendo verbo, oggetto e divieto.",
      "sequence-switchboard": "clicca l'azione che rispetta before, after, then, until o unless.",
      "data-command-scan": "clicca l'azione coerente con soglia, confronto o intervallo.",
      "grammar-fix": "scegli la forma corretta: tempo verbale, comparativo, modale, preposizione o quantificatore.",
      "sentence-build": "tocca le parole nell'ordine giusto per formare la frase o la domanda in inglese.",
      "vocab-lab": "scegli la parola inglese più adatta al contesto tecnico o scientifico.",
      "translation-match": "riconosci la traduzione italiana corretta di una parola o breve frase inglese.",
      "reading-detective": "leggi un breve log e scegli sia l'inferenza sia la prova testuale.",
      "error-diagnosis": "ripara una frase inglese e riconosci che tipo di errore conteneva.",
      "dialogue-response": "scegli la risposta inglese più adatta a scopo, registro e situazione.",
    };
    return {
      type,
      title: titles[type],
      durationMs: 60_000,
      instructions: instructions[type],
      scoringRule: "60 secondi: punti per risposte corrette e serie pulite, penalità per errori e aiuti. Non basta tradurre: devi eseguire il comando giusto.",
      prompts,
      competencies: Array.from(new Set([
        "inglese.istruzioni",
        "inglese.comprensione",
        "pensieroCritico",
        ...(type === "action-relay" ? ["inglese.lessico"] : []),
        ...(type === "sequence-switchboard" ? ["inglese.grammatica", "inglese.bilingue"] : []),
        ...(type === "data-command-scan" ? ["inglese.scientifico", "inglese.dati"] : []),
        ...(type === "grammar-fix" ? ["inglese.grammatica", "inglese.lessico"] : []),
        ...(type === "sentence-build" ? ["inglese.grammatica", "inglese.scritturaBreve"] : []),
        ...(type === "vocab-lab" ? ["inglese.lessico", "inglese.scientifico", "inglese.comprensione"] : []),
        ...(type === "translation-match" ? ["inglese.lessico", "inglese.bilingue", "inglese.comprensione"] : []),
        ...(type === "reading-detective" ? ["inglese.comprensione", "inglese.bilingue", "inglese.scientifico"] : []),
        ...(type === "error-diagnosis" ? ["inglese.grammatica", "inglese.comprensione"] : []),
        ...(type === "dialogue-response" ? ["inglese.comprensione", "inglese.lessico", "inglese.bilingue"] : []),
      ])),
    };
  }

  private uniqueMinigamePrompt(
    random: Random,
    level: number,
    type: EnglishMinigameType,
    index: number,
    usedSignatures: Set<string>,
  ): EnglishMinigamePrompt {
    let first: EnglishMinigamePrompt | undefined;
    for (let attempt = 0; attempt < 36; attempt += 1) {
      const prompt = this.buildMinigamePrompt(random, level, type, index + attempt);
      first ??= prompt;
      if (!usedSignatures.has(prompt.signature)) {
        return this.sanitizeMinigamePrompt(prompt);
      }
    }
    return this.sanitizeMinigamePrompt(first ?? this.buildMinigamePrompt(random, level, type, index + 99));
  }

  private sanitizeMinigamePrompt(prompt: EnglishMinigamePrompt): EnglishMinigamePrompt {
    const dataPoints = prompt.dataPoints?.map((point) => ({
      label: point.label,
      value: point.value,
    }));
    const glossary = prompt.type === "sentence-build"
      ? prompt.glossary
      : prompt.glossary.filter((entry) => !this.glossaryEntryLeaksSolution(entry, prompt));
    return {
      ...prompt,
      dataPoints,
      glossary: glossary.length > 0 ? glossary : this.safeMinigameGlossary(prompt.type),
    };
  }

  private glossaryEntryLeaksSolution(
    entry: { term: string; meaning: string },
    prompt: EnglishMinigamePrompt,
  ): boolean {
    const term = this.normalizeVisibleHint(entry.term);
    if (!term) return false;
    return prompt.solutionLabels.some((label) => {
      const solution = this.normalizeVisibleHint(this.stripChoiceRole(label));
      if (!solution) return false;
      return this.visibleHintContains(term, solution) || this.visibleHintContains(solution, term);
    });
  }

  private stripChoiceRole(label: string): string {
    return label.replace(/^(azione|prova|risposta|motivo|correzione|diagnosi):\s*/i, "").trim();
  }

  private normalizeVisibleHint(text: string): string {
    return text
      .normalize("NFKD")
      .toLocaleLowerCase("en")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9']+/g, " ")
      .trim();
  }

  private visibleHintContains(haystack: string, needle: string): boolean {
    if (needle.length < 2) return false;
    const haystackTokens = haystack.split(/\s+/).filter(Boolean);
    const needleTokens = needle.split(/\s+/).filter(Boolean);
    if (needleTokens.length === 0) return false;
    if (needleTokens.length === 1 && needle.length <= 3) {
      return haystackTokens.includes(needle);
    }
    return ` ${haystack} `.includes(` ${needle} `);
  }

  private safeMinigameGlossary(type: EnglishMinigameType): Array<{ term: string; meaning: string }> {
    const glossary: Record<EnglishMinigameType, Array<{ term: string; meaning: string }>> = {
      "action-relay": [{ term: "limiter", meaning: "parola che limita il comando" }, { term: "evidence", meaning: "prova nel testo" }],
      "sequence-switchboard": [{ term: "time word", meaning: "parola che ordina le azioni" }, { term: "condition", meaning: "condizione" }],
      "data-command-scan": [{ term: "threshold", meaning: "soglia" }, { term: "compare", meaning: "confrontare i dati" }],
      "grammar-fix": [{ term: "signal word", meaning: "parola-spia grammaticale" }, { term: "form", meaning: "forma da scegliere" }],
      "sentence-build": [{ term: "word order", meaning: "ordine delle parole" }, { term: "auxiliary", meaning: "ausiliare" }],
      "vocab-lab": [{ term: "context", meaning: "situazione d'uso" }, { term: "word class", meaning: "tipo di parola" }],
      "translation-match": [{ term: "meaning", meaning: "significato" }, { term: "false friend", meaning: "falso amico" }],
      "reading-detective": [{ term: "inference", meaning: "conclusione dal testo" }, { term: "evidence", meaning: "prova testuale" }],
      "error-diagnosis": [{ term: "repair", meaning: "correzione" }, { term: "error type", meaning: "tipo di errore" }],
      "dialogue-response": [{ term: "register", meaning: "tono adatto" }, { term: "purpose", meaning: "scopo della risposta" }],
    };
    return glossary[type];
  }

  private buildMinigamePrompt(random: Random, level: number, type: EnglishMinigameType, index: number): EnglishMinigamePrompt {
    if (type === "action-relay") return this.buildActionRelayPrompt(random, level, index);
    if (type === "sequence-switchboard") return this.buildSequenceSwitchboardPrompt(random, level, index);
    if (type === "grammar-fix") return this.buildGrammarFixPrompt(random, level, index);
    if (type === "sentence-build") return this.buildSentenceBuildPrompt(random, level, index);
    if (type === "vocab-lab") return this.buildVocabularyPrompt(random, level, index);
    if (type === "translation-match") return this.buildTranslationMatchPrompt(random, level, index);
    if (type === "reading-detective") return this.buildReadingDetectivePrompt(random, level, index);
    if (type === "error-diagnosis") return this.buildErrorDiagnosisPrompt(random, level, index);
    if (type === "dialogue-response") return this.buildDialogueResponsePrompt(random, level, index);
    return this.buildDataCommandScanPrompt(random, level, index);
  }

  private buildActionRelayPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    type ActionRelayItem = {
      instruction: string;
      meaning: string;
      meaningDistractors: string[];
      evidence: string;
      evidenceDistractors: string[];
      explanation: string;
      glossary: Array<{ term: string; meaning: string }>;
      concept: string;
    };
    const pool = [
      {
        instruction: "Press the green button. Do not press the red button.",
        meaning: "Azione: premi il pulsante verde",
        meaningDistractors: ["Azione: premi il pulsante rosso", "Azione: premi entrambi i pulsanti"],
        evidence: "Prova: do not vieta il rosso",
        evidenceDistractors: ["Prova: red completa il comando positivo", "Prova: green e red sono entrambi permessi"],
        explanation: "Do not press the red button vieta il rosso; il comando positivo resta green.",
        glossary: [{ term: "press", meaning: "premere" }, { term: "do not", meaning: "non fare" }, { term: "green/red", meaning: "verde/rosso" }],
        concept: "imperative + prohibition",
      },
      {
        instruction: "Take the small key, not the large key.",
        meaning: "Azione: prendi la chiave piccola",
        meaningDistractors: ["Azione: prendi la chiave grande", "Azione: prendi entrambe le chiavi"],
        evidence: "Prova: not the large key esclude quella grande",
        evidenceDistractors: ["Prova: large indica la chiave corretta", "Prova: not lascia valide entrambe"],
        explanation: "Not the large key esclude la chiave grande: resta small key.",
        glossary: [{ term: "take", meaning: "prendere" }, { term: "small", meaning: "piccolo" }, { term: "large", meaning: "grande" }],
        concept: "object adjective",
      },
      {
        instruction: "Open the left drawer and keep the right drawer closed.",
        meaning: "Azione: apri il cassetto sinistro",
        meaningDistractors: ["Azione: apri il cassetto destro", "Azione: apri entrambi i cassetti"],
        evidence: "Prova: keep closed mantiene chiuso il destro",
        evidenceDistractors: ["Prova: right drawer è l'oggetto da aprire", "Prova: left rimanda al lato destro"],
        explanation: "Left e right distinguono due oggetti; il destro deve restare chiuso.",
        glossary: [{ term: "open", meaning: "aprire" }, { term: "left/right", meaning: "sinistra/destra" }, { term: "keep closed", meaning: "tenere chiuso" }],
        concept: "spatial direction",
      },
      {
        instruction: "Insert the blue card only.",
        meaning: "Azione: inserisci solo la scheda blu",
        meaningDistractors: ["Azione: inserisci la scheda gialla", "Azione: inserisci tutte le schede"],
        evidence: "Prova: only limita l'azione alla scheda blu",
        evidenceDistractors: ["Prova: blue è un dettaglio opzionale", "Prova: only permette tutte le schede"],
        explanation: "Only limita l'azione alla card blu.",
        glossary: [{ term: "insert", meaning: "inserire" }, { term: "only", meaning: "solo" }, { term: "card", meaning: "scheda" }],
        concept: "only limiter",
      },
      {
        instruction: "Save the report, but do not send it yet.",
        meaning: "Azione: salva il report",
        meaningDistractors: ["Azione: invia subito il report", "Azione: cancella il report"],
        evidence: "Prova: do not send it yet blocca l'invio",
        evidenceDistractors: ["Prova: yet rende l'invio immediato", "Prova: but cancella il comando save"],
        explanation: "Save è permesso; do not send it yet vieta l'invio per ora.",
        glossary: [{ term: "save", meaning: "salvare" }, { term: "send", meaning: "inviare" }, { term: "yet", meaning: "ancora / per ora" }],
        concept: "allowed action + delayed action",
      },
      {
        instruction: "Mark the verified source and ignore the rumor.",
        meaning: "Azione: segnala la fonte verificata",
        meaningDistractors: ["Azione: segnala la voce non verificata", "Azione: ignora la fonte verificata"],
        evidence: "Prova: verified source è affidabile, rumor va ignorata",
        evidenceDistractors: ["Prova: rumor è la fonte verificata", "Prova: ignore riguarda la fonte verificata"],
        explanation: "Verified source è la fonte controllata; rumor è la voce da ignorare.",
        glossary: [{ term: "mark", meaning: "segnare" }, { term: "verified", meaning: "verificato" }, { term: "rumor", meaning: "voce non verificata" }],
        concept: "source reliability",
      },
      {
        instruction: "Keep the backup switch on. Turn off the test lamp.",
        meaning: "Azione: spegni la lampada di test",
        meaningDistractors: ["Azione: spegni lo switch di backup", "Azione: spegni entrambi"],
        evidence: "Prova: keep on protegge lo switch di backup",
        evidenceDistractors: ["Prova: keep on richiede di spegnere", "Prova: turn off riguarda entrambi"],
        explanation: "Keep on preserva lo switch di backup; turn off riguarda solo la lampada di test.",
        glossary: [{ term: "keep on", meaning: "tenere acceso" }, { term: "turn off", meaning: "spegnere" }, { term: "backup", meaning: "riserva" }],
        concept: "two commands with different objects",
      },
    ] satisfies ActionRelayItem[];
    const advanced = [
      {
        instruction: "Replace the damaged cable, but leave the spare cable in the box.",
        meaning: "Azione: sostituisci il cavo danneggiato",
        meaningDistractors: ["Azione: sostituisci il cavo di ricambio", "Azione: sostituisci entrambi i cavi"],
        evidence: "Prova: damaged identifica il cavo da cambiare",
        evidenceDistractors: ["Prova: spare è il cavo guasto", "Prova: leave rende spare il bersaglio"],
        explanation: "Damaged identifica il cavo da sostituire; spare resta nella scatola.",
        glossary: [{ term: "replace", meaning: "sostituire" }, { term: "damaged", meaning: "danneggiato" }, { term: "spare", meaning: "di ricambio" }],
        concept: "technical adjective",
      },
      {
        instruction: "Switch off neither the pump nor the sensor.",
        meaning: "Azione: lascia accesi pompa e sensore",
        meaningDistractors: ["Azione: spegni la pompa", "Azione: spegni entrambi"],
        evidence: "Prova: neither...nor vieta entrambe le azioni",
        evidenceDistractors: ["Prova: neither...nor autorizza lo spegnimento", "Prova: nor riguarda solo il sensore"],
        explanation: "Neither...nor esclude entrambe le azioni: non spegnere né pompa né sensore.",
        glossary: [{ term: "switch off", meaning: "spegnere" }, { term: "neither...nor", meaning: "né...né" }, { term: "keep on", meaning: "tenere acceso" }],
        concept: "neither/nor prohibition",
      },
      {
        instruction: "Do not erase the draft; copy it to the archive.",
        meaning: "Azione: copia la bozza nell'archivio",
        meaningDistractors: ["Azione: cancella la bozza", "Azione: archivia una copia vuota"],
        evidence: "Prova: do not erase vieta la cancellazione",
        evidenceDistractors: ["Prova: erase è il comando positivo", "Prova: copy significa cancellare"],
        explanation: "Do not erase vieta di cancellare; copy it to the archive è l'azione corretta.",
        glossary: [{ term: "erase", meaning: "cancellare" }, { term: "draft", meaning: "bozza" }, { term: "copy", meaning: "copiare" }],
        concept: "negative imperative",
      },
      {
        instruction: "Close the upper hatch, not the lower hatch.",
        meaning: "Azione: chiudi lo sportello superiore",
        meaningDistractors: ["Azione: chiudi lo sportello inferiore", "Azione: chiudi entrambi"],
        evidence: "Prova: not the lower hatch esclude quello inferiore",
        evidenceDistractors: ["Prova: lower è l'oggetto giusto", "Prova: not permette entrambi"],
        explanation: "Upper identifica lo sportello da chiudere; lower è escluso da not.",
        glossary: [{ term: "upper", meaning: "superiore" }, { term: "lower", meaning: "inferiore" }, { term: "hatch", meaning: "sportello" }],
        concept: "spatial adjective + not",
      },
      {
        instruction: "Turn on the desk lamp, but leave the ceiling light off.",
        meaning: "Azione: accendi la lampada da tavolo",
        meaningDistractors: ["Azione: accendi la luce del soffitto", "Azione: spegni la lampada da tavolo"],
        evidence: "Prova: leave off mantiene spenta la ceiling light",
        evidenceDistractors: ["Prova: ceiling light è l'oggetto da accendere", "Prova: leave off significa accendere"],
        explanation: "Turn on riguarda la desk lamp; leave off vieta di accendere la ceiling light.",
        glossary: [{ term: "turn on", meaning: "accendere" }, { term: "leave off", meaning: "lasciare spento" }, { term: "ceiling", meaning: "soffitto" }],
        concept: "opposite phrasal verbs",
      },
      {
        instruction: "Move the empty crate, but keep the full crate still.",
        meaning: "Azione: sposta la cassa vuota",
        meaningDistractors: ["Azione: sposta la cassa piena", "Azione: sposta entrambe le casse"],
        evidence: "Prova: keep still blocca la cassa piena",
        evidenceDistractors: ["Prova: full crate è il bersaglio", "Prova: still significa veloce"],
        explanation: "Empty crate è l'oggetto da muovere; full crate deve restare ferma.",
        glossary: [{ term: "empty", meaning: "vuoto" }, { term: "full", meaning: "pieno" }, { term: "still", meaning: "fermo" }],
        concept: "object contrast",
      },
      {
        instruction: "Upload the final report only after checking the source.",
        meaning: "Azione: carica il report dopo aver controllato la fonte",
        meaningDistractors: ["Azione: carica il report subito", "Azione: ignora la fonte"],
        evidence: "Prova: only after impone il controllo prima dell'upload",
        evidenceDistractors: ["Prova: only after rende l'upload immediato", "Prova: source è un dettaglio inutile"],
        explanation: "Only after crea un prerequisito: prima controlli la fonte, poi carichi il report.",
        glossary: [{ term: "upload", meaning: "caricare online" }, { term: "source", meaning: "fonte" }, { term: "only after", meaning: "solo dopo" }],
        concept: "only after prerequisite",
      },
      {
        instruction: "Use the clean filter; do not touch the dusty one.",
        meaning: "Azione: usa il filtro pulito",
        meaningDistractors: ["Azione: usa il filtro polveroso", "Azione: tocca entrambi i filtri"],
        evidence: "Prova: do not touch vieta quello dusty",
        evidenceDistractors: ["Prova: dusty indica il filtro corretto", "Prova: clean è il filtro vietato"],
        explanation: "Clean filter è autorizzato; dusty one è escluso dal divieto.",
        glossary: [{ term: "clean", meaning: "pulito" }, { term: "dusty", meaning: "polveroso" }, { term: "touch", meaning: "toccare" }],
        concept: "adjective contrast",
      },
      {
        instruction: "Label the safe sample and quarantine the risky sample.",
        meaning: "Azione: etichetta il campione sicuro",
        meaningDistractors: ["Azione: etichetta il campione rischioso", "Azione: ignora il campione sicuro"],
        evidence: "Prova: quarantine riguarda il campione rischioso",
        evidenceDistractors: ["Prova: risky significa sicuro", "Prova: label e quarantine sono la stessa azione"],
        explanation: "Label si applica al safe sample; quarantine è l'azione separata per il risky sample.",
        glossary: [{ term: "label", meaning: "etichettare" }, { term: "safe", meaning: "sicuro" }, { term: "risky", meaning: "rischioso" }],
        concept: "paired actions",
      },
      {
        instruction: "Pick the written note, not the voice message.",
        meaning: "Azione: scegli la nota scritta",
        meaningDistractors: ["Azione: scegli il messaggio vocale", "Azione: scegli entrambi i messaggi"],
        evidence: "Prova: not the voice message esclude l'audio",
        evidenceDistractors: ["Prova: voice message è l'unico valido", "Prova: written significa vocale"],
        explanation: "Written note è il messaggio richiesto; voice message è escluso.",
        glossary: [{ term: "written", meaning: "scritto" }, { term: "voice", meaning: "voce" }, { term: "pick", meaning: "scegliere" }],
        concept: "media choice",
      },
      {
        instruction: "Restart the tablet only, not the main computer.",
        meaning: "Azione: riavvia solo il tablet",
        meaningDistractors: ["Azione: riavvia il computer principale", "Azione: riavvia entrambi"],
        evidence: "Prova: only limita l'azione al tablet",
        evidenceDistractors: ["Prova: main computer è incluso da only", "Prova: not rende valido il computer"],
        explanation: "Only limita restart al tablet; not the main computer esclude il computer principale.",
        glossary: [{ term: "restart", meaning: "riavviare" }, { term: "only", meaning: "solo" }, { term: "main", meaning: "principale" }],
        concept: "only + not",
      },
      {
        instruction: "Keep the old password hidden and write the new password down.",
        meaning: "Azione: annota la nuova password",
        meaningDistractors: ["Azione: scrivi la vecchia password", "Azione: mostra entrambe le password"],
        evidence: "Prova: keep hidden protegge la vecchia password",
        evidenceDistractors: ["Prova: old password è quella da scrivere", "Prova: hidden significa visibile"],
        explanation: "Write down riguarda la new password; old password deve restare nascosta.",
        glossary: [{ term: "old/new", meaning: "vecchio/nuovo" }, { term: "hidden", meaning: "nascosto" }, { term: "write down", meaning: "annotare" }],
        concept: "old/new contrast",
      },
      {
        instruction: "Select the confirmed answer, not the guess.",
        meaning: "Azione: scegli la risposta confermata",
        meaningDistractors: ["Azione: scegli l'ipotesi", "Azione: scegli entrambe"],
        evidence: "Prova: not the guess esclude la supposizione",
        evidenceDistractors: ["Prova: guess è confermata", "Prova: confirmed answer è vietata"],
        explanation: "Confirmed answer è supportata; guess è una supposizione esclusa.",
        glossary: [{ term: "confirmed", meaning: "confermato" }, { term: "guess", meaning: "ipotesi non provata" }, { term: "select", meaning: "selezionare" }],
        concept: "evidence vs guess",
      },
      {
        instruction: "Scan the front page, but skip the back page.",
        meaning: "Azione: scansiona la pagina frontale",
        meaningDistractors: ["Azione: scansiona il retro", "Azione: scansiona entrambe le pagine"],
        evidence: "Prova: skip the back page esclude il retro",
        evidenceDistractors: ["Prova: back page è il bersaglio", "Prova: skip significa scansionare"],
        explanation: "Scan riguarda la front page; skip esclude la back page.",
        glossary: [{ term: "front", meaning: "fronte" }, { term: "back", meaning: "retro" }, { term: "skip", meaning: "saltare" }],
        concept: "front/back contrast",
      },
      {
        instruction: "Store the glass tube carefully; throw away the cracked tube.",
        meaning: "Azione: conserva con cura il tubo di vetro",
        meaningDistractors: ["Azione: conserva il tubo incrinato", "Azione: getta via entrambi"],
        evidence: "Prova: throw away riguarda il tubo cracked",
        evidenceDistractors: ["Prova: cracked significa integro", "Prova: store e throw away coincidono"],
        explanation: "Store carefully riguarda il glass tube integro; cracked tube va eliminato.",
        glossary: [{ term: "store", meaning: "conservare" }, { term: "cracked", meaning: "incrinato" }, { term: "throw away", meaning: "gettare via" }],
        concept: "safe handling",
      },
      {
        instruction: "Read the warning first, then start the engine.",
        meaning: "Azione: leggi l'avviso prima di avviare il motore",
        meaningDistractors: ["Azione: avvia subito il motore", "Azione: ignora l'avviso"],
        evidence: "Prova: first mette warning prima di start",
        evidenceDistractors: ["Prova: then anticipa il motore", "Prova: warning è opzionale"],
        explanation: "First ordina la lettura dell'avviso prima di start the engine.",
        glossary: [{ term: "warning", meaning: "avviso" }, { term: "first", meaning: "prima" }, { term: "engine", meaning: "motore" }],
        concept: "first/then order",
      },
      {
        instruction: "Accept the signed form and reject the unsigned form.",
        meaning: "Azione: accetta il modulo firmato",
        meaningDistractors: ["Azione: accetta il modulo non firmato", "Azione: rifiuta entrambi"],
        evidence: "Prova: reject riguarda unsigned form",
        evidenceDistractors: ["Prova: unsigned significa firmato", "Prova: accept riguarda entrambi"],
        explanation: "Signed form è accettato; unsigned form è rifiutato.",
        glossary: [{ term: "signed", meaning: "firmato" }, { term: "unsigned", meaning: "non firmato" }, { term: "reject", meaning: "rifiutare" }],
        concept: "signed/unsigned",
      },
      {
        instruction: "Follow the north route; avoid the south tunnel.",
        meaning: "Azione: segui il percorso nord",
        meaningDistractors: ["Azione: entra nel tunnel sud", "Azione: usa entrambi i percorsi"],
        evidence: "Prova: avoid esclude il south tunnel",
        evidenceDistractors: ["Prova: avoid significa seguire", "Prova: south è il percorso sicuro"],
        explanation: "Follow riguarda north route; avoid esclude south tunnel.",
        glossary: [{ term: "follow", meaning: "seguire" }, { term: "avoid", meaning: "evitare" }, { term: "route", meaning: "percorso" }],
        concept: "route selection",
      },
      {
        instruction: "Mute the noisy channel, but keep the emergency channel active.",
        meaning: "Azione: silenzia il canale rumoroso",
        meaningDistractors: ["Azione: silenzia il canale di emergenza", "Azione: spegni entrambi i canali"],
        evidence: "Prova: keep active protegge il canale emergency",
        evidenceDistractors: ["Prova: emergency channel è quello da mutare", "Prova: active significa spento"],
        explanation: "Mute riguarda noisy channel; emergency channel resta attivo.",
        glossary: [{ term: "mute", meaning: "silenziare" }, { term: "noisy", meaning: "rumoroso" }, { term: "emergency", meaning: "emergenza" }],
        concept: "communication safety",
      },
    ] satisfies ActionRelayItem[];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index * 10, item.meaning, true, `Significato corretto. ${item.explanation}`),
      this.englishTile(index * 10 + 1, item.evidence, true, `Prova linguistica corretta. ${item.explanation}`),
      ...item.meaningDistractors.map((label, choiceIndex) => this.englishTile(index * 10 + choiceIndex + 2, label, false, `Significato non coerente: ${item.explanation}`)),
      ...item.evidenceDistractors.map((label, choiceIndex) => this.englishTile(index * 10 + choiceIndex + 5, label, false, `Prova linguistica non valida: ${item.explanation}`)),
    ]);
    return {
      id: `english-action-${index}`,
      type: "action-relay",
      instruction: item.instruction,
      context: "Decodifica il comando: scegli una tessera AZIONE e una tessera VINCOLO che giustificano la scelta.",
      targetLabel: "Significato + vincolo",
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: [item.meaning, item.evidence],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `action-${item.instruction}-${item.meaning}-${item.evidence}`,
    };
  }

  private buildSequenceSwitchboardPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    const pool = [
      {
        instruction: "Check the sensor before you open the valve.",
        correct: "Check sensor first",
        distractors: ["Open valve first", "Skip sensor", "Open and check together"],
        explanation: "Before indica che check the sensor viene prima di open the valve.",
        glossary: [{ term: "before", meaning: "prima di" }, { term: "check", meaning: "controllare" }, { term: "valve", meaning: "valvola" }],
        concept: "before",
      },
      {
        instruction: "Open the gate after the robot reaches the dock.",
        correct: "Robot at dock -> open gate",
        distractors: ["Open gate now", "Send robot away", "Open before robot arrives"],
        explanation: "After richiede che l'arrivo del robot sia già avvenuto.",
        glossary: [{ term: "after", meaning: "dopo che" }, { term: "reaches", meaning: "raggiunge" }, { term: "dock", meaning: "base" }],
        concept: "after",
      },
      {
        instruction: "Wait until the light turns blue, then reset the panel.",
        correct: "Blue light -> reset",
        distractors: ["Reset before blue", "Ignore the light", "Turn light red"],
        explanation: "Until impone attesa; then introduce l'azione successiva.",
        glossary: [{ term: "wait", meaning: "aspettare" }, { term: "until", meaning: "finché" }, { term: "then", meaning: "poi" }],
        concept: "until + then",
      },
      {
        instruction: "If the alarm starts, close the door immediately.",
        correct: "Alarm starts -> close door",
        distractors: ["No alarm -> close door", "Alarm starts -> open door", "Ignore alarm"],
        explanation: "If introduce la condizione che attiva l'azione.",
        glossary: [{ term: "if", meaning: "se" }, { term: "alarm", meaning: "allarme" }, { term: "immediately", meaning: "subito" }],
        concept: "first conditional",
      },
    ];
    const advanced = [
      {
        instruction: "Do not restart the core unless the backup light is green.",
        correct: "Green backup -> restart",
        distractors: ["Restart without green", "Green backup -> shut down", "Restart because light is red"],
        explanation: "Unless significa a meno che: il riavvio è permesso solo con luce verde.",
        glossary: [{ term: "unless", meaning: "a meno che" }, { term: "backup", meaning: "di riserva" }, { term: "restart", meaning: "riavviare" }],
        concept: "unless",
      },
      {
        instruction: "Not until the pressure drops should you unlock the hatch.",
        correct: "Pressure drops -> unlock hatch",
        distractors: ["Unlock before pressure drops", "Raise pressure", "Lock the hatch forever"],
        explanation: "Not until vieta di anticipare: sblocca solo dopo il calo di pressione.",
        glossary: [{ term: "not until", meaning: "non prima che" }, { term: "pressure drops", meaning: "la pressione scende" }, { term: "unlock", meaning: "sbloccare" }],
        concept: "not until",
      },
      {
        instruction: "Write down the result after the second sensor confirms it.",
        correct: "Second sensor confirms -> write result",
        distractors: ["Write before confirmation", "Ignore second sensor", "Erase the result"],
        explanation: "After richiede che la conferma del secondo sensore venga prima dell'annotazione.",
        glossary: [{ term: "write down", meaning: "annotare" }, { term: "after", meaning: "dopo" }, { term: "confirms", meaning: "conferma" }],
        concept: "after + evidence",
      },
      {
        instruction: "Test the cable, then report whether it is safe.",
        correct: "Test cable -> report safety",
        distractors: ["Report before test", "Replace cable without test", "Test after reporting"],
        explanation: "Then mette il report dopo il test: prima prova, poi conclusione.",
        glossary: [{ term: "test", meaning: "testare" }, { term: "then", meaning: "poi" }, { term: "whether", meaning: "se / se oppure no" }],
        concept: "test before conclusion",
      },
      {
        instruction: "If the note is unsigned, ask for a source before you act.",
        correct: "Unsigned note -> ask source",
        distractors: ["Act immediately", "Ignore every note", "Ask source after acting"],
        explanation: "If introduce la condizione; before you act impone la verifica della fonte prima dell'azione.",
        glossary: [{ term: "unsigned", meaning: "non firmato" }, { term: "source", meaning: "fonte" }, { term: "before", meaning: "prima" }],
        concept: "condition + source check",
      },
      {
        instruction: "Save the log before you close the console.",
        correct: "Save log -> close console",
        distractors: ["Close console first", "Delete log", "Save after closing"],
        explanation: "Before mette il salvataggio prima della chiusura della console.",
        glossary: [{ term: "save", meaning: "salvare" }, { term: "before", meaning: "prima" }, { term: "close", meaning: "chiudere" }],
        concept: "before + prerequisite",
      },
      {
        instruction: "After the teacher checks the answer, correct the report.",
        correct: "Teacher checks -> correct report",
        distractors: ["Correct before check", "Ignore teacher check", "Delete report"],
        explanation: "After indica che la correzione avviene dopo il controllo dell'insegnante.",
        glossary: [{ term: "after", meaning: "dopo che" }, { term: "checks", meaning: "controlla" }, { term: "correct", meaning: "correggere" }],
        concept: "after + review",
      },
      {
        instruction: "Do not enter the lab until the green sign appears.",
        correct: "Green sign appears -> enter lab",
        distractors: ["Enter before sign", "Wait for red sign", "Never enter lab"],
        explanation: "Until impone attesa: entri solo quando compare il segnale verde.",
        glossary: [{ term: "until", meaning: "finché / fino a quando" }, { term: "appears", meaning: "compare" }, { term: "enter", meaning: "entrare" }],
        concept: "until + permission",
      },
      {
        instruction: "Unless the map is updated, follow the old route.",
        correct: "Map not updated -> follow old route",
        distractors: ["Always follow new route", "Delete the map", "Ignore every route"],
        explanation: "Unless introduce l'eccezione: se la mappa non è aggiornata, resta il vecchio percorso.",
        glossary: [{ term: "unless", meaning: "a meno che" }, { term: "updated", meaning: "aggiornato" }, { term: "route", meaning: "percorso" }],
        concept: "unless exception",
      },
      {
        instruction: "If the value is missing, ask for a new measurement.",
        correct: "Value missing -> ask new measurement",
        distractors: ["Value missing -> confirm result", "Ignore missing value", "Ask after confirming"],
        explanation: "If introduce la condizione: un valore mancante richiede una nuova misura.",
        glossary: [{ term: "missing", meaning: "mancante" }, { term: "measurement", meaning: "misura" }, { term: "ask for", meaning: "chiedere" }],
        concept: "if + missing data",
      },
      {
        instruction: "Check the battery, then connect the sensor.",
        correct: "Check battery -> connect sensor",
        distractors: ["Connect sensor first", "Disconnect battery", "Skip battery check"],
        explanation: "Then mette connect sensor dopo il controllo della batteria.",
        glossary: [{ term: "check", meaning: "controllare" }, { term: "then", meaning: "poi" }, { term: "connect", meaning: "collegare" }],
        concept: "then sequence",
      },
      {
        instruction: "Before you answer, read the question twice.",
        correct: "Read twice -> answer",
        distractors: ["Answer immediately", "Read after answering", "Skip the question"],
        explanation: "Before you answer impone la lettura prima della risposta.",
        glossary: [{ term: "answer", meaning: "rispondere" }, { term: "twice", meaning: "due volte" }, { term: "question", meaning: "domanda" }],
        concept: "metacognitive sequence",
      },
      {
        instruction: "After the alarm stops, open the safe door.",
        correct: "Alarm stops -> open safe door",
        distractors: ["Open during alarm", "Start alarm", "Lock safe forever"],
        explanation: "After richiede che l'allarme sia già terminato prima dell'apertura.",
        glossary: [{ term: "stops", meaning: "si ferma" }, { term: "safe door", meaning: "porta sicura/cassaforte" }, { term: "open", meaning: "aprire" }],
        concept: "after + safety",
      },
      {
        instruction: "Wait until the file finishes loading, then print it.",
        correct: "File loads -> print",
        distractors: ["Print before loading", "Close file", "Wait after printing"],
        explanation: "Until impone attesa; then mette print dopo il caricamento.",
        glossary: [{ term: "loading", meaning: "caricamento" }, { term: "print", meaning: "stampare" }, { term: "wait", meaning: "aspettare" }],
        concept: "until + then",
      },
      {
        instruction: "If the source is reliable, include it in the report.",
        correct: "Reliable source -> include it",
        distractors: ["Unreliable source -> include it", "Delete report", "Include every source"],
        explanation: "If lega l'inclusione alla fonte affidabile, non a qualunque fonte.",
        glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "include", meaning: "includere" }, { term: "source", meaning: "fonte" }],
        concept: "condition + reliability",
      },
      {
        instruction: "Do not submit the answer unless you can explain it.",
        correct: "Can explain -> submit answer",
        distractors: ["Submit without explanation", "Never submit", "Explain after submitting"],
        explanation: "Unless crea un requisito: invii solo se sai spiegare.",
        glossary: [{ term: "submit", meaning: "consegnare/inviare" }, { term: "explain", meaning: "spiegare" }, { term: "unless", meaning: "a meno che" }],
        concept: "unless + evidence of understanding",
      },
      {
        instruction: "Measure the current before replacing the fuse.",
        correct: "Measure current -> replace fuse",
        distractors: ["Replace fuse first", "Measure temperature", "Ignore current"],
        explanation: "Before mette la misura della corrente prima della sostituzione del fusibile.",
        glossary: [{ term: "current", meaning: "corrente" }, { term: "replace", meaning: "sostituire" }, { term: "fuse", meaning: "fusibile" }],
        concept: "technical before",
      },
      {
        instruction: "After you compare the two sources, choose the clearer one.",
        correct: "Compare sources -> choose clearer one",
        distractors: ["Choose before comparing", "Choose both sources", "Ignore clearer source"],
        explanation: "After indica che la scelta viene dopo il confronto tra le fonti.",
        glossary: [{ term: "compare", meaning: "confrontare" }, { term: "sources", meaning: "fonti" }, { term: "clearer", meaning: "più chiaro" }],
        concept: "compare before choose",
      },
      {
        instruction: "Not until the backup is ready should you shut down the main line.",
        correct: "Backup ready -> shut down main line",
        distractors: ["Shut down before backup", "Keep backup off", "Shut down every line now"],
        explanation: "Not until vieta di anticipare lo spegnimento prima del backup pronto.",
        glossary: [{ term: "backup", meaning: "riserva" }, { term: "ready", meaning: "pronto" }, { term: "shut down", meaning: "spegnere/arrestare" }],
        concept: "not until + backup",
      },
      {
        instruction: "If the door stays locked, check the code again.",
        correct: "Door locked -> check code again",
        distractors: ["Door locked -> open by force", "Ignore code", "Check after leaving"],
        explanation: "If introduce la condizione; again indica ripetere il controllo del codice.",
        glossary: [{ term: "stays locked", meaning: "resta bloccata" }, { term: "again", meaning: "di nuovo" }, { term: "code", meaning: "codice" }],
        concept: "if + retry",
      },
      {
        instruction: "Start the timer only when everyone is ready.",
        correct: "Everyone ready -> start timer",
        distractors: ["Start timer immediately", "Start when one person is ready", "Stop timer forever"],
        explanation: "Only when restringe il momento: serve che tutti siano pronti.",
        glossary: [{ term: "only when", meaning: "solo quando" }, { term: "everyone", meaning: "tutti" }, { term: "timer", meaning: "timer" }],
        concept: "only when condition",
      },
      {
        instruction: "Read the warning before touching the metal plate.",
        correct: "Read warning -> touch plate",
        distractors: ["Touch plate first", "Ignore warning", "Read after touching"],
        explanation: "Before mette la lettura dell'avviso prima del contatto con la piastra.",
        glossary: [{ term: "warning", meaning: "avviso" }, { term: "touching", meaning: "toccare" }, { term: "metal plate", meaning: "piastra metallica" }],
        concept: "safety before action",
      },
      {
        instruction: "After the robot docks, download its log.",
        correct: "Robot docks -> download log",
        distractors: ["Download before docking", "Delete log", "Send robot away"],
        explanation: "After indica che il download segue l'arrivo del robot alla base.",
        glossary: [{ term: "docks", meaning: "attracca/arriva alla base" }, { term: "download", meaning: "scaricare" }, { term: "log", meaning: "registro" }],
        concept: "after + data retrieval",
      },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Wrong order: ${item.explanation}`)),
    ]);
    return {
      id: `english-sequence-${index}`,
      type: "sequence-switchboard",
      instruction: item.instruction,
      context: "Select the safe sequence. Time words are control levers, not decorations.",
      targetLabel: "Safe sequence",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `sequence-${item.instruction}-${item.correct}`,
    };
  }

  private buildDataCommandScanPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    const kind = level >= 5 ? random.pick(["below", "above", "between", "compare"] as const) : random.pick(["below", "above", "between"] as const);
    if (kind === "below") {
      const threshold = random.pick([18, 20, 24, 30]);
      const pods = random.shuffle(["A", "B", "C"]);
      const low = random.integer(8, threshold - 2);
      const safeOne = random.integer(threshold + 2, threshold + 10);
      const safeTwo = random.integer(threshold + 11, threshold + 20);
      const target = pods[0];
      return this.dataPrompt(
        index,
        "data-command-scan",
        `Water the pod whose moisture is below ${threshold}. Leave the other pods unchanged.`,
        "Find the value below the threshold and act only there.",
        "Threshold decision",
        [
          { label: `Pod ${target}`, value: `${low}` },
          { label: `Pod ${pods[1]}`, value: `${safeOne}` },
          { label: `Pod ${pods[2]}`, value: `${safeTwo}` },
        ].sort((a, b) => a.label.localeCompare(b.label)),
        `Water pod ${target}`,
        [`Water pod ${pods[1]}`, "Water all pods", "Do nothing"],
        `Below ${threshold} significa sotto ${threshold}: solo pod ${target} è sotto soglia.`,
        "below threshold",
        [{ term: "below", meaning: "sotto" }, { term: "whose", meaning: "il cui / la cui" }, { term: "unchanged", meaning: "senza modifiche" }],
      );
    }
    if (kind === "above") {
      const threshold = random.pick([60, 70, 75, 80]);
      const panels = random.shuffle(["North", "East", "West"]);
      const high = random.integer(threshold + 3, threshold + 15);
      const lowOne = random.integer(threshold - 22, threshold - 4);
      const lowTwo = random.integer(threshold - 35, threshold - 23);
      const target = panels[0];
      return this.dataPrompt(
        index,
        "data-command-scan",
        `Cool the panel whose heat is above ${threshold}. Do not cool the others.`,
        "Above points to the only value over the limit.",
        "Above-limit action",
        [
          { label: `${target} panel`, value: `${high}°C` },
          { label: `${panels[1]} panel`, value: `${lowOne}°C` },
          { label: `${panels[2]} panel`, value: `${lowTwo}°C` },
        ].sort((a, b) => a.label.localeCompare(b.label)),
        `Cool ${target}`,
        [`Cool ${panels[1]}`, "Cool every panel", "Ignore heat"],
        `Above ${threshold} significa sopra ${threshold}: intervieni solo sul pannello ${target}.`,
        "above threshold",
        [{ term: "above", meaning: "sopra" }, { term: "cool", meaning: "raffreddare" }, { term: "others", meaning: "gli altri" }],
      );
    }
    if (kind === "between") {
      const low = random.pick([16, 18, 20]);
      const high = low + random.pick([5, 6, 7]);
      const value = random.integer(low, high);
      return this.dataPrompt(
        index,
        "data-command-scan",
        `If the temperature is between ${low} and ${high}, open the vent halfway.`,
        "Between includes the values inside the interval.",
        "Interval command",
        [{ label: "Temperature", value: `${value}°C` }],
        "Open vent halfway",
        ["Keep vent closed", "Open vent fully", "Lower the temperature first"],
        `${value} è dentro l'intervallo ${low}-${high}; halfway significa a metà.`,
        "between range",
        [{ term: "between", meaning: "tra" }, { term: "halfway", meaning: "a metà" }, { term: "vent", meaning: "presa d'aria" }],
      );
    }
    const labels = random.shuffle(["A", "B"]);
    const dimmer = random.integer(25, 45);
    const brighter = random.integer(dimmer + 18, dimmer + 42);
    return this.dataPrompt(
      index,
      "data-command-scan",
      "Choose the dimmer signal and lock the brighter one.",
      "Compare the two values before acting.",
      "Comparison command",
      [
        { label: `Signal ${labels[0]}`, value: `${dimmer} lux` },
        { label: `Signal ${labels[1]}`, value: `${brighter} lux` },
      ],
      `Choose ${labels[0]} -> lock ${labels[1]}`,
      [`Choose ${labels[1]} -> lock ${labels[0]}`, "Lock both signals", `Ignore signal ${labels[0]}`],
      "Dimmer indica il valore minore; brighter il valore maggiore.",
      "comparatives",
      [{ term: "dimmer", meaning: "meno luminoso" }, { term: "brighter", meaning: "più luminoso" }, { term: "lock", meaning: "bloccare" }],
    );
  }

  private dataPrompt(
    index: number,
    type: EnglishMinigameType,
    instruction: string,
    context: string,
    targetLabel: string,
    dataPoints: Array<{ label: string; value: string; note?: string }>,
    correct: string,
    distractors: string[],
    explanation: string,
    concept: string,
    glossary: Array<{ term: string; meaning: string }>,
  ): EnglishMinigamePrompt {
    const tiles = this.shuffleEnglishTiles(new Random(`${instruction}:${index}`), [
      this.englishTile(index, correct, true, `Correct: ${explanation}`),
      ...distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Check the data: ${explanation}`)),
    ]);
    return {
      id: `english-data-${index}`,
      type,
      instruction,
      context,
      targetLabel,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [correct],
      explanation,
      concept,
      glossary,
      dataPoints,
      signature: `data-${instruction}-${correct}-${dataPoints.map((point) => `${point.label}:${point.value}`).join("|")}`,
    };
  }

  private englishTile(seed: number, label: string, isCorrect: boolean, feedback: string): EnglishMinigameTile {
    return {
      id: `english-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
      label,
      isCorrect,
      feedback,
    };
  }

  private shuffleEnglishTiles(random: Random, tiles: EnglishMinigameTile[]): EnglishMinigameTile[] {
    return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
  }

  private buildGrammarFixPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    type GrammarItem = { instruction: string; correct: string; distractors: string[]; explanation: string; concept: string; glossary: Array<{ term: string; meaning: string }> };
    const base: GrammarItem[] = [
      { instruction: "She ___ to school every day.", correct: "goes", distractors: ["go", "is going", "going"], explanation: "Present simple per le abitudini: alla terza persona si aggiunge -es (go → goes).", concept: "present simple", glossary: [{ term: "every day", meaning: "ogni giorno" }, { term: "goes", meaning: "va" }] },
      { instruction: "Look! The robot ___ a box now.", correct: "is carrying", distractors: ["carries", "carry", "carried"], explanation: "Present continuous per ciò che accade ora: be + verbo-ing.", concept: "present continuous", glossary: [{ term: "now", meaning: "adesso" }, { term: "carry", meaning: "trasportare" }] },
      { instruction: "Yesterday we ___ the test.", correct: "started", distractors: ["start", "starts", "starting"], explanation: "Past simple per il passato concluso: verbi regolari in -ed.", concept: "past simple", glossary: [{ term: "yesterday", meaning: "ieri" }, { term: "start", meaning: "iniziare" }] },
      { instruction: "This cable is ___ than that one.", correct: "longer", distractors: ["long", "longest", "more long"], explanation: "Comparativo di maggioranza con aggettivo corto: -er + than.", concept: "comparative", glossary: [{ term: "than", meaning: "di/che (confronto)" }, { term: "long", meaning: "lungo" }] },
      { instruction: "This is the ___ room in the lab.", correct: "biggest", distractors: ["bigger", "big", "most big"], explanation: "Superlativo con aggettivo corto: the + -est (big → biggest).", concept: "superlative", glossary: [{ term: "the biggest", meaning: "il più grande" }] },
      { instruction: "Lab rule: you ___ wear gloves here.", correct: "must", distractors: ["mustn't", "can", "should"], explanation: "Must esprime obbligo; mustn't sarebbe divieto.", concept: "modal: obligation", glossary: [{ term: "must", meaning: "dovere (obbligo)" }, { term: "gloves", meaning: "guanti" }] },
      { instruction: "Robots ___ lift heavy boxes without help.", correct: "can", distractors: ["must", "should", "can't"], explanation: "Can esprime capacità/abilità.", concept: "modal: ability", glossary: [{ term: "can", meaning: "potere/sapere" }, { term: "lift", meaning: "sollevare" }] },
      { instruction: "You look tired. You ___ rest.", correct: "should", distractors: ["must", "mustn't", "can't"], explanation: "Should dà un consiglio, non un obbligo.", concept: "modal: advice", glossary: [{ term: "should", meaning: "dovere (consiglio)" }, { term: "rest", meaning: "riposare" }] },
      { instruction: "The key is ___ the closed drawer.", correct: "in", distractors: ["on", "at", "to"], explanation: "In per ciò che è dentro un contenitore.", concept: "preposition of place", glossary: [{ term: "in", meaning: "dentro" }, { term: "drawer", meaning: "cassetto" }] },
      { instruction: "The test starts ___ Monday.", correct: "on", distractors: ["in", "at", "by"], explanation: "On con i giorni della settimana.", concept: "preposition of time", glossary: [{ term: "on Monday", meaning: "di lunedì" }] },
      { instruction: "There aren't ___ batteries left.", correct: "any", distractors: ["some", "much", "a"], explanation: "Any nelle frasi negative con plurali numerabili.", concept: "quantifier some/any", glossary: [{ term: "any", meaning: "nessuno/alcuni" }, { term: "left", meaning: "rimasto" }] },
      { instruction: "How ___ sensors are there?", correct: "many", distractors: ["much", "some", "any"], explanation: "Many con i nomi numerabili plurali.", concept: "quantifier much/many", glossary: [{ term: "how many", meaning: "quanti" }] },
      { instruction: "It is ___ open circuit.", correct: "an", distractors: ["a", "the", "one"], explanation: "An davanti a suono vocalico (open).", concept: "articles a/an", glossary: [{ term: "an", meaning: "un/uno (davanti a vocale)" }] },
      { instruction: "___ she like science?", correct: "Does", distractors: ["Do", "Is", "Did"], explanation: "Domanda al present simple, terza persona: ausiliare Does.", concept: "question form", glossary: [{ term: "does", meaning: "ausiliare (3ª pers.)" }] },
      { instruction: "There ___ three robots in the room.", correct: "are", distractors: ["is", "be", "has"], explanation: "There are con i plurali.", concept: "there is/are", glossary: [{ term: "there are", meaning: "ci sono" }] },
    ];
    const advanced: GrammarItem[] = [
      { instruction: "I ___ already finished the report.", correct: "have", distractors: ["has", "am", "did"], explanation: "Present perfect: have/has + participio passato.", concept: "present perfect", glossary: [{ term: "already", meaning: "già" }, { term: "have finished", meaning: "ho finito" }] },
      { instruction: "Look at the clouds! It ___ rain.", correct: "is going to", distractors: ["will", "goes to", "go to"], explanation: "Be going to per previsioni con prove evidenti.", concept: "future: going to", glossary: [{ term: "is going to", meaning: "sta per/andrà" }] },
      { instruction: "If you press it, the light ___ on.", correct: "will turn", distractors: ["turns", "turned", "turning"], explanation: "Primo condizionale: if + present, will + base.", concept: "first conditional", glossary: [{ term: "will turn on", meaning: "si accenderà" }] },
      { instruction: "This result is ___ than before.", correct: "better", distractors: ["gooder", "more good", "best"], explanation: "Comparativo irregolare: good → better.", concept: "irregular comparative", glossary: [{ term: "better", meaning: "migliore" }] },
      { instruction: "Where ___ you go yesterday?", correct: "did", distractors: ["do", "does", "was"], explanation: "Domanda al past simple: ausiliare did + base.", concept: "past question", glossary: [{ term: "did", meaning: "ausiliare passato" }] },
      { instruction: "The wires ___ checked every morning.", correct: "are", distractors: ["is", "was", "be"], explanation: "Passivo al presente con soggetto plurale: are checked.", concept: "present passive", glossary: [{ term: "wires", meaning: "cavi" }, { term: "checked", meaning: "controllati" }] },
      { instruction: "The old battery ___ replaced yesterday.", correct: "was", distractors: ["is", "were", "has"], explanation: "Passivo al passato con soggetto singolare: was replaced.", concept: "past passive", glossary: [{ term: "was replaced", meaning: "è stata sostituita" }] },
      { instruction: "We have not tested the east cable ___.", correct: "yet", distractors: ["already", "still", "ever"], explanation: "Yet si usa spesso nelle frasi negative per dire non ancora.", concept: "present perfect yet", glossary: [{ term: "yet", meaning: "ancora / non ancora" }] },
      { instruction: "The robot ___ already found the key.", correct: "has", distractors: ["have", "is", "did"], explanation: "Present perfect con terza persona singolare: has already found.", concept: "present perfect already", glossary: [{ term: "already", meaning: "già" }] },
      { instruction: "There is too ___ noise in the room.", correct: "much", distractors: ["many", "any", "few"], explanation: "Much si usa con nomi non numerabili come noise.", concept: "much/many", glossary: [{ term: "noise", meaning: "rumore" }] },
      { instruction: "There are ___ loose screws on the desk.", correct: "some", distractors: ["any", "much", "a"], explanation: "Some indica una quantità positiva non precisa con plurali numerabili.", concept: "some + plural", glossary: [{ term: "loose screws", meaning: "viti allentate" }] },
      { instruction: "The sample is ___ the glass box.", correct: "inside", distractors: ["between", "above", "across"], explanation: "Inside indica dentro un contenitore.", concept: "preposition: inside", glossary: [{ term: "inside", meaning: "dentro" }] },
      { instruction: "The drone flew ___ the bridge.", correct: "under", distractors: ["into", "between", "on"], explanation: "Under significa sotto: il drone passa sotto il ponte.", concept: "preposition: under", glossary: [{ term: "under", meaning: "sotto" }] },
      { instruction: "If water reaches the sensor, the alarm ___.", correct: "starts", distractors: ["will starts", "started", "starting"], explanation: "Zero conditional/regola generale: if + present, present.", concept: "zero conditional", glossary: [{ term: "reaches", meaning: "raggiunge" }] },
      { instruction: "You ___ open the hatch without gloves.", correct: "mustn't", distractors: ["must", "can", "should"], explanation: "Mustn't esprime divieto forte.", concept: "modal: prohibition", glossary: [{ term: "mustn't", meaning: "non devi" }] },
    ];
    // Core terza-media (A2→B1) grammar under-covered above: irregular past, past
    // continuous, present-perfect nuances, will vs going to, second conditional,
    // have to / might, subject-vs-object questions, used to, relative pronouns.
    const terzaMediaExtra: GrammarItem[] = [
      { instruction: "We ___ to the lab an hour ago.", correct: "went", distractors: ["goed", "go", "gone"], explanation: "Past simple irregolare: go → went (mai «goed»).", concept: "past simple (irregular)", glossary: [{ term: "went", meaning: "andammo/andò" }, { term: "an hour ago", meaning: "un'ora fa" }] },
      { instruction: "They ___ finish the experiment yesterday.", correct: "didn't", distractors: ["don't", "weren't", "hadn't"], explanation: "Past simple negativo: did + not + base (didn't finish).", concept: "past simple negative", glossary: [{ term: "didn't", meaning: "non (passato)" }] },
      { instruction: "While I ___ the data, the power went off.", correct: "was reading", distractors: ["read", "am reading", "was read"], explanation: "Past continuous per un'azione in corso nel passato: was/were + -ing.", concept: "past continuous", glossary: [{ term: "while", meaning: "mentre" }, { term: "was reading", meaning: "stavo leggendo" }] },
      { instruction: "She was writing when the alarm ___.", correct: "rang", distractors: ["was ringing", "rings", "ring"], explanation: "L'azione breve che interrompe va al past simple: when the alarm rang.", concept: "past simple vs continuous", glossary: [{ term: "rang", meaning: "suonò" }] },
      { instruction: "Have you ___ used this tool?", correct: "ever", distractors: ["never", "yet", "already"], explanation: "Ever nelle domande al present perfect significa «mai/qualche volta».", concept: "present perfect (ever)", glossary: [{ term: "ever", meaning: "mai/qualche volta" }] },
      { instruction: "The phone is ringing. I ___ answer it.", correct: "will", distractors: ["am going to", "going to", "won't"], explanation: "Will per una decisione presa sul momento; going to sarebbe un piano già deciso.", concept: "future: will (decision)", glossary: [{ term: "I'll answer", meaning: "rispondo io" }] },
      { instruction: "We have worked here ___ three hours.", correct: "for", distractors: ["since", "from", "during"], explanation: "For + durata (for three hours); since + punto di inizio.", concept: "present perfect (for/since)", glossary: [{ term: "for", meaning: "per (durata)" }] },
      { instruction: "I have known her ___ 2020.", correct: "since", distractors: ["for", "from", "in"], explanation: "Since + punto preciso nel tempo (since 2020); for + durata.", concept: "present perfect (for/since)", glossary: [{ term: "since", meaning: "da (un momento)" }] },
      { instruction: "The delivery has ___ arrived.", correct: "just", distractors: ["yet", "ago", "still"], explanation: "Just (appena) va tra l'ausiliare have/has e il participio.", concept: "present perfect (just)", glossary: [{ term: "just", meaning: "appena" }] },
      { instruction: "I ___ him last week.", correct: "saw", distractors: ["have seen", "see", "seen"], explanation: "Con un tempo passato finito (last week) si usa il past simple, non il present perfect.", concept: "past simple vs present perfect", glossary: [{ term: "saw", meaning: "vidi/ho visto (last week → saw)" }] },
      { instruction: "If I ___ you, I would check the logs.", correct: "were", distractors: ["was", "am", "will be"], explanation: "Secondo condizionale (ipotesi irreale): «If I were you, I would…».", concept: "second conditional", glossary: [{ term: "were", meaning: "fossi (2° condizionale)" }] },
      { instruction: "Visitors ___ sign in at the door.", correct: "have to", distractors: ["must to", "has to", "haves to"], explanation: "Have to per un obbligo dato da una regola; con «Visitors» (plurale) è «have to».", concept: "modal: have to", glossary: [{ term: "have to", meaning: "dover (regola)" }] },
      { instruction: "It's very cloudy. It ___ rain soon.", correct: "might", distractors: ["must", "can", "should"], explanation: "Might/may per una possibilità incerta nel futuro.", concept: "modal: possibility (may/might)", glossary: [{ term: "might", meaning: "potrebbe" }] },
      { instruction: "Who ___ the window?", correct: "broke", distractors: ["did break", "did broke", "was break"], explanation: "Nelle domande sul soggetto NON si usa l'ausiliare: «Who broke…?».", concept: "subject question (no auxiliary)", glossary: [{ term: "who broke", meaning: "chi ruppe" }] },
      { instruction: "Who ___ you invite?", correct: "did", distractors: ["do", "invited", "have"], explanation: "Nelle domande sull'oggetto serve l'ausiliare: «Who did you invite?».", concept: "object question (auxiliary)", glossary: [{ term: "did you invite", meaning: "hai invitato" }] },
      { instruction: "I ___ walk to school, but now I take the bus.", correct: "used to", distractors: ["use to", "used", "am used to"], explanation: "Used to + base per un'abitudine passata che non c'è più.", concept: "used to (past habit)", glossary: [{ term: "used to", meaning: "ero solito/una volta" }] },
      { instruction: "The engineer ___ fixed it is here.", correct: "who", distractors: ["which", "whose", "what"], explanation: "Who è il pronome relativo per le persone.", concept: "relative pronoun (who)", glossary: [{ term: "who", meaning: "che (persone)" }] },
      { instruction: "The machine ___ broke down is old.", correct: "which", distractors: ["who", "whose", "where"], explanation: "Which (o that) è il pronome relativo per le cose.", concept: "relative pronoun (which)", glossary: [{ term: "which", meaning: "che (cose)" }] },
      { instruction: "You are the new student, ___?", correct: "aren't you", distractors: ["are you", "don't you", "isn't it"], explanation: "Question tag: frase affermativa con «are» → tag negativo «aren't you?».", concept: "question tag (be)", glossary: [{ term: "aren't you?", meaning: "vero? (non è così?)" }] },
      { instruction: "She works in the lab, ___?", correct: "doesn't she", distractors: ["does she", "isn't she", "don't she"], explanation: "Present simple affermativo (works) → tag negativo con l'ausiliare: «doesn't she?».", concept: "question tag (present simple)", glossary: [{ term: "doesn't she?", meaning: "vero?" }] },
      { instruction: "They didn't call, ___?", correct: "did they", distractors: ["didn't they", "do they", "were they"], explanation: "Frase negativa (didn't) → tag positivo: «did they?».", concept: "question tag (negative sentence)", glossary: [{ term: "did they?", meaning: "vero?" }] },
    ];
    const item = random.pick(
      level >= 4 ? [...base, ...advanced, ...terzaMediaExtra]
        : level >= 2 ? [...base, ...terzaMediaExtra.slice(0, 6)]
          : base,
    );
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Not correct here: ${item.explanation}`)),
    ]);
    return {
      id: `english-grammar-${index}`,
      type: "grammar-fix",
      instruction: item.instruction,
      context: "Choose the correct English form so the sentence is grammatically right.",
      targetLabel: "Correct form",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `grammar-${item.instruction}-${item.correct}`,
    };
  }

  private buildSentenceBuildPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    const base = [
      { sentence: "She goes to school every day", concept: "present simple word order", glossary: [{ term: "every day", meaning: "ogni giorno" }] },
      { sentence: "The robot is moving the box", concept: "present continuous word order", glossary: [{ term: "is moving", meaning: "sta muovendo" }] },
      { sentence: "We started the test yesterday", concept: "past simple word order", glossary: [{ term: "yesterday", meaning: "ieri" }] },
      { sentence: "There are three sensors here", concept: "there are + plural", glossary: [{ term: "there are", meaning: "ci sono" }] },
      { sentence: "Does she like science", concept: "question word order", glossary: [{ term: "does", meaning: "ausiliare domanda" }] },
    ];
    const advanced = [
      { sentence: "Where did you put the key", concept: "wh- question word order", glossary: [{ term: "where", meaning: "dove" }] },
      { sentence: "You must wear gloves here", concept: "modal word order", glossary: [{ term: "must", meaning: "dovere (obbligo)" }] },
      { sentence: "I have finished the report", concept: "present perfect word order", glossary: [{ term: "have finished", meaning: "ho finito" }] },
      { sentence: "The teacher checked the answer", concept: "past simple word order", glossary: [{ term: "checked", meaning: "ha controllato" }] },
      { sentence: "We should save the log now", concept: "modal advice word order", glossary: [{ term: "should", meaning: "dovremmo" }] },
      { sentence: "The battery is under the desk", concept: "preposition word order", glossary: [{ term: "under", meaning: "sotto" }] },
      { sentence: "Can the robot open the gate", concept: "can question word order", glossary: [{ term: "can", meaning: "può" }] },
      { sentence: "Do not touch the red wire", concept: "negative imperative word order", glossary: [{ term: "do not", meaning: "non" }] },
      { sentence: "The sensor does not work today", concept: "negative present simple", glossary: [{ term: "does not", meaning: "non" }] },
      { sentence: "Why did the alarm stop", concept: "why question word order", glossary: [{ term: "why", meaning: "perché" }] },
      { sentence: "The door will close automatically", concept: "future with will", glossary: [{ term: "will close", meaning: "si chiuderà" }] },
      { sentence: "The east cable was repaired yesterday", concept: "passive past word order", glossary: [{ term: "was repaired", meaning: "è stato riparato" }] },
      { sentence: "Have you tested the backup battery", concept: "present perfect question", glossary: [{ term: "have you tested", meaning: "hai testato" }] },
      { sentence: "The report is clearer than before", concept: "comparative word order", glossary: [{ term: "clearer than", meaning: "più chiaro di" }] },
      { sentence: "There is not enough water", concept: "there is negative quantity", glossary: [{ term: "enough", meaning: "abbastanza" }] },
      { sentence: "Please keep the door closed", concept: "polite imperative", glossary: [{ term: "please", meaning: "per favore" }] },
      { sentence: "The backup light is still green", concept: "adverb position", glossary: [{ term: "still", meaning: "ancora" }] },
      { sentence: "She can explain the evidence", concept: "modal ability", glossary: [{ term: "evidence", meaning: "prova" }] },
      { sentence: "They are comparing two sources", concept: "present continuous plural", glossary: [{ term: "comparing", meaning: "confrontando" }] },
      { sentence: "The file has already loaded", concept: "present perfect already", glossary: [{ term: "already", meaning: "già" }] },
      { sentence: "If it rains the robot stops", concept: "zero conditional order", glossary: [{ term: "if", meaning: "se" }] },
      { sentence: "The safest route avoids the tunnel", concept: "superlative + verb", glossary: [{ term: "safest", meaning: "più sicuro" }] },
      { sentence: "We did not finish the test", concept: "negative past simple word order", glossary: [{ term: "did not", meaning: "non (passato)" }] },
      { sentence: "The door will not open", concept: "negative future word order", glossary: [{ term: "will not", meaning: "non (futuro)" }] },
      { sentence: "I have not seen the report", concept: "negative present perfect word order", glossary: [{ term: "have not seen", meaning: "non ho visto" }] },
      { sentence: "She always arrives on time", concept: "adverb of frequency position", glossary: [{ term: "always", meaning: "sempre (prima del verbo)" }] },
      { sentence: "I was reading the data", concept: "past continuous word order", glossary: [{ term: "was reading", meaning: "stavo leggendo" }] },
      { sentence: "If I were you I would wait", concept: "second conditional order", glossary: [{ term: "if I were you", meaning: "se fossi in te" }] },
    ];
    const item = random.bool(0.58)
      ? this.parametricEnglishSentenceBuildItem(random, level)
      : random.pick(level >= 4 ? [...base, ...advanced] : base);
    const words = item.sentence.split(/\s+/);
    const isQuestion = ["does", "did", "where", "what", "why", "when", "how", "who", "do", "is", "are", "can", "have", "has", "could", "should", "would"].includes(words[0].toLowerCase());
    const tiles = this.shuffleEnglishTiles(
      random,
      words.map((word, position) => this.englishTile(index * 100 + position, word, true, "Word of the sentence: mind its position.")),
    );
    const explanation = isQuestion
      ? "Nelle domande inglesi l'ausiliare va prima del soggetto: (Wh-) + aux + soggetto + verbo."
      : "Ordine inglese: soggetto + verbo + resto della frase. L'ordine cambia il significato.";
    return {
      id: `english-build-${index}`,
      type: "sentence-build",
      instruction: `Build: ${isQuestion ? "the question" : "the sentence"} in correct English.`,
      context: `Scrambled words: ${random.shuffle([...words]).join(" · ")}`,
      targetLabel: "Correct order",
      requiredSelectionCount: words.length,
      tiles,
      solutionLabels: words,
      explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `sentence-build-${item.sentence}`,
    };
  }

  private parametricEnglishSentenceBuildItem(random: Random, level: number): { sentence: string; concept: string; glossary: Array<{ term: string; meaning: string }> } {
    const everyday = [
      { sentence: "My sister checks the timetable before school", concept: "everyday sequence", glossary: [{ term: "timetable", meaning: "orario" }, { term: "before", meaning: "prima" }] },
      { sentence: "The teacher explains the rule with an example", concept: "school communication", glossary: [{ term: "explains", meaning: "spiega" }, { term: "example", meaning: "esempio" }] },
      { sentence: "We compare two prices at the supermarket", concept: "shopping context", glossary: [{ term: "compare", meaning: "confrontare" }, { term: "price", meaning: "prezzo" }] },
      { sentence: "The bus leaves from platform three", concept: "travel information", glossary: [{ term: "leaves", meaning: "parte" }, { term: "platform", meaning: "binario" }] },
      { sentence: "This app protects your password", concept: "digital safety", glossary: [{ term: "protects", meaning: "protegge" }, { term: "password", meaning: "password" }] },
      { sentence: "The doctor checks the appointment time", concept: "health appointment", glossary: [{ term: "appointment", meaning: "appuntamento" }, { term: "checks", meaning: "controlla" }] },
      { sentence: "Our team collects evidence before deciding", concept: "evidence before decision", glossary: [{ term: "evidence", meaning: "prove" }, { term: "before", meaning: "prima" }] },
      { sentence: "The message gives clear directions to the library", concept: "directions", glossary: [{ term: "directions", meaning: "indicazioni" }, { term: "library", meaning: "biblioteca" }] },
      { sentence: "A careful student saves the file twice", concept: "study habit", glossary: [{ term: "careful", meaning: "attento" }, { term: "twice", meaning: "due volte" }] },
      { sentence: "The weather forecast changes our plan", concept: "weather and plans", glossary: [{ term: "forecast", meaning: "previsioni" }, { term: "plan", meaning: "piano" }] },
      { sentence: "Please write the address in your notebook", concept: "polite imperative", glossary: [{ term: "please", meaning: "per favore" }, { term: "address", meaning: "indirizzo" }] },
      { sentence: "The recipe lists the ingredients in order", concept: "everyday procedure", glossary: [{ term: "recipe", meaning: "ricetta" }, { term: "ingredients", meaning: "ingredienti" }] },
      { sentence: "The class discusses a reliable source", concept: "critical reading", glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "source", meaning: "fonte" }] },
      { sentence: "The coach gives useful feedback after training", concept: "feedback and sport", glossary: [{ term: "coach", meaning: "allenatore" }, { term: "feedback", meaning: "riscontro" }] },
      { sentence: "A polite answer keeps the conversation calm", concept: "communication register", glossary: [{ term: "polite", meaning: "cortese" }, { term: "conversation", meaning: "conversazione" }] },
      { sentence: "The group shares the task fairly", concept: "collaboration", glossary: [{ term: "shares", meaning: "divide/condivide" }, { term: "fairly", meaning: "in modo equo" }] },
    ];
    const questions = [
      { sentence: "Did you save the file before lunch", concept: "past simple question", glossary: [{ term: "did you save", meaning: "hai salvato" }, { term: "before lunch", meaning: "prima di pranzo" }] },
      { sentence: "Where is the nearest pharmacy", concept: "where question", glossary: [{ term: "nearest", meaning: "più vicino" }, { term: "pharmacy", meaning: "farmacia" }] },
      { sentence: "How can we check this source", concept: "how question", glossary: [{ term: "how can we", meaning: "come possiamo" }, { term: "source", meaning: "fonte" }] },
      { sentence: "Why did the bus arrive late", concept: "why past question", glossary: [{ term: "why", meaning: "perché" }, { term: "late", meaning: "in ritardo" }] },
      { sentence: "Have you finished the summary yet", concept: "present perfect question", glossary: [{ term: "yet", meaning: "ancora / già in domanda" }, { term: "summary", meaning: "riassunto" }] },
      { sentence: "Could you repeat the last instruction", concept: "polite request", glossary: [{ term: "could you", meaning: "potresti" }, { term: "repeat", meaning: "ripetere" }] },
      { sentence: "Should we ask for another measurement", concept: "advice question", glossary: [{ term: "should", meaning: "dovremmo" }, { term: "measurement", meaning: "misura" }] },
      { sentence: "What does reliable mean in this text", concept: "vocabulary question", glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "mean", meaning: "significare" }] },
    ];
    const complex = [
      { sentence: "If the bus is late we send a message", concept: "first conditional", glossary: [{ term: "if", meaning: "se" }, { term: "late", meaning: "in ritardo" }] },
      { sentence: "When the source is unclear we ask for proof", concept: "when + response", glossary: [{ term: "unclear", meaning: "poco chiaro" }, { term: "proof", meaning: "prova" }] },
      { sentence: "Although the answer is quick it is not accurate", concept: "although contrast", glossary: [{ term: "although", meaning: "sebbene" }, { term: "accurate", meaning: "preciso" }] },
      { sentence: "Before you share a photo ask for permission", concept: "before + imperative", glossary: [{ term: "share", meaning: "condividere" }, { term: "permission", meaning: "permesso" }] },
      { sentence: "The route is safer because it avoids traffic", concept: "because + reason", glossary: [{ term: "safer", meaning: "più sicuro" }, { term: "traffic", meaning: "traffico" }] },
      { sentence: "We will start when everyone is ready", concept: "future with when", glossary: [{ term: "will start", meaning: "inizieremo" }, { term: "everyone", meaning: "tutti" }] },
      { sentence: "The report is useful because it separates facts and opinions", concept: "reason and critical reading", glossary: [{ term: "facts", meaning: "fatti" }, { term: "opinions", meaning: "opinioni" }] },
      { sentence: "If I were you I would check the evidence", concept: "second conditional", glossary: [{ term: "if I were you", meaning: "se fossi in te" }, { term: "would", meaning: "condizionale" }] },
    ];
    const proverbs = [
      { sentence: "Practice makes perfect", concept: "common proverb", glossary: [{ term: "practice", meaning: "esercizio" }, { term: "perfect", meaning: "perfetto" }] },
      { sentence: "Better late than never", concept: "common proverb", glossary: [{ term: "better", meaning: "meglio" }, { term: "never", meaning: "mai" }] },
      { sentence: "Actions speak louder than words", concept: "common proverb", glossary: [{ term: "actions", meaning: "azioni" }, { term: "words", meaning: "parole" }] },
      { sentence: "Look before you leap", concept: "common proverb", glossary: [{ term: "look before", meaning: "guarda prima" }, { term: "leap", meaning: "saltare" }] },
      { sentence: "Time is money", concept: "common proverb", glossary: [{ term: "time", meaning: "tempo" }, { term: "money", meaning: "denaro" }] },
      { sentence: "Honesty is the best policy", concept: "common proverb", glossary: [{ term: "honesty", meaning: "onestà" }, { term: "policy", meaning: "regola / linea" }] },
      { sentence: "Good things take time", concept: "common proverb", glossary: [{ term: "good things", meaning: "cose buone" }, { term: "take time", meaning: "richiedono tempo" }] },
    ];
    if (level >= 6 && random.bool(0.2)) {
      return random.pick(proverbs);
    }
    if (level >= 4 && random.bool(0.4)) {
      return random.pick(complex);
    }
    if (level >= 3 && random.bool(0.32)) {
      return random.pick(questions);
    }
    return random.pick(everyday);
  }

  private englishSentenceDistractors(random: Random, words: string[]): string[] {
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
    let guard = 0;
    while (variants.size < 3 && guard < 20) {
      const shuffled = random.shuffle([...words]).join(" ");
      if (shuffled !== correct) variants.add(shuffled);
      guard += 1;
    }
    return [...variants].slice(0, 3);
  }

  private buildVocabularyPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    const item = this.pickVocabularyEntry(random, level);
    const context = this.vocabularyContext(item);
    const distractors = this.vocabularyDistractorEntries(random, item, "term");
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.term, true, `Correct: ${context.explanation}`),
      ...distractors.map((entry, choiceIndex) => this.englishTile(
        index + choiceIndex + 1,
        entry.term,
        false,
        `"${entry.term}" significa "${entry.meaning}" (${englishVocabularyCategoryLabels[entry.category]}): non corrisponde all'indizio "${item.meaning}".`,
      )),
    ]);
    return {
      id: `english-vocab-${index}`,
      type: "vocab-lab",
      instruction: "Complete the mission card: choose the English word that matches meaning, context and word class.",
      context: context.prompt,
      targetLabel: "Vocabulary in context",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.term],
      explanation: context.explanation,
      concept: context.concept,
      glossary: [
        { term: item.term, meaning: item.meaning },
        { term: "category", meaning: englishVocabularyCategoryLabels[item.category] },
        { term: "level", meaning: `lessico livello ${item.level}` },
      ],
      signature: `vocab-${item.id}-${item.term}`,
    };
  }

  private buildTranslationMatchPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    const item = this.pickVocabularyEntry(random, level);
    const distractors = this.vocabularyDistractorEntries(random, item, "meaning");
    const explanation = `${item.term} significa "${item.meaning}" nel contesto ${englishVocabularyCategoryLabels[item.category]}.`;
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.meaning, true, `Correct: ${explanation}`),
      ...distractors.map((entry, choiceIndex) => this.englishTile(
        index + choiceIndex + 1,
        entry.meaning,
        false,
        `"${entry.meaning}" traduce "${entry.term}", non "${item.term}". ${explanation}`,
      )),
    ]);
    return {
      id: `english-translation-${index}`,
      type: "translation-match",
      instruction: `What does "${item.term}" mean in Italian?`,
      context: `Vocabulary card: "${item.term}" | ${englishVocabularyCategoryLabels[item.category]} | ${item.wordClass}`,
      targetLabel: "Traduzione corretta",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.meaning],
      explanation,
      concept: `${englishVocabularyCategoryLabels[item.category]} (${item.wordClass})`,
      glossary: [
        { term: "task", meaning: "scegli la traduzione italiana corretta" },
        { term: "watch out", meaning: "controlla falsi amici e contesto" },
      ],
      signature: `translation-${item.id}-${item.term}-${item.meaning}`,
    };
  }

  private buildReadingDetectivePrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    type ReadingItem = {
      log: string;
      question: string;
      answer: string;
      answerDistractors: string[];
      evidence: string;
      evidenceDistractors: string[];
      explanation: string;
      concept: string;
      glossary: Array<{ term: string; meaning: string }>;
    };
    const base: ReadingItem[] = [
      {
        log: "Log: The blue door is locked because the backup battery is empty. The green door is open.",
        question: "Which door needs power before it can open?",
        answer: "Risposta: blue door",
        answerDistractors: ["Risposta: green door", "Risposta: every door"],
        evidence: "Prova: because the backup battery is empty",
        evidenceDistractors: ["Prova: the green door is open", "Prova: every door is locked"],
        explanation: "Blue door è collegata alla batteria scarica; green door è già aperta.",
        concept: "cause vs irrelevant detail",
        glossary: [{ term: "because", meaning: "perché / causa" }, { term: "locked", meaning: "bloccato" }, { term: "empty", meaning: "vuoto / scarico" }],
      },
      {
        log: "Message: The robot can carry the small box, but it cannot lift the metal crate.",
        question: "What can the robot safely move?",
        answer: "Risposta: the small box",
        answerDistractors: ["Risposta: the metal crate", "Risposta: both objects"],
        evidence: "Prova: can carry the small box",
        evidenceDistractors: ["Prova: cannot lift the metal crate", "Prova: but means both are safe"],
        explanation: "Can indica capacità; cannot esclude la metal crate.",
        concept: "can/cannot + object",
        glossary: [{ term: "can", meaning: "può / è in grado" }, { term: "cannot", meaning: "non può" }, { term: "carry", meaning: "trasportare" }],
      },
      {
        log: "Notice: The meeting starts at 8:30. Students should arrive ten minutes earlier.",
        question: "When should students arrive?",
        answer: "Risposta: at 8:20",
        answerDistractors: ["Risposta: at 8:30", "Risposta: ten minutes later"],
        evidence: "Prova: ten minutes earlier",
        evidenceDistractors: ["Prova: starts at 8:30 is the arrival time", "Prova: earlier means later"],
        explanation: "Earlier sottrae dieci minuti dall'orario di inizio.",
        concept: "time inference",
        glossary: [{ term: "starts", meaning: "inizia" }, { term: "earlier", meaning: "prima" }, { term: "arrive", meaning: "arrivare" }],
      },
    ];
    const advanced: ReadingItem[] = [
      {
        log: "Report: Although the main pump is noisy, the pressure is stable. However, the east valve is leaking.",
        question: "Which part needs repair first?",
        answer: "Risposta: east valve",
        answerDistractors: ["Risposta: main pump", "Risposta: pressure sensor"],
        evidence: "Prova: the east valve is leaking",
        evidenceDistractors: ["Prova: although the pump is noisy", "Prova: pressure is stable"],
        explanation: "Although segnala un contrasto: il rumore non è il guasto principale; leaking indica perdita.",
        concept: "contrast + fault evidence",
        glossary: [{ term: "although", meaning: "sebbene" }, { term: "however", meaning: "tuttavia" }, { term: "leaking", meaning: "perde" }],
      },
      {
        log: "Lab note: The sample was heated for five minutes and then cooled slowly. It was not tested after cooling.",
        question: "Which step is missing?",
        answer: "Risposta: test after cooling",
        answerDistractors: ["Risposta: heat for five minutes", "Risposta: cool slowly"],
        evidence: "Prova: was not tested after cooling",
        evidenceDistractors: ["Prova: was heated for five minutes", "Prova: then cooled slowly"],
        explanation: "Was not tested after cooling indica il controllo mancante, non un passaggio già fatto.",
        concept: "passive + missing step",
        glossary: [{ term: "was heated", meaning: "è stato riscaldato" }, { term: "cooled", meaning: "raffreddato" }, { term: "after", meaning: "dopo" }],
      },
      {
        log: "Log: The north cable was repaired yesterday, but the east cable was not checked.",
        question: "Which cable needs attention now?",
        answer: "Risposta: east cable",
        answerDistractors: ["Risposta: north cable", "Risposta: both cables"],
        evidence: "Prova: was not checked",
        evidenceDistractors: ["Prova: was repaired yesterday", "Prova: both cables were repaired"],
        explanation: "North cable è già riparato; east cable manca del controllo.",
        concept: "passive + contrast",
        glossary: [{ term: "was repaired", meaning: "è stato riparato" }, { term: "was not checked", meaning: "non è stato controllato" }],
      },
      {
        log: "Message: The old password is hidden. The new password is written on the blue card.",
        question: "Where should you look for the usable password?",
        answer: "Risposta: blue card",
        answerDistractors: ["Risposta: old password file", "Risposta: red card"],
        evidence: "Prova: new password is written on the blue card",
        evidenceDistractors: ["Prova: old password is hidden", "Prova: every password is visible"],
        explanation: "La password usabile è new, non old; il testo la collega alla blue card.",
        concept: "old/new reference",
        glossary: [{ term: "hidden", meaning: "nascosto" }, { term: "written on", meaning: "scritto su" }],
      },
      {
        log: "Report: The source is reliable, but the conclusion is still too strong for one measurement.",
        question: "What should the team do before closing the report?",
        answer: "Risposta: add another measurement",
        answerDistractors: ["Risposta: close the report now", "Risposta: delete the source"],
        evidence: "Prova: too strong for one measurement",
        evidenceDistractors: ["Prova: source is reliable means finished", "Prova: conclusion is already proven"],
        explanation: "Una fonte affidabile non basta se la conclusione è troppo forte per una sola misura.",
        concept: "evidence strength",
        glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "too strong", meaning: "troppo forte" }],
      },
      {
        log: "Notice: The backup light is green only when the spare battery is ready.",
        question: "What does a green backup light mean?",
        answer: "Risposta: spare battery is ready",
        answerDistractors: ["Risposta: main battery is broken", "Risposta: backup is forbidden"],
        evidence: "Prova: only when the spare battery is ready",
        evidenceDistractors: ["Prova: green always means broken", "Prova: spare battery is missing"],
        explanation: "Only when lega la luce verde alla batteria di riserva pronta.",
        concept: "only when inference",
        glossary: [{ term: "only when", meaning: "solo quando" }, { term: "spare", meaning: "di riserva" }],
      },
      {
        log: "Email: I cannot open the file because the tablet is offline. The file is not damaged.",
        question: "What is the real problem?",
        answer: "Risposta: tablet is offline",
        answerDistractors: ["Risposta: file is damaged", "Risposta: password is wrong"],
        evidence: "Prova: because the tablet is offline",
        evidenceDistractors: ["Prova: file is not damaged", "Prova: cannot always means password"],
        explanation: "Because introduce la causa: il tablet è offline; il file non è danneggiato.",
        concept: "because + excluded cause",
        glossary: [{ term: "offline", meaning: "non connesso" }, { term: "damaged", meaning: "danneggiato" }],
      },
      {
        log: "Instruction: Use the north route unless the bridge is closed. Today the bridge is closed.",
        question: "Which route rule applies today?",
        answer: "Risposta: do not use the north route",
        answerDistractors: ["Risposta: always use north", "Risposta: ignore the bridge"],
        evidence: "Prova: unless the bridge is closed",
        evidenceDistractors: ["Prova: bridge is closed means north is required", "Prova: unless removes every rule"],
        explanation: "Unless crea un'eccezione: con bridge closed la regola nord non vale.",
        concept: "unless exception",
        glossary: [{ term: "unless", meaning: "a meno che" }, { term: "closed", meaning: "chiuso" }],
      },
      {
        log: "Lab note: The red sample is clean. The green sample is clean too. The yellow sample is contaminated.",
        question: "Which sample should be isolated?",
        answer: "Risposta: yellow sample",
        answerDistractors: ["Risposta: red sample", "Risposta: green sample"],
        evidence: "Prova: yellow sample is contaminated",
        evidenceDistractors: ["Prova: red sample is clean", "Prova: green sample is clean too"],
        explanation: "Contaminated indica il campione da isolare; clean esclude red e green.",
        concept: "contrast in list",
        glossary: [{ term: "clean", meaning: "pulito" }, { term: "contaminated", meaning: "contaminato" }],
      },
      {
        log: "Log: The robot usually scans the left gate, but now it is scanning the right gate.",
        question: "Which gate is being scanned now?",
        answer: "Risposta: right gate",
        answerDistractors: ["Risposta: left gate", "Risposta: both gates"],
        evidence: "Prova: now it is scanning the right gate",
        evidenceDistractors: ["Prova: usually scans the left gate", "Prova: usually means now"],
        explanation: "Usually descrive routine; now identifica la situazione attuale.",
        concept: "routine vs now",
        glossary: [{ term: "usually", meaning: "di solito" }, { term: "now", meaning: "adesso" }],
      },
      {
        log: "Notice: The index can be scanned after the archive opens. The archive is still locked.",
        question: "What should wait?",
        answer: "Risposta: scanning the index",
        answerDistractors: ["Risposta: locking the archive", "Risposta: opening has already happened"],
        evidence: "Prova: after the archive opens",
        evidenceDistractors: ["Prova: archive is still locked means scan now", "Prova: after means before"],
        explanation: "After the archive opens colloca la scansione dopo l'apertura; l'archivio è ancora chiuso.",
        concept: "after + current state",
        glossary: [{ term: "after", meaning: "dopo" }, { term: "still locked", meaning: "ancora bloccato" }],
      },
      {
        log: "Report: The west pump is louder than the east pump, but both pumps work normally.",
        question: "Which conclusion is supported?",
        answer: "Risposta: both pumps work",
        answerDistractors: ["Risposta: west pump is broken", "Risposta: east pump is silent"],
        evidence: "Prova: both pumps work normally",
        evidenceDistractors: ["Prova: louder means broken", "Prova: east pump is silent"],
        explanation: "Louder descrive rumore relativo; il testo dice che entrambe funzionano normalmente.",
        concept: "comparison vs fault",
        glossary: [{ term: "louder", meaning: "più rumoroso" }, { term: "normally", meaning: "normalmente" }],
      },
      {
        log: "Message: The answer is correct, but the explanation is missing.",
        question: "What is missing?",
        answer: "Risposta: explanation",
        answerDistractors: ["Risposta: answer", "Risposta: question"],
        evidence: "Prova: explanation is missing",
        evidenceDistractors: ["Prova: answer is correct", "Prova: correct means complete"],
        explanation: "Correct riguarda la risposta; missing riguarda la spiegazione.",
        concept: "correct vs complete",
        glossary: [{ term: "correct", meaning: "corretto" }, { term: "missing", meaning: "mancante" }],
      },
      {
        log: "Warning: Neither the metal probe nor the wet cloth is safe. Use the insulated tester.",
        question: "Which tool is safe?",
        answer: "Risposta: insulated tester",
        answerDistractors: ["Risposta: metal probe", "Risposta: wet cloth"],
        evidence: "Prova: Use the insulated tester",
        evidenceDistractors: ["Prova: neither...nor makes both safe", "Prova: wet cloth is safe"],
        explanation: "Neither...nor esclude probe e cloth; instead resta insulated tester.",
        concept: "neither/nor safety",
        glossary: [{ term: "neither...nor", meaning: "né...né" }, { term: "insulated", meaning: "isolato" }],
      },
      {
        log: "Update: The first source confirms the time. The second source confirms the place.",
        question: "What is still not confirmed?",
        answer: "Risposta: cause",
        answerDistractors: ["Risposta: time", "Risposta: place"],
        evidence: "Prova: confirms the time / confirms the place",
        evidenceDistractors: ["Prova: cause is confirmed twice", "Prova: second source confirms cause"],
        explanation: "Il log conferma tempo e luogo, non la causa.",
        concept: "not mentioned inference",
        glossary: [{ term: "confirms", meaning: "conferma" }, { term: "cause", meaning: "causa" }],
      },
      {
        log: "Note: The meeting was moved from Room 2 to Room 5.",
        question: "Where is the meeting now?",
        answer: "Risposta: Room 5",
        answerDistractors: ["Risposta: Room 2", "Risposta: both rooms"],
        evidence: "Prova: moved from Room 2 to Room 5",
        evidenceDistractors: ["Prova: from Room 2 is the new place", "Prova: moved means both rooms"],
        explanation: "From indica origine; to indica destinazione nuova.",
        concept: "from/to direction",
        glossary: [{ term: "from", meaning: "da" }, { term: "to", meaning: "a/verso" }],
      },
      {
        log: "Status: The main server is online. The backup server is offline but not damaged.",
        question: "What is true about the backup server?",
        answer: "Risposta: offline but not damaged",
        answerDistractors: ["Risposta: online and damaged", "Risposta: main server is offline"],
        evidence: "Prova: backup server is offline but not damaged",
        evidenceDistractors: ["Prova: main server is online", "Prova: offline always means damaged"],
        explanation: "But collega due informazioni: backup offline, però non danneggiato.",
        concept: "but + state",
        glossary: [{ term: "online", meaning: "connesso" }, { term: "damaged", meaning: "danneggiato" }],
      },
      {
        log: "Instruction: Print the final page only. The draft page must stay hidden.",
        question: "Which page should be printed?",
        answer: "Risposta: final page",
        answerDistractors: ["Risposta: draft page", "Risposta: both pages"],
        evidence: "Prova: final page only",
        evidenceDistractors: ["Prova: draft page must stay hidden", "Prova: only means both"],
        explanation: "Only limita la stampa alla pagina finale; draft resta nascosta.",
        concept: "only + hidden object",
        glossary: [{ term: "final", meaning: "finale" }, { term: "draft", meaning: "bozza" }],
      },
      {
        log: "Observation: The soil is dry, but the light level is normal.",
        question: "Which problem is more likely?",
        answer: "Risposta: water problem",
        answerDistractors: ["Risposta: light problem", "Risposta: no problem"],
        evidence: "Prova: soil is dry",
        evidenceDistractors: ["Prova: light level is normal", "Prova: normal means broken"],
        explanation: "Dry soil sostiene un problema d'acqua; light normal esclude la luce.",
        concept: "scientific evidence",
        glossary: [{ term: "soil", meaning: "terreno" }, { term: "dry", meaning: "secco" }],
      },
      {
        log: "Message: The student answered quickly, but not accurately.",
        question: "What needs improvement?",
        answer: "Risposta: accuracy",
        answerDistractors: ["Risposta: speed", "Risposta: handwriting"],
        evidence: "Prova: not accurately",
        evidenceDistractors: ["Prova: answered quickly", "Prova: quickly means accurately"],
        explanation: "Quickly è positivo sulla velocità; not accurately indica il problema.",
        concept: "adverb contrast",
        glossary: [{ term: "quickly", meaning: "velocemente" }, { term: "accurately", meaning: "con precisione" }],
      },
      {
        log: "Log: The red wire must stay connected unless the fuse overheats.",
        question: "When can the red wire be disconnected?",
        answer: "Risposta: if the fuse overheats",
        answerDistractors: ["Risposta: always", "Risposta: when the wire is red"],
        evidence: "Prova: unless the fuse overheats",
        evidenceDistractors: ["Prova: must stay connected means disconnect now", "Prova: red wire creates exception"],
        explanation: "Unless introduce l'eccezione al must stay connected.",
        concept: "unless + modal",
        glossary: [{ term: "must stay", meaning: "deve restare" }, { term: "overheats", meaning: "si surriscalda" }],
      },
      {
        log: "Note: The safe route is shorter than the old route and less steep than the tunnel route.",
        question: "Which route should be preferred?",
        answer: "Risposta: safe route",
        answerDistractors: ["Risposta: old route", "Risposta: tunnel route"],
        evidence: "Prova: shorter and less steep",
        evidenceDistractors: ["Prova: old route is shorter", "Prova: tunnel route is less steep"],
        explanation: "Il testo attribuisce entrambi i vantaggi alla safe route.",
        concept: "comparative evidence",
        glossary: [{ term: "shorter", meaning: "più corto" }, { term: "less steep", meaning: "meno ripido" }],
      },
      {
        log: "Notice: The report is formal enough for the teacher, but too informal for the external technician.",
        question: "Who needs a more formal report?",
        answer: "Risposta: external technician",
        answerDistractors: ["Risposta: teacher", "Risposta: both are satisfied"],
        evidence: "Prova: too informal for the external technician",
        evidenceDistractors: ["Prova: formal enough for the teacher", "Prova: enough means everyone"],
        explanation: "Enough vale per teacher; too informal identifica il tecnico esterno.",
        concept: "enough vs too",
        glossary: [{ term: "formal enough", meaning: "abbastanza formale" }, { term: "too informal", meaning: "troppo informale" }],
      },
    ];
    const item = random.pick(level >= 5 ? [...base, ...advanced] : base);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index * 20, item.answer, true, `Inferenza corretta. ${item.explanation}`),
      this.englishTile(index * 20 + 1, item.evidence, true, `Prova corretta. ${item.explanation}`),
      ...item.answerDistractors.map((label, choiceIndex) => this.englishTile(index * 20 + choiceIndex + 2, label, false, `Risposta non sostenuta dal log: ${item.explanation}`)),
      ...item.evidenceDistractors.map((label, choiceIndex) => this.englishTile(index * 20 + choiceIndex + 6, label, false, `Questa prova non giustifica la risposta: ${item.explanation}`)),
    ]);
    return {
      id: `english-reading-${index}`,
      type: "reading-detective",
      instruction: item.question,
      context: item.log,
      targetLabel: "Inferenza + prova",
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: [item.answer, item.evidence],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `reading-${item.log}-${item.answer}-${item.evidence}`,
    };
  }

  private buildErrorDiagnosisPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    type ErrorItem = {
      wrong: string;
      correction: string;
      correctionDistractors: string[];
      diagnosis: string;
      diagnosisDistractors: string[];
      explanation: string;
      concept: string;
      glossary: Array<{ term: string; meaning: string }>;
    };
    const base: ErrorItem[] = [
      {
        wrong: "She go to school every day.",
        correction: "Correzione: She goes to school every day.",
        correctionDistractors: ["Correzione: She is going to school every day.", "Correzione: She going to school every day."],
        diagnosis: "Diagnosi: third person -s",
        diagnosisDistractors: ["Diagnosi: past simple", "Diagnosi: preposition of place"],
        explanation: "Every day segnala abitudine; alla terza persona singolare serve goes.",
        concept: "present simple agreement",
        glossary: [{ term: "every day", meaning: "ogni giorno" }, { term: "third person", meaning: "terza persona" }],
      },
      {
        wrong: "There is three sensors in the room.",
        correction: "Correzione: There are three sensors in the room.",
        correctionDistractors: ["Correzione: There be three sensors in the room.", "Correzione: There has three sensors in the room."],
        diagnosis: "Diagnosi: there are + plural",
        diagnosisDistractors: ["Diagnosi: article a/an", "Diagnosi: comparative"],
        explanation: "Three sensors è plurale: si usa there are, non there is.",
        concept: "there is/are",
        glossary: [{ term: "there are", meaning: "ci sono" }, { term: "plural", meaning: "plurale" }],
      },
      {
        wrong: "The key is on the drawer.",
        correction: "Correzione: The key is in the drawer.",
        correctionDistractors: ["Correzione: The key is at the drawer.", "Correzione: The key is to the drawer."],
        diagnosis: "Diagnosi: in = inside a container",
        diagnosisDistractors: ["Diagnosi: future with will", "Diagnosi: modal verb"],
        explanation: "Se la chiave è dentro il cassetto, in è la preposizione corretta.",
        concept: "preposition of place",
        glossary: [{ term: "in", meaning: "dentro" }, { term: "drawer", meaning: "cassetto" }],
      },
    ];
    const advanced: ErrorItem[] = [
      {
        wrong: "I have finished the report yesterday.",
        correction: "Correzione: I finished the report yesterday.",
        correctionDistractors: ["Correzione: I have finish the report yesterday.", "Correzione: I am finished the report yesterday."],
        diagnosis: "Diagnosi: yesterday -> past simple",
        diagnosisDistractors: ["Diagnosi: present continuous", "Diagnosi: superlative"],
        explanation: "Yesterday è tempo concluso preciso: richiede past simple, non present perfect.",
        concept: "past simple vs present perfect",
        glossary: [{ term: "yesterday", meaning: "ieri" }, { term: "finished", meaning: "ho finito / finii" }],
      },
      {
        wrong: "If the alarm starts, close the door will.",
        correction: "Correzione: If the alarm starts, the door will close.",
        correctionDistractors: ["Correzione: If the alarm will start, the door closes.", "Correzione: If the alarm starts, the door closing."],
        diagnosis: "Diagnosi: first conditional word order",
        diagnosisDistractors: ["Diagnosi: many/much", "Diagnosi: article the"],
        explanation: "Primo condizionale: if + present, poi soggetto + will + verbo base.",
        concept: "first conditional",
        glossary: [{ term: "if", meaning: "se" }, { term: "will close", meaning: "si chiuderà" }],
      },
      {
        wrong: "The wires is checked every morning.",
        correction: "Correzione: The wires are checked every morning.",
        correctionDistractors: ["Correzione: The wires was checked every morning.", "Correzione: The wires be checked every morning."],
        diagnosis: "Diagnosi: plural subject -> are",
        diagnosisDistractors: ["Diagnosi: article a/an", "Diagnosi: comparative"],
        explanation: "Wires è plurale: nel passivo presente serve are checked.",
        concept: "present passive agreement",
        glossary: [{ term: "wires", meaning: "cavi" }, { term: "are checked", meaning: "sono controllati" }],
      },
      {
        wrong: "The battery were replaced yesterday.",
        correction: "Correzione: The battery was replaced yesterday.",
        correctionDistractors: ["Correzione: The battery is replace yesterday.", "Correzione: The battery has replaced yesterday."],
        diagnosis: "Diagnosi: singular passive was",
        diagnosisDistractors: ["Diagnosi: present simple habit", "Diagnosi: question word order"],
        explanation: "Battery è singolare e yesterday indica passato: was replaced.",
        concept: "past passive",
        glossary: [{ term: "was replaced", meaning: "è stata sostituita" }, { term: "yesterday", meaning: "ieri" }],
      },
      {
        wrong: "There are too much sensors in the box.",
        correction: "Correzione: There are too many sensors in the box.",
        correctionDistractors: ["Correzione: There is too many sensors in the box.", "Correzione: There are too much sensor in the box."],
        diagnosis: "Diagnosi: many + countable plural",
        diagnosisDistractors: ["Diagnosi: present perfect", "Diagnosi: preposition of time"],
        explanation: "Sensors è numerabile plurale: si usa many, non much.",
        concept: "much/many",
        glossary: [{ term: "many", meaning: "molti con nomi numerabili" }, { term: "sensors", meaning: "sensori" }],
      },
      {
        wrong: "I have already saw the warning.",
        correction: "Correzione: I have already seen the warning.",
        correctionDistractors: ["Correzione: I already seen the warning.", "Correzione: I have already see the warning."],
        diagnosis: "Diagnosi: present perfect participle",
        diagnosisDistractors: ["Diagnosi: future plan", "Diagnosi: superlative"],
        explanation: "Present perfect richiede have + participio passato: seen.",
        concept: "present perfect irregular participle",
        glossary: [{ term: "already", meaning: "già" }, { term: "seen", meaning: "visto" }],
      },
      {
        wrong: "The report is more clear than before.",
        correction: "Correzione: The report is clearer than before.",
        correctionDistractors: ["Correzione: The report is clear than before.", "Correzione: The report is clearest than before."],
        diagnosis: "Diagnosi: comparative -er",
        diagnosisDistractors: ["Diagnosi: modal obligation", "Diagnosi: past continuous"],
        explanation: "Con un aggettivo breve come clear si usa clearer than.",
        concept: "comparative adjective",
        glossary: [{ term: "clearer", meaning: "più chiaro" }, { term: "than", meaning: "di/che" }],
      },
      {
        wrong: "Can opens the robot the gate?",
        correction: "Correzione: Can the robot open the gate?",
        correctionDistractors: ["Correzione: The robot can opens the gate?", "Correzione: Can the robot opens the gate?"],
        diagnosis: "Diagnosi: modal + subject + base verb",
        diagnosisDistractors: ["Diagnosi: past simple did", "Diagnosi: article the"],
        explanation: "Nelle domande con can: can + soggetto + verbo base.",
        concept: "modal question word order",
        glossary: [{ term: "can", meaning: "può" }, { term: "open", meaning: "aprire" }],
      },
      {
        wrong: "Do not to touch the red wire.",
        correction: "Correzione: Do not touch the red wire.",
        correctionDistractors: ["Correzione: Do not touching the red wire.", "Correzione: Does not touch the red wire."],
        diagnosis: "Diagnosi: negative imperative + base verb",
        diagnosisDistractors: ["Diagnosi: plural there are", "Diagnosi: comparative"],
        explanation: "L'imperativo negativo usa do not + verbo base, senza to.",
        concept: "negative imperative",
        glossary: [{ term: "do not", meaning: "non" }, { term: "touch", meaning: "toccare" }],
      },
      {
        wrong: "The key is between the drawer.",
        correction: "Correzione: The key is in the drawer.",
        correctionDistractors: ["Correzione: The key is into the drawer.", "Correzione: The key is at the drawer."],
        diagnosis: "Diagnosi: in = inside one container",
        diagnosisDistractors: ["Diagnosi: between two objects", "Diagnosi: future will"],
        explanation: "Drawer è un contenitore singolo: serve in, non between.",
        concept: "preposition of place",
        glossary: [{ term: "in", meaning: "dentro" }, { term: "between", meaning: "tra due elementi" }],
      },
      {
        wrong: "If it will rain, the robot stops.",
        correction: "Correzione: If it rains, the robot stops.",
        correctionDistractors: ["Correzione: If it rain, the robot stops.", "Correzione: If it raining, the robot stops."],
        diagnosis: "Diagnosi: zero conditional present",
        diagnosisDistractors: ["Diagnosi: present perfect", "Diagnosi: article a/an"],
        explanation: "Nelle regole generali con if si usa il presente: if it rains.",
        concept: "zero conditional",
        glossary: [{ term: "if", meaning: "se" }, { term: "rains", meaning: "piove" }],
      },
      {
        wrong: "You mustn't to open the hatch.",
        correction: "Correzione: You mustn't open the hatch.",
        correctionDistractors: ["Correzione: You mustn't opening the hatch.", "Correzione: You don't must open the hatch."],
        diagnosis: "Diagnosi: modal + base verb",
        diagnosisDistractors: ["Diagnosi: past passive", "Diagnosi: there is/are"],
        explanation: "Dopo must/mustn't il verbo resta alla forma base, senza to.",
        concept: "modal prohibition",
        glossary: [{ term: "mustn't", meaning: "non devi" }, { term: "hatch", meaning: "sportello" }],
      },
      {
        wrong: "Where you put the key yesterday?",
        correction: "Correzione: Where did you put the key yesterday?",
        correctionDistractors: ["Correzione: Where do you put the key yesterday?", "Correzione: Where did you putted the key yesterday?"],
        diagnosis: "Diagnosi: past question did + base verb",
        diagnosisDistractors: ["Diagnosi: present continuous", "Diagnosi: possessive adjective"],
        explanation: "Domanda al past simple: wh-word + did + soggetto + verbo base.",
        concept: "past question",
        glossary: [{ term: "where", meaning: "dove" }, { term: "did", meaning: "ausiliare passato" }],
      },
      {
        wrong: "The file has loaded yet.",
        correction: "Correzione: The file has not loaded yet.",
        correctionDistractors: ["Correzione: The file has loaded already not.", "Correzione: The file load yet."],
        diagnosis: "Diagnosi: yet in negative sentence",
        diagnosisDistractors: ["Diagnosi: comparative", "Diagnosi: preposition of place"],
        explanation: "Yet indica non ancora in frasi negative: has not loaded yet.",
        concept: "present perfect yet",
        glossary: [{ term: "yet", meaning: "ancora / non ancora" }, { term: "loaded", meaning: "caricato" }],
      },
      {
        wrong: "This is the more safe route.",
        correction: "Correzione: This is the safest route.",
        correctionDistractors: ["Correzione: This is the safer route.", "Correzione: This is the most safe route."],
        diagnosis: "Diagnosi: superlative safest",
        diagnosisDistractors: ["Diagnosi: comparative between two", "Diagnosi: past passive"],
        explanation: "Con the e un confronto tra più alternative serve il superlativo: safest.",
        concept: "superlative adjective",
        glossary: [{ term: "safest", meaning: "il più sicuro" }, { term: "route", meaning: "percorso" }],
      },
      {
        wrong: "She don't understand the evidence.",
        correction: "Correzione: She doesn't understand the evidence.",
        correctionDistractors: ["Correzione: She doesn't understands the evidence.", "Correzione: She not understand the evidence."],
        diagnosis: "Diagnosi: third person doesn't + base verb",
        diagnosisDistractors: ["Diagnosi: passive voice", "Diagnosi: many/much"],
        explanation: "Terza persona singolare negativa: doesn't + verbo base.",
        concept: "present simple negative",
        glossary: [{ term: "doesn't", meaning: "non" }, { term: "evidence", meaning: "prova" }],
      },
      {
        wrong: "The robot is more fast than the drone.",
        correction: "Correzione: The robot is faster than the drone.",
        correctionDistractors: ["Correzione: The robot is fast than the drone.", "Correzione: The robot is fastest than the drone."],
        diagnosis: "Diagnosi: comparative faster",
        diagnosisDistractors: ["Diagnosi: superlative", "Diagnosi: modal verb"],
        explanation: "Fast è aggettivo breve: comparativo faster than.",
        concept: "comparative adjective",
        glossary: [{ term: "faster", meaning: "più veloce" }, { term: "than", meaning: "di/che" }],
      },
      {
        wrong: "Please you close the door.",
        correction: "Correzione: Please close the door.",
        correctionDistractors: ["Correzione: Please closing the door.", "Correzione: Please to close the door."],
        diagnosis: "Diagnosi: polite imperative",
        diagnosisDistractors: ["Diagnosi: wh-question", "Diagnosi: past perfect"],
        explanation: "L'imperativo cortese usa please + verbo base, senza soggetto you.",
        concept: "polite imperative",
        glossary: [{ term: "please", meaning: "per favore" }, { term: "close", meaning: "chiudere" }],
      },
      {
        wrong: "The informations are useful.",
        correction: "Correzione: The information is useful.",
        correctionDistractors: ["Correzione: The information are useful.", "Correzione: The informations is useful."],
        diagnosis: "Diagnosi: information is uncountable",
        diagnosisDistractors: ["Diagnosi: plural countable noun", "Diagnosi: future will"],
        explanation: "Information in inglese è non numerabile: singolare, senza -s.",
        concept: "uncountable noun",
        glossary: [{ term: "information", meaning: "informazione/i" }, { term: "useful", meaning: "utile" }],
      },
      {
        wrong: "I am agree with the report.",
        correction: "Correzione: I agree with the report.",
        correctionDistractors: ["Correzione: I am agreeing with the report.", "Correzione: I do agree to the report."],
        diagnosis: "Diagnosi: agree is not be + adjective",
        diagnosisDistractors: ["Diagnosi: present continuous action", "Diagnosi: preposition of place"],
        explanation: "Agree è un verbo: si dice I agree, non I am agree.",
        concept: "verb vs adjective",
        glossary: [{ term: "agree", meaning: "essere d'accordo" }, { term: "with", meaning: "con" }],
      },
      {
        wrong: "The students was ready.",
        correction: "Correzione: The students were ready.",
        correctionDistractors: ["Correzione: The students is ready.", "Correzione: The students be ready."],
        diagnosis: "Diagnosi: plural past be = were",
        diagnosisDistractors: ["Diagnosi: present simple", "Diagnosi: article a/an"],
        explanation: "Students è plurale: al passato del verbo be serve were.",
        concept: "past be agreement",
        glossary: [{ term: "students", meaning: "studenti" }, { term: "were", meaning: "erano" }],
      },
      {
        wrong: "I need an uniform for the lab.",
        correction: "Correzione: I need a uniform for the lab.",
        correctionDistractors: ["Correzione: I need the uniform a lab.", "Correzione: I need an uniforms for the lab."],
        diagnosis: "Diagnosi: a before /ju:/ sound",
        diagnosisDistractors: ["Diagnosi: plural article", "Diagnosi: past simple"],
        explanation: "Uniform inizia con suono /ju/ consonantico: si usa a, non an.",
        concept: "article a/an by sound",
        glossary: [{ term: "uniform", meaning: "uniforme" }, { term: "a/an", meaning: "un/una" }],
      },
      {
        wrong: "The test starts in Monday.",
        correction: "Correzione: The test starts on Monday.",
        correctionDistractors: ["Correzione: The test starts at Monday.", "Correzione: The test starts by Monday."],
        diagnosis: "Diagnosi: on + day",
        diagnosisDistractors: ["Diagnosi: in + month", "Diagnosi: at + time"],
        explanation: "Con i giorni della settimana si usa on: on Monday.",
        concept: "preposition of time",
        glossary: [{ term: "on Monday", meaning: "di lunedì" }, { term: "starts", meaning: "inizia" }],
      },
    ];
    const item = random.pick(level >= 5 ? [...base, ...advanced] : base);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index * 20, item.correction, true, `Correzione corretta. ${item.explanation}`),
      this.englishTile(index * 20 + 1, item.diagnosis, true, `Diagnosi corretta. ${item.explanation}`),
      ...item.correctionDistractors.map((label, choiceIndex) => this.englishTile(index * 20 + choiceIndex + 2, label, false, `La frase resta scorretta: ${item.explanation}`)),
      ...item.diagnosisDistractors.map((label, choiceIndex) => this.englishTile(index * 20 + choiceIndex + 6, label, false, `Diagnosi fuori bersaglio: ${item.explanation}`)),
    ]);
    return {
      id: `english-error-${index}`,
      type: "error-diagnosis",
      instruction: `Fix and diagnose: "${item.wrong}"`,
      context: "Una frase inglese è instabile: scegli la correzione e il motivo grammaticale.",
      targetLabel: "Correzione + diagnosi",
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: [item.correction, item.diagnosis],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `error-${item.wrong}-${item.correction}-${item.diagnosis}`,
    };
  }

  private buildDialogueResponsePrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    type DialogueItem = {
      situation: string;
      prompt: string;
      response: string;
      responseDistractors: string[];
      reason: string;
      reasonDistractors: string[];
      explanation: string;
      concept: string;
      glossary: Array<{ term: string; meaning: string }>;
    };
    const base: DialogueItem[] = [
      {
        situation: "A classmate asks: Can I borrow your ruler?",
        prompt: "Choose a polite useful reply.",
        response: "Risposta: Sure, here you are.",
        responseDistractors: ["Risposta: No ruler yesterday.", "Risposta: I am ruler."],
        reason: "Motivo: polite permission + object",
        reasonDistractors: ["Motivo: past time", "Motivo: place preposition"],
        explanation: "Sure, here you are è una risposta naturale e cortese a una richiesta semplice.",
        concept: "polite classroom response",
        glossary: [{ term: "borrow", meaning: "prendere in prestito" }, { term: "here you are", meaning: "ecco a te" }],
      },
      {
        situation: "The teacher says: The lab starts in five minutes.",
        prompt: "Choose the best response to show readiness.",
        response: "Risposta: I'm ready.",
        responseDistractors: ["Risposta: I ready yesterday.", "Risposta: Where is my lunch?"],
        reason: "Motivo: readiness now",
        reasonDistractors: ["Motivo: completed past action", "Motivo: unrelated topic"],
        explanation: "I'm ready risponde allo stato attuale richiesto dalla situazione.",
        concept: "short functional response",
        glossary: [{ term: "ready", meaning: "pronto" }, { term: "starts", meaning: "inizia" }],
      },
      {
        situation: "A sign says: Please keep the door closed.",
        prompt: "Choose the action-response that respects the sign.",
        response: "Risposta: OK, I will keep it closed.",
        responseDistractors: ["Risposta: I will open it now.", "Risposta: It closed yesterday?"],
        reason: "Motivo: keep closed repeats the instruction",
        reasonDistractors: ["Motivo: opposite action", "Motivo: question form only"],
        explanation: "Keep it closed riprende esattamente l'obbligo cortese del cartello.",
        concept: "instruction response",
        glossary: [{ term: "please", meaning: "per favore" }, { term: "keep closed", meaning: "tenere chiuso" }],
      },
    ];
    const advanced: DialogueItem[] = [
      {
        situation: "You need help by email: your file will not open before the deadline.",
        prompt: "Choose the most appropriate formal message.",
        response: "Risposta: Could you help me open the file, please?",
        responseDistractors: ["Risposta: Open my file now!!!", "Risposta: I file not open help?"],
        reason: "Motivo: polite request with could",
        reasonDistractors: ["Motivo: command too direct", "Motivo: wrong word order"],
        explanation: "Could you...? è una richiesta cortese e adatta a un'email scolastica.",
        concept: "polite request",
        glossary: [{ term: "could you", meaning: "potresti" }, { term: "deadline", meaning: "scadenza" }],
      },
      {
        situation: "A teammate reports: I found the cause of the error.",
        prompt: "Choose a response that asks for evidence.",
        response: "Risposta: What evidence did you find?",
        responseDistractors: ["Risposta: Because evidence found?", "Risposta: I ignore the cause."],
        reason: "Motivo: wh-question asks for proof",
        reasonDistractors: ["Motivo: because gives a cause", "Motivo: refusal to collaborate"],
        explanation: "What evidence did you find? chiede la prova in modo corretto: wh-word + did + subject + verb.",
        concept: "evidence question",
        glossary: [{ term: "evidence", meaning: "prova" }, { term: "did you find", meaning: "hai trovato" }],
      },
      {
        situation: "A visitor asks where the lab is.",
        prompt: "Choose a clear helpful reply.",
        response: "Risposta: It is next to the library.",
        responseDistractors: ["Risposta: Lab yesterday next.", "Risposta: I am the library."],
        reason: "Motivo: place preposition",
        reasonDistractors: ["Motivo: past time", "Motivo: identity sentence"],
        explanation: "Next to indica una posizione chiara e la frase ha soggetto + verbo.",
        concept: "giving directions",
        glossary: [{ term: "next to", meaning: "accanto a" }, { term: "library", meaning: "biblioteca" }],
      },
      {
        situation: "Your partner says: I don't understand this instruction.",
        prompt: "Choose a supportive response.",
        response: "Risposta: Let's read it together.",
        responseDistractors: ["Risposta: You are instruction.", "Risposta: Yesterday together read."],
        reason: "Motivo: collaborative suggestion",
        reasonDistractors: ["Motivo: wrong identity", "Motivo: past time confusion"],
        explanation: "Let's propone un'azione collaborativa naturale e utile.",
        concept: "collaborative classroom language",
        glossary: [{ term: "let's", meaning: "facciamo" }, { term: "together", meaning: "insieme" }],
      },
      {
        situation: "The teacher asks: Why is your conclusion still uncertain?",
        prompt: "Choose the best answer.",
        response: "Risposta: Because we need one more source.",
        responseDistractors: ["Risposta: Yes, it is source.", "Risposta: I am uncertain yesterday."],
        reason: "Motivo: because gives a cause",
        reasonDistractors: ["Motivo: yes/no answer", "Motivo: past-time mismatch"],
        explanation: "Why richiede una causa; because introduce il motivo dell'incertezza.",
        concept: "answering why",
        glossary: [{ term: "why", meaning: "perché" }, { term: "because", meaning: "perché / poiché" }],
      },
      {
        situation: "A teammate asks permission: Can I restart the tablet?",
        prompt: "Choose a safe conditional reply.",
        response: "Risposta: Yes, if the log is saved.",
        responseDistractors: ["Risposta: Restart because yes.", "Risposta: No save the log yesterday."],
        reason: "Motivo: permission with condition",
        reasonDistractors: ["Motivo: no condition", "Motivo: past irrelevant"],
        explanation: "Yes, if... dà permesso solo quando la condizione è rispettata.",
        concept: "conditional permission",
        glossary: [{ term: "if", meaning: "se" }, { term: "saved", meaning: "salvato" }],
      },
      {
        situation: "You need to interrupt politely during group work.",
        prompt: "Choose the polite phrase.",
        response: "Risposta: Excuse me, can I add something?",
        responseDistractors: ["Risposta: Stop talking now.", "Risposta: I add yesterday something?"],
        reason: "Motivo: polite interruption",
        reasonDistractors: ["Motivo: rude command", "Motivo: wrong question order"],
        explanation: "Excuse me + can I...? è una formula cortese per intervenire.",
        concept: "polite interruption",
        glossary: [{ term: "excuse me", meaning: "scusami/scusate" }, { term: "add", meaning: "aggiungere" }],
      },
      {
        situation: "A classmate says: I think this source is reliable.",
        prompt: "Choose a critical but polite response.",
        response: "Risposta: How can we check it?",
        responseDistractors: ["Risposta: You are wrong always.", "Risposta: Source check how can?"],
        reason: "Motivo: asks for verification",
        reasonDistractors: ["Motivo: personal attack", "Motivo: wrong word order"],
        explanation: "How can we check it? chiede verifica senza attaccare la persona.",
        concept: "critical thinking dialogue",
        glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "check", meaning: "controllare" }],
      },
      {
        situation: "The technician writes: Please send the report by 4 p.m.",
        prompt: "Choose an appropriate reply.",
        response: "Risposta: Sure, I will send it by 4 p.m.",
        responseDistractors: ["Risposta: I sent tomorrow yesterday.", "Risposta: No report is pizza."],
        reason: "Motivo: confirms deadline",
        reasonDistractors: ["Motivo: time words conflict", "Motivo: unrelated topic"],
        explanation: "La risposta conferma l'azione e la scadenza richiesta.",
        concept: "deadline response",
        glossary: [{ term: "send", meaning: "inviare" }, { term: "by 4 p.m.", meaning: "entro le 16" }],
      },
      {
        situation: "You made a mistake in the shared file.",
        prompt: "Choose a responsible response.",
        response: "Risposta: Sorry, I will correct it now.",
        responseDistractors: ["Risposta: It mistakes me never.", "Risposta: Correct yesterday sorry."],
        reason: "Motivo: apology + repair action",
        reasonDistractors: ["Motivo: denies responsibility", "Motivo: broken word order"],
        explanation: "Sorry + I will correct it now riconosce il problema e propone un'azione.",
        concept: "apology and repair",
        glossary: [{ term: "sorry", meaning: "mi dispiace" }, { term: "correct", meaning: "correggere" }],
      },
      {
        situation: "A teammate asks: Which route is safer?",
        prompt: "Choose the useful comparative answer.",
        response: "Risposta: The north route is safer.",
        responseDistractors: ["Risposta: North more safe route is.", "Risposta: Yes, route."],
        reason: "Motivo: comparative adjective",
        reasonDistractors: ["Motivo: wrong word order", "Motivo: incomplete answer"],
        explanation: "Safer è il comparativo corretto e la frase risponde alla domanda.",
        concept: "comparative response",
        glossary: [{ term: "safer", meaning: "più sicuro" }, { term: "route", meaning: "percorso" }],
      },
      {
        situation: "The teacher asks: Have you finished the report yet?",
        prompt: "Choose a clear honest answer.",
        response: "Risposta: Not yet, but I have checked the data.",
        responseDistractors: ["Risposta: Yes not finished already.", "Risposta: I finish yesterday tomorrow."],
        reason: "Motivo: present perfect with yet",
        reasonDistractors: ["Motivo: contradictory answer", "Motivo: conflicting time words"],
        explanation: "Not yet risponde correttamente a una domanda con yet e aggiunge progresso reale.",
        concept: "present perfect answer",
        glossary: [{ term: "not yet", meaning: "non ancora" }, { term: "checked", meaning: "controllato" }],
      },
      {
        situation: "A sign says: Do not touch the metal plate.",
        prompt: "Choose the safest response.",
        response: "Risposta: OK, I won't touch it.",
        responseDistractors: ["Risposta: I will touch it now.", "Risposta: Plate touch not yesterday."],
        reason: "Motivo: respects prohibition",
        reasonDistractors: ["Motivo: opposite action", "Motivo: broken sentence"],
        explanation: "I won't touch it rispetta il divieto del cartello.",
        concept: "responding to prohibition",
        glossary: [{ term: "won't", meaning: "non farò" }, { term: "touch", meaning: "toccare" }],
      },
      {
        situation: "You do not hear the instruction clearly.",
        prompt: "Choose a polite request.",
        response: "Risposta: Could you repeat that, please?",
        responseDistractors: ["Risposta: Repeat now you!", "Risposta: I not hear yesterday?"],
        reason: "Motivo: polite request",
        reasonDistractors: ["Motivo: rude imperative", "Motivo: time mismatch"],
        explanation: "Could you...? + please rende la richiesta cortese e corretta.",
        concept: "asking for repetition",
        glossary: [{ term: "repeat", meaning: "ripetere" }, { term: "please", meaning: "per favore" }],
      },
      {
        situation: "A classmate thanks you for help.",
        prompt: "Choose a natural reply.",
        response: "Risposta: You're welcome.",
        responseDistractors: ["Risposta: You welcome me.", "Risposta: I am thank."],
        reason: "Motivo: fixed polite formula",
        reasonDistractors: ["Motivo: literal translation", "Motivo: wrong verb"],
        explanation: "You're welcome è la risposta naturale a thank you.",
        concept: "polite formula",
        glossary: [{ term: "thank you", meaning: "grazie" }, { term: "you're welcome", meaning: "prego" }],
      },
      {
        situation: "The group needs a decision, but the evidence is incomplete.",
        prompt: "Choose a cautious response.",
        response: "Risposta: Let's collect more evidence first.",
        responseDistractors: ["Risposta: We are certainly finished.", "Risposta: Evidence more first collect let's?"],
        reason: "Motivo: cautious action before decision",
        reasonDistractors: ["Motivo: overconfident conclusion", "Motivo: wrong word order"],
        explanation: "More evidence first è prudente quando le prove sono incomplete.",
        concept: "cautious academic response",
        glossary: [{ term: "collect", meaning: "raccogliere" }, { term: "evidence", meaning: "prove" }],
      },
      {
        situation: "A teammate says: The file is missing.",
        prompt: "Choose a practical response.",
        response: "Risposta: Let's check the archive.",
        responseDistractors: ["Risposta: File missing happy.", "Risposta: We checked tomorrow."],
        reason: "Motivo: proposes next action",
        reasonDistractors: ["Motivo: unrelated adjective", "Motivo: time conflict"],
        explanation: "Let's check propone un'azione utile e collaborativa.",
        concept: "problem-solving response",
        glossary: [{ term: "missing", meaning: "mancante" }, { term: "archive", meaning: "archivio" }],
      },
      {
        situation: "The teacher says: Work quietly, please.",
        prompt: "Choose the response that shows understanding.",
        response: "Risposta: OK, we will work quietly.",
        responseDistractors: ["Risposta: We loud work please.", "Risposta: Quietly is yesterday."],
        reason: "Motivo: adverb of manner",
        reasonDistractors: ["Motivo: opposite manner", "Motivo: time mismatch"],
        explanation: "Work quietly riprende l'avverbio di modo richiesto.",
        concept: "adverb response",
        glossary: [{ term: "quietly", meaning: "in silenzio" }, { term: "work", meaning: "lavorare" }],
      },
      {
        situation: "You want to disagree politely with an idea.",
        prompt: "Choose a respectful response.",
        response: "Risposta: I see your point, but I think the data says otherwise.",
        responseDistractors: ["Risposta: Your idea is stupid.", "Risposta: Data otherwise think I but."],
        reason: "Motivo: polite disagreement with evidence",
        reasonDistractors: ["Motivo: rude personal comment", "Motivo: broken word order"],
        explanation: "La frase riconosce l'altro punto di vista e introduce una prova contraria.",
        concept: "polite disagreement",
        glossary: [{ term: "I see your point", meaning: "capisco il tuo punto" }, { term: "otherwise", meaning: "il contrario/altrimenti" }],
      },
      {
        situation: "A student asks: What does 'reliable' mean?",
        prompt: "Choose a helpful explanation.",
        response: "Risposta: It means you can trust it.",
        responseDistractors: ["Risposta: It means very colorful.", "Risposta: Trust can it you means."],
        reason: "Motivo: explains meaning in context",
        reasonDistractors: ["Motivo: unrelated meaning", "Motivo: wrong word order"],
        explanation: "Reliable riguarda fiducia/affidabilità, non aspetto.",
        concept: "explaining vocabulary",
        glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "trust", meaning: "fidarsi" }],
      },
      {
        situation: "The lab assistant asks: Are the samples ready?",
        prompt: "Choose a precise answer.",
        response: "Risposta: The red sample is ready, but the blue one is not.",
        responseDistractors: ["Risposta: Samples ready blue not red yes.", "Risposta: Every sample is ready."],
        reason: "Motivo: contrast with but",
        reasonDistractors: ["Motivo: broken syntax", "Motivo: overgeneralization"],
        explanation: "But distingue due stati senza dire che tutti i campioni sono pronti.",
        concept: "contrast response",
        glossary: [{ term: "ready", meaning: "pronto" }, { term: "but", meaning: "ma" }],
      },
      {
        situation: "A teammate asks: Should we open the archive now?",
        prompt: "Choose a safe answer.",
        response: "Risposta: Not until the green seal is on.",
        responseDistractors: ["Risposta: Yes, without the seal.", "Risposta: Archive now green not."],
        reason: "Motivo: not until sets a condition",
        reasonDistractors: ["Motivo: ignores condition", "Motivo: broken word order"],
        explanation: "Not until impone attesa fino alla condizione del sigillo verde.",
        concept: "conditional safety response",
        glossary: [{ term: "not until", meaning: "non prima che" }, { term: "seal", meaning: "sigillo" }],
      },
      {
        situation: "You need to ask for clarification in an email.",
        prompt: "Choose the formal sentence.",
        response: "Risposta: Could you clarify the last instruction, please?",
        responseDistractors: ["Risposta: What you mean???", "Risposta: Last instruction clarify could you please?"],
        reason: "Motivo: formal clarification request",
        reasonDistractors: ["Motivo: too informal", "Motivo: wrong question order"],
        explanation: "Could you clarify...? è cortese, chiaro e adatto a un'email.",
        concept: "formal email request",
        glossary: [{ term: "clarify", meaning: "chiarire" }, { term: "instruction", meaning: "istruzione" }],
      },
    ];
    const item = random.pick(level >= 5 ? [...base, ...advanced] : base);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index * 20, item.response, true, `Risposta corretta. ${item.explanation}`),
      this.englishTile(index * 20 + 1, item.reason, true, `Motivo corretto. ${item.explanation}`),
      ...item.responseDistractors.map((label, choiceIndex) => this.englishTile(index * 20 + choiceIndex + 2, label, false, `Risposta non adeguata: ${item.explanation}`)),
      ...item.reasonDistractors.map((label, choiceIndex) => this.englishTile(index * 20 + choiceIndex + 6, label, false, `Motivo non valido: ${item.explanation}`)),
    ]);
    return {
      id: `english-dialogue-${index}`,
      type: "dialogue-response",
      instruction: item.prompt,
      context: item.situation,
      targetLabel: "Risposta + motivo",
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: [item.response, item.reason],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `dialogue-${item.situation}-${item.response}-${item.reason}`,
    };
  }

  private pickVocabularyEntry(random: Random, level: number): EnglishVocabularyEntry {
    const cappedLevel = Math.max(1, Math.min(8, level));
    const pool = englishVocabularyByMaxLevel(cappedLevel);
    return random.pick(pool.length > 0 ? pool : englishVocabularyEntries);
  }

  private vocabularyDistractors(
    random: Random,
    item: EnglishVocabularyEntry,
    field: "term" | "meaning",
  ): string[] {
    return this.vocabularyDistractorEntries(random, item, field).map((entry) => field === "term" ? entry.term : entry.meaning);
  }

  private vocabularyDistractorEntries(
    random: Random,
    item: EnglishVocabularyEntry,
    field: "term" | "meaning",
  ): EnglishVocabularyEntry[] {
    const labelOf = (entry: EnglishVocabularyEntry): string => field === "term" ? entry.term : entry.meaning;
    const used = new Set<string>([labelOf(item)]);
    const closePool = englishVocabularyEntries.filter((entry) =>
      entry.id !== item.id
      && entry.category === item.category
      && entry.wordClass === item.wordClass
      && !used.has(labelOf(entry)),
    );
    const nearPool = englishVocabularyEntries.filter((entry) =>
      entry.id !== item.id
      && (entry.category === item.category || entry.wordClass === item.wordClass)
      && !used.has(labelOf(entry)),
    );
    const fallbackPool = englishVocabularyEntries.filter((entry) => entry.id !== item.id && !used.has(labelOf(entry)));
    const entries: EnglishVocabularyEntry[] = [];
    // Prefer semantically/grammatically CLOSE distractors (same category or word
    // class) so the answer can't be found by eliminating the wrong part of speech.
    // Only fall back to unrelated words if there aren't enough close ones.
    for (const entry of [...random.shuffle(closePool), ...random.shuffle(nearPool), ...random.shuffle(fallbackPool)]) {
      const label = labelOf(entry);
      if (!used.has(label)) {
        used.add(label);
        entries.push(entry);
      }
      if (entries.length >= 3) break;
    }
    return entries;
  }

  private vocabularyContext(item: EnglishVocabularyEntry): { prompt: string; explanation: string; concept: string } {
    const category = englishVocabularyCategoryLabels[item.category];
    const scenarioByCategory: Record<EnglishVocabularyEntry["category"], string> = {
      actions: "procedure di laboratorio e comandi operativi",
      objects: "strumenti, oggetti e parti della stanza",
      safety: "sicurezza, avvisi e prevenzione dei rischi",
      "data-science": "lettura di dati, esperimenti e conclusioni",
      "school-communication": "scuola, studio, email e spiegazioni",
      connectors: "relazioni logiche tra due idee",
      "false-friends": "falsi amici frequenti per studenti italiani",
      "home-family": "vita quotidiana, casa e relazioni familiari",
      "food-shopping": "pasti, negozi, prezzi e acquisti",
      "time-weather": "orari, abitudini, stagioni e meteo",
      "travel-places": "spostamenti, indicazioni e luoghi pubblici",
      "body-health": "corpo, salute, sintomi e appuntamenti",
      "feelings-opinions": "emozioni, carattere e opinioni personali",
      "digital-media": "telefono, computer, app e comunicazione online",
      "jobs-community": "lavori, servizi pubblici e comunità",
      "leisure-culture": "sport, hobby, musica, film e letture",
      "nature-environment": "ambiente, animali, luoghi naturali e clima",
      "everyday-phrases": "collocazioni e frasi frequenti della vita quotidiana",
    };
    return {
      prompt: [
        `Scenario: ${scenarioByCategory[item.category]}.`,
        `Mission card: ____ = "${item.meaning}".`,
        `Choose an English ${item.wordClass}; distractors are close, so use meaning and context together.`,
      ].join(" "),
      explanation: `La parola corretta è "${item.term}": significa "${item.meaning}" ed appartiene a ${category}.`,
      concept: `${category} · ${item.wordClass}`,
    };
  }

  private englishMinigameConcepts(type: EnglishMinigameType): string[] {
    if (type === "action-relay") return ["imperative", "object choice", "prohibition"];
    if (type === "sequence-switchboard") return ["before/after", "condition", "sequence"];
    if (type === "grammar-fix") return ["verb tenses", "grammar choice", "word forms"];
    if (type === "sentence-build") return ["word order", "sentence structure", "questions"];
    if (type === "vocab-lab") return ["vocabulary", "false friends", "technical register"];
    if (type === "translation-match") return ["translation recognition", "bilingual vocabulary", "false friends"];
    if (type === "reading-detective") return ["reading comprehension", "text evidence", "inference"];
    if (type === "error-diagnosis") return ["error analysis", "grammar repair", "metalinguistic diagnosis"];
    if (type === "dialogue-response") return ["communication", "register", "appropriate response"];
    return ["data reading", "threshold", "comparison"];
  }

  private englishMinigamePurpose(type: EnglishMinigameType): string {
    if (type === "action-relay") return "Allena comprensione e giustificazione del comando: significato operativo più vincolo linguistico esplicito.";
    if (type === "sequence-switchboard") return "Allena lettura di before, after, until, unless e if come vincoli di procedura.";
    if (type === "grammar-fix") return "Allena la grammatica della scuola media: tempi verbali, comparativi, modali, preposizioni, quantificatori e domande.";
    if (type === "sentence-build") return "Allena la costruzione della frase e della domanda in inglese: ordine soggetto-verbo e posizione dell'ausiliare.";
    if (type === "vocab-lab") return "Allena vocabolario inglese in contesto: termini tecnici, falsi amici, prove, sicurezza e registro formale.";
    if (type === "translation-match") return "Allena il riconoscimento rapido della traduzione italiana corretta, con distrattori vicini e falsi amici.";
    if (type === "reading-detective") return "Allena comprensione di brevi testi: lo studente deve scegliere l'inferenza e la prova testuale che la sostiene.";
    if (type === "error-diagnosis") return "Allena grammatica attiva: non basta scegliere la forma, bisogna riconoscere il tipo di errore.";
    if (type === "dialogue-response") return "Allena inglese comunicativo scolastico: risposta adeguata, registro cortese e scopo della conversazione.";
    return "Allena lettura di dati semplici in inglese: below, above, between, dimmer, brighter e soglie.";
  }

  private englishMinigameMethod(type: EnglishMinigameType): string {
    if (type === "action-relay") return "Scegli due prove: cosa bisogna fare e quale parola inglese lo giustifica o limita.";
    if (type === "sequence-switchboard") return "Sottolinea le parole-tempo: before, after, until, then, unless. Poi ordina le azioni.";
    if (type === "grammar-fix") return "Riconosci il segnale (every day, now, yesterday, than, must...) e scegli la forma che lo rispetta.";
    if (type === "sentence-build") return "Parti dal soggetto, poi il verbo; nelle domande metti l'ausiliare prima del soggetto.";
    if (type === "vocab-lab") return "Leggi il contesto e scegli la parola che rende il messaggio tecnicamente corretto: attenzione a falsi amici e registro.";
    if (type === "translation-match") return "Leggi la parola inglese, richiama il significato italiano e scarta distrattori simili o falsi amici.";
    if (type === "reading-detective") return "Prima rispondi alla domanda, poi scegli la frase del testo che dimostra la risposta.";
    if (type === "error-diagnosis") return "Ripara la frase e nomina l'errore: tempo verbale, accordo, ordine, preposizione o condizione.";
    if (type === "dialogue-response") return "Identifica situazione, rapporto tra persone e scopo; poi scegli la risposta naturale e il motivo.";
    return "Leggi la soglia o il confronto, confronta i dati, poi scegli una sola azione.";
  }

  private englishMinigameMethodSteps(type: EnglishMinigameType): string[] {
    if (type === "action-relay") return ["meaning", "text evidence", "limiter"];
    if (type === "sequence-switchboard") return ["time word", "first event", "safe action"];
    if (type === "grammar-fix") return ["find the signal", "recall the rule", "pick the form"];
    if (type === "sentence-build") return ["subject", "verb", "rest / aux first in questions"];
    if (type === "vocab-lab") return ["context", "meaning", "best word"];
    if (type === "translation-match") return ["English term", "Italian meaning", "false-friend check"];
    if (type === "reading-detective") return ["question", "answer", "text evidence"];
    if (type === "error-diagnosis") return ["wrong sentence", "repair", "error type"];
    if (type === "dialogue-response") return ["situation", "purpose", "appropriate reply"];
    return ["threshold", "data", "action"];
  }

  fallback(random?: Random, difficultyLevel = 1): GeneratedEnglishPuzzle {
    const source = random ?? new Random("english-fallback");
    const eligible = englishTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const template = this.specializeTemplate(source.pick(eligible.length > 0 ? eligible : englishTemplates), source.fork("template"), difficultyLevel);
    const choices = source.shuffle([
      { id: `${template.id}-correct`, label: template.correctLabel, isCorrect: true, feedback: template.correctFeedback ?? "Sequenza operativa corretta." },
      ...template.distractors.map((distractor, index) => ({
        id: `${template.id}-fallback-${index}`,
        label: distractor.label,
        isCorrect: false,
        feedback: distractor.feedback,
      })),
    ]);
    return {
      ...this.buildPuzzle(template, choices, difficultyLevel),
      id: `english-fallback-${template.id}-${source.integer(1000, 9999)}`,
    };
  }

  private specializeTemplate(template: EnglishTemplate, random: Random, difficultyLevel: number): EnglishTemplate {
    if (template.id === "sensor-below-threshold") {
      const pods = random.shuffle(["A", "B", "C"]);
      const threshold = random.pick([22, 24, 25, 28]);
      const lowValue = random.integer(12, threshold - 2);
      const safeOne = random.integer(threshold + 3, threshold + 14);
      const safeTwo = random.integer(threshold + 15, threshold + 28);
      const target = pods[0];
      const dataPoints = [
        { label: `Pod ${target}`, value: `moisture ${lowValue}` },
        { label: `Pod ${pods[1]}`, value: `moisture ${safeOne}` },
        { label: `Pod ${pods[2]}`, value: `moisture ${safeTwo}` },
      ].sort((a, b) => a.label.localeCompare(b.label));
      return {
        ...template,
        instruction: `Water the pod whose moisture is below ${threshold}. Leave the other pods unchanged.`,
        dataPoints,
        correctLabel: `Water pod ${target} only`,
        distractors: [
          { label: "Water all pods", feedback: `Whose moisture is below ${threshold} limita l'azione solo alla capsula sotto soglia.` },
          { label: `Water pod ${pods[1]} only`, feedback: `Pod ${pods[1]} è sopra ${threshold}: below significa sotto la soglia, non vicino alla soglia.` },
          { label: "Do nothing", feedback: `Pod ${target} è sotto ${threshold}, quindi almeno un intervento è richiesto.` },
        ],
        diagnosticSteps: [`Below ${threshold} definisce la soglia.`, `Confronta ogni valore con ${threshold}.`, "Only evita interventi sulle capsule già stabili."],
      };
    }

    if (template.id === "compare-two-signals") {
      const labels = random.shuffle(["A", "B"]);
      const dimmerValue = random.integer(28, 48);
      const brighterValue = random.integer(dimmerValue + 15, dimmerValue + 40);
      return {
        ...template,
        dataPoints: [
          { label: `Signal ${labels[0]}`, value: `${dimmerValue} lux` },
          { label: `Signal ${labels[1]}`, value: `${brighterValue} lux` },
        ],
        correctLabel: `Choose ${labels[0]} -> Lock ${labels[1]}`,
        distractors: [
          { label: `Choose ${labels[1]} -> Lock ${labels[0]}`, feedback: "Dimmer indica il segnale meno luminoso: viene scelto per primo." },
          { label: "Lock both signals", feedback: "Il comando distingue due azioni diverse: choose e lock non sono equivalenti." },
          { label: `Ignore signal ${labels[0]}`, feedback: `Signal ${labels[0]} è il meno luminoso nei dati, quindi è proprio quello da scegliere.` },
        ],
      };
    }

    if (template.id === "between-limits") {
      const low = random.pick([16, 18, 19]);
      const high = low + random.pick([5, 6, 7]);
      const inside = random.bool(0.72);
      const value = inside ? random.integer(low, high) : random.pick([random.integer(low - 5, low - 1), random.integer(high + 1, high + 5)]);
      const correctLabel = inside ? `${value}°C -> Vent halfway` : `${value}°C -> Keep vent closed`;
      return {
        ...template,
        instruction: `If the temperature is between ${low} and ${high} degrees, open the vent halfway; otherwise keep it closed.`,
        dataPoints: [{ label: "Temperature", value: `${value}°C` }],
        correctLabel,
        distractors: inside
          ? [
              { label: `${value}°C -> Keep vent closed`, feedback: `${value} è tra ${low} e ${high}, quindi vale la prima parte del comando.` },
              { label: `${value}°C -> Fully open vent`, feedback: "Halfway significa a metà, non completamente aperto." },
              { label: `Below ${low}°C -> Vent halfway`, feedback: `Between ${low} and ${high} esclude i valori sotto ${low}.` },
            ]
          : [
              { label: `${value}°C -> Vent halfway`, feedback: `${value} è fuori dall'intervallo ${low}-${high}, quindi si applica otherwise.` },
              { label: `${value}°C -> Fully open vent`, feedback: "Halfway sarebbe comunque a metà; in questo caso il comando chiede di tenere chiuso." },
              { label: `Between ${low}-${high}°C -> Keep closed`, feedback: "Dentro l'intervallo la ventola va aperta a metà, non tenuta chiusa." },
            ],
        diagnosticSteps: ["If introduce la condizione.", `Between ${low} and ${high} definisce un intervallo.`, `${value} è ${inside ? "dentro" : "fuori"} l'intervallo.`, "Otherwise vale solo fuori intervallo."],
      };
    }

    if (template.id === "cause-report" && difficultyLevel >= 6) {
      const causes = [
        { cause: "the cooling fan stopped", effect: "the archive shut down", detail: "the warning light turned purple" },
        { cause: "the backup battery failed", effect: "the door locked itself", detail: "the status icon flashed twice" },
        { cause: "the water pump jammed", effect: "the greenhouse paused irrigation", detail: "the side lamp turned orange" },
      ];
      const picked = random.pick(causes);
      return {
        ...template,
        sourceText: `Log: At 07:${random.integer(20, 58)} ${picked.detail}. ${picked.cause}, so ${picked.effect}.`,
        correctLabel: `Cause: ${picked.cause}`,
        distractors: [
          { label: "Time from the log", feedback: "Il testo dice do not report the time: l'orario è un dettaglio escluso." },
          { label: `Detail: ${picked.detail}`, feedback: "Il dettaglio visivo è nel log ma non risponde alla richiesta sulla causa." },
          { label: `Effect: ${picked.effect}`, feedback: "Questo è l'effetto da spiegare, non la causa che lo ha prodotto." },
        ],
      };
    }

    return template;
  }

  private defaultConceptTags(templateId: string): string[] {
    if (["green-not-red", "small-key"].includes(templateId)) return ["action verbs", "do not", "object choice"];
    if (["where-is-core", "movement-prepositions-route", "relative-where-lab"].includes(templateId)) return ["prepositions", "spatial reading", "technical nouns"];
    if (["who-can-open", "question-formation-why"].includes(templateId)) return ["question words", "can/did", "permission or cause"];
    if (["main-switch", "left-before-blue", "measure-before-switch", "after-robot-dock", "have-to-vs-can", "multi-clause-mission-order"].includes(templateId)) return ["sequence", "before/after", "procedure"];
    if (["simple-vs-now"].includes(templateId)) return ["present simple", "present continuous", "now"];
    if (["past-log-today", "past-vs-present-perfect-log"].includes(templateId)) return ["past simple", "present state", "time markers"];
    if (["present-perfect-already-yet"].includes(templateId)) return ["present perfect", "already", "yet"];
    if (["some-any-fuses", "much-many-supplies"].includes(templateId)) return ["quantity", "countable/uncountable", "prohibition"];
    if (["frequency-adverbs"].includes(templateId)) return ["frequency adverbs", "when", "cause/effect"];
    if (["going-to-scan"].includes(templateId)) return ["future plan", "going to", "after"];
    if (["pronoun-reference", "possessive-their-its"].includes(templateId)) return ["pronouns", "possessives", "reference"];
    if (["only-if-stable", "sensor-below-threshold", "first-conditional-alarm", "zero-conditional-rule"].includes(templateId)) return ["if/otherwise", "condition", "threshold"];
    if (["unless-blue-blinks", "until-door-unlocks", "reported-warning"].includes(templateId)) return ["unless/until", "exception", "waiting"];
    if (["compare-two-signals", "which-route-safest", "as-as-comparison"].includes(templateId)) return ["comparison", "adjectives", "data reading"];
    if (["relative-drawer"].includes(templateId)) return ["relative clause", "that", "technical nouns"];
    if (["may-must-not", "passive-reattach-wire", "passive-simple-past", "must-should-cable"].includes(templateId)) return ["modal verbs", "passive", "safety"];
    if (["although-however-report", "main-idea-log", "detail-not-mentioned", "scientific-observation-evidence"].includes(templateId)) return ["reading comprehension", "inference", "evidence"];
    if (["adverbs-manner-safety"].includes(templateId)) return ["adverbs of manner", "sequence", "safety"];
    if (["word-formation-re-over"].includes(templateId)) return ["word formation", "prefixes", "technical verbs"];
    if (["either-neither-tool"].includes(templateId)) return ["neither/nor", "instead", "safety"];
    if (["email-register-formal"].includes(templateId)) return ["formal register", "because", "short writing"];
    return ["operational English", "condition", "safe action"];
  }

  private defaultHints(templateId: string): string[] {
    if (templateId.includes("unless")) return ["Unless introduce un'eccezione: prima leggi il divieto, poi l'unico caso permesso.", "Controlla quale condizione sblocca l'azione."];
    if (templateId.includes("until")) return ["Until indica fino a quando devi aspettare.", "Non anticipare l'azione finale: cerca then."];
    return ["Cerca prima il verbo d'azione.", "Poi controlla se c'è un divieto, una condizione o un ordine temporale."];
  }

  private defaultMethod(type: EnglishTemplate["challengeType"]): string {
    if (type === "data-reading") return "Prima leggi la soglia o il comparativo, poi confronta i dati e scegli l'azione che soddisfa la condizione.";
    if (type === "procedure-debug") return "Confronta istruzione e log guasto: correggi ordine, oggetti e azioni senza aggiungere passaggi.";
    if (type === "inference") return "Individua la richiesta, elimina i dettagli vietati o inutili e conserva solo l'informazione necessaria.";
    if (type === "sequence") return "Sottolinea i verbi, poi usa before, after o then per ricostruire l'ordine.";
    if (type === "safety") return "Trova prima l'azione permessa, poi marca ogni oggetto dentro il divieto.";
    if (type === "vocabulary-in-context") return "Interpreta le parole tecniche dal contesto e controlla i limitatori come only, must e should not.";
    return "Individua verbo, oggetto, condizione e divieto; poi controlla l'ordine delle azioni.";
  }

  private defaultMethodSteps(type: EnglishTemplate["challengeType"]): string[] {
    if (type === "data-reading") return ["parola chiave", "dato", "decisione"];
    if (type === "procedure-debug") return ["istruzione", "log guasto", "correzione"];
    if (type === "inference") return ["richiesta", "dettagli esclusi", "risposta"];
    if (type === "sequence") return ["verbi", "connettore", "ordine"];
    if (type === "safety") return ["permesso", "divieto", "oggetto"];
    if (type === "vocabulary-in-context") return ["termine", "contesto", "azione"];
    return ["verbo", "oggetto", "vincolo"];
  }

  private defaultGlossary(template: EnglishTemplate): Array<{ term: string; meaning: string }> {
    const glossary: Array<{ term: string; meaning: string }> = [];
    const text = template.instruction.toLowerCase();
    if (text.includes("press")) glossary.push({ term: "press", meaning: "premere" });
    if (text.includes("take")) glossary.push({ term: "take", meaning: "prendere" });
    if (text.includes("insert")) glossary.push({ term: "insert", meaning: "inserire" });
    if (text.includes("turn on")) glossary.push({ term: "turn on", meaning: "accendere / attivare" });
    if (text.includes("before")) glossary.push({ term: "before", meaning: "prima di" });
    if (text.includes("after")) glossary.push({ term: "after", meaning: "dopo che" });
    if (text.includes("if")) glossary.push({ term: "if", meaning: "se" });
    if (text.includes("otherwise")) glossary.push({ term: "otherwise", meaning: "altrimenti" });
    if (text.includes("unless")) glossary.push({ term: "unless", meaning: "a meno che / salvo se" });
    if (text.includes("until")) glossary.push({ term: "until", meaning: "finché / fino a quando" });
    if (text.includes("below")) glossary.push({ term: "below", meaning: "sotto" });
    if (text.includes("whose")) glossary.push({ term: "whose", meaning: "il cui / la cui" });
    if (text.includes("only")) glossary.push({ term: "only", meaning: "solo" });
    if (text.includes("write down")) glossary.push({ term: "write down", meaning: "annotare" });
    if (text.includes("must")) glossary.push({ term: "must", meaning: "deve / obbligo" });
    if (text.includes("have to")) glossary.push({ term: "have to", meaning: "dovere / obbligo" });
    if (text.includes("should not")) glossary.push({ term: "should not", meaning: "non dovrebbe" });
    if (text.includes("cause")) glossary.push({ term: "cause", meaning: "causa" });
    if (text.includes("dimmer")) glossary.push({ term: "dimmer", meaning: "meno luminoso" });
    if (text.includes("brighter")) glossary.push({ term: "brighter", meaning: "più luminoso" });
    if (text.includes("under")) glossary.push({ term: "under", meaning: "sotto" });
    if (text.includes("between")) glossary.push({ term: "between", meaning: "tra" });
    if (text.includes("usually")) glossary.push({ term: "usually", meaning: "di solito" });
    if (text.includes("often")) glossary.push({ term: "often", meaning: "spesso" });
    if (text.includes("rarely")) glossary.push({ term: "rarely", meaning: "raramente" });
    if (text.includes("safest")) glossary.push({ term: "safest", meaning: "il più sicuro" });
    if (text.includes("may")) glossary.push({ term: "may", meaning: "può / permesso" });
    if (text.includes("has been")) glossary.push({ term: "has been", meaning: "è stato / forma passiva" });
    if (text.includes("was repaired")) glossary.push({ term: "was repaired", meaning: "è stato riparato" });
    if (text.includes("yesterday")) glossary.push({ term: "yesterday", meaning: "ieri" });
    if (text.includes("offline")) glossary.push({ term: "offline", meaning: "non attivo" });
    if (text.includes("some")) glossary.push({ term: "some", meaning: "alcuni / un po'" });
    if (text.includes("many")) glossary.push({ term: "many", meaning: "molti, con nomi numerabili" });
    if (text.includes("little")) glossary.push({ term: "little", meaning: "poco, con nomi non numerabili" });
    if (text.includes("no spare")) glossary.push({ term: "no spare", meaning: "nessun ricambio" });
    if (text.includes("going to")) glossary.push({ term: "going to", meaning: "ha in programma di" });
    if (text.includes("them")) glossary.push({ term: "them", meaning: "li / loro" });
    if (text.includes("already")) glossary.push({ term: "already", meaning: "già" });
    if (text.includes("yet")) glossary.push({ term: "yet", meaning: "ancora / non ancora" });
    if (text.includes("although")) glossary.push({ term: "although", meaning: "sebbene / anche se" });
    if (text.includes("however")) glossary.push({ term: "however", meaning: "tuttavia" });
    if (text.includes("neither")) glossary.push({ term: "neither...nor", meaning: "né...né" });
    if (text.includes("because")) glossary.push({ term: "because", meaning: "perché / poiché" });
    if (text.includes("as stable as")) glossary.push({ term: "as...as", meaning: "tanto...quanto" });
    if (text.includes("through")) glossary.push({ term: "through", meaning: "attraverso un passaggio" });
    if (text.includes("across")) glossary.push({ term: "across", meaning: "attraverso una superficie" });
    if (text.includes("into")) glossary.push({ term: "into", meaning: "verso l'interno" });
    return glossary.slice(0, 5);
  }

  private competenciesFor(templateId: string): string[] {
    const base = ["inglese.istruzioni", "pensieroCritico"];
    if (["sensor-below-threshold", "compare-two-signals", "between-limits", "which-route-safest", "first-conditional-alarm", "as-as-comparison", "scientific-observation-evidence"].includes(templateId)) return [...base, "inglese.scientifico", "inglese.dati"];
    if (["where-is-core", "replace-only-damaged", "relative-drawer", "some-any-fuses", "possessive-their-its", "movement-prepositions-route", "much-many-supplies", "relative-where-lab", "word-formation-re-over", "either-neither-tool"].includes(templateId)) return [...base, "inglese.lessico"];
    if (["who-can-open", "simple-vs-now", "past-log-today", "frequency-adverbs", "going-to-scan", "pronoun-reference", "may-must-not", "passive-reattach-wire", "must-should-cable", "present-perfect-already-yet", "past-vs-present-perfect-log", "question-formation-why", "adverbs-manner-safety", "passive-simple-past", "have-to-vs-can", "reported-warning"].includes(templateId)) return [...base, "inglese.grammatica", "inglese.comprensione"];
    if (["unless-blue-blinks", "until-door-unlocks", "only-if-stable", "not-until-pressure-drops", "zero-conditional-rule", "multi-clause-mission-order"].includes(templateId)) return [...base, "inglese.bilingue", "inglese.grammatica"];
    if (["cause-report", "procedure-debug-charge", "although-however-report", "main-idea-log", "detail-not-mentioned", "email-register-formal"].includes(templateId)) return [...base, "inglese.bilingue", "inglese.comprensione"];
    return base;
  }

  private levelName(level: number): string {
    if (level <= 2) return "comandi, oggetti e spazio";
    if (level <= 4) return "tempi base, quantità e sequenze";
    if (level <= 6) return "condizioni, dati e comprensione";
    return "eccezioni, inferenze e registro";
  }
}
