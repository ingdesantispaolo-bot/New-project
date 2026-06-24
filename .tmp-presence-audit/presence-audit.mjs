var __defProp = Object.defineProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField = (obj, key, value) => __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);
var _a;
const difficultyPresets = [
  {
    level: 1,
    roomCount: 1,
    puzzleCount: 5,
    mathComplexity: 1,
    robotGrid: { cols: 5, rows: 4 },
    robotObstacleCount: 2,
    circuitComplexity: 1,
    availableHints: 5,
    maxAttemptsBeforeExplanation: 4,
    distractorCount: 1,
    noiseDataCount: 0,
    requiredReasoningSteps: 1,
    pedagogicalFocus: ["osservazione", "ipotesi"]
  },
  {
    level: 2,
    roomCount: 1,
    puzzleCount: 5,
    mathComplexity: 2,
    robotGrid: { cols: 5, rows: 5 },
    robotObstacleCount: 4,
    circuitComplexity: 2,
    availableHints: 4,
    maxAttemptsBeforeExplanation: 4,
    distractorCount: 2,
    noiseDataCount: 0,
    requiredReasoningSteps: 2,
    pedagogicalFocus: ["osservazione", "ipotesi", "diagnosi"]
  },
  {
    level: 3,
    roomCount: 2,
    puzzleCount: 5,
    mathComplexity: 3,
    robotGrid: { cols: 6, rows: 5 },
    robotObstacleCount: 6,
    circuitComplexity: 3,
    availableHints: 3,
    maxAttemptsBeforeExplanation: 3,
    distractorCount: 2,
    noiseDataCount: 1,
    requiredReasoningSteps: 2,
    pedagogicalFocus: ["ipotesi", "diagnosi", "controllo-errore"]
  },
  {
    level: 4,
    roomCount: 2,
    puzzleCount: 5,
    mathComplexity: 4,
    robotGrid: { cols: 7, rows: 5 },
    robotObstacleCount: 8,
    circuitComplexity: 4,
    availableHints: 3,
    maxAttemptsBeforeExplanation: 3,
    distractorCount: 3,
    noiseDataCount: 1,
    requiredReasoningSteps: 3,
    pedagogicalFocus: ["diagnosi", "strategia", "controllo-errore"]
  },
  {
    level: 5,
    roomCount: 3,
    puzzleCount: 5,
    mathComplexity: 5,
    robotGrid: { cols: 7, rows: 6 },
    robotObstacleCount: 10,
    circuitComplexity: 5,
    availableHints: 2,
    maxAttemptsBeforeExplanation: 2,
    distractorCount: 3,
    noiseDataCount: 2,
    requiredReasoningSteps: 3,
    pedagogicalFocus: ["strategia", "controllo-errore", "metacognizione"]
  },
  {
    level: 6,
    roomCount: 3,
    puzzleCount: 6,
    mathComplexity: 6,
    robotGrid: { cols: 8, rows: 6 },
    robotObstacleCount: 12,
    circuitComplexity: 6,
    availableHints: 2,
    maxAttemptsBeforeExplanation: 2,
    distractorCount: 4,
    noiseDataCount: 2,
    requiredReasoningSteps: 4,
    pedagogicalFocus: ["diagnosi", "strategia", "controllo-errore", "metacognizione"]
  },
  {
    level: 7,
    roomCount: 4,
    puzzleCount: 7,
    mathComplexity: 7,
    robotGrid: { cols: 8, rows: 7 },
    robotObstacleCount: 14,
    circuitComplexity: 7,
    availableHints: 1,
    maxAttemptsBeforeExplanation: 2,
    distractorCount: 4,
    noiseDataCount: 3,
    requiredReasoningSteps: 4,
    pedagogicalFocus: ["ipotesi", "diagnosi", "strategia", "controllo-errore", "metacognizione"]
  },
  {
    level: 8,
    roomCount: 4,
    puzzleCount: 8,
    mathComplexity: 8,
    robotGrid: { cols: 9, rows: 7 },
    robotObstacleCount: 16,
    circuitComplexity: 8,
    availableHints: 1,
    maxAttemptsBeforeExplanation: 1,
    distractorCount: 5,
    noiseDataCount: 4,
    requiredReasoningSteps: 5,
    pedagogicalFocus: ["osservazione", "ipotesi", "diagnosi", "strategia", "controllo-errore", "metacognizione"]
  }
];
class DifficultyModel {
  getPreset(level) {
    const normalized = this.normalize(level);
    return difficultyPresets.find((preset) => preset.level === normalized) ?? difficultyPresets[0];
  }
  normalize(level) {
    return Math.min(8, Math.max(1, Math.round(level)));
  }
  describe(level) {
    const preset = this.getPreset(level);
    if (preset.level <= 2) return "osservazione guidata";
    if (preset.level <= 4) return "diagnosi con vincoli";
    if (preset.level <= 6) return "strategia multi-passaggio";
    return "sistema integrato con controllo dell'errore";
  }
}
const difficultyModel = new DifficultyModel();
const proceduralFocusPaths = {
  libera: {
    id: "libera",
    label: "Run libera",
    title: "Laboratorio Sempre Diverso",
    chamberTitle: "Sala riconfigurabile",
    roomTitles: [
      "Sala dei Circuiti Variabili",
      "Officina delle Serrature Vive",
      "Laboratorio delle Tracce Incerte",
      "Camera del Segnale Muto"
    ],
    introFragments: [
      "NORA apre una porta secondaria dell'Accademia: la stanza cambia disposizione ogni volta, ma lascia sempre indizi verificabili.",
      "Il laboratorio si riconfigura con una mappa nuova. Non è caos: è un test controllato di osservazione.",
      "Le pareti ruotano lentamente. Eli vede sistemi diversi, ma la regola resta la stessa: capire prima di agire."
    ],
    sideNote: "Ogni modulo nasce dal seed e viene validato prima di apparire.",
    ruleTitle: "Regola della missione",
    ruleText: "Scegli liberamente una console. Osserva, formula una diagnosi, poi intervieni. Tentare tutto non produce un log affidabile.",
    stageHint: "Rete libera: ogni materia può essere affrontata subito. La porta finale richiede il sistema completo.",
    challengeStages: [],
    badge: {
      badgeId: "cartografa-del-caos-controllato",
      label: "Cartografa del Caos Controllato",
      description: "Ha risolto una missione generata ma validata."
    },
    hotspots: {
      language: { label: "Segnale corrotto", description: "Un pannello linguistico deve essere stabilizzato senza perdere il senso operativo." },
      circuit: { label: "Circuito variabile", description: "Il circuito è cambiato con la stanza: va diagnosticato, non ricordato." },
      math: { label: "Terminale numerico", description: "La serratura calcola energia, non accetta numeri tentati a caso." },
      english: { label: "Modulo inglese", description: "Un comando operativo arriva dall'ala esterna dell'Accademia." },
      robot: { label: "Robot riconfigurato", description: "Il robot deve raggiungere chiave e uscita nella griglia generata." },
      music: { label: "Armonizzatore", description: "Un pentagramma instabile richiede di riconoscere la nota corretta." }
    },
    objectives: {
      language: { label: "Stabilizza il segnale", description: "Ripara il messaggio tecnico senza perdere il senso operativo." },
      circuit: { label: "Diagnostica il circuito", description: "Trova i guasti e ripristina un percorso elettrico stabile." },
      math: { label: "Calcola il codice", description: "Ricostruisci il codice del terminale seguendo la traccia numerica." },
      english: { label: "Decodifica il comando esterno", description: "Esegui solo l'azione autorizzata dall'istruzione inglese." },
      robot: { label: "Guida il robot alla chiave", description: "Costruisci una sequenza coerente nella griglia generata." },
      music: { label: "Riconosci la nota", description: "Leggi la nota sul pentagramma prima che il segnale svanisca." }
    }
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
      "Eli entra in un settore dove i numeri non sono risposte isolate, ma comandi per trasformare la sala."
    ],
    sideNote: "Il percorso alterna calcolo strategico e Officina dei Grafici: formule, punti e parametri diventano trasformazioni visibili.",
    ruleTitle: "Regola della forgia",
    ruleText: "Nel Focus matematica trovi sempre l'Officina dei Grafici. Modifica un parametro alla volta e usa punti, pendenza, vertice e radici come prove.",
    stageHint: "Percorso matematica: una prova è sempre dedicata al piano cartesiano interattivo; osserva come ogni parametro trasforma la curva.",
    primaryPuzzle: "math",
    challengeStages: [
      { label: "Numeri e quote", description: "Lavora su calcolo mentale, frazioni e percentuali dentro una risorsa da gestire." },
      { label: "Officina dei Grafici", description: "Modifica i parametri di rette e parabole sul piano cartesiano e certifica proprietà esatte." },
      { label: "Vincoli e spazio", description: "Combina divisibilità, proporzioni, probabilità o geometria per soddisfare condizioni multiple." },
      { label: "Algebra viva", description: "Usa incognite, operazioni inverse, sistemi o funzioni lineari per risalire a un valore nascosto." },
      { label: "Modelli avanzati", description: "Affronta potenze, radici, crescita, notazione scientifica o log di errore da verificare." }
    ],
    badge: {
      badgeId: "custode-delle-regole-numeriche",
      label: "Custode delle Regole Numeriche",
      description: "Ha riconosciuto trasformazioni, vincoli e controlli d'errore."
    },
    hotspots: {
      language: { label: "Log dei dati", description: "Il testo contiene dati utili e dettagli di disturbo: va riparato prima di usarlo." },
      circuit: { label: "Alimentatore della forgia", description: "Il circuito decide se le macchine numeriche ricevono energia stabile." },
      math: { label: "Officina dei Grafici", description: "Il piano cartesiano reagisce ai parametri: costruisci rette e parabole rispettando punti e proprietà." },
      english: { label: "Protocollo esterno", description: "Un breve comando inglese stabilisce l'ordine sicuro delle operazioni." },
      robot: { label: "Carrello automatico", description: "Il robot trasporta la chiave lungo una griglia che richiede pianificazione." },
      music: { label: "Sequenza sonora", description: "Una nota sul pentagramma calibra il ritmo delle macchine." }
    },
    objectives: {
      language: { label: "Filtra il log dati", description: "Distingui informazione utile e rumore linguistico." },
      circuit: { label: "Stabilizza l'alimentatore", description: "Garantisci energia sicura alle macchine numeriche." },
      math: { label: "Calibra il grafico", description: "Intervieni sui parametri e certifica la curva richiesta sul piano cartesiano." },
      english: { label: "Esegui il protocollo", description: "Interpreta l'istruzione operativa senza invertire ordine o condizione." },
      robot: { label: "Muovi il carrello", description: "Trasforma la pianificazione in una sequenza di comandi." },
      music: { label: "Leggi la nota", description: "Riconosci posizione e ottava sul pentagramma." }
    }
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
      "La sala conserva messaggi di emergenza danneggiati: ogni parola deve tornare utile al sistema."
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
      { label: "Lessico preciso", description: "Scegli parole tecniche corrette, non sinonimi vaghi." }
    ],
    badge: {
      badgeId: "restauratrice-dei-log",
      label: "Restauratrice dei Log",
      description: "Ha ricostruito messaggi precisi, coerenti e utilizzabili."
    },
    hotspots: {
      language: { label: "Nucleo del messaggio", description: "Il messaggio corrotto va riparato senza alterare causa, ordine e senso tecnico." },
      circuit: { label: "Pannello di verifica", description: "Il circuito conferma se il testo riparato descrive un sistema plausibile." },
      math: { label: "Indice numerico", description: "Il codice ordina l'archivio e richiede controllo dei passaggi." },
      english: { label: "Nota bilingue", description: "Un comando inglese breve va letto come istruzione, non tradotto parola per parola." },
      robot: { label: "Archivista robotico", description: "Il robot recupera una chiave seguendo un piano coerente." },
      music: { label: "Archivio sonoro", description: "Il pentagramma contiene una nota da catalogare con precisione." }
    },
    objectives: {
      language: { label: "Ripara il messaggio centrale", description: "Correggi accordi, connettivi e riferimenti senza perdere il significato." },
      circuit: { label: "Verifica il pannello", description: "Collega il testo tecnico a una diagnosi elettrica reale." },
      math: { label: "Ordina l'indice", description: "Ricostruisci il codice che cataloga il registro." },
      english: { label: "Decifra la nota bilingue", description: "Individua azione, oggetto e condizione nel comando inglese." },
      robot: { label: "Recupera il fascicolo", description: "Programma il robot per raggiungere il documento chiave." },
      music: { label: "Classifica la nota", description: "Leggi chiave, riga o spazio e ottava." }
    }
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
      "Eli entra in una sala dove before, after, unless e otherwise sono vere leve di sicurezza."
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
      { label: "Inferenza avanzata", description: "Separa causa, effetto, eccezioni e vincoli temporali in testi brevi." }
    ],
    badge: {
      badgeId: "interprete-operativa",
      label: "Interprete Operativa",
      description: "Ha trasformato istruzioni inglesi in azioni sicure."
    },
    hotspots: {
      language: { label: "Registro bilingue", description: "Il testo italiano aiuta a non confondere dettaglio e istruzione." },
      circuit: { label: "Circuito di sicurezza", description: "Il pannello verifica se l'azione scelta può essere eseguita senza rischio." },
      math: { label: "Codice di accesso", description: "Il terminale richiede un valore coerente prima di trasmettere l'ordine." },
      english: { label: "Console dei comandi", description: "L'istruzione inglese decide quale azione è autorizzata e quale è vietata." },
      robot: { label: "Unità esecutiva", description: "Il robot applica una sequenza dopo aver ricevuto il comando corretto." },
      music: { label: "Segnale musicale", description: "La console mostra una nota che va letta prima della trasmissione." }
    },
    objectives: {
      language: { label: "Allinea il registro", description: "Ripara il messaggio italiano che contestualizza il comando esterno." },
      circuit: { label: "Arma la sicurezza", description: "Stabilizza il circuito prima della trasmissione finale." },
      math: { label: "Calibra il codice", description: "Ottieni il valore richiesto dalla procedura di accesso." },
      english: { label: "Interpreta il comando", description: "Distingui azione, ordine temporale, divieto e condizione." },
      robot: { label: "Esegui l'ordine", description: "Guida il robot secondo una sequenza coerente." },
      music: { label: "Identifica la nota", description: "Riconosci la nota sul pentagramma come segnale ausiliario." }
    }
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
      "La sala non chiede formule: chiede di seguire il percorso della corrente e motivare la riparazione."
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
      { label: "Guasto combinato", description: "Ripara solo le cause reali e ignora il rumore di manutenzione." }
    ],
    badge: {
      badgeId: "tecnica-dei-circuiti",
      label: "Tecnica dei Circuiti",
      description: "Ha diagnosticato componenti e percorso della corrente."
    },
    hotspots: {
      language: { label: "Manuale tecnico", description: "Il testo descrive il guasto: va letto con precisione." },
      circuit: { label: "Banco prova circuito", description: "Il circuito include componenti con funzioni diverse e guasti diagnosticabili." },
      math: { label: "Misuratore numerico", description: "Il terminale richiede una lettura calcolata del sistema." },
      english: { label: "Etichetta di sicurezza", description: "L'istruzione inglese può vietare una manovra rischiosa." },
      robot: { label: "Drone di manutenzione", description: "Il robot porta un attrezzo solo se la sequenza è corretta." },
      music: { label: "Oscilloscopio musicale", description: "Una nota calibrata stabilizza il segnale del banco." }
    },
    objectives: {
      language: { label: "Leggi il manuale", description: "Ripara la frase tecnica che descrive il sintomo." },
      circuit: { label: "Diagnostica il banco", description: "Spiega componente per componente perché il circuito non è stabile." },
      math: { label: "Calcola la lettura", description: "Ricostruisci il valore richiesto dal misuratore." },
      english: { label: "Applica l'etichetta", description: "Segui l'istruzione di sicurezza in inglese." },
      robot: { label: "Invia manutenzione", description: "Programma il robot per recuperare l'attrezzo necessario." },
      music: { label: "Calibra la nota", description: "Leggi la nota sul pentagramma per allineare il segnale." }
    }
  },
  coding: {
    id: "coding",
    label: "Percorso Coding",
    title: "Laboratorio degli Algoritmi",
    chamberTitle: "Console algoritmica",
    roomTitles: ["Sala del Tracing", "Archivio delle Variabili", "Banco dei Cicli", "Nucleo del Debug"],
    introFragments: [
      "NORA apre il laboratorio degli algoritmi: qui ogni riga cambia lo stato del sistema.",
      "Eli entra in una console generata: non basta indovinare l'output, bisogna seguire il codice passo dopo passo.",
      "La stanza proietta pseudocodice vivo: variabili, cicli e condizioni decidono quali porte si attivano."
    ],
    sideNote: "Il percorso privilegia tracing, variabili, cicli, condizioni, logica booleana, decomposizione e debugging.",
    ruleTitle: "Regola della console",
    ruleText: "Puoi iniziare da qualunque modulo. Prima simula il codice mentalmente, poi scegli la risposta certificabile.",
    stageHint: "Percorso coding: output, stato delle variabili, cicli, condizioni, booleani e debug. Il robot resta una missione ambientale, ma qui si allena il pensiero algoritmico.",
    primaryPuzzle: "coding",
    challengeStages: [
      { label: "Tracing output", description: "Esegui mentalmente righe di pseudocodice e prevedi cosa viene stampato." },
      { label: "Stato variabili", description: "Segui assegnazioni e aggiornamenti senza confondere valore iniziale e finale." },
      { label: "Cicli e condizioni", description: "Conta ripetizioni e scegli il ramo realmente eseguito." },
      { label: "Logica booleana", description: "Combina vero/falso con AND e condizioni multiple." },
      { label: "Debug del codice", description: "Trova la riga che rompe la regola e correggi la causa, non il sintomo." }
    ],
    badge: {
      badgeId: "debugger-di-rotta",
      label: "Debugger di Algoritmi",
      description: "Ha seguito stati, condizioni e cicli fino a una risposta verificabile."
    },
    hotspots: {
      language: { label: "Log del robot", description: "Il messaggio descrive lo stato della pista e va riparato." },
      circuit: { label: "Dock di ricarica", description: "Il robot parte solo se il circuito del dock è stabile." },
      math: { label: "Coordinate cifrate", description: "Il terminale calcola un codice legato alla rotta." },
      english: { label: "Comando remoto", description: "L'istruzione inglese stabilisce quando inviare il robot." },
      robot: { label: "Griglia di missione", description: "La griglia generata richiede pianificazione, non tentativi casuali." },
      music: { label: "Modulo di scansione", description: "Una nota sul pentagramma scandisce l'avvio del percorso." }
    },
    objectives: {
      language: { label: "Ripara il log robot", description: "Rendi chiaro il messaggio che descrive la rotta." },
      circuit: { label: "Stabilizza il dock", description: "Diagnostica il circuito che alimenta il robot." },
      math: { label: "Calcola le coordinate", description: "Ottieni il codice che sincronizza la griglia." },
      english: { label: "Leggi il comando remoto", description: "Interpreta condizione e ordine operativo." },
      robot: { label: "Programma la rotta", description: "Costruisci una sequenza corretta, breve e verificabile." },
      music: { label: "Leggi il segnale", description: "Riconosci nota, chiave e posizione prima dell'esecuzione." }
    }
  },
  musica: {
    id: "musica",
    label: "Percorso Musica",
    title: "Osservatorio del Pentagramma",
    chamberTitle: "Sala delle Risonanze",
    roomTitles: ["Sala delle Chiavi", "Osservatorio delle Linee", "Galleria delle Note Alte", "Camera delle Note Profonde"],
    introFragments: [
      "NORA apre una sala silenziosa: qui ogni porta vibra solo quando Eli riconosce la nota scritta sul pentagramma.",
      "Le pareti mostrano chiavi di violino e basso. Il sistema non chiede memoria: chiede posizione, chiave e controllo dell'ottava.",
      "Un pentagramma luminoso attraversa la stanza. Le note sopra e sotto le linee sono segnali da leggere con calma e precisione."
    ],
    sideNote: "Il percorso privilegia lettura del pentagramma; il riconoscimento dal suono resta una sfida avanzata da sbloccare dopo.",
    ruleTitle: "Regola della risonanza",
    ruleText: "Guarda prima la chiave, poi conta linee e spazi. Le linee addizionali sopra e sotto cambiano posizione e spesso ottava.",
    stageHint: "Percorso musica: ogni console mostra una nota diversa. Il tempo scende con il livello, ma puoi usare indizi per ragionare.",
    primaryPuzzle: "music",
    challengeStages: [
      { label: "Chiave di violino", description: "Riconosci note interne al pentagramma in chiave di violino." },
      { label: "Spazi e linee", description: "Distingui righe e spazi senza saltare passaggi." },
      { label: "Chiave di basso", description: "Leggi note in chiave di basso usando il Fa come riferimento." },
      { label: "Linee addizionali", description: "Riconosci note sopra e sotto il pentagramma controllando l'ottava." },
      { label: "Lettura rapida", description: "Alterna chiavi e note estreme con tempo ridotto." }
    ],
    badge: {
      badgeId: "lettrice-del-pentagramma",
      label: "Lettrice del Pentagramma",
      description: "Ha riconosciuto note in chiave di violino, basso e linee addizionali."
    },
    hotspots: {
      language: { label: "Registro ritmico", description: "Il testo descrive una regola di lettura da non confondere." },
      circuit: { label: "Amplificatore", description: "Il circuito alimenta il banco sonoro." },
      math: { label: "Metronomo numerico", description: "Il terminale misura intervalli e tempo di risposta." },
      english: { label: "Etichetta audio", description: "Un comando inglese indica una procedura di ascolto." },
      robot: { label: "Carrello spartiti", description: "Il robot porta lo spartito corretto." },
      music: { label: "Pentagramma vivo", description: "La nota va riconosciuta da posizione, chiave e linee addizionali." }
    },
    objectives: {
      language: { label: "Leggi la regola", description: "Capisci l'istruzione testuale che spiega il pentagramma." },
      circuit: { label: "Accendi l'amplificatore", description: "Stabilizza l'energia del banco sonoro." },
      math: { label: "Sincronizza il metronomo", description: "Calcola una soglia di tempo o ritmo." },
      english: { label: "Decodifica l'etichetta", description: "Interpreta un comando operativo audio in inglese." },
      robot: { label: "Recupera lo spartito", description: "Programma il robot verso la partitura." },
      music: { label: "Riconosci la nota", description: "Identifica la nota sul pentagramma entro il tempo previsto." }
    }
  }
};
function getProceduralFocusPath(focus = []) {
  const key = focus.find(
    (item) => ["matematica", "italiano", "inglese", "elettronica", "coding", "musica", "libera"].includes(item)
  ) ?? "libera";
  return proceduralFocusPaths[key] ?? proceduralFocusPaths.libera;
}
function proceduralFocusChallengeCount(level) {
  if (level >= 6) return 5;
  if (level >= 3) return 4;
  return 3;
}
class MapGenerator {
  generate(random, difficulty, focus = []) {
    const path = getProceduralFocusPath(focus);
    const title = random.pick(path.roomTitles);
    const allHotspots = [
      {
        id: "language",
        label: path.hotspots.language.label,
        x: 382,
        y: 472,
        radius: 42,
        puzzleId: "language",
        description: path.hotspots.language.description
      },
      {
        id: "circuit",
        label: path.hotspots.circuit.label,
        x: 312,
        y: 256,
        radius: 52,
        puzzleId: "circuit",
        description: path.hotspots.circuit.description
      },
      {
        id: "math",
        label: path.hotspots.math.label,
        x: 640,
        y: 220,
        radius: 56,
        puzzleId: "math",
        description: path.hotspots.math.description
      },
      {
        id: "english",
        label: path.hotspots.english.label,
        x: 914,
        y: 254,
        radius: 50,
        puzzleId: "english",
        description: path.hotspots.english.description
      },
      {
        id: "robot",
        label: path.hotspots.robot.label,
        x: 914,
        y: 502,
        radius: 56,
        puzzleId: "robot",
        description: path.hotspots.robot.description
      },
      {
        id: "music",
        label: path.hotspots.music.label,
        x: 640,
        y: 502,
        radius: 52,
        puzzleId: "music",
        description: path.hotspots.music.description
      }
    ];
    const activeHotspots = path.primaryPuzzle ? this.focusHotspots(path.primaryPuzzle, path.challengeStages, difficulty.level) : allHotspots;
    return {
      id: `procedural-room-map-${path.id}`,
      title,
      roomCount: difficulty.roomCount,
      hotspots: [
        ...activeHotspots,
        {
          id: "door",
          label: "Porta di uscita",
          x: 640,
          y: 650,
          radius: 64,
          description: "La porta si apre solo quando tutti i sistemi della missione sono coerenti."
        }
      ]
    };
  }
  focusHotspots(puzzleKind, stages, level) {
    const positions = [
      { x: 382, y: 256 },
      { x: 640, y: 220 },
      { x: 914, y: 256 },
      { x: 458, y: 502 },
      { x: 830, y: 502 }
    ];
    return stages.slice(0, proceduralFocusChallengeCount(level)).map((stage, index) => ({
      id: `${puzzleKind}-${index + 1}`,
      label: stage.label,
      x: positions[index].x,
      y: positions[index].y,
      radius: index === 0 ? 56 : 50,
      puzzleId: `${puzzleKind}-${index + 1}`,
      puzzleKind,
      description: stage.description
    }));
  }
}
const circuitNodes = ["battery", "switch", "resistor", "led", "return"];
const optionalCircuitNodes = ["sensor", "capacitor", "branchLed", "relay", "motor", "ground"];
const circuitBaseEdges = [
  { from: "battery", to: "switch" },
  { from: "switch", to: "resistor" },
  { from: "resistor", to: "led" },
  { from: "led", to: "return" },
  { from: "return", to: "battery" }
];
const circuitFaultTemplates = [
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
  { type: "loose-ground", label: "Ritorno a massa instabile", hint: "Il ritorno al polo negativo deve essere stabile, non solo presente a tratti.", minComplexity: 6 }
];
const circuitComponentGuide = [
  {
    id: "battery",
    label: "Batteria",
    role: "fornisce una differenza di potenziale: nel gioco è la spinta che mette in moto la corrente",
    check: "controlla sempre dove sono + e -",
    symbolName: "due piastre parallele di lunghezza diversa",
    functionSummary: "fornisce la spinta elettrica tra polo + e polo -",
    symbolClue: "la piastra lunga indica il polo positivo",
    commonConfusion: "non è una resistenza: non limita la corrente, la alimenta"
  },
  {
    id: "switch",
    label: "Interruttore",
    role: "apre o chiude il percorso: se è aperto il circuito è interrotto anche se tutti i pezzi sono presenti",
    check: "verifica se la leva collega davvero i due contatti",
    symbolName: "due contatti con una leva mobile",
    functionSummary: "apre o chiude il passaggio della corrente",
    symbolClue: "la leva inclinata indica circuito aperto",
    commonConfusion: "non genera corrente: decide solo se il percorso continua"
  },
  {
    id: "resistor",
    label: "Resistenza",
    role: "limita la corrente e protegge il LED da impulsi troppo forti",
    check: "se manca, il LED non è certificabile anche quando si accende",
    symbolName: "zig-zag in serie sul filo",
    functionSummary: "limita la corrente e protegge i componenti sensibili",
    symbolClue: "il valore in ohm indica quanta opposizione offre",
    commonConfusion: "non serve ad accendere di più: serve a non sovraccaricare"
  },
  {
    id: "led",
    label: "LED",
    role: "è un diodo luminoso: lascia passare corrente quasi solo nel verso corretto",
    check: "se arriva corrente ma resta spento, controlla la polarità",
    symbolName: "diodo con due frecce luminose",
    functionSummary: "emette luce solo se polarità e corrente sono corrette",
    symbolClue: "il triangolo/freccia e la barretta mostrano il verso",
    commonConfusion: "non è una lampadina normale: il verso conta"
  },
  {
    id: "sensor",
    label: "Sensore",
    role: "misura un valore e lo manda al terminale, ma solo se è alimentato e collegato al bus dati",
    check: "un sensore scollegato può sembrare guasto anche quando il circuito principale funziona",
    symbolName: "modulo con ingresso circolare e freccia dati",
    functionSummary: "misura un segnale e invia dati al terminale",
    symbolClue: "ha sia alimentazione sia uscita dati",
    commonConfusion: "se non è alimentato, non può misurare"
  },
  {
    id: "capacitor",
    label: "Condensatore",
    role: "accumula una piccola carica e la rilascia per stabilizzare impulsi brevi",
    check: "se è scarico, il LED può fare un lampo debole o ritardato",
    symbolName: "due piastre uguali affiancate",
    functionSummary: "accumula carica e la rilascia per stabilizzare impulsi",
    symbolClue: "due piastre vicine suggeriscono accumulo",
    commonConfusion: "non è una batteria: non produce energia nuova, la conserva per poco"
  },
  {
    id: "return",
    label: "Ritorno",
    role: "riporta il percorso verso il polo negativo: senza ritorno non c'è circuito chiuso",
    check: "segui il filo fino al - della batteria",
    symbolName: "linea di ritorno verso il polo negativo",
    functionSummary: "chiude il giro riportando la corrente al polo -",
    symbolClue: "senza questo tratto la linea finisce nel vuoto",
    commonConfusion: "non è opzionale: ogni circuito deve tornare alla sorgente"
  },
  {
    id: "branchLed",
    label: "Ramo parallelo",
    role: "crea un secondo percorso: un guasto su un ramo non deve per forza spegnere tutto il circuito",
    check: "controlla quale ramo resta alimentato e quale si interrompe",
    symbolName: "biforcazione con due percorsi",
    functionSummary: "divide la corrente in rami che possono funzionare separatamente",
    symbolClue: "due strade partono dagli stessi nodi",
    commonConfusion: "non trattarlo come un unico filo in serie"
  },
  {
    id: "relay",
    label: "Relè",
    role: "usa una piccola corrente di comando per chiudere un circuito più potente",
    check: "verifica sia la bobina di comando sia il contatto che alimenta il carico",
    symbolName: "bobina con contatto comandato",
    functionSummary: "usa un comando debole per chiudere un circuito di potenza",
    symbolClue: "ha una parte di comando e una parte di contatto",
    commonConfusion: "non è solo un interruttore manuale: viene comandato elettricamente"
  },
  {
    id: "motor",
    label: "Motore",
    role: "è un carico più esigente di un LED: richiede alimentazione stabile e protezione",
    check: "se il LED funziona ma il motore no, controlla caduta di tensione e relè",
    symbolName: "cerchio con lettera M",
    functionSummary: "trasforma energia elettrica in movimento",
    symbolClue: "la M indica il carico meccanico",
    commonConfusion: "non è un sensore: consuma energia, non misura"
  },
  {
    id: "ground",
    label: "Massa",
    role: "è il riferimento di ritorno del circuito: se è ballerina, le misure diventano instabili",
    check: "cerca letture che passano da continuità a interruzione",
    symbolName: "tre linee orizzontali decrescenti",
    functionSummary: "stabilizza il riferimento comune del ritorno",
    symbolClue: "le linee a scalare indicano riferimento a massa",
    commonConfusion: "non è un interruttore: è un riferimento stabile"
  }
];
const faultObservations = {
  "missing-wire": "Il tester non legge continuità tra LED e ritorno: il percorso si interrompe dopo il LED.",
  "open-switch": "La leva dell'interruttore è sollevata: prima della resistenza la corrente si ferma.",
  "reversed-led": "Il LED resta spento anche se arriva corrente: la polarità potrebbe essere invertita.",
  "missing-resistor": "Il LED lampeggia in modo instabile: manca un componente che limiti la corrente.",
  "disconnected-component": "Il sensore rileva un componente presente ma fuori dal percorso principale.",
  "sensor-unpowered": "Il sensore non manda dati al terminale: i suoi morsetti non ricevono alimentazione.",
  "capacitor-discharged": "Il LED fa solo un lampo debole: il condensatore non accumula carica sufficiente.",
  "short-circuit": "Il tester segnala continuità quasi diretta tra + e ritorno: la corrente può saltare il carico.",
  "parallel-branch-open": "Il LED principale si accende, ma il ramo secondario resta spento: il guasto è locale, non generale.",
  "wrong-resistor-value": "Il LED si accende troppo debole o troppo forte: il circuito funziona, ma la protezione non è adeguata.",
  "relay-not-armed": "Il comando arriva al relè, ma il contatto di potenza resta aperto: il carico non parte.",
  "loose-ground": "La misura sul ritorno cambia quando il pannello vibra: il collegamento a massa non è stabile."
};
const explanationByFault = {
  "missing-wire": "Un filo mancante interrompe il giro: anche con batteria e LED corretti non circola corrente.",
  "open-switch": "Un interruttore aperto è una pausa volontaria nel percorso: chiuderlo rende continuo il ramo.",
  "reversed-led": "Il LED è un diodo: nel verso sbagliato blocca la corrente e resta spento.",
  "missing-resistor": "La resistenza protegge il LED limitando la corrente. Senza protezione il circuito non è sicuro.",
  "disconnected-component": "Un componente fuori percorso non partecipa al circuito: va ricollegato al nodo corretto.",
  "sensor-unpowered": "Un sensore può leggere dati solo se riceve alimentazione e ha un ritorno affidabile.",
  "capacitor-discharged": "Il condensatore accumula carica: se è scarico non stabilizza un impulso breve.",
  "short-circuit": "Un corto crea una scorciatoia a bassa resistenza: la corrente evita il carico e può danneggiare il circuito.",
  "parallel-branch-open": "Nei rami paralleli una parte può funzionare mentre l'altra è interrotta: bisogna isolare il ramo guasto.",
  "wrong-resistor-value": "Il valore della resistenza cambia quanta corrente passa: non basta che il LED si accenda.",
  "relay-not-armed": "Il relè separa comando e potenza: se la bobina non è alimentata, il contatto del carico resta aperto.",
  "loose-ground": "Un ritorno instabile fa sembrare casuali le misure: il circuito ha bisogno di un riferimento stabile."
};
class CircuitFaultGenerator {
  generate(random, difficulty, preferredFaults = []) {
    const eligibleFaults = circuitFaultTemplates.filter((fault) => (fault.minComplexity ?? 1) <= difficulty.circuitComplexity);
    const faultCount = Math.min(1 + Math.floor(difficulty.circuitComplexity / 3), 3, eligibleFaults.length);
    const preferredPool = preferredFaults.length > 0 ? eligibleFaults.filter((fault) => preferredFaults.includes(fault.type)) : [];
    const firstFault = preferredPool.length > 0 ? [random.pick(preferredPool)] : [];
    const remainingPool = random.shuffle(eligibleFaults.filter((fault) => !firstFault.some((selected) => selected.type === fault.type)));
    const faults = [...firstFault, ...remainingPool].slice(0, faultCount);
    const missingWire = faults.some((fault) => fault.type === "missing-wire");
    const edges = missingWire ? circuitBaseEdges.slice(0, -1) : [...circuitBaseEdges];
    const faultTypes = faults.map((fault) => fault.type);
    const scenarioType = this.scenarioType(faultTypes);
    const nodes = this.nodesForFaults(faultTypes);
    const testerReadings = this.testerReadingsForFaults(faultTypes, random);
    const repairChoices = this.repairChoicesForFaults(faultTypes, random, difficulty.circuitComplexity);
    const componentChallenges = this.componentChallengesForFaults(faultTypes, nodes, random, difficulty.level);
    const observations = [
      ...faults.map((fault) => faultObservations[fault.type]),
      ...this.noiseObservations(random, difficulty.noiseDataCount)
    ];
    return {
      id: "circuit-fault",
      title: this.titleForScenario(scenarioType),
      symptom: this.describeSymptom(faultTypes),
      observations: random.shuffle(observations),
      nodes,
      edges,
      faults: faultTypes,
      requiredRepairs: faultTypes,
      hints: [
        "Segui prima il giro completo: batteria, interruttore, protezione, LED, ritorno.",
        "Distingui tre domande: il percorso è chiuso? il componente ha il verso giusto? la corrente è protetta?",
        ...faults.map((fault) => fault.hint)
      ],
      scenarioType,
      diagnosticQuestion: this.questionForScenario(scenarioType),
      testerReadings,
      explanationByFault: Object.fromEntries(faultTypes.map((fault) => [fault, explanationByFault[fault]])),
      componentGuide: circuitComponentGuide.filter((component) => nodes.includes(component.id)),
      circuitGoal: this.goalForScenario(scenarioType),
      repairChoices,
      diagnosticPlan: this.diagnosticPlanForScenario(scenarioType),
      difficultyLabel: `Livello ${difficulty.level} - ${this.levelName(difficulty.level)}`,
      learningPurpose: this.learningPurposeForScenario(scenarioType),
      conceptTags: this.conceptsForFaults(faultTypes),
      componentChallenges,
      competencies: ["elettronica.circuitoChiuso", "problemSolving", "pensieroCritico"]
    };
  }
  fallback(level = 1, random, difficulty) {
    if (random && difficulty) {
      const safeFaults = circuitFaultTemplates.filter((fault) => (fault.minComplexity ?? 1) <= 1).map((fault) => fault.type);
      return this.generate(random.fork("safe-circuit"), {
        ...difficulty,
        circuitComplexity: 1,
        noiseDataCount: 0
      }, [random.pick(safeFaults)]);
    }
    const fallbackNodes = [...circuitNodes];
    return {
      id: "circuit-fallback",
      title: "Circuito con interruttore aperto",
      symptom: "Il LED resta spento e il tester segnala percorso interrotto prima della resistenza.",
      observations: [faultObservations["open-switch"]],
      nodes: fallbackNodes,
      edges: [...circuitBaseEdges],
      faults: ["open-switch"],
      requiredRepairs: ["open-switch"],
      hints: ["L'interruttore interrompe il percorso: chiuderlo completa il giro."],
      scenarioType: "percorso-aperto",
      diagnosticQuestion: "Dove si interrompe il giro della corrente?",
      testerReadings: [
        { from: "Batteria +", to: "Interruttore", reading: "continuita", note: "La corrente arriva al primo contatto." },
        { from: "Interruttore", to: "Resistenza", reading: "interrotto", note: "La leva aperta interrompe il percorso." }
      ],
      explanationByFault: { "open-switch": explanationByFault["open-switch"] },
      componentGuide: circuitComponentGuide.filter((component) => circuitNodes.includes(component.id)),
      circuitGoal: this.goalForScenario("percorso-aperto"),
      repairChoices: ["open-switch", "missing-wire", "missing-resistor"],
      diagnosticPlan: this.diagnosticPlanForScenario("percorso-aperto"),
      difficultyLabel: "Livello 1 - percorso chiuso",
      learningPurpose: this.learningPurposeForScenario("percorso-aperto"),
      conceptTags: ["circuito chiuso", "interruttore", "continuità"],
      componentChallenges: level > 3 ? [this.fallbackComponentChallenge("switch")] : [],
      competencies: ["elettronica.circuitoChiuso", "problemSolving"]
    };
  }
  fallbackComponentChallenge(componentId) {
    const component = circuitComponentGuide.find((item) => item.id === componentId) ?? circuitComponentGuide[0];
    const distractors = circuitComponentGuide.filter((item) => item.id !== component.id).slice(0, 2);
    const correctSymbol = component.symbolName ?? component.label;
    const correctFunction = component.functionSummary ?? component.role;
    return {
      componentId: component.id,
      componentLabel: component.label,
      symbolQuestion: "Quale simbolo è evidenziato nello schema?",
      functionQuestion: "Quale funzione svolge nel circuito?",
      correctSymbol,
      correctFunction,
      symbolChoices: [correctSymbol, ...distractors.map((item) => item.symbolName ?? item.label)],
      functionChoices: [correctFunction, ...distractors.map((item) => item.functionSummary ?? item.role)],
      explanation: `${component.label}: ${component.role}. Indizio visivo: ${component.symbolClue ?? component.check}. Attenzione: ${component.commonConfusion ?? component.check}.`
    };
  }
  scenarioType(faults) {
    if (faults.length > 1) return "multi-guasto";
    if (faults.includes("short-circuit")) return "corto-circuito";
    if (faults.includes("parallel-branch-open")) return "serie-parallelo";
    if (faults.includes("relay-not-armed")) return "logica-rele";
    if (faults.includes("missing-resistor")) return "corrente-instabile";
    if (faults.includes("wrong-resistor-value")) return "corrente-instabile";
    if (faults.includes("reversed-led")) return "polarita";
    if (faults.includes("sensor-unpowered")) return "sensore-soglia";
    if (faults.includes("capacitor-discharged")) return "temporizzazione";
    if (faults.includes("loose-ground")) return "corrente-instabile";
    return "percorso-aperto";
  }
  titleForScenario(scenario) {
    return {
      "percorso-aperto": "Diagnosi: percorso interrotto",
      "corrente-instabile": "Diagnosi: corrente non protetta",
      polarita: "Diagnosi: LED in polarità sospetta",
      "multi-guasto": "Diagnosi: guasto combinato",
      "serie-parallelo": "Diagnosi: ramo parallelo",
      "sensore-soglia": "Diagnosi: sensore non operativo",
      "logica-rele": "Diagnosi: relè di comando",
      temporizzazione: "Diagnosi: impulso non stabilizzato",
      "corto-circuito": "Diagnosi: corto circuito"
    }[scenario ?? "percorso-aperto"];
  }
  questionForScenario(scenario) {
    return {
      "percorso-aperto": "Quale punto impedisce alla corrente di completare il giro?",
      "corrente-instabile": "Il percorso esiste, ma perché il LED non è certificabile?",
      polarita: "Se la corrente arriva al LED, quale proprietà del componente va controllata?",
      "multi-guasto": "Quali cause sono reali e quali interventi sarebbero solo tentativi?",
      "serie-parallelo": "Quale ramo è interrotto, se il circuito principale continua a funzionare?",
      "sensore-soglia": "Perché il terminale non legge il sensore anche se il LED può accendersi?",
      "logica-rele": "Il comando arriva, ma quale parte del relè non permette al carico di partire?",
      temporizzazione: "Perché l'impulso non resta stabile abbastanza a lungo?",
      "corto-circuito": "Dove la corrente trova una scorciatoia che evita il carico?"
    }[scenario ?? "percorso-aperto"];
  }
  goalForScenario(scenario) {
    return {
      "percorso-aperto": "Obiettivo: creare un giro chiuso dal + della batteria al LED e ritorno al -. Se un solo tratto è aperto, la corrente non circola.",
      "corrente-instabile": "Obiettivo: non basta accendere il LED. Il circuito deve essere stabile, protetto e leggibile dal terminale.",
      polarita: "Obiettivo: capire che alcuni componenti hanno un verso. Il LED è un diodo luminoso: la polarità conta.",
      "multi-guasto": "Obiettivo: separare le cause reali dai dettagli inutili. Ripara solo ciò che il tester rende necessario.",
      "serie-parallelo": "Obiettivo: capire che due rami possono comportarsi diversamente. Isola il ramo guasto senza cambiare quello sano.",
      "sensore-soglia": "Obiettivo: collegare alimentazione e dato. Un sensore non misura se non riceve energia stabile.",
      "logica-rele": "Obiettivo: distinguere circuito di comando e circuito di potenza. Il relè collega i due mondi.",
      temporizzazione: "Obiettivo: usare il condensatore come piccola riserva di energia per impulsi brevi.",
      "corto-circuito": "Obiettivo: riconoscere una scorciatoia pericolosa: il percorso più facile non è quello corretto."
    }[scenario ?? "percorso-aperto"];
  }
  nodesForFaults(faults) {
    const nodes = new Set(circuitNodes);
    if (faults.includes("sensor-unpowered") || faults.includes("disconnected-component")) nodes.add(optionalCircuitNodes[0]);
    if (faults.includes("capacitor-discharged")) nodes.add(optionalCircuitNodes[1]);
    if (faults.includes("parallel-branch-open")) nodes.add(optionalCircuitNodes[2]);
    if (faults.includes("relay-not-armed")) nodes.add(optionalCircuitNodes[3]);
    if (faults.includes("relay-not-armed")) nodes.add(optionalCircuitNodes[4]);
    if (faults.includes("loose-ground") || faults.includes("short-circuit")) nodes.add(optionalCircuitNodes[5]);
    return [...nodes];
  }
  testerReadingsForFaults(faults, random) {
    const readings = [
      { from: "Batteria +", to: "Interruttore", reading: "continuita", note: "La sorgente è presente: il problema è più avanti nel percorso." }
    ];
    const byFault = {
      "missing-wire": { from: "LED", to: "Ritorno", reading: "interrotto", note: "Dopo il LED il percorso si apre: manca un tratto di filo." },
      "open-switch": { from: "Interruttore", to: "Resistenza", reading: "interrotto", note: "La leva non chiude i due contatti." },
      "reversed-led": { from: "Resistenza", to: "LED", reading: "polarita-inversa", note: "Arriva corrente, ma il verso del LED non è compatibile." },
      "missing-resistor": { from: "Resistenza", to: "LED", reading: "non-stabile", note: "Il LED riceve impulsi non limitati: manca protezione." },
      "disconnected-component": { from: "Sensore", to: "Bus dati", reading: "interrotto", note: "Il componente è fisicamente presente ma fuori nodo." },
      "sensor-unpowered": { from: "Batteria +", to: "Sensore", reading: "tensione-bassa", note: "Il sensore non riceve energia sufficiente per misurare." },
      "capacitor-discharged": { from: "Condensatore", to: "Ritorno", reading: "carica-bassa", note: "La carica non resta abbastanza per stabilizzare l'impulso." },
      "short-circuit": { from: "Batteria +", to: "Ritorno", reading: "corto", note: "C'è una scorciatoia: la corrente evita resistenza e LED." },
      "parallel-branch-open": { from: "Ramo B", to: "Ritorno", reading: "interrotto", note: "Il ramo principale è vivo, ma il secondo ramo non chiude il giro." },
      "wrong-resistor-value": { from: "Resistenza", to: "LED", reading: "non-stabile", note: "Il componente c'è, ma il valore rende la corrente non adatta al LED." },
      "relay-not-armed": { from: "Bobina relè", to: "Ritorno", reading: "tensione-bassa", note: "Il contatto di potenza resta aperto perché la bobina non è armata." },
      "loose-ground": { from: "Ritorno", to: "Massa", reading: "non-stabile", note: "La continuità compare e sparisce: il riferimento non è affidabile." }
    };
    faults.forEach((fault) => readings.push(byFault[fault]));
    const confirmation = [
      { from: "Batteria -", to: "Ritorno", reading: "continuita", note: "Il tester conferma che una parte del ritorno è raggiungibile." },
      { from: "Terminale", to: "Pannello", reading: "continuita", note: "Il pannello comunica: il guasto è nel circuito di carico." },
      { from: "Telaio", to: "Vite del coperchio", reading: "continuita", note: "La vite non spiega il sintomo: è un falso indizio." }
    ];
    return random.shuffle([...readings, ...random.shuffle(confirmation).slice(0, 1 + Math.min(2, faults.length))]);
  }
  repairChoicesForFaults(faults, random, complexity) {
    const required = new Set(faults);
    const distractorCount = Math.max(1, Math.min(6 - faults.length, 2 + Math.floor(complexity / 3)));
    const distractors = random.shuffle(circuitFaultTemplates.map((fault) => fault.type).filter((fault) => !required.has(fault))).slice(0, distractorCount);
    return random.shuffle([...faults, ...distractors]);
  }
  componentChallengesForFaults(faults, nodes, random, level) {
    if (level <= 3) {
      return [];
    }
    const priorityByFault = {
      "missing-wire": ["return", "battery"],
      "open-switch": ["switch", "battery"],
      "reversed-led": ["led", "resistor"],
      "missing-resistor": ["resistor", "led"],
      "disconnected-component": ["sensor", "return"],
      "sensor-unpowered": ["sensor", "battery"],
      "capacitor-discharged": ["capacitor", "battery"],
      "short-circuit": ["resistor", "ground", "battery"],
      "parallel-branch-open": ["branchLed", "return"],
      "wrong-resistor-value": ["resistor", "led"],
      "relay-not-armed": ["relay", "motor"],
      "loose-ground": ["ground", "return"]
    };
    const ordered = /* @__PURE__ */ new Set();
    faults.forEach((fault) => {
      priorityByFault[fault].filter((componentId) => nodes.includes(componentId)).forEach((componentId) => ordered.add(componentId));
    });
    nodes.filter((componentId) => circuitComponentGuide.some((component) => component.id === componentId)).forEach((componentId) => ordered.add(componentId));
    const count = level >= 7 ? 2 : 1;
    return [...ordered].slice(0, count).map((componentId) => this.componentChallenge(componentId, nodes, random));
  }
  componentChallenge(componentId, nodes, random) {
    const component = circuitComponentGuide.find((item) => item.id === componentId) ?? circuitComponentGuide[0];
    const visibleComponents = circuitComponentGuide.filter((item) => nodes.includes(item.id) || ["battery", "switch", "resistor", "led", "return"].includes(item.id));
    const symbolDistractors = random.shuffle(visibleComponents.filter((item) => item.id !== component.id)).slice(0, 2).map((item) => item.symbolName ?? item.label);
    const functionDistractors = random.shuffle(visibleComponents.filter((item) => item.id !== component.id)).slice(0, 2).map((item) => item.functionSummary ?? item.role);
    const correctSymbol = component.symbolName ?? component.label;
    const correctFunction = component.functionSummary ?? component.role;
    return {
      componentId: component.id,
      componentLabel: component.label,
      symbolQuestion: "Quale simbolo è evidenziato nello schema?",
      functionQuestion: "Quale funzione svolge nel circuito?",
      correctSymbol,
      correctFunction,
      symbolChoices: random.shuffle([correctSymbol, ...symbolDistractors]),
      functionChoices: random.shuffle([correctFunction, ...functionDistractors]),
      explanation: `${component.label}: ${component.role}. Indizio visivo: ${component.symbolClue ?? component.check}. Attenzione: ${component.commonConfusion ?? component.check}.`
    };
  }
  diagnosticPlanForScenario(scenario) {
    return {
      "percorso-aperto": ["Controlla continuità in ordine.", "Trova il primo tratto interrotto.", "Ripara solo quel tratto."],
      "corrente-instabile": ["Verifica se il LED si accende.", "Controlla protezione e ritorno.", "Stabilizza prima di certificare."],
      polarita: ["Controlla se arriva corrente.", "Leggi il verso del LED.", "Inverti solo se la polarità è la causa."],
      "multi-guasto": ["Separa sintomo principale e secondario.", "Associa ogni misura a una causa.", "Evita riparazioni non dimostrate."],
      "serie-parallelo": ["Confronta ramo A e ramo B.", "Non toccare il ramo funzionante.", "Chiudi solo il ramo aperto."],
      "sensore-soglia": ["Distingui alimentazione e dato.", "Misura tensione al sensore.", "Ricollega il ramo sensore."],
      "logica-rele": ["Controlla circuito di comando.", "Poi controlla contatto di potenza.", "Arma il relè se la bobina non riceve energia."],
      temporizzazione: ["Osserva la durata dell'impulso.", "Misura la carica del condensatore.", "Stabilizza l'impulso."],
      "corto-circuito": ["Cerca percorsi troppo facili.", "Non alimentare finché c'è corto.", "Rimuovi la scorciatoia prima del test."]
    }[scenario ?? "percorso-aperto"];
  }
  learningPurposeForScenario(scenario) {
    return {
      "percorso-aperto": "Imparare che la corrente ha bisogno di un percorso completo.",
      "corrente-instabile": "Capire che un circuito deve essere anche protetto e stabile.",
      polarita: "Riconoscere componenti polarizzati e verso della corrente.",
      "multi-guasto": "Allenare diagnosi: collegare misure diverse a cause diverse.",
      "serie-parallelo": "Capire la differenza tra ramo in serie e ramo parallelo.",
      "sensore-soglia": "Distinguere circuito di alimentazione e circuito di misura.",
      "logica-rele": "Vedere un relè come ponte tra comando logico e carico fisico.",
      temporizzazione: "Intuire accumulo e rilascio di energia in un condensatore.",
      "corto-circuito": "Riconoscere perché una scorciatoia elettrica è pericolosa."
    }[scenario ?? "percorso-aperto"];
  }
  conceptsForFaults(faults) {
    const concepts = /* @__PURE__ */ new Set(["diagnosi", "tester", "circuito chiuso"]);
    faults.forEach((fault) => {
      if (fault === "reversed-led") concepts.add("polarità");
      if (fault === "missing-resistor" || fault === "wrong-resistor-value") concepts.add("protezione LED");
      if (fault === "sensor-unpowered") concepts.add("sensori");
      if (fault === "capacitor-discharged") concepts.add("condensatore");
      if (fault === "parallel-branch-open") concepts.add("parallelo");
      if (fault === "relay-not-armed") concepts.add("relè");
      if (fault === "short-circuit") concepts.add("corto circuito");
      if (fault === "loose-ground") concepts.add("massa");
    });
    return [...concepts].slice(0, 5);
  }
  levelName(level) {
    if (level <= 2) return "circuito chiuso";
    if (level <= 4) return "tester e polarità";
    if (level <= 6) return "rami e sensori";
    return "diagnosi di sistema";
  }
  noiseObservations(random, count) {
    const noise = [
      "La cornice del pannello è graffiata, ma il tester non cambia valore vicino al graffio.",
      "La spia laterale lampeggia lentamente: è un segnale di attesa, non un componente del circuito.",
      "Il cavo esterno è vecchio, ma la continuità fino alla batteria resta stabile.",
      "Il terminale registra polvere sul vetro: non influenza il percorso elettrico.",
      "Il colore del filo cambia dopo una giunta, ma il tester misura continuità normale.",
      "La vite del coperchio è allentata: è manutenzione, non causa elettrica del LED spento."
    ];
    return random.shuffle(noise).slice(0, Math.max(0, count));
  }
  describeSymptom(faults) {
    if (faults.includes("missing-resistor")) {
      return "Il LED tenta di accendersi ma pulsa in modo irregolare: il circuito non è stabile.";
    }
    if (faults.includes("capacitor-discharged")) {
      return "Il LED emette un lampo breve e poi si spegne: manca energia accumulata per stabilizzare l'impulso.";
    }
    if (faults.includes("short-circuit")) {
      return "Il pannello blocca l'alimentazione: il tester sospetta una scorciatoia tra + e ritorno.";
    }
    if (faults.includes("parallel-branch-open")) {
      return "Una luce resta accesa, ma il ramo secondario non risponde: non tutto il circuito è guasto.";
    }
    if (faults.includes("wrong-resistor-value")) {
      return "Il LED si accende, ma con intensità fuori scala: la protezione non è corretta.";
    }
    if (faults.includes("relay-not-armed")) {
      return "Il comando viene inviato, ma il carico non parte: il relè non chiude il contatto di potenza.";
    }
    if (faults.includes("loose-ground")) {
      return "Il LED sfarfalla quando il pannello vibra: il ritorno a massa sembra instabile.";
    }
    if (faults.includes("sensor-unpowered")) {
      return "Il LED può accendersi, ma il terminale non riceve dati: il sensore non è alimentato.";
    }
    if (faults.includes("reversed-led")) {
      return "La corrente sembra arrivare al LED, ma la luce resta spenta.";
    }
    if (faults.includes("missing-wire") || faults.includes("open-switch") || faults.includes("disconnected-component")) {
      return "Il LED resta spento: il tester segnala che la corrente non completa il giro.";
    }
    return "Il pannello segnala un comportamento elettrico non coerente.";
  }
}
class Random {
  constructor(seed) {
    __publicField(this, "state");
    this.state = typeof seed === "number" ? seed >>> 0 : Random.hash(seed);
    if (this.state === 0) {
      this.state = 1831565813;
    }
  }
  static hash(value) {
    let hash = 2166136261;
    for (let index = 0; index < value.length; index += 1) {
      hash ^= value.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
  }
  next() {
    this.state += 1831565813;
    let value = this.state;
    value = Math.imul(value ^ value >>> 15, value | 1);
    value ^= value + Math.imul(value ^ value >>> 7, value | 61);
    return ((value ^ value >>> 14) >>> 0) / 4294967296;
  }
  integer(min, max) {
    return Math.floor(this.next() * (max - min + 1)) + min;
  }
  bool(chance = 0.5) {
    return this.next() < chance;
  }
  pick(items) {
    return items[this.integer(0, items.length - 1)];
  }
  shuffle(items) {
    const result = [...items];
    for (let index = result.length - 1; index > 0; index -= 1) {
      const target = this.integer(0, index);
      [result[index], result[target]] = [result[target], result[index]];
    }
    return result;
  }
  fork(label) {
    return new Random(`${this.state}:${label}`);
  }
}
class CodingPuzzleGenerator {
  generate(random, difficulty, preferredTypes) {
    const available = codingTemplates.filter((template2) => template2.minLevel <= difficulty.level && (!preferredTypes || preferredTypes.includes(template2.type)));
    const template = random.pick(available.length > 0 ? available : codingTemplates.filter((item) => item.minLevel <= difficulty.level));
    return template.build(random.fork(template.type), difficulty);
  }
  generateMinigame(random, difficulty, preferredTypes = []) {
    const type = preferredTypes.length > 0 ? random.pick(preferredTypes) : random.pick(["sequence-builder", "state-tracer", "bug-hunt"]);
    const game = buildCodingMinigame(random.fork(type), difficulty, type);
    const first = game.prompts[0];
    const options = first.tiles.map((tile) => tile.label);
    return {
      id: `coding-mini-${type}-${random.integer(1e3, 9999)}`,
      title: game.title,
      challengeType: type === "bug-hunt" ? "debug-line" : type === "state-tracer" ? "variable-state" : "trace-output",
      difficultyLabel: `Livello ${difficulty.level}/8 - sprint coding`,
      scenario: "La console genera micro-programmi da stabilizzare in un minuto. Non premiare la memoria: simula il codice.",
      codeLines: first.codeLines,
      question: first.question,
      options,
      correctOption: first.solutionLabels[0],
      explanation: first.explanation,
      conceptTags: codingMinigameConcepts(type),
      methodSteps: codingMinigameMethodSteps(type),
      learningPurpose: codingMinigamePurpose(type),
      hints: [
        "Segui una riga alla volta: il computer non salta passaggi.",
        "Quando una variabile cambia, aggiorna il suo valore prima di leggere la riga successiva.",
        "Nel debug cerca la prima riga che rompe la regola, non una compensazione finale."
      ],
      competencies: game.competencies,
      maxSeconds: 60,
      minigame: game
    };
  }
  fallback(random = new Random("coding-fallback"), difficulty) {
    return buildTracePuzzle(random, difficulty ?? {
      level: 1
    });
  }
}
function buildCodingMinigame(random, difficulty, type) {
  const promptCount = 18 + difficulty.level;
  const prompts = [];
  let previousSignature = "";
  for (let index = 0; index < promptCount; index += 1) {
    const prompt = uniqueCodingPrompt(random, difficulty, type, index, previousSignature);
    prompts.push(prompt);
    previousSignature = prompt.signature;
  }
  const titles = {
    "sequence-builder": "Minigioco coding: Completa il codice",
    "state-tracer": "Minigioco coding: Traccia la memoria",
    "bug-hunt": "Minigioco coding: Caccia al bug"
  };
  const instructions = {
    "sequence-builder": "clicca il prossimo blocco che completa una procedura corretta.",
    "state-tracer": "clicca il valore o lo stato prodotto dal codice.",
    "bug-hunt": "clicca la correzione che elimina la causa dell'errore."
  };
  return {
    type,
    title: titles[type],
    durationMs: 6e4,
    instructions: instructions[type],
    scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. Devi simulare mentalmente, non provare a caso.",
    prompts,
    competencies: Array.from(/* @__PURE__ */ new Set([
      "coding.sequenze",
      "coding.testMentale",
      "problemSolving",
      "pensieroCritico",
      ...type === "sequence-builder" ? ["coding.decomposizione"] : [],
      ...type === "state-tracer" ? ["coding.efficienza", "matematica.logica"] : [],
      ...type === "bug-hunt" ? ["coding.debugging", "coding.controlloErrore"] : []
    ]))
  };
}
function uniqueCodingPrompt(random, difficulty, type, index, previousSignature) {
  for (let attempt = 0; attempt < 12; attempt += 1) {
    const prompt = buildCodingMinigamePrompt(random, difficulty, type, index + attempt);
    if (prompt.signature !== previousSignature) {
      return prompt;
    }
  }
  return buildCodingMinigamePrompt(random, difficulty, type, index + 99);
}
function buildCodingMinigamePrompt(random, difficulty, type, index) {
  if (type === "sequence-builder") return buildSequenceBuilderPrompt(random, difficulty, index);
  if (type === "state-tracer") return buildStateTracerPrompt(random, difficulty, index);
  return buildBugHuntPrompt(random, difficulty, index);
}
function buildSequenceBuilderPrompt(random, difficulty, index) {
  const variants = [
    () => {
      const start = random.integer(2, 8);
      const target = start + random.integer(3, 8);
      const delta = target - start;
      return {
        title: "Completa la procedura",
        codeLines: [`energia = ${start}`, "obiettivo = " + target, "?"],
        question: "Quale blocco porta energia esattamente all'obiettivo?",
        correct: `energia = energia + ${delta}`,
        distractors: [`energia = energia * ${delta}`, `energia = energia - ${delta}`, `obiettivo = energia + ${delta}`],
        explanation: `Per arrivare da ${start} a ${target} serve aggiungere ${delta}. L'assegnazione deve aggiornare energia, non obiettivo.`,
        concept: "assegnazione come aggiornamento",
        methodSteps: ["leggi stato iniziale", "calcola differenza", "aggiorna la variabile giusta"]
      };
    },
    () => {
      const turns = random.integer(2, Math.min(6, difficulty.level + 2));
      return {
        title: "Riduci una ripetizione",
        codeLines: ["apri registro", "? ", "salva registro"],
        question: `Quale blocco ripete un controllo ${turns} volte senza copiare righe?`,
        correct: `ripeti ${turns} volte: controlla sensore`,
        distractors: [`controlla sensore ${turns}`, "se sensore: ripeti registro", `ripeti ${turns + 1} volte: salva registro`],
        explanation: `Un ciclo deve dire quante volte ripetere e quale istruzione ripete: controlla sensore per ${turns} volte.`,
        concept: "ciclo come compattezza",
        methodSteps: ["trova azione ripetuta", "trova numero ripetizioni", "non cambiare azioni esterne"]
      };
    },
    () => {
      const threshold = random.pick([40, 50, 60, 70]);
      return {
        title: "Scegli il ramo sicuro",
        codeLines: [`se batteria >= ${threshold}:`, "  avvia scansione", "altrimenti:", "?"],
        question: "Quale blocco completa il ramo alternativo in modo coerente?",
        correct: "ricarica batteria",
        distractors: ["avvia scansione", "stampa batteria >= soglia", "spegni tutto"],
        explanation: `Il ramo altrimenti vale quando la batteria non raggiunge ${threshold}: l'azione coerente è ricaricare.`,
        concept: "if / else",
        methodSteps: ["leggi condizione", "identifica ramo falso", "scegli azione complementare"]
      };
    }
  ];
  const item = random.pick(variants)();
  return codingPromptFromItem(random, index, "sequence-builder", item, "Completa la riga con ?");
}
function buildStateTracerPrompt(random, difficulty, index) {
  if (difficulty.level >= 4 && random.bool(0.5)) {
    const start = random.integer(1, 6);
    const add = random.integer(2, 5);
    const times = random.integer(3, Math.min(8, difficulty.level + 2));
    const answer2 = start + add * times;
    return codingPromptFromItem(random, index, "state-tracer", {
      title: "Traccia il ciclo",
      codeLines: [`x = ${start}`, `ripeti ${times} volte:`, `  x = x + ${add}`, "stampa x"],
      question: "Quale valore viene stampato?",
      correct: String(answer2),
      distractors: [String(start + add), String(times * add), String(answer2 - add)],
      explanation: `Il ciclo aggiunge ${add} per ${times} volte: ${start} + ${times} * ${add} = ${answer2}.`,
      concept: "accumulatore",
      methodSteps: ["stato iniziale", "effetto di una ripetizione", "moltiplica l'effetto"]
    }, "Valore stampato");
  }
  const a = random.integer(2, 8);
  const b = random.integer(2, 7);
  const c = a + b;
  const sub = random.integer(1, Math.min(5, c - 1));
  const answer = c - sub;
  return codingPromptFromItem(random, index, "state-tracer", {
    title: "Traccia la memoria",
    codeLines: [`a = ${a}`, `b = ${b}`, "c = a + b", `a = c - ${sub}`, "stampa a"],
    question: "Quanto vale a alla fine?",
    correct: String(answer),
    distractors: [String(a), String(c), String(b)],
    explanation: `a viene sovrascritta. c = ${a} + ${b} = ${c}; poi a = ${c} - ${sub} = ${answer}.`,
    concept: "variabile sovrascritta",
    methodSteps: ["tabella variabili", "aggiorna a sinistra", "usa l'ultimo valore"]
  }, "Valore finale");
}
function buildBugHuntPrompt(random, difficulty, index) {
  const variants = [
    () => {
      const start = random.integer(4, 9);
      const inc = random.integer(2, 5);
      const times = random.integer(3, Math.min(7, difficulty.level + 2));
      const expected = start + inc * times;
      return {
        title: "Riga che rompe il risultato",
        codeLines: [`energia = ${start}`, `ripeti ${times} volte:`, `  energia = energia + ${inc}`, `energia = energia - ${inc}`, "stampa energia"],
        question: `Il valore atteso è ${expected}. Quale correzione elimina la causa?`,
        correct: `rimuovi: energia = energia - ${inc}`,
        distractors: [`ripeti ${times - 1} volte`, `energia = ${start + inc}`, "stampa prima del ciclo"],
        explanation: `Il ciclo produce già ${expected}; la sottrazione dopo il ciclo rovina il risultato.`,
        concept: "debug della causa",
        methodSteps: ["calcola atteso", "trova prima rottura", "non compensare altrove"]
      };
    },
    () => {
      const threshold = random.pick([50, 60, 70]);
      return {
        title: "Operatore invertito",
        codeLines: [`se batteria < ${threshold}:`, "  avvia scansione", "altrimenti:", "  ricarica batteria"],
        question: "Il sistema dovrebbe avviare solo con batteria sufficiente. Quale correzione serve?",
        correct: `< diventa >= nella condizione`,
        distractors: ["scambia i nomi delle variabili", "rimuovi altrimenti", "avvia sempre scansione"],
        explanation: `Batteria sufficiente significa maggiore o uguale a ${threshold}, non minore.`,
        concept: "operatore di confronto",
        methodSteps: ["leggi requisito", "confronta con condizione", "correggi il simbolo"]
      };
    },
    () => {
      return {
        title: "AND o OR?",
        codeLines: ["codiceOk = vero", "portaAperta = codiceOk OR circuitoOk", "stampa portaAperta"],
        question: "La porta deve aprirsi solo se codice e circuito sono entrambi ok. Quale correzione serve?",
        correct: "OR diventa AND",
        distractors: ["codiceOk diventa falso", "stampa circuitoOk", "rimuovi codiceOk"],
        explanation: "Solo se entrambi sono ok richiede AND. OR basterebbe con una sola condizione vera.",
        concept: "logica booleana",
        methodSteps: ["traduci requisito", "controlla operatore", "AND = tutti veri"]
      };
    }
  ];
  const item = random.pick(variants)();
  return codingPromptFromItem(random, index, "bug-hunt", item, "Correzione corretta");
}
function codingPromptFromItem(random, index, type, item, targetLabel) {
  const tiles = shuffleCodingTiles(random, [
    codingTile(index, item.correct, true, `Corretto: ${item.explanation}`),
    ...item.distractors.map((label, choiceIndex) => codingTile(index + choiceIndex + 1, label, false, `Non basta: ${item.explanation}`))
  ]);
  return {
    id: `coding-${type}-${index}`,
    type,
    title: item.title,
    codeLines: item.codeLines,
    question: item.question,
    targetLabel,
    requiredSelectionCount: 1,
    tiles,
    solutionLabels: [item.correct],
    explanation: item.explanation,
    concept: item.concept,
    methodSteps: item.methodSteps,
    signature: `${type}-${item.question}-${item.correct}-${item.codeLines.join("|")}`
  };
}
function codingTile(seed, label, isCorrect, feedback) {
  return {
    id: `coding-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
    label,
    isCorrect,
    feedback
  };
}
function shuffleCodingTiles(random, tiles) {
  return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
}
function codingMinigameConcepts(type) {
  if (type === "sequence-builder") return ["sequenza", "decomposizione", "algoritmo"];
  if (type === "state-tracer") return ["variabili", "tracing", "cicli"];
  return ["debug", "condizioni", "controllo errore"];
}
function codingMinigameMethodSteps(type) {
  if (type === "sequence-builder") return ["obiettivo", "stato attuale", "prossimo blocco"];
  if (type === "state-tracer") return ["tabella variabili", "aggiorna stato", "stampa finale"];
  return ["risultato atteso", "prima rottura", "correzione minima"];
}
function codingMinigamePurpose(type) {
  if (type === "sequence-builder") return "Allenare costruzione di algoritmi brevi: scegliere il prossimo blocco coerente con obiettivo e stato.";
  if (type === "state-tracer") return "Allenare esecuzione mentale del codice: aggiornare variabili, cicli e output senza tirare a indovinare.";
  return "Allenare debugging: distinguere causa dell'errore, sintomo e correzione minima.";
}
function basePuzzle(difficulty, type, title, scenario, codeLines, question, options, correctOption, explanation, conceptTags, methodSteps) {
  return {
    id: `coding-${type}`,
    title,
    challengeType: type,
    difficultyLabel: `Livello ${difficulty.level}/8 - ${difficulty.level <= 2 ? "traccia guidata" : difficulty.level <= 5 ? "ragionamento su stati" : "debug e astrazione"}`,
    scenario,
    codeLines,
    question,
    options,
    correctOption,
    explanation,
    conceptTags,
    methodSteps,
    learningPurpose: learningPurposeFor(type),
    hints: hintsFor(type),
    competencies: competenciesFor(type),
    maxSeconds: Math.max(45, 95 - difficulty.level * 5)
  };
}
function buildTracePuzzle(random, difficulty) {
  const start = random.integer(2, 7);
  const add = random.integer(2, 6);
  const multiplier = difficulty.level >= 3 ? random.integer(2, 4) : 2;
  const answer = (start + add) * multiplier;
  return basePuzzle(
    difficulty,
    "trace-output",
    "Console codice: prevedi l'uscita",
    "Il terminale non esegue il codice finche non sai prevedere cosa stampera.",
    [
      `energia = ${start}`,
      `energia = energia + ${add}`,
      `energia = energia * ${multiplier}`,
      "stampa energia"
    ],
    "Quale valore viene stampato?",
    shuffledOptions(random, String(answer), [String(start + add), String(start * multiplier + add), String(start + add + multiplier)]),
    String(answer),
    `Il codice aggiorna energia in sequenza: prima ${start} + ${add} = ${start + add}, poi ${start + add} * ${multiplier} = ${answer}.`,
    ["sequenza", "tracing", "output"],
    ["leggi dall'alto", "scrivi ogni valore nuovo", "controlla cosa stampa l'ultima riga"]
  );
}
function buildVariableStatePuzzle(random, difficulty) {
  const a = random.integer(3, 8);
  const b = random.integer(2, 6);
  const c = a + b;
  const finalA = c - random.integer(1, Math.min(4, c - 1));
  return basePuzzle(
    difficulty,
    "variable-state",
    "Console codice: stato variabili",
    "La memoria della console cambia riga dopo riga: serve sapere il valore finale di una variabile.",
    [
      `a = ${a}`,
      `b = ${b}`,
      "c = a + b",
      `a = c - ${c - finalA}`,
      "stampa a"
    ],
    "Quanto vale `a` alla fine?",
    shuffledOptions(random, String(finalA), [String(a), String(c), String(b)]),
    String(finalA),
    `La variabile a viene sovrascritta: all'inizio vale ${a}, ma alla fine diventa c - ${c - finalA}, cioe ${finalA}.`,
    ["variabili", "assegnazione", "stato"],
    ["non usare il primo valore per forza", "aggiorna la tabella delle variabili", "leggi l'ultima assegnazione"]
  );
}
function buildLoopPuzzle(random, difficulty) {
  const times = random.integer(3, Math.min(8, 3 + difficulty.level));
  const delta = random.integer(2, 6);
  const start = random.integer(0, 5);
  const answer = start + times * delta;
  return basePuzzle(
    difficulty,
    "loop-count",
    "Console codice: ciclo controllato",
    "Il ciclo ripete lo stesso blocco: la sfida e contare l'effetto, non ripetere a caso.",
    [
      `segnale = ${start}`,
      `ripeti ${times} volte:`,
      `  segnale = segnale + ${delta}`,
      "stampa segnale"
    ],
    "Quale valore viene stampato dopo il ciclo?",
    shuffledOptions(random, String(answer), [String(start + delta), String(times + delta), String(answer - delta)]),
    String(answer),
    `Il blocco aggiunge ${delta} per ${times} volte: aumento totale ${times} * ${delta} = ${times * delta}; ${start} + ${times * delta} = ${answer}.`,
    ["ciclo", "ripetizione", "accumulatore"],
    ["trova cosa si ripete", "calcola effetto di una ripetizione", "moltiplica per il numero di ripetizioni"]
  );
}
function buildConditionalPuzzle(random, difficulty) {
  const battery = random.integer(35, 95);
  const threshold = difficulty.level >= 5 ? random.integer(55, 75) : 60;
  const safe = battery >= threshold;
  return basePuzzle(
    difficulty,
    "conditional-branch",
    "Console codice: ramo condizionale",
    "La porta non vuole il risultato di un calcolo: vuole sapere quale ramo del codice verra eseguito.",
    [
      `batteria = ${battery}`,
      `se batteria >= ${threshold}:`,
      '  azione = "avvia scansione"',
      "altrimenti:",
      '  azione = "ricarica"',
      "stampa azione"
    ],
    "Quale azione viene stampata?",
    shuffledOptions(random, safe ? "avvia scansione" : "ricarica", ["apri porta", "spegni sensore", safe ? "ricarica" : "avvia scansione"]),
    safe ? "avvia scansione" : "ricarica",
    `${battery} ${safe ? "e maggiore o uguale" : "e minore"} di ${threshold}: quindi il codice segue il ramo ${safe ? "se" : "altrimenti"}.`,
    ["condizione", "confronto", "ramo"],
    ["valuta la condizione", "scegli solo il ramo vero", "ignora il ramo non eseguito"]
  );
}
function buildBooleanPuzzle(random, difficulty) {
  const codeOk = random.bool(0.55);
  const circuitOk = difficulty.level >= 6 ? random.bool(0.5) : true;
  const sensorOk = difficulty.level >= 6 ? random.bool(0.55) : true;
  const answer = codeOk && circuitOk && sensorOk;
  return basePuzzle(
    difficulty,
    "boolean-logic",
    "Console codice: logica booleana",
    "La porta usa condizioni insieme: basta un falso per bloccare tutto.",
    [
      `codiceOk = ${codeOk ? "vero" : "falso"}`,
      `circuitoOk = ${circuitOk ? "vero" : "falso"}`,
      `sensoreOk = ${sensorOk ? "vero" : "falso"}`,
      "portaAperta = codiceOk AND circuitoOk AND sensoreOk",
      "stampa portaAperta"
    ],
    "Che cosa stampa la console?",
    shuffledOptions(random, answer ? "vero" : "falso", [answer ? "falso" : "vero", "solo se codiceOk", "errore"]),
    answer ? "vero" : "falso",
    `AND richiede che tutte le condizioni siano vere. Qui il risultato e ${answer ? "vero" : "falso"}.`,
    ["booleani", "AND", "condizioni multiple"],
    ["controlla ogni variabile", "AND funziona solo se tutto e vero", "un falso basta a rendere falso il risultato"]
  );
}
function buildDebugPuzzle(random, difficulty) {
  const base = random.integer(4, 9);
  const increment = random.integer(2, 5);
  const repeats = random.integer(3, Math.min(6, difficulty.level + 1));
  const correct = base + repeats * increment;
  return basePuzzle(
    difficulty,
    "debug-line",
    "Console codice: trova la riga guasta",
    "Il log dovrebbe accumulare energia con lo stesso incremento, ma una riga rompe la regola.",
    [
      `energia = ${base}`,
      `ripeti ${repeats} volte:`,
      `  energia = energia + ${increment}`,
      `energia = energia - ${increment}`,
      "stampa energia"
    ],
    `Il valore atteso era ${correct}. Quale correzione rende coerente il programma?`,
    shuffledOptions(random, "elimina la riga energia = energia - " + increment, [
      `cambia ripeti ${repeats} volte in ripeti ${repeats - 1} volte`,
      `cambia energia = ${base} in energia = ${base + increment}`,
      "sposta stampa energia sopra il ciclo"
    ]),
    "elimina la riga energia = energia - " + increment,
    `Il ciclo produce gia ${correct}. La riga successiva sottrae ${increment} e rovina il risultato: va rimossa, non compensata altrove.`,
    ["debug", "invariante", "controllo errore"],
    ["calcola il valore atteso del ciclo", "trova la prima riga che rompe la regola", "correggi la causa, non il sintomo"]
  );
}
function shuffledOptions(random, correct, distractors) {
  return random.shuffle([correct, ...random.shuffle(distractors.filter((item) => item !== correct)).slice(0, 3)]);
}
function learningPurposeFor(type) {
  return {
    "trace-output": "Allenare il tracing: prevedere l'output eseguendo mentalmente le righe in ordine.",
    "variable-state": "Capire che una variabile puo cambiare valore e va aggiornata riga dopo riga.",
    "loop-count": "Capire i cicli come ripetizione controllata di un effetto.",
    "conditional-branch": "Valutare una condizione e scegliere il ramo realmente eseguito.",
    "boolean-logic": "Combinare condizioni vere/falsi con logica booleana.",
    "debug-line": "Trovare la riga che rompe una regola attesa e correggere la causa."
  }[type];
}
function hintsFor(type) {
  return {
    "trace-output": ["Fai una tabella con una riga per ogni assegnazione.", "L'output e solo cio che viene stampato alla fine."],
    "variable-state": ["Quando vedi =, aggiorna il valore della variabile a sinistra.", "Il valore iniziale puo non essere quello finale."],
    "loop-count": ["Calcola l'effetto di una ripetizione.", "Poi moltiplica l'effetto per quante volte si ripete."],
    "conditional-branch": ["Prima decidi se la condizione e vera o falsa.", "Esegui solo il ramo scelto."],
    "boolean-logic": ["AND richiede tutto vero.", "OR richiederebbe almeno un vero, ma qui controlla l'operatore scritto."],
    "debug-line": ["Calcola prima cosa dovrebbe succedere.", "La riga guasta e quella che rovina una regola gia soddisfatta."]
  }[type];
}
function competenciesFor(type) {
  const base = ["coding.sequenze", "problemSolving", "pensieroCritico"];
  if (type === "debug-line") return [...base, "coding.debugging", "coding.testMentale"];
  if (type === "loop-count") return [...base, "coding.efficienza", "matematica.logica"];
  if (type === "conditional-branch" || type === "boolean-logic") return [...base, "coding.decomposizione", "matematica.logica"];
  return [...base, "coding.testMentale"];
}
const codingTemplates = [
  { type: "trace-output", minLevel: 1, build: buildTracePuzzle },
  { type: "variable-state", minLevel: 2, build: buildVariableStatePuzzle },
  { type: "loop-count", minLevel: 3, build: buildLoopPuzzle },
  { type: "conditional-branch", minLevel: 3, build: buildConditionalPuzzle },
  { type: "boolean-logic", minLevel: 5, build: buildBooleanPuzzle },
  { type: "debug-line", minLevel: 5, build: buildDebugPuzzle }
];
const englishTemplates = [
  {
    id: "green-not-red",
    title: "Console colori",
    challengeType: "command",
    scenario: "Due pulsanti sono illuminati, ma il messaggio autorizza una sola azione.",
    taskPrompt: "Trasforma il comando inglese in una singola azione sicura.",
    instruction: "Press the green button. Do not press the red button.",
    correctLabel: "Press green",
    distractors: [
      { label: "Press red", feedback: "Do not press indica un divieto: red è l'azione da evitare, non quella da eseguire." },
      { label: "Press both", feedback: "Il comando autorizza green e vieta red: premere entrambi violerebbe la seconda frase." },
      { label: "Wait", feedback: "Press è un verbo d'azione immediata; il testo non contiene wait o hold." }
    ],
    diagnosticSteps: ["Press indica l'azione.", "Green identifica il bersaglio.", "Do not press segnala cosa evitare."],
    conceptTags: ["action verb", "do not", "colour words"],
    methodSteps: ["azione", "oggetto", "divieto"],
    glossary: [
      { term: "press", meaning: "premere" },
      { term: "green", meaning: "verde" },
      { term: "do not", meaning: "non / divieto" }
    ]
  },
  {
    id: "small-key",
    title: "Chiave corretta",
    challengeType: "safety",
    scenario: "Sul banco ci sono due chiavi simili: una apre il vano, l'altra blocca il terminale.",
    taskPrompt: "Distingui l'oggetto autorizzato da quello vietato.",
    instruction: "Take the small key. Do not take the large key.",
    correctLabel: "Take small key",
    distractors: [
      { label: "Take large key", feedback: "Large key è proprio l'oggetto vietato dalla seconda frase." },
      { label: "Take both keys", feedback: "Do not limita la seconda azione: prenderle entrambe non rispetta il comando." },
      { label: "Open left door", feedback: "Il comando parla di take e key; non compare nessun ordine di apertura." }
    ],
    diagnosticSteps: ["Take indica prendere.", "Small distingue l'oggetto corretto.", "Large è collegato al divieto."],
    conceptTags: ["adjectives", "object choice", "do not"],
    methodSteps: ["verbo", "aggettivo", "oggetto vietato"],
    glossary: [
      { term: "take", meaning: "prendere" },
      { term: "small", meaning: "piccolo" },
      { term: "large", meaning: "grande" }
    ]
  },
  {
    id: "where-is-core",
    title: "Mappa dei moduli",
    challengeType: "vocabulary-in-context",
    minDifficulty: 2,
    scenario: "NORA descrive la posizione di tre moduli: devi trovare quello corretto senza affidarti al colore.",
    taskPrompt: "Usa preposizioni di luogo e lessico spaziale.",
    instruction: "The power core is under the central desk, between the two blue crates.",
    correctLabel: "Core under desk, between crates",
    distractors: [
      { label: "Core above the desk", feedback: "Under significa sotto: above è la posizione opposta." },
      { label: "Core next to the red crate", feedback: "Il testo parla di two blue crates e between, non di una cassa rossa." },
      { label: "Core inside the left door", feedback: "Door non è nominato: central desk e crates sono gli indizi spaziali." }
    ],
    diagnosticSteps: ["Under indica sotto.", "Central desk è il riferimento principale.", "Between the two blue crates restringe la posizione."],
    conceptTags: ["prepositions", "under", "between", "spatial reading"],
    learningPurpose: "Allena preposizioni di luogo e comprensione di descrizioni spaziali.",
    commandGoal: "Individua il modulo nella posizione descritta, non nel punto più evidente.",
    method: "Trova il nome dell'oggetto, poi leggi preposizione e riferimenti spaziali.",
    methodSteps: ["oggetto", "preposizione", "riferimento"],
    glossary: [
      { term: "under", meaning: "sotto" },
      { term: "between", meaning: "tra due elementi" },
      { term: "crate", meaning: "cassa" }
    ]
  },
  {
    id: "who-can-open",
    title: "Autorizzazione operatore",
    challengeType: "inference",
    minDifficulty: 2,
    scenario: "Un breve log indica chi ha il permesso di aprire il vano.",
    taskPrompt: "Rispondi a una domanda wh- usando solo l'informazione richiesta.",
    instruction: "Who can open the supply hatch? Only the operator with the silver badge can open it.",
    sourceText: "Access log: the red badge opens the storage map. Only the operator with the silver badge can open the supply hatch.",
    correctLabel: "Operator with silver badge",
    distractors: [
      { label: "Any operator", feedback: "Only restringe il permesso: non basta essere un operatore qualunque." },
      { label: "The operator with red badge", feedback: "Il badge nominato è silver, non red." },
      { label: "No one can open it", feedback: "Can open indica che qualcuno ha il permesso: la frase specifica chi." }
    ],
    diagnosticSteps: ["Who chiede una persona o ruolo.", "Can indica possibilità o permesso.", "Only restringe la risposta al badge argento."],
    conceptTags: ["who", "can", "only", "permission"],
    learningPurpose: "Allena question words e modali di possibilità/permesso.",
    commandGoal: "Identifica chi è autorizzato senza allargare il permesso.",
    method: "Leggi la domanda, cerca il ruolo, poi controlla il limitatore only.",
    methodSteps: ["question word", "can", "only"],
    glossary: [
      { term: "who", meaning: "chi" },
      { term: "can", meaning: "può / ha il permesso" },
      { term: "supply hatch", meaning: "sportello rifornimenti" }
    ]
  },
  {
    id: "main-switch",
    title: "Sequenza di avvio",
    challengeType: "sequence",
    scenario: "Il terminale accetta la procedura solo se l'ordine è identico al protocollo.",
    taskPrompt: "Ricostruisci l'ordine delle azioni seguendo then.",
    instruction: "Insert the code, then turn on the main switch.",
    correctLabel: "Code -> Main switch",
    distractors: [
      { label: "Main switch -> Code", feedback: "Then impone un ordine: il codice viene prima dello switch principale." },
      { label: "Open left door", feedback: "La porta sinistra non è nominata; aggiungere azioni nuove rende la procedura non valida." },
      { label: "Turn off switch", feedback: "Turn on significa accendere o attivare, non spegnere." }
    ],
    diagnosticSteps: ["Insert the code è la prima azione.", "Then ordina le azioni.", "Turn on significa attivare."],
    conceptTags: ["then", "sequence", "phrasal verb"],
    methodSteps: ["prima azione", "then", "seconda azione"]
  },
  {
    id: "left-before-blue",
    title: "Reset protetto",
    challengeType: "sequence",
    minDifficulty: 2,
    scenario: "Il reset blu funziona solo se prima viene aperto il pannello corretto.",
    taskPrompt: "Usa before per decidere l'ordine, non il colore più evidente.",
    instruction: "Open the left panel before pressing the blue reset button.",
    correctLabel: "Left panel -> Blue reset",
    distractors: [
      { label: "Blue reset -> Left panel", feedback: "Before indica che il pannello sinistro viene prima del reset blu." },
      { label: "Open right panel", feedback: "Right non compare: left indica il lato sinistro, non quello destro." },
      { label: "Press green button", feedback: "Il colore nominato è blue; green è un distrattore non presente nel protocollo." }
    ],
    diagnosticSteps: ["Open indica aprire.", "Left panel identifica il primo oggetto.", "Before stabilisce l'ordine delle azioni."],
    conceptTags: ["before", "left/right", "procedure"],
    methodSteps: ["verbo", "oggetto", "before"]
  },
  {
    id: "inspect-record-reset",
    title: "Protocollo sensore",
    challengeType: "sequence",
    minDifficulty: 2,
    scenario: "Il sistema conserva il log solo se il valore viene annotato prima del reset.",
    taskPrompt: "Ordina tre azioni senza saltare il passaggio di registrazione.",
    instruction: "Check the left sensor, write down its value, then reset only the right sensor.",
    correctLabel: "Check left -> write value -> reset right",
    distractors: [
      { label: "Reset right -> check left -> write value", feedback: "Then arriva dopo write down: il reset è l'ultima azione, non la prima." },
      { label: "Check right -> write value -> reset left", feedback: "Left e right sono invertiti: il sensore da controllare e quello da resettare non coincidono." },
      { label: "Check left -> reset both sensors", feedback: "Only the right sensor limita il reset a un solo sensore." }
    ],
    diagnosticSteps: ["Check the left sensor è il primo comando.", "Write down its value chiede di registrare il dato.", "Then reset only the right sensor chiude la procedura."],
    conceptTags: ["three-step sequence", "only", "left/right"],
    learningPurpose: "Allena la comprensione di una procedura a tre passaggi, tipica di manuali e laboratori.",
    commandGoal: "Conserva il dato corretto e resetta solo il sensore indicato.",
    method: "Sottolinea i verbi in ordine, poi controlla i limitatori come only.",
    methodSteps: ["check", "write down", "then reset only"],
    glossary: [
      { term: "check", meaning: "controllare" },
      { term: "write down", meaning: "annotare" },
      { term: "only", meaning: "solo / soltanto" }
    ]
  },
  {
    id: "measure-before-switch",
    title: "Misura prima di agire",
    challengeType: "sequence",
    minDifficulty: 3,
    scenario: "Un interruttore può essere chiuso solo dopo aver controllato la tensione.",
    taskPrompt: "Riconosci l'azione preparatoria e quella finale.",
    instruction: "Measure the voltage before closing the switch.",
    correctLabel: "Measure voltage -> Close switch",
    distractors: [
      { label: "Close switch -> Measure voltage", feedback: "Before impone che la misura venga prima della chiusura." },
      { label: "Open the switch", feedback: "Closing significa chiudere, non aprire: qui l'azione è diversa." },
      { label: "Measure temperature", feedback: "Voltage è tensione elettrica, non temperatura." }
    ],
    diagnosticSteps: ["Measure indica misurare.", "Voltage indica la tensione.", "Before stabilisce l'ordine sicuro."],
    conceptTags: ["before", "technical noun", "safety"],
    methodSteps: ["measure", "before", "close"]
  },
  {
    id: "procedure-debug-charge",
    title: "Debug della procedura",
    challengeType: "procedure-debug",
    minDifficulty: 3,
    scenario: "Il log automatico ha riordinato male le istruzioni di ricarica.",
    taskPrompt: "Trova la procedura corretta confrontando istruzione e log guasto.",
    instruction: "Before charging the drone, unplug the red cable and connect the blue cable.",
    sourceText: "Broken log: charge the drone -> unplug the red cable -> connect the blue cable.",
    correctLabel: "Unplug red -> connect blue -> charge drone",
    distractors: [
      { label: "Charge drone -> unplug red -> connect blue", feedback: "Before charging indica che scollegare e collegare devono avvenire prima della ricarica." },
      { label: "Connect blue -> charge drone -> unplug red", feedback: "Unplug the red cable è ancora prima di charging; lasciarlo dopo è rischioso." },
      { label: "Unplug blue -> connect red -> charge drone", feedback: "I colori sono invertiti: il testo dice unplug red e connect blue." }
    ],
    diagnosticSteps: ["Before charging sposta la ricarica alla fine.", "Unplug red e connect blue sono le azioni preparatorie.", "Il log guasto anticipa charging."],
    conceptTags: ["before + -ing", "procedure debug", "colour words"],
    learningPurpose: "Allena il confronto tra istruzione originale e procedura corrotta.",
    commandGoal: "Ripara il log senza inventare passaggi nuovi.",
    method: "Individua il blocco introdotto da before, poi confrontalo con l'ordine del log.",
    methodSteps: ["leggi before", "trova log guasto", "riordina"],
    glossary: [
      { term: "before charging", meaning: "prima di ricaricare" },
      { term: "unplug", meaning: "scollegare" },
      { term: "connect", meaning: "collegare" }
    ]
  },
  {
    id: "simple-vs-now",
    title: "Routine o emergenza",
    challengeType: "condition",
    minDifficulty: 3,
    scenario: "Il manuale distingue ciò che accade di solito da ciò che sta accadendo ora.",
    taskPrompt: "Distingui present simple e present continuous dentro una decisione operativa.",
    instruction: "The scanner usually checks the left gate, but it is checking the right gate now.",
    correctLabel: "Trust right gate now",
    distractors: [
      { label: "Trust left gate now", feedback: "Usually descrive la routine, ma now sposta l'azione attuale sulla right gate." },
      { label: "Check both gates", feedback: "Il testo non ordina di controllare entrambe: indica quale gate è in controllo ora." },
      { label: "Turn scanner off", feedback: "Non c'è un comando di spegnimento; devi distinguere routine e situazione attuale." }
    ],
    diagnosticSteps: ["Usually segnala abitudine.", "Is checking indica azione in corso.", "Now conferma che la situazione attuale riguarda il right gate."],
    conceptTags: ["present simple", "present continuous", "usually", "now"],
    learningPurpose: "Allena la differenza tra routine e azione in corso, competenza chiave della scuola media.",
    commandGoal: "Usa il dato attuale invece dell'abitudine generale.",
    method: "Separa routine e momento presente; quando compare now, scegli l'azione in corso.",
    methodSteps: ["routine", "now", "azione attuale"],
    glossary: [
      { term: "usually", meaning: "di solito" },
      { term: "is checking", meaning: "sta controllando" },
      { term: "right gate", meaning: "porta/cancello destro" }
    ]
  },
  {
    id: "past-log-today",
    title: "Registro di ieri",
    challengeType: "inference",
    minDifficulty: 3,
    scenario: "Il sistema mescola un guasto passato con una lettura aggiornata.",
    taskPrompt: "Distingui past simple e situazione attuale.",
    instruction: "Yesterday the left sensor failed, but today it is working. The right sensor is offline now.",
    sourceText: "Status log: yesterday the left sensor failed. Today it is working. Current warning: the right sensor is offline now.",
    correctLabel: "Fix right sensor now",
    distractors: [
      { label: "Fix left sensor now", feedback: "Yesterday indica un fatto passato; today it is working dice che ora il sensore sinistro funziona." },
      { label: "Ignore both sensors", feedback: "Right sensor is offline now è un problema attuale." },
      { label: "Replace the working sensor", feedback: "Working significa funzionante: non è il componente da riparare." }
    ],
    diagnosticSteps: ["Yesterday segnala un evento passato.", "Today it is working aggiorna lo stato del sensore sinistro.", "Now indica che il sensore destro è il problema attuale."],
    conceptTags: ["past simple", "today", "now", "state change"],
    learningPurpose: "Allena la distinzione tra evento passato e stato presente.",
    commandGoal: "Intervieni sul guasto attuale, non su quello già risolto.",
    method: "Segna le parole-tempo, poi confronta stato vecchio e stato attuale.",
    methodSteps: ["yesterday", "today", "now"],
    glossary: [
      { term: "failed", meaning: "ha smesso di funzionare" },
      { term: "working", meaning: "funzionante" },
      { term: "offline", meaning: "non collegato / non attivo" }
    ]
  },
  {
    id: "some-any-fuses",
    title: "Scorta fusibili",
    challengeType: "vocabulary-in-context",
    minDifficulty: 3,
    scenario: "Il magazzino automatico segnala quantità diverse in tre cassetti.",
    taskPrompt: "Usa some, no e any per trovare la scorta utile.",
    instruction: "There are no spare fuses in drawer A. There are some in drawer C. Do not open drawer B.",
    correctLabel: "Open drawer C",
    distractors: [
      { label: "Open drawer A", feedback: "No spare fuses significa che nel cassetto A non ci sono fusibili utili." },
      { label: "Open drawer B", feedback: "Do not open drawer B è un divieto esplicito." },
      { label: "Open every drawer", feedback: "Il comando vieta B e identifica C come cassetto utile." }
    ],
    diagnosticSteps: ["No indica assenza.", "Some indica presenza di una quantità non precisa ma utile.", "Do not open esclude il cassetto B."],
    conceptTags: ["some/no", "quantity", "do not", "technical nouns"],
    learningPurpose: "Allena quantità, divieti e lessico tecnico scolastico.",
    commandGoal: "Trova il cassetto con materiale utile rispettando il divieto.",
    method: "Leggi quantità e divieto prima di scegliere l'oggetto.",
    methodSteps: ["no", "some", "do not"],
    glossary: [
      { term: "spare", meaning: "di ricambio" },
      { term: "fuse", meaning: "fusibile" },
      { term: "drawer", meaning: "cassetto" }
    ]
  },
  {
    id: "frequency-adverbs",
    title: "Priorità dei controlli",
    challengeType: "inference",
    minDifficulty: 4,
    scenario: "Il terminale usa avverbi di frequenza per descrivere un guasto intermittente.",
    taskPrompt: "Capisci quale evento è raro ma critico.",
    instruction: "Sensor A often blinks during startup. Sensor B rarely blinks, but when it does, the door locks.",
    sourceText: "Maintenance note: Sensor A often blinks during startup. Sensor B rarely blinks, but when it does, the door locks.",
    correctLabel: "Sensor B blinking is critical",
    distractors: [
      { label: "Sensor A blinking is critical", feedback: "Often indica che A lampeggia spesso in avvio; il blocco porta è collegato a B." },
      { label: "Both sensors always lock the door", feedback: "Always non compare e il blocco porta è legato solo a Sensor B." },
      { label: "Ignore Sensor B", feedback: "Rarely non significa inutile: il testo dice che quando B lampeggia, la porta si blocca." }
    ],
    diagnosticSteps: ["Often descrive un evento frequente.", "Rarely descrive un evento raro.", "When it does collega il lampeggio di B alla porta che si blocca."],
    conceptTags: ["often", "rarely", "when", "cause/effect"],
    learningPurpose: "Allena avverbi di frequenza e lettura causa-effetto.",
    commandGoal: "Individua il segnale raro ma importante.",
    method: "Confronta frequenza e conseguenza: non tutto ciò che accade spesso è più importante.",
    methodSteps: ["frequenza", "conseguenza", "priorità"],
    glossary: [
      { term: "often", meaning: "spesso" },
      { term: "rarely", meaning: "raramente" },
      { term: "when it does", meaning: "quando succede" }
    ]
  },
  {
    id: "going-to-scan",
    title: "Piano di scansione",
    challengeType: "sequence",
    minDifficulty: 5,
    scenario: "Un drone ha una procedura futura programmata, ma il pannello consente anche un lancio immediato.",
    taskPrompt: "Riconosci be going to e after come pianificazione, non comando immediato.",
    instruction: "The drone is going to scan the roof after sunrise. Do not launch it now.",
    correctLabel: "Wait until sunrise",
    distractors: [
      { label: "Launch drone now", feedback: "Do not launch it now vieta il lancio immediato." },
      { label: "Scan the basement", feedback: "Il luogo indicato è the roof, non the basement." },
      { label: "Cancel the scan", feedback: "Il testo non annulla la scansione: la pianifica dopo sunrise." }
    ],
    diagnosticSteps: ["Is going to indica un piano futuro.", "After sunrise stabilisce quando.", "Do not launch it now impedisce l'azione immediata."],
    conceptTags: ["be going to", "after", "future plan", "do not"],
    learningPurpose: "Allena futuro intenzionale e ordine temporale in procedure operative.",
    commandGoal: "Rispetta il piano futuro senza anticipare l'azione.",
    method: "Trova il tempo futuro, poi cerca il vincolo temporale e il divieto.",
    methodSteps: ["going to", "after", "not now"],
    glossary: [
      { term: "is going to", meaning: "sta per / ha in programma di" },
      { term: "roof", meaning: "tetto" },
      { term: "sunrise", meaning: "alba" }
    ]
  },
  {
    id: "pronoun-reference",
    title: "Pronome nel log",
    challengeType: "inference",
    minDifficulty: 6,
    scenario: "Un log tecnico usa it e them: devi capire a cosa si riferiscono.",
    taskPrompt: "Collega pronomi e nomi per evitare una riparazione sbagliata.",
    instruction: "The backup cables are clean. The damaged adapter is on the shelf. Replace it, not them.",
    sourceText: "Robot log: the backup cables are clean. The damaged adapter is on the shelf. Replace it, not them.",
    correctLabel: "Replace the adapter",
    distractors: [
      { label: "Replace the cables", feedback: "Them si riferisce a cables, ma il testo dice not them." },
      { label: "Clean the adapter", feedback: "L'adapter è damaged: il comando è replace it." },
      { label: "Replace adapter and cables", feedback: "Not them esclude i cavi, anche se sono nominati." }
    ],
    diagnosticSteps: ["Them richiama un nome plurale: cables.", "It richiama un nome singolare: adapter.", "Replace it, not them seleziona solo l'adattatore."],
    conceptTags: ["pronouns", "it/them", "singular/plural", "repair command"],
    learningPurpose: "Allena riferimento pronominale e precisione lessicale.",
    commandGoal: "Capisci a quale oggetto si riferisce il pronome prima di agire.",
    method: "Cerca nome singolare e plurale; poi collega it e them.",
    methodSteps: ["nomi", "it", "them"],
    glossary: [
      { term: "cables", meaning: "cavi" },
      { term: "adapter", meaning: "adattatore" },
      { term: "replace", meaning: "sostituire" }
    ]
  },
  {
    id: "sensor-below-threshold",
    title: "Dati sensore",
    challengeType: "data-reading",
    minDifficulty: 3,
    scenario: "Tre capsule mostrano dati diversi. Il comando non dice quale capsula: devi dedurlo dai valori.",
    taskPrompt: "Leggi il dato numerico e applica below alla soglia indicata.",
    instruction: "Water the pod whose moisture is below 25. Leave the other pods unchanged.",
    dataPoints: [
      { label: "Pod A", value: "moisture 18", note: "below threshold" },
      { label: "Pod B", value: "moisture 31", note: "safe" },
      { label: "Pod C", value: "moisture 44", note: "safe" }
    ],
    correctLabel: "Water pod A only",
    distractors: [
      { label: "Water all pods", feedback: "Whose moisture is below 25 limita l'azione solo alla capsula sotto soglia." },
      { label: "Water pod B only", feedback: "Pod B è sopra 25: below significa sotto la soglia, non vicino alla soglia." },
      { label: "Do nothing", feedback: "Pod A è sotto 25, quindi almeno un intervento è richiesto." }
    ],
    diagnosticSteps: ["Below 25 definisce la soglia.", "Confronta ogni valore con 25.", "Only evita interventi sulle capsule già stabili."],
    conceptTags: ["below", "data reading", "selective action"],
    learningPurpose: "Allena inglese scientifico base: leggere una soglia e prendere una decisione dai dati.",
    commandGoal: "Intervieni solo sulla capsula che soddisfa la condizione.",
    method: "Traduci below come sotto, confronta i numeri, poi scarta gli oggetti fuori condizione.",
    methodSteps: ["soglia", "confronto dati", "azione selettiva"],
    glossary: [
      { term: "whose", meaning: "il cui / la cui" },
      { term: "moisture", meaning: "umidità" },
      { term: "below", meaning: "sotto" }
    ]
  },
  {
    id: "only-if-stable",
    title: "Condizione luce",
    challengeType: "condition",
    minDifficulty: 4,
    scenario: "Il robot può partire solo se il segnale luminoso è stabile.",
    taskPrompt: "Applica if e otherwise: non esiste un comando valido per tutti i casi.",
    instruction: "If the light is stable, send the robot to the exit. Otherwise wait.",
    correctLabel: "Stable light -> Send robot",
    distractors: [
      { label: "Unstable light -> Send robot", feedback: "Otherwise wait significa aspettare se la luce non è stabile." },
      { label: "Always send robot", feedback: "If crea una condizione: non è un comando sempre valido." },
      { label: "Turn off the light", feedback: "Il testo non ordina di spegnere la luce, ma di decidere se inviare il robot." }
    ],
    diagnosticSteps: ["If introduce una condizione.", "Stable è il requisito per agire.", "Otherwise indica cosa fare nel caso contrario."],
    conceptTags: ["if", "otherwise", "condition"],
    methodSteps: ["if", "caso vero", "otherwise"]
  },
  {
    id: "at-least-three-pulses",
    title: "Limite impulsi",
    challengeType: "condition",
    minDifficulty: 4,
    scenario: "Il trasmettitore accetta un intervallo di impulsi, non un numero unico.",
    taskPrompt: "Individua minimo, massimo e tipo di segnale.",
    instruction: "Send at least three short pulses, but no more than five.",
    correctLabel: "Send 3-5 short pulses",
    distractors: [
      { label: "Send two short pulses", feedback: "At least three significa almeno tre: due non bastano." },
      { label: "Send six short pulses", feedback: "No more than five impone un massimo: sei supera il limite." },
      { label: "Send one long pulse", feedback: "Short pulses indica impulsi brevi e plurali, non un impulso lungo." }
    ],
    diagnosticSteps: ["At least indica un minimo.", "No more than indica un massimo.", "Short pulses descrive il tipo di segnale."],
    conceptTags: ["at least", "no more than", "quantity range"],
    learningPurpose: "Allena la lettura di soglie minime e massime in un comando tecnico.",
    commandGoal: "Scegli una quantità valida senza uscire dall'intervallo richiesto.",
    method: "Trova prima minimo e massimo, poi scarta le azioni fuori intervallo.",
    methodSteps: ["minimo", "massimo", "tipo segnale"],
    glossary: [
      { term: "at least", meaning: "almeno" },
      { term: "no more than", meaning: "non più di" },
      { term: "short pulses", meaning: "impulsi brevi" }
    ]
  },
  {
    id: "compare-two-signals",
    title: "Confronto segnali",
    challengeType: "data-reading",
    minDifficulty: 4,
    scenario: "Due canali hanno intensità diverse: il protocollo usa comparativi, non colori.",
    taskPrompt: "Confronta i valori e applica dimmer/brighter nell'ordine corretto.",
    instruction: "Choose the dimmer signal, then lock the brighter one.",
    dataPoints: [
      { label: "Signal A", value: "42 lux", note: "dimmer" },
      { label: "Signal B", value: "71 lux", note: "brighter" }
    ],
    correctLabel: "Choose A -> Lock B",
    distractors: [
      { label: "Choose B -> Lock A", feedback: "Dimmer indica il segnale meno luminoso: viene scelto per primo." },
      { label: "Lock both signals", feedback: "Il comando distingue due azioni diverse: choose e lock non sono equivalenti." },
      { label: "Ignore signal A", feedback: "Signal A è il meno luminoso nei dati, quindi è proprio quello da scegliere." }
    ],
    diagnosticSteps: ["Dimmer significa meno luminoso.", "Brighter significa più luminoso.", "Then impone l'ordine tra le due azioni."],
    conceptTags: ["comparatives", "data reading", "then"],
    learningPurpose: "Allena comparativi inglesi collegati a dati misurabili.",
    commandGoal: "Usa i dati per scegliere prima il segnale più debole e poi bloccare quello più forte.",
    method: "Ordina i valori, assegna dimmer e brighter, poi rispetta then.",
    methodSteps: ["confronta", "assegna comparativi", "ordina azioni"],
    glossary: [
      { term: "dimmer", meaning: "meno luminoso" },
      { term: "brighter", meaning: "più luminoso" },
      { term: "lock", meaning: "bloccare" }
    ]
  },
  {
    id: "which-route-safest",
    title: "Rotta più sicura",
    challengeType: "data-reading",
    minDifficulty: 5,
    scenario: "Tre percorsi hanno rischio e tempo diversi. Il protocollo chiede la sicurezza, non la velocità.",
    taskPrompt: "Usa comparativi e superlativi collegandoli ai dati.",
    instruction: "Choose the safest route, even if it is slower than the others.",
    dataPoints: [
      { label: "Route A", value: "6 min, medium risk", note: "faster" },
      { label: "Route B", value: "9 min, low risk", note: "safest" },
      { label: "Route C", value: "5 min, high risk", note: "fastest" }
    ],
    correctLabel: "Choose Route B",
    distractors: [
      { label: "Choose Route A", feedback: "A è più veloce di B ma non è la più sicura: safest pesa più di faster." },
      { label: "Choose Route C", feedback: "C è la più veloce, ma high risk la esclude dal criterio safest." },
      { label: "Choose fastest route", feedback: "Il comando dice safest, non fastest: il criterio è sicurezza." }
    ],
    diagnosticSteps: ["Safest è superlativo: cerca il rischio più basso.", "Even if slower elimina il distrattore del tempo.", "Route B ha low risk."],
    conceptTags: ["superlatives", "comparatives", "even if", "data reading"],
    learningPurpose: "Allena comparativi/superlativi e decisione da dati.",
    commandGoal: "Scegli il percorso più sicuro anche se non è il più rapido.",
    method: "Identifica il criterio principale, poi usa i dati per scartare i distrattori.",
    methodSteps: ["criterio", "dati", "scelta"],
    glossary: [
      { term: "safest", meaning: "il più sicuro" },
      { term: "slower", meaning: "più lento" },
      { term: "even if", meaning: "anche se" }
    ]
  },
  {
    id: "relative-drawer",
    title: "Cassetto corretto",
    challengeType: "vocabulary-in-context",
    minDifficulty: 5,
    scenario: "Due cassetti sembrano simili: la frase relativa identifica quello utile.",
    taskPrompt: "Usa that/which per capire quale oggetto è definito dalla descrizione.",
    instruction: "Open the drawer that contains the spare fuse, not the drawer with old cables.",
    correctLabel: "Open spare-fuse drawer",
    distractors: [
      { label: "Open old-cables drawer", feedback: "Not the drawer with old cables esclude quel cassetto." },
      { label: "Open both drawers", feedback: "La relativa seleziona un cassetto preciso; aprirli entrambi viola il divieto." },
      { label: "Replace all cables", feedback: "Il comando parla di drawer e spare fuse, non di sostituire cavi." }
    ],
    diagnosticSteps: ["Drawer è l'oggetto principale.", "That contains the spare fuse identifica quello corretto.", "Not esclude il cassetto con vecchi cavi."],
    conceptTags: ["relative clause", "that", "not", "technical nouns"],
    learningPurpose: "Allena frasi relative semplici e lessico tecnico in contesto.",
    commandGoal: "Scegli l'oggetto identificato dalla descrizione, non dal primo nome disponibile.",
    method: "Leggi nome principale, frase relativa e divieto finale.",
    methodSteps: ["nome", "that", "not"],
    glossary: [
      { term: "drawer", meaning: "cassetto" },
      { term: "spare fuse", meaning: "fusibile di ricambio" },
      { term: "old cables", meaning: "vecchi cavi" }
    ]
  },
  {
    id: "neither-red-nor-yellow",
    title: "Cavo autorizzato",
    challengeType: "safety",
    minDifficulty: 5,
    scenario: "Tre cavi alimentano il quadro. Due sono vietati dalla stessa frase.",
    taskPrompt: "Gestisci un divieto doppio senza trasformarlo in una scelta libera.",
    instruction: "Use the blue cable. Do not use either the red cable or the yellow cable.",
    correctLabel: "Use blue cable",
    distractors: [
      { label: "Use red cable", feedback: "Red cable è dentro il divieto: do not use either...or vieta entrambe le alternative." },
      { label: "Use yellow cable", feedback: "Yellow cable è vietato quanto red cable; either...or non autorizza una scelta." },
      { label: "Use red and yellow", feedback: "Either...or qui elenca oggetti vietati dentro do not use, non oggetti da usare insieme." }
    ],
    diagnosticSteps: ["Use indica l'oggetto corretto.", "Do not use introduce il divieto.", "Either...or collega due oggetti entrambi vietati."],
    conceptTags: ["either/or", "do not", "object choice"],
    learningPurpose: "Allena la gestione di due distrattori vietati nello stesso comando.",
    commandGoal: "Individua l'unico cavo autorizzato e scarta entrambi i cavi proibiti.",
    method: "Prima trova l'azione positiva, poi marca tutti gli oggetti dentro do not use.",
    methodSteps: ["azione positiva", "divieto", "lista vietata"],
    glossary: [
      { term: "either...or", meaning: "uno o l'altro; qui entrambi nel divieto" },
      { term: "cable", meaning: "cavo" }
    ]
  },
  {
    id: "replace-only-damaged",
    title: "Fusibili selettivi",
    challengeType: "vocabulary-in-context",
    minDifficulty: 5,
    scenario: "Il pannello contiene fusibili guasti e fusibili integri: una sostituzione inutile può creare un nuovo guasto.",
    taskPrompt: "Usa only, damaged e intact per capire quanto deve essere limitato l'intervento.",
    instruction: "Replace only the damaged fuse; leave the intact fuses in place.",
    correctLabel: "Replace damaged fuse only",
    distractors: [
      { label: "Replace all fuses", feedback: "Only limita l'intervento al fusibile danneggiato; tutti è troppo esteso." },
      { label: "Leave damaged fuse", feedback: "Replace the damaged fuse chiede di sostituire proprio quello guasto." },
      { label: "Remove intact fuses", feedback: "Leave the intact fuses in place significa lasciarli al loro posto." }
    ],
    diagnosticSteps: ["Replace indica sostituire.", "Only restringe l'azione.", "Damaged e intact distinguono guasto e integro."],
    conceptTags: ["only", "opposites", "technical adjectives"],
    learningPurpose: "Allena lessico tecnico in contesto e limitatori come only.",
    commandGoal: "Intervieni solo sul componente guasto senza toccare quelli sani.",
    method: "Trova il limitatore only, poi separa damaged da intact.",
    methodSteps: ["replace", "only", "damaged vs intact"],
    glossary: [
      { term: "replace", meaning: "sostituire" },
      { term: "damaged", meaning: "danneggiato" },
      { term: "intact", meaning: "integro" },
      { term: "in place", meaning: "al suo posto" }
    ]
  },
  {
    id: "cause-report",
    title: "Rapporto essenziale",
    challengeType: "inference",
    minDifficulty: 5,
    scenario: "NORA chiede un rapporto breve: bisogna separare causa utile e dettagli decorativi.",
    taskPrompt: "Leggi il log e scegli solo l'informazione che risponde alla richiesta.",
    instruction: "Report the cause of the shutdown. Do not report the time or the colour of the warning light.",
    sourceText: "Log: At 07:40 the warning light turned purple. The cooling fan stopped, so the archive shut down.",
    correctLabel: "Cause: the cooling fan stopped",
    distractors: [
      { label: "Time: 07:40", feedback: "Il testo dice do not report the time: l'orario è un dettaglio escluso." },
      { label: "Colour: purple warning light", feedback: "Il colore è nominato nel log ma è vietato dalla richiesta." },
      { label: "Cause: the archive shut down", feedback: "Lo shutdown è l'effetto da spiegare, non la causa che lo ha prodotto." }
    ],
    diagnosticSteps: ["Report the cause definisce la domanda.", "Do not report esclude tempo e colore.", "So collega causa ed effetto nel log."],
    conceptTags: ["cause/effect", "irrelevant detail", "do not"],
    learningPurpose: "Allena comprensione del testo breve e selezione di informazioni rilevanti.",
    commandGoal: "Rispondi alla richiesta senza copiare dettagli inutili dal log.",
    method: "Leggi la domanda, elimina i dettagli vietati, poi cerca il rapporto causa-effetto.",
    methodSteps: ["richiesta", "dettagli esclusi", "causa"],
    glossary: [
      { term: "cause", meaning: "causa" },
      { term: "shutdown", meaning: "spegnimento/arresto" },
      { term: "warning light", meaning: "spia di avviso" }
    ]
  },
  {
    id: "between-limits",
    title: "Intervallo temperatura",
    challengeType: "data-reading",
    minDifficulty: 6,
    scenario: "La serra invia un dato numerico: la risposta cambia se il valore è dentro o fuori intervallo.",
    taskPrompt: "Controlla entrambi gli estremi di between.",
    instruction: "If the temperature is between 18 and 24 degrees, open the vent halfway; otherwise keep it closed.",
    dataPoints: [{ label: "Temperature", value: "21°C", note: "inside range" }],
    correctLabel: "21°C -> Vent halfway",
    distractors: [
      { label: "21°C -> Keep vent closed", feedback: "21 è tra 18 e 24, quindi vale la prima parte del comando." },
      { label: "21°C -> Fully open vent", feedback: "Halfway significa a metà, non completamente aperto." },
      { label: "Below 18°C -> Vent halfway", feedback: "Between 18 and 24 esclude i valori sotto 18." }
    ],
    diagnosticSteps: ["If introduce la condizione.", "Between 18 and 24 definisce un intervallo.", "Otherwise dice cosa fare fuori intervallo.", "Halfway limita l'apertura."],
    conceptTags: ["between", "range", "otherwise"],
    learningPurpose: "Allena lettura di intervalli numerici e azioni proporzionate.",
    commandGoal: "Apri la ventola solo se il dato cade nell'intervallo richiesto.",
    method: "Controlla il dato rispetto ai due estremi, poi scegli l'azione collegata alla condizione.",
    methodSteps: ["estremo basso", "estremo alto", "azione"],
    glossary: [
      { term: "between", meaning: "tra" },
      { term: "vent", meaning: "presa d'aria / bocchetta" },
      { term: "halfway", meaning: "a metà" }
    ]
  },
  {
    id: "unless-blue-blinks",
    title: "Eccezione al reset",
    challengeType: "condition",
    minDifficulty: 6,
    scenario: "Il reset è normalmente vietato, ma una spia può creare l'unica eccezione.",
    taskPrompt: "Interpreta unless come eccezione, non come semplice if.",
    instruction: "Do not reset the panel unless the blue light is blinking.",
    correctLabel: "Reset only if blue blinks",
    distractors: [
      { label: "Always reset panel", feedback: "Unless introduce un'eccezione: non è un via libera sempre valido." },
      { label: "Reset if blue is off", feedback: "Blinking significa che la luce lampeggia, non che è spenta." },
      { label: "Turn off blue light", feedback: "Il comando non chiede di spegnere la luce; decide quando il reset è permesso." }
    ],
    diagnosticSteps: ["Do not reset è il divieto iniziale.", "Unless introduce l'unico caso permesso.", "Blinking significa lampeggiante."],
    conceptTags: ["unless", "exception", "blinking"],
    methodSteps: ["divieto", "unless", "caso permesso"]
  },
  {
    id: "after-robot-dock",
    title: "Valvola sincronizzata",
    challengeType: "sequence",
    minDifficulty: 6,
    scenario: "La valvola può aprirsi solo dopo l'arrivo del robot alla base.",
    taskPrompt: "Non anticipare l'azione: after e not before dicono la stessa regola da due lati.",
    instruction: "Open the valve after the robot reaches the dock, not before.",
    correctLabel: "Robot at dock -> Open valve",
    distractors: [
      { label: "Open valve before robot arrives", feedback: "Not before vieta l'apertura anticipata della valvola." },
      { label: "Send robot away", feedback: "Il testo dice reaches the dock, non leave the dock." },
      { label: "Close the valve", feedback: "Open significa aprire: close sarebbe l'azione opposta." }
    ],
    diagnosticSteps: ["After ordina le azioni.", "Reaches the dock indica arrivo alla base.", "Not before rinforza il divieto di anticipare."],
    conceptTags: ["after", "not before", "synchronisation"],
    methodSteps: ["evento", "after", "azione"]
  },
  {
    id: "until-door-unlocks",
    title: "Impulso dopo attesa",
    challengeType: "condition",
    minDifficulty: 7,
    scenario: "La porta deve sbloccarsi prima dell'impulso finale.",
    taskPrompt: "Usa until per capire fino a quando mantenere lo stato iniziale.",
    instruction: "Keep the circuit open until the door unlocks, then close it for one pulse.",
    correctLabel: "Wait open -> One close pulse",
    distractors: [
      { label: "Close circuit immediately", feedback: "Until indica che devi aspettare lo sblocco della porta." },
      { label: "Keep circuit closed", feedback: "Keep open dice di mantenere aperto, non chiuso." },
      { label: "Close it twice", feedback: "One pulse significa un solo impulso, non due." }
    ],
    diagnosticSteps: ["Keep open descrive lo stato iniziale.", "Until indica fino a quando attendere.", "Then close it for one pulse chiede un'azione breve e singola."],
    conceptTags: ["until", "then", "one pulse"],
    methodSteps: ["stato iniziale", "until", "then"]
  },
  {
    id: "not-until-pressure-drops",
    title: "Soglia di pressione",
    challengeType: "condition",
    minDifficulty: 7,
    scenario: "Lo sportello resta bloccato finché la pressione non scende sotto soglia.",
    taskPrompt: "Capisci quando termina un divieto con not until.",
    instruction: "Do not unlock the hatch until the pressure drops below 5 units.",
    correctLabel: "Wait; unlock below 5",
    distractors: [
      { label: "Unlock immediately", feedback: "Do not unlock vieta l'apertura immediata dello sportello." },
      { label: "Unlock above 5", feedback: "Below 5 significa sotto 5, non sopra la soglia." },
      { label: "Keep locked below 5 forever", feedback: "Until indica che il divieto termina quando la pressione scende sotto 5." }
    ],
    diagnosticSteps: ["Do not unlock è il divieto iniziale.", "Until indica la condizione che termina l'attesa.", "Below 5 units è la soglia richiesta."],
    conceptTags: ["not until", "threshold", "safety condition"],
    learningPurpose: "Allena comandi di sicurezza con attesa e soglia numerica.",
    commandGoal: "Non anticipare lo sblocco: aspetta la condizione misurabile.",
    method: "Leggi prima il divieto, poi individua la condizione che lo sblocca.",
    methodSteps: ["divieto", "until", "soglia"],
    glossary: [
      { term: "unlock", meaning: "sbloccare" },
      { term: "hatch", meaning: "sportello" },
      { term: "pressure", meaning: "pressione" },
      { term: "drops below", meaning: "scende sotto" }
    ]
  },
  {
    id: "may-must-not",
    title: "Permesso e divieto",
    challengeType: "safety",
    minDifficulty: 7,
    scenario: "Il manuale distingue ciò che è permesso da ciò che è vietato finché manca autorizzazione.",
    taskPrompt: "Distingui may, must not e yet.",
    instruction: "You may inspect the panel, but you must not reset it yet.",
    correctLabel: "Inspect panel; do not reset",
    distractors: [
      { label: "Reset panel immediately", feedback: "Must not reset it yet vieta il reset per ora." },
      { label: "Do not inspect the panel", feedback: "May inspect dà il permesso di ispezionare." },
      { label: "Inspect and reset panel", feedback: "La prima azione è permessa, la seconda è vietata da must not." }
    ],
    diagnosticSteps: ["May indica permesso.", "But introduce contrasto.", "Must not è un divieto forte.", "Yet significa per ora/non ancora."],
    conceptTags: ["may", "must not", "yet", "contrast"],
    learningPurpose: "Allena modali di permesso e divieto in istruzioni di sicurezza.",
    commandGoal: "Esegui solo l'azione permessa e rimanda quella vietata.",
    method: "Separa la parte prima e dopo but; poi valuta il modale di ciascuna azione.",
    methodSteps: ["may", "but", "must not"],
    glossary: [
      { term: "may", meaning: "puoi / è permesso" },
      { term: "must not", meaning: "non devi / divieto forte" },
      { term: "yet", meaning: "ancora / per ora" }
    ]
  },
  {
    id: "passive-reattach-wire",
    title: "Passivo tecnico",
    challengeType: "procedure-debug",
    minDifficulty: 8,
    scenario: "Il log descrive un guasto con forma passiva: devi trasformarlo in azione correttiva.",
    taskPrompt: "Capisci chi subisce l'azione e quale riparazione è richiesta.",
    instruction: "The red wire has been disconnected; it must be reattached before testing.",
    sourceText: "Broken plan: test circuit -> check red wire later.",
    correctLabel: "Reattach red wire -> Test",
    distractors: [
      { label: "Test circuit first", feedback: "Before testing dice che il filo va ricollegato prima del test." },
      { label: "Disconnect red wire", feedback: "Has been disconnected descrive il guasto; la riparazione è reattached." },
      { label: "Check wire later", feedback: "Later è nel piano guasto; il comando richiede before testing." }
    ],
    diagnosticSteps: ["Has been disconnected descrive lo stato del filo.", "Must be reattached indica obbligo di riparazione.", "Before testing ordina la riparazione prima del test."],
    conceptTags: ["passive form", "must be", "before", "technical repair"],
    learningPurpose: "Introduce il passivo tecnico collegandolo a una riparazione concreta.",
    commandGoal: "Trasforma il log passivo in una procedura corretta.",
    method: "Leggi lo stato guasto, trova l'obbligo con must be, poi rispetta before.",
    methodSteps: ["stato", "must be", "before"],
    glossary: [
      { term: "has been disconnected", meaning: "è stato scollegato" },
      { term: "reattached", meaning: "ricollegato" },
      { term: "before testing", meaning: "prima di testare" }
    ]
  },
  {
    id: "must-should-cable",
    title: "Obbligo e consiglio",
    challengeType: "vocabulary-in-context",
    minDifficulty: 7,
    scenario: "Il manuale distingue un obbligo tecnico da una raccomandazione di prudenza.",
    taskPrompt: "Distingui must, should not e backup line.",
    instruction: "The damaged cable must be replaced, but the backup line should not be disconnected.",
    correctLabel: "Replace damaged cable; keep backup connected",
    distractors: [
      { label: "Disconnect backup line first", feedback: "Should not be disconnected indica che la linea di backup deve restare collegata." },
      { label: "Leave damaged cable in place", feedback: "Must be replaced indica un obbligo forte: il cavo danneggiato va sostituito." },
      { label: "Replace backup line only", feedback: "Backup line non è il componente danneggiato e non è quello da sostituire." }
    ],
    diagnosticSteps: ["Must indica obbligo.", "Damaged cable è il componente da sostituire.", "Should not be disconnected protegge la linea di backup."],
    conceptTags: ["must", "should not", "passive form"],
    learningPurpose: "Introduce modali e passivo tecnico senza trasformarli in esercizio astratto.",
    commandGoal: "Esegui l'obbligo e rispetta la raccomandazione di sicurezza.",
    method: "Separa must da should not, poi collega ogni verbo al componente corretto.",
    methodSteps: ["must", "oggetto", "should not"],
    glossary: [
      { term: "must", meaning: "deve / obbligo" },
      { term: "should not", meaning: "non dovrebbe / raccomandazione forte" },
      { term: "backup line", meaning: "linea di riserva" }
    ]
  },
  {
    id: "possessive-their-its",
    title: "Proprietà dei moduli",
    challengeType: "vocabulary-in-context",
    minDifficulty: 2,
    scenario: "Due droni hanno lasciato sensori simili sul banco. Il comando distingue proprietario e oggetto.",
    taskPrompt: "Usa aggettivi possessivi e pronome it per scegliere il sensore corretto.",
    instruction: "Take their spare sensor and put it in its charging slot.",
    correctLabel: "Take the team's spare sensor -> charging slot",
    distractors: [
      { label: "Take Eli's personal sensor", feedback: "Their indica il sensore del gruppo o dei droni, non l'oggetto personale di Eli." },
      { label: "Put the sensor in any slot", feedback: "Its charging slot indica lo slot proprio di quel sensore: any slot è troppo generico." },
      { label: "Take the charger only", feedback: "It si riferisce al sensor appena nominato, non al caricatore." }
    ],
    diagnosticSteps: ["Their indica appartenenza a più persone o sistemi.", "It riprende il sensore appena citato.", "Its indica lo slot appartenente al sensore."],
    conceptTags: ["possessives", "their/its", "pronoun reference"],
    learningPurpose: "Allena possessivi e riferimenti pronominali, frequenti nei testi tecnici brevi.",
    commandGoal: "Evita di scambiare proprietario, oggetto e destinazione.",
    method: "Cerca prima il nome principale, poi collega ogni pronome all'ultimo oggetto sensato.",
    methodSteps: ["their", "it", "its"],
    glossary: [
      { term: "their", meaning: "loro / del gruppo" },
      { term: "it", meaning: "esso / lo" },
      { term: "its", meaning: "suo, riferito a una cosa" }
    ]
  },
  {
    id: "movement-prepositions-route",
    title: "Percorso nel condotto",
    challengeType: "sequence",
    minDifficulty: 2,
    scenario: "Un micro-drone deve attraversare un condotto senza urtare i pannelli isolati.",
    taskPrompt: "Interpreta preposizioni di movimento in una rotta operativa.",
    instruction: "Move through the tunnel, across the bridge, and into the control room.",
    correctLabel: "Tunnel -> bridge -> control room",
    distractors: [
      { label: "Bridge -> tunnel -> control room", feedback: "L'ordine dei luoghi segue la frase: through the tunnel viene prima di across the bridge." },
      { label: "Tunnel -> under the bridge -> control room", feedback: "Across significa attraverso/sopra la superficie del ponte, non sotto il ponte." },
      { label: "Tunnel -> bridge -> outside the room", feedback: "Into indica entrare nella stanza, non restare fuori." }
    ],
    diagnosticSteps: ["Through indica attraversare un volume o corridoio.", "Across indica attraversare una superficie o ponte.", "Into indica movimento verso l'interno."],
    conceptTags: ["prepositions of movement", "through", "across", "into"],
    learningPurpose: "Allena preposizioni di movimento con una sequenza concreta.",
    commandGoal: "Trasforma una frase spaziale in una rotta eseguibile.",
    methodSteps: ["through", "across", "into"],
    glossary: [
      { term: "through", meaning: "attraverso, dentro un passaggio" },
      { term: "across", meaning: "attraverso una superficie" },
      { term: "into", meaning: "verso l'interno" }
    ]
  },
  {
    id: "much-many-supplies",
    title: "Scorte misurabili",
    challengeType: "vocabulary-in-context",
    minDifficulty: 3,
    scenario: "Il magazzino distingue materiali numerabili e non numerabili.",
    taskPrompt: "Scegli la frase che usa correttamente much, many, a little e a few.",
    instruction: "The repair kit has little coolant but many spare bolts. Take a few bolts and add more coolant.",
    correctLabel: "Take some bolts; add coolant",
    distractors: [
      { label: "Take coolant only", feedback: "Il comando chiede anche a few bolts: i bulloni sono numerabili e servono in piccola quantità." },
      { label: "Take all bolts", feedback: "A few significa alcuni, non tutti; many descrive la scorta disponibile." },
      { label: "Ignore coolant", feedback: "Little coolant segnala che il liquido è scarso e va aggiunto." }
    ],
    diagnosticSteps: ["Little si usa con quantità non numerabile e indica scarsità.", "Many si usa con elementi numerabili plurali.", "A few indica alcuni elementi, non tutti."],
    conceptTags: ["much/many", "few/little", "countable/uncountable"],
    learningPurpose: "Allena quantità e nomi numerabili/non numerabili in un contesto tecnico.",
    commandGoal: "Preleva solo la quantità utile e correggi la scorta carente.",
    methodSteps: ["little", "many", "a few"],
    glossary: [
      { term: "coolant", meaning: "liquido refrigerante" },
      { term: "bolt", meaning: "bullone" },
      { term: "a few", meaning: "alcuni" }
    ]
  },
  {
    id: "present-perfect-already-yet",
    title: "Controlli completati",
    challengeType: "inference",
    minDifficulty: 4,
    scenario: "Il log distingue ciò che è già stato fatto da ciò che manca ancora.",
    taskPrompt: "Usa present perfect con already e yet per decidere il prossimo passo.",
    instruction: "The scanner has already checked the left door, but it has not checked the right door yet.",
    sourceText: "Scan log: the scanner has already checked the left door. Missing step: it has not checked the right door yet.",
    correctLabel: "Check the right door",
    distractors: [
      { label: "Check the left door again", feedback: "Already checked indica che il controllo sinistro è già stato completato." },
      { label: "Open both doors", feedback: "Il testo parla di controllare, non di aprire le porte." },
      { label: "Stop the scanner", feedback: "Yet indica un controllo non ancora fatto: il prossimo passo è completarlo." }
    ],
    diagnosticSteps: ["Has already checked indica azione completata.", "Has not checked yet indica azione non ancora completata.", "Il prossimo passo riguarda la right door."],
    conceptTags: ["present perfect", "already", "yet"],
    learningPurpose: "Allena una struttura centrale della scuola media: azioni già completate e azioni ancora da fare.",
    commandGoal: "Non ripetere un controllo già concluso: completa quello mancante.",
    methodSteps: ["already", "not yet", "next action"],
    glossary: [
      { term: "already", meaning: "già" },
      { term: "yet", meaning: "ancora / non ancora" },
      { term: "has checked", meaning: "ha controllato" }
    ]
  },
  {
    id: "past-vs-present-perfect-log",
    title: "Evento o risultato",
    challengeType: "inference",
    minDifficulty: 4,
    scenario: "Un registro mescola un evento concluso e un risultato ancora valido.",
    taskPrompt: "Distingui past simple e present perfect nel log.",
    instruction: "The pump failed at 06:10. The backup system has kept the plants alive since then.",
    sourceText: "Greenhouse log: the pump failed at 06:10. The backup system has kept the plants alive since then.",
    correctLabel: "Pump failed; backup is still helping",
    distractors: [
      { label: "Backup failed at 06:10", feedback: "Failed at 06:10 si riferisce alla pump, non al sistema di backup." },
      { label: "Plants are already dead", feedback: "Has kept the plants alive indica un risultato positivo ancora valido." },
      { label: "Ignore the pump failure", feedback: "Il guasto della pompa è l'evento iniziale da riparare, anche se il backup sta aiutando." }
    ],
    diagnosticSteps: ["Failed at 06:10 è past simple con tempo preciso.", "Has kept indica effetto iniziato nel passato e ancora rilevante.", "Since then collega il risultato al momento del guasto."],
    conceptTags: ["past simple", "present perfect", "since"],
    learningPurpose: "Allena la differenza tra evento passato e risultato ancora attivo.",
    commandGoal: "Capisci cosa è successo e quale sistema sta ancora proteggendo la missione.",
    methodSteps: ["time marker", "present perfect", "result"],
    glossary: [
      { term: "failed", meaning: "si è guastata" },
      { term: "has kept", meaning: "ha mantenuto" },
      { term: "since then", meaning: "da allora" }
    ]
  },
  {
    id: "first-conditional-alarm",
    title: "Allarme condizionale",
    challengeType: "condition",
    minDifficulty: 4,
    scenario: "Il sistema antincendio reagisce solo se una condizione futura diventa vera.",
    taskPrompt: "Interpreta il first conditional senza anticipare l'azione.",
    instruction: "If the smoke level rises above 30, the alarm will lock the east door.",
    dataPoints: [{ label: "Smoke level", value: "28", note: "below limit" }],
    correctLabel: "Do not lock the east door yet",
    distractors: [
      { label: "Lock the east door now", feedback: "Il valore 28 non è above 30: la condizione non è ancora vera." },
      { label: "Open the west door", feedback: "Il comando parla di east door e di un possibile blocco, non della porta ovest." },
      { label: "Disable the alarm", feedback: "Il testo descrive cosa farà l'allarme se la soglia sale; non ordina di disattivarlo." }
    ],
    diagnosticSteps: ["If introduce la condizione.", "Rises above 30 richiede un valore maggiore di 30.", "Will lock descrive l'effetto futuro se la condizione si verifica."],
    conceptTags: ["first conditional", "if", "will", "threshold"],
    learningPurpose: "Allena periodo ipotetico di primo tipo con soglie misurabili.",
    commandGoal: "Agisci solo quando il dato soddisfa la condizione.",
    methodSteps: ["if", "threshold", "will"],
    glossary: [
      { term: "rises above", meaning: "sale sopra" },
      { term: "will", meaning: "farà / futuro" },
      { term: "smoke", meaning: "fumo" }
    ]
  },
  {
    id: "zero-conditional-rule",
    title: "Regola automatica",
    challengeType: "condition",
    minDifficulty: 4,
    scenario: "Il manuale descrive una regola sempre valida, non un evento singolo.",
    taskPrompt: "Riconosci lo zero conditional come regola generale.",
    instruction: "If a sensor loses power, it sends no data.",
    correctLabel: "No power -> no data",
    distractors: [
      { label: "No power -> more data", feedback: "Loses power significa perdere alimentazione; il risultato è no data, non più dati." },
      { label: "Power on -> no data", feedback: "La regola riguarda il caso in cui il sensore perde alimentazione." },
      { label: "Ignore the sensor", feedback: "La frase spiega una relazione causa-effetto utile per diagnosticare il guasto." }
    ],
    diagnosticSteps: ["If introduce una condizione generale.", "Loses power è la causa.", "Sends no data è la conseguenza."],
    conceptTags: ["zero conditional", "cause/effect", "technical rule"],
    learningPurpose: "Allena regole generali in inglese scientifico-operativo.",
    commandGoal: "Usa la regola per diagnosticare il perché mancano dati.",
    methodSteps: ["if", "cause", "effect"],
    glossary: [
      { term: "loses power", meaning: "perde alimentazione" },
      { term: "sends", meaning: "invia" },
      { term: "no data", meaning: "nessun dato" }
    ]
  },
  {
    id: "although-however-report",
    title: "Rapporto con contrasto",
    challengeType: "inference",
    minDifficulty: 5,
    scenario: "Il report contiene una buona notizia e un problema reale collegati da connettivi.",
    taskPrompt: "Usa although e however per non confondere contrasto e causa.",
    instruction: "Although the battery is full, the robot does not move. However, its left wheel is jammed.",
    sourceText: "Robot report: although the battery is full, the robot does not move. However, its left wheel is jammed.",
    correctLabel: "Battery ok; fix left wheel",
    distractors: [
      { label: "Recharge the battery", feedback: "Although the battery is full esclude la batteria come problema principale." },
      { label: "Replace the right wheel", feedback: "Il log identifica la left wheel, non la ruota destra." },
      { label: "Start a battery test only", feedback: "However introduce il dato decisivo: la ruota sinistra è bloccata." }
    ],
    diagnosticSteps: ["Although introduce un contrasto.", "Battery is full indica che la batteria non è scarica.", "However segnala il problema effettivo: left wheel jammed."],
    conceptTags: ["although", "however", "contrast", "inference"],
    learningPurpose: "Allena connettivi logici e lettura critica di un breve report.",
    commandGoal: "Non fermarti al primo dettaglio: trova il contrasto che cambia la diagnosi.",
    methodSteps: ["although", "however", "real fault"],
    glossary: [
      { term: "although", meaning: "sebbene / anche se" },
      { term: "however", meaning: "tuttavia" },
      { term: "jammed", meaning: "bloccato" }
    ]
  },
  {
    id: "main-idea-log",
    title: "Idea principale del log",
    challengeType: "inference",
    minDifficulty: 5,
    scenario: "Il terminale mostra molti dettagli. Serve capire il messaggio principale.",
    taskPrompt: "Scegli la sintesi più fedele, non il dettaglio più vistoso.",
    instruction: "Read the log and choose its main idea.",
    sourceText: "Log: The corridor lights flickered twice. The air filter became blocked, so the temperature rose and the seedlings started to dry.",
    correctLabel: "Blocked filter caused overheating and dry seedlings",
    distractors: [
      { label: "The lights flickered twice", feedback: "È un dettaglio presente, ma non spiega il problema principale." },
      { label: "The seedlings grew faster", feedback: "Il testo dice started to dry: le piantine hanno iniziato a seccarsi." },
      { label: "The temperature dropped because of the filter", feedback: "Il testo dice temperature rose, quindi è salita." }
    ],
    diagnosticSteps: ["Main idea chiede la sintesi centrale.", "So collega filtro bloccato, temperatura alta e piantine secche.", "I lampeggi sono dettagli non decisivi."],
    conceptTags: ["main idea", "cause/effect", "irrelevant detail"],
    learningPurpose: "Allena comprensione globale e selezione delle informazioni rilevanti.",
    commandGoal: "Trasforma un log breve in una diagnosi sintetica.",
    methodSteps: ["topic", "cause", "effect"],
    glossary: [
      { term: "main idea", meaning: "idea principale" },
      { term: "blocked", meaning: "bloccato" },
      { term: "seedlings", meaning: "piantine" }
    ]
  },
  {
    id: "detail-not-mentioned",
    title: "Dettaglio non detto",
    challengeType: "inference",
    minDifficulty: 5,
    scenario: "NORA controlla se Eli sta leggendo davvero o sta inventando informazioni.",
    taskPrompt: "Distingui informazione esplicita, inferenza e dettaglio assente.",
    instruction: "Which detail is not mentioned in the log?",
    sourceText: "Log: The blue drone scanned the roof at noon. It found two loose panels near the antenna.",
    correctLabel: "The battery level",
    distractors: [
      { label: "The drone colour", feedback: "Blue drone è nominato esplicitamente nel log." },
      { label: "The time of the scan", feedback: "At noon indica l'orario della scansione." },
      { label: "The loose panels", feedback: "Two loose panels è una delle informazioni principali del log." }
    ],
    diagnosticSteps: ["Not mentioned chiede ciò che manca.", "Blue, noon e loose panels compaiono nel testo.", "Battery level non viene indicato."],
    conceptTags: ["not mentioned", "detail reading", "question words"],
    learningPurpose: "Allena lettura precisa e controllo dell'inferenza non autorizzata.",
    commandGoal: "Non inventare dati: separa testo presente e testo assente.",
    methodSteps: ["question", "scan text", "missing detail"],
    glossary: [
      { term: "mentioned", meaning: "menzionato" },
      { term: "loose", meaning: "allentato" },
      { term: "near", meaning: "vicino a" }
    ]
  },
  {
    id: "question-formation-why",
    title: "Domanda diagnostica",
    challengeType: "vocabulary-in-context",
    minDifficulty: 5,
    scenario: "Il terminale accetta solo domande costruite correttamente.",
    taskPrompt: "Scegli la domanda inglese corretta per chiedere una causa.",
    instruction: "Ask why the robot stopped near the gate.",
    correctLabel: "Why did the robot stop near the gate?",
    distractors: [
      { label: "Why the robot stopped near the gate?", feedback: "Nelle domande al passato serve did prima del soggetto." },
      { label: "Where did the robot stop near the gate?", feedback: "Where chiede il luogo; qui il comando chiede why, la causa." },
      { label: "Why does the robot stopped near the gate?", feedback: "Con did il verbo resta alla forma base stop, non stopped." }
    ],
    diagnosticSteps: ["Why chiede la causa.", "Past simple interrogativo usa did.", "Il verbo principale torna alla forma base stop."],
    conceptTags: ["question formation", "why", "past simple"],
    learningPurpose: "Allena costruzione delle domande, competenza fondamentale della scuola media.",
    commandGoal: "Formula una domanda utile per una diagnosi, non una frase dichiarativa mascherata.",
    methodSteps: ["question word", "did", "base verb"],
    glossary: [
      { term: "why", meaning: "perché" },
      { term: "did", meaning: "ausiliare per domanda al passato" },
      { term: "near", meaning: "vicino a" }
    ]
  },
  {
    id: "relative-where-lab",
    title: "Stanza corretta",
    challengeType: "vocabulary-in-context",
    minDifficulty: 5,
    scenario: "Tre stanze hanno nomi simili. La frase relativa indica quella giusta.",
    taskPrompt: "Usa where per collegare luogo e azione.",
    instruction: "Enter the room where the plants are stored, not the room where the batteries are charged.",
    correctLabel: "Enter plant storage room",
    distractors: [
      { label: "Enter battery charging room", feedback: "Not the room where the batteries are charged esclude quella stanza." },
      { label: "Enter both rooms", feedback: "Il comando seleziona una stanza e ne esclude un'altra." },
      { label: "Charge the plants", feedback: "Stored significa conservate; non è un comando di ricarica." }
    ],
    diagnosticSteps: ["Where introduce una relativa di luogo.", "Plants are stored identifica la stanza corretta.", "Not esclude la stanza delle batterie."],
    conceptTags: ["relative clause", "where", "places"],
    learningPurpose: "Allena relative di luogo applicate a istruzioni operative.",
    commandGoal: "Individua il luogo giusto usando la descrizione, non solo una parola isolata.",
    methodSteps: ["room", "where", "not"],
    glossary: [
      { term: "where", meaning: "dove / in cui" },
      { term: "stored", meaning: "conservate" },
      { term: "charged", meaning: "ricaricate" }
    ]
  },
  {
    id: "adverbs-manner-safety",
    title: "Modo dell'azione",
    challengeType: "safety",
    minDifficulty: 5,
    scenario: "Il braccio robotico può riuscire o danneggiare il campione in base al modo in cui si muove.",
    taskPrompt: "Interpreta avverbi di modo dentro una procedura sicura.",
    instruction: "Move the sample carefully, then close the container quickly.",
    correctLabel: "Careful move -> quick close",
    distractors: [
      { label: "Quick move -> careful close", feedback: "Carefully modifica move, mentre quickly modifica close: hai scambiato gli avverbi." },
      { label: "Move and leave container open", feedback: "Then close the container quickly è una seconda azione obbligatoria." },
      { label: "Throw the sample into the container", feedback: "Carefully indica un movimento controllato, non brusco." }
    ],
    diagnosticSteps: ["Carefully descrive come muovere il campione.", "Then introduce la seconda azione.", "Quickly descrive come chiudere il contenitore."],
    conceptTags: ["adverbs of manner", "carefully", "quickly", "sequence"],
    learningPurpose: "Allena avverbi di modo, spesso trascurati ma decisivi nelle istruzioni.",
    commandGoal: "Esegui la stessa azione nel modo richiesto, non solo nell'ordine giusto.",
    methodSteps: ["verb", "adverb", "next verb"],
    glossary: [
      { term: "carefully", meaning: "con attenzione" },
      { term: "quickly", meaning: "rapidamente" },
      { term: "sample", meaning: "campione" }
    ]
  },
  {
    id: "as-as-comparison",
    title: "Confronto di stabilità",
    challengeType: "data-reading",
    minDifficulty: 6,
    scenario: "Due segnali sembrano simili, ma il protocollo chiede uguaglianza sufficiente.",
    taskPrompt: "Interpreta as stable as e dati numerici semplici.",
    instruction: "Use the backup signal only if it is as stable as the main signal.",
    dataPoints: [
      { label: "Main signal", value: "stability 82", note: "reference" },
      { label: "Backup signal", value: "stability 82", note: "same value" }
    ],
    correctLabel: "Use backup signal",
    distractors: [
      { label: "Reject backup signal", feedback: "As stable as richiede stabilità uguale: 82 e 82 soddisfano la condizione." },
      { label: "Use both and ignore main", feedback: "Only if decide se il backup è permesso, non chiede di ignorare il principale." },
      { label: "Use backup only if it is faster", feedback: "Il criterio è stable, non speed." }
    ],
    diagnosticSteps: ["As stable as indica uguaglianza di stabilità.", "Confronta i due valori.", "Only if lega l'azione alla condizione."],
    conceptTags: ["as...as", "comparison", "data reading"],
    learningPurpose: "Allena confronti di uguaglianza con dati numerici.",
    commandGoal: "Usa un backup solo quando il confronto richiesto è soddisfatto.",
    methodSteps: ["criterion", "compare", "only if"],
    glossary: [
      { term: "as stable as", meaning: "stabile quanto" },
      { term: "backup", meaning: "di riserva" },
      { term: "main", meaning: "principale" }
    ]
  },
  {
    id: "passive-simple-past",
    title: "Passivo nel registro",
    challengeType: "procedure-debug",
    minDifficulty: 6,
    scenario: "Il registro descrive cosa è stato riparato, non chi lo ha fatto.",
    taskPrompt: "Interpreta il passivo al passato e scegli il prossimo controllo.",
    instruction: "The north cable was repaired, but the east cable was not tested.",
    sourceText: "Repair log: the north cable was repaired. The east cable was not tested.",
    correctLabel: "Test the east cable",
    distractors: [
      { label: "Repair the north cable again", feedback: "Was repaired indica che il cavo nord è già stato riparato." },
      { label: "Test the north cable only", feedback: "Il problema esplicito è east cable was not tested." },
      { label: "Replace all cables", feedback: "Il log non chiede sostituzione completa: indica un controllo mancante." }
    ],
    diagnosticSteps: ["Was repaired è passivo al passato: azione già fatta.", "Was not tested indica controllo mancante.", "But introduce il contrasto utile."],
    conceptTags: ["passive past", "was/were", "not tested"],
    learningPurpose: "Allena il passivo in log tecnici semplici.",
    commandGoal: "Trasforma una frase passiva in un'azione successiva corretta.",
    methodSteps: ["was repaired", "but", "was not tested"],
    glossary: [
      { term: "was repaired", meaning: "è stato riparato" },
      { term: "was not tested", meaning: "non è stato testato" },
      { term: "east", meaning: "est" }
    ]
  },
  {
    id: "have-to-vs-can",
    title: "Obbligo o possibilità",
    challengeType: "safety",
    minDifficulty: 6,
    scenario: "Il pannello distingue ciò che è obbligatorio da ciò che è solo possibile.",
    taskPrompt: "Distingui have to, can e cannot.",
    instruction: "You have to save the sensor log before you can restart the system.",
    correctLabel: "Save log -> Restart system",
    distractors: [
      { label: "Restart system -> Save log", feedback: "Before you can restart indica che il salvataggio viene prima del riavvio." },
      { label: "Restart without saving", feedback: "Have to save indica obbligo: non è opzionale." },
      { label: "Delete the sensor log", feedback: "Save significa salvare, non cancellare." }
    ],
    diagnosticSteps: ["Have to indica obbligo.", "Before ordina le azioni.", "Can restart diventa permesso solo dopo il salvataggio."],
    conceptTags: ["have to", "can", "before", "permission"],
    learningPurpose: "Allena obbligo e possibilità in una procedura reale.",
    commandGoal: "Rispetta il prerequisito prima dell'azione finale.",
    methodSteps: ["have to", "before", "can"],
    glossary: [
      { term: "have to", meaning: "dovere / essere obbligati" },
      { term: "can", meaning: "potere" },
      { term: "restart", meaning: "riavviare" }
    ]
  },
  {
    id: "word-formation-re-over",
    title: "Prefissi tecnici",
    challengeType: "vocabulary-in-context",
    minDifficulty: 6,
    scenario: "Il terminale usa prefissi per descrivere azioni diverse: rifare, surriscaldare, scollegare.",
    taskPrompt: "Usa prefissi e contesto per scegliere l'azione corretta.",
    instruction: "The motor overheated. Do not restart it; let it cool down before rechecking the circuit.",
    correctLabel: "Cool motor -> Recheck circuit",
    distractors: [
      { label: "Restart motor immediately", feedback: "Do not restart it vieta il riavvio immediato." },
      { label: "Heat the motor more", feedback: "Overheated significa già surriscaldato: aggiungere calore peggiora il problema." },
      { label: "Disconnect every circuit", feedback: "Rechecking significa controllare di nuovo, non scollegare tutto." }
    ],
    diagnosticSteps: ["Overheated indica calore eccessivo.", "Do not restart è un divieto.", "Rechecking significa controllare di nuovo dopo il raffreddamento."],
    conceptTags: ["word formation", "over-", "re-", "technical verbs"],
    learningPurpose: "Allena prefissi frequenti in inglese tecnico e scolastico.",
    commandGoal: "Capisci l'azione correttiva senza confondere prefissi simili.",
    methodSteps: ["over-", "do not", "re-"],
    glossary: [
      { term: "overheated", meaning: "si è surriscaldato" },
      { term: "restart", meaning: "riavviare" },
      { term: "rechecking", meaning: "ricontrollare" }
    ]
  },
  {
    id: "scientific-observation-evidence",
    title: "Osservazione e prova",
    challengeType: "inference",
    minDifficulty: 7,
    scenario: "NORA chiede una conclusione basata su prove, non una supposizione.",
    taskPrompt: "Distingui observation, evidence e guess.",
    instruction: "Choose the statement supported by evidence, not the guess.",
    sourceText: "Observation: the soil is dry and the leaf tips are brown. Sensor data: water level 12%, light level normal.",
    correctLabel: "The plant probably needs water",
    distractors: [
      { label: "The plant needs less light", feedback: "Light level normal non supporta un problema di luce." },
      { label: "The soil is flooded", feedback: "Dry e water level 12% indicano poca acqua, non terreno allagato." },
      { label: "The sensor is broken for sure", feedback: "Il testo non fornisce prove di sensore guasto; sarebbe una supposizione." }
    ],
    diagnosticSteps: ["Supported by evidence chiede una conclusione basata sui dati.", "Dry soil e 12% water level puntano alla mancanza d'acqua.", "Normal light esclude la luce come causa principale."],
    conceptTags: ["evidence", "observation", "inference", "science English"],
    learningPurpose: "Allena inglese scientifico e pensiero critico: distinguere prova e supposizione.",
    commandGoal: "Formula la conclusione più giustificata dai dati disponibili.",
    methodSteps: ["observation", "data", "supported conclusion"],
    glossary: [
      { term: "evidence", meaning: "prova / evidenza" },
      { term: "guess", meaning: "ipotesi non dimostrata" },
      { term: "soil", meaning: "terreno" }
    ]
  },
  {
    id: "reported-warning",
    title: "Avviso riferito",
    challengeType: "procedure-debug",
    minDifficulty: 7,
    scenario: "Un messaggio vocale è stato trascritto in forma riferita.",
    taskPrompt: "Trasforma il reported speech in una regola operativa.",
    instruction: "NORA said that the lower hatch should stay closed until the pressure is stable.",
    sourceText: "Voice transcript: NORA said that the lower hatch should stay closed until the pressure is stable.",
    correctLabel: "Keep lower hatch closed until stable pressure",
    distractors: [
      { label: "Open lower hatch now", feedback: "Should stay closed indica che lo sportello deve restare chiuso." },
      { label: "Close upper hatch only", feedback: "Lower hatch è lo sportello inferiore; upper non compare." },
      { label: "Open hatch when pressure is unstable", feedback: "Until the pressure is stable significa aspettare la stabilità, non l'instabilità." }
    ],
    diagnosticSteps: ["Said that introduce un messaggio riferito.", "Should stay closed indica raccomandazione forte.", "Until definisce quando termina l'attesa."],
    conceptTags: ["reported speech", "should", "until", "safety"],
    learningPurpose: "Introduce il discorso indiretto in forma pratica, collegato a una regola di sicurezza.",
    commandGoal: "Recupera il comando operativo nascosto dentro la frase riferita.",
    methodSteps: ["said that", "should", "until"],
    glossary: [
      { term: "said that", meaning: "ha detto che" },
      { term: "lower hatch", meaning: "sportello inferiore" },
      { term: "stable", meaning: "stabile" }
    ]
  },
  {
    id: "either-neither-tool",
    title: "Scelta esclusa",
    challengeType: "safety",
    minDifficulty: 7,
    scenario: "Due strumenti sembrano adatti, ma il testo li esclude entrambi.",
    taskPrompt: "Interpreta neither...nor in una scelta di sicurezza.",
    instruction: "Use neither the metal probe nor the wet cloth; choose the insulated tester instead.",
    correctLabel: "Use insulated tester",
    distractors: [
      { label: "Use metal probe", feedback: "Neither...nor esclude anche la metal probe." },
      { label: "Use wet cloth", feedback: "Wet cloth è il secondo elemento escluso dal divieto." },
      { label: "Use probe and cloth together", feedback: "Neither...nor non significa usare entrambi: significa nessuno dei due." }
    ],
    diagnosticSteps: ["Neither...nor esclude due alternative.", "Instead introduce l'alternativa corretta.", "Insulated indica strumento isolato e sicuro."],
    conceptTags: ["neither/nor", "instead", "safety vocabulary"],
    learningPurpose: "Allena esclusione doppia e lessico di sicurezza.",
    commandGoal: "Scegli l'unico strumento autorizzato dopo aver scartato due distrattori plausibili.",
    methodSteps: ["neither", "nor", "instead"],
    glossary: [
      { term: "neither...nor", meaning: "né...né" },
      { term: "instead", meaning: "invece" },
      { term: "insulated", meaning: "isolato elettricamente" }
    ]
  },
  {
    id: "multi-clause-mission-order",
    title: "Ordine a più vincoli",
    challengeType: "procedure-debug",
    minDifficulty: 8,
    scenario: "La console finale accetta una procedura solo se rispetta ordine, divieto e condizione.",
    taskPrompt: "Combina before, unless e after in una sola decisione.",
    instruction: "Before opening the archive, save the log; do not open it unless the green seal is on; after opening it, scan the index.",
    sourceText: "Final console rule: before opening the archive, save the log. Do not open it unless the green seal is on. After opening it, scan the index.",
    correctLabel: "Save log -> Check green seal -> Open archive -> Scan index",
    distractors: [
      { label: "Open archive -> Save log -> Scan index", feedback: "Before opening impone che il log venga salvato prima dell'apertura." },
      { label: "Save log -> Open archive without seal", feedback: "Unless the green seal is on vieta l'apertura se il sigillo verde non è attivo." },
      { label: "Save log -> Scan index -> Open archive", feedback: "After opening it indica che la scansione dell'indice avviene dopo l'apertura." }
    ],
    diagnosticSteps: ["Before opening sposta save the log all'inizio.", "Unless crea una condizione necessaria per aprire.", "After opening it colloca scan the index alla fine."],
    conceptTags: ["before", "unless", "after", "multi-clause procedure"],
    learningPurpose: "Allena comprensione di istruzioni complesse con più subordinate.",
    commandGoal: "Costruisci una procedura coerente senza saltare prerequisiti.",
    methodSteps: ["before", "unless", "after"],
    glossary: [
      { term: "archive", meaning: "archivio" },
      { term: "seal", meaning: "sigillo" },
      { term: "index", meaning: "indice" }
    ]
  },
  {
    id: "email-register-formal",
    title: "Registro del messaggio",
    challengeType: "vocabulary-in-context",
    minDifficulty: 8,
    scenario: "Il rapporto finale va inviato a un tecnico esterno: serve registro chiaro e formale.",
    taskPrompt: "Scegli la frase più adatta a un report tecnico breve.",
    instruction: "Write a formal one-line report: the cooling fan failed, so the server stopped.",
    correctLabel: "The server stopped because the cooling fan failed.",
    distractors: [
      { label: "The server got weird because stuff broke.", feedback: "È troppo colloquiale e impreciso per un report tecnico." },
      { label: "The fan was nice and the server was sad.", feedback: "Attribuisce emozioni e non comunica causa tecnica." },
      { label: "Stop server fan cooling failed because.", feedback: "La frase non ha ordine grammaticale corretto e non è comprensibile." }
    ],
    diagnosticSteps: ["Formal richiede lessico preciso.", "Because collega causa ed effetto.", "Una riga deve essere chiara e completa."],
    conceptTags: ["formal register", "because", "technical report"],
    learningPurpose: "Allena scrittura breve in inglese con registro adeguato.",
    commandGoal: "Produrre un report leggibile, preciso e non colloquiale.",
    methodSteps: ["effect", "because", "cause"],
    glossary: [
      { term: "formal", meaning: "formale" },
      { term: "failed", meaning: "si è guastata" },
      { term: "because", meaning: "perché / poiché" }
    ]
  }
];
class EnglishInstructionGenerator {
  generate(random, difficultyLevel = 1, preferredTemplateIds = []) {
    const eligibleTemplates = englishTemplates.filter((template2) => (template2.minDifficulty ?? 1) <= difficultyLevel);
    const floor = Math.max(1, difficultyLevel - 2);
    const focusedTemplates = eligibleTemplates.filter((template2) => (template2.minDifficulty ?? 1) >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : englishTemplates;
    const preferredPool = preferredTemplateIds.length > 0 ? (eligibleTemplates.length > 0 ? eligibleTemplates : englishTemplates).filter((template2) => preferredTemplateIds.includes(template2.id)) : [];
    const template = this.specializeTemplate(random.pick(preferredPool.length > 0 ? preferredPool : pool), random.fork("english-template"), difficultyLevel);
    const choices = random.shuffle([
      {
        id: `${template.id}-correct`,
        label: template.correctLabel,
        isCorrect: true,
        feedback: template.correctFeedback ?? "Sequenza operativa corretta: verbo, oggetto e condizione sono stati interpretati senza ambiguità."
      },
      ...template.distractors.map((distractor, index) => ({
        id: `${template.id}-distractor-${index}`,
        label: distractor.label,
        isCorrect: false,
        feedback: distractor.feedback
      }))
    ]);
    return this.buildPuzzle(template, choices, difficultyLevel);
  }
  generateMinigame(random, difficultyLevel = 1, preferredTypes = []) {
    const level = Math.max(1, Math.min(8, difficultyLevel));
    const type = preferredTypes.length > 0 ? random.pick(preferredTypes) : random.pick(["action-relay", "sequence-switchboard", "data-command-scan"]);
    const minigame = this.buildMinigame(random.fork(type), level, type);
    const first = minigame.prompts[0];
    const choices = first.tiles.map((tile) => ({
      id: tile.id,
      label: tile.label,
      isCorrect: tile.isCorrect,
      feedback: tile.feedback
    }));
    return {
      id: `english-mini-${type}-${random.integer(1e3, 9999)}`,
      title: minigame.title,
      challengeType: type === "data-command-scan" ? "data-reading" : type === "sequence-switchboard" ? "sequence" : "command",
      scenario: "Training rapido del ponte operativo",
      taskPrompt: first.targetLabel,
      instruction: first.instruction,
      sourceText: first.context,
      dataPoints: first.dataPoints,
      choices,
      diagnosticSteps: [
        `Task: ${first.targetLabel}.`,
        "Find the action word, then check object, limiters and time words.",
        first.explanation
      ],
      hints: [
        "Cerca prima il verbo: press, open, take, insert, wait, choose.",
        "Poi controlla le parole che cambiano tutto: not, only, before, after, until, below, above.",
        "Se ci sono dati, confrontali con la soglia prima di scegliere l'azione."
      ],
      competencies: minigame.competencies,
      difficultyLabel: `Livello ${level} - sprint inglese operativo`,
      conceptTags: this.englishMinigameConcepts(type),
      learningPurpose: this.englishMinigamePurpose(type),
      commandGoal: "Trasformare molti micro-comandi inglesi in azioni sicure entro 60 secondi.",
      method: this.englishMinigameMethod(type),
      methodSteps: this.englishMinigameMethodSteps(type),
      glossary: first.glossary,
      minigame
    };
  }
  buildPuzzle(template, choices, difficultyLevel) {
    const conceptTags = template.conceptTags ?? this.defaultConceptTags(template.id);
    return {
      id: `english-${template.id}`,
      title: template.title ?? "Istruzione operativa esterna",
      challengeType: template.challengeType,
      scenario: template.scenario,
      taskPrompt: template.taskPrompt,
      instruction: template.instruction,
      sourceText: template.sourceText,
      dataPoints: template.dataPoints,
      choices,
      diagnosticSteps: template.diagnosticSteps,
      hints: template.hints ?? this.defaultHints(template.id),
      competencies: this.competenciesFor(template.id),
      difficultyLabel: `Livello ${Math.max(1, Math.min(8, difficultyLevel))} - ${this.levelName(difficultyLevel)}`,
      conceptTags,
      learningPurpose: template.learningPurpose ?? `Allena inglese operativo: ${conceptTags.join(", ")} in un comando da eseguire.`,
      commandGoal: template.commandGoal ?? "Trasforma l'istruzione inglese in una procedura sicura e non ambigua.",
      method: template.method ?? this.defaultMethod(template.challengeType),
      methodSteps: template.methodSteps ?? this.defaultMethodSteps(template.challengeType),
      glossary: template.glossary ?? this.defaultGlossary(template)
    };
  }
  buildMinigame(random, level, type) {
    const promptCount = 18 + level;
    const prompts = [];
    let previousSignature = "";
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniqueMinigamePrompt(random, level, type, index, previousSignature);
      prompts.push(prompt);
      previousSignature = prompt.signature;
    }
    const titles = {
      "action-relay": "Minigioco inglese: Action Relay",
      "sequence-switchboard": "Minigioco inglese: Sequence Switchboard",
      "data-command-scan": "Minigioco inglese: Data Command Scan"
    };
    const instructions = {
      "action-relay": "clicca l'azione corretta leggendo verbo, oggetto e divieto.",
      "sequence-switchboard": "clicca l'azione che rispetta before, after, then, until o unless.",
      "data-command-scan": "clicca l'azione coerente con soglia, confronto o intervallo."
    };
    return {
      type,
      title: titles[type],
      durationMs: 6e4,
      instructions: instructions[type],
      scoringRule: "60 secondi: punti per risposte corrette e serie pulite, penalità per errori e aiuti. Non basta tradurre: devi eseguire il comando giusto.",
      prompts,
      competencies: Array.from(/* @__PURE__ */ new Set([
        "inglese.istruzioni",
        "inglese.comprensione",
        "pensieroCritico",
        ...type === "action-relay" ? ["inglese.lessico"] : [],
        ...type === "sequence-switchboard" ? ["inglese.grammatica", "inglese.bilingue"] : [],
        ...type === "data-command-scan" ? ["inglese.scientifico", "inglese.dati"] : []
      ]))
    };
  }
  uniqueMinigamePrompt(random, level, type, index, previousSignature) {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const prompt = this.buildMinigamePrompt(random, level, type, index + attempt);
      if (prompt.signature !== previousSignature) {
        return prompt;
      }
    }
    return this.buildMinigamePrompt(random, level, type, index + 99);
  }
  buildMinigamePrompt(random, level, type, index) {
    if (type === "action-relay") return this.buildActionRelayPrompt(random, level, index);
    if (type === "sequence-switchboard") return this.buildSequenceSwitchboardPrompt(random, level, index);
    return this.buildDataCommandScanPrompt(random, level, index);
  }
  buildActionRelayPrompt(random, level, index) {
    const pool = [
      {
        instruction: "Press the green button. Do not press the red button.",
        correct: "Press green",
        distractors: ["Press red", "Press both", "Do nothing"],
        explanation: "Do not press the red button vieta il rosso; il comando positivo resta green.",
        glossary: [{ term: "press", meaning: "premere" }, { term: "do not", meaning: "non fare" }, { term: "green/red", meaning: "verde/rosso" }],
        concept: "imperative + prohibition"
      },
      {
        instruction: "Take the small key, not the large key.",
        correct: "Take small key",
        distractors: ["Take large key", "Take both keys", "Leave the key"],
        explanation: "Not the large key esclude la chiave grande: resta small key.",
        glossary: [{ term: "take", meaning: "prendere" }, { term: "small", meaning: "piccolo" }, { term: "large", meaning: "grande" }],
        concept: "object adjective"
      },
      {
        instruction: "Open the left drawer and keep the right drawer closed.",
        correct: "Open left drawer",
        distractors: ["Open right drawer", "Close left drawer", "Open both drawers"],
        explanation: "Left e right distinguono due oggetti; il destro deve restare chiuso.",
        glossary: [{ term: "open", meaning: "aprire" }, { term: "left/right", meaning: "sinistra/destra" }, { term: "keep closed", meaning: "tenere chiuso" }],
        concept: "spatial direction"
      },
      {
        instruction: "Insert the blue card only.",
        correct: "Insert blue card",
        distractors: ["Insert yellow card", "Insert every card", "Remove blue card"],
        explanation: "Only limita l'azione alla card blu.",
        glossary: [{ term: "insert", meaning: "inserire" }, { term: "only", meaning: "solo" }, { term: "card", meaning: "scheda" }],
        concept: "only limiter"
      }
    ];
    const advanced = [
      {
        instruction: "Replace the damaged cable, but leave the spare cable in the box.",
        correct: "Replace damaged cable",
        distractors: ["Replace spare cable", "Replace both cables", "Leave damaged cable"],
        explanation: "Damaged identifica il cavo da sostituire; spare resta nella scatola.",
        glossary: [{ term: "replace", meaning: "sostituire" }, { term: "damaged", meaning: "danneggiato" }, { term: "spare", meaning: "di ricambio" }],
        concept: "technical adjective"
      },
      {
        instruction: "Switch off neither the pump nor the sensor.",
        correct: "Keep both on",
        distractors: ["Switch off pump", "Switch off sensor", "Switch off both"],
        explanation: "Neither...nor esclude entrambe le azioni: non spegnere né pompa né sensore.",
        glossary: [{ term: "switch off", meaning: "spegnere" }, { term: "neither...nor", meaning: "né...né" }, { term: "keep on", meaning: "tenere acceso" }],
        concept: "neither/nor prohibition"
      }
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Not safe: ${item.explanation}`))
    ]);
    return {
      id: `english-action-${index}`,
      type: "action-relay",
      instruction: item.instruction,
      context: "Choose the action the Academy system can safely execute.",
      targetLabel: "Action to execute",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `action-${item.instruction}-${item.correct}`
    };
  }
  buildSequenceSwitchboardPrompt(random, level, index) {
    const pool = [
      {
        instruction: "Check the sensor before you open the valve.",
        correct: "Check sensor first",
        distractors: ["Open valve first", "Skip sensor", "Open and check together"],
        explanation: "Before indica che check the sensor viene prima di open the valve.",
        glossary: [{ term: "before", meaning: "prima di" }, { term: "check", meaning: "controllare" }, { term: "valve", meaning: "valvola" }],
        concept: "before"
      },
      {
        instruction: "Open the gate after the robot reaches the dock.",
        correct: "Robot at dock -> open gate",
        distractors: ["Open gate now", "Send robot away", "Open before robot arrives"],
        explanation: "After richiede che l'arrivo del robot sia già avvenuto.",
        glossary: [{ term: "after", meaning: "dopo che" }, { term: "reaches", meaning: "raggiunge" }, { term: "dock", meaning: "base" }],
        concept: "after"
      },
      {
        instruction: "Wait until the light turns blue, then reset the panel.",
        correct: "Blue light -> reset",
        distractors: ["Reset before blue", "Ignore the light", "Turn light red"],
        explanation: "Until impone attesa; then introduce l'azione successiva.",
        glossary: [{ term: "wait", meaning: "aspettare" }, { term: "until", meaning: "finché" }, { term: "then", meaning: "poi" }],
        concept: "until + then"
      },
      {
        instruction: "If the alarm starts, close the door immediately.",
        correct: "Alarm starts -> close door",
        distractors: ["No alarm -> close door", "Alarm starts -> open door", "Ignore alarm"],
        explanation: "If introduce la condizione che attiva l'azione.",
        glossary: [{ term: "if", meaning: "se" }, { term: "alarm", meaning: "allarme" }, { term: "immediately", meaning: "subito" }],
        concept: "first conditional"
      }
    ];
    const advanced = [
      {
        instruction: "Do not restart the core unless the backup light is green.",
        correct: "Green backup -> restart",
        distractors: ["Restart without green", "Green backup -> shut down", "Restart because light is red"],
        explanation: "Unless significa a meno che: il riavvio è permesso solo con luce verde.",
        glossary: [{ term: "unless", meaning: "a meno che" }, { term: "backup", meaning: "di riserva" }, { term: "restart", meaning: "riavviare" }],
        concept: "unless"
      },
      {
        instruction: "Not until the pressure drops should you unlock the hatch.",
        correct: "Pressure drops -> unlock hatch",
        distractors: ["Unlock before pressure drops", "Raise pressure", "Lock the hatch forever"],
        explanation: "Not until vieta di anticipare: sblocca solo dopo il calo di pressione.",
        glossary: [{ term: "not until", meaning: "non prima che" }, { term: "pressure drops", meaning: "la pressione scende" }, { term: "unlock", meaning: "sbloccare" }],
        concept: "not until"
      }
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleEnglishTiles(random, [
      this.englishTile(index, item.correct, true, `Correct: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Wrong order: ${item.explanation}`))
    ]);
    return {
      id: `english-sequence-${index}`,
      type: "sequence-switchboard",
      instruction: item.instruction,
      context: "Select the safe sequence. Time words are control levers, not decorations.",
      targetLabel: "Safe sequence",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      glossary: item.glossary,
      signature: `sequence-${item.instruction}-${item.correct}`
    };
  }
  buildDataCommandScanPrompt(random, level, index) {
    const kind = level >= 5 ? random.pick(["below", "above", "between", "compare"]) : random.pick(["below", "above", "between"]);
    if (kind === "below") {
      const threshold = random.pick([18, 20, 24, 30]);
      const pods = random.shuffle(["A", "B", "C"]);
      const low = random.integer(8, threshold - 2);
      const safeOne = random.integer(threshold + 2, threshold + 10);
      const safeTwo = random.integer(threshold + 11, threshold + 20);
      const target = pods[0];
      return this.dataPrompt(
        index,
        "data-command-scan",
        `Water the pod whose moisture is below ${threshold}. Leave the other pods unchanged.`,
        "Find the value below the threshold and act only there.",
        "Threshold decision",
        [
          { label: `Pod ${target}`, value: `${low}`, note: "below threshold" },
          { label: `Pod ${pods[1]}`, value: `${safeOne}`, note: "safe" },
          { label: `Pod ${pods[2]}`, value: `${safeTwo}`, note: "safe" }
        ].sort((a, b) => a.label.localeCompare(b.label)),
        `Water pod ${target}`,
        [`Water pod ${pods[1]}`, "Water all pods", "Do nothing"],
        `Below ${threshold} significa sotto ${threshold}: solo pod ${target} è sotto soglia.`,
        "below threshold",
        [{ term: "below", meaning: "sotto" }, { term: "whose", meaning: "il cui / la cui" }, { term: "unchanged", meaning: "senza modifiche" }]
      );
    }
    if (kind === "above") {
      const threshold = random.pick([60, 70, 75, 80]);
      const panels = random.shuffle(["North", "East", "West"]);
      const high = random.integer(threshold + 3, threshold + 15);
      const lowOne = random.integer(threshold - 22, threshold - 4);
      const lowTwo = random.integer(threshold - 35, threshold - 23);
      const target = panels[0];
      return this.dataPrompt(
        index,
        "data-command-scan",
        `Cool the panel whose heat is above ${threshold}. Do not cool the others.`,
        "Above points to the only value over the limit.",
        "Above-limit action",
        [
          { label: `${target} panel`, value: `${high}°C`, note: "above limit" },
          { label: `${panels[1]} panel`, value: `${lowOne}°C`, note: "safe" },
          { label: `${panels[2]} panel`, value: `${lowTwo}°C`, note: "safe" }
        ].sort((a, b) => a.label.localeCompare(b.label)),
        `Cool ${target}`,
        [`Cool ${panels[1]}`, "Cool every panel", "Ignore heat"],
        `Above ${threshold} significa sopra ${threshold}: intervieni solo sul pannello ${target}.`,
        "above threshold",
        [{ term: "above", meaning: "sopra" }, { term: "cool", meaning: "raffreddare" }, { term: "others", meaning: "gli altri" }]
      );
    }
    if (kind === "between") {
      const low = random.pick([16, 18, 20]);
      const high = low + random.pick([5, 6, 7]);
      const value = random.integer(low, high);
      return this.dataPrompt(
        index,
        "data-command-scan",
        `If the temperature is between ${low} and ${high}, open the vent halfway.`,
        "Between includes the values inside the interval.",
        "Interval command",
        [{ label: "Temperature", value: `${value}°C`, note: "inside range" }],
        "Open vent halfway",
        ["Keep vent closed", "Open vent fully", "Lower the temperature first"],
        `${value} è dentro l'intervallo ${low}-${high}; halfway significa a metà.`,
        "between range",
        [{ term: "between", meaning: "tra" }, { term: "halfway", meaning: "a metà" }, { term: "vent", meaning: "presa d'aria" }]
      );
    }
    const labels = random.shuffle(["A", "B"]);
    const dimmer = random.integer(25, 45);
    const brighter = random.integer(dimmer + 18, dimmer + 42);
    return this.dataPrompt(
      index,
      "data-command-scan",
      "Choose the dimmer signal and lock the brighter one.",
      "Compare the two values before acting.",
      "Comparison command",
      [
        { label: `Signal ${labels[0]}`, value: `${dimmer} lux`, note: "dimmer" },
        { label: `Signal ${labels[1]}`, value: `${brighter} lux`, note: "brighter" }
      ],
      `Choose ${labels[0]} -> lock ${labels[1]}`,
      [`Choose ${labels[1]} -> lock ${labels[0]}`, "Lock both signals", `Ignore signal ${labels[0]}`],
      "Dimmer indica il valore minore; brighter il valore maggiore.",
      "comparatives",
      [{ term: "dimmer", meaning: "meno luminoso" }, { term: "brighter", meaning: "più luminoso" }, { term: "lock", meaning: "bloccare" }]
    );
  }
  dataPrompt(index, type, instruction, context, targetLabel, dataPoints, correct, distractors, explanation, concept, glossary) {
    const tiles = this.shuffleEnglishTiles(new Random(`${instruction}:${index}`), [
      this.englishTile(index, correct, true, `Correct: ${explanation}`),
      ...distractors.map((label, choiceIndex) => this.englishTile(index + choiceIndex + 1, label, false, `Check the data: ${explanation}`))
    ]);
    return {
      id: `english-data-${index}`,
      type,
      instruction,
      context,
      targetLabel,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [correct],
      explanation,
      concept,
      glossary,
      dataPoints,
      signature: `data-${instruction}-${correct}-${dataPoints.map((point) => `${point.label}:${point.value}`).join("|")}`
    };
  }
  englishTile(seed, label, isCorrect, feedback) {
    return {
      id: `english-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
      label,
      isCorrect,
      feedback
    };
  }
  shuffleEnglishTiles(random, tiles) {
    return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
  }
  englishMinigameConcepts(type) {
    if (type === "action-relay") return ["imperative", "object choice", "prohibition"];
    if (type === "sequence-switchboard") return ["before/after", "condition", "sequence"];
    return ["data reading", "threshold", "comparison"];
  }
  englishMinigamePurpose(type) {
    if (type === "action-relay") return "Allena riconoscimento rapido di verbi operativi, oggetti, colori, direzioni e divieti.";
    if (type === "sequence-switchboard") return "Allena lettura di before, after, until, unless e if come vincoli di procedura.";
    return "Allena lettura di dati semplici in inglese: below, above, between, dimmer, brighter e soglie.";
  }
  englishMinigameMethod(type) {
    if (type === "action-relay") return "Trova verbo d'azione e oggetto, poi controlla not, only, neither e aggettivi.";
    if (type === "sequence-switchboard") return "Sottolinea le parole-tempo: before, after, until, then, unless. Poi ordina le azioni.";
    return "Leggi la soglia o il confronto, confronta i dati, poi scegli una sola azione.";
  }
  englishMinigameMethodSteps(type) {
    if (type === "action-relay") return ["verb", "object", "not/only"];
    if (type === "sequence-switchboard") return ["time word", "first event", "safe action"];
    return ["threshold", "data", "action"];
  }
  fallback(random, difficultyLevel = 1) {
    const source = random ?? new Random("english-fallback");
    const eligible = englishTemplates.filter((template2) => (template2.minDifficulty ?? 1) <= difficultyLevel);
    const template = this.specializeTemplate(source.pick(eligible.length > 0 ? eligible : englishTemplates), source.fork("template"), difficultyLevel);
    const choices = source.shuffle([
      { id: `${template.id}-correct`, label: template.correctLabel, isCorrect: true, feedback: template.correctFeedback ?? "Sequenza operativa corretta." },
      ...template.distractors.map((distractor, index) => ({
        id: `${template.id}-fallback-${index}`,
        label: distractor.label,
        isCorrect: false,
        feedback: distractor.feedback
      }))
    ]);
    return {
      ...this.buildPuzzle(template, choices, difficultyLevel),
      id: `english-fallback-${template.id}-${source.integer(1e3, 9999)}`
    };
  }
  specializeTemplate(template, random, difficultyLevel) {
    if (template.id === "sensor-below-threshold") {
      const pods = random.shuffle(["A", "B", "C"]);
      const threshold = random.pick([22, 24, 25, 28]);
      const lowValue = random.integer(12, threshold - 2);
      const safeOne = random.integer(threshold + 3, threshold + 14);
      const safeTwo = random.integer(threshold + 15, threshold + 28);
      const target = pods[0];
      const dataPoints = [
        { label: `Pod ${target}`, value: `moisture ${lowValue}`, note: "below threshold" },
        { label: `Pod ${pods[1]}`, value: `moisture ${safeOne}`, note: "safe" },
        { label: `Pod ${pods[2]}`, value: `moisture ${safeTwo}`, note: "safe" }
      ].sort((a, b) => a.label.localeCompare(b.label));
      return {
        ...template,
        instruction: `Water the pod whose moisture is below ${threshold}. Leave the other pods unchanged.`,
        dataPoints,
        correctLabel: `Water pod ${target} only`,
        distractors: [
          { label: "Water all pods", feedback: `Whose moisture is below ${threshold} limita l'azione solo alla capsula sotto soglia.` },
          { label: `Water pod ${pods[1]} only`, feedback: `Pod ${pods[1]} è sopra ${threshold}: below significa sotto la soglia, non vicino alla soglia.` },
          { label: "Do nothing", feedback: `Pod ${target} è sotto ${threshold}, quindi almeno un intervento è richiesto.` }
        ],
        diagnosticSteps: [`Below ${threshold} definisce la soglia.`, `Confronta ogni valore con ${threshold}.`, "Only evita interventi sulle capsule già stabili."]
      };
    }
    if (template.id === "compare-two-signals") {
      const labels = random.shuffle(["A", "B"]);
      const dimmerValue = random.integer(28, 48);
      const brighterValue = random.integer(dimmerValue + 15, dimmerValue + 40);
      return {
        ...template,
        dataPoints: [
          { label: `Signal ${labels[0]}`, value: `${dimmerValue} lux`, note: "dimmer" },
          { label: `Signal ${labels[1]}`, value: `${brighterValue} lux`, note: "brighter" }
        ],
        correctLabel: `Choose ${labels[0]} -> Lock ${labels[1]}`,
        distractors: [
          { label: `Choose ${labels[1]} -> Lock ${labels[0]}`, feedback: "Dimmer indica il segnale meno luminoso: viene scelto per primo." },
          { label: "Lock both signals", feedback: "Il comando distingue due azioni diverse: choose e lock non sono equivalenti." },
          { label: `Ignore signal ${labels[0]}`, feedback: `Signal ${labels[0]} è il meno luminoso nei dati, quindi è proprio quello da scegliere.` }
        ]
      };
    }
    if (template.id === "between-limits") {
      const low = random.pick([16, 18, 19]);
      const high = low + random.pick([5, 6, 7]);
      const inside = random.bool(0.72);
      const value = inside ? random.integer(low, high) : random.pick([random.integer(low - 5, low - 1), random.integer(high + 1, high + 5)]);
      const correctLabel = inside ? `${value}°C -> Vent halfway` : `${value}°C -> Keep vent closed`;
      return {
        ...template,
        instruction: `If the temperature is between ${low} and ${high} degrees, open the vent halfway; otherwise keep it closed.`,
        dataPoints: [{ label: "Temperature", value: `${value}°C`, note: inside ? "inside range" : "outside range" }],
        correctLabel,
        distractors: inside ? [
          { label: `${value}°C -> Keep vent closed`, feedback: `${value} è tra ${low} e ${high}, quindi vale la prima parte del comando.` },
          { label: `${value}°C -> Fully open vent`, feedback: "Halfway significa a metà, non completamente aperto." },
          { label: `Below ${low}°C -> Vent halfway`, feedback: `Between ${low} and ${high} esclude i valori sotto ${low}.` }
        ] : [
          { label: `${value}°C -> Vent halfway`, feedback: `${value} è fuori dall'intervallo ${low}-${high}, quindi si applica otherwise.` },
          { label: `${value}°C -> Fully open vent`, feedback: "Halfway sarebbe comunque a metà; in questo caso il comando chiede di tenere chiuso." },
          { label: `Between ${low}-${high}°C -> Keep closed`, feedback: "Dentro l'intervallo la ventola va aperta a metà, non tenuta chiusa." }
        ],
        diagnosticSteps: ["If introduce la condizione.", `Between ${low} and ${high} definisce un intervallo.`, `${value} è ${inside ? "dentro" : "fuori"} l'intervallo.`, "Otherwise vale solo fuori intervallo."]
      };
    }
    if (template.id === "cause-report" && difficultyLevel >= 6) {
      const causes = [
        { cause: "the cooling fan stopped", effect: "the archive shut down", detail: "the warning light turned purple" },
        { cause: "the backup battery failed", effect: "the door locked itself", detail: "the status icon flashed twice" },
        { cause: "the water pump jammed", effect: "the greenhouse paused irrigation", detail: "the side lamp turned orange" }
      ];
      const picked = random.pick(causes);
      return {
        ...template,
        sourceText: `Log: At 07:${random.integer(20, 58)} ${picked.detail}. ${picked.cause}, so ${picked.effect}.`,
        correctLabel: `Cause: ${picked.cause}`,
        distractors: [
          { label: "Time from the log", feedback: "Il testo dice do not report the time: l'orario è un dettaglio escluso." },
          { label: `Detail: ${picked.detail}`, feedback: "Il dettaglio visivo è nel log ma non risponde alla richiesta sulla causa." },
          { label: `Effect: ${picked.effect}`, feedback: "Questo è l'effetto da spiegare, non la causa che lo ha prodotto." }
        ]
      };
    }
    return template;
  }
  defaultConceptTags(templateId) {
    if (["green-not-red", "small-key"].includes(templateId)) return ["action verbs", "do not", "object choice"];
    if (["where-is-core", "movement-prepositions-route", "relative-where-lab"].includes(templateId)) return ["prepositions", "spatial reading", "technical nouns"];
    if (["who-can-open", "question-formation-why"].includes(templateId)) return ["question words", "can/did", "permission or cause"];
    if (["main-switch", "left-before-blue", "measure-before-switch", "after-robot-dock", "have-to-vs-can", "multi-clause-mission-order"].includes(templateId)) return ["sequence", "before/after", "procedure"];
    if (["simple-vs-now"].includes(templateId)) return ["present simple", "present continuous", "now"];
    if (["past-log-today", "past-vs-present-perfect-log"].includes(templateId)) return ["past simple", "present state", "time markers"];
    if (["present-perfect-already-yet"].includes(templateId)) return ["present perfect", "already", "yet"];
    if (["some-any-fuses", "much-many-supplies"].includes(templateId)) return ["quantity", "countable/uncountable", "prohibition"];
    if (["frequency-adverbs"].includes(templateId)) return ["frequency adverbs", "when", "cause/effect"];
    if (["going-to-scan"].includes(templateId)) return ["future plan", "going to", "after"];
    if (["pronoun-reference", "possessive-their-its"].includes(templateId)) return ["pronouns", "possessives", "reference"];
    if (["only-if-stable", "sensor-below-threshold", "first-conditional-alarm", "zero-conditional-rule"].includes(templateId)) return ["if/otherwise", "condition", "threshold"];
    if (["unless-blue-blinks", "until-door-unlocks", "reported-warning"].includes(templateId)) return ["unless/until", "exception", "waiting"];
    if (["compare-two-signals", "which-route-safest", "as-as-comparison"].includes(templateId)) return ["comparison", "adjectives", "data reading"];
    if (["relative-drawer"].includes(templateId)) return ["relative clause", "that", "technical nouns"];
    if (["may-must-not", "passive-reattach-wire", "passive-simple-past", "must-should-cable"].includes(templateId)) return ["modal verbs", "passive", "safety"];
    if (["although-however-report", "main-idea-log", "detail-not-mentioned", "scientific-observation-evidence"].includes(templateId)) return ["reading comprehension", "inference", "evidence"];
    if (["adverbs-manner-safety"].includes(templateId)) return ["adverbs of manner", "sequence", "safety"];
    if (["word-formation-re-over"].includes(templateId)) return ["word formation", "prefixes", "technical verbs"];
    if (["either-neither-tool"].includes(templateId)) return ["neither/nor", "instead", "safety"];
    if (["email-register-formal"].includes(templateId)) return ["formal register", "because", "short writing"];
    return ["operational English", "condition", "safe action"];
  }
  defaultHints(templateId) {
    if (templateId.includes("unless")) return ["Unless introduce un'eccezione: prima leggi il divieto, poi l'unico caso permesso.", "Controlla quale condizione sblocca l'azione."];
    if (templateId.includes("until")) return ["Until indica fino a quando devi aspettare.", "Non anticipare l'azione finale: cerca then."];
    return ["Cerca prima il verbo d'azione.", "Poi controlla se c'è un divieto, una condizione o un ordine temporale."];
  }
  defaultMethod(type) {
    if (type === "data-reading") return "Prima leggi la soglia o il comparativo, poi confronta i dati e scegli l'azione che soddisfa la condizione.";
    if (type === "procedure-debug") return "Confronta istruzione e log guasto: correggi ordine, oggetti e azioni senza aggiungere passaggi.";
    if (type === "inference") return "Individua la richiesta, elimina i dettagli vietati o inutili e conserva solo l'informazione necessaria.";
    if (type === "sequence") return "Sottolinea i verbi, poi usa before, after o then per ricostruire l'ordine.";
    if (type === "safety") return "Trova prima l'azione permessa, poi marca ogni oggetto dentro il divieto.";
    if (type === "vocabulary-in-context") return "Interpreta le parole tecniche dal contesto e controlla i limitatori come only, must e should not.";
    return "Individua verbo, oggetto, condizione e divieto; poi controlla l'ordine delle azioni.";
  }
  defaultMethodSteps(type) {
    if (type === "data-reading") return ["parola chiave", "dato", "decisione"];
    if (type === "procedure-debug") return ["istruzione", "log guasto", "correzione"];
    if (type === "inference") return ["richiesta", "dettagli esclusi", "risposta"];
    if (type === "sequence") return ["verbi", "connettore", "ordine"];
    if (type === "safety") return ["permesso", "divieto", "oggetto"];
    if (type === "vocabulary-in-context") return ["termine", "contesto", "azione"];
    return ["verbo", "oggetto", "vincolo"];
  }
  defaultGlossary(template) {
    const glossary = [];
    const text = template.instruction.toLowerCase();
    if (text.includes("press")) glossary.push({ term: "press", meaning: "premere" });
    if (text.includes("take")) glossary.push({ term: "take", meaning: "prendere" });
    if (text.includes("insert")) glossary.push({ term: "insert", meaning: "inserire" });
    if (text.includes("turn on")) glossary.push({ term: "turn on", meaning: "accendere / attivare" });
    if (text.includes("before")) glossary.push({ term: "before", meaning: "prima di" });
    if (text.includes("after")) glossary.push({ term: "after", meaning: "dopo che" });
    if (text.includes("if")) glossary.push({ term: "if", meaning: "se" });
    if (text.includes("otherwise")) glossary.push({ term: "otherwise", meaning: "altrimenti" });
    if (text.includes("unless")) glossary.push({ term: "unless", meaning: "a meno che / salvo se" });
    if (text.includes("until")) glossary.push({ term: "until", meaning: "finché / fino a quando" });
    if (text.includes("below")) glossary.push({ term: "below", meaning: "sotto" });
    if (text.includes("whose")) glossary.push({ term: "whose", meaning: "il cui / la cui" });
    if (text.includes("only")) glossary.push({ term: "only", meaning: "solo" });
    if (text.includes("write down")) glossary.push({ term: "write down", meaning: "annotare" });
    if (text.includes("must")) glossary.push({ term: "must", meaning: "deve / obbligo" });
    if (text.includes("have to")) glossary.push({ term: "have to", meaning: "dovere / obbligo" });
    if (text.includes("should not")) glossary.push({ term: "should not", meaning: "non dovrebbe" });
    if (text.includes("cause")) glossary.push({ term: "cause", meaning: "causa" });
    if (text.includes("dimmer")) glossary.push({ term: "dimmer", meaning: "meno luminoso" });
    if (text.includes("brighter")) glossary.push({ term: "brighter", meaning: "più luminoso" });
    if (text.includes("under")) glossary.push({ term: "under", meaning: "sotto" });
    if (text.includes("between")) glossary.push({ term: "between", meaning: "tra" });
    if (text.includes("usually")) glossary.push({ term: "usually", meaning: "di solito" });
    if (text.includes("often")) glossary.push({ term: "often", meaning: "spesso" });
    if (text.includes("rarely")) glossary.push({ term: "rarely", meaning: "raramente" });
    if (text.includes("safest")) glossary.push({ term: "safest", meaning: "il più sicuro" });
    if (text.includes("may")) glossary.push({ term: "may", meaning: "può / permesso" });
    if (text.includes("has been")) glossary.push({ term: "has been", meaning: "è stato / forma passiva" });
    if (text.includes("was repaired")) glossary.push({ term: "was repaired", meaning: "è stato riparato" });
    if (text.includes("yesterday")) glossary.push({ term: "yesterday", meaning: "ieri" });
    if (text.includes("offline")) glossary.push({ term: "offline", meaning: "non attivo" });
    if (text.includes("some")) glossary.push({ term: "some", meaning: "alcuni / un po'" });
    if (text.includes("many")) glossary.push({ term: "many", meaning: "molti, con nomi numerabili" });
    if (text.includes("little")) glossary.push({ term: "little", meaning: "poco, con nomi non numerabili" });
    if (text.includes("no spare")) glossary.push({ term: "no spare", meaning: "nessun ricambio" });
    if (text.includes("going to")) glossary.push({ term: "going to", meaning: "ha in programma di" });
    if (text.includes("them")) glossary.push({ term: "them", meaning: "li / loro" });
    if (text.includes("already")) glossary.push({ term: "already", meaning: "già" });
    if (text.includes("yet")) glossary.push({ term: "yet", meaning: "ancora / non ancora" });
    if (text.includes("although")) glossary.push({ term: "although", meaning: "sebbene / anche se" });
    if (text.includes("however")) glossary.push({ term: "however", meaning: "tuttavia" });
    if (text.includes("neither")) glossary.push({ term: "neither...nor", meaning: "né...né" });
    if (text.includes("because")) glossary.push({ term: "because", meaning: "perché / poiché" });
    if (text.includes("as stable as")) glossary.push({ term: "as...as", meaning: "tanto...quanto" });
    if (text.includes("through")) glossary.push({ term: "through", meaning: "attraverso un passaggio" });
    if (text.includes("across")) glossary.push({ term: "across", meaning: "attraverso una superficie" });
    if (text.includes("into")) glossary.push({ term: "into", meaning: "verso l'interno" });
    return glossary.slice(0, 5);
  }
  competenciesFor(templateId) {
    const base = ["inglese.istruzioni", "pensieroCritico"];
    if (["sensor-below-threshold", "compare-two-signals", "between-limits", "which-route-safest", "first-conditional-alarm", "as-as-comparison", "scientific-observation-evidence"].includes(templateId)) return [...base, "inglese.scientifico", "inglese.dati"];
    if (["where-is-core", "replace-only-damaged", "relative-drawer", "some-any-fuses", "possessive-their-its", "movement-prepositions-route", "much-many-supplies", "relative-where-lab", "word-formation-re-over", "either-neither-tool"].includes(templateId)) return [...base, "inglese.lessico"];
    if (["who-can-open", "simple-vs-now", "past-log-today", "frequency-adverbs", "going-to-scan", "pronoun-reference", "may-must-not", "passive-reattach-wire", "must-should-cable", "present-perfect-already-yet", "past-vs-present-perfect-log", "question-formation-why", "adverbs-manner-safety", "passive-simple-past", "have-to-vs-can", "reported-warning"].includes(templateId)) return [...base, "inglese.grammatica", "inglese.comprensione"];
    if (["unless-blue-blinks", "until-door-unlocks", "only-if-stable", "not-until-pressure-drops", "zero-conditional-rule", "multi-clause-mission-order"].includes(templateId)) return [...base, "inglese.bilingue", "inglese.grammatica"];
    if (["cause-report", "procedure-debug-charge", "although-however-report", "main-idea-log", "detail-not-mentioned", "email-register-formal"].includes(templateId)) return [...base, "inglese.bilingue", "inglese.comprensione"];
    return base;
  }
  levelName(level) {
    if (level <= 2) return "comandi, oggetti e spazio";
    if (level <= 4) return "tempi base, quantità e sequenze";
    if (level <= 6) return "condizioni, dati e comprensione";
    return "eccezioni, inferenze e registro";
  }
}
const languageTemplates = [
  {
    id: "single-generator",
    title: "Messaggio del generatore",
    corrupted: "Il generatori laterale sono acceso ma la luce rosse resta spente.",
    repaired: "Il generatore laterale è acceso ma la luce rossa resta spenta.",
    distractors: [
      "I generatori laterali è acceso ma la luce rossa resta spenta.",
      "Il generatore laterale sono accesi ma la luce rossa resta spenta.",
      "Il generatore laterale è acceso ma il luce rosso resta spento."
    ],
    diagnosticSteps: [
      "Il messaggio parla di un solo generatore.",
      "La luce è femminile singolare.",
      "Acceso/spenta descrivono due oggetti diversi."
    ],
    hints: [
      "Separa il gruppo del generatore dal gruppo della luce.",
      "Controlla articolo, nome, aggettivo e verbo nello stesso gruppo."
    ]
  },
  {
    id: "north-sensor",
    title: "Avviso del sensore nord",
    corrupted: "La sensori nord segnala valori instabili e richiedono una verifica.",
    repaired: "Il sensore nord segnala valori instabili e richiede una verifica.",
    distractors: [
      "I sensori nord segnala valori instabili e richiede una verifica.",
      "Il sensore nord segnalano valori instabili e richiedono una verifica.",
      "La sensore nord segnala valori instabili e richiede una verifica."
    ],
    diagnosticSteps: [
      "Il sensore è singolare maschile.",
      "I valori sono plurali, ma non sono il soggetto principale.",
      "Il secondo verbo deve riferirsi al sensore."
    ],
    hints: [
      "Non farti distrarre da 'valori': cerca chi compie l'azione.",
      "Il soggetto principale governa entrambi i verbi."
    ]
  },
  {
    id: "sealed-door",
    title: "Registro della porta",
    corrupted: "Le porta ovest è bloccati finché il codici non sono verificato.",
    repaired: "La porta ovest è bloccata finché il codice non è verificato.",
    distractors: [
      "La porta ovest sono bloccata finché il codice non è verificato.",
      "La porta ovest è bloccata finché i codice non sono verificati.",
      "Le porte ovest è bloccata finché il codice non è verificato."
    ],
    diagnosticSteps: [
      "La porta è una sola.",
      "Il codice è uno solo.",
      "Bloccata e verificato descrivono nomi diversi."
    ],
    hints: [
      "Porta e codice non hanno lo stesso genere.",
      "La frase contiene due accordi da riparare."
    ]
  },
  {
    id: "unstable-log",
    title: "Log del terminale",
    corrupted: "I registro centrale indica una anomalie, ma le sensore non conferma l'errore.",
    repaired: "Il registro centrale indica un'anomalia, ma il sensore non conferma l'errore.",
    distractors: [
      "Il registro centrale indicano un'anomalia, ma il sensore non conferma l'errore.",
      "Il registro centrale indica una anomalia, ma i sensore non conferma l'errore.",
      "I registri centrali indica un'anomalia, ma il sensore non confermano l'errore."
    ],
    diagnosticSteps: [
      "Registro centrale è singolare maschile.",
      "Anomalia inizia per vocale: il sistema accetta un'anomalia.",
      "Sensore è singolare: conferma resta singolare."
    ],
    hints: [
      "Non trasformare tutto al plurale: il log parla di un registro e un sensore.",
      "Controlla anche l'articolo davanti ad anomalia."
    ]
  },
  {
    id: "robot-report",
    title: "Rapporto robot",
    corrupted: "La robot ausiliario hanno raccolto la chiave, però non hanno aperta la uscita.",
    repaired: "Il robot ausiliario ha raccolto la chiave, però non ha aperto l'uscita.",
    distractors: [
      "Il robot ausiliario hanno raccolto la chiave, però non ha aperto l'uscita.",
      "La robot ausiliaria ha raccolto la chiave, però non ha aperto l'uscita.",
      "Il robot ausiliario ha raccolto la chiave, però non ha aperta l'uscita."
    ],
    diagnosticSteps: [
      "Robot è maschile singolare nel messaggio tecnico.",
      "I due verbi descrivono lo stesso robot: ha raccolto, non hanno raccolto.",
      "Aperto resta collegato all'azione, uscita richiede l'apostrofo."
    ],
    hints: [
      "Segui lo stesso soggetto attraverso tutta la frase.",
      "Non basta correggere il primo verbo: controlla anche la seconda azione."
    ]
  },
  {
    id: "cause-effect-cooling",
    title: "Registro causa-effetto",
    minDifficulty: 3,
    corrupted: "Il modulo scalda troppo quindi la ventola alimentata resta ferma.",
    repaired: "Il modulo scalda troppo, quindi la ventola alimentata deve partire per raffreddarlo.",
    distractors: [
      "Il modulo scalda troppo perché la ventola alimentata deve partire per raffreddarlo.",
      "Il modulo scaldano troppo, quindi la ventola alimentata deve partire per raffreddarlo.",
      "Il modulo scalda troppo, però la ventola alimentata deve partire per raffreddarlo.",
      "La ventola alimentata deve partire, quindi il modulo scalda troppo per raffreddarla."
    ],
    diagnosticSteps: [
      "Il testo descrive una causa: il modulo scalda troppo.",
      "Quindi deve introdurre la conseguenza: avviare la ventola.",
      "La ventola parte per raffreddare il modulo, non per provocarne il surriscaldamento."
    ],
    hints: [
      "Cerca prima la causa e poi la conseguenza.",
      "Se il modulo scalda, la conseguenza utile è attivare il raffreddamento.",
      "Quindi introduce l'effetto della causa descritta prima."
    ],
    conceptTags: ["causa-effetto", "connettivi", "coerenza"],
    learningPurpose: "Allena a distinguere una causa dalla sua conseguenza operativa.",
    repairGoal: "Ricostruisci una frase in cui il surriscaldamento provoca l'avvio del raffreddamento.",
    method: "Individua la causa, verifica quale azione ne consegue e controlla che quindi non inverta il rapporto logico."
  },
  {
    id: "useful-vs-noise",
    title: "Nota con dettaglio inutile",
    minDifficulty: 4,
    corrupted: "La porta e graffiata ma il blocco resta chiuso, percio il sensore magnetico non riconosce la chiave.",
    repaired: "La porta è graffiata, ma il blocco resta chiuso perché il sensore magnetico non riconosce la chiave.",
    distractors: [
      "La porta è graffiata, perciò il blocco resta chiuso perché il sensore magnetico riconosce la chiave.",
      "La porta è graffiata, ma il blocco resta chiuso perciò il sensore magnetico riconosce la chiave.",
      "La porte è graffiata, ma il blocco resta chiuso perché il sensore magnetico non riconosce la chiave.",
      "La porta è graffiata, ma il blocco resta chiusa perché il sensore magnetico non riconosce la chiave."
    ],
    diagnosticSteps: [
      "Il graffio è un dettaglio visivo: non spiega da solo il blocco.",
      "La causa utile è il sensore magnetico che non riconosce la chiave.",
      "Il connettivo deve distinguere contrasto e causa."
    ],
    hints: [
      "Non tutto quello che leggi è una causa.",
      "Ma segnala contrasto; perché segnala motivo.",
      "Il sistema vuole una frase che indichi quale informazione serve davvero."
    ]
  },
  {
    id: "pronoun-reference",
    title: "Pronome ambiguo",
    minDifficulty: 4,
    corrupted: "La batteria alimenta il sensore e lo invia dati alla porta.",
    repaired: "La batteria alimenta il sensore, che invia dati alla porta.",
    distractors: [
      "La batteria alimenta il sensore e la invia dati alla porta.",
      "La batteria alimenta il sensore, che inviano dati alla porta.",
      "La batteria alimenta il sensore e gli invia dati alla porta.",
      "La batteria alimentano il sensore, che invia dati alla porta."
    ],
    diagnosticSteps: [
      "Chi invia i dati non è la batteria, ma il sensore alimentato.",
      "Il pronome deve rendere chiaro il riferimento.",
      "Che collega il sensore alla seconda azione senza cambiare il senso tecnico."
    ],
    hints: [
      "Chiediti: chi manda i dati alla porta?",
      "La frase corretta deve togliere l'ambiguità.",
      "Non cambiare il fatto tecnico: la batteria alimenta, il sensore comunica."
    ]
  },
  {
    id: "conditional-alert",
    title: "Condizione di sicurezza",
    minDifficulty: 5,
    corrupted: "Se il LED non lampeggia chiudi il circuito finche il tester segnala corto.",
    repaired: "Se il LED non lampeggia, non chiudere il circuito finché il tester segnala corto.",
    distractors: [
      "Se il LED non lampeggia, chiudi il circuito finché il tester segnala corto.",
      "Se il LED lampeggia, non chiudere il circuito finché il tester segnala corto.",
      "Se il LED non lampeggia, non chiudere il circuito perché il tester non segnala corto.",
      "Se il LED non lampeggia, non chiudono il circuito finché il tester segnala corto."
    ],
    diagnosticSteps: [
      "La frase è un avviso: la negazione cambia completamente l'azione.",
      "Finché indica una condizione che dura nel tempo.",
      "Un corto circuito è un motivo per aspettare, non per chiudere il circuito."
    ],
    hints: [
      "Individua prima il rischio.",
      "Controlla se la frase autorizza o vieta l'azione.",
      "Una sola parola negativa può cambiare tutta la procedura."
    ]
  },
  {
    id: "technical-summary",
    title: "Sintesi tecnica",
    minDifficulty: 6,
    corrupted: "Dopo che il robot ha raccolto la chiave il terminale verifica il codice, ma la porta si apre prima.",
    repaired: "Dopo che il robot ha raccolto la chiave, il terminale verifica il codice e solo dopo la porta si apre.",
    distractors: [
      "Dopo che il robot ha raccolto la chiave, la porta si apre prima e il terminale verifica il codice.",
      "Dopo che il robot ha raccolto la chiave, il terminale verifica il codice ma la porta non si apre.",
      "Dopo che il robot hanno raccolto la chiave, il terminale verifica il codice e solo dopo la porta si apre.",
      "Dopo che il robot ha raccolto la chiave, il terminali verifica il codice e solo dopo la porta si apre."
    ],
    diagnosticSteps: [
      "Il sistema ha un ordine: chiave, verifica, apertura.",
      "Ma introdurrebbe un contrasto, mentre qui serve una sequenza coerente.",
      "Solo dopo rende esplicito che la porta non anticipa il controllo."
    ],
    hints: [
      "Ricostruisci la catena degli eventi.",
      "Scegli il connettivo che mantiene l'ordine tecnico.",
      "Non basta una frase grammaticale: deve essere eseguibile dal sistema."
    ]
  },
  {
    id: "lexical-precision",
    title: "Lessico di sistema",
    minDifficulty: 7,
    corrupted: "Il circuito consuma il segnale, quindi la resistenza deve amplificare la corrente.",
    repaired: "Il circuito disperde energia, quindi la resistenza deve limitare la corrente.",
    distractors: [
      "Il circuito disperde energia, quindi la resistenza deve amplificare la corrente.",
      "Il circuito consuma il segnale, quindi la batteria deve limitare la corrente.",
      "Il circuito disperde energia, quindi la resistenza devono limitare la corrente.",
      "Il circuito disperde energia, però la resistenza deve limitare la corrente."
    ],
    diagnosticSteps: [
      "Consuma il segnale è vago: il registro tecnico richiede disperde energia.",
      "La resistenza non amplifica: limita la corrente.",
      "La frase deve essere grammaticalmente corretta e tecnicamente precisa."
    ],
    hints: [
      "Cerca la parola più precisa, non solo quella più familiare.",
      "Un componente non va descritto con una funzione che non possiede.",
      "La soluzione migliore conserva il rapporto causa-intervento."
    ]
  },
  {
    id: "sequence-before-after",
    title: "Sequenza temporale",
    minDifficulty: 3,
    corrupted: "Prima il sensore invia il dato dopo che la porta si apre.",
    repaired: "Prima il sensore invia il dato, poi la porta si apre.",
    distractors: [
      "Prima la porta si apre, poi il sensore invia il dato.",
      "Dopo che la porta si apre, il sensore invia il dato prima.",
      "Prima il sensori invia il dato, poi la porta si apre.",
      "Il sensore invia il dato, però la porta si apre prima."
    ],
    diagnosticSteps: [
      "Il sistema deve sapere l'ordine delle azioni.",
      "Prima e poi costruiscono una sequenza, non una causa.",
      "Il sensore deve mandare il dato prima dell'apertura."
    ],
    hints: [
      "Disegna mentalmente due eventi: dato inviato e porta aperta.",
      "Non invertire l'ordine solo perché la frase suona più breve.",
      "Controlla anche l'accordo di sensore."
    ],
    conceptTags: ["ordine temporale", "connettivi", "coesione"],
    learningPurpose: "Allena la comprensione di sequenze operative e l'uso di connettivi temporali chiari.",
    repairGoal: "Ricostruisci un messaggio che dica quale evento deve accadere prima.",
    method: "Metti gli eventi in fila, scegli il connettivo temporale corretto, poi verifica che la porta non anticipi il controllo."
  },
  {
    id: "relative-clause",
    title: "Modulo con relativa",
    minDifficulty: 4,
    corrupted: "Il modulo che controllano le pompe segnala un blocco e richiedono una prova manuale.",
    repaired: "Il modulo che controlla le pompe segnala un blocco e richiede una prova manuale.",
    distractors: [
      "Il modulo che controllano le pompe segnala un blocco e richiede una prova manuale.",
      "I moduli che controlla le pompe segnalano un blocco e richiedono una prova manuale.",
      "Il modulo che controlla le pompe segnalano un blocco e richiedono una prova manuale.",
      "Le pompe che controlla il modulo segnala un blocco e richiede una prova manuale."
    ],
    diagnosticSteps: [
      "Il soggetto principale è il modulo.",
      "Che controlla le pompe descrive il modulo, non le pompe.",
      "Segnala e richiede devono restare singolari."
    ],
    hints: [
      "Trova prima il nome a cui si riferisce che.",
      "Le pompe sono oggetto della relativa: non comandano il verbo principale.",
      "Controlla entrambi i verbi della frase."
    ],
    conceptTags: ["frase relativa", "soggetto", "accordo verbale"],
    learningPurpose: "Allena il riconoscimento del soggetto anche quando la frase contiene una relativa.",
    repairGoal: "Rendi eseguibile il log mantenendo chi controlla cosa.",
    method: "Isola la frase con che, torna al soggetto principale, poi controlla i verbi collegati."
  },
  {
    id: "punctuation-safety",
    title: "Punteggiatura di sicurezza",
    minDifficulty: 5,
    corrupted: "Non aprire il vano se il LED rosso lampeggia e scollega la batteria.",
    repaired: "Non aprire il vano: se il LED rosso lampeggia, scollega la batteria.",
    distractors: [
      "Non aprire il vano se il LED rosso lampeggia e scollega la batteria.",
      "Apri il vano: se il LED rosso lampeggia, scollega la batteria.",
      "Non aprire il vano: se il LED rosso lampeggia e scollega la batteria.",
      "Non aprire il vano, perché il LED rosso lampeggia e scollega la batteria."
    ],
    diagnosticSteps: [
      "La frase contiene un divieto e una procedura di sicurezza.",
      "I due punti separano il divieto dalla condizione operativa.",
      "La virgola dopo la condizione aiuta a capire cosa fare."
    ],
    hints: [
      "Chiediti: qual è l'azione vietata e qual è l'azione richiesta?",
      "La punteggiatura può cambiare chi compie l'azione.",
      "Il LED non scollega la batteria: lo fa l'operatore."
    ],
    conceptTags: ["punteggiatura", "condizione", "sicurezza"],
    learningPurpose: "Allena l'uso della punteggiatura per evitare ambiguità nelle istruzioni.",
    repairGoal: "Scrivi un avviso che distingua chiaramente divieto, condizione e azione sicura.",
    method: "Separa divieto e procedura, poi controlla chi deve compiere l'azione."
  },
  {
    id: "source-reliability",
    title: "Fonte non verificata",
    minDifficulty: 6,
    corrupted: "Il diario dice forse la valvola è guasta quindi spegni tutto.",
    repaired: "Il diario segnala un'ipotesi: la valvola potrebbe essere guasta, quindi verifica prima di spegnere il sistema.",
    distractors: [
      "Il diario dice che la valvola è guasta, quindi spegni tutto.",
      "Il diario forse segnala la valvola guasta, però spegni tutto.",
      "Il diario segnala un'ipotesi: la valvola è sicuramente guasta, quindi spegni il sistema.",
      "Il diario segnala un'ipotesi: la valvola potrebbe essere guasta, quindi ignora il controllo."
    ],
    diagnosticSteps: [
      "Forse indica incertezza, non prova definitiva.",
      "Un'ipotesi va verificata prima di un'azione drastica.",
      "La frase corretta deve conservare prudenza e procedura."
    ],
    hints: [
      "Distingui informazione certa e informazione da verificare.",
      "Non trasformare forse in sicuramente.",
      "Il sistema deve capire che serve un controllo prima dell'arresto."
    ],
    conceptTags: ["pensiero critico", "modalità", "fonte"],
    learningPurpose: "Allena la lettura critica: una fonte incerta non autorizza subito una decisione massima.",
    repairGoal: "Rendi il messaggio prudente: conserva l'ipotesi e aggiungi la verifica necessaria.",
    method: "Valuta quanto è certa la fonte, poi scegli una frase che guidi una decisione proporzionata."
  },
  {
    id: "nominalization-precision",
    title: "Precisione del rapporto",
    minDifficulty: 7,
    corrupted: "Il robot fa il controllo del sensore e lo aggiusta.",
    repaired: "Il robot verifica il sensore e ne calibra la lettura.",
    distractors: [
      "Il robot fa il controllo del sensore e lo aggiusta.",
      "Il robot verifica il sensore e lo calibra la lettura.",
      "Il robot controlla la lettura e aggiusta il sensore senza verificarlo.",
      "Il robot verifica il sensore e calibra la porta."
    ],
    diagnosticSteps: [
      "Fa il controllo è vago: verifica è più preciso.",
      "Aggiusta è generico: calibra la lettura descrive l'intervento tecnico.",
      "Ne collega la lettura al sensore senza ripetizioni inutili."
    ],
    hints: [
      "Cerca verbi più precisi, non parole più lunghe.",
      "Chiediti quale parte viene calibrata: il sensore o la sua lettura?",
      "Il pronome ne evita ambiguità e ripetizione."
    ],
    conceptTags: ["lessico tecnico", "pronome ne", "precisione"],
    learningPurpose: "Allena lessico preciso e coesione testuale con pronomi avanzati ma utili.",
    repairGoal: "Trasforma un rapporto vago in una procedura tecnica comprensibile.",
    method: "Sostituisci parole generiche con verbi tecnici e controlla a cosa si riferisce il pronome."
  },
  {
    id: "apostrophe-accent",
    title: "Apostrofi e accenti",
    minDifficulty: 2,
    corrupted: "Ce un anomalia nell archivio, pero il sistema da ancora accesso.",
    repaired: "C'è un'anomalia nell'archivio, però il sistema dà ancora accesso.",
    distractors: [
      "Cè un anomalia nell'archivio, però il sistema da ancora accesso.",
      "C'è una anomalia nell archivio, pero il sistema dà ancora accesso.",
      "C'è un'anomalia nell'archivio, pero il sistema da ancora accesso.",
      "Ce un'anomalia nell'archivio, però il sistema dà ancora accesso."
    ],
    diagnosticSteps: [
      "C'è indica presenza e richiede apostrofo.",
      "Un'anomalia richiede apostrofo perché anomalia è femminile e inizia per vocale.",
      "Però e dà hanno accento quando servono come connettivo e verbo."
    ],
    hints: [
      "Cerca prima le parole che cambiano significato senza accento.",
      "Controlla gli incontri tra articolo e parola che inizia per vocale.",
      "Non correggere solo l'apostrofo: anche però e dà sono segnali importanti."
    ],
    conceptTags: ["ortografia", "apostrofo", "accenti"],
    learningPurpose: "Allena ortografia funzionale: accenti e apostrofi cambiano chiarezza e significato.",
    repairGoal: "Ripristina un messaggio tecnico leggibile senza cambiare l'informazione.",
    method: "Individua presenza, articolo davanti a vocale e verbi/connettivi accentati."
  },
  {
    id: "ha-a-control",
    title: "Ha oppure a",
    minDifficulty: 2,
    corrupted: "Il tecnico a collegato il cavo a massa ma non ha dato energia al modulo.",
    repaired: "Il tecnico ha collegato il cavo a massa, ma non ha dato energia al modulo.",
    distractors: [
      "Il tecnico a collegato il cavo ha massa, ma non ha dato energia al modulo.",
      "Il tecnico ha collegato il cavo ha massa, ma non a dato energia al modulo.",
      "Il tecnico ha collegato il cavo a massa ma non a dato energia al modulo.",
      "Il tecnico a collegato il cavo a massa, ma non a dato energia al modulo."
    ],
    diagnosticSteps: [
      "Ha è verbo ausiliare quando accompagna collegato o dato.",
      "A indica direzione o collegamento: a massa.",
      "La virgola prima di ma separa due informazioni in contrasto."
    ],
    hints: [
      "Prova a sostituire ha con aveva: se funziona serve l'h.",
      "A massa non è un verbo: indica dove va collegato il cavo.",
      "Il contrasto tra collegamento e assenza di energia va separato."
    ],
    conceptTags: ["ortografia", "verbo avere", "punteggiatura"],
    learningPurpose: "Allena distinzione tra preposizione e verbo, frequente nel passaggio alla scuola media.",
    repairGoal: "Rendi il log corretto distinguendo azione compiuta e collegamento.",
    method: "Controlla ogni a/ha chiedendoti se indica possesso/azione oppure direzione."
  },
  {
    id: "direct-indirect-pronouns",
    title: "Pronomi operativi",
    minDifficulty: 4,
    corrupted: "La console avvisa il robot e gli ferma prima che raggiunga la base.",
    repaired: "La console avvisa il robot e lo ferma prima che raggiunga la base.",
    distractors: [
      "La console avvisa il robot e le ferma prima che raggiunga la base.",
      "La console avvisa il robot e gli ferma prima che raggiunge la base.",
      "La console avvisa il robot e lo ferma prima che raggiungono la base.",
      "La console avvisa il robot e li ferma prima che raggiunga la base."
    ],
    diagnosticSteps: [
      "Il robot è ciò che viene fermato: serve lo, complemento oggetto.",
      "Gli significherebbe a lui, non lui.",
      "Prima che richiede raggiunga in questa istruzione."
    ],
    hints: [
      "Chiediti: la console ferma chi o dà qualcosa a qualcuno?",
      "Se la risposta è chi?, serve lo.",
      "Controlla anche il verbo dopo prima che."
    ],
    conceptTags: ["pronomi", "complemento oggetto", "subordinata"],
    learningPurpose: "Allena pronomi diretti e uso corretto del verbo in una frase complessa.",
    repairGoal: "Elimina l'ambiguità su chi viene fermato e quando.",
    method: "Trova il referente del pronome, decidi se è oggetto diretto o indiretto, poi controlla la subordinata."
  },
  {
    id: "relative-cui",
    title: "Relativa con cui",
    minDifficulty: 5,
    corrupted: "Il pannello che il codice dipende non apre la porta se manca la chiave.",
    repaired: "Il pannello da cui dipende il codice non apre la porta se manca la chiave.",
    distractors: [
      "Il pannello che dipende il codice non apre la porta se manca la chiave.",
      "Il pannello da cui dipende il codice non aprono la porta se manca la chiave.",
      "Il pannello in cui dipende il codice non apre la porta se manca la chiave.",
      "Il pannello da cui dipende il codice apre la porta se manca la chiave."
    ],
    diagnosticSteps: [
      "Dipendere richiede da: da cui dipende.",
      "Il soggetto principale è il pannello, quindi non apre resta singolare.",
      "Se manca la chiave è una condizione che impedisce l'apertura."
    ],
    hints: [
      "Cerca il verbo che regge una preposizione: dipendere da.",
      "Non cambiare il vincolo della chiave.",
      "La relativa deve spiegare il rapporto tra pannello e codice."
    ],
    conceptTags: ["frase relativa", "cui", "reggenza verbale"],
    learningPurpose: "Allena relative con preposizione, molto utili nei testi argomentativi e tecnici.",
    repairGoal: "Ricostruisci la relazione corretta tra pannello, codice e chiave.",
    method: "Trova il verbo della relativa, recupera la preposizione richiesta e controlla il verbo principale."
  },
  {
    id: "concessive-although",
    title: "Contrasto reale",
    minDifficulty: 5,
    corrupted: "Il registro è completo perché manca la firma del supervisore.",
    repaired: "Il registro è quasi completo, ma manca la firma del supervisore.",
    distractors: [
      "Il registro è completo, infatti manca la firma del supervisore.",
      "Il registro è completo perché manca la firma del supervisore.",
      "Il registro manca completo, ma la firma del supervisore è presente.",
      "Il registro è completo, quindi manca la firma del supervisore."
    ],
    diagnosticSteps: [
      "Mancare una firma non spiega che il registro è completo: crea un contrasto.",
      "Quasi completo conserva l'idea di progresso senza mentire.",
      "Ma è il connettivo adatto a segnalare l'ostacolo residuo."
    ],
    hints: [
      "Chiediti se la seconda informazione spiega o contraddice la prima.",
      "Una frase può essere grammaticalmente corretta ma logicamente falsa.",
      "Completo e manca non possono convivere senza una precisazione."
    ],
    conceptTags: ["connettivi", "coerenza", "contrasto"],
    learningPurpose: "Allena coerenza logica: causa, conseguenza e contrasto non sono intercambiabili.",
    repairGoal: "Fai capire che il sistema è vicino alla chiusura, ma non ancora completato.",
    method: "Classifica il rapporto tra le due parti: causa, conseguenza o contrasto."
  },
  {
    id: "passive-active",
    title: "Passivo tecnico",
    minDifficulty: 6,
    corrupted: "Il cavo è stato scollegato il robot durante la prova.",
    repaired: "Il cavo è stato scollegato dal robot durante la prova.",
    distractors: [
      "Il cavo ha stato scollegato dal robot durante la prova.",
      "Il robot è stato scollegato dal cavo durante la prova.",
      "Il cavo è stato scollegato al robot durante la prova.",
      "Il cavo è stato scollegati dal robot durante la prova."
    ],
    diagnosticSteps: [
      "Nel passivo chi compie l'azione è introdotto da dal.",
      "Il cavo subisce l'azione; il robot la compie.",
      "Stato scollegato concorda con cavo singolare maschile."
    ],
    hints: [
      "Chiediti chi subisce e chi agisce.",
      "Nel passivo l'agente richiede da/dal.",
      "Non invertire cavo e robot: cambieresti il fatto tecnico."
    ],
    conceptTags: ["forma passiva", "complemento d'agente", "accordo"],
    learningPurpose: "Introduce la forma passiva come strumento per leggere rapporti tecnici e storici.",
    repairGoal: "Conserva chi ha scollegato cosa, usando la struttura passiva corretta.",
    method: "Identifica paziente e agente, poi scegli la preposizione del complemento d'agente."
  },
  {
    id: "reported-speech-log",
    title: "Discorso riferito",
    minDifficulty: 6,
    corrupted: "NORA dice: controllare la pressione e che il valore deve restare sotto 40.",
    repaired: "NORA dice di controllare la pressione e che il valore deve restare sotto 40.",
    distractors: [
      "NORA dice che controllare la pressione e che il valore deve restare sotto 40.",
      "NORA dice di controllare la pressione e il valore deve resta sotto 40.",
      "NORA dice: controllare la pressione e che il valore resta sotto 40.",
      "NORA dice di controllare la pressione, ma il valore deve superare 40."
    ],
    diagnosticSteps: [
      "Dice di introduce un'azione da compiere.",
      "Dice che introduce un'informazione da verificare.",
      "Sotto 40 è un vincolo: non va trasformato in superare 40."
    ],
    hints: [
      "Ci sono due contenuti: un comando e una condizione.",
      "Non tutto ciò che segue dice si introduce allo stesso modo.",
      "Controlla che la soglia numerica resti invariata."
    ],
    conceptTags: ["discorso indiretto", "reggenza", "soglia"],
    learningPurpose: "Allena il passaggio da indicazione orale a rapporto scritto corretto.",
    repairGoal: "Rendi il messaggio di NORA eseguibile distinguendo comando e informazione.",
    method: "Separa ciò che bisogna fare da ciò che bisogna sapere."
  },
  {
    id: "main-idea-summary",
    title: "Sintesi essenziale",
    minDifficulty: 6,
    corrupted: "Il corridoio è lungo, le luci sono belle, il sensore B non risponde e la porta resta chiusa.",
    repaired: "La porta resta chiusa perché il sensore B non risponde.",
    distractors: [
      "Il corridoio è lungo e le luci sono belle.",
      "La porta resta chiusa perché il corridoio è lungo.",
      "Il sensore B non risponde, però la porta è aperta.",
      "Le luci sono belle, quindi il sensore B non risponde."
    ],
    diagnosticSteps: [
      "La consegna richiede la sintesi utile, non tutti i dettagli.",
      "Corridoio e luci sono descrizioni secondarie.",
      "La relazione operativa è sensore non risponde -> porta chiusa."
    ],
    hints: [
      "Elimina ciò che non cambia la decisione.",
      "Cerca la causa tecnica e il suo effetto.",
      "Una buona sintesi è più corta ma più precisa."
    ],
    conceptTags: ["sintesi", "informazioni utili", "causa-effetto"],
    learningPurpose: "Allena riassunto e selezione delle informazioni, competenze centrali nella scuola media.",
    repairGoal: "Trasforma un log pieno di dettagli in una frase operativa breve.",
    method: "Scarta descrizioni decorative, conserva causa ed effetto necessari."
  },
  {
    id: "thesis-evidence",
    title: "Tesi e prova",
    minDifficulty: 7,
    corrupted: "Il modulo è sicuro secondo me, infatti il tester non è stato letto.",
    repaired: "Il modulo non è ancora verificato: il tester non è stato letto.",
    distractors: [
      "Il modulo è sicuro perché il tester non è stato letto.",
      "Il modulo è sicuro secondo me, quindi il tester non serve.",
      "Il modulo non è ancora verificato, però il tester conferma tutto.",
      "Il modulo è verificato: il tester non è stato letto."
    ],
    diagnosticSteps: [
      "Secondo me è un'opinione, non una prova.",
      "Se il tester non è stato letto, la verifica manca.",
      "La frase corretta deve distinguere tesi e prova disponibile."
    ],
    hints: [
      "Chiediti quale dato dimostra davvero la conclusione.",
      "L'assenza di controllo non può provare sicurezza.",
      "La formulazione corretta deve essere prudente e verificabile."
    ],
    conceptTags: ["argomentazione", "prova", "pensiero critico"],
    learningPurpose: "Allena pensiero critico: una conclusione richiede una prova pertinente.",
    repairGoal: "Sostituisci un'opinione non dimostrata con un rapporto verificabile.",
    method: "Trova affermazione, prova e grado di certezza; se manca la prova, non concludere troppo."
  },
  {
    id: "register-formal",
    title: "Registro del rapporto",
    minDifficulty: 7,
    corrupted: "Il sensore fa casino e il tecnico lo sistema un po'.",
    repaired: "Il sensore produce dati instabili e il tecnico lo calibra.",
    distractors: [
      "Il sensore fa casino e il tecnico lo calibra.",
      "Il sensore produce dati instabili e il tecnico lo sistema un po'.",
      "Il sensore produce dati instabili e il tecnico li calibra.",
      "Il sensore produce dati stabili e il tecnico lo calibra."
    ],
    diagnosticSteps: [
      "Fa casino è colloquiale e poco preciso.",
      "Sistema un po' non descrive l'intervento.",
      "Lo si riferisce al sensore singolare, non ai dati."
    ],
    hints: [
      "Cerca un registro adatto a un rapporto tecnico.",
      "Sostituisci parole vaghe con verbi osservabili.",
      "Controlla il pronome: cosa viene calibrato?"
    ],
    conceptTags: ["registro", "lessico", "pronomi"],
    learningPurpose: "Allena il passaggio da lingua colloquiale a comunicazione precisa.",
    repairGoal: "Rendi il rapporto credibile senza appesantirlo.",
    method: "Sostituisci espressioni vaghe con parole tecniche e controlla i riferimenti."
  },
  {
    id: "period-hypothesis",
    title: "Ipotesi controllata",
    minDifficulty: 8,
    corrupted: "Se il nucleo sarebbe stabile la porta si apriva subito.",
    repaired: "Se il nucleo fosse stabile, la porta si aprirebbe subito.",
    distractors: [
      "Se il nucleo sarebbe stabile, la porta si aprirebbe subito.",
      "Se il nucleo fosse stabile, la porta si apriva subito.",
      "Se il nucleo è stabile, la porta si aprirebbe subito.",
      "Se il nucleo fosse stabile, la porta si apreva subito."
    ],
    diagnosticSteps: [
      "L'ipotesi non reale richiede fosse nella subordinata.",
      "La conseguenza richiede si aprirebbe.",
      "La virgola separa condizione e conseguenza."
    ],
    hints: [
      "La frase non descrive un fatto certo, ma una possibilità.",
      "Nel periodo ipotetico controlla entrambe le metà.",
      "Sarebbe non va nella parte introdotta da se in questa costruzione."
    ],
    conceptTags: ["periodo ipotetico", "congiuntivo", "condizionale"],
    learningPurpose: "Introduce una struttura avanzata in modo operativo: ipotesi e conseguenza.",
    repairGoal: "Formula un'ipotesi chiara sul comportamento della porta.",
    method: "Distingui condizione e conseguenza, poi usa congiuntivo e condizionale in coppia."
  },
  {
    id: "implicit-subject",
    title: "Soggetto sottinteso",
    minDifficulty: 8,
    corrupted: "Dopo aver letto il log, il guasto è stato riparato dal robot.",
    repaired: "Dopo aver letto il log, il robot ha riparato il guasto.",
    distractors: [
      "Dopo aver letto il log, il guasto ha riparato il robot.",
      "Dopo avere letto il log, il guasto è stato riparato.",
      "Dopo aver letto il robot, il log ha riparato il guasto.",
      "Dopo aver letto il log, il robot è stato riparato dal guasto."
    ],
    diagnosticSteps: [
      "Chi legge il log deve essere lo stesso soggetto dell'azione principale.",
      "Il guasto non può leggere il log.",
      "La forma attiva elimina l'ambiguità del soggetto sottinteso."
    ],
    hints: [
      "Chiediti chi ha letto il log.",
      "Una subordinata implicita eredita il soggetto della principale.",
      "Se il soggetto sembra impossibile, riscrivi la frase."
    ],
    conceptTags: ["subordinata implicita", "soggetto", "chiarezza"],
    learningPurpose: "Allena controllo della frase complessa e prevenzione di ambiguità sintattiche.",
    repairGoal: "Rendi chiaro chi legge, chi agisce e cosa viene riparato.",
    method: "Collega il soggetto sottinteso alla frase principale; se non coincide, riscrivi."
  }
];
class LanguageCorruptionGenerator {
  generate(random, difficultyLevel = 1, preferredTemplateIds = []) {
    const eligibleTemplates = languageTemplates.filter((template2) => (template2.minDifficulty ?? 1) <= difficultyLevel);
    const floor = Math.max(1, difficultyLevel - 2);
    const focusedTemplates = eligibleTemplates.filter((template2) => (template2.minDifficulty ?? 1) >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates;
    const preferredPool = preferredTemplateIds.length > 0 ? (eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates).filter((template2) => preferredTemplateIds.includes(template2.id)) : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const options = random.shuffle([template.repaired, ...template.distractors]);
    return this.buildPuzzle(template, options, difficultyLevel);
  }
  generateMinigame(random, difficultyLevel = 1, preferredTypes = []) {
    const level = Math.max(1, Math.min(8, difficultyLevel));
    const type = preferredTypes.length > 0 ? random.pick(preferredTypes) : random.pick(["agreement-sprint", "connector-route", "intruder-hunt"]);
    const minigame = this.buildMinigame(random.fork(type), level, type);
    const first = minigame.prompts[0];
    const options = first.tiles.map((tile) => tile.label);
    const optionFeedback = {};
    first.tiles.forEach((tile) => {
      optionFeedback[tile.label] = tile.feedback;
    });
    return {
      id: `language-mini-${type}-${random.integer(1e3, 9999)}`,
      title: minigame.title,
      corrupted: first.context,
      repaired: first.solutionLabels[0],
      options,
      diagnosticSteps: [
        `Leggi il compito: ${first.targetLabel}.`,
        "Non scegliere la frase che suona meglio: controlla la regola linguistica richiesta.",
        first.explanation
      ],
      hints: [
        "Prima individua il soggetto o il nesso logico, poi guarda le opzioni.",
        "Scarta i distrattori che cambiano significato, genere, numero o rapporto causa-effetto.",
        "Se due risposte sembrano possibili, rileggi l'obiettivo operativo della console."
      ],
      competencies: minigame.competencies,
      difficultyLabel: `Livello ${level} - sprint linguistico`,
      conceptTags: this.languageMinigameConcepts(type),
      learningPurpose: this.languageMinigamePurpose(type),
      repairGoal: "Stabilizzare molti micro-messaggi in 60 secondi senza provare a caso.",
      method: this.languageMinigameMethod(type),
      optionFeedback,
      minigame
    };
  }
  buildPuzzle(template, options, difficultyLevel) {
    const conceptTags = template.conceptTags ?? this.defaultConceptTags(template.id);
    const optionFeedback = this.buildOptionFeedback(template);
    return {
      id: `language-${template.id}`,
      title: template.title,
      corrupted: template.corrupted,
      repaired: template.repaired,
      options,
      diagnosticSteps: template.diagnosticSteps,
      hints: template.hints,
      competencies: this.competenciesFor(template.id),
      difficultyLabel: `Livello ${Math.max(1, Math.min(8, difficultyLevel))} - ${this.levelName(difficultyLevel)}`,
      conceptTags,
      learningPurpose: template.learningPurpose ?? `Allena ${conceptTags.join(", ")} dentro un messaggio tecnico da rendere eseguibile.`,
      repairGoal: template.repairGoal ?? "Trasforma il log corrotto in una frase chiara, corretta e utile al sistema.",
      method: template.method ?? "Trova soggetto e azione, controlla accordi e connettivi, poi verifica che il significato tecnico non cambi.",
      optionFeedback
    };
  }
  fallback(random, difficultyLevel = 1) {
    const eligible = languageTemplates.filter((template2) => (template2.minDifficulty ?? 1) <= difficultyLevel);
    const template = (random == null ? void 0 : random.pick(eligible.length > 0 ? eligible : languageTemplates)) ?? languageTemplates[0];
    const options = (random == null ? void 0 : random.shuffle([template.repaired, ...template.distractors])) ?? [template.repaired, ...template.distractors];
    return {
      ...this.buildPuzzle(template, options, difficultyLevel),
      id: `language-fallback-${template.id}-${(random == null ? void 0 : random.integer(1e3, 9999)) ?? 0}`
    };
  }
  buildMinigame(random, level, type) {
    const promptCount = 18 + level;
    const prompts = [];
    let previousSignature = "";
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniqueMinigamePrompt(random, level, type, index, previousSignature);
      prompts.push(prompt);
      previousSignature = prompt.signature;
    }
    const titles = {
      "agreement-sprint": "Minigioco italiano: Concordanze lampo",
      "connector-route": "Minigioco italiano: Rotte dei connettivi",
      "intruder-hunt": "Minigioco italiano: Intruso nel log"
    };
    const instructions = {
      "agreement-sprint": "clicca la forma che rende la frase corretta per genere, numero e verbo.",
      "connector-route": "clicca il connettivo che mantiene il rapporto logico tra le informazioni.",
      "intruder-hunt": "clicca il dettaglio inutile o contraddittorio rispetto allo scopo del log."
    };
    return {
      type,
      title: titles[type],
      durationMs: 6e4,
      instructions: instructions[type],
      scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. La velocità vale solo se resta precisa.",
      prompts,
      competencies: Array.from(/* @__PURE__ */ new Set([
        "italiano.comprensione",
        "italiano.grammatica",
        "pensieroCritico",
        ...type === "agreement-sprint" ? ["italiano.coesione"] : [],
        ...type === "connector-route" ? ["italiano.coesione", "italiano.argomentazione"] : [],
        ...type === "intruder-hunt" ? ["italiano.lessico", "italiano.scritturaBreve"] : []
      ]))
    };
  }
  uniqueMinigamePrompt(random, level, type, index, previousSignature) {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const prompt = this.buildMinigamePrompt(random, level, type, index + attempt);
      if (prompt.signature !== previousSignature) {
        return prompt;
      }
    }
    return this.buildMinigamePrompt(random, level, type, index + 99);
  }
  buildMinigamePrompt(random, level, type, index) {
    if (type === "agreement-sprint") return this.buildAgreementPrompt(random, level, index);
    if (type === "connector-route") return this.buildConnectorPrompt(random, level, index);
    return this.buildIntruderPrompt(random, level, index);
  }
  buildAgreementPrompt(random, level, index) {
    const pool = [
      {
        context: "I sensori della serra ___ prima dell'apertura.",
        correct: "sono calibrati",
        distractors: ["è calibrato", "sono calibrato", "è calibrati"],
        explanation: "Il soggetto è plurale maschile: i sensori sono calibrati.",
        concept: "accordo soggetto-verbo-aggettivo"
      },
      {
        context: "La valvola e il filtro ___ lo stesso registro.",
        correct: "condividono",
        distractors: ["condivide", "condivisa", "condividono stato"],
        explanation: "Due elementi formano un soggetto plurale: condividono.",
        concept: "soggetto composto"
      },
      {
        context: "L'energia residua non ___ abbastanza stabile.",
        correct: "è",
        distractors: ["sono", "ha", "anno"],
        explanation: "Energia è singolare: è stabile. Ha/anno cambiano funzione o ortografia.",
        concept: "verbo essere e omofoni"
      },
      {
        context: "Le istruzioni, se lette in ordine, ___ il percorso.",
        correct: "chiariscono",
        distractors: ["chiarisce", "chiarito", "chiariscono la"],
        explanation: "Il soggetto grammaticale è le istruzioni: terza plurale.",
        concept: "inciso tra soggetto e verbo"
      },
      {
        context: "Il dato che manca nei registri ___ la diagnosi incompleta.",
        correct: "rende",
        distractors: ["rendono", "renda", "rendono la"],
        explanation: "Il nucleo del soggetto è dato, non registri: il dato rende.",
        concept: "soggetto con relativa"
      },
      {
        context: "Nessuna delle porte laterali ___ ancora autorizzata.",
        correct: "è",
        distractors: ["sono", "hanno", "vengono"],
        explanation: "Nessuna è singolare: nessuna porta è autorizzata.",
        concept: "quantificatori singolari"
      },
      {
        context: "Il registro e la mappa ___ nella stessa cartella.",
        correct: "sono salvati",
        distractors: ["è salvato", "sono salvato", "è salvati"],
        explanation: "Registro e mappa formano un soggetto plurale: sono salvati.",
        concept: "accordo con soggetto composto"
      },
      {
        context: "Questa serie di avvisi ___ un controllo immediato.",
        correct: "richiede",
        distractors: ["richiedono", "richiesta", "richieda"],
        explanation: "Il nucleo del soggetto è serie, singolare: questa serie richiede.",
        concept: "nucleo del soggetto"
      }
    ];
    const advanced = [
      {
        context: "Il gruppo di segnali che arrivano dal nucleo ___ un'anomalia.",
        correct: "indica",
        distractors: ["indicano", "indichi", "indicate"],
        explanation: "Il soggetto è il gruppo, singolare; che arrivano è una relativa interna.",
        concept: "nucleo del soggetto"
      },
      {
        context: "Se la pressione e la temperatura non ___, il log resta in attesa.",
        correct: "coincidono",
        distractors: ["coincide", "coincisa", "coincidono il"],
        explanation: "Pressione e temperatura sono due elementi: coincidono.",
        concept: "accordo in subordinata condizionale"
      },
      {
        context: "La maggior parte dei moduli ___ pronta, ma alcuni sensori restano isolati.",
        correct: "è",
        distractors: ["sono", "hanno", "vengono"],
        explanation: "La maggior parte è un'espressione singolare: è pronta.",
        concept: "accordo con nome collettivo"
      }
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Non regge: ${item.explanation}`))
    ]);
    return {
      id: `agreement-${index}`,
      type: "agreement-sprint",
      prompt: "Completa il log con la forma grammaticale che il sistema può eseguire.",
      context: item.context,
      targetLabel: "Concordanza corretta",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `agreement-${item.context}-${item.correct}`
    };
  }
  buildConnectorPrompt(random, level, index) {
    const pool = [
      {
        context: "Il tester segnala corto, ___ il pannello blocca l'accensione.",
        correct: "quindi",
        distractors: ["però", "mentre", "sebbene"],
        explanation: "Il secondo fatto è una conseguenza del primo: quindi.",
        concept: "causa-conseguenza"
      },
      {
        context: "Il LED è orientato bene, ___ resta spento perché manca la resistenza.",
        correct: "ma",
        distractors: ["infatti", "dunque", "quando"],
        explanation: "C'è un contrasto tra una parte corretta e il problema ancora presente.",
        concept: "contrasto"
      },
      {
        context: "Controlla il registro ___ aprire la porta.",
        correct: "prima di",
        distractors: ["dopo che", "nonostante", "perciò"],
        explanation: "Serve un vincolo temporale: il controllo avviene prima dell'apertura.",
        concept: "ordine temporale"
      },
      {
        context: "La console accetta il comando ___ il sensore conferma stabilità.",
        correct: "solo se",
        distractors: ["anche se", "mentre", "quindi"],
        explanation: "Solo se introduce una condizione necessaria.",
        concept: "condizione necessaria"
      },
      {
        context: "Il log cita molte luci decorative, ___ una sola indica il guasto.",
        correct: "tuttavia",
        distractors: ["perciò", "affinché", "poiché"],
        explanation: "Tuttavia segnala contrasto tra molti dettagli e il dato utile.",
        concept: "opposizione argomentativa"
      },
      {
        context: "La porta resta bloccata ___ il codice inserito non coincide con il registro.",
        correct: "perché",
        distractors: ["quindi", "mentre", "sebbene"],
        explanation: "Perché introduce la causa del blocco.",
        concept: "causa esplicita"
      },
      {
        context: "Il robot invia il segnale, ___ il nucleo registra l'arrivo.",
        correct: "poi",
        distractors: ["benché", "affinché", "perciò"],
        explanation: "Poi mantiene l'ordine temporale: prima il segnale, dopo la registrazione.",
        concept: "sequenza temporale"
      }
    ];
    const advanced = [
      {
        context: "Il robot non deve partire ___ la base non ha confermato la rotta.",
        correct: "finché",
        distractors: ["affinché", "poiché", "benché"],
        explanation: "Finché indica il limite temporale negativo: non partire fino alla conferma.",
        concept: "limite temporale"
      },
      {
        context: "Annota la fonte ___ il rapporto sia verificabile.",
        correct: "affinché",
        distractors: ["benché", "invece", "dunque"],
        explanation: "Affinché introduce lo scopo: rendere il rapporto verificabile.",
        concept: "finalità"
      },
      {
        context: "Il pannello non si riavvia ___ il tecnico non isola il corto.",
        correct: "finché",
        distractors: ["affinché", "inoltre", "tuttavia"],
        explanation: "Finché indica una condizione temporale: non avviene prima dell'isolamento.",
        concept: "vincolo temporale"
      }
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      this.languageTile(index, item.correct, true, `Corretto: ${item.explanation}`),
      ...item.distractors.map((label, choiceIndex) => this.languageTile(index + choiceIndex + 1, label, false, `Connettivo non coerente: ${item.explanation}`))
    ]);
    return {
      id: `connector-${index}`,
      type: "connector-route",
      prompt: "Scegli il connettivo che mantiene il rapporto logico tra le due parti.",
      context: item.context,
      targetLabel: "Nesso logico",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.correct],
      explanation: item.explanation,
      concept: item.concept,
      signature: `connector-${item.context}-${item.correct}`
    };
  }
  buildIntruderPrompt(random, level, index) {
    const pool = [
      {
        context: "Obiettivo: capire perché la porta resta chiusa.",
        useful: ["la serratura non riceve corrente", "il codice è stato accettato", "il circuito è ancora aperto"],
        intruder: "la cornice della porta è blu",
        explanation: "Il colore della cornice non spiega il blocco della porta.",
        concept: "informazioni utili e rumore"
      },
      {
        context: "Obiettivo: scrivere un rapporto sulle cause del guasto.",
        useful: ["il sensore B non risponde", "il log indica soglia superata", "la valvola si apre in ritardo"],
        intruder: "il banco degli attrezzi è vicino alla finestra",
        explanation: "La posizione del banco non è una causa del guasto.",
        concept: "causa e dettaglio irrilevante"
      },
      {
        context: "Obiettivo: ricostruire l'ordine degli eventi.",
        useful: ["prima il robot entra in base", "poi la valvola si apre", "infine il registro viene salvato"],
        intruder: "il robot ha una scocca verde",
        explanation: "Il colore del robot non aiuta a ricostruire la sequenza.",
        concept: "sequenza temporale"
      },
      {
        context: "Obiettivo: verificare se una fonte è affidabile.",
        useful: ["il dato è registrato dal tester", "la misura compare due volte", "l'orario del log è coerente"],
        intruder: "il messaggio usa un font elegante",
        explanation: "La grafica del font non dimostra affidabilità della fonte.",
        concept: "fonte e prova"
      },
      {
        context: "Obiettivo: capire quale istruzione eseguire subito.",
        useful: ["il comando dice prima controlla la valvola", "il timer scade tra un minuto", "il pannello segnala rischio basso"],
        intruder: "la valvola è disegnata con un'icona grande",
        explanation: "La dimensione dell'icona non decide quale azione eseguire.",
        concept: "priorità operativa"
      },
      {
        context: "Obiettivo: riscrivere un log chiaro per un compagno.",
        useful: ["indica il componente guasto", "spiega l'effetto osservato", "propone il prossimo controllo"],
        intruder: "usa tre aggettivi decorativi sulla stanza",
        explanation: "Gli aggettivi decorativi non aiutano un compagno a riparare il sistema.",
        concept: "chiarezza comunicativa"
      }
    ];
    const advanced = [
      {
        context: "Obiettivo: distinguere tesi e prova nel rapporto.",
        useful: ["tesi: il blocco dipende dal sensore", "prova: il tester non legge continuità", "prova: la soglia resta fuori range"],
        intruder: "opinione: il sensore sembra antipatico",
        explanation: "Un'opinione non verificabile non è una prova.",
        concept: "tesi, prova, opinione"
      },
      {
        context: "Obiettivo: preparare una sintesi breve e precisa.",
        useful: ["causa principale: corto sul ramo B", "effetto: porta non certificata", "azione: isolare il corto"],
        intruder: "descrizione lunga delle luci del corridoio",
        explanation: "Una sintesi elimina dettagli decorativi che non cambiano causa, effetto o azione.",
        concept: "sintesi e pertinenza"
      }
    ];
    const item = random.pick(level >= 5 ? [...pool, ...advanced] : pool);
    const tiles = this.shuffleLanguageTiles(random, [
      ...item.useful.map((label, choiceIndex) => this.languageTile(index + choiceIndex, label, false, "Dato utile: non eliminarlo, serve allo scopo del log.")),
      this.languageTile(index + 9, item.intruder, true, `Intruso corretto: ${item.explanation}`)
    ]);
    return {
      id: `intruder-${index}`,
      type: "intruder-hunt",
      prompt: "Clicca il dettaglio da eliminare: è inutile o non verificabile per l'obiettivo.",
      context: item.context,
      targetLabel: "Intruso testuale",
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [item.intruder],
      explanation: item.explanation,
      concept: item.concept,
      signature: `intruder-${item.context}-${item.intruder}`
    };
  }
  languageTile(seed, label, isCorrect, feedback) {
    return {
      id: `lang-tile-${seed}-${label.replace(/\W+/g, "-").toLowerCase()}`,
      label,
      isCorrect,
      feedback
    };
  }
  shuffleLanguageTiles(random, tiles) {
    return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
  }
  languageMinigameConcepts(type) {
    if (type === "agreement-sprint") return ["accordo", "soggetto", "concordanza"];
    if (type === "connector-route") return ["connettivi", "logica del testo", "coesione"];
    return ["comprensione", "informazioni utili", "pensiero critico"];
  }
  languageMinigamePurpose(type) {
    if (type === "agreement-sprint") return "Allena riconoscimento rapido di accordi, soggetti reali e forme verbali corrette.";
    if (type === "connector-route") return "Allena scelta dei connettivi in base a causa, contrasto, tempo, condizione e scopo.";
    return "Allena lettura selettiva: separare dati utili, prove, opinioni e dettagli decorativi.";
  }
  languageMinigameMethod(type) {
    if (type === "agreement-sprint") return "Trova il soggetto, controlla singolare/plurale e verifica che verbo e aggettivo concordino.";
    if (type === "connector-route") return "Nomina il rapporto tra le due frasi: causa, conseguenza, contrasto, tempo, condizione o scopo.";
    return "Rileggi l'obiettivo del log e tieni solo ciò che aiuta a rispondere a quell'obiettivo.";
  }
  buildOptionFeedback(template) {
    const feedback = {};
    template.distractors.forEach((option, index) => {
      var _a2;
      feedback[option] = ((_a2 = template.distractorFeedback) == null ? void 0 : _a2[option]) ?? `Questa versione sembra plausibile, ma non supera il controllo ${index + 1}: ${template.diagnosticSteps[index % template.diagnosticSteps.length]} ${template.hints[index % template.hints.length]}`;
    });
    feedback[template.repaired] = "Riparazione coerente: grammatica, significato tecnico e ordine operativo restano allineati.";
    return feedback;
  }
  defaultConceptTags(templateId) {
    if (["single-generator", "north-sensor", "sealed-door", "unstable-log", "robot-report"].includes(templateId)) {
      return ["accordo", "soggetto", "coesione"];
    }
    if (["apostrophe-accent", "ha-a-control"].includes(templateId)) {
      return ["ortografia", "accenti", "apostrofi"];
    }
    if (["cause-effect-cooling", "useful-vs-noise"].includes(templateId)) {
      return ["causa-effetto", "connettivi", "informazioni utili"];
    }
    if (["pronoun-reference", "direct-indirect-pronouns"].includes(templateId)) {
      return ["pronomi", "riferimenti", "ambiguita"];
    }
    if (["relative-clause", "relative-cui"].includes(templateId)) {
      return ["frase relativa", "soggetto", "reggenza"];
    }
    if (templateId === "conditional-alert") {
      return ["negazione", "condizione", "sicurezza"];
    }
    if (["technical-summary", "sequence-before-after"].includes(templateId)) {
      return ["ordine logico", "sequenza", "coesione"];
    }
    if (["punctuation-safety"].includes(templateId)) {
      return ["punteggiatura", "condizione", "chiarezza"];
    }
    if (["source-reliability", "thesis-evidence"].includes(templateId)) {
      return ["pensiero critico", "tesi e prova", "fonte"];
    }
    if (["lexical-precision", "nominalization-precision", "register-formal"].includes(templateId)) {
      return ["lessico tecnico", "precisione", "significato"];
    }
    if (["passive-active"].includes(templateId)) {
      return ["forma passiva", "agente", "accordo"];
    }
    if (["reported-speech-log"].includes(templateId)) {
      return ["discorso indiretto", "reggenza", "soglia"];
    }
    if (["main-idea-summary"].includes(templateId)) {
      return ["sintesi", "informazioni utili", "causa-effetto"];
    }
    if (["period-hypothesis"].includes(templateId)) {
      return ["periodo ipotetico", "congiuntivo", "condizionale"];
    }
    if (["implicit-subject"].includes(templateId)) {
      return ["subordinata implicita", "soggetto", "chiarezza"];
    }
    return ["comprensione", "grammatica", "coerenza"];
  }
  competenciesFor(templateId) {
    const base = ["italiano.comprensione", "italiano.grammatica", "pensieroCritico"];
    if (["lexical-precision", "nominalization-precision", "register-formal", "useful-vs-noise"].includes(templateId)) {
      return [...base, "italiano.lessico"];
    }
    if (["main-idea-summary", "technical-summary", "source-reliability", "thesis-evidence"].includes(templateId)) {
      return [...base, "italiano.scritturaBreve", "italiano.argomentazione"];
    }
    if (["punctuation-safety", "apostrophe-accent", "ha-a-control"].includes(templateId)) {
      return [...base, "italiano.punteggiatura"];
    }
    if (["pronoun-reference", "direct-indirect-pronouns", "relative-clause", "relative-cui", "implicit-subject"].includes(templateId)) {
      return [...base, "italiano.coesione"];
    }
    return base;
  }
  levelName(level) {
    if (level <= 2) return "ortografia e accordi fondamentali";
    if (level <= 4) return "connettivi, pronomi e coerenza";
    if (level <= 6) return "frasi complesse e sintesi";
    return "argomentazione, registro e precisione";
  }
}
const mathTemplates = [
  {
    id: "double-add-subtract",
    title: "Serratura a energia",
    narrative: "Il terminale misura un nucleo che va amplificato e poi raffreddato.",
    minComplexity: 1,
    archetype: "calcolo-diretto",
    build: (a, b, c) => ({
      prompt: `Il codice è il doppio di ${a}, più ${b}, meno ${c}.`,
      answer: a * 2 + b - c,
      hints: [
        `Prima raddoppia ${a}.`,
        `Aggiungi ${b} al risultato del raddoppio.`,
        `Solo alla fine sottrai ${c}.`
      ],
      steps: [`${a} x 2 = ${a * 2}`, `${a * 2} + ${b} = ${a * 2 + b}`, `${a * 2 + b} - ${c} = ${a * 2 + b - c}`]
    })
  },
  {
    id: "triple-minus-half",
    title: "Bilanciatore di carica",
    narrative: "La carica va triplicata, poi divisa in due camere solo dopo il raffreddamento.",
    minComplexity: 2,
    archetype: "calcolo-diretto",
    build: (a, b, c) => {
      const base = a * 3 - b;
      const adjusted = base % 2 === 0 ? base : base + 1;
      return {
        prompt: `Triplica ${a}, togli ${b}, poi usa metà del valore stabilizzato.`,
        answer: adjusted / 2,
        hints: [
          `Triplica ${a}: ottieni ${a * 3}.`,
          `Sottrai ${b}; se il valore non è pari, il terminale lo stabilizza al pari successivo.`,
          "La camera finale usa metà del valore stabilizzato."
        ],
        steps: [`${a} x 3 = ${a * 3}`, `${a * 3} - ${b} = ${base}`, `valore stabilizzato = ${adjusted}`, `${adjusted} / 2 = ${adjusted / 2}`]
      };
    }
  },
  {
    id: "multiply-add-divide",
    title: "Codice del compressore",
    narrative: "Il compressore accetta solo risultati divisibili senza resto.",
    minComplexity: 3,
    archetype: "vincolo",
    build: (a, b, c) => {
      const dividend = a * b + c;
      const divisor = c % 2 === 0 ? 2 : 3;
      const correctedDividend = dividend + (divisor - dividend % divisor) % divisor;
      return {
        prompt: `Moltiplica ${a} per ${b}, aggiungi ${c}, poi dividi il valore stabilizzato per ${divisor}.`,
        answer: correctedDividend / divisor,
        hints: [
          `Prima calcola ${a} x ${b}.`,
          `Poi aggiungi ${c}; il terminale stabilizza al primo valore divisibile per ${divisor}.`,
          `Dividi per ${divisor} solo alla fine.`
        ],
        steps: [`${a} x ${b} = ${a * b}`, `${a * b} + ${c} = ${dividend}`, `stabilizzazione a ${correctedDividend}`, `${correctedDividend} / ${divisor} = ${correctedDividend / divisor}`]
      };
    }
  },
  {
    id: "reverse-output-lock",
    title: "Inversore di uscita",
    narrative: "La macchina mostra il valore finale, ma l'ingresso è stato cancellato dal log.",
    minComplexity: 4,
    archetype: "ragionamento-inverso",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(5, c));
      const target = (a + b) * multiplier;
      return {
        prompt: `Un valore sconosciuto entra, riceve +${b}, poi viene moltiplicato per ${multiplier}. L'uscita è ${target}. Qual era il valore iniziale?`,
        answer: a,
        hints: [
          `Lavora al contrario: prima annulla la moltiplicazione per ${multiplier}.`,
          `${target} / ${multiplier} = ${target / multiplier}.`,
          `Se prima era stato aggiunto ${b}, ora devi toglierlo.`
        ],
        steps: [`${target} / ${multiplier} = ${target / multiplier}`, `${target / multiplier} - ${b} = ${a}`]
      };
    }
  },
  {
    id: "sequence-signal",
    title: "Sequenza del segnale",
    narrative: "Tre impulsi rivelano la regola del trasmettitore, il quarto apre il vano.",
    minComplexity: 4,
    archetype: "sequenza",
    build: (a, b, c) => {
      const step = Math.max(3, b);
      const first = a;
      const second = first + step;
      const third = second + step + c;
      const fourth = third + step + c * 2;
      return {
        prompt: `Impulsi registrati: ${first}, ${second}, ${third}, ?. Ogni salto aumenta di ${c}. Quale numero completa il quarto impulso?`,
        answer: fourth,
        hints: [
          `Il primo salto è ${second - first}.`,
          `Il secondo salto è ${third - second}: confrontalo con il primo.`,
          `Il terzo salto aumenta ancora di ${c}.`
        ],
        steps: [`salto 1 = ${second - first}`, `salto 2 = ${third - second}`, `salto 3 = ${fourth - third}`, `${third} + ${fourth - third} = ${fourth}`]
      };
    }
  },
  {
    id: "divisibility-valve",
    title: "Valvola dei Vincoli",
    narrative: "La valvola non vuole il numero più grande: vuole il primo numero che rispetta due regole.",
    minComplexity: 5,
    archetype: "vincolo",
    build: (a, b, c) => {
      const divisor = c % 2 === 0 ? 3 : 4;
      const threshold = a + b;
      let candidate = threshold + 1;
      while (candidate % 2 !== 0 || candidate % divisor !== 0) candidate += 1;
      return {
        prompt: `Trova il più piccolo numero maggiore di ${threshold} che sia pari e divisibile per ${divisor}.`,
        answer: candidate,
        hints: [
          "Deve superare la soglia, quindi non provare numeri più piccoli.",
          "Deve essere pari: scarta tutti i dispari.",
          `Tra i pari rimasti, cerca il primo divisibile per ${divisor}.`
        ],
        steps: [`soglia = ${threshold}`, `primi pari oltre soglia`, `${candidate} e divisibile per 2 e per ${divisor}`]
      };
    }
  },
  {
    id: "wrong-machine-log",
    title: "Log di errore",
    narrative: "La fabbrica ha scritto un risultato sbagliato: devi trovare il valore coerente, non fidarti del log.",
    minComplexity: 6,
    archetype: "diagnosi-errore",
    build: (a, b, c) => {
      const correct = (a - c) * 2 + b;
      const wrong = (a + c) * 2 + b;
      return {
        prompt: `Il log dice ${wrong}, ma la macchina corretta fa: togli ${c} da ${a}, raddoppia, poi aggiungi ${b}. Quale valore deve essere certificato?`,
        answer: correct,
        hints: [
          `Il log ha aggiunto ${c}, ma il comando dice togli.`,
          `Prima calcola ${a} - ${c}.`,
          "Solo dopo raddoppia e aggiungi l'ultimo valore."
        ],
        steps: [`${a} - ${c} = ${a - c}`, `${a - c} x 2 = ${(a - c) * 2}`, `${(a - c) * 2} + ${b} = ${correct}`]
      };
    }
  },
  {
    id: "sensor-average-threshold",
    title: "Sensori in media",
    narrative: "Il terminale non chiede un numero isolato: vuole una lettura stabile da tre sensori.",
    minComplexity: 3,
    archetype: "lettura-dati",
    build: (a, b, c) => {
      const s1 = a + c;
      const s2 = a + b;
      const s3 = a + b + c;
      const average = Math.round((s1 + s2 + s3) / 3);
      const code = average + c;
      return {
        prompt: `Tre sensori leggono ${s1}, ${s2} e ${s3}. Il codice è la media arrotondata all'intero più vicino; se finisse con ,5 si arrotonda all'intero superiore. Poi aggiungi ${c} per compensare la dispersione. Quale codice inserisci?`,
        answer: code,
        hints: [
          "Prima somma le tre letture: non scegliere il sensore più alto.",
          "Dividi la somma per 3 e arrotonda solo dopo aver diviso, usando la regola indicata.",
          `La compensazione +${c} arriva alla fine.`
        ],
        steps: [
          `${s1} + ${s2} + ${s3} = ${s1 + s2 + s3}`,
          `${s1 + s2 + s3} / 3 = ${(s1 + s2 + s3) / 3}`,
          `media arrotondata = ${average}`,
          `${average} + ${c} = ${code}`
        ]
      };
    }
  },
  {
    id: "energy-budget-choice",
    title: "Budget di energia",
    narrative: "La porta apre solo se resta energia dopo aver alimentato due sottosistemi.",
    minComplexity: 5,
    archetype: "vincolo",
    build: (a, b, c) => {
      const reserve = a + b + c;
      const terminalCost = b * 2;
      const robotCost = a - c;
      const remaining = reserve - terminalCost - robotCost;
      const recharge = remaining < 10 ? 10 - remaining : 0;
      const answer = remaining + recharge;
      return {
        prompt: `La riserva è ${reserve}. Il terminale consuma ${terminalCost}, il robot consuma ${robotCost}. Se il residuo scende sotto 10, devi ricaricare fino a 10. Quale valore finale deve leggere il pannello?`,
        answer,
        hints: [
          "Calcola prima quanto resta dopo i due consumi.",
          "Confronta il residuo con la soglia 10.",
          "Se è sotto soglia, il valore finale non è il residuo: è la soglia minima."
        ],
        steps: [
          `${reserve} - ${terminalCost} = ${reserve - terminalCost}`,
          `${reserve - terminalCost} - ${robotCost} = ${remaining}`,
          remaining < 10 ? `${remaining} e sotto 10, quindi ricarica fino a 10` : `${remaining} supera la soglia 10`,
          `valore finale = ${answer}`
        ]
      };
    }
  },
  {
    id: "ratio-cooling-loop",
    title: "Proporzione del radiatore",
    narrative: "Il radiatore non scala a caso: ogni modulo acceso consuma la stessa quota d'acqua.",
    minComplexity: 6,
    archetype: "proporzione",
    build: (a, b, c) => {
      const modules = Math.max(3, c);
      const waterPerModule = Math.max(4, Math.floor(b / 2));
      const activeModules = modules + 2;
      const reserve = activeModules * waterPerModule + a;
      const remaining = reserve - modules * waterPerModule;
      return {
        prompt: `${modules} moduli usano ${modules * waterPerModule} unità d'acqua. Ora sono attivi ${activeModules} moduli e la riserva è ${reserve}. Dopo aver alimentato solo ${modules} moduli, quanta acqua resta?`,
        answer: remaining,
        hints: [
          "Trova prima quanta acqua usa un solo modulo.",
          `Se ${modules} moduli usano ${modules * waterPerModule}, ogni modulo usa ${waterPerModule}.`,
          `Per ${modules} moduli sottrai ${modules * waterPerModule} dalla riserva ${reserve}.`
        ],
        steps: [
          `${modules * waterPerModule} / ${modules} = ${waterPerModule}`,
          `${modules} x ${waterPerModule} = ${modules * waterPerModule}`,
          `${reserve} - ${modules * waterPerModule} = ${remaining}`
        ]
      };
    }
  },
  {
    id: "parentheses-power-gate",
    title: "Porta con parentesi",
    narrative: "La porta legge i blocchi in ordine: prima il gruppo interno, poi il moltiplicatore.",
    minComplexity: 6,
    archetype: "pre-algebra",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(5, c));
      const inside = a - b;
      const answer = inside * multiplier + c;
      return {
        prompt: `Il codice segue questa procedura: (${a} - ${b}) x ${multiplier} + ${c}. Quale valore stabilizza la porta?`,
        answer,
        hints: [
          "La parentesi è il primo blocco da risolvere.",
          `Dopo la parentesi moltiplica per ${multiplier}.`,
          `Il +${c} si applica solo alla fine.`
        ],
        steps: [`${a} - ${b} = ${inside}`, `${inside} x ${multiplier} = ${inside * multiplier}`, `${inside * multiplier} + ${c} = ${answer}`]
      };
    }
  },
  {
    id: "hidden-input-equation",
    title: "Ingresso cancellato",
    narrative: "Il registro finale è leggibile, ma il numero iniziale è stato cancellato dalla macchina.",
    minComplexity: 7,
    archetype: "pre-algebra",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(5, c));
      const output = (a - b) * multiplier;
      return {
        prompt: `Un numero entra nella macchina. Prima viene diminuito di ${b}, poi moltiplicato per ${multiplier}. L'uscita è ${output}. Qual era il numero iniziale?`,
        answer: a,
        hints: [
          "Risolvi la macchina al contrario.",
          `Annulla la moltiplicazione: ${output} / ${multiplier}.`,
          `Se prima il numero era stato diminuito di ${b}, alla fine devi riaggiungerlo.`
        ],
        steps: [`${output} / ${multiplier} = ${a - b}`, `${a - b} + ${b} = ${a}`]
      };
    }
  },
  {
    id: "signed-temperature-offset",
    title: "Camera criogenica",
    narrative: "La fabbrica usa anche numeri sotto zero: la temperatura è un segnale, non un errore.",
    minComplexity: 7,
    archetype: "vincolo",
    build: (a, b, c) => {
      const start = -Math.max(4, c + 2);
      const cooling = Math.max(3, Math.floor(a / 3));
      const heat = Math.max(7, b, Math.abs(start) + cooling + 2);
      const answer = start + heat - cooling;
      return {
        prompt: `La camera parte da ${start} gradi. Si riscalda di ${heat} gradi e poi si raffredda di ${cooling} gradi. Quale temperatura finale deve leggere il sensore?`,
        answer,
        hints: [
          "Partire sotto zero significa che devi muoverti sulla linea dei numeri.",
          `Aggiungi ${heat}: ti sposti verso destra.`,
          `Poi sottrai ${cooling}: ti sposti indietro.`
        ],
        steps: [`${start} + ${heat} = ${start + heat}`, `${start + heat} - ${cooling} = ${answer}`]
      };
    }
  },
  {
    id: "error-control-two-logs",
    title: "Doppio log sospetto",
    narrative: "Due tecnici hanno registrato risultati diversi: solo uno rispetta l'ordine delle operazioni.",
    minComplexity: 8,
    archetype: "diagnosi-errore",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(4, c));
      const correct = a + b * multiplier - c;
      const wrong = (a + b) * multiplier - c;
      return {
        prompt: `Il protocollo dice: ${a} + ${b} x ${multiplier} - ${c}. Il log A segna ${wrong}, il log B segna ${correct}. Quale valore va certificato?`,
        answer: correct,
        hints: [
          "Moltiplicazione prima di addizione, anche senza parentesi.",
          `Calcola ${b} x ${multiplier} prima di sommare ${a}.`,
          "Il log che somma prima sta cambiando la regola del protocollo."
        ],
        steps: [`${b} x ${multiplier} = ${b * multiplier}`, `${a} + ${b * multiplier} = ${a + b * multiplier}`, `${a + b * multiplier} - ${c} = ${correct}`]
      };
    }
  },
  {
    id: "fraction-reserve-split",
    title: "Ripartitore di frazioni",
    narrative: "La riserva non va consumata a caso: due reparti prendono quote diverse dello stesso totale.",
    minComplexity: 3,
    archetype: "frazioni",
    competencies: ["matematica.frazioni", "matematica.calcolo", "matematica.logica"],
    curriculumTags: ["frazioni", "complemento all'intero", "problema a piu passaggi"],
    build: (a, b, c) => {
      const total = (a + b + c) * 6;
      const half = total / 2;
      const third = total / 3;
      const remaining = total - half - third;
      return {
        prompt: `La riserva ha ${total} unita. Il nucleo usa metà della riserva e il radiatore ne usa un terzo. Quante unita restano nel serbatoio?`,
        answer: remaining,
        hints: [
          "Metà e un terzo sono quote dello stesso totale, non del resto.",
          `${total} / 2 = ${half} e ${total} / 3 = ${third}.`,
          "Sottrai entrambe le quote dal totale iniziale."
        ],
        steps: [`${total} / 2 = ${half}`, `${total} / 3 = ${third}`, `${total} - ${half} - ${third} = ${remaining}`]
      };
    }
  },
  {
    id: "ratio-crystal-mix",
    title: "Miscela in rapporto",
    narrative: "Il miscelatore lavora con rapporti: se cambi la scala, la relazione deve restare uguale.",
    minComplexity: 4,
    archetype: "proporzione",
    competencies: ["matematica.frazioni", "matematica.logica", "problemSolving"],
    curriculumTags: ["rapporti", "proporzioni", "scalare una ricetta"],
    build: (a, b, c) => {
      const blueParts = 2 + c % 3;
      const goldParts = blueParts + 1;
      const factor = Math.max(3, Math.floor((a + b) / 6));
      const blue = blueParts * factor;
      const gold = goldParts * factor;
      const total = blue + gold;
      return {
        prompt: `La miscela richiede rapporto ${blueParts}:${goldParts} tra cristalli blu e oro. Il sistema ha ${blue} cristalli blu. Quanti cristalli totali avrà la miscela corretta?`,
        answer: total,
        hints: [
          `Se ${blueParts} parti blu diventano ${blue}, il fattore di scala è ${factor}.`,
          `Le parti oro sono ${goldParts}, quindi servono ${goldParts} x ${factor}.`,
          "Il totale è blu più oro."
        ],
        steps: [`${blue} / ${blueParts} = ${factor}`, `${goldParts} x ${factor} = ${gold}`, `${blue} + ${gold} = ${total}`]
      };
    }
  },
  {
    id: "percent-energy-boost",
    title: "Percentuale di carica",
    narrative: "Il pannello mostra una carica che aumenta in percentuale, poi perde una quota fissa durante il trasferimento.",
    minComplexity: 4,
    archetype: "percentuali",
    competencies: ["matematica.percentuali", "matematica.calcolo", "matematica.controlloErrore"],
    curriculumTags: ["percentuali", "aumento percentuale", "sottrazione finale"],
    build: (a, b, c) => {
      const base = (a + b) * 20;
      const percent = c % 2 === 0 ? 25 : 20;
      const boosted = base + base * percent / 100;
      const transferLoss = c * 5;
      const answer = boosted - transferLoss;
      return {
        prompt: `La batteria contiene ${base} unita. Un amplificatore aggiunge il ${percent}%, poi il trasferimento consuma ${transferLoss} unita. Quale valore resta?`,
        answer,
        hints: [
          `Calcola prima il ${percent}% di ${base}.`,
          "Aggiungi la percentuale al valore iniziale.",
          `Solo dopo sottrai la perdita fissa di ${transferLoss}.`
        ],
        steps: [`${percent}% di ${base} = ${base * percent / 100}`, `${base} + ${base * percent / 100} = ${boosted}`, `${boosted} - ${transferLoss} = ${answer}`]
      };
    }
  },
  {
    id: "rectangle-panel-code",
    title: "Pannello geometrico",
    narrative: "La porta misura una lastra: area e perimetro raccontano due proprietà diverse dello stesso oggetto.",
    minComplexity: 4,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.calcolo", "matematica.espressioni"],
    curriculumTags: ["rettangoli", "area", "perimetro"],
    build: (a, b, c) => {
      const width = Math.max(5, c + 4);
      const height = Math.max(6, Math.floor(b / 2) + 3);
      const area = width * height;
      const perimeter = 2 * (width + height);
      const answer = area + perimeter;
      return {
        prompt: `Una lastra rettangolare misura ${width} per ${height}. Il codice è area più perimetro. Quale codice inserisci?`,
        answer,
        hints: [
          "Area e perimetro non sono la stessa cosa.",
          `Area = ${width} x ${height}.`,
          `Perimetro = 2 x (${width} + ${height}).`
        ],
        steps: [`area = ${width} x ${height} = ${area}`, `perimetro = 2 x (${width} + ${height}) = ${perimeter}`, `${area} + ${perimeter} = ${answer}`]
      };
    }
  },
  {
    id: "coordinate-manhattan-route",
    title: "Coordinate del drone",
    narrative: "Il drone non vola in diagonale: deve contare spostamenti orizzontali e verticali sulla griglia.",
    minComplexity: 5,
    archetype: "coordinate",
    competencies: ["matematica.geometria", "matematica.logica", "coding.sequenze"],
    curriculumTags: ["piano cartesiano", "coordinate", "distanza su griglia"],
    build: (a, b, c) => {
      const startX = c;
      const startY = Math.max(2, c - 1);
      const endX = startX + Math.max(3, Math.floor(b / 3));
      const endY = startY + Math.max(2, Math.floor(a / 5));
      const distance = Math.abs(endX - startX) + Math.abs(endY - startY);
      return {
        prompt: `Il drone parte da (${startX}, ${startY}) e deve arrivare a (${endX}, ${endY}) senza diagonali. Quanti passi minimi servono?`,
        answer: distance,
        hints: [
          "Conta separatamente spostamento orizzontale e verticale.",
          `Orizzontale: ${endX} - ${startX}.`,
          `Verticale: ${endY} - ${startY}.`
        ],
        steps: [`dx = ${endX - startX}`, `dy = ${endY - startY}`, `${endX - startX} + ${endY - startY} = ${distance}`]
      };
    }
  },
  {
    id: "median-range-log",
    title: "Log statistico",
    narrative: "Il terminale non vuole il dato più vistoso: vuole una lettura stabile tra valori ordinati.",
    minComplexity: 5,
    archetype: "statistica",
    competencies: ["matematica.statistica", "matematica.grafici", "pensieroCritico"],
    curriculumTags: ["mediana", "range", "dati ordinati"],
    build: (a, b, c) => {
      const v1 = c + 4;
      const v2 = v1 + Math.max(2, Math.floor(b / 4));
      const v3 = v2 + Math.max(2, Math.floor(a / 6));
      const v4 = v3 + c;
      const v5 = v4 + 3;
      const median = v3;
      const range = v5 - v1;
      const answer = median + range;
      return {
        prompt: `I sensori ordinati leggono ${v1}, ${v2}, ${v3}, ${v4}, ${v5}. Il codice è mediana più intervallo massimo-minimo. Quale codice ottieni?`,
        answer,
        hints: [
          "Con cinque dati ordinati, la mediana è il valore centrale.",
          `L'intervallo è ${v5} - ${v1}.`,
          "Somma mediana e intervallo solo alla fine."
        ],
        steps: [`mediana = ${median}`, `range = ${v5} - ${v1} = ${range}`, `${median} + ${range} = ${answer}`]
      };
    }
  },
  {
    id: "probability-capsule-forecast",
    title: "Previsione di capsule",
    narrative: "Il selettore usa probabilità sperimentale: da un rapporto previsto devi stimare quante capsule arriveranno.",
    minComplexity: 6,
    archetype: "probabilita",
    competencies: ["matematica.probabilita", "matematica.frazioni", "matematica.logica"],
    curriculumTags: ["probabilita", "frequenza attesa", "rapporto"],
    build: (a, b, c) => {
      const total = (c + 4) * 6;
      const favorable = total / 3;
      const inspected = Math.max(18, Math.floor((a + b) / 3) * 6);
      const expected = inspected / 3;
      return {
        prompt: `Nel selettore, ${favorable} capsule su ${total} sono blu. Se il robot controlla ${inspected} capsule con lo stesso rapporto, quante capsule blu si aspetta?`,
        answer: expected,
        hints: [
          `Il rapporto ${favorable}/${total} si semplifica a 1/3.`,
          `Devi trovare un terzo di ${inspected}.`,
          "Non serve contare capsule una per una: usa il rapporto."
        ],
        steps: [`${favorable}/${total} = 1/3`, `${inspected} / 3 = ${expected}`]
      };
    }
  },
  {
    id: "square-root-door",
    title: "Radice della camera",
    narrative: "La stanza nasconde il lato di un quadrato dentro la sua area.",
    minComplexity: 6,
    archetype: "potenze-radici",
    competencies: ["matematica.potenzeRadici", "matematica.geometria", "matematica.algebra"],
    curriculumTags: ["quadrati perfetti", "radice quadrata", "area"],
    build: (a, b, c) => {
      const side = Math.max(6, c + 5);
      const area = side * side;
      const offset = Math.max(3, Math.floor(b / 3));
      const answer = side + offset;
      return {
        prompt: `Una camera quadrata ha area ${area}. Il codice è il lato della camera più ${offset}. Quale codice inserisci?`,
        answer,
        hints: [
          "Per un quadrato, lato x lato = area.",
          `La radice quadrata di ${area} è ${side}.`,
          `Dopo aver trovato il lato, aggiungi ${offset}.`
        ],
        steps: [`radice di ${area} = ${side}`, `${side} + ${offset} = ${answer}`]
      };
    }
  },
  {
    id: "linear-function-terminal",
    title: "Funzione del terminale",
    narrative: "Il terminale trasforma ogni ingresso con la stessa regola lineare.",
    minComplexity: 6,
    archetype: "funzione-lineare",
    competencies: ["matematica.funzioni", "matematica.algebra", "matematica.espressioni"],
    curriculumTags: ["funzioni lineari", "sostituzione", "modello ingresso-uscita"],
    build: (a, b, c) => {
      const m = Math.max(2, Math.min(5, c));
      const x = Math.max(3, Math.floor(a / 4));
      const q = b;
      const y = m * x + q;
      return {
        prompt: `Il terminale usa la funzione y = ${m}x + ${q}. Se x = ${x}, quale uscita y viene generata?`,
        answer: y,
        hints: [
          `Sostituisci x con ${x}.`,
          `Prima calcola ${m} x ${x}.`,
          `Poi aggiungi ${q}.`
        ],
        steps: [`${m} x ${x} = ${m * x}`, `${m * x} + ${q} = ${y}`]
      };
    }
  },
  {
    id: "two-drones-system",
    title: "Sistema dei due droni",
    narrative: "Due droni nascondono i propri carichi, ma il terminale conosce somma e differenza.",
    minComplexity: 7,
    archetype: "sistemi-lineari",
    competencies: ["matematica.algebra", "matematica.logica", "problemSolving"],
    curriculumTags: ["sistemi lineari", "somma e differenza", "incognite"],
    build: (a, b) => {
      const droneA = a + b;
      const droneB = a;
      const total = droneA + droneB;
      const difference = droneA - droneB;
      return {
        prompt: `Due droni trasportano carichi diversi. Insieme hanno ${total} unita; il primo ha ${difference} unita in più del secondo. Quante unita porta il primo drone?`,
        answer: droneA,
        hints: [
          "Se togli la differenza dalla somma, restano due carichi uguali al secondo drone.",
          `Calcola (${total} - ${difference}) / 2 per trovare il secondo drone.`,
          `Poi aggiungi la differenza ${difference}.`
        ],
        steps: [`(${total} - ${difference}) / 2 = ${droneB}`, `${droneB} + ${difference} = ${droneA}`]
      };
    }
  },
  {
    id: "pythagorean-cable",
    title: "Cavo diagonale",
    narrative: "La manutenzione deve tendere un cavo diagonale: i due lati della griglia formano un triangolo rettangolo.",
    minComplexity: 8,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.potenzeRadici", "problemSolving"],
    curriculumTags: ["teorema di Pitagora", "triangolo rettangolo", "distanza"],
    build: (_a2, _b, c) => {
      const scale = Math.max(2, Math.min(5, Math.floor(c / 2)));
      const sideA = 3 * scale;
      const sideB = 4 * scale;
      const hypotenuse = 5 * scale;
      return {
        prompt: `Due guide perpendicolari misurano ${sideA} e ${sideB}. Il cavo diagonale usa il triangolo 3-4-5 in scala. Quanto è lungo il cavo?`,
        answer: hypotenuse,
        hints: [
          "Riconosci una terna pitagorica scalata.",
          `${sideA}, ${sideB}, ? corrispondono a 3, 4, 5 moltiplicati per ${scale}.`,
          `La diagonale è 5 x ${scale}.`
        ],
        steps: [`scala = ${scale}`, `diagonale = 5 x ${scale} = ${hypotenuse}`]
      };
    }
  },
  {
    id: "exponential-signal-doubling",
    title: "Segnale esponenziale",
    narrative: "Un segnale di test raddoppia a ogni ciclo: all'inizio sembra lento, poi cresce molto rapidamente.",
    minComplexity: 8,
    archetype: "potenze-radici",
    competencies: ["matematica.potenzeRadici", "matematica.funzioni", "pensieroCritico"],
    curriculumTags: ["potenze di 2", "crescita esponenziale", "modello discreto"],
    build: (_a2, _b, c) => {
      const start = Math.max(2, Math.min(8, c));
      const cycles = c % 2 === 0 ? 4 : 3;
      const multiplier = 2 ** cycles;
      const answer = start * multiplier;
      return {
        prompt: `Il segnale parte da ${start} unita e raddoppia per ${cycles} cicli. Quale valore raggiunge alla fine?`,
        answer,
        hints: [
          `Raddoppiare per ${cycles} cicli significa moltiplicare per 2^${cycles}.`,
          `2^${cycles} = ${multiplier}.`,
          `Moltiplica ${start} per ${multiplier}.`
        ],
        steps: [`2^${cycles} = ${multiplier}`, `${start} x ${multiplier} = ${answer}`]
      };
    }
  },
  {
    id: "scientific-notation-decoder",
    title: "Decodificatore scientifico",
    narrative: "L'archivio compatta numeri grandi con potenze di dieci: bisogna espanderli senza perdere zeri.",
    minComplexity: 8,
    archetype: "potenze-radici",
    competencies: ["matematica.potenzeRadici", "matematica.calcolo", "matematica.controlloErrore"],
    curriculumTags: ["potenze di dieci", "notazione scientifica", "ordine di grandezza"],
    build: (_a2, _b, c) => {
      const mantissa = Math.max(2, Math.min(9, c));
      const exponent = c % 2 === 0 ? 3 : 2;
      const answer = mantissa * 10 ** exponent;
      return {
        prompt: `Il registro compresso mostra ${mantissa} x 10^${exponent}. Quale numero intero deve comparire nel terminale esteso?`,
        answer,
        hints: [
          `10^${exponent} sposta il valore di ${exponent} posizioni decimali.`,
          `10^${exponent} = ${10 ** exponent}.`,
          `Moltiplica ${mantissa} per ${10 ** exponent}.`
        ],
        steps: [`10^${exponent} = ${10 ** exponent}`, `${mantissa} x ${10 ** exponent} = ${answer}`]
      };
    }
  },
  {
    id: "linear-equation-balance",
    title: "Bilancia a incognita",
    narrative: "La console mostra una bilancia energetica: i due lati devono restare equivalenti.",
    minComplexity: 4,
    archetype: "equazione-primo-grado",
    competencies: ["matematica.algebra", "matematica.logica", "matematica.controlloErrore"],
    curriculumTags: ["equazioni di primo grado", "operazioni inverse", "incognita"],
    build: (a, b, c) => {
      const x = Math.max(4, c + 3);
      const coefficient = 2 + b % 4;
      const addend = Math.max(3, Math.floor(a / 3));
      const total = coefficient * x + addend;
      return {
        prompt: `La bilancia legge ${coefficient}x + ${addend} = ${total}. Quale valore di x mantiene il sistema in equilibrio?`,
        answer: x,
        hints: [
          `Prima togli ${addend} da entrambi i lati.`,
          `${total} - ${addend} = ${total - addend}.`,
          `Poi dividi per il coefficiente ${coefficient}.`
        ],
        steps: [`${coefficient}x + ${addend} = ${total}`, `${coefficient}x = ${total - addend}`, `x = ${total - addend} / ${coefficient} = ${x}`]
      };
    }
  },
  {
    id: "equation-with-parentheses",
    title: "Equazione con parentesi",
    narrative: "Il portello usa un'equazione compatta: prima devi espandere il blocco tra parentesi.",
    minComplexity: 6,
    archetype: "equazione-primo-grado",
    competencies: ["matematica.algebra", "matematica.espressioni", "matematica.controlloErrore"],
    curriculumTags: ["equazioni di primo grado", "parentesi", "proprieta distributiva"],
    build: (a, b, c) => {
      const x = Math.max(5, c + 4);
      const multiplier = 2 + c % 3;
      const shift = Math.max(2, Math.floor(b / 4));
      const right = multiplier * (x + shift);
      return {
        prompt: `Il portello registra ${multiplier}(x + ${shift}) = ${right}. Quale valore di x sblocca il registro?`,
        answer: x,
        hints: [
          `Dividi prima entrambi i lati per ${multiplier}.`,
          `${right} / ${multiplier} = ${x + shift}.`,
          `Se resta x + ${shift}, togli ${shift}.`
        ],
        steps: [`${multiplier}(x + ${shift}) = ${right}`, `x + ${shift} = ${right / multiplier}`, `x = ${right / multiplier} - ${shift} = ${x}`]
      };
    }
  },
  {
    id: "composite-area-panel",
    title: "Lastra composta",
    narrative: "La porta non e un rettangolo solo: e fatta da due pannelli affiancati con misure diverse.",
    minComplexity: 5,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.espressioni", "problemSolving"],
    curriculumTags: ["geometria composta", "area", "scomposizione"],
    build: (a, b, c) => {
      const h = Math.max(5, c + 4);
      const w1 = Math.max(4, Math.floor(a / 4));
      const w2 = Math.max(3, Math.floor(b / 4));
      const area = h * w1 + h * w2;
      return {
        prompt: `La lastra e composta da due rettangoli alti ${h}. Il primo e largo ${w1}, il secondo e largo ${w2}. Qual e l'area totale?`,
        answer: area,
        hints: [
          "Scomponi la figura in due rettangoli.",
          `Area 1 = ${h} x ${w1}; area 2 = ${h} x ${w2}.`,
          "Somma le due aree solo alla fine."
        ],
        steps: [`${h} x ${w1} = ${h * w1}`, `${h} x ${w2} = ${h * w2}`, `${h * w1} + ${h * w2} = ${area}`]
      };
    }
  },
  {
    id: "triangle-area-shield",
    title: "Scudo triangolare",
    narrative: "Uno scudo di emergenza ha forma triangolare: la base non basta, serve anche l'altezza.",
    minComplexity: 5,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.frazioni", "matematica.calcolo"],
    curriculumTags: ["triangoli", "area", "base e altezza"],
    build: (a, b, c) => {
      const base = 2 * Math.max(4, c + 2);
      const height = Math.max(5, Math.floor(b / 2));
      const area = base * height / 2;
      return {
        prompt: `Lo scudo triangolare ha base ${base} e altezza ${height}. Qual e la sua area?`,
        answer: area,
        hints: [
          "Per un triangolo non basta base x altezza: va diviso per 2.",
          `${base} x ${height} = ${base * height}.`,
          `Poi dividi per 2.`
        ],
        steps: [`base x altezza = ${base} x ${height} = ${base * height}`, `${base * height} / 2 = ${area}`]
      };
    }
  },
  {
    id: "cartesian-midpoint-code",
    title: "Nodo medio cartesiano",
    narrative: "Due fari segnano gli estremi di un corridoio: il terminale vuole il punto centrale del tratto.",
    minComplexity: 5,
    archetype: "coordinate",
    competencies: ["matematica.geometria", "matematica.algebra", "problemSolving"],
    curriculumTags: ["piano cartesiano", "punto medio", "coordinate"],
    build: (a, b, c) => {
      const x1 = c;
      const y1 = Math.max(2, c - 1);
      const x2 = x1 + 2 * Math.max(2, Math.floor(a / 6));
      const y2 = y1 + 2 * Math.max(2, Math.floor(b / 6));
      const midX = (x1 + x2) / 2;
      const midY = (y1 + y2) / 2;
      const answer = midX + midY;
      return {
        prompt: `I fari sono in A(${x1}, ${y1}) e B(${x2}, ${y2}). Il codice e la somma delle coordinate del punto medio. Quale codice inserisci?`,
        answer,
        hints: [
          "Il punto medio fa la media delle x e la media delle y.",
          `x medio = (${x1} + ${x2}) / 2.`,
          `y medio = (${y1} + ${y2}) / 2; poi somma le due coordinate.`
        ],
        steps: [`x medio = (${x1} + ${x2}) / 2 = ${midX}`, `y medio = (${y1} + ${y2}) / 2 = ${midY}`, `${midX} + ${midY} = ${answer}`]
      };
    }
  },
  {
    id: "cartesian-slope-ramp",
    title: "Pendenza della rampa",
    narrative: "Una rampa luminosa collega due nodi: il terminale misura quanto sale per ogni passo orizzontale.",
    minComplexity: 6,
    archetype: "coordinate",
    competencies: ["matematica.funzioni", "matematica.geometria", "matematica.logica"],
    curriculumTags: ["piano cartesiano", "pendenza", "variazione"],
    build: (a, b, c) => {
      const x1 = c;
      const y1 = Math.max(2, c + 1);
      const dx = Math.max(2, Math.min(5, Math.floor(b / 4)));
      const slope = Math.max(2, Math.min(5, Math.floor(a / 5)));
      const x2 = x1 + dx;
      const y2 = y1 + dx * slope;
      return {
        prompt: `La rampa va da A(${x1}, ${y1}) a B(${x2}, ${y2}). La pendenza e aumento verticale diviso aumento orizzontale. Quale pendenza legge il terminale?`,
        answer: slope,
        hints: [
          `Aumento orizzontale: ${x2} - ${x1}.`,
          `Aumento verticale: ${y2} - ${y1}.`,
          "Dividi aumento verticale per aumento orizzontale."
        ],
        steps: [`dx = ${x2} - ${x1} = ${dx}`, `dy = ${y2} - ${y1} = ${dx * slope}`, `pendenza = ${dx * slope} / ${dx} = ${slope}`]
      };
    }
  },
  {
    id: "probability-complement",
    title: "Probabilita complementare",
    narrative: "Il selettore non chiede quante capsule funzionano: chiede quante potrebbero fallire.",
    minComplexity: 5,
    archetype: "probabilita",
    competencies: ["matematica.probabilita", "matematica.frazioni", "pensieroCritico"],
    curriculumTags: ["probabilita", "evento complementare", "frequenza attesa"],
    build: (a, b, c) => {
      const total = Math.max(24, (c + 6) * 6);
      const success = Math.floor(total * 2 / 3);
      const checked = Math.max(18, Math.floor((a + b) / 3) * 6);
      const failExpected = checked / 3;
      return {
        prompt: `Nel lotto, ${success} capsule su ${total} funzionano: le altre sono difettose. Se il robot controlla ${checked} capsule con lo stesso rapporto, quante difettose si aspetta?`,
        answer: failExpected,
        hints: [
          "Se 2/3 funzionano, il complemento difettoso e 1/3.",
          `Devi calcolare un terzo di ${checked}.`,
          "La domanda chiede le difettose, non quelle funzionanti."
        ],
        steps: [`probabilita difettosa = 1 - 2/3 = 1/3`, `${checked} / 3 = ${failExpected}`]
      };
    }
  },
  {
    id: "probability-two-stage-selector",
    title: "Selettore a due stadi",
    narrative: "Un selettore controlla prima il colore e poi il simbolo: per passare servono entrambe le condizioni.",
    minComplexity: 7,
    archetype: "probabilita",
    competencies: ["matematica.probabilita", "matematica.frazioni", "matematica.logica"],
    curriculumTags: ["probabilita composta", "eventi indipendenti", "frazioni"],
    build: (a, b, c) => {
      const batch = Math.max(24, (c + 6) * 8);
      const colorDen = 4;
      const symbolDen = 2;
      const expected = batch / (colorDen * symbolDen);
      return {
        prompt: `In un lotto di ${batch} tessere, 1 su ${colorDen} ha il colore giusto. Tra quelle, 1 su ${symbolDen} ha anche il simbolo corretto. Quante tessere superano entrambi i controlli?`,
        answer: expected,
        hints: [
          "Servono entrambe le condizioni: non devi sommare le probabilita.",
          `1/${colorDen} e poi 1/${symbolDen} diventano 1/${colorDen * symbolDen}.`,
          `Calcola ${batch} / ${colorDen * symbolDen}.`
        ],
        steps: [`1/${colorDen} x 1/${symbolDen} = 1/${colorDen * symbolDen}`, `${batch} / ${colorDen * symbolDen} = ${expected}`]
      };
    }
  },
  {
    id: "lcm-beacon-sync",
    title: "Sincronizzazione beacon",
    narrative: "Due beacon lampeggiano con ritmi diversi: la porta si apre solo quando tornano insieme.",
    minComplexity: 4,
    archetype: "vincolo",
    competencies: ["matematica.multipliDivisori", "matematica.logica", "matematica.controlloErrore"],
    curriculumTags: ["mcm", "multipli", "sincronizzazione"],
    build: (_a2, b, c) => {
      const first = c % 2 === 0 ? 6 : 8;
      const second = b % 2 === 0 ? 9 : 12;
      const max = first * second;
      let sync = Math.max(first, second);
      while (sync <= max && (sync % first !== 0 || sync % second !== 0)) sync += 1;
      return {
        prompt: `Il beacon A lampeggia ogni ${first} secondi, il beacon B ogni ${second} secondi. Dopo quanti secondi lampeggiano insieme per la prima volta?`,
        answer: sync,
        hints: [
          "Cerca un numero che sia multiplo di entrambi gli intervalli.",
          `Elenca i multipli di ${first} e controlla quali sono anche multipli di ${second}.`,
          "Il primo multiplo comune è il tempo di sincronizzazione."
        ],
        steps: [`multipli di ${first}`, `multipli di ${second}`, `primo multiplo comune = ${sync}`]
      };
    }
  },
  {
    id: "gcd-cable-bundles",
    title: "Fasci di cavi",
    narrative: "Il magazzino vuole dividere due scorte in pacchi uguali senza avanzi.",
    minComplexity: 5,
    archetype: "vincolo",
    competencies: ["matematica.multipliDivisori", "matematica.logica", "problemSolving"],
    curriculumTags: ["MCD", "divisori", "ripartizione senza resto"],
    build: (a, b, c) => {
      const unit = c % 2 === 0 ? 6 : 4;
      const red = unit * Math.max(4, Math.floor(a / 3));
      const blue = unit * Math.max(5, Math.floor(b / 3));
      let gcd = Math.min(red, blue);
      while (gcd > 1 && (red % gcd !== 0 || blue % gcd !== 0)) gcd -= 1;
      return {
        prompt: `Ci sono ${red} cavi rossi e ${blue} cavi blu. Vuoi creare il massimo numero possibile di gruppi identici, senza lasciare cavi fuori. Quanti gruppi uguali puoi creare?`,
        answer: gcd,
        hints: [
          "Serve un numero che divida entrambe le quantità senza resto.",
          "Il numero massimo di gruppi identici è il massimo comune divisore.",
          `Controlla i divisori comuni di ${red} e ${blue}.`
        ],
        steps: [`divisori comuni di ${red} e ${blue}`, `MCD = ${gcd}`, `numero massimo di gruppi uguali = ${gcd}`]
      };
    }
  },
  {
    id: "fraction-successive-shares",
    title: "Quote successive",
    narrative: "Due reparti prelevano quote in momenti diversi: la seconda quota si calcola su ciò che resta.",
    minComplexity: 5,
    archetype: "frazioni",
    competencies: ["matematica.frazioni", "matematica.controlloErrore", "problemSolving"],
    curriculumTags: ["frazioni successive", "resto", "problemi a piu passaggi"],
    build: (a, b, c) => {
      const total = (a + b + c) * 4;
      const first = total / 4;
      const afterFirst = total - first;
      const second = afterFirst / 3;
      const remaining = afterFirst - second;
      return {
        prompt: `La riserva contiene ${total} unita. Il primo reparto usa un quarto della riserva. Poi il secondo reparto usa un terzo di ciò che resta. Quante unita rimangono?`,
        answer: remaining,
        hints: [
          "La seconda frazione non si calcola sul totale iniziale.",
          `Prima trova un quarto di ${total}.`,
          "Poi calcola un terzo del nuovo resto."
        ],
        steps: [`${total} / 4 = ${first}`, `${total} - ${first} = ${afterFirst}`, `${afterFirst} / 3 = ${second}`, `${afterFirst} - ${second} = ${remaining}`]
      };
    }
  },
  {
    id: "percent-reverse-charge",
    title: "Carica prima dello sconto",
    narrative: "Il registro mostra una carica dopo una perdita percentuale: devi ricostruire il valore iniziale.",
    minComplexity: 7,
    archetype: "percentuali",
    competencies: ["matematica.percentuali", "matematica.proporzionalita", "matematica.controlloErrore"],
    curriculumTags: ["percentuali inverse", "valore iniziale", "proporzione"],
    build: (_a2, b, c) => {
      const percentLeft = c % 2 === 0 ? 75 : 80;
      const final = Math.max(5, Math.floor(b / 2)) * percentLeft;
      const initial = final * 100 / percentLeft;
      return {
        prompt: `Dopo una perdita, resta il ${percentLeft}% della carica iniziale. Il display mostra ${final} unita. Qual era la carica iniziale?`,
        answer: initial,
        hints: [
          `Se ${final} è il ${percentLeft}%, non devi togliere ancora una percentuale.`,
          `Dividi per ${percentLeft} e moltiplica per 100.`,
          "Controlla: il valore iniziale deve essere maggiore del valore finale."
        ],
        steps: [`${final} / ${percentLeft} = ${final / percentLeft}`, `${final / percentLeft} x 100 = ${initial}`]
      };
    }
  },
  {
    id: "scale-map-route",
    title: "Mappa in scala",
    narrative: "La planimetria compatta le distanze: il robot deve convertire la mappa in metri reali.",
    minComplexity: 5,
    archetype: "proporzione",
    competencies: ["matematica.proporzionalita", "matematica.misure", "matematica.geometria"],
    curriculumTags: ["scale", "conversione", "proporzioni"],
    build: (_a2, b, c) => {
      const scale = c % 2 === 0 ? 5 : 10;
      const mapCm = Math.max(6, Math.floor(b / 2));
      const meters = mapCm * scale;
      return {
        prompt: `Sulla mappa 1 cm corrisponde a ${scale} metri reali. Il corridoio misura ${mapCm} cm sulla mappa. Quanti metri reali percorre il robot?`,
        answer: meters,
        hints: [
          "La scala indica quanti metri reali vale ogni centimetro disegnato.",
          `Ogni cm vale ${scale} m.`,
          `Moltiplica ${mapCm} per ${scale}.`
        ],
        steps: [`1 cm -> ${scale} m`, `${mapCm} x ${scale} = ${meters}`]
      };
    }
  },
  {
    id: "robot-speed-time",
    title: "Velocita del carrello",
    narrative: "Il carrello non teletrasporta: distanza, velocità e tempo devono essere coerenti.",
    minComplexity: 6,
    archetype: "proporzione",
    competencies: ["matematica.proporzionalita", "matematica.funzioni", "matematica.misure"],
    curriculumTags: ["velocita", "tempo", "distanza"],
    build: (a, _b, c) => {
      const speed = Math.max(3, c + 2);
      const time = Math.max(4, Math.floor(a / 4));
      const distance = speed * time;
      return {
        prompt: `Un carrello si muove a ${speed} metri al secondo per ${time} secondi. Quanti metri percorre?`,
        answer: distance,
        hints: [
          "Se la velocità è costante, distanza = velocità x tempo.",
          `Ogni secondo aggiunge ${speed} metri.`,
          `Ripeti per ${time} secondi.`
        ],
        steps: [`distanza = ${speed} x ${time}`, `${speed} x ${time} = ${distance}`]
      };
    }
  },
  {
    id: "unit-conversion-sensor",
    title: "Sensore in centimetri",
    narrative: "Il terminale rifiuta dati con unità miste: prima bisogna convertirli.",
    minComplexity: 3,
    archetype: "lettura-dati",
    competencies: ["matematica.misure", "matematica.calcolo", "matematica.controlloErrore"],
    curriculumTags: ["unita di misura", "centimetri e metri", "somma coerente"],
    build: (_a2, b, c) => {
      const meters = Math.max(2, c);
      const centimeters = Math.max(30, Math.floor(b / 2) * 10);
      const totalCm = meters * 100 + centimeters;
      return {
        prompt: `Un cavo misura ${meters} metri e un secondo tratto misura ${centimeters} centimetri. Il terminale vuole il totale in centimetri. Che valore inserisci?`,
        answer: totalCm,
        hints: [
          "Prima converti tutto nella stessa unità.",
          `${meters} metri = ${meters * 100} centimetri.`,
          `Poi aggiungi ${centimeters} centimetri.`
        ],
        steps: [`${meters} m = ${meters * 100} cm`, `${meters * 100} + ${centimeters} = ${totalCm}`]
      };
    }
  },
  {
    id: "triangle-angle-console",
    title: "Angolo mancante",
    narrative: "Tre bracci formano un triangolo: il terminale deve sapere l'angolo rimasto.",
    minComplexity: 4,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.calcolo", "matematica.controlloErrore"],
    curriculumTags: ["angoli", "triangoli", "somma interna"],
    build: (a, b, c) => {
      const angleA = 40 + c % 4 * 5;
      const angleB = 50 + Math.floor(b / 3) % 5 * 4;
      const missing = 180 - angleA - angleB;
      return {
        prompt: `Due angoli di un triangolo misurano ${angleA}° e ${angleB}°. Quanto misura il terzo angolo?`,
        answer: missing,
        hints: [
          "La somma degli angoli interni di un triangolo è 180°.",
          `Somma prima ${angleA} e ${angleB}.`,
          "Il terzo angolo è ciò che manca per arrivare a 180°."
        ],
        steps: [`${angleA} + ${angleB} = ${angleA + angleB}`, `180 - ${angleA + angleB} = ${missing}`]
      };
    }
  },
  {
    id: "prism-volume-crate",
    title: "Volume del contenitore",
    narrative: "La fabbrica deve sapere quante unità entrano in una cassa, non solo quanto è lungo il bordo.",
    minComplexity: 6,
    archetype: "geometria",
    competencies: ["matematica.geometria3D", "matematica.geometria", "matematica.misure"],
    curriculumTags: ["volume", "parallelepipedo", "geometria solida"],
    build: (_a2, b, c) => {
      const length = Math.max(4, c + 3);
      const width = Math.max(3, Math.floor(b / 5));
      const height = 2 + c % 4;
      const volume = length * width * height;
      return {
        prompt: `Una cassa misura ${length} x ${width} x ${height}. Quante unita cubiche contiene?`,
        answer: volume,
        hints: [
          "Il volume di un parallelepipedo è lunghezza x larghezza x altezza.",
          `Prima calcola ${length} x ${width}.`,
          `Poi moltiplica per l'altezza ${height}.`
        ],
        steps: [`${length} x ${width} = ${length * width}`, `${length * width} x ${height} = ${volume}`]
      };
    }
  },
  {
    id: "circle-perimeter-approx",
    title: "Anello di sicurezza",
    narrative: "Il nucleo circolare richiede un bordo protettivo: il sistema usa pi greco approssimato a 3.",
    minComplexity: 7,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.misure", "matematica.controlloErrore"],
    curriculumTags: ["cerchio", "circonferenza", "approssimazione"],
    build: (_a2, _b, c) => {
      const radius = Math.max(4, c + 3);
      const circumference = 2 * 3 * radius;
      return {
        prompt: `Un anello circolare ha raggio ${radius}. Per questa prova il sistema definisce π = 3. Quale valore numerico ottieni per la circonferenza?`,
        answer: circumference,
        hints: [
          "La circonferenza è 2 x π x r.",
          "Qui non devi scegliere una stima libera: usa esattamente π = 3.",
          `Calcola 2 x 3 x ${radius}.`
        ],
        steps: [`2 x 3 x ${radius} = ${circumference}`]
      };
    }
  },
  {
    id: "relative-temperature-net",
    title: "Bilancio termico",
    narrative: "Nel laboratorio le temperature sotto zero sono informazioni utili: devi controllare il saldo finale.",
    minComplexity: 5,
    archetype: "vincolo",
    competencies: ["matematica.numeriRelativi", "matematica.calcolo", "matematica.logica"],
    curriculumTags: ["numeri relativi", "variazione", "linea dei numeri"],
    build: (a, b, c) => {
      const start = -Math.max(5, c + 3);
      const fall = Math.max(3, Math.floor(b / 5));
      const rise = Math.max(Math.abs(start) + fall + 2, Math.floor(a / 2));
      const final = start + rise - fall;
      return {
        prompt: `La camera è a ${start}°. Si riscalda di ${rise}° e poi perde ${fall}°. Quale temperatura finale legge il sistema?`,
        answer: final,
        hints: [
          "Parti da un numero negativo e muoviti sulla linea dei numeri.",
          `Riscaldarsi di ${rise} significa aggiungere ${rise}.`,
          `Perdere ${fall} gradi significa sottrarre ${fall}.`
        ],
        steps: [`${start} + ${rise} = ${start + rise}`, `${start + rise} - ${fall} = ${final}`]
      };
    }
  },
  {
    id: "inequality-safe-load",
    title: "Carico massimo sicuro",
    narrative: "La piattaforma può aggiungere capsule solo finché non supera il limite di sicurezza.",
    minComplexity: 7,
    archetype: "vincolo",
    competencies: ["matematica.equazioni", "matematica.algebra", "matematica.controlloErrore"],
    curriculumTags: ["disequazioni", "massimo intero", "vincolo"],
    build: (a, b, c) => {
      const weightEach = Math.max(3, c + 2);
      const fixed = Math.max(8, Math.floor(a / 2));
      const maxCapsules = Math.max(4, Math.floor(b / 3));
      const limit = fixed + weightEach * maxCapsules + (weightEach - 1);
      return {
        prompt: `La piattaforma pesa già ${fixed}. Ogni capsula aggiunge ${weightEach}. Il limite è ${limit}. Qual è il massimo numero intero di capsule che puoi caricare senza superare il limite?`,
        answer: maxCapsules,
        hints: [
          `Prima togli il peso fisso ${fixed} dal limite.`,
          `Poi dividi lo spazio rimasto per il peso di una capsula: ${weightEach}.`,
          "Devi prendere il massimo intero che non supera il limite."
        ],
        steps: [`${limit} - ${fixed} = ${limit - fixed}`, `${limit - fixed} / ${weightEach} = ${(limit - fixed) / weightEach}`, `massimo intero = ${maxCapsules}`]
      };
    }
  },
  {
    id: "fraction-equation-balance",
    title: "Equazione con quota",
    narrative: "La bilancia nasconde un valore diviso in quote: devi ricostruire l'intero.",
    minComplexity: 8,
    archetype: "equazione-primo-grado",
    competencies: ["matematica.equazioni", "matematica.frazioni", "matematica.algebra"],
    curriculumTags: ["equazioni con frazioni", "operazioni inverse", "incognita"],
    build: (_a2, b, c) => {
      const x = Math.max(12, (c + 5) * 3);
      const addend = Math.max(4, Math.floor(b / 4));
      const result = x / 3 + addend;
      return {
        prompt: `La bilancia mostra x/3 + ${addend} = ${result}. Quale valore ha x?`,
        answer: x,
        hints: [
          `Prima togli ${addend} da entrambi i lati.`,
          `Resta x/3 = ${result - addend}.`,
          "Per annullare la divisione per 3, moltiplica per 3."
        ],
        steps: [`x/3 + ${addend} = ${result}`, `x/3 = ${result - addend}`, `x = ${result - addend} x 3 = ${x}`]
      };
    }
  },
  {
    id: "negative-coordinate-route",
    title: "Coordinate sotto zero",
    narrative: "La mappa dell'ala ovest usa coordinate negative: attraversare lo zero conta come movimento.",
    minComplexity: 7,
    archetype: "coordinate",
    competencies: ["matematica.numeriRelativi", "matematica.geometria", "matematica.logica"],
    curriculumTags: ["coordinate negative", "piano cartesiano", "distanza su griglia"],
    build: (_a2, b, c) => {
      const x1 = -Math.max(2, c);
      const y1 = Math.max(2, c - 1);
      const x2 = Math.max(3, Math.floor(b / 4));
      const y2 = y1 - 3;
      const distance = Math.abs(x2 - x1) + Math.abs(y2 - y1);
      return {
        prompt: `Il robot parte da (${x1}, ${y1}) e arriva a (${x2}, ${y2}) senza diagonali. Quanti passi minimi servono?`,
        answer: distance,
        hints: [
          "Conta lo spostamento in x attraversando anche lo zero.",
          `Da ${x1} a ${x2} ci sono ${Math.abs(x2 - x1)} passi orizzontali.`,
          `Poi aggiungi i ${Math.abs(y2 - y1)} passi verticali.`
        ],
        steps: [`dx = |${x2} - (${x1})| = ${Math.abs(x2 - x1)}`, `dy = |${y2} - ${y1}| = ${Math.abs(y2 - y1)}`, `${Math.abs(x2 - x1)} + ${Math.abs(y2 - y1)} = ${distance}`]
      };
    }
  },
  {
    id: "similar-triangles-scale",
    title: "Triangoli in scala",
    narrative: "Una proiezione ingrandisce un triangolo: tutti i lati devono crescere con lo stesso fattore.",
    minComplexity: 7,
    archetype: "proporzione",
    competencies: ["matematica.proporzionalita", "matematica.geometria", "problemSolving"],
    curriculumTags: ["similitudine", "fattore di scala", "proporzioni"],
    build: (_a2, b, c) => {
      const smallSide = Math.max(3, c + 2);
      const scale = Math.max(2, Math.min(5, Math.floor(b / 5)));
      const bigKnown = smallSide * scale;
      const secondSmall = smallSide + 2;
      const secondBig = secondSmall * scale;
      return {
        prompt: `In due triangoli simili, un lato passa da ${smallSide} a ${bigKnown}. Un altro lato del triangolo piccolo misura ${secondSmall}. Quanto misura il lato corrispondente nel triangolo grande?`,
        answer: secondBig,
        hints: [
          "Trova prima il fattore di scala.",
          `${bigKnown} / ${smallSide} = ${scale}.`,
          `Applica lo stesso fattore a ${secondSmall}.`
        ],
        steps: [`fattore = ${bigKnown} / ${smallSide} = ${scale}`, `${secondSmall} x ${scale} = ${secondBig}`]
      };
    }
  },
  {
    id: "outlier-mean-repair",
    title: "Dato anomalo",
    narrative: "Un sensore impazzito altera la media: devi riconoscere l'effetto del dato anomalo.",
    minComplexity: 7,
    archetype: "statistica",
    competencies: ["matematica.statistica", "matematica.grafici", "pensieroCritico"],
    curriculumTags: ["media", "dato anomalo", "lettura critica"],
    build: (_a2, _b, c) => {
      const normal = Math.max(8, c + 7);
      const outlier = normal + 30;
      const meanWith = (normal * 4 + outlier) / 5;
      const meanWithout = normal;
      const difference = meanWith - meanWithout;
      return {
        prompt: `Cinque letture sono ${normal}, ${normal}, ${normal}, ${normal}, ${outlier}. Usa la media esatta, senza arrotondare. Di quanto la media con il dato anomalo supera la media delle quattro letture stabili?`,
        answer: difference,
        hints: [
          "Le quattro letture stabili hanno media uguale al loro valore.",
          "Calcola la media includendo anche il dato anomalo.",
          "La domanda chiede la differenza tra le due medie."
        ],
        steps: [`media stabile = ${normal}`, `media con anomalia = (${normal} x 4 + ${outlier}) / 5 = ${meanWith}`, `${meanWith} - ${normal} = ${difference}`]
      };
    }
  },
  {
    id: "histogram-total-frequency",
    title: "Istogramma del terminale",
    narrative: "Il terminale mostra barre, non un numero unico: devi sommare frequenze coerenti.",
    minComplexity: 4,
    archetype: "statistica",
    competencies: ["matematica.statistica", "matematica.grafici", "matematica.calcolo"],
    curriculumTags: ["frequenze", "istogramma", "somma dati"],
    build: (a, b, c) => {
      const f1 = Math.max(3, c + 1);
      const f2 = Math.max(4, Math.floor(a / 5));
      const f3 = Math.max(5, Math.floor(b / 5));
      const total = f1 + f2 + f3;
      return {
        prompt: `L'istogramma registra tre barre con frequenze ${f1}, ${f2} e ${f3}. Quante osservazioni totali sono state raccolte?`,
        answer: total,
        hints: [
          "Le frequenze indicano quante osservazioni cadono in ogni barra.",
          "Il totale è la somma delle frequenze.",
          "Non devi fare la media: la domanda chiede quante osservazioni ci sono."
        ],
        steps: [`${f1} + ${f2} + ${f3} = ${total}`]
      };
    }
  }
];
function clampNumber(value, min, max) {
  return Math.max(min, Math.min(max, value));
}
class MathPuzzleGenerator {
  generate(random, difficulty, preferredArchetypes = []) {
    const equationRequested = preferredArchetypes.includes("equazione-secondo-grado") || preferredArchetypes.includes("equazione-primo-grado");
    const graphRequested = preferredArchetypes.includes("grafici-cartesiani") || preferredArchetypes.includes("funzione-lineare") || preferredArchetypes.includes("coordinate");
    if (difficulty.mathComplexity >= 3 && (preferredArchetypes.includes("grafici-cartesiani") && random.bool(0.82) || graphRequested && random.bool(difficulty.mathComplexity >= 6 ? 0.48 : 0.32) || preferredArchetypes.length === 0 && random.bool(difficulty.mathComplexity >= 6 ? 0.26 : 0.12))) {
      return this.generateGraphWorkshop(random.fork("graph-workshop"), difficulty);
    }
    if (difficulty.mathComplexity >= 4 && (equationRequested && random.bool(difficulty.mathComplexity >= 6 ? 0.65 : 0.42) || preferredArchetypes.length === 0 && random.bool(difficulty.mathComplexity >= 6 ? 0.24 : 0.16))) {
      return this.generateEquationLab(random.fork("equation-lab"), difficulty);
    }
    const eligibleTemplates = mathTemplates.filter((template2) => template2.minComplexity <= difficulty.mathComplexity);
    const floor = Math.max(1, difficulty.mathComplexity - 2);
    const focusedTemplates = eligibleTemplates.filter((template2) => template2.minComplexity >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates;
    const preferredPool = preferredArchetypes.length > 0 ? (eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates).filter((template2) => preferredArchetypes.includes(template2.archetype)) : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const base = 4 + difficulty.mathComplexity * 2;
    const a = random.integer(base, base + 8);
    const b = random.integer(3, 6 + difficulty.mathComplexity * 2);
    const c = random.integer(2, 4 + difficulty.mathComplexity);
    const built = template.build(a, b, c);
    const responseRule = "Formato risposta: inserisci un solo numero intero. Se il testo indica una regola di arrotondamento, usa solo quella regola.";
    return {
      id: `math-${template.id}`,
      title: template.title,
      prompt: `Situazione: ${template.narrative}
Richiesta: ${built.prompt}
${responseRule}`,
      answer: built.answer,
      hints: built.hints,
      archetype: template.archetype,
      curriculumTags: template.curriculumTags ?? [],
      solutionSteps: built.steps ?? [
        `Identifica i dati: ${a}, ${b}, ${c}.`,
        ...built.hints.map((hint) => hint.replace(/\.$/, "")),
        `Valore finale certificato: ${built.answer}.`
      ],
      competencies: Array.from(/* @__PURE__ */ new Set([...template.competencies ?? ["matematica.calcolo", "matematica.logica"], "problemSolving"]))
    };
  }
  generateEquationLab(random, difficulty) {
    const quadratic = difficulty.mathComplexity >= 6 && random.bool(difficulty.mathComplexity >= 8 ? 0.76 : 0.58);
    return quadratic ? this.buildQuadraticEquationLab(random, difficulty) : this.buildLinearEquationLab(random, difficulty);
  }
  generateGraphWorkshop(random, difficulty) {
    const modes = difficulty.mathComplexity <= 2 ? ["beacon-line"] : difficulty.mathComplexity <= 4 ? ["beacon-line", "vertex-shift"] : difficulty.mathComplexity <= 6 ? ["beacon-line", "vertex-shift", "root-gates", "curve-match"] : ["vertex-shift", "root-gates", "curve-match", "beacon-line"];
    const mode = random.pick(modes);
    const workshop = mode === "beacon-line" ? this.buildBeaconLineWorkshop(random, difficulty) : mode === "vertex-shift" ? this.buildVertexWorkshop(random, difficulty) : mode === "root-gates" ? this.buildRootGateWorkshop(random, difficulty) : this.buildCurveMatchWorkshop(random, difficulty);
    const modeCopy = {
      "beacon-line": {
        title: "Linea tra i beacon",
        narrative: "Due trasmettitori devono essere attraversati dalla stessa retta."
      },
      "vertex-shift": {
        title: "Teletrasporto del vertice",
        narrative: "Una parabola deve spostare il proprio vertice sul portale indicato."
      },
      "root-gates": {
        title: "Porte delle radici",
        narrative: "La curva deve attraversare due serrature poste sull'asse x."
      },
      "curve-match": {
        title: "Sovrapponi la curva",
        narrative: "Una traccia fantasma mostra la funzione che il proiettore deve ricostruire."
      }
    }[workshop.mode];
    return {
      id: `math-graph-${workshop.mode}-${workshop.parameters.map((parameter) => parameter.target).join("-")}`,
      title: `Officina dei Grafici · ${modeCopy.title}`,
      prompt: [
        `Situazione: ${modeCopy.narrative}`,
        `Richiesta: ${workshop.objective}`,
        "Formato risposta: modifica i parametri con i controlli grafici, osserva la curva in tempo reale e certifica quando soddisfa tutti i vincoli."
      ].join("\n"),
      answer: 0,
      hints: this.graphWorkshopHints(workshop),
      archetype: "grafici-cartesiani",
      curriculumTags: workshop.functionKind === "linear" ? ["piano cartesiano", "retta", "coefficiente angolare", "intercetta"] : ["piano cartesiano", "parabola", "vertice", "radici", "trasformazioni"],
      solutionSteps: [
        workshop.principle,
        ...workshop.parameters.map((parameter) => `${parameter.label} = ${parameter.target}: ${parameter.meaning}`),
        workshop.successExplanation
      ],
      competencies: [
        "matematica.grafici",
        "matematica.funzioni",
        "matematica.coordinate",
        "matematica.algebra",
        "problemSolving"
      ],
      graphWorkshop: workshop
    };
  }
  generateMinigame(random, difficulty, preferredTypes = []) {
    const type = preferredTypes.length > 0 ? random.pick(preferredTypes) : random.pick(["target-sum", "factor-hunt", "operation-chain"]);
    const minigame = this.buildMinigame(random.fork(type), difficulty, type);
    const first = minigame.prompts[0];
    const firstSolution = first.solutionLabels.join(" + ");
    return {
      id: `math-mini-${type}-${random.integer(1e3, 9999)}`,
      title: minigame.title,
      prompt: [
        `Situazione: una console di calcolo rapido apre micro-portali numerici per 60 secondi.`,
        `Richiesta: ${first.prompt}`,
        `Formato risposta: inserisci un solo numero intero se usi la modalità terminale; nel minigioco seleziona le tessere corrette.`
      ].join("\n"),
      answer: this.answerProxy(first),
      hints: [
        "Prima leggi il bersaglio: non tutte le tessere utili sono vicine tra loro.",
        "Scarta i distrattori con un controllo rapido: pari/dispari, multiplo, divisore o operazione inversa.",
        "Dopo ogni risposta, chiediti se hai seguito una regola o se hai solo provato."
      ],
      archetype: type === "target-sum" ? "calcolo-diretto" : type === "factor-hunt" ? "vincolo" : "pre-algebra",
      curriculumTags: type === "target-sum" ? ["calcolo mentale", "scomposizione", "somma strategica"] : type === "factor-hunt" ? ["multipli", "divisori", "vincoli"] : ["operazioni inverse", "espressioni", "trasformazioni"],
      solutionSteps: [
        `Leggi la regola del minigioco: ${minigame.instructions}`,
        `Prima schermata: ${first.targetLabel}.`,
        `Tessere corrette iniziali: ${firstSolution}.`,
        first.explanation
      ],
      competencies: minigame.competencies,
      minigame
    };
  }
  fallback(random, difficulty) {
    const complexity = (difficulty == null ? void 0 : difficulty.mathComplexity) ?? 1;
    const value = (random == null ? void 0 : random.integer(5 + complexity, 12 + complexity * 2)) ?? 8;
    const multiplier = (random == null ? void 0 : random.integer(2, Math.min(5, 2 + complexity))) ?? 3;
    const subtract = (random == null ? void 0 : random.integer(2, Math.min(9, value - 1))) ?? 5;
    const answer = value * multiplier - subtract;
    return {
      id: `math-fallback-${value}-${multiplier}-${subtract}`,
      title: (random == null ? void 0 : random.bool()) ? "Serratura variabile" : "Codice di riserva",
      prompt: `Situazione: La serratura genera un codice numerico diverso per ogni sessione.
Richiesta: Moltiplica ${value} per ${multiplier}, poi sottrai ${subtract}.
Formato risposta: inserisci un solo numero intero.`,
      answer,
      hints: [`Prima calcola ${value} x ${multiplier}.`, `Poi sottrai ${subtract} dal risultato.`],
      archetype: "calcolo-diretto",
      curriculumTags: ["calcolo mentale", "ordine delle operazioni"],
      solutionSteps: [`${value} x ${multiplier} = ${value * multiplier}`, `${value * multiplier} - ${subtract} = ${answer}`],
      competencies: ["matematica.calcolo", "matematica.logica"]
    };
  }
  buildMinigame(random, difficulty, type) {
    const promptCount = 18 + difficulty.level;
    const prompts = [];
    let previousSignature = "";
    for (let index = 0; index < promptCount; index += 1) {
      const prompt = this.uniquePrompt(random, difficulty, type, index, previousSignature);
      prompts.push(prompt);
      previousSignature = prompt.signature;
    }
    const titles = {
      "target-sum": "Minigioco: Somma al bersaglio",
      "factor-hunt": "Minigioco: Caccia a multipli e divisori",
      "operation-chain": "Minigioco: Rotte delle operazioni"
    };
    const instructions = {
      "target-sum": "seleziona solo le tessere che raggiungono il bersaglio esatto.",
      "factor-hunt": "seleziona tutti e soli i numeri che rispettano il vincolo.",
      "operation-chain": "scegli la trasformazione che porta dall'ingresso all'uscita."
    };
    return {
      type,
      title: titles[type],
      durationMs: 6e4,
      instructions: instructions[type],
      scoringRule: "60 secondi: +punti per risposte corrette e serie pulite, penalità per errori e aiuti. In missione l'errore chiude il tentativo.",
      prompts,
      competencies: Array.from(/* @__PURE__ */ new Set([
        "matematica.calcolo",
        "matematica.logica",
        "problemSolving",
        ...type === "factor-hunt" ? ["matematica.multipliDivisori"] : [],
        ...type === "operation-chain" ? ["matematica.espressioni", "matematica.controlloErrore"] : []
      ]))
    };
  }
  buildLinearEquationLab(random, difficulty) {
    const root = random.integer(2, 7 + difficulty.mathComplexity);
    const coefficient = random.integer(2, Math.min(6, 2 + difficulty.mathComplexity));
    const addend = random.integer(2, 10 + difficulty.mathComplexity);
    const total = coefficient * root + addend;
    const equation = `${coefficient}x + ${addend} = ${total}`;
    const afterSubtract = total - addend;
    const wrongSubtract = total + addend;
    const solutionValues = /* @__PURE__ */ new Set([root, afterSubtract, wrongSubtract, root + coefficient]);
    let distractorOffset = 1;
    while (solutionValues.size < 4) {
      solutionValues.add(root + coefficient * distractorOffset + 1);
      distractorOffset += 1;
    }
    const solutionOptions = [...solutionValues].slice(0, 4).map(String);
    const stages = [
      {
        id: "linear-balance",
        title: "1 · Conserva l'equilibrio",
        prompt: `Per eliminare +${addend} dal lato sinistro, quale operazione mantiene equivalenti i due membri?`,
        options: random.shuffle([
          `Sottrarre ${addend} a entrambi i membri`,
          `Sottrarre ${addend} solo a sinistra`,
          `Dividere subito tutto per ${addend}`,
          `Aggiungere ${addend} a entrambi i membri`
        ]),
        correctOption: `Sottrarre ${addend} a entrambi i membri`,
        explanation: `La stessa operazione sui due membri conserva l'uguaglianza: ${equation} diventa ${coefficient}x = ${afterSubtract}.`,
        visual: "balance"
      },
      {
        id: "linear-inverse",
        title: "2 · Isola l'incognita",
        prompt: `Dopo il primo passaggio hai ${coefficient}x = ${afterSubtract}. Qual è il passaggio corretto?`,
        options: random.shuffle([
          `Dividere entrambi i membri per ${coefficient}`,
          `Sottrarre ${coefficient} da entrambi i membri`,
          `Moltiplicare entrambi i membri per ${coefficient}`,
          `Dividere solo il membro sinistro per ${coefficient}`
        ]),
        correctOption: `Dividere entrambi i membri per ${coefficient}`,
        explanation: `La moltiplicazione per ${coefficient} si annulla dividendo entrambi i membri per ${coefficient}: x = ${root}.`,
        visual: "inverse-steps"
      },
      {
        id: "linear-solution",
        title: "3 · Calcola la soluzione",
        prompt: `Quale valore risolve ${equation}?`,
        options: random.shuffle(solutionOptions),
        correctOption: `${root}`,
        explanation: `${total} - ${addend} = ${afterSubtract}; ${afterSubtract} : ${coefficient} = ${root}.`,
        visual: "inverse-steps"
      },
      {
        id: "linear-check",
        title: "4 · Verifica per sostituzione",
        prompt: `Quale sostituzione dimostra che x = ${root} è corretta?`,
        options: random.shuffle([
          `${coefficient} · ${root} + ${addend} = ${total}`,
          `${coefficient} + ${root} · ${addend} = ${total}`,
          `${coefficient} · ${root} - ${addend} = ${total}`,
          `${root} + ${addend} = ${total}`
        ]),
        correctOption: `${coefficient} · ${root} + ${addend} = ${total}`,
        explanation: `Sostituendo x con ${root}, il primo membro vale ${coefficient * root} + ${addend} = ${total}, uguale al secondo.`,
        visual: "substitution"
      }
    ];
    return {
      id: `math-equation-lab-linear-${coefficient}-${addend}-${root}`,
      title: "Laboratorio equazioni · Bilancia lineare",
      prompt: `Situazione: una bilancia algebrica mantiene uguali i due membri solo se ogni trasformazione è applicata da entrambe le parti.
Richiesta: risolvi e verifica ${equation} attraverso quattro decisioni guidate.
Formato risposta: scegli una tessera a ogni passaggio; la soluzione finale è un numero intero.`,
      answer: root,
      hints: [
        "Un'equazione è una bilancia: ciò che fai a sinistra va fatto anche a destra.",
        `Annulla prima il termine +${addend} usando l'operazione inversa.`,
        `Quando resta ${coefficient}x, dividi entrambi i membri per ${coefficient}.`
      ],
      archetype: "equazione-primo-grado",
      curriculumTags: ["equazioni di primo grado", "principi di equivalenza", "operazioni inverse", "verifica"],
      solutionSteps: [
        equation,
        `${coefficient}x = ${total} - ${addend} = ${afterSubtract}`,
        `x = ${afterSubtract} : ${coefficient} = ${root}`,
        `verifica: ${coefficient} · ${root} + ${addend} = ${total}`
      ],
      competencies: ["matematica.equazioni", "matematica.algebra", "matematica.controlloErrore", "problemSolving"],
      equationLab: {
        degree: 1,
        equation,
        coefficients: { a: coefficient, b: addend - total, c: 0 },
        roots: [root],
        principle: "I principi di equivalenza permettono di trasformare un'equazione senza cambiarne le soluzioni.",
        verification: `${coefficient} · ${root} + ${addend} = ${total}`,
        stages
      }
    };
  }
  buildBeaconLineWorkshop(random, difficulty) {
    const beginner = difficulty.mathComplexity <= 2;
    const m = beginner ? random.pick([-2, -1, 1, 2]) : random.pick([-3, -2, -1, 1, 2, 3]);
    const q = beginner ? random.integer(-2, 2) : random.integer(-4, 4);
    const firstX = beginner ? 0 : random.pick([-3, -2, -1]);
    const secondX = beginner ? random.pick([1, 2]) : random.pick([1, 2, 3]);
    const slopeLimit = beginner ? 2 : 3;
    const interceptLimit = beginner ? 3 : 5;
    const initialM = this.shiftedInitial(random, m, -slopeLimit, slopeLimit, m === 0 ? 1 : 0);
    const initialQ = this.shiftedInitial(random, q, -interceptLimit, interceptLimit);
    return {
      mode: "beacon-line",
      functionKind: "linear",
      objective: `Regola pendenza e intercetta finché la retta attraversa entrambi i beacon A e B.`,
      targetFormula: this.linearFormula(m, q),
      principle: "In y = mx + q, m controlla inclinazione e verso; q è il punto in cui la retta incontra l'asse y.",
      parameters: [
        { key: "m", label: "m", meaning: "pendenza: variazione verticale per ogni passo orizzontale", min: -slopeLimit, max: slopeLimit, step: 1, target: m, initial: initialM },
        { key: "q", label: "q", meaning: "intercetta sull'asse y", min: -interceptLimit, max: interceptLimit, step: 1, target: q, initial: initialQ }
      ],
      targetPoints: [
        { x: firstX, y: m * firstX + q, label: "A" },
        { x: secondX, y: m * secondX + q, label: "B" }
      ],
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-14, 14],
      successExplanation: `La retta ${this.linearFormula(m, q)} attraversa entrambi i punti; la variazione tra A e B conferma m = ${m}.`
    };
  }
  buildVertexWorkshop(random, difficulty) {
    const a = difficulty.mathComplexity >= 6 ? random.pick([-2, -1, 1, 2]) : random.pick([-1, 1]);
    const h = random.integer(-3, 3);
    const k = random.integer(-4, 4);
    return {
      mode: "vertex-shift",
      functionKind: "quadratic",
      objective: `Porta il vertice sul portale V(${h}, ${k}) e fai attraversare la curva anche i due anelli guida simmetrici.`,
      targetFormula: this.quadraticVertexFormula(a, h, k),
      principle: "Nella forma y = a(x − h)² + k, il vertice è V(h,k); il segno di a decide se la parabola apre verso l'alto o verso il basso.",
      parameters: this.quadraticParameters(random, a, h, k, difficulty),
      targetPoints: [
        { x: h, y: k, label: "V" },
        { x: h - 1, y: k + a, label: "G₁" },
        { x: h + 1, y: k + a, label: "G₂" }
      ],
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-10, 10],
      successExplanation: `Il vertice è V(${h}, ${k}); a = ${a} determina ${a > 0 ? "apertura verso l'alto" : "apertura verso il basso"} e ampiezza della curva.`
    };
  }
  buildRootGateWorkshop(random, difficulty) {
    const a = difficulty.mathComplexity >= 7 ? random.pick([-2, -1, 1, 2]) : random.pick([-1, 1]);
    const h = random.integer(-2, 2);
    const distance = random.integer(1, 3);
    const k = -a * distance * distance;
    const leftRoot = h - distance;
    const rightRoot = h + distance;
    return {
      mode: "root-gates",
      functionKind: "quadratic",
      objective: `Fai attraversare alla parabola le porte R₁ e R₂ e colloca il vertice sul nucleo V(${h}, ${k}).`,
      targetFormula: this.quadraticVertexFormula(a, h, k),
      principle: "Le radici sono i punti in cui y = 0. Nella forma col vertice, spostare h muove entrambe le radici; modificare k le avvicina o le allontana dall'asse x.",
      parameters: this.quadraticParameters(random, a, h, k, difficulty, Math.max(5, Math.abs(k))),
      targetPoints: [
        { x: leftRoot, y: 0, label: "R₁" },
        { x: rightRoot, y: 0, label: "R₂" },
        { x: h, y: k, label: "V" }
      ],
      showTargetCurve: false,
      xRange: [-6, 6],
      yRange: [-Math.max(12, Math.abs(k) + 3), Math.max(12, Math.abs(k) + 3)],
      successExplanation: `Con ${this.quadraticVertexFormula(a, h, k)}, ponendo y = 0 si ottengono x = ${leftRoot} e x = ${rightRoot}.`
    };
  }
  buildCurveMatchWorkshop(random, difficulty) {
    const quadratic = difficulty.mathComplexity >= 5 && random.bool(0.7);
    if (!quadratic) {
      const m = random.pick([-3, -2, -1, 1, 2, 3]);
      const q = random.integer(-4, 4);
      return {
        mode: "curve-match",
        functionKind: "linear",
        objective: "Sovrapponi la retta attiva alla traccia fantasma usando m e q. Osserva separatamente inclinazione e altezza.",
        targetFormula: this.linearFormula(m, q),
        principle: "Due rette coincidono solo se hanno la stessa pendenza e la stessa intercetta.",
        parameters: [
          { key: "m", label: "m", meaning: "pendenza della retta", min: -3, max: 3, step: 1, target: m, initial: this.shiftedInitial(random, m, -3, 3, 1) },
          { key: "q", label: "q", meaning: "intercetta verticale", min: -5, max: 5, step: 1, target: q, initial: this.shiftedInitial(random, q, -5, 5) }
        ],
        targetPoints: [{ x: 0, y: q, label: "q" }],
        showTargetCurve: true,
        xRange: [-6, 6],
        yRange: [-10, 10],
        successExplanation: `Stessa pendenza m = ${m} e stessa intercetta q = ${q}: le rette coincidono in ogni punto.`
      };
    }
    const a = random.pick([-2, -1, 1, 2]);
    const h = random.integer(-3, 3);
    const k = random.integer(-4, 4);
    return {
      mode: "curve-match",
      functionKind: "quadratic",
      objective: "Sovrapponi la parabola attiva alla traccia fantasma regolando apertura, asse di simmetria e quota del vertice.",
      targetFormula: this.quadraticVertexFormula(a, h, k),
      principle: "Due parabole nella forma y = a(x − h)² + k coincidono quando condividono apertura a e vertice V(h,k).",
      parameters: this.quadraticParameters(random, a, h, k, difficulty),
      targetPoints: [{ x: h, y: k, label: "V" }],
      showTargetCurve: true,
      xRange: [-6, 6],
      yRange: [-12, 12],
      successExplanation: `La curva attiva ha raggiunto a = ${a}, h = ${h}, k = ${k}: forma, asse e vertice coincidono con la traccia.`
    };
  }
  quadraticParameters(random, a, h, k, difficulty, verticalLimit = 6) {
    const aValues = difficulty.mathComplexity >= 6 ? [-2, -1, 1, 2] : [-1, 1];
    const initialA = random.pick(aValues.filter((value) => value !== a));
    return [
      { key: "a", label: "a", meaning: "verso e apertura della parabola", min: -2, max: 2, step: 1, target: a, initial: initialA },
      { key: "h", label: "h", meaning: "asse di simmetria x = h", min: -4, max: 4, step: 1, target: h, initial: this.shiftedInitial(random, h, -4, 4) },
      { key: "k", label: "k", meaning: "altezza del vertice", min: -verticalLimit, max: verticalLimit, step: 1, target: k, initial: this.shiftedInitial(random, k, -verticalLimit, verticalLimit) }
    ];
  }
  graphWorkshopHints(workshop) {
    if (workshop.mode === "beacon-line") {
      const [first, second] = workshop.targetPoints;
      return [
        `Calcola la pendenza osservando i beacon: Δy/Δx = (${second.y} − ${first.y}) / (${second.x} − ${first.x}).`,
        "Dopo aver regolato m, usa q per traslare la retta senza cambiarne l'inclinazione.",
        "Controlla entrambi i beacon: attraversarne uno solo non determina una retta unica."
      ];
    }
    if (workshop.mode === "root-gates") {
      return [
        "Le due radici sono simmetriche rispetto alla verticale x = h: trova prima il loro punto medio.",
        "Regola k finché la curva raggiunge l'asse x esattamente sulle due porte.",
        "Il segno di a deve rispettare il verso di apertura; |a| cambia quanto la curva è stretta."
      ];
    }
    if (workshop.mode === "vertex-shift") {
      return [
        "h muove il vertice a destra o sinistra; k lo muove in alto o in basso.",
        "Il segno di a inverte la parabola; il suo valore assoluto modifica l'apertura.",
        "Modifica un parametro alla volta e osserva quale proprietà resta invariata."
      ];
    }
    return [
      "Allinea prima il punto notevole: intercetta per la retta, vertice per la parabola.",
      "Poi correggi l'inclinazione o l'apertura senza perdere l'allineamento raggiunto.",
      "La sovrapposizione completa richiede gli stessi parametri, non solo un punto in comune."
    ];
  }
  shiftedInitial(random, target, min, max, fallbackDelta = 1) {
    const candidates = [-3, -2, -1, 1, 2, 3].map((delta) => target + delta).filter((value) => value >= min && value <= max && value !== target);
    return candidates.length > 0 ? random.pick(candidates) : clampNumber(target + fallbackDelta, min, max);
  }
  linearFormula(m, q) {
    const slope = m === 1 ? "x" : m === -1 ? "−x" : `${m}x`;
    const intercept = q === 0 ? "" : q > 0 ? ` + ${q}` : ` − ${Math.abs(q)}`;
    return `y = ${slope}${intercept}`;
  }
  quadraticVertexFormula(a, h, k) {
    const leading = a === 1 ? "" : a === -1 ? "−" : `${a}`;
    const horizontal = h === 0 ? "x" : h > 0 ? `(x − ${h})` : `(x + ${Math.abs(h)})`;
    const vertical = k === 0 ? "" : k > 0 ? ` + ${k}` : ` − ${Math.abs(k)}`;
    return `y = ${leading}${horizontal}²${vertical}`;
  }
  buildQuadraticEquationLab(random, difficulty) {
    const solutionMode = difficulty.mathComplexity >= 8 ? random.pick(["two", "two", "double", "none"]) : random.pick(["two", "two", "double"]);
    const leading = difficulty.mathComplexity >= 7 && random.bool(0.35) ? 2 : 1;
    let roots = [];
    let b = 0;
    let c = 0;
    if (solutionMode === "two") {
      const first = random.integer(1, 5 + Math.floor(difficulty.mathComplexity / 2));
      let second = random.integer(1, 7 + Math.floor(difficulty.mathComplexity / 2));
      if (second === first) second += 2;
      roots = [Math.min(first, second), Math.max(first, second)];
      b = -leading * (roots[0] + roots[1]);
      c = leading * roots[0] * roots[1];
    } else if (solutionMode === "double") {
      const root = random.integer(2, 7);
      roots = [root];
      b = -2 * leading * root;
      c = leading * root * root;
    } else {
      const vertexX = random.integer(1, 4);
      const lift = random.integer(1, 5);
      b = -2 * leading * vertexX;
      c = leading * vertexX * vertexX + lift;
    }
    const discriminant = b * b - 4 * leading * c;
    const equation = `${this.term(leading, "x²", true)} ${this.term(b, "x")} ${this.term(c, "")} = 0`.replace(/\s+/g, " ").trim();
    const solutionLabel = roots.length === 0 ? "Nessuna soluzione reale" : roots.length === 1 ? `x = ${roots[0]}` : `x₁ = ${roots[0]}, x₂ = ${roots[1]}`;
    const factorization = roots.length === 2 ? `${leading === 1 ? "" : `${leading}`}·(x - ${roots[0]})(x - ${roots[1]}) = 0` : roots.length === 1 ? `${leading === 1 ? "" : `${leading}`}·(x - ${roots[0]})² = 0` : "La parabola non incontra l'asse x";
    const deltaClass = discriminant > 0 ? "Δ > 0: due soluzioni reali distinte" : discriminant === 0 ? "Δ = 0: una soluzione reale doppia" : "Δ < 0: nessuna soluzione reale";
    const stages = [
      {
        id: "quadratic-standard",
        title: "1 · Riconosci la struttura",
        prompt: `Nell'equazione ${equation}, quali sono i coefficienti a, b e c?`,
        options: random.shuffle([
          `a = ${leading}, b = ${b}, c = ${c}`,
          `a = ${b}, b = ${leading}, c = ${c}`,
          `a = ${leading}, b = ${c}, c = ${b}`,
          `a = 1, b = ${Math.abs(b)}, c = ${Math.abs(c)}`
        ]),
        correctOption: `a = ${leading}, b = ${b}, c = ${c}`,
        explanation: "La forma standard è ax² + bx + c = 0. I segni fanno parte dei coefficienti.",
        visual: "standard-form"
      },
      {
        id: "quadratic-delta",
        title: "2 · Calcola il discriminante",
        prompt: `Quanto vale Δ = b² - 4ac per questa equazione?`,
        options: random.shuffle([`${discriminant}`, `${b * b + 4 * leading * c}`, `${Math.abs(b) - 4 * leading * c}`, `${b * b - 2 * leading * c}`]),
        correctOption: `${discriminant}`,
        explanation: `Δ = (${b})² - 4·${leading}·${c} = ${b * b} - ${4 * leading * c} = ${discriminant}.`,
        visual: "discriminant"
      },
      {
        id: "quadratic-count",
        title: "3 · Prevedi quante soluzioni",
        prompt: `Cosa indica Δ = ${discriminant}?`,
        options: random.shuffle([
          deltaClass,
          "Δ > 0: nessuna soluzione reale",
          "Δ = 0: due soluzioni reali distinte",
          "Il discriminante non dice nulla sulle soluzioni"
        ]),
        correctOption: deltaClass,
        explanation: "Il segno del discriminante anticipa quante volte la parabola incontra l'asse x.",
        visual: "parabola"
      },
      {
        id: "quadratic-solve",
        title: "4 · Trova le radici",
        prompt: "Qual è l'insieme delle soluzioni reali?",
        options: random.shuffle([
          solutionLabel,
          roots.length === 2 ? `x₁ = ${-roots[0]}, x₂ = ${-roots[1]}` : `x = ${Math.abs(b)}`,
          roots.length === 1 ? `x = ${-roots[0]}` : "x = 0",
          roots.length === 0 ? "x = 1 e x = -1" : "Nessuna soluzione reale"
        ]),
        correctOption: solutionLabel,
        explanation: roots.length === 0 ? `Poiché Δ = ${discriminant} è negativo, √Δ non è reale: la parabola resta sopra l'asse x.` : `Con x = (-b ± √Δ)/(2a) ottieni ${solutionLabel}.`,
        visual: roots.length > 0 ? "formula" : "parabola"
      },
      {
        id: "quadratic-meaning",
        title: "5 · Collega algebra e grafico",
        prompt: "Quale descrizione grafica è coerente con le soluzioni trovate?",
        options: random.shuffle([
          roots.length === 2 ? `La parabola taglia l'asse x in ${roots[0]} e ${roots[1]}` : roots.length === 1 ? `La parabola è tangente all'asse x in ${roots[0]}` : "La parabola non interseca l'asse x",
          "La parabola coincide sempre con l'asse x",
          "Le radici indicano le intersezioni con l'asse y",
          "Il coefficiente c indica sempre il numero di radici"
        ]),
        correctOption: roots.length === 2 ? `La parabola taglia l'asse x in ${roots[0]} e ${roots[1]}` : roots.length === 1 ? `La parabola è tangente all'asse x in ${roots[0]}` : "La parabola non interseca l'asse x",
        explanation: `Le soluzioni di f(x)=0 sono le ascisse dei punti in cui il grafico incontra l'asse x. ${factorization}.`,
        visual: "parabola"
      }
    ];
    return {
      id: `math-equation-lab-quadratic-${leading}-${b}-${c}`,
      title: "Laboratorio equazioni · Parabola e radici",
      prompt: `Situazione: il sistema visualizza un'equazione di secondo grado come formula e come parabola.
Richiesta: riconosci coefficienti, discriminante, numero di soluzioni e radici di ${equation}.
Formato risposta: scegli una tessera a ogni passaggio; possono esistere zero, una o due soluzioni reali.`,
      answer: roots[0] ?? 0,
      hints: [
        "Porta l'equazione nella forma ax² + bx + c = 0 e conserva i segni.",
        "Calcola prima Δ = b² - 4ac: il suo segno dice quante soluzioni reali aspettarti.",
        "Le radici sono le ascisse delle intersezioni della parabola con l'asse x."
      ],
      archetype: "equazione-secondo-grado",
      curriculumTags: ["equazioni di secondo grado", "discriminante", "formula risolutiva", "parabola", "radici"],
      solutionSteps: [
        `a = ${leading}, b = ${b}, c = ${c}`,
        `Δ = (${b})² - 4·${leading}·${c} = ${discriminant}`,
        deltaClass,
        solutionLabel,
        factorization
      ],
      competencies: ["matematica.equazioni", "matematica.algebra", "matematica.funzioni", "matematica.grafici", "problemSolving"],
      equationLab: {
        degree: 2,
        equation,
        coefficients: { a: leading, b, c },
        roots,
        discriminant,
        principle: "Il discriminante collega la forma algebrica al numero di intersezioni della parabola con l'asse x.",
        verification: roots.length > 0 ? roots.map((root) => `f(${root}) = ${leading * root * root + b * root + c}`).join("; ") : `Vertice sopra l'asse x e Δ = ${discriminant} < 0`,
        stages
      }
    };
  }
  term(value, symbol, first = false) {
    if (value === 0) return "";
    const sign = value < 0 ? "-" : first ? "" : "+";
    const magnitude = Math.abs(value);
    const coefficient = symbol && magnitude === 1 ? "" : `${magnitude}`;
    return `${sign}${coefficient}${symbol}`;
  }
  uniquePrompt(random, difficulty, type, index, previousSignature) {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const prompt = this.buildPrompt(random, difficulty, type, index + attempt);
      if (prompt.signature !== previousSignature) {
        return prompt;
      }
    }
    return this.buildPrompt(random, difficulty, type, index + 99);
  }
  buildPrompt(random, difficulty, type, index) {
    if (type === "target-sum") {
      return this.buildTargetSumPrompt(random, difficulty, index);
    }
    if (type === "factor-hunt") {
      return this.buildFactorHuntPrompt(random, difficulty, index);
    }
    return this.buildOperationChainPrompt(random, difficulty, index);
  }
  buildTargetSumPrompt(random, difficulty, index) {
    const required = difficulty.level >= 5 ? 3 : 2;
    const min = 4 + difficulty.level;
    const max = 13 + difficulty.level * 4;
    for (let attempt = 0; attempt < 24; attempt += 1) {
      const correctValues = this.uniqueNumbers(random, required, min, max);
      const target = correctValues.reduce((sum, value) => sum + value, 0);
      const distractors = this.uniqueNumbers(random, 7 - required, Math.max(2, min - 3), max + 8).filter((value) => !correctValues.includes(value) && value !== target);
      const allValues = [...correctValues, ...distractors].slice(0, 7);
      if (this.hasAlternativeSum(allValues, target, required, correctValues)) {
        continue;
      }
      const tiles = this.shuffleTiles(random, allValues.map((value, tileIndex) => ({
        id: `sum-${index}-${tileIndex}`,
        label: `${value}`,
        value,
        isCorrect: correctValues.includes(value),
        feedback: correctValues.includes(value) ? `${value} appartiene alla somma esatta.` : `${value} porta fuori bersaglio.`
      })));
      return {
        id: `target-sum-${index}`,
        type: "target-sum",
        prompt: `Carica il nucleo a ${target}: scegli ${required} tessere la cui somma sia esatta.`,
        targetLabel: `Bersaglio ${target}`,
        requiredSelectionCount: required,
        tiles,
        solutionLabels: correctValues.map(String),
        explanation: `${correctValues.join(" + ")} = ${target}. I distrattori sono vicini, ma cambiano la somma finale.`,
        concept: required === 2 ? "scomposizione di una somma" : "somma a tre addendi con controllo intermedio",
        signature: `sum-${target}-${correctValues.join("-")}`
      };
    }
    return this.simpleTargetSumFallback(index);
  }
  buildFactorHuntPrompt(random, difficulty, index) {
    const useMultiples = random.bool(0.58);
    if (useMultiples) {
      const base = random.pick([3, 4, 5, 6, 7, 8, 9]);
      const correctValues2 = this.uniqueNumbers(random, 3 + (difficulty.level >= 6 ? 1 : 0), 2, 8).map((factor) => factor * base);
      const distractors2 = this.uniqueNumbers(random, 7 - correctValues2.length, base + 1, base * 9 + 5).filter((value) => value % base !== 0 && !correctValues2.includes(value));
      const values2 = [...correctValues2, ...distractors2].slice(0, 7);
      const tiles2 = this.shuffleTiles(random, values2.map((value, tileIndex) => ({
        id: `multiple-${index}-${tileIndex}`,
        label: `${value}`,
        value,
        isCorrect: value % base === 0,
        feedback: value % base === 0 ? `${value} è divisibile per ${base}.` : `${value} lascia resto nella divisione per ${base}.`
      })));
      return {
        id: `factor-hunt-m-${index}`,
        type: "factor-hunt",
        prompt: `Il filtro accetta solo multipli di ${base}. Seleziona tutti quelli validi.`,
        targetLabel: `Multipli di ${base}`,
        requiredSelectionCount: tiles2.filter((tile) => tile.isCorrect).length,
        tiles: tiles2,
        solutionLabels: values2.filter((value) => value % base === 0).map(String),
        explanation: `Un multiplo di ${base} si ottiene moltiplicando ${base} per un numero intero.`,
        concept: "multipli e divisibilità",
        signature: `multiple-${base}-${values2.join("-")}`
      };
    }
    const target = random.pick([18, 24, 30, 36, 42, 48, 60, 72]);
    const divisorPool = Array.from({ length: target }, (_, i) => i + 1).filter((value) => target % value === 0 && value > 1 && value < target);
    const correctValues = random.shuffle(divisorPool).slice(0, difficulty.level >= 6 ? 4 : 3);
    const distractors = this.uniqueNumbers(random, 7 - correctValues.length, 2, Math.min(30, target - 1)).filter((value) => target % value !== 0 && !correctValues.includes(value));
    const values = [...correctValues, ...distractors].slice(0, 7);
    const tiles = this.shuffleTiles(random, values.map((value, tileIndex) => ({
      id: `divisor-${index}-${tileIndex}`,
      label: `${value}`,
      value,
      isCorrect: target % value === 0,
      feedback: target % value === 0 ? `${value} divide ${target} senza resto.` : `${value} non divide ${target} in parti intere.`
    })));
    return {
      id: `factor-hunt-d-${index}`,
      type: "factor-hunt",
      prompt: `Il divisore centrale è ${target}. Seleziona tutti i divisori mostrati.`,
      targetLabel: `Divisori di ${target}`,
      requiredSelectionCount: tiles.filter((tile) => tile.isCorrect).length,
      tiles,
      solutionLabels: values.filter((value) => target % value === 0).map(String),
      explanation: `Un divisore entra in ${target} un numero intero di volte: nessun resto.`,
      concept: "divisori e controllo del resto",
      signature: `divisor-${target}-${values.join("-")}`
    };
  }
  buildOperationChainPrompt(random, difficulty, index) {
    const twoSteps = difficulty.level >= 4;
    const start = random.integer(3 + difficulty.level, 14 + difficulty.level * 3);
    const operations = [
      { label: "+ 6", apply: (value) => value + 6 },
      { label: "- 4", apply: (value) => value - 4 },
      { label: "x 2", apply: (value) => value * 2 },
      { label: "x 3", apply: (value) => value * 3 },
      { label: ": 2", apply: (value) => Math.floor(value / 2), valid: (value) => value % 2 === 0 },
      { label: ": 3", apply: (value) => Math.floor(value / 3), valid: (value) => value % 3 === 0 }
    ];
    const validFirst = operations.filter((operation) => !operation.valid || operation.valid(start));
    const first = random.pick(validFirst);
    const mid = first.apply(start);
    const validSecond = operations.filter((operation) => !operation.valid || operation.valid(mid));
    const second = twoSteps ? random.pick(validSecond) : void 0;
    const target = second ? second.apply(mid) : mid;
    const correctLabel = second ? `${first.label} poi ${second.label}` : first.label;
    const distractors = random.shuffle(operations).filter((operation) => operation.label !== first.label).map((operation) => {
      const label = twoSteps ? `${operation.label} poi ${random.pick(operations).label}` : operation.label;
      return label;
    }).filter((label) => label !== correctLabel).slice(0, 5);
    const labels = random.shuffle([correctLabel, ...distractors]).slice(0, 6);
    const tiles = labels.map((label, tileIndex) => ({
      id: `operation-${index}-${tileIndex}`,
      label,
      isCorrect: label === correctLabel,
      feedback: label === correctLabel ? `Da ${start} arrivi a ${target}.` : "Questa rotta cambia troppo o troppo poco il valore."
    }));
    return {
      id: `operation-chain-${index}`,
      type: "operation-chain",
      prompt: `Ingresso ${start}, uscita richiesta ${target}. Quale rotta di operazioni certifica il passaggio?`,
      targetLabel: `${start} -> ${target}`,
      requiredSelectionCount: 1,
      tiles,
      solutionLabels: [correctLabel],
      explanation: second ? `${start} ${first.label} = ${mid}; poi ${mid} ${second.label} = ${target}.` : `${start} ${first.label} = ${target}.`,
      concept: twoSteps ? "due trasformazioni ordinate" : "trasformazione singola",
      signature: `op-${start}-${correctLabel}-${target}`
    };
  }
  shuffleTiles(random, tiles) {
    return random.shuffle(tiles).map((tile, index) => ({ ...tile, id: `${tile.id}-${index}` }));
  }
  uniqueNumbers(random, count, min, max) {
    const values = /* @__PURE__ */ new Set();
    let guard = 0;
    while (values.size < count && guard < 80) {
      values.add(random.integer(min, max));
      guard += 1;
    }
    return [...values];
  }
  hasAlternativeSum(values, target, count, intended) {
    const intendedKey = [...intended].sort((a, b) => a - b).join(",");
    const scan = (start, chosen) => {
      if (chosen.length === count) {
        const sum = chosen.reduce((total, value) => total + value, 0);
        const key = [...chosen].sort((a, b) => a - b).join(",");
        return sum === target && key !== intendedKey;
      }
      for (let index = start; index < values.length; index += 1) {
        if (scan(index + 1, [...chosen, values[index]])) {
          return true;
        }
      }
      return false;
    };
    return scan(0, []);
  }
  simpleTargetSumFallback(index) {
    const tiles = [
      { id: `fallback-${index}-1`, label: "8", value: 8, isCorrect: true, feedback: "Parte della somma." },
      { id: `fallback-${index}-2`, label: "11", value: 11, isCorrect: true, feedback: "Parte della somma." },
      { id: `fallback-${index}-3`, label: "9", value: 9, isCorrect: false, feedback: "Porta fuori bersaglio." },
      { id: `fallback-${index}-4`, label: "13", value: 13, isCorrect: false, feedback: "Porta fuori bersaglio." }
    ];
    return {
      id: `target-sum-fallback-${index}`,
      type: "target-sum",
      prompt: "Carica il nucleo a 19: scegli 2 tessere la cui somma sia esatta.",
      targetLabel: "Bersaglio 19",
      requiredSelectionCount: 2,
      tiles,
      solutionLabels: ["8", "11"],
      explanation: "8 + 11 = 19.",
      concept: "scomposizione di una somma",
      signature: `sum-fallback-${index}`
    };
  }
  answerProxy(prompt) {
    var _a2;
    if (prompt.type === "operation-chain") {
      const parts = prompt.targetLabel.split("->");
      const target = Number((_a2 = parts[parts.length - 1]) == null ? void 0 : _a2.trim());
      return Number.isFinite(target) ? Math.max(0, Math.min(9999, target)) : 0;
    }
    const total = prompt.tiles.filter((tile) => tile.isCorrect).reduce((sum, tile) => sum + (tile.value ?? 0), 0);
    return Math.max(0, Math.min(9999, total));
  }
}
const diatonicNotes = [
  { name: "Do", octave: 2, treblePosition: 24, bassPosition: 12 },
  { name: "Re", octave: 2, treblePosition: 23, bassPosition: 11 },
  { name: "Mi", octave: 2, treblePosition: 22, bassPosition: 10 },
  { name: "Fa", octave: 2, treblePosition: 21, bassPosition: 9 },
  { name: "Sol", octave: 2, treblePosition: 20, bassPosition: 8 },
  { name: "La", octave: 2, treblePosition: 19, bassPosition: 7 },
  { name: "Si", octave: 2, treblePosition: 18, bassPosition: 6 },
  { name: "Do", octave: 3, treblePosition: 17, bassPosition: 5 },
  { name: "Re", octave: 3, treblePosition: 16, bassPosition: 4 },
  { name: "Mi", octave: 3, treblePosition: 15, bassPosition: 3 },
  { name: "Fa", octave: 3, treblePosition: 14, bassPosition: 2 },
  { name: "Sol", octave: 3, treblePosition: 13, bassPosition: 1 },
  { name: "La", octave: 3, treblePosition: 12, bassPosition: 0 },
  { name: "Si", octave: 3, treblePosition: 11, bassPosition: -1 },
  { name: "Do", octave: 4, treblePosition: 10, bassPosition: -2 },
  { name: "Re", octave: 4, treblePosition: 9, bassPosition: -3 },
  { name: "Mi", octave: 4, treblePosition: 8, bassPosition: -4 },
  { name: "Fa", octave: 4, treblePosition: 7, bassPosition: -5 },
  { name: "Sol", octave: 4, treblePosition: 6, bassPosition: -6 },
  { name: "La", octave: 4, treblePosition: 5, bassPosition: -7 },
  { name: "Si", octave: 4, treblePosition: 4, bassPosition: -8 },
  { name: "Do", octave: 5, treblePosition: 3, bassPosition: -9 },
  { name: "Re", octave: 5, treblePosition: 2, bassPosition: -10 },
  { name: "Mi", octave: 5, treblePosition: 1, bassPosition: -11 },
  { name: "Fa", octave: 5, treblePosition: 0, bassPosition: -12 },
  { name: "Sol", octave: 5, treblePosition: -1, bassPosition: -13 }
];
class MusicNoteGenerator {
  generate(random, difficultyLevel = 1, preferredModes = []) {
    const available = difficultyLevel <= 1 ? ["note-hunt", "rhythm-gap"] : ["note-hunt", "interval-jump", "rhythm-gap"];
    const requested = preferredModes.filter((mode2) => available.includes(mode2) || preferredModes.length === 1);
    const mode = random.pick(requested.length > 0 ? requested : available);
    if (mode === "interval-jump") return this.buildIntervalJump(random, difficultyLevel);
    if (mode === "rhythm-gap") return this.buildRhythmGap(random, difficultyLevel);
    return this.buildNoteHunt(random, difficultyLevel);
  }
  buildNoteHunt(random, difficultyLevel) {
    const clef = this.pickClef(random, difficultyLevel);
    const note = random.pick(this.notePool(difficultyLevel, clef));
    const staffPosition = clef === "treble" ? note.treblePosition : note.bassPosition;
    const answerMode = difficultyLevel >= 7 ? "note-and-octave" : "note-name";
    const choices = this.buildChoices(random, note, clef, staffPosition, answerMode);
    return {
      id: `music-${clef}-${note.name.toLowerCase()}${note.octave}-${staffPosition}`,
      title: "Caccia alla nota",
      challengeMode: "note-hunt",
      clef,
      noteName: note.name,
      octave: note.octave,
      staffPosition,
      ledgerLines: this.ledgerLinesFor(staffPosition),
      timeLimitMs: this.timeLimitMs(difficultyLevel, this.outsideStaffDistance(staffPosition)),
      answerMode,
      choices,
      hints: this.hintsFor(clef, staffPosition, note),
      competencies: ["musica.pentagramma", `musica.${clef === "treble" ? "chiaveViolino" : "chiaveBasso"}`, "musica.letturaNote"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - ${this.levelName(difficultyLevel)}`,
      learningPurpose: answerMode === "note-name" ? "Riconoscere rapidamente il nome della nota sul pentagramma." : "Riconoscere rapidamente nome e registro della nota, includendo l'ottava.",
      method: clef === "treble" ? "In chiave di violino parti dal Sol sulla seconda linea o dal Do centrale sotto il pentagramma, poi conta linee e spazi." : "In chiave di basso parti dal Fa sulla quarta linea o dal Do centrale sopra il pentagramma, poi conta linee e spazi.",
      methodSteps: answerMode === "note-name" ? ["chiave", "nota guida", "linea/spazio", "nome nota"] : ["chiave", "nota guida", "linee addizionali", "nome + ottava"],
      conceptTags: [
        clef === "treble" ? "chiave di violino" : "chiave di basso",
        this.ledgerLinesFor(staffPosition).length > 0 ? "linee addizionali" : "pentagramma",
        this.isStaffLine(staffPosition) ? "linea" : "spazio"
      ]
    };
  }
  buildIntervalJump(random, difficultyLevel) {
    const clef = this.pickClef(random, difficultyLevel);
    const pool = this.notePool(difficultyLevel, clef);
    const maxDistance = Math.min(difficultyLevel >= 6 ? 5 : difficultyLevel >= 3 ? 4 : 2, Math.max(1, pool.length - 1));
    let first = random.pick(pool);
    let second = first;
    for (let attempt = 0; attempt < 16 && second === first; attempt += 1) {
      const firstIndex = pool.indexOf(first);
      const distance = random.integer(1, maxDistance);
      const direction2 = random.bool() ? 1 : -1;
      const targetIndex = firstIndex + direction2 * distance;
      if (targetIndex >= 0 && targetIndex < pool.length) second = pool[targetIndex];
      else first = random.pick(pool);
    }
    if (second === first) second = pool[first === pool[0] ? 1 : pool.indexOf(first) - 1];
    const firstPosition = clef === "treble" ? first.treblePosition : first.bassPosition;
    const secondPosition = clef === "treble" ? second.treblePosition : second.bassPosition;
    const steps = Math.abs(diatonicNotes.indexOf(second) - diatonicNotes.indexOf(first));
    const direction = diatonicNotes.indexOf(second) > diatonicNotes.indexOf(first) ? "Sale" : "Scende";
    const intervalNames = ["unisono", "seconda", "terza", "quarta", "quinta", "sesta"];
    const interval = intervalNames[Math.min(steps, intervalNames.length - 1)];
    const correct = `${direction}: ${interval}`;
    const alternatives = /* @__PURE__ */ new Set();
    alternatives.add(`${direction === "Sale" ? "Scende" : "Sale"}: ${interval}`);
    alternatives.add(`${direction}: ${intervalNames[Math.max(1, Math.min(5, steps + 1))]}`);
    alternatives.add(`${direction}: ${intervalNames[Math.max(1, steps - 1)]}`);
    alternatives.delete(correct);
    for (const label of ["Sale: seconda", "Scende: seconda", "Sale: quarta", "Scende: quarta"]) {
      if (alternatives.size >= 3) break;
      if (label !== correct) alternatives.add(label);
    }
    const choices = random.shuffle([
      { id: "correct", label: correct, isCorrect: true, feedback: `Corretto: la melodia ${direction.toLowerCase()} di ${interval}.` },
      ...[...alternatives].slice(0, 3).map((label, index) => ({
        id: `distractor-${index}`,
        label,
        isCorrect: false,
        feedback: `Confronta le due altezze: la seconda nota è ${secondPosition < firstPosition ? "più in alto" : "più in basso"} e la distanza è una ${interval}.`
      }))
    ]);
    return {
      id: `music-interval-${clef}-${first.name}${first.octave}-${second.name}${second.octave}`,
      title: "Salto melodico",
      challengeMode: "interval-jump",
      clef,
      noteName: first.name,
      octave: first.octave,
      staffPosition: firstPosition,
      ledgerLines: this.ledgerLinesFor(firstPosition),
      secondaryNote: { noteName: second.name, octave: second.octave, staffPosition: secondPosition, ledgerLines: this.ledgerLinesFor(secondPosition) },
      timeLimitMs: this.timeLimitMs(difficultyLevel, Math.max(this.outsideStaffDistance(firstPosition), this.outsideStaffDistance(secondPosition))),
      answerMode: "note-name",
      choices,
      hints: ["Guarda prima se la seconda nota sale o scende.", "Conta ogni passaggio linea-spazio: due nomi consecutivi formano una seconda.", `La risposta corretta usa direzione e distanza: ${correct}.`],
      competencies: ["musica.pentagramma", "musica.intervalli", "musica.ascoltoVisivo"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - intervalli melodici`,
      learningPurpose: "Riconoscere direzione e distanza tra due note, collegando pentagramma e movimento melodico.",
      method: "Confronta l'altezza delle due note, stabilisci la direzione, poi conta i nomi includendo partenza e arrivo.",
      methodSteps: ["prima nota", "direzione", "conta i gradi", "nomina intervallo"],
      conceptTags: ["melodia", "intervalli", direction.toLowerCase()]
    };
  }
  buildRhythmGap(random, difficultyLevel) {
    const beatsPerMeasure = difficultyLevel >= 5 && random.bool(0.35) ? 3 : 4;
    const allowed = difficultyLevel >= 4 ? [0.5, 1, 2] : [1, 2];
    const missingBeats = random.pick(allowed.filter((beats) => beats <= beatsPerMeasure - 1));
    let remaining = beatsPerMeasure - missingBeats;
    const durations = [];
    while (remaining > 0) {
      const candidates = allowed.filter((beats2) => beats2 <= remaining);
      const beats = random.pick(candidates);
      durations.push(beats);
      remaining -= beats;
    }
    const missingIndex = random.integer(0, durations.length);
    const complete = [...durations];
    complete.splice(missingIndex, 0, missingBeats);
    const cells = complete.map((beats, index) => ({ label: this.rhythmSymbol(beats), beats, missing: index === missingIndex }));
    const answerLabels = [0.5, 1, 2, 4].map((beats) => this.rhythmChoiceLabel(beats));
    const correct = this.rhythmChoiceLabel(missingBeats);
    const choices = random.shuffle(answerLabels.map((label, index) => ({
      id: label === correct ? "correct" : `distractor-${index}`,
      label,
      isCorrect: label === correct,
      feedback: label === correct ? `Corretto: mancavano ${missingBeats} ${missingBeats === 1 ? "battito" : "battiti"}. La battuta ora vale ${beatsPerMeasure}.` : `La battuta deve totalizzare ${beatsPerMeasure}: le figure visibili valgono ${beatsPerMeasure - missingBeats}, quindi mancano ${missingBeats}.`
    })));
    return {
      id: `music-rhythm-${beatsPerMeasure}-${complete.join("-")}-${missingIndex}`,
      title: "Battito mancante",
      challengeMode: "rhythm-gap",
      clef: "treble",
      noteName: "Do",
      octave: 4,
      staffPosition: 10,
      ledgerLines: [],
      rhythmPattern: { beatsPerMeasure, missingBeats, cells },
      timeLimitMs: Math.max(8e3, 16e3 - difficultyLevel * 900),
      answerMode: "note-name",
      choices,
      hints: ["Conta prima i battiti già visibili.", "Semiminima = 1, minima = 2, croma = mezzo battito.", `La battuta deve arrivare esattamente a ${beatsPerMeasure} battiti.`],
      competencies: ["musica.ritmo", "musica.durate", "matematica.frazioni"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - ritmo e durate`,
      learningPurpose: "Completare una battuta usando valore delle figure, somma e percezione della pulsazione.",
      method: `Somma le figure visibili e sottrai il totale da ${beatsPerMeasure}: il risultato è la durata mancante.`,
      methodSteps: ["leggi il metro", "somma le durate", "trova quanto manca", "chiudi la battuta"],
      conceptTags: ["ritmo", "durate", `${beatsPerMeasure}/4`]
    };
  }
  rhythmSymbol(beats) {
    return beats === 0.5 ? "♪" : beats === 1 ? "♩" : beats === 2 ? "𝅗𝅥" : "𝅝";
  }
  rhythmChoiceLabel(beats) {
    const unit = beats === 1 ? "battito" : "battiti";
    return `${this.rhythmSymbol(beats)}  ${beats === 0.5 ? "½" : beats} ${unit}`;
  }
  fallback(random, difficultyLevel = 1) {
    if (random) return this.generate(random, difficultyLevel);
    return this.generate({ pick: (items) => items[0], shuffle: (items) => [...items] }, difficultyLevel);
  }
  pickClef(random, level) {
    if (level <= 2) return "treble";
    if (level === 3) return random.bool(0.75) ? "treble" : "bass";
    return random.pick(["treble", "bass"]);
  }
  notePool(level, clef) {
    const position = (note) => clef === "treble" ? note.treblePosition : note.bassPosition;
    const ranges = {
      1: { min: 4, max: 8 },
      2: { min: 0, max: 8 },
      3: { min: 0, max: 8 },
      4: { min: -1, max: 9 },
      5: { min: -2, max: 10 },
      6: { min: -3, max: 11, preferOutside: true },
      7: { min: -4, max: 12, preferOutside: true },
      8: { min: -5, max: 13, preferOutside: true }
    };
    const range = ranges[level];
    const pool = diatonicNotes.filter((note) => {
      const pos = position(note);
      return pos >= range.min && pos <= range.max;
    });
    if (range.preferOutside) {
      const outside = pool.filter((note) => {
        const pos = position(note);
        return this.ledgerLinesFor(pos).length > 0;
      });
      if (outside.length > 0) return outside;
    }
    return pool;
  }
  outsideStaffDistance(position) {
    if (position < 0) return Math.abs(position);
    if (position > 8) return position - 8;
    return 0;
  }
  isStaffLine(position) {
    return position % 2 === 0;
  }
  buildChoices(random, note, clef, staffPosition, answerMode) {
    const correct = this.noteLabel(note, answerMode);
    const nearby = diatonicNotes.filter((candidate) => candidate !== note).map((candidate) => ({
      candidate,
      label: this.noteLabel(candidate, answerMode),
      distance: Math.abs((clef === "treble" ? candidate.treblePosition : candidate.bassPosition) - staffPosition)
    })).filter((item) => item.label !== correct).sort((a, b) => a.distance - b.distance).slice(0, 8);
    const picked = [];
    const usedLabels = /* @__PURE__ */ new Set([correct]);
    for (const item of random.shuffle(nearby)) {
      if (usedLabels.has(item.label)) continue;
      usedLabels.add(item.label);
      picked.push({ candidate: item.candidate, label: item.label });
      if (picked.length === 3) break;
    }
    const choices = [
      {
        id: "correct",
        label: correct,
        isCorrect: true,
        feedback: answerMode === "note-name" ? `Corretto: la nota è ${correct}. Hai riconosciuto la posizione sul pentagramma.` : `Corretto: la nota è ${correct}. Hai letto chiave, posizione e ottava.`
      },
      ...picked.map(({ candidate, label }, index) => ({
        id: `distractor-${index}`,
        label,
        isCorrect: false,
        feedback: this.feedbackFor(note, candidate, clef)
      }))
    ];
    return random.shuffle(choices);
  }
  feedbackFor(correct, picked, clef) {
    if (correct.name === picked.name && correct.octave !== picked.octave) {
      return `Nome giusto ma ottava sbagliata: in ${clef === "treble" ? "chiave di violino" : "chiave di basso"} devi contare anche le linee addizionali.`;
    }
    const correctPos = clef === "treble" ? correct.treblePosition : correct.bassPosition;
    const pickedPos = clef === "treble" ? picked.treblePosition : picked.bassPosition;
    return pickedPos < correctPos ? "Hai scelto una nota più alta: riconta verso il basso alternando linea e spazio." : "Hai scelto una nota più bassa: riconta verso l'alto alternando linea e spazio.";
  }
  noteLabel(note, answerMode) {
    return answerMode === "note-name" ? note.name : `${note.name} (ottava ${note.octave})`;
  }
  ledgerLinesFor(position) {
    const lines = [];
    if (position < 0) {
      for (let line = -2; line >= position; line -= 2) lines.push(line);
    }
    if (position > 8) {
      for (let line = 10; line <= position; line += 2) lines.push(line);
    }
    return lines;
  }
  hintsFor(clef, position, note) {
    const anchor = clef === "treble" ? "Sol4 sulla seconda linea dal basso" : "Fa3 sulla quarta linea dal basso";
    const direction = position < 0 ? "sopra il pentagramma" : position > 8 ? "sotto il pentagramma" : "dentro il pentagramma";
    return [
      `Prima guarda la chiave: il punto di riferimento è ${anchor}.`,
      `La nota è ${direction}: conta ogni passaggio linea-spazio senza saltare.`,
      "Controllo finale: nei livelli base scegli il nome della nota; nei livelli avanzati compare anche l'ottava.",
      "Se sei indecisa, riparti dalla nota guida della chiave e conta ogni riga/spazio senza saltare."
    ];
  }
  timeLimitMs(level, distance) {
    const base = Math.max(7500, 18e3 - level * 1200);
    const ledgerBonus = distance > 5 ? Math.min(4e3, (distance - 4) * 650) : 0;
    return base + ledgerBonus;
  }
  levelName(level) {
    if (level <= 2) return "note interne in chiave di violino";
    if (level <= 4) return "chiavi alternate e primi bordi";
    if (level <= 6) return "linee addizionali controllate";
    return "lettura rapida con ottave e linee estreme";
  }
}
const facings = ["N", "E", "S", "W"];
const deltas = {
  N: { col: 0, row: -1 },
  E: { col: 1, row: 0 },
  S: { col: 0, row: 1 },
  W: { col: -1, row: 0 }
};
class GridPathSolver {
  findCommandPath(cols, rows, start, target, obstacles, maxCommands = 48) {
    const obstacleKeys = new Set(obstacles.map((cell) => `${cell.col}:${cell.row}`));
    const queue = [{ state: start, commands: [] }];
    const visited = /* @__PURE__ */ new Set([this.key(start)]);
    while (queue.length > 0) {
      const current = queue.shift();
      if (!current) {
        break;
      }
      if (current.state.col === target.col && current.state.row === target.row) {
        return current.commands;
      }
      if (current.commands.length >= maxCommands) {
        continue;
      }
      for (const next of this.nextStates(current.state)) {
        if (next.state.col < 0 || next.state.row < 0 || next.state.col >= cols || next.state.row >= rows || obstacleKeys.has(`${next.state.col}:${next.state.row}`)) {
          continue;
        }
        const key = this.key(next.state);
        if (!visited.has(key)) {
          visited.add(key);
          queue.push({ state: next.state, commands: [...current.commands, next.command] });
        }
      }
    }
    return void 0;
  }
  nextStates(state) {
    const facingIndex = facings.indexOf(state.facing);
    const leftFacing = facings[(facingIndex + facings.length - 1) % facings.length];
    const rightFacing = facings[(facingIndex + 1) % facings.length];
    const delta = deltas[state.facing];
    return [
      { state: { ...state, facing: leftFacing }, command: "TURN_LEFT" },
      { state: { ...state, facing: rightFacing }, command: "TURN_RIGHT" },
      { state: { col: state.col + delta.col, row: state.row + delta.row, facing: state.facing }, command: "MOVE_FORWARD" }
    ];
  }
  simulate(start, commands) {
    return commands.reduce((state, command) => {
      if (command === "TURN_LEFT") {
        const facingIndex = facings.indexOf(state.facing);
        return { ...state, facing: facings[(facingIndex + facings.length - 1) % facings.length] };
      }
      if (command === "TURN_RIGHT") {
        const facingIndex = facings.indexOf(state.facing);
        return { ...state, facing: facings[(facingIndex + 1) % facings.length] };
      }
      if (command === "MOVE_FORWARD") {
        const delta = deltas[state.facing];
        return { ...state, col: state.col + delta.col, row: state.row + delta.row };
      }
      return state;
    }, start);
  }
  key(state) {
    return `${state.col}:${state.row}:${state.facing}`;
  }
}
class RobotGridGenerator {
  constructor() {
    __publicField(this, "solver", new GridPathSolver());
  }
  generate(random, difficulty, preferredType) {
    const cols = difficulty.robotGrid.cols;
    const rows = difficulty.robotGrid.rows;
    const challengeType = preferredType ?? this.pickChallengeType(random, difficulty);
    const minimumPathLength = 5 + difficulty.requiredReasoningSteps * 2 + (challengeType === "minimal-route" ? 2 : 0);
    for (let attempt = 0; attempt < 24; attempt += 1) {
      const layout = this.buildLayout(random.fork(`layout-${attempt}`), cols, rows, challengeType);
      const obstacles = this.buildObstacles(
        random.fork(`obstacles-${attempt}`),
        cols,
        rows,
        difficulty.robotObstacleCount,
        [layout.start, layout.key, layout.exit, ...layout.checkpoints]
      );
      const solutionCommands = this.solveRoute(cols, rows, layout.start, layout.key, layout.exit, obstacles, layout.checkpoints);
      if (!solutionCommands) {
        continue;
      }
      const enoughDepth = solutionCommands.length >= minimumPathLength || attempt >= 18;
      const enoughTurns = solutionCommands.filter((command) => command === "TURN_LEFT" || command === "TURN_RIGHT").length >= Math.min(4, difficulty.requiredReasoningSteps);
      if (enoughDepth && (enoughTurns || challengeType === "route-planning" || challengeType === "coordinate-routing")) {
        return this.buildPuzzle(cols, rows, layout.start, layout.key, layout.exit, obstacles, solutionCommands, difficulty, challengeType, layout.checkpoints, random);
      }
    }
    return this.fallback(challengeType, random.fork("fallback-layout"));
  }
  pickChallengeType(random, difficulty) {
    if (difficulty.level <= 2) {
      return random.pick(["route-planning", "minimal-route", "coordinate-routing"]);
    }
    if (difficulty.level <= 4) {
      return random.pick(["minimal-route", "checkpoint-order", "coordinate-routing", "debug-program"]);
    }
    if (difficulty.level <= 6) {
      return random.pick(["checkpoint-order", "debug-program", "pattern-routing", "conditional-gate", "minimal-route"]);
    }
    return random.pick(["debug-program", "pattern-routing", "loop-compression", "conditional-gate", "minimal-route", "coordinate-routing"]);
  }
  buildLayout(random, cols, rows, type) {
    const start = { col: 0, row: rows - 1, facing: random.pick(["N", "E"]) };
    const exit = { col: cols - 1, row: rows - 1 };
    const key = this.uniqueCell(
      { col: random.integer(Math.max(2, Math.floor(cols / 2)), cols - 1), row: random.integer(0, Math.max(1, Math.floor(rows / 2))) },
      cols,
      rows,
      [start, exit]
    );
    const checkpoints = this.checkpointsFor(random, cols, rows, type, [start, key, exit]);
    return { start, key, exit, checkpoints };
  }
  checkpointsFor(random, cols, rows, type, reserved) {
    if (type === "checkpoint-order") {
      const first = this.uniqueCell({ col: random.integer(1, Math.max(1, Math.floor(cols / 2))), row: random.integer(0, rows - 2) }, cols, rows, reserved);
      return [{ ...first, label: "A", order: 1 }];
    }
    if (type === "conditional-gate") {
      const first = this.uniqueCell({ col: random.integer(1, Math.max(1, Math.floor(cols / 2))), row: random.integer(0, rows - 2) }, cols, rows, reserved);
      const second = this.uniqueCell({ col: random.integer(Math.max(2, Math.floor(cols / 2)), cols - 2), row: random.integer(1, rows - 2) }, cols, rows, [...reserved, first]);
      return [
        { ...first, label: "S1", order: 1 },
        { ...second, label: "S2", order: 2 }
      ];
    }
    if (type === "pattern-routing" || type === "loop-compression") {
      const first = this.uniqueCell({ col: Math.max(1, Math.floor(cols / 3)), row: 1 }, cols, rows, reserved);
      const second = this.uniqueCell({ col: Math.min(cols - 2, Math.floor(cols * 2 / 3)), row: rows - 2 }, cols, rows, [...reserved, first]);
      return [
        { ...first, label: type === "loop-compression" ? "M1" : "A", order: 1 },
        { ...second, label: type === "loop-compression" ? "M2" : "B", order: 2 }
      ];
    }
    return [];
  }
  uniqueCell(candidate, cols, rows, reserved) {
    for (let radius = 0; radius < cols + rows; radius += 1) {
      for (let dc = -radius; dc <= radius; dc += 1) {
        const dr = radius - Math.abs(dc);
        for (const sign of [-1, 1]) {
          const cell = {
            col: Math.max(0, Math.min(cols - 1, candidate.col + dc)),
            row: Math.max(0, Math.min(rows - 1, candidate.row + dr * sign))
          };
          if (!reserved.some((item) => item.col === cell.col && item.row === cell.row)) {
            return cell;
          }
        }
      }
    }
    return { col: 0, row: 0 };
  }
  buildObstacles(random, cols, rows, count, reserved) {
    const reservedKeys = new Set(reserved.map((cell) => `${cell.col}:${cell.row}`));
    const obstacles = [];
    let guard = 0;
    while (obstacles.length < count && guard < 180) {
      guard += 1;
      const cell = { col: random.integer(0, cols - 1), row: random.integer(0, rows - 1) };
      const key = `${cell.col}:${cell.row}`;
      const tooCloseToStart = Math.abs(cell.col) + Math.abs(cell.row - (rows - 1)) <= 1;
      if (!tooCloseToStart && !reservedKeys.has(key) && !obstacles.some((obstacle) => obstacle.col === cell.col && obstacle.row === cell.row)) {
        obstacles.push(cell);
      }
    }
    return obstacles;
  }
  solveRoute(cols, rows, start, key, exit, obstacles, checkpoints) {
    let state = { ...start };
    const commands = [];
    for (const target of [...checkpoints, key]) {
      const path = this.solver.findCommandPath(cols, rows, state, target, obstacles, cols * rows * 4);
      if (!path) {
        return void 0;
      }
      commands.push(...path);
      state = this.solver.simulate(state, path);
    }
    commands.push("PICK_UP");
    const toExit = this.solver.findCommandPath(cols, rows, state, exit, obstacles, cols * rows * 4);
    if (!toExit) {
      return void 0;
    }
    commands.push(...toExit, "EXIT");
    return commands;
  }
  buildPuzzle(cols, rows, start, key, exit, obstacles, solutionCommands, difficulty, challengeType, checkpoints, random) {
    const buggedCommands = challengeType === "debug-program" ? this.mutateProgram(solutionCommands, random) : void 0;
    const maxCommands = challengeType === "minimal-route" || challengeType === "loop-compression" ? solutionCommands.length + (difficulty.level <= 2 ? 2 : 1) : solutionCommands.length + Math.max(2, 6 - difficulty.level);
    return {
      id: `robot-grid-${challengeType}`,
      title: this.titleFor(challengeType),
      instructions: this.instructionsFor(challengeType, checkpoints),
      cols,
      rows,
      start,
      key,
      exit,
      obstacles,
      solutionCommands,
      maxCommands,
      challengeType,
      checkpoints,
      buggedCommands,
      debugBrief: buggedCommands ? "Il log registrato contiene un programma quasi corretto ma instabile: non copiarlo, usalo per cercare il primo comando che rompe la rotta." : void 0,
      successConditions: this.successConditionsFor(challengeType, checkpoints, maxCommands),
      conceptTags: this.conceptsFor(challengeType, checkpoints),
      requiredConcepts: this.conceptsFor(challengeType, checkpoints),
      routeBrief: this.routeBriefFor(challengeType, checkpoints, solutionCommands),
      visualFocus: this.visualFocusFor(challengeType),
      coordinateLabels: challengeType === "coordinate-routing",
      planningPrompt: this.planningPromptFor(challengeType),
      hints: this.hintsFor(challengeType, checkpoints),
      competencies: this.competenciesFor(challengeType)
    };
  }
  mutateProgram(commands, random) {
    const mutableIndexes = commands.map((command, index) => ({ command, index })).filter(({ command }) => command !== "PICK_UP" && command !== "EXIT");
    if (mutableIndexes.length === 0) {
      return commands;
    }
    const picked = random.pick(mutableIndexes);
    const replacement = picked.command === "MOVE_FORWARD" ? random.pick(["TURN_LEFT", "TURN_RIGHT"]) : "MOVE_FORWARD";
    return commands.map((command, index) => index === picked.index ? replacement : command);
  }
  titleFor(type) {
    return {
      "route-planning": "Robot: rotta operativa",
      "minimal-route": "Robot: percorso minimo",
      "checkpoint-order": "Robot: checkpoint ordinati",
      "debug-program": "Robot: programma da debuggare",
      "pattern-routing": "Robot: pattern di rotta",
      "coordinate-routing": "Robot: coordinate operative",
      "conditional-gate": "Robot: porta condizionata",
      "loop-compression": "Robot: blocco ripetuto"
    }[type];
  }
  instructionsFor(type, checkpoints) {
    const checkpointLine = checkpoints.length > 0 ? `Passa sui checkpoint ${checkpoints.map((checkpoint) => checkpoint.label).join(" -> ")} prima di raccogliere la chiave.` : "Non ci sono checkpoint: concentrati su posizione, direzione e budget.";
    return {
      "route-planning": [
        "Obiettivo: porta il robot sulla stella, usa Raccogli, poi raggiungi il quadrato di uscita e usa Esci.",
        "La punta indica la direzione iniziale; le rotazioni cambiano solo direzione, non casella.",
        "Prima simula mentalmente tre comandi: posizione, direzione, nuova posizione."
      ],
      "minimal-route": [
        "Obiettivo: stessa missione, ma con budget stretto. Ogni comando inutile consuma energia.",
        "Cerca corridoi lunghi prima di aggiungere svolte.",
        "Se due rotazioni consecutive si annullano, probabilmente puoi accorciare il programma."
      ],
      "checkpoint-order": [
        checkpointLine,
        "Dividi il programma in sottoproblemi: start -> checkpoint -> chiave -> uscita.",
        "Non raccogliere la chiave prima del checkpoint: il sistema non certifichera la rotta."
      ],
      "debug-program": [
        "Un programma precedente e quasi corretto ma contiene un errore. Devi riscrivere la rotta stabile.",
        "Non provare a caso: individua dove cambia posizione o direzione rispetto all'obiettivo.",
        "Esegui solo quando sai spiegare perche il programma corretto arriva a chiave e uscita."
      ],
      "pattern-routing": [
        checkpointLine,
        "La griglia nasconde un pattern: alterna tratti lunghi e svolte controllate.",
        "Costruisci la sequenza per segmenti, poi verifica che l'ultimo segmento arrivi all'uscita."
      ],
      "coordinate-routing": [
        "Leggi la griglia come coordinate: colonne da sinistra a destra, righe dall'alto verso il basso.",
        "Prima individua coordinate di robot, chiave e uscita; poi trasforma gli spostamenti in comandi.",
        "La direzione iniziale conta: uno spostamento verso destra non e sempre un Avanza immediato."
      ],
      "conditional-gate": [
        checkpointLine,
        "I sensori aprono la porta solo se vengono attivati nell'ordine indicato.",
        "Pensa come un algoritmo con condizioni: se S1 e S2 sono attivi, allora puoi raccogliere e uscire."
      ],
      "loop-compression": [
        checkpointLine,
        "Cerca un blocco di comandi che si ripete: tratto dritto, svolta, tratto dritto.",
        "Non devi usare un comando Repeat: devi pero riconoscere il pattern per scrivere meno tentativi."
      ]
    }[type];
  }
  successConditionsFor(type, checkpoints, maxCommands) {
    const conditions = [
      "Raccogli la chiave dalla stessa casella della stella.",
      "Raggiungi il quadrato di uscita e usa Esci.",
      `Non superare ${maxCommands} comandi.`
    ];
    if (checkpoints.length > 0) {
      conditions.unshift(`Visita i checkpoint in ordine: ${checkpoints.map((checkpoint) => checkpoint.label).join(" -> ")}.`);
    }
    if (type === "debug-program") {
      conditions.unshift("Correggi il programma guasto invece di copiarlo.");
    }
    if (type === "conditional-gate") {
      conditions.unshift("Attiva i sensori prima della chiave: la porta finale accetta solo una procedura condizionata.");
    }
    if (type === "coordinate-routing") {
      conditions.unshift("Usa le coordinate come piano, non come risposta: il robot esegue solo comandi.");
    }
    if (type === "loop-compression") {
      conditions.unshift("Riconosci il blocco ripetuto prima di eseguire: evita comandi esplorativi.");
    }
    return conditions;
  }
  hintsFor(type, checkpoints) {
    const base = [
      "Segna la direzione del robot dopo ogni svolta: molti errori nascono da una punta dimenticata.",
      "Dividi la rotta in segmenti e controlla un segmento alla volta.",
      "Prima di eseguire, leggi la sequenza come se fossi il robot."
    ];
    if (type === "minimal-route") {
      return ["Il percorso piu breve spesso usa il bordo come corridoio.", "Elimina rotazioni che non cambiano la prossima cella utile.", ...base];
    }
    if (type === "debug-program") {
      return ["Confronta il log guasto con la mappa: il primo urto e la vera informazione.", "Un solo comando sbagliato puo cambiare tutte le caselle successive.", ...base];
    }
    if (type === "coordinate-routing") {
      return ["Scrivi le coordinate di partenza, chiave e uscita: poi conta colonne e righe.", "Una rotazione cambia verso, non posizione: dopo ogni svolta aggiorna la freccia.", ...base];
    }
    if (type === "conditional-gate") {
      return ["Tratta i checkpoint come condizioni da rendere vere prima della chiave.", "Se raccogli prima dei sensori, il programma sembra vicino ma non e valido.", ...base];
    }
    if (type === "loop-compression") {
      return ["Cerca due segmenti simili: spesso la stessa idea si ripete con direzioni diverse.", "Scrivi il blocco una volta su carta, poi adattalo alla seconda tappa.", ...base];
    }
    if (checkpoints.length > 0) {
      return [`Prima punta al checkpoint ${checkpoints[0].label}, poi riparti da li come se fosse un nuovo inizio.`, ...base];
    }
    return base;
  }
  conceptsFor(type, checkpoints) {
    const concepts = ["direzione", "sequenza", "simulazione mentale"];
    if (checkpoints.length > 0) concepts.push("decomposizione in sotto-obiettivi");
    if (type === "minimal-route") concepts.push("ottimizzazione", "budget di comandi");
    if (type === "debug-program") concepts.push("debugging", "traccia di errore");
    if (type === "pattern-routing") concepts.push("pattern spaziale");
    if (type === "coordinate-routing") concepts.push("coordinate", "assi della griglia");
    if (type === "conditional-gate") concepts.push("condizione se-allora", "stato del sistema");
    if (type === "loop-compression") concepts.push("pattern ripetuto", "astrazione di blocco");
    concepts.push("raccolta contestuale", "uscita finale");
    return concepts;
  }
  competenciesFor(type) {
    const base = ["coding.sequenze", "coding.orientamento", "problemSolving"];
    if (type === "minimal-route") return [...base, "coding.efficienza", "pensieroCritico"];
    if (type === "debug-program") return [...base, "coding.debugging", "coding.testMentale", "pensieroCritico"];
    if (type === "coordinate-routing") return [...base, "coding.testMentale", "matematica.logica"];
    if (type === "conditional-gate") return [...base, "coding.decomposizione", "matematica.logica", "pensieroCritico"];
    if (type === "loop-compression") return [...base, "coding.decomposizione", "coding.efficienza", "pensieroCritico"];
    if (type === "checkpoint-order" || type === "pattern-routing") return [...base, "coding.decomposizione", "coding.testMentale"];
    return [...base, "coding.debugging"];
  }
  routeBriefFor(type, checkpoints, solutionCommands) {
    const turns = solutionCommands.filter((command) => command === "TURN_LEFT" || command === "TURN_RIGHT").length;
    const checkpointsText = checkpoints.length > 0 ? ` Tappe obbligatorie: ${checkpoints.map((checkpoint) => checkpoint.label).join(" -> ")}.` : "";
    return {
      "route-planning": `Pianifica una rotta completa: chiave, uscita e comando finale.${checkpointsText}`,
      "minimal-route": `Budget stretto: soluzione di riferimento ${solutionCommands.length} comandi, con ${turns} rotazioni.`,
      "checkpoint-order": `Scomponi in tappe: ogni checkpoint crea un nuovo sotto-problema.${checkpointsText}`,
      "debug-program": "Usa il log guasto come indizio: cerca il primo comando che cambia direzione o posizione nel punto sbagliato.",
      "pattern-routing": `Cerca una struttura visiva ricorrente tra le tappe.${checkpointsText}`,
      "coordinate-routing": "Trasforma coordinate e direzione in comandi: colonna/riga non bastano se la freccia punta altrove.",
      "conditional-gate": `Algoritmo con stato: prima rendi veri i sensori, poi raccogli e apri.${checkpointsText}`,
      "loop-compression": `Individua il blocco ripetuto: una buona sequenza nasce da segmenti riconoscibili.${checkpointsText}`
    }[type];
  }
  visualFocusFor(type) {
    return {
      "route-planning": "rotta completa",
      "minimal-route": "efficienza",
      "checkpoint-order": "sotto-obiettivi",
      "debug-program": "primo errore",
      "pattern-routing": "pattern spaziale",
      "coordinate-routing": "coordinate",
      "conditional-gate": "se -> allora",
      "loop-compression": "blocco ripetuto"
    }[type];
  }
  planningPromptFor(type) {
    return {
      "route-planning": "Scrivi la sequenza solo quando sai dove saranno posizione e direzione dopo i primi tre comandi.",
      "minimal-route": "Prima elimina svolte inutili: un programma corretto ma lungo non supera il budget.",
      "checkpoint-order": "Risolvi una tappa alla volta, poi unisci i segmenti senza perdere la direzione finale.",
      "debug-program": "Non copiare il log: confrontalo con la mappa e correggi la prima divergenza.",
      "pattern-routing": "Cerca simmetrie e corridoi: spesso il percorso si costruisce per segmenti simili.",
      "coordinate-routing": "Annota coordinate e verso iniziale: conta spostamenti, poi converti in Avanza/Gira.",
      "conditional-gate": "Pensa a variabili di stato: sensore attivo oppure no. La chiave vale solo dopo le condizioni.",
      "loop-compression": "Trova il blocco ripetuto e riscrivilo con variazioni minime di direzione."
    }[type];
  }
  fallback(challengeType = "route-planning", random) {
    const mirror = (random == null ? void 0 : random.bool()) ?? false;
    const cell = (col, row) => ({ col: mirror ? 4 - col : col, row });
    const commands = (items) => mirror ? items.map((command) => command === "TURN_LEFT" ? "TURN_RIGHT" : command === "TURN_RIGHT" ? "TURN_LEFT" : command) : items;
    const checkpoints = ["checkpoint-order", "pattern-routing", "conditional-gate", "loop-compression"].includes(challengeType) ? [{ col: 1, row: 1, label: challengeType === "conditional-gate" ? "S1" : "A", order: 1 }] : [];
    const baseSolutionCommands = checkpoints.length > 0 ? ["TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "PICK_UP", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "EXIT"] : ["MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD", "PICK_UP", "TURN_RIGHT", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "EXIT"];
    const solutionCommands = commands(baseSolutionCommands);
    const variedCheckpoints = checkpoints.map((checkpoint) => ({ ...cell(checkpoint.col, checkpoint.row), label: checkpoint.label, order: checkpoint.order }));
    return {
      id: `robot-grid-fallback-${challengeType}-${mirror ? "mirror" : "base"}`,
      title: this.titleFor(challengeType),
      instructions: this.instructionsFor(challengeType, variedCheckpoints),
      cols: 5,
      rows: 4,
      start: { ...cell(0, 3), facing: mirror ? "W" : "E" },
      key: cell(3, 1),
      exit: cell(4, 3),
      obstacles: [cell(2, 2)],
      solutionCommands,
      maxCommands: solutionCommands.length + 2,
      challengeType,
      checkpoints: variedCheckpoints,
      buggedCommands: challengeType === "debug-program" ? commands(["MOVE_FORWARD", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "PICK_UP", "EXIT"]) : void 0,
      debugBrief: challengeType === "debug-program" ? "Il log guasto prova a raccogliere troppo presto: correggi la rotta completa." : void 0,
      successConditions: this.successConditionsFor(challengeType, variedCheckpoints, solutionCommands.length + 2),
      requiredConcepts: this.conceptsFor(challengeType, variedCheckpoints),
      conceptTags: this.conceptsFor(challengeType, variedCheckpoints),
      routeBrief: this.routeBriefFor(challengeType, variedCheckpoints, solutionCommands),
      visualFocus: this.visualFocusFor(challengeType),
      coordinateLabels: challengeType === "coordinate-routing",
      planningPrompt: this.planningPromptFor(challengeType),
      hints: this.hintsFor(challengeType, variedCheckpoints),
      competencies: this.competenciesFor(challengeType)
    };
  }
}
class HintLadder {
  fromTexts(texts, fallbackPrinciple) {
    const defaults = [
      { level: 1, kind: "osservazione", text: texts[0] ?? "Osserva prima il sintomo: il sistema mostra dove cambia comportamento." },
      { level: 2, kind: "restrizione", text: texts[1] ?? "Scarta le mosse che non cambiano il punto del guasto." },
      { level: 3, kind: "principio", text: texts[2] ?? fallbackPrinciple },
      { level: 4, kind: "quasi-soluzione", text: texts[3] ?? "Applica il principio al componente o al passaggio che interrompe il sistema." }
    ];
    return defaults;
  }
  next(steps, used) {
    return steps[Math.min(Math.max(used, 0), steps.length - 1)] ?? {
      level: 4,
      kind: "quasi-soluzione",
      text: "Rileggi il sintomo e prova una riparazione che cambi solo la causa più probabile."
    };
  }
}
const hintLadder = new HintLadder();
class ExplanationBuilder {
  math(operationSummary, workedExample, principle = "Un codice numerico affidabile nasce dall'ordine delle operazioni: ogni macchina trasforma il valore precedente.") {
    return {
      principle,
      workedExample,
      transferPrompt: `La prossima volta cerca prima la catena di trasformazioni: ${operationSummary}.`
    };
  }
  robot(requiredConcepts, optimalLength) {
    return {
      principle: "Un programma non è una lista di tentativi: è un piano che tiene insieme posizione, direzione e obiettivo.",
      workedExample: `La soluzione validata usa ${optimalLength} comandi e richiede: ${requiredConcepts.join(", ")}.`,
      transferPrompt: "Prima di premere Esegui, simula mentalmente i primi tre comandi e controlla dove punta il robot."
    };
  }
  circuit(faultSummary) {
    return {
      principle: "Un circuito funziona solo se il percorso della corrente è chiuso, orientato e protetto.",
      workedExample: faultSummary,
      transferPrompt: "Quando un LED non si accende, separa tre domande: il percorso è chiuso, il verso è giusto, la corrente è limitata?"
    };
  }
}
const explanationBuilder = new ExplanationBuilder();
class MistakeAnalyzer {
  circuitMistakes() {
    return [
      {
        id: "circuit-open-path",
        pattern: "test senza continuita",
        feedback: "Il LED non puo accendersi se la corrente non riesce a tornare alla batteria.",
        repairPrompt: "Cerca il primo punto in cui il tester smette di leggere continuita."
      },
      {
        id: "circuit-led-polarity",
        pattern: "corrente presente ma LED spento",
        feedback: "Il LED lascia passare corrente in un verso privilegiato: se e invertito resta spento.",
        repairPrompt: "Confronta il lato positivo della batteria con il verso del LED."
      },
      {
        id: "circuit-missing-resistor",
        pattern: "luce instabile",
        feedback: "La resistenza non serve a far passare corrente: serve a limitarla e proteggere il LED.",
        repairPrompt: "Inserisci la resistenza in serie, prima del LED."
      }
    ];
  }
  robotFailureMessage(failure, commands) {
    if (failure.kind === "wall") {
      const command = commands[failure.commandIndex] ?? "MOVE_FORWARD";
      return `Il comando ${failure.commandIndex + 1} (${command}) porta contro un ostacolo o fuori griglia. Controlla direzione e casella prima di avanzare.`;
    }
    if (failure.kind === "premature-pickup") {
      return `Il comando ${failure.commandIndex + 1} prova a raccogliere, ma la chiave non e sotto il robot. Prima porta N-7 sulla stella.`;
    }
    if (failure.kind === "too-long") {
      return `La sequenza funziona quasi, ma usa ${failure.commandCount} comandi: il budget ragionato e ${failure.ideal}. Cerca una svolta o un corridoio piu efficiente.`;
    }
    if (failure.kind === "missing-key") {
      return "Il robot ha eseguito il programma, ma non ha raccolto la chiave: serve un comando Raccogli quando si trova sulla stella.";
    }
    return "Il robot ha la chiave, ma non ha completato l'uscita: raggiungi il quadrato finale e usa Esci.";
  }
}
const mistakeAnalyzer = new MistakeAnalyzer();
class ExerciseDirector {
  constructor() {
    __publicField(this, "mathGenerator", new MathPuzzleGenerator());
    __publicField(this, "robotGenerator", new RobotGridGenerator());
    __publicField(this, "circuitGenerator", new CircuitFaultGenerator());
  }
  generateSet(seed, difficulty) {
    const preset = difficultyModel.getPreset(difficulty);
    const random = new Random(`${seed}:exercise-director:${preset.level}`);
    return {
      math: this.enrichMath(this.mathGenerator.generate(random.fork("math"), preset), preset.level),
      robot: this.enrichRobot(this.robotGenerator.generate(random.fork("robot"), preset), preset.level),
      circuit: this.enrichCircuit(this.circuitGenerator.generate(random.fork("circuit"), preset), preset.level)
    };
  }
  enrichMath(puzzle, level) {
    const steps = puzzle.solutionSteps ?? this.inferMathSteps(puzzle.prompt, puzzle.answer);
    const profile = this.mathProfile(puzzle, level, steps);
    return {
      ...puzzle,
      solutionSteps: steps,
      difficultyLevel: level,
      difficultyLabel: profile.difficultyLabel,
      learningPurpose: profile.learningPurpose,
      calculationAid: profile.calculationAid,
      pedagogy: this.basePedagogy(
        level,
        profile.learningPurpose,
        profile.difficultyReason,
        puzzle.hints,
        explanationBuilder.math(
          profile.operationSummary,
          `Passaggi controllati: ${steps.join(" -> ")}. Risultato finale: ${puzzle.answer}.`,
          profile.theoryPrinciple
        )
      )
    };
  }
  enrichRobot(puzzle, level) {
    const concepts = this.robotConcepts(puzzle);
    return {
      ...puzzle,
      maxCommands: puzzle.maxCommands ?? Math.max(puzzle.solutionCommands.length + (level <= 2 ? 4 : 2), puzzle.solutionCommands.length),
      requiredConcepts: concepts,
      pedagogy: this.basePedagogy(
        level,
        this.robotLearningGoal(puzzle),
        "La difficolta cresce con dimensione griglia, ostacoli, checkpoint, budget e numero di stati da ricordare.",
        puzzle.hints,
        explanationBuilder.robot(concepts, puzzle.solutionCommands.length)
      )
    };
  }
  enrichCircuit(puzzle, level) {
    const faultSummary = puzzle.requiredRepairs.map((fault) => this.circuitFaultExplanation(fault)).join(" ");
    return {
      ...puzzle,
      testerReadings: puzzle.testerReadings ?? this.testerReadings(puzzle),
      explanationByFault: {
        ...Object.fromEntries(puzzle.requiredRepairs.map((fault) => [fault, this.circuitFaultExplanation(fault)])),
        ...puzzle.explanationByFault ?? {}
      },
      pedagogy: this.basePedagogy(
        level,
        puzzle.learningPurpose ?? "Diagnosticare un circuito separando percorso chiuso, verso del LED, protezione e comportamento dei componenti.",
        "La difficolta cresce con numero di guasti, letture del tester e distrattori plausibili.",
        puzzle.hints,
        explanationBuilder.circuit(faultSummary),
        mistakeAnalyzer.circuitMistakes()
      )
    };
  }
  basePedagogy(level, learningGoal, difficultyReason, hints, explanation, commonMistakes = []) {
    return {
      phase: level <= 2 ? "osserva" : level <= 5 ? "formula-ipotesi" : "verifica-correggi",
      learningGoal,
      difficultyReason,
      hintLadder: hintLadder.fromTexts(hints, explanation.principle),
      commonMistakes,
      explanation
    };
  }
  inferMathSteps(prompt, answer) {
    return [prompt.replace(/\s+/g, " ").trim(), `risultato ${answer}`];
  }
  mathProfile(puzzle, level, steps) {
    const archetype = puzzle.archetype ?? "calcolo-diretto";
    const concept = this.mathConcept(archetype);
    const difficultyLabel = this.mathDifficultyLabel(level);
    const multiStepReason = steps.length >= 4 ? "richiede piu passaggi ordinati e controllo finale" : steps.length >= 3 ? "richiede almeno tre passaggi distinti" : "richiede pochi passaggi, ma l'ordine e importante";
    return {
      difficultyLabel,
      learningPurpose: concept.learningPurpose,
      difficultyReason: `Livello ${level}/8: ${difficultyModel.describe(level)}; ${multiStepReason}.`,
      theoryPrinciple: concept.theoryPrinciple,
      operationSummary: `${concept.shortName}: ${steps.slice(0, 3).join(" -> ")}`,
      calculationAid: {
        mentalMathNote: "Puoi calcolare a mente se vuoi, ma non e richiesto. La sfida valuta strategia, ordine dei passaggi e controllo dell'errore.",
        strategy: concept.strategy,
        scratchpadPrompt: steps.length >= 3 ? "Usa un taccuino: una riga per ogni passaggio, poi inserisci solo il risultato finale." : "Scrivi dati, operazione e risultato: evita di tenere tutto in memoria."
      }
    };
  }
  mathDifficultyLabel(level) {
    if (level <= 2) return `Livello ${level}/8 - Fondamenta guidate`;
    if (level <= 4) return `Livello ${level}/8 - Strategie intermedie`;
    if (level <= 6) return `Livello ${level}/8 - Ragionamento multi-passaggio`;
    return `Livello ${level}/8 - Ponte verso le superiori`;
  }
  mathConcept(archetype) {
    const concepts = {
      "calcolo-diretto": {
        shortName: "calcolo ordinato",
        learningPurpose: "Allenare calcolo mentale scritto, ordine delle operazioni e controllo del risultato.",
        theoryPrinciple: "Quando una macchina applica piu operazioni, il valore cambia passo dopo passo: cambiare l'ordine cambia quasi sempre il risultato.",
        strategy: "Spezza la catena: calcola il primo blocco, scrivi il risultato intermedio, poi passa al blocco successivo."
      },
      "ragionamento-inverso": {
        shortName: "operazioni inverse",
        learningPurpose: "Capire come tornare dal risultato all'ingresso usando operazioni inverse.",
        theoryPrinciple: "Per annullare una trasformazione si usa l'operazione inversa: somma e sottrazione si annullano, moltiplicazione e divisione si annullano.",
        strategy: "Parti dall'uscita e risali la macchina al contrario, una trasformazione per volta."
      },
      sequenza: {
        shortName: "sequenze",
        learningPurpose: "Riconoscere pattern numerici e prevedere il termine successivo senza andare per tentativi.",
        theoryPrinciple: "Una sequenza ha una regola: puo crescere con salti costanti, salti che cambiano o moltiplicazioni ripetute.",
        strategy: "Calcola le differenze tra termini consecutivi e cerca come cambiano i salti."
      },
      vincolo: {
        shortName: "vincoli",
        learningPurpose: "Scegliere un numero che rispetta piu condizioni contemporaneamente.",
        theoryPrinciple: "Un vincolo elimina possibilita: piu vincoli insieme riducono lo spazio di ricerca e obbligano a ragionare.",
        strategy: "Applica prima il vincolo che scarta piu numeri, poi controlla gli altri uno alla volta."
      },
      "diagnosi-errore": {
        shortName: "controllo errore",
        learningPurpose: "Individuare un errore di procedura e correggerlo con un calcolo verificabile.",
        theoryPrinciple: "Un risultato non basta: devi controllare se rispetta la procedura e l'ordine delle operazioni.",
        strategy: "Rifai il protocollo lentamente e confronta ogni passaggio con il log sospetto."
      },
      "lettura-dati": {
        shortName: "dati",
        learningPurpose: "Leggere dati numerici e trasformarli in un'informazione utile.",
        theoryPrinciple: "I dati grezzi non sono ancora una conclusione: vanno ordinati, confrontati o sintetizzati.",
        strategy: "Sottolinea quali dati servono davvero e quale trasformazione richiede il terminale."
      },
      proporzione: {
        shortName: "proporzioni",
        learningPurpose: "Usare rapporti e fattori di scala in situazioni concrete.",
        theoryPrinciple: "In una proporzione il rapporto resta lo stesso anche quando le quantita cambiano scala.",
        strategy: "Trova il fattore di scala, poi applicalo a tutte le parti coinvolte."
      },
      "pre-algebra": {
        shortName: "pre-algebra",
        learningPurpose: "Tradurre una procedura in una espressione e rispettare parentesi e priorita.",
        theoryPrinciple: "Le parentesi indicano un blocco da risolvere prima; moltiplicazioni e divisioni precedono somme e sottrazioni.",
        strategy: "Risolvi prima i blocchi interni, poi moltiplicazioni/divisioni, infine somme/sottrazioni."
      },
      "equazione-primo-grado": {
        shortName: "equazioni",
        learningPurpose: "Risolvere equazioni di primo grado mantenendo l'equilibrio tra i due lati.",
        theoryPrinciple: "Un'equazione resta equivalente se applichi la stessa operazione a entrambi i lati: l'obiettivo e isolare x.",
        strategy: "Togli prima addizioni o sottrazioni, poi annulla moltiplicazioni o divisioni. Se ci sono parentesi, semplifica quel blocco prima di isolare x."
      },
      "equazione-secondo-grado": {
        shortName: "equazioni quadratiche",
        learningPurpose: "Collegare coefficienti, discriminante, radici e grafico di una parabola.",
        theoryPrinciple: "Nella forma ax² + bx + c = 0, il discriminante Δ = b² - 4ac determina quante soluzioni reali esistono; le radici sono le intersezioni con l'asse x.",
        strategy: "Identifica a, b e c con i rispettivi segni; calcola Δ; prevedi il numero di soluzioni; applica fattorizzazione o formula e verifica sul grafico."
      },
      "grafici-cartesiani": {
        shortName: "grafici interattivi",
        learningPurpose: "Comprendere come i parametri trasformano rette e parabole intervenendo direttamente sul grafico.",
        theoryPrinciple: "I parametri non sono numeri decorativi: pendenza e intercetta muovono una retta; apertura, asse e vertice trasformano una parabola.",
        strategy: "Modifica un parametro alla volta, osserva cosa resta invariato e usa punti notevoli, vertice e intersezioni per verificare il risultato."
      },
      frazioni: {
        shortName: "frazioni",
        learningPurpose: "Capire le frazioni come parti dello stesso intero e non come comandi isolati.",
        theoryPrinciple: "Una frazione indica una quota di un totale: prima identifica l'intero, poi calcola la parte richiesta.",
        strategy: "Scrivi qual e il totale, calcola ogni quota sul totale iniziale, poi combina le quote."
      },
      percentuali: {
        shortName: "percentuali",
        learningPurpose: "Usare percentuali come frazioni su 100 in aumenti, perdite e confronti.",
        theoryPrinciple: "Una percentuale e una quota su 100: il 25% significa 25 parti ogni 100, cioe un quarto.",
        strategy: "Calcola prima la quota percentuale, poi decidi se aggiungerla o sottrarla."
      },
      geometria: {
        shortName: "geometria",
        learningPurpose: "Collegare misure, formule e significato geometrico della situazione.",
        theoryPrinciple: "Area, perimetro e distanza misurano proprieta diverse: non sono intercambiabili.",
        strategy: "Disegna una mini figura, assegna le misure e scegli la formula prima di calcolare."
      },
      statistica: {
        shortName: "statistica",
        learningPurpose: "Sintetizzare una serie di dati con misure come mediana, media e intervallo.",
        theoryPrinciple: "La statistica cerca una lettura stabile dei dati: non sempre il valore piu alto o piu visibile e quello utile.",
        strategy: "Ordina i dati, trova la misura richiesta, poi applica l'eventuale passaggio finale."
      },
      probabilita: {
        shortName: "probabilita",
        learningPurpose: "Stimare eventi usando rapporti e frequenze attese.",
        theoryPrinciple: "La probabilita descrive quanto e plausibile un evento: se il rapporto resta uguale, puoi prevedere una frequenza attesa.",
        strategy: "Semplifica il rapporto, poi applicalo al nuovo totale."
      },
      "potenze-radici": {
        shortName: "potenze e radici",
        learningPurpose: "Usare potenze, radici e ordine di grandezza per leggere segnali compatti.",
        theoryPrinciple: "Una potenza ripete una moltiplicazione; una radice quadrata cerca il lato che moltiplicato per se stesso produce l'area.",
        strategy: "Riconosci prima il tipo di potenza o radice, poi usa un valore intermedio scritto."
      },
      "funzione-lineare": {
        shortName: "funzioni",
        learningPurpose: "Capire una funzione come macchina ingresso-uscita.",
        theoryPrinciple: "Una funzione assegna a ogni ingresso una uscita seguendo sempre la stessa regola.",
        strategy: "Sostituisci x con il valore dato, calcola la moltiplicazione, poi aggiungi il termine finale."
      },
      "sistemi-lineari": {
        shortName: "sistemi",
        learningPurpose: "Ragionare su due incognite collegate da piu informazioni.",
        theoryPrinciple: "Un sistema usa piu relazioni per trovare valori sconosciuti: una sola informazione spesso non basta.",
        strategy: "Trasforma somma e differenza in due quantita uguali, poi ricostruisci i valori."
      },
      coordinate: {
        shortName: "coordinate",
        learningPurpose: "Usare il piano cartesiano o una griglia per calcolare spostamenti.",
        theoryPrinciple: "Le coordinate descrivono posizione; uno spostamento senza diagonali si calcola separando asse orizzontale e verticale.",
        strategy: "Calcola prima lo spostamento in x, poi quello in y, infine somma i due percorsi."
      }
    };
    return concepts[archetype];
  }
  robotConcepts(puzzle) {
    var _a2;
    const commands = puzzle.solutionCommands;
    const concepts = /* @__PURE__ */ new Set(["direzione iniziale", "sequenza"]);
    if (commands.includes("PICK_UP")) concepts.add("azione contestuale");
    if (commands.includes("EXIT")) concepts.add("obiettivo finale");
    if (commands.filter((command) => command === "TURN_LEFT" || command === "TURN_RIGHT").length >= 2) concepts.add("rotazioni multiple");
    if ((((_a2 = puzzle.checkpoints) == null ? void 0 : _a2.length) ?? 0) > 0) concepts.add("checkpoint ordinati");
    if (puzzle.challengeType === "minimal-route") concepts.add("ottimizzazione");
    if (puzzle.challengeType === "debug-program") concepts.add("debug del programma");
    if (puzzle.challengeType === "pattern-routing") concepts.add("pattern spaziale");
    if (puzzle.challengeType === "coordinate-routing") concepts.add("coordinate su griglia");
    if (puzzle.challengeType === "conditional-gate") concepts.add("logica condizionale");
    if (puzzle.challengeType === "loop-compression") concepts.add("pattern ripetuto");
    return [...concepts];
  }
  robotLearningGoal(puzzle) {
    return {
      "route-planning": "Pianificare una sequenza tenendo conto di direzione, ostacoli, raccolta e uscita.",
      "minimal-route": "Costruire un algoritmo corretto ma essenziale, riducendo comandi inutili.",
      "checkpoint-order": "Scomporre una rotta in sotto-obiettivi ordinati e verificabili.",
      "debug-program": "Analizzare un programma quasi corretto, individuare l'errore e riscrivere la sequenza.",
      "pattern-routing": "Riconoscere pattern spaziali e trasformarli in sequenze di comandi controllate.",
      "coordinate-routing": "Tradurre posizioni su griglia e direzione iniziale in una sequenza di comandi.",
      "conditional-gate": "Usare una logica se-allora: attivare condizioni prima dell'azione finale.",
      "loop-compression": "Riconoscere blocchi ripetuti e usarli per progettare sequenze piu efficienti."
    }[puzzle.challengeType ?? "route-planning"];
  }
  testerReadings(puzzle) {
    return puzzle.requiredRepairs.map((fault) => {
      if (fault === "open-switch") return { from: "batteria", to: "interruttore", reading: "interrotto", note: "La leva aperta interrompe il percorso." };
      if (fault === "missing-wire") return { from: "LED", to: "ritorno", reading: "interrotto", note: "Manca il tratto che chiude il giro." };
      if (fault === "reversed-led") return { from: "resistenza", to: "LED", reading: "polarita-inversa", note: "La corrente arriva, ma il LED e orientato al contrario." };
      if (fault === "missing-resistor") return { from: "interruttore", to: "LED", reading: "non-stabile", note: "Il percorso c'e, ma non e protetto." };
      if (fault === "sensor-unpowered") return { from: "sensore", to: "alimentazione", reading: "interrotto", note: "Il circuito principale puo funzionare, ma il sensore non riceve energia." };
      if (fault === "capacitor-discharged") return { from: "condensatore", to: "LED", reading: "non-stabile", note: "Il condensatore non accumula carica: l'impulso resta troppo breve." };
      if (fault === "short-circuit") return { from: "batteria +", to: "ritorno", reading: "corto", note: "La corrente trova una scorciatoia e non attraversa il carico." };
      if (fault === "parallel-branch-open") return { from: "ramo B", to: "ritorno", reading: "interrotto", note: "Il ramo principale funziona, ma il ramo parallelo resta aperto." };
      if (fault === "wrong-resistor-value") return { from: "resistenza", to: "LED", reading: "non-stabile", note: "Il valore non limita la corrente nel modo richiesto." };
      if (fault === "relay-not-armed") return { from: "bobina relè", to: "ritorno", reading: "tensione-bassa", note: "Il relè non chiude il contatto di potenza." };
      if (fault === "loose-ground") return { from: "ritorno", to: "massa", reading: "non-stabile", note: "Il riferimento di ritorno non e stabile." };
      return { from: "componente", to: "linea principale", reading: "interrotto", note: "Il componente non e dentro il percorso utile." };
    });
  }
  circuitFaultExplanation(fault) {
    return {
      "missing-wire": "Un filo mancante lascia il circuito aperto: la corrente non ritorna alla batteria.",
      "open-switch": "Un interruttore aperto e come un ponte sollevato: il percorso si interrompe.",
      "reversed-led": "Un LED invertito riceve corrente dal verso sbagliato e non emette luce.",
      "missing-resistor": "Senza resistenza il LED non e protetto: il sistema vede corrente instabile.",
      "disconnected-component": "Un componente scollegato puo essere presente ma non partecipa al circuito.",
      "sensor-unpowered": "Un sensore non alimentato non puo misurare ne inviare dati affidabili al terminale.",
      "capacitor-discharged": "Un condensatore scarico non stabilizza gli impulsi: la luce puo apparire solo per un istante.",
      "short-circuit": "Un corto circuito offre una scorciatoia pericolosa: la corrente evita il carico.",
      "parallel-branch-open": "Un ramo parallelo aperto puo lasciare acceso un ramo e spento l'altro.",
      "wrong-resistor-value": "Una resistenza con valore errato rende la corrente troppo debole o troppo forte.",
      "relay-not-armed": "Un rele non armato non trasferisce il comando al circuito di potenza.",
      "loose-ground": "Una massa instabile rende il ritorno intermittente e le letture poco affidabili."
    }[fault];
  }
}
const exerciseDirector = new ExerciseDirector();
class CircuitPuzzleValidator {
  validate(puzzle) {
    var _a2, _b, _c, _d;
    const hasCoreNodes = ["battery", "switch", "resistor", "led", "return"].every((node) => puzzle.nodes.includes(node));
    const repairable = puzzle.faults.every((fault) => puzzle.requiredRepairs.includes(fault));
    const repairsAreUnique = new Set(puzzle.requiredRepairs).size === puzzle.requiredRepairs.length;
    const choicesAreUnique = new Set(puzzle.repairChoices ?? []).size === (((_a2 = puzzle.repairChoices) == null ? void 0 : _a2.length) ?? 0);
    const hasDiagnostics = Boolean(((_b = puzzle.testerReadings) == null ? void 0 : _b.length) && ((_c = puzzle.diagnosticPlan) == null ? void 0 : _c.length) && puzzle.learningPurpose);
    const hasPlausibleChoices = Boolean(
      ((_d = puzzle.repairChoices) == null ? void 0 : _d.length) && puzzle.requiredRepairs.every((fault) => {
        var _a3;
        return (_a3 = puzzle.repairChoices) == null ? void 0 : _a3.includes(fault);
      }) && puzzle.repairChoices.length > puzzle.requiredRepairs.length
    );
    const componentChallengesAreValid = (puzzle.componentChallenges ?? []).every((challenge) => {
      const symbolChoices = new Set(challenge.symbolChoices);
      const functionChoices = new Set(challenge.functionChoices);
      return challenge.componentId.length > 0 && challenge.explanation.length > 30 && challenge.symbolChoices.length >= 3 && challenge.functionChoices.length >= 3 && symbolChoices.size === challenge.symbolChoices.length && functionChoices.size === challenge.functionChoices.length && symbolChoices.has(challenge.correctSymbol) && functionChoices.has(challenge.correctFunction);
    });
    return hasCoreNodes && repairable && repairsAreUnique && choicesAreUnique && puzzle.faults.length > 0 && puzzle.hints.length >= puzzle.faults.length && hasDiagnostics && hasPlausibleChoices && componentChallengesAreValid;
  }
}
class CodingPuzzleValidator {
  validate(puzzle) {
    const choices = new Set(puzzle.options);
    return puzzle.codeLines.length >= 3 && puzzle.options.length >= 3 && choices.size === puzzle.options.length && choices.has(puzzle.correctOption) && puzzle.question.trim().length > 20 && puzzle.explanation.trim().length > 35 && puzzle.hints.length >= 2 && puzzle.competencies.length >= 2;
  }
}
class LanguagePuzzleValidator {
  validateItalian(puzzle) {
    var _a2;
    const normalizedOptions = puzzle.options.map((option) => option.trim().toLocaleLowerCase("it"));
    return puzzle.corrupted.trim().length > 0 && puzzle.repaired.trim().length > 0 && puzzle.corrupted !== puzzle.repaired && puzzle.options.includes(puzzle.repaired) && puzzle.options.filter((option) => option === puzzle.repaired).length === 1 && puzzle.options.length >= 3 && puzzle.options.every((option) => option.trim().length > 0) && new Set(puzzle.options).size === puzzle.options.length && new Set(normalizedOptions).size === normalizedOptions.length && puzzle.diagnosticSteps.length >= 2 && Boolean(puzzle.learningPurpose) && Boolean(puzzle.repairGoal) && Boolean(puzzle.method) && (((_a2 = puzzle.conceptTags) == null ? void 0 : _a2.length) ?? 0) >= 2 && puzzle.options.every((option) => {
      var _a3;
      return option === puzzle.repaired || Boolean((_a3 = puzzle.optionFeedback) == null ? void 0 : _a3[option]);
    });
  }
  validateEnglish(puzzle) {
    var _a2, _b;
    const needsData = puzzle.challengeType === "data-reading";
    const needsSource = puzzle.challengeType === "procedure-debug" || puzzle.challengeType === "inference";
    const uniqueChoices = new Set(puzzle.choices.map((choice) => choice.label));
    return puzzle.choices.filter((choice) => choice.isCorrect).length === 1 && puzzle.choices.length >= 3 && uniqueChoices.size === puzzle.choices.length && puzzle.diagnosticSteps.length >= 2 && puzzle.hints.length >= 2 && Boolean(puzzle.learningPurpose) && Boolean(puzzle.commandGoal) && Boolean(puzzle.method) && (!needsData || (((_a2 = puzzle.dataPoints) == null ? void 0 : _a2.length) ?? 0) >= 1) && (!needsSource || Boolean(puzzle.sourceText)) && (((_b = puzzle.conceptTags) == null ? void 0 : _b.length) ?? 0) >= 2 && puzzle.choices.every((choice) => choice.isCorrect || choice.feedback.length >= 30);
  }
}
class MathSolver {
  isIntegerSolution(puzzle) {
    return Number.isInteger(puzzle.answer) && Number.isFinite(puzzle.answer);
  }
}
class MathPuzzleValidator {
  constructor() {
    __publicField(this, "solver", new MathSolver());
  }
  validate(puzzle) {
    const answerIsInteger = Number.isInteger(puzzle.answer);
    const asksRounding = /arrotond/i.test(puzzle.prompt);
    const roundingIsExplicit = !asksRounding || /,5|superiore|inferiore|regola indicata|senza arrotondare/i.test(puzzle.prompt);
    const formatIsExplicit = /un solo numero intero|numero intero/i.test(puzzle.prompt) || Boolean(puzzle.equationLab) || Boolean(puzzle.graphWorkshop);
    const equationLabIsValid = !puzzle.equationLab || this.validateEquationLab(puzzle);
    const graphWorkshopIsValid = !puzzle.graphWorkshop || this.validateGraphWorkshop(puzzle);
    return this.solver.isIntegerSolution(puzzle) && answerIsInteger && puzzle.answer >= 0 && puzzle.answer <= 9999 && puzzle.hints.length >= 2 && puzzle.prompt.length > 20 && roundingIsExplicit && formatIsExplicit && equationLabIsValid && graphWorkshopIsValid;
  }
  validateEquationLab(puzzle) {
    const lab = puzzle.equationLab;
    if (!lab || lab.stages.length < (lab.degree === 1 ? 4 : 5)) return false;
    const stagesAreValid = lab.stages.every((stage) => stage.options.length === 4 && new Set(stage.options).size === stage.options.length && stage.options.includes(stage.correctOption) && stage.explanation.length >= 18);
    if (!stagesAreValid) return false;
    if (lab.degree === 1) {
      return lab.roots.length === 1 && Number.isInteger(lab.roots[0]);
    }
    const { a, b, c } = lab.coefficients;
    const discriminant = b * b - 4 * a * c;
    if (a === 0 || discriminant !== lab.discriminant) return false;
    const rootsAreExact = lab.roots.every((root) => a * root * root + b * root + c === 0);
    const expectedRootCount = discriminant > 0 ? 2 : discriminant === 0 ? 1 : 0;
    return rootsAreExact && lab.roots.length === expectedRootCount;
  }
  validateGraphWorkshop(puzzle) {
    const workshop = puzzle.graphWorkshop;
    if (!workshop || workshop.parameters.length < 2 || workshop.targetPoints.length === 0) return false;
    const keys = new Set(workshop.parameters.map((parameter) => parameter.key));
    if (keys.size !== workshop.parameters.length) return false;
    const parametersAreValid = workshop.parameters.every((parameter) => Number.isInteger(parameter.target) && Number.isInteger(parameter.initial) && parameter.target >= parameter.min && parameter.target <= parameter.max && parameter.initial >= parameter.min && parameter.initial <= parameter.max && parameter.step > 0);
    if (!parametersAreValid) return false;
    if (workshop.functionKind === "linear") {
      return keys.has("m") && keys.has("q") && workshop.parameters.length === 2;
    }
    const a = workshop.parameters.find((parameter) => parameter.key === "a");
    return keys.has("a") && keys.has("h") && keys.has("k") && workshop.parameters.length === 3 && (a == null ? void 0 : a.target) !== 0;
  }
}
class RobotPuzzleValidator {
  constructor() {
    __publicField(this, "solver", new GridPathSolver());
  }
  validate(puzzle) {
    const obstacleKeys = new Set(puzzle.obstacles.map((cell) => `${cell.col}:${cell.row}`));
    const keyBlocked = obstacleKeys.has(`${puzzle.key.col}:${puzzle.key.row}`);
    const exitBlocked = obstacleKeys.has(`${puzzle.exit.col}:${puzzle.exit.row}`);
    const checkpointBlocked = (puzzle.checkpoints ?? []).some((cell) => obstacleKeys.has(`${cell.col}:${cell.row}`));
    const toKey = this.solver.findCommandPath(puzzle.cols, puzzle.rows, puzzle.start, puzzle.key, puzzle.obstacles);
    const keyState = toKey ? this.solver.simulate(puzzle.start, toKey) : { ...puzzle.key, facing: puzzle.start.facing };
    const toExit = this.solver.findCommandPath(puzzle.cols, puzzle.rows, keyState, puzzle.exit, puzzle.obstacles);
    const programWorks = this.programSatisfiesPuzzle(puzzle, puzzle.solutionCommands);
    const pickupCount = puzzle.solutionCommands.filter((command) => command === "PICK_UP").length;
    const exitCount = puzzle.solutionCommands.filter((command) => command === "EXIT").length;
    const startKeyDistinct = puzzle.start.col !== puzzle.key.col || puzzle.start.row !== puzzle.key.row;
    const keyExitDistinct = puzzle.key.col !== puzzle.exit.col || puzzle.key.row !== puzzle.exit.row;
    const hasClearFinish = pickupCount === 1 && exitCount === 1 && puzzle.solutionCommands[puzzle.solutionCommands.length - 1] === "EXIT";
    return !keyBlocked && !exitBlocked && !checkpointBlocked && startKeyDistinct && keyExitDistinct && Boolean(toKey) && Boolean(toExit) && puzzle.solutionCommands.length > 0 && hasClearFinish && programWorks;
  }
  programSatisfiesPuzzle(puzzle, commands) {
    const turn = (facing, direction) => {
      const order = ["N", "E", "S", "W"];
      const offset = direction === "R" ? 1 : -1;
      return order[(order.indexOf(facing) + offset + order.length) % order.length];
    };
    const checkpoints = [...puzzle.checkpoints ?? []].sort((a, b) => a.order - b.order);
    let checkpointIndex = 0;
    let state = { ...puzzle.start };
    let hasKey = false;
    for (const command of commands) {
      if (command === "TURN_LEFT") {
        state.facing = turn(state.facing, "L");
      } else if (command === "TURN_RIGHT") {
        state.facing = turn(state.facing, "R");
      } else if (command === "MOVE_FORWARD") {
        const delta = { N: [0, -1], E: [1, 0], S: [0, 1], W: [-1, 0] }[state.facing];
        const next = { col: state.col + delta[0], row: state.row + delta[1], facing: state.facing };
        const blocked = next.col < 0 || next.row < 0 || next.col >= puzzle.cols || next.row >= puzzle.rows || puzzle.obstacles.some((cell) => cell.col === next.col && cell.row === next.row);
        if (blocked) {
          return false;
        }
        state = next;
        const checkpoint = checkpoints[checkpointIndex];
        if (checkpoint && state.col === checkpoint.col && state.row === checkpoint.row) {
          checkpointIndex += 1;
        }
      } else if (command === "PICK_UP") {
        if (checkpointIndex < checkpoints.length || state.col !== puzzle.key.col || state.row !== puzzle.key.row) {
          return false;
        }
        hasKey = true;
      } else if (command === "EXIT") {
        return hasKey && checkpointIndex === checkpoints.length && state.col === puzzle.exit.col && state.row === puzzle.exit.row;
      }
    }
    return false;
  }
}
class PuzzleGenerator {
  constructor(validationEngine) {
    __publicField(this, "mathGenerator", new MathPuzzleGenerator());
    __publicField(this, "robotGenerator", new RobotGridGenerator());
    __publicField(this, "codingGenerator", new CodingPuzzleGenerator());
    __publicField(this, "musicGenerator", new MusicNoteGenerator());
    __publicField(this, "circuitGenerator", new CircuitFaultGenerator());
    __publicField(this, "languageGenerator", new LanguageCorruptionGenerator());
    __publicField(this, "englishGenerator", new EnglishInstructionGenerator());
    __publicField(this, "mathValidator", new MathPuzzleValidator());
    __publicField(this, "robotValidator", new RobotPuzzleValidator());
    __publicField(this, "codingValidator", new CodingPuzzleValidator());
    __publicField(this, "circuitValidator", new CircuitPuzzleValidator());
    __publicField(this, "languageValidator", new LanguagePuzzleValidator());
    this.validationEngine = validationEngine;
  }
  generate(random, difficulty, focus = []) {
    const mathRandom = random.fork("math");
    const robotRandom = random.fork("robot");
    const circuitRandom = random.fork("circuit");
    const languageRandom = random.fork("language");
    const englishRandom = random.fork("english");
    const musicRandom = random.fork("music");
    const codingRandom = random.fork("coding");
    const mathDifficulty = this.boostForFocus(difficulty, focus, "matematica");
    const robotDifficulty = this.boostForFocus(difficulty, focus, "coding");
    const circuitDifficulty = this.boostForFocus(difficulty, focus, "elettronica");
    const languageLevel = this.levelForFocus(difficulty.level, focus, "italiano");
    const englishLevel = this.levelForFocus(difficulty.level, focus, "inglese");
    const musicLevel = this.levelForFocus(difficulty.level, focus, "musica");
    const codingDifficulty = this.boostForFocus(difficulty, focus, "coding");
    const math = this.validationEngine.generateWithRetries(
      () => this.mathGenerator.generateGraphWorkshop(mathRandom, mathDifficulty),
      (puzzle) => this.mathValidator.validate(puzzle),
      () => this.mathGenerator.generateGraphWorkshop(mathRandom.fork("fallback"), mathDifficulty)
    );
    const robot = this.validationEngine.generateWithRetries(
      () => this.robotGenerator.generate(robotRandom, robotDifficulty),
      (puzzle) => this.robotValidator.validate(puzzle),
      () => this.robotGenerator.fallback(void 0, robotRandom.fork("fallback"))
    );
    const circuit = this.validationEngine.generateWithRetries(
      () => this.circuitGenerator.generate(circuitRandom, circuitDifficulty),
      (puzzle) => this.circuitValidator.validate(puzzle),
      () => this.circuitGenerator.fallback(circuitDifficulty.level, circuitRandom.fork("fallback"), circuitDifficulty)
    );
    const coding = this.validationEngine.generateWithRetries(
      () => this.codingGenerator.generate(codingRandom, codingDifficulty),
      (puzzle) => this.codingValidator.validate(puzzle),
      () => this.codingGenerator.fallback(codingRandom.fork("fallback"), codingDifficulty)
    );
    return {
      math: exerciseDirector.enrichMath(math, mathDifficulty.level),
      robot: exerciseDirector.enrichRobot(robot, robotDifficulty.level),
      circuit: exerciseDirector.enrichCircuit(circuit, circuitDifficulty.level),
      coding,
      language: this.validationEngine.generateWithRetries(
        () => this.languageGenerator.generate(languageRandom, languageLevel),
        (puzzle) => this.languageValidator.validateItalian(puzzle),
        () => this.languageGenerator.fallback(languageRandom.fork("fallback"), languageLevel)
      ),
      english: this.validationEngine.generateWithRetries(
        () => this.englishGenerator.generate(englishRandom, englishLevel),
        (puzzle) => this.languageValidator.validateEnglish(puzzle),
        () => this.englishGenerator.fallback(englishRandom.fork("fallback"), englishLevel)
      ),
      music: this.musicGenerator.generate(musicRandom, musicLevel)
    };
  }
  generateFocusChallenges(random, difficulty, focus, kind, stages) {
    return stages.map((stage, index) => {
      var _a2;
      const stagedDifficulty = this.escalateDifficulty(this.boostForFocus(difficulty, focus, this.domainForKind(kind)), index);
      const challengeRandom = random.fork(`${kind}-${index + 1}`);
      const id = `${kind}-${index + 1}`;
      if (kind === "math") {
        const graphStageIndex = Math.min(1, Math.max(0, stages.length - 1));
        const useGraphWorkshop = index === graphStageIndex;
        const useMinigame = !useGraphWorkshop && index % 2 === 0;
        const puzzle2 = this.validationEngine.generateWithRetries(
          () => useGraphWorkshop ? this.mathGenerator.generateGraphWorkshop(challengeRandom, stagedDifficulty) : useMinigame ? this.mathGenerator.generateMinigame(challengeRandom, stagedDifficulty, this.mathMinigameTypesForStep(index)) : this.mathGenerator.generate(challengeRandom, stagedDifficulty, this.mathArchetypesForStep(index)),
          (candidate) => this.mathValidator.validate(candidate),
          () => useGraphWorkshop ? this.mathGenerator.generateGraphWorkshop(challengeRandom.fork("fallback"), stagedDifficulty) : this.mathGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty)
        );
        return {
          id,
          kind,
          title: useGraphWorkshop ? "Officina dei Grafici" : stage.label,
          description: useGraphWorkshop ? ((_a2 = puzzle2.graphWorkshop) == null ? void 0 : _a2.objective) ?? "Modifica i parametri e certifica il grafico sul piano cartesiano." : stage.description,
          difficultyStep: index + 1,
          puzzle: exerciseDirector.enrichMath(puzzle2, stagedDifficulty.level)
        };
      }
      if (kind === "language") {
        const useMinigame = [0, 1, 3].includes(index);
        const puzzle2 = this.validationEngine.generateWithRetries(
          () => useMinigame ? this.languageGenerator.generateMinigame(challengeRandom, stagedDifficulty.level, this.languageMinigameTypesForStep(index)) : this.languageGenerator.generate(challengeRandom, stagedDifficulty.level, this.languageTemplatesForStep(index)),
          (candidate) => this.languageValidator.validateItalian(candidate),
          () => this.languageGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty.level)
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle: puzzle2 };
      }
      if (kind === "english") {
        const useMinigame = [0, 1, 2, 4].includes(index);
        const puzzle2 = this.validationEngine.generateWithRetries(
          () => useMinigame ? this.englishGenerator.generateMinigame(challengeRandom, stagedDifficulty.level, this.englishMinigameTypesForStep(index)) : this.englishGenerator.generate(challengeRandom, stagedDifficulty.level, this.englishTemplatesForStep(index)),
          (candidate) => this.languageValidator.validateEnglish(candidate),
          () => this.englishGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty.level)
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle: puzzle2 };
      }
      if (kind === "music") {
        const puzzle2 = this.musicGenerator.generate(challengeRandom, stagedDifficulty.level);
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle: puzzle2 };
      }
      if (kind === "coding") {
        const useMinigame = [0, 1, 2, 4].includes(index);
        const puzzle2 = this.validationEngine.generateWithRetries(
          () => useMinigame ? this.codingGenerator.generateMinigame(challengeRandom, stagedDifficulty, this.codingMinigameTypesForStep(index)) : this.codingGenerator.generate(challengeRandom, stagedDifficulty, this.codingChallengeTypesForStep(index)),
          (candidate) => this.codingValidator.validate(candidate),
          () => this.codingGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty)
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle: puzzle2 };
      }
      if (kind === "circuit") {
        const puzzle2 = this.validationEngine.generateWithRetries(
          () => this.circuitGenerator.generate(challengeRandom, stagedDifficulty, this.circuitFaultsForStep(index)),
          (candidate) => this.circuitValidator.validate(candidate),
          () => this.circuitGenerator.fallback(stagedDifficulty.level, challengeRandom.fork("fallback"), stagedDifficulty)
        );
        return {
          id,
          kind,
          title: stage.label,
          description: stage.description,
          difficultyStep: index + 1,
          puzzle: exerciseDirector.enrichCircuit(puzzle2, stagedDifficulty.level)
        };
      }
      const robotType = this.robotChallengeTypeForStep(index, difficulty.level);
      const puzzle = this.validationEngine.generateWithRetries(
        () => this.robotGenerator.generate(challengeRandom, stagedDifficulty, robotType),
        (candidate) => this.robotValidator.validate(candidate),
        () => this.robotGenerator.fallback(robotType, challengeRandom.fork("fallback"))
      );
      return {
        id,
        kind,
        title: stage.label,
        description: stage.description,
        difficultyStep: index + 1,
        puzzle: exerciseDirector.enrichRobot(puzzle, stagedDifficulty.level)
      };
    });
  }
  boostForFocus(difficulty, focus, domain) {
    if (!this.hasFocus(focus, domain)) {
      return difficulty;
    }
    const boostedLevel = Math.min(8, difficulty.level + 1);
    return {
      ...difficulty,
      level: boostedLevel,
      mathComplexity: domain === "matematica" ? Math.min(8, difficulty.mathComplexity + 2) : difficulty.mathComplexity,
      robotGrid: domain === "coding" ? { cols: Math.min(9, difficulty.robotGrid.cols + 1), rows: difficulty.robotGrid.rows } : difficulty.robotGrid,
      robotObstacleCount: domain === "coding" ? difficulty.robotObstacleCount + 2 : difficulty.robotObstacleCount,
      circuitComplexity: domain === "elettronica" ? Math.min(8, difficulty.circuitComplexity + 2) : difficulty.circuitComplexity,
      requiredReasoningSteps: Math.min(5, difficulty.requiredReasoningSteps + 1),
      noiseDataCount: Math.min(4, difficulty.noiseDataCount + 1)
    };
  }
  levelForFocus(level, focus, domain) {
    return this.hasFocus(focus, domain) ? Math.min(8, level + 2) : level;
  }
  hasFocus(focus, domain) {
    return focus.includes(domain) || focus.some((item) => item.startsWith(`${domain}.`));
  }
  escalateDifficulty(difficulty, step) {
    return {
      ...difficulty,
      level: Math.min(8, difficulty.level + step),
      mathComplexity: Math.min(8, difficulty.mathComplexity + step),
      robotGrid: {
        cols: Math.min(9, difficulty.robotGrid.cols + Math.floor((step + 1) / 2)),
        rows: Math.min(7, difficulty.robotGrid.rows + Math.floor(step / 2))
      },
      robotObstacleCount: difficulty.robotObstacleCount + step * 2,
      circuitComplexity: Math.min(8, difficulty.circuitComplexity + step),
      requiredReasoningSteps: Math.min(5, difficulty.requiredReasoningSteps + Math.ceil(step / 2)),
      noiseDataCount: Math.min(4, difficulty.noiseDataCount + Math.floor(step / 2))
    };
  }
  domainForKind(kind) {
    return {
      language: "italiano",
      circuit: "elettronica",
      math: "matematica",
      english: "inglese",
      music: "musica",
      robot: "coding",
      coding: "coding"
    }[kind];
  }
  codingChallengeTypesForStep(step) {
    return [
      ["trace-output", "variable-state"],
      ["variable-state", "trace-output"],
      ["loop-count", "conditional-branch"],
      ["conditional-branch", "boolean-logic"],
      ["debug-line", "boolean-logic", "loop-count"]
    ][Math.min(step, 4)];
  }
  codingMinigameTypesForStep(step) {
    return [
      ["sequence-builder"],
      ["state-tracer"],
      ["bug-hunt"],
      ["state-tracer", "sequence-builder"],
      ["bug-hunt", "state-tracer", "sequence-builder"]
    ][Math.min(step, 4)];
  }
  mathArchetypesForStep(step) {
    return [
      ["calcolo-diretto", "frazioni", "percentuali", "lettura-dati"],
      ["sequenza", "statistica", "coordinate", "lettura-dati", "vincolo"],
      ["vincolo", "proporzione", "geometria", "probabilita", "percentuali", "frazioni"],
      ["ragionamento-inverso", "pre-algebra", "equazione-primo-grado", "funzione-lineare", "grafici-cartesiani", "coordinate", "statistica"],
      ["diagnosi-errore", "potenze-radici", "geometria", "sistemi-lineari", "probabilita", "equazione-primo-grado", "equazione-secondo-grado", "grafici-cartesiani", "funzione-lineare", "proporzione"]
    ][Math.min(step, 4)];
  }
  mathMinigameTypesForStep(step) {
    return [
      ["target-sum"],
      ["target-sum", "factor-hunt"],
      ["factor-hunt", "operation-chain"],
      ["operation-chain", "target-sum"],
      ["operation-chain", "factor-hunt", "target-sum"]
    ][Math.min(step, 4)];
  }
  robotChallengeTypeForStep(step, level = 1) {
    if (step >= 4 && level >= 7) {
      return "loop-compression";
    }
    if (step >= 4 && level >= 5) {
      return "conditional-gate";
    }
    return [
      "route-planning",
      "coordinate-routing",
      "checkpoint-order",
      "minimal-route",
      "debug-program"
    ][Math.min(step, 4)];
  }
  languageTemplatesForStep(step) {
    return [
      ["single-generator", "north-sensor", "sealed-door", "unstable-log", "apostrophe-accent", "ha-a-control"],
      ["cause-effect-cooling", "useful-vs-noise", "sequence-before-after", "direct-indirect-pronouns", "concessive-although"],
      ["pronoun-reference", "robot-report", "relative-clause", "relative-cui", "punctuation-safety"],
      ["conditional-alert", "technical-summary", "source-reliability", "passive-active", "reported-speech-log", "main-idea-summary"],
      ["lexical-precision", "nominalization-precision", "thesis-evidence", "register-formal", "period-hypothesis", "implicit-subject"]
    ][Math.min(step, 4)];
  }
  languageMinigameTypesForStep(step) {
    return [
      ["agreement-sprint"],
      ["intruder-hunt"],
      ["connector-route"],
      ["connector-route"],
      ["intruder-hunt", "agreement-sprint", "connector-route"]
    ][Math.min(step, 4)];
  }
  englishTemplatesForStep(step) {
    return [
      ["green-not-red", "small-key", "main-switch", "where-is-core", "who-can-open", "possessive-their-its", "movement-prepositions-route"],
      ["left-before-blue", "inspect-record-reset", "measure-before-switch", "simple-vs-now", "past-log-today", "some-any-fuses", "much-many-supplies", "present-perfect-already-yet"],
      ["procedure-debug-charge", "sensor-below-threshold", "at-least-three-pulses", "frequency-adverbs", "first-conditional-alarm", "zero-conditional-rule", "adverbs-manner-safety"],
      ["only-if-stable", "compare-two-signals", "neither-red-nor-yellow", "replace-only-damaged", "which-route-safest", "relative-drawer", "going-to-scan", "past-vs-present-perfect-log", "although-however-report", "main-idea-log", "detail-not-mentioned", "question-formation-why", "relative-where-lab"],
      ["cause-report", "between-limits", "unless-blue-blinks", "until-door-unlocks", "not-until-pressure-drops", "must-should-cable", "may-must-not", "passive-reattach-wire", "pronoun-reference", "as-as-comparison", "passive-simple-past", "have-to-vs-can", "word-formation-re-over", "scientific-observation-evidence", "reported-warning", "either-neither-tool", "multi-clause-mission-order", "email-register-formal"]
    ][Math.min(step, 4)];
  }
  englishMinigameTypesForStep(step) {
    return [
      ["action-relay"],
      ["sequence-switchboard"],
      ["data-command-scan"],
      ["sequence-switchboard", "action-relay"],
      ["action-relay", "sequence-switchboard", "data-command-scan"]
    ][Math.min(step, 4)];
  }
  circuitFaultsForStep(step) {
    return [
      ["missing-wire", "open-switch"],
      ["missing-resistor", "wrong-resistor-value", "reversed-led"],
      ["sensor-unpowered", "disconnected-component", "short-circuit"],
      ["parallel-branch-open", "capacitor-discharged", "loose-ground"],
      ["relay-not-armed", "short-circuit", "wrong-resistor-value", "parallel-branch-open"]
    ][Math.min(step, 4)];
  }
}
class ValidationEngine {
  generateWithRetries(factory, validate, fallbackFactory, maxAttempts = 40) {
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const candidate = factory();
      if (validate(candidate)) {
        return candidate;
      }
    }
    const fallback = fallbackFactory();
    if (validate(fallback)) {
      return fallback;
    }
    throw new Error("Procedural generation failed: fallback did not pass validation");
  }
}
class ChallengeQualityValidator {
  validateMission(mission, difficulty) {
    const reports = [
      this.validateMath(mission.puzzles.math, difficulty),
      this.validateRobot(mission.puzzles.robot, difficulty),
      this.validateCircuit(mission.puzzles.circuit, difficulty),
      this.validateCoding(mission.puzzles.coding),
      this.validateLanguage(mission.puzzles.language),
      this.validateEnglish(mission.puzzles.english),
      this.validateMusic(mission.puzzles.music)
    ];
    const reasons = reports.flatMap((report) => report.reasons);
    return { valid: reasons.length === 0, reasons };
  }
  validateMath(puzzle, difficulty) {
    var _a2;
    const reasons = [];
    const steps = ((_a2 = puzzle.solutionSteps) == null ? void 0 : _a2.length) ?? 0;
    const asksRounding = /arrotond/i.test(puzzle.prompt);
    if (steps < Math.min(3, Math.max(2, difficulty.mathComplexity))) {
      reasons.push("math: meno di 2-3 passaggi cognitivi");
    }
    if (difficulty.level >= 3 && /^.*\b(triplo|doppio|metà)\b.*$/i.test(puzzle.prompt) && steps < 3) {
      reasons.push("math: troppo vicino al calcolo diretto");
    }
    if (puzzle.hints.length < 2 || puzzle.hints.some((hint) => String(puzzle.answer) === hint.trim())) {
      reasons.push("math: indizi insufficienti o troppo espliciti");
    }
    if (!puzzle.difficultyLabel || !puzzle.learningPurpose || !puzzle.calculationAid) {
      reasons.push("math: mancano livello, scopo didattico o supporto al calcolo");
    }
    if (!puzzle.prompt.includes("Situazione:") || !puzzle.prompt.includes("Richiesta:")) {
      reasons.push("math: formulazione non separa contesto e richiesta");
    }
    if (!Number.isInteger(puzzle.answer) || !/numero intero/i.test(puzzle.prompt) && !puzzle.equationLab && !puzzle.graphWorkshop) {
      reasons.push("math: risposta numerica non esplicitamente intera");
    }
    if (asksRounding && !/,5|superiore|inferiore|regola indicata|senza arrotondare/i.test(puzzle.prompt)) {
      reasons.push("math: arrotondamento non univoco");
    }
    if (puzzle.equationLab) {
      const expectedStages = puzzle.equationLab.degree === 1 ? 4 : 5;
      if (puzzle.equationLab.stages.length < expectedStages) {
        reasons.push("math: laboratorio equazioni troppo breve");
      }
      if (puzzle.equationLab.stages.some((stage) => new Set(stage.options).size !== 4 || !stage.options.includes(stage.correctOption))) {
        reasons.push("math: laboratorio equazioni con opzioni ambigue");
      }
      if (puzzle.equationLab.degree === 2 && !puzzle.equationLab.stages.some((stage) => stage.visual === "parabola")) {
        reasons.push("math: equazione quadratica senza collegamento grafico");
      }
    }
    if (puzzle.graphWorkshop) {
      if (puzzle.graphWorkshop.parameters.length < 2 || puzzle.graphWorkshop.targetPoints.length === 0) {
        reasons.push("math: officina grafica senza parametri o riferimenti");
      }
      if (puzzle.graphWorkshop.functionKind === "quadratic" && !puzzle.graphWorkshop.parameters.some((parameter) => parameter.key === "a" && parameter.target !== 0)) {
        reasons.push("math: parabola grafica degenere");
      }
      if (puzzle.graphWorkshop.parameters.every((parameter) => parameter.initial === parameter.target)) {
        reasons.push("math: officina grafica gia risolta");
      }
    }
    return { valid: reasons.length === 0, reasons };
  }
  validateRobot(puzzle, difficulty) {
    var _a2;
    const reasons = [];
    if (puzzle.solutionCommands.length < Math.max(6, difficulty.robotGrid.cols + difficulty.robotGrid.rows - 2)) {
      reasons.push("robot: soluzione troppo breve");
    }
    if (difficulty.level >= 3 && puzzle.obstacles.length < Math.max(2, difficulty.robotObstacleCount - 1)) {
      reasons.push("robot: pochi vincoli spaziali");
    }
    if (puzzle.hints.length < 2 || puzzle.instructions.length < 2) {
      reasons.push("robot: istruzioni o indizi insufficienti");
    }
    if ((puzzle.challengeType === "checkpoint-order" || puzzle.challengeType === "pattern-routing" || puzzle.challengeType === "conditional-gate" || puzzle.challengeType === "loop-compression") && (((_a2 = puzzle.checkpoints) == null ? void 0 : _a2.length) ?? 0) === 0) {
      reasons.push("robot: sfida checkpoint senza checkpoint");
    }
    if (puzzle.solutionCommands.filter((command) => command === "PICK_UP").length !== 1 || puzzle.solutionCommands.filter((command) => command === "EXIT").length !== 1 || puzzle.solutionCommands[puzzle.solutionCommands.length - 1] !== "EXIT") {
      reasons.push("robot: soluzione senza raccolta unica e uscita finale chiara");
    }
    if (puzzle.challengeType === "debug-program" && (!puzzle.buggedCommands || puzzle.buggedCommands.join(",") === puzzle.solutionCommands.join(","))) {
      reasons.push("robot: debug senza programma guasto plausibile");
    }
    if (puzzle.challengeType === "minimal-route" && (puzzle.maxCommands ?? 999) > puzzle.solutionCommands.length + 2) {
      reasons.push("robot: percorso minimo con budget troppo largo");
    }
    if (puzzle.challengeType === "coordinate-routing" && !puzzle.coordinateLabels) {
      reasons.push("robot: sfida coordinate senza griglia coordinate");
    }
    if (difficulty.level >= 5 && !puzzle.planningPrompt) {
      reasons.push("robot: manca richiesta di pianificazione esplicita");
    }
    return { valid: reasons.length === 0, reasons };
  }
  validateCircuit(puzzle, difficulty) {
    const reasons = [];
    const minimumFaults = difficulty.level >= 5 ? 2 : 1;
    if (puzzle.faults.length < minimumFaults) {
      reasons.push("circuit: diagnosi troppo corta");
    }
    if (puzzle.observations.length < puzzle.faults.length + 1) {
      reasons.push("circuit: pochi sintomi da interpretare");
    }
    if (!puzzle.diagnosticQuestion || puzzle.hints.length < 2) {
      reasons.push("circuit: domanda diagnostica o indizi mancanti");
    }
    if (!puzzle.testerReadings || puzzle.testerReadings.length < puzzle.faults.length + 1) {
      reasons.push("circuit: letture tester insufficienti");
    }
    if (!puzzle.repairChoices || puzzle.repairChoices.length <= puzzle.requiredRepairs.length) {
      reasons.push("circuit: mancano distrattori plausibili");
    }
    if (!puzzle.learningPurpose || !puzzle.diagnosticPlan || puzzle.diagnosticPlan.length < 3 || !puzzle.conceptTags || puzzle.conceptTags.length < 2) {
      reasons.push("circuit: mancano scopo didattico, piano diagnostico o concetti");
    }
    if (difficulty.level >= 4) {
      const componentChecks = puzzle.componentChallenges ?? [];
      if (componentChecks.length < 1) {
        reasons.push("circuit: livelli alti senza riconoscimento simboli/componenti");
      }
      if (componentChecks.some((check) => check.symbolChoices.length < 3 || check.functionChoices.length < 3)) {
        reasons.push("circuit: scelte componente troppo povere");
      }
    }
    return { valid: reasons.length === 0, reasons };
  }
  validateCoding(puzzle) {
    const reasons = [];
    const uniqueOptions = new Set(puzzle.options);
    if (puzzle.codeLines.length < 3) {
      reasons.push("coding: programma troppo corto per allenare tracing");
    }
    if (puzzle.options.length < 4 || uniqueOptions.size !== puzzle.options.length || !uniqueOptions.has(puzzle.correctOption)) {
      reasons.push("coding: opzioni non uniche o risposta corretta assente");
    }
    if (puzzle.methodSteps.length < 3 || puzzle.hints.length < 2) {
      reasons.push("coding: metodo o indizi insufficienti");
    }
    if (!puzzle.learningPurpose || puzzle.learningPurpose.length < 40 || puzzle.explanation.length < 45) {
      reasons.push("coding: scopo didattico o spiegazione troppo deboli");
    }
    if (puzzle.challengeType === "debug-line" && !puzzle.question.toLowerCase().includes("correzione")) {
      reasons.push("coding: debug senza richiesta esplicita di correzione");
    }
    if ((puzzle.challengeType === "loop-count" || puzzle.challengeType === "conditional-branch") && puzzle.codeLines.length < 4) {
      reasons.push("coding: ciclo/condizione senza abbastanza righe di contesto");
    }
    return { valid: reasons.length === 0, reasons };
  }
  validateLanguage(puzzle) {
    const reasons = [];
    const uniqueOptions = new Set(puzzle.options);
    if (puzzle.options.length < 4 || uniqueOptions.size !== puzzle.options.length) {
      reasons.push("language: servono almeno quattro distrattori unici");
    }
    if (!puzzle.options.includes(puzzle.repaired)) {
      reasons.push("language: correzione assente tra le opzioni");
    }
    if (puzzle.diagnosticSteps.length < 2 || puzzle.hints.length < 2) {
      reasons.push("language: diagnostica troppo povera");
    }
    if (!puzzle.learningPurpose || !puzzle.repairGoal || !puzzle.method || !puzzle.conceptTags || puzzle.conceptTags.length < 2) {
      reasons.push("language: mancano scopo, metodo o concetti didattici");
    }
    if (!puzzle.optionFeedback || puzzle.options.some((option) => {
      var _a2, _b;
      return option !== puzzle.repaired && (((_b = (_a2 = puzzle.optionFeedback) == null ? void 0 : _a2[option]) == null ? void 0 : _b.length) ?? 0) < 40;
    })) {
      reasons.push("language: feedback dei distrattori insufficiente");
    }
    return { valid: reasons.length === 0, reasons };
  }
  validateEnglish(puzzle) {
    var _a2;
    const reasons = [];
    const correctCount = puzzle.choices.filter((choice) => choice.isCorrect).length;
    const uniqueLabels = new Set(puzzle.choices.map((choice) => choice.label));
    if (puzzle.choices.length < 3 || correctCount !== 1 || uniqueLabels.size !== puzzle.choices.length) {
      reasons.push("english: distrattori non validi");
    }
    if (puzzle.choices.some((choice) => choice.feedback.length < 20)) {
      reasons.push("english: feedback troppo debole");
    }
    if (puzzle.hints.length < 2) {
      reasons.push("english: indizi insufficienti");
    }
    if (!puzzle.learningPurpose || !puzzle.commandGoal || !puzzle.method || !puzzle.conceptTags || puzzle.conceptTags.length < 2) {
      reasons.push("english: mancano scopo, metodo o concetti didattici");
    }
    if (!puzzle.glossary || puzzle.glossary.length === 0) {
      reasons.push("english: glossario operativo mancante");
    }
    if (puzzle.challengeType === "data-reading" && (((_a2 = puzzle.dataPoints) == null ? void 0 : _a2.length) ?? 0) === 0) {
      reasons.push("english: sfida dati senza dati leggibili");
    }
    if ((puzzle.challengeType === "procedure-debug" || puzzle.challengeType === "inference") && !puzzle.sourceText) {
      reasons.push("english: sfida testuale senza log o testo sorgente");
    }
    return { valid: reasons.length === 0, reasons };
  }
  validateMusic(puzzle) {
    const reasons = [];
    const correctCount = puzzle.choices.filter((choice) => choice.isCorrect).length;
    const uniqueLabels = new Set(puzzle.choices.map((choice) => choice.label));
    if (puzzle.choices.length < 4 || correctCount !== 1 || uniqueLabels.size !== puzzle.choices.length) {
      reasons.push("music: servono quattro opzioni uniche e una sola risposta corretta");
    }
    if (puzzle.hints.length < 3 || !puzzle.learningPurpose || !puzzle.method || puzzle.methodSteps.length < 3) {
      reasons.push("music: mancano indizi, scopo o metodo di lettura");
    }
    if (puzzle.timeLimitMs < 6e3 || puzzle.timeLimitMs > 24e3) {
      reasons.push("music: tempo di risposta fuori range didattico");
    }
    if ((puzzle.staffPosition <= -2 || puzzle.staffPosition >= 10) && puzzle.ledgerLines.length === 0) {
      reasons.push("music: nota esterna senza linee addizionali");
    }
    return { valid: reasons.length === 0, reasons };
  }
}
class MapValidator {
  validate(map) {
    const ids = new Set(map.hotspots.map((hotspot) => hotspot.id));
    const puzzleHotspots = map.hotspots.filter((hotspot) => Boolean(hotspot.puzzleId));
    const hasRequired = ids.has("door") && puzzleHotspots.length >= 1;
    const puzzleIds = new Set(puzzleHotspots.map((hotspot) => hotspot.puzzleId));
    const coherentFocus = puzzleHotspots.length === 1 || puzzleIds.size === puzzleHotspots.length;
    const nonOverlapping = map.hotspots.every(
      (hotspot, index) => map.hotspots.every((other, otherIndex) => {
        if (index === otherIndex) {
          return true;
        }
        const distance = Math.hypot(hotspot.x - other.x, hotspot.y - other.y);
        return distance > hotspot.radius + other.radius + 18;
      })
    );
    return hasRequired && coherentFocus && nonOverlapping;
  }
}
class MissionGenerator {
  constructor() {
    __publicField(this, "validationEngine", new ValidationEngine());
    __publicField(this, "puzzleGenerator", new PuzzleGenerator(this.validationEngine));
    __publicField(this, "mapGenerator", new MapGenerator());
    __publicField(this, "mapValidator", new MapValidator());
    __publicField(this, "qualityValidator", new ChallengeQualityValidator());
  }
  generate(seed, random, difficulty, focus) {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const candidate = this.buildMission(seed, random.fork(`mission-${attempt}`), difficulty, focus);
      if (this.qualityValidator.validateMission(candidate, difficulty).valid) {
        return candidate;
      }
    }
    return this.buildMission(seed, new Random(`${seed}:quality-fallback`), difficulty, focus);
  }
  buildMission(seed, random, difficulty, focus) {
    const path = getProceduralFocusPath(focus);
    const puzzles = this.puzzleGenerator.generate(random.fork("puzzles"), difficulty, focus);
    const focusStages = path.primaryPuzzle ? path.challengeStages.slice(0, proceduralFocusChallengeCount(difficulty.level)) : [];
    const focusChallenges = path.primaryPuzzle ? this.puzzleGenerator.generateFocusChallenges(random.fork("focus-series"), difficulty, focus, path.primaryPuzzle, focusStages) : void 0;
    const map = this.validationEngine.generateWithRetries(
      () => this.mapGenerator.generate(random.fork("map"), difficulty, focus),
      (candidate) => this.mapValidator.validate(candidate),
      () => this.mapGenerator.generate(random.fork("fallback-map"), difficulty, focus)
    );
    const competencies = Array.from(
      /* @__PURE__ */ new Set([
        ...focus,
        ...focusChallenges ? focusChallenges.flatMap((challenge) => challenge.puzzle.competencies) : [
          ...puzzles.math.competencies,
          ...puzzles.robot.competencies,
          ...puzzles.circuit.competencies,
          ...puzzles.language.competencies,
          ...puzzles.english.competencies,
          ...puzzles.music.competencies
        ]
      ])
    );
    return {
      id: `mission-procedural-${path.id}`,
      seed,
      difficulty: difficulty.level,
      title: path.title,
      intro: `${random.pick(path.introFragments)} ${this.focusLine(focus)}`,
      objectives: focusChallenges ? focusChallenges.map((challenge) => ({
        id: `procedural-${challenge.id}`,
        label: challenge.title,
        description: challenge.description,
        competencies: challenge.puzzle.competencies
      })) : [
        {
          id: "procedural-language",
          label: path.objectives.language.label,
          description: path.objectives.language.description,
          competencies: puzzles.language.competencies
        },
        {
          id: "procedural-circuit",
          label: path.objectives.circuit.label,
          description: path.objectives.circuit.description,
          competencies: puzzles.circuit.competencies
        },
        {
          id: "procedural-math",
          label: path.objectives.math.label,
          description: path.objectives.math.description,
          competencies: puzzles.math.competencies
        },
        {
          id: "procedural-english",
          label: path.objectives.english.label,
          description: path.objectives.english.description,
          competencies: puzzles.english.competencies
        },
        {
          id: "procedural-robot",
          label: path.objectives.robot.label,
          description: path.objectives.robot.description,
          competencies: puzzles.robot.competencies
        },
        {
          id: "procedural-music",
          label: path.objectives.music.label,
          description: path.objectives.music.description,
          competencies: puzzles.music.competencies
        }
      ],
      map,
      puzzles,
      focusChallenges,
      rewards: [
        path.badge,
        {
          badgeId: "custode-del-seed",
          label: "Custode del Seed",
          description: "Sa riprodurre una missione usando il seed."
        }
      ],
      competencies
    };
  }
  focusLine(focus) {
    const label = this.focusLabel(focus);
    if (label === "libera") {
      return "Puoi iniziare da qualunque console: la porta finale controllerà il sistema completo.";
    }
    return `Allenamento attivo: ${label}. Le console generate appartengono a questa materia e misurano tempo, precisione e uso degli aiuti.`;
  }
  focusLabel(focus) {
    if (focus.includes("matematica")) return "matematica";
    if (focus.includes("italiano")) return "italiano";
    if (focus.includes("inglese")) return "inglese";
    if (focus.includes("elettronica")) return "elettronica";
    if (focus.includes("coding")) return "coding";
    if (focus.includes("musica")) return "musica";
    return "libera";
  }
}
class SeedManager {
  constructor() {
    __publicField(this, "volatileSerial", 0);
  }
  createRandomSeed(prefix = "ELI") {
    var _a2;
    const bytes = new Uint32Array(2);
    if ((_a2 = globalThis.crypto) == null ? void 0 : _a2.getRandomValues) {
      globalThis.crypto.getRandomValues(bytes);
    } else {
      bytes[0] = Date.now() >>> 0;
      bytes[1] = performance.now() * 1e3 >>> 0;
    }
    return this.normalize(`${prefix}-${bytes[0].toString(36)}-${bytes[1].toString(36)}`);
  }
  createDateSeed(date = /* @__PURE__ */ new Date(), prefix = "ELI-DAY") {
    const isoDay = date.toISOString().slice(0, 10).replaceAll("-", "");
    return this.normalize(`${prefix}-${isoDay}`);
  }
  createDifficultySeed(difficulty, focus = [], prefix = "ELI-DIFF") {
    const entropy = this.createRandomSeed("RUN").replace(/^RUN-/, "");
    const serial = this.nextRunSerial();
    return this.normalize(`${prefix}-${difficulty}-${focus.join("-")}-R${serial.toString(36)}-${entropy}`);
  }
  nextRunSerial() {
    var _a2, _b;
    this.volatileSerial += 1;
    try {
      const key = "eli-quest:procedural-run-serial";
      const previous = Number(((_a2 = globalThis.localStorage) == null ? void 0 : _a2.getItem(key)) ?? 0);
      const next = Number.isFinite(previous) ? previous + 1 : 1;
      (_b = globalThis.localStorage) == null ? void 0 : _b.setItem(key, String(next));
      return next;
    } catch {
      return Date.now() + this.volatileSerial >>> 0;
    }
  }
  normalize(seed) {
    return seed.trim().toUpperCase().replace(/[^A-Z0-9-]+/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "");
  }
  toNumber(seed) {
    return Random.hash(this.normalize(seed));
  }
}
const seedManager = new SeedManager();
class ProceduralDirector {
  constructor() {
    __publicField(this, "missionGenerator", new MissionGenerator());
  }
  generateMission(seed, difficulty, focus = []) {
    const normalizedSeed = seedManager.normalize(seed);
    const random = new Random(normalizedSeed);
    const preset = difficultyModel.getPreset(difficulty);
    return this.missionGenerator.generate(normalizedSeed, random, preset, focus);
  }
  generateFreshMission(difficulty, focus = []) {
    const seed = seedManager.createDifficultySeed(difficulty, focus, "ELI-PROC");
    return this.generateMission(seed, difficulty, focus);
  }
}
const proceduralDirector = new ProceduralDirector();
const disciplineLabels = {
  language: {
    label: "Ripara il segnale",
    description: "Sistema un messaggio tecnico: forma e significato devono restare operativi."
  },
  circuit: {
    label: "Diagnostica energia",
    description: "Leggi sintomi e componenti prima di scegliere l'intervento sul circuito."
  },
  math: {
    label: "Calcola il codice",
    description: "Usa un ragionamento numerico verificabile, non tentativi a caso."
  },
  english: {
    label: "Decodifica comando",
    description: "Trasforma l'istruzione inglese in una scelta sicura."
  },
  coding: {
    label: "Verifica algoritmo",
    description: "Segui righe, variabili, condizioni o debug per prevedere il sistema."
  },
  music: {
    label: "Leggi il pentagramma",
    description: "Riconosci la nota dal segno sul pentagramma prima che il timer prema."
  }
};
const disciplinePositions = {
  language: { x: 382, y: 472, radius: 42 },
  circuit: { x: 312, y: 256, radius: 52 },
  math: { x: 640, y: 220, radius: 56 },
  english: { x: 914, y: 254, radius: 50 },
  coding: { x: 914, y: 502, radius: 54 },
  music: { x: 640, y: 502, radius: 52 }
};
const levelFocuses = {
  1: "italiano",
  2: "matematica",
  3: "inglese",
  4: "coding",
  5: "elettronica",
  6: "musica",
  7: "matematica",
  8: "coding"
};
const levelBlueprints = {
  1: {
    goal: "Riconoscere il dato chiave e rispettare una sequenza semplice.",
    synthesisPrompt: "Quale metodo collega messaggio, calcolo e comando finale?",
    synthesisCorrect: "Leggo il segnale, ricavo il dato e solo dopo eseguo il comando.",
    synthesisDistractors: ["Provo subito ogni comando disponibile.", "Scelgo la console con il punteggio più alto e ignoro le altre."],
    synthesisSteps: ["Leggi il segnale", "Ricava il dato", "Esegui il comando"],
    synthesisExplanation: "Le tre discipline formano una catena: comprensione, trasformazione del dato, azione sicura."
  },
  2: {
    goal: "Combinare dati numerici e vincoli tecnici senza perdere l'ordine.",
    synthesisPrompt: "Il codice è corretto ma il circuito non risponde: quale controllo viene prima?",
    synthesisCorrect: "Verifico continuità e vincoli del circuito, poi applico il codice nel punto corretto.",
    synthesisDistractors: ["Cambio il risultato matematico finché il circuito si accende.", "Ignoro il circuito perché il calcolo è già corretto."],
    synthesisSteps: ["Controlla il circuito", "Verifica i vincoli", "Applica il codice"],
    synthesisExplanation: "Un risultato corretto non basta se il sistema che deve usarlo non rispetta i propri vincoli."
  },
  3: {
    goal: "Tradurre condizioni linguistiche in decisioni logiche verificabili.",
    synthesisPrompt: "Come trasformi un comando inglese con una condizione in un'azione sicura?",
    synthesisCorrect: "Isolo condizione e divieto, li trasformo in controlli logici, poi verifico il dato.",
    synthesisDistractors: ["Traduco soltanto il verbo principale.", "Eseguo prima l'azione e controllo la condizione dopo."],
    synthesisSteps: ["Isola condizione e divieto", "Trasforma in controlli", "Verifica il dato"],
    synthesisExplanation: "Lingua, matematica e coding convergono quando una frase diventa una regola eseguibile."
  },
  4: {
    goal: "Prevedere una procedura prima di eseguirla e riconoscere pattern.",
    synthesisPrompt: "Qual è il controllo migliore prima di avviare un algoritmo?",
    synthesisCorrect: "Simulo i passaggi con un caso concreto e confronto il risultato con tutti i vincoli.",
    synthesisDistractors: ["Controllo soltanto la prima istruzione.", "Avvio più volte il programma e tengo il risultato più comune."],
    synthesisSteps: ["Scegli un caso concreto", "Simula i passaggi", "Confronta tutti i vincoli"],
    synthesisExplanation: "Calcolo, linguaggio e pattern diventano strumenti per prevedere l'effetto del codice."
  },
  5: {
    goal: "Diagnosticare cause multiple distinguendo sintomo, dato e intervento.",
    synthesisPrompt: "Due console segnalano lo stesso sintomo: come scegli la riparazione?",
    synthesisCorrect: "Confronto le prove di ogni sistema e intervengo solo sulla causa compatibile con tutte.",
    synthesisDistractors: ["Applico entrambe le riparazioni per sicurezza.", "Scelgo la causa indicata dalla console più veloce."],
    synthesisSteps: ["Raccogli le prove", "Escludi cause incompatibili", "Intervieni sulla causa comune"],
    synthesisExplanation: "La diagnosi interdisciplinare usa più fonti per escludere interventi inutili."
  },
  6: {
    goal: "Riconoscere strutture e ritmi trasformandoli in sequenze controllabili.",
    synthesisPrompt: "Come può un pattern musicale aiutare a verificare una sequenza tecnica?",
    synthesisCorrect: "Confronto ordine, ripetizioni e variazioni: lo stesso pattern deve restare coerente nei due sistemi.",
    synthesisDistractors: ["Uso soltanto la nota più alta come comando.", "La musica non può fornire informazioni a un algoritmo."],
    synthesisSteps: ["Rileva il pattern", "Confronta le variazioni", "Verifica la sequenza tecnica"],
    synthesisExplanation: "Ritmo e algoritmo condividono ordine, ripetizione, previsione e controllo delle variazioni."
  },
  7: {
    goal: "Gestire informazioni incomplete e scegliere una conclusione proporzionata alle prove.",
    synthesisPrompt: "I dati sono coerenti ma incompleti: quale conclusione è certificabile?",
    synthesisCorrect: "Formulo una conclusione limitata ai dati disponibili e segnalo ciò che resta da verificare.",
    synthesisDistractors: ["Completo i dati mancanti con l'ipotesi più probabile.", "Dichiaro il sistema risolto perché non ci sono contraddizioni."],
    synthesisSteps: ["Separa dati e ipotesi", "Formula una conclusione limitata", "Segnala cosa manca"],
    synthesisExplanation: "Pensiero critico significa distinguere ciò che le prove mostrano da ciò che resta ipotesi."
  },
  8: {
    goal: "Integrare tutte le discipline in una decisione tecnica spiegabile.",
    synthesisPrompt: "Quando il nucleo può essere dichiarato stabile?",
    synthesisCorrect: "Quando dati, istruzioni, calcoli e simulazione sostengono la stessa conclusione senza conflitti.",
    synthesisDistractors: ["Quando ogni console ha prodotto almeno un risultato.", "Quando il punteggio totale supera quello della run precedente."],
    synthesisSteps: ["Confronta tutte le prove", "Risolvi i conflitti", "Certifica la conclusione comune"],
    synthesisExplanation: "La certificazione finale richiede coerenza tra prove diverse, non una somma di risposte isolate."
  }
};
const levelPools = {
  1: ["language", "math", "english"],
  2: ["language", "math", "english", "circuit"],
  3: ["math", "english", "coding", "circuit"],
  4: ["language", "math", "coding", "music"],
  5: ["circuit", "math", "english", "coding", "music"],
  6: ["language", "circuit", "math", "english", "coding"],
  7: ["circuit", "math", "english", "coding", "music"],
  8: ["language", "circuit", "math", "english", "coding", "music"]
};
const focusDisciplines = {
  libera: void 0,
  matematica: "math",
  italiano: "language",
  inglese: "english",
  elettronica: "circuit",
  coding: "coding",
  musica: "music"
};
class ProgressiveMissionBuilder {
  focusForLevel(level) {
    return levelFocuses[level];
  }
  blueprintForLevel(level) {
    return levelBlueprints[level];
  }
  buildLevelMission(base, level) {
    const random = new Random(`${base.seed}:progressive:${level}`);
    const variedBase = this.withNonRepeatingMath(base, level);
    const selected = this.selectDisciplines(random, level, base.seed);
    const objectives = selected.map((kind) => this.objectiveFor(variedBase, kind));
    const hotspots = selected.map((kind) => this.hotspotFor(kind));
    const pathLabel = selected.map((kind) => disciplineLabels[kind].label.toLowerCase()).join(" -> ");
    return {
      ...variedBase,
      id: `mission-progressive-level-${level}`,
      title: `Scalata dell'Accademia - Livello ${level}`,
      intro: [
        `Livello ${level}/8: la stanza propone una sequenza guidata a difficolta crescente.`,
        `Obiettivo: ${this.blueprintForLevel(level).goal}`,
        "Completa ogni console entro tempo e vite. Il livello successivo si sblocca solo con successo.",
        `Sequenza: ${pathLabel}.`
      ].join(" "),
      objectives,
      map: {
        ...variedBase.map,
        id: `progressive-room-${level}`,
        title: this.roomTitle(level),
        hotspots: [
          ...hotspots,
          {
            id: "door",
            label: "Porta di livello",
            x: 640,
            y: 650,
            radius: 64,
            description: "Si apre solo quando tutte le console del livello sono coerenti."
          }
        ]
      },
      competencies: Array.from(new Set(objectives.flatMap((objective) => objective.competencies))),
      rewards: [
        {
          badgeId: `scalata-livello-${level}`,
          label: `Stanza ${level} stabilizzata`,
          description: "Ha superato una stanza interdisciplinare a difficoltà crescente."
        },
        ...variedBase.rewards
      ]
    };
  }
  withNonRepeatingMath(base, level) {
    var _a2, _b;
    const storageKey = `eli-quest:progressive-math:${level}`;
    const signatureOf = (puzzle) => `${puzzle.archetype ?? "base"}|${puzzle.answer}|${puzzle.prompt.replace(/\s+/g, " ")}`;
    let recentSignatures = [];
    let previousArchetype = "";
    try {
      const stored = JSON.parse(((_a2 = globalThis.localStorage) == null ? void 0 : _a2.getItem(storageKey)) ?? "{}");
      if (stored.seed === base.seed) return base;
      recentSignatures = stored.signatures ?? [];
      previousArchetype = stored.archetype ?? "";
    } catch {
    }
    let selected = base.puzzles.math;
    const currentSignature = signatureOf(selected);
    if (recentSignatures.includes(currentSignature) || selected.id.startsWith("math-fallback") || level > 1 && (selected.archetype ?? "") === previousArchetype) {
      const generator = new MathPuzzleGenerator();
      const preset = difficultyModel.getPreset(level);
      let firstFresh = selected;
      for (let attempt = 0; attempt < 18; attempt += 1) {
        const candidate = exerciseDirector.enrichMath(
          generator.generateGraphWorkshop(new Random(`${base.seed}:math-diversity:${attempt}`), preset),
          level
        );
        if (recentSignatures.includes(signatureOf(candidate))) continue;
        if (firstFresh === selected) firstFresh = candidate;
        if ((candidate.archetype ?? "") !== previousArchetype || level === 1) {
          selected = candidate;
          break;
        }
      }
      if (selected === base.puzzles.math) selected = firstFresh;
    }
    const signature = signatureOf(selected);
    try {
      (_b = globalThis.localStorage) == null ? void 0 : _b.setItem(storageKey, JSON.stringify({
        seed: base.seed,
        signatures: [signature, ...recentSignatures.filter((item) => item !== signature)].slice(0, 4),
        archetype: selected.archetype ?? ""
      }));
    } catch {
    }
    if (selected === base.puzzles.math) return base;
    return { ...base, puzzles: { ...base.puzzles, math: selected } };
  }
  timeLimitMs(level, objectiveCount) {
    const secondsPerObjective = Math.max(34, 74 - level * 5);
    return Math.max(145, objectiveCount * secondsPerObjective + 35) * 1e3;
  }
  selectDisciplines(random, level, seed) {
    const pool = levelPools[level];
    const targetCount = Math.min(pool.length, level <= 1 ? 3 : level <= 4 ? 4 : level <= 7 ? 5 : 6);
    const primary = focusDisciplines[this.focusForLevel(level)];
    const mustHave = Array.from(/* @__PURE__ */ new Set([
      ...primary ? [primary] : [],
      ...level >= 5 ? ["math", "coding"] : level >= 3 ? ["math"] : []
    ])).filter((kind) => pool.includes(kind));
    const rest = random.shuffle(pool.filter((kind) => !mustHave.includes(kind)));
    const selected = [...mustHave, ...rest].slice(0, targetCount);
    return this.nonRepeatingOrder(random, level, seed, selected);
  }
  nonRepeatingOrder(random, level, seed, selected) {
    var _a2, _b;
    if (selected.length < 2) return selected;
    const storageKey = `eli-quest:progressive-order:${level}`;
    let previousSeed = "";
    let previousOrder = "";
    try {
      const stored = JSON.parse(((_a2 = globalThis.localStorage) == null ? void 0 : _a2.getItem(storageKey)) ?? "{}");
      previousSeed = stored.seed ?? "";
      previousOrder = stored.order ?? "";
      if (previousSeed === seed && previousOrder) {
        const restored = previousOrder.split(",");
        if (restored.length === selected.length && restored.every((kind) => selected.includes(kind))) return restored;
      }
    } catch {
    }
    let ordered = random.shuffle(selected);
    if (ordered.join(",") === previousOrder) {
      ordered = [...ordered.slice(1), ordered[0]];
    }
    try {
      (_b = globalThis.localStorage) == null ? void 0 : _b.setItem(storageKey, JSON.stringify({ seed, order: ordered.join(",") }));
    } catch {
    }
    return ordered;
  }
  objectiveFor(base, kind) {
    const puzzle = base.puzzles[kind];
    return {
      id: `procedural-${kind}`,
      label: disciplineLabels[kind].label,
      description: disciplineLabels[kind].description,
      competencies: puzzle.competencies
    };
  }
  hotspotFor(kind) {
    const position = disciplinePositions[kind];
    return {
      id: kind,
      label: disciplineLabels[kind].label,
      x: position.x,
      y: position.y,
      radius: position.radius,
      puzzleId: kind,
      puzzleKind: kind,
      description: disciplineLabels[kind].description
    };
  }
  roomTitle(level) {
    return [
      "Sala delle Tracce",
      "Sala dei Vincoli",
      "Galleria dei Sistemi",
      "Nucleo delle Decisioni",
      "Anello dei Codici",
      "Camera delle Interferenze",
      "Osservatorio Critico",
      "Nucleo dell'Accademia"
    ][level - 1];
  }
}
const progressiveMissionBuilder = new ProgressiveMissionBuilder();
const focuses = [["libera"], ["matematica"], ["italiano"], ["inglese"], ["coding"], ["elettronica"], ["musica"]];
let missions = 0;
let mathFocuses = 0;
let progressive = 0;
for (let level = 1; level <= 8; level += 1) {
  for (let index = 0; index < 40; index += 1) {
    for (const focus of focuses) {
      const mission2 = proceduralDirector.generateMission(`presence:${level}:${index}:${focus[0]}`, level, focus);
      missions += 1;
      if (!mission2.puzzles.math.graphWorkshop) throw new Error(`Missione senza Officina: L${level}/${focus[0]}`);
      if (focus[0] === "matematica") {
        mathFocuses += 1;
        if (!((_a = mission2.focusChallenges) == null ? void 0 : _a.some((challenge) => challenge.kind === "math" && Boolean(challenge.puzzle.graphWorkshop)))) {
          throw new Error(`Focus matematica senza Officina: L${level}`);
        }
      }
    }
    const base = proceduralDirector.generateMission(`progressive:${level}:${index}`, level, [progressiveMissionBuilder.focusForLevel(level)]);
    const mission = progressiveMissionBuilder.buildLevelMission(base, level);
    progressive += 1;
    if (mission.objectives.some((objective) => objective.id === "procedural-math") && !mission.puzzles.math.graphWorkshop) {
      throw new Error(`Scalata con matematica senza Officina: L${level}`);
    }
  }
}
console.log(JSON.stringify({ missions, mathFocuses, progressive }));
