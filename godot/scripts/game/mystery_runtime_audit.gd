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
	_assert_art_contract()
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
		assert(artifact.global_position.distance_to(ruin.global_position) <= 520.0,
			"Traccia o seme troppo lontano dalla Rovina")
		assert(not world.get("chunks").composition.is_protected(artifact.global_position, 40.0),
			"Traccia o seme dentro safeRadius o safeRoute")
		assert(world.get("chunks").composition.raw_water_weight(artifact.global_position) < 0.24,
			"Traccia o seme in acqua")

	assert(world.call("_show_decisive_fallback_if_needed"),
		"beat di ripiego decisivo non mostrato quando la Traccia e' saltata")
	assert(not world.call("_show_decisive_fallback_if_needed"),
		"beat di ripiego mostrato due volte")
	var narrative: Dictionary = world.get("game_save").data.get("narrative", {})
	assert(Array(narrative.get("fallbacksSeen", [])).has("12"),
		"beat di ripiego non persistito")

	print("Mystery runtime audit OK - Tracce, semi e ripiego fisici")
	quit(0)

func _assert_art_contract() -> void:
	assert(MysteryCatalog.TAVOLE_TRACCE.size() == MysteryCatalog.TRACCE.size(),
		"ogni Traccia deve dichiarare una tavola")
	for world_level in MysteryCatalog.TRACCE.keys():
		var trace := MysteryCatalog.traccia_for(int(world_level))
		var table_id := str(trace.get("tavola", ""))
		assert(table_id == "mystery-trace-%02d" % int(world_level),
			"Traccia %d senza la propria tavola" % int(world_level))
	for seed in MysteryCatalog.tutti_i_semi():
		var table_id := MysteryCatalog.tavola_per_seme(seed as Dictionary)
		assert(table_id != "", "seme senza tavola o pittogramma dichiarato")
	for required_table in [
		"mystery-seed-sigillo", "mystery-seed-schede",
		"mystery-seed-stanza", "mystery-seed-tredicesimo"]:
		assert(MysteryCatalog.TAVOLE_SEMI.values().has(required_table),
			"manca tavola per %s" % required_table)
	for world_level in MysteryCatalog.tracce_decisive():
		var decisive_artifact := MysteryArtifact.new()
		decisive_artifact.configure("trace", "audit-%02d" % world_level,
			MysteryCatalog.traccia_for(world_level), true)
		assert(decisive_artifact.get_node_or_null("ArtifactIllustration") != null,
			"Traccia decisiva %d senza tavola ad alto contrasto" % world_level)
		var label := decisive_artifact.get_node_or_null("ArtifactLabel") as Label
		assert(label != null and label.text.begins_with("TRACCIA"),
			"Traccia decisiva %d non leggibile ad alto contrasto" % world_level)
		decisive_artifact.queue_free()
