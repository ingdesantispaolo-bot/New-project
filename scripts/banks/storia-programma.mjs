// Storia, fasce 1 e 2 — i mondi da 1 a 6.
//
// ## Perché questo file esiste
//
// Il banco di storia ha 167 item su nove argomenti, ma nelle prime due fasce ne
// ha ventidue in tutto:
//
//   fascia   1   2   3   4   5   6   7   8
//   item    11  11  21  21  29  28  23  23
//
// `variety_audit` lo segnalava due volte, ed era il secondo caso peggiore dopo
// il latino: «storia L1, il 30% delle prove è una ripetizione (max 17%)» e «la
// stessa prova (short_answer) ricapita 5 volte su 30».
//
// Il secondo dei due merita attenzione a parte. Il 30% dei nodi viene convertito
// automaticamente a risposta libera (Decisione 10): con un pozzo piccolo la
// stessa domanda torna, e torna nella forma che si nota di più, perché scriverla
// costa più fatica che toccarla.
//
// ## Che cosa si può chiedere alla fascia 1 senza chiedere una data
//
// La tentazione, in storia, è chiedere anni. Ma una data isolata non si deduce e
// non si ragiona: si ricorda o non si ricorda, ed è il tipo di domanda che fa
// credere a un ragazzo che la storia sia una lista. Vale il vincolo già scritto
// in `insieme.md`: **nessuna domanda di nome o di data senza una tavola su cui
// impararla** — la linea del tempo esiste apposta.
//
// Quindi le fasce basse di questo file chiedono tre cose diverse:
//
//   - **il metodo**: che cos'è una fonte, come si sa quello che si sa, perché
//     due datazioni possono convivere. È la parte che rende la storia una
//     disciplina invece che un elenco;
//   - **la successione**: prima e dopo, non l'anno esatto. Ordinare è un
//     ragionamento, ricordare una cifra no;
//   - **la causa**: perché una cosa è potuta succedere solo dopo un'altra. È il
//     nesso che regge tutto il resto del programma.
//
// Le date precise restano nelle fasce alte, dove il banco è ricco e la linea del
// tempo è già stata incontrata.
//
// ## Regole di scrittura
//
// Le stesse di `coding-programma.mjs`: fascia dichiarata con `difficulty8`, la
// risposta non più lunga di quattro caratteri del distrattore più lungo, nessun
// distrattore equivalente, un perché per ciascuno.

export const STORIA_PROGRAMMA = [
  // ---------------------------------------------------------------- fascia 1
  { topic: "fonti", difficulty: 1, difficulty8: true,
    prompt: "Perché un libro di storia scritto oggi non è una fonte sull'antico Egitto?",
    answer: "perché non viene da quel tempo", distractors: ["perché è troppo lungo", "perché è tradotto", "perché non ha immagini fatte allora"],
    explanation: "La fonte è ciò che il passato ha lasciato; il libro è ciò che qualcuno ha scritto dopo averla letta. Confondere i due significa credere a una ricostruzione senza poterla verificare.",
    distractorWhy: { "perché è troppo lungo": "La lunghezza non c'entra: anche una riga scritta allora sarebbe una fonte.", "perché è tradotto": "Una fonte tradotta resta una fonte: cambia la lingua, non l'origine.", "perché non ha immagini fatte allora": "Molte fonti autentiche sono solo testo, e restano fonti." } },
  { topic: "fonti", difficulty: 1, difficulty8: true,
    prompt: "Quale di questi è una fonte materiale e non scritta?",
    answer: "un vaso rotto", distractors: ["una lettera", "un contratto", "un'iscrizione"],
    explanation: "Le fonti materiali parlano senza parole: dicono che cosa si mangiava, come si costruiva, quanto si viveva. Sono spesso le uniche disponibili per chi non sapeva scrivere.",
    distractorWhy: { "una lettera": "Contiene parole scritte: è una fonte scritta.", "un contratto": "È un documento, quindi una fonte scritta.", "un'iscrizione": "È scritta anche se incisa nella pietra: conta il testo, non il materiale." } },
  { topic: "metodo", difficulty: 1, difficulty8: true,
    prompt: "Perché uno storico confronta più fonti invece di fidarsi di una sola?",
    answer: "perché ognuna vede da un punto", distractors: ["perché le fonti sono sempre false", "perché servono numeri pari", "perché una sola è troppo corta"],
    explanation: "Chi scrive racconta ciò che ha visto e ciò che gli conviene. Non vuol dire che menta: vuol dire che una fonte sola è un solo punto di vista, e la storia si costruisce incrociandoli.",
    distractorWhy: { "perché le fonti sono sempre false": "Sarebbero inutili: il problema è che sono parziali, non che siano bugie.", "perché servono numeri pari": "Il numero non conta: contano i punti di vista diversi.", "perché una sola è troppo corta": "Anche una fonte lunghissima resterebbe un solo punto di vista." } },
  { topic: "metodo", difficulty: 1, difficulty8: true,
    prompt: "Il racconto di una battaglia scritto dal vincitore va buttato via?",
    answer: "no, va letto sapendo chi scrive", distractors: ["sì, è sempre falso", "sì, se non ci sono numeri", "no, perché i vincitori sono sinceri"],
    explanation: "Chi ha vinto racconta ciò che gli conviene, ma è anche chi era presente. Sapere chi tiene la penna non serve a scartare la fonte: serve a leggerla, e a cercarne un'altra dall'altro lato.",
    distractorWhy: { "sì, è sempre falso": "Essere di parte non vuol dire mentire: spesso i fatti sono esatti e la scelta di che cosa raccontare no.", "sì, se non ci sono numeri": "I numeri antichi sono fra le cose meno affidabili di una fonte, non le più.", "no, perché i vincitori sono sinceri": "La sincerità non c'entra: anche chi è convinto racconta da dove si trova." } },
  // Tre prove a risposta libera, e non per caso: la Decisione 10 chiede che ogni
  // banco stia fra il 20% e il 30% di risposte non a scelta multipla, e ventuno
  // item nuovi tutti a crocetta avevano fatto scendere storia al 19%. Sono le
  // tre domande che si prestano, perché hanno una risposta breve e senza
  // sinonimi: un numero o il nome di un secolo.
  { topic: "cronologia", difficulty: 1, difficulty8: true, format: "numeric_input",
    prompt: "Quanti secoli stanno in un millennio?",
    answer: "10",
    explanation: "Sapere quale scala si sta usando evita di confondere un cambiamento lento con uno improvviso: dieci secoli sono abbastanza perché una lingua diventi un'altra lingua." },
  { topic: "cronologia", difficulty: 1, difficulty8: true,
    prompt: "L'anno 50 a.C. viene prima o dopo l'anno 20 a.C.?",
    answer: "prima", distractors: ["dopo", "lo stesso anno", "non si può dire"],
    explanation: "Prima di Cristo i numeri scorrono al contrario: più il numero è grande, più si va indietro. È l'inciampo più comune, e si evita immaginando un conto alla rovescia che finisce a zero.",
    distractorWhy: { "dopo": "Sarebbe vero dopo Cristo, dove i numeri crescono andando avanti.", "lo stesso anno": "Sono due anni diversi, distanti trent'anni.", "non si può dire": "Si può dire con certezza: la regola non ha eccezioni." } },
  { topic: "cronologia", difficulty: 1, difficulty8: true,
    prompt: "Quale di questi periodi è il più antico?",
    answer: "preistoria", distractors: ["medioevo", "età moderna", "età antica"],
    explanation: "La preistoria è tutto ciò che viene prima della scrittura, ed è di gran lunga il periodo più lungo. Quella che chiamiamo storia occupa una fetta sottilissima del tempo umano.",
    distractorWhy: { "medioevo": "Sta nel mezzo, fra l'età antica e quella moderna.", "età moderna": "È la più vicina a noi fra quelle elencate.", "età antica": "È antica ma comincia con la scrittura, quindi dopo la preistoria." } },
  { topic: "preistoria", difficulty: 1, difficulty8: true, format: "short_answer",
    prompt: "Che cosa segna il passaggio dalla preistoria alla storia? Una parola.",
    answer: "scrittura", accept: ["la scrittura", "l'invenzione della scrittura", "invenzione della scrittura", "scrittura"],
    explanation: "Non è che prima non succedesse niente: è che senza scrittura non restano parole, e possiamo sapere solo ciò che gli oggetti raccontano. Il confine è nostro, non loro." },
  { topic: "preistoria", difficulty: 1, difficulty8: true,
    prompt: "Che cosa cambiò con l'agricoltura?",
    answer: "gli uomini smisero di spostarsi", distractors: ["si cominciò a usare il fuoco per cuocere", "nacque la scrittura", "si estinsero gli animali"],
    explanation: "Chi semina deve tornare a raccogliere, e quindi resta. Da lì nascono i villaggi, i magazzini, la proprietà e i mestieri: è il cambiamento che rende possibili quasi tutti gli altri.",
    distractorWhy: { "si cominciò a usare il fuoco per cuocere": "Il fuoco era già in uso da moltissimo tempo prima.", "nacque la scrittura": "Arriva molto dopo, e nasce proprio per contare i raccolti.", "si estinsero gli animali": "Gli animali vennero addomesticati, non fatti sparire." } },
  { topic: "egizi", difficulty: 1, difficulty8: true,
    prompt: "Perché gli antichi egizi si stabilirono lungo il Nilo?",
    answer: "perché le piene rendevano fertile la terra", distractors: ["perché il fiume li difendeva dai nemici", "perché ci trovavano metalli", "perché il clima era freddo"],
    explanation: "Ogni anno la piena depositava limo sui campi e li rendeva coltivabili senza concime. Un'intera civiltà è cresciuta attorno a un evento che si ripeteva puntuale, e il calendario è nato per prevederlo.",
    distractorWhy: { "perché il fiume li difendeva dai nemici": "Il Nilo era soprattutto una via di passaggio, non una barriera.", "perché ci trovavano metalli": "I metalli venivano cercati altrove, spesso lontano dal fiume.", "perché il clima era freddo": "Il clima era caldo e arido: senza il fiume la terra sarebbe stata deserto." } },
  { topic: "civilta", difficulty: 1, difficulty8: true,
    prompt: "Perché le prime città nacquero vicino ai fiumi?",
    answer: "per l'acqua e le terre coltivabili", distractors: ["per difendersi meglio dagli attacchi", "per commerciare con navi", "per il clima più fresco"],
    explanation: "Prima di tutto viene il cibo: dove la terra rende, le persone possono essere molte e non tutte devono coltivare. È quel surplus a rendere possibili artigiani, sacerdoti e scribi.",
    distractorWhy: { "per difendersi meglio dagli attacchi": "Per difendersi si sceglievano le alture, non le pianure fluviali.", "per commerciare con navi": "Il commercio arriva dopo, quando la città esiste già.", "per il clima più fresco": "Il clima dipende dalla latitudine più che dalla presenza di un fiume." } },

  // ---------------------------------------------------------------- fascia 2
  { topic: "cronologia", difficulty: 2, difficulty8: true, format: "short_answer",
    prompt: "L'anno 1492 appartiene a quale secolo? Scrivi il numero in cifre.",
    answer: "15", accept: ["XV", "quindicesimo", "quindicesimo secolo", "15esimo"],
    explanation: "Il secolo si ottiene togliendo le ultime due cifre e aggiungendo uno, perché il primo secolo comincia con l'anno uno e non con l'anno zero. Gli anni che iniziano per 14 stanno quindi nel quindicesimo." },
  { topic: "cronologia", difficulty: 2, difficulty8: true, format: "numeric_input",
    prompt: "Quanti anni passano fra il 30 a.C. e il 20 d.C.?",
    answer: "50",
    explanation: "Attraversando il confine i due numeri si sommano invece di sottrarsi, perché si contano da zero in due direzioni. È il calcolo che si sbaglia più spesso di tutta la cronologia." },
  { topic: "metodo", difficulty: 2, difficulty8: true,
    prompt: "Due fonti danno per lo stesso fatto due date diverse. Che cosa fa uno storico?",
    answer: "tiene tutte e due e spiega perché", distractors: ["sceglie la più antica fra le due fonti", "sceglie la più recente", "scarta il fatto"],
    explanation: "Una data incerta è un'informazione, non un buco: dice che le fonti usavano calendari diversi, o che il fatto non fu percepito nello stesso momento. Cancellarne una fa sparire proprio quel dato.",
    distractorWhy: { "sceglie la più antica fra le due fonti": "L'anzianità di una fonte non garantisce che sia più precisa.", "sceglie la più recente": "Una fonte tarda può copiare da una sbagliata: la data non migliora con il tempo.", "scarta il fatto": "Il fatto è attestato da due fonti: è la sua collocazione a essere discussa, non la sua esistenza." } },
  { topic: "metodo", difficulty: 2, difficulty8: true,
    prompt: "Perché sappiamo pochissimo della vita quotidiana dei contadini antichi?",
    answer: "perché non scrivevano", distractors: ["perché erano pochissimi", "perché si spostavano sempre", "perché non avevano oggetti"],
    explanation: "Le fonti scritte le producono soprattutto chi ha potere e chi commercia. Di tutti gli altri restano ossa, attrezzi e case: sappiamo che cosa mangiavano molto meglio di che cosa pensavano.",
    distractorWhy: { "perché erano pochissimi": "Erano la stragrande maggioranza della popolazione.", "perché si spostavano sempre": "Chi coltiva resta: sono i pastori a spostarsi.", "perché non avevano oggetti": "Di oggetti ne restano moltissimi, ed è grazie a quelli che sappiamo qualcosa." } },
  { topic: "fonti", difficulty: 2, difficulty8: true,
    prompt: "Perché un falso storico è comunque una fonte utile?",
    answer: "perché dice che cosa si voleva far credere", distractors: ["perché di solito è quasi vero", "perché è più antico degli altri", "perché non è mai davvero falso in tutto"],
    explanation: "Un documento inventato non dice il vero sul fatto che racconta, ma dice il vero su chi lo ha fabbricato: che cosa gli conveniva, che cosa il suo pubblico avrebbe creduto, e quando.",
    distractorWhy: { "perché di solito è quasi vero": "Un falso può essere inventato da cima a fondo e restare utile lo stesso.", "perché è più antico degli altri": "Spesso è più recente di ciò che pretende di essere: è proprio così che si smaschera.", "perché non è mai davvero falso in tutto": "Può esserlo del tutto: cambia a quale domanda risponde." } },
  { topic: "preistoria", difficulty: 2, difficulty8: true,
    prompt: "Perché la scrittura nacque prima nei magazzini che nelle biblioteche?",
    answer: "serviva a contare le merci", distractors: ["serviva a scrivere poesie e canti", "serviva a mandare lettere", "serviva a scrivere leggi"],
    explanation: "I primi segni sono conti: quante pecore, quanti sacchi, di chi. Raccontare storie per iscritto arriva molto dopo, quando il sistema esiste già ed è abbastanza flessibile da reggere le parole.",
    distractorWhy: { "serviva a scrivere poesie e canti": "La poesia esisteva da prima, ma si tramandava a voce.", "serviva a mandare lettere": "La corrispondenza arriva dopo, quando saper leggere è meno raro.", "serviva a scrivere leggi": "Le prime leggi scritte sono più tarde dei primi conti." } },
  { topic: "egizi", difficulty: 2, difficulty8: true,
    prompt: "Perché conosciamo così bene le tombe egizie e molto meno le loro case?",
    answer: "le tombe erano di pietra, le case di fango", distractors: ["le case furono tutte bruciate in guerra", "vivevano dentro le tombe", "le case erano sottoterra"],
    explanation: "Ciò che resta non è ciò che era più importante: è ciò che dura. Costruivano per l'eternità con la pietra e per la vita quotidiana con il mattone crudo, che si scioglie.",
    distractorWhy: { "le case furono tutte bruciate in guerra": "Non servì nessun incendio: il fango si disfa da solo con l'acqua.", "vivevano dentro le tombe": "Le tombe erano riservate ai morti e spesso sigillate.", "le case erano sottoterra": "Stavano in superficie, vicino ai campi e al fiume." } },
  { topic: "grecia", difficulty: 2, difficulty8: true,
    prompt: "Perché la Grecia antica era divisa in tante città indipendenti?",
    answer: "le montagne separavano le valli", distractors: ["mancava una lingua comune fra le città", "erano sempre in guerra", "non conoscevano le strade"],
    explanation: "La geografia rende alcune forme politiche più facili di altre: valli separate da montagne e collegate dal mare producono città autonome che commerciano fra loro invece di un unico stato.",
    distractorWhy: { "mancava una lingua comune fra le città": "La lingua era comune, ed è una delle cose che li faceva sentire greci.", "erano sempre in guerra": "Si combattevano spesso, ma la divisione veniva prima delle guerre, non dopo.", "non conoscevano le strade": "Le costruivano: il punto è che le montagne le rendevano lunghe e costose." } },
  { topic: "roma", difficulty: 2, difficulty8: true,
    prompt: "Perché le strade romane erano importanti quanto l'esercito?",
    answer: "permettevano di arrivare in fretta ovunque", distractors: ["servivano a commerciare grano e olio", "erano un simbolo di potenza", "collegavano solo le città grandi"],
    explanation: "Un impero grande si tiene se le notizie e i soldati viaggiano più veloci delle rivolte. Le strade servivano al commercio, ma furono costruite per una ragione militare.",
    distractorWhy: { "servivano a commerciare grano e olio": "Lo facevano anche, ma il grano viaggiava soprattutto via mare, che costa meno.", "erano un simbolo di potenza": "Lo erano, ma un simbolo non spiega perché valessero quanto un esercito.", "collegavano solo le città grandi": "Arrivavano anche agli accampamenti e ai confini, dove città non ce n'erano." } },
  { topic: "civilta", difficulty: 2, difficulty8: true,
    prompt: "Perché la nascita dei mestieri specializzati richiede prima l'agricoltura?",
    answer: "serve cibo in più per chi non coltiva", distractors: ["servono attrezzi di metallo già diffusi", "serve una lingua scritta", "servono città murate"],
    explanation: "Un vasaio non produce cibo: qualcuno deve produrne più del necessario perché lui possa fare il vasaio. Il surplus agricolo è la condizione materiale di tutto ciò che chiamiamo civiltà.",
    distractorWhy: { "servono attrezzi di metallo già diffusi": "I primi mestieri specializzati sono più antichi della metallurgia.", "serve una lingua scritta": "La scrittura è essa stessa un mestiere specializzato: viene dopo, non prima.", "servono città murate": "Le mura arrivano quando c'è già qualcosa da difendere." } },

  // ---------------------------------------------------------------- fascia 5
  // Aggiunta per un difetto DIVERSO da quello delle fasce basse, e vale la pena
  // scriverlo perché non era prevedibile dal conteggio.
  //
  // Il pozzo della fascia 5 non era povero: settantanove item. Eppure
  // `variety_audit` dava «storia L13, il 20% delle prove è una ripetizione».
  // Guardando la scomposizione per argomento la causa era netta: `civilta` e
  // `metodo` avevano **un solo item** in quella fascia, `egizi` due, `cronologia`
  // tre. Il selettore sceglie prima l'argomento e poi l'item: pescato un
  // argomento che ne ha uno, la ripetizione è certa.
  //
  // **La regola generale, da tenere:** per la varietà non conta quanto è grande
  // il pozzo della fascia, conta la casella più piccola fra argomento e fascia.
  // Un banco può essere ricco e ripetitivo insieme.
  { topic: "civilta", difficulty: 5, difficulty8: true,
    prompt: "Perché la scrittura cuneiforme si faceva su tavolette d'argilla?",
    answer: "era il materiale che c'era", distractors: ["si conservava meglio del resto", "era più economica del papiro", "si poteva cancellare e riusare"],
    explanation: "In Mesopotamia non c'erano né papiro né pietra facile da lavorare, ma fango di fiume in abbondanza. Il supporto disponibile ha deciso anche la forma dei segni: nell'argilla molle si preme un cuneo, non si traccia una curva.",
    distractorWhy: { "si conservava meglio del resto": "Si conserva benissimo, ma è una fortuna per noi, non il motivo della scelta.", "era più economica del papiro": "Il papiro lì non arrivava affatto: non c'era nessun confronto di prezzo da fare.", "si poteva cancellare e riusare": "Una volta essiccata o cotta la tavoletta diventa permanente." } },
  { topic: "civilta", difficulty: 5, difficulty8: true,
    prompt: "Che cosa permise alle prime civiltà di mantenere eserciti permanenti?",
    answer: "il cibo prodotto in più", distractors: ["la scoperta del ferro battuto", "la costruzione di grandi mura", "l'invenzione della ruota da carro"],
    explanation: "Un soldato non coltiva: qualcuno deve produrre il suo cibo. Il surplus agricolo è la condizione di ogni mestiere a tempo pieno, dal sacerdote allo scriba al soldato.",
    distractorWhy: { "la scoperta del ferro battuto": "Migliora le armi, ma non risolve il problema di chi nutre chi le impugna.", "la costruzione di grandi mura": "Le mura difendono, e per costruirle serve a sua volta gente sfamata.", "l'invenzione della ruota da carro": "Aiuta il trasporto, ma non aumenta il cibo disponibile." } },
  { topic: "civilta", difficulty: 5, difficulty8: true,
    prompt: "Perché le prime leggi vennero scritte su pietra in luoghi pubblici?",
    answer: "perché nessuno potesse cambiarle", distractors: ["perché la pietra costava pochissimo", "perché tutti sapevano già leggere", "perché servivano da decorazione"],
    explanation: "Una legge incisa ed esposta è una legge che il potente non può modificare di nascosto. Che quasi nessuno sapesse leggere conta meno di quanto sembra: bastava che alcuni potessero verificare.",
    distractorWhy: { "perché la pietra costava pochissimo": "Incidere la pietra era anzi lungo e costoso: è proprio il costo a renderla solenne.", "perché tutti sapevano già leggere": "Leggere era raro: l'esposizione serviva a garantire, non a informare tutti.", "perché servivano da decorazione": "Erano testi giuridici collocati dove la gente passava, non ornamenti." } },
  { topic: "metodo", difficulty: 5, difficulty8: true,
    prompt: "Che cosa può dire a uno storico una discarica di duemila anni fa?",
    answer: "che cosa si mangiava davvero", distractors: ["chi comandava in quella città", "quali leggi erano in vigore", "come si chiamavano gli abitanti"],
    explanation: "I rifiuti sono la fonte meno interessata di tutte: nessuno li produce per essere ricordato. Per questo dicono sulla vita quotidiana molto più di un'iscrizione celebrativa.",
    distractorWhy: { "chi comandava in quella città": "I nomi dei potenti stanno nelle iscrizioni, non negli scarti.", "quali leggi erano in vigore": "Le leggi sono testi, e in una discarica non si conservano.", "come si chiamavano gli abitanti": "I nomi arrivano da lapidi, contratti e registri." } },
  // Due delle dieci righe nuove sono a risposta libera: dieci item tutti a
  // crocetta avrebbero riportato storia sotto il 20% della Decisione 10.
  { topic: "metodo", difficulty: 5, difficulty8: true, format: "short_answer",
    prompt: "Quale elemento si misura per datare un reperto di legno o di osso? Scrivi il nome e il numero.",
    answer: "carbonio 14", accept: ["carbonio-14", "c14", "c 14", "il carbonio 14", "carbonio quattordici"],
    explanation: "Ogni essere vivente accumula carbonio 14 finché è vivo; da quando muore quel carbonio diminuisce a un ritmo noto e regolare. Misurando quanto ne resta si conta quanto tempo è passato." },
  { topic: "metodo", difficulty: 5, difficulty8: true,
    prompt: "Perché una fonte scritta e un reperto che si contraddicono sono una buona notizia?",
    answer: "segnalano che qualcosa va spiegato", distractors: ["provano che una delle due è falsa", "permettono di scartare la più vecchia", "dimostrano che il fatto non avvenne"],
    explanation: "La contraddizione è il punto in cui si impara: di solito le due fonti rispondono a domande diverse, oppure una racconta come si voleva che le cose fossero. Il disaccordo indica dove guardare.",
    distractorWhy: { "provano che una delle due è falsa": "Possono essere vere tutte e due e riguardare momenti o aspetti diversi.", "permettono di scartare la più vecchia": "L'età non decide l'attendibilità di una fonte.", "dimostrano che il fatto non avvenne": "Il disaccordo riguarda i dettagli, non l'esistenza del fatto." } },
  { topic: "cronologia", difficulty: 5, difficulty8: true,
    prompt: "Perché due popoli antichi potevano datare lo stesso anno in modi diversi?",
    answer: "ognuno contava da un evento suo", distractors: ["non conoscevano ancora i numeri", "cambiavano calendario ogni anno", "sbagliavano il conto dei giorni"],
    explanation: "Roma contava dalla fondazione della città, i greci dalle olimpiadi, altri dall'anno di regno del sovrano. Il conto dalla nascita di Cristo arriva molto dopo, e tradurre fra i sistemi è parte del mestiere.",
    distractorWhy: { "non conoscevano ancora i numeri": "Contavano benissimo: erano i punti di partenza a essere diversi.", "cambiavano calendario ogni anno": "I calendari erano stabili per secoli.", "sbagliavano il conto dei giorni": "Gli errori esistevano ma erano piccoli, e non spiegano date molto diverse." } },
  { topic: "cronologia", difficulty: 5, difficulty8: true,
    prompt: "Che cosa vuol dire che un periodo storico ha confini «convenzionali»?",
    answer: "che li abbiamo scelti noi dopo", distractors: ["che sono incerti di pochi anni", "che valgono solo in Europa", "che nessuno li usa più"],
    explanation: "Chi viveva nel 476 non sapeva di stare passando dall'età antica al medioevo. I confini servono a noi per ordinare, e cambiarli non cambia i fatti: cambia il racconto che ne facciamo.",
    distractorWhy: { "che sono incerti di pochi anni": "L'incertezza è un'altra cosa: qui la data è nota ma la scelta è nostra.", "che valgono solo in Europa": "È spesso vero, ma non è il significato della parola.", "che nessuno li usa più": "Si usano continuamente: è proprio per questo che vanno capiti." } },
  { topic: "egizi", difficulty: 5, difficulty8: true, format: "short_answer",
    prompt: "«Geometria» in greco vuol dire misura di una cosa sola. Quale?",
    answer: "terra", accept: ["la terra", "il terreno", "terreno", "i campi"],
    explanation: "Ogni piena del Nilo cancellava i confini dei terreni, e ogni anno bisognava ridisegnarli con esattezza per non litigare. La parola stessa dice il mestiere da cui è nata: misura della terra." },
  { topic: "egizi", difficulty: 5, difficulty8: true,
    prompt: "Perché la scrittura geroglifica restò comprensibile a pochi per millenni?",
    answer: "impararla richiedeva anni", distractors: ["era vietata alla gente comune", "cambiava di regno in regno", "si scriveva solo sulle tombe"],
    explanation: "Centinaia di segni, con valori diversi secondo il contesto: diventare scriba era un mestiere a tempo pieno con una scuola dietro. Un alfabeto di poche lettere, molto più tardi, cambierà proprio questo.",
    distractorWhy: { "era vietata alla gente comune": "Non c'era nessun divieto: era la difficoltà a fare da filtro.", "cambiava di regno in regno": "Restò notevolmente stabile per moltissimo tempo.", "si scriveva solo sulle tombe": "Si usava anche su papiri, contratti e oggetti d'uso." } },
];
