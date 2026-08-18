extends SceneTree

## Vertical slice del Ponte delle Trasformazioni: contenuto generato valido,
## calcolo condiviso, interazione reale e linguaggio non scolastico.

func _init() -> void:
	var manager := MinigameManager.new()
	for level in [1, 6, 13, 24]:
		for seed_value in range(24):
			var rng := RandomNumberGenerator.new()
			rng.seed = level * 1009 + seed_value
			var node := manager._machine_path_node("matematica", level, 0, rng, seed_value)
			var validation := ExerciseInteraction.validate(node)
			assert(bool(validation.get("ok", false)), "percorso non valido L%d seed%d: %s" % [level, seed_value, str(validation.get("errors", []))])
			var result := ExerciseInteraction.evaluate_machine_path(
				int(node["start"]), Array(node["solution"]), Array(node["machines"]))
			assert(bool(result.get("ok", false)), "la soluzione si blocca")
			assert(int(result.get("value", 0)) == int(node["target"]), "la soluzione non apre il ponte")

	_test_player(manager)
	print("Machine path audit OK — 96 percorsi validi, renderer giocabile e voce 11 anni")
	quit(0)

func _test_player(manager: MinigameManager) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260810
	var node := manager._machine_path_node("matematica", 1, 0, rng, 0)
	var session := {
		"sessionId": "machine-path-audit", "kind": "minigame",
		"subject": "matematica", "level": 1, "nodes": [node], "shields": 3,
		"pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 0}},
	}
	var player := ExercisePlayer.new()
	root.add_child(player)
	player.start_session(session)
	assert(str(player._status.text).begins_with("Tappa 1/1"), "la UI mostra ancora 'Esercizio'")
	assert(player.find_child("MachinePathTrack", true, false) != null, "manca il percorso visuale")
	assert(player.find_child("MachineShelf", true, false) != null, "mancano le macchine da montare")
	for index in Array(node["solution"]).size():
		player._machine_place(str(Array(node["solution"])[index]), index, node)
	var result := ExerciseInteraction.evaluate_machine_path(
		int(node["start"]), Array(node["solution"]), Array(node["machines"]))
	player._finish_machine_run(node, result)
	assert(bool(player._answered), "il percorso riuscito non conclude la tappa")
	assert(int(player._correct) == 1, "il percorso riuscito non vale una riuscita")
	assert(str(player._feedback.text).begins_with("Funziona!"), "feedback ancora scolastico: %s" % player._feedback.text)
	player.queue_free()
