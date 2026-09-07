extends Node

# Scena temporanea per test-exercise-touch-web.mjs. Non entra nella release.

const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")

var exercise: ExercisePlayer
var world: Node
var results: Array = []
var phase := "numeric"
var numeric_finished_at := -1
var torch_solved_index := -1

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
	exercise.session_finished.connect(func(result):
		results.append(result)
		if results.size() == 1:
			phase = "numeric_done"
			numeric_finished_at = Time.get_ticks_msec())
	var item := {"id": "input-web", "topic": "tabelline", "format": "numeric_input", "prompt": "Quale numero completa 3 × ? = 18?", "answer": "6", "explanation": "Dividi 18 per 3: il fattore mancante è 6."}
	world.get("gameplay").active_session_context = {"kind": "enigma", "subject": "matematica", "encounterId": "input-web", "theme": "ponte"}
	world.call("_on_gameplay_session_requested", {"sessionId": "input-web", "kind": "enigma", "subject": "matematica", "nodes": [item, item, item], "shields": 3, "rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 35}}})
	while is_instance_valid(exercise):
		if phase == "numeric_done" and Time.get_ticks_msec() - numeric_finished_at >= 1500:
			_start_torch_minimission()
		if phase == "torch" and exercise.visible and not exercise._answered \
				and exercise._index >= 0 and exercise._index < exercise._nodes.size() \
				and torch_solved_index != exercise._index:
			# La scena reale può presentare la mini-lezione prima della domanda. Nel
			# test la chiudiamo prima di rispondere, come fa il giocatore; risolvere
			# dietro l'overlay renderebbe AVANTI visibile nei dati ma non toccabile.
			var overlay := exercise.find_child("TeachingOverlay", true, false)
			if overlay != null:
				overlay.queue_free()
			else:
				torch_solved_index = exercise._index
				Autoplay.solve(exercise, exercise._nodes[exercise._index], true)
		var state := exercise.session_cursor()
		state["phase"] = phase
		state["visible"] = exercise.visible
		var buttons := {}
		for name in ["Numpad_6", "TextAnswerSubmit", "ExerciseNextButton"]:
			var button := exercise.find_child(name, true, false) as Button
			var rect := button.get_global_rect()
			buttons[name] = {"x": rect.get_center().x, "y": rect.get_center().y, "height": rect.size.y, "visible": button.is_visible_in_tree(), "disabled": button.disabled}
		state["buttons"] = buttons
		state["results"] = results
		state["torchOwned"] = world.get("gameplay").reward_manager.owned(FieldTools.TORCIA)
		state["torchMissionCompleted"] = world.get("gameplay").game_save.has_minimission(1)
		var hovered := get_viewport().gui_get_hovered_control()
		state["hovered"] = str(hovered.get_path()) if hovered != null else ""
		state["viewport"] = [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__exerciseInputTest = %s" % JSON.stringify(state))
		await get_tree().create_timer(0.1).timeout

func _start_torch_minimission() -> void:
	phase = "torch_starting"
	var poi: Area2D = null
	for node in get_tree().get_nodes_in_group("enigma_poi"):
		if node is Area2D and world.is_ancestor_of(node) \
				and str(node.get_meta("kind", "")) == "minimission":
			poi = node
			break
	if poi == null:
		phase = "torch_missing"
		return
	var started: bool = world.get("gameplay").try_start_minimission(
		poi.get_meta("payload", {}), str(poi.get_meta("id", "")))
	phase = "torch" if started else "torch_failed"
