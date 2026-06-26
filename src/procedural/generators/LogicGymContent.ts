import { Random } from "../Random";

export type LogicSequence = {
  kind: string;
  sequence: string[];
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
};

export type MemoryPair = { id: string; a: string; b: string; theme: string };

export type BalancePuzzle = {
  items: string[];
  clues: string[];
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
};

// -- Logic sequences (inductive reasoning) --------------------------------

type NumericRule = {
  kind: string;
  build: (r: Random, level: number) => { terms: number[]; next: number; why: string };
};

const NUMERIC_RULES: NumericRule[] = [
  {
    kind: "Progressione aritmetica",
    build: (r, level) => {
      const start = r.integer(1, 6 + level * 2);
      const step = r.integer(2, 3 + level * 2);
      const terms = Array.from({ length: 5 }, (_, i) => start + i * step);
      return { terms, next: start + 5 * step, why: `Ogni numero aumenta di ${step}.` };
    },
  },
  {
    kind: "Progressione geometrica",
    build: (r, level) => {
      const start = r.integer(1, 3);
      const ratio = level >= 3 ? r.pick([2, 3]) : 2;
      const terms = Array.from({ length: 4 }, (_, i) => start * ratio ** i);
      return { terms, next: start * ratio ** 4, why: `Ogni numero si moltiplica per ${ratio}.` };
    },
  },
  {
    kind: "Quadrati perfetti",
    build: (r) => {
      const base = r.integer(1, 3);
      const terms = Array.from({ length: 5 }, (_, i) => (base + i) ** 2);
      return { terms, next: (base + 5) ** 2, why: `Sono i quadrati: ${base}², ${base + 1}², ${base + 2}²…` };
    },
  },
  {
    kind: "Numeri triangolari",
    build: (r) => {
      const start = r.integer(1, 2);
      const term = (n: number) => (n * (n + 1)) / 2;
      const terms = Array.from({ length: 5 }, (_, i) => term(start + i));
      return { terms, next: term(start + 5), why: "Si aggiunge ogni volta un numero in più: +2, +3, +4, +5…" };
    },
  },
  {
    kind: "Sequenza di Fibonacci",
    build: (r) => {
      let a = r.integer(1, 3);
      let b = a + r.integer(1, 3);
      const terms = [a, b];
      for (let i = 0; i < 3; i += 1) {
        const c = a + b;
        terms.push(c);
        a = b;
        b = c;
      }
      return { terms, next: a + b, why: "Ogni numero è la somma dei due precedenti." };
    },
  },
  {
    kind: "Passo alternato",
    build: (r, level) => {
      const start = r.integer(1, 6);
      const up = r.integer(2, 3 + level);
      const down = r.integer(1, up - 1 < 1 ? 1 : up - 1);
      const terms = [start];
      for (let i = 1; i < 6; i += 1) {
        terms.push(terms[i - 1] + (i % 2 === 1 ? up : -down));
      }
      const lastWasUp = (6 - 1) % 2 === 1;
      return { terms, next: terms[5] + (lastWasUp ? -down : up), why: `Si alternano +${up} e -${down}.` };
    },
  },
];

export class LogicSequenceGenerator {
  generate(random: Random, level = 1): LogicSequence {
    // Figural pattern about a third of the time for variety.
    if (random.integer(1, 3) === 1) {
      return this.figural(random, level);
    }
    const rule = random.pick(NUMERIC_RULES);
    const { terms, next, why } = rule.build(random.fork(rule.kind), level);
    const options = this.numericOptions(random.fork("opt"), next);
    return {
      kind: rule.kind,
      sequence: terms.map(String),
      question: "Quale numero continua la serie?",
      options: options.labels,
      correctIndex: options.correctIndex,
      explanation: `${rule.kind}: ${why} Quindi viene ${next}.`,
    };
  }

  private numericOptions(random: Random, correct: number): { labels: string[]; correctIndex: number } {
    const values = new Set<number>([correct]);
    const deltas = [1, -1, 2, -2, 3, correct > 6 ? Math.round(correct / 2) : 4];
    let guard = 0;
    while (values.size < 4 && guard < 40) {
      const delta = random.pick(deltas) * random.pick([1, 1, 2]);
      const candidate = correct + delta;
      if (candidate > 0) {
        values.add(candidate);
      }
      guard += 1;
    }
    while (values.size < 4) {
      values.add(correct + values.size);
    }
    const labels = random.shuffle(Array.from(values)).map(String);
    return { labels, correctIndex: labels.indexOf(String(correct)) };
  }

  private figural(random: Random, level: number): LogicSequence {
    const palette = ["🔺", "🟦", "🟢", "🟡", "🟣", "🟠"];
    const cycleLen = Math.min(palette.length, 2 + Math.min(2, level));
    const cycle = random.shuffle(palette).slice(0, cycleLen);
    const visible = Array.from({ length: 6 }, (_, i) => cycle[i % cycle.length]);
    const next = cycle[6 % cycle.length];
    const options = random.shuffle(cycle.slice(0, Math.max(4, cycleLen)).concat(palette).filter((value, index, arr) => arr.indexOf(value) === index)).slice(0, 4);
    if (!options.includes(next)) {
      options[0] = next;
    }
    const shuffled = random.shuffle(options);
    return {
      kind: "Schema figurale",
      sequence: visible,
      question: "Quale figura continua lo schema?",
      options: shuffled,
      correctIndex: shuffled.indexOf(next),
      explanation: `Lo schema si ripete ogni ${cycle.length} figure: ${cycle.join(" ")}. Dopo viene ${next}.`,
    };
  }
}

// -- Memory pairs (visual memory + cross-domain knowledge) -----------------

const PAIR_POOL: MemoryPair[] = [
  { id: "frac-half", a: "1/2", b: "0,5", theme: "Frazioni" },
  { id: "frac-quarter", a: "1/4", b: "0,25", theme: "Frazioni" },
  { id: "frac-3q", a: "3/4", b: "0,75", theme: "Frazioni" },
  { id: "frac-fifth", a: "1/5", b: "0,2", theme: "Frazioni" },
  { id: "pct-ten", a: "10%", b: "0,1", theme: "Percentuali" },
  { id: "pow-2-3", a: "2³", b: "8", theme: "Potenze" },
  { id: "pow-5-2", a: "5²", b: "25", theme: "Potenze" },
  { id: "root-81", a: "√81", b: "9", theme: "Radici" },
  { id: "root-144", a: "√144", b: "12", theme: "Radici" },
  { id: "mul-78", a: "7×8", b: "56", theme: "Tabelline" },
  { id: "mul-96", a: "9×6", b: "54", theme: "Tabelline" },
  { id: "geo-tri", a: "Triangolo", b: "3 lati", theme: "Geometria" },
  { id: "geo-pent", a: "Pentagono", b: "5 lati", theme: "Geometria" },
  { id: "geo-hex", a: "Esagono", b: "6 lati", theme: "Geometria" },
  { id: "en-dog", a: "dog", b: "cane", theme: "Inglese" },
  { id: "en-water", a: "water", b: "acqua", theme: "Inglese" },
  { id: "en-book", a: "book", b: "libro", theme: "Inglese" },
  { id: "en-three", a: "three", b: "tre", theme: "Inglese" },
  { id: "mus-la", a: "LA", b: "A", theme: "Musica" },
  { id: "mus-do", a: "DO", b: "C", theme: "Musica" },
  { id: "mus-sol", a: "SOL", b: "G", theme: "Musica" },
  { id: "unit-km", a: "1 km", b: "1000 m", theme: "Misure" },
  { id: "unit-h", a: "1 h", b: "60 min", theme: "Misure" },
  { id: "unit-kg", a: "1 kg", b: "1000 g", theme: "Misure" },
];

export function buildMemoryPairs(random: Random, count: number): MemoryPair[] {
  return random.shuffle(PAIR_POOL).slice(0, Math.min(count, PAIR_POOL.length));
}

// -- Balance puzzles (deductive reasoning) --------------------------------

const BALANCE_ITEMS = ["🐘", "🦏", "🦛", "🐻", "🐶", "🐱", "🐰", "🐭"];

/**
 * Builds a transitive "who weighs more" deduction. A full adjacent chain of
 * clues guarantees the order is deducible; the clues are shuffled (and phrased
 * both ways) so the player must actually reason rather than read the answer.
 */
export function generateBalance(random: Random, level = 1): BalancePuzzle {
  const count = level >= 3 ? 4 : 3;
  const items = random.shuffle(BALANCE_ITEMS).slice(0, count);
  // weights[i] = rank; we build a strict order by shuffling the picked items.
  const ordered = random.shuffle(items); // ordered[0] is heaviest ... last lightest
  const clues: string[] = [];
  for (let i = 0; i < ordered.length - 1; i += 1) {
    const heavier = ordered[i];
    const lighter = ordered[i + 1];
    clues.push(random.integer(0, 1) === 0
      ? `${heavier} è più pesante di ${lighter}`
      : `${lighter} è più leggero di ${heavier}`);
  }
  const shuffledClues = random.shuffle(clues);

  const askHeaviest = random.integer(0, 1) === 0;
  const correct = askHeaviest ? ordered[0] : ordered[ordered.length - 1];
  const options = random.shuffle(items);
  return {
    items,
    clues: shuffledClues,
    question: askHeaviest ? "Chi è il più PESANTE?" : "Chi è il più LEGGERO?",
    options,
    correctIndex: options.indexOf(correct),
    explanation: `Mettendo in fila gli indizi: ${ordered.join(" > ")}. Quindi il più ${askHeaviest ? "pesante" : "leggero"} è ${correct}.`,
  };
}
