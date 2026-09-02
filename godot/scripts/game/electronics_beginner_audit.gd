extends SceneTree

## Guardia didattica per il primo incontro con elettronica (mondo 8).
## Un bambino senza prerequisiti deve trovare soltanto basi osservabili,
## attività manipolative e una spiegazione sostanziosa prima della prova.

const SUBJECT := "elettronica"
const FIRST_WORLD_LEVEL := 8
const ADVANCED_WORLD_LEVEL := 20
const ADVANCED_TOPICS := [
	"legge-ohm", "prefissi", "potenza", "serie-parallelo", "condensatore",
	"sensori", "segnali", "ruoli", "grandezze", "batteria", "guasti",
]
const REQUIRED_BEGINNER_TOPICS := [
	"componenti-base", "circuito", "conduttori", "sicurezza-elettrica",
	"montaggio-led",
]

var errors: Array = []

func _init() -> void:
	_check_palette()
	_check_lessons(FIRST_WORLD_LEVEL, "primo incontro")
	_check_lessons(ADVANCED_WORLD_LEVEL, "approfondimento")
	_check_led_build()
	_check_first_exam()
	if errors.is_empty():
		print("ELECTRONICS BEGINNER audit VERDE")
	else:
		printerr("ELECTRONICS BEGINNER audit ROSSO")
		for message in errors:
			printerr("  - %s" % message)
	quit(0 if errors.is_empty() else 1)

func _fail(message: String) -> void:
	errors.append(message)

func _beginner_specs() -> Array:
	return _specs_for_level(FIRST_WORLD_LEVEL)

func _specs_for_level(level: int) -> Array:
	var specs: Array = []
	for format_data in MinigameManager.runtime_formats_for(SUBJECT, level):
		var format := str(format_data)
		for raw in MinigameManager.eligible_specs(SUBJECT, format, level):
			var spec: Dictionary = Dictionary(raw).duplicate(true)
			spec["_format"] = format
			specs.append(spec)
	return specs

func _check_palette() -> void:
	var topics: Dictionary = {}
	var formats: Dictionary = {}
	for spec in _beginner_specs():
		var topic := str((spec as Dictionary).get("topic", ""))
		topics[topic] = true
		formats[str((spec as Dictionary).get("_format", ""))] = true
		if topic in ADVANCED_TOPICS:
			_fail("«%s» compare già nel primo incontro" % topic)
	for topic in REQUIRED_BEGINNER_TOPICS:
		if not topics.has(topic):
			_fail("manca la competenza iniziale «%s»" % topic)
	for format in ["matching", "ordering", "classification", "circuit"]:
		if not formats.has(format):
			_fail("manca il formato interattivo «%s»" % format)

func _check_lessons(level: int, phase: String) -> void:
	var codex := KnowledgeCodex.new(ContentManager.new())
	var checked: Dictionary = {}
	for spec in _specs_for_level(level):
		var topic := str((spec as Dictionary).get("topic", ""))
		if checked.has(topic):
			continue
		checked[topic] = true
		var lesson := codex.mini_lesson(SUBJECT, topic)
		var explanation := str(lesson.get("explanation", "")).strip_edges()
		var strategy := str(lesson.get("strategy", "")).strip_edges()
		if explanation.length() < 90:
			_fail("%s · «%s»: spiegazione troppo breve (%d caratteri)" % [phase, topic, explanation.length()])
		if strategy.length() < 55:
			_fail("%s · «%s»: il metodo non guida davvero il bambino (%d caratteri)" % [phase, topic, strategy.length()])

func _check_led_build() -> void:
	for spec in MinigameManager.eligible_specs(SUBJECT, "ordering", FIRST_WORLD_LEVEL):
		if str((spec as Dictionary).get("topic", "")) != "montaggio-led":
			continue
		var order: Array = (spec as Dictionary).get("correctOrder", [])
		var text := " | ".join(PackedStringArray(order))
		if not text.containsn("resistore"):
			_fail("il montaggio LED non include il resistore di protezione")
		if order.is_empty() or not str(order[-1]).containsn("pila"):
			_fail("il montaggio LED deve collegare la pila per ultima")
		return
	_fail("nessun montaggio LED disponibile nel primo incontro")

func _check_first_exam() -> void:
	var forbidden_words := [
		"condensatore", "relè", "messa a terra", "fusibile", "semiconduttore",
		"voltmetro", "amperometro", "multimetro", "in parallelo", "legge di ohm",
	]
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	for seed in range(80):
		rng.seed = seed * 7919 + FIRST_WORLD_LEVEL
		var exam := content.build_final_exam(SUBJECT, FIRST_WORLD_LEVEL, 5, rng, 0.5, {})
		for raw in Array(exam.get("nodes", [])):
			var node: Dictionary = raw
			if str(node.get("subject", "")) != SUBJECT:
				continue
			var words := "%s %s %s" % [
				str(node.get("prompt", "")), str(node.get("answer", "")),
				str(node.get("explanation", ""))]
			for forbidden in forbidden_words:
				if words.containsn(str(forbidden)):
					_fail("primo esame: compare «%s» prima di essere insegnato" % forbidden)
					return
