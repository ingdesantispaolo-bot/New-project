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

	# Adattività: un topic in ripasso spaziato viene ripescato e marcato review,
	# indipendentemente dalla difficoltà del livello corrente.
	var due := {"matematica:tabelline": 2}
	var review_mission := content.build_mission("matematica", 5, 3, due)
	var has_review := false
	for node in review_mission["nodes"]:
		if bool(node.get("review", false)):
			has_review = true
	assert(has_review, "il topic in ripasso deve essere ripescato e marcato review")

	# Senza ripasso pendente, nessun item è marcato review.
	var plain := content.build_mission("matematica", 1, 3)
	for node in plain["nodes"]:
		assert(not bool(node.get("review", false)), "senza due nessun review")

	print("C-04 audit OK — 8 materie, item validati e ripasso spaziato adattivo")
	quit(0)
