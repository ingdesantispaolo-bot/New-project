extends SceneTree

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")

## Regressione del blocco Web sull'ultimo Avanti: gioca un enigma corretto nella
## scena reale, chiude la sessione e ripete subito l'input. L'esito deve essere
## emesso una volta sola e il mondo deve tornare interattivo.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("exercise-completion-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame

	var area: Area2D = null
	for node in get_nodes_in_group("enigma_poi"):
		if node is Area2D and world.is_ancestor_of(node) \
				and str(node.get_meta("kind", "")) == "enigma":
			area = node
			break
	assert(area != null, "enigma assente")
	var gameplay := world.get("gameplay") as OutdoorGameplay
	assert(gameplay.try_start_enigma(
		area.get_meta("payload", {}), str(area.get_meta("id", ""))),
		"enigma non avviato")
	await process_frame

	var exercise := world.get("exercise_player") as ExercisePlayer
	var signals := {"emitted": 0}
	exercise.session_finished.connect(func(_result): signals["emitted"] += 1)
	var total := Array(exercise.session.get("nodes", [])).size()
	for index in total:
		Autoplay.solve(exercise, exercise._nodes[exercise._index], true)
		if index < total - 1:
			exercise._advance()
	exercise._advance()
	# Simula touch + click sintetico nello stesso frame.
	exercise._advance()
	await process_frame

	assert(int(signals["emitted"]) == 1,
		"l'ultimo Avanti ha emesso %d esiti" % int(signals["emitted"]))
	assert(not exercise.visible, "ExercisePlayer ancora visibile dopo il completamento")
	assert(not gameplay.session_active(), "contesto sessione ancora attivo")
	assert(Array(world.get("result").get("completedEncounterIds", [])).has(
		str(area.get_meta("id", ""))), "enigma corretto non registrato")
	print("EXERCISE COMPLETION audit OK - ultimo Avanti idempotente")
	quit(0)
