extends SceneTree

## Sonda: **quanto costa davvero salire di livello?**
##
## Nasce da un'osservazione del committente su un giocatore vero: la tendenza a
## fare il minimo indispensabile per passare al mondo dopo. Prima di cambiare la
## difficoltà serve sapere qual è, oggi, quel minimo — in esercizi e in argomenti
## toccati, non a sensazione.

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)

	print("Costo per livello — gate a 12 materie, copertura scalata
")
	print("%-6s %-13s %9s %10s %12s" % ["MONDO", "MATERIA", "esercizi", "cumulato", "copertura"])
	var cumulato := 0
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if save.level() != livello:
			break
		var focus := ApparatusConfig.world_subject(livello)
		var esercizi := 0
		var giri := 0
		while (not prog.can_repair() or not prog.can_level_up()) and giri < 300:
			for subject_data in ApparatusConfig.SUBJECT_CYCLE:
				var s := str(subject_data)
				var mission: Dictionary = content.build_mission(
					s, save.level(), 3, SpacedRepetition.due_map(save),
					null, save.mastery_of(s), save.topic_masteries(s))
				var nodes: Array = mission.get("nodes", [])
				if s == focus:
					prog.record_mission(s, nodes.size(), nodes.size(), 0)
				else:
					prog.record_practice(s, nodes.size(), nodes.size(), 0)
				prog.record_topic_stats(s, _topic_stats(nodes))
				esercizi += nodes.size()
			giri += 1
		if giri >= 300:
			var stato: Dictionary = prog.readiness()
			print("  BLOCCATO al mondo %d. Materie non pronte:" % livello)
			for materia_data in Array(stato.get("missing", [])).slice(0, 4):
				var m := str(materia_data)
				var d: Dictionary = Dictionary(stato.get("subjects", {})).get(m, {})
				print("    %-12s motivi=%s  copertura=%d/%d  padronanza=%.2f" % [
					m, str(d.get("reasons", [])),
					save.topics_seen_this_level(m),
					GateReadiness.coverage_target(content.reachable_topic_count(m, livello), livello),
					float(d.get("mastery", 0.0))])
			break
		esercizi += 5   # l'esame
		cumulato += esercizi
		var richiesti := GateReadiness.coverage_target(content.reachable_topic_count(focus, livello), livello)
		prog.repair_apparatus(focus, true)
		prog.advance_level()
		print("%-6d %-13s %9d %10d %12d" % [livello, focus, esercizi, cumulato, richiesti])
		if save.level() == livello:
			print("  (fermo)")
			break
	print("
Totale campagna: %d esercizi · a ~20 s l'uno, circa %d ore" % [
		cumulato, int(cumulato * 20 / 3600)])
	quit(0)
