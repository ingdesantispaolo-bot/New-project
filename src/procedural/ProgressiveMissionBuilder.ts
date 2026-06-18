import type {
  DifficultyLevel,
  GeneratedMission,
  GeneratedObjective,
  GeneratedRoomHotspot,
  ProceduralPuzzleKind,
} from "./ProceduralTypes";
import { Random } from "./Random";

type ProgressiveDiscipline = Exclude<ProceduralPuzzleKind, "robot">;

const disciplineLabels: Record<ProgressiveDiscipline, { label: string; description: string }> = {
  language: {
    label: "Ripara il segnale",
    description: "Sistema un messaggio tecnico: forma e significato devono restare operativi.",
  },
  circuit: {
    label: "Diagnostica energia",
    description: "Leggi sintomi e componenti prima di scegliere l'intervento sul circuito.",
  },
  math: {
    label: "Calcola il codice",
    description: "Usa un ragionamento numerico verificabile, non tentativi a caso.",
  },
  english: {
    label: "Decodifica comando",
    description: "Trasforma l'istruzione inglese in una scelta sicura.",
  },
  coding: {
    label: "Verifica algoritmo",
    description: "Segui righe, variabili, condizioni o debug per prevedere il sistema.",
  },
  music: {
    label: "Leggi il pentagramma",
    description: "Riconosci la nota dal segno sul pentagramma prima che il timer prema.",
  },
};

const disciplinePositions: Record<ProgressiveDiscipline, { x: number; y: number; radius: number }> = {
  language: { x: 382, y: 472, radius: 42 },
  circuit: { x: 312, y: 256, radius: 52 },
  math: { x: 640, y: 220, radius: 56 },
  english: { x: 914, y: 254, radius: 50 },
  coding: { x: 914, y: 502, radius: 54 },
  music: { x: 640, y: 502, radius: 52 },
};

const levelPools: Record<DifficultyLevel, ProgressiveDiscipline[]> = {
  1: ["language", "math", "english"],
  2: ["language", "math", "english", "circuit"],
  3: ["math", "english", "coding", "circuit"],
  4: ["language", "math", "coding", "music"],
  5: ["circuit", "math", "english", "coding", "music"],
  6: ["language", "circuit", "math", "english", "coding"],
  7: ["circuit", "math", "english", "coding", "music"],
  8: ["language", "circuit", "math", "english", "coding", "music"],
};

export class ProgressiveMissionBuilder {
  buildLevelMission(base: GeneratedMission, level: DifficultyLevel): GeneratedMission {
    const random = new Random(`${base.seed}:progressive:${level}`);
    const selected = this.selectDisciplines(random, level);
    const objectives = selected.map((kind) => this.objectiveFor(base, kind));
    const hotspots = selected.map((kind) => this.hotspotFor(kind));
    return {
      ...base,
      id: `mission-progressive-level-${level}`,
      title: `Scalata dell'Accademia - Livello ${level}`,
      intro: [
        `Livello ${level}/8: la stanza sceglie discipline diverse e aumenta la pressione.`,
        "Completa tutte le console entro il tempo. Il livello successivo si sblocca solo con successo.",
        `Percorso guidato: ${selected.map((kind) => disciplineLabels[kind].label.toLowerCase()).join(", ")}.`,
      ].join(" "),
      objectives,
      map: {
        ...base.map,
        id: `progressive-room-${level}`,
        title: this.roomTitle(level),
        hotspots: [
          ...hotspots,
          {
            id: "door",
            label: "Porta di livello",
            x: 610,
            y: 504,
            radius: 64,
            description: "Si apre solo quando tutte le console del livello sono coerenti.",
          },
        ],
      },
      competencies: Array.from(new Set(objectives.flatMap((objective) => objective.competencies))),
      rewards: [
        {
          badgeId: `scalata-livello-${level}`,
          label: `Stanza ${level} stabilizzata`,
          description: "Ha superato una stanza interdisciplinare a difficoltà crescente.",
        },
        ...base.rewards,
      ],
    };
  }

  timeLimitMs(level: DifficultyLevel, objectiveCount: number): number {
    const secondsPerObjective = Math.max(34, 74 - level * 5);
    return Math.max(145, objectiveCount * secondsPerObjective + 35) * 1000;
  }

  private selectDisciplines(random: Random, level: DifficultyLevel): ProgressiveDiscipline[] {
    const pool = levelPools[level];
    const targetCount = Math.min(pool.length, level <= 1 ? 3 : level <= 4 ? 4 : level <= 7 ? 5 : 6);
    const mustHave: ProgressiveDiscipline[] = level >= 5 ? ["math", "coding"] : level >= 3 ? ["math"] : [];
    const rest = random.shuffle(pool.filter((kind) => !mustHave.includes(kind)));
    return [...mustHave, ...rest].slice(0, targetCount);
  }

  private objectiveFor(base: GeneratedMission, kind: ProgressiveDiscipline): GeneratedObjective {
    const puzzle = base.puzzles[kind];
    return {
      id: `procedural-${kind}`,
      label: disciplineLabels[kind].label,
      description: disciplineLabels[kind].description,
      competencies: puzzle.competencies,
    };
  }

  private hotspotFor(kind: ProgressiveDiscipline): GeneratedRoomHotspot {
    const position = disciplinePositions[kind];
    return {
      id: kind,
      label: disciplineLabels[kind].label,
      x: position.x,
      y: position.y,
      radius: position.radius,
      puzzleId: kind,
      puzzleKind: kind,
      description: disciplineLabels[kind].description,
    };
  }

  private roomTitle(level: DifficultyLevel): string {
    return [
      "Sala delle Tracce",
      "Sala dei Vincoli",
      "Galleria dei Sistemi",
      "Nucleo delle Decisioni",
      "Anello dei Codici",
      "Camera delle Interferenze",
      "Osservatorio Critico",
      "Nucleo dell'Accademia",
    ][level - 1];
  }
}

export const progressiveMissionBuilder = new ProgressiveMissionBuilder();
