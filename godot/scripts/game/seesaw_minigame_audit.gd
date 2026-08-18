extends SceneTree

## Prova giocata di Tilla: previsione obbligatoria, errore recuperabile e tre
## equilibri identici nella regola anche se cambia chi guarda.

const SEESAW_PANEL := preload("res://scripts/ui/seesaw_minigame_panel.gd")

var errori: Array[String] = []

func _init() -> void:
	call_deferred("_esegui")

func _fallisci(testo: String) -> void:
	errori.append(testo)

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	# La funzione fisica non riceve né usa l'osservatore.
	if SEESAW_PANEL.esito(2, 4, 4, 2) != 0 or SEESAW_PANEL.esito(2, 4, 4, 4) != 1:
		_fallisci("pesi e distanze non determinano correttamente l'esito")
	var pannello := SEESAW_PANEL.new()
	root.add_child(pannello)
	var esito_finale := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito_finale["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w05-tilla"), true)
	await process_frame

	# Una previsione sbagliata mostra l'esito e lascia correggere.
	(pannello.find_child("SeesawPredict_1", true, false) as Button).pressed.emit()
	(pannello.find_child("SeesawRunButton", true, false) as Button).pressed.emit()
	if not esito_finale["value"].is_empty():
		_fallisci("la prima previsione sbagliata chiude il gioco")

	for soluzione in [2, 3, 4]:
		(pannello.find_child("SeesawDistance_%d" % soluzione, true, false) as Button).pressed.emit()
		(pannello.find_child("SeesawPredict_1", true, false) as Button).pressed.emit()
		(pannello.find_child("SeesawRunButton", true, false) as Button).pressed.emit()
		await process_frame
	if esito_finale["value"] != [true, 3, 3]:
		_fallisci("i tre equilibri non chiudono il gioco: %s" % str(esito_finale["value"]))

	if errori.is_empty():
		print("SEESAW MINIGAME audit VERDE")
	else:
		printerr("SEESAW MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
