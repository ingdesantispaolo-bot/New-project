extends SceneTree

## Vertical slice del Campione senza nome: casi variabili, risultati coerenti,
## strumenti giocabili e deduzione senza domanda a scelta multipla iniziale.

func _init() -> void:
	var manager := MinigameManager.new()
	var answers: Dictionary = {}
	var checked := 0
	for level in [1, 6, 13, 24]:
		for seed_value in range(32):
			var rng := RandomNumberGenerator.new()
			rng.seed = level * 2027 + seed_value
			var node := manager._mystery_sample_node("scienze", level, 0, rng, seed_value)
			var validation := ExerciseInteraction.validate(node)
			assert(bool(validation.get("ok", false)), "campione non valido L%d seed%d: %s" % [level, seed_value, str(validation.get("errors", []))])
			var answer := str(node.get("answer", ""))
			answers[answer] = int(answers.get(answer, 0)) + 1
			for raw in Array(node.get("tests", [])):
				var test_id := str((raw as Dictionary).get("id", ""))
				assert(ExerciseInteraction.mystery_sample_result(node, test_id) != "", "esperimento muto: %s" % test_id)
			checked += 1
	assert(answers.size() >= 5, "i casi avanzati non fanno comparire tutti i materiali: %s" % str(answers))
	_test_player(manager)
	print("MYSTERY SAMPLE audit OK — %d casi coerenti, 5 materiali e laboratorio giocabile" % checked)
	quit(0)

func _test_player(manager: MinigameManager) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260810
	var node := manager._mystery_sample_node("scienze", 24, 0, rng, 0)
	var session := {
		"sessionId": "mystery-sample-audit", "kind": "minigame",
		"subject": "scienze", "level": 24, "nodes": [node], "shields": 3,
		"pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 0}},
	}
	var player := ExercisePlayer.new()
	root.add_child(player)
	player.start_session(session)
	assert(player.find_child("MysterySampleCapsule", true, false) != null, "manca il campione sigillato")
	assert(player.find_child("MysterySampleTools", true, false) != null, "mancano gli strumenti")
	assert(player.find_child("MysterySampleCandidates", true, false) != null, "mancano le ipotesi")
	var tests: Array = node.get("tests", [])
	for index in int(node.get("minTests", 2)):
		player._sample_run_test(str((tests[index] as Dictionary).get("id", "")), node)
	assert(player._sample_tests_run.size() == int(node.get("minTests", 2)), "gli esperimenti non entrano nel quaderno")
	player._sample_select_candidate(str(node.get("answer", "")))
	player._sample_submit(node)
	assert(bool(player._answered), "la scoperta corretta non conclude la tappa")
	assert(int(player._correct) == 1, "la scoperta corretta non vale una riuscita")
	assert(str(player._feedback.text).begins_with("Funziona!"), "feedback ancora scolastico: %s" % player._feedback.text)
	player.queue_free()
