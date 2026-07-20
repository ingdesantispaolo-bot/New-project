// Bake dei banchi di esercizi → godot/data/banks/*.json
//
// Fase 1 del full-Godot (vedi docs/ARCHITETTURA_FULL_GODOT.md, strategia "bake
// prima, port poi"): produce banchi JSON di ExerciseItem che Godot carica
// on-demand. Qui parte con un generatore self-contained di tabelline; in seguito
// si aggancerà ai generatori/validatori TS reali per le altre materie.
//
// Uso: node scripts/build-exercise-banks.mjs

import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { mkdir, writeFile } from "node:fs/promises";

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, "..", "godot", "data", "banks");

const shuffle = (arr, rand) => {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

// PRNG deterministico (mulberry32) così il banco è stabile tra build.
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a += 0x6d2b79f5;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Difficoltà → intervallo di fattori.
const RANGES = { 1: [2, 5], 2: [2, 10], 3: [3, 12], 4: [6, 12] };

function timesItem(a, b, difficulty, rand) {
  const answer = a * b;
  const useNumeric = rand() < 0.25;
  const explanation = `${a} × ${b} = ${answer}.`;
  const base = {
    id: `math-times-${a}x${b}-d${difficulty}`,
    subject: "matematica",
    topic: "tabelline",
    difficulty,
    prompt: `Quanto fa ${a} × ${b}?`,
    answer: String(answer),
    explanation,
  };
  if (useNumeric) return { ...base, format: "numeric_input", options: [] };
  const distractors = new Set();
  const candidates = [answer + a, answer - a, answer + b, answer - b, answer + 1, answer - 1, a * (b + 1), (a + 1) * b];
  for (const c of candidates) {
    if (c > 0 && c !== answer) distractors.add(c);
    if (distractors.size >= 3) break;
  }
  const options = shuffle([answer, ...[...distractors].slice(0, 3)], rand).map(String);
  return { ...base, format: "multiple_choice", options };
}

function tabellineBank() {
  const rand = rng(20260720);
  const items = [];
  for (const difficulty of [1, 2, 3, 4]) {
    const [lo, hi] = RANGES[difficulty];
    for (let a = lo; a <= hi; a += 1) {
      for (let b = 2; b <= hi; b += 1) {
        items.push(timesItem(a, b, difficulty, rand));
      }
    }
  }
  return { schemaVersion: 1, subject: "matematica", topic: "tabelline", generator: "tabelline-v1", items };
}

const BANKS = { "matematica-tabelline": tabellineBank() };

await mkdir(outDir, { recursive: true });
for (const [name, bank] of Object.entries(BANKS)) {
  const file = join(outDir, `${name}.json`);
  await writeFile(file, JSON.stringify(bank, null, "\t") + "\n", "utf8");
  console.log(`Banco '${name}': ${bank.items.length} item → ${file}`);
}
