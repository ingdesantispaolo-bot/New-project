import type { ProceduralSpecialization } from "../../procedural/ProceduralTypes";

type FocusPuzzleId = "language" | "circuit" | "math" | "english" | "robot";

type FocusChallengeStage = {
  label: string;
  description: string;
};

export type ProceduralFocusPath = {
  id: ProceduralSpecialization;
  label: string;
  title: string;
  chamberTitle: string;
  roomTitles: string[];
  introFragments: string[];
  sideNote: string;
  ruleTitle: string;
  ruleText: string;
  stageHint: string;
  primaryPuzzle?: FocusPuzzleId;
  challengeStages: FocusChallengeStage[];
  badge: {
    badgeId: string;
    label: string;
    description: string;
  };
  hotspots: Record<FocusPuzzleId, { label: string; description: string }>;
  objectives: Record<FocusPuzzleId, { label: string; description: string }>;
};

export const proceduralFocusPaths: Record<ProceduralSpecialization, ProceduralFocusPath> = {
  libera: {
    id: "libera",
    label: "Run libera",
    title: "Laboratorio Sempre Diverso",
    chamberTitle: "Sala riconfigurabile",
    roomTitles: [
      "Sala dei Circuiti Variabili",
      "Officina delle Serrature Vive",
      "Laboratorio delle Tracce Incerte",
      "Camera del Segnale Muto",
    ],
    introFragments: [
      "NORA apre una porta secondaria dell'Accademia: la stanza cambia disposizione ogni volta, ma lascia sempre indizi verificabili.",
      "Il laboratorio si riconfigura con una mappa nuova. Non è caos: è un test controllato di osservazione.",
      "Le pareti ruotano lentamente. Eli vede sistemi diversi, ma la regola resta la stessa: capire prima di agire.",
    ],
    sideNote: "Ogni modulo nasce dal seed e viene validato prima di apparire.",
    ruleTitle: "Regola della missione",
    ruleText: "Scegli liberamente una console. Osserva, formula una diagnosi, poi intervieni. Tentare tutto non produce un log affidabile.",
    stageHint: "Rete libera: ogni materia può essere affrontata subito. La porta finale richiede il sistema completo.",
    challengeStages: [],
    badge: {
      badgeId: "cartografa-del-caos-controllato",
      label: "Cartografa del Caos Controllato",
      description: "Ha risolto una missione generata ma validata.",
    },
    hotspots: {
      language: { label: "Segnale corrotto", description: "Un pannello linguistico deve essere stabilizzato senza perdere il senso operativo." },
      circuit: { label: "Circuito variabile", description: "Il circuito è cambiato con la stanza: va diagnosticato, non ricordato." },
      math: { label: "Terminale numerico", description: "La serratura calcola energia, non accetta numeri tentati a caso." },
      english: { label: "Modulo inglese", description: "Un comando operativo arriva dall'ala esterna dell'Accademia." },
      robot: { label: "Robot riconfigurato", description: "Il robot deve raggiungere chiave e uscita nella griglia generata." },
    },
    objectives: {
      language: { label: "Stabilizza il segnale", description: "Ripara il messaggio tecnico senza perdere il senso operativo." },
      circuit: { label: "Diagnostica il circuito", description: "Trova i guasti e ripristina un percorso elettrico stabile." },
      math: { label: "Calcola il codice", description: "Ricostruisci il codice del terminale seguendo la traccia numerica." },
      english: { label: "Decodifica il comando esterno", description: "Esegui solo l'azione autorizzata dall'istruzione inglese." },
      robot: { label: "Guida il robot alla chiave", description: "Costruisci una sequenza coerente nella griglia generata." },
    },
  },
  matematica: {
    id: "matematica",
    label: "Percorso Matematica",
    title: "Forgia dei Numeri",
    chamberTitle: "Officina numerica",
    roomTitles: ["Linea delle Macchine Inverse", "Sala dei Vincoli", "Forgia delle Sequenze", "Camera delle Parentesi"],
    introFragments: [
      "NORA apre l'officina numerica: le macchine non chiedono risultati, chiedono di capire quale regola le governa.",
      "La stanza vibra come una fabbrica di energia: ogni calcolo è una leva che sposta un sistema reale.",
      "Eli entra in un settore dove i numeri non sono risposte isolate, ma comandi per trasformare la sala.",
    ],
    sideNote: "Il percorso privilegia calcolo strategico, controllo dell'errore, vincoli e ragionamento inverso.",
    ruleTitle: "Regola della forgia",
    ruleText: "Puoi partire da qualunque console, ma il terminale numerico contiene la sfida centrale. Scrivi passaggi mentali, non tentativi.",
    stageHint: "Percorso matematica: cerca relazioni, soglie, sequenze e operazioni inverse. Il bonus focus premia il terminale numerico.",
    primaryPuzzle: "math",
    challengeStages: [
      { label: "Numeri e quote", description: "Lavora su calcolo mentale, frazioni e percentuali dentro una risorsa da gestire." },
      { label: "Pattern e dati", description: "Leggi sequenze, coordinate o piccoli insiemi di dati per ricavare una regola." },
      { label: "Vincoli e spazio", description: "Combina divisibilità, proporzioni, probabilità o geometria per soddisfare condizioni multiple." },
      { label: "Algebra viva", description: "Usa incognite, operazioni inverse, sistemi o funzioni lineari per risalire a un valore nascosto." },
      { label: "Modelli avanzati", description: "Affronta potenze, radici, crescita, notazione scientifica o log di errore da verificare." },
    ],
    badge: {
      badgeId: "custode-delle-regole-numeriche",
      label: "Custode delle Regole Numeriche",
      description: "Ha riconosciuto trasformazioni, vincoli e controlli d'errore.",
    },
    hotspots: {
      language: { label: "Log dei dati", description: "Il testo contiene dati utili e dettagli di disturbo: va riparato prima di usarlo." },
      circuit: { label: "Alimentatore della forgia", description: "Il circuito decide se le macchine numeriche ricevono energia stabile." },
      math: { label: "Cuore di calcolo", description: "Il terminale genera una regola numerica validata: non si apre per tentativi." },
      english: { label: "Protocollo esterno", description: "Un breve comando inglese stabilisce l'ordine sicuro delle operazioni." },
      robot: { label: "Carrello automatico", description: "Il robot trasporta la chiave lungo una griglia che richiede pianificazione." },
    },
    objectives: {
      language: { label: "Filtra il log dati", description: "Distingui informazione utile e rumore linguistico." },
      circuit: { label: "Stabilizza l'alimentatore", description: "Garantisci energia sicura alle macchine numeriche." },
      math: { label: "Risolvi la regola centrale", description: "Usa più passaggi, vincoli o operazioni inverse per ottenere il codice." },
      english: { label: "Esegui il protocollo", description: "Interpreta l'istruzione operativa senza invertire ordine o condizione." },
      robot: { label: "Muovi il carrello", description: "Trasforma la pianificazione in una sequenza di comandi." },
    },
  },
  italiano: {
    id: "italiano",
    label: "Percorso Italiano",
    title: "Archivio dei Segnali",
    chamberTitle: "Archivio linguistico",
    roomTitles: ["Archivio delle Cause", "Sala dei Pronomi", "Biblioteca dei Log Corrotti", "Camera delle Frasi Eseguibili"],
    introFragments: [
      "NORA apre l'Archivio dei Segnali: qui una frase imprecisa può mandare un intero sistema nella direzione sbagliata.",
      "Eli trova registri tecnici corrotti: non basta correggere la grammatica, bisogna salvare il significato.",
      "La sala conserva messaggi di emergenza danneggiati: ogni parola deve tornare utile al sistema.",
    ],
    sideNote: "Il percorso privilegia comprensione, coesione, nessi logici, lessico preciso e pensiero critico sul testo.",
    ruleTitle: "Regola dell'archivio",
    ruleText: "Puoi esplorare liberamente, ma il segnale testuale è il centro del percorso. Una frase corretta deve essere anche eseguibile.",
    stageHint: "Percorso italiano: cerca soggetto reale, causa, conseguenza, negazioni e dettagli inutili. Il bonus focus premia il segnale.",
    primaryPuzzle: "language",
    challengeStages: [
      { label: "Accordo del sistema", description: "Ripara articolo, nome, verbo e aggettivo mantenendo il significato tecnico." },
      { label: "Causa o dettaglio", description: "Distingui la vera causa del guasto da un particolare visibile ma inutile." },
      { label: "Pronome sotto esame", description: "Chiarisci a quale componente si riferisce il messaggio." },
      { label: "Condizione di sicurezza", description: "Controlla negazioni, finché, se e quindi: una parola cambia l'azione." },
      { label: "Lessico preciso", description: "Scegli parole tecniche corrette, non sinonimi vaghi." },
    ],
    badge: {
      badgeId: "restauratrice-dei-log",
      label: "Restauratrice dei Log",
      description: "Ha ricostruito messaggi precisi, coerenti e utilizzabili.",
    },
    hotspots: {
      language: { label: "Nucleo del messaggio", description: "Il messaggio corrotto va riparato senza alterare causa, ordine e senso tecnico." },
      circuit: { label: "Pannello di verifica", description: "Il circuito conferma se il testo riparato descrive un sistema plausibile." },
      math: { label: "Indice numerico", description: "Il codice ordina l'archivio e richiede controllo dei passaggi." },
      english: { label: "Nota bilingue", description: "Un comando inglese breve va letto come istruzione, non tradotto parola per parola." },
      robot: { label: "Archivista robotico", description: "Il robot recupera una chiave seguendo un piano coerente." },
    },
    objectives: {
      language: { label: "Ripara il messaggio centrale", description: "Correggi accordi, connettivi e riferimenti senza perdere il significato." },
      circuit: { label: "Verifica il pannello", description: "Collega il testo tecnico a una diagnosi elettrica reale." },
      math: { label: "Ordina l'indice", description: "Ricostruisci il codice che cataloga il registro." },
      english: { label: "Decifra la nota bilingue", description: "Individua azione, oggetto e condizione nel comando inglese." },
      robot: { label: "Recupera il fascicolo", description: "Programma il robot per raggiungere il documento chiave." },
    },
  },
  inglese: {
    id: "inglese",
    label: "Percorso Inglese",
    title: "Torre dei Comandi",
    chamberTitle: "Ponte operativo",
    roomTitles: ["Ponte dei Protocolli", "Torre delle Istruzioni", "Sala degli Ordini Condizionati", "Console dei Segnali Esterni"],
    introFragments: [
      "NORA apre il ponte operativo: i sistemi esterni parlano in inglese breve, preciso, senza spazio per supposizioni.",
      "La stanza riceve istruzioni da un settore internazionale dell'Accademia: capire l'ordine delle azioni è vitale.",
      "Eli entra in una sala dove before, after, unless e otherwise sono vere leve di sicurezza.",
    ],
    sideNote: "Il percorso privilegia inglese operativo: verbi d'azione, divieti, condizioni, sequenze e soglie.",
    ruleTitle: "Regola del ponte",
    ruleText: "Puoi affrontare tutto liberamente, ma il modulo inglese è il cuore del percorso. Cerca verbo, oggetto, condizione e divieto.",
    stageHint: "Percorso inglese: leggi l'istruzione come procedura tecnica. Il bonus focus premia il modulo operativo.",
    primaryPuzzle: "english",
    challengeStages: [
      { label: "Comando operativo", description: "Individua verbo d'azione, oggetto corretto e divieto esplicito." },
      { label: "Sequenza tecnica", description: "Ordina piu azioni usando then, before, after e only." },
      { label: "Dati e procedura", description: "Leggi valori, soglie o log guasti prima di scegliere l'azione." },
      { label: "Sicurezza e lessico", description: "Interpreta divieti doppi, comparativi, componenti guasti e limitatori." },
      { label: "Inferenza avanzata", description: "Separa causa, effetto, eccezioni e vincoli temporali in testi brevi." },
    ],
    badge: {
      badgeId: "interprete-operativa",
      label: "Interprete Operativa",
      description: "Ha trasformato istruzioni inglesi in azioni sicure.",
    },
    hotspots: {
      language: { label: "Registro bilingue", description: "Il testo italiano aiuta a non confondere dettaglio e istruzione." },
      circuit: { label: "Circuito di sicurezza", description: "Il pannello verifica se l'azione scelta può essere eseguita senza rischio." },
      math: { label: "Codice di accesso", description: "Il terminale richiede un valore coerente prima di trasmettere l'ordine." },
      english: { label: "Console dei comandi", description: "L'istruzione inglese decide quale azione è autorizzata e quale è vietata." },
      robot: { label: "Unità esecutiva", description: "Il robot applica una sequenza dopo aver ricevuto il comando corretto." },
    },
    objectives: {
      language: { label: "Allinea il registro", description: "Ripara il messaggio italiano che contestualizza il comando esterno." },
      circuit: { label: "Arma la sicurezza", description: "Stabilizza il circuito prima della trasmissione finale." },
      math: { label: "Calibra il codice", description: "Ottieni il valore richiesto dalla procedura di accesso." },
      english: { label: "Interpreta il comando", description: "Distingui azione, ordine temporale, divieto e condizione." },
      robot: { label: "Esegui l'ordine", description: "Guida il robot secondo una sequenza coerente." },
    },
  },
  elettronica: {
    id: "elettronica",
    label: "Percorso Circuiti",
    title: "Banco delle Energie",
    chamberTitle: "Laboratorio circuiti",
    roomTitles: ["Banco dei Guasti Controllati", "Sala della Corrente Stabile", "Officina dei Componenti", "Camera dei Tester"],
    introFragments: [
      "NORA apre il Banco delle Energie: ogni componente ha una funzione e ogni guasto lascia un sintomo.",
      "Eli entra in un laboratorio dove batteria, resistenza, LED, sensori e condensatori devono lavorare insieme.",
      "La sala non chiede formule: chiede di seguire il percorso della corrente e motivare la riparazione.",
    ],
    sideNote: "Il percorso privilegia diagnosi elettronica, componenti, circuito chiuso, protezione e lettura del tester.",
    ruleTitle: "Regola del banco",
    ruleText: "Puoi aprire ogni console, ma il circuito è il centro del percorso. Prima osserva il sintomo, poi scegli solo riparazioni necessarie.",
    stageHint: "Percorso circuiti: segui energia, protezione, polarità, sensore e ritorno. Il bonus focus premia la diagnosi elettrica.",
    primaryPuzzle: "circuit",
    challengeStages: [
      { label: "Circuito chiuso", description: "Segui il percorso corrente: batteria, carico, ritorno." },
      { label: "Protezione del LED", description: "Diagnostica quando il LED si accende ma il circuito non è sicuro." },
      { label: "Polarità", description: "Controlla il verso dei componenti che non funzionano in entrambe le direzioni." },
      { label: "Sensore e bus", description: "Distingui alimentazione, misura e collegamento dati." },
      { label: "Guasto combinato", description: "Ripara solo le cause reali e ignora il rumore di manutenzione." },
    ],
    badge: {
      badgeId: "tecnica-dei-circuiti",
      label: "Tecnica dei Circuiti",
      description: "Ha diagnosticato componenti e percorso della corrente.",
    },
    hotspots: {
      language: { label: "Manuale tecnico", description: "Il testo descrive il guasto: va letto con precisione." },
      circuit: { label: "Banco prova circuito", description: "Il circuito include componenti con funzioni diverse e guasti diagnosticabili." },
      math: { label: "Misuratore numerico", description: "Il terminale richiede una lettura calcolata del sistema." },
      english: { label: "Etichetta di sicurezza", description: "L'istruzione inglese può vietare una manovra rischiosa." },
      robot: { label: "Drone di manutenzione", description: "Il robot porta un attrezzo solo se la sequenza è corretta." },
    },
    objectives: {
      language: { label: "Leggi il manuale", description: "Ripara la frase tecnica che descrive il sintomo." },
      circuit: { label: "Diagnostica il banco", description: "Spiega componente per componente perché il circuito non è stabile." },
      math: { label: "Calcola la lettura", description: "Ricostruisci il valore richiesto dal misuratore." },
      english: { label: "Applica l'etichetta", description: "Segui l'istruzione di sicurezza in inglese." },
      robot: { label: "Invia manutenzione", description: "Programma il robot per recuperare l'attrezzo necessario." },
    },
  },
  coding: {
    id: "coding",
    label: "Percorso Coding",
    title: "Hangar degli Algoritmi",
    chamberTitle: "Hangar robotico",
    roomTitles: ["Hangar delle Sequenze", "Pista del Debug", "Sala dei Comandi Minimi", "Griglia delle Rotte"],
    introFragments: [
      "NORA apre l'hangar robotico: qui ogni comando è una scelta e ogni errore deve essere debuggato.",
      "Eli entra in una pista generata: non basta muovere il robot, bisogna progettare una sequenza essenziale.",
      "La stanza espone una griglia nuova: ostacoli, chiave e uscita cambiano, ma la logica resta verificabile.",
    ],
    sideNote: "Il percorso privilegia sequenze, rotazioni, decomposizione, debugging, efficienza e controllo mentale del percorso.",
    ruleTitle: "Regola dell'hangar",
    ruleText: "Puoi esplorare liberamente, ma il robot è il centro del percorso. Prima simula mentalmente, poi esegui.",
    stageHint: "Percorso coding: orientamento, checkpoint, comandi minimi, debug di programmi guasti e pattern di rotta. Il bonus focus premia la griglia robot.",
    primaryPuzzle: "robot",
    challengeStages: [
      { label: "Sequenza base", description: "Raggiungi chiave e uscita spiegando cosa fa ogni comando." },
      { label: "Rotazioni e coordinate", description: "Pianifica direzione iniziale, svolte e posizione su griglia." },
      { label: "Percorso minimo", description: "Trova una rotta corretta con budget stretto e pochi comandi inutili." },
      { label: "Debug della rotta", description: "Analizza un programma difettoso e riscrivilo prima di eseguirlo." },
      { label: "Checkpoint e pattern", description: "Spezza il problema in tappe ordinate e riconosci una struttura di percorso." },
    ],
    badge: {
      badgeId: "debugger-di-rotta",
      label: "Debugger di Rotta",
      description: "Ha trasformato una mappa in una sequenza controllata.",
    },
    hotspots: {
      language: { label: "Log del robot", description: "Il messaggio descrive lo stato della pista e va riparato." },
      circuit: { label: "Dock di ricarica", description: "Il robot parte solo se il circuito del dock è stabile." },
      math: { label: "Coordinate cifrate", description: "Il terminale calcola un codice legato alla rotta." },
      english: { label: "Comando remoto", description: "L'istruzione inglese stabilisce quando inviare il robot." },
      robot: { label: "Griglia di missione", description: "La griglia generata richiede pianificazione, non tentativi casuali." },
    },
    objectives: {
      language: { label: "Ripara il log robot", description: "Rendi chiaro il messaggio che descrive la rotta." },
      circuit: { label: "Stabilizza il dock", description: "Diagnostica il circuito che alimenta il robot." },
      math: { label: "Calcola le coordinate", description: "Ottieni il codice che sincronizza la griglia." },
      english: { label: "Leggi il comando remoto", description: "Interpreta condizione e ordine operativo." },
      robot: { label: "Programma la rotta", description: "Costruisci una sequenza corretta, breve e verificabile." },
    },
  },
};

export function getProceduralFocusPath(focus: string[] = []): ProceduralFocusPath {
  const key = focus.find((item): item is ProceduralSpecialization =>
    ["matematica", "italiano", "inglese", "elettronica", "coding", "libera"].includes(item),
  ) ?? "libera";
  return proceduralFocusPaths[key] ?? proceduralFocusPaths.libera;
}

export function proceduralFocusChallengeCount(level: number): number {
  if (level >= 6) return 5;
  if (level >= 3) return 4;
  return 3;
}
