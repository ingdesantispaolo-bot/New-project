extends SceneTree

## Rilievo affiancato per C-ART-6. Non è un asset di gioco: rende il normale
## gesto di occupazione e lo stesso identico attore durante `smemora` profondo,
## così la differenza visuale può essere controllata senza aprire un dialogo.

const ACTOR := preload("res://scripts/game/npc_actor.gd")
const OUTPUT := "res://../artifacts/deep-smemora-c-art-6.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(900, 520)
	var background := ColorRect.new()
	background.color = Color("07171d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	_add_caption("GESTO NORMALE", Vector2(135, 55), Color("9fded8"))
	_add_caption("STESSO GESTO · SCOPO SPEZZATO", Vector2(500, 55), Color("ffd078"))
	_add_caption("Il corpo continua a lavorare", Vector2(120, 420), Color("cbe9e5"), 18)
	_add_caption("l'attrezzo gira · il bersaglio resta fuori", Vector2(485, 420), Color("ffd9a0"), 18)

	var resident := NpcCatalog.resident("w23-cronia")
	var normal: NpcActor = ACTOR.new()
	normal.configure("w23-cronia", resident, true)
	normal.position = Vector2(280, 265)
	root.add_child(normal)
	normal.set_activity("come ha sempre fatto")

	var deep: NpcActor = ACTOR.new()
	deep.configure("w23-cronia", resident, true)
	deep.position = Vector2(620, 265)
	root.add_child(deep)
	deep.set_activity("come ha sempre fatto")
	deep.set_deep_forgotten(true)

	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var error := root.get_texture().get_image().save_png(output_path)
	assert(error == OK, "impossibile salvare il rilievo C-ART-6")
	print("Deep smemora render probe: %s" % output_path)
	quit(0)

func _add_caption(text: String, position: Vector2, color: Color, size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
