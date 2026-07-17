import type { TheoryTopic } from "../../data/theoryCatalog";

export type NoraTwinExercise = {
  prompt: string;
  options: string[];
  correct: string;
  explanation: string;
};

export type NoraMicroLesson = {
  title: string;
  lens: string;
  method: string;
  example: string;
  watch: string;
  twin: NoraTwinExercise;
};

export function buildNoraMicroLesson(topic: TheoryTopic, wrongMessage: string, attempt: number): NoraMicroLesson {
  const method = topic.method[0] ?? topic.coreRules[0] ?? topic.definition;
  const watch = topic.watchOut[0] ?? "controlla che la risposta rispetti tutti i dati, non solo il primo indizio.";
  const exampleSteps = topic.example.steps.slice(0, 2).join(" -> ");
  return {
    title: topic.title,
    lens: `${topic.definition} Qui l'errore dice dove guardare: ${shorten(wrongMessage, 150)}`,
    method,
    example: `${topic.example.prompt} ${exampleSteps ? `${exampleSteps} -> ` : ""}${topic.example.answer}`,
    watch,
    twin: buildTwinExercise(topic, method, watch, attempt),
  };
}

function buildTwinExercise(topic: TheoryTopic, method: string, watch: string, attempt: number): NoraTwinExercise {
  const numeric = numericAnswer(topic.example.answer);
  if (numeric !== undefined) {
    const correct = cleanAnswer(topic.example.answer);
    return {
      prompt: `Gemello rapido: ${topic.example.prompt}`,
      options: numericDistractors(numeric, correct),
      correct,
      explanation: `Stesso schema, numeri già guidati: ${topic.example.steps.slice(0, 3).join(" -> ") || method}.`,
    };
  }

  const correct = cleanAnswer(topic.example.answer || method);
  const distractors = [
    shorten(watch, 58),
    shorten(topic.coreRules.find((rule) => cleanAnswer(rule) !== correct) ?? "Rispondo a intuito e controllo dopo.", 58),
    shorten(topic.method.find((step) => cleanAnswer(step) !== correct && step !== method) ?? "Cambio strategia senza verificare i dati.", 58),
  ].filter((item) => item && cleanAnswer(item) !== correct);

  return {
    prompt: `Gemello rapido: quale risposta o controllo chiude l'esempio "${shorten(topic.example.prompt, 82)}"?`,
    options: shuffleStable([correct, ...unique(distractors)].slice(0, 3), `${topic.id}:${attempt}`),
    correct,
    explanation: `Il gemello ripete il cuore della scheda: ${method}`,
  };
}

function numericAnswer(answer: string): number | undefined {
  const normalized = answer.replace(",", ".").match(/-?\d+(?:\.\d+)?/);
  if (!normalized) return undefined;
  const value = Number(normalized[0]);
  return Number.isFinite(value) ? value : undefined;
}

function numericDistractors(value: number, correct: string): string[] {
  const delta = Math.max(1, Math.round(Math.abs(value) * 0.12));
  const candidates = [
    correct,
    String(Math.round(value + delta)),
    String(Math.round(value - delta)),
    String(Math.round(value * 2)),
    String(Math.round(value / 2)),
  ];
  return unique(candidates.filter((candidate) => candidate !== correct || candidate === candidates[0])).slice(0, 3);
}

function cleanAnswer(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function shorten(value: string, max: number): string {
  const clean = cleanAnswer(value);
  return clean.length <= max ? clean : `${clean.slice(0, Math.max(0, max - 1)).trim()}…`;
}

function unique(values: string[]): string[] {
  return [...new Set(values.map(cleanAnswer).filter(Boolean))];
}

function shuffleStable(values: string[], seed: string): string[] {
  const items = [...values];
  let h = 2166136261;
  for (let i = 0; i < seed.length; i += 1) {
    h ^= seed.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  for (let i = items.length - 1; i > 0; i -= 1) {
    h ^= h << 13;
    h ^= h >>> 17;
    h ^= h << 5;
    const j = Math.abs(h) % (i + 1);
    [items[i], items[j]] = [items[j]!, items[i]!];
  }
  return items;
}
