extends SceneTree

## CRITERIO 6 — ogni livello sblocca contenuto che il precedente non aveva.
##
## Non confrontiamo `format_depth(L)` con `format_depth(L - 1)`: a L13 il
## generatore quantitativo di matematica passa dai prodotti alle frazioni e la
## cardinalità totale può scendere anche se il contenuto nuovo esiste. Misuriamo
## invece la profondità delle specifiche il cui `minLevel` è proprio il livello
## corrente. È profondità marginale reale: prima non erano idonee, ora sì.
##
## La soglia è volutamente bassa e assoluta. Nei formati a dato fisso una buona
## specifica vale una prova; chiedere più di 1 spingerebbe ad autorare riempitivi.

const FIRST_LEVEL := 1
const LAST_LEVEL := 24
const MIN_MARGINAL_DEPTH := 1

func _init() -> void:
	var failures: Array = []
	print("Progressione dei contenuti — profondità nuova sbloccata per livello")
	print("LIVELLO    SPEC NUOVE    PROFONDITÀ MARGINALE")

	for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var new_specs := 0
		var marginal_depth := 0
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			for fmt_data in MinigameManager.FORMATS:
				var fmt := str(fmt_data)
				for spec_data in MinigameManager.eligible_specs(subject, fmt, level):
					var spec := spec_data as Dictionary
					var unlock_level := maxi(FIRST_LEVEL, int(spec.get("minLevel", FIRST_LEVEL)))
					if unlock_level != level:
						continue
					new_specs += 1
					marginal_depth += MinigameManager.spec_depth(fmt, spec, level)
		print("L%-8d %-12d %d" % [level, new_specs, marginal_depth])
		if marginal_depth < MIN_MARGINAL_DEPTH:
			failures.append(
				"L%d: profondità marginale %d (minimo %d) — non sblocca nessuna prova nuova" % [
					level, marginal_depth, MIN_MARGINAL_DEPTH])

	if not failures.is_empty():
		printerr("PROGRESSIONE CONTENUTI FERMA — %d livelli:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Content progression audit OK — tutti i 24 livelli sbloccano contenuto nuovo")
	quit(0)
