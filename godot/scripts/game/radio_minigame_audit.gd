extends SceneTree

## Prova giocata della radio di Marea, più la regola che serve ai giochi col
## cronometro.
##
## **Il riscontro deve sopravvivere a un fotogramma.** Qui la riga di stato viene
## ridipinta a ogni `_process` per far scorrere i secondi: nella prima stesura
## quel ridisegno passava una stringa vuota, e la frase «quella luce non risponde
## al bisogno» restava sullo schermo **sedici millesimi di secondo**. Il gioco
## sembrava non rispondere all'errore — che è, parola per parola, la segnalazione
## che arriva dai ragazzi quando qualcosa non va. Ogni gioco a tempo che scrive
## nello stesso posto in cui conta i secondi corre questo rischio.

const RADIO_MINIGAME_PANEL := preload("res://scripts/ui/radio_minigame_panel.gd")

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 600)
	var pannello := RADIO_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w04-marea"), true)
	await process_frame

	var stato := pannello.find_child("RadioStatus", true, false) as Label
	if not is_instance_valid(stato):
		_fallisci("la radio non ha una riga di stato")
		_chiudi()
		return

	(pannello.find_child("RadioLight_1", true, false) as Button).pressed.emit()
	if not esito["value"].is_empty():
		_fallisci("un intento errato ha chiuso la radio: %s" % str(esito["value"]))
	var subito := stato.text
	if not subito.contains("luce"):
		_fallisci("l'errore non scrive niente: <%s>" % subito)
	await process_frame
	await process_frame
	if not stato.text.contains("luce"):
		_fallisci("il riscontro dell'errore dura meno di due fotogrammi: <%s> è diventato <%s>" % [
			subito, stato.text])

	for luce in [0, 1, 2, 0, 1]:
		(pannello.find_child("RadioLight_%d" % luce, true, false) as Button).pressed.emit()
	if esito["value"] != [true, 5, 5]:
		_fallisci("gli intenti corretti non hanno chiuso la radio: %s" % str(esito["value"]))
	_chiudi()

func _chiudi() -> void:
	if errori.is_empty():
		print("RADIO MINIGAME audit VERDE")
	else:
		printerr("RADIO MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
