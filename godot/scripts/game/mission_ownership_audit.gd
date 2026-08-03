extends SceneTree

const FLOW := preload("res://scripts/game/mission_ownership_flow.gd")
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_contract()
	await _test_world_fixture()
	print("Mission ownership audit OK — richiesta, bussola, prova e ritorno senza toccare il gate")
	quit(0)

func _test_contract() -> void:
	var events := [
		{"id": "mission", "kind": "mission"},
		{"id": "enigma", "kind": "enigma"},
		{"id": "practice", "kind": "practice"},
	]
	var flow = FLOW.new()
	flow.setup(1, events, [])
	assert(flow.owner_of("mission") == "w01-tobia", "missione non assegnata allo specialista")
	assert(flow.owner_of("enigma") == "w01-ersilia", "enigma non assegnato alla testimone")
	assert(flow.owner_of("practice") == "", "la pratica non deve avere proprietario")
	assert(not flow.can_start("mission") and flow.can_start("practice"),
		"degradazione senza proprietario o gate richiesta errati")
	var first_route: Dictionary = flow.navigation()
	assert(first_route.get("id") == "w01-tobia" and first_route.get("phase") == "request",
		"la bussola non presenta prima la missione di Tobia")
	assert(not flow.accept_request("w01-tobia").is_empty(), "richiesta di Tobia non accettata")
	assert(flow.can_start("mission"), "missione ancora bloccata dopo la richiesta")
	assert(flow.navigation().get("id") == "mission", "bussola non passata alla prova")
	flow.record_result("mission", false)
	assert(flow.navigation().get("id") == "w01-tobia" and flow.navigation().get("phase") == "return",
		"fallimento non rimanda al proprietario")
	var consolation := NpcCatalog.mission_lines("w01-tobia", "consolazione")
	assert(not consolation.is_empty(), "fixture di consolazione assente")
	for dialogue in consolation:
		var joined := " ".join(PackedStringArray(dialogue)).to_lower()
		assert(not joined.contains("delus") and not joined.contains("peccato"),
			"consolazione colpevolizzante: %s" % joined)
	flow.consume_return("w01-tobia")
	assert(flow.navigation().get("id") == "mission", "dopo la consolazione non propone il retry")

	var fallback = FLOW.new()
	fallback.setup(24, [{"id": "free", "kind": "mission"}], [])
	assert(fallback.owner_of("free") == "" and fallback.can_start("free"),
		"mondo senza cast non degrada al flusso diretto")

func _test_world_fixture() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("mission-ownership-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var mission: Area2D = null
	for node in get_nodes_in_group("mission_poi"):
		if node is Area2D and str(Dictionary(node.get_meta("payload", {})).get("directorKind", "")) == "mission":
			mission = node as Area2D
			break
	assert(mission != null, "fixture missione del mondo 1 assente")
	var payload: Dictionary = mission.get_meta("payload", {})
	assert(payload.get("ownerNpc") == "w01-tobia", "ownerNpc non montato sul POI reale")
	var player := world.get("player") as OutdoorPlayerController
	var tobia: Area2D = world.call("_npc_actor_by_id", "w01-tobia")
	assert(tobia != null, "Tobia non istanziato")
	player.global_position = mission.global_position + Vector2(40, 0)
	world.call("on_interactable_entered", mission, player)
	world.call("_interact")
	assert(not (world.get("exercise_player") as ExercisePlayer).visible,
		"missione partita prima della richiesta")
	assert(player.touch_target.distance_to(tobia.global_position) < 1.0,
		"bussola non punta a Tobia")

	world.call("_open_npc_dialogue", "w01-tobia")
	var box := world.get("dialogue_box") as Control
	assert(box.visible, "richiesta di Tobia non mostrata")
	assert(Array(box.get("screens")) == Array(NpcCatalog.mission_lines("w01-tobia", "richiesta")[0]),
		"dialogo reale non usa il pool richiesta")
	box.call("close_dialogue")
	await process_frame
	assert(bool(world.get("mission_ownership_flow").can_start(str(mission.get_meta("id", "")))),
		"POI non sbloccato dopo il dialogo")

	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame
