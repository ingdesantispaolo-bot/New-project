import type {
  DifficultyLevel,
  ProceduralPuzzleScore,
  ProceduralScoreSummary,
  ProceduralSpecialization,
} from "../procedural/ProceduralTypes";

export type ScoreInput = {
  puzzleId: string;
  difficulty: DifficultyLevel;
  focus: string[];
  startedAt: string;
  completedAt: string;
  hintsUsed: number;
  attempts: number;
};

const puzzleDomains: Record<string, ProceduralSpecialization> = {
  language: "italiano",
  circuit: "elettronica",
  math: "matematica",
  english: "inglese",
  robot: "coding",
  coding: "coding",
  music: "musica",
  physics: "fisica",
};

const expectedSeconds: Record<string, number> = {
  language: 95,
  circuit: 150,
  math: 120,
  english: 85,
  robot: 180,
  coding: 100,
  music: 45,
  physics: 115,
};

const domainLabels: Record<ProceduralSpecialization, string> = {
  libera: "missione libera",
  matematica: "matematica",
  italiano: "italiano",
  inglese: "inglese",
  elettronica: "elettronica",
  coding: "coding",
  musica: "musica",
  fisica: "fisica",
};

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function elapsedMs(startedAt: string, completedAt: string): number {
  const elapsed = new Date(completedAt).getTime() - new Date(startedAt).getTime();
  return Math.max(1_000, Number.isFinite(elapsed) ? elapsed : 1_000);
}

function focusMatchesPuzzle(focus: string[], puzzleId: string): boolean {
  const domain = domainForPuzzle(puzzleId);
  return focus.includes(domain) || focus.some((item) => item.startsWith(`${domain}.`));
}

function basePuzzleId(puzzleId: string): string {
  return Object.keys(puzzleDomains).find((candidate) => puzzleId === candidate || puzzleId.startsWith(`${candidate}-`)) ?? puzzleId;
}

function domainForPuzzle(puzzleId: string): ProceduralSpecialization {
  return puzzleDomains[basePuzzleId(puzzleId)] ?? "libera";
}

function feedbackFor(speedBonus: number, hintsUsed: number, focusBonus: number): string {
  if (focusBonus > 0 && speedBonus >= 12 && hintsUsed === 0) {
    return "Padronanza alta: hai lavorato con precisione nel tuo focus senza appoggi esterni.";
  }
  if (speedBonus >= 12) {
    return "Ragionamento fluido: la soluzione è arrivata mantenendo il controllo dei passaggi.";
  }
  if (hintsUsed > 1) {
    return "Percorso guidato: hai usato supporti, ma hai comunque completato la diagnosi.";
  }
  return "Percorso accurato: il tempo è stato usato per osservare e consolidare.";
}

export function formatDuration(ms: number): string {
  const totalSeconds = Math.max(0, Math.round(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
}

export class ProceduralScoring {
  calculate(input: ScoreInput): ProceduralPuzzleScore {
    const domain = domainForPuzzle(input.puzzleId);
    const elapsed = elapsedMs(input.startedAt, input.completedAt);
    const expected = (expectedSeconds[basePuzzleId(input.puzzleId)] ?? 120) * (1 + input.difficulty * 0.16);
    const elapsedSecondsValue = elapsed / 1000;
    const basePoints = 70;
    const difficultyBonus = input.difficulty * 14;
    // Time is a small fluency bonus, never the main source of the score.
    const speedBonus = clamp(Math.round((expected / elapsedSecondsValue) * 7), 0, 16);
    const focusBonus = focusMatchesPuzzle(input.focus, input.puzzleId) ? 20 + input.difficulty * 3 : 0;
    const supportPenalty = Math.min(28, input.hintsUsed * 6 + Math.max(0, input.attempts - 1) * 4);
    const total = Math.max(25, basePoints + difficultyBonus + speedBonus + focusBonus - supportPenalty);

    return {
      puzzleId: input.puzzleId,
      domain,
      startedAt: input.startedAt,
      completedAt: input.completedAt,
      elapsedMs: elapsed,
      hintsUsed: input.hintsUsed,
      attempts: input.attempts,
      basePoints,
      difficultyBonus,
      speedBonus,
      focusBonus,
      supportPenalty,
      total,
      feedback: feedbackFor(speedBonus, input.hintsUsed, focusBonus),
    };
  }

  addToSummary(previous: ProceduralScoreSummary | undefined, score: ProceduralPuzzleScore): ProceduralScoreSummary {
    const byPuzzle = {
      ...(previous?.byPuzzle ?? {}),
      [score.puzzleId]: score.total,
    };
    const byDomain = {
      ...(previous?.byDomain ?? {}),
      [score.domain]: (previous?.byDomain?.[score.domain] ?? 0) + score.total,
    };
    return {
      total: Object.values(byPuzzle).reduce((sum, value) => sum + value, 0),
      byPuzzle,
      byDomain,
      lastAward: score,
    };
  }

  domainLabel(domain: string | undefined): string {
    return domainLabels[(domain as ProceduralSpecialization) ?? "libera"] ?? domainLabels.libera;
  }

  puzzleDomain(puzzleId: string): ProceduralSpecialization {
    return domainForPuzzle(puzzleId);
  }
}

export const proceduralScoring = new ProceduralScoring();
