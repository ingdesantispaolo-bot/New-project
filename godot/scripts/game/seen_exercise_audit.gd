extends SceneTree

## Una prova mostrata non deve ricomparire cambiando mondo o entrando in esame.
## L'esito non conta: la memoria registra anche una domanda sbagliata o una
## sessione abbandonata, mentre il ripasso richiama l'argomento con una variante.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _presentation_is_recorded_on_abandon()
	_save_index_is_live()
	_cross_world_missions_do_not_repeat()
	_exams_use_the_same_deck()
	print("Seen exercise audit OK — memoria globale attiva in missioni, abbandono ed esami")
	quit(0)

func _presentation_is_recorded_on_abandon() -> void:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 71001
	var session := content.build_mission("italiano", 4, 3, {}, rng)
	var player := ExercisePlayer.new()
	root.add_child(player)
	var holder := {"result": {}}
	player.session_finished.connect(func(result): holder["result"] = result)
	player.start_session(session)
	player._abandon()
	var result: Dictionary = holder["result"]
	var seen: Dictionary = result.get("seenExercises", {})
	assert(Array(seen.get("italiano", [])).size() == 1,
		"l'abbandono non ha ricordato l'unica prova effettivamente mostrata")
	player.queue_free()
	await process_frame

func _save_index_is_live() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	content.seen_by_subject = save.seen_index()
	save.remember_seen("fisica", [42])
	assert(Dictionary(content.seen_by_subject.get("fisica", {})).has(42),
		"l'indice delle prove viste non si aggiorna per riferimento")

func _cross_world_missions_do_not_repeat() -> void:
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var save := GameSaveManager.new()
		var first_content := ContentManager.new()
		first_content.seen_by_subject = save.seen_index()
		var first_rng := RandomNumberGenerator.new()
		first_rng.seed = 72000 + subject.hash()
		var count := ApparatusConfig.exercise_nodes_for(subject)
		var first := first_content.build_varied_mission(subject, 4, count, {}, first_rng)
		_remember_nodes(save, Array(first.get("nodes", [])))

		# Mondo diverso, stessa fascia e stesso seme: senza memoria globale sarebbe
		# la riproduzione piu' aggressiva possibile della stessa sessione.
		var second_content := ContentManager.new()
		second_content.seen_by_subject = save.seen_index()
		var second_rng := RandomNumberGenerator.new()
		second_rng.seed = 72000 + subject.hash()
		var second := second_content.build_varied_mission(subject, 5, count, {}, second_rng)
		assert(_overlap(save, subject, Array(second.get("nodes", []))) == 0,
			"%s: una prova del mondo 4 e' ricomparsa nel mondo 5" % subject)

func _exams_use_the_same_deck() -> void:
	var save := GameSaveManager.new()
	var first_content := ContentManager.new()
	first_content.seen_by_subject = save.seen_index()
	var first_rng := RandomNumberGenerator.new()
	first_rng.seed = 73001
	var first := first_content.build_final_exam("matematica", 7, 3, first_rng)
	_remember_nodes(save, Array(first.get("nodes", [])))

	var second_content := ContentManager.new()
	second_content.seen_by_subject = save.seen_index()
	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 73001
	var second := second_content.build_final_exam("matematica", 8, 3, second_rng)
	for node_data in Array(second.get("nodes", [])):
		var node := node_data as Dictionary
		var subject := str(node.get("subject", ""))
		assert(not save.has_seen(subject, node),
			"esame: prova gia' mostrata ripescata per %s" % subject)

func _remember_nodes(save: GameSaveManager, nodes: Array) -> void:
	var per_subject: Dictionary = {}
	for node_data in nodes:
		var node := node_data as Dictionary
		var subject := str(node.get("subject", ""))
		var prints: Array = per_subject.get(subject, [])
		prints.append(GameSaveManager.solved_fingerprint(node))
		per_subject[subject] = prints
	save.remember_seen_map(per_subject)

func _overlap(save: GameSaveManager, subject: String, nodes: Array) -> int:
	var count := 0
	for node_data in nodes:
		if save.has_seen(subject, node_data as Dictionary):
			count += 1
	return count
