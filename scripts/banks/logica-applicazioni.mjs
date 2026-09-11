// Logica — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Ottava materia convertita alla regola delle dispense
// (`docs/REGOLA_DISPENSE.md`), e l'ultima delle quattro piccole. Sei argomenti,
// dodici dispense.
//
// ## Perché logica NON entra fra le materie di richiamo
//
// È la stessa ragione di coding, e vale la pena averla scritta perché è la
// distinzione su cui la regola si regge. Qui la risposta è il **risultato di un
// procedimento applicato a un caso**: alla domanda «quale non appartiene al
// gruppo: cane, mela, gatto, cavallo?» si risponde «mela», una parola che in
// nessuna dispensa comparirà mai né deve. Pretenderla nel documento vorrebbe
// dire vietare di scrivere esercizi nuovi.
//
// Le dispense di logica non insegnano quindi fatti ma **procedimenti**, e le
// domande li applicano a materiale che il documento non ha visto:
//
//   il documento dice   nomina la proprietà che condividono gli altri, non
//                       cercare l'elemento strano
//   la domanda chiede   quale non appartiene a un gruppo mai nominato prima
//
// ## Regole di scrittura
//
// Quelle degli altri lotti, più una che qui conta più che altrove: **ogni
// distrattore deve essere l'errore che una regola sbagliata produrrebbe**, non
// un'alternativa a caso. In logica i distrattori sono la parte didattica: dicono
// quale scorciatoia mentale ha portato lì, e il `distractorWhy` la nomina.

export const LOGICA_APPLICAZIONI = [

  // =========================================================== SEQUENZE
  { topic: "sequenze", difficulty: 2, difficulty8: true, applica: "logica-sequenze-base",
    prompt: "Quale lettera continua la serie: B, D, F, H, ?",
    answer: "J", distractors: ["I", "G", "K"],
    explanation: "La differenza è costante e vale due posizioni dell'alfabeto, ed è la stessa fra tutte le coppie: applicandola alla H si arriva alla J.",
    distractorWhy: { "I": "È la lettera immediatamente successiva: avanza di uno invece che di due, cioè applica un passo che nella serie non compare.", "G": "Torna indietro di una posizione: il verso della serie è in avanti, non all'indietro.", "K": "Avanza di tre posizioni: il passo va calcolato sulle coppie date, e lì è sempre di due." } },

  { topic: "sequenze", difficulty: 3, difficulty8: true, applica: "logica-sequenze-base",
    prompt: "Quale numero continua la serie: 20, 17, 14, 11, ?",
    answer: "8", distractors: ["14", "9", "7"],
    explanation: "La differenza è costante e vale tre, e il verso è all'indietro: controllare il verso prima di applicare il passo evita metà degli errori su queste serie.",
    distractorWhy: { "14": "Applica il passo nel verso sbagliato, tornando in avanti invece di proseguire in discesa.", "9": "Sottrae due invece di tre: il passo va verificato su tutte le coppie, e lì è sempre tre.", "7": "Sottrae quattro: stesso errore del precedente, nella direzione opposta." } },

  { topic: "sequenze", difficulty: 5, difficulty8: true, applica: "logica-sequenze-alta",
    prompt: "Il treno passa alle 7:40, 7:55, 8:10, 8:25. A che ora passa il prossimo?",
    answer: "8:40", distractors: ["8:35", "9:25", "8:45"],
    explanation: "Il passo è di quindici minuti. L'ora è un ciclo di sessanta, quindi conviene contare i minuti e riportarli, invece di sommare le cifre come fossero numeri normali.",
    distractorWhy: { "8:35": "Somma dieci minuti invece di quindici: il passo va calcolato su una coppia e verificato sulle altre.", "9:25": "Somma un'ora intera: il passo è di quindici minuti, e un'ora è quattro passi.", "8:45": "Somma venti minuti: l'errore nasce dal contare i passaggi invece dei minuti fra due passaggi." } },

  { topic: "sequenze", difficulty: 6, difficulty8: true, applica: "logica-sequenze-alta",
    prompt: "Le differenze fra elementi consecutivi di una serie non sono costanti. Che cosa provi per prima cosa?",
    answer: "Separare posizioni pari e dispari", distractors: ["Cambiare il verso della serie", "Sommare tutti gli elementi", "Cercare il numero più grande"],
    explanation: "Sono spesso due sequenze alternate dentro una fila sola: separandole, ciascuna delle due rivela una regola propria e costante.",
    distractorWhy: { "Cambiare il verso della serie": "Il verso cambia il segno del passo ma non lo rende costante: se le differenze variano, variano in entrambi i versi.", "Sommare tutti gli elementi": "La somma non dice niente sulla regola che lega un elemento al successivo.", "Cercare il numero più grande": "Il massimo è un dato della serie, non una regola: non permette di calcolare il prossimo elemento." } },

  // ========================================================= ESCLUSIONI
  { topic: "esclusioni", difficulty: 2, difficulty8: true, applica: "logica-esclusioni-base",
    prompt: "Quale non appartiene al gruppo: martello, pinza, quaderno, cacciavite?",
    answer: "quaderno", distractors: ["martello", "pinza", "cacciavite"],
    explanation: "La proprietà comune dei più è essere un attrezzo da lavoro, e l'unico a non averla è il quaderno, che è materiale per scrivere.",
    distractorWhy: { "martello": "Condivide la proprietà con pinza e cacciavite: è un attrezzo, quindi sta nel gruppo.", "pinza": "Stessa proprietà degli altri due attrezzi: escluderla lascerebbe fuori un elemento che ce l'ha.", "cacciavite": "È un attrezzo come gli altri due: la proprietà comune vale anche per lui." } },

  { topic: "esclusioni", difficulty: 3, difficulty8: true, applica: "logica-esclusioni-base",
    prompt: "Davanti a un gruppo di quattro elementi, qual è la prima cosa da fare?",
    answer: "Nominare la proprietà comune", distractors: ["Cercare l'elemento più strano", "Contare le lettere delle parole", "Eliminare il primo della lista"],
    explanation: "Detta a parole, la proprietà si può verificare su tutti gli altri elementi: finché resta un'impressione non c'è modo di controllare la risposta.",
    distractorWhy: { "Cercare l'elemento più strano": "«Strano» dipende da chi guarda, e su gruppi meno ovvi porta all'elemento sbagliato.", "Contare le lettere delle parole": "È un criterio sulle parole e non sulle cose: cambiando i nomi degli oggetti smetterebbe di funzionare.", "Eliminare il primo della lista": "La posizione nell'elenco non ha nessun rapporto con le proprietà degli elementi." } },

  { topic: "esclusioni", difficulty: 5, difficulty8: true, applica: "logica-esclusioni-alta",
    prompt: "Quale non appartiene al gruppo: tromba, trombone, tuba, arpa?",
    answer: "arpa", distractors: ["tromba", "trombone", "tuba"],
    explanation: "Tre sono ottoni, cioè fiati di metallo, mentre l'arpa è a corde: il criterio lascia fuori esattamente un elemento e vale per tutti e tre gli altri.",
    distractorWhy: { "tromba": "Condivide con trombone e tuba il modo in cui nasce il suono: è un fiato come loro.", "trombone": "Stessa famiglia degli altri due: escluderlo lascerebbe nel gruppo uno strumento a corde.", "tuba": "È il più grave dei tre ottoni, ma la dimensione non è un criterio: conta come nasce la vibrazione." } },

  { topic: "esclusioni", difficulty: 8, difficulty8: true, applica: "logica-esclusioni-alta",
    prompt: "Due criteri diversi escludono due elementi diversi. Quale scegli?",
    answer: "Quello che ne lascia fuori uno solo", distractors: ["Quello che ti viene per primo", "Quello con la parola più corta", "Quello che esclude l'ultimo elemento"],
    explanation: "Un criterio che escluderebbe due elementi non serve, perché l'esercizio ne chiede uno; e vince quello che vale esattamente per tutti gli altri senza forzature.",
    distractorWhy: { "Quello che ti viene per primo": "L'ordine in cui vengono in mente non dice niente sulla loro solidità: il primo è spesso il più superficiale.", "Quello con la parola più corta": "La lunghezza del criterio non c'entra con la sua validità.", "Quello che esclude l'ultimo elemento": "La posizione nell'elenco è arbitraria e non ha rapporto con le proprietà." } },

  // ========================================================== DEDUZIONI
  { topic: "deduzioni", difficulty: 2, difficulty8: true, applica: "logica-deduzioni-base",
    prompt: "Tutti i corvi sono neri. Kraa è un corvo. Allora Kraa…",
    answer: "è nero", distractors: ["potrebbe essere nero", "non è nero", "non si può sapere"],
    explanation: "«Tutti» non lascia eccezioni, e Kraa è uno dei casi: la conclusione non è probabile ma obbligata, se le premesse sono vere.",
    distractorWhy: { "potrebbe essere nero": "Confonde la deduzione con una stima: le premesse escludono ogni altra possibilità, quindi non resta nessun «potrebbe».", "non è nero": "Contraddice direttamente la prima premessa, che vale per ogni singolo corvo.", "non si può sapere": "Si può eccome: è esattamente il caso in cui la conclusione è contenuta nelle premesse." } },

  { topic: "deduzioni", difficulty: 4, difficulty8: true, applica: "logica-deduzioni-base",
    prompt: "Tutti i gatti hanno la coda. Fufi ha la coda. Che cosa si può concludere su Fufi?",
    answer: "Niente di certo", distractors: ["Che è un gatto", "Che non è un gatto", "Che è un mammifero"],
    explanation: "La premessa dice che i gatti stanno fra gli animali con la coda, non che siano i soli: anche un cane rispetterebbe le premesse senza essere un gatto.",
    distractorWhy: { "Che è un gatto": "È l'errore più comune della logica elementare: la frase suona simmetrica ma non lo è.", "Che non è un gatto": "Nulla lo esclude: Fufi potrebbe benissimo essere un gatto, semplicemente non lo si può dedurre.", "Che è un mammifero": "Molti animali con la coda non sono mammiferi, e le premesse non dicono niente in proposito." } },

  { topic: "deduzioni", difficulty: 6, difficulty8: true, applica: "logica-deduzioni-alta",
    prompt: "Se il forno è acceso, la spia è rossa. La spia NON è rossa. Allora…",
    answer: "il forno è spento", distractors: ["il forno è acceso", "la spia è rotta", "non si può concludere"],
    explanation: "Se il forno fosse acceso la spia sarebbe rossa: la sua assenza esclude l'accensione. Il rovescio invece non varrebbe, perché la spia potrebbe essere rossa per altri motivi.",
    distractorWhy: { "il forno è acceso": "Contraddice la premessa: se lo fosse, la spia dovrebbe essere rossa e non lo è.", "la spia è rotta": "È una possibilità nel mondo reale, ma le premesse la escludono: dentro l'esercizio valgono solo quelle.", "non si può concludere": "Si può, ed è una deduzione valida: negare la conseguenza permette di negare la causa." } },

  { topic: "deduzioni", difficulty: 7, difficulty8: true, applica: "logica-deduzioni-alta",
    prompt: "Ada è più veloce di Bo. Bo è più veloce di Cid. Cid è più veloce di Dea. Chi è il più lento?",
    answer: "Dea", distractors: ["Cid", "Ada", "Non si può sapere"],
    explanation: "I confronti si incatenano: scrivendo la fila in ordine, Dea si colloca all'estremo più lento e nessuna premessa la contraddice.",
    distractorWhy: { "Cid": "È più veloce di Dea, quindi non può essere l'ultimo della fila.", "Ada": "È all'estremo opposto: nessuno la supera, quindi è la più veloce.", "Non si può sapere": "Le tre premesse coprono tutta la catena e collocano ogni nome: la fila è completamente determinata." } },

  // ============================================================ INSIEMI
  { topic: "insiemi", difficulty: 2, difficulty8: true, applica: "logica-insiemi-base",
    prompt: "Tutte le rose sono fiori. Che cosa si può dire dei due insiemi?",
    answer: "Le rose stanno dentro i fiori", distractors: ["I fiori stanno dentro le rose", "Sono lo stesso insieme", "Non si toccano"],
    explanation: "Il cerchio delle rose sta interamente dentro quello dei fiori, che però contiene anche moltissimi fiori che rose non sono: la relazione non è simmetrica.",
    distractorWhy: { "I fiori stanno dentro le rose": "Rovescia l'inclusione: significherebbe che ogni fiore è una rosa, che le premesse non dicono.", "Sono lo stesso insieme": "Servirebbe che valesse anche il contrario, cioè che tutti i fiori fossero rose.", "Non si toccano": "Si toccano eccome: uno è interamente contenuto nell'altro." } },

  { topic: "insiemi", difficulty: 5, difficulty8: true, applica: "logica-insiemi-alta",
    prompt: "Che cosa contiene l'intersezione fra «numeri dispari» e «numeri minori di 10»?",
    answer: "1, 3, 5, 7 e 9", distractors: ["Tutti i numeri dispari", "Tutti i numeri sotto 10", "Nessun numero"],
    explanation: "L'intersezione tiene solo gli elementi che soddisfano entrambe le condizioni insieme, ed è sempre più piccola o uguale a ciascuno dei due insiemi di partenza.",
    distractorWhy: { "Tutti i numeri dispari": "Sarebbe uno dei due insiemi interi: l'intersezione non può essere più grande dei pezzi da cui nasce.", "Tutti i numeri sotto 10": "Stesso errore simmetrico: include anche i pari, che non soddisfano la prima condizione.", "Nessun numero": "Sarebbe l'insieme vuoto, e qui la zona comune contiene cinque elementi." } },

  { topic: "insiemi", difficulty: 6, difficulty8: true, applica: "logica-insiemi-alta",
    prompt: "Qual è l'intersezione fra i numeri pari e i numeri dispari?",
    answer: "Nessun elemento", distractors: ["Tutti i numeri interi", "Lo zero soltanto", "I numeri molto grandi"],
    explanation: "Nessun numero è pari e dispari insieme: l'insieme vuoto è un risultato legittimo, e dice qualcosa di forte — le due condizioni sono incompatibili.",
    distractorWhy: { "Tutti i numeri interi": "È l'unione dei due insiemi, non l'intersezione: confonde la O con la E.", "Lo zero soltanto": "Lo zero è pari e non dispari, quindi non sta in entrambi gli insiemi.", "I numeri molto grandi": "La dimensione non c'entra: nessun numero, grande o piccolo, può essere pari e dispari insieme." } },

  { topic: "insiemi", difficulty: 8, difficulty8: true, applica: "logica-insiemi-alta",
    prompt: "L'unione di due insiemi può essere più piccola di uno dei due?",
    answer: "No, mai", distractors: ["Sì, se si sovrappongono", "Sì, se uno è vuoto", "Dipende dagli elementi"],
    explanation: "L'unione contiene tutti gli elementi di entrambi, quindi contiene per forza tutti quelli di ciascuno: è un controllo rapido per accorgersi di aver scambiato le due operazioni.",
    distractorWhy: { "Sì, se si sovrappongono": "La sovrapposizione riduce l'unione rispetto alla somma dei due conteggi, ma non la porta mai sotto il più grande dei due.", "Sì, se uno è vuoto": "Con un insieme vuoto l'unione è uguale all'altro, quindi al massimo uguale e mai più piccola.", "Dipende dagli elementi": "Non dipende: la proprietà vale per costruzione, qualunque cosa contengano i due insiemi." } },

  // ============================================================= VERITA
  { topic: "verita", difficulty: 3, difficulty8: true, applica: "logica-verita-base",
    prompt: "«Ho finito i compiti E ho riordinato» è falsa quando…",
    answer: "Almeno una delle due manca", distractors: ["Mancano tutte e due", "Ho fatto solo i compiti", "Non è mai falsa"],
    explanation: "La E vuole entrambe le parti vere: basta che una sola sia falsa perché tutta la frase lo sia, anche se l'altra è verissima.",
    distractorWhy: { "Mancano tutte e due": "È uno dei casi in cui è falsa, ma non l'unico: lo è anche quando ne manca una sola.", "Ho fatto solo i compiti": "Anche questo è un caso di falsità, ma la domanda chiede quando lo è in generale.", "Non è mai falsa": "È falsa in tre casi su quattro: è vera solo quando valgono entrambe le parti." } },

  { topic: "verita", difficulty: 5, difficulty8: true, applica: "logica-verita-base",
    prompt: "«Vado al mare O vado in montagna» è vera anche se vado in tutti e due i posti?",
    answer: "Sì, la O comprende entrambi", distractors: ["No, è o l'uno o l'altro", "Solo se ci vado in giorni diversi", "Dipende da quale preferisci"],
    explanation: "La O della logica è larga: è vera se almeno una parte è vera, quindi anche quando lo sono tutte e due. È falsa in un caso solo, quando nessuna delle due vale.",
    distractorWhy: { "No, è o l'uno o l'altro": "È l'uso dell'italiano parlato, dove «o» suggerisce un'alternativa esclusiva: in logica va intesa nel senso largo.", "Solo se ci vado in giorni diversi": "Il tempo non entra nella valutazione: conta soltanto se ciascuna delle due parti sia vera o falsa.", "Dipende da quale preferisci": "La verità di una frase non dipende dalle preferenze di chi la dice." } },

  { topic: "verita", difficulty: 7, difficulty8: true, applica: "logica-verita-alta",
    prompt: "«Tutti hanno consegnato» risulta falsa. Che cosa è sicuramente vero?",
    answer: "Almeno uno non ha consegnato", distractors: ["Nessuno ha consegnato", "Quasi nessuno ha consegnato", "Tutti hanno copiato"],
    explanation: "Per smentire un «tutti» basta e serve una sola eccezione: dire che nessuno ha consegnato sarebbe un'affermazione molto più forte e potrebbe essere falsa anch'essa.",
    distractorWhy: { "Nessuno ha consegnato": "Dice molto di più di quanto la smentita autorizzi: potrebbero aver consegnato quasi tutti tranne uno.", "Quasi nessuno ha consegnato": "Introduce una quantità che nessuna premessa fornisce: la falsità di un «tutti» non dice quanti siano.", "Tutti hanno copiato": "Non ha nessun rapporto con la frase negata: parla di un fatto diverso." } },

  { topic: "verita", difficulty: 8, difficulty8: true, applica: "logica-verita-alta",
    prompt: "«Se studio, passo l'esame.» Ho passato l'esame. Che cosa si conclude?",
    answer: "Niente di certo sullo studio", distractors: ["Che ho studiato", "Che non ho studiato", "Che l'esame era molto facile"],
    explanation: "La frase vincola lo studio al passaggio, non il passaggio allo studio: non dice che si passa SOLO studiando, quindi il verso opposto non è deducibile.",
    distractorWhy: { "Che ho studiato": "È l'errore più frequente sulle condizioni: la premessa non esclude che si possa passare anche senza studiare.", "Che non ho studiato": "Nulla lo suggerisce: lo studio resta perfettamente possibile, semplicemente non è dimostrato.", "Che l'esame era molto facile": "È una spiegazione possibile nel mondo reale, ma non segue in nessun modo dalle premesse." } },

  // ===================================================== QUANTIFICATORI
  { topic: "quantificatori", difficulty: 3, difficulty8: true, applica: "logica-quantificatori-base",
    prompt: "«Alcuni studenti hanno la bicicletta» esclude che ce l'abbiano tutti?",
    answer: "No, dice solo almeno uno", distractors: ["Sì, alcuni significa non tutti", "Sì, se fossero tutti si direbbe", "Dipende da quanti sono"],
    explanation: "In logica «alcuni» significa almeno uno e nient'altro: è una parola debole, e proprio per questo difficilissima da smentire.",
    distractorWhy: { "Sì, alcuni significa non tutti": "È l'uso comune della parola, non il suo significato logico: qui «alcuni» non esclude la totalità.", "Sì, se fossero tutti si direbbe": "Dire meno di quello che si potrebbe non rende falsa l'affermazione: la rende soltanto più prudente.", "Dipende da quanti sono": "Non dipende: basta che ce ne sia almeno uno perché la frase sia vera, qualunque sia il totale." } },

  { topic: "quantificatori", difficulty: 4, difficulty8: true, applica: "logica-quantificatori-base",
    format: "short_answer",
    prompt: "Quale parola indica che una proprietà vale per ogni singolo caso, senza eccezioni?",
    answer: "tutti", accept: ["tutti quanti", "ogni"],
    explanation: "È il quantificatore più forte, ed è per questo che basta un solo caso contrario per renderlo falso: chi lo usa si espone più di chiunque altro." },

  { topic: "quantificatori", difficulty: 6, difficulty8: true, applica: "logica-quantificatori-alta",
    prompt: "«Nessun treno è in orario» viene smentita da…",
    answer: "Un solo treno in orario", distractors: ["Metà dei treni in orario", "Tutti i treni in orario", "Nessun treno in ritardo"],
    explanation: "Per smentire un «nessuno» basta un controesempio, e uno solo chiude la questione: non serve dimostrare che siano molti.",
    distractorWhy: { "Metà dei treni in orario": "Smentisce la frase, ma chiede molto più del necessario: ne basta uno.", "Tutti i treni in orario": "Anche questo la smentisce, ed è l'affermazione più forte possibile: enormemente più di quanto serva.", "Nessun treno in ritardo": "Parla di un fatto diverso, e in un mondo con soppressioni non implicherebbe nemmeno che qualcuno sia in orario." } },

  { topic: "quantificatori", difficulty: 7, difficulty8: true, applica: "logica-quantificatori-alta",
    prompt: "Da «tutti i cani sono animali» che cosa si può dire dei due gruppi?",
    answer: "Alcuni animali sono cani", distractors: ["Tutti gli animali sono cani", "Nessun animale è un cane", "Non si può dire niente"],
    explanation: "Il cerchio dei cani sta dentro quello degli animali, quindi nella zona comune c'è sicuramente qualcosa; ma il cerchio grande sporge parecchio, e questo esclude il «tutti».",
    distractorWhy: { "Tutti gli animali sono cani": "Girando una frase con «tutti» si conserva solo «alcuni»: il cerchio degli animali contiene moltissime specie.", "Nessun animale è un cane": "Contraddice la premessa: se tutti i cani sono animali, allora qualche animale è un cane.", "Non si può dire niente": "Si può dire l'affermazione più debole: nella zona comune c'è qualcosa, ed è quanto «alcuni» richiede." } },
];
