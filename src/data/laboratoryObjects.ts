export type LaboratoryAction = "inspect" | "grammar" | "circuit" | "terminal" | "robot" | "door" | "journal";

export type LaboratoryObject = {
  id: string;
  label: string;
  x: number;
  y: number;
  radius: number;
  action: LaboratoryAction;
  actionLabel: string;
  description: string;
  hints: string[];
  requiredFlags?: string[];
  completedFlag?: string;
  itemReward?: string;
};

export const laboratoryObjects: LaboratoryObject[] = [
  {
    id: "corrupted-message",
    label: "Messaggio instabile",
    x: 910,
    y: 502,
    radius: 42,
    action: "grammar",
    actionLabel: "Stabilizza testo",
    description:
      "La frase sul pannello lampeggia come se una parte della memoria linguistica fosse graffiata. Il sistema non accetta comandi finché il messaggio non torna coerente.",
    hints: [
      "Il primo indizio è nel numero: il messaggio parla di un solo generatore.",
      "Se il soggetto è singolare, anche verbo e aggettivo devono seguirlo.",
      "Non correggere solo la prima metà: anche la luce rossa deve avere articolo, colore e verbo coerenti.",
    ],
    completedFlag: "grammarFixed",
  },
  {
    id: "electric-panel",
    label: "Pannello elettrico",
    x: 470,
    y: 286,
    radius: 56,
    action: "circuit",
    actionLabel: "Apri pannello",
    description:
      "Dietro il vetro opaco si vede una linea di componenti scollegati. Un piccolo LED prova ad accendersi, poi si spegne subito.",
    hints: [
      "Il pannello non è morto: sta aspettando un percorso completo.",
      "La corrente deve partire, attraversare i componenti e tornare alla sorgente.",
      "Una resistenza non serve ad aprire la porta: serve a far lavorare il LED senza stressarlo.",
    ],
    requiredFlags: ["grammarFixed"],
    completedFlag: "circuitFixed",
    itemReward: "schema circuito",
  },
  {
    id: "terminal",
    label: "Terminale a bassa energia",
    x: 1072,
    y: 276,
    radius: 62,
    action: "terminal",
    actionLabel: "Interroga terminale",
    description:
      "Lo schermo non chiede una password qualunque: mostra un indizio numerico e un modulo operativo in inglese.",
    hints: [
      "Prima serve corrente stabile dal pannello.",
      "Il codice nasce da una frase: fai le operazioni nell'ordine in cui sono scritte.",
      "Quando compare una frase in inglese, non tradurre tutto: cerca il comando d'azione e la negazione.",
    ],
    requiredFlags: ["circuitFixed"],
    completedFlag: "englishInstructionSolved",
    itemReward: "nota terminale",
  },
  {
    id: "robot",
    label: "Robot N-7 inattivo",
    x: 560,
    y: 500,
    radius: 56,
    action: "robot",
    actionLabel: "Carica sequenza",
    description:
      "Il robot ha ruote magnetiche e un braccio sottile. Sembra capace di raggiungere una chiave, ma solo con comandi ordinati.",
    hints: [
      "Il robot non interpreta intenzioni: esegue ciò che gli dai, nell'ordine.",
      "Se urta un muro, il punto dell'urto dice quale comando va cambiato.",
      "La chiave non si raccoglie da lontano: il robot deve trovarsi sulla casella giusta.",
    ],
    requiredFlags: ["englishInstructionSolved"],
    completedFlag: "robotKeyRecovered",
  },
  {
    id: "final-door",
    label: "Porta sigillata",
    x: 760,
    y: 214,
    radius: 72,
    action: "door",
    actionLabel: "Verifica porta",
    description:
      "Tre serrature invisibili ascoltano il laboratorio: energia, codice e chiave magnetica. La porta non forza, ragiona.",
    hints: [
      "La porta non ha un enigma separato: controlla se i sistemi della stanza sono coerenti.",
      "Se un sistema è ancora scuro, la porta lo vede.",
      "Circuito chiuso, terminale verificato, chiave robot: questa è la condizione completa.",
    ],
    requiredFlags: ["robotKeyRecovered"],
    completedFlag: "doorOpened",
  },
  {
    id: "workbench",
    label: "Banco degli attrezzi",
    x: 430,
    y: 514,
    radius: 36,
    action: "inspect",
    actionLabel: "Osserva",
    description:
      "Cacciaviti isolati, pinze e un quaderno con disegni di frecce. Qualcuno lavorava qui senza separare teoria e mani.",
    hints: [
      "Un disegno mostra un anello: batteria, interruttore, resistenza, LED e ritorno.",
      "La freccia non è decorazione: indica che il circuito ha un verso da rispettare.",
    ],
    itemReward: "quaderno di laboratorio",
  },
  {
    id: "nora-core",
    label: "Nucleo NORA",
    x: 1120,
    y: 486,
    radius: 38,
    action: "inspect",
    actionLabel: "Ascolta NORA",
    description:
      "Il nucleo dell'assistente vibra a bassa frequenza. NORA non risolve al posto tuo, ma confronta le tue ipotesi con ciò che vede.",
    hints: [
      "NORA suggerisce: quando un sistema tace, chiediti cosa gli manca per funzionare.",
      "NORA aggiunge: una buona prova cambia una cosa sola alla volta.",
    ],
  },
  {
    id: "observation-window",
    label: "Finestra oscurata",
    x: 1120,
    y: 180,
    radius: 42,
    action: "inspect",
    actionLabel: "Guarda fuori",
    description:
      "Dietro il vetro si intravedono altri laboratori. Alcuni hanno piante illuminate, altri mappe sospese e archivi verticali.",
    hints: [
      "Non tutto si sblocca oggi: l'Accademia sembra organizzata in missioni concatenate.",
      "Il laboratorio biologico sul lato est ha già sensori verdi accesi.",
    ],
  },
  {
    id: "floor-trace",
    label: "Traccia sul pavimento",
    x: 686,
    y: 590,
    radius: 34,
    action: "inspect",
    actionLabel: "Segui traccia",
    description:
      "Una linea sottile collega pannello, terminale, robot e porta. Non è una decorazione: è una mappa del problema.",
    hints: [
      "La stanza stessa suggerisce l'ordine: testo, energia, terminale, robot, porta.",
      "Se salti un passaggio, un sistema successivo resta in attesa.",
    ],
  },
  {
    id: "journal-station",
    label: "Diario di bordo",
    x: 820,
    y: 575,
    radius: 38,
    action: "journal",
    actionLabel: "Apri diario",
    description:
      "Una tavoletta sottile registra scoperte, non voti. Le competenze compaiono come tracce di missione.",
    hints: [
      "Il diario serve a vedere che cosa hai scoperto, non a giudicare il tentativo.",
      "Quando la porta si aprirà, qui apparirà il riepilogo completo.",
    ],
  },
];
