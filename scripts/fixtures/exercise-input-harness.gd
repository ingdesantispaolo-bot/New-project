extends Node

# Scena temporanea per test-exercise-touch-web.mjs. Non entra nella release.

var exercise: ExercisePlayer
var world: Node
var results: Array = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var request := NativeWorldState.default_request("exercise-input-web")
	request["loadLocalSave"] = false
	var save := GameSaveManager.new("user://exercise-input-web.json")
	save.data = GameSaveManager._default_data()
	save.claim_world_intro(1)
	request["initialSave"] = save.data
	world = load("res://scenes/outdoor_world.tscn").instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	add_child(world)
	await get_tree().process_frame
	exercise = world.get("exercise_player")
	exercise.session_finished.connect(func(result): results.append(result))
	var item := {"id": "input-web", "topic": "tabelline", "format": "numeric_input", "prompt": "Quale numero completa 3 × ? = 18?", "answer": "6", "explanation": "Dividi 18 per 3: il fattore mancante è 6."}
	world.get("gameplay").active_session_context = {"kind": "enigma", "subject": "matematica", "encounterId": "input-web", "theme": "ponte"}
	world.call("_on_gameplay_session_requested", {"sessionId": "input-web", "kind": "enigma", "subject": "matematica", "nodes": [item, item, item], "shields": 3, "rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 35}}})
	while is_instance_valid(exercise):
		var state := exercise.session_cursor()
		state["visible"] = exercise.visible
		var buttons := {}
		for name in ["Numpad_6", "TextAnswerSubmit", "ExerciseNextButton"]:
			var button := exercise.find_child(name, true, false) as Button
			var rect := button.get_global_rect()
			buttons[name] = {"x": rect.get_center().x, "y": rect.get_center().y, "height": rect.size.y, "visible": button.is_visible_in_tree(), "disabled": button.disabled}
		state["buttons"] = buttons
		state["results"] = results
		state["viewport"] = [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__exerciseInputTest = %s" % JSON.stringify(state))
		await get_tree().create_timer(0.1).timeout
