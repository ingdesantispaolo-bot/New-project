extends SceneTree

const SUBJECTS := [
	"matematica", "italiano", "inglese", "coding", "fisica", "musica", "latino", "elettronica",
	# Materie nuove (scope ampliato 2026-07-21).
	"geografia", "scienze", "storia", "logica",
]

func _init() -> void:
	var content := ContentManager.new()
	for subject in SUBJECTS:
		var session := content.build_mission(subject, 1, 3)
		assert(str(session.get("subject", "")) == subject)
		assert((session.get("nodes", []) as Array).size() >= 1, "banco vuoto: %s" % subject)
		for item in session["nodes"]:
			# **Ogni formato ha i suoi campi-soluzione.** (10 settembre 2026) Qui
			# c'era `assert(item.answer != "")`, vero finche' il banco portava solo
			# crocette e risposte libere. Da quando porta anche ordinamenti e
			# abbinamenti l'`answer` non esiste piu' per tutti, e il campo giusto lo
			# sa `ExerciseInteraction`, che e' il validatore del contratto comune.
			var esito: Dictionary = ExerciseInteraction.validate(item)
			assert(bool(esito["ok"]), "%s: %s" % [subject, str(esito["errors"])])
			var difficulty := int(item.get("difficulty", 0))
			assert(difficulty >= 1 and difficulty <= ContentManager.DIFFICULTY_BANDS, "difficolta invalida: %s" % subject)

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

	print("C-04 audit OK — %d materie, item validati e ripasso spaziato adattivo" % SUBJECTS.size())
	quit(0)
