// Storia — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Seconda materia convertita alla regola delle dispense
// (`docs/REGOLA_DISPENSE.md`), e quella su cui il committente l'aveva chiesta:
//
//   «Nella storia si deve preparare un documento da presentare allo studente
//   dove si racconta un contesto preciso e dettagliato. Solo dopo si può fare
//   una domanda.»
//
// Le diciassette dispense di storia stanno in `godot/scripts/game/dispense.gd`.
// Qui ci sono le domande che le applicano, e ognuna dichiara `applica`.
//
// ## La forma che si è cercata, e perché
//
// La domanda buona di storia non è «in che anno cadde l'Impero d'Occidente»:
// quella o si sa o non si sa. È **applicare a un caso nuovo un criterio che il
// documento ha spiegato**:
//
//   il documento dice   «chi semina deve tornare a raccogliere»
//   la domanda chiede   «un archeologo trova macine, semi e una capra recintata:
//                        in quale periodo si trova?»
//
// Chi ha letto il documento risponde ragionando, e chi non l'ha letto non
// indovina. È la differenza fra una prova e un quiz.
//
// Restano alcune domande di richiamo — un nome, una parola tecnica — e su quelle
// `dispense_audit` applica il controllo più severo di tutti: **la risposta deve
// comparire nel testo della dispensa dichiarata**. Se non c'è, la domanda è
// impossibile per costruzione, e nessuna delle guardie precedenti se ne
// accorgeva.
//
// ## Regole di scrittura
//
// Le stesse degli altri lotti — fascia dichiarata con `difficulty8`, risposta mai
// più lunga di quattro caratteri del distrattore più lungo, ogni distrattore con
// il suo perché — più due che appartengono a questa materia:
//
//  1. **Niente che il documento non abbia detto.** Un item di fascia 1-4 applica
//     la banda bassa e non può usare parole introdotte nella banda alta: alla
//     quarta fascia gli Egizi non hanno ancora incontrato i geroglifici.
//  2. **I distrattori sono errori storici plausibili**, non alternative assurde:
//     confondere repubblica e impero, prendere il 476 per un crollo improvviso,
//     leggere le pitture rupestri come decorazione.

export const STORIA_APPLICAZIONI = [

  // ========================================================== PREISTORIA
  { topic: "preistoria", difficulty: 1, difficulty8: true, applica: "storia-preistoria-base",
    prompt: "Un gruppo del Paleolitico esaurisce la selvaggina della sua valle. Che cosa fa?",
    answer: "Si sposta in un'altra valle", distractors: ["Semina il grano per l'anno dopo", "Costruisce un villaggio stabile", "Alleva gli animali rimasti"],
    explanation: "Nel Paleolitico il cibo si prende dove si trova: quando finisce non c'è nessun modo di farne crescere dell'altro, e restare non è possibile.",
    distractorWhy: { "Semina il grano per l'anno dopo": "Seminare è la novità del Neolitico: nel Paleolitico non si produce cibo, lo si raccoglie.", "Costruisce un villaggio stabile": "I villaggi fissi nascono quando si coltiva, perché chi semina deve tornare a raccogliere.", "Alleva gli animali rimasti": "Anche l'allevamento arriva con il Neolitico: prima gli animali si inseguono, non si tengono." } },

  { topic: "preistoria", difficulty: 2, difficulty8: true, applica: "storia-preistoria-base",
    format: "short_answer",
    prompt: "In quale periodo della preistoria nascono l'agricoltura e l'allevamento?",
    answer: "Neolitico", accept: ["neolitico", "il neolitico", "nel neolitico"],
    explanation: "«Pietra nuova»: comincia circa diecimila anni fa, e con la semina arriva la conseguenza che cambia tutto, cioè restare fermi in un luogo." },

  { topic: "preistoria", difficulty: 3, difficulty8: true, applica: "storia-preistoria-base",
    prompt: "Il documento dice che con il fuoco l'uomo cambia l'ambiente invece di subirlo. Quale di questi gesti è dello stesso tipo?",
    answer: "Scavare un canale per irrigare", distractors: ["Raccogliere i frutti già maturi", "Seguire un branco che migra", "Ripararsi in una caverna già aperta"],
    explanation: "Il canale modifica il posto per adattarlo a sé, come il fuoco: gli altri tre prendono il posto così com'è e si adattano a lui.",
    distractorWhy: { "Raccogliere i frutti già maturi": "Prende quello che l'ambiente offre quando lo offre: non lo cambia in nessun modo.", "Seguire un branco che migra": "È l'ambiente a decidere dove si va: l'uomo si adatta al movimento degli animali.", "Ripararsi in una caverna già aperta": "Usa un riparo che c'era: diventerebbe un cambiamento solo scavandolo o costruendolo." } },

  { topic: "preistoria", difficulty: 4, difficulty8: true, applica: "storia-preistoria-base",
    prompt: "Un archeologo trova in un villaggio delle macine, dei semi e un recinto per capre. In quale periodo si trova?",
    answer: "Neolitico", distractors: ["Paleolitico", "Prima del fuoco", "Dopo la scrittura"],
    explanation: "Macine, semi e recinti dicono che quel cibo veniva prodotto e non solo trovato: agricoltura e allevamento sono la definizione stessa del Neolitico.",
    distractorWhy: { "Paleolitico": "Lì il cibo si prende dove si trova: non ci sarebbero né semi conservati né animali tenuti in un recinto.", "Prima del fuoco": "Il fuoco arriva circa 400.000 anni fa, molto prima dell'agricoltura: quel villaggio è enormemente più recente.", "Dopo la scrittura": "Con la scrittura finisce la preistoria: qui non c'è nessun segno inciso, solo oggetti." } },

  { topic: "preistoria", difficulty: 5, difficulty8: true, applica: "storia-preistoria-alta",
    prompt: "Che cosa, nella posizione delle pitture rupestri, fa pensare a un uso rituale?",
    answer: "Stanno in gallerie profonde e buie", distractors: ["Stanno all'ingresso, ben visibili", "Stanno sui muri delle capanne", "Stanno sempre accanto ai focolari"],
    explanation: "Per dipingerle bisognava andarci apposta portandosi il fuoco, in punti dove nessuno viveva: non erano lì per essere guardate ogni giorno.",
    distractorWhy: { "Stanno all'ingresso, ben visibili": "Se fosse così sarebbero proprio un abbellimento: invece si trovano nelle parti interne della grotta.", "Stanno sui muri delle capanne": "Le pitture di cui parliamo sono nelle grotte, sulla roccia, non in luoghi di abitazione.", "Stanno sempre accanto ai focolari": "I focolari stanno dove si viveva, cioè verso l'imboccatura: le pitture sono molto più dentro." } },

  { topic: "preistoria", difficulty: 6, difficulty8: true, applica: "storia-preistoria-alta",
    format: "short_answer",
    prompt: "Come si chiama una grande pietra piantata verticalmente nel terreno, tipica del Neolitico?",
    answer: "menhir", accept: ["un menhir", "il menhir"],
    explanation: "Dal bretone «pietra lunga». Quello che dice non è tanto la forma quanto il peso: spostarla richiedeva centinaia di persone organizzate." },

  { topic: "preistoria", difficulty: 7, difficulty8: true, applica: "storia-preistoria-alta",
    prompt: "Perché la lavorazione del bronzo obbligò a commerciare lontano?",
    answer: "Rame e stagno non stanno negli stessi posti", distractors: ["Il bronzo era troppo pesante da trasportare", "Soltanto pochi re sapevano fonderlo", "Serviva legna di un'unica specie di albero"],
    explanation: "Il bronzo è rame mescolato a stagno, e i due metalli si trovano in regioni diverse: per farne uno bisogna per forza scambiare a grande distanza.",
    distractorWhy: { "Il bronzo era troppo pesante da trasportare": "Il peso è un problema di trasporto, non la ragione per cui bisogna andare lontano a procurarsi gli ingredienti.", "Soltanto pochi re sapevano fonderlo": "Chi sa fondere spiega chi comanda sul metallo, non perché le materie prime vengano da lontano.", "Serviva legna di un'unica specie di albero": "Per la fusione serve calore, e la legna si trova quasi ovunque: il vincolo è sui metalli." } },

  // ============================================================= CIVILTA
  { topic: "civilta", difficulty: 2, difficulty8: true, applica: "storia-civilta-base",
    prompt: "Perché un raccolto che avanza permette la nascita di mestieri nuovi?",
    answer: "Perché mantiene chi non coltiva", distractors: ["Perché il cibo si conserva più a lungo", "Perché la terra diventa più fertile", "Perché i villaggi si allargano da soli"],
    explanation: "Il cibo in più nutre chi fa altro: un vasaio, un sacerdote, un soldato. Finché ognuno produce appena quel che gli serve, devono coltivare tutti.",
    distractorWhy: { "Perché il cibo si conserva più a lungo": "La conservazione serve a non perdere l'eccedenza, ma da sola non libera nessuno dal lavoro dei campi.", "Perché la terra diventa più fertile": "La fertilità è la causa dell'eccedenza, non la sua conseguenza: qui si chiede che cosa produce l'eccedenza.", "Perché i villaggi si allargano da soli": "Un villaggio più grande resta un villaggio di contadini se nessuno può smettere di coltivare." } },

  { topic: "civilta", difficulty: 3, difficulty8: true, applica: "storia-civilta-base",
    prompt: "Le prime tavolette sumere sono elenchi di sacchi di grano e di pecore. Che cosa dice questo sulla scrittura?",
    answer: "Che nacque per tenere i conti", distractors: ["Che i Sumeri allevavano moltissimo", "Che le storie si scrivevano altrove", "Che la scrittura era un segreto sacro"],
    explanation: "Le prime cose messe per iscritto sono ricevute di magazzino: la scrittura nasce come strumento di amministrazione e impara a raccontare molto dopo.",
    distractorWhy: { "Che i Sumeri allevavano moltissimo": "Legge le tavolette come una notizia sull'economia invece che come una prova sull'uso della scrittura.", "Che le storie si scrivevano altrove": "Non c'è nessuna traccia di racconti scritti su altri supporti in quel periodo: i testi narrativi arrivano secoli dopo.", "Che la scrittura era un segreto sacro": "Sarebbe il contrario di un uso di magazzino, che è aperto a chi amministra e serve a rendere controllabili le merci." } },

  { topic: "civilta", difficulty: 4, difficulty8: true, applica: "storia-civilta-base",
    format: "short_answer",
    prompt: "In quale regione, fra il Tigri e l'Eufrate, nacquero i Sumeri e poi i Babilonesi?",
    answer: "Mesopotamia", accept: ["la mesopotamia", "in mesopotamia"],
    explanation: "Il nome significa «terra fra i fiumi», e dice già la causa: due grandi corsi d'acqua che irrigano, concimano con il limo e fanno da strada." },

  { topic: "civilta", difficulty: 4, difficulty8: true, applica: "storia-civilta-base",
    prompt: "Quale dono del fiume rifà fertile il terreno ogni anno senza che nessuno lavori?",
    answer: "Il limo lasciato dalla piena", distractors: ["L'acqua portata dai canali", "La via d'acqua per i battelli carichi", "Il pesce che si trova sulle rive"],
    explanation: "Ritirandosi, la piena lascia sui campi uno strato di fango ricchissimo: è concime che arriva da solo, ogni anno, senza fatica e senza costo.",
    distractorWhy: { "L'acqua portata dai canali": "L'irrigazione è un vantaggio vero, ma i canali bisogna scavarli e mantenerli: non arriva da sola.", "La via d'acqua per i battelli carichi": "Il trasporto è il terzo dono del fiume, e non ha niente a che fare con la fertilità della terra.", "Il pesce che si trova sulle rive": "È cibo in più, non fertilità: non rende coltivabile nessun campo." } },

  { topic: "civilta", difficulty: 5, difficulty8: true, applica: "storia-civilta-alta",
    prompt: "Perché mettere le leggi per iscritto cambia il rapporto fra chi giudica e chi è giudicato?",
    answer: "Perché la regola diventa controllabile", distractors: ["Perché le pene diventano più leggere", "Perché il giudice smette di servire", "Perché la legge non cambia mai più"],
    explanation: "Finché la regola sta a voce, cambia da un giudice all'altro e nessuno può dimostrare che abbia sbagliato. Incisa su una pietra pubblica, chiunque va a leggerla.",
    distractorWhy: { "Perché le pene diventano più leggere": "Le leggi di Hammurabi sono durissime: scriverle le rende pubbliche, non miti.", "Perché il giudice smette di servire": "Il giudice continua a decidere i casi: quello che cambia è che ora si può verificare su quale regola.", "Perché la legge non cambia mai più": "Anche una legge scritta si può sostituire: il vantaggio è che finché vale, vale uguale per tutti." } },

  { topic: "civilta", difficulty: 7, difficulty8: true, applica: "storia-civilta-alta",
    prompt: "Perché l'alfabeto fenicio tolse potere a chi scriveva di mestiere?",
    answer: "Perché con venti segni impara quasi chiunque", distractors: ["Perché i Fenici proibirono il cuneiforme", "Perché la pietra costava meno del papiro", "Perché gli scribi erano quasi tutti stranieri"],
    explanation: "Il cuneiforme e i geroglifici richiedono centinaia di segni e anni di scuola, quindi scrivere è mestiere di pochi. Con un segno per suono si impara in settimane.",
    distractorWhy: { "Perché i Fenici proibirono il cuneiforme": "Nessuno proibì niente: l'alfabeto si diffuse perché era più comodo, soprattutto per i commercianti.", "Perché la pietra costava meno del papiro": "Il costo del supporto non c'entra: quello che cambia è quanti segni bisogna imparare.", "Perché gli scribi erano quasi tutti stranieri": "Gli scribi erano funzionari locali, e il loro potere veniva dalla rarità della competenza, non dalla provenienza." } },

  { topic: "civilta", difficulty: 8, difficulty8: true, applica: "storia-civilta-alta",
    format: "short_answer",
    prompt: "Quale popolo di navigatori del Mediterraneo diffuse un alfabeto di poco più di venti segni?",
    answer: "Fenici", accept: ["i fenici", "fenici"],
    explanation: "Commerciavano in porti diversi con gente diversa e avevano bisogno di conti rapidi: da quell'alfabeto derivano il greco, il latino e le nostre lettere." },

  // =============================================================== EGIZI
  { topic: "egizi", difficulty: 1, difficulty8: true, applica: "storia-egizi-base",
    prompt: "Perché la striscia di terra lungo il Nilo è verde mentre tutto il resto è deserto?",
    answer: "Perché la piena vi lascia il limo", distractors: ["Perché lì piove molto più spesso", "Perché il vento porta via la sabbia", "Perché il sole vi arriva più debole"],
    explanation: "Ogni anno il fiume esce dal suo letto e ritirandosi deposita un fango fertile: fuori da quella striscia il limo non arriva, e resta deserto.",
    distractorWhy: { "Perché lì piove molto più spesso": "In Egitto piove pochissimo ovunque: l'acqua che conta arriva dal fiume, non dal cielo.", "Perché il vento porta via la sabbia": "Togliere sabbia non renderebbe fertile niente: sotto ci sarebbe altro deserto.", "Perché il sole vi arriva più debole": "Il sole è lo stesso su tutta la regione: la differenza fra verde e deserto la fa l'acqua con il suo limo." } },

  { topic: "egizi", difficulty: 3, difficulty8: true, applica: "storia-egizi-base",
    format: "short_answer",
    prompt: "Come si chiamava il sovrano dell'Egitto, considerato anche divino?",
    answer: "faraone", accept: ["il faraone", "un faraone"],
    explanation: "Non era soltanto un capo politico: si credeva che da lui dipendesse l'ordine del mondo, e perfino il ritorno regolare della piena." },

  { topic: "egizi", difficulty: 4, difficulty8: true, applica: "storia-egizi-base",
    prompt: "Perché per gli Egizi contava che la piena fosse regolare, e non solo che portasse il limo?",
    answer: "Perché così si poteva organizzare", distractors: ["Perché rendeva l'acqua più pulita", "Perché faceva arretrare il deserto", "Perché riempiva i pozzi di tutti i villaggi"],
    explanation: "Una cosa che torna sempre nello stesso momento si può prevedere: si sa quando seminare, quando raccogliere e quando scavare i canali.",
    distractorWhy: { "Perché rendeva l'acqua più pulita": "La piena porta fango, non limpidezza: il suo valore è il concime che deposita.", "Perché faceva arretrare il deserto": "Il deserto resta dov'è: la piena fertilizza la striscia che raggiunge, non la allarga.", "Perché riempiva i pozzi di tutti i villaggi": "L'acqua da bere era un problema minore: quello grande era far crescere il cibo su una terra di deserto." } },

  { topic: "egizi", difficulty: 4, difficulty8: true, applica: "storia-egizi-base",
    prompt: "Migliaia di uomini lavorano per anni a una sola piramide. Che cosa dice questo, prima ancora della religione?",
    answer: "Quanto potere aveva chi la ordinava", distractors: ["Che la pietra era facile da tagliare", "Che il lavoro veniva pagato molto bene", "Che nel deserto non c'erano altri lavori possibili"],
    explanation: "Per tenere migliaia di persone su un unico cantiere per anni bisogna poterle comandare e nutrire: la piramide misura l'organizzazione del faraone.",
    distractorWhy: { "Che la pietra era facile da tagliare": "Tagliare e spostare blocchi enormi era difficilissimo: è proprio la difficoltà a rendere significativo lo sforzo.", "Che il lavoro veniva pagato molto bene": "I lavoratori ricevevano razioni, e comunque la paga non spiegherebbe come si coordinano migliaia di persone per anni.", "Che nel deserto non c'erano altri lavori possibili": "La valle del Nilo era piena di lavoro agricolo: togliere braccia ai campi era un costo, non un ripiego." } },

  { topic: "egizi", difficulty: 5, difficulty8: true, applica: "storia-egizi-alta",
    format: "short_answer",
    prompt: "Come si chiamava la scrittura sacra egizia, incisa sulla pietra dei templi e delle tombe?",
    answer: "geroglifici", accept: ["geroglifica", "i geroglifici", "scrittura geroglifica"],
    explanation: "Centinaia di segni, alcuni per cose e altri per suoni. Per l'uso di ogni giorno si scriveva invece sul papiro, molto più rapido." },

  { topic: "egizi", difficulty: 6, difficulty8: true, applica: "storia-egizi-alta",
    prompt: "Perché la geometria egizia nasce da un lavoro di catasto e non dallo studio astratto?",
    answer: "Perché la piena cancellava i confini", distractors: ["Perché mancavano i numeri per contare", "Perché i templi andavano orientati al sole", "Perché le piramidi chiedevano calcoli esatti"],
    explanation: "Ogni anno, ritirata l'acqua, bisognava restituire a ciascuno il suo pezzo esatto: da lì corde annodate, angoli retti e regole per le aree.",
    distractorWhy: { "Perché mancavano i numeri per contare": "Gli Egizi avevano un sistema di numerazione ben sviluppato: il problema non era contare ma misurare il terreno.", "Perché i templi andavano orientati al sole": "L'orientamento riguarda l'astronomia, ed è un uso successivo: l'origine sta nella misura dei campi.", "Perché le piramidi chiedevano calcoli esatti": "I cantieri usarono la geometria che già esisteva: il problema che l'ha fatta nascere si ripresentava ogni anno in ogni campo." } },

  { topic: "egizi", difficulty: 6, difficulty8: true, applica: "storia-egizi-alta",
    prompt: "Per decifrare i geroglifici si partì dal testo greco della stele di Rosetta. Perché proprio da quello?",
    answer: "Perché il greco si sapeva già leggere", distractors: ["Perché era il più lungo dei tre testi", "Perché era inciso più in profondità", "Perché i geroglifici erano rovinati"],
    explanation: "Un documento sconosciuto non si indovina: lo si aggancia a qualcosa di già noto. Il greco antico era leggibile, e i tre testi dicevano la stessa cosa.",
    distractorWhy: { "Perché era il più lungo dei tre testi": "La lunghezza non aiuta se non si capisce la lingua: quello che serviva era un testo comprensibile.", "Perché era inciso più in profondità": "La profondità dell'incisione riguarda la conservazione, non la possibilità di leggerlo.", "Perché i geroglifici erano rovinati": "La parte geroglifica è incompleta ma leggibile: il problema era che nessuno ne conoscesse più il significato." } },

  // ============================================================== GRECIA
  { topic: "grecia", difficulty: 2, difficulty8: true, applica: "storia-grecia-base",
    prompt: "Perché in Grecia ogni pianura tendeva a formare una comunità a sé?",
    answer: "Perché le montagne le separavano", distractors: ["Perché i fiumi erano troppo larghi", "Perché il clima cambiava ogni valle", "Perché un re aveva diviso il paese"],
    explanation: "Arrivare alla pianura vicina via terra era lungo e faticoso: le comunità crescevano separate, e il mare era una strada più facile delle montagne.",
    distractorWhy: { "Perché i fiumi erano troppo larghi": "La Grecia non ha grandi fiumi: è proprio l'assenza di una valle fluviale a distinguerla da Egitto e Mesopotamia.", "Perché il clima cambiava ogni valle": "Il clima mediterraneo è simile in tutta la regione: a dividere è il rilievo, non il tempo che fa.", "Perché un re aveva diviso il paese": "Non c'era nessun re di tutta la Grecia: la divisione nasce dalla geografia, non da una decisione." } },

  { topic: "grecia", difficulty: 3, difficulty8: true, applica: "storia-grecia-base",
    format: "short_answer",
    prompt: "Come si chiamava la piazza centrale della pòlis, dove si commerciava e si discutevano le decisioni?",
    answer: "agorà", accept: ["agora", "l'agorà", "l agora"],
    explanation: "Che il luogo del mercato e quello della politica coincidessero non è un caso: decidere insieme era un'attività quotidiana, non un evento raro." },

  { topic: "grecia", difficulty: 4, difficulty8: true, applica: "storia-grecia-base",
    prompt: "Che cosa era una colonia greca rispetto alla città che l'aveva fondata?",
    answer: "Una città nuova e indipendente", distractors: ["Una provincia che pagava tributi", "Un accampamento militare stagionale", "Un porto amministrato dalla madrepatria"],
    explanation: "Restava legata per lingua, dèi e affetti, ma si dava leggi proprie: una figlia, non una provincia. È per questo che il mondo greco si allarga senza diventare un impero.",
    distractorWhy: { "Una provincia che pagava tributi": "Descrive il rapporto tipico di un impero, che è esattamente quello che i Greci non costruirono.", "Un accampamento militare stagionale": "Chi partiva andava a restare: portava famiglie e attrezzi, e fondava una città vera.", "Un porto amministrato dalla madrepatria": "L'amministrazione era locale fin dall'inizio: il legame era culturale, non di governo." } },

  { topic: "grecia", difficulty: 6, difficulty8: true, applica: "storia-grecia-alta",
    prompt: "Ad Atene molte cariche si assegnavano per sorteggio. A quale problema rispondeva?",
    answer: "Un sorteggio non si può comprare", distractors: ["Le assemblee duravano troppo tempo", "I cittadini non sapevano contare i voti", "Nessuno voleva ricoprire le cariche"],
    explanation: "Con l'elezione chi ha denaro e clientele parte avvantaggiato; con il sorteggio no. È una difesa contro la conquista delle cariche da parte dei ricchi.",
    distractorWhy: { "Le assemblee duravano troppo tempo": "Il sorteggio riguarda chi ottiene la carica, non quanto si discute prima di decidere.", "I cittadini non sapevano contare i voti": "Le votazioni ad Atene erano frequenti e i conteggi ordinari: la difficoltà non era aritmetica.", "Nessuno voleva ricoprire le cariche": "Le cariche erano ambite, ed è proprio per questo che si temeva finissero sempre alle stesse famiglie." } },

  { topic: "grecia", difficulty: 6, difficulty8: true, applica: "storia-grecia-alta",
    format: "short_answer",
    prompt: "Come si chiamava la popolazione sottomessa che lavorava la terra al posto degli Spartani?",
    answer: "iloti", accept: ["gli iloti", "ilota"],
    explanation: "Erano molti più dei cittadini spartani, e il timore di una loro rivolta spiega perché Sparta scelse di organizzarsi prima di tutto come un esercito." },

  { topic: "grecia", difficulty: 7, difficulty8: true, applica: "storia-grecia-alta",
    prompt: "Perché Sparta scelse di organizzarsi prima di tutto come un esercito?",
    answer: "Perché gli iloti erano molti più di loro", distractors: ["Perché la terra spartana era sterile", "Perché non aveva mura da difendere", "Perché voleva vincere le olimpiadi"],
    explanation: "Una minoranza che vive del lavoro forzato di una maggioranza ha paura di una rivolta: la durezza dell'educazione spartana è la risposta a quel timore.",
    distractorWhy: { "Perché la terra spartana era sterile": "La pianura spartana era fra le più fertili della Grecia: è proprio per questo che valeva la pena controllarla.", "Perché non aveva mura da difendere": "Che Sparta non avesse mura è una conseguenza di quella scelta — si vantava che le mura fossero i suoi uomini — non la causa.", "Perché voleva vincere le olimpiadi": "Gli atleti spartani vincevano spesso, ma nessuna città costruisce un sistema sociale intero per una gara." } },

  // ================================================================ ROMA
  { topic: "roma", difficulty: 2, difficulty8: true, applica: "storia-roma-base",
    prompt: "Perché un guado sul Tevere rese importante il luogo in cui nacque Roma?",
    answer: "Perché tutti dovevano passare di lì", distractors: ["Perché l'acqua era potabile solo lì", "Perché il fiume la difendeva da ogni lato", "Perché le navi da guerra vi attraccavano"],
    explanation: "Un guado è un imbuto: tutto ciò che si sposta fra nord e sud deve attraversare in quel punto, e chi lo controlla vede passare merci, eserciti e notizie.",
    distractorWhy: { "Perché l'acqua era potabile solo lì": "L'acqua del Tevere si poteva prendere lungo tutto il corso: il vantaggio del guado è il passaggio, non la bevuta.", "Perché il fiume la difendeva da ogni lato": "Il fiume passa da un lato solo: la difesa veniva dalle colline, e comunque un guado è un punto di passaggio, non una barriera.", "Perché le navi da guerra vi attraccavano": "Un guado è dove il fiume è basso, cioè il punto peggiore per una nave: sono due cose incompatibili." } },

  { topic: "roma", difficulty: 3, difficulty8: true, applica: "storia-roma-base",
    format: "short_answer",
    prompt: "Da quale lingua di Roma derivano l'italiano, lo spagnolo e il francese?",
    answer: "latino", accept: ["il latino", "dal latino"],
    explanation: "Era la lingua del Lazio e si diffuse con le conquiste: dove arrivavano le strade e l'amministrazione, arrivava anche la lingua in cui erano scritte." },

  { topic: "roma", difficulty: 4, difficulty8: true, applica: "storia-roma-base",
    prompt: "I consoli erano sempre due e restavano in carica un anno solo. Contro quale rischio era costruita la regola?",
    answer: "Che uno tornasse a farsi re", distractors: ["Che i plebei prendessero il senato", "Che le guerre durassero troppo", "Che i patrizi perdessero le terre"],
    explanation: "La repubblica nasce cacciando l'ultimo re, e si difende dividendo il potere: due persone si controllano a vicenda, e un anno finisce presto.",
    distractorWhy: { "Che i plebei prendessero il senato": "Per i plebei c'erano i tribuni, dal 494 a.C.: il numero e la durata dei consoli riguardano un'altra paura.", "Che le guerre durassero troppo": "L'anno di carica complicava anzi le campagne lunghe: era un costo accettato, non lo scopo.", "Che i patrizi perdessero le terre": "Le magistrature erano in mano ai patrizi: la regola limitava proprio loro, non li proteggeva." } },

  { topic: "roma", difficulty: 5, difficulty8: true, applica: "storia-roma-alta",
    prompt: "Una strada consolare non accorcia la distanza fra due città. Che cosa accorcia?",
    answer: "Il tempo per percorrerla", distractors: ["Il costo delle pietre miliari", "Il numero di legioni necessarie", "La fatica dei muli da soma"],
    explanation: "Una rivolta a cinquecento chilometri è un problema diverso a seconda che le legioni ci mettano un mese o otto giorni: la strada compra tempo di reazione.",
    distractorWhy: { "Il costo delle pietre miliari": "Le pietre miliari sono un segnale sulla strada, e costruire una strada costa molto di più che non farla.", "Il numero di legioni necessarie": "Le legioni servono lo stesso: cambia quanto in fretta arrivano dove serve.", "La fatica dei muli da soma": "Il carico si fa più agevole, ma il vantaggio che decide è un altro, e si misura in giorni." } },

  { topic: "roma", difficulty: 7, difficulty8: true, applica: "storia-roma-alta",
    prompt: "Perché a un popolo conquistato conveniva integrarsi invece di ribellarsi?",
    answer: "Perché la cittadinanza si poteva ottenere", distractors: ["Perché le legioni erano davvero invincibili", "Perché Roma proibiva ogni altra lingua", "Perché le tasse romane erano quasi nulle"],
    explanation: "Non era un privilegio chiuso dalla nascita: si poteva ottenere, per esempio con il servizio militare, e dava diritti e protezione legale concreti.",
    distractorWhy: { "Perché le legioni erano davvero invincibili": "Roma perse molte battaglie: la sola paura non spiega perché tanti popoli restarono dentro per secoli.", "Perché Roma proibiva ogni altra lingua": "Le lingue locali continuarono a esistere a lungo: l'integrazione era offerta, non imposta parlando.", "Perché le tasse romane erano quasi nulle": "Le tasse c'erano ed erano pesanti: quello che le bilanciava era l'accesso ai diritti." } },

  { topic: "roma", difficulty: 7, difficulty8: true, applica: "storia-roma-alta",
    prompt: "Perché il 476 d.C. viene chiamato una data di comodo?",
    answer: "Perché niente finì in quel giorno", distractors: ["Perché le fonti la datano male", "Perché la scelse un imperatore", "Perché cadde anche l'Oriente"],
    explanation: "Le città si erano svuotate lentamente per decenni, e l'impero d'Oriente proseguì per altri mille anni: la data serve a mettere ordine, non a descrivere un crollo.",
    distractorWhy: { "Perché le fonti la datano male": "La deposizione dell'ultimo imperatore d'Occidente è ben documentata: il problema non è la data, è che cosa si pretende che significhi.", "Perché la scelse un imperatore": "L'hanno scelta gli storici molto tempo dopo, come confine fra due periodi.", "Perché cadde anche l'Oriente": "L'impero d'Oriente non cadde affatto nel 476: continuò per circa mille anni ancora." } },

  { topic: "roma", difficulty: 8, difficulty8: true, applica: "storia-roma-alta",
    format: "numeric_input",
    prompt: "In quale anno dopo Cristo fu deposto l'ultimo imperatore d'Occidente, la data che si usa come inizio del Medioevo?",
    answer: "476",
    explanation: "È una convenzione utile e non un crollo improvviso: serve a segnare un confine fra due periodi che in realtà sfumano l'uno nell'altro." },

  // ============================================================ MEDIOEVO
  { topic: "medioevo", difficulty: 6, difficulty8: true, applica: "storia-medioevo-alta",
    prompt: "Caduti i commerci a lunga distanza, perché la terra diventa la ricchezza principale?",
    answer: "Perché il denaro non compra quasi nulla", distractors: ["Perché i signori la requisirono tutta", "Perché l'oro era stato portato via", "Perché coltivare era diventato facile"],
    explanation: "Se non c'è quasi niente da comprare, avere monete serve a poco: conta ciò che dà da mangiare da sé, cioè il campo e chi lo lavora.",
    distractorWhy: { "Perché i signori la requisirono tutta": "La concentrazione della terra nelle mani dei signori è una conseguenza di quel mondo, non la causa del valore della terra.", "Perché l'oro era stato portato via": "L'oro non sparì: semplicemente smise di essere utile, perché mancavano i mercati in cui spenderlo.", "Perché coltivare era diventato facile": "Coltivare restò durissimo: il valore della terra non viene dalla comodità ma dal fatto che nutre." } },

  { topic: "medioevo", difficulty: 7, difficulty8: true, applica: "storia-medioevo-alta",
    format: "short_answer",
    prompt: "Come si chiamavano i contadini legati alla terra su cui erano nati, che non potevano lasciarla?",
    answer: "servi della gleba", accept: ["i servi della gleba", "servi"],
    explanation: "Non erano schiavi comprabili uno per uno: erano vincolati al fondo, e cambiavano proprietario insieme al terreno quando questo passava di mano." },

  { topic: "medioevo", difficulty: 7, difficulty8: true, applica: "storia-medioevo-alta",
    prompt: "Perché senza i monaci amanuensi molti testi antichi non sarebbero arrivati fino a noi?",
    answer: "Perché la pergamena si consuma", distractors: ["Perché i testi antichi erano proibiti", "Perché nessuno sapeva più il latino", "Perché gli originali erano in Oriente"],
    explanation: "Nessun libro dura duemila anni da solo: se non viene ricopiato prima di rovinarsi, sparisce. Copiare a mano era l'unico modo di moltiplicarlo.",
    distractorWhy: { "Perché i testi antichi erano proibiti": "Erano proprio i monasteri a conservarli e a studiarli: non c'era nessun divieto da aggirare.", "Perché nessuno sapeva più il latino": "Nei monasteri il latino si sapeva benissimo: era la lingua in cui si leggeva e si copiava.", "Perché gli originali erano in Oriente": "Alcuni sì e molti no, ma il problema è materiale: anche un originale vicino si sarebbe comunque consumato." } },

  { topic: "medioevo", difficulty: 8, difficulty8: true, applica: "storia-medioevo-alta",
    prompt: "Arriva la stampa a caratteri mobili, a metà del Quattrocento. Che cosa cambia per primo?",
    answer: "Quanto costa un libro", distractors: ["Chi decide che cosa scrivere", "La lingua in cui si scrive", "Il numero dei monasteri"],
    explanation: "Copiare a mano richiedeva mesi, e un volume costava come un piccolo podere. Stampandolo il prezzo crolla, e da lì il sapere cambia velocità di diffusione.",
    distractorWhy: { "Chi decide che cosa scrivere": "I controlli su ciò che si pubblica cambiano dopo, proprio come reazione al fatto che i libri erano diventati tanti.", "La lingua in cui si scrive": "Il passaggio dal latino alle lingue volgari è un processo suo, cominciato prima e proseguito per altre ragioni.", "Il numero dei monasteri": "I monasteri restano: quello che perdono è il monopolio sulla riproduzione dei testi." } },

  // ========================================================== CRONOLOGIA
  { topic: "cronologia", difficulty: 1, difficulty8: true, applica: "storia-cronologia-base",
    format: "numeric_input",
    prompt: "Quanti anni ci sono in due secoli e mezzo?",
    answer: "250",
    explanation: "Un secolo dura cento anni, quindi due ne fanno duecento e mezzo secolo ne fa cinquanta." },

  { topic: "cronologia", difficulty: 2, difficulty8: true, applica: "storia-cronologia-base",
    format: "numeric_input",
    prompt: "Quanti decenni ci sono in un millennio?",
    answer: "100",
    explanation: "Un millennio dura mille anni e un decennio dieci: mille diviso dieci fa cento. Sono anche dieci secoli, e ogni secolo contiene dieci decenni." },

  { topic: "cronologia", difficulty: 4, difficulty8: true, applica: "storia-cronologia-base",
    prompt: "A quale secolo appartiene l'anno 1215?",
    answer: "XIII secolo", distractors: ["XII secolo", "XIV secolo", "XXI secolo"],
    explanation: "Il conteggio parte da uno: il primo secolo finisce nel 100, quindi agli anni che cominciano per 12 corrisponde il tredicesimo secolo.",
    distractorWhy: { "XII secolo": "Legge le centinaia senza aggiungere uno: il XII secolo va dal 1101 al 1200, e il 1215 è già oltre.", "XIV secolo": "Ha aggiunto due invece di uno: il XIV secolo comincia nel 1301.", "XXI secolo": "È il secolo in cui viviamo noi: il 1215 è più di ottocento anni prima." } },

  { topic: "cronologia", difficulty: 4, difficulty8: true, applica: "storia-cronologia-base",
    prompt: "Quale dei due anni è il più antico: il 480 a.C. o il 44 a.C.?",
    answer: "il 480 a.C.", distractors: ["il 44 a.C.", "sono contemporanei", "non si può stabilire"],
    explanation: "Gli anni avanti Cristo si contano all'indietro: più il numero è grande, più il fatto è lontano da noi. È l'unica numerazione della storia che va al contrario.",
    distractorWhy: { "il 44 a.C.": "Applica la regola dei numeri normali: fra gli anni a.C. il più piccolo è il più vicino a noi, quindi il più recente.", "sono contemporanei": "Li separano più di quattro secoli: il 480 a.C. è l'età delle guerre persiane, il 44 a.C. quella di Cesare.", "non si può stabilire": "Si stabilisce benissimo: entrambi sono avanti Cristo, e basta confrontare i due numeri sapendo che vanno al contrario." } },

  { topic: "cronologia", difficulty: 5, difficulty8: true, applica: "storia-cronologia-alta",
    format: "numeric_input",
    prompt: "Quanti anni passano fra il 100 a.C. e il 200 d.C.?",
    answer: "300",
    explanation: "L'intervallo attraversa il punto di partenza della numerazione, quindi i due tratti si sommano: cento fino a Cristo, poi altri duecento." },

  { topic: "cronologia", difficulty: 5, difficulty8: true, applica: "storia-cronologia-alta",
    prompt: "Perché fra due date ai lati opposti della nascita di Cristo si somma invece di sottrarre?",
    answer: "Perché i numeri vanno in versi opposti", distractors: ["Perché i secoli si contano da uno", "Perché a.C. si scrive al contrario", "Perché le date antiche sono incerte"],
    explanation: "Da un lato i numeri calano avvicinandosi a noi, dall'altro crescono: si misura il tratto fino a Cristo e poi quello da Cristo in poi, e si mettono insieme.",
    distractorWhy: { "Perché i secoli si contano da uno": "È la regola che sposta il numero del secolo, e non ha niente a che fare con il calcolo di un intervallo.", "Perché a.C. si scrive al contrario": "L'abbreviazione si scrive normalmente: quello che va al contrario è il verso in cui crescono gli anni.", "Perché le date antiche sono incerte": "L'incertezza di una data non cambia il modo di calcolare la distanza fra due date." } },

  { topic: "cronologia", difficulty: 7, difficulty8: true, applica: "storia-cronologia-alta",
    prompt: "Che cosa mostra una linea del tempo disegnata in scala, che un elenco ordinato non mostra?",
    answer: "Quanto è lunga la preistoria", distractors: ["In che ordine sono i fatti", "Quali fatti sono importanti", "Chi ha scritto le fonti"],
    explanation: "La scala rende visibili le proporzioni: disegnata in scala, la preistoria occupa quasi tutta la riga e tutto il resto si schiaccia in un tratto finale.",
    distractorWhy: { "In che ordine sono i fatti": "L'ordine lo dà già un elenco: è esattamente quello che la scala aggiunge in più.", "Quali fatti sono importanti": "L'importanza la decide chi costruisce la linea scegliendo che cosa metterci: non la mostra la scala.", "Chi ha scritto le fonti": "La linea del tempo colloca gli eventi, non racconta da quali documenti li conosciamo." } },

  // =============================================================== FONTI
  { topic: "fonti", difficulty: 1, difficulty8: true, applica: "storia-fonti-base",
    prompt: "Un osso con i segni di un taglio, trovato in uno scavo, è una fonte storica?",
    answer: "Sì, dice come si macellava", distractors: ["No, non è un documento scritto", "No, gli oggetti non sono fonti", "Sì, ma solo se è stato datato"],
    explanation: "Fonte non vuol dire cosa importante: vuol dire cosa da cui si può ricavare un'informazione. Quei tagli raccontano attrezzi e abitudini alimentari.",
    distractorWhy: { "No, non è un documento scritto": "Restringe le fonti ai testi, e allora di tutta la preistoria non si saprebbe niente.", "No, gli oggetti non sono fonti": "Gli oggetti sono fonti materiali, e per i periodi senza scrittura sono le uniche disponibili.", "Sì, ma solo se è stato datato": "La datazione rende la fonte più utile, ma un oggetto non datato dice comunque qualcosa su come si viveva." } },

  { topic: "fonti", difficulty: 3, difficulty8: true, applica: "storia-fonti-base",
    format: "short_answer",
    prompt: "Il diario che un soldato scrive al fronte mentre la guerra è in corso è una fonte primaria o secondaria?",
    answer: "primaria", accept: ["fonte primaria", "una fonte primaria"],
    explanation: "È prodotta nell'epoca studiata da chi la stava vivendo: nessuno l'ha ancora interpretata, ed è per questo che chi vuole controllare risale fino a lì." },

  { topic: "fonti", difficulty: 3, difficulty8: true, applica: "storia-fonti-base",
    prompt: "Si dice che un oggetto «non mente». Perché allora non basta da solo?",
    answer: "Perché non spiega niente di sé", distractors: ["Perché si rovina con il tempo", "Perché è sempre incompleto", "Perché non si può datare"],
    explanation: "Non ha intenzioni, quindi non può ingannare; ma non dice a che cosa serviva né perché fosse lì. Quello va ricostruito confrontandolo con altre fonti.",
    distractorWhy: { "Perché si rovina con il tempo": "Anche un oggetto perfettamente conservato continuerebbe a non dire nulla del proprio scopo.", "Perché è sempre incompleto": "Molti oggetti si ritrovano interi: il limite non è la completezza ma il silenzio sul significato.", "Perché non si può datare": "Gli oggetti si datano, spesso con grande precisione: il problema è un altro." } },

  { topic: "fonti", difficulty: 5, difficulty8: true, applica: "storia-fonti-base",
    prompt: "Il manuale di scuola e la lettera di un soldato al fronte: che cosa li distingue davvero?",
    answer: "La distanza dal fatto", distractors: ["La lingua in cui sono scritti", "Quanto sono lunghi i due testi", "Se sono stampati o scritti a mano"],
    explanation: "La lettera viene da chi c'era, il manuale da chi ha studiato dopo le fonti di chi c'era: uno è primario, l'altro secondario, e nessuno dei due è meno vero.",
    distractorWhy: { "La lingua in cui sono scritti": "Potrebbero essere scritti nella stessa lingua e resterebbero comunque uno primario e l'altro secondario.", "Quanto sono lunghi i due testi": "La lunghezza non c'entra: esistono fonti primarie di due righe e ricostruzioni di mille pagine.", "Se sono stampati o scritti a mano": "Il supporto non decide: una lettera stampata resterebbe primaria, e un manuale manoscritto secondario." } },

  { topic: "fonti", difficulty: 5, difficulty8: true, applica: "storia-fonti-alta",
    prompt: "Un vincitore scrive il giorno dopo la battaglia, uno sconfitto trent'anni più tardi. Che cosa cambia?",
    answer: "Che cosa ciascuno poteva sapere", distractors: ["Che uno dei due sta mentendo", "Che la fonte più antica vale di più", "Che la seconda ha smesso di essere primaria"],
    explanation: "Uno ha visto un pezzo di campo e ha interesse a fare bella figura; l'altro ha avuto trent'anni per rileggere l'evento alla luce di quello che è seguito.",
    distractorWhy: { "Che uno dei due sta mentendo": "Possono essere entrambi sinceri e raccontare cose diverse: è la posizione a cambiare, non l'onestà.", "Che la fonte più antica vale di più": "La vicinanza aiuta su certe cose e ostacola su altre: chi è dentro l'evento ne vede solo una parte.", "Che la seconda ha smesso di essere primaria": "Resta primaria, perché è di chi c'era: quello che cambia è la distanza nel tempo dal fatto." } },

  { topic: "fonti", difficulty: 6, difficulty8: true, applica: "storia-fonti-alta",
    prompt: "Di contadini e servi restano pochissime fonti scritte. Che cosa se ne deve concludere?",
    answer: "Che non sapevano scrivere", distractors: ["Che erano davvero molto pochi", "Che non avevano nessun ruolo", "Che vivevano troppo poco a lungo"],
    explanation: "L'assenza di fonti non è assenza di fatti: erano la stragrande maggioranza, e sono invisibili perché nessuno scriveva per loro né di loro.",
    distractorWhy: { "Che erano davvero molto pochi": "Erano la maggioranza della popolazione: il vuoto nelle fonti misura chi scriveva, non quanti fossero.", "Che non avevano nessun ruolo": "Producevano il cibo di tutti: il loro peso reale e la loro presenza nei documenti non coincidono affatto.", "Che vivevano troppo poco a lungo": "La vita era breve per quasi tutti, anche per chi ha lasciato moltissimi documenti." } },

  { topic: "fonti", difficulty: 8, difficulty8: true, applica: "storia-fonti-alta",
    prompt: "Trovate due fonti in contrasto, uno storico sceglie quella che conferma la sua tesi. Che errore commette?",
    answer: "Cerca conferme, non spiegazioni", distractors: ["Usa una fonte secondaria", "Non ha datato le due fonti", "Confonde il fatto con la data"],
    explanation: "La differenza fra due fonti va spiegata: chi erano gli autori, che cosa potevano sapere, che cosa conveniva loro dire. Scegliere e basta chiude la ricerca.",
    distractorWhy: { "Usa una fonte secondaria": "Il problema non è il tipo di fonte: sarebbe identico con due fonti primarie.", "Non ha datato le due fonti": "Datarle è un passo necessario, ma qui l'errore avviene dopo, nel modo di trattare il contrasto.", "Confonde il fatto con la data": "È un altro errore possibile, e non è quello descritto: qui il difetto è il criterio con cui sceglie." } },

  // ============================================================== METODO
  { topic: "metodo", difficulty: 1, difficulty8: true, applica: "storia-metodo-base",
    prompt: "Da che cosa comincia il lavoro di uno storico?",
    answer: "Da una domanda", distractors: ["Da un racconto già pronto", "Da una data importante", "Da un libro di scuola"],
    explanation: "Si parte da un problema — come si viveva in un villaggio medievale? — e poi si cercano le fonti che possono rispondere. L'ordine inverso produce solo conferme.",
    distractorWhy: { "Da un racconto già pronto": "Chi parte dal racconto cerca le fonti che lo confermano, e cercando apposta si trova sempre qualcosa.", "Da una data importante": "Una data è un punto della risposta, non la domanda: da sola non dice che cosa si vuole capire.", "Da un libro di scuola": "Il manuale è una ricostruzione già fatta da altri: è un punto di arrivo, non di partenza." } },

  { topic: "metodo", difficulty: 2, difficulty8: true, applica: "storia-metodo-base",
    prompt: "Perché un racconto sul passato senza fonti dichiarate non è un lavoro di storia?",
    answer: "Perché non si può controllare", distractors: ["Perché è sempre poco preciso", "Perché non lo capisce nessuno", "Perché non nomina nessuna data"],
    explanation: "Senza sapere da dove viene ciascuna informazione non si può né confermare né smentire: si può solo credergli. Dichiarare le fonti significa accettare di poter essere corretti.",
    distractorWhy: { "Perché è sempre poco preciso": "Può essere precisissimo e restare incontrollabile: il problema non è la cura, è la verificabilità.", "Perché non lo capisce nessuno": "Può essere chiarissimo da leggere: la chiarezza non sostituisce la possibilità di andare a controllare.", "Perché non nomina nessuna data": "Un racconto pieno di date e senza riferimenti resterebbe ugualmente impossibile da verificare." } },

  { topic: "metodo", difficulty: 4, difficulty8: true, applica: "storia-metodo-base",
    format: "short_answer",
    prompt: "«Nel 476 l'ultimo imperatore d'Occidente fu deposto»: è un fatto o un'interpretazione?",
    answer: "fatto", accept: ["un fatto", "è un fatto"],
    explanation: "È accaduto e le fonti permettono di stabilirlo. Sarebbe interpretazione la spiegazione del perché l'impero non resse, e su quella gli storici discutono." },

  { topic: "metodo", difficulty: 6, difficulty8: true, applica: "storia-metodo-alta",
    format: "short_answer",
    prompt: "Come si chiama l'errore di attribuire a un'epoca qualcosa che quell'epoca non aveva?",
    answer: "anacronismo", accept: ["un anacronismo", "anacronismi"],
    explanation: "La forma evidente riguarda gli oggetti e fa ridere; quella pericolosa riguarda le parole e le idee, perché non si vede e produce domande prive di senso." },

  { topic: "metodo", difficulty: 6, difficulty8: true, applica: "storia-metodo-alta",
    prompt: "Chiedersi se un cittadino romano fosse «di destra o di sinistra» è…",
    answer: "un anacronismo", distractors: ["una interpretazione", "una ricostruzione", "una fonte orale"],
    explanation: "Quelle categorie nascono con la Rivoluzione francese, nel 1789: applicarle prima non dà una risposta sbagliata, dà una domanda che non significa niente.",
    distractorWhy: { "una interpretazione": "Un'interpretazione spiega un fatto con categorie che hanno senso in quel contesto: qui le categorie non esistevano ancora.", "una ricostruzione": "Una ricostruzione mette insieme le fonti: qui non c'è nessuna fonte che possa rispondere, perché la domanda è fuori tempo.", "una fonte orale": "Una fonte orale è una testimonianza raccolta a voce: qui non si parla di una fonte ma di una domanda mal posta." } },

  { topic: "metodo", difficulty: 8, difficulty8: true, applica: "storia-metodo-alta",
    prompt: "Perché il fatto che la storia venga riscritta è un buon segno e non un difetto?",
    answer: "Perché arrivano fonti nuove", distractors: ["Perché le vecchie erano false", "Perché cambiano i governi", "Perché i libri si consumano"],
    explanation: "Archivi riaperti, scavi e tecniche di analisi nuove permettono di correggere: una disciplina che non si correggesse mai non starebbe verificando niente.",
    distractorWhy: { "Perché le vecchie erano false": "Le ricostruzioni precedenti erano di solito oneste e basate su meno materiale: si affinano, non si smascherano.", "Perché cambiano i governi": "Quando è il governo a riscrivere la storia si chiama propaganda, ed è il contrario di questo metodo.", "Perché i libri si consumano": "Ristampare un libro non cambia una riga del suo contenuto: qui a cambiare sono le conclusioni." } },
];
