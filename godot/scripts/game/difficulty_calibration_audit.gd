extends SceneTree

## Audit di CALIBRAZIONE della difficoltà (playthrough #10: la qualità delle
## domande deve salire di livello). Verifica gli invarianti di scala e SEGNALA le
## materie il cui banco è "tappato" sotto la difficoltà 4: alle loro ricomparse ai
## livelli alti (13–24) la difficoltà effettiva non può crescere, e servono item
## più difficili. È una diagnosi didattica, non un fallimento del motore.
## Uso: godot --headless --path godot --script res://scripts/game/difficulty_calibration_audit.gd

func _init() -> void:
	var content := ContentManager.new()

	# 1) Invarianti di scala del motore.
	assert(ContentManager.target_difficulty(1) == 1, "il livello 1 parte dalla difficoltà 1")
	assert(ContentManager.target_difficulty(24) == 4, "i livelli alti raggiungono la difficoltà 4")
	var prev := 0
	for level in range(1, 25):
		var t := ContentManager.target_difficulty(level)
		assert(t >= prev, "la difficoltà target deve essere non decrescente")
		prev = t
	# La matematica generata scala con il livello (complessità fine oltre la banda).
	assert(ContentManager.math_effective_level(16, 0.9) > ContentManager.math_effective_level(4, 0.2),
		"la matematica deve diventare più complessa ai livelli alti")

	# 2) Diagnosi per materia: banco capace di salire fino a 4? La materia ricompare
	# a (indice) e a (indice+12): la seconda ricomparsa punta a difficoltà 4.
	var gaps: Array = []
	var subjects: Array = ApparatusConfig.SUBJECT_CYCLE
	print("Calibrazione difficoltà per materia (banda banco → difficoltà effettiva ai due focus):")
	for i in subjects.size():
		var subject := str(subjects[i])
		if subject == "matematica":
			print("  %-13s generata (scala con la complessità, nessun tetto di banco)" % subject)
			continue
		var span := content.subject_difficulty_range(subject)
		var low_level := i + 1
		var high_level := i + 13
		var eff_low := content.effective_difficulty(subject, low_level, 0.5)
		var eff_high := content.effective_difficulty(subject, high_level, 0.9)
		var capped := span.y < 4
		print("  %-13s banco d%d–d%d · focus L%d→d%d, L%d→d%d%s" % [
			subject, span.x, span.y, low_level, eff_low, high_level, eff_high,
			("  ⚠ TETTO < 4" if capped else "")])
		if capped:
			gaps.append({"subject": subject, "maxDifficulty": span.y})

	# Report finale: elenco delle materie da arricchire per i livelli alti.
	if gaps.is_empty():
		print("Difficulty calibration OK — ogni materia può salire fino alla difficoltà 4")
	else:
		var names: Array = []
		for g in gaps:
			names.append("%s(≤d%d)" % [str(g["subject"]), int(g["maxDifficulty"])])
		print("Difficulty calibration — DIAGNOSI: banchi da arricchire con item difficili per i livelli alti: %s" % ", ".join(PackedStringArray(names)))
	quit(0)
