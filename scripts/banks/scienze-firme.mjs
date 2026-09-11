// Scienze — le firme, primo lotto. 11 settembre 2026.
//
// ## La firma c'era e non era mai stata scritta a mano
//
// `mystery_sample` è registrato come formato di scienze e fisica dal 1 settembre,
// con peso 34 — la dichiarazione, nel codice, che l'indagine di laboratorio è il
// modo in cui questa disciplina si fa. Ma fino a oggi ogni campione misterioso
// era **generato**: il banco non sapeva portare il formato, quindi nessuno ne
// aveva mai scritto uno scegliendo i materiali e le prove.
//
// È il gesto giusto, ed è quello che distingue le scienze da un elenco di
// nozioni: **prima si producono le prove, poi si dà un nome.** Il bambino sceglie
// quali esperimenti fare, osserva le reazioni di un materiale nascosto e solo
// dopo formula l'ipotesi.
//
// ## Il contratto, e la cosa che il validatore NON controlla
//
// `ExerciseInteraction._validate_mystery_sample` vuole da tre a cinque
// materiali, da tre a quattro prove, e per ogni coppia materiale×prova una
// osservazione scritta. Controlla che **non esistano due materiali con la stessa
// impronta**, cioè che le prove tutte insieme bastino a distinguerli: due
// materiali che reagiscono uguale renderebbero il mistero irrisolvibile.
//
// Quello che NON controlla, e che è il vero lavoro di chi scrive: **che nessuna
// prova SOLA basti a chiudere il caso.** Se l'acqua separa già il campione da
// tutti gli altri, l'indagine finisce alla prima mossa e la lezione — servono
// più prove indipendenti — non viene mai imparata. Le due indagini qui sotto
// sono costruite perché la prima prova lasci sempre almeno un dubbio, ed è per
// questo che `minTests` non è mai uno.
//
// Le osservazioni sono quelle vere: lo zucchero sulla fiamma annerisce e profuma
// di caramello, il marmo nell'aceto fa bollicine, la limatura di ferro salta
// verso la calamita. Un'osservazione inventata insegnerebbe a fidarsi di un
// laboratorio che non esiste.

export const SCIENZE_FIRME = [

  // ============================== l'indagine: prima le prove, poi il nome

  { topic: "materia", difficulty: 4, difficulty8: true, format: "mystery_sample",
    prompt: "Nel cassetto del laboratorio c'è una polvere bianca senza etichetta. Fai gli esperimenti che ti servono, poi dì che cos'è.",
    samples: [
      { id: "zucchero", name: "zucchero" },
      { id: "sale", name: "sale da cucina" },
      { id: "marmo", name: "polvere di marmo" },
      { id: "ferro", name: "limatura di ferro" },
    ],
    tests: [
      { id: "acqua", label: "mettine un cucchiaino in acqua" },
      { id: "calamita", label: "avvicina una calamita" },
      { id: "aceto", label: "versaci sopra dell'aceto" },
      { id: "fiamma", label: "scaldala sulla piastra" },
    ],
    results: {
      zucchero: {
        acqua: "sparisce, l'acqua resta limpida",
        calamita: "non succede niente",
        aceto: "nessuna reazione",
        fiamma: "fonde, diventa scura e profuma di caramello",
      },
      sale: {
        acqua: "sparisce, l'acqua resta limpida",
        calamita: "non succede niente",
        aceto: "nessuna reazione",
        fiamma: "non cambia, resta bianca",
      },
      marmo: {
        acqua: "resta sul fondo senza sciogliersi",
        calamita: "non succede niente",
        aceto: "bollicine vivaci, schiuma subito",
        fiamma: "non cambia, resta bianca",
      },
      ferro: {
        acqua: "resta sul fondo senza sciogliersi",
        calamita: "i granelli saltano verso la calamita",
        aceto: "nessuna reazione visibile",
        fiamma: "non cambia colore",
      },
    },
    minTests: 2,
    answer: "sale",
    explanation: "Il sale è l'unico che nessuna prova nomina da sola: la calamita accusa il ferro, l'aceto il marmo, la fiamma lo zucchero, e a lui non succede mai niente di speciale. Ci si arriva solo per esclusione, con almeno due prove che dividano in modi diversi — l'acqua lo mette insieme allo zucchero, la fiamma lo separa. È il caso più istruttivo: a volte l'identità non ha una firma propria, ed è quello che resta quando tutto il resto è stato escluso." },

  { topic: "metodo", difficulty: 7, difficulty8: true, format: "mystery_sample",
    prompt: "Cinque bottiglie identiche, tutte con dentro un liquido trasparente. Scegli le prove, osserva, e poi dì quale hai in mano.",
    samples: [
      { id: "acqua", name: "acqua distillata" },
      { id: "aceto", name: "aceto bianco" },
      { id: "bicarbonato", name: "acqua e bicarbonato" },
      { id: "salata", name: "acqua salata" },
      { id: "limone", name: "succo di limone filtrato" },
    ],
    tests: [
      { id: "cartina", label: "immergi una cartina indicatrice" },
      { id: "corrente", label: "prova se conduce la corrente" },
      { id: "bicarb", label: "aggiungi un pizzico di bicarbonato" },
      { id: "evapora", label: "lasciane evaporare qualche goccia" },
    ],
    results: {
      acqua: {
        cartina: "la cartina resta verde: né acido né base",
        corrente: "la lampadina non si accende",
        bicarb: "il bicarbonato si deposita e basta",
        evapora: "non resta niente sul vetrino",
      },
      aceto: {
        cartina: "la cartina diventa rossa: è acido",
        corrente: "la lampadina si accende debolmente",
        bicarb: "bollicine subito, molto vivaci",
        evapora: "non resta niente sul vetrino",
      },
      bicarbonato: {
        cartina: "la cartina diventa blu: è una base",
        corrente: "la lampadina si accende",
        bicarb: "il bicarbonato si deposita e basta",
        evapora: "resta una velatura bianca e polverosa",
      },
      salata: {
        cartina: "la cartina resta verde: né acido né base",
        corrente: "la lampadina si accende forte",
        bicarb: "il bicarbonato si deposita e basta",
        evapora: "restano cristallini a spigoli vivi",
      },
      limone: {
        cartina: "la cartina diventa rossa: è acido",
        corrente: "la lampadina si accende debolmente",
        bicarb: "bollicine subito, molto vivaci",
        evapora: "resta una macchia appiccicosa e giallina",
      },
    },
    minTests: 2,
    answer: "aceto",
    explanation: "Aceto e limone si comportano identici a tre prove su quattro: tutti e due acidi, tutti e due conduttori deboli, tutti e due frizzanti col bicarbonato. Solo l'evaporazione li separa — il limone lascia una macchia appiccicosa, l'aceto se ne va senza lasciare niente, come l'acqua. È la situazione più istruttiva di tutte: quando due ipotesi resistono alle stesse prove non vuol dire che una sia giusta, vuol dire che serve una prova costruita apposta per distinguerle." },

  // ====================================== il metodo, con i gesti che ci vogliono

  { topic: "metodo", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Vuoi scoprire se le piante crescono di più con la luce accesa. Smista ogni cosa secondo il ruolo che ha nell'esperimento.",
    items: ["le ore di luce al giorno", "l'altezza della pianta dopo due settimane", "la quantità d'acqua data a ogni vaso", "il tipo di terriccio nei vasi"],
    categories: ["quello che cambio apposta", "quello che misuro", "quello che tengo uguale"],
    assignments: {
      "le ore di luce al giorno": "quello che cambio apposta",
      "l'altezza della pianta dopo due settimane": "quello che misuro",
      "la quantità d'acqua data a ogni vaso": "quello che tengo uguale",
      "il tipo di terriccio nei vasi": "quello che tengo uguale",
    },
    explanation: "Si cambia una cosa sola, si misura una cosa sola, e tutto il resto si tiene fermo: se cambi luce e acqua insieme e le piante crescono, non sai a chi dire grazie. Le cose tenute uguali non sono un dettaglio noioso — sono quello che rende l'esperimento capace di rispondere." },

  { topic: "metodo", difficulty: 5, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passi di un esperimento che possa davvero rispondere a una domanda.",
    items: ["misura e scrivi quello che è successo", "prepara due gruppi uguali e cambia una cosa sola", "scrivi che cosa ti aspetti che succeda, e perché", "confronta il risultato con quello che ti aspettavi"],
    correctOrder: ["scrivi che cosa ti aspetti che succeda, e perché", "prepara due gruppi uguali e cambia una cosa sola", "misura e scrivi quello che è successo", "confronta il risultato con quello che ti aspettavi"],
    explanation: "La previsione va scritta PRIMA, e questo è tutto il metodo: dopo aver visto il risultato è facilissimo convincersi di averlo previsto, e succede a tutti. Una previsione messa nero su bianco prima è l'unica che possa essere smentita — e solo quello che può essere smentito insegna qualcosa." },

  // =============================================== le basi, da toccare

  { topic: "corpo", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni organo al lavoro che fa.",
    pairs: [
      { left: "i polmoni", right: "prendono ossigeno dall'aria" },
      { left: "il cuore", right: "spinge il sangue in tutto il corpo" },
      { left: "lo stomaco", right: "comincia a smontare il cibo" },
      { left: "i reni", right: "ripuliscono il sangue da quello che avanza" },
    ],
    explanation: "Nessuno di questi lavora da solo: i polmoni prendono l'ossigeno ma è il cuore a portarlo dove serve, e lo stomaco smonta il cibo che poi il sangue distribuisce. Il corpo è fatto di mestieri che si passano il lavoro, e per questo un guasto in un posto si sente da un'altra parte." },

  { topic: "viventi", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni cosa secondo che sia viva o no.",
    items: ["un seme nel cassetto", "un cristallo che cresce nell'acqua salata", "il lievito nella farina", "una fiamma che si allarga"],
    categories: ["è vivo", "non è vivo"],
    assignments: {
      "un seme nel cassetto": "è vivo",
      "un cristallo che cresce nell'acqua salata": "non è vivo",
      "il lievito nella farina": "è vivo",
      "una fiamma che si allarga": "non è vivo",
    },
    explanation: "Crescere e muoversi non bastano: anche un cristallo cresce e una fiamma si allarga e consuma. Quello che serve è l'insieme — nutrirsi, rispondere all'ambiente, riprodursi — e il seme sembra inerte ma ha tutto pronto, mentre il cristallo non avrà mai un figlio." },

  { topic: "terra-universo", difficulty: 3, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine questi corpi celesti, dal più piccolo al più grande.",
    items: ["il Sole", "la Luna", "la Terra", "Giove"],
    correctOrder: ["la Luna", "la Terra", "Giove", "il Sole"],
    explanation: "Le distanze fra questi numeri sono enormi: nel Sole ci starebbero più di un milione di Terre, e in Giove più di mille. I disegni dei libri li mettono vicini e della stessa misura per farceli stare nella pagina, ed è il motivo per cui quasi tutti se li immaginano più simili di quanto sono." },

  { topic: "energia", difficulty: 3, difficulty8: true, format: "matching",
    prompt: "Abbina ogni oggetto alla trasformazione di energia che fa.",
    pairs: [
      { left: "la lampadina", right: "da elettrica a luce e calore" },
      { left: "il pannello solare", right: "da luce a elettrica" },
      { left: "l'altoparlante", right: "da elettrica a suono" },
      { left: "la dinamo della bicicletta", right: "da movimento a elettrica" },
    ],
    explanation: "L'energia non si crea e non si distrugge: cambia forma, e ogni oggetto di questo elenco è una macchina per cambiarla. Nota che quasi tutte producono anche calore senza volerlo — è la parte che si perde, e nessuna macchina riesce a non perderne affatto." },

  { topic: "ecosistema", difficulty: 6, difficulty8: true, format: "classification",
    prompt: "Smista ogni essere vivente secondo il posto che occupa nel giro dell'energia.",
    items: ["il muschio sul tronco", "il capriolo", "la lince", "i funghi sul legno marcio"],
    categories: ["produce il proprio cibo", "mangia altri viventi", "smonta quello che resta"],
    assignments: {
      "il muschio sul tronco": "produce il proprio cibo",
      "il capriolo": "mangia altri viventi",
      "la lince": "mangia altri viventi",
      "i funghi sul legno marcio": "smonta quello che resta",
    },
    explanation: "Il terzo gruppo è quello che si dimentica sempre, ed è quello senza cui tutto si ferma: senza chi smonta, le sostanze resterebbero chiuse dentro i corpi morti e le piante non avrebbero più niente da cui ripartire. Il giro si chiude lì, non dal predatore." },

  { topic: "ambiente", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passaggi dell'energia in un prato, da dove entra a dove finisce.",
    items: ["il falco caccia la volpe ferita", "l'erba cattura la luce del sole", "la volpe mangia il coniglio", "il coniglio bruca l'erba"],
    correctOrder: ["l'erba cattura la luce del sole", "il coniglio bruca l'erba", "la volpe mangia il coniglio", "il falco caccia la volpe ferita"],
    explanation: "A ogni passaggio si perde circa il novanta per cento dell'energia in calore, e per questo le catene alimentari sono corte: non esistono predatori al sesto livello, perché non resterebbe abbastanza da mangiare. Serve un prato intero per mantenere un falco." },

  { topic: "materia", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni passaggio di stato al suo nome.",
    pairs: [
      { left: "dal solido al liquido", right: "fusione" },
      { left: "dal liquido al gas", right: "evaporazione" },
      { left: "dal gas al liquido", right: "condensazione" },
      { left: "dal solido al gas, senza passare dal liquido", right: "sublimazione" },
    ],
    explanation: "L'ultimo esiste davvero e si vede: la neve che sparisce in una giornata secca e fredda senza mai bagnare il terreno sta sublimando. Tutti questi passaggi avvengono a temperature precise per ogni sostanza, ed è per questo che si usano per riconoscerla." },

  { topic: "energia", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama l'energia che un corpo possiede per il fatto di trovarsi in alto?",
    answer: "potenziale", accept: ["energia potenziale", "potenziale gravitazionale"],
    explanation: "È immagazzinata nella posizione: un sasso tenuto in mano non fa niente, ma lasciandolo andare quell'energia diventa movimento. Potenziale non vuol dire «possibile» — vuol dire che è già lì e aspetta soltanto di trasformarsi." },

  { topic: "ecosistema", difficulty: 4, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il gruppo di individui della stessa specie che vive nella stessa zona?",
    answer: "popolazione", accept: ["una popolazione", "la popolazione"],
    explanation: "Popolazione è una specie sola in un posto solo; più popolazioni diverse che convivono formano una comunità, e la comunità insieme all'ambiente fisico fa l'ecosistema. Sono tre parole per tre scale diverse, e confonderle rende impossibile dire di che cosa si sta parlando." },

  { topic: "ambiente", difficulty: 6, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il passaggio dell'acqua dal terreno all'aria attraverso le foglie delle piante?",
    answer: "traspirazione", accept: ["la traspirazione", "traspirazione fogliare"],
    explanation: "Una quercia adulta può mandare in aria centinaia di litri al giorno: nel ciclo dell'acqua le piante non sono comparse, sono una delle pompe principali. È anche il motivo per cui un bosco tagliato cambia le piogge della zona." },

  { topic: "terra-universo", difficulty: 2, difficulty8: true, format: "numeric_input",
    prompt: "Quanti pianeti ci sono nel Sistema Solare?",
    answer: "8",
    explanation: "Otto dal 2006, quando Plutone è stato riclassificato come pianeta nano: non era cambiato Plutone, era cambiata la definizione di pianeta. È un buon esempio di come funziona la scienza — le categorie si rivedono quando si scoprono decine di oggetti simili, e ridefinire non è ammettere un errore." },

  { topic: "corpo", difficulty: 6, difficulty8: true, format: "short_answer",
    prompt: "Come si chiamano i vasi che portano il sangue DAL cuore verso il resto del corpo?",
    answer: "arterie", accept: ["le arterie", "arteria"],
    explanation: "Arterie in andata, vene al ritorno, e il nome non dipende dal colore o dall'ossigeno ma dalla direzione: l'arteria polmonare porta sangue povero di ossigeno ed è comunque un'arteria, perché esce dal cuore." },
];
