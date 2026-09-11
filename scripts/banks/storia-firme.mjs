// Storia — le firme, primo lotto. 11 settembre 2026.
//
// ## La linea del tempo esisteva e non era mai stata scritta
//
// `timeline` è disponibile per storia dal mondo 1 ed è uno dei dieci formati
// manipolativi: collocare un evento su una scala è un gesto di posizione, non un
// riconoscimento. Ma tutte le linee del tempo giocate finora erano **generate**,
// e il banco di storia non ne conteneva nemmeno una.
//
// È la firma naturale della materia. Il vincolo dichiarato — *nessuna domanda di
// nome o di data senza una tavola su cui impararla* — qui non si aggira: si
// risolve, perché **la linea del tempo È la tavola**. Gli eventi portano l'anno
// scritto accanto, e collocarli è il modo in cui quell'anno si impara.
//
// ## Dove vanno questi item, e perché
//
// Storia aveva ventuno prove manipolative, **tutte concentrate alle fasce 2 e
// 8**: il centro della scala — dalla 3 alla 7, cioè i mondi dal 7 al 21 — non ne
// aveva nessuna. Un bambino che attraversava metà campagna non toccava mai
// niente in storia. Questo lotto sta tutto lì in mezzo, e le tre linee del tempo
// crescono con lui: prima la scala lunga dalla preistoria al Medioevo, poi Roma
// sola, poi il Medioevo solo.
//
// ## Il contratto, e la trappola
//
// `_validate_timeline` vuole da due a sei eventi, valori dentro la scala, e una
// `answer` che sia uno degli id. La trappola è la **separazione minima**: due
// eventi più vicini del 2% della scala si sovrappongono sotto un dito e la
// guardia li rifiuta. La prima stesura della linea di Roma metteva Cesare (44
// a.C.) e l'inizio dell'impero (27 a.C.) a tredici millesimi di distanza: sono
// due eventi diversi per la storia e lo stesso punto per uno schermo. Cesare è
// uscito, e non è una perdita — su una scala di milletrecento anni quei diciassette
// anni non si vedono, ed è esattamente quello che la scala deve insegnare.

export const STORIA_FIRME = [

  // ================================================ le linee del tempo

  { topic: "cronologia", difficulty: 3, difficulty8: true, format: "timeline",
    prompt: "La linea va dal 3500 a.C. al 1500 d.C. Colloca gli eventi, poi indica quello che si prende come inizio del Medioevo.",
    min: -3500, max: 1500,
    targets: [
      { id: "-3200", label: "nasce la scrittura · 3200 a.C.", value: -3200 },
      { id: "-2500", label: "le grandi piramidi · 2500 a.C.", value: -2500 },
      { id: "-753", label: "fondazione di Roma · 753 a.C.", value: -753 },
      { id: "476", label: "cade l'Impero d'Occidente · 476 d.C.", value: 476 },
      { id: "1096", label: "la prima crociata · 1096", value: 1096 },
    ],
    answer: "476",
    explanation: "Guarda dove cadono i punti: fra la scrittura e la fondazione di Roma passa più tempo che fra Roma e noi. La storia antica non è «tutta insieme all'inizio» — è la parte più lunga di tutte, e sembra corta solo perché ne sappiamo meno. Le date di confine come il 476 sono comode, non esatte: nessuno quel mattino si è svegliato nel Medioevo." },

  { topic: "roma", difficulty: 5, difficulty8: true, format: "timeline",
    prompt: "La linea di Roma, dall'800 a.C. al 500 d.C. Colloca i quattro momenti, poi indica quando Roma smette di avere un re.",
    min: -800, max: 500,
    targets: [
      { id: "-753", label: "fondazione e re · 753 a.C.", value: -753 },
      { id: "-509", label: "nasce la repubblica · 509 a.C.", value: -509 },
      { id: "-27", label: "comincia l'impero · 27 a.C.", value: -27 },
      { id: "476", label: "cade l'Impero d'Occidente · 476 d.C.", value: 476 },
    ],
    answer: "-509",
    explanation: "La repubblica dura quasi cinque secoli, l'impero d'Occidente cinque: sulla linea si vede che nessuna delle due è una parentesi. E si vede anche che fra la cacciata del re e il primo imperatore passa più tempo di quanto ne separi noi da Cristoforo Colombo — la repubblica non fu un passaggio, fu quasi tutta la storia di Roma." },

  { topic: "medioevo", difficulty: 7, difficulty8: true, format: "timeline",
    prompt: "La linea del Medioevo, dal 400 al 1500. Colloca gli eventi, poi indica l'incoronazione che rimette insieme mezza Europa.",
    min: 400, max: 1500,
    targets: [
      { id: "476", label: "cade l'Impero d'Occidente · 476", value: 476 },
      { id: "800", label: "Carlo Magno imperatore · 800", value: 800 },
      { id: "1096", label: "la prima crociata · 1096", value: 1096 },
      { id: "1200", label: "i Comuni italiani · intorno al 1200", value: 1200 },
      { id: "1492", label: "Colombo raggiunge l'America · 1492", value: 1492 },
    ],
    answer: "800",
    explanation: "Mille anni, e i primi trecento sono quasi vuoti su questa linea: è la parte che si chiamava «secoli bui», e il nome dice più su chi l'ha inventato che su quei secoli. Guarda invece l'ultima metà — crociate, Comuni, università, e infine le navi: il Medioevo finisce in pieno movimento, non spegnendosi." },

  // ============================ il centro della scala, che non aveva niente
  // da toccare

  { topic: "fonti", difficulty: 3, difficulty8: true, format: "matching",
    prompt: "Abbina ogni domanda dello storico alla fonte che può rispondere.",
    pairs: [
      { left: "che cosa mangiavano i contadini?", right: "i resti nelle discariche e nei pozzi" },
      { left: "quanto costava il grano?", right: "i registri del mercato" },
      { left: "che cosa pensava di sé un re?", right: "le iscrizioni che ha fatto incidere" },
      { left: "quanti anni si viveva?", right: "le ossa nelle sepolture" },
    ],
    explanation: "La fonte giusta dipende dalla domanda, e quasi mai è quella che sembra: per sapere che cosa mangiava la gente comune servono i rifiuti, non le cronache, perché nessuno scriveva la lista della spesa. Le fonti più utili sono spesso quelle che nessuno aveva l'intenzione di lasciare." },

  { topic: "grecia", difficulty: 4, difficulty8: true, format: "classification",
    prompt: "Nell'Atene del quinto secolo, smista chi poteva votare nell'assemblea e chi no.",
    items: ["un cittadino ateniese adulto", "una donna ateniese", "un mercante venuto da Corinto", "uno schiavo nato in città"],
    categories: ["poteva votare", "non poteva votare"],
    assignments: {
      "un cittadino ateniese adulto": "poteva votare",
      "una donna ateniese": "non poteva votare",
      "un mercante venuto da Corinto": "non poteva votare",
      "uno schiavo nato in città": "non poteva votare",
    },
    explanation: "La prima democrazia della storia escludeva la grande maggioranza di chi viveva ad Atene: donne, stranieri e schiavi, forse quattro persone su cinque. Non toglie niente all'invenzione — decidere votando invece che obbedendo era nuovo — ma va detto, perché «democrazia» ha cambiato significato molte volte prima di arrivare a noi." },

  { topic: "egizi", difficulty: 4, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine le fasi dell'anno agricolo egizio, come lo scandiva il Nilo.",
    items: ["si semina sul limo lasciato dall'acqua", "il fiume si ritira", "il Nilo straripa e copre i campi", "si raccoglie prima del caldo peggiore"],
    correctOrder: ["il Nilo straripa e copre i campi", "il fiume si ritira", "si semina sul limo lasciato dall'acqua", "si raccoglie prima del caldo peggiore"],
    explanation: "L'anno egizio aveva tre stagioni e non quattro, e le decideva il fiume: inondazione, semina, raccolto. È il motivo per cui in Egitto nasce un calendario preciso prima che altrove — non per curiosità astronomica, ma perché sbagliare di due settimane la semina significava non mangiare." },

  { topic: "metodo", difficulty: 4, difficulty8: true, format: "matching",
    prompt: "Abbina ogni problema di una fonte al modo in cui lo storico lo affronta.",
    pairs: [
      { left: "il cronista era pagato dal re", right: "si cerca un racconto scritto da un'altra parte" },
      { left: "il documento è incompleto", right: "si dice che cosa manca invece di riempirlo" },
      { left: "la data è scritta in un altro calendario", right: "si converte prima di confrontarla" },
      { left: "il testo è una copia di una copia", right: "si confrontano le copie e si cercano gli errori ripetuti" },
    ],
    explanation: "Nessuno di questi problemi rende la fonte inutilizzabile: li rende dichiarabili. La differenza fra una ricostruzione seria e una inventata non è che la prima abbia fonti perfette — è che dice quali sono i buchi invece di coprirli con una frase che suona bene." },

  { topic: "fonti", difficulty: 4, difficulty8: true, format: "ordering",
    prompt: "È stata trovata una moneta antica in uno scavo. Metti in ordine i passi per capire che cosa racconta.",
    items: ["confrontala con le monete già note", "guarda dove esattamente è stata trovata", "leggi che cosa c'è inciso sopra", "prova a dire che cosa dimostra, e che cosa no"],
    correctOrder: ["guarda dove esattamente è stata trovata", "leggi che cosa c'è inciso sopra", "confrontala con le monete già note", "prova a dire che cosa dimostra, e che cosa no"],
    explanation: "Il posto viene prima dell'oggetto: una moneta romana trovata in Scozia dice qualcosa che la stessa moneta trovata a Roma non direbbe. Gli archeologi registrano la posizione al centimetro proprio per questo — e un reperto comprato al mercato, di cui non si sa dove stava, ha perso quasi tutto quello che poteva raccontare." },

  { topic: "roma", difficulty: 4, difficulty8: true, format: "numeric_input",
    prompt: "La repubblica romana comincia nel 509 a.C. e finisce nel 27 a.C. Quanti anni è durata?",
    answer: "482",
    explanation: "Fra due date prima di Cristo si sottrae, perché si contano all'indietro verso lo zero: 509 meno 27. Quasi cinque secoli, più di quanto sia durato l'impero d'Occidente — e più del tempo che separa noi dalla scoperta dell'America." },

  { topic: "cronologia", difficulty: 5, difficulty8: true, format: "matching",
    prompt: "Abbina ogni modo di contare il tempo a quello che serviva a fare.",
    pairs: [
      { left: "le stagioni del Nilo", right: "sapere quando seminare" },
      { left: "gli anni dalla fondazione di Roma", right: "datare gli atti dello Stato" },
      { left: "le Olimpiadi ogni quattro anni", right: "mettere in ordine i fatti fra città diverse" },
      { left: "gli anni prima e dopo Cristo", right: "avere una scala unica per tutti" },
    ],
    explanation: "Ogni calendario nasce da un bisogno pratico, e nessuno è più «vero» degli altri: contare dalle Olimpiadi funzionava perché tutte le città greche le conoscevano. La scala che usiamo oggi è stata scelta nel Medioevo e ha vinto perché è comoda, non perché sia naturale — infatti mezzo mondo ne usa anche un'altra." },

  { topic: "roma", difficulty: 6, difficulty8: true, format: "classification",
    prompt: "Smista ogni fatto secondo se abbia rafforzato o indebolito la repubblica romana.",
    items: ["i tribuni della plebe ottengono il diritto di veto", "gli eserciti diventano fedeli al comandante che li paga", "le cariche durano un anno e sono in due", "un generale entra in città con le sue legioni"],
    categories: ["la rafforza", "la indebolisce"],
    assignments: {
      "i tribuni della plebe ottengono il diritto di veto": "la rafforza",
      "gli eserciti diventano fedeli al comandante che li paga": "la indebolisce",
      "le cariche durano un anno e sono in due": "la rafforza",
      "un generale entra in città con le sue legioni": "la indebolisce",
    },
    explanation: "Tutte le regole della repubblica servono a impedire che uno solo comandi: due consoli, un anno di mandato, un veto in mano al popolo. Cadono tutte insieme quando l'esercito smette di obbedire allo Stato e comincia a obbedire a chi lo paga — da lì la guerra civile non è un incidente, è l'esito." },

  { topic: "medioevo", difficulty: 6, difficulty8: true, format: "numeric_input",
    prompt: "Si fa durare il Medioevo dal 476 al 1492. Quanti secoli sono, arrotondando?",
    answer: "10",
    explanation: "Poco più di mille anni, cioè dieci secoli: un quinto di tutta la storia scritta, liquidato in scuola in poche settimane. È il periodo più lungo che abbia un nome solo — e infatti gli storici lo dividono in alto e basso Medioevo, perché il mondo del 600 e quello del 1400 non si somigliano per niente." },

  { topic: "cronologia", difficulty: 7, difficulty8: true, format: "classification",
    prompt: "Smista ogni affermazione secondo che cosa è: una data che si può verificare o una convenzione che qualcuno ha scelto.",
    items: ["il Vesuvio seppellisce Pompei nel 79 d.C.", "il Medioevo comincia nel 476", "Colombo sbarca il 12 ottobre 1492", "l'età moderna comincia nel 1492"],
    categories: ["un fatto databile", "un confine deciso dagli storici"],
    assignments: {
      "il Vesuvio seppellisce Pompei nel 79 d.C.": "un fatto databile",
      "il Medioevo comincia nel 476": "un confine deciso dagli storici",
      "Colombo sbarca il 12 ottobre 1492": "un fatto databile",
      "l'età moderna comincia nel 1492": "un confine deciso dagli storici",
    },
    explanation: "Un'eruzione ha un giorno, un'epoca no: i confini fra le età sono decisioni prese secoli dopo, per poter parlare di grandi periodi senza rifare ogni volta l'elenco. Sono utili e sono arbitrari — in Inghilterra il Medioevo si fa finire nel 1485, e non è che lì il tempo scorresse diverso." },

  { topic: "grecia", difficulty: 3, difficulty8: true, format: "numeric_input",
    prompt: "Le Olimpiadi antiche si tenevano ogni quattro anni. Quante se ne celebravano in un secolo?",
    answer: "25",
    explanation: "Venticinque, e i Greci le usavano come calendario: «nel terzo anno della novantesima Olimpiade» era una data che capivano tutte le città, anche quelle in guerra fra loro. Contare il tempo con qualcosa che si ripete è più antico che contarlo dalla nascita di qualcuno." },
];
