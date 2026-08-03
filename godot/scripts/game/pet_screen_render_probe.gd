extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/pet"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	var pet := PetState.DEFAULT.duplicate(true)
	pet["grantedAtLevel"] = 1
	pet["name"] = "Briciola"
	pet["bond"] = 0.47
	pet["faces"] = ["sereno", "orgoglioso", "incoraggiante", "festa", "beato", "curioso", "concentrato"]
	pet["sessionsTogether"] = 23
	initial["pet"] = pet
	var request := NativeWorldState.default_request("pet-screen-render-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": false}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	(world.get("pet_face") as Control).emit_signal("screen_requested")
	await process_frame
	await create_timer(0.12).timeout
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/customization-tablet.png" % OUTPUT))
	var screen := world.get("pet_screen") as Control
	var scroll: ScrollContainer
	for node in screen.find_children("*", "ScrollContainer", true, false):
		scroll = node as ScrollContainer
		break
	if scroll != null:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await process_frame
		await process_frame
		image = root.get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path("%s/faces-album-tablet.png" % OUTPUT))
	print("PET SCREEN RENDER probe OK — 900x600, personalizzazione + album")
	quit(0)
