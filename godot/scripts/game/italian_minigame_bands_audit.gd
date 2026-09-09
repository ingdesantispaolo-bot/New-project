extends SceneTree

## Verifica che il percorso italiano copra davvero tutte le otto fasce e che le
## sfide prodotte rispettino il contratto comune degli esercizi.

const Catalog = preload("res://scripts/game/italian_minigame_catalog.gd")
const Interaction = preload("res://scripts/game/exercise_interaction.gd")

func _init() -> void:
	var manager := MinigameManager.new()
	var formats: Dictionary = {}
	for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
		var options := Catalog.options_for_band(band)
		assert(options.size() >= 2, "italiano fascia %d: servono almeno due varianti" % band)
		for option_data in options:
			var option := option_data as Dictionary
			assert(str(option.get("title", "")).strip_edges() != "", "italiano fascia %d: titolo mancante" % band)
			assert(int(option.get("complexity", 0)) == band, "italiano fascia %d: complessita' non calibrata" % band)
			var fmt := str(option.get("format", ""))
			formats[fmt] = true
			var rng := RandomNumberGenerator.new()
			rng.seed = 17000 + band * 100 + str(option.get("title", "")).hash()
			var level := (band - 1) * 3 + 2
			var node := manager._build_node_for_format(fmt, "italiano", level, 0, rng, 0, option.get("spec", {}))
			assert(int(node.get("difficulty", 0)) == band, "italiano fascia %d: nodo a difficolta' %d" % [band, int(node.get("difficulty", 0))])
			var validation := Interaction.validate(node)
			assert(bool(validation.get("ok", false)), "italiano fascia %d (%s): %s" % [band, str(option.get("title", "")), str(validation.get("errors", []))])

		# L'integrazione deve garantire una sola campata calibrata, senza gonfiare o
		# svuotare la sessione e senza dipendere dal formato sorteggiato.
		var session_rng := RandomNumberGenerator.new()
		session_rng.seed = 28000 + band
		var session := manager.build_minigame("italiano", (band - 1) * 3 + 2, session_rng)
		var nodes: Array = session.get("nodes", [])
		assert(nodes.size() >= 4, "italiano fascia %d: sessione incompleta" % band)
		var calibrated := 0
		for node_data in nodes:
			var node := node_data as Dictionary
			var validation := Interaction.validate(node)
			assert(bool(validation.get("ok", false)), "italiano fascia %d: nodo live non valido: %s" % [band, str(validation.get("errors", []))])
			if node.has("calibrationBand"):
				calibrated += 1
				assert(int(node.get("calibrationBand", 0)) == band)
				assert(int(node.get("challengeComplexity", 0)) == band)
				assert(int(node.get("difficulty", 0)) == band)
		assert(calibrated == 1, "italiano fascia %d: attese 1 campata calibrata, trovate %d" % [band, calibrated])

		var guided_rng := RandomNumberGenerator.new()
		guided_rng.seed = 39000 + band
		var guided := manager.build_guided_minigame("italiano", "ortografia", "", (band - 1) * 3 + 2, guided_rng)
		var guided_calibrated := 0
		for node_data in Array(guided.get("nodes", [])):
			if (node_data as Dictionary).has("calibrationBand"):
				guided_calibrated += 1
		assert(guided_calibrated == 1, "italiano fascia %d: la pratica guidata ha rimosso la campata calibrata" % band)

	assert(formats.size() >= 4, "il percorso italiano deve alternare almeno quattro meccaniche")
	print("ITALIAN MINIGAME BANDS audit VERDE — 8 fasce, 16 sfide, %d meccaniche" % formats.size())
	quit(0)
