class_name GuardianDuel
extends RefCounted

## **IL DUELLO DELLE CIFRE.** (16 agosto 2026)
##
## Richiesta del committente: il combattimento contro i guardiani diventa un
## **minigioco di calcolo**, con difficoltà legata al livello del mondo, e
## **non deve somigliare al chiavistello dei forzieri** ([[LockChallenge]]).
## Deve essere un combattimento: divertente, stimolante, e deve insegnare a
## padroneggiare il calcolo veloce.
##
## Sostituisce il duello di riflessi che stava qui prima (una barra, un cursore,
## il momento giusto). Il motivo per cui se ne va: era l'unico momento del gioco
## in cui **la bravura non c'entrava con quello che il gioco insegna**. Un
## bambino che si allena a leggere e a contare non diventava più bravo a
## centrare un cursore; e un bambino con riflessi buoni scioglieva i guardiani
## senza avere imparato niente. Il grado di potenza allargava il varco, ma la
## competenza vera restava fuori dalla porta.
##
## ## La forma, e perché non è il chiavistello
##
## Il chiavistello chiede di **riconoscere**: c'è un numero, ci sono quattro
## operazioni, si tocca quella che lo fa. Una domanda, una risposta, si ricomincia.
##
## Il duello chiede di **costruire**. Il guardiano porta un **sigillo**, cioè un
## numero. Eli ha un **impulso**, cioè un altro numero, che parte piccolo. In mano
## ha delle **rune** — `+7`, `×4`, `−5`, `÷3` — e ogni runa è un colpo: applicata
## all'impulso lo cambia. Quando l'impulso vale **esattamente** il sigillo, il
## sigillo si spezza.
##
## La differenza non è cosmetica ed è tutto il punto pedagogico:
##
## - il chiavistello si gioca **in avanti** (calcolo e confronto: quanto fa 7×8);
## - il duello si gioca **all'indietro** (sono a 12, il sigillo è 36: cosa mi ci
##   porta?). È il pensiero inverso — la cosa che separa chi sa le tabelline da
##   chi sa *usarle*, e la sola scorciatoia vera verso il calcolo mentale rapido.
##
## E siccome i colpi sono **contati** (`colpi`, cioè `passi` più uno di riserva),
## la strada lunga non basta: bisogna scegliere la strada corta. Tocca a occhio
## nessuno: ogni runa consumata non torna.
##
## ## Perché è un combattimento e non un esercizio a tempo
##
## Tre cose, e tutte e tre erano assenti dal varco:
##
## 1. **Il guardiano si carica.** La barra della carica è il tempo, ma raccontato
##    dalla parte di chi ti sta davanti: quando è piena il guardiano colpisce e
##    Eli perde un punto di **tenuta**. Non è un cronometro sopra una domanda —
##    è un avversario che si muove.
## 2. **Ha più sigilli** (da due a quattro con il grado): il duello è fatto di
##    scambi, e ogni sigillo spezzato lo fa arretrare. La ripresa esiste.
## 3. **Accelera.** Ogni sigillo spezzato accorcia la carica del successivo
##    ([[ACCELERAZIONE]]). Un combattimento che finisce più teso di come è
##    cominciato è la sola forma di crescendo che costi una riga di codice.
##
## ## I guard-rail, che non cambiano
##
## Il duello sta davanti ai **frammenti**, cioè ai cosmetici: non c'è niente
## dietro un guardiano che serva a finire la campagna. È la condizione che rende
## lecita una prova a tempo in un gioco che si studia, ed è la stessa che valeva
## per il varco. Perdere costa quanto un morso e **non più**, altrimenti la scelta
## razionale sarebbe girare alla larga; abbandonare non costa niente; il guardiano
## resta dov'è e si può tornare più forti.
##
## I numeri di taratura stanno tutti qui e non nella scena: [[GuardianDuelPanel]]
## non ricalcola niente di suo, e `guardian_duel_audit` può quindi collaudare la
## difficoltà di tutti i mondi senza aprire una finestra.

## Le cinque fasce lungo i ventiquattro mondi.
##
## Cosa cresce, e in quest'ordine — lo stesso ordine del chiavistello, perché è
## l'ordine in cui un bambino di dieci anni riesce ad assorbire una difficoltà:
## prima i **numeri**, poi le **operazioni**, poi i **passi** della catena, e per
## ultimo il **tempo** che si accorcia.
##
## `passi` è la lunghezza della strada giusta: due colpi nei primi mondi, tre da
## metà campagna. Il salto da due a tre è il salto vero del duello — con due
## colpi si può ancora andare a tentativi, con tre no.
##
## `fattore` è l'intervallo dei moltiplicatori: comincia a ×2/×3 perché il
## raddoppio e il triplo sono le prime due cose che un bambino sa fare a mente, e
## arriva a ×12 quando le tabelline devono essere in dito.
const FASCE := [
	{
		"mondi": [1, 4], "nome": "primo sigillo",
		"massimo": 30, "operazioni": ["+", "*"], "fattore": [2, 3],
		"passi": 2, "mano": 4, "secondi": 12.0,
	},
	{
		"mondi": [5, 9], "nome": "sigillo doppio",
		"massimo": 60, "operazioni": ["+", "-", "*"], "fattore": [2, 5],
		"passi": 2, "mano": 5, "secondi": 11.0,
	},
	{
		"mondi": [10, 14], "nome": "sigillo dei Primi",
		"massimo": 100, "operazioni": ["+", "-", "*", "/"], "fattore": [2, 9],
		"passi": 3, "mano": 5, "secondi": 11.0,
	},
	{
		"mondi": [15, 19], "nome": "sigillo intrecciato",
		"massimo": 150, "operazioni": ["+", "-", "*", "/"], "fattore": [2, 12],
		"passi": 3, "mano": 6, "secondi": 10.0,
	},
	{
		"mondi": [20, 24], "nome": "sigillo del Cuore",
		"massimo": 240, "operazioni": ["+", "-", "*", "/"], "fattore": [2, 12],
		"passi": 3, "mano": 6, "secondi": 9.0,
	},
]

## **Il colpo di riserva.** I colpi concessi sono i passi della strada giusta più
## uno. Quell'uno è la cosa che rende sensate la sottrazione e la divisione: senza
## riserva, sbagliare un colpo chiuderebbe lo scambio e le rune che *tornano
## indietro* non servirebbero mai a niente. Con la riserva, chi supera il sigillo
## ha una via di rientro — e trovarla è esattamente il calcolo che si vuole
## insegnare.
const COLPO_DI_RISERVA := 1

## Il sigillo non scende mai sotto questo numero: un sigillo da 6 si spezza per
## caso, e un duello vinto per caso non insegna niente.
const SIGILLO_MINIMO := 12

## Quanto tempo dà ogni grado di potenza di Eli, e quanto ne toglie ogni grado
## del guardiano. Le stesse due leve del vecchio varco, sulla stessa promessa:
## **allenarsi deve servire**, e un guardiano più forte deve essere più duro.
const SECONDI_PER_GRADO := 0.55
const SECONDI_PER_TIER := 0.5
## Il tetto del vantaggio: oltre, il grado massimo regalerebbe il duello. Tre
## secondi e mezzo tengono il colpo più lento sotto gli otto secondi, che è la
## soglia oltre la quale il guardiano smette di essere un pericolo e il duello
## torna a essere un esercizio con un disegno intorno.
const SECONDI_BONUS_MASSIMO := 3.5
## Sotto questa soglia non si scende, qualunque cosa dicano fasce e gradi. Sei
## secondi e mezzo per tre colpi sono poco più di due secondi a colpo: sotto non
## si misura più il calcolo, si misura la velocità del dito — che a un bambino
## non si insegna.
const SECONDI_MINIMI := 6.5

## Quanto si accorcia la carica dopo ogni sigillo spezzato. Il combattimento
## accelera mentre lo si vince: è la sola forma di crescendo che non costa un
## sistema nuovo.
const ACCELERAZIONE := 0.9

## Quanto si allunga tutto con `reduced_motion`. Stessa scelta del chiavistello:
## chi ha bisogno di meno movimento non deve per questo perdere il premio.
const TEMPO_RIDOTTO := 1.4

static func fascia_per_mondo(world_level: int) -> Dictionary:
	var livello := clampi(world_level, 1, 24)
	for voce in FASCE:
		var fascia: Dictionary = voce
		var intervallo: Array = fascia["mondi"]
		if livello >= int(intervallo[0]) and livello <= int(intervallo[1]):
			return fascia.duplicate(true)
	return Dictionary(FASCE[0]).duplicate(true)

## **Quanti sigilli porta un guardiano.** Cresce col suo grado, non col mondo: è
## la stessa cifra che decide quanto fa male il morso, e un guardiano che sulla
## mappa è più minaccioso deve esserlo anche da vicino.
static func sigilli_richiesti(tier: int) -> int:
	return clampi(2 + floori(float(tier - 1) / 3.0), 2, 4)

## **Quanti colpi può incassare Eli**, e cresce solo con il suo grado di potenza.
## È la leva più generosa delle tre, di proposito: dare più tempo aiuta chi già
## calcola in fretta, dare più tenuta aiuta chi ci mette di più — e sono gli
## stessi bambini che non devono restare fuori da un premio estetico.
static func tenuta_di(grado: int) -> int:
	return clampi(2 + floori(float(grado) / 2.0), 2, 6)

static func secondi_di(fascia: Dictionary, tier: int, grado: int) -> float:
	var base := float(fascia.get("secondi", 10.0))
	return clampf(
		base + float(grado) * SECONDI_PER_GRADO - float(tier - 1) * SECONDI_PER_TIER,
		SECONDI_MINIMI, base + SECONDI_BONUS_MASSIMO)

## Tutte le regole di UN duello. La scena non ne ricalcola nessuna.
static func regole(world_level: int, tier: int, grado: int, movimento_ridotto := false) -> Dictionary:
	var fascia := fascia_per_mondo(world_level)
	var passi := int(fascia["passi"])
	var secondi := secondi_di(fascia, tier, grado)
	if movimento_ridotto:
		secondi *= TEMPO_RIDOTTO
	return {
		"nome": str(fascia["nome"]),
		"mondo": clampi(world_level, 1, 24),
		"tier": tier,
		"grado": grado,
		"sigilli": sigilli_richiesti(tier),
		"tenuta": tenuta_di(grado),
		"passi": passi,
		"colpi": passi + COLPO_DI_RISERVA,
		"mano": int(fascia["mano"]),
		"secondi": secondi,
		"massimo": int(fascia["massimo"]),
		"operazioni": Array(fascia["operazioni"]).duplicate(),
		"fattore": Array(fascia["fattore"]).duplicate(),
	}

## La carica del guardiano per il sigillo N-esimo: si accorcia a ogni sigillo
## spezzato, mai sotto il minimo assoluto.
static func secondi_del_sigillo(regole_duello: Dictionary, sigilli_rotti: int) -> float:
	var secondi := float(regole_duello.get("secondi", 10.0))
	return maxf(SECONDI_MINIMI, secondi * pow(ACCELERAZIONE, float(maxi(sigilli_rotti, 0))))

# --- Il colpo -----------------------------------------------------------------

## **Applica una runa all'impulso.** Torna il nuovo valore, o `-1` se la runa
## qui non entra.
##
## Due sole cose non entrano, ed entrambe sono informazione utile invece che
## divieto arbitrario:
##
## - una sottrazione che **spegnerebbe l'impulso**: sotto uno non si scende —
##   l'impulso è una carica, non un debito, e una strada che passa per zero è una
##   strada che riparte da capo;
## - una divisione che **non è esatta**: `÷4` su 30 non si può fare, e vederlo
##   scritto sulla runa spenta insegna la divisibilità meglio di qualunque
##   spiegazione. È l'unico posto del gioco in cui «non si può» significa
##   «guarda perché».
static func applica(valore: int, runa: Dictionary) -> int:
	var n := int(runa.get("n", 0))
	match str(runa.get("op", "+")):
		"+":
			return valore + n
		"-":
			return valore - n if valore - n >= 1 else -1
		"*":
			return valore * n
		"/":
			return int(float(valore) / float(n)) if n > 0 and valore % n == 0 else -1
	return -1

static func applicabile(valore: int, runa: Dictionary) -> bool:
	return applica(valore, runa) >= 0

static func testo_runa(runa: Dictionary) -> String:
	var n := int(runa.get("n", 0))
	match str(runa.get("op", "+")):
		"+":
			return "+%d" % n
		"-":
			return "−%d" % n
		"*":
			return "×%d" % n
		"/":
			return "÷%d" % n
	return "?"

static func runa(op: String, n: int) -> Dictionary:
	var costruita := {"op": op, "n": n}
	costruita["testo"] = testo_runa(costruita)
	return costruita

# --- La strada più corta ------------------------------------------------------

## **Il percorso più corto** dall'impulso al sigillo, come lista di indici di
## rune. Vuoto se non ce n'è nessuno entro `limite` colpi.
##
## Serve a tre cose diverse, e per questo sta qui e non nella scena: la
## generazione lo usa per **garantire** che ogni scambio sia risolvibile,
## il pannello per riconoscere il *colpo netto* (spezzare un sigillo nel numero
## minimo di colpi), e l'audit per giocare il duello davvero senza dita.
##
## Cerca in profondità su rune non ripetibili: con sei rune e quattro colpi sono
## al massimo 360 sequenze, cioè niente.
static func percorso_minimo(partenza: int, bersaglio: int, rune: Array, limite: int) -> Array:
	return _esplora(partenza, bersaglio, rune, {}, [], [], limite)

static func _esplora(valore: int, bersaglio: int, rune: Array, usate: Dictionary,
		pila: Array, migliore: Array, limite: int) -> Array:
	if valore == bersaglio and not pila.is_empty():
		if migliore.is_empty() or pila.size() < migliore.size():
			return pila.duplicate()
		return migliore
	if pila.size() >= limite:
		return migliore
	# Potatura: da qui in giù non si può più battere il migliore già trovato.
	if not migliore.is_empty() and pila.size() + 1 >= migliore.size():
		return migliore
	for indice in rune.size():
		if usate.has(indice):
			continue
		var prossimo := applica(valore, rune[indice])
		# Un impulso otto volte il sigillo non è una strada, è un vicolo: non
		# vale la pena esplorarlo e allunga la ricerca per niente.
		if prossimo < 0 or prossimo > bersaglio * 8:
			continue
		usate[indice] = true
		pila.append(indice)
		migliore = _esplora(prossimo, bersaglio, rune, usate, pila, migliore, limite)
		pila.pop_back()
		usate.erase(indice)
	return migliore

# --- Uno scambio --------------------------------------------------------------

## **Uno scambio**: il sigillo da fare, l'impulso di partenza e le rune in mano.
##
## `rng` arriva da fuori perché il duello sia ripetibile negli audit e perché
## riprovare lo stesso guardiano dia numeri nuovi: rifare a memoria un duello
## perso non deve essere possibile.
##
## Costruisce **prima la strada giusta** e poi il sigillo che ne esce: partire
## dal sigillo e cercare una strada avrebbe prodotto scambi irrisolvibili da
## scartare a caso. Così ogni scambio nasce con almeno una soluzione, per
## costruzione — e `percorso_minimo` verifica che non ne esista una più corta,
## perché uno scambio da tre colpi che se ne fa uno solo è una promessa rotta.
static func genera_scambio(rng: RandomNumberGenerator, regole_duello: Dictionary) -> Dictionary:
	var passi := int(regole_duello.get("passi", 2))
	var colpi := int(regole_duello.get("colpi", passi + COLPO_DI_RISERVA))
	for _tentativo in range(32):
		var scambio := _tenta_scambio(rng, regole_duello, passi, colpi)
		if not scambio.is_empty():
			return scambio
	return _scambio_di_ripiego(rng, regole_duello, passi, colpi)

static func _tenta_scambio(rng: RandomNumberGenerator, regole_duello: Dictionary,
		passi: int, colpi: int) -> Dictionary:
	var massimo := int(regole_duello.get("massimo", 30))
	var operazioni: Array = regole_duello.get("operazioni", ["+", "*"])
	var fattore: Array = regole_duello.get("fattore", [2, 3])
	var mano := int(regole_duello.get("mano", 4))

	var partenza := rng.randi_range(2, 9)
	var valore := partenza
	var strada: Array = []
	var viste: Dictionary = {}
	var ultima_op := ""
	for _passo in range(passi):
		var scelto := _passo_valido(rng, valore, operazioni, fattore, massimo, ultima_op, viste)
		if scelto.is_empty():
			return {}
		strada.append(scelto)
		viste["%s%d" % [str(scelto["op"]), int(scelto["n"])]] = true
		ultima_op = str(scelto["op"])
		valore = applica(valore, scelto)
	var bersaglio := valore
	if bersaglio < SIGILLO_MINIMO or bersaglio > massimo or bersaglio == partenza:
		return {}

	var rune: Array = strada.duplicate()
	for falsa in _esche(rng, mano - rune.size(), strada, partenza, bersaglio, operazioni, fattore, massimo):
		if rune.size() >= mano:
			break
		var chiave := "%s%d" % [str(falsa["op"]), int(falsa["n"])]
		if viste.has(chiave):
			continue
		viste[chiave] = true
		rune.append(falsa)
	if rune.size() < mano:
		return {}
	_mescola(rng, rune)

	# **Almeno due rune devono entrare subito.** Con sottrazioni e divisioni in
	# mano può capitare una mano quasi tutta spenta sull'impulso di partenza: un
	# bambino che apre lo scambio e non ha niente da toccare non sta pensando,
	# sta aspettando. Uno scambio così si butta e se ne genera un altro.
	var vive := 0
	for r in rune:
		if applicabile(partenza, r):
			vive += 1
	if vive < 2:
		return {}

	var minimo := percorso_minimo(partenza, bersaglio, rune, colpi)
	# Nessun colpo singolo deve spezzare un sigillo da due o tre passi: sarebbe
	# la stessa cosa del chiavistello, e per di più mascherata.
	if minimo.size() < 2 or minimo.size() > passi:
		return {}
	return {
		"partenza": partenza,
		"bersaglio": bersaglio,
		"rune": rune,
		"minimi": minimo.size(),
	}

## Un colpo che sta in piedi: non porta fuori scala, non azzera l'impulso, non
## ripete una runa già in mano — due pietre identiche sono una scelta finta — e
## non ripete l'operazione precedente quando può evitarlo, perché due addizioni
## di fila sono una addizione sola travestita e non insegnano il secondo passo.
static func _passo_valido(rng: RandomNumberGenerator, valore: int, operazioni: Array,
		fattore: Array, massimo: int, ultima_op: String, gia_viste: Dictionary) -> Dictionary:
	for _prova in range(14):
		var op := str(operazioni[rng.randi_range(0, operazioni.size() - 1)])
		if op == ultima_op and op == "+":
			continue
		var candidata := _costruisci_passo(rng, valore, op, fattore, massimo)
		if candidata.is_empty():
			continue
		if gia_viste.has("%s%d" % [str(candidata["op"]), int(candidata["n"])]):
			continue
		var esito := applica(valore, candidata)
		if esito >= 3 and esito <= massimo and esito != valore:
			return candidata
	return {}

static func _costruisci_passo(rng: RandomNumberGenerator, valore: int, op: String,
		fattore: Array, massimo: int) -> Dictionary:
	match op:
		"+":
			var spazio := massimo - valore
			if spazio < 2:
				return {}
			return runa("+", rng.randi_range(2, mini(spazio, 15)))
		"-":
			if valore < 9:
				return {}
			return runa("-", rng.randi_range(1, mini(valore - 3, 12)))
		"*":
			var tetto := mini(int(fattore[1]), int(float(massimo) / float(maxi(valore, 1))))
			if tetto < int(fattore[0]):
				return {}
			return runa("*", rng.randi_range(int(fattore[0]), tetto))
		"/":
			var divisori: Array = []
			for candidato in range(2, 10):
				if valore % candidato == 0 and int(float(valore) / float(candidato)) >= 3:
					divisori.append(candidato)
			if divisori.is_empty():
				return {}
			return runa("/", int(divisori[rng.randi_range(0, divisori.size() - 1)]))
	return {}

## **Le esche non sono rune a caso.**
##
## Una runa a caso si scarta a occhio e lascia il duello a due strade quando ne
## dichiara sei. Queste tre invece si scartano solo calcolando, ed è tutta la
## differenza fra un combattimento e un esercizio travestito:
##
## - **l'esca d'ampiezza**: il moltiplicatore grosso, quello che dalla partenza
##   sfonda il sigillo. Chi lo tocca impara l'ordine di grandezza addosso;
## - **la vicina**: una runa della strada giusta con il numero spostato di uno.
##   È l'errore di chi legge di fretta, e qui costa un colpo e non una vita;
## - **la runa che serve dopo**: una divisione o una sottrazione che all'inizio è
##   spenta e si accende a metà strada. Insegna a guardare la mano *prima* di
##   cominciare, che è il gesto del calcolo mentale rapido.
static func _esche(rng: RandomNumberGenerator, quante: int, strada: Array, partenza: int,
		bersaglio: int, operazioni: Array, fattore: Array, massimo: int) -> Array:
	var esche: Array = []
	if quante <= 0:
		return esche
	if operazioni.has("*"):
		var grosso := clampi(int(ceil(float(bersaglio) * 1.6 / float(maxi(partenza, 1)))),
			int(fattore[0]) + 1, maxi(int(fattore[1]), int(fattore[0]) + 1))
		esche.append(runa("*", grosso))
	for originale in strada:
		var scarto := 1 if rng.randf() < 0.5 else -1
		var n := int(originale["n"])
		var op := str(originale["op"])
		if op == "/":
			# Spostare un divisore produce quasi sempre una runa spenta: la
			# vicina di una divisione è una divisione per il numero accanto solo
			# se l'impulso la accetta, e qui non lo sappiamo ancora. Meglio una
			# sottrazione vicina, che è sempre leggibile.
			esche.append(runa("-", clampi(n + scarto, 1, 12)))
		else:
			var minimo_op := 2 if op == "*" else 1
			esche.append(runa(op, maxi(minimo_op, n + scarto)))
	while esche.size() < quante + 2:
		var op2 := str(operazioni[rng.randi_range(0, operazioni.size() - 1)])
		match op2:
			"*":
				esche.append(runa("*", rng.randi_range(int(fattore[0]), int(fattore[1]))))
			"/":
				esche.append(runa("/", rng.randi_range(2, 9)))
			"-":
				esche.append(runa("-", rng.randi_range(1, 12)))
			_:
				esche.append(runa("+", rng.randi_range(2, mini(maxi(massimo / 3, 3), 15))))
	_mescola(rng, esche)
	return esche

## Lo scambio che non può fallire: due addizioni e delle vicine. Si usa solo se
## trentadue tentativi non hanno prodotto niente — non è mai successo nelle
## misure dell'audit, ma un duello che si apre vuoto sarebbe l'unico difetto
## capace di bloccare un bambino davanti a un guardiano.
static func _scambio_di_ripiego(rng: RandomNumberGenerator, regole_duello: Dictionary,
		passi: int, colpi: int) -> Dictionary:
	var partenza := 4
	var primo := 6
	var secondo := 3
	var rune: Array = [runa("+", primo), runa("*", secondo)]
	var bersaglio := (partenza + primo) * secondo
	var mano := int(regole_duello.get("mano", 4))
	var extra := 1
	while rune.size() < mano:
		rune.append(runa("+", primo + extra))
		extra += 1
	_mescola(rng, rune)
	var minimo := percorso_minimo(partenza, bersaglio, rune, colpi)
	return {
		"partenza": partenza,
		"bersaglio": bersaglio,
		"rune": rune,
		"minimi": maxi(minimo.size(), passi),
	}

static func _mescola(rng: RandomNumberGenerator, lista: Array) -> void:
	for indice in range(lista.size() - 1, 0, -1):
		var scambio := rng.randi_range(0, indice)
		var tmp = lista[indice]
		lista[indice] = lista[scambio]
		lista[scambio] = tmp

# --- Quanto costa e quanto paga -----------------------------------------------

## Quanto costa perdere: **la stessa formula del morso**, perché provarci e
## sbagliare non può stare peggio che girare alla larga. Se costasse di più, la
## scelta razionale sarebbe non giocare — e allora il minigioco non lo
## giocherebbe nessuno.
static func costo_sconfitta(tier: int, grado: int) -> int:
	return maxi(0, tier - grado) * WorldEnemy.COSTO_PER_GRADO

## Il premio: frammenti, cioè cosmetici. Cresce col guardiano e non col grado di
## Eli — allenarsi rende il duello più facile, e sarebbe doppio anche pagarlo di più.
static func premio_frammenti(tier: int) -> int:
	return FragmentEconomy.premio_varco(tier)

## La riga che accompagna la vittoria. `netto` è vero se ogni sigillo è stato
## spezzato nel numero minimo di colpi: non vale frammenti in più — il premio non
## dipende da come si gioca — vale una riga diversa, che è l'unica ricompensa che
## non sposta l'economia.
static func riga_di_vittoria(netto: bool) -> String:
	return "Duello netto: ogni sigillo al colpo giusto." if netto \
		else "L'ultimo sigillo si spezza."

static func riga_di_sconfitta() -> String:
	return "Il guardiano regge. Resta lì dov'è: si torna quando vuoi."
