extends SceneTree

## Reporter (non un test): per ogni materia elenca banco (topic + difficolta) e i
## minigiochi disponibili con il numero di gruppi per formato, piu i formati di una
## missione varia campione. Uso solo per fare il punto sui contenuti.
## Uso: godot --headless --path godot --script res://scripts/game/content_by_subject.gd

func _n(dict, subject) -> int:
	return int(Array(dict.get(subject, [])).size())

func _init() -> void:
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	print("MATERIA        | BANCO (topic/diff) | MATCH ORD CLASS GRAPH CIRC CODE | NUMERIC | MISSIONE VARIA (formati)")
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var span := content.subject_difficulty_range(s)
		var topics := content.bank_topics(s).size()
		var numeric := "si" if s in MinigameManager.NUMERIC_ORDERING_SUBJECTS else "-"
		# formati di una missione varia campione
		var varied := content.build_varied_mission(s, 6, 3, {}, rng)
		var fmts := {}
		for node in varied.get("nodes", []):
			fmts[str(node.get("format", ""))] = true
		var bank_desc := "d%d-d%d, %d top" % [span.x, span.y, topics]
		if s == "matematica":
			bank_desc = "generato (16 top)"
		print("%-14s | %-18s |   %d    %d    %d     %d    %d    %d  |   %-4s | %s" % [
			s, bank_desc,
			_n(MinigameManager.MATCHING, s), _n(MinigameManager.ORDERING, s),
			_n(MinigameManager.CLASSIFICATION, s), _n(MinigameManager.GRAPH, s),
			_n(MinigameManager.CIRCUIT, s), _n(MinigameManager.CODE_DEBUG, s),
			numeric, ", ".join(PackedStringArray(fmts.keys()))])
	print("(MATCH=abbinamento ORD=ordinamento CLASS=classificazione GRAPH=grafico CIRC=circuito CODE=code-debug NUMERIC=ordinamento numerico generato)")
	quit(0)
