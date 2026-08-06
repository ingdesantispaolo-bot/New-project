extends SceneTree

const WorldLessonCatalog = preload("res://scripts/game/world_lesson.gd")

## Decisione utente del 29 luglio: le RIVISITAZIONI sono ripasso mirato, non una
## replica della frontiera. Tornando in un mondo già superato le prove devono
## essere quelle di QUEL mondo — i suoi argomenti e la sua banda di difficoltà —
## mentre l'ESAME dell'apparato resta al rango del giocatore, così il ripasso non
## diventa una scorciatoia per il gate.
## Uso: godot --headless --path godot --script res://scripts/game/revisit_audit.gd

const PLAYER_RANK := 12   # frontiera del giocatore
const REVISITED := 5      # mondo già superato in cui torna (fisica)

func _init() -> void:
	_test_ripasso_sul_mondo_visitato()
	_test_frontiera_invariata()
	_test_esame_al_rango_del_giocatore()
	print("Revisit audit OK — il ritorno su un mondo superato è ripasso di quel mondo; l'esame resta al rango")
	quit(0)

# Nel mondo rivisitato la prova nasce dal livello di QUEL mondo e ne serve gli
# argomenti; la difficoltà resta dentro la banda del mondo (± il nudge di mastery).
func _test_ripasso_sul_mondo_visitato() -> void:
	var gameplay := _new_gameplay(PLAYER_RANK, REVISITED)
	var state := gameplay.runtime_state()
	assert(bool(state["revisit"]), "il ritorno su un mondo superato deve essere segnalato come ripasso")
	assert(int(state["learningLevel"]) == REVISITED, "la prova deve nascere dal mondo visitato")
	assert(int(state["level"]) == PLAYER_RANK, "il rango del giocatore non cambia tornando indietro")

	var subject := str(WorldProfileCatalog.profile(REVISITED)["learningFocus"]["subject"])
	var promised: Array = WorldLessonCatalog.topics(REVISITED)
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)
	var served := 0
	var total := 0
	var max_band := ContentManager.target_difficulty(REVISITED) + 1
	for i in range(12):
		assert(gameplay.try_start_mission({"subject": subject}, "ripasso-%d" % i), "missione di ripasso avviabile")
		var session: Dictionary = requested["session"]
		assert(int(session["level"]) == REVISITED, "la sessione deve usare il livello del mondo visitato")
		for node in session.get("nodes", []):
			total += 1
			var n: Dictionary = node
			if promised.has(str(n.get("topic", ""))):
				served += 1
			assert(int(n.get("difficulty", 1)) <= max_band,
				"il ripasso non deve superare la banda del mondo %d (trovata %d)" % [REVISITED, int(n.get("difficulty", 1))])
		gameplay.active_session_context = {}
	assert(served > 0, "il ripasso deve toccare gli argomenti del mondo visitato")
	gameplay.queue_free()

# Sulla frontiera (mondo corrente == rango) nulla cambia rispetto a prima.
func _test_frontiera_invariata() -> void:
	var gameplay := _new_gameplay(PLAYER_RANK, PLAYER_RANK)
	var state := gameplay.runtime_state()
	assert(not bool(state["revisit"]), "sulla frontiera non è un ripasso")
	assert(int(state["learningLevel"]) == PLAYER_RANK, "sulla frontiera la prova resta al rango")
	var subject := str(state["focusSubject"])
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)
	assert(gameplay.try_start_mission({"subject": subject}, "frontiera-1"), "missione avviabile")
	assert(int((requested["session"] as Dictionary)["level"]) == PLAYER_RANK, "la sessione della frontiera usa il rango")
	gameplay.queue_free()

# L'esame dell'apparato è la prova del gate: resta al rango anche se il giocatore
# si trova in un mondo precedente, altrimenti il ripasso regalerebbe il livello.
func _test_esame_al_rango_del_giocatore() -> void:
	var gameplay := _new_gameplay(PLAYER_RANK, REVISITED)
	var subject := str(gameplay.runtime_state()["focusSubject"])
	var progression: ProgressionManager = gameplay.progression_manager
	var guard := 0
	while not progression.can_repair() and guard < 40:
		progression.record_mission(subject, 3, 3, 0, true)
		progression.record_topic_stats(subject, {"t0": {"seen": 1, "correct": 1}, "t1": {"seen": 1, "correct": 1}, "t2": {"seen": 1, "correct": 1}, "t3": {"seen": 1, "correct": 1}, "t4": {"seen": 1, "correct": 1}, "t5": {"seen": 1, "correct": 1}, "t6": {"seen": 1, "correct": 1}, "t7": {"seen": 1, "correct": 1}, "t8": {"seen": 1, "correct": 1}, "t9": {"seen": 1, "correct": 1}, "t10": {"seen": 1, "correct": 1}, "t11": {"seen": 1, "correct": 1}, "t12": {"seen": 1, "correct": 1}, "t13": {"seen": 1, "correct": 1}, "t14": {"seen": 1, "correct": 1}, "t15": {"seen": 1, "correct": 1}, "t16": {"seen": 1, "correct": 1}, "t17": {"seen": 1, "correct": 1}, "t18": {"seen": 1, "correct": 1}, "t19": {"seen": 1, "correct": 1}, "t20": {"seen": 1, "correct": 1}, "t21": {"seen": 1, "correct": 1}, "t22": {"seen": 1, "correct": 1}, "t23": {"seen": 1, "correct": 1}})
		guard += 1
	assert(progression.can_repair(), "il gate deve potersi aprire anche mentre si ripassa")
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)
	assert(gameplay.try_start_final_exam(), "esame avviabile con il gate pronto")
	var exam: Dictionary = requested["session"]
	assert(str(exam["kind"]) == "final_exam", "kind=final_exam")
	assert(int(exam["level"]) == PLAYER_RANK, "l'esame non scende al livello del mondo rivisitato")
	gameplay.queue_free()

func _new_gameplay(rank: int, world: int) -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var unlocked: Array = []
	for level in range(1, rank + 1):
		unlocked.append(level)
	var request := {
		"outdoorState": {"fragments": 0},
		"initialSave": {
			"schemaVersion": 1, "playerId": "local", "level": rank, "energy": 400, "fragments": 0,
			"mastery": {}, "missionsBySubject": {}, "apparatus": {},
			"worlds": {"unlocked": unlocked, "current": world},
			"cosmetics": {"unlocked": [], "equipped": {}}, "modules": {"owned": [], "equipped": []},
		},
	}
	var result := {
		"schemaVersion": 1, "energyEarned": 0, "energySpent": 0, "fragmentsEarned": 0,
		"completedEncounterIds": [], "collectedTreasureIds": [],
	}
	gameplay.setup(request, result, false)
	return gameplay
