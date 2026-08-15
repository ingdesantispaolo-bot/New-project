extends SceneTree

## Audit end-to-end del recupero: per tutte le 12 materie, in tutti i 24 mondi,
## una palestra aperta con un hint anche obsoleto deve proporre davvero i topic
## dovuti, marcarli `review` e permettere allo scheduler di togliere lo stato
## "da recuperare" dopo la risposta corretta.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var representative: Dictionary = {}
	var catalog := MinigameManager.new()
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("recovery-topic:%s" % subject)
		var baseline := catalog.build_minigame(subject, 1, rng)
		for node_data in Array(baseline.get("nodes", [])):
			var topic := str(Dictionary(node_data).get("topic", ""))
			if topic != "":
				representative[subject] = topic
				break
		assert(representative.has(subject), "%s non offre topic verificabili" % subject)

	# La matrice completa usa un nodo reale nel contratto ExercisePlayer e prova
	# la semantica invariabile per livello senza ricostruire 288 volte tutti i
	# cataloghi grafici (quello e' compito degli audit di disponibilita').
	var matrix_gameplay := _new_gameplay(1)
	var checked := 0
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			var due_topics: Array = [str(representative[subject])]
			var schedule: Dictionary = {}
			for topic_data in due_topics:
				schedule["%s:%s" % [subject, str(topic_data)]] = {
					"dueAt": 0, "interval": SpacedRepetition.FIRST_INTERVAL, "lapses": 1,
				}
			matrix_gameplay.game_save.data["spacedRepetition"] = {
				"sessionClock": 0, "schedule": schedule, "history": [],
			}
			var recovery := matrix_gameplay._inject_due_reviews({
				"subject": subject,
				"level": level,
				"nodes": [{
					"id": "matrix-%d-%s" % [level, subject], "subject": subject,
					"topic": due_topics[0], "format": "multiple_choice",
					"prompt": "audit", "options": ["si", "no"], "answer": "si",
					"explanation": "audit", "difficulty": 1,
				}],
			}, subject, level, due_topics)
			var recovered: Array = []
			for node_data in Array(recovery.get("nodes", [])):
				var node: Dictionary = node_data
				var topic := str(node.get("topic", ""))
				if bool(node.get("review", false)) and due_topics.has(topic) and not recovered.has(topic):
					recovered.append(topic)
			assert(recovered.size() == mini(due_topics.size(), Array(recovery.get("nodes", [])).size()),
				"%s L%d: recuperi richiesti %s, serviti %s" % [subject, level, str(due_topics), str(recovered)])

			SpacedRepetition.apply_outcome(matrix_gameplay.game_save, subject, [], recovered)
			SpacedRepetition.tick(matrix_gameplay.game_save)
			assert(SpacedRepetition.subject_overdue_count(matrix_gameplay.game_save, subject) == 0,
				"%s L%d resta etichettata da recuperare dopo l'esito corretto" % [subject, level])
			checked += 1
	matrix_gameplay.free()
	await process_frame

	# Integrazione con cataloghi reali ai due estremi della campagna. L'hint e'
	# volutamente obsoleto: riproduce il POI gia' presente quando avviene l'errore.
	for level in [1, WorldProfileCatalog.MAX_LEVEL]:
		var gameplay := _new_gameplay(level)
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			var topic := str(representative[subject])
			gameplay.game_save.data["spacedRepetition"] = {
				"sessionClock": 0,
				"schedule": {"%s:%s" % [subject, topic]: {
					"dueAt": 0, "interval": SpacedRepetition.FIRST_INTERVAL, "lapses": 1,
				}},
				"history": [],
			}
			var recovery := gameplay._build_practice_session(subject, "hint-obsoleto", "")
			var found := false
			for node_data in Array(recovery.get("nodes", [])):
				var node: Dictionary = node_data
				if str(node.get("topic", "")) == topic and bool(node.get("review", false)):
					found = true
					break
			assert(found, "%s L%d: la palestra reale non serve il recupero %s" % [subject, level, topic])
		gameplay.free()
		await process_frame

	# La matematica e' generata e non legge un banco completo: ogni archetipo
	# avanzato deve quindi poter essere richiesto direttamente dal recupero,
	# comprese potenze e radici che prima condividevano un'estrazione casuale.
	var math_topics: Array = []
	for topic_data in MathExerciseGenerator.ARCHETYPE_TOPIC.values():
		var topic := str(topic_data)
		if not math_topics.has(topic):
			math_topics.append(topic)
	for topic_data in math_topics:
		var topic := str(topic_data)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("math-recovery:%s" % topic)
		var nodes := MathExerciseGenerator.new().build_nodes(
			WorldProfileCatalog.MAX_LEVEL, 1, rng, [], [topic])
		assert(nodes.size() == 1 and str(Dictionary(nodes[0]).get("topic", "")) == topic
			and bool(Dictionary(nodes[0]).get("review", false)),
			"matematica: il generatore non prioritizza il recupero %s" % topic)
	print("RECOVERY FLOW audit OK — %d combinazioni (24 mondi × 12 materie) recuperabili" % checked)
	quit(0)

func _new_gameplay(level: int) -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var unlocked: Array = []
	for world in range(1, level + 1):
		unlocked.append(world)
	gameplay.setup({
		"initialSave": {
			"schemaVersion": 1, "playerId": "recovery-audit", "level": level,
			"energy": 400, "fragments": 0, "mastery": {}, "missionsBySubject": {},
			"apparatus": {}, "worlds": {"unlocked": unlocked, "current": level},
			"cosmetics": {"unlocked": [], "equipped": {}},
			"modules": {"owned": [], "equipped": []},
		},
	}, {
		"schemaVersion": 1, "energyEarned": 0, "energySpent": 0,
		"fragmentsEarned": 0, "completedEncounterIds": [], "collectedTreasureIds": [],
	}, false)
	return gameplay
