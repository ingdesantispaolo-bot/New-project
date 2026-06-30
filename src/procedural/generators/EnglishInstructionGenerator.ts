import { englishTemplates, type EnglishTemplate } from "../../data/procedural/englishTemplates";
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
    const eligibleTemplates = englishTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const floor = Math.max(1, difficultyLevel - 2);
    const focusedTemplates = eligibleTemplates.filter((template) => (template.minDifficulty ?? 1) >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : englishTemplates;
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
      : random.pick<EnglishMinigameType>(["action-relay", "sequence-switchboard", "data-command-scan", "grammar-fix", "sentence-build", "vocab-lab", "translation-match"]);
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
          : type === "grammar-fix" ? "vocabulary-in-context"
            : type === "vocab-lab" ? "vocabulary-in-context"
              : type === "translation-match" ? "translation-recognition"
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
    };
    const instructions: Record<EnglishMinigameType, string> = {
      "action-relay": "clicca l'azione corretta leggendo verbo, oggetto e divieto.",
      "sequence-switchboard": "clicca l'azione che rispetta before, after, then, until o unless.",
      "data-command-scan": "clicca l'azione coerente con soglia, confronto o intervallo.",
      "grammar-fix": "scegli la forma corretta: tempo verbale, comparativo, modale, preposizione o quantificatore.",
      "sentence-build": "tocca le parole nell'ordine giusto per formare la frase o la domanda in inglese.",
      "vocab-lab": "scegli la parola inglese più adatta al contesto tecnico o scientifico.",
      "translation-match": "riconosci la traduzione italiana corretta di una parola o breve frase inglese.",
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
        return prompt;
      }
    }
    return first ?? this.buildMinigamePrompt(random, level, type, index + 99);
  }

  private buildMinigamePrompt(random: Random, level: number, type: EnglishMinigameType, index: number): EnglishMinigamePrompt {
    if (type === "action-relay") return this.buildActionRelayPrompt(random, level, index);
    if (type === "sequence-switchboard") return this.buildSequenceSwitchboardPrompt(random, level, index);
    if (type === "grammar-fix") return this.buildGrammarFixPrompt(random, level, index);
    if (type === "sentence-build") return this.buildSentenceBuildPrompt(random, level, index);
    if (type === "vocab-lab") return this.buildVocabularyPrompt(random, level, index);
    if (type === "translation-match") return this.buildTranslationMatchPrompt(random, level, index);
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
        meaning: "Esegui: premi il pulsante verde",
        meaningDistractors: ["Esegui: premi il pulsante rosso", "Esegui: premi entrambi i pulsanti"],
        evidence: "Vincolo: do not vieta il rosso",
        evidenceDistractors: ["Vincolo: red è l'azione principale", "Vincolo: green e red sono equivalenti"],
        explanation: "Do not press the red button vieta il rosso; il comando positivo resta green.",
        glossary: [{ term: "press", meaning: "premere" }, { term: "do not", meaning: "non fare" }, { term: "green/red", meaning: "verde/rosso" }],
        concept: "imperative + prohibition",
      },
      {
        instruction: "Take the small key, not the large key.",
        meaning: "Esegui: prendi la chiave piccola",
        meaningDistractors: ["Esegui: prendi la chiave grande", "Esegui: prendi entrambe le chiavi"],
        evidence: "Vincolo: not the large key esclude quella grande",
        evidenceDistractors: ["Vincolo: large indica la chiave corretta", "Vincolo: not permette entrambe"],
        explanation: "Not the large key esclude la chiave grande: resta small key.",
        glossary: [{ term: "take", meaning: "prendere" }, { term: "small", meaning: "piccolo" }, { term: "large", meaning: "grande" }],
        concept: "object adjective",
      },
      {
        instruction: "Open the left drawer and keep the right drawer closed.",
        meaning: "Esegui: apri il cassetto sinistro",
        meaningDistractors: ["Esegui: apri il cassetto destro", "Esegui: apri entrambi i cassetti"],
        evidence: "Vincolo: keep closed mantiene chiuso il destro",
        evidenceDistractors: ["Vincolo: right drawer va aperto", "Vincolo: left significa destra"],
        explanation: "Left e right distinguono due oggetti; il destro deve restare chiuso.",
        glossary: [{ term: "open", meaning: "aprire" }, { term: "left/right", meaning: "sinistra/destra" }, { term: "keep closed", meaning: "tenere chiuso" }],
        concept: "spatial direction",
      },
      {
        instruction: "Insert the blue card only.",
        meaning: "Esegui: inserisci solo la scheda blu",
        meaningDistractors: ["Esegui: inserisci la scheda gialla", "Esegui: inserisci tutte le schede"],
        evidence: "Vincolo: only limita l'azione alla scheda blu",
        evidenceDistractors: ["Vincolo: only permette ogni scheda", "Vincolo: insert significa rimuovere"],
        explanation: "Only limita l'azione alla card blu.",
        glossary: [{ term: "insert", meaning: "inserire" }, { term: "only", meaning: "solo" }, { term: "card", meaning: "scheda" }],
        concept: "only limiter",
      },
      {
        instruction: "Save the report, but do not send it yet.",
        meaning: "Esegui: salva il report",
        meaningDistractors: ["Esegui: invia subito il report", "Esegui: cancella il report"],
        evidence: "Vincolo: do not send it yet blocca l'invio",
        evidenceDistractors: ["Vincolo: yet significa subito", "Vincolo: but cancella il comando save"],
        explanation: "Save è permesso; do not send it yet vieta l'invio per ora.",
        glossary: [{ term: "save", meaning: "salvare" }, { term: "send", meaning: "inviare" }, { term: "yet", meaning: "ancora / per ora" }],
        concept: "allowed action + delayed action",
      },
      {
        instruction: "Mark the verified source and ignore the rumor.",
        meaning: "Esegui: segnala la fonte verificata",
        meaningDistractors: ["Esegui: segnala la voce non verificata", "Esegui: ignora la fonte verificata"],
        evidence: "Vincolo: verified source è affidabile, rumor va ignorata",
        evidenceDistractors: ["Vincolo: rumor è una prova verificata", "Vincolo: ignore riguarda la fonte verificata"],
        explanation: "Verified source è la fonte controllata; rumor è la voce da ignorare.",
        glossary: [{ term: "mark", meaning: "segnare" }, { term: "verified", meaning: "verificato" }, { term: "rumor", meaning: "voce non verificata" }],
        concept: "source reliability",
      },
      {
        instruction: "Keep the backup switch on. Turn off the test lamp.",
        meaning: "Esegui: spegni la lampada di test",
        meaningDistractors: ["Esegui: spegni lo switch di backup", "Esegui: spegni entrambi"],
        evidence: "Vincolo: keep on protegge lo switch di backup",
        evidenceDistractors: ["Vincolo: keep on significa spegnere", "Vincolo: turn off riguarda entrambi"],
        explanation: "Keep on preserva lo switch di backup; turn off riguarda solo la lampada di test.",
        glossary: [{ term: "keep on", meaning: "tenere acceso" }, { term: "turn off", meaning: "spegnere" }, { term: "backup", meaning: "riserva" }],
        concept: "two commands with different objects",
      },
    ] satisfies ActionRelayItem[];
    const advanced = [
      {
        instruction: "Replace the damaged cable, but leave the spare cable in the box.",
        meaning: "Esegui: sostituisci il cavo danneggiato",
        meaningDistractors: ["Esegui: sostituisci il cavo di ricambio", "Esegui: sostituisci entrambi i cavi"],
        evidence: "Vincolo: damaged identifica il cavo da cambiare",
        evidenceDistractors: ["Vincolo: spare è il cavo guasto", "Vincolo: leave significa sostituire"],
        explanation: "Damaged identifica il cavo da sostituire; spare resta nella scatola.",
        glossary: [{ term: "replace", meaning: "sostituire" }, { term: "damaged", meaning: "danneggiato" }, { term: "spare", meaning: "di ricambio" }],
        concept: "technical adjective",
      },
      {
        instruction: "Switch off neither the pump nor the sensor.",
        meaning: "Esegui: lascia accesi pompa e sensore",
        meaningDistractors: ["Esegui: spegni la pompa", "Esegui: spegni entrambi"],
        evidence: "Vincolo: neither...nor vieta entrambe le azioni",
        evidenceDistractors: ["Vincolo: neither...nor autorizza lo spegnimento", "Vincolo: nor riguarda solo il sensore"],
        explanation: "Neither...nor esclude entrambe le azioni: non spegnere né pompa né sensore.",
        glossary: [{ term: "switch off", meaning: "spegnere" }, { term: "neither...nor", meaning: "né...né" }, { term: "keep on", meaning: "tenere acceso" }],
        concept: "neither/nor prohibition",
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
          { label: `Pod ${target}`, value: `${low}`, note: "below threshold" },
          { label: `Pod ${pods[1]}`, value: `${safeOne}`, note: "safe" },
          { label: `Pod ${pods[2]}`, value: `${safeTwo}`, note: "safe" },
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
          { label: `${target} panel`, value: `${high}°C`, note: "above limit" },
          { label: `${panels[1]} panel`, value: `${lowOne}°C`, note: "safe" },
          { label: `${panels[2]} panel`, value: `${lowTwo}°C`, note: "safe" },
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
        [{ label: "Temperature", value: `${value}°C`, note: "inside range" }],
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
        { label: `Signal ${labels[0]}`, value: `${dimmer} lux`, note: "dimmer" },
        { label: `Signal ${labels[1]}`, value: `${brighter} lux`, note: "brighter" },
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
      { instruction: "She ___ to school every day. (ogni giorno)", correct: "goes", distractors: ["go", "is going", "going"], explanation: "Present simple per le abitudini: alla terza persona si aggiunge -es (go → goes).", concept: "present simple", glossary: [{ term: "every day", meaning: "ogni giorno" }, { term: "goes", meaning: "va" }] },
      { instruction: "Look! The robot ___ a box now. (now)", correct: "is carrying", distractors: ["carries", "carry", "carried"], explanation: "Present continuous per ciò che accade ora: be + verbo-ing.", concept: "present continuous", glossary: [{ term: "now", meaning: "adesso" }, { term: "carry", meaning: "trasportare" }] },
      { instruction: "Yesterday we ___ the test. (yesterday)", correct: "started", distractors: ["start", "starts", "starting"], explanation: "Past simple per il passato concluso: verbi regolari in -ed.", concept: "past simple", glossary: [{ term: "yesterday", meaning: "ieri" }, { term: "start", meaning: "iniziare" }] },
      { instruction: "This cable is ___ than that one.", correct: "longer", distractors: ["long", "longest", "more long"], explanation: "Comparativo di maggioranza con aggettivo corto: -er + than.", concept: "comparative", glossary: [{ term: "than", meaning: "di/che (confronto)" }, { term: "long", meaning: "lungo" }] },
      { instruction: "This is the ___ room in the lab.", correct: "biggest", distractors: ["bigger", "big", "most big"], explanation: "Superlativo con aggettivo corto: the + -est (big → biggest).", concept: "superlative", glossary: [{ term: "the biggest", meaning: "il più grande" }] },
      { instruction: "You ___ wear gloves here. (obbligo)", correct: "must", distractors: ["mustn't", "can", "should"], explanation: "Must esprime obbligo; mustn't sarebbe divieto.", concept: "modal: obligation", glossary: [{ term: "must", meaning: "dovere (obbligo)" }, { term: "gloves", meaning: "guanti" }] },
      { instruction: "Robots ___ lift heavy boxes. (capacità)", correct: "can", distractors: ["must", "should", "can't"], explanation: "Can esprime capacità/abilità.", concept: "modal: ability", glossary: [{ term: "can", meaning: "potere/sapere" }, { term: "lift", meaning: "sollevare" }] },
      { instruction: "You look tired. You ___ rest. (consiglio)", correct: "should", distractors: ["must", "mustn't", "can't"], explanation: "Should dà un consiglio, non un obbligo.", concept: "modal: advice", glossary: [{ term: "should", meaning: "dovere (consiglio)" }, { term: "rest", meaning: "riposare" }] },
      { instruction: "The key is ___ the drawer. (dentro)", correct: "in", distractors: ["on", "at", "to"], explanation: "In per ciò che è dentro un contenitore.", concept: "preposition of place", glossary: [{ term: "in", meaning: "dentro" }, { term: "drawer", meaning: "cassetto" }] },
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
    ];
    const item = random.pick(level >= 4 ? [...base, ...advanced] : base);
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
    ];
    const item = random.pick(level >= 4 ? [...base, ...advanced] : base);
    const words = item.sentence.split(/\s+/);
    const isQuestion = ["does", "did", "where", "do", "is", "are", "can"].includes(words[0].toLowerCase());
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
    const pool = [
      {
        instruction: "Choose the word that completes the technical sentence.",
        context: "The sensor is not broken; it needs a new ___ before the test.",
        correct: "calibration",
        distractors: ["decoration", "rumor", "shortcut"],
        explanation: "Calibration è regolazione della misura; decoration e rumor non sono procedure tecniche.",
        glossary: [{ term: "calibration", meaning: "calibrazione" }, { term: "broken", meaning: "rotto" }, { term: "test", meaning: "prova" }],
        concept: "technical nouns",
      },
      {
        instruction: "Choose the safest vocabulary in context.",
        context: "A note with no name or date is not reliable evidence; it is only a ___.",
        correct: "rumor",
        distractors: ["proof", "measurement", "source"],
        explanation: "Rumor è voce non verificata; proof e measurement indicano prove.",
        glossary: [{ term: "rumor", meaning: "voce non verificata" }, { term: "evidence", meaning: "prova" }, { term: "reliable", meaning: "affidabile" }],
        concept: "evidence vocabulary",
      },
      {
        instruction: "Pick the word that matches the warning.",
        context: "The cable is hot. Touching it is ___ until the power is off.",
        correct: "unsafe",
        distractors: ["accurate", "empty", "silent"],
        explanation: "Unsafe riguarda rischio; accurate significa accurato, non sicuro.",
        glossary: [{ term: "unsafe", meaning: "non sicuro" }, { term: "accurate", meaning: "accurato" }, { term: "power off", meaning: "alimentazione spenta" }],
        concept: "safety adjective",
      },
      {
        instruction: "Choose the word that describes the data.",
        context: "Two sensors show the same number, so the result is more ___.",
        correct: "reliable",
        distractors: ["random", "decorative", "noisy"],
        explanation: "Reliable significa affidabile; i dati confermati sono più affidabili.",
        glossary: [{ term: "reliable", meaning: "affidabile" }, { term: "random", meaning: "casuale" }, { term: "noisy", meaning: "rumoroso / disturbato" }],
        concept: "data reliability",
      },
      {
        instruction: "Complete the operating log.",
        context: "Do not guess. First collect enough ___ for your conclusion.",
        correct: "evidence",
        distractors: ["paint", "buttons", "speed"],
        explanation: "Evidence sono prove; una conclusione non va basata su tentativi.",
        glossary: [{ term: "evidence", meaning: "prove" }, { term: "guess", meaning: "indovinare" }, { term: "conclusion", meaning: "conclusione" }],
        concept: "critical thinking vocabulary",
      },
      {
        instruction: "Choose the correct technical verb.",
        context: "If the backup battery is low, ___ it before restarting the door.",
        correct: "recharge",
        distractors: ["rewrite", "rename", "repaint"],
        explanation: "Recharge significa ricaricare una batteria; gli altri prefissi re- non sono adatti.",
        glossary: [{ term: "recharge", meaning: "ricaricare" }, { term: "rewrite", meaning: "riscrivere" }, { term: "restart", meaning: "riavviare" }],
        concept: "word formation re-",
      },
      {
        instruction: "Choose the word that fits the route.",
        context: "The robot moves ___ the tunnel, not across the roof.",
        correct: "through",
        distractors: ["under", "between", "above"],
        explanation: "Through indica attraversare un passaggio; across sarebbe su una superficie.",
        glossary: [{ term: "through", meaning: "attraverso un passaggio" }, { term: "across", meaning: "attraverso una superficie" }, { term: "tunnel", meaning: "tunnel" }],
        concept: "movement prepositions",
      },
    ];
    const advanced = [
      {
        instruction: "Avoid the false friend.",
        context: "The log is ___: it gives exact values and clear limits.",
        correct: "accurate",
        distractors: ["actual", "eventual", "sensible"],
        explanation: "Accurate significa preciso; actual significa reale/effettivo, non attuale.",
        glossary: [{ term: "accurate", meaning: "preciso" }, { term: "actual", meaning: "reale / effettivo" }, { term: "sensible", meaning: "ragionevole" }],
        concept: "false friends",
      },
      {
        instruction: "Choose the word for a limited conclusion.",
        context: "The data ___ that the valve may be blocked, but they do not prove it yet.",
        correct: "suggest",
        distractors: ["prove", "decorate", "erase"],
        explanation: "Suggest indica suggerire un'ipotesi; prove sarebbe troppo forte.",
        glossary: [{ term: "suggest", meaning: "suggerire" }, { term: "prove", meaning: "dimostrare" }, { term: "yet", meaning: "ancora" }],
        concept: "hedging and evidence",
      },
      {
        instruction: "Choose the register that fits a formal report.",
        context: "The technician will ___ the damaged module, not just 'fix the thing'.",
        correct: "repair",
        distractors: ["mess up", "hang out with", "look pretty at"],
        explanation: "Repair è verbo tecnico/formale; gli altri non appartengono a un report.",
        glossary: [{ term: "repair", meaning: "riparare" }, { term: "damaged", meaning: "danneggiato" }, { term: "module", meaning: "modulo" }],
        concept: "formal technical register",
      },
      {
        instruction: "Choose the word that completes the scientific note.",
        context: "A repeated test makes the observation more ___.",
        correct: "consistent",
        distractors: ["lonely", "painted", "forbidden"],
        explanation: "Consistent indica coerenza tra prove ripetute.",
        glossary: [{ term: "consistent", meaning: "coerente / costante" }, { term: "repeated", meaning: "ripetuto" }, { term: "observation", meaning: "osservazione" }],
        concept: "scientific vocabulary",
      },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Not this word: ${item.explanation}`)),
    ]);
    return {
      id: `english-vocab-${index}`,
      type: "vocab-lab",
      instruction: item.instruction,
      context: item.context,
      targetLabel: "Vocabulary in context",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `vocab-${item.context}-${item.correct}`,
    };
  }

  private buildTranslationMatchPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    type TranslationItem = {
      term: string;
      correct: string;
      distractors: string[];
      explanation: string;
      concept: string;
      register: string;
    };
    const base: TranslationItem[] = [
      {
        term: "above",
        correct: "sopra",
        distractors: ["sotto", "tra due elementi", "accanto a"],
        explanation: "Above indica una posizione più alta: è il contrario di below.",
        concept: "spatial prepositions",
        register: "preposizione di luogo",
      },
      {
        term: "below",
        correct: "sotto",
        distractors: ["sopra", "attraverso", "lontano da"],
        explanation: "Below significa sotto una soglia o sotto un punto di riferimento.",
        concept: "spatial and data prepositions",
        register: "preposizione di luogo/dato",
      },
      {
        term: "through",
        correct: "attraverso un passaggio",
        distractors: ["sopra una superficie", "tra due oggetti", "prima di agire"],
        explanation: "Through descrive un movimento dentro e fuori da un passaggio, come un tunnel.",
        concept: "movement prepositions",
        register: "preposizione di movimento",
      },
      {
        term: "switch off",
        correct: "spegnere",
        distractors: ["accendere", "sbloccare", "ricaricare"],
        explanation: "Switch off e turn off indicano spegnere un dispositivo.",
        concept: "phrasal verbs",
        register: "verbo operativo",
      },
      {
        term: "reliable",
        correct: "affidabile",
        distractors: ["casuale", "rotto", "rumoroso"],
        explanation: "Reliable descrive qualcosa di cui ci si può fidare, come una fonte o una misura.",
        concept: "evidence vocabulary",
        register: "aggettivo valutativo",
      },
      {
        term: "evidence",
        correct: "prova / elementi di prova",
        distractors: ["decorazione", "velocità", "scorciatoia"],
        explanation: "Evidence sono le prove che sostengono una conclusione.",
        concept: "critical thinking vocabulary",
        register: "nome astratto",
      },
      {
        term: "warning",
        correct: "avviso di pericolo",
        distractors: ["ricompensa", "misura precisa", "strumento di ricambio"],
        explanation: "Warning segnala un rischio o qualcosa a cui prestare attenzione.",
        concept: "safety vocabulary",
        register: "nome operativo",
      },
      {
        term: "source",
        correct: "fonte",
        distractors: ["interruttore", "cavo", "risultato finale"],
        explanation: "Source è la fonte da cui arriva un'informazione.",
        concept: "information literacy",
        register: "nome scolastico/scientifico",
      },
    ];
    const advanced: TranslationItem[] = [
      {
        term: "actual",
        correct: "reale / effettivo",
        distractors: ["attuale", "eventuale", "sensibile"],
        explanation: "Actual è un falso amico: non significa attuale, ma reale o effettivo.",
        concept: "false friends",
        register: "falso amico",
      },
      {
        term: "eventually",
        correct: "alla fine",
        distractors: ["eventualmente", "subito", "raramente"],
        explanation: "Eventually significa alla fine; non equivale all'italiano eventualmente.",
        concept: "false friends",
        register: "avverbio",
      },
      {
        term: "sensible",
        correct: "ragionevole",
        distractors: ["sensibile", "silenzioso", "sperimentale"],
        explanation: "Sensible significa ragionevole; sensitive è la parola per sensibile.",
        concept: "false friends",
        register: "aggettivo",
      },
      {
        term: "consistent",
        correct: "coerente / costante",
        distractors: ["abbondante", "provvisorio", "pericoloso"],
        explanation: "Consistent descrive risultati che restano coerenti nel tempo o tra prove.",
        concept: "scientific vocabulary",
        register: "aggettivo scientifico",
      },
      {
        term: "to suggest",
        correct: "suggerire / indicare come ipotesi",
        distractors: ["dimostrare con certezza", "cancellare", "decorare"],
        explanation: "Suggest è più debole di prove: indica un'ipotesi plausibile, non una prova definitiva.",
        concept: "hedging and evidence",
        register: "verbo di ragionamento",
      },
    ];
    const item = random.pick(level >= 5 ? [...base, ...advanced] : base);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Traduzione non corretta: ${item.explanation}`)),
    ]);
    return {
      id: `english-translation-${index}`,
      type: "translation-match",
      instruction: `What does "${item.term}" mean in Italian?`,
      context: `Vocabulary card: "${item.term}" | ${item.register}`,
      targetLabel: "Traduzione corretta",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: [
        { term: "task", meaning: "scegli la traduzione italiana corretta" },
        { term: "watch out", meaning: "controlla falsi amici e contesto" },
      ],
      signature: `translation-${item.term}-${item.correct}`,
    };
  }

  private englishMinigameConcepts(type: EnglishMinigameType): string[] {
    if (type === "action-relay") return ["imperative", "object choice", "prohibition"];
    if (type === "sequence-switchboard") return ["before/after", "condition", "sequence"];
    if (type === "grammar-fix") return ["verb tenses", "grammar choice", "word forms"];
    if (type === "sentence-build") return ["word order", "sentence structure", "questions"];
    if (type === "vocab-lab") return ["vocabulary", "false friends", "technical register"];
    if (type === "translation-match") return ["translation recognition", "bilingual vocabulary", "false friends"];
    return ["data reading", "threshold", "comparison"];
  }

  private englishMinigamePurpose(type: EnglishMinigameType): string {
    if (type === "action-relay") return "Allena riconoscimento rapido di verbi operativi, oggetti, colori, direzioni e divieti.";
    if (type === "sequence-switchboard") return "Allena lettura di before, after, until, unless e if come vincoli di procedura.";
    if (type === "grammar-fix") return "Allena la grammatica della scuola media: tempi verbali, comparativi, modali, preposizioni, quantificatori e domande.";
    if (type === "sentence-build") return "Allena la costruzione della frase e della domanda in inglese: ordine soggetto-verbo e posizione dell'ausiliare.";
    if (type === "vocab-lab") return "Allena vocabolario inglese in contesto: termini tecnici, falsi amici, prove, sicurezza e registro formale.";
    if (type === "translation-match") return "Allena il riconoscimento rapido della traduzione italiana corretta, con distrattori vicini e falsi amici.";
    return "Allena lettura di dati semplici in inglese: below, above, between, dimmer, brighter e soglie.";
  }

  private englishMinigameMethod(type: EnglishMinigameType): string {
    if (type === "action-relay") return "Trova verbo d'azione e oggetto, poi controlla not, only, neither e aggettivi.";
    if (type === "sequence-switchboard") return "Sottolinea le parole-tempo: before, after, until, then, unless. Poi ordina le azioni.";
    if (type === "grammar-fix") return "Riconosci il segnale (every day, now, yesterday, than, must...) e scegli la forma che lo rispetta.";
    if (type === "sentence-build") return "Parti dal soggetto, poi il verbo; nelle domande metti l'ausiliare prima del soggetto.";
    if (type === "vocab-lab") return "Leggi il contesto e scegli la parola che rende il messaggio tecnicamente corretto: attenzione a falsi amici e registro.";
    if (type === "translation-match") return "Leggi la parola inglese, richiama il significato italiano e scarta distrattori simili o falsi amici.";
    return "Leggi la soglia o il confronto, confronta i dati, poi scegli una sola azione.";
  }

  private englishMinigameMethodSteps(type: EnglishMinigameType): string[] {
    if (type === "action-relay") return ["verb", "object", "not/only"];
    if (type === "sequence-switchboard") return ["time word", "first event", "safe action"];
    if (type === "grammar-fix") return ["find the signal", "recall the rule", "pick the form"];
    if (type === "sentence-build") return ["subject", "verb", "rest / aux first in questions"];
    if (type === "vocab-lab") return ["context", "meaning", "best word"];
    if (type === "translation-match") return ["English term", "Italian meaning", "false-friend check"];
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
        { label: `Pod ${target}`, value: `moisture ${lowValue}`, note: "below threshold" },
        { label: `Pod ${pods[1]}`, value: `moisture ${safeOne}`, note: "safe" },
        { label: `Pod ${pods[2]}`, value: `moisture ${safeTwo}`, note: "safe" },
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
          { label: `Signal ${labels[0]}`, value: `${dimmerValue} lux`, note: "dimmer" },
          { label: `Signal ${labels[1]}`, value: `${brighterValue} lux`, note: "brighter" },
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
        dataPoints: [{ label: "Temperature", value: `${value}°C`, note: inside ? "inside range" : "outside range" }],
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
