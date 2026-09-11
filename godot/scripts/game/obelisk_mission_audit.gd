extends SceneTree

const GAMEPLAY = preload("res://scripts/game/outdoor_gameplay.gd")
const PLAYER = preload("res://scripts/game/exercise_player.gd")
const PILOT = preload("res://scripts/game/obelisk_mission.gd")
const AUTOPLAY = preload("res://scripts/game/exercise_autoplay.gd")
var failures: Array = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _game(world: int = 1):
	var game = GAMEPLAY.new()
	root.add_child(game)
	game.setup({}, {"completedEncounterIds": [], "collectedTreasureIds": [], "energySpent": 0}, false)
	game.game_save.set_current_world(world)
	return game

func _start(game, world: int = 1) -> Dictionary:
	var captured: Dictionary = {}
	game.session_requested.connect(func(session): captured.assign(session))
	var payload: Dictionary = MinimissionCatalog.incarico(world)
	payload["subject"] = "matematica" if world == 1 else "italiano"
	_check(game.try_start_minimission(payload, "audit-obelisk-%d" % world), "avvio minimissione mondo %d" % world)
	return captured

func _play(session: Dictionary, mode: String) -> Dictionary:
	var player = PLAYER.new()
	root.add_child(player)
	var result: Dictionary = {}
	var help_calls: Array = []
	player.session_finished.connect(func(value): result.assign(value))
	player.concept_help_requested.connect(func(subject, topic): help_calls.append([subject, topic]))
	player.start_session(session)
	if mode == "help":
		player._request_concept_help()
		_check(help_calls == [["italiano", "testo-narrativo"]], "aiuto indirizzato alla materia del nodo")
	AUTOPLAY.solve(player, player._nodes[0], mode != "wrong")
	if mode == "abandon":
		player._abandon()
	else:
		player._advance()
		var guard := 0
		while result.is_empty() and guard < 10:
			guard += 1
			AUTOPLAY.solve(player, player._nodes[player._index], true)
			if result.is_empty():
				player._advance()
	_check(not result.is_empty(), "player termina: %s" % mode)
	player.free()
	return result

func _run() -> void:
	var content = ContentManager.new()
	var italian_topics: Array = []
	for item in content._load_bank("italiano"):
		italian_topics.append(item.get("topic", ""))
	for variant in 6:
		var session: Dictionary = PILOT.build({"shields": 3, "subject": "matematica", "kind": "enigma"}, variant)
		var valid: Dictionary = ExerciseInteraction.validate_session(session)
		_check(bool(valid["ok"]), "variante %d: %s" % [variant, valid["errors"]])
		_check(session.nodes.size() == 3 and int(session.stages) == 3, "tre nodi e campate")
		_check(italian_topics.has(session.nodes[0].topic), "topic italiano ripassabile nel banco")
		for item in session.nodes.slice(1):
			_check(KnowledgeCodex.MATH_CONCEPTS.has(item.topic), "topic matematico nel Codex")
		var solved := _play(session, "correct")
		_check(bool(solved.get("passed", false)), "variante %d risolvibile nel renderer" % variant)

	for mode in ["correct", "wrong", "help", "abandon"]:
		var game = _game()
		var session := _start(game)
		_check(bool(session.get("interdisciplinary", false)), "pipeline reale consegna il pilota")
		var before_clock := SpacedRepetition.session_clock(game.game_save)
		var before_energy := int(game.game_save.energy())
		var outcome := _play(session, mode)
		var subjects: Dictionary = outcome.get("subjectResults", {})
		_check(subjects.has("italiano") and not subjects.has("inglese"), "materie pertinenti nell'esito")
		if mode == "abandon":
			_check(subjects.size() == 1, "abbandono: nessuna evidenza dei nodi non tentati")
		else:
			_check(subjects.size() == 2 and int(subjects.matematica.total) == 2, "due soli nodi matematici")
			_check(not subjects.matematica.topicStats.has("testo-narrativo"), "comprensione non accreditata alla matematica")
			_check(int(subjects.matematica.topicStats.tabelline.correct) == 1, "errore o aiuto italiano non penalizza matematica")
		if mode in ["wrong", "help"]:
			_check(int(subjects.italiano.topicStats["testo-narrativo"].correct) == 0, "nessuna evidenza autonoma dopo errore/aiuto")
		if mode == "help":
			_check(int(subjects.italiano.assisted) == 1 and float(subjects.italiano.effectiveCorrect) == 0.0, "assistenza tracciata senza credito pieno")
		game.resolve_session(outcome)
		_check(SpacedRepetition.session_clock(game.game_save) == before_clock + 1, "un solo tick per missione mista")
		_check(game.game_save.missions_of("italiano") == 0 and game.game_save.missions_of("inglese") == 0, "nessuna missione aggiuntiva per materia")
		_check(game.game_save.missions_of("matematica") == int(bool(outcome.get("passed", false)) and mode != "abandon"), "una sola missione host se superata")
		if mode == "abandon":
			_check(game.game_save.energy() <= before_energy and not game.game_save.has_minimission(1), "abbandono senza premio o claim")
		if mode == "correct":
			_check(game.game_save.has_minimission(1), "claim minimissione persistente")
			_check(float(game.game_save.subject_evidence("italiano").get("nodi", 0)) == 1.0, "un nodo italiano registrato")
			_check(float(game.game_save.subject_evidence("matematica").get("nodi", 0)) == 2.0, "due nodi matematici registrati")
			game.game_save.path = "user://obelisk-audit-roundtrip.json"
			game.game_save.save()
			var reload = GameSaveManager.new(game.game_save.path)
			reload.load_save()
			_check(reload.has_minimission(1) and reload.missions_of("matematica") == 1, "claim e missione dopo reload")
			_check(not reload.claim_minimission(1) and reload.minimission_count() == 1, "reload non duplica il claim")
			_check(reload.topic_masteries("italiano") == game.game_save.topic_masteries("italiano"), "evidenza italiana dopo reload")
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.game_save.path))
		var snapshot: Dictionary = game.game_save.data.duplicate(true)
		game.resolve_session(outcome)
		_check(game.game_save.data == snapshot, "doppia resolve senza effetti")
		game.free()
	await process_frame
	for message in failures:
		printerr(message)
	print("OBELISK audit %s — 6 varianti, pipeline, esiti, aiuti, abbandono, reload e fallback" % ("OK" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
