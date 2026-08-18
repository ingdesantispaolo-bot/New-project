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
	print("WORLD 1 VERTICAL SLICE render probe OK - 5 catture 900x600")
	quit(0)

func _capture(world: Node, target: Node2D, filename: String) -> void:
	var player := world.get("player") as OutdoorPlayerController
	player.global_position = target.global_position + Vector2(0, 168)
	world.get("chunks").update_stream(player.global_position)
	var camera := world.get("camera") as Camera2D
	camera.reset_smoothing()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(
		"%s/%s.png" % [OUTPUT, filename]))
