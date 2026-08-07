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

const MINIMO := 3
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

	print("FORMAT DEPTH audit OK — nessun formato sotto le %d ricette, %d materie con ordinamenti tutti fissi" % [
		MINIMO, tutte_fisse.size()])
	quit(0)
