export type LanguageTemplate = {
  id: string;
  title: string;
  minDifficulty?: number;
  corrupted: string;
  repaired: string;
  distractors: string[];
  diagnosticSteps: string[];
  hints: string[];
  conceptTags?: string[];
  learningPurpose?: string;
  repairGoal?: string;
  method?: string;
  distractorFeedback?: Record<string, string>;
};

export const languageTemplates: LanguageTemplate[] = [
  {
    id: "single-generator",
    title: "Messaggio del generatore",
    corrupted: "Il generatori laterale sono acceso ma la luce rosse resta spente.",
    repaired: "Il generatore laterale è acceso ma la luce rossa resta spenta.",
    distractors: [
      "I generatori laterali è acceso ma la luce rossa resta spenta.",
      "Il generatore laterale sono accesi ma la luce rossa resta spenta.",
      "Il generatore laterale è acceso ma il luce rosso resta spento.",
    ],
    diagnosticSteps: [
      "Il messaggio parla di un solo generatore.",
      "La luce è femminile singolare.",
      "Acceso/spenta descrivono due oggetti diversi.",
    ],
    hints: [
      "Separa il gruppo del generatore dal gruppo della luce.",
      "Controlla articolo, nome, aggettivo e verbo nello stesso gruppo.",
    ],
  },
  {
    id: "north-sensor",
    title: "Avviso del sensore nord",
    corrupted: "La sensori nord segnala valori instabili e richiedono una verifica.",
    repaired: "Il sensore nord segnala valori instabili e richiede una verifica.",
    distractors: [
      "I sensori nord segnala valori instabili e richiede una verifica.",
      "Il sensore nord segnalano valori instabili e richiedono una verifica.",
      "La sensore nord segnala valori instabili e richiede una verifica.",
    ],
    diagnosticSteps: [
      "Il sensore è singolare maschile.",
      "I valori sono plurali, ma non sono il soggetto principale.",
      "Il secondo verbo deve riferirsi al sensore.",
    ],
    hints: [
      "Non farti distrarre da 'valori': cerca chi compie l'azione.",
      "Il soggetto principale governa entrambi i verbi.",
    ],
  },
  {
    id: "sealed-door",
    title: "Registro della porta",
    corrupted: "Le porta ovest è bloccati finché il codici non sono verificato.",
    repaired: "La porta ovest è bloccata finché il codice non è verificato.",
    distractors: [
      "La porta ovest sono bloccata finché il codice non è verificato.",
      "La porta ovest è bloccata finché i codice non sono verificati.",
      "Le porte ovest è bloccata finché il codice non è verificato.",
    ],
    diagnosticSteps: [
      "La porta è una sola.",
      "Il codice è uno solo.",
      "Bloccata e verificato descrivono nomi diversi.",
    ],
    hints: [
      "Porta e codice non hanno lo stesso genere.",
      "La frase contiene due accordi da riparare.",
    ],
  },
  {
    id: "unstable-log",
    title: "Log del terminale",
    corrupted: "I registro centrale indica una anomalie, ma le sensore non conferma l'errore.",
    repaired: "Il registro centrale indica un'anomalia, ma il sensore non conferma l'errore.",
    distractors: [
      "Il registro centrale indicano un'anomalia, ma il sensore non conferma l'errore.",
      "Il registro centrale indica una anomalia, ma i sensore non conferma l'errore.",
      "I registri centrali indica un'anomalia, ma il sensore non confermano l'errore.",
    ],
    diagnosticSteps: [
      "Registro centrale è singolare maschile.",
      "Anomalia inizia per vocale: il sistema accetta un'anomalia.",
      "Sensore è singolare: conferma resta singolare.",
    ],
    hints: [
      "Non trasformare tutto al plurale: il log parla di un registro e un sensore.",
      "Controlla anche l'articolo davanti ad anomalia.",
    ],
  },
  {
    id: "robot-report",
    title: "Rapporto robot",
    corrupted: "La robot ausiliario hanno raccolto la chiave, però non hanno aperta la uscita.",
    repaired: "Il robot ausiliario ha raccolto la chiave, però non ha aperto l'uscita.",
    distractors: [
      "Il robot ausiliario hanno raccolto la chiave, però non ha aperto l'uscita.",
      "La robot ausiliaria ha raccolto la chiave, però non ha aperto l'uscita.",
      "Il robot ausiliario ha raccolto la chiave, però non ha aperta l'uscita.",
    ],
    diagnosticSteps: [
      "Robot è maschile singolare nel messaggio tecnico.",
      "I due verbi descrivono lo stesso robot: ha raccolto, non hanno raccolto.",
      "Aperto resta collegato all'azione, uscita richiede l'apostrofo.",
    ],
    hints: [
      "Segui lo stesso soggetto attraverso tutta la frase.",
      "Non basta correggere il primo verbo: controlla anche la seconda azione.",
    ],
  },
  {
    id: "cause-effect-cooling",
    title: "Registro causa-effetto",
    minDifficulty: 3,
    corrupted: "Il modulo scalda troppo quindi la ventola resta ferma perche riceve energia.",
    repaired: "Il modulo scalda troppo, quindi la ventola deve partire perché riceve energia.",
    distractors: [
      "Il modulo scalda troppo, quindi la ventola resta ferma perché riceve energia.",
      "Il modulo scalda troppo perché la ventola deve partire, quindi riceve energia.",
      "Il modulo scaldano troppo, quindi la ventola deve partire perché riceve energia.",
      "Il modulo scalda troppo, pero la ventola deve partire perché riceve energia.",
    ],
    diagnosticSteps: [
      "Il testo descrive una causa: il modulo scalda troppo.",
      "Quindi introduce una conseguenza operativa, non un dettaglio decorativo.",
      "Perche spiega il motivo della partenza della ventola e va scritto con accento.",
    ],
    hints: [
      "Cerca prima la causa e poi la conseguenza.",
      "Una ventola alimentata non dovrebbe restare ferma se il modulo scalda.",
      "Controlla anche il connettivo: perché spiega una ragione.",
    ],
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
      "La porta è graffiata, ma il blocco resta chiusa perché il sensore magnetico non riconosce la chiave.",
    ],
    diagnosticSteps: [
      "Il graffio è un dettaglio visivo: non spiega da solo il blocco.",
      "La causa utile è il sensore magnetico che non riconosce la chiave.",
      "Il connettivo deve distinguere contrasto e causa.",
    ],
    hints: [
      "Non tutto quello che leggi è una causa.",
      "Ma segnala contrasto; perché segnala motivo.",
      "Il sistema vuole una frase che indichi quale informazione serve davvero.",
    ],
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
      "La batteria alimentano il sensore, che invia dati alla porta.",
    ],
    diagnosticSteps: [
      "Chi invia i dati non è la batteria, ma il sensore alimentato.",
      "Il pronome deve rendere chiaro il riferimento.",
      "Che collega il sensore alla seconda azione senza cambiare il senso tecnico.",
    ],
    hints: [
      "Chiediti: chi manda i dati alla porta?",
      "La frase corretta deve togliere l'ambiguità.",
      "Non cambiare il fatto tecnico: la batteria alimenta, il sensore comunica.",
    ],
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
      "Se il LED non lampeggia, non chiudono il circuito finché il tester segnala corto.",
    ],
    diagnosticSteps: [
      "La frase è un avviso: la negazione cambia completamente l'azione.",
      "Finché indica una condizione che dura nel tempo.",
      "Un corto circuito è un motivo per aspettare, non per chiudere il circuito.",
    ],
    hints: [
      "Individua prima il rischio.",
      "Controlla se la frase autorizza o vieta l'azione.",
      "Una sola parola negativa può cambiare tutta la procedura.",
    ],
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
      "Dopo che il robot ha raccolto la chiave, il terminali verifica il codice e solo dopo la porta si apre.",
    ],
    diagnosticSteps: [
      "Il sistema ha un ordine: chiave, verifica, apertura.",
      "Ma introdurrebbe un contrasto, mentre qui serve una sequenza coerente.",
      "Solo dopo rende esplicito che la porta non anticipa il controllo.",
    ],
    hints: [
      "Ricostruisci la catena degli eventi.",
      "Scegli il connettivo che mantiene l'ordine tecnico.",
      "Non basta una frase grammaticale: deve essere eseguibile dal sistema.",
    ],
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
      "Il circuito disperde energia, però la resistenza deve limitare la corrente.",
    ],
    diagnosticSteps: [
      "Consuma il segnale è vago: il registro tecnico richiede disperde energia.",
      "La resistenza non amplifica: limita la corrente.",
      "La frase deve essere grammaticalmente corretta e tecnicamente precisa.",
    ],
    hints: [
      "Cerca la parola più precisa, non solo quella più familiare.",
      "Un componente non va descritto con una funzione che non possiede.",
      "La soluzione migliore conserva il rapporto causa-intervento.",
    ],
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
      "Il sensore invia il dato, però la porta si apre prima.",
    ],
    diagnosticSteps: [
      "Il sistema deve sapere l'ordine delle azioni.",
      "Prima e poi costruiscono una sequenza, non una causa.",
      "Il sensore deve mandare il dato prima dell'apertura.",
    ],
    hints: [
      "Disegna mentalmente due eventi: dato inviato e porta aperta.",
      "Non invertire l'ordine solo perché la frase suona più breve.",
      "Controlla anche l'accordo di sensore.",
    ],
    conceptTags: ["ordine temporale", "connettivi", "coesione"],
    learningPurpose: "Allena la comprensione di sequenze operative e l'uso di connettivi temporali chiari.",
    repairGoal: "Ricostruisci un messaggio che dica quale evento deve accadere prima.",
    method: "Metti gli eventi in fila, scegli il connettivo temporale corretto, poi verifica che la porta non anticipi il controllo.",
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
      "Le pompe che controlla il modulo segnala un blocco e richiede una prova manuale.",
    ],
    diagnosticSteps: [
      "Il soggetto principale è il modulo.",
      "Che controlla le pompe descrive il modulo, non le pompe.",
      "Segnala e richiede devono restare singolari.",
    ],
    hints: [
      "Trova prima il nome a cui si riferisce che.",
      "Le pompe sono oggetto della relativa: non comandano il verbo principale.",
      "Controlla entrambi i verbi della frase.",
    ],
    conceptTags: ["frase relativa", "soggetto", "accordo verbale"],
    learningPurpose: "Allena il riconoscimento del soggetto anche quando la frase contiene una relativa.",
    repairGoal: "Rendi eseguibile il log mantenendo chi controlla cosa.",
    method: "Isola la frase con che, torna al soggetto principale, poi controlla i verbi collegati.",
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
      "Non aprire il vano, perché il LED rosso lampeggia e scollega la batteria.",
    ],
    diagnosticSteps: [
      "La frase contiene un divieto e una procedura di sicurezza.",
      "I due punti separano il divieto dalla condizione operativa.",
      "La virgola dopo la condizione aiuta a capire cosa fare.",
    ],
    hints: [
      "Chiediti: qual è l'azione vietata e qual è l'azione richiesta?",
      "La punteggiatura può cambiare chi compie l'azione.",
      "Il LED non scollega la batteria: lo fa l'operatore.",
    ],
    conceptTags: ["punteggiatura", "condizione", "sicurezza"],
    learningPurpose: "Allena l'uso della punteggiatura per evitare ambiguità nelle istruzioni.",
    repairGoal: "Scrivi un avviso che distingua chiaramente divieto, condizione e azione sicura.",
    method: "Separa divieto e procedura, poi controlla chi deve compiere l'azione.",
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
      "Il diario segnala un'ipotesi: la valvola potrebbe essere guasta, quindi ignora il controllo.",
    ],
    diagnosticSteps: [
      "Forse indica incertezza, non prova definitiva.",
      "Un'ipotesi va verificata prima di un'azione drastica.",
      "La frase corretta deve conservare prudenza e procedura.",
    ],
    hints: [
      "Distingui informazione certa e informazione da verificare.",
      "Non trasformare forse in sicuramente.",
      "Il sistema deve capire che serve un controllo prima dell'arresto.",
    ],
    conceptTags: ["pensiero critico", "modalità", "fonte"],
    learningPurpose: "Allena la lettura critica: una fonte incerta non autorizza subito una decisione massima.",
    repairGoal: "Rendi il messaggio prudente: conserva l'ipotesi e aggiungi la verifica necessaria.",
    method: "Valuta quanto è certa la fonte, poi scegli una frase che guidi una decisione proporzionata.",
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
      "Il robot verifica il sensore e calibra la porta.",
    ],
    diagnosticSteps: [
      "Fa il controllo è vago: verifica è più preciso.",
      "Aggiusta è generico: calibra la lettura descrive l'intervento tecnico.",
      "Ne collega la lettura al sensore senza ripetizioni inutili.",
    ],
    hints: [
      "Cerca verbi più precisi, non parole più lunghe.",
      "Chiediti quale parte viene calibrata: il sensore o la sua lettura?",
      "Il pronome ne evita ambiguità e ripetizione.",
    ],
    conceptTags: ["lessico tecnico", "pronome ne", "precisione"],
    learningPurpose: "Allena lessico preciso e coesione testuale con pronomi avanzati ma utili.",
    repairGoal: "Trasforma un rapporto vago in una procedura tecnica comprensibile.",
    method: "Sostituisci parole generiche con verbi tecnici e controlla a cosa si riferisce il pronome.",
  },
];
