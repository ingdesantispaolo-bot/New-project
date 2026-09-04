extends SceneTree

## **Nessun formato con meno di tre ricette.** (7 agosto 2026)
##
## Segnalazione di gioco: «al mondo 1 la prova di scienze riguarda sempre la
## farfalla, anche in punti diversi della mappa».
##
## Era vero, e il difetto era mio. Avevo contato le ricette **per materia** — e
## scienze ne aveva dieci, quindi sembrava a posto — ma le avevo aggiunte quasi
## tutte ad abbinamento e smistamento: gli **ordinamenti** erano rimasti due, e
## nessuno dei due estrae. La farfalla usciva a ogni secondo ordinamento, sempre
## identica, perché il suo elenco è fisso.
##
## Misurato dopo la segnalazione: **nove materie su dodici avevano due soli
## ordinamenti** al mondo 1. Non era un caso di scienze: era il formato più
## sottile di tutti, e il conteggio per materia lo nascondeva.
##
## Da qui la regola: **un formato con meno di tre ricette si ripete**, e la
## somma per materia non lo dice. Questo audit conta per FORMATO.
##
## ## I formati specialisti erano fuori dal conto (4 settembre 2026)
##
## Fino a oggi le tre coppie qui sotto — abbinamento, ordinamento, smistamento —
## erano le sole misurate. Sono le tre generiche, quelle che ogni materia ha; i
## **formati specialisti** (compositore, grafico, circuito, ciclo, notazione,
## bilancia, indiziario, tracciatore, retta, carta, reperti, caccia all'errore)
## non li guardava nessuno.
##
## Il difetto è uscito da un'altra parte: `explanation_coverage_audit` si è
## arrossato perché **una sola frase di latino copriva il 30% dei nodi
## `compose`**. La spiegazione non era brutta — il formato era sottile. Aveva
## sette ricette in tutto su sei materie, cioè quasi una per materia, ed è
## esattamente la farfalla di scienze spostata di un piano.
##
## Un minimo secco qui non si può mettere, e la ragione è la regola di casa:
## *prima il contenuto, poi il cricchetto*. Alcuni specialisti vivono legittimamente
## in una materia sola — i reperti sono di storia — e imporre tre ricette a
## tutti obbligherebbe a scrivere contenuto per far passare un test. Quindi si
## misura **quante coppie (formato, materia) stanno sotto le tre ricette**, e
## quel numero può solo scendere.

const MINIMO := 3

## I formati specialisti, con la tabella che li contiene. Il conto si fa sulle
## ricette disponibili al livello, come per le tre generiche.
static func _specialisti() -> Array:
	return [
		["compositore", MinigameManager.COMPOSE], ["grafico", MinigameManager.GRAPH],
		["circuito", MinigameManager.CIRCUIT], ["ciclo", MinigameManager.CYCLE],
		["notazione", MinigameManager.NOTATION], ["bilancia", MinigameManager.BALANCE],
		["indiziario", MinigameManager.CLUE], ["tracciatore", MinigameManager.TRACE],
		["retta", MinigameManager.NUMBER_LINE], ["carta", MinigameManager.MAP_READING],
		["reperti", MinigameManager.HOTSPOT], ["scorri", MinigameManager.SWIPE],
		["caccia-errore", MinigameManager.CODE_DEBUG],
	]

## **Quante coppie (specialista, materia) offrono meno di tre ricette.**
##
## **Ventidue, misurate il 4 settembre 2026** dopo aver portato `compose` da
## sette ricette a diciotto — che è la ragione per cui il compositore non è più
## in questa lista, mentre ci era in cima. Come ogni cricchetto di questo
## progetto: **si abbassa e mai si alza.**
##
## Il numero non è un obiettivo da azzerare a tutti i costi. Alcune di queste
## coppie sono sottili per natura — un ciclo dell'acqua ha le fasi che ha — e la
## regola di casa dice *prima il contenuto, poi il cricchetto*: partire da zero
## obbligherebbe a scrivere ricette per far passare un test. Il numero serve a
## rendere il debito **visibile e decrescente**, che è l'unica forma che in questo
## progetto ha mai funzionato.
##
## Le più esposte sono quelle a una ricetta sola: lì il bambino rivede la stessa
## identica prova ogni volta che il formato esce, ed è il difetto che
## `explanation_coverage_audit` ha preso su latino. Si abbassa scrivendo ricette
## dove la materia ne ha una, non togliendo il formato alla materia.
const MAX_SPECIALISTI_SOTTILI := 22
## Matematica non ha ordinamenti a catalogo: usa quelli numerici generati, che
## sono infiniti. È l'unica eccezione, ed è dichiarata invece che dedotta.
const SENZA_ORDINAMENTO := ["matematica"]
## Quante materie possono avere, al mondo 1, ordinamenti TUTTI a elenco fisso.
## E' il numero misurato oggi: puo' solo scendere.
const MAX_TUTTE_FISSE := 6

func _init() -> void:
	var problemi: Array = []
	var tutte_fisse: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for livello in [1, 2, 4, 8]:
			for coppia in [
				["abbinamento", MinigameManager.MATCHING],
				["ordinamento", MinigameManager.ORDERING],
				["smistamento", MinigameManager.CLASSIFICATION],
			]:
				var nome := str(coppia[0])
				if nome == "ordinamento" and SENZA_ORDINAMENTO.has(subject):
					continue
				var n := 0
				for spec in Array(Dictionary(coppia[1]).get(subject, [])):
					if int(Dictionary(spec).get("minLevel", 0)) <= livello:
						n += 1
				if n < MINIMO:
					problemi.append("%s L%d %s: %d" % [subject, livello, nome, n])

	var elenco := "nessuno" if problemi.is_empty() else ", ".join(PackedStringArray(problemi))
	assert(problemi.is_empty(),
		"formati con meno di %d ricette (si ripetono): %s" % [MINIMO, elenco])

	# E le ricette a elenco FISSO — quelle senza estrazione — sono le peggiori:
	# ogni volta che escono sono identiche. Non si vietano (un ciclo dell'acqua
	# ha quattro fasi e non se ne inventano altre), ma non possono essere la
	# maggioranza di un formato, o quel formato diventa una filastrocca.
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var specs: Array = Array(MinigameManager.ORDERING.get(subject, []))
		if specs.is_empty():
			continue
		var ammesse := 0
		var fisse := 0
		for spec in specs:
			var s: Dictionary = spec
			if int(s.get("minLevel", 0)) > 1:
				continue
			ammesse += 1
			if not s.has("draw"):
				fisse += 1
		if ammesse > 0 and fisse == ammesse:
			tutte_fisse.append(subject)

	# **Il cricchetto sugli elenchi fissi.** Un ordinamento senza estrazione esce
	# sempre identico: e' esattamente la farfalla che il collaudo ha segnalato.
	# Non si vietano — un ciclo dell'acqua ha quattro fasi e non se ne inventano
	# altre — ma il numero di materie in cui TUTTI gli ordinamenti del mondo 1
	# sono fissi puo' solo scendere.
	assert(tutte_fisse.size() <= MAX_TUTTE_FISSE,
		"materie in cui ogni ordinamento del mondo 1 e' a elenco fisso: %d (tetto %d) — %s" % [
			tutte_fisse.size(), MAX_TUTTE_FISSE, ", ".join(PackedStringArray(tutte_fisse))])

	# **Gli specialisti.** Una materia che offre un formato specialista deve
	# offrirlo con almeno tre ricette, altrimenti quel formato è una filastrocca
	# con un nome esotico. Il conto si fa al livello più alto, dove tutte le
	# ricette sono disponibili: se non bastano lì, non bastano da nessuna parte.
	var sottili: Array = []
	for coppia in _specialisti():
		var nome := str(coppia[0])
		var tabella: Dictionary = coppia[1]
		for subject_data in tabella.keys():
			var subject := str(subject_data)
			var n := Array(tabella[subject]).size()
			if n < MINIMO:
				sottili.append("%s/%s: %d" % [subject, nome, n])
	sottili.sort()

	print("FORMAT DEPTH — specialisti sotto le %d ricette: %d%s" % [
		MINIMO, sottili.size(),
		"" if sottili.is_empty() else " → " + ", ".join(PackedStringArray(sottili))])
	assert(sottili.size() <= MAX_SPECIALISTI_SOTTILI,
		"coppie (specialista, materia) sotto le %d ricette: %d (tetto %d) — %s" % [
			MINIMO, sottili.size(), MAX_SPECIALISTI_SOTTILI,
			", ".join(PackedStringArray(sottili))])

	print("FORMAT DEPTH audit OK — nessun formato sotto le %d ricette, %d materie con ordinamenti tutti fissi, %d specialisti sottili" % [
		MINIMO, tutte_fisse.size(), sottili.size()])
	quit(0)
