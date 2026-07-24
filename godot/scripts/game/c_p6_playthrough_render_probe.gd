extends SceneTree

## Evidenza GPU riproducibile del playthrough C-P6:
## boot -> mondo -> missione touch -> nave -> esame -> mondo successivo.
##
## La preparazione del gate serve soltanto ad accorciare la sonda visuale; la
## progressione naturale 1->24 è verificata da progression_1to24_audit.gd.

const OUTPUT_DIR := "res://../artifacts/c-p6-playthrough"
const BOOT_SCENE := "res://scenes/boot_menu.tscn"
const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name]))
	assert(error == OK, "cattura C-P6 fallita: %s" % file_name)

func _reset_local_save() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.save()

func _prepare_gate(world: Node) -> void:
	var save: GameSaveManager = world.get("game_save")
	var progression: ProgressionManager = world.get("progression_manager")
	var gate := progression.current_gate()
	var subject := str(gate.get("subject", "matematica"))
	for _index in range(int(gate.get("missionsRequired", 1))):
		save.add_mission(subject)
	save.set_mastery(subject, float(gate.get("masteryThreshold", 0.7)))
	var topic_target := GateReadiness.coverage_target(world.get("content_manager").subject_topic_count(subject))
	for index in range(maxi(topic_target, 1)):
		save.set_topic_mastery(subject, "c-p6-topic-%d" % index, 1.0)
	world.get("gameplay").call("_emit_state")

func _portal_area(world: Node) -> Area2D:
	var portal := world.find_child("ExitPortal", true, false)
	if portal == null:
		return null
	for child in portal.get_children():
		if child is Area2D and str(child.get_meta("kind", "")) == "portal":
			return child as Area2D
	return null

func _first_gate_mission(world: Node) -> Area2D:
	for node in get_nodes_in_group("mission_poi"):
		if not node is Area2D or not world.is_ancestor_of(node):
			continue
		var area := node as Area2D
		if str(area.get_meta("kind", "")) != "encounter":
			continue
		if bool(Dictionary(area.get_meta("directorEvent", {})).get("countsForGate", false)):
			return area
	return null

func _assert_touch_targets(node: Node) -> void:
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():
			var button := child as Button
			assert(button.size.y >= 44.0,
				"bersaglio touch troppo basso: %s = %.1f px" % [button.name, button.size.y])
		_assert_touch_targets(child)

func _cleanup() -> void:
	if is_instance_valid(current_scene):
		var ending_scene := current_scene
		root.remove_child(ending_scene)
		ending_scene.queue_free()
	current_scene = null
	await process_frame
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

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_reset_local_save()

	root.size = Vector2i(1280, 720)
	var boot := (load(BOOT_SCENE) as PackedScene).instantiate()
	root.add_child(boot)
	current_scene = boot
	await process_frame
	await _capture("01-boot-desktop.png")
	root.size = Vector2i(900, 600)
	await _capture("02-boot-tablet.png")
	var play_button := boot.find_child("PlayButton", true, false) as Button
	assert(play_button != null and play_button.size.y >= 58.0)
	play_button.pressed.emit()
	await process_frame
	await process_frame

	var world := current_scene
	assert(world != null and world.scene_file_path == WORLD_SCENE)
	await _capture("03-world-tablet.png")
	var player := world.get("player") as CharacterBody2D
	var mission := _first_gate_mission(world)
	assert(player != null and mission != null, "missione touch non disponibile")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = world.get_viewport().get_canvas_transform() * mission.global_position
	world.call("_unhandled_input", tap)
	player.global_position = world.call("_touch_approach_position", mission)
	world.call("_update_pending_touch_interaction")
	await process_frame
	var exercise := world.get("exercise_player") as ExercisePlayer
	assert(exercise.visible, "la missione touch non apre l'esercizio")
	assert(str(exercise.session.get("kind", "")) == "mission",
		"la tappa C-P6 deve provare una missione ordinaria")
	_assert_touch_targets(exercise)
	await _capture("04-missione-tablet.png")
	world.call("_on_exercise_finished", {
		"kind": str(exercise.session.get("kind", "mission")),
		"subject": str(exercise.session.get("subject", "matematica")),
		"correct": 0,
		"total": maxi(1, Array(exercise.session.get("nodes", [])).size()),
		"passed": false,
		"energyGained": 0,
		"topicStats": {},
	})
	await process_frame

	_prepare_gate(world)
	await process_frame
	var portal := world.find_child("ExitPortal", true, false) as Node2D
	var portal_area := _portal_area(world)
	assert(portal != null and portal_area != null, "ingresso nave non disponibile")
	player.global_position = portal.global_position
	world.call("on_interactable_entered", portal_area, player)
	await process_frame
	var context_button := world.find_child("ContextInteractButton", true, false) as Button
	assert(context_button.visible and context_button.text == "ENTRA NELLA NAVE")
	await _capture("05-ingresso-nave-tablet.png")
	context_button.pressed.emit()
	await process_frame
	await process_frame

	var hub := current_scene
	assert(hub != null and hub.scene_file_path == HUB_SCENE)
	_assert_touch_targets(hub)
	await _capture("06-nave-tablet.png")
	hub.call("_repair_action")
	await process_frame
	var exam := hub.get("exercise_player") as ExercisePlayer
	assert(exam.visible and str(exam.session.get("kind", "")) == "final_exam")
	_assert_touch_targets(exam)
	await _capture("07-esame-tablet.png")
	var subject := str(exam.session.get("subject", "matematica"))
	await hub.call("_on_exam_finished", {
		"kind": "final_exam",
		"subject": subject,
		"correct": 3,
		"total": 3,
		"passed": true,
		"energyGained": 30,
		"topicStats": {},
	})
	assert(hub.get("save").level() == 2, "l'esame non avanza al mondo successivo")
	hub.call("_return_to_world")
	await process_frame
	await process_frame

	var next_world := current_scene
	assert(next_world != null and next_world.scene_file_path == WORLD_SCENE)
	assert(int(next_world.get("world_profile").get("level", 0)) == 2,
		"il ritorno post-esame non apre il mondo 2")
	await _capture("08-mondo-successivo-tablet.png")
	await _cleanup()
	print("C-P6 PLAYTHROUGH RENDER probe OK — desktop boot + percorso tablet completo fino al mondo 2")
	quit(0)
