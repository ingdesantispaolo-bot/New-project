extends SceneTree

const FLOW := preload("res://scripts/game/mission_ownership_flow.gd")
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_contract()
	_test_all_world_owners()
	_test_chained_owner_return()
	_test_tool_delivery_priority()
	await _test_world_fixture()
	print("Mission ownership audit OK — 23 mondi coerenti, ritorni concatenati e nessun referente incrociato")
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

## Ogni nome mostrato dalla bussola deve appartenere al mondo corrente e avere
## il ruolo che giustifica il rimando: specialista per le missioni, testimone
## per gli enigmi. Questo e' il controllo che impedisce a un futuro riordino del
## catalogo di far comparire, per esempio, "Parla con Tobia" fuori dalla Radura.
func _test_all_world_owners() -> void:
	for world in range(1, WorldProfileCatalog.MAX_LEVEL):
		var cast: Dictionary = NpcCatalog.for_world(world)
		var residents: Array = Array(cast.get("residents", []))
		var specialists := residents.filter(func(id):
			return str(NpcCatalog.resident(str(id)).get("funzione", "")) == "specialista")
		var witnesses := residents.filter(func(id):
			return str(NpcCatalog.resident(str(id)).get("funzione", "")) == "testimone")
		assert(specialists.size() == 1 and witnesses.size() == 1,
			"mondo %d: cast senza un referente univoco per missione ed enigma" % world)
		var specialist_id := str(specialists[0])
		var witness_id := str(witnesses[0])
		assert(NpcCatalog.owner_for(world, "mission") == specialist_id,
			"mondo %d: la missione rimanda a un personaggio di un altro ruolo/mondo" % world)
		assert(NpcCatalog.owner_for(world, "enigma") == witness_id,
			"mondo %d: l'enigma rimanda a un personaggio di un altro ruolo/mondo" % world)
		assert(int(NpcCatalog.resident(specialist_id).get("world", 0)) == world
			and int(NpcCatalog.resident(witness_id).get("world", 0)) == world,
			"mondo %d: referente non presente nel mondo corrente" % world)
		assert(not NpcCatalog.mission_lines(specialist_id, "richiesta").is_empty()
			and not NpcCatalog.mission_lines(witness_id, "richiesta").is_empty(),
			"mondo %d: la bussola rimanda a un personaggio che non puo' affidare l'incarico" % world)

		var flow = FLOW.new()
		flow.setup(world, [
			{"id": "mission-%d" % world, "kind": "mission"},
			{"id": "enigma-%d" % world, "kind": "enigma"},
		], [])
		var first: Dictionary = flow.navigation()
		assert(str(first.get("id", "")) == specialist_id and str(first.get("phase", "")) == "request",
			"mondo %d: la prima rotta non porta allo specialista locale" % world)
		flow.accept_request(specialist_id)
		flow.record_result("mission-%d" % world, true)
		assert(str(flow.navigation().get("id", "")) == specialist_id,
			"mondo %d: il ritorno non porta allo stesso proprietario" % world)
		flow.consume_return(specialist_id)
		assert(str(flow.navigation().get("id", "")) == witness_id,
			"mondo %d: dopo la missione la rotta non passa al testimone locale" % world)

## Due lavori consecutivi dello stesso personaggio non devono richiedere di
## chiudere il dialogo di consegna e riaprirlo immediatamente. Il runtime usa
## questa stessa sequenza: consuma il ritorno e affida il prossimo lavoro nella
## conversazione gia' aperta.
func _test_chained_owner_return() -> void:
	var flow = FLOW.new()
	flow.setup(1, [
		{"id": "first", "kind": "mission"},
		{"id": "second", "kind": "mission"},
	], [])
	assert(not flow.accept_request("w01-tobia").is_empty(), "prima richiesta non accettata")
	flow.record_result("first", true)
	assert(not flow.consume_return("w01-tobia").is_empty(), "ritorno da Tobia non consumato")
	var chained: Dictionary = flow.accept_request("w01-tobia")
	assert(str(chained.get("id", "")) == "second",
		"il secondo incarico non puo' essere concatenato al dialogo di ritorno")
	var route: Dictionary = flow.navigation()
	assert(str(route.get("kind", "")) == "event" and str(route.get("id", "")) == "second",
		"dopo il ritorno la bussola dice ancora PARLA CON TOBIA invece di indicare la missione")

func _test_tool_delivery_priority() -> void:
	var events := [
		{"id": "regular", "kind": "mission"},
		{"id": "tool-job", "kind": "minimission"},
		{"id": "later-mini", "kind": "minimission"},
	]
	var flow = FLOW.new()
	flow.setup(2, events, [], "tool-job")
	var owner := flow.owner_of("tool-job")
	var route: Dictionary = flow.navigation()
	assert(route.get("id") == "tool-job",
		"la bussola non privilegia l'incarico che consegna lo strumento")
	if owner != "":
		assert(route.get("eventId") == "tool-job",
			"la rotta verso il referente perde l'incarico strumento")
		assert(flow.assignment_for(owner).get("id") == "tool-job",
			"il referente assegna un altro lavoro prima dello strumento")
		assert(flow.accept_request(owner).get("id") == "tool-job",
			"l'incarico strumento non viene accettato")
		assert(flow.navigation().get("id") == "tool-job",
			"dopo il dialogo la bussola non punta all'incarico strumento")
	# Una volta chiusa la priorità, anche le minimissioni normali devono entrare
	# nella sequenza guidata invece di restare affidate all'esplorazione casuale.
	var remaining = FLOW.new()
	remaining.setup(2, [{"id": "only-mini", "kind": "minimission"}], [])
	assert(not remaining.navigation().is_empty(),
		"una minimissione senza strumento resta invisibile alla bussola")

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
