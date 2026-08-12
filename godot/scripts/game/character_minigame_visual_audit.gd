extends SceneTree

## Verifica strutturale dei due pilot grafici dei minigiochi-personaggio.
## Il gusto si collauda a occhio; qui teniamo le condizioni che non devono
## regredire: asset presente, decine visibili, bersagli tablet e stesso glifo.

const OK := "CHARACTER MINIGAME VISUAL audit VERDE"
var errori: Array[String] = []

func _init() -> void:
	call_deferred("_esegui")

func _pretendi(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _esegui() -> void:
	root.size = Vector2i(1024, 600)
	var mucchio := PileMinigamePanel.new()
	root.add_child(mucchio)
	mucchio.avvia(CharacterMinigameCatalog.scheda("w01-tobia"), false)
	await process_frame
	_pretendi(mucchio.find_child("PileCard", true, false) != null,
		"mucchio senza carta tablet")
	_pretendi(mucchio.find_child("PileConvictionGlyph", true, false) is ConvictionGlyph,
		"mucchio senza glifo della convinzione")
	_pretendi(mucchio.find_child("TenTray_00", true, false) != null,
		"prima decina senza vassoio visivo")
	var primo := mucchio.find_child("Crystal_00", true, false) as Button
	_pretendi(is_instance_valid(primo) and primo.icon != null,
		"cristallo generativo non caricato")
	_pretendi(is_instance_valid(primo) and primo.custom_minimum_size.x >= 40.0,
		"bersaglio del cristallo sotto i 40 px")
	mucchio.queue_free()
	await process_frame

	var scaffale := ShelfMinigamePanel.new()
	root.add_child(scaffale)
	scaffale.avvia(CharacterMinigameCatalog.scheda("w02-corinna"), false)
	await process_frame
	_pretendi(scaffale.find_child("ShelfCard", true, false) != null,
		"scaffale senza carta tablet")
	_pretendi(scaffale.find_child("ShelfWordCard", true, false) != null,
		"parola senza scheda visiva")
	_pretendi(scaffale.find_child("ShelfConvictionGlyph", true, false) is ConvictionGlyph,
		"scaffale senza lo stesso glifo del mucchio")
	_pretendi(scaffale.find_child("ShelfClock", true, false) == null,
		"il gioco di riflessione mostra un cronometro")
	for i in 2:
		var pulsante := scaffale.find_child("Shelf_%d" % i, true, false) as Button
		_pretendi(is_instance_valid(pulsante) and pulsante.custom_minimum_size.y >= 88.0,
			"scaffale %d troppo piccolo per il tablet" % i)
	scaffale.queue_free()
	await process_frame

	var circuito := CircuitMinigamePanel.new()
	root.add_child(circuito)
	circuito.avvia(CharacterMinigameCatalog.scheda("w08-ciro"), false)
	await process_frame
	_pretendi(circuito.find_child("CircuitCard", true, false) != null,
		"circuito senza carta tablet")
	_pretendi(circuito.find_child("CircuitConvictionGlyph", true, false) is ConvictionGlyph,
		"circuito senza lo stesso glifo degli altri pilot")
	var quadro := circuito.find_child("CircuitBoard", true, false) as CircuitMinigameBoard
	_pretendi(is_instance_valid(quadro), "rete mutante non costruita")
	if is_instance_valid(quadro):
		_pretendi(quadro.numero_interruttori() >= 9,
			"Ciro ha meno di tre passaggi per tre corsie")
		var giusto := quadro.find_child("CircuitSwitch_0_%d" % quadro.riga_corretta(0), true, false) as Button
		_pretendi(is_instance_valid(giusto) and giusto.custom_minimum_size.x >= 48.0,
			"interruttore corretto troppo piccolo per il tablet")
		if is_instance_valid(giusto):
			giusto.pressed.emit()
			_pretendi(quadro.passaggio_attivo() == 1,
				"il primo nodo corretto non propaga la corrente")
	_pretendi(circuito.find_child("CircuitClock", true, false) == null,
		"il Circuito mutante mostra un cronometro")
	circuito.queue_free()
	await process_frame

	if errori.is_empty():
		print(OK)
	else:
		printerr("CHARACTER MINIGAME VISUAL audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
