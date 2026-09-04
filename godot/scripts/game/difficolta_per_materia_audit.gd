extends SceneTree

## **La difficoltà segue il mondo.** (4 settembre 2026)
##
## Esperienza e mastery restano dati di valutazione: decidono se la competenza è
## stata padroneggiata e quindi se il gate può aprirsi. Non possono cambiare la
## banda o il livello dei formati con cui quella competenza viene dimostrata.

const OK := "DIFFICOLTA PER MATERIA audit VERDE — livello del mondo invariato"

var errors: Array = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _init() -> void:
	var content := ContentManager.new()
	print("")
	print("MATERIA        MONDO   INDIETRO(0)   ESPERTO(60)   TARGET")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for level in [1, 5, 11, 18, 24]:
			var span := content.subject_difficulty_range(subject)
			var target := clampi(ContentManager.target_difficulty(level), span.x, span.y)
			var beginner := content.effective_difficulty(subject, level, 0.1, 0)
			var expert := content.effective_difficulty(subject, level, 0.95, 60)
			if level in [1, 24]:
				print("%-13s %5d   %11d   %11d   %6d" % [subject, level, beginner, expert, target])
			_check(beginner == target and expert == target,
				"%s mondo %d: la banda dipende dallo studente (%d/%d, target %d)" % [
					subject, level, beginner, expert, target])
			_check(content.effective_exercise_level(subject, level, 0.1, 0) == level,
				"%s mondo %d: i formati sono stati abbassati" % [subject, level])

	# Il requisito per avanzare cresce e riguarda la padronanza del mondo.
	var previous_threshold := 0.0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var threshold := ApparatusConfig.mastery_threshold(level)
		_check(threshold >= previous_threshold,
			"mondo %d: soglia di padronanza %.3f sotto la precedente %.3f" % [
				level, threshold, previous_threshold])
		previous_threshold = threshold

	var save := GameSaveManager.new()
	var progression := ProgressionManager.new(save, content)
	_check(Array(progression.current_gate().get("coreSubjects", [])).size() == ApparatusConfig.SUBJECT_CYCLE.size(),
		"il gate non richiede tutte le dodici materie")
	_check(not progression.can_level_up(),
		"un profilo senza padronanza può accedere al livello successivo")

	print("")
	if errors.is_empty():
		print(OK)
	else:
		printerr("DIFFICOLTA PER MATERIA audit ROSSO — %d problemi:" % errors.size())
		for error in errors:
			printerr("  - %s" % str(error))
	quit(0 if errors.is_empty() else 1)
