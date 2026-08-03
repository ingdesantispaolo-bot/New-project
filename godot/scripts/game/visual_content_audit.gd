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
			if MinigameManager.spec_depth(fmt, spec, 12) != 1:
				failures.append("%s/%s: profondità spec diversa da 1" % [fmt, str(spec.get("topic", ""))])
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
	for expected in [["musica", "notation"], ["geografia", "map"], ["storia", "hotspot"]]:
		var subject := str(expected[0])
		var fmt := str(expected[1])
		var reached := false
		for seed in 128:
			var rng := RandomNumberGenerator.new()
			rng.seed = 20000 + seed
			var session := manager.build_minigame(subject, 24, rng)
			for node_data in session.get("nodes", []):
				if str((node_data as Dictionary).get("format", "")) == fmt:
					reached = true
					break
			if reached:
				break
		if not reached:
			failures.append("%s: formato %s irraggiungibile nella rotazione reale" % [subject, fmt])

	if not failures.is_empty():
		printerr("CONTENUTO VISUALE NON VALIDO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("VISUAL CONTENT audit OK — %d nodi, builder reali, profondità e rotazione" % checked)
	quit(0)
