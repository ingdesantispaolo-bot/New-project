extends SceneTree

## Audit headless del percorso completo C-01 (mondo esterno nativo, niente Phaser):
## missioni → gate → esame finale → riparazione apparato → salita di livello,
## usando l'ExercisePlayer reale simulando le risposte.
## Uso: godot --headless --path godot --script res://scripts/game/c01_audit.gd

func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save)
	save.data["energy"] = 200  # energia iniziale per pagare gli ingressi

	var gate := prog.current_gate()
	var subject := str(gate["subject"])
	assert(save.level() == 1)
	assert(not prog.can_repair())

	# 1) Missioni native (tutte corrette) finché il gate non si apre.
	var missions := 0
	while not prog.can_repair() and missions < 200:
		var mission := content.build_mission(subject, save.level(), 3)
		assert(not Array(mission["nodes"]).is_empty(), "banco mancante: node scripts/build-exercise-banks.mjs")
		assert(save.spend_energy(3), "energia sufficiente per la missione")
		var res := _play(mission, true)
		assert(bool(res["passed"]), "missione con tutte corrette deve passare")
		assert(int(res["energyGained"]) > 0, "risposte corrette danno energia")
		prog.record_mission(subject, int(res["correct"]), int(res["total"]), int(res["energyGained"]), true)
		missions += 1
	assert(prog.can_repair(), "il gate deve aprirsi dopo missioni + padronanza")

	# 2) Esame finale → riparazione → salita di livello.
	var level_before := save.level()
	var exam := content.build_final_exam(subject, save.level(), 3)
	assert(str(exam.get("kind", "")) == "final_exam")
	var exam_res := _play(exam, true)
	assert(bool(exam_res["passed"]), "esame con tutte corrette deve passare")
	if int(exam_res["energyGained"]) > 0:
		save.add_energy(int(exam_res["energyGained"]))
	assert(prog.repair_and_advance(true), "riparazione deve avanzare di livello")
	assert(save.level() == level_before + 1)
	assert(save.missions_of(subject) == 0, "conteggio missioni azzerato al salire")
	assert(int(save.data["apparatus"][str(gate["apparatus"])]["repairedLevel"]) == level_before)

	# 3) Missione fallita (tutte sbagliate): non passa e non fa avanzare indebitamente.
	var next_subject := str(prog.current_gate()["subject"])
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
		var given := str(item["answer"]) if answer_correct else "__risposta_sbagliata__"
		player._answer(given)
		player._advance()
	player.queue_free()
	return holder["result"]
