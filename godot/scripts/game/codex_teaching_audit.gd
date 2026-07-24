extends SceneTree

const KnowledgeCodex = preload("res://scripts/game/knowledge_codex.gd")
const SpacedRepetition = preload("res://scripts/game/spaced_repetition.gd")

## Audit del layer d'INSEGNAMENTO del Manuale (playthrough #13: gli esercizi non
## devono solo interrogare — atlante e NORA insegnano). Verifica che ogni topic
## abbia una mini-lezione istruttiva e che i momenti d'insegnamento di NORA
## (pre-insegna / ri-insegna) scattino correttamente.
## Uso: godot --headless --path godot --script res://scripts/game/codex_teaching_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	var codex := KnowledgeCodex.new(content)

	# 1) Copertura: ogni argomento del runtime ha una mini-lezione completa.
	var topics := codex.runtime_topics()
	var count := 0
	for key in topics.keys():
		var meta: Dictionary = topics[key]
		var lesson := codex.mini_lesson(str(meta["subject"]), str(meta["topic"]))
		assert(str(lesson.get("intro", "")).strip_edges() != "", "intro mancante: %s" % key)
		assert(str(lesson.get("explanation", "")).strip_edges() != "", "spiegazione mancante: %s" % key)
		assert(str(lesson.get("strategy", "")).strip_edges() != "", "strategia mancante: %s" % key)
		assert(lesson.has("workedExample") and lesson.has("watchOut"), "lezione incompleta: %s" % key)
		count += 1
	assert(count >= 100, "l'insegnamento deve coprire i topic del runtime, trovati %d" % count)

	# 2) Pre-insegnamento al primo incontro assoluto.
	var save := GameSaveManager.new()
	assert(KnowledgeCodex.teaching_moment(save, "matematica", "tabelline") == "pre_teach", "primo incontro → pre_teach")
	# Applicato con successo → nessun insegnamento forzato (atlante resta consultabile).
	KnowledgeCodex.advance_state(save, "matematica", "tabelline", "correct")
	assert(KnowledgeCodex.teaching_moment(save, "matematica", "tabelline") == "none", "applicato → none")

	# 3) Ri-insegnamento sull'errore ricorrente (sbagliato e di nuovo dovuto).
	SpacedRepetition.apply_outcome(save, "italiano", ["scuola-studio"], [])  # miss → lapse
	SpacedRepetition.tick(save)                                              # ora è dovuto
	assert(KnowledgeCodex.teaching_moment(save, "italiano", "scuola-studio") == "re_teach", "errore ricorrente → re_teach")

	# 4) NORA ha una frase per ogni momento d'insegnamento.
	assert(KnowledgeCodex.teach_line("pre_teach") != "" and KnowledgeCodex.teach_line("re_teach") != "", "frasi d'insegnamento mancanti")
	assert(KnowledgeCodex.teach_line("none") == "", "nessuna frase quando non si insegna")

	print("Codex teaching audit OK — %d mini-lezioni; NORA pre-insegna al primo incontro e ri-insegna sull'errore" % count)
	quit(0)
