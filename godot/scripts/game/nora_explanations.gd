class_name NoraExplanations
extends RefCounted

## **Il perché di NORA, uno per argomento.** (12 agosto 2026)
##
## Richiesta del committente: «fai una revisione totale delle spiegazioni di
## NORA. Le trovo scarse.» Aveva ragione, e misurandolo sono venuti fuori tre
## difetti di dimensione molto diversa.
##
## **Primo, e il più grosso: rispondendo GIUSTO non arrivava nessuna
## spiegazione.** `exercise_player` mostrava «Giusto! +N energia» e passava
## avanti; il campo `explanation` compariva **solo sbagliando**. Il gioco è
## tarato perché il bambino risponda bene la maggior parte delle volte, quindi la
## maggior parte delle volte non riceveva niente: confermava di sapere una cosa e
## non ne imparava nessun'altra. Tremilaquattrocento spiegazioni scritte, e la
## strada per arrivare al bambino era aperta solo sull'errore.
##
## **Secondo: le spiegazioni dicono COSA, non PERCHÉ.** Su 3412 item, **l'8%**
## contiene un nesso causale. Le altre riformulano il fatto: alla domanda «qual è
## la capitale d'Italia?» la spiegazione era «Roma è la capitale della Repubblica
## Italiana». Vera, inutile: il bambino rilegge quello che ha appena scritto.
##
## Il difetto **non è la lunghezza** — `bank_explanation_audit` l'aveva già
## misurato: fra le spiegazioni sotto i 40 caratteri la maggioranza è ottima,
## corta perché precisa. Il difetto è che non danno **niente a cui aggrapparsi**:
## una causa, un'immagine, un modo per ritrovarselo da soli. Le poche buone si
## riconoscono subito — «Da *aqua* vengono acquedotto e acquario», «Senza le
## piene l'Egitto sarebbe stato solo deserto», «Il cucchiaino di metallo nel tè
## scotta per conduzione».
##
## **Terzo: il manuale ereditava la debolezza.** `KnowledgeCodex` dichiara di
## raccogliere le voci dai banchi perché «ogni item porta già una spiegazione
## causale». Non è vero, e la misura lo dice: il manuale raccoglieva
## riformulazioni. Gli argomenti autorati a mano erano **due**.
##
## ### Perché per argomento e non per item
##
## Gli item sono 3412, gli argomenti del runtime **135**. Riscrivere gli item
## sarebbe stato un lavoro di massa a qualità bassa; il perché di «declinazione
## terza» è lo stesso per tutti e trentatré i suoi item, e scritto una volta bene
## vale per tutti. Venticinque volte meno lavoro, e nessuna deriva fra copie.
##
## L'item resta quello che è: il caso particolare. NORA aggiunge la ragione
## generale — e solo **quando l'item non ce l'ha già**, per non ripetersi.
##
## ### Che cosa contiene una voce
##
## **`perche`** — a che cosa serve, o perché funziona così. Mai la ripetizione
## del nome dell'argomento.
##
## **`come`** — come ci si arriva da soli la prossima volta. È la convinzione di
## NORA messa in pratica: la risposta non si presta, il metodo sì.

## Le parole che segnalano un nesso.
##
## **Questo elenco serve a SCEGLIERE, non a giudicare**, e la distinzione è
## costata un errore. L'avevo usato come criterio di qualità in un audit, e ne
## sono uscite rosse trenta voci scritte bene: «Le parentesi servono a dire
## *questo prima*» spiega un perché senza contenere la parola «perché», e
## «L'uguale è una bilancia in equilibrio» non ha nessuna parola-spia ed è la
## spiegazione migliore del gruppo. È lo stesso errore dei digrammi impossibili:
## una lista di parole messa al posto di un giudizio.
##
## Qui va benissimo, perché la posta è bassa: decide solo se NORA debba
## aggiungere il suo perché o se l'item ce l'abbia già. Sbagliare vuol dire, al
## massimo, una riga in più.
const SEGNI_DI_CAUSA := ["perch", "poich", "siccome", "quindi", "perciò", "infatti",
	"per questo", "vuol dire", "cioè", "significa", "dato che", "serve a", "serve per",
	"servono a", "servono per", "basta ", "così che", "dunque", "allora "]

## Una voce per ogni argomento che il runtime può proporre.
const VOCI := {
	# -- matematica -------------------------------------------------------------
	"matematica:tabelline": {
		"perche": "Moltiplicare serve a non contare uno per uno: è la scorciatoia per i gruppi uguali.",
		"come": "Se una tabellina non ti viene, parti da una che sai e aggiungi una riga: 7×6 è 7×5 più altri 7.",
	},
	"matematica:calcolo": {
		"perche": "L'ordine delle operazioni non è un capriccio: senza, la stessa scrittura darebbe risultati diversi a persone diverse.",
		"come": "Cerchia prima moltiplicazioni e divisioni, risolvile, e solo dopo somma quello che resta.",
	},
	"matematica:divisioni": {
		"perche": "Dividere risponde a due domande diverse: in quante parti uguali, oppure quante volte ci sta.",
		"come": "Chiediti quale delle due domande ti stanno facendo: cambia che cosa rappresenta il risultato.",
	},
	"matematica:frazioni": {
		"perche": "La frazione serve a parlare di pezzi di una cosa sola, quando il numero intero non basta più.",
		"come": "Leggi il denominatore come «in quanti pezzi ho tagliato» e il numeratore come «quanti ne tengo».",
	},
	"matematica:percentuali": {
		"perche": "La percentuale serve a confrontare quantità di grandezze diverse: su cento si può paragonare tutto.",
		"come": "Il 10% è dividere per dieci. Da lì costruisci: il 30% è tre volte il 10%, il 5% è la metà.",
	},
	"matematica:proporzioni": {
		"perche": "Servono quando due cose crescono insieme: raddoppia una, raddoppia l'altra.",
		"come": "Scrivi la coppia che conosci, poi chiediti per quanto è stata moltiplicata: lo stesso numero vale per l'altra.",
	},
	"matematica:potenze": {
		"perche": "Sono una moltiplicazione ripetuta scritta corta, perché certe quantità crescono troppo in fretta per scriverle per esteso.",
		"come": "L'esponente dice quante volte compare la base, non per quanto la moltiplichi: 2³ è 2×2×2, non 2×3.",
	},
	"matematica:radici": {
		"perche": "La radice torna indietro dalla potenza, come la sottrazione torna indietro dall'addizione.",
		"come": "Non cercare la radice: cerca il numero che moltiplicato per sé stesso dà quello che vedi.",
	},
	"matematica:espressioni": {
		"perche": "Le parentesi servono a dire «questo prima», quando l'ordine normale non darebbe il conto che vuoi.",
		"come": "Risolvi sempre la parentesi più interna e riscrivi tutta l'espressione: un passo per riga, senza saltarne.",
	},
	"matematica:equazioni": {
		"perche": "L'uguale è una bilancia in equilibrio: tutto quello che fai da una parte lo devi fare dall'altra.",
		"come": "Sposta i numeri da una parte e la lettera dall'altra, cambiando segno a chi attraversa l'uguale.",
	},
	"matematica:geometria": {
		"perche": "Perimetro e area rispondono a domande diverse: quanto filo per recintare, quanta vernice per dipingere.",
		"come": "Prima di calcolare, chiediti se ti serve il contorno o la superficie: sbagliare formula è quasi sempre sbagliare domanda.",
	},
	"matematica:coordinate": {
		"perche": "Due numeri bastano a individuare un punto, ed è per questo che una mappa può stare su un foglio.",
		"come": "Prima quanto vai a destra, poi quanto vai in su. Sempre in quest'ordine, altrimenti arrivi altrove.",
	},
	"matematica:sequenze": {
		"perche": "Trovare la regola vale più che indovinare il numero: con la regola sai anche il centesimo termine.",
		"come": "Calcola le differenze fra termini vicini. Se sono uguali si somma sempre lo stesso; se no, prova a moltiplicare.",
	},
	"matematica:dati": {
		"perche": "I dati si organizzano per rispondere a una domanda: senza la domanda, una tabella è solo un elenco.",
		"come": "Prima di leggere il grafico, leggi che cosa c'è scritto sui due assi. Metà degli errori nasce lì.",
	},
	"matematica:statistica": {
		"perche": "Media, moda e mediana riassumono lo stesso gruppo in tre modi, e servono a cose diverse.",
		"come": "La media si sposta se c'è un valore enorme; la mediana no. Guarda se nel gruppo c'è un caso fuori scala.",
	},
	"matematica:problemi": {
		"perche": "Un problema è una traduzione: le parole vanno trasformate in operazioni, e l'errore quasi sempre sta nella traduzione.",
		"come": "Scrivi tre righe: che cosa so, che cosa cerco, che cosa lega le due. L'operazione compare da sola.",
	},

	# -- italiano ---------------------------------------------------------------
	"italiano:analisi-grammaticale": {
		"perche": "Riconoscere che parte del discorso è una parola serve a capire che cosa può fare nella frase, non a mettere etichette.",
		"come": "Prova a cambiarla: se puoi metterci davanti «il» o «la» è un nome, se puoi coniugarla è un verbo.",
	},
	"italiano:analisi-logica": {
		"perche": "Le domande «chi?», «che cosa?», «a chi?» servono a capire chi fa e chi subisce, che è il senso della frase.",
		"come": "Trova prima il verbo, poi chiedi al verbo chi lo compie: quello è il soggetto, sempre, anche se sta in fondo.",
	},
	"italiano:casa-famiglia": {
		"perche": "Sono le parole che si usano ogni giorno senza pensarci, e proprio per questo si scrivono male più spesso.",
		"come": "Se una parola di casa ti sembra strana scritta, prova a pensare a una parola della stessa famiglia più lunga.",
	},
	"italiano:cibo-spesa": {
		"perche": "Sono parole concrete, e le parole concrete si ricordano meglio se le leghi al gesto invece che alla definizione.",
		"come": "Associa la parola a quello che fai con quella cosa: si impara molto meglio di una definizione.",
	},
	"italiano:corpo-salute": {
		"perche": "Molte parole del corpo vengono dal latino o dal greco, e per questo tornano nei nomi delle malattie e degli strumenti.",
		"come": "Se riconosci la radice in una parola difficile, l'hai già mezza capita: «cardio» è cuore ovunque compaia.",
	},
	"italiano:digitale-media": {
		"perche": "Sono parole giovani, spesso prese dall'inglese: capire da dove vengono aiuta a non confonderle.",
		"come": "Chiediti se la parola descrive uno strumento, un'azione o un luogo: quasi tutte ricadono in queste tre.",
	},
	"italiano:emozioni-relazioni": {
		"perche": "Avere una parola precisa per un'emozione serve a distinguerla dalle altre: chi ha più parole sente in modo più preciso.",
		"come": "Chiediti se l'emozione è più forte o più debole di quella vicina: le sfumature stanno quasi sempre nell'intensità.",
	},
	"italiano:figure-retoriche": {
		"perche": "Servono a dire una cosa in modo che si veda, non a decorare: la metafora fa vedere, il paragone fa confrontare.",
		"come": "Se c'è «come» è una similitudine; se la cosa viene chiamata direttamente con un altro nome è una metafora.",
	},
	"italiano:lavoro-comunita": {
		"perche": "I nomi dei mestieri raccontano che cosa si fa: quasi tutti nascono dal verbo dell'azione.",
		"come": "Togli il suffisso e cerca il verbo: «panettiere» sta al pane come «giardiniere» al giardino.",
	},
	"italiano:lessico": {
		"perche": "Le parole non stanno da sole: sinonimi, contrari e famiglie sono la mappa che permette di sceglierne una precisa.",
		"come": "Quando cerchi una parola, prova prima il contrario di quella che non ti viene: spesso arriva più in fretta.",
	},
	"italiano:natura-ambiente": {
		"perche": "Molti nomi della natura descrivono una caratteristica, non sono etichette scelte a caso.",
		"come": "Se il nome ti sembra strano, cerca dentro un pezzo che conosci: spesso c'è un colore o una forma.",
	},
	"italiano:ortografia": {
		"perche": "Le regole di ortografia servono a far leggere a tutti lo stesso suono: senza, la stessa parola si leggerebbe in dieci modi.",
		"come": "Quando dubiti, cerca una parola della stessa famiglia dove il suono si sente meglio.",
	},
	"italiano:pensiero-linguaggio": {
		"perche": "Nominare bene una cosa serve a poterci ragionare sopra: senza la parola giusta il pensiero resta approssimativo.",
		"come": "Prima chiediti chi fa che cosa, poi scegli la parola: l'ordine inverso porta a frasi belle che non dicono niente.",
	},
	"italiano:punteggiatura": {
		"perche": "La punteggiatura serve a far sentire le pause al posto della voce, e cambia il senso: «andiamo a mangiare, nonna» non è «andiamo a mangiare nonna».",
		"come": "Rileggi ad alta voce: dove ti fermi a prendere fiato, quasi sempre ci va un segno.",
	},
	"italiano:scuola-studio": {
		"perche": "Sono le parole con cui si parla dell'imparare, e servono a dire con precisione che cosa non hai capito.",
		"come": "Lega ogni parola a un gesto che fai davvero a scuola: si ricorda molto meglio della definizione.",
	},
	"italiano:sintassi": {
		"perche": "L'ordine delle parole in italiano è libero ma non gratuito: quello che metti prima è quello a cui dài peso.",
		"come": "Individua il verbo principale: tutto il resto della frase gli gira intorno, comprese le subordinate.",
	},
	"italiano:sport-tempo-libero": {
		"perche": "Molte parole dello sport sono inglesi entrate in italiano, e questo spiega perché si scrivono in modo insolito.",
		"come": "Se la parola non segue le regole italiane, quasi sempre viene da un'altra lingua: cercala lì.",
	},
	"italiano:tempo-meteo": {
		"perche": "Le parole del tempo distinguono cose che a occhio si somigliano: pioggia, acquazzone e pioviggine non sono la stessa cosa.",
		"come": "Chiediti quanto dura e quanto è forte: quasi tutte le parole del meteo si distinguono su questi due.",
	},
	"italiano:testo-narrativo": {
		"perche": "Chi racconta decide che cosa il lettore può sapere: cambiare narratore cambia la storia, non solo il tono.",
		"come": "Chiediti che cosa quel narratore poteva davvero vedere. Se sa cose che non poteva sapere, il punto di vista è un altro.",
	},
	"italiano:verbo": {
		"perche": "Il verbo porta il tempo e la persona: è l'unica parola della frase che dice quando è successo e chi lo ha fatto.",
		"come": "Per riconoscere il modo, prova a metterci davanti «io»: se non regge, non è un indicativo.",
	},
	"italiano:viaggi-luoghi": {
		"perche": "I nomi dei luoghi conservano la loro storia: molti dicono che cosa c'era lì prima.",
		"come": "Cerca nel nome un pezzo che riconosci — un santo, un fiume, una forma del terreno: quasi sempre c'è.",
	},

	# -- inglese ----------------------------------------------------------------
	"inglese:actions": {
		"perche": "I verbi d'azione inglesi sono corti e cambiano senso con la preposizione che segue: è lì che sta il significato.",
		"come": "Impara il verbo insieme alla sua preposizione, mai da solo: «look» da solo non vuol dire quasi niente.",
	},
	"inglese:body-health": {
		"perche": "Molte parole del corpo inglesi vengono dalle stesse radici delle nostre, ma quelle di uso quotidiano no: sono germaniche e vanno imparate a parte.",
		"come": "Se la parola somiglia all'italiano è quasi sempre quella medica; se è corta e strana è quella di tutti i giorni.",
	},
	"inglese:connectors": {
		"perche": "I connettivi dicono che rapporto c'è fra due frasi: cambiarli cambia il ragionamento, non lo stile.",
		"come": "Chiediti se le due frasi si sommano, si oppongono o una spiega l'altra: il connettivo esce da lì.",
	},
	"inglese:data-science": {
		"perche": "È il lessico che si trova nei grafici e nei testi scientifici, e ricompare uguale in ogni materia.",
		"come": "Molte di queste parole sono latine passate dall'inglese: se somiglia all'italiano, fidati.",
	},
	"inglese:digital-media": {
		"perche": "Sono parole che usi già in italiano senza tradurle, quindi qui il lavoro è ricordarne il senso originale.",
		"come": "Chiediti che cosa vuol dire la parola in inglese normale: «stream» è un ruscello, e spiega perché si chiama così.",
	},
	"inglese:everyday-phrases": {
		"perche": "Le frasi fatte non si costruiscono parola per parola: «take a photo» non si traduce con «prendere».",
		"come": "Impara il blocco intero, verbo compreso. Se provi a costruirlo dall'italiano sbagli il verbo quasi sempre.",
	},
	"inglese:false-friends": {
		"perche": "Sono parole che somigliano alle nostre e vogliono dire altro, e proprio la somiglianza le rende pericolose.",
		"come": "Se una parola inglese sembra troppo facile, fermati: i falsi amici si travestono da parole che sai già.",
	},
	"inglese:feelings-opinions": {
		"perche": "Per dire un'opinione l'inglese usa formule fisse, e sbagliarle suona brusco anche quando le parole sono giuste.",
		"come": "Ricorda che l'inglese ammorbidisce con «I think» e «maybe» dove noi cambieremmo solo il tono.",
	},
	"inglese:food-shopping": {
		"perche": "Con il cibo l'inglese distingue quello che si conta da quello che non si conta, e cambia la parola davanti.",
		"come": "Chiediti se puoi dire «due»: se sì è «many», se no è «much». È la stessa regola per tutto.",
	},
	"inglese:home-family": {
		"perche": "L'inglese ha meno parole di parentela dell'italiano e le specifica con un aggettivo.",
		"come": "Quando manca la parola precisa, l'inglese la costruisce: «grand-», «step-», «-in-law» funzionano come pezzi.",
	},
	"inglese:jobs-community": {
		"perche": "Quasi tutti i nomi di mestiere inglesi sono il verbo più «-er»: è una regola, non un elenco.",
		"come": "Trova il verbo dentro il nome: «teacher» è chi fa «teach», e vale per la maggior parte degli altri.",
	},
	"inglese:leisure-culture": {
		"perche": "Sono le parole con cui si parla di quello che piace fare, e servono più di molte altre in una conversazione vera.",
		"come": "Legale al verbo che le regge: «play» per gli sport con la palla, «go» per quelli che finiscono in -ing.",
	},
	"inglese:nature-environment": {
		"perche": "Il lessico ambientale è quasi tutto internazionale, e riconoscerlo apre anche i testi scientifici.",
		"come": "Se la parola compare uguale in italiano, è quasi sempre vera anche in inglese: sono termini presi dal latino.",
	},
	"inglese:objects": {
		"perche": "I nomi degli oggetti sono corti e antichi, e per questo somigliano poco all'italiano.",
		"come": "Legali a una stanza: ricordare «gli oggetti della cucina» funziona meglio di un elenco alfabetico.",
	},
	"inglese:safety": {
		"perche": "Sono le parole dei cartelli e delle istruzioni: si leggono di fretta e devono essere capite al primo colpo.",
		"come": "Impara prima i verbi all'imperativo: sui cartelli l'inglese usa quasi solo quelli.",
	},
	"inglese:school-communication": {
		"perche": "Sono le formule per chiedere aiuto e chiarimenti, cioè le più utili quando non capisci il resto.",
		"come": "Tieni pronte tre frasi: chiedere di ripetere, chiedere di rallentare, chiedere che cosa vuol dire una parola.",
	},
	"inglese:time-weather": {
		"perche": "L'inglese usa «it» come soggetto vuoto per il tempo atmosferico: «it rains» non ha un «esso» che piove.",
		"come": "Ricorda che le frasi sul tempo cominciano quasi sempre con «it is»: manca il soggetto e l'inglese lo inventa.",
	},
	"inglese:travel-places": {
		"perche": "Le preposizioni di luogo inglesi non corrispondono alle nostre: «in» e «at» dividono spazi che l'italiano non divide.",
		"come": "«At» è un punto, «in» è dentro qualcosa, «on» è sopra una superficie. Chiediti quale delle tre è il posto.",
	},

	# -- coding -----------------------------------------------------------------
	"coding:algoritmi": {
		"perche": "Un algoritmo è una sequenza che funziona anche se la esegue qualcun altro: per questo va scritto senza sottintesi.",
		"come": "Prova a eseguirlo tu, alla lettera, facendo solo quello che c'è scritto. Il passo che ti manca è il difetto.",
	},
	"coding:booleani": {
		"perche": "Vero e falso servono al programma per scegliere: senza una risposta a due valori non ci sarebbe nessuna decisione.",
		"come": "Traduci la condizione in una domanda a cui si risponde sì o no. Se non ci riesci, la condizione è ancora confusa.",
	},
	"coding:cicli": {
		"perche": "Il ciclo serve a non riscrivere cento volte la stessa istruzione: si scrive una volta e si dice quante volte ripeterla.",
		"come": "Chiediti se sai quante volte: se sì è un for, se dipende da una condizione è un while.",
	},
	"coding:condizioni": {
		"perche": "L'if è il punto in cui il programma smette di essere una lista e diventa una scelta.",
		"come": "Leggi il codice due volte: una immaginando che la condizione sia vera, una che sia falsa. Devono avere senso tutt'e due.",
	},
	"coding:funzioni": {
		"perche": "Una funzione dà un nome a un pezzo di lavoro, così puoi usarlo senza ricordarti come è fatto dentro.",
		"come": "Se stai per copiare e incollare del codice, quello è il momento in cui serve una funzione.",
	},
	"coding:input": {
		"perche": "L'input è il punto in cui il programma smette di sapere già tutto: da lì in poi deve reggere anche a risposte che non ti aspetti.",
		"come": "Quello che arriva da input è sempre testo: se ti serve un numero, va convertito prima di farci i conti.",
	},
	"coding:liste": {
		"perche": "La lista serve quando le cose sono tante e non sai quante: con variabili separate dovresti saperlo in anticipo.",
		"come": "Ricorda che si conta da zero: l'ultimo elemento ha indice «quanti sono, meno uno».",
	},
	"coding:operatori": {
		"perche": "Un solo uguale assegna, due uguali confrontano: sono due azioni diverse e la confusione fra loro è l'errore più comune che esista.",
		"come": "Leggi «=» come «diventa» e «==» come «è uguale a?». Se la frase non ha senso, hai sbagliato operatore.",
	},
	"coding:output": {
		"perche": "L'output è l'unico modo che hai di vedere che cosa sta pensando il programma mentre gira.",
		"come": "Quando non capisci un difetto, stampa i valori a metà strada: quasi sempre uno è diverso da come credevi.",
	},
	"coding:stile": {
		"perche": "Il codice si legge molte più volte di quante si scrive, e quasi sempre lo rilegge qualcuno che non ricorda perché l'ha scritto.",
		"come": "Dai ai nomi il significato della cosa, non del tipo: «prezzo» dice più di «numero2».",
	},
	"coding:stringhe": {
		"perche": "Una stringa è testo, non un numero: «5» + «3» dà «53» perché il programma sta accostando due scritte.",
		"come": "Guarda se ci sono le virgolette. Sono l'unica differenza fra un conto e un accostamento.",
	},
	"coding:tipi": {
		"perche": "Il tipo dice che cosa si può fare con quel valore: si possono sommare due numeri, non un numero e una data.",
		"come": "Chiediti che operazione avrebbe senso su quel valore: la risposta ti dice il tipo meglio di come è scritto.",
	},
	"coding:variabili": {
		"perche": "La variabile è un nome dato a un valore che può cambiare: serve a scrivere istruzioni prima di sapere i numeri.",
		"come": "Segui una variabile riga per riga scrivendo a lato quanto vale. È così che si trovano gli errori veri.",
	},

	# -- fisica -----------------------------------------------------------------
	"fisica:calore": {
		"perche": "Il calore è energia che passa da caldo a freddo, sempre in quella direzione: non è una sostanza che sta dentro le cose.",
		"come": "Chiediti se il passaggio avviene per contatto, per movimento di un fluido o a distanza: sono i tre modi, e non ce n'è un quarto.",
	},
	"fisica:energia": {
		"perche": "L'energia non si crea e non si distrugge, cambia forma: per questo trovarla significa sempre chiedersi da dove è arrivata.",
		"come": "Quando qualcosa si muove o si scalda, chiediti che cosa si è svuotato: da lì viene l'energia.",
	},
	"fisica:forze": {
		"perche": "Una forza non serve a tenere in moto una cosa, ma a cambiarne il moto: senza attrito un oggetto lanciato non si fermerebbe mai.",
		"come": "Disegna le frecce di tutte le forze. Se si annullano, la velocità resta com'è — anche se è zero.",
	},
	"fisica:materia": {
		"perche": "Gli stati della materia dipendono da quanto sono legate le particelle, non da che cosa sono fatte.",
		"come": "Chiediti se le particelle possono scorrere e se possono allontanarsi: due domande, tre stati.",
	},
	"fisica:metodo": {
		"perche": "Un esperimento vale solo se si può rifare: per questo si cambia una cosa per volta e si scrive tutto.",
		"come": "Prima di misurare, decidi che cosa ti aspetti. Un risultato che non poteva sorprenderti non era un esperimento.",
	},
	"fisica:misure": {
		"perche": "L'unità di misura non è un'aggiunta al numero: senza, il numero non dice niente. «Tre» non è una distanza.",
		"come": "Controlla che le unità dei due lati tornino: se moltiplichi metri per metri non puoi ottenere metri.",
	},
	"fisica:moto": {
		"perche": "La velocità mette insieme spazio e tempo, e serve proprio perché nessuno dei due da solo dice quanto vai forte.",
		"come": "A parità di strada, meno tempo vuol dire più veloce. Se cambiano tutt'e due, fai il rapporto.",
	},
	"fisica:onde-luce": {
		"perche": "Un'onda trasporta energia senza trasportare materia: il tappo sull'acqua sale e scende, non arriva a riva.",
		"come": "Guarda che cosa si sposta davvero. Se la cosa torna dov'era, si è mossa l'onda e non la materia.",
	},

	# -- musica -----------------------------------------------------------------
	"musica:dinamica": {
		"perche": "Il forte e il piano non sono decorazioni: sono il modo in cui la musica dice che cosa è importante in quel momento.",
		"come": "Ricorda che i segni sono relativi: un «piano» dopo un «fortissimo» è più forte di un «piano» da solo.",
	},
	"musica:intervalli": {
		"perche": "L'intervallo è la distanza fra due note, ed è quello che rende una melodia riconoscibile anche cantata più in alto.",
		"come": "Conta le note comprese, prima e ultima incluse: da do a sol sono cinque note, quindi una quinta.",
	},
	"musica:lettura": {
		"perche": "Il pentagramma serve a scrivere l'altezza: più in alto sul rigo, più acuta la nota. È una mappa, non un codice.",
		"come": "Trova prima la chiave: dice quale nota sta su quale riga, e senza quella tutto il resto non si può leggere.",
	},
	"musica:note": {
		"perche": "I nomi delle note vengono dalle prime sillabe di un inno latino: non sono simboli inventati a caso.",
		"come": "Le note si ripetono ogni sette: quando arrivi a si, ricominci da do più in alto.",
	},
	"musica:ritmo": {
		"perche": "Il ritmo è la durata, non l'altezza: due brani con le stesse note ma ritmi diversi sono due brani diversi.",
		"come": "Somma le durate della battuta e controlla che facciano quello che dice il numero in alto: se non torna, manca qualcosa.",
	},
	"musica:strumenti": {
		"perche": "Gli strumenti si raggruppano per come producono il suono, non per come sono fatti: è la vibrazione che li classifica.",
		"come": "Chiediti che cosa vibra: una corda, una colonna d'aria o una pelle tesa. Il gruppo esce da lì.",
	},
	"musica:tempo": {
		"perche": "L'indicazione di tempo dice quanti battiti stanno in una battuta e che figura vale un battito: è la griglia su cui tutto si appoggia.",
		"come": "Il numero sopra conta i battiti, quello sotto dice quale nota ne vale uno. Sono due informazioni, non una frazione.",
	},
	"musica:timbro": {
		"perche": "Il timbro è quello che ti fa riconoscere chi sta suonando anche quando la nota è identica.",
		"come": "Se due suoni hanno la stessa altezza ma li distingui lo stesso, quello che stai sentendo è il timbro.",
	},

	# -- latino -----------------------------------------------------------------
	"latino:basi": {
		"perche": "Il latino non serve solo a leggere i romani: metà delle parole italiane ne viene, e capirlo spiega l'italiano.",
		"come": "Quando incontri una parola latina, cerca l'italiana che le somiglia: quasi sempre esiste ed è imparentata.",
	},
	"latino:casi": {
		"perche": "In latino è la desinenza a dire il ruolo nella frase, non la posizione: per questo l'ordine delle parole può cambiare senza cambiare il senso.",
		"come": "Guarda la fine della parola prima del suo posto nella frase. È lì che il latino scrive chi fa e chi subisce.",
	},
	"latino:declinazione-2m": {
		"perche": "La seconda declinazione raccoglie i nomi maschili in -us: sono tantissimi, e riconoscerne lo schema ne apre centinaia insieme.",
		"come": "Se il nominativo finisce in -us e il genitivo in -i, tutto il resto dello schema segue senza sorprese.",
	},
	"latino:declinazione-3m": {
		"perche": "La terza è la più irregolare perché è la più antica: i nomi ci sono arrivati consumati dall'uso.",
		"come": "Non fidarti del nominativo: nella terza è il genitivo a mostrare la vera radice della parola.",
	},
	"latino:declinazione-3n": {
		"perche": "I neutri hanno nominativo e accusativo uguali, e questo dice una cosa vera: chi non agisce, in latino, non si distingue da chi subisce.",
		"come": "Se trovi la stessa forma per soggetto e oggetto, è un neutro: il contesto ti dirà quale dei due.",
	},
	"latino:declinazione-4": {
		"perche": "La quarta è piccola ma contiene parole d'uso costante come «manus» e «domus»: si incontra più di quanto la sua grandezza faccia pensare.",
		"come": "Il genitivo in -us la distingue dalla seconda, che ha la stessa uscita al nominativo.",
	},
	"latino:declinazioni-base": {
		"perche": "Le declinazioni sono cinque schemi, non cinque elenchi: imparato lo schema, ogni parola nuova ci si incastra dentro.",
		"come": "Del nome impara sempre due forme, nominativo e genitivo: da quelle due si ricava tutto il resto.",
	},
	"latino:etimologia": {
		"perche": "Sapere da dove viene una parola serve a ricordarla e a capirne di nuove: la radice torna in decine di parole diverse.",
		"come": "Quando trovi una parola italiana difficile, cerca la radice latina dentro: spesso la spiega tutta.",
	},
	"latino:frasi": {
		"perche": "Le frasi latine famose sono sopravvissute perché dicono in tre parole quello che a noi ne servono venti.",
		"come": "Traduci parola per parola e poi rileggi: quasi sempre il senso è più largo della somma delle parole.",
	},
	"latino:verbo-sum": {
		"perche": "«Sum» è irregolare perché è il verbo più usato di tutti: le parole usate ogni giorno si consumano e perdono la regolarità.",
		"come": "Vale la pena impararlo a memoria: essendo irregolare non ci sono regole da applicare, e torna continuamente.",
	},
	"latino:vocabolario": {
		"perche": "Ogni parola latina che impari è anche una chiave per parole italiane che non hai ancora incontrato.",
		"come": "Impara la parola insieme a un derivato italiano: si fissa in due punti invece che in uno.",
	},

	# -- elettronica ------------------------------------------------------------
	"elettronica:circuito": {
		"perche": "La corrente ha bisogno di un percorso chiuso: se il giro si interrompe in un punto qualsiasi, non passa da nessuna parte.",
		"come": "Segui il filo col dito dalla pila e torna alla pila. Se non ci riesci, il circuito è aperto.",
	},
	"elettronica:componenti": {
		"perche": "Ogni componente fa una cosa sola: sapere che cosa fa conta più di sapere come si chiama.",
		"come": "Chiediti che cosa succede alla corrente quando ci passa: se la frena, la blocca, la accumula o la trasforma.",
	},
	"elettronica:conduttori": {
		"perche": "Conducono i materiali che hanno elettroni liberi di muoversi: per questo i metalli sì e la plastica no.",
		"come": "Se un materiale conduce anche il calore, quasi sempre conduce anche la corrente: è la stessa libertà di movimento.",
	},
	"elettronica:elettricita-base": {
		"perche": "Tensione e corrente sono cose diverse: la tensione è la spinta, la corrente è quanto passa. Una può esserci senza l'altra.",
		"come": "Pensa all'acqua: la tensione è il dislivello, la corrente è quanta acqua scorre. Il dislivello c'è anche a rubinetto chiuso.",
	},
	"elettronica:guasti": {
		"perche": "Un guasto si trova dividendo il circuito a metà, non guardandolo tutto insieme: così ogni prova dimezza il lavoro.",
		"come": "Misura a metà strada. Se lì il segnale c'è, il difetto è dopo; se non c'è, è prima.",
	},
	"elettronica:misure-elettriche": {
		"perche": "Lo strumento va inserito in modo diverso a seconda di che cosa misuri, e sbagliarlo può romperlo.",
		"come": "La tensione si misura fra due punti, la corrente si misura facendola passare dentro. È la differenza fra affiancare e interrompere.",
	},
	"elettronica:serie-parallelo": {
		"perche": "In serie la corrente ha una strada sola, quindi se salta una lampadina si spengono tutte; in parallelo ogni ramo è indipendente.",
		"come": "Conta le strade che la corrente può prendere. Una sola è serie, più di una è parallelo.",
	},
	"elettronica:sicurezza-elettrica": {
		"perche": "È la corrente che attraversa il corpo a fare male, non la tensione da sola: per questo l'acqua e i piedi scalzi cambiano tutto.",
		"come": "Prima di toccare, chiediti se il corpo potrebbe chiudere un giro verso terra. Se sì, non toccare.",
	},

	# -- geografia --------------------------------------------------------------
	"geografia:capitali": {
		"perche": "Le capitali quasi mai sono al centro geografico: stanno dove passavano i commerci, i fiumi o il potere.",
		"come": "Lega la capitale a un fiume o a una costa: quasi tutte sono nate lì, e il nome resta attaccato al posto.",
	},
	"geografia:climi": {
		"perche": "Il clima dipende da quanta luce solare arriva e da quanto è vicino il mare: sono due cause, e spiegano quasi tutte le fasce.",
		"come": "Guarda la latitudine e poi la distanza dal mare. Con quelle due il clima si indovina quasi sempre.",
	},
	"geografia:continenti": {
		"perche": "I continenti non sono divisioni naturali perfette: sono anche una convenzione storica, ed è per questo che Europa e Asia si toccano.",
		"come": "Ricorda che i confini fra Europa e Asia sono decisi dagli uomini, non dal mare: sono l'eccezione.",
	},
	"geografia:europa": {
		"perche": "L'Europa è piccola ma frastagliata, e questo spiega perché ha tanti stati: le montagne e i mari hanno separato i popoli.",
		"come": "Guarda dove ci sono catene montuose e mari: quasi sempre lì passa anche un confine.",
	},
	"geografia:geografia-fisica": {
		"perche": "Le linee immaginarie servono a dare un indirizzo a ogni punto della Terra: senza, non si potrebbe dire dove si è.",
		"come": "La latitudine sale e scende dall'Equatore, la longitudine gira intorno. Prima quanto su o giù, poi quanto a lato.",
	},
	"geografia:geografia-italia": {
		"perche": "La forma dell'Italia decide quasi tutto il resto: lunga e stretta, con il mare vicino ovunque e le montagne in mezzo.",
		"come": "Quando non ricordi una regione, parti dal mare che la bagna e dalla catena che la attraversa.",
	},
	"geografia:geografia-umana": {
		"perche": "La gente si concentra dove c'è acqua e terra coltivabile: le mappe della popolazione somigliano alle mappe dei fiumi.",
		"come": "Se una zona è vuota, chiediti che cosa manca: quasi sempre è acqua, terra buona o un clima vivibile.",
	},
	"geografia:mondo": {
		"perche": "Le grandi catene e i grandi fiumi non sono curiosità: hanno deciso dove sono nate le città e dove passano i confini.",
		"come": "Prima di imparare un nome, guarda dove sta sulla mappa: la posizione lo tiene a mente molto meglio.",
	},

	# -- scienze ----------------------------------------------------------------
	"scienze:ambiente": {
		"perche": "In un ambiente tutto è collegato: togliere una specie sposta le altre, anche quelle che sembravano non c'entrare.",
		"come": "Segui chi mangia chi. Quasi tutti gli effetti a sorpresa si spiegano seguendo quella catena.",
	},
	"scienze:corpo": {
		"perche": "Gli organi si capiscono per la funzione, non per la forma: il cuore è una pompa, i polmoni uno scambio.",
		"come": "Chiediti che cosa entra e che cosa esce da quell'organo: la funzione viene fuori da sola.",
	},
	"scienze:ecosistema": {
		"perche": "L'energia entra sempre dal sole ed esce come calore: per questo i predatori sono pochi e le piante tante.",
		"come": "Sali la catena e conta: a ogni passaggio si perde quasi tutto, quindi in cima ci sta poca roba.",
	},
	"scienze:energia": {
		"perche": "L'energia si trasforma e non si consuma: quando diciamo «consumata» vuol dire che è diventata calore disperso.",
		"come": "Cerca sempre dove è finita: se una cosa si scalda o fa rumore, l'energia è passata lì.",
	},
	"scienze:materia": {
		"perche": "I passaggi di stato non cambiano la sostanza: l'acqua ghiacciata è ancora acqua, sono cambiati i legami.",
		"come": "Chiediti se serve dare o togliere calore: metà dei nomi dei passaggi si ricorda solo con quello.",
	},
	"scienze:metodo": {
		"perche": "Un'ipotesi vale solo se potrebbe risultare falsa: una che spiega qualunque risultato non spiega niente.",
		"come": "Prima dell'esperimento scrivi che cosa ti aspetti. Se non sai dirlo, non hai ancora un'ipotesi.",
	},
	"scienze:terra-universo": {
		"perche": "Il giorno e le stagioni vengono da due movimenti diversi: uno su sé stessa, uno attorno al Sole.",
		"come": "Chiediti se la cosa dura un giorno o un anno: dice subito quale dei due movimenti la causa.",
	},
	"scienze:viventi": {
		"perche": "I viventi si classificano per come si nutrono e come si riproducono, non per come appaiono.",
		"come": "Chiediti se si fabbrica il cibo da solo o se lo deve prendere: è la prima grande divisione.",
	},

	# -- storia -----------------------------------------------------------------
	"storia:civilta": {
		"perche": "Le grandi civiltà nascono quasi tutte lungo un fiume, e non è un caso: l'acqua permette l'agricoltura, e l'agricoltura permette le città.",
		"come": "Quando incontri una civiltà nuova, cerca prima il suo fiume: spiega dove stava e perché stava lì.",
	},
	"storia:cronologia": {
		"perche": "Contare i secoli serve a mettere in ordine cose lontane fra loro: senza un ordine, la storia è un elenco.",
		"come": "Il secolo è il numero delle centinaia più uno: il 1492 è il Quattrocento, cioè il quindicesimo secolo.",
	},
	"storia:egizi": {
		"perche": "L'Egitto è nato dalle piene del Nilo: senza quel limo sarebbe stato deserto, e non ci sarebbe stato niente.",
		"come": "Lega ogni cosa che studi al fiume: le stagioni, le tasse, il calendario e perfino la religione ne dipendevano.",
	},
	"storia:fonti": {
		"perche": "La storia si ricostruisce da quello che è rimasto, e quello che è rimasto non è mai tutto: per questo le fonti si confrontano.",
		"come": "Chiediti chi ha prodotto quella fonte e perché. Anche una bugia è una fonte, se sai chi l'ha detta.",
	},
	"storia:grecia": {
		"perche": "La Grecia è fatta di montagne e isole, e per questo ha avuto tante città-stato invece di un regno solo.",
		"come": "Quando un fatto greco ti sembra strano, guarda la geografia: quasi sempre la spiega.",
	},
	"storia:medioevo": {
		"perche": "Dopo la caduta di Roma il potere si è frantumato, e il castello è la risposta pratica a un mondo senza uno stato.",
		"come": "Chiediti chi proteggeva chi e in cambio di che cosa: quasi tutte le istituzioni medievali sono questo scambio.",
	},
	"storia:metodo": {
		"perche": "Lo storico non racconta quello che è successo: racconta quello che le fonti permettono di sostenere.",
		"come": "Distingui sempre il fatto dall'interpretazione. Se una frase dice «perché», quasi sempre è interpretazione.",
	},
	"storia:preistoria": {
		"perche": "Si chiama preistoria perché mancano le scritture: sappiamo di quel periodo solo quello che gli oggetti raccontano.",
		"come": "Guarda gli strumenti: il materiale con cui sono fatti dà il nome all'epoca e dice che cosa sapevano fare.",
	},
	"storia:roma": {
		"perche": "Roma è durata tanto perché ha assorbito i popoli che conquistava invece di cancellarli.",
		"come": "Segui le strade: dove arrivavano le strade romane arrivavano la lingua, le leggi e le città.",
	},

	# -- logica -----------------------------------------------------------------
	"logica:analogie": {
		"perche": "Un'analogia si risolve trovando il rapporto fra le prime due, non cercando la parola che somiglia di più.",
		"come": "Dì ad alta voce che rapporto c'è nella prima coppia, poi applica quella stessa frase alla seconda.",
	},
	"logica:deduzioni": {
		"perche": "Da premesse vere segue una conclusione vera: la deduzione non aggiunge informazioni, le tira fuori.",
		"come": "Controlla se la conclusione dice più di quanto dicevano le premesse. Se sì, non è una deduzione.",
	},
	"logica:esclusioni": {
		"perche": "Escludere è un modo di sapere: quando le possibilità sono poche, eliminare le sbagliate equivale a trovare quella giusta.",
		"come": "Segna quelle che hai escluso e il motivo. Se il motivo non lo sai dire, non l'hai davvero esclusa.",
	},
	"logica:insiemi": {
		"perche": "Gli insiemi servono a ragionare su gruppi senza elencarli: si può dire qualcosa di «tutti i quadrati» senza vederli tutti.",
		"come": "Disegna due cerchi. Quello che sta nella sovrapposizione ha tutte e due le proprietà, e quasi ogni errore sta lì.",
	},
	"logica:quantificatori": {
		"perche": "«Tutti» e «qualcuno» cambiano completamente che cosa serve per smentire una frase: per «tutti» basta un caso solo.",
		"come": "Per smentire un «tutti» cerca un controesempio; per smentire un «qualcuno» devi controllarli tutti.",
	},
	"logica:sequenze": {
		"perche": "Una sequenza si continua solo se hai trovato la regola: indovinare il prossimo numero senza regola non è averla capita.",
		"come": "Calcola le differenze fra numeri vicini. Se non sono costanti, guarda se sono i rapporti a esserlo.",
	},
	"logica:verita": {
		"perche": "Una frase è vera o falsa indipendentemente da chi la dice: è questa la differenza fra un ragionamento e una discussione.",
		"come": "Cerca il caso che renderebbe falsa la frase. Se non esiste, la frase è vera; se esiste, hai finito.",
	},
}

## La voce di un argomento, vuota se non c'è.
static func voce(subject: String, topic: String) -> Dictionary:
	return VOCI.get("%s:%s" % [subject, topic], {})

## Il testo contiene già un nesso causale?
##
## È la stessa domanda che si fa `bank_explanation_audit`, e sta qui perché la
## misura e il contenuto non possano scollarsi: se un giorno cambiano i segni,
## cambiano per tutt'e due.
static func ha_causa(testo: String) -> bool:
	var basso := testo.to_lower()
	for segno in SEGNI_DI_CAUSA:
		if basso.contains(str(segno)):
			return true
	return false

## **Che cosa dice NORA dopo una prova**, indovinata o sbagliata.
##
## L'item porta il caso particolare; NORA aggiunge la ragione generale — e la
## aggiunge **solo se l'item non ce l'ha già**, altrimenti direbbe due volte la
## stessa cosa e il bambino imparerebbe a saltarla.
##
## Sbagliando arriva il `come` invece del `perche`: chi ha appena sbagliato ha
## bisogno di sapere come rifarlo, non di una ragione generale. È la convinzione
## di NORA applicata al momento in cui conta — la risposta non si presta, il
## metodo sì.
static func riga(subject: String, topic: String, spiegazione: String, corretto: bool) -> String:
	var testo := spiegazione.strip_edges()
	var v := voce(subject, topic)
	if v.is_empty():
		return testo
	var aggiunta := str(v.get("perche", "")) if corretto else str(v.get("come", ""))
	if aggiunta.is_empty():
		return testo
	if corretto and ha_causa(testo):
		return testo
	if testo.is_empty():
		return aggiunta
	return "%s\n%s" % [testo, aggiunta]

## Tutti gli argomenti coperti. Serve all'audit della copertura.
static func argomenti() -> Array:
	var elenco := VOCI.keys()
	elenco.sort()
	return elenco
