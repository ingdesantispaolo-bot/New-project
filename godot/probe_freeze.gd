extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var gp := OutdoorGameplay.new()
	gp.content_manager = ContentManager.new()
	gp.game_save = GameSaveManager.new("user://probe-freeze.json")
	var trovati := 0
	for giro in range(40):
		var subject := "matematica"
		var s: Dictionary = gp.content_manager.build_varied_mission(subject, 1, 3, {}, null, 0.2, {})
		s = gp._decorate_teaching_session(s, subject)
		var quante := 0
		for raw in Array(s.get("nodes", [])):
			if Dictionary(raw).has("teachingLesson"):
				quante += 1
		var player := ExercisePlayer.new()
		root.add_child(player)
		player.present(s)
		await process_frame
		# scorre tutti i nodi rispondendo "avanti"
		for i in range(Array(s.get("nodes", [])).size() + 1):
			player.call("_advance")
			await process_frame
		var overlay := player.get_node_or_null("TeachingOverlay")
		if overlay != null:
			trovati += 1
			print("GIRO %d: scheda modale RIMASTA dopo la fine (lezioni nella sessione: %d)" % [giro, quante])
		player.queue_free()
		await process_frame
	print("sessioni con scheda bloccante alla fine: %d su 40" % trovati)
	quit(0)
