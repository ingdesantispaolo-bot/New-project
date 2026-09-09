extends SceneTree

## Guardia della scala 8 x 3: otto fasce di contenuto, tre mondi per fascia.
## Controlla anche che ogni materia possa riempire una sessione della propria
## fascia e che missioni ed esami servano il grado del mondo (tolleranza +/-1
## soltanto per riscaldamento, finale e ripasso).

func _init() -> void:
	var content := ContentManager.new()
	_test_world_mapping()
	_test_bank_capacity(content)
	_test_live_sessions(content)
	print("Difficulty bands audit OK — 8 fasce complete, 3 mondi ciascuna, sessioni ed esami calibrati")
	quit(0)

func _test_world_mapping() -> void:
	assert(ContentManager.DIFFICULTY_BANDS == 8)
	for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
		for level in range((band - 1) * 3 + 1, band * 3 + 1):
			assert(ContentManager.target_difficulty(level) == band,
				"mondo %d: fascia %d invece di %d" % [level, ContentManager.target_difficulty(level), band])

func _test_bank_capacity(content: ContentManager) -> void:
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var counts := content.bank_difficulty_counts(subject)
		var session_size := ApparatusConfig.exercise_nodes_for(subject)
		for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
			assert(int(counts.get(band, 0)) >= session_size,
				"%s fascia %d: %d prove, non bastano per una sessione da %d" % [
					subject, band, int(counts.get(band, 0)), session_size])

func _test_live_sessions(content: ContentManager) -> void:
	for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
		var level := (band - 1) * 3 + 2
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			var expected_count := ApparatusConfig.exercise_nodes_for(subject)
			var rng := RandomNumberGenerator.new()
			rng.seed = 88000 + band * 101 + subject.hash()
			var mission := content.build_varied_mission(subject, level, expected_count, {}, rng)
			var nodes: Array = mission.get("nodes", [])
			assert(nodes.size() == expected_count,
				"%s L%d: sessione da %d invece di %d" % [subject, level, nodes.size(), expected_count])
			for node_data in nodes:
				var difficulty := int((node_data as Dictionary).get("difficulty", 0))
				assert(absi(difficulty - band) <= 1,
					"%s L%d: prova d%d fuori dalla finestra della fascia %d" % [subject, level, difficulty, band])

		var exam_rng := RandomNumberGenerator.new()
		exam_rng.seed = 99000 + band
		var exam := content.build_final_exam("matematica", level, 3, exam_rng)
		var exam_nodes: Array = exam.get("nodes", [])
		assert(exam_nodes.size() == ContentManager.PRIORITY_EXAM_NODES,
			"esame L%d incompleto: %d prove" % [level, exam_nodes.size()])
		for node_data in exam_nodes:
			var difficulty := int((node_data as Dictionary).get("difficulty", 0))
			assert(absi(difficulty - band) <= 1,
				"esame L%d: prova d%d fuori dalla finestra della fascia %d" % [level, difficulty, band])
