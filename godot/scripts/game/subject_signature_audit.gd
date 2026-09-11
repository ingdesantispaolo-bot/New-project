extends SceneTree

const PAIRS := {
	"breadboard":"elettronica", "rhythm_fill":"musica", "causal_chain":"storia",
	"robot_grid":"coding", "blank_map":"geografia",
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array = []
	var manager := MinigameManager.new()
	for fmt in PAIRS.keys():
		var subject := str(PAIRS[fmt])
		_check(MinigameManager.runtime_formats_for(subject, 1).has(fmt), "%s non raggiungibile nel runtime" % fmt, failures)
		_check(MinigameManager.format_depth(subject, fmt, 1) >= 15, "%s ha meno di 15 varianti" % fmt, failures)
		for band in range(1, 9):
			var signatures: Dictionary = {}
			for sample in range(60):
				var rng := RandomNumberGenerator.new()
				rng.seed = hash("signature:%s:%d:%d" % [fmt, band, sample])
				var node := SubjectSignatureGenerators.build(fmt, subject, band * 3, band, rng, sample)
				var validation := ExerciseInteraction.validate(node)
				_check(bool(validation.get("ok", false)), "%s fascia %d non valido: %s" % [fmt, band, str(validation.get("errors", []))], failures)
				signatures[ExerciseSignature.of(node)] = true
			_check(signatures.size() >= 15, "%s fascia %d produce solo %d sessioni distinte" % [fmt, band, signatures.size()], failures)

	# Contratti di esecuzione: una soluzione valida passa e un errore resta causale.
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var breadboard := SubjectSignatureGenerators.build("breadboard", "elettronica", 8, 3, rng, 0)
	_check(bool(ExerciseInteraction.evaluate_breadboard(breadboard, Array(breadboard["soluzioni"])[0]).get("correct", false)), "il banco non accetta una topologia dichiarata", failures)
	var open_result := ExerciseInteraction.evaluate_breadboard(breadboard, {})
	_check(not bool(open_result.get("correct", false)) and str(open_result.get("openNode", "")) != "", "il banco non nomina il nodo aperto", failures)

	var rhythm := SubjectSignatureGenerators.build("rhythm_fill", "musica", 6, 2, rng, 0)
	_check(bool(ExerciseInteraction.evaluate_rhythm_fill(rhythm, Array(rhythm["soluzioni"])[1]).get("correct", false)), "la battuta non accetta la seconda somma valida", failures)

	var causal := SubjectSignatureGenerators.build("causal_chain", "storia", 11, 4, rng, 0)
	var events: Array = causal["eventi"]
	var backward := ExerciseInteraction.evaluate_causal_link(causal, str((events[2] as Dictionary)["id"]), str((events[0] as Dictionary)["id"]))
	_check(bool(backward.get("backward", false)) and str(backward.get("reason", "")).contains(str((events[0] as Dictionary)["anno"])), "la freccia retrograda non cita la data", failures)

	var robot := SubjectSignatureGenerators.build("robot_grid", "coding", 15, 5, rng, 0)
	var robot_result := ExerciseInteraction.evaluate_robot_grid(robot, robot["soluzione"])
	_check(bool(robot_result.get("correct", false)) and int(robot_result.get("steps", 0)) > 0, "il programma del robot non viene eseguito", failures)

	var map_node := SubjectSignatureGenerators.build("blank_map", "geografia", 9, 3, rng, 0)
	if str(map_node.get("modalita", "")) == "percorso":
		_check(bool(ExerciseInteraction.evaluate_blank_map(map_node, {}, map_node["percorso"]).get("correct", false)), "la rotta corretta non passa", failures)
	else:
		var placements: Dictionary = {}
		for raw in Array(map_node["etichette"]):
			var label := raw as Dictionary
			placements[str(label["id"])] = str(label["ancora"])
		_check(bool(ExerciseInteraction.evaluate_blank_map(map_node, placements).get("correct", false)), "le etichette corrette non passano", failures)

	# C-R4f: tre titoli opzionali sono validi; due no.
	var decoder := manager.call("_verb_decoder_node", "italiano", 7, 0, rng, 0) as Dictionary
	decoder["axisTitles"] = ["1 · CASO", "2 · NUMERO", "3 · FORMA"]
	_check(bool(ExerciseInteraction.validate(decoder).get("ok", false)), "axisTitles validi rifiutati", failures)
	decoder["axisTitles"] = ["CASO", "NUMERO"]
	_check(not bool(ExerciseInteraction.validate(decoder).get("ok", true)), "axisTitles incompleti accettati", failures)

	# Il renderer deve costruire una plancia vera per ognuna delle cinque famiglie.
	for fmt in PAIRS.keys():
		var visual_rng := RandomNumberGenerator.new()
		visual_rng.seed = hash("renderer:%s" % fmt)
		var node := SubjectSignatureGenerators.build(str(fmt), str(PAIRS[fmt]), 8, 3, visual_rng, 0)
		var player := ExercisePlayer.new()
		root.add_child(player)
		player.start_session({"kind":"mission", "subject":str(PAIRS[fmt]), "nodes":[node], "shields":3})
		await process_frame
		_check(player.find_child("SubjectSignatureDiagram", true, false) != null, "%s non costruisce la plancia" % fmt, failures)
		_check(player.find_child("InteractionSubmit", true, false) != null, "%s non offre il verdetto" % fmt, failures)

	if not failures.is_empty():
		printerr("SUBJECT SIGNATURE AUDIT ROSSO — %d problemi" % failures.size())
		for failure in failures: printerr("  - %s" % failure)
		quit(1)
		return
	print("Subject signature audit OK — 5 renderer, 5 contratti, 15 varianti per fascia, axisTitles data-driven")
	quit(0)

func _check(condition: bool, message: String, failures: Array) -> void:
	if not condition: failures.append(message)
