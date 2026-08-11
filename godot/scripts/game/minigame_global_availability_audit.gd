extends SceneTree

## Audit trasversale dei minigiochi nei 24 mondi.
##
## Distingue la meccanica dal contenuto: una specifica avanzata puo' restare
## bloccata, ma il formato di gioco compatibile con una materia deve avere una
## variante introduttiva e deve essere realmente estraibile dal runtime.

const FIRST_LEVEL := 1
const LAST_LEVEL := 24
const PROBE_SEEDS := 32

func _init() -> void:
	var failures: Array = []
	print("Disponibilita globale dei minigiochi")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var rows: Array = []
		for fmt_data in MinigameManager.FORMATS:
			var fmt := str(fmt_data)
			var final_specs := MinigameManager.eligible_specs(subject, fmt, LAST_LEVEL)
			if final_specs.is_empty():
				continue
			var first_content := _first_content_level(subject, fmt)
			var first_runtime := _first_runtime_level(subject, fmt)
			rows.append("%s:%d/%d" % [fmt, first_content, first_runtime])
			if first_runtime < 0:
				failures.append("%s/%s: contenuto presente ma formato mai estratto" % [subject, fmt])
		print("%-13s %s" % [subject, "  ".join(PackedStringArray(rows))])

	# In ogni livello tutte le meccaniche devono essere raggiungibili attraverso
	# almeno una delle dodici materie presenti nel mondo. Il generatore guidato
	# deve poi rispettare davvero il formato scelto dal direttore.
	var manager := MinigameManager.new()
	for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var owners: Dictionary = {}
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			for fmt_data in MinigameManager.runtime_formats_for(subject, level):
				var fmt := str(fmt_data)
				if not owners.has(fmt):
					owners[fmt] = subject
		for fmt_data in MinigameManager.FORMATS:
			var fmt := str(fmt_data)
			if not owners.has(fmt):
				failures.append("mondo %d: meccanica %s non disponibile" % [level, fmt])
				continue
			var subject := str(owners[fmt])
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("guided:%d:%s:%s" % [level, subject, fmt])
			var session := manager.build_guided_minigame(subject, "", fmt, level, rng)
			if _first_format(session, fmt).is_empty():
				failures.append("mondo %d: %s/%s ignora il formato guidato" % [level, subject, fmt])
				continue
			var validation := ExerciseInteraction.validate_session(session)
			if not bool(validation.get("ok", false)):
				failures.append("mondo %d: %s/%s non valido: %s" % [level, subject, fmt, str(validation.get("errors", []))])

	# Disponibilita del minigioco d'azione sulle frazioni: e il primo contenuto
	# ad adottare il contratto globale e fa da regressione per la difficolta a tier.
	for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("global-fraction-forge:%d" % level)
		var session := manager.build_topic_minigame("matematica", "frazioni", level, rng)
		var forge := _first_theme(session, "fraction_forge")
		if forge.is_empty():
			failures.append("Forgia delle Frazioni assente al livello %d" % level)
			continue
		var difficulty := int(forge.get("difficulty", 1))
		for statement_data in Array(forge.get("statements", [])):
			var statement: Dictionary = statement_data
			if int(statement.get("minDifficulty", 1)) > difficulty:
				failures.append("Forgia L%d: contenuto tier %d in difficolta %d" % [
					level, int(statement.get("minDifficulty", 1)), difficulty])

	_test_director_rotation(failures)

	if not failures.is_empty():
		printerr("MINIGAME GLOBAL AVAILABILITY FALLITO - %d problemi" % failures.size())
		for failure in failures:
			printerr("  - %s" % str(failure))
		quit(1)
		return
	print("Minigame global availability audit OK")
	quit(0)

func _first_content_level(subject: String, fmt: String) -> int:
	for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
		if not MinigameManager.eligible_specs(subject, fmt, level).is_empty():
			return level
	return -1

func _first_runtime_level(subject: String, fmt: String) -> int:
	var manager := MinigameManager.new()
	for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
		for seed_index in PROBE_SEEDS:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("global:%s:%s:%d:%d" % [subject, fmt, level, seed_index])
			for node_data in Array(manager.build_minigame(subject, level, rng).get("nodes", [])):
				if str((node_data as Dictionary).get("format", "")) == fmt:
					return level
	return -1

func _first_theme(session: Dictionary, theme: String) -> Dictionary:
	for node_data in Array(session.get("nodes", [])):
		var node: Dictionary = node_data
		if str(node.get("actionTheme", "")) == theme:
			return node
	return {}

func _first_format(session: Dictionary, fmt: String) -> Dictionary:
	for node_data in Array(session.get("nodes", [])):
		var node: Dictionary = node_data
		if str(node.get("format", "")) == fmt:
			return node
	return {}

func _test_director_rotation(failures: Array) -> void:
	# Una palestra completata rinasce con `practiceRound + 1`: dopo un giro della
	# tavolozza ogni meccanica compatibile deve essere comparsa almeno una volta.
	for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var focus := str(Dictionary(profile.get("learningFocus", {})).get("subject", ""))
		var seen: Dictionary = {}
		for round_index in MinigameManager.FORMATS.size() + 2:
			var rounds: Dictionary = {}
			for subject_data in ApparatusConfig.SUBJECT_CYCLE:
				rounds[str(subject_data)] = round_index
			var events := MissionEventDirector.plan(
				profile, {"practiceRound": rounds}, "global-rotation-%d" % level)
			for event_data in events:
				var event: Dictionary = event_data
				if str(event.get("kind", "")) != "practice":
					continue
				var subject := str(event.get("subject", ""))
				var fmt := str(event.get("format", ""))
				if not MinigameManager.runtime_formats_for(subject, level).has(fmt):
					failures.append("mondo %d: direttore assegna %s non disponibile a %s" % [level, fmt, subject])
				var subject_seen: Dictionary = seen.get(subject, {})
				subject_seen[fmt] = true
				seen[subject] = subject_seen
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			if subject == focus:
				continue
			for fmt_data in MinigameManager.runtime_formats_for(subject, level):
				var fmt := str(fmt_data)
				if not Dictionary(seen.get(subject, {})).has(fmt):
					failures.append("mondo %d: rotazione %s non raggiunge %s" % [level, subject, fmt])
