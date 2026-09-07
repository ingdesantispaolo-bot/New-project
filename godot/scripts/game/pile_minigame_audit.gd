extends SceneTree

## Regressione giocata del deposito di Tobia: tre ordini, correzione senza
## sconfitta, composizione per decine/unita' e vittoria soltanto a lavoro finito.

var _esito: Dictionary = {}


func _init() -> void:
	call_deferred("_esegui")


func _esegui() -> void:
	root.size = Vector2i(1024, 640)
	assert(PileMinigamePanel.scomponi(43) == Vector2i(4, 3), "43 deve diventare 4 decine e 3 unita'")
	assert(PileMinigamePanel.valore(4, 3) == 43, "4 decine e 3 unita' devono valere 43")

	var pannello := PileMinigamePanel.new()
	root.add_child(pannello)
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int):
		_esito = {"vinto": vinto, "fatti": fatti, "totale": totale})
	pannello.avvia(CharacterMinigameCatalog.scheda("w01-tobia"), true)
	await process_frame
	assert(pannello.find_child("PileClock", true, false) == null, "il mondo 1 non deve avere un cronometro")
	assert(_testo(pannello, "PileTarget").contains("24"), "il primo ordine deve essere 24")

	# Un carico errato non termina il gioco e produce una correzione quantitativa.
	_premi(pannello, "PileAddTen", 1)
	_premi(pannello, "PileCheckButton", 1)
	assert(_esito.is_empty(), "un errore non deve chiudere la partita")
	assert(_testo(pannello, "PileFeedback").contains("Mancano 14"), "la correzione deve dire quanto manca")

	# 24 = 2 decine + 4 unita'.
	_premi(pannello, "PileAddTen", 1)
	_premi(pannello, "PileAddOne", 4)
	assert(pannello.find_children("TenCrate_*", "PanelContainer", true, false).size() == 2,
		"due decine devono apparire come due casse")
	_premi(pannello, "PileCheckButton", 1)
	assert(_testo(pannello, "PileFeedback").contains("2 decine e 4"),
		"la conferma deve restare leggibile prima di avanzare")
	_premi(pannello, "PileCheckButton", 1)
	assert(_testo(pannello, "PileTarget").contains("30"), "il secondo ordine deve insegnare zero unita'")

	# 30 = 3 decine + 0 unita'.
	_premi(pannello, "PileAddTen", 3)
	_premi(pannello, "PileCheckButton", 1)
	_premi(pannello, "PileCheckButton", 1)
	assert(_testo(pannello, "PileTarget").contains("43"), "il terzo ordine deve distinguere 43 da 34")

	# 43 = 4 decine + 3 unita'; in movimento ridotto l'esito e' immediato.
	_premi(pannello, "PileAddTen", 4)
	_premi(pannello, "PileAddOne", 3)
	_premi(pannello, "PileCheckButton", 1)
	assert(_testo(pannello, "PileFeedback").contains("4 decine e 3"),
		"la conferma finale deve esplicitare il valore posizionale")
	_premi(pannello, "PileCheckButton", 1)
	assert(bool(_esito.get("vinto", false)), "tre ordini corretti devono vincere")
	assert(int(_esito.get("fatti", 0)) == 3 and int(_esito.get("totale", 0)) == 3,
		"l'esito deve riportare tre consegne su tre")

	pannello.queue_free()
	await process_frame
	print("PILE MINIGAME audit VERDE - decine/unita', 3 ordini, nessun timer")
	quit(0)


func _premi(pannello: Node, nome: String, volte: int) -> void:
	var bottone := pannello.find_child(nome, true, false) as Button
	assert(is_instance_valid(bottone), "pulsante mancante: %s" % nome)
	for _indice in range(volte):
		bottone.pressed.emit()


func _testo(pannello: Node, nome: String) -> String:
	var label := pannello.find_child(nome, true, false) as Label
	assert(is_instance_valid(label), "etichetta mancante: %s" % nome)
	return label.text
