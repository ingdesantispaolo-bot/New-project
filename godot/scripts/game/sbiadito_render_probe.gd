extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/sbiaditi"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 7
	initial["worlds"] = {"unlocked": range(1, 8), "current": 7}
	var request := NativeWorldState.default_request("sbiadito-render-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 7
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame
	var player := world.get("player") as OutdoorPlayerController
	var enemies := get_nodes_in_group("world_enemy")
	assert(enemies.size() >= 2, "servono due Sbiaditi per il confronto")
	var normal := enemies[0] as CharacterBody2D
	var stabilized := enemies[1] as CharacterBody2D
	normal.global_position = player.global_position + Vector2(-150, -60)
	stabilized.global_position = player.global_position + Vector2(150, -60)
	for enemy in [normal, stabilized]:
		enemy.set("anchor", enemy.global_position)
		enemy.set_physics_process(false)
	stabilized.set("reduced_motion", true)
	stabilized.call("stun", 30.0)
	world.get("chunks").update_stream(player.global_position)
	var camera := world.get("camera") as Camera2D
	camera.reset_smoothing()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("%s/world7-normal-and-stabilized-tablet.png" % OUTPUT))
	print("SBIADITO RENDER probe OK - normale e stabilizzato 900x600")
	quit(0)
