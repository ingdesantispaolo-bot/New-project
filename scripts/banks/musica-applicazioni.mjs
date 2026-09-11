// Musica — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Settima materia convertita alla regola delle dispense
// (`docs/REGOLA_DISPENSE.md`). Otto argomenti, quindici dispense: `intervalli`
// ne ha una sola, perché il banco lo interroga soltanto alle fasce 6, 7 e 8.
//
// ## Il filo che tiene insieme tutte e quindici
//
// Un suono porta **tre informazioni indipendenti**: quanto è acuto (altezza),
// quanto dura (durata) e con che colore suona (timbro). La notazione le scrive
// con segni diversi nello stesso posto — la posizione sul rigo, la forma della
// nota, le lettere sotto — e quasi tutti gli errori di lettura nascono dall'aver
// letto una delle tre al posto di un'altra.
//
// È dichiarato nella prima dispensa e ripreso in tutte le altre, e le domande lo
// applicano: «una nota scritta più in alto dura di più?» misura esattamente
// quella confusione, e non si può rispondere a memoria.
//
// ## La forma delle domande
//
// Due tipi, e il secondo è quello che vale:
//
//   - **il conto che deve tornare**: sommare le durate di una battuta e
//     confrontarle con il tempo, contare i gradi di un intervallo includendo
//     entrambe le note. Sono verifiche, non ricordi;
//   - **la previsione**: che cosa distingue due suoni, perché due esecuzioni
//     suonano diverse, dove collocare uno strumento mai visto.
//
// Le poche domande di nome — le famiglie, i segni di dinamica, le note — sono
// coperte dal controllo 4b, perché musica entra fra le `MATERIE_DI_RICHIAMO`.

export const MUSICA_APPLICAZIONI = [

  // =============================================================== NOTE
  { topic: "note", difficulty: 1, difficulty8: true, applica: "musica-note-base",
    prompt: "Dopo il si, quale nota viene?",
    answer: "Di nuovo il do", distractors: ["Una nota nuova", "Il la un'altra volta", "Dipende dallo strumento"],
    explanation: "I nomi sono sette e ricominciano: la nota dopo il si è ancora un do, semplicemente più acuto di quello da cui si era partiti.",
    distractorWhy: { "Una nota nuova": "Non esiste un ottavo nome: il sistema è ciclico, e arrivati in fondo si riparte.", "Il la un'altra volta": "Il la viene prima del si, non dopo: si tornerebbe indietro invece di proseguire.", "Dipende dallo strumento": "L'ordine delle note è lo stesso per qualunque strumento: cambia il timbro, non la successione." } },

  { topic: "note", difficulty: 3, difficulty8: true, applica: "musica-note-base",
    prompt: "Due strumenti suonano una nota che vibra 440 volte al secondo. È la stessa nota?",
    answer: "Sì, la frequenza la definisce", distractors: ["No, dipende dallo strumento", "No, se uno è più forte", "Solo se sono della stessa famiglia"],
    explanation: "L'altezza dipende dalla frequenza e da nient'altro: è per questo che si riconosce la stessa nota anche su strumenti diversissimi.",
    distractorWhy: { "No, dipende dallo strumento": "Lo strumento cambia il timbro, cioè il colore: l'altezza resta quella della frequenza.", "No, se uno è più forte": "L'intensità è una terza proprietà indipendente: non sposta l'altezza di un suono.", "Solo se sono della stessa famiglia": "La famiglia riguarda come nasce il suono, non quale nota sia." } },

  { topic: "note", difficulty: 5, difficulty8: true, applica: "musica-note-alta",
    prompt: "Un la vibra 440 volte al secondo. Quante volte vibra il la un'ottava sopra?",
    answer: "880", distractors: ["440 come prima", "660", "1320"],
    explanation: "Un'ottava è un rapporto esatto di due a uno: per questo l'orecchio riconosce le due note come «la stessa», e i nomi ricominciano invece di continuare.",
    distractorWhy: { "440 come prima": "Sarebbe la stessa identica nota: un'ottava sopra è un suono diverso, anche se porta lo stesso nome.", "660": "È una volta e mezza, che corrisponde alla quinta e non all'ottava.", "1320": "È il triplo, cioè due ottave più una quinta: si è saltato troppo in alto." } },

  { topic: "note", difficulty: 6, difficulty8: true, applica: "musica-note-alta",
    prompt: "Sul pianoforte, perché fra il mi e il fa non c'è un tasto nero?",
    answer: "Perché distano già un semitono", distractors: ["Perché sono note poco usate", "Perché il mi non si può alterare", "Perché è una scelta dei costruttori"],
    explanation: "Il semitono è il passo più piccolo del sistema: fra due note che distano già così non c'è spazio per nessun suono intermedio da rappresentare.",
    distractorWhy: { "Perché sono note poco usate": "Sono usate quanto le altre: la disposizione dei tasti non dipende dalla frequenza d'uso.", "Perché il mi non si può alterare": "Si può, e il risultato coincide con il fa: è proprio il segno che non c'è spazio in mezzo.", "Perché è una scelta dei costruttori": "La disposizione riflette la struttura della scala, non una preferenza costruttiva." } },

  // ============================================================ LETTURA
  { topic: "lettura", difficulty: 3, difficulty8: true, applica: "musica-lettura-base",
    format: "short_answer",
    prompt: "Come si chiama l'insieme delle cinque righe su cui si scrive la musica?",
    answer: "pentagramma", accept: ["il pentagramma"],
    explanation: "Con i quattro spazi fra le righe fa nove posizioni, e la regola di lettura è immediata: più in alto sta la nota, più acuto è il suono." },

  { topic: "lettura", difficulty: 4, difficulty8: true, applica: "musica-lettura-base",
    prompt: "Due note sono nella stessa posizione sul rigo, ma una è piena con il gambo e l'altra vuota. Che cosa cambia?",
    answer: "La durata, non l'altezza", distractors: ["L'altezza, non la durata", "Il volume di esecuzione", "Lo strumento che la suona"],
    explanation: "La posizione dice quanto è acuta, la forma dice quanto dura: sono due informazioni indipendenti scritte nello stesso simbolo.",
    distractorWhy: { "L'altezza, non la durata": "È l'inverso: l'altezza dipende da dove sta la nota, e le due note stanno nello stesso posto.", "Il volume di esecuzione": "Il volume lo indica la dinamica, con lettere scritte sotto il rigo.", "Lo strumento che la suona": "Lo strumento è scritto all'inizio della parte, e non dipende dalla forma delle note." } },

  { topic: "lettura", difficulty: 6, difficulty8: true, applica: "musica-lettura-alta",
    prompt: "Leggi un rigo in chiave di basso con l'abitudine della chiave di violino. Che cosa succede?",
    answer: "Sbagli tutte le note ugualmente", distractors: ["Sbagli soltanto le note più acute", "Sbagli solo le durate", "Non cambia niente"],
    explanation: "La chiave sposta il riferimento di tutte le posizioni della stessa quantità: la melodia resta coerente e per questo l'errore non si nota leggendo.",
    distractorWhy: { "Sbagli soltanto le note più acute": "Lo spostamento vale per tutto il rigo: non c'è nessuna zona che resti corretta.", "Sbagli solo le durate": "Le durate stanno nella forma delle note e la chiave non le tocca affatto.", "Non cambia niente": "Cambia tutto: la stessa posizione porta un nome diverso a seconda della chiave." } },

  { topic: "lettura", difficulty: 8, difficulty8: true, applica: "musica-lettura-alta",
    prompt: "Perché non si usa una chiave sola per tutti gli strumenti?",
    answer: "Perché le estensioni sono diverse", distractors: ["Perché ogni epoca ne ha inventata una", "Perché così si legge più in fretta", "Perché alcune note non esistono"],
    explanation: "Con un riferimento unico moltissima musica finirebbe scritta quasi tutta su linee addizionali, cioè illeggibile: ogni chiave fa stare comoda sulle cinque righe l'estensione di chi la usa.",
    distractorWhy: { "Perché ogni epoca ne ha inventata una": "La ragione non è storica ma pratica, e le chiavi in uso convivono nello stesso brano.", "Perché così si legge più in fretta": "Vero come effetto, ma è la conseguenza: la causa è che le estensioni degli strumenti sono diverse.", "Perché alcune note non esistono": "Tutte le note esistono in ogni chiave: cambia solo dove vengono scritte." } },

  // ============================================================== RITMO
  { topic: "ritmo", difficulty: 2, difficulty8: true, applica: "musica-ritmo-base",
    format: "numeric_input",
    prompt: "Quanti battiti vale una minima?",
    answer: "2",
    explanation: "Ogni figura vale la metà della precedente: semibreve quattro, minima due, semiminima uno, croma mezzo. Basta ricordare da dove si parte e dimezzare." },

  { topic: "ritmo", difficulty: 4, difficulty8: true, applica: "musica-ritmo-base",
    prompt: "Una nota scritta più in alto sul pentagramma dura di più?",
    answer: "No, la durata sta nella figura", distractors: ["Sì, più è alta più dura", "Sì, ma solo in chiave di violino", "Dipende dal tempo del brano"],
    explanation: "Altezza e durata sono due informazioni indipendenti: la posizione dice quanto la nota è acuta, la forma del simbolo dice quanto dura.",
    distractorWhy: { "Sì, più è alta più dura": "È la confusione fra i due assi: la posizione verticale riguarda solo l'altezza del suono.", "Sì, ma solo in chiave di violino": "La chiave cambia quale nota sia, non quanto duri: non c'entra con la durata in nessun caso.", "Dipende dal tempo del brano": "Il tempo cambia quanto vale un battito, ma non lega mai la durata alla posizione sul rigo." } },

  { topic: "ritmo", difficulty: 6, difficulty8: true, applica: "musica-ritmo-alta",
    prompt: "In 4/4 una battuta contiene una minima e una semiminima. Cosa manca?",
    answer: "Manca una semiminima", distractors: ["Non manca niente", "Manca una minima", "Manca una croma"],
    explanation: "Due più uno fa tre, e servono quattro battiti: la differenza è di un battito, cioè esattamente il valore di una semiminima.",
    distractorWhy: { "Non manca niente": "La somma fa tre e il tempo ne chiede quattro: la battuta non torna.", "Manca una minima": "Una minima vale due battiti, e ne manca uno solo: si arriverebbe a cinque.", "Manca una croma": "La croma vale mezzo battito, e ne manca uno intero: resterebbe ancora scoperto mezzo battito." } },

  { topic: "ritmo", difficulty: 7, difficulty8: true, applica: "musica-ritmo-alta",
    prompt: "Ritmo e intervallo misurano la stessa cosa?",
    answer: "No, durata contro altezza", distractors: ["Sì, sono due nomi uguali", "No, forte contro piano", "No, strumento contro voce"],
    explanation: "Sono i due assi di un brano: il ritmo organizza le durate nel tempo, l'intervallo misura la distanza in altezza fra due note.",
    distractorWhy: { "Sì, sono due nomi uguali": "Misurano grandezze diverse, e confonderli porta a descrivere come «più alta» una nota che semplicemente dura di più.", "No, forte contro piano": "Quella è la dinamica, che è una terza cosa ancora e non è nessuna delle due.", "No, strumento contro voce": "La differenza fra strumento e voce riguarda il timbro, non ritmo né intervalli." } },

  // ============================================================== TEMPO
  { topic: "tempo", difficulty: 2, difficulty8: true, applica: "musica-tempo-base",
    prompt: "Durante una pausa, in cui non suona nessuno strumento, la pulsazione continua?",
    answer: "Sì, il battito prosegue", distractors: ["No, si ferma con le note", "Solo se qualcuno la batte", "Solo nei tempi dispari"],
    explanation: "La pulsazione è la griglia sotto la musica e non dipende dalle note: è proprio per questo che dopo una pausa tutti rientrano insieme.",
    distractorWhy: { "No, si ferma con le note": "Se si fermasse, dopo una pausa nessuno saprebbe quando rientrare.", "Solo se qualcuno la batte": "Il direttore la rende visibile, ma esiste anche quando nessuno la segna.", "Solo nei tempi dispari": "Vale in qualunque tempo: è la definizione stessa di pulsazione." } },

  { topic: "tempo", difficulty: 4, difficulty8: true, applica: "musica-tempo-base",
    format: "numeric_input",
    prompt: "In un tempo di 3/4, quanti movimenti ci sono in una battuta?",
    answer: "3",
    explanation: "Lo dice il numero in alto della frazione. È il tempo del valzer, e si distingue dal quattro quarti perché l'andamento gira invece di essere quadrato." },

  { topic: "tempo", difficulty: 5, difficulty8: true, applica: "musica-tempo-alta",
    prompt: "Che cosa indica il numero in basso di un tempo come 4/4?",
    answer: "Quale figura vale un movimento", distractors: ["Quanti movimenti ci sono", "Quanto è veloce il brano", "Quante battute ha il brano"],
    explanation: "Il 4 in basso significa che il movimento è la semiminima, cioè un quarto di semibreve. Non si conta e non si somma: fissa l'unità di misura del battito.",
    distractorWhy: { "Quanti movimenti ci sono": "Lo dice il numero in alto: è l'unico dei due che si conta ad alta voce.", "Quanto è veloce il brano": "La velocità è un'indicazione a parte, scritta in parole o in battiti al minuto.", "Quante battute ha il brano": "Il numero di battute non è mai indicato all'inizio: si vede scorrendo il foglio." } },

  { topic: "tempo", difficulty: 7, difficulty8: true, applica: "musica-tempo-alta",
    prompt: "Un brano in 6/8 è per forza più veloce di uno in 3/4?",
    answer: "No, la velocità si scrive a parte", distractors: ["Sì, i numeri sono più grandi", "Sì, le crome corrono di più", "Solo se lo suona un'orchestra"],
    explanation: "La frazione dice come sono raggruppati i battiti, non quanto sono rapidi: lo stesso quattro quarti può essere lentissimo o velocissimo.",
    distractorWhy: { "Sì, i numeri sono più grandi": "I numeri della frazione non sono una misura di velocità: contano movimenti e figure.", "Sì, le crome corrono di più": "La croma dura la metà di una semiminima, ma quanto duri una semiminima lo decide la velocità dichiarata a parte.", "Solo se lo suona un'orchestra": "L'organico non c'entra: la velocità è scritta sullo spartito e vale per chiunque." } },

  // =========================================================== DINAMICA
  { topic: "dinamica", difficulty: 2, difficulty8: true, applica: "musica-dinamica-base",
    prompt: "Che cosa significa il segno «f» su uno spartito?",
    answer: "Forte", distractors: ["Finale", "Fermata", "Flauto"],
    explanation: "È l'iniziale della parola italiana, come la p sta per piano: raddoppiandola si rafforza, e ff significa fortissimo.",
    distractorWhy: { "Finale": "La fine di un brano si indica con una doppia stanghetta, non con una lettera.", "Fermata": "La fermata ha un segno suo, un punto sotto un archetto sopra la nota.", "Flauto": "Gli strumenti si scrivono per esteso all'inizio della parte, non con un'iniziale sotto il rigo." } },

  { topic: "dinamica", difficulty: 3, difficulty8: true, applica: "musica-dinamica-base",
    prompt: "Una nota grave può essere suonata fortissimo?",
    answer: "Sì, sono proprietà indipendenti", distractors: ["No, le gravi sono sempre deboli", "Solo sugli strumenti a fiato", "Solo se dura abbastanza"],
    explanation: "L'altezza dice quanto è acuto il suono, l'intensità quanto è forte: si può cambiarne una lasciando ferma l'altra, e il linguaggio comune le confonde.",
    distractorWhy: { "No, le gravi sono sempre deboli": "Un tamburo grave può essere assordante: la gravità non limita in nessun modo l'intensità.", "Solo sugli strumenti a fiato": "Vale per tutti gli strumenti: la relazione fra le due proprietà non dipende dalla famiglia.", "Solo se dura abbastanza": "La durata è la terza informazione, e non ha nessun effetto su quanto forte suoni una nota." } },

  { topic: "dinamica", difficulty: 5, difficulty8: true, applica: "musica-dinamica-alta",
    format: "short_answer",
    prompt: "Come si chiama l'indicazione che dice di aumentare il volume a poco a poco?",
    answer: "crescendo", accept: ["il crescendo", "un crescendo"],
    explanation: "Si scrive in parole oppure con un cuneo che si apre: la sua lunghezza sul rigo dice su quante battute il cambiamento deve distribuirsi." },

  { topic: "dinamica", difficulty: 6, difficulty8: true, applica: "musica-dinamica-alta",
    prompt: "Un finale fortissimo colpisce di più dopo dieci minuti forti o dopo un passaggio pianissimo?",
    answer: "Dopo il passaggio pianissimo", distractors: ["Dopo i dieci minuti forti", "Colpisce uguale in entrambi", "Dipende dallo strumento"],
    explanation: "L'effetto sta nella differenza rispetto a quello che c'era prima, non nel livello raggiunto: l'orecchio si abitua a un volume costante e smette di notarlo.",
    distractorWhy: { "Dopo i dieci minuti forti": "Dieci minuti allo stesso livello abituano l'orecchio, e il finale non si distingue più da quello che lo precede.", "Colpisce uguale in entrambi": "È proprio quello che il contrasto smentisce: lo stesso identico finale ha effetti diversissimi secondo ciò che lo precede.", "Dipende dallo strumento": "Il meccanismo dell'abitudine vale per qualunque suono, con qualunque timbro." } },

  // ============================================================= TIMBRO
  { topic: "timbro", difficulty: 4, difficulty8: true, applica: "musica-timbro-base",
    format: "short_answer",
    prompt: "Come si chiama la proprietà che distingue due strumenti che suonano la stessa nota alla stessa intensità?",
    answer: "timbro", accept: ["il timbro"],
    explanation: "Si definisce per esclusione: tolte l'altezza e l'intensità, quello che resta a distinguere i due suoni è il colore della sorgente." },

  { topic: "timbro", difficulty: 4, difficulty8: true, applica: "musica-timbro-base",
    prompt: "Quali sono le tre proprietà che descrivono un suono?",
    answer: "Altezza, intensità e timbro", distractors: ["Altezza, durata e ritmo", "Volume, velocità e colore", "Nota, battuta e chiave"],
    explanation: "Sono indipendenti: si può cambiarne una lasciando ferme le altre due, e per descrivere un suono bisogna dire qualcosa su tutte e tre.",
    distractorWhy: { "Altezza, durata e ritmo": "La durata riguarda come il suono si dispone nel tempo, e il ritmo è la loro organizzazione: manca il timbro.", "Volume, velocità e colore": "Volume e colore ci sono, con altri nomi, ma la velocità è del brano e non del singolo suono.", "Nota, battuta e chiave": "Sono elementi della notazione, cioè di come la musica si scrive, non proprietà fisiche di un suono." } },

  { topic: "timbro", difficulty: 6, difficulty8: true, applica: "musica-timbro-alta",
    prompt: "Che cosa rende diverso il timbro di due strumenti che suonano la stessa frequenza?",
    answer: "La miscela di armonici", distractors: ["La frequenza principale", "L'intensità del suono", "La durata della nota"],
    explanation: "Ogni suono porta con sé frequenze più deboli e acute, e quali siano presenti e quanto pesino cambia da strumento a strumento: quella miscela è il colore.",
    distractorWhy: { "La frequenza principale": "È identica per ipotesi: è proprio quella che rende le due note «la stessa nota».", "L'intensità del suono": "È una proprietà indipendente, e si può renderla uguale senza che i due timbri si assomiglino.", "La durata della nota": "Non cambia il colore: una nota lunga e una corta dello stesso strumento hanno lo stesso timbro." } },

  { topic: "timbro", difficulty: 7, difficulty8: true, applica: "musica-timbro-alta",
    prompt: "Due violini con corde identiche suonano diversi. Dove nasce la differenza?",
    answer: "Nel corpo dello strumento", distractors: ["Nella tensione delle corde", "Nell'altezza delle note", "Nella forza dell'archetto"],
    explanation: "La corda genera il suono, ma è la cassa a rinforzare certi armonici e a smorzarne altri: è lì che si decide il colore finale.",
    distractorWhy: { "Nella tensione delle corde": "La tensione decide l'altezza della nota, non il suo colore, e per ipotesi le note sono le stesse.", "Nell'altezza delle note": "Le note sono identiche: se lo fossero anche i timbri non si sentirebbe nessuna differenza.", "Nella forza dell'archetto": "Cambia l'intensità e in parte l'attacco, ma i due strumenti restano distinguibili anche suonati allo stesso modo." } },

  // ========================================================== STRUMENTI
  { topic: "strumenti", difficulty: 2, difficulty8: true, applica: "musica-strumenti-base",
    format: "short_answer",
    prompt: "A quale famiglia appartiene il clarinetto, in cui a vibrare è una colonna d'aria?",
    answer: "fiati", accept: ["i fiati", "strumenti a fiato"],
    explanation: "Il criterio delle famiglie è come nasce la vibrazione: qui è una colonna d'aria dentro un tubo, messa in movimento dal soffio." },

  { topic: "strumenti", difficulty: 4, difficulty8: true, applica: "musica-strumenti-base",
    prompt: "Ti mostrano uno strumento mai visto. Quali due domande bastano per collocarlo in una famiglia?",
    answer: "Che cosa vibra e come", distractors: ["Di che materiale è e quanto pesa", "Chi lo suona e in quale orchestra", "Quante note fa e quanto costa"],
    explanation: "Il criterio delle famiglie è come nasce la vibrazione: corda, colonna d'aria o corpo solido, e se venga sfregato, soffiato, pizzicato o percosso.",
    distractorWhy: { "Di che materiale è e quanto pesa": "Un flauto di metallo resta un fiato: il materiale non decide la famiglia.", "Chi lo suona e in quale orchestra": "L'organico è una questione di repertorio, e non dice niente su come nasce il suono.", "Quante note fa e quanto costa": "L'estensione e il prezzo variano dentro la stessa famiglia e non la identificano." } },

  { topic: "strumenti", difficulty: 6, difficulty8: true, applica: "musica-strumenti-alta",
    prompt: "Perché il pianoforte può essere messo sia fra le corde sia fra le percussioni?",
    answer: "Perché le corde vengono colpite", distractors: ["Perché ha molte corde", "Perché è grande e pesante", "Perché si suona con le mani"],
    explanation: "Dentro la cassa a vibrare è una corda, quindi è a corde; ma quella corda viene colpita da un martelletto e non pizzicata né sfregata, quindi è anche a percussione.",
    distractorWhy: { "Perché ha molte corde": "Anche un'arpa ne ha molte e non è una percussione: conta come vengono messe in vibrazione.", "Perché è grande e pesante": "La dimensione non entra in nessuno dei criteri di classificazione.", "Perché si suona con le mani": "Anche la chitarra si suona con le mani ed è soltanto a corde." } },

  { topic: "strumenti", difficulty: 6, difficulty8: true, applica: "musica-strumenti-alta",
    prompt: "Sapere che uno strumento è un fiato che cosa ti permette di prevedere?",
    answer: "Che ha bisogno di respiro e pause", distractors: ["Che suona sempre acuto", "Che è fatto di metallo", "Che si suona sempre stando in piedi"],
    explanation: "La famiglia non è un'etichetta ma una previsione: il suono dura quanto dura il fiato, quindi le pause per respirare fanno parte della musica.",
    distractorWhy: { "Che suona sempre acuto": "Esistono fiati gravissimi, dal fagotto alla tuba: la famiglia non fissa il registro.", "Che è fatto di metallo": "Molti fiati sono di legno, e il flauto traverso di metallo è un legno per classificazione.", "Che si suona sempre stando in piedi": "La posizione dipende dallo strumento e dal contesto, non dalla famiglia." } },

  // ========================================================= INTERVALLI
  { topic: "intervalli", difficulty: 6, difficulty8: true, applica: "musica-intervalli-alta",
    format: "numeric_input",
    prompt: "Quanti gradi ci sono nell'intervallo da do a sol?",
    answer: "5",
    explanation: "Si contano do, re, mi, fa, sol includendo entrambe le note: cinque gradi, quindi l'intervallo si chiama quinta. Chi conta i passi trova quattro e sbaglia." },

  { topic: "intervalli", difficulty: 7, difficulty8: true, applica: "musica-intervalli-alta",
    prompt: "Come si chiama la distanza di una nota da se stessa?",
    answer: "Prima", distractors: ["Zero", "Nessun intervallo", "Ottava"],
    explanation: "Contando includendo la nota di partenza si arriva a uno: è la conferma più netta che l'intervallo si conta in gradi e non in passi.",
    distractorWhy: { "Zero": "Sarebbe il conto dei passi, che è appunto nessuno: ma gli intervalli si contano in gradi, includendo la nota da cui si parte.", "Nessun intervallo": "Un intervallo c'è, ed è quello di distanza nulla: ha un nome proprio.", "Ottava": "È la distanza fra una nota e quella con lo stesso nome, ma otto gradi più in alto." } },

  { topic: "intervalli", difficulty: 8, difficulty8: true, applica: "musica-intervalli-alta",
    prompt: "Perché la stessa canzone cantata più in basso resta riconoscibile?",
    answer: "Perché gli intervalli non cambiano", distractors: ["Perché le note cantate sono le stesse", "Perché il ritmo è più lento", "Perché il timbro resta uguale"],
    explanation: "Chi canta più grave cambia tutte le note assolute e mantiene tutte le distanze fra loro: l'orecchio segue le distanze, non le altezze.",
    distractorWhy: { "Perché le note cantate sono le stesse": "Non lo sono affatto: cantando più in basso ogni nota è diversa da quella originale.", "Perché il ritmo è più lento": "Non c'è ragione che lo sia: si può cantare più in basso alla stessa identica velocità.", "Perché il timbro resta uguale": "Cambia anche il timbro se cambia chi canta, e la canzone resta comunque riconoscibile." } },
];
