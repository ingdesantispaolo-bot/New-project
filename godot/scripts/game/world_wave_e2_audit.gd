extends SceneTree

## Gate E2: mondo 24 e finale devono funzionare come un solo flusso. Verifica
## identità visuale, dodici settori, esame trasversale live, Cuore in cinque fasi,
## riparazione completa, beat finale di NORA e ritorno al mondo rivisitabile.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _request_for_world_24() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["worlds"] = {"unlocked": range(1, 25), "current": 24}
	var request := NativeWorldState.default_request("gate-e2-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world_24() -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for_world_24())
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _assert_world_24(world: Node) -> void:
	var profile: Dictionary = world.get("world_profile")
	assert(str(profile.get("id", "")) == "world-24-cuore")
	assert(str(profile.get("soundscape", "")) == "coro-dei-sistemi")
	var chunks: OutdoorChunkManager = world.get("chunks")
	var composition: WorldCompositionData = chunks.composition
	assert(composition.visual_theme == "first_heart")
	assert(composition.paths.size() >= 5, "servono ingresso e tre firme convergenti")
	assert(composition.waters.is_empty(), "il Cuore è un santuario asciutto")
	assert(composition.protected_corridors.size() == 1, "corridoio nave non protetto")
	assert(composition.identity_regions.size() == 13, "nucleo + dodici settori richiesti")
	var sector_count := 0
	var pylon_count := 0
	for region in composition.identity_regions:
		if str(region.get("kind", "")) == "system_sector":
			sector_count += 1
	for prop in composition.identity_props:
		if str(prop.get("kind", "")) == "system_pylon":
			pylon_count += 1
	assert(sector_count == 12 and pylon_count == 12, "i dodici sistemi non sono visibili nella mappa")
	var portal := world.find_child("ExitPortal", true, false) as Node2D
	assert(portal != null and portal.global_position.distance_to(profile["shipEntrance"]["position"]) < 0.01)
	assert(world.find_child("ShipEntrance_system_pylon", true, false) != null)
	var hero := world.find_child("ProfileHeroLandmark", true, false) as Node2D
	assert(hero != null and str(hero.get_meta("landmark_kind", "")) == "firstHeart")
	assert(hero.find_child("LandmarkFirstHeartArt", true, false) != null)
	var reaction := world.find_child("ProfileEnvironmentTransform", true, false)
	assert(reaction != null and Array(reaction.get("active_parts")).size() == 5,
		"il Cuore deve mostrare esattamente cinque fasi")
	assert(ResourceLoader.exists("res://assets/cuore-primi-underpaint-v1.png"))
	var texture := load("res://assets/cuore-primi-landmark-v1.png") as Texture2D
	assert(texture != null)
	var image := texture.get_image()
	assert(image != null and image.get_pixel(0, 0).a < 0.05, "landmark senza alpha reale")

func _prepare_final_gate(save: GameSaveManager, content: ContentManager) -> void:
	save.data = GameSaveManager._default_data()
	save.set_level(24)
	save.data["worlds"] = {"unlocked": range(1, 25), "current": 24}
	for level in range(1, 24):
		var old_gate := ApparatusConfig.level_gate(level)
		save.set_apparatus_repaired(str(old_gate["apparatus"]), level)
	var gate := ApparatusConfig.level_gate(24)
	var subject := str(gate["subject"])
	for _mission in int(gate["missionsRequired"]):
		save.add_mission(subject)
	save.set_mastery(subject, float(gate["masteryThreshold"]))
	var topic_target := GateReadiness.coverage_target(content.subject_topic_count(subject))
	for index in maxi(topic_target, 1):
		save.set_topic_mastery(subject, "gate-e2-topic-%d" % index, 1.0)

func _assert_live_finale() -> void:
	var hub := (load(HUB_SCENE) as PackedScene).instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame
	var save: GameSaveManager = hub.get("save")
	var content: ContentManager = hub.get("content")
	_prepare_final_gate(save, content)
	var controller: HubController = hub.get("controller")
	controller.refresh()
	assert(controller.progression.can_repair(), "gate 24 non pronto nella fixture live")
	hub.call("_start_exam")
	var player: ExercisePlayer = hub.get("exercise_player")
	assert(player.visible and bool(player.session.get("transversal", false)))
	assert(Array(player.session.get("systems", [])).size() == 12)
	assert(int(player.session.get("shields", 0)) > 12, "il finale deve attraversare tutti i sistemi")
	assert(bool(player.session.get("completeAllSystems", false)),
		"gli errori non devono troncare il finale prima del dodicesimo sistema")
	var display: FinalConvergenceDisplay = player.find_child("FinalConvergenceDisplay", true, false)
	assert(display != null)
	for system in ApparatusConfig.SUBJECT_CYCLE:
		display.resolve_system(str(system), true)
	display.resolve_system("sintesi", true)
	assert(display.resolved_system_count() == 12 and display.heart_stage() == 5)
	assert(display.synthesis_resolved, "sintesi non visualizzata")

	await hub.call("_on_exam_finished", {
		"sessionId": "final-transversal-exam",
		"kind": "final_exam",
		"passed": true,
		"subject": "trasversale",
		"correct": 13,
		"total": 13,
		"seconds": 120.0,
		"systemsResolved": Array(ApparatusConfig.SUBJECT_CYCLE).duplicate(),
		"synthesisResolved": true,
	})
	assert(save.level() == 25 and controller.progression.is_complete())
	for room_id in ShipRoomCatalog.ids():
		var activation := ShipActivationModel.activation_for_room(save, str(room_id))
		assert(int(activation["completed"]) == int(activation["total"]),
			"ponte non completo: %s" % room_id)
	NoraState.sync_from_progress(save)
	assert(is_equal_approx(NoraState.integrity(save), 1.0))
	assert(NoraState.memory(save) == 24)
	var nora_line := hub.find_child("NoraShipLine", true, false) as Label
	assert(nora_line != null and nora_line.text == NarrativeManager.FINAL_BEAT)
	assert(save.current_world() == 24 and save.is_world_unlocked(24))

	hub.call("_return_to_world")
	await process_frame
	await process_frame
	var returned := current_scene
	assert(returned != null and returned != hub, "ritorno dalla nave non eseguito")
	var returned_profile: Dictionary = returned.get("world_profile")
	assert(int(returned_profile.get("level", 0)) == 24)
	assert(returned.get("player") != null, "mondo finale non giocabile dopo i titoli")
	root.remove_child(returned)
	returned.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	display = null
	player = null
	controller = null
	content = null
	save = null
	hub = null
	returned = null

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
	root.size = Vector2i(1280, 720)
	var world := await _open_world_24()
	_assert_world_24(world)
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await _assert_live_finale()
	_cleanup_audio()
	await process_frame
	await create_timer(0.15).timeout
	print("GATE E2 audit OK — mondo 24, 12 sistemi, Cuore 5 fasi, nave completa, NORA finale e ritorno giocabile")
	quit(0)
