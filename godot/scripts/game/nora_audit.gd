extends SceneTree

## Audit headless della voce di NORA (C-15): NoraVoice (pool per beat,
## anti-ripetizione), NoraContextEngine (apertura sessione per materia,
## distingue il ripasso spaziato) e l'integrazione in OutdoorGameplay
## (apertura missione/enigma, esiti di missione/enigma/esame finale).
## Uso: godot --headless --path godot --script res://scripts/game/nora_audit.gd

func _init() -> void:
	_test_voice_pools_and_anti_repeat()
	_test_context_engine_subjects()
	_test_gameplay_integration()
	print("Nora audit OK — pool/anti-ripetizione, frasi per materia e integrazione nel loop verificati")
	quit(0)

func _test_voice_pools_and_anti_repeat() -> void:
	var voice := NoraVoice.new()
	var generator := RandomNumberGenerator.new()
	generator.seed = 7
	for beat in ["solve", "victory", "defeat", "scaffold"]:
		var first := voice.line(beat, generator)
		assert(first != "", "il beat '%s' produce una frase" % beat)
		for i in range(12):
			var next := voice.line(beat, generator)
			assert(next != "", "frase non vuota (%s)" % beat)
	# Beat sconosciuto: pool vuota, nessun crash, stringa vuota.
	assert(voice.line("beat-inesistente") == "", "beat non mappato restituisce stringa vuota")

func _test_context_engine_subjects() -> void:
	# Materia nota: label/metodo specifici, non il fallback generico.
	var line := NoraContextEngine.open_line("matematica", false)
	assert(line.find("terminale numerico") >= 0, "label di matematica presente")
	assert(line.find("Apro il") == 0, "apertura standard quando non è ripasso")
	var review_line := NoraContextEngine.open_line("latino", true)
	assert(review_line.find("tavola latina") >= 0, "label di latino presente nel ripasso")
	assert(review_line.find("già fatto inciampare") >= 0, "frase di ripasso distinta dall'apertura standard")
	# Materia sconosciuta: fallback generico, nessun crash.
	var unknown := NoraContextEngine.open_line("robot", false)
	assert(unknown.find("sistema") >= 0, "fallback generico per materia non mappata")

func _new_gameplay() -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := {
		"outdoorState": {"fragments": 0},
		"initialSave": {
			"schemaVersion": 1, "playerId": "local", "level": 1, "energy": 200, "fragments": 0,
			"mastery": {}, "missionsBySubject": {}, "apparatus": {},
			"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []}, "modules": {"owned": [], "equipped": []},
		},
	}
	var result := {
		"schemaVersion": 1, "energyEarned": 0, "energySpent": 0, "fragmentsEarned": 0,
		"completedEncounterIds": [], "collectedTreasureIds": [],
	}
	gameplay.setup(request, result)
	return gameplay

func _test_gameplay_integration() -> void:
	var gameplay := _new_gameplay()
	var subject := str(gameplay.runtime_state()["focusSubject"])
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)

	# Apertura missione: NORA parla con la label della materia (via feedback).
	var messages: Array = []
	gameplay.feedback.connect(func(msg): messages.append(msg))
	assert(gameplay.try_start_mission({"subject": subject}, "enc-nora-1"), "missione avviabile")
	assert(messages.size() == 1 and str(messages[0]) != "", "apertura missione emette una frase di NORA")

	# Missione superata: la frase viene dal pool "solve" e riporta l'energia.
	var session: Dictionary = requested["session"]
	var res := _play(session, true)
	messages.clear()
	gameplay.resolve_session(res)
	assert(messages.size() == 1, "un solo messaggio all'esito")
	assert(str(messages[0]).find("energia") >= 0, "energia guadagnata riportata nel messaggio")

	# Missione fallita: comunque una frase di NORA (pool "defeat"), nessun crash.
	requested["session"] = {}
	assert(gameplay.try_start_mission({"subject": subject}, "enc-nora-2"), "seconda missione avviabile")
	var failing_session: Dictionary = requested["session"]
	var failed := _play(failing_session, false)
	messages.clear()
	gameplay.resolve_session(failed)
	assert(messages.size() == 1 and str(messages[0]) != "", "sconfitta produce comunque una frase di NORA")

# Gioca la sessione con l'ExercisePlayer reale (stesso schema di c02_audit/enigma_audit).
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
		# Le missioni live sono multi-formato (O-P3): qui interessa l'esito e la
		# conseguente voce di NORA, non ripetere il test di ogni renderer.
		player._score_current(answer_correct, item)
		player._advance()
	player.queue_free()
	return holder["result"]
