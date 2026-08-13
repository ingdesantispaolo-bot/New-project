extends SceneTree

## Prova giocata di **Parenti nell'ombra**. Verifica la sequenza didattica
## ipotesi → due indizi → revisione → conferma, l'assenza di cronometro e la
## possibilità di vincere usando soltanto le famiglie mostrate.

const PANEL := preload("res://scripts/ui/kinship_minigame_panel.gd")

var errori: Array[String] = []

func _pretendi(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	var scheda := CharacterMinigameCatalog.scheda("w07-zeno")
	var p: Dictionary = scheda.get("parametri", {})
	_pretendi(str(scheda.get("archetipo", "")) == CharacterMinigameCatalog.ARCHETIPO_PARENTELA,
		"Zeno non usa l'archetipo della parentela")
	_pretendi(str(scheda.get("forma", "")) == CharacterMinigameCatalog.FORMA_RIFLESSIONE,
		"Zeno non è un gioco di riflessione")
	_pretendi(float(p.get("secondi", -1.0)) == 0.0, "Zeno ha un limite di tempo")

	var pannello := PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, presi: int, totale: int): esito["value"] = [vinto, presi, totale])
	pannello.avvia(scheda, true)
	await process_frame

	_pretendi(pannello.find_child("KinshipBoard", true, false) is Control,
		"manca l'albero etimologico vettoriale")
	_pretendi(pannello.find_child("KinshipClock", true, false) == null,
		"il gioco riflessivo mostra un cronometro")
	var metodo := pannello.find_child("KinshipMethod", true, false) as Label
	_pretendi(is_instance_valid(metodo) and metodo.text.contains("IPOTIZZA") and metodo.text.contains("CAMBIA"),
		"la sequenza ipotesi-indizi-revisione non è visibile")
	var stato := pannello.find_child("KinshipStatus", true, false) as Label

	# L'indizio senza ipotesi non parte: altrimenti non si può fare esperienza
	# di una previsione che viene confermata o corretta.
	(pannello.find_child("KinshipClueButton", true, false) as Button).pressed.emit()
	_pretendi(stato.text.contains("Prima fai un'ipotesi"), "si possono scoprire indizi senza ipotesi")

	# Prima famiglia: ipotesi sbagliata, un indizio insufficiente, due indizi,
	# conferma fallita e revisione corretta. La partita deve restare aperta.
	(pannello.find_child("KinshipHypothesis_1", true, false) as Button).pressed.emit()
	(pannello.find_child("KinshipClueButton", true, false) as Button).pressed.emit()
	(pannello.find_child("KinshipConfirmButton", true, false) as Button).pressed.emit()
	_pretendi(stato.text.contains("illumina due parenti"), "si può confermare con un solo parente")
	(pannello.find_child("KinshipClueButton", true, false) as Button).pressed.emit()
	(pannello.find_child("KinshipConfirmButton", true, false) as Button).pressed.emit()
	_pretendi(esito["value"].is_empty(), "un'ipotesi sbagliata chiude il gioco")
	_pretendi(stato.text.contains("Cambiala"), "l'errore non invita a revisionare l'ipotesi")
	(pannello.find_child("KinshipHypothesis_0", true, false) as Button).pressed.emit()
	(pannello.find_child("KinshipConfirmButton", true, false) as Button).pressed.emit()
	await process_frame

	# Famiglie restanti: la risposta deriva dai dati, non dalla posizione.
	var famiglie: Array = Array(scheda.get("famiglie", [])).slice(1, int(p.get("famiglie", 3)))
	for famiglia_data in famiglie:
		var famiglia: Dictionary = famiglia_data
		var giusta := int(famiglia.get("giusta", -1))
		(pannello.find_child("KinshipHypothesis_%d" % giusta, true, false) as Button).pressed.emit()
		for _i in int(p.get("indizi", 2)):
			(pannello.find_child("KinshipClueButton", true, false) as Button).pressed.emit()
		(pannello.find_child("KinshipConfirmButton", true, false) as Button).pressed.emit()
		await process_frame

	_pretendi(not esito["value"].is_empty() and bool(esito["value"][0]),
		"le famiglie corrette non vincono: %s" % str(esito["value"]))
	_pretendi(not esito["value"].is_empty() and int(esito["value"][1]) == int(esito["value"][2]),
		"la vittoria non completa tutte le famiglie")

	pannello.queue_free()
	await process_frame
	if errori.is_empty():
		print("KINSHIP MINIGAME audit VERDE")
	else:
		printerr("KINSHIP MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
