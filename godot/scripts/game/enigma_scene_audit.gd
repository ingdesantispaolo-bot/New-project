extends SceneTree

## Regressione reale della scena: il player entra nel raggio di ciascun POI,
## il prompt compare e l'azione `interact` apre davvero ExercisePlayer.

func _init() -> void:
	var packed := load("res://scenes/outdoor_world.tscn") as PackedScene
	assert(packed != null, "scena outdoor assente")
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var player: CharacterBody2D = scene.get("player")
	var exercise: Control = scene.get("exercise_player")
	var gameplay: OutdoorGameplay = scene.get("gameplay")
	assert(player != null and exercise != null and gameplay != null, "servizi scena mancanti")
	# Un profilo nuovo parte senza energia: tutti i POI devono comunque poter
	# aprire una sessione di recupero, altrimenti il loop resta irraggiungibile.
	gameplay.game_save.data["energy"] = 0
	var tested := 0
	for node in get_nodes_in_group("enigma_poi"):
		if not (node is Area2D):
			continue
		var area := node as Area2D
		# Le prove successive devono partire senza sessione attiva.
		if gameplay.session_active():
			gameplay.active_session_context = {}
		exercise.visible = false
		player.global_position = area.global_position
		for frame in range(3):
			await physics_frame
		var nearby: Array = scene.get("nearby")
		assert(nearby.has(area), "POI %s non rileva il player" % str(area.get_meta("id", "")))
		# Evento reale nel pipeline Viewport: individua regressioni in cui un
		# Control dell'HUD assorbe E prima che la scena possa gestirlo.
		var press := InputEventKey.new()
		press.physical_keycode = KEY_E
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventKey.new()
		release.physical_keycode = KEY_E
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
		assert(exercise.visible, "E non apre ExercisePlayer per %s" % str(area.get_meta("id", "")))
		assert(gameplay.session_active(), "sessione enigma non avviata per %s" % str(area.get_meta("id", "")))
		tested += 1
	assert(tested == 12, "devono essere provati tutti i 12 enigmi")
	print("ENIGMA SCENE audit OK - Area2D, prompt, E e sessione su 12 POI")
	quit(0)
