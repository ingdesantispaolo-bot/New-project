// Musica — le firme, primo lotto. 11 settembre 2026.
//
// ## Due gesti trovati senza chiedere niente a Codex
//
// La lezione del lotto di elettronica — prima di chiedere un renderer, guardare
// se il gesto esiste già sotto il nome di un'altra materia — vale anche qui, e
// due volte.
//
// **1. Il ritmo è aritmetica esatta, quindi è `machine_path`.** L'albero delle
// durate è una catena di dimezzamenti: la semibreve vale due minime, la minima
// due semiminime, e così via fino alla croma e alla semicroma. Contando tutto in
// **sedicesimi** i valori diventano interi — semibreve 16, minima 8, semiminima
// 4, croma 2, semicroma 1 — e la catena di macchine li attraversa senza mai
// dover dividere male. Il punto di valore è un ×3 seguito da un ÷2, che è
// esattamente «una volta e mezza»: montarlo è capirlo.
//
// **2. Il metronomo è una scala, quindi è `timeline`.** Adagio, andante,
// allegro e presto non sono nomi da ricordare: sono zone di una linea che va da
// quaranta a duecento battiti al minuto, e collocarli è il gesto con cui si
// imparano. Il contratto vuole da due a sei eventi, ben separati sulla scala, e
// una risposta che sia uno di loro.
//
// Resta C-R4b — la battuta da riempire, dove si trascinano figure finché i
// valori tornano — perché quella chiede un pentagramma vero e non c'è.
//
// ## La quota di risposta libera
//
// Musica stava esattamente al 20,0%, cioè sul pavimento: ogni item da toccare
// abbassa quella frazione, perché conta nel totale e non fra i liberi. Quattro
// di queste prove sono quindi a risposta scritta, e non come riempitivo — sono
// le cose che in musica si sanno o non si sanno, e che avere davanti quattro
// alternative regalerebbe.

export const MUSICA_FIRME = [

  // ============================ le durate: una catena di dimezzamenti esatti

  { topic: "ritmo", difficulty: 3, difficulty8: true, format: "machine_path",
    prompt: "Contiamo tutto in sedicesimi: la semibreve ne vale 16. Monta tre stadi per arrivare dalla semibreve alla croma, che ne vale 2.",
    start: 16, target: 2, slotCount: 3,
    machines: [
      { id: "meta", op: "divide", value: 2, label: "la figura successiva (metà)" },
      { id: "quarto", op: "divide", value: 4, label: "salta due figure (un quarto)" },
      { id: "x2", op: "multiply", value: 2, label: "la figura precedente (doppia)" },
      { id: "m4", op: "subtract", value: 4, label: "togli quattro sedicesimi" },
    ],
    solution: ["meta", "meta", "meta"],
    explanation: "Semibreve, minima, semiminima, croma: ogni figura vale la metà della precedente, e tre dimezzamenti portano da sedici a due. È il motivo per cui le durate non si sommano a caso — sono una scala di potenze di due, e per questo quattro semiminime riempiono esattamente una semibreve." },

  { topic: "note", difficulty: 6, difficulty8: true, format: "machine_path",
    prompt: "La minima vale 8 sedicesimi. Il punto messo accanto a una figura la allunga della metà: monta due stadi per arrivare al valore della minima puntata.",
    start: 8, target: 12, slotCount: 2,
    machines: [
      { id: "x3", op: "multiply", value: 3, label: "triplica" },
      { id: "meta", op: "divide", value: 2, label: "dimezza" },
      { id: "p4", op: "add", value: 4, label: "aggiungi quattro sedicesimi" },
      { id: "x2", op: "multiply", value: 2, label: "raddoppia" },
    ],
    solution: ["x3", "meta"],
    explanation: "Allungare della metà vuol dire moltiplicare per uno e mezzo, e uno e mezzo si ottiene triplicando e poi dimezzando: otto diventa ventiquattro e poi dodici. Funziona anche nell'ordine opposto, e non è un caso — ma provare ad aggiungere quattro funziona solo per la minima, e con un'altra figura darebbe il numero sbagliato." },

  // ============================ il metronomo: una scala, non quattro parole

  { topic: "tempo", difficulty: 3, difficulty8: true, format: "timeline",
    prompt: "La scala del metronomo va da 40 a 200 battiti al minuto. Colloca le indicazioni, poi indica dov'è ALLEGRO.",
    min: 40, max: 200,
    targets: [
      { id: "adagio", label: "adagio · 60", value: 60 },
      { id: "andante", label: "andante · 90", value: 90 },
      { id: "allegro", label: "allegro · 130", value: 130 },
      { id: "presto", label: "presto · 180", value: 180 },
    ],
    answer: "allegro",
    explanation: "Non sono quattro parole da ricordare in fila: sono zone di una scala, e conoscerne una aiuta a collocare le altre. «Andante» conserva ancora il suo senso letterale — la velocità di uno che cammina, novanta passi al minuto — e allegro sta ben oltre, dove il passo diventa corsa." },

  // ================================================= i gesti sulle basi

  { topic: "lettura", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni segno dello spartito a quello che dice all'esecutore.",
    pairs: [
      { left: "la chiave di violino", right: "da quale nota partire per leggere il rigo" },
      { left: "la stanghetta", right: "dove finisce una battuta" },
      { left: "il ritornello", right: "torna indietro e ripeti" },
      { left: "la pausa", right: "sta' in silenzio per questa durata" },
    ],
    explanation: "La pausa è il segno che sorprende: non è un vuoto, è una durata come le altre, e va contata esattamente come una nota. Uno spartito senza pause non sarebbe più veloce — sarebbe sbagliato, perché le battute non tornerebbero." },

  { topic: "dinamica", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni indicazione secondo che cosa chiede.",
    items: ["piano", "forte", "crescendo", "diminuendo"],
    categories: ["dice quanto suonare", "dice come cambiare"],
    assignments: {
      "piano": "dice quanto suonare",
      "forte": "dice quanto suonare",
      "crescendo": "dice come cambiare",
      "diminuendo": "dice come cambiare",
    },
    explanation: "Due famiglie diverse: alcune indicazioni fissano un livello e ci si resta, altre chiedono un viaggio da un livello all'altro. Un crescendo senza un punto di partenza e uno di arrivo non vuol dire niente — ed è per questo che nello spartito sta quasi sempre fra due indicazioni fisse." },

  { topic: "strumenti", difficulty: 1, difficulty8: true, format: "ordering",
    prompt: "Metti questi strumenti ad arco in ordine, dal suono più grave al più acuto.",
    items: ["il violino", "il contrabbasso", "la viola", "il violoncello"],
    correctOrder: ["il contrabbasso", "il violoncello", "la viola", "il violino"],
    explanation: "L'ordine è quello delle dimensioni, e non è una coincidenza: più lunga e grossa è la corda, più lentamente vibra, e più grave è il suono. Vale per qualunque famiglia — è lo stesso motivo per cui le canne lunghe dell'organo fanno i bassi." },

  { topic: "tempo", difficulty: 1, difficulty8: true, format: "numeric_input",
    prompt: "In una battuta di 4/4, quanti movimenti ci sono?",
    answer: "4",
    explanation: "Il numero sopra dice quanti movimenti ha la battuta, quello sotto quale figura vale un movimento: in 4/4 sono quattro movimenti da un quarto. Cambiare il numero di sotto non cambia quanti movimenti ci sono, cambia quanto dura ciascuno." },

  { topic: "lettura", difficulty: 4, difficulty8: true, format: "classification",
    prompt: "Smista ogni coppia di note secondo come si muove la melodia sul rigo.",
    items: ["da una riga alla riga sopra", "da uno spazio alla riga subito sopra", "dalla stessa riga alla stessa riga", "da una riga allo spazio sotto"],
    categories: ["sale", "scende", "resta ferma"],
    assignments: {
      "da una riga alla riga sopra": "sale",
      "da uno spazio alla riga subito sopra": "sale",
      "dalla stessa riga alla stessa riga": "resta ferma",
      "da una riga allo spazio sotto": "scende",
    },
    explanation: "Sul pentagramma l'altezza è letterale: più in alto sta il pallino, più acuta è la nota. È l'unica scrittura al mondo in cui il significato sta nella posizione verticale, ed è il motivo per cui si legge una melodia a colpo d'occhio anche senza riconoscere ogni singola nota." },

  { topic: "note", difficulty: 4, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il segno che alza una nota di un semitono?",
    answer: "diesis", accept: ["il diesis", "diesis (#)"],
    explanation: "Il diesis alza, il bemolle abbassa, il bequadro riporta la nota com'era. Valgono per tutta la battuta e non per la nota singola: è proprio per questo che il bequadro esiste — serve ad annullare un'alterazione prima che la battuta finisca." },

  { topic: "intervalli", difficulty: 6, difficulty8: true, format: "numeric_input",
    prompt: "Da do a sol, contando do come primo grado, quanti gradi ci sono?",
    answer: "5",
    explanation: "Do, re, mi, fa, sol: cinque gradi, e per questo l'intervallo si chiama quinta. Gli intervalli si contano includendo la nota di partenza, che sembra strano ma rende il conto coerente — do-do è una prima, non una zero." },

  { topic: "intervalli", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista questi intervalli secondo come suonano quando le due note si sentono insieme.",
    items: ["l'ottava", "la quinta giusta", "la seconda minore", "la settima maggiore"],
    categories: ["suonano stabili insieme", "creano tensione"],
    assignments: {
      "l'ottava": "suonano stabili insieme",
      "la quinta giusta": "suonano stabili insieme",
      "la seconda minore": "creano tensione",
      "la settima maggiore": "creano tensione",
    },
    explanation: "La stabilità non è una questione di gusto: dipende da quanto semplici sono i rapporti fra le frequenze — l'ottava è 2:1, la quinta 3:2, mentre la seconda minore è un rapporto complicato e l'orecchio lo sente come attrito. La musica usa la tensione apposta, per poi scioglierla." },

  { topic: "ritmo", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni metro al movimento che gli somiglia.",
    pairs: [
      { left: "4/4", right: "il passo di una marcia" },
      { left: "3/4", right: "il giro di un valzer" },
      { left: "6/8", right: "il dondolio di una barca" },
      { left: "2/4", right: "il saltello di una polka" },
    ],
    explanation: "Il metro non conta soltanto i movimenti: dice dove cadono gli accenti, e l'accento è quello che il corpo sente. In tre si gira perché l'accento torna ogni tre passi e non si può marciare; in sei ottavi i movimenti si raggruppano a due a due e nasce il dondolio." },

  { topic: "dinamica", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama l'indicazione che chiede di aumentare l'intensità poco a poco?",
    answer: "crescendo", accept: ["il crescendo", "cresc."],
    explanation: "È un participio presente italiano — «mentre cresce» — e come quasi tutto il vocabolario musicale è rimasto in italiano in ogni orchestra del mondo. Il suo opposto è diminuendo, e tutti e due chiedono un viaggio: dicono come si cambia, non a che livello si arriva." },
];
