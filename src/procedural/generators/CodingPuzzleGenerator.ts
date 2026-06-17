import type { CodingChallengeType, DifficultyPreset, GeneratedCodingPuzzle } from "../ProceduralTypes";
import { Random } from "../Random";

type CodingTemplate = {
  type: CodingChallengeType;
  minLevel: number;
  build: (random: Random, difficulty: DifficultyPreset) => GeneratedCodingPuzzle;
};

export class CodingPuzzleGenerator {
  generate(random: Random, difficulty: DifficultyPreset, preferredTypes?: CodingChallengeType[]): GeneratedCodingPuzzle {
    const available = codingTemplates.filter((template) =>
      template.minLevel <= difficulty.level
      && (!preferredTypes || preferredTypes.includes(template.type)));
    const template = random.pick(available.length > 0 ? available : codingTemplates.filter((item) => item.minLevel <= difficulty.level));
    return template.build(random.fork(template.type), difficulty);
  }

  fallback(): GeneratedCodingPuzzle {
    return buildTracePuzzle(new Random("coding-fallback"), {
      level: 1,
      roomCount: 1,
      puzzleCount: 5,
      mathComplexity: 1,
      robotGrid: { cols: 5, rows: 4 },
      robotObstacleCount: 2,
      circuitComplexity: 1,
      availableHints: 5,
      maxAttemptsBeforeExplanation: 4,
      distractorCount: 1,
      noiseDataCount: 0,
      requiredReasoningSteps: 1,
      pedagogicalFocus: ["osservazione"],
    });
  }
}

function basePuzzle(
  difficulty: DifficultyPreset,
  type: CodingChallengeType,
  title: string,
  scenario: string,
  codeLines: string[],
  question: string,
  options: string[],
  correctOption: string,
  explanation: string,
  conceptTags: string[],
  methodSteps: string[],
): GeneratedCodingPuzzle {
  return {
    id: `coding-${type}`,
    title,
    challengeType: type,
    difficultyLabel: `Livello ${difficulty.level}/8 - ${difficulty.level <= 2 ? "traccia guidata" : difficulty.level <= 5 ? "ragionamento su stati" : "debug e astrazione"}`,
    scenario,
    codeLines,
    question,
    options,
    correctOption,
    explanation,
    conceptTags,
    methodSteps,
    learningPurpose: learningPurposeFor(type),
    hints: hintsFor(type),
    competencies: competenciesFor(type),
    maxSeconds: Math.max(45, 95 - difficulty.level * 5),
  };
}

function buildTracePuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  const start = random.integer(2, 7);
  const add = random.integer(2, 6);
  const multiplier = difficulty.level >= 3 ? random.integer(2, 4) : 2;
  const answer = (start + add) * multiplier;
  return basePuzzle(
    difficulty,
    "trace-output",
    "Console codice: prevedi l'uscita",
    "Il terminale non esegue il codice finche non sai prevedere cosa stampera.",
    [
      `energia = ${start}`,
      `energia = energia + ${add}`,
      `energia = energia * ${multiplier}`,
      "stampa energia",
    ],
    "Quale valore viene stampato?",
    shuffledOptions(random, String(answer), [String(start + add), String(start * multiplier + add), String(start + add + multiplier)]),
    String(answer),
    `Il codice aggiorna energia in sequenza: prima ${start} + ${add} = ${start + add}, poi ${start + add} * ${multiplier} = ${answer}.`,
    ["sequenza", "tracing", "output"],
    ["leggi dall'alto", "scrivi ogni valore nuovo", "controlla cosa stampa l'ultima riga"],
  );
}

function buildVariableStatePuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  const a = random.integer(3, 8);
  const b = random.integer(2, 6);
  const c = a + b;
  const finalA = c - random.integer(1, Math.min(4, c - 1));
  return basePuzzle(
    difficulty,
    "variable-state",
    "Console codice: stato variabili",
    "La memoria della console cambia riga dopo riga: serve sapere il valore finale di una variabile.",
    [
      `a = ${a}`,
      `b = ${b}`,
      "c = a + b",
      `a = c - ${c - finalA}`,
      "stampa a",
    ],
    "Quanto vale `a` alla fine?",
    shuffledOptions(random, String(finalA), [String(a), String(c), String(b)]),
    String(finalA),
    `La variabile a viene sovrascritta: all'inizio vale ${a}, ma alla fine diventa c - ${c - finalA}, cioe ${finalA}.`,
    ["variabili", "assegnazione", "stato"],
    ["non usare il primo valore per forza", "aggiorna la tabella delle variabili", "leggi l'ultima assegnazione"],
  );
}

function buildLoopPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  const times = random.integer(3, Math.min(8, 3 + difficulty.level));
  const delta = random.integer(2, 6);
  const start = random.integer(0, 5);
  const answer = start + times * delta;
  return basePuzzle(
    difficulty,
    "loop-count",
    "Console codice: ciclo controllato",
    "Il ciclo ripete lo stesso blocco: la sfida e contare l'effetto, non ripetere a caso.",
    [
      `segnale = ${start}`,
      `ripeti ${times} volte:`,
      `  segnale = segnale + ${delta}`,
      "stampa segnale",
    ],
    "Quale valore viene stampato dopo il ciclo?",
    shuffledOptions(random, String(answer), [String(start + delta), String(times + delta), String(answer - delta)]),
    String(answer),
    `Il blocco aggiunge ${delta} per ${times} volte: aumento totale ${times} * ${delta} = ${times * delta}; ${start} + ${times * delta} = ${answer}.`,
    ["ciclo", "ripetizione", "accumulatore"],
    ["trova cosa si ripete", "calcola effetto di una ripetizione", "moltiplica per il numero di ripetizioni"],
  );
}

function buildConditionalPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  const battery = random.integer(35, 95);
  const threshold = difficulty.level >= 5 ? random.integer(55, 75) : 60;
  const safe = battery >= threshold;
  return basePuzzle(
    difficulty,
    "conditional-branch",
    "Console codice: ramo condizionale",
    "La porta non vuole il risultato di un calcolo: vuole sapere quale ramo del codice verra eseguito.",
    [
      `batteria = ${battery}`,
      `se batteria >= ${threshold}:`,
      "  azione = \"avvia scansione\"",
      "altrimenti:",
      "  azione = \"ricarica\"",
      "stampa azione",
    ],
    "Quale azione viene stampata?",
    shuffledOptions(random, safe ? "avvia scansione" : "ricarica", ["apri porta", "spegni sensore", safe ? "ricarica" : "avvia scansione"]),
    safe ? "avvia scansione" : "ricarica",
    `${battery} ${safe ? "e maggiore o uguale" : "e minore"} di ${threshold}: quindi il codice segue il ramo ${safe ? "se" : "altrimenti"}.`,
    ["condizione", "confronto", "ramo"],
    ["valuta la condizione", "scegli solo il ramo vero", "ignora il ramo non eseguito"],
  );
}

function buildBooleanPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  const codeOk = random.bool(0.55);
  const circuitOk = difficulty.level >= 6 ? random.bool(0.5) : true;
  const sensorOk = difficulty.level >= 6 ? random.bool(0.55) : true;
  const answer = codeOk && circuitOk && sensorOk;
  return basePuzzle(
    difficulty,
    "boolean-logic",
    "Console codice: logica booleana",
    "La porta usa condizioni insieme: basta un falso per bloccare tutto.",
    [
      `codiceOk = ${codeOk ? "vero" : "falso"}`,
      `circuitoOk = ${circuitOk ? "vero" : "falso"}`,
      `sensoreOk = ${sensorOk ? "vero" : "falso"}`,
      "portaAperta = codiceOk AND circuitoOk AND sensoreOk",
      "stampa portaAperta",
    ],
    "Che cosa stampa la console?",
    shuffledOptions(random, answer ? "vero" : "falso", [answer ? "falso" : "vero", "solo se codiceOk", "errore"]),
    answer ? "vero" : "falso",
    `AND richiede che tutte le condizioni siano vere. Qui il risultato e ${answer ? "vero" : "falso"}.`,
    ["booleani", "AND", "condizioni multiple"],
    ["controlla ogni variabile", "AND funziona solo se tutto e vero", "un falso basta a rendere falso il risultato"],
  );
}

function buildDebugPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  const base = random.integer(4, 9);
  const increment = random.integer(2, 5);
  const repeats = random.integer(3, Math.min(6, difficulty.level + 1));
  const correct = base + repeats * increment;
  return basePuzzle(
    difficulty,
    "debug-line",
    "Console codice: trova la riga guasta",
    "Il log dovrebbe accumulare energia con lo stesso incremento, ma una riga rompe la regola.",
    [
      `energia = ${base}`,
      `ripeti ${repeats} volte:`,
      `  energia = energia + ${increment}`,
      `energia = energia - ${increment}`,
      "stampa energia",
    ],
    `Il valore atteso era ${correct}. Quale correzione rende coerente il programma?`,
    shuffledOptions(random, "elimina la riga energia = energia - " + increment, [
      `cambia ripeti ${repeats} volte in ripeti ${repeats - 1} volte`,
      `cambia energia = ${base} in energia = ${base + increment}`,
      "sposta stampa energia sopra il ciclo",
    ]),
    "elimina la riga energia = energia - " + increment,
    `Il ciclo produce gia ${correct}. La riga successiva sottrae ${increment} e rovina il risultato: va rimossa, non compensata altrove.`,
    ["debug", "invariante", "controllo errore"],
    ["calcola il valore atteso del ciclo", "trova la prima riga che rompe la regola", "correggi la causa, non il sintomo"],
  );
}

function shuffledOptions(random: Random, correct: string, distractors: string[]): string[] {
  return random.shuffle([correct, ...random.shuffle(distractors.filter((item) => item !== correct)).slice(0, 3)]);
}

function learningPurposeFor(type: CodingChallengeType): string {
  return {
    "trace-output": "Allenare il tracing: prevedere l'output eseguendo mentalmente le righe in ordine.",
    "variable-state": "Capire che una variabile puo cambiare valore e va aggiornata riga dopo riga.",
    "loop-count": "Capire i cicli come ripetizione controllata di un effetto.",
    "conditional-branch": "Valutare una condizione e scegliere il ramo realmente eseguito.",
    "boolean-logic": "Combinare condizioni vere/falsi con logica booleana.",
    "debug-line": "Trovare la riga che rompe una regola attesa e correggere la causa.",
  }[type];
}

function hintsFor(type: CodingChallengeType): string[] {
  return {
    "trace-output": ["Fai una tabella con una riga per ogni assegnazione.", "L'output e solo cio che viene stampato alla fine."],
    "variable-state": ["Quando vedi =, aggiorna il valore della variabile a sinistra.", "Il valore iniziale puo non essere quello finale."],
    "loop-count": ["Calcola l'effetto di una ripetizione.", "Poi moltiplica l'effetto per quante volte si ripete."],
    "conditional-branch": ["Prima decidi se la condizione e vera o falsa.", "Esegui solo il ramo scelto."],
    "boolean-logic": ["AND richiede tutto vero.", "OR richiederebbe almeno un vero, ma qui controlla l'operatore scritto."],
    "debug-line": ["Calcola prima cosa dovrebbe succedere.", "La riga guasta e quella che rovina una regola gia soddisfatta."],
  }[type];
}

function competenciesFor(type: CodingChallengeType): string[] {
  const base = ["coding.sequenze", "problemSolving", "pensieroCritico"];
  if (type === "debug-line") return [...base, "coding.debugging", "coding.testMentale"];
  if (type === "loop-count") return [...base, "coding.efficienza", "matematica.logica"];
  if (type === "conditional-branch" || type === "boolean-logic") return [...base, "coding.decomposizione", "matematica.logica"];
  return [...base, "coding.testMentale"];
}

const codingTemplates: CodingTemplate[] = [
  { type: "trace-output", minLevel: 1, build: buildTracePuzzle },
  { type: "variable-state", minLevel: 2, build: buildVariableStatePuzzle },
  { type: "loop-count", minLevel: 3, build: buildLoopPuzzle },
  { type: "conditional-branch", minLevel: 3, build: buildConditionalPuzzle },
  { type: "boolean-logic", minLevel: 5, build: buildBooleanPuzzle },
  { type: "debug-line", minLevel: 5, build: buildDebugPuzzle },
];
