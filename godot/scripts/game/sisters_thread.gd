class_name SistersThread
extends RefCounted

## Le undici sorelle: DATI. Una traccia per mondo, dal 13 al 23, e la voce di Eli
## sopra ognuna.
##
## **Il difetto che risolve.** Il mondo 24 dice «le undici prima di te le ho
## costruite io, e le ho perse tutte» e deve fare male. Ma fino a ieri il
## giocatore incontrava le undici **due volte**: come numero al mondo 12 («la tua
## è la dodici») e come confessione al 24. In mezzo, undici mondi in cui la cosa
## più importante della vita di Eli non esisteva. `MysteryCatalog` aveva già
## visto il problema e gli aveva dato una risposta piccola — un solo Sbiadito che
## ripete una frase di NORA. Questo file è la risposta grande: **le undici
## diventano undici persone, una per mondo, esattamente nell'intervallo vuoto.**
##
## **Perché una per mondo e in quest'ordine.** Ogni mondo insegna un modo di
## capire (`ApparatusConfig.SUBJECT_CYCLE`). Ogni sorella era bravissima in
## **uno solo** — quello del mondo dove sta la sua traccia — e si è fermata lì.
## Eli non è più brava di nessuna di loro in niente: è l'unica che li tiene tutti
## e dodici insieme, ed è letteralmente ciò che dice il beat finale («sei l'unica
## che tiene dodici modi di capire nella stessa testa»). La risposta alla domanda
## che una ragazzina si porta dietro per tutto il gioco — *sono unica o sono la
## prossima della fila?* — non è «sei speciale»: è **sei l'unica a cui non è
## stato detto niente**. Il talento non la distingue. Il metodo sì.
##
## Il dodicesimo modo, la **logica**, non ce l'ha nessuna sorella: era di Scala,
## che non è mai entrato nel suo apparato (§7 del documento trama). È il solo che
## Eli si ricava da sola, al mondo 24, ed è per questo che il finale si gioca lì.
##
## **La forma di ogni traccia, e perché è sempre la stessa.** All'inizio del
## quaderno ci sono domande ai margini, cancellature, tentativi. Verso la fine i
## margini sono puliti e i risultati sono tutti giusti. Nessun testo dice mai
## perché — il giocatore lo capisce al mondo 24 e gli torna addosso undici volte
## insieme. È lo stesso motivo per cui il gioco non dà mai la risposta: qui lo
## **mostra**, invece di dirlo.
##
## Guard-rail rispettati (§10 di `docs/TRAMA_E_MISTERO.md`): nessuna sorella è
## morta — si è **fermata**, ed è trattenuta e recuperabile (il Secondo Viaggio
## esiste per riprenderle); niente di tutto questo è obbligatorio per il gate;
## nessuna traccia incolpa Eli di niente.

## I nomi sono nomi di strumenti perché **i Primi si chiamavano come lo strumento
## che insegnavano** (§5.1: Abaco, Stilo, Telaio, Faro, Corda… e Scala). NORA ha
## imparato da loro e ha fatto come loro: dare il nome era la prima cosa che
## dava. Il nome di Eli non è uno strumento, e nel gioco nessuno lo commenta:
## si vede e basta.
const SORELLE := [
	{
		"numero": 1, "nome": "Lente", "world": 13, "materia": "matematica",
		"dove": "oggetto",
		"cosa": "Un quaderno di stime lasciato in una nicchia del deserto. Le prime pagine hanno più domande che numeri, ai margini. Verso la fine i margini sono puliti e i risultati sono tutti giusti. In copertina, una parola sola: Lente.",
		"eli": "Le prime pagine somigliano alle mie. Le ultime no: le ultime sono troppo in ordine.",
	},
	{
		"numero": 2, "nome": "Sestante", "world": 14, "materia": "italiano",
		"dove": "oggetto",
		"cosa": "In fondo a uno scaffale della Biblioteca, un elenco di parole copiato con una grafia che si fa più sicura riga dopo riga. In cima al foglio, di una mano più adulta: «per Sestante, che le voleva tutte».",
		"eli": "«Le voleva tutte.» Per un secondo ci ho scritto sopra il mio nome, e non mi è piaciuto come ci stava.",
	},
	{
		"numero": 3, "nome": "Livella", "world": 15, "materia": "coding",
		"dove": "oggetto",
		"cosa": "Nel registro dei guasti della Città Macchina, undici pagine firmate in piccolo: Livella. Le prime riparazioni hanno tre tentativi segnati e due cancellature. Le ultime hanno un tentativo solo, e nessuna cancellatura.",
		"eli": "Nessuna cancellatura. Io ne faccio dieci per volta. Non ho ancora deciso se è una cosa di cui vergognarmi.",
	},
	{
		"numero": 4, "nome": "Àncora", "world": 16, "materia": "inglese",
		"dove": "oggetto",
		"cosa": "Alla Frontiera, un quaderno bilingue a colonne affiancate. All'inizio, nella colonna di destra, molte parole hanno accanto un punto interrogativo. Dopo pagina venti i punti interrogativi finiscono e la traduzione diventa perfetta.",
		"eli": "Vorrei sapere cos'è successo a pagina venti. L'ho chiesto. NORA ha detto che il registro è incompleto.",
	},
	{
		"numero": 5, "nome": "Crogiolo", "world": 17, "materia": "fisica",
		"dove": "oggetto",
		"cosa": "Sul molo, una cassetta con i pesi di prova numerati a mano. Sul coperchio, graffiato: «Crogiolo — se non lo sollevi, hai scelto il punto sbagliato». Dentro, i pesi sono tutti al loro posto e non li tocca nessuno da molto.",
		"eli": "La leva l'aveva capita da sola. Si vede da come ha scritto la frase: se l'è detta, non gliel'ha detta nessuno.",
	},
	{
		"numero": 6, "nome": "Specchio", "world": 18, "materia": "musica",
		"dove": "oggetto",
		"cosa": "Nella navata, dentro un leggio, un foglio di esercizi di intonazione. Sopra ogni riga la stessa correzione, ripetuta con calma da un'altra mano. Sotto l'ultima riga, di mano di Specchio: «adesso lo sento anche senza di te».",
		"eli": "«Anche senza di te.» È la cosa più bella che ho letto qui dentro, e non riesco a smettere di rigirarmela.",
	},
	{
		"numero": 7, "nome": "Chiave", "world": 19, "materia": "latino",
		"dove": "dettaglio",
		"cosa": "Fra le radici incise, una tavoletta d'esercizio con le parole scomposte per origine. Nella metà bassa le scomposizioni sono tutte corrette e tutte della stessa lunghezza, come se qualcuno le dettasse. Il nome sul bordo è Chiave, e la mano non trema.",
		"eli": "«Come se qualcuno le dettasse.» L'ho pensato e ho alzato gli occhi verso la nave. Non so nemmeno io perché.",
	},
	{
		"numero": 8, "nome": "Setaccio", "world": 20, "materia": "elettronica",
		"dove": "oggetto",
		"cosa": "Un banco di prova sotto la tempesta: undici sensori montati e uno smontato a metà. Il quaderno accanto si ferma dentro una frase — «se il fulmine si annuncia, allora il sensore deve».",
		"eli": "Si è fermata a metà di una frase. Non a metà di un lavoro: a metà di una frase.",
	},
	{
		"numero": 9, "nome": "Compasso", "world": 21, "materia": "geografia",
		"dove": "oggetto",
		"cosa": "Nell'Atlante, una carta disegnata da zero e firmata Compasso. I contorni dei mondi sono esatti. Al centro, dove ogni altra carta lascia bianco, lei ha segnato un punto e ci ha scritto accanto: «qui non ci manda nessuno».",
		"eli": "Ha disegnato il punto al centro. Ci stava andando anche lei. E il punto al centro è quello dove la rotta non passa mai.",
	},
	{
		"numero": 10, "nome": "Pendolo", "world": 22, "materia": "scienze",
		"dove": "oggetto",
		"cosa": "In fondo alla biosfera, un diario di osservazioni con una riga al giorno per quattrocento giorni. Le prime righe sono ipotesi. Le ultime sono misure sole, senza ipotesi. L'ultima pagina ha la data e nient'altro.",
		"eli": "Ha smesso di fare ipotesi prima di smettere di scrivere. Non me lo tolgo dalla testa.",
	},
	{
		"numero": 11, "nome": "Squadra", "world": 23, "materia": "storia",
		"dove": "dettaglio",
		"cosa": "Nell'archivio, un fascicolo con le fonti allineate a due a due: quelle d'accordo e quelle no. L'inchiostro è di poche settimane fa. Sull'ultima riga, a matita: «Squadra — undicesima. Se leggi questo, non chiedere. Guarda».",
		"eli": "Poche settimane fa. E ha lasciato scritto di non chiedere — a me, che non sapevo nemmeno che esistesse.",
	},
]

## Il confronto del mondo 24. **Stesso formato di `FinaleCatalog.CATTEDRA.scena`**
## (`chi` + `dice`), perché è la stessa scena e la regia è la stessa: Codex.
##
## Cosa cambia rispetto a prima. Il beat 24 è una confessione di NORA, e finora
## Eli la riceveva **in silenzio** — in tutta la campagna non ha mai una riga. A
## dieci anni passa; a tredici no: chi gioca è nell'età in cui si smette di
## accettare che un adulto decida cosa puoi reggere, e un personaggio che tace
## mentre le viene detta quella cosa lì non è la protagonista, è il pubblico.
##
## Le regole che tengono la scena dentro i guard-rail:
##
## - **Eli è arrabbiata, e ha ragione.** Ma non chiede scuse: chiede una regola
##   nuova per il futuro. È la differenza fra un capriccio e una richiesta di
##   autonomia, ed è la cosa che a quell'età si sta imparando davvero;
## - **NORA non si giustifica e non implora.** Risponde «sì» e non tenta di
##   attenuarlo. Un personaggio che i bambini devono continuare ad amare dopo il
##   colpo 7 (§6.1.5) regge meglio la verità secca che una spiegazione lunga;
## - **la risposta alla domanda vera** — *ero l'ultimo tentativo?* — non è «sei
##   speciale». È che le altre le sono state date le risposte e a lei no. Merito
##   del metodo, non del talento: se fosse talento, il gioco starebbe dicendo a
##   chi lo gioca che o ce l'hai o non ce l'hai;
## - **finisce con Eli che va**, e va da sola. La scena consegna il nodo di
##   sintesi che il gioco aveva già lì: non aggiunge una prova, dà una ragione a
##   quella che c'è.
const CONFRONTO := [
	{"chi": "eli", "dice": [
		"Undici nomi.",
		"Li ho imparati uno alla volta, dai loro quaderni, mentre tu mi dicevi che il file non ce l'avevi.",
	]},
	{"chi": "nora", "dice": [
		"Non ce l'avevo. L'avevo cancellato io.",
		"Non è la stessa cosa, e te l'ho detto lo stesso.",
	]},
	{"chi": "eli", "dice": [
		"Sai qual è la parte che non mi passa? Non è avermele nascoste.",
		"È che hai deciso tu cosa potevo reggere. Per ventitré mondi.",
	]},
	{"chi": "nora", "dice": [
		"Sì.",
		"Non ho una risposta migliore di sì.",
	]},
	{"chi": "nora", "dice": [
		"Alle altre il nome gliel'ho scelto io. Era la prima cosa che davo, e non me ne sono mai accorta.",
		"Tu al mondo uno ti sei presentata da sola. Non ti ho corretta.",
	]},
	{"chi": "eli", "dice": [
		"Allora dimmene una vera adesso. Ero l'ultimo tentativo?",
	]},
	{"chi": "nora", "dice": [
		"No. Eri la prima fatta in un altro modo.",
		"Alle altre davo le risposte perché avevo paura di perderle. Le ho perse tutte così.",
		"A te non ho dato niente, e ti ho vista arrivare fin qui.",
	]},
	{"chi": "eli", "dice": [
		"Squadra mi ha lasciato scritto «non chiedere, guarda».",
		"Ci ho messo un mondo intero a capire che non ce l'aveva con me.",
	]},
	{"chi": "nora", "dice": [
		"Ce l'aveva con me.",
		"E c'era arrivata da sola. È la cosa che mi fa più male e più orgoglio insieme.",
	]},
	{"chi": "eli", "dice": [
		"Va bene.",
		"Da adesso però le cose difficili me le dici mentre succedono. Anche se ho paura. Soprattutto se ho paura.",
	]},
	{"chi": "nora", "dice": [
		"Va bene, sorella.",
		"La prima è questa: l'ultimo nodo non so risolverlo. Nessuno di noi dodici lo sa.",
		"Devi andarci tu.",
	]},
]

## --- API -------------------------------------------------------------------

## La sorella la cui traccia sta in questo mondo, o {} se il mondo non ne ha una.
static func sorella_for(world: int) -> Dictionary:
	for raw in SORELLE:
		var sorella: Dictionary = raw
		if int(sorella.get("world", 0)) == world:
			return sorella.duplicate(true)
	return {}

## Le tracce nella forma dei semi di `MysteryCatalog`: è così che diventano
## oggetti veri nel mondo, senza una seconda pipeline di spawn accanto a quella
## che c'è già. Il colpo che seminano è il settimo — sono la sua prova materiale.
static func semi() -> Array:
	var out: Array = []
	for raw in SORELLE:
		var sorella: Dictionary = raw
		out.append({
			"colpo": "undici-quaderni",
			"world": int(sorella["world"]),
			"dove": str(sorella["dove"]),
			"cosa": str(sorella["cosa"]),
			"eli": str(sorella["eli"]),
			"sorella": str(sorella["nome"]),
		})
	return out

## I mondi che ospitano una traccia, in ordine. Serve agli audit e a chi colloca.
static func mondi() -> Array:
	var out: Array = []
	for raw in SORELLE:
		out.append(int((raw as Dictionary)["world"]))
	out.sort()
	return out
