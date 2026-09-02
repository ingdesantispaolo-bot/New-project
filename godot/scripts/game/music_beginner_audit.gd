extends SceneTree

## Guardia didattica per il primo incontro con musica (mondo 6).
## Il bambino parte da zero: ogni prova deve restare sulle quattro basi spiegate,
## senza far trapelare per difficoltà alterazioni, accordi o teoria avanzata.

const SUBJECT := "musica"
const FIRST_WORLD_LEVEL := 6
const ADVANCED_WORLD_LEVEL := 18
const ALLOWED_TOPICS := ["note", "lettura", "ritmo", "intervalli"]
const ADVANCED_TOPICS := ["intervalli", "dinamica", "timbro"]
const REQUIRED_INTERACTIVE := ["matching", "ordering", "notation"]

var errors: Array = []

func _init() -> void:
	_check_lesson_contract()
	_check_explanations()
	_check_missions()
	_check_advanced_world()
	_check_interactive_palette()
	if errors.is_empty():
		print("MUSIC BEGINNER audit VERDE")
	else:
		printerr("MUSIC BEGINNER audit ROSSO")
		for message in errors:
			printerr("  - %s" % message)
	quit(0 if errors.is_empty() else 1)

func _fail(message: String) -> void:
	errors.append(message)

func _check_lesson_contract() -> void:
	var lesson := WorldLessonCatalog.lesson(FIRST_WORLD_LEVEL)
	if str(lesson.get("subject", "")) != SUBJECT:
		_fail("il mondo 6 non dichiara musica")
	for topic in ALLOWED_TOPICS:
		if not Array(lesson.get("topics", [])).has(topic):
			_fail("la lezione iniziale non dichiara «%s»" % topic)
	var briefing := str(Dictionary(lesson.get("nora", {})).get("briefing", ""))
	if briefing.length() < 220 or not briefing.containsn("non serve conoscere"):
		_fail("il briefing non accoglie davvero un bambino che parte da zero")

func _check_explanations() -> void:
	var codex := KnowledgeCodex.new(ContentManager.new())
	for topic in ALLOWED_TOPICS:
		var lesson := codex.mini_lesson(SUBJECT, topic)
		var explanation := str(lesson.get("explanation", "")).strip_edges()
		var strategy := str(lesson.get("strategy", "")).strip_edges()
		var example: Dictionary = lesson.get("workedExample", {})
		if explanation.length() < 130:
			_fail("«%s»: spiegazione iniziale troppo breve (%d caratteri)" % [topic, explanation.length()])
		if strategy.length() < 90:
			_fail("«%s»: il metodo non guida un principiante (%d caratteri)" % [topic, strategy.length()])
		if str(example.get("prompt", "")).strip_edges() == "" or str(example.get("answer", "")).strip_edges() == "":
			_fail("«%s»: manca un esempio svolto prima della prova" % topic)

func _check_missions() -> void:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	var played_formats: Dictionary = {}
	for seed in range(100):
		rng.seed = seed * 6151 + FIRST_WORLD_LEVEL
		var mission := content.build_varied_mission(SUBJECT, FIRST_WORLD_LEVEL, 6, {}, rng, 0.5, {})
		var seen: Dictionary = {}
		for raw in Array(mission.get("nodes", [])):
			var node: Dictionary = raw
			var topic := str(node.get("topic", ""))
			var format := str(node.get("format", ""))
			played_formats[format] = true
			var key := "%s|%s" % [format, topic]
			if seen.has(key):
				_fail("la missione ripete due volte «%s» con lo stesso gesto" % topic)
				return
			seen[key] = true
			if not topic in ALLOWED_TOPICS:
				_fail("la missione iniziale interroga «%s», non insegnato nel mondo" % topic)
				return
			# Nei minigiochi il numero di difficoltà regola quante tessere vengono
			# mostrate, non introduce nuova teoria. Il tetto vale per le domande del
			# banco, dove la banda 3 contiene davvero concetti successivi.
			if str(node.get("format", "")) in ["multiple_choice", "short_answer", "numeric_input"] \
					and int(node.get("difficulty", 1)) > 2:
				_fail("la missione iniziale espone già la banda %d" % int(node.get("difficulty", 1)))
				return
	for format in ["matching", "ordering"]:
		if not played_formats.has(format):
			_fail("le missioni simulate non servono mai il gesto «%s»" % format)

func _check_interactive_palette() -> void:
	var found: Dictionary = {}
	for format in MinigameManager.runtime_formats_for(SUBJECT, FIRST_WORLD_LEVEL):
		for raw in MinigameManager.eligible_specs(SUBJECT, str(format), FIRST_WORLD_LEVEL):
			if str((raw as Dictionary).get("topic", "")) in ALLOWED_TOPICS:
				found[str(format)] = true
	for format in REQUIRED_INTERACTIVE:
		if not found.has(format):
			_fail("manca un'attività interattiva iniziale di tipo «%s»" % format)

func _check_advanced_world() -> void:
	var codex := KnowledgeCodex.new(ContentManager.new())
	for topic in ADVANCED_TOPICS:
		var lesson := codex.mini_lesson(SUBJECT, topic)
		if str(lesson.get("explanation", "")).strip_edges().length() < 130:
			_fail("approfondimento · «%s»: spiegazione troppo breve" % topic)
		if str(lesson.get("strategy", "")).strip_edges().length() < 90:
			_fail("approfondimento · «%s»: metodo troppo breve" % topic)
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	for seed in range(60):
		rng.seed = seed * 8081 + ADVANCED_WORLD_LEVEL
		var mission := content.build_varied_mission(SUBJECT, ADVANCED_WORLD_LEVEL, 6, {}, rng, 0.65, {})
		for raw in Array(mission.get("nodes", [])):
			var topic := str((raw as Dictionary).get("topic", ""))
			if not topic in ADVANCED_TOPICS:
				_fail("l'approfondimento interroga «%s», fuori dalla sua lezione" % topic)
				return
