extends SceneTree

## Sonda visuale del chiavistello. Salva viste reali in `artifacts/lock/` per
## giudicare composizione e leggibilità con gli occhi invece che a parole — un
## minigioco che si vede decine di volte per mondo si valuta guardandolo.
##
## Cattura le quattro situazioni che contano: il primo mondo (numeri piccoli,
## quattro tessere), l'ultimo (sei tessere, operazioni doppie), il momento in cui
## un dente è già scattato e una tessera è stata spenta da un errore, e la resa
## ad alto contrasto.
##
## Uso: godot --path godot --script res://scripts/game/lock_render_probe.gd

const OUTPUT_DIR := "res://../artifacts/lock"

func _init() -> void:
	root.size = Vector2i(1100, 820)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var host := Control.new()
	host.name = "LockRenderHost"
	host.size = root.get_visible_rect().size
	root.add_child(host)
	var sfondo := ColorRect.new()
	sfondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sfondo.color = Color("123322")
	host.add_child(sfondo)

	var pannello := LockMinigamePanel.new()
	host.add_child(pannello)
	await process_frame

	# 1 · Mondo 1: il primo chiavistello, quattro tessere e numeri piccoli.
	pannello.avvia(LockChallenge.regole(1, TreasureCatalog.TIPO_LASCITO), "forziere chiuso con cura",
		20260814, false, false)
	await _settle()
	if await _capture("chiavistello-mondo-01.png") != OK:
		push_error("LOCK RENDER: renderer grafico non disponibile")
		quit(2)
		return

	# 2 · Mondo 24: sei tessere, operazioni doppie, il quadrante più affollato che
	# il gioco produce. È la vista che dice se la composizione regge.
	pannello.avvia(LockChallenge.regole(24, TreasureCatalog.TIPO_LASCITO), "forziere chiuso con cura",
		777, false, false)
	await _settle()
	if await _capture("chiavistello-mondo-24.png") != OK:
		quit(2)
		return

	# 3 · A metà: un dente scattato, una tessera spenta da un errore.
	pannello.avvia(LockChallenge.regole(12, TreasureCatalog.TIPO_LASCITO), "forziere chiuso con cura",
		4242, false, false)
	await process_frame
	var sbagliata := (int(pannello.call("indice_giusto")) + 1) % 5
	pannello.call("scegli", sbagliata)
	await _settle()
	if await _capture("chiavistello-in-corso.png") != OK:
		quit(2)
		return

	# 4 · Alto contrasto e movimento ridotto: la stessa prova, l'altra resa.
	pannello.avvia(LockChallenge.regole(12, TreasureCatalog.TIPO_LASCITO, true), "cassa",
		4242, true, true)
	await _settle()
	if await _capture("chiavistello-contrasto.png") != OK:
		quit(2)
		return

	print("LOCK RENDER probe OK - artifacts/lock")
	quit(0)

func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.14).timeout

func _capture(file_name: String) -> Error:
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		return ERR_UNAVAILABLE
	return image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name]))
