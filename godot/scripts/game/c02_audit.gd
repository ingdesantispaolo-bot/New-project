extends SceneTree

## Audit headless di C-02: il componente `OutdoorGameplay` estratto espone il
## contratto `OutdoorRuntimeState` completo, guida il loop (missione → gate →
## esame → riparazione → livello) in modo evento-driven e non concede ricompense
## fuori dalla propria logica. Il save è isolato via `initialSave` nella richiesta,
## così l'audit è deterministico a prescindere dal file persistito.
## Uso: godot --headless --path godot --script res://scripts/game/c02_audit.gd

const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")

const RUNTIME_KEYS := [
	"level", "focusSubject", "apparatus", "missionsDone", "missionsRequired",
	"missionsRemaining", "missionProgress", "mastery", "masteryThreshold",
	"masteryProgress", "ready", "energy", "fragments", "phase", "sessionActive",
]

func _init() -> void:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)

	var request := {
		"outdoorState": {"fragments": 5},
		"initialSave": {
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
	gameplay.setup(request, result, false)
	var state: Dictionary = last_state["v"]
	for key in RUNTIME_KEYS:
		assert(state.has(key), "manca il campo runtime '%s'" % key)
	assert(int(state["level"]) == 1)
	assert(int(state["energy"]) == 200)
	assert(int(state["fragments"]) == 5)
	assert(not bool(state["sessionActive"]))
	assert(not bool(gameplay.runtime_state()["ready"]))

	var subject := str(state["focusSubject"])

	# 1) Missioni native fino all'apertura del gate. `ready` è la prontezza del
	# LIVELLO, che dal 30 luglio dipende dalle tre materie del nucleo: allenare la
	# sola materia del mondo non lo aprirebbe mai.
	var played := 0
	while not bool(gameplay.runtime_state()["ready"]) and played < 200:
		requested["session"] = {}
		var turn_subject := str(ApparatusConfig.CORE_SUBJECTS[played % ApparatusConfig.CORE_SUBJECTS.size()])
		assert(gameplay.try_start_mission({"subject": turn_subject}, "enc-%d" % played), "missione avviabile")
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

	print("C-02 audit OK — contratto runtime completo + loop nativo; livello %d dopo %d missioni" % [int(gameplay.runtime_state()["level"]), played])
	quit(0)

# Le missioni del percorso live sono a formati VARI: ogni nodo va risolto con la
# propria interazione (vedi ExerciseAutoplay), non rispondendo sempre con `answer`.
func _play(session: Dictionary, answer_correct: bool) -> Dictionary:
	return Autoplay.play(root, session, answer_correct)
