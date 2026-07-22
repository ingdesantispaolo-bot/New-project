extends SceneTree

## Headless smoke test del loop nativo Godot:
## spawn world -> collect treasure -> start native mission -> complete it.
## L'incontro resta nella scena e non effettua redirect a runtime esterni.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/outdoor_world.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var chunks: Dictionary = scene.get("chunks").get("loaded")
	var origin: Dictionary = chunks["chunk-0_0"]["data"]
	var player: Node = scene.get("player")
	# C-16: il profilo Godot-root nasce con 0 energia. Il primo esercizio deve
	# comunque aprirsi come ingresso di recupero, senza costo fantasma.
	scene.get("game_save").data["energy"] = 0

	var treasure: Dictionary = origin["treasures"][0]
	var treasure_area := _find_area(scene, "treasure", str(treasure["id"]))
	assert(treasure_area != null)
	player.position = Vector2(treasure["x"], treasure["y"])
	scene.call("on_interactable_entered", treasure_area, player)
	scene.call("_interact")
	var treasure_result: Dictionary = scene.get("result")
	assert(treasure_result["collectedTreasureIds"].has(treasure["id"]))
	assert(int(treasure_result["energyEarned"]) == 0)
	assert(int(treasure_result["fragmentsEarned"]) > 0)

	var encounter: Dictionary = origin["encounters"][0]
	var encounter_area := _find_area(scene, "encounter", str(encounter["id"]))
	assert(encounter_area != null)
	player.position = Vector2(encounter["x"], encounter["y"])
	scene.call("on_interactable_entered", encounter_area, player)
	scene.call("_interact")
	var exercise: ExercisePlayer = scene.get("exercise_player")
	assert(exercise != null and exercise.visible, "ExercisePlayer deve aprirsi in-scena")
	assert(str(exercise.session.get("kind", "")) == "mission")
	var mission_subject := str(exercise.session.get("subject", ""))
	assert(ContentManager.BANKS.has(mission_subject), "l'incontro deve instradare una materia disponibile")
	var subject_missions_before := int(scene.get("game_save").missions_of(mission_subject))
	var pending_result: Dictionary = scene.get("result")
	assert(int(pending_result["energySpent"]) == 0, "ingresso di recupero gratuito a energia zero")
	scene.call("_on_exercise_finished", {
		"kind": "mission", "subject": mission_subject, "correct": 3,
		"total": 3, "passed": true, "energyGained": 60,
	})
	var completed_result: Dictionary = scene.get("result")
	assert(not completed_result.has("pendingEncounter"))
	assert(completed_result["completedEncounterIds"].has(encounter["id"]))
	assert(int(completed_result["energyEarned"]) == 60)
	assert(int(scene.get("game_save").missions_of(mission_subject)) == subject_missions_before + 1)
	var progression: ProgressionManager = scene.get("progression_manager")
	var gate_before := progression.current_gate()
	var initial_level := int(gate_before["level"])
	var focus_subject := str(gate_before["subject"])
	var focus_apparatus := str(gate_before["apparatus"])
	# Il primo incontro puo allenare una materia diversa dalla materia-focus del
	# livello. Completiamo soltanto le missioni della materia-focus necessarie al
	# gate, verificando cosi sia il routing multi-materia sia l'esame corrente.
	var guard := 0
	while not progression.can_repair() and guard < 20:
		progression.record_mission(focus_subject, 3, 3, 0, true)
		guard += 1
	assert(progression.can_repair(), "il gate dell'apparato deve aprirsi con missioni e mastery richieste")
	assert(bool(scene.call("start_final_exam")), "l'esame finale deve essere avviabile in Godot")
	var exam: ExercisePlayer = scene.get("exercise_player")
	assert(exam.visible and str(exam.session.get("kind", "")) == "final_exam")
	scene.call("_on_exercise_finished", {
		"kind": "final_exam", "subject": focus_subject, "correct": 3,
		"total": 3, "passed": true, "energyGained": 76,
	})
	var final_save: GameSaveManager = scene.get("game_save")
	assert(final_save.level() == initial_level + 1, "l'esame deve far avanzare il livello")
	assert(int(final_save.data["apparatus"][focus_apparatus]["repairedLevel"]) == initial_level)
	print("Outdoor Godot native mission + final exam round-trip smoke OK")
	quit(0)

func _find_area(node: Node, kind: String, id: String) -> Area2D:
	for child in node.get_children():
		if child is Area2D and str(child.get_meta("kind", "")) == kind and str(child.get_meta("id", "")) == id:
			return child
		var nested := _find_area(child, kind, id)
		if nested != null:
			return nested
	return null
