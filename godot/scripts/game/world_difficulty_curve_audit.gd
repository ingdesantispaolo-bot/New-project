extends SceneTree

## Decisione vincolante 16 — curva effettiva dei 24 mondi.
##
## Le quattro bande dei banchi non bastano a descrivere la campagna. Questa
## guardia misura insieme difficoltà degli item realmente serviti, gesto
## richiesto dal formato e contenuto nuovo sbloccato a ogni mondo.
##
## La selezione è stocastica e le materie sono diverse: è ammessa una piccola
## inversione locale (0,35 punti sulla scala composita), non un salto di fase o
## una discesa prolungata. L'invarianza è verificata a parte: il mondo è il
## requisito che ogni studente deve padroneggiare prima di avanzare.

const REPEATS := 8
const MAX_ADJACENT_DROP := 0.35
const MIN_PHASE_GAIN := 3.5
const MAX_BAND_ERROR := 0.40
const MIN_FORMAT_GAIN := 0.12

var failures: Array = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _init() -> void:
	_check_policy()
	var measures: Array = []
	print("")
	print("Curva effettiva dei 24 mondi (%d campioni per materia)" % REPEATS)
	print("MONDO  BANDA  GESTO  SCORE  NUOVE/PROFONDITA")
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var measure := _measure_world(level)
		measures.append(measure)
		print("%2d     %4.2f   %4.2f  %5.2f  %4d/%d" % [
			level, float(measure["band"]), float(measure["format"]),
			float(measure["score"]), int(measure["newSpecs"]),
			int(measure["newDepth"])])
		_check(int(measure["newDepth"]) >= 1,
			"mondo %d: nessun contenuto nuovo sbloccato" % level)
		_check(absf(float(measure["band"]) - float(ContentManager.target_difficulty(level))) <= MAX_BAND_ERROR,
			"mondo %d: banda effettiva %.2f lontana dal target %d (tolleranza %.2f)" % [
				level, float(measure["band"]), ContentManager.target_difficulty(level),
				MAX_BAND_ERROR])
		if level > 1:
			var previous := measures[level - 2] as Dictionary
			var drop := float(previous["score"]) - float(measure["score"])
			_check(drop <= MAX_ADJACENT_DROP,
				"mondi %d->%d: inversione %.2f (massimo %.2f)" % [
					level - 1, level, drop, MAX_ADJACENT_DROP])

	_check_phase_gains(measures)
	var early_format := _mean(measures, 0, 4, "format")
	var late_format := _mean(measures, 17, 24, "format")
	_check(late_format - early_format >= MIN_FORMAT_GAIN,
		"i formati non maturano abbastanza: primi mondi %.2f, ultimi %.2f (guadagno minimo %.2f)" % [
			early_format, late_format, MIN_FORMAT_GAIN])
	_check_student_invariance()

	print("")
	if failures.is_empty():
		print("CURVA 24 MONDI audit VERDE — progressione continua, scostamento locale <= %.2f" % MAX_ADJACENT_DROP)
	else:
		printerr("CURVA 24 MONDI audit ROSSO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % str(failure))
	quit(0 if failures.is_empty() else 1)

func _check_policy() -> void:
	var seen: Dictionary = {}
	var previous_mc := 1.0
	var previous_stage := 0.0
	var previous_easy_weight := 99.0
	var previous_hard_weight := 0.0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var challenge := ContentManager.challenge_level(level)
		_check(challenge == level, "mondo %d: livello di sfida dichiarato %d" % [level, challenge])
		_check(not seen.has(challenge), "livello di sfida %d duplicato" % challenge)
		seen[challenge] = true
		var mc := ContentManager.mc_target_for("geografia", level)
		var stage := ContentManager.target_format_stage(level)
		var easy_weight := ContentManager.format_progression_weight("matching", level)
		var hard_weight := ContentManager.format_progression_weight("machine_path", level)
		if level > 1:
			_check(mc < previous_mc, "mondo %d: la quota di riconoscimento non diminuisce" % level)
			_check(stage > previous_stage, "mondo %d: il target dei formati non cresce" % level)
			_check(easy_weight < previous_easy_weight, "mondo %d: il peso dei formati introduttivi non cala" % level)
			_check(hard_weight > previous_hard_weight, "mondo %d: il peso dei formati vincolati non cresce" % level)
		previous_mc = mc
		previous_stage = stage
		previous_easy_weight = easy_weight
		previous_hard_weight = hard_weight
	_check(ContentManager.target_difficulty(4) == 1 and ContentManager.target_difficulty(5) == 2,
		"confine riconoscimento/processo non collocato fra i mondi 4 e 5")
	_check(ContentManager.target_difficulty(10) == 2 and ContentManager.target_difficulty(11) == 3,
		"confine processo/rappresentazione non collocato fra i mondi 10 e 11")
	_check(ContentManager.target_difficulty(17) == 3 and ContentManager.target_difficulty(18) == 4,
		"confine rappresentazione/vincoli non collocato fra i mondi 17 e 18")
	_check(ContentManager.mc_target_for("geografia", 1) <= 0.33,
		"il primo mondo supera il tetto del 33% di scelta multipla")
	_check(ContentManager.mc_target_for("elettronica", 1) == 0.0
		and ContentManager.mc_target_for("logica", 24) == 0.0,
		"le eccezioni manipolative di elettronica/logica sono state perse")

func _measure_world(level: int) -> Dictionary:
	var content := ContentManager.new()
	var band_total := 0.0
	var format_total := 0.0
	var nodes := 0
	for repeat in range(REPEATS):
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			var rng := RandomNumberGenerator.new()
			rng.seed = 160000 + level * 1000 + repeat * 31 + subject.hash()
			var sessions := [
				content.build_varied_mission(subject, level, 3, {}, rng, -1.0, {}, 60),
				content.minigame_manager.build_minigame(subject, level, rng),
			]
			for session_data in sessions:
				for node_data in Array((session_data as Dictionary).get("nodes", [])):
					var node := node_data as Dictionary
					var format := str(node.get("format", ""))
					_check(ContentManager.FORMAT_STAGE.has(format),
						"mondo %d: formato '%s' privo di fascia cognitiva" % [level, format])
					band_total += float(int(node.get("difficulty", 1)))
					format_total += float(ContentManager.format_stage(format))
					nodes += 1
	var band_mean := band_total / float(maxi(1, nodes))
	var format_mean := format_total / float(maxi(1, nodes))
	var marginal := _marginal(level)
	return {
		"band": band_mean,
		"format": format_mean,
		"score": band_mean * 6.0 + format_mean * 2.0,
		"newSpecs": marginal.x,
		"newDepth": marginal.y,
	}

func _marginal(level: int) -> Vector2i:
	var specs := 0
	var depth := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for format_data in MinigameManager.FORMATS:
			var format := str(format_data)
			for spec_data in MinigameManager.eligible_specs(subject, format, level):
				var spec := spec_data as Dictionary
				if maxi(1, int(spec.get("minLevel", 1))) != level:
					continue
				specs += 1
				depth += MinigameManager.spec_depth(format, spec, level)
	return Vector2i(specs, depth)

func _check_phase_gains(measures: Array) -> void:
	var phase_means := [
		_mean(measures, 0, 4, "score"),
		_mean(measures, 4, 10, "score"),
		_mean(measures, 10, 17, "score"),
		_mean(measures, 17, 24, "score"),
	]
	print("medie di fase: %s" % str(phase_means))
	for index in range(1, phase_means.size()):
		var gain := float(phase_means[index]) - float(phase_means[index - 1])
		_check(gain >= MIN_PHASE_GAIN,
			"fase %d->%d: guadagno %.2f (minimo %.2f)" % [
				index, index + 1, gain, MIN_PHASE_GAIN])

func _mean(measures: Array, start: int, end: int, key: String) -> float:
	var total := 0.0
	for index in range(start, end):
		total += float((measures[index] as Dictionary)[key])
	return total / float(maxi(1, end - start))

func _check_student_invariance() -> void:
	var beginner_total := 0.0
	var expert_total := 0.0
	var beginner_format := 0.0
	var expert_format := 0.0
	var nodes := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for repeat in range(REPEATS):
			var beginner_rng := RandomNumberGenerator.new()
			var expert_rng := RandomNumberGenerator.new()
			var seed_value := 240000 + repeat * 97 + subject.hash()
			beginner_rng.seed = seed_value
			expert_rng.seed = seed_value
			var beginner := ContentManager.new().build_varied_mission(
				subject, 24, 3, {}, beginner_rng, -1.0, {}, 0)
			var expert := ContentManager.new().build_varied_mission(
				subject, 24, 3, {}, expert_rng, -1.0, {}, 60)
			var beginner_nodes := Array(beginner.get("nodes", []))
			var expert_nodes := Array(expert.get("nodes", []))
			for index in mini(beginner_nodes.size(), expert_nodes.size()):
				var beginner_node := beginner_nodes[index] as Dictionary
				var expert_node := expert_nodes[index] as Dictionary
				beginner_total += float(int(beginner_node.get("difficulty", 1)))
				expert_total += float(int(expert_node.get("difficulty", 1)))
				beginner_format += float(ContentManager.format_stage(str(beginner_node.get("format", ""))))
				expert_format += float(ContentManager.format_stage(str(expert_node.get("format", ""))))
				nodes += 1
	var beginner_band := beginner_total / float(maxi(1, nodes))
	var expert_band := expert_total / float(maxi(1, nodes))
	var beginner_stage := beginner_format / float(maxi(1, nodes))
	var expert_stage := expert_format / float(maxi(1, nodes))
	print("invarianza L24: indietro banda %.2f/gesto %.2f · esperto banda %.2f/gesto %.2f" % [
		beginner_band, beginner_stage, expert_band, expert_stage])
	_check(is_equal_approx(expert_band, beginner_band),
		"mastery/esperienza cambiano la banda: indietro %.2f, esperto %.2f" % [
			beginner_band, expert_band])
	_check(is_equal_approx(beginner_stage, expert_stage),
		"mastery/esperienza cambiano i formati: indietro %.2f, esperto %.2f" % [
			beginner_stage, expert_stage])
