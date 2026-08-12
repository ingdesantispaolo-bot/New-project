extends SceneTree

## Prova giocata di Ruggine: una sequenza errata si può correggere; quella
## giusta viene riusata per tutto il lotto e chiude il gioco.

const CYCLE_MINIGAME_PANEL := preload("res://scripts/ui/cycle_minigame_panel.gd")

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 600)
	var pannello := CYCLE_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w03-ruggine"), true)
	await process_frame
	for comando in [0, 2, 1]:
		(pannello.find_child("CycleCommand_%d" % comando, true, false) as Button).pressed.emit()
	(pannello.find_child("CycleRunButton", true, false) as Button).pressed.emit()
	assert(esito["value"].is_empty(), "una sequenza errata non deve chiudere il gioco")
	for comando in [0, 1, 2]:
		(pannello.find_child("CycleCommand_%d" % comando, true, false) as Button).pressed.emit()
	(pannello.find_child("CycleRunButton", true, false) as Button).pressed.emit()
	assert(esito["value"] == [true, 3, 3], "il ciclo giusto non ha liberato tutto il nastro: %s" % str(esito["value"]))
	print("CYCLE MINIGAME audit VERDE")
	quit()
