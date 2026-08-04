extends SceneTree

## Gate dei contenuti visuali: prova i costruttori usati dal gioco, non una copia
## manuale del contratto, e dimostra che i formati entrano davvero in rotazione.

const INTERACTION := preload("res://scripts/game/exercise_interaction.gd")

func _init() -> void:
	var manager := MinigameManager.new()
	var failures: Array = []
	var checked := 0
	var builder_cases := [
		["notation", "musica", MinigameManager.NOTATION, "_notation_node", "symbols"],
		["map", "geografia", MinigameManager.MAP_READING, "_map_node", "targets"],
		["hotspot", "storia", MinigameManager.HOTSPOT, "_hotspot_node", "targets"],
	]

	for case_data in builder_cases:
		var fmt := str(case_data[0])
		var subject := str(case_data[1])
		var table := case_data[2] as Dictionary
		var builder := str(case_data[3])
		var shuffled_field := str(case_data[4])
		for spec_index in Array(table[subject]).size():
			var spec := Array(table[subject])[spec_index] as Dictionary
			var rng := RandomNumberGenerator.new()
			rng.seed = 9000 + spec_index
			var node := manager.call(builder, subject, spec, 2, rng, spec_index) as Dictionary
			checked += 1
			var report := INTERACTION.validate(node)
			if not bool(report.get("ok", false)):
				failures.append("%s/%s: %s" % [fmt, str(spec.get("topic", "")), ", ".join(PackedStringArray(report.get("errors", [])))])
			# La profondità di una specifica a dato fisso è **una prova per
			# domanda**: quella della specifica più quelle dichiarate in
			# `domande`. Fino al 3 agosto la regola era «esattamente 1», ed era
			# giusta quando una specifica poteva porre una domanda sola; adesso
			# la stessa figura ne può porre più d'una, e ognuna è una prova vera
			# (risposta diversa, spiegazione diversa, ragionamento diverso).
			#
			# Il controllo resta **stretto**: non «almeno 1», ma il numero esatto.
			# Serve a impedire la cosa che la regola vecchia impediva, cioè che
			# qualcuno gonfi la profondità dichiarando un pool su un formato che
			# un pool non ce l'ha.
			var attesa := 1 + Array(spec.get("domande", [])).size()
			if MinigameManager.spec_depth(fmt, spec, 12) != attesa:
				failures.append("%s/%s: profondità %d, attesa %d (1 + %d domande)" % [
					fmt, str(spec.get("topic", "")),
					MinigameManager.spec_depth(fmt, spec, 12), attesa,
					Array(spec.get("domande", [])).size()])
			if (node.get(shuffled_field, []) as Array).is_empty():
				failures.append("%s/%s: campo presentazione vuoto" % [fmt, str(spec.get("topic", ""))])

	# La notazione deriva la posizione orizzontale dall'array: su più seed la
	# risposta deve occupare posizioni diverse, non diventare una scorciatoia.
	var notation_spec := MinigameManager.NOTATION["musica"][0] as Dictionary
	var answer_positions: Dictionary = {}
	for seed in 32:
		var rng := RandomNumberGenerator.new()
		rng.seed = 12000 + seed
		var node := manager.call("_notation_node", "musica", notation_spec, 2, rng, seed) as Dictionary
		var ids := (node["symbols"] as Array).map(func(entry): return str((entry as Dictionary).get("id", "")))
		answer_positions[ids.find(str(node["answer"]))] = true
	if answer_positions.size() < 2:
		failures.append("notation: la risposta resta nella stessa posizione orizzontale")

	# Ogni nuovo specialista deve essere producibile dal selettore reale. Si usa
	# un ventaglio di seed perché la materia ruota anche altri specialisti.
	for expected in [["musica", "notation", 6], ["geografia", "map", 9], ["storia", "hotspot", 11]]:
		var subject := str(expected[0])
		var fmt := str(expected[1])
		var introduction_level := int(expected[2])
		var reached := false
		for seed in 128:
			var rng := RandomNumberGenerator.new()
			rng.seed = 20000 + seed
			var session := manager.build_minigame(subject, introduction_level, rng)
			for node_data in session.get("nodes", []):
				if str((node_data as Dictionary).get("format", "")) == fmt:
					reached = true
					break
			if reached:
				break
		if not reached:
			failures.append("%s: formato %s irraggiungibile al mondo %d" % [subject, fmt, introduction_level])

	if not failures.is_empty():
		printerr("CONTENUTO VISUALE NON VALIDO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("VISUAL CONTENT audit OK — %d nodi, builder reali, profondità e rotazione" % checked)
	quit(0)
