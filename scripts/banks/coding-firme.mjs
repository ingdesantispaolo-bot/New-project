// Coding — le firme della materia, primo lotto. 10 settembre 2026.
//
// ## Perché questo file esiste
//
// Coding è la materia più povera del gioco in ventuno mondi su ventiquattro: 306
// item, quindici sessioni distinte nelle fasce 1, 4 e 8 — cioè esattamente sul
// pavimento — e da ieri sta nel nucleo, dove una sessione ne consuma sei.
//
// Ma il problema vero non è la quantità. Coding aveva **tre formati soli**:
// abbina, ordina, smista, gli stessi che hanno tutte e dodici le materie. Non
// c'era niente che somigliasse a programmare, e il formato che ci andava più
// vicino — `code_debug`, «trova la riga sbagliata» — è una scelta multipla con
// del codice sopra.
//
// ## Le quattro firme, e perché quattro
//
// Una disciplina non si esaurisce in un gesto. Programmare è almeno quattro cose
// diverse, e ciascuna vuole un'interazione sua:
//
//   1. **la catena di montaggio** — comporre funzioni in fila, e scoprire che
//      l'ordine cambia il risultato. È `machine_path`, che ESISTE già: il valore
//      entra da un capo, attraversa le macchine montate e ne esce trasformato.
//      Il risultato lo produce il montaggio, non un elenco di alternative.
//   2. **il robot nella griglia** — sequenza, cicli, condizioni, e il bug che si
//      guarda muovere. Chiesto a Codex come C-R4d.
//   3. **il centralino** — le condizioni e il loro ORDINE: in una catena di
//      `elif` vince il primo controllo vero, e metterli nell'ordine sbagliato non
//      dà errore, dà il risultato sbagliato a tutti. Secondo giro.
//   4. **il passo a passo** — lo stato: che cosa vale ogni variabile dopo ogni
//      riga. Secondo giro.
//
// Questo lotto scrive la prima e prepara il terreno alle altre tre usando i
// formati disponibili: la catena di `elif` si può già ORDINARE, lo stato si può
// già SMISTARE fra «cambia» e «legge».
//
// ## La catena di montaggio, nel dettaglio
//
// `machine_path` accetta da due a quattro posti e pretende almeno una macchina
// in più dei posti: ci devono essere alternative da scartare, o non si sceglie
// niente. La stessa macchina si può montare due volte — ed è un concetto, non
// una scappatoia: applicare due volte la stessa funzione è quello che fa un
// ciclo. La divisione si blocca se il numero non è divisibile, e il blocco è
// didattico: è una precondizione che non è stata rispettata, e si vede dove.
//
// **Ogni soluzione dichiarata è stata verificata a mano e la ricontrolla il
// bake**: `ExerciseInteraction.evaluate_machine_path` rifiuta un percorso che
// non arriva al traguardo, e questo file è la sorgente, non la copia.
//
// ## Regole di scrittura
//
// Le stesse degli altri lotti: fascia dichiarata con `difficulty8`, un
// (formato, argomento) mai ripetuto dentro la finestra di difficoltà, e ogni
// prova con la sua spiegazione — che dice il *perché*, non ripete la risposta.

export const CODING_FIRME = [

  // =========================================================== fascia 1
  //
  // Il primo incontro con l'officina. Due posti soli: si sceglie che cosa
  // montare, non ancora in che ordine.

  { topic: "funzioni", difficulty: 1, difficulty8: true, format: "machine_path",
    prompt: "Nell'officina del Relitto il pacchetto entra con 3 e deve uscire con 10. Monta due macchine in fila.",
    start: 3, target: 10, slotCount: 2,
    machines: [
      { id: "x2", op: "multiply", value: 2, label: "raddoppia" },
      { id: "p4", op: "add", value: 4, label: "aggiungi 4" },
      { id: "m1", op: "subtract", value: 1, label: "togli 1" },
      { id: "x3", op: "multiply", value: 3, label: "triplica" },
    ],
    solution: ["x2", "p4"],
    explanation: "Tre raddoppiato fa sei, più quattro fa dieci. Ogni macchina lavora su quello che le arriva, non sul numero di partenza: è la prima idea delle funzioni in fila, e da qui in poi non cambia più." },

  { topic: "operatori", difficulty: 1, difficulty8: true, format: "machine_path",
    prompt: "Il pacchetto entra con 5 e deve uscire con 12. Due macchine.",
    start: 5, target: 12, slotCount: 2,
    machines: [
      { id: "p1", op: "add", value: 1, label: "aggiungi 1" },
      { id: "x2", op: "multiply", value: 2, label: "raddoppia" },
      { id: "m2", op: "subtract", value: 2, label: "togli 2" },
      { id: "x3", op: "multiply", value: 3, label: "triplica" },
    ],
    solution: ["p1", "x2"],
    explanation: "Cinque più uno fa sei, raddoppiato fa dodici. Prova anche l'ordine opposto e guarda che cosa succede: raddoppiare prima porta a undici, non a dodici. Le macchine sono le stesse, il risultato no." },

  { topic: "liste", difficulty: 1, difficulty8: true, format: "ordering",
    prompt: "Il nastro consegna quattro casse numerate. Mettile nell'ordine in cui il programma le leggerebbe partendo dalla posizione zero.",
    items: ["la cassa in posizione 2", "la cassa in posizione 0", "la cassa in posizione 3", "la cassa in posizione 1"],
    correctOrder: ["la cassa in posizione 0", "la cassa in posizione 1", "la cassa in posizione 2", "la cassa in posizione 3"],
    explanation: "La prima cassa sta in posizione zero, non uno. Sembra un capriccio e non lo è: contando da zero, la posizione dice quante caselle hai saltato per arrivarci — e la quarta cassa sta in posizione tre." },

  { topic: "condizioni", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Il portello si apre solo a certe condizioni. Abbina ogni controllo a quello che deve essere vero perché passi.",
    pairs: [
      { left: "energia > 50", right: "l'energia deve superare cinquanta" },
      { left: "chiavi == 3", right: "le chiavi devono essere esattamente tre" },
      { left: "allarme == False", right: "l'allarme deve essere spento" },
      { left: "peso <= 20", right: "il peso non deve superare venti" },
    ],
    explanation: "Ogni simbolo dice una cosa precisa e una sola: maggiore non è «maggiore o uguale», e due uguali chiedono, non comandano. Un portello che si apre con la condizione sbagliata non dà errore: si apre quando non dovrebbe." },

  { topic: "cicli", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni compito secondo come conviene farlo fare alla macchina.",
    items: ["accendere tutte e trenta le luci del corridoio", "accendere la luce dell'ingresso", "salutare ognuno dei dodici abitanti", "aprire il portello principale"],
    categories: ["con un ciclo", "con una riga sola"],
    assignments: {
      "accendere tutte e trenta le luci del corridoio": "con un ciclo",
      "accendere la luce dell'ingresso": "con una riga sola",
      "salutare ognuno dei dodici abitanti": "con un ciclo",
      "aprire il portello principale": "con una riga sola",
    },
    explanation: "Il ciclo serve quando la stessa cosa va fatta molte volte e non sai in anticipo quante: trenta luci scritte una per una funzionano finché non ne aggiungono una trentunesima. Una cosa che si fa una volta sola non ha bisogno di niente." },

  { topic: "tipi", difficulty: 1, difficulty8: true, format: "ordering",
    prompt: "Il numero digitato dall'abitante arriva come testo. Metti in ordine quello che deve succedere prima di poterci fare un conto.",
    items: ["fai la somma", "trasforma il testo in numero", "ricevi quello che è stato scritto"],
    correctOrder: ["ricevi quello che è stato scritto", "trasforma il testo in numero", "fai la somma"],
    explanation: "Sommare a un testo non dà un numero sbagliato: dà un errore, e il programma si ferma. La trasformazione sta in mezzo perché è l'unico punto in cui può stare — dopo la somma sarebbe troppo tardi." },

  { topic: "booleani", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni sensore del Relitto a quello che restituisce.",
    pairs: [
      { left: "il portello è aperto?", right: "vero oppure falso" },
      { left: "quanta energia c'è?", right: "un numero" },
      { left: "come si chiama l'abitante?", right: "un testo" },
      { left: "quali chiavi hai?", right: "un elenco" },
    ],
    explanation: "Una domanda che si può chiudere con sì o no restituisce vero o falso, e sono i soli due valori possibili: non «quasi aperto». Il tipo della risposta si capisce dalla domanda, prima ancora di leggere il codice." },

  { topic: "stringhe", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Il pannello vuole un testo. Smista quello che ci puoi scrivere dentro.",
    items: ["\"portello 3\"", "\"7\"", "7", "\"vero\""],
    categories: ["è già un testo", "va prima trasformato"],
    assignments: {
      "\"portello 3\"": "è già un testo",
      "\"7\"": "è già un testo",
      "7": "va prima trasformato",
      "\"vero\"": "è già un testo",
    },
    explanation: "Le virgolette fanno il testo, non il contenuto: «7» fra virgolette è un carattere scritto, 7 senza è una quantità. È la stessa differenza che c'è fra il numero di un portello e il portello." },

  // =========================================================== fascia 4-5
  //
  // Tre posti. Adesso l'ordine conta, e la stessa macchina si può montare due
  // volte: applicare due volte una funzione è quello che fa un ciclo.

  { topic: "funzioni", difficulty: 4, difficulty8: true, format: "machine_path",
    prompt: "Il pacchetto entra con 2 e deve uscire con 20. Hai tre posti, e una macchina si può montare anche due volte.",
    start: 2, target: 20, slotCount: 3,
    machines: [
      { id: "x2", op: "multiply", value: 2, label: "raddoppia" },
      { id: "p3", op: "add", value: 3, label: "aggiungi 3" },
      { id: "m4", op: "subtract", value: 4, label: "togli 4" },
      { id: "x5", op: "multiply", value: 5, label: "moltiplica per 5" },
    ],
    solution: ["p3", "x2", "x2"],
    explanation: "Due più tre fa cinque, raddoppiato due volte fa venti. Montare due volte la stessa macchina non è una scorciatoia: è esattamente quello che fa un ciclo che gira due volte, e qui lo si vede in fila." },

  { topic: "operatori", difficulty: 4, difficulty8: true, format: "machine_path",
    prompt: "Il pacchetto entra con 7 e deve uscire con 3. Attenzione: la macchina che dimezza si inceppa sui numeri dispari.",
    start: 7, target: 3, slotCount: 3,
    machines: [
      { id: "p1", op: "add", value: 1, label: "aggiungi 1" },
      { id: "meta", op: "divide", value: 2, label: "dimezza" },
      { id: "m1", op: "subtract", value: 1, label: "togli 1" },
      { id: "x3", op: "multiply", value: 3, label: "triplica" },
    ],
    solution: ["p1", "meta", "m1"],
    explanation: "Sette più uno fa otto, che si dimezza; quattro meno uno fa tre. Dimezzare per primo blocca tutto, e non perché la macchina sia rotta: dividere in parti uguali un numero dispari non si può. È una precondizione, ed è il tipo di errore che in un programma vero si scopre solo quando capita." },

  { topic: "funzioni", difficulty: 5, difficulty8: true, format: "classification",
    prompt: "Smista ogni frammento secondo che cosa fa quando il programma ci arriva.",
    items: ["def accendi(luce):", "accendi(3)", "return energia", "risultato = accendi(3)"],
    categories: ["descrive e basta", "esegue davvero"],
    assignments: {
      "def accendi(luce):": "descrive e basta",
      "accendi(3)": "esegue davvero",
      "return energia": "descrive e basta",
      "risultato = accendi(3)": "esegue davvero",
    },
    explanation: "Definire è scrivere la ricetta, chiamare è cucinarla. Una funzione definita e mai chiamata non fa assolutamente niente, e il programma non protesta: è il motivo per cui «ho scritto la funzione ma non succede nulla» è il primo errore di tutti." },

  { topic: "variabili", difficulty: 4, difficulty8: true, format: "classification",
    prompt: "Due nomi indicano la stessa cassa di attrezzi. Smista che cosa succede a ciascuna operazione.",
    items: ["aggiungi un attrezzo usando il primo nome", "leggi quanti attrezzi ci sono col secondo nome", "dai il primo nome a una cassa nuova", "svuota la cassa col secondo nome"],
    categories: ["si vede da tutti e due i nomi", "riguarda un nome solo"],
    assignments: {
      "aggiungi un attrezzo usando il primo nome": "si vede da tutti e due i nomi",
      "leggi quanti attrezzi ci sono col secondo nome": "riguarda un nome solo",
      "dai il primo nome a una cassa nuova": "riguarda un nome solo",
      "svuota la cassa col secondo nome": "si vede da tutti e due i nomi",
    },
    explanation: "Due nomi sulla stessa cassa: chi modifica il contenuto lo cambia per entrambi, chi sposta un nome su un'altra cassa lascia l'altro dov'era. È la differenza fra cambiare una cosa e cambiare a che cosa punta un nome, ed è la sorgente di quasi tutti i guasti difficili." },

  { topic: "liste", difficulty: 4, difficulty8: true, format: "matching",
    prompt: "Abbina ogni comando al nastro trasportatore che fa quel lavoro.",
    pairs: [
      { left: "aggiungi in fondo", right: "il nastro si allunga di una cassa" },
      { left: "conta quante ce ne sono", right: "il nastro resta com'è e ti dà un numero" },
      { left: "prendi la prima", right: "il nastro resta com'è e ti dà una cassa" },
      { left: "riordina dalla più leggera", right: "le stesse casse cambiano posto" },
    ],
    explanation: "Alcune operazioni chiedono e altre modificano, e non si distinguono dal nome: contare e riordinare sembrano parenti e fanno cose opposte. La differenza conta quando lo stesso nastro è usato in due punti del programma." },

  { topic: "condizioni", difficulty: 5, difficulty8: true, format: "ordering",
    prompt: "Il centralino assegna un badge secondo l'energia. Metti i tre controlli nell'ordine in cui devono comparire perché il badge sia giusto.",
    items: ["energia >= 30", "energia >= 80", "energia >= 60"],
    correctOrder: ["energia >= 80", "energia >= 60", "energia >= 30"],
    explanation: "In una catena di controlli vince il primo che è vero, quindi vanno messi dal più esigente al meno esigente. Con «trenta» in cima, un abitante con novanta di energia entrerebbe lì dentro e non arriverebbe mai agli altri due: nessun errore, e il badge sbagliato a tutti i migliori." },

  { topic: "cicli", difficulty: 5, difficulty8: true, format: "matching",
    prompt: "Abbina ogni comando all'effetto che ha sul nastro in movimento.",
    pairs: [
      { left: "ferma tutto", right: "il nastro si spegne, le casse rimaste restano lì" },
      { left: "salta questa", right: "questa cassa non viene lavorata, il nastro prosegue" },
      { left: "gira finché non è vuoto", right: "va avanti da solo finché qualcosa lo ferma" },
      { left: "una ogni due", right: "lavora la prima, salta la seconda, e così via" },
    ],
    explanation: "Fermare tutto e saltarne una sembrano parenti e sono opposti: uno abbandona il ciclo, l'altro abbandona solo il giro. Scambiarli produce un programma che funziona sui casi facili e sbaglia esattamente quando la condizione scatta." },

  // =========================================================== fascia 7-8
  //
  // Quattro posti, e macchine che si bloccano. Qui il montaggio non basta:
  // bisogna prevedere che cosa arriva alla macchina successiva.

  { topic: "algoritmi", difficulty: 7, difficulty8: true, format: "machine_path",
    prompt: "Il pacchetto entra con 3 e deve uscire con 48. Quattro posti.",
    start: 3, target: 48, slotCount: 4,
    machines: [
      { id: "p1", op: "add", value: 1, label: "aggiungi 1" },
      { id: "x2", op: "multiply", value: 2, label: "raddoppia" },
      { id: "x3", op: "multiply", value: 3, label: "triplica" },
      { id: "m2", op: "subtract", value: 2, label: "togli 2" },
      { id: "meta", op: "divide", value: 2, label: "dimezza" },
    ],
    solution: ["p1", "x2", "x3", "x2"],
    explanation: "Tre più uno fa quattro, poi otto, poi ventiquattro, poi quarantotto. Con quattro posti i percorsi possibili sono centinaia: conviene guardare il traguardo e chiedersi da quali numeri ci si arriva — quarantotto è il doppio di ventiquattro, che è il triplo di otto. Ragionare all'indietro costa meno che provare in avanti." },

  { topic: "operatori", difficulty: 8, difficulty8: true, format: "machine_path",
    prompt: "Il pacchetto entra con 9 e deve uscire con 5. Due macchine dividono, e tutte e due si inceppano se il numero non è divisibile.",
    start: 9, target: 5, slotCount: 4,
    machines: [
      { id: "x2", op: "multiply", value: 2, label: "raddoppia" },
      { id: "terzo", op: "divide", value: 3, label: "dividi per 3" },
      { id: "p4", op: "add", value: 4, label: "aggiungi 4" },
      { id: "meta", op: "divide", value: 2, label: "dimezza" },
      { id: "m1", op: "subtract", value: 1, label: "togli 1" },
    ],
    solution: ["x2", "terzo", "p4", "meta"],
    explanation: "Nove raddoppiato fa diciotto, che si divide per tre; sei più quattro fa dieci, che si dimezza. Raddoppiare per primo sembra un passo indietro e serve proprio a rendere il numero divisibile: a volte bisogna allontanarsi dal traguardo per poterci arrivare." },

  { topic: "liste", difficulty: 7, difficulty8: true, format: "ordering",
    prompt: "Ordinamento per selezione sul nastro. Metti in ordine i passi di un singolo giro.",
    items: ["ricomincia dalla cassa successiva", "scambiala con la prima non ancora sistemata", "cerca la più leggera fra quelle non sistemate"],
    correctOrder: ["cerca la più leggera fra quelle non sistemate", "scambiala con la prima non ancora sistemata", "ricomincia dalla cassa successiva"],
    explanation: "Ogni giro sistema definitivamente una posizione, e la parte già ordinata cresce di uno. È lento — su mille casse quasi un milione di confronti — ma ha una proprietà preziosa: dopo k giri le prime k casse sono quelle giuste e non si toccano più." },

  { topic: "stringhe", difficulty: 7, difficulty8: true, format: "classification",
    prompt: "Il registro del Relitto confronta due nomi digitati. Smista ogni coppia.",
    items: ["\"Nora\" e \"Nora\"", "\"Nora\" e \"nora\"", "\"Nora \" e \"Nora\"", "\"No\" + \"ra\" e \"Nora\""],
    categories: ["il programma le considera uguali", "le considera diverse"],
    assignments: {
      "\"Nora\" e \"Nora\"": "il programma le considera uguali",
      "\"Nora\" e \"nora\"": "le considera diverse",
      "\"Nora \" e \"Nora\"": "le considera diverse",
      "\"No\" + \"ra\" e \"Nora\"": "il programma le considera uguali",
    },
    explanation: "Il confronto guarda i caratteri uno per uno: una maiuscola è un carattere diverso da una minuscola, e uno spazio in fondo è un carattere in più. Per questo prima di ogni confronto si toglie lo spazio e si porta tutto minuscolo — non per eleganza, perché altrimenti due nomi identici per un essere umano non lo sono per il programma." },

  { topic: "tipi", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni contenitore del Relitto a quello che lo distingue.",
    pairs: [
      { left: "il nastro", right: "si può allungare e riordinare" },
      { left: "la targa incisa", right: "una volta scritta non cambia più" },
      { left: "lo schedario", right: "si cerca per nome, non per posizione" },
      { left: "il sigillo a coppie", right: "tiene insieme due valori e li blocca" },
    ],
    explanation: "Poter cambiare o no non è un dettaglio tecnico: decide se puoi passare il contenitore a un'altra parte del programma senza rischiare che te lo modifichi. Quello che non cambia si può condividere senza paura." },

  { topic: "cicli", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Il nastro raddoppia di lunghezza. Smista ogni operazione secondo come cresce il tempo che impiega.",
    items: ["scorrere tutte le casse una volta", "guardare solo la prima cassa", "confrontare ogni cassa con ogni altra", "dimezzare la ricerca su un nastro ordinato"],
    categories: ["raddoppia anche il tempo", "il tempo cresce molto di più", "il tempo resta quasi lo stesso"],
    assignments: {
      "scorrere tutte le casse una volta": "raddoppia anche il tempo",
      "guardare solo la prima cassa": "il tempo resta quasi lo stesso",
      "confrontare ogni cassa con ogni altra": "il tempo cresce molto di più",
      "dimezzare la ricerca su un nastro ordinato": "il tempo resta quasi lo stesso",
    },
    explanation: "Non conta quanto è veloce la macchina: conta come il lavoro cresce con i dati. Confrontare tutte le coppie quadruplica quando le casse raddoppiano, e su un nastro lungo diventa impraticabile su qualunque macchina; dimezzare aggiunge un solo passo." },

  { topic: "booleani", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Il portello si apre solo se hai la chiave E l'allarme è spento. Metti in ordine i controlli in modo che il programma smetta di controllare il prima possibile.",
    items: ["l'allarme è spento (richiede di interrogare il sensore)", "hai la chiave (basta guardare nello zaino)"],
    correctOrder: ["hai la chiave (basta guardare nello zaino)", "l'allarme è spento (richiede di interrogare il sensore)"],
    explanation: "Con «e» basta che il primo sia falso perché il secondo non venga nemmeno guardato: il programma smette lì. Mettere per primo il controllo che costa meno risparmia tutte le volte che quello fallisce — e con «oppure» vale il contrario, per primo va quello che ha più probabilità di essere vero." },

  { topic: "output", difficulty: 7, difficulty8: true, format: "matching",
    prompt: "Abbina ogni messaggio del Relitto a chi lo deve leggere.",
    pairs: [
      { left: "Portello 3 aperto", right: "l'abitante che sta usando la macchina" },
      { left: "energia=47 chiavi=2", right: "chi sta cercando un guasto" },
      { left: "Manca la chiave: cercala nell'officina", right: "chi ha appena sbagliato qualcosa" },
      { left: "riga 12: valore non atteso", right: "chi ha scritto il programma" },
    ],
    explanation: "Un messaggio serve a qualcuno di preciso, e cambiare destinatario lo rende inutile: «valore non atteso» a un bambino non dice niente, e «tutto bene!» a chi cerca un guasto nemmeno. Un buon messaggio d'errore dice che cosa è successo e che cosa si può fare, in quest'ordine." },
];
