extends SceneTree

## Prova giocata della prova controllata.
##
## L'audit **gioca il metodo**: parte da una configurazione base, cambia una
## manopola per volta e legge l'esito. Se il metodo entra nelle prove concesse,
## il gioco è giocabile; se non ci entrasse, sarebbe una punizione travestita da
## lezione sul metodo scientifico, che è il peggio che potesse capitargli.
##
## Verifica anche la frase che giustifica l'intero minigioco: quando fra due
## prove cambiano **due** manopole, il gioco deve dire che quell'esito non dice
## quale delle due. È l'unico posto in cui la lezione è scritta a parole, e ci
## sta perché arriva dopo il gesto, non prima.

const TRIAL_MINIGAME_PANEL := preload("res://scripts/ui/controlled_trial_minigame_panel.gd")

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	for npc_id in CharacterMinigameCatalog.giochi_con_archetipo(CharacterMinigameCatalog.ARCHETIPO_PROVA):
		await _gioca(str(npc_id))
	if errori.is_empty():
		print("CONTROLLED TRIAL MINIGAME audit VERDE")
	else:
		printerr("CONTROLLED TRIAL MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)

func _gioca(npc_id: String) -> void:
	var scheda := CharacterMinigameCatalog.scheda(npc_id)
	var parametri: Dictionary = scheda.get("parametri", {})
	var quanti := int(parametri.get("fattori", 3))
	var prove := int(parametri.get("prove", quanti + 1))
	var pannello := TRIAL_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, usate: int, totali: int): esito["value"] = [vinto, usate, totali])
	pannello.avvia(scheda, true)
	await process_frame

	var riuscita := str(scheda.get("successo", "Funziona."))
	var uscita := pannello.find_child("TrialOutcome", true, false) as Label

	# La base: nessuna manopola girata. Serve come termine di paragone, ed è la
	# prima delle prove concesse.
	(pannello.find_child("TrialRunButton", true, false) as Button).pressed.emit()
	var usate := 1
	var causa := -1
	for i in quanti:
		if usate >= prove:
			break
		# Una manopola per volta: si gira, si prova, si rimette com'era.
		(pannello.find_child("TrialKnob_%d" % i, true, false) as Button).pressed.emit()
		(pannello.find_child("TrialRunButton", true, false) as Button).pressed.emit()
		usate += 1
		if uscita.text.begins_with(riuscita):
			causa = i
			break
		(pannello.find_child("TrialKnob_%d" % i, true, false) as Button).pressed.emit()
	if causa < 0:
		_fallisci("%s: cambiando una manopola per volta non si trova la causa in %d prove" % [npc_id, prove])
		pannello.queue_free()
		await process_frame
		return

	# Accusare la manopola sbagliata costa un errore e non chiude la partita.
	var innocente := (causa + 1) % quanti
	(pannello.find_child("TrialAccuse_%d" % innocente, true, false) as Button).pressed.emit()
	if not esito["value"].is_empty():
		_fallisci("%s: un'accusa sbagliata ha chiuso subito: %s" % [npc_id, str(esito["value"])])
	(pannello.find_child("TrialAccuse_%d" % causa, true, false) as Button).pressed.emit()
	if esito["value"].is_empty() or not bool(esito["value"][0]):
		_fallisci("%s: la causa giusta non ha chiuso il gioco: %s" % [npc_id, str(esito["value"])])
	pannello.queue_free()
	await process_frame

	# **La frase che deve restare.** Due manopole cambiate insieme non dicono
	# quale delle due, e il gioco lo deve dire.
	var secondo := TRIAL_MINIGAME_PANEL.new()
	root.add_child(secondo)
	secondo.avvia(scheda, true)
	await process_frame
	(secondo.find_child("TrialRunButton", true, false) as Button).pressed.emit()
	(secondo.find_child("TrialKnob_0", true, false) as Button).pressed.emit()
	(secondo.find_child("TrialKnob_1", true, false) as Button).pressed.emit()
	(secondo.find_child("TrialRunButton", true, false) as Button).pressed.emit()
	var testo := (secondo.find_child("TrialOutcome", true, false) as Label).text
	if not testo.contains("non dice quale"):
		_fallisci("%s: cambiando due manopole il gioco non avverte: <%s>" % [npc_id, testo])
	secondo.queue_free()
	await process_frame
