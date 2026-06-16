import { englishTemplates, type EnglishTemplate } from "../../data/procedural/englishTemplates";
import type { GeneratedEnglishPuzzle } from "../ProceduralTypes";
import type { Random } from "../Random";

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

  fallback(): GeneratedEnglishPuzzle {
    const template = englishTemplates[0];
    return {
      ...this.buildPuzzle(template, [
        { id: "green", label: template.correctLabel, isCorrect: true, feedback: template.correctFeedback ?? "Sequenza operativa corretta." },
        ...template.distractors.map((distractor, index) => ({
          id: `fallback-${index}`,
          label: distractor.label,
          isCorrect: false,
          feedback: distractor.feedback,
        })),
      ], 1),
      id: "english-fallback",
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
    if (["where-is-core"].includes(templateId)) return ["prepositions", "spatial reading", "technical nouns"];
    if (["who-can-open"].includes(templateId)) return ["question words", "can", "permission"];
    if (["main-switch", "left-before-blue", "measure-before-switch", "after-robot-dock"].includes(templateId)) return ["sequence", "before/after", "procedure"];
    if (["simple-vs-now"].includes(templateId)) return ["present simple", "present continuous", "now"];
    if (["past-log-today"].includes(templateId)) return ["past simple", "present state", "time markers"];
    if (["some-any-fuses"].includes(templateId)) return ["some/no", "quantity", "prohibition"];
    if (["frequency-adverbs"].includes(templateId)) return ["frequency adverbs", "when", "cause/effect"];
    if (["going-to-scan"].includes(templateId)) return ["future plan", "going to", "after"];
    if (["pronoun-reference"].includes(templateId)) return ["pronouns", "it/them", "singular/plural"];
    if (["only-if-stable", "below-threshold"].includes(templateId)) return ["if/otherwise", "condition", "threshold"];
    if (["unless-blue-blinks", "until-door-unlocks"].includes(templateId)) return ["unless/until", "exception", "waiting"];
    if (["compare-two-signals", "which-route-safest"].includes(templateId)) return ["comparison", "adjectives", "sequence"];
    if (["relative-drawer"].includes(templateId)) return ["relative clause", "that", "technical nouns"];
    if (["may-must-not", "passive-reattach-wire"].includes(templateId)) return ["modal verbs", "passive", "safety"];
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
    if (text.includes("yesterday")) glossary.push({ term: "yesterday", meaning: "ieri" });
    if (text.includes("offline")) glossary.push({ term: "offline", meaning: "non attivo" });
    if (text.includes("some")) glossary.push({ term: "some", meaning: "alcuni / un po'" });
    if (text.includes("no spare")) glossary.push({ term: "no spare", meaning: "nessun ricambio" });
    if (text.includes("going to")) glossary.push({ term: "going to", meaning: "ha in programma di" });
    if (text.includes("them")) glossary.push({ term: "them", meaning: "li / loro" });
    return glossary.slice(0, 5);
  }

  private competenciesFor(templateId: string): string[] {
    const base = ["inglese.istruzioni", "pensieroCritico"];
    if (["sensor-below-threshold", "compare-two-signals", "between-limits", "which-route-safest"].includes(templateId)) return [...base, "inglese.scientifico", "inglese.dati"];
    if (["where-is-core", "replace-only-damaged", "relative-drawer", "some-any-fuses"].includes(templateId)) return [...base, "inglese.lessico"];
    if (["who-can-open", "simple-vs-now", "past-log-today", "frequency-adverbs", "going-to-scan", "pronoun-reference", "may-must-not", "passive-reattach-wire", "must-should-cable"].includes(templateId)) return [...base, "inglese.grammatica", "inglese.comprensione"];
    if (["unless-blue-blinks", "until-door-unlocks", "only-if-stable", "not-until-pressure-drops"].includes(templateId)) return [...base, "inglese.bilingue", "inglese.grammatica"];
    if (["cause-report", "procedure-debug-charge"].includes(templateId)) return [...base, "inglese.bilingue", "inglese.comprensione"];
    return base;
  }

  private levelName(level: number): string {
    if (level <= 2) return "comandi e divieti";
    if (level <= 4) return "ordine e sequenze";
    if (level <= 6) return "condizioni operative";
    return "eccezioni e vincoli";
  }
}
