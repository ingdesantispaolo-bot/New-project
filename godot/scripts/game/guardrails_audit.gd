extends SceneTree

const LearningConfig = preload("res://scripts/game/learning_config.gd")

## Audit O-P6 (guardrail): verifica gli invarianti che impediscono di falsare
## l'apprendimento — niente grinding, ragionamento senza timer, la padronanza
## cambia SOLO con gli esercizi, i premi non aprono il gate al posto della
## competenza, le materie disattivate non compaiono.
## Uso: godot --headless --path godot --script res://scripts/game/guardrails_audit.gd

func _init() -> void:
	var content := ContentManager.new()

	# 1) Ragionamento SENZA tempo: tutte le materie tranne la matematica (fluency)
	# sono non cronometrate, e nessuna sessione è timed oggi.
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var untimed := ContentManager.is_untimed(str(subject))
		if str(subject) == "matematica":
			assert(not untimed, "la matematica è l'unica fluency")
		else:
			assert(untimed, "%s (ragionamento) non deve avere limite di tempo" % subject)
		var session := content.build_mission(str(subject), 1, 3)
		assert(not bool(session.get("timed", false)), "nessuna sessione deve essere cronometrata (%s)" % subject)

	# 2) Anti-grinding: la PRATICA (minigiochi) non conta per il gate. Ripeterla
	# non fa avanzare il progresso-verso-gate né apre il gate.
	var save := GameSaveManager.new()
	var prog := ProgressionManager.new(save, content)
	var focus := str(prog.current_gate()["subject"])
	for _i in range(20):
		prog.record_practice(focus, 3, 3, 12)
	assert(save.missions_toward_gate(focus) == 0, "la pratica non deve contare per il gate")

	# 3) La padronanza cambia SOLO con gli esercizi, mai con l'economia. Energia e
	# frammenti (guadagni/spese/acquisti) non toccano la mastery.
	var save2 := GameSaveManager.new()
	save2.set_mastery("matematica", 0.5)
	var before := save2.mastery_of("matematica")
	save2.add_energy(1000)
	save2.add_fragments(1000)
	save2.spend_energy(300)
	assert(save2.mastery_of("matematica") == before, "energia/frammenti non devono cambiare la padronanza")

	# 4) I premi NON saltano la competenza: molta energia/frammenti non aprono il
	# gate senza padronanza e copertura.
	var save3 := GameSaveManager.new()
	var prog3 := ProgressionManager.new(save3, content)
	save3.add_energy(99999)
	save3.add_fragments(99999)
	assert(not prog3.can_repair(), "il gate non deve aprirsi con la sola ricchezza, serve competenza")

	# 5) Materie disattivate non compaiono tra quelle attive (config).
	var save4 := GameSaveManager.new()
	assert(LearningConfig.active_subjects(save4).size() == 12, "default: tutte le 12 materie attive")
	assert(LearningConfig.set_active_subjects(save4, ["matematica", "italiano", "inglese"]))
	assert(LearningConfig.active_subjects(save4).size() == 3, "solo le materie configurate restano attive")
	assert(not LearningConfig.is_subject_active(save4, "latino"), "una materia disattivata non deve essere attiva")
	assert(not LearningConfig.set_active_subjects(save4, []), "l'insieme delle materie attive non può essere vuoto")

	print("Guardrails audit OK — ragionamento senza timer, pratica non farma il gate, padronanza solo dagli esercizi, premi non saltano la competenza, materie configurabili")
	quit(0)
