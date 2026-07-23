extends SceneTree

## Headless smoke test del loop nativo Godot:
## mondo -> tesoro -> missione -> gate -> ingresso nave -> esame -> riattivazione.
## L'esame non è più raggiungibile dal mondo esterno.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/outdoor_world.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
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
	assert(mission_subject == str(scene.get("runtime").get("focusSubject", "")),
		"l'incontro procedurale deve essere una missione della materia-focus")
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
	# Completiamo le restanti evidenze della materia-focus necessarie al gate e
	# verifichiamo poi che l'esame resti disponibile soltanto nella nave.
	var guard := 0
	while not progression.can_repair() and guard < 40:
		progression.record_mission(focus_subject, 3, 3, 0, true)
		# Evidenza per-argomento (dimensione COPERTURA): tre topic distinti coprono
		# qualsiasi materia-focus indipendentemente dalla dimensione del suo banco.
		progression.record_topic_stats(focus_subject, {"a": {"seen": 1, "correct": 1}, "b": {"seen": 1, "correct": 1}, "c": {"seen": 1, "correct": 1}})
		guard += 1
	assert(progression.can_repair(), "il gate dell'apparato deve aprirsi con missioni, padronanza e copertura")
	assert(not scene.has_method("start_final_exam"), "il mondo non deve esporre l'esame finale")
	scene.get("gameplay").call("_emit_state")
	await process_frame
	var portal := scene.find_child("ExitPortal", true, false) as Node2D
	assert(portal != null and bool(portal.get("gate_ready")), "l'ingresso nave deve segnalare il gate pronto")
	var portal_area := _find_area(scene, "portal", "portal")
	assert(portal_area != null, "l'ingresso nave deve essere interagibile")
	player.global_position = portal.global_position
	scene.call("on_interactable_entered", portal_area, player)
	scene.call("_interact")
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://scenes/hub.tscn",
		"il gate pronto deve proseguire nella nave")
	var hub = current_scene
	assert(bool(hub.get("controller").state().get("ready", false)), "la nave deve ricevere il gate pronto")
	hub.call("_repair_action")
	await process_frame
	var exam: ExercisePlayer = hub.get("exercise_player")
	assert(exam.visible and str(exam.session.get("kind", "")) == "final_exam")
	await hub.call("_on_exam_finished", {
		"kind": "final_exam", "subject": focus_subject, "correct": 3,
		"total": 3, "passed": true, "energyGained": 76,
	})
	var final_save: GameSaveManager = hub.get("save")
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
