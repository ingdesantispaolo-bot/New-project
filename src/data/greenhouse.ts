export type GreenhouseSensor = "water" | "light" | "temperature";

export type GreenhouseValues = Record<GreenhouseSensor, number>;

export type PlantDefinition = {
  id: string;
  name: string;
  scientificHint: string;
  englishNote: string;
  startingValues: GreenhouseValues;
  idealValues: GreenhouseValues;
  tolerance: GreenhouseValues;
  leafClues: string[];
};

export type GreenhouseAdjustment = {
  id: string;
  label: string;
  sensor: GreenhouseSensor;
  delta: number;
};

export const greenhousePlants: PlantDefinition[] = [
  {
    id: "felce-luna",
    name: "Felce Luna",
    scientificHint: "Ama luce morbida e terreno umido, ma soffre quando la serra diventa troppo calda.",
    englishNote: "Low light. Keep soil moist.",
    startingValues: { water: 50, light: 66, temperature: 27 },
    idealValues: { water: 68, light: 42, temperature: 22 },
    tolerance: { water: 18, light: 16, temperature: 5 },
    leafClues: [
      "Le foglie sono arrotolate ai bordi: sta perdendo acqua.",
      "Le punte chiare suggeriscono troppa luce diretta.",
      "Il vapore sul vetro vicino è alto: la temperatura non è neutra.",
    ],
  },
  {
    id: "pomodoro-aurora",
    name: "Pomodoro Aurora",
    scientificHint: "Cresce bene con molta luce, acqua regolare e temperatura tiepida.",
    englishNote: "Full light. Warm temperature.",
    startingValues: { water: 50, light: 58, temperature: 22 },
    idealValues: { water: 62, light: 82, temperature: 25 },
    tolerance: { water: 16, light: 14, temperature: 4 },
    leafClues: [
      "Il fusto cerca la lampada: la luce non basta.",
      "Il terreno è secco in superficie, ma non completamente vuoto.",
      "I fiori restano chiusi: la temperatura è un po' bassa.",
    ],
  },
  {
    id: "cactus-vetro",
    name: "Cactus di Vetro",
    scientificHint: "Conserva acqua, vuole luce intensa e non ama radici bagnate.",
    englishNote: "Dry soil. Bright light.",
    startingValues: { water: 52, light: 64, temperature: 24 },
    idealValues: { water: 28, light: 88, temperature: 27 },
    tolerance: { water: 14, light: 16, temperature: 5 },
    leafClues: [
      "La base è lucida e molle: troppa acqua resta nel substrato.",
      "Le spine sono pallide: cerca più luce.",
      "Il sensore termico è sotto il valore ideale per una pianta desertica.",
    ],
  },
];

export const greenhouseAdjustments: GreenhouseAdjustment[] = [
  { id: "water-up", label: "+ acqua", sensor: "water", delta: 12 },
  { id: "water-down", label: "- acqua", sensor: "water", delta: -12 },
  { id: "light-up", label: "+ luce", sensor: "light", delta: 12 },
  { id: "light-down", label: "- luce", sensor: "light", delta: -12 },
  { id: "temp-up", label: "+ temp", sensor: "temperature", delta: 3 },
  { id: "temp-down", label: "- temp", sensor: "temperature", delta: -3 },
];

export const greenhouseMissionRules = {
  maxTurns: 12,
  savedHealth: 72,
  plantsToSave: 3,
};
