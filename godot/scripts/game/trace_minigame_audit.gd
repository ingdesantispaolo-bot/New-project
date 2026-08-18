extends SceneTree

## Prova giocata della traccia, sulla meccanica nuova.
##
## **La regola che prima non c'era, ed è tutto il gioco:** quando cala la nebbia
## la stanza deve **sparire davvero**. Nella stesura precedente restava
## visibile mentre si componeva la striscia, quindi si copiava una riga da sopra
## a sotto e la memoria non veniva mai messa alla prova — che è esattamente ciò
## che il minigioco di Sesto esiste per fare.
##
## Si verifica anche che il percorso si possa **leggere** dalla stanza (se non è
## leggibile non è un gioco, è un indovinello) e che sbagliare a nebbia calata
## costi un errore senza chiudere la partita.

const TRACE_MINIGAME_PANEL := preload("res://scripts/ui/trace_minigame_panel.gd")

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

## I nomi dei segnali nell'ordine in cui la stanza li mostra.
func _percorso_letto(pannello: Control) -> PackedStringArray:
	var stanza := pannello.find_child("TraceRoom", true, false) as Label
	if not is_instance_valid(stanza):
		return PackedStringArray()
	var testo := stanza.text.replace("STANZA:", "")
	var fuori := PackedStringArray()
	for pezzo in testo.split("→", false):
		var pulito := str(pezzo).strip_edges()
		if pulito != "":
			fuori.append(pulito)
	return fuori

func _premi_segnale(pannello: Control, nome: String) -> bool:
	for i in 12:
		var pulsante := pannello.find_child("TraceSignal_%d" % i, true, false) as Button
		if is_instance_valid(pulsante) and pulsante.text == nome:
			pulsante.pressed.emit()
			return true
	return false

func _esegui() -> void:
	root.size = Vector2i(1024, 700)
	var pannello := TRACE_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w03-sesto"), true)
	await process_frame

	var percorso := _percorso_letto(pannello)
	if percorso.size() < 4:
		_fallisci("la stanza non mostra un percorso leggibile: %s" % str(percorso))
		_chiudi()
		return

	# Fase 1: si posa la traccia a stanza aperta.
	for nome in percorso:
		if not _premi_segnale(pannello, nome):
			_fallisci("il segnale «%s" % nome + "» della stanza non ha un pulsante")
	var striscia := pannello.find_child("TraceStrip", true, false) as Label
	if not striscia.text.contains(percorso[0]):
		_fallisci("la striscia non ha registrato niente: <%s>" % striscia.text)

	# Fase 2: la nebbia. **La stanza deve sparire.**
	(pannello.find_child("TraceVeilButton", true, false) as Button).pressed.emit()
	var stanza := pannello.find_child("TraceRoom", true, false) as Label
	for nome in percorso:
		if stanza.text.contains(nome):
			_fallisci("a nebbia calata la stanza mostra ancora «%s»: si copia invece di ricordare" % nome)
			break
	if not striscia.text.contains(percorso[0]):
		_fallisci("la nebbia ha portato via anche la striscia: <%s>" % striscia.text)

	# Fase 3: si rifà il percorso.
	for nome in percorso:
		_premi_segnale(pannello, nome)
	if esito["value"] != [true, percorso.size(), percorso.size()]:
		_fallisci("il percorso giusto non ha chiuso il gioco: %s" % str(esito["value"]))

	# Sbagliare a nebbia calata costa un errore e non chiude.
	var secondo := TRACE_MINIGAME_PANEL.new()
	root.add_child(secondo)
	var esito2 := {"value": []}
	secondo.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito2["value"] = [vinto, fatti, totale])
	secondo.avvia(CharacterMinigameCatalog.scheda("w03-sesto"), true)
	await process_frame
	var atteso := _percorso_letto(secondo)
	(secondo.find_child("TraceVeilButton", true, false) as Button).pressed.emit()
	for i in 12:
		var pulsante := secondo.find_child("TraceSignal_%d" % i, true, false) as Button
		if is_instance_valid(pulsante) and pulsante.text != atteso[0]:
			pulsante.pressed.emit()
			break
	if not esito2["value"].is_empty():
		_fallisci("un errore a nebbia calata ha chiuso subito la partita: %s" % str(esito2["value"]))

	_chiudi()

func _chiudi() -> void:
	if errori.is_empty():
		print("TRACE MINIGAME audit VERDE")
	else:
		printerr("TRACE MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
