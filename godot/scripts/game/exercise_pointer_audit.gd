extends SceneTree

# Exercise the actual GUI hit testing instead of calling _advance directly.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _click(viewport: Viewport, button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	var hovered := viewport.gui_get_hovered_control()
	print("CLICK ", button.name, " rect=", button.get_global_rect(), " hit=", hovered.get_path() if hovered else "none")
	if hovered != button:
		failures.append("%s intercepted by %s" % [button.name, hovered.get_path() if hovered else "none"])
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event, true)
		await process_frame

func _run() -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(1280, 2240)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		viewport.handle_input_locally = true
		viewport.notify_mouse_entered()
		var request := NativeWorldState.default_request("exercise-pointer-audit")
		request["loadLocalSave"] = false
		var save := GameSaveManager._default_data()
		var initial := GameSaveManager.new("user://exercise-pointer.json")
		initial.data = save
		initial.claim_world_intro(1)
		request["initialSave"] = initial.data
		var world: Node = load("res://scenes/outdoor_world.tscn").instantiate()
		world.set("launch_request_override", request)
		world.set("launch_stream_radius_override", 0)
		viewport.add_child(world)
		await process_frame
		await process_frame
		var player: ExercisePlayer = world.get("exercise_player")
		var results: Array = []
		player.session_finished.connect(func(result): results.append(result))
		var item := {"id": "pointer", "topic": "tabelline", "format": "numeric_input", "prompt": "Quale numero completa 3 × ? = 18?", "answer": "6", "explanation": "Dividi 18 per 3: il fattore mancante è 6."}
		world.get("gameplay").active_session_context = {"kind": "enigma", "subject": "matematica", "encounterId": "pointer", "theme": "ponte"}
		world.call("_on_gameplay_session_requested", {"sessionId": "pointer", "kind": "enigma", "subject": "matematica", "nodes": [item, item, item], "shields": 3, "rewards": {"energyPerCorrect": 10}})
		for index in range(3):
			for frame in range(5):
				await process_frame
			player.get("_input").text = "6"
			await _click(viewport, player.find_child("TextAnswerSubmit", true, false))
			await create_timer(0.6).timeout
			await _click(viewport, player.find_child("ExerciseNextButton", true, false))
			if int(player.session_cursor()["index"]) != index + 1:
				failures.append("%s node %d did not advance: %s" % [dimensions, index, player.session_cursor()])
		if results.size() != 1:
			failures.append("%s delivered %d results" % [dimensions, results.size()])
		if player.visible or not world.get("player").is_physics_processing():
			failures.append("%s did not return control to the world" % dimensions)
		viewport.queue_free()
		await process_frame
	for failure in failures:
		printerr(failure)
	print("EXERCISE POINTER ", "VERDE" if failures.is_empty() else "ROSSO")
	quit(0 if failures.is_empty() else 1)
