extends SceneTree

## Catture della vertical slice reale: una famiglia per apparato, un varco e la
## riaccensione dell'obelisco. Usa renderer e HUD del gioco, non una vetrina.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const OUTPUT := "res://../artifacts/world1-vertical-slice"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(900, 600))
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	initial["worldProgress"] = {
		"1": {
			"completedEncounterIds": ["evt-1-gate-2"],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"resume": {},
		},
	}
	var request := NativeWorldState.default_request("world1-vertical-slice-render")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame

	var sites: Dictionary = {}
	var crossing: Area2D = null
	var minimission: Area2D = null
	for event_data in Array(world.get("mission_events")):
		var event: Dictionary = event_data
		if not bool(event.get("countsForGate", false)):
			continue
		var node := world.find_child(
			"MissionEvent_%s" % str(event["id"]).replace("-", "_"), true, false) as Area2D
		if node == null:
			continue
		var site := node.get_node_or_null("World1ActivitySite")
		if site != null:
			sites[str(site.get_meta("site_family", ""))] = node
		elif event.has("bridgeCenter"):
			crossing = node
		elif str(event.get("kind", "")) == "minimission":
			minimission = node

	for family in ["measure", "sequence", "matching"]:
		assert(sites.has(family), "famiglia non renderizzabile: %s" % family)
		await _capture(world, sites[family] as Node2D, "site-%s" % family)
	assert(crossing != null, "varco non renderizzabile")
	await _capture(world, crossing, "enigma-varco")
	assert(minimission != null, "obelisco non renderizzabile")
	await _capture(world, minimission, "obelisco-spento")

	var composition: WorldCompositionData = world.get("chunks").composition
	var discovery_marker := Node2D.new()
	discovery_marker.position = _first_expedition_position(composition)
	world.add_child(discovery_marker)
	await _capture(world, discovery_marker, "spedizione-scoperta")
	var profile: Dictionary = world.get("world_profile")
	var shape: PackedVector2Array = profile.get("worldShape", PackedVector2Array())
	assert(not shape.is_empty(), "costa procedurale assente")
	var coast_marker := Node2D.new()
	coast_marker.position = shape[0].move_toward(profile.get("worldCenter", Vector2.ZERO), 150.0)
	world.add_child(coast_marker)
	await _capture(world, coast_marker, "spedizione-costa")

	var hazards := get_nodes_in_group("world_challenge_hazard")
	assert(not hazards.is_empty(), "pericolo specifico del mondo non renderizzabile")
	var hazard := hazards[0] as WorldHazard
	hazard.force_phase_for_audit(WorldHazard.SAFE)
	await _capture(world, hazard, "hazard-sicuro")
	await _capture(world, hazard, "hazard-prova-vicina", Vector2(0, 64))
	hazard.force_phase_for_audit(WorldHazard.WARNING)
	await _capture(world, hazard, "hazard-preavviso")
	hazard.force_phase_for_audit(WorldHazard.ACTIVE)
	await _capture(world, hazard, "hazard-attivo")
	print("WORLD 1 VERTICAL SLICE render probe OK - 11 catture 900x600")
	quit(0)

func _first_expedition_position(composition: WorldCompositionData) -> Vector2:
	for region_data in composition.identity_regions:
		var region: Dictionary = region_data
		if str(region.get("id", "")).begins_with("expedition-pocket-"):
			return region.get("position", Vector2.ZERO)
	assert(false, "luogo di spedizione non renderizzabile")
	return Vector2.ZERO

func _capture(
	world: Node, target: Node2D, filename: String,
	player_offset: Vector2 = Vector2(0, 168)
) -> void:
	var player := world.get("player") as OutdoorPlayerController
	player.global_position = target.global_position + player_offset
	world.get("chunks").update_stream(player.global_position)
	var camera := world.get("camera") as Camera2D
	camera.reset_smoothing()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(
		"%s/%s.png" % [OUTPUT, filename]))
