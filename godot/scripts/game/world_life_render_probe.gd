extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/world-life"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("world-life-render-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame

	var life = world.get("world_life")
	var anchors: Dictionary = life.get("anchors")
	for actor in world.get("npc_actors"):
		var npc_id := str(actor.get_meta("id", ""))
		actor.global_position = Dictionary(anchors[npc_id])["ritrovo"]
	var player := world.get("player") as OutdoorPlayerController
	player.global_position = world.call("ritrovo_position") + Vector2(190, 175)
	world.set("day_clock", WorldSky.DURATA * 0.23) # fascia alba: il Ritrovo si popola
	world.get("chunks").update_stream(player.global_position)
	var camera := world.get("camera") as Camera2D
	camera.reset_smoothing()
	life.update("alba", player.global_position, Rect2(player.global_position - Vector2(450, 300), Vector2(900, 600)), 0.1)
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("%s/world1-ritrovo-conversation-tablet.png" % OUTPUT))
	print("WORLD LIFE RENDER probe OK - conversazione al Ritrovo 900x600")
	quit(0)
