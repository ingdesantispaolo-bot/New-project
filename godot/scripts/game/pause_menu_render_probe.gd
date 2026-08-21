extends SceneTree

## Sonda visuale del menu di pausa. Salva viste reali in `artifacts/pausa/`.
##
## Serve qui più che altrove per una ragione precisa: questo pannello è l'unico
## posto del gioco in cui un bambino può **perdere** qualcosa toccando il
## pulsante sbagliato. Se «RIAVVIA IL MONDO» e «MENU PRINCIPALE» si assomigliano
## troppo, o se la riga che spiega che cosa resta non si legge, il difetto non è
## un pixel storto: è un pomeriggio di gioco buttato. Una cosa così non si
## giudica leggendo il codice.
##
## Le viste: la pausa nel mondo, la conferma del riavvio, l'elenco dei giocatori
## aperto da dentro la pausa, la pausa nella nave, e la resa ad alto contrasto.
##
## Uso: godot --path godot --script res://scripts/game/pause_menu_render_probe.gd

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const HUB_SCENE := preload("res://scenes/hub.tscn")
const OUTPUT := "res://../artifacts/pausa"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)

	# 1 · La pausa nel mondo aperto: la vista che conta, perché è quella in cui
	# fino a ieri non c'era nessuna porta.
	var mondo := _apri_mondo(3, false)
	mondo.call("_apri_pausa")
	await _posa()
	var pausa = mondo.get("pause_menu")
	assert(pausa != null and pausa.aperto(), "la pausa non si apre nel mondo")
	assert(paused, "la pausa non ferma il mondo")
	if await _scatta("pausa-mondo.png") != OK:
		push_error("PAUSA RENDER: renderer grafico non disponibile")
		quit(2)
		return

	# 2 · La conferma del riavvio: l'unico comando che sposta, e l'unico che
	# chiede. Qui si legge se la riga che dice **che cosa resta** si legge.
	_premi(pausa, "PauseRestartButton")
	await _posa()
	assert(pausa.find_child("PauseRestartConfirmButton", true, false) != null,
		"il riavvio non chiede conferma")
	if await _scatta("pausa-conferma-riavvio.png") != OK:
		quit(2)
		return

	# 3 · L'elenco dei giocatori, aperto da dentro la pausa. È il pannello del
	# menu d'avvio, e deve restare leggibile sopra un mondo invece che sopra la
	# schermata del titolo.
	_premi(pausa, "PauseRestartCancelButton")
	await _posa()
	_premi(pausa, "PauseSwitchPlayerButton")
	await _posa()
	assert(pausa.find_child("PauseProfilePanel", true, false) != null,
		"CAMBIA GIOCATORE non apre l'elenco")
	if await _scatta("pausa-giocatori.png") != OK:
		quit(2)
		return

	# 4 · Ad alto contrasto, dove la cornice deve diventare bianca e piena.
	pausa.chiudi()
	await _posa()
	assert(not paused, "RIPRENDI non fa ripartire il mondo")
	_congeda(mondo)
	var mondo_hc := _apri_mondo(12, true)
	mondo_hc.call("_apri_pausa")
	await _posa()
	if await _scatta("pausa-contrasto.png") != OK:
		quit(2)
		return
	_congeda(mondo_hc)

	# 5 · La stessa pausa dalla nave: stessi comandi, stesso ordine.
	var nave := HUB_SCENE.instantiate()
	root.add_child(nave)
	await _posa()
	nave.call("_apri_pausa")
	await _posa()
	var pausa_nave = nave.get("pause_menu")
	assert(pausa_nave != null and pausa_nave.aperto(), "la pausa non si apre nella nave")
	if await _scatta("pausa-nave.png") != OK:
		quit(2)
		return
	pausa_nave.congeda()
	_congeda(nave)

	print("PAUSE MENU render probe OK - artifacts/pausa")
	quit(0)

func _apri_mondo(livello: int, alto_contrasto: bool) -> Node:
	var salvataggio := GameSaveManager._default_data()
	salvataggio["level"] = livello
	salvataggio["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var richiesta := NativeWorldState.default_request("pausa-render-%d" % livello)
	richiesta["loadLocalSave"] = false
	richiesta["initialSave"] = salvataggio
	richiesta["worldLevel"] = livello
	richiesta["accessibility"] = {"highContrast": alto_contrasto, "reducedMotion": true}
	richiesta["accessibilityExplicit"] = true
	var mondo := WORLD_SCENE.instantiate()
	mondo.set("launch_request_override", richiesta)
	mondo.set("launch_stream_radius_override", 1)
	root.add_child(mondo)
	return mondo

## Il pulsante si preme per nome, come lo premerebbe un dito: passare per il
## metodo privato salterebbe proprio il cablaggio che questa sonda deve provare.
func _premi(pannello: Node, nome: String) -> void:
	var bottone := pannello.find_child(nome, true, false) as Button
	assert(bottone != null, "pulsante assente: %s" % nome)
	bottone.pressed.emit()

## Il mondo resta in pausa finché la sonda non lo congeda: un albero fermo
## lasciato in eredità alla vista successiva la fotograferebbe immobile.
func _congeda(scena: Node) -> void:
	paused = false
	root.remove_child(scena)
	scena.queue_free()

func _posa() -> void:
	await process_frame
	await process_frame
	await create_timer(0.12).timeout

func _scatta(nome_file: String) -> Error:
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		return ERR_UNAVAILABLE
	var immagine := texture.get_image()
	if immagine == null:
		return ERR_UNAVAILABLE
	return immagine.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT, nome_file]))
