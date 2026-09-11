// Coding — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// È il primo lotto scritto sotto la regola delle dispense
// (`docs/REGOLA_DISPENSE.md`, richiesta del committente dell'11 settembre):
//
//   «Le prove devono essere applicazioni che lo studente deve fare di concetti
//   spiegati. Non presumere che debba sapere concetti che nessuno gli ha
//   spiegato. Le domande devono essere rielaborazione e utilizzo di un concetto
//   spiegato. La spiegazione di poche frasi di NORA non è sufficiente.»
//
// Coding è la prima materia convertita: ventisei dispense in `Dispense`, due
// bande per ognuno dei tredici argomenti del banco, e nessun item scoperto.
//
// ## Che cosa cambia rispetto agli altri lotti
//
// **Ogni item dichiara `applica`**, cioè l'id della dispensa che contiene il
// paragrafo che lo rende rispondibile. Non è una decorazione: `dispense_audit`
// verifica che quella dispensa esista, che parli dello stesso argomento e che
// la sua banda non cominci DOPO la fascia dell'item — non si applica una
// lezione che deve ancora arrivare.
//
// E il vocabolario è chiuso. Un item di fascia 1-4 può usare solo le notazioni
// che le dispense della banda bassa hanno introdotto: niente `sorted(`, niente
// `.split(`, niente `break`, che stanno nella banda alta. L'audit le conta, e
// per coding il tetto è zero.
//
// ## Regole di scrittura, in aggiunta a quelle degli altri lotti
//
//  1. **Si chiede di APPLICARE, non di riconoscere.** «Che cosa stampa questo
//     codice» è un'applicazione; «come si chiama questo costrutto» no. Le
//     domande di nome qui non ci sono affatto.
//  2. **La risposta si ricava dalla dispensa.** Chi ha letto il documento
//     dell'argomento ha tutto quello che serve: nessun fatto arriva da fuori.
//  3. **Ogni distrattore è un errore di ragionamento che la dispensa nomina.**
//     Quasi tutti vengono dalla sezione «errore tipico» del documento.
//  4. **Fascia dichiarata** con `difficulty8`, e mai una fascia diversa dalla
//     banda della dispensa che l'item applica.
//  5. **La risposta non è più lunga di quattro caratteri del distrattore più
//     lungo**, o si indovina misurando invece che leggendo.
//
// ## I contesti
//
// Le prove parlano del Relitto, dei suoi pannelli e dei suoi abitanti invece che
// di «un programma»: è la regola dell'effetto compito in `docs/PEDAGOGY.md`, e
// serve anche a tenere i prompt distinti da quelli dei lotti precedenti.

export const CODING_APPLICAZIONI = [

  // =========================================================== VARIABILI
  { topic: "variabili", difficulty: 1, difficulty8: true, applica: "coding-variabili-base",
    prompt: "Il pannello dell'energia esegue queste righe. Quanto vale energia alla fine?\nenergia = 5\nenergia = 12",
    answer: "12", distractors: ["5", "17", "512"],
    explanation: "Il secondo ordine non aggiunge: sostituisce. La casella ricorda solo l'ultimo valore ricevuto, e il cinque sparisce senza lasciare traccia.",
    distractorWhy: { "5": "Era il valore prima della seconda riga, che però viene eseguita anche lei.", "17": "Somma i due ordini invece di eseguirli in fila: il secondo uguale riscrive la casella da capo.", "512": "L'uguale non affianca le cifre: ogni riga scrive un valore intero." } },

  { topic: "variabili", difficulty: 2, difficulty8: true, applica: "coding-variabili-base",
    format: "numeric_input",
    prompt: "Il contatore dei portelli aperti gira così. Quanto vale portelli alla fine?\nportelli = 2\nportelli = portelli + 3\nportelli = portelli + 1",
    answer: "6",
    explanation: "Ogni riga si legge da destra: si calcola con il valore vecchio e poi si riscrive. Due diventa cinque, cinque diventa sei." },

  { topic: "variabili", difficulty: 3, difficulty8: true, applica: "coding-variabili-base",
    prompt: "Il pannello copia una misura. Quanto vale b alla fine?\na = 6\nb = a + 4\na = 1",
    answer: "10", distractors: ["5", "1", "11"],
    explanation: "b aveva già ricevuto dieci quando a valeva sei: la copia era fatta. Cambiare a dopo non torna indietro a correggere b.",
    distractorWhy: { "5": "Tratta b come collegato ad a e rifà il conto con il valore nuovo: b ha ricevuto un risultato, non un collegamento.", "1": "È il valore finale di a, ma la domanda chiede b, che era già stata scritta.", "11": "Somma il nuovo valore di a a quello che b già conteneva: nessuna riga lo chiede." } },

  { topic: "variabili", difficulty: 4, difficulty8: true, applica: "coding-variabili-base",
    format: "numeric_input",
    prompt: "La riserva del Relitto parte da dieci. Quanto vale riserva alla fine?\nriserva = 10\nriserva += 4\nriserva -= 6\nriserva += 2",
    answer: "10",
    explanation: "Il segno composto legge, calcola e riscrive nella stessa casella: dieci, quattordici, otto, dieci. Torna al punto di partenza per caso, non per una regola." },

  { topic: "variabili", difficulty: 5, difficulty8: true, applica: "coding-variabili-alta",
    prompt: "Due sensori vanno scambiati. Quanto vale nord alla fine?\nnord = 3\nsud = 8\nnord, sud = sud, nord",
    answer: "8", distractors: ["3", "11", "38"],
    explanation: "La parte destra vale (8, 3) prima che si scriva qualcosa a sinistra, quindi nessuno dei due valori vecchi va perso.",
    distractorWhy: { "3": "È il valore di partenza di nord, ma la riga dello scambio viene eseguita.", "11": "Lo scambio non somma: sposta due valori, uno nel posto dell'altro.", "38": "I due valori non si affiancano: ognuno finisce in una casella diversa." } },

  { topic: "variabili", difficulty: 6, difficulty8: true, applica: "coding-variabili-alta",
    prompt: "Un abitante prova a scambiare due valori così. Che cosa vale sud alla fine?\nnord = 3\nsud = 8\nnord = sud\nsud = nord",
    answer: "8", distractors: ["3", "0", "11"],
    explanation: "Alla terza riga nord ha già smesso di contenere tre, quindi la quarta rimette in sud quello che sud aveva già: lo scambio non avviene e un valore è perso.",
    distractorWhy: { "3": "Sarebbe il risultato di uno scambio riuscito, ma con due righe il vecchio valore di nord è già stato cancellato.", "0": "Nessuna riga azzera niente: le due righe copiano, non svuotano.", "11": "L'uguale copia il valore di destra, non somma le due caselle." } },

  { topic: "variabili", difficulty: 7, difficulty8: true, applica: "coding-variabili-alta",
    prompt: "Il registro dei turni viene passato a un secondo nome. Quanti elementi ha turni alla fine?\nturni = [1, 2]\ncopia = turni\ncopia.append(3)\nprint(len(turni))",
    answer: "3", distractors: ["2", "1", "0"],
    explanation: "I due nomi sono due etichette sulla stessa lista, non due liste: l'aggiunta fatta con un nome si vede leggendo l'altro. Per averne due separate servirebbe list(turni).",
    distractorWhy: { "2": "Presume che l'assegnazione abbia costruito una copia: con una lista attacca solo una seconda etichetta alla stessa scatola.", "1": "Nessuna riga toglie elementi, e la lista ne aveva già due all'inizio.", "0": "La lista non viene mai svuotata: append aggiunge, non sostituisce." } },

  // =============================================================== TIPI
  { topic: "tipi", difficulty: 1, difficulty8: true, applica: "coding-tipi-base",
    prompt: "Il pannello accetta soltanto quantità su cui si possano fare conti. Quale di queste lo è?",
    answer: "30", distractors: ["\"30\"", "'30'", "\"trenta\""],
    explanation: "Senza virgolette il trenta è un numero e ci si può fare aritmetica. Le virgolette dicono al computer «questo è testo, non contarlo».",
    distractorWhy: { "\"30\"": "Le virgolette lo rendono testo: assomiglia a un numero ma non si può sommare.", "'30'": "Anche gli apici singoli fanno testo: cambia il segno, non la sostanza.", "\"trenta\"": "È la parola scritta, e resta testo in ogni caso." } },

  { topic: "tipi", difficulty: 2, difficulty8: true, applica: "coding-tipi-base",
    prompt: "Il pannello stampa questo. Che cosa esce?\nprint(\"7\" + \"1\")",
    answer: "71", distractors: ["8", "7 1", "17"],
    explanation: "Fra due testi il più non somma: unisce. Le virgolette avevano già deciso che quelle non erano quantità ma sequenze di caratteri.",
    distractorWhy: { "8": "Sarebbe la somma, ma le virgolette li avevano resi testo prima che il più li guardasse.", "7 1": "Unendo due testi non compare nessuno spazio: nessuno lo ha scritto.", "17": "L'unione mantiene l'ordine in cui i pezzi sono scritti: prima il sette." } },

  { topic: "tipi", difficulty: 3, difficulty8: true, applica: "coding-tipi-base",
    format: "numeric_input",
    prompt: "Il codice del portello arriva come testo e va sommato. Che numero esce?\nprint(int(\"40\") + 2)",
    answer: "42",
    explanation: "int() costruisce il numero a partire dal testo prima che il più lo guardi: da lì in poi il segno fa il suo mestiere di somma." },

  { topic: "tipi", difficulty: 4, difficulty8: true, applica: "coding-tipi-base",
    prompt: "Il sensore ha misurato 3.9 e il pannello vuole un numero di caselle intere. Che cosa stampa?\nprint(int(3.9))",
    answer: "3", distractors: ["4", "3.9", "39"],
    explanation: "int() sul numero con la virgola TAGLIA la parte decimale invece di arrotondare: per arrotondare esiste un altro strumento.",
    distractorWhy: { "4": "Sarebbe l'arrotondamento, ma int taglia sempre verso il basso qualunque sia la parte decimale.", "3.9": "La conversione a intero non lascia nessuna virgola: quello è il valore di partenza.", "39": "La virgola non sparisce attaccando le cifre: la parte decimale viene buttata via." } },

  { topic: "tipi", difficulty: 5, difficulty8: true, applica: "coding-tipi-alta",
    prompt: "Il pannello divide otto unità fra quattro condotti. Che cosa stampa?\nprint(8 / 4)",
    answer: "2.0", distractors: ["2", "4.0", "0.5"],
    explanation: "La barra singola in Python 3 restituisce sempre un float, anche quando la divisione è esatta: il tipo lo decide l'operatore, non i numeri.",
    distractorWhy: { "2": "Il valore è giusto ma il tipo no: la barra singola dà un float, e si scrive 2.0.", "4.0": "È il divisore travestito da risultato: otto diviso quattro fa due.", "0.5": "È la divisione fatta al contrario, quattro diviso otto." } },

  { topic: "tipi", difficulty: 6, difficulty8: true, applica: "coding-tipi-alta",
    prompt: "Che tipo esce da questo conto misto?\nprint(type(5 + 2.0))",
    answer: "float", distractors: ["int", "str", "bool"],
    explanation: "Con un intero e un numero con la virgola nello stesso conto, Python promuove al tipo più capiente: tagliare la virgola perderebbe informazione.",
    distractorWhy: { "int": "Sarebbe il tipo se entrambi i valori fossero interi: il 2.0 porta la virgola nel conto.", "str": "Non compaiono virgolette da nessuna parte: nessuno dei due valori è testo.", "bool": "Il conto produce una quantità, non una risposta vero o falso." } },

  { topic: "tipi", difficulty: 7, difficulty8: true, applica: "coding-tipi-alta",
    prompt: "Il pannello ripete un segnale. Che cosa stampa?\nprint(\"ab\" * 3)",
    answer: "ababab", distractors: ["abababab", "ab3", "ab ab ab"],
    explanation: "Stringa per intero è l'unica operazione mista fra testo e numero che Python accetta, e ripete il testo quel numero di volte.",
    distractorWhy: { "abababab": "Sono quattro ripetizioni: il numero scritto è tre.", "ab3": "Il numero non viene attaccato al testo: dice quante volte ripeterlo.", "ab ab ab": "Fra una ripetizione e l'altra non compare nessuno spazio: nessuno lo ha scritto." } },

  // ========================================================== OPERATORI
  { topic: "operatori", difficulty: 1, difficulty8: true, applica: "coding-operatori-base",
    format: "numeric_input",
    prompt: "Undici razioni vanno divise fra quattro abitanti senza spezzarne nessuna. Quante ne riceve ciascuno?\nprint(11 // 4)",
    answer: "2",
    explanation: "La doppia barra risponde a «quante volte ci sta per intero»: il quattro ci sta due volte dentro undici, e il resto non si spezza." },

  { topic: "operatori", difficulty: 2, difficulty8: true, applica: "coding-operatori-base",
    format: "numeric_input",
    prompt: "Delle stesse undici razioni divise fra quattro, quante ne avanzano?\nprint(11 % 4)",
    answer: "3",
    explanation: "Due volte quattro fa otto, e da otto a undici ne restano tre. Il resto è sempre più piccolo del divisore, o ci starebbe dentro un'altra volta." },

  { topic: "operatori", difficulty: 3, difficulty8: true, applica: "coding-operatori-base",
    prompt: "Il portello deve aprirsi anche a chi ha esattamente sei chiavi. Quale controllo è giusto?",
    answer: "chiavi >= 6", distractors: ["chiavi > 6", "chiavi = 6", "chiavi > 5.5"],
    explanation: "Il maggiore stretto lascia fuori proprio il valore che sta sul confine: maggiore o uguale lo comprende, ed è l'unico caso in cui i due segni differiscono.",
    distractorWhy: { "chiavi > 6": "Lascia fuori chi ne ha esattamente sei, che è il caso che la richiesta nomina.", "chiavi = 6": "Un uguale solo è un ordine, non una domanda: dentro un controllo non ci può stare.", "chiavi > 5.5": "Funziona per caso sugli interi ma non dice quello che si intende, e su una misura con la virgola sbaglia." } },

  { topic: "operatori", difficulty: 4, difficulty8: true, applica: "coding-operatori-base",
    prompt: "Due modi di togliere la virgola a 7.8 danno risultati diversi. Che cosa stampa questa riga?\nprint(round(7.8))",
    answer: "8", distractors: ["7", "7.8", "78"],
    explanation: "round va al numero intero più vicino, mentre la doppia barra taglia sempre verso il basso: sullo stesso valore danno otto e sette.",
    distractorWhy: { "7": "È quello che darebbe il taglio verso il basso: round guarda quale intero è più vicino.", "7.8": "L'arrotondamento restituisce un intero: la virgola non resta.", "78": "Le cifre non si attaccano: la parte decimale partecipa alla scelta e poi sparisce." } },

  { topic: "operatori", difficulty: 5, difficulty8: true, applica: "coding-operatori-alta",
    format: "numeric_input",
    prompt: "L'orologio del Relitto ha dodici ore. Sono le 9 e ne passano 7: che ora segna?\nprint((9 + 7) % 12)",
    answer: "4",
    explanation: "Sedici su un quadrante da dodici: fatto un giro intero ne avanzano quattro. Tutto ciò che torna al punto di partenza si scrive con il resto." },

  { topic: "operatori", difficulty: 6, difficulty8: true, applica: "coding-operatori-alta",
    format: "numeric_input",
    prompt: "Il pannello calcola questa espressione. Che numero stampa?\nprint(5 + 2 * 3 ** 2)",
    answer: "23",
    explanation: "Prima la potenza, che dà nove, poi la moltiplicazione, che dà diciotto, poi la somma. L'ordine è sempre questo e non dipende da come è scritta la riga." },

  { topic: "operatori", difficulty: 7, difficulty8: true, applica: "coding-operatori-alta",
    prompt: "Il sensore è valido fra 1 e 10, estremi compresi. Quale riga lo dice davvero?",
    answer: "1 <= v <= 10", distractors: ["1 < v < 10", "1 <= v or v <= 10", "v >= 1 or v <= 10"],
    explanation: "Il confronto incatenato chiede le due cose insieme e comprende gli estremi. Con or ne basterebbe una vera, e per ogni numero almeno una lo è.",
    distractorWhy: { "1 < v < 10": "Esclude proprio l'uno e il dieci, che la richiesta comprende.", "1 <= v or v <= 10": "Con or basta una parte vera, e per qualsiasi numero almeno una lo è: non filtra niente.", "v >= 1 or v <= 10": "Stessa trappola scritta al contrario: il risultato è vero per ogni numero esistente." } },

  // ========================================================= CONDIZIONI
  { topic: "condizioni", difficulty: 1, difficulty8: true, applica: "coding-condizioni-base",
    prompt: "Il pannello esegue queste righe. Che cosa stampa?\nenergia = 4\nif energia > 10:\n    print(\"pieno\")\nprint(\"pronto\")",
    answer: "pronto", distractors: ["pieno", "pieno pronto", "niente"],
    explanation: "La condizione è falsa e la riga rientrata viene saltata. L'ultima riga non è rientrata: non appartiene all'if e si esegue comunque.",
    distractorWhy: { "pieno": "Quattro non è maggiore di dieci: quel ramo non parte.", "pieno pronto": "La riga rientrata è stata saltata, quindi ne resta una sola.", "niente": "L'ultima riga sta fuori dall'if, e quello che sta fuori si esegue sempre." } },

  { topic: "condizioni", difficulty: 2, difficulty8: true, applica: "coding-condizioni-base",
    prompt: "Il portello decide da solo. Che cosa stampa?\npeso = 12\nif peso <= 20:\n    print(\"passa\")\nelse:\n    print(\"fermo\")",
    answer: "passa", distractors: ["fermo", "passa fermo", "niente"],
    explanation: "I due rami sono alternativi: se la condizione è vera parte il primo e l'altro viene saltato senza nemmeno essere guardato.",
    distractorWhy: { "fermo": "È il ramo dell'else, e ci si arriva solo con la condizione falsa.", "passa fermo": "Con if ed else ne parte sempre uno soltanto, mai tutti e due.", "niente": "Insieme i due rami coprono tutti i casi: uno parte per forza." } },

  { topic: "condizioni", difficulty: 3, difficulty8: true, applica: "coding-condizioni-base",
    prompt: "Il pannello assegna un grado. Che cosa stampa con un valore di 9?\nv = 9\nif v >= 5:\n    print(\"base\")\nelif v >= 8:\n    print(\"alto\")",
    answer: "base", distractors: ["alto", "base alto", "niente"],
    explanation: "Vince il primo controllo vero, e nove supera anche il primo: il ramo alto non viene raggiunto da nessun valore, perché chi arriva a otto ha già superato il cinque.",
    distractorWhy: { "alto": "Sarebbe giusto se i controlli fossero nell'ordine opposto: così com'è, non ci si arriva mai.", "base alto": "In una catena parte un ramo solo: gli altri vengono saltati anche se sarebbero veri.", "niente": "Il primo controllo è vero, quindi qualcosa viene stampato." } },

  { topic: "condizioni", difficulty: 4, difficulty8: true, applica: "coding-condizioni-base",
    prompt: "Vanno distinti i valori sopra 8 da quelli sopra 5. In che ordine si scrivono i controlli?",
    answer: "prima >= 8, poi >= 5", distractors: ["prima >= 5, poi >= 8", "l'ordine non conta", "prima >= 5, poi == 8"],
    explanation: "In una catena vince il primo controllo vero, quindi il più stretto va davanti: messo dopo, non verrebbe mai raggiunto e nessun errore lo segnalerebbe.",
    distractorWhy: { "prima >= 5, poi >= 8": "Il controllo largo intercetta anche i valori destinati a quello stretto, che resta irraggiungibile.", "l'ordine non conta": "In una catena conta eccome: cambia quale ramo viene eseguito, in silenzio.", "prima >= 5, poi == 8": "Oltre a lasciare davanti il controllo largo, restringe il secondo a un solo valore." } },

  { topic: "condizioni", difficulty: 5, difficulty8: true, applica: "coding-condizioni-alta",
    prompt: "Il pannello controlla due cose. Che cosa stampa?\nn = 14\nif n > 10:\n    if n % 2 == 0:\n        print(\"ok\")",
    answer: "ok", distractors: ["niente", "ok ok", "None"],
    explanation: "Il blocco interno è raggiunto solo con la condizione esterna vera, quindi chiede tutt'e due le cose: quattordici supera dieci ed è pari.",
    distractorWhy: { "niente": "Entrambe le condizioni risultano vere, quindi il blocco più interno viene eseguito.", "ok ok": "C'è una sola riga di stampa, dentro un solo blocco: non si ripete.", "None": "Nessuna funzione consegna niente qui: la riga stampa un testo scritto a mano." } },

  { topic: "condizioni", difficulty: 6, difficulty8: true, applica: "coding-condizioni-alta",
    prompt: "Il pannello sceglie fra due etichette in una riga. Che cosa stampa?\nn = 11\ne = \"pari\" if n % 2 == 0 else \"dispari\"\nprint(e)",
    answer: "dispari", distractors: ["pari", "True", "None"],
    explanation: "Il resto di undici diviso due è uno, quindi la condizione è falsa e viene scelto il valore dopo else. Si legge nell'ordine in cui è scritta.",
    distractorWhy: { "pari": "È il valore del ramo vero, e la condizione qui risulta falsa.", "True": "La casella riceve uno dei due testi, non l'esito del confronto.", "None": "Un valore viene scelto in ogni caso: l'else copre tutti gli altri." } },

  { topic: "condizioni", difficulty: 7, difficulty8: true, applica: "coding-condizioni-alta",
    prompt: "Una funzione ha tre rientri annidati. Qual è il modo migliore di appiattirla?",
    answer: "uscire subito sui casi impossibili", distractors: ["unire tutto in una riga sola", "togliere i controlli superflui", "spostare i controlli in fondo"],
    explanation: "La clausola di guardia controlla per prima i casi storti e chiude la funzione con return: il lavoro vero resta sulla colonna principale, dove si legge.",
    distractorWhy: { "unire tutto in una riga sola": "Accorcia il testo e peggiora la lettura: il problema era la profondità, non la lunghezza.", "togliere i controlli superflui": "Nessuno dei tre è superfluo: vanno tutti fatti, ma non uno dentro l'altro.", "spostare i controlli in fondo": "In fondo arriverebbero dopo il lavoro che dovevano proteggere, cioè troppo tardi." } },

  // =========================================================== BOOLEANI
  { topic: "booleani", difficulty: 1, difficulty8: true, applica: "coding-booleani-base",
    prompt: "Il portello chiede due condizioni insieme. Che cosa stampa?\nprint(True and False)",
    answer: "False", distractors: ["True", "None", "0"],
    explanation: "and pretende che siano vere tutte e due le parti: ne basta una falsa perché il risultato sia falso.",
    distractorWhy: { "True": "Sarebbe il risultato di or, che si accontenta di una parte vera.", "None": "Il confronto produce sempre uno dei due valori booleani, mai l'assenza di valore.", "0": "Lo zero conta come falso dentro un if, ma non è quello che questa riga stampa." } },

  { topic: "booleani", difficulty: 2, difficulty8: true, applica: "coding-booleani-base",
    prompt: "Il sensore ribalta una risposta. Che cosa stampa?\nprint(not (2 > 7))",
    answer: "True", distractors: ["False", "None", "2"],
    explanation: "Due non è maggiore di sette, quindi dentro le parentesi c'è falso, e not lo ribalta.",
    distractorWhy: { "False": "È il valore dentro le parentesi, prima che not intervenga.", "None": "not restituisce sempre uno dei due valori booleani.", "2": "Il confronto non restituisce i numeri confrontati ma l'esito del confronto." } },

  { topic: "booleani", difficulty: 3, difficulty8: true, applica: "coding-booleani-base",
    prompt: "Il pannello chiede come giudicherebbe uno zero. Che cosa stampa?\nprint(bool(0))",
    answer: "False", distractors: ["True", "0", "None"],
    explanation: "Dentro un if lo zero conta come falso e ogni altro numero come vero: bool mostra proprio quel giudizio.",
    distractorWhy: { "True": "Vale per ogni numero diverso da zero, e questo è proprio lo zero.", "0": "bool non restituisce il valore ricevuto ma come lo giudicherebbe un controllo.", "None": "Il giudizio è sempre uno dei due valori booleani." } },

  { topic: "booleani", difficulty: 4, difficulty8: true, applica: "coding-booleani-base",
    prompt: "Il filtro deve accettare solo i valori fra 2 e 9. Quale condizione funziona?",
    answer: "v > 2 and v < 9", distractors: ["v > 2 or v < 9", "v > 2 not v < 9", "v > 9 and v < 2"],
    explanation: "Servono vere tutte e due le parti, e quello lo chiede and: con or ne basterebbe una, e per ogni numero almeno una lo è.",
    distractorWhy: { "v > 2 or v < 9": "Con or basta una parte vera: il risultato è vero per qualsiasi numero, e il filtro non filtra.", "v > 2 not v < 9": "not ribalta un valore, non unisce due condizioni: la riga non ha senso.", "v > 9 and v < 2": "Chiede due cose che non possono essere vere insieme: non passa mai niente." } },

  { topic: "booleani", difficulty: 5, difficulty8: true, applica: "coding-booleani-alta",
    prompt: "Perché in un controllo si mette prima «la lista non è vuota» e poi «il primo elemento è positivo»?",
    answer: "la seconda non viene calcolata se la prima è falsa", distractors: ["la seconda è più lenta della prima", "le condizioni vengono lette in ordine alfabetico", "and richiede sempre due controlli veri"],
    explanation: "Con and, se la prima parte è già falsa il risultato è deciso e la seconda non viene guardata affatto: è quello che permette di controllare e usare nella stessa riga.",
    distractorWhy: { "la seconda è più lenta della prima": "La velocità non c'entra: conta che sulla lista vuota la seconda si fermerebbe con un errore.", "le condizioni vengono lette in ordine alfabetico": "L'ordine è quello in cui sono scritte, e chi lo sceglie è chi scrive.", "and richiede sempre due controlli veri": "Li richiede per dare vero, ma quando il primo è falso smette di guardare." } },

  { topic: "booleani", difficulty: 6, difficulty8: true, applica: "coding-booleani-alta",
    prompt: "Il contrario di «il portello è aperto e l'allarme è spento» è…",
    answer: "è chiuso oppure l'allarme suona", distractors: ["è chiuso e l'allarme suona", "è aperto oppure l'allarme suona", "è chiuso e l'allarme è spento"],
    explanation: "Negando una condizione composta si ribaltano le parti E si scambia and con or: il contrario di «tutt'e due» è «almeno una no».",
    distractorWhy: { "è chiuso e l'allarme suona": "Ribalta le parti ma lascia l'and: pretende che siano false tutte e due, che è troppo.", "è aperto oppure l'allarme suona": "Ha scambiato la parola di unione ma dimenticato di ribaltare la prima parte.", "è chiuso e l'allarme è spento": "Ha ribaltato una parte sola e lasciato l'altra com'era." } },

  { topic: "booleani", difficulty: 7, difficulty8: true, applica: "coding-booleani-alta",
    prompt: "Il magazzino è vuoto. Che cosa stampa?\ncasse = []\nprint(bool(casse))",
    answer: "False", distractors: ["True", "0", "None"],
    explanation: "Una lista vuota conta come falsa: è il motivo per cui si scrive «if casse:» invece di confrontarne la lunghezza con zero.",
    distractorWhy: { "True": "Vale per una lista con almeno un elemento dentro: questa non ne ha nessuno.", "0": "Quella è la sua lunghezza, non il giudizio che ne darebbe un controllo.", "None": "Il giudizio è sempre uno dei due valori booleani." } },

  // ============================================================== CICLI
  { topic: "cicli", difficulty: 1, difficulty8: true, applica: "coding-cicli-base",
    prompt: "Il braccio meccanico esegue questo. Quali numeri stampa, in ordine?\nfor i in range(4):\n    print(i)",
    answer: "0 1 2 3", distractors: ["1 2 3 4", "0 1 2 3 4", "1 2 3"],
    explanation: "Il numero scritto dentro range è il punto in cui ci si ferma e non viene mai raggiunto: quattro giri, ma l'ultimo valore è tre.",
    distractorWhy: { "1 2 3 4": "Parte da uno: range senza un primo numero comincia sempre da zero.", "0 1 2 3 4": "Sono cinque valori: il quattro è il punto d'arresto, non uno dei valori.", "1 2 3": "Sono solo tre giri, e ne vengono fatti quattro." } },

  { topic: "cicli", difficulty: 2, difficulty8: true, applica: "coding-cicli-base",
    format: "numeric_input",
    prompt: "Il nastro somma i pesi delle casse. Quanto vale t alla fine?\nt = 0\nfor i in range(1, 5):\n    t = t + i\nprint(t)",
    answer: "10",
    explanation: "I valori sono 1, 2, 3 e 4 — il cinque è il punto d'arresto — e la casella t sopravvive ai giri accumulando: uno più due più tre più quattro." },

  { topic: "cicli", difficulty: 3, difficulty8: true, applica: "coding-cicli-base",
    format: "numeric_input",
    prompt: "Quante volte viene eseguito il corpo di questo ciclo?\nfor i in range(3, 9):\n    print(\"passo\")",
    answer: "6",
    explanation: "La lunghezza è la differenza fra i due numeri: nove meno tre. Il nove è il punto d'arresto e non viene mai raggiunto." },

  { topic: "cicli", difficulty: 4, difficulty8: true, applica: "coding-cicli-base",
    format: "numeric_input",
    prompt: "Il condotto si svuota così. Quanto vale n quando il ciclo finisce?\nn = 20\nwhile n > 5:\n    n -= 5\nprint(n)",
    answer: "5",
    explanation: "Venti, quindici, dieci, cinque: a cinque la condizione «maggiore di cinque» smette di essere vera e il ciclo si ferma lì." },

  { topic: "cicli", difficulty: 5, difficulty8: true, applica: "coding-cicli-alta",
    prompt: "Il cercatore si ferma appena trova. Che cosa stampa?\nfor i in range(6):\n    if i == 3:\n        break\n    print(i)",
    answer: "0 1 2", distractors: ["0 1 2 3", "0 1 2 4 5", "0 1 2 3 4 5"],
    explanation: "Al giro con i uguale a tre si esce prima della stampa, e non ci sono altri giri: il ciclo finisce lì per sempre.",
    distractorWhy: { "0 1 2 3": "L'uscita avviene prima della stampa di quel giro, quindi il tre non compare.", "0 1 2 4 5": "Descrive un salto di un giro solo, che è quello che fa continue, non break.", "0 1 2 3 4 5": "Sarebbe il ciclo senza nessuna uscita anticipata." } },

  { topic: "cicli", difficulty: 6, difficulty8: true, applica: "coding-cicli-alta",
    prompt: "Il filtro scarta una cassa e prosegue. Che cosa stampa?\nfor i in range(5):\n    if i == 3:\n        continue\n    print(i)",
    answer: "0 1 2 4", distractors: ["0 1 2", "0 1 2 3 4", "0 1 2 3"],
    explanation: "Il giro del tre salta soltanto la propria stampa: il ciclo prosegue, e il quattro viene stampato normalmente.",
    distractorWhy: { "0 1 2": "Sarebbe l'uscita definitiva dal ciclo, che è quello che fa break.", "0 1 2 3 4": "Il giro del tre viene interrotto prima della stampa: quel valore non compare.", "0 1 2 3": "Salta l'ultimo giro invece di quello del tre, e il tre non viene saltato affatto." } },

  { topic: "cicli", difficulty: 7, difficulty8: true, applica: "coding-cicli-alta",
    format: "numeric_input",
    prompt: "Quante volte viene eseguita la riga più interna?\nfor r in range(4):\n    for c in range(6):\n        print(r, c)",
    answer: "24",
    explanation: "Il ciclo interno riparte da capo a ogni giro di quello esterno, quindi i giri si moltiplicano: quattro per sei." },

  // ============================================================== LISTE
  { topic: "liste", difficulty: 1, difficulty8: true, applica: "coding-liste-base",
    prompt: "Il magazzino tiene le casse in fila. Che cosa stampa?\ncasse = [12, 7, 30]\nprint(casse[1])",
    answer: "7", distractors: ["12", "30", "1"],
    explanation: "La posizione uno è la SECONDA, perché il conteggio parte da zero: il dodici sta alla posizione zero.",
    distractorWhy: { "12": "Sta alla posizione zero: la prima casella non è la numero uno.", "30": "Sta alla posizione due, l'ultima delle tre.", "1": "È il numero della posizione, non il contenuto della casella." } },

  { topic: "liste", difficulty: 2, difficulty8: true, applica: "coding-liste-base",
    format: "numeric_input",
    prompt: "Arriva una cassa nuova. Quanti elementi ha la lista alla fine?\ncasse = [4, 9, 1]\ncasse.append(5)\nprint(len(casse))",
    answer: "4",
    explanation: "append aggiunge in fondo modificando la lista esistente: da tre elementi si passa a quattro, e le posizioni valide diventano da zero a tre." },

  { topic: "liste", difficulty: 3, difficulty8: true, applica: "coding-liste-base",
    prompt: "La lista ha sei elementi. A quale posizione sta l'ultimo?",
    answer: "5", distractors: ["6", "7", "0"],
    explanation: "Le posizioni partono da zero, quindi l'ultima è «quanti sono, meno uno». Chiedere la posizione sei è una oltre la fine, e ferma il programma.",
    distractorWhy: { "6": "È quanti sono, non dove sta l'ultimo: quella posizione è già oltre la fine.", "7": "È ancora più in là: la lista non ha nessuna casella lì.", "0": "È la posizione del PRIMO elemento, non dell'ultimo." } },

  { topic: "liste", difficulty: 4, difficulty8: true, applica: "coding-liste-base",
    prompt: "Il pannello vuole l'ultima misura di una lista lunga sette. Quale riga la prende?",
    answer: "misure[-1]", distractors: ["misure[7]", "misure[len(misure)]", "misure[0]"],
    explanation: "Il meno uno conta dalla fine ed è sempre l'ultimo, qualunque sia la lunghezza. Le altre due forme chiedono una posizione che non esiste.",
    distractorWhy: { "misure[7]": "Con sette elementi le posizioni arrivano a sei: la sette è una oltre la fine.", "misure[len(misure)]": "len dice quanti sono, e quella posizione è sempre una oltre l'ultima.", "misure[0]": "È il PRIMO elemento, non l'ultimo." } },

  { topic: "liste", difficulty: 5, difficulty8: true, applica: "coding-liste-alta",
    prompt: "Il pannello taglia una fetta del registro. Che cosa stampa?\nr = [10, 20, 30, 40, 50]\nprint(r[1:3])",
    answer: "[20, 30]", distractors: ["[20, 30, 40]", "[10, 20, 30]", "[10, 20]"],
    explanation: "Dalla posizione uno fino a PRIMA della tre: la lunghezza della fetta è la differenza fra i due numeri, cioè due.",
    distractorWhy: { "[20, 30, 40]": "Include anche l'estremo destro, che invece è il punto in cui ci si ferma.", "[10, 20, 30]": "Parte dalla posizione zero: il primo numero della fetta è uno.", "[10, 20]": "Prende i primi due elementi, cioè la fetta che comincia da zero." } },

  { topic: "liste", difficulty: 6, difficulty8: true, applica: "coding-liste-alta",
    prompt: "Il pannello cerca la misura più bassa. Che cosa stampa?\nm = [8, 3, 9, 1]\nprint(sorted(m)[0])",
    answer: "1", distractors: ["8", "9", "3"],
    explanation: "sorted costruisce una lista nuova ordinata senza toccare m, e la posizione zero di una lista ordinata è il valore più piccolo.",
    distractorWhy: { "8": "È il primo elemento della lista originale, ma sorted la riordina prima di prendere la posizione zero.", "9": "È il valore più grande: starebbe all'ultima posizione, non alla zero.", "3": "È il secondo valore in ordine crescente, quindi sta alla posizione uno." } },

  { topic: "liste", difficulty: 7, difficulty8: true, applica: "coding-liste-alta",
    prompt: "Un abitante scrive questo e la lista sparisce. Che cosa stampa?\nm = [3, 1, 2]\nm = m.sort()\nprint(m)",
    answer: "None", distractors: ["[1, 2, 3]", "[3, 1, 2]", "[]"],
    explanation: "sort ordina sul posto e non restituisce niente: la variabile riceve None e la lista ordinata viene persa. Per avere un valore da assegnare serve sorted.",
    distractorWhy: { "[1, 2, 3]": "Sarebbe il risultato di sorted, che costruisce e restituisce una lista nuova.", "[3, 1, 2]": "Sarebbe la lista di partenza, ma la riga l'ha sostituita con quello che sort ha consegnato.", "[]": "La lista non viene svuotata: viene proprio sostituita da un'assenza di valore." } },

  // =========================================================== STRINGHE
  { topic: "stringhe", difficulty: 1, difficulty8: true, applica: "coding-stringhe-base",
    format: "numeric_input",
    prompt: "Quanti caratteri ha l'etichetta del portello?\nprint(len(\"porta est\"))",
    answer: "9",
    explanation: "Cinque lettere più tre più lo spazio in mezzo: lo spazio è un carattere come gli altri, e len conta tutto quello che sta fra le virgolette." },

  { topic: "stringhe", difficulty: 2, difficulty8: true, applica: "coding-stringhe-base",
    prompt: "Il pannello unisce due pezzi di etichetta. Che cosa stampa?\nprint(\"sala\" + \"nord\")",
    answer: "salanord", distractors: ["sala nord", "nordsala", "sala+nord"],
    explanation: "Il più fra due testi li accosta senza aggiungere niente in mezzo: per avere lo spazio bisogna scriverlo, come terzo pezzo.",
    distractorWhy: { "sala nord": "Lo spazio non compare da solo: nessuno lo ha scritto fra i due pezzi.", "nordsala": "L'unione mantiene l'ordine in cui i pezzi sono scritti.", "sala+nord": "Il segno è l'operazione, non un carattere che finisce nel risultato." } },

  { topic: "stringhe", difficulty: 3, difficulty8: true, applica: "coding-stringhe-base",
    prompt: "Un abitante prova a mettere in maiuscolo. Che cosa stampa?\ns = \"eco\"\ns.upper()\nprint(s)",
    answer: "eco", distractors: ["ECO", "Eco", "None"],
    explanation: "Le stringhe non si modificano: upper ne costruisce una nuova e la restituisce, e quella riga la butta via senza assegnarla a niente.",
    distractorWhy: { "ECO": "Sarebbe il risultato se la riga fosse stata assegnata: com'è scritta, viene perso.", "Eco": "upper mette in maiuscolo tutto, non la sola iniziale.", "None": "La variabile non è stata toccata: contiene ancora il testo di partenza." } },

  { topic: "stringhe", difficulty: 4, difficulty8: true, applica: "coding-stringhe-base",
    prompt: "Il pannello legge una lettera dell'etichetta. Che cosa stampa?\ns = \"relitto\"\nprint(s[0])",
    answer: "r", distractors: ["e", "o", "7"],
    explanation: "Anche nel testo le posizioni partono da zero, quindi la posizione zero è la prima lettera.",
    distractorWhy: { "e": "Sta alla posizione uno: la prima casella non è la numero uno.", "o": "È l'ultima lettera, che sta alla posizione sei.", "7": "È la lunghezza della parola, non il carattere richiesto." } },

  { topic: "stringhe", difficulty: 5, difficulty8: true, applica: "coding-stringhe-alta",
    format: "numeric_input",
    prompt: "Quante parole ha il messaggio?\nprint(len(\"il condotto est perde\".split()))",
    answer: "4",
    explanation: "split senza argomenti taglia sugli spazi e restituisce una lista di parole; len conta gli elementi di quella lista, non i caratteri del testo." },

  { topic: "stringhe", difficulty: 6, difficulty8: true, applica: "coding-stringhe-alta",
    prompt: "Il registro ricuce tre sigle. Che cosa stampa?\nprint(\"/\".join([\"a\", \"b\", \"c\"]))",
    answer: "a/b/c", distractors: ["/a/b/c", "a/b/c/", "abc"],
    explanation: "Il separatore va FRA gli elementi: con tre elementi compare due volte, mai davanti al primo né dopo l'ultimo.",
    distractorWhy: { "/a/b/c": "Mette il separatore anche in testa, dove non c'è nessuna coppia da separare.", "a/b/c/": "Mette il separatore anche in coda, dopo l'ultimo elemento.", "abc": "Sarebbe il risultato con un separatore vuoto: qui è stata indicata una barra." } },

  { topic: "stringhe", difficulty: 7, difficulty8: true, applica: "coding-stringhe-alta",
    prompt: "Il codice digitato ha uno spazio in fondo e il confronto fallisce. Che cosa si scrive prima di confrontare?",
    answer: "codice = codice.strip()", distractors: ["codice = codice.upper()", "codice.strip()", "codice = codice.replace(\"a\", \"\")"],
    explanation: "strip restituisce una copia senza gli spazi ai bordi, e va assegnata: chiamarla e basta costruisce la copia pulita e la butta via.",
    distractorWhy: { "codice = codice.upper()": "Cambia le maiuscole e lascia lo spazio esattamente dov'era.", "codice.strip()": "Costruisce la copia pulita ma non la assegna a niente: la variabile resta sporca.", "codice = codice.replace(\"a\", \"\")": "Toglie una lettera in tutto il testo, non gli spazi ai bordi." } },

  // =========================================================== FUNZIONI
  { topic: "funzioni", difficulty: 1, difficulty8: true, applica: "coding-funzioni-base",
    format: "numeric_input",
    prompt: "L'officina raddoppia i pacchi. Che numero stampa?\ndef doppio(n):\n    return n * 2\nprint(doppio(7))",
    answer: "14",
    explanation: "Il sette entra nel parametro n, il corpo calcola quattordici e lo consegna: print riceve il valore consegnato e lo mostra." },

  { topic: "funzioni", difficulty: 2, difficulty8: true, applica: "coding-funzioni-base",
    prompt: "L'officina saluta e basta. Che cosa stampa l'ultima riga?\ndef avvisa():\n    print(\"attenzione\")\nx = avvisa()\nprint(x)",
    answer: "None", distractors: ["attenzione", "0", "x"],
    explanation: "La funzione mostra qualcosa ma non consegna niente, quindi a x arriva None: mostrare e consegnare sono due cose diverse.",
    distractorWhy: { "attenzione": "È quello che la funzione stampa per conto suo, non quello che consegna a chi la chiama.", "0": "L'assenza di valore non è lo zero: sono due cose diverse.", "x": "È il nome della casella, e senza virgolette print ne stampa il contenuto." } },

  { topic: "funzioni", difficulty: 3, difficulty8: true, applica: "coding-funzioni-base",
    prompt: "Un abitante scrive «avvisa» su una riga da sola e non succede niente. Perché?",
    answer: "mancano le parentesi che la chiamano", distractors: ["la funzione non è stata definita", "manca return dentro il corpo", "il nome è scritto in minuscolo"],
    explanation: "Senza parentesi la riga nomina la funzione invece di eseguirla: nessun errore, nessun effetto, e nulla che spieghi perché non è successo niente.",
    distractorWhy: { "la funzione non è stata definita": "Se non lo fosse, Python si fermerebbe con un errore invece di non fare niente.", "manca return dentro il corpo": "Senza return la funzione consegna None, ma il corpo verrebbe comunque eseguito.", "il nome è scritto in minuscolo": "Il minuscolo è la convenzione normale dei nomi e non impedisce nessuna chiamata." } },

  { topic: "funzioni", difficulty: 4, difficulty8: true, applica: "coding-funzioni-base",
    prompt: "Che cosa stampa questa officina?\ndef prova():\n    return 1\n    return 2\nprint(prova())",
    answer: "1", distractors: ["2", "3", "None"],
    explanation: "return consegna e chiude la funzione all'istante: la riga sotto non viene eseguita mai, perché si trova dopo un'uscita.",
    distractorWhy: { "2": "È il secondo return, che il flusso non raggiunge: il primo ha già chiuso la funzione.", "3": "I due valori non si sommano: viene consegnato solo quello del return raggiunto.", "None": "Un return c'è ed è stato raggiunto, quindi qualcosa viene consegnato." } },

  { topic: "funzioni", difficulty: 5, difficulty8: true, applica: "coding-funzioni-alta",
    format: "numeric_input",
    prompt: "Che numero stampa l'ultima riga?\ndef f(n):\n    n = n + 10\n    return n\nx = 5\nf(x)\nprint(x)",
    answer: "5",
    explanation: "Dentro la funzione n è una casella sua: riassegnarla non tocca x, e il valore consegnato non è stato raccolto da nessuno." },

  { topic: "funzioni", difficulty: 6, difficulty8: true, applica: "coding-funzioni-alta",
    format: "numeric_input",
    prompt: "Quanti elementi ha la lista alla fine?\ndef carica(l):\n    l.append(1)\n    l.append(2)\nv = []\ncarica(v)\nprint(len(v))",
    answer: "2",
    explanation: "Il parametro è un'altra etichetta sulla stessa lista: le due aggiunte fatte dentro la funzione si vedono anche da fuori. Riassegnare no, modificare sì." },

  { topic: "funzioni", difficulty: 7, difficulty8: true, applica: "coding-funzioni-alta",
    prompt: "Una funzione calcola un totale e lo stampa. Perché conviene separarla in due?",
    answer: "la parte che calcola diventa riusabile", distractors: ["due funzioni corte sono più veloci", "la stampa va sempre fatta per ultima", "una funzione non può avere due righe"],
    explanation: "Chi calcola senza stampare può essere usato altrove e provato da solo; chi mescola le due cose non si riesce a riutilizzare mai.",
    distractorWhy: { "due funzioni corte sono più veloci": "La velocità non cambia: cambia che cosa si può fare con i pezzi.", "la stampa va sempre fatta per ultima": "Non è una regola, e comunque non spiega perché separare i due lavori.", "una funzione non può avere due righe": "Può averne quante ne servono: il problema è che ne fa due di mestieri." } },

  // ============================================================== STILE
  { topic: "stile", difficulty: 1, difficulty8: true, applica: "coding-stile-base",
    prompt: "La casella conta i portelli chiusi. Quale nome è il migliore?",
    answer: "portelli_chiusi", distractors: ["p", "numero2", "PortelliChiusi"],
    explanation: "Dice il significato del valore, e permette di leggere le righe che lo usano senza tornare indietro a cercare che cosa contiene.",
    distractorWhy: { "p": "Una lettera sola obbliga a tornare indietro ogni volta per ricordarsi che cosa contiene.", "numero2": "Dice il tipo e un numero d'ordine, cioè le due cose che si vedono già leggendo il valore.", "PortelliChiusi": "Il significato c'è, ma non è la convenzione di Python, che vuole minuscolo e trattino basso." } },

  { topic: "stile", difficulty: 2, difficulty8: true, applica: "coding-stile-base",
    prompt: "Accanto alla riga «i = i + 1», quale commento è utile?",
    answer: "# il sensore conta da 1, non da 0", distractors: ["# aggiunge 1 a i", "# incrementa di uno la variabile", "# somma uno al contatore"],
    explanation: "Spiega la ragione per cui quella riga esiste, e la ragione dal codice non si può dedurre. Gli altri tre ripetono quello che la riga già dice.",
    distractorWhy: { "# aggiunge 1 a i": "Ripete la riga parola per parola: alla prima modifica resterà indietro a dire il falso.", "# incrementa di uno la variabile": "Stessa ripetizione, scritta con una parola più tecnica.", "# somma uno al contatore": "Dice ancora una volta quello che si legge dalla riga stessa." } },

  { topic: "stile", difficulty: 3, difficulty8: true, applica: "coding-stile-base",
    prompt: "In Python, che cosa succede se il rientro di un blocco è sbagliato?",
    answer: "il programma non parte o cambia senso", distractors: ["diventa soltanto un poco meno leggibile", "Python lo sistema da solo", "cambia soltanto la velocità"],
    explanation: "Il rientro in Python è sintassi, non ordine: è il modo in cui il linguaggio sa dove comincia e dove finisce un blocco.",
    distractorWhy: { "diventa soltanto un poco meno leggibile": "Vale negli altri linguaggi: qui il rientro decide a chi appartiene una riga.", "Python lo sistema da solo": "Non lo tocca: non ha modo di sapere quale dei due significati volevi.", "cambia soltanto la velocità": "La velocità non c'entra: cambia quali righe vengono eseguite." } },

  { topic: "stile", difficulty: 4, difficulty8: true, applica: "coding-stile-base",
    prompt: "Quale di questi nomi segue la convenzione di Python?",
    answer: "giorni_rimasti", distractors: ["GiorniRimasti", "giorniRimasti", "GIORNI-RIMASTI"],
    explanation: "Minuscolo con le parole separate dal trattino basso: non è una regola del linguaggio ma la seguono tutti, il che è quasi la stessa cosa.",
    distractorWhy: { "GiorniRimasti": "È la convenzione di altri linguaggi: in Python rallenta chi legge.", "giorniRimasti": "La maiuscola in mezzo appartiene a un'altra convenzione, non a questa.", "GIORNI-RIMASTI": "Il trattino non è nemmeno ammesso in un nome: Python lo leggerebbe come una sottrazione." } },

  { topic: "stile", difficulty: 5, difficulty8: true, applica: "coding-stile-alta",
    prompt: "Lo stesso blocco compare in tre punti, cambia solo un valore. Che cosa conviene fare?",
    answer: "una funzione con quel valore come parametro", distractors: ["copiarlo con attenzione una quarta volta", "commentare che sono uguali", "accorciarlo togliendo le righe"],
    explanation: "L'unica differenza è un valore, ed è esattamente il lavoro di un parametro: una copia sola del calcolo, e una correzione che vale per tutti i casi.",
    distractorWhy: { "copiarlo con attenzione una quarta volta": "Aggiunge una copia che invecchierà per conto suo, cioè peggiora il difetto.", "commentare che sono uguali": "Il commento non impedisce che una copia venga corretta e le altre no.", "accorciarlo togliendo le righe": "Toglie codice che serve: il problema non è la lunghezza ma la duplicazione." } },

  { topic: "stile", difficulty: 6, difficulty8: true, applica: "coding-stile-alta",
    prompt: "Nel codice compare più volte il numero 18 come soglia d'età. Che cosa conviene fare?",
    answer: "dargli un nome e usarlo ovunque", distractors: ["lasciarlo dov'è e ricordarselo", "commentarlo in ogni punto", "cambiarlo in un numero più chiaro"],
    explanation: "Il nome spiega perché è proprio quel valore, e raccoglierlo in un punto solo evita la caccia alle occorrenze quando la soglia cambia.",
    distractorWhy: { "lasciarlo dov'è e ricordarselo": "Alla prima modifica bisogna trovarle tutte, distinguendole dai 18 che significano altro.", "commentarlo in ogni punto": "Ripete la spiegazione in ogni copia, e il valore resta comunque sparso.", "cambiarlo in un numero più chiaro": "Nessun numero è chiaro da solo: quello che manca è il nome, non un altro valore." } },

  { topic: "stile", difficulty: 7, difficulty8: true, applica: "coding-stile-alta",
    prompt: "Come si riconosce che una funzione fa troppe cose?",
    answer: "per descriverla serve una «e»", distractors: ["supera le dieci righe di codice", "ha più di due parametri", "contiene almeno un ciclo"],
    explanation: "Se il nome ha bisogno di una congiunzione — «calcola il totale E lo stampa» — dentro ci sono due funzioni, e separarle rende riusabile la prima.",
    distractorWhy: { "supera le dieci righe di codice": "Una funzione lunga che fa una cosa sola va benissimo: conta il mestiere, non la misura.", "ha più di due parametri": "Il numero di parametri riguarda la firma, non quante cose la funzione fa dentro.", "contiene almeno un ciclo": "Un ciclo è un modo di fare una cosa sola molte volte, non due cose diverse." } },

  // ============================================================== INPUT
  { topic: "input", difficulty: 1, difficulty8: true, applica: "coding-input-base",
    prompt: "L'abitante digita 12 al pannello. Che cosa contiene la casella?\nv = input()",
    answer: "il testo \"12\"", distractors: ["il numero 12", "il numero 1", "niente"],
    explanation: "input consegna sempre testo, anche quando sono tutte cifre: il fatto che assomigli a un numero non lo rende un numero.",
    distractorWhy: { "il numero 12": "Sarebbe così solo dopo una conversione scritta a mano: input non la fa mai da solo.", "il numero 1": "Non viene letta una cifra sola: arriva tutto quello che è stato scritto.", "niente": "Qualcosa è stato digitato, e input lo consegna." } },

  { topic: "input", difficulty: 2, difficulty8: true, applica: "coding-input-base",
    prompt: "L'abitante digita 2 e poi 3. Che cosa stampa?\na = input()\nb = input()\nprint(a + b)",
    answer: "23", distractors: ["5", "2 3", "6"],
    explanation: "I due valori sono testo, e il più fra testi accosta invece di sommare: il programma non segnala nulla e risponde con le due cifre attaccate.",
    distractorWhy: { "5": "Sarebbe la somma, ma servirebbe convertire i due valori prima del più.", "2 3": "Unendo due testi non compare nessuno spazio: nessuno lo ha scritto.", "6": "Il più non moltiplica mai, né su numeri né su testo." } },

  { topic: "input", difficulty: 3, difficulty8: true, applica: "coding-input-base",
    prompt: "Lo stesso pannello deve fare la somma. Quale riga lo ripara?",
    answer: "a = int(input())", distractors: ["a = str(input())", "a = input() + 0", "a = input(int())"],
    explanation: "La conversione va fatta appena il valore arriva: da quella riga in poi la casella contiene un numero e nessun'altra parte del programma deve ricordarsene.",
    distractorWhy: { "a = str(input())": "Trasforma in testo una cosa che è già testo: non cambia niente.", "a = input() + 0": "Somma un numero a un testo, che è proprio l'operazione che Python rifiuta.", "a = input(int())": "Mette la conversione al posto del messaggio da mostrare: converte il testo sbagliato." } },

  { topic: "input", difficulty: 4, difficulty8: true, applica: "coding-input-base",
    prompt: "Prima di convertire in numero, come si controlla che il testo digitato sia fatto di sole cifre?",
    answer: "v.isdigit()", distractors: ["v == int", "int(v) == True", "v.lower()"],
    explanation: "isdigit risponde vero o falso e permette di controllare PRIMA di convertire, invece di lasciare che il programma si fermi con un errore.",
    distractorWhy: { "v == int": "Confronta il testo con il nome di un tipo: il risultato è sempre falso.", "int(v) == True": "Converte prima di controllare, cioè si ferma proprio nel caso che si voleva evitare.", "v.lower()": "Porta il testo in minuscolo, che sulle cifre non cambia niente e non dice se di cifre si tratta." } },

  { topic: "input", difficulty: 5, difficulty8: true, applica: "coding-input-alta",
    prompt: "Un ciclo che chiede un valore valido ripete la domanda all'infinito anche con la risposta giusta. Che cosa manca?",
    answer: "una nuova lettura dentro il corpo", distractors: ["un controllo più largo", "una condizione con or", "un messaggio di errore più chiaro"],
    explanation: "Senza rileggere, la condizione esamina per sempre lo stesso valore: il ciclo gira, la domanda ricompare, e la risposta giusta non viene mai accettata.",
    distractorWhy: { "un controllo più largo": "Il controllo funziona: quello che non arriva mai al controllo è il valore nuovo.", "una condizione con or": "Cambiare la parola di unione non fa rileggere niente, e il ciclo resta identico.", "un messaggio di errore più chiaro": "Il messaggio aiuta chi legge, ma non è lui a impedire al ciclo di finire." } },

  { topic: "input", difficulty: 6, difficulty8: true, applica: "coding-input-alta",
    prompt: "Vengono digitati 4, 6 e poi «fine». Quanto vale il totale?\nt = 0\nv = input()\nwhile v != \"fine\":\n    t = t + int(v)\n    v = input()",
    answer: "10", distractors: ["0", "4", "16"],
    explanation: "Il controllo avviene prima di usare il valore, quindi la parola fine non entra mai nella somma: quattro più sei.",
    distractorWhy: { "0": "Il ciclo parte: il primo valore letto non è la sentinella.", "4": "Sarebbe la somma di un giro solo, ma il ciclo rilegge e ne fa due.", "16": "Aggiunge un valore che non è stato digitato: i numeri sono due." } },

  { topic: "input", difficulty: 7, difficulty8: true, applica: "coding-input-alta",
    prompt: "Il pannello rifiuta un valore. Quale messaggio è il migliore?",
    answer: "serve un numero fra 1 e 10, hai scritto 42", distractors: ["errore nel valore digitato", "valore non valido, riprova", "attenzione: il valore è stato rifiutato"],
    explanation: "Contiene il vincolo e il valore ricevuto, cioè le due informazioni che chi sta davanti allo schermo non ha. Gli altri dicono solo che qualcosa non va.",
    distractorWhy: { "errore nel valore digitato": "Dice che c'è un problema e non dice né quale vincolo né che cosa è arrivato.", "valore non valido, riprova": "Invita a riprovare senza dare niente di nuovo su cui basare il secondo tentativo.", "attenzione: il valore è stato rifiutato": "Nomina l'esito e nasconde entrambe le informazioni che servirebbero." } },

  // ============================================================= OUTPUT
  { topic: "output", difficulty: 1, difficulty8: true, applica: "coding-output-base",
    prompt: "Il pannello esegue queste due righe. Che cosa stampa?\nsala = 9\nprint(\"sala\")",
    answer: "sala", distractors: ["9", "sala = 9", "niente"],
    explanation: "Le virgolette dichiarano testo: Python stampa le quattro lettere senza cercare nessuna casella, ed è la differenza fra il nome e la cosa.",
    distractorWhy: { "9": "Sarebbe il risultato senza virgolette, quando il nome viene cercato e se ne stampa il contenuto.", "sala = 9": "print mostra solo quello che riceve, e ha ricevuto una parola sola.", "niente": "La riga è valida ed esegue: qualcosa viene stampato di sicuro." } },

  { topic: "output", difficulty: 2, difficulty8: true, applica: "coding-output-base",
    prompt: "Il pannello mostra un'etichetta e un numero. Che cosa stampa?\nprint(\"Casse:\", 8)",
    answer: "Casse: 8", distractors: ["Casse:8", "Casse: , 8", "Casse 8"],
    explanation: "La virgola dentro print inserisce da sola uno spazio fra i due valori, e accetta tipi diversi senza chiedere conversioni.",
    distractorWhy: { "Casse:8": "Sarebbe il risultato unendo due testi con il più: la virgola invece lo spazio lo mette.", "Casse: , 8": "La virgola è il separatore degli argomenti e non finisce mai nel risultato.", "Casse 8": "I due punti stanno dentro le virgolette, quindi vengono stampati com'erano scritti." } },

  { topic: "output", difficulty: 3, difficulty8: true, applica: "coding-output-base",
    prompt: "Quante righe produce questo?\nprint(\"primo\")\nprint(\"secondo\")",
    answer: "2", distractors: ["1", "0", "4"],
    explanation: "print va a capo dopo aver mostrato quello che riceve, quindi due print producono due righe distinte.",
    distractorWhy: { "1": "Sarebbe così se print non andasse a capo, e invece ci va sempre da solo.", "0": "Tutt'e due le righe sono valide ed eseguono.", "4": "Ogni print produce una riga sola, non due." } },

  { topic: "output", difficulty: 4, difficulty8: true, applica: "coding-output-base",
    prompt: "Il pannello ha una casella piena e la mostra. Che cosa stampa?\nlivello = 3\nprint(livello)",
    answer: "3", distractors: ["livello", "livello 3", "None"],
    explanation: "Senza virgolette Python capisce che è il nome di una casella, va a vedere che cosa c'è dentro e stampa quello.",
    distractorWhy: { "livello": "Sarebbe il risultato con le virgolette attorno al nome.", "livello 3": "print mostra solo quello che riceve, e ha ricevuto un valore solo.", "None": "La casella è stata riempita dalla riga sopra: qualcosa c'è dentro." } },

  { topic: "output", difficulty: 5, difficulty8: true, applica: "coding-output-alta",
    prompt: "Il pannello compone una frase. Che cosa stampa?\nn = 4\nprint(f\"restano {n} casse\")",
    answer: "restano 4 casse", distractors: ["restano n casse", "restano {4} casse", "restano {n} casse"],
    explanation: "La f davanti alle virgolette attiva le graffe: quello che sta dentro viene sostituito con il suo valore al momento della stampa.",
    distractorWhy: { "restano n casse": "Sarebbe il risultato senza la f davanti, quando le graffe non vengono guardate.", "restano {4} casse": "Le graffe spariscono insieme al nome: sono il segnale della sostituzione, non testo.", "restano {n} casse": "È la riga così com'è scritta nel codice, prima che la sostituzione avvenga." } },

  { topic: "output", difficulty: 6, difficulty8: true, applica: "coding-output-alta",
    prompt: "Il pannello mostra tre valori in fila. Su quante righe escono?\nfor i in range(3):\n    print(i, end=\" \")",
    answer: "1", distractors: ["3", "0", "2"],
    explanation: "end sostituisce l'a capo con uno spazio, quindi i tre valori restano sulla stessa riga invece di occuparne tre.",
    distractorWhy: { "3": "Sarebbe il risultato senza end, quando ogni print va a capo per conto suo.", "0": "Il ciclo esegue e stampa: qualcosa compare di sicuro.", "2": "Non c'è nessun punto in cui il ciclo andrebbe a capo una volta sola." } },

  { topic: "output", difficulty: 7, difficulty8: true, applica: "coding-output-alta",
    prompt: "Dopo aver stampato una media con due decimali, quante cifre ha la variabile?",
    answer: "tutte quelle che aveva", distractors: ["esattamente due decimali", "nessun decimale", "una in meno di prima"],
    explanation: "Il formato riguarda solo la stampa: il valore nella casella resta com'era, e i conti successivi useranno quello. Per cambiarlo davvero serve round.",
    distractorWhy: { "esattamente due decimali": "È quello che si vede a schermo, non quello che la casella contiene.", "nessun decimale": "Nessuna riga ha convertito il valore a intero: la virgola c'è ancora.", "una in meno di prima": "Il formato non toglie cifre al valore: decide soltanto quante mostrarne." } },

  // ========================================================== ALGORITMI
  { topic: "algoritmi", difficulty: 1, difficulty8: true, applica: "coding-algoritmi-base",
    prompt: "Quale di questi non è un passo valido di un algoritmo?",
    answer: "aggiungi un po' di sale", distractors: ["aggiungi un cucchiaino di sale", "conta le casse rimaste", "apri il portello est"],
    explanation: "Ogni passo deve potersi eseguire senza chiedere niente a nessuno: «un po'» obbliga chi esegue a indovinare quanto, e il risultato cambia a ogni esecuzione.",
    distractorWhy: { "aggiungi un cucchiaino di sale": "È la stessa azione resa misurabile: chi esegue sa esattamente quanto.", "conta le casse rimaste": "L'azione è definita e il risultato è lo stesso per chiunque la esegua.", "apri il portello est": "Dice quale portello e che cosa farne: non resta niente da indovinare." } },

  { topic: "algoritmi", difficulty: 2, difficulty8: true, applica: "coding-algoritmi-base",
    format: "numeric_input",
    prompt: "Con lo schema «tieni il migliore finora», quanti confronti servono per trovare il valore più grande fra 40 misure?",
    answer: "39",
    explanation: "La prima misura riempie la casella senza nessun confronto, e ognuna delle 39 successive viene confrontata una volta sola con il migliore finora." },

  { topic: "algoritmi", difficulty: 3, difficulty8: true, applica: "coding-algoritmi-base",
    prompt: "Due passi di una procedura vengono scambiati di posto. Che cosa succede?",
    answer: "il risultato può cambiare", distractors: ["il risultato resta identico", "la procedura diventa più veloce", "Python segnala un errore"],
    explanation: "In un algoritmo i passi sono ordinati, e l'ordine è una delle tre proprietà che lo distinguono da un elenco: mettere il caffè prima dell'acqua non è la stessa cosa.",
    distractorWhy: { "il risultato resta identico": "Vale solo per i passi indipendenti fra loro, che sono la minoranza.", "la procedura diventa più veloce": "Il numero di passi non cambia: cambia che cosa producono.", "Python segnala un errore": "Un ordine sbagliato quasi sempre è codice valido: dà la risposta sbagliata in silenzio." } },

  { topic: "algoritmi", difficulty: 4, difficulty8: true, applica: "coding-algoritmi-base",
    prompt: "Va contato quante misure superano una soglia. Quale schema si applica?",
    answer: "una casella che cresce a ogni misura buona", distractors: ["una casella che tiene il valore più alto", "una casella che tiene l'ultimo valore", "due cicli uno dentro l'altro"],
    explanation: "È lo stesso schema del massimo con l'accumulatore cambiato: si scorre una volta sola e si aggiorna la casella quando la condizione è vera.",
    distractorWhy: { "una casella che tiene il valore più alto": "Risponde a «qual è il massimo», non a «quante ne superano la soglia».", "una casella che tiene l'ultimo valore": "Alla fine conterrebbe l'ultima misura letta, che non è un conteggio.", "due cicli uno dentro l'altro": "Basta un passaggio solo: il secondo ciclo moltiplicherebbe il lavoro per niente." } },

  { topic: "algoritmi", difficulty: 5, difficulty8: true, applica: "coding-algoritmi-alta",
    format: "numeric_input",
    prompt: "Due cicli annidati scorrono ciascuno 500 elementi. Quante volte viene eseguita la riga più interna?",
    answer: "250000",
    explanation: "Il ciclo interno riparte per intero a ogni giro di quello esterno, quindi i giri si moltiplicano: cinquecento per cinquecento." },

  { topic: "algoritmi", difficulty: 6, difficulty8: true, applica: "coding-algoritmi-alta",
    prompt: "La ricerca che taglia a metà dà una risposta sbagliata. Qual è la causa più probabile?",
    answer: "la lista non era ordinata", distractors: ["la lista era troppo lunga", "il valore cercato era il primo", "la lista aveva dei doppioni"],
    explanation: "Tagliare a metà funziona solo se dalla parte scartata non può esserci niente, e questo lo garantisce l'ordine: senza, il metodo sbaglia in silenzio.",
    distractorWhy: { "la lista era troppo lunga": "La lunghezza è proprio il caso in cui questo metodo dà il suo meglio.", "il valore cercato era il primo": "È un caso fortunato, non un caso che produca risposte sbagliate.", "la lista aveva dei doppioni": "Con i doppioni può trovarne uno qualsiasi, ma resta una risposta giusta." } },

  { topic: "algoritmi", difficulty: 7, difficulty8: true, applica: "coding-algoritmi-alta",
    prompt: "Su un registro disordinato vanno fatte mille ricerche. Conviene ordinarlo prima?",
    answer: "sì, il costo si divide su mille", distractors: ["no, ordinare costa sempre troppo", "no, l'ordine non serve a cercare", "sì, ma solo se è già quasi ordinato"],
    explanation: "Ordinare costa più di una singola ricerca, e per una sola sarebbe una perdita netta: pagato una volta e diviso su mille, diventa il ragionamento che sta dietro a ogni indice.",
    distractorWhy: { "no, ordinare costa sempre troppo": "Costa troppo per una ricerca sola: su mille il conto si ribalta.", "no, l'ordine non serve a cercare": "È proprio l'ordine a permettere di buttare via metà registro a ogni passo.", "sì, ma solo se è già quasi ordinato": "Il vantaggio non dipende da quanto era disordinato, ma da quante ricerche seguiranno." } },
];
