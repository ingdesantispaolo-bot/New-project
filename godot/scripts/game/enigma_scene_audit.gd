extends SceneTree

## C-P6: regressione del percorso di interazione degli enigmi.
##
## Gli enigmi non vivono più tutti nella stessa scena: ogni WorldProfile ne
## riceve almeno uno dal MissionEventDirector. L'audit apre quindi i 24 profili
## reali e, su ciascuno, prova il flusso tablet completo:
##   tap sul POI -> avvicinamento -> apertura automatica dell'esercizio.
## Verifica inoltre il pulsante contestuale accessibile e mantiene una prova del
## tasto E su un profilo, senza usarlo come unico criterio di giocabilità.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const PROFILE_COUNT := ApparatusConfig.MAX_LEVEL
const TABLET_VIEWPORT := Vector2i(900, 600)

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = level
	initial["worlds"] = {"unlocked": range(1, level + 1), "current": level}
	var request := NativeWorldState.default_request("c-p6-enigma-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world(level: int) -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _first_enigma(world: Node) -> Area2D:
	var profile_level := int(Dictionary(world.get("world_profile")).get("level", 0))
	for node in get_nodes_in_group("enigma_poi"):
		# La scena corrente è l'unico mondo vivo; il controllo sul parent evita
		# comunque di accettare nodi in coda di eliminazione.
		if node is Area2D and not node.is_queued_for_deletion() and world.is_ancestor_of(node):
			return node as Area2D
	assert(false, "mondo %d senza enigma del MissionEventDirector" % profile_level)
	return null

func _failed_result(exercise: ExercisePlayer) -> Dictionary:
	return {
		"kind": str(exercise.session.get("kind", "enigma")),
		"subject": str(exercise.session.get("subject", "matematica")),
		"correct": 0,
		"total": maxi(1, Array(exercise.session.get("nodes", [])).size()),
		"passed": false,
		"energyGained": 0,
		"topicStats": {},
	}

func _close_failed_session(world: Node, exercise: ExercisePlayer) -> void:
	assert(exercise.visible, "la sessione da chiudere non è visibile")
	world.call("_on_exercise_finished", _failed_result(exercise))
	await process_frame
	assert(not exercise.visible, "ExercisePlayer non si chiude dopo l'esito")
	assert(not world.get("gameplay").session_active(), "contesto enigma rimasto attivo")

func _test_touch_path(world: Node, area: Area2D) -> void:
	var player := world.get("player") as CharacterBody2D
	var exercise := world.get("exercise_player") as ExercisePlayer
	var gameplay := world.get("gameplay") as OutdoorGameplay
	assert(player != null and exercise != null and gameplay != null, "servizi outdoor mancanti")
	gameplay.game_save.data["energy"] = 0

	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = world.get_viewport().get_canvas_transform() * area.global_position
	world.call("_unhandled_input", tap)
	assert(world.get("pending_touch_interaction") == area,
		"il tap non memorizza l'enigma %s" % str(area.get_meta("id", "")))
	var expected_approach: Vector2 = world.call("_touch_approach_position", area)
	assert(player.get("touch_target").distance_to(expected_approach) < 0.01,
		"il tap non guida Eli alla distanza di interazione")

	# Simula l'arrivo ottenuto dal movimento reale, senza teleportare il target:
	# è la stessa callback eseguita dal processo della scena.
	player.global_position = expected_approach
	world.call("_update_pending_touch_interaction")
	await process_frame
	assert(exercise.visible, "l'arrivo non apre l'enigma %s" % str(area.get_meta("id", "")))
	assert(gameplay.session_active(), "sessione enigma non avviata dopo il tap")
	assert(str(exercise.session.get("kind", "")) == "enigma", "il POI apre il tipo di sessione errato")
	await _close_failed_session(world, exercise)

func _test_context_button(world: Node, area: Area2D) -> void:
	var player := world.get("player") as CharacterBody2D
	var exercise := world.get("exercise_player") as ExercisePlayer
	var button := world.find_child("ContextInteractButton", true, false) as Button
	assert(button != null, "pulsante contestuale assente")
	player.global_position = area.global_position
	world.call("on_interactable_entered", area, player)
	await process_frame
	assert(button.visible and not button.disabled, "pulsante contestuale non disponibile vicino all'enigma")
	assert(button.text == "RICOSTRUISCI", "azione contestuale enigma non riconoscibile")
	assert(button.size.x >= 320.0 and button.size.y >= 64.0, "bersaglio touch inferiore al minimo C-P6")
	button.pressed.emit()
	await process_frame
	assert(exercise.visible and world.get("gameplay").session_active(),
		"RICOSTRUISCI non apre ExercisePlayer")
	await _close_failed_session(world, exercise)

func _test_keyboard_path(world: Node, area: Area2D) -> void:
	var player := world.get("player") as CharacterBody2D
	var exercise := world.get("exercise_player") as ExercisePlayer
	player.global_position = area.global_position
	world.call("on_interactable_entered", area, player)
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	world.call("_input", press)
	await process_frame
	assert(exercise.visible and world.get("gameplay").session_active(),
		"l'azione tastiera interact non apre l'enigma")
	await _close_failed_session(world, exercise)

func _dispose_world(world: Node) -> void:
	if is_instance_valid(world):
		root.remove_child(world)
		world.queue_free()
	current_scene = null
	await process_frame
	await process_frame

func _cleanup_audio() -> void:
	var audio := root.get_node_or_null("NativeAudio")
	if audio == null:
		return
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
				child.free()
	audio.set("_stream_cache", {})

func _run() -> void:
	root.size = TABLET_VIEWPORT
	var tested_profiles := 0
	var tested_ids: Array[String] = []
	for level in range(1, PROFILE_COUNT + 1):
		var world := await _open_world(level)
		var area := _first_enigma(world)
		assert(area != null, "profilo %d privo di enigma" % level)
		var enigma_id := str(area.get_meta("id", ""))
		assert(enigma_id != "" and not tested_ids.has(enigma_id), "ID enigma non univoco: %s" % enigma_id)
		tested_ids.append(enigma_id)
		await _test_touch_path(world, area)
		await _test_context_button(world, area)
		if level == 1:
			await _test_keyboard_path(world, area)
		tested_profiles += 1
		await _dispose_world(world)

	assert(tested_profiles == PROFILE_COUNT, "non sono stati provati tutti i 24 profili")
	_cleanup_audio()
	await create_timer(0.15).timeout
	print("ENIGMA SCENE audit OK — 24 profili, tap+avvicinamento, pulsante contestuale e tastiera")
	quit(0)
