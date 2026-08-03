extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _request_for(world_level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = world_level
	initial["worlds"] = {"unlocked": range(1, world_level + 1), "current": world_level}
	var request := NativeWorldState.default_request("mystery-runtime-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = world_level
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	return request

func _run() -> void:
	root.size = Vector2i(900, 600)
	var world = WORLD_SCENE.instantiate()
	world.set("launch_request_override", _request_for(12))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var artifacts := get_nodes_in_group("mystery_artifact")
	var expected_seeds := 0
	for raw_seed in MysteryCatalog.SEMI:
		if int((raw_seed as Dictionary).get("world", 0)) == 12:
			expected_seeds += 1
	assert(artifacts.size() == expected_seeds + 1,
		"Rovina 12 non contiene una Traccia e tutti i suoi semi")
	var ruin: Node2D = null
	for building in world.get("world_buildings"):
		if str(building.get_meta("building_role", "")) == "first_ruin":
			ruin = building
	assert(ruin != null, "Rovina dei Primi assente")
	for artifact in artifacts:
		assert(artifact.get_parent() == ruin, "Traccia o seme fuori dalla Rovina")
		assert(artifact.position.length() <= 150.0, "Traccia o seme troppo lontano dalla Rovina")

	assert(world.call("_show_decisive_fallback_if_needed"),
		"beat di ripiego decisivo non mostrato quando la Traccia e' saltata")
	assert(not world.call("_show_decisive_fallback_if_needed"),
		"beat di ripiego mostrato due volte")
	var narrative: Dictionary = world.get("game_save").data.get("narrative", {})
	assert(Array(narrative.get("fallbacksSeen", [])).has("12"),
		"beat di ripiego non persistito")

	print("Mystery runtime audit OK - Tracce, semi e ripiego fisici")
	quit(0)
