extends SceneTree

## Invariante del percorso studente:
## compiti del mondo -> esame finale -> successo -> mondo successivo.

func _prepara_materia(save: GameSaveManager, subject: String, level: int) -> void:
	save.set_mastery(subject, ApparatusConfig.subject_mastery_threshold(subject, level))
	for topic_index in range(24):
		save.set_topic_mastery(subject, "flow-topic-%d" % topic_index, 1.0)

func _init() -> void:
	var save := GameSaveManager.new()
	var progression := ProgressionManager.new(save, ContentManager.new())
	var level_before := save.level()
	var host := ApparatusConfig.world_subject(level_before)

	_prepara_materia(save, host, level_before)
	assert(progression.can_repair_apparatus(host),
		"la materia ospite deve risultare preparata nella fixture")
	assert(not progression.can_start_final_exam(),
		"l'esame non deve aprirsi con compiti incompleti nelle altre materie")
	assert(not progression.repair_and_advance(true),
		"un esito iniettato non deve aggirare il gate dei compiti")
	assert(save.level() == level_before and not save.is_world_unlocked(level_before + 1))

	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		_prepara_materia(save, str(subject_data), level_before)
	assert(progression.can_level_up(), "tutti i compiti devono completare la preparazione")
	assert(progression.can_start_final_exam(), "tutti i compiti devono aprire l'esame")
	assert(not progression.advance_level(), "i compiti non devono consentire di saltare l'esame")
	assert(not progression.repair_and_advance(false), "un esame fallito non deve aprire il mondo")
	assert(save.level() == level_before and not save.is_world_unlocked(level_before + 1))

	assert(progression.repair_and_advance(true), "l'esame superato deve chiudere il mondo")
	assert(save.level() == level_before + 1, "il livello deve avanzare di uno")
	assert(save.is_world_unlocked(level_before + 1), "il mondo successivo deve essere sbloccato")
	assert(save.current_world() == level_before + 1, "il mondo successivo deve diventare corrente")
	assert(not progression.can_start_final_exam(), "il nuovo mondo deve ripartire con i compiti da fare")

	print("WORLD EXAM FLOW audit OK — compiti -> esame -> successo -> mondo successivo")
	quit(0)
