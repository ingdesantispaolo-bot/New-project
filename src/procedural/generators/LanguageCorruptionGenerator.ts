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
      : random.pick<LanguageMinigameType>(["agreement-sprint", "connector-route", "intruder-hunt"]);
    const minigame = this.buildMinigame(random.fork(type), level, type);
    const first = minigame.prompts[0];
    const options = first.tiles.map((tile) => tile.label);
    const optionFeedback: Record<string, string> = {};
    first.tiles.forEach((tile) => {
      optionFeedback[tile.label] = tile.feedback;
    });
    return {
      id: `language-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      corrupted: first.context,
      repaired: first.solutionLabels[0],
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

  fallback(): GeneratedLanguagePuzzle {
    const template = languageTemplates[0];
    return { ...this.buildPuzzle(template, [template.repaired, ...template.distractors], 1), id: "language-fallback" };
  }

  private buildMinigame(random: Random, level: number, type: LanguageMinigameType): GeneratedLanguageMinigame {
    const promptCount = 18 + level;
    const prompts: LanguageMinigamePrompt[] = [];
    let previousSignature = "";
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniqueMinigamePrompt(random, level, type, index, previousSignature);
      prompts.push(prompt);
      previousSignature = prompt.signature;
    }
    const titles: Record<LanguageMinigameType, string> = {
      "agreement-sprint": "Minigioco italiano: Concordanze lampo",
      "connector-route": "Minigioco italiano: Rotte dei connettivi",
      "intruder-hunt": "Minigioco italiano: Intruso nel log",
    };
    const instructions: Record<LanguageMinigameType, string> = {
      "agreement-sprint": "clicca la forma che rende la frase corretta per genere, numero e verbo.",
      "connector-route": "clicca il connettivo che mantiene il rapporto logico tra le informazioni.",
      "intruder-hunt": "clicca il dettaglio inutile o contraddittorio rispetto allo scopo del log.",
    };
    return {
      type,
      title: titles[type],
      durationMs: 60_000,
      instructions: instructions[type],
      scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. La velocità vale solo se resta precisa.",
      prompts,
      competencies: Array.from(new Set([
        "italiano.comprensione",
        "italiano.grammatica",
        "pensieroCritico",
        ...(type === "agreement-sprint" ? ["italiano.coesione"] : []),
        ...(type === "connector-route" ? ["italiano.coesione", "italiano.argomentazione"] : []),
        ...(type === "intruder-hunt" ? ["italiano.lessico", "italiano.scritturaBreve"] : []),
      ])),
    };
  }

  private uniqueMinigamePrompt(
    random: Random,
    level: number,
    type: LanguageMinigameType,
    index: number,
    previousSignature: string,
  ): LanguageMinigamePrompt {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const prompt = this.buildMinigamePrompt(random, level, type, index + attempt);
      if (prompt.signature !== previousSignature) {
        return prompt;
      }
    }
    return this.buildMinigamePrompt(random, level, type, index + 99);
  }

  private buildMinigamePrompt(random: Random, level: number, type: LanguageMinigameType, index: number): LanguageMinigamePrompt {
    if (type === "agreement-sprint") return this.buildAgreementPrompt(random, level, index);
    if (type === "connector-route") return this.buildConnectorPrompt(random, level, index);
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
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Non regge: ${item.explanation}`)),
    ]);
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

  private languageMinigameConcepts(type: LanguageMinigameType): string[] {
    if (type === "agreement-sprint") return ["accordo", "soggetto", "concordanza"];
    if (type === "connector-route") return ["connettivi", "logica del testo", "coesione"];
    return ["comprensione", "informazioni utili", "pensiero critico"];
  }

  private languageMinigamePurpose(type: LanguageMinigameType): string {
    if (type === "agreement-sprint") return "Allena riconoscimento rapido di accordi, soggetti reali e forme verbali corrette.";
    if (type === "connector-route") return "Allena scelta dei connettivi in base a causa, contrasto, tempo, condizione e scopo.";
    return "Allena lettura selettiva: separare dati utili, prove, opinioni e dettagli decorativi.";
  }

  private languageMinigameMethod(type: LanguageMinigameType): string {
    if (type === "agreement-sprint") return "Trova il soggetto, controlla singolare/plurale e verifica che verbo e aggettivo concordino.";
    if (type === "connector-route") return "Nomina il rapporto tra le due frasi: causa, conseguenza, contrasto, tempo, condizione o scopo.";
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
