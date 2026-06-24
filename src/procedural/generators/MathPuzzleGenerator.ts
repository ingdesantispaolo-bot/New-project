import { mathTemplates } from "../../data/procedural/mathTemplates";
import type {
  DifficultyPreset,
  EquationLabStage,
  GeneratedGraphWorkshop,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  MathMinigamePrompt,
  MathMinigameTile,
  MathMinigameType,
} from "../ProceduralTypes";
import type { Random } from "../Random";

function clampNumber(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
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
        "Formato risposta: modifica i parametri con i controlli grafici, osserva la curva in tempo reale e certifica quando soddisfa tutti i vincoli.",
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
    return {
      mode: "beacon-line",
      functionKind: "linear",
      objective: `Regola pendenza e intercetta finché la retta attraversa entrambi i beacon A e B.`,
      targetFormula: this.linearFormula(m, q),
      principle: "In y = mx + q, m controlla inclinazione e verso; q è il punto in cui la retta incontra l'asse y.",
      parameters: [
        { key: "m", label: "m", meaning: "pendenza: variazione verticale per ogni passo orizzontale", min: -slopeLimit, max: slopeLimit, step: 1, target: m, initial: initialM },
        { key: "q", label: "q", meaning: "intercetta sull'asse y", min: -interceptLimit, max: interceptLimit, step: 1, target: q, initial: initialQ },
      ],
      targetPoints: [
        { x: firstX, y: m * firstX + q, label: "A" },
        { x: secondX, y: m * secondX + q, label: "B" },
      ],
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-14, 14],
      successExplanation: `La retta ${this.linearFormula(m, q)} attraversa entrambi i punti; la variazione tra A e B conferma m = ${m}.`,
    };
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
        "Dopo aver regolato m, usa q per traslare la retta senza cambiarne l'inclinazione.",
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
