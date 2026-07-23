extends SceneTree

## Gate visuale C-P3: ogni famiglia usa il contratto comune, costruisce controlli
## accessibili e arriva allo stesso `_score_current`, senza conoscere save,
## mastery o ricompense.

const PLAYER := preload("res://scripts/game/exercise_player.gd")
const INTERACTION := preload("res://scripts/game/exercise_interaction.gd")

var player: Control

func _init() -> void:
	call_deferred("_run")

func _base(fmt: String) -> Dictionary:
	return {
		"format": fmt,
		"prompt": "Completa la prova di verifica del renderer.",
		"topic": "renderer-cp3",
		"difficulty": 2,
		"explanation": "Il feedback spiega la relazione corretta.",
	}

func _session(node: Dictionary, kind: String = "mission") -> Dictionary:
	return {
		"sessionId": "renderer-%s" % str(node["format"]),
		"kind": kind,
		"subject": "logica",
		"nodes": [node],
		"shields": 3,
		"pace": "reasoning",
		"timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {}},
	}

func _run() -> void:
	player = PLAYER.new()
	root.add_child(player)

	var ordering := _base("ordering")
	ordering.merge({"items": ["B", "A", "C"], "correctOrder": ["A", "B", "C"]})
	await _start(ordering)
	assert(player.find_child("OrderingSlot_00", true, false) != null, "ordering: slot numerati mancanti")
	player.call("_ordering_place", "1", 0)
	player.call("_ordering_place", "0", 1)
	player.call("_ordering_place", "2", 2)
	player.call("_ordering_submit", ordering)
	_assert_scored("ordering")

	var matching := _base("matching")
	matching.merge({"pairs": [
		{"left": "2 + 2", "right": "4"},
		{"left": "3 + 3", "right": "6"},
		{"left": "4 + 4", "right": "8"},
	]})
	await _start(matching)
	assert(player.find_child("MatchingBoard", true, false) != null, "matching: board mancante")
	for i in 3:
		player.call("_matching_left", i)
		player.call("_matching_right", str(matching["pairs"][i]["right"]), matching)
	_assert_scored("matching")
	assert((player.get("_matching_connections") as Array).size() == 3, "matching: linee/snap non registrati")

	var classification := _base("classification")
	classification.merge({
		"items": ["sole", "pioggia", "vento"],
		"categories": ["astro", "meteo"],
		"assignments": {"sole": "astro", "pioggia": "meteo", "vento": "meteo"},
	})
	await _start(classification)
	for key in classification["assignments"].keys():
		player.call("_classification_assign", str(key), str(classification["assignments"][key]))
	player.call("_classification_assign", "sole", "meteo")
	player.call("_classification_submit", classification)
	assert(not bool(player.get("_answered")) and int(player.get("_shields")) == 2,
		"classification: errore correggibile deve togliere uno scudo senza chiudere il nodo")
	player.call("_classification_assign", "sole", "astro")
	player.call("_classification_submit", classification)
	_assert_scored("classification")

	var hotspot := _base("hotspot")
	hotspot.merge({
		"hotspots": [
			{"id": "north", "label": "Nord", "x": 0.5, "y": 0.18},
			{"id": "south", "label": "Sud", "x": 0.5, "y": 0.82},
		],
		"answer": "north",
	})
	await _visual_success(hotspot)

	var graph := _base("graph")
	graph.merge({
		"points": [
			{"id": "low", "label": "A", "x": 0.2, "y": 0.2},
			{"id": "high", "label": "B", "x": 0.8, "y": 0.8},
		],
		"answer": "high",
	})
	await _visual_success(graph)

	var circuit := _base("circuit")
	circuit.merge({
		"components": [
			{"id": "battery", "label": "Pila", "x": 0.18, "y": 0.5},
			{"id": "switch", "label": "Interruttore", "x": 0.5, "y": 0.25},
			{"id": "lamp", "label": "Lampada", "x": 0.82, "y": 0.5},
		],
		"connections": [["battery", "switch"], ["switch", "lamp"]],
		"answer": "switch",
	})
	await _visual_success(circuit)

	var code := _base("code_debug")
	code.merge({"codeLines": ["x = 2", "if x = 2:", "    print(x)"], "answerLine": 2})
	await _start(code)
	player.call("_code_line_select", 2)
	player.call("_code_submit", code)
	_assert_scored("code_debug")

	# Prova finale distinta e leggibile: heading specifico, scroll delle opzioni
	# e target touch/focus presenti.
	await _start(ordering, "final_exam")
	var heading := player.find_child("ExerciseHeading", true, false) as Label
	assert(heading != null and "ESAME FINALE" in heading.text, "esame non distinto dalla missione")
	assert(player.find_child("ExerciseOptionsScroll", true, false) != null, "overflow: manca lo scroll")
	for node in player.find_children("*", "Button", true, false):
		var button := node as Button
		assert(button.focus_mode == Control.FOCUS_ALL, "tastiera: bottone senza focus %s" % button.name)
		assert(button.custom_minimum_size.y >= 42.0, "touch target troppo basso: %s" % button.name)

	# Il percorso realmente usato nel mondo deve chiedere la missione variata,
	# non lasciare la policy O-P3 disponibile ma scollegata.
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := NativeWorldState.default_request()
	var result := NativeWorldState.result_for(request)
	gameplay.setup(request, result, false)
	var live_sessions: Array = []
	gameplay.session_requested.connect(func(value): live_sessions.append(value))
	assert(gameplay.try_start_mission({"subject": "matematica"}, "cp3-live"), "percorso live non avviato")
	assert(live_sessions.size() == 1, "percorso live non ha emesso la sessione")
	var live_nodes: Array = (live_sessions[0] as Dictionary).get("nodes", [])
	assert(INTERACTION.distinct_formats(live_nodes).size() >= 2, "missione live con una sola famiglia")
	assert(INTERACTION.multiple_choice_ratio(live_nodes) <= 0.34, "missione live oltre 1/3 MC")

	print("EXERCISE RENDERER audit OK — ordering/matching drag+click, classification, hotspot, graph, circuit, code-debug, exam/accessibilità")
	quit(0)

func _start(node: Dictionary, kind: String = "mission") -> void:
	var validation := INTERACTION.validate(node)
	assert(bool(validation["ok"]), "%s non valido: %s" % [str(node["format"]), str(validation["errors"])])
	player.call("start_session", _session(node, kind))
	await process_frame
	await process_frame

func _visual_success(node: Dictionary) -> void:
	await _start(node)
	assert(player.find_child("ExerciseDiagram_%s" % str(node["format"]), true, false) != null,
		"%s: diagramma mancante" % str(node["format"]))
	player.call("_visual_select", str(node["answer"]))
	player.call("_visual_submit", node)
	_assert_scored(str(node["format"]))

func _assert_scored(fmt: String) -> void:
	assert(bool(player.get("_answered")), "%s non ha chiuso il nodo" % fmt)
	assert(int(player.get("_correct")) == 1, "%s non è passato dal bookkeeping comune" % fmt)
