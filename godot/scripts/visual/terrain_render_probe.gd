extends SceneTree

const PROBES := [
	{"id": "academy", "position": Vector2(448, 448)},
	{"id": "geo", "position": Vector2(-470, 2490)},
	{"id": "wild", "position": Vector2(-2450, -500)},
	{"id": "logic", "position": Vector2(2850, -650)},
	{"id": "ruins", "position": Vector2(-2450, -2700)},
	{"id": "north-edge", "position": Vector2(0, -3460)},
	{"id": "east-edge", "position": Vector2(3460, 0)},
]

func _initialize() -> void:
	var packed := load("res://scenes/outdoor_world.tscn") as PackedScene
	if packed == null:
		push_error("TERRAIN_RENDER_PROBE: main scene missing")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	# Stable daylight makes painterly material/detail QA independent from the
	# saved day/night phase.
	scene.set("day_clock", 60.0)
	_capture_tour.call_deferred(scene)

func _capture_tour(scene: Node) -> void:
	var player: Node2D = scene.get("player")
	var camera: Camera2D = scene.get("camera")
	var chunks: Node = scene.get("chunks")
	if player == null or camera == null or chunks == null:
		push_error("TERRAIN_RENDER_PROBE: world services unavailable")
		quit(2)
		return
	player.set_physics_process(false)
	camera.position_smoothing_enabled = false
	for probe in PROBES:
		player.position = probe["position"]
		camera.position = probe["position"]
		chunks.update_stream(probe["position"])
		for frame in range(10):
			await process_frame
		var error := _save_viewport("res://../artifacts/terrain-%s.png" % str(probe["id"]))
		if error != OK:
			push_error("TERRAIN_RENDER_PROBE: %s save failed (%s)" % [probe["id"], error_string(error)])
			quit(1)
			return
		print("TERRAIN_RENDER_PROBE_CAPTURE %s" % str(probe["id"]))
	print("TERRAIN_RENDER_PROBE_OK %d biomes" % PROBES.size())
	quit(0)

func _save_viewport(output_path: String) -> Error:
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		return ERR_UNAVAILABLE
	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	return image.save_png(absolute_output)
