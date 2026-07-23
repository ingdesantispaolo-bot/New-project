extends SceneTree

## Gate integrato C-P1/G1-G2: la stessa outdoor_world.tscn consuma due profili,
## mantiene stato/posizione separati, rispetta nave e percorso sicuro e usa
## esclusivamente gli eventi del MissionEventDirector.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request_for(current_world: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["worlds"] = {"unlocked": [1, 2], "current": current_world}
	initial["worldProgress"] = {
		"1": {
			"completedEncounterIds": ["evt-1-gate-0"],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"resume": {"playerX": 520.0, "playerY": 1400.0, "dayClock": 22.0},
		},
		"2": {
			"completedEncounterIds": [],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"resume": {},
		},
	}
	var request := NativeWorldState.default_request("profile-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _instantiate_world(current_world: int) -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(current_world))
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _assert_world(world: Node, expected_level: int) -> Dictionary:
	var profile: Dictionary = world.get("world_profile")
	assert(int(profile.get("level", 0)) == expected_level, "profilo errato: atteso mondo %d" % expected_level)
	var title := world.find_child("WorldProfileTitle", true, false) as Label
	assert(title != null and str(profile.get("title", "")).to_upper() in title.text,
		"HUD non configurato dal WorldProfile %d" % expected_level)
	var portal := world.find_child("ExitPortal", true, false) as Node2D
	assert(portal != null and portal.global_position.distance_to(profile["shipEntrance"]["position"]) < 0.01,
		"ingresso nave non mappato sulle coordinate del profilo")
	var events: Array = world.get("mission_events")
	var subject := str(profile["learningFocus"]["subject"])
	var required := int(ApparatusConfig.level_gate(expected_level).get("missionsRequired", 5))
	assert(MissionEventDirector.reachable_gate_events(events, subject) >= required,
		"eventi focus insufficienti nella scena del mondo %d" % expected_level)
	var practices := 0
	for event in events:
		var position: Vector2 = event["position"]
		assert(position.distance_to(profile["shipEntrance"]["position"]) >= float(profile["shipEntrance"]["safeRadius"]),
			"evento %s dentro la zona nave" % str(event["id"]))
		if str(event["kind"]) == "practice":
			practices += 1
	assert(practices > 0, "il mondo deve contenere pratica distribuita dal Director")
	assert(world.find_child("Palestra*", true, false) == null,
		"le Palestre fisse legacy non devono essere istanziate")
	var first_gate_id := "evt-%d-gate-0" % expected_level
	var first_gate := world.find_child("MissionEvent_%s" % first_gate_id.replace("-", "_"), true, false)
	assert(first_gate != null and first_gate.get_node_or_null("LearningReaction") != null,
		"la missione deve avere una trasformazione ambientale")
	var expected_complete := Array(world.get("result").get("completedEncounterIds", [])).has(first_gate_id)
	assert(bool(first_gate.get_node("LearningReaction").get("completed")) == expected_complete,
		"la trasformazione ambientale non riflette lo stato persistente")
	var reactive_event: Dictionary = {}
	for event in events:
		if bool(event.get("countsForGate", false)) and not Array(world.get("result").get("completedEncounterIds", [])).has(str(event.get("id", ""))):
			reactive_event = event
			break
	assert(not reactive_event.is_empty(), "manca un evento disponibile per provare la reazione ambientale")
	var reactive_node := world.find_child(
		"MissionEvent_%s" % str(reactive_event["id"]).replace("-", "_"), true, false)
	var reactive_visual := reactive_node.get_node("LearningReaction")
	world.get("gameplay").active_session_context = {
		"kind": str(reactive_event["kind"]),
		"encounterId": str(reactive_event["id"]),
		"subject": subject,
	}
	world.call("_on_exercise_progress", 1, 3)
	var lit_parts := 0
	for part in reactive_visual.get("active_parts"):
		if part.visible:
			lit_parts += 1
	assert(lit_parts > 0 and lit_parts < Array(reactive_visual.get("active_parts")).size(),
		"una risposta corretta deve trasformare gradualmente l'ambiente del POI")
	world.get("gameplay").active_session_context = {}

	var chunks: OutdoorChunkManager = world.get("chunks")
	assert(not chunks.composition.identity_regions.is_empty(),
		"il profilo %d non ha regioni visuali identitarie" % expected_level)
	var has_ground := false
	for entry in chunks.loaded.values():
		var data: Dictionary = entry["data"]
		var chunk_node: Node = entry["node"]
		if chunk_node.find_child("WorldSpaceUnderpainting", true, false) != null:
			has_ground = true
		assert(Array(data.get("encounters", [])).is_empty(),
			"gli incontri legacy non devono affiancare il MissionEventDirector")
		for obstacle in data.get("obstacles", []):
			var pos := Vector2(float(obstacle["x"]), float(obstacle["y"]))
			assert(not chunks.composition.is_protected(pos, float(obstacle.get("r", 0.0))),
				"ostacolo dentro nave/percorso sicuro nel mondo %d" % expected_level)
	assert(has_ground, "il terreno del profilo non è stato compilato/istanziato")
	return {
		"id": str(profile["id"]),
		"title": str(profile["title"]),
		"terrain": str(profile["terrainFamily"]),
		"seed": str(world.get("world_seed")),
		"spawnBiome": chunks.composition.dominant_biome(profile["spawn"]),
		"visualTheme": chunks.composition.visual_theme,
		"identityRegionCount": chunks.composition.identity_regions.size(),
		"identityPropCount": chunks.composition.identity_props.size(),
		"result": Dictionary(world.get("result")).duplicate(true),
		"playerPosition": (world.get("player") as CharacterBody2D).global_position,
		"spawn": profile["spawn"],
	}

func _dispose_world(world: Node) -> void:
	if is_instance_valid(world):
		root.remove_child(world)
		world.queue_free()
	current_scene = null
	await process_frame

func _run() -> void:
	var world_one := await _instantiate_world(1)
	var first := _assert_world(world_one, 1)
	assert((first["playerPosition"] as Vector2).distance_to(Vector2(520, 1400)) < 0.01,
		"la posizione persistente del mondo 1 non è stata ripristinata")
	assert(Array(first["result"]["completedEncounterIds"]).has("evt-1-gate-0"),
		"lo stato persistente del mondo 1 non è stato idratato")
	await _dispose_world(world_one)

	var world_two := await _instantiate_world(2)
	var second := _assert_world(world_two, 2)
	assert((second["playerPosition"] as Vector2).distance_to(second["spawn"]) < 0.01,
		"un mondo nuovo deve usare lo spawn autorato")
	assert(not Array(second["result"]["completedEncounterIds"]).has("evt-1-gate-0"),
		"stato del mondo 1 contaminato nel mondo 2")
	assert(first["id"] != second["id"] and first["title"] != second["title"] and first["terrain"] != second["terrain"],
		"i due profili devono mantenere identità distinte")
	assert(first["seed"] != second["seed"], "ogni profilo deve derivare un seed distinto")
	assert(first["spawnBiome"] != second["spawnBiome"], "la composizione visuale deve cambiare tra i primi due profili")
	assert(first["visualTheme"] == "radura" and second["visualTheme"] == "archive",
		"Radura e Archivio devono usare kit visuali distinti")
	assert(int(first["identityRegionCount"]) != int(second["identityRegionCount"])
		or int(first["identityPropCount"]) != int(second["identityPropCount"]),
		"topologia e scenografia dei primi due mondi non devono coincidere")
	await _dispose_world(world_two)

	# Viaggio reale dalla mappa della nave: il save lasciato dal mondo 2 ha
	# entrambi i mondi sbloccati; scegliendo il mondo 1 devono tornare profilo,
	# stato e posizione propri di quella destinazione.
	var hub := (load("res://scenes/hub.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame
	var map_button := hub.find_child("WorldMapButton", true, false) as Button
	map_button.pressed.emit()
	var first_button := hub.find_child("WorldTravel_01", true, false) as Button
	var second_button := hub.find_child("WorldTravel_02", true, false) as Button
	assert("COMPLETATO" in first_button.text and "CORRENTE" in second_button.text,
		"la mappa deve distinguere mondo completato/rivisitabile e corrente")
	first_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == WORLD_SCENE,
		"la selezione dalla mappa deve aprire la WorldScene unica")
	assert(int(current_scene.get("world_profile").get("level", 0)) == 1,
		"la mappa non ha caricato il profilo selezionato")
	assert((current_scene.get("player") as CharacterBody2D).global_position.distance_to(Vector2(520, 1400)) < 0.01,
		"il viaggio non ha ripristinato la posizione del mondo 1")

	print("WORLD SCENE PROFILE audit OK — due profili, Director, nave sicura, mappa e stato/posizione separati")
	quit(0)
