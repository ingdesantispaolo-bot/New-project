extends SceneTree

## Guardia storica della calibrazione. Dal 4 settembre 2026 l'adattamento della
## difficoltà è disattivato: mastery ed esperienza misurano se il livello è
## padroneggiato, ma non cambiano il livello degli esercizi.

func _init() -> void:
	var content := ContentManager.new()
	_test_calibrazione_per_materia(content)
	_test_invarianza(content)
	_test_matematica()
	_test_selezione_reale()
	print("Adaptive audit OK — nessun adattamento: gli esercizi restano al livello del mondo")
	quit(0)

func _test_calibrazione_per_materia(content: ContentManager) -> void:
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var span := content.subject_difficulty_range(subject)
		assert(span.x >= 1 and span.y <= 4 and span.x <= span.y,
			"%s: range di banco non valido (%d-%d)" % [subject, span.x, span.y])
		for level in [1, 5, 11, 18, 24]:
			var expected := clampi(ContentManager.target_difficulty(level), span.x, span.y)
			assert(content.effective_difficulty(subject, level, 0.1, 0) == expected,
				"%s L%d: lo studente in difficoltà non deve ricevere una banda diversa" % [subject, level])
			assert(content.effective_difficulty(subject, level, 0.95, 60) == expected,
				"%s L%d: lo studente esperto non deve ricevere una banda diversa" % [subject, level])

func _test_invarianza(content: ContentManager) -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var low := content.effective_difficulty("geografia", level, 0.1, 0)
		var high := content.effective_difficulty("geografia", level, 0.95, 60)
		assert(low == high, "geografia L%d: mastery/esperienza modificano la banda (%d != %d)" % [level, low, high])
		assert(content.effective_exercise_level("geografia", level, 0.1, 0) == level,
			"geografia L%d: il livello dei formati è stato abbassato" % level)

func _test_matematica() -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		assert(ContentManager.math_effective_level(level, 0.1) == level,
			"matematica L%d: mastery bassa modifica il generatore" % level)
		assert(ContentManager.math_effective_level(level, 0.95) == level,
			"matematica L%d: mastery alta modifica il generatore" % level)

func _test_selezione_reale() -> void:
	for subject in ["matematica", "geografia", "italiano", "logica"]:
		for level in [5, 12, 20, 24]:
			var low_rng := RandomNumberGenerator.new()
			var high_rng := RandomNumberGenerator.new()
			var seed_value: int = 41000 + level * 101 + str(subject).hash()
			low_rng.seed = seed_value
			high_rng.seed = seed_value
			var low := ContentManager.new().build_varied_mission(
				str(subject), level, 5, {}, low_rng, 0.1, {}, 0)
			var high := ContentManager.new().build_varied_mission(
				str(subject), level, 5, {}, high_rng, 0.95, {}, 60)
			assert(_profile(low) == _profile(high),
				"%s L%d: la sessione cambia con mastery/esperienza" % [subject, level])

func _profile(session: Dictionary) -> Array:
	var profile: Array = []
	for node_data in Array(session.get("nodes", [])):
		var node := node_data as Dictionary
		profile.append("%s|%s|%d" % [
			str(node.get("format", "")), str(node.get("topic", "")),
			int(node.get("difficulty", 0))])
	return profile
