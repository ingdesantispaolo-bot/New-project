extends SceneTree

## **Per quanti argomenti NORA non ha niente da dire?** (15 agosto 2026)
##
## Nasce da una segnalazione con schermata: la scheda «NUOVO CONCETTO · NORA
## SPIEGA» compariva vuota — «Concetto di numeri in matematica» ripetuto due
## volte e un ESEMPIO SVOLTO senza esempio.
##
## La causa non era la scheda: era che `KnowledgeCodex.runtime_topics()` enumera
## i topic dei **banchi** e i concetti di matematica, mentre il gioco serve anche
## i topic dei **minigiochi** (`MinigameManager.topics_for`). `codex_teaching_audit`
## pretende da sempre spiegazione ed esempio per ogni topic che conosce, ed era
## verde: non guardava dove il buco stava.
##
## Questa sonda misura il buco prima di deciderne il rimedio: conta, materia per
## materia, quanti argomenti realmente serviti hanno una lezione con sostanza
## (`KnowledgeCodex.lezione_ha_sostanza`) e quanti no, ed elenca i primi scoperti.
##
## Uso: godot --headless --path godot --script res://scripts/game/teaching_coverage_probe.gd

func _init() -> void:
	var content := ContentManager.new()
	var codex := KnowledgeCodex.new(content)

	var noti := codex.runtime_topics()
	var totale_serviti := 0
	var scoperti: Array = []
	var per_materia: Array = []

	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var topics: Dictionary = {}
		for topic in content.bank_topics(subject):
			topics[str(topic)] = true
		for topic in MinigameManager.topics_for(subject):
			topics[str(topic)] = true
		var vuoti := 0
		for topic_data in topics.keys():
			var topic := str(topic_data)
			totale_serviti += 1
			var lesson := codex.mini_lesson(subject, topic)
			if not KnowledgeCodex.lezione_ha_sostanza(lesson):
				vuoti += 1
				scoperti.append("%s:%s%s" % [
					subject, topic,
					"" if noti.has("%s:%s" % [subject, topic]) else "  (invisibile all'audit)"])
		per_materia.append("%-13s %3d serviti · %3d senza lezione" % [subject, topics.size(), vuoti])

	for riga in per_materia:
		print(riga)
	print("")
	print("argomenti serviti dal gioco : %d" % totale_serviti)
	print("senza lezione con sostanza  : %d (%d%%)" % [
		scoperti.size(), int(round(float(scoperti.size()) / maxf(float(totale_serviti), 1.0) * 100.0))])
	print("")
	print("i primi trenta scoperti:")
	for indice in range(mini(30, scoperti.size())):
		print("  %s" % str(scoperti[indice]))
	quit(0)
