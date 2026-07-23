extends SceneTree

## Capture GPU C-P2 dei primi due WorldProfile caricati dalla stessa scena:
## confronto gameplay con HUD e tavole pulite desktop/compatte.

const OUTPUT_DIR := "res://../artifacts/world-profiles"
const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["worlds"] = {"unlocked": [1, 2], "current": level}
	var request := NativeWorldState.default_request("world-profile-capture")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _capture_profile(level: int, viewport_size: Vector2i, suffix: String = "", show_hud: bool = true) -> Error:
	root.size = viewport_size
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var profile: Dictionary = world.get("world_profile")
	var player := world.get("player") as CharacterBody2D
	var ship: Vector2 = profile["shipEntrance"]["position"]
	player.global_position = ship + Vector2(0, 540)
	player.set_physics_process(false)
	var camera := world.get("camera") as Camera2D
	camera.position = player.global_position
	camera.position_smoothing_enabled = false
	world.get("chunks").update_stream(player.global_position)
	if not show_hud:
		var ui := world.get("ui_layer") as CanvasLayer
		if ui != null:
			ui.visible = false
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	var image := root.get_texture().get_image()
	var base_name := "world-%02d-%s" % [level, str(profile["id"]).trim_prefix("world-%02d-" % level)]
	var error := image.save_png(ProjectSettings.globalize_path(
		"%s/%s%s.png" % [OUTPUT_DIR, base_name, suffix]))
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	return error

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for level in [1, 2]:
		for capture in [
			{"size": Vector2i(1440, 900), "suffix": "", "hud": true},
			{"size": Vector2i(1440, 900), "suffix": "-desktop-clean", "hud": false},
			{"size": Vector2i(900, 600), "suffix": "-compact-clean", "hud": false},
		]:
			if await _capture_profile(level, capture["size"], str(capture["suffix"]), bool(capture["hud"])) != OK:
				push_error("WORLD PROFILE RENDER probe: cattura fallita al livello %d (%s)" % [level, str(capture["suffix"])])
				quit(2)
				return
	root.size = Vector2i(1280, 720)
	var hub := (load("res://scenes/hub.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame
	(hub.find_child("WorldMapButton", true, false) as Button).pressed.emit()
	await process_frame
	await create_timer(0.18).timeout
	var map_image := root.get_texture().get_image()
	if map_image.save_png(ProjectSettings.globalize_path("%s/world-map-level-2.png" % OUTPUT_DIR)) != OK:
		push_error("WORLD PROFILE RENDER probe: cattura mappa fallita")
		quit(2)
		return
	print("WORLD PROFILE RENDER probe OK — profili 1/2 HUD + clean desktop/compatto + mappa")
	quit(0)
