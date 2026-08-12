extends SceneTree

## Sesto: sbagliare lascia riprovare; una traccia esterna corretta continua a
## guidare il braccio quando la stanza viene velata.

const TRACE_MINIGAME_PANEL := preload("res://scripts/ui/trace_minigame_panel.gd")

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 600)
	var pannello := TRACE_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w03-sesto"), true)
	await process_frame
	for segnale in [1, 0, 2]:
		(pannello.find_child("TraceSignal_%d" % segnale, true, false) as Button).pressed.emit()
	(pannello.find_child("TraceVeilButton", true, false) as Button).pressed.emit()
	assert(esito["value"].is_empty(), "la traccia errata non deve chiudere il gioco")
	for segnale in [0, 2, 1]:
		(pannello.find_child("TraceSignal_%d" % segnale, true, false) as Button).pressed.emit()
	(pannello.find_child("TraceVeilButton", true, false) as Button).pressed.emit()
	assert(esito["value"] == [true, 3, 3], "la traccia corretta non ha guidato il braccio: %s" % str(esito["value"]))
	print("TRACE MINIGAME audit VERDE")
	quit()
