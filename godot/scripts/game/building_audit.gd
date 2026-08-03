extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for level in range(1, 25):
		var profile := WorldProfileCatalog.profile(level)
		var specs := BuildingCatalog.for_world(level, profile)
		assert(specs.size() == 3, "mondo %d senza tre edifici" % level)
		var roles: Array = specs.map(func(spec): return str(spec.get("role", "")))
		for role in BuildingCatalog.ROLES:
			assert(roles.has(role), "mondo %d senza ruolo %s" % [level, role])
		for spec in specs:
			assert(str(spec.get("artKit", "")) == str(profile.get("artKit", "")),
				"edificio non vestito per artKit nel mondo %d" % level)
	await _test_world_one()
	print("Building audit OK — 3 ruoli × 24 mondi, finestre a stadio e Rovina allineata")
	quit(0)

func _test_world_one() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("building-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var buildings: Array = world.get("world_buildings")
	assert(buildings.size() == 3, "fixture mondo 1 senza tre edifici reali")
	var ruin: Node2D = null
	var composition = world.get("chunks").composition
	for building in buildings:
		var actor := building as Node2D
		var role := str(actor.get_meta("building_role", ""))
		assert(actor.get_node_or_null("BuildingLabel") != null, "edificio senza etichetta accessibile")
		if role == "first_ruin":
			ruin = actor
		else:
			assert(composition.raw_water_weight(actor.global_position) < 0.24,
				"edificio %s in acqua" % role)
			assert(not composition.is_protected(actor.global_position, 80.0),
				"edificio %s su area protetta" % role)
		for glow in Array(actor.get("window_glows")):
			assert(not (glow as CanvasItem).visible, "finestra accesa allo stadio 0")
	assert(ruin != null and ruin.global_position.distance_to(world.call("_hero_landmark_position")) < 0.1,
		"Rovina non allineata al landmark eroe")
	var ritrovo: Vector2 = world.call("ritrovo_position")
	assert(ritrovo.distance_to(world.get("world_profile").get("spawn", Vector2.ZERO)) > 100.0,
		"Ritrovo privo di ancoraggio distinto")

	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame
