extends SceneTree

const GAMEPLAY = preload("res://scripts/game/outdoor_gameplay.gd")
const PLAYER = preload("res://scripts/game/exercise_player.gd")
const MISSIONS = preload("res://scripts/game/linked_missions_first.gd")
const MISSIONS_LATE = preload("res://scripts/game/linked_missions_late.gd")
const AUTOPLAY = preload("res://scripts/game/exercise_autoplay.gd")

const EXPECTED_SUBJECTS := {
	2: ["italiano", "matematica"],
	3: ["coding", "matematica"],
	4: ["inglese", "logica", "matematica"],
	5: ["fisica", "matematica"],
	6: ["musica", "matematica"],
	7: ["latino", "logica", "matematica"],
	8: ["elettronica", "matematica", "coding"],
	9: ["geografia", "matematica", "coding"],
	10: ["scienze", "matematica"],
	11: ["storia", "matematica"],
	12: ["logica", "coding", "fisica"],
	13: ["fisica", "matematica", "coding"],
	14: ["italiano", "matematica", "logica"],
	15: ["coding", "matematica", "fisica"],
	16: ["inglese", "matematica", "logica"],
	17: ["fisica", "matematica", "scienze"],
	18: ["musica", "coding", "fisica"],
	19: ["latino", "scienze", "logica"],
	20: ["elettronica", "matematica", "coding"],
	21: ["geografia", "matematica", "coding"],
	22: ["scienze", "matematica", "logica"],
	23: ["storia", "matematica", "italiano"],
	24: ["logica", "matematica", "coding"],
}

var failures: Array = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _game(world: int):
	var game = GAMEPLAY.new()
	root.add_child(game)
	game.setup({}, {
		"completedEncounterIds": [], "collectedTreasureIds": [], "energySpent": 0,
	}, false)
	game.game_save.set_current_world(world)
	return game

func _start(game, world: int) -> Dictionary:
	var captured: Dictionary = {}
	game.session_requested.connect(func(session): captured.assign(session))
	var payload := MinimissionCatalog.incarico(world)
	payload["subject"] = ApparatusConfig.world_subject(world)
	_check(game.try_start_minimission(payload, "audit-linked-%d" % world),
		"mondo %d: avvio dalla pipeline reale" % world)
	return captured

func _play(session: Dictionary) -> Dictionary:
	var player = PLAYER.new()
	root.add_child(player)
	var result: Dictionary = {}
	player.session_finished.connect(func(value): result.assign(value))
	player.start_session(session)
	var guard := 0
	while result.is_empty() and guard < 10:
		guard += 1
		AUTOPLAY.solve(player, player._nodes[player._index], true)
		if result.is_empty():
			player._advance()
	_check(not result.is_empty() and bool(result.get("passed", false)),
		"sessione risolvibile nel renderer")
	player.free()
	return result

func _nodes_for(world: int, variant: int) -> Array:
	return MISSIONS.nodes_for(world, variant) if world <= 12 else MISSIONS_LATE.nodes_for(world, variant)

func _run() -> void:
	# Due varianti per mondo: stesso concetto, dati diversi, sempre tre tappe.
	for world in range(2, 25):
		for variant in 2:
			var nodes := _nodes_for(world, variant)
			var session := {
				"nodes": nodes, "stages": nodes.size(), "shields": 3,
				"subject": ApparatusConfig.world_subject(world),
				"interdisciplinary": true,
			}
			var valid := ExerciseInteraction.validate_session(session)
			_check(bool(valid.get("ok", false)),
				"mondo %d variante %d: %s" % [world, variant, valid.get("errors", [])])
			_check(nodes.size() == 3, "mondo %d: tre tappe" % world)
			var found_subjects: Array = []
			for node_data in nodes:
				var node: Dictionary = node_data
				var node_subject := str(node.get("subject", ""))
				if not found_subjects.has(node_subject):
					found_subjects.append(node_subject)
				_check(int(node.get("challengeLevel", 0)) == world,
					"mondo %d: challenge level dichiarato" % world)
				_check(int(node.get("difficulty", 0)) == 1 + floori(float(world - 1) / 3.0),
					"mondo %d: fascia dichiarata" % world)
				_check(str(node.get("missionStep", "")) != "" and str(node.get("missionOutput", "")) != "",
					"mondo %d: scopo e dato di passaggio" % world)
			_check(found_subjects == EXPECTED_SUBJECTS[world],
				"mondo %d: materie %s" % [world, found_subjects])
			_play(session)

	# Il percorso vero deve attribuire l'evidenza a ogni materia, ma concedere
	# una sola missione ospite, un solo claim e un solo tick del ripasso.
	for world in range(2, 25):
		var game = _game(world)
		var session := _start(game, world)
		_check(bool(session.get("interdisciplinary", false)),
			"mondo %d: sessione collegata" % world)
		_check(str(session.get("missionTitle", "")) == str(MinimissionCatalog.incarico(world).get("titolo", "")),
			"mondo %d: titolo dell'incarico conservato" % world)
		var before_clock := SpacedRepetition.session_clock(game.game_save)
		var outcome := _play(session)
		var subjects: Dictionary = outcome.get("subjectResults", {})
		for subject in EXPECTED_SUBJECTS[world]:
			_check(subjects.has(subject),
				"mondo %d: evidenza separata per %s" % [world, subject])
		game.resolve_session(outcome)
		var host := ApparatusConfig.world_subject(world)
		_check(game.game_save.missions_of(host) == 1,
			"mondo %d: una sola missione ospite" % world)
		for subject in EXPECTED_SUBJECTS[world]:
			if subject != host:
				_check(game.game_save.missions_of(subject) == 0,
					"mondo %d: nessuna missione extra per %s" % [world, subject])
		_check(game.game_save.has_minimission(world) and game.game_save.minimission_count() == 1,
			"mondo %d: conseguenza reclamata una volta" % world)
		_check(SpacedRepetition.session_clock(game.game_save) == before_clock + 1,
			"mondo %d: un solo tick" % world)
		var snapshot: Dictionary = game.game_save.data.duplicate(true)
		game.resolve_session(outcome)
		_check(game.game_save.data == snapshot,
			"mondo %d: doppia resolve senza effetti" % world)
		game.free()

	await process_frame
	for message in failures:
		printerr(message)
	print("LINKED MISSIONS 2-24 %s — 46 varianti, renderer, pipeline, attribuzione e claim" %
		("OK" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
