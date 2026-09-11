// Latino — le firme, primo lotto. 11 settembre 2026.
//
// ## Una correzione allo studio del 10 settembre
//
// Lo studio diceva: «le manopole del caso — renderer già pronto, costo zero»,
// cioè riusare `verb_decoder` per far regolare **caso, numero e genere** di un
// nome. È sbagliato, e si vede aprendo il renderer: i titoli delle tre ghiere
// sono scritti dentro `ExercisePlayer`, non nei dati —
//
//     1 · QUANDO ACCADE?     2 · COME VIENE PRESENTATA?     3 · QUALE FORMA?
//
// — e sopra una scelta di casi la prima direbbe una cosa senza senso.
//
// Ma quelle tre ghiere sono **esatte per i verbi**, che è dove il latino è più
// difficile e dove l'italiano non aiuta: tempo, modo e forma sono proprio le tre
// informazioni che una desinenza latina porta insieme. Separarle è tutto il
// punto — chi indovina «scribebat» perché «suona da passato» non ha capito
// niente, chi sceglie *imperfetto* e *indicativo* e poi trova la forma ha capito.
//
// Per la declinazione servirà che i titoli vengano dai dati: è una riga di
// contratto, aggiunta a **C-R4** come C-R4f, e non blocca niente di questo lotto.
//
// ## La regola della materia, rispettata
//
// «Nessuna domanda di FORMA senza una tavola di paradigma su cui impararla»: qui
// la tavola è dentro la prova. Le forme alternative stanno tutte davanti al
// bambino — scribit, scribebat, scribet — e gli indizi delle tre ghiere dicono
// *come* si riconosce quale, non quale sia. Il -ba- dell'imperfetto e la -t che
// dice «lui» si imparano confrontando, che è il modo in cui si imparano davvero.

export const LATINO_FIRME = [

  // ======================================= il decodificatore, sui verbi

  { topic: "verbi", difficulty: 4, difficulty8: true, format: "verb_decoder",
    prompt: "Il messaggio è corroso proprio sul verbo. Regola le tre ghiere e ricomponi la frase.",
    segments: ["Marcus epistulam", "ad amicum."],
    timeChoices: [
      { id: "pres", label: "presente · adesso" },
      { id: "imp", label: "imperfetto · durava nel passato" },
      { id: "fut", label: "futuro · deve ancora succedere" },
    ],
    moodChoices: [
      { id: "ind", label: "indicativo · si afferma un fatto" },
      { id: "imper", label: "imperativo · si dà un ordine" },
      { id: "cong", label: "congiuntivo · si ipotizza" },
    ],
    forms: [
      { id: "scribit", label: "scribit" },
      { id: "scribebat", label: "scribebat" },
      { id: "scribet", label: "scribet" },
      { id: "scribe", label: "scribe" },
    ],
    solution: { time: "pres", mood: "ind", form: "scribit" },
    hints: {
      time: "Nella frase non c'è niente che spinga nel passato o nel futuro: il fatto succede mentre si racconta.",
      mood: "Marco non riceve un ordine e non si sta immaginando niente: si dice che cosa fa.",
      form: "La -t finale dice «lui». Fra le quattro, tre hanno quella -t: quello che le distingue è il pezzo in mezzo — il -ba- porta nel passato, la -e- nel futuro, e senza niente resta il presente.",
    },
    discovery: "Il messaggio si apre: «Marco scrive una lettera all'amico». Era un saluto, non un allarme.",
    explanation: "Le tre ghiere sono tre informazioni diverse che in latino viaggiano insieme dentro una desinenza sola. Chi sceglie la forma «a orecchio» azzecca metà delle volte e non sa perché; chi decide prima *quando* e *come*, arriva alla forma per esclusione — ed è l'unico modo che funziona anche con un verbo mai visto." },

  { topic: "verbo-sum", difficulty: 6, difficulty8: true, format: "verb_decoder",
    prompt: "La tavoletta racconta una tempesta, ma il verbo essere è illeggibile. Regola le ghiere.",
    segments: ["Nautae in nave", "cum tempestas venit."],
    timeChoices: [
      { id: "pres", label: "presente · adesso" },
      { id: "imp", label: "imperfetto · durava mentre succedeva altro" },
      { id: "fut", label: "futuro · deve ancora succedere" },
    ],
    moodChoices: [
      { id: "ind", label: "indicativo · si racconta un fatto" },
      { id: "imper", label: "imperativo · si comanda" },
      { id: "cong", label: "congiuntivo · si suppone" },
    ],
    forms: [
      { id: "sunt", label: "sunt" },
      { id: "erant", label: "erant" },
      { id: "erunt", label: "erunt" },
      { id: "este", label: "este" },
    ],
    solution: { time: "imp", mood: "ind", form: "erant" },
    hints: {
      time: "I marinai erano già sulla nave QUANDO è arrivata la tempesta: una cosa durava mentre l'altra accadeva. È esattamente il lavoro dell'imperfetto.",
      mood: "È il racconto di quello che è successo, non un ordine ai marinai.",
      form: "La coda -nt dice «essi» e c'è in tre forme su quattro. Il pezzo davanti decide il tempo: sum non usa il -ba- degli altri verbi, ma la sua era- fa lo stesso mestiere.",
    },
    discovery: "«I marinai erano sulla nave quando venne la tempesta.» La tavoletta è un rapporto di naufragio.",
    explanation: "Il verbo essere è irregolare in ogni lingua, e per una ragione sola: è quello che si usa di più, e le parole usate di più consumano le regole. Ma l'irregolarità è nella radice, non nelle desinenze — la -nt di «erant» è la stessa di «amant» e di «scribunt»." },

  { topic: "verbi", difficulty: 8, difficulty8: true, format: "verb_decoder",
    prompt: "L'annale è bruciato sul verbo più importante della riga. Regola le ghiere e scopri che cosa fece Cesare.",
    segments: ["Caesar Rubiconem", "et bellum civile coepit."],
    timeChoices: [
      { id: "pres", label: "presente · adesso" },
      { id: "imp", label: "imperfetto · durava, si ripeteva" },
      { id: "perf", label: "perfetto · successo una volta, e finito" },
      { id: "fut", label: "futuro · deve ancora succedere" },
    ],
    moodChoices: [
      { id: "ind", label: "indicativo · si afferma che è successo" },
      { id: "cong", label: "congiuntivo · si ipotizza" },
      { id: "imper", label: "imperativo · si ordina" },
    ],
    forms: [
      { id: "transit", label: "transit" },
      { id: "transibat", label: "transibat" },
      { id: "transiit", label: "transiit" },
      { id: "transibit", label: "transibit" },
    ],
    solution: { time: "perf", mood: "ind", form: "transiit" },
    hints: {
      time: "Attraversare un fiume non è una cosa che si fa un po' per volta: è un gesto compiuto, e dopo quello comincia la guerra. Il latino ha un tempo apposta per le azioni concluse.",
      mood: "L'annale registra quello che è accaduto, non un'ipotesi su che cosa sarebbe potuto accadere.",
      form: "Tre forme hanno il tema regolare transi-; la quarta raddoppia la -i-. È lì che si nasconde il perfetto del verbo eo, «andare».",
    },
    discovery: "«Cesare attraversò il Rubicone e cominciò la guerra civile.» Una riga sola, e un mondo che finisce.",
    explanation: "Imperfetto e perfetto raccontano lo stesso passato in due modi diversi: «transibat» sarebbe «stava attraversando, lo faceva di solito», «transiit» è «lo fece, una volta, e fu fatto». L'italiano ha la stessa differenza fra «attraversava» e «attraversò», e in latino non è una sfumatura di stile: cambia che cosa è successo." },

  // ================================== i gesti sulle basi e sui casi

  { topic: "vocabolario", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni parola latina alla parola italiana che ne è nata.",
    pairs: [
      { left: "aqua", right: "acquedotto" },
      { left: "terra", right: "sotterraneo" },
      { left: "liber", right: "libreria" },
      { left: "manus", right: "manuale" },
    ],
    explanation: "Non si tratta di imparare parole nuove: sono già nella testa di chi parla italiano, nascoste dentro parole lunghe. Riconoscere la radice latina di una parola italiana è il modo più veloce per ricordarla — e funziona anche al contrario, per indovinare il senso di una parola latina mai vista." },

  { topic: "basi", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni cosa secondo che sia una caratteristica del latino o dell'italiano.",
    items: ["la funzione la dice la desinenza", "la funzione la dice la posizione nella frase", "non esistono gli articoli", "il verbo sta quasi sempre in fondo"],
    categories: ["latino", "italiano"],
    assignments: {
      "la funzione la dice la desinenza": "latino",
      "la funzione la dice la posizione nella frase": "italiano",
      "non esistono gli articoli": "latino",
      "il verbo sta quasi sempre in fondo": "latino",
    },
    explanation: "Da qui viene tutta la differenza: in italiano «il cane morde l'uomo» e «l'uomo morde il cane» dicono cose opposte pur avendo le stesse parole, in latino no — perché a dire chi morde è la desinenza, e le parole si possono spostare quasi a piacere." },

  { topic: "etimologia", difficulty: 1, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passi per capire una parola italiana difficile partendo dal latino.",
    items: ["metti insieme i due pezzi e prova il significato", "cerca se riconosci una radice che già conosci", "guarda se davanti c'è un prefisso", "controlla se il senso torna nella frase"],
    correctOrder: ["guarda se davanti c'è un prefisso", "cerca se riconosci una radice che già conosci", "metti insieme i due pezzi e prova il significato", "controlla se il senso torna nella frase"],
    explanation: "Si comincia dal prefisso perché è la parte più regolare: «sub-» vuol dire sotto in ogni parola in cui compare, dalla subacquea al suburbio. L'ultimo passo non è una formalità — «premeditare» smontato male dà «meditare prima», che è quasi giusto, e la frase serve a vedere se quel «quasi» basta." },

  { topic: "declinazioni-base", difficulty: 3, difficulty8: true, format: "classification",
    prompt: "Smista ogni nome secondo la declinazione, guardando il genitivo che ti viene dato.",
    items: ["rosa, rosae", "dominus, domini", "consul, consulis", "dies, diei"],
    categories: ["prima", "seconda", "terza", "quinta"],
    assignments: {
      "rosa, rosae": "prima",
      "dominus, domini": "seconda",
      "consul, consulis": "terza",
      "dies, diei": "quinta",
    },
    explanation: "Si guarda solo la seconda forma, mai la prima: -ae, -i, -is, -ei. Il vocabolario mette il genitivo accanto al nominativo proprio per questo, e non per pignoleria — «manus» e «dominus» finiscono uguali al nominativo e sono di due declinazioni diverse." },

  { topic: "casi", difficulty: 3, difficulty8: true, format: "ordering",
    prompt: "Hai una frase latina davanti e non sai da dove cominciare. Metti in ordine i passi per tradurla senza indovinare.",
    items: ["trova il complemento oggetto all'accusativo", "cerca il verbo e guarda che persona è", "sistema gli altri casi al loro posto", "cerca il nominativo che concorda col verbo"],
    correctOrder: ["cerca il verbo e guarda che persona è", "cerca il nominativo che concorda col verbo", "trova il complemento oggetto all'accusativo", "sistema gli altri casi al loro posto"],
    explanation: "Si parte dal verbo perché è lui a dire quante persone servono e di che tipo: un verbo transitivo pretende un accusativo, uno intransitivo no. Cominciare dalla prima parola è l'errore che fa tradurre a caso — in latino la prima parola può essere qualunque cosa." },

  { topic: "declinazione-3m", difficulty: 5, difficulty8: true, format: "matching",
    prompt: "Abbina ogni desinenza della terza declinazione alla funzione che segnala.",
    pairs: [
      { left: "-is (singolare)", right: "di chi, di che cosa" },
      { left: "-i (singolare)", right: "a chi, per chi" },
      { left: "-em", right: "chi o che cosa subisce l'azione" },
      { left: "-es (plurale)", right: "più soggetti che fanno l'azione" },
    ],
    explanation: "La terza è la declinazione più numerosa e la più irregolare al nominativo — consul, corpus, mare non si somigliano — ma dal genitivo in poi le desinenze sono le stesse per tutti. È il motivo per cui conviene impararla dal genitivo e non dal nominativo." },

  { topic: "frasi", difficulty: 5, difficulty8: true, format: "classification",
    prompt: "Smista ogni frase latina secondo che cosa fa il verbo.",
    items: ["Puella cantat.", "Agricola terram arat.", "Marcus dormit.", "Nauta epistulam scribit."],
    categories: ["il verbo ha bisogno di un oggetto", "il verbo sta in piedi da solo"],
    assignments: {
      "Puella cantat.": "il verbo sta in piedi da solo",
      "Agricola terram arat.": "il verbo ha bisogno di un oggetto",
      "Marcus dormit.": "il verbo sta in piedi da solo",
      "Nauta epistulam scribit.": "il verbo ha bisogno di un oggetto",
    },
    explanation: "Riconoscere se un verbo è transitivo prima di tradurre fa risparmiare metà del lavoro: se lo è, nella frase ci sarà un accusativo da cercare; se non lo è, un accusativo che compare ha un altro mestiere — di solito dice un moto verso un luogo o una durata." },

  { topic: "declinazione-2m", difficulty: 7, difficulty8: true, format: "ordering",
    prompt: "Metti i casi di «dominus» nell'ordine in cui il vocabolario li elenca al singolare.",
    items: ["dominum", "dominus", "domino", "domini"],
    correctOrder: ["dominus", "domini", "domino", "dominum"],
    explanation: "Nominativo, genitivo, dativo, accusativo: è l'ordine di tutti i vocabolari e di tutte le grammatiche, e impararlo a memoria in quest'ordine serve davvero — quando cerchi una forma sai già in che punto della tabella guardare, e lo stesso ordine vale per tutte e cinque le declinazioni." },

  { topic: "etimologia", difficulty: 7, difficulty8: true, format: "matching",
    prompt: "Abbina ogni espressione latina rimasta viva all'uso che se ne fa.",
    pairs: [
      { left: "curriculum vitae", right: "il percorso di studi e di lavoro" },
      { left: "post scriptum", right: "aggiunto dopo aver finito di scrivere" },
      { left: "et cetera", right: "e tutte le altre cose dell'elenco" },
      { left: "in extremis", right: "all'ultimo momento utile" },
    ],
    explanation: "Nessuna di queste è una citazione colta: sono espressioni che si usano ogni giorno senza accorgersi che sono latine. Smontarle le rende trasparenti — «curriculum» è la corsa, e un curriculum vitae è letteralmente il percorso di una vita." },

  { topic: "casi", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "In «Marcus gladio hostem in silva vulnerat», smista ogni parola secondo il ruolo che ha.",
    items: ["Marcus", "gladio", "hostem", "in silva"],
    categories: ["chi compie l'azione", "chi la subisce", "con che cosa", "dove"],
    assignments: {
      "Marcus": "chi compie l'azione",
      "gladio": "con che cosa",
      "hostem": "chi la subisce",
      "in silva": "dove",
    },
    explanation: "Quattro parole, quattro casi diversi, e nessuna preposizione tranne una: il latino dice «con la spada» cambiando la desinenza, e «nel bosco» con preposizione più ablativo. È per questo che una frase latina è più corta della sua traduzione — le informazioni che noi mettiamo in parole separate, lì stanno dentro le parole." },

  { topic: "vocabolario", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti queste parole latine in ordine, dalla più generale alla più precisa.",
    items: ["canis", "animal", "corpus", "catulus"],
    correctOrder: ["corpus", "animal", "canis", "catulus"],
    explanation: "Corpo, animale, cane, cucciolo: ogni parola dice più della precedente e quindi descrive meno cose. È la stessa scala che regge i gruppi in logica e le classificazioni in scienze — aggiungere informazione restringe sempre, e chi traduce lo usa per indovinare: se «catulus» è dentro «canis», il senso è lì attorno." },
];
