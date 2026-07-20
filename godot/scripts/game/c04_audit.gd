extends SceneTree

const SUBJECTS := ["matematica", "italiano", "inglese", "coding", "fisica", "musica", "latino", "elettronica"]

func _init() -> void:
	var content := ContentManager.new()
	for subject in SUBJECTS:
		var session := content.build_mission(subject, 1, 3)
		assert(str(session.get("subject", "")) == subject)
		assert((session.get("nodes", []) as Array).size() >= 1, "banco vuoto: %s" % subject)
		for item in session["nodes"]:
			assert(str(item.get("answer", "")).strip_edges() != "", "risposta mancante: %s" % subject)
			assert(str(item.get("explanation", "")).strip_edges() != "", "spiegazione mancante: %s" % subject)
			assert(int(item.get("difficulty", 0)) in [1, 2, 3, 4], "difficolta invalida: %s" % subject)
	print("C-04 audit OK — 8 materie con banchi giocabili e item validati")
	quit(0)
