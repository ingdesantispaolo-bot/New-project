class_name VerbDuel
extends RefCounted

## **IL DUELLO DELLE VOCI.** (17 agosto 2026)
##
## Richiesta del committente: un secondo minigioco per i guardiani, di
## **italiano**, con i guardiani che sfidano a caso in italiano o matematica.
## Deve insegnare a **padroneggiare modi e tempi verbali veloci**, dev'essere un
## combattimento, e la difficoltà deve dipendere dal livello del mondo.
##
## ## La forma
##
## Il guardiano porta un **sigillo**: una casella del sistema verbale — modo,
## tempo, persona. Eli ha un **impulso**: il suo verbo, fermo su un'altra
## casella, scritto per esteso («canto»). In mano ha delle **rune**, e ognuna
## sposta *un asse solo*:
##
##     modo → congiuntivo     tempo → imperfetto     persona → voi
##
## Ogni runa è un colpo. Quando l'impulso si ferma esattamente sulla casella del
## sigillo, il sigillo si spezza. E mentre lo si fa, **il verbo si trasforma
## sotto gli occhi**: `canto → cantavo → cantavate → cantaste`.
##
## ## Perché questa forma, e non un quiz sui verbi
##
## Un quiz («che tempo è *cantavate*?» con quattro risposte) misura se lo sai già.
## Qui il bambino **attraversa** il paradigma: per andare da «canto» a «cantaste»
## deve decidere *quali tre coordinate* cambiare, e vedere la parola cambiare
## forma a ogni colpo. È la differenza fra guardare una tabella di coniugazione e
## camminarci dentro — e camminarci dentro è l'unico modo in cui quella tabella
## smette di essere una pagina da ricopiare.
##
## Le alternative scartate:
##
## - *scrivere la voce giusta*: la tastiera su tablet è lenta, e si finirebbe per
##   misurare l'ortografia invece del sistema dei verbi;
## - *scegliere la voce giusta fra quattro*: è il chiavistello dei forzieri con
##   le parole al posto dei numeri, ed è un quiz;
## - *trascinare le voci nella casella giusta*: bello, ma è un puzzle da tavolo —
##   niente in esso somiglia a un combattimento, e il tempo lo renderebbe solo
##   fastidioso.
##
## ## Le due cose che insegnano davvero, e sono gratis
##
## **1. Le rune spente.** Una runa che qui non entra è disegnata spenta:
## `tempo → passato remoto` è spenta quando sei nel congiuntivo, perché il
## congiuntivo **non ha** il passato remoto. E `modo → condizionale` è spenta
## quando sei sul futuro, perché il condizionale non ha il futuro. Il bambino
## impara la **forma del sistema** sbattendoci contro, che è l'unico modo in cui
## quella forma si impara.
##
## **2. L'ordine conta.** Per arrivare al congiuntivo passato partendo
## dall'indicativo futuro non puoi cambiare modo per primo — quella casella non
## esiste. Devi passare da un tempo che i due modi hanno in comune. È
## pianificazione vera, e nasce dalla grammatica invece che da una regola
## inventata dal gioco.
##
## ## Guard-rail
##
## Le regole del combattimento — sigilli, tenuta, carica, prezzo della sconfitta,
## premio — stanno in [[DuelRules]] e sono **le stesse del duello delle cifre**:
## nessuna delle due materie può essere la strada conveniente. Il duello chiude
## solo frammenti, cioè cosmetici. E la coniugazione viene da
## [[VerbConjugator]], che è collaudato voce per voce: un gioco che insegna una
## coniugazione sbagliata è peggio di un gioco che non insegna niente.

## Le cinque fasce lungo i ventiquattro mondi.
##
## Cresce in quest'ordine: prima i **tempi** dentro l'indicativo, poi i **modi**,
## poi la lunghezza della catena, poi i **verbi irregolari**, e per ultimo il
## modo in cui il bersaglio è scritto.
##
## `bersaglio` è la scelta più importante della progressione:
##
##   - `descrizione` il sigillo dice **a che cosa serve** la casella: «quello
##                  che durava, o si ripeteva · 2ª plur.». Si impara che cosa
##                  significa un tempo, che è quello che a scuola si chiede.
##                  Fino al 20 agosto qui c'era `etichetta`, che scriveva
##                  «INDICATIVO IMPERFETTO · voi» — le stesse parole delle
##                  rune, quindi un abbinamento invece di una domanda.
##   - `campione`   il sigillo mostra una **voce vera di un altro verbo**
##                  («aveste temuto») e tocca a te capire che casella sia. Si
##                  impara il **riconoscimento**, che è la competenza vera e che
##                  senza la mappa non si può nemmeno cominciare.
##
## Il passaggio da una all'altra è a metà campagna, e non prima: chiedere di
## riconoscere una casella a chi non sa ancora quali caselle esistono è il modo
## più rapido per far smettere di giocare.
const FASCE := [
	{
		"mondi": [1, 4], "nome": "prima voce",
		"modi": ["indicativo"],
		"tempi": ["presente", "imperfetto", "futuro semplice"],
		# **Cinque rune e non quattro** (21 agosto 2026): con due passi e quattro
		# rune restavano due sole esche, e chi toccava a caso ne azzeccava
		# troppe. Una quinta pietra non allunga la strada — restano due passi —
		# ma toglie alla fortuna un terzo delle sue probabilita'.
		"verbi": "are", "passi": 2, "mano": 5, "secondi": 13.0,
		"bersaglio": "descrizione",
	},
	{
		"mondi": [5, 9], "nome": "voce doppia",
		"modi": ["indicativo"],
		"tempi": ["presente", "imperfetto", "passato remoto", "futuro semplice", "passato prossimo"],
		"verbi": "regolari", "passi": 2, "mano": 5, "secondi": 12.0,
		"bersaglio": "descrizione",
	},
	{
		"mondi": [10, 14], "nome": "voce del congiuntivo",
		"modi": ["indicativo", "congiuntivo"],
		"tempi": ["presente", "imperfetto", "passato remoto", "futuro semplice", "passato prossimo"],
		"verbi": "tutti", "passi": 3, "mano": 5, "secondi": 12.0,
		"bersaglio": "campione",
	},
	{
		"mondi": [15, 19], "nome": "voce intrecciata",
		"modi": ["indicativo", "congiuntivo", "condizionale"],
		"tempi": [
			"presente", "imperfetto", "passato remoto", "futuro semplice",
			"passato prossimo", "trapassato prossimo", "passato",
		],
		"verbi": "tutti", "passi": 3, "mano": 6, "secondi": 11.0,
		"bersaglio": "campione",
	},
	{
		"mondi": [20, 24], "nome": "voce del Cuore",
		"modi": ["indicativo", "congiuntivo", "condizionale"],
		"tempi": [
			"presente", "imperfetto", "passato remoto", "futuro semplice",
			"passato prossimo", "trapassato prossimo", "futuro anteriore",
			"passato", "trapassato",
		],
		"verbi": "tutti", "passi": 3, "mano": 6, "secondi": 10.0,
		"bersaglio": "campione",
	},
]

## Quante rune, al massimo, si pretende che entrino all'apertura di uno
## scambio. Il minimo vero e' `mini(mano - 1, VIVE_MINIME)`: una mano da
## quattro non puo' averne cinque, e pretenderlo farebbe fallire la
## generazione invece di migliorarla.
const VIVE_MINIME := 4

const ASSI := ["modo", "tempo", "persona"]

static func fascia_per_mondo(world_level: int) -> Dictionary:
	var livello := clampi(world_level, 1, 24)
	for voce in FASCE:
		var fascia: Dictionary = voce
		var intervallo: Array = fascia["mondi"]
		if livello >= int(intervallo[0]) and livello <= int(intervallo[1]):
			return fascia.duplicate(true)
	return Dictionary(FASCE[0]).duplicate(true)

## **Le caselle vive di una fascia**: l'incrocio fra i modi e i tempi che la
## fascia concede e quelli che esistono davvero in italiano. È qui che il
## condizionale perde l'imperfetto e il congiuntivo perde il futuro — non per una
## scelta di gioco, ma perché quelle caselle non ci sono.
static func caselle_di(fascia: Dictionary) -> Array:
	var fuori: Array = []
	for modo in Array(fascia.get("modi", ["indicativo"])):
		for tempo in Array(fascia.get("tempi", ["presente"])):
			if VerbConjugator.casella_esiste(str(modo), str(tempo)):
				fuori.append({"modo": str(modo), "tempo": str(tempo)})
	return fuori

## I verbi che una fascia mette in campo. Le prime due fasce restano sui
## regolari, perché prima si impara il meccanismo e poi le eccezioni: incontrare
## «vado» mentre si sta ancora capendo che cos'è un imperfetto insegna solo che
## i verbi sono imprevedibili.
static func verbi_di(fascia: Dictionary) -> Array:
	var filtro := str(fascia.get("verbi", "tutti"))
	var fuori: Array = []
	for scheda in VerbConjugator.VERBI:
		var verbo: Dictionary = scheda
		match filtro:
			"are":
				if bool(verbo.get("regolare", false)) and str(verbo.get("gruppo", "")) == "are":
					fuori.append(verbo)
			"regolari":
				if bool(verbo.get("regolare", false)):
					fuori.append(verbo)
			_:
				fuori.append(verbo)
	return fuori

## Tutte le regole di UN duello di voci. La scena non ne ricalcola nessuna.
static func regole(world_level: int, tier: int, grado: int, movimento_ridotto := false) -> Dictionary:
	var fascia := fascia_per_mondo(world_level)
	var regole_duello := DuelRules.telaio(world_level, tier, grado,
		float(fascia["secondi"]), int(fascia["passi"]), movimento_ridotto)
	regole_duello["materia"] = DuelRules.VOCI
	regole_duello["nome"] = str(fascia["nome"])
	regole_duello["modi"] = Array(fascia["modi"]).duplicate()
	regole_duello["tempi"] = Array(fascia["tempi"]).duplicate()
	regole_duello["verbi"] = str(fascia["verbi"])
	regole_duello["mano"] = int(fascia["mano"])
	regole_duello["bersaglio"] = str(fascia["bersaglio"])
	return regole_duello

# --- Il colpo -----------------------------------------------------------------

static func runa(asse: String, valore) -> Dictionary:
	return {"asse": asse, "valore": valore, "testo": testo_runa(asse, valore)}

static func testo_runa(asse: String, valore) -> String:
	if asse == "persona":
		return str(VerbConjugator.PERSONE[clampi(int(valore), 0, 5)])
	return str(valore)

## **Applica una runa alla casella.** Torna la casella nuova, o vuoto se la runa
## qui non entra.
##
## Due sole cose non entrano, ed entrambe sono grammatica e non capriccio:
##
## - la casella che ne uscirebbe **non esiste** — `modo → condizionale` mentre sei
##   sul futuro semplice, perché il condizionale non ha il futuro; `tempo →
##   passato remoto` mentre sei nel congiuntivo, che il passato remoto non ce
##   l'ha;
## - la casella che ne uscirebbe **è quella dove sei già**: una runa che non
##   sposta niente non è un colpo, e spenderci un colpo sarebbe una beffa.
static func applica(cella: Dictionary, runa_scelta: Dictionary) -> Dictionary:
	var nuova := {
		"modo": str(cella.get("modo", "")),
		"tempo": str(cella.get("tempo", "")),
		"persona": int(cella.get("persona", 0)),
	}
	match str(runa_scelta.get("asse", "")):
		"modo":
			nuova["modo"] = str(runa_scelta.get("valore", ""))
		"tempo":
			nuova["tempo"] = str(runa_scelta.get("valore", ""))
		"persona":
			nuova["persona"] = clampi(int(runa_scelta.get("valore", 0)), 0, 5)
		_:
			return {}
	if not VerbConjugator.casella_esiste(str(nuova["modo"]), str(nuova["tempo"])):
		return {}
	if uguali(nuova, cella):
		return {}
	return nuova

static func applicabile(cella: Dictionary, runa_scelta: Dictionary) -> bool:
	return not applica(cella, runa_scelta).is_empty()

static func uguali(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("modo", "")) == str(b.get("modo", "")) \
		and str(a.get("tempo", "")) == str(b.get("tempo", "")) \
		and int(a.get("persona", -1)) == int(b.get("persona", -2))

static func assi_diversi(a: Dictionary, b: Dictionary) -> int:
	var quanti := 0
	if str(a.get("modo", "")) != str(b.get("modo", "")):
		quanti += 1
	if str(a.get("tempo", "")) != str(b.get("tempo", "")):
		quanti += 1
	if int(a.get("persona", -1)) != int(b.get("persona", -2)):
		quanti += 1
	return quanti

# --- La strada più corta ------------------------------------------------------

## **Il percorso più corto** dalla casella di partenza al sigillo, come lista di
## indici di rune. Vuoto se non ce n'è nessuno entro `limite` colpi.
##
## Non è un dettaglio tecnico ma la conseguenza diretta della grammatica: con le
## stesse tre rune, un ordine funziona e l'altro no. La ricerca esiste perché il
## gioco sappia sempre se una strada c'è — e perché non ne prometta mai una che
## non c'è.
static func percorso_minimo(partenza: Dictionary, bersaglio: Dictionary,
		rune: Array, limite: int) -> Array:
	return _esplora(partenza, bersaglio, rune, {}, [], [], limite)

static func _esplora(cella: Dictionary, bersaglio: Dictionary, rune: Array, usate: Dictionary,
		pila: Array, migliore: Array, limite: int) -> Array:
	if uguali(cella, bersaglio) and not pila.is_empty():
		if migliore.is_empty() or pila.size() < migliore.size():
			return pila.duplicate()
		return migliore
	if pila.size() >= limite:
		return migliore
	if not migliore.is_empty() and pila.size() + 1 >= migliore.size():
		return migliore
	for indice in rune.size():
		if usate.has(indice):
			continue
		var prossima := applica(cella, rune[indice])
		if prossima.is_empty():
			continue
		usate[indice] = true
		pila.append(indice)
		migliore = _esplora(prossima, bersaglio, rune, usate, pila, migliore, limite)
		pila.pop_back()
		usate.erase(indice)
	return migliore

# --- Uno scambio --------------------------------------------------------------

## **Uno scambio**: il verbo, la casella di partenza, il sigillo da raggiungere e
## le rune in mano.
##
## Costruisce e poi **verifica**: la strada più corta deve esistere ed essere
## lunga esattamente quanto la fascia promette. Il controllo non è pignoleria —
## con le caselle che non esistono, tre rune giuste possono benissimo non bastare
## (dall'indicativo futuro al condizionale passato non si arriva né cambiando
## prima il modo né cambiando prima il tempo), e uno scambio così lascerebbe un
## bambino a guardare la carica che scende senza capire perché.
static func genera_scambio(rng: RandomNumberGenerator, regole_duello: Dictionary) -> Dictionary:
	var passi := int(regole_duello.get("passi", 2))
	var colpi := int(regole_duello.get("colpi", passi + DuelRules.COLPO_DI_RISERVA))
	# **Duecento tentativi e non quarantotto.** (21 agosto 2026) Con il minimo
	# di rune giocabili alzato a quattro, quarantotto tentativi non bastavano
	# piu' nelle fasce alte e lo scambio cadeva sul ripiego — che e' lungo due
	# passi mentre la fascia ne promette tre. Se n'e' accorto l'audit.
	#
	# Provare di piu' non costa: un tentativo e' qualche operazione su
	# dizionari, e se ne fa uno per scambio, non uno per fotogramma.
	for _tentativo in range(200):
		var scambio := _tenta_scambio(rng, regole_duello, passi, colpi)
		if not scambio.is_empty():
			return scambio
	return _scambio_di_ripiego(rng, regole_duello, passi, colpi)

static func _tenta_scambio(rng: RandomNumberGenerator, regole_duello: Dictionary,
		passi: int, colpi: int) -> Dictionary:
	var fascia := fascia_per_mondo(int(regole_duello.get("mondo", 1)))
	var caselle := caselle_di(fascia)
	var verbi := verbi_di(fascia)
	var mano := int(regole_duello.get("mano", 4))
	if caselle.is_empty() or verbi.is_empty():
		return {}

	var verbo: Dictionary = verbi[rng.randi_range(0, verbi.size() - 1)]
	var da: Dictionary = Dictionary(caselle[rng.randi_range(0, caselle.size() - 1)]).duplicate()
	da["persona"] = rng.randi_range(0, 5)
	var a: Dictionary = Dictionary(caselle[rng.randi_range(0, caselle.size() - 1)]).duplicate()
	a["persona"] = rng.randi_range(0, 5)
	if assi_diversi(da, a) != passi:
		return {}

	# Le rune della strada: una per ogni asse che cambia.
	var rune: Array = []
	var viste: Dictionary = {}
	for asse in ASSI:
		var valore_da = da.get(asse)
		var valore_a = a.get(asse)
		if str(valore_da) == str(valore_a):
			continue
		var giusta := runa(asse, valore_a)
		rune.append(giusta)
		viste["%s|%s" % [asse, str(valore_a)]] = true

	for falsa in _esche(rng, fascia, caselle, da, a, mano - rune.size()):
		if rune.size() >= mano:
			break
		var chiave := "%s|%s" % [str(falsa["asse"]), str(falsa["valore"])]
		if viste.has(chiave):
			continue
		viste[chiave] = true
		rune.append(falsa)
	if rune.size() < mano:
		return {}
	_mescola(rng, rune)

	# **Quante rune devono entrare subito.** (rivisto il 21 agosto 2026)
	#
	# Erano due, e bastava a evitare uno scambio che si apre senza niente da
	# toccare. Ma `voci_valore_probe` ha misurato che entravano in media 3,2
	# rune su sei, e con cosi' poche scelte **la fortuna vinceva il 91% dei
	# duelli** al mondo 1 con Eli al grado massimo: bastava toccare a caso.
	#
	# Alzare il minimo non rende lo scambio piu' duro — la strada giusta e'
	# sempre la stessa, lunga gli stessi passi — ma **diluisce il caso**: chi
	# tocca a vanvera ha piu' modi di sbagliare, e chi ha letto il sigillo no.
	# E' l'unica leva che sta dentro le voci: sigilli, tenuta e colpo di
	# riserva stanno in [[DuelRules]] e li condivide il duello delle cifre.
	var vive := 0
	for r in rune:
		if applicabile(da, r):
			vive += 1
	if vive < mini(mano - 1, VIVE_MINIME):
		return {}

	var percorso := percorso_minimo(da, a, rune, colpi)
	if percorso.size() != passi:
		return {}

	var sigillo := _sigillo(rng, fascia, verbo, a, verbi)
	if sigillo.is_empty():
		return {}
	return {
		"verbo": verbo,
		"infinito": str(verbo.get("infinito", "")),
		"partenza": da,
		"bersaglio": a,
		"rune": rune,
		"minimi": percorso.size(),
		"sigillo": sigillo,
	}

## **Come è scritto il sigillo.**
##
## `descrizione`: che cosa fa quella casella — «quello che durava, o si
## ripeteva» — con la persona come la chiama la scuola. Nessuna delle sue parole
## sta su una runa: per trovarla bisogna sapere che cos'è un imperfetto.
##
## `campione`: una **voce vera di un altro verbo** nella stessa casella, e tocca
## a te capire quale sia. Con due condizioni severe, perché un bersaglio che
## mente è il difetto peggiore che un gioco di grammatica possa avere:
##
##   1. la voce deve individuare **una casella sola** dentro tutto il paradigma
##      del verbo campione. «cantaste» è passato remoto *e* congiuntivo
##      imperfetto; «canti» è tre cose. Nessuna delle due può fare da bersaglio;
##   2. il verbo campione dev'essere **diverso** da quello di Eli, altrimenti il
##      bersaglio sarebbe la risposta scritta in chiaro.
##
## Sotto la voce resta scritto l'infinito del campione: il duello misura modi e
## tempi, non il vocabolario, e far perdere per non aver riconosciuto «seppe»
## sarebbe misurare la cosa sbagliata.
static func _sigillo(rng: RandomNumberGenerator, fascia: Dictionary, verbo: Dictionary,
		bersaglio: Dictionary, verbi: Array) -> Dictionary:
	var modo := str(bersaglio.get("modo", ""))
	var tempo := str(bersaglio.get("tempo", ""))
	var persona := int(bersaglio.get("persona", 0))
	if str(fascia.get("bersaglio", "descrizione")) == "descrizione":
		# **Non piu' «INDICATIVO IMPERFETTO · voi».** (21 agosto 2026)
		# `voci_valore_probe` ha misurato che un giocatore che non sa niente
		# di verbi vinceva il 99% di questi scambi: bastava abbinare la parola
		# scritta sul sigillo alla parola scritta su una runa. Adesso il
		# sigillo dice **che cosa fa** quella casella, e la persona la dice
		# come la scuola. Nessuna parola del sigillo sta su una runa, quindi
		# l'abbinamento non ha piu' niente da abbinare.
		return {
			"tipo": "descrizione",
			"testo": VerbConjugator.descrizione(modo, tempo),
			"sotto": "persona: %s" % VerbConjugator.persona_grammaticale(persona),
		}
	var candidati: Array = []
	for scheda in verbi:
		var altro: Dictionary = scheda
		if str(altro.get("infinito", "")) == str(verbo.get("infinito", "")):
			continue
		candidati.append(altro)
	_mescola(rng, candidati)
	for scheda in candidati:
		var campione: Dictionary = scheda
		var forma := VerbConjugator.voce(campione, modo, tempo, persona)
		if forma.is_empty():
			continue
		if VerbConjugator.caselle_che_danno(campione, forma) != 1:
			continue
		return {
			"tipo": "campione",
			"testo": forma,
			"sotto": "verbo del guardiano: %s" % str(campione.get("infinito", "")),
			"campione": str(campione.get("infinito", "")),
		}
	return {}

## **Le esche non sono rune a caso.** Tre famiglie, ognuna con una lezione:
##
## - **la vicina**: un valore sbagliato sull'asse giusto (`tempo → passato
##   remoto` quando serve l'imperfetto). Costa un colpo, non una vita;
## - **la ferma**: una runa che sull'asse già a posto ti porterebbe via dal
##   sigillo. Insegna a controllare *cosa è già giusto* prima di colpire;
## - **la spenta**: una runa che dalla casella di partenza non entra proprio. È
##   la più preziosa delle tre — è lì che si impara che il congiuntivo non ha il
##   passato remoto, e lo si impara guardando invece che studiando.
static func _esche(rng: RandomNumberGenerator, fascia: Dictionary, caselle: Array,
		da: Dictionary, a: Dictionary, quante: int) -> Array:
	var esche: Array = []
	if quante <= 0:
		return esche
	var modi: Array = []
	var tempi: Array = []
	for voce in caselle:
		var cella: Dictionary = voce
		if not modi.has(str(cella["modo"])):
			modi.append(str(cella["modo"]))
		if not tempi.has(str(cella["tempo"])):
			tempi.append(str(cella["tempo"]))

	# La vicina, su ogni asse che cambia.
	for asse in ASSI:
		if str(da.get(asse)) == str(a.get(asse)):
			continue
		match asse:
			"modo":
				for valore in modi:
					if str(valore) != str(a["modo"]):
						esche.append(runa("modo", valore))
			"tempo":
				for valore in tempi:
					if str(valore) != str(a["tempo"]):
						esche.append(runa("tempo", valore))
			_:
				esche.append(runa("persona", (int(a["persona"]) + 1 + rng.randi_range(0, 3)) % 6))
	# La ferma, sugli assi già a posto.
	for asse in ASSI:
		if str(da.get(asse)) != str(a.get(asse)):
			continue
		match asse:
			"modo":
				for valore in modi:
					if str(valore) != str(a["modo"]):
						esche.append(runa("modo", valore))
			"tempo":
				for valore in tempi:
					if str(valore) != str(a["tempo"]):
						esche.append(runa("tempo", valore))
			_:
				esche.append(runa("persona", (int(a["persona"]) + 2 + rng.randi_range(0, 3)) % 6))
	# La spenta: una runa che dalla partenza non entra. Se non ce n'è nessuna
	# possibile la fascia è troppo piccola perché ne esistano, e va bene così.
	for valore in tempi:
		var prova := runa("tempo", valore)
		if not applicabile(da, prova):
			esche.append(prova)
	for valore in modi:
		var prova2 := runa("modo", valore)
		if not applicabile(da, prova2):
			esche.append(prova2)
	# E qualche persona in più per riempire.
	for indice in range(6):
		esche.append(runa("persona", indice))
	_mescola(rng, esche)
	return esche

## Lo scambio che non può fallire: due assi, due rune giuste e delle persone a
## riempire. Non è mai servito nelle misure dell'audit, ma un duello che si apre
## vuoto sarebbe l'unico difetto capace di bloccare un bambino davanti a un
## guardiano.
static func _scambio_di_ripiego(rng: RandomNumberGenerator, regole_duello: Dictionary,
		passi: int, colpi: int) -> Dictionary:
	var verbo := VerbConjugator.verbo_per_infinito("cantare")
	var da := {"modo": "indicativo", "tempo": "presente", "persona": 0}
	var a := {"modo": "indicativo", "tempo": "imperfetto", "persona": 4}
	var rune: Array = [runa("tempo", "imperfetto"), runa("persona", 4)]
	var extra := 0
	while rune.size() < int(regole_duello.get("mano", 4)) and extra < 6:
		if extra != 4 and extra != 0:
			rune.append(runa("persona", extra))
		extra += 1
	_mescola(rng, rune)
	return {
		"verbo": verbo,
		"infinito": "cantare",
		"partenza": da,
		"bersaglio": a,
		"rune": rune,
		"minimi": maxi(percorso_minimo(da, a, rune, colpi).size(), 2),
		"sigillo": {
			"tipo": "descrizione",
			"testo": VerbConjugator.descrizione("indicativo", "imperfetto"),
			"sotto": "persona: %s" % VerbConjugator.persona_grammaticale(4),
		},
	}

static func _mescola(rng: RandomNumberGenerator, lista: Array) -> void:
	for indice in range(lista.size() - 1, 0, -1):
		var scambio := rng.randi_range(0, indice)
		var tmp = lista[indice]
		lista[indice] = lista[scambio]
		lista[scambio] = tmp

## La voce di Eli in una casella: quello che il pannello scrive grande al centro.
static func voce_di(scambio: Dictionary, cella: Dictionary) -> String:
	return VerbConjugator.voce(Dictionary(scambio.get("verbo", {})),
		str(cella.get("modo", "")), str(cella.get("tempo", "")), int(cella.get("persona", 0)))
