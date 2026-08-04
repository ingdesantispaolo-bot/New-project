extends SceneTree

## Secondo taglio del censimento: formati, topic e specifiche dei minigiochi.

func _init() -> void:
	var cm := ContentManager.new()
	var subjects: Array = ApparatusConfig.SUBJECT_CYCLE.duplicate()

	print("=== FORMATI nei banchi ===")
	for subject in subjects:
		var items: Array = cm._load_bank(str(subject))
		var formats: Dictionary = {}
		for entry in items:
			var f := str((entry as Dictionary).get("format", "multiple_choice"))
			formats[f] = int(formats.get(f, 0)) + 1
		var parts: Array = []
		for f in formats.keys():
			parts.append("%s %d%%" % [f, roundi(100.0 * float(formats[f]) / maxf(1.0, float(items.size())))])
		print("%-13s %s" % [subject, ", ".join(PackedStringArray(parts))])

	print("\n=== TOPIC per materia ===")
	for subject in subjects:
		var topics: Array = cm.bank_topics(str(subject))
		print("%-13s %2d topic" % [subject, topics.size()])

	print("\n=== SPECIFICHE DEI MINIGIOCHI per materia ===")
	var tables := {
		"matching": MinigameManager.MATCHING, "ordering": MinigameManager.ORDERING,
		"classification": MinigameManager.CLASSIFICATION, "graph": MinigameManager.GRAPH,
		"circuit": MinigameManager.CIRCUIT, "cycle": MinigameManager.CYCLE,
		"code_debug": MinigameManager.CODE_DEBUG, "notation": MinigameManager.NOTATION,
		"map": MinigameManager.MAP_READING, "hotspot": MinigameManager.HOTSPOT,
	}
	var per_subject: Dictionary = {}
	for fmt in tables.keys():
		for subject in (tables[fmt] as Dictionary).keys():
			var specs: Array = (tables[fmt] as Dictionary)[subject]
			var row: Dictionary = per_subject.get(str(subject), {})
			row[str(fmt)] = specs.size()
			per_subject[str(subject)] = row
	for subject in subjects:
		var row: Dictionary = per_subject.get(str(subject), {})
		var parts: Array = []
		var totale := 0
		for fmt in row.keys():
			parts.append("%s:%d" % [fmt, int(row[fmt])])
			totale += int(row[fmt])
		parts.sort()
		print("%-13s %2d specifiche  %s" % [subject, totale, ", ".join(PackedStringArray(parts))])
	quit(0)
