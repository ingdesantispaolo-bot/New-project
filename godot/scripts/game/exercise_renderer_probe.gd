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
	node.merge(extra)
	return node

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	player = PLAYER.new()
	root.add_child(player)
	await _capture("ordering-exam-desktop", _node("ordering", {
		"items": ["Osserva i dati", "Scegli la strategia", "Verifica il risultato"],
		"correctOrder": ["Osserva i dati", "Scegli la strategia", "Verifica il risultato"],
	}), "final_exam", Vector2i(1280, 720))
	await _capture("matching-tablet", _node("matching", {
		"pairs": [
			{"left": "Soggetto", "right": "chi compie l'azione"},
			{"left": "Predicato", "right": "che cosa accade"},
			{"left": "Complemento", "right": "informazione aggiunta"},
		],
	}), "mission", Vector2i(900, 600))
	await _capture("classification-tablet", _node("classification", {
		"items": ["triangolo", "quattro", "cerchio", "sette"],
		"categories": ["forme", "numeri"],
		"assignments": {"triangolo": "forme", "quattro": "numeri", "cerchio": "forme", "sette": "numeri"},
	}), "mission", Vector2i(900, 600))
	await _capture("graph-desktop", _node("graph", {
		"points": [
			{"id": "a", "label": "A", "x": 0.12, "y": 0.20},
			{"id": "b", "label": "B", "x": 0.48, "y": 0.55},
			{"id": "c", "label": "C", "x": 0.84, "y": 0.82},
		],
		"answer": "c",
	}), "mission", Vector2i(1280, 720))
	await _capture("circuit-desktop", _node("circuit", {
		"components": [
			{"id": "battery", "label": "PILA", "x": 0.15, "y": 0.52},
			{"id": "switch", "label": "INTERRUTTORE", "x": 0.50, "y": 0.22},
			{"id": "lamp", "label": "LAMPADA", "x": 0.84, "y": 0.52},
		],
		"connections": [["battery", "switch"], ["switch", "lamp"], ["lamp", "battery"]],
		"answer": "switch",
	}), "mission", Vector2i(1280, 720))
	await _capture("code-debug-tablet", _node("code_debug", {
		"codeLines": ["energia = 3", "if energia = 0:", "    accendi_portale()", "mostra(energia)"],
		"answerLine": 2,
	}), "mission", Vector2i(900, 600))
	print("EXERCISE RENDER probe OK — 6 capture desktop/tablet")
	quit(0)

func _capture(name: String, node: Dictionary, kind: String, viewport_size: Vector2i) -> void:
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	player.start_session({
		"sessionId": name,
		"kind": kind,
		"subject": "logica",
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
