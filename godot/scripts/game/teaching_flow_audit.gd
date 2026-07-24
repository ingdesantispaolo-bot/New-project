extends SceneTree

const GAMEPLAY := preload("res://scripts/game/outdoor_gameplay.gd")
const PLAYER := preload("res://scripts/game/exercise_player.gd")

## C-P6 #13: prova il collegamento end-to-end fra contenuto didattico e UI live.
## Uso:
## godot --headless --path godot --script res://scripts/game/teaching_flow_audit.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var gameplay := GAMEPLAY.new()
	root.add_child(gameplay)
	gameplay.setup({}, {
		"completedEncounterIds": [],
		"collectedTreasureIds": [],
		"energySpent": 0,
	}, false)

	var captured: Dictionary = {}
	gameplay.session_requested.connect(func(session: Dictionary):
		captured.assign(session)
	)
	assert(gameplay.try_start_mission({"subject": "matematica"}, "audit-teaching"), "la missione live deve partire")
	assert(str(captured.get("teachingMoment", "")) == "pre_teach", "il primo concetto deve essere pre-insegnato")
	assert(not Dictionary(captured.get("teachingLesson", {})).is_empty(), "mini-lezione non consegnata al renderer")
	assert(str(captured.get("teachingLine", "")).strip_edges() != "", "NORA non introduce la lezione")

	var player := PLAYER.new()
	root.add_child(player)
	player.start_session(captured)
	await process_frame
	var overlay := player.find_child("TeachingOverlay", true, false) as Control
	var begin := player.find_child("TeachingStartButton", true, false) as Button
	assert(overlay != null and overlay.visible, "la lezione deve coprire la domanda")
	assert(overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "la domanda sotto la lezione deve essere non interagibile")
	assert(begin != null and begin.custom_minimum_size.y >= 48.0, "CTA touch della lezione insufficiente")
	begin.pressed.emit()
	await process_frame
	assert(player.find_child("TeachingOverlay", true, false) == null, "la prova deve aprirsi dopo conferma")

	# Un errore già dovuto trasforma la stessa pipeline in ripasso mirato.
	var subject := str(captured.get("subject", "matematica"))
	var topic := str(captured.get("teachingTopic", ""))
	var key := "%s:%s" % [subject, topic]
	gameplay.game_save.data["spacedRepetition"] = {
		"sessionClock": 4,
		"schedule": {key: {"lapses": 1, "dueAt": 4}},
	}
	var retry := gameplay._decorate_teaching_session({
		"subject": subject,
		"nodes": [{"topic": topic, "prompt": "audit"}],
	}, subject)
	assert(str(retry.get("teachingMoment", "")) == "re_teach", "un errore dovuto deve attivare il ri-insegnamento")

	player.free()
	gameplay.free()
	await process_frame
	print("TEACHING FLOW audit OK — pre-lezione touch prima della prova e ripasso mirato live")
	quit(0)
