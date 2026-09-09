extends SceneTree

## **La fascia di un item l'ha decisa una persona o la lunghezza del testo?**
## (9 settembre 2026)
##
## Il passaggio da quattro bande a otto fasce, l'8 settembre, e' stato fatto
## bene sul piano della struttura e per niente sul piano del contenuto: gli item
## non sono stati riautorati, sono stati **tagliati in due da un'euristica**.
## `expandLegacyDifficultyBands()` in `scripts/build-exercise-banks.mjs` ordina
## i quesiti di una vecchia banda per un punteggio di «domanda cognitiva» —
## lunghezza del prompt, formato libero, presenza di parole come «perche'» o
## «se» — e manda la meta' piu' lunga nella fascia pari.
##
## Misurato il 9 settembre: **3159 item su 4854, il 65,1%**, avevano preso la
## loro fascia da li'. Cinque materie erano al 100%.
##
## **La lunghezza del testo non e' la difficolta' di un argomento.** E' lo stesso
## errore gia' pagato sulle risposte — «le domande perche' regalano la
## lunghezza» — qui applicato alla scala di difficolta' di tutto il gioco: una
## domanda corta su un argomento avanzato finisce in basso, una domanda lunga su
## un argomento elementare finisce in alto.
##
## ## Che cosa conta come «autorata»
##
## Il bake marca `_difficulty8` su ogni item la cui fascia 1..8 e' stata decisa
## da una persona, in due modi:
##
##   - **scritta sull'item**, come nei sei file `scripts/banks/*-programma.mjs`;
##   - **scritta in una scala dichiarata per argomento** (`SCALA_LOGICA`,
##     `SCALA_LATINO` e le altre): una tabella che dice, argomento per
##     argomento, in quali quattro fasce cadono i suoi gradi. Non e' un'euristica
##     perche' non guarda il testo: guarda l'ordine in cui la materia si insegna,
##     ed e' scritta e rileggibile.
##
## Il flag resta nel JSON apposta. Cancellarlo — come faceva il bake fino a oggi
## — rendeva la distinzione invisibile a valle, e quindi non misurabile.
##
## ## Perche' e' un cricchetto per materia e non una soglia sola
##
## Nessuno riautorera' cinquemila item in un giorno. Il pavimento parte dal
## valore misurato di ciascuna materia e **sale, mai scende**: ogni lotto che
## riautora alza la sua riga. Una soglia unica al 100% renderebbe rosso un audit
## su lavoro che nessuno ha ancora fatto, e obbligherebbe a barare per farlo
## passare.
##
## Quando tutte e dodici sono a 100 questo dizionario sparisce e resta un
## `assert` solo.

## Percentuale minima di item con la fascia autorata, per materia. Cricchetto:
## si alza, non si abbassa mai.
const PAVIMENTO := {
	"elettronica": 100,
	"latino": 100,
	"logica": 100,
	"musica": 100,
	"scienze": 100,
	"storia": 100,
	"inglese": 67,
	"italiano": 42,
	"coding": 37,
	"matematica": 33,
	"fisica": 25,
	"geografia": 25,
}

## Sotto questa quota complessiva il gioco sta ancora decidendo la difficolta'
## con un righello. Sale insieme alle righe qui sopra.
const PAVIMENTO_TOTALE := 57.0

func _init() -> void:
	var rotte: Array = []
	var totale := 0
	var autorati := 0
	print("FASCIA AUTORATA — chi ha deciso la fascia di ogni item")
	print("materia        autorati / totale     %   pavimento")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var items := _bank_items(subject)
		if items.is_empty():
			rotte.append("%s: banco vuoto o illeggibile" % subject)
			continue
		var n := 0
		for item_data in items:
			if bool((item_data as Dictionary).get("_difficulty8", false)):
				n += 1
		totale += items.size()
		autorati += n
		var quota := 100.0 * float(n) / float(items.size())
		var pavimento := float(PAVIMENTO.get(subject, 0))
		print("%-14s %8d / %6d %6.1f %10.0f" % [subject, n, items.size(), quota, pavimento])
		# Mezzo punto di tolleranza: il conteggio si muove di un item quando il
		# banco cresce, e non deve arrossire per un arrotondamento.
		if quota < pavimento - 0.5:
			rotte.append("%s: %.1f%% autorati, il pavimento e' %.0f%%" % [subject, quota, pavimento])
		elif quota > pavimento + 0.5:
			print("      ^ il pavimento di %s puo' salire da %.0f a %.0f" % [subject, pavimento, floor(quota)])

	var quota_totale := 100.0 * float(autorati) / float(maxi(1, totale))
	print("\nTOTALE %d/%d = %.1f%% (pavimento %.1f%%)" % [autorati, totale, quota_totale, PAVIMENTO_TOTALE])
	if quota_totale < PAVIMENTO_TOTALE - 0.5:
		rotte.append("complessivo: %.1f%% contro un pavimento di %.1f%%" % [quota_totale, PAVIMENTO_TOTALE])

	for riga in rotte:
		print("ROTTO — %s" % riga)
	assert(rotte.is_empty(), "la fascia autorata e' scesa: %d casi" % rotte.size())

	print("\nFASCIA AUTORATA audit OK — nessuna materia ha ceduto terreno al ponte")
	quit(0)

## Legge il JSON direttamente invece di passare da ContentManager: il flag
## `_difficulty8` e' un dato del bake e non appartiene al contratto di gioco,
## quindi il selettore non lo espone e non deve farlo.
func _bank_items(subject: String) -> Array:
	var path := "res://data/banks/%s-base.json" % subject
	if not FileAccess.file_exists(path):
		path = "res://data/banks/%s-tabelline.json" % subject
	if not FileAccess.file_exists(path):
		return []
	var dati = JSON.parse_string(FileAccess.get_file_as_string(path))
	if dati is Dictionary:
		return Array((dati as Dictionary).get("items", []))
	return []
