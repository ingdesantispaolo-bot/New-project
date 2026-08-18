extends SceneTree

## Evidenza visuale C-P6: leggibilità di Eli, posa impulso e quattro tier delle
## anomalie sul renderer reale del mondo.

const OUTPUT_DIR := "res://../artifacts/eli-enemies"
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const ENEMY_SCRIPT := preload("res://scripts/world_enemy.gd")

func _init() -> void:
	call_deferred("_run")

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["powerRuns"] = 140
	initial["energy"] = 500
	initial["worlds"] = {"unlocked": range(1, 25), "current": 24}
	var request := NativeWorldState.default_request("eli-enemy-render")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 24
	return request

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, name]))
	assert(error == OK, "cattura Eli/anomalie fallita: %s" % name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1440, 900)
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", _request())
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame

	var player := world.get("player") as OutdoorPlayerController
	var camera := world.get("camera") as Camera2D
	var world_layer := world.get("world_layer") as Node2D
	for enemy in get_nodes_in_group("world_enemy"):
		enemy.queue_free()
	await process_frame

	var center := world.get("world_profile").get("spawn", Vector2.ZERO) as Vector2
	player.global_position = center
	player.set_physics_process(false)
	camera.global_position = center
	camera.position_smoothing_enabled = false
	var offsets := [
		Vector2(-300, -120), Vector2(-100, -120),
		Vector2(100, -120), Vector2(300, -120),
	]
	var colors := [Color("6be7d6"), Color("8fa7ff"), Color("e9a86d"), Color("f6c85f")]
	for index in range(4):
		var enemy := ENEMY_SCRIPT.new()
		enemy.name = "TierGallery_%d" % (index + 1)
		enemy.setup(world, center + offsets[index], 1 + index * 6, "logica", colors[index], index)
		enemy.set_physics_process(false)
		world_layer.add_child(enemy)

	await _capture("01-eli-tier-desktop.png")
	player.velocity = Vector2.RIGHT * 100.0
	player.call("_animate", 0.24)
	await _capture("02-eli-cammino-desktop.png")
	player.velocity = Vector2.ZERO
	player.play_pulse_action()
	player.call("_animate", 0.01)
	world.call("_spawn_combat_pulse_visual")
	await process_frame
	var pulse := world.find_child("EliCombatPulse", true, false) as Node2D
	if pulse != null:
		pulse.get_tree().paused = true
	await _capture("03-eli-impulso-desktop.png")
	paused = false

	root.size = Vector2i(900, 600)
	await _capture("04-eli-tier-tablet.png")
	world.queue_free()
	await process_frame
	print("ELI/ENEMY RENDER probe OK — idle, cammino, impulso e tier 1→4 desktop/tablet")
	quit(0)
