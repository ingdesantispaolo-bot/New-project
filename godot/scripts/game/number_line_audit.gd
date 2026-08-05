extends SceneTree

## **La retta numerica e la bilancia.** (5 agosto 2026)
##
## Perché è stata aggiunta: `format_shape_probe` ha misurato che a livello 1
## matematica non aveva **nessun formato visuale** — solo abbinamenti,
## ordinamenti e smistamenti, tutti di testo. La retta è il primo posto in cui un
## numero smette di essere un simbolo e diventa una posizione, ed è dove
## frazioni, decimali e negativi diventano confrontabili a occhio invece che a
## regola.
##
## Questo audit tiene le tre cose che la rendono giocabile davvero:
##
## 1. **le posizioni stanno dentro la scala disegnata.** Un bersaglio fuori
##    finisce oltre il bordo del riquadro e non si può toccare;
## 2. **due posizioni non condividono un valore.** Occuperebbero lo stesso punto
##    a schermo, e la domanda avrebbe due bottoni sovrapposti;
## 3. **si gioca davvero**: il nodo passa dall'`ExercisePlayer`, i bersagli
##    diventano bottoni, e rispondere giusto conta come risposta giusta.

func _init() -> void:
	var failures: Array = []
	var mg := MinigameManager.new()

	# --- 1. Le specifiche ------------------------------------------------------
	var quante := 0
	for materia in MinigameManager.NUMBER_LINE.keys():
		for spec_data in Array(MinigameManager.NUMBER_LINE[materia]):
			var spec := spec_data as Dictionary
			quante += 1
			var etichetta := "%s/%s" % [str(materia), str(spec.get("topic", "?"))]
			var minimo := float(spec.get("min", 0.0))
			var massimo := float(spec.get("max", 0.0))
			if massimo <= minimo:
				failures.append("%s: scala rovesciata" % etichetta)
			# Le etichette scritte devono stare anch'esse dentro la scala,
			# altrimenti il numero compare fuori dalla retta.
			for voce in Array(spec.get("labels", [])):
				var v := float((voce as Dictionary).get("value", 0.0))
				if v < minimo or v > massimo:
					failures.append("%s: etichetta %s fuori scala" % [etichetta, v])
			var passo := float(spec.get("tick", 0.0))
			if passo > 0.0 and (massimo - minimo) / passo > 24.0:
				failures.append("%s: più di 24 tacche, la retta diventa illeggibile" % etichetta)

	# --- 2. I nodi costruiti passano la validazione ----------------------------
	var rng := RandomNumberGenerator.new()
	var costruiti := 0
	for seme in range(12):
		rng.seed = seme * 131 + 7
		for livello in [1, 5, 9, 13, 20]:
			var sessione := mg.build_minigame("matematica", livello, rng)
			for nodo_data in Array(sessione.get("nodes", [])):
				var nodo := nodo_data as Dictionary
				if str(nodo.get("format", "")) != "number_line":
					continue
				costruiti += 1
				var esito := ExerciseInteraction.validate(nodo)
				if not bool(esito.get("ok", false)):
					failures.append("nodo non valido: %s" % str(esito.get("errors", [])))
				# La risposta deve essere uno dei bersagli offerti, sempre.
				var ids: Array = []
				for b in Array(nodo.get("targets", [])):
					ids.append(str((b as Dictionary).get("id", "")))
				if not ids.has(str(nodo.get("answer", ""))):
					failures.append("la risposta non è fra i bersagli: %s" % str(nodo.get("answer", "")))
	if costruiti == 0:
		failures.append("nessun nodo di retta numerica è mai stato costruito in 60 sessioni")

	# --- 3. Si gioca davvero ---------------------------------------------------
	var player := ExercisePlayer.new()
	root.add_child(player)
	var nodo_prova := mg._number_line_node(
		"matematica", MinigameManager.NUMBER_LINE["matematica"][0], 1, rng, 0)
	var esiti: Array = []
	player.session_finished.connect(func(r): esiti.append(r))
	player.start_session({
		"sessionId": "numline-audit", "kind": "minigame", "subject": "matematica",
		"level": 1, "nodes": [nodo_prova], "shields": 3, "pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 30, "fragments": 2}},
	})
	var bottoni := player.find_children("VisualChoice_*", "Button", true, false)
	if bottoni.size() != Array(nodo_prova.get("targets", [])).size():
		failures.append("i bersagli non sono diventati bottoni: %d su %d" % [
			bottoni.size(), Array(nodo_prova.get("targets", [])).size()])
	for nodo_bottone in bottoni:
		var b := nodo_bottone as Button
		if str(b.accessibility_name).strip_edges() == "":
			failures.append("bottone della retta senza etichetta accessibile: %s" % b.name)
		if b.custom_minimum_size.y < 44.0:
			failures.append("bersaglio della retta troppo piccolo per un dito: %s" % b.name)
	player.call("_answer", str(nodo_prova.get("answer", "")))
	if player.get("_correct") != 1:
		failures.append("rispondere giusto sulla retta non è stato contato come giusto")
	player.queue_free()

	# --- 4. La bilancia: il controllo è ARITMETICO -----------------------------
	# La validazione ricalcola i due piatti e pretende che UN SOLO candidato
	# pareggi. Qui si verifica che ogni specifica scritta lo rispetti davvero:
	# una bilancia che non pareggia insegna un'equivalenza falsa, che è peggio
	# di non insegnare niente.
	var bilance := 0
	for materia in MinigameManager.BALANCE.keys():
		for spec_data in Array(MinigameManager.BALANCE[materia]):
			var spec := spec_data as Dictionary
			bilance += 1
			var nodo := mg._balance_node(str(materia), spec, 2, rng, 0)
			var esito := ExerciseInteraction.validate(nodo)
			if not bool(esito.get("ok", false)):
				failures.append("bilancia %s/%s: %s" % [
					str(materia), str(spec.get("topic", "?")), str(esito.get("errors", []))])
	if bilance < 5:
		failures.append("solo %d bilance: troppo poche per entrare nella rotazione" % bilance)

	if failures.is_empty():
		print("BILANCE: %d specifiche, aritmetica verificata" % bilance)
		print("NUMBER LINE audit OK — %d specifiche, %d nodi costruiti e giocabili" % [quante, costruiti])
		quit(0)
	else:
		print("RETTA NUMERICA ROSSA — %d problemi:" % failures.size())
		for f in failures.slice(0, 15):
			print("  - %s" % f)
		quit(1)
