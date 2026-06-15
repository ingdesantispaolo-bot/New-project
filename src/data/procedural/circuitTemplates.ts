import type { CircuitFaultType } from "../../procedural/ProceduralTypes";

export const circuitNodes = ["battery", "switch", "resistor", "led", "return"] as const;

export const optionalCircuitNodes = ["sensor", "capacitor", "branchLed", "relay", "motor", "ground"] as const;

export const circuitBaseEdges = [
  { from: "battery", to: "switch" },
  { from: "switch", to: "resistor" },
  { from: "resistor", to: "led" },
  { from: "led", to: "return" },
  { from: "return", to: "battery" },
];

export const circuitFaultTemplates: Array<{
  type: CircuitFaultType;
  label: string;
  hint: string;
  minComplexity?: number;
}> = [
  { type: "missing-wire", label: "Filo mancante", hint: "Un tratto del percorso non collega due componenti." },
  { type: "open-switch", label: "Interruttore aperto", hint: "L'interruttore interrompe il giro della corrente." },
  { type: "reversed-led", label: "LED invertito", hint: "Il LED ha un verso: se è invertito resta spento." },
  { type: "missing-resistor", label: "Resistenza assente", hint: "Il LED può accendersi male senza protezione." },
  { type: "disconnected-component", label: "Componente scollegato", hint: "Un componente esiste, ma non partecipa al circuito." },
  { type: "sensor-unpowered", label: "Sensore non alimentato", hint: "Il sensore può leggere solo se riceve energia dal ramo corretto.", minComplexity: 4 },
  { type: "capacitor-discharged", label: "Condensatore scarico", hint: "Il condensatore deve accumulare carica prima di stabilizzare un impulso.", minComplexity: 5 },
  { type: "short-circuit", label: "Corto circuito", hint: "Un collegamento salta il carico: la corrente prende una scorciatoia rischiosa.", minComplexity: 4 },
  { type: "parallel-branch-open", label: "Ramo parallelo aperto", hint: "Un ramo può essere interrotto anche se l'altro continua a funzionare.", minComplexity: 5 },
  { type: "wrong-resistor-value", label: "Resistenza errata", hint: "Una resistenza troppo bassa o troppo alta cambia luminosità e sicurezza.", minComplexity: 5 },
  { type: "relay-not-armed", label: "Relè non armato", hint: "Il relè è un interruttore comandato: senza bobina alimentata non chiude il carico.", minComplexity: 6 },
  { type: "loose-ground", label: "Ritorno a massa instabile", hint: "Il ritorno al polo negativo deve essere stabile, non solo presente a tratti.", minComplexity: 6 },
];

export const circuitComponentGuide = [
  {
    id: "battery",
    label: "Batteria",
    role: "fornisce una differenza di potenziale: nel gioco è la spinta che mette in moto la corrente",
    check: "controlla sempre dove sono + e -",
  },
  {
    id: "switch",
    label: "Interruttore",
    role: "apre o chiude il percorso: se è aperto il circuito è interrotto anche se tutti i pezzi sono presenti",
    check: "verifica se la leva collega davvero i due contatti",
  },
  {
    id: "resistor",
    label: "Resistenza",
    role: "limita la corrente e protegge il LED da impulsi troppo forti",
    check: "se manca, il LED non è certificabile anche quando si accende",
  },
  {
    id: "led",
    label: "LED",
    role: "è un diodo luminoso: lascia passare corrente quasi solo nel verso corretto",
    check: "se arriva corrente ma resta spento, controlla la polarità",
  },
  {
    id: "sensor",
    label: "Sensore",
    role: "misura un valore e lo manda al terminale, ma solo se è alimentato e collegato al bus dati",
    check: "un sensore scollegato può sembrare guasto anche quando il circuito principale funziona",
  },
  {
    id: "capacitor",
    label: "Condensatore",
    role: "accumula una piccola carica e la rilascia per stabilizzare impulsi brevi",
    check: "se è scarico, il LED può fare un lampo debole o ritardato",
  },
  {
    id: "return",
    label: "Ritorno",
    role: "riporta il percorso verso il polo negativo: senza ritorno non c'è circuito chiuso",
    check: "segui il filo fino al - della batteria",
  },
  {
    id: "branchLed",
    label: "Ramo parallelo",
    role: "crea un secondo percorso: un guasto su un ramo non deve per forza spegnere tutto il circuito",
    check: "controlla quale ramo resta alimentato e quale si interrompe",
  },
  {
    id: "relay",
    label: "Relè",
    role: "usa una piccola corrente di comando per chiudere un circuito più potente",
    check: "verifica sia la bobina di comando sia il contatto che alimenta il carico",
  },
  {
    id: "motor",
    label: "Motore",
    role: "è un carico più esigente di un LED: richiede alimentazione stabile e protezione",
    check: "se il LED funziona ma il motore no, controlla caduta di tensione e relè",
  },
  {
    id: "ground",
    label: "Massa",
    role: "è il riferimento di ritorno del circuito: se è ballerina, le misure diventano instabili",
    check: "cerca letture che passano da continuità a interruzione",
  },
];
