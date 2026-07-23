extends SceneTree

## Gate integrato C-P4: UI del Manuale, stato separato, aiuto dopo errore,
## protezione dell'esame e ritorno alla stessa sessione.

const PANEL := preload("res://scripts/ui/knowledge_codex_panel.gd")
const PLAYER := preload("res://scripts/game/exercise_player.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("C-P4 UI audit: setup")
	var save := GameSaveManager.new()
	var mastery_before: Dictionary = Dictionary(save.data.get("mastery", {})).duplicate(true)
	var panel := PANEL.new()
	root.add_child(panel)
	panel.setup(save, ContentManager.new())
	panel.mark_encountered("matematica", ["tabelline"])
	panel.open_codex("matematica", "tabelline", "mission")
	await process_frame
	print("C-P4 UI audit: panel aperto")
	assert(panel.visible, "il Manuale deve aprirsi")
	assert(panel.find_child("CodexSearch", true, false) != null, "ricerca assente")
	assert(panel.find_child("CodexSubjectFilter", true, false) != null, "filtro materia assente")
	assert(panel.find_child("CodexFavoritesFilter", true, false) != null, "filtro preferiti assente")
	assert(panel.find_child("CodexDemoStep", true, false) != null, "dimostrazione guidata assente")
	assert(panel.find_child("CodexRelated", true, false) != null, "collegamenti correlati assenti")
	assert(save.data.get("mastery", {}) == mastery_before, "consultare il Manuale non deve cambiare mastery")

	var player := PLAYER.new()
	root.add_child(player)
	var session := {
		"sessionId": "codex-return",
		"kind": "mission",
		"subject": "matematica",
		"nodes": [{
			"format": "multiple_choice",
			"topic": "tabelline",
			"prompt": "Quanto fa 2 × 3?",
			"options": ["5", "6", "7"],
			"answer": "6",
			"explanation": "Due gruppi da tre fanno sei.",
		}],
		"shields": 3,
		"rewards": {"energyPerCorrect": 10, "onComplete": {}},
	}
	player.start_session(session)
	player._answer("5")
	print("C-P4 UI audit: errore riprodotto")
	var help := player.get("_help_button") as Button
	assert(help != null and help.visible, "dopo un errore deve apparire Spiega con NORA")
	var requested := {"subject": "", "topic": ""}
	player.concept_help_requested.connect(func(subject, topic):
		requested["subject"] = subject
		requested["topic"] = topic
	)
	var cursor_before := player.session_cursor()
	help.pressed.emit()
	assert(requested == {"subject": "matematica", "topic": "tabelline"}, "richiesta aiuto non contestuale")
	panel.open_codex(str(requested["subject"]), str(requested["topic"]), "mission")
	panel.close_panel()
	assert(player.session_cursor() == cursor_before, "aprire/chiudere il Manuale ha alterato la sessione")
	print("C-P4 UI audit: ritorno verificato")

	session["kind"] = "final_exam"
	session["sessionId"] = "codex-exam"
	player.start_session(session)
	player._answer("5")
	help = player.get("_help_button") as Button
	assert(help != null and not help.visible, "in esame l'aiuto contestuale deve restare nascosto")
	panel.open_codex("matematica", "tabelline", "final_exam")
	print("C-P4 UI audit: esame protetto")
	var exam_entry := panel.codex.entry_for_context("matematica", "tabelline", "final_exam")
	assert(bool(exam_entry.get("answerHidden", false)), "l'esame non deve rivelare la risposta")

	panel.free()
	player.free()
	await process_frame
	print("Knowledge Codex UI audit OK — ricerca/filtri/preferiti/demo, errore→aiuto→ritorno e protezione esame")
	quit(0)
