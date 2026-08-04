extends SceneTree

## La ricompensa della pratica: **il Codex, non l'energia.**
##
## Gli undici eventi di pratica di ogni mondo hanno `countsForGate: false`. Non
## aprono apparati, non fanno salire di livello, non sbloccano niente — ed è
## giusto così: alternare materie è pratica migliore di sette missioni di fila
## della stessa. Ma vuol dire che un bambino che punta al traguardo può
## ignorarli tutti, e allora l'unica materia che pratica è quella ospite.
##
## La risposta scelta il 3 agosto non è dare energia — diventerebbe una miniera
## da sfruttare, e la prima volta che l'energia non serve la pratica smette di
## avere senso. È rendere **visibile** ciò che la pratica già produce: un
## argomento che avanza nel manuale di NORA.
##
## Questo audit tiene le tre cose che rendono vera quella promessa.

func _init() -> void:
	var failures: Array = []
	print("La pratica avanza il Codex, e lo dice\n")

	# --- 1 · gli stati hanno un nome che un bambino capisce -------------------
	for state in KnowledgeCodex.STATE_ORDER:
		var label := KnowledgeCodex.state_label(str(state))
		if label == str(state):
			failures.append("lo stato «%s» non ha un'etichetta italiana: comparirebbe così a schermo" % state)
		if label.strip_edges() == "":
			failures.append("lo stato «%s» ha un'etichetta vuota" % state)
	print("stati: %s" % ", ".join(PackedStringArray(
		KnowledgeCodex.STATE_ORDER.map(func(s): return KnowledgeCodex.state_label(str(s))))))

	# --- 2 · una sessione di pratica fa avanzare il Codex e lo riporta --------
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var progression := ProgressionManager.new(save)

	var stats := {"tabelline": {"seen": 4, "correct": 4}, "frazioni": {"seen": 3, "correct": 2}}
	var advanced: Array = progression.record_topic_stats("matematica", stats)
	if advanced.is_empty():
		failures.append("una pratica risolta bene non ha fatto avanzare nessun argomento nel Codex")
	for entry in advanced:
		var row := entry as Dictionary
		for field in ["topic", "da", "a"]:
			if not row.has(field):
				failures.append("l'avanzamento non dichiara «%s»" % field)
		# Il Codex non regredisce mai: è la sua regola fondamentale.
		if KnowledgeCodex._rank(str(row["a"])) <= KnowledgeCodex._rank(str(row["da"])):
			failures.append("«%s» è passato da %s a %s: il Codex non torna indietro" % [
				str(row["topic"]), str(row["da"]), str(row["a"])])
	print("prima pratica: %d argomenti avanzati (%s)" % [
		advanced.size(),
		", ".join(PackedStringArray(advanced.map(
			func(r): return "%s→%s" % [str((r as Dictionary)["topic"]), str((r as Dictionary)["a"])])))])

	# --- 3 · rifarla non regala niente di nuovo -------------------------------
	# Se ripetere la stessa pratica producesse ogni volta un avanzamento, il
	# manuale diventerebbe una barra da riempire a forza di ripetizioni, cioè
	# esattamente la miniera che si voleva evitare.
	var again: Array = progression.record_topic_stats("matematica", stats)
	if again.size() >= advanced.size() and not advanced.is_empty():
		failures.append("ripetere la stessa pratica avanza di nuovo (%d argomenti): il Codex sarebbe una miniera" % again.size())
	print("stessa pratica ripetuta: %d argomenti avanzati" % again.size())

	# --- 4 · il consolidamento non si compra in una sera ----------------------
	# Serve evidenza di ritenzione (tre sessioni distinte, ≥3 giorni), non
	# padronanza alta: quella si raggiunge in una sera e non è ritenzione.
	var stato := KnowledgeCodex.state_of(save, "matematica", "tabelline")
	if stato == KnowledgeCodex.STATE_CONSOLIDATED:
		failures.append("«tabelline» è già consolidato dopo due sessioni nello stesso momento")
	print("dopo due pratiche di fila, «tabelline» è: %s" % KnowledgeCodex.state_label(stato))

	if not failures.is_empty():
		printerr("RICOMPENSA DELLA PRATICA NON VALIDA — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nPractice reward audit OK — la pratica avanza il Codex, una volta sola, e si può dire a voce")
	quit(0)
