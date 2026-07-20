extends SceneTree

## Audit headless di C-02: il componente `OutdoorGameplay` estratto espone il
## contratto `OutdoorRuntimeState` completo, guida il loop (missione → gate →
## esame → riparazione → livello) in modo evento-driven e non concede ricompense
## fuori dalla propria logica. Il save è isolato via `godotSave` nella richiesta,
## così l'audit è deterministico a prescindere dal file persistito.
## Uso: godot --headless --path godot --script res://scripts/game/c02_audit.gd

const RUNTIME_KEYS := [
	"level", "focusSubject", "apparatus", "missionsDone", "missionsRequired",
	"mastery", "masteryThreshold", "ready", "energy", "fragments", "phase", "sessionActive",
]

func _init() -> void:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)

	var request := {
		"outdoorState": {"fragments": 5},
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

	var last_state := {"v": {}}
	gameplay.runtime_state_changed.connect(func(state): last_state["v"] = state)
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(session): requested["session"] = session)

	# setup emette lo stato iniziale (evento-driven)
	gameplay.setup(request, result)
	var state: Dictionary = last_state["v"]
	for key in RUNTIME_KEYS:
		assert(state.has(key), "manca il campo runtime '%s'" % key)
	assert(int(state["level"]) == 1)
	assert(int(state["energy"]) == 200)
	assert(int(state["fragments"]) == 5)
	assert(not bool(state["sessionActive"]))
	assert(not bool(gameplay.runtime_state()["ready"]))

	var subject := str(state["focusSubject"])

	# 1) Missioni native fino all'apertura del gate.
	var played := 0
	while not bool(gameplay.runtime_state()["ready"]) and played < 200:
		requested["session"] = {}
		assert(gameplay.try_start_mission({"subject": subject}, "enc-%d" % played), "missione avviabile")
		assert(bool(gameplay.runtime_state()["sessionActive"]), "sessione attiva dopo l'avvio")
		var session: Dictionary = requested["session"]
		assert(not session.is_empty(), "session_requested emesso")
		gameplay.resolve_session(_play(session, true))
		assert(not bool(gameplay.runtime_state()["sessionActive"]), "sessione chiusa dopo resolve")
		played += 1
	assert(bool(gameplay.runtime_state()["ready"]), "gate pronto dopo missioni + padronanza")

	# 2) Esame finale → riparazione → livello.
	var level_before := int(gameplay.runtime_state()["level"])
	requested["session"] = {}
	assert(gameplay.try_start_final_exam(), "esame avviabile quando il gate è pronto")
	var exam: Dictionary = requested["session"]
	assert(str(exam.get("kind", "")) == "final_exam")
	gameplay.resolve_session(_play(exam, true))
	assert(int(gameplay.runtime_state()["level"]) == level_before + 1, "livello avanzato dopo la riparazione")
	assert(int(gameplay.runtime_state()["missionsDone"]) == 0, "conteggio missioni azzerato")

	# 3) Stato d'uscita per il bridge.
	gameplay.publish_exit_state()
	assert(result.has("godotSave"))
	assert(int(result["level"]) == int(gameplay.runtime_state()["level"]))

	print("C-02 audit OK — contratto runtime completo + loop nativo; livello %d dopo %d missioni" % [int(gameplay.runtime_state()["level"]), played])
	quit(0)

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
