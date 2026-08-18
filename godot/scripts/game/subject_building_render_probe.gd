extends SceneTree

## Cattura il pilot illustrato della Casa del Conto insieme alla stazione di
## attivita'. Non e' un audit semantico: serve a controllare scala, silhouette,
## sovrapposizioni e leggibilita' nel vero renderer del mondo.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/buildings"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("subject-building-render-probe")
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
	var casa: Node2D = null
	for building in Array(world.get("world_buildings")):
		if str((building as Node2D).get_meta("building_role", "")) == "work_home":
			casa = building as Node2D
			break
	assert(casa != null, "Casa del mestiere assente dal pilot")
	var player := world.get("player") as OutdoorPlayerController
	player.global_position = casa.global_position + Vector2(0, 150)
	world.get("chunks").update_stream(player.global_position)
	var camera := world.get("camera") as Camera2D
	camera.reset_smoothing()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("%s/world1-casa-conto-tablet.png" % OUTPUT))
	print("SUBJECT BUILDING RENDER probe OK — Casa del Conto 900x600")
	quit(0)
