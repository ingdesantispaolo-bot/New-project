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

## I formati **con diagramma**: sono quelli della segnalazione del 15 agosto, in
## cui il disegno occupa mezza schermata e spingeva VERIFICA sotto il bordo.
func _nodo_interattivo(formato: String) -> Dictionary:
	match formato:
		"number_line":
			return {
				"id": "probe-nl", "topic": "numeri", "format": "number_line",
				"prompt": "Quale punto sta esattamente a metà fra 0 e 10?",
				"line": {"min": 0, "max": 10, "step": 1},
				"answer": "5", "explanation": "La metà di 10 è 5.",
			}
		"cycle":
			return {
				"id": "probe-cy", "topic": "cicli", "format": "cycle",
				"prompt": "Rimetti in ordine il ciclo dell'acqua.",
				"steps": ["evaporazione", "condensazione", "precipitazione"],
				"answer": "evaporazione", "explanation": "Si parte dall'evaporazione.",
			}
	return {
		"id": "probe-or", "topic": "sequenze", "format": "ordering",
		"prompt": "Ordina dal più piccolo al più grande.",
		"items": ["3", "7", "12", "21"], "correctOrder": ["3", "7", "12", "21"],
		"answer": "3", "explanation": "Si confrontano a due a due.",
	}

func _sessione_interattiva(formato: String) -> Dictionary:
	return {
		"sessionId": "probe-int-%s" % formato,
		"kind": "mission",
		"subject": "matematica",
		"nodes": [_nodo_interattivo(formato), _nodo_interattivo(formato)],
		"shields": 3,
		"rewards": {"energyPerCorrect": 10},
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

		# **1 · la garanzia, aggiornata il 15 agosto 2026.**
		#
		# Fino a ieri diceva: «i pulsanti stanno in una zona scorrevole». Era la
		# correzione dell'8 agosto, ed era una mezza risposta — una segnalazione
		# con schermata l'ha dimostrato: su una domanda con la retta dei numeri si
		# vedeva SPIEGA CON NORA e sotto, tagliato dal bordo, VERIFICA. Il
		# contenuto scorreva davvero, ma **i pulsanti scorrevano con lui**.
		#
		# Adesso la garanzia è più forte e più semplice da verificare: i pulsanti
		# che fanno proseguire stanno nella BARRA FISSA (`ExerciseActionBar`),
		# ancorata al fondo del riquadro e fuori da ogni scorrimento. Chi sta lì
		# non può sbordare per costruzione. La porta d'uscita resta invece nella
		# colonna scorrevole: è secondaria, e la si raggiunge scorrendo.
		var scorrevole := player.find_child("ExerciseContentScroll", true, false)
		var barra := player.find_child("ExerciseActionBar", true, false)
		if scorrevole == null:
			_fallisci("%s: la colonna dell'esercizio non è scorrevole" % formato)
		if barra == null:
			_fallisci("%s: manca la barra fissa delle azioni" % formato)
		else:
			for nome in ["ExerciseNextButton", "ConceptHelpButton", "TextAnswerSubmit"]:
				var pulsante := player.find_child(nome, true, false)
				if pulsante == null:
					continue
				if not barra.is_ancestor_of(pulsante):
					_fallisci("%s: «%s» non sta nella barra fissa: scorrerà via col contenuto" % [
						formato, nome])
		if scorrevole != null:
			var uscita := player.find_child("ExerciseExitButton", true, false)
			if uscita != null and not scorrevole.is_ancestor_of(uscita):
				_fallisci("%s: la porta d'uscita non è nella colonna scorrevole" % formato)

		# **1-bis · il riquadro deve stare dentro lo schermo, sbagliando.**
		#
		# Questa regola mancava, e la sua assenza e' costata una seconda
		# segnalazione: «il programma si blocca se si sbaglia esercizio». L'audit
		# era verde mentre il difetto c'era, perche' controllava che i pulsanti
		# stessero nella zona scorrevole — ed era vero — ma non che la zona
		# scorrevole stesse nella FINESTRA. Il riquadro cresceva col contenuto e
		# usciva dal basso portandosi via i pulsanti.
		#
		# Si prova con la risposta SBAGLIATA apposta: e' il momento in cui il
		# contenuto e' piu' alto, perche' al riscontro si aggiunge la spiegazione
		# dell'esercizio. Rispondendo giusto si legge una riga sola e spesso ci
		# si sta dentro lo stesso — ed e' esattamente per questo che lo studente
		# ha visto il blocco solo quando sbagliava.
		var nodo_corrente := _nodo(formato)
		player.call("_score_current", false, nodo_corrente)
		await process_frame
		await process_frame
		# **Il metro e' la viewport vera, non un numero che ho scritto io.**
		#
		# Al primo tentativo confrontavo con una costante di 560 px, convinto di
		# aver rimpicciolito la finestra con `root.get_window().size`. In headless
		# quella riga non ha effetto: la viewport restava quella di progetto, e
		# l'audit dichiarava un difetto misurando contro un'altezza inventata.
		# Stavo per "riparare" un guasto sulla base di un metro sbagliato.
		var altezza := root.get_visible_rect().size.y
		var pannello := player.find_child("ExercisePanel", true, false) as Control
		if pannello != null:
			var fondo := pannello.get_global_rect().end.y
			if fondo > altezza + 1.0:
				_fallisci("%s: sbagliando, il riquadro finisce a y=%.0f su una viewport alta %.0f" % [
					formato, fondo, altezza])
		var avanti := player.find_child("ExerciseNextButton", true, false) as Button
		if avanti != null and avanti.visible:
			var giu := avanti.get_global_rect().end.y
			if giu > altezza + 1.0:
				_fallisci("%s: sbagliando, AVANTI finisce a y=%.0f (viewport %.0f) — da li' non si prosegue" % [
					formato, giu, altezza])

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

	# **4 · il caso della segnalazione: VERIFICA con un diagramma alto.**
	#
	# Qui il contenuto è alto per forza — c'è un disegno — ed è la situazione in
	# cui il pulsante spariva sotto il bordo. Si misura la cosa che conta per chi
	# gioca: il rettangolo del pulsante, dentro la viewport, senza scorrere.
	var provati := 0
	for formato in ["number_line", "ordering", "cycle"]:
		var player := ExercisePlayer.new()
		player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(player)
		player.start_session(_sessione_interattiva(formato))
		await process_frame
		await process_frame

		var altezza := root.get_visible_rect().size.y
		var barra := player.find_child("ExerciseActionBar", true, false) as Control
		var verifica := player.find_child("InteractionSubmit", true, false) as Button
		if verifica == null:
			# Non tutti i formati costruiscono la riga ANNULLA/VERIFICA: dove non
			# c'è, la prova si consegna in un altro modo e non c'è niente da
			# controllare qui.
			player.queue_free()
			await process_frame
			continue
		provati += 1
		if barra == null or not barra.is_ancestor_of(verifica):
			_fallisci("%s: VERIFICA non sta nella barra fissa" % formato)
		var giu := verifica.get_global_rect().end.y
		if giu > altezza + 1.0:
			_fallisci("%s: VERIFICA finisce a y=%.0f su una viewport alta %.0f — e' il difetto della segnalazione" % [
				formato, giu, altezza])
		if verifica.get_global_rect().position.y < 0.0:
			_fallisci("%s: VERIFICA finisce sopra il bordo alto della viewport" % formato)
		player.queue_free()
		await process_frame

	# **5 · se c'è spazio, non si scorre.** (15 agosto 2026)
	#
	# Segnalazione con schermata: le tessere da ordinare stavano in una
	# finestrella con la sua barra di scorrimento mentre sotto restavano
	# settecento pixel vuoti. Far scorrere un bambino per vedere una cosa che ci
	# starebbe è lavoro inutile che il gioco gli chiede.
	#
	# La causa era strutturale: dentro uno ScrollContainer i figli ricevono la
	# loro altezza MINIMA, quindi `EXPAND_FILL` sull'area delle opzioni non aveva
	# effetto e restava ai suoi 180 px su qualunque schermo. Qui si verifica il
	# risultato: su una finestra alta, con poco contenuto, la barra interna non
	# deve comparire.
	root.get_window().size = Vector2i(900, 1180)
	for formato in ["ordering", "multiple_choice"]:
		var player := ExercisePlayer.new()
		player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(player)
		player.start_session(_sessione_interattiva(formato) if formato == "ordering" else _sessione(formato))
		for _giro in range(4):
			await process_frame
		var opzioni := player.find_child("ExerciseOptionsScroll", true, false) as ScrollContainer
		if opzioni != null:
			var barra_v := opzioni.get_v_scroll_bar()
			var contenuto := 0.0
			for figlio in opzioni.get_children():
				var controllo := figlio as Control
				if controllo != null and controllo.visible:
					contenuto = maxf(contenuto, controllo.get_combined_minimum_size().y)
			if barra_v != null and barra_v.visible and contenuto <= opzioni.size.y + 1.0:
				_fallisci("%s: la barra di scorrimento compare pur avendo spazio (contenuto %.0f, area %.0f)" % [
					formato, contenuto, opzioni.size.y])
		player.queue_free()
		await process_frame
	root.get_window().size = FINESTRA

	# Un controllo che non trova mai il pulsante non sta controllando niente: se
	# nessuno dei tre formati costruisce VERIFICA, questo audit è una finzione e
	# deve dirlo invece di stare zitto.
	if provati == 0:
		_fallisci("nessun formato interattivo ha prodotto VERIFICA: il controllo non tocca il difetto")
	else:
		print("  VERIFICA misurata su %d formati con diagramma" % provati)

	if errori.is_empty():
		print(OK)
	else:
		printerr("EXERCISE REACHABILITY audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
