export type ArchiveMessage = {
  id: string;
  title: string;
  corrupted: string;
  repaired: string;
  options: string[];
  systemMeaning: string;
  diagnosticSteps: string[];
  hint: string;
  maxAttemptsBeforeReview: number;
};

export type ArchiveEvidence = {
  id: string;
  text: string;
  useful: boolean;
  reason: string;
};

export type BilingualInstruction = {
  instruction: string;
  choices: Array<{
    id: string;
    label: string;
    correct: boolean;
    consequence: string;
  }>;
  hint: string;
};

export const archiveMessages: ArchiveMessage[] = [
  {
    id: "north-door",
    title: "Registro Porta Nord",
    corrupted: "Le porta nord sono stato aperta alle 09:14, ma il registro indica un solo varco.",
    repaired: "La porta nord è stata aperta alle 09:14, ma il registro indica un solo varco.",
    options: [
      "La porta nord è stata aperta alle 09:14, ma il registro indica un solo varco.",
      "Le porte nord sono state aperte alle 09:14, ma il registro indica un solo varco.",
      "La porta nord è stato aperto alle 09:14, ma il registro indica un solo varco.",
      "La porta nord è stata aperta alle 19:14, ma il registro indica un solo varco.",
    ],
    systemMeaning: "Il sistema deve sapere quale porta controllare e quando è stata aperta, senza moltiplicare il varco.",
    diagnosticSteps: [
      "Il dato 'un solo varco' rende singolare il soggetto.",
      "L'orario è un dato di log: non va corretto a intuito.",
      "Il participio deve concordare con 'porta'.",
    ],
    hint: "Il registro parla di una sola porta: grammatica e dato numerico devono restare coerenti.",
    maxAttemptsBeforeReview: 2,
  },
  {
    id: "blue-folder",
    title: "Indice Fascicolo Blu",
    corrupted: "Il fascicoli blu contengono una nota utile, però la etichetta indica scaffale B.",
    repaired: "Il fascicolo blu contiene una nota utile, però l'etichetta indica lo scaffale B.",
    options: [
      "Il fascicolo blu contiene una nota utile, però l'etichetta indica lo scaffale B.",
      "I fascicoli blu contengono una nota utile, però l'etichetta indica lo scaffale B.",
      "Il fascicolo blu contengono una nota utile, però l'etichetta indica lo scaffale B.",
      "Il fascicolo blu contiene una nota utile, però l'etichetta indica il scaffale B.",
    ],
    systemMeaning: "Il fascicolo blu contiene la nota da aprire e rimanda allo scaffale corretto.",
    diagnosticSteps: [
      "Il colore identifica un fascicolo specifico, non una categoria intera.",
      "Dopo 'però' arriva un secondo dato utile: l'etichetta.",
      "Davanti a 'scaffale' il sistema accetta 'lo', non 'il'.",
    ],
    hint: "Cerca il numero del fascicolo e conserva il dato dello scaffale.",
    maxAttemptsBeforeReview: 2,
  },
  {
    id: "red-note",
    title: "Avviso Nota Rossa",
    corrupted: "Non cancellare le nota rossi: serve per confrontare le fonti, non per aprire la uscita.",
    repaired: "Non cancellare la nota rossa: serve per confrontare le fonti, non per aprire l'uscita.",
    options: [
      "Non cancellare la nota rossa: serve per confrontare le fonti, non per aprire l'uscita.",
      "Non cancellare la nota rossa: serve per confrontare la fonte, non per aprire l'uscita.",
      "Non cancellare il nota rosso: serve per confrontare le fonti, non per aprire l'uscita.",
      "Cancella la nota rossa: serve per confrontare le fonti, non per aprire l'uscita.",
    ],
    systemMeaning: "La nota rossa non va eliminata: è una fonte di controllo, non una chiave d'uscita.",
    diagnosticSteps: [
      "La negazione è parte del comando: perderla cambia l'azione.",
      "Nota rossa è femminile singolare.",
      "Il testo parla di fonti al plurale e di uscita con apostrofo.",
    ],
    hint: "Qui il rischio non è solo grammaticale: se togli la negazione, il sistema distrugge una fonte.",
    maxAttemptsBeforeReview: 2,
  },
];

export const archiveEvidence: ArchiveEvidence[] = [
  {
    id: "door-time",
    text: "La porta nord è stata aperta alle 09:14 e il registro parla di un solo varco.",
    useful: true,
    reason: "Indica evento, orario e quantità: è un dato verificabile.",
  },
  {
    id: "blue-folder-info",
    text: "Il fascicolo blu contiene una nota utile e rimanda allo scaffale B.",
    useful: true,
    reason: "Indica dove cercare il contenuto rilevante.",
  },
  {
    id: "red-note-warning",
    text: "La nota rossa non deve essere cancellata.",
    useful: true,
    reason: "Indica una fonte da conservare per confronto critico.",
  },
  {
    id: "dust-detail",
    text: "Lo scaffale vicino al soffitto è molto polveroso.",
    useful: false,
    reason: "È un dettaglio ambientale, ma non aiuta a riparare il sistema.",
  },
  {
    id: "clock-color",
    text: "L'orologio dell'archivio ha una cornice verde.",
    useful: false,
    reason: "Il colore dell'orologio non cambia la decisione narrativa.",
  },
  {
    id: "south-door-color",
    text: "La porta sud ha una maniglia più lucida della porta nord.",
    useful: false,
    reason: "Sembra vicino al caso, ma non cambia porta, orario, fascicolo o fonte da conservare.",
  },
];

export const archiveInstruction: BilingualInstruction = {
  instruction: "Open the blue folder. Do not delete the red note.",
  choices: [
    {
      id: "open-blue",
      label: "Apri fascicolo blu",
      correct: true,
      consequence: "Il fascicolo blu si apre senza alterare le fonti.",
    },
    {
      id: "delete-red",
      label: "Cancella nota rossa",
      correct: false,
      consequence: "La frase dice 'Do not delete': cancellare distruggerebbe una fonte.",
    },
    {
      id: "open-red",
      label: "Apri nota rossa",
      correct: false,
      consequence: "La nota rossa va conservata, ma il comando d'azione riguarda il fascicolo blu.",
    },
  ],
  hint: "Open indica l'azione da fare. Do not delete indica cosa evitare.",
};

export const reportRequirements = {
  minLength: 80,
  keywords: ["porta nord", "09:14", "fascicolo blu", "nota rossa"],
  prompt:
    "Scrivi un rapporto breve per NORA: cosa è successo, quale fascicolo aprire, dove cercarlo e quale fonte non cancellare.",
};
