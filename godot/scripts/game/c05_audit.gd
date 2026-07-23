extends SceneTree

func _init() -> void:
	assert(ApparatusConfig.SUBJECT_CYCLE.size() == 12, "la progressione deve includere tutte le 12 materie")
	var first_cycle := {}
	var content := ContentManager.new()
	for level in range(1, 13):
		var cycle_gate := ApparatusConfig.level_gate(level)
		var subject := str(cycle_gate["subject"])
		first_cycle[subject] = true
		assert(not Array(content.build_mission(subject, level, 1).get("nodes", [])).is_empty(),
			"banco contenuti assente per %s" % subject)
	assert(first_cycle.size() == 12, "il primo ciclo deve visitare 12 materie distinte")
	for level in [1, 2, 6, 12, 20, 24]:
		var gate := ApparatusConfig.level_gate(level)
		assert(int(gate["level"]) == level)
		assert(int(gate["missionsRequired"]) >= 5)
		assert(float(gate["masteryThreshold"]) >= 0.70 and float(gate["masteryThreshold"]) <= 0.90)
		assert(str(gate["subject"]) != "")
		assert(str(gate["apparatus"]) != "")
	var save := GameSaveManager.new()
	var progression := ProgressionManager.new(save, content)
	save.set_level(1)
	for _i in range(5):
		progression.record_mission("matematica", 3, 3, 10, true)
		# Evidenza per-argomento: alimenta la dimensione COPERTURA del gate.
		progression.record_topic_stats("matematica", {"tabelline": {"seen": 3, "correct": 3}})
	assert(progression.can_repair())
	assert(progression.repair_and_advance(true))
	assert(save.level() == 2)
	# Cumulativo preservato; azzerato solo il progresso-verso-gate (gate consumato).
	assert(save.missions_toward_gate("matematica") == 0)
	assert(save.data["apparatus"]["nucleo"]["repairedLevel"] == 1)
	print("C-05 audit OK — 12 materie, gate livelli 1/2/6/12/20/24 e reset apparato")
	quit(0)
