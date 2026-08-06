extends SceneTree

## Audit headless del percorso completo C-01 (mondo esterno nativo, niente Phaser):
## missioni → gate → esame finale → riparazione apparato → salita di livello,
## usando l'ExercisePlayer reale simulando le risposte.
## Uso: godot --headless --path godot --script res://scripts/game/c01_audit.gd

# Il gate del livello chiede TUTTE le materie dal 5 agosto 2026: allenare le
# tre strumentali non basta più, e questo audit descriveva la regola vecchia.
func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)  # content: dimensione copertura
	save.data["energy"] = 200  # energia iniziale per pagare gli ingressi

	var host := ApparatusConfig.world_subject(save.level())
	assert(save.level() == 1)
	assert(not prog.can_level_up(), "un profilo nuovo non deve poter salire di livello")
	assert(not prog.can_repair_apparatus(host), "un profilo nuovo non deve poter riparare")

	# 1) Missioni sulle TRE materie del nucleo finché il livello non si apre. Il gate
	# non conta più i giri (decisione del 30 luglio): si sale con padronanza,
	# copertura e ritenzione su italiano, matematica e inglese.
	var missions := 0
	while not prog.can_level_up() and missions < 400:
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			var mission := content.build_varied_mission(subject, save.level(), 3)
			assert(not Array(mission["nodes"]).is_empty(), "banco mancante: node scripts/build-exercise-banks.mjs")
			save.add_energy(3)
			assert(save.spend_energy(3), "energia sufficiente per la missione")
			var res := _play(mission, true)
			assert(bool(res["passed"]), "missione con tutte corrette deve passare")
			assert(int(res["energyGained"]) > 0, "risposte corrette danno energia")
			prog.record_mission(subject, int(res["correct"]), int(res["total"]), int(res["energyGained"]), true)
			prog.record_topic_stats(subject, res.get("topicStats", {}))
			missions += 1
	assert(prog.can_level_up(), "il livello deve aprirsi con la padronanza del nucleo")

	# 2) L'apparato si ripara con la padronanza della SUA materia, ed è un atto
	# distinto dal salire di livello: prima erano la stessa cosa.
	var level_before := save.level()
	var exam_missions := 0
	while not prog.can_repair_apparatus(host) and exam_missions < 200:
		var host_mission := content.build_varied_mission(host, save.level(), 3)
		var host_res := _play(host_mission, true)
		prog.record_mission(host, int(host_res["correct"]), int(host_res["total"]), 0, true)
		prog.record_topic_stats(host, host_res.get("topicStats", {}))
		exam_missions += 1
	assert(prog.can_repair_apparatus(host), "l'apparato deve aprirsi con la padronanza della sua materia")

	var exam := content.build_final_exam(host, save.level(), 3)
	assert(str(exam.get("kind", "")) == "final_exam")
	var exam_res := _play(exam, true)
	assert(bool(exam_res["passed"]), "esame con tutte corrette deve passare")
	assert(prog.repair_apparatus(host, true), "l'esame superato deve riparare l'apparato")
	assert(save.level() == level_before, "riparare un apparato NON deve far salire di livello")
	assert(int(save.data["apparatus"][ApparatusConfig.apparatus_of(host)]["repairedLevel"]) == level_before)
	assert(prog.repaired_apparatus_count() == 1, "una stanza accesa")

	# 3) La salita di livello è un atto a sé.
	assert(prog.advance_level(), "col nucleo pronto si deve poter salire")
	assert(save.level() == level_before + 1)

	# 4) Missione fallita (tutte sbagliate): non passa.
	var next_subject := ApparatusConfig.world_subject(save.level())
	var fail_mission := content.build_mission(next_subject, save.level(), 3)
	if not Array(fail_mission["nodes"]).is_empty():
		var fail_res := _play(fail_mission, false)
		assert(not bool(fail_res["passed"]), "missione con tutte sbagliate deve fallire")

	print("C-01 audit OK — livello %d, energia %d dopo %d missioni + esame" % [save.level(), save.energy(), missions])
	quit(0)

# Simula una sessione con l'ExercisePlayer reale, rispondendo sempre giusto o
# sempre sbagliato. Ritorna il dizionario di `session_finished`.
func _play(session: Dictionary, answer_correct: bool) -> Dictionary:
	var player := ExercisePlayer.new()
	root.add_child(player)
	var holder := {"result": {}}
	player.session_finished.connect(func(r): holder["result"] = r)
	player.start_session(session)
	var nodes: Array = session["nodes"]
	for i in range(nodes.size()):
		if not (holder["result"] as Dictionary).is_empty():
			break
		var item: Dictionary = nodes[i]
		if answer_correct:
			_solve_correct(player, item)
		else:
			player._answer("__risposta_sbagliata__")
		player._advance()
	player.queue_free()
	return holder["result"]

# Risolve correttamente il nodo secondo il suo FORMATO (l'esame è multi-formato:
# scelta multipla/inserimento, abbinamento, ordinamento).
func _solve_correct(player: ExercisePlayer, item: Dictionary) -> void:
	match str(item.get("format", "multiple_choice")):
		"matching":
			var pairs: Array = item.get("pairs", [])
			for i in pairs.size():
				player._matching_left(i)
				player._matching_right(str((pairs[i] as Dictionary).get("right", "")), item)
		"ordering":
			# Modello a slot numerati: riempi in ordine corretto, poi invia.
			var items: Array = item.get("items", [])
			var order: Array = item.get("correctOrder", [])
			for expected in order:
				var idx := items.find(expected)
				if idx < 0:
					for k in items.size():
						if str(items[k]) == str(expected):
							idx = k
							break
				if idx >= 0:
					player._ordering_click(idx, item)
			player._ordering_submit(item)
		"classification":
			var assignments: Dictionary = item.get("assignments", {})
			for key in assignments.keys():
				player._classification_assign(str(key), str(assignments[key]))
			player._classification_submit(item)
		"graph", "circuit", "hotspot", "notation", "map":
			player._visual_select(str(item.get("answer", "")))
			player._visual_submit(item)
		"cycle":
			for id in item.get("correctOrder", []):
				player._cycle_select(str(id))
			player._cycle_submit(item)
		"code_debug":
			player._code_line_select(int(item.get("answerLine", 0)))
			player._code_submit(item)
		_:
			player._answer(str(item.get("answer", "")))
