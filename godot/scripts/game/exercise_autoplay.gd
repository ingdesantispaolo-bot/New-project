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
		"ordering":
			_solve_ordering(player, node, correctly)
		"matching":
			_solve_matching(player, node, correctly)
		"classification":
			_solve_classification(player, node, correctly)
		"graph", "circuit", "hotspot":
			player._visual_select(_visual_pick(node, correctly))
			player._visual_submit(node)
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
	var points: Array = node.get("hotspots", []) if fmt == "hotspot" else node.get("points", []) if fmt == "graph" else node.get("components", [])
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
