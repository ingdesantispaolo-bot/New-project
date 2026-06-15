export type NumberMachineKind =
  | "add"
  | "subtract"
  | "multiply"
  | "divide"
  | "evenGate"
  | "multipleOfThreeGate"
  | "transform";

export type NumberMachineDefinition = {
  id: string;
  label: string;
  kind: NumberMachineKind;
  value?: number;
  expressionLabel: string;
  description: string;
  hint: string;
};

export type ProductionOrder = {
  id: string;
  title: string;
  start: number;
  target: number;
  maxSteps: number;
  requiredMachineIds: string[];
  narrative: string;
  clue: string;
  solutionHint: string;
};

export const numberMachines: NumberMachineDefinition[] = [
  {
    id: "gate-even",
    label: "Cancello Pari",
    kind: "evenGate",
    expressionLabel: "pari",
    description: "Lascia passare solo nuclei con carica pari. Non cambia il numero, ma blocca percorsi instabili.",
    hint: "Un numero pari si divide esattamente per 2.",
  },
  {
    id: "gate-multiple-3",
    label: "Filtro x3",
    kind: "multipleOfThreeGate",
    expressionLabel: "multiplo di 3",
    description: "Accetta solo nuclei sincronizzati su gruppi da tre.",
    hint: "Un multiplo di 3 entra in gruppi uguali da 3 senza resto.",
  },
  {
    id: "add-5",
    label: "Additore +5",
    kind: "add",
    value: 5,
    expressionLabel: "+ 5",
    description: "Inietta cinque unità di energia nel nucleo.",
    hint: "Aggiungere può preparare un numero a diventare pari o multiplo di 3.",
  },
  {
    id: "subtract-4",
    label: "Scarico -4",
    kind: "subtract",
    value: 4,
    expressionLabel: "- 4",
    description: "Scarica quattro unità per raffreddare il nucleo.",
    hint: "Sottrarre può correggere un eccesso dopo una moltiplicazione.",
  },
  {
    id: "multiply-2",
    label: "Duplicatore x2",
    kind: "multiply",
    value: 2,
    expressionLabel: "x 2",
    description: "Raddoppia il nucleo usando due rulli sincronizzati.",
    hint: "Raddoppiare conserva la parita: pari resta pari, dispari diventa pari.",
  },
  {
    id: "multiply-3",
    label: "Triplicatore x3",
    kind: "multiply",
    value: 3,
    expressionLabel: "x 3",
    description: "Crea tre copie energetiche e le fonde in un unico nucleo.",
    hint: "Dopo questa macchina il numero sarà sempre multiplo di 3.",
  },
  {
    id: "divide-2",
    label: "Separatore /2",
    kind: "divide",
    value: 2,
    expressionLabel: "/ 2",
    description: "Divide il nucleo in due camere uguali. Accetta solo numeri pari.",
    hint: "Se il numero è dispari, il separatore si blocca per evitare mezzi pezzi.",
  },
  {
    id: "divide-3",
    label: "Separatore /3",
    kind: "divide",
    value: 3,
    expressionLabel: "/ 3",
    description: "Divide il nucleo in tre camere uguali. Accetta solo multipli di 3.",
    hint: "Prima di usarlo, controlla se il filtro x3 lo lascerebbe passare.",
  },
  {
    id: "transform-2n1",
    label: "Bobina 2n+1",
    kind: "transform",
    value: 1,
    expressionLabel: "2n + 1",
    description: "Raddoppia il nucleo e aggiunge una scintilla di avvio.",
    hint: "Questa macchina è una piccola espressione: prima raddoppia, poi aggiunge 1.",
  },
];

export const productionOrders: ProductionOrder[] = [
  {
    id: "order-stable-gear",
    title: "Ingranaggio Stabile",
    start: 7,
    target: 32,
    maxSteps: 4,
    requiredMachineIds: ["add-5", "multiply-3", "subtract-4"],
    narrative: "La pressa centrale richiede energia 32: abbastanza alta, ma ancora controllabile.",
    clue: "Il nucleo 7 può diventare pari prima di essere triplicato.",
    solutionHint: "Prova a trasformare 7 in 12, poi usa il triplicatore e correggi l'eccesso.",
  },
  {
    id: "order-blue-turbine",
    title: "Turbina Blu",
    start: 10,
    target: 15,
    maxSteps: 4,
    requiredMachineIds: ["gate-even", "divide-2", "multiply-3"],
    narrative: "La turbina accetta solo un nucleo già verificato pari e poi ridotto senza resto.",
    clue: "Qui il cancello pari non cambia il numero: serve a controllare l'errore prima del separatore.",
    solutionHint: "Un percorso possibile controlla 10 come pari, lo divide in due camere e poi usa il triplicatore.",
  },
  {
    id: "order-red-core",
    title: "Nucleo Rosso",
    start: 5,
    target: 33,
    maxSteps: 4,
    requiredMachineIds: ["transform-2n1", "multiply-3", "gate-multiple-3"],
    narrative: "Il nucleo rosso richiede una trasformazione rapida e un controllo sui multipli di 3.",
    clue: "La bobina 2n+1 rende 5 uguale a 11: da lì il triplicatore produce un multiplo di 3.",
    solutionHint: "Usa la bobina, poi il triplicatore. Il filtro x3 può confermare che il nucleo è stabile.",
  },
];
