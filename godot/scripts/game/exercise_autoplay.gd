extends RefCounted

## Pilota automatico degli esercizi per gli AUDIT: risolve un nodo qualunque sia
## il suo formato, usando le stesse interazioni dell'ExercisePlayer che userebbe
## un dito sullo schermo. Da quando missioni ed enigmi sono a formati vari
## (scelta multipla ~20%), un audit che risponde solo con `node["answer"]` non
## completa più la sessione: questo file è l'unico posto in cui la conoscenza dei
## formati vive, così un formato nuovo si insegna agli audit una volta sola.
##
## Uso: `const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")`
## poi `Autoplay.solve(player, node, true)` prima di `player._advance()`.

static func solve(player, node: Dictionary, correctly: bool) -> void:
	match str(node.get("format", "multiple_choice")):
		"machine_path":
			_solve_machine_path(player, node, correctly)
		"mystery_sample":
			_solve_mystery_sample(player, node, correctly)
		"verb_decoder":
			_solve_verb_decoder(player, node, correctly)
		"ordering":
			_solve_ordering(player, node, correctly)
		"matching":
			_solve_matching(player, node, correctly)
		"classification":
			_solve_classification(player, node, correctly)
		"graph", "circuit", "hotspot", "notation", "map":
			player._visual_select(_visual_pick(node, correctly))
			player._visual_submit(node)
		"cycle":
			var sequence: Array = Array(node.get("correctOrder", [])).duplicate()
			if not correctly:
				sequence.reverse()
			for id in sequence:
				player._cycle_select(str(id))
			player._cycle_submit(node)
		"code_debug":
			var line := int(node.get("answerLine", 1))
			if not correctly:
				line = 2 if line == 1 else 1
			player._code_line_select(line)
			player._code_submit(node)
		_:
			player._answer(str(node.get("answer", "")) if correctly else "__risposta_sbagliata__")

## Gioca un'intera sessione con un ExercisePlayer già in scena e ne restituisce
## il risultato. `on_start` (opzionale) riceve il player appena creato per
## cablare i segnali della scena reale (es. `progress_changed`).
static func play(tree_root: Node, session: Dictionary, correctly: bool, on_start: Callable = Callable()) -> Dictionary:
	var player := ExercisePlayer.new()
	tree_root.add_child(player)
	if on_start.is_valid():
		on_start.call(player)
	var holder := {"result": {}}
	player.session_finished.connect(func(r): holder["result"] = r)
	player.start_session(session)
	var guard := 0
	while (holder["result"] as Dictionary).is_empty() and guard < 200:
		guard += 1
		solve(player, player._nodes[player._index], correctly)
		if not (holder["result"] as Dictionary).is_empty():
			break
		player._advance()
	player.queue_free()
	return holder["result"]

static func _solve_ordering(player, node: Dictionary, correctly: bool) -> void:
	# Modello a slot numerati: ogni click riempie lo slot successivo, la
	# valutazione avviene al submit.
	var sequence: Array = Array(node.get("correctOrder", [])).duplicate()
	if not correctly:
		sequence.reverse()
	for target in sequence:
		var idx := _button_index(player._mg_buttons, str(target))
		if idx >= 0:
			player._ordering_click(idx, node)
	player._ordering_submit(node)

static func _solve_machine_path(player, node: Dictionary, correctly: bool) -> void:
	var path: Array = Array(node.get("solution", [])).duplicate()
	if not correctly:
		var solution_ids: Array = path.duplicate()
		for raw in Array(node.get("machines", [])):
			var id := str((raw as Dictionary).get("id", ""))
			if not solution_ids.has(id):
				path[0] = id
				break
	for index in path.size():
		player._machine_place(str(path[index]), index, node)
	var result := ExerciseInteraction.evaluate_machine_path(
		int(node.get("start", 0)), path, Array(node.get("machines", [])))
	# Gli audit non aspettano l'animazione: consegnano direttamente il risultato
	# prodotto dallo stesso motore usato dal pulsante AVVIA LA SFERA.
	player._finish_machine_run(node, result)

static func _solve_mystery_sample(player, node: Dictionary, correctly: bool) -> void:
	var tests: Array = node.get("tests", [])
	for index in mini(tests.size(), int(node.get("minTests", 2))):
		player._sample_run_test(str((tests[index] as Dictionary).get("id", "")), node)
	var answer := str(node.get("answer", ""))
	if not correctly:
		for raw in Array(node.get("samples", [])):
			var candidate := str((raw as Dictionary).get("id", ""))
			if candidate != answer:
				answer = candidate
				break
	player._sample_select_candidate(answer)
	player._sample_submit(node)

static func _solve_verb_decoder(player, node: Dictionary, correctly: bool) -> void:
	var selected := (node.get("solution", {}) as Dictionary).duplicate()
	if not correctly:
		for raw in Array(node.get("timeChoices", [])):
			var id := str((raw as Dictionary).get("id", ""))
			if id != str(selected.get("time", "")):
				selected["time"] = id
				break
	player._verb_selection = selected
	var result := ExerciseInteraction.evaluate_verb_decoder(node, selected)
	# Gli audit saltano soltanto l'animazione della barra: valutazione e scoring
	# restano quelli usati dal pulsante APRI IL MESSAGGIO.
	player._finish_verb_decode(node, result)

static func _solve_matching(player, node: Dictionary, correctly: bool) -> void:
	var pairs: Array = node.get("pairs", [])
	for i in pairs.size():
		if player._answered:
			break
		player._matching_left(i)
		var pick := i if correctly else (i + 1) % pairs.size()
		player._matching_right(str((pairs[pick] as Dictionary).get("right", "")), node)

static func _solve_classification(player, node: Dictionary, correctly: bool) -> void:
	var assignments: Dictionary = node.get("assignments", {})
	var categories: Array = node.get("categories", [])
	for key in assignments.keys():
		var right := str(assignments[key])
		var chosen := right
		if not correctly:
			for c in categories:
				if str(c) != right:
					chosen = str(c)
					break
		player._classification_assign(str(key), chosen)
	player._classification_submit(node)

static func _visual_pick(node: Dictionary, correctly: bool) -> String:
	var answer := str(node.get("answer", ""))
	if correctly:
		return answer
	var fmt := str(node.get("format", ""))
	var points: Array = node.get("targets", []) if fmt == "hotspot" and str(node.get("assetId", "")) != "" else node.get("hotspots", []) if fmt == "hotspot" else node.get("points", []) if fmt == "graph" else node.get("components", []) if fmt == "circuit" else node.get("symbols", []) if fmt == "notation" else node.get("targets", [])
	for p in points:
		var id := str((p as Dictionary).get("id", ""))
		if id != answer:
			return id
	return answer

static func _button_index(buttons: Array, text: String) -> int:
	for i in buttons.size():
		var b: Button = buttons[i]
		if not b.disabled and str(b.text) == text:
			return i
	return -1
