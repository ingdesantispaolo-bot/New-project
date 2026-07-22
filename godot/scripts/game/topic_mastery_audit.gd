extends SceneTree

## Audit mastery PER-ARGOMENTO (adattività fine dentro la materia).
## Verifica: (1) gli esiti per-topic aggiornano `masteryByTopic` (EMA, primo
## incontro = accuratezza osservata); (2) `topic_masteries()` espone la mappa;
## (3) la selezione privilegia gli argomenti deboli (mastery < soglia) a parità
## di difficoltà.
## Uso: godot --headless --path godot --script res://scripts/game/topic_mastery_audit.gd

func _init() -> void:
	_test_update_ema()
	_test_map_esposta()
	_test_selezione_privilegia_deboli()
	print("Topic mastery audit OK — aggiornamento per-topic ed selezione weakness-first")
	quit(0)

func _test_update_ema() -> void:
	var save := GameSaveManager.new()
	var prog := ProgressionManager.new(save)
	# Primo incontro: mastery del topic = accuratezza osservata.
	prog.record_topic_stats("geografia", {
		"capitali": {"seen": 2, "correct": 2},
		"climi": {"seen": 2, "correct": 0},
	})
	assert(is_equal_approx(save.topic_mastery_of("geografia", "capitali"), 1.0), "primo incontro forte = 1.0")
	assert(is_equal_approx(save.topic_mastery_of("geografia", "climi"), 0.0), "primo incontro debole = 0.0")
	# Secondo incontro: media mobile verso la nuova accuratezza (peso 0.34).
	prog.record_topic_stats("geografia", {"climi": {"seen": 1, "correct": 1}})
	assert(is_equal_approx(save.topic_mastery_of("geografia", "climi"), lerpf(0.0, 1.0, 0.34)), "EMA per-topic errata")
	# Topic mai visto: sconosciuto (-1), distinto da "debole".
	assert(save.topic_mastery_of("geografia", "mai-vista") < 0.0, "topic nuovo deve essere sconosciuto")

func _test_map_esposta() -> void:
	var save := GameSaveManager.new()
	save.set_topic_mastery("scienze", "materia", 0.4)
	save.set_topic_mastery("scienze", "corpo", 0.8)
	save.set_topic_mastery("geografia", "capitali", 0.9)  # altra materia: esclusa
	var map := save.topic_masteries("scienze")
	assert(map.size() == 2, "la mappa deve contenere solo i topic della materia")
	assert(is_equal_approx(float(map.get("materia", -1.0)), 0.4), "valore topic errato")
	assert(not map.has("capitali"), "non deve mescolare materie diverse")

# A parità di difficoltà, un topic debole viene servito prima di uno padroneggiato.
func _test_selezione_privilegia_deboli() -> void:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# geografia a livello 5 → difficoltà target 2 (climi e capitali hanno item a d2).
	var topic_mastery := {"climi": 0.15, "capitali": 0.95}
	# node_count 1: il pool "debole" viene svuotato per primo → esce un item debole.
	var mission := content.build_mission("geografia", 5, 1, {}, rng, 0.65, topic_mastery)
	var nodes: Array = mission.get("nodes", [])
	assert(nodes.size() == 1, "missione deve avere un item")
	assert(str(nodes[0].get("topic", "")) == "climi", "a parità di difficoltà l'argomento debole va servito per primo")
