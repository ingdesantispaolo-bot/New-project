extends SceneTree

## Vertical slice del Messaggio fuori tempo: progressione dai tempi
## dell'indicativo ai modi indefiniti e al periodo ipotetico, contratto valido e
## tre ghiere realmente giocabili nel renderer.

func _init() -> void:
	var manager := MinigameManager.new()
	var cases: Dictionary = {}
	var topics: Dictionary = {}
	var checked := 0
	for level in [1, 6, 13, 24]:
		for seed_value in range(64):
			var rng := RandomNumberGenerator.new()
			rng.seed = level * 4099 + seed_value
			var node := manager._verb_decoder_node("italiano", level, 0, rng, seed_value)
			var validation := ExerciseInteraction.validate(node)
			assert(bool(validation.get("ok", false)),
				"messaggio non valido L%d seed%d: %s" % [level, seed_value, str(validation.get("errors", []))])
			var result := ExerciseInteraction.evaluate_verb_decoder(node, node.get("solution", {}))
			assert(bool(result.get("correct", false)), "la soluzione dichiarata non apre il messaggio")
			assert("_____" not in str(result.get("rendered", "")), "la soluzione lascia il verbo vuoto")
			var id := str(node.get("id", ""))
			cases[id.get_slice("-", 3)] = true
			topics[str(node.get("topic", ""))] = true
			checked += 1
	assert(cases.size() >= 12, "troppi pochi casi verbali incontrati: %s" % str(cases.keys()))
	assert(topics.size() >= 4, "la progressione non copre abbastanza famiglie verbali: %s" % str(topics.keys()))
	_test_player(manager)
	print("VERB DECODER audit OK — %d casi validi, %d scene e %d famiglie verbali" % [checked, cases.size(), topics.size()])
	quit(0)

func _test_player(manager: MinigameManager) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260810
	var node := manager._verb_decoder_node("italiano", 24, 0, rng, 0)
	var session := {
		"sessionId": "verb-decoder-audit", "kind": "minigame",
		"subject": "italiano", "level": 24, "nodes": [node], "shields": 3,
		"pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 0}},
	}
	var player := ExercisePlayer.new()
	root.add_child(player)
	player.start_session(session)
	assert(player.find_child("VerbEvidence", true, false) != null, "mancano gli indizi narrativi")
	assert(player.find_child("VerbMessagePreview", true, false) != null, "manca il messaggio da ricostruire")
	assert(player.find_child("VerbAxis_time", true, false) != null, "manca la ghiera del tempo")
	assert(player.find_child("VerbAxis_mood", true, false) != null, "manca la ghiera del modo")
	assert(player.find_child("VerbAxis_form", true, false) != null, "manca la ghiera della forma")
	var solution := node.get("solution", {}) as Dictionary
	for axis in ["time", "mood", "form"]:
		player._verb_select(axis, str(solution.get(axis, "")), node)
	var result := ExerciseInteraction.evaluate_verb_decoder(node, player._verb_selection)
	player._finish_verb_decode(node, result)
	assert(bool(player._answered), "il messaggio ricostruito non conclude la tappa")
	assert(int(player._correct) == 1, "il messaggio ricostruito non vale una riuscita")
	assert("INDIZIO RECUPERATO" in str(player._verb_preview.text), "la scoperta narrativa non appare")
	player.queue_free()
