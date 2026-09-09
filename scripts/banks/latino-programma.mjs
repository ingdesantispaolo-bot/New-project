// Latino, fasce 1 e 2 — i mondi da 1 a 6.
//
// ## Perché questo file esiste
//
// Il banco di latino ha 289 item, il più grande dopo il nucleo, ma distribuiti
// così:
//
//   fascia   1   2   3   4   5   6   7   8
//   item    11  10  46  45  58  58  31  30
//
// Ventuno item nelle prime due fasce, contro quasi cento nelle fasce 3 e 4.
// `variety_audit` lo trovava dall'altra parte, ed era il peggiore di tutte e
// dodici le materie: «latino L1, il 33% delle prove è una ripetizione (max 17%),
// la peggiore vista 7 volte su 30».
//
// Guardando gli argomenti la causa è netta: undici argomenti su quindici hanno
// **zero** item nelle prime due fasce. Le declinazioni, i verbi, le frasi
// cominciano tutti alla fascia 3. Nei mondi da 1 a 6 il latino era quattro
// argomenti: casi, vocabolario, basi e una riga di verbo-sum.
//
// ## Perché gli item facili di latino sono di un tipo particolare
//
// Vale il vincolo scoperto il 2 settembre e scritto in `insieme.md`: **una
// domanda di FORMA non si deduce.** Chiedere il genitivo plurale di una parola a
// chi non ha la tavola davanti non misura il ragionamento, misura la memoria di
// una schermata — ed è per questo che è nata la famiglia di tavole «paradigma».
//
// Quindi nelle fasce 1 e 2 questo file NON chiede forme. Chiede tre cose che si
// possono davvero ragionare senza tabella:
//
//   - **il mestiere del caso**: qual è il soggetto, chi subisce l'azione, di chi
//     è una cosa. Si legge dalla frase italiana, prima ancora che dal latino;
//   - **la parola italiana che viene da lì**: è il ponte che rende il latino una
//     lingua viva invece che un elenco, e un ragazzo di undici anni lo attraversa
//     bene;
//   - **come funziona una lingua a casi**: perché l'ordine delle parole conta
//     meno che in italiano, e che cosa cambia una desinenza.
//
// Le forme vere arrivano dalla fascia 3, dove il banco è già ricco e le tavole
// esistono.
//
// ## Regole di scrittura
//
// Le stesse di `coding-programma.mjs`: fascia dichiarata con `difficulty8`, la
// risposta non più lunga di quattro caratteri del distrattore più lungo, nessun
// distrattore equivalente, un perché per ciascuno.

export const LATINO_PROGRAMMA = [
  // ---------------------------------------------------------------- fascia 1
  // Il mestiere dei casi, chiesto sull'italiano. Prima di riconoscere una
  // desinenza bisogna sapere che cosa si sta cercando.
  { topic: "casi", difficulty: 1, difficulty8: true,
    prompt: "In «Il lupo vede il cervo», chi compie l'azione?",
    answer: "il lupo", distractors: ["il cervo", "vede", "nessuno"],
    explanation: "Chi compie l'azione è il soggetto, e in latino va al nominativo. Riconoscerlo in italiano è il primo passo: la desinenza si impara dopo, quando si sa già che cosa deve marcare.",
    distractorWhy: { "il cervo": "È chi subisce l'azione: viene visto, non vede.", "vede": "È l'azione stessa, non chi la compie.", "nessuno": "Ogni frase con un verbo attivo ha qualcuno che agisce." } },
  { topic: "casi", difficulty: 1, difficulty8: true,
    prompt: "In «Il lupo vede il cervo», chi subisce l'azione?",
    answer: "il cervo", distractors: ["il lupo", "vede", "tutti e due"],
    explanation: "Chi subisce è il complemento oggetto, e in latino va all'accusativo. È il secondo caso che si impara, ed è quello che rende inutile l'ordine delle parole.",
    distractorWhy: { "il lupo": "È chi guarda: compie l'azione invece di riceverla.", "vede": "È il verbo, cioè l'azione, non una persona coinvolta.", "tutti e due": "In questa frase i due ruoli sono distinti: uno vede, l'altro è visto." } },
  { topic: "casi", difficulty: 1, difficulty8: true,
    prompt: "In «La casa del contadino è grande», di chi si sta dicendo che è il proprietario?",
    answer: "il contadino", distractors: ["la casa", "grande", "nessuno dei due"],
    explanation: "Il legame «di chi è» si esprime con il genitivo. In italiano lo segna la preposizione «del», in latino lo segna la fine della parola.",
    distractorWhy: { "la casa": "È la cosa posseduta, non chi la possiede.", "grande": "È una qualità della casa, e non indica nessun proprietario.", "nessuno dei due": "«del contadino» dichiara esplicitamente di chi è la casa." } },
  { topic: "casi", difficulty: 1, difficulty8: true,
    prompt: "In italiano «il cane morde l'uomo» e «l'uomo morde il cane» dicono cose opposte. Che cosa lo decide?",
    answer: "la posizione delle parole", distractors: ["la fine di ciascuna parola", "il tono di voce", "la lunghezza della frase"],
    explanation: "In italiano il ruolo lo dà il posto: chi viene prima del verbo agisce. In latino lo dà la desinenza, ed è per questo che lì le parole si possono spostare senza cambiare il senso.",
    distractorWhy: { "la fine di ciascuna parola": "È il sistema latino: in italiano «cane» resta «cane» in tutti e due i ruoli.", "il tono di voce": "Le due frasi restano diverse anche lette senza espressione.", "la lunghezza della frase": "Le due frasi hanno esattamente le stesse parole e la stessa lunghezza." } },
  { topic: "basi", difficulty: 1, difficulty8: true,
    prompt: "Che cos'è una desinenza?",
    answer: "la parte finale che cambia", distractors: ["la prima lettera della parola", "il significato della radice", "un segno di punteggiatura"],
    explanation: "La parola latina si divide in due: una parte che resta ferma e porta il significato, e una finale che cambia e dice il ruolo nella frase. Tutta la grammatica latina vive in quella finale.",
    distractorWhy: { "la prima lettera della parola": "L'inizio è la parte che resta ferma: è la radice.", "il significato della radice": "Il significato sta nella parte fissa, non in quella che cambia.", "un segno di punteggiatura": "La desinenza è fatta di lettere e appartiene alla parola." } },
  { topic: "basi", difficulty: 1, difficulty8: true,
    prompt: "In «rosam», qual è la parte che porta il significato?",
    answer: "ros-", distractors: ["-am", "-m", "tutta la parola"],
    explanation: "La radice ros- vuol dire rosa in ogni forma della parola; la finale -am dice soltanto che qui la rosa subisce l'azione. Separarle è il gesto che si ripete per tutto il latino.",
    distractorWhy: { "-am": "È la desinenza: dice il ruolo, non che cosa sia la cosa.", "-m": "È solo un pezzo della desinenza, e da solo non è una parte della parola.", "tutta la parola": "La parola è divisibile, ed è proprio questa divisione che serve a leggerla." } },
  { topic: "etimologia", difficulty: 1, difficulty8: true,
    prompt: "Da quale parola latina viene l'italiano «acqua»?",
    answer: "aqua", distractors: ["ager", "arbor", "arma"],
    explanation: "Alcune parole sono passate quasi intatte: cambia una lettera o niente. Riconoscerle rende il latino una lingua che si sa già in parte, invece di un elenco da imparare.",
    distractorWhy: { "ager": "Vuol dire campo, e ha dato «agricoltura».", "arbor": "Vuol dire albero, e la somiglianza è con un'altra parola italiana.", "arma": "Vuol dire armi, e ha dato «arma» in italiano." } },
  { topic: "etimologia", difficulty: 1, difficulty8: true,
    prompt: "L'italiano «terrestre» viene dal latino «terra». Che cosa vuol dire quindi «terrestre»?",
    answer: "che sta sulla terra", distractors: ["che è molto antico", "che è fatto di pietra", "che vive nell'acqua"],
    explanation: "Conoscere la radice permette di capire una parola mai vista prima. È il vero guadagno del latino: non ricordare di più, ma dedurre invece di chiedere.",
    distractorWhy: { "che è molto antico": "L'antichità non c'entra con la radice terra.", "che è fatto di pietra": "La pietra è un'altra parola latina, e darebbe un'altra famiglia.", "che vive nell'acqua": "Sarebbe la famiglia di aqua, non quella di terra." } },
  { topic: "etimologia", difficulty: 1, difficulty8: true,
    prompt: "Il latino «liber» vuol dire libro. Quale parola italiana viene da lì?",
    answer: "libreria", distractors: ["libertà", "libbra", "libeccio"],
    explanation: "Due parole latine possono somigliarsi molto e non essere parenti: liber libro e liber libero sono diverse. La somiglianza di suono non basta, serve il significato.",
    distractorWhy: { "libertà": "Viene da un altro liber, che vuol dire libero: stessa forma, altra famiglia.", "libbra": "È un'unità di peso, dal latino libra, che vuol dire bilancia.", "libeccio": "È un vento, e il nome arriva dall'arabo passando per il greco." } },
  { topic: "vocabolario", difficulty: 1, difficulty8: true,
    prompt: "Che cosa vuol dire il latino «puella»?",
    answer: "ragazza", distractors: ["ragazzo", "casa", "strada"],
    explanation: "È una delle prime parole che si incontrano perché appartiene alla prima declinazione, la più regolare: serve come modello per tutte le altre parole dello stesso gruppo.",
    distractorWhy: { "ragazzo": "Si dice puer, ed è di un gruppo diverso.", "casa": "Si dice villa oppure domus, secondo il tipo di casa.", "strada": "Si dice via, e infatti la parola è rimasta in italiano." } },
  { topic: "vocabolario", difficulty: 1, difficulty8: true,
    prompt: "Che cosa vuol dire il latino «magnus»?",
    answer: "grande", distractors: ["piccolo", "veloce", "buono"],
    explanation: "È rimasta in italiano dentro parole come «magnifico» e «magnate»: chi la riconosce lì dentro non deve impararla due volte.",
    distractorWhy: { "piccolo": "Si dice parvus, ed è il suo contrario.", "veloce": "Si dice celer, da cui «celerità».", "buono": "Si dice bonus, da cui «bonario» e «bonifico»." } },

  // ---------------------------------------------------------------- fascia 2
  // Dal ruolo alla lettura: qui la frase latina si guarda davvero, ma sempre con
  // domande che si possono ragionare senza avere la tavola davanti.
  { topic: "casi", difficulty: 2, difficulty8: true,
    prompt: "In latino «Puella rosam videt» vuol dire «la ragazza vede la rosa». Chi vede?",
    answer: "la ragazza", distractors: ["la rosa", "tutte e due", "non si può sapere"],
    explanation: "Puella è al nominativo e rosam all'accusativo: la prima agisce, la seconda subisce. Spostando le parole la traduzione non cambierebbe, perché il ruolo sta nella finale.",
    distractorWhy: { "la rosa": "Rosam finisce in -m, la marca di chi subisce l'azione.", "tutte e due": "Un verbo attivo ha un solo soggetto, e qui è puella.", "non si può sapere": "Le desinenze lo dicono con certezza: è esattamente il loro mestiere." } },
  { topic: "casi", difficulty: 2, difficulty8: true,
    prompt: "In «Rosam puella videt» che cosa cambia rispetto a «Puella rosam videt»?",
    answer: "niente", distractors: ["si scambiano i ruoli", "diventa una domanda", "il verbo cambia tempo"],
    explanation: "Lo spostamento può servire a dare enfasi, ma non tocca il significato: chi agisce e chi subisce lo hanno già detto le desinenze. È la differenza più profonda con l'italiano.",
    distractorWhy: { "si scambiano i ruoli": "Sarebbe vero in italiano, dove il ruolo lo dà la posizione.", "diventa una domanda": "Le domande si segnano con altre parole, non con l'ordine.", "il verbo cambia tempo": "Il verbo è rimasto identico: nessuna sua lettera è cambiata." } },
  { topic: "casi", difficulty: 2, difficulty8: true,
    prompt: "Una parola latina finisce in -m al singolare. Quale ruolo indica più spesso?",
    answer: "chi subisce l'azione", distractors: ["chi compie davvero l'azione", "il proprietario", "il luogo"],
    explanation: "La -m finale è il segno dell'accusativo singolare in quasi tutte le declinazioni: è l'indizio più affidabile che il latino offre a chi comincia a leggere.",
    distractorWhy: { "chi compie davvero l'azione": "Il nominativo ha finali diverse, e non usa la -m.", "il proprietario": "Il genitivo si riconosce da altre finali, come -ae o -i.", "il luogo": "I complementi di luogo si costruiscono con preposizioni e altri casi." } },
  { topic: "verbo-sum", difficulty: 2, difficulty8: true,
    prompt: "Che cosa vuol dire il latino «sum»?",
    answer: "io sono", distractors: ["tu sei", "egli è", "noi siamo"],
    explanation: "Il verbo essere è il primo che si impara perché è irregolare in tutte le lingue e serve continuamente. In latino la persona è già dentro il verbo: non serve scrivere «io».",
    distractorWhy: { "tu sei": "Si dice es, ed è una forma più corta.", "egli è": "Si dice est, con la t finale della terza persona.", "noi siamo": "Si dice sumus, e la parte -mus segna il plurale." } },
  { topic: "verbo-sum", difficulty: 2, difficulty8: true,
    prompt: "Perché in latino si può dire «sum» senza scrivere «ego»?",
    answer: "perché la persona sta nella desinenza", distractors: ["perché ego non esiste", "perché è un errore comune fra i principianti", "perché il verbo è irregolare"],
    explanation: "La finale del verbo dice già chi compie l'azione, quindi il pronome è superfluo. Quando compare, serve a insistere: «io, proprio io».",
    distractorWhy: { "perché ego non esiste": "Ego esiste eccome, ed è rimasto anche in italiano.", "perché è un errore comune fra i principianti": "Non è un errore: è la forma normale della lingua.", "perché il verbo è irregolare": "Vale anche per i verbi regolari: tutti portano la persona nella finale." } },
  { topic: "basi", difficulty: 2, difficulty8: true,
    prompt: "Che cosa sono le declinazioni?",
    answer: "gruppi di nomi con le stesse finali", distractors: ["i tempi del verbo", "le regole di pronuncia", "i segni di lettura usati nei testi antichi"],
    explanation: "I nomi latini non cambiano tutti allo stesso modo: si dividono in cinque gruppi, e imparato il modello di un gruppo si sanno leggere tutte le parole che gli appartengono.",
    distractorWhy: { "i tempi del verbo": "I verbi si organizzano in coniugazioni, che sono un'altra cosa.", "le regole di pronuncia": "La pronuncia è indipendente dal gruppo a cui il nome appartiene.", "i segni di lettura usati nei testi antichi": "Il latino classico si scriveva senza segni di lettura." } },
  { topic: "basi", difficulty: 2, difficulty8: true,
    prompt: "Quante declinazioni ha il latino?",
    answer: "5", distractors: ["3", "4", "7"],
    explanation: "Cinque gruppi, e non hanno tutti lo stesso peso: le prime tre coprono la grande maggioranza delle parole che si incontrano leggendo.",
    distractorWhy: { "3": "Sono le coniugazioni principali dei verbi che si contano diversamente.", "4": "Ne mancherebbe una, la quinta, che è la più piccola ma esiste.", "7": "I casi sono sei: il numero dei gruppi è un'altra cosa." } },
  { topic: "basi", difficulty: 2, difficulty8: true,
    prompt: "Quanti casi ha il latino?",
    answer: "6", distractors: ["4", "5", "8"],
    explanation: "Sei ruoli diversi che una parola può avere nella frase. In italiano quegli stessi ruoli si esprimono con le preposizioni e con la posizione, non con la fine della parola.",
    distractorWhy: { "4": "Ne mancherebbero due, e sono fra i più usati.", "5": "Cinque è il numero delle declinazioni, non dei casi.", "8": "Alcune lingue antiche ne hanno di più, ma il latino si ferma a sei." } },
  { topic: "vocabolario", difficulty: 2, difficulty8: true,
    prompt: "Che cosa vuol dire il latino «bellum»?",
    answer: "guerra", distractors: ["bello", "libro", "il campo coltivato"],
    explanation: "È il classico falso amico: somiglia a «bello» e vuol dire l'opposto di ciò che si spera. Chi traduce a orecchio qui sbaglia, e la lezione vale per tutto il latino.",
    distractorWhy: { "bello": "Si dice pulcher: la somiglianza con l'italiano è un caso.", "libro": "Si dice liber, e la confusione nasce da un'altra parola.", "il campo coltivato": "Si dice ager, da cui l'italiano «agricoltura»." } },
  { topic: "vocabolario", difficulty: 2, difficulty8: true,
    prompt: "Che cosa vuol dire il latino «aqua»?",
    answer: "acqua", distractors: ["aquila", "aria", "fiume"],
    explanation: "È una delle parole rimaste quasi intatte: cambia una lettera sola. Le parole di questo tipo sono un buon punto di partenza perché danno subito la sensazione di leggere.",
    distractorWhy: { "aquila": "Si dice aquila anche in latino, ma è un'altra parola.", "aria": "Si dice aer, presa a sua volta dal greco.", "fiume": "Si dice flumen, da cui l'italiano «fluviale»." } },
  { topic: "etimologia", difficulty: 2, difficulty8: true,
    prompt: "Il latino «manus» vuol dire mano. Quale parola italiana conserva quella radice?",
    answer: "manuale", distractors: ["mandare", "manata", "mantello"],
    explanation: "Una radice latina si riconosce meglio nelle parole colte che in quelle di tutti i giorni: «manuale» dice «che si fa con le mani» e conserva la forma latina quasi intera.",
    distractorWhy: { "mandare": "Viene da mandare, che a sua volta contiene manus ma per un'altra strada e con un altro senso.", "manata": "È formata sull'italiano «mano», non direttamente sul latino.", "mantello": "Viene da mantellum, che è un'altra parola e non c'entra con la mano." } },
  { topic: "etimologia", difficulty: 2, difficulty8: true,
    prompt: "«Aquedotto» unisce due parole latine. Quali?",
    answer: "acqua e condurre", distractors: ["acqua e casa grande", "aquila e volare", "alto e strada"],
    explanation: "Molte parole italiane sono due parole latine incollate. Smontarle è il modo più rapido per capirne il senso senza cercarle: un acquedotto conduce acqua.",
    distractorWhy: { "acqua e casa grande": "La casa non compare: la seconda metà indica un'azione, non un luogo.", "aquila e volare": "L'aquila somiglia ad aqua ma è un'altra parola.", "alto e strada": "Nessuna delle due compare nella parola." } },
  { topic: "frasi", difficulty: 2, difficulty8: true,
    prompt: "In latino il verbo si trova spesso in quale punto della frase?",
    answer: "alla fine", distractors: ["all'inizio", "sempre al centro", "prima del soggetto"],
    explanation: "È un'abitudine della prosa latina, non una regola: aiuta a orientarsi leggendo, ma non si può usare come prova, perché i poeti la violano di continuo.",
    distractorWhy: { "all'inizio": "Capita, e serve a dare enfasi, ma non è la posizione abituale.", "sempre al centro": "La parola «sempre» rende falsa l'affermazione: nel latino la posizione è libera.", "prima del soggetto": "Anche questo capita, ma non è la disposizione più frequente." } },
  { topic: "frasi", difficulty: 2, difficulty8: true,
    prompt: "Perché in latino non esistono «il» e «la»?",
    answer: "perché non ha articoli", distractors: ["perché sono sottintesi dalle desinenze", "perché li usava solo la poesia", "perché li ha persi con il tempo"],
    explanation: "Il latino non ha mai avuto articoli: traducendo li aggiungiamo noi, scegliendo secondo il contesto. Gli articoli italiani nascono più tardi, dai dimostrativi latini.",
    distractorWhy: { "perché sono sottintesi dalle desinenze": "Le desinenze dicono il ruolo nella frase, non la determinatezza.", "perché li usava solo la poesia": "Non li usava nemmeno la poesia: la lingua non li aveva.", "perché li ha persi con il tempo": "Non li ha persi: non li ha mai avuti, e sono le lingue romanze ad averli inventati." } },
];
