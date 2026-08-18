extends SceneTree

## **Le spiegazioni di NORA devono andare oltre la singola domanda, quando
## serve a capire il contesto — sempre, non solo qualche volta.** (16 agosto
## 2026, segnalazione diretta: «lo scopo del programma deve essere didattico
## non un test».)
##
## `bank_explanation_audit.gd` verifica che ogni ITEM (3412) abbia una
## spiegazione non circolare. `explanation_coverage_audit.gd` verifica che
## ogni FORMATO produca una spiegazione. Nessuno dei due garantiva che
## esistesse, per ogni ARGOMENTO, un contenuto più largo del singolo quesito:
## un item spiega perché QUELLA risposta è giusta; `NoraExplanations` deve
## spiegare perché la REGOLA generale funziona così, con un modo per
## ritrovarsela da soli. Misurato il 16 agosto 2026: **111 argomenti su 246
## (45%) non avevano questa voce** — interamente assenti in fisica (14/22),
## quasi assenti in elettronica (13/21) e scienze (13/21), presenti a
## macchia in ogni altra materia. Uno studente su quei topic riceveva, nella
## grande maggioranza dei casi (l'8% degli item porta già un nesso causale
## nativo), **solo** la riformulazione stretta del singolo quesito — mai il
## contesto più ampio.
##
## Questo audit non rimisura `bank_explanation_audit` (item) né
## `explanation_coverage_audit` (formato): guarda lo strato che li completa,
## l'argomento, ed è la garanzia — non solo la misura — richiesta dalla
## segnalazione: se un giorno un argomento nuovo entra nel runtime senza la
## sua voce di NoraExplanations, questo audit lo blocca.

## Sotto questa soglia una frase non porta abbastanza per contare come
## "contesto": misurato sulle 246 voci reali, la più corta oggi supera i 60.
const MIN_LUNGHEZZA_PERCHE := 40
const MIN_LUNGHEZZA_COME := 30

func _init() -> void:
	var failures: Array = []
	var content := ContentManager.new()
	var codex := KnowledgeCodex.new(content)
	var topics := codex.runtime_topics()

	# 1) Copertura totale: il regalo di questo lavoro non deve poter regredire.
	var mancanti: Array = []
	for key in topics.keys():
		var meta_check: Dictionary = topics[key]
		var v := NoraExplanations.voce(str(meta_check["subject"]), str(meta_check["topic"]))
		if v.is_empty():
			mancanti.append(str(key))
	mancanti.sort()
	if not mancanti.is_empty():
		failures.append("%d argomenti senza voce di contesto in NoraExplanations: %s" % [
			mancanti.size(), ", ".join(PackedStringArray(mancanti.slice(0, 15)))])

	# 2) Qualità di ogni voce: sostanziosa, non un guscio, non duplicata.
	#
	# **Non si usa `NoraExplanations.ha_causa()` come giudice.** Quella funzione
	# è dichiaratamente un criterio di SELEZIONE («questo testo ha già un nesso,
	# non serve aggiungerne un altro»), non un criterio di qualità — il file
	# stesso lo dice a chiare lettere dopo un errore già fatto una volta: trenta
	# voci scritte bene («Le parentesi servono a dire *questo prima*») risultano
	# «senza causa» perché non contengono le parole-spia dell'elenco. Riusarla
	# qui come giudice avrebbe ripetuto esattamente quell'errore.
	var visti_perche: Dictionary = {}
	var visti_come: Dictionary = {}
	for chiave in NoraExplanations.argomenti():
		var parti := str(chiave).split(":")
		if parti.size() != 2:
			failures.append("chiave malformata in NoraExplanations: «%s»" % chiave)
			continue
		var voce := NoraExplanations.voce(parti[0], parti[1])
		var perche := str(voce.get("perche", "")).strip_edges()
		var come := str(voce.get("come", "")).strip_edges()
		if perche.length() < MIN_LUNGHEZZA_PERCHE:
			failures.append("%s: «perche» troppo corto per dare contesto (%d caratteri) — «%s»" % [
				chiave, perche.length(), perche])
		if come.length() < MIN_LUNGHEZZA_COME:
			failures.append("%s: «come» troppo corto per essere un metodo utilizzabile (%d caratteri) — «%s»" % [
				chiave, come.length(), come])
		if perche.to_lower() == come.to_lower():
			failures.append("%s: «perche» e «come» sono la stessa frase" % chiave)
		if visti_perche.has(perche):
			failures.append("%s: stesso «perche» di %s — non è più il contesto di QUESTO argomento" % [
				chiave, str(visti_perche[perche])])
		else:
			visti_perche[perche] = chiave
		if visti_come.has(come):
			failures.append("%s: stesso «come» di %s — non è più il metodo di QUESTO argomento" % [
				chiave, str(visti_come[come])])
		else:
			visti_come[come] = chiave

	# 3) Il collegamento reale: `KnowledgeCodex.entry_for()` deve arrivare a
	# produrre UNA spiegazione non vuota per ogni argomento coperto — altrimenti
	# il contenuto scritto qui esiste ma non arriva mai al bambino, esattamente
	# il difetto descritto in `nora_explanations.gd` per il manuale prima del 12
	# agosto 2026 (spiegazioni scritte, mai mostrate).
	var non_collegati: Array = []
	for key in topics.keys():
		var meta: Dictionary = topics[key]
		var subject := str(meta["subject"])
		var topic := str(meta["topic"])
		var voce := NoraExplanations.voce(subject, topic)
		if voce.is_empty():
			continue
		var entry := codex.entry_for(subject, topic)
		var short_text := str(entry.get("shortExplanation", "")).strip_edges()
		if short_text == "":
			non_collegati.append("%s: ha una voce di contesto ma entry_for() non produce nessuna spiegazione" % key)
	if not non_collegati.is_empty():
		failures.append_array(non_collegati.slice(0, 15))

	if not failures.is_empty():
		printerr("NORA EXPLANATION DEPTH audit ROSSO — %d problemi:" % failures.size())
		for f in failures.slice(0, 30):
			printerr("  - %s" % f)
		quit(1)
		return
	print("Nora explanation depth audit OK — %d argomenti, tutti con contesto più largo della singola domanda, tutti collegati" % [
		NoraExplanations.argomenti().size()])
	quit(0)
