extends SceneTree

## Cattura i cinque stadi di NORA affiancati. Non decide se sono belli: serve a
## poter giudicare la progressione con gli occhi, invece di dedurla dai numeri di
## un audit. Un poligono texturizzato con le UV sbagliate supera qualunque
## asserzione e disegna un disco nero.
##
## Uso: godot --headless --path godot --script res://scripts/game/nora_presence_render_probe.gd

const OUTPUT := "res://../artifacts/nora-presence"
const NoraPortrait = preload("res://scripts/ui/nora_portrait.gd")

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	# Il progetto rende in «canvas_items» su 1280x720 e riscala: una cattura a
	# taglia reale finirebbe rimpicciolita in un angolo. Qui lo stretch non serve.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED

	# Striscia con i cinque stadi in fila, alla taglia reale della HUD e a una
	# taglia grande: il ritratto vive in entrambe, e a 82 px si perde per primo.
	await _striscia("stadi-hud-82.png", 82)
	await _striscia("stadi-grande-220.png", 220)
	print("NORA presence render probe OK")
	quit()

func _striscia(file_name: String, lato: int) -> void:
	var margine := 12
	var larghezza := (lato + margine) * 5 + margine
	root.size = Vector2i(larghezza, lato + margine * 2)
	var sfondo := ColorRect.new()
	sfondo.color = Color("071018")
	sfondo.size = Vector2(larghezza, lato + margine * 2)
	root.add_child(sfondo)

	var ritratti: Array = []
	for i in range(5):
		var s: Dictionary = NoraPortrait.STADI[i]
		var r = NoraPortrait.new()
		root.add_child(r)
		# Dopo l'aggiunta all'albero, non prima: `_ready()` fissa la dimensione
		# minima, e una taglia assegnata prima viene riscritta da quella.
		r.custom_minimum_size = Vector2(lato, lato)
		r.size = Vector2(lato, lato)
		r.position = Vector2(margine + i * (lato + margine), margine)
		r.set_integrity(float(s["apparati"]) / 24.0, true, 0.5)
		ritratti.append(r)

	await process_frame
	# La taglia dei Control si assesta in un passaggio di layout differito: va
	# riscritta DOPO il primo frame, o resta la dimensione minima.
	for i in range(5):
		var r: Control = ritratti[i]
		r.size = Vector2(lato, lato)
		r.position = Vector2(margine + i * (lato + margine), margine)
	await process_frame
	await process_frame
	print("  %s: viewport %s, ritratto %s" % [file_name, str(root.size), str((ritratti[0] as Control).size)])
	var immagine := root.get_texture().get_image()
	var errore := immagine.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT, file_name]))
	assert(errore == OK, "impossibile salvare %s" % file_name)
	for r in ritratti:
		r.queue_free()
	sfondo.queue_free()
	await process_frame
