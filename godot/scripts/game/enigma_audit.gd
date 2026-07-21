extends SceneTree

## Audit headless dell'enigma ambientale: `try_start_enigma` produce una sessione
## kind=enigma con `theme`/`stages`; l'ExercisePlayer, cablato a `notify_progress`,
## fa avanzare `enigma_progress` una campata per risposta corretta; il completamento
## costruisce l'elemento (built==total), conta come missione per il gate e completa
## l'incontro. Su fallimento (tutte sbagliate) nulla si completa: penalità morbida.
## Uso: godot --headless --path godot --script res://scripts/game/enigma_audit.gd

func _init() -> void:
	_test_success()
	_test_failure()
	print("Enigma audit OK — progresso live, completamento e penalità morbida verificati")
	quit(0)

func _new_gameplay() -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := {
		"outdoorState": {"fragments": 0},
		"godotSave": {
			"schemaVersion": 1, "playerId": "local", "level": 1, "energy": 200, "fragments": 0,
			"mastery": {}, "missionsBySubject": {}, "apparatus": {},
			"cosmetics": {"unlocked": [], "equipped": {}}, "modules": {"owned": [], "equipped": []},
		},
	}
	var result := {
		"schemaVersion": 1, "energyEarned": 0, "energySpent": 0, "fragmentsEarned": 0,
		"completedEncounterIds": [], "collectedTreasureIds": [],
	}
	gameplay.setup(request, result)
	gameplay.set_meta("result", result)
	return gameplay

func _test_success() -> void:
	var gameplay := _new_gameplay()
	var result: Dictionary = gameplay.get_meta("result")
	var subject := str(gameplay.runtime_state()["focusSubject"])

	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)
	var progress: Array = []
	gameplay.enigma_progress.connect(func(built, total, theme): progress.append([built, total, theme]))

	assert(gameplay.try_start_enigma({"subject": subject}, "enigma-1"), "enigma avviabile")
	assert(bool(gameplay.runtime_state()["sessionActive"]), "sessione attiva")
	var session: Dictionary = requested["session"]
	assert(str(session.get("kind", "")) == "enigma", "kind=enigma")
	assert(session.has("theme") and str(session["theme"]) != "", "tema presente per la resa")
	assert(int(session["stages"]) == int(session["nodes"].size()), "una campata per esercizio")
	# Stato iniziale della costruzione: 0 campate, per partire da "rotto".
	assert(progress.size() == 1 and int(progress[0][0]) == 0, "progresso iniziale a 0")

	# Gioca tutto corretto cablando progress_changed → notify_progress (come la scena).
	var res := _play(gameplay, session, true)
	# Durante il gioco il progresso è cresciuto 1,2,3,…,total.
	var stages := int(session["stages"])
	assert(int(progress[stages][0]) == stages, "ultima campata costruita in gioco")
	assert(int(res["correct"]) == stages and bool(res["passed"]), "enigma superato")

	var missions_before := int(gameplay.runtime_state()["missionsDone"])
	gameplay.resolve_session(res)
	# Il completamento emette la costruzione piena e conta come missione + incontro.
	var last: Array = progress[progress.size() - 1]
	assert(int(last[0]) == stages and int(last[1]) == stages, "costruzione completata su resolve")
	assert(int(gameplay.runtime_state()["missionsDone"]) == missions_before + 1, "enigma conta come missione")
	assert(Array(result["completedEncounterIds"]).has("enigma-1"), "incontro completato")
	assert(int(result["fragmentsEarned"]) >= 3, "frammenti dell'enigma")
	gameplay.queue_free()

func _test_failure() -> void:
	var gameplay := _new_gameplay()
	var result: Dictionary = gameplay.get_meta("result")
	var subject := str(gameplay.runtime_state()["focusSubject"])
	var level_before := int(gameplay.runtime_state()["level"])

	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)
	var completed_full := {"v": false}
	gameplay.enigma_progress.connect(func(built, total, _t):
		if int(built) == int(total) and int(total) > 0:
			completed_full["v"] = true)

	assert(gameplay.try_start_enigma({"subject": subject}, "enigma-x"), "enigma avviabile")
	var session: Dictionary = requested["session"]
	var res := _play(gameplay, session, false)
	assert(not bool(res["passed"]), "enigma fallito con tutte sbagliate")

	var missions_before := int(gameplay.runtime_state()["missionsDone"])
	gameplay.resolve_session(res)
	# Penalità morbida: niente costruzione completata, niente incontro, nessuna
	# regressione di livello; l'enigma è ripetibile.
	assert(not completed_full["v"], "costruzione NON completata su fallimento")
	assert(not Array(result["completedEncounterIds"]).has("enigma-x"), "incontro non completato")
	assert(int(gameplay.runtime_state()["missionsDone"]) == missions_before, "fallire non conta come missione")
	assert(int(gameplay.runtime_state()["level"]) == level_before, "nessuna regressione di livello")
	gameplay.queue_free()

# Gioca la sessione con l'ExercisePlayer reale, cablando il progresso come la scena.
func _play(gameplay: OutdoorGameplay, session: Dictionary, answer_correct: bool) -> Dictionary:
	var player := ExercisePlayer.new()
	root.add_child(player)
	player.progress_changed.connect(gameplay.notify_progress)
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
