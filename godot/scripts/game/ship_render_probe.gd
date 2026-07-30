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
	await process_frame
	_set_completed_levels(hub, 0)
	hub.call("_select_room", "central")
	await _settle()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if await _capture("nave-01-inerte-wide.png") != OK:
		push_error("SHIP RENDER probe: renderer grafico non disponibile")
		quit(2)
		return

	_set_completed_levels(hub, 8)
	hub.call("_select_room", "reactor")
	await _settle()
	if await _capture("nave-02-riattivazione-wide.png") != OK:
		quit(2)
		return
	var reactor_after := ShipActivationModel.activation_for_room(hub.get("save"), "reactor")
	var reactor_before := reactor_after.duplicate()
	reactor_before["stage"] = maxi(0, int(reactor_after.get("stage", 1)) - 1)
	reactor_before["ratio"] = maxf(0.0, float(reactor_after.get("ratio", 0.2)) - 0.12)
	hub.call("_play_reactivation_sequence", "reactor", reactor_before, reactor_after)
	await create_timer(0.62).timeout
	if await _capture("nave-02b-regia-accensione-wide.png") != OK:
		quit(2)
		return
	await create_timer(2.4).timeout

	root.size = Vector2i(1024, 720)
	await _settle()
	_set_completed_levels(hub, ApparatusConfig.MAX_LEVEL)
	hub.call("_select_room", "glyphs")
	await _settle()
	if await _capture("nave-03-piena-potenza-compact.png") != OK:
		quit(2)
		return
	var final_after := ShipActivationModel.activation_for_room(hub.get("save"), "glyphs")
	var final_before := final_after.duplicate()
	final_before["stage"] = 4
	final_before["ratio"] = 0.92
	hub.call("_play_reactivation_sequence", "glyphs", final_before, final_after)
	await create_timer(1.72).timeout
	if await _capture("nave-04-finale-rotta-aperta-compact.png") != OK:
		quit(2)
		return
	print("SHIP RENDER probe OK - 5 capture in artifacts/ship, incluse regia e finale")
	quit(0)

func _set_completed_levels(hub: Node, completed_levels: int) -> void:
	var save: GameSaveManager = hub.get("save")
	save.data = GameSaveManager._default_data()
	for level in range(1, mini(completed_levels, ApparatusConfig.MAX_LEVEL) + 1):
		var gate := ApparatusConfig.level_gate(level)
		save.set_apparatus_repaired(str(gate["apparatus"]), level)
	save.set_level(mini(completed_levels, ApparatusConfig.MAX_LEVEL) + 1)
	var controller: HubController = hub.get("controller")
	controller.refresh()

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
