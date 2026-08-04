extends SceneTree

## Le **domande variabili** sui formati a dato fisso.
##
## Grafico, circuito, notazione, carta e reperti hanno dati fissi: un grafico è
## quel grafico. Fino al 3 agosto questo voleva dire una specifica = una prova, e
## il risultato misurato era che **43 coppie (materia, formato) su 73 producevano
## meno di 100 prove distinte** anche a fine campagna — con la maggioranza sotto
## le quindici. Un bambino rivedeva lo stesso grafico cinque o sei volte per
## partita, identico alla partita dopo.
##
## Il rimedio non aggiunge dati: cambia la **domanda** sugli stessi dati. Un
## grafico letto solo per «dov'è il massimo?» insegna a cercare il punto più
## alto; lo stesso grafico che a volte chiede «quale sta a metà fra il massimo e
## il minimo?» insegna a leggerlo. Didatticamente è meglio, non solo più vario.
##
## Questo audit tiene le tre cose che possono rompersi in silenzio.

func _init() -> void:
	var failures: Array = []
	print("Domande variabili sugli stessi dati\n")

	# Tutti e cinque i formati a dato fisso, non solo i due di partenza: la carta
	# muta e i reperti erano proprio le coppie piu' povere del gioco.
	var tables := {
		"graph": MinigameManager.GRAPH,
		"circuit": MinigameManager.CIRCUIT,
		"notation": MinigameManager.NOTATION,
		"map": MinigameManager.MAP_READING,
		"hotspot": MinigameManager.HOTSPOT,
	}
	var con_domande := 0
	var totale := 0
	var extra := 0

	for fmt in tables.keys():
		for subject in (tables[fmt] as Dictionary).keys():
			for entry in (tables[fmt] as Dictionary)[subject]:
				var spec := entry as Dictionary
				totale += 1
				var domande := Array(spec.get("domande", []))
				if domande.is_empty():
					continue
				con_domande += 1
				extra += domande.size()

				# 1 · ogni domanda dev'essere completa. Una senza spiegazione è
				#     una prova che non insegna niente quando si sbaglia.
				for i in domande.size():
					var q := domande[i] as Dictionary
					for field in ["prompt", "answer", "explanation"]:
						if str(q.get(field, "")).strip_edges() == "":
							failures.append("%s/%s: la domanda %d non ha «%s»" % [
								subject, str(spec.get("topic", "?")), i, field])

				# 2 · la risposta deve esistere fra i bersagli del dato.
				var ids: Array = []
				for point in (Array(spec.get("points", [])) + Array(spec.get("components", []))
						+ Array(spec.get("targets", [])) + Array(spec.get("symbols", []))):
					ids.append(str((point as Dictionary).get("id", "")))
				for q in domande:
					var answer := str((q as Dictionary).get("answer", ""))
					if not ids.is_empty() and not ids.has(answer):
						failures.append("%s/%s: la risposta «%s» non è uno dei bersagli (%s)" % [
							subject, str(spec.get("topic", "?")), answer,
							", ".join(PackedStringArray(ids))])

				# 3 · domande diverse, e diverse anche da quella della specifica.
				#     Due domande uguali sono una prova sola contata due volte, ed
				#     è esattamente il tipo di gonfiaggio che rende inutile la
				#     misura di profondità.
				var viste := {str(spec.get("prompt", "")): true}
				for q in domande:
					var testo := str((q as Dictionary).get("prompt", ""))
					if viste.has(testo):
						failures.append("%s/%s: la domanda «%s…» è ripetuta" % [
							subject, str(spec.get("topic", "?")), testo.substr(0, 40)])
					viste[testo] = true

				# 4 · la profondità dichiarata deve combaciare con le domande.
				var depth := MinigameManager.spec_depth(str(fmt), spec, 24, 0)
				if depth != domande.size() + 1:
					failures.append("%s/%s: profondità %d con %d domande + 1" % [
						subject, str(spec.get("topic", "?")), depth, domande.size()])

	print("specifiche a dato fisso: %d · con domande extra: %d · domande aggiunte: %d" % [
		totale, con_domande, extra])

	# 4-bis · **La risposta dev'essere quella giusta per QUEI dati.**
	#
	# È il controllo che mancava, e la sua assenza è costata caro: il 3 agosto ho
	# generato 94 domande sui grafici con uno script che cercava le specifiche per
	# testo, e dopo la prima inserzione le ricerche trovavano i prompt appena
	# scritti. Le domande sono finite su specifiche che non erano le loro —
	# risposte sbagliate su dati giusti — e **l'audit era verde**, perché
	# controllava solo che la risposta fosse uno dei bersagli.
	#
	# Per i grafici la risposta giusta si calcola: minimo e massimo stanno nei
	# numeri. Dove si può calcolare, si calcola.
	failures.append_array(_check_grafici_coerenti())

	# 5 · `question_of` deve girare su tutte le domande, non fermarsi alla prima.
	for fmt in tables.keys():
		for subject in (tables[fmt] as Dictionary).keys():
			for entry in (tables[fmt] as Dictionary)[subject]:
				var spec := entry as Dictionary
				var domande := Array(spec.get("domande", []))
				if domande.is_empty():
					continue
				var raccolte: Dictionary = {}
				for idx in range(domande.size() + 1):
					raccolte[str(MinigameManager.question_of(spec, idx)["prompt"])] = true
				if raccolte.size() != domande.size() + 1:
					failures.append("%s/%s: scorrendo gli indici escono %d domande su %d" % [
						subject, str(spec.get("topic", "?")), raccolte.size(), domande.size() + 1])

	if not failures.is_empty():
		printerr("DOMANDE VARIABILI NON VALIDE — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("
Question variety audit OK — risposte verificate sui dati, domande distinte, profondità onesta")
	quit(0)

## Ogni domanda che chiede il minimo o il massimo di un grafico deve avere per
## risposta il punto che i dati dicono. Le domande «a metà» e quelle sulla
## salita nominano gli estremi nella frase ma non li chiedono: si saltano, o il
## controllo direbbe il falso.
func _check_grafici_coerenti() -> Array:
	var out: Array = []
	var controllate := 0
	for subject in MinigameManager.GRAPH.keys():
		for entry in MinigameManager.GRAPH[subject]:
			var spec := entry as Dictionary
			var punti: Array = spec.get("points", [])
			if punti.size() < 2:
				continue
			var basso := str((punti[0] as Dictionary).get("id", ""))
			var alto := basso
			var y_basso := float((punti[0] as Dictionary).get("y", 0.0))
			var y_alto := y_basso
			for p in punti:
				var y := float((p as Dictionary).get("y", 0.0))
				if y < y_basso:
					y_basso = y
					basso = str((p as Dictionary).get("id", ""))
				if y > y_alto:
					y_alto = y
					alto = str((p as Dictionary).get("id", ""))
			for q in Array(spec.get("domande", [])):
				var testo := str((q as Dictionary).get("prompt", "")).to_lower()
				var risposta := str((q as Dictionary).get("answer", ""))
				if testo.contains("metà") or testo.contains("in mezzo") \
						or testo.contains("cresce di più") or testo.contains("balzo") \
						or testo.contains("salto in alto"):
					continue
				var atteso := ""
				if testo.contains("minimo") or testo.contains("più basso"):
					atteso = basso
				elif testo.contains("massimo") or testo.contains("più alto"):
					atteso = alto
				if atteso == "":
					continue
				controllate += 1
				if risposta != atteso:
					out.append("%s/%s: «%s…» risponde %s, ma i dati dicono %s" % [
						subject, str(spec.get("topic", "?")), testo.substr(0, 40),
						risposta, atteso])
	print("domande di minimo/massimo verificate contro i dati: %d" % controllate)
	return out
