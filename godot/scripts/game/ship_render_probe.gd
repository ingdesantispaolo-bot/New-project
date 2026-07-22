extends SceneTree

## Sonda GPU della nave. Produce screenshot delle viste reali usate per la
## revisione visiva, senza mock o segnali emessi programmaticamente.

const OUTPUT_DIR := "res://../artifacts/ship"
const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var hub := (load(HUB_SCENE) as PackedScene).instantiate()
	root.add_child(hub)
	current_scene = hub
	await _settle()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if await _capture("nave-ponte-centrale-wide.png") != OK:
		push_error("SHIP RENDER probe: renderer grafico non disponibile")
		quit(2)
		return

	hub.call("_select_room", "reactor")
	await _settle()
	if await _capture("nave-reattore-wide.png") != OK:
		quit(2)
		return

	root.size = Vector2i(1024, 720)
	await _settle()
	hub.call("_select_room", "glyphs")
	await _settle()
	if await _capture("nave-glifi-compact.png") != OK:
		quit(2)
		return
	print("SHIP RENDER probe OK - artifacts/ship")
	quit(0)

func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.12).timeout

func _capture(file_name: String) -> Error:
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		return ERR_UNAVAILABLE
	return image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name]))
