extends SceneTree

## Prova giocata di **Corde sotto le dita**. Verifica che Oreste abbia un banco
## distinto, che l'errore non chiuda un gioco di riflessione, che l'annulla sia
## reale e che l'intero percorso sia vincibile senza audio.

const PANEL := preload("res://scripts/ui/vibration_minigame_panel.gd")

var errori: Array[String] = []

func _pretendi(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	var scheda := CharacterMinigameCatalog.scheda("w06-oreste")
	_pretendi(str(scheda.get("archetipo", "")) == CharacterMinigameCatalog.ARCHETIPO_VIBRAZIONE,
		"Oreste non usa l'archetipo della vibrazione")
	_pretendi(str(scheda.get("forma", "")) == CharacterMinigameCatalog.FORMA_RIFLESSIONE,
		"Oreste non è un gioco di riflessione")

	var pannello := PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, presi: int, totale: int): esito["value"] = [vinto, presi, totale])
	pannello.avvia(scheda, true)
	await process_frame

	_pretendi(pannello.find_child("VibrationBoard", true, false) is Control,
		"manca il banco vettoriale di palmo e corde")
	_pretendi(pannello.find_child("VibrationClock", true, false) == null,
		"il gioco di riflessione mostra un cronometro")
	var replay := pannello.find_child("VibrationReplayButton", true, false) as Button
	_pretendi(is_instance_valid(replay) and replay.text.contains("OSSERVA"),
		"il tremito non si può riprodurre visivamente")
	_pretendi(_conta_audio(pannello) == 0,
		"il confronto dipende da un nodo audio")

	# Una scelta può essere ritirata prima del confronto.
	(pannello.find_child("VibrationString_0", true, false) as Button).pressed.emit()
	(pannello.find_child("VibrationUndoButton", true, false) as Button).pressed.emit()
	(pannello.find_child("VibrationCompareButton", true, false) as Button).pressed.emit()
	var stato := pannello.find_child("VibrationStatus", true, false) as Label
	_pretendi(is_instance_valid(stato) and stato.text.contains("Prima scegli"),
		"annullare non restituisce davvero la scelta")

	# Primo errore: non deve terminare la partita né cambiare round.
	(pannello.find_child("VibrationString_0", true, false) as Button).pressed.emit()
	(pannello.find_child("VibrationCompareButton", true, false) as Button).pressed.emit()
	_pretendi(esito["value"].is_empty(), "un solo errore chiude il gioco")
	_pretendi(stato.text.contains("forza e ordine"),
		"l'errore non insegna che cosa confrontare")

	# Strategia buona: segue l'identità dei pattern, non il numero della corda.
	for giusta in [1, 0, 2]:
		(pannello.find_child("VibrationString_%d" % giusta, true, false) as Button).pressed.emit()
		(pannello.find_child("VibrationCompareButton", true, false) as Button).pressed.emit()
		await process_frame
	_pretendi(not esito["value"].is_empty() and bool(esito["value"][0]),
		"i tre accoppiamenti corretti non vincono: %s" % str(esito["value"]))
	_pretendi(not esito["value"].is_empty() and int(esito["value"][1]) == int(esito["value"][2]),
		"la vittoria non completa tutti i tremiti")

	pannello.queue_free()
	await process_frame
	if errori.is_empty():
		print("VIBRATION MINIGAME audit VERDE")
	else:
		printerr("VIBRATION MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)

func _conta_audio(nodo: Node) -> int:
	var totale := 1 if nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D else 0
	for figlio in nodo.get_children():
		totale += _conta_audio(figlio)
	return totale
