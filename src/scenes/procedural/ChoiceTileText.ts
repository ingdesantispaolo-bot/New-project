const REASON_TEXT: Record<string, string> = {
  "readiness now": "shows readiness now",
  "completed past action": "talks about a past action",
  "unrelated topic": "does not answer the situation",
  "polite permission + object": "gives polite permission",
  "past time": "uses the wrong time",
  "place preposition": "talks about place, not reply",
  "keep closed repeats the instruction": "matches the instruction",
  "question form only": "only asks a question",
  "polite request with could": "uses a polite request",
  "command too direct": "sounds too direct",
  "wrong word order": "has wrong word order",
  "wh-question asks for proof": "asks for evidence",
  "because gives a cause": "gives a cause",
  "refusal to collaborate": "refuses to collaborate",
  "identity sentence": "answers with identity, not place",
  "collaborative suggestion": "suggests working together",
  "wrong identity": "confuses the subject",
  "past time confusion": "uses the wrong time",
  "yes/no answer": "answers yes/no, not why",
  "past-time mismatch": "uses the wrong time",
  "permission with condition": "gives permission with a condition",
  "no condition": "misses the condition",
  "past irrelevant": "uses an irrelevant past action",
  "polite interruption": "interrupts politely",
  "rude command": "is too rude",
  "asks for verification": "asks how to verify it",
  "personal attack": "attacks the person",
  "confirms deadline": "confirms the deadline",
  "time words conflict": "mixes incompatible times",
  "apology + repair action": "apologizes and repairs",
  "denies responsibility": "denies responsibility",
  "comparative adjective": "uses a comparative",
  "incomplete answer": "does not fully answer",
  "present perfect with yet": "uses not yet correctly",
  "contradictory answer": "contradicts itself",
  "conflicting time words": "mixes incompatible times",
  "opposite action": "does the opposite",
  "broken sentence": "is not a stable sentence",
  "polite request": "asks politely",
  "rude imperative": "uses a rude command",
  "time mismatch": "uses the wrong time",
  "fixed polite formula": "uses a fixed polite formula",
  "literal translation": "is a literal translation trap",
  "wrong verb": "uses the wrong verb",
  "cautious action before decision": "waits for evidence first",
  "overconfident conclusion": "concludes too early",
  "proposes next action": "proposes a useful next step",
  "unrelated adjective": "uses an unrelated adjective",
  "time conflict": "mixes incompatible times",
  "adverb of manner": "matches how to act",
  "opposite manner": "does the opposite manner",
  "polite disagreement with evidence": "disagrees politely with evidence",
  "rude personal comment": "attacks the person",
  "explains meaning in context": "explains the meaning in context",
  "unrelated meaning": "uses an unrelated meaning",
  "contrast with but": "uses contrast with but",
  "broken syntax": "has broken syntax",
  "overgeneralization": "says too much",
  "not until sets a condition": "sets a clear condition",
  "ignores condition": "ignores the condition",
  "formal clarification request": "asks formally for clarification",
  "too informal": "is too informal",
};

function choiceTileBadge(prefix: string): string {
  const key = prefix.trim().toLowerCase();
  if (key === "risposta") return "RISPOSTA";
  if (key === "motivo") return "MOTIVO";
  if (key === "prova") return "PROVA";
  if (key === "azione") return "AZIONE";
  if (key === "correzione") return "CORREZIONE";
  if (key === "diagnosi") return "DIAGNOSI";
  if (key === "traduzione") return "TRADUZIONE";
  return prefix.trim().toUpperCase();
}

function polishChoiceTileBody(prefix: string, body: string): string {
  const trimmed = body.trim();
  const lower = trimmed.toLowerCase();
  const polishedReason = REASON_TEXT[lower];
  if (polishedReason) return polishedReason;
  if (prefix.trim().toLowerCase() === "prova") {
    return trimmed
      .replace(/\s+(blocca|permette|impone|conferma|nega)\s+/u, " -> $1 ")
      .replace(/\s+(rende)\s+/u, " -> $1 ");
  }
  return trimmed;
}

export function choiceTileLabel(rawLabel: string, selected = false): string {
  const prefixMatch = rawLabel.match(/^([^:]{3,22}):\s*(.+)$/);
  if (!prefixMatch) {
    return `${selected ? "✓ " : ""}${rawLabel}`;
  }
  const badge = choiceTileBadge(prefixMatch[1]);
  const body = polishChoiceTileBody(prefixMatch[1], prefixMatch[2]);
  return `${selected ? "✓ " : ""}${badge}\n${body}`;
}

export function choiceTileFontSize(rawLabel: string, baseSize: number): number {
  const displayLabel = choiceTileLabel(rawLabel);
  const longestLine = Math.max(...displayLabel.split("\n").map((line) => line.length));
  if (longestLine > 44) return Math.max(10, baseSize - 3);
  if (longestLine > 30) return Math.max(11, baseSize - 2);
  if (longestLine > 20) return Math.max(12, baseSize - 1);
  return baseSize;
}
