class_name OutdoorChunkManager
extends Node2D

const CHUNK_SIZE := 896
const WORLD_MIN := -4
const WORLD_MAX := 3
const ACTIVE_RADIUS := 1
const CHUNK_VISUAL := preload("res://scripts/chunk_visual.gd")
const WORLD_PATH_RENDERER := preload("res://scripts/visual/world_path_renderer.gd")
const PAINTERLY_GROUND_SHADER: Shader = preload("res://shaders/painterly_ground.gdshader")
const UNDERPAINT_ACADEMY: Texture2D = preload("res://assets/terrain-underpaint-academy.png")
const UNDERPAINT_WILD: Texture2D = preload("res://assets/terrain-underpaint-wild.png")
const UNDERPAINT_MINERAL: Texture2D = preload("res://assets/terrain-underpaint-mineral.png")
const UNDERPAINT_MAGIC: Texture2D = preload("res://assets/terrain-underpaint-magic.png")
const BOUNDARY_DEPTH := 1400.0
const BOUNDARY_MARGIN := 92.0

var world_seed := "outdoor-dev-1"
var generator := OutdoorGenerator.new()
var loaded: Dictionary = {}
var player_position := Vector2.ZERO
var world: Node
var composition: WorldCompositionData

func configure(seed: String, world_ref: Node = null) -> void:
	world_seed = seed
	world = world_ref
	composition = WorldCompositionGenerator.generate(seed)
	y_sort_enabled = true
	_build_global_paths()
	_build_world_boundaries()

func _build_global_paths() -> void:
	if has_node("GlobalNavigationPaths"):
		return
	var paths: Node2D = WORLD_PATH_RENDERER.new()
	paths.configure(composition)
	add_child(paths)

func world_bounds() -> Rect2:
	var minimum := Vector2(WORLD_MIN * CHUNK_SIZE, WORLD_MIN * CHUNK_SIZE)
	var span := float((WORLD_MAX - WORLD_MIN + 1) * CHUNK_SIZE)
	return Rect2(minimum, Vector2.ONE * span)

func clamp_to_world(position: Vector2, margin: float = BOUNDARY_MARGIN) -> Vector2:
	var bounds := world_bounds()
	return Vector2(
		clampf(position.x, bounds.position.x + margin, bounds.end.x - margin),
		clampf(position.y, bounds.position.y + margin, bounds.end.y - margin))

func update_stream(position: Vector2) -> void:
	player_position = position
	var center_x := floori(position.x / CHUNK_SIZE)
	var center_y := floori(position.y / CHUNK_SIZE)
	var required := {}
	for y in range(center_y - ACTIVE_RADIUS, center_y + ACTIVE_RADIUS + 1):
		for x in range(center_x - ACTIVE_RADIUS, center_x + ACTIVE_RADIUS + 1):
			if x < WORLD_MIN or x > WORLD_MAX or y < WORLD_MIN or y > WORLD_MAX:
				continue
			var id := "chunk-%d_%d" % [x, y]
			required[id] = true
			if not loaded.has(id):
				var cell_distance := absi(x - center_x) + absi(y - center_y)
				var visual_lod := 0 if cell_distance == 0 else 1 if cell_distance == 1 else 2
				_load_chunk(generator.generate_chunk(world_seed, x, y), visual_lod)
	var stale_ids: Array[String] = []
	for id in loaded.keys():
		if not required.has(id):
			stale_ids.append(str(id))
	for id in stale_ids:
		_unload_chunk(id)

func _load_chunk(chunk: Dictionary, visual_lod: int = 0) -> void:
	var node: OutdoorChunkVisual = CHUNK_VISUAL.new()
	node.name = str(chunk["id"])
	node.position = Vector2(chunk["worldX"], chunk["worldY"])
	add_child(node)
	node.configure(chunk, world, visual_lod, composition)
	loaded[chunk["id"]] = {"data": chunk, "node": node}

func _unload_chunk(id: String) -> void:
	var entry: Dictionary = loaded[id]
	if is_instance_valid(entry["node"]):
		entry["node"].queue_free()
	loaded.erase(id)

func _build_world_boundaries() -> void:
	if has_node("WorldBoundary"):
		return
	var bounds := world_bounds()
	var root := Node2D.new()
	root.name = "WorldBoundary"
	root.y_sort_enabled = true
	add_child(root)

	# Quattro fondali esterni impediscono al colore di clear del viewport di
	# apparire anche con camera larga. La fascia e piu profonda di una viewport.
	var backdrop := Node2D.new()
	backdrop.name = "BoundaryBackdrop"
	backdrop.z_index = -30
	root.add_child(backdrop)
	_add_boundary_fill(backdrop, Rect2(bounds.position - Vector2(BOUNDARY_DEPTH, BOUNDARY_DEPTH), Vector2(bounds.size.x + BOUNDARY_DEPTH * 2.0, BOUNDARY_DEPTH)), Color("10241d"))
	_add_boundary_fill(backdrop, Rect2(Vector2(bounds.position.x - BOUNDARY_DEPTH, bounds.end.y), Vector2(bounds.size.x + BOUNDARY_DEPTH * 2.0, BOUNDARY_DEPTH)), Color("14241f"))
	_add_boundary_fill(backdrop, Rect2(Vector2(bounds.position.x - BOUNDARY_DEPTH, bounds.position.y), Vector2(BOUNDARY_DEPTH, bounds.size.y)), Color("13251d"))
	_add_boundary_fill(backdrop, Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(BOUNDARY_DEPTH, bounds.size.y)), Color("111f22"))

	# Collisioni rettangolari continue: nessun varco tra i singoli alberi/sassi.
	_add_boundary_collider(root, Vector2(bounds.position.x + 22.0, bounds.position.y + bounds.size.y * 0.5), Vector2(88, bounds.size.y + 180))
	_add_boundary_collider(root, Vector2(bounds.end.x - 22.0, bounds.position.y + bounds.size.y * 0.5), Vector2(88, bounds.size.y + 180))
	_add_boundary_collider(root, Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + 22.0), Vector2(bounds.size.x + 180, 88))
	_add_boundary_collider(root, Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.end.y - 22.0), Vector2(bounds.size.x + 180, 88))

	var canopy := Node2D.new()
	canopy.name = "NaturalBoundaryCanopy"
	canopy.y_sort_enabled = true
	root.add_child(canopy)
	var step := 148.0
	var horizontal_count := ceili(bounds.size.x / step)
	for index in range(horizontal_count + 1):
		var x := bounds.position.x + minf(bounds.size.x, float(index) * step)
		_add_boundary_motif(canopy, Vector2(x, bounds.position.y + 58.0), index, 0)
		_add_boundary_motif(canopy, Vector2(x, bounds.end.y - 38.0), index, 1)
	var vertical_count := ceili(bounds.size.y / step)
	for index in range(1, vertical_count):
		var y := bounds.position.y + float(index) * step
		_add_boundary_motif(canopy, Vector2(bounds.position.x + 58.0, y), index, 2)
		_add_boundary_motif(canopy, Vector2(bounds.end.x - 58.0, y), index, 3)

func _add_boundary_fill(parent: Node2D, rect: Rect2, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	polygon.texture = UNDERPAINT_ACADEMY
	var texture_size := UNDERPAINT_ACADEMY.get_size()
	polygon.uv = PackedVector2Array([Vector2.ZERO, Vector2(texture_size.x, 0), texture_size, Vector2(0, texture_size.y)])
	var material := ShaderMaterial.new()
	material.shader = PAINTERLY_GROUND_SHADER
	material.set_shader_parameter("academy_tex", UNDERPAINT_ACADEMY)
	material.set_shader_parameter("wild_tex", UNDERPAINT_WILD)
	material.set_shader_parameter("mineral_tex", UNDERPAINT_MINERAL)
	material.set_shader_parameter("magic_tex", UNDERPAINT_MAGIC)
	material.set_shader_parameter("surface_world_origin", rect.position)
	material.set_shader_parameter("surface_world_size", rect.size)
	material.set_shader_parameter("detail_strength", 0.58)
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]
	var names := ["weights_tl", "weights_tr", "weights_bl", "weights_br"]
	for index in range(corners.size()):
		material.set_shader_parameter(names[index], _boundary_material_weights(corners[index]))
	polygon.material = material
	parent.add_child(polygon)
	var dim := Polygon2D.new()
	dim.polygon = polygon.polygon
	dim.color = Color(color, 0.48)
	parent.add_child(dim)

func _boundary_material_weights(world_pos: Vector2) -> Vector4:
	var weights := composition.biome_weights(world_pos)
	return Vector4(
		float(weights.get("academy", 0.0)),
		float(weights.get("wild", 0.0)),
		float(weights.get("geo", 0.0)) + float(weights.get("ruins", 0.0)),
		float(weights.get("logic", 0.0)) + float(weights.get("crystal", 0.0)))

func _add_boundary_collider(parent: Node2D, position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)
	parent.add_child(body)

func _add_boundary_motif(parent: Node2D, position: Vector2, index: int, edge: int) -> void:
	var biome := composition.dominant_biome(position)
	var kind := "tree" if biome in ["academy", "wild"] else "rock" if biome in ["geo", "ruins"] else "crystal"
	var variant := fmod(float(index) * 0.371 + float(edge) * 0.219, 1.0)
	var motif := OutdoorVisualFactory.build_obstacle(kind, 48.0 + variant * 14.0, 0x355b42, variant, biome)
	motif.position = position + Vector2(sin(float(index) * 1.7 + edge) * 22.0, cos(float(index) * 1.13 + edge) * 10.0)
	motif.scale = Vector2.ONE * (1.05 + variant * 0.28)
	parent.add_child(motif)
