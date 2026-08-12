extends SceneTree

## Prova giocata del Circuito mutante: un errore non resetta, la sequenza cambia
## davvero fra schemi e tre lampade accese chiudono il pilot di Ciro.

const OK_MESSAGE := "CIRCUIT MINIGAME audit VERDE"

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 600)
	var parametri: Dictionary = CharacterMinigameCatalog.scheda("w08-ciro").get("parametri", {})
	assert(int(parametri.get("schemi", 0)) == 3, "al mondo 8 Ciro deve affrontare tre schemi")
	assert(int(parametri.get("passaggi", 0)) == 3, "al mondo 8 ogni schema deve avere tre passaggi")

	var firme: Array[String] = []
	for round_index in 3:
		var quadro := CircuitMinigameBoard.new()
		root.add_child(quadro)
		quadro.configura(round_index, 3, true)
		await process_frame
		var firma := ""
		for passaggio in 3:
			firma += str(quadro.riga_corretta(passaggio))
		firme.append(firma)
		quadro.queue_free()
		await process_frame
	assert(firme[0] != firme[1] and firme[1] != firme[2] and firme[0] != firme[2],
		"i tre schemi ripetono la stessa fotografia: %s" % str(firme))

	var pannello := CircuitMinigamePanel.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, completati: int, totale: int):
		esito["value"] = [vinto, completati, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w08-ciro"), true)
	await process_frame
	var primo_quadro := pannello.find_child("CircuitBoard", true, false) as CircuitMinigameBoard
	var riga_sbagliata := posmod(primo_quadro.riga_corretta(0) + 1, 3)
	var sbagliato := primo_quadro.find_child("CircuitSwitch_0_%d" % riga_sbagliata, true, false) as Button
	sbagliato.pressed.emit()
	assert(primo_quadro.passaggio_attivo() == 0, "un nodo non alimentato fa avanzare la corrente")

	for schema in 3:
		var quadro := pannello.find_child("CircuitBoard", true, false) as CircuitMinigameBoard
		assert(is_instance_valid(quadro), "schema %d non costruito" % (schema + 1))
		for passaggio in 3:
			var corretto := quadro.find_child(
				"CircuitSwitch_%d_%d" % [passaggio, quadro.riga_corretta(passaggio)], true, false) as Button
			assert(is_instance_valid(corretto), "interruttore corretto assente")
			corretto.pressed.emit()
		if schema < 2:
			await process_frame
	assert(esito["value"] == [true, 3, 3], "tre lampade non chiudono il pilot: %s" % str(esito["value"]))
	print(OK_MESSAGE)
	quit()
