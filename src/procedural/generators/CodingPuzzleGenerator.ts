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
      : random.pick<CodingMinigameType>(["sequence-builder", "state-tracer", "bug-hunt", "binary-bits", "logic-gate", "loop-output", "conditional-path", "algorithm-order"]);
    const game = buildCodingMinigame(random.fork(type), difficulty, type);
    const first = game.prompts[0];
    let options: string[];
    let correctOption: string;
    if (type === "algorithm-order") {
      // Tiles are single steps; the repair-tab choices come from the full
      // ordered algorithm plus plausible wrong orderings.
      const ordered = first.solutionLabels.join(" → ");
      const variants = new Set<string>();
      const swap = (source: string[], i: number, j: number): string => {
        const copy = [...source];
        [copy[i], copy[j]] = [copy[j], copy[i]];
        return copy.join(" → ");
      };
      if (first.solutionLabels.length >= 2) variants.add(swap(first.solutionLabels, 0, 1));
      if (first.solutionLabels.length >= 3) variants.add(swap(first.solutionLabels, first.solutionLabels.length - 2, first.solutionLabels.length - 1));
      variants.add([...first.solutionLabels].reverse().join(" → "));
      let guard = 0;
      while (variants.size < 3 && guard < 20) {
        variants.add(random.shuffle([...first.solutionLabels]).join(" → "));
        guard += 1;
      }
      variants.delete(ordered);
      options = random.shuffle([ordered, ...[...variants].slice(0, 3)]);
      correctOption = ordered;
    } else {
      options = first.tiles.map((tile) => tile.label);
      correctOption = first.solutionLabels[0];
    }
    return {
      id: `coding-mini-${type}-${random.integer(1000, 9999)}`,
      title: game.title,
      challengeType: type === "bug-hunt" ? "debug-line" : type === "state-tracer" ? "variable-state" : "trace-output",
      difficultyLabel: `Livello ${difficulty.level}/8 - sprint coding`,
      scenario: "La console genera micro-programmi da stabilizzare in un minuto. Non premiare la memoria: simula il codice.",
      codeLines: first.codeLines,
      question: first.question,
      options,
      correctOption,
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

  fallback(random = new Random("coding-fallback"), difficulty?: DifficultyPreset): GeneratedCodingPuzzle {
    return buildTracePuzzle(random, difficulty ?? {
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
    "sequence-builder": "Minigioco coding: Completa il codice",
    "state-tracer": "Minigioco coding: Traccia la memoria",
    "bug-hunt": "Minigioco coding: Caccia al bug",
    "binary-bits": "Minigioco coding: Codice binario",
    "logic-gate": "Minigioco coding: Porte logiche",
    "loop-output": "Minigioco coding: Output del ciclo",
    "conditional-path": "Minigioco coding: Bivio condizionale",
    "algorithm-order": "Minigioco coding: Ordina l'algoritmo",
  };
  const instructions: Record<CodingMinigameType, string> = {
    "sequence-builder": "clicca il prossimo blocco che completa una procedura corretta.",
    "state-tracer": "clicca il valore o lo stato prodotto dal codice.",
    "bug-hunt": "clicca la correzione che elimina la causa dell'errore.",
    "binary-bits": "converti tra numero binario e decimale: scegli il valore giusto dei bit.",
    "logic-gate": "valuta AND, OR, NOT e scegli il risultato vero/falso.",
    "loop-output": "simula il ciclo aggiornando la variabile e scegli l'output finale.",
    "conditional-path": "valuta la condizione e scegli quale ramo if/else viene eseguito.",
    "algorithm-order": "tocca i passi nell'ordine giusto per comporre l'algoritmo.",
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
      ...(type === "binary-bits" ? ["matematica.logica", "coding.efficienza"] : []),
      ...(type === "logic-gate" ? ["matematica.logica", "coding.controlloErrore"] : []),
      ...(type === "loop-output" ? ["coding.efficienza", "matematica.logica"] : []),
      ...(type === "conditional-path" ? ["coding.debugging", "matematica.logica"] : []),
      ...(type === "algorithm-order" ? ["coding.decomposizione", "coding.sequenze"] : []),
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
  if (type === "binary-bits") return buildBinaryBitsPrompt(random, difficulty, index);
  if (type === "logic-gate") return buildLogicGatePrompt(random, difficulty, index);
  if (type === "loop-output") return buildLoopOutputPrompt(random, difficulty, index);
  if (type === "conditional-path") return buildConditionalPathPrompt(random, difficulty, index);
  if (type === "algorithm-order") return buildAlgorithmOrderPrompt(random, difficulty, index);
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
        distractorFeedback: [
          `Moltiplica invece di aggiungere: da ${start} servirebbe una somma. «energia * ${delta}» non porta a ${target}.`,
          `Sottrae: allontana dall'obiettivo invece di avvicinarsi. Da ${start} serve «+ ${delta}» per arrivare a ${target}.`,
          `Aggiorni la variabile sbagliata: cambia «obiettivo», ma deve cambiare «energia».`,
        ],
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
        distractorFeedback: [
          `Non è un ciclo: manca «ripeti … volte». Così metti solo un numero accanto all'azione, che resta eseguita una volta.`,
          `È una condizione (se…), non un ciclo: non garantisce ${turns} ripetizioni del controllo.`,
          `Sbagli sia il numero (${turns + 1} invece di ${turns}) sia l'azione ripetuta (salva invece di controlla).`,
        ],
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
        distractorFeedback: [
          `È l'azione del ramo «se» (batteria alta): nel ramo «altrimenti» serve l'azione opposta.`,
          `Stampa un confronto, non risolve il problema: con batteria sotto ${threshold} bisogna agire, cioè ricaricare.`,
          `Reazione eccessiva: la batteria è solo sotto soglia, basta ricaricarla, non spegnere tutto.`,
        ],
        explanation: `Il ramo altrimenti vale quando la batteria non raggiunge ${threshold}: l'azione coerente è ricaricare.`,
        concept: "if / else",
        methodSteps: ["leggi condizione", "identifica ramo falso", "scegli azione complementare"],
      };
    },
  ];
  const item = random.pick(variants)();
  return codingPromptFromItem(random, index, "sequence-builder", item, "Completa la riga con ?");
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
        distractorFeedback: [
          `Compensi un errore con un altro: togli un giro al ciclo invece di rimuovere la riga che sottrae. La causa resta.`,
          `Cambi lo stato iniziale a caso: il ciclo funziona, l'errore non è nel valore di partenza.`,
          `Sposti la stampa, ma la sottrazione dopo il ciclo resta: la causa non è eliminata.`,
        ],
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
        distractorFeedback: [
          `I nomi delle variabili non c'entrano: l'errore è il simbolo di confronto («<» dove serve «>=»).`,
          `Togliere il ramo «altrimenti» non corregge la soglia sbagliata: la condizione resta invertita.`,
          `Avviare sempre ignora la condizione: la scansione deve partire solo con batteria sufficiente.`,
        ],
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
        distractorFeedback: [
          "Cambi un dato, non la logica: il problema è l'operatore OR, che apre con una sola condizione vera.",
          "Aggiunge una stampa ma non cambia quando la porta si apre: l'operatore resta OR.",
          "Togli una condizione necessaria: per aprire servono entrambe (AND), non una sola.",
        ],
        explanation: "Solo se entrambi sono ok richiede AND. OR basterebbe con una sola condizione vera.",
        concept: "logica booleana",
        methodSteps: ["traduci requisito", "controlla operatore", "AND = tutti veri"],
      };
    },
  ];
  const item = random.pick(variants)();
  return codingPromptFromItem(random, index, "bug-hunt", item, "Correzione corretta");
}

function distinctNumberDistractors(random: Random, correct: number, seeds: number[]): string[] {
  const out: string[] = [];
  const push = (value: number): void => {
    if (value >= 0 && value !== correct && !out.includes(String(value))) {
      out.push(String(value));
    }
  };
  seeds.forEach(push);
  let guard = 0;
  while (out.length < 3 && guard < 30) {
    push(correct + random.integer(-5, 5));
    guard += 1;
  }
  return random.shuffle(out).slice(0, 3);
}

function buildBinaryBitsPrompt(random: Random, difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const max = difficulty.level >= 4 ? 31 : 15;
  const value = random.integer(5, max);
  const binary = value.toString(2);
  const toDecimal = random.bool();
  if (toDecimal) {
    const distractors = distinctNumberDistractors(random, value, [value + 1, value - 1, parseInt([...binary].reverse().join(""), 2)]);
    return codingPromptFromItem(random, index, "binary-bits", {
      title: "Dal binario al decimale",
      codeLines: ["# ogni bit vale una potenza di 2", `bits = "${binary}"`, "valore = ?"],
      question: `Quanto vale il numero binario ${binary} in decimale?`,
      correct: String(value),
      distractors,
      explanation: `Da destra i bit valgono 1, 2, 4, 8, 16...: sommi le potenze di 2 dove c'è un 1. Qui ${binary} vale ${value}.`,
      concept: "binario → decimale",
      methodSteps: ["scrivi il valore di ogni bit", "somma dove c'è 1", "confronta col target"],
    }, "Valore decimale");
  }
  const distractors = [
    (value + 1).toString(2),
    (value - 1).toString(2),
    value.toString(2).padStart(binary.length + 1, "1"),
  ].filter((candidate, position, all) => candidate !== binary && all.indexOf(candidate) === position).slice(0, 3);
  while (distractors.length < 3) {
    const candidate = random.integer(1, max).toString(2);
    if (candidate !== binary && !distractors.includes(candidate)) distractors.push(candidate);
  }
  return codingPromptFromItem(random, index, "binary-bits", {
    title: "Dal decimale al binario",
    codeLines: ["# scomponi il numero in potenze di 2", `numero = ${value}`, "bits = ?"],
    question: `Come si scrive ${value} in binario?`,
    correct: binary,
    distractors,
    explanation: `Dividi per 2 e leggi i resti dal basso, oppure togli la potenza di 2 più grande possibile. ${value} = ${binary}.`,
    concept: "decimale → binario",
    methodSteps: ["trova la potenza di 2 più grande", "togli e ripeti", "leggi i bit"],
  }, "Numero binario");
}

function buildLogicGatePrompt(random: Random, _difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const expressions: Array<{ text: string; value: boolean }> = [
    { text: "true AND false", value: false },
    { text: "true OR false", value: true },
    { text: "false OR false", value: false },
    { text: "NOT false", value: true },
    { text: "NOT true", value: false },
    { text: "true AND true", value: true },
    { text: "false AND true", value: false },
    { text: "NOT (true AND false)", value: true },
  ];
  const wantTrue = random.bool();
  const matching = expressions.filter((expression) => expression.value === wantTrue);
  const others = expressions.filter((expression) => expression.value !== wantTrue);
  const correct = random.pick(matching).text;
  const distractors = random.shuffle(others).slice(0, 3).map((expression) => expression.text);
  return codingPromptFromItem(random, index, "logic-gate", {
    title: "Porte logiche",
    codeLines: ["# AND: vero solo se tutti veri", "# OR: vero se almeno uno vero", "# NOT: inverte il valore"],
    question: `Quale espressione vale ${wantTrue ? "TRUE" : "FALSE"}?`,
    correct,
    distractors,
    explanation: "AND è vero solo se entrambi gli ingressi sono veri; OR se almeno uno è vero; NOT inverte il valore di verità.",
    concept: "logica booleana (AND/OR/NOT)",
    methodSteps: ["valuta ogni ingresso", "applica la porta", "scegli vero/falso"],
  }, "Espressione corretta");
}

function buildLoopOutputPrompt(random: Random, difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const n = random.integer(3, difficulty.level >= 4 ? 6 : 4);
  const mode = random.integer(0, 1);
  if (mode === 0) {
    const total = (n * (n + 1)) / 2;
    return codingPromptFromItem(random, index, "loop-output", {
      title: "Somma in un ciclo",
      codeLines: ["total = 0", `per i da 1 a ${n}:`, "    total = total + i", "stampa total"],
      question: "Che cosa stampa il programma?",
      correct: String(total),
      distractors: distinctNumberDistractors(random, total, [total - n, total + n, n]),
      explanation: `total parte da 0 e a ogni giro aggiunge i (1, 2, ... ${n}). La somma 1+...+${n} fa ${total}.`,
      concept: "ciclo + accumulatore",
      methodSteps: ["leggi il range", "aggiorna total a ogni giro", "leggi l'output finale"],
    }, "Output del ciclo");
  }
  const factor = random.integer(2, 3);
  let value = 1;
  for (let i = 0; i < n; i += 1) value *= factor;
  return codingPromptFromItem(random, index, "loop-output", {
    title: "Prodotto in un ciclo",
    codeLines: ["value = 1", `per i da 1 a ${n}:`, `    value = value * ${factor}`, "stampa value"],
    question: "Che cosa stampa il programma?",
    correct: String(value),
    distractors: distinctNumberDistractors(random, value, [value / factor, value * factor, factor * n]),
    explanation: `value parte da 1 e viene moltiplicato per ${factor} per ${n} volte: ${factor}^${n} = ${value}.`,
    concept: "ciclo + variabile",
    methodSteps: ["leggi il valore iniziale", "applica l'operazione a ogni giro", "leggi l'output"],
  }, "Output del ciclo");
}

function buildConditionalPathPrompt(random: Random, _difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const x = random.integer(0, 14);
  const correct = x < 5 ? "LOW" : x < 10 ? "MID" : "HIGH";
  const distractors = ["LOW", "MID", "HIGH", "ZERO"].filter((label) => label !== correct).slice(0, 3);
  return codingPromptFromItem(random, index, "conditional-path", {
    title: "Bivio condizionale",
    codeLines: [`x = ${x}`, "se x < 5: stampa LOW", "oppure se x < 10: stampa MID", "altrimenti: stampa HIGH"],
    question: "Quale parola stampa il programma?",
    correct,
    distractors,
    explanation: `Le condizioni si controllano in ordine: con x = ${x} la prima vera porta a stampare ${correct}.`,
    concept: "if / elif / else",
    methodSteps: ["valuta la prima condizione", "se falsa passa alla successiva", "esegui il primo ramo vero"],
  }, "Ramo eseguito");
}

function buildAlgorithmOrderPrompt(random: Random, difficulty: DifficultyPreset, index: number): CodingMinigamePrompt {
  const recipes = [
    { goal: "spedire un messaggio sicuro", steps: ["scrivi il messaggio", "cifra il messaggio", "invia il messaggio", "conferma la ricezione"] },
    { goal: "trovare il numero più grande in una lista", steps: ["prendi il primo numero come massimo", "scorri gli altri numeri", "se trovi un numero più grande aggiorna il massimo", "stampa il massimo"] },
    { goal: "accendere il robot in sicurezza", steps: ["controlla la batteria", "avvia il sistema", "esegui il test sensori", "abilita il movimento"] },
    { goal: "salvare un file", steps: ["apri il file", "scrivi i dati", "chiudi il file"] },
  ];
  const recipe = difficulty.level >= 4 ? random.pick(recipes) : random.pick(recipes.filter((entry) => entry.steps.length <= 4));
  const steps = recipe.steps;
  const tiles = shuffleCodingTiles(
    random,
    steps.map((step, position) => codingTile(index * 100 + position, step, true, "Passo dell'algoritmo: conta la sua posizione.")),
  );
  return {
    id: `coding-algorithm-${index}`,
    type: "algorithm-order",
    title: "Ordina l'algoritmo",
    codeLines: [`# Obiettivo: ${recipe.goal}`, "# Rimetti i passi nell'ordine giusto", `# Passi: ${random.shuffle([...steps]).length}`],
    question: `In che ordine vanno i passi per ${recipe.goal}?`,
    targetLabel: "Ordine corretto",
    requiredSelectionCount: steps.length,
    tiles,
    solutionLabels: steps,
    explanation: `Un algoritmo è una sequenza ordinata: per ${recipe.goal} ogni passo dipende dal precedente, quindi l'ordine conta.`,
    concept: "pensiero algoritmico",
    methodSteps: ["parti dall'obiettivo", "scegli il primo passo necessario", "concatena i passi in ordine"],
    signature: `algorithm-${recipe.goal}`,
  };
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
    distractorFeedback?: string[];
    explanation: string;
    concept: string;
    methodSteps: string[];
  },
  targetLabel: string,
): CodingMinigamePrompt {
  const tiles = shuffleCodingTiles(random, [
    codingTile(index, item.correct, true, `Corretto: ${item.explanation}`),
    ...item.distractors.map((label, choiceIndex) => codingTile(index + choiceIndex + 1, label, false,
      item.distractorFeedback?.[choiceIndex] ?? `Ripercorri il codice passo-passo: la risposta giusta è «${item.correct}» (${item.concept}). ${item.explanation}`)),
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
  if (type === "binary-bits") return ["sistema binario", "bit", "rappresentazione dei numeri"];
  if (type === "logic-gate") return ["logica booleana", "AND/OR/NOT", "valori di verità"];
  if (type === "loop-output") return ["cicli", "variabili", "accumulatore"];
  if (type === "conditional-path") return ["condizioni", "if/else", "flusso del programma"];
  if (type === "algorithm-order") return ["algoritmo", "sequenza", "decomposizione"];
  return ["debug", "condizioni", "controllo errore"];
}

function codingMinigameMethodSteps(type: CodingMinigameType): string[] {
  if (type === "sequence-builder") return ["obiettivo", "stato attuale", "prossimo blocco"];
  if (type === "state-tracer") return ["tabella variabili", "aggiorna stato", "stampa finale"];
  if (type === "binary-bits") return ["valore dei bit", "somma le potenze di 2", "confronta col target"];
  if (type === "logic-gate") return ["valuta gli ingressi", "applica la porta", "scegli vero/falso"];
  if (type === "loop-output") return ["leggi il range", "aggiorna la variabile a ogni giro", "leggi l'output"];
  if (type === "conditional-path") return ["valuta la condizione", "scegli il ramo", "leggi cosa stampa"];
  if (type === "algorithm-order") return ["obiettivo", "primo passo", "passi in sequenza"];
  return ["risultato atteso", "prima rottura", "correzione minima"];
}

function codingMinigamePurpose(type: CodingMinigameType): string {
  if (type === "sequence-builder") return "Allenare costruzione di algoritmi brevi: scegliere il prossimo blocco coerente con obiettivo e stato.";
  if (type === "state-tracer") return "Allenare esecuzione mentale del codice: aggiornare variabili, cicli e output senza tirare a indovinare.";
  if (type === "binary-bits") return "Capire come i computer rappresentano i numeri in binario: valore dei bit e conversione con le potenze di due.";
  if (type === "logic-gate") return "Capire la logica booleana alla base dei circuiti e del codice: combinare AND, OR e NOT per ottenere vero o falso.";
  if (type === "loop-output") return "Capire come un ciclo ripete istruzioni e come una variabile accumulatore cambia a ogni iterazione fino all'output.";
  if (type === "conditional-path") return "Capire il flusso condizionale: valutare un'espressione e seguire il ramo if oppure else che viene eseguito.";
  if (type === "algorithm-order") return "Allenare il pensiero algoritmico: scomporre un compito in passi e disporli nell'ordine corretto per farlo funzionare.";
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
  optionFeedback?: Record<string, string>,
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
    optionFeedback,
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
    numericOptions(random, answer, [start + add, start * multiplier + add, start + add + multiplier]),
    String(answer),
    `Il codice aggiorna energia in sequenza: prima ${start} + ${add} = ${start + add}, poi ${start + add} * ${multiplier} = ${answer}.`,
    ["sequenza", "tracing", "output"],
    ["leggi dall'alto", "scrivi ogni valore nuovo", "controlla cosa stampa l'ultima riga"],
    {
      [String(start + add)]: `Ti sei fermato troppo presto: ${start} + ${add} = ${start + add}, ma manca l'ultima riga «energia × ${multiplier}».`,
      [String(start * multiplier + add)]: `Ordine sbagliato: il codice fa (${start} + ${add}) × ${multiplier}, non ${start} × ${multiplier} + ${add}. Prima somma, poi moltiplica.`,
      [String(start + add + multiplier)]: `Hai sommato ${multiplier} invece di moltiplicare: l'ultima riga è «× ${multiplier}», non «+ ${multiplier}».`,
    },
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
    numericOptions(random, finalA, [a, c, b]),
    String(finalA),
    `La variabile a viene sovrascritta: all'inizio vale ${a}, ma alla fine diventa c - ${c - finalA}, cioe ${finalA}.`,
    ["variabili", "assegnazione", "stato"],
    ["non usare il primo valore per forza", "aggiorna la tabella delle variabili", "leggi l'ultima assegnazione"],
    {
      [String(a)]: `${a} è il valore iniziale di a, ma a viene sovrascritta dall'ultima riga: usa il valore finale, ${finalA}.`,
      [String(c)]: `${c} è a + b prima della sottrazione: manca l'ultimo passo «a = c - ${c - finalA}».`,
      [String(b)]: `${b} è il valore di b, non di a: segui le assegnazioni di a fino all'ultima.`,
    },
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
    numericOptions(random, answer, [start + delta, times + delta, answer - delta]),
    String(answer),
    `Il blocco aggiunge ${delta} per ${times} volte: aumento totale ${times} * ${delta} = ${times * delta}; ${start} + ${times * delta} = ${answer}.`,
    ["ciclo", "ripetizione", "accumulatore"],
    ["trova cosa si ripete", "calcola effetto di una ripetizione", "moltiplica per il numero di ripetizioni"],
    {
      [String(start + delta)]: `Hai contato una sola ripetizione: il ciclo aggiunge ${delta} per ${times} volte, non una.`,
      [String(times + delta)]: `Hai sommato ${times} + ${delta} invece di moltiplicare: l'aumento è ${times} × ${delta}.`,
      [String(answer - delta)]: `Off-by-one: hai contato una ripetizione in meno. I giri sono esattamente ${times}.`,
    },
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
    {
      "apri porta": `«apri porta» non compare nel codice: le uniche azioni sono «avvia scansione» e «ricarica».`,
      "spegni sensore": `«spegni sensore» non è tra i rami: esegui solo il ramo scelto dalla condizione.`,
      [safe ? "ricarica" : "avvia scansione"]: `È il ramo «${safe ? "altrimenti" : "se"}», ma ${battery} ${safe ? "≥" : "<"} ${threshold}: quindi viene eseguito il ramo «${safe ? "se" : "altrimenti"}» → «${safe ? "avvia scansione" : "ricarica"}».`,
    },
  );
}

function buildBooleanPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedCodingPuzzle {
  // boolean-logic appears from level 5: keep all three conditions genuinely
  // variable so the AND is actually exercised (never reducible to one variable).
  const codeOk = random.bool(0.55);
  const circuitOk = random.bool(0.5);
  const sensorOk = random.bool(0.55);
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
    {
      [answer ? "falso" : "vero"]: `Con AND ${answer ? "servono tutte vere e qui lo sono: risultato «vero»" : "basta un «falso» per rendere tutto falso: qui almeno una è falsa"}.`,
      "solo se codiceOk": `AND richiede TUTTE le condizioni vere, non solo codiceOk: conta anche circuitoOk e sensoreOk.`,
      "errore": `Il codice è valido e produce un valore booleano: non genera errore.`,
    },
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
  const unique: string[] = [];
  for (const item of random.shuffle(distractors)) {
    if (item !== correct && !unique.includes(item) && unique.length < 3) {
      unique.push(item);
    }
  }
  return random.shuffle([correct, ...unique]);
}

/** Numeric multiple choice that always yields four distinct options. */
function numericOptions(random: Random, correct: number, seeds: number[]): string[] {
  return random.shuffle([String(correct), ...distinctNumberDistractors(random, correct, seeds)]);
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
