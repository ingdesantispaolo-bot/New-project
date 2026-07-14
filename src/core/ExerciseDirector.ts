import { MathPuzzleGenerator } from "../procedural/generators/MathPuzzleGenerator";
import { RobotGridGenerator } from "../procedural/generators/RobotGridGenerator";
import { CircuitFaultGenerator } from "../procedural/generators/CircuitFaultGenerator";
import type {
  DifficultyLevel,
  ExercisePedagogy,
  GeneratedCircuitPuzzle,
  GeneratedMathPuzzle,
  GeneratedRobotPuzzle,
} from "../procedural/ProceduralTypes";
import { Random } from "../procedural/Random";
import { difficultyModel } from "../procedural/DifficultyModel";
import { hintLadder } from "./HintLadder";
import { explanationBuilder } from "./ExplanationBuilder";
import { mistakeAnalyzer } from "./MistakeAnalyzer";

export type DirectedExerciseSet = {
  math: GeneratedMathPuzzle;
  robot: GeneratedRobotPuzzle;
  circuit: GeneratedCircuitPuzzle;
};

export class ExerciseDirector {
  private mathGenerator = new MathPuzzleGenerator();
  private robotGenerator = new RobotGridGenerator();
  private circuitGenerator = new CircuitFaultGenerator();

  generateSet(seed: string, difficulty: DifficultyLevel | number): DirectedExerciseSet {
    const preset = difficultyModel.getPreset(difficulty);
    const random = new Random(`${seed}:exercise-director:${preset.level}`);
    return {
      math: this.enrichMath(this.mathGenerator.generate(random.fork("math"), preset), preset.level),
      robot: this.enrichRobot(this.robotGenerator.generate(random.fork("robot"), preset), preset.level),
      circuit: this.enrichCircuit(this.circuitGenerator.generate(random.fork("circuit"), preset), preset.level),
    };
  }

  enrichMath(puzzle: GeneratedMathPuzzle, level: DifficultyLevel): GeneratedMathPuzzle {
    const steps = this.completeMathSteps(
      puzzle.solutionSteps ?? this.inferMathSteps(puzzle.prompt, puzzle.answer),
      puzzle,
      level,
    );
    const profile = this.mathProfile(puzzle, level, steps);
    return {
      ...puzzle,
      solutionSteps: steps,
      difficultyLevel: level,
      difficultyLabel: profile.difficultyLabel,
      learningPurpose: profile.learningPurpose,
      calculationAid: profile.calculationAid,
      pedagogy: this.basePedagogy(
        level,
        profile.learningPurpose,
        profile.difficultyReason,
        puzzle.hints,
        explanationBuilder.math(
          profile.operationSummary,
          `Passaggi controllati: ${steps.join(" -> ")}. Risultato finale: ${puzzle.answer}.`,
          profile.theoryPrinciple,
        ),
      ),
    };
  }

  enrichRobot(puzzle: GeneratedRobotPuzzle, level: DifficultyLevel): GeneratedRobotPuzzle {
    const concepts = this.robotConcepts(puzzle);
    return {
      ...puzzle,
      maxCommands: puzzle.maxCommands ?? Math.max(puzzle.solutionCommands.length + (level <= 2 ? 4 : 2), puzzle.solutionCommands.length),
      requiredConcepts: concepts,
      pedagogy: this.basePedagogy(
        level,
        this.robotLearningGoal(puzzle),
        "La profondità cresce con dimensione griglia, ostacoli, checkpoint, budget e numero di stati da ricordare.",
        puzzle.hints,
        explanationBuilder.robot(concepts, puzzle.solutionCommands.length),
      ),
    };
  }

  enrichCircuit(puzzle: GeneratedCircuitPuzzle, level: DifficultyLevel): GeneratedCircuitPuzzle {
    const faultSummary = puzzle.requiredRepairs.map((fault) => this.circuitFaultExplanation(fault)).join(" ");
    return {
      ...puzzle,
      testerReadings: puzzle.testerReadings ?? this.testerReadings(puzzle),
      explanationByFault: {
        ...Object.fromEntries(puzzle.requiredRepairs.map((fault) => [fault, this.circuitFaultExplanation(fault)])),
        ...(puzzle.explanationByFault ?? {}),
      },
      pedagogy: this.basePedagogy(
        level,
        puzzle.learningPurpose ?? "Diagnosticare un circuito separando percorso chiuso, verso del LED, protezione e comportamento dei componenti.",
        level <= 2
          ? "La profondità resta bassa: prima riconosci i pezzi e segui il giro della corrente."
          : level <= 5
            ? "La profondità cresce unendo pezzi gia visti: resistenza, LED, tester e primi rami."
            : "La profondità cresce con piu guasti, letture del tester e componenti combinati.",
        puzzle.hints,
        explanationBuilder.circuit(faultSummary),
        mistakeAnalyzer.circuitMistakes(),
      ),
    };
  }

  private basePedagogy(
    level: DifficultyLevel,
    learningGoal: string,
    difficultyReason: string,
    hints: string[],
    explanation: ExercisePedagogy["explanation"],
    commonMistakes: ExercisePedagogy["commonMistakes"] = [],
  ): ExercisePedagogy {
    return {
      phase: level <= 2 ? "osserva" : level <= 5 ? "formula-ipotesi" : "verifica-correggi",
      learningGoal,
      difficultyReason,
      hintLadder: hintLadder.fromTexts(hints, explanation.principle),
      commonMistakes,
      explanation,
    };
  }

  private inferMathSteps(prompt: string, answer: number): string[] {
    return [prompt.replace(/\s+/g, " ").trim(), `risultato ${answer}`];
  }

  private completeMathSteps(steps: string[], puzzle: GeneratedMathPuzzle, level: DifficultyLevel): string[] {
    const targetCount = Math.min(3, Math.max(2, difficultyModel.getPreset(level).mathComplexity));
    const completed = [...steps].filter((step) => step.trim().length > 0);
    const candidates = [
      ...(puzzle.hints ?? []),
      `Controlla che la risposta sia un numero intero: ${puzzle.answer}.`,
    ];
    for (const candidate of candidates) {
      if (completed.length >= targetCount) break;
      const normalized = candidate.replace(/\.$/, "").trim();
      if (normalized.length > 0 && !completed.includes(normalized)) {
        completed.push(normalized);
      }
    }
    while (completed.length < targetCount) {
      completed.push(`Verifica il passaggio ${completed.length + 1} prima di confermare il risultato.`);
    }
    return completed;
  }

  private mathProfile(puzzle: GeneratedMathPuzzle, level: DifficultyLevel, steps: string[]) {
    const archetype = puzzle.archetype ?? "calcolo-diretto";
    const concept = this.mathConcept(archetype);
    const difficultyLabel = this.mathDifficultyLabel(level);
    const multiStepReason = steps.length >= 4
      ? "richiede piu passaggi ordinati e controllo finale"
      : steps.length >= 3
        ? "richiede almeno tre passaggi distinti"
        : "richiede pochi passaggi, ma l'ordine e importante";

    return {
      difficultyLabel,
      learningPurpose: concept.learningPurpose,
      difficultyReason: `Profondità ${level}/8: ${difficultyModel.describe(level)}; ${multiStepReason}.`,
      theoryPrinciple: concept.theoryPrinciple,
      operationSummary: `${concept.shortName}: ${steps.slice(0, 3).join(" -> ")}`,
      calculationAid: {
        mentalMathNote: "Puoi calcolare a mente se vuoi, ma non e richiesto. La sfida valuta strategia, ordine dei passaggi e controllo dell'errore.",
        strategy: concept.strategy,
        scratchpadPrompt: steps.length >= 3
          ? "Usa un taccuino: una riga per ogni passaggio, poi inserisci solo il risultato finale."
          : "Scrivi dati, operazione e risultato: evita di tenere tutto in memoria.",
      },
    };
  }

  private mathDifficultyLabel(level: DifficultyLevel): string {
    if (level <= 2) return `Profondità ${level}/8 - Fondamenta guidate`;
    if (level <= 4) return `Profondità ${level}/8 - Strategie intermedie`;
    if (level <= 6) return `Profondità ${level}/8 - Ragionamento multi-passaggio`;
    return `Profondità ${level}/8 - Ponte verso le superiori`;
  }

  private mathConcept(archetype: NonNullable<GeneratedMathPuzzle["archetype"]>) {
    const concepts: Record<NonNullable<GeneratedMathPuzzle["archetype"]>, { shortName: string; learningPurpose: string; theoryPrinciple: string; strategy: string }> = {
      "calcolo-diretto": {
        shortName: "calcolo ordinato",
        learningPurpose: "Calibrare calcolo mentale scritto, ordine delle operazioni e controllo del risultato.",
        theoryPrinciple: "Quando una macchina applica piu operazioni, il valore cambia passo dopo passo: cambiare l'ordine cambia quasi sempre il risultato.",
        strategy: "Spezza la catena: calcola il primo blocco, scrivi il risultato intermedio, poi passa al blocco successivo.",
      },
      "ragionamento-inverso": {
        shortName: "operazioni inverse",
        learningPurpose: "Capire come tornare dal risultato all'ingresso usando operazioni inverse.",
        theoryPrinciple: "Per annullare una trasformazione si usa l'operazione inversa: somma e sottrazione si annullano, moltiplicazione e divisione si annullano.",
        strategy: "Parti dall'uscita e risali la macchina al contrario, una trasformazione per volta.",
      },
      sequenza: {
        shortName: "sequenze",
        learningPurpose: "Riconoscere pattern numerici e prevedere il termine successivo senza andare per tentativi.",
        theoryPrinciple: "Una sequenza ha una regola: puo crescere con salti costanti, salti che cambiano o moltiplicazioni ripetute.",
        strategy: "Calcola le differenze tra termini consecutivi e cerca come cambiano i salti.",
      },
      vincolo: {
        shortName: "vincoli",
        learningPurpose: "Scegliere un numero che rispetta piu condizioni contemporaneamente.",
        theoryPrinciple: "Un vincolo elimina possibilita: piu vincoli insieme riducono lo spazio di ricerca e obbligano a ragionare.",
        strategy: "Applica prima il vincolo che scarta piu numeri, poi controlla gli altri uno alla volta.",
      },
      "diagnosi-errore": {
        shortName: "controllo errore",
        learningPurpose: "Individuare un errore di procedura e correggerlo con un calcolo verificabile.",
        theoryPrinciple: "Un risultato non basta: devi controllare se rispetta la procedura e l'ordine delle operazioni.",
        strategy: "Rifai il protocollo lentamente e confronta ogni passaggio con il log sospetto.",
      },
      "lettura-dati": {
        shortName: "dati",
        learningPurpose: "Leggere dati numerici e trasformarli in un'informazione utile.",
        theoryPrinciple: "I dati grezzi non sono ancora una conclusione: vanno ordinati, confrontati o sintetizzati.",
        strategy: "Sottolinea quali dati servono davvero e quale trasformazione richiede il terminale.",
      },
      proporzione: {
        shortName: "proporzioni",
        learningPurpose: "Usare rapporti e fattori di scala in situazioni concrete.",
        theoryPrinciple: "In una proporzione il rapporto resta lo stesso anche quando le quantita cambiano scala.",
        strategy: "Trova il fattore di scala, poi applicalo a tutte le parti coinvolte.",
      },
      "pre-algebra": {
        shortName: "pre-algebra",
        learningPurpose: "Tradurre una procedura in una espressione e rispettare parentesi e priorita.",
        theoryPrinciple: "Le parentesi indicano un blocco da risolvere prima; moltiplicazioni e divisioni precedono somme e sottrazioni.",
        strategy: "Risolvi prima i blocchi interni, poi moltiplicazioni/divisioni, infine somme/sottrazioni.",
      },
      "equazione-primo-grado": {
        shortName: "equazioni",
        learningPurpose: "Risolvere equazioni di primo grado mantenendo l'equilibrio tra i due lati.",
        theoryPrinciple: "Un'equazione resta equivalente se applichi la stessa operazione a entrambi i lati: l'obiettivo e isolare x.",
        strategy: "Togli prima addizioni o sottrazioni, poi annulla moltiplicazioni o divisioni. Se ci sono parentesi, semplifica quel blocco prima di isolare x.",
      },
      "equazione-secondo-grado": {
        shortName: "equazioni quadratiche",
        learningPurpose: "Collegare coefficienti, discriminante, radici e grafico di una parabola.",
        theoryPrinciple: "Nella forma ax² + bx + c = 0, il discriminante Δ = b² - 4ac determina quante soluzioni reali esistono; le radici sono le intersezioni con l'asse x.",
        strategy: "Identifica a, b e c con i rispettivi segni; calcola Δ; prevedi il numero di soluzioni; applica fattorizzazione o formula e verifica sul grafico.",
      },
      "grafici-cartesiani": {
        shortName: "grafici interattivi",
        learningPurpose: "Comprendere come i parametri trasformano rette e parabole intervenendo direttamente sul grafico.",
        theoryPrinciple: "I parametri non sono numeri decorativi: pendenza e intercetta muovono una retta; apertura, asse e vertice trasformano una parabola.",
        strategy: "Modifica un parametro alla volta, osserva cosa resta invariato e usa punti notevoli, vertice e intersezioni per verificare il risultato.",
      },
      frazioni: {
        shortName: "frazioni",
        learningPurpose: "Capire le frazioni come parti dello stesso intero e non come comandi isolati.",
        theoryPrinciple: "Una frazione indica una quota di un totale: prima identifica l'intero, poi calcola la parte richiesta.",
        strategy: "Scrivi qual e il totale, calcola ogni quota sul totale iniziale, poi combina le quote.",
      },
      percentuali: {
        shortName: "percentuali",
        learningPurpose: "Usare percentuali come frazioni su 100 in aumenti, perdite e confronti.",
        theoryPrinciple: "Una percentuale e una quota su 100: il 25% significa 25 parti ogni 100, cioe un quarto.",
        strategy: "Calcola prima la quota percentuale, poi decidi se aggiungerla o sottrarla.",
      },
      geometria: {
        shortName: "geometria",
        learningPurpose: "Collegare misure, formule e significato geometrico della situazione.",
        theoryPrinciple: "Area, perimetro e distanza misurano proprieta diverse: non sono intercambiabili.",
        strategy: "Disegna una mini figura, assegna le misure e scegli la formula prima di calcolare.",
      },
      statistica: {
        shortName: "statistica",
        learningPurpose: "Sintetizzare una serie di dati con misure come mediana, media e intervallo.",
        theoryPrinciple: "La statistica cerca una lettura stabile dei dati: non sempre il valore piu alto o piu visibile e quello utile.",
        strategy: "Ordina i dati, trova la misura richiesta, poi applica l'eventuale passaggio finale.",
      },
      probabilita: {
        shortName: "probabilita",
        learningPurpose: "Stimare eventi usando rapporti e frequenze attese.",
        theoryPrinciple: "La probabilita descrive quanto e plausibile un evento: se il rapporto resta uguale, puoi prevedere una frequenza attesa.",
        strategy: "Semplifica il rapporto, poi applicalo al nuovo totale.",
      },
      "potenze-radici": {
        shortName: "potenze e radici",
        learningPurpose: "Usare potenze, radici e ordine di grandezza per leggere segnali compatti.",
        theoryPrinciple: "Una potenza ripete una moltiplicazione; una radice quadrata cerca il lato che moltiplicato per se stesso produce l'area.",
        strategy: "Riconosci prima il tipo di potenza o radice, poi usa un valore intermedio scritto.",
      },
      "funzione-lineare": {
        shortName: "funzioni",
        learningPurpose: "Capire una funzione come macchina ingresso-uscita.",
        theoryPrinciple: "Una funzione assegna a ogni ingresso una uscita seguendo sempre la stessa regola.",
        strategy: "Sostituisci x con il valore dato, calcola la moltiplicazione, poi aggiungi il termine finale.",
      },
      "sistemi-lineari": {
        shortName: "sistemi",
        learningPurpose: "Ragionare su due incognite collegate da piu informazioni.",
        theoryPrinciple: "Un sistema usa piu relazioni per trovare valori sconosciuti: una sola informazione spesso non basta.",
        strategy: "Trasforma somma e differenza in due quantita uguali, poi ricostruisci i valori.",
      },
      coordinate: {
        shortName: "coordinate",
        learningPurpose: "Usare il piano cartesiano o una griglia per calcolare spostamenti.",
        theoryPrinciple: "Le coordinate descrivono posizione; uno spostamento senza diagonali si calcola separando asse orizzontale e verticale.",
        strategy: "Calcola prima lo spostamento in x, poi quello in y, infine somma i due percorsi.",
      },
    };
    return concepts[archetype];
  }

  private robotConcepts(puzzle: GeneratedRobotPuzzle): string[] {
    const commands = puzzle.solutionCommands;
    const concepts = new Set<string>(["direzione iniziale", "sequenza"]);
    if (commands.includes("PICK_UP")) concepts.add("azione contestuale");
    if (commands.includes("EXIT")) concepts.add("obiettivo finale");
    if (commands.filter((command) => command === "TURN_LEFT" || command === "TURN_RIGHT").length >= 2) concepts.add("rotazioni multiple");
    if ((puzzle.checkpoints?.length ?? 0) > 0) concepts.add("checkpoint ordinati");
    if (puzzle.challengeType === "minimal-route") concepts.add("ottimizzazione");
    if (puzzle.challengeType === "debug-program") concepts.add("debug del programma");
    if (puzzle.challengeType === "pattern-routing") concepts.add("pattern spaziale");
    if (puzzle.challengeType === "coordinate-routing") concepts.add("coordinate su griglia");
    if (puzzle.challengeType === "conditional-gate") concepts.add("logica condizionale");
    if (puzzle.challengeType === "loop-compression") concepts.add("pattern ripetuto");
    return [...concepts];
  }

  private robotLearningGoal(puzzle: GeneratedRobotPuzzle): string {
    return {
      "route-planning": "Pianificare una sequenza tenendo conto di direzione, ostacoli, raccolta e uscita.",
      "minimal-route": "Costruire un algoritmo corretto ma essenziale, riducendo comandi inutili.",
      "checkpoint-order": "Scomporre una rotta in sotto-obiettivi ordinati e verificabili.",
      "debug-program": "Analizzare un programma quasi corretto, individuare l'errore e riscrivere la sequenza.",
      "pattern-routing": "Riconoscere pattern spaziali e trasformarli in sequenze di comandi controllate.",
      "coordinate-routing": "Tradurre posizioni su griglia e direzione iniziale in una sequenza di comandi.",
      "conditional-gate": "Usare una logica se-allora: attivare condizioni prima dell'azione finale.",
      "loop-compression": "Riconoscere blocchi ripetuti e usarli per progettare sequenze piu efficienti.",
    }[puzzle.challengeType ?? "route-planning"];
  }

  private testerReadings(puzzle: GeneratedCircuitPuzzle): GeneratedCircuitPuzzle["testerReadings"] {
    return puzzle.requiredRepairs.map((fault) => {
      if (fault === "open-switch") return { from: "batteria", to: "interruttore", reading: "interrotto", note: "La leva aperta interrompe il percorso." };
      if (fault === "missing-wire") return { from: "LED", to: "ritorno", reading: "interrotto", note: "Manca il tratto che chiude il giro." };
      if (fault === "reversed-led") return { from: "resistenza", to: "LED", reading: "polarita-inversa", note: "La corrente arriva, ma il LED e orientato al contrario." };
      if (fault === "missing-resistor") return { from: "interruttore", to: "LED", reading: "non-stabile", note: "Il percorso c'e, ma non e protetto." };
      if (fault === "sensor-unpowered") return { from: "sensore", to: "alimentazione", reading: "interrotto", note: "Il circuito principale puo funzionare, ma il sensore non riceve energia." };
      if (fault === "capacitor-discharged") return { from: "condensatore", to: "LED", reading: "non-stabile", note: "Il condensatore non accumula carica: l'impulso resta troppo breve." };
      if (fault === "short-circuit") return { from: "batteria +", to: "ritorno", reading: "corto", note: "La corrente trova una scorciatoia e non attraversa il carico." };
      if (fault === "parallel-branch-open") return { from: "ramo B", to: "ritorno", reading: "interrotto", note: "Il ramo principale funziona, ma il ramo parallelo resta aperto." };
      if (fault === "wrong-resistor-value") return { from: "resistenza", to: "LED", reading: "non-stabile", note: "Il valore non limita la corrente nel modo richiesto." };
      if (fault === "relay-not-armed") return { from: "bobina relè", to: "ritorno", reading: "tensione-bassa", note: "Il relè non chiude il contatto di potenza." };
      if (fault === "loose-ground") return { from: "ritorno", to: "massa", reading: "non-stabile", note: "Il riferimento di ritorno non e stabile." };
      return { from: "componente", to: "linea principale", reading: "interrotto", note: "Il componente non e dentro il percorso utile." };
    });
  }

  private circuitFaultExplanation(fault: GeneratedCircuitPuzzle["requiredRepairs"][number]): string {
    return {
      "missing-wire": "Un filo mancante lascia il circuito aperto: la corrente non ritorna alla batteria.",
      "open-switch": "Un interruttore aperto e come un ponte sollevato: il percorso si interrompe.",
      "reversed-led": "Un LED invertito riceve corrente dal verso sbagliato e non emette luce.",
      "missing-resistor": "Senza resistenza il LED non e protetto: il sistema vede corrente instabile.",
      "disconnected-component": "Un componente scollegato puo essere presente ma non partecipa al circuito.",
      "sensor-unpowered": "Un sensore non alimentato non puo misurare ne inviare dati affidabili al terminale.",
      "capacitor-discharged": "Un condensatore scarico non stabilizza gli impulsi: la luce puo apparire solo per un istante.",
      "short-circuit": "Un corto circuito offre una scorciatoia pericolosa: la corrente evita il carico.",
      "parallel-branch-open": "Un ramo parallelo aperto puo lasciare acceso un ramo e spento l'altro.",
      "wrong-resistor-value": "Una resistenza con valore errato rende la corrente troppo debole o troppo forte.",
      "relay-not-armed": "Un rele non armato non trasferisce il comando al circuito di potenza.",
      "loose-ground": "Una massa instabile rende il ritorno intermittente e le letture poco affidabili.",
    }[fault];
  }
}

export const exerciseDirector = new ExerciseDirector();
