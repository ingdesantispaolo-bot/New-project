extends SceneTree

## **Da una prova si deve sempre poter uscire.** (8 agosto 2026)
##
## Segnalazione di gioco, con schermata: «rispondendo correttamente alla domanda
## il programma si blocca».
##
## Non si bloccava. Il pulsante AVANTI finiva **sotto il bordo dello schermo**, e
## da lì non si poteva più andare avanti — che per chi gioca è la stessa cosa, ed
## è peggio di un errore visibile: sembra un guasto del gioco.
##
## **Due cause, una dentro l'altra.**
##
##   1. la colonna dell'esercizio stava in un riquadro **senza scorrimento**:
##      tutto ciò che non ci stava era irraggiungibile, senza rimedio;
##   2. nelle risposte numeriche e scritte il contenitore delle opzioni resta
##      **vuoto** — campo, tastierino e conferma sono fratelli, non figli — ma
##      si espandeva lo stesso e pretendeva 180 px di minimo. Nella schermata
##      della segnalazione si vede: un buco di seicento pixel fra la domanda e
##      il tastierino, e i pulsanti spinti fuori.
##
## Questo audit tiene la garanzia, non le due correzioni: **i pulsanti che fanno
## proseguire o uscire devono stare dentro una zona scorrevole**. Così, comunque
## cresca il contenuto — una domanda lunga, un tastierino, un indizio in più —
## il bambino ci arriva.

const OK := "EXERCISE REACHABILITY audit VERDE"
## Le forme in cui l'interazione NON vive nel contenitore delle opzioni.
const FUORI_DALLE_OPZIONI := ["numeric_input", "short_answer"]
## Una finestra bassa apposta: è lì che il difetto si manifesta. Un tablet in
## orizzontale con la tastiera aperta lascia poco più di questo.
const FINESTRA := Vector2i(900, 560)

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _nodo(formato: String) -> Dictionary:
	match formato:
		"numeric_input":
			return {
				"id": "probe-num", "topic": "tabelline", "format": "numeric_input",
				"prompt": "Il draghetto Ember mette 2 monete in ogni cesto e riempie 2 cesti. Quante ne ha in tutto?",
				"answer": "4", "explanation": "Due cesti da due monete: 2 × 2 = 4.",
			}
		"short_answer":
			return {
				"id": "probe-sa", "topic": "vocabolario", "format": "short_answer",
				"prompt": "Come si chiama il materiale che lascia passare bene la corrente?",
				"answer": "conduttore", "explanation": "I conduttori hanno elettroni liberi.",
			}
	return {
		"id": "probe-mc", "topic": "tabelline", "format": "multiple_choice",
		"prompt": "Quanto fa 6 × 7?",
		"options": ["42", "36", "48", "40"], "answer": "42",
		"explanation": "Sei gruppi da sette: 42.",
	}

func _sessione(formato: String) -> Dictionary:
	return {
		"sessionId": "probe-%s" % formato,
		"kind": "mission",
		"subject": "matematica",
		"nodes": [_nodo(formato), _nodo(formato)],
		"shields": 3,
		"rewards": {"energyPerCorrect": 10},
	}

func _run() -> void:
	root.get_window().size = FINESTRA
	for formato in ["multiple_choice", "numeric_input", "short_answer"]:
		var player := ExercisePlayer.new()
		player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(player)
		player.start_session(_sessione(formato))
		await process_frame
		await process_frame

		# 1 · la garanzia: i pulsanti d'uscita stanno in una zona scorrevole.
		var scorrevole := player.find_child("ExerciseContentScroll", true, false)
		if scorrevole == null:
			_fallisci("%s: la colonna dell'esercizio non è scorrevole" % formato)
		else:
			for nome in ["ExerciseNextButton", "ExerciseExitButton"]:
				var pulsante := player.find_child(nome, true, false)
				if pulsante == null:
					continue
				if not scorrevole.is_ancestor_of(pulsante):
					_fallisci("%s: «%s» sta fuori dalla zona scorrevole: se sborda è perduto" % [
						formato, nome])

		# 2 · un contenitore vuoto non occupa spazio.
		var opzioni := player.find_child("ExerciseOptionsScroll", true, false) as Control
		if opzioni != null and formato in FUORI_DALLE_OPZIONI:
			if opzioni.size_flags_vertical == Control.SIZE_EXPAND_FILL:
				_fallisci("%s: il riquadro delle opzioni è vuoto ma si espande lo stesso" % formato)
			if opzioni.custom_minimum_size.y > 0.0:
				_fallisci("%s: il riquadro delle opzioni è vuoto ma pretende %.0f px" % [
					formato, opzioni.custom_minimum_size.y])

		# 3 · nessuna scheda modale sopravvive alla fine della prova.
		#
		# Difetto trovato leggendo il codice mentre si cercava il blocco: la
		# scheda della lezione veniva mostrata anche quando l'indice superava
		# l'ultimo nodo, cioè a prova già consegnata. Un pannello a tutto schermo
		# su una sessione che non esiste più è un blocco vero, non apparente.
		for _giro in range(Array(_sessione(formato).get("nodes", [])).size() + 2):
			player.call("_advance")
			await process_frame
		if player.find_child("TeachingOverlay", true, false) != null:
			_fallisci("%s: una scheda modale è rimasta aperta dopo la fine della prova" % formato)

		player.queue_free()
		await process_frame

	if errori.is_empty():
		print(OK)
	else:
		printerr("EXERCISE REACHABILITY audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
