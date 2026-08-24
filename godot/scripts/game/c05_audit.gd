extends SceneTree

# Il gate del livello chiede la materia assegnata dal mondo: completare tutti i
# compiti dichiarati deve bastare a sbloccare il mondo seguente.
## Evidenza su abbastanza argomenti da soddisfare la COPERTURA a qualunque
## livello. Dal 5 agosto 2026 la copertura richiesta cresce col livello e scala
## con la materia (prima c'era un tetto fisso di tre): una fixture con tre
## argomenti non basta più, e falliva senza che ci fosse niente di rotto.
func _evidenza_larga() -> Dictionary:
	var stats: Dictionary = {}
	for i in range(24):
		stats["t%d" % (i + 1)] = {"seen": 3, "correct": 3}
	return stats

func _init() -> void:
	assert(ApparatusConfig.SUBJECT_CYCLE.size() == 12, "la progressione deve includere tutte le 12 materie")
	var first_cycle := {}
	var content := ContentManager.new()
	for level in range(1, 13):
		var subject := ApparatusConfig.world_subject(level)
		first_cycle[subject] = true
		assert(not Array(content.build_mission(subject, level, 1).get("nodes", [])).is_empty(),
			"banco contenuti assente per %s" % subject)
	assert(first_cycle.size() == 12, "il primo ciclo deve visitare 12 materie distinte")
	for level in [1, 2, 6, 12, 20, 24]:
		var gate := ApparatusConfig.level_gate(level)
		assert(int(gate["level"]) == level)
		assert(float(gate["masteryThreshold"]) >= 0.70 and float(gate["masteryThreshold"]) <= 0.90)
		assert(Array(gate["coreSubjects"]) == [ApparatusConfig.world_subject(level)],
			"il gate del livello deve chiedere la materia del mondo")
	var save := GameSaveManager.new()
	var progression := ProgressionManager.new(save, content)
	save.set_level(1)
	# Il livello e l'apparato si aprono con la materia assegnata dal mondo.
	for _i in range(5):
		var core_subject := ApparatusConfig.world_subject(save.level())
		progression.record_mission(core_subject, 3, 3, 10, true)
		# Evidenza per-argomento: alimenta la dimensione COPERTURA del gate.
		progression.record_topic_stats(core_subject, _evidenza_larga())
	assert(progression.can_repair(), "l'apparato di matematica deve essere riparabile")
	assert(progression.can_level_up(), "i compiti del mondo pronti devono aprire il livello")
	assert(progression.repair_and_advance(true))
	assert(save.level() == 2)
	# Cumulativo preservato; azzerato solo il progresso-verso-gate (gate consumato).
	assert(save.missions_toward_gate("matematica") == 0)
	assert(save.data["apparatus"]["nucleo"]["repairedLevel"] == 1)
	print("C-05 audit OK — gate locale, livelli 1/2/6/12/20/24 e reset apparato")
	quit(0)
