import { circuitBaseEdges, circuitComponentGuide, circuitFaultTemplates, circuitNodes, optionalCircuitNodes } from "../../data/procedural/circuitTemplates";
import type { CircuitComponentChallenge, CircuitFaultType, CircuitMinigameType, DifficultyPreset, GeneratedCircuitPuzzle } from "../ProceduralTypes";
import type { Random } from "../Random";
import { buildCircuitMinigame, circuitMinigameTypeForLevel } from "./CircuitMinigameGenerator";

const faultObservations: Record<CircuitFaultType, string> = {
  "missing-wire": "Il tester dice che tra LED e ritorno manca un tratto: il filo non chiude il giro.",
  "open-switch": "La leva dell'interruttore è sollevata: il ponte è aperto e la corrente si ferma.",
  "reversed-led": "Il LED resta spento anche se la corrente arriva: potrebbe essere girato al contrario.",
  "missing-resistor": "Il LED lampeggia male: manca la resistenza che lo protegge.",
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
  "missing-wire": "Un filo mancante interrompe il giro: anche con batteria e LED corretti la corrente non torna indietro.",
  "open-switch": "Un interruttore aperto è come un ponte alzato: chiuderlo fa continuare il percorso.",
  "reversed-led": "Il LED funziona quasi solo in un verso: se è girato male resta spento.",
  "missing-resistor": "La resistenza protegge il LED limitando la corrente. Senza resistenza il LED non è al sicuro.",
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
    const levelFaults = new Set(this.faultsForLevel(difficulty.level));
    const eligibleFaults = circuitFaultTemplates.filter((fault) => levelFaults.has(fault.type) && (fault.minComplexity ?? 1) <= difficulty.circuitComplexity);
    const fallbackEligible = circuitFaultTemplates.filter((fault) => (fault.minComplexity ?? 1) <= 1);
    const safeEligibleFaults = eligibleFaults.length > 0 ? eligibleFaults : fallbackEligible;
    const faultCount = this.faultCountForLevel(difficulty.level, difficulty.circuitComplexity, safeEligibleFaults.length);
    const preferredPool = preferredFaults.length > 0 ? safeEligibleFaults.filter((fault) => preferredFaults.includes(fault.type)) : [];
    const firstFault = preferredPool.length > 0 ? [random.pick(preferredPool)] : [];
    const remainingPool = random.shuffle(safeEligibleFaults.filter((fault) => !firstFault.some((selected) => selected.type === fault.type)));
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
        "Prima nomina i pezzi: batteria, interruttore, resistenza, LED e ritorno.",
        "Poi segui il giro con il dito: parte dal +, passa nei componenti e deve tornare al -.",
        "Solo dopo usa il tester: cerca il primo punto in cui il giro non torna.",
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
      difficultyLabel: `Profondità ${difficulty.level} - ${this.levelName(difficulty.level)}`,
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

  private faultsForLevel(level: number): CircuitFaultType[] {
    if (level <= 1) {
      return ["open-switch", "missing-wire"];
    }
    if (level === 2) {
      return ["open-switch", "missing-wire", "missing-resistor"];
    }
    if (level === 3) {
      return ["open-switch", "missing-wire", "missing-resistor", "reversed-led", "wrong-resistor-value"];
    }
    if (level === 4) {
      return ["missing-wire", "reversed-led", "missing-resistor", "wrong-resistor-value", "disconnected-component", "sensor-unpowered"];
    }
    if (level <= 6) {
      return [
        "missing-wire",
        "reversed-led",
        "missing-resistor",
        "wrong-resistor-value",
        "disconnected-component",
        "sensor-unpowered",
        "parallel-branch-open",
        "capacitor-discharged",
        "short-circuit",
        "loose-ground",
      ];
    }
    return circuitFaultTemplates.map((fault) => fault.type);
  }

  private faultCountForLevel(level: number, complexity: number, eligibleCount: number): number {
    if (level <= 3) {
      return Math.min(1, eligibleCount);
    }
    if (level <= 6) {
      return Math.min(1 + Math.floor(complexity / 4), 2, eligibleCount);
    }
    return Math.min(1 + Math.floor(complexity / 3), 3, eligibleCount);
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
      difficultyLabel: "Profondità 1 - percorso chiuso",
      learningPurpose: this.learningPurposeForScenario("percorso-aperto"),
      conceptTags: ["circuito chiuso", "interruttore", "continuità"],
      componentChallenges: this.fallbackComponentChallenges(level),
      competencies: ["elettronica.circuitoChiuso", "problemSolving"],
    };
  }

  private fallbackComponentChallenges(level: number): CircuitComponentChallenge[] {
    const components = level <= 1
      ? ["battery", "switch", "return"]
      : level === 2
        ? ["resistor", "led"]
        : ["switch", "resistor", "led"];
    return components.map((componentId) => this.fallbackComponentChallenge(componentId));
  }

  private fallbackComponentChallenge(componentId: string): CircuitComponentChallenge {
    const component = circuitComponentGuide.find((item) => item.id === componentId) ?? circuitComponentGuide[0];
    const distractors = circuitComponentGuide.filter((item) => item.id !== component.id).slice(0, 2);
    const correctSymbol = component.symbolName ?? component.label;
    const correctFunction = component.functionSummary ?? component.role;
    return {
      componentId: component.id,
      componentLabel: component.label,
      symbolQuestion: "Che pezzo è quello cerchiato?",
      functionQuestion: "A cosa serve nel giro della corrente?",
      correctSymbol,
      correctFunction,
      symbolChoices: [correctSymbol, ...distractors.map((item) => item.symbolName ?? item.label)],
      functionChoices: [correctFunction, ...distractors.map((item) => item.functionSummary ?? item.role)],
      visualHint: component.symbolClue ?? component.check,
      explanation: `${component.label}: ${component.functionSummary ?? component.role}. Indizio visivo: ${component.symbolClue ?? component.check}. Da ricordare: ${component.commonConfusion ?? component.check}.`,
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
      "percorso-aperto": "Circuito base: il LED non si accende",
      "corrente-instabile": "Circuito con LED da proteggere",
      polarita: "Circuito con LED girato",
      "multi-guasto": "Circuito con due problemi",
      "serie-parallelo": "Circuito con due strade",
      "sensore-soglia": "Circuito con sensore spento",
      "logica-rele": "Circuito con relè",
      temporizzazione: "Circuito con impulso breve",
      "corto-circuito": "Circuito con scorciatoia",
    }[scenario ?? "percorso-aperto"];
  }

  private questionForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "In quale punto il giro della corrente si ferma?",
      "corrente-instabile": "Quale pezzo deve proteggere il LED?",
      polarita: "Il LED è messo nel verso giusto?",
      "multi-guasto": "Quali problemi sono davvero provati dal tester?",
      "serie-parallelo": "Quale delle due strade è interrotta?",
      "sensore-soglia": "Perché il sensore non riceve energia?",
      "logica-rele": "Quale parte del relè non fa partire il carico?",
      temporizzazione: "Perché l'impulso dura troppo poco?",
      "corto-circuito": "Dove la corrente prende una scorciatoia?",
    }[scenario ?? "percorso-aperto"];
  }

  private goalForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "Obiettivo: costruire un giro chiuso. La corrente parte dal +, passa nei pezzi e torna al -.",
      "corrente-instabile": "Obiettivo: capire che il LED va protetto dalla resistenza, non solo acceso.",
      polarita: "Obiettivo: scoprire che il LED funziona solo se è girato nel verso giusto.",
      "multi-guasto": "Obiettivo: trovare due problemi senza riparare pezzi a caso.",
      "serie-parallelo": "Obiettivo: vedere che due strade possono funzionare in modo diverso.",
      "sensore-soglia": "Obiettivo: capire che un sensore misura solo se riceve energia.",
      "logica-rele": "Obiettivo: usare il relè come interruttore comandato.",
      temporizzazione: "Obiettivo: vedere il condensatore come una piccola riserva di energia.",
      "corto-circuito": "Obiettivo: riconoscere una scorciatoia pericolosa.",
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
      { from: "Batteria +", to: "Interruttore", reading: "continuita", note: "Fin qui il filo è collegato: il problema è più avanti." },
    ];
    const byFault: Record<CircuitFaultType, NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]> = {
      "missing-wire": { from: "LED", to: "Ritorno", reading: "interrotto", note: "Dopo il LED il giro si apre: manca un pezzo di filo." },
      "open-switch": { from: "Interruttore", to: "Resistenza", reading: "interrotto", note: "La leva non unisce i due contatti." },
      "reversed-led": { from: "Resistenza", to: "LED", reading: "polarita-inversa", note: "La corrente arriva, ma il LED è nel verso sbagliato." },
      "missing-resistor": { from: "Resistenza", to: "LED", reading: "non-stabile", note: "La corrente non è limitata: manca la protezione del LED." },
      "disconnected-component": { from: "Sensore", to: "Bus dati", reading: "interrotto", note: "Il componente è fisicamente presente ma fuori nodo." },
      "sensor-unpowered": { from: "Batteria +", to: "Sensore", reading: "tensione-bassa", note: "Il sensore non riceve energia sufficiente per misurare." },
      "capacitor-discharged": { from: "Condensatore", to: "Ritorno", reading: "carica-bassa", note: "La carica non resta abbastanza per stabilizzare l'impulso." },
      "short-circuit": { from: "Batteria +", to: "Ritorno", reading: "corto", note: "C'è una scorciatoia: la corrente evita resistenza e LED." },
      "parallel-branch-open": { from: "Ramo B", to: "Ritorno", reading: "interrotto", note: "Il ramo principale è vivo, ma il secondo ramo non chiude il giro." },
      "wrong-resistor-value": { from: "Resistenza", to: "LED", reading: "non-stabile", note: "La resistenza c'è, ma lascia passare troppa o troppo poca corrente." },
      "relay-not-armed": { from: "Bobina relè", to: "Ritorno", reading: "tensione-bassa", note: "Il contatto di potenza resta aperto perché la bobina non è armata." },
      "loose-ground": { from: "Ritorno", to: "Massa", reading: "non-stabile", note: "La continuità compare e sparisce: il riferimento non è affidabile." },
    };
    faults.forEach((fault) => readings.push(byFault[fault]));
    const confirmation = [
      { from: "Batteria -", to: "Ritorno", reading: "continuita" as const, note: "Il tester conferma che il ritorno arriva verso il polo -." },
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
    const stagedComponents = this.componentLearningPath(level);
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
    stagedComponents
      .filter((componentId) => nodes.includes(componentId))
      .forEach((componentId) => ordered.add(componentId));
    faults.forEach((fault) => {
      priorityByFault[fault]
        .filter((componentId) => nodes.includes(componentId))
        .forEach((componentId) => ordered.add(componentId));
    });
    nodes
      .filter((componentId) => circuitComponentGuide.some((component) => component.id === componentId))
      .forEach((componentId) => ordered.add(componentId));
    const count = level <= 1 ? 3 : level <= 3 ? 2 : level >= 7 ? 2 : 1;
    return [...ordered]
      .slice(0, count)
      .map((componentId) => this.componentChallenge(componentId, nodes, random));
  }

  private componentLearningPath(level: number): string[] {
    if (level <= 1) {
      return ["battery", "switch", "return"];
    }
    if (level === 2) {
      return ["resistor", "led"];
    }
    if (level === 3) {
      return ["switch", "resistor", "led", "return"];
    }
    if (level <= 5) {
      return ["resistor", "led", "sensor", "branchLed", "capacitor"];
    }
    return ["resistor", "ground", "relay", "motor", "branchLed"];
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
      symbolQuestion: "Che pezzo è quello cerchiato?",
      functionQuestion: "A cosa serve nel giro della corrente?",
      correctSymbol,
      correctFunction,
      symbolChoices: random.shuffle([correctSymbol, ...symbolDistractors]),
      functionChoices: random.shuffle([correctFunction, ...functionDistractors]),
      visualHint: component.symbolClue ?? component.check,
      explanation: `${component.label}: ${component.functionSummary ?? component.role}. Indizio visivo: ${component.symbolClue ?? component.check}. Da ricordare: ${component.commonConfusion ?? component.check}.`,
    };
  }

  private diagnosticPlanForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string[] {
    return {
      "percorso-aperto": ["Nomina i pezzi.", "Segui il filo dal + al -.", "Trova dove il giro si ferma."],
      "corrente-instabile": ["Trova la resistenza.", "Controlla se protegge il LED.", "Ripara solo la protezione."],
      polarita: ["Trova il LED.", "Guarda il verso.", "Giralo solo se il tester lo conferma."],
      "multi-guasto": ["Leggi una misura alla volta.", "Abbina ogni misura a un pezzo.", "Ripara solo ciò che è provato."],
      "serie-parallelo": ["Segui strada A.", "Segui strada B.", "Ripara solo la strada rotta."],
      "sensore-soglia": ["Trova il sensore.", "Controlla se riceve energia.", "Ricollega il suo ramo."],
      "logica-rele": ["Trova il comando.", "Trova il contatto.", "Attiva il relè se manca energia."],
      temporizzazione: ["Osserva quanto dura la luce.", "Controlla il condensatore.", "Ricarica la riserva."],
      "corto-circuito": ["Cerca una scorciatoia.", "Non testare finché c'è corto.", "Togli la scorciatoia."],
    }[scenario ?? "percorso-aperto"];
  }

  private learningPurposeForScenario(scenario: GeneratedCircuitPuzzle["scenarioType"]): string {
    return {
      "percorso-aperto": "Imparare il giro base della corrente.",
      "corrente-instabile": "Imparare perché la resistenza protegge il LED.",
      polarita: "Imparare che il LED ha un verso.",
      "multi-guasto": "Imparare a trovare più problemi senza andare a caso.",
      "serie-parallelo": "Imparare che un circuito può avere due strade.",
      "sensore-soglia": "Imparare che un sensore deve essere alimentato.",
      "logica-rele": "Imparare che un relè è un interruttore comandato.",
      temporizzazione: "Imparare che un condensatore conserva energia per poco.",
      "corto-circuito": "Imparare perché una scorciatoia è pericolosa.",
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
    if (level <= 1) return "pezzi base";
    if (level <= 2) return "resistenza e LED";
    if (level <= 3) return "verso del LED";
    if (level <= 5) return "tester e rami";
    if (level <= 6) return "sicurezza";
    return "circuiti combinati";
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
      return "Il LED prova ad accendersi, ma lampeggia male: manca protezione.";
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
      return "Il LED si accende troppo forte o troppo debole: la resistenza non va bene.";
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
      return "La corrente arriva al LED, ma la luce resta spenta: forse è girato male.";
    }
    if (faults.includes("missing-wire") || faults.includes("open-switch") || faults.includes("disconnected-component")) {
      return "Il LED resta spento: da qualche parte il giro della corrente si interrompe.";
    }
    return "Il pannello segnala un comportamento elettrico non coerente.";
  }
}
