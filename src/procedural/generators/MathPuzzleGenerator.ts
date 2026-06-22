import { mathTemplates } from "../../data/procedural/mathTemplates";
import type {
  DifficultyPreset,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  MathMinigamePrompt,
  MathMinigameTile,
  MathMinigameType,
} from "../ProceduralTypes";
import type { Random } from "../Random";

export class MathPuzzleGenerator {
  generate(random: Random, difficulty: DifficultyPreset, preferredArchetypes: Array<(typeof mathTemplates)[number]["archetype"]> = []): GeneratedMathPuzzle {
    const eligibleTemplates = mathTemplates.filter((template) => template.minComplexity <= difficulty.mathComplexity);
    const floor = Math.max(1, difficulty.mathComplexity - 2);
    const focusedTemplates = eligibleTemplates.filter((template) => template.minComplexity >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates;
    const preferredPool = preferredArchetypes.length > 0
      ? (eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates).filter((template) => preferredArchetypes.includes(template.archetype))
      : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const base = 4 + difficulty.mathComplexity * 2;
    const a = random.integer(base, base + 8);
    const b = random.integer(3, 6 + difficulty.mathComplexity * 2);
    const c = random.integer(2, 4 + difficulty.mathComplexity);
    const built = template.build(a, b, c);
    const responseRule = "Formato risposta: inserisci un solo numero intero. Se il testo indica una regola di arrotondamento, usa solo quella regola.";
    return {
      id: `math-${template.id}`,
      title: template.title,
      prompt: `Situazione: ${template.narrative}\nRichiesta: ${built.prompt}\n${responseRule}`,
      answer: built.answer,
      hints: built.hints,
      archetype: template.archetype,
      curriculumTags: template.curriculumTags ?? [],
      solutionSteps: built.steps ?? [
        `Identifica i dati: ${a}, ${b}, ${c}.`,
        ...built.hints.map((hint) => hint.replace(/\.$/, "")),
        `Valore finale certificato: ${built.answer}.`,
      ],
      competencies: Array.from(new Set([...(template.competencies ?? ["matematica.calcolo", "matematica.logica"]), "problemSolving"])),
    };
  }

  generateMinigame(
    random: Random,
    difficulty: DifficultyPreset,
    preferredTypes: MathMinigameType[] = [],
  ): GeneratedMathPuzzle {
    const type = preferredTypes.length > 0
      ? random.pick(preferredTypes)
      : random.pick<MathMinigameType>(["target-sum", "factor-hunt", "operation-chain"]);
    const minigame = this.buildMinigame(random.fork(type), difficulty, type);
    const first = minigame.prompts[0];
    const firstSolution = first.solutionLabels.join(" + ");
    return {
      id: `math-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      prompt: [
        `Situazione: una console di calcolo rapido apre micro-portali numerici per 60 secondi.`,
        `Richiesta: ${first.prompt}`,
        `Formato risposta: inserisci un solo numero intero se usi la modalità terminale; nel minigioco seleziona le tessere corrette.`,
      ].join("\n"),
      answer: this.answerProxy(first),
      hints: [
        "Prima leggi il bersaglio: non tutte le tessere utili sono vicine tra loro.",
        "Scarta i distrattori con un controllo rapido: pari/dispari, multiplo, divisore o operazione inversa.",
        "Dopo ogni risposta, chiediti se hai seguito una regola o se hai solo provato.",
      ],
      archetype: type === "target-sum" ? "calcolo-diretto" : type === "factor-hunt" ? "vincolo" : "pre-algebra",
      curriculumTags: type === "target-sum"
        ? ["calcolo mentale", "scomposizione", "somma strategica"]
        : type === "factor-hunt"
          ? ["multipli", "divisori", "vincoli"]
          : ["operazioni inverse", "espressioni", "trasformazioni"],
      solutionSteps: [
        `Leggi la regola del minigioco: ${minigame.instructions}`,
        `Prima schermata: ${first.targetLabel}.`,
        `Tessere corrette iniziali: ${firstSolution}.`,
        first.explanation,
      ],
      competencies: minigame.competencies,
      minigame,
    };
  }

  fallback(random?: Random, difficulty?: DifficultyPreset): GeneratedMathPuzzle {
    const complexity = difficulty?.mathComplexity ?? 1;
    const value = random?.integer(5 + complexity, 12 + complexity * 2) ?? 8;
    const multiplier = random?.integer(2, Math.min(5, 2 + complexity)) ?? 3;
    const subtract = random?.integer(2, Math.min(9, value - 1)) ?? 5;
    const answer = value * multiplier - subtract;
    return {
      id: `math-fallback-${value}-${multiplier}-${subtract}`,
      title: random?.bool() ? "Serratura variabile" : "Codice di riserva",
      prompt: `Situazione: La serratura genera un codice numerico diverso per ogni sessione.\nRichiesta: Moltiplica ${value} per ${multiplier}, poi sottrai ${subtract}.\nFormato risposta: inserisci un solo numero intero.`,
      answer,
      hints: [`Prima calcola ${value} x ${multiplier}.`, `Poi sottrai ${subtract} dal risultato.`],
      archetype: "calcolo-diretto",
      curriculumTags: ["calcolo mentale", "ordine delle operazioni"],
      solutionSteps: [`${value} x ${multiplier} = ${value * multiplier}`, `${value * multiplier} - ${subtract} = ${answer}`],
      competencies: ["matematica.calcolo", "matematica.logica"],
    };
  }

  private buildMinigame(random: Random, difficulty: DifficultyPreset, type: MathMinigameType): GeneratedMathMinigame {
    const promptCount = 18 + difficulty.level;
    const prompts: MathMinigamePrompt[] = [];
    let previousSignature = "";
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniquePrompt(random, difficulty, type, index, previousSignature);
      prompts.push(prompt);
      previousSignature = prompt.signature;
    }
    const titles: Record<MathMinigameType, string> = {
      "target-sum": "Minigioco: Somma al bersaglio",
      "factor-hunt": "Minigioco: Caccia a multipli e divisori",
      "operation-chain": "Minigioco: Rotte delle operazioni",
    };
    const instructions: Record<MathMinigameType, string> = {
      "target-sum": "seleziona solo le tessere che raggiungono il bersaglio esatto.",
      "factor-hunt": "seleziona tutti e soli i numeri che rispettano il vincolo.",
      "operation-chain": "scegli la trasformazione che porta dall'ingresso all'uscita.",
    };
    return {
      type,
      title: titles[type],
      durationMs: 60_000,
      instructions: instructions[type],
      scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. In missione l'errore chiude il tentativo.",
      prompts,
      competencies: Array.from(new Set([
        "matematica.calcolo",
        "matematica.logica",
        "problemSolving",
        ...(type === "factor-hunt" ? ["matematica.multipliDivisori"] : []),
        ...(type === "operation-chain" ? ["matematica.espressioni", "matematica.controlloErrore"] : []),
      ])),
    };
  }

  private uniquePrompt(
    random: Random,
    difficulty: DifficultyPreset,
    type: MathMinigameType,
    index: number,
    previousSignature: string,
  ): MathMinigamePrompt {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const prompt = this.buildPrompt(random, difficulty, type, index + attempt);
      if (prompt.signature !== previousSignature) {
        return prompt;
      }
    }
    return this.buildPrompt(random, difficulty, type, index + 99);
  }

  private buildPrompt(random: Random, difficulty: DifficultyPreset, type: MathMinigameType, index: number): MathMinigamePrompt {
    if (type === "target-sum") {
      return this.buildTargetSumPrompt(random, difficulty, index);
    }
    if (type === "factor-hunt") {
      return this.buildFactorHuntPrompt(random, difficulty, index);
    }
    return this.buildOperationChainPrompt(random, difficulty, index);
  }

  private buildTargetSumPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const required = difficulty.level >= 5 ? 3 : 2;
    const min = 4 + difficulty.level;
    const max = 13 + difficulty.level * 4;
    for (let attempt = 0; attempt < 24; attempt += 1) {
      const correctValues = this.uniqueNumbers(random, required, min, max);
      const target = correctValues.reduce((sum, value) => sum + value, 0);
      const distractors = this.uniqueNumbers(random, 7 - required, Math.max(2, min - 3), max + 8)
        .filter((value) => !correctValues.includes(value) && value !== target);
      const allValues = [...correctValues, ...distractors].slice(0, 7);
      if (this.hasAlternativeSum(allValues, target, required, correctValues)) {
        continue;
      }
      const tiles = this.shuffleTiles(random, allValues.map((value, tileIndex) => ({
        id: `sum-${index}-${tileIndex}`,
        label: `${value}`,
        value,
        isCorrect: correctValues.includes(value),
        feedback: correctValues.includes(value)
          ? `${value} appartiene alla somma esatta.`
          : `${value} porta fuori bersaglio.`,
      })));
      return {
        id: `target-sum-${index}`,
        type: "target-sum",
        prompt: `Carica il nucleo a ${target}: scegli ${required} tessere la cui somma sia esatta.`,
        targetLabel: `Bersaglio ${target}`,
        requiredSelectionCount: required,
        tiles,
        solutionLabels: correctValues.map(String),
        explanation: `${correctValues.join(" + ")} = ${target}. I distrattori sono vicini, ma cambiano la somma finale.`,
        concept: required === 2 ? "scomposizione di una somma" : "somma a tre addendi con controllo intermedio",
        signature: `sum-${target}-${correctValues.join("-")}`,
      };
    }
    return this.simpleTargetSumFallback(index);
  }

  private buildFactorHuntPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const useMultiples = random.bool(0.58);
    if (useMultiples) {
      const base = random.pick([3, 4, 5, 6, 7, 8, 9]);
      const correctValues = this.uniqueNumbers(random, 3 + (difficulty.level >= 6 ? 1 : 0), 2, 8)
        .map((factor) => factor * base);
      const distractors = this.uniqueNumbers(random, 7 - correctValues.length, base + 1, base * 9 + 5)
        .filter((value) => value % base !== 0 && !correctValues.includes(value));
      const values = [...correctValues, ...distractors].slice(0, 7);
      const tiles = this.shuffleTiles(random, values.map((value, tileIndex) => ({
        id: `multiple-${index}-${tileIndex}`,
        label: `${value}`,
        value,
        isCorrect: value % base === 0,
        feedback: value % base === 0 ? `${value} è divisibile per ${base}.` : `${value} lascia resto nella divisione per ${base}.`,
      })));
      return {
        id: `factor-hunt-m-${index}`,
        type: "factor-hunt",
        prompt: `Il filtro accetta solo multipli di ${base}. Seleziona tutti quelli validi.`,
        targetLabel: `Multipli di ${base}`,
        requiredSelectionCount: tiles.filter((tile) => tile.isCorrect).length,
        tiles,
        solutionLabels: values.filter((value) => value % base === 0).map(String),
        explanation: `Un multiplo di ${base} si ottiene moltiplicando ${base} per un numero intero.`,
        concept: "multipli e divisibilità",
        signature: `multiple-${base}-${values.join("-")}`,
      };
    }

    const target = random.pick([18, 24, 30, 36, 42, 48, 60, 72]);
    const divisorPool = Array.from({ length: target }, (_, i) => i + 1).filter((value) => target % value === 0 && value > 1 && value < target);
    const correctValues = random.shuffle(divisorPool).slice(0, difficulty.level >= 6 ? 4 : 3);
    const distractors = this.uniqueNumbers(random, 7 - correctValues.length, 2, Math.min(30, target - 1))
      .filter((value) => target % value !== 0 && !correctValues.includes(value));
    const values = [...correctValues, ...distractors].slice(0, 7);
    const tiles = this.shuffleTiles(random, values.map((value, tileIndex) => ({
      id: `divisor-${index}-${tileIndex}`,
      label: `${value}`,
      value,
      isCorrect: target % value === 0,
      feedback: target % value === 0 ? `${value} divide ${target} senza resto.` : `${value} non divide ${target} in parti intere.`,
    })));
    return {
      id: `factor-hunt-d-${index}`,
      type: "factor-hunt",
      prompt: `Il divisore centrale è ${target}. Seleziona tutti i divisori mostrati.`,
      targetLabel: `Divisori di ${target}`,
      requiredSelectionCount: tiles.filter((tile) => tile.isCorrect).length,
      tiles,
      solutionLabels: values.filter((value) => target % value === 0).map(String),
      explanation: `Un divisore entra in ${target} un numero intero di volte: nessun resto.`,
      concept: "divisori e controllo del resto",
      signature: `divisor-${target}-${values.join("-")}`,
    };
  }

  private buildOperationChainPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const twoSteps = difficulty.level >= 4;
    const start = random.integer(3 + difficulty.level, 14 + difficulty.level * 3);
    const operations = [
      { label: "+ 6", apply: (value: number) => value + 6 },
      { label: "- 4", apply: (value: number) => value - 4 },
      { label: "x 2", apply: (value: number) => value * 2 },
      { label: "x 3", apply: (value: number) => value * 3 },
      { label: ": 2", apply: (value: number) => Math.floor(value / 2), valid: (value: number) => value % 2 === 0 },
      { label: ": 3", apply: (value: number) => Math.floor(value / 3), valid: (value: number) => value % 3 === 0 },
    ];
    const validFirst = operations.filter((operation) => !operation.valid || operation.valid(start));
    const first = random.pick(validFirst);
    const mid = first.apply(start);
    const validSecond = operations.filter((operation) => !operation.valid || operation.valid(mid));
    const second = twoSteps ? random.pick(validSecond) : undefined;
    const target = second ? second.apply(mid) : mid;
    const correctLabel = second ? `${first.label} poi ${second.label}` : first.label;
    const distractors = random.shuffle(operations)
      .filter((operation) => operation.label !== first.label)
      .map((operation) => {
        const label = twoSteps
          ? `${operation.label} poi ${random.pick(operations).label}`
          : operation.label;
        return label;
      })
      .filter((label) => label !== correctLabel)
      .slice(0, 5);
    const labels = random.shuffle([correctLabel, ...distractors]).slice(0, 6);
    const tiles = labels.map((label, tileIndex) => ({
      id: `operation-${index}-${tileIndex}`,
      label,
      isCorrect: label === correctLabel,
      feedback: label === correctLabel
        ? `Da ${start} arrivi a ${target}.`
        : "Questa rotta cambia troppo o troppo poco il valore.",
    }));
    return {
      id: `operation-chain-${index}`,
      type: "operation-chain",
      prompt: `Ingresso ${start}, uscita richiesta ${target}. Quale rotta di operazioni certifica il passaggio?`,
      targetLabel: `${start} -> ${target}`,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [correctLabel],
      explanation: second
        ? `${start} ${first.label} = ${mid}; poi ${mid} ${second.label} = ${target}.`
        : `${start} ${first.label} = ${target}.`,
      concept: twoSteps ? "due trasformazioni ordinate" : "trasformazione singola",
      signature: `op-${start}-${correctLabel}-${target}`,
    };
  }

  private shuffleTiles(random: Random, tiles: MathMinigameTile[]): MathMinigameTile[] {
    return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
  }

  private uniqueNumbers(random: Random, count: number, min: number, max: number): number[] {
    const values = new Set<number>();
    let guard = 0;
    while (values.size < count && guard < 80) {
      values.add(random.integer(min, max));
      guard += 1;
    }
    return [...values];
  }

  private hasAlternativeSum(values: number[], target: number, count: number, intended: number[]): boolean {
    const intendedKey = [...intended].sort((a, b) => a - b).join(",");
    const scan = (start: number, chosen: number[]): boolean => {
      if (chosen.length === count) {
        const sum = chosen.reduce((total, value) => total + value, 0);
        const key = [...chosen].sort((a, b) => a - b).join(",");
        return sum === target && key !== intendedKey;
      }
      for (let index = start; index < values.length; index += 1) {
        if (scan(index + 1, [...chosen, values[index]])) {
          return true;
        }
      }
      return false;
    };
    return scan(0, []);
  }

  private simpleTargetSumFallback(index: number): MathMinigamePrompt {
    const tiles: MathMinigameTile[] = [
      { id: `fallback-${index}-1`, label: "8", value: 8, isCorrect: true, feedback: "Parte della somma." },
      { id: `fallback-${index}-2`, label: "11", value: 11, isCorrect: true, feedback: "Parte della somma." },
      { id: `fallback-${index}-3`, label: "9", value: 9, isCorrect: false, feedback: "Porta fuori bersaglio." },
      { id: `fallback-${index}-4`, label: "13", value: 13, isCorrect: false, feedback: "Porta fuori bersaglio." },
    ];
    return {
      id: `target-sum-fallback-${index}`,
      type: "target-sum",
      prompt: "Carica il nucleo a 19: scegli 2 tessere la cui somma sia esatta.",
      targetLabel: "Bersaglio 19",
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: ["8", "11"],
      explanation: "8 + 11 = 19.",
      concept: "scomposizione di una somma",
      signature: `sum-fallback-${index}`,
    };
  }

  private answerProxy(prompt: MathMinigamePrompt): number {
    if (prompt.type === "operation-chain") {
      const parts = prompt.targetLabel.split("->");
      const target = Number(parts[parts.length - 1]?.trim());
      return Number.isFinite(target) ? Math.max(0, Math.min(9999, target)) : 0;
    }
    const total = prompt.tiles.filter((tile) => tile.isCorrect).reduce((sum, tile) => sum + (tile.value ?? 0), 0);
    return Math.max(0, Math.min(9999, total));
  }
}
