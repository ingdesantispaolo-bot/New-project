class_name LockChallenge
extends RefCounted

## **Il chiavistello.** (14 agosto 2026)
##
## Richiesta del committente: i forzieri si aprono con un minigioco di **velocità
## di matematica**, con difficoltà che dipende dal mondo. È l'unico posto del
## gioco dove una prova di abilità può lecitamente chiudere qualcosa — la regola
## è già scritta in `outdoor_world` per il duello dei guardiani: *dentro c'è
## bellezza, non progressione*, quindi sbagliare non toglie niente a nessuno.
##
## **La forma, e perché questa.** Un bersaglio al centro, N tessere attorno,
## ognuna con una **operazione da svolgere**: si tocca quella che fa il bersaglio.
## Le alternative scartate e il motivo:
##
## - *«quanto fa 7×8?» con quattro risposte*: è un quiz, ed è già il formato di
##   mezzo gioco. Rifarlo qui in fretta lo renderebbe solo più stressante;
## - *scrivere il risultato*: la tastiera numerica è lenta su tablet, e la
##   velocità la deciderebbe il dito invece della testa;
## - *centrare un bersaglio che si muove*: premia lo schermo grande e la mano
##   ferma, ed è il motivo per cui in questo gioco non si mira mai.
##
## Toccare l'operazione **giusta fra tante** è invece calcolo mentale puro e
## parallelo: il bambino non risolve una domanda, ne scarta quattro. E il modo in
## cui si diventa veloci è esattamente quello che si vorrebbe insegnare — si
## impara a **stimare** e a scartare senza calcolare tutto (l'ordine di
## grandezza, la parità, l'ultima cifra).
##
## **Non è il duello dei guardiani, e la differenza è voluta** ([[GuardianDuel]]).
## Qui si *riconosce*: un numero, quattro operazioni, si tocca quella giusta e si
## ricomincia. Là si *costruisce*: si parte da un numero e lo si porta al sigillo
## incatenando colpi, che è il pensiero inverso. Due minigiochi di calcolo nello
## stesso gioco si giustificano solo se chiedono due gesti mentali diversi.
##
## **I distrattori sono errori tipici, non numeri a caso** (`_distrattori`):
## la somma al posto del prodotto, l'inversione della sottrazione, il vicino di
## uno. Un distrattore casuale si scarta a occhio; questi si scartano solo
## calcolando, ed è tutta la differenza fra un minigioco e un esercizio travestito.
##
## **Guard-rail.** Il chiavistello non tocca energia, padronanza, copertura,
## ripasso, gate né Lascito: apre una cassa e basta. Fallire non costa niente e
## non blocca niente — il forziere resta lì e si può riprovare subito con numeri
## nuovi. Nessun forziere è obbligatorio: se lo fosse, questa sarebbe la prima
## prova di velocità del gioco capace di fermare un bambino lento, e i bambini
## lenti in questo gioco non si fermano mai.

## Le cinque fasce di difficoltà lungo i ventiquattro mondi. Non seguono la
## materia del mondo — il chiavistello è sempre matematica, perché è l'unica
## competenza che regge il calcolo a tempo senza diventare una gara di lettura.
##
## Cosa cresce, e in quest'ordine: prima i **numeri**, poi le **operazioni**, poi
## il **tempo** che si accorcia. La rotazione delle tessere cresce per ultima ed è
## la sola cosa puramente estetica che diventa anche difficoltà: leggere mentre
## una cosa si muove costa attenzione, e a dieci anni quella è la risorsa scarsa.
const FASCE := [
	{
		"mondi": [1, 4], "nome": "primo chiavistello",
		"massimo": 20, "operazioni": ["+", "-"], "tessere": 4,
		"secondi": 6.5, "rotazione": 6.0, "doppia": false,
	},
	{
		"mondi": [5, 9], "nome": "chiavistello a due giri",
		"massimo": 50, "operazioni": ["+", "-", "*"], "tessere": 4,
		"secondi": 5.5, "rotazione": 9.0, "doppia": false,
	},
	{
		"mondi": [10, 14], "nome": "chiavistello dei Primi",
		"massimo": 100, "operazioni": ["+", "-", "*", "/"], "tessere": 5,
		"secondi": 4.8, "rotazione": 12.0, "doppia": false,
	},
	{
		"mondi": [15, 19], "nome": "chiavistello doppio",
		"massimo": 144, "operazioni": ["+", "-", "*", "/"], "tessere": 5,
		"secondi": 4.2, "rotazione": 15.0, "doppia": true,
	},
	{
		"mondi": [20, 24], "nome": "chiavistello del Cuore",
		"massimo": 200, "operazioni": ["+", "-", "*", "/"], "tessere": 6,
		"secondi": 3.8, "rotazione": 18.0, "doppia": true,
	},
]

## Quanti denti ha il chiavistello, per tipo di forziere. La fatica segue il
## valore: una cassa di cianfrusaglie non può chiedere quanto il forziere di
## qualcuno, o il bambino impara che aprire non vale la pena.
const DENTI := {
	TreasureCatalog.TIPO_RESTO: 2,
	TreasureCatalog.TIPO_CUSTODE: 2,
	TreasureCatalog.TIPO_LASCITO: 3,
}

## Quanto si allunga il tempo con `reduced_motion`, e di quanto rallenta la
## rotazione. Chi ha bisogno di meno movimento non deve per questo perdere il
## forziere: è la stessa scelta del duello dei guardiani ([[GuardianDuelPanel]]).
const TEMPO_RIDOTTO := 1.45

## Il tempo minimo di un dente, qualunque cosa dicano le fasce. Sotto i tre
## secondi non si sta più misurando il calcolo: si misura il tempo di reazione
## del dito, che è una cosa diversa e che a un bambino non si può insegnare.
const SECONDI_MINIMI := 3.0

static func fascia_per_mondo(world_level: int) -> Dictionary:
	var livello := clampi(world_level, 1, 24)
	for voce in FASCE:
		var fascia: Dictionary = voce
		var intervallo: Array = fascia["mondi"]
		if livello >= int(intervallo[0]) and livello <= int(intervallo[1]):
			return fascia.duplicate(true)
	return Dictionary(FASCE[0]).duplicate(true)

## Le regole complete di UNA sfida: quanti denti, quanto tempo, quante tessere.
static func regole(world_level: int, tipo_forziere: String, movimento_ridotto := false) -> Dictionary:
	var fascia := fascia_per_mondo(world_level)
	var secondi := float(fascia["secondi"])
	var rotazione := float(fascia["rotazione"])
	if movimento_ridotto:
		secondi *= TEMPO_RIDOTTO
		rotazione = 0.0
	return {
		"nome": str(fascia["nome"]),
		"denti": int(DENTI.get(tipo_forziere, 2)),
		"tessere": int(fascia["tessere"]),
		"secondi": maxf(SECONDI_MINIMI, secondi),
		"rotazione": rotazione,
		"massimo": int(fascia["massimo"]),
		"operazioni": Array(fascia["operazioni"]).duplicate(),
		"doppia": bool(fascia["doppia"]),
	}

## **Un dente.** Ritorna il bersaglio e le tessere, una sola delle quali lo vale.
##
## `rng` arriva da fuori perché la sfida sia ripetibile negli audit e perché
## riprovare lo stesso forziere dia numeri diversi: il seme cambia a ogni
## tentativo, e rifare a memoria un chiavistello fallito non deve essere possibile.
static func genera_dente(rng: RandomNumberGenerator, regole_sfida: Dictionary) -> Dictionary:
	var operazioni: Array = regole_sfida.get("operazioni", ["+"])
	var massimo := int(regole_sfida.get("massimo", 20))
	var quante := int(regole_sfida.get("tessere", 4))
	var doppia := bool(regole_sfida.get("doppia", false))

	var giusta := _espressione(rng, str(operazioni[rng.randi_range(0, operazioni.size() - 1)]), massimo, doppia)
	var bersaglio := int(giusta["valore"])

	var tessere: Array = [{"testo": str(giusta["testo"]), "valore": bersaglio, "giusta": true}]
	var valori_usati := {bersaglio: true}
	var tentativi := 0
	while tessere.size() < quante and tentativi < 80:
		tentativi += 1
		var falsa := _distrattore(rng, giusta, operazioni, massimo, doppia)
		var valore := int(falsa["valore"])
		# Due tessere che valgono lo stesso numero renderebbero il dente
		# ambiguo: una sarebbe giusta quanto l'altra e il bambino avrebbe
		# ragione a sentirsi imbrogliato.
		if valori_usati.has(valore) or valore < 0:
			continue
		valori_usati[valore] = true
		tessere.append({"testo": str(falsa["testo"]), "valore": valore, "giusta": false})

	# Se i distrattori non bastano (numeri piccoli, poche combinazioni), si
	# riempie con vicini semplici: meglio un dente più facile che un dente rotto.
	var scarto := 1
	while tessere.size() < quante:
		var valore := bersaglio + scarto
		if not valori_usati.has(valore) and valore >= 0:
			valori_usati[valore] = true
			tessere.append({"testo": "%d + 0" % valore, "valore": valore, "giusta": false})
		scarto += 1
		if scarto > massimo:
			break

	_mescola(rng, tessere)
	return {"bersaglio": bersaglio, "tessere": tessere}

## Un'espressione che vale qualcosa, e il suo testo. La divisione è sempre esatta
## e la sottrazione non scende mai sotto zero: un chiavistello non è il posto dove
## si scoprono i numeri negativi.
static func _espressione(rng: RandomNumberGenerator, operazione: String, massimo: int, doppia: bool) -> Dictionary:
	match operazione:
		"+":
			var a := rng.randi_range(2, maxi(3, massimo - 2))
			var b := rng.randi_range(2, maxi(3, massimo - a))
			if doppia and rng.randf() < 0.5:
				var c := rng.randi_range(2, 9)
				return {"testo": "%d + %d + %d" % [a, b, c], "valore": a + b + c}
			return {"testo": "%d + %d" % [a, b], "valore": a + b}
		"-":
			var grande := rng.randi_range(6, maxi(8, massimo))
			var piccolo := rng.randi_range(1, grande - 1)
			return {"testo": "%d − %d" % [grande, piccolo], "valore": grande - piccolo}
		"*":
			var limite := 12 if massimo > 60 else 9
			var x := rng.randi_range(2, limite)
			var y := rng.randi_range(2, maxi(2, mini(limite, int(float(massimo) / float(maxi(x, 1))))))
			if doppia and rng.randf() < 0.45:
				var piu := rng.randi_range(1, 9)
				return {"testo": "%d × %d + %d" % [x, y, piu], "valore": x * y + piu}
			return {"testo": "%d × %d" % [x, y], "valore": x * y}
		_:
			var divisore := rng.randi_range(2, 9)
			var quoziente := rng.randi_range(2, maxi(2, mini(12, int(float(massimo) / float(divisore)))))
			return {"testo": "%d ÷ %d" % [divisore * quoziente, divisore], "valore": quoziente}

## **I distrattori sono gli errori che si fanno davvero.**
##
## Ognuno di questi corrisponde a un modo tipico di sbagliare, e il bambino che
## ci casca impara qualcosa di preciso invece di sentirsi soltanto lento:
##
## - il **vicino**: la stessa operazione con un numero spostato di uno, che è
##   l'errore di chi conta sulle dita e parte da capo;
## - lo **scambio di operazione**: 3+4 al posto di 3×4, cioè l'errore di chi
##   legge il simbolo di sfuggita;
## - la **sottrazione girata**: 4−9 letto come 9−4, l'errore più comune di tutti;
## - l'**operazione qualunque**: serve a tenere il campo vario, e a non rendere i
##   distrattori riconoscibili per forma invece che per valore.
static func _distrattore(rng: RandomNumberGenerator, giusta: Dictionary,
		operazioni: Array, massimo: int, doppia: bool) -> Dictionary:
	var testo := str(giusta.get("testo", ""))
	var pezzi := testo.split(" ")
	var tiro := rng.randf()
	if pezzi.size() == 3 and tiro < 0.34:
		var a := int(pezzi[0])
		var segno := str(pezzi[1])
		var b := int(pezzi[2])
		var scarto := 1 if rng.randf() < 0.5 else -1
		# **La divisione si sposta sul dividendo, non sul divisore.** Spostare il
		# divisore produceva «22 ÷ 3», che non è una divisione esatta: il
		# troncamento la faceva valere 7 e il bambino che la calcolava per bene
		# trovava 7,33 e non la riconosceva più. Un distrattore che mente sul
		# proprio valore è l'unico difetto che un minigioco di calcolo non può
		# permettersi. Spostando il dividendo di un divisore, «22 ÷ 2» diventa
		# «24 ÷ 2»: resta esatta, resta vicina, e resta un errore plausibile.
		if segno == "÷":
			return _valuta("%d ÷ %d" % [maxi(b * 2, a + scarto * b), b])
		var nuovo_b := maxi(1, b + scarto)
		return _valuta("%d %s %d" % [a, segno, nuovo_b])
	if pezzi.size() == 3 and tiro < 0.62:
		var a2 := int(pezzi[0])
		var b2 := int(pezzi[2])
		var segno2 := str(pezzi[1])
		var alternativo := "+" if segno2 == "×" else "×"
		if segno2 == "−":
			# La sottrazione girata: stessi numeri, ordine invertito.
			return _valuta("%d − %d" % [maxi(a2, b2), mini(a2, b2)]) if a2 < b2 \
				else _valuta("%d + %d" % [a2, b2])
		return _valuta("%d %s %d" % [a2, alternativo, b2])
	# **Il quarto caso, e perché non è un'espressione a caso.** Misurato dall'audit
	# alla prima stesura: con un'operazione qualunque solo il 42% dei distrattori
	# finiva vicino al bersaglio, e gli altri si scartavano a occhio — un dente
	# dove tre tessere su quattro si buttano senza calcolare non è calcolo veloce,
	# è fortuna veloce. Adesso il valore si sceglie **prima** (un vicino del
	# bersaglio) e l'espressione si costruisce per farlo.
	var bersaglio := int(giusta.get("valore", 0))
	var raggio := maxi(3, int(float(bersaglio) * 0.18))
	var scarto := rng.randi_range(1, raggio) * (1 if rng.randf() < 0.5 else -1)
	var voluto := maxi(1, bersaglio + scarto)
	if voluto == bersaglio:
		voluto += 1
	return _espressione_per_valore(rng, voluto, operazioni, massimo)

## Un'espressione che vale ESATTAMENTE `valore`. Serve ai distrattori vicini: il
## numero lo decide chi chiama, la forma la decide il caso.
##
## Il prodotto si usa solo quando il valore ha un divisore comodo — costringere
## una moltiplicazione su un numero primo produrrebbe «1 × 47», che si legge come
## un trucco e insegna a riconoscere il distrattore invece del numero.
static func _espressione_per_valore(rng: RandomNumberGenerator, valore: int,
		operazioni: Array, massimo: int) -> Dictionary:
	var tiro := rng.randf()
	if operazioni.has("*") and tiro < 0.34:
		var divisori: Array = []
		for candidato in range(2, mini(13, valore)):
			if valore % candidato == 0 and int(float(valore) / float(candidato)) <= 12:
				divisori.append(candidato)
		if not divisori.is_empty():
			var d := int(divisori[rng.randi_range(0, divisori.size() - 1)])
			return {"testo": "%d × %d" % [d, int(float(valore) / float(d))], "valore": valore}
	# La soglia è bassa apposta: con 0,67 le sottrazioni diventavano tre tessere su
	# quattro nei primi mondi, dove le operazioni disponibili sono solo due. Un
	# quadrante tutto uguale si legge peggio e insegna meno — la forma dell'operazione
	# è essa stessa un'informazione da riconoscere in fretta.
	if operazioni.has("-") and tiro < 0.55:
		var aggiunta := rng.randi_range(1, maxi(2, mini(massimo - valore, 12)))
		return {"testo": "%d − %d" % [valore + aggiunta, aggiunta], "valore": valore}
	var a := rng.randi_range(1, maxi(1, valore - 1))
	return {"testo": "%d + %d" % [a, valore - a], "valore": valore}

## Rilegge un testo di espressione e ne calcola il valore. Serve ai distrattori
## costruiti manipolando il testo della tessera giusta: il valore deve venire da
## quello che il bambino LEGGE, non da un conto parallelo che potrebbe divergere.
static func _valuta(testo: String) -> Dictionary:
	var pezzi := testo.split(" ")
	if pezzi.size() < 3:
		return {"testo": testo, "valore": -1}
	var valore := int(pezzi[0])
	var indice := 1
	while indice + 1 < pezzi.size():
		var segno := str(pezzi[indice])
		var operando := int(pezzi[indice + 1])
		match segno:
			"+": valore += operando
			"−": valore -= operando
			"×": valore *= operando
			"÷": valore = int(float(valore) / float(maxi(operando, 1)))
		indice += 2
	return {"testo": testo, "valore": valore}

static func _mescola(rng: RandomNumberGenerator, lista: Array) -> void:
	for indice in range(lista.size() - 1, 0, -1):
		var scambio := rng.randi_range(0, indice)
		var tmp = lista[indice]
		lista[indice] = lista[scambio]
		lista[scambio] = tmp

## La riga che accompagna l'apertura riuscita. `pulito` è vero se non si è
## sbagliato nemmeno una tessera: non vale frammenti in più — il contenuto del
## forziere non dipende da come si gioca ([[TreasureCatalog]]) — vale una riga
## diversa, che è l'unica ricompensa che non sposta l'economia.
static func riga_di_vittoria(pulito: bool) -> String:
	return "Chiavistello pulito: tutti i denti al primo colpo." if pulito \
		else "Il chiavistello cede."

static func riga_di_fallimento() -> String:
	return "I denti si riallineano da soli. Il forziere resta lì: si riprova quando vuoi."
