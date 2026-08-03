extends SceneTree

## Censimento: quanti contenuti distinti esistono davvero, materia per materia e
## livello per livello. Serve a scrivere il recap con i numeri veri invece che
## con l'impressione di chi ha scritto i banchi.
##
## Non e' un audit: non fallisce mai. Stampa e basta.

func _init() -> void:
	var cm := ContentManager.new()
	cm.setup()
	var subjects: Array = ApparatusConfig.SUBJECT_CYCLE.duplicate()

	print("=== BANCHI: item per materia, per banda di difficolta' ===")
	print("materia        tot  b1  b2  b3  b4  topic  formati")
	var totale := 0
	for subject in subjects:
		var items: Array = cm._load_bank(str(subject))
		var bands := [0, 0, 0, 0]
		var topics: Dictionary = {}
		var formats: Dictionary = {}
		for entry in items:
			var item := entry as Dictionary
			var band: int = clampi(int(item.get("difficulty", 1)), 1, 4)
			bands[band - 1] += 1
			topics[str(item.get("topic", ""))] = true
			formats[str(item.get("format", "multiple_choice"))] = true
		totale += items.size()
		print("%-13s %4d %3d %3d %3d %3d   %3d   %d" % [
			subject, items.size(), bands[0], bands[1], bands[2], bands[3],
			topics.size(), formats.size()])
	print("TOTALE item nei banchi: %d" % totale)

	print("\n=== MATERIA DEL MONDO, livello per livello ===")
	var per_subject: Dictionary = {}
	for level in range(1, 25):
		var subject := ApparatusConfig.world_subject(level)
		var seen: Array = per_subject.get(subject, [])
		seen.append(level)
		per_subject[subject] = seen
	for subject in subjects:
		print("%-13s mondi %s" % [subject, str(per_subject.get(subject, []))])

	print("\n=== PROFONDITA': item eleggibili per materia al livello 1, 8, 16, 24 ===")
	print("materia        L1   L8  L16  L24")
	for subject in subjects:
		var row := "%-13s" % subject
		for level in [1, 8, 16, 24]:
			var items: Array = cm._load_bank(str(subject))
			var eligible := 0
			var target := ContentManager.target_difficulty(level)
			for entry in items:
				var band := int((entry as Dictionary).get("difficulty", 1))
				if band <= target:
					eligible += 1
			row += " %4d" % eligible
		print(row)
	quit(0)
