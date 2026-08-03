extends SceneTree

## CRITERIO 5 — una specifica sola significa la stessa consegna ogni volta,
## anche quando pesca dati diversi. Dopo la consegna O-P7 del 3 agosto il
## cricchetto è vincolante sull'intero ciclo: nessuna materia ha più una corsia
## diagnostica che possa nascondere una regressione.

const MIN_ELIGIBLE_SPECS := 2
const MIN_FIXED_SPECS := 6
const FIRST_LEVEL := 1
const LAST_LEVEL := 24
const STEM_SUBJECTS := ["matematica", "fisica", "elettronica", "coding", "scienze"]
const STRICT_SUBJECTS := ApparatusConfig.SUBJECT_CYCLE
const FIXED_FORMATS := ["graph", "circuit", "code_debug"]

func _init() -> void:
	var failures: Array = []
	var pending: Dictionary = {}

	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for fmt_data in MinigameManager.FORMATS:
			var fmt := str(fmt_data)
			# Una coppia assente per tutta la campagna non è un buco: il formato non
			# è servito da quella materia.
			if MinigameManager.eligible_specs(subject, fmt, LAST_LEVEL).is_empty():
				continue
			for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
				# Un formato non viene servito finché non offre almeno due consegne:
				# il cricchetto riguarda le corsie giocabili, non contenuto futuro.
				if not MinigameManager.format_available(subject, fmt, level):
					continue
				var count := MinigameManager.eligible_specs(subject, fmt, level).size()
				if count != 1:
					continue
				var issue := "%s/%s L%d: una sola specifica idonea" % [subject, fmt, level]
				if STRICT_SUBJECTS.has(subject):
					failures.append(issue)
				else:
					var key := "%s/%s" % [subject, fmt]
					var levels: Array = pending.get(key, [])
					levels.append(level)
					pending[key] = levels

	# Contratto specifico C-P8.5: i tre formati a dato fisso STEM hanno almeno
	# sei consegne complessive e almeno due disponibili dal primo livello.
	for subject in STEM_SUBJECTS:
		for fmt in FIXED_FORMATS:
			var first_count := MinigameManager.eligible_specs(str(subject), str(fmt), FIRST_LEVEL).size()
			var final_count := MinigameManager.eligible_specs(str(subject), str(fmt), LAST_LEVEL).size()
			if first_count < MIN_ELIGIBLE_SPECS:
				failures.append("%s/%s: %d specifiche a L1 (minimo %d)" % [
					subject, fmt, first_count, MIN_ELIGIBLE_SPECS])
			if final_count < MIN_FIXED_SPECS:
				failures.append("%s/%s: %d specifiche a L24 (minimo %d)" % [
					subject, fmt, final_count, MIN_FIXED_SPECS])

	print("Copertura specifiche — criterio 5")
	print("12 materie: cricchetto ≥%d per livello; formati fissi STEM ≥%d a L24" % [
		MIN_ELIGIBLE_SPECS, MIN_FIXED_SPECS])
	if not pending.is_empty():
		print("Umanistiche ancora diagnostiche (%d coppie):" % pending.size())
		for key in pending.keys():
			print("  - %s: %s" % [str(key), _level_span(pending[key] as Array)])

	if not failures.is_empty():
		printerr("COPERTURA SPECIFICHE STEM FALLITA — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Spec coverage audit OK — copertura vincolante su tutte le 12 materie")
	quit(0)

func _level_span(levels: Array) -> String:
	if levels.is_empty():
		return "—"
	if levels.size() == 1:
		return "L%d" % int(levels[0])
	return "L%d–L%d" % [int(levels[0]), int(levels[levels.size() - 1])]
