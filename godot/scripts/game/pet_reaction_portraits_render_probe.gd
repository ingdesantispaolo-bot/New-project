extends SceneTree

## Confronto UI delle undici identita': a sinistra riposo, a destra il sorriso
## generativo mostrato dopo una carezza. Verifica insieme corrispondenza specie,
## ritaglio del volto e leggibilita' alla dimensione reale dell'HUD.

const FACE_WIDGET := preload("res://scripts/ui/pet_face_widget.gd")
const OUTPUT := "res://../artifacts/pet/reaction-portraits-sheet.png"
const KINDS := [
	"dog", "cat", "rabbit", "spark", "comet", "orbit",
	"satellite", "prisma", "luma", "guardiano", "codex",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../artifacts/pet"))
	DisplayServer.window_set_size(Vector2i(1440, 610))
	root.size = Vector2i(1440, 610)
	var backdrop := ColorRect.new()
	backdrop.color = Color("071b22")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var title := Label.new()
	title.text = "OGNI CUSTODE CONSERVA LA PROPRIA IDENTITA'"
	title.position = Vector2(26, 16)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("ffd75e"))
	backdrop.add_child(title)

	for index in KINDS.size():
		var column := index % 6
		var row := index / 6
		var card := VBoxContainer.new()
		card.position = Vector2(18 + column * 232, 58 + row * 266)
		card.custom_minimum_size = Vector2(226, 252)
		backdrop.add_child(card)
		var name_label := Label.new()
		name_label.text = str(KINDS[index]).capitalize()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color("dff7f2"))
		card.add_child(name_label)
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 0)
		card.add_child(row_box)
		for face in ["sereno", "beato", "stupito"]:
			var preview := FACE_WIDGET.new()
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.configure("", PetState.LIVERIES[0], "vivace", str(face), 1.0, PetState.all_faces(), true, str(KINDS[index]))
			preview.set_preview_face(str(face))
			row_box.add_child(preview)
		var caption := Label.new()
		caption.text = "riposo      carezza      stupore"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 11)
		caption.add_theme_color_override("font_color", Color("9fc4bb"))
		card.add_child(caption)

	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("PET REACTION PORTRAITS probe: salvataggio fallito (%d)" % error)
		quit(1)
		return
	print("PET REACTION PORTRAITS probe OK - 11 identita' x 3 stati")
	quit(0)
