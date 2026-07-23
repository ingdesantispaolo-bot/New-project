extends SceneTree

## Capture GPU dei WorldProfile approvati, caricati dalla stessa scena:
## confronto gameplay con HUD, tavole pulite desktop/compatte e landmark.

const OUTPUT_DIR := "res://../artifacts/world-profiles"
const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 8
	initial["worlds"] = {"unlocked": range(1, 9), "current": level}
	var request := NativeWorldState.default_request("world-profile-capture")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _capture_profile(
	level: int,
	viewport_size: Vector2i,
	suffix: String = "",
	show_hud: bool = true,
	focus_landmark: bool = false
) -> Error:
	root.size = viewport_size
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	# Le capture sono anche il riferimento del tier Web/tablet.
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var profile: Dictionary = world.get("world_profile")
	var player := world.get("player") as CharacterBody2D
	var ship: Vector2 = profile["shipEntrance"]["position"]
	var hero := world.find_child("ProfileHeroLandmark", true, false) as Node2D
	player.global_position = (
		hero.global_position + Vector2(0, 80)
		if focus_landmark and hero != null
		else ship + Vector2(0, 540)
	)
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
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var web_budget := int(profile.get("performanceBudget", {}).get("web", {}).get("maxDrawCalls", 900))
	if draw_calls > 0 and draw_calls > web_budget:
		push_error("WORLD PROFILE RENDER probe: %d draw call oltre budget Web %d nel mondo %d" % [
			draw_calls, web_budget, level])
		return ERR_OUT_OF_MEMORY
	print("WORLD PROFILE RENDER — mondo %d %s: %d draw call (budget Web %d)" % [
		level, suffix if suffix != "" else "HUD", draw_calls, web_budget])
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
	for level in [5, 6, 7, 8]:
		for capture in [
			{"size": Vector2i(1440, 900), "suffix": "", "hud": true, "landmark": false},
			{"size": Vector2i(1440, 900), "suffix": "-desktop-clean", "hud": false, "landmark": false},
			{"size": Vector2i(900, 600), "suffix": "-compact-hud", "hud": true, "landmark": false},
			{"size": Vector2i(900, 600), "suffix": "-compact-clean", "hud": false, "landmark": false},
		]:
			if await _capture_profile(level, capture["size"], str(capture["suffix"]), bool(capture["hud"]), bool(capture["landmark"])) != OK:
				push_error("WORLD PROFILE RENDER probe: cattura fallita al livello %d (%s)" % [level, str(capture["suffix"])])
				quit(2)
				return
		if level in [5, 6, 7, 8]:
			if await _capture_profile(level, Vector2i(1440, 900), "-landmark-clean", false, true) != OK:
				push_error("WORLD PROFILE RENDER probe: cattura landmark fallita al livello %d" % level)
				quit(2)
				return
	print("WORLD PROFILE RENDER probe OK — ondata P5 mondi 5/8, HUD + clean desktop/compatto + landmark")
	quit(0)
