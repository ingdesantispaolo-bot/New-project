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
    symbolName: "due piastre parallele di lunghezza diversa",
    functionSummary: "fornisce la spinta elettrica tra polo + e polo -",
    symbolClue: "la piastra lunga indica il polo positivo",
    commonConfusion: "non è una resistenza: non limita la corrente, la alimenta",
  },
  {
    id: "switch",
    label: "Interruttore",
    role: "apre o chiude il percorso: se è aperto il circuito è interrotto anche se tutti i pezzi sono presenti",
    check: "verifica se la leva collega davvero i due contatti",
    symbolName: "due contatti con una leva mobile",
    functionSummary: "apre o chiude il passaggio della corrente",
    symbolClue: "la leva inclinata indica circuito aperto",
    commonConfusion: "non genera corrente: decide solo se il percorso continua",
  },
  {
    id: "resistor",
    label: "Resistenza",
    role: "limita la corrente e protegge il LED da impulsi troppo forti",
    check: "se manca, il LED non è certificabile anche quando si accende",
    symbolName: "zig-zag in serie sul filo",
    functionSummary: "limita la corrente e protegge i componenti sensibili",
    symbolClue: "il valore in ohm indica quanta opposizione offre",
    commonConfusion: "non serve ad accendere di più: serve a non sovraccaricare",
  },
  {
    id: "led",
    label: "LED",
    role: "è un diodo luminoso: lascia passare corrente quasi solo nel verso corretto",
    check: "se arriva corrente ma resta spento, controlla la polarità",
    symbolName: "diodo con due frecce luminose",
    functionSummary: "emette luce solo se polarità e corrente sono corrette",
    symbolClue: "il triangolo/freccia e la barretta mostrano il verso",
    commonConfusion: "non è una lampadina normale: il verso conta",
  },
  {
    id: "sensor",
    label: "Sensore",
    role: "misura un valore e lo manda al terminale, ma solo se è alimentato e collegato al bus dati",
    check: "un sensore scollegato può sembrare guasto anche quando il circuito principale funziona",
    symbolName: "modulo con ingresso circolare e freccia dati",
    functionSummary: "misura un segnale e invia dati al terminale",
    symbolClue: "ha sia alimentazione sia uscita dati",
    commonConfusion: "se non è alimentato, non può misurare",
  },
  {
    id: "capacitor",
    label: "Condensatore",
    role: "accumula una piccola carica e la rilascia per stabilizzare impulsi brevi",
    check: "se è scarico, il LED può fare un lampo debole o ritardato",
    symbolName: "due piastre uguali affiancate",
    functionSummary: "accumula carica e la rilascia per stabilizzare impulsi",
    symbolClue: "due piastre vicine suggeriscono accumulo",
    commonConfusion: "non è una batteria: non produce energia nuova, la conserva per poco",
  },
  {
    id: "return",
    label: "Ritorno",
    role: "riporta il percorso verso il polo negativo: senza ritorno non c'è circuito chiuso",
    check: "segui il filo fino al - della batteria",
    symbolName: "linea di ritorno verso il polo negativo",
    functionSummary: "chiude il giro riportando la corrente al polo -",
    symbolClue: "senza questo tratto la linea finisce nel vuoto",
    commonConfusion: "non è opzionale: ogni circuito deve tornare alla sorgente",
  },
  {
    id: "branchLed",
    label: "Ramo parallelo",
    role: "crea un secondo percorso: un guasto su un ramo non deve per forza spegnere tutto il circuito",
    check: "controlla quale ramo resta alimentato e quale si interrompe",
    symbolName: "biforcazione con due percorsi",
    functionSummary: "divide la corrente in rami che possono funzionare separatamente",
    symbolClue: "due strade partono dagli stessi nodi",
    commonConfusion: "non trattarlo come un unico filo in serie",
  },
  {
    id: "relay",
    label: "Relè",
    role: "usa una piccola corrente di comando per chiudere un circuito più potente",
    check: "verifica sia la bobina di comando sia il contatto che alimenta il carico",
    symbolName: "bobina con contatto comandato",
    functionSummary: "usa un comando debole per chiudere un circuito di potenza",
    symbolClue: "ha una parte di comando e una parte di contatto",
    commonConfusion: "non è solo un interruttore manuale: viene comandato elettricamente",
  },
  {
    id: "motor",
    label: "Motore",
    role: "è un carico più esigente di un LED: richiede alimentazione stabile e protezione",
    check: "se il LED funziona ma il motore no, controlla caduta di tensione e relè",
    symbolName: "cerchio con lettera M",
    functionSummary: "trasforma energia elettrica in movimento",
    symbolClue: "la M indica il carico meccanico",
    commonConfusion: "non è un sensore: consuma energia, non misura",
  },
  {
    id: "ground",
    label: "Massa",
    role: "è il riferimento di ritorno del circuito: se è ballerina, le misure diventano instabili",
    check: "cerca letture che passano da continuità a interruzione",
    symbolName: "tre linee orizzontali decrescenti",
    functionSummary: "stabilizza il riferimento comune del ritorno",
    symbolClue: "le linee a scalare indicano riferimento a massa",
    commonConfusion: "non è un interruttore: è un riferimento stabile",
  },
];
