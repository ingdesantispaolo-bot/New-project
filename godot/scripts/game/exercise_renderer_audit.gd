extends SceneTree

## Gate visuale C-P3: ogni famiglia usa il contratto comune, costruisce controlli
## accessibili e arriva allo stesso `_score_current`, senza conoscere save,
## mastery o ricompense.

const PLAYER := preload("res://scripts/game/exercise_player.gd")
const INTERACTION := preload("res://scripts/game/exercise_interaction.gd")
const SIGNATURE := preload("res://scripts/game/exercise_signature.gd")

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
	assert(str(player.get_meta("last_causal_feedback", "")) == "snap",
		"ordering: lo snap non emette feedback causale")
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
	assert(str(player.get_meta("last_causal_feedback", "")) in ["connect", "snap"],
		"matching: collegamento senza feedback causale")

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
	assert(str(player.get_meta("last_causal_feedback", "")) == "error",
		"classification: errore senza feedback distinto")
	player.call("_classification_assign", "sole", "astro")
	player.call("_classification_submit", classification)
	_assert_scored("classification")

	var hotspot := _base("hotspot")
	hotspot.merge({
		"assetId": "roman_artifacts",
		"targets": [
			{"id": "aqueduct", "label": "Acquedotto romano"},
			{"id": "column", "label": "Colonna romana"},
			{"id": "amphora", "label": "Anfora romana"},
			{"id": "mosaic", "label": "Mosaico romano"},
		],
		"answer": "aqueduct",
	})
	await _visual_success(hotspot, "mosaic")
	var hotspot_button := player.find_child("VisualChoice_aqueduct", true, false) as Button
	assert(hotspot_button != null and hotspot_button.text == ""
		and hotspot_button.accessibility_name == "Acquedotto romano"
		and hotspot_button.custom_minimum_size.x >= 48.0 and hotspot_button.custom_minimum_size.y >= 48.0,
		"hotspot: bersaglio illustrato deve essere touch-accessibile senza testo sovrapposto")
	var invalid_atlas := hotspot.duplicate(true)
	invalid_atlas["assetId"] = "missing_atlas"
	assert(not bool(INTERACTION.validate(invalid_atlas)["ok"]),
		"hotspot: un atlante sconosciuto deve essere rifiutato")
	var invalid_target := hotspot.duplicate(true)
	invalid_target["targets"][0]["id"] = "missing_target"
	assert(not bool(INTERACTION.validate(invalid_target)["ok"]),
		"hotspot: un bersaglio non catalogato deve essere rifiutato")
	var different_atlas := hotspot.duplicate(true)
	different_atlas["assetId"] = "roman_artifacts_variant"
	assert(SIGNATURE.of(hotspot) != SIGNATURE.of(different_atlas),
		"hotspot: l'atlante deve contribuire alla firma del contenuto")

	var graph := _base("graph")
	graph.merge({
		"points": [
			{"id": "low", "label": "A", "x": 0.2, "y": 0.2},
			{"id": "high", "label": "B", "x": 0.8, "y": 0.8},
		],
		"answer": "high",
	})
	await _visual_success(graph, "low")

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
	await _visual_success(circuit, "battery")

	var notation := _base("notation")
	notation.merge({
		"staff": {"clef": "treble"},
		"symbols": [
			{"id": "do", "kind": "note", "label": "Do centrale, semiminima", "staffStep": -2, "duration": "quarter"},
			{"id": "mi", "kind": "note", "label": "Mi, minima", "staffStep": 0, "duration": "half"},
			{"id": "sol", "kind": "note", "label": "Sol, croma", "staffStep": 2, "duration": "eighth"},
			{"id": "pause", "kind": "rest", "label": "Pausa di semiminima", "staffStep": 4, "duration": "quarter"},
		],
		"answer": "sol",
	})
	await _visual_success(notation, "pause")
	var notation_button := player.find_child("VisualChoice_sol", true, false) as Button
	assert(notation_button != null and notation_button.text == ""
		and notation_button.accessibility_name == "Sol, croma",
		"notation: il target deve restare visivo ma avere un nome accessibile")
	var overcrowded := notation.duplicate(true)
	for extra_index in range(4):
		overcrowded["symbols"].append({
			"id": "extra%d" % extra_index, "kind": "note", "label": "Nota extra %d" % extra_index,
			"staffStep": extra_index + 3, "duration": "quarter",
		})
	var overcrowded_validation := INTERACTION.validate(overcrowded)
	assert(not bool(overcrowded_validation["ok"])
		and "target touch" in " ".join(overcrowded_validation["errors"]),
		"notation: il contratto deve limitare il numero di target touch sul rigo")
	var different_pitch := notation.duplicate(true)
	different_pitch["symbols"][0]["staffStep"] = -1
	assert(SIGNATURE.of(notation) != SIGNATURE.of(different_pitch),
		"notation: altezze diverse non possono condividere la firma contenuto")

	var map := _base("map")
	map.merge({
		"mapId": "italy",
		"targets": [
			{"id": "po", "label": "Fiume Po"},
			{"id": "sicily", "label": "Sicilia"},
			{"id": "sardinia", "label": "Sardegna"},
		],
		"answer": "po",
	})
	await _visual_success(map, "sicily")
	var map_button := player.find_child("VisualChoice_po", true, false) as Button
	assert(map_button != null and map_button.text == ""
		and map_button.accessibility_name == "Fiume Po"
		and map_button.custom_minimum_size.x >= 48.0
		and map_button.custom_minimum_size.y >= 48.0,
		"map: bersaglio muto deve avere nome accessibile e target touch sufficiente")
	var missing_map := map.duplicate(true)
	missing_map["mapId"] = "atlante-inesistente"
	assert(not bool(INTERACTION.validate(missing_map)["ok"]),
		"map: il contratto deve rifiutare carte non presenti nell'atlante")
	var missing_target := map.duplicate(true)
	missing_target["targets"][0]["id"] = "fiume-inesistente"
	missing_target["answer"] = "fiume-inesistente"
	assert(not bool(INTERACTION.validate(missing_target)["ok"]),
		"map: il contratto deve rifiutare bersagli senza geometria")
	var different_map_answer := map.duplicate(true)
	different_map_answer["answer"] = "sicily"
	assert(SIGNATURE.of(map) != SIGNATURE.of(different_map_answer),
		"map: bersagli corretti diversi non possono condividere la firma contenuto")
	var semantic_map := map.duplicate(true)
	semantic_map["targets"] = [
		{"id": "alps", "label": "Alpi"},
		{"id": "apennines", "label": "Appennini"},
		{"id": "adriatic_sea", "label": "Mare Adriatico"},
		{"id": "tyrrhenian_sea", "label": "Mar Tirreno"},
	]
	semantic_map["answer"] = "alps"
	assert(bool(INTERACTION.validate(semantic_map)["ok"]),
		"map: catene e mari italiani devono essere bersagli semantici disponibili")
	var europe_map := _base("map")
	europe_map.merge({
		"mapId": "europe",
		"targets": [
			{"id": "italy", "label": "Segnaposto A"},
			{"id": "france", "label": "Segnaposto B"},
			{"id": "germany", "label": "Segnaposto C"},
		],
		"answer": "italy",
	})
	assert(bool(INTERACTION.validate(europe_map)["ok"]),
		"map: la carta vettoriale d'Europa deve offrire bersagli validi")

	var cycle := _base("cycle")
	cycle.merge({
		"stages": [
			{"id": "pioggia", "label": "Precipitazione", "glyph": "rain"},
			{"id": "mare", "label": "Raccolta", "glyph": "water"},
			{"id": "nuvola", "label": "Condensazione", "glyph": "cloud"},
			{"id": "vapore", "label": "Evaporazione", "glyph": "sun"},
		],
		"correctOrder": ["mare", "vapore", "nuvola", "pioggia"],
	})
	await _start(cycle)
	var cycle_diagram := player.find_child("ExerciseDiagram_cycle", true, false)
	assert(cycle_diagram != null, "cycle: schema mancante")
	for id in ["pioggia", "nuvola", "vapore", "mare"]:
		player.call("_cycle_select", id)
	player.call("_cycle_submit", cycle)
	assert(str(cycle_diagram.get("cycle_feedback_state")) == "error",
		"cycle: sequenza errata senza feedback sullo schema")
	player.call("_cycle_clear")
	for id in cycle["correctOrder"]:
		player.call("_cycle_select", str(id))
	player.call("_cycle_submit", cycle)
	assert(str(cycle_diagram.get("cycle_feedback_state")) == "correct",
		"cycle: sequenza corretta non evidenziata")
	_assert_scored("cycle")

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
	# Cercava «ESAME FINALE»; la voce a 11 anni dice «SFIDA FINALE». Quello che
	# conta è che l'intestazione distingua la prova finale da una missione
	# normale, non con quale parola lo faccia.
	assert(
		heading != null and ("ESAME FINALE" in heading.text or "SFIDA FINALE" in heading.text),
		"prova finale non distinta dalla missione: intestazione «%s»" % [
			"" if heading == null else heading.text],
	)
	assert(player.find_child("ExerciseOptionsScroll", true, false) != null, "overflow: manca lo scroll")
	for node in player.find_children("*", "Button", true, false):
		var button := node as Button
		assert(button.focus_mode == Control.FOCUS_ALL, "tastiera: bottone senza focus %s" % button.name)
		assert(button.custom_minimum_size.y >= 48.0, "touch target troppo basso: %s" % button.name)

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

	root.remove_child(gameplay)
	gameplay.free()
	root.remove_child(player)
	player.free()
	player = null
	await process_frame
	var audio := root.get_node_or_null("NativeAudio")
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
					child.free()
		audio.set("_stream_cache", {})
	await create_timer(0.15).timeout
	print("EXERCISE RENDERER audit OK — ordering/matching drag+click, classification, hotspot, graph, circuit, notation, map, cycle, code-debug, exam/accessibilità")
	quit(0)

func _start(node: Dictionary, kind: String = "mission") -> void:
	var validation := INTERACTION.validate(node)
	assert(bool(validation["ok"]), "%s non valido: %s" % [str(node["format"]), str(validation["errors"])])
	player.call("start_session", _session(node, kind))
	await process_frame
	await process_frame

func _visual_success(node: Dictionary, wrong_id: String = "") -> void:
	await _start(node)
	var diagram := player.find_child("ExerciseDiagram_%s" % str(node["format"]), true, false)
	assert(diagram != null,
		"%s: diagramma mancante" % str(node["format"]))
	if wrong_id != "":
		player.call("_visual_select", wrong_id)
		assert(str(diagram.get("feedback_state")) == "selected",
			"%s: selezione non riflessa sulla superficie" % str(node["format"]))
		player.call("_visual_submit", node)
		assert(str(diagram.get("feedback_state")) == "error"
			and str(player.get_meta("last_causal_feedback", "")) == "error",
			"%s: errore privo di feedback causale" % str(node["format"]))
	player.call("_visual_select", str(node["answer"]))
	player.call("_visual_submit", node)
	assert(str(diagram.get("feedback_state")) == "correct",
		"%s: soluzione non evidenziata sulla superficie" % str(node["format"]))
	_assert_scored(str(node["format"]))

func _assert_scored(fmt: String) -> void:
	assert(bool(player.get("_answered")), "%s non ha chiuso il nodo" % fmt)
	assert(int(player.get("_correct")) == 1, "%s non è passato dal bookkeeping comune" % fmt)
