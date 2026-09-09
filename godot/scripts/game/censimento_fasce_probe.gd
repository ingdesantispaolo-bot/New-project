extends SceneTree

## Censimento: quanti ESERCIZI di banco e quante RICETTE di minigioco vede ogni
## materia in ciascuna delle otto fasce. Sonda di sola lettura, nessuna assert.

func _init() -> void:
	var content := ContentManager.new()
	_banco(content)
	_ricette()
	_formati()
	quit(0)

func _fascia_livello(band: int) -> int:
	return (band - 1) * 3 + 2   # il mondo centrale della fascia

func _banco(content: ContentManager) -> void:
	print("\n=== BANCO: item per fascia ===")
	print("materia        tier  totale |    F1    F2    F3    F4    F5    F6    F7    F8 | sessione")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var counts := content.bank_difficulty_counts(subject)
		var riga := ""
		var totale := 0
		for band in range(1, 9):
			var n := int(counts.get(band, 0))
			totale += n
			riga += "%6d" % n
		print("%-14s %4d %7d |%s | %d" % [
			subject, ApparatusConfig.priority_tier(subject), totale, riga,
			ApparatusConfig.exercise_nodes_for(subject)])

func _ricette() -> void:
	print("\n=== MINIGIOCHI: ricette idonee per fascia (cumulative, gate minLevel) ===")
	print("materia        tier |    F1    F2    F3    F4    F5    F6    F7    F8 | tot")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var riga := ""
		var massimo := 0
		for band in range(1, 9):
			var level := _fascia_livello(band)
			var n := 0
			for fmt in MinigameManager.FORMATS:
				n += MinigameManager.eligible_specs(subject, str(fmt), level).size()
			massimo = maxi(massimo, n)
			riga += "%6d" % n
		print("%-14s %4d |%s | %d" % [
			subject, ApparatusConfig.priority_tier(subject), riga, massimo])

func _formati() -> void:
	print("\n=== MECCANICHE giocabili per fascia (>= 2 ricette, cioe' in rotazione) ===")
	print("materia        tier |    F1    F2    F3    F4    F5    F6    F7    F8")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var riga := ""
		for band in range(1, 9):
			var level := _fascia_livello(band)
			var n := 0
			for fmt in MinigameManager.FORMATS:
				if MinigameManager.format_available(subject, str(fmt), level):
					n += 1
			riga += "%6d" % n
		print("%-14s %4d |%s" % [subject, ApparatusConfig.priority_tier(subject), riga])

	print("\n=== MECCANICHE che il RUNTIME espone davvero (runtime_formats_for) ===")
	print("materia        tier |    F1    F2    F3    F4    F5    F6    F7    F8")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var riga := ""
		for band in range(1, 9):
			var n: int = MinigameManager.runtime_formats_for(subject, _fascia_livello(band)).size()
			riga += "%6d" % n
		print("%-14s %4d |%s" % [subject, ApparatusConfig.priority_tier(subject), riga])
