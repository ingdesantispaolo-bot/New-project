import { circuitBaseEdges, circuitComponentGuide, circuitFaultTemplates, circuitNodes, optionalCircuitNodes } from "../../data/procedural/circuitTemplates";
import type { CircuitComponentChallenge, CircuitFaultType, CircuitMinigameType, DifficultyPreset, GeneratedCircuitPuzzle } from "../ProceduralTypes";
import type { Random } from "../Random";
import { buildCircuitMinigame, circuitMinigameTypeForLevel } from "./CircuitMinigameGenerator";

const faultObservations: Record<CircuitFaultType, string> = {
  "missing-wire": "Il tester non legge continuità tra LED e ritorno: il percorso si interrompe dopo il LED.",
  "open-switch": "La leva dell'interruttore è sollevata: prima della resistenza la corrente si ferma.",
  "reversed-led": "Il LED resta spento anche se arriva corrente: la polarità potrebbe essere invertita.",
  "missing-resistor": "Il LED lampeggia in modo instabile: manca un componente che limiti la corrente.",
  "disconnected-component": "Il sensore rileva un componente presente ma fuori dal percorso principale.",
  "sensor-unpowered": "Il sensore non manda dati al terminale: i suoi morsetti non ricevono alimentazione.",
  "capacitor-discharged": "Il LED fa solo un lampo debole: il condensatore non accumula carica sufficiente.",
  "short-circuit": "Il tester segnala continuità quasi diretta tra + e ritorno: la corrente può saltare il carico.",
  "parallel-branch-open": "Il LED principale si accende, ma il ramo secondario resta spento: il guasto è locale, non generale.",
  "wrong-resistor-value": "Il LED si accende troppo debole o troppo forte: il circuito funziona, ma la protezione non è adeguata.",
  "relay-not-armed": "Il comando arriva al relè, ma il contatto di potenza resta aperto: il carico non parte.",
  "loose-ground": "La misura sul ritorno cambia quando il pannello vibra: il collegamento a massa non è stabile.",
};

const explanationByFault: Record<CircuitFaultType, string> = {
  "missing-wire": "Un filo mancante interrompe il giro: anche con batteria e LED corretti non circola corrente.",
  "open-switch": "Un interruttore aperto è una pausa volontaria nel percorso: chiuderlo rende continuo il ramo.",
  "reversed-led": "Il LED è un diodo: nel verso sbagliato blocca la corrente e resta spento.",
  "missing-resistor": "La resistenza protegge il LED limitando la corrente. Senza protezione il circuito non è sicuro.",
  "disconnected-component": "Un componente fuori percorso non partecipa al circuito: va ricollegato al nodo corretto.",
  "sensor-unpowered": "Un sensore può leggere dati solo se riceve alimentazione e ha un ritorno affidabile.",
  "capacitor-discharged": "Il condensatore accumula carica: se è scarico non stabilizza un impulso breve.",
  "short-circuit": "Un corto crea una scorciatoia a bassa resistenza: la corrente evita il carico e può danneggiare il circuito.",
  "parallel-branch-open": "Nei rami paralleli una parte può funzionare mentre l'altra è interrotta: bisogna isolare il ramo guasto.",
  "wrong-resistor-value": "Il valore della resistenza cambia quanta corrente passa: non basta che il LED si accenda.",
  "relay-not-armed": "Il relè separa comando e potenza: se la bobina non è alimentata, il contatto del carico resta aperto.",
  "loose-ground": "Un ritorno instabile fa sembrare casuali le misure: il circuito ha bisogno di un riferimento stabile.",
};

export class CircuitFaultGenerator {
  generate(random: Random, difficulty: DifficultyPreset, preferredFaults: CircuitFaultType[] = []): GeneratedCircuitPuzzle {
    const eligibleFaults = circuitFaultTemplates.filter((fault) => (fault.minComplexity ?? 1) <= difficulty.circuitComplexity);
    const faultCount = Math.min(1 + Math.floor(difficulty.circuitComplexity / 3), 3, eligibleFaults.length);
    const preferredPool = preferredFaults.length > 0 ? eligibleFaults.filter((fault) => preferredFaults.includes(fault.type)) : [];
    const firstFault = preferredPool.length > 0 ? [random.pick(preferredPool)] : [];
    const remainingPool = random.shuffle(eligibleFaults.filter((fault) => !firstFault.some((selected) => selected.type === fault.type)));
    const faults = [...firstFault, ...remainingPool].slice(0, faultCount);
    const missingWire = faults.some((fault) => fault.type === "missing-wire");
    const edges = missingWire ? circuitBaseEdges.slice(0, -1) : [...circuitBaseEdges];
    const faultTypes = faults.map((fault) => fault.type);
    const scenarioType = this.scenarioType(faultTypes);
    const nodes = this.nodesForFaults(faultTypes);
    const testerReadings = this.testerReadingsForFaults(faultTypes, random);
    const repairChoices = this.repairChoicesForFaults(faultTypes, random, difficulty.circuitComplexity);
    const componentChallenges = this.componentChallengesForFaults(faultTypes, nodes, random, difficulty.level);
    const observations = [
      ...faults.map((fault) => faultObservations[fault.type]),
      ...this.noiseObservations(random, difficulty.noiseDataCount),
    ];
    return {
      id: "circuit-fault",
      title: this.titleForScenario(scenarioType),
      symptom: this.describeSymptom(faultTypes),
      observations: random.shuffle(observations),
      nodes,
      edges,
      faults: faultTypes,
      requiredRepairs: faultTypes,
      hints: [
        "Segui prima il giro completo: batteria, interruttore, protezione, LED, ritorno.",
        "Distingui tre domande: il percorso è chiuso? il componente ha il verso giusto? la corrente è protetta?",
        ...faults.map((fault) => fault.hint),
      ],
      scenarioType,
      diagnosticQuestion: this.questionForScenario(scenarioType),
      testerReadings,
      explanationByFault: Object.fromEntries(faultTypes.map((fault) => [fault, explanationByFault[fault]])),
      componentGuide: circuitComponentGuide.filter((component) => nodes.includes(component.id)),
      circuitGoal: this.goalForScenario(scenarioType),
      repairChoices,
      diagnosticPlan: this.diagnosticPlanForScenario(scenarioType),
      difficultyLabel: `Livello ${difficulty.level} - ${this.levelName(difficulty.level)}`,
      learningPurpose: this.learningPurposeForScenario(scenarioType),
      conceptTags: this.conceptsForFaults(faultTypes),
      componentChallenges,
      competencies: ["elettronica.circuitoChiuso", "problemSolving", "pensieroCritico"],
    };
  }

  /**
   * A real, valid fault-diagnosis circuit with a quick electronics minigame
   * attached. The base puzzle stays valid (so it passes the strict circuit
   * validator); the scene branches to the minigame when present.
   */
  generateMinigame(random: Random, difficulty: DifficultyPreset, preferredTypes: CircuitMinigameType[] = []): GeneratedCircuitPuzzle {
    const base = this.generate(random, difficulty);
    const type = preferredTypes.length > 0
      ? random.pick(preferredTypes)
      : circuitMinigameTypeForLevel(random, difficulty.level);
    const minigame = buildCircuitMinigame(random.fork(`circuit-mini-${type}`), difficulty, type);
    return {
      ...base,
      id: `circuit-mini-${type}`,
      title: minigame.title,
      competencies: Array.from(new Set([...base.competencies, ...minigame.competencies])),
      minigame,
    };
  }

  fallback(level = 1, random?: Random, difficulty?: DifficultyPreset): GeneratedCircuitPuzzle {
    if (random && difficulty) {
      const safeFaults = circuitFaultTemplates.filter((fault) => (fault.minComplexity ?? 1) <= 1).map((fault) => fault.type);
      return this.generate(random.fork("safe-circuit"), {
        ...difficulty,
        circuitComplexity: 1,
        noiseDataCount: 0,
      }, [random.pick(safeFaults)]);
    }
    const fallbackNodes = [...circuitNodes];
    return {
      id: "circuit-fallback",
      title: "Circuito con interruttore aperto",
      symptom: "Il LED resta spento e il tester segnala percorso interrotto prima della resistenza.",
      observations: [faultObservations["open-switch"]],
      nodes: fallbackNodes,
      edges: [...circuitBaseEdges],
      faults: ["open-switch"],
      requiredRepairs: ["open-switch"],
      hints: ["L'interruttore interrompe il percorso: chiuderlo completa il giro."],
      scenarioType: "percorso-aperto",
      diagnosticQuestion: "Dove si interrompe il giro della corrente?",
      testerReadings: [
        { from: "Batteria +", to: "Interruttore", reading: "continuita", note: "La corrente arriva al primo contatto." },
        { from: "Interruttore", to: "Resistenza", reading: "interrotto", note: "La leva aperta interrompe il percorso." },
      ],
      explanationByFault: { "open-switch": explanationByFault["open-switch"] },
      componentGuide: circuitComponentGuide.filter((component) => circuitNodes.includes(component.id as typeof circuitNodes[number])),
      circuitGoal: this.goalForScenario("percorso-aperto"),
      repairChoices: ["open-switch", "missing-wire", "missing-resistor"],
      diagnosticPlan: this.diagnosticPlanForScenario("percorso-aperto"),
      difficultyLabel: "Livello 1 - percorso chiuso",
      learningPurpose: this.learningPurposeForScenario("percorso-aperto"),
      conceptTags: ["circuito chiuso", "interruttore", "continuità"],
      componentChallenges: level > 3 ? [this.fallbackComponentChallenge("switch")] : [],
      competencies: ["elettronica.circuitoChiuso", "problemSolving"],
    };
  }

  private fallbackComponentChallenge(componentId: string): CircuitComponentChallenge {
    const component = circuitComponentGuide.find((item) => item.id === componentId) ?? circuitComponentGuide[0];
    const distractors = circuitComponentGuide.filter((item) => item.id !== component.id).slice(0, 2);
    const correctSymbol = component.symbolName ?? component.label;
    const correctFunction = component.functionSummary ?? component.role;
    return {
      componentId: component.id,
      componentLabel: component.label,
      symbolQuestion: "Quale simbolo è evidenziato nello schema?",
      functionQuestion: "Quale funzione svolge nel circuito?",
      correctSymbol,
      correctFunction,
      symbolChoices: [correctSymbol, ...distractors.map((item) => item.symbolName ?? item.label)],
      functionChoices: [correctFunction, ...distractors.map((item) => item.functionSummary ?? item.role)],
      explanation: `${component.label}: ${component.role}. Indizio visivo: ${component.symbolClue ?? component.check}. Attenzione: ${component.commonConfusion ?? component.check}.`,
    };
  }

  private scenarioType(faults: CircuitFaultType[]): GeneratedCircuitPuzzle["scenarioType"] {
    if (faults.length > 1) return "multi-guasto";
    if (faults.includes("short-circuit")) return "corto-circuito";
    if (faults.includes("parallel-branch-open")) return "serie-parallelo";
    if (faults.includes("relay-not-armed")) return "logica-rele";
    if (faults.includes("missing-resistor")) return "corrente-instabile";
    if (faults.includes("wrong-resistor-value")) return "corrente-instabile";
    if (faults.includes("reversed-led")) return "polarita";
    if (faults.includes("sensor-unpowered")) return "sensore-soglia";
    if (faults.includes("capacitor-discharged")) return "temporizzazione";
    if (faults.includes("loose-ground")) return "corrente-instabile";
    return "percorso-aperto";
  }

  private titleForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "Diagnosi: percorso interrotto",
      "corrente-instabile": "Diagnosi: corrente non protetta",
      polarita: "Diagnosi: LED in polarità sospetta",
      "multi-guasto": "Diagnosi: guasto combinato",
      "serie-parallelo": "Diagnosi: ramo parallelo",
      "sensore-soglia": "Diagnosi: sensore non operativo",
      "logica-rele": "Diagnosi: relè di comando",
      temporizzazione: "Diagnosi: impulso non stabilizzato",
      "corto-circuito": "Diagnosi: corto circuito",
    }[scenario ?? "percorso-aperto"];
  }

  private questionForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "Quale punto impedisce alla corrente di completare il giro?",
      "corrente-instabile": "Il percorso esiste, ma perché il LED non è certificabile?",
      polarita: "Se la corrente arriva al LED, quale proprietà del componente va controllata?",
      "multi-guasto": "Quali cause sono reali e quali interventi sarebbero solo tentativi?",
      "serie-parallelo": "Quale ramo è interrotto, se il circuito principale continua a funzionare?",
      "sensore-soglia": "Perché il terminale non legge il sensore anche se il LED può accendersi?",
      "logica-rele": "Il comando arriva, ma quale parte del relè non permette al carico di partire?",
      temporizzazione: "Perché l'impulso non resta stabile abbastanza a lungo?",
      "corto-circuito": "Dove la corrente trova una scorciatoia che evita il carico?",
    }[scenario ?? "percorso-aperto"];
  }

  private goalForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "Obiettivo: creare un giro chiuso dal + della batteria al LED e ritorno al -. Se un solo tratto è aperto, la corrente non circola.",
      "corrente-instabile": "Obiettivo: non basta accendere il LED. Il circuito deve essere stabile, protetto e leggibile dal terminale.",
      polarita: "Obiettivo: capire che alcuni componenti hanno un verso. Il LED è un diodo luminoso: la polarità conta.",
      "multi-guasto": "Obiettivo: separare le cause reali dai dettagli inutili. Ripara solo ciò che il tester rende necessario.",
      "serie-parallelo": "Obiettivo: capire che due rami possono comportarsi diversamente. Isola il ramo guasto senza cambiare quello sano.",
      "sensore-soglia": "Obiettivo: collegare alimentazione e dato. Un sensore non misura se non riceve energia stabile.",
      "logica-rele": "Obiettivo: distinguere circuito di comando e circuito di potenza. Il relè collega i due mondi.",
      temporizzazione: "Obiettivo: usare il condensatore come piccola riserva di energia per impulsi brevi.",
      "corto-circuito": "Obiettivo: riconoscere una scorciatoia pericolosa: il percorso più facile non è quello corretto.",
    }[scenario ?? "percorso-aperto"];
  }

  private nodesForFaults(faults: CircuitFaultType[]): string[] {
    const nodes = new Set<string>(circuitNodes);
    if (faults.includes("sensor-unpowered") || faults.includes("disconnected-component")) nodes.add(optionalCircuitNodes[0]);
    if (faults.includes("capacitor-discharged")) nodes.add(optionalCircuitNodes[1]);
    if (faults.includes("parallel-branch-open")) nodes.add(optionalCircuitNodes[2]);
    if (faults.includes("relay-not-armed")) nodes.add(optionalCircuitNodes[3]);
    if (faults.includes("relay-not-armed")) nodes.add(optionalCircuitNodes[4]);
    if (faults.includes("loose-ground") || faults.includes("short-circuit")) nodes.add(optionalCircuitNodes[5]);
    return [...nodes];
  }

  private testerReadingsForFaults(faults: CircuitFaultType[], random: Random): GeneratedCircuitPuzzle["testerReadings"] {
    const readings: NonNullable<GeneratedCircuitPuzzle["testerReadings"]> = [
      { from: "Batteria +", to: "Interruttore", reading: "continuita", note: "La sorgente è presente: il problema è più avanti nel percorso." },
    ];
    const byFault: Record<CircuitFaultType, NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]> = {
      "missing-wire": { from: "LED", to: "Ritorno", reading: "interrotto", note: "Dopo il LED il percorso si apre: manca un tratto di filo." },
      "open-switch": { from: "Interruttore", to: "Resistenza", reading: "interrotto", note: "La leva non chiude i due contatti." },
      "reversed-led": { from: "Resistenza", to: "LED", reading: "polarita-inversa", note: "Arriva corrente, ma il verso del LED non è compatibile." },
      "missing-resistor": { from: "Resistenza", to: "LED", reading: "non-stabile", note: "Il LED riceve impulsi non limitati: manca protezione." },
      "disconnected-component": { from: "Sensore", to: "Bus dati", reading: "interrotto", note: "Il componente è fisicamente presente ma fuori nodo." },
      "sensor-unpowered": { from: "Batteria +", to: "Sensore", reading: "tensione-bassa", note: "Il sensore non riceve energia sufficiente per misurare." },
      "capacitor-discharged": { from: "Condensatore", to: "Ritorno", reading: "carica-bassa", note: "La carica non resta abbastanza per stabilizzare l'impulso." },
      "short-circuit": { from: "Batteria +", to: "Ritorno", reading: "corto", note: "C'è una scorciatoia: la corrente evita resistenza e LED." },
      "parallel-branch-open": { from: "Ramo B", to: "Ritorno", reading: "interrotto", note: "Il ramo principale è vivo, ma il secondo ramo non chiude il giro." },
      "wrong-resistor-value": { from: "Resistenza", to: "LED", reading: "non-stabile", note: "Il componente c'è, ma il valore rende la corrente non adatta al LED." },
      "relay-not-armed": { from: "Bobina relè", to: "Ritorno", reading: "tensione-bassa", note: "Il contatto di potenza resta aperto perché la bobina non è armata." },
      "loose-ground": { from: "Ritorno", to: "Massa", reading: "non-stabile", note: "La continuità compare e sparisce: il riferimento non è affidabile." },
    };
    faults.forEach((fault) => readings.push(byFault[fault]));
    const confirmation = [
      { from: "Batteria -", to: "Ritorno", reading: "continuita" as const, note: "Il tester conferma che una parte del ritorno è raggiungibile." },
      { from: "Terminale", to: "Pannello", reading: "continuita" as const, note: "Il pannello comunica: il guasto è nel circuito di carico." },
      { from: "Telaio", to: "Vite del coperchio", reading: "continuita" as const, note: "La vite non spiega il sintomo: è un falso indizio." },
    ];
    return random.shuffle([...readings, ...random.shuffle(confirmation).slice(0, 1 + Math.min(2, faults.length))]);
  }

  private repairChoicesForFaults(faults: CircuitFaultType[], random: Random, complexity: number): CircuitFaultType[] {
    const required = new Set(faults);
    const distractorCount = Math.max(1, Math.min(6 - faults.length, 2 + Math.floor(complexity / 3)));
    const distractors = random
      .shuffle(circuitFaultTemplates.map((fault) => fault.type).filter((fault) => !required.has(fault)))
      .slice(0, distractorCount);
    return random.shuffle([...faults, ...distractors]);
  }

  private componentChallengesForFaults(
    faults: CircuitFaultType[],
    nodes: string[],
    random: Random,
    level: number,
  ): CircuitComponentChallenge[] {
    if (level <= 3) {
      return [];
    }
    const priorityByFault: Record<CircuitFaultType, string[]> = {
      "missing-wire": ["return", "battery"],
      "open-switch": ["switch", "battery"],
      "reversed-led": ["led", "resistor"],
      "missing-resistor": ["resistor", "led"],
      "disconnected-component": ["sensor", "return"],
      "sensor-unpowered": ["sensor", "battery"],
      "capacitor-discharged": ["capacitor", "battery"],
      "short-circuit": ["resistor", "ground", "battery"],
      "parallel-branch-open": ["branchLed", "return"],
      "wrong-resistor-value": ["resistor", "led"],
      "relay-not-armed": ["relay", "motor"],
      "loose-ground": ["ground", "return"],
    };
    const ordered = new Set<string>();
    faults.forEach((fault) => {
      priorityByFault[fault]
        .filter((componentId) => nodes.includes(componentId))
        .forEach((componentId) => ordered.add(componentId));
    });
    nodes
      .filter((componentId) => circuitComponentGuide.some((component) => component.id === componentId))
      .forEach((componentId) => ordered.add(componentId));
    const count = level >= 7 ? 2 : 1;
    return [...ordered]
      .slice(0, count)
      .map((componentId) => this.componentChallenge(componentId, nodes, random));
  }

  private componentChallenge(componentId: string, nodes: string[], random: Random): CircuitComponentChallenge {
    const component = circuitComponentGuide.find((item) => item.id === componentId) ?? circuitComponentGuide[0];
    const visibleComponents = circuitComponentGuide.filter((item) => nodes.includes(item.id) || ["battery", "switch", "resistor", "led", "return"].includes(item.id));
    const symbolDistractors = random
      .shuffle(visibleComponents.filter((item) => item.id !== component.id))
      .slice(0, 2)
      .map((item) => item.symbolName ?? item.label);
    const functionDistractors = random
      .shuffle(visibleComponents.filter((item) => item.id !== component.id))
      .slice(0, 2)
      .map((item) => item.functionSummary ?? item.role);
    const correctSymbol = component.symbolName ?? component.label;
    const correctFunction = component.functionSummary ?? component.role;
    return {
      componentId: component.id,
      componentLabel: component.label,
      symbolQuestion: "Quale simbolo è evidenziato nello schema?",
      functionQuestion: "Quale funzione svolge nel circuito?",
      correctSymbol,
      correctFunction,
      symbolChoices: random.shuffle([correctSymbol, ...symbolDistractors]),
      functionChoices: random.shuffle([correctFunction, ...functionDistractors]),
      explanation: `${component.label}: ${component.role}. Indizio visivo: ${component.symbolClue ?? component.check}. Attenzione: ${component.commonConfusion ?? component.check}.`,
    };
  }

  private diagnosticPlanForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string[] {
    return {
      "percorso-aperto": ["Controlla continuità in ordine.", "Trova il primo tratto interrotto.", "Ripara solo quel tratto."],
      "corrente-instabile": ["Verifica se il LED si accende.", "Controlla protezione e ritorno.", "Stabilizza prima di certificare."],
      polarita: ["Controlla se arriva corrente.", "Leggi il verso del LED.", "Inverti solo se la polarità è la causa."],
      "multi-guasto": ["Separa sintomo principale e secondario.", "Associa ogni misura a una causa.", "Evita riparazioni non dimostrate."],
      "serie-parallelo": ["Confronta ramo A e ramo B.", "Non toccare il ramo funzionante.", "Chiudi solo il ramo aperto."],
      "sensore-soglia": ["Distingui alimentazione e dato.", "Misura tensione al sensore.", "Ricollega il ramo sensore."],
      "logica-rele": ["Controlla circuito di comando.", "Poi controlla contatto di potenza.", "Arma il relè se la bobina non riceve energia."],
      temporizzazione: ["Osserva la durata dell'impulso.", "Misura la carica del condensatore.", "Stabilizza l'impulso."],
      "corto-circuito": ["Cerca percorsi troppo facili.", "Non alimentare finché c'è corto.", "Rimuovi la scorciatoia prima del test."],
    }[scenario ?? "percorso-aperto"];
  }

  private learningPurposeForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "Imparare che la corrente ha bisogno di un percorso completo.",
      "corrente-instabile": "Capire che un circuito deve essere anche protetto e stabile.",
      polarita: "Riconoscere componenti polarizzati e verso della corrente.",
      "multi-guasto": "Allenare diagnosi: collegare misure diverse a cause diverse.",
      "serie-parallelo": "Capire la differenza tra ramo in serie e ramo parallelo.",
      "sensore-soglia": "Distinguere circuito di alimentazione e circuito di misura.",
      "logica-rele": "Vedere un relè come ponte tra comando logico e carico fisico.",
      temporizzazione: "Intuire accumulo e rilascio di energia in un condensatore.",
      "corto-circuito": "Riconoscere perché una scorciatoia elettrica è pericolosa.",
    }[scenario ?? "percorso-aperto"];
  }

  private conceptsForFaults(faults: CircuitFaultType[]): string[] {
    const concepts = new Set(["diagnosi", "tester", "circuito chiuso"]);
    faults.forEach((fault) => {
      if (fault === "reversed-led") concepts.add("polarità");
      if (fault === "missing-resistor" || fault === "wrong-resistor-value") concepts.add("protezione LED");
      if (fault === "sensor-unpowered") concepts.add("sensori");
      if (fault === "capacitor-discharged") concepts.add("condensatore");
      if (fault === "parallel-branch-open") concepts.add("parallelo");
      if (fault === "relay-not-armed") concepts.add("relè");
      if (fault === "short-circuit") concepts.add("corto circuito");
      if (fault === "loose-ground") concepts.add("massa");
    });
    return [...concepts].slice(0, 5);
  }

  private levelName(level: number): string {
    if (level <= 2) return "circuito chiuso";
    if (level <= 4) return "tester e polarità";
    if (level <= 6) return "rami e sensori";
    return "diagnosi di sistema";
  }

  private noiseObservations(random: Random, count: number): string[] {
    const noise = [
      "La cornice del pannello è graffiata, ma il tester non cambia valore vicino al graffio.",
      "La spia laterale lampeggia lentamente: è un segnale di attesa, non un componente del circuito.",
      "Il cavo esterno è vecchio, ma la continuità fino alla batteria resta stabile.",
      "Il terminale registra polvere sul vetro: non influenza il percorso elettrico.",
      "Il colore del filo cambia dopo una giunta, ma il tester misura continuità normale.",
      "La vite del coperchio è allentata: è manutenzione, non causa elettrica del LED spento.",
    ];
    return random.shuffle(noise).slice(0, Math.max(0, count));
  }

  private describeSymptom(faults: CircuitFaultType[]): string {
    if (faults.includes("missing-resistor")) {
      return "Il LED tenta di accendersi ma pulsa in modo irregolare: il circuito non è stabile.";
    }
    if (faults.includes("capacitor-discharged")) {
      return "Il LED emette un lampo breve e poi si spegne: manca energia accumulata per stabilizzare l'impulso.";
    }
    if (faults.includes("short-circuit")) {
      return "Il pannello blocca l'alimentazione: il tester sospetta una scorciatoia tra + e ritorno.";
    }
    if (faults.includes("parallel-branch-open")) {
      return "Una luce resta accesa, ma il ramo secondario non risponde: non tutto il circuito è guasto.";
    }
    if (faults.includes("wrong-resistor-value")) {
      return "Il LED si accende, ma con intensità fuori scala: la protezione non è corretta.";
    }
    if (faults.includes("relay-not-armed")) {
      return "Il comando viene inviato, ma il carico non parte: il relè non chiude il contatto di potenza.";
    }
    if (faults.includes("loose-ground")) {
      return "Il LED sfarfalla quando il pannello vibra: il ritorno a massa sembra instabile.";
    }
    if (faults.includes("sensor-unpowered")) {
      return "Il LED può accendersi, ma il terminale non riceve dati: il sensore non è alimentato.";
    }
    if (faults.includes("reversed-led")) {
      return "La corrente sembra arrivare al LED, ma la luce resta spenta.";
    }
    if (faults.includes("missing-wire") || faults.includes("open-switch") || faults.includes("disconnected-component")) {
      return "Il LED resta spento: il tester segnala che la corrente non completa il giro.";
    }
    return "Il pannello segnala un comportamento elettrico non coerente.";
  }
}
