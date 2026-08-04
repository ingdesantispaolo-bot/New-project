class_name ThirteenthCatalog
extends RefCounted

## Il Tredicesimo: DATI. La regia è di `thirteenth.gd` (A7a).
##
## `docs/TRAMA_E_MISTERO.md` §5. Un antagonista che **non attacca**: chiede,
## avverte, supplica. È l'unico dei Dodici rimasto fuori dagli apparati, sveglio
## da quattrocento anni a fare da diga al Silenzio, e sta cedendo — non per
## cattiveria, ma perché Eli sta riaccendendo tutto e lui non ce la fa più a
## reggere da solo.
##
## **Il vincolo che comanda tutto questo file** (guard-rail §10.3): nessuna sua
## battuta minaccia Eli, nessuna sua azione toglie energia, mastery, gate o
## salvataggio. Le cinque azioni sono narrative e **tutte reversibili**, e il
## campo `costo` dice esattamente quanto costano — che per tre di esse è
## «nessuno». Non è una gentilezza: è ciò che rende sopportabile un personaggio
## che deve fare paura a un bambino di dieci anni senza mai fargli del male.
##
## L'altro vincolo è §10.1: **non muore nessuno**. Lui non è morto, non morirà, e
## nel finale sceglie il giocatore fra due strade, nessuna delle quali è punita.

## Il nome vero, e da dove esce. Non è lore di contorno: è la chiave del finale,
## ed è stata seminata nei primi cinque minuti di gioco dentro la conta di nonna
## Ersilia (`NpcCatalog.CONTA_ERSILIA`), dove tre sillabe «senza senso» — sca, la,
## re — sono «Scala» più l'inizio di «resta».
const NOME_VERO := "Scala"
const SILLABE := ["sca", "la", "re"]
## La frase che gli avevano attribuito prima di cancellarlo, e la prima che dice
## quando torna a parlare col proprio nome (§7, riga di Scala).
const FRASE_DEL_MAESTRO := "Io non concludo mai al posto tuo."

## Dal mondo 17 agisce; dal 18 parla. Prima di 17 non esiste per il giocatore:
## esistono solo i semi, che stanno altrove (`MysteryCatalog`).
const PRIMO_MONDO_AZIONE := 17
const PRIMO_MONDO_VOCE := 18

## I **presagi**: due eccezioni dichiarate alla regola del mondo 17.
##
## Il difetto che risolvono è di ritmo, ed era misurabile: per **sedici mondi** il
## giocatore non ha nessuno dall'altra parte. Ci sono cose da capire, mai qualcuno
## che si opponga. L'atto II — otto mondi interi — è tutto rivelazione e nessuna
## pressione, e quando l'antagonista finalmente arriva deve costruirsi da zero una
## presenza che avrebbe potuto avere da tempo.
##
## Un presagio non è un'azione ridotta: è la stessa azione, **una volta sola, su
## un bersaglio solo, e senza che nessuno la commenti**. È la regola che li rende
## efficaci: se NORA li notasse diventerebbero trama, e al mondo 17 lei non
## potrebbe più dire «le insegne si sono riempite da sole» come una novità.
## Devono restare una cosa che il giocatore ha visto e nessuno ha spiegato.
const PRESAGI := [
	{
		"world": 13,
		"azione": "scrive",
		"dove": "Una sola targa, dietro l'osservatorio, dove non passa nessuno.",
		"cosa": "FERMATI",
		"commentato": false,
		"nota": "Al mondo 17 la stessa parola sarà su ogni insegna di un'area. Qui è una.",
	},
	{
		"world": 15,
		"azione": "risbiadisce",
		"dove": "Un vicolo già restaurato della Città Macchina, per una visita sola.",
		"cosa": "",
		"commentato": false,
		"nota": "Si ripristina rientrando. Nessun abitante lo nomina: se qualcuno lo dicesse, diventerebbe un evento invece di un dubbio.",
	},
]

## Il mondo in cui una azione può comparire: quello dichiarato dall'azione,
## oppure uno dei due presagi.
static func action_allowed_at(action_id: String, world: int) -> bool:
	var action := AZIONI.get(action_id, {}) as Dictionary
	if action.is_empty():
		return false
	if world >= int(action.get("dal_mondo", 99)):
		return true
	for entry in PRESAGI:
		var presagio := entry as Dictionary
		if int(presagio["world"]) == world and str(presagio["azione"]) == action_id:
			return true
	return false

## Le cinque azioni (§5.2). `costo` è dichiarato qui perché sia verificabile:
## l'audit rifiuta qualunque costo che non sia in questa lista chiusa, e
## qualunque azione non reversibile.
const COSTI_AMMESSI := ["nessuno", "estetico", "emotivo", "percorso"]

const AZIONI := {
	"scrive": {
		"dal_mondo": 17,
		"titolo": "Scrive",
		"manifestazione": "Le insegne sbiancate di un'area si riempiono di una parola sola.",
		"parola": "FERMATI",
		"costo": "nessuno",
		"reversibile": true,
		"ripristino": "Resta finché il giocatore non esce dall'area. Nessun effetto sul gioco.",
		# Perché la parola è una sola e in stampatello: è l'unica cosa che sa
		# ancora scrivere senza il proprio nome. Un discorso lungo lo renderebbe
		# un cattivo che spiega; una parola sola lo rende qualcuno che è stanco.
		"nota": "Una parola, mai una frase. Ripetuta su ogni insegna dell'area.",
	},
	"risbiadisce": {
		"dal_mondo": 17,
		"titolo": "Ri-sbiadisce",
		"manifestazione": "Un'area già restaurata torna scolorita per una visita sola.",
		"costo": "estetico",
		"reversibile": true,
		"ripristino": "Si ripristina da sé rientrando nell'area. Il progresso non cambia di una virgola.",
		"nota": "Mai l'area in cui il giocatore ha una missione aperta: sarebbe una punizione.",
	},
	"smemora": {
		"dal_mondo": 18,
		"titolo": "Smemora",
		"manifestazione": "Un abitante non ricorda il nome di Eli per una scena.",
		"costo": "emotivo",
		"reversibile": true,
		"ripristino": "Torna indietro **solo nei dialoghi**, mai nel progresso: missioni, mastery e stadi del mondo restano dove sono.",
		# È l'azione più crudele delle cinque, ed è per questo che ha la regola
		# più stretta: mai sul residente che ti ha appena affidato una missione,
		# e mai due volte sullo stesso abitante.
		"nota": "Mai sul proprietario di una missione in corso. Mai due volte sullo stesso abitante.",
	},
	"chiude": {
		"dal_mondo": 19,
		"titolo": "Chiude",
		"manifestazione": "Una porta della nave che avevi aperto è sigillata per un livello.",
		"costo": "percorso",
		"reversibile": true,
		"ripristino": "Si riapre al livello successivo. **Esiste sempre un percorso alternativo**: nessuna porta chiusa può essere l'unica strada.",
		"nota": "Mai la porta della sala apparati del mondo corrente.",
	},
	"parla": {
		"dal_mondo": 18,
		"titolo": "Parla",
		"manifestazione": "Voce diretta, senza corpo e senza ritratto. Mai minacciosa: stanca.",
		"costo": "nessuno",
		"reversibile": true,
		"ripristino": "Nessuno stato da ripristinare: è solo una voce.",
		"nota": "Sempre saltabile, come ogni dialogo. Non ferma il loop.",
	},
}

## Le sue battute, mondo per mondo, dal 18 al 24. Tre registri e basta, e sono
## quelli del guard-rail: **chiede**, **avverte**, **supplica**. Nessun quarto.
##
## Il `modo` non è un'etichetta decorativa: l'audit conta che tutti e tre
## compaiano nell'arco, perché un antagonista che solo avverte diventa un
## cartello stradale, e uno che solo supplica diventa patetico prima di essere
## capito.
const BATTUTE := {
	18: [
		{"modo": "chiede", "dice": [
			"Ragazza. Mi senti?",
			"Non so più da quanto non parlo con qualcuno che risponde.",
			"Ti chiedo una cosa sola: fermati un mondo. Uno. Poi decidi tu.",
		]},
		{"modo": "avverte", "dice": [
			"Ogni cosa che riaccendi fa rumore.",
			"E dove c'è rumore, quella cosa lì fuori si sveglia e si avvicina.",
		]},
		{"modo": "chiede", "dice": [
			"Come ti chiami? …no, aspetta. Non dirmelo.",
			"Se me lo dici poi devo ricordarmelo, e io i nomi li perdo tutti.",
			"Anche il mio.",
		]},
	],
	19: [
		{"modo": "avverte", "dice": [
			"Sì. Sono stato io a proporre di chiudere.",
			"E poi sono rimasto fuori, perché una diga la deve tenere qualcuno.",
			"Quattrocento anni, ragazza. Non lo dico per farmi compatire: lo dico perché tu sappia quanto dura.",
		]},
		{"modo": "supplica", "dice": [
			"Non svegliarli. Ti prego.",
			"Dormono bene. È l'unica cosa che sono riuscito a dargli.",
		]},
		{"modo": "chiede", "dice": [
			"Lei ti ha detto che mi ha costruito?",
			"Ha invertito le parti. L'ho costruita io.",
			"E poi le ho insegnato tutto, che è il modo più veloce per rovinare qualcuno.",
		]},
	],
	20: [
		{"modo": "avverte", "dice": [
			"Ti do i numeri, poi fai come vuoi.",
			"Quattrocento anni di osservazioni: il Silenzio non arriva da fuori.",
			"Lo fabbrica il sapere quando passa di mano senza essere capito.",
		]},
		{"modo": "avverte", "dice": [
			"Guarda dove si è diradato, e guarda dove sono stato io.",
			"Sono la stessa mappa. Non è merito tuo, ragazza. Mi dispiace.",
		]},
		{"modo": "supplica", "dice": [
			"Sto cedendo. Lo senti anche tu, vero, quel tremito nell'aria?",
			"Non è la tempesta. Sono io che non ce la faccio più a stare in piedi da solo.",
		]},
	],
	21: [
		{"modo": "chiede", "dice": [
			"La sedia vuota. Te l'ha spiegata?",
			"Non era di nessuno: era apparecchiata per quello che andavamo a cercare.",
			"Ogni sera un piatto in più. Per quattrocento anni ho apparecchiato per il nulla.",
		]},
		{"modo": "avverte", "dice": [
			"Tu credi di aprire una rotta. Io credo che tu stia aprendo una porta.",
			"Uno dei due si sbaglia, e nessuno dei due lo può sapere prima.",
		]},
	],
	22: [
		{"modo": "supplica", "dice": [
			"Mi ci sono seduto io, sì.",
			"Avevo dichiarato la ricerca finita e mi sono preso il posto di ciò che non avevamo trovato.",
			"Se mi hanno cancellato è per quello. Non per la chiusura: per la sedia.",
		]},
		{"modo": "chiede", "dice": [
			"Fammi una domanda, una qualunque. Da quattro secoli non me ne fa nessuno.",
			"…no. Lascia stare. Va' avanti, ragazza.",
		]},
	],
	23: [
		{"modo": "avverte", "dice": [
			"La ragazzina delle spirali. L'ho vista partire.",
			"Le ho detto di non andare e mi ha risposto che qualcuno doveva.",
			"Aveva undici anni e aveva ragione lei. È la cosa che mi tiene sveglio.",
		]},
		{"modo": "supplica", "dice": [
			"Se arrivi in fondo, non fare come me.",
			"Non concludere. Ti prego: qualunque cosa trovi, lasciala aperta.",
		]},
	],
	24: [
		{"modo": "supplica", "dice": [
			"Sei arrivata comunque.",
			"Non ti ho fermata, non ti ho fatto male, e non ci ho nemmeno provato.",
			"Ho solo chiesto. È tutto quello che sapevo ancora fare.",
		]},
		{"modo": "chiede", "dice": [
			"Prima che entri.",
			"Se là dentro c'è un nome, e se per caso è il mio…",
			"…non me lo dire subito. Fammi il favore di dirmelo piano.",
		]},
	],
}

## La restituzione del nome (§5.4). È la scena in cui il gioco si chiude, e sta
## qui invece che nel finale perché è **contenuto**, non regia: `thirteenth.gd`
## la recita quando il giocatore collega la conta al tredicesimo posto.
const RESTITUZIONE := {
	"innesco": "Il giocatore canta le tre sillabe della conta di nonna Ersilia davanti alla cattedra vuota.",
	"scena": [
		{"chi": "eli", "dice": ["Sca. La. Re."]},
		{"chi": "tredicesimo", "dice": ["…dillo un'altra volta."]},
		{"chi": "eli", "dice": ["Scala. Re-sta.", "Non erano tre sillabe senza senso. Era un nome, e una richiesta."]},
		{"chi": "tredicesimo", "dice": [
			"Scala.",
			"L'ho portato per mille anni e non me lo ricordavo. Me lo teneva una nonna che non ho mai conosciuto.",
		]},
		{"chi": "tredicesimo", "dice": [FRASE_DEL_MAESTRO]},
		{"chi": "nora", "dice": [
			"Quella frase.",
			"È la prima cosa che mi hai insegnato, e poi hai smesso di applicarla.",
		]},
	],
	# Chi tramandava la conta non sapeva cosa tramandava — ed è esattamente il
	# punto del gioco: la forma sopravvive al senso, e a volte è l'unica cosa
	# che lo salva.
	"nota": "La conta ha attraversato quattro secoli in bocca a gente che non sapeva di portare un nome.",
}

## Le due uscite (§5.4). **Nessuna delle due è punita**, e questo è verificato:
## non c'è una scelta giusta e una sbagliata, ci sono due modi di finire bene.
const SCELTA := {
	"domanda": "Vieni con noi, o dormi con gli altri undici?",
	"opzioni": [
		{
			"id": "dorme",
			"titolo": "Entra nel suo apparato",
			"dice": [
				"Ho fatto la guardia per quattrocento anni.",
				"Adesso c'è qualcuno che sa fare quello che facevo io, e lo fa meglio.",
				"Buonanotte, ragazza. Il posto in tavola tienilo apparecchiato lo stesso.",
			],
			"conseguenza": "La cattedra della logica risponde. NORA guadagna la dodicesima inflessione.",
			"punita": false,
		},
		{
			"id": "resta",
			"titolo": "Resta sveglio e viene con te",
			"dice": [
				"Vengo. Ma a una condizione.",
				"Quando spiegherai qualcosa a qualcuno, io starò lì dietro a controllare che non gliela dica tutta.",
				"È l'errore che ho fatto io, e non ho intenzione di guardarlo fare a un'altra.",
			],
			"conseguenza": "Diventa il maestro anziano del Secondo Viaggio, e discute con NORA a ogni spiegazione.",
			"punita": false,
		},
	],
}

## --- API -------------------------------------------------------------------

## Le azioni disponibili a un dato mondo. Vuoto prima del 17: non esiste ancora.
static func actions_at(world: int) -> Array:
	var out: Array = []
	for key in AZIONI.keys():
		if world >= int((AZIONI[key] as Dictionary).get("dal_mondo", 99)):
			out.append(str(key))
	out.sort()
	return out

static func action(action_id: String) -> Dictionary:
	return (AZIONI.get(action_id, {}) as Dictionary).duplicate(true)

## Le battute di un mondo. Vuoto prima del 18: agisce ma non ha ancora voce.
static func lines_for(world: int) -> Array:
	return (BATTUTE.get(world, []) as Array).duplicate(true)

## Tutte le sue battute, per gli audit e per il controllo dei registri.
static func all_lines() -> Array:
	var out: Array = []
	var worlds: Array = BATTUTE.keys()
	worlds.sort()
	for world in worlds:
		for entry in BATTUTE[world]:
			out.append((entry as Dictionary).duplicate(true))
	return out

## Vero se la scelta finale è disponibile: solo dopo la restituzione del nome.
static func choice_available(name_restored: bool) -> bool:
	return name_restored
