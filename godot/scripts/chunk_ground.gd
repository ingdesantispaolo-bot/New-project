extends Node2D

## Sfondo piatto del chunk: terreno, tinta del bioma, chiazze d'erba, ciuffi,
## fiori e sentieri con bordo. Sta su z_index basso e fuori dall'y-sort, così
## resta sempre dietro agli oggetti (ostacoli, player, interagibili).
##
## I dettagli decorativi usano un RNG seedato SEPARATO ("<id>:ground"): stessa
## estetica a ogni visita, nessun impatto sulla parità del generatore.
## Tutti i valori casuali sono precalcolati in setup(): _draw() deve essere
## ripetibile senza consumare RNG.

const PAINTERLY_GROUND_SHADER: Shader = preload("res://shaders/painterly_ground.gdshader")
const PAINTERLY_WATER_SHADER: Shader = preload("res://shaders/painterly_water.gdshader")
const UNDERPAINT_ACADEMY: Texture2D = preload("res://assets/terrain-underpaint-academy.png")
const UNDERPAINT_WILD: Texture2D = preload("res://assets/terrain-underpaint-wild.png")
const UNDERPAINT_MINERAL: Texture2D = preload("res://assets/terrain-underpaint-mineral.png")
const UNDERPAINT_MAGIC: Texture2D = preload("res://assets/terrain-underpaint-magic.png")
const UNDERPAINT_ARCHIVE: Texture2D = preload("res://assets/archivio-parole-underpaint-v1.png")
const PATH_EARTH_TEXTURE: Texture2D = preload("res://assets/terrain-path-earth.png")
const WATER_POND_TEXTURE: Texture2D = preload("res://assets/terrain-water-pond.png")
const RNG := preload("res://scripts/deterministic_rng.gd")

var chunk: Dictionary
var visual_lod := 0
var blotches: Array = []   # [{pos, radius, alpha}]
var speckles: Array = []   # [{pos, radius, color}]
var tufts: Array = []      # [{pos, height, color}]
var blossom_clusters: Array = [] # [{pos, radius, color}]
var academy_focus := false
var academy_paths: Array[PackedVector2Array] = []
var academy_gardens: Array[Vector2] = []
var academy_stones: Array[Vector2] = []
var corridor_points: Array[Vector2] = []
var anchor_points: Array[Vector2] = []
var motif_points: Array[Vector2] = []
var composition: WorldCompositionData
var painterly_surface: Polygon2D

func setup(data: Dictionary, lod_level: int = 0, composition_data: WorldCompositionData = null) -> void:
	chunk = data
	visual_lod = maxi(0, lod_level)
	composition = composition_data
	var decor = RNG.new(str(chunk.get("id", "chunk")) + ":ground")
	var size := float(chunk.get("size", 896))
	_build_painterly_surface(size)
	_build_world_water_features(size)
	_build_identity_regions(size)
	var patch: Dictionary = chunk.get("patch", {})
	var biome := str(chunk.get("biome", "academy"))
	var tint := _hex_color(int(patch.get("color", 0x173b36))).lerp(_biome_palette_tint(biome), 0.22)
	var accent := _hex_color(int(patch.get("accent", 0x6be7d6))).lerp(_biome_palette_accent(biome), 0.18)
	academy_focus = str(chunk.get("biome", "")) == "academy" and int(chunk.get("chunkX", 99)) == 0 and int(chunk.get("chunkY", 99)) == 0
	academy_paths.clear()
	academy_gardens.clear()
	academy_stones.clear()
	motif_points.clear()
	_prepare_composition_masks(size)
	var density := _biome_density(biome)

	blotches.clear()
	for i in range(maxi(3, roundi(6.0 * density))):
		blotches.append({
			"pos": Vector2(decor.next_float() * size, decor.next_float() * size),
			"radius": 90.0 + decor.next_float() * 140.0,
			"alpha": 0.05 + decor.next_float() * 0.05,
		})

	speckles.clear()
	var speckle_count := roundi((112.0 if visual_lod == 0 else 36.0) * density)
	for i in range(maxi(10, speckle_count)):
		var roll := decor.next_float()
		var color: Color
		var radius: float
		if roll < 0.62:
			color = Color(tint.darkened(0.25), 0.4)
			radius = 1.6 + decor.next_float() * 2.2
		elif roll < 0.9:
			color = Color(tint.lightened(0.35), 0.3)
			radius = 1.4 + decor.next_float() * 1.8
		else:
			color = Color(accent, 0.75)
			radius = 1.8 + decor.next_float() * 0.9
		speckles.append({
			"pos": Vector2(8.0 + decor.next_float() * (size - 16.0), 8.0 + decor.next_float() * (size - 16.0)),
			"radius": radius,
			"color": color,
		})

	tufts.clear()
	var tuft_count := roundi((46.0 if visual_lod == 0 else 18.0) * density)
	for i in range(maxi(6, tuft_count)):
		var tuft_roll := decor.next_float()
		var tuft_color := Color(accent, 0.24) if tuft_roll > 0.76 else Color(tint.lightened(0.3), 0.22)
		tufts.append({
			"pos": Vector2(12.0 + decor.next_float() * (size - 24.0), 12.0 + decor.next_float() * (size - 24.0)),
			"height": 3.0 + decor.next_float() * 6.0,
			"color": tuft_color,
		})

	blossom_clusters.clear()
	var blossom_count := roundi((22.0 if visual_lod == 0 else 8.0) * density)
	for i in range(maxi(3, blossom_count)):
		var blossom_roll := decor.next_float()
		var blossom_color := Color(accent, 0.68) if blossom_roll > 0.42 else Color(tint.lightened(0.46), 0.52)
		blossom_clusters.append({
			"pos": Vector2(24.0 + decor.next_float() * (size - 48.0), 24.0 + decor.next_float() * (size - 48.0)),
			"radius": 2.0 + decor.next_float() * 2.2,
			"color": blossom_color,
		})

	for i in range(4 if visual_lod == 0 else 2):
		motif_points.append(Vector2(
			56.0 + decor.next_float() * (size - 112.0),
			56.0 + decor.next_float() * (size - 112.0)))

	# Layout decorativo separato dal generatore: il chunk centrale della Radura
	# diventa una piccola scena composta (cortile, acqua, sentieri e bordi
	# naturali), mentre gli ID e le posizioni gameplay restano invariati.
	if academy_focus:
		_prepare_academy_composition(decor, size)
	queue_redraw()

func _build_painterly_surface(size: float) -> void:
	# Exact edge-to-edge polygons share identical world samples. Overdraw with
	# different LOD materials would reintroduce a seam, so no cell bleed here.
	var bleed := 0.0
	painterly_surface = Polygon2D.new()
	painterly_surface.name = "WorldSpaceUnderpainting"
	painterly_surface.z_index = -20
	painterly_surface.polygon = PackedVector2Array([
		Vector2(-bleed, -bleed), Vector2(size + bleed, -bleed),
		Vector2(size + bleed, size + bleed), Vector2(-bleed, size + bleed),
	])
	painterly_surface.texture = UNDERPAINT_ACADEMY
	var texture_size := UNDERPAINT_ACADEMY.get_size()
	painterly_surface.uv = PackedVector2Array([
		Vector2(0, 0), Vector2(texture_size.x, 0),
		texture_size, Vector2(0, texture_size.y),
	])
	var material := ShaderMaterial.new()
	material.shader = PAINTERLY_GROUND_SHADER
	material.set_shader_parameter("academy_tex", UNDERPAINT_ACADEMY)
	material.set_shader_parameter("wild_tex", UNDERPAINT_WILD)
	material.set_shader_parameter("mineral_tex", UNDERPAINT_MINERAL)
	material.set_shader_parameter("magic_tex", UNDERPAINT_MAGIC)
	material.set_shader_parameter("identity_tex", UNDERPAINT_ARCHIVE)
	var visual_theme := composition.visual_theme if composition != null else "legacy"
	var archive_strength := 0.86 if visual_theme == "archive" else 0.0
	material.set_shader_parameter("identity_strength", archive_strength)
	material.set_shader_parameter("identity_calm_palette", Color("4b536f"))
	var world_origin := Vector2(float(chunk.get("worldX", 0)), float(chunk.get("worldY", 0))) - Vector2.ONE * bleed
	var surface_size := size + bleed * 2.0
	material.set_shader_parameter("surface_world_origin", world_origin)
	material.set_shader_parameter("surface_world_size", Vector2.ONE * surface_size)
	material.set_shader_parameter("detail_strength", 1.0)
	var corners := [
		world_origin,
		world_origin + Vector2(surface_size, 0),
		world_origin + Vector2(0, surface_size),
		world_origin + Vector2.ONE * surface_size,
	]
	var names := ["weights_tl", "weights_tr", "weights_bl", "weights_br"]
	for i in range(corners.size()):
		material.set_shader_parameter(names[i], _material_weights(corners[i]))
	painterly_surface.material = material
	add_child(painterly_surface)

func _build_identity_regions(size: float) -> void:
	if composition == null or composition.identity_regions.is_empty():
		return
	var world_origin := Vector2(float(chunk.get("worldX", 0)), float(chunk.get("worldY", 0)))
	var world_rect := Rect2(world_origin, Vector2.ONE * size)
	for region in composition.identity_regions:
		var center: Vector2 = region.get("position", Vector2.ZERO)
		# Una sola cella possiede la piattaforma. Le regioni sono più piccole del
		# raggio di streaming, quindi restano caricate quando entrano in camera.
		if not world_rect.has_point(center):
			continue
		var radii: Vector2 = region.get("radii", Vector2(320, 210))
		var root := Node2D.new()
		root.name = "IdentityRegion_%s" % str(region.get("id", "region"))
		root.position = center - world_origin
		root.rotation = float(region.get("rotation", 0.0))
		root.z_index = -7
		var kind := str(region.get("kind", "radura_clearing"))
		var outer := Polygon2D.new()
		outer.polygon = _organic_ellipse_points(radii * 1.10, center, 48)
		var inner := Polygon2D.new()
		inner.polygon = _organic_ellipse_points(radii, center + Vector2(31, -17), 48)
		if kind == "archive_room":
			outer.color = Color(0.08, 0.10, 0.18, 0.78)
			inner.color = Color(0.57, 0.55, 0.52, 0.32)
			root.add_child(outer)
			root.add_child(inner)
			_add_archive_floor_ornament(root, radii)
		elif kind == "radura_garden":
			outer.color = Color(0.14, 0.28, 0.16, 0.46)
			inner.color = Color(0.52, 0.58, 0.25, 0.26)
			root.add_child(outer)
			root.add_child(inner)
			_add_radial_floor_lines(root, radii, Color(0.78, 0.93, 0.48, 0.16), 10)
		else:
			outer.color = Color(0.30, 0.38, 0.17, 0.38)
			inner.color = Color(0.76, 0.65, 0.30, 0.14)
			root.add_child(outer)
			root.add_child(inner)
			_add_radial_floor_lines(root, radii, Color(1.0, 0.83, 0.42, 0.12), 12)
		add_child(root)

func _add_archive_floor_ornament(root: Node2D, radii: Vector2) -> void:
	for scale_value in [0.82, 0.58, 0.34]:
		var ring := Line2D.new()
		var ring_points := _organic_ellipse_points(radii * float(scale_value), Vector2(radii.x, radii.y) * float(scale_value), 40)
		ring_points.append(ring_points[0])
		ring.points = ring_points
		ring.width = 3.0 if float(scale_value) > 0.7 else 2.0
		ring.default_color = Color(0.86, 0.72, 0.39, 0.22)
		ring.antialiased = true
		root.add_child(ring)
	_add_radial_floor_lines(root, radii, Color(0.42, 0.63, 0.86, 0.20), 8)

func _add_radial_floor_lines(root: Node2D, radii: Vector2, color: Color, count: int) -> void:
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var line := Line2D.new()
		line.points = PackedVector2Array([
			Vector2(cos(angle) * radii.x * 0.20, sin(angle) * radii.y * 0.20),
			Vector2(cos(angle) * radii.x * 0.86, sin(angle) * radii.y * 0.86),
		])
		line.width = 1.5
		line.default_color = color
		line.antialiased = true
		root.add_child(line)

func _material_weights(world_pos: Vector2) -> Vector4:
	if composition == null:
		return _biome_material_weights(str(chunk.get("biome", "academy")))
	var weights := composition.biome_weights(world_pos)
	return Vector4(
		float(weights.get("academy", 0.0)),
		float(weights.get("wild", 0.0)),
		float(weights.get("geo", 0.0)) + float(weights.get("ruins", 0.0)),
		float(weights.get("logic", 0.0)) + float(weights.get("crystal", 0.0)))

func _biome_material_weights(biome: String) -> Vector4:
	match biome:
		"wild": return Vector4(0, 1, 0, 0)
		"geo", "ruins": return Vector4(0, 0, 1, 0)
		"logic", "crystal": return Vector4(0, 0, 0, 1)
		_: return Vector4(1, 0, 0, 0)

func _build_world_path_ribbons(size: float) -> void:
	if composition == null:
		return
	var world_origin := Vector2(float(chunk.get("worldX", 0)), float(chunk.get("worldY", 0)))
	var world_rect := Rect2(world_origin, Vector2.ONE * size).grow(96.0)
	var layer := Node2D.new()
	layer.name = "PainterlyPathRibbons"
	layer.z_index = -5
	add_child(layer)
	for path in composition.paths:
		var source_points: PackedVector2Array = path.get("points", PackedVector2Array())
		if source_points.size() < 2:
			continue
		var width := clampf(float(path.get("width", 64.0)) * 0.39, 20.0, 29.0)
		if not world_rect.intersects(_points_bounds(source_points).grow(width * 2.0)):
			continue
		var steps_per_segment := 7
		var curved_world := _catmull_rom_polyline(source_points, steps_per_segment)
		# Ogni segmento ha un unico chunk proprietario. Prima tutti i chunk che lo
		# vedevano ridisegnavano l'intera spline, sommando opacita e saturazione.
		for segment_index in range(source_points.size() - 1):
			var midpoint := source_points[segment_index].lerp(source_points[segment_index + 1], 0.5)
			var owner := Vector2i(floori(midpoint.x / size), floori(midpoint.y / size))
			if owner != Vector2i(int(chunk.get("chunkX", 0)), int(chunk.get("chunkY", 0))):
				continue
			var segment_world := PackedVector2Array()
			var first := segment_index * steps_per_segment
			var last := mini(first + steps_per_segment, curved_world.size() - 1)
			for point_index in range(first, last + 1):
				segment_world.append(curved_world[point_index])
			_add_path_ribbon(layer, _offset_points(segment_world, -world_origin), width)

func _add_path_ribbon(layer: Node2D, curved: PackedVector2Array, width: float) -> void:
	if curved.size() < 2:
		return
	var bank := Line2D.new()
	bank.points = curved
	bank.width = width + 9.0
	bank.default_color = Color(0.31, 0.30, 0.18, 0.22)
	bank.joint_mode = Line2D.LINE_JOINT_ROUND
	bank.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bank.end_cap_mode = Line2D.LINE_CAP_ROUND
	bank.antialiased = true
	layer.add_child(bank)
	var soil := Line2D.new()
	soil.points = curved
	soil.width = width
	soil.texture = PATH_EARTH_TEXTURE
	soil.texture_mode = Line2D.LINE_TEXTURE_TILE
	soil.default_color = Color(0.72, 0.68, 0.53, 0.62)
	soil.joint_mode = Line2D.LINE_JOINT_ROUND
	soil.begin_cap_mode = Line2D.LINE_CAP_ROUND
	soil.end_cap_mode = Line2D.LINE_CAP_ROUND
	soil.antialiased = true
	layer.add_child(soil)
	var highlight := Line2D.new()
	highlight.points = curved
	highlight.width = maxf(1.5, width * 0.055)
	highlight.default_color = Color(1.0, 0.91, 0.68, 0.08)
	highlight.antialiased = true
	layer.add_child(highlight)

func _curved_segment(a: Vector2, b: Vector2, world_origin: Vector2, segment_index: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var delta := b - a
	var normal := Vector2(-delta.y, delta.x).normalized()
	var phase := sin((a.x * 0.0067) + (a.y * 0.0049) + float(segment_index) * 1.71)
	var bend := phase * minf(delta.length() * 0.10, 82.0)
	for step in range(13):
		var t := float(step) / 12.0
		var easing := 4.0 * t * (1.0 - t)
		points.append(a.lerp(b, t) + normal * bend * easing - world_origin)
	return points

func _build_world_water_features(size: float) -> void:
	if composition == null:
		return
	var world_origin := Vector2(float(chunk.get("worldX", 0)), float(chunk.get("worldY", 0)))
	var world_rect := Rect2(world_origin, Vector2.ONE * size)
	for water in composition.waters:
		if str(water.get("kind", "pond")) == "stream":
			_build_stream_feature(water, world_origin, world_rect)
			continue
		var center: Vector2 = water["position"]
		# The center cell owns the full visual. Active-radius streaming keeps that
		# cell loaded whenever the player can see the feature.
		if not world_rect.has_point(center):
			continue
		var radii: Vector2 = water["radii"]
		var root := Node2D.new()
		root.name = "PainterlyWater_%s" % str(water.get("id", "water"))
		root.position = center - world_origin
		root.z_index = -4
		var outer_points := _organic_ellipse_points(radii * 1.12, center, 52)
		var inner_points := _organic_ellipse_points(radii, center, 52)
		var bank := Polygon2D.new()
		bank.polygon = outer_points
		bank.color = Color(0.25, 0.34, 0.17, 0.96)
		root.add_child(bank)
		var shore := Line2D.new()
		var shore_points := inner_points.duplicate()
		shore_points.append(inner_points[0])
		shore.points = shore_points
		shore.width = 18.0
		shore.default_color = Color(0.58, 0.59, 0.34, 0.82)
		shore.joint_mode = Line2D.LINE_JOINT_ROUND
		shore.antialiased = true
		root.add_child(shore)
		var surface := Polygon2D.new()
		surface.polygon = inner_points
		surface.texture = WATER_POND_TEXTURE
		var water_texture_size := WATER_POND_TEXTURE.get_size()
		var water_uv := PackedVector2Array()
		for point in inner_points:
			var normalized := (point + radii) / (radii * 2.0)
			water_uv.append(normalized * water_texture_size)
		surface.uv = water_uv
		var material := ShaderMaterial.new()
		material.shader = PAINTERLY_WATER_SHADER
		material.set_shader_parameter("water_tex", WATER_POND_TEXTURE)
		material.set_shader_parameter("surface_world_origin", center - radii)
		material.set_shader_parameter("surface_world_size", radii * 2.0)
		surface.material = material
		root.add_child(surface)
		add_child(root)

func _build_stream_feature(water: Dictionary, world_origin: Vector2, world_rect: Rect2) -> void:
	var source_points: PackedVector2Array = water.get("points", PackedVector2Array())
	if source_points.size() < 2:
		return
	var width := float(water.get("width", 200.0))
	var source_bounds := _points_bounds(source_points).grow(width)
	if not world_rect.grow(96.0).intersects(source_bounds):
		return
	# Ogni chunk visibile che interseca il corso ricostruisce la stessa sagoma
	# globale. Le copie coincidono al pixel, quindi lo streaming non apre tagli.
	var smooth_centerline := _catmull_rom_polyline(source_points, 8)
	var inner_world := _stream_ribbon_points(smooth_centerline, width * 0.5)
	var outer_world := _stream_ribbon_points(smooth_centerline, width * 0.5 + 28.0)
	var root := Node2D.new()
	root.name = "PainterlyStream_%s" % str(water.get("id", "stream"))
	root.z_index = -4
	var outer_local := _offset_points(outer_world, -world_origin)
	var inner_local := _offset_points(inner_world, -world_origin)
	var bank := Polygon2D.new()
	bank.polygon = outer_local
	bank.color = Color(0.20, 0.29, 0.14, 0.98)
	root.add_child(bank)
	var shore := Line2D.new()
	var shore_points := inner_local.duplicate()
	shore_points.append(inner_local[0])
	shore.points = shore_points
	shore.width = 17.0
	shore.default_color = Color(0.56, 0.59, 0.34, 0.82)
	shore.joint_mode = Line2D.LINE_JOINT_ROUND
	shore.antialiased = true
	root.add_child(shore)
	var surface := Polygon2D.new()
	surface.polygon = inner_local
	surface.texture = WATER_POND_TEXTURE
	var bounds := _points_bounds(inner_world)
	var texture_size := WATER_POND_TEXTURE.get_size()
	var water_uv := PackedVector2Array()
	for point in inner_world:
		water_uv.append((point - bounds.position) / bounds.size * texture_size)
	surface.uv = water_uv
	var material := ShaderMaterial.new()
	material.shader = PAINTERLY_WATER_SHADER
	material.set_shader_parameter("water_tex", WATER_POND_TEXTURE)
	material.set_shader_parameter("surface_world_origin", bounds.position)
	material.set_shader_parameter("surface_world_size", bounds.size)
	material.set_shader_parameter("edge_glow_strength", 0.035)
	surface.material = material
	root.add_child(surface)
	add_child(root)

func _catmull_rom_polyline(source: PackedVector2Array, steps_per_segment: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(source.size() - 1):
		var p0 := source[maxi(index - 1, 0)]
		var p1 := source[index]
		var p2 := source[index + 1]
		var p3 := source[mini(index + 2, source.size() - 1)]
		for step in range(steps_per_segment):
			var t := float(step) / float(steps_per_segment)
			var t2 := t * t
			var t3 := t2 * t
			result.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	result.append(source[source.size() - 1])
	return result

func _stream_ribbon_points(centerline: PackedVector2Array, half_width: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(centerline.size()):
		var previous := centerline[maxi(index - 1, 0)]
		var following := centerline[mini(index + 1, centerline.size() - 1)]
		var tangent := (following - previous).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var undulation := 1.0 + sin(float(index) * 0.73 + centerline[index].x * 0.0031) * 0.055
		left.append(centerline[index] + normal * half_width * undulation)
		right.append(centerline[index] - normal * half_width * (2.0 - undulation))
	var polygon := left
	for index in range(right.size() - 1, -1, -1):
		polygon.append(right[index])
	return polygon

func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result

func _points_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum = Vector2(minf(minimum.x, point.x), minf(minimum.y, point.y))
		maximum = Vector2(maxf(maximum.x, point.x), maxf(maximum.y, point.y))
	return Rect2(minimum, Vector2(maxf(1.0, maximum.x - minimum.x), maxf(1.0, maximum.y - minimum.y)))

func _organic_ellipse_points(radii: Vector2, seed_point: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var phase := seed_point.x * 0.0071 + seed_point.y * 0.0043
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		var wobble := 1.0 + sin(angle * 5.0 + phase) * 0.035 + sin(angle * 9.0 - phase) * 0.018
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y) * wobble)
	return points

func _prepare_composition_masks(size: float) -> void:
	corridor_points.clear()
	anchor_points.clear()
	var world_x := float(chunk.get("worldX", 0))
	var world_y := float(chunk.get("worldY", 0))
	for point in chunk.get("pathPoints", []):
		corridor_points.append(Vector2(float(point.get("x", 0)) - world_x, float(point.get("y", 0)) - world_y))
	for key in ["obstacles", "props", "landmarks", "treasures", "encounters"]:
		for item in chunk.get(key, []):
			anchor_points.append(Vector2(float(item.get("x", world_x)) - world_x, float(item.get("y", world_y)) - world_y))

func _biome_palette_tint(biome: String) -> Color:
	# Palette percettiva condivisa: il patch procedurale resta la base, questi
	# colori stabilizzano temperatura e leggibilità tra chunk adiacenti.
	match biome:
		"academy": return Color("5e7545")
		"wild": return Color("315f42")
		"geo": return Color("3c7864")
		"logic": return Color("3f4f78")
		"ruins": return Color("604a56")
		"crystal": return Color("4b4f8c")
		_: return Color("3d5a48")

func _biome_palette_accent(biome: String) -> Color:
	match biome:
		"academy": return Color("f2c66d")
		"wild": return Color("7fe0a7")
		"geo": return Color("79d8d0")
		"logic": return Color("b4a7ff")
		"ruins": return Color("f0a080")
		"crystal": return Color("d6c8ff")
		_: return Color("9fe0c3")

func _biome_density(biome: String) -> float:
	match biome:
		"academy": return 0.92
		"wild": return 1.18
		"geo": return 0.86
		"ruins": return 0.68
		"logic": return 0.76
		"crystal": return 0.58
		_: return 0.85

func _is_composition_clear(pos: Vector2, radius: float = 0.0) -> bool:
	for point in corridor_points:
		if pos.distance_to(point) < 58.0 + radius:
			return true
	for point in anchor_points:
		if pos.distance_to(point) < 48.0 + radius:
			return true
	return false

func _draw() -> void:
	var size := float(chunk.get("size", 896))
	var patch: Dictionary = chunk.get("patch", {})
	var biome := str(chunk.get("biome", "academy"))
	var tint := _hex_color(int(patch.get("color", 0x173b36))).lerp(_biome_palette_tint(biome), 0.22)
	var accent := _hex_color(int(patch.get("accent", 0x6be7d6))).lerp(_biome_palette_accent(biome), 0.18)
	# Tinta quasi impercettibile: un overlay pieno al 28% rendeva visibili i
	# rettangoli tecnici dei chunk sui biomi scuri. La palette resta leggibile
	# ma il bordo non viene più percepito come una griglia.
	if composition != null:
		_draw_composition_surface(size)
	if academy_focus and composition == null:
		_draw_academy_composition(size, tint)
	elif biome == "academy" and composition == null:
		# I chunk accanto alla Radura ricevono la stessa temperatura cromatica
		# del vertical slice. In questo modo la camera può attraversare il bordo
		# senza il salto netto fra hero dorato e terreno blu-verde del prototipo.
		_draw_academy_peripheral_composition(size, tint, accent)
	elif composition == null:
		_draw_biome_motif(size, tint, accent)
	if composition == null and not academy_focus and _is_academy_neighbor():
		_draw_academy_neighbor_transition(size, accent)

	if composition == null:
		for blotch in blotches:
			if _is_composition_clear(blotch["pos"], blotch["radius"] * 0.35):
				continue
			draw_circle(blotch["pos"], blotch["radius"], Color(tint.darkened(0.3), blotch["alpha"]))

	# I punti di percorso restano nel contratto procedurale, ma non disegniamo
	# più linee fino ai bordi del chunk: erano percepite come una griglia visiva.
	if composition == null:
		_draw_meadow_clearing(size, tint)

	for speckle in speckles:
		if _is_composition_clear(speckle["pos"], 2.0):
			continue
		draw_circle(speckle["pos"], speckle["radius"], speckle["color"])

	for tuft in tufts:
		var base: Vector2 = tuft["pos"]
		if _is_composition_clear(base, 3.0):
			continue
		var height: float = tuft["height"]
		var color: Color = tuft["color"]
		draw_line(base, base + Vector2(-1.8, -height), color, 1.3, true)
		draw_line(base + Vector2(1.0, 0), base + Vector2(2.8, -height * 0.78), color, 1.1, true)

	for blossom in blossom_clusters:
		var blossom_pos: Vector2 = blossom["pos"]
		if _is_composition_clear(blossom_pos, 5.0):
			continue
		var blossom_radius: float = blossom["radius"]
		var blossom_color: Color = blossom["color"]
		# Tre piccoli fiori vicini creano ciuffi leggibili, non punti casuali.
		draw_circle(blossom_pos, blossom_radius, blossom_color)
		draw_circle(blossom_pos + Vector2(blossom_radius * 1.25, -blossom_radius * 0.55), blossom_radius * 0.72, blossom_color)
		draw_circle(blossom_pos + Vector2(-blossom_radius * 1.1, -blossom_radius * 0.35), blossom_radius * 0.68, blossom_color)

func _draw_composition_surface(_size: float) -> void:
	# Surface, paths and water are child materials in absolute world space.
	# Keeping this hook makes legacy calls harmless while removing circle splats.
	pass

func _draw_owned_global_features(world_rect: Rect2, world_origin: Vector2) -> void:
	# Ogni feature globale ha un solo chunk proprietario e può debordare nel
	# vicino: niente duplicazione alpha e nessuna giunzione sul confine.
	for water in composition.waters:
		var center: Vector2 = water["position"]
		var radii: Vector2 = water["radii"]
		var water_bounds := Rect2(center - radii * 1.18, radii * 2.36)
		if not world_rect.grow(32.0).intersects(water_bounds):
			continue
		var local := center - world_origin
		draw_set_transform(local, -0.08, Vector2(radii.x / 120.0, radii.y / 120.0))
		draw_circle(Vector2.ZERO, 132.0, Color(0.24, 0.31, 0.20, 0.30))
		draw_circle(Vector2.ZERO, 120.0, Color(0.13, 0.55, 0.58, 0.88))
		draw_circle(Vector2(-22, -24), 78.0, Color(0.45, 0.85, 0.77, 0.30))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_academy_peripheral_composition(size: float, tint: Color, accent: Color) -> void:
	# Fascia di raccordo per i chunk non hero: colori caldi, radure morbide e
	# piccoli gruppi naturali. È solo pittura sul terreno, senza collisioni.
	draw_rect(Rect2(Vector2(-18, -18), Vector2(size + 36.0, size + 36.0)), Color(0.48, 0.54, 0.25, 0.08))
	var warm := Color(0.78, 0.62, 0.32, 0.16)
	for point in [
		Vector2(size * 0.12, size * 0.18),
		Vector2(size * 0.82, size * 0.26),
		Vector2(size * 0.22, size * 0.76),
		Vector2(size * 0.78, size * 0.82),
	]:
		if _is_composition_clear(point, 24.0):
			continue
		draw_set_transform(point, -0.12, Vector2(1.5, 0.54))
		draw_circle(Vector2.ZERO, 82.0, Color(0.28, 0.45, 0.22, 0.18))
		draw_circle(Vector2(-18, -5), 50.0, warm)
		draw_circle(Vector2(25, 6), 34.0, Color(accent, 0.10))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for petal in [Vector2(-28, -12), Vector2(-4, -20), Vector2(18, -10), Vector2(8, 12)]:
			draw_circle(point + petal, 3.2, Color(1.0, 0.84, 0.48, 0.58))
			draw_circle(point + petal + Vector2(4, -2), 2.2, Color(1.0, 0.96, 0.72, 0.48))

	# Nebbia calda sui bordi: riduce il contrasto percepito fra due superfici
	# adiacenti mentre il giocatore attraversa il raccordo.
	draw_rect(Rect2(-18, 0, 34, size), Color(0.62, 0.54, 0.28, 0.12))
	draw_rect(Rect2(size - 16, 0, 34, size), Color(0.62, 0.54, 0.28, 0.12))
	draw_rect(Rect2(0, -18, size, 34), Color(0.62, 0.54, 0.28, 0.08))
	draw_rect(Rect2(0, size - 16, size, 34), Color(0.62, 0.54, 0.28, 0.08))

func _draw_academy_focus_transition(size: float) -> void:
	# Il fondale hero è più luminoso dei chunk procedurali. Quattro fasce
	# sovrapposte, decrescenti verso il centro, trasformano il bordo tecnico in
	# una vignetta naturale senza introdurre una linea visibile.
	var edge := Color(0.09, 0.18, 0.16, 0.0)
	for i in range(5):
		var t := float(i) / 4.0
		var alpha := 0.15 - t * 0.11
		var inset := float(i) * 16.0
		edge.a = alpha
		draw_rect(Rect2(-18.0 + inset, -18.0, 18.0, size + 36.0), edge)
		draw_rect(Rect2(size - inset - 18.0, -18.0, 18.0, size + 36.0), edge)
		draw_rect(Rect2(-18.0, -18.0 + inset, size + 36.0, 18.0), edge)
		draw_rect(Rect2(-18.0, size - inset - 18.0, size + 36.0, 18.0), edge)

func _is_academy_neighbor() -> bool:
	var x := int(chunk.get("chunkX", 99))
	var y := int(chunk.get("chunkY", 99))
	return (abs(x) + abs(y)) == 1

func _draw_academy_neighbor_transition(size: float, accent: Color) -> void:
	# Solo i quattro chunk adiacenti alla Radura ricevono una fascia di
	# transizione. La tinta è confinata al bordo rivolto verso (0,0), così il
	# bioma mantiene la propria identità ma non crea una cucitura verticale.
	var x := int(chunk.get("chunkX", 99))
	var y := int(chunk.get("chunkY", 99))
	var warm := Color(0.78, 0.62, 0.32, 0.16)
	if x < 0:
		draw_rect(Rect2(size - 86.0, -18, 104, size + 36), Color(0.64, 0.55, 0.30, 0.16))
		draw_set_transform(Vector2(size - 22.0, size * 0.52), -0.1, Vector2(1.0, 0.54))
		draw_circle(Vector2.ZERO, 142.0, warm)
	elif x > 0:
		draw_rect(Rect2(-18, -18, 104, size + 36), Color(0.64, 0.55, 0.30, 0.16))
		draw_set_transform(Vector2(22.0, size * 0.52), 0.1, Vector2(1.0, 0.54))
		draw_circle(Vector2.ZERO, 142.0, warm)
	elif y < 0:
		draw_rect(Rect2(-18, size - 86.0, size + 36, 104), Color(0.64, 0.55, 0.30, 0.13))
		draw_set_transform(Vector2(size * 0.52, size - 22.0), 0.0, Vector2(1.25, 0.58))
		draw_circle(Vector2.ZERO, 142.0, warm)
	else:
		draw_rect(Rect2(-18, -18, size + 36, 104), Color(0.64, 0.55, 0.30, 0.13))
		draw_set_transform(Vector2(size * 0.52, 22.0), 0.0, Vector2(1.25, 0.58))
		draw_circle(Vector2.ZERO, 142.0, warm)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Pochi riflessi dell'accento locale fanno leggere il raccordo come un
	# bordo naturale, non come una maschera di colore uniforme.
	for i in range(5):
		var t := float(i) / 4.0
		var pos: Vector2
		if x != 0:
			pos = Vector2(size - 26.0 if x < 0 else 26.0, 116.0 + t * (size - 232.0))
		else:
			pos = Vector2(116.0 + t * (size - 232.0), size - 26.0 if y < 0 else 26.0)
		draw_circle(pos, 2.8 + fmod(float(i), 2.0), Color(accent, 0.28))

func _draw_biome_motif(size: float, tint: Color, accent: Color) -> void:
	var biome := str(chunk.get("biome", "academy"))
	for point in motif_points:
		if _is_composition_clear(point, 30.0):
			continue
		match biome:
			"academy":
				draw_set_transform(point, -0.1, Vector2(1.4, 0.55))
				draw_circle(Vector2.ZERO, 32.0, Color(0.18, 0.38, 0.21, 0.25))
				draw_circle(Vector2(-12, -3), 4.0, Color(1.0, 0.78, 0.42, 0.72))
				draw_circle(Vector2(10, 3), 3.2, Color(1.0, 0.95, 0.72, 0.65))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"wild":
				draw_set_transform(point, -0.12, Vector2(1.5, 0.58))
				draw_circle(Vector2.ZERO, 38.0, Color(0.08, 0.26, 0.16, 0.34))
				draw_circle(Vector2(16, 4), 18.0, Color(0.16, 0.40, 0.22, 0.4))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for blade in range(6):
					var base := point + Vector2(-20.0 + blade * 7.0, 8.0)
					draw_line(base, base + Vector2(-5.0 + blade * 1.5, -22.0), Color(accent, 0.52), 2.2, true)
				for berry in [Vector2(-16, -10), Vector2(4, -16), Vector2(20, -5)]:
					draw_circle(point + berry, 3.4, Color(0.68, 0.22, 0.33, 0.72))
			"geo":
				draw_set_transform(point, -0.08, Vector2(1.55, 0.62))
				draw_circle(Vector2.ZERO, 38.0, Color(0.08, 0.27, 0.28, 0.34))
				draw_circle(Vector2.ZERO, 30.0, Color(0.14, 0.52, 0.56, 0.52))
				draw_arc(Vector2.ZERO, 25.0, 0.2, 2.8, 24, Color(accent, 0.7), 3.0, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for stone in [Vector2(-28, 14), Vector2(-9, 20), Vector2(14, 16), Vector2(31, 7)]:
					draw_circle(point + stone, 5.0, Color(0.66, 0.68, 0.54, 0.58))
			"logic":
				draw_set_transform(point, 0.0, Vector2(1.0, 0.42))
				draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 6, Color(accent, 0.48), 4.0, true)
				draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 6, Color(0.58, 0.47, 0.78, 0.42), 3.0, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var diamond := PackedVector2Array([point + Vector2(0, -13), point + Vector2(13, 0), point + Vector2(0, 13), point + Vector2(-13, 0)])
				draw_colored_polygon(diamond, Color(accent, 0.22))
			"ruins":
				draw_set_transform(point, -0.1, Vector2(1.25, 0.52))
				draw_circle(Vector2.ZERO, 40.0, Color(0.11, 0.09, 0.14, 0.38))
				draw_arc(Vector2.ZERO, 31.0, 0.25, 2.45, 18, Color(0.50, 0.42, 0.48, 0.6), 8.0, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for moss in [Vector2(-21, 6), Vector2(9, 18), Vector2(25, -4)]:
					draw_circle(point + moss, 4.0, Color(0.30, 0.52, 0.30, 0.58))
			"crystal":
				var glow := Color(accent, 0.22)
				draw_circle(point, 42.0, glow)
				var crystal := PackedVector2Array([point + Vector2(0, -34), point + Vector2(18, 0), point + Vector2(0, 26), point + Vector2(-18, 0)])
				draw_colored_polygon(crystal, Color(accent, 0.42))
				var facet := PackedVector2Array([point + Vector2(0, -25), point + Vector2(9, 0), point + Vector2(0, 13)])
				draw_colored_polygon(facet, Color(0.88, 0.96, 1.0, 0.45))

func _draw_meadow_clearing(size: float, tint: Color) -> void:
	# Radura morbida al centro: lega visivamente gli elementi vicini senza
	# introdurre segmenti rettilinei o giunzioni sui bordi dei chunk.
	var center := Vector2(size * 0.5, size * 0.5)
	var clearing := Color(tint.lightened(0.16), 0.055)
	draw_set_transform(center, -0.08, Vector2(1.35, 0.62))
	draw_circle(Vector2.ZERO, size * 0.27, clearing)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _prepare_academy_composition(decor, size: float) -> void:
	# Piccoli jitter seedati impediscono che la scena sembri un template rigido,
	# ma la grammatica resta leggibile a ogni caricamento.
	var j1 := Vector2((decor.next_float() - 0.5) * 18.0, (decor.next_float() - 0.5) * 14.0)
	var j2 := Vector2((decor.next_float() - 0.5) * 16.0, (decor.next_float() - 0.5) * 12.0)
	var j3 := Vector2((decor.next_float() - 0.5) * 14.0, (decor.next_float() - 0.5) * 12.0)
	var center := Vector2(size * 0.5, size * 0.51)
	# Un anello di sentieri organici: nessun segmento segue i bordi del chunk,
	# quindi non viene percepito come griglia tecnica.
	academy_paths = [
		PackedVector2Array([
			Vector2(78, 818), Vector2(126, 738), Vector2(232, 668),
			Vector2(350, 622), center + Vector2(-48, 30), center + Vector2(18, -2),
			Vector2(628, 390), Vector2(742, 304), Vector2(820, 240),
		]),
		PackedVector2Array([
			Vector2(56, 260), Vector2(144, 278), Vector2(226, 320),
			Vector2(292, 390), center + Vector2(-48, 30),
		]),
		PackedVector2Array([
			center + Vector2(18, -2), Vector2(500, 342), Vector2(536, 242),
			Vector2(626, 176), Vector2(748, 124),
		]),
	]
	academy_gardens = [
		Vector2(118, 182) + j1, Vector2(344, 190) + j2,
		Vector2(714, 274) + j3, Vector2(762, 586) + j1,
		Vector2(284, 748) + j2,
	]
	academy_stones = [
		Vector2(136, 731), Vector2(185, 687), Vector2(254, 649), Vector2(326, 617),
		Vector2(409, 574), Vector2(484, 510), Vector2(564, 444), Vector2(645, 375),
		Vector2(720, 319), Vector2(786, 270),
	]

func _draw_academy_composition(size: float, tint: Color) -> void:
	# Un velo più caldo evita il fondale blu-verde uniforme del prototipo e
	# avvicina la Radura alla luce dorata del modello di riferimento.
	draw_rect(Rect2(Vector2(-18, -18), Vector2(size + 36.0, size + 36.0)), Color(0.52, 0.60, 0.28, 0.13))

	# Sentieri a tre strati: bordo morbido, sabbia calda e riflesso centrale.
	for path in academy_paths:
		draw_polyline(path, Color(0.16, 0.12, 0.07, 0.22), 70.0, true)
		draw_polyline(path, Color(0.76, 0.56, 0.28, 0.66), 52.0, true)
		draw_polyline(path, Color(1.0, 0.86, 0.54, 0.24), 11.0, true)

	for stone in academy_stones:
		draw_circle(stone, 7.0, Color(0.82, 0.70, 0.46, 0.34))
		draw_circle(stone + Vector2(-1.5, -1.5), 3.2, Color(1.0, 0.9, 0.66, 0.26))

	# Laghetto principale e sponda: la forma ovale è leggibile anche con la
	# camera zoomata e dà un punto focale al lato sinistro della radura.
	var pond := Vector2(192, 432)
	draw_set_transform(pond, -0.13, Vector2(1.42, 0.72))
	draw_circle(Vector2.ZERO, 118.0, Color(0.12, 0.27, 0.22, 0.38))
	draw_circle(Vector2.ZERO, 104.0, Color(0.12, 0.52, 0.53, 0.80))
	draw_circle(Vector2(-18, -22), 76.0, Color(0.27, 0.75, 0.70, 0.38))
	draw_circle(Vector2(-25, -30), 38.0, Color(0.75, 0.97, 0.76, 0.20))
	draw_arc(Vector2.ZERO, 108.0, 0.0, TAU, 48, Color(0.72, 0.72, 0.45, 0.56), 13.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for bank_pos in [Vector2(106, 408), Vector2(127, 502), Vector2(224, 533), Vector2(285, 432), Vector2(245, 348), Vector2(142, 344)]:
		draw_circle(bank_pos, 10.0, Color(0.48, 0.52, 0.34, 0.64))
		draw_circle(bank_pos + Vector2(-2, -3), 5.0, Color(0.76, 0.72, 0.48, 0.42))

	# Cortile della fontana, con anelli concentrici in pietra e acqua luminosa.
	var courtyard := Vector2(size * 0.53, size * 0.51)
	draw_set_transform(courtyard, 0.0, Vector2(1.34, 0.62))
	draw_circle(Vector2.ZERO, 96.0, Color(0.26, 0.34, 0.22, 0.20))
	draw_circle(Vector2.ZERO, 78.0, Color(0.83, 0.68, 0.38, 0.34))
	draw_circle(Vector2.ZERO, 62.0, Color(0.92, 0.77, 0.44, 0.44))
	draw_circle(Vector2.ZERO, 45.0, Color(0.18, 0.54, 0.49, 0.70))
	draw_circle(Vector2(-10, -11), 17.0, Color(0.51, 0.94, 0.77, 0.64))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(courtyard + Vector2(0, -42), 10.0, Color(0.74, 1.0, 0.80, 0.44))

	# Isole di fiori/vegetazione: masse più ampie e raggruppate al posto di
	# punti isolati. Sono solo pittura sul terreno, non nascondono collisioni.
	for garden in academy_gardens:
		draw_set_transform(garden, -0.1, Vector2(1.45, 0.54))
		draw_circle(Vector2.ZERO, 42.0, Color(0.14, 0.33, 0.20, 0.32))
		draw_circle(Vector2(-13, -4), 24.0, Color(0.30, 0.54, 0.26, 0.44))
		draw_circle(Vector2(17, 2), 22.0, Color(0.39, 0.62, 0.28, 0.38))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for petal_offset in [Vector2(-22, -10), Vector2(-4, -18), Vector2(15, -8), Vector2(7, 10)]:
			draw_circle(garden + petal_offset, 4.0, Color(0.98, 0.78, 0.42, 0.72))
			draw_circle(garden + petal_offset + Vector2(4, -2), 2.8, Color(0.98, 0.96, 0.74, 0.64))

	# Bordo foreground morbido: incornicia la scena senza creare una barriera.
	for x in range(24, int(size) - 20, 44):
		var sway := sin(float(x) * 0.035) * 8.0
		draw_circle(Vector2(float(x), size - 18.0 + sway), 19.0, Color(0.13, 0.31, 0.18, 0.34))
		draw_circle(Vector2(float(x) + 12.0, size - 33.0 + sway), 12.0, Color(0.31, 0.52, 0.24, 0.42))

func _hex_color(rgb: int) -> Color:
	return Color(
		float((rgb >> 16) & 0xFF) / 255.0,
		float((rgb >> 8) & 0xFF) / 255.0,
		float(rgb & 0xFF) / 255.0,
	)
