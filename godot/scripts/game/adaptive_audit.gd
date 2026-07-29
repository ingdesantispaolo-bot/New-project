extends SceneTree

## Audit selezione adattiva · difficoltà per materia.
## Verifica due proprietà nuove:
##  1) CALIBRAZIONE PER MATERIA: la difficoltà effettiva non esce mai dal range
##     che il banco può servire (un target fuori banco svuoterebbe la finestra di
##     selezione e la scelta diventerebbe casuale).
##  2) ADATTIVITÀ SU MASTERY: a parità di livello, chi fatica riceve item più
##     facili, chi padroneggia più difficili (materie e matematica generata).
## Uso: godot --headless --path godot --script res://scripts/game/adaptive_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	_test_calibrazione_per_materia(content)
	_test_adattivita_mastery(content)
	_test_matematica_adattiva(content)
	_test_retro_compatibile(content)
	_test_selezione_reale(content)
	print("Adaptive audit OK — difficoltà calibrata per materia e adattiva sulla mastery")
	quit(0)

# La difficoltà effettiva resta dentro il range reale del banco, a ogni livello.
func _test_calibrazione_per_materia(content: ContentManager) -> void:
	# Vale per OGNI materia, sia quando il banco copre tutta la scala sia quando è
	# più stretto: il clamp sul range reale è la garanzia che la finestra di
	# selezione non resti mai vuota.
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		if s == "matematica":
			continue  # generata a runtime: nessun banco statico da calibrare
		var span := content.subject_difficulty_range(s)
		assert(span.x >= 1 and span.y <= 4 and span.x <= span.y, "%s: range di banco non valido (%d-%d)" % [s, span.x, span.y])
		for level in [1, 6, 12, 18, 24]:
			for mastery in [0.1, 0.65, 0.95]:
				var eff := content.effective_difficulty(s, level, mastery)
				assert(eff >= span.x and eff <= span.y, "%s L%d: difficoltà %d fuori dal banco (%d-%d)" % [s, level, eff, span.x, span.y])
	# fisica copre 1-4: dopo l'espansione del banco il range resta completo.
	assert(content.subject_difficulty_range("fisica") == Vector2i(1, 4), "fisica deve esporre il range completo 1-4 del banco")

# A parità di livello, la mastery alza/abbassa la difficoltà effettiva.
func _test_adattivita_mastery(content: ContentManager) -> void:
	# geografia copre 1-4: la mastery ha spazio per muovere la difficoltà.
	var struggle := content.effective_difficulty("geografia", 6, 0.2)
	var neutral := content.effective_difficulty("geografia", 6, 0.65)
	var mastered := content.effective_difficulty("geografia", 6, 0.95)
	assert(struggle < mastered, "chi fatica deve ricevere item più facili di chi padroneggia")
	assert(struggle <= neutral and neutral <= mastered, "la difficoltà deve crescere in modo monotono con la mastery")

# Anche la matematica generata è adattiva: la mastery sposta il livello efficace.
func _test_matematica_adattiva(_content: ContentManager) -> void:
	var low := ContentManager.math_effective_level(9, 0.2)
	var high := ContentManager.math_effective_level(9, 0.95)
	assert(low < high, "matematica: livello efficace deve salire con la mastery")
	assert(ContentManager.math_effective_level(1, 0.1) >= 1, "livello efficace mai sotto 1")

# Mastery sconosciuta (-1): nessun nudge, comportamento solo-livello (ma calibrato).
func _test_retro_compatibile(content: ContentManager) -> void:
	var span := content.subject_difficulty_range("geografia")
	var expected := clampi(ContentManager.target_difficulty(6), span.x, span.y)
	assert(content.effective_difficulty("geografia", 6, -1.0) == expected, "mastery -1 deve valere solo-livello")
	assert(ContentManager.mastery_nudge(-1.0) == 0, "mastery sconosciuta = nessun nudge")

# La selezione reale rispetta la difficoltà effettiva (finestra ±1): senza item in
# ripasso, chi fatica non riceve i più difficili e chi padroneggia non riceve i più
# facili. Bound deterministici garantiti dalla finestra, non medie probabilistiche.
func _test_selezione_reale(content: ContentManager) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	# geografia (82 item, 1-4): pool ampio, nessun fallback casuale, nessun ripasso.
	var eff_low := content.effective_difficulty("geografia", 8, 0.2)
	var low := content.build_mission("geografia", 8, 6, {}, rng, 0.2)
	for node in low.get("nodes", []):
		assert(int(node.get("difficulty", 1)) <= eff_low + 1, "chi fatica non deve ricevere item oltre la sua difficoltà")
	var eff_high := content.effective_difficulty("geografia", 8, 0.95)
	var high := content.build_mission("geografia", 8, 6, {}, rng, 0.95)
	for node in high.get("nodes", []):
		assert(int(node.get("difficulty", 1)) >= eff_high - 1, "chi padroneggia non deve ricevere i item più facili")
	assert(eff_low < eff_high, "la difficoltà effettiva di chi fatica deve restare sotto quella di chi padroneggia")
