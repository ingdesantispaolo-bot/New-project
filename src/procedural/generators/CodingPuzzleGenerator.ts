import type {
  CodingChallengeType,
  CodingMinigamePrompt,
  CodingMinigameTile,
  CodingMinigameType,
  DifficultyPreset,
  GeneratedCodingMinigame,
  GeneratedCodingPuzzle,
} from "../ProceduralTypes";
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

  generateMinigame(
    random: Random,
    difficulty: DifficultyPreset,
    preferredTypes: CodingMinigameType[] = [],
  ): GeneratedCodingPuzzle {
    const type = preferredTypes.length > 0
      ? random.pick(preferredTypes)
      : random.pick<CodingMinigameType>(["sequence-builder", "state-tracer", "bug-hunt"]);
    const game = buildCodingMinigame(random.fork(type), difficulty, type);
    const first = game.prompts[0];
    const options = first.tiles.map((tile) => tile.label);
    return {
      id: `coding-mini-${type}-${random.integer(1000, 9999)}`,
      title: game.title,
      challengeType: type === "bug-hunt" ? "debug-line" : type === "state-tracer" ? "variable-state" : "trace-output",
      difficultyLabel: `Livello ${difficulty.level}/8 - sprint coding`,
      scenario: "La console genera micro-programmi da stabilizzare in un minuto. Non premiare la memoria: simula il codice.",
      codeLines: first.codeLines,
      question: first.question,
      options,
      correctOption: first.solutionLabels[0],
      explanation: first.explanation,
      conceptTags: codingMinigameConcepts(type),
      methodSteps: codingMinigameMethodSteps(type),
      learningPurpose: codingMinigamePurpose(type),
      hints: [
        "Segui una riga alla volta: il computer non salta passaggi.",
        "Quando una variabile cambia, aggiorna il suo valore prima di leggere la riga successiva.",
        "Nel debug cerca la prima riga che rompe la regola, non una compensazione finale.",
      ],
      competencies: game.competencies,
      maxSeconds: 60,
      minigame: game,
    };
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

function buildCodingMinigame(random: Random, difficulty: DifficultyPreset, type: CodingMinigameType): GeneratedCodingMinigame {
  const promptCount = 18 + difficulty.level;
  const prompts: CodingMinigamePrompt[] = [];
  let previousSignature = "";
  for (let index = 0; index < promptCount; index += 1) {
    const prompt = uniqueCodingPrompt(random, difficulty, type, index, previousSignature);
    prompts.push(prompt);
    previousSignature = prompt.signature;
  }
  const titles: Record<CodingMinigameType, string> = {
    "sequence-builder": "Minigioco coding: Sequenza di comandi",
    "state-tracer": "Minigioco coding: Traccia la memoria",
    "bug-hunt": "Minigioco coding: Caccia al bug",
  };
  const instructions: Record<CodingMinigameType, string> = {
    "sequence-builder": "clicca il prossimo blocco che completa una procedura corretta.",
    "state-tracer": "clicca il valore o lo stato prodotto dal codice.",
    "bug-hunt": "clicca la correzione che elimina la causa dell'errore.",
  };
  return {
    type,
    title: titles[type],
    durationMs: 60_000,
    instructions: instructions[type],
    scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. Devi simulare mentalmente, non provare a caso.",
    prompts,
    competencies: Array.from(new Set([
      "coding.sequenze",
      "coding.testMentale",
      "problemSolving",
      "pensieroCritico",
      ...(type === "sequence-builder" ? ["coding.decomposizione"] : []),
      ...(type === "state-tracer" ? ["coding.efficienza", "matematica.logica"] : []),
      ...(type === "bug-hunt" ? ["coding.debugging", "coding.controlloErrore"] : []),
    ])),
  };
}

function uniqueCodingPrompt(
  random: Random,
  difficulty: DifficultyPreset,
  type: CodingMinigameType,
  index: number,
  previousSignature: string,
): CodingMinigamePrompt {
  for (let attempt = 0; attempt < 12; attempt += 1) {
    const prompt = buildCodingMinigamePrompt(random, difficulty, type, index + attempt);
    if (prompt.signature !== previousSignature) {
      return prompt;
    }
  }
  return buildCodingMinigamePrompt(random, difficulty, type, index + 99);
}

function buildCodingMinigamePrompt(
  random: Random,
  difficulty: DifficultyPreset,
  type: CodingMinigameType,
  index: number,
): CodingMinigamePrompt {
  if (type === "sequence-builder") return buildSequenceBuilderPrompt(random, difficulty, index);
  if (type === "state-tracer") return buildStateTracerPrompt(random, difficulty, index);
  return buildBugHuntPrompt(random, difficulty, index);
}

function buildSequenceBuilderPrompt(random: Random, difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const variants = [
    () => {
      const start = random.integer(2, 8);
      const target = start + random.integer(3, 8);
      const delta = target - start;
      return {
        title: "Completa la procedura",
        codeLines: [`energia = ${start}`, "obiettivo = " + target, "?"],
        question: "Quale blocco porta energia esattamente all'obiettivo?",
        correct: `energia = energia + ${delta}`,
        distractors: [`energia = energia * ${delta}`, `energia = energia - ${delta}`, `obiettivo = energia + ${delta}`],
        explanation: `Per arrivare da ${start} a ${target} serve aggiungere ${delta}. L'assegnazione deve aggiornare energia, non obiettivo.`,
        concept: "assegnazione come aggiornamento",
        methodSteps: ["leggi stato iniziale", "calcola differenza", "aggiorna la variabile giusta"],
      };
    },
    () => {
      const turns = random.integer(2, Math.min(6, difficulty.level + 2));
      return {
        title: "Riduci una ripetizione",
        codeLines: ["apri registro", "? ", "salva registro"],
        question: `Quale blocco ripete un controllo ${turns} volte senza copiare righe?`,
        correct: `ripeti ${turns} volte: controlla sensore`,
        distractors: [`controlla sensore ${turns}`, "se sensore: ripeti registro", `ripeti ${turns + 1} volte: salva registro`],
        explanation: `Un ciclo deve dire quante volte ripetere e quale istruzione ripete: controlla sensore per ${turns} volte.`,
        concept: "ciclo come compattezza",
        methodSteps: ["trova azione ripetuta", "trova numero ripetizioni", "non cambiare azioni esterne"],
      };
    },
    () => {
      const threshold = random.pick([40, 50, 60, 70]);
      return {
        title: "Scegli il ramo sicuro",
        codeLines: [`se batteria >= ${threshold}:`, "  avvia scansione", "altrimenti:", "?"],
        question: "Quale blocco completa il ramo alternativo in modo coerente?",
        correct: "ricarica batteria",
        distractors: ["avvia scansione", "stampa batteria >= soglia", "spegni tutto"],
        explanation: `Il ramo altrimenti vale quando la batteria non raggiunge ${threshold}: l'azione coerente è ricaricare.`,
        concept: "if / else",
        methodSteps: ["leggi condizione", "identifica ramo falso", "scegli azione complementare"],
      };
    },
  ];
  const item = random.pick(variants)();
  return codingPromptFromItem(random, index, "sequence-builder", item, "Prossimo blocco corretto");
}

function buildStateTracerPrompt(random: Random, difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  if (difficulty.level >= 4 && random.bool(0.5)) {
    const start = random.integer(1, 6);
    const add = random.integer(2, 5);
    const times = random.integer(3, Math.min(8, difficulty.level + 2));
    const answer = start + add * times;
    return codingPromptFromItem(random, index, "state-tracer", {
      title: "Traccia il ciclo",
      codeLines: [`x = ${start}`, `ripeti ${times} volte:`, `  x = x + ${add}`, "stampa x"],
      question: "Quale valore viene stampato?",
      correct: String(answer),
      distractors: [String(start + add), String(times * add), String(answer - add)],
      explanation: `Il ciclo aggiunge ${add} per ${times} volte: ${start} + ${times} * ${add} = ${answer}.`,
      concept: "accumulatore",
      methodSteps: ["stato iniziale", "effetto di una ripetizione", "moltiplica l'effetto"],
    }, "Valore stampato");
  }
  const a = random.integer(2, 8);
  const b = random.integer(2, 7);
  const c = a + b;
  const sub = random.integer(1, Math.min(5, c - 1));
  const answer = c - sub;
  return codingPromptFromItem(random, index, "state-tracer", {
    title: "Traccia la memoria",
    codeLines: [`a = ${a}`, `b = ${b}`, "c = a + b", `a = c - ${sub}`, "stampa a"],
    question: "Quanto vale a alla fine?",
    correct: String(answer),
    distractors: [String(a), String(c), String(b)],
    explanation: `a viene sovrascritta. c = ${a} + ${b} = ${c}; poi a = ${c} - ${sub} = ${answer}.`,
    concept: "variabile sovrascritta",
    methodSteps: ["tabella variabili", "aggiorna a sinistra", "usa l'ultimo valore"],
  }, "Valore finale");
}

function buildBugHuntPrompt(random: Random, difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const variants = [
    () => {
      const start = random.integer(4, 9);
      const inc = random.integer(2, 5);
      const times = random.integer(3, Math.min(7, difficulty.level + 2));
      const expected = start + inc * times;
      return {
        title: "Riga che rompe il risultato",
        codeLines: [`energia = ${start}`, `ripeti ${times} volte:`, `  energia = energia + ${inc}`, `energia = energia - ${inc}`, "stampa energia"],
        question: `Il valore atteso è ${expected}. Quale correzione elimina la causa?`,
        correct: `rimuovi: energia = energia - ${inc}`,
        distractors: [`ripeti ${times - 1} volte`, `energia = ${start + inc}`, "stampa prima del ciclo"],
        explanation: `Il ciclo produce già ${expected}; la sottrazione dopo il ciclo rovina il risultato.`,
        concept: "debug della causa",
        methodSteps: ["calcola atteso", "trova prima rottura", "non compensare altrove"],
      };
    },
    () => {
      const threshold = random.pick([50, 60, 70]);
      return {
        title: "Operatore invertito",
        codeLines: [`se batteria < ${threshold}:`, "  avvia scansione", "altrimenti:", "  ricarica batteria"],
        question: "Il sistema dovrebbe avviare solo con batteria sufficiente. Quale correzione serve?",
        correct: `< diventa >= nella condizione`,
        distractors: ["scambia i nomi delle variabili", "rimuovi altrimenti", "avvia sempre scansione"],
        explanation: `Batteria sufficiente significa maggiore o uguale a ${threshold}, non minore.`,
        concept: "operatore di confronto",
        methodSteps: ["leggi requisito", "confronta con condizione", "correggi il simbolo"],
      };
    },
    () => {
      return {
        title: "AND o OR?",
        codeLines: ["codiceOk = vero", "portaAperta = codiceOk OR circuitoOk", "stampa portaAperta"],
        question: "La porta deve aprirsi solo se codice e circuito sono entrambi ok. Quale correzione serve?",
        correct: "OR diventa AND",
        distractors: ["codiceOk diventa falso", "stampa circuitoOk", "rimuovi codiceOk"],
        explanation: "Solo se entrambi sono ok richiede AND. OR basterebbe con una sola condizione vera.",
        concept: "logica booleana",
        methodSteps: ["traduci requisito", "controlla operatore", "AND = tutti veri"],
      };
    },
  ];
  const item = random.pick(variants)();
  return codingPromptFromItem(random, index, "bug-hunt", item, "Correzione corretta");
}

function codingPromptFromItem(
  random: Random,
  index: number,
  type: CodingMinigameType,
  item: {
    title: string;
    codeLines: string[];
    question: string;
    correct: string;
    distractors: string[];
    explanation: string;
    concept: string;
    methodSteps: string[];
  },
  targetLabel: string,
): CodingMinigamePrompt {
  const tiles = shuffleCodingTiles(random, [
    codingTile(index, item.correct, true, `Corretto: ${item.explanation}`),
    ...item.distractors.map((label, choiceIndex) => codingTile(index + choiceIndex + 1, label, false, `Non basta: ${item.explanation}`)),
  ]);
  return {
    id: `coding-${type}-${index}`,
    type,
    title: item.title,
    codeLines: item.codeLines,
    question: item.question,
    targetLabel,
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [item.correct],
    explanation: item.explanation,
    concept: item.concept,
    methodSteps: item.methodSteps,
    signature: `${type}-${item.question}-${item.correct}-${item.codeLines.join("|")}`,
  };
}

function codingTile(seed: number, label: string, isCorrect: boolean, feedback: string): CodingMinigameTile {
  return {
    id: `coding-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
    label,
    isCorrect,
    feedback,
  };
}

function shuffleCodingTiles(random: Random, tiles: CodingMinigameTile[]): CodingMinigameTile[] {
  return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
}

function codingMinigameConcepts(type: CodingMinigameType): string[] {
  if (type === "sequence-builder") return ["sequenza", "decomposizione", "algoritmo"];
  if (type === "state-tracer") return ["variabili", "tracing", "cicli"];
  return ["debug", "condizioni", "controllo errore"];
}

function codingMinigameMethodSteps(type: CodingMinigameType): string[] {
  if (type === "sequence-builder") return ["obiettivo", "stato attuale", "prossimo blocco"];
  if (type === "state-tracer") return ["tabella variabili", "aggiorna stato", "stampa finale"];
  return ["risultato atteso", "prima rottura", "correzione minima"];
}

function codingMinigamePurpose(type: CodingMinigameType): string {
  if (type === "sequence-builder") return "Allenare costruzione di algoritmi brevi: scegliere il prossimo blocco coerente con obiettivo e stato.";
  if (type === "state-tracer") return "Allenare esecuzione mentale del codice: aggiornare variabili, cicli e output senza tirare a indovinare.";
  return "Allenare debugging: distinguere causa dell'errore, sintomo e correzione minima.";
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
