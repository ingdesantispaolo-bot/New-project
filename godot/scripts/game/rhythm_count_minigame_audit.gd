extends SceneTree

## Regressione giocabile della conta di Ersilia: completa le tre strofe tramite
## gli stessi pulsanti del bambino, verificando annulla, assenza di cronometro e
## conclusione. Non controlla solo i dati: attraversa davvero il pannello.

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	var scheda := CharacterMinigameCatalog.scheda("w01-ersilia")
	assert(not scheda.is_empty(), "Ersilia non ha la sua conta")
	assert(str(scheda.get("archetipo", "")) == CharacterMinigameCatalog.ARCHETIPO_RITMO,
		"Ersilia non usa l'archetipo ritmo")
	assert(float(Dictionary(scheda.get("parametri", {})).get("secondi", -1.0)) == 0.0,
		"la conta di riflessione non deve avere un timer")

	var pannello := RhythmCountPanel.new()
	root.add_child(pannello)
	var esito := {"ricevuto": false, "vinto": false, "completati": 0, "totale": 0}
	pannello.risolto.connect(func(vinto: bool, completati: int, totale: int):
		esito["ricevuto"] = true
		esito["vinto"] = vinto
		esito["completati"] = completati
		esito["totale"] = totale)
	pannello.avvia(scheda, true)
	await process_frame
	assert(pannello.find_child("RhythmClock", true, false) == null, "compare un cronometro")

	# Annulla deve restituire davvero la pagnotta al banco.
	var primo := pannello.find_child("RhythmLoaf_0", true, false) as Button
	var annulla := pannello.find_child("RhythmUndoButton", true, false) as Button
	primo.pressed.emit()
	assert(primo.disabled, "la pagnotta posata si può duplicare")
	annulla.pressed.emit()
	assert(not primo.disabled, "annulla non restituisce la pagnotta")

	for strofa_data in RhythmCountPanel.STROFE.slice(0, 3):
		var strofa: Dictionary = strofa_data
		var soluzione: Array = Array(strofa["sequenza"]).slice(2)
		for valore in soluzione:
			var trovato := false
			for i in 5:
				var bottone := pannello.find_child("RhythmLoaf_%d" % i, true, false) as Button
				if is_instance_valid(bottone) and bottone.text == str(valore) and not bottone.disabled:
					bottone.pressed.emit()
					trovato = true
					break
			assert(trovato, "manca la pagnotta %s" % str(valore))
		var conferma := pannello.find_child("RhythmConfirmButton", true, false) as Button
		conferma.pressed.emit()
		await process_frame

	assert(bool(esito["ricevuto"]), "il pannello non conclude la sessione")
	assert(bool(esito["vinto"]), "la soluzione corretta non vince")
	assert(int(esito["completati"]) == 3 and int(esito["totale"]) == 3,
		"il riepilogo non conta le tre strofe")
	print("RHYTHM COUNT MINIGAME audit VERDE")
	quit()
