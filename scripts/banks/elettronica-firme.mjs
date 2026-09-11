// Elettronica — le firme, primo lotto. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Elettronica era la materia più scoperta delle dodici: 171 item e **zero**
// manipolativi, cioè nemmeno un esercizio in cui si sposta qualcosa. Il suo
// formato-firma, il banco di prova che si monta e si accende, è stato chiesto a
// Codex come C-R4a e non esiste ancora.
//
// ## Ma una firma ce l'aveva già, e nessuno se n'era accorto
//
// `porte` — la tavola di verità a quattro righe — è registrata come formato di
// **logica**. Eppure le porte logiche sono elettronica prima che logica, e il
// legame è letterale, non una metafora:
//
//   due interruttori **in serie**      →  la porta AND
//   due interruttori **in parallelo**  →  la porta OR
//
// Sono la stessa cosa guardata da due discipline. Un bambino che ha montato due
// interruttori in fila e ha visto che la lampada si accende solo con tutti e due
// ha già capito la porta AND, e non lo sa. Queste prove glielo dicono.
//
// Il renderer c'è, il contratto è quello di `ExerciseInteraction._validate_porte`
// — quattro righe, una per combinazione, nessuna ripetuta, e mai una porta
// degenere — e da ieri il banco lo sa portare. Costo per Codex: zero.
//
// ## E `machine_path` diventa la catena di stadi
//
// Il percorso di macchine è nato per la matematica, ma un segnale che attraversa
// stadi che lo dimezzano o lo triplicano è esattamente quello che fa un
// partitore: il valore entra da un capo, ogni stadio lo trasforma, e quello che
// esce dipende dall'ordine. Qui l'aritmetica non è un travestimento: è la
// grandezza vera.
//
// **Nota sull'esame.** `build_final_exam` accetta dall'elettronica soltanto
// `multiple_choice` e `short_answer`: nel mondo si impara facendo, all'esame la
// sua prova misura il richiamo. Queste prove vivono quindi nelle palestre e
// nelle missioni, non nell'esame — ed è deliberato, non un limite da aggirare.

export const ELETTRONICA_FIRME = [

  // ===================================================== le porte, che sono
  // interruttori prima di essere logica

  { topic: "circuito", difficulty: 3, difficulty8: true, format: "porte",
    prompt: "Due interruttori sono montati IN SERIE, uno dopo l'altro sullo stesso filo. Segna in quali casi la lampada si accende.",
    ingressi: ["interruttore 1", "interruttore 2"],
    condizione: "la corrente passa solo se il filo è chiuso in tutti e due i punti",
    righe: [
      { id: "r1", a: false, b: false, label: "tutti e due aperti" },
      { id: "r2", a: true, b: false, label: "chiuso il primo, aperto il secondo" },
      { id: "r3", a: false, b: true, label: "aperto il primo, chiuso il secondo" },
      { id: "r4", a: true, b: true, label: "tutti e due chiusi" },
    ],
    soluzione: { r1: false, r2: false, r3: false, r4: true },
    explanation: "In serie la corrente ha una strada sola: un interruttore aperto la interrompe, e non importa quale. Guarda la tavola che hai appena riempito — è la porta AND, e l'hai costruita con due interruttori e un filo. Le porte logiche non sono un'astrazione della matematica: sono la descrizione di come si comportano i circuiti." },

  { topic: "serie-parallelo", difficulty: 6, difficulty8: true, format: "porte",
    prompt: "Adesso i due interruttori sono IN PARALLELO: due strade diverse che portano alla stessa lampada. Segna in quali casi si accende.",
    ingressi: ["ramo di destra", "ramo di sinistra"],
    condizione: "basta che una delle due strade sia chiusa",
    righe: [
      { id: "r1", a: false, b: false, label: "tutti e due aperti" },
      { id: "r2", a: true, b: false, label: "chiuso solo quello di destra" },
      { id: "r3", a: false, b: true, label: "chiuso solo quello di sinistra" },
      { id: "r4", a: true, b: true, label: "tutti e due chiusi" },
    ],
    soluzione: { r1: false, r2: true, r3: true, r4: true },
    explanation: "In parallelo le strade sono due e ne basta una: è la porta OR, ed è anche il motivo per cui la luce delle scale si accende da due punti diversi. Confronta questa tavola con quella degli interruttori in serie — stessi due interruttori, stessa lampada, e tre casi su quattro rovesciati solo per come sono collegati." },

  // ==================================== la catena di stadi: machine_path con
  // dentro un segnale invece di un numero astratto

  { topic: "misure-elettriche", difficulty: 4, difficulty8: true, format: "machine_path",
    prompt: "Il segnale entra nel banco a 24 e deve arrivare al sensore a 3. Monta tre stadi in fila.",
    start: 24, target: 3, slotCount: 3,
    machines: [
      { id: "meta", op: "divide", value: 2, label: "stadio che dimezza" },
      { id: "terzo", op: "divide", value: 3, label: "stadio che divide per 3" },
      { id: "x2", op: "multiply", value: 2, label: "stadio che raddoppia" },
      { id: "m6", op: "subtract", value: 6, label: "stadio che toglie 6" },
    ],
    solution: ["meta", "meta", "meta"],
    explanation: "Ventiquattro dimezzato tre volte fa tre. Lo stesso stadio montato più volte non è una scorciatoia: è come funziona davvero una catena di attenuatori uguali, e ogni stadio lavora su quello che gli arriva, non sul segnale di partenza. Prova anche 24, diviso 3, poi dimezzato due volte: arriva a 2, e la differenza è tutta nell'ordine." },

  { topic: "elettricita-base", difficulty: 7, difficulty8: true, format: "machine_path",
    prompt: "Il segnale entra a 18 e deve uscire a 5. Quattro stadi, e gli stadi che dividono si bloccano se il valore non è divisibile.",
    start: 18, target: 5, slotCount: 4,
    machines: [
      { id: "meta", op: "divide", value: 2, label: "stadio che dimezza" },
      { id: "terzo", op: "divide", value: 3, label: "stadio che divide per 3" },
      { id: "x2", op: "multiply", value: 2, label: "stadio che raddoppia" },
      { id: "m1", op: "subtract", value: 1, label: "stadio che toglie 1" },
      { id: "p2", op: "add", value: 2, label: "stadio che aggiunge 2" },
    ],
    solution: ["meta", "terzo", "x2", "m1"],
    explanation: "Diciotto dimezzato fa nove, diviso tre fa tre, raddoppiato fa sei, meno uno fa cinque. Dividere per tre all'inizio sembra più diretto e porta a sei, da cui cinque non si raggiunge più con gli stadi rimasti: in una catena conta l'ordine, e uno stadio che blocca non è rotto — è una condizione che non è stata rispettata." },

  // ============================================ le basi, con i gesti che ci
  // volevano: smistare e abbinare, non riconoscere un nome

  { topic: "componenti", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni componente al lavoro che fa nel circuito.",
    pairs: [
      { left: "la pila", right: "spinge la corrente nel filo" },
      { left: "l'interruttore", right: "apre o chiude la strada" },
      { left: "la resistenza", right: "frena il passaggio e si scalda" },
      { left: "la lampada", right: "trasforma il passaggio in luce" },
    ],
    explanation: "Ogni componente fa una cosa sola e la fa sempre: la pila non decide quanta corrente passa, la spinge e basta — quanta ne passa lo decide quello che trova lungo la strada. Tenere separati «chi spinge» e «chi frena» è ciò che permette di prevedere un circuito prima di montarlo." },

  { topic: "conduttori", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni materiale secondo che cosa fa alla corrente.",
    items: ["il filo di rame", "il manico di gomma", "la moneta", "il legno asciutto"],
    categories: ["la lascia passare", "la blocca"],
    assignments: {
      "il filo di rame": "la lascia passare",
      "il manico di gomma": "la blocca",
      "la moneta": "la lascia passare",
      "il legno asciutto": "la blocca",
    },
    explanation: "Quasi tutti i metalli conducono, quasi tutto il resto no: dentro un metallo ci sono cariche libere di muoversi, nel legno e nella gomma no. «Asciutto» però è una parola importante — il legno bagnato conduce, e l'acqua è il motivo per cui gli attrezzi hanno il manico di gomma." },

  { topic: "guasti", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "La lampada del corridoio non si accende. Metti in ordine i passi per trovare il guasto senza smontare tutto.",
    items: ["controlla il filo tratto per tratto", "guarda se l'interruttore è chiuso", "prova la lampada su un altro portalampada", "verifica che la pila abbia ancora carica"],
    correctOrder: ["guarda se l'interruttore è chiuso", "verifica che la pila abbia ancora carica", "prova la lampada su un altro portalampada", "controlla il filo tratto per tratto"],
    explanation: "Si parte da quello che costa meno controllare e si finisce con quello che costa di più: guardare un interruttore è gratis, controllare il filo tratto per tratto è l'ultima cosa. È lo stesso metodo che si usa per qualunque guasto — non il pezzo più sospetto per primo, ma il controllo più facile." },

  { topic: "sicurezza-elettrica", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Smista ogni gesto secondo che cosa cambia del rischio.",
    items: ["staccare la spina prima di aprire l'apparecchio", "asciugarsi le mani prima di toccare un interruttore", "sostituire un fusibile con uno più robusto", "usare un cacciavite con il manico isolato"],
    categories: ["riduce il rischio", "lo aumenta"],
    assignments: {
      "staccare la spina prima di aprire l'apparecchio": "riduce il rischio",
      "asciugarsi le mani prima di toccare un interruttore": "riduce il rischio",
      "sostituire un fusibile con uno più robusto": "lo aumenta",
      "usare un cacciavite con il manico isolato": "riduce il rischio",
    },
    explanation: "Il fusibile più robusto è quello che inganna: sembra una riparazione e toglie esattamente la protezione per cui il fusibile esiste. È un pezzo di filo studiato per fondersi prima degli altri — sostituirlo con uno che regge di più significa che a fondersi sarà qualcos'altro." },

  { topic: "serie-parallelo", difficulty: 5, difficulty8: true, format: "ordering",
    prompt: "Devi calcolare la resistenza totale di due resistenze in serie e poi la corrente. Metti in ordine i passi.",
    items: ["dividi la tensione della pila per la resistenza totale", "somma le due resistenze", "leggi il valore di ciascuna resistenza", "controlla che la corrente trovata sia ragionevole"],
    correctOrder: ["leggi il valore di ciascuna resistenza", "somma le due resistenze", "dividi la tensione della pila per la resistenza totale", "controlla che la corrente trovata sia ragionevole"],
    explanation: "In serie le resistenze si sommano, e solo dopo si può usare la legge di Ohm: dividere prima di sommare dà la corrente di un circuito che non hai montato. L'ultimo passo non è una formalità — un risultato di cento ampere da una pila da nove volt dice che da qualche parte c'è un errore di conto." },

  { topic: "misure-elettriche", difficulty: 5, difficulty8: true, format: "matching",
    prompt: "Abbina ogni strumento a quello che misura e a come va collegato.",
    pairs: [
      { left: "il voltmetro", right: "la tensione, collegato ai due capi" },
      { left: "l'amperometro", right: "la corrente, inserito nella maglia" },
      { left: "l'ohmetro", right: "la resistenza, con il circuito spento" },
      { left: "la pinza amperometrica", right: "la corrente, senza toccare il filo" },
    ],
    explanation: "Il collegamento non è un dettaglio: il voltmetro va in parallelo perché la tensione è una differenza fra due punti, l'amperometro in serie perché deve farsi attraversare da quello che misura. Scambiarli non dà una misura sbagliata, di solito rompe qualcosa." },

  { topic: "circuito", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Una lampadina su quattro si fulmina. Smista che cosa succede alle altre tre, secondo come sono collegate.",
    items: ["quattro lampade in serie, una si fulmina", "quattro lampade in parallelo, una si fulmina", "quattro lampade in serie, una si allenta nel portalampada", "quattro lampade in parallelo, si stacca il filo comune"],
    categories: ["le altre restano accese", "si spengono tutte"],
    assignments: {
      "quattro lampade in serie, una si fulmina": "si spengono tutte",
      "quattro lampade in parallelo, una si fulmina": "le altre restano accese",
      "quattro lampade in serie, una si allenta nel portalampada": "si spengono tutte",
      "quattro lampade in parallelo, si stacca il filo comune": "si spengono tutte",
    },
    explanation: "In serie qualunque interruzione ferma tutto, e allentare una lampadina interrompe quanto fulminarla. In parallelo ogni ramo è indipendente — ma il filo comune non è un ramo: è la strada che portano tutti, e staccarlo spegne l'impianto intero. La domanda giusta non è «serie o parallelo» ma «dove si è aperto il giro»." },

  { topic: "elettricita-base", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine queste quattro correnti, dalla più piccola alla più grande.",
    items: ["il fulmine di un temporale", "il LED di una spia", "il fornello elettrico", "la lampadina di una torcia"],
    correctOrder: ["il LED di una spia", "la lampadina di una torcia", "il fornello elettrico", "il fulmine di un temporale"],
    explanation: "Fra un LED e un fulmine ci sono nove ordini di grandezza: qualche millesimo di ampere contro decine di migliaia. Avere in testa la scala serve più di ricordare un numero — quando un conto dà cento ampere per una torcia, è la scala a dire che c'è un errore prima ancora di rifare il calcolo." },

  // =========================== due risposte libere, perché ogni lotto porta
  // con sé la sua quota: gli item da toccare contano nel totale e non fra i
  // liberi, e senza queste il banco scenderebbe sotto il 20%.

  { topic: "serie-parallelo", difficulty: 3, difficulty8: true, format: "short_answer",
    prompt: "Due resistenze da 10 ohm sono in serie. Quanto vale la resistenza totale, in ohm?",
    answer: "20", accept: ["20 ohm", "venti"],
    explanation: "In serie si sommano, perché la corrente deve attraversarle tutte e due una dopo l'altra: la strada diventa più lunga e più difficile. In parallelo sarebbe il contrario — due strade uguali dimezzano, e farebbe cinque." },

  { topic: "componenti", difficulty: 4, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il componente che si oppone al passaggio della corrente e per questo si scalda?",
    answer: "resistenza", accept: ["la resistenza", "resistore", "il resistore"],
    explanation: "Il suo lavoro è proprio frenare: l'energia che la corrente perde attraversandola non sparisce, diventa calore. È un guasto quando succede in un filo e un mestiere quando succede in un fornello — stesso fenomeno, intenzione diversa." },

  { topic: "guasti", difficulty: 6, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il componente che si fonde apposta per interrompere il circuito quando la corrente è troppo alta?",
    answer: "fusibile", accept: ["il fusibile", "un fusibile"],
    explanation: "È un tratto di filo scelto per cedere prima degli altri: si sacrifica per salvare il resto dell'impianto. Per questo si sostituisce con uno identico e mai con uno più robusto — un fusibile che non si fonde non protegge niente." },
];
