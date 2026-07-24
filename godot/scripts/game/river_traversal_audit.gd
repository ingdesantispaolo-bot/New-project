extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const GROUND := preload("res://scripts/chunk_ground.gd")

## C-P6 #2: corso coerente (sorgente→cascata), riva invalicabile e apertura
## persistente esclusivamente attraverso il ponte costruito dall'enigma.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 8
	initial["energy"] = 1000
	initial["worlds"] = {"unlocked": range(1, 9), "current": 8}
	var request := NativeWorldState.default_request("river-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 8
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	root.add_child(world)
	await process_frame
	await process_frame

	var composition: WorldCompositionData = world.get("chunks").composition
	assert(composition.crossings.size() == 1, "il profilo acquatico deve avere un varco principale")
	var crossing: Dictionary = composition.crossings[0]
	var event_id := str(crossing.get("eventId", ""))
	assert(event_id != "", "il varco non è legato a un enigma")
	var event: Dictionary = {}
	for candidate in world.get("mission_events"):
		if str(candidate.get("id", "")) == event_id:
			event = candidate
			break
	assert(str(event.get("kind", "")) == "enigma", "il ponte deve essere costruito da un enigma")
	assert(event.has("bridgeCenter") and event.has("crossingId"), "contratto ponte incompleto")
	var area := world.find_child("MissionEvent_%s" % event_id.replace("-", "_"), true, false) as Area2D
	var visual := area.get_node("EnigmaStructureVisual")
	assert(str(visual.get("theme")) == "ponte", "il varco acquatico deve rendere un ponte")

	var center: Vector2 = crossing["position"]
	var approach: Vector2 = crossing["approach"]
	assert(composition.raw_water_weight(center) > 0.8, "il ponte non attraversa il corso d'acqua")
	assert(bool(world.call("_water_blocks_position", center)), "il fiume è attraversabile prima della costruzione")
	assert(not bool(world.call("_water_blocks_position", approach)), "l'attivazione dell'enigma non è raggiungibile dalla riva")
	Array(world.get("result")["completedEncounterIds"]).append(event_id)
	assert(not bool(world.call("_water_blocks_position", center)), "il ponte completato non apre il varco")

	# Le estremità hanno una grammatica leggibile, non un nastro tagliato.
	var stream: Dictionary = {}
	for water_data in composition.waters:
		if str(water_data.get("id", "")) == str(crossing.get("waterId", "")):
			stream = water_data
			break
	var points: PackedVector2Array = stream.get("points", PackedVector2Array())
	assert(points.size() >= 2, "corso del varco assente")
	var source_ground := _ground_for(points[0], composition)
	var falls_ground := _ground_for(points[points.size() - 1], composition)
	assert(source_ground.find_child("StreamSource_*", true, false) != null, "sorgente non resa")
	assert(falls_ground.find_child("StreamWaterfall_*", true, false) != null, "cascata terminale non resa")

	world.queue_free()
	source_ground.queue_free()
	falls_ground.queue_free()
	await process_frame
	print("RIVER TRAVERSAL audit OK — sorgente/cascata, riva bloccata e ponte-enigma persistente")
	quit(0)

func _ground_for(world_point: Vector2, composition: WorldCompositionData) -> Node2D:
	var cx := floori(world_point.x / 896.0)
	var cy := floori(world_point.y / 896.0)
	var ground := GROUND.new()
	root.add_child(ground)
	ground.setup({
		"id": "river-audit-%d-%d" % [cx, cy],
		"worldX": cx * 896,
		"worldY": cy * 896,
		"chunkX": cx,
		"chunkY": cy,
		"size": 896,
		"biome": "geo",
		"patch": {"color": 0x173b36, "accent": 0x6be7d6},
		"pathPoints": [],
		"obstacles": [],
		"props": [],
		"landmarks": [],
		"treasures": [],
		"encounters": [],
	}, 2, composition)
	return ground
