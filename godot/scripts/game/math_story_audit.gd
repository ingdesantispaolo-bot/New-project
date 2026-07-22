extends SceneTree

## Audit dei problemi di matematica "a storia" (piccoli problemi divertenti,
## tarati per livello). Verifica che ogni archetipo narrativo produca un nodo
## valido e risolvibile, e che i problemi compaiano già ai livelli bassi.
## Uso: godot --headless --path godot --script res://scripts/game/math_story_audit.gd

const STORY_ARCHETYPES := [
	"story_sum", "story_take", "story_groups", "story_share",
	"story_rate", "story_change", "story_double",
]

func _init() -> void:
	_test_archetipi_validi()
	_test_presenti_ai_livelli_bassi()
	print("Math story audit OK — problemi a storia validi e presenti da livello 1")
	quit(0)

# Ogni archetipo narrativo: nodo valido, risposta coerente con le opzioni.
func _test_archetipi_validi() -> void:
	var gen := MathExerciseGenerator.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for arche in STORY_ARCHETYPES:
		for complexity in [1, 4, 8]:
			var node := gen._build_archetype(arche, complexity, rng, 1)
			assert(str(node.get("topic", "")) == "problemi", "%s deve avere topic 'problemi'" % arche)
			assert(str(node.get("prompt", "")).length() > 15, "%s: prompt troppo corto" % arche)
			assert(str(node.get("answer", "")).strip_edges() != "", "%s: risposta vuota" % arche)
			assert(str(node.get("explanation", "")).strip_edges() != "", "%s: spiegazione vuota" % arche)
			if str(node.get("format", "")) == "multiple_choice":
				var options: Array = node.get("options", [])
				assert(options.size() == 4, "%s: servono 4 opzioni" % arche)
				assert(options.has(str(node["answer"])), "%s: la risposta deve essere tra le opzioni" % arche)
				assert(_unique(options), "%s: opzioni duplicate" % arche)

# I problemi a storia devono comparire nel repertorio già a livello 1.
func _test_presenti_ai_livelli_bassi() -> void:
	var gen := MathExerciseGenerator.new()
	var eligible_l1: Array = gen._eligible_archetypes(MathExerciseGenerator.complexity_for_level(1))
	assert(eligible_l1.has("story_sum") and eligible_l1.has("story_take"), "problemi a storia assenti a livello 1")
	# Generando un gruppo, almeno un problema a storia deve uscire (repertorio ricco).
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var nodes := gen.build_nodes(3, 24, rng, [])
	var found_story := false
	for node in nodes:
		if str(node.get("topic", "")) == "problemi":
			found_story = true
			break
	assert(found_story, "nessun problema (topic 'problemi') in 24 estrazioni a livello 3")

func _unique(a: Array) -> bool:
	var seen: Dictionary = {}
	for v in a:
		if seen.has(v):
			return false
		seen[v] = true
	return true
