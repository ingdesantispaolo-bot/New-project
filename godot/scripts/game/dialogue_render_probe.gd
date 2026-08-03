extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/dialogue"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("dialogue-render-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": false}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	# The tablet viewport extends beyond the spawn chunk. Load its neighbours so
	# the dialogue snapshot keeps the world visible behind the overlay.
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame
	var player := world.get("player") as OutdoorPlayerController
	var target: Area2D = null
	for node in get_nodes_in_group("npc_actor"):
		if str(node.get_meta("id", "")) == "w01-tobia":
			target = node as Area2D
			break
	assert(target != null, "Tobia non istanziato")
	target.global_position = player.global_position + Vector2(52, 0)
	world.call("on_interactable_entered", target, player)
	world.call("_interact")
	await process_frame
	var box := world.get("dialogue_box") as Control
	box.call("advance") # completa la macchina da scrivere, non cambia pagina
	await process_frame
	await create_timer(0.10).timeout
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/world1-tobia-tablet.png" % OUTPUT))
	print("DIALOGUE RENDER probe OK — Tobia 900x600")
	quit(0)
