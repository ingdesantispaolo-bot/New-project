import type { ProceduralPuzzleKind, ProceduralSpecialization } from "../../procedural/ProceduralTypes";

type FocusPuzzleId = ProceduralPuzzleKind;
type StandardFocusPuzzleId = Exclude<FocusPuzzleId, "coding" | "physics">;

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
  hotspots: Record<StandardFocusPuzzleId, { label: string; description: string }> & Partial<Record<"coding" | "physics", { label: string; description: string }>>;
  objectives: Record<StandardFocusPuzzleId, { label: string; description: string }> & Partial<Record<"coding" | "physics", { label: string; description: string }>>;
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
      music: { label: "Armonizzatore", description: "Un pentagramma instabile richiede di riconoscere la nota corretta." },
    },
    objectives: {
      language: { label: "Stabilizza il segnale", description: "Ripara il messaggio tecnico senza perdere il senso operativo." },
      circuit: { label: "Diagnostica il circuito", description: "Trova i guasti e ripristina un percorso elettrico stabile." },
      math: { label: "Calcola il codice", description: "Ricostruisci il codice del terminale seguendo la traccia numerica." },
      english: { label: "Decodifica il comando esterno", description: "Esegui solo l'azione autorizzata dall'istruzione inglese." },
      robot: { label: "Guida il robot alla chiave", description: "Costruisci una sequenza coerente nella griglia generata." },
      music: { label: "Riconosci la nota", description: "Leggi la nota sul pentagramma prima che il segnale svanisca." },
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
      math: { label: "Officina dei Grafici", description: "Il piano cartesiano reagisce ai parametri: costruisci rette e parabole rispettando punti e proprietà." },
      english: { label: "Protocollo esterno", description: "Un breve comando inglese stabilisce l'ordine sicuro delle operazioni." },
      robot: { label: "Carrello automatico", description: "Il robot trasporta la chiave lungo una griglia che richiede pianificazione." },
      music: { label: "Sequenza sonora", description: "Una nota sul pentagramma calibra il ritmo delle macchine." },
    },
    objectives: {
      language: { label: "Filtra il log dati", description: "Distingui informazione utile e rumore linguistico." },
      circuit: { label: "Stabilizza l'alimentatore", description: "Garantisci energia sicura alle macchine numeriche." },
      math: { label: "Calibra il grafico", description: "Intervieni sui parametri e certifica la curva richiesta sul piano cartesiano." },
      english: { label: "Esegui il protocollo", description: "Interpreta l'istruzione operativa senza invertire ordine o condizione." },
      robot: { label: "Muovi il carrello", description: "Trasforma la pianificazione in una sequenza di comandi." },
      music: { label: "Leggi la nota", description: "Riconosci posizione e ottava sul pentagramma." },
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
      music: { label: "Archivio sonoro", description: "Il pentagramma contiene una nota da catalogare con precisione." },
    },
    objectives: {
      language: { label: "Ripara il messaggio centrale", description: "Correggi accordi, connettivi e riferimenti senza perdere il significato." },
      circuit: { label: "Verifica il pannello", description: "Collega il testo tecnico a una diagnosi elettrica reale." },
      math: { label: "Ordina l'indice", description: "Ricostruisci il codice che cataloga il registro." },
      english: { label: "Decifra la nota bilingue", description: "Individua azione, oggetto e condizione nel comando inglese." },
      robot: { label: "Recupera il fascicolo", description: "Programma il robot per raggiungere il documento chiave." },
      music: { label: "Classifica la nota", description: "Leggi chiave, riga o spazio e ottava." },
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
      music: { label: "Segnale musicale", description: "La console mostra una nota che va letta prima della trasmissione." },
    },
    objectives: {
      language: { label: "Allinea il registro", description: "Ripara il messaggio italiano che contestualizza il comando esterno." },
      circuit: { label: "Arma la sicurezza", description: "Stabilizza il circuito prima della trasmissione finale." },
      math: { label: "Calibra il codice", description: "Ottieni il valore richiesto dalla procedura di accesso." },
      english: { label: "Interpreta il comando", description: "Distingui azione, ordine temporale, divieto e condizione." },
      robot: { label: "Esegui l'ordine", description: "Guida il robot secondo una sequenza coerente." },
      music: { label: "Identifica la nota", description: "Riconosci la nota sul pentagramma come segnale ausiliario." },
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
      music: { label: "Oscilloscopio musicale", description: "Una nota calibrata stabilizza il segnale del banco." },
    },
    objectives: {
      language: { label: "Leggi il manuale", description: "Ripara la frase tecnica che descrive il sintomo." },
      circuit: { label: "Diagnostica il banco", description: "Spiega componente per componente perché il circuito non è stabile." },
      math: { label: "Calcola la lettura", description: "Ricostruisci il valore richiesto dal misuratore." },
      english: { label: "Applica l'etichetta", description: "Segui l'istruzione di sicurezza in inglese." },
      robot: { label: "Invia manutenzione", description: "Programma il robot per recuperare l'attrezzo necessario." },
      music: { label: "Calibra la nota", description: "Leggi la nota sul pentagramma per allineare il segnale." },
    },
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
      "La stanza proietta pseudocodice vivo: variabili, cicli e condizioni decidono quali porte si attivano.",
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
      { label: "Debug del codice", description: "Trova la riga che rompe la regola e correggi la causa, non il sintomo." },
    ],
    badge: {
      badgeId: "debugger-di-rotta",
      label: "Debugger di Algoritmi",
      description: "Ha seguito stati, condizioni e cicli fino a una risposta verificabile.",
    },
    hotspots: {
      language: { label: "Log del robot", description: "Il messaggio descrive lo stato della pista e va riparato." },
      circuit: { label: "Dock di ricarica", description: "Il robot parte solo se il circuito del dock è stabile." },
      math: { label: "Coordinate cifrate", description: "Il terminale calcola un codice legato alla rotta." },
      english: { label: "Comando remoto", description: "L'istruzione inglese stabilisce quando inviare il robot." },
      robot: { label: "Griglia di missione", description: "La griglia generata richiede pianificazione, non tentativi casuali." },
      music: { label: "Modulo di scansione", description: "Una nota sul pentagramma scandisce l'avvio del percorso." },
    },
    objectives: {
      language: { label: "Ripara il log robot", description: "Rendi chiaro il messaggio che descrive la rotta." },
      circuit: { label: "Stabilizza il dock", description: "Diagnostica il circuito che alimenta il robot." },
      math: { label: "Calcola le coordinate", description: "Ottieni il codice che sincronizza la griglia." },
      english: { label: "Leggi il comando remoto", description: "Interpreta condizione e ordine operativo." },
      robot: { label: "Programma la rotta", description: "Costruisci una sequenza corretta, breve e verificabile." },
      music: { label: "Leggi il segnale", description: "Riconosci nota, chiave e posizione prima dell'esecuzione." },
    },
  },
  fisica: {
    id: "fisica",
    label: "Percorso Fisica",
    title: "Osservatorio delle Leggi",
    chamberTitle: "Laboratorio fisico",
    roomTitles: ["Banco delle Misure", "Galleria del Moto", "Sala delle Forze", "Camera delle Trasformazioni"],
    introFragments: [
      "NORA apre l'osservatorio fisico: ogni fenomeno deve essere letto con misure, modelli e prove controllate.",
      "Eli entra in un laboratorio dove grafici, forze ed energia non sono formule isolate, ma modi per prevedere cosa succede.",
      "La sala mostra carrelli, raggi, onde e sensori: prima si osserva, poi si sceglie il modello piu semplice che spiega i dati.",
    ],
    sideNote: "Il percorso semplifica i nuclei iniziali del liceo scientifico: misura, moto, forze, energia, esperimento e lettura grafica.",
    ruleTitle: "Regola dell'osservatorio",
    ruleText: "Puoi esplorare liberamente, ma il modulo fisica e il centro del percorso. Parti da grandezze e unita, poi scegli il modello coerente con i dati.",
    stageHint: "Percorso fisica: leggi la situazione, individua le grandezze, controlla unita e grafico, poi collega causa e modello.",
    primaryPuzzle: "physics",
    challengeStages: [
      { label: "Misure e unita", description: "Converti unita, riconosci grandezze e controlla se il valore e plausibile." },
      { label: "Grafici del moto", description: "Leggi posizione, tempo, velocita e pendenza senza applicare formule alla cieca." },
      { label: "Forze ed equilibrio", description: "Costruisci diagrammi semplici distinguendo peso, vincoli e forze bilanciate." },
      { label: "Energia e trasformazioni", description: "Descrivi passaggi di energia in sistemi quotidiani senza crearla dal nulla." },
      { label: "Esperimento e dati", description: "Progetta prove controllate, leggi onde, pressione, calore o raggi con metodo." },
    ],
    badge: {
      badgeId: "osservatrice-delle-leggi",
      label: "Osservatrice delle Leggi",
      description: "Ha collegato misure, modelli fisici e prove sperimentali.",
    },
    hotspots: {
      language: { label: "Registro dell'esperimento", description: "Il testo descrive dati e condizioni: va letto senza confondere ipotesi e prova." },
      circuit: { label: "Sensore di misura", description: "Il circuito alimenta strumenti e sensori del banco fisico." },
      math: { label: "Grafico dei dati", description: "Il terminale traduce misure in rapporti, pendenze e relazioni." },
      english: { label: "Protocollo scientifico", description: "Una breve istruzione inglese indica procedura, vincoli e sicurezza." },
      robot: { label: "Carrello di laboratorio", description: "Il robot sposta strumenti seguendo una sequenza verificabile." },
      coding: { label: "Simulatore dati", description: "Un algoritmo prevede l'andamento di misure o stati." },
      music: { label: "Segnale periodico", description: "Il pentagramma richiama pattern, frequenza e lettura ordinata." },
      physics: { label: "Banco fisico", description: "La console chiede di leggere un fenomeno con grandezze, unita e modello." },
    },
    objectives: {
      language: { label: "Leggi il registro", description: "Distingui dati, ipotesi e conclusione nel testo sperimentale." },
      circuit: { label: "Alimenta i sensori", description: "Stabilizza il circuito che sostiene gli strumenti di misura." },
      math: { label: "Interpreta il grafico", description: "Usa rapporti e pendenze per dare senso alle misure." },
      english: { label: "Applica il protocollo", description: "Interpreta istruzioni scientifiche brevi in inglese operativo." },
      robot: { label: "Muovi il carrello", description: "Programma una sequenza di laboratorio coerente." },
      coding: { label: "Simula i dati", description: "Segui variabili e condizioni che modellano il fenomeno." },
      music: { label: "Leggi il segnale", description: "Riconosci pattern ordinati utili alla lettura di frequenze." },
      physics: { label: "Stabilizza il fenomeno", description: "Scegli il modello fisico piu coerente con dati, grafico e unita." },
    },
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
      "Un pentagramma luminoso attraversa la stanza. Le note sopra e sotto le linee sono segnali da leggere con calma e precisione.",
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
      { label: "Lettura rapida", description: "Alterna chiavi e note estreme con tempo ridotto." },
    ],
    badge: {
      badgeId: "lettrice-del-pentagramma",
      label: "Lettrice del Pentagramma",
      description: "Ha riconosciuto note in chiave di violino, basso e linee addizionali.",
    },
    hotspots: {
      language: { label: "Registro ritmico", description: "Il testo descrive una regola di lettura da non confondere." },
      circuit: { label: "Amplificatore", description: "Il circuito alimenta il banco sonoro." },
      math: { label: "Metronomo numerico", description: "Il terminale misura intervalli e tempo di risposta." },
      english: { label: "Etichetta audio", description: "Un comando inglese indica una procedura di ascolto." },
      robot: { label: "Carrello spartiti", description: "Il robot porta lo spartito corretto." },
      music: { label: "Pentagramma vivo", description: "La nota va riconosciuta da posizione, chiave e linee addizionali." },
    },
    objectives: {
      language: { label: "Leggi la regola", description: "Capisci l'istruzione testuale che spiega il pentagramma." },
      circuit: { label: "Accendi l'amplificatore", description: "Stabilizza l'energia del banco sonoro." },
      math: { label: "Sincronizza il metronomo", description: "Calcola una soglia di tempo o ritmo." },
      english: { label: "Decodifica l'etichetta", description: "Interpreta un comando operativo audio in inglese." },
      robot: { label: "Recupera lo spartito", description: "Programma il robot verso la partitura." },
      music: { label: "Riconosci la nota", description: "Identifica la nota sul pentagramma entro il tempo previsto." },
    },
  },
};

export function getProceduralFocusPath(focus: string[] = []): ProceduralFocusPath {
  const key = focus.find((item): item is ProceduralSpecialization =>
    ["matematica", "italiano", "inglese", "elettronica", "coding", "musica", "fisica", "libera"].includes(item),
  ) ?? "libera";
  return proceduralFocusPaths[key] ?? proceduralFocusPaths.libera;
}

export function proceduralFocusChallengeCount(level: number): number {
  if (level >= 6) return 5;
  if (level >= 3) return 4;
  return 3;
}
