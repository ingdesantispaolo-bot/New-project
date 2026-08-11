extends SceneTree

const PLAYER := preload("res://scripts/game/exercise_player.gd")
const OUTPUT := "res://../artifacts/exercise-renderers"

var player: Control

func _init() -> void:
	call_deferred("_run")

func _node(fmt: String, extra: Dictionary) -> Dictionary:
	var node := {
		"format": fmt,
		"prompt": "Osserva, prova e costruisci la risposta.",
		"topic": "renderer-cp3",
		"difficulty": 2,
		"explanation": "La relazione corretta emerge dagli elementi della prova.",
	}
	node.merge(extra, true)
	return node

func _notation_node() -> Dictionary:
	return _node("notation", {
		"staff": {"clef": "treble"},
		"symbols": [
			{"id": "do", "kind": "note", "label": "Do centrale, semiminima", "staffStep": -2, "duration": "quarter"},
			{"id": "mi", "kind": "note", "label": "Mi, minima", "staffStep": 0, "duration": "half"},
			{"id": "sol", "kind": "note", "label": "Sol, croma", "staffStep": 2, "duration": "eighth"},
			{"id": "pausa", "kind": "rest", "label": "Pausa di semiminima", "staffStep": 4, "duration": "quarter"},
		],
		"answer": "sol",
	})

func _cycle_node() -> Dictionary:
	return _node("cycle", {
		"stages": [
			{"id": "pioggia", "label": "Precipitazione", "glyph": "rain"},
			{"id": "mare", "label": "Raccolta", "glyph": "water"},
			{"id": "nuvola", "label": "Condensazione", "glyph": "cloud"},
			{"id": "vapore", "label": "Evaporazione", "glyph": "sun"},
		],
		"correctOrder": ["mare", "vapore", "nuvola", "pioggia"],
	})

func _map_node() -> Dictionary:
	return _node("map", {
		"prompt": "Tocca il fiume Po sulla carta muta.",
		"mapId": "italy",
		"targets": [
			{"id": "po", "label": "Fiume Po"},
			{"id": "sicily", "label": "Sicilia"},
			{"id": "sardinia", "label": "Sardegna"},
		],
		"answer": "po",
	})

func _hotspot_node() -> Dictionary:
	return _node("hotspot", {
		"prompt": "Tocca l'acquedotto romano nell'atlante.",
		"assetId": "roman_artifacts",
		"targets": [
			{"id": "aqueduct", "label": "Acquedotto romano"},
			{"id": "column", "label": "Colonna romana"},
			{"id": "amphora", "label": "Anfora romana"},
			{"id": "mosaic", "label": "Mosaico romano"},
		],
		"answer": "aqueduct",
	})

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	player = PLAYER.new()
	root.add_child(player)
	if "--all-formats" in OS.get_cmdline_user_args():
		await _capture_all_formats()
		print("EXERCISE RENDER probe OK - 17 formati / 19 varianti tablet")
		quit(0)
		return
	if "--notation-only" in OS.get_cmdline_user_args():
		await _capture("notation-tablet", _notation_node(), "mission", Vector2i(900, 600))
		print("EXERCISE RENDER probe OK — notazione")
		quit(0)
		return
	if "--cycle-only" in OS.get_cmdline_user_args():
		await _capture("cycle-tablet", _cycle_node(), "mission", Vector2i(900, 600))
		player.call("_cycle_select", "mare")
		player.call("_cycle_select", "vapore")
		await _capture_current("cycle-progress-tablet")
		print("EXERCISE RENDER probe OK — ciclo")
		quit(0)
		return
	if "--map-only" in OS.get_cmdline_user_args():
		await _capture("map-italy-tablet", _map_node(), "mission", Vector2i(900, 600))
		player.call("_visual_select", "po")
		await _capture_current("map-italy-selected-tablet")
		print("EXERCISE RENDER probe OK — carta muta Italia")
		quit(0)
		return
	if "--hotspot-only" in OS.get_cmdline_user_args():
		await _capture("hotspot-roman-atlas-tablet", _hotspot_node(), "mission", Vector2i(900, 600))
		player.call("_visual_select", "aqueduct")
		await _capture_current("hotspot-roman-atlas-selected-tablet")
		print("EXERCISE RENDER probe OK — atlante storico romano")
		quit(0)
		return
	if "--numpad-only" in OS.get_cmdline_user_args():
		var numeric := _node("numeric_input", {
			"prompt": "Nocciola raccoglie 25 ghiande e ne usa 7. Quante ne restano?",
			"answer": "18",
		})
		await _capture("numeric-numpad-tablet", numeric, "mission", Vector2i(900, 600))
		player.call("_numpad_press", "1")
		player.call("_numpad_press", "8")
		await _capture_current("numeric-numpad-filled-tablet")
		await _capture("numeric-numpad-portrait", numeric, "mission", Vector2i(600, 900))
		print("EXERCISE RENDER probe OK — tastierino numerico landscape + portrait")
		quit(0)
		return
	await _capture("ordering-exam-desktop", _node("ordering", {
		"items": ["Osserva i dati", "Scegli la strategia", "Verifica il risultato"],
		"correctOrder": ["Osserva i dati", "Scegli la strategia", "Verifica il risultato"],
	}), "final_exam", Vector2i(1280, 720))
	var matching := _node("matching", {
		"pairs": [
			{"left": "Soggetto", "right": "chi compie l'azione"},
			{"left": "Predicato", "right": "che cosa accade"},
			{"left": "Complemento", "right": "informazione aggiunta"},
		],
	})
	await _capture("matching-tablet", matching, "mission", Vector2i(900, 600))
	player.call("_matching_left", 0)
	player.call("_matching_right", "chi compie l'azione", matching)
	await _capture_current("matching-connected-tablet")
	var classification := _node("classification", {
		"items": ["triangolo", "quattro", "cerchio", "sette"],
		"categories": ["forme", "numeri"],
		"assignments": {"triangolo": "forme", "quattro": "numeri", "cerchio": "forme", "sette": "numeri"},
	})
	await _capture("classification-tablet", classification, "mission", Vector2i(900, 600))
	player.call("_classification_assign", "triangolo", "forme")
	player.call("_classification_assign", "quattro", "numeri")
	await _capture_current("classification-snapped-tablet")
	var graph := _node("graph", {
		"points": [
			{"id": "a", "label": "A", "x": 0.12, "y": 0.20},
			{"id": "b", "label": "B", "x": 0.48, "y": 0.55},
			{"id": "c", "label": "C", "x": 0.84, "y": 0.82},
		],
		"answer": "c",
	})
	await _capture("graph-desktop", graph, "mission", Vector2i(1280, 720))
	player.call("_visual_select", "b")
	player.call("_visual_submit", graph)
	await _capture_current("graph-error-desktop")
	var circuit := _node("circuit", {
		"components": [
			{"id": "battery", "label": "PILA", "x": 0.15, "y": 0.52},
			{"id": "switch", "label": "INTERRUTTORE", "x": 0.50, "y": 0.22},
			{"id": "lamp", "label": "LAMPADA", "x": 0.84, "y": 0.52},
		],
		"connections": [["battery", "switch"], ["switch", "lamp"], ["lamp", "battery"]],
		"answer": "switch",
	})
	await _capture("circuit-desktop", circuit, "mission", Vector2i(1280, 720))
	player.call("_visual_select", "switch")
	player.call("_visual_submit", circuit)
	await _capture_current("circuit-connected-desktop")
	await _capture("notation-tablet", _notation_node(), "mission", Vector2i(900, 600))
	await _capture("cycle-tablet", _cycle_node(), "mission", Vector2i(900, 600))
	await _capture("map-italy-tablet", _map_node(), "mission", Vector2i(900, 600))
	await _capture("hotspot-roman-atlas-tablet", _hotspot_node(), "mission", Vector2i(900, 600))
	await _capture("code-debug-tablet", _node("code_debug", {
		"codeLines": ["energia = 3", "if energia = 0:", "    accendi_portale()", "mostra(energia)"],
		"answerLine": 2,
	}), "mission", Vector2i(900, 600))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2424
	var final_session := ContentManager.new().build_final_transversal_exam(24, rng)
	await _capture_session("final-transversal-desktop", final_session, Vector2i(1280, 720))
	var convergence := player.find_child("FinalConvergenceDisplay", true, false) as FinalConvergenceDisplay
	for system_index in 7:
		convergence.resolve_system(str(ApparatusConfig.SUBJECT_CYCLE[system_index]), true)
	await create_timer(0.24).timeout
	await _capture_current("final-convergence-progress-desktop")
	await _capture_session("final-transversal-tablet", final_session, Vector2i(900, 600))
	print("EXERCISE RENDER probe OK — 16 capture, inclusi notazione, carta muta, ciclo e finale animato")
	quit(0)

func _capture(name: String, node: Dictionary, kind: String, viewport_size: Vector2i) -> void:
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	player.start_session({
		"sessionId": name,
		"kind": kind,
		"subject": "geografia" if str(node.get("format", "")) == "map" else "logica",
		"nodes": [node],
		"shields": 3,
		"pace": "reasoning",
		"timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {}},
	})
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, name]))

func _capture_session(name: String, session: Dictionary, viewport_size: Vector2i) -> void:
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	player.start_session(session)
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, name]))

func _capture_current(name: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.10).timeout
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, name]))

func _capture_all_formats() -> void:
	var manager := MinigameManager.new()
	var cases := [
		["matching", "italiano", "matching", 8, ""],
		["ordering", "coding", "ordering", 8, ""],
		["classification", "scienze", "classification", 8, ""],
		["graph", "fisica", "graph", 8, ""],
		["circuit", "elettronica", "circuit", 8, ""],
		["cycle", "scienze", "cycle", 8, ""],
		["notation", "musica", "notation", 8, ""],
		["map", "geografia", "map", 8, ""],
		["hotspot", "storia", "hotspot", 8, ""],
		["code-debug", "coding", "code_debug", 8, ""],
		["number-line", "matematica", "number_line", 8, ""],
		["balance", "matematica", "balance", 8, ""],
		["timeline", "storia", "timeline", 8, ""],
		["compose", "italiano", "compose", 8, ""],
		["trace", "matematica", "trace", 8, ""],
		["clue", "scienze", "clue", 8, ""],
		["swipe-fractions", "matematica", "swipe", 13, "frazioni"],
		["swipe-verb-times", "italiano", "swipe", 12, "tempi-indicativo"],
		["swipe-verb-modes", "italiano", "swipe", 12, "modi-verbali"],
	]
	for case_data in cases:
		var name := str(case_data[0])
		var subject := str(case_data[1])
		var fmt := str(case_data[2])
		var level := int(case_data[3])
		var topic := str(case_data[4])
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("renderer:%s" % name)
		var session := manager.build_guided_minigame(subject, topic, fmt, level, rng)
		for node_data in Array(session.get("nodes", [])):
			var node: Dictionary = node_data
			if str(node.get("format", "")) == fmt:
				await _capture("all-%s-tablet" % name, node, "mission", Vector2i(900, 600))
				break
