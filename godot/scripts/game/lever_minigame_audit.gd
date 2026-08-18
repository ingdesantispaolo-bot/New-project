extends SceneTree

## Prova giocata della leva di Gerbo.
##
## Le due metà della sua convinzione, in ordine: **spingere non basta** con
## l'appoggio dov'è all'inizio, e **spostare l'appoggio basta** senza spingere
## più forte. Se cedesse la prima, Gerbo avrebbe ragione al primo tentativo; se
## cedesse la seconda, il gioco sarebbe una punizione.

const LEVER_MINIGAME_PANEL := preload("res://scripts/ui/lever_minigame_panel.gd")

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _sollevati(pannello: Control) -> int:
	var stato := pannello.find_child("LeverStatus", true, false) as Label
	if not is_instance_valid(stato):
		return -1
	var pezzi := stato.text.split("sollevati ", false)
	if pezzi.size() < 2:
		return -1
	return int(str(pezzi[1]).split("/")[0])

func _esegui() -> void:
	root.size = Vector2i(1024, 700)
	var pannello := LEVER_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, presi: int, totale: int): esito["value"] = [vinto, presi, totale])
	var scheda := CharacterMinigameCatalog.scheda("w05-gerbo")
	pannello.avvia(scheda, true)
	await process_frame

	var parametri: Dictionary = scheda.get("parametri", {})
	var peso := float(parametri.get("peso", 20.0))
	var massi := int(parametri.get("massi", 3))

	# **Spingere con l'appoggio di partenza non deve alzare niente**, e non deve
	# nemmeno chiudere la partita: costa secondi, e basta.
	for _i in 3:
		(pannello.find_child("LeverPushButton", true, false) as Button).pressed.emit()
	if _sollevati(pannello) != 0:
		_fallisci("la forza bruta ha sollevato qualcosa: sollevati %d" % _sollevati(pannello))
	if not esito["value"].is_empty():
		_fallisci("spingere a vuoto ha chiuso la partita: %s" % str(esito["value"]))

	# **Spostare l'appoggio deve bastare**, e va rifatto per ogni masso perché il
	# cuneo torna indietro: è il gesto che si impara.
	var utile := LeverMinigamePanel.fulcro_utile(peso)
	if utile <= 0:
		_fallisci("nessun appoggio utile al mondo di Gerbo (peso %.0f)" % peso)
		_chiudi()
		return
	for _masso in massi:
		var cuneo := pannello.find_child("LeverFulcrum_%d" % utile, true, false) as Button
		if not is_instance_valid(cuneo):
			_fallisci("manca il cuneo in posizione %d" % utile)
			break
		cuneo.pressed.emit()
		(pannello.find_child("LeverPushButton", true, false) as Button).pressed.emit()
	if esito["value"] != [true, massi, massi]:
		_fallisci("il cuneo al posto giusto non ha sollevato tutti i massi: %s" % str(esito["value"]))

	_chiudi()

func _chiudi() -> void:
	if errori.is_empty():
		print("LEVER MINIGAME audit VERDE")
	else:
		printerr("LEVER MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
