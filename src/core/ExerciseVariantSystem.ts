import { greenhousePlants, type GreenhouseValues, type PlantDefinition } from "../data/greenhouse";
import { archiveEvidence, archiveInstruction, archiveMessages, type ArchiveEvidence, type ArchiveMessage, type BilingualInstruction } from "../data/wordArchive";
import { grammarRepairPuzzle, mathLockPuzzle, robotPuzzle } from "../data/puzzles";
import type { EnglishInstructionDefinition, GrammarRepairDefinition, MathPuzzleDefinition, RobotPuzzleDefinition } from "../types/puzzleTypes";
import { productionOrders, type ProductionOrder } from "../data/numberFactory";
import { Random } from "../procedural/Random";
import { numberFactorySolver } from "./NumberFactorySolver";
import { saveSystem } from "./SaveSystem";

type ArchiveVariant = {
  messages: ArchiveMessage[];
  evidence: ArchiveEvidence[];
  instruction: BilingualInstruction;
  reportKeywords: string[];
  reportPrompt: string;
};

const mathVariants: MathPuzzleDefinition[] = [
  mathLockPuzzle,
  {
    id: "mission1.mathLock.variant.energy-27",
    prompt: "Codice operativo: triplo di 11, meno 9, poi aggiungi la metà di 6.",
    answer: 27,
    hints: ["Triplo di 11 significa 11 x 3.", "Sottrai 9 dal risultato.", "La metà di 6 è 3: aggiungila solo alla fine."],
    nearMisses: [
      { value: 24, feedback: "Hai triplicato e sottratto, ma manca la metà di 6." },
      { value: 30, feedback: "Sembra che tu abbia aggiunto 6 intero: il terminale chiede metà di 6." },
      { value: 36, feedback: "Hai aggiunto invece di sottrarre 9. Il raffreddamento toglie energia." },
    ],
  },
  {
    id: "mission1.mathLock.variant.compressor-17",
    prompt: "Codice operativo: doppio di 14, dividi per 4, poi aggiungi 10.",
    answer: 17,
    hints: ["Prima raddoppia 14.", "Dividi il risultato in 4 camere uguali.", "Solo dopo aggiungi 10."],
    nearMisses: [
      { value: 7, feedback: "Hai diviso correttamente, ma manca l'aggiunta finale di 10." },
      { value: 24, feedback: "Hai aggiunto 10 troppo presto: prima il doppio va diviso per 4." },
      { value: 38, feedback: "Il terminale non chiede solo doppio più 10: c'è una divisione nel mezzo." },
    ],
  },
  {
    id: "mission1.mathLock.variant.relay-31",
    prompt: "Codice operativo: somma 18 e 7, raddoppia il risultato, poi togli 19.",
    answer: 31,
    hints: ["Prima somma 18 e 7.", "Raddoppia tutta la somma, non solo il 7.", "Infine sottrai 19."],
    nearMisses: [
      { value: 50, feedback: "Hai raddoppiato la somma, ma manca la sottrazione finale." },
      { value: 13, feedback: "Hai sottratto 19 prima di raddoppiare: l'ordine dei moduli è diverso." },
      { value: 39, feedback: "Sembra che tu abbia raddoppiato solo il 7: il raddoppio riguarda tutta la somma." },
    ],
  },
];

const grammarVariants: GrammarRepairDefinition[] = [
  grammarRepairPuzzle,
  {
    id: "mission1.grammarRepair.variant.sensor",
    corrupted: "La sensori centrale indicano valori instabile e il porta resta bloccati.",
    repaired: "Il sensore centrale indica valori instabili e la porta resta bloccata.",
    options: [
      "Il sensore centrale indica valori instabili e la porta resta bloccata.",
      "La sensore centrale indica valori instabili e il porta resta bloccati.",
      "Il sensore centrale indicano valori instabili e la porta resta bloccata.",
      "Il sensore centrale indica valore instabile e le porte resta bloccata.",
    ],
    diagnosticSteps: [
      "Il sensore è uno solo: articolo e verbo devono essere singolari.",
      "I valori sono plurali, quindi l'aggettivo diventa instabili.",
      "La porta è femminile singolare: resta bloccata.",
    ],
    hints: ["Trova prima il soggetto principale.", "Non confondere il plurale valori con il sensore.", "Controlla anche il gruppo della porta."],
    maxAttemptsBeforeReview: 2,
  },
  {
    id: "mission1.grammarRepair.variant.battery",
    corrupted: "Le batteria secondaria sono carichi ma il led restano spenti.",
    repaired: "La batteria secondaria è carica ma il LED resta spento.",
    options: [
      "La batteria secondaria è carica ma il LED resta spento.",
      "Le batterie secondarie è carica ma il LED resta spento.",
      "La batteria secondaria sono cariche ma il LED resta spento.",
      "La batteria secondaria è carica ma i LED resta spento.",
    ],
    diagnosticSteps: [
      "La frase parla di una batteria secondaria.",
      "Batteria è femminile singolare: è carica.",
      "Il LED indicato è uno solo: resta spento.",
    ],
    hints: ["Il sistema non vuole cambiare quantità: una batteria, un LED.", "Correggi genere e numero senza modificare il senso tecnico."],
    maxAttemptsBeforeReview: 2,
  },
];

const englishVariants: EnglishInstructionDefinition[] = [
  {
    ...archiveInstructionToEnglish(archiveInstruction),
    id: "mission1.englishInstruction.archive-like",
  },
  {
    id: "mission1.englishInstruction.blue-green-red",
    instruction: "Open the blue cover, then press the green button. Do not press the red emergency button.",
    choices: [
      { id: "blue-cover-green-button", label: "Blue cover -> Green", isCorrect: true, feedback: "Sequenza corretta: prima apri il coperchio blu, poi premi il verde." },
      { id: "green-only", label: "Green subito", isCorrect: false, feedback: "Il comando non dice solo di premere il verde: prima richiede di aprire il coperchio blu." },
      { id: "red-emergency", label: "Red emergency", isCorrect: false, feedback: "La frase contiene un divieto esplicito: Do not press the red emergency button." },
      { id: "blue-cover-red-button", label: "Blue cover -> Red", isCorrect: false, feedback: "La prima azione è corretta, ma dopo il coperchio il pulsante autorizzato è verde." },
    ],
    diagnosticSteps: ["Open indica preparazione.", "Then impone l'ordine.", "Do not press segnala il divieto."],
    hint: "Cerca tre segnali: Open, then, Do not.",
    maxAttemptsBeforeReview: 2,
  },
  {
    id: "mission1.englishInstruction.key-switch",
    instruction: "Take the small key, then turn on the main switch. Do not take the large key.",
    choices: [
      { id: "small-key-main-switch", label: "Small key -> Main switch", isCorrect: true, feedback: "Hai rispettato oggetto piccolo e ordine operativo." },
      { id: "large-key-main-switch", label: "Large key -> Main switch", isCorrect: false, feedback: "Large key è proprio l'oggetto vietato." },
      { id: "switch-first", label: "Main switch -> Small key", isCorrect: false, feedback: "Then indica che l'interruttore arriva dopo la chiave piccola." },
      { id: "take-both", label: "Take both keys", isCorrect: false, feedback: "Do not take limita la seconda chiave." },
    ],
    diagnosticSteps: ["Take indica prendere.", "Small distingue la chiave corretta.", "Then ordina le azioni.", "Do not take vieta la chiave grande."],
    hint: "Non basta capire il verbo: controlla aggettivo e ordine.",
    maxAttemptsBeforeReview: 2,
  },
];

const robotVariants: RobotPuzzleDefinition[] = [
  robotPuzzle,
  {
    id: "mission1.robot.variant-zigzag",
    grid: {
      cols: 6,
      rows: 5,
      start: { col: 0, row: 4, facing: "E" },
      key: { col: 4, row: 0 },
      obstacles: [
        { col: 1, row: 3 },
        { col: 2, row: 3 },
        { col: 3, row: 2 },
        { col: 4, row: 2 },
      ],
    },
    commands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "PICK_UP"],
    idealLength: 11,
  },
  {
    id: "mission1.robot.variant-corridor",
    grid: {
      cols: 6,
      rows: 5,
      start: { col: 0, row: 4, facing: "N" },
      key: { col: 3, row: 1 },
      obstacles: [
        { col: 1, row: 2 },
        { col: 2, row: 2 },
        { col: 4, row: 3 },
      ],
    },
    commands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "PICK_UP"],
    idealLength: 10,
  },
];

const productionOrderPool: ProductionOrder[] = [
  ...productionOrders,
  {
    id: "order-gold-valve",
    title: "Valvola Dorata",
    start: 8,
    target: 27,
    maxSteps: 4,
    requiredMachineIds: ["gate-even", "divide-2", "add-5", "multiply-3"],
    narrative: "La valvola vuole un nucleo pari verificato, poi alzato e triplicato.",
    clue: "Il controllo pari non cambia 8. Dopo +5 arrivi a 13, e il triplicatore porta a 39: serve un'altra strada.",
    solutionHint: "Usa il controllo pari, dividi 8 per 2, aggiungi 5 e poi triplica.",
  },
  {
    id: "order-silver-relay",
    title: "Relè Argento",
    start: 6,
    target: 30,
    maxSteps: 3,
    requiredMachineIds: ["multiply-2", "transform-2n1", "add-5"],
    narrative: "Il relè accetta una sequenza breve: raddoppio, bobina e piccola spinta finale.",
    clue: "La bobina 2n+1 lavora bene dopo un raddoppio.",
    solutionHint: "Raddoppia 6, passa nella bobina 2n+1, poi aggiungi 5.",
  },
];

const archiveMessagePool: ArchiveMessage[] = [
  ...archiveMessages,
  {
    id: "east-map",
    title: "Mappa Est",
    corrupted: "Le mappa est indicano due corridoio, ma il segnale cita un solo passaggio sicuro.",
    repaired: "La mappa est indica due corridoi, ma il segnale cita un solo passaggio sicuro.",
    options: [
      "La mappa est indica due corridoi, ma il segnale cita un solo passaggio sicuro.",
      "Le mappe est indica due corridoio, ma il segnale cita un solo passaggio sicuro.",
      "La mappa est indicano due corridoi, ma il segnale cita un solo passaggio sicuro.",
      "La mappa est indica due corridoi, ma il segnale cita due passaggi sicuri.",
    ],
    systemMeaning: "La mappa mostra due corridoi, ma solo uno è sicuro.",
    diagnosticSteps: ["Mappa è singolare.", "Corridoi è plurale.", "Il dato 'un solo passaggio sicuro' non va modificato."],
    hint: "Ripara la frase senza cambiare il numero di passaggi sicuri.",
    maxAttemptsBeforeReview: 2,
  },
  {
    id: "sensor-log",
    title: "Log Sensore",
    corrupted: "Il sensori sud registrano una vibrazione debole e richiedono il controllo manuale.",
    repaired: "Il sensore sud registra una vibrazione debole e richiede il controllo manuale.",
    options: [
      "Il sensore sud registra una vibrazione debole e richiede il controllo manuale.",
      "I sensori sud registra una vibrazione debole e richiede il controllo manuale.",
      "Il sensore sud registrano vibrazioni deboli e richiede il controllo manuale.",
      "Il sensore sud registra una vibrazione debole e richiedono il controllo manuale.",
    ],
    systemMeaning: "Il sensore sud segnala una sola vibrazione debole da controllare.",
    diagnosticSteps: ["Sensore è singolare.", "Vibrazione è singolare.", "Entrambi i verbi si riferiscono al sensore."],
    hint: "Non farti distrarre dal nome tecnico: cerca il soggetto dei due verbi.",
    maxAttemptsBeforeReview: 2,
  },
];

export class ExerciseVariantSystem {
  private random(label: string): Random {
    return new Random(`${saveSystem.data.exerciseSeed}:${label}`);
  }

  getMathLockPuzzle(): MathPuzzleDefinition {
    return this.random("mission1-math").pick(mathVariants);
  }

  getGrammarRepairPuzzle(): GrammarRepairDefinition {
    const random = this.random("mission1-grammar");
    const picked = random.pick(grammarVariants);
    return { ...picked, options: random.shuffle(picked.options) };
  }

  getEnglishInstructionPuzzle(): EnglishInstructionDefinition {
    const random = this.random("mission1-english");
    const picked = random.pick(englishVariants);
    return { ...picked, choices: random.shuffle(picked.choices) };
  }

  getRobotPuzzle(): RobotPuzzleDefinition {
    return this.random("mission1-robot").pick(robotVariants);
  }

  getGreenhousePlants(): PlantDefinition[] {
    const random = this.random("mission2-greenhouse");
    return random.shuffle(greenhousePlants).map((plant) => {
      const values = { ...plant.startingValues };
      (Object.keys(values) as Array<keyof GreenhouseValues>).forEach((sensor) => {
        const step = sensor === "temperature" ? 1 : 4;
        values[sensor] += random.integer(-1, 1) * step;
      });
      return { ...plant, startingValues: values };
    });
  }

  getProductionOrders(): ProductionOrder[] {
    const random = this.random("mission3-orders");
    const solvableOrders = productionOrderPool.filter((order) => numberFactorySolver.isSolvable(order));
    const orders = random.shuffle(solvableOrders).slice(0, 3);
    return orders.some((order) => order.id === productionOrders[0].id) ? orders : [productionOrders[0], ...orders.slice(0, 2)];
  }

  getArchiveVariant(): ArchiveVariant {
    const random = this.random("mission4-archive");
    const messages = random.shuffle(archiveMessagePool).slice(0, 3);
    const usefulEvidence = messages.map((message) => ({
      id: `evidence-${message.id}`,
      text: message.systemMeaning,
      useful: true,
      reason: "È un'informazione operativa ricavata da un messaggio riparato.",
    }));
    const noise = random.shuffle(archiveEvidence.filter((evidence) => !evidence.useful)).slice(0, 3);
    const reportKeywords = messages.flatMap((message) => reportKeywordsByMessageId[message.id] ?? [message.title.toLowerCase()]);
    return {
      messages,
      evidence: random.shuffle([...usefulEvidence, ...noise]),
      instruction: {
        instruction: "Open the verified record. Do not delete the source note.",
        choices: random.shuffle([
          {
            id: "open-verified-record",
            label: "Apri record verificato",
            correct: true,
            consequence: "Il record verificato si apre e la fonte resta disponibile.",
          },
          {
            id: "delete-source-note",
            label: "Cancella nota fonte",
            correct: false,
            consequence: "La frase dice 'Do not delete': cancellare toglierebbe una fonte di controllo.",
          },
          {
            id: "open-unverified-record",
            label: "Apri record non verificato",
            correct: false,
            consequence: "Verified indica il record controllato, non uno qualunque.",
          },
        ]),
        hint: "Open indica l'azione. Do not delete indica cosa evitare.",
      },
      reportKeywords,
      reportPrompt: `Scrivi un rapporto breve per NORA citando questi dati operativi: ${reportKeywords.join(", ")}.`,
    };
  }
}

const reportKeywordsByMessageId: Record<string, string[]> = {
  "north-door": ["porta nord", "09:14"],
  "blue-folder": ["fascicolo blu", "scaffale B"],
  "red-note": ["nota rossa", "fonti"],
  "east-map": ["mappa est", "passaggio sicuro"],
  "sensor-log": ["sensore sud", "vibrazione debole"],
};

function archiveInstructionToEnglish(instruction: BilingualInstruction): EnglishInstructionDefinition {
  return {
    id: "mission1.englishInstruction.open-blue-note",
    instruction: instruction.instruction,
    choices: instruction.choices.map((choice) => ({
      id: choice.id,
      label: choice.label,
      isCorrect: choice.correct,
      feedback: choice.consequence,
    })),
    diagnosticSteps: ["Open indica l'azione da fare.", "Do not delete indica cosa evitare."],
    hint: instruction.hint,
    maxAttemptsBeforeReview: 2,
  };
}

export const exerciseVariantSystem = new ExerciseVariantSystem();
