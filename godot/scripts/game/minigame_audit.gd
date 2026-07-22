extends SceneTree

## Audit dei minigiochi (formati "matching" e "ordering"). Verifica: (1) ogni
## materia costruisce nodi minigioco ben formati; (2) l'ExercisePlayer li gioca e
## li punteggia (soluzione → passato, con topicStats); (3) l'integrazione nella
## pipeline (try_start_minigame → resolve_session) conta come missione per il gate.
## Uso: godot --headless --path godot --script res://scripts/game/minigame_audit.gd

const SUBJECTS := [
	"matematica", "italiano", "inglese", "coding", "fisica", "musica", "latino",
	"elettronica", "geografia", "scienze", "cittadinanza", "logica",
]

func _init() -> void:
	_test_costruzione_tutte_materie()
	_test_gioco_ordering()
	_test_gioco_matching()
	_test_integrazione_pipeline()
	print("Minigame audit OK — abbina/ordina validi, giocabili e integrati nel loop")
	quit(0)

# Ogni materia produce almeno un nodo minigioco ben formato.
func _test_costruzione_tutte_materie() -> void:
	var mg := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for subject in SUBJECTS:
		var session := mg.build_minigame(subject, 6, rng)
		var nodes: Array = session.get("nodes", [])
		assert(nodes.size() >= 1, "nessun nodo minigioco per %s" % subject)
		assert(str(session.get("kind", "")) == "minigame", "kind errato per %s" % subject)
		for node in nodes:
			var fmt := str(node.get("format", ""))
			assert(fmt == "matching" or fmt == "ordering", "formato inatteso (%s): %s" % [subject, fmt])
			assert(str(node.get("topic", "")) != "", "topic vuoto (%s)" % subject)
			assert(int(node.get("difficulty", 0)) in [1, 2, 3, 4], "difficoltà invalida (%s)" % subject)
			if fmt == "matching":
				var pairs: Array = node.get("pairs", [])
				assert(pairs.size() >= 3, "troppe poche coppie (%s)" % subject)
				assert(_unique_sides(pairs), "lati destri non univoci (%s): ambiguo" % subject)
			else:
				var correct: Array = node.get("correctOrder", [])
				assert(correct.size() >= 3, "sequenza troppo corta (%s)" % subject)
				assert((node.get("items", []) as Array).size() == correct.size(), "items/correctOrder disallineati (%s)" % subject)

# Gioca un ordinamento risolvendolo nell'ordine giusto: deve risultare corretto.
func _test_gioco_ordering() -> void:
	var mg := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# matematica → ordinamento numerico garantito.
	var session := mg.build_minigame("matematica", 6, rng)
	# Sostituisco i nodi con un singolo ordering deterministico per il test.
	var ordering_node := _first_of_format(session, "ordering")
	assert(not ordering_node.is_empty(), "matematica dovrebbe includere un ordinamento")
	var res := _play_single(_wrap_session("matematica", "minigame", [ordering_node]), true)
	assert(bool(res.get("passed", false)), "l'ordinamento risolto bene deve passare")
	assert(int(res.get("correct", 0)) == 1, "il nodo risolto vale 1 corretto")
	assert((res.get("topicStats", {}) as Dictionary).has(str(ordering_node["topic"])), "topicStats mancante per l'ordinamento")

# Gioca un abbinamento risolvendolo correttamente.
func _test_gioco_matching() -> void:
	var mg := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var session := mg.build_minigame("inglese", 6, rng)
	var matching_node := _first_of_format(session, "matching")
	assert(not matching_node.is_empty(), "inglese dovrebbe includere un abbinamento")
	var res := _play_single(_wrap_session("inglese", "minigame", [matching_node]), true)
	assert(bool(res.get("passed", false)), "l'abbinamento risolto bene deve passare")
	# Sbagliando di proposito si perdono scudi fino al fallimento.
	var res_fail := _play_single(_wrap_session("inglese", "minigame", [matching_node]), false)
	assert(not bool(res_fail.get("passed", false)), "sbagliando l'abbinamento non deve passare")

# try_start_minigame → gioca → resolve: conta come missione e completa l'incontro.
func _test_integrazione_pipeline() -> void:
	var gameplay := _new_gameplay()
	var result: Dictionary = gameplay.get_meta("result")
	var subject := str(gameplay.runtime_state()["focusSubject"])
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(s): requested["session"] = s)
	assert(gameplay.try_start_minigame({"subject": subject}, "mg-1"), "minigioco avviabile")
	var session: Dictionary = requested["session"]
	assert(str(session.get("kind", "")) == "minigame", "kind minigame")
	var res := _play_session(gameplay, session, true)
	var missions_before := int(gameplay.runtime_state()["missionsDone"])
	gameplay.resolve_session(res)
	assert(int(gameplay.runtime_state()["missionsDone"]) == missions_before + 1, "il minigioco conta come missione")
	assert(Array(result["completedEncounterIds"]).has("mg-1"), "incontro minigioco completato")
	gameplay.queue_free()

# --- helper ------------------------------------------------------------------

func _unique_sides(pairs: Array) -> bool:
	var rights: Dictionary = {}
	for p in pairs:
		var r := str((p as Dictionary).get("right", ""))
		if rights.has(r):
			return false
		rights[r] = true
	return true

func _first_of_format(session: Dictionary, fmt: String) -> Dictionary:
	for node in session.get("nodes", []):
		if str((node as Dictionary).get("format", "")) == fmt:
			return node
	return {}

func _wrap_session(subject: String, kind: String, nodes: Array) -> Dictionary:
	return {
		"sessionId": "test-%s" % subject, "kind": kind, "subject": subject, "level": 6,
		"nodes": nodes, "shields": 3, "pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 30, "fragments": 2}},
	}

func _play_single(session: Dictionary, solve_correctly: bool) -> Dictionary:
	return _play_session(null, session, solve_correctly)

# Gioca una sessione con l'ExercisePlayer reale, pilotando i minigiochi via i loro
# handler (come farebbe un click). Se `gameplay` è presente, cabla il progresso.
func _play_session(gameplay, session: Dictionary, solve_correctly: bool) -> Dictionary:
	var player := ExercisePlayer.new()
	root.add_child(player)
	var holder := {"result": {}}
	player.session_finished.connect(func(r): holder["result"] = r)
	player.start_session(session)
	var guard := 0
	while (holder["result"] as Dictionary).is_empty() and guard < 200:
		guard += 1
		var node: Dictionary = player._nodes[player._index]
		var fmt := str(node.get("format", ""))
		if fmt == "ordering":
			_solve_ordering(player, node, solve_correctly)
		elif fmt == "matching":
			_solve_matching(player, node, solve_correctly)
		else:
			player._answer(str(node.get("answer", "")) if solve_correctly else "__sbagliata__")
		if not (holder["result"] as Dictionary).is_empty():
			break
		player._advance()
	player.queue_free()
	return holder["result"]

func _solve_ordering(player, node: Dictionary, correctly: bool) -> void:
	var correct: Array = node.get("correctOrder", [])
	if correctly:
		for target in correct:
			var idx := _button_index(player._mg_buttons, str(target))
			if idx >= 0:
				player._ordering_click(idx, node)
	else:
		# Clicca in ordine inverso per forzare gli errori fino a esaurire gli scudi.
		var reversed_order := correct.duplicate()
		reversed_order.reverse()
		for target in reversed_order:
			var idx := _button_index(player._mg_buttons, str(target))
			if idx >= 0 and not player._answered:
				player._ordering_click(idx, node)

func _solve_matching(player, node: Dictionary, correctly: bool) -> void:
	var pairs: Array = node.get("pairs", [])
	if correctly:
		for i in pairs.size():
			player._matching_left(i)
			player._matching_right(str((pairs[i] as Dictionary).get("right", "")), node)
	else:
		# Abbina ogni sinistra al destra SBAGLIATO finché gli scudi finiscono.
		for i in pairs.size():
			if player._answered:
				break
			player._matching_left(i)
			var wrong_idx := (i + 1) % pairs.size()
			player._matching_right(str((pairs[wrong_idx] as Dictionary).get("right", "")), node)

func _button_index(buttons: Array, text: String) -> int:
	for i in buttons.size():
		var b: Button = buttons[i]
		if not b.disabled and str(b.text) == text:
			return i
	return -1

func _new_gameplay() -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := {
		"outdoorState": {"fragments": 0},
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
	gameplay.setup(request, result)
	gameplay.set_meta("result", result)
	return gameplay
