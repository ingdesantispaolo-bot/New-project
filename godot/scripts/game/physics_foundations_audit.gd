extends SceneTree

## Contratto didattico della fisica per 10–11 anni:
## 1. il mondo chiede soltanto le competenze che dichiara di insegnare;
## 2. ogni competenza ha una spiegazione concreta e un esempio svolto;
## 3. la varietà visuale non sostituisce una prova con un argomento futuro.

const WORLDS := {
	5: ["moto", "forze", "leve"],
	17: ["pressione", "galleggiamento", "correnti"],
}

func _init() -> void:
	var content := ContentManager.new()
	var codex := KnowledgeCodex.new(content)
	for level in WORLDS:
		var allowed: Array = WORLDS[level]
		var declared := ContentManager.lesson_topic_set("fisica", int(level)).keys()
		assert(_stesso_insieme(declared, allowed),
			"L%d dichiara topic diversi dal percorso di fisica: %s" % [level, declared])
		var incontrati: Dictionary = {}
		var formati: Dictionary = {}
		for seed_value in range(80):
			var rng := RandomNumberGenerator.new()
			rng.seed = int(level) * 1000 + seed_value
			var session := content.build_varied_mission(
				"fisica", int(level), 3, {}, rng, 0.35, {})
			for raw_node in Array(session.get("nodes", [])):
				var node: Dictionary = raw_node
				var topic := str(node.get("topic", ""))
				assert(allowed.has(topic),
					"L%d chiede «%s», che non è stato insegnato qui" % [level, topic])
				incontrati[topic] = true
				formati[str(node.get("format", ""))] = true
		for topic in allowed:
			assert(incontrati.has(topic), "L%d non rende raggiungibile «%s»" % [level, topic])
			var lesson := codex.mini_lesson("fisica", str(topic))
			assert(str(lesson.get("explanation", "")).strip_edges().length() >= 80,
				"La spiegazione di «%s» è troppo corta per una prima volta" % topic)
			var example: Dictionary = lesson.get("workedExample", {})
			assert(str(example.get("prompt", "")).strip_edges() != "",
				"«%s» non ha un esempio con una domanda" % topic)
			assert(str(example.get("answer", "")).strip_edges() != "",
				"«%s» non ha un esempio svolto" % topic)
		assert(formati.size() >= 3,
			"L%d usa meno di tre tipi di interazione: %s" % [level, formati.keys()])
	print("PHYSICS FOUNDATIONS audit VERDE — 2 mondi, 6 competenze, spiegazione prima della prova")
	quit(0)

func _stesso_insieme(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for value in a:
		if not b.has(value):
			return false
	return true
