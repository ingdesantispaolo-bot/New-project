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
var world_profile: Dictionary = {}
var reserved_event_positions: Array = []
var profile_bounds := Rect2()
var active_radius := ACTIVE_RADIUS

func configure(seed: String, world_ref: Node = null, profile: Dictionary = {}, event_positions: Array = []) -> void:
	world_seed = seed
	world = world_ref
	world_profile = profile.duplicate(true)
	reserved_event_positions = event_positions.duplicate()
	if not world_profile.is_empty():
		var ship: Vector2 = world_profile.get("shipEntrance", {}).get("position", Vector2.ZERO)
		var half_extent := float(world_profile.get("worldHalfExtent", 2200.0))
		profile_bounds = Rect2(ship - Vector2.ONE * half_extent, Vector2.ONE * half_extent * 2.0)
		var budget: Dictionary = _performance_budget(world_profile)
		active_radius = clampi(int(floor(float(budget.get("streamRadius", 1400)) / float(CHUNK_SIZE))), 1, 2)
	composition = WorldCompositionGenerator.generate(seed, world_profile)
	if composition != null and not world_profile.is_empty():
		for index in range(reserved_event_positions.size()):
			composition.protected_zones.append({
				"id": "reserved-event-%d" % index,
				"position": reserved_event_positions[index],
				"radius": 104.0,
			})
	y_sort_enabled = true
	_build_global_paths()
	_build_world_boundaries()

func _performance_budget(profile: Dictionary) -> Dictionary:
	var budgets: Dictionary = profile.get("performanceBudget", {})
	var tier := "mobile" if OS.has_feature("mobile") else "web" if OS.has_feature("web") else "desktop"
	return Dictionary(budgets.get(tier, budgets.get("web", {})))

func _build_global_paths() -> void:
	if has_node("GlobalNavigationPaths"):
		return
	var paths: Node2D = WORLD_PATH_RENDERER.new()
	paths.configure(composition)
	add_child(paths)

func world_bounds() -> Rect2:
	if profile_bounds.has_area():
		return profile_bounds
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
	for y in range(center_y - active_radius, center_y + active_radius + 1):
		for x in range(center_x - active_radius, center_x + active_radius + 1):
			if x < WORLD_MIN or x > WORLD_MAX or y < WORLD_MIN or y > WORLD_MAX:
				continue
			if not world_profile.is_empty() and not _chunk_rect(x, y).intersects(profile_bounds):
				continue
			var id := "chunk-%d_%d" % [x, y]
			required[id] = true
			if not loaded.has(id):
				var cell_distance := absi(x - center_x) + absi(y - center_y)
				var visual_lod := 0 if cell_distance == 0 else 1 if cell_distance == 1 else 2
				_load_chunk(_profile_filtered_chunk(generator.generate_chunk(world_seed, x, y)), visual_lod)
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

func _chunk_rect(chunk_x: int, chunk_y: int) -> Rect2:
	return Rect2(Vector2(chunk_x * CHUNK_SIZE, chunk_y * CHUNK_SIZE), Vector2.ONE * CHUNK_SIZE)

func _profile_filtered_chunk(source: Dictionary) -> Dictionary:
	if world_profile.is_empty():
		return source
	var chunk := source.duplicate(true)
	for field in ["obstacles", "props", "treasures"]:
		var kept: Array = []
		for item in chunk.get(field, []):
			var position := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
			var margin := float(item.get("r", 28.0)) + (42.0 if field == "obstacles" else 56.0)
			if not profile_bounds.grow(-18.0).has_point(position):
				continue
			if composition != null and composition.is_protected(position, margin):
				continue
			if _near_reserved_event(position, margin + 54.0):
				continue
			# Le vertical slice autorate tengono la decorazione procedurale come
			# tessuto secondario: la topologia resta quella del profilo.
			var level := int(world_profile.get("level", 1))
			if level in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] and field in ["obstacles", "props"]:
				var signature := str(item.get("id", "%s:%.1f:%.1f" % [field, position.x, position.y]))
				var keep_percent := 58 if field == "obstacles" else 42
				if level == 3:
					keep_percent = 70 if field == "obstacles" else 34
				elif level == 4:
					keep_percent = 46 if field == "obstacles" else 28
				elif level == 5:
					keep_percent = 12 if field == "obstacles" else 8
				elif level == 6:
					keep_percent = 28 if field == "obstacles" else 22
				elif level == 7:
					keep_percent = 18 if field == "obstacles" else 10
				elif level == 8:
					keep_percent = 12 if field == "obstacles" else 8
				elif level == 9:
					keep_percent = 10 if field == "obstacles" else 8
				elif level == 10:
					keep_percent = 35 if field == "obstacles" else 24
				elif level == 11:
					keep_percent = 10 if field == "obstacles" else 6
				elif level == 12:
					keep_percent = 8 if field == "obstacles" else 5
				elif level == 13:
					keep_percent = 12 if field == "obstacles" else 6
				elif level == 14:
					keep_percent = 8 if field == "obstacles" else 6
				elif level == 15:
					keep_percent = 6 if field == "obstacles" else 5
				elif level == 16:
					keep_percent = 16 if field == "obstacles" else 10
				elif level == 17:
					keep_percent = 3
				elif level == 18:
					keep_percent = 6 if field == "obstacles" else 4
				elif level == 19:
					keep_percent = 6 if field == "obstacles" else 4
				elif level == 20:
					keep_percent = 5 if field == "obstacles" else 4
				elif level == 21:
					keep_percent = 4 if field == "obstacles" else 2
				elif level == 22:
					keep_percent = 3 if field == "obstacles" else 2
				elif level == 23:
					keep_percent = 0
				elif level == 24:
					keep_percent = 0
				if posmod(hash(signature), 100) >= keep_percent:
					continue
			kept.append(item)
		chunk[field] = kept
	# Il profilo ha già un landmark eroe autorato: i landmark casuali legacy
	# introducevano etichette di altri biomi ("Prisma", "Porta dell'Atlante").
	chunk["landmarks"] = []
	# Le missioni non provengono più dal generatore legacy: l'unica fonte è il
	# MissionEventDirector O-P1, che garantisce quota focus e determinismo.
	chunk["encounters"] = []
	return chunk

func _near_reserved_event(position: Vector2, radius: float) -> bool:
	for reserved in reserved_event_positions:
		if position.distance_to(reserved as Vector2) <= radius:
			return true
	return false

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
	var boundary_colors := _boundary_palette()
	_add_boundary_fill(backdrop, Rect2(bounds.position - Vector2(BOUNDARY_DEPTH, BOUNDARY_DEPTH), Vector2(bounds.size.x + BOUNDARY_DEPTH * 2.0, BOUNDARY_DEPTH)), boundary_colors[0])
	_add_boundary_fill(backdrop, Rect2(Vector2(bounds.position.x - BOUNDARY_DEPTH, bounds.end.y), Vector2(bounds.size.x + BOUNDARY_DEPTH * 2.0, BOUNDARY_DEPTH)), boundary_colors[1])
	_add_boundary_fill(backdrop, Rect2(Vector2(bounds.position.x - BOUNDARY_DEPTH, bounds.position.y), Vector2(BOUNDARY_DEPTH, bounds.size.y)), boundary_colors[2])
	_add_boundary_fill(backdrop, Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(BOUNDARY_DEPTH, bounds.size.y)), boundary_colors[3])

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

func _boundary_palette() -> Array[Color]:
	match composition.visual_theme:
		"motion_forge":
			return [Color("181619"), Color("241a17"), Color("1c191d"), Color("14171b")]
		"resonance_garden":
			return [Color("201333"), Color("28173d"), Color("171f35"), Color("25152f")]
		"glyph_ruins":
			return [Color("3a271d"), Color("4a3020"), Color("33271f"), Color("3c2a22")]
		"circuit_delta":
			return [Color("061b23"), Color("082b30"), Color("071d28"), Color("051922")]
		"charted_archipelago":
			return [Color("0a3045"), Color("0d4656"), Color("16384b"), Color("092b40")]
		"symbiosis_greenhouse":
			return [Color("153c25"), Color("1d4a2c"), Color("173725"), Color("103321")]
		"civic_city":
			return [Color("3f2b20"), Color("513526"), Color("39271f"), Color("453025")]
		"rule_labyrinth":
			return [Color("0d1422"), Color("111a2b"), Color("0b1320"), Color("101827")]
		"orbital_desert":
			return [Color("241612"), Color("332019"), Color("1b1720"), Color("2b1b17")]
		"voices_library":
			return [Color("2a1723"), Color("39202a"), Color("211623"), Color("321b27")]
		"machine_city":
			return [Color("07131e"), Color("0a1c29"), Color("06101a"), Color("0b1724")]
		"language_frontier":
			return [Color("49301e"), Color("5d3b24"), Color("3d2b1d"), Color("523620")]
		"force_ocean":
			return [Color("102b3b"), Color("17475a"), Color("123447"), Color("0c2536")]
		"sound_cathedral":
			return [Color("211a32"), Color("493556"), Color("2b203c"), Color("372944")]
		"root_necropolis":
			return [Color("2a241d"), Color("514431"), Color("322b21"), Color("453a2b")]
		"electromagnetic_storm":
			return [Color("101829"), Color("263b55"), Color("17243a"), Color("201e3d")]
		"fractured_atlas":
			return [Color("353127"), Color("4d5637"), Color("293f48"), Color("4a3025")]
		"deep_biosphere":
			return [Color("102b27"), Color("17483d"), Color("202944"), Color("133832")]
		"colony_council":
			return [Color("111b31"), Color("263b5b"), Color("172641"), Color("202f4a")]
		"first_heart":
			return [Color("241d33"), Color("4a3c5a"), Color("252e48"), Color("503b35")]
		_:
			return [Color("10241d"), Color("14241f"), Color("13251d"), Color("111f22")]

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
	if composition.visual_theme == "crater":
		kind = "crystal" if (index + edge) % 4 == 0 else "rock"
	elif composition.visual_theme == "signal_bay":
		kind = "rock"
	elif composition.visual_theme == "motion_forge":
		kind = "rock"
	elif composition.visual_theme == "resonance_garden":
		kind = "crystal" if (index + edge) % 3 != 0 else "tree"
	elif composition.visual_theme == "glyph_ruins":
		kind = "rock"
	elif composition.visual_theme == "circuit_delta":
		kind = "crystal" if (index + edge) % 2 == 0 else "rock"
	elif composition.visual_theme == "charted_archipelago":
		kind = "rock"
	elif composition.visual_theme == "symbiosis_greenhouse":
		kind = "tree" if (index + edge) % 4 != 0 else "crystal"
	elif composition.visual_theme == "civic_city":
		kind = "rock"
	elif composition.visual_theme == "rule_labyrinth":
		kind = "crystal" if (index + edge) % 5 == 0 else "rock"
	elif composition.visual_theme == "orbital_desert":
		kind = "crystal" if (index + edge) % 6 == 0 else "rock"
	elif composition.visual_theme == "voices_library":
		kind = "rock"
	elif composition.visual_theme == "machine_city":
		kind = "crystal" if (index + edge) % 3 == 0 else "rock"
	elif composition.visual_theme == "language_frontier":
		kind = "tree" if (index + edge) % 5 == 0 else "rock"
	elif composition.visual_theme == "force_ocean":
		kind = "crystal" if (index + edge) % 3 == 0 else "rock"
	elif composition.visual_theme == "sound_cathedral":
		kind = "crystal" if (index + edge) % 5 == 0 else "rock"
	elif composition.visual_theme == "root_necropolis":
		kind = "tree" if (index + edge) % 3 == 0 else "rock"
	elif composition.visual_theme == "electromagnetic_storm":
		kind = "crystal" if (index + edge) % 2 == 0 else "rock"
	elif composition.visual_theme == "fractured_atlas":
		kind = "tree" if (index + edge) % 4 == 0 else "rock"
	elif composition.visual_theme == "deep_biosphere":
		kind = "crystal" if (index + edge) % 3 == 0 else "tree"
	elif composition.visual_theme == "colony_council":
		kind = "crystal" if (index + edge) % 4 == 0 else "rock"
	elif composition.visual_theme == "first_heart":
		kind = "crystal"
	var variant := fmod(float(index) * 0.371 + float(edge) * 0.219, 1.0)
	var motif := OutdoorVisualFactory.build_obstacle(kind, 48.0 + variant * 14.0, 0x355b42, variant, biome)
	motif.position = position + Vector2(sin(float(index) * 1.7 + edge) * 22.0, cos(float(index) * 1.13 + edge) * 10.0)
	motif.scale = Vector2.ONE * (1.05 + variant * 0.28)
	parent.add_child(motif)
