import { circuitFaultTemplates } from "../../data/procedural/circuitTemplates";
import type {
  CircuitFaultType,
  GeneratedCodingMinigame,
  GeneratedCodingPuzzle,
  GeneratedEnglishMinigame,
  GeneratedEnglishPuzzle,
  GeneratedLanguageMinigame,
  GeneratedLanguagePuzzle,
  GeneratedMathMinigame,
  GeneratedMathPuzzle,
  GeneratedMusicPuzzle,
  GridCommand,
  MusicMinigameType,
} from "../../procedural/ProceduralTypes";
import { Random } from "../../procedural/Random";

// --- Display label tables (pure data) ---------------------------------------

export const commandLabels: Record<GridCommand, string> = {
  MOVE_FORWARD: "Avanza",
  TURN_LEFT: "Gira SX",
  TURN_RIGHT: "Gira DX",
  PICK_UP: "Raccogli",
  EXIT: "Esci",
};

export const faultLabels: Record<CircuitFaultType, string> = Object.fromEntries(
  circuitFaultTemplates.map((fault) => [fault.type, fault.label]),
) as Record<CircuitFaultType, string>;

export const repairLabels: Record<CircuitFaultType, string> = {
  "missing-wire": "Collega filo",
  "open-switch": "Chiudi switch",
  "reversed-led": "Inverti LED",
  "missing-resistor": "Inserisci R",
  "disconnected-component": "Ricollega",
  "sensor-unpowered": "Alimenta sensore",
  "capacitor-discharged": "Carica condens.",
  "short-circuit": "Isola corto",
  "parallel-branch-open": "Chiudi ramo B",
  "wrong-resistor-value": "Cambia valore R",
  "relay-not-armed": "Arma relè",
  "loose-ground": "Fissa massa",
};

// --- Focus training session shapes ------------------------------------------

export type MusicTrainingSession = {
  puzzleId: string;
  random: Random;
  current: GeneratedMusicPuzzle;
  startedAt: number;
  durationMs: number;
  questionStartedAt: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  recentSignatures: string[];
  modeRotation: MusicMinigameType[];
  modeIndex: number;
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

export type MathMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedMathPuzzle;
  game: GeneratedMathMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

export type LanguageMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedLanguagePuzzle;
  game: GeneratedLanguageMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  /** Ordered tile ids for the "word-order" (Ricomponi la frase) minigame. */
  orderedSelection: string[];
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

export type EnglishMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedEnglishPuzzle;
  game: GeneratedEnglishMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  /** Ordered tile ids for the "sentence-build" minigame. */
  orderedSelection: string[];
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};

export type CodingMinigameSession = {
  puzzleId: string;
  puzzle: GeneratedCodingPuzzle;
  game: GeneratedCodingMinigame;
  startedAt: number;
  durationMs: number;
  promptIndex: number;
  answered: number;
  correct: number;
  wrong: number;
  streak: number;
  bestStreak: number;
  netScore: number;
  selectedIds: Set<string>;
  feedback: string;
  locked: boolean;
  summaryOpen: boolean;
};
