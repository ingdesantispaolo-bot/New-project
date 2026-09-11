extends SceneTree

const AUTOPLAY := preload("res://scripts/game/exercise_autoplay.gd")
const OUTPUT_ROOT := "res://../artifacts/linked-missions"
const DEFAULT_WORLD := 4
var capture_failures: Array = []
var world_level := DEFAULT_WORLD
var output_dir := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	world_level = _world_from_args()
	output_dir = "%s/world-%d" % [OUTPUT_ROOT, world_level]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	DisplayServer.window_set_size(Vector2i(1100, 740))
	root.size = Vector2i(1100, 740)
	var request := NativeWorldState.default_request("linked-missions-render")
	request["loadLocalSave"] = false
	var initial_save := GameSaveManager._default_data()
	initial_save["level"] = world_level
	initial_save["worlds"] = {"unlocked": range(1, world_level + 1), "current": world_level}
	request["initialSave"] = initial_save
	request["worldLevel"] = world_level
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
	assert(area != null, "minimissione assente dalla scena reale")
	var gameplay := world.get("gameplay") as OutdoorGameplay
	assert(int(gameplay.game_save.current_world()) == world_level)
	assert(gameplay.try_start_minimission(area.get_meta("payload", {}), str(area.get_meta("id", ""))))
	var player := world.get("exercise_player") as ExercisePlayer
	assert(bool(player.session.get("interdisciplinary", false)))
	assert(Array(player.session.get("nodes", [])).size() == 3)
	for i in 3:
		await _capture("tappa-%d" % [i + 1])
		if i == 0:
			DisplayServer.window_set_size(Vector2i(740, 1000))
			root.size = Vector2i(740, 1000)
			await _capture("tappa-1-verticale")
			DisplayServer.window_set_size(Vector2i(1100, 740))
			root.size = Vector2i(1100, 740)
			await process_frame
		AUTOPLAY.solve(player, player._nodes[player._index], true)
		await _capture("esito-%d" % [i + 1])
		player._advance()
		await process_frame
	assert(not gameplay.session_active())
	assert(gameplay.game_save.has_minimission(world_level))
	await _capture("dopo")
	if not capture_failures.is_empty():
		for failure in capture_failures:
			printerr(failure)
		quit(2)
		return
	print("LINKED MISSIONS RENDER OK — mondo %d, layout orizzontale e verticale" % world_level)
	quit(0)

func _world_from_args() -> int:
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--world="):
			return clampi(str(arg).trim_prefix("--world=").to_int(), 2, 24)
	return DEFAULT_WORLD

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	# `frame_post_draw` non viene emesso in modo affidabile dal renderer
	# headless; tre frame sono il contratto usato anche dalla sonda dei renderer.
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		capture_failures.append("%s: texture viewport assente" % label)
		return
	var captured := texture.get_image()
	if captured == null:
		capture_failures.append("%s: immagine viewport assente" % label)
		return
	var error := captured.save_png(ProjectSettings.globalize_path("%s/%s.png" % [output_dir, label]))
	if error != OK:
		capture_failures.append("%s: save_png %d" % [label, error])
