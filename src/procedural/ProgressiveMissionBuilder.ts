import type {
  DifficultyLevel,
  GeneratedFocusChallenge,
  GeneratedMission,
  GeneratedObjective,
  GeneratedRoomHotspot,
  ProceduralPuzzleKind,
  ProceduralSpecialization,
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

const sequencePositions: Array<{ x: number; y: number; radius: number }> = [
  { x: 312, y: 236, radius: 50 },
  { x: 640, y: 218, radius: 54 },
  { x: 914, y: 236, radius: 50 },
  { x: 438, y: 488, radius: 50 },
  { x: 842, y: 488, radius: 50 },
  { x: 640, y: 356, radius: 54 },
];

const levelFocuses: Record<DifficultyLevel, ProceduralSpecialization> = {
  1: "italiano",
  2: "matematica",
  3: "inglese",
  4: "coding",
  5: "elettronica",
  6: "musica",
  7: "matematica",
  8: "coding",
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
  focusForLevel(level: DifficultyLevel): ProceduralSpecialization {
    return levelFocuses[level];
  }

  buildLevelMission(base: GeneratedMission, level: DifficultyLevel): GeneratedMission {
    const random = new Random(`${base.seed}:progressive:${level}`);
    const focusSequence = base.focusChallenges?.length ? base.focusChallenges : undefined;
    const selected = focusSequence ? [] : this.selectDisciplines(random, level);
    const objectives = focusSequence
      ? focusSequence.map((challenge) => this.objectiveForChallenge(challenge))
      : selected.map((kind) => this.objectiveFor(base, kind));
    const hotspots = focusSequence
      ? focusSequence.map((challenge, index) => this.hotspotForChallenge(challenge, index))
      : selected.map((kind) => this.hotspotFor(kind));
    const pathLabel = focusSequence
      ? focusSequence.map((challenge) => challenge.title.toLowerCase()).join(" -> ")
      : selected.map((kind) => disciplineLabels[kind].label.toLowerCase()).join(", ");
    return {
      ...base,
      id: `mission-progressive-level-${level}`,
      title: `Scalata dell'Accademia - Livello ${level}`,
      intro: [
        `Livello ${level}/8: la stanza propone una sequenza guidata a difficolta crescente.`,
        "Completa ogni console entro tempo e vite. Il livello successivo si sblocca solo con successo.",
        `Sequenza: ${pathLabel}.`,
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

  private objectiveForChallenge(challenge: GeneratedFocusChallenge): GeneratedObjective {
    return {
      id: `procedural-${challenge.id}`,
      label: challenge.title,
      description: challenge.description,
      competencies: challenge.puzzle.competencies,
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

  private hotspotForChallenge(challenge: GeneratedFocusChallenge, index: number): GeneratedRoomHotspot {
    const position = sequencePositions[index] ?? sequencePositions[sequencePositions.length - 1];
    return {
      id: challenge.id,
      label: challenge.title,
      x: position.x,
      y: position.y,
      radius: position.radius,
      puzzleId: challenge.id,
      puzzleKind: challenge.kind,
      description: challenge.description,
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
