extends SceneTree

## Prova giocata del ciclo, sulla meccanica nuova.
##
## Quella vecchia non aveva la mano: si sceglieva fra sei permutazioni senza
## indizi. Qui si verifica quello che rende il gioco un gioco: **la mano
## funziona** (il pezzo dice sempre che gesto aspetta, quindi non si indovina),
## **il tetto della mano esiste** (due gesti di fila senza far passare tempo non
## valgono due), **una sequenza sbagliata si corregge** e **il braccio giusto
## sgombra il nastro**.
##
## Il tempo lo facciamo passare noi chiamando `_process` con un passo scelto:
## `await process_frame` in headless avanza di frazioni impredicibili, e un
## audit che dipende dalla velocità della macchina non è un audit.

const CYCLE_MINIGAME_PANEL := preload("res://scripts/ui/cycle_minigame_panel.gd")

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _premi(pannello: Control, nome: String) -> void:
	var pulsante := pannello.find_child(nome, true, false) as Button
	if is_instance_valid(pulsante):
		pulsante.pressed.emit()
	else:
		_fallisci("manca il pulsante «%s»" % nome)

func _esegui() -> void:
	root.size = Vector2i(1024, 600)
	var pannello := CYCLE_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w03-ruggine"), true)
	await process_frame

	# **La mano fa il suo lavoro.** Il primo gesto della sequenza deve valere; il
	# secondo, chiesto subito dopo senza far passare tempo, no.
	var mano := pannello.find_child("CycleHand", true, false) as Label
	var prima := mano.text
	_premi(pannello, "CycleCommand_0")
	if mano.text == prima:
		_fallisci("il primo gesto non ha mosso niente: <%s>" % mano.text)
	var dopo_uno := mano.text
	_premi(pannello, "CycleCommand_1")
	if mano.text != dopo_uno:
		_fallisci("due gesti di fila senza tempo in mezzo: il tetto della mano non c'è")

	# **Una sequenza sbagliata non chiude niente e si corregge.**
	for _i in 3:
		_premi(pannello, "CycleRecordButton")
	_premi(pannello, "CycleRunButton")
	if not esito["value"].is_empty():
		_fallisci("una sequenza sbagliata ha chiuso il gioco: %s" % str(esito["value"]))

	# **Il braccio giusto sgombra il nastro.** Le caselle si riempiono col gesto
	# che si ha **in mano adesso**, quindi si alternano REGISTRA e gesto — ed è
	# il motivo per cui prima bisogna finire il pezzo cominciato sopra: la mano
	# è ferma al secondo gesto, e registrare da lì scriverebbe le caselle
	# sfasate. Non è un difetto del gioco: è come funziona il registratore, e
	# infatti l'audit lo fa come lo farebbe un bambino che ha lavorato a mano.
	_premi(pannello, "CycleClearButton")
	pannello._process(0.4)
	_premi(pannello, "CycleCommand_1")
	pannello._process(0.4)
	_premi(pannello, "CycleCommand_2")
	pannello._process(0.4)
	_premi(pannello, "CycleRecordButton")
	_premi(pannello, "CycleCommand_0")
	_premi(pannello, "CycleRecordButton")
	pannello._process(0.4)
	_premi(pannello, "CycleCommand_1")
	_premi(pannello, "CycleRecordButton")
	_premi(pannello, "CycleRunButton")
	var giri := 0
	while esito["value"].is_empty() and giri < 400:
		pannello._process(0.1)
		giri += 1
	if esito["value"].is_empty():
		_fallisci("il braccio non ha mai finito il nastro")
	elif not bool(esito["value"][0]):
		_fallisci("il braccio giusto non ha liberato il nastro: %s" % str(esito["value"]))

	if errori.is_empty():
		print("CYCLE MINIGAME audit VERDE")
	else:
		printerr("CYCLE MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
