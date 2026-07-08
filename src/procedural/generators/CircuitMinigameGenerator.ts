import type {
  CircuitMinigamePrompt,
  CircuitMinigameTile,
  CircuitMinigameType,
  GeneratedCircuitMinigame,
} from "../ProceduralTypes";
import type { DifficultyPreset } from "../ProceduralTypes";
import { Random } from "../Random";

// Quick, varied electronics minigames that complement the full fault-diagnosis
// circuit. They widen the component gamma (component-id) and add new exercise
// kinds graded by difficulty: predict the LED state, Ohm's law, and
// series/parallel reasoning.

const COMPONENTS: Array<{ name: string; description: string; fn: string }> = [
  { name: "Batteria", description: "spinge la corrente dal + al -", fn: "fornisce energia" },
  { name: "Interruttore", description: "apre o chiude il percorso", fn: "controlla il passaggio di corrente" },
  { name: "Resistenza", description: "limita la corrente", fn: "protegge gli altri componenti" },
  { name: "LED", description: "si accende solo nel verso giusto", fn: "emette luce" },
  { name: "Condensatore", description: "accumula e rilascia carica", fn: "immagazzina energia" },
  { name: "Diodo", description: "lascia passare la corrente in un solo verso", fn: "fa passare corrente in un verso solo" },
  { name: "Fusibile", description: "si interrompe se la corrente è troppo alta", fn: "protegge da sovracorrenti" },
  { name: "Potenziometro", description: "resistenza regolabile a manopola", fn: "regola la corrente con continuità" },
  { name: "Relè", description: "interruttore comandato da un elettromagnete", fn: "comanda un circuito di potenza" },
  { name: "Motore", description: "trasforma corrente in movimento", fn: "produce movimento" },
  { name: "Sensore", description: "misura una grandezza e invia un segnale", fn: "rileva e segnala dati" },
  { name: "Buzzer", description: "emette un suono quando è alimentato", fn: "produce un segnale acustico" },
  { name: "Massa", description: "punto di ritorno stabile del circuito", fn: "dà un riferimento comune" },
  { name: "Lampadina", description: "si illumina al passaggio di corrente", fn: "emette luce per riscaldamento" },
];

function circuitTile(seed: number, label: string, isCorrect: boolean, feedback: string): CircuitMinigameTile {
  return {
    id: `circuit-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
    label,
    isCorrect,
    feedback,
  };
}

function shuffleCircuitTiles(random: Random, tiles: CircuitMinigameTile[]): CircuitMinigameTile[] {
  return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
}

function distinctNumbers(random: Random, correct: number, seeds: number[]): string[] {
  const out: string[] = [];
  const push = (value: number): void => {
    if (value >= 0 && value !== correct && !out.includes(String(value))) out.push(String(value));
  };
  seeds.forEach(push);
  let guard = 0;
  while (out.length < 3 && guard < 30) {
    push(correct + random.integer(-5, 5));
    guard += 1;
  }
  return random.shuffle(out).slice(0, 3);
}

// Components that have a drawable schematic symbol (see CircuitSymbols).
const DRAWABLE: Array<{ key: string; name: string }> = [
  { key: "battery", name: "Batteria" },
  { key: "switch", name: "Interruttore" },
  { key: "resistor", name: "Resistenza" },
  { key: "led", name: "LED" },
  { key: "capacitor", name: "Condensatore" },
  { key: "sensor", name: "Sensore" },
  { key: "relay", name: "Relè" },
  { key: "motor", name: "Motore" },
  { key: "ground", name: "Massa" },
];

function buildComponentSymbolPrompt(random: Random, index: number): CircuitMinigamePrompt {
  const target = random.pick(DRAWABLE);
  const others = random.shuffle(DRAWABLE.filter((c) => c.key !== target.key)).slice(0, 3);
  const tiles = shuffleCircuitTiles(random, [
    circuitTile(index, target.name, true, `Esatto: questo è il simbolo di ${target.name}.`),
    ...others.map((c, i) => circuitTile(index + i + 1, c.name, false, `No: questo è il simbolo di ${c.name}.`)),
  ]);
  return {
    id: `circuit-symbol-${index}`,
    type: "component-id",
    title: "Leggi il simbolo",
    diagramLines: ["Osserva il simbolo schematico a sinistra."],
    question: "Quale componente rappresenta questo simbolo?",
    targetLabel: "Simbolo",
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [target.name],
    explanation: `Il simbolo mostrato è quello di: ${target.name}.`,
    concept: "lettura dei simboli schematici",
    methodSteps: ["osserva la forma", "ricorda il simbolo standard", "scegli il componente"],
    visual: { kind: "component", component: target.key },
    signature: `component-symbol-${target.key}`,
  };
}

function buildComponentIdPrompt(random: Random, _level: number, index: number): CircuitMinigamePrompt {
  const mode = random.integer(0, 2);
  if (mode === 2) {
    return buildComponentSymbolPrompt(random, index);
  }
  const target = random.pick(COMPONENTS);
  const askFunction = mode === 1;
  const others = random.shuffle(COMPONENTS.filter((c) => c.name !== target.name)).slice(0, 3);
  if (askFunction) {
    const tiles = shuffleCircuitTiles(random, [
      circuitTile(index, target.fn, true, `Esatto: ${target.name} ${target.description}.`),
      ...others.map((c, i) => circuitTile(index + i + 1, c.fn, false, `Questa è la funzione di: ${c.name}.`)),
    ]);
    return {
      id: `circuit-component-${index}`,
      type: "component-id",
      title: "Riconosci il componente",
      diagramLines: [`Componente: ${target.name}`, `Indizio: ${target.description}`],
      question: `Qual è la funzione principale di: ${target.name}?`,
      targetLabel: target.name,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [target.fn],
      explanation: `${target.name}: ${target.fn} (${target.description}).`,
      concept: "componenti elettronici",
      methodSteps: ["leggi il nome", "ricorda a cosa serve", "scegli la funzione"],
      signature: `component-fn-${target.name}`,
    };
  }
  const tiles = shuffleCircuitTiles(random, [
    circuitTile(index, target.name, true, `Esatto: ${target.description}.`),
    ...others.map((c, i) => circuitTile(index + i + 1, c.name, false, `${c.name} invece ${c.description}.`)),
  ]);
  return {
    id: `circuit-component-${index}`,
    type: "component-id",
    title: "Riconosci il componente",
    diagramLines: ["Descrizione del componente:", target.description],
    question: `Quale componente ${target.description}?`,
    targetLabel: "Componente",
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [target.name],
    explanation: `${target.name}: ${target.description}. Funzione: ${target.fn}.`,
    concept: "componenti elettronici",
    methodSteps: ["leggi la descrizione", "collega alla funzione", "scegli il componente"],
    signature: `component-name-${target.name}`,
  };
}

function buildPredictLedPrompt(random: Random, level: number, index: number): CircuitMinigamePrompt {
  const switchClosed = random.bool(0.7);
  const ledForward = random.bool(0.7);
  const hasResistor = random.bool(level >= 3 ? 0.6 : 0.8);
  const hasOpen = random.bool(0.25);
  let correct: string;
  let why: string;
  if (!switchClosed || hasOpen || !ledForward) {
    correct = "Resta spento";
    why = !switchClosed ? "l'interruttore è aperto" : hasOpen ? "il percorso è interrotto" : "il LED è invertito";
  } else if (!hasResistor) {
    correct = "Si brucia";
    why = "senza resistenza la corrente è troppo alta";
  } else {
    correct = "Si accende";
    why = "percorso chiuso, polarità giusta e resistenza che protegge il LED";
  }
  const labels = ["Si accende", "Resta spento", "Si brucia", "Lampeggia"];
  const tiles = shuffleCircuitTiles(random, labels.map((label, i) =>
    circuitTile(index + i, label, label === correct, label === correct ? `Esatto: ${why}.` : `No: ${why}.`),
  ));
  return {
    id: `circuit-led-${index}`,
    type: "predict-led",
    title: "Cosa fa il LED?",
    diagramLines: [
      `Interruttore: ${switchClosed ? "chiuso" : "aperto"}`,
      `Polarità LED: ${ledForward ? "corretta" : "invertita"}`,
      `Resistenza: ${hasResistor ? "presente" : "assente"}`,
      `Percorso: ${hasOpen ? "interrotto" : "continuo"}`,
    ],
    question: "Premendo il pulsante, cosa succede al LED?",
    targetLabel: "Stato del LED",
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [correct],
    explanation: `Il LED ${correct.toLowerCase()}: ${why}.`,
    concept: "percorso chiuso e polarità",
    methodSteps: ["controlla l'interruttore", "controlla polarità e percorso", "verifica la resistenza"],
    visual: { kind: "led-circuit", switchClosed, ledForward, hasResistor, hasOpen, lit: correct === "Si accende" },
    signature: `led-${switchClosed}-${ledForward}-${hasResistor}-${hasOpen}`,
  };
}

function buildOhmsLawPrompt(random: Random, _level: number, index: number): CircuitMinigamePrompt {
  const r = random.integer(2, 9);
  const i = random.integer(1, 5);
  const v = r * i;
  const ask = random.integer(0, 2);
  let question: string;
  let correct: number;
  let lines: string[];
  if (ask === 0) {
    question = "Quanto vale la tensione V?";
    correct = v;
    lines = [`Resistenza R = ${r} Ω`, `Corrente I = ${i} A`, "Tensione V = ?", "Legge di Ohm: V = R × I"];
  } else if (ask === 1) {
    question = "Quanto vale la resistenza R?";
    correct = r;
    lines = [`Tensione V = ${v} V`, `Corrente I = ${i} A`, "Resistenza R = ?", "Legge di Ohm: R = V ÷ I"];
  } else {
    question = "Quanto vale la corrente I?";
    correct = i;
    lines = [`Tensione V = ${v} V`, `Resistenza R = ${r} Ω`, "Corrente I = ?", "Legge di Ohm: I = V ÷ R"];
  }
  const tiles = shuffleCircuitTiles(random, [
    circuitTile(index, String(correct), true, "Esatto: hai applicato la legge di Ohm."),
    ...distinctNumbers(random, correct, [correct + 1, correct - 1, v]).map((value, i2) =>
      circuitTile(index + i2 + 1, value, false, `Con la legge di Ohm il risultato è ${correct}, non ${value}: rileggi quale grandezza devi calcolare.`)),
  ]);
  return {
    id: `circuit-ohm-${index}`,
    type: "ohms-law",
    title: "Legge di Ohm",
    diagramLines: lines,
    question,
    targetLabel: "Legge di Ohm",
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [String(correct)],
    explanation: `Con V = R × I: ${v} = ${r} × ${i}.`,
    concept: "legge di Ohm (V = R × I)",
    methodSteps: ["scrivi la formula", "isola la grandezza richiesta", "calcola"],
    signature: `ohm-${r}-${i}-${ask}`,
  };
}

function buildSeriesParallelPrompt(random: Random, _level: number, index: number): CircuitMinigamePrompt {
  const conceptual = random.bool(0.4);
  if (conceptual) {
    const tiles = shuffleCircuitTiles(random, [
      circuitTile(index, "in parallelo", true, "Esatto: in parallelo la resistenza totale scende e passa più corrente."),
      circuitTile(index + 1, "in serie", false, "In serie la resistenza totale aumenta e la corrente cala."),
      circuitTile(index + 2, "in cortocircuito", false, "Il corto è un guasto, non una soluzione."),
      circuitTile(index + 3, "a circuito aperto", false, "A circuito aperto non passa corrente."),
    ]);
    return {
      id: `circuit-sp-${index}`,
      type: "series-parallel",
      title: "Serie o parallelo?",
      diagramLines: ["Stessa pila, due resistenze uguali.", "Vuoi più corrente nel circuito."],
      question: "Come conviene collegare le due resistenze per avere più corrente?",
      targetLabel: "Collegamento",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: ["in parallelo"],
      explanation: "In parallelo la resistenza totale diminuisce, quindi a parità di tensione passa più corrente.",
      concept: "serie e parallelo",
      methodSteps: ["ricorda l'effetto sulla resistenza totale", "serie somma, parallelo riduce", "scegli per la corrente voluta"],
      signature: "sp-conceptual",
    };
  }
  const r1 = random.integer(2, 9);
  const r2 = random.integer(2, 9);
  const total = r1 + r2;
  const tiles = shuffleCircuitTiles(random, [
    circuitTile(index, `${total} Ω`, true, "Esatto: in serie le resistenze si sommano."),
    ...distinctNumbers(random, total, [Math.abs(r1 - r2), r1, r2]).map((value, i2) =>
      circuitTile(index + i2 + 1, `${value} Ω`, false, `In serie si sommano: R1 + R2 = ${r1} + ${r2} = ${total} Ω, non ${value} Ω.`)),
  ]);
  return {
    id: `circuit-sp-${index}`,
    type: "series-parallel",
    title: "Resistenza in serie",
    diagramLines: [`Resistenza R1 = ${r1} Ω`, `Resistenza R2 = ${r2} Ω`, "Collegamento: in serie", "Totale = ?"],
    question: "Qual è la resistenza totale del collegamento in serie?",
    targetLabel: "Resistenza totale",
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [`${total} Ω`],
    explanation: `In serie le resistenze si sommano: ${r1} + ${r2} = ${total} Ω.`,
    concept: "resistenze in serie",
    methodSteps: ["riconosci il collegamento", "in serie somma le resistenze", "calcola il totale"],
    signature: `sp-series-${r1}-${r2}`,
  };
}

function buildPrompt(random: Random, level: number, type: CircuitMinigameType, index: number): CircuitMinigamePrompt {
  if (type === "component-id") return buildComponentIdPrompt(random, level, index);
  if (type === "predict-led") return buildPredictLedPrompt(random, level, index);
  if (type === "ohms-law") return buildOhmsLawPrompt(random, level, index);
  return buildSeriesParallelPrompt(random, level, index);
}

function concepts(type: CircuitMinigameType): string[] {
  if (type === "component-id") return ["componenti", "simboli", "funzioni"];
  if (type === "predict-led") return ["percorso chiuso", "polarità", "protezione"];
  if (type === "ohms-law") return ["legge di Ohm", "tensione", "corrente"];
  return ["serie", "parallelo", "resistenza totale"];
}

export function buildCircuitMinigame(random: Random, difficulty: DifficultyPreset, type: CircuitMinigameType): GeneratedCircuitMinigame {
  const promptCount = 16 + difficulty.level;
  const prompts: CircuitMinigamePrompt[] = [];
  let previousSignature = "";
  for (let index = 0; index < promptCount; index += 1) {
    let prompt = buildPrompt(random, difficulty.level, type, index);
    for (let attempt = 0; attempt < 8 && prompt.signature === previousSignature; attempt += 1) {
      prompt = buildPrompt(random, difficulty.level, type, index + 50 + attempt);
    }
    prompts.push(prompt);
    previousSignature = prompt.signature;
  }
  const titles: Record<CircuitMinigameType, string> = {
    "component-id": "Minigioco circuiti: Riconosci i componenti",
    "predict-led": "Minigioco circuiti: Prevedi il LED",
    "ohms-law": "Minigioco circuiti: Legge di Ohm",
    "series-parallel": "Minigioco circuiti: Serie e parallelo",
  };
  const instructions: Record<CircuitMinigameType, string> = {
    "component-id": "riconosci il componente o la sua funzione.",
    "predict-led": "prevedi se il LED si accende leggendo interruttore, polarità e resistenza.",
    "ohms-law": "applica la legge di Ohm per trovare il valore mancante.",
    "series-parallel": "calcola la resistenza totale o scegli il collegamento giusto.",
  };
  return {
    type,
    title: titles[type],
    durationMs: 60_000,
    instructions: instructions[type],
    scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti.",
    prompts,
    competencies: Array.from(new Set([
      "elettronica.circuitoChiuso",
      "pensieroCritico",
      ...concepts(type),
      ...(type === "ohms-law" || type === "series-parallel" ? ["matematica.calcolo", "matematica.logica"] : []),
      ...(type === "component-id" ? ["scienze.osservazione"] : []),
    ])),
  };
}

/** Picks a minigame type appropriate to the difficulty (harder kinds unlock later). */
export function circuitMinigameTypeForLevel(random: Random, level: number): CircuitMinigameType {
  const pool: CircuitMinigameType[] = ["component-id"];
  if (level >= 2) pool.push("predict-led");
  if (level >= 4) pool.push("ohms-law");
  if (level >= 5) pool.push("series-parallel");
  return random.pick(pool);
}
