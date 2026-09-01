extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/world-challenge-hazards"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	await _capture_level(1)
	await _capture_level(24)
	print("WORLD CHALLENGE HAZARD render probe OK — rischio 1 e rischio 5 nel mondo reale")
	quit(0)

func _capture_level(level: int) -> void:
	var initial := GameSaveManager._default_data()
	initial["energy"] = 99
	initial["level"] = level
	var unlocked: Array = []
	for value in range(1, level + 1):
		unlocked.append(value)
	initial["worlds"] = {"unlocked": unlocked, "current": level}
	var request := NativeWorldState.default_request("world-hazard-render-%02d" % level)
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = level
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame
	var hazard: WorldHazard = null
	for node in get_nodes_in_group("world_challenge_hazard"):
		if node is WorldHazard and world.is_ancestor_of(node):
			hazard = node
			break
	assert(hazard != null, "pericolo specifico assente al mondo %d" % level)
	hazard.force_phase_for_audit(WorldHazard.ACTIVE)
	var player := world.get("player") as OutdoorPlayerController
	player.global_position = hazard.global_position + Vector2(0, 64)
	world.get("chunks").update_stream(player.global_position)
	var camera := world.get("camera") as Camera2D
	camera.reset_smoothing()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(
		"%s/pericolo-mondo-%02d-rischio-%d.png" % [OUTPUT, level, hazard.threat_tier]))
	world.queue_free()
	await process_frame
	await process_frame
