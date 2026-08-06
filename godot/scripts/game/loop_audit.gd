extends SceneTree

## Audit headless del loop di Fase 1 su UN livello: missioni esterne → gate a 4
## dimensioni → riparazione apparato → salita di livello. Non richiede rendering.
## Uso: godot --headless --path godot --script res://scripts/game/loop_audit.gd
## (per il playthrough completo 1→24 vedi progression_1to24_audit.gd)

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

# Il gate del livello chiede TUTTE le materie dal 5 agosto 2026: allenare le
# tre strumentali non basta più, e questo audit descriveva la regola vecchia.
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
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	# ContentManager alla progressione: alimenta la dimensione COPERTURA del gate.
	var prog := ProgressionManager.new(save, content)

	assert(save.level() == 1)
	assert(not prog.can_repair())

	var subject := ApparatusConfig.world_subject(save.level())
	var apparatus := ApparatusConfig.apparatus_of(subject)

	# Svolge missioni (tutte corrette) finché il gate del livello non si apre,
	# registrando anche l'evidenza per-argomento (necessaria a copertura/ritenzione).
	var missions_played := 0
	while not prog.can_repair() and missions_played < 200:
		var mission := content.build_mission(subject, save.level(), 3)
		var nodes: Array = mission["nodes"]
		var total := int(nodes.size())
		if total == 0:
			push_error("Banco vuoto per '%s': esegui `node scripts/build-exercise-banks.mjs`" % subject)
			quit(1)
			return
		prog.record_mission(subject, total, total, total * 10)
		prog.record_topic_stats(subject, _topic_stats(nodes))
		missions_played += 1

	assert(prog.can_repair(), "il gate deve aprirsi dopo missioni + padronanza + copertura")

	var level_before := save.level()
	# Riparare un apparato NON fa più salire di livello: sono due assi distinti.
	# Il livello si apre col nucleo, che qui va allenato a parte.
	assert(prog.repair_apparatus(subject, true), "l'esame superato deve riparare l'apparato")
	assert(save.level() == level_before, "la riparazione non deve far salire di livello")
	for core_data in ApparatusConfig.SUBJECT_CYCLE:
		var core_subject := str(core_data)
		for _round in range(6):
			prog.record_mission(core_subject, 3, 3, 0, true)
			prog.record_topic_stats(core_subject, _evidenza_larga())
	assert(prog.can_level_up(), "il nucleo allenato deve aprire il livello")
	# Si misura qui: la salita consuma il progresso-VERSO-gate, non il cumulativo.
	var cumulative_before := save.missions_of(subject)
	assert(prog.advance_level(), "col nucleo pronto si deve salire")
	assert(save.level() == level_before + 1)
	# Il conteggio cumulativo NON si azzera (il lavoro resta); azzera solo il
	# progresso-verso-gate della materia, perché il gate è stato consumato.
	assert(save.missions_of(subject) == cumulative_before, "il conteggio cumulativo resta")
	assert(save.missions_toward_gate(subject) == 0, "progresso-verso-gate azzerato dal consume")
	assert(int(save.data["apparatus"][apparatus]["repairedLevel"]) == level_before)

	print("Loop Fase 1 OK — riparato '%s' (materia %s), ora livello %d dopo %d missioni; energia %d" % [apparatus, subject, save.level(), missions_played, save.energy()])
	quit(0)
