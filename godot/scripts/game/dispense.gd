class_name Dispense
extends RefCounted

## **La dispensa: il documento che si legge PRIMA della domanda.**
## (11 settembre 2026 — regola di progetto, vedi `docs/REGOLA_DISPENSE.md`)
##
## Richiesta del committente: «le prove devono essere applicazioni che lo
## studente deve fare di concetti spiegati. Non presumere che debba sapere
## concetti che nessuno gli ha spiegato. La spiegazione di poche frasi di NORA
## non è sufficiente.»
##
## ### La misura che dà ragione alla segnalazione
##
## Costruendo per tutti i **300 argomenti** del runtime la scheda che NORA
## mostrerebbe, e contando i soli caratteri con cui NORA *spiega* — introduzione
## più metodo, senza il testo dell'esempio, che è un item del banco:
##
##     tutte le materie   300 argomenti   media 290 caratteri
##     matematica          40 argomenti   media 191
##     coding              29 argomenti   media 276
##     latino              16 argomenti   media 352 (il massimo)
##
## Duecentonovanta caratteri sono quarantacinque parole. Possono **ricordare** un
## concetto a chi lo ha già studiato; non possono **insegnarlo** a chi lo incontra
## per la prima volta — e quella scheda è l'unico posto in cui questo gioco
## presenta un concetto per la prima volta.
##
## ### Che cos'è una dispensa, e in che cosa differisce dai tre strati esistenti
##
##   `NoraExplanations`   il *perché* dell'argomento, due frasi. Resta: è il
##                        richiamo breve per chi la dispensa l'ha già letta.
##   `KnowledgeCodex`     assembla la scheda dal banco. Resta: è la forma che
##                        `ExercisePlayer` sa disegnare, e una dispensa la riempie.
##   `TavoleRiferimento`  la linea del tempo e la carta su cui un NOME si impara.
##                        Resta: è la figura del documento, non il documento.
##
## La dispensa è il **testo**: due o più sezioni con il loro sottotitolo, il
## vocabolario dei termini che le domande useranno, almeno due esempi svolti, il
## metodo, l'errore tipico. Minimo milleduecento caratteri di sole sezioni —
## quattro volte la scheda di oggi, ed è la lunghezza sotto la quale non ci stanno
## insieme un contesto e un esempio.
##
## ### Il patto con il banco, ed è ciò che l'audit verifica
##
## Un item scrive `applica: "<id>"`. Non è ridondanza: è il legame **verificabile**
## fra ciò che si insegna e ciò che si chiede — la stessa forma del campo
## `risposte` delle tavole. Chi scrive una domanda deve poter indicare il
## paragrafo che la rende rispondibile; se non ci riesce, va scritta prima la
## dispensa. Vedi `dispense_audit.gd`.
##
## **Quando la risposta non è un fatto ma il risultato di una regola.** Nelle
## materie di richiamo l'audit pretende che la risposta compaia nel testo della
## dispensa — se il documento non dice «Romolo», chiedere chi fondò Roma è
## impossibile. Ma «a quale secolo appartiene il 1215?» ha infinite risposte
## possibili e una regola sola, e elencarle tutte sarebbe assurdo. Per questi casi
## la dispensa dichiara `regole`, espressioni regolari: una risposta che ne
## soddisfa una è considerata insegnata dalla regola invece che dal testo.
##
## Non è un'invenzione di questo file: `TavoleRiferimento` aveva già lo stesso
## campo per la stessa ragione, e una delle sue voci porta già l'espressione dei
## secoli. Stesso problema, stessa forma.
##
## E `insegna` porta il patto un passo più in là: elenca le **notazioni esatte**
## che quella dispensa autorizza. Una domanda di coding che mostra `range(` senza
## che nessuna dispensa fino a quella fascia lo abbia introdotto è, letteralmente,
## una domanda che il bambino non può capire. L'audit la trova.

# --- I minimi, e perché sono questi -------------------------------------------

## Milleduecento caratteri di sole sezioni. Vedi il commento in testa: è la
## lunghezza sotto la quale un contesto e un esempio non ci stanno insieme.
const MINIMO_SEZIONI := 1200
## Due voci di glossario. Una sola non è un vocabolario, è una definizione.
const MINIMO_GLOSSARIO := 2
## Due esempi svolti. Con uno solo il bambino impara il caso, non il metodo.
const MINIMO_ESEMPI := 2
## Il metodo sotto i sessanta caratteri è uno slogan, non una procedura.
const MINIMO_METODO := 60

## Le famiglie di fasce. Una dispensa ne copre una: sotto, il primo incontro;
## sopra, l'uso composto. Spezzare in otto avrebbe prodotto otto documenti che si
## ripetono; tenerne uno solo avrebbe messo i cicli annidati davanti a chi non ha
## ancora visto un ciclo.
const BANDA_BASE := [1, 4]
const BANDA_ALTA := [5, 8]

## **Una dispensa sola per tutte e otto le fasce.** (11 settembre 2026, con latino)
##
## L'eccezione vale quando il contenuto è una TABELLA e non un percorso: le sei
## caselle di una declinazione latina si imparano insieme o non si imparano, e
## spezzarle in due bande produrrebbe due documenti che si ripetono mezzi a
## vicenda. È lo stesso criterio per cui `medioevo` ha una banda sola — lì perché
## il banco non interroga le fasce basse, qui perché il materiale non si divide.
const BANDA_INTERA := [1, 8]


# --- Le dispense ---------------------------------------------------------------
#
# **Coding è la prima materia convertita.** (11 settembre 2026) Tredici argomenti
# nel banco, due bande ciascuno: ventisei documenti, e nessun item di coding
# resta scoperto. Le altre undici materie stanno nel registro del debito di
# `dispense_audit.gd`, con un tetto che si abbassa e non si alza mai.

const DISPENSE := {

# ============================================================ VARIABILI · base
"coding-variabili-base": {
	"subject": "coding", "topic": "variabili", "fasce": BANDA_BASE,
	"titolo": "La scatola con un nome, e il segno che ci mette dentro",
	"apertura": "Nel Relitto ogni pannello tiene i suoi numeri in caselle con un'etichetta sopra. In Python le caselle si chiamano variabili, e il segno = è l'ordine che ci mette qualcosa dentro.",
	"sezioni": [
		{"titolo": "Il segno = non è l'uguale della matematica",
		 "testo": "In matematica «x = 4» è un'affermazione: dice che x vale quattro, e resta vera. In Python è un ORDINE, e si esegue da destra verso sinistra: «calcola quello che c'è a destra, poi mettilo nella casella che si chiama come quello che c'è a sinistra». Per questo in Python si può scrivere una riga che in matematica sarebbe falsa, come n = n + 1. E per questo la stessa casella può ricevere due ordini diversi: dopo x = 4 e poi x = 9, dentro x c'è nove. Non tredici: il secondo ordine non aggiunge niente al primo, lo SOSTITUISCE. Una variabile ricorda soltanto l'ultimo valore ricevuto, e quello di prima sparisce senza lasciare traccia."},
		{"titolo": "Un nome a destra vale il suo contenuto",
		 "testo": "Quando il nome di una variabile compare a destra dell'uguale, Python prima va a vedere che cosa contiene in quel momento, e poi calcola. Con x = 5 e y = x + 2, sulla seconda riga Python legge x, trova cinque, somma due, e mette sette dentro y. Da quel momento y vale sette e ci resta anche se x cambia: y ha ricevuto una copia del risultato, non un collegamento a x. Questa è la regola che fa funzionare il contatore, la riga più usata di tutta la programmazione: con n = 3 e poi n = n + 1, la parte destra viene calcolata con il valore VECCHIO — tre più uno fa quattro — e solo dopo il quattro viene riscritto dentro n. Questa riga è così frequente che esiste una forma corta: n += 1 significa esattamente n = n + 1, cioè leggi, aggiungi, riscrivi nella stessa casella. Allo stesso modo -= toglie e *= moltiplica. L'unica cosa da ricordare è che la casella deve già esistere, perché la prima delle tre mosse è leggerla."},
		{"titolo": "Il nome non è la cosa",
		 "testo": "Le virgolette fanno la differenza fra il nome della casella e quello che c'è dentro. Scrivendo print(nome) si stampa il contenuto; scrivendo print(\"nome\") si stampano le quattro lettere n-o-m-e, perché le virgolette dicono a Python «questo è testo, non andarlo a cercare da nessuna parte». È lo stesso motivo per cui un'etichetta sul barattolo non si mangia."}],
	"glossario": [
		{"voce": "variabile", "spiega": "Un nome dato a un valore che può cambiare. Serve a scrivere istruzioni prima di sapere i numeri su cui gireranno."},
		{"voce": "=", "spiega": "Assegnazione: metti nella casella di sinistra il risultato di destra. Si legge «diventa», mai «è uguale a»."},
		{"voce": "n = n + 1", "spiega": "Il contatore: prendi il valore che c'è, aggiungine uno, rimettilo al suo posto. Avanzare di uno si scrive così."},
		{"voce": "+=", "spiega": "La forma corta del contatore: n += 1 è n = n + 1. Leggi, calcola, riscrivi nella stessa casella."}],
	"esempi": [
		{"prompt": "p = 2\np = 7\nprint(p)", "answer": "7",
		 "explanation": "Due ordini alla stessa casella: vince l'ultimo. Il due non è sommato né ricordato, è stato coperto."},
		{"prompt": "a = 6\nb = a + 4\na = 1\nprint(b)", "answer": "10",
		 "explanation": "b aveva già ricevuto dieci quando a valeva sei. Cambiare a dopo non torna indietro a correggere b: la copia era già stata fatta."}],
	"metodo": "Prendi un foglio, scrivi i nomi delle variabili in cima e scendi riga per riga cancellando il valore vecchio e scrivendo quello nuovo. Alla fine leggi la colonna che ti interessa: è sempre l'ultimo numero scritto.",
	"errore": {"wrong": "Dopo x = 4 e x = 9, rispondere 13.",
		"why": "Somma i due ordini invece di eseguirli in fila. Il secondo uguale non aggiunge: riscrive la casella da capo."},
	"insegna": ["=", "print(", "+", "-", "*", "+=", "-=", "*="]},

# ============================================================ VARIABILI · alta
"coding-variabili-alta": {
	"subject": "coding", "topic": "variabili", "fasce": BANDA_ALTA,
	"titolo": "Scambiare, accumulare, e due nomi sulla stessa cosa",
	"apertura": "Tre mosse che si scrivono in una riga sola e che in una riga sola si sbagliano: lo scambio, l'accumulo e il nome condiviso.",
	"sezioni": [
		{"titolo": "Lo scambio in una riga, e perché quella con tre righe ne vuole tre",
		 "testo": "Per scambiare il contenuto di due caselle con il metodo lungo servono TRE righe e una casella d'appoggio: t = a, poi a = b, poi b = t. Chi ne scrive due — a = b e poi b = a — perde un valore per sempre: sulla prima riga a ha già smesso di contenere il suo vecchio numero, quindi la seconda riga rimette in b quello che b aveva già. Python offre la scorciatoia a, b = b, a: la parte destra viene calcolata TUTTA prima che venga scritto qualcosa a sinistra, quindi le due copie partono dai valori vecchi e nessuna delle due sovrascrive l'altra. È l'unico posto in cui l'ordine delle scritture non conta, e conta proprio perché le scritture avvengono dopo."},
		{"titolo": "Gli operatori composti: leggere, calcolare, riscrivere",
		 "testo": "La riga totale = totale + 5 compare talmente spesso che esiste una forma corta: totale += 5. Sono la stessa cosa, lettera per lettera: leggi il valore, aggiungi, riscrivilo nella stessa casella. Funzionano allo stesso modo -= che toglie, *= che moltiplica, //= che divide tenendo l'intero. Attenzione a una cosa sola: la casella deve già esistere e contenere qualcosa, perché la prima operazione è LEGGERE. Un += su una variabile mai assegnata non parte da zero: non parte."},
		{"titolo": "Il nome è un'etichetta, e le etichette si possono attaccare in due",
		 "testo": "Con un numero non si vede la differenza, perché i numeri non si modificano: si sostituiscono. Con una lista sì. Dopo b = a, i due nomi sono due etichette attaccate alla STESSA lista, e un a.append(7) si vede anche leggendo b — è la stessa scatola guardata da due porte. Per avere davvero due liste separate si scrive b = list(a), che ne costruisce una copia nuova."}],
	"glossario": [
		{"voce": "a, b = b, a", "spiega": "Scambio simultaneo: la destra si calcola per intero prima che la sinistra venga scritta."},
		{"voce": "+=", "spiega": "Leggi, aggiungi, riscrivi nella stessa casella. Forma corta di casella = casella + qualcosa."},
		{"voce": "list(a)", "spiega": "Costruisce una lista nuova con gli stessi elementi. Serve quando NON si vuole la stessa scatola con due nomi."}],
	"esempi": [
		{"prompt": "a = 2\nb = 9\na, b = b, a\nprint(a)", "answer": "9",
		 "explanation": "La destra vale (9, 2) prima che si scriva qualsiasi cosa a sinistra: nessuno dei due valori vecchi è andato perso."},
		{"prompt": "t = 10\nt += 4\nt -= 6\nprint(t)", "answer": "8",
		 "explanation": "Dieci più quattro fa quattordici, meno sei fa otto. Ogni riga riparte dal valore che la riga prima ha lasciato."}],
	"metodo": "Quando vedi una riga composta, riscrivila per esteso a fianco: += diventa «casella = casella + ...». Se la forma lunga ti torna, torna anche la corta, e diventa impossibile sbagliarla.",
	"errore": {"wrong": "Scambiare due variabili con a = b seguito da b = a.",
		"why": "La prima riga cancella il vecchio valore di a: alla seconda riga non esiste più niente da rimettere in b, e le due caselle finiscono uguali."},
	"insegna": ["+=", "-=", "*=", "a, b = b, a", "list("]},

# ============================================================== TIPI · base
"coding-tipi-base": {
	"subject": "coding", "topic": "tipi", "fasce": BANDA_BASE,
	"titolo": "Numeri, testo, e le virgolette che decidono chi è chi",
	"apertura": "Un valore in Python non è mai solo un valore: è un valore DI UN TIPO, e il tipo decide che cosa si può farci.",
	"sezioni": [
		{"titolo": "Le virgolette non sono decorazione",
		 "testo": "Scrivere 12 e scrivere \"12\" produce due cose diverse. Il primo è un numero intero, un int: ci si possono fare i conti. Il secondo è testo, una stringa, uno str: sono due caratteri messi in fila, e il fatto che assomiglino a un numero non li rende un numero, esattamente come la fotografia di una mela non si mangia. Gli apici singoli fanno lo stesso lavoro dei doppi: '12' è testo quanto \"12\". La prova sta nel segno più: fra due numeri somma, fra due testi UNISCE. Per questo 2 + 3 dà 5 mentre \"2\" + \"3\" dà \"23\": nel secondo caso Python non ha mai visto due quantità, ha visto due scritte e le ha accostate."},
		{"titolo": "I tre tipi che servono da subito",
		 "testo": "int è il numero intero: 7, 0, -12. float è il numero con la virgola, che in Python si scrive con il punto: 3.5, 2.0. Attenzione: 2.0 è un float anche se il suo valore è intero, perché il punto l'ha dichiarato tale. str è il testo. C'è un quarto tipo, bool, che ha due soli valori — True e False — e ha la sua dispensa. La funzione type(qualcosa) risponde dicendo di che tipo è: serve quando un programma si comporta in un modo che non ci si aspetta, e quasi sempre la risposta spiega il difetto."},
		{"titolo": "Convertire, quando serve",
		 "testo": "int(\"12\") legge il testo e ne costruisce il numero dodici; str(12) fa il viaggio contrario e ne costruisce la scritta. Servono nei punti in cui due mondi si toccano — soprattutto dopo input(), che consegna sempre testo. Una conversione fallisce se il testo non descrive un numero: int(\"dodici\") non ha senso e Python si ferma. int(3.9) invece funziona e dà 3, perché TAGLIA la parte decimale invece di arrotondare."}],
	"glossario": [
		{"voce": "int / float / str", "spiega": "Numero intero, numero con il punto decimale, testo. Il tipo decide quali operazioni hanno senso su quel valore."},
		{"voce": "type(x)", "spiega": "Risponde dicendo di che tipo è x. È il primo strumento da usare quando un programma fa una cosa inspiegabile."},
		{"voce": "int(\"12\")", "spiega": "Costruisce il numero a partire dal testo. Fallisce se il testo non descrive un numero."}],
	"esempi": [
		{"prompt": "print(\"4\" + \"1\")", "answer": "41",
		 "explanation": "Due stringhe: il più le accosta. Le virgolette avevano già deciso che quelle non erano quantità."},
		{"prompt": "print(int(\"4\") + 1)", "answer": "5",
		 "explanation": "int() trasforma il testo in numero prima della somma, e da lì in poi il più fa il suo mestiere di somma."}],
	"metodo": "Prima di leggere un'operazione, guarda se ci sono le virgolette attorno ai valori. Sono l'unica differenza fra un conto e un accostamento, e si vedono da lontano.",
	"errore": {"wrong": "Rispondere 5 a print(\"2\" + \"3\").",
		"why": "Legge i due valori come quantità, ma le virgolette li avevano resi testo: il più fra testi unisce, e il risultato è la scritta 23."},
	"insegna": ["int(", "str(", "float(", "type(", "'"]},

# ============================================================== TIPI · alta
"coding-tipi-alta": {
	"subject": "coding", "topic": "tipi", "fasce": BANDA_ALTA,
	"titolo": "Quando il tipo cambia da solo, e quando si rifiuta di farlo",
	"apertura": "Python a volte converte per conto suo e a volte si ferma. Le due regole che decidono quale delle due cose fa sono poche e non cambiano mai.",
	"sezioni": [
		{"titolo": "La divisione che promuove, e le due che non lo fanno",
		 "testo": "In Python 3 la barra singola restituisce SEMPRE un float, anche quando la divisione è esatta: 10 / 2 dà 5.0, non 5. È una scelta di progetto — il risultato di una divisione, in generale, ha la virgola, e cambiare tipo a seconda dei numeri renderebbe imprevedibile ogni programma. La doppia barra, 10 // 2, resta intera e dà 5, perché chiede un'altra cosa: quante volte ci sta dentro. Anche il resto, 10 % 3, resta intero. Quando in un conto compaiono un int e un float, il risultato è float: Python promuove al tipo più capiente, perché il contrario perderebbe informazione."},
		{"titolo": "Fra numero e testo non converte niente",
		 "testo": "Sommare un numero e una stringa non produce nessuna conversione automatica: Python si ferma e lo dice. Non è una scortesia, è l'unica risposta sensata — non c'è modo di indovinare se 3 + \"4\" debba dare 7 o \"34\", e una macchina che indovina al posto tuo è una macchina che sbaglia in silenzio. La conversione va chiesta: int(\"4\") + 3 fa sette, str(3) + \"4\" fa la scritta 34. La moltiplicazione fra stringa e intero invece è definita, e fa una cosa utile: \"ab\" * 3 ripete il testo tre volte e dà \"ababab\"."},
		{"titolo": "I float non sono precisi come sembrano",
		 "testo": "Un float è memorizzato in binario, e alcuni decimali che in dieci dita sono esatti in binario non lo sono: per questo 0.1 + 0.2 non dà esattamente 0.3. Non è un difetto di Python, capita in ogni linguaggio. La conseguenza pratica è una sola: due float non si confrontano con ==, si confronta la loro distanza. Per i soldi e per i conteggi si usano gli interi, che non hanno questo problema."}],
	"glossario": [
		{"voce": "/", "spiega": "Divisione: in Python 3 il risultato è sempre un float, anche quando la divisione è esatta."},
		{"voce": "promozione", "spiega": "In un conto misto int e float, il risultato è float: si sale al tipo più capiente per non perdere informazione."},
		{"voce": "\"ab\" * 3", "spiega": "Stringa per intero: ripete il testo. È l'unica operazione mista fra testo e numero che Python accetta."}],
	"esempi": [
		{"prompt": "print(8 / 4)", "answer": "2.0",
		 "explanation": "La barra singola dà sempre un float, anche su una divisione esatta: il tipo dipende dall'operatore, non dai numeri."},
		{"prompt": "print(type(3 + 2.0))", "answer": "float",
		 "explanation": "Un int e un float in un conto: Python promuove al tipo più capiente, perché tagliare la virgola perderebbe informazione."}],
	"metodo": "Guarda l'OPERATORE prima dei numeri: è lui a decidere il tipo del risultato. La barra singola dà float sempre, la doppia e il resto restano interi sempre.",
	"errore": {"wrong": "Rispondere 2 a print(8 / 4).",
		"why": "Il valore è giusto ma il tipo no: in Python 3 la barra singola restituisce un float, e il risultato si scrive 2.0."},
	"insegna": ["/", "//", "%", "* su stringa"]},

# =========================================================== OPERATORI · base
"coding-operatori-base": {
	"subject": "coding", "topic": "operatori", "fasce": BANDA_BASE,
	"titolo": "I due segni che dividono, e i due che si confondono",
	"apertura": "Dividere in Python si può fare in tre modi, e rispondono a tre domande diverse. Poi c'è la coppia di segni che causa più errori di ogni altra cosa: = e ==.",
	"sezioni": [
		{"titolo": "Tre divisioni, tre domande",
		 "testo": "7 / 2 dà 3.5 e risponde a «in quante parti uguali si divide». 7 // 2 dà 3 e risponde a «quante volte ci sta per intero»: è la domanda di chi distribuisce oggetti che non si possono spezzare, come sedie o biglietti. 7 % 2 dà 1 e risponde a «quanto avanza». Le ultime due lavorano insieme: se dividi sette caramelle fra due bambini, ognuno ne prende 7 // 2 = tre e ne resta 7 % 2 = una. Il resto è sempre più piccolo del divisore — se fosse uguale o più grande, ci starebbe dentro un'altra volta. Da qui viene il modo più corto di sapere se un numero è pari: n % 2 vale zero per i pari e uno per i dispari, sempre."},
		{"titolo": "Un uguale assegna, due confrontano",
		 "testo": "Il segno singolo = è un ordine: metti questo valore in quella casella. Il segno doppio == è una domanda: questi due valori sono lo stesso? La risposta di == non è un numero, è True oppure False. Il modo per non sbagliare è leggerli ad alta voce in due modi diversi: = si legge «diventa», == si legge «è uguale a?». La frase «x diventa 5» ha senso come ordine; la frase «x è uguale a 5?» ha senso come domanda. Se metti la lettura sbagliata nel posto sbagliato, la frase suona storta, e quello è il segnale."},
		{"titolo": "Gli altri cinque segni che fanno una domanda",
		 "testo": "Insieme a == ce ne sono altri cinque, e rispondono tutti True o False: != chiede «sono diversi?», < chiede «è più piccolo?», > «è più grande?». Poi ci sono i due che comprendono anche il caso dell'uguaglianza: <= si legge «minore o uguale» e >= «maggiore o uguale». La differenza fra > e >= è un solo caso, quello in cui i due valori coincidono, ed è proprio quello che viene sbagliato: con una soglia di sei, la condizione voto > 6 lascia fuori chi ha esattamente sei, mentre voto >= 6 lo include. Prima di scrivere il segno conviene sempre chiedersi da che parte deve stare il valore che sta esattamente sul confine."},
		{"titolo": "Le parentesi decidono chi va per primo",
		 "testo": "Senza parentesi la moltiplicazione e la divisione si fanno prima della somma e della sottrazione, come a scuola: 2 + 3 * 4 fa 14, non 20. Le parentesi cambiano l'ordine dicendo «questo prima»: (2 + 3) * 4 fa 20. Il doppio asterisco ** eleva a potenza e viene prima di tutti: 2 ** 3 fa 8, cioè due moltiplicato per se stesso tre volte."},
		{"titolo": "Arrotondare, e togliere il segno",
		 "testo": "round(x) arrotonda al numero intero più vicino, e con un secondo argomento dice a quante cifre: round(3.456, 2) dà 3.46. Non è la stessa cosa della doppia barra, che TAGLIA sempre verso il basso: 3.9 // 1 dà 3, mentre round(3.9) dà 4. abs(x) invece toglie il segno e restituisce la distanza da zero: abs(-7) e abs(7) danno tutt'e due 7. Serve tutte le volte che interessa quanto due cose sono lontane e non quale delle due è più grande — per esempio per sapere se una misura si discosta troppo da quella attesa, in un verso o nell'altro."}],
	"glossario": [
		{"voce": "//", "spiega": "Divisione intera: quante volte ci sta dentro. Taglia la parte decimale, non arrotonda."},
		{"voce": "%", "spiega": "Resto della divisione. Niente a che vedere con le percentuali: n % 2 vale zero se n è pari."},
		{"voce": "==", "spiega": "Domanda di uguaglianza. Risponde True o False, mentre = non risponde niente perché è un ordine."},
		{"voce": ">= e <=", "spiega": "Maggiore o uguale, minore o uguale. Comprendono il valore che sta esattamente sul confine, a differenza di > e <."},
		{"voce": "round( e abs(", "spiega": "Arrotonda al più vicino; toglie il segno. round(3.9) dà 4, mentre 3.9 // 1 dà 3 perché taglia."}],
	"esempi": [
		{"prompt": "print(9 // 4)", "answer": "2",
		 "explanation": "Il quattro ci sta dentro due volte intere. La doppia barra taglia il resto invece di arrotondare, quindi non diventa mai tre."},
		{"prompt": "print(9 % 4)", "answer": "1",
		 "explanation": "Due volte quattro fa otto, e fino a nove ne avanza uno. Il resto è sempre più piccolo del divisore."}],
	"metodo": "Per il resto fai il conto al contrario: quante volte ci sta, moltiplica, e guarda quanto manca per arrivare al numero di partenza. Quel «quanto manca» è il resto.",
	"errore": {"wrong": "Usare = dentro un if, come in if x = 5.",
		"why": "Dentro un if serve una domanda, e = non è una domanda: è l'ordine di scrivere in una casella. Python si ferma e non esegue nulla."},
	"insegna": ["//", "%", "==", "**", "(", ")", "/", "!=", "<", ">", "<=", ">=", "round(", "abs("]},

# =========================================================== OPERATORI · alta
"coding-operatori-alta": {
	"subject": "coding", "topic": "operatori", "fasce": BANDA_ALTA,
	"titolo": "Il resto come strumento, e la catena dei confronti",
	"apertura": "Il resto non serve solo a dire se un numero è pari: è il modo con cui i programmi ragionano su tutto ciò che gira in tondo — le ore, i giorni, le posizioni su un anello.",
	"sezioni": [
		{"titolo": "Tutto ciò che torna al punto di partenza si scrive con il resto",
		 "testo": "Un orologio a dodici ore, sette giorni della settimana, i posti attorno a un tavolo: ogni volta che una cosa torna al punto di partenza, il resto è lo strumento giusto. Se adesso sono le 10 e passano 5 ore, l'ora è (10 + 5) % 12 = 3. Se oggi è il giorno 2 della settimana e ne passano 10, il giorno è (2 + 10) % 7 = 5. La regola è sempre la stessa: somma, poi prendi il resto rispetto a quanto è lungo il giro. Con i numeri negativi Python fa una scelta sua e utile: il resto ha il segno del DIVISORE, quindi -1 % 12 dà 11, non -1. È esattamente ciò che serve per tornare indietro su un anello."},
		{"titolo": "I confronti si incatenano, e in Python si incatenano davvero",
		 "testo": "Per dire «x sta fra 1 e 10» in molti linguaggi bisogna scrivere due confronti uniti da and. In Python si può scrivere 1 <= x <= 10, e non è una scorciatoia di scrittura: Python valuta davvero i due confronti e li unisce con and, valutando x una volta sola. Gli operatori di confronto sono sei: == uguale, != diverso, < minore, > maggiore, <= minore o uguale, >= maggiore o uguale. Restituiscono tutti True o False, e per questo si possono mettere ovunque serva una condizione."},
		{"titolo": "La precedenza, quando la riga si allunga",
		 "testo": "In una riga lunga l'ordine è: prima **, poi * / // %, poi + -, poi i confronti, poi not, poi and, poi or. Sapere la lista serve a leggere il codice degli altri; per scrivere il proprio la regola pratica è un'altra e non sbaglia mai: se hai dovuto pensarci, metti le parentesi. Non rallentano niente e tolgono il dubbio a chi rileggerà, che quasi sempre sei tu fra un mese."}],
	"glossario": [
		{"voce": "(a + b) % n", "spiega": "Avanzare di b posizioni su un giro lungo n: ore, giorni, caselle di un anello."},
		{"voce": "1 <= x <= 10", "spiega": "Confronto incatenato: Python lo valuta come i due confronti uniti da and, calcolando x una volta sola."},
		{"voce": "!=", "spiega": "Diverso da. Risponde True quando i due valori NON sono lo stesso."}],
	"esempi": [
		{"prompt": "print((9 + 6) % 12)", "answer": "3",
		 "explanation": "Quindici su un quadrante da dodici: fatto un giro intero, avanzano tre. È il conto dell'orologio, scritto con il resto."},
		{"prompt": "print(2 + 3 * 4 ** 2)", "answer": "50",
		 "explanation": "Prima la potenza (16), poi la moltiplicazione (48), poi la somma. La precedenza si applica in quest'ordine, sempre."}],
	"metodo": "Su un problema che gira in tondo, chiediti solo due cose: quanto è lungo il giro e di quanto ti sposti. La risposta è sempre (posizione + spostamento) % lunghezza del giro.",
	"errore": {"wrong": "Calcolare 2 + 3 * 4 come 20.",
		"why": "Esegue da sinistra a destra, ma la moltiplicazione viene prima della somma: dodici più due fa quattordici."},
	"insegna": ["!=", "<=", ">=", "<", ">", "1 <= x <= 10"]},

# ============================================================ CONDIZIONI · base
"coding-condizioni-base": {
	"subject": "coding", "topic": "condizioni", "fasce": BANDA_BASE,
	"titolo": "Il punto in cui il programma smette di essere una lista",
	"apertura": "Finché ci sono solo assegnazioni e stampe, un programma è un elenco che si esegue tutto. L'if è il primo posto in cui qualcosa può NON succedere.",
	"sezioni": [
		{"titolo": "La forma, e il rientro che decide chi appartiene a chi",
		 "testo": "Un if si scrive su due righe: la prima porta la condizione e finisce con i due punti, la seconda è RIENTRATA di quattro spazi e contiene quello che va fatto se la condizione è vera. Il rientro non è un'abitudine di ordine: in Python è la sintassi, ed è il solo modo in cui il linguaggio sa dove finisce il corpo dell'if. Una riga non rientrata che segue un if non appartiene all'if: viene eseguita in ogni caso, vera o falsa che sia la condizione. Questo è il difetto più frequente nei primi mesi, e si trova sempre nello stesso modo — guardando da che colonna comincia ogni riga."},
		{"titolo": "else prende tutto il resto",
		 "testo": "if ed else sono due strade alternative: ne parte sempre esattamente una, mai nessuna e mai tutt'e due. Se la condizione è vera parte il ramo dell'if e quello dell'else viene saltato senza nemmeno essere guardato; se è falsa succede il contrario. Insieme coprono tutti i casi possibili, perché else non ha una condizione da controllare: significa «in tutti gli altri casi». Per questo un if con else non può mai passare senza fare niente."},
		{"titolo": "elif, e perché l'ordine dei controlli conta",
		 "testo": "Quando le strade sono più di due si usa elif, che è la contrazione di «else if». In una catena di if / elif / elif / else viene eseguito il PRIMO ramo la cui condizione risulta vera, e tutti gli altri vengono saltati anche se sarebbero veri anche loro. È la conseguenza più importante di tutta la dispensa: mettere i controlli nell'ordine sbagliato non produce nessun errore, produce la risposta sbagliata in silenzio. Se il primo controllo è voto >= 6 e il secondo è voto >= 8, chi ha nove riceve la risposta del primo, perché anche nove è maggiore o uguale a sei. I controlli vanno messi dal più stretto al più largo."}],
	"glossario": [
		{"voce": "if condizione:", "spiega": "Esegui il blocco rientrato solo se la condizione è vera. I due punti e il rientro sono obbligatori."},
		{"voce": "else:", "spiega": "In tutti gli altri casi. Non porta una condizione, perché la sua condizione è «nessuna delle precedenti»."},
		{"voce": "elif", "spiega": "Altro controllo, esaminato solo se tutti i precedenti sono risultati falsi. Vince il primo vero."}],
	"esempi": [
		{"prompt": "eta = 8\nif eta > 10:\n    print(\"grande\")\nprint(\"fine\")", "answer": "fine",
		 "explanation": "La condizione è falsa e la riga rientrata viene saltata. L'ultima riga non è rientrata: non appartiene all'if e si esegue comunque."},
		{"prompt": "v = 9\nif v >= 6:\n    print(\"sufficiente\")\nelif v >= 8:\n    print(\"ottimo\")", "answer": "sufficiente",
		 "explanation": "Nove supera anche il primo controllo, e vince il primo vero: il ramo ottimo non viene mai raggiunto da nessun voto."}],
	"metodo": "Leggi il codice due volte, una immaginando la condizione vera e una falsa, e segna con il dito la colonna da cui parte ogni riga. Le righe fuori colonna sono quelle che si eseguono sempre.",
	"errore": {"wrong": "Mettere il controllo più largo per primo in una catena di elif.",
		"why": "Vince il primo controllo vero, quindi quello largo intercetta anche i casi destinati a quelli dopo, che non vengono mai raggiunti. Python non segnala niente: la risposta è semplicemente sbagliata."},
	"insegna": ["if ", "else:", "elif ", ":", "rientro"]},

# ============================================================ CONDIZIONI · alta
"coding-condizioni-alta": {
	"subject": "coding", "topic": "condizioni", "fasce": BANDA_ALTA,
	"titolo": "Condizioni dentro condizioni, e come non scriverle",
	"apertura": "Un if dentro un altro if funziona, ma dopo tre livelli nessuno riesce più a leggerlo. Ci sono due modi per tenerlo piatto, e sono i due che si usano davvero.",
	"sezioni": [
		{"titolo": "Annidare significa aggiungere un vincolo, non una strada",
		 "testo": "Un if scritto dentro il corpo di un altro if viene raggiunto solo quando la condizione esterna è vera: le due condizioni si sommano, e il blocco più interno richiede che siano vere TUTTE E DUE. Per questo un annidamento semplice si può quasi sempre riscrivere con una condizione sola unita da and, e il risultato è identico ma più corto e più leggibile. L'annidamento serve davvero quando fra i due controlli c'è del lavoro da fare, o quando l'if esterno ha un suo else che riguarda solo lui."},
		{"titolo": "La clausola di guardia: uscire presto invece di rientrare",
		 "testo": "Dentro una funzione c'è una tecnica che toglie quasi tutti gli annidamenti: si controllano per primi i casi impossibili e si esce subito con return, così il resto del corpo può andare avanti senza rientri, sapendo che i casi storti sono già stati tolti di mezzo. Invece di «se il dato va bene, allora se anche l'altro va bene, allora fai il lavoro», si scrive «se il primo non va bene, esci; se il secondo non va bene, esci; fai il lavoro». Le condizioni sono le stesse, ma il lavoro vero resta a sinistra, sulla colonna principale, dove si legge."},
		{"titolo": "L'espressione condizionale, quando la scelta è solo fra due valori",
		 "testo": "Quando l'if serve soltanto a scegliere quale valore mettere in una casella, Python ha una forma da una riga: stato = \"pari\" if n % 2 == 0 else \"dispari\". Si legge nell'ordine in cui è scritta: questo valore, se la condizione è vera, altrimenti quest'altro. Va usata solo quando entrambi i rami sono corti: appena uno dei due fa qualcosa di più che essere un valore, l'if normale su quattro righe è più chiaro."}],
	"glossario": [
		{"voce": "if annidato", "spiega": "Un if dentro il corpo di un altro: le due condizioni si sommano, e il blocco interno chiede che siano vere entrambe."},
		{"voce": "clausola di guardia", "spiega": "Controllo in testa a una funzione che esce subito con return sui casi impossibili, così il resto resta senza rientri."},
		{"voce": "A if cond else B", "spiega": "Espressione condizionale: sceglie fra due VALORI in una riga. Non serve a eseguire due lavori diversi."}],
	"esempi": [
		{"prompt": "n = 12\nif n > 10:\n    if n % 2 == 0:\n        print(\"grande e pari\")", "answer": "grande e pari",
		 "explanation": "Il blocco interno è raggiunto solo con la condizione esterna vera, quindi chiede entrambe le cose: è lo stesso di un and."},
		{"prompt": "n = 7\nesito = \"pari\" if n % 2 == 0 else \"dispari\"\nprint(esito)", "answer": "dispari",
		 "explanation": "Il resto di sette diviso due è uno, quindi la condizione è falsa e viene scelto il valore dopo else."}],
	"metodo": "Ogni volta che stai per scrivere il terzo rientro, fermati e chiediti se le condizioni si possono unire con and o se i casi storti si possono togliere prima con un return. Quasi sempre si può.",
	"errore": {"wrong": "Credere che l'if interno venga controllato anche quando l'esterno è falso.",
		"why": "Il blocco interno sta dentro il corpo dell'esterno: se l'esterno è falso, quel corpo viene saltato per intero e l'if interno non viene nemmeno letto."},
	"insegna": ["and", "or", "not", "A if cond else B", "return"]},

# ============================================================= BOOLEANI · base
"coding-booleani-base": {
	"subject": "coding", "topic": "booleani", "fasce": BANDA_BASE,
	"titolo": "Vero, falso, e le tre parole che li combinano",
	"apertura": "Un booleano è un valore che può essere solo True o False. Sono i mattoni con cui si costruisce ogni decisione che un programma prende.",
	"sezioni": [
		{"titolo": "Due valori soli, e si scrivono con la maiuscola",
		 "testo": "In Python vero e falso si scrivono True e False, con l'iniziale maiuscola: sono nomi del linguaggio, non parole normali, e \"True\" fra virgolette sarebbe una stringa, cioè una cosa diversa. Un confronto produce sempre uno di questi due valori: 5 > 3 vale True, 2 == 7 vale False. E poiché sono valori, si possono mettere in una variabile e usarla dopo: piove = True, e da lì in poi il nome piove si può scrivere direttamente dentro un if, senza confronti. Se serve vedere come Python giudicherebbe un valore qualsiasi, si può chiederglielo con bool(): bool(0) risponde False e bool(5) risponde True, perché dentro un if lo zero conta come falso e ogni altro numero come vero."},
		{"titolo": "and, or, not: le tre combinazioni",
		 "testo": "and dà True solo se SONO VERE ENTRAMBE le parti: basta una falsa e il risultato è falso. or dà True se ne è vera ALMENO UNA: serve che siano false tutt'e due perché il risultato sia falso. not ribalta: prende True e restituisce False, e viceversa. Il modo più sicuro per applicarli è tradurre in italiano: and diventa «e anche», or diventa «oppure, o tutt'e due», not diventa «non è vero che». La frase «non è vero che piove e fa freddo» si sente subito che è diversa da «non piove e fa freddo», ed è esattamente la differenza che fa una coppia di parentesi nel codice."},
		{"titolo": "L'errore più comune: or usato al posto di and",
		 "testo": "In italiano si dice «i numeri fra 1 e 10» e si pensa a due condizioni insieme, ma scrivendo n > 1 or n < 10 si ottiene qualcosa che è vero per QUALSIASI numero: il tre supera uno, il cento è minore di... no, ma supera uno lo stesso, quindi basta la prima parte. Con or basta una condizione vera, e queste due sono costruite in modo che almeno una lo sia sempre. La forma giusta è n > 1 and n < 10, e in Python si può scrivere ancora meglio: 1 < n < 10."}],
	"glossario": [
		{"voce": "True / False", "spiega": "I due soli valori booleani. Si scrivono con la maiuscola e senza virgolette: con le virgolette sarebbero testo."},
		{"voce": "and / or", "spiega": "and vuole vere entrambe le parti; or si accontenta di una. Sono «e anche» ed «oppure»."},
		{"voce": "not", "spiega": "Ribalta il valore. Si legge «non è vero che», e conviene leggerlo davvero così prima di rispondere."},
		{"voce": "bool(x)", "spiega": "Mostra come Python giudicherebbe x dentro un if: bool(0) è False, bool(5) è True."}],
	"esempi": [
		{"prompt": "print(True and False)", "answer": "False",
		 "explanation": "and pretende che siano vere tutte e due le parti: ne basta una falsa perché il risultato sia falso."},
		{"prompt": "print(not (3 > 5))", "answer": "True",
		 "explanation": "Tre non è maggiore di cinque, quindi dentro le parentesi c'è False, e not lo ribalta."}],
	"metodo": "Traduci la condizione in una domanda a cui si risponde sì o no, e leggi and come «e anche», or come «oppure». Se la frase italiana suona strana, la condizione è ancora sbagliata.",
	"errore": {"wrong": "Scrivere n > 1 or n < 10 per dire «fra 1 e 10».",
		"why": "Con or basta una parte vera, e per ogni numero almeno una delle due lo è: la condizione è sempre vera e non filtra niente."},
	"insegna": ["True", "False", "and", "or", "not", "bool("]},

# ============================================================= BOOLEANI · alta
"coding-booleani-alta": {
	"subject": "coding", "topic": "booleani", "fasce": BANDA_ALTA,
	"titolo": "La valutazione pigra, e il modo di negare una condizione intera",
	"apertura": "Python non calcola più di quanto gli serve, e questa pigrizia ha conseguenze pratiche. Poi c'è la regola che dice come si nega una condizione composta senza sbagliare.",
	"sezioni": [
		{"titolo": "Il corto circuito: la seconda parte a volte non viene guardata",
		 "testo": "In un and, se la prima parte è già False il risultato è deciso — falso — qualunque cosa dica la seconda. Python allora la seconda NON la calcola affatto. Lo stesso vale per or con la prima parte True. Si chiama valutazione a corto circuito, e non è un dettaglio di velocità: è quello che permette di scrivere un controllo di sicurezza e il suo uso nella stessa riga. In «se la lista non è vuota E il suo primo elemento è positivo», la seconda parte andrebbe in errore su una lista vuota, ma non ci arriva mai, perché la prima l'ha già fermata. Invertendo le due parti, lo stesso codice si rompe."},
		{"titolo": "Negare una condizione composta: le due parti cambiano tutte",
		 "testo": "not (A and B) NON è (not A) and (not B). È (not A) or (not B), e il motivo si sente in italiano: il contrario di «sono venuti tutti e due» non è «non è venuto nessuno dei due», è «ne è mancato almeno uno». Allo stesso modo il contrario di «ne è venuto almeno uno» è «non ne è venuto nessuno», cioè not (A or B) diventa (not A) and (not B). La regola, in breve: negando si ribaltano le parti E si scambia and con or. Vale sempre, e serve ogni volta che si vuole invertire il ramo di un if."},
		{"titolo": "Cose che valgono come vere e come false anche senza essere booleani",
		 "testo": "Dentro un if, Python accetta qualsiasi valore e decide da solo: contano come falsi lo zero, la stringa vuota, la lista vuota e None; tutto il resto conta come vero. Per questo si scrive «if lista:» invece di «if len(lista) > 0:» — dice la stessa cosa in meno parole. Attenzione a un caso: lo zero conta come falso, quindi un controllo scritto così su un numero non distingue «il valore è zero» da «il valore manca»."}],
	"glossario": [
		{"voce": "corto circuito", "spiega": "Se il risultato è già deciso dalla prima parte, la seconda non viene calcolata. Permette di controllare e usare nella stessa riga."},
		{"voce": "not (A and B)", "spiega": "Diventa (not A) or (not B): negando si ribaltano le parti e si scambia and con or."},
		{"voce": "valore di verità", "spiega": "Zero, stringa vuota, lista vuota e None contano come falsi dentro un if; tutto il resto conta come vero."}],
	"esempi": [
		{"prompt": "print(not (True and False))", "answer": "True",
		 "explanation": "Dentro le parentesi c'è False perché and vuole entrambe vere; not lo ribalta. Negando si sarebbe potuto anche scrivere (not True) or (not False)."},
		{"prompt": "lista = []\nprint(bool(lista))", "answer": "False",
		 "explanation": "Una lista vuota conta come falsa: è il motivo per cui si scrive «if lista:» invece di confrontare la sua lunghezza con zero."}],
	"metodo": "Per negare una condizione composta non aggiungere not davanti a tutto: ribalta ogni parte e scambia and con or. Poi rileggila in italiano per controllare che dica il contrario di prima.",
	"errore": {"wrong": "Trasformare not (A and B) in (not A) and (not B).",
		"why": "Nega le parti ma lascia l'and: il risultato pretende che siano false tutte e due, mentre il contrario di «entrambe vere» è «almeno una falsa»."},
	"insegna": ["not (", "bool(", "corto circuito"]},

# ================================================================ CICLI · base
"coding-cicli-base": {
	"subject": "coding", "topic": "cicli", "fasce": BANDA_BASE,
	"titolo": "Scrivere una volta una cosa da fare cento volte",
	"apertura": "Un ciclo serve a non riscrivere cento righe uguali: si scrive il lavoro una volta sola e si dice quante volte ripeterlo.",
	"sezioni": [
		{"titolo": "range conta da zero e si ferma PRIMA del numero scritto",
		 "testo": "for i in range(5): esegue il corpo cinque volte, e la variabile i vale 0, 1, 2, 3, 4 — cinque valori, ma l'ultimo è quattro, non cinque. Il numero scritto dentro range è il punto in cui ci si FERMA, e non viene mai raggiunto. Sembra una stranezza ed è invece la scelta che fa tornare i conti: range(5) ha esattamente cinque elementi, e gli indici di una lista di cinque elementi sono proprio 0..4. Con due numeri, range(2, 6) parte da due e si ferma prima del sei: dà 2, 3, 4, 5, cioè sei meno due uguale quattro valori. Con tre, range(0, 10, 2) aggiunge il passo e dà 0, 2, 4, 6, 8."},
		{"titolo": "for quando sai quante volte, while quando dipende",
		 "testo": "Il for si usa quando il numero di ripetizioni è noto prima di partire, o quando si vuole passare su ogni elemento di una lista. Il while si usa quando il numero di giri dipende da qualcosa che succede durante: «finché il numero è più grande di uno», «finché l'utente non scrive fine». Un while ha una responsabilità in più: dentro al corpo deve esserci qualcosa che, prima o poi, rende falsa la condizione. Se non c'è, il ciclo non finisce mai — e non è un errore che Python segnala, è un programma che resta lì."},
		{"titolo": "Il corpo è ciò che è rientrato, e cambia a ogni giro",
		 "testo": "Come per l'if, il corpo del ciclo è il blocco rientrato sotto i due punti: quello si ripete, e la prima riga non rientrata dopo il ciclo si esegue una volta sola, alla fine di tutto. Dentro il corpo, la variabile del for cambia valore a ogni giro, quindi una riga che stampa i stampa un numero diverso ogni volta. Chi accumula — totale = totale + i — vede crescere la casella giro dopo giro, perché il valore sopravvive alla fine del giro e riparte da lì."}],
	"glossario": [
		{"voce": "range(n)", "spiega": "I numeri da 0 a n-1: n valori in tutto, e il numero scritto non viene mai raggiunto."},
		{"voce": "for i in ...", "spiega": "Ripeti il corpo una volta per ogni valore, mettendolo in i. Si usa quando le ripetizioni sono note."},
		{"voce": "while condizione:", "spiega": "Ripeti finché la condizione resta vera. Il corpo deve contenere qualcosa che prima o poi la renda falsa."}],
	"esempi": [
		{"prompt": "for i in range(3):\n    print(i)", "answer": "0 1 2",
		 "explanation": "Tre giri, e i parte da zero: l'ultimo valore è due perché il tre è il punto in cui ci si ferma, non uno dei valori."},
		{"prompt": "t = 0\nfor i in range(1, 4):\n    t = t + i\nprint(t)", "answer": "6",
		 "explanation": "I valori sono 1, 2 e 3 — il quattro non ci arriva — e la casella t sopravvive ai giri accumulando: uno più due più tre."}],
	"metodo": "Prima di rispondere a una domanda su un ciclo, scrivi in colonna i valori che prende la variabile. Quasi tutti gli errori sui cicli sono un valore in più o in meno all'estremo.",
	"errore": {"wrong": "Credere che range(5) arrivi fino a cinque.",
		"why": "Il numero scritto è il punto in cui il ciclo si ferma e non viene mai usato: i valori sono cinque ma vanno da zero a quattro."},
	"insegna": ["for ", "range(", "while ", "in "]},

# ================================================================ CICLI · alta
"coding-cicli-alta": {
	"subject": "coding", "topic": "cicli", "fasce": BANDA_ALTA,
	"titolo": "Uscire prima, saltare un giro, e i cicli dentro i cicli",
	"apertura": "Tre cose che cambiano il flusso di un ciclo: due parole che lo interrompono e una struttura che lo moltiplica.",
	"sezioni": [
		{"titolo": "break esce, continue salta: la differenza è tutta lì",
		 "testo": "break abbandona il ciclo per sempre: si salta anche il resto del corpo e non si fanno più giri, si riprende dalla prima riga dopo il ciclo. continue invece salta solo il RESTO DI QUESTO GIRO e passa al successivo: il ciclo continua. La regola pratica per scegliere è una domanda sola: «ho finito di cercare?» — allora break; «questo elemento non mi interessa?» — allora continue. break è quello che rende efficiente una ricerca: appena trovi ciò che cerchi non ha senso guardare il resto, e su una lista lunga è la differenza fra un giro e mille."},
		{"titolo": "Due cicli uno dentro l'altro moltiplicano i giri",
		 "testo": "Quando un for sta dentro il corpo di un altro for, quello interno riparte da capo a ogni giro di quello esterno. Con range(3) fuori e range(4) dentro, il corpo più interno viene eseguito 3 per 4 uguale dodici volte. È il motivo per cui i cicli annidati sono la cosa più costosa che si scrive senza accorgersene: due cicli su mille elementi fanno un milione di giri. Servono davvero quando il problema ha due dimensioni — le righe e le colonne di una tabella, tutte le coppie possibili — e in quel caso la variabile esterna è la riga e quella interna la colonna."},
		{"titolo": "Modificare una lista mentre la si percorre",
		 "testo": "Togliere elementi da una lista dentro il for che la sta percorrendo produce risultati sbagliati che sembrano casuali: il ciclo avanza di posizione mentre gli elementi scivolano indietro, e alcuni vengono saltati. La soluzione standard sono due: costruire una lista NUOVA con i soli elementi da tenere, oppure percorrere una copia. La prima è quasi sempre la migliore, perché non modifica niente mentre legge, e il codice dice che cosa si vuole ottenere invece di come smontare quello che c'è."}],
	"glossario": [
		{"voce": "break", "spiega": "Esce dal ciclo immediatamente. Nessun altro giro, e il resto del corpo di questo giro viene saltato."},
		{"voce": "continue", "spiega": "Salta il resto di questo giro e passa al successivo. Il ciclo prosegue."},
		{"voce": "ciclo annidato", "spiega": "Un ciclo dentro il corpo di un altro: quello interno riparte da capo ogni giro, e i giri totali si moltiplicano."}],
	"esempi": [
		{"prompt": "for i in range(5):\n    if i == 2:\n        break\n    print(i)", "answer": "0 1",
		 "explanation": "Al giro con i uguale a due si esce prima della stampa, e non ci sono altri giri: il ciclo finisce lì."},
		{"prompt": "for i in range(4):\n    if i == 2:\n        continue\n    print(i)", "answer": "0 1 3",
		 "explanation": "Il giro del due salta solo la propria stampa: il ciclo prosegue e il tre viene stampato normalmente."}],
	"metodo": "Su un ciclo annidato conta i giri prima di leggere il corpo: quanti ne fa quello esterno, moltiplicato per quanti ne fa quello interno. Il numero ti dice subito se la domanda è sul risultato o sul costo.",
	"errore": {"wrong": "Usare break per saltare un elemento che non interessa.",
		"why": "break non salta l'elemento: chiude il ciclo. Tutti gli elementi successivi non vengono mai esaminati, e la ricerca si ferma al primo scarto."},
	"insegna": ["break", "continue", "ciclo annidato"]},

# ================================================================ LISTE · base
"coding-liste-base": {
	"subject": "coding", "topic": "liste", "fasce": BANDA_BASE,
	"titolo": "Molte cose sotto un nome solo, e il conto che parte da zero",
	"apertura": "Una lista serve quando le cose sono tante e non si sa quante: con variabili separate bisognerebbe saperlo in anticipo, e dare un nome a ciascuna.",
	"sezioni": [
		{"titolo": "Le posizioni si contano da zero",
		 "testo": "Una lista si scrive fra parentesi quadre, con gli elementi separati da virgole: voti = [7, 9, 6, 8]. Per prendere un elemento si scrive il nome seguito dalla posizione fra quadre, e le posizioni cominciano da ZERO: voti[0] è il sette, voti[1] è il nove. Di conseguenza l'ultimo elemento non sta alla posizione «quanti sono», ma a «quanti sono meno uno»: qui la lista ha quattro elementi e l'ultimo è voti[3]. Chiedere voti[4] è un errore che ferma il programma, ed è l'errore più frequente di tutti. Python offre una scorciatoia comoda: voti[-1] è l'ultimo, voti[-2] il penultimo, contando dalla fine."},
		{"titolo": "len dice quanti, non l'ultima posizione",
		 "testo": "len(voti) restituisce quanti elementi ci sono: quattro. Non è la posizione dell'ultimo, ed è esattamente la trappola: la posizione dell'ultimo è len(voti) - 1. Il motivo per cui i due numeri non coincidono è lo stesso per cui non coincidono su un righello: il primo elemento occupa la posizione zero. Su una lista vuota, len vale zero e non esiste nessuna posizione valida."},
		{"titolo": "Aggiungere in fondo, cambiare sul posto",
		 "testo": "voti.append(10) aggiunge un elemento IN FONDO e la lista diventa lunga cinque. Non restituisce la lista nuova: modifica quella che c'è, quindi si scrive come una riga a sé e non come voti = voti.append(10) — quella riga riempirebbe voti di niente. Allo stesso modo voti[0] = 5 sostituisce l'elemento in prima posizione lasciando tutti gli altri dov'erano. Le liste sono fatte apposta per essere modificate: è la differenza principale fra loro e le stringhe."}],
	"glossario": [
		{"voce": "lista[0]", "spiega": "Il primo elemento. Le posizioni partono da zero, quindi l'ultimo sta a len(lista) - 1."},
		{"voce": "len(lista)", "spiega": "Quanti elementi ci sono. Non è la posizione dell'ultimo: quella è questo numero meno uno."},
		{"voce": ".append(x)", "spiega": "Aggiunge x in fondo, modificando la lista esistente. Non restituisce niente da assegnare."}],
	"esempi": [
		{"prompt": "n = [4, 8, 15]\nprint(n[1])", "answer": "8",
		 "explanation": "La posizione uno è la SECONDA, perché il conteggio parte da zero: il quattro sta a posizione zero."},
		{"prompt": "n = [4, 8, 15]\nn.append(16)\nprint(len(n))", "answer": "4",
		 "explanation": "append aggiunge in fondo e la lista passa da tre a quattro elementi. Le posizioni valide diventano da zero a tre."}],
	"metodo": "Disegna la lista come una fila di caselle e scrivi sotto ciascuna il suo numero partendo da zero. La domanda «quale posizione» e la domanda «quanti» smettono di confondersi appena le vedi scritte sotto e sopra.",
	"errore": {"wrong": "Leggere lista[len(lista)] per prendere l'ultimo elemento.",
		"why": "Quella posizione è una oltre la fine, perché il conteggio parte da zero: l'ultimo elemento sta a len(lista) - 1, e Python ferma il programma."},
	"insegna": ["[", "]", ".append(", "len(", "lista[0]", "lista[-1]"]},

# ================================================================ LISTE · alta
"coding-liste-alta": {
	"subject": "coding", "topic": "liste", "fasce": BANDA_ALTA,
	"titolo": "Tagliare una fetta, ordinare, e riassumere in un numero",
	"apertura": "Con le liste lunghe servono tre gesti: prenderne un pezzo, metterle in ordine, e ricavarne un numero solo.",
	"sezioni": [
		{"titolo": "La fetta prende da dove dici fino a PRIMA di dove dici",
		 "testo": "lista[1:4] restituisce una lista NUOVA con gli elementi nelle posizioni 1, 2 e 3: il quattro è il punto in cui ci si ferma, esattamente come in range. La lunghezza della fetta è quindi la differenza fra i due numeri, qui tre, e questo rende facile calcolarla a mente. Si possono lasciare vuoti gli estremi: lista[:3] parte dall'inizio, lista[2:] arriva alla fine, lista[:] è una copia intera. L'ultima forma è il modo più corto di copiare una lista, e serve perché la fetta costruisce una lista nuova: modificarla non tocca l'originale."},
		{"titolo": "Due modi di ordinare, e non fanno la stessa cosa",
		 "testo": "lista.sort() ordina la lista SUL POSTO: cambia quella che c'è e non restituisce niente. sorted(lista) invece lascia l'originale com'è e restituisce una lista nuova ordinata. Scegliere quello sbagliato produce due difetti opposti e altrettanto frequenti: scrivere lista = lista.sort() riempie la variabile di niente, e scrivere sorted(lista) da solo su una riga calcola l'ordinamento e poi lo butta via. Entrambi accettano reverse=True per l'ordine decrescente."},
		{"titolo": "Riassumere: sum, max, min, e il conteggio",
		 "testo": "sum(numeri) somma tutti gli elementi, max(numeri) trova il più grande, min(numeri) il più piccolo, len(numeri) quanti sono. Da sum e len viene la media: sum(numeri) / len(numeri), e la barra singola serve proprio qui, perché una media può avere la virgola. Su una lista vuota sum dà zero, ma max e min si fermano con un errore — non esiste un massimo fra niente — e la media dividerebbe per zero: per questo il controllo «if numeri:» va messo prima, non dopo."}],
	"glossario": [
		{"voce": "lista[1:4]", "spiega": "Fetta: gli elementi da 1 a 3. Costruisce una lista nuova, e il secondo numero non viene incluso."},
		{"voce": ".sort() e sorted()", "spiega": "Il primo ordina sul posto e non restituisce niente; il secondo lascia stare l'originale e restituisce una lista nuova."},
		{"voce": "sum / max / min", "spiega": "Riassumono una lista in un numero. Su una lista vuota sum dà zero, mentre max e min si fermano con un errore."}],
	"esempi": [
		{"prompt": "n = [10, 20, 30, 40]\nprint(n[1:3])", "answer": "[20, 30]",
		 "explanation": "Dalla posizione uno fino a PRIMA della tre: due elementi, cioè la differenza fra i due numeri."},
		{"prompt": "n = [3, 1, 2]\nprint(sorted(n)[0])", "answer": "1",
		 "explanation": "sorted costruisce una lista nuova ordinata senza toccare n, e la posizione zero di una lista ordinata è il minimo."}],
	"metodo": "Per una fetta calcola prima la lunghezza — secondo numero meno primo — e poi scrivi gli elementi. Se il conto e l'elenco non coincidono, hai incluso l'estremo destro per sbaglio.",
	"errore": {"wrong": "Scrivere lista = lista.sort().",
		"why": "sort ordina sul posto e non restituisce niente: la variabile riceve None, e la lista ordinata viene persa. Per avere un valore da assegnare serve sorted."},
	"insegna": ["[1:4]", ".sort(", "sorted(", "sum(", "max(", "min(", "reverse=True"]},

# ============================================================= STRINGHE · base
"coding-stringhe-base": {
	"subject": "coding", "topic": "stringhe", "fasce": BANDA_BASE,
	"titolo": "Il testo è una fila di caratteri, e si conta come una lista",
	"apertura": "Una stringa è testo: una sequenza di caratteri in fila. Molte cose che valgono per le liste valgono anche per lei, e una no.",
	"sezioni": [
		{"titolo": "Si indicizza come una lista, e si conta da zero",
		 "testo": "parola = \"ciao\" contiene quattro caratteri, e parola[0] è la lettera c. Come per le liste il conteggio parte da zero, l'ultimo carattere sta a len(parola) - 1, e parola[-1] è una scorciatoia per l'ultimo. len(\"ciao\") vale quattro, e conta TUTTO quello che c'è fra le virgolette: gli spazi sono caratteri come gli altri, quindi len(\"ci ao\") vale cinque. È una fonte di risposte sbagliate quando la stringa contiene uno spazio in mezzo o, peggio, uno in fondo che non si vede."},
		{"titolo": "Unire e ripetere",
		 "testo": "Il più fra due stringhe le accosta senza aggiungere niente in mezzo: \"ci\" + \"ao\" dà \"ciao\", e \"buon\" + \"giorno\" dà \"buongiorno\" senza spazio, perché nessuno lo ha scritto. Per averlo bisogna metterlo: \"buon\" + \" \" + \"giorno\". L'asterisco fra stringa e numero ripete: \"ab\" * 3 dà \"ababab\". Il più fra una stringa e un numero invece non è definito e ferma il programma: prima si converte il numero con str()."},
		{"titolo": "Una stringa non si modifica: se ne costruisce un'altra",
		 "testo": "Questa è la differenza con le liste, ed è quella che sorprende tutti. parola[0] = \"C\" non funziona: le stringhe sono immutabili, cioè una volta costruite restano com'erano. Tutti i metodi che sembrano cambiarle in realtà ne restituiscono una NUOVA, lasciando intatta l'originale: parola.upper() restituisce la versione tutta maiuscola, e se non se ne fa niente si perde. Per tenerla bisogna assegnarla: grande = parola.upper(). Lo stesso vale per lower(), replace() e strip()."}],
	"glossario": [
		{"voce": "stringa", "spiega": "Testo fra virgolette: una fila di caratteri, con le posizioni che partono da zero come nelle liste."},
		{"voce": "len(\"ciao\")", "spiega": "Quanti caratteri ci sono. Gli spazi contano, anche quelli in fondo che non si vedono."},
		{"voce": ".upper()", "spiega": "Restituisce una stringa NUOVA tutta maiuscola. L'originale resta com'era: le stringhe non si modificano."}],
	"esempi": [
		{"prompt": "print(len(\"buon giorno\"))", "answer": "11",
		 "explanation": "Quattro più cinque lettere fa nove, più lo spazio in mezzo: lo spazio è un carattere, e si conta come gli altri. Undici in tutto."},
		{"prompt": "s = \"eco\"\ns.upper()\nprint(s)", "answer": "eco",
		 "explanation": "upper restituisce una stringa nuova, e quella riga la butta via senza assegnarla: l'originale non è stata toccata."}],
	"metodo": "Quando una domanda chiede la lunghezza di un testo, conta i caratteri con il dito compresi gli spazi, invece di contare le parole. La differenza fra i due conteggi è quasi sempre la risposta sbagliata proposta.",
	"errore": {"wrong": "Scrivere parola.upper() su una riga da sola e aspettarsi che parola sia cambiata.",
		"why": "Le stringhe sono immutabili: il metodo ne costruisce una nuova e la restituisce. Senza assegnarla a qualcosa, il risultato viene perso."},
	"insegna": ["\"", "len(", ".upper(", ".lower(", "+ fra stringhe", "stringa[0]"]},

# ============================================================= STRINGHE · alta
"coding-stringhe-alta": {
	"subject": "coding", "topic": "stringhe", "fasce": BANDA_ALTA,
	"titolo": "Spezzare, ricucire, ripulire",
	"apertura": "Il testo che arriva da fuori è quasi sempre sporco e attaccato. Tre metodi lo rendono dati, e uno lo rimette insieme.",
	"sezioni": [
		{"titolo": "split spezza in una LISTA, e senza argomenti spezza sugli spazi",
		 "testo": "\"a,b,c\".split(\",\") restituisce la lista [\"a\", \"b\", \"c\"]: il separatore indicato viene usato per tagliare e sparisce dal risultato. Chiamato senza argomenti, split taglia sugli spazi e ignora quelli doppi, che è proprio ciò che serve per contare le parole di una frase: len(frase.split()) dà il numero di parole. Da notare che il risultato è una lista, non una stringa: da quel momento in poi valgono le regole delle liste, indici da zero compresi."},
		{"titolo": "join ricuce, e si chiama sul separatore",
		 "testo": "L'operazione inversa ha una forma che sembra girata al contrario e non lo è: \", \".join(lista) unisce gli elementi della lista mettendo fra l'uno e l'altro la stringa su cui è stato chiamato. Si scrive così perché il separatore è una stringa e il risultato è una stringa, mentre la lista è solo l'ingrediente. Il separatore compare fra gli elementi, non prima e non dopo: con tre elementi compare due volte. E gli elementi devono essere già stringhe: su una lista di numeri join si ferma, e vanno convertiti prima."},
		{"titolo": "strip toglie ai bordi, replace ovunque",
		 "testo": "strip() restituisce il testo senza spazi all'inizio e alla fine, ed è la prima cosa da fare su tutto ciò che arriva da input: uno spazio invisibile in fondo fa fallire ogni confronto, e un confronto fallito senza ragione apparente è quasi sempre questo. Toglie solo ai BORDI: gli spazi in mezzo restano, perché servono. replace(vecchio, nuovo) invece sostituisce TUTTE le occorrenze, non la prima soltanto, e come ogni metodo delle stringhe restituisce una copia nuova senza toccare l'originale."}],
	"glossario": [
		{"voce": ".split(sep)", "spiega": "Spezza il testo in una lista usando il separatore, che sparisce. Senza argomenti taglia sugli spazi."},
		{"voce": "sep.join(lista)", "spiega": "Ricuce gli elementi mettendo il separatore in mezzo. Si chiama sul separatore, e gli elementi devono essere stringhe."},
		{"voce": ".strip()", "spiega": "Toglie gli spazi ai bordi, non quelli in mezzo. Prima cosa da fare sul testo che arriva da fuori."}],
	"esempi": [
		{"prompt": "print(len(\"il gatto nero\".split()))", "answer": "3",
		 "explanation": "split senza argomenti taglia sugli spazi e restituisce tre parole; len conta gli elementi della lista, non i caratteri."},
		{"prompt": "print(\"-\".join([\"a\", \"b\", \"c\"]))", "answer": "a-b-c",
		 "explanation": "Il separatore va FRA gli elementi: con tre elementi compare due volte, mai davanti al primo o dopo l'ultimo."}],
	"metodo": "Su un testo che arriva da fuori applica sempre la stessa sequenza: strip per pulire i bordi, poi split per ottenere i pezzi, poi le conversioni. In quest'ordine, e prima di ogni confronto.",
	"errore": {"wrong": "Scrivere lista.join(\", \").",
		"why": "join si chiama sul separatore e riceve la lista, non il contrario: il risultato è una stringa, quindi il metodo appartiene alle stringhe."},
	"insegna": [".split(", ".join(", ".strip(", ".replace("]},

# ============================================================= FUNZIONI · base
"coding-funzioni-base": {
	"subject": "coding", "topic": "funzioni", "fasce": BANDA_BASE,
	"titolo": "Dare un nome a un pezzo di lavoro",
	"apertura": "Una funzione serve a usare un pezzo di lavoro senza doversi ricordare come è fatto dentro. Si scrive una volta e si chiama quante volte si vuole.",
	"sezioni": [
		{"titolo": "Definire non è eseguire",
		 "testo": "def saluta(): seguito da un corpo rientrato DEFINISCE la funzione: scrive la ricetta e le dà un nome, ma non cucina niente. Il corpo viene eseguito solo quando la funzione viene CHIAMATA, cioè quando si scrive il suo nome seguito dalle parentesi tonde: saluta(). Le parentesi sono la differenza fra nominare e fare, e dimenticarle è un difetto che non dà nessun errore: la riga calcola il valore «la funzione» e lo butta via, quindi non succede assolutamente niente e non c'è niente da leggere per capire perché."},
		{"titolo": "I parametri sono caselle che si riempiono al momento della chiamata",
		 "testo": "def doppio(n): dichiara che la funzione lavora su un valore che al suo interno si chiamerà n. Chiamandola con doppio(5), dentro il corpo n vale cinque; chiamandola con doppio(7), vale sette. Il nome del parametro vive solo dentro la funzione, e non ha niente a che fare con eventuali variabili che si chiamano allo stesso modo fuori. Questo è il vero motivo per cui le funzioni sono utili: quello che succede dentro non disturba quello che c'è fuori, e si può leggere il loro nome senza doverle aprire."},
		{"titolo": "return consegna un valore e chiude la funzione",
		 "testo": "return valore fa due cose insieme: consegna il valore a chi ha chiamato e termina la funzione all'istante, anche se sotto ci sono altre righe. Una funzione senza return restituisce None, cioè niente — e None non è zero e non è la stringa vuota, è l'assenza di un valore. C'è una differenza importante fra return e print: print MOSTRA e basta, return CONSEGNA. Una funzione che stampa invece di restituire non si può usare dentro un conto, perché a chi l'ha chiamata non arriva nulla."}],
	"glossario": [
		{"voce": "def nome(...):", "spiega": "Definisce la funzione, cioè scrive la ricetta. Il corpo non viene eseguito finché qualcuno non la chiama."},
		{"voce": "return", "spiega": "Consegna un valore a chi ha chiamato e chiude la funzione all'istante. Diverso da print, che mostra soltanto."},
		{"voce": "None", "spiega": "L'assenza di valore. È ciò che restituisce una funzione senza return, e non è zero né stringa vuota."}],
	"esempi": [
		{"prompt": "def doppio(n):\n    return n * 2\nprint(doppio(4))", "answer": "8",
		 "explanation": "Il quattro entra nel parametro n, il corpo calcola otto e lo consegna: print riceve il valore consegnato e lo mostra."},
		{"prompt": "def saluta():\n    print(\"ciao\")\nx = saluta()\nprint(x)", "answer": "None",
		 "explanation": "La funzione stampa ma non restituisce niente, quindi a x arriva None: mostrare e consegnare sono due cose diverse."}],
	"metodo": "Quando incontri una chiamata, sostituiscila mentalmente con il valore che la funzione consegna e vai avanti a leggere. Se non consegna niente, la sostituzione è None, e quasi sempre lì c'è il difetto.",
	"errore": {"wrong": "Scrivere il nome della funzione senza parentesi per eseguirla.",
		"why": "Senza parentesi la riga nomina la funzione invece di chiamarla: nessun errore, nessun effetto, e nulla che spieghi perché non è successo niente."},
	"insegna": ["def ", "return", "None", "chiamata con ()"]},

# ============================================================= FUNZIONI · alta
"coding-funzioni-alta": {
	"subject": "coding", "topic": "funzioni", "fasce": BANDA_ALTA,
	"titolo": "Dentro e fuori: che cosa una funzione vede e che cosa tocca",
	"apertura": "Una funzione ha un suo spazio. Sapere che cosa entra, che cosa esce e che cosa resta fuori è la metà dei difetti difficili.",
	"sezioni": [
		{"titolo": "Le variabili nate dentro muoiono dentro",
		 "testo": "Una variabile assegnata nel corpo di una funzione è LOCALE: esiste dal momento dell'assegnazione fino alla fine della chiamata, e fuori non esiste affatto. Provare a leggerla dopo produce un errore, e se fuori esiste un'altra variabile con lo stesso nome sono due caselle diverse che non si toccano. La funzione può invece LEGGERE le variabili definite fuori, se non ne ha una sua con quel nome. Assegnare crea sempre una locale nuova, e questa asimmetria — leggere sì, scrivere no — è il motivo per cui una funzione è sicura da chiamare."},
		{"titolo": "Gli argomenti mutabili sono l'eccezione, e va conosciuta",
		 "testo": "Se a una funzione passi un numero o una stringa, qualunque cosa faccia dentro non tocca l'originale: riassegnare il parametro attacca semplicemente l'etichetta a un valore nuovo. Se le passi una LISTA, il parametro è un'altra etichetta sulla stessa lista: chiamare .append() dentro la funzione si vede anche fuori. Non è una contraddizione, è la stessa regola di prima — riassegnare no, modificare sì — e una funzione che modifica quello che riceve deve dirlo nel nome, altrimenti sorprende chi la chiama."},
		{"titolo": "Due return, e il primo che si incontra vince",
		 "testo": "Una funzione può contenere più return: viene eseguito il primo che il flusso incontra, e da lì la funzione termina. È quello che rende possibile la clausola di guardia — controllare i casi impossibili in testa e uscire subito — e rende inutile scrivere un else dopo un ramo che finisce con return, perché se quel ramo è stato preso non si arriva comunque al resto. Il codice che sta dopo un return, nello stesso blocco, non viene eseguito mai."}],
	"glossario": [
		{"voce": "variabile locale", "spiega": "Nata dentro una funzione, esiste solo lì. Fuori non c'è, anche se un altro nome uguale esiste."},
		{"voce": "parametro", "spiega": "La casella che riceve il valore al momento della chiamata. Vive dentro la funzione e non tocca ciò che c'è fuori."},
		{"voce": "argomento mutabile", "spiega": "Una lista passata a una funzione: riassegnarla non si vede fuori, modificarla sì. È la stessa etichetta su una scatola sola."}],
	"esempi": [
		{"prompt": "def f(n):\n    n = n + 1\n    return n\nx = 5\nf(x)\nprint(x)", "answer": "5",
		 "explanation": "Dentro la funzione n è una casella sua: riassegnarla non tocca x, e il valore consegnato non è stato raccolto da nessuno."},
		{"prompt": "def g(lista):\n    lista.append(1)\nv = []\ng(v)\nprint(len(v))", "answer": "1",
		 "explanation": "Il parametro è un'altra etichetta sulla stessa lista: append la modifica, e la modifica si vede da entrambi i nomi."}],
	"metodo": "Davanti a una funzione chiediti tre cose in quest'ordine: che cosa entra, che cosa consegna, che cosa tocca di quello che c'era già. La terza è quella che nessuno guarda e che produce i difetti lunghi.",
	"errore": {"wrong": "Chiamare una funzione che restituisce un valore senza assegnarlo, e aspettarsi un effetto.",
		"why": "return consegna il valore a chi chiama: se nessuno lo raccoglie va perso, e le variabili di fuori restano esattamente come prima."},
	"insegna": ["variabile locale", "parametro", "return anticipato"]},

# ================================================================ INPUT · base
"coding-input-base": {
	"subject": "coding", "topic": "input", "fasce": BANDA_BASE,
	"titolo": "Il punto in cui il programma smette di sapere già tutto",
	"apertura": "Finché i valori sono scritti nel codice, il programma sa già tutto. Con input arriva qualcosa da fuori, e da lì in poi non può più dare niente per scontato.",
	"sezioni": [
		{"titolo": "input consegna SEMPRE testo",
		 "testo": "input(\"Quanti anni hai? \") mostra la domanda, aspetta che qualcuno scriva e prema invio, e restituisce quello che ha scritto — sempre come STRINGA, anche quando sono tutte cifre. Digitando 12 si ottiene la stringa \"12\", non il numero dodici, e questo è il punto in cui nascono quasi tutti i difetti dei primi programmi interattivi. Sommare due input senza convertirli non produce un errore: produce un accostamento, perché il più fra due stringhe unisce. Il programma sembra funzionare e dà il risultato sbagliato, che è il modo peggiore di rompersi."},
		{"titolo": "Convertire subito, una volta sola",
		 "testo": "Se serve un numero, la conversione va fatta appena il valore arriva: eta = int(input(\"Anni? \")). Così da quella riga in poi la variabile contiene un numero e nessun'altra parte del programma deve ricordarsene. Convertire tardi, o convertire due volte in posti diversi, è il modo in cui un programma diventa difficile da leggere. Se il numero può avere la virgola si usa float() invece di int()."},
		{"titolo": "Chi scrive può scrivere qualsiasi cosa",
		 "testo": "int() si ferma con un errore se il testo non descrive un numero, e chi usa il programma prima o poi scriverà «dodici», oppure premerà invio senza scrivere niente. Un programma robusto controlla prima di convertire, e per farlo c'è un metodo pronto: testo.isdigit() risponde True se il testo contiene solo cifre. E la prima riga di ogni trattamento resta strip(), perché uno spazio invisibile in fondo è la causa numero uno dei confronti che falliscono senza motivo apparente."}],
	"glossario": [
		{"voce": "input(\"...\")", "spiega": "Mostra il messaggio, aspetta, e restituisce quello che è stato scritto. Sempre come stringa, anche se sono cifre."},
		{"voce": "int(input(...))", "spiega": "La forma normale quando serve un numero: si converte appena il valore arriva, non più tardi."},
		{"voce": ".isdigit()", "spiega": "True se il testo contiene solo cifre. Si usa per controllare PRIMA di convertire, invece di fermarsi con un errore."}],
	"esempi": [
		{"prompt": "a = input()\nb = input()\nprint(a + b)\n\n(chi scrive digita 2 e poi 3)", "answer": "23",
		 "explanation": "I due input sono stringhe, e il più fra stringhe accosta invece di sommare: il programma non segnala nulla e dà il risultato sbagliato."},
		{"prompt": "a = int(input())\nb = int(input())\nprint(a + b)\n\n(chi scrive digita 2 e poi 3)", "answer": "5",
		 "explanation": "Le conversioni trasformano il testo in numeri appena arriva, e da lì in poi il più fa il suo mestiere di somma."}],
	"metodo": "Accanto a ogni riga con input scrivi «testo» a margine. Poi segui quella variabile: il primo punto in cui la usi come numero senza averla convertita è il difetto.",
	"errore": {"wrong": "Sommare due valori letti con input senza convertirli.",
		"why": "input restituisce stringhe, e il più fra stringhe le accosta: il programma non si ferma e risponde con le due cifre attaccate."},
	"insegna": ["input(", ".isdigit(", "int(input("]},

# ================================================================ INPUT · alta
"coding-input-alta": {
	"subject": "coding", "topic": "input", "fasce": BANDA_ALTA,
	"titolo": "Chiedere finché non arriva una risposta valida",
	"apertura": "Controllare un dato non basta: se è sbagliato bisogna decidere che cosa farne. Ci sono due schemi, e si usano in situazioni diverse.",
	"sezioni": [
		{"titolo": "Il ciclo di validazione",
		 "testo": "Lo schema standard è un while che ripete la domanda finché la risposta non va bene: si chiede, si controlla, e se il controllo fallisce si spiega che cosa c'era di storto e si torna a chiedere. Il punto delicato è uno solo: la prima lettura deve stare DENTRO il ciclo, o prima di esso, ma in ogni caso il controllo deve poter essere rifatto sul valore nuovo. Un while che controlla sempre il primo valore letto non finisce mai, ed è il difetto più comune di questo schema — il ciclo gira, la domanda ricompare, e la risposta giusta non viene mai accettata."},
		{"titolo": "Il sentinella: un valore che vuol dire «ho finito»",
		 "testo": "Quando non si sa quanti dati arriveranno, si sceglie un valore speciale che significa fine — la parola «fine», la riga vuota, il numero zero — e si legge in un ciclo finché non arriva quello. Si chiama valore sentinella. Due regole lo rendono affidabile: deve essere un valore che non può essere un dato vero, e il controllo va fatto PRIMA di usare il valore, altrimenti la sentinella finisce dentro i conti. Su una media, per esempio, la sentinella contata come un dato sposta il risultato senza che niente segnali l'errore."},
		{"titolo": "Messaggi che dicono che cosa fare",
		 "testo": "Un programma che risponde «errore» insegna solo che qualcosa non va. Uno che risponde «serve un numero intero fra 1 e 10, hai scritto dodici» dice anche come uscirne. La regola pratica è che il messaggio deve contenere il vincolo e il valore ricevuto: sono le due informazioni che chi sta davanti allo schermo non ha. Vale per i programmi e vale per i messaggi di NORA, ed è la stessa idea del feedback formativo di questo gioco: descrivere il sistema, non giudicare chi lo usa."}],
	"glossario": [
		{"voce": "ciclo di validazione", "spiega": "while che ripete la domanda finché la risposta non è valida. Il controllo deve rifarsi sul valore nuovo, o non finisce mai."},
		{"voce": "valore sentinella", "spiega": "Un valore convenuto che significa «ho finito». Va controllato prima di essere usato, o entra nei conti."},
		{"voce": "messaggio utile", "spiega": "Dice il vincolo e il valore ricevuto. Sono le due cose che chi sbaglia non conosce."}],
	"esempi": [
		{"prompt": "n = 0\nt = 0\nv = input()\nwhile v != \"fine\":\n    t = t + int(v)\n    n = n + 1\n    v = input()\n\n(vengono scritti 4, 6, fine)", "answer": "t vale 10 e n vale 2",
		 "explanation": "Il controllo avviene prima di usare il valore, quindi la parola fine non entra mai nella somma né nel conteggio."},
		{"prompt": "v = input()\nwhile not v.isdigit():\n    v = input()\nprint(int(v) * 2)\n\n(vengono scritti ciao e poi 7)", "answer": "14",
		 "explanation": "Il ciclo rilegge dentro il corpo, quindi il controllo del giro dopo esamina il valore NUOVO e il ciclo può finire."}],
	"metodo": "In un ciclo di validazione controlla sempre che dentro il corpo ci sia una lettura nuova. Se il corpo non rilegge, la condizione esamina per sempre lo stesso valore e il ciclo non finisce.",
	"errore": {"wrong": "Contare la sentinella insieme ai dati.",
		"why": "La sentinella significa «ho finito», non è un dato: sommata o conteggiata sposta il risultato, e nessun errore lo segnala."},
	"insegna": ["ciclo di validazione", "sentinella"]},

# =============================================================== OUTPUT · base
"coding-output-base": {
	"subject": "coding", "topic": "output", "fasce": BANDA_BASE,
	"titolo": "L'unico modo di vedere che cosa sta pensando il programma",
	"apertura": "Un programma che calcola e non stampa niente, da fuori, è indistinguibile da uno che non fa niente. print è la finestra.",
	"sezioni": [
		{"titolo": "print mostra quello che riceve, e va a capo",
		 "testo": "print(x) scrive a schermo il valore di x e poi va a capo, quindi due print producono due righe. Con le virgolette stampa il testo così com'è, senza: cerca la variabile con quel nome e stampa il suo contenuto. È la differenza fra il nome e la cosa, e si vede meglio in due righe vicine: con x = 7, print(\"x\") scrive la lettera x mentre print(x) scrive 7. Le virgolette stesse non compaiono mai a schermo: servono a scrivere il testo nel codice, non a mostrarlo."},
		{"titolo": "Più valori in una print, separati da virgole",
		 "testo": "print(\"Totale:\", 12) stampa «Totale: 12» — la virgola dentro print mette automaticamente uno spazio fra un valore e l'altro, e questo è il motivo per cui conviene usarla invece del più: la virgola accetta valori di qualsiasi tipo e li converte da sola, mentre il più fra una stringa e un numero ferma il programma. Con tre valori gli spazi automatici sono due, uno fra ogni coppia."},
		{"titolo": "Stampare per capire",
		 "testo": "L'uso più importante di print non è mostrare il risultato: è capire un difetto. Quando un programma fa una cosa che non ci si aspetta, si mettono delle print a metà strada per vedere quanto valgono davvero le variabili in quel punto. Quasi sempre una di loro è diversa da come si credeva, e il difetto si trova prima ancora di aver capito il perché. Conviene stampare anche il nome, così: print(\"qui n vale\", n) — cinque print che dicono solo dei numeri nudi non si distinguono più fra loro."}],
	"glossario": [
		{"voce": "print(x)", "spiega": "Stampa il contenuto della variabile x e va a capo. Con le virgolette attorno stamperebbe la lettera x."},
		{"voce": "print(a, b)", "spiega": "Più valori separati da virgole: fra l'uno e l'altro compare uno spazio automatico, e i tipi non devono coincidere."},
		{"voce": "print di controllo", "spiega": "Una stampa messa a metà del codice per vedere quanto valgono davvero le variabili. Il primo strumento contro un difetto."}],
	"esempi": [
		{"prompt": "x = 7\nprint(\"x\")", "answer": "x",
		 "explanation": "Le virgolette rendono la x un testo: print mostra la lettera, non va a cercare nessuna variabile."},
		{"prompt": "print(\"Punti:\", 3)", "answer": "Punti: 3",
		 "explanation": "La virgola dentro print inserisce da sola uno spazio fra i due valori, e accetta tipi diversi senza conversioni."}],
	"metodo": "Davanti a una print guarda prima le virgolette: quello che sta dentro esce tale e quale, quello che sta fuori viene prima cercato e poi stampato.",
	"errore": {"wrong": "Scrivere print(\"totale\") aspettandosi il valore della variabile totale.",
		"why": "Le virgolette dichiarano testo: Python stampa le sette lettere senza cercare nessuna variabile, e non segnala niente perché la riga è valida."},
	"insegna": ["print(", "print(a, b)"]},

# =============================================================== OUTPUT · alta
"coding-output-alta": {
	"subject": "coding", "topic": "output", "fasce": BANDA_ALTA,
	"titolo": "Dare forma a quello che esce",
	"apertura": "Quando i valori da mostrare sono molti, il come conta quanto il che cosa: un tabulato leggibile si ottiene con due strumenti.",
	"sezioni": [
		{"titolo": "Le f-string mettono i valori dentro il testo",
		 "testo": "Anteponendo una f alle virgolette, tutto ciò che sta fra parentesi graffe dentro la stringa viene sostituito con il suo valore: f\"Hai {punti} punti\" produce «Hai 12 punti» quando punti vale 12. Dentro le graffe può stare anche un conto, come {a + b}. È più leggibile della somma di pezzi, perché la frase si legge tutta intera nell'ordine in cui uscirà, e non ha il problema dei tipi: i valori vengono convertiti da soli."},
		{"titolo": "Controllare il separatore e il fine riga",
		 "testo": "print accetta due indicazioni: sep dice che cosa mettere fra i valori al posto dello spazio, ed end dice che cosa mettere alla fine al posto dell'a capo. print(a, b, sep=\"-\") scrive i due valori uniti da un trattino; print(x, end=\" \") lascia il cursore sulla stessa riga, ed è il modo di stampare una sequenza di valori in orizzontale dentro un ciclo. Senza end, un ciclo che stampa dieci numeri produce dieci righe."},
		{"titolo": "Quante cifre dopo la virgola",
		 "testo": "Un float stampato senza indicazioni esce con tutte le cifre che ha, e una media può uscire con quindici decimali. Dentro una f-string si può chiedere quante cifre mostrare scrivendo due punti e il formato: f\"{media:.2f}\" arrotonda a due decimali per la stampa. È importante sapere che arrotonda solo QUELLO CHE SI VEDE: il valore nella variabile resta quello di prima, con tutte le sue cifre, e i conti successivi useranno quello. Per cambiare davvero il numero serve round()."}],
	"glossario": [
		{"voce": "f\"...{x}...\"", "spiega": "f-string: quello che sta fra graffe viene sostituito con il suo valore, conversioni comprese."},
		{"voce": "end=\"\"", "spiega": "Dice a print che cosa mettere alla fine invece dell'a capo. Serve a stampare in orizzontale dentro un ciclo."},
		{"voce": "{x:.2f}", "spiega": "Mostra due decimali. Arrotonda solo la stampa: il valore nella variabile non cambia."}],
	"esempi": [
		{"prompt": "n = 3\nprint(f\"ho {n} mele\")", "answer": "ho 3 mele",
		 "explanation": "La f davanti alle virgolette attiva le graffe: il nome dentro viene sostituito con il suo valore al momento della stampa."},
		{"prompt": "for i in range(3):\n    print(i, end=\" \")", "answer": "0 1 2",
		 "explanation": "end sostituisce l'a capo con uno spazio, quindi i tre valori restano sulla stessa riga invece di occuparne tre."}],
	"metodo": "Se l'uscita è illeggibile, non cambiare i calcoli: cambia sep, end e il numero di decimali. Il difetto della forma non sta quasi mai nei conti.",
	"errore": {"wrong": "Credere che f\"{x:.2f}\" abbia arrotondato la variabile.",
		"why": "Il formato riguarda solo la stampa: nella variabile il numero resta intero di cifre, e i conti dopo useranno quello. Per cambiarlo serve round()."},
	"insegna": ["f\"", "end=", "sep=", ":.2f", "round("]},

# ================================================================ STILE · base
"coding-stile-base": {
	"subject": "coding", "topic": "stile", "fasce": BANDA_BASE,
	"titolo": "Il codice si legge molte più volte di quante si scrive",
	"apertura": "E quasi sempre lo rilegge qualcuno che non ricorda perché lo ha scritto: cioè tu, fra un mese.",
	"sezioni": [
		{"titolo": "I nomi dicono il significato, non il tipo",
		 "testo": "prezzo dice più di numero2, e giorni_rimasti dice più di n. Un buon nome è quello che permette di leggere una riga senza tornare indietro a cercare dove la variabile è stata creata: se leggendo totale = prezzo * quantita si capisce tutto senza scorrere, i nomi sono giusti. In Python i nomi si scrivono in minuscolo con le parole separate da trattino basso — giorni_rimasti — e questa non è una regola del linguaggio ma una convenzione che tutti seguono, il che è quasi la stessa cosa: il codice scritto in un altro modo rallenta chiunque lo legga. Le uniche abbreviazioni ammesse senza pensarci sono i contatori dei cicli, i e j, che tutti conoscono."},
		{"titolo": "Il rientro è sintassi, non ordine",
		 "testo": "In quasi tutti i linguaggi il rientro è una cortesia; in Python è il modo in cui si dice dove comincia e dove finisce un blocco. Quattro spazi per livello è lo standard, e mescolare spazi e tabulazioni produce errori che non si vedono perché il codice sembra allineato. Ne segue una conseguenza utile: in Python un codice mal indentato non è brutto, è rotto — e questo toglie di mezzo per sempre una discussione che negli altri linguaggi non finisce mai."},
		{"titolo": "I commenti dicono il perché",
		 "testo": "Un commento che ripete quello che il codice già dice — «# aumenta i di uno» accanto a i = i + 1 — occupa spazio e invecchia male: quando qualcuno cambierà quella riga, il commento resterà a dire una cosa falsa. Il commento utile spiega il PERCHÉ: perché quel valore è 7 e non 10, quale caso strano ha costretto a scrivere il codice così, che cosa si è provato prima. Se una riga ha bisogno di un commento per essere capita, spesso la soluzione migliore è un nome diverso invece del commento."}],
	"glossario": [
		{"voce": "nome parlante", "spiega": "Un nome che dice il significato del valore, non il suo tipo: prezzo, non numero2."},
		{"voce": "snake_case", "spiega": "La convenzione dei nomi in Python: minuscolo e parole separate da trattino basso."},
		{"voce": "commento", "spiega": "Testo dopo il cancelletto, ignorato da Python. Serve a dire il perché, non a ripetere il codice."}],
	"esempi": [
		{"prompt": "Quale nome è migliore per il numero di biglietti venduti: n, x2, o biglietti_venduti?", "answer": "biglietti_venduti",
		 "explanation": "Permette di leggere le righe che lo usano senza tornare indietro a cercare che cosa contiene, ed è scritto nella convenzione di Python."},
		{"prompt": "Quale dei due commenti è utile?\n# aggiunge 1 a i\ni = i + 1\n\n# il sensore conta da 1, non da 0\ni = i + 1", "answer": "il secondo",
		 "explanation": "Il primo ripete quello che la riga già dice; il secondo spiega la ragione per cui quella riga esiste, che dal codice non si può dedurre."}],
	"metodo": "Rileggi il tuo codice come se lo avesse scritto un altro: ogni volta che devi tornare indietro per ricordarti che cosa contiene una variabile, quel nome va cambiato.",
	"errore": {"wrong": "Commentare ogni riga con quello che la riga fa.",
		"why": "Raddoppia il testo senza aggiungere informazione, e alla prima modifica il commento resta indietro e comincia a dire il falso."},
	"insegna": ["#", "snake_case", "quattro spazi"]},

# ================================================================ STILE · alta
"coding-stile-alta": {
	"subject": "coding", "topic": "stile", "fasce": BANDA_ALTA,
	"titolo": "Togliere la ripetizione, e i numeri senza nome",
	"apertura": "Due difetti che non fermano nessun programma e che rendono impossibile cambiarlo: il codice copiato e il numero scritto a mano.",
	"sezioni": [
		{"titolo": "Se stai per copiare e incollare, lì serve una funzione",
		 "testo": "Due blocchi quasi uguali che differiscono per un valore sono una funzione con un parametro che nessuno ha ancora scritto. Il problema del codice duplicato non è la lunghezza: è che le copie invecchiano in modo diverso. Chi corregge un difetto ne trova una sola e lascia le altre rotte, e il programma comincia a comportarsi in modo diverso in punti che dovrebbero essere identici. La regola pratica: alla seconda copia si tollera, alla terza si estrae. E il nome della funzione estratta è sempre facile da trovare, perché è la frase che si direbbe per spiegare che cosa fa quel blocco."},
		{"titolo": "I numeri magici",
		 "testo": "Un numero scritto direttamente in mezzo al codice — if eta > 17 — non dice perché è proprio quello. Chi legge non sa se 17 è la maggiore età, il numero di posti disponibili o una soglia scelta a caso, e chi deve cambiarlo deve trovarne tutte le occorrenze sperando di non confonderle con altri 17 che significano altro. La cura è una variabile con un nome: ETA_MINIMA = 18 scritto una volta in alto, e usato ovunque serva. Il valore si cambia in un posto solo, e ogni riga che lo usa diventa leggibile da sola."},
		{"titolo": "Una funzione fa una cosa",
		 "testo": "Il segnale più affidabile che una funzione è troppo grande è il suo nome: se per descriverla bisogna usare una «e» — «calcola il totale E lo stampa» — dentro ci sono due funzioni. Separarle ha un vantaggio concreto oltre alla leggibilità: la parte che calcola, non stampando niente, si può usare in altri posti e si può provare da sola. Le funzioni che mescolano calcolo e stampa sono quelle che non si riescono a riutilizzare mai."}],
	"glossario": [
		{"voce": "duplicazione", "spiega": "Lo stesso codice in due posti. Il difetto non è la lunghezza: è che una copia verrà corretta e l'altra no."},
		{"voce": "numero magico", "spiega": "Un valore scritto in mezzo al codice senza un nome che dica perché è quello."},
		{"voce": "responsabilità singola", "spiega": "Una funzione fa una cosa. Se il nome ha bisogno di una «e», dentro ce ne sono due."}],
	"esempi": [
		{"prompt": "Due blocchi identici calcolano lo sconto, uno con 10 e uno con 20. Che cosa conviene fare?", "answer": "una funzione con la percentuale come parametro",
		 "explanation": "L'unica differenza è un valore, ed è esattamente il lavoro di un parametro: una sola copia del calcolo, e una correzione che vale per tutti i casi."},
		{"prompt": "Perché conviene scrivere ETA_MINIMA = 18 invece di usare 18 nel codice?", "answer": "per cambiarlo in un posto solo e dire perché è quello",
		 "explanation": "Il nome spiega il significato a chi legge, e il valore raccolto in un punto solo evita la caccia alle occorrenze quando cambia."}],
	"metodo": "Prima di aggiungere codice nuovo, cerca se quello che stai per scrivere esiste già da qualche altra parte del programma. Quasi sempre esiste, e quasi sempre è quasi uguale.",
	"errore": {"wrong": "Correggere un difetto in una copia sola del codice duplicato.",
		"why": "Le altre copie restano rotte, e il programma si comporta in modo diverso in punti che sembrano identici: è il difetto più lungo da trovare."},
	"insegna": ["costante con nome", "estrazione di funzione"]},

# ============================================================ ALGORITMI · base
"coding-algoritmi-base": {
	"subject": "coding", "topic": "algoritmi", "fasce": BANDA_BASE,
	"titolo": "Una sequenza che funziona anche se la esegue qualcun altro",
	"apertura": "Un algoritmo è un elenco di passi che porta sempre allo stesso risultato, anche se a eseguirlo è qualcuno che non sa che cosa stai cercando di ottenere.",
	"sezioni": [
		{"titolo": "Le tre proprietà che distinguono un algoritmo da un elenco",
		 "testo": "Primo: i passi sono ORDINATI, e cambiarli di posto cambia il risultato — mettere il caffè prima dell'acqua non è la stessa cosa. Secondo: ogni passo è NON AMBIGUO, cioè si può eseguire senza chiedere niente a nessuno: «aggiungi un po' di sale» non è un passo, «aggiungi un cucchiaino di sale» sì. Terzo: l'esecuzione TERMINA, cioè prima o poi finisce. Una ricetta che dice «mescola finché non è pronto» senza dire come si riconosce il pronto non è un algoritmo, perché chi la esegue non sa quando fermarsi. Il difetto più comune è il secondo: chi scrive conosce già il risultato e lascia dei sottintesi che solo lui può riempire."},
		{"titolo": "Lo schema più usato: scorri e tieni il migliore",
		 "testo": "Per trovare il massimo di una lista non serve confrontare tutti con tutti. Si tiene una casella con il migliore visto finora, la si riempie con il primo elemento, e poi si scorre il resto: ogni volta che se ne incontra uno più grande, si sostituisce. Alla fine la casella contiene il massimo, e la lista è stata percorsa una volta sola. Lo stesso schema con il confronto rovesciato dà il minimo, con una somma dà il totale, con un contatore dà «quanti ne soddisfano una condizione». Imparato una volta, serve per sempre."},
		{"titolo": "La ricerca: da un capo, o tagliando a metà",
		 "testo": "Cercare un elemento in una lista qualsiasi vuol dire guardarli uno per uno finché non lo si trova: nel caso peggiore si guardano tutti. Ma se la lista è già ORDINATA si può fare molto meglio: si guarda quello in mezzo, e se non è quello giusto si sa da che parte continuare, buttando via metà lista in un colpo solo. Ripetendo, su mille elementi bastano dieci confronti invece di mille. Il prezzo è la condizione: la lista deve essere ordinata, e se non lo è questo metodo dà risposte sbagliate senza segnalare niente."}],
	"glossario": [
		{"voce": "algoritmo", "spiega": "Sequenza di passi ordinati, non ambigui e che termina. Chi lo esegue non deve dover indovinare niente."},
		{"voce": "accumulatore", "spiega": "La casella che tiene il risultato parziale mentre si scorre: il migliore finora, il totale finora, il conteggio finora."},
		{"voce": "ricerca a metà", "spiega": "Su una lista ordinata, guardare l'elemento centrale e buttare via la metà sbagliata. Dieci passi per mille elementi."}],
	"esempi": [
		{"prompt": "Per trovare il numero più grande in una lista di 100 numeri, quanti confronti servono con lo schema «tieni il migliore»?", "answer": "99",
		 "explanation": "Il primo riempie la casella senza confronti, e ognuno dei 99 successivi viene confrontato una volta sola con il migliore finora."},
		{"prompt": "Perché «mescola finché non è pronto» non è un passo valido di un algoritmo?", "answer": "perché non dice come si riconosce il pronto",
		 "explanation": "Chi esegue non può sapere quando fermarsi: il passo è ambiguo, e l'esecuzione non ha una fine definita."}],
	"metodo": "Prova a eseguire l'algoritmo tu, alla lettera, facendo solo ciò che c'è scritto e niente di quello che sai. Il primo punto in cui devi indovinare è il difetto.",
	"errore": {"wrong": "Lasciare un passo che richiede di sapere già il risultato.",
		"why": "Chi esegue non ha quella conoscenza: il passo è ambiguo, e l'algoritmo funziona solo nelle mani di chi lo ha scritto."},
	"insegna": ["accumulatore", "ricerca lineare", "ricerca a metà"]},

# ============================================================ ALGORITMI · alta
"coding-algoritmi-alta": {
	"subject": "coding", "topic": "algoritmi", "fasce": BANDA_ALTA,
	"titolo": "Quanto costa, e perché il conto si fa sui giri",
	"apertura": "Due programmi che danno la stessa risposta possono metterci un secondo o un'ora. La differenza si prevede contando i giri, senza eseguire niente.",
	"sezioni": [
		{"titolo": "Il costo si misura in giri, non in secondi",
		 "testo": "Un secondo su questa macchina è mezzo secondo sulla prossima, quindi misurare il tempo non dice niente sull'algoritmo. Si contano invece i giri in funzione di quanto è grande il problema. Un ciclo solo su n elementi fa n giri: raddoppiando i dati raddoppia il lavoro, e si dice che il costo è lineare. Due cicli annidati fanno n per n giri: raddoppiando i dati il lavoro diventa quattro volte tanto, e su diecimila elementi sono cento milioni di giri, cioè il punto in cui un programma smette di essere utilizzabile. Tagliare a metà ogni volta dà il costo logaritmico, il più economico che si incontri a questo livello: su un milione di elementi bastano venti passi."},
		{"titolo": "Il caso peggiore è quello che conta",
		 "testo": "Una ricerca lineare può trovare l'elemento al primo colpo, ma fare il conto su quel caso non dice niente di utile: la fortuna non è una proprietà dell'algoritmo. Si misura il caso PEGGIORE — l'elemento non c'è, e sono stati guardati tutti — perché è l'unica garanzia che si può dare. E spesso il caso peggiore capita proprio quando conta: l'elemento assente è esattamente la situazione in cui un programma deve rispondere in fretta a molte richieste."},
		{"titolo": "Ordinare costa, e a volte conviene lo stesso",
		 "testo": "La ricerca a metà pretende una lista ordinata, e ordinare costa più di una singola ricerca lineare. Quindi per cercare UNA volta sola in una lista disordinata, ordinarla prima è una perdita netta. Ma se le ricerche saranno mille, il costo dell'ordinamento si paga una volta e si divide su tutte: è il ragionamento che sta dietro a ogni indice, in ogni archivio e in ogni banca dati. La domanda giusta non è mai «quale metodo è più veloce», è «quante volte lo farò»."}],
	"glossario": [
		{"voce": "costo lineare", "spiega": "Un ciclo su n elementi: n giri. Raddoppiando i dati, raddoppia il lavoro."},
		{"voce": "costo quadratico", "spiega": "Due cicli annidati: n per n giri. Raddoppiando i dati, il lavoro diventa quattro volte tanto."},
		{"voce": "caso peggiore", "spiega": "Il conto si fa sulla situazione più sfortunata, perché è l'unica garanzia che un algoritmo può dare."}],
	"esempi": [
		{"prompt": "Due cicli annidati su 1000 elementi ciascuno: quanti giri fa il corpo interno?", "answer": "1000000",
		 "explanation": "Quello interno riparte per intero a ogni giro di quello esterno, quindi i giri si moltiplicano: mille per mille."},
		{"prompt": "Serve cercare un elemento una sola volta in una lista disordinata di 1000 numeri. Conviene ordinarla prima?", "answer": "no",
		 "explanation": "Ordinare costa più della ricerca stessa, e il vantaggio si recupera solo dividendolo su molte ricerche successive."}],
	"metodo": "Conta i cicli annidati prima di leggere che cosa fanno: uno è lineare, due è quadratico, e un taglio a metà a ogni passo è logaritmico. Il numero dice già se il programma reggerà.",
	"errore": {"wrong": "Giudicare un algoritmo dal tempo che ci mette su un esempio piccolo.",
		"why": "Su pochi dati tutti gli algoritmi sembrano veloci: la differenza fra lineare e quadratico si vede solo quando i dati crescono, ed è allora che è troppo tardi."},
	"insegna": ["costo lineare", "costo quadratico", "caso peggiore"]},

# ==============================================================================
# STORIA — la seconda materia convertita (11 settembre 2026)
#
# **Qui la regola mostra la sua forma vera.** Richiesta del committente: «nella
# storia si deve preparare un documento da presentare allo studente dove si
# racconta un contesto preciso e dettagliato. Solo dopo si può fare una domanda.»
#
# In coding le sezioni spiegano un meccanismo; qui **raccontano**: dove, quando,
# chi comandava, che cosa stava cambiando, che cosa è successo dopo. La differenza
# non è di stile. «In che anno cadde l'Impero Romano d'Occidente?» senza racconto
# è una domanda a cui o si sa rispondere o non si sa — la definizione di domanda
# inutile. Dentro un racconto, la stessa data ha un prima e un dopo, e chi non la
# ricorda può ricostruirla.
#
# Le tavole di riferimento non spariscono e non vengono ripetute: restano la
# linea del tempo su cui il racconto si appoggia, cioè la figura del documento.
# Le date qui sotto sono le stesse di `TAVOLE_STORIA`, controllate una per una.
#
# Nove argomenti, diciassette dispense: `medioevo` ne ha una sola perché il banco
# lo interroga soltanto alle fasce 6, 7 e 8. Scriverne una per la banda bassa
# sarebbe stato contenuto scritto e mai collegato.

# ========================================================== PREISTORIA · base
"storia-preistoria-base": {
	"subject": "storia", "topic": "preistoria", "fasce": BANDA_BASE,
	"titolo": "Due milioni di anni senza una riga scritta",
	"apertura": "Il tratto più lungo della storia dell'uomo è anche quello di cui sappiamo meno, e per una ragione sola: nessuno l'ha raccontato.",
	"sezioni": [
		{"titolo": "Perché si chiama preistoria",
		 "testo": "«Preistoria» vuol dire prima della storia scritta, e il confine è preciso: finisce intorno al 3300 a.C., quando in Mesopotamia compaiono i primi segni incisi sull'argilla. Prima di quel momento nessuno ha lasciato scritto niente, quindi tutto quello che sappiamo lo dicono gli OGGETTI: una punta di pietra, i resti di un fuoco, le ossa degli animali mangiati, una sepoltura. Gli oggetti però non spiegano: dicono che cosa è stato fatto, non perché. Un archeologo può stabilire che una pietra è stata scheggiata e come, e deve invece ipotizzare a che cosa serviva. È il motivo per cui in preistoria le frasi prudenti — «probabilmente», «si ritiene» — non sono timidezza, sono onestà."},
		{"titolo": "Il Paleolitico: il cibo si prende dov'è",
		 "testo": "Paleolitico significa «pietra antica», e il nome dice la tecnica: la pietra si SCHEGGIA, colpendola per ricavarne un filo tagliente. Si vive di caccia e di raccolta, cioè si prende il cibo dove si trova, e per questo si è nomadi: finito il cibo in un posto ci si sposta, perché non c'è nessun modo di farne crescere dell'altro. Si ripara nelle caverne e sotto sporgenze di roccia. Circa 400.000 anni fa arriva il fuoco, ed è la svolta più grande di tutto il periodo: cuocere rende mangiabili cibi che crudi non lo sono, il calore permette di vivere dove fa freddo, e la luce allunga la giornata. È la prima volta che l'uomo cambia l'ambiente invece di subirlo."},
		{"titolo": "Il Neolitico: il cibo si produce, e allora si resta",
		 "testo": "Circa 10.000 anni fa cambia tutto, e non per un'invenzione tecnica: per un'idea. Invece di cercare le piante buone, si seminano; invece di inseguire gli animali, se ne tengono alcuni vicino. Nascono agricoltura e allevamento, e il nome del periodo — Neolitico, «pietra nuova» — segna intanto una tecnica diversa: la pietra si LEVIGA, strofinandola fino a renderla liscia. Ma la conseguenza importante è un'altra: chi semina deve tornare a raccogliere, quindi coltivare vuol dire restare. Da lì nascono le case fisse, i primi villaggi e le scorte — e con le scorte, per la prima volta nella storia, qualcuno che le custodisce e qualcuno che le conta."}],
	"glossario": [
		{"voce": "preistoria", "spiega": "Il tempo prima della scrittura. Non «prima dell'uomo»: l'uomo c'è, e non lascia testi."},
		{"voce": "Paleolitico", "spiega": "«Pietra antica»: si scheggia la pietra, si vive di caccia e raccolta, ci si sposta."},
		{"voce": "Neolitico", "spiega": "«Pietra nuova»: si leviga la pietra, nascono agricoltura e allevamento, ci si ferma."},
		{"voce": "nomade", "spiega": "Chi si sposta seguendo il cibo. È una conseguenza del modo di procurarselo, non una scelta."}],
	"esempi": [
		{"prompt": "Perché gli uomini del Paleolitico erano nomadi?", "answer": "Perché seguivano gli animali e le stagioni",
		 "explanation": "Il cibo si prendeva dove si trovava, e quando finiva in un posto non c'era modo di farne crescere dell'altro: restare non era possibile."},
		{"prompt": "Che cosa distingue il Paleolitico dal Neolitico?", "answer": "Nel Neolitico nascono agricoltura e allevamento",
		 "explanation": "La lavorazione della pietra cambia, ma la differenza che conta è il cibo: prima si prende, poi si produce — e chi produce resta."}],
	"metodo": "Il nome di ogni periodo della preistoria dice che cosa si sapeva FARE, non che cosa è successo. Letto così, «pietra antica» e «pietra nuova» smettono di essere due etichette da imparare a memoria.",
	"errore": {"wrong": "Credere che «preistoria» significhi «prima che ci fossero gli uomini».",
		"why": "Gli uomini ci sono per tutti quei millenni, e fanno cose complicatissime: quello che manca è la scrittura, cioè il loro racconto."},
	"insegna": ["Paleolitico", "Neolitico", "il fuoco", "caccia e raccolta", "nomadi"]},

# ========================================================== PREISTORIA · alta
"storia-preistoria-alta": {
	"subject": "storia", "topic": "preistoria", "fasce": BANDA_ALTA,
	"titolo": "Le pitture, le pietre piantate e i metalli",
	"apertura": "Tre cose che gli oggetti dicono chiaramente e non spiegano affatto, e il modo in cui uno storico ci lavora sopra.",
	"sezioni": [
		{"titolo": "Le pitture rupestri, e perché non sono decorazioni",
		 "testo": "Sulle pareti di alcune grotte — Lascaux in Francia, Altamira in Spagna — ci sono animali dipinti con ocra e carbone, bisonti, cavalli, cervi, disegnati con una precisione che sorprende ancora. Tre osservazioni fanno scartare l'idea che siano un abbellimento. Primo: quasi tutte stanno nelle parti PROFONDE e buie della grotta, dove nessuno viveva e dove bisognava portarsi il fuoco apposta. Secondo: le figure umane sono rarissime, mentre gli animali sono moltissimi. Terzo: in diversi casi sono state ridipinte più volte nello stesso punto. Da qui l'ipotesi che avessero un valore rituale e simbolico — legato alla caccia, forse propiziatorio. Resta un'ipotesi: nessuno ha lasciato scritto perché le faceva, ed è esattamente il limite della preistoria."},
		{"titolo": "I megaliti: pietre enormi, e quello che implicano",
		 "testo": "Nel Neolitico compaiono i megaliti, cioè costruzioni di pietre grandissime. Un menhir è una grande pietra piantata verticalmente nel terreno; un dolmen è formato da due o più pietre verticali con una lastra appoggiata sopra, come un tavolo. A Stonehenge, in Inghilterra, le pietre sono disposte in cerchio e allineate con il punto in cui sorge il sole nel giorno più lungo dell'anno: servivano anche a misurare l'anno. Ma la cosa che dice di più è il peso: spostare pietre di decine di tonnellate senza ruote e senza metalli richiede centinaia di persone che lavorano insieme per anni, e quindi qualcuno che le organizzi, le nutra e le comandi. Il megalite non racconta una religione: racconta una società."},
		{"titolo": "L'Età dei metalli, e il commercio che ne nasce",
		 "testo": "Dal 3500 a.C. circa si impara a fondere i metalli: prima il rame, poi il bronzo — che è rame mescolato a stagno — e molto dopo il ferro. Ogni età prende il nome dal metallo che si sapeva lavorare. Il salto tecnico è evidente: un'ascia di bronzo taglia meglio e dura più di una di pietra, e si può rifondere invece di buttarla. Ma la conseguenza più profonda è commerciale, e nasce da un dettaglio geografico: lo stagno non si trova dove si trova il rame. Per fare il bronzo bisogna quindi scambiare a grande distanza, e nascono rotte, intermediari e ricchezze che non vengono dalla terra. Chi controlla il metallo comincia a comandare su chi non ce l'ha."}],
	"glossario": [
		{"voce": "menhir", "spiega": "Una grande pietra piantata verticalmente nel terreno. Dal bretone: «pietra lunga»."},
		{"voce": "dolmen", "spiega": "Pietre verticali con una lastra appoggiata sopra, a forma di tavolo. Spesso una sepoltura."},
		{"voce": "rituale", "spiega": "Legato a un gesto che si ripete per un significato, non per un'utilità immediata."},
		{"voce": "bronzo", "spiega": "Rame mescolato a stagno. I due metalli non si trovano negli stessi posti: per farlo serve commerciare."}],
	"esempi": [
		{"prompt": "A che cosa servivano probabilmente le pitture rupestri?", "answer": "Avevano un valore rituale e simbolico",
		 "explanation": "Stanno nelle parti profonde e buie delle grotte, dove non si viveva e bisognava portare il fuoco apposta: non erano lì per essere guardate tutti i giorni."},
		{"prompt": "Perché la lavorazione dei metalli segna una svolta?", "answer": "Perché dà strumenti migliori e nuovi scambi",
		 "explanation": "Gli attrezzi tagliano di più e si rifondono; e poiché stagno e rame non stanno negli stessi luoghi, il bronzo obbliga a commerciare lontano."}],
	"metodo": "Davanti a un oggetto preistorico fatti due domande in quest'ordine: che cosa è servito per costruirlo, e chi ha dovuto mettersi d'accordo con chi. La seconda risposta racconta più della prima.",
	"errore": {"wrong": "Dire che le pitture rupestri servivano a decorare la casa.",
		"why": "Non stanno dove si abitava ma nelle gallerie profonde, al buio: chi le faceva doveva andarci apposta con una fonte di luce."},
	"insegna": ["menhir", "dolmen", "pitture rupestri", "bronzo", "Età dei metalli"]},

# ============================================================ CIVILTA · base
"storia-civilta-base": {
	"subject": "storia", "topic": "civilta", "fasce": BANDA_BASE,
	"titolo": "Perché le prime città nascono tutte in riva a un fiume",
	"apertura": "Mesopotamia, Egitto, valle dell'Indo, Fiume Giallo: quattro civiltà lontanissime fra loro, nate nello stesso modo e per lo stesso motivo.",
	"sezioni": [
		{"titolo": "Il fiume non è un dettaglio: è la causa",
		 "testo": "Le prime grandi civiltà nascono tutte vicino a un grande fiume, e non è una coincidenza né una preferenza estetica. Un fiume dà tre cose insieme, e nessuna delle tre da sola basterebbe. Primo, l'acqua per irrigare: con i canali si coltiva anche dove piove poco, e si coltiva quando serve invece che quando capita. Secondo, il limo: le piene depositano sui campi un fango ricchissimo che rifà la fertilità del terreno ogni anno, gratis. Terzo, la strada: prima delle strade vere, il modo più economico di spostare pesi è galleggiare, e un fiume è una via che scorre da sola. Messe insieme, queste tre cose producono un raccolto più grande di quello che serve a chi lo coltiva — e quel «più grande» cambia tutto."},
		{"titolo": "Dall'eccedenza nasce tutto il resto",
		 "testo": "Finché ogni famiglia produce appena il cibo che le serve, tutti devono coltivare. Quando invece il raccolto avanza, il cibo in più può mantenere qualcuno che NON coltiva: un artigiano che fa vasi tutto il giorno e diventa bravissimo, un sacerdote, un soldato, un funzionario che tiene il conto dei magazzini. Nascono così i mestieri specializzati, e con loro le differenze: chi controlla i magazzini ha un potere che prima non esisteva, perché in una carestia decide lui. È in questo passaggio che compaiono le città vere, i re e le prime forme di stato. La parola «civiltà» viene proprio da lì: dal latino *civis*, cittadino, cioè chi vive in città."},
		{"titolo": "La scrittura, e il fatto che nasce per contare",
		 "testo": "Intorno al 3300 a.C., in Mesopotamia — la terra fra i fiumi Tigri ed Eufrate — i Sumeri cominciano a incidere segni su tavolette di argilla fresca con una cannuccia dalla punta a cuneo: per questo la loro scrittura si chiama cuneiforme. Le prime tavolette non raccontano storie né preghiere: sono ricevute. Tanti sacchi di grano entrati, tante pecore uscite, tanto olio dovuto. La scrittura nasce come strumento di magazzino, e solo dopo, molto dopo, impara a raccontare. Ed è comunque l'invenzione che segna il passaggio dalla preistoria alla storia, perché da quel momento gli uomini dicono da soli quello che fanno, e non dobbiamo più indovinarlo dagli oggetti."}],
	"glossario": [
		{"voce": "civiltà", "spiega": "Da *civis*, cittadino: una società con città, mestieri specializzati e un'organizzazione che li tiene insieme."},
		{"voce": "Mesopotamia", "spiega": "«Terra fra i fiumi», il Tigri e l'Eufrate. È lì che nascono Sumeri e Babilonesi."},
		{"voce": "eccedenza", "spiega": "Il cibo che avanza dopo aver nutrito chi lo ha prodotto. È quello che mantiene chi non coltiva."},
		{"voce": "cuneiforme", "spiega": "La scrittura dei Sumeri, incisa sull'argilla con una punta a cuneo. Serviva a registrare merci."}],
	"esempi": [
		{"prompt": "Che cosa hanno in comune le prime grandi civiltà?", "answer": "Sono nate vicino a grandi fiumi",
		 "explanation": "Il fiume dà irrigazione, limo fertile e trasporto: insieme producono un raccolto che avanza, e l'eccedenza permette mestieri che non siano coltivare."},
		{"prompt": "A cosa servivano i primi segni di scrittura in Mesopotamia?", "answer": "A registrare merci e magazzini",
		 "explanation": "Le prime tavolette sono ricevute di grano e di bestiame: la scrittura nasce come strumento di conto, e impara a raccontare solo più tardi."}],
	"metodo": "Davanti a una civiltà antica cerca prima il fiume, poi il magazzino, poi chi lo controlla. Quasi tutto quello che quella civiltà ha inventato sta a valle di questi tre.",
	"errore": {"wrong": "Pensare che la scrittura sia nata per tramandare racconti e poesie.",
		"why": "Le prime tavolette sumere sono elenchi di merci: nasce dal bisogno di tenere il conto, e i testi narrativi arrivano secoli dopo."},
	"insegna": ["Mesopotamia", "Sumeri", "la scrittura", "cuneiforme", "eccedenza"]},

# ============================================================ CIVILTA · alta
"storia-civilta-alta": {
	"subject": "storia", "topic": "civilta", "fasce": BANDA_ALTA,
	"titolo": "Tre invenzioni che spostano il potere",
	"apertura": "La ruota, le leggi scritte e l'alfabeto. Tutte e tre servono a qualcosa di pratico, e tutte e tre finiscono per cambiare chi comanda.",
	"sezioni": [
		{"titolo": "L'aratro e la ruota: produrre di più, portarlo lontano",
		 "testo": "L'aratro trainato da animali rivolta la terra molto più in profondità di una zappa, e permette a una sola famiglia di coltivare una superficie che a mano sarebbe impensabile: moltiplica il raccolto. La ruota, che compare in Mesopotamia intorno al 3500 a.C., risolve il problema opposto: non produrre, ma spostare. Un uomo porta sulle spalle poche decine di chili per poche ore; un carro a ruote ne porta centinaia per giornate intere. Le due invenzioni insieme fanno una cosa che nessuna delle due farebbe da sola: rendono conveniente coltivare per qualcuno che sta lontano. Nasce il commercio su distanze lunghe, e nascono città che non vivono di quello che coltivano intorno a sé ma di quello che fanno passare."},
		{"titolo": "Il codice di Hammurabi: scrivere una legge la rende controllabile",
		 "testo": "Intorno al 1750 a.C. il re babilonese Hammurabi fa incidere su una stele di pietra nera, alta più di due metri, una raccolta di leggi scritte. Prima le regole si tramandavano a voce, e questo aveva una conseguenza precisa: cambiavano da un giudice all'altro, e nessuno poteva dimostrare che il giudice avesse sbagliato. Scriverle e metterle in un luogo pubblico rovescia la situazione. Non rende le leggi più giuste — molte di quelle di Hammurabi sono durissime e diverse a seconda della classe sociale — ma le rende UGUALI per tutti quelli a cui si applicano, e soprattutto verificabili: chiunque può andare a leggere che cosa dice la pietra. È la prima volta che il potere accetta di essere misurato su una regola pubblica."},
		{"titolo": "L'alfabeto dei Fenici: togliere il monopolio della scrittura",
		 "testo": "I Fenici, che dal 1200 a.C. circa navigano e commerciano in tutto il Mediterraneo dalle loro città sulla costa dell'attuale Libano, hanno un problema pratico: servono conti veloci in porti diversi, con gente diversa. Il cuneiforme e i geroglifici richiedono centinaia di segni e anni di studio, quindi chi scrive è un professionista raro e costoso. I Fenici mettono a punto un alfabeto di poco più di venti segni, uno per suono. La differenza non è di eleganza ma di accesso: con venti segni scrivere si impara in settimane, e smette di essere il mestiere di una casta. Da quell'alfabeto derivano il greco, il latino e le lettere con cui è scritta questa frase."}],
	"glossario": [
		{"voce": "aratro", "spiega": "Attrezzo trainato che rivolta la terra in profondità: moltiplica quanto una famiglia riesce a coltivare."},
		{"voce": "stele", "spiega": "Lastra di pietra eretta, con inciso un testo o un'immagine, messa dove tutti possano vederla."},
		{"voce": "codice di Hammurabi", "spiega": "Una raccolta di leggi scritte, incisa su pietra intorno al 1750 a.C. dal re di Babilonia."},
		{"voce": "alfabeto", "spiega": "Un segno per ogni suono, poche decine in tutto: rende la scrittura imparabile da chiunque."}],
	"esempi": [
		{"prompt": "Perché la ruota fu importante quanto l'aratro?", "answer": "Perché permise di trasportare pesi lontano",
		 "explanation": "L'aratro fa produrre di più, la ruota fa arrivare lontano quel di più: insieme rendono conveniente coltivare per chi sta altrove, e nasce il commercio."},
		{"prompt": "Che cos'era il codice di Hammurabi?", "answer": "Una raccolta di leggi scritte",
		 "explanation": "Inciso su una stele pubblica intorno al 1750 a.C.: metterlo per iscritto impedisce che la regola cambi da un giudice all'altro."}],
	"metodo": "Di ogni invenzione antica chiediti che cosa smette di essere raro. La ruota rende comune il trasporto, l'alfabeto rende comune il saper scrivere: è lì che si vede chi perde potere.",
	"errore": {"wrong": "Giudicare il codice di Hammurabi «giusto» perché era scritto.",
		"why": "Metterlo per iscritto lo rende pubblico e verificabile, non mite: prevede pene durissime e diverse a seconda della classe sociale."},
	"insegna": ["Fenici", "alfabeto", "la ruota", "aratro", "stele"]},

# ============================================================== EGIZI · base
"storia-egizi-base": {
	"subject": "storia", "topic": "egizi", "fasce": BANDA_BASE,
	"titolo": "Un paese lungo e stretto, tutto attaccato a un fiume",
	"apertura": "Un antico storico greco scrisse che l'Egitto è «un dono del Nilo». Non era un complimento poetico: era una descrizione geografica.",
	"sezioni": [
		{"titolo": "Il Nilo, e la piena che torna ogni anno",
		 "testo": "L'Egitto è quasi tutto deserto. La terra abitabile è una striscia verde larga pochi chilometri che segue il Nilo per centinaia di chilometri, più il delta dove il fiume si apre sul mare. Ogni anno, alla stessa stagione, il Nilo si gonfia per le piogge cadute molto più a sud, esce dal suo letto e allaga i campi; quando si ritira lascia uno strato di limo scuro che rifà fertile il terreno. Senza quelle piene l'Egitto sarebbe stato soltanto deserto, e non ci sarebbe stata nessuna civiltà. Ma la piena non è solo generosa: è anche regolare, e questo conta quanto il limo. Una cosa che torna sempre nello stesso momento si può prevedere, e prevedere significa organizzare — quando seminare, quando raccogliere, quando scavare i canali."},
		{"titolo": "Il faraone: un re che era anche qualcos'altro",
		 "testo": "Dal 3100 a.C. circa l'Egitto è unificato sotto un sovrano unico, il faraone, e questo sovrano non è soltanto un capo politico: è considerato anche divino, un dio in terra o il figlio di un dio. La differenza non è formale. Un re normale si giudica da come governa; un faraone garantisce l'ordine del mondo, e si credeva che dipendesse da lui anche il ritorno della piena. Per questo il suo potere è enorme e la sua morte è un problema cosmico, non solo dinastico. Le piramidi, costruite soprattutto fra il 2600 e il 2500 a.C., sono tombe monumentali dei faraoni: una montagna di pietra costruita da migliaia di uomini per proteggere un corpo solo. Guardate così dicono, prima ancora che della religione, quanto potere avesse chi poteva ordinarle."},
		{"titolo": "L'aldilà, e perché si conserva il corpo",
		 "testo": "Gli Egizi credevano che dopo la morte la vita continuasse, ma che per continuare avesse bisogno del corpo: se il corpo si decomponeva, chi era morto non aveva più dove tornare. Da questa convinzione nasce la mummificazione, cioè il complesso procedimento con cui il corpo veniva svuotato degli organi che marciscono, essiccato con il natron — un sale naturale — e fasciato di bende. Nella tomba si mettevano cibo, gioielli, mobili, modellini di servitori: tutto quello che sarebbe servito di là. Non è superstizione inspiegabile: è la conseguenza pratica e coerente di una premessa, cioè che l'aldilà assomigli alla vita e ne abbia gli stessi bisogni."}],
	"glossario": [
		{"voce": "piena", "spiega": "L'innalzamento annuale del Nilo che allaga i campi. Regolare, e per questo prevedibile."},
		{"voce": "limo", "spiega": "Il fango fertile che la piena deposita sui campi ritirandosi. È quello che rifà la terra ogni anno."},
		{"voce": "faraone", "spiega": "Il sovrano dell'Egitto, considerato anche divino: garantiva l'ordine del mondo, non solo il governo."},
		{"voce": "mummificazione", "spiega": "Il procedimento con cui si conservava il corpo, perché nell'aldilà servisse ancora."}],
	"esempi": [
		{"prompt": "Perché il Nilo era essenziale per gli Egizi?", "answer": "Perché le sue piene rendevano fertile la terra",
		 "explanation": "L'Egitto è deserto quasi ovunque: il limo depositato ogni anno dalla piena è ciò che rende coltivabile la striscia lungo il fiume."},
		{"prompt": "Perché gli Egizi praticavano la mummificazione?", "answer": "Per conservare il corpo per l'aldilà",
		 "explanation": "Credevano che la vita continuasse e che avesse bisogno del corpo: se quello si decomponeva, il morto non aveva più dove tornare."}],
	"metodo": "Di ogni usanza egizia chiediti da quale convinzione discende. Quasi tutte — le tombe, le bende, gli oggetti sepolti — sono conseguenze coerenti della stessa premessa sull'aldilà.",
	"errore": {"wrong": "Dire che le piramidi erano palazzi in cui il faraone abitava.",
		"why": "Erano tombe: dentro non ci sono stanze per vivere ma camere funerarie, e servivano a proteggere il corpo dopo la morte."},
	"insegna": ["Nilo", "faraone", "piramidi", "mummificazione", "le piene"]},

# ============================================================== EGIZI · alta
"storia-egizi-alta": {
	"subject": "storia", "topic": "egizi", "fasce": BANDA_ALTA,
	"titolo": "Scrivere, misurare, e ritrovare i confini dopo l'acqua",
	"apertura": "Tre cose che gli Egizi hanno portato avanti più di chiunque altro, e che nascono tutte e tre da un problema concreto.",
	"sezioni": [
		{"titolo": "I geroglifici e il mestiere dello scriba",
		 "testo": "Dal 3200 a.C. circa gli Egizi usano i geroglifici, la loro scrittura sacra: centinaia di segni, alcuni dei quali rappresentano una cosa e altri un suono, incisi sulla pietra dei templi e delle tombe. Per l'uso quotidiano, dal 3000 a.C., c'è il papiro, ricavato intrecciando le fibre di una pianta di palude: leggero, arrotolabile, e molto più rapido da scrivere. Imparare a scrivere richiedeva anni di scuola, quindi chi ci riusciva — lo scriba — non era un semplice impiegato: era un uomo di potere. Registrava i raccolti, calcolava le tasse, scriveva per conto del faraone. In un paese in cui quasi nessuno sa leggere, chi tiene i registri ha in mano informazioni che nessun altro può controllare."},
		{"titolo": "La geometria nasce da un problema di confini",
		 "testo": "La piena del Nilo ha un effetto collaterale fastidioso: cancella i segni sul terreno. Ogni anno, ritirandosi l'acqua, i campi vanno ridisegnati, e bisogna restituire a ciascuno esattamente il pezzo che aveva — o scoppiano liti, e le tasse non tornano. Per farlo servono misure affidabili: corde con nodi a distanze regolari per tracciare lunghezze e angoli retti, regole per calcolare l'area di un campo rettangolare o triangolare, metodi per dividere un terreno in parti uguali. La geometria egizia nasce da lì, dal bisogno di rimettere i confini dopo l'acqua, e il suo nome lo dice: *geo-metria* significa «misura della terra». Non è nata come pensiero astratto: lo è diventata dopo, con i Greci."},
		{"titolo": "La stele di Rosetta, e come si apre una lingua chiusa",
		 "testo": "Per più di mille anni nessuno seppe più leggere i geroglifici: la conoscenza si era interrotta, e le iscrizioni erano diventate disegni muti. La chiave arrivò nel 1799, quando in Egitto fu trovata la stele di Rosetta: una pietra con lo stesso testo scritto in TRE scritture diverse — geroglifica, demotica e greca. Il greco antico si sapeva leggere benissimo. Confrontando i tre testi, e partendo dai nomi propri dei sovrani, Jean-François Champollion riuscì nel 1822 a decifrare i geroglifici. È il caso più limpido di come funziona il mestiere dello storico: non si indovina il documento sconosciuto: lo si aggancia a qualcosa che già si sa, e lo si fa parlare da lì."}],
	"glossario": [
		{"voce": "geroglifici", "spiega": "La scrittura sacra egizia, incisa su pietra: centinaia di segni, alcuni per cose e altri per suoni."},
		{"voce": "papiro", "spiega": "Materiale da scrittura ricavato da una pianta di palude: leggero, arrotolabile, per l'uso quotidiano."},
		{"voce": "scriba", "spiega": "Chi sapeva scrivere e teneva i registri. In un paese analfabeta era un mestiere di potere."},
		{"voce": "stele di Rosetta", "spiega": "Una pietra con lo stesso testo in tre scritture: permise di decifrare i geroglifici nel 1822."}],
	"esempi": [
		{"prompt": "Perché gli Egizi svilupparono la geometria?", "answer": "Per ridisegnare i campi dopo ogni piena",
		 "explanation": "L'acqua cancellava i confini, e ogni anno bisognava restituire a ciascuno il suo pezzo esatto: servivano misure di lunghezze, angoli e aree."},
		{"prompt": "Che cos'è la stele di Rosetta?", "answer": "Una pietra con lo stesso testo in tre scritture",
		 "explanation": "Una delle tre era il greco, che si sapeva leggere: confrontandole si è potuto risalire al significato dei geroglifici."}],
	"metodo": "Quando una fonte antica sembra impenetrabile, non chiederti che cosa dice: chiediti a quale cosa nota la puoi agganciare. È il metodo della stele di Rosetta, e vale ancora.",
	"errore": {"wrong": "Credere che la geometria egizia sia nata come studio astratto delle figure.",
		"why": "Nasce da un lavoro di catasto: ritrovare i confini dopo la piena. L'astrazione arriva dopo, con i matematici greci."},
	"insegna": ["geroglifici", "papiro", "scriba", "stele di Rosetta", "geometria"]},

# ============================================================= GRECIA · base
"storia-grecia-base": {
	"subject": "storia", "topic": "grecia", "fasce": BANDA_BASE,
	"titolo": "Tante città, nessuno stato",
	"apertura": "I Greci si sentivano un popolo solo e non ebbero mai un governo solo. La ragione è scritta nella forma del loro paese.",
	"sezioni": [
		{"titolo": "Un paese di montagne e di mare",
		 "testo": "La Grecia è fatta di montagne, di piccole pianure separate le une dalle altre e di isole. Non c'è nessuna grande valle fluviale come in Egitto o in Mesopotamia, e la terra coltivabile è poca e spezzettata. Da questa geografia discendono due conseguenze che spiegano quasi tutto il resto. La prima: ogni pianura chiusa fra i monti tende a vivere per conto suo, perché arrivare alla pianura vicina via terra è lungo e faticoso. La seconda: il mare, che sembrerebbe un ostacolo, è invece la strada più facile — navigare da un'isola all'altra è più rapido che attraversare una catena montuosa. Così i Greci restano divisi in decine di comunità autonome e, nello stesso tempo, sono tutti marinai."},
		{"titolo": "La pòlis, e l'agorà che sta in mezzo",
		 "testo": "Dall'800 a.C. circa la forma normale della vita greca è la pòlis: una città-stato indipendente, con le sue leggi, il suo esercito, le sue monete e i suoi culti. Atene e Sparta sono due pòleis, e non obbediscono a nessuno. La pòlis non è soltanto un centro abitato: comprende la città e le campagne intorno, e soprattutto è la comunità dei suoi cittadini. Al centro c'è l'agorà, la piazza: lì si vendono le merci, lì si incontrano le persone, e lì si discutono le decisioni che riguardano tutti. Che il luogo del commercio e quello della politica coincidano non è un caso — è il segno che decidere insieme era considerato un'attività quotidiana, non un evento eccezionale."},
		{"titolo": "Perché partivano: le colonie",
		 "testo": "Dal 750 a.C. circa i Greci fondano colonie lungo tutto il Mediterraneo, dalla Spagna al Mar Nero, e fittissime in Sicilia e nell'Italia meridionale — tanto che quella zona verrà chiamata Magna Grecia, «Grecia grande». Il motivo non è la voglia di avventura ma l'aritmetica: la terra coltivabile in patria era poca, e quando i figli erano più numerosi dei campi disponibili, una parte della popolazione doveva andarsene. Chi partiva fondava una città nuova, che restava legata a quella d'origine per lingua, dèi e affetti, ma era politicamente INDIPENDENTE: una figlia, non una provincia. È per questo che il mondo greco si allarga senza mai diventare un impero."}],
	"glossario": [
		{"voce": "pòlis", "spiega": "La città-stato greca: città più campagne intorno, con leggi, esercito e dèi propri. Non obbedisce a nessuno."},
		{"voce": "agorà", "spiega": "La piazza centrale della pòlis, dove si commercia e si discutono le decisioni comuni."},
		{"voce": "colonia", "spiega": "Città nuova fondata da chi parte. Legata alla madrepatria per cultura, ma politicamente indipendente."},
		{"voce": "Magna Grecia", "spiega": "L'Italia meridionale e la Sicilia, fittissime di colonie greche: «Grecia grande»."}],
	"esempi": [
		{"prompt": "Che cos'era una polis greca?", "answer": "Una città-stato indipendente",
		 "explanation": "Città e campagne intorno, con leggi, esercito e culti propri: le montagne rendevano difficile unirle, e nessuna obbediva a un'altra."},
		{"prompt": "Perché i Greci fondarono colonie nel Mediterraneo?", "answer": "Perché la terra coltivabile in patria era poca",
		 "explanation": "In un paese di montagne i campi non bastavano per tutti: quando la popolazione cresceva, una parte partiva e fondava una città nuova."}],
	"metodo": "Quando una domanda sulla Grecia comincia con «perché», prova prima la risposta geografica: montagne che dividono, mare che unisce, terra coltivabile che non basta. Funziona più spesso di quanto sembri.",
	"errore": {"wrong": "Dire che la Grecia antica era uno stato unito con Atene per capitale.",
		"why": "Le pòleis erano indipendenti l'una dall'altra, e spesso in guerra fra loro: i Greci erano un popolo per lingua e religione, non per governo."},
	"insegna": ["pòlis", "agorà", "colonia", "Magna Grecia"]},

# ============================================================= GRECIA · alta
"storia-grecia-alta": {
	"subject": "storia", "topic": "grecia", "fasce": BANDA_ALTA,
	"titolo": "Atene e Sparta, due risposte alla stessa domanda",
	"apertura": "Come si tiene insieme una comunità? Le due pòleis più famose rispondono in modi opposti, ed entrambe funzionano per secoli.",
	"sezioni": [
		{"titolo": "Atene: il governo del popolo, e chi era il popolo",
		 "testo": "Dal 508 a.C. Atene adotta un sistema che chiama democrazia, parola composta da *dèmos*, popolo, e *kràtos*, potere: governo del popolo. Le decisioni si prendono nell'assemblea, dove chi vuole parla e poi si vota; molte cariche si assegnano perfino per sorteggio, perché il sorteggio non si può comprare. È una novità enorme: per la prima volta il potere non appartiene a un re né a poche famiglie. Bisogna però dire con precisione chi votava: soltanto i cittadini maschi adulti e liberi, cioè una minoranza. Restavano fuori le donne, gli schiavi e gli stranieri residenti, che insieme erano la maggioranza degli abitanti. Chiamarla democrazia è corretto e va capito nel senso che aveva allora: era la prima volta, non la versione finale."},
		{"titolo": "Sparta: una città organizzata come una caserma",
		 "testo": "Sparta sceglie la strada opposta. I bambini maschi dei cittadini venivano tolti alla famiglia intorno ai sette anni e cresciuti in comune con un'educazione militare durissima, fatta di fatica, fame e disciplina; da adulti erano soldati a tempo pieno. Non c'erano mestieri né commerci per loro, e la città era governata da due re insieme a un ristretto gruppo di anziani. La ragione di tanta durezza è concreta: i cittadini spartani erano pochissimi rispetto agli iloti, la popolazione sottomessa che lavorava la terra al posto loro. Una minoranza che vive del lavoro forzato di una maggioranza ha paura, e la paura di una rivolta spiega perché Sparta scelse di essere prima di tutto un esercito."},
		{"titolo": "Quello che li teneva insieme: i giochi e il teatro",
		 "testo": "Pur divisi e spesso in guerra, i Greci avevano occasioni in cui si riconoscevano un popolo solo. Dal 776 a.C. a Olimpia si svolgevano ogni quattro anni i Giochi olimpici, gare sportive in onore di Zeus, durante le quali valeva una tregua sacra che permetteva agli atleti di viaggiare in sicurezza. E ad Atene c'era il teatro: le tragedie non erano uno svago serale ma una cerimonia civica, in cui la città intera guardava insieme storie che mettevano in scena i suoi problemi — la giustizia, il potere, la guerra, l'obbedienza alle leggi. Discutere pubblicamente delle proprie contraddizioni davanti a tutti è, di per sé, una forma di politica. Più tardi, fra il 336 e il 323 a.C., Alessandro Magno porterà lingua e cultura greca fino all'India."}],
	"glossario": [
		{"voce": "democrazia", "spiega": "«Governo del popolo», da dèmos e kràtos. Ad Atene votavano i soli cittadini maschi adulti liberi."},
		{"voce": "iloti", "spiega": "La popolazione sottomessa che lavorava la terra per gli Spartani. Erano molti più dei cittadini."},
		{"voce": "Giochi olimpici", "spiega": "Gare in onore di Zeus a Olimpia, dal 776 a.C. ogni quattro anni, con una tregua sacra."},
		{"voce": "tragedia", "spiega": "Spettacolo teatrale civico: metteva in scena davanti a tutta la città i suoi problemi."}],
	"esempi": [
		{"prompt": "Che cosa significa la parola «democrazia»?", "answer": "Governo del popolo",
		 "explanation": "È composta da dèmos, popolo, e kràtos, potere. Ad Atene il popolo che votava erano i cittadini maschi adulti liberi."},
		{"prompt": "Perché il teatro era importante nella Grecia antica?", "answer": "Perché faceva discutere la città sui suoi problemi",
		 "explanation": "Le tragedie erano una cerimonia civica: tutta la comunità guardava insieme storie di giustizia, potere e obbedienza alle leggi."}],
	"metodo": "Davanti a un'istituzione greca chiediti sempre CHI ne faceva parte e chi restava fuori. È la domanda che distingue il ricordare una parola dal capire come funzionava.",
	"errore": {"wrong": "Dire che nella democrazia ateniese votavano tutti gli abitanti.",
		"why": "Votavano solo i cittadini maschi adulti liberi: donne, schiavi e stranieri residenti, che erano la maggioranza, restavano fuori."},
	"insegna": ["Atene", "Sparta", "democrazia", "Giochi olimpici", "Alessandro Magno"]},

# =============================================================== ROMA · base
"storia-roma-base": {
	"subject": "storia", "topic": "roma", "fasce": BANDA_BASE,
	"titolo": "Da un villaggio sul Tevere",
	"apertura": "Roma comincia come una delle tante piccole città del Lazio e finisce per governare il Mediterraneo. Il primo pezzo della spiegazione è dove si trova.",
	"sezioni": [
		{"titolo": "Il luogo, e la leggenda che lo racconta",
		 "testo": "La tradizione fissa la fondazione di Roma al 753 a.C. e la attribuisce a Romolo, che secondo il racconto tracciò con l'aratro il confine della città. La leggenda serve a dare un inizio preciso a una cosa che precisa non è: gli archeologi trovano villaggi su quelle colline da molto prima. Più interessante è il posto. Roma sorge sul Tevere, nell'ultimo punto in cui il fiume si può guadare risalendo dal mare, e su colline facili da difendere; poco più a monte ci sono le saline, e il sale era una merce preziosissima. Un guado su un fiume è un imbuto: tutto ciò che si sposta fra nord e sud deve passare di lì. Chi controlla l'imbuto vede passare merci, eserciti e notizie. La lingua che vi si parlava era il latino."},
		{"titolo": "Tre forme di governo, una dopo l'altra",
		 "testo": "La storia romana si divide in tre periodi, e conoscerne l'ordine è il modo più rapido per non confondere niente. Prima la monarchia, dal 753 al 509 a.C.: Roma è guidata da re. Poi la repubblica, dal 509 al 27 a.C.: i Romani cacciano l'ultimo re e costruiscono un sistema pensato apposta perché nessuno possa ridiventarlo — al vertice non c'è una persona sola ma DUE consoli, che restano in carica un anno solo e possono bloccarsi a vicenda. Infine l'impero, dal 27 a.C.: Ottaviano Augusto diventa il primo imperatore, mantenendo le forme della repubblica e concentrando nelle proprie mani il potere reale. Le tre parole — monarchia, repubblica, impero — non sono etichette: descrivono chi decide e per quanto tempo."},
		{"titolo": "Chi comandava davvero durante la repubblica",
		 "testo": "Nella repubblica la popolazione libera era divisa in patrizi, le famiglie aristocratiche, e plebei, tutti gli altri. Le magistrature e il senato — l'assemblea dei capi delle grandi famiglie, che di fatto guidava la politica — erano all'inizio riservati ai patrizi. I plebei ottennero peso lottando: dal 494 a.C. esistono i tribuni della plebe, magistrati incaricati di difendere i plebei e capaci di bloccare le decisioni che li danneggiavano. Va detto con chiarezza chi poteva votare: soltanto i cittadini maschi liberi. Le donne non votavano, e gli schiavi non erano cittadini. Come ad Atene, la partecipazione era reale e riguardava una parte della popolazione, non tutta."}],
	"glossario": [
		{"voce": "repubblica", "spiega": "Dal 509 al 27 a.C.: nessun re, cariche elettive e a scadenza. Da *res publica*, la cosa di tutti."},
		{"voce": "console", "spiega": "Il magistrato al vertice della repubblica. Erano sempre due insieme, per un anno solo."},
		{"voce": "senato", "spiega": "L'assemblea dei capi delle grandi famiglie: guidava di fatto la politica romana."},
		{"voce": "tribuno della plebe", "spiega": "Magistrato che dal 494 a.C. difendeva i plebei e poteva bloccare decisioni a loro dannose."}],
	"esempi": [
		{"prompt": "Quale lingua parlavano gli antichi Romani?", "answer": "Il latino",
		 "explanation": "Era la lingua del Lazio, la regione di Roma, e si diffuse con le conquiste: da essa derivano l'italiano e le altre lingue neolatine."},
		{"prompt": "Perché i consoli della repubblica erano due e duravano un anno?", "answer": "Per impedire che uno tornasse a essere re",
		 "explanation": "Dopo aver cacciato l'ultimo re, i Romani costruirono il sistema in modo che nessuno potesse accumulare potere: due persone si controllano, e un anno passa presto."}],
	"metodo": "Prima di rispondere a una domanda su Roma, collocala in uno dei tre periodi: monarchia, repubblica o impero. Molte risposte cambiano completamente a seconda del periodo, e la domanda quasi sempre lo dice.",
	"errore": {"wrong": "Usare «repubblica» e «impero» come se fossero la stessa cosa.",
		"why": "Sono due sistemi opposti e successivi: nella repubblica il potere è diviso fra cariche annuali, nell'impero è concentrato in una persona a vita."},
	"insegna": ["Romolo", "Tevere", "il latino", "repubblica", "consoli", "senato"]},

# =============================================================== ROMA · alta
"storia-roma-alta": {
	"subject": "storia", "topic": "roma", "fasce": BANDA_ALTA,
	"titolo": "Come si tiene insieme un impero per cinque secoli",
	"apertura": "Conquistare è la parte facile. La domanda storica interessante è un'altra: perché tanti popoli diversissimi restarono dentro lo stesso stato così a lungo?",
	"sezioni": [
		{"titolo": "Le strade, cioè il tempo",
		 "testo": "Dal 312 a.C., con la via Appia, i Romani cominciano a costruire strade consolari: tracciati il più possibile diritti, con fondo di pietre a strati, leggermente bombati perché l'acqua scoli via, e segnati da pietre miliari che indicano la distanza. Servivano prima di tutto a spostare rapidamente eserciti e merci. La conseguenza non è geografica ma temporale: una strada buona non accorcia la distanza, accorcia il TEMPO. Una rivolta che scoppia a cinquecento chilometri da Roma è un problema molto diverso a seconda che le legioni ci mettano un mese o otto giorni. Con le strade l'impero smette di essere una macchia sulla carta e diventa un sistema in cui le notizie e le forze circolano, e chi lo governa può reagire prima che le cose degenerino."},
		{"titolo": "Il diritto, e una cittadinanza che si poteva ottenere",
		 "testo": "La seconda risposta è giuridica. I Romani scrivono le leggi, le applicano con procedure pubbliche e le studiano come una tecnica: è la nascita del diritto, forse la loro eredità più duratura. E la cittadinanza romana non era un privilegio chiuso di nascita: si poteva ottenere, per esempio con il servizio militare, e nel 212 d.C. venne estesa a quasi tutti gli abitanti liberi dell'impero. Era ambitissima perché dava diritti concreti e protezione legale: un cittadino non poteva essere punito in certi modi e poteva appellarsi. Qui sta il meccanismo: a un popolo conquistato viene offerta una prospettiva di entrare nel sistema invece di essere solo schiacciato da esso, e questo rende la ribellione meno conveniente dell'integrazione."},
		{"titolo": "La vita in comune, e una data di comodo alla fine",
		 "testo": "La terza risposta è quotidiana: gli acquedotti portavano acqua corrente nelle città, e le terme — grandi bagni pubblici, aperti a pagamenti minimi — erano anche luogo di incontro, di affari e di chiacchiere, cioè il posto dove una città diventava una comunità. Nell'80 d.C. viene inaugurato il Colosseo; l'anno prima, nel 79 d.C., l'eruzione del Vesuvio aveva sepolto Pompei, e ce l'ha consegnata intatta. Nel 476 d.C. l'ultimo imperatore d'Occidente viene deposto, e questa data si usa come inizio del Medioevo. Va presa per quello che è: una data di comodo. Niente finì in quel giorno — le città si erano svuotate lentamente per decenni, e l'impero d'Oriente proseguì per altri mille anni."}],
	"glossario": [
		{"voce": "via consolare", "spiega": "Strada romana principale, diritta e lastricata. Serviva a spostare in fretta eserciti e merci."},
		{"voce": "cittadinanza", "spiega": "Lo stato giuridico che dava diritti e protezione legale. Si poteva ottenere, e per questo era ambita."},
		{"voce": "terme", "spiega": "Bagni pubblici, e insieme luogo d'incontro: il posto in cui una città diventava una comunità."},
		{"voce": "476 d.C.", "spiega": "Deposizione dell'ultimo imperatore d'Occidente. Si usa come inizio del Medioevo: è una convenzione utile, non un crollo improvviso."}],
	"esempi": [
		{"prompt": "A che cosa serviva una via consolare romana?", "answer": "A spostare rapidamente eserciti e merci",
		 "explanation": "Una strada buona non accorcia la distanza ma il tempo: con le legioni che arrivano in giorni invece che in mesi, una rivolta lontana diventa governabile."},
		{"prompt": "Perché la cittadinanza romana era così ambita?", "answer": "Perché dava diritti e protezione legale",
		 "explanation": "Non era chiusa dalla nascita e si poteva ottenere: per un popolo conquistato entrare nel sistema conveniva più che ribellarsi."}],
	"metodo": "Quando ti chiedono perché Roma durò tanto, non cercare una sola causa: metti in fila strade, leggi e cittadinanza. È la combinazione a reggere, e ciascuna da sola non basterebbe.",
	"errore": {"wrong": "Raccontare il 476 d.C. come il giorno in cui l'impero crollò all'improvviso.",
		"why": "È una data convenzionale di fine: il declino era durato decenni, e l'impero d'Oriente continuò per altri mille anni."},
	"insegna": ["via consolare", "cittadinanza", "terme", "Colosseo", "476 d.C."]},

# ============================================================ MEDIOEVO · alta
"storia-medioevo-alta": {
	"subject": "storia", "topic": "medioevo", "fasce": BANDA_ALTA,
	"titolo": "Mille anni fra due date di comodo",
	"apertura": "Dal 476 al 1492: due date scelte dagli storici per mettere ordine. In mezzo ci sta un periodo lunghissimo che cambia due volte.",
	"sezioni": [
		{"titolo": "Dopo il 476: quando la terra prende il posto del denaro",
		 "testo": "Caduto l'impero d'Occidente, i commerci a lunga distanza si riducono moltissimo, le strade non vengono più mantenute, le città si svuotano e viaggiare diventa pericoloso. In una situazione così il denaro serve a poco — non c'è quasi niente da comprare — e la ricchezza torna a essere una sola: la terra, che dà da mangiare. Su questa base si costruisce il feudalesimo, che dal IX secolo diventa il sistema normale: il signore concede a un altro uomo delle terre, il feudo, e in cambio ne riceve fedeltà e servizio armato. Chi lavora davvero quella terra sono i contadini, in gran parte servi della gleba: non schiavi comprabili, ma legati alla terra su cui sono nati, che non possono lasciare e che passa di proprietario con loro sopra."},
		{"titolo": "I monasteri, e mille anni di copie a mano",
		 "testo": "Mentre le città si svuotano, i monasteri diventano il luogo più stabile d'Europa: producono cibo, accolgono viandanti, e soprattutto conservano i libri. Dal VI secolo, nella stanza chiamata scriptorium, i monaci amanuensi copiavano a mano i libri antichi, uno per uno, riga per riga. Copiare un volume poteva richiedere mesi, e ogni copia era anche un'occasione di errore: per questo si confrontavano più esemplari. Senza questo lavoro paziente, gran parte dei testi greci e latini che oggi leggiamo non sarebbe arrivata fino a noi, semplicemente perché la pergamena si consuma e nessun libro dura duemila anni da solo. Un libro, in quel mondo, costava quanto un piccolo podere — ed è la ragione per cui leggere restava cosa di pochissimi."},
		{"titolo": "Il Basso Medioevo: le città tornano, e tutto accelera",
		 "testo": "Dall'XI secolo il quadro si rovescia. La popolazione cresce, si coltiva meglio, ripartono i commerci e l'artigianato, e le città rinascono attirando chi vuole lavorare e vendere. Molte ottengono di governarsi da sé: sono i comuni, città che si danno leggi e magistrature proprie invece di obbedire a un signore. Intanto l'Europa si muove: la prima crociata è del 1096-1099, Marco Polo viaggia verso la Cina fra il 1271 e il 1295, e la peste nera del 1347-1352 uccide forse un terzo degli europei, sconvolgendo i rapporti fra chi lavora e chi possiede. Verso la metà del Quattrocento arriva la stampa a caratteri mobili, e un libro smette di costare come un podere: da lì la diffusione del sapere cambia velocità per sempre."}],
	"glossario": [
		{"voce": "feudalesimo", "spiega": "Il sistema in cui il signore dà terre in cambio di fedeltà e servizio armato. Dal IX secolo."},
		{"voce": "servi della gleba", "spiega": "Contadini legati alla terra su cui erano nati: non la potevano lasciare, e cambiavano proprietario con essa."},
		{"voce": "amanuensi", "spiega": "Monaci che copiavano a mano i libri antichi nello scriptorium. Senza di loro molti testi sarebbero perduti."},
		{"voce": "comune", "spiega": "Città medievale che si governa da sé, con leggi e magistrature proprie. Dall'XI secolo."}],
	"esempi": [
		{"prompt": "Perché nel Basso Medioevo rinascono le città?", "answer": "Perché ripartono commerci e artigianato",
		 "explanation": "Cresce la popolazione e si coltiva meglio: il di più si scambia, e chi vive di mestieri e di scambi ha bisogno di stare dove passa la gente."},
		{"prompt": "Che cosa facevano i monaci amanuensi?", "answer": "Copiavano a mano i libri antichi",
		 "explanation": "Nello scriptorium, uno per uno: era l'unico modo di moltiplicare un testo prima della stampa, e per questo molti libri antichi sono arrivati fino a noi."}],
	"metodo": "Dividi sempre il Medioevo in due: prima le città si svuotano e conta solo la terra, poi le città tornano e conta di nuovo lo scambio. Quasi ogni domanda riguarda una delle due metà, e la risposta cambia.",
	"errore": {"wrong": "Trattare i mille anni del Medioevo come un unico periodo immobile.",
		"why": "L'Alto e il Basso Medioevo vanno in direzioni opposte: nel primo i commerci si spengono e la terra è tutto, nel secondo rinascono città, comuni e mercati."},
	"insegna": ["feudalesimo", "servi della gleba", "amanuensi", "comune", "stampa a caratteri mobili"]},

# ========================================================= CRONOLOGIA · base
"storia-cronologia-base": {
	"subject": "storia", "topic": "cronologia", "fasce": BANDA_BASE,
	"titolo": "Come si conta il tempo, e perché una parte si conta all'indietro",
	"apertura": "Prima di collocare un fatto bisogna saper leggere la riga su cui si colloca. Sono tre regole, e due di loro sono controintuitive apposta.",
	"sezioni": [
		{"titolo": "Le tre unità, e quando si usano",
		 "testo": "Un decennio dura dieci anni, un secolo cento, un millennio mille — cioè dieci secoli. Non sono tre modi eleganti di dire la stessa cosa: si scelgono in base a quanto il fatto è lontano. Per gli avvenimenti vicini a noi dieci anni sono già una differenza che si vede, e si ragiona per decenni. Per l'antichità e soprattutto per la preistoria, invece, un secolo in più o in meno non cambia il racconto, e si usano i millenni. È il motivo per cui le date della preistoria sono quasi sempre approssimate — «circa 10.000 anni fa» — mentre per il Novecento si indica l'anno preciso: cambia la precisione che le fonti permettono, e cambia quella che serve."},
		{"titolo": "Il secolo non porta lo stesso numero dell'anno",
		 "testo": "Questa è la regola che fa sbagliare più di ogni altra, e ha una causa semplice: il conteggio dei secoli comincia da uno, non da zero. Il primo secolo va dall'anno 1 all'anno 100, il secondo dal 101 al 200, e così via. Ne segue che un anno che comincia per 17 non sta nel diciassettesimo secolo ma nel DICIOTTESIMO: il 1789 appartiene al XVIII secolo. La regola pratica è: prendi le cifre che stanno davanti alle ultime due e aggiungi uno. L'unica eccezione sono gli anni che finiscono con due zeri, che chiudono il secolo invece di aprirlo: il 1900 è l'ultimo anno del XIX secolo, non il primo del XX. I secoli, per tradizione, si scrivono in numeri romani."},
		{"titolo": "Avanti Cristo: i numeri crescono andando indietro",
		 "testo": "La nostra numerazione degli anni prende come punto zero la nascita di Cristo. Gli anni successivi sono «dopo Cristo», abbreviato d.C., e si contano in avanti come ci si aspetta: il 1200 viene dopo il 500. Gli anni precedenti sono «avanti Cristo», a.C., e si contano all'INDIETRO: più il numero è grande, più il fatto è lontano da noi. Per questo il 300 a.C. viene PRIMA del 100 a.C., anche se trecento è maggiore di cento. È l'unica numerazione della storia che va al contrario, e su una linea del tempo si vede subito perché: procedendo da sinistra verso destra, cioè dal passato al presente, i numeri a.C. calano fino a uno e poi ricominciano a salire come d.C."}],
	"glossario": [
		{"voce": "secolo", "spiega": "Cento anni. Il primo va dall'1 al 100, quindi il numero del secolo è quasi sempre una unità più alto delle centinaia dell'anno."},
		{"voce": "millennio", "spiega": "Mille anni, cioè dieci secoli. Si usa per l'antichità e la preistoria, dove il secolo è una precisione che le fonti non danno."},
		{"voce": "a.C.", "spiega": "«Avanti Cristo»: anni contati all'indietro. Più il numero è grande, più il fatto è antico."},
		{"voce": "d.C.", "spiega": "«Dopo Cristo»: anni contati in avanti, nel verso a cui siamo abituati."}],
	"esempi": [
		{"prompt": "A quale secolo appartiene l'anno 1789?", "answer": "XVIII secolo",
		 "explanation": "Il conteggio parte da uno, non da zero: il primo secolo finisce nel 100, quindi gli anni che cominciano per 17 stanno nel diciottesimo."},
		{"prompt": "Quale anno viene prima: 300 a.C. o 100 a.C.?", "answer": "300 a.C.",
		 "explanation": "Gli anni avanti Cristo si contano all'indietro, quindi il numero più grande è il più lontano da noi, cioè il più antico."}],
	"metodo": "Disegna sempre la riga prima di rispondere, con lo zero in mezzo. Le due regole che sembrano capricci — il secolo più uno e i numeri a.C. che calano — su una riga disegnata diventano ovvie.",
	"errore": {"wrong": "Rispondere «XVII secolo» per l'anno 1789.",
		"why": "Conta le centinaia dell'anno senza aggiungere uno, ma il primo secolo va dall'1 al 100: gli anni del Settecento stanno nel XVIII secolo."},
	# Le due forme di risposta che questa dispensa insegna a COSTRUIRE invece che a
	# ricordare: il nome di un secolo in numeri romani, e un anno con la sua sigla.
	# Sono infinite, e la stessa espressione dei secoli sta già nella tavola
	# `storia-come-si-conta-il-tempo`.
	"regole": ["^[IVXLCDM]+ secolo$", "^(il |l')?[0-9]+ (a\\.C\\.|d\\.C\\.)$"],
	"insegna": ["secolo", "millennio", "a.C.", "d.C.", "XVIII secolo"]},

# ========================================================= CRONOLOGIA · alta
"storia-cronologia-alta": {
	"subject": "storia", "topic": "cronologia", "fasce": BANDA_ALTA,
	"titolo": "Misurare le distanze, e dividere il tempo in età",
	"apertura": "Sapere dove sta un anno non basta: bisogna saper misurare quanto dista da un altro, e sapere che i nomi dei periodi li abbiamo scelti noi.",
	"sezioni": [
		{"titolo": "Gli intervalli che attraversano la nascita di Cristo",
		 "testo": "Calcolare quanti anni passano fra due date dello stesso lato è una sottrazione: dal 1492 al 1789 passano 1789 meno 1492, cioè 297 anni. Quando invece l'intervallo attraversa il punto di partenza della numerazione, la sottrazione non funziona più, perché da un lato i numeri calano e dall'altro crescono: bisogna SOMMARE. Dal 50 a.C. al 50 d.C. passano 50 più 50, cioè 100 anni. Il modo per non sbagliare mai è pensare alla riga: si conta il pezzo da 50 a.C. fino a Cristo, poi il pezzo da Cristo fino al 50 d.C., e si mettono insieme i due pezzi. Fare la differenza fra i due numeri darebbe zero, che è il segnale immediato di aver applicato la regola sbagliata."},
		{"titolo": "Le cinque grandi età, e chi ha deciso dove tagliare",
		 "testo": "Per orientarsi, gli storici dividono il passato in cinque grandi periodi. La Preistoria arriva fino alla scrittura, intorno al 3300 a.C. L'Età antica va da lì al 476 d.C. Il Medioevo dal 476 al 1492. L'Età moderna dal 1492 al 1789. L'Età contemporanea dal 1789 a oggi. Ogni confine è un evento scelto come segnale: la scrittura, la deposizione dell'ultimo imperatore d'Occidente, l'arrivo di Colombo in America, la Rivoluzione francese. Il punto importante è che queste date sono CONVENZIONI, non fatti naturali: nessuno si è svegliato moderno il mattino del 1492. Servono a mettere ordine e vanno usate sapendo che cosa sono — strumenti comodi, e discutibili."},
		{"titolo": "La linea del tempo, e quello che la sua scala fa vedere",
		 "testo": "Una linea del tempo è uno schema che mette gli eventi in ordine lungo una riga. La sua forza non sta nell'ordine, che si potrebbe dare anche con un elenco, ma nella SCALA: se la distanza sulla carta è proporzionale al tempo trascorso, si vedono cose che un elenco nasconde. Disegnando in scala la storia dell'uomo, per esempio, si scopre che la preistoria occupa quasi tutta la riga e che tutto il resto — Egizi, Greci, Romani, Medioevo, noi — si schiaccia in un tratto finale piccolissimo. È lo stesso motivo per cui su una linea del tempo si nota subito che Cleopatra visse più vicina a noi che alla costruzione delle piramidi."}],
	"glossario": [
		{"voce": "intervallo", "spiega": "La distanza fra due date. Si sottrae se stanno dallo stesso lato, si somma se attraversa la nascita di Cristo."},
		{"voce": "Età antica", "spiega": "Dalla scrittura, intorno al 3300 a.C., al 476 d.C."},
		{"voce": "Età moderna", "spiega": "Dal 1492 al 1789: dall'arrivo di Colombo in America alla Rivoluzione francese."},
		{"voce": "periodizzazione", "spiega": "La divisione del passato in periodi. È una scelta degli storici, utile e discutibile, non un fatto naturale."}],
	"esempi": [
		{"prompt": "Quanti anni passano fra il 50 a.C. e il 50 d.C.?", "answer": "100",
		 "explanation": "L'intervallo attraversa il punto di partenza della numerazione, quindi i due tratti si sommano invece di sottrarsi: cinquanta più cinquanta."},
		{"prompt": "Che cos'è una linea del tempo?", "answer": "Uno schema che mette gli eventi in ordine",
		 "explanation": "E se la distanza è in scala mostra anche le proporzioni: la preistoria occupa quasi tutta la riga, tutto il resto un tratto finale piccolissimo."}],
	"metodo": "Prima di calcolare un intervallo guarda se le due date stanno dalla stessa parte di Cristo. Stessa parte: si sottrae. Parti opposte: si somma. È l'unica decisione da prendere, e se la prendi bene il conto viene da sé.",
	"errore": {"wrong": "Calcolare la distanza fra 50 a.C. e 50 d.C. facendo la sottrazione.",
		"why": "Verrebbe zero, mentre i due fatti distano un secolo: da lati opposti della nascita di Cristo i tratti si sommano."},
	"insegna": ["linea del tempo", "Età antica", "Età moderna", "Età contemporanea", "periodizzazione"]},

# ============================================================== FONTI · base
"storia-fonti-base": {
	"subject": "storia", "topic": "fonti", "fasce": BANDA_BASE,
	"titolo": "Come si sa quello che si sa",
	"apertura": "La domanda che uno storico si fa per prima non è «che cosa è successo», ma «da che cosa lo so». Tutto il mestiere sta in quella differenza.",
	"sezioni": [
		{"titolo": "Che cos'è una fonte",
		 "testo": "Una fonte storica è qualsiasi traccia che ci dice qualcosa del passato. Non solo i documenti solenni: un vaso rotto trovato in uno scavo è una fonte, e lo sono un muro, una lista della spesa, una canzone tramandata, un osso con i segni di un taglio, una fotografia, il nome di una via. Fonte non significa «cosa importante»: significa «cosa da cui si può ricavare un'informazione». Da qui discende il principio che tiene in piedi tutta la disciplina: senza fonti non c'è storia, ci sono soltanto ipotesi. Ed è per questo che i millenni prima della scrittura si chiamano preistoria — non perché non sia successo niente, ma perché le uniche fonti disponibili sono gli oggetti, che mostrano e non spiegano."},
		{"titolo": "I tipi di fonte, e che cosa ciascuno sa fare",
		 "testo": "Le fonti si classificano in base a com'è fatta la traccia. Una fonte materiale è un oggetto: un vaso trovato in uno scavo, un'arma, i resti di una casa. Una fonte scritta è un testo: il diario di un soldato, una legge, un contratto, una lettera. Una fonte orale è un racconto tramandato a voce o una testimonianza raccolta. Una fonte iconografica è un'immagine: un affresco, una moneta con un ritratto, una fotografia. Ognuna ha un limite suo, ed è per questo che si usano insieme: un oggetto non mente, perché non ha intenzioni, ma non spiega niente di sé; uno scritto spiega moltissimo, ma ha un autore che scriveva per qualcuno e per un motivo."},
		{"titolo": "Primarie e secondarie: quanto si è vicini al fatto",
		 "testo": "La seconda classificazione non riguarda la forma ma la DISTANZA dal fatto. Una fonte primaria è un documento prodotto nell'epoca studiata, da chi quell'epoca la viveva: la lettera che un soldato scrive dal fronte mentre la guerra è in corso. Una fonte secondaria è costruita dopo, da qualcuno che ha studiato le fonti primarie e le racconta: il manuale che usi a scuola è una fonte secondaria. Attenzione a non trasformare questa distinzione in un giudizio di valore. La secondaria non è meno vera: è più lontana, e soprattutto è già interpretata da qualcun altro. Per questo chi vuole controllare una ricostruzione risale sempre alla fonte primaria, dove l'interpretazione non è ancora stata fatta."}],
	"glossario": [
		{"voce": "fonte", "spiega": "Qualsiasi traccia che dice qualcosa del passato. Non deve essere importante: deve poter essere interrogata."},
		{"voce": "fonte materiale", "spiega": "Un oggetto: vaso, arma, muro. Non mente, perché non ha intenzioni, ma non spiega se stesso."},
		{"voce": "fonte primaria", "spiega": "Un documento prodotto nell'epoca studiata, da chi la viveva."},
		{"voce": "fonte secondaria", "spiega": "Ricostruita dopo studiando le primarie. Il manuale di scuola è una fonte secondaria."}],
	"esempi": [
		{"prompt": "Un vaso trovato in uno scavo è una fonte…", "answer": "Materiale",
		 "explanation": "È un oggetto, non un testo: mostra come era fatto e dove stava, ma non dice niente sul perché — quello va ricostruito."},
		{"prompt": "Che cos'è una fonte primaria?", "answer": "Un documento prodotto nell'epoca studiata",
		 "explanation": "Viene da chi quell'epoca la viveva, quindi non è ancora stata interpretata da nessuno: è lì che risale chi vuole controllare."}],
	"metodo": "Davanti a una fonte fatti due domande separate: di che cosa è fatta (oggetto, testo, voce, immagine) e quanto è vicina al fatto (primaria o secondaria). Sono due classificazioni diverse, e ogni fonte ha una risposta per entrambe.",
	"errore": {"wrong": "Pensare che una fonte secondaria sia meno affidabile di una primaria.",
		"why": "Non è meno vera: è più lontana e già interpretata. Un buon manuale può essere più affidabile di un testimone di parte."},
	"insegna": ["fonte", "materiale", "scritta", "primaria", "secondaria"]},

# ============================================================== FONTI · alta
"storia-fonti-alta": {
	"subject": "storia", "topic": "fonti", "fasce": BANDA_ALTA,
	"titolo": "Una fonte non dice la verità: dice qualcosa, da un certo punto",
	"apertura": "Il passo difficile non è trovare le fonti. È leggerle sapendo che ciascuna è stata prodotta da qualcuno, in un momento, per una ragione.",
	"sezioni": [
		{"titolo": "Datare e attribuire, sempre",
		 "testo": "Di ogni fonte scritta bisogna stabilire due cose prima ancora di leggerne il contenuto: QUANDO è stata scritta e CHI l'ha scritta. Non è pignoleria d'archivio, perché entrambe cambiano ciò che il testo dice. Il resoconto di una battaglia scritto dal comandante vincitore il giorno dopo e quello scritto da un soldato della parte sconfitta trent'anni più tardi raccontano due cose diverse, e non perché uno dei due menta: uno ha visto un pezzo di campo e ha interesse a far bella figura, l'altro ha avuto trent'anni per rileggere l'evento alla luce di quello che è successo dopo. Una fonte senza data e senza autore non è inutile, ma è molto meno utile: non si sa da quale posizione stia parlando."},
		{"titolo": "Quando due fonti si contraddicono",
		 "testo": "Capita spesso, ed è il momento in cui il mestiere si vede. La cosa che uno storico NON fa è scegliere la fonte che gli piace di più o che conferma quello che pensava. Quello che fa è confrontarle e cercare PERCHÉ differiscono: chi erano i due autori, che cosa potevano sapere ciascuno, che cosa gli conveniva dire, a chi si rivolgevano. Molto spesso la spiegazione della differenza è più istruttiva del punto su cui si contraddicono, perché rivela il contesto di entrambe. E a volte la conclusione onesta è che con le fonti disponibili non si può decidere: dirlo è un risultato, non una sconfitta."},
		{"titolo": "Il silenzio delle fonti",
		 "testo": "Di alcune persone il passato ha conservato moltissimo, di altre quasi niente, e la differenza non dipende da quanto contavano davvero. Chi sapeva scrivere ha lasciato testi; chi non sapeva scrivere ha lasciato al massimo oggetti, e spesso nemmeno quelli. Re, sacerdoti e proprietari compaiono ovunque; contadini, donne, servi e bambini quasi mai, pur essendo la stragrande maggioranza degli esseri umani vissuti. Il punto da tenere fermo è questo: l'assenza di fonti non è assenza di fatti. Ed è la ragione per cui da tempo si studia anche la storia della gente comune, andando a cercare tracce indirette — registri di battesimo, conti, utensili, resti di cibo — che raccontano come si viveva davvero."}],
	"glossario": [
		{"voce": "attribuire", "spiega": "Stabilire chi ha prodotto una fonte. Serve a sapere da quale posizione parla."},
		{"voce": "datare", "spiega": "Stabilire quando è stata prodotta. La distanza dall'evento cambia che cosa l'autore poteva sapere."},
		{"voce": "confrontare", "spiega": "Mettere due fonti una accanto all'altra e cercare perché differiscono, invece di sceglierne una."},
		{"voce": "silenzio delle fonti", "spiega": "L'assenza di tracce su interi gruppi di persone. Non significa che non ci fossero o che non contassero."}],
	"esempi": [
		{"prompt": "Perché una fonte scritta va sempre datata e attribuita?", "answer": "Perché chi scrive e quando cambia ciò che dice",
		 "explanation": "Un vincitore il giorno dopo e uno sconfitto trent'anni più tardi vedono cose diverse e hanno interessi diversi, anche senza mentire."},
		{"prompt": "Due fonti primarie dello stesso evento si contraddicono. Cosa fa uno storico?", "answer": "Le confronta e cerca perché differiscono",
		 "explanation": "La ragione della differenza dice chi erano gli autori e che cosa gli conveniva: è spesso più istruttiva del punto contestato."}],
	"metodo": "Prima di credere a una fonte chiediti chi la scrive, quando, e a chi si rivolge. Poi chiediti chi in quella fonte non compare affatto: il vuoto è un'informazione quanto il testo.",
	"errore": {"wrong": "Davanti a due fonti in contrasto, scegliere quella che conferma quello che già si pensava.",
		"why": "Trasforma la ricerca in una conferma: la differenza va spiegata, e la spiegazione racconta il contesto di entrambe."},
	"insegna": ["attribuire", "datare", "confrontare", "silenzio delle fonti"]},

# ============================================================= METODO · base
"storia-metodo-base": {
	"subject": "storia", "topic": "metodo", "fasce": BANDA_BASE,
	"titolo": "Che cosa fa, in concreto, uno storico",
	"apertura": "Non ricorda date: le cerca, le confronta e dichiara dove le ha prese. È un mestiere con una procedura, e la procedura è controllabile.",
	"sezioni": [
		{"titolo": "I quattro passi, in ordine",
		 "testo": "Il lavoro comincia da una domanda — «come si viveva in un villaggio medievale?» — non da un racconto già pronto. Primo passo: raccogliere le fonti, cioè cercare tutte le tracce che possono rispondere. Secondo: analizzarle una per una, stabilendo di ciascuna che cos'è, quando è stata prodotta e da chi. Terzo: confrontarle fra loro, notando dove concordano e dove no. Quarto: proporre una ricostruzione, cioè un racconto che tenga insieme quello che le fonti dicono, dichiarando quali sono. L'ordine conta: chi parte dalla ricostruzione e poi cerca le fonti che la confermano non sta facendo storia, sta cercando conferme — e le troverà, perché cercando apposta si trova sempre qualcosa."},
		{"titolo": "Perché le fonti si dichiarano",
		 "testo": "Ogni lavoro storico serio indica da dove viene ciascuna informazione: note, bibliografia, riferimenti agli archivi. Sembra una formalità accademica ed è invece la cosa che distingue la storia da un bel racconto sul passato. Il motivo è uno solo: perché altri possano CONTROLLARE il lavoro. Chi non è d'accordo può andare a vedere la stessa fonte, rileggerla e sostenere che dice un'altra cosa; e se ha ragione, la ricostruzione cambia. Un racconto senza fonti dichiarate non si può né confermare né smentire: si può solo credergli o no. Dichiarare le proprie fonti significa accettare in anticipo di poter essere corretti, ed è per questo che è una regola e non una cortesia."},
		{"titolo": "Il fatto e l'interpretazione: due cose diverse",
		 "testo": "Un fatto è qualcosa che è accaduto e che le fonti permettono di stabilire: nel 476 d.C. l'ultimo imperatore d'Occidente fu deposto. Un'interpretazione è la spiegazione che se ne dà: perché l'impero non resse, che peso ebbero le invasioni, l'economia, l'esercito. Sul fatto, se le fonti sono solide, si è d'accordo; sull'interpretazione si discute, e storici diversi propongono spiegazioni diverse tutte compatibili con gli stessi fatti. Tenere separate le due cose è la difesa principale contro la confusione: quando si legge un testo di storia conviene chiedersi, frase per frase, se si sta leggendo qualcosa che è accaduto o qualcosa che qualcuno propone per spiegarlo."}],
	"glossario": [
		{"voce": "ricostruzione", "spiega": "Il racconto che lo storico propone mettendo insieme le fonti. Non è un romanzo: deve reggere al controllo."},
		{"voce": "fatto", "spiega": "Qualcosa che è accaduto e che le fonti permettono di stabilire."},
		{"voce": "interpretazione", "spiega": "La spiegazione che si dà di un fatto. Si discute, e può cambiare senza che il fatto cambi."},
		{"voce": "fonti dichiarate", "spiega": "L'elenco di dove viene ciascuna informazione. Serve a permettere agli altri di controllare."}],
	"esempi": [
		{"prompt": "Perché lo storico deve dichiarare le proprie fonti?", "answer": "Perché altri possano controllare il lavoro",
		 "explanation": "Un racconto senza fonti non si può né confermare né smentire: dichiararle significa accettare in anticipo di poter essere corretti."},
		{"prompt": "Che differenza c'è fra un fatto e un'interpretazione?", "answer": "Il fatto è accaduto, l'interpretazione lo spiega",
		 "explanation": "Sul fatto, con fonti solide, si è d'accordo; sulla spiegazione si discute, e più spiegazioni possono reggere sugli stessi fatti."}],
	"metodo": "Leggendo un testo di storia, separa mentalmente le frasi in due colonne: quelle che dicono che cosa è successo e quelle che dicono perché. La seconda colonna è quella su cui si può discutere.",
	"errore": {"wrong": "Partire da una tesi e poi cercare le fonti che la confermano.",
		"why": "Cercando apposta si trova sempre qualcosa: l'ordine va rovesciato, prima le fonti e poi la ricostruzione, o il risultato è garantito in partenza."},
	"insegna": ["fonti dichiarate", "fatto", "interpretazione", "ricostruzione"]},

# ============================================================= METODO · alta
"storia-metodo-alta": {
	"subject": "storia", "topic": "metodo", "fasce": BANDA_ALTA,
	"titolo": "Contestualizzare, e non prestare le proprie idee ai morti",
	"apertura": "L'errore più frequente di chi studia storia non è dimenticare una data: è leggere il passato con le abitudini mentali del presente.",
	"sezioni": [
		{"titolo": "Contestualizzare una fonte",
		 "testo": "Contestualizzare vuol dire capire in che epoca e in che situazione una fonte è nata: che cosa si sapeva allora, che cosa era considerato normale, chi decideva, che parole si usavano e con che significato. Senza questo lavoro una frase del passato si legge con le nostre abitudini e finisce per dire il contrario di quello che diceva. Un esempio: leggere che un padrone «trattava bene» i suoi servi non significa affatto quello che significherebbe oggi, perché l'intera idea di che cosa sia dovuto a una persona era diversa. Contestualizzare non serve a giustificare, e non è la stessa cosa che approvare: serve a capire perché una cosa apparisse ovvia a chi la faceva, che è l'unico modo di spiegarla."},
		{"titolo": "L'anacronismo",
		 "testo": "Un anacronismo è attribuire a un'epoca qualcosa che non aveva. La forma evidente riguarda gli oggetti — un orologio da polso in un film sull'antica Roma — e fa ridere. La forma pericolosa riguarda le idee e le parole, perché non si vede. Chiedersi se un cittadino romano fosse «di destra o di sinistra» è un anacronismo: quelle categorie nascono con la Rivoluzione francese, nel 1789, e applicarle prima non produce una risposta sbagliata ma una domanda priva di senso. Lo stesso vale per «nazione», «razza», «infanzia», «privacy»: parole che oggi usiamo come se fossero sempre esistite, e che in altre epoche o non c'erano o significavano altro. Il primo controllo da fare su una propria frase è se le sue parole esistevano allora."},
		{"titolo": "Perché la storia si riscrive, e perché è un buon segno",
		 "testo": "Si sente dire che la storia viene continuamente riscritta, e a volte lo si dice come se fosse un difetto. È il contrario. Le ricostruzioni cambiano perché saltano fuori nuove fonti — un archivio riaperto, uno scavo, una tecnica di analisi che prima non esisteva — e perché si imparano a fare domande nuove al materiale già noto. Di conseguenza, quando uno storico trova un solo documento su un fatto, la cosa corretta da concludere non è che il fatto è accertato: è una ricostruzione provvisoria, da verificare quando e se altre fonti compariranno. Dichiarare provvisorio ciò che è provvisorio è precisione, non debolezza — ed è esattamente ciò che permette a chi verrà dopo di correggere."}],
	"glossario": [
		{"voce": "contestualizzare", "spiega": "Capire in che epoca e situazione è nata una fonte. Serve a capire, non a giustificare."},
		{"voce": "anacronismo", "spiega": "Attribuire a un'epoca qualcosa che non aveva: un oggetto, una parola o un'idea."},
		{"voce": "ricostruzione provvisoria", "spiega": "Quello che si può concludere da fonti scarse: va dichiarata tale, e verificata più avanti."},
		{"voce": "revisione", "spiega": "Il cambiamento di una ricostruzione quando arrivano fonti nuove. È il metodo che funziona, non un suo cedimento."}],
	"esempi": [
		{"prompt": "Che cos'è un anacronismo?", "answer": "Attribuire a un'epoca qualcosa che non aveva",
		 "explanation": "Vale per gli oggetti e, in modo più insidioso perché invisibile, per le parole e le idee: sono categorie che allora non esistevano."},
		{"prompt": "Uno storico trova un solo documento su un fatto. Cosa può concludere?", "answer": "Una ricostruzione provvisoria, da verificare",
		 "explanation": "Una fonte sola non permette il confronto: la conclusione resta aperta finché non compaiono altre tracce che la confermino o la smentiscano."}],
	"metodo": "Rileggi la tua frase sul passato e controlla le parole una per una: quali di queste esistevano allora, e con quale significato. È il modo più rapido per scoprire un anacronismo prima che lo scopra qualcun altro.",
	"errore": {"wrong": "Giudicare le scelte di un'epoca usando le categorie della nostra.",
		"why": "Produce una condanna comoda e nessuna spiegazione: per capire perché una cosa apparisse ovvia bisogna prima ricostruire che cosa si sapeva e si riteneva normale allora."},
	"insegna": ["contestualizzare", "anacronismo", "ricostruzione provvisoria", "revisione"]},

# ==============================================================================
# GEOGRAFIA — la terza materia convertita (11 settembre 2026)
#
# **È il caso più difficile dei tre**, e la misura lo diceva già dal 1 settembre:
# il 78% delle domande di geografia ha per risposta un NOME, e su `capitali` e
# `continenti` è il 100%. «Qual è la capitale della Norvegia?» non si ragiona.
#
# Le tavole di riferimento rispondono a quel problema elencando i nomi con la
# loro coordinata, e restano: sono quarantanove tavole e seicento voci, e nessuna
# dispensa può né deve ripetere quell'elenco. Le dispense fanno l'altra metà del
# lavoro, quella che mancava: **dicono perché le cose stanno dove stanno**.
#
#   la tavola dice      Oslo, in fondo a un fiordo
#   la dispensa dice    le capitali stanno dove passava il potere o il commercio,
#                       e la Norvegia è tutta costa
#
# Il primo nome si impara; il secondo criterio si applica a un Paese mai visto.
# Per questo le domande nuove di geografia chiedono quasi sempre di APPLICARE il
# criterio, e le poche di richiamo nominano solo ciò che il documento nomina —
# verificato dal controllo 4b, che da oggi vale anche per questa materia.

# ==================================================== GEOGRAFIA FISICA · base
"geografia-geografia-fisica-base": {
	"subject": "geografia", "topic": "geografia-fisica", "fasce": BANDA_BASE,
	"titolo": "Le forme della terra e dell'acqua, e i nomi che le distinguono",
	"apertura": "Quasi tutti i nomi della geografia fisica si definiscono per contrasto: si capiscono a coppie, mai uno alla volta.",
	"sezioni": [
		{"titolo": "Dove la terra incontra il mare",
		 "testo": "Un'isola è una terra circondata dal mare da OGNI lato: per arrivarci si attraversa l'acqua comunque si faccia. Una penisola è circondata su tre lati soltanto, e resta attaccata alla terraferma dal quarto: l'Italia è una penisola, e infatti ci si arriva da nord senza barche. Un arcipelago è un gruppo di isole vicine fra loro, considerate insieme perché condividono storia, clima e spesso abitanti. Restano due nomi che sono l'uno il rovescio dell'altro: un golfo è un tratto di mare che entra dentro la terra, uno stretto è un tratto di mare sottile fra due terre vicine. Osservare la carta chiedendosi «chi entra in chi» risolve quasi sempre il dubbio su quale nome usare."},
		{"titolo": "I rilievi, e perché le montagne più alte sono le più giovani",
		 "testo": "Si chiama montagna un rilievo che supera i seicento metri, collina quello che resta sotto, pianura una terra distesa quasi senza dislivelli, altopiano una pianura che però sta in alto. Le montagne nascono dove due grandi pezzi della crosta terrestre si spingono l'uno contro l'altro e il terreno si corruga, come un tappeto spinto contro un muro. Da qui una conseguenza che sembra strana e non lo è: le catene più alte sono le più GIOVANI, perché una montagna appena sollevata non ha ancora avuto tempo di essere consumata. Pioggia, gelo e vento smussano tutto, lentamente e senza fermarsi: una catena antichissima è oggi una fila di colline arrotondate."},
		{"titolo": "L'acqua che scorre, e quello che si porta dietro",
		 "testo": "Un fiume nasce dalla sorgente e finisce alla foce, dove si getta nel mare o in un lago. Lungo il percorso riceve altri corsi d'acqua più piccoli: ciascuno di questi si chiama affluente, e l'insieme del territorio che scarica l'acqua in quel fiume è il suo bacino. Un fiume non porta solo acqua: strappa terra e sassi dove scende ripido e veloce, e li lascia cadere dove rallenta. È per questo che alla foce si formano spesso i delta, ventagli di terra nuova, e che le grandi pianure sono quasi sempre state costruite dai fiumi che le attraversano, un deposito alla volta, per migliaia di anni."}],
	"glossario": [
		{"voce": "isola", "spiega": "Terra circondata dal mare da ogni lato. Una penisola invece resta attaccata su un lato."},
		{"voce": "penisola", "spiega": "Terra circondata dal mare su tre lati, unita alla terraferma dal quarto. L'Italia lo è."},
		{"voce": "arcipelago", "spiega": "Un gruppo di isole vicine fra loro, considerate come un insieme."},
		{"voce": "affluente", "spiega": "Un corso d'acqua che si getta in un altro fiume invece che nel mare."}],
	"esempi": [
		{"prompt": "Che cos'è un'isola?", "answer": "Una terra circondata dal mare da ogni lato",
		 "explanation": "Il «da ogni lato» è la parte che conta: se un lato resta attaccato alla terraferma non è un'isola ma una penisola."},
		{"prompt": "Che cos'è un arcipelago?", "answer": "Un gruppo di isole vicine fra loro",
		 "explanation": "Il nome vale per l'insieme, non per una sola isola: si usa perché quelle isole condividono clima, storia e spesso abitanti."}],
	"metodo": "Davanti a una forma sulla carta chiediti da quanti lati la tocca l'acqua, e se è l'acqua a entrare nella terra o la terra a entrare nell'acqua. Quasi tutti i nomi della geografia fisica si decidono con queste due domande.",
	"errore": {"wrong": "Chiamare isola una penisola come l'Italia.",
		"why": "Il mare la circonda su tre lati, ma il quarto è attaccato al continente: ci si arriva da nord via terra, senza attraversare acqua."},
	"insegna": ["isola", "penisola", "arcipelago", "affluente", "foce"]},

# ==================================================== GEOGRAFIA FISICA · alta
"geografia-geografia-fisica-alta": {
	"subject": "geografia", "topic": "geografia-fisica", "fasce": BANDA_ALTA,
	"titolo": "Perché i deserti stanno tutti sulla stessa fascia",
	"apertura": "Guardando un mappamondo i grandi deserti sembrano sparsi a caso. Messi su una riga, si scopre che stanno quasi tutti alla stessa distanza dall'equatore.",
	"sezioni": [
		{"titolo": "La fascia dei deserti",
		 "testo": "All'equatore il sole scalda fortissimo, l'aria si solleva e salendo si raffredda: l'umidità che conteneva condensa e cade come pioggia, ed è per questo che lì crescono le foreste più fitte del pianeta. Quell'aria però, ormai secca, continua a salire, si sposta in quota verso nord e verso sud, e ridiscende a circa trenta gradi di latitudine. Scendendo si riscalda e si asciuga ancora: arriva al suolo calda e senza una goccia. È la ragione per cui su quella fascia stanno il Sahara, il deserto arabico, il Kalahari e i grandi deserti australiani. Il Sahara, in Africa, è il più esteso deserto caldo della Terra. Non è un caso e non è una coincidenza: è il punto in cui torna giù l'aria che ha già piovuto altrove."},
		{"titolo": "Le catene giovani, e quella che cresce ancora",
		 "testo": "Dove due placche si scontrano frontalmente il terreno si solleva, e le catene più alte del pianeta sono quelle in cui lo scontro è ancora in corso. L'Himalaya nasce dalla spinta dell'India contro l'Asia, e ospita l'Everest, la montagna più alta della Terra: continua a sollevarsi di qualche millimetro all'anno, mentre l'erosione ne toglie quasi altrettanti. Le Ande corrono lungo tutto il bordo occidentale dell'America del Sud, dove la placca oceanica si infila sotto il continente — e per lo stesso motivo sono piene di vulcani. Le Alpi nascono dalla spinta dell'Africa contro l'Europa. Tre catene, una sola causa."},
		{"titolo": "I fiumi grandi: lunghezza e portata non sono la stessa cosa",
		 "testo": "Il Rio delle Amazzoni, in America del Sud, scarica in mare più acqua di qualunque altro fiume del pianeta, tanta che l'oceano resta meno salato per decine di chilometri al largo. Il Nilo, in Africa, è fra i più lunghi, ma attraversa il deserto e ne arriva molta meno. Sono due misure diverse, e conviene tenerle separate: la lunghezza dipende da quanta strada fa, la portata da quanta pioggia cade sul suo bacino. Un fiume lunghissimo che attraversa terre aride può portare pochissima acqua, e uno più corto che raccoglie una foresta intera può portarne moltissima."}],
	"glossario": [
		{"voce": "Sahara", "spiega": "Il più esteso deserto caldo della Terra, in Africa, sulla fascia dei trenta gradi."},
		{"voce": "Everest", "spiega": "La montagna più alta della Terra, nell'Himalaya. Si solleva ancora di qualche millimetro l'anno."},
		{"voce": "bacino", "spiega": "Tutto il territorio che scarica la propria acqua in un certo fiume."},
		{"voce": "portata", "spiega": "Quanta acqua un fiume trasporta. È una misura diversa dalla lunghezza, e spesso non vanno insieme."}],
	"esempi": [
		{"prompt": "In quale continente si trova il deserto del Sahara?", "answer": "Africa",
		 "explanation": "Occupa tutta la fascia settentrionale del continente, proprio dove ridiscende l'aria ormai secca che è salita all'equatore."},
		{"prompt": "In quale continente scorre il Rio delle Amazzoni?", "answer": "America del Sud",
		 "explanation": "Raccoglie l'acqua della più grande foresta pluviale del pianeta, e per questo scarica in mare più acqua di qualunque altro fiume."}],
	"metodo": "Quando devi indovinare se una zona è arida, guarda prima quanto dista dall'equatore. Sull'equatore piove moltissimo, intorno ai trenta gradi quasi mai: due fasce vicine e opposte.",
	"errore": {"wrong": "Pensare che un fiume lungo porti per forza molta acqua.",
		"why": "La portata dipende da quanta pioggia cade sul bacino, non da quanta strada fa: il Nilo è lunghissimo e attraversa il deserto."},
	"insegna": ["Sahara", "Everest", "Himalaya", "Ande", "Rio delle Amazzoni"]},

# ============================================================== CLIMI · base
"geografia-climi-base": {
	"subject": "geografia", "topic": "climi", "fasce": BANDA_BASE,
	"titolo": "Perché all'equatore fa caldo, e ai poli no",
	"apertura": "Il Sole è lo stesso per tutti. Quello che cambia da un punto all'altro della Terra è l'inclinazione con cui i suoi raggi arrivano al suolo.",
	"sezioni": [
		{"titolo": "L'inclinazione dei raggi decide tutto",
		 "testo": "La Terra è una sfera, quindi i raggi del Sole non possono colpirla ovunque allo stesso modo. All'equatore arrivano quasi perpendicolari e concentrano il loro calore su una superficie piccola. Vicino ai poli arrivano radenti, quasi striscianti, e lo stesso fascio di luce si spalma su una superficie molto più larga: lo stesso calore diviso su più terreno scalda molto meno. È lo stesso effetto che si vede puntando una torcia su un muro, prima dritta e poi di sbieco: la macchia di luce si allunga e diventa più debole. Da questa sola causa nascono le fasce climatiche: torrida attorno all'equatore, temperate nelle zone intermedie, polari alle due estremità."},
		{"titolo": "Il tempo di oggi e il clima di sempre",
		 "testo": "Sono due cose diverse e si confondono continuamente. Il tempo meteorologico è quello che fa adesso o farà domani: pioggia, sole, vento, e cambia di ora in ora. Il clima è la MEDIA di molti anni di tempo in un certo luogo — trent'anni è il periodo che si usa di solito. Ne segue una conseguenza che vale la pena tenere in mente: una giornata gelida in un paese caldo non contraddice il suo clima, e nemmeno una settimana. Per dire qualcosa sul clima bisogna guardare decenni, non giornate, ed è il motivo per cui i dati climatici si leggono sempre su grafici lunghi."},
		{"titolo": "Le tre cose che spostano il clima di un luogo",
		 "testo": "A parità di tutto il resto, tre fattori modificano il clima di un posto. La latitudine, cioè la distanza dall'equatore: è quella di cui si è appena parlato, e pesa più delle altre. L'altitudine: salendo la temperatura cala di circa sei gradi ogni mille metri, e per questo esistono ghiacciai anche in Africa, sulle cime più alte. La vicinanza al mare: l'acqua si scalda e si raffredda molto più lentamente della terra, quindi le coste hanno inverni meno rigidi ed estati meno torride, mentre l'interno dei continenti oscilla molto di più."}],
	"glossario": [
		{"voce": "latitudine", "spiega": "La distanza dall'equatore. È il fattore che pesa di più sul clima di un luogo."},
		{"voce": "altitudine", "spiega": "L'altezza sul livello del mare. Salendo si perdono circa sei gradi ogni mille metri."},
		{"voce": "tempo meteorologico", "spiega": "Che cosa fa oggi o domani. Cambia di ora in ora, e non è il clima."},
		{"voce": "clima", "spiega": "La media del tempo su molti anni, di solito trenta, in un certo luogo."}],
	"esempi": [
		{"prompt": "In quale zona della Terra fa caldo tutto l'anno?", "answer": "Vicino all'Equatore",
		 "explanation": "Lì i raggi arrivano quasi perpendicolari e concentrano il calore su poca superficie, in ogni stagione."},
		{"prompt": "Qual è la differenza fra tempo meteorologico e clima?", "answer": "Il tempo è di oggi, il clima è la media di molti anni",
		 "explanation": "Una giornata fredda non dice niente sul clima di un luogo: per parlare di clima servono decenni di misure."}],
	"metodo": "Per stimare il clima di un posto guarda tre numeri in quest'ordine: quanto dista dall'equatore, quanto sta in alto, quanto è vicino al mare. In quest'ordine, perché è l'ordine del loro peso.",
	"errore": {"wrong": "Dire che un'estate fresca smentisce il clima caldo di una regione.",
		"why": "Confonde il tempo con il clima: il clima è la media di decenni, e una stagione fuori media ci sta dentro senza cambiarla."},
	"insegna": ["Equatore", "fascia torrida", "latitudine", "altitudine"]},

# ============================================================== CLIMI · alta
"geografia-climi-alta": {
	"subject": "geografia", "topic": "climi", "fasce": BANDA_ALTA,
	"titolo": "Il clima di casa nostra, e il vento che lo porta",
	"apertura": "Perché in Italia piove d'inverno e non d'estate, mentre all'equatore piove tutto l'anno? La risposta sta in che cosa fa l'aria quando si sposta.",
	"sezioni": [
		{"titolo": "Il vento è aria che si sposta",
		 "testo": "Il vento è aria che si sposta verso dove la pressione è minore. Dove l'aria è più calda si dilata, pesa meno e sale, lasciando sotto di sé una pressione bassa; l'aria vicina, più fredda e pesante, scivola in quel posto — e quello scorrimento è il vento. Si vede in piccolo ogni giorno al mare: la terra si scalda in fretta e di giorno l'aria sale da lì, richiamando la brezza dal mare verso la costa; di notte la terra si raffredda prima dell'acqua e la brezza gira al contrario. Gli stessi movimenti, alla scala di un continente, producono i venti che decidono dove piove."},
		{"titolo": "Il clima mediterraneo",
		 "testo": "Il clima mediterraneo, tipico dell'Italia, ha una firma inconfondibile: estati calde e secche, inverni miti e piovosi. Non è una stranezza locale: dipende dal fatto che d'estate la fascia di alta pressione dei deserti si sposta un po' più a nord e copre il Mediterraneo, spingendo via le perturbazioni; d'inverno quella fascia scende di nuovo verso sud, e le perturbazioni atlantiche possono rientrare. Il mare fa il resto, smorzando gli sbalzi. È per questo che qui la pioggia e il caldo non capitano insieme, al contrario di quasi tutto il resto d'Europa, dove i temporali estivi sono normali."},
		{"titolo": "Tre grandi ambienti, tre regimi di pioggia",
		 "testo": "La foresta pluviale, la grande foresta calda e piovosa attorno all'equatore, riceve pioggia tutto l'anno: caldo costante, umidità costante, e per questo la maggiore varietà di specie del pianeta. La savana sta poco più a nord e poco più a sud, e riceve la stessa quantità d'acqua concentrata in una sola stagione: alberi radi, erba alta, e una lunga stagione secca in cui gli animali si spostano. La tundra, alle latitudini più alte, ha pochissime piogge e un terreno gelato per gran parte dell'anno: nessun albero vi cresce, perché le radici non trovano terra scongelata abbastanza in profondità."}],
	"glossario": [
		{"voce": "clima mediterraneo", "spiega": "Estati calde e secche, inverni miti e piovosi. È il clima dell'Italia."},
		{"voce": "pressione", "spiega": "Il peso dell'aria su un punto. Il vento va sempre da dove è alta a dove è bassa."},
		{"voce": "foresta pluviale", "spiega": "La grande foresta calda e piovosa attorno all'equatore, con pioggia in ogni stagione."},
		{"voce": "savana", "spiega": "Erba alta e alberi radi, con la pioggia concentrata in una sola stagione e una lunga secca."}],
	"esempi": [
		{"prompt": "Che cos'è il vento?", "answer": "Aria che si sposta dove la pressione è minore",
		 "explanation": "L'aria calda sale e lascia sotto di sé pressione bassa: quella vicina, più fredda e pesante, scivola a prenderne il posto."},
		{"prompt": "Che cosa caratterizza il clima mediterraneo?", "answer": "Estati calde e secche, inverni miti e piovosi",
		 "explanation": "D'estate l'alta pressione dei deserti risale e tiene lontane le perturbazioni; d'inverno scende, e quelle atlantiche rientrano."}],
	"metodo": "Per capire dove piove, segui l'aria invece della carta: dove sale piove, dove scende è secco. Sono le due sole cose che devi ricordare, e spiegano tanto le foreste quanto i deserti.",
	"errore": {"wrong": "Descrivere il clima mediterraneo come piovoso d'estate.",
		"why": "È il contrario, ed è la sua firma: d'estate l'alta pressione blocca le perturbazioni, e la pioggia si concentra nella stagione fredda."},
	"insegna": ["clima mediterraneo", "foresta pluviale", "savana", "pressione", "brezza"]},

# ========================================================= CONTINENTI · base
"geografia-continenti-base": {
	"subject": "geografia", "topic": "continenti", "fasce": BANDA_BASE,
	"titolo": "Sette terre, e dove finisce una e comincia l'altra",
	"apertura": "Contare i continenti sembra una cosa da imparare a memoria. In realtà uno dei sette confini non è affatto naturale, e sapere quale spiega parecchio.",
	"sezioni": [
		{"titolo": "I sette, e quanti sono davvero abitati",
		 "testo": "I continenti sono sette: Africa, America del Nord, America del Sud, Antartide, Asia, Europa e Oceania. Di questi, gli abitati stabilmente sono SEI: l'Antartide non ha popolazione residente, ma soltanto basi scientifiche in cui i ricercatori si alternano per qualche mese alla volta e poi tornano a casa. È la distinzione che sta dietro a due domande che sembrano identiche e non lo sono: «quanti continenti ci sono» fa sette, «quanti ne sono abitati» fa sei. L'Asia è il più grande e anche il più popoloso; l'Oceania è il più piccolo; l'Europa è piccola e molto densamente abitata."},
		{"titolo": "Il confine che non è fatto d'acqua",
		 "testo": "Sei confini fra continenti sono oceani, e si vedono su qualunque carta. Uno no. Europa e Asia stanno sulla stessa massa di terra continua, e il confine fra loro è tracciato lungo i Monti Urali, una catena che attraversa la Russia da nord a sud. Non è una divisione geologica: è una convenzione storica e culturale, fissata da geografi molti secoli fa, e infatti chi guarda la sola crosta terrestre parla di un unico blocco, l'Eurasia. La conseguenza più visibile è che la Russia si estende su due continenti, con la parte europea a ovest degli Urali e quella asiatica, molto più grande, a est."},
		{"titolo": "Collocare un Paese",
		 "testo": "Sapere in quale continente sta un Paese è la prima coordinata di ogni altra cosa che se ne dirà, perché il continente porta con sé clima, vicini e storia. Italia, Francia, Spagna, Germania, Portogallo e Regno Unito stanno tutti in Europa: è il continente più frastagliato, pieno di penisole e di isole, e nessuno dei suoi punti è lontanissimo dal mare. Questo spiega perché la sua storia sia stata così fatta di navigazione e di commercio: per gli europei il mare non è mai stato un confine lontano ma una strada che comincia poco lontano da casa."}],
	"glossario": [
		{"voce": "continente", "spiega": "Una delle sette grandi masse di terra. Sei sono abitate stabilmente: l'Antartide no."},
		{"voce": "Monti Urali", "spiega": "La catena che segna il confine convenzionale fra Europa e Asia, dentro la Russia."},
		{"voce": "Antartide", "spiega": "Il continente intorno al polo sud: nessuna popolazione residente, solo basi scientifiche."},
		{"voce": "Oceania", "spiega": "Il continente più piccolo: Australia, Nuova Zelanda e le isole del Pacifico."}],
	"esempi": [
		{"prompt": "In quale continente si trova l'Italia?", "answer": "Europa",
		 "explanation": "L'Italia è una penisola del Mediterraneo, e il Mediterraneo è il mare interno dell'Europa meridionale."},
		{"prompt": "Dei sette continenti, quanti sono abitati stabilmente?", "answer": "6",
		 "explanation": "L'Antartide non ha popolazione residente: nelle sue basi i ricercatori si alternano per qualche mese e poi rientrano."}],
	"metodo": "Prima di rispondere, controlla se la domanda dice «quanti sono» o «quanti sono abitati»: è una sola parola di differenza e cambia la risposta da sette a sei.",
	"errore": {"wrong": "Cercare il confine fra Europa e Asia lungo un mare.",
		"why": "Fra i sette continenti è l'unico confine di terra: passa per i Monti Urali, ed è una convenzione storica e non una separazione naturale."},
	"insegna": ["Europa", "Asia", "Africa", "Antartide", "Oceania", "Monti Urali"]},

# ========================================================= CONTINENTI · alta
"geografia-continenti-alta": {
	"subject": "geografia", "topic": "continenti", "fasce": BANDA_ALTA,
	"titolo": "Perché i continenti hanno proprio quella forma",
	"apertura": "Chi guarda una carta del mondo prima o poi nota una cosa: la costa occidentale dell'Africa e quella orientale del Sud America sembrano combaciare. Non è un'illusione.",
	"sezioni": [
		{"titolo": "La crosta è in pezzi, e i pezzi si muovono",
		 "testo": "Lo strato solido esterno della Terra non è un guscio intero ma un mosaico di grandi pezzi, chiamati placche, che galleggiano su materiale caldissimo e lentamente deformabile. Si spostano di pochi centimetri all'anno — più o meno come crescono le unghie — ma su tempi lunghissimi quei centimetri fanno migliaia di chilometri. Circa duecento milioni di anni fa tutte le terre emerse erano riunite in un unico blocco, che i geologi chiamano Pangea; poi si è spezzato e i frammenti si sono allontanati. È per questo che le coste di Africa e America del Sud combaciano: un tempo erano attaccate, e l'Atlantico si è aperto fra loro."},
		{"titolo": "Che cosa succede sul bordo di una placca",
		 "testo": "Quasi tutto ciò che di violento accade sulla Terra accade sui bordi delle placche, e ce ne sono di tre tipi. Dove due placche si scontrano il terreno si solleva e nascono le grandi catene montuose; se una delle due si infila sotto l'altra, il materiale che sprofonda si fonde e risale in superficie come vulcano. Dove si allontanano si apre una spaccatura da cui esce roccia fusa che forma crosta nuova: sotto gli oceani queste spaccature formano lunghissime catene sommerse, le dorsali. Dove scorrono l'una accanto all'altra, si incastrano e poi scattano: sono i terremoti. Attorno all'Oceano Pacifico i bordi sono quasi tutti attivi, e quella corona di vulcani e terremoti viene chiamata cerchio di fuoco."},
		{"titolo": "Grandezza e popolazione non vanno insieme",
		 "testo": "L'Asia è il continente più grande e anche il più popoloso, e in questo caso le due cose coincidono; ma è un caso, non una regola. L'Antartide è più grande dell'Europa e non ha abitanti stabili; l'Oceania è piccolissima e ha pochissima gente; l'Europa, che è il secondo più piccolo dopo l'Oceania, è fra i più densamente abitati. Quello che decide dove vive la gente non è lo spazio disponibile ma quanto quel posto è abitabile: acqua dolce, terra coltivabile, un clima che non uccida. Un continente può essere immenso e quasi vuoto."}],
	"glossario": [
		{"voce": "placca", "spiega": "Uno dei grandi pezzi in cui è divisa la crosta terrestre. Si spostano di pochi centimetri l'anno."},
		{"voce": "Pangea", "spiega": "Il blocco unico in cui erano riunite tutte le terre emerse circa duecento milioni di anni fa."},
		{"voce": "dorsale", "spiega": "La catena sommersa che si forma dove due placche oceaniche si allontanano e nasce crosta nuova."},
		{"voce": "cerchio di fuoco", "spiega": "La corona di vulcani e terremoti che circonda l'Oceano Pacifico, sui bordi attivi delle placche."}],
	"esempi": [
		{"prompt": "Perché le coste di Africa e America del Sud sembrano combaciare?", "answer": "Perché erano attaccate e si sono separate",
		 "explanation": "Facevano parte dello stesso blocco, la Pangea: quando si è spezzato, l'Atlantico si è aperto nello spazio fra le due."},
		{"prompt": "Su quali due continenti si estende la Russia?", "answer": "Europa e Asia",
		 "explanation": "Il confine convenzionale passa per i Monti Urali, che attraversano la Russia: a ovest la parte europea, a est quella asiatica, molto più vasta."}],
	"metodo": "Quando una domanda riguarda montagne, vulcani o terremoti, cerca il bordo di placca più vicino. Quasi tutto quello che di violento accade sulla Terra accade là, e quasi nulla accade al centro delle placche.",
	"errore": {"wrong": "Pensare che il continente più grande sia per forza il più popoloso.",
		"why": "Vale per l'Asia e per caso: l'Antartide è più grande dell'Europa e non ha abitanti stabili. Decide l'abitabilità, non lo spazio."},
	"insegna": ["placca", "Pangea", "dorsale", "cerchio di fuoco"]},

# ============================================================== MONDO · base
"geografia-mondo-base": {
	"subject": "geografia", "topic": "mondo", "fasce": BANDA_BASE,
	"titolo": "Un pianeta fatto per tre quarti d'acqua",
	"apertura": "Chiamarlo Terra è quasi un errore di battitura: le terre emerse sono meno di un terzo della superficie, e il resto è oceano.",
	"sezioni": [
		{"titolo": "Gli oceani, e quello che è più grande di tutte le terre",
		 "testo": "L'acqua salata copre circa il settanta per cento della superficie del pianeta, ed è divisa in cinque oceani: Pacifico, Atlantico, Indiano, Artico e Antartico. Il Pacifico è di gran lunga il più esteso — da solo copre più superficie di tutte le terre emerse messe insieme — ed è anche il più profondo. L'Atlantico separa Europa e Africa dalle Americhe ed è quello che si è aperto quando le terre si sono separate. I mari sono invece tratti d'acqua salata più piccoli e in parte chiusi dalle terre, come il Mediterraneo: la differenza fra mare e oceano è di dimensione e di apertura, non di natura."},
		{"titolo": "Grande non vuol dire affollato",
		 "testo": "Due domande che sembrano la stessa e danno risposte diverse. Il Paese più grande del mondo per superficie è la Russia, che occupa da sola più di un ottavo di tutte le terre emerse; ma buona parte di quel territorio è Siberia, fredda e quasi vuota. Il Paese più popoloso oggi è l'India, che ha una superficie molto minore. La lezione generale vale ovunque: la quantità di terra e la quantità di gente sono due misure indipendenti, perché quello che conta per vivere non è quanto spazio c'è ma quanto ne è abitabile — acqua dolce, terra coltivabile, un clima sopportabile."},
		{"titolo": "L'equatore, gli emisferi e le stagioni al contrario",
		 "testo": "L'equatore è la linea immaginaria che gira attorno alla Terra a metà strada fra i due poli, e divide il pianeta in emisfero settentrionale ed emisfero meridionale. Poiché l'asse della Terra è inclinato, quando un emisfero è rivolto verso il Sole riceve raggi più diretti e giornate più lunghe — cioè è estate — mentre l'altro è nella situazione opposta. Ne segue una cosa che stupisce sempre: le stagioni nei due emisferi sono INVERTITE. A Natale in Argentina e in Australia è piena estate, e chi ci vive associa le vacanze estive a dicembre invece che a luglio."}],
	"glossario": [
		{"voce": "oceano", "spiega": "Una delle cinque grandi distese d'acqua salata. Il Pacifico è il più esteso e il più profondo."},
		{"voce": "mare", "spiega": "Un tratto d'acqua salata più piccolo e in parte chiuso dalle terre, come il Mediterraneo."},
		{"voce": "equatore", "spiega": "La linea immaginaria a metà fra i poli. Divide il pianeta nei due emisferi."},
		{"voce": "emisfero", "spiega": "Una delle due metà della Terra separate dall'equatore. Le loro stagioni sono invertite."}],
	"esempi": [
		{"prompt": "Qual è l'oceano più esteso del pianeta?", "answer": "Pacifico",
		 "explanation": "Da solo copre più superficie di tutte le terre emerse messe insieme, ed è anche il più profondo."},
		{"prompt": "Qual è il Paese più grande del mondo per superficie?", "answer": "Russia",
		 "explanation": "Occupa più di un ottavo delle terre emerse, ma gran parte è Siberia: grande non vuol dire popoloso, e il più popoloso è l'India."}],
	"metodo": "Quando una domanda dice «più grande», controlla sempre più grande in che cosa: superficie e popolazione danno due classifiche diverse, e quasi mai lo stesso vincitore.",
	"errore": {"wrong": "Dare per scontato che a dicembre sia inverno in tutto il mondo.",
		"why": "Nell'emisfero meridionale le stagioni sono invertite: a dicembre in Argentina e in Australia è piena estate."},
	"insegna": ["Pacifico", "Atlantico", "Russia", "India", "equatore", "emisfero"]},

# ============================================================== MONDO · alta
"geografia-mondo-alta": {
	"subject": "geografia", "topic": "mondo", "fasce": BANDA_ALTA,
	"titolo": "Le strettoie del pianeta, e l'ora che cambia",
	"apertura": "Su una mappa del commercio mondiale quasi tutte le rotte passano per cinque o sei punti larghi pochi chilometri. Quei punti decidono più di molti confini.",
	"sezioni": [
		{"titolo": "I canali scavati apposta",
		 "testo": "Il Canale di Suez, aperto nel 1869, taglia l'istmo fra Mar Mediterraneo e Mar Rosso: prima di allora una nave che andava dall'Europa all'Asia doveva circumnavigare tutta l'Africa, e il canale le risparmia migliaia di chilometri. Il Canale di Panama, aperto nel 1914, fa lo stesso fra Atlantico e Pacifico, evitando il giro attorno al Sud America. Sono due opere enormi con lo stesso effetto: accorciano il tempo, e quindi il costo, di quasi tutto quello che si muove via mare. È anche il motivo per cui il controllo di un canale è sempre stato una questione politica seria — chi lo tiene può rallentare il commercio di mezzo mondo."},
		{"titolo": "Gli stretti naturali",
		 "testo": "Alcune strettoie non le ha scavate nessuno. Lo stretto di Gibilterra è l'unica porta fra Atlantico e Mediterraneo, largo appena una quindicina di chilometri. Il Bosforo, dentro la città di Istanbul, collega il Mar Nero al Mediterraneo ed è ancora più stretto. Lo stretto di Malacca, fra Malesia e Indonesia, è il passaggio obbligato fra Oceano Indiano e Pacifico. Ogni strettoia è due cose insieme: un punto di forza per chi la controlla e un punto di fragilità per tutti gli altri, perché basta un incidente o una chiusura a fermare un flusso enorme di merci."},
		{"titolo": "I fusi orari",
		 "testo": "La Terra compie un giro completo su se stessa, trecentosessanta gradi, in ventiquattro ore: quindici gradi ogni ora. Per questo il globo è diviso in ventiquattro fusi orari, ognuno largo circa quindici gradi di longitudine, e spostandosi verso est l'orologio va avanti, verso ovest indietro. Il punto di partenza del conteggio è il meridiano di Greenwich, scelto per convenzione internazionale. I confini dei fusi però non sono righe dritte: si piegano per seguire i confini degli Stati, perché nessun Paese vuole due ore diverse in due quartieri della stessa città."}],
	"glossario": [
		{"voce": "Canale di Suez", "spiega": "Aperto nel 1869 fra Mediterraneo e Mar Rosso: evita alle navi il giro dell'Africa."},
		{"voce": "Canale di Panama", "spiega": "Aperto nel 1914 fra Atlantico e Pacifico: evita il giro del Sud America."},
		{"voce": "stretto", "spiega": "Un passaggio d'acqua sottile fra due terre. Gibilterra, il Bosforo e Malacca sono i più trafficati."},
		{"voce": "fuso orario", "spiega": "Una delle ventiquattro fasce di circa quindici gradi in cui è divisa la Terra per l'ora."}],
	"esempi": [
		{"prompt": "Attraverso quale canale le navi passano tra Mar Mediterraneo e Mar Rosso?", "answer": "Canale di Suez",
		 "explanation": "Aperto nel 1869: senza di esso una nave diretta in Asia dovrebbe circumnavigare l'intera Africa."},
		{"prompt": "Quanti gradi di longitudine copre un fuso orario?", "answer": "15",
		 "explanation": "La Terra compie trecentosessanta gradi in ventiquattro ore, quindi quindici gradi corrispondono a un'ora."}],
	"metodo": "Davanti a una domanda su una rotta commerciale, cerca il punto più stretto del percorso. È lì che si decidono i costi, e quasi sempre è lì che sta la risposta.",
	"errore": {"wrong": "Immaginare i confini dei fusi orari come righe perfettamente dritte.",
		"why": "Si piegano per seguire i confini degli Stati: nessun Paese accetta di avere due ore diverse in due quartieri della stessa città."},
	"insegna": ["Canale di Suez", "Canale di Panama", "Gibilterra", "fuso orario", "Greenwich"]},

# ============================================================= EUROPA · base
"geografia-europa-base": {
	"subject": "geografia", "topic": "europa", "fasce": BANDA_BASE,
	"titolo": "Un continente piccolo con moltissima costa",
	"apertura": "L'Europa è il secondo continente più piccolo. Quello che la distingue non è la dimensione ma quanto è frastagliata: nessun suo punto è davvero lontano dal mare.",
	"sezioni": [
		{"titolo": "Penisole, isole, e una conseguenza storica",
		 "testo": "Guardando la carta l'Europa sembra sfilacciata: dalla massa centrale sporgono la penisola iberica a sud-ovest, la penisola italiana al centro, la penisola balcanica a sud-est e la penisola scandinava a nord, e tutto attorno stanno isole grandi e piccole. Nessun altro continente ha un rapporto così alto fra lunghezza delle coste e superficie. Da qui una conseguenza che riguarda la storia più della geografia: per un europeo il mare non è mai stato un confine lontano da raggiungere con una spedizione, ma una strada che comincia a poche giornate da casa. Navigazione, pesca e commercio marittimo sono stati normali qui molto prima che altrove."},
		{"titolo": "I fiumi, e quello che attraversa dieci Paesi",
		 "testo": "I fiumi europei sono corti rispetto a quelli di altri continenti, ma fittissimi e quasi tutti navigabili, e per secoli sono stati le vere autostrade del continente. Il Danubio è il più internazionale di tutti: nasce in Germania, scorre verso est e attraversa dieci Paesi diversi prima di sfociare nel Mar Nero — nessun altro fiume al mondo ne tocca altrettanti. La Senna attraversa Parigi, e la città è nata proprio su un'isola in mezzo al suo corso. Il Reno collega le Alpi al Mare del Nord ed è la via d'acqua più trafficata d'Europa. Il Volga, in Russia, è il più lungo del continente."},
		{"titolo": "Dove finisce l'Europa",
		 "testo": "A ovest, a sud e a nord i confini dell'Europa sono acqua, e non c'è dubbio su dove passino. A est no: lì l'Europa continua senza interruzione nella stessa massa di terra dell'Asia, e il confine è tracciato per convenzione lungo i Monti Urali, la catena che attraversa la Russia da nord a sud. Sapere questo evita l'errore più comune sulla Russia, che risulta così un Paese a cavallo di due continenti. E spiega perché domande come «dove finisce l'Europa» non abbiano una risposta naturale ma una risposta concordata: è una decisione di geografi, non una cosa che si vede dal satellite."}],
	"glossario": [
		{"voce": "Danubio", "spiega": "Il fiume che attraversa dieci Paesi, dalla Germania al Mar Nero: il più internazionale del mondo."},
		{"voce": "Senna", "spiega": "Il fiume che attraversa Parigi. La città è nata su un'isola in mezzo al suo corso."},
		{"voce": "Reno", "spiega": "Dalle Alpi al Mare del Nord: la via d'acqua più trafficata d'Europa."},
		{"voce": "penisola scandinava", "spiega": "La grande penisola del nord Europa, con Norvegia e Svezia."}],
	"esempi": [
		{"prompt": "Quale fiume attraversa la città di Parigi?", "answer": "Senna",
		 "explanation": "La città è nata su un'isola in mezzo al suo corso: un'isola fluviale è facile da difendere e sta su un punto di guado."},
		{"prompt": "Quale grande fiume europeo attraversa dieci Paesi diversi?", "answer": "Danubio",
		 "explanation": "Nasce in Germania e scorre verso est fino al Mar Nero: nessun altro fiume al mondo ne tocca altrettanti."}],
	"metodo": "Per ricordare dove sta una città europea cercane il fiume: quasi tutte sono nate su un corso d'acqua, e il fiume le mette in fila meglio di qualunque elenco.",
	"errore": {"wrong": "Cercare un mare fra Europa e Asia.",
		"why": "A est non c'è acqua: le due si toccano sulla stessa terra, e il confine passa per i Monti Urali per convenzione."},
	"insegna": ["Danubio", "Senna", "Reno", "penisola scandinava", "Monti Urali"]},

# ============================================================= EUROPA · alta
"geografia-europa-alta": {
	"subject": "geografia", "topic": "europa", "fasce": BANDA_ALTA,
	"titolo": "Stati che hanno deciso di decidere insieme",
	"apertura": "Nella prima metà del Novecento gli Stati europei si sono combattuti due volte. Quello che è venuto dopo nasce esattamente da lì.",
	"sezioni": [
		{"titolo": "Perché nasce l'Unione Europea",
		 "testo": "L'Unione Europea è l'unione economica e politica di molti Stati europei, e la sua idea di partenza è semplice quanto spregiudicata: legare fra loro le economie di Paesi che si erano appena fatti la guerra, così strettamente da rendere una guerra futura non solo sbagliata ma sconveniente. Si comincia negli anni Cinquanta mettendo in comune il carbone e l'acciaio — cioè proprio le materie con cui si fabbricano le armi — e si prosegue allargando il campo: commercio, agricoltura, ambiente, ricerca. Gli Stati membri restano Stati, con i loro governi e le loro leggi, e trasferiscono all'Unione alcune decisioni che conviene prendere insieme."},
		{"titolo": "Mercato unico, circolazione, moneta",
		 "testo": "Tre conseguenze si toccano con mano. Il mercato unico: le merci attraversano i confini interni senza dazi né controlli doganali, e le regole sui prodotti sono comuni, così un oggetto approvato in un Paese è vendibile in tutti. La libera circolazione: i cittadini possono viaggiare, studiare e lavorare negli altri Stati membri. E l'euro, la moneta comune, che però NON è adottata da tutti i membri: alcuni hanno mantenuto la propria valuta. È un dettaglio che vale la pena ricordare, perché smonta l'idea che l'Unione sia un blocco uniforme: è un insieme di accordi a geometria variabile, a cui ciascuno partecipa in misura diversa."},
		{"titolo": "Confini che si muovono e confini che no",
		 "testo": "Una carta politica dell'Europa del 1900, una del 1950 e una di oggi mostrano Paesi diversi, con nomi diversi e confini diversi: gli Stati nascono, si uniscono, si dividono. Una carta fisica degli stessi tre momenti invece è praticamente identica, perché montagne, fiumi e coste si muovono su tempi geologici. È la differenza pratica fra i due tipi di carta: la politica invecchia e va aggiornata, la fisica no. Quando una domanda parla di confini conviene sempre chiedersi di quale tipo si tratti, perché un confine politico è una decisione umana e può cambiare l'anno prossimo."}],
	"glossario": [
		{"voce": "Unione Europea", "spiega": "L'unione economica e politica di molti Stati europei, nata per legare economie che si erano combattute."},
		{"voce": "euro", "spiega": "La moneta comune di una parte dei membri dell'Unione. Non tutti l'hanno adottata."},
		{"voce": "confine politico", "spiega": "Una linea decisa dagli uomini fra due Stati. Cambia con la storia."},
		{"voce": "confine fisico", "spiega": "Un limite naturale: una catena, un fiume, una costa. Cambia su tempi geologici."}],
	"esempi": [
		{"prompt": "Come si chiama l'unione economica e politica di molti Stati europei?", "answer": "Unione Europea",
		 "explanation": "Nasce dopo la seconda guerra mondiale per legare fra loro economie che si erano combattute, cominciando da carbone e acciaio."},
		{"prompt": "Tutti gli Stati dell'Unione Europea usano l'euro?", "answer": "No, solo una parte",
		 "explanation": "Alcuni membri hanno mantenuto la propria moneta: l'Unione è un insieme di accordi a cui ciascuno partecipa in misura diversa."}],
	"metodo": "Davanti a una domanda sui confini chiediti se sono politici o fisici. I primi cambiano con la storia e vanno datati, i secondi restano e si possono imparare una volta sola.",
	"errore": {"wrong": "Dire che l'euro è la moneta di tutti gli Stati dell'Unione Europea.",
		"why": "Alcuni membri hanno mantenuto la propria valuta: l'adesione all'Unione e l'adozione della moneta comune sono due scelte separate."},
	"insegna": ["Unione Europea", "euro", "confine politico", "confine fisico"]},

# ==================================================== GEOGRAFIA ITALIA · base
"geografia-geografia-italia-base": {
	"subject": "geografia", "topic": "geografia-italia", "fasce": BANDA_BASE,
	"titolo": "Una penisola lunga, chiusa in alto e percorsa nel mezzo",
	"apertura": "L'Italia si riconosce da lontano sulla carta, e la sua forma spiega quasi tutto il resto: dove scorrono i fiumi, dove stanno le città, perché il nord e il sud non si somigliano.",
	"sezioni": [
		{"titolo": "La forma e le due isole",
		 "testo": "L'Italia è una penisola stretta e lunga protesa al centro del Mar Mediterraneo, unita al resto dell'Europa solo a nord. A chiuderla in alto ci sono le Alpi, la catena più alta d'Europa, che formano un arco da ovest a est; a percorrerla per tutta la lunghezza ci sono gli Appennini, una catena più bassa e più antica che scende da nord a sud come una spina dorsale. Le due isole più grandi sono la Sicilia, oltre lo stretto di Messina, e la Sardegna, in mezzo al Tirreno. Essere lunga e stretta significa che quasi nessun punto del Paese è lontano dal mare, e che il clima cambia parecchio fra un'estremità e l'altra."},
		{"titolo": "Le acque: il fiume più lungo e il lago più grande",
		 "testo": "Il Po è il fiume più lungo d'Italia: nasce in Piemonte, scorre verso est raccogliendo l'acqua sia delle Alpi sia degli Appennini, e sfocia nell'Adriatico con un ampio delta. La pianura che porta il suo nome, la Pianura Padana, è la più estesa del Paese, e non è un caso che sia anche la più popolata e la più coltivata. Il lago più grande è il Lago di Garda, ai piedi delle Alpi, scavato da un antico ghiacciaio come gli altri grandi laghi del nord. I fiumi del centro e del sud sono molto più corti e irregolari, perché gli Appennini sono vicini al mare e l'acqua ha poca strada da fare."},
		{"titolo": "La capitale e i vulcani",
		 "testo": "Roma è la capitale d'Italia e sorge sul fiume Tevere, nel Lazio. L'Italia è anche uno dei pochi Paesi europei con vulcani attivi, tutti concentrati al centro e al sud: l'Etna, in Sicilia, è il più grande vulcano attivo d'Europa e erutta con una certa regolarità; il Vesuvio domina il golfo di Napoli ed è famoso per l'eruzione che seppellì Pompei; lo Stromboli, in una piccola isola delle Eolie, è in attività quasi continua da millenni. La presenza dei vulcani e quella dei terremoti hanno la stessa causa, e in un Paese che sta su una zona di scontro fra placche vanno insieme."}],
	"glossario": [
		{"voce": "Appennini", "spiega": "La catena che percorre l'Italia da nord a sud, più bassa e antica delle Alpi."},
		{"voce": "Po", "spiega": "Il fiume più lungo d'Italia: dal Piemonte all'Adriatico, con la pianura più estesa del Paese."},
		{"voce": "Etna", "spiega": "Il più grande vulcano attivo d'Europa, in Sicilia."},
		{"voce": "Sicilia e Sardegna", "spiega": "Le due isole più grandi d'Italia, nel Mediterraneo."}],
	"esempi": [
		{"prompt": "Qual è il fiume più lungo d'Italia?", "answer": "Po",
		 "explanation": "Raccoglie l'acqua sia delle Alpi sia degli Appennini e attraversa da ovest a est la pianura più estesa del Paese."},
		{"prompt": "Quali sono le due isole più grandi d'Italia?", "answer": "Sicilia e Sardegna",
		 "explanation": "La Sicilia sta oltre lo stretto di Messina, la Sardegna in mezzo al Tirreno: sono le uniche due di dimensioni continentali."}],
	"metodo": "Per collocare qualcosa in Italia parti dalle due catene: se è a nord della pianura sono le Alpi, se corre lungo la penisola sono gli Appennini. Fiumi, laghi e città si dispongono attorno a quelle due.",
	"errore": {"wrong": "Confondere le Alpi con gli Appennini.",
		"why": "Le Alpi chiudono il Paese a nord in un arco e sono le più alte d'Europa; gli Appennini lo percorrono da nord a sud e sono più bassi e antichi."},
	"insegna": ["Sicilia", "Sardegna", "Appennini", "Alpi", "Po", "Etna", "Roma"]},

# ==================================================== GEOGRAFIA ITALIA · alta
"geografia-geografia-italia-alta": {
	"subject": "geografia", "topic": "geografia-italia", "fasce": BANDA_ALTA,
	"titolo": "Perché l'Italia è fatta proprio così",
	"apertura": "Montagne, terremoti, vulcani e la pianura più fertile del Paese hanno tutti la stessa causa, e sono la stessa storia raccontata in punti diversi.",
	"sezioni": [
		{"titolo": "Una terra su una zona di scontro",
		 "testo": "L'Italia sta esattamente dove la placca africana spinge verso nord contro quella euroasiatica. È una spinta lentissima — pochi centimetri l'anno — ma continua da milioni di anni, e tutto quello che segue ne discende. Il terreno compresso fra le due si è corrugato: sono nate le Alpi e, più tardi e in modo più complicato, gli Appennini. Dove la crosta si spezza e scivola avvengono i terremoti, ed è per questo che quasi tutta la penisola è sismica. Dove materiale fuso trova una via d'uscita nascono i vulcani. Non sono tre sfortune separate: sono tre facce della stessa spinta, ed è la ragione per cui in Italia si presentano insieme."},
		{"titolo": "La Pianura Padana è terra costruita dai fiumi",
		 "testo": "Dove oggi c'è la Pianura Padana, alcuni milioni di anni fa c'era un golfo di mare. I fiumi che scendevano dalle Alpi a nord e dagli Appennini a sud portavano con sé enormi quantità di sabbia, ghiaia e limo strappati alle montagne, e li depositavano man mano che rallentavano avvicinandosi al mare. Strato dopo strato, il golfo si è riempito. Questo spiega due cose insieme: perché quella pianura sia così estesa e piatta, e perché sia così fertile — è fatta del materiale migliore di due catene montuose, macinato e rimescolato. La stessa vicenda, in scala minore, si ripete in ogni pianura costiera del Paese."},
		{"titolo": "Perché il nord e il sud non si somigliano",
		 "testo": "L'Italia si estende per più di mille chilometri da nord a sud, e su quella distanza la latitudine cambia abbastanza da cambiare il clima: il nord ha inverni freddi e precipitazioni distribuite, il sud ha estati lunghe e secche e piove quasi solo d'inverno. A questo si somma l'altitudine, che nelle zone alpine e appenniniche crea isole di clima freddo anche al sud — sull'Etna c'è neve. E si somma la distanza dal mare: la Pianura Padana, lontana dalle coste e chiusa dalle montagne, ha sbalzi molto più forti fra estate e inverno di quanto non abbia una città di mare alla stessa latitudine."}],
	"glossario": [
		{"voce": "placca africana", "spiega": "La placca che spinge verso nord contro quella euroasiatica: è la causa delle montagne, dei terremoti e dei vulcani italiani."},
		{"voce": "Pianura Padana", "spiega": "La pianura del Po: un antico golfo di mare riempito dai detriti portati dai fiumi."},
		{"voce": "sismico", "spiega": "Soggetto a terremoti. Quasi tutta la penisola lo è, per la stessa ragione per cui ha le montagne."}],
	"esempi": [
		{"prompt": "Perché in Italia ci sono insieme montagne, terremoti e vulcani?", "answer": "Perché due placche si spingono qui",
		 "explanation": "La placca africana preme contro quella euroasiatica: il terreno si corruga, si spezza e lascia risalire materiale fuso. Una causa, tre effetti."},
		{"prompt": "Come si è formata la Pianura Padana?", "answer": "Riempiendo un golfo con i detriti dei fiumi",
		 "explanation": "I fiumi alpini e appenninici hanno depositato sabbia e limo per milioni di anni: la pianura è fatta del materiale di due catene."}],
	"metodo": "Quando una domanda sull'Italia chiede un «perché», prova a risalire alla spinta fra le due placche: montagne, terremoti, vulcani e perfino la pianura più fertile stanno tutti a valle di quella.",
	"errore": {"wrong": "Trattare terremoti e vulcani italiani come fenomeni indipendenti dalle montagne.",
		"why": "Hanno la stessa causa: la crosta compressa fra due placche si corruga, si spezza e lascia uscire materiale fuso."},
	"insegna": ["placca africana", "Pianura Padana", "sismico"]},

# ===================================================== GEOGRAFIA UMANA · base
"geografia-geografia-umana-base": {
	"subject": "geografia", "topic": "geografia-umana", "fasce": BANDA_BASE,
	"titolo": "Come si legge una carta",
	"apertura": "Una carta geografica non è una fotografia: è un disegno che sceglie che cosa mostrare e in che misura ridurlo. Leggerla è una competenza, non un colpo d'occhio.",
	"sezioni": [
		{"titolo": "Orientarsi: i punti cardinali",
		 "testo": "Il Sole sorge a est e tramonta a ovest, ogni giorno, ovunque: è il riferimento più antico e più affidabile che esista, e basta per orientarsi senza strumenti. Guardando il punto in cui sorge, si ha il nord a sinistra e il sud a destra. Sulle carte geografiche il nord è disegnato in alto quasi sempre, ma è importante sapere che si tratta di una CONVENZIONE e non di una legge di natura: nello spazio non esiste un alto e un basso, ed esistono carte antiche e moderne orientate diversamente. Chi lo dà per scontato si trova in difficoltà davanti a una carta ruotata, che è proprio quello che capita usando una mappa in mano mentre si cammina."},
		{"titolo": "La scala: di quanto è stata ridotta la realtà",
		 "testo": "Una carta geografica è la rappresentazione ridotta della Terra, o di una sua parte, disegnata su un foglio. La scala è il numero che dice di quanto è stata ridotta. Scritta come 1:100.000 significa che un centimetro sulla carta corrisponde a centomila centimetri nella realtà, cioè un chilometro. Più il secondo numero è grande, più la riduzione è forte e più territorio ci sta nel foglio — ma con meno dettaglio. Una carta a grande scala mostra poche vie con i nomi dei negozi; una a piccola scala mostra un continente intero e non può disegnare nemmeno le città piccole. Scegliere la scala significa scegliere che cosa sacrificare."},
		{"titolo": "Carta fisica e carta politica",
		 "testo": "Le due carte più comuni rispondono a domande diverse e vanno scelte in base a quello che si cerca. La carta fisica mostra come è fatto il terreno: montagne, pianure, fiumi, laghi, coste, di solito con i colori che indicano l'altitudine — verde in basso, marrone in alto, bianco sulle cime. La carta politica mostra i confini fra gli Stati, le capitali e le città principali, con colori che servono solo a distinguere un Paese dall'altro. Chiedere dove passa un fiume a una carta politica è una fatica inutile, e così cercare un confine su una carta fisica."}],
	"glossario": [
		{"voce": "carta geografica", "spiega": "La rappresentazione ridotta della Terra o di una sua parte, disegnata su un foglio."},
		{"voce": "scala", "spiega": "Di quanto è stata ridotta la realtà. In 1:100.000 un centimetro sulla carta è un chilometro sul terreno."},
		{"voce": "carta fisica", "spiega": "Mostra il terreno: rilievi, acque, coste, con i colori dell'altitudine."},
		{"voce": "carta politica", "spiega": "Mostra i confini fra gli Stati, le capitali e le città principali."}],
	"esempi": [
		{"prompt": "Da quale punto cardinale sorge il Sole?", "answer": "Est",
		 "explanation": "Ogni giorno e ovunque: guardando il punto in cui sorge si ha il nord a sinistra, ed è il modo più antico di orientarsi senza strumenti."},
		{"prompt": "Su una carta geografica, che cosa indica la scala?", "answer": "Di quanto è stata ridotta la realtà",
		 "explanation": "In 1:100.000 un centimetro sul foglio vale un chilometro sul terreno: più il numero è grande, più territorio ci sta e meno dettaglio resta."}],
	"metodo": "Prima di leggere una carta guarda due cose in un angolo: la scala e la legenda. Dicono quanto è ridotta e che cosa significano i colori, e senza quelle due il resto del foglio si interpreta a caso.",
	"errore": {"wrong": "Cercare i confini fra gli Stati su una carta fisica.",
		"why": "La carta fisica disegna il terreno, non le decisioni umane: i confini stanno sulla carta politica, che è fatta per quella domanda."},
	"insegna": ["est", "ovest", "carta geografica", "scala", "carta fisica", "carta politica"]},

# ===================================================== GEOGRAFIA UMANA · alta
"geografia-geografia-umana-alta": {
	"subject": "geografia", "topic": "geografia-umana", "fasce": BANDA_ALTA,
	"titolo": "Dove vive la gente, e perché proprio lì",
	"apertura": "Gli esseri umani non sono distribuiti a caso sul pianeta, e nemmeno in modo uniforme: si addensano su pochissime fasce, sempre per le stesse ragioni.",
	"sezioni": [
		{"titolo": "La densità, e perché la media inganna",
		 "testo": "La densità di popolazione si calcola dividendo il numero di abitanti per la superficie, e si esprime in abitanti per chilometro quadrato. Un Paese enorme con pochi abitanti ha densità bassa — è il caso della Mongolia o del Canada — mentre uno piccolo e affollato ha densità alta. C'è però una trappola che vale la pena conoscere: la densità è una MEDIA, e una media nasconde i vuoti. Il Canada ha una densità bassissima, eppure quasi tutti i canadesi vivono in una fascia stretta lungo il confine meridionale, dove la densità reale è simile a quella europea. Il resto del Paese è quasi disabitato, e la media mescola le due cose in un numero che non descrive nessuno dei due."},
		{"titolo": "Perché le città nascono su fiumi e coste",
		 "testo": "Guardando dove sono le grandi città del mondo si trova quasi sempre acqua vicina, e le ragioni sono tre e si sommano. L'acqua dolce, che serve a bere, a irrigare e a lavorare. La terra fertile, perché le pianure alluvionali sono fatte del limo che il fiume deposita. E soprattutto il trasporto: muovere merci pesanti sull'acqua è sempre costato molto meno che muoverle via terra, e per gran parte della storia è stato l'unico modo economico di farlo. Una città su un fiume navigabile o su un buon porto sta su un incrocio di scambi, e gli scambi attirano gente, mestieri e denaro."},
		{"titolo": "L'urbanizzazione",
		 "testo": "L'urbanizzazione è lo spostamento della popolazione dalle campagne verso le città, ed è il fenomeno demografico più grande degli ultimi due secoli. Comincia con la rivoluzione industriale, quando le fabbriche concentrano il lavoro in pochi luoghi, e non si è più fermato: da circa il 2007 più della metà dell'umanità vive in centri urbani. Le conseguenze si vedono da entrambi i lati. In città i servizi si concentrano e diventano più efficienti — scuole, ospedali, trasporti — ma crescono congestione, costo delle case e inquinamento. Nelle campagne restano meno persone e più anziane, e alcuni paesi si svuotano al punto da chiudere scuole e negozi."}],
	"glossario": [
		{"voce": "densità di popolazione", "spiega": "Abitanti diviso superficie. È una media, e come ogni media nasconde i vuoti e i pieni."},
		{"voce": "urbanizzazione", "spiega": "Lo spostamento della popolazione verso le città. Dal 2007 più di metà dell'umanità vive in città."},
		{"voce": "pianura alluvionale", "spiega": "Pianura costruita dai depositi di un fiume: è fertile proprio per questo."}],
	"esempi": [
		{"prompt": "Un Paese enorme con pochi abitanti ha densità di popolazione…", "answer": "Bassa",
		 "explanation": "La densità è abitanti diviso superficie: con molta superficie al denominatore e pochi abitanti sopra, il risultato è piccolo."},
		{"prompt": "Perché le città nascono spesso vicino a fiumi o coste?", "answer": "Perché acqua e trasporti facilitano gli scambi",
		 "explanation": "Acqua dolce, terra fertile e soprattutto trasporto economico: muovere merci sull'acqua è sempre costato meno che via terra."}],
	"metodo": "Davanti a un dato di densità chiediti sempre come è distribuita davvero: se il Paese ha zone inabitabili, la media non descrive né quelle né le zone affollate.",
	"errore": {"wrong": "Concludere da una densità bassa che tutto il Paese sia poco abitato.",
		"why": "La densità è una media: in Canada è bassissima, eppure quasi tutti gli abitanti stanno addensati in una fascia lungo il confine sud."},
	"insegna": ["densità di popolazione", "urbanizzazione", "pianura alluvionale"]},

# =========================================================== CAPITALI · base
"geografia-capitali-base": {
	"subject": "geografia", "topic": "capitali", "fasce": BANDA_BASE,
	"titolo": "Che cos'è una capitale, e perché non è sempre la città più grande",
	"apertura": "Le capitali sembrano una cosa da imparare a memoria una per una. In parte lo sono; ma c'è un criterio, e conoscerlo rende molte di loro ricostruibili.",
	"sezioni": [
		{"titolo": "La definizione, ed è più stretta di quanto sembri",
		 "testo": "La capitale di uno Stato è la città in cui hanno sede le istituzioni di governo: il parlamento, i ministeri, il capo dello Stato. Non è «la città più importante» in un senso generico, e non è nemmeno per forza la più famosa all'estero: è dove si prendono le decisioni pubbliche. Qualche esempio europeo: Roma è la capitale dell'Italia, Parigi della Francia, Madrid della Spagna, Berlino della Germania, Lisbona del Portogallo, Londra del Regno Unito. Quando una domanda chiede la capitale di uno Stato, chiede questo e solo questo — non la città con più abitanti, non quella con più monumenti."},
		{"titolo": "Spesso coincide con la città più grande, ma non è una regola",
		 "testo": "In Europa la capitale è quasi sempre anche la città più popolosa del Paese, e questo fa nascere l'abitudine mentale di aspettarselo sempre. È un'abitudine che tradisce appena si esce dal continente. Negli Stati Uniti la capitale è Washington, che non è fra le città più grandi, mentre la più popolosa è New York. Casi come questo non sono rarità: sono molto comuni fuori dall'Europa, e spesso raccontano una decisione precisa, cioè la scelta di non dare il ruolo di capitale a una città già ricca e potente. Vale la pena tenere separate in testa le due domande, «qual è la capitale» e «qual è la città più grande»."},
		{"titolo": "Dove stanno, e perché lì",
		 "testo": "Le capitali antiche quasi mai sono nate al centro geografico del Paese: sono nate dove passava qualcosa — un fiume navigabile, un porto, un guado, un incrocio di strade commerciali — perché chi controlla un passaggio accumula ricchezza e potere, e il potere poi resta dov'è. Roma è nata sul Tevere, in un punto in cui il fiume si poteva guadare; Parigi su un'isola in mezzo alla Senna; Londra sul Tamigi, nel primo punto risalendo dal mare in cui si poteva costruire un ponte. Cercare il fiume o il porto di una capitale antica è quasi sempre il modo più rapido per ricordarsi dove si trova."}],
	"glossario": [
		{"voce": "capitale", "spiega": "La città in cui hanno sede le istituzioni di governo di uno Stato. Non per forza la più popolosa."},
		{"voce": "Roma", "spiega": "Capitale dell'Italia, sul fiume Tevere."},
		{"voce": "Parigi", "spiega": "Capitale della Francia, nata su un'isola in mezzo alla Senna."},
		{"voce": "Londra", "spiega": "Capitale del Regno Unito, sul Tamigi, nel primo punto dal mare in cui si poteva fare un ponte."}],
	"esempi": [
		{"prompt": "Qual è la capitale della Spagna?", "answer": "Madrid",
		 "explanation": "È la sede del governo spagnolo, e in questo caso è anche la città più popolosa del Paese — cosa frequente in Europa e non altrove."},
		{"prompt": "La capitale è sempre la città più grande di un Paese?", "answer": "No, spesso lo è ma non sempre",
		 "explanation": "Negli Stati Uniti la capitale è Washington mentre la città più popolosa è New York: fuori dall'Europa è un caso molto comune."}],
	"metodo": "Per ricordare dove sta una capitale antica, cercane il fiume o il porto. Quasi tutte sono nate su un passaggio, e il passaggio si ricorda meglio di un nome isolato.",
	"errore": {"wrong": "Rispondere con la città più famosa o più popolosa invece che con la sede del governo.",
		"why": "Sono due domande diverse: negli Stati Uniti darebbe New York, mentre la capitale è Washington."},
	"insegna": ["capitale", "Roma", "Parigi", "Madrid", "Berlino", "Lisbona", "Londra"]},

# =========================================================== CAPITALI · alta
"geografia-capitali-alta": {
	"subject": "geografia", "topic": "capitali", "fasce": BANDA_ALTA,
	"titolo": "Le capitali scelte a tavolino",
	"apertura": "Alcune capitali non sono diventate tali: sono state decise, e in qualche caso costruite da zero in un posto dove non c'era niente.",
	"sezioni": [
		{"titolo": "Quando si sceglie per non scegliere",
		 "testo": "Quando in un Paese ci sono due città grandi e rivali, fare capitale una delle due significa dare un vantaggio permanente a metà del Paese. Diversi Stati hanno risolto il problema nello stesso modo: scegliendo un terzo luogo. In Australia Sydney e Melbourne non trovavano un accordo, e nel primo Novecento fu fondata Canberra in mezzo, in una zona allora quasi disabitata. Negli Stati Uniti Washington fu costruita su un terreno ceduto da due Stati, fra il nord e il sud. In Turchia il governo si spostò ad Ankara, all'interno, lasciando la grande Istanbul. In ogni caso la capitale è un compromesso politico prima che una città."},
		{"titolo": "Capitali costruite da zero",
		 "testo": "Il caso più radicale è Brasilia, inaugurata nel 1960. Il Brasile aveva tutte le sue grandi città sulla costa atlantica, e l'immenso interno restava vuoto e povero: la capitale fu progettata e costruita da zero a più di mille chilometri dal mare, proprio per spostare il baricentro del Paese verso l'interno e spingere la gente a popolarlo. È un esperimento di geografia volontaria, e come tutti gli esperimenti ha funzionato solo in parte. Il principio però è chiaro e vale la pena ricordarlo: una capitale può essere uno strumento per cambiare la geografia umana di un Paese, non solo una sua conseguenza."},
		{"titolo": "Quando è invece la geografia a decidere",
		 "testo": "All'estremo opposto ci sono le capitali che stanno dove stanno perché il territorio non lasciava molte alternative. Oslo, la capitale della Norvegia, sta in fondo a un fiordo, cioè in fondo a una lunga insenatura protetta: la Norvegia è un Paese tutto costa e montagne, dove l'interno è poco praticabile e il mare è la via principale, e una città di governo doveva stare su un porto sicuro. Guardare la forma di un Paese prima di guardare l'elenco delle sue città spiega spesso la scelta: dove c'è una sola pianura, una sola valle o un solo porto riparato, la capitale è quasi sempre lì."}],
	"glossario": [
		{"voce": "Canberra", "spiega": "Capitale dell'Australia, fondata in mezzo perché Sydney e Melbourne non si accordavano."},
		{"voce": "Brasilia", "spiega": "Capitale del Brasile, costruita da zero e inaugurata nel 1960 per spostare il Paese verso l'interno."},
		{"voce": "Washington", "spiega": "Capitale degli Stati Uniti, costruita su terreno ceduto fra nord e sud. La città più popolosa è New York."},
		{"voce": "Oslo", "spiega": "Capitale della Norvegia, in fondo a un fiordo: in un Paese tutto costa, il porto riparato decide."}],
	"esempi": [
		{"prompt": "Perché la capitale dell'Australia è Canberra e non Sydney?", "answer": "Perché Sydney e Melbourne non si accordavano",
		 "explanation": "Fare capitale una delle due avrebbe dato un vantaggio permanente a metà del Paese: si scelse un terzo luogo in mezzo."},
		{"prompt": "Perché il Brasile costruì Brasilia lontano dalla costa?", "answer": "Per spostare il Paese verso l'interno",
		 "explanation": "Tutte le grandi città stavano sull'Atlantico e l'interno era vuoto: la capitale fu usata come strumento per popolarlo."}],
	"metodo": "Davanti a una capitale che non ti aspetti, fatti due domande: c'erano due città rivali da non scegliere, oppure il territorio lasciava un solo posto possibile? Quasi tutte le sorprese rientrano in uno dei due casi.",
	"errore": {"wrong": "Applicare fuori dall'Europa la regola «la capitale è la città più grande».",
		"why": "Fuori dall'Europa è spesso falsa proprio per scelta: molte capitali sono state messe altrove per non favorire una città già ricca."},
	"insegna": ["Canberra", "Brasilia", "Washington", "Ankara", "Oslo"]},

# ==============================================================================
# LATINO — la quarta materia convertita (11 settembre 2026)
#
# Il latino ha un difetto suo, già misurato il 2 settembre: non la domanda di
# NOME ma la domanda di **FORMA**. «Da *rosa*, quale forma useresti per dire
# *della rosa*?» non si deduce da niente — o si è vista la tabella, o si tira a
# indovinare. Per questo esistono le tavole `paradigma`, e per questo il latino
# entra fra le materie di richiamo di `dispense_audit`.
#
# **Ventidue dispense e non trenta.** I sette argomenti di declinazione hanno una
# dispensa sola che copre tutte e otto le fasce (`BANDA_INTERA`): le caselle di un
# paradigma sono una tabella, e una tabella non si divide in «prime quattro» e
# «ultime quattro» senza ripetersi. Gli argomenti concettuali — i casi, i verbi,
# le frasi, l'etimologia — si dividono invece in due bande, perché lì c'è davvero
# un prima e un dopo.
#
# Le `regole` fanno qui il lavoro che nelle altre materie fanno poco: la risposta
# a una domanda di forma è una parola costruita, e le parole costruibili sono
# centinaia. Una riga di espressione regolare copre un intero gruppo di radici —
# è la stessa scelta che `TAVOLE_LATINO` aveva già fatto, e le espressioni sono
# scritte sulle stesse radici.

# =============================================================== BASI · base
"latino-basi-base": {
	"subject": "latino", "topic": "basi", "fasce": BANDA_BASE,
	"titolo": "Una lingua in cui è la coda della parola a dire tutto",
	"apertura": "La prima cosa da capire del latino non è una parola: è che funziona in un modo diverso dall'italiano, e il modo si può spiegare in tre righe.",
	"sezioni": [
		{"titolo": "In italiano conta il posto, in latino conta la desinenza",
		 "testo": "In italiano «il cane morde l'uomo» e «l'uomo morde il cane» sono fatte delle stesse parole e dicono due cose opposte: a decidere chi morde è la POSIZIONE. Il latino fa il contrario. Lì la funzione di ogni parola sta scritta nella sua parte finale, che si chiama desinenza, e cambia a seconda del mestiere che la parola sta facendo nella frase. Ne segue una conseguenza che all'inizio sorprende: l'ordine delle parole può cambiare senza che il senso cambi, perché l'informazione non sta nell'ordine. Una lingua costruita così si chiama lingua flessiva, cioè una lingua in cui le parole cambiano desinenza invece di appoggiarsi al posto che occupano."},
		{"titolo": "Sei casi, cinque declinazioni",
		 "testo": "Le forme che una parola può prendere si chiamano CASI, e in latino sono sei: nominativo, genitivo, dativo, accusativo, vocativo e ablativo. Ogni caso corrisponde a un mestiere — fare l'azione, subirla, indicare di chi è una cosa, e così via. I sostantivi latini però non prendono tutti le stesse desinenze: si dividono in cinque gruppi, che si chiamano DECLINAZIONI. Sapere a quale gruppo appartiene una parola è la condizione per sapere che cosa diventa: la stessa funzione si scrive con code diverse a seconda della declinazione, esattamente come in italiano i verbi si dividono in tre coniugazioni."},
		{"titolo": "Perché vale la pena",
		 "testo": "Il latino è la lingua in cui è scritta la maggior parte delle iscrizioni romane, e per un millennio è stato l'unico modo di scrivere in Europa. Ma la ragione più immediata è un'altra e riguarda l'italiano: la stragrande maggioranza delle parole che usiamo ogni giorno viene da lì, e spesso conoscere la parola latina spiega insieme dieci parole italiane. Da *aqua* vengono acqua, acquedotto, acquario e acquerello; da *terra* terrestre, sotterraneo, interrare. Studiare latino non è solo studiare una lingua morta: è capire da dentro come è fatta quella che si parla."}],
	"glossario": [
		{"voce": "caso", "spiega": "La forma che indica la funzione di un nome nella frase. In latino sono sei."},
		{"voce": "declinazione", "spiega": "Il gruppo a cui un sostantivo appartiene. Sono cinque, e decidono quali desinenze prende."},
		{"voce": "desinenza", "spiega": "La parte finale della parola, quella che cambia e che porta l'informazione. In latino è la desinenza a dire il mestiere di una parola, non la sua posizione."},
		{"voce": "lingua flessiva", "spiega": "Una lingua in cui le parole cambiano desinenza invece di affidarsi all'ordine."}],
	"esempi": [
		{"prompt": "Che cos'è un caso in latino?", "answer": "La forma che indica la funzione di un nome",
		 "explanation": "Non è una categoria astratta: è proprio la forma scritta, cioè quale coda la parola porta in quella frase."},
		{"prompt": "Quante declinazioni ha il latino?", "answer": "5",
		 "explanation": "Cinque gruppi di sostantivi, ciascuno con le proprie desinenze: la stessa funzione si scrive in modo diverso a seconda del gruppo."}],
	"metodo": "Davanti a una parola latina non chiederti prima che cosa significa, ma che mestiere sta facendo. La coda lo dice, e il significato da solo non basterebbe a capire la frase.",
	"errore": {"wrong": "Leggere una frase latina nell'ordine italiano, dando il ruolo di soggetto alla prima parola.",
		"why": "In latino il soggetto è quello che porta la desinenza del nominativo, e può stare in qualunque punto della frase."},
	"insegna": ["caso", "declinazione", "desinenza", "lingua flessiva"]},

# =============================================================== CASI · base
"latino-casi-base": {
	"subject": "latino", "topic": "casi", "fasce": BANDA_BASE,
	"titolo": "Chi fa, chi subisce, di chi è, a chi",
	"apertura": "Quattro dei sei casi bastano a leggere quasi tutte le frasi semplici. Si imparano a coppie, chiedendosi ogni volta la stessa domanda.",
	"sezioni": [
		{"titolo": "Nominativo e accusativo: chi fa e chi subisce",
		 "testo": "Il nominativo è il caso del SOGGETTO, cioè di chi compie l'azione. L'accusativo è il caso del complemento oggetto, cioè di chi la subisce. Nella frase «Dominus servum vocat», che significa «Il padrone chiama lo schiavo», è *dominus* a chiamare ed è *servum* a essere chiamato — e lo si capisce dalla coda -um, non dal posto in cui le due parole stanno. La prova è che invertendole, «Servum dominus vocat», la frase significa esattamente la stessa cosa. Nella seconda declinazione l'accusativo singolare finisce in -um, nella prima in -am, nella terza in -em: tre code diverse per lo stesso mestiere."},
		{"titolo": "Genitivo e dativo: di chi è, e a chi",
		 "testo": "Il genitivo risponde alla domanda «di chi?» ed è quello che in italiano si traduce quasi sempre con «di»: *rosae* vuol dire «della rosa», *domini* «del padrone». È anche il caso che si usa per citare una parola nel vocabolario, perché è quello che rivela la declinazione. Il dativo risponde a «a chi?» o «per chi?», cioè indica il destinatario: *rosae* vuol dire anche «alla rosa», *domino* «al padrone». Nella prima declinazione genitivo e dativo singolare hanno la STESSA forma, -ae, ed è la prima delle ambiguità che si incontrano: a distinguerle non è la parola ma la frase che le sta intorno."},
		{"titolo": "Come si legge, in pratica",
		 "testo": "Il metodo è sempre lo stesso e conviene applicarlo alla lettera finché non diventa automatico. Primo: cerca il verbo, che in latino sta spesso in fondo alla frase. Secondo: chiediti «chi compie questa azione?» e cerca la parola al nominativo. Terzo: chiediti «su che cosa ricade?» e cerca l'accusativo. Quello che resta si assegna dopo. Guardare le code prima del significato è l'abitudine che fa la differenza: chi traduce a orecchio, andando a intuito sulle parole che riconosce, prima o poi scambia chi fa con chi subisce, ed è l'errore che cambia la frase nel suo contrario."}],
	"glossario": [
		{"voce": "nominativo", "spiega": "Il caso del soggetto: chi compie l'azione."},
		{"voce": "accusativo", "spiega": "Il caso del complemento oggetto: chi subisce l'azione. Singolare in -am, -um, -em secondo la declinazione."},
		{"voce": "genitivo", "spiega": "Risponde a «di chi?». È anche la forma con cui si cita una parola, perché rivela la declinazione."},
		{"voce": "dativo", "spiega": "Risponde a «a chi, per chi?»: indica il destinatario."}],
	"esempi": [
		{"prompt": "«Dominus servum vocat.» vuol dire «Il padrone chiama lo schiavo.». Quale parola indica chi SUBISCE l'azione?", "answer": "servum",
		 "explanation": "La coda -um è quella dell'accusativo nella seconda declinazione: dice che quella parola subisce, indipendentemente da dove si trovi nella frase."},
		{"prompt": "Da «rosa», quale forma useresti per dire «della rosa»?", "answer": "rosae",
		 "explanation": "È il genitivo singolare della prima declinazione. La stessa forma vale anche come dativo: a distinguerli è la frase, non la parola."}],
	"metodo": "Cerca prima il verbo, poi chiedi «chi?» per trovare il nominativo e «che cosa?» per l'accusativo. Il resto si assegna dopo, e non prima.",
	"errore": {"wrong": "Prendere per soggetto la prima parola della frase latina.",
		"why": "L'ordine in latino è libero: il soggetto è quello che porta la desinenza del nominativo, e può trovarsi anche in fondo."},
	# Il documento non elenca le forme una per una — sarebbero centinaia — ma insegna
	# a costruirle: dice quale desinenza porta ogni caso nelle tre declinazioni che
	# nomina. Le regole dichiarano esattamente quell'insieme.
	"regole": ["^(ros|puell|aqu|terr|patri|silv)(a|ae|am)$",
		"^(domin|serv|amic|puer|libr|magistr)(us|i|o|um)$",
		"^(reg|consul|milit|leg)(is|i|em)$"],
	"insegna": ["nominativo", "accusativo", "genitivo", "dativo"]},

# =============================================================== CASI · alta
"latino-casi-alta": {
	"subject": "latino", "topic": "casi", "fasce": BANDA_ALTA,
	"titolo": "Gli altri due casi, e le code che vogliono dire più cose",
	"apertura": "Restano l'ablativo e il vocativo. Poi c'è il problema vero del latino, che non è ricordare le tabelle ma decidere fra due caselle che si scrivono uguale.",
	"sezioni": [
		{"titolo": "L'ablativo: con che cosa, da dove, in che modo",
		 "testo": "L'ablativo è il più versatile dei sei casi e copre da solo diversi complementi che l'italiano distingue con preposizioni diverse. Risponde a «con che cosa?» — *gladio*, con la spada — a «da dove?», a «in che modo?», a «quando?». Spesso in latino l'ablativo va da solo, senza nessuna preposizione davanti, e va tradotto aggiungendola in italiano: è una delle differenze che rendono la traduzione un lavoro e non una sostituzione parola per parola. Il vocativo invece è il caso di chi viene chiamato, e nella maggior parte dei casi ha la stessa forma del nominativo: fa eccezione la seconda declinazione, dove *dominus* diventa *domine*."},
		{"titolo": "Una forma, tre funzioni",
		 "testo": "Ecco il punto che fa sbagliare più di ogni tabella dimenticata. Nella prima declinazione la forma *rosae* è contemporaneamente genitivo singolare («della rosa»), dativo singolare («alla rosa») e nominativo plurale («le rose»). Tre mestieri, una sola scrittura. Non è un difetto della lingua e non si risolve imparando meglio: si risolve LEGGENDO LA FRASE. Se il verbo è al plurale, *rosae* è quasi certamente il soggetto; se accanto c'è un altro sostantivo di cui la rosa può essere proprietà, è genitivo; se il verbo è di dare o dire, è dativo. Il latino chiede di decidere con il contesto, e questa è la competenza vera."},
		{"titolo": "La procedura completa",
		 "testo": "Su una frase che non si capisce al primo colpo conviene procedere sempre nello stesso ordine, e scriverlo. Uno: individua il verbo e guarda se è singolare o plurale. Due: cerca fra i sostantivi quello che può essere nominativo e che concorda con quel numero — se il verbo è plurale, il soggetto deve essere plurale. Tre: assegna l'accusativo. Quattro: solo alla fine decidi che cosa sono le forme ambigue rimaste, usando il senso che si è formato. Chi decide le ambiguità per prime sbaglia, perché le decide senza informazioni."}],
	"glossario": [
		{"voce": "ablativo", "spiega": "Copre «con, da, in, quando»: spesso va senza preposizione, e la preposizione la aggiunge l'italiano."},
		{"voce": "vocativo", "spiega": "Il caso di chi viene chiamato. Quasi sempre uguale al nominativo, tranne nella seconda declinazione."},
		{"voce": "forma ambigua", "spiega": "Una desinenza che vale per più caselle: *rosae* è genitivo e dativo singolare, e nominativo plurale."},
		{"voce": "concordanza", "spiega": "Il soggetto deve avere lo stesso numero del verbo. È l'indizio che scioglie quasi tutte le ambiguità."}],
	"esempi": [
		{"prompt": "«Rosae pulchrae sunt.» Che funzione ha «rosae»?", "answer": "nominativo plurale",
		 "explanation": "Il verbo *sunt* è plurale, quindi il soggetto deve essere plurale: fra le tre funzioni possibili di *rosae* resta solo quella."},
		{"prompt": "Quanti casi ha il latino in tutto?", "answer": "6",
		 "explanation": "Nominativo, genitivo, dativo, accusativo, vocativo e ablativo: gli ultimi due sono quelli che si incontrano più tardi."}],
	"metodo": "Non decidere mai una forma ambigua per prima. Trova il verbo, guarda se è singolare o plurale, e usa quella informazione per scegliere: quasi tutte le ambiguità si sciolgono così.",
	"errore": {"wrong": "Tradurre *rosae* come genitivo perché è la prima funzione imparata.",
		"why": "La stessa forma vale anche come dativo singolare e come nominativo plurale: senza guardare il verbo e il resto della frase la scelta è un tiro a caso."},
	"insegna": ["ablativo", "vocativo", "forma ambigua", "concordanza"]},

# =================================================== DECLINAZIONI BASE · base
"latino-declinazioni-base-base": {
	"subject": "latino", "topic": "declinazioni-base", "fasce": BANDA_BASE,
	"titolo": "Come si capisce a quale gruppo appartiene una parola",
	"apertura": "Ogni sostantivo latino si cita con due forme, e la seconda non è un capriccio: è l'unica che dice a quale declinazione appartiene.",
	"sezioni": [
		{"titolo": "Due forme, e conta la seconda",
		 "testo": "Nei vocabolari e negli elenchi un sostantivo latino compare sempre così: *rosa, rosae*; *dominus, domini*; *rex, regis*. La prima forma è il nominativo singolare, la seconda il GENITIVO singolare, ed è quest'ultima a portare l'informazione che serve. Il motivo è semplice: nominativi diversi possono somigliarsi fra gruppi diversi, mentre la coda del genitivo singolare è caratteristica di una sola declinazione. Imparare una parola latina significa quindi imparare due forme, non una — e chi ne impara una sola si trova poi a non poter costruire nessuna delle altre caselle."},
		{"titolo": "Le cinque code del genitivo",
		 "testo": "Ecco la tabella che decide tutto, e sono cinque righe. Genitivo in **-ae**: prima declinazione, come *rosa, rosae*. Genitivo in **-i**: seconda, come *dominus, domini*. Genitivo in **-is**: terza, come *rex, regis*. Genitivo in **-us**: quarta, come *manus, manus*. Genitivo in **-ei**: quinta, come *dies, diei*. Una volta riconosciuto il gruppo, tutte le altre caselle si costruiscono con le desinenze di quel gruppo: è per questo che l'identificazione viene prima di qualunque traduzione, e non dopo."},
		{"titolo": "Il tema, cioè la parte che non cambia",
		 "testo": "Per costruire una forma non si parte dal nominativo ma dal TEMA, che è la parte di parola che resta uguale in tutte le caselle. Lo si ricava togliendo la desinenza dal genitivo singolare: da *rosae* si toglie -ae e resta ros-; da *domini* si toglie -i e resta domin-; da *regis* si toglie -is e resta reg-. Da lì in poi si aggiunge la desinenza della casella che serve. È il motivo per cui la terza declinazione sembra difficile e poi non lo è: *rex* al nominativo non somiglia a *regis*, ma dal genitivo in avanti il tema reg- non cambia più."}],
	"glossario": [
		{"voce": "genitivo singolare", "spiega": "La seconda forma con cui si cita una parola. È quella che dice a quale declinazione appartiene."},
		{"voce": "tema", "spiega": "La parte che non cambia. Si ottiene togliendo la desinenza dal genitivo singolare."},
		{"voce": "rosa, rosae", "spiega": "Prima declinazione: il genitivo in -ae la identifica."},
		{"voce": "dominus, domini", "spiega": "Seconda declinazione: il genitivo in -i la identifica."}],
	"esempi": [
		{"prompt": "A quale declinazione appartiene «rosa, rosae»?", "answer": "Prima",
		 "explanation": "Il genitivo singolare finisce in -ae, e quella coda appartiene solo alla prima declinazione."},
		{"prompt": "A quale declinazione appartiene «dominus, domini»?", "answer": "Seconda",
		 "explanation": "Il genitivo singolare finisce in -i: è la firma della seconda declinazione, quella dei maschili in -us."}],
	"metodo": "Guarda sempre la SECONDA forma, non la prima. Il nominativo può ingannare, il genitivo singolare no: la sua coda appartiene a un gruppo solo.",
	"errore": {"wrong": "Decidere la declinazione guardando il nominativo singolare.",
		"why": "Nominativi simili appartengono a gruppi diversi: *manus* e *dominus* finiscono entrambi in -us e sono di due declinazioni differenti."},
	"insegna": ["genitivo singolare", "tema", "rosa, rosae", "dominus, domini", "rex, regis"]},

# =================================================== DECLINAZIONI BASE · alta
"latino-declinazioni-base-alta": {
	"subject": "latino", "topic": "declinazioni-base", "fasce": BANDA_ALTA,
	"titolo": "Costruire una forma qualsiasi, e riconoscere quelle che si ripetono",
	"apertura": "Sapere il gruppo serve a una cosa sola: poter costruire da soli la casella che serve, invece di sperare di averla già vista.",
	"sezioni": [
		{"titolo": "Il procedimento in tre mosse",
		 "testo": "Data una parola e una funzione da esprimere, il procedimento è sempre lo stesso. Uno: dal genitivo singolare ricava il tema, togliendogli la desinenza. Due: riconosci la declinazione dalla coda di quel genitivo. Tre: attacca al tema la desinenza della casella che ti serve in quella declinazione. Con *rosa, rosae* il tema è ros-, la declinazione è la prima, e l'accusativo singolare della prima è -am: quindi *rosam*. Con *dominus, domini* il tema è domin-, la declinazione è la seconda, e l'accusativo singolare è -um: quindi *dominum*. Non è memoria: è una procedura, e funziona anche su una parola mai vista prima."},
		{"titolo": "Il plurale della prima declinazione",
		 "testo": "Le caselle del plurale della prima declinazione sono cinque forme e vale la pena averle tutte davanti insieme. Nominativo plurale *rosae*, «le rose». Genitivo plurale *rosarum*, «delle rose». Dativo plurale *rosis*, «alle rose». Accusativo plurale *rosas*, «le rose» come complemento oggetto. Ablativo plurale *rosis*, uguale al dativo. Due osservazioni utili: il genitivo plurale in -arum è inconfondibile e non si presta ad ambiguità, e dativo e ablativo plurale hanno sempre la stessa forma — vale in tutte e cinque le declinazioni, non solo qui."},
		{"titolo": "Le forme che si ripetono, e come conviverci",
		 "testo": "Dentro un paradigma alcune caselle coincidono, e conviene conoscerle invece di scoprirle sbagliando. Nella prima declinazione *rosae* vale per genitivo singolare, dativo singolare e nominativo plurale; *rosa* vale per nominativo e ablativo singolare; *rosis* per dativo e ablativo plurale. Sono sovrapposizioni previste, non errori del sistema, e si sciolgono sempre allo stesso modo: guardando il numero del verbo e il ruolo che resta libero nella frase. Chi impara a memoria le sovrapposizioni insieme al paradigma legge molto più in fretta di chi le incontra una per volta."}],
	"glossario": [
		{"voce": "rosarum", "spiega": "Genitivo plurale della prima declinazione: «delle rose». La coda -arum è inconfondibile."},
		{"voce": "rosas", "spiega": "Accusativo plurale della prima declinazione: le rose che subiscono l'azione."},
		{"voce": "rosis", "spiega": "Dativo e ablativo plurale insieme: in tutte le declinazioni queste due caselle coincidono."},
		{"voce": "procedimento", "spiega": "Tema dal genitivo, declinazione dalla sua coda, desinenza della casella. Funziona su parole mai viste."}],
	"esempi": [
		{"prompt": "Qual è il nominativo plurale di «rosa»?", "answer": "rosae",
		 "explanation": "La stessa forma vale anche come genitivo e dativo singolare: qui a decidere è che serve il soggetto di un verbo plurale."},
		{"prompt": "Qual è l'accusativo plurale di «rosa»?", "answer": "rosas",
		 "explanation": "Tema ros- più la desinenza -as dell'accusativo plurale della prima declinazione: una forma che non si confonde con nessun'altra."}],
	"metodo": "Non cercare la forma nella memoria: costruiscila. Tema, declinazione, desinenza della casella — tre mosse che funzionano anche su una parola che non hai mai visto.",
	"errore": {"wrong": "Formare il plurale aggiungendo una -s come in italiano o in inglese.",
		"why": "Il plurale latino dipende dalla casella e dalla declinazione: il nominativo plurale della prima è *rosae*, e la -s compare solo nell'accusativo."},
	"regole": ["^(ros|puell|aqu|terr|patri|silv|stell|don)(a|ae|am|as|arum|is)$",
		"^(domin|serv|amic|puer|libr|magistr|templ|bell)(us|i|o|um|e|os|orum|is|a|orum)$"],
	"insegna": ["rosarum", "rosas", "rosis", "tema", "desinenza"]},

# ====================================================== DECLINAZIONE 1 · tutta
"latino-declinazione-1": {
	"subject": "latino", "topic": "declinazione-1", "fasce": BANDA_INTERA,
	"titolo": "La prima declinazione: rosa, rosae",
	"apertura": "È la più regolare delle cinque e la prima che si impara. Undici forme in tutto, e tre di loro si scrivono uguali: conviene saperlo subito.",
	"sezioni": [
		{"titolo": "La tabella intera",
		 "testo": "Il modello è *rosa, rosae*, «la rosa». Al singolare: nominativo *rosa*, genitivo *rosae*, dativo *rosae*, accusativo *rosam*, vocativo *rosa*, ablativo *rosa*. Al plurale: nominativo *rosae*, genitivo *rosarum*, dativo *rosis*, accusativo *rosas*, ablativo *rosis*. Il tema è ros-, e tutte le forme si ottengono attaccandogli la desinenza della casella. Appartengono a questo gruppo quasi tutti i sostantivi femminili che al nominativo finiscono in -a: *puella* la fanciulla, *aqua* l'acqua, *terra* la terra, *patria* la patria, *silva* la selva, *stella* la stella. Riconosciuto il gruppo, tutte funzionano allo stesso modo."},
		{"titolo": "Le tre coincidenze, e come si sciolgono",
		 "testo": "Dentro questo paradigma tre forme fanno doppio servizio, ed è bene conoscerle prima di incontrarle. *Rosae* vale come genitivo singolare («della rosa»), dativo singolare («alla rosa») e nominativo plurale («le rose»). *Rosa* vale come nominativo e come ablativo singolare. *Rosis* vale come dativo e come ablativo plurale. Nessuna di queste ambiguità si risolve guardando la parola: si risolvono guardando la frase, e in particolare il numero del verbo. Se il verbo è plurale, *rosae* è il soggetto; se c'è un sostantivo di cui la rosa può essere proprietà, è genitivo; se il verbo è di dare, offrire o dire, è dativo."},
		{"titolo": "Come si usa in una frase",
		 "testo": "«Puella rosam amat» significa «La fanciulla ama la rosa»: *puella* porta la desinenza del nominativo e quindi è il soggetto, *rosam* porta quella dell'accusativo e quindi subisce. Cambiando l'ordine in «Rosam puella amat» il significato non cambia di una virgola, perché l'informazione sta nelle code. Se invece si scambiassero le desinenze — «Puellam rosa amat» — la frase direbbe che è la rosa ad amare la fanciulla. È l'esempio più breve che si possa fare di che cosa significhi davvero una lingua flessiva, e vale la pena tenerlo a mente come prova del nove."}],
	"glossario": [
		{"voce": "rosa", "spiega": "Nominativo e ablativo singolare. La forma di citazione della prima declinazione."},
		{"voce": "rosae", "spiega": "Genitivo e dativo singolare, e nominativo plurale: tre funzioni per una sola scrittura."},
		{"voce": "rosam", "spiega": "Accusativo singolare: la rosa che subisce l'azione."},
		{"voce": "rosarum", "spiega": "Genitivo plurale, «delle rose». L'unica coda -arum del paradigma, inconfondibile."}],
	"esempi": [
		{"prompt": "Da «puella» (la fanciulla): quale forma useresti per dire «alla fanciulla»?", "answer": "puellae",
		 "explanation": "È il dativo singolare, che nella prima declinazione ha la stessa forma del genitivo: tema puell- più la desinenza -ae."},
		{"prompt": "Da «aqua» (l'acqua): quale forma useresti se è l'acqua a SUBIRE l'azione?", "answer": "aquam",
		 "explanation": "Chi subisce va all'accusativo, e l'accusativo singolare della prima declinazione è -am: tema aqu- più -am."}],
	"metodo": "Ricava il tema togliendo la -a al nominativo, poi attacca la desinenza della casella. Su ogni parola di questo gruppo funziona identico, anche su una mai vista.",
	"errore": {"wrong": "Tradurre sempre *rosae* con «della rosa».",
		"why": "La stessa forma è anche dativo singolare e nominativo plurale: senza guardare il verbo e il resto della frase si sceglie a caso fra tre."},
	"regole": ["^(ros|puell|aqu|terr|patri|silv|stell|don|femin|insul|via|vit)(a|ae|am|as|arum|is)$"],
	"insegna": ["rosa", "rosae", "rosam", "rosas", "rosarum", "rosis"]},

# ===================================================== DECLINAZIONE 2M · tutta
"latino-declinazione-2m": {
	"subject": "latino", "topic": "declinazione-2m", "fasce": BANDA_INTERA,
	"titolo": "La seconda declinazione maschile: dominus, domini",
	"apertura": "Il gruppo dei maschili in -us. È regolare quanto la prima, e porta l'unico vocativo davvero diverso dal nominativo di tutto il latino.",
	"sezioni": [
		{"titolo": "La tabella intera",
		 "testo": "Il modello è *dominus, domini*, «il signore, il padrone». Al singolare: nominativo *dominus*, genitivo *domini*, dativo *domino*, accusativo *dominum*, vocativo *domine*, ablativo *domino*. Al plurale: nominativo *domini*, genitivo *dominorum*, dativo *dominis*, accusativo *dominos*, ablativo *dominis*. Il tema è domin-. Appartengono a questo gruppo moltissimi maschili di uso comune: *servus* lo schiavo, *amicus* l'amico, *puer* il ragazzo, *liber* il libro, *magister* il maestro. Le ultime tre finiscono in -er invece che in -us al solo nominativo, e dal genitivo in avanti si comportano come tutte le altre."},
		{"titolo": "Il vocativo in -e, e perché è l'unica eccezione",
		 "testo": "In tutte le declinazioni il vocativo — il caso di chi viene chiamato — ha la stessa forma del nominativo, e non dà mai problemi. Qui no: il vocativo singolare di *dominus* è *domine*. È l'unico punto di tutto il sistema in cui quei due casi si separano, ed è il motivo per cui la frase più citata del latino scolastico, «Et tu, Brute?», ha quella forma: il nominativo sarebbe *Brutus*, ma Cesare sta chiamando qualcuno, e chi viene chiamato va al vocativo. Vale la pena impararlo come eccezione isolata, perché è esattamente questo: una sola casella in un solo gruppo."},
		{"titolo": "Le coincidenze di questo gruppo",
		 "testo": "Anche qui alcune caselle si scrivono uguali. *Domini* vale come genitivo singolare («del padrone») e come nominativo plurale («i padroni»): è la coppia che confonde di più, e si scioglie guardando il numero del verbo. *Domino* vale come dativo e come ablativo singolare; *dominis* come dativo e ablativo plurale, esattamente come accade nella prima declinazione. L'accusativo invece non si confonde mai: -um al singolare e -os al plurale sono code che nessun'altra casella di questo paradigma usa, ed è per questo che chi subisce l'azione è sempre la parola più facile da individuare."}],
	"glossario": [
		{"voce": "dominus", "spiega": "Nominativo singolare, la forma di citazione dei maschili della seconda."},
		{"voce": "domini", "spiega": "Genitivo singolare e nominativo plurale: una forma, due funzioni."},
		{"voce": "dominum", "spiega": "Accusativo singolare: chi subisce l'azione. La coda -um non si confonde con nessun'altra casella."},
		{"voce": "domine", "spiega": "Vocativo singolare: l'unico caso in tutto il latino in cui il vocativo differisce dal nominativo."}],
	"esempi": [
		{"prompt": "Da «servus» (lo schiavo): quale forma useresti per dire «allo schiavo»?", "answer": "servo",
		 "explanation": "È il dativo singolare: tema serv- più la desinenza -o. La stessa forma vale anche come ablativo."},
		{"prompt": "Da «amicus» (l'amico): quale forma useresti se è l'amico a SUBIRE l'azione?", "answer": "amicum",
		 "explanation": "Chi subisce va all'accusativo, e l'accusativo singolare di questo gruppo è -um: tema amic- più -um."}],
	"metodo": "Togli la -us del nominativo per avere il tema, poi attacca la desinenza. Se la parola finisce in -er guarda il genitivo: da lì in poi si comporta come tutte le altre.",
	"errore": {"wrong": "Usare *dominus* per chiamare qualcuno.",
		"why": "Per chiamare serve il vocativo, che qui è *domine*: è l'unico gruppo in cui vocativo e nominativo non coincidono."},
	"regole": ["^(domin|serv|amic|puer|libr|magistr|popul|ann|mur|equ|filii?|deus?)(us|i|o|um|e|os|orum|is|er)$"],
	"insegna": ["dominus", "domini", "domino", "dominum", "domine", "dominos", "dominorum"]},

# ===================================================== DECLINAZIONE 2N · tutta
"latino-declinazione-2n": {
	"subject": "latino", "topic": "declinazione-2n", "fasce": BANDA_INTERA,
	"titolo": "La seconda declinazione neutra: templum, templi",
	"apertura": "Stesso gruppo dei maschili, stesso genitivo in -i, ma con una regola in più che vale per TUTTI i neutri latini e va imparata una volta sola.",
	"sezioni": [
		{"titolo": "La regola dei neutri, valida in ogni declinazione",
		 "testo": "Prima ancora della tabella conviene imparare la regola generale, perché vale per i neutri di tutte e cinque le declinazioni e risparmia metà del lavoro. Primo: nei neutri il nominativo e l'accusativo hanno SEMPRE la stessa forma, sia al singolare sia al plurale. Secondo: il nominativo e l'accusativo plurale dei neutri finiscono SEMPRE in -a. Queste due regole insieme hanno una conseguenza pratica importante: in una frase con un neutro non si può stabilire dalla forma se sia soggetto od oggetto, e bisogna guardare il resto della frase — di solito l'altro sostantivo presente, o il senso del verbo."},
		{"titolo": "La tabella intera",
		 "testo": "Il modello è *templum, templi*, «il tempio». Al singolare: nominativo *templum*, genitivo *templi*, dativo *templo*, accusativo *templum*, vocativo *templum*, ablativo *templo*. Al plurale: nominativo *templa*, genitivo *templorum*, dativo *templis*, accusativo *templa*, ablativo *templis*. Il tema è templ-, e come si vede le uniche differenze rispetto ai maschili stanno nelle tre caselle toccate dalla regola dei neutri: -um invece di -us al nominativo singolare, e -a invece di -i e -os ai due plurali. Tutto il resto è identico a *dominus*. Appartengono a questo gruppo *bellum* la guerra, *donum* il dono, *verbum* la parola, *oppidum* la città fortificata."},
		{"titolo": "Perché *templa* non è un femminile",
		 "testo": "È l'errore più frequente e nasce da un'abitudine italiana: una parola che finisce in -a sembra femminile singolare. In latino *templa* è invece un neutro PLURALE, «i templi», e la -a finale è la desinenza dei neutri plurali. Lo stesso vale per *bella*, che non significa «bella» ma «le guerre», e per *dona*, «i doni». Il modo per non cadere nella trappola è controllare il verbo: se è al plurale, quella -a è un plurale neutro. E chi impara la parola con il suo genitivo — *templum, templi* — la trappola non la incontra nemmeno."}],
	"glossario": [
		{"voce": "neutro", "spiega": "Genere in cui nominativo e accusativo hanno sempre la stessa forma, e il loro plurale finisce in -a."},
		{"voce": "templum", "spiega": "Nominativo, accusativo e vocativo singolare: nei neutri queste tre caselle coincidono."},
		{"voce": "templa", "spiega": "Nominativo e accusativo plurale. La -a finale è la firma dei neutri plurali, non un femminile."},
		{"voce": "templorum", "spiega": "Genitivo plurale, «dei templi»: identico nella forma a quello dei maschili."}],
	"esempi": [
		{"prompt": "Da «templum» (il tempio): qual è il nominativo plurale?", "answer": "templa",
		 "explanation": "Nei neutri il plurale di nominativo e accusativo finisce sempre in -a: è la regola generale, non una particolarità di questa parola."},
		{"prompt": "In un neutro, che rapporto c'è fra nominativo e accusativo?", "answer": "Hanno sempre la stessa forma",
		 "explanation": "Vale in tutte e cinque le declinazioni: per capire se quel neutro sia soggetto o oggetto bisogna guardare il resto della frase."}],
	"metodo": "Sui neutri applica sempre le due regole prima della tabella: nominativo uguale ad accusativo, e plurale in -a. Restano da imparare solo le caselle che non toccano.",
	"errore": {"wrong": "Leggere *templa* come un femminile singolare.",
		"why": "È un neutro plurale: la -a finale è la desinenza dei neutri plurali, e non ha niente a che vedere con il femminile della prima declinazione."},
	"regole": ["^(templ|bell|don|verb|oppid|regn|auxili|vin|ferr)(um|i|o|a|orum|is)$"],
	"insegna": ["neutro", "templum", "templa", "templorum", "templis"]},

# ===================================================== DECLINAZIONE 3M · tutta
"latino-declinazione-3m": {
	"subject": "latino", "topic": "declinazione-3m", "fasce": BANDA_INTERA,
	"titolo": "La terza declinazione: rex, regis",
	"apertura": "È la più grande e ha fama di essere la più difficile. Lo è per una ragione sola, e una volta capita quella il resto è regolarissimo.",
	"sezioni": [
		{"titolo": "Perché sembra difficile: la prima forma non si deduce",
		 "testo": "Nelle prime due declinazioni il nominativo e il tema si somigliano: da *rosa* si arriva a ros- e da *dominus* a domin- senza sorprese. Nella terza no. *Rex* ha per tema reg-, *miles* ha milit-, *corpus* ha corpor-: fra il nominativo e il tema c'è stata una trasformazione antica, e non esiste nessuna regola per indovinarla. Questo è tutto il problema della terza declinazione, e la soluzione è quella che vale per ogni parola latina, qui però obbligatoria: si impara la parola con il suo genitivo. *Rex, regis*. Da lì in avanti non c'è più nessuna sorpresa, perché il tema reg- resta identico in tutte le caselle."},
		{"titolo": "La tabella intera",
		 "testo": "Il modello è *rex, regis*, «il re». Al singolare: nominativo *rex*, genitivo *regis*, dativo *regi*, accusativo *regem*, vocativo *rex*, ablativo *rege*. Al plurale: nominativo *reges*, genitivo *regum*, dativo *regibus*, accusativo *reges*, ablativo *regibus*. Da notare due cose: la coda -ibus del dativo e ablativo plurale è la firma inconfondibile della terza declinazione, e non compare in nessun altro gruppo; e nominativo e accusativo plurale hanno la stessa forma, *reges*, anche se non siamo fra i neutri. Appartengono a questo gruppo *consul* il console, *miles* il soldato, *lex* la legge, *pater* il padre, *homo* l'uomo."},
		{"titolo": "Come si riconosce nel testo",
		 "testo": "In una frase la terza declinazione si individua da tre indizi, in ordine di affidabilità. Primo: una parola che finisce in -ibus è quasi certamente un dativo o ablativo plurale di terza. Secondo: una che finisce in -em al singolare è un accusativo di terza — la prima fa -am e la seconda -um, quindi la -em non si confonde. Terzo: una che finisce in -is può essere un genitivo singolare di terza, ma attenzione, perché la stessa coda è anche il dativo e ablativo plurale della prima e della seconda: *rosis* e *dominis* finiscono in -is senza essere terza declinazione. Anche qui decide il contesto."}],
	"glossario": [
		{"voce": "rex, regis", "spiega": "Il modello della terza: fra nominativo e tema c'è una trasformazione che non si deduce."},
		{"voce": "regem", "spiega": "Accusativo singolare. La coda -em appartiene alla sola terza declinazione."},
		{"voce": "regibus", "spiega": "Dativo e ablativo plurale. La coda -ibus è la firma inconfondibile della terza."},
		{"voce": "reges", "spiega": "Nominativo e accusativo plurale insieme: due funzioni per una forma."}],
	"esempi": [
		{"prompt": "Da «rex» (il re): quale forma useresti per dire «al re»?", "answer": "regi",
		 "explanation": "È il dativo singolare: tema reg- ricavato dal genitivo *regis*, più la desinenza -i della casella."},
		{"prompt": "Da «consul» (il console): quale forma useresti se è il console a SUBIRE l'azione?", "answer": "consulem",
		 "explanation": "Chi subisce va all'accusativo, e l'accusativo singolare della terza è -em: tema consul- più -em."}],
	"metodo": "Della terza non imparare mai il solo nominativo: impara la coppia con il genitivo, e ricava il tema da quello. È l'unica declinazione in cui saltare questo passaggio rende impossibile tutto il resto.",
	"errore": {"wrong": "Ricavare il tema dal nominativo, come si fa nella prima e nella seconda.",
		"why": "Nella terza il nominativo è trasformato: da *rex* non si arriva a reg-, e da *miles* non si arriva a milit-. Il tema sta solo nel genitivo."},
	"regole": ["^(reg|consul|milit|leg|patr|homin|corpor|nomin|civ|urb|hosti|flumin|temp?or)(is|i|em|e|es|um|ibus)$",
		"^(rex|consul|miles|lex|pater|homo|corpus|nomen|civis|urbs|hostis|flumen|tempus)$"],
	"insegna": ["rex, regis", "regi", "regem", "reges", "regibus", "regum"]},

# ===================================================== DECLINAZIONE 3N · tutta
"latino-declinazione-3n": {
	"subject": "latino", "topic": "declinazione-3n", "fasce": BANDA_INTERA,
	"titolo": "I neutri della terza: nomen, nominis",
	"apertura": "Stessa declinazione di *rex*, con sopra la regola dei neutri. Due sistemi che si sovrappongono, e il risultato è più semplice di entrambi.",
	"sezioni": [
		{"titolo": "Due regole che si sommano",
		 "testo": "I neutri della terza declinazione seguono le desinenze della terza — quelle di *rex, regis* — ma con le due regole dei neutri applicate sopra. Regola uno: nominativo e accusativo hanno la stessa forma, al singolare come al plurale. Regola due: il loro plurale finisce in -a. Il modello è *nomen, nominis*, «il nome». Al singolare: nominativo *nomen*, genitivo *nominis*, dativo *nomini*, accusativo *nomen*, ablativo *nomine*. Al plurale: nominativo *nomina*, genitivo *nominum*, dativo *nominibus*, accusativo *nomina*, ablativo *nominibus*. Come si vede, le caselle diverse da quelle di *rex* sono soltanto le quattro toccate dalle due regole."},
		{"titolo": "Il nominativo trasformato, di nuovo",
		 "testo": "Vale anche qui, e in forma anche più marcata, il problema della terza: fra il nominativo e il tema c'è una trasformazione che non si deduce. *Nomen* ha tema nomin-, *corpus* ha corpor-, *tempus* ha tempor-, *flumen* ha flumin-. Le prime forme si somigliano fra loro pur avendo temi diversi, quindi tirare a indovinare è particolarmente rischioso. La regola pratica è la stessa e non ha eccezioni: si impara la coppia, non la parola singola. Con la coppia in testa, tutte le nove caselle restanti si costruiscono senza incertezze."},
		{"titolo": "Come si riconosce un neutro di terza nel testo",
		 "testo": "Il segnale più forte è una parola che finisce in -a preceduta da un tema che non è di prima declinazione, con accanto un verbo plurale: *nomina*, *corpora*, *tempora*, *flumina* sono neutri plurali. È la stessa trappola dei neutri della seconda — *templa* — con una differenza che aiuta: qui il tema è quasi sempre più lungo e più riconoscibile, e difficilmente somiglia a un femminile della prima. L'altro segnale sicuro è -ibus, che come nella terza maschile marca il dativo e l'ablativo plurale e non compare in nessun altro gruppo."}],
	"glossario": [
		{"voce": "nomen, nominis", "spiega": "Il modello dei neutri della terza: il tema nomin- si ricava solo dal genitivo."},
		{"voce": "nomina", "spiega": "Nominativo e accusativo plurale. La -a è la desinenza dei neutri plurali, non un femminile."},
		{"voce": "nominibus", "spiega": "Dativo e ablativo plurale: la coda -ibus della terza declinazione."},
		{"voce": "nominum", "spiega": "Genitivo plurale, «dei nomi»."}],
	"esempi": [
		{"prompt": "Da «nomen» (il nome): qual è l'accusativo singolare?", "answer": "nomen",
		 "explanation": "Nei neutri nominativo e accusativo coincidono sempre: la forma non cambia, e a dire il ruolo è il resto della frase."},
		{"prompt": "Da «corpus, corporis» (il corpo): qual è il nominativo plurale?", "answer": "corpora",
		 "explanation": "Tema corpor- ricavato dal genitivo, più la -a dei neutri plurali. Dal nominativo *corpus* quel tema non si sarebbe potuto indovinare."}],
	"metodo": "Applica prima le due regole dei neutri e poi le desinenze della terza: restano pochissime caselle da ricordare, e nessuna di quelle che confondono.",
	"errore": {"wrong": "Ricavare il tema di *corpus* o *tempus* dalla loro forma al nominativo.",
		"why": "I temi sono corpor- e tempor-, e non si deducono: la coda -us al nominativo li fa perfino somigliare a maschili della seconda."},
	"regole": ["^(nomin|corpor|tempor|flumin|opor|itiner|gener)(is|i|e|a|um|ibus)$",
		"^(nomen|corpus|tempus|flumen|opus|iter|genus)$"],
	"insegna": ["nomen, nominis", "nomina", "nominibus", "nominum"]},

# ====================================================== DECLINAZIONE 4 · tutta
"latino-declinazione-4": {
	"subject": "latino", "topic": "declinazione-4", "fasce": BANDA_INTERA,
	"titolo": "La quarta declinazione: manus, manus",
	"apertura": "È la più piccola delle cinque e la più insidiosa, perché la sua forma di citazione somiglia a quella della seconda e non lo è.",
	"sezioni": [
		{"titolo": "La trappola: due -us che non sono lo stesso -us",
		 "testo": "*Dominus, domini* è di seconda declinazione; *manus, manus* è di quarta. Al nominativo si somigliano, e chi guarda solo la prima forma sbaglia gruppo e poi sbaglia tutte le caselle che ne derivano. La differenza sta dove sta sempre: nel GENITIVO singolare. La seconda lo fa in -i, la quarta in -us — cioè uguale al nominativo. È il caso che spiega meglio di ogni altro perché in latino una parola si impara in coppia: la prima forma qui non è soltanto insufficiente, è attivamente ingannevole. Appartengono alla quarta *manus* la mano, *exercitus* l'esercito, *senatus* il senato, *portus* il porto, *fructus* il frutto."},
		{"titolo": "La tabella intera",
		 "testo": "Il modello è *manus, manus*, «la mano». Al singolare: nominativo *manus*, genitivo *manus*, dativo *manui*, accusativo *manum*, vocativo *manus*, ablativo *manu*. Al plurale: nominativo *manus*, genitivo *manuum*, dativo *manibus*, accusativo *manus*, ablativo *manibus*. Il tema è man-, e la vocale caratteristica di tutto il gruppo è la -u-, che compare in quasi ogni casella. Si noti quante coincidenze ci sono: *manus* da solo vale nominativo singolare, genitivo singolare, vocativo singolare, nominativo plurale e accusativo plurale — cinque funzioni per una forma. È il paradigma con più sovrapposizioni di tutto il latino."},
		{"titolo": "Come si sopravvive a cinque funzioni per una forma",
		 "testo": "Con un paradigma così ambiguo, la traduzione non può che passare dal contesto, e conviene farlo in modo ordinato. Si guarda il verbo: se è plurale, *manus* è soggetto plurale; se è singolare e non c'è altro candidato, è soggetto singolare. Si guarda se c'è un altro sostantivo di cui la mano possa essere proprietà: allora è genitivo. Si guarda se il verbo ha già un soggetto chiaro: allora *manus* è accusativo plurale. Le caselle che invece non si confondono mai sono tre e vale la pena ancorarsi a quelle: *manui* dativo singolare, *manum* accusativo singolare, *manuum* genitivo plurale."}],
	"glossario": [
		{"voce": "manus, manus", "spiega": "Il modello della quarta: il genitivo singolare uguale al nominativo è la sua firma."},
		{"voce": "manum", "spiega": "Accusativo singolare: una delle poche caselle della quarta che non si confonde."},
		{"voce": "manuum", "spiega": "Genitivo plurale, «delle mani». La doppia -u- lo rende inconfondibile."},
		{"voce": "manibus", "spiega": "Dativo e ablativo plurale, con la stessa coda -ibus della terza declinazione."}],
	"esempi": [
		{"prompt": "Come si distingue «manus, manus» da «dominus, domini»?", "answer": "Dal genitivo singolare",
		 "explanation": "La quarta lo fa in -us, uguale al nominativo; la seconda in -i. Al nominativo le due parole si somigliano e non dicono niente."},
		{"prompt": "Da «exercitus» (l'esercito): qual è l'accusativo singolare?", "answer": "exercitum",
		 "explanation": "Tema exercit- più la desinenza -um dell'accusativo singolare: è una delle caselle della quarta che non si confondono con nessun'altra."}],
	"metodo": "Sulla quarta ancora di più che altrove: leggi il genitivo prima di decidere qualsiasi cosa. È l'unico modo di non scambiarla per la seconda, e lo scambio porta con sé tutte le altre caselle.",
	"errore": {"wrong": "Trattare *manus* come un maschile della seconda perché finisce in -us.",
		"why": "Il genitivo di *manus* è *manus*, non *mani*: la coda del nominativo è identica ma il gruppo è un altro, e tutte le desinenze cambiano."},
	"regole": ["^(man|exercit|senat|port|fruct|grad|cas|corn)(us|ui|um|u|uum|ibus)$"],
	"insegna": ["manus, manus", "manui", "manum", "manuum", "manibus"]},

# ====================================================== DECLINAZIONE 5 · tutta
"latino-declinazione-5": {
	"subject": "latino", "topic": "declinazione-5", "fasce": BANDA_INTERA,
	"titolo": "La quinta declinazione: dies, diei",
	"apertura": "È la più piccola di tutte — poche decine di parole, e appena due di uso davvero comune — ma quelle due si incontrano continuamente.",
	"sezioni": [
		{"titolo": "Un gruppo minuscolo e due parole che contano",
		 "testo": "La quinta declinazione comprende pochissimi sostantivi, e di questi solo due si usano spesso: *dies, diei*, «il giorno», e *res, rei*, «la cosa, la faccenda, l'affare». Le altre — *spes* la speranza, *fides* la fedeltà, *acies* lo schieramento — compaiono in testi specifici. La firma del gruppo è il genitivo singolare in -ei, che nessun'altra declinazione usa: quando lo si vede non c'è nessuna ambiguità sul gruppo. *Res* in particolare è una delle parole più frequenti del latino, perché entra in moltissime espressioni: *res publica*, la cosa pubblica, da cui viene direttamente la parola italiana repubblica."},
		{"titolo": "La tabella intera",
		 "testo": "Il modello è *dies, diei*. Al singolare: nominativo *dies*, genitivo *diei*, dativo *diei*, accusativo *diem*, vocativo *dies*, ablativo *die*. Al plurale: nominativo *dies*, genitivo *dierum*, dativo *diebus*, accusativo *dies*, ablativo *diebus*. La vocale caratteristica del gruppo è la -e-, e come nella quarta ci sono parecchie coincidenze: *dies* vale nominativo singolare, vocativo, nominativo plurale e accusativo plurale; *diei* vale genitivo e dativo singolare. Le caselle inconfondibili sono *diem*, *dierum* e *diebus*, e conviene usare quelle come appigli quando si legge."},
		{"titolo": "Dove si incontra, e perché vale la pena",
		 "testo": "Le parole della quinta declinazione sono poche ma stanno dentro espressioni entrate nell'italiano e nell'uso comune, ed è questo il motivo per cui si studiano. *Res publica* ha dato repubblica. *Dies* ha dato il nome ai giorni della settimana nelle lingue romanze: *lunae dies*, il giorno della luna, è diventato lunedì. Riconoscere una parola di quinta serve quindi anche fuori dalla traduzione, perché spiega da dove vengono parole che si usano tutti i giorni senza saperlo — ed è lo stesso motivo per cui si impara il latino in generale."}],
	"glossario": [
		{"voce": "dies, diei", "spiega": "Il modello della quinta: il genitivo in -ei è la firma del gruppo, e non appartiene a nessun altro."},
		{"voce": "res, rei", "spiega": "«La cosa, la faccenda». Una delle parole più frequenti del latino: da *res publica* viene repubblica."},
		{"voce": "diem", "spiega": "Accusativo singolare: una delle tre caselle della quinta che non si confondono."},
		{"voce": "diebus", "spiega": "Dativo e ablativo plurale, con la stessa coda -bus della terza e della quarta."}],
	"esempi": [
		{"prompt": "Da quale espressione latina viene la parola «repubblica»?", "answer": "res publica",
		 "explanation": "Letteralmente «la cosa pubblica», cioè quello che appartiene a tutti: *res* è una parola della quinta declinazione."},
		{"prompt": "Da «dies» (il giorno): qual è l'accusativo singolare?", "answer": "diem",
		 "explanation": "Tema di- più la desinenza -em: è una delle poche caselle della quinta che non si sovrappone a nessun'altra."}],
	"metodo": "Riconosci la quinta dal genitivo in -ei, che non appartiene a nessun altro gruppo, e ancorati alle tre caselle inconfondibili: accusativo singolare, genitivo plurale e dativo plurale.",
	"errore": {"wrong": "Scambiare *dies* per un nominativo plurale della terza.",
		"why": "Anche la terza fa -es al plurale, ma il genitivo distingue subito: *regis* per la terza, *diei* per la quinta."},
	"regole": ["^(di|r|sp|fid|aci)(es|ei|em|e|erum|ebus)$"],
	"insegna": ["dies, diei", "res, rei", "diem", "dierum", "diebus"]},

# ========================================================== VERBO SUM · base
"latino-verbo-sum-base": {
	"subject": "latino", "topic": "verbo-sum", "fasce": BANDA_BASE,
	"titolo": "Il verbo essere, che non somiglia a se stesso",
	"apertura": "È il primo verbo che si impara e l'unico che si impara a memoria per intero, perché non segue nessuna regola.",
	"sezioni": [
		{"titolo": "Le sei persone del presente",
		 "testo": "Il presente del verbo essere in latino è questo, e va saputo senza esitazioni: *sum* io sono, *es* tu sei, *est* egli è, *sumus* noi siamo, *estis* voi siete, *sunt* essi sono. Sei forme, e conviene ripeterle in ordine finché non escono da sole, perché ricorrono in quasi ogni frase latina. Da notare che, come in tutti i verbi latini, il pronome personale non si scrive: *sum* significa già «io sono», e non serve mettere *ego* davanti. In italiano il pronome è facoltativo per lo stesso motivo — diciamo «sono stanco», non «io sono stanco» — ed è un'eredità diretta del latino."},
		{"titolo": "Perché è irregolare",
		 "testo": "Guardando le sei forme si vede che non hanno un tema costante: *sum*, *es*, *est* cominciano in modo diverso da *sumus* e *sunt*, e non c'è nessuna regola che le colleghi. Non è un capriccio: è quello che succede in tutte le lingue al verbo essere, e per un motivo preciso. Le parole molto usate si consumano nella bocca di chi le pronuncia, e le irregolarità sopravvivono proprio perché l'uso continuo le fissa — nessuno sbaglia una forma che sente cento volte al giorno. Lo stesso fenomeno si vede in italiano con «sono, sei, è, siamo, siete, sono», che è altrettanto irregolare, e in inglese con «am, are, is»."},
		{"titolo": "A che cosa serve, oltre che a dire «è»",
		 "testo": "Il verbo essere fa in latino due mestieri distinti. Il primo è dire che qualcosa esiste o si trova da qualche parte: *Roma est in Italia*, «Roma è in Italia». Il secondo, e molto più frequente, è fare da collegamento fra il soggetto e ciò che si dice di lui: *rosa pulchra est*, «la rosa è bella». In questo secondo uso il verbo non porta un'azione ma tiene insieme due elementi, e ha una conseguenza grammaticale importante che si vedrà più avanti: la parola che descrive il soggetto va al NOMINATIVO come lui, non all'accusativo, perché non subisce nessuna azione."}],
	"glossario": [
		{"voce": "sum", "spiega": "«Io sono». Il pronome non si scrive: è la desinenza a dire chi parla."},
		{"voce": "est", "spiega": "«Egli è». La forma più frequente del latino, perché serve anche a collegare soggetto e descrizione."},
		{"voce": "sumus", "spiega": "«Noi siamo»."},
		{"voce": "sunt", "spiega": "«Essi sono». Un verbo plurale è l'indizio più forte per sciogliere le forme ambigue del soggetto."}],
	"esempi": [
		{"prompt": "Che cosa significa «sumus»?", "answer": "Noi siamo",
		 "explanation": "La desinenza -mus indica la prima persona plurale in tutti i verbi latini: qui il tema è irregolare, la desinenza no."},
		{"prompt": "Che cosa significa «sunt»?", "answer": "Essi sono",
		 "explanation": "Terza persona plurale. Incontrandolo in una frase si sa subito che il soggetto deve essere plurale, e questo scioglie molte ambiguità."}],
	"metodo": "Ripeti le sei forme in ordine finché non escono senza pensarci: è l'unico verbo che conviene sapere a memoria per intero, e ricorre in quasi ogni frase.",
	"errore": {"wrong": "Aggiungere il pronome davanti al verbo, come *ego sum*, credendolo obbligatorio.",
		"why": "La desinenza dice già chi compie l'azione: il pronome in latino si aggiunge solo quando si vuole insistere sul soggetto."},
	"insegna": ["sum", "es", "est", "sumus", "estis", "sunt"]},

# ========================================================== VERBO SUM · alta
"latino-verbo-sum-alta": {
	"subject": "latino", "topic": "verbo-sum", "fasce": BANDA_ALTA,
	"titolo": "Essere come collante, e il passato",
	"apertura": "Quando *est* non porta un'azione ma collega due cose, la frase segue una regola che è la prima vera regola di sintassi latina.",
	"sezioni": [
		{"titolo": "Il predicato nominale sta al nominativo",
		 "testo": "In una frase come *rosa pulchra est*, «la rosa è bella», la parola *pulchra* non subisce nessuna azione: descrive il soggetto. Per questo non va all'accusativo, come farebbe un complemento oggetto, ma al NOMINATIVO, esattamente come *rosa*. La regola si enuncia così: con il verbo essere, ciò che si dice del soggetto si accorda con il soggetto in caso, genere e numero. Ne segue un controllo utile: se in una frase con *est* o *sunt* si trova un accusativo, quasi certamente si è sbagliato a leggere qualche desinenza, perché il verbo essere non regge complementi oggetto."},
		{"titolo": "L'imperfetto: eram, eras, erat",
		 "testo": "Il passato più semplice del verbo essere è l'imperfetto, e le sue forme sono regolari fra loro anche se il verbo non lo è: *eram* io ero, *eras* tu eri, *erat* egli era, *eramus* noi eravamo, *eratis* voi eravate, *erant* essi erano. Si riconoscono tutte dal blocco er- iniziale, che il presente non ha mai: vedere un *erat* significa senza dubbio essere in un racconto al passato. Le desinenze -m, -s, -t, -mus, -tis, -nt sono le stesse che portano tutti i verbi latini, ed è per questo che riconoscere la persona è facile anche su un verbo mai visto."},
		{"titolo": "Frasi senza soggetto scritto",
		 "testo": "Poiché la desinenza dice già chi compie l'azione, in latino il soggetto spesso non c'è affatto nella frase. *Sumus in horto* significa «siamo nel giardino», e nessuna parola dice «noi»: lo dice la coda -mus. È una cosa a cui abituarsi, perché in traduzione il pronome va aggiunto in italiano anche se in latino non c'era. E vale un avvertimento pratico: cercare a tutti i costi un soggetto scritto fa perdere tempo e a volte porta a prendere per soggetto una parola che sta facendo tutt'altro mestiere."}],
	"glossario": [
		{"voce": "predicato nominale", "spiega": "Ciò che si dice del soggetto con il verbo essere. Va al nominativo, accordato con il soggetto."},
		{"voce": "eram", "spiega": "«Io ero». Tutte le forme dell'imperfetto di essere cominciano con er-."},
		{"voce": "erat", "spiega": "«Egli era». Incontrarlo significa trovarsi in un racconto al passato."},
		{"voce": "soggetto sottinteso", "spiega": "In latino il soggetto spesso non è scritto: lo dice la desinenza del verbo."}],
	"esempi": [
		{"prompt": "In «rosa pulchra est», a quale caso sta «pulchra»?", "answer": "nominativo",
		 "explanation": "Descrive il soggetto e non subisce nessuna azione: con il verbo essere ciò che si dice del soggetto si accorda con lui."},
		{"prompt": "Che cosa significa «erat»?", "answer": "Egli era",
		 "explanation": "È l'imperfetto, riconoscibile dal blocco er- che il presente non ha mai: la desinenza -t dà la terza persona singolare."}],
	"metodo": "Quando vedi *est* o *sunt* smetti di cercare un complemento oggetto: quel verbo non ne regge, e quello che segue descrive il soggetto al nominativo.",
	"errore": {"wrong": "Mettere all'accusativo la parola che segue il verbo essere.",
		"why": "Non subisce nessuna azione ma descrive il soggetto: con il verbo essere si accorda con lui, quindi resta al nominativo."},
	"insegna": ["predicato nominale", "eram", "eras", "erat", "soggetto sottinteso"]},

# ============================================================== VERBI · base
"latino-verbi-base": {
	"subject": "latino", "topic": "verbi", "fasce": BANDA_BASE,
	"titolo": "La persona sta nella coda, non davanti",
	"apertura": "Nei verbi latini vale lo stesso principio dei nomi: l'informazione è nella desinenza. Qui l'informazione è chi compie l'azione.",
	"sezioni": [
		{"titolo": "Sei desinenze che valgono per tutti i verbi",
		 "testo": "Il presente del verbo *amare*, amare, è: *amo* io amo, *amas* tu ami, *amat* egli ama, *amamus* noi amiamo, *amatis* voi amate, *amant* essi amano. Guardando solo le parti finali si vede la regola che conta davvero: **-o** prima persona singolare, **-s** seconda singolare, **-t** terza singolare, **-mus** prima plurale, **-tis** seconda plurale, **-nt** terza plurale. Queste sei code sono le stesse in tutti i verbi latini, anche in quelli mai visti. Imparate una volta, permettono di dire chi compie l'azione in qualunque frase, anche senza sapere che cosa quel verbo significhi."},
		{"titolo": "Nessun pronome davanti",
		 "testo": "In italiano si può dire «io amo» oppure «amo», e la seconda forma è quella normale; in inglese il pronome è obbligatorio e si deve dire «I love». Il latino sta dalla parte dell'italiano, anzi la porta all'estremo: il pronome personale si scrive soltanto quando si vuole insistere, per esempio in un contrasto. Nel testo normale non c'è, e il soggetto va ricavato dalla desinenza. È un'abitudine da prendere presto, perché chi cerca il pronome in ogni frase finisce per attribuire il ruolo di soggetto a un sostantivo che sta facendo altro."},
		{"titolo": "Come si legge un verbo mai visto",
		 "testo": "Davanti a una forma verbale sconosciuta il procedimento è sempre lo stesso e dà sempre una risposta parziale ma utile. Si guarda la coda: se finisce in -mus, chi compie l'azione siamo noi; se in -tis, siete voi; se in -nt, sono loro. Poi si guarda quello che resta e si cerca di riconoscere il significato. Questo ordine — prima la persona, poi il senso — è più efficiente dell'ordine opposto, perché la persona si ricava con certezza da una regola, mentre il significato dipende dal vocabolario. E una volta nota la persona, si sa già quale sostantivo della frase può essere il soggetto."}],
	"glossario": [
		{"voce": "amo", "spiega": "«Io amo». La desinenza -o indica la prima persona singolare in quasi tutti i verbi."},
		{"voce": "amas", "spiega": "«Tu ami». La -s finale è la seconda persona singolare."},
		{"voce": "amat", "spiega": "«Egli ama». La -t finale è la terza persona singolare."},
		{"voce": "amant", "spiega": "«Essi amano». La coda -nt è la terza persona plurale, in ogni verbo latino."}],
	"esempi": [
		{"prompt": "Nel verbo latino che significa «amare»: in «amas», chi compie l'azione?", "answer": "Tu",
		 "explanation": "La desinenza -s indica la seconda persona singolare, e vale allo stesso modo in tutti i verbi latini."},
		{"prompt": "Nel verbo latino che significa «avvisare»: in «monemus», chi compie l'azione?", "answer": "Noi",
		 "explanation": "La coda -mus è la prima persona plurale: si riconosce anche senza sapere che *monere* significhi avvisare."}],
	"metodo": "Guarda sempre la coda del verbo prima del suo significato: sei desinenze coprono tutti i verbi latini, e ti dicono chi agisce anche su una parola mai vista.",
	"errore": {"wrong": "Cercare un pronome scritto per capire chi compie l'azione.",
		"why": "In latino il pronome quasi non si scrive: chi agisce sta nella desinenza del verbo, e cercarlo altrove porta a scegliere il soggetto sbagliato."},
	"insegna": ["amo", "amas", "amat", "amamus", "amatis", "amant"]},

# ============================================================== VERBI · alta
"latino-verbi-alta": {
	"subject": "latino", "topic": "verbi", "fasce": BANDA_ALTA,
	"titolo": "Le quattro coniugazioni, e la vocale che le distingue",
	"apertura": "Le desinenze sono le stesse per tutti. Quello che cambia da un gruppo all'altro è la vocale che sta appena prima, ed è lei a dire la coniugazione.",
	"sezioni": [
		{"titolo": "Quattro gruppi, quattro vocali",
		 "testo": "I verbi latini si dividono in quattro coniugazioni, riconoscibili dalla vocale che precede la desinenza dell'infinito. Prima coniugazione: *amare*, vocale -a-, e al presente fa *amo, amas, amat*. Seconda: *monere*, avvisare, vocale -e- lunga, che fa *moneo, mones, monet*. Terza: *regere*, governare, vocale -e- breve che nelle forme del presente diventa -i-, e fa *rego, regis, regit, regimus, regitis, regunt*. Quarta: *audire*, ascoltare, vocale -i-, che fa *audio, audis, audit*. Le sei desinenze di persona restano identiche in tutti e quattro i gruppi: cambia soltanto che cosa le precede."},
		{"titolo": "La terza, che è quella che si comporta peggio",
		 "testo": "Delle quattro, la terza coniugazione è la meno regolare nel presente, e vale la pena guardarla da vicino. La vocale del tema è breve e instabile: diventa -i- in quasi tutte le persone — *regis, regit, regimus, regitis* — ma sparisce nella prima singolare, *rego*, e diventa -u- nella terza plurale, *regunt*. È l'unico gruppo in cui succede, ed è la ragione per cui *regunt* sorprende chi si aspettava *regint*. Anche qui però le desinenze di persona non cambiano: sono sempre -o, -s, -t, -mus, -tis, -nt, ed è su quelle che conviene ancorarsi."},
		{"titolo": "Riconoscere la coniugazione serve a costruire il resto",
		 "testo": "Sapere a quale coniugazione appartiene un verbo non è un esercizio di classificazione: è la condizione per costruire i tempi che non si sono ancora visti, esattamente come conoscere la declinazione è la condizione per costruire i casi. L'imperfetto, per esempio, si forma in modo diverso a seconda del gruppo. Per questo un verbo latino nel vocabolario si cita sempre con più forme, e la seconda — l'infinito — è quella che rivela il gruppo: *amare* con la -a-, *monere* con la -e-, *regere* con la -e- breve, *audire* con la -i-. Stessa logica dei sostantivi, stesso motivo."}],
	"glossario": [
		{"voce": "coniugazione", "spiega": "Il gruppo a cui appartiene un verbo. Sono quattro, e si riconoscono dalla vocale dell'infinito."},
		{"voce": "monet", "spiega": "«Egli avvisa», seconda coniugazione: vocale -e- e desinenza -t della terza persona singolare."},
		{"voce": "regitis", "spiega": "«Voi governate», terza coniugazione: la vocale del tema diventa -i- e la desinenza -tis dà la seconda plurale."},
		{"voce": "regunt", "spiega": "«Essi governano»: nella terza coniugazione la vocale diventa -u- davanti a -nt, e solo lì."}],
	"esempi": [
		{"prompt": "Nel verbo latino che significa «governare»: in «regitis», chi compie l'azione?", "answer": "Voi",
		 "explanation": "La desinenza -tis è la seconda persona plurale in tutti i verbi: la -i- che la precede indica invece la terza coniugazione."},
		{"prompt": "Quante coniugazioni ha il verbo latino?", "answer": "4",
		 "explanation": "Si distinguono dalla vocale dell'infinito: -a- in *amare*, -e- in *monere* e *regere*, -i- in *audire*."}],
	"metodo": "Separa sempre in due pezzi: la desinenza finale dice la persona, la vocale che la precede dice la coniugazione. Sono due informazioni indipendenti, e si leggono una alla volta.",
	"errore": {"wrong": "Aspettarsi *regint* per «essi governano».",
		"why": "Nella terza coniugazione la vocale del tema diventa -u- davanti alla desinenza -nt: la forma corretta è *regunt*, ed è l'unico gruppo in cui accade."},
	"insegna": ["coniugazione", "monet", "regitis", "regunt", "audire"]},

# ============================================================== FRASI · base
"latino-frasi-base": {
	"subject": "latino", "topic": "frasi", "fasce": BANDA_BASE,
	"titolo": "Leggere una frase latina: si comincia dal verbo",
	"apertura": "Tradurre non è sostituire le parole una per una nell'ordine in cui stanno. È una procedura, e ha un punto di partenza preciso.",
	"sezioni": [
		{"titolo": "Il verbo prima di tutto",
		 "testo": "In una frase latina il verbo sta spessissimo in fondo, ed è comunque la prima cosa da cercare. Il motivo è che il verbo dà due informazioni che servono per tutto il resto: che azione avviene, e a quale persona e numero. Sapere che il verbo è singolare restringe subito i candidati al ruolo di soggetto; sapere che è plurale li restringe in modo opposto. Chi invece comincia dalla prima parola e prosegue verso destra si costruisce un'ipotesi su basi deboli, e spesso deve rifare tutto da capo a metà frase. La regola pratica è: leggi tutta la frase una volta senza tradurre, individua il verbo, e solo allora comincia."},
		{"titolo": "Poi il soggetto, poi l'oggetto",
		 "testo": "Individuato il verbo, si fa la domanda «chi compie questa azione?» e si cerca fra i sostantivi quello al nominativo, cioè quello che porta la desinenza giusta e che concorda col numero del verbo. Poi si fa la domanda «su che cosa ricade l'azione?» e si cerca l'accusativo. Prendiamo *Puella rosam amat*: il verbo è *amat*, terza singolare; *puella* ha la desinenza del nominativo della prima declinazione e concorda; *rosam* ha quella dell'accusativo. Traduzione: «La fanciulla ama la rosa». Le parole erano in quell'ordine, ma la traduzione non dipende dall'ordine: dipende dalle code."},
		{"titolo": "Perché l'ordine non serve a niente, e a che cosa serve invece",
		 "testo": "Scrivendo *Rosam puella amat* il significato non cambia: le desinenze sono le stesse, quindi i ruoli sono gli stessi. Allora a che cosa serve l'ordine in latino? Serve all'ENFASI. Mettere una parola all'inizio, in un punto in cui normalmente non starebbe, la mette in evidenza — come in italiano si può dire «la rosa, la fanciulla ama» per insistere sulla rosa. È una risorsa in più che l'italiano ha quasi perso, e che i poeti latini usano continuamente. Per chi traduce, la conseguenza pratica è una sola: l'ordine si può ignorare senza perdere il senso di base."}],
	"glossario": [
		{"voce": "ordine libero", "spiega": "In latino la posizione non assegna i ruoli: quelli li assegnano le desinenze."},
		{"voce": "concordanza", "spiega": "Il soggetto ha lo stesso numero del verbo. È il primo filtro per trovarlo."},
		{"voce": "enfasi", "spiega": "A questo serve l'ordine in latino: mettere in evidenza una parola spostandola."},
		{"voce": "Puella rosam amat", "spiega": "«La fanciulla ama la rosa»: nominativo, accusativo, verbo."}],
	"esempi": [
		{"prompt": "Che cosa significa «Puella rosam amat.»?", "answer": "La fanciulla ama la rosa.",
		 "explanation": "*Puella* porta la desinenza del nominativo e quindi agisce, *rosam* quella dell'accusativo e quindi subisce. Il verbo sta in fondo, come spesso accade."},
		{"prompt": "«Rosam puella amat» significa qualcosa di diverso da «Puella rosam amat»?", "answer": "No, significa lo stesso",
		 "explanation": "Le desinenze non sono cambiate, quindi i ruoli non cambiano: l'ordine in latino serve a dare enfasi, non ad assegnare le funzioni."}],
	"metodo": "Leggi la frase intera una volta senza tradurre, trova il verbo, guarda se è singolare o plurale. Solo dopo cerca il nominativo, e per ultimo l'accusativo.",
	"errore": {"wrong": "Tradurre la frase parola per parola nell'ordine in cui è scritta.",
		"why": "In latino l'ordine non assegna i ruoli: seguendolo si prende per soggetto la prima parola, che può benissimo essere un complemento oggetto."},
	"insegna": ["ordine libero", "concordanza", "enfasi"]},

# ============================================================== FRASI · alta
"latino-frasi-alta": {
	"subject": "latino", "topic": "frasi", "fasce": BANDA_ALTA,
	"titolo": "Frasi con il plurale, e con più di un complemento",
	"apertura": "Il metodo resta lo stesso. Quello che cambia è che ora le forme ambigue sono di più, e bisogna scioglierle nell'ordine giusto.",
	"sezioni": [
		{"titolo": "Il numero del verbo fa da chiave",
		 "testo": "In *Dominus servos vocat*, «Il padrone chiama gli schiavi», il verbo *vocat* è singolare: il soggetto deve quindi essere singolare, e *servos* — accusativo plurale — è escluso in partenza. Resta *dominus*, che è nominativo singolare. In *Milites patriam defendunt*, «I soldati difendono la patria», il verbo *defendunt* è plurale, quindi il soggetto va cercato fra le forme plurali: *milites* è nominativo plurale della terza, mentre *patriam* è accusativo singolare. Il numero del verbo è quindi il primo filtro da applicare, ed è quello che costa meno e taglia di più."},
		{"titolo": "Le forme che potrebbero essere due cose",
		 "testo": "Nella terza declinazione nominativo e accusativo plurale hanno la stessa forma: *milites* può essere «i soldati» che agiscono o «i soldati» che subiscono. In *Romani leges servant*, «I Romani osservano le leggi», sia *Romani* sia *leges* sono ambigui presi da soli — il primo è nominativo plurale della seconda ma potrebbe essere genitivo singolare, il secondo è nominativo o accusativo plurale della terza. Si scioglie così: il verbo *servant* è plurale e chiede un soggetto plurale; fra i due, *Romani* è quello che può esserlo al nominativo, quindi *leges* resta all'accusativo. Nessuna delle due decisioni si poteva prendere guardando una parola sola."},
		{"titolo": "Quando la frase ha tre o più parole piene",
		 "testo": "Con frasi più lunghe l'ordine di lavoro è lo stesso, esteso: verbo, soggetto, oggetto, e infine tutto il resto. Il resto sono in genere ablativi — il mezzo, il luogo, il tempo — e dativi, che indicano a chi è destinata l'azione. La regola pratica per non perdersi è non tradurre finché non si è assegnato un ruolo a ogni parola: una traduzione costruita a metà, con due parole ancora senza funzione, quasi sempre porta a forzare il senso per farlo tornare. Meglio restare ancora un momento sulle desinenze e tradurre dopo, quando lo scheletro della frase è completo."}],
	"glossario": [
		{"voce": "servos", "spiega": "Accusativo plurale della seconda: «gli schiavi» che subiscono l'azione."},
		{"voce": "milites", "spiega": "Nominativo o accusativo plurale della terza: una forma per due funzioni, sciolta dal verbo."},
		{"voce": "leges", "spiega": "Nominativo o accusativo plurale di *lex, legis*, la legge."},
		{"voce": "primo filtro", "spiega": "Il numero del verbo. Taglia i candidati al ruolo di soggetto prima di ogni altra considerazione."}],
	"esempi": [
		{"prompt": "Che cosa significa «Dominus servos vocat.»?", "answer": "Il padrone chiama gli schiavi.",
		 "explanation": "Il verbo è singolare, quindi il soggetto è *dominus*; *servos* è accusativo plurale e subisce l'azione."},
		{"prompt": "Che cosa significa «Milites patriam defendunt.»?", "answer": "I soldati difendono la patria.",
		 "explanation": "*Defendunt* è plurale, quindi il soggetto va cercato fra le forme plurali: *milites*. *Patriam* è accusativo singolare."}],
	"metodo": "Applica il numero del verbo come primo filtro: è l'informazione che costa meno da leggere e che elimina più candidati. Poi assegna un ruolo a ogni parola prima di tradurre.",
	"errore": {"wrong": "Assegnare i ruoli parola per parola man mano che si legge.",
		"why": "Molte forme sono ambigue prese da sole: si decidono solo dopo aver visto il verbo e il resto della frase, e decidendole prima si sbaglia in silenzio."},
	"insegna": ["servos", "milites", "leges", "primo filtro"]},

# ========================================================= ETIMOLOGIA · base
"latino-etimologia-base": {
	"subject": "latino", "topic": "etimologia", "fasce": BANDA_BASE,
	"titolo": "Le parole italiane che sono latine sotto",
	"apertura": "Una parola latina non spiega una parola italiana: ne spiega dieci insieme, e le tiene legate fra loro in un modo che non si dimentica più.",
	"sezioni": [
		{"titolo": "Una radice, una famiglia",
		 "testo": "Da *aqua*, che significa acqua, vengono in italiano acqua, acquedotto, acquario, acquerello, acquazzone e subacqueo. Da *terra* vengono terra, terrestre, sotterraneo, interrare, territorio e atterrare. Da *videre*, vedere, vengono visione, televisione, evidente, provvedere e visibile. Il punto non è memorizzare gli elenchi ma accorgersi del meccanismo: parole che nell'uso quotidiano sembrano non avere niente in comune si rivelano imparentate appena si vede la radice latina, e da quel momento si ricordano a gruppi invece che una per una. È il motivo più immediato per cui studiare latino aiuta l'italiano."},
		{"titolo": "Come si riconosce una radice",
		 "testo": "La radice è la parte della parola che porta il significato e che si ritrova, magari un po' modificata, in tutti i suoi parenti. Per trovarla si mettono in fila due o tre parole che sembrano imparentate e si cerca il pezzo che hanno in comune: acqua, acquedotto, acquario condividono acqu-. Poi si controlla se il significato torna: un acquedotto è ciò che conduce l'acqua, un acquario un luogo per l'acqua e per ciò che ci vive. Quando il pezzo comune c'è ma il significato non torna, quasi sempre la somiglianza è casuale — e succede più spesso di quanto si creda."},
		{"titolo": "Perché le parole latine sono rimaste",
		 "testo": "L'italiano non discende dal latino elegante dei libri ma da quello parlato tutti i giorni nell'impero, che si è trasformato lentamente bocca dopo bocca per secoli. Ne segue una cosa utile: le parole d'uso quotidiano — acqua, terra, casa, madre — hanno cambiato poco perché sono state usate sempre, mentre le parole colte sono state riprese dal latino scritto molto più tardi, e per questo somigliano ancora di più all'originale. Quando una parola italiana assomiglia moltissimo al latino, quasi sempre è arrivata per questa seconda strada."}],
	"glossario": [
		{"voce": "radice", "spiega": "La parte di parola che porta il significato e si ritrova in tutta la sua famiglia."},
		{"voce": "aqua", "spiega": "Acqua. Da qui acquedotto, acquario, subacqueo."},
		{"voce": "terra", "spiega": "Terra. Da qui terrestre, sotterraneo, territorio."},
		{"voce": "videre", "spiega": "Vedere. Da qui visione, televisione, evidente."}],
	"esempi": [
		{"prompt": "Da quale parola latina viene «sotterraneo»?", "answer": "terra",
		 "explanation": "Vuol dire «sotto terra»: la radice terr- è la stessa di terrestre, territorio e interrare."},
		{"prompt": "Da quale verbo latino viene «visione»?", "answer": "videre",
		 "explanation": "Significa vedere: dalla stessa radice vengono televisione, evidente e visibile, tutte legate al vedere."}],
	"metodo": "Quando incontri una parola italiana che non conosci, cerca dentro di lei un pezzo che hai già visto altrove. Se il significato dei due parenti torna, hai trovato la radice e con essa il senso.",
	"errore": {"wrong": "Dare per imparentate due parole solo perché cominciano allo stesso modo.",
		"why": "La somiglianza di forma senza somiglianza di significato è quasi sempre casuale: la parentela va confermata dal senso, non dalle lettere."},
	"insegna": ["radice", "aqua", "terra", "videre"]},

# ========================================================= ETIMOLOGIA · alta
"latino-etimologia-alta": {
	"subject": "latino", "topic": "etimologia", "fasce": BANDA_ALTA,
	"titolo": "I prefissi, cioè pezzi che si riusano",
	"apertura": "Davanti a una radice si può attaccare un pezzetto che ne cambia il senso in modo prevedibile. Sono pochi, e ricorrono ovunque.",
	"sezioni": [
		{"titolo": "I prefissi più frequenti, e che cosa fanno",
		 "testo": "Un prefisso è un elemento che si mette davanti a una parola e ne modifica il significato in modo regolare. I latini più produttivi in italiano sono pochi e vale la pena saperli. **Trans-** significa attraverso, oltre: transatlantico, trasporto, transito. **Sub-** significa sotto: sottomarino, subacqueo, suburbano. **Ante-** significa prima: anteprima, antefatto, anticamera. **Post-** significa dopo: posticipare, postumo. **Inter-** significa fra: internazionale, intervallo, interporre. **Contra-** significa contro: contraddire, contrasto. Conoscerne sei permette di capire a prima vista centinaia di parole mai incontrate."},
		{"titolo": "Prefisso più radice: si sommano i significati",
		 "testo": "Il bello dei prefissi è che il risultato è quasi sempre la somma dei due pezzi, e quindi si può calcolare invece che ricordare. *Trans-* più *portare* dà trasportare, cioè portare da una parte all'altra. *Sub-* più *marino* dà sottomarino, cioè sotto il mare. *Inter-* più *nazionale* dà internazionale, cioè fra le nazioni. Questo rende leggibili anche parole tecniche mai viste: se si sa che *scribere* è scrivere, allora «prescrivere» è scrivere prima, «sottoscrivere» è scrivere sotto, «trascrivere» è scrivere passando da una parte all'altra. La parola non si impara: si smonta."},
		{"titolo": "Quando il prefisso cambia forma",
		 "testo": "C'è una complicazione, e conoscerla evita di non riconoscere un prefisso che c'è. Per ragioni di pronuncia il prefisso a volte si adatta alla lettera che segue: *in-* davanti a p diventa im- (impossibile), davanti a l diventa il- (illegale), davanti a r diventa ir- (irregolare). Lo stesso accade a *sub-*, che davanti a c può diventare suc- (succedere), e a *con-*, che diventa com- davanti a p (comporre) e col- davanti a l (collaborare). Sono adattamenti di suono, non prefissi diversi: il significato resta lo stesso, e riconoscerlo è solo questione di sapere che il travestimento esiste."}],
	"glossario": [
		{"voce": "prefisso", "spiega": "Un elemento che si mette davanti a una parola e ne modifica il significato in modo regolare."},
		{"voce": "trans-", "spiega": "Attraverso, oltre: transatlantico, trasporto, transito."},
		{"voce": "sub-", "spiega": "Sotto: sottomarino, subacqueo, suburbano."},
		{"voce": "inter-", "spiega": "Fra: internazionale, intervallo, interporre."}],
	"esempi": [
		{"prompt": "Che cosa significa il prefisso latino «trans-»?", "answer": "Attraverso, oltre",
		 "explanation": "Lo si ritrova in transatlantico, che attraversa l'Atlantico, e in trasporto, che porta da una parte all'altra."},
		{"prompt": "Che cosa significa il prefisso latino «sub-»?", "answer": "Sotto",
		 "explanation": "Sottomarino è ciò che sta sotto il mare, subacqueo ciò che sta sotto l'acqua: il significato si somma alla radice."}],
	"metodo": "Davanti a una parola lunga e sconosciuta, taglia il primo pezzo e chiediti se è uno dei prefissi che conosci. Quasi sempre il significato è la somma del prefisso e di ciò che resta.",
	"errore": {"wrong": "Non riconoscere un prefisso perché ha cambiato lettera, come in «illegale» o «irregolare».",
		"why": "È sempre *in-*, adattato alla consonante che segue per ragioni di pronuncia: il significato di negazione resta identico."},
	"insegna": ["prefisso", "trans-", "sub-", "ante-", "post-", "inter-", "contra-"]},

# ======================================================== VOCABOLARIO · base
"latino-vocabolario-base": {
	"subject": "latino", "topic": "vocabolario", "fasce": BANDA_BASE,
	"titolo": "Le prime parole, e perché proprio queste",
	"apertura": "Un vocabolario iniziale non si sceglie a caso: si scelgono le parole che ricorrono di più nelle frasi di esercizio e che hanno lasciato più tracce in italiano.",
	"sezioni": [
		{"titolo": "Le parole della prima declinazione",
		 "testo": "*Aqua* significa acqua, ed è la parola da cui vengono acquedotto e acquario. *Puella* significa fanciulla, bambina. *Rosa* significa rosa, ed è il modello su cui si impara tutta la prima declinazione. *Terra* significa terra, e da lei vengono terrestre e sotterraneo. *Patria* significa patria, cioè la terra dei padri — *pater* è padre — e questo spiega la parola meglio di qualunque definizione. *Silva* significa selva, bosco. Tutte finiscono in -a al nominativo e fanno il genitivo in -ae: sono femminili, e si comportano esattamente come *rosa*."},
		{"titolo": "Le parole della seconda",
		 "testo": "*Dominus* significa signore, padrone: è il modello dei maschili in -us. *Servus* significa schiavo, ed è la parola che sta di fronte a *dominus* in moltissime frasi di esercizio. *Amicus* significa amico, e da lei vengono amicizia e amichevole. *Magister* significa maestro, e da lei maestro e magistrato — chi ha autorità. *Liber* significa libro, ed è una parola su cui vale la pena fermarsi un momento: esiste anche un aggettivo *liber* che significa libero, e sono due parole diverse che si scrivono uguali. *Puer* significa ragazzo, fanciullo, e da lei viene puerile."},
		{"titolo": "Come si impara una parola latina",
		 "testo": "Non si impara da sola. Si impara con tre informazioni insieme: il nominativo, il genitivo e il significato — *rosa, rosae*, la rosa. Il genitivo serve perché senza di lui non si può costruire nessun'altra forma, e il significato serve perché senza di lui la forma non serve a niente. Aggiungere una quarta informazione aiuta moltissimo: la parola italiana che ne discende. *Magister* si ricorda meglio se si sa che magistrato viene da lì; *puer* si ricorda meglio pensando a puerile. La parola imparata da sola si dimentica; quella agganciata a qualcosa che già si sa, no."}],
	"glossario": [
		{"voce": "aqua", "spiega": "Acqua. Prima declinazione, femminile."},
		{"voce": "puella", "spiega": "Fanciulla, bambina. Prima declinazione."},
		{"voce": "amicus", "spiega": "Amico. Seconda declinazione, maschile. Da qui amicizia."},
		{"voce": "magister", "spiega": "Maestro. Seconda declinazione, con nominativo in -er. Da qui magistrato."}],
	"esempi": [
		{"prompt": "Che cosa significa «puella»?", "answer": "Bambina",
		 "explanation": "Fanciulla o bambina: è una delle parole più usate negli esercizi, perché appartiene alla prima declinazione e compare in moltissime frasi."},
		{"prompt": "Che cosa significa «magister»?", "answer": "Maestro",
		 "explanation": "Di seconda declinazione, con nominativo in -er: da questa parola vengono in italiano maestro e magistrato."}],
	"metodo": "Impara ogni parola con tre pezzi — nominativo, genitivo, significato — e agganciale una parola italiana che ne discende. Il gancio è quello che la fa restare.",
	"errore": {"wrong": "Imparare solo il nominativo e il significato.",
		"why": "Senza il genitivo non si conosce la declinazione, e senza la declinazione non si può costruire nessuna delle altre forme della parola."},
	"insegna": ["aqua", "puella", "rosa", "terra", "patria", "silva", "dominus", "servus", "amicus", "magister", "liber", "puer"]},

# ======================================================== VOCABOLARIO · alta
"latino-vocabolario-alta": {
	"subject": "latino", "topic": "vocabolario", "fasce": BANDA_ALTA,
	"titolo": "Parole che ingannano",
	"apertura": "Alcune parole latine somigliano a parole italiane e significano tutt'altro. Sono poche, ricorrono spesso, e sbagliarle rovescia il senso della frase.",
	"sezioni": [
		{"titolo": "I falsi amici del latino",
		 "testo": "*Bellum* significa guerra, non «bello»: la somiglianza è casuale, e l'aggettivo latino per bello è *pulcher*. È il falso amico più frequente in assoluto, perché *bellum* compare in moltissimi testi storici. *Liber* significa libro se è sostantivo e libero se è aggettivo: due parole diverse con la stessa scrittura, e a distinguerle è la funzione nella frase. *Ferro* può essere l'ablativo di *ferrum*, il ferro, ma somiglia al verbo italiano ferire, che non c'entra. *Vir* significa uomo inteso come maschio adulto, mentre *homo* significa essere umano in generale: due parole che l'italiano ha fuso in una sola."},
		{"titolo": "Parole di significato più largo o più stretto dell'italiano",
		 "testo": "Un caso meno vistoso ma più insidioso è quello delle parole che esistono in entrambe le lingue con un'ampiezza diversa. *Virtus* non significa soltanto virtù nel senso morale: significa anche valore, coraggio, qualità dell'uomo forte. *Fortuna* non significa soltanto buona sorte: significa sorte in generale, e può essere cattiva. *Res* significa cosa, ma anche faccenda, affare, questione, situazione — ed è talmente vaga che il suo senso lo decide sempre la frase intorno. Tradurle con la parola italiana che somiglia dà spesso una frase che sta in piedi e dice una cosa diversa da quella scritta."},
		{"titolo": "Come ci si difende",
		 "testo": "La difesa non è imparare l'elenco dei falsi amici, che è lungo e non finisce mai. È un'abitudine: quando una traduzione viene fuori strana, sospettare della parola che somigliava di più all'italiano invece che di quelle difficili. Su quelle difficili si è già andati a controllare; su quella facile no, ed è proprio lì che il vocabolario non è stato aperto. La seconda difesa è il contesto storico: in un testo che parla di eserciti, *bellum* è quasi certamente guerra, e leggerlo come «bello» produce una frase che non significa niente — ed è quel «non significa niente» il segnale da ascoltare."}],
	"glossario": [
		{"voce": "bellum", "spiega": "Guerra, non «bello». L'aggettivo per bello è *pulcher*."},
		{"voce": "liber", "spiega": "Libro come sostantivo, libero come aggettivo: due parole con la stessa scrittura."},
		{"voce": "virtus", "spiega": "Virtù, ma anche valore e coraggio: più largo dell'italiano."},
		{"voce": "vir", "spiega": "Uomo inteso come maschio adulto, distinto da *homo*, essere umano."}],
	"esempi": [
		{"prompt": "Che cosa significa «bellum»?", "answer": "Guerra",
		 "explanation": "È il falso amico più frequente del latino: somiglia a «bello», ma l'aggettivo per bello è *pulcher*."},
		{"prompt": "Che cosa significa il sostantivo «liber, libri»?", "answer": "Libro",
		 "explanation": "Con quel genitivo è il sostantivo della seconda declinazione: l'aggettivo *liber*, che significa libero, si riconosce dalla funzione nella frase."}],
	"metodo": "Quando una traduzione suona strana, vai a controllare la parola che somigliava di più all'italiano. Su quelle difficili hai già aperto il vocabolario; su quella facile no.",
	"errore": {"wrong": "Tradurre *bellum* con «bello».",
		"why": "Significa guerra: la somiglianza con l'italiano è casuale, e in un testo storico produce frasi che non vogliono dire niente."},
	"insegna": ["bellum", "liber", "virtus", "fortuna", "res", "vir", "homo"]},

# ==============================================================================
# SCIENZE — la quinta materia convertita (11 settembre 2026)
#
# Otto argomenti, due bande ciascuno. Qui la maggior parte delle risposte non è
# un nome ma una spiegazione, quindi il controllo 4b morde su poche domande — e
# proprio per questo scienze entra comunque fra le materie di richiamo: le poche
# che chiedono un nome («qual è l'unità di base dei viventi?») sono esattamente
# quelle in cui il documento deve aver pronunciato la parola.

# =========================================================== VIVENTI · base
"scienze-viventi-base": {
	"subject": "scienze", "topic": "viventi", "fasce": BANDA_BASE,
	"titolo": "Che cosa distingue una cosa viva da una che non lo è",
	"apertura": "Sembra ovvio finché non si prova a scriverlo: un cristallo cresce, il fuoco si nutre e si moltiplica, eppure nessuno dei due è vivo.",
	"sezioni": [
		{"titolo": "I segni che valgono tutti insieme",
		 "testo": "Tutti gli esseri viventi fanno le stesse cose: nascono, crescono, si nutrono, si riproducono e muoiono. Il punto è che valgono INSIEME, non uno alla volta: prese singolarmente ciascuna di queste cose si trova anche altrove. Un cristallo cresce, ma per accumulo dall'esterno, mentre un vivente cresce dall'interno costruendosi da sé con il materiale che ha assorbito. Il fuoco consuma e si propaga, ma non nasce da un altro fuoco che gli trasmette delle istruzioni. È la combinazione a definire la vita, ed è per questo che una definizione fatta di un solo segno non ha mai funzionato."},
		{"titolo": "Tutti fatti di cellule",
		 "testo": "L'unità di base di tutti gli esseri viventi è la cellula: la più piccola parte capace di fare, da sola, tutte le cose che fa un vivente. Alcuni organismi ne hanno una sola — i batteri, molte alghe — e si dicono unicellulari; altri ne hanno miliardi, organizzate in tessuti e organi, e si dicono pluricellulari. Da questo discende una regola che vale senza eccezioni conosciute: ogni cellula nasce da un'altra cellula. È il motivo per cui la vita, oggi, non compare mai dal nulla, e per cui una ferita si chiude dividendo le cellule che stanno ai bordi invece che facendone apparire di nuove."},
		{"titolo": "Le piante, e perché i funghi non lo sono",
		 "testo": "In una pianta ogni parte ha un mestiere. Le radici assorbono l'acqua e i sali dal terreno e tengono ferma la pianta; il fusto le trasporta verso l'alto; le foglie fanno la fotosintesi, cioè usano la luce del Sole per fabbricare da sé il nutrimento partendo da acqua e anidride carbonica. Quest'ultima è la differenza che conta: una pianta si costruisce il cibo, un animale lo deve trovare già fatto. I funghi per molto tempo sono stati messi con le piante perché non si muovono, ma non fanno la fotosintesi: assorbono sostanze già pronte dall'ambiente, e per questo oggi stanno in un regno tutto loro."}],
	"glossario": [
		{"voce": "cellula", "spiega": "L'unità di base di tutti i viventi. Ogni cellula nasce da un'altra cellula."},
		{"voce": "fotosintesi", "spiega": "Il modo in cui le piante fabbricano il nutrimento usando la luce, l'acqua e l'anidride carbonica."},
		{"voce": "radici", "spiega": "Assorbono acqua e sali dal terreno, e tengono ferma la pianta."},
		{"voce": "unicellulare", "spiega": "Fatto di una cellula sola, che da sola fa tutto."}],
	"esempi": [
		{"prompt": "Qual è l'unità di base di tutti gli esseri viventi?", "answer": "La cellula",
		 "explanation": "È la parte più piccola capace di fare da sola tutto quello che fa un vivente, e ogni cellula nasce dalla divisione di un'altra."},
		{"prompt": "Perché i funghi non sono considerati piante?", "answer": "Perché non fanno la fotosintesi",
		 "explanation": "Non si fabbricano il nutrimento con la luce: lo assorbono già pronto dall'ambiente, e questo li separa dalle piante nonostante non si muovano."}],
	"metodo": "Davanti a un dubbio su «è vivo?», non cercare un solo segno: controllali tutti insieme. È la combinazione a definire la vita, e ogni segno preso da solo si trova anche in cose non vive.",
	"errore": {"wrong": "Classificare i funghi fra le piante perché non si muovono.",
		"why": "Il criterio non è il movimento ma come ci si procura il nutrimento: le piante lo fabbricano con la fotosintesi, i funghi lo assorbono già pronto."},
	"insegna": ["cellula", "fotosintesi", "radici", "unicellulare"]},

# =========================================================== VIVENTI · alta
"scienze-viventi-alta": {
	"subject": "scienze", "topic": "viventi", "fasce": BANDA_ALTA,
	"titolo": "Adattamento, e perché si classificano gli esseri viventi",
	"apertura": "Due idee che a scuola sembrano elenchi da imparare e sono invece strumenti: servono a prevedere, non a ordinare.",
	"sezioni": [
		{"titolo": "Che cos'è un adattamento",
		 "testo": "Un adattamento è una caratteristica che aiuta un organismo a vivere in un certo ambiente: il pelo folto della volpe artica, le foglie ridotte a spine del cactus, le zampe palmate dell'anatra. La parte che si fraintende più spesso è il COME nasce. L'organismo non decide di adattarsi e non si trasforma perché ne ha bisogno: dentro una popolazione ci sono già differenze, e chi si trova ad avere la caratteristica utile sopravvive più a lungo e lascia più discendenti. Nel giro di molte generazioni quella caratteristica diventa comune. L'adattamento è il risultato di una selezione, non di uno sforzo."},
		{"titolo": "Vertebrati e invertebrati",
		 "testo": "La prima grande divisione degli animali è fra vertebrati e invertebrati, e il criterio è uno solo: il vertebrato ha una colonna vertebrale, una struttura ossea interna che sostiene il corpo e protegge il midollo. I vertebrati si dividono in cinque classi — pesci, anfibi, rettili, uccelli e mammiferi — e sono in realtà una minoranza: la stragrande maggioranza delle specie animali è fatta di invertebrati, insetti soprattutto. È un buon promemoria contro l'illusione ottica per cui gli animali che ci vengono in mente per primi sono quasi tutti vertebrati: sono i più grandi e i più visibili, non i più numerosi."},
		{"titolo": "Perché si classifica",
		 "testo": "Mettere in gruppi gli esseri viventi non serve a fare ordine negli elenchi: serve a PREVEDERE. Se si sa che un animale è un mammifero, si sa già senza averlo osservato che ha una temperatura costante, che allatta i piccoli e che respira con i polmoni. Una classificazione utile è quella che permette di dire cose vere su un individuo mai visto, a partire dal gruppo a cui appartiene. È lo stesso criterio per cui in latino serve conoscere la declinazione di una parola: il gruppo permette di costruire quello che non si è ancora incontrato."}],
	"glossario": [
		{"voce": "adattamento", "spiega": "Una caratteristica che aiuta a vivere in un ambiente. Nasce da selezione, non da uno sforzo dell'individuo."},
		{"voce": "vertebrato", "spiega": "Animale con una colonna vertebrale. Sono cinque classi, e una minoranza delle specie."},
		{"voce": "invertebrato", "spiega": "Animale senza colonna vertebrale: la grande maggioranza delle specie, insetti in testa."},
		{"voce": "classificare", "spiega": "Raggruppare per poter prevedere: dal gruppo si ricavano proprietà di un individuo mai visto."}],
	"esempi": [
		{"prompt": "Che cos'è un adattamento?", "answer": "Una caratteristica che aiuta a vivere in un ambiente",
		 "explanation": "Non è una trasformazione voluta: chi si trova già ad averla sopravvive di più e la trasmette, finché diventa comune nella popolazione."},
		{"prompt": "Che differenza c'è fra un vertebrato e un invertebrato?", "answer": "Il vertebrato ha una colonna vertebrale",
		 "explanation": "È l'unico criterio della divisione. I vertebrati sono i più visibili ma sono una minoranza delle specie animali."}],
	"metodo": "Quando incontri un adattamento, chiediti quale problema dell'ambiente risolve. La caratteristica si ricorda molto meglio insieme alla difficoltà per cui è utile.",
	"errore": {"wrong": "Dire che un animale «si è adattato» come se avesse cambiato se stesso per bisogno.",
		"why": "L'individuo non si trasforma: dentro la popolazione la caratteristica utile c'era già, e chi l'aveva ha lasciato più discendenti."},
	"insegna": ["adattamento", "vertebrato", "invertebrato", "classificare"]},

# ============================================================= CORPO · base
"scienze-corpo-base": {
	"subject": "scienze", "topic": "corpo", "fasce": BANDA_BASE,
	"titolo": "Gli apparati, e perché si chiamano così",
	"apertura": "Un apparato è un gruppo di organi che collaborano a uno stesso compito. Impararli separati è il modo più rapido per non capire come funziona il corpo.",
	"sezioni": [
		{"titolo": "Respirare e far circolare",
		 "testo": "I polmoni servono a scambiare ossigeno e anidride carbonica: l'aria che entra cede ossigeno al sangue, e il sangue lascia ai polmoni l'anidride carbonica che deve uscire. Da soli però i polmoni non servirebbero a niente, perché l'ossigeno va portato dove serve — in ogni muscolo, in ogni organo. Quel trasporto lo fa il sangue, spinto dal cuore, che è una pompa che non si ferma mai. Respiratorio e circolatorio sono quindi due apparati che hanno senso solo insieme: uno prende l'ossigeno, l'altro lo consegna, e lo stesso viaggio riporta indietro lo scarto."},
		{"titolo": "Digerire comincia in bocca",
		 "testo": "La digestione non comincia nello stomaco ma in bocca, e in due modi insieme: la masticazione rompe il cibo in pezzi piccoli, aumentando la superficie su cui si potrà lavorare, e la saliva comincia già a trasformare chimicamente gli amidi. Da lì il cibo scende nello stomaco, dove i succhi gastrici continuano, e poi nell'intestino, dove le sostanze utili passano nel sangue. Tutto l'apparato digerente fa quindi un lavoro solo, spezzato in tappe: ridurre il cibo in pezzi abbastanza piccoli da poter entrare nel sangue e raggiungere le cellule."},
		{"titolo": "Ossa e muscoli lavorano in coppia",
		 "testo": "Le ossa non si muovono da sole: sono rigide e servono a sostenere, ma il movimento lo producono i muscoli, che si accorciano e le tirano. Ogni movimento è quindi il risultato di una coppia — un muscolo tira da una parte, un altro tira dalla parte opposta — perché un muscolo può solo contrarsi, mai spingere. Lo scheletro poi fa due cose oltre a sostenere: protegge gli organi delicati, con il cranio attorno al cervello e le costole attorno a cuore e polmoni, e produce nel midollo le cellule del sangue. Un'ossatura non è quindi un'impalcatura morta: è un organo attivo."}],
	"glossario": [
		{"voce": "apparato", "spiega": "Un gruppo di organi che collaborano a uno stesso compito."},
		{"voce": "sangue", "spiega": "Il trasporto: porta l'ossigeno dai polmoni a tutto il corpo e riporta indietro l'anidride carbonica."},
		{"voce": "saliva", "spiega": "Comincia la digestione già in bocca, trasformando gli amidi mentre i denti riducono il cibo."},
		{"voce": "midollo", "spiega": "La parte interna delle ossa in cui si producono le cellule del sangue."}],
	"esempi": [
		{"prompt": "Che cosa trasporta l'ossigeno dai polmoni al resto del corpo?", "answer": "Il sangue",
		 "explanation": "I polmoni lo prendono dall'aria, ma senza un trasporto resterebbe lì: il cuore spinge il sangue, e il sangue lo consegna a ogni cellula."},
		{"prompt": "Come si muovono le ossa?", "answer": "Grazie ai muscoli che le tirano",
		 "explanation": "Un muscolo può solo accorciarsi, mai spingere: per questo ogni movimento richiede una coppia di muscoli che tirano in versi opposti."}],
	"metodo": "Di ogni organo chiediti con quale altro lavora. Nel corpo quasi nessuna struttura ha senso da sola, e le domande difficili sono quasi sempre su come due apparati si passano il lavoro.",
	"errore": {"wrong": "Dire che la digestione comincia nello stomaco.",
		"why": "Comincia in bocca: la masticazione riduce il cibo e la saliva inizia già a trasformarlo chimicamente prima che scenda."},
	"insegna": ["apparato", "sangue", "saliva", "midollo", "polmoni"]},

# ============================================================= CORPO · alta
"scienze-corpo-alta": {
	"subject": "scienze", "topic": "corpo", "fasce": BANDA_ALTA,
	"titolo": "Quando il corpo si accorda con se stesso",
	"apertura": "La domanda interessante non è che cosa fa ogni apparato, ma come fanno a sapere l'uno dell'altro quando cambia qualcosa.",
	"sezioni": [
		{"titolo": "Perché correndo il respiro accelera",
		 "testo": "Correndo, i muscoli lavorano di più e quindi consumano più ossigeno e producono più anidride carbonica. Il corpo se ne accorge misurando proprio l'anidride carbonica nel sangue: quando sale, il centro del respiro fa accelerare e approfondire gli atti respiratori, e insieme il cuore batte più in fretta per far circolare il sangue più rapidamente. Due apparati diversi rispondono così allo stesso segnale, senza che nessuno decida niente coscientemente. È l'esempio più semplice di regolazione automatica, ed è il motivo per cui il respiro riprende da solo il ritmo normale quando ci si ferma."},
		{"titolo": "Il sangue come rete di collegamento",
		 "testo": "Se si guarda il corpo come un insieme di parti che devono coordinarsi, il sangue è la rete che le collega tutte. Trasporta l'ossigeno dai polmoni e le sostanze nutrienti dall'intestino; porta via l'anidride carbonica verso i polmoni e gli altri scarti verso i reni; e distribuisce i messaggeri chimici che dicono agli organi lontani che cosa sta succedendo. Un solo sistema di tubi fa quindi tre mestieri insieme — rifornimento, smaltimento e comunicazione — ed è per questo che quasi ogni problema serio in un organo si vede prima o poi in un esame del sangue."},
		{"titolo": "Tenere costante l'interno mentre fuori cambia",
		 "testo": "Il corpo mantiene condizioni interne quasi costanti anche quando l'ambiente cambia molto: la temperatura resta attorno ai trentasette gradi d'estate e d'inverno. I meccanismi sono semplici e si osservano tutti i giorni. Quando fa caldo si suda, e l'acqua evaporando porta via calore; quando fa freddo si trema, e la contrazione rapida dei muscoli produce calore. Tutte e due le risposte partono senza che si decida di attivarle. Questo modo di funzionare — misurare uno scarto e reagire per annullarlo — si ritrova identico in moltissimi sistemi viventi, e vale la pena riconoscerlo come schema."}],
	"glossario": [
		{"voce": "regolazione automatica", "spiega": "Misurare uno scarto e reagire per annullarlo, senza decidere. Il corpo lo fa di continuo."},
		{"voce": "anidride carbonica", "spiega": "Lo scarto della respirazione delle cellule. È il suo livello nel sangue a far accelerare il respiro."},
		{"voce": "sudare", "spiega": "L'acqua che evapora dalla pelle porta via calore: è il raffreddamento del corpo."},
		{"voce": "tremare", "spiega": "Contrazioni rapide dei muscoli che producono calore quando la temperatura scende."}],
	"esempi": [
		{"prompt": "Perché quando corri il respiro accelera?", "answer": "Perché i muscoli chiedono più ossigeno",
		 "explanation": "E producono più anidride carbonica: è il suo aumento nel sangue il segnale che fa accelerare respiro e battito, automaticamente."},
		{"prompt": "Perché si trema quando fa freddo?", "answer": "Perché i muscoli producono calore",
		 "explanation": "La contrazione rapida e ripetuta genera calore: è una risposta automatica per tenere costante la temperatura interna."}],
	"metodo": "Davanti a una reazione del corpo cerca il segnale che l'ha innescata e lo scarto che sta cercando di annullare. Quasi tutte le risposte automatiche hanno questa forma.",
	"errore": {"wrong": "Credere che il respiro acceleri perché manca aria nei polmoni.",
		"why": "I polmoni sono pieni come sempre: a far accelerare è l'aumento di anidride carbonica nel sangue, che è un segnale chimico, non una mancanza di spazio."},
	"insegna": ["regolazione automatica", "anidride carbonica", "sudare", "tremare"]},

# =========================================================== MATERIA · base
"scienze-materia-base": {
	"subject": "scienze", "topic": "materia", "fasce": BANDA_BASE,
	"titolo": "Tre stati, e le particelle che li spiegano",
	"apertura": "Solido, liquido, gassoso non sono tre tipi di sostanza: sono tre modi in cui la stessa sostanza può stare, e a deciderlo è quanto si muovono le sue particelle.",
	"sezioni": [
		{"titolo": "Come si riconoscono i tre stati",
		 "testo": "Un solido ha forma propria e volume proprio: se lo si sposta da un recipiente a un altro non cambia né la sua forma né quanto spazio occupa. Un liquido ha volume proprio ma non forma propria: occupa sempre lo stesso spazio, però prende la forma del recipiente che lo contiene. Un gas non ha né l'una né l'altro: si espande fino a riempire tutto lo spazio disponibile, qualunque esso sia. Bastano quindi due domande per classificare qualsiasi campione: «mantiene la forma?» e «mantiene il volume?». Due sì, un sì, nessun sì."},
		{"titolo": "Che cosa fanno le particelle",
		 "testo": "La spiegazione delle tre differenze sta sotto, in come sono disposte e quanto si muovono le particelle di cui la sostanza è fatta. In un solido sono vicinissime e tenute in posizione fissa: possono solo vibrare attorno al loro posto, e per questo la forma resta. In un liquido sono ancora vicine ma libere di scorrere le une sulle altre: restano a contatto — quindi il volume non cambia — ma non hanno una posizione, e la forma si adatta. In un gas sono lontanissime e si muovono in tutte le direzioni, urtandosi di rado: niente le tiene insieme, e occupano tutto quello che trovano."},
		{"titolo": "Scaldare vuol dire dare movimento",
		 "testo": "Scaldare una sostanza significa aumentare l'agitazione delle sue particelle. Finché l'aumento è piccolo si nota solo come temperatura più alta; quando diventa abbastanza grande le particelle vincono le forze che le tenevano ferme, e la sostanza cambia stato. Per questo scaldando un solido si arriva a un punto in cui le particelle si muovono tanto da perdere la posizione fissa, e il solido fonde diventando liquido. Raffreddare fa il percorso inverso. Lo stato non è quindi una proprietà fissa di una sostanza ma dipende dalle condizioni: l'acqua è solida, liquida o gassosa a seconda della temperatura."}],
	"glossario": [
		{"voce": "solido", "spiega": "Ha forma e volume propri: le particelle sono in posizione fissa e possono solo vibrare."},
		{"voce": "liquido", "spiega": "Ha volume proprio ma prende la forma del recipiente: le particelle scorrono restando a contatto."},
		{"voce": "gassoso", "spiega": "Non ha né forma né volume propri: le particelle sono lontane e riempiono ogni spazio."},
		{"voce": "fondere", "spiega": "Passare da solido a liquido: le particelle si muovono tanto da perdere la posizione fissa."}],
	"esempi": [
		{"prompt": "In quale stato la materia ha forma e volume propri?", "answer": "Solido",
		 "explanation": "Le sue particelle sono tenute in posizione fissa e possono solo vibrare: nessuna delle due caratteristiche cambia spostandolo."},
		{"prompt": "Che cosa succede alle particelle quando un solido si scalda e fonde?", "answer": "Si muovono di più e perdono la posizione fissa",
		 "explanation": "Scaldare significa aumentare la loro agitazione: a un certo punto vincono le forze che le tenevano ferme, e la forma non si conserva più."}],
	"metodo": "Per classificare un campione fatti due domande in quest'ordine: mantiene il volume? mantiene la forma? Due sì è solido, solo il primo è liquido, nessuno dei due è gas.",
	"errore": {"wrong": "Trattare «solido» e «liquido» come tipi diversi di sostanza.",
		"why": "Sono stati della stessa sostanza in condizioni diverse: l'acqua è solida, liquida o gassosa a seconda della temperatura."},
	"insegna": ["solido", "liquido", "gassoso", "fondere", "particelle"]},

# =========================================================== MATERIA · alta
"scienze-materia-alta": {
	"subject": "scienze", "topic": "materia", "fasce": BANDA_ALTA,
	"titolo": "I passaggi di stato, e come si separa un miscuglio",
	"apertura": "Ogni passaggio ha un nome, e i nomi vanno a coppie opposte. Poi c'è una sostanza che si comporta al contrario di tutte le altre, e ci ha salvati.",
	"sezioni": [
		{"titolo": "I nomi dei passaggi, a coppie",
		 "testo": "Da solido a liquido è la fusione; da liquido a solido la solidificazione. Da liquido a gassoso l'evaporazione; da gassoso a liquido la condensazione. Da solido direttamente a gassoso la sublimazione, che si vede nel ghiaccio secco. Impararli a coppie opposte è molto più efficiente che impararli in fila, perché ogni coppia è lo stesso fenomeno percorso nei due versi: nella direzione che va verso il disordine si fornisce calore, in quella che va verso l'ordine il calore si toglie. Sapendo questo, il verso di ogni passaggio si ricostruisce anche senza ricordare il nome."},
		{"titolo": "L'acqua che ghiacciando si espande",
		 "testo": "Quasi tutte le sostanze, solidificando, occupano meno spazio: le particelle si avvicinano e si ordinano. L'acqua no. Le sue molecole, congelando, si dispongono in una struttura regolare che le tiene più distanziate di quanto non fossero da liquide, e il risultato è che il ghiaccio occupa più spazio dell'acqua da cui è venuto. Da qui due conseguenze molto concrete: una bottiglia piena lasciata nel congelatore si spacca, e il ghiaccio galleggia invece di affondare. La seconda ha effetti enormi, perché uno strato di ghiaccio che resta in superficie isola l'acqua sotto e permette la vita nei laghi ghiacciati."},
		{"titolo": "Miscugli, e come si separano",
		 "testo": "Un miscuglio è più sostanze mescolate ma non combinate: ciascuna conserva le proprie proprietà, e per questo si possono riseparare con mezzi fisici, senza reazioni chimiche. Il metodo si sceglie in base a quale proprietà le distingue. Se una evapora e l'altra no, si fa evaporare: è così che si separa il sale dall'acqua salata, lasciando andare via l'acqua e trovando il sale sul fondo. Se una è solida in pezzi e l'altra liquida, si filtra. Se hanno densità diverse e non si mescolano, si lasciano separare da sole e si travasa. La domanda da farsi è sempre la stessa: in che cosa le due sostanze differiscono?"}],
	"glossario": [
		{"voce": "evaporazione", "spiega": "Il passaggio da liquido a gassoso. Il suo opposto è la condensazione."},
		{"voce": "sublimazione", "spiega": "Il passaggio diretto da solido a gassoso, senza passare dal liquido."},
		{"voce": "miscuglio", "spiega": "Più sostanze mescolate ma non combinate: ognuna tiene le proprie proprietà e si può riseparare."},
		{"voce": "filtrare", "spiega": "Separare un solido in pezzi da un liquido facendo passare solo quest'ultimo."}],
	"esempi": [
		{"prompt": "Come si chiama il passaggio da liquido a gassoso?", "answer": "Evaporazione",
		 "explanation": "Il suo opposto è la condensazione: nella direzione verso il gas si fornisce calore, in quella verso il liquido lo si toglie."},
		{"prompt": "Come si può separare il sale dall'acqua salata?", "answer": "Facendo evaporare l'acqua",
		 "explanation": "È un miscuglio, quindi le due sostanze conservano le proprie proprietà: l'acqua evapora e il sale no, e questa differenza basta a separarli."}],
	"metodo": "Per separare un miscuglio non cercare un metodo a memoria: chiediti in che cosa le due sostanze differiscono. La differenza che trovi ti dice già quale metodo usare.",
	"errore": {"wrong": "Aspettarsi che l'acqua, come le altre sostanze, occupi meno spazio da solida.",
		"why": "È l'eccezione: congelando le molecole si dispongono più distanziate, e per questo il ghiaccio galleggia e le bottiglie piene si spaccano."},
	"insegna": ["evaporazione", "condensazione", "sublimazione", "miscuglio", "filtrare"]},

# ==================================================== TERRA UNIVERSO · base
"scienze-terra-universo-base": {
	"subject": "scienze", "topic": "terra-universo", "fasce": BANDA_BASE,
	"titolo": "Due movimenti, e tutto quello che ne segue",
	"apertura": "Il giorno, le stagioni e le fasi della Luna non sono tre fenomeni da imparare separati: sono conseguenze di due soli movimenti più uno.",
	"sezioni": [
		{"titolo": "La rotazione: il giorno e la notte",
		 "testo": "La Terra gira su se stessa, e impiega circa ventiquattro ore a compiere un giro completo. È questo movimento — la rotazione — a causare l'alternarsi del giorno e della notte: il Sole illumina sempre metà del pianeta, e ruotando ogni punto passa a turno dalla parte illuminata a quella in ombra. Da qui viene anche l'illusione più antica che esista: il Sole sembra muoversi da est a ovest, mentre in realtà siamo noi a girare nel verso opposto. Vale la pena tenerlo a mente, perché quasi tutti i fenomeni del cielo che sembrano movimenti del cielo sono invece movimenti nostri."},
		{"titolo": "La rivoluzione e l'asse inclinato: le stagioni",
		 "testo": "La Terra compie anche un secondo movimento: gira attorno al Sole, e impiega un anno a completare il giro. Da solo questo non basterebbe a produrre le stagioni. Quello che le produce è che l'asse terrestre è INCLINATO: mentre la Terra percorre la sua orbita, per una metà dell'anno l'emisfero settentrionale è rivolto verso il Sole e riceve raggi più diretti e giornate più lunghe — ed è estate — mentre l'altro emisfero è nella condizione opposta. Sei mesi dopo la situazione si rovescia. È per questo, e non per la distanza dal Sole, che le stagioni dei due emisferi sono invertite."},
		{"titolo": "La Luna, e perché cambia forma",
		 "testo": "La Luna gira attorno alla Terra e non produce luce propria: la riflette dal Sole, che ne illumina sempre esattamente metà. Quello che cambia è la nostra posizione rispetto a quella metà illuminata: girandole attorno ne vediamo una parte diversa, e da questo nascono le fasi — luna nuova quando la faccia illuminata è rivolta dall'altra parte, luna piena quando la vediamo tutta, e i quarti in mezzo. Non c'è nessuna ombra della Terra in gioco nelle fasi normali: quella produce le eclissi, che sono un fenomeno diverso e molto più raro."}],
	"glossario": [
		{"voce": "rotazione", "spiega": "Il giro della Terra su se stessa in circa ventiquattro ore: causa il giorno e la notte."},
		{"voce": "rivoluzione", "spiega": "Il giro della Terra attorno al Sole in un anno."},
		{"voce": "asse inclinato", "spiega": "L'inclinazione dell'asse terrestre: è questa a produrre le stagioni, non la distanza dal Sole."},
		{"voce": "fasi lunari", "spiega": "Le forme con cui vediamo la Luna: cambia quale parte della metà illuminata ci è rivolta."}],
	"esempi": [
		{"prompt": "Che cosa causa l'alternarsi del giorno e della notte?", "answer": "La rotazione della Terra su sé stessa",
		 "explanation": "Il Sole illumina sempre metà del pianeta: girando, ogni punto passa a turno dalla parte illuminata a quella in ombra."},
		{"prompt": "Che cosa causa le stagioni?", "answer": "L'inclinazione dell'asse terrestre",
		 "explanation": "Non la distanza dal Sole: l'asse inclinato fa sì che un emisfero per volta riceva raggi più diretti e giornate più lunghe."}],
	"metodo": "Prima di spiegare un fenomeno del cielo, chiediti se a muoversi sia davvero quello che sembra muoversi. Quasi sempre il movimento è nostro, e riconoscerlo semplifica la spiegazione.",
	"errore": {"wrong": "Spiegare le stagioni con la distanza della Terra dal Sole.",
		"why": "Se fosse la distanza, le stagioni sarebbero uguali nei due emisferi: sono invertite proprio perché a decidere è l'inclinazione dell'asse."},
	"insegna": ["rotazione", "rivoluzione", "asse inclinato", "fasi lunari"]},

# ==================================================== TERRA UNIVERSO · alta
"scienze-terra-universo-alta": {
	"subject": "scienze", "topic": "terra-universo", "fasce": BANDA_ALTA,
	"titolo": "Dal sistema solare alla galassia",
	"apertura": "Uscendo dalla Terra le distanze diventano così grandi che i chilometri smettono di servire, e bisogna cambiare unità di misura.",
	"sezioni": [
		{"titolo": "Le scale, una dentro l'altra",
		 "testo": "Il sistema solare è il Sole con tutto ciò che gli gira attorno: otto pianeti, le loro lune, asteroidi e comete. Il Sole è una stella, cioè una sfera di gas che produce luce e calore con reazioni nel proprio nucleo, ed è una fra moltissime. Una galassia è un enorme insieme di stelle, gas e polveri tenuti insieme dalla gravità: la nostra si chiama Via Lattea e contiene centinaia di miliardi di stelle. E le galassie a loro volta sono innumerevoli. Ogni livello contiene il precedente, e il salto di dimensione fra un livello e l'altro è tale che disegnarli in scala sullo stesso foglio è impossibile."},
		{"titolo": "Misurare con la luce",
		 "testo": "A queste distanze il chilometro diventa inutilizzabile, come sarebbe il millimetro per misurare l'Italia. Si usa allora l'anno luce: la distanza che la luce percorre in un anno viaggiando a trecentomila chilometri al secondo. Da questa unità viene una conseguenza che vale la pena capire bene: guardare lontano nello spazio significa guardare indietro nel tempo. Se una stella dista mille anni luce, la sua luce è partita mille anni fa, e ciò che vediamo è come era allora — potrebbe non esistere più. Il cielo notturno non è una fotografia del presente ma un collage di epoche diverse."},
		{"titolo": "Perché di giorno non si vedono le stelle",
		 "testo": "Le stelle ci sono anche di giorno, e non si sono spente: semplicemente non si vedono. La ragione è che la luce del Sole viene diffusa in tutte le direzioni dall'atmosfera — è lo stesso fenomeno che rende azzurro il cielo — e quella luce diffusa è molto più intensa di quella debolissima che arriva dalle stelle. L'occhio non riesce a distinguere un segnale debole su uno sfondo luminoso. La prova è che dallo spazio, dove non c'è atmosfera a diffondere, le stelle si vedono anche con il Sole illuminato: non è il Sole a nasconderle, è l'aria."}],
	"glossario": [
		{"voce": "galassia", "spiega": "Un enorme insieme di stelle, gas e polveri tenuti insieme dalla gravità. La nostra è la Via Lattea."},
		{"voce": "stella", "spiega": "Una sfera di gas che produce luce e calore con reazioni nel proprio nucleo. Il Sole è una stella."},
		{"voce": "anno luce", "spiega": "La distanza percorsa dalla luce in un anno. Guardare lontano significa guardare indietro nel tempo."},
		{"voce": "diffusione", "spiega": "La luce sparsa in tutte le direzioni dall'atmosfera: rende azzurro il cielo e copre le stelle di giorno."}],
	"esempi": [
		{"prompt": "Che cos'è una galassia?", "answer": "Un enorme insieme di stelle, gas e polveri",
		 "explanation": "Tenuti insieme dalla gravità. La nostra, la Via Lattea, contiene centinaia di miliardi di stelle, e di galassie ce ne sono innumerevoli."},
		{"prompt": "Perché di giorno non vediamo le stelle?", "answer": "Perché la luce del Sole diffusa nell'aria le copre",
		 "explanation": "Le stelle ci sono: è la luce diffusa dall'atmosfera a essere troppo intensa perché l'occhio distingua un segnale così debole."}],
	"metodo": "Quando incontri una distanza astronomica, traducila in tempo di viaggio della luce. Un numero di chilometri con venti zeri non dice niente; «la sua luce è partita mille anni fa» dice tutto.",
	"errore": {"wrong": "Pensare che di giorno le stelle non ci siano.",
		"why": "Ci sono e brillano come di notte: è la luce solare diffusa dall'atmosfera a coprirle, e infatti dallo spazio si vedono anche di giorno."},
	"insegna": ["galassia", "stella", "anno luce", "diffusione"]},

# ========================================================= ECOSISTEMA · base
"scienze-ecosistema-base": {
	"subject": "scienze", "topic": "ecosistema", "fasce": BANDA_BASE,
	"titolo": "Chi mangia chi, e chi rimette tutto in circolo",
	"apertura": "Un bosco non è un elenco di piante e animali: è un insieme di rapporti, e i rapporti si possono disegnare.",
	"sezioni": [
		{"titolo": "Che cos'è un ecosistema",
		 "testo": "Un ecosistema è l'insieme dei viventi e dell'ambiente in cui stanno, considerati insieme perché si influenzano a vicenda. Comprende quindi sia la parte viva — piante, animali, funghi, batteri — sia quella non viva: il suolo, l'acqua, la luce, la temperatura. Un ecosistema può essere grande come una foresta o piccolo come uno stagno, e i suoi confini li sceglie chi lo studia in base a che cosa vuole capire. La parola importante è «insieme»: studiare una specie da sola dice molto poco, perché quasi tutto quello che le succede dipende da chi le sta attorno e da dove si trova."},
		{"titolo": "La catena alimentare, e i suoi tre ruoli",
		 "testo": "L'energia entra in un ecosistema in un punto solo: dalla luce del Sole, attraverso le piante. Le piante si fabbricano il nutrimento da sé con la fotosintesi, e per questo si chiamano PRODUTTORI. Chi mangia le piante e chi mangia chi le ha mangiate sono i consumatori, che si dividono a loro volta in erbivori e carnivori. Alla fine intervengono i decompositori — funghi e batteri — che trasformano i resti e i cadaveri in sostanze riutilizzabili dalle piante, chiudendo il cerchio. Senza decompositori il materiale si accumulerebbe e i produttori resterebbero a corto di ciò che serve loro."},
		{"titolo": "Perché una catena non basta: la rete",
		 "testo": "Una catena alimentare è una fila semplice: erba, cavalletta, rana, serpente. Nella realtà però quasi nessun animale mangia una cosa sola, e quasi nessuna specie è mangiata da un solo predatore. Mettendo insieme tutte le catene di un ambiente si ottiene una rete alimentare, cioè più catene collegate fra loro. La differenza non è di dettaglio: una rete regge la scomparsa di un anello molto meglio di una catena, perché chi mangiava quella specie può ripiegare su un'altra. È il motivo per cui gli ambienti con più specie sono più stabili di quelli poveri."}],
	"glossario": [
		{"voce": "ecosistema", "spiega": "L'insieme dei viventi e dell'ambiente in cui stanno, studiati insieme perché si influenzano."},
		{"voce": "produttori", "spiega": "Le piante, che si fabbricano il nutrimento con la fotosintesi. È da lì che l'energia entra."},
		{"voce": "decompositori", "spiega": "Funghi e batteri: trasformano i resti in sostanze riutilizzabili, chiudendo il cerchio."},
		{"voce": "rete alimentare", "spiega": "Più catene alimentari collegate fra loro. Regge la scomparsa di un anello meglio di una catena sola."}],
	"esempi": [
		{"prompt": "In una catena alimentare, chi sono i produttori?", "answer": "Le piante, che si fabbricano il nutrimento",
		 "explanation": "Sono il punto in cui l'energia del Sole entra nell'ecosistema: tutti gli altri, direttamente o indirettamente, vivono di quello che loro hanno costruito."},
		{"prompt": "Che ruolo hanno i decompositori?", "answer": "Trasformano i resti in sostanze riutilizzabili",
		 "explanation": "Chiudono il cerchio: senza di loro il materiale si accumulerebbe e le piante resterebbero senza le sostanze che prendono dal suolo."}],
	"metodo": "Per capire un ecosistema disegna le frecce di chi mangia chi, e poi cerca chi rimette in circolo. Quasi ogni domanda su un ambiente si risponde guardando quel disegno.",
	"errore": {"wrong": "Considerare i decompositori un dettaglio finale della catena.",
		"why": "Sono l'anello che la chiude in cerchio: senza di loro le sostanze non tornerebbero al suolo e i produttori si fermerebbero."},
	"insegna": ["ecosistema", "produttori", "consumatori", "decompositori", "rete alimentare"]},

# ========================================================= ECOSISTEMA · alta
"scienze-ecosistema-alta": {
	"subject": "scienze", "topic": "ecosistema", "fasce": BANDA_ALTA,
	"titolo": "L'energia che si perde a ogni passaggio",
	"apertura": "C'è una ragione numerica per cui i leoni sono pochi e le gazzelle molte, e non ha niente a che fare con la caccia.",
	"sezioni": [
		{"titolo": "Solo una piccola parte passa al livello successivo",
		 "testo": "Quando un erbivoro mangia una pianta, non tutta l'energia contenuta in quella pianta finisce nel suo corpo: gran parte viene consumata per vivere — respirare, muoversi, mantenere la temperatura — e se ne va come calore, e un'altra parte esce con gli scarti non digeriti. Di tutto quello che entra, solo una piccola frazione, attorno a un decimo, diventa nuovo corpo disponibile per chi lo mangerà. Lo stesso accade a ogni passaggio successivo. Da qui segue direttamente che in una catena alimentare i predatori sono molto meno numerosi delle prede: non ci sarebbe abbastanza energia per mantenerne di più."},
		{"titolo": "La piramide, e perché le catene sono corte",
		 "testo": "Disegnando i livelli uno sopra l'altro in proporzione all'energia disponibile si ottiene una piramide: larghissima alla base dei produttori, molto stretta in cima. La stessa aritmetica spiega un'altra cosa che sembra un caso: le catene alimentari sono quasi sempre corte, tre o quattro anelli, raramente cinque. Dopo quattro passaggi da un decimo l'energia rimasta è un decimillesimo di quella iniziale, e non basta più a mantenere una popolazione stabile. Non è una regola biologica arbitraria: è una conseguenza di quanto si perde a ogni salto."},
		{"titolo": "Convivenze: la simbiosi",
		 "testo": "Non tutti i rapporti fra specie sono «chi mangia chi». La simbiosi è una convivenza stretta fra due specie diverse, e ne esistono forme molto differenti. Nel mutualismo entrambe ci guadagnano: l'ape prende il nettare e il fiore viene impollinato. Nel commensalismo una guadagna e l'altra non ci perde niente. Nel parassitismo una guadagna a spese dell'altra, come la zecca. Riconoscere quale dei tre casi si ha davanti richiede una domanda sola, fatta due volte: che cosa ci guadagna il primo, e che cosa ci guadagna o ci perde il secondo."}],
	"glossario": [
		{"voce": "perdita di energia", "spiega": "A ogni passaggio della catena passa circa un decimo: il resto se ne va come calore e scarti."},
		{"voce": "piramide ecologica", "spiega": "I livelli disegnati in proporzione all'energia: larga alla base, strettissima in cima."},
		{"voce": "simbiosi", "spiega": "Una convivenza stretta fra due specie diverse: può avvantaggiare entrambe, una sola, o una a spese dell'altra."},
		{"voce": "mutualismo", "spiega": "La forma di simbiosi in cui entrambe le specie ci guadagnano, come l'ape e il fiore."}],
	"esempi": [
		{"prompt": "Perché in una catena alimentare i predatori sono meno numerosi delle prede?", "answer": "Perché a ogni passaggio si perde molta energia",
		 "explanation": "Solo circa un decimo di quello che un livello contiene diventa corpo per il livello successivo: il resto se ne va come calore e scarti."},
		{"prompt": "Che cos'è la simbiosi?", "answer": "Una convivenza stretta fra due specie diverse",
		 "explanation": "Può essere vantaggiosa per entrambe, indifferente per una, o dannosa per una: per distinguerle basta chiedersi che cosa ci guadagna ciascuna."}],
	"metodo": "Quando una domanda riguarda il numero degli individui di un livello, ragiona in energia e non in caccia. Un decimo per salto spiega sia le proporzioni sia perché le catene siano corte.",
	"errore": {"wrong": "Spiegare la scarsità dei predatori dicendo che sono difficili da nutrire perché cacciano male.",
		"why": "Il limite è a monte ed è energetico: a ogni passaggio della catena resta circa un decimo, e quel decimo non mantiene molti individui."},
	"insegna": ["perdita di energia", "piramide ecologica", "simbiosi", "mutualismo"]},

# ========================================================== AMBIENTE · base
"scienze-ambiente-base": {
	"subject": "scienze", "topic": "ambiente", "fasce": BANDA_BASE,
	"titolo": "Varietà, aria, e da dove prendiamo l'energia",
	"apertura": "Tre idee che tornano in quasi ogni discorso sull'ambiente, e che conviene avere chiare prima di sentirle nominare.",
	"sezioni": [
		{"titolo": "La biodiversità, e perché conta",
		 "testo": "La biodiversità è la varietà di specie viventi in un ambiente. Non è un valore estetico ma una proprietà che si può misurare, e da cui dipende quanto quell'ambiente è robusto. Il motivo è quello della rete alimentare: in un ambiente ricco di specie, chi mangiava una preda che scompare può ripiegare su un'altra, e il sistema assorbe il colpo. In un ambiente povero lo stesso colpo si propaga a tutti. Vale la pena aggiungere che quasi tutta la biodiversità è invisibile: insetti, funghi e batteri sono la stragrande maggioranza delle specie, e sono quelli di cui si parla di meno."},
		{"titolo": "Gli alberi e l'aria",
		 "testo": "Gli alberi sono importanti per l'aria che respiriamo perché assorbono anidride carbonica e liberano ossigeno. Lo fanno con la fotosintesi: prendono l'anidride carbonica dall'aria e l'acqua dal terreno, usano la luce del Sole per costruire con questi materiali il proprio nutrimento, e come scarto rilasciano ossigeno. È un doppio servizio che si riceve gratuitamente e che una foresta fa in continuazione. Va detto per precisione che anche le piante respirano, consumando ossigeno: il saldo però resta ampiamente in positivo, perché una pianta che cresce accumula carbonio nel proprio legno."},
		{"titolo": "Fonti rinnovabili e non",
		 "testo": "Una fonte di energia rinnovabile è una fonte che si rigenera in tempi brevi rispetto a quanto la usiamo: il vento, la luce del Sole, l'acqua che scorre, il calore della Terra. Una fonte non rinnovabile è quella che esiste in una quantità fissa e che, consumata, non torna: il petrolio, il carbone, il gas naturale, che si sono formati in milioni di anni. La differenza non sta nel fatto che una si esaurisca e l'altra no, ma nella VELOCITÀ con cui si rigenera rispetto a quella con cui la si consuma. Il vento soffia domani; il petrolio bruciato oggi non si rifà in tempi umani."}],
	"glossario": [
		{"voce": "biodiversità", "spiega": "La varietà di specie viventi in un ambiente. Più è alta, più l'ambiente regge i cambiamenti."},
		{"voce": "fonte rinnovabile", "spiega": "Una fonte che si rigenera in tempi brevi: vento, sole, acqua, calore della Terra."},
		{"voce": "fonte non rinnovabile", "spiega": "Petrolio, carbone, gas: formati in milioni di anni, non si rifanno in tempi umani."},
		{"voce": "anidride carbonica", "spiega": "Il gas che le piante assorbono per la fotosintesi e che la combustione libera."}],
	"esempi": [
		{"prompt": "Che cos'è la biodiversità?", "answer": "La varietà di specie viventi in un ambiente",
		 "explanation": "Non è solo bellezza: più specie ci sono, più la rete alimentare ha alternative, e più l'ambiente assorbe la scomparsa di un anello."},
		{"prompt": "Quale di queste è una fonte di energia rinnovabile?", "answer": "Il vento",
		 "explanation": "Si rigenera in tempi brevissimi rispetto a quanto lo usiamo, a differenza del petrolio o del carbone che hanno impiegato milioni di anni a formarsi."}],
	"metodo": "Per stabilire se una fonte sia rinnovabile non chiederti se finisce, ma se si rigenera più in fretta di quanto la consumiamo. È il confronto fra due velocità, non una proprietà assoluta.",
	"errore": {"wrong": "Dire che la biodiversità riguarda solo gli animali grandi e le piante.",
		"why": "La stragrande maggioranza delle specie è fatta di insetti, funghi e batteri: la varietà che conta di più per l'equilibrio è quella che non si vede."},
	"insegna": ["biodiversità", "fonte rinnovabile", "fonte non rinnovabile", "anidride carbonica"]},

# ========================================================== AMBIENTE · alta
"scienze-ambiente-alta": {
	"subject": "scienze", "topic": "ambiente", "fasce": BANDA_ALTA,
	"titolo": "Equilibri che si rompono, e tempi che non coincidono",
	"apertura": "Quasi tutti i problemi ambientali hanno la stessa forma: qualcosa che cambia molto più in fretta di quanto il sistema riesca a ricomporre.",
	"sezioni": [
		{"titolo": "Le specie chiave",
		 "testo": "Non tutte le specie pesano allo stesso modo dentro un ecosistema. Alcune, che si chiamano specie chiave, tengono in equilibrio molte altre, e la loro scomparsa può cambiare l'equilibrio di un ambiente intero. Un predatore al vertice, per esempio, tiene sotto controllo il numero degli erbivori; se sparisce, gli erbivori crescono, consumano troppa vegetazione, e il danno arriva fino al suolo e ai corsi d'acqua. È il motivo per cui gli effetti di un intervento sull'ambiente sono spesso indiretti e ritardati, e per cui è difficile prevederli guardando la sola specie su cui si interviene."},
		{"titolo": "La plastica, e la questione dei tempi",
		 "testo": "La plastica dispersa è un problema per il mare perché impiega secoli a degradarsi: nel frattempo non sparisce ma si frammenta in pezzi sempre più piccoli, fino alle microplastiche, che vengono ingerite dagli organismi e risalgono la catena alimentare fino ai grandi predatori — e ai nostri piatti. Il punto generale è il rapporto fra due tempi: quello con cui produciamo e disperdiamo, misurato in giorni, e quello con cui l'ambiente smaltisce, misurato in secoli. Ogni volta che queste due velocità non coincidono, il materiale si accumula, e l'accumulo è il problema."},
		{"titolo": "L'effetto serra, e che cosa lo ha cambiato",
		 "testo": "Alcuni gas dell'atmosfera — anidride carbonica, metano, vapore acqueo — trattengono parte del calore che la Terra irradia verso lo spazio. È l'effetto serra, ed è un fenomeno naturale e necessario: senza, la temperatura media del pianeta sarebbe sotto lo zero e la vita come la conosciamo non esisterebbe. Quello che è cambiato è la QUANTITÀ. Bruciando carbone, petrolio e gas si rimette nell'aria, in poche generazioni, il carbonio che si era accumulato sotto terra in milioni di anni, e la quantità di gas che trattiene calore è aumentata. Di nuovo, il problema non è il fenomeno: è la velocità."}],
	"glossario": [
		{"voce": "specie chiave", "spiega": "Una specie da cui dipende l'equilibrio di molte altre: la sua scomparsa cambia l'ambiente intero."},
		{"voce": "microplastiche", "spiega": "I frammenti in cui la plastica si spezza senza degradarsi. Risalgono la catena alimentare."},
		{"voce": "effetto serra", "spiega": "I gas che trattengono il calore irradiato dalla Terra. È naturale e necessario: è la quantità a essere cambiata."},
		{"voce": "scala dei tempi", "spiega": "Il confronto fra la velocità con cui qualcosa si produce e quella con cui si smaltisce."}],
	"esempi": [
		{"prompt": "Perché la plastica dispersa è un problema per il mare?", "answer": "Perché impiega secoli a degradarsi",
		 "explanation": "Nel frattempo si frammenta in microplastiche che gli organismi ingeriscono: la produciamo in giorni e l'ambiente la smaltisce in secoli."},
		{"prompt": "Che cosa succede a un ecosistema se sparisce una specie chiave?", "answer": "Può cambiare l'equilibrio di molte altre specie",
		 "explanation": "Gli effetti sono indiretti: tolto un predatore gli erbivori crescono, la vegetazione cala, e il danno arriva fino al suolo."}],
	"metodo": "Davanti a un problema ambientale confronta due tempi: quanto ci mettiamo noi e quanto ci mette l'ambiente. Quasi tutti i problemi stanno in quella differenza, non nel fenomeno in sé.",
	"errore": {"wrong": "Trattare l'effetto serra come un fenomeno artificiale da eliminare.",
		"why": "È naturale e necessario: senza di esso la temperatura media sarebbe sotto lo zero. Il problema è l'aumento rapido della quantità di gas che lo producono."},
	"insegna": ["specie chiave", "microplastiche", "effetto serra", "scala dei tempi"]},

# =========================================================== ENERGIA · base
"scienze-energia-base": {
	"subject": "scienze", "topic": "energia", "fasce": BANDA_BASE,
	"titolo": "Che cos'è l'energia, e in quante forme si presenta",
	"apertura": "L'energia non è una sostanza che si può mettere in una scatola: è la capacità di produrre un cambiamento, e si riconosce solo dai suoi effetti.",
	"sezioni": [
		{"titolo": "Due forme da cui partire",
		 "testo": "L'energia cinetica è l'energia che ha un corpo perché si muove: una palla che rotola, l'acqua di un fiume, l'aria del vento. Più è veloce e più è pesante, più ne ha. L'energia potenziale è invece l'energia che un corpo ha per la sua POSIZIONE: un sasso in cima a una scala ne possiede, anche se è fermo, perché lasciandolo cadere quella posizione si trasformerà in movimento. Sono le due forme più immediate da riconoscere, e stanno una di fronte all'altra: la potenziale è energia in attesa, la cinetica è energia in atto."},
		{"titolo": "Le altre forme, e come si riconoscono",
		 "testo": "Oltre a quelle due ci sono l'energia termica, che si manifesta come calore e agitazione delle particelle; quella luminosa, portata dalla luce; quella elettrica, portata dalle cariche che si spostano in un conduttore; e quella chimica, immagazzinata nei legami delle sostanze — nel cibo, nella benzina, in una pila. Ognuna si riconosce dall'effetto che produce, non dall'aspetto, perché l'energia non si vede mai direttamente: si vede che qualcosa si è scaldato, si è mosso, si è illuminato. Quello che si osserva è sempre un cambiamento, e l'energia è ciò che lo ha reso possibile."},
		{"titolo": "Le trasformazioni sono la norma",
		 "testo": "L'energia passa continuamente da una forma all'altra, e quasi ogni oggetto che usiamo è un trasformatore. Quando si accende una lampadina, l'energia elettrica diventa luce e calore: la parte che si voleva — la luce — e una parte che non si voleva ma che arriva comunque. Il cibo trasforma energia chimica in movimento e calore del corpo. Una pallina che cade trasforma potenziale in cinetica. Descrivere un oggetto dicendo che cosa trasforma in che cosa è quasi sempre il modo più utile di capirlo: dice a che cosa serve e dove va a finire ciò che gli si dà."}],
	"glossario": [
		{"voce": "energia cinetica", "spiega": "L'energia che ha un corpo perché si muove."},
		{"voce": "energia potenziale", "spiega": "L'energia che un corpo ha per la sua posizione: è energia in attesa."},
		{"voce": "energia chimica", "spiega": "Immagazzinata nei legami delle sostanze: nel cibo, nella benzina, in una pila."},
		{"voce": "trasformazione", "spiega": "Il passaggio dell'energia da una forma all'altra. È quello che fa ogni macchina."}],
	"esempi": [
		{"prompt": "Che cos'è l'energia cinetica?", "answer": "L'energia che ha un corpo perché si muove",
		 "explanation": "Dipende da quanto è veloce e da quanto è pesante: è l'energia in atto, di fronte a quella potenziale che è in attesa."},
		{"prompt": "Quando accendi una lampadina, l'energia elettrica diventa…", "answer": "Luce e calore",
		 "explanation": "La luce è quello che si voleva; il calore arriva comunque, ed è la parte che in quasi ogni trasformazione va persa."}],
	"metodo": "Davanti a un oggetto che funziona, descrivilo come «trasforma questa forma in quest'altra». È quasi sempre la frase che spiega meglio a che cosa serve e dove va a finire l'energia.",
	"errore": {"wrong": "Pensare che un corpo fermo non possa avere energia.",
		"why": "Un sasso in cima a una scala è fermo e ha energia potenziale per la sua posizione: basta lasciarlo andare perché diventi movimento."},
	"insegna": ["energia cinetica", "energia potenziale", "energia chimica", "trasformazione"]},

# =========================================================== ENERGIA · alta
"scienze-energia-alta": {
	"subject": "scienze", "topic": "energia", "fasce": BANDA_ALTA,
	"titolo": "Si conserva, e però si degrada",
	"apertura": "Due affermazioni che sembrano contraddirsi e non si contraddicono, e capire perché è il passaggio più importante di tutta la fisica elementare.",
	"sezioni": [
		{"titolo": "Il principio di conservazione",
		 "testo": "Il principio di conservazione dell'energia dice che l'energia non si crea né si distrugge: si trasforma. In un sistema chiuso la quantità totale resta la stessa, qualunque cosa avvenga al suo interno. È uno dei principi meglio verificati di tutta la scienza, e ha una conseguenza pratica immediata: quando in un fenomeno sembra che dell'energia sia sparita, non è sparita — è andata da qualche parte, e quasi sempre è diventata calore. Cercare dove è finita, invece di accettare che sia svanita, è l'abitudine che permette di capire quasi ogni macchina."},
		{"titolo": "Perché nessuna macchina funziona per sempre",
		 "testo": "Se l'energia si conserva, perché una macchina si ferma? La risposta è che la conservazione riguarda la QUANTITÀ, non l'utilizzabilità. A ogni trasformazione una parte dell'energia si disperde in calore — per attrito, per resistenza dell'aria, per riscaldamento dei componenti — e il calore disperso nell'ambiente è la forma meno riutilizzabile di tutte, perché è distribuita in modo uniforme e non c'è più nessuna differenza da sfruttare. La quantità totale non è cambiata, ma la parte utilizzabile sì. È il motivo per cui nessuna macchina può funzionare all'infinito da sola, e per cui le macchine a moto perpetuo sono impossibili, non soltanto difficili."},
		{"titolo": "Da dove viene tutta l'energia che usiamo",
		 "testo": "Quasi tutta l'energia che usiamo sulla Terra viene dal Sole, direttamente o indirettamente, e vale la pena seguire le catene. Il fotovoltaico è il Sole diretto. Il vento nasce dalle differenze di temperatura che il Sole produce. L'idroelettrico funziona perché il Sole evapora l'acqua che poi ricade in quota. Il cibo viene dalle piante, che usano la luce. E perfino carbone e petrolio sono resti di organismi che vivevano di luce solare milioni di anni fa: bruciarli significa liberare energia solare immagazzinata allora. Le poche eccezioni sono il nucleare, il geotermico e le maree."}],
	"glossario": [
		{"voce": "conservazione", "spiega": "L'energia totale non cambia: non si crea né si distrugge, si trasforma."},
		{"voce": "degradazione", "spiega": "A ogni trasformazione una parte diventa calore disperso, la forma meno riutilizzabile."},
		{"voce": "attrito", "spiega": "La resistenza fra superfici che si toccano: trasforma movimento in calore, e non si annulla mai del tutto."},
		{"voce": "moto perpetuo", "spiega": "Una macchina che funzioni da sola per sempre. È impossibile, non difficile: perderebbe comunque energia utilizzabile."}],
	"esempi": [
		{"prompt": "Che cosa dice il principio di conservazione dell'energia?", "answer": "L'energia non si crea né si distrugge, si trasforma",
		 "explanation": "La quantità totale resta la stessa: quando sembra sparita è andata da qualche parte, e quasi sempre è diventata calore."},
		{"prompt": "Perché nessuna macchina può funzionare all'infinito da sola?", "answer": "Perché parte dell'energia si disperde in calore",
		 "explanation": "La quantità si conserva ma non l'utilizzabilità: il calore sparso nell'ambiente non offre più nessuna differenza da sfruttare."}],
	"metodo": "Quando dell'energia sembra sparita, non accettarlo: cerca dove è finita. Nove volte su dieci è diventata calore, e trovarlo spiega il funzionamento della macchina.",
	"errore": {"wrong": "Dedurre dalla conservazione che una macchina potrebbe funzionare per sempre.",
		"why": "La conservazione riguarda la quantità, non l'utilizzabilità: a ogni passaggio una parte diventa calore disperso, che non è più sfruttabile."},
	"insegna": ["conservazione", "degradazione", "attrito", "moto perpetuo"]},

# ============================================================ METODO · base
"scienze-metodo-base": {
	"subject": "scienze", "topic": "metodo", "fasce": BANDA_BASE,
	"titolo": "Osservare, ipotizzare, provare",
	"apertura": "La scienza non è un elenco di cose sapute: è un modo di decidere quali cose meritino di essere credute. Il modo ha dei passi, e sono pochi.",
	"sezioni": [
		{"titolo": "Osservare non è interpretare",
		 "testo": "È la distinzione da cui dipende tutto il resto, e si perde con facilità. L'osservazione registra quello che accade: «la pianta sul davanzale è più alta di quella nell'angolo». L'interpretazione lo spiega: «è più alta perché ha ricevuto più luce». La prima si può controllare misurando; la seconda è una proposta, e potrebbe essere sbagliata anche se l'osservazione è giusta — magari le due piante sono state annaffiate diversamente. Tenerle separate quando si scrive un resoconto è una disciplina faticosa e ripaga subito, perché rende visibile quale parte del discorso è ancora da dimostrare."},
		{"titolo": "L'ipotesi",
		 "testo": "Un'ipotesi scientifica è una risposta possibile ancora da verificare. Non è un'opinione e non è una certezza: è una proposta formulata in modo che si possa metterla alla prova. Perché sia utile deve avere una caratteristica precisa: deve dire che cosa ci si aspetta di osservare se è vera, e soprattutto che cosa si osserverebbe se fosse FALSA. «Le piante crescono meglio con più luce» dice entrambe le cose, e si può quindi provare. Un'ipotesi che non dice che cosa la smentirebbe non si può né confermare né rifiutare, e per questo non serve a niente."},
		{"titolo": "L'esperimento",
		 "testo": "L'esperimento è il modo di mettere alla prova un'ipotesi costruendo apposta la situazione in cui si vedrà se è vera. Non è un'osservazione qualsiasi: è un'osservazione preparata, in cui si decide prima che cosa si cambia, che cosa si tiene fermo e che cosa si misura. Alla fine si confronta il risultato con quello che l'ipotesi aveva previsto. Se non corrisponde, l'ipotesi va corretta o abbandonata — e questo non è un fallimento dell'esperimento ma il suo scopo: un esperimento che non avrebbe potuto dare torto a nessuno non ha misurato niente."}],
	"glossario": [
		{"voce": "osservazione", "spiega": "Registra quello che accade. Si può controllare misurando."},
		{"voce": "interpretazione", "spiega": "Spiega quello che è stato osservato. È una proposta, e può essere sbagliata."},
		{"voce": "ipotesi", "spiega": "Una risposta possibile ancora da verificare, formulata in modo da poter essere smentita."},
		{"voce": "esperimento", "spiega": "Un'osservazione preparata apposta: si decide prima che cosa cambiare, tenere fermo e misurare."}],
	"esempi": [
		{"prompt": "Che cos'è un'ipotesi scientifica?", "answer": "Una risposta possibile ancora da verificare",
		 "explanation": "Per essere utile deve dire anche che cosa si osserverebbe se fosse falsa: senza quello non si può né confermare né rifiutare."},
		{"prompt": "Che differenza c'è fra osservare e interpretare?", "answer": "L'osservazione registra, l'interpretazione spiega",
		 "explanation": "La prima si controlla misurando; la seconda è una proposta che può essere sbagliata anche quando l'osservazione è esatta."}],
	"metodo": "Rileggendo un resoconto, separa le frasi in due colonne: quelle che dicono che cosa è stato visto e quelle che dicono perché. La seconda colonna è quella ancora da dimostrare.",
	"errore": {"wrong": "Scrivere «la pianta è cresciuta di più perché aveva più luce» come se fosse un'osservazione.",
		"why": "L'osservazione è solo che è cresciuta di più: il «perché» è un'interpretazione, e va verificata tenendo ferme tutte le altre condizioni."},
	"insegna": ["osservazione", "interpretazione", "ipotesi", "esperimento"]},

# ============================================================ METODO · alta
"scienze-metodo-alta": {
	"subject": "scienze", "topic": "metodo", "fasce": BANDA_ALTA,
	"titolo": "Come si fa un esperimento che dice davvero qualcosa",
	"apertura": "Fare un esperimento è facile. Farne uno da cui si possa concludere qualcosa richiede tre precauzioni, e sono sempre le stesse.",
	"sezioni": [
		{"titolo": "Una variabile per volta",
		 "testo": "Se in un esperimento si cambiano insieme la luce e la quantità d'acqua, e una pianta cresce di più, non si può sapere quale delle due l'ha fatta crescere — o se sia stata la combinazione. Per questo si cambia una sola variabile per volta, tenendo ferme tutte le altre: per sapere quale ha causato il risultato. È la precauzione più elementare e la più violata, perché nella realtà tenere ferme tutte le altre condizioni è faticoso e a volte impossibile. Quando non si riesce, la conclusione onesta non è «probabilmente è la luce»: è che quell'esperimento su quella domanda non decide."},
		{"titolo": "Il gruppo di controllo",
		 "testo": "Il gruppo di controllo serve a confrontare con ciò che accade senza l'intervento. Se si vuole sapere se un fertilizzante fa crescere le piante, non basta metterlo e vedere che crescono: le piante crescono anche da sole. Serve un secondo gruppo identico in tutto, tranne che non riceve il fertilizzante, e il confronto fra i due è l'unica cosa che dice qualcosa. Senza controllo si misura l'effetto dell'intervento sommato a tutto il resto, e non si riesce a separarli. È il motivo per cui in medicina esistono i gruppi che ricevono una sostanza inerte: senza, non si distingue il farmaco da ciò che sarebbe successo comunque."},
		{"titolo": "Ripetere, e accettare di poter avere torto",
		 "testo": "Un esperimento va ripetuto più volte perché un risultato singolo può essere un caso: una pianta può essere cresciuta di più per differenze individuali, e con un esemplare per gruppo non si distingue l'effetto dal caso. Ripetendo, le fluttuazioni si compensano e resta ciò che è sistematico. A questo si aggiunge la regola che vale sopra tutte: un'ipotesi che non si può smentire in nessun modo è inutile dal punto di vista scientifico. Non falsa — inutile: se qualunque risultato la conferma, allora nessun risultato la sta mettendo alla prova, e l'esperimento non sta misurando niente."}],
	"glossario": [
		{"voce": "variabile", "spiega": "Una condizione che può cambiare. Se ne cambia una per volta, o non si sa quale ha agito."},
		{"voce": "gruppo di controllo", "spiega": "Identico in tutto tranne l'intervento: serve a confrontare con ciò che sarebbe successo comunque."},
		{"voce": "ripetizione", "spiega": "Ripetere più volte perché un risultato singolo può essere un caso."},
		{"voce": "ipotesi non smentibile", "spiega": "Una che nessun risultato potrebbe contraddire: inutile, perché nessun esperimento la sta provando."}],
	"esempi": [
		{"prompt": "Perché in un esperimento si cambia una sola variabile per volta?", "answer": "Per sapere quale ha causato il risultato",
		 "explanation": "Cambiandone due insieme, un effetto osservato può venire dall'una, dall'altra o dalla combinazione, e non c'è modo di distinguerle."},
		{"prompt": "A che cosa serve il gruppo di controllo?", "answer": "A confrontare con ciò che accade senza intervento",
		 "explanation": "Senza di esso si misura l'intervento sommato a tutto il resto: le piante crescono anche da sole, e non si distinguono le due cose."}],
	"metodo": "Prima di credere al risultato di un esperimento fatti tre domande: che cosa è stato cambiato, con che cosa è stato confrontato, e quante volte è stato ripetuto. Se una delle tre non ha risposta, il risultato non decide.",
	"errore": {"wrong": "Concludere che un intervento funziona perché il gruppo trattato è migliorato.",
		"why": "Senza un gruppo di controllo non si sa che cosa sarebbe successo comunque: il miglioramento potrebbe non avere niente a che fare con l'intervento."},
	"insegna": ["variabile", "gruppo di controllo", "ripetizione", "ipotesi non smentibile"]},
}


# --- Come si consulta ---------------------------------------------------------

## Tutte le dispense di una materia, per id.
static func per_materia(subject: String) -> Array:
	var out: Array = []
	for id in DISPENSE.keys():
		if str((DISPENSE[id] as Dictionary).get("subject", "")) == subject:
			out.append(str(id))
	out.sort()
	return out

## Gli argomenti di una materia che hanno almeno una dispensa.
static func argomenti_coperti(subject: String) -> Array:
	var out: Array = []
	for id in DISPENSE.keys():
		var d: Dictionary = DISPENSE[id]
		if str(d.get("subject", "")) != subject:
			continue
		var topic := str(d.get("topic", ""))
		if not out.has(topic):
			out.append(topic)
	out.sort()
	return out

static func per_id(id: String) -> Dictionary:
	return DISPENSE.get(id, {})

## La dispensa che copre questa fascia di questo argomento, {} se non c'è.
static func per_argomento(subject: String, topic: String, fascia: int) -> Dictionary:
	for id in DISPENSE.keys():
		var d: Dictionary = DISPENSE[id]
		if str(d.get("subject", "")) != subject or str(d.get("topic", "")) != topic:
			continue
		var fasce: Array = d.get("fasce", [])
		if fasce.size() == 2 and fascia >= int(fasce[0]) and fascia <= int(fasce[1]):
			var copia := d.duplicate(true)
			copia["id"] = str(id)
			return copia
	return {}

## Tutte le dispense dell'argomento fino a questa fascia compresa, in ordine.
## Serve alla regola 4: una domanda può usare anche ciò che le bande precedenti
## hanno già introdotto.
static func fino_a_fascia(subject: String, topic: String, fascia: int) -> Array:
	var out: Array = []
	for id in DISPENSE.keys():
		var d: Dictionary = DISPENSE[id]
		if str(d.get("subject", "")) != subject or str(d.get("topic", "")) != topic:
			continue
		var fasce: Array = d.get("fasce", [])
		if fasce.size() == 2 and int(fasce[0]) <= fascia:
			var copia := d.duplicate(true)
			copia["id"] = str(id)
			out.append(copia)
	out.sort_custom(func(a, b): return int((a["fasce"] as Array)[0]) < int((b["fasce"] as Array)[0]))
	return out

## L'unione delle notazioni autorizzate fino a questa fascia.
static func vocabolario(subject: String, topic: String, fascia: int) -> Array:
	var out: Array = []
	for d_data in fino_a_fascia(subject, topic, fascia):
		var d: Dictionary = d_data
		for voce in d.get("insegna", []):
			if not out.has(str(voce)):
				out.append(str(voce))
	return out

## **La dispensa vestita da lezione.** `ExercisePlayer._show_teaching_overlay`
## sa disegnare una forma sola — quella di `KnowledgeCodex.mini_lesson` — e
## riscriverne una seconda avrebbe prodotto due schede da mantenere allineate.
## I campi in più (`documento`, `glossario`, `esempiExtra`) sono facoltativi:
## chi non li ha continua a disegnarsi come prima.
static func lezione(subject: String, topic: String, fascia: int) -> Dictionary:
	var d := per_argomento(subject, topic, fascia)
	if d.is_empty():
		return {}
	var esempi: Array = d.get("esempi", [])
	var primo: Dictionary = esempi[0] if esempi.size() > 0 else {}
	var extra: Array = []
	for indice in range(1, esempi.size()):
		extra.append(esempi[indice])
	# `explanation` regge `lezione_ha_sostanza`: è il testo della prima sezione,
	# cioè la cosa che il bambino legge davvero per prima.
	var sezioni: Array = d.get("sezioni", [])
	var prima_sezione := str((sezioni[0] as Dictionary).get("testo", "")) if sezioni.size() > 0 else ""
	return {
		"subject": subject,
		"topic": topic,
		"dispensaId": str(d.get("id", "")),
		"titolo": str(d.get("titolo", "")),
		"intro": str(d.get("apertura", "")),
		"explanation": prima_sezione,
		"documento": sezioni,
		"glossario": d.get("glossario", []),
		"workedExample": primo,
		"esempiExtra": extra,
		"strategy": str(d.get("metodo", "")),
		"watchOut": d.get("errore", {}),
	}

## **Questa dispensa insegna davvero questa risposta?**
##
## Vero se la risposta compare nel testo del documento, o se una delle `regole`
## dichiarate la descrive. È la traduzione di «solo dopo si può fare una domanda»
## in una condizione verificabile.
##
## **Sta qui e non dentro un audit perché la usano in due**, e devono usarne una
## sola: `dispense_audit` per bocciare un item che chiede quello che il suo
## documento non dice, e `tavole_riferimento_audit` per accettare una dispensa al
## posto di una tavola. Scritta due volte, prima o poi le due copie divergono — è
## il difetto ricorrente di questo progetto.
static func insegna_la_risposta(id: String, etichetta: String) -> bool:
	var d := per_id(id)
	if d.is_empty():
		return false
	var cercata := etichetta.strip_edges()
	if cercata == "":
		return false
	if testo_completo(d).to_lower().contains(cercata.to_lower()):
		return true
	for regola_data in d.get("regole", []):
		var re := RegEx.new()
		if re.compile(str(regola_data)) != OK:
			continue
		if re.search(cercata) != null:
			return true
	return false

## Tutto quello che il bambino legge nella scheda. Il confronto è su questo e non
## sulle sole sezioni, perché anche il glossario e gli esempi si leggono.
static func testo_completo(d: Dictionary) -> String:
	var pezzi: Array = [str(d.get("titolo", "")), str(d.get("apertura", "")),
		str(d.get("metodo", ""))]
	for sezione_data in d.get("sezioni", []):
		var sezione: Dictionary = sezione_data
		pezzi.append(str(sezione.get("titolo", "")))
		pezzi.append(str(sezione.get("testo", "")))
	for voce_data in d.get("glossario", []):
		var voce: Dictionary = voce_data
		pezzi.append(str(voce.get("voce", "")))
		pezzi.append(str(voce.get("spiega", "")))
	for esempio_data in d.get("esempi", []):
		var esempio: Dictionary = esempio_data
		pezzi.append(str(esempio.get("prompt", "")))
		pezzi.append(str(esempio.get("answer", "")))
		pezzi.append(str(esempio.get("explanation", "")))
	var errore: Dictionary = d.get("errore", {})
	pezzi.append(str(errore.get("wrong", "")))
	pezzi.append(str(errore.get("why", "")))
	return "\n".join(PackedStringArray(pezzi))

## Quanti caratteri di sole sezioni. È la misura della regola.
static func lunghezza_sezioni(d: Dictionary) -> int:
	var totale := 0
	for sezione_data in d.get("sezioni", []):
		var sezione: Dictionary = sezione_data
		totale += str(sezione.get("testo", "")).strip_edges().length()
	return totale

## I problemi di sostanza di una dispensa, elenco vuoto se non ne ha.
## Usato da `dispense_audit`, e scritto qui perché i minimi stiano accanto al
## contenuto che devono misurare.
static func problemi_di_sostanza(id: String, d: Dictionary) -> Array:
	var problemi: Array = []
	if str(d.get("titolo", "")).strip_edges() == "":
		problemi.append("%s: senza titolo" % id)
	var sezioni: Array = d.get("sezioni", [])
	if sezioni.size() < 2:
		problemi.append("%s: %d sezioni, ne servono almeno 2" % [id, sezioni.size()])
	for sezione_data in sezioni:
		var sezione: Dictionary = sezione_data
		if str(sezione.get("titolo", "")).strip_edges() == "":
			problemi.append("%s: una sezione senza sottotitolo" % id)
		if str(sezione.get("testo", "")).strip_edges() == "":
			problemi.append("%s: una sezione senza testo" % id)
	var lunghezza := lunghezza_sezioni(d)
	if lunghezza < MINIMO_SEZIONI:
		problemi.append("%s: %d caratteri di sezioni, il minimo e' %d" % [id, lunghezza, MINIMO_SEZIONI])
	var glossario: Array = d.get("glossario", [])
	if glossario.size() < MINIMO_GLOSSARIO:
		problemi.append("%s: %d voci di glossario, ne servono %d" % [id, glossario.size(), MINIMO_GLOSSARIO])
	for voce_data in glossario:
		var voce: Dictionary = voce_data
		if str(voce.get("voce", "")).strip_edges() == "" or str(voce.get("spiega", "")).strip_edges() == "":
			problemi.append("%s: una voce di glossario incompleta" % id)
	var esempi: Array = d.get("esempi", [])
	if esempi.size() < MINIMO_ESEMPI:
		problemi.append("%s: %d esempi svolti, ne servono %d" % [id, esempi.size(), MINIMO_ESEMPI])
	for esempio_data in esempi:
		var esempio: Dictionary = esempio_data
		if str(esempio.get("prompt", "")).strip_edges() == "":
			problemi.append("%s: un esempio senza domanda" % id)
		if str(esempio.get("answer", "")).strip_edges() == "":
			problemi.append("%s: un esempio senza risposta" % id)
		if str(esempio.get("explanation", "")).strip_edges() == "":
			problemi.append("%s: un esempio senza il suo perche'" % id)
	if str(d.get("metodo", "")).strip_edges().length() < MINIMO_METODO:
		problemi.append("%s: metodo troppo corto, il minimo e' %d caratteri" % [id, MINIMO_METODO])
	var errore: Dictionary = d.get("errore", {})
	if str(errore.get("wrong", "")).strip_edges() == "" or str(errore.get("why", "")).strip_edges() == "":
		problemi.append("%s: errore tipico incompleto" % id)
	var fasce: Array = d.get("fasce", [])
	if fasce.size() != 2 or int(fasce[0]) < 1 or int(fasce[1]) > 8 or int(fasce[0]) > int(fasce[1]):
		problemi.append("%s: fasce dichiarate male" % id)
	return problemi
