extends SceneTree

## Prova giocata di **Glifi vivi**: il catalogo deve rispettare la matrice
## veloce, la guida deve insegnare prima di chiedere, una macchia non deve
## chiudere il turno e tutte le funzioni corrette devono portare alla vittoria.

const PANEL := preload("res://scripts/ui/glyph_minigame_panel.gd")

var errori: Array[String] = []

func _pretendi(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	var scheda := CharacterMinigameCatalog.scheda("w07-livia")
	var parametri: Dictionary = scheda.get("parametri", {})
	_pretendi(str(scheda.get("archetipo", "")) == CharacterMinigameCatalog.ARCHETIPO_GLIFI,
		"Livia usa ancora lo scaffale invece dei glifi vivi")
	_pretendi(str(scheda.get("forma", "")) == CharacterMinigameCatalog.FORMA_VELOCITA,
		"Livia non rispetta la forma veloce della matrice")
	_pretendi(float(parametri.get("secondi", 0.0)) >= 6.0,
		"una parola resta visibile meno di sei secondi")

	var pannello := PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, presi: int, totale: int): esito["value"] = [vinto, presi, totale])
	pannello.avvia(scheda, true)
	await process_frame

	_pretendi(pannello.find_child("GlyphBoard", true, false) is Control,
		"manca lo scriptorium vettoriale")
	var guida := pannello.find_child("GlyphGuide", true, false) as Label
	_pretendi(is_instance_valid(guida) and guida.text.contains("-AM") and guida.text.contains("RICEVE"),
		"la regola delle desinenze non è visibile prima del gesto")
	var clock := pannello.find_child("GlyphClock", true, false) as Label
	_pretendi(is_instance_valid(clock) and clock.text.contains("INCHIOSTRO"),
		"la pressione temporale non è resa come inchiostro")

	# ROS-A agisce: la porta opposta produce una macchia ma lascia riprovare.
	(pannello.find_child("GlyphDoor_1", true, false) as Button).pressed.emit()
	var stato := pannello.find_child("GlyphStatus", true, false) as Label
	_pretendi(esito["value"].is_empty(), "una sola macchia chiude il gioco")
	_pretendi(is_instance_valid(stato) and stato.text.contains("desinenza dorata"),
		"l'errore non rimanda all'indizio utile")

	var glifi: Array = Array(scheda.get("glifi", [])).slice(0, int(parametri.get("glifi", 6)))
	for voce_data in glifi:
		var voce: Dictionary = voce_data
		var funzione := int(voce.get("funzione", -1))
		(pannello.find_child("GlyphDoor_%d" % funzione, true, false) as Button).pressed.emit()
		await process_frame

	_pretendi(not esito["value"].is_empty() and bool(esito["value"][0]),
		"instradare tutti i glifi per funzione non vince: %s" % str(esito["value"]))
	_pretendi(not esito["value"].is_empty() and int(esito["value"][1]) == glifi.size(),
		"la vittoria non contabilizza tutte le pergamene")

	pannello.queue_free()
	await process_frame
	if errori.is_empty():
		print("GLYPH MINIGAME audit VERDE")
	else:
		printerr("GLYPH MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
