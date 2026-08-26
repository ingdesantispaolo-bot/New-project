extends SceneTree

## Tavola delle sedici combinelle a meta' gesto. Non e' un test logico: rende
## insieme silhouette, oggetti di scena e specie diverse per una verifica
## visiva rapida dopo ogni modifica al motore del Custode.

const COMPANION := preload("res://scripts/pet_companion.gd")
const OUTPUT := "res://../artifacts/pet/antics-sheet.png"
const KINDS := [
	"dog", "cat", "rabbit", "spark", "comet", "orbit", "satellite", "prisma",
	"luma", "guardiano", "codex",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../artifacts/pet"))
	DisplayServer.window_set_size(Vector2i(920, 700))
	root.size = Vector2i(920, 700)
	var backdrop := ColorRect.new()
	backdrop.color = Color("071b22")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var title := Label.new()
	title.text = "LE 16 COMBINELLE DEI CUSTODI"
	title.position = Vector2(28, 16)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("ffd75e"))
	backdrop.add_child(title)

	var antics: Array = OutdoorPetCompanion.VISUALIZED_ANTICS
	for index in antics.size():
		var column := index % 4
		var row := index / 4
		var card := ColorRect.new()
		card.color = Color("102c35") if (row + column) % 2 == 0 else Color("0c252d")
		card.position = Vector2(18 + column * 224, 58 + row * 156)
		card.size = Vector2(214, 146)
		backdrop.add_child(card)
		var caption := Label.new()
		caption.text = str(antics[index]).capitalize()
		caption.position = Vector2(10, 9)
		caption.add_theme_font_size_override("font_size", 14)
		caption.add_theme_color_override("font_color", Color("dff7f2"))
		card.add_child(caption)

		var pet := COMPANION.new()
		pet.position = Vector2(107, 105)
		card.add_child(pet)
		pet.setup(str(KINDS[index % KINDS.size()]), Color("f6c85f"), null, "vivace", false)
		var antic_id := str(antics[index])
		var duration := float(Dictionary(PetAntics.CATALOG[antic_id]).get("duration", 3.0))
		pet.call("_on_antic_started", antic_id, duration)
		pet.set("_antic_time", duration * 0.45)
		pet.call("_process", 0.0)

	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("PET ANTICS RENDER probe: salvataggio fallito (%d)" % error)
		quit(1)
		return
	print("PET ANTICS RENDER probe OK - 16 pose in una tavola")
	quit(0)
