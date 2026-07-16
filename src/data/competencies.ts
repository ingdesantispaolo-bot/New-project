export type CompetencyDefinition = {
  id: string;
  label: string;
  description: string;
};

// Alcuni generatori assegnano una competenza con un nome storico diverso da
// quello del registro (stesso concetto, etichetta diversa). Qui li riportiamo
// all'id canonico, così la pratica NON viene persa e non nascono doppioni nel
// report. I concetti davvero nuovi (fisica.*, musica.ritmo…) sono invece
// registrati sotto, non aliasati.
export const competencyAliases: Record<string, string> = {
  "matematica.proporzioni": "matematica.proporzionalita",
  "matematica.rapporti": "matematica.proporzionalita",
  "matematica.unitaMisura": "matematica.misure",
  "matematica.pitagora": "matematica.geometria",
  "matematica.equivalenze": "matematica.frazioni",
  "matematica.letturaDati": "matematica.statistica",
  "coding.controlloErrore": "coding.debugging",
  "inglese.scritturaBreve": "inglese.grammatica",
  "scienze.energia": "scienze.sistemi",
};

/** Riporta un id al suo nome canonico registrato (o lo lascia com'è). */
export function canonicalCompetencyId(id: string): string {
  return competencyAliases[id] ?? id;
}

/** Vero se l'id (dopo alias) è una competenza registrata e tracciabile. */
export function isKnownCompetency(id: string): boolean {
  return competencies.some((competency) => competency.id === canonicalCompetencyId(id));
}

export const competencies: CompetencyDefinition[] = [
  {
    id: "matematica.calcolo",
    label: "Calcolo strategico",
    description: "Usare operazioni semplici dentro una situazione da risolvere.",
  },
  {
    id: "matematica.operazioni",
    label: "Proprieta delle operazioni",
    description: "Scegliere operazioni e ordine dei passaggi in base all'effetto previsto.",
  },
  {
    id: "matematica.logica",
    label: "Logica matematica",
    description: "Collegare condizioni, numeri e conseguenze.",
  },
  {
    id: "matematica.multipliDivisori",
    label: "Multipli e divisori",
    description: "Riconoscere quando un numero può attraversare filtri e divisioni senza resto.",
  },
  {
    id: "matematica.espressioni",
    label: "Prime espressioni",
    description: "Leggere una trasformazione composta rispettando l'ordine interno dei passaggi.",
  },
  {
    id: "matematica.controlloErrore",
    label: "Controllo dell'errore",
    description: "Usare vincoli e risultati intermedi per capire dove un percorso si rompe.",
  },
  {
    id: "matematica.grafici",
    label: "Lettura di grafici",
    description: "Interpretare andamenti semplici per capire se una scelta sta funzionando.",
  },
  {
    id: "matematica.frazioni",
    label: "Frazioni e rapporti",
    description: "Usare parti, rapporti e quote per interpretare risorse e misure.",
  },
  {
    id: "matematica.percentuali",
    label: "Percentuali",
    description: "Ragionare su aumenti, sconti, soglie e quote percentuali.",
  },
  {
    id: "matematica.geometria",
    label: "Geometria operativa",
    description: "Usare perimetri, aree, distanze e figure dentro problemi concreti.",
  },
  {
    id: "matematica.statistica",
    label: "Statistica semplice",
    description: "Leggere media, mediana, intervallo e dati anomali.",
  },
  {
    id: "matematica.probabilita",
    label: "Probabilita",
    description: "Stimare eventi possibili e usare rapporti per prevedere esiti.",
  },
  {
    id: "matematica.algebra",
    label: "Algebra iniziale",
    description: "Usare incognite, formule e relazioni per risalire a valori nascosti.",
  },
  {
    id: "matematica.funzioni",
    label: "Funzioni e modelli",
    description: "Leggere relazioni lineari e trasformazioni tra ingresso e uscita.",
  },
  {
    id: "matematica.potenzeRadici",
    label: "Potenze e radici",
    description: "Usare quadrati, potenze e radici in misure e codici.",
  },
  {
    id: "matematica.numeriRelativi",
    label: "Numeri relativi",
    description: "Usare valori positivi e negativi in variazioni, temperature e bilanci.",
  },
  {
    id: "matematica.proporzionalita",
    label: "Proporzionalita",
    description: "Riconoscere rapporti costanti, scale, velocita e trasformazioni proporzionali.",
  },
  {
    id: "matematica.misure",
    label: "Misure e unita",
    description: "Convertire e confrontare misure senza perdere il significato fisico.",
  },
  {
    id: "matematica.equazioni",
    label: "Equazioni e disequazioni",
    description: "Isolare incognite e trovare valori massimi o minimi compatibili con vincoli.",
  },
  {
    id: "matematica.geometria3D",
    label: "Geometria solida",
    description: "Usare volumi e dimensioni di solidi semplici in problemi concreti.",
  },
  {
    id: "matematica.coordinate",
    label: "Coordinate sul piano",
    description: "Leggere e collocare punti su una griglia usando coppie di coordinate.",
  },
  {
    id: "coding.sequenze",
    label: "Sequenze di comandi",
    description: "Ordinare istruzioni per ottenere un comportamento previsto.",
  },
  {
    id: "coding.debugging",
    label: "Debugging",
    description: "Osservare un errore, capirne la causa e correggere.",
  },
  {
    id: "coding.orientamento",
    label: "Orientamento su griglia",
    description: "Tenere insieme posizione, direzione e rotazioni su una mappa.",
  },
  {
    id: "coding.decomposizione",
    label: "Decomposizione",
    description: "Dividere un problema di percorso in sotto-obiettivi verificabili.",
  },
  {
    id: "coding.efficienza",
    label: "Efficienza algoritmica",
    description: "Ridurre comandi inutili mantenendo il comportamento corretto.",
  },
  {
    id: "coding.testMentale",
    label: "Test mentale",
    description: "Simulare un programma prima di eseguirlo per prevenire errori.",
  },
  {
    id: "coding.condizioni",
    label: "Logica condizionale",
    description: "Usare regole se/allora per far reagire un sistema alle condizioni.",
  },
  {
    id: "elettronica.circuitoChiuso",
    label: "Circuito chiuso",
    description: "Capire che la corrente ha bisogno di un percorso completo.",
  },
  {
    id: "elettronica.energia",
    label: "Distribuzione dell'energia",
    description: "Distribuire energia limitata rispettando minimi, priorità e capacità della rete.",
  },
  {
    id: "italiano.comprensione",
    label: "Lettura di indizi",
    description: "Ricavare informazioni operative da testi brevi.",
  },
  {
    id: "italiano.grammatica",
    label: "Riparazione linguistica",
    description: "Riconoscere accordi e forme corrette in una frase.",
  },
  {
    id: "italiano.verbi",
    label: "Modi e tempi dei verbi",
    description: "Riconoscere e usare modo, tempo, persona e forme verbali in contesto.",
  },
  {
    id: "italiano.lessico",
    label: "Lessico in contesto",
    description: "Scegliere parole precise per distinguere oggetti, azioni e fonti.",
  },
  {
    id: "italiano.scritturaBreve",
    label: "Scrittura breve",
    description: "Sintetizzare informazioni utili in un rapporto chiaro e operativo.",
  },
  {
    id: "italiano.punteggiatura",
    label: "Punteggiatura funzionale",
    description: "Usare punteggiatura, accenti e apostrofi per rendere chiaro il significato.",
  },
  {
    id: "italiano.coesione",
    label: "Coesione del testo",
    description: "Collegare soggetti, pronomi, relative e subordinate senza ambiguità.",
  },
  {
    id: "italiano.argomentazione",
    label: "Tesi e prove",
    description: "Distinguere opinioni, ipotesi, prove e conclusioni proporzionate.",
  },
  {
    id: "inglese.istruzioni",
    label: "Inglese operativo",
    description: "Capire istruzioni brevi utili per agire.",
  },
  {
    id: "inglese.scientifico",
    label: "Inglese scientifico base",
    description: "Interpretare brevi note tecniche su condizioni naturali e osservazioni.",
  },
  {
    id: "inglese.bilingue",
    label: "Istruzioni bilingui",
    description: "Collegare comandi inglesi a decisioni operative in italiano.",
  },
  {
    id: "inglese.grammatica",
    label: "Grammatica inglese funzionale",
    description: "Usare tempi verbali, modali, pronomi e connettivi per capire una procedura.",
  },
  {
    id: "inglese.lessico",
    label: "Lessico inglese in contesto",
    description: "Capire parole tecniche e scolastiche dal contesto operativo.",
  },
  {
    id: "inglese.comprensione",
    label: "Comprensione inglese",
    description: "Selezionare informazioni utili da istruzioni, log e brevi testi in inglese.",
  },
  {
    id: "inglese.dati",
    label: "Dati e misure in inglese",
    description: "Interpretare soglie, quantità, confronti e misure scritte in inglese.",
  },
  {
    id: "musica.pentagramma",
    label: "Pentagramma",
    description: "Riconoscere linee, spazi e linee addizionali sopra e sotto il pentagramma.",
  },
  {
    id: "musica.chiaveViolino",
    label: "Chiave di violino",
    description: "Leggere note in chiave di violino usando riferimenti e conteggio linee-spazi.",
  },
  {
    id: "musica.chiaveBasso",
    label: "Chiave di basso",
    description: "Leggere note in chiave di basso usando riferimenti e conteggio linee-spazi.",
  },
  {
    id: "musica.letturaNote",
    label: "Lettura note",
    description: "Identificare nome e ottava della nota entro un tempo adeguato alla profondità.",
  },
  {
    id: "musica.orecchio",
    label: "Riconoscimento sonoro",
    description: "Riconoscere note dal suono come sfida avanzata dopo la lettura visiva.",
  },
  {
    id: "scienze.osservazione",
    label: "Osservazione scientifica",
    description: "Leggere segnali naturali e dati semplici prima di intervenire.",
  },
  {
    id: "scienze.sistemi",
    label: "Sistemi viventi",
    description: "Capire relazioni tra luce, acqua, temperatura e organismi.",
  },
  {
    id: "scienze.dati",
    label: "Raccolta dati",
    description: "Usare sensori, tabelle e osservazioni per decidere un intervento.",
  },
  {
    id: "geografia.orientamento",
    label: "Orientamento e direzioni",
    description: "Usare punti cardinali, rilevamenti e angoli per stabilire una direzione.",
  },
  {
    id: "geografia.scale",
    label: "Mappe e scale",
    description: "Convertire distanze su mappa in distanze reali usando la scala.",
  },
  {
    id: "cittadinanza.tecnologica",
    label: "Cittadinanza tecnologica",
    description: "Decidere come usare risorse e tecnologia mettendo prima vita, sicurezza e servizi essenziali.",
  },
  {
    id: "problemSolving",
    label: "Problem solving",
    description: "Scomporre un problema in passi osservabili.",
  },
  {
    id: "pensieroCritico",
    label: "Pensiero critico",
    description: "Verificare ipotesi prima di agire.",
  },
  {
    id: "trasversali.memoria",
    label: "Memoria di lavoro",
    description: "Trattenere e ripetere informazioni, sequenze e posizioni.",
  },
  {
    id: "trasversali.logica",
    label: "Ragionamento logico",
    description: "Dedurre regole, completare schemi e ragionare per esclusione.",
  },
  {
    id: "latino.declinazioni",
    label: "Le declinazioni",
    description: "Riconoscere e formare i casi delle cinque declinazioni dei sostantivi.",
  },
  {
    id: "latino.coniugazioni",
    label: "Il sistema verbale",
    description: "Formare e riconoscere i tempi delle quattro coniugazioni e di sum.",
  },
  {
    id: "latino.casiFunzioni",
    label: "Funzioni dei casi",
    description: "Collegare il caso alla funzione logica: soggetto, oggetto, complementi.",
  },
  {
    id: "latino.concordanza",
    label: "Concordanza",
    description: "Accordare aggettivi e sostantivi in genere, numero e caso.",
  },
  {
    id: "latino.lessico",
    label: "Lessico latino",
    description: "Riconoscere il significato dei vocaboli latini di base ad alta frequenza.",
  },
  {
    id: "latino.traduzione",
    label: "Traduzione",
    description: "Comprendere e rendere in italiano brevi frasi latine.",
  },
  {
    id: "latino.morfologiaVerbale",
    label: "Analisi verbale",
    description: "Analizzare persona, tempo, modo e diatesi di una voce verbale.",
  },
  {
    id: "latino.sintassi",
    label: "Sintassi del periodo",
    description: "Riconoscere participio, ablativo assoluto e le principali subordinate.",
  },

  // --- Fisica: il generatore fisica assegna queste; senza registro il ramo
  //     Fisica resterebbe sempre a zero e la pratica non verrebbe tracciata. ---
  {
    id: "fisica.osservazione",
    label: "Osservazione scientifica",
    description: "Osservare un fenomeno e descriverlo con grandezze misurabili.",
  },
  {
    id: "fisica.misure",
    label: "Misure e unità",
    description: "Collegare un numero a un'unità e confrontare grandezze omogenee.",
  },
  {
    id: "fisica.metodoSperimentale",
    label: "Metodo sperimentale",
    description: "Cambiare una variabile alla volta per isolare la causa di un effetto.",
  },
  {
    id: "fisica.moto",
    label: "Moto e velocità",
    description: "Descrivere il movimento con posizione, tempo e velocità, anche su grafici.",
  },
  {
    id: "fisica.forze",
    label: "Forze",
    description: "Riconoscere intensità e direzione di una forza e i suoi effetti.",
  },
  {
    id: "fisica.equilibrio",
    label: "Equilibrio",
    description: "Capire quando forze opposte si bilanciano e un corpo resta fermo.",
  },
  {
    id: "fisica.energia",
    label: "Energia e trasformazioni",
    description: "Seguire l'energia mentre cambia forma, senza crearsi né distruggersi.",
  },
  {
    id: "fisica.termologia",
    label: "Calore e temperatura",
    description: "Distinguere temperatura e calore e il passaggio dal caldo al freddo.",
  },
  {
    id: "fisica.materia",
    label: "Densità e pressione",
    description: "Collegare massa, volume e forza su un'area.",
  },
  {
    id: "fisica.onde",
    label: "Onde",
    description: "Descrivere un'onda con lunghezza d'onda, frequenza e velocità.",
  },
  {
    id: "fisica.ottica",
    label: "Ottica",
    description: "Rappresentare la luce con raggi e prevederne la direzione.",
  },
  {
    id: "fisica.modelli",
    label: "Modelli e grafici",
    description: "Usare grafici e modelli per rappresentare un fenomeno fisico.",
  },

  // --- Musica: durate, ritmo, intervalli, scale e ascolto, oltre alla lettura
  //     delle note già registrata. ---
  {
    id: "musica.durate",
    label: "Durate delle figure",
    description: "Riconoscere quanti battiti dura ogni figura musicale.",
  },
  {
    id: "musica.ritmo",
    label: "Ritmo e battute",
    description: "Completare una battuta rispettando i battiti indicati dal tempo.",
  },
  {
    id: "musica.intervalli",
    label: "Intervalli",
    description: "Misurare la distanza di altezza tra due note.",
  },
  {
    id: "musica.scale",
    label: "Scale e gradi",
    description: "Muoversi tra i gradi della scala Do-Re-Mi-Fa-Sol-La-Si.",
  },
  {
    id: "musica.ascoltoVisivo",
    label: "Ascolto e riconoscimento",
    description: "Riconoscere note e intervalli anche dal suono, non solo dal pentagramma.",
  },

  // --- Coding: rappresentazione dei dati e lettura del codice. ---
  {
    id: "coding.culturaInformatica",
    label: "Cultura informatica",
    description: "Capire come il computer rappresenta i dati, per esempio in binario.",
  },
  {
    id: "coding.linguaggiProgrammazione",
    label: "Linguaggi di programmazione",
    description: "Leggere ed eseguire istruzioni di codice riga per riga.",
  },
];
