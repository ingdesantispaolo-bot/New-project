extends SceneTree

## Verifica comportamentale della correzione anti-tentativo.
##
## Copre i due varchi che permettevano di avanzare cliccando a caso:
## 1. una missione breve con 2 risposte giuste e 1 errata superava la vecchia
##    soglia del 50%; ora il risultato netto e' 1,5 e la prova fallisce;
## 2. un nodo ritentabile trovato dopo un errore risultava corretto pieno; ora
##    conserva la soluzione grezza, ma vale 0,5 e non alza la padronanza topic.
## Controlla inoltre che gli esami pesati sottraggano gli errori nella stessa
## scala 50/35/15 usata per le risposte corrette.

const PLAYER := preload("res://scripts/game/exercise_player.gd")

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_controlla_voto_pesato()
	await _missione_breve_non_passa_a_caso()
	await _ritentare_non_cancella_l_errore()
	if errori.is_empty():
		print("ANTI GUESSING audit VERDE — errori sottratti da missioni, ritentativi ed esami")
	else:
		printerr("ANTI GUESSING audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)

func _nodo(indice: int) -> Dictionary:
	return {
		"format": "multiple_choice",
		"prompt": "Domanda anti-tentativo %d" % (indice + 1),
		"options": ["giusta", "a", "b", "c"],
		"answer": "giusta",
		"topic": "anti-tentativo-%d" % indice,
		"subject": "matematica",
		"difficulty": 1,
		"explanation": "La risposta si ricava, non si tenta.",
	}

func _sessione(nodi: int) -> Dictionary:
	var elenco: Array = []
	for i in range(nodi):
		elenco.append(_nodo(i))
	return {
		"sessionId": "anti-guessing-%d" % nodi,
		"kind": "mission",
		"subject": "matematica",
		"nodes": elenco,
		"shields": 3,
		"pace": "reasoning",
		"timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {}},
	}

func _controlla_voto_pesato() -> void:
	var esame := {
		"weightedScoring": true,
		"weightedPassRatio": 0.75,
	}
	_controlla(PLAYER.session_score_passed(esame, 15, 20, 0.75, 1.0, 10),
		"un esame pulito al 75% non passa")
	_controlla(not PLAYER.session_score_passed(
		esame, 15, 20, 0.75, 1.0, 10, 5, 0.25),
		"il 75% grezzo passa ancora nonostante cinque risposte errate")
	_controlla(PLAYER.session_score_passed(
		esame, 17, 20, 0.85, 1.0, 10, 3, 0.15),
		"la penalita' rende impossibile recuperare anche con un esame solido")

func _missione_breve_non_passa_a_caso() -> void:
	var player := PLAYER.new()
	root.add_child(player)
	var esiti: Array = []
	player.session_finished.connect(func(esito): esiti.append(esito))
	player.start_session(_sessione(3))
	await process_frame
	for risposta in ["giusta", "giusta", "a"]:
		player.call("_answer", risposta)
		await process_frame
		player.call("_advance")
		await process_frame
	_controlla(esiti.size() == 1, "la missione breve non ha prodotto un esito")
	if esiti.size() == 1:
		var esito: Dictionary = esiti[0]
		_controlla(int(esito.get("correct", -1)) == 2,
			"il conteggio grezzo della missione non e' 2/3")
		_controlla(int(esito.get("wrongAnswers", -1)) == 1,
			"la risposta errata non e' stata contata")
		_controlla(is_equal_approx(float(esito.get("effectiveCorrect", -1.0)), 1.5),
			"il punteggio netto della missione non e' 1,5")
		_controlla(not bool(esito.get("passed", true)),
			"2 giuste + 1 errata superano ancora la missione")
	player.queue_free()

func _ritentare_non_cancella_l_errore() -> void:
	var player := PLAYER.new()
	root.add_child(player)
	var esiti: Array = []
	player.session_finished.connect(func(esito): esiti.append(esito))
	var sessione := _sessione(1)
	player.start_session(sessione)
	await process_frame
	var item: Dictionary = sessione["nodes"][0]
	# Stesso percorso dei formati interattivi: prima un tentativo errato, poi la
	# soluzione. In passato `_score_current(true)` cancellava di fatto l'errore.
	player.call("_retryable_result", false, item, "Riprova.")
	await process_frame
	player.call("_retryable_result", true, item, "")
	await process_frame
	player.call("_advance")
	await process_frame
	_controlla(esiti.size() == 1, "il nodo ritentabile non ha prodotto un esito")
	if esiti.size() == 1:
		var esito: Dictionary = esiti[0]
		_controlla(int(esito.get("correct", -1)) == 1,
			"la soluzione finale del ritentativo non e' registrata")
		_controlla(is_equal_approx(float(esito.get("effectiveCorrect", -1.0)), 0.5),
			"il ritentativo errato vale ancora come risposta piena")
		_controlla(not bool(esito.get("passed", true)),
			"un nodo singolo trovato per tentativi risulta superato")
		var stats: Dictionary = esito.get("topicStats", {})
		var topic: Dictionary = stats.get("anti-tentativo-0", {})
		_controlla(int(topic.get("correct", -1)) == 0,
			"il tentativo sporco aumenta ancora la padronanza dell'argomento")
	player.queue_free()
