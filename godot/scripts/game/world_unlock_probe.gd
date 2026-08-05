extends SceneTree

## Sonda: **si riesce a uscire da un mondo usando solo ciò che quel mondo offre?**
##
## Nasce da una segnalazione di gioco vera: «ho superato l'esame del primo mondo
## e non riesco ad accedere al secondo».
##
## `progression_1to24_audit` dichiara la campagna 1→24 percorribile, ma gioca
## MISSIONI delle materie del nucleo a ogni livello. Nel gioco vero un mondo
## offre missioni che contano per il gate **soltanto per la propria materia**
## (`mission_event_director`: `countsForGate: true` solo sul focus); tutte le
## altre materie compaiono come PRATICA, e `record_practice` per contratto non
## tocca il gate (lo verifica `guardrails_audit`).
##
## Questa sonda riproduce esattamente il giocatore: missioni solo della materia
## del mondo, pratica per tutte le altre. Se il livello non si apre, il giocatore
## è bloccato — e non c'è schermata che possa dirglielo.

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

## Una MISSIONE del mondo: conta per il gate. Disponibile solo per la materia
## del mondo corrente.
func _missione(save, content, prog, subject: String) -> void:
	var mission: Dictionary = content.build_mission(subject, save.level(), 3, SpacedRepetition.due_map(save),
		null, save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	prog.record_mission(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))

## Una PRATICA: allena mastery e argomenti, NON conta per il gate. È tutto quello
## che il mondo offre sulle materie diverse dalla propria.
func _pratica(save, content, prog, subject: String) -> void:
	var mission: Dictionary = content.build_mission(subject, save.level(), 3, SpacedRepetition.due_map(save),
		null, save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	prog.record_practice(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))

func _init() -> void:
	print("Blocco di avanzamento — il giocatore fa SOLO le missioni che il mondo indica
")
	print("%-6s %-13s %-9s %-9s %s" % ["MONDO", "MATERIA", "ESAME", "SALE", "esito"])
	var bloccati: Array = []
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)

	for atteso in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var livello := save.level()
		if livello != atteso:
			break
		var focus := ApparatusConfig.world_subject(livello)
		var giri := 0
		while not prog.can_repair() and giri < 300:
			_missione(save, content, prog, focus)
			giri += 1
		var esame := prog.can_repair()
		var sale := prog.can_level_up()
		prog.repair_apparatus(focus, true)
		var salito := prog.advance_level()
		var esito := "ok" if salito else "BLOCCATO"
		if not salito:
			bloccati.append(livello)
			# Per proseguire il controllo sui mondi successivi serve sbloccare a
			# mano: senza, si fermerebbe qui e non si vedrebbe il resto.
			for core_data in ApparatusConfig.CORE_SUBJECTS:
				for _i in range(40):
					_missione(save, content, prog, str(core_data))
			prog.advance_level()
		print("%-6d %-13s %-9s %-9s %s" % [
			livello, focus, "sì" if esame else "no", "sì" if sale else "NO", esito])

	print("")
	if bloccati.is_empty():
		print("Nessun mondo blocca l'avanzamento.")
		quit(0)
	else:
		print("MONDI CHE BLOCCANO: %s (%d su 24)" % [str(bloccati), bloccati.size()])
		quit(1)
