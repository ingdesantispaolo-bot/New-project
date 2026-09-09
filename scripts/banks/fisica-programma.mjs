// Fisica, fasce 1-2 e 7-8 — i mondi 1-6 e 19-24.
//
// ## Perché questo file esiste
//
// Fisica non è mai stata rossa in `variety_audit`, ed è l'unica delle sei
// materie povere alle fasce basse a non esserlo stata. Ma è anche la seconda per
// pozzo più magro dopo geografia: **nove sessioni** prima di rivedere un
// esercizio alla fascia 1, contro le dieci di coding *dopo* che coding è stato
// riparato. Non essere rossi non vuol dire stare bene: vuol dire stare sotto la
// soglia di un cricchetto tarato sul peggiore.
//
//   fascia   1   2   3   4   5   6   7   8
//   item    25  24  24  22  37  46  29  22
//
// Fisica è materia di SECONDA fascia di priorità, quindi una sessione ne consuma
// cinque: il pozzo della fascia 1 (49 item, cioè fascia 1 più fascia 2) regge
// nove sessioni, quello della fascia 8 (51) ne regge dieci.
//
// ## Il difetto vero non è il totale, è la casella
//
// È la lezione pagata con storia il 9 settembre: il selettore sceglie **prima
// l'argomento e poi l'item**, quindi ciò che produce ripetizione non è un pozzo
// magro ma una casella (argomento, fascia) da uno o zero. In fisica ce ne sono
// molte, ed è per questo che il rosso poteva arrivare da un momento all'altro:
//
//   fascia 1   `onde-luce`, `energia`, `calore` e `metodo` a ZERO
//   fascia 2   `moto`, `metodo`, `pressione`, `galleggiamento`, `correnti` a UNO
//   fascia 8   `moto` e `correnti` a ZERO; altri cinque argomenti a UNO
//
// Quattro argomenti su dodici non esistevano affatto nei primi tre mondi. Un
// bambino che al mondo 1 incontrava fisica poteva vedere solo misure, forze,
// leve e correnti — e mai la luce, il calore o l'energia, che sono le tre cose
// di cui ha esperienza diretta ogni giorno.
//
// ## Che cosa si può chiedere alla fascia 1 senza formule
//
// La tentazione della fisica è la formula. Ma una formula applicata senza il
// fenomeno è aritmetica travestita, e alla fascia 1 il fenomeno non è ancora
// stato guardato. Quindi le fasce basse di questo file chiedono:
//
//   - **la previsione**: se scaldo, se spingo, se immergo, che cosa succede;
//   - **la distinzione che tutti sbagliano**: calore e temperatura, peso e
//     massa, velocità e accelerazione. Sono i punti in cui l'intuizione quotidiana
//     è precisa ma il nome è sbagliato, ed è lì che la fisica comincia davvero;
//   - **la lettura di uno strumento**: che cosa misura, in quale unità, e che
//     cosa vuol dire un numero senza la sua unità.
//
// Le fasce 7 e 8 invece **chiedono i conti**, perché a quel punto il fenomeno è
// stato visto e la formula è il modo per prevederlo con precisione. Lì stanno i
// `numeric_input`.
//
// ## Regole di scrittura
//
// Le stesse di `coding-programma.mjs`: fascia dichiarata con `difficulty8`
// (niente ponte 4→8), la risposta **mai più lunga del distrattore più lungo**,
// nessun distrattore equivalente, un perché per ciascuno. Otto item a risposta
// libera perché la Decisione 10 chiede fra il 20% e il 30% non a crocetta, e
// cinquanta item tutti a scelta multipla farebbero scendere fisica dal 22% al
// 18%.

export const FISICA_PROGRAMMA = [
  // ---------------------------------------------------------------- fascia 1
  // I quattro argomenti che qui non esistevano: luce, calore, energia, metodo.
  { topic: "onde-luce", difficulty: 1, difficulty8: true,
    prompt: "Perché la tua ombra è più lunga la sera che a mezzogiorno?",
    answer: "il Sole è più basso", distractors: ["il Sole è più lontano", "l'aria è più fredda", "il corpo si allunga"],
    explanation: "La luce va dritta: più la sorgente è bassa, più l'ombra si stende sul terreno. È lo stesso motivo per cui una torcia tenuta di sbieco allunga l'ombra sul muro.",
    distractorWhy: { "il Sole è più lontano": "La distanza cambia pochissimo nel corso di una giornata.", "l'aria è più fredda": "La temperatura non ha effetto sulla direzione dei raggi.", "il corpo si allunga": "Chi proietta l'ombra resta identico: cambia da dove arriva la luce." } },
  { topic: "onde-luce", difficulty: 1, difficulty8: true,
    prompt: "Perché vedi un oggetto che non emette luce?",
    answer: "rimanda indietro la luce", distractors: ["produce una luce molto debole", "assorbe tutta la luce", "scalda l'aria attorno"],
    explanation: "Quasi tutto ciò che vediamo non brilla: rimanda ai nostri occhi la luce che ha ricevuto. È per questo che al buio completo non si vede niente, per quanto si aspetti.",
    distractorWhy: { "produce una luce molto debole": "Se producesse luce lo vedresti anche in una stanza buia.", "assorbe tutta la luce": "Un oggetto che assorbe tutto appare nero, e il nero è ciò che non rimanda.", "scalda l'aria attorno": "Il calore c'è ma non arriva agli occhi come immagine." } },
  { topic: "onde-luce", difficulty: 1, difficulty8: true,
    prompt: "Un oggetto appare rosso. Che cosa fa con la luce bianca?",
    answer: "rimanda solo il rosso", distractors: ["rimanda tutti i colori", "aggiunge il colore rosso", "toglie soltanto il rosso"],
    explanation: "La luce bianca contiene tutti i colori: un oggetto rosso assorbe gli altri e rimanda il rosso. Illuminato con luce verde, lo stesso oggetto sembra quasi nero, perché non ha rosso da rimandare.",
    distractorWhy: { "rimanda tutti i colori": "Allora apparirebbe bianco, come un foglio.", "aggiunge il colore rosso": "Nessun oggetto crea luce: può solo rimandare quella che riceve.", "toglie soltanto il rosso": "È il contrario: trattiene gli altri e lascia andare il rosso." } },
  { topic: "calore", difficulty: 1, difficulty8: true,
    prompt: "Perché il manico di metallo di una pentola scotta prima di quello di legno?",
    answer: "il metallo conduce meglio", distractors: ["il metallo si scalda di più", "il legno respinge il calore", "il metallo è più pesante"],
    explanation: "Il calore arriva a tutti e due allo stesso modo, ma nel metallo viaggia in fretta e nel legno quasi si ferma. Per questo il legno serve da manico: non isola perché è freddo, ma perché è lento.",
    distractorWhy: { "il metallo si scalda di più": "Ricevono lo stesso calore: cambia quanto in fretta lo trasportano.", "il legno respinge il calore": "Non lo respinge: lo lascia passare molto lentamente.", "il metallo è più pesante": "Il peso non decide la velocità con cui il calore attraversa un materiale." } },
  { topic: "calore", difficulty: 1, difficulty8: true,
    prompt: "Metti un cucchiaio freddo in acqua calda. Che cosa passa da uno all'altro?",
    answer: "il calore", distractors: ["il freddo del cucchiaio", "la temperatura stessa", "l'acqua dentro il metallo"],
    explanation: "Il freddo non esiste come cosa che si sposta: esiste il calore, che va sempre dal più caldo al più freddo finché i due si pareggiano. «Il freddo entra» è un modo di dire, non un fenomeno.",
    distractorWhy: { "il freddo del cucchiaio": "Il freddo è solo assenza di calore: non è qualcosa che viaggia.", "la temperatura stessa": "La temperatura è una misura, non una sostanza che si trasferisce.", "l'acqua dentro il metallo": "Il metallo non assorbe acqua: si scalda e basta." } },
  { topic: "calore", difficulty: 1, difficulty8: true,
    prompt: "Un cucchiaino e una pentola d'acqua sono tutti e due a 20 gradi. Chi contiene più calore?",
    answer: "la pentola", distractors: ["il cucchiaino", "tutti e due uguale", "nessuno dei due"],
    explanation: "Temperatura e calore non sono la stessa cosa: la temperatura dice quanto è caldo, il calore quanta energia c'è in tutto. Tanta materia alla stessa temperatura contiene molta più energia.",
    distractorWhy: { "il cucchiaino": "È molto più piccolo, quindi contiene molta meno energia.", "tutti e due uguale": "Sarebbe vero per la temperatura, che infatti è la stessa: il calore no.", "nessuno dei due": "A venti gradi tutti e due contengono energia: lo zero del calore è molto più in basso." } },
  { topic: "energia", difficulty: 1, difficulty8: true,
    prompt: "Che cosa succede all'energia di una palla che rotola e si ferma?",
    answer: "diventa calore per attrito", distractors: ["sparisce completamente", "torna alla mano che l'ha spinta", "resta ferma dentro la palla"],
    explanation: "L'energia non si distrugge: lo strisciare contro il terreno la trasforma in calore, poco per volta, finché il movimento finisce. Se non ci fosse attrito la palla non si fermerebbe mai.",
    distractorWhy: { "sparisce completamente": "L'energia non sparisce mai: cambia forma.", "torna alla mano che l'ha spinta": "Una volta lasciata, non c'è nessun collegamento con la mano.", "resta ferma dentro la palla": "Se fosse ancora energia di movimento, la palla si muoverebbe." } },
  { topic: "energia", difficulty: 1, difficulty8: true,
    prompt: "Una biglia in cima a uno scivolo ha energia anche se è ferma. Perché?",
    answer: "per la sua posizione in alto", distractors: ["per il suo peso elevato", "per il colore della sua superficie", "per il materiale di cui è fatta"],
    explanation: "Stare in alto è già una riserva: appena la lasci, quella posizione si trasforma in movimento. È lo stesso principio di una diga, di un orologio a pesi e di una molla carica.",
    distractorWhy: { "per il suo peso elevato": "Il peso conta, ma da solo non basta: a terra quella stessa biglia non ha nulla da restituire.", "per il colore della sua superficie": "Il colore non ha nessun ruolo nell'energia immagazzinata.", "per il materiale di cui è fatta": "Il materiale cambia l'attrito, non l'energia della posizione." } },
  { topic: "energia", difficulty: 1, difficulty8: true,
    prompt: "Quale di queste NON è una forma di energia?",
    answer: "il volume", distractors: ["il movimento", "il calore", "la luce"],
    explanation: "L'energia è la capacità di far succedere qualcosa, e si presenta in molte forme che si trasformano l'una nell'altra. Il volume è invece una misura di quanto spazio occupa una cosa.",
    distractorWhy: { "il movimento": "È l'energia cinetica, la forma più visibile di tutte.", "il calore": "È energia in transito da un corpo più caldo a uno più freddo.", "la luce": "Trasporta energia: è ciò che scalda la pelle al sole." } },
  { topic: "metodo", difficulty: 1, difficulty8: true,
    prompt: "Perché una misura si scrive sempre con la sua unità?",
    answer: "senza, il numero non dice niente", distractors: ["per rendere il testo più chiaro", "perché lo chiede il quaderno", "per far vedere che si è misurato"],
    explanation: "«Cinque» può essere cinque centimetri o cinque chilometri: il numero da solo non è una misura. Confondere le unità ha fatto perdere una sonda spaziale, ed è l'errore più costoso della storia della fisica.",
    distractorWhy: { "per rendere il testo più chiaro": "Non è una questione di stile: senza unità l'informazione manca proprio.", "perché lo chiede il quaderno": "È una regola della fisica, non una convenzione scolastica.", "per far vedere che si è misurato": "L'unità serve a chi legge, non a dimostrare di aver lavorato." } },
  { topic: "metodo", difficulty: 1, difficulty8: true,
    prompt: "Misuri lo stesso tavolo tre volte e trovi 120, 121 e 120 centimetri. Che cosa vuol dire?",
    answer: "ogni misura ha un'incertezza", distractors: ["due misure sono sbagliate", "il tavolo si è allungato", "il metro è rotto e va cambiato"],
    explanation: "Nessuna misura è esatta: c'è sempre un margine, e ripetere serve proprio a vederlo. Un risultato scritto senza incertezza sta dicendo una cosa che nessuno strumento può garantire.",
    distractorWhy: { "due misure sono sbagliate": "Sono tutte e tre valide: differiscono meno di quanto lo strumento possa distinguere.", "il tavolo si è allungato": "Un centimetro in pochi minuti non è una variazione reale del legno.", "il metro è rotto e va cambiato": "Uno scarto di un centimetro su 120 è normale per un metro da sarto." } },
  { topic: "misure", difficulty: 1, difficulty8: true,
    prompt: "Con quale strumento misuri la massa di un oggetto?",
    answer: "la bilancia", distractors: ["il dinamometro", "il termometro", "il cronometro"],
    explanation: "La bilancia confronta la tua massa con masse note. Il dinamometro misura invece una forza: sulla Luna darebbe un numero diverso per lo stesso oggetto, la bilancia no.",
    distractorWhy: { "il dinamometro": "Misura forze, quindi il peso: sulla Luna segnerebbe meno.", "il termometro": "Misura la temperatura, che non ha niente a che vedere con la massa.", "il cronometro": "Misura il tempo: serve per le velocità, non per le quantità di materia." } },
  { topic: "moto", difficulty: 1, difficulty8: true,
    prompt: "Sei seduto su un treno che viaggia. Rispetto al treno, tu sei...",
    answer: "fermo", distractors: ["in movimento veloce", "in movimento lento", "sia fermo sia in moto"],
    explanation: "Il movimento esiste solo rispetto a qualcosa: rispetto al vagone sei fermo, rispetto ai binari corri. Non è un gioco di parole — è il motivo per cui in treno si può appoggiare un bicchiere.",
    distractorWhy: { "in movimento veloce": "Lo sei rispetto alla terra fuori, non rispetto al treno.", "in movimento lento": "Rispetto al treno la tua distanza dal sedile non cambia affatto.", "sia fermo sia in moto": "Rispetto a UN riferimento la risposta è una sola: il treno." } },
  { topic: "materia", difficulty: 1, difficulty8: true,
    prompt: "Che cosa distingue un solido da un liquido?",
    answer: "il solido tiene la sua forma", distractors: ["il solido è sempre più pesante", "il liquido è sempre trasparente", "il solido è sempre più freddo"],
    explanation: "Nel solido le particelle stanno al loro posto e possono solo vibrare; nel liquido scivolano una sull'altra, quindi il liquido prende la forma del recipiente ma non si espande a riempirlo come farebbe un gas.",
    distractorWhy: { "il solido è sempre più pesante": "Il sughero è solido e galleggia sull'acqua, che è liquida.", "il liquido è sempre trasparente": "Il latte e il mercurio sono liquidi e non si vede attraverso.", "il solido è sempre più freddo": "Il ferro fuso è liquido e caldissimo; il ghiaccio è solido e freddo: non c'è regola." } },

  // ---------------------------------------------------------------- fascia 2
  { topic: "moto", difficulty: 2, difficulty8: true,
    prompt: "Che cosa vuol dire che un'auto va a 50 chilometri all'ora?",
    answer: "farebbe 50 km in un'ora", distractors: ["ha percorso 50 km finora", "impiega 50 minuti a partire", "pesa 50 volte più di prima"],
    explanation: "La velocità è un rapporto, non una distanza: dice quanti chilometri per ogni ora, anche se l'auto viaggia solo dieci minuti. È il primo numero che a scuola si impara a leggere come rapporto.",
    distractorWhy: { "ha percorso 50 km finora": "Quella sarebbe la distanza già fatta, che è un'altra informazione.", "impiega 50 minuti a partire": "Il tempo di partenza non c'entra con la velocità.", "pesa 50 volte più di prima": "La velocità non ha niente a che vedere con il peso." } },
  { topic: "moto", difficulty: 2, difficulty8: true,
    prompt: "Un ciclista accelera. Che cosa sta cambiando?",
    answer: "la sua velocità", distractors: ["la strada che percorre", "la sua massa corporea", "la direzione del vento"],
    explanation: "Accelerare vuol dire cambiare velocità, e vale anche quando si rallenta o si curva a velocità costante: anche cambiare direzione è un'accelerazione, perché cambia il verso del movimento.",
    distractorWhy: { "la strada che percorre": "La distanza cresce anche andando a velocità costante.", "la sua massa corporea": "La massa resta la stessa qualunque cosa faccia.", "la direzione del vento": "Il vento è esterno e non dipende da come pedala." } },
  { topic: "metodo", difficulty: 2, difficulty8: true,
    prompt: "In un esperimento sulla caduta dei corpi, che cosa va tenuto uguale?",
    answer: "tutto tranne ciò che si prova", distractors: ["soltanto l'altezza di partenza", "soltanto il peso degli oggetti", "niente, purché si ripeta"],
    explanation: "Si cambia una cosa sola per volta, e tutto il resto resta fermo: altrimenti un risultato diverso non dice quale delle due variazioni lo ha prodotto. È la regola che rende un esperimento una prova.",
    distractorWhy: { "soltanto l'altezza di partenza": "Non basta: anche la forma e l'aria attorno cambierebbero il risultato.", "soltanto il peso degli oggetti": "Se è il peso che si sta provando, è proprio la cosa che deve variare.", "niente, purché si ripeta": "Ripetere un esperimento confuso lo rende confuso più volte." } },
  { topic: "metodo", difficulty: 2, difficulty8: true,
    prompt: "Che differenza c'è fra osservare e misurare?",
    answer: "misurare dà un numero", distractors: ["osservare richiede più tempo", "misurare si fa solo in laboratorio", "osservare è sempre più preciso"],
    explanation: "«L'acqua è calda» è un'osservazione e dipende da chi tocca; «l'acqua è a 48 gradi» è una misura e vale per tutti. Passare dall'una all'altra è ciò che ha reso possibile la fisica.",
    distractorWhy: { "osservare richiede più tempo": "Il tempo non distingue le due cose: si può osservare in un attimo.", "misurare si fa solo in laboratorio": "Si misura ovunque: un metro e un orologio bastano.", "osservare è sempre più preciso": "È il contrario: l'osservazione dipende dalla persona." } },
  { topic: "pressione", difficulty: 2, difficulty8: true,
    prompt: "Perché è più facile camminare sulla neve con le racchette che con gli scarponi?",
    answer: "il peso si distribuisce su più superficie", distractors: ["le racchette sono molto più leggere", "gli scarponi scivolano di più sul ghiaccio", "le racchette scaldano meno la neve"],
    explanation: "La pressione è la forza divisa per la superficie su cui agisce: lo stesso peso su un'area più larga preme meno in ogni punto, e la neve regge. Lo stesso principio spiega perché un chiodo appuntito entra e uno spuntato no.",
    distractorWhy: { "le racchette sono molto più leggere": "Pesano di più, e funzionano lo stesso: non è il peso a contare.", "gli scarponi scivolano di più sul ghiaccio": "Il problema sulla neve fresca è sprofondare, non scivolare.", "le racchette scaldano meno la neve": "Il calore del piede non ha effetti apprezzabili in quei tempi." } },
  { topic: "pressione", difficulty: 2, difficulty8: true,
    prompt: "Perché in fondo a una piscina senti premere di più sulle orecchie?",
    answer: "sopra di te c'è più acqua", distractors: ["l'acqua è più fredda in basso", "l'acqua in fondo è più densa", "il fondo spinge verso l'alto"],
    explanation: "La pressione di un liquido cresce con la profondità perché sopra ogni punto grava la colonna d'acqua che sta più in alto. Non dipende da quanto è larga la piscina: solo da quanto si è scesi.",
    distractorWhy: { "l'acqua è più fredda in basso": "La temperatura può cambiare ma non produce quella spinta sulle orecchie.", "l'acqua in fondo è più densa": "In una piscina la densità è praticamente la stessa ovunque.", "il fondo spinge verso l'alto": "La spinta esiste ma agisce sul corpo intero, non sui timpani." } },
  { topic: "galleggiamento", difficulty: 2, difficulty8: true,
    prompt: "Perché una nave d'acciaio galleggia e un chiodo affonda?",
    answer: "la nave è cava e sposta più acqua", distractors: ["l'acciaio della nave è più leggero", "la nave è tenuta a galla dal motore", "il chiodo è appuntito e taglia l'acqua"],
    explanation: "Conta la densità media, non il materiale: lo scafo racchiude aria, quindi nel suo insieme pesa meno dell'acqua che sposta. Lo stesso acciaio compattato in un chiodo va a fondo.",
    distractorWhy: { "l'acciaio della nave è più leggero": "È lo stesso acciaio: cambia come è disposto nello spazio.", "la nave è tenuta a galla dal motore": "Una nave galleggia anche a motori spenti, in porto.", "il chiodo è appuntito e taglia l'acqua": "Anche un chiodo di piatto affonda: la forma non è il punto." } },
  { topic: "galleggiamento", difficulty: 2, difficulty8: true,
    prompt: "Un oggetto immerso riceve una spinta verso l'alto pari a...",
    answer: "il peso dell'acqua spostata", distractors: ["il peso dell'oggetto immerso", "metà del peso dell'oggetto", "il volume totale della vasca"],
    explanation: "È il principio di Archimede: la spinta dipende da quanta acqua l'oggetto manda via, non da quanto pesa lui. Se quel peso d'acqua supera il suo, l'oggetto sale.",
    distractorWhy: { "il peso dell'oggetto immerso": "Se fosse così tutto galleggerebbe sempre, restando in equilibrio.", "metà del peso dell'oggetto": "Non c'è nessuna frazione fissa: dipende dall'acqua spostata.", "il volume totale della vasca": "Una vasca più grande non aumenta la spinta su un sassolino." } },
  { topic: "correnti", difficulty: 2, difficulty8: true,
    prompt: "Perché in un circuito con l'interruttore aperto la lampadina è spenta?",
    answer: "la corrente non ha un giro chiuso", distractors: ["l'elettricità esce dal punto aperto", "la pila si scarica più in fretta", "il filo diventa troppo freddo"],
    explanation: "La corrente ha bisogno di un percorso che torni al punto di partenza: un'interruzione in qualunque punto ferma tutto il giro. È per questo che una lucina bruciata poteva spegnere l'intera fila delle vecchie luci di Natale.",
    distractorWhy: { "l'elettricità esce dal punto aperto": "Non esce niente: semplicemente non parte nessun movimento.", "la pila si scarica più in fretta": "A circuito aperto la pila dura di più, non di meno.", "il filo diventa troppo freddo": "La temperatura del filo non decide se il circuito funziona." } },
  { topic: "correnti", difficulty: 2, difficulty8: true,
    prompt: "Quale di questi materiali NON conduce corrente?",
    answer: "la plastica", distractors: ["il rame dei fili", "l'alluminio in foglio", "l'acqua del rubinetto"],
    explanation: "Nei metalli alcune cariche sono libere di spostarsi, nella plastica no: per questo i fili sono di rame dentro e di plastica fuori. L'acqua pura conduce poco, ma quella del rubinetto contiene sali e conduce abbastanza da essere pericolosa.",
    distractorWhy: { "il rame dei fili": "È il conduttore più usato proprio per la sua efficienza.", "l'alluminio in foglio": "È un metallo e conduce bene, anche se sottile.", "l'acqua del rubinetto": "I sali disciolti la rendono conduttrice: è la ragione dei divieti in bagno." } },
  { topic: "leve", difficulty: 2, difficulty8: true,
    prompt: "Per sollevare un sasso pesante con un bastone, dove conviene mettere il punto di appoggio?",
    answer: "vicino al sasso", distractors: ["vicino alle tue mani", "esattamente a metà bastone", "sotto il centro del sasso"],
    explanation: "Più il fulcro è vicino al carico, più lungo diventa il braccio su cui spingi e meno forza serve. Il prezzo è che la tua mano deve fare un tragitto più lungo: la leva scambia forza con spostamento.",
    distractorWhy: { "vicino alle tue mani": "Accorcia il tuo braccio di leva e rende tutto più faticoso.", "esattamente a metà bastone": "Dà un vantaggio nullo: serve la stessa forza del peso.", "sotto il centro del sasso": "Lì non c'è nessun appoggio da cui far ruotare il bastone." } },
  { topic: "energia", difficulty: 2, difficulty8: true,
    prompt: "In una centrale idroelettrica, l'energia dell'acqua che cade diventa...",
    answer: "energia elettrica", distractors: ["energia chimica di riserva", "energia luminosa diretta", "energia sonora del salto"],
    explanation: "L'acqua in alto ha energia di posizione; cadendo diventa movimento, il movimento fa girare una turbina e la turbina produce elettricità. Ogni passaggio ne perde un po' in calore: nessuna trasformazione è completa.",
    distractorWhy: { "energia chimica di riserva": "Nessuna reazione chimica avviene: è tutto meccanico ed elettrico.", "energia luminosa diretta": "La luce arriva dopo, quando l'elettricità accende una lampadina.", "energia sonora del salto": "Un po' di energia diventa rumore, ma è uno spreco, non lo scopo." } },
  { topic: "materia", difficulty: 2, difficulty8: true,
    prompt: "Che cosa succede alle particelle di un solido mentre si scioglie?",
    answer: "cominciano a scorrere", distractors: ["diventano più grandi di prima", "si moltiplicano rapidamente", "smettono di muoversi del tutto"],
    explanation: "Le particelle sono sempre le stesse: cambia quanto sono legate. Nel solido vibrano al loro posto, nel liquido hanno abbastanza energia per scivolare una sull'altra pur restando vicine.",
    distractorWhy: { "diventano più grandi di prima": "La particella non cambia dimensione: cambia la distanza fra loro.", "si moltiplicano rapidamente": "Il numero resta identico: scaldare non crea materia.", "smettono di muoversi del tutto": "È il contrario: si muovono di più, ed è per questo che scorrono." } },

  // ---------------------------------------------------------------- fascia 7
  // Da qui i conti, perché il fenomeno è stato visto e la formula serve a
  // prevederlo. È anche dove stanno i `numeric_input`.
  { topic: "moto", difficulty: 7, difficulty8: true, format: "numeric_input",
    prompt: "Un ciclista percorre 45 chilometri in 3 ore a velocità costante. Qual è la sua velocità in km/h?",
    answer: "15",
    explanation: "La velocità è lo spazio diviso il tempo: 45 diviso 3 fa 15. Costante vuol dire che in ogni ora percorre gli stessi chilometri, quindi la media coincide con la velocità in ogni istante." },
  { topic: "moto", difficulty: 7, difficulty8: true, format: "numeric_input",
    prompt: "Un treno viaggia a 80 km/h. Quanti chilometri percorre in 3 ore?",
    answer: "240",
    explanation: "Lo spazio è la velocità moltiplicata per il tempo: 80 per 3 fa 240. È la stessa formula di prima girata, e sapere girarla è ciò che rende utile impararla una volta sola." },
  { topic: "moto", difficulty: 7, difficulty8: true,
    prompt: "Un'auto rallenta da 60 a 20 km/h. La sua accelerazione è...",
    answer: "negativa", distractors: ["positiva ma piccola", "nulla per definizione", "impossibile da definire"],
    explanation: "L'accelerazione è la variazione di velocità nel tempo, e se la velocità diminuisce quella variazione è negativa. Frenare è accelerare all'indietro: lo dicono i conti prima ancora dell'intuizione.",
    distractorWhy: { "positiva ma piccola": "Sarebbe positiva solo se la velocità aumentasse, anche di poco.", "nulla per definizione": "È nulla quando la velocità resta costante, e qui cambia molto.", "impossibile da definire": "Si definisce benissimo: è il rapporto fra la variazione e il tempo impiegato." } },
  { topic: "correnti", difficulty: 7, difficulty8: true,
    prompt: "Due lampadine in serie: se una si brucia, che cosa succede all'altra?",
    answer: "si spegne anche lei", distractors: ["diventa più luminosa", "resta identica a prima", "si brucia subito dopo"],
    explanation: "In serie la corrente passa da entrambe in fila: interrompere in un punto interrompe tutto il giro. In parallelo invece ogni lampadina ha il suo percorso, e per questo negli impianti di casa si usa il parallelo.",
    distractorWhy: { "diventa più luminosa": "Succede in parallelo togliendo un carico, non in serie.", "resta identica a prima": "Servirebbe un percorso indipendente, che in serie non esiste.", "si brucia subito dopo": "Non le arriva più corrente, quindi non può bruciarsi." } },
  { topic: "correnti", difficulty: 7, difficulty8: true,
    prompt: "Che cosa fa una resistenza in un circuito?",
    answer: "ostacola il passaggio di corrente", distractors: ["accumula la corrente per dopo", "cambia il verso della corrente", "produce corrente aggiuntiva"],
    explanation: "Ostacolando il passaggio, la resistenza limita la corrente e trasforma parte dell'energia in calore: è così che funzionano un fornello elettrico e un asciugacapelli, dove il calore è lo scopo e non lo spreco.",
    distractorWhy: { "accumula la corrente per dopo": "Quello lo fa un condensatore, che è un componente diverso.", "cambia il verso della corrente": "Il verso lo decide il generatore, non la resistenza.", "produce corrente aggiuntiva": "Nessun componente passivo crea corrente: la consuma." } },
  { topic: "energia", difficulty: 7, difficulty8: true,
    prompt: "Perché nessuna macchina restituisce tutta l'energia che riceve?",
    answer: "una parte diventa sempre calore", distractors: ["l'energia si consuma nell'uso", "le macchine sono costruite male", "una parte torna al generatore"],
    explanation: "L'energia si conserva, ma non tutta resta utilizzabile: attriti e resistenze ne trasformano una quota in calore disperso, che non si può riconvertire del tutto. È il motivo per cui il moto perpetuo è impossibile, non difficile.",
    distractorWhy: { "l'energia si consuma nell'uso": "L'energia non si consuma mai: cambia forma e si degrada.", "le macchine sono costruite male": "Anche la macchina perfetta perderebbe: è una legge, non un difetto.", "una parte torna al generatore": "Il calore disperso si diffonde nell'ambiente e non torna indietro." } },
  { topic: "leve", difficulty: 7, difficulty8: true, format: "numeric_input",
    prompt: "Una leva è in equilibrio: a sinistra un peso di 20 N a 3 metri dal fulcro, a destra un peso a 2 metri. Quanti newton pesa quello di destra?",
    answer: "30",
    explanation: "In equilibrio i due prodotti forza per distanza sono uguali: 20 per 3 fa 60, quindi a destra serve 60 diviso 2, cioè 30 newton. Braccio più corto vuol dire forza più grande." },
  { topic: "pressione", difficulty: 7, difficulty8: true, format: "numeric_input",
    prompt: "Una forza di 200 newton preme su una superficie di 4 metri quadrati. Qual è la pressione in pascal?",
    answer: "50",
    explanation: "La pressione è la forza divisa la superficie: 200 diviso 4 fa 50 pascal. Lo stesso peso su un metro quadrato darebbe 200 pascal — quattro volte tanto, ed è per questo che le racchette da neve funzionano." },
  { topic: "misure", difficulty: 7, difficulty8: true,
    prompt: "Perché la massa di un oggetto non cambia sulla Luna e il peso sì?",
    answer: "il peso dipende dalla gravità", distractors: ["sulla Luna manca del tutto l'aria", "la massa si misura in modo diverso", "sulla Luna gli oggetti si comprimono"],
    explanation: "La massa è quanta materia c'è e viaggia con l'oggetto; il peso è la forza con cui un pianeta la attira, e sulla Luna quella forza è circa un sesto. Un astronauta con la stessa massa pesa sei volte meno.",
    distractorWhy: { "sulla Luna manca del tutto l'aria": "L'assenza d'aria toglie l'attrito, non cambia il peso.", "la massa si misura in modo diverso": "Si misura allo stesso modo ovunque: è proprio questo il suo pregio.", "sulla Luna gli oggetti si comprimono": "Le dimensioni restano identiche: cambia solo la forza di attrazione." } },
  { topic: "galleggiamento", difficulty: 7, difficulty8: true,
    prompt: "Un sottomarino scende. Che cosa ha aumentato?",
    answer: "il proprio peso complessivo", distractors: ["la velocità dei suoi motori", "la temperatura interna dello scafo", "la superficie esposta all'acqua"],
    explanation: "Riempendo d'acqua le casse di zavorra il sottomarino aumenta il proprio peso senza cambiare volume: la spinta di Archimede resta uguale e il peso la supera. Per risalire svuota le casse con aria compressa.",
    distractorWhy: { "la velocità dei suoi motori": "I motori spostano in avanti: la profondità si regola con la zavorra.", "la temperatura interna dello scafo": "Non ha effetti apprezzabili sulla galleggiabilità.", "la superficie esposta all'acqua": "Lo scafo è rigido: la sua superficie non cambia." } },
  { topic: "calore", difficulty: 7, difficulty8: true,
    prompt: "Perché una pentola d'acqua che bolle resta a 100 gradi anche col fuoco alto?",
    answer: "il calore serve a evaporare", distractors: ["il fuoco alto disperde più calore", "l'acqua non può superare i 100 gradi", "il metallo assorbe il calore in più"],
    explanation: "Durante un passaggio di stato il calore fornito non alza la temperatura: serve tutto a staccare le particelle dal liquido. Il fuoco alto fa bollire più in fretta, non più caldo.",
    distractorWhy: { "il fuoco alto disperde più calore": "Ne fornisce di più, infatti l'acqua evapora prima.", "l'acqua non può superare i 100 gradi": "Può: in pentola a pressione arriva oltre, perché la pressione è maggiore.", "il metallo assorbe il calore in più": "La pentola si scalda ma raggiunge presto un equilibrio." } },

  // ---------------------------------------------------------------- fascia 8
  { topic: "onde-luce", difficulty: 8, difficulty8: true,
    prompt: "Un pesce visto dalla riva sembra più in alto di dove si trova davvero. Perché?",
    answer: "l'occhio suppone la luce dritta", distractors: ["l'acqua ingrandisce ciò che contiene", "il pesce nuota più in alto quando è visto", "la superficie riflette la sua immagine"],
    explanation: "Uscendo dall'acqua la luce cambia direzione, ma il cervello continua a prolungare all'indietro in linea retta il raggio che arriva: colloca il pesce dove il raggio sarebbe partito se non avesse mai piegato.",
    distractorWhy: { "l'acqua ingrandisce ciò che contiene": "L'ingrandimento c'è, ma sposta la dimensione, non la posizione apparente.", "il pesce nuota più in alto quando è visto": "Il pesce non sa di essere guardato e resta dove sta.", "la superficie riflette la sua immagine": "La riflessione dà un'immagine sopra il pelo dell'acqua, non un pesce spostato sotto." } },
  { topic: "onde-luce", difficulty: 8, difficulty8: true,
    prompt: "Che cosa distingue un suono acuto da uno grave?",
    answer: "la frequenza dell'onda", distractors: ["l'intensità con cui arriva", "la distanza dalla sorgente", "la durata complessiva della nota"],
    explanation: "La frequenza è quante oscillazioni al secondo: più sono, più il suono è acuto. L'intensità è un'altra cosa e si sente come volume: una nota grave può essere fortissima e una acuta appena percepibile.",
    distractorWhy: { "l'intensità con cui arriva": "È il volume: un suono può essere forte e grave insieme.", "la distanza dalla sorgente": "Allontanandosi il suono si indebolisce ma non diventa più grave.", "la durata complessiva della nota": "Una nota lunga e una breve possono avere la stessa altezza." } },
  { topic: "materia", difficulty: 8, difficulty8: true, format: "numeric_input",
    prompt: "Un blocco ha massa 300 grammi e volume 100 centimetri cubi. Qual è la sua densità in grammi per centimetro cubo?",
    answer: "3",
    explanation: "La densità è la massa divisa il volume: 300 diviso 100 fa 3. Essendo maggiore di 1, cioè della densità dell'acqua, quel blocco affonda — e il conto lo dice prima di provare." },
  { topic: "materia", difficulty: 8, difficulty8: true,
    prompt: "Due cubi hanno lo stesso volume ma masse diverse. Che cosa è certamente diverso?",
    answer: "la densità", distractors: ["la temperatura di fusione", "il colore della superficie", "la forma dei due cubi"],
    explanation: "La densità è massa diviso volume: a parità di volume, masse diverse danno densità diverse per forza. Sono probabilmente due materiali differenti, e questo è il modo più rapido per accorgersene senza analisi.",
    distractorWhy: { "la temperatura di fusione": "Probabile ma non certo: due materiali diversi possono fondere a temperature vicine.", "il colore della superficie": "Due materiali diversi possono avere lo stesso colore.", "la forma dei due cubi": "Sono cubi tutti e due e hanno lo stesso volume: la forma coincide." } },
  { topic: "energia", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "L'energia non si crea e non si distrugge. Come si chiama il principio che lo afferma? Una parola.",
    answer: "conservazione", accept: ["la conservazione", "conservazione dell'energia", "principio di conservazione"],
    explanation: "È il principio più solido della fisica: seguendo l'energia da una forma all'altra si ritrova sempre tutta, e di solito la parte mancante è finita in calore disperso." },
  { topic: "leve", difficulty: 8, difficulty8: true,
    prompt: "Una carriola è una leva di quale genere?",
    answer: "seconda", distractors: ["prima", "terza", "quarta o quinta"],
    explanation: "Nella carriola il fulcro è la ruota, il carico sta in mezzo e la forza sta alle maniglie: è il secondo genere, quello che dà sempre un vantaggio. Nel primo il fulcro sta in mezzo, nel terzo ci sta la forza.",
    distractorWhy: { "prima": "Nella prima il fulcro sta fra forza e carico, come nell'altalena.", "terza": "Nella terza la forza sta in mezzo, come nella pinza da ghiaccio: costa più fatica.", "quarta o quinta": "I generi di leva sono soltanto tre: il quarto non esiste." } },
  { topic: "pressione", difficulty: 8, difficulty8: true,
    prompt: "Perché in montagna l'acqua bolle sotto i 100 gradi?",
    answer: "la pressione dell'aria è minore", distractors: ["l'aria di montagna è più fredda", "l'acqua è più pura in quota", "il fuoco scalda meno in altura"],
    explanation: "Bollire vuol dire che il vapore riesce a vincere la pressione che lo schiaccia: dove l'aria preme meno, ci riesce prima. È anche il motivo per cui in quota la pasta cuoce peggio: l'acqua è meno calda.",
    distractorWhy: { "l'aria di montagna è più fredda": "La temperatura dell'aria non cambia quella a cui l'acqua bolle.", "l'acqua è più pura in quota": "La purezza sposta il punto di ebollizione pochissimo, e nel verso opposto.", "il fuoco scalda meno in altura": "Con meno ossigeno il fuoco rende un po' meno, ma non è questo a spostare i gradi." } },
  { topic: "galleggiamento", difficulty: 8, difficulty8: true,
    prompt: "Perché si galleggia più facilmente nel mare che in piscina?",
    answer: "l'acqua salata è più densa", distractors: ["il mare è più profondo", "le onde spingono verso l'alto", "l'acqua di mare è più fredda"],
    explanation: "Il sale disciolto aumenta la densità dell'acqua: a parità di volume spostato la spinta di Archimede è maggiore. Nel Mar Morto, saturo di sali, si galleggia senza nemmeno muoversi.",
    distractorWhy: { "il mare è più profondo": "La profondità non cambia la spinta su un corpo in superficie.", "le onde spingono verso l'alto": "Le onde alzano e abbassano: mediamente non aggiungono spinta.", "l'acqua di mare è più fredda": "La temperatura cambia la densità pochissimo, molto meno del sale." } },
  { topic: "correnti", difficulty: 8, difficulty8: true,
    prompt: "Perché gli impianti di casa hanno le prese in parallelo e non in serie?",
    answer: "ogni apparecchio resta indipendente", distractors: ["il parallelo consuma molta meno energia", "in serie i fili si scaldano troppo", "il parallelo richiede meno cavo"],
    explanation: "In parallelo ogni apparecchio ha il suo percorso e la sua tensione piena: spegnerne uno non tocca gli altri, e ognuno assorbe la corrente che gli serve. In serie basterebbe una lampadina bruciata per spegnere la casa.",
    distractorWhy: { "il parallelo consuma molta meno energia": "Il consumo dipende dagli apparecchi, non dal collegamento.", "in serie i fili si scaldano troppo": "In serie passa meno corrente, quindi si scalderebbero meno.", "il parallelo richiede meno cavo": "Ne richiede di più: ogni presa ha il suo ramo." } },
  { topic: "misure", difficulty: 8, difficulty8: true, format: "numeric_input",
    prompt: "Quanti centimetri cubi ci sono in un decimetro cubo?",
    answer: "1000",
    explanation: "Passando alle unità di volume il fattore va elevato al cubo: dieci centimetri per lato fanno 10 per 10 per 10, cioè mille. È l'errore più comune delle conversioni, e vale un litro esatto." },
  { topic: "metodo", difficulty: 8, difficulty8: true,
    prompt: "Un modello fisico che prevede bene ma semplifica la realtà va scartato?",
    answer: "no, se si conoscono i suoi limiti", distractors: ["sì, la fisica descrive tutto esattamente", "sì, ogni semplificazione è un errore", "no, i modelli non vanno mai discussi"],
    explanation: "Ogni modello trascura qualcosa: si trattano i pianeti come punti e le corde come prive di peso. Il modello è utile finché si sa dove smette di valere — ed è quel confine, non la formula, la cosa da imparare.",
    distractorWhy: { "sì, la fisica descrive tutto esattamente": "Nessuna teoria descrive tutto: si sceglie sempre che cosa trascurare.", "sì, ogni semplificazione è un errore": "Senza semplificare non si potrebbe calcolare nulla.", "no, i modelli non vanno mai discussi": "Discuterli è esattamente il lavoro: è così che vengono sostituiti." } },
  { topic: "forze", difficulty: 8, difficulty8: true,
    prompt: "Un libro fermo sul tavolo: quali forze agiscono su di lui?",
    answer: "il peso e la spinta del tavolo", distractors: ["nessuna, perché è fermo", "solo il peso verso il basso", "solo l'attrito con la superficie"],
    explanation: "Fermo non vuol dire senza forze: vuol dire che le forze si annullano. Il tavolo spinge in su esattamente quanto il peso tira in giù, e se non lo facesse il libro cadrebbe.",
    distractorWhy: { "nessuna, perché è fermo": "L'assenza di movimento indica equilibrio fra forze, non assenza.", "solo il peso verso il basso": "Con il solo peso il libro accelererebbe verso il pavimento.", "solo l'attrito con la superficie": "L'attrito agisce di lato e qui non serve: nessuno spinge il libro." } },
  { topic: "forze", difficulty: 8, difficulty8: true,
    prompt: "Spingi un muro e il muro non si muove. Che cosa fa il muro?",
    answer: "spinge te con la stessa forza", distractors: ["assorbe la forza che ricevi", "non esercita nessuna forza", "restituisce metà della spinta"],
    explanation: "Le forze vanno sempre a coppie e sono uguali e opposte: non è il muro a essere più forte, è che spinge te esattamente quanto tu spingi lui. È il motivo per cui si cammina, si nuota e si vola.",
    distractorWhy: { "assorbe la forza che ricevi": "Le forze non si assorbono: si esercitano sempre a coppie.", "non esercita nessuna forza": "Allora la tua mano attraverserebbe il muro senza fermarsi.", "restituisce metà della spinta": "Non c'è nessuna frazione: le due forze sono esattamente uguali." } },
];
