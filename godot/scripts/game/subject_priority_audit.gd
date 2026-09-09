extends SceneTree

## Verifica la gerarchia 50/35/15 senza trasformare la terza fascia in materia
## facoltativa: tutte le dodici restano nel gate, mentre progresso ed esami
## rispettano le quote entro cinque punti percentuali.

func _init() -> void:
	var seen: Dictionary = {}
	var weight_total := 0.0
	for tier in [1, 2, 3]:
		var subjects := ApparatusConfig.tier_subjects(tier)
		assert(not subjects.is_empty(), "fascia %d vuota" % tier)
		for subject_data in subjects:
			var subject := str(subject_data)
			assert(not seen.has(subject), "materia duplicata nelle fasce: %s" % subject)
			seen[subject] = true
			assert(ApparatusConfig.priority_tier(subject) == tier)
		weight_total += ApparatusConfig.tier_weight(tier)
	assert(seen.size() == ApparatusConfig.SUBJECT_CYCLE.size(), "le fasce devono coprire tutte le materie")
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		assert(seen.has(str(subject)), "materia fuori dalle fasce: %s" % subject)
	assert(is_equal_approx(weight_total, 1.0), "le quote devono sommare 100%%")
	assert(ApparatusConfig.subject_mastery_threshold("matematica", 24) > ApparatusConfig.subject_mastery_threshold("fisica", 24))
	assert(ApparatusConfig.subject_mastery_threshold("fisica", 24) > ApparatusConfig.subject_mastery_threshold("storia", 24))
	assert(GateReadiness.coverage_target(20, 12, true) > GateReadiness.coverage_target(20, 12, false),
		"le fasce alte devono richiedere piu' copertura")
	var exercise_total := 0
	var exercise_by_tier := {1: 0, 2: 0, 3: 0}
	for tier in [1, 2, 3]:
		var tier_exercises := ApparatusConfig.tier_subjects(tier).size() * int(ApparatusConfig.EXERCISE_NODES_BY_TIER[tier])
		exercise_by_tier[tier] = tier_exercises
		exercise_total += tier_exercises
	for tier in [1, 2, 3]:
		var exercise_share := float(exercise_by_tier[tier]) / float(exercise_total)
		assert(absf(exercise_share - ApparatusConfig.tier_weight(tier)) <= ApparatusConfig.PRIORITY_TOLERANCE,
			"esercizi fascia %d al %.1f%%" % [tier, exercise_share * 100.0])

	var gate: Dictionary = ApparatusConfig.level_gate(1)
	assert(Array(gate["coreSubjects"]).size() == 12, "il gate deve continuare a chiedere tutte le materie")

	var content := ContentManager.new()
	# Il percorso vivo deve usare davvero 6/5/1, non limitarsi ad avere le
	# costanti corrette sulla carta.
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var expected := ApparatusConfig.exercise_nodes_for(subject)
		var practice_rng := RandomNumberGenerator.new()
		practice_rng.seed = 47000 + subject.hash()
		var mission := content.build_varied_mission(subject, 12, expected, {}, practice_rng)
		assert(Array(mission.get("nodes", [])).size() == expected,
			"%s: esercizi reali diversi dalla numerosita' della fascia (%d)" % [subject, expected])
	for level in [1, 8, 16, 24]:
		for host_data in ApparatusConfig.SUBJECT_CYCLE:
			var host := str(host_data)
			var rng := RandomNumberGenerator.new()
			rng.seed = 5000 + level * 31 + ApparatusConfig.SUBJECT_CYCLE.find(host)
			var exam := content.build_final_exam(host, level, 3, rng)
			var nodes: Array = exam.get("nodes", [])
			assert(nodes.size() == ContentManager.PRIORITY_EXAM_NODES, "%s L%d: esame incompleto" % [host, level])
			assert(bool(exam.get("weightedScoring", false)), "%s: manca il voto pesato" % host)
			var counts := {1: 0, 2: 0, 3: 0}
			var scores := {1: 0.0, 2: 0.0, 3: 0.0}
			var host_seen := false
			for node_data in nodes:
				var node: Dictionary = node_data
				var subject := str(node.get("subject", ""))
				var tier := ApparatusConfig.priority_tier(subject)
				counts[tier] = int(counts[tier]) + 1
				scores[tier] = float(scores[tier]) + float(node.get("scoreWeight", 0.0))
				host_seen = host_seen or subject == host
			assert(host_seen, "%s L%d: la materia del mondo deve restare nell'esame" % [host, level])
			for tier in [1, 2, 3]:
				var share := float(counts[tier]) / float(nodes.size())
				var target := ApparatusConfig.tier_weight(tier)
				assert(absf(share - target) <= ApparatusConfig.PRIORITY_TOLERANCE + 0.00001,
					"%s L%d: fascia %d al %.1f%%, atteso %.1f%% +/-5" % [host, level, tier, share * 100.0, target * 100.0])
				assert(is_equal_approx(float(scores[tier]), target),
					"%s L%d: peso voto fascia %d non esatto" % [host, level, tier])

	var final_exam := content.build_final_transversal_exam(24)
	var final_scores := {1: 0.0, 2: 0.0, 3: 0.0}
	for node_data in Array(final_exam.get("nodes", [])):
		var node: Dictionary = node_data
		if str(node.get("system", "")) == "sintesi":
			assert(is_zero_approx(float(node.get("scoreWeight", -1.0))), "la sintesi non deve alterare le quote")
			continue
		var tier := ApparatusConfig.priority_tier(str(node.get("subject", "")))
		final_scores[tier] = float(final_scores[tier]) + float(node.get("scoreWeight", 0.0))
	for tier in [1, 2, 3]:
		assert(is_equal_approx(float(final_scores[tier]), ApparatusConfig.tier_weight(tier)),
			"finale: quota fascia %d errata" % tier)
	# Nove risposte su tredici supererebbero la vecchia soglia grezza, ma non se
	# valgono soltanto il 50% del profilo: prova che i pesi entrano nel verdetto.
	assert(not ExercisePlayer.session_score_passed(final_exam, 9, 13, 0.50, 1.0, 1),
		"il voto ha ignorato le fasce e usato il solo numero di risposte")
	assert(ExercisePlayer.session_score_passed(final_exam, 9, 13, 0.75, 1.0, 1),
		"il 75% pesato deve superare la soglia")

	print("Subject priority audit OK — tutte le materie obbligatorie; percorso ed esami 50/35/15 (+/-5%)")
	quit(0)
