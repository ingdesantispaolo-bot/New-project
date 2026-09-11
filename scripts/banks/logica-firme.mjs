// Logica — le firme scritte a mano, primo lotto. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Logica ha 140 item, il banco più piccolo dei dodici, e su sei argomenti soli.
// Ma ha anche due formati-firma che nessun'altra materia possiede — la griglia
// degli incroci e le porte — e fino a oggi **tutte e due erano generate**: sei
// scenari in tabella, le permutazioni degli attributi, gli indizi potati finché
// ne restava una soluzione sola. Materiale onesto, e sempre della stessa forma.
//
// Da ieri il banco sa portare `griglia` e `porte`, quindi si possono scrivere.
// Un indizio pensato non è un indizio potato: il generatore toglie finché il
// puzzle si chiude, chi scrive sceglie *quale* deduzione il bambino deve fare.
//
// ## Il contratto della griglia, che è severo e va capito prima di scrivere
//
// `ExerciseInteraction._griglia_frase_regge` rilegge gli indizi **dal loro
// testo**, perché il testo è l'unica cosa che il bambino vede. Capisce due sole
// forme:
//
//   «X non <verbo> Y»                 → nessuno dei nominati ha Y
//   «Chi <verbo> Y è X oppure Z»      → almeno uno dei nominati ha Y
//
// Da cui tre regole di scrittura che non si possono violare:
//
//  1. **un indizio nomina UN attributo solo.** Il parser prende l'ultimo che
//     trova nel testo: due attributi in una frase e l'indizio vincola l'altro.
//  2. **nessun nome può essere sottostringa di un altro**, né di un attributo.
//     «Ada» dentro «Adamo» farebbe scattare tutti e due.
//  3. **la parola «non» decide il verso.** Non esistono altri modi di negare:
//     «nessuno tranne», «mai», «escluso» non vengono capiti e l'indizio passa
//     senza vincolare niente — cioè il puzzle resta aperto e la guardia lo
//     boccia con «due soluzioni».
//
// Il validatore conta le permutazioni compatibili per forza bruta e pretende
// che ne resti **esattamente una**. Due soluzioni non sono un puzzle più
// difficile: sono un puzzle rotto, in cui il bambino ragiona bene e la verifica
// gli dice che ha sbagliato.
//
// ## Le porte
//
// Quattro righe, una per combinazione, nessuna ripetuta, e la porta non può
// essere degenere — tutte accese o tutte spente si supera premendo sempre lo
// stesso pulsante. Le tre qui sotto sono le tre che contano davvero: entrambi,
// almeno uno, e **soltanto uno dei due**, che è quella che nessuno si aspetta
// e che spiega perché «o» in italiano è ambiguo e in logica no.

export const LOGICA_FIRME = [

  // ============================================================ le porte

  { topic: "verita", difficulty: 3, difficulty8: true, format: "porte",
    prompt: "Il portello della stiva si apre solo quando tutti e due i sigilli sono accesi. Segna in quali casi si apre.",
    ingressi: ["sigillo A", "sigillo B"],
    condizione: "si apre solo se sono accesi tutti e due",
    righe: [
      { id: "r1", a: false, b: false, label: "A spento, B spento" },
      { id: "r2", a: true, b: false, label: "A acceso, B spento" },
      { id: "r3", a: false, b: true, label: "A spento, B acceso" },
      { id: "r4", a: true, b: true, label: "A acceso, B acceso" },
    ],
    soluzione: { r1: false, r2: false, r3: false, r4: true },
    explanation: "«Tutti e due» è la condizione più severa che esista: basta un sigillo spento e il portello resta chiuso, e non importa quale dei due. Su quattro casi possibili ne accende uno solo — ed è il motivo per cui una catena di «e» diventa rapidamente impossibile da soddisfare." },

  { topic: "insiemi", difficulty: 5, difficulty8: true, format: "porte",
    prompt: "L'allarme suona se c'è movimento nel corridoio oppure nella stiva, o in tutti e due. Segna in quali casi suona.",
    ingressi: ["corridoio", "stiva"],
    condizione: "suona se almeno uno dei due rileva movimento",
    righe: [
      { id: "r1", a: false, b: false, label: "corridoio fermo, stiva ferma" },
      { id: "r2", a: true, b: false, label: "movimento nel corridoio" },
      { id: "r3", a: false, b: true, label: "movimento nella stiva" },
      { id: "r4", a: true, b: true, label: "movimento in tutti e due" },
    ],
    soluzione: { r1: false, r2: true, r3: true, r4: true },
    explanation: "«Almeno uno» accende tre casi su quattro, e comprende anche quello in cui succedono entrambe le cose: in logica «oppure» non esclude, aggiunge. Messa accanto agli insiemi è l'unione — tutto quello che sta in uno, nell'altro, o in tutti e due." },

  { topic: "verita", difficulty: 7, difficulty8: true, format: "porte",
    prompt: "Il ponte si alza solo quando una leva è tirata e l'altra no: se le tiri tutte e due i contrappesi si bilanciano e non succede niente. Segna in quali casi si alza.",
    ingressi: ["leva di dritta", "leva di sinistra"],
    condizione: "si alza solo se ne è tirata esattamente una",
    righe: [
      { id: "r1", a: false, b: false, label: "nessuna leva tirata" },
      { id: "r2", a: true, b: false, label: "solo quella di dritta" },
      { id: "r3", a: false, b: true, label: "solo quella di sinistra" },
      { id: "r4", a: true, b: true, label: "tutte e due tirate" },
    ],
    soluzione: { r1: false, r2: true, r3: true, r4: false },
    explanation: "Questa è l'«o» del linguaggio comune — «o vieni tu o vengo io», non tutti e due — e in logica ha un nome suo perché è diversa dall'altra. Guarda la tavola: si accende quando i due ingressi sono DIVERSI, e si spegne quando sono uguali. È lo stesso motivo per cui serve chiedere «e se fossero tutti e due?» ogni volta che si legge un «o»." },

  // ========================================================== le griglie

  { topic: "esclusioni", difficulty: 4, difficulty8: true, format: "griglia",
    prompt: "Tre esploratori sono scesi nel relitto, ognuno con un attrezzo diverso. Chiudi le caselle impossibili e scopri chi porta che cosa.",
    soggetti: ["Bea", "Nilo", "Truc"],
    attributi: ["la torcia", "la falce", "la chiave"],
    indizi: [
      { text: "Bea non porta la torcia." },
      { text: "Chi porta la falce è Bea oppure Truc." },
      { text: "Nilo non porta la chiave." },
      { text: "Truc non porta la chiave." },
    ],
    soluzione: { Bea: "la chiave", Nilo: "la torcia", Truc: "la falce" },
    explanation: "Gli ultimi due indizi insieme dicono una cosa che nessuno dei due dice da solo: se né Nilo né Truc hanno la chiave, ce l'ha per forza Bea. Chiudere una casella ne apre un'altra, ed è per questo che conviene partire dall'informazione più stretta invece che dalla prima che si legge." },

  { topic: "deduzioni", difficulty: 6, difficulty8: true, format: "griglia",
    prompt: "Quattro abitanti hanno lasciato un oggetto ciascuno nella sala dei glifi. Scopri di chi è che cosa.",
    soggetti: ["Ada", "Milo", "Vera", "Ugo"],
    attributi: ["il cristallo", "la bussola", "il diario", "la lanterna"],
    indizi: [
      { text: "Chi ha lasciato la lanterna è Vera oppure Ugo." },
      { text: "Ugo non ha lasciato la lanterna." },
      { text: "Ada non ha lasciato il cristallo." },
      { text: "Ada non ha lasciato il diario." },
      { text: "Milo non ha lasciato il cristallo." },
    ],
    soluzione: { Ada: "la bussola", Milo: "il diario", Vera: "la lanterna", Ugo: "il cristallo" },
    explanation: "I primi due vanno letti insieme: se la lanterna è di Vera o di Ugo e non è di Ugo, allora è di Vera. Da lì cade tutto il resto — e nota che nessun indizio dice mai direttamente di chi è una cosa: quattro negazioni e una scelta fra due bastano a chiudere sedici caselle." },

  { topic: "esclusioni", difficulty: 8, difficulty8: true, format: "griglia",
    prompt: "Quattro moduli del relitto si sono spenti, ognuno per un guasto diverso. Chiudi le caselle e scopri quale guasto ha fermato quale modulo.",
    soggetti: ["Serra", "Fucina", "Ponte", "Antenna"],
    attributi: ["il fusibile bruciato", "la perdita d'acqua", "il cavo staccato", "la muffa sui contatti"],
    indizi: [
      { text: "Chi si è fermato per la perdita d'acqua è la Serra oppure il Ponte." },
      { text: "Il Ponte non si è fermato per la perdita d'acqua." },
      { text: "L'Antenna non si è fermata per il cavo staccato." },
      { text: "La Fucina non si è fermata per la muffa sui contatti." },
      { text: "Il Ponte non si è fermato per la muffa sui contatti." },
      { text: "Il Ponte non si è fermato per il fusibile bruciato." },
    ],
    soluzione: { Serra: "la perdita d'acqua", Fucina: "il fusibile bruciato", Ponte: "il cavo staccato", Antenna: "la muffa sui contatti" },
    explanation: "Sei indizi per sedici caselle, e nessuno dice mai «è stato questo». I primi due insieme assegnano la perdita d'acqua alla Serra; poi tre negazioni di fila sul Ponte lo lasciano con il solo cavo staccato, e da lì cade il resto. Ogni deduzione si appoggia su quella prima: è il modo in cui si risolve qualunque problema con troppi pezzi." },

  // =========================== fascia 3: il centro sottile del banco
  //
  // Otto item soli alla fascia 3, il punto più magro di logica. Tre
  // ordinamenti, perché è il gesto che alla fascia 3 mancava del tutto.

  { topic: "esclusioni", difficulty: 3, difficulty8: true, format: "ordering",
    prompt: "Quattro chiavi aprono quattro portelli, una ciascuno. Sai che la chiave rossa non apre il primo portello e che la verde apre l'ultimo. Metti in ordine i passi per scoprire tutto senza tirare a indovinare.",
    items: ["prova le due chiavi rimaste sui due portelli rimasti", "segna la chiave verde sull'ultimo portello", "cancella la rossa dal primo portello", "guarda quale portello è rimasto con una sola chiave possibile"],
    correctOrder: ["segna la chiave verde sull'ultimo portello", "cancella la rossa dal primo portello", "guarda quale portello è rimasto con una sola chiave possibile", "prova le due chiavi rimaste sui due portelli rimasti"],
    explanation: "Si parte sempre da quello che è certo, non da quello che è scritto per primo: la chiave verde è l'unica informazione che assegna, le altre tolgono. Ogni cosa che togli restringe il campo per tutte le altre, e la prova a tentativi resta per ultima — quando ne sono rimaste due." },

  { topic: "verita", difficulty: 3, difficulty8: true, format: "ordering",
    prompt: "Metti queste quattro frasi in ordine, da quella che è vera in più casi a quella che è vera in meno casi.",
    items: ["piove e c'è vento", "piove", "piove oppure c'è vento", "piove, c'è vento ed è notte"],
    correctOrder: ["piove oppure c'è vento", "piove", "piove e c'è vento", "piove, c'è vento ed è notte"],
    explanation: "Ogni «e» che aggiungi rende la frase più difficile da soddisfare, ogni «oppure» più facile: aggiungere una condizione con «e» restringe, con «oppure» allarga. È la stessa cosa che succede alle descrizioni — più parole metti, meno cose descrivi." },

  { topic: "quantificatori", difficulty: 3, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine queste frasi sugli abitanti del relitto, da quella che dice di più a quella che dice di meno.",
    items: ["qualcuno ha una chiave", "tutti hanno una chiave", "nessuno ha una chiave", "non tutti hanno una chiave"],
    correctOrder: ["tutti hanno una chiave", "qualcuno ha una chiave", "non tutti hanno una chiave", "nessuno ha una chiave"],
    explanation: "«Tutti» è la più impegnativa: basta un'eccezione e cade. «Qualcuno» chiede solo un caso. Poi si scende verso le negazioni — «non tutti» ammette che qualcuno ce l'abbia, «nessuno» non ammette più niente. Notare che «non tutti» e «qualcuno» possono essere veri insieme è già metà del lavoro." },

  // ============================ fascia 8: l'altro punto magro, dodici item

  { topic: "deduzioni", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Una regola dice: «se il sigillo è rosso allora il portello è chiuso». Metti in ordine i quattro casi, dal più informativo per verificarla al meno informativo.",
    items: ["un sigillo verde", "un portello aperto", "un sigillo rosso", "un portello chiuso"],
    correctOrder: ["un sigillo rosso", "un portello aperto", "un portello chiuso", "un sigillo verde"],
    explanation: "Per mettere alla prova «se rosso allora chiuso» servono i due casi che possono smentirla: un sigillo rosso (il portello dev'essere chiuso) e un portello aperto (il sigillo non può essere rosso). Un portello chiuso e un sigillo verde non possono smentirla in nessun modo, quindi guardarli non insegna niente — ed è esattamente l'errore che quasi tutti fanno, cercare conferme invece di prove." },

  { topic: "insiemi", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni coppia di gruppi al modo in cui stanno insieme.",
    pairs: [
      { left: "i quadrati e i rettangoli", right: "uno sta tutto dentro l'altro" },
      { left: "i numeri pari e i multipli di tre", right: "si sovrappongono solo in parte" },
      { left: "i numeri pari e i numeri dispari", right: "non hanno niente in comune e coprono tutto" },
      { left: "i gatti e le cose che volano", right: "non hanno niente in comune, ma non coprono tutto" },
    ],
    explanation: "Sono i quattro modi possibili, e confonderli è la sorgente di quasi tutti gli errori sui gruppi: ogni quadrato è un rettangolo ma non viceversa, mentre sei è pari e multiplo di tre insieme. Pari e dispari sono speciali perché si escludono *e* non lasciano fuori nessun numero: si chiama partizione." },

  { topic: "verita", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni affermazione secondo che cosa basta a dimostrarla o a smentirla.",
    items: ["tutti i cristalli del relitto brillano", "esiste un cristallo che brilla", "nessun cristallo brilla", "non tutti i cristalli brillano"],
    categories: ["basta un solo esempio per DIMOSTRARLA", "basta un solo esempio per SMENTIRLA"],
    assignments: {
      "tutti i cristalli del relitto brillano": "basta un solo esempio per SMENTIRLA",
      "esiste un cristallo che brilla": "basta un solo esempio per DIMOSTRARLA",
      "nessun cristallo brilla": "basta un solo esempio per SMENTIRLA",
      "non tutti i cristalli brillano": "basta un solo esempio per DIMOSTRARLA",
    },
    explanation: "Le frasi che parlano di *tutti* o di *nessuno* si smentiscono con un caso e si dimostrano solo guardandoli tutti; quelle che dicono *esiste* fanno l'opposto. È il motivo per cui in scienza si cercano i controesempi: sono l'unica cosa che una prova sola può decidere." },
];
