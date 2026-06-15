export type CircuitPuzzleDefinition = {
  id: string;
  title: string;
  requiredParts: string[];
  optionalWarnings: {
    missingResistance: string;
    reversedLed: string;
  };
};

export type MathPuzzleDefinition = {
  id: string;
  prompt: string;
  answer: number;
  hints: string[];
  nearMisses?: Array<{
    value: number;
    feedback: string;
  }>;
};

export type RobotCommand = "MOVE_FORWARD" | "TURN_LEFT" | "TURN_RIGHT" | "PICK_UP";

export type RobotPuzzleDefinition = {
  id: string;
  grid: {
    cols: number;
    rows: number;
    start: { col: number; row: number; facing: "N" | "E" | "S" | "W" };
    key: { col: number; row: number };
    obstacles: Array<{ col: number; row: number }>;
  };
  commands: RobotCommand[];
  idealLength: number;
};

export type GrammarRepairDefinition = {
  id: string;
  corrupted: string;
  repaired: string;
  options: string[];
  diagnosticSteps: string[];
  hints: string[];
  maxAttemptsBeforeReview: number;
};

export type EnglishInstructionDefinition = {
  id: string;
  instruction: string;
  choices: Array<{
    id: string;
    label: string;
    isCorrect: boolean;
    feedback: string;
  }>;
  diagnosticSteps: string[];
  hint: string;
  maxAttemptsBeforeReview: number;
};
