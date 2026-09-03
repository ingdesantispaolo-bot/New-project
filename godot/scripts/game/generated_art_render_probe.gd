extends SceneTree

const OUTPUT_DIR := "res://../artifacts/generated-art"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(900, 700)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture_intro(1)
	await _capture_intro(24)
	await _capture_resident("w01-tobia", "resident-authored-tobia")
	await _capture_resident("w18-bea", "resident-subject-music")
	await _capture_duel(24)
	print("GENERATED ART render probe OK — intro, residenti e duello")
	quit(0)

func _capture_intro(level: int) -> void:
	var panel := WorldIntroPanel.new()
	panel.livello = level
	root.add_child(panel)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(
		"%s/intro-world-%02d.png" % [OUTPUT_DIR, level])
	var error := image.save_png(path)
	assert(error == OK, "Impossibile salvare %s" % path)
	root.remove_child(panel)
	panel.queue_free()
	await process_frame

func _capture_resident(resident_id: String, filename: String) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("315f59")
	backdrop.size = Vector2(root.size)
	root.add_child(backdrop)
	var visual := ResidentConsequenceVisual.new()
	visual.configure(resident_id, 2, false, true)
	visual.position = Vector2(root.size) * 0.5
	root.add_child(visual)
	await process_frame
	await RenderingServer.frame_post_draw
	await _save_frame("%s/%s.png" % [OUTPUT_DIR, filename])
	root.remove_child(visual)
	root.remove_child(backdrop)
	visual.queue_free()
	backdrop.queue_free()
	await process_frame

func _capture_duel(level: int) -> void:
	root.size = Vector2i(1280, 720)
	var duel := GuardianDuelPanel.new()
	root.add_child(duel)
	await process_frame
	duel.avvia(GuardianDuel.regole(level, 3, 2), "Guardiano", 42024, true, false)
	await process_frame
	await RenderingServer.frame_post_draw
	await _save_frame("%s/duel-world-%02d.png" % [OUTPUT_DIR, level])
	root.remove_child(duel)
	duel.queue_free()
	await process_frame

func _save_frame(relative_path: String) -> void:
	var path := ProjectSettings.globalize_path(relative_path)
	var error := root.get_texture().get_image().save_png(path)
	assert(error == OK, "Impossibile salvare %s" % path)
