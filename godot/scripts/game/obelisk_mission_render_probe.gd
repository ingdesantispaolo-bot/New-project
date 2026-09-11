extends SceneTree

const AUTOPLAY := preload("res://scripts/game/exercise_autoplay.gd")
const OUTPUT := "res://../artifacts/obelisk-mission"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(1100, 740))
	root.size = Vector2i(1100, 740)
	var request := NativeWorldState.default_request("obelisk-linked-render")
	request["loadLocalSave"] = false
	request["initialSave"] = GameSaveManager._default_data()
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := (load("res://scenes/outdoor_world.tscn") as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var area: Area2D = null
	for node in get_nodes_in_group("enigma_poi"):
		if node is Area2D and world.is_ancestor_of(node) and str(node.get_meta("kind", "")) == "minimission":
			area = node
			break
	assert(area != null, "obelisco assente dalla scena reale")
	var gameplay := world.get("gameplay") as OutdoorGameplay
	assert(gameplay.try_start_minimission(area.get_meta("payload", {}), str(area.get_meta("id", ""))))
	var player := world.get("exercise_player") as ExercisePlayer
	assert(bool(player.session.get("interdisciplinary", false)))
	for i in 3:
		await _capture("tappa-%d" % [i + 1])
		if i == 1:
			DisplayServer.window_set_size(Vector2i(740, 1000))
			root.size = Vector2i(740, 1000)
			await _capture("tappa-2-verticale")
			DisplayServer.window_set_size(Vector2i(1100, 740))
			root.size = Vector2i(1100, 740)
			await process_frame
		AUTOPLAY.solve(player, player._nodes[player._index], true)
		await _capture("esito-%d" % [i + 1])
		player._advance()
		await process_frame
	assert(not gameplay.session_active())
	assert(gameplay.game_save.has_minimission(1))
	assert(not player.visible)
	await _capture("mondo-dopo")
	print("OBELISK RENDER OK — scena reale, tre tappe, ritorno al mondo")
	quit(0)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var captured := root.get_texture().get_image()
	assert(captured.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, label])) == OK)
