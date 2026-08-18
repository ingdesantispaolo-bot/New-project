extends SceneTree

## Ambra deve usare davvero il renderer come staffetta musicale: materiale,
## parole e percorso giocato non possono restare quelli dell'officina.

const CYCLE_PANEL := preload("res://scripts/ui/cycle_minigame_panel.gd")

var errori: Array[String] = []

func _init() -> void:
	call_deferred("_esegui")

func _premi(pannello: Control, nome: String) -> void:
	var b := pannello.find_child(nome, true, false) as Button
	if is_instance_valid(b):
		b.pressed.emit()
	else:
		errori.append("manca %s" % nome)

func _esegui() -> void:
	root.size = Vector2i(1024, 700)
	var pannello := CYCLE_PANEL.new()
	root.add_child(pannello)
	var finale := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): finale["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w06-ambra"), true)
	await process_frame
	if pannello.find_child("CycleStage", true, false) == null:
		errori.append("manca la staffetta vettoriale")
	var coda := pannello.find_child("CycleBelt", true, false) as Label
	if not is_instance_valid(coda) or not coda.text.contains("LANTERNE") or coda.text.contains("NASTRO"):
		errori.append("Ambra parla ancora come l'officina: <%s>" % (coda.text if is_instance_valid(coda) else "manca"))
	var avvia := pannello.find_child("CycleRunButton", true, false) as Button
	if not is_instance_valid(avvia) or not avvia.text.contains("STAFFETTA"):
		errori.append("il comando finale non appartiene alla staffetta")

	# Registra ASCOLTA → NOMINA → MANDA e lascia lavorare la staffetta.
	_premi(pannello, "CycleRecordButton")
	_premi(pannello, "CycleCommand_0")
	_premi(pannello, "CycleRecordButton")
	pannello._process(0.4)
	_premi(pannello, "CycleCommand_1")
	_premi(pannello, "CycleRecordButton")
	_premi(pannello, "CycleRunButton")
	var giri := 0
	while finale["value"].is_empty() and giri < 500:
		pannello._process(0.1)
		giri += 1
	if finale["value"].is_empty() or not bool(finale["value"][0]):
		errori.append("la staffetta corretta non raggiunge le lanterne: %s" % str(finale["value"]))

	if errori.is_empty():
		print("MUSIC RELAY MINIGAME audit VERDE")
	else:
		printerr("MUSIC RELAY MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
