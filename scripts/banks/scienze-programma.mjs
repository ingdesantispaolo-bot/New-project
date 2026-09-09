// Scienze, fasce 1 e 2 — i mondi da 1 a 6.
//
// ## Perché questo file esiste
//
// Il banco di scienze ha 154 item, il più piccolo dopo logica, con trentuno
// nelle prime due fasce:
//
//   fascia   1   2   3   4   5   6   7   8
//   item    16  15  21  20  26  25  16  15
//
// `variety_audit`: «scienze L1, il 27% delle prove è una ripetizione, tetto
// 17%». Il pozzo basso non è il più povero in assoluto — latino e coding stavano
// peggio — ma scienze ha una particolarità: gli argomenti sono otto e nelle
// prime due fasce ce ne stanno sette, quindi il materiale è sparso e ogni
// argomento ne ha due o tre. Con un pozzo così, un argomento pescato due volte
// dà la stessa prova.
//
// ## Che cosa si può chiedere alla fascia 1
//
// La tentazione delle scienze è la definizione: «che cos'è la fotosintesi». Ma
// una definizione si ripete, non si ragiona, e due domande di definizione sullo
// stesso argomento si somigliano sempre — che è esattamente il difetto che
// `variety_audit` misura.
//
// Queste ventisei righe chiedono invece tre cose che si possono pensare:
//
//   - **la previsione**: se scaldo, se tolgo, se aspetto, che cosa succede.
//     È l'unica forma che rende il metodo sperimentale una cosa e non un elenco
//     di passi da recitare;
//   - **la causa**: perché il ghiaccio galleggia, perché di notte fa più freddo,
//     perché una pianta al buio muore. Ha una risposta sola e non si indovina;
//   - **il confine di una categoria**: che cosa è vivente e che cosa no, che cosa
//     è materia e che cosa è energia. Sono le distinzioni su cui poggia tutto il
//     resto del programma, e si sbagliano in modi molto tipici.
//
// ## Regole di scrittura
//
// Le stesse di `coding-programma.mjs`: fascia dichiarata con `difficulty8`, la
// risposta **mai più lunga del distrattore più lungo**, nessun distrattore
// equivalente, un perché per ciascuno. Tre item a risposta libera per non far
// scendere la quota della Decisione 10 sotto il 20%.

export const SCIENZE_PROGRAMMA = [
  // ---------------------------------------------------------------- fascia 1
  { topic: "metodo", difficulty: 1, difficulty8: true,
    prompt: "Per capire se una pianta ha bisogno di luce, quante piante servono almeno?",
    answer: "2", distractors: ["1", "5", "10"],
    explanation: "Ne serve una al buio e una alla luce, tenendo tutto il resto uguale: senza qualcosa con cui confrontare, un risultato non dimostra niente. La seconda pianta si chiama controllo.",
    distractorWhy: { "1": "Se muore, non si sa se per il buio o per un'altra ragione: manca il confronto.", "5": "Più piante rendono il risultato più solido, ma il minimo per confrontare è due.", "10": "Il numero alto aiuta la statistica, non cambia la logica dell'esperimento." } },
  { topic: "metodo", difficulty: 1, difficulty8: true,
    prompt: "In un esperimento, perché si cambia una cosa sola per volta?",
    answer: "per sapere che cosa ha agito", distractors: ["per fare prima e risparmiare", "perché due cose non stanno insieme", "per non rompere gli strumenti"],
    explanation: "Cambiandone due, se il risultato cambia non si sa quale delle due lo abbia causato. È la regola che rende un esperimento una prova invece che un'osservazione fortunata.",
    distractorWhy: { "per fare prima e risparmiare": "Cambiare una cosa per volta richiede anzi più prove, non meno.", "perché due cose non stanno insieme": "Possono benissimo stare insieme: è il risultato a diventare illeggibile.", "per non rompere gli strumenti": "Non c'entra la sicurezza: c'entra che cosa si può concludere." } },
  { topic: "viventi", difficulty: 1, difficulty8: true,
    prompt: "Quale di questi non è un essere vivente?",
    answer: "un cristallo di sale", distractors: ["un fungo del sottobosco", "un batterio del terreno", "un seme non ancora germogliato"],
    explanation: "Un cristallo cresce aggiungendo materiale all'esterno, un vivente cresce dall'interno usando ciò che mangia. È la distinzione che regge tutta la biologia, e la crescita da sola non basta a decidere.",
    distractorWhy: { "un fungo del sottobosco": "È vivente: non è una pianta, ma è un regno a sé.", "un batterio del terreno": "Ha una cellula sola, e tanto basta a farne un vivente.", "un seme non ancora germogliato": "È vivo ma fermo: aspetta le condizioni giuste per ripartire." } },
  { topic: "viventi", difficulty: 1, difficulty8: true,
    prompt: "Che cosa fa una pianta con la luce del sole?",
    answer: "si fabbrica il cibo", distractors: ["si scalda per non morire", "asciuga l'acqua in eccesso", "si orienta verso l'alto"],
    explanation: "La pianta non prende il cibo dal terreno: lo costruisce dall'acqua e dall'aria usando la luce come energia. Dal terreno prende acqua e sali, che sono ingredienti, non nutrimento.",
    distractorWhy: { "si scalda per non morire": "Il calore le arriva, ma non è il motivo per cui la luce le è indispensabile.", "asciuga l'acqua in eccesso": "L'acqua le serve, e perderla è un problema, non uno scopo.", "si orienta verso l'alto": "Lo fa, ma è una conseguenza: senza luce morirebbe anche restando dritta." } },
  { topic: "corpo", difficulty: 1, difficulty8: true,
    prompt: "A che cosa serve lo scheletro oltre a sorreggere?",
    answer: "a proteggere gli organi", distractors: ["a produrre il calore del corpo", "a far circolare il sangue", "a immagazzinare l'acqua"],
    explanation: "Cranio e gabbia toracica sono scatole: chiudono cervello, cuore e polmoni. Le ossa fanno anche una terza cosa che sorprende — dentro, il midollo fabbrica le cellule del sangue.",
    distractorWhy: { "a produrre il calore del corpo": "Il calore lo producono soprattutto i muscoli quando lavorano.", "a far circolare il sangue": "La circolazione è compito del cuore e dei vasi.", "a immagazzinare l'acqua": "L'acqua è distribuita ovunque, non conservata nelle ossa." } },
  { topic: "materia", difficulty: 1, difficulty8: true,
    prompt: "Che cosa succede all'acqua se la scaldi a lungo dopo che ha iniziato a bollire?",
    answer: "resta alla stessa temperatura", distractors: ["diventa sempre più calda", "si raffredda un poco", "cambia colore molto lentamente"],
    explanation: "Durante un cambiamento di stato il calore non alza la temperatura: serve tutto a staccare le particelle. Il termometro resta fermo a cento finché c'è acqua liquida.",
    distractorWhy: { "diventa sempre più calda": "Succede prima dell'ebollizione: da lì in poi il calore va nel passaggio di stato.", "si raffredda un poco": "Si continua a fornire calore, quindi non può raffreddarsi.", "cambia colore molto lentamente": "L'acqua pura resta trasparente in tutti i suoi stati." } },
  { topic: "materia", difficulty: 1, difficulty8: true,
    prompt: "Perché il ghiaccio galleggia sull'acqua?",
    answer: "pesa meno a parità di volume", distractors: ["è più freddo dell'acqua attorno", "l'aria dentro lo tiene a galla", "il ghiaccio è sempre più leggero"],
    explanation: "L'acqua è una delle pochissime sostanze che aumentano di volume gelando: la stessa quantità occupa più spazio, quindi è meno densa. Se non fosse così, i laghi gelerebbero dal fondo.",
    distractorWhy: { "è più freddo dell'acqua attorno": "La temperatura da sola non decide se una cosa galleggia.", "l'aria dentro lo tiene a galla": "Anche il ghiaccio senza bolle galleggia lo stesso.", "il ghiaccio è sempre più leggero": "Un blocco grande pesa più di un bicchiere d'acqua: conta la densità, non il peso." } },
  { topic: "terra-universo", difficulty: 1, difficulty8: true,
    prompt: "Che cosa provoca il giorno e la notte?",
    answer: "la Terra gira su sé stessa", distractors: ["la Terra gira intorno al Sole", "la Luna copre il Sole a turno", "il Sole si spegne e si riaccende"],
    explanation: "Un giro su sé stessa in ventiquattro ore: la faccia illuminata cambia di continuo. Il giro attorno al Sole dura un anno e produce un'altra cosa, cioè le stagioni.",
    distractorWhy: { "la Terra gira intorno al Sole": "Quel movimento dura un anno e non c'entra con il ritmo quotidiano.", "la Luna copre il Sole a turno": "Succede solo durante le eclissi, che sono rare e brevi.", "il Sole si spegne e si riaccende": "Il Sole brilla senza interruzioni: siamo noi a girarci." } },
  { topic: "terra-universo", difficulty: 1, difficulty8: true,
    prompt: "Perché vediamo la Luna anche se non emette luce?",
    answer: "riflette la luce del Sole", distractors: ["brilla di luce sua più debole", "è illuminata dalle stelle vicine", "trattiene la luce del giorno"],
    explanation: "La Luna è una roccia illuminata: le sue fasi sono la parte illuminata che vediamo cambiare mentre gira attorno a noi. Non è la Terra a farle ombra, se non durante un'eclissi.",
    distractorWhy: { "brilla di luce sua più debole": "Non produce luce: sarebbe una stella, e le stelle bruciano.", "è illuminata dalle stelle vicine": "Le altre stelle sono troppo lontane per illuminare qualcosa.", "trattiene la luce del giorno": "La luce non si accumula: se la sorgente si spegne, l'illuminazione finisce." } },
  { topic: "ecosistema", difficulty: 1, difficulty8: true,
    prompt: "In una catena alimentare, da dove viene l'energia all'inizio?",
    answer: "dal Sole", distractors: ["dal terreno fertile", "dall'acqua piovana", "dagli animali morti"],
    explanation: "Le piante catturano l'energia della luce e la trasformano in cibo; tutti gli altri la ricevono mangiando. Ogni catena alimentare, anche in fondo al mare, comincia da lì.",
    distractorWhy: { "dal terreno fertile": "Il terreno dà acqua e sali minerali, che sono materiali e non energia.", "dall'acqua piovana": "L'acqua serve, ma non porta energia utilizzabile dai viventi.", "dagli animali morti": "I decompositori chiudono il ciclo della materia, non aprono quello dell'energia." } },
  { topic: "ambiente", difficulty: 1, difficulty8: true,
    prompt: "Perché si dice che l'acqua sulla Terra è sempre la stessa?",
    answer: "gira in un ciclo chiuso", distractors: ["se ne produce quanta se ne perde", "il mare ne fabbrica di nuova", "la pioggia la porta dallo spazio"],
    explanation: "Evapora, forma nuvole, ricade, torna al mare: cambia stato e posizione ma non sparisce. È il motivo per cui inquinarla in un punto la rovina anche altrove.",
    distractorWhy: { "se ne produce quanta se ne perde": "Non c'è nessuna produzione: la quantità è la stessa da moltissimo tempo.", "il mare ne fabbrica di nuova": "Il mare la conserva e la evapora, ma non la crea.", "la pioggia la porta dallo spazio": "La pioggia viene dal vapore che si è alzato dalla Terra stessa." } },

  // ---------------------------------------------------------------- fascia 2
  { topic: "metodo", difficulty: 2, difficulty8: true,
    prompt: "Un'ipotesi scientifica deve avere una caratteristica su tutte. Quale?",
    answer: "poter essere smentita", distractors: ["essere già stata dimostrata", "essere condivisa da tutti", "riguardare cose visibili"],
    explanation: "Un'affermazione che nessun esperimento potrebbe contraddire non è una scoperta: è una posizione. La scienza avanza scartando ipotesi, quindi devono essere scartabili.",
    distractorWhy: { "essere già stata dimostrata": "Allora non sarebbe un'ipotesi ma una conclusione.", "essere condivisa da tutti": "Molte scoperte sono partite da idee che quasi nessuno accettava.", "riguardare cose visibili": "Atomi e onde radio non si vedono, e sono materia di scienza." } },
  { topic: "metodo", difficulty: 2, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama la pianta lasciata alla luce, quella con cui si confronta il risultato dell'esperimento?",
    answer: "controllo", accept: ["il controllo", "gruppo di controllo", "campione di controllo"],
    explanation: "Il controllo è la prova tenuta nelle condizioni normali: serve a stabilire che cosa sarebbe successo comunque, e senza di lui nessun risultato dimostra una causa." },
  { topic: "viventi", difficulty: 2, difficulty8: true,
    prompt: "Qual è l'unità più piccola di cui è fatto ogni essere vivente?",
    answer: "la cellula", distractors: ["il tessuto muscolare", "l'organo interno", "l'apparato completo"],
    explanation: "Chi ne ha una sola e chi ne ha miliardi: la cellula è il mattone comune. Tessuti, organi e apparati sono livelli successivi, e si costruiscono tutti a partire da lei.",
    distractorWhy: { "il tessuto muscolare": "È un insieme di cellule dello stesso tipo: viene dopo, non prima.", "l'organo interno": "Un organo è fatto di più tessuti, quindi sta ancora più in alto.", "l'apparato completo": "È l'insieme di più organi che lavorano insieme: è il livello più grande." } },
  { topic: "viventi", difficulty: 2, difficulty8: true,
    prompt: "Perché un fungo non è una pianta?",
    answer: "non si fabbrica il cibo", distractors: ["non ha radici nel terreno", "non ha bisogno di acqua", "cresce soltanto all'ombra"],
    explanation: "Le piante costruiscono il proprio nutrimento con la luce; i funghi lo assorbono da materia già esistente, come fanno gli animali. È per questo che formano un regno a parte.",
    distractorWhy: { "non ha radici nel terreno": "Ha filamenti che ne fanno le veci e si estendono anche molto.", "non ha bisogno di acqua": "L'acqua gli è indispensabile, e infatti cresce dove è umido.", "cresce soltanto all'ombra": "Preferisce l'ombra ma può crescere anche in luce piena." } },
  { topic: "corpo", difficulty: 2, difficulty8: true,
    prompt: "Che cosa espiri di diverso da quello che hai inspirato?",
    answer: "più anidride carbonica", distractors: ["più ossigeno di quanto ne entra", "aria completamente identica", "soltanto vapore acqueo puro"],
    explanation: "Il corpo prende ossigeno e restituisce anidride carbonica: è lo scarto della combustione degli zuccheri nei muscoli. È anche il motivo per cui una stanza chiusa e piena diventa presto sgradevole.",
    distractorWhy: { "più ossigeno di quanto ne entra": "L'ossigeno viene consumato, quindi ne esce meno di quanto ne entra.", "aria completamente identica": "Se non cambiasse nulla, respirare non servirebbe a niente.", "soltanto vapore acqueo puro": "Il vapore c'è, ma è l'anidride carbonica il vero scarto da eliminare." } },
  { topic: "corpo", difficulty: 2, difficulty8: true,
    prompt: "Che cosa porta il sangue ai muscoli mentre lavorano?",
    answer: "ossigeno e zuccheri", distractors: ["soltanto acqua e sali", "aria presa dai polmoni", "calore prodotto dal cuore"],
    explanation: "Il sangue è un servizio di consegna a doppio senso: porta ciò che serve e ritira gli scarti, fra cui l'anidride carbonica che poi si espira.",
    distractorWhy: { "soltanto acqua e sali": "Li trasporta, ma da soli non danno nessuna energia.", "aria presa dai polmoni": "Nel sangue passa l'ossigeno, non l'aria intera.", "calore prodotto dal cuore": "Il calore lo producono i muscoli, e il sangue lo distribuisce." } },
  { topic: "materia", difficulty: 2, difficulty8: true,
    prompt: "Che cos'è l'evaporazione?",
    answer: "il passaggio da liquido a gas", distractors: ["il passaggio da gas a liquido", "il passaggio da solido a liquido", "il passaggio da liquido a solido"],
    explanation: "Avviene anche molto sotto i cento gradi: una pozzanghera si asciuga in una giornata fresca. L'ebollizione è solo l'evaporazione fatta in fretta e in tutto il liquido insieme.",
    distractorWhy: { "il passaggio da gas a liquido": "È la condensazione, ed è ciò che forma le nuvole e la rugiada.", "il passaggio da solido a liquido": "È la fusione, come il ghiaccio che si scioglie.", "il passaggio da liquido a solido": "È la solidificazione, il verso opposto." } },
  { topic: "energia", difficulty: 2, difficulty8: true,
    prompt: "Quando accendi una lampadina, l'energia elettrica diventa...",
    answer: "luce e calore", distractors: ["soltanto luce visibile", "soltanto calore diffuso", "movimento del filamento"],
    explanation: "L'energia non si crea e non si distrugge: si trasforma, e una parte finisce sempre in calore. Una lampadina a incandescenza scalda molto più di quanto illumini, ed è per questo che è stata abbandonata.",
    distractorWhy: { "soltanto luce visibile": "Se fosse così la lampadina resterebbe fredda al tatto.", "soltanto calore diffuso": "Sarebbe una stufa: la luce c'è ed è ciò per cui la usiamo.", "movimento del filamento": "Il filamento resta fermo: si scalda e diventa incandescente." } },
  { topic: "energia", difficulty: 2, difficulty8: true, format: "short_answer",
    prompt: "L'energia non si crea e non si distrugge: che cosa fa invece? Una parola.",
    answer: "si trasforma", accept: ["trasforma", "si trasforma soltanto", "cambia forma"],
    explanation: "È il principio di conservazione: seguendo l'energia da una forma all'altra si scopre sempre dove è finita, e di solito una parte è finita in calore." },
  { topic: "ecosistema", difficulty: 2, difficulty8: true,
    prompt: "Che cosa succede a un prato se spariscono tutti i decompositori?",
    answer: "i resti si accumulano", distractors: ["le piante crescono più in fretta", "gli erbivori aumentano di numero", "il terreno diventa più fertile"],
    explanation: "I decompositori restituiscono al terreno le sostanze intrappolate nei resti. Senza di loro il ciclo della materia si interrompe: tutto resta lì e le piante non trovano più nutrimento.",
    distractorWhy: { "le piante crescono più in fretta": "Succede il contrario: i sali minerali smettono di tornare disponibili.", "gli erbivori aumentano di numero": "Con meno piante avrebbero meno da mangiare, non di più.", "il terreno diventa più fertile": "La fertilità dipende proprio dal lavoro dei decompositori." } },
  { topic: "ecosistema", difficulty: 2, difficulty8: true,
    prompt: "Perché in una catena alimentare i predatori sono sempre meno delle prede?",
    answer: "a ogni passaggio si perde energia", distractors: ["i predatori vivono molto più a lungo", "le prede si riproducono in fretta", "i predatori mangiano una volta sola"],
    explanation: "Solo una piccola parte dell'energia di un livello passa a quello sopra: il resto se ne va in calore e movimento. Per questo le piramidi alimentari hanno la base larga e la punta stretta, sempre.",
    distractorWhy: { "i predatori vivono molto più a lungo": "Capita spesso, ma non spiega perché siano numericamente pochi.", "le prede si riproducono in fretta": "È vero e aiuta, ma la causa è la perdita di energia lungo la catena.", "i predatori mangiano una volta sola": "Mangiano regolarmente: è quanto cibo esiste a limitarli." } },
  { topic: "ambiente", difficulty: 2, difficulty8: true,
    prompt: "Perché piantare alberi aiuta contro l'aumento dell'anidride carbonica?",
    answer: "gli alberi la assorbono crescendo", distractors: ["gli alberi bloccano il vento caldo", "gli alberi producono più pioggia", "gli alberi riflettono la luce solare"],
    explanation: "Crescendo, l'albero costruisce il proprio legno usando il carbonio preso dall'aria: un tronco è in buona parte anidride carbonica solidificata. Bruciarlo la restituisce tutta.",
    distractorWhy: { "gli alberi bloccano il vento caldo": "Riparano dal vento, ma questo non toglie gas dall'aria.", "gli alberi producono più pioggia": "Influenzano il clima locale, ma la pioggia non rimuove il gas accumulato.", "gli alberi riflettono la luce solare": "Una foresta scura assorbe più luce di un prato chiaro." } },
  { topic: "terra-universo", difficulty: 2, difficulty8: true,
    prompt: "Perché di notte fa più freddo?",
    answer: "il suolo perde il calore accumulato", distractors: ["la Terra si allontana un poco dal Sole", "l'aria diventa più pesante", "il vento cambia direzione"],
    explanation: "Di giorno il suolo incassa calore, di notte lo irradia verso il cielo senza riceverne. È anche il motivo per cui una notte nuvolosa è più mite: le nuvole rimandano indietro parte di quel calore.",
    distractorWhy: { "la Terra si allontana un poco dal Sole": "La distanza non cambia in modo apprezzabile nel giro di una notte.", "l'aria diventa più pesante": "L'aria fredda è più pesante: è una conseguenza, non la causa.", "il vento cambia direzione": "Può accadere, ma il raffreddamento notturno avviene anche senza vento." } },
];
