import { mathTemplates } from "../../data/procedural/mathTemplates";
import type {
  DifficultyPreset,
  EquationLabStage,
  GeneratedGraphWorkshop,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  GraphReadingStep,
  MathGeometryVisual,
  MathMinigamePrompt,
  MathMinigameTile,
  MathMinigameType,
} from "../ProceduralTypes";
import type { Random } from "../Random";

function clampNumber(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

type OperationDefinition = {
  label: string;
  apply: (value: number) => number;
  valid?: (value: number) => boolean;
};

type ChoiceCandidate = {
  label: string;
  value: number;
  feedback: string;
};

function gcd(left: number, right: number): number {
  let a = Math.abs(left);
  let b = Math.abs(right);
  while (b !== 0) {
    const next = a % b;
    a = b;
    b = next;
  }
  return a || 1;
}

export class MathPuzzleGenerator {
  generate(random: Random, difficulty: DifficultyPreset, preferredArchetypes: Array<(typeof mathTemplates)[number]["archetype"]> = []): GeneratedMathPuzzle {
    const equationRequested = preferredArchetypes.includes("equazione-secondo-grado")
      || preferredArchetypes.includes("equazione-primo-grado");
    const graphRequested = preferredArchetypes.includes("grafici-cartesiani")
      || preferredArchetypes.includes("funzione-lineare")
      || preferredArchetypes.includes("coordinate");
    if (
      difficulty.mathComplexity >= 3
      && (
        (preferredArchetypes.includes("grafici-cartesiani") && random.bool(0.82))
        || (graphRequested && random.bool(difficulty.mathComplexity >= 6 ? 0.48 : 0.32))
        || (preferredArchetypes.length === 0 && random.bool(difficulty.mathComplexity >= 6 ? 0.26 : 0.12))
      )
    ) {
      return this.generateGraphWorkshop(random.fork("graph-workshop"), difficulty);
    }
    if (
      difficulty.mathComplexity >= 4
      && (
        (equationRequested && random.bool(difficulty.mathComplexity >= 6 ? 0.65 : 0.42))
        || (preferredArchetypes.length === 0 && random.bool(difficulty.mathComplexity >= 6 ? 0.24 : 0.16))
      )
    ) {
      return this.generateEquationLab(random.fork("equation-lab"), difficulty);
    }
    // Levels grade DIFFICULTY (numbers scale via a,b,c), not exercise type. Keep
    // the FULL pool of eligible archetypes available at every level so variety
    // never collapses. A previous "floor" restricted each level to the hardest
    // few templates, which made every run feel like the same sequence.
    const eligibleTemplates = mathTemplates.filter((template) => template.minComplexity <= difficulty.mathComplexity);
    const pool = eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates;
    const preferredPool = preferredArchetypes.length > 0
      ? (eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates).filter((template) => preferredArchetypes.includes(template.archetype))
      : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const base = 4 + difficulty.mathComplexity * 2;
    const a = random.integer(base, base + 8);
    const b = random.integer(3, 6 + difficulty.mathComplexity * 2);
    const c = random.integer(2, 4 + difficulty.mathComplexity);
    const built = template.build(a, b, c);
    const responseRule = "Formato risposta: inserisci un solo numero intero. Se una regola di approssimazione è scritta nella richiesta, applica solo quella.";
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

  generateEquationLab(random: Random, difficulty: DifficultyPreset): GeneratedMathPuzzle {
    const quadratic = difficulty.mathComplexity >= 6 && random.bool(difficulty.mathComplexity >= 8 ? 0.76 : 0.58);
    return quadratic
      ? this.buildQuadraticEquationLab(random, difficulty)
      : this.buildLinearEquationLab(random, difficulty);
  }

  generateGraphWorkshop(random: Random, difficulty: DifficultyPreset): GeneratedMathPuzzle {
    const modes = difficulty.mathComplexity <= 2
      ? ["beacon-line"] as const
      : difficulty.mathComplexity <= 4
      ? ["beacon-line", "vertex-shift"] as const
      : difficulty.mathComplexity <= 6
        ? ["beacon-line", "vertex-shift", "root-gates", "curve-match"] as const
        : ["vertex-shift", "root-gates", "curve-match", "beacon-line"] as const;
    const mode = random.pick(modes);
    const workshop = mode === "beacon-line"
      ? this.buildBeaconLineWorkshop(random, difficulty)
      : mode === "vertex-shift"
        ? this.buildVertexWorkshop(random, difficulty)
        : mode === "root-gates"
          ? this.buildRootGateWorkshop(random, difficulty)
          : this.buildCurveMatchWorkshop(random, difficulty);
    const modeCopy = {
      "beacon-line": {
        title: "Linea tra i beacon",
        narrative: "Due trasmettitori devono essere attraversati dalla stessa retta.",
      },
      "vertex-shift": {
        title: "Teletrasporto del vertice",
        narrative: "Una parabola deve spostare il proprio vertice sul portale indicato.",
      },
      "root-gates": {
        title: "Porte delle radici",
        narrative: "La curva deve attraversare due serrature poste sull'asse x.",
      },
      "curve-match": {
        title: "Sovrapponi la curva",
        narrative: "Una traccia fantasma mostra la funzione che il proiettore deve ricostruire.",
      },
    }[workshop.mode];
    return {
      id: `math-graph-${workshop.mode}-${workshop.parameters.map((parameter) => parameter.target).join("-")}`,
      title: `Officina dei Grafici · ${modeCopy.title}`,
      prompt: [
        `Situazione: ${modeCopy.narrative}`,
        `Richiesta: ${workshop.objective}`,
        workshop.mode === "beacon-line"
          ? "Formato risposta: completa il taccuino di lettura, disegna la retta dall'equazione trovata e certifica sul piano cartesiano."
          : "Formato risposta: modifica i parametri con i controlli grafici, osserva la curva in tempo reale e certifica quando soddisfa tutti i vincoli.",
      ].join("\n"),
      answer: 0,
      hints: this.graphWorkshopHints(workshop),
      archetype: "grafici-cartesiani",
      curriculumTags: workshop.functionKind === "linear"
        ? ["piano cartesiano", "retta", "coefficiente angolare", "intercetta"]
        : ["piano cartesiano", "parabola", "vertice", "radici", "trasformazioni"],
      solutionSteps: [
        workshop.principle,
        ...workshop.parameters.map((parameter) => `${parameter.label} = ${parameter.target}: ${parameter.meaning}`),
        workshop.successExplanation,
      ],
      competencies: [
        "matematica.grafici",
        "matematica.funzioni",
        "matematica.coordinate",
        "matematica.algebra",
        "problemSolving",
      ],
      graphWorkshop: workshop,
    };
  }

  generateMinigame(
    random: Random,
    difficulty: DifficultyPreset,
    preferredTypes: MathMinigameType[] = [],
  ): GeneratedMathPuzzle {
    const minigameTypes: MathMinigameType[] = [
      "target-sum",
      "factor-hunt",
      "operation-chain",
      "number-sequence",
      "expression-build",
      "fraction-lab",
      "ratio-proportion",
      "geometry-measure",
      "data-probability",
    ];
    const type = preferredTypes.length > 0
      ? random.pick(preferredTypes)
      : random.pick<MathMinigameType>(minigameTypes);
    const minigame = this.buildMinigame(random.fork(type), difficulty, type);
    const first = minigame.prompts[0];
    const firstSolution = first.solutionLabels.join(" + ");
    const archetypes: Record<MathMinigameType, GeneratedMathPuzzle["archetype"]> = {
      "target-sum": "calcolo-diretto",
      "factor-hunt": "vincolo",
      "operation-chain": "pre-algebra",
      "number-sequence": "sequenza",
      "expression-build": "pre-algebra",
      "fraction-lab": "frazioni",
      "ratio-proportion": "proporzione",
      "geometry-measure": "geometria",
      "data-probability": "statistica",
    };
    const curriculumTags: Record<MathMinigameType, string[]> = {
      "target-sum": ["calcolo mentale", "scomposizione", "somma strategica"],
      "factor-hunt": ["multipli", "divisori", "vincoli"],
      "operation-chain": ["operazioni inverse", "espressioni", "trasformazioni"],
      "number-sequence": ["sequenze", "regolarita", "pre-algebra"],
      "expression-build": ["ordine delle operazioni", "espressioni", "priorita"],
      "fraction-lab": ["frazioni", "percentuali", "equivalenze"],
      "ratio-proportion": ["proporzioni", "rapporto unitario", "scale"],
      "geometry-measure": ["perimetro", "area", "volume", "teorema di Pitagora"],
      "data-probability": ["media", "mediana", "moda", "probabilita"],
    };
    return {
      id: `math-mini-${type}-${random.integer(1000, 9999)}`,
      title: minigame.title,
      prompt: [
        `Situazione: una console di calcolo rapido apre micro-portali numerici per 120 secondi.`,
        `Richiesta: ${first.prompt}`,
        `Formato risposta: inserisci un solo numero intero se usi la modalità terminale; nel minigioco seleziona le tessere corrette.`,
      ].join("\n"),
      answer: this.answerProxy(first),
      hints: [
        "Prima leggi il bersaglio: non tutte le tessere utili sono vicine tra loro.",
        "Scarta i distrattori con un controllo rapido: pari/dispari, multiplo, divisore o operazione inversa.",
        "Dopo ogni risposta, chiediti se hai seguito una regola o se hai solo provato.",
      ],
      archetype: archetypes[type],
      curriculumTags: curriculumTags[type],
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
    const usedSignatures = new Set<string>();
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniquePrompt(random, difficulty, type, index, usedSignatures);
      prompts.push(prompt);
      usedSignatures.add(prompt.signature);
    }
    const titles: Record<MathMinigameType, string> = {
      "target-sum": "Minigioco: Somma al bersaglio",
      "factor-hunt": "Minigioco: Caccia a multipli e divisori",
      "operation-chain": "Minigioco: Rotte delle operazioni",
      "number-sequence": "Minigioco: Indovina la sequenza",
      "expression-build": "Minigioco: Colpisci il bersaglio",
      "fraction-lab": "Minigioco: Laboratorio frazioni",
      "ratio-proportion": "Minigioco: Proporzioni in missione",
      "geometry-measure": "Minigioco: Misure sul campo",
      "data-probability": "Minigioco: Dati sotto pressione",
    };
    const instructions: Record<MathMinigameType, string> = {
      "target-sum": "seleziona solo le tessere che raggiungono il bersaglio esatto.",
      "factor-hunt": "seleziona tutti e soli i numeri che rispettano il vincolo.",
      "operation-chain": "scegli la trasformazione che porta dall'ingresso all'uscita.",
      "number-sequence": "scopri la regola della sequenza e scegli il numero che continua.",
      "expression-build": "inserisci gli operatori tra i numeri per ottenere il bersaglio.",
      "fraction-lab": "leggi frazione o percentuale e scegli il valore coerente con la situazione.",
      "ratio-proportion": "riduci al rapporto unitario o imposta la proporzione prima di scegliere.",
      "geometry-measure": "riconosci la misura richiesta e applica la formula adatta.",
      "data-probability": "leggi i dati, scegli l'indice corretto o la probabilita richiesta.",
    };
    return {
      type,
      title: titles[type],
      durationMs: 120_000,
      instructions: instructions[type],
      scoringRule: "120 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. In missione l'errore chiude il tentativo.",
      prompts,
      competencies: Array.from(new Set([
        "matematica.calcolo",
        "matematica.logica",
        "problemSolving",
        ...(type === "factor-hunt" ? ["matematica.multipliDivisori"] : []),
        ...(type === "operation-chain" ? ["matematica.espressioni", "matematica.controlloErrore"] : []),
        ...(type === "number-sequence" ? ["matematica.logica"] : []),
        ...(type === "expression-build" ? ["matematica.espressioni", "matematica.operazioni"] : []),
        ...(type === "fraction-lab" ? ["matematica.frazioni", "matematica.percentuali", "matematica.equivalenze"] : []),
        ...(type === "ratio-proportion" ? ["matematica.proporzioni", "matematica.rapporti", "matematica.unitaMisura"] : []),
        ...(type === "geometry-measure" ? ["matematica.geometria", "matematica.misure", "matematica.pitagora"] : []),
        ...(type === "data-probability" ? ["matematica.statistica", "matematica.probabilita", "matematica.letturaDati"] : []),
      ])),
    };
  }

  private buildLinearEquationLab(random: Random, difficulty: DifficultyPreset): GeneratedMathPuzzle {
    const root = random.integer(2, 7 + difficulty.mathComplexity);
    const coefficient = random.integer(2, Math.min(6, 2 + difficulty.mathComplexity));
    const addend = random.integer(2, 10 + difficulty.mathComplexity);
    const total = coefficient * root + addend;
    const equation = `${coefficient}x + ${addend} = ${total}`;
    const afterSubtract = total - addend;
    const wrongSubtract = total + addend;
    const solutionValues = new Set<number>([root, afterSubtract, wrongSubtract, root + coefficient]);
    let distractorOffset = 1;
    while (solutionValues.size < 4) {
      solutionValues.add(root + coefficient * distractorOffset + 1);
      distractorOffset += 1;
    }
    const solutionOptions = [...solutionValues].slice(0, 4).map(String);
    const stages: EquationLabStage[] = [
      {
        id: "linear-balance",
        title: "1 · Conserva l'equilibrio",
        prompt: `Per eliminare +${addend} dal lato sinistro, quale operazione mantiene equivalenti i due membri?`,
        options: random.shuffle([
          `Sottrarre ${addend} a entrambi i membri`,
          `Sottrarre ${addend} solo a sinistra`,
          `Dividere subito tutto per ${addend}`,
          `Aggiungere ${addend} a entrambi i membri`,
        ]),
        correctOption: `Sottrarre ${addend} a entrambi i membri`,
        explanation: `La stessa operazione sui due membri conserva l'uguaglianza: ${equation} diventa ${coefficient}x = ${afterSubtract}.`,
        visual: "balance",
      },
      {
        id: "linear-inverse",
        title: "2 · Isola l'incognita",
        prompt: `Dopo il primo passaggio hai ${coefficient}x = ${afterSubtract}. Qual è il passaggio corretto?`,
        options: random.shuffle([
          `Dividere entrambi i membri per ${coefficient}`,
          `Sottrarre ${coefficient} da entrambi i membri`,
          `Moltiplicare entrambi i membri per ${coefficient}`,
          `Dividere solo il membro sinistro per ${coefficient}`,
        ]),
        correctOption: `Dividere entrambi i membri per ${coefficient}`,
        explanation: `La moltiplicazione per ${coefficient} si annulla dividendo entrambi i membri per ${coefficient}: x = ${root}.`,
        visual: "inverse-steps",
      },
      {
        id: "linear-solution",
        title: "3 · Calcola la soluzione",
        prompt: `Quale valore risolve ${equation}?`,
        options: random.shuffle(solutionOptions),
        correctOption: `${root}`,
        explanation: `${total} - ${addend} = ${afterSubtract}; ${afterSubtract} : ${coefficient} = ${root}.`,
        visual: "inverse-steps",
      },
      {
        id: "linear-check",
        title: "4 · Verifica per sostituzione",
        prompt: `Quale sostituzione dimostra che x = ${root} è corretta?`,
        options: random.shuffle([
          `${coefficient} · ${root} + ${addend} = ${total}`,
          `${coefficient} + ${root} · ${addend} = ${total}`,
          `${coefficient} · ${root} - ${addend} = ${total}`,
          `${root} + ${addend} = ${total}`,
        ]),
        correctOption: `${coefficient} · ${root} + ${addend} = ${total}`,
        explanation: `Sostituendo x con ${root}, il primo membro vale ${coefficient * root} + ${addend} = ${total}, uguale al secondo.`,
        visual: "substitution",
      },
    ];
    return {
      id: `math-equation-lab-linear-${coefficient}-${addend}-${root}`,
      title: "Laboratorio equazioni · Bilancia lineare",
      prompt: `Situazione: una bilancia algebrica mantiene uguali i due membri solo se ogni trasformazione è applicata da entrambe le parti.\nRichiesta: risolvi e verifica ${equation} attraverso quattro decisioni guidate.\nFormato risposta: scegli una tessera a ogni passaggio; la soluzione finale è un numero intero.`,
      answer: root,
      hints: [
        "Un'equazione è una bilancia: ciò che fai a sinistra va fatto anche a destra.",
        `Annulla prima il termine +${addend} usando l'operazione inversa.`,
        `Quando resta ${coefficient}x, dividi entrambi i membri per ${coefficient}.`,
      ],
      archetype: "equazione-primo-grado",
      curriculumTags: ["equazioni di primo grado", "principi di equivalenza", "operazioni inverse", "verifica"],
      solutionSteps: [
        equation,
        `${coefficient}x = ${total} - ${addend} = ${afterSubtract}`,
        `x = ${afterSubtract} : ${coefficient} = ${root}`,
        `verifica: ${coefficient} · ${root} + ${addend} = ${total}`,
      ],
      competencies: ["matematica.equazioni", "matematica.algebra", "matematica.controlloErrore", "problemSolving"],
      equationLab: {
        degree: 1,
        equation,
        coefficients: { a: coefficient, b: addend - total, c: 0 },
        roots: [root],
        principle: "I principi di equivalenza permettono di trasformare un'equazione senza cambiarne le soluzioni.",
        verification: `${coefficient} · ${root} + ${addend} = ${total}`,
        stages,
      },
    };
  }

  private buildBeaconLineWorkshop(random: Random, difficulty: DifficultyPreset): GeneratedGraphWorkshop {
    const beginner = difficulty.mathComplexity <= 2;
    const m = beginner ? random.pick([-2, -1, 1, 2]) : random.pick([-3, -2, -1, 1, 2, 3]);
    const q = beginner ? random.integer(-2, 2) : random.integer(-4, 4);
    const firstX = beginner ? 0 : random.pick([-3, -2, -1]);
    const secondX = beginner ? random.pick([1, 2]) : random.pick([1, 2, 3]);
    const slopeLimit = beginner ? 2 : 3;
    const interceptLimit = beginner ? 3 : 5;
    const initialM = this.shiftedInitial(random, m, -slopeLimit, slopeLimit, m === 0 ? 1 : 0);
    const initialQ = this.shiftedInitial(random, q, -interceptLimit, interceptLimit);
    const targetPoints = [
      { x: firstX, y: m * firstX + q, label: "A" },
      { x: secondX, y: m * secondX + q, label: "B" },
    ];
    return {
      mode: "beacon-line",
      functionKind: "linear",
      objective: "Leggi i beacon, ricava q e m, poi disegna la retta corrispondente.",
      targetFormula: this.linearFormula(m, q),
      principle: "In y = mx + q, m controlla inclinazione e verso; q è il punto in cui la retta incontra l'asse y.",
      parameters: [
        { key: "m", label: "m", meaning: "pendenza: variazione verticale per ogni passo orizzontale", min: -slopeLimit, max: slopeLimit, step: 1, target: m, initial: initialM },
        { key: "q", label: "q", meaning: "intercetta sull'asse y", min: -interceptLimit, max: interceptLimit, step: 1, target: q, initial: initialQ },
      ],
      readingSteps: this.beaconLineReadingSteps(random, targetPoints[0], targetPoints[1], m, q),
      targetPoints,
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-14, 14],
      successExplanation: `La retta ${this.linearFormula(m, q)} attraversa entrambi i punti; la variazione tra A e B conferma m = ${m}.`,
    };
  }

  private beaconLineReadingSteps(
    random: Random,
    first: { x: number; y: number; label: string },
    second: { x: number; y: number; label: string },
    m: number,
    q: number,
  ): GraphReadingStep[] {
    const dx = second.x - first.x;
    const dy = second.y - first.y;
    const yAxisBeacon = [first, second].find((point) => point.x === 0);
    const qStep: GraphReadingStep = yAxisBeacon
      ? this.graphReadingStep(random, {
        key: "q",
        label: "1 · Leggi q",
        prompt: `Quale valore di q leggi dal beacon ${yAxisBeacon.label} sull'asse y?`,
        correctValue: q,
        min: -6,
        max: 6,
        explanation: `${yAxisBeacon.label} ha x = 0, quindi sta sull'asse y: in y = mx + q quel punto mostra q = ${q}.`,
        parameterKey: "q",
      })
      : this.graphReadingStep(random, {
        key: "q",
        label: "4 · Ricava q",
        prompt: `Usa ${first.label}: q = y - m*x. Quanto vale q?`,
        correctValue: q,
        min: -8,
        max: 8,
        explanation: `Con ${first.label}(${first.x}, ${first.y}) e m = ${m}: q = ${first.y} - (${m}*${first.x}) = ${q}.`,
        parameterKey: "q",
      });
    const slopeSteps = [
      this.graphReadingStep(random, {
        key: "dx",
        label: yAxisBeacon ? "2 · Calcola dx" : "1 · Calcola dx",
        prompt: `Da ${first.label} a ${second.label}, di quanto avanza x?`,
        correctValue: dx,
        min: 1,
        max: 8,
        explanation: `dx = xB - xA = ${second.x} - (${first.x}) = ${dx}.`,
      }),
      this.graphReadingStep(random, {
        key: "dy",
        label: yAxisBeacon ? "3 · Calcola dy" : "2 · Calcola dy",
        prompt: `Da ${first.label} a ${second.label}, di quanto cambia y?`,
        correctValue: dy,
        min: -18,
        max: 18,
        explanation: `dy = yB - yA = ${second.y} - (${first.y}) = ${dy}.`,
      }),
      this.graphReadingStep(random, {
        key: "m",
        label: yAxisBeacon ? "4 · Calcola m" : "3 · Calcola m",
        prompt: "La pendenza e m = dy / dx. Quanto vale m?",
        correctValue: m,
        min: -4,
        max: 4,
        explanation: `m = dy / dx = ${dy} / ${dx} = ${m}. Questo numero dice quanto sale o scende y per ogni passo in x.`,
        parameterKey: "m",
      }),
    ];
    return yAxisBeacon ? [qStep, ...slopeSteps] : [...slopeSteps, qStep];
  }

  private graphReadingStep(
    random: Random,
    config: Omit<GraphReadingStep, "options"> & { min: number; max: number },
  ): GraphReadingStep {
    const { min, max, ...step } = config;
    return {
      ...step,
      options: this.graphReadingOptions(random, step.correctValue, min, max),
    };
  }

  private graphReadingOptions(random: Random, correct: number, min: number, max: number): number[] {
    const values = new Set<number>([correct]);
    [correct - 1, correct + 1, -correct, correct + 2, correct - 2].forEach((value) => {
      if (value >= min && value <= max && value !== correct) values.add(value);
    });
    let guard = 0;
    while (values.size < 4 && guard < 40) {
      const candidate = random.integer(min, max);
      if (candidate !== correct) values.add(candidate);
      guard += 1;
    }
    for (let candidate = min; values.size < 4 && candidate <= max; candidate += 1) {
      if (candidate !== correct) values.add(candidate);
    }
    return random.shuffle([...values].slice(0, 4));
  }

  private buildVertexWorkshop(random: Random, difficulty: DifficultyPreset): GeneratedGraphWorkshop {
    const a = difficulty.mathComplexity >= 6 ? random.pick([-2, -1, 1, 2]) : random.pick([-1, 1]);
    const h = random.integer(-3, 3);
    const k = random.integer(-4, 4);
    return {
      mode: "vertex-shift",
      functionKind: "quadratic",
      objective: `Porta il vertice sul portale V(${h}, ${k}) e fai attraversare la curva anche i due anelli guida simmetrici.`,
      targetFormula: this.quadraticVertexFormula(a, h, k),
      principle: "Nella forma y = a(x − h)² + k, il vertice è V(h,k); il segno di a decide se la parabola apre verso l'alto o verso il basso.",
      parameters: this.quadraticParameters(random, a, h, k, difficulty),
      targetPoints: [
        { x: h, y: k, label: "V" },
        { x: h - 1, y: k + a, label: "G₁" },
        { x: h + 1, y: k + a, label: "G₂" },
      ],
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-10, 10],
      successExplanation: `Il vertice è V(${h}, ${k}); a = ${a} determina ${a > 0 ? "apertura verso l'alto" : "apertura verso il basso"} e ampiezza della curva.`,
    };
  }

  private buildRootGateWorkshop(random: Random, difficulty: DifficultyPreset): GeneratedGraphWorkshop {
    const a = difficulty.mathComplexity >= 7 ? random.pick([-2, -1, 1, 2]) : random.pick([-1, 1]);
    const h = random.integer(-2, 2);
    const distance = random.integer(1, 3);
    const k = -a * distance * distance;
    const leftRoot = h - distance;
    const rightRoot = h + distance;
    return {
      mode: "root-gates",
      functionKind: "quadratic",
      objective: `Fai attraversare alla parabola le porte R₁ e R₂ e colloca il vertice sul nucleo V(${h}, ${k}).`,
      targetFormula: this.quadraticVertexFormula(a, h, k),
      principle: "Le radici sono i punti in cui y = 0. Nella forma col vertice, spostare h muove entrambe le radici; modificare k le avvicina o le allontana dall'asse x.",
      parameters: this.quadraticParameters(random, a, h, k, difficulty, Math.max(5, Math.abs(k))),
      targetPoints: [
        { x: leftRoot, y: 0, label: "R₁" },
        { x: rightRoot, y: 0, label: "R₂" },
        { x: h, y: k, label: "V" },
      ],
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-Math.max(12, Math.abs(k) + 3), Math.max(12, Math.abs(k) + 3)],
      successExplanation: `Con ${this.quadraticVertexFormula(a, h, k)}, ponendo y = 0 si ottengono x = ${leftRoot} e x = ${rightRoot}.`,
    };
  }

  private buildCurveMatchWorkshop(random: Random, difficulty: DifficultyPreset): GeneratedGraphWorkshop {
    const quadratic = difficulty.mathComplexity >= 5 && random.bool(0.7);
    if (!quadratic) {
      const m = random.pick([-3, -2, -1, 1, 2, 3]);
      const q = random.integer(-4, 4);
      return {
        mode: "curve-match",
        functionKind: "linear",
        objective: "Sovrapponi la retta attiva alla traccia fantasma usando m e q. Osserva separatamente inclinazione e altezza.",
        targetFormula: this.linearFormula(m, q),
        principle: "Due rette coincidono solo se hanno la stessa pendenza e la stessa intercetta.",
        parameters: [
          { key: "m", label: "m", meaning: "pendenza della retta", min: -3, max: 3, step: 1, target: m, initial: this.shiftedInitial(random, m, -3, 3, 1) },
          { key: "q", label: "q", meaning: "intercetta verticale", min: -5, max: 5, step: 1, target: q, initial: this.shiftedInitial(random, q, -5, 5) },
        ],
        targetPoints: [{ x: 0, y: q, label: "q" }],
        showTargetCurve: true,
        xRange: [-6, 6],
        yRange: [-10, 10],
        successExplanation: `Stessa pendenza m = ${m} e stessa intercetta q = ${q}: le rette coincidono in ogni punto.`,
      };
    }
    const a = random.pick([-2, -1, 1, 2]);
    const h = random.integer(-3, 3);
    const k = random.integer(-4, 4);
    return {
      mode: "curve-match",
      functionKind: "quadratic",
      objective: "Sovrapponi la parabola attiva alla traccia fantasma regolando apertura, asse di simmetria e quota del vertice.",
      targetFormula: this.quadraticVertexFormula(a, h, k),
      principle: "Due parabole nella forma y = a(x − h)² + k coincidono quando condividono apertura a e vertice V(h,k).",
      parameters: this.quadraticParameters(random, a, h, k, difficulty),
      targetPoints: [{ x: h, y: k, label: "V" }],
      showTargetCurve: true,
      xRange: [-6, 6],
      yRange: [-12, 12],
      successExplanation: `La curva attiva ha raggiunto a = ${a}, h = ${h}, k = ${k}: forma, asse e vertice coincidono con la traccia.`,
    };
  }

  private quadraticParameters(
    random: Random,
    a: number,
    h: number,
    k: number,
    difficulty: DifficultyPreset,
    verticalLimit = 6,
  ): GeneratedGraphWorkshop["parameters"] {
    const aValues = difficulty.mathComplexity >= 6 ? [-2, -1, 1, 2] : [-1, 1];
    const initialA = random.pick(aValues.filter((value) => value !== a));
    return [
      { key: "a", label: "a", meaning: "verso e apertura della parabola", min: -2, max: 2, step: 1, target: a, initial: initialA },
      { key: "h", label: "h", meaning: "asse di simmetria x = h", min: -4, max: 4, step: 1, target: h, initial: this.shiftedInitial(random, h, -4, 4) },
      { key: "k", label: "k", meaning: "altezza del vertice", min: -verticalLimit, max: verticalLimit, step: 1, target: k, initial: this.shiftedInitial(random, k, -verticalLimit, verticalLimit) },
    ];
  }

  private graphWorkshopHints(workshop: GeneratedGraphWorkshop): string[] {
    if (workshop.mode === "beacon-line") {
      const [first, second] = workshop.targetPoints;
      return [
        `Calcola la pendenza osservando i beacon: Δy/Δx = (${second.y} − ${first.y}) / (${second.x} − ${first.x}).`,
        first.x === 0 || second.x === 0
          ? "Il beacon con x = 0 sta sull'asse y: la sua y è q."
          : "Dopo aver trovato m, ricava q con q = y - m*x usando uno dei due beacon.",
        "Controlla entrambi i beacon: attraversarne uno solo non determina una retta unica.",
      ];
    }
    if (workshop.mode === "root-gates") {
      return [
        "Le due radici sono simmetriche rispetto alla verticale x = h: trova prima il loro punto medio.",
        "Regola k finché la curva raggiunge l'asse x esattamente sulle due porte.",
        "Il segno di a deve rispettare il verso di apertura; |a| cambia quanto la curva è stretta.",
      ];
    }
    if (workshop.mode === "vertex-shift") {
      return [
        "h muove il vertice a destra o sinistra; k lo muove in alto o in basso.",
        "Il segno di a inverte la parabola; il suo valore assoluto modifica l'apertura.",
        "Modifica un parametro alla volta e osserva quale proprietà resta invariata.",
      ];
    }
    return [
      "Allinea prima il punto notevole: intercetta per la retta, vertice per la parabola.",
      "Poi correggi l'inclinazione o l'apertura senza perdere l'allineamento raggiunto.",
      "La sovrapposizione completa richiede gli stessi parametri, non solo un punto in comune.",
    ];
  }

  private shiftedInitial(random: Random, target: number, min: number, max: number, fallbackDelta = 1): number {
    const candidates = [-3, -2, -1, 1, 2, 3]
      .map((delta) => target + delta)
      .filter((value) => value >= min && value <= max && value !== target);
    return candidates.length > 0 ? random.pick(candidates) : clampNumber(target + fallbackDelta, min, max);
  }

  private linearFormula(m: number, q: number): string {
    const slope = m === 1 ? "x" : m === -1 ? "−x" : `${m}x`;
    const intercept = q === 0 ? "" : q > 0 ? ` + ${q}` : ` − ${Math.abs(q)}`;
    return `y = ${slope}${intercept}`;
  }

  private quadraticVertexFormula(a: number, h: number, k: number): string {
    const leading = a === 1 ? "" : a === -1 ? "−" : `${a}`;
    const horizontal = h === 0 ? "x" : h > 0 ? `(x − ${h})` : `(x + ${Math.abs(h)})`;
    const vertical = k === 0 ? "" : k > 0 ? ` + ${k}` : ` − ${Math.abs(k)}`;
    return `y = ${leading}${horizontal}²${vertical}`;
  }

  private buildQuadraticEquationLab(random: Random, difficulty: DifficultyPreset): GeneratedMathPuzzle {
    const solutionMode = difficulty.mathComplexity >= 8
      ? random.pick<"two" | "double" | "none">(["two", "two", "double", "none"])
      : random.pick<"two" | "double">(["two", "two", "double"]);
    const leading = difficulty.mathComplexity >= 7 && random.bool(0.35) ? 2 : 1;
    let roots: number[] = [];
    let b = 0;
    let c = 0;
    if (solutionMode === "two") {
      const first = random.integer(1, 5 + Math.floor(difficulty.mathComplexity / 2));
      let second = random.integer(1, 7 + Math.floor(difficulty.mathComplexity / 2));
      if (second === first) second += 2;
      roots = [Math.min(first, second), Math.max(first, second)];
      b = -leading * (roots[0] + roots[1]);
      c = leading * roots[0] * roots[1];
    } else if (solutionMode === "double") {
      const root = random.integer(2, 7);
      roots = [root];
      b = -2 * leading * root;
      c = leading * root * root;
    } else {
      const vertexX = random.integer(1, 4);
      const lift = random.integer(1, 5);
      b = -2 * leading * vertexX;
      c = leading * vertexX * vertexX + lift;
    }
    const discriminant = b * b - 4 * leading * c;
    const equation = `${this.term(leading, "x²", true)} ${this.term(b, "x")} ${this.term(c, "")} = 0`.replace(/\s+/g, " ").trim();
    const solutionLabel = roots.length === 0
      ? "Nessuna soluzione reale"
      : roots.length === 1
        ? `x = ${roots[0]}`
        : `x₁ = ${roots[0]}, x₂ = ${roots[1]}`;
    const factorization = roots.length === 2
      ? `${leading === 1 ? "" : `${leading}`}·(x - ${roots[0]})(x - ${roots[1]}) = 0`
      : roots.length === 1
        ? `${leading === 1 ? "" : `${leading}`}·(x - ${roots[0]})² = 0`
        : "La parabola non incontra l'asse x";
    const deltaClass = discriminant > 0 ? "Δ > 0: due soluzioni reali distinte" : discriminant === 0 ? "Δ = 0: una soluzione reale doppia" : "Δ < 0: nessuna soluzione reale";
    const stages: EquationLabStage[] = [
      {
        id: "quadratic-standard",
        title: "1 · Riconosci la struttura",
        prompt: `Nell'equazione ${equation}, quali sono i coefficienti a, b e c?`,
        options: random.shuffle([
          `a = ${leading}, b = ${b}, c = ${c}`,
          `a = ${b}, b = ${leading}, c = ${c}`,
          `a = ${leading}, b = ${c}, c = ${b}`,
          `a = 1, b = ${Math.abs(b)}, c = ${Math.abs(c)}`,
        ]),
        correctOption: `a = ${leading}, b = ${b}, c = ${c}`,
        explanation: "La forma standard è ax² + bx + c = 0. I segni fanno parte dei coefficienti.",
        visual: "standard-form",
      },
      {
        id: "quadratic-delta",
        title: "2 · Calcola il discriminante",
        prompt: `Quanto vale Δ = b² - 4ac per questa equazione?`,
        options: random.shuffle([`${discriminant}`, `${b * b + 4 * leading * c}`, `${Math.abs(b) - 4 * leading * c}`, `${b * b - 2 * leading * c}`]),
        correctOption: `${discriminant}`,
        explanation: `Δ = (${b})² - 4·${leading}·${c} = ${b * b} - ${4 * leading * c} = ${discriminant}.`,
        visual: "discriminant",
      },
      {
        id: "quadratic-count",
        title: "3 · Prevedi quante soluzioni",
        prompt: `Cosa indica Δ = ${discriminant}?`,
        options: random.shuffle([
          deltaClass,
          "Δ > 0: nessuna soluzione reale",
          "Δ = 0: due soluzioni reali distinte",
          "Il discriminante non dice nulla sulle soluzioni",
        ]),
        correctOption: deltaClass,
        explanation: "Il segno del discriminante anticipa quante volte la parabola incontra l'asse x.",
        visual: "parabola",
      },
      {
        id: "quadratic-solve",
        title: "4 · Trova le radici",
        prompt: "Qual è l'insieme delle soluzioni reali?",
        options: random.shuffle([
          solutionLabel,
          roots.length === 2 ? `x₁ = ${-roots[0]}, x₂ = ${-roots[1]}` : `x = ${Math.abs(b)}`,
          roots.length === 1 ? `x = ${-roots[0]}` : "x = 0",
          roots.length === 0 ? "x = 1 e x = -1" : "Nessuna soluzione reale",
        ]),
        correctOption: solutionLabel,
        explanation: roots.length === 0
          ? `Poiché Δ = ${discriminant} è negativo, √Δ non è reale: la parabola resta sopra l'asse x.`
          : `Con x = (-b ± √Δ)/(2a) ottieni ${solutionLabel}.`,
        visual: roots.length > 0 ? "formula" : "parabola",
      },
      {
        id: "quadratic-meaning",
        title: "5 · Collega algebra e grafico",
        prompt: "Quale descrizione grafica è coerente con le soluzioni trovate?",
        options: random.shuffle([
          roots.length === 2
            ? `La parabola taglia l'asse x in ${roots[0]} e ${roots[1]}`
            : roots.length === 1
              ? `La parabola è tangente all'asse x in ${roots[0]}`
              : "La parabola non interseca l'asse x",
          "La parabola coincide sempre con l'asse x",
          "Le radici indicano le intersezioni con l'asse y",
          "Il coefficiente c indica sempre il numero di radici",
        ]),
        correctOption: roots.length === 2
          ? `La parabola taglia l'asse x in ${roots[0]} e ${roots[1]}`
          : roots.length === 1
            ? `La parabola è tangente all'asse x in ${roots[0]}`
            : "La parabola non interseca l'asse x",
        explanation: `Le soluzioni di f(x)=0 sono le ascisse dei punti in cui il grafico incontra l'asse x. ${factorization}.`,
        visual: "parabola",
      },
    ];
    return {
      id: `math-equation-lab-quadratic-${leading}-${b}-${c}`,
      title: "Laboratorio equazioni · Parabola e radici",
      prompt: `Situazione: il sistema visualizza un'equazione di secondo grado come formula e come parabola.\nRichiesta: riconosci coefficienti, discriminante, numero di soluzioni e radici di ${equation}.\nFormato risposta: scegli una tessera a ogni passaggio; possono esistere zero, una o due soluzioni reali.`,
      answer: roots[0] ?? 0,
      hints: [
        "Porta l'equazione nella forma ax² + bx + c = 0 e conserva i segni.",
        "Calcola prima Δ = b² - 4ac: il suo segno dice quante soluzioni reali aspettarti.",
        "Le radici sono le ascisse delle intersezioni della parabola con l'asse x.",
      ],
      archetype: "equazione-secondo-grado",
      curriculumTags: ["equazioni di secondo grado", "discriminante", "formula risolutiva", "parabola", "radici"],
      solutionSteps: [
        `a = ${leading}, b = ${b}, c = ${c}`,
        `Δ = (${b})² - 4·${leading}·${c} = ${discriminant}`,
        deltaClass,
        solutionLabel,
        factorization,
      ],
      competencies: ["matematica.equazioni", "matematica.algebra", "matematica.funzioni", "matematica.grafici", "problemSolving"],
      equationLab: {
        degree: 2,
        equation,
        coefficients: { a: leading, b, c },
        roots,
        discriminant,
        principle: "Il discriminante collega la forma algebrica al numero di intersezioni della parabola con l'asse x.",
        verification: roots.length > 0
          ? roots.map((root) => `f(${root}) = ${leading * root * root + b * root + c}`).join("; ")
          : `Vertice sopra l'asse x e Δ = ${discriminant} < 0`,
        stages,
      },
    };
  }

  private term(value: number, symbol: string, first = false): string {
    if (value === 0) return "";
    const sign = value < 0 ? "-" : first ? "" : "+";
    const magnitude = Math.abs(value);
    const coefficient = symbol && magnitude === 1 ? "" : `${magnitude}`;
    return `${sign}${coefficient}${symbol}`;
  }

  private uniquePrompt(
    random: Random,
    difficulty: DifficultyPreset,
    type: MathMinigameType,
    index: number,
    usedSignatures: Set<string>,
  ): MathMinigamePrompt {
    for (let attempt = 0; attempt < 48; attempt += 1) {
      const prompt = this.buildPrompt(random, difficulty, type, index + attempt);
      if (!usedSignatures.has(prompt.signature)) {
        return prompt;
      }
    }
    const fallback = this.buildPrompt(random, difficulty, type, index + 99);
    return usedSignatures.has(fallback.signature)
      ? { ...fallback, signature: `${fallback.signature}#${index}` }
      : fallback;
  }

  private buildPrompt(random: Random, difficulty: DifficultyPreset, type: MathMinigameType, index: number): MathMinigamePrompt {
    if (type === "target-sum") {
      return this.buildTargetSumPrompt(random, difficulty, index);
    }
    if (type === "factor-hunt") {
      return this.buildFactorHuntPrompt(random, difficulty, index);
    }
    if (type === "number-sequence") {
      return this.buildNumberSequencePrompt(random, difficulty, index);
    }
    if (type === "expression-build") {
      return this.buildExpressionBuildPrompt(random, difficulty, index);
    }
    if (type === "fraction-lab") {
      return this.buildFractionLabPrompt(random, difficulty, index);
    }
    if (type === "ratio-proportion") {
      return this.buildRatioProportionPrompt(random, difficulty, index);
    }
    if (type === "geometry-measure") {
      return this.buildGeometryMeasurePrompt(random, difficulty, index);
    }
    if (type === "data-probability") {
      return this.buildDataProbabilityPrompt(random, difficulty, index);
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
      const distractors = this.uniqueNumbersWhere(
        random,
        7 - required,
        Math.max(2, min - 3),
        max + 8,
        (value) => !correctValues.includes(value) && value !== target,
      );
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
          ? `${value} è uno degli addendi che porta a ${target}.`
          : `${value} non entra nella combinazione esatta: includerlo cambia il totale rispetto a ${target}.`,
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
      const distractors = this.uniqueNumbersWhere(
        random,
        7 - correctValues.length,
        Math.max(2, base + 1),
        base * 10 + 7,
        (value) => value % base !== 0 && !correctValues.includes(value),
      );
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
    const distractors = this.uniqueNumbersWhere(
      random,
      7 - correctValues.length,
      2,
      Math.min(36, target - 1),
      (value) => target % value !== 0 && !correctValues.includes(value),
    );
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
    const operations = this.operationDefinitions();
    const validFirst = operations.filter((operation) => !operation.valid || operation.valid(start));
    const first = random.pick(validFirst);
    const mid = first.apply(start);
    const validSecond = operations.filter((operation) => !operation.valid || operation.valid(mid));
    const second = twoSteps ? random.pick(validSecond) : undefined;
    const target = second ? second.apply(mid) : mid;
    const correctLabel = second ? `${first.label} poi ${second.label}` : first.label;
    const routeLabels = twoSteps
      ? operations.flatMap((left) => operations.map((right) => `${left.label} poi ${right.label}`))
      : operations.map((operation) => operation.label);
    const distractors = random.shuffle(routeLabels)
      .map((label) => ({ label, result: this.evaluateOperationRoute(start, label) }))
      .filter(({ label, result }) => label !== correctLabel && result !== undefined && result !== target)
      .slice(0, 5);
    const labels = random.shuffle([correctLabel, ...distractors.map((candidate) => candidate.label)]).slice(0, 6);
    const tiles = labels.map((label, tileIndex) => ({
      id: `operation-${index}-${tileIndex}`,
      label,
      isCorrect: label === correctLabel,
      feedback: label === correctLabel
        ? `Da ${start} arrivi a ${target}.`
        : `Questa rotta porta a ${this.evaluateOperationRoute(start, label)}, non a ${target}.`,
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

  private singleCorrectTiles(
    random: Random,
    prefix: string,
    index: number,
    correct: ChoiceCandidate,
    distractors: ChoiceCandidate[],
    fallbackHint: string,
  ): MathMinigameTile[] {
    const seen = new Set<string>();
    const candidates: Array<ChoiceCandidate & { isCorrect: boolean }> = [];
    const push = (candidate: ChoiceCandidate, isCorrect: boolean): void => {
      const label = candidate.label.trim();
      if (!label || seen.has(label)) return;
      seen.add(label);
      candidates.push({ ...candidate, label, isCorrect });
    };
    push(correct, true);
    distractors.forEach((candidate) => push(candidate, false));
    const offsets = [-10, 10, -6, 6, -4, 4, -2, 2, -1, 1, 12, -12, 15, -15];
    for (const offset of offsets) {
      if (candidates.length >= 4) break;
      const value = correct.value + offset;
      if (value <= 0 || value === correct.value) continue;
      push({
        label: `${value}`,
        value,
        feedback: `${value} e vicino, ma non rispetta il passaggio richiesto: ${fallbackHint}.`,
      }, false);
    }
    return this.shuffleTiles(random, candidates.slice(0, 5).map((candidate, tileIndex) => ({
      id: `${prefix}-${index}-${tileIndex}`,
      label: candidate.label,
      value: candidate.value,
      isCorrect: candidate.isCorrect,
      feedback: candidate.feedback,
    })));
  }

  private buildChoicePrompt(params: {
    random: Random;
    index: number;
    type: MathMinigameType;
    prefix: string;
    prompt: string;
    targetLabel: string;
    correct: ChoiceCandidate;
    distractors: ChoiceCandidate[];
    explanation: string;
    concept: string;
    signature: string;
    fallbackHint: string;
    geometryVisual?: MathGeometryVisual;
  }): MathMinigamePrompt {
    const tiles = this.singleCorrectTiles(
      params.random,
      params.prefix,
      params.index,
      params.correct,
      params.distractors,
      params.fallbackHint,
    );
    return {
      id: `${params.prefix}-${params.index}`,
      type: params.type,
      prompt: params.prompt,
      targetLabel: params.targetLabel,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [params.correct.label],
      explanation: params.explanation,
      concept: params.concept,
      geometryVisual: params.geometryVisual,
      signature: params.signature,
    };
  }

  private buildFractionLabPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const modes = difficulty.level <= 2
      ? ["fraction-of", "percent-of"] as const
      : difficulty.level <= 4
        ? ["fraction-of", "percent-of", "percent-from-fraction"] as const
        : ["fraction-of", "percent-of", "percent-from-fraction", "decimal-percent"] as const;
    const mode = random.pick(modes);
    if (mode === "fraction-of") {
      const denominators = difficulty.level >= 5 ? [3, 4, 5, 6, 8, 10, 12] : [2, 3, 4, 5, 6, 8];
      const denominator = random.pick(denominators);
      const numerator = random.integer(1, denominator - 1);
      const unit = random.integer(3, 8 + difficulty.level * 2);
      const total = denominator * unit;
      const answer = numerator * unit;
      const contexts = [
        { place: "playlist", item: "brani" },
        { place: "quaderno di appunti", item: "pagine" },
        { place: "scatola per la merenda", item: "biscotti" },
        { place: "album fotografico", item: "foto" },
        { place: "zaino per la gita", item: "oggetti" },
      ];
      const context = random.pick(contexts);
      return this.buildChoicePrompt({
        random,
        index,
        type: "fraction-lab",
        prefix: "fraction-of",
        prompt: `Nel ${context.place} ci sono ${total} ${context.item}. Devi usarne ${numerator}/${denominator}. Quanti ${context.item} sono?`,
        targetLabel: `${numerator}/${denominator} di ${total}`,
        correct: { label: `${answer}`, value: answer, feedback: `${answer} e corretto: prima trovi 1/${denominator} = ${unit}, poi moltiplichi per ${numerator}.` },
        distractors: [
          { label: `${unit}`, value: unit, feedback: `${unit} e solo 1/${denominator} del totale: manca il moltiplicatore ${numerator}.` },
          { label: `${Math.max(1, total - answer)}`, value: Math.max(1, total - answer), feedback: `Questo e il resto, non la parte richiesta dalla frazione ${numerator}/${denominator}.` },
          { label: `${Math.max(1, answer + denominator)}`, value: Math.max(1, answer + denominator), feedback: `Hai aggiunto il denominatore: la frazione chiede divisione in parti uguali e poi moltiplicazione.` },
          { label: `${Math.max(1, numerator * denominator)}`, value: Math.max(1, numerator * denominator), feedback: `Moltiplicare numeratore e denominatore non usa il totale ${total}.` },
        ],
        explanation: `${total} : ${denominator} = ${unit}; ${unit} x ${numerator} = ${answer}.`,
        concept: "frazione come operatore su una quantita",
        signature: `fraction-of-${numerator}-${denominator}-${total}`,
        fallbackHint: `dividi ${total} in ${denominator} parti uguali e prendine ${numerator}`,
      });
    }
    if (mode === "percent-of") {
      const percent = random.pick([10, 15, 20, 25, 30, 40, 50, 60, 75]);
      const step = 100 / gcd(percent, 100);
      const base = step * random.integer(5, 18 + difficulty.level);
      const answer = (base * percent) / 100;
      const contexts = [
        { subject: "la batteria del tablet", unit: "punti percentuali usati" },
        { subject: "uno sconto su una felpa", unit: "euro di sconto" },
        { subject: "gli studenti che scelgono il laboratorio", unit: "studenti" },
        { subject: "i posti occupati sul bus", unit: "posti" },
      ];
      const context = random.pick(contexts);
      return this.buildChoicePrompt({
        random,
        index,
        type: "fraction-lab",
        prefix: "percent-of",
        prompt: `Calcola il ${percent}% di ${base}: nella situazione "${context.subject}", quanti ${context.unit} sono?`,
        targetLabel: `${percent}% di ${base}`,
        correct: { label: `${answer}`, value: answer, feedback: `${answer} e corretto: ${percent}% significa ${percent}/100 del totale.` },
        distractors: [
          { label: `${percent}`, value: percent, feedback: `${percent} e la percentuale, non il valore calcolato su ${base}.` },
          { label: `${Math.max(1, base - answer)}`, value: Math.max(1, base - answer), feedback: `Questo e il resto dopo aver tolto il ${percent}%, non la parte richiesta.` },
          { label: `${Math.max(1, answer + step)}`, value: Math.max(1, answer + step), feedback: `Sei vicino, ma il rapporto percentuale deve restare ${percent}/100.` },
          { label: `${Math.max(1, Math.round(base / percent))}`, value: Math.max(1, Math.round(base / percent)), feedback: `Dividere ${base} per ${percent} confonde percentuale e denominatore 100.` },
        ],
        explanation: `${percent}% di ${base} = ${base} x ${percent} : 100 = ${answer}.`,
        concept: "percentuale di una quantita",
        signature: `percent-of-${percent}-${base}`,
        fallbackHint: `trasforma ${percent}% in ${percent}/100`,
      });
    }
    if (mode === "percent-from-fraction") {
      const fraction = random.pick([
        { numerator: 1, denominator: 2, percent: 50 },
        { numerator: 1, denominator: 4, percent: 25 },
        { numerator: 3, denominator: 4, percent: 75 },
        { numerator: 1, denominator: 5, percent: 20 },
        { numerator: 2, denominator: 5, percent: 40 },
        { numerator: 3, denominator: 5, percent: 60 },
        { numerator: 1, denominator: 10, percent: 10 },
      ]);
      return this.buildChoicePrompt({
        random,
        index,
        type: "fraction-lab",
        prefix: "fraction-percent",
        prompt: `Durante un sondaggio, ${fraction.numerator}/${fraction.denominator} della classe sceglie l'opzione A. Qual e la percentuale equivalente?`,
        targetLabel: `${fraction.numerator}/${fraction.denominator} in percentuale`,
        correct: { label: `${fraction.percent}`, value: fraction.percent, feedback: `${fraction.percent}% e corretto: la frazione e stata portata su 100.` },
        distractors: [
          { label: `${fraction.numerator * 10}`, value: fraction.numerator * 10, feedback: `Hai guardato solo il numeratore: serve il rapporto tra numeratore e denominatore.` },
          { label: `${fraction.denominator * 10}`, value: fraction.denominator * 10, feedback: `Il denominatore non diventa automaticamente la percentuale.` },
          { label: `${100 - fraction.percent}`, value: 100 - fraction.percent, feedback: `Questa e la percentuale complementare, non la parte indicata.` },
          { label: `${Math.min(95, fraction.percent + 10)}`, value: Math.min(95, fraction.percent + 10), feedback: `Aggiungere 10 punti altera l'equivalenza della frazione.` },
        ],
        explanation: `${fraction.numerator}/${fraction.denominator} = ${fraction.percent}/100, quindi ${fraction.percent}%.`,
        concept: "equivalenza fra frazioni e percentuali",
        signature: `fraction-percent-${fraction.numerator}-${fraction.denominator}`,
        fallbackHint: "porta la frazione a denominatore 100",
      });
    }
    const decimal = random.pick([
      { text: "0,1", value: 10 },
      { text: "0,2", value: 20 },
      { text: "0,25", value: 25 },
      { text: "0,4", value: 40 },
      { text: "0,5", value: 50 },
      { text: "0,75", value: 75 },
      { text: "0,8", value: 80 },
    ]);
    return this.buildChoicePrompt({
      random,
      index,
      type: "fraction-lab",
      prefix: "decimal-percent",
      prompt: `Nel registro digitale compare ${decimal.text} come parte completata di un compito. Qual e la percentuale corrispondente?`,
      targetLabel: `${decimal.text} in percentuale`,
      correct: { label: `${decimal.value}`, value: decimal.value, feedback: `${decimal.text} corrisponde a ${decimal.value}%.` },
      distractors: [
        { label: `${Math.max(1, decimal.value / 10)}`, value: Math.max(1, decimal.value / 10), feedback: `Hai spostato la virgola nella direzione sbagliata: per la percentuale si moltiplica per 100.` },
        { label: `${Math.max(1, 100 - decimal.value)}`, value: Math.max(1, 100 - decimal.value), feedback: `Questo e il completamento mancante, non la parte gia completata.` },
        { label: `${Math.min(99, decimal.value + 5)}`, value: Math.min(99, decimal.value + 5), feedback: `Aggiungere punti percentuali rompe l'equivalenza decimale-percentuale.` },
      ],
      explanation: `${decimal.text} x 100 = ${decimal.value}%, quindi la parte decimale diventa percentuale.`,
      concept: "numero decimale e percentuale equivalente",
      signature: `decimal-percent-${decimal.text}`,
      fallbackHint: "moltiplica il numero decimale per 100",
    });
  }

  private buildRatioProportionPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const modes = difficulty.level >= 6
      ? ["unit-price", "recipe", "scale", "speed", "inverse"] as const
      : ["unit-price", "recipe", "scale", "speed"] as const;
    const mode = random.pick(modes);
    if (mode === "unit-price") {
      const unitPrice = random.integer(2, 9 + difficulty.level);
      const knownQuantity = random.integer(2, 6);
      const requestedQuantity = random.integer(knownQuantity + 1, knownQuantity + 7);
      const knownPrice = unitPrice * knownQuantity;
      const answer = unitPrice * requestedQuantity;
      return this.buildChoicePrompt({
        random,
        index,
        type: "ratio-proportion",
        prefix: "ratio-price",
        prompt: `${knownQuantity} quaderni costano ${knownPrice} euro. Quanto costano ${requestedQuantity} quaderni allo stesso prezzo unitario?`,
        targetLabel: `Prezzo di ${requestedQuantity}`,
        correct: { label: `${answer}`, value: answer, feedback: `${answer} e corretto: il prezzo unitario e ${unitPrice} euro.` },
        distractors: [
          { label: `${knownPrice + requestedQuantity}`, value: knownPrice + requestedQuantity, feedback: `Somma non proporzionale: serve prima il prezzo di un quaderno.` },
          { label: `${knownPrice * requestedQuantity}`, value: knownPrice * requestedQuantity, feedback: `Hai moltiplicato per la quantita senza dividere per ${knownQuantity}.` },
          { label: `${unitPrice + requestedQuantity}`, value: unitPrice + requestedQuantity, feedback: `Hai mescolato prezzo unitario e quantita: bisogna moltiplicarli.` },
        ],
        explanation: `${knownPrice} : ${knownQuantity} = ${unitPrice}; ${unitPrice} x ${requestedQuantity} = ${answer}.`,
        concept: "rapporto unitario in un acquisto quotidiano",
        signature: `ratio-price-${knownQuantity}-${knownPrice}-${requestedQuantity}`,
        fallbackHint: "trova prima il valore di una sola unita",
      });
    }
    if (mode === "recipe") {
      const gramsPerPerson = random.pick([40, 50, 60, 75, 80, 100, 120]);
      const peopleKnown = random.integer(2, 5);
      const peopleWanted = random.integer(peopleKnown + 1, peopleKnown + 6);
      const knownGrams = gramsPerPerson * peopleKnown;
      const answer = gramsPerPerson * peopleWanted;
      return this.buildChoicePrompt({
        random,
        index,
        type: "ratio-proportion",
        prefix: "ratio-recipe",
        prompt: `Per ${peopleKnown} persone servono ${knownGrams} g di pasta. Quanti grammi servono per ${peopleWanted} persone?`,
        targetLabel: `Dosi per ${peopleWanted}`,
        correct: { label: `${answer}`, value: answer, feedback: `${answer} g e corretto: la dose per persona resta ${gramsPerPerson} g.` },
        distractors: [
          { label: `${knownGrams + peopleWanted}`, value: knownGrams + peopleWanted, feedback: `Aggiungere persone ai grammi non mantiene il rapporto.` },
          { label: `${gramsPerPerson + peopleWanted}`, value: gramsPerPerson + peopleWanted, feedback: `Hai trovato la dose unitaria ma non l'hai moltiplicata per le persone.` },
          { label: `${knownGrams * peopleWanted}`, value: knownGrams * peopleWanted, feedback: `Manca la divisione per le ${peopleKnown} persone iniziali.` },
        ],
        explanation: `${knownGrams} : ${peopleKnown} = ${gramsPerPerson} g a persona; ${gramsPerPerson} x ${peopleWanted} = ${answer} g.`,
        concept: "proporzionalita diretta in una ricetta",
        signature: `ratio-recipe-${peopleKnown}-${knownGrams}-${peopleWanted}`,
        fallbackHint: "riduci la ricetta a una persona",
      });
    }
    if (mode === "scale") {
      const scale = random.pick([2, 3, 4, 5, 8, 10, 12]);
      const cm = random.integer(3, 12 + difficulty.level);
      const answer = scale * cm;
      return this.buildChoicePrompt({
        random,
        index,
        type: "ratio-proportion",
        prefix: "ratio-scale",
        prompt: `Su una mappa, 1 cm rappresenta ${scale} km. Una pista misura ${cm} cm sulla mappa. Quanti km misura nella realta?`,
        targetLabel: `Scala 1 cm = ${scale} km`,
        correct: { label: `${answer}`, value: answer, feedback: `${answer} km e corretto: ogni centimetro vale ${scale} km.` },
        distractors: [
          { label: `${Math.max(1, cm + scale)}`, value: Math.max(1, cm + scale), feedback: `Somma scala e centimetri: non e una proporzione.` },
          { label: `${Math.max(1, cm)}`, value: Math.max(1, cm), feedback: `Hai letto la misura sulla mappa, non quella reale.` },
          { label: `${Math.max(1, answer - scale)}`, value: Math.max(1, answer - scale), feedback: `Hai contato un centimetro in meno nella scala.` },
        ],
        explanation: `${cm} x ${scale} = ${answer} km: ogni centimetro sulla mappa vale ${scale} km reali.`,
        concept: "scala grafica e proporzione diretta",
        signature: `ratio-scale-${scale}-${cm}`,
        fallbackHint: "moltiplica ogni centimetro per il valore della scala",
      });
    }
    if (mode === "speed") {
      const speed = random.pick([30, 40, 50, 60, 70, 80]);
      const hours = random.integer(2, 5);
      const distance = speed * hours;
      const askDistance = random.bool(0.52);
      const answer = askDistance ? distance : speed;
      return this.buildChoicePrompt({
        random,
        index,
        type: "ratio-proportion",
        prefix: "ratio-speed",
        prompt: askDistance
          ? `Un treno locale procede a ${speed} km/h per ${hours} ore. Quanti km percorre?`
          : `Un treno locale percorre ${distance} km in ${hours} ore. Qual e la velocita media in km/h?`,
        targetLabel: askDistance ? "Distanza" : "Velocita media",
        correct: { label: `${answer}`, value: answer, feedback: askDistance ? `${answer} km e corretto: velocita x tempo.` : `${answer} km/h e corretto: distanza : tempo.` },
        distractors: [
          { label: `${Math.max(1, speed + hours)}`, value: Math.max(1, speed + hours), feedback: `Somma velocita e tempo: le unita non sono compatibili.` },
          { label: `${Math.max(1, distance - hours)}`, value: Math.max(1, distance - hours), feedback: `Sottrarre il tempo non calcola ne distanza ne velocita.` },
          { label: `${Math.max(1, Math.round(distance / speed))}`, value: Math.max(1, Math.round(distance / speed)), feedback: `Questo recupera il tempo, non la grandezza richiesta.` },
        ],
        explanation: askDistance
          ? `${speed} x ${hours} = ${distance} km: la distanza nasce da velocita per tempo.`
          : `${distance} : ${hours} = ${speed} km/h: la velocita media e distanza divisa per tempo.`,
        concept: "rapporto tra spazio, tempo e velocita",
        signature: `ratio-speed-${askDistance ? "d" : "v"}-${speed}-${hours}`,
        fallbackHint: "controlla le unita: km/h, ore, km",
      });
    }
    const machines = random.pick([2, 3, 4, 5]);
    const multiplier = random.pick([2, 3]);
    const knownTime = random.integer(4, 10) * multiplier;
    const newMachines = machines * multiplier;
    const answer = knownTime / multiplier;
    return this.buildChoicePrompt({
      random,
      index,
      type: "ratio-proportion",
      prefix: "ratio-inverse",
      prompt: `${machines} stampanti completano un fascicolo in ${knownTime} minuti. Con ${newMachines} stampanti uguali, quanti minuti servono?`,
      targetLabel: "Proporzionalita inversa",
      correct: { label: `${answer}`, value: answer, feedback: `${answer} minuti e corretto: se le stampanti aumentano, il tempo diminuisce nello stesso rapporto.` },
      distractors: [
        { label: `${knownTime * multiplier}`, value: knownTime * multiplier, feedback: `Hai applicato una proporzione diretta: qui il tempo deve diminuire.` },
        { label: `${knownTime + multiplier}`, value: knownTime + multiplier, feedback: `Aggiungere stampanti al tempo non conserva il lavoro totale.` },
        { label: `${Math.max(1, knownTime - machines)}`, value: Math.max(1, knownTime - machines), feedback: `Sottrarre il numero di stampanti non usa il rapporto ${newMachines}:${machines}.` },
      ],
      explanation: `${newMachines} e ${multiplier} volte ${machines}, quindi il tempo diventa ${knownTime} : ${multiplier} = ${answer} minuti.`,
      concept: "proporzionalita inversa in un lavoro condiviso",
      signature: `ratio-inverse-${machines}-${knownTime}-${newMachines}`,
      fallbackHint: "piu macchine uguali lavorano in meno tempo",
    });
  }

  private buildGeometryMeasurePrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const modes = difficulty.level <= 2
      ? ["rectangle-perimeter", "rectangle-area"] as const
      : difficulty.level <= 5
        ? ["rectangle-perimeter", "rectangle-area", "triangle-area", "volume"] as const
        : ["rectangle-perimeter", "rectangle-area", "triangle-area", "volume", "pythagoras", "circle"] as const;
    const mode = random.pick(modes);
    if (mode === "rectangle-perimeter" || mode === "rectangle-area") {
      const width = random.integer(4, 10 + difficulty.level);
      const height = random.integer(3, 9 + difficulty.level);
      const isPerimeter = mode === "rectangle-perimeter";
      const answer = isPerimeter ? 2 * (width + height) : width * height;
      return this.buildChoicePrompt({
        random,
        index,
        type: "geometry-measure",
        prefix: mode,
        prompt: `Un cortile rettangolare misura ${width} m per ${height} m. Calcola ${isPerimeter ? "il perimetro" : "l'area"}.`,
        targetLabel: isPerimeter ? "Perimetro rettangolo" : "Area rettangolo",
        correct: { label: `${answer}`, value: answer, feedback: isPerimeter ? `${answer} m e corretto: sommi tutti i lati.` : `${answer} m2 e corretto: base x altezza.` },
        distractors: [
          { label: `${width + height}`, value: width + height, feedback: `Hai sommato solo due lati: per il perimetro servono tutti e quattro.` },
          { label: `${width * height}`, value: width * height, feedback: isPerimeter ? `Questa e l'area, non il perimetro.` : `Questa e proprio l'area: controlla se la richiesta era perimetro.` },
          { label: `${2 * width + height}`, value: 2 * width + height, feedback: `Hai contato due lati lunghi e uno corto: manca un lato.` },
        ],
        explanation: isPerimeter
          ? `2 x (${width} + ${height}) = ${answer}: nel rettangolo i lati uguali si ripetono due volte.`
          : `${width} x ${height} = ${answer}: l'area conta le unita di superficie dentro il rettangolo.`,
        concept: isPerimeter ? "perimetro come somma dei lati" : "area del rettangolo",
        signature: `${mode}-${width}-${height}`,
        fallbackHint: isPerimeter ? "perimetro = somma dei lati" : "area = base x altezza",
        geometryVisual: { shape: "rectangle", measure: isPerimeter ? "perimeter" : "area", width, height, unit: "m" },
      });
    }
    if (mode === "triangle-area") {
      const base = random.integer(4, 14 + difficulty.level);
      const height = random.integer(4, 12 + difficulty.level);
      const doubled = base * height;
      const answer = doubled % 2 === 0 ? doubled / 2 : (base * (height + 1)) / 2;
      const actualHeight = doubled % 2 === 0 ? height : height + 1;
      return this.buildChoicePrompt({
        random,
        index,
        type: "geometry-measure",
        prefix: "triangle-area",
        prompt: `Un cartellone triangolare ha base ${base} cm e altezza ${actualHeight} cm. Qual e l'area?`,
        targetLabel: "Area triangolo",
        correct: { label: `${answer}`, value: answer, feedback: `${answer} cm2 e corretto: base x altezza diviso 2.` },
        distractors: [
          { label: `${base * actualHeight}`, value: base * actualHeight, feedback: `Hai dimenticato di dividere per 2: quello e il rettangolo equivalente doppio.` },
          { label: `${base + actualHeight}`, value: base + actualHeight, feedback: `Somma base e altezza: non misura una superficie.` },
          { label: `${Math.max(1, answer + base)}`, value: Math.max(1, answer + base), feedback: `Hai aggiunto la base dopo la formula: l'area non richiede questo passaggio.` },
        ],
        explanation: `${base} x ${actualHeight} : 2 = ${answer}: il triangolo occupa meta del rettangolo corrispondente.`,
        concept: "area del triangolo come meta del rettangolo",
        signature: `triangle-area-${base}-${actualHeight}`,
        fallbackHint: "il triangolo e meta del rettangolo con stessa base e altezza",
        geometryVisual: { shape: "triangle", measure: "area", base, height: actualHeight, unit: "cm" },
      });
    }
    if (mode === "volume") {
      const length = random.integer(3, 9 + difficulty.level);
      const width = random.integer(2, 7 + difficulty.level);
      const height = random.integer(2, 6 + difficulty.level);
      const answer = length * width * height;
      return this.buildChoicePrompt({
        random,
        index,
        type: "geometry-measure",
        prefix: "volume-box",
        prompt: `Una scatola misura ${length} cm x ${width} cm x ${height} cm. Qual e il volume?`,
        targetLabel: "Volume parallelepipedo",
        correct: { label: `${answer}`, value: answer, feedback: `${answer} cm3 e corretto: moltiplichi le tre dimensioni.` },
        distractors: [
          { label: `${length * width}`, value: length * width, feedback: `Questo e solo il fondo della scatola: manca l'altezza.` },
          { label: `${2 * (length + width)}`, value: 2 * (length + width), feedback: `Questo assomiglia a un perimetro, non a un volume.` },
          { label: `${length + width + height}`, value: length + width + height, feedback: `Somma le misure lineari: il volume richiede una moltiplicazione tripla.` },
        ],
        explanation: `${length} x ${width} x ${height} = ${answer}: il volume moltiplica le tre dimensioni della scatola.`,
        concept: "volume del parallelepipedo",
        signature: `volume-${length}-${width}-${height}`,
        fallbackHint: "volume = lunghezza x larghezza x altezza",
        geometryVisual: { shape: "box", measure: "volume", length, width, height, unit: "cm" },
      });
    }
    if (mode === "pythagoras") {
      const triple = random.pick([[3, 4, 5], [5, 12, 13], [6, 8, 10], [8, 15, 17], [7, 24, 25]]);
      const scale = random.integer(1, difficulty.level >= 7 ? 3 : 2);
      const a = triple[0] * scale;
      const b = triple[1] * scale;
      const c = triple[2] * scale;
      return this.buildChoicePrompt({
        random,
        index,
        type: "geometry-measure",
        prefix: "pythagoras",
        prompt: `Una scala forma un triangolo rettangolo con cateti ${a} m e ${b} m. Quanto misura la scala?`,
        targetLabel: "Ipotenusa",
        correct: { label: `${c}`, value: c, feedback: `${c} m e corretto: ${a}2 + ${b}2 = ${c}2.` },
        distractors: [
          { label: `${a + b}`, value: a + b, feedback: `Somma dei cateti: Pitagora usa i quadrati, non una somma diretta.` },
          { label: `${Math.abs(b - a)}`, value: Math.abs(b - a), feedback: `Differenza dei cateti: non rappresenta l'ipotenusa.` },
          { label: `${Math.max(1, c - scale)}`, value: Math.max(1, c - scale), feedback: `Sei vicino, ma la terna pitagorica corretta porta a ${c}.` },
        ],
        explanation: `${a}2 + ${b}2 = ${a * a + b * b}; la radice e ${c}.`,
        concept: "teorema di Pitagora in un triangolo rettangolo",
        signature: `pythagoras-${a}-${b}-${c}`,
        fallbackHint: "somma i quadrati dei cateti e poi prendi la radice",
        geometryVisual: { shape: "right-triangle", measure: "hypotenuse", a, b, c, unit: "m" },
      });
    }
    const radius = random.integer(2, 9);
    const askArea = random.bool(0.52);
    const answer = askArea ? 3 * radius * radius : 2 * 3 * radius;
    return this.buildChoicePrompt({
      random,
      index,
      type: "geometry-measure",
      prefix: "circle-measure",
      prompt: `Una pista circolare ha raggio ${radius} m. Usa pi greco = 3 e calcola ${askArea ? "l'area" : "la circonferenza"}.`,
      targetLabel: askArea ? "Area cerchio" : "Circonferenza",
      correct: { label: `${answer}`, value: answer, feedback: askArea ? `${answer} m2 e corretto: 3 x r x r.` : `${answer} m e corretto: 2 x 3 x r.` },
      distractors: [
        { label: `${3 * radius}`, value: 3 * radius, feedback: `Manca un fattore: per area serve r x r, per circonferenza serve 2 x r.` },
        { label: `${radius * radius}`, value: radius * radius, feedback: `Hai calcolato solo r2 senza moltiplicare per pi greco.` },
        { label: `${2 * radius}`, value: 2 * radius, feedback: `Questo e il diametro, non la misura richiesta.` },
      ],
      explanation: askArea
        ? `Area = 3 x ${radius} x ${radius} = ${answer}: per la superficie del cerchio usi pi greco per raggio al quadrato.`
        : `Circonferenza = 2 x 3 x ${radius} = ${answer}: per il bordo del cerchio usi 2 per pi greco per raggio.`,
      concept: askArea ? "area del cerchio con pi greco approssimato" : "circonferenza con pi greco approssimato",
      signature: `circle-${askArea ? "area" : "circ"}-${radius}`,
      fallbackHint: "controlla se serve area o bordo del cerchio",
      geometryVisual: { shape: "circle", measure: askArea ? "area" : "circumference", radius, unit: "m" },
    });
  }

  private buildDataProbabilityPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const modes = difficulty.level <= 3
      ? ["mean", "range", "mode"] as const
      : ["mean", "median", "range", "mode", "probability", "complement"] as const;
    const mode = random.pick(modes);
    if (mode === "mean") {
      const average = random.integer(6, 18 + difficulty.level);
      const deltas = random.shuffle([-3, -1, 0, 1, 3]);
      const values = deltas.map((delta) => Math.max(1, average + delta));
      const correction = average * values.length - values.reduce((sum, value) => sum + value, 0);
      values[values.length - 1] += correction;
      return this.buildChoicePrompt({
        random,
        index,
        type: "data-probability",
        prefix: "data-mean",
        prompt: `Cinque calibrazioni durano ${values.join(", ")} minuti. Qual e la media?`,
        targetLabel: "Media aritmetica",
        correct: { label: `${average}`, value: average, feedback: `${average} e corretto: somma i dati e dividi per 5.` },
        distractors: [
          { label: `${Math.max(...values)}`, value: Math.max(...values), feedback: `Hai scelto il massimo, non la media.` },
          { label: `${Math.min(...values)}`, value: Math.min(...values), feedback: `Hai scelto il minimo, non la media.` },
          { label: `${Math.max(...values) - Math.min(...values)}`, value: Math.max(...values) - Math.min(...values), feedback: `Questo e il campo di variazione, non la media.` },
        ],
        explanation: `${values.join(" + ")} = ${average * values.length}; ${average * values.length} : ${values.length} = ${average}.`,
        concept: "media aritmetica",
        signature: `mean-${values.join("-")}`,
        fallbackHint: "somma tutti i dati e dividi per quanti sono",
      });
    }
    if (mode === "median") {
      const start = random.integer(4, 12);
      const values = [start, start + random.integer(1, 3), start + random.integer(4, 6), start + random.integer(7, 9), start + random.integer(10, 14)];
      const answer = values[2];
      return this.buildChoicePrompt({
        random,
        index,
        type: "data-probability",
        prefix: "data-median",
        prompt: `I tempi ordinati di cinque corse sono ${values.join(", ")} minuti. Qual e la mediana?`,
        targetLabel: "Mediana",
        correct: { label: `${answer}`, value: answer, feedback: `${answer} e corretto: e il dato centrale dopo l'ordinamento.` },
        distractors: [
          { label: `${values[0]}`, value: values[0], feedback: `Questo e il primo dato, non quello centrale.` },
          { label: `${values[4]}`, value: values[4], feedback: `Questo e l'ultimo dato, non la mediana.` },
          { label: `${Math.round(values.reduce((sum, value) => sum + value, 0) / values.length)}`, value: Math.round(values.reduce((sum, value) => sum + value, 0) / values.length), feedback: `Questa assomiglia alla media: la mediana e il valore centrale.` },
        ],
        explanation: `Con cinque dati ordinati, la mediana e il terzo valore: ${answer}.`,
        concept: "mediana di una serie ordinata",
        signature: `median-${values.join("-")}`,
        fallbackHint: "prendi il dato al centro della lista ordinata",
      });
    }
    if (mode === "range") {
      const min = random.integer(3, 12);
      const max = min + random.integer(8, 24);
      const middleA = random.integer(min + 1, max - 2);
      const middleB = random.integer(middleA + 1, max - 1);
      const values = random.shuffle([min, middleA, middleB, max]);
      const answer = max - min;
      return this.buildChoicePrompt({
        random,
        index,
        type: "data-probability",
        prefix: "data-range",
        prompt: `Le temperature registrate sono ${values.join(", ")} gradi. Qual e il campo di variazione?`,
        targetLabel: "Massimo - minimo",
        correct: { label: `${answer}`, value: answer, feedback: `${answer} e corretto: massimo ${max} meno minimo ${min}.` },
        distractors: [
          { label: `${max}`, value: max, feedback: `Hai scelto il massimo: manca il confronto con il minimo.` },
          { label: `${min}`, value: min, feedback: `Hai scelto il minimo: il campo e massimo meno minimo.` },
          { label: `${max + min}`, value: max + min, feedback: `Somma massimo e minimo: il campo di variazione usa la differenza.` },
        ],
        explanation: `${max} - ${min} = ${answer}: il campo di variazione misura la distanza tra massimo e minimo.`,
        concept: "campo di variazione",
        signature: `range-${values.join("-")}`,
        fallbackHint: "trova massimo e minimo, poi sottrai",
      });
    }
    if (mode === "mode") {
      const repeated = random.integer(4, 18);
      const values = random.shuffle([repeated, repeated, repeated, repeated + 2, repeated + 5, Math.max(1, repeated - 3)]);
      return this.buildChoicePrompt({
        random,
        index,
        type: "data-probability",
        prefix: "data-mode",
        prompt: `In un sondaggio compaiono questi voti: ${values.join(", ")}. Qual e la moda?`,
        targetLabel: "Moda statistica",
        correct: { label: `${repeated}`, value: repeated, feedback: `${repeated} e corretto: e il valore che compare piu spesso.` },
        distractors: [
          { label: `${Math.max(...values)}`, value: Math.max(...values), feedback: `Il valore massimo non e necessariamente la moda.` },
          { label: `${Math.min(...values)}`, value: Math.min(...values), feedback: `Il valore minimo non e necessariamente il piu frequente.` },
          { label: `${Math.round(values.reduce((sum, value) => sum + value, 0) / values.length)}`, value: Math.round(values.reduce((sum, value) => sum + value, 0) / values.length), feedback: `Questa e una media arrotondata: la moda riguarda la frequenza.` },
        ],
        explanation: `${repeated} compare piu volte degli altri valori.`,
        concept: "moda come valore piu frequente",
        signature: `mode-${values.join("-")}`,
        fallbackHint: "conta quale valore si ripete di piu",
      });
    }
    if (mode === "probability") {
      const total = random.pick([10, 20, 25, 50]);
      const favorable = random.integer(1, Math.min(total - 1, 12));
      const answer = (favorable * 100) / total;
      return this.buildChoicePrompt({
        random,
        index,
        type: "data-probability",
        prefix: "data-probability",
        prompt: `In un sacchetto ci sono ${total} gettoni, ${favorable} sono blu. Qual e la probabilita di pescare un blu, in percentuale?`,
        targetLabel: "Probabilita %",
        correct: { label: `${answer}`, value: answer, feedback: `${answer}% e corretto: casi favorevoli su casi possibili.` },
        distractors: [
          { label: `${favorable}`, value: favorable, feedback: `Hai indicato i casi favorevoli, non la percentuale di probabilita.` },
          { label: `${total - favorable}`, value: total - favorable, feedback: `Questi sono i casi non blu, non la probabilita richiesta.` },
          { label: `${100 - answer}`, value: 100 - answer, feedback: `Questa e la probabilita complementare.` },
        ],
        explanation: `${favorable}/${total} x 100 = ${answer}%: la probabilita confronta casi favorevoli e casi possibili.`,
        concept: "probabilita classica in percentuale",
        signature: `probability-${favorable}-${total}`,
        fallbackHint: "casi favorevoli diviso casi possibili, poi per 100",
      });
    }
    const total = random.pick([10, 20, 25, 50]);
    const broken = random.integer(1, Math.min(total - 2, 10));
    const good = total - broken;
    const answer = (good * 100) / total;
    return this.buildChoicePrompt({
      random,
      index,
      type: "data-probability",
      prefix: "data-complement",
      prompt: `Su ${total} lampadine, ${broken} sono difettose. Qual e la probabilita di prenderne una funzionante, in percentuale?`,
      targetLabel: "Evento complementare",
      correct: { label: `${answer}`, value: answer, feedback: `${answer}% e corretto: prima trovi le funzionanti, poi la percentuale.` },
      distractors: [
        { label: `${(broken * 100) / total}`, value: (broken * 100) / total, feedback: `Questa e la probabilita di prendere una difettosa, cioe il complementare sbagliato.` },
        { label: `${good}`, value: good, feedback: `Hai contato le lampadine funzionanti ma non hai convertito in percentuale.` },
        { label: `${broken}`, value: broken, feedback: `Hai usato i difetti come risposta numerica, non la probabilita richiesta.` },
      ],
      explanation: `${total} - ${broken} = ${good}; ${good}/${total} x 100 = ${answer}%: prima trovi l'evento favorevole, poi la percentuale.`,
      concept: "probabilita dell'evento complementare",
      signature: `complement-${broken}-${total}`,
      fallbackHint: "trova prima quante sono funzionanti",
    });
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

  private uniqueNumbersWhere(
    random: Random,
    count: number,
    min: number,
    max: number,
    predicate: (value: number) => boolean,
  ): number[] {
    const values = new Set<number>();
    let guard = 0;
    while (values.size < count && guard < 160) {
      const candidate = random.integer(min, max);
      if (predicate(candidate)) {
        values.add(candidate);
      }
      guard += 1;
    }
    for (let candidate = min; values.size < count && candidate <= max; candidate += 1) {
      if (predicate(candidate)) {
        values.add(candidate);
      }
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
      { id: `fallback-${index}-1`, label: "8", value: 8, isCorrect: true, feedback: "8 è un addendo di 8 + 11 = 19." },
      { id: `fallback-${index}-2`, label: "11", value: 11, isCorrect: true, feedback: "11 è un addendo di 8 + 11 = 19." },
      { id: `fallback-${index}-3`, label: "9", value: 9, isCorrect: false, feedback: "9 non entra nella somma esatta: 9 + 11 = 20 e 9 + 8 = 17, non 19." },
      { id: `fallback-${index}-4`, label: "13", value: 13, isCorrect: false, feedback: "13 supera già da solo quasi il bersaglio: nessuna coppia con 13 dà 19." },
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

  private buildNumberSequencePrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const mode = random.integer(0, difficulty.level >= 6 ? 7 : difficulty.level >= 3 ? 5 : 3);
    let terms: number[];
    let next: number;
    let rule: string;
    if (mode === 0) {
      const start = random.integer(1, 6);
      const step = random.integer(2, 3 + difficulty.level);
      terms = [start, start + step, start + 2 * step, start + 3 * step];
      next = start + 4 * step;
      rule = `si aggiunge sempre ${step}`;
    } else if (mode === 1) {
      const start = random.integer(1, 3);
      const ratio = random.integer(2, 3);
      terms = [start, start * ratio, start * ratio * ratio, start * ratio * ratio * ratio];
      next = terms[3] * ratio;
      rule = `si moltiplica sempre per ${ratio}`;
    } else if (mode === 2) {
      const start = random.integer(1, 4);
      terms = [start, start + 1, start + 3, start + 6];
      next = start + 10;
      rule = "si aggiunge 1, poi 2, poi 3, poi 4 (passo crescente)";
    } else if (mode === 3) {
      const base = random.integer(1, 3);
      terms = [base * base, (base + 1) * (base + 1), (base + 2) * (base + 2), (base + 3) * (base + 3)];
      next = (base + 4) * (base + 4);
      rule = "sono numeri quadrati consecutivi";
    } else if (mode === 4) {
      const start = random.integer(24, 48);
      const step = random.integer(3, 8);
      terms = [start, start - step, start - 2 * step, start - 3 * step];
      next = start - 4 * step;
      rule = `si sottrae sempre ${step}`;
    } else if (mode === 5) {
      const start = random.integer(2, 8);
      const a = random.integer(2, 5);
      const b = random.integer(a + 1, a + 5);
      terms = [start, start + a, start + a + b, start + a + b + a];
      next = start + a + b + a + b;
      rule = `si alternano +${a} e +${b}`;
    } else if (mode === 6) {
      const first = random.integer(1, 5);
      const second = random.integer(2, 7);
      terms = [first, second, first + second, first + 2 * second];
      next = terms[2] + terms[3];
      rule = "ogni termine nuovo è la somma dei due precedenti";
    } else {
      const start = random.integer(2, 5);
      const add = random.integer(1, 4);
      terms = [start];
      while (terms.length < 4) {
        terms.push(terms[terms.length - 1] * 2 + add);
      }
      next = terms[3] * 2 + add;
      rule = `si raddoppia e poi si aggiunge ${add}`;
    }
    const distractorValues = new Set<number>();
    [next + 1, next - 1, next + (terms[1] - terms[0]), next * 2 - terms[3]].forEach((value) => {
      if (value !== next && value > 0) distractorValues.add(value);
    });
    let guard = 0;
    while (distractorValues.size < 3 && guard < 20) {
      const candidate = next + random.integer(-6, 6);
      if (candidate !== next && candidate > 0) distractorValues.add(candidate);
      guard += 1;
    }
    const options = [next, ...[...distractorValues].slice(0, 3)];
    const tiles = this.shuffleTiles(random, options.map((value, tileIndex) => ({
      id: `seq-${index}-${tileIndex}`,
      label: `${value}`,
      value,
      isCorrect: value === next,
      feedback: value === next ? `${value} continua la sequenza.` : `${value} non rispetta la regola: ${rule}.`,
    })));
    return {
      id: `number-sequence-${index}`,
      type: "number-sequence",
      prompt: `Quale numero continua la sequenza ${terms.join(", ")}, ... ?`,
      targetLabel: `${terms.join("  ,  ")}  ,  ?`,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [String(next)],
      explanation: `Regola: ${rule}. Dopo ${terms[3]} viene ${next}.`,
      concept: "sequenze numeriche",
      signature: `seq-${terms.join("-")}-${next}`,
    };
  }

  private evaluateOperatorInsertion(numbers: number[], operators: string[]): number {
    const values = [...numbers];
    const ops = [...operators];
    for (let i = 0; i < ops.length;) {
      if (ops[i] === "×") {
        values.splice(i, 2, values[i] * values[i + 1]);
        ops.splice(i, 1);
      } else {
        i += 1;
      }
    }
    let result = values[0];
    for (let i = 0; i < ops.length; i += 1) {
      result = ops[i] === "+" ? result + values[i + 1] : result - values[i + 1];
    }
    return result;
  }

  private operatorSolutions(numbers: number[], allowed: string[], target: number): string[][] {
    const solutions: string[][] = [];
    const scan = (operators: string[]): void => {
      if (operators.length === numbers.length - 1) {
        if (this.evaluateOperatorInsertion(numbers, operators) === target) {
          solutions.push(operators);
        }
        return;
      }
      allowed.forEach((operator) => scan([...operators, operator]));
    };
    scan([]);
    return solutions;
  }

  private sameOperators(left: string[], right: string[]): boolean {
    return left.length === right.length && left.every((operator, index) => operator === right[index]);
  }

  private formatExpression(numbers: number[], operators: string[], target: number): string {
    return `${numbers.map((n, i) => i < operators.length ? `${n} ${operators[i]} ` : `${n}`).join("").trim()} = ${target}`;
  }

  private buildExpressionBuildPrompt(random: Random, difficulty: DifficultyPreset, index: number): MathMinigamePrompt {
    const count = difficulty.level >= 5 ? 4 : 3;
    const allowed = difficulty.level >= 3 ? ["+", "-", "×"] : ["+", "-"];
    for (let attempt = 0; attempt < 90; attempt += 1) {
      const numbers = Array.from({ length: count }, () => random.integer(2, 9));
      const operators = Array.from({ length: count - 1 }, () => random.pick(allowed));
      const target = this.evaluateOperatorInsertion(numbers, operators);
      if (target < 0 || target > 99 || numbers.includes(target)) {
        continue;
      }
      const equivalentSolutions = this.operatorSolutions(numbers, allowed, target);
      if (equivalentSolutions.length !== 1 || !this.sameOperators(equivalentSolutions[0], operators)) {
        continue;
      }
      const tiles = ["+", "-", "×"].filter((op) => allowed.includes(op)).map((op, tileIndex) => ({
        id: `op-${index}-${tileIndex}`,
        label: op,
        isCorrect: false,
        feedback: "Operatore disponibile.",
      }));
      return {
        id: `expression-build-${index}`,
        type: "expression-build",
        prompt: `Inserisci gli operatori tra ${numbers.join(", ")} per ottenere ${target}. Ricorda: la moltiplicazione si calcola prima.`,
        targetLabel: `Bersaglio: ${target}`,
        requiredSelectionCount: count - 1,
        tiles,
        solutionLabels: [this.formatExpression(numbers, operators, target)],
        explanation: `Soluzione unica: ${this.formatExpression(numbers, operators, target)} (× prima di + e -).`,
        concept: "ordine delle operazioni",
        numbers,
        target,
        signature: `expr-${numbers.join("-")}-${target}`,
      };
    }
    // Safe fallback: simple addition target.
    const numbers = [random.integer(2, 6), random.integer(2, 6), random.integer(2, 6)];
    const target = numbers[0] + numbers[1] + numbers[2];
    const tiles = ["+", "-"].map((op, tileIndex) => ({ id: `op-${index}-${tileIndex}`, label: op, isCorrect: false, feedback: "Operatore disponibile." }));
    return {
      id: `expression-build-${index}`,
      type: "expression-build",
      prompt: `Inserisci gli operatori tra ${numbers.join(", ")} per ottenere ${target}.`,
      targetLabel: `Bersaglio: ${target}`,
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: [`${numbers.join(" + ")} = ${target}`],
      explanation: `${numbers.join(" + ")} = ${target}.`,
      concept: "ordine delle operazioni",
      numbers,
      target,
      signature: `expr-fallback-${numbers.join("-")}`,
    };
  }

  private answerProxy(prompt: MathMinigamePrompt): number {
    if (prompt.type === "operation-chain") {
      const parts = prompt.targetLabel.split("->");
      const target = Number(parts[parts.length - 1]?.trim());
      return Number.isFinite(target) ? Math.max(0, Math.min(9999, target)) : 0;
    }
    if (prompt.type === "expression-build") {
      return Math.max(0, Math.min(9999, prompt.target ?? 0));
    }
    if (prompt.type === "number-sequence") {
      const correct = prompt.tiles.find((tile) => tile.isCorrect)?.value ?? 0;
      return Math.max(0, Math.min(9999, correct));
    }
    const total = prompt.tiles.filter((tile) => tile.isCorrect).reduce((sum, tile) => sum + (tile.value ?? 0), 0);
    return Math.max(0, Math.min(9999, total));
  }

  private operationDefinitions(): OperationDefinition[] {
    return [
      { label: "+ 6", apply: (value: number) => value + 6 },
      { label: "- 4", apply: (value: number) => value - 4 },
      { label: "x 2", apply: (value: number) => value * 2 },
      { label: "x 3", apply: (value: number) => value * 3 },
      { label: ": 2", apply: (value: number) => value / 2, valid: (value: number) => value % 2 === 0 },
      { label: ": 3", apply: (value: number) => value / 3, valid: (value: number) => value % 3 === 0 },
    ];
  }

  private evaluateOperationRoute(start: number, label: string): number | undefined {
    const operations = this.operationDefinitions();
    let value = start;
    for (const part of label.split(" poi ").map((item) => item.trim())) {
      const operation = operations.find((candidate) => candidate.label === part);
      if (!operation || (operation.valid && !operation.valid(value))) {
        return undefined;
      }
      value = operation.apply(value);
    }
    return value;
  }
}
