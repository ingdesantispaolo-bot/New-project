import type {
  CircuitPuzzleDefinition,
  EnglishInstructionDefinition,
  GrammarRepairDefinition,
  MathPuzzleDefinition,
  RobotPuzzleDefinition,
} from "../types/puzzleTypes";

export const circuitPuzzle: CircuitPuzzleDefinition = {
  id: "mission1.circuit",
  title: "Pannello elettrico ausiliario",
  requiredParts: ["battery", "switch", "resistor", "led", "wire"],
  optionalWarnings: {
    missingResistance: "Il LED si accende in modo instabile: una resistenza lo protegge dalla corrente eccessiva.",
    reversedLed: "Il LED sembra muto: prova a invertire la polarità, non tutti i componenti sono simmetrici.",
  },
};

export const mathLockPuzzle: MathPuzzleDefinition = {
  id: "mission1.mathLock",
  prompt: "Codice operativo: quadruplo di 9, meno il doppio di 7, poi dividi il risultato per 2.",
  answer: 11,
  hints: [
    "Quadruplo di 9 significa 9 x 4.",
    "Doppio di 7 significa 14: sottrai 14 dal risultato precedente.",
    "Il valore rimasto va diviso in due camere uguali.",
  ],
  nearMisses: [
    {
      value: 22,
      feedback: "Hai trovato il valore prima dell'ultima camera: manca la divisione finale per 2.",
    },
    {
      value: 29,
      feedback: "Hai tolto 7 invece del doppio di 7. Il terminale chiede di usare 14.",
    },
    {
      value: 4,
      feedback: "Hai diviso il quadruplo prima di sottrarre il doppio: il terminale chiede prima meno 14, poi metà del risultato.",
    },
  ],
};

export const robotPuzzle: RobotPuzzleDefinition = {
  id: "mission1.robot",
  grid: {
    cols: 6,
    rows: 5,
    start: { col: 0, row: 4, facing: "E" },
    key: { col: 5, row: 1 },
    obstacles: [
      { col: 2, row: 4 },
      { col: 2, row: 3 },
      { col: 3, row: 2 },
      { col: 4, row: 2 },
    ],
  },
  commands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "PICK_UP"],
  idealLength: 11,
};

export const grammarRepairPuzzle: GrammarRepairDefinition = {
  id: "mission1.grammarRepair",
  corrupted: "Il generatori principale sono spento e il luce rossa lampeggiano.",
  repaired: "Il generatore principale è spento e la luce rossa lampeggia.",
  options: [
    "Il generatore principale è spento e la luce rossa lampeggia.",
    "I generatori principali è spento e la luce rossa lampeggia.",
    "Il generatore principale sono spenti e la luce rossa lampeggia.",
    "Il generatore principale è spento e il luce rosso lampeggia.",
  ],
  diagnosticSteps: [
    "Il messaggio descrive un solo generatore: cerca un soggetto singolare.",
    "Il generatore ha un aggettivo tecnico: anche quello deve concordare.",
    "La seconda parte parla della luce rossa: articolo, nome, colore e verbo devono stare insieme.",
  ],
  hints: [
    "Controlla prima il gruppo 'generatore principale': è singolare.",
    "Non basta correggere il primo verbo: anche 'luce rossa lampeggia' deve essere stabile.",
    "Se una parola sembra quasi giusta, verifica articolo e verbo della stessa parte di frase.",
  ],
  maxAttemptsBeforeReview: 2,
};

export const englishInstructionPuzzle: EnglishInstructionDefinition = {
  id: "mission1.englishInstruction",
  instruction: "Open the blue cover, then press the green button. Do not press the red emergency button.",
  choices: [
    {
      id: "blue-cover-green-button",
      label: "Blue cover -> Green",
      isCorrect: true,
      feedback: "Sequenza corretta: prima apri il coperchio blu, poi premi il verde.",
    },
    {
      id: "green-only",
      label: "Green subito",
      isCorrect: false,
      feedback: "Il comando non dice solo di premere il verde: prima richiede di aprire il coperchio blu.",
    },
    {
      id: "red-emergency",
      label: "Red emergency",
      isCorrect: false,
      feedback: "La frase contiene un divieto esplicito: Do not press the red emergency button.",
    },
    {
      id: "blue-cover-red-button",
      label: "Blue cover -> Red",
      isCorrect: false,
      feedback: "La prima azione è corretta, ma dopo il coperchio il pulsante autorizzato è verde.",
    },
  ],
  diagnosticSteps: [
    "Open indica l'azione di preparazione.",
    "Then indica l'ordine: dopo il coperchio arriva il pulsante.",
    "Do not press segnala un divieto, non un'alternativa.",
  ],
  hint: "Cerca tre parole-chiave: Open, then, Do not.",
  maxAttemptsBeforeReview: 2,
};
