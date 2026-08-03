extends SceneTree

## Tavola GPU delle dieci espressioni del Custode. Serve a confrontarle tutte
## alla stessa dimensione reale dell'HUD e a evitare differenze affidate al colore.

const FACE_WIDGET := preload("res://scripts/ui/pet_face_widget.gd")
const OUTPUT := "res://../artifacts/pet/faces-sheet.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../artifacts/pet"))
	DisplayServer.window_set_size(Vector2i(900, 300))
	root.size = Vector2i(900, 300)
	var backdrop := ColorRect.new()
	backdrop.color = Color("071b22")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var title := Label.new()
	title.text = "LE FACCE DEL CUSTODE"
	title.position = Vector2(28, 18)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("ffd75e"))
	backdrop.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.position = Vector2(18, 64)
	grid.add_theme_constant_override("h_separation", 10)
	backdrop.add_child(grid)
	for face in PetState.all_faces():
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(76, 126)
		var preview := FACE_WIDGET.new()
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.configure("", PetState.LIVERIES[0], "vivace", str(face), 1.0, PetState.all_faces(), true)
		preview.set_preview_face(str(face))
		card.add_child(preview)
		var caption := Label.new()
		caption.text = str(face).capitalize()
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.add_theme_font_size_override("font_size", 11)
		caption.add_theme_color_override("font_color", Color("dff7f2"))
		card.add_child(caption)
		grid.add_child(card)
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("PET FACES RENDER probe: salvataggio fallito (%d)" % error)
		quit(1)
		return
	print("PET FACES RENDER probe OK — 10 espressioni a dimensione HUD")
	quit(0)
