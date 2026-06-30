// Data for Mission 6 — "La Città Intelligente" (Stagione 2, Atto VI, finale).
// Four phases that each change the kind of thinking required:
//   1. diagnose the grid (read sensors, compare load vs capacity)
//   2. set conditional rules (if/then control logic, cross-domain with English)
//   3. balance the energy budget (constraint reasoning)
//   4. make a civic decision under scarcity (citizenship: protect life first)

export type CityDistrict = {
  id: string;
  name: string;
  load: number;
  capacity: number;
  note: string;
};

/** A district is critical when its demand exceeds the energy it receives. */
export const cityDistricts: CityDistrict[] = [
  { id: "centro", name: "Centro Storico", load: 70, capacity: 60, note: "Semafori e insegne al massimo: il nodo chiede più di quanto riceve." },
  { id: "ospedale", name: "Distretto Ospedale", load: 55, capacity: 80, note: "Sotto controllo: la riserva copre la domanda." },
  { id: "porto", name: "Porto Merci", load: 90, capacity: 75, note: "Gru e depositi in funzione: richiesta oltre la capacità." },
  { id: "residenza", name: "Quartiere Residenziale", load: 40, capacity: 50, note: "Consumi serali normali, margine disponibile." },
];

export type CityRule = {
  id: string;
  condition: string;
  english: string;
  options: string[];
  answer: string;
  hint: string;
};

/** Each rule pairs a condition with the action that resolves it. */
export const cityRules: CityRule[] = [
  {
    id: "overload",
    condition: "SE un nodo è in sovraccarico…",
    english: "if a node is overloaded, reroute power",
    options: ["Deviare energia da un nodo con margine", "Spegnere l'intero distretto", "Aumentare ancora il consumo"],
    answer: "Deviare energia da un nodo con margine",
    hint: "overloaded = troppa richiesta: serve spostare energia da chi ne ha in più, non toglierla a chi è già al limite.",
  },
  {
    id: "sensorfault",
    condition: "SE un sensore è guasto…",
    english: "if a sensor is faulty, use the backup value",
    options: ["Usare il valore di backup", "Ignorare quel nodo", "Spegnere tutti i semafori"],
    answer: "Usare il valore di backup",
    hint: "backup value = valore di riserva da usare quando il dato diretto non è affidabile.",
  },
  {
    id: "emergency",
    condition: "SE arriva un'emergenza…",
    english: "if there is an emergency, give priority to rescue vehicles",
    options: ["Dare priorità ai mezzi di soccorso", "Bloccare tutti gli incroci", "Mettere il rosso ovunque"],
    answer: "Dare priorità ai mezzi di soccorso",
    hint: "emergency = la sicurezza delle persone viene prima del traffico normale.",
  },
];

export type EnergyPlan = {
  id: string;
  label: string;
  allocation: { ospedale: number; trasporti: number; acqua: number };
  valid: boolean;
  reason: string;
};

export const energyBudget = 90;
export const energyMinimums = { ospedale: 40, trasporti: 25, acqua: 20 };

/** Only one plan meets every minimum without exceeding the budget. */
export const energyPlans: EnergyPlan[] = [
  {
    id: "A",
    label: "Piano A",
    allocation: { ospedale: 45, trasporti: 25, acqua: 20 },
    valid: true,
    reason: "Ogni servizio essenziale supera il minimo e il totale (90) resta dentro il budget.",
  },
  {
    id: "B",
    label: "Piano B",
    allocation: { ospedale: 35, trasporti: 30, acqua: 25 },
    valid: false,
    reason: "L'ospedale scende sotto il minimo (40): un servizio salvavita resterebbe scoperto.",
  },
  {
    id: "C",
    label: "Piano C",
    allocation: { ospedale: 50, trasporti: 30, acqua: 25 },
    valid: false,
    reason: "Il totale (105) supera l'energia disponibile (90): la rete salterebbe del tutto.",
  },
];

export type CivicOption = {
  id: string;
  label: string;
  correct: boolean;
  reason: string;
};

export const civicDilemma: { prompt: string; options: CivicOption[] } = {
  prompt: "Il sabotatore ha tagliato l'energia esterna. Ne resta solo per due settori su tre. Quali proteggi per primi?",
  options: [
    {
      id: "life",
      label: "Ospedale + Acqua potabile",
      correct: true,
      reason: "Prima la vita e la salute: ospedale e acqua sono servizi salvavita, vengono prima di ogni comodità.",
    },
    {
      id: "comfort",
      label: "Ospedale + Centro commerciale",
      correct: false,
      reason: "L'ospedale è giusto, ma il centro commerciale è una comodità, non un bisogno vitale come l'acqua potabile.",
    },
    {
      id: "transport",
      label: "Trasporti + Illuminazione decorativa",
      correct: false,
      reason: "Utili, ma senza ospedale e acqua le persone più fragili resterebbero senza l'essenziale.",
    },
  ],
};
