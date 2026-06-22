import { englishTemplates, type EnglishTemplate } from "../../data/procedural/englishTemplates";
import type {
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
      : random.pick<EnglishMinigameType>(["action-relay", "sequence-switchboard", "data-command-scan"]);
    const minigame = this.buildMinigame(random.fork(type), level, type);
    const first = minigame.prompts[0];
    const choices = first.tiles.map((tile) => ({
      id: tile.id,
      label: tile.label,
      isCorrect: tile.isCorrect,
      feedback: tile.feedback,
    }));
    return {
      id: `english-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      challengeType: type === "data-command-scan" ? "data-reading" : type === "sequence-switchboard" ? "sequence" : "command",
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
    let previousSignature = "";
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniqueMinigamePrompt(random, level, type, index, previousSignature);
      prompts.push(prompt);
      previousSignature = prompt.signature;
    }
    const titles: Record<EnglishMinigameType, string> = {
      "action-relay": "Minigioco inglese: Action Relay",
      "sequence-switchboard": "Minigioco inglese: Sequence Switchboard",
      "data-command-scan": "Minigioco inglese: Data Command Scan",
    };
    const instructions: Record<EnglishMinigameType, string> = {
      "action-relay": "clicca l'azione corretta leggendo verbo, oggetto e divieto.",
      "sequence-switchboard": "clicca l'azione che rispetta before, after, then, until o unless.",
      "data-command-scan": "clicca l'azione coerente con soglia, confronto o intervallo.",
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
      ])),
    };
  }

  private uniqueMinigamePrompt(
    random: Random,
    level: number,
    type: EnglishMinigameType,
    index: number,
    previousSignature: string,
  ): EnglishMinigamePrompt {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const prompt = this.buildMinigamePrompt(random, level, type, index + attempt);
      if (prompt.signature !== previousSignature) {
        return prompt;
      }
    }
    return this.buildMinigamePrompt(random, level, type, index + 99);
  }

  private buildMinigamePrompt(random: Random, level: number, type: EnglishMinigameType, index: number): EnglishMinigamePrompt {
    if (type === "action-relay") return this.buildActionRelayPrompt(random, level, index);
    if (type === "sequence-switchboard") return this.buildSequenceSwitchboardPrompt(random, level, index);
    return this.buildDataCommandScanPrompt(random, level, index);
  }

  private buildActionRelayPrompt(random: Random, level: number, index: number): EnglishMinigamePrompt {
    const pool = [
      {
        instruction: "Press the green button. Do not press the red button.",
        correct: "Press green",
        distractors: ["Press red", "Press both", "Do nothing"],
        explanation: "Do not press the red button vieta il rosso; il comando positivo resta green.",
        glossary: [{ term: "press", meaning: "premere" }, { term: "do not", meaning: "non fare" }, { term: "green/red", meaning: "verde/rosso" }],
        concept: "imperative + prohibition",
      },
      {
        instruction: "Take the small key, not the large key.",
        correct: "Take small key",
        distractors: ["Take large key", "Take both keys", "Leave the key"],
        explanation: "Not the large key esclude la chiave grande: resta small key.",
        glossary: [{ term: "take", meaning: "prendere" }, { term: "small", meaning: "piccolo" }, { term: "large", meaning: "grande" }],
        concept: "object adjective",
      },
      {
        instruction: "Open the left drawer and keep the right drawer closed.",
        correct: "Open left drawer",
        distractors: ["Open right drawer", "Close left drawer", "Open both drawers"],
        explanation: "Left e right distinguono due oggetti; il destro deve restare chiuso.",
        glossary: [{ term: "open", meaning: "aprire" }, { term: "left/right", meaning: "sinistra/destra" }, { term: "keep closed", meaning: "tenere chiuso" }],
        concept: "spatial direction",
      },
      {
        instruction: "Insert the blue card only.",
        correct: "Insert blue card",
        distractors: ["Insert yellow card", "Insert every card", "Remove blue card"],
        explanation: "Only limita l'azione alla card blu.",
        glossary: [{ term: "insert", meaning: "inserire" }, { term: "only", meaning: "solo" }, { term: "card", meaning: "scheda" }],
        concept: "only limiter",
      },
    ];
    const advanced = [
      {
        instruction: "Replace the damaged cable, but leave the spare cable in the box.",
        correct: "Replace damaged cable",
        distractors: ["Replace spare cable", "Replace both cables", "Leave damaged cable"],
        explanation: "Damaged identifica il cavo da sostituire; spare resta nella scatola.",
        glossary: [{ term: "replace", meaning: "sostituire" }, { term: "damaged", meaning: "danneggiato" }, { term: "spare", meaning: "di ricambio" }],
        concept: "technical adjective",
      },
      {
        instruction: "Switch off neither the pump nor the sensor.",
        correct: "Keep both on",
        distractors: ["Switch off pump", "Switch off sensor", "Switch off both"],
        explanation: "Neither...nor esclude entrambe le azioni: non spegnere né pompa né sensore.",
        glossary: [{ term: "switch off", meaning: "spegnere" }, { term: "neither...nor", meaning: "né...né" }, { term: "keep on", meaning: "tenere acceso" }],
        concept: "neither/nor prohibition",
      },
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Not safe: ${item.explanation}`)),
    ]);
    return {
      id: `english-action-${index}`,
      type: "action-relay",
      instruction: item.instruction,
      context: "Choose the action the Academy system can safely execute.",
      targetLabel: "Action to execute",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `action-${item.instruction}-${item.correct}`,
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

  private englishMinigameConcepts(type: EnglishMinigameType): string[] {
    if (type === "action-relay") return ["imperative", "object choice", "prohibition"];
    if (type === "sequence-switchboard") return ["before/after", "condition", "sequence"];
    return ["data reading", "threshold", "comparison"];
  }

  private englishMinigamePurpose(type: EnglishMinigameType): string {
    if (type === "action-relay") return "Allena riconoscimento rapido di verbi operativi, oggetti, colori, direzioni e divieti.";
    if (type === "sequence-switchboard") return "Allena lettura di before, after, until, unless e if come vincoli di procedura.";
    return "Allena lettura di dati semplici in inglese: below, above, between, dimmer, brighter e soglie.";
  }

  private englishMinigameMethod(type: EnglishMinigameType): string {
    if (type === "action-relay") return "Trova verbo d'azione e oggetto, poi controlla not, only, neither e aggettivi.";
    if (type === "sequence-switchboard") return "Sottolinea le parole-tempo: before, after, until, then, unless. Poi ordina le azioni.";
    return "Leggi la soglia o il confronto, confronta i dati, poi scegli una sola azione.";
  }

  private englishMinigameMethodSteps(type: EnglishMinigameType): string[] {
    if (type === "action-relay") return ["verb", "object", "not/only"];
    if (type === "sequence-switchboard") return ["time word", "first event", "safe action"];
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
