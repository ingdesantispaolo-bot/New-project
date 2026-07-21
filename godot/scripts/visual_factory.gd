class_name OutdoorVisualFactory
extends RefCounted

## Costruttori statici dei visual procedurali del mondo esterno.
## SOLO estetica: nessuna estrazione dall'RNG di generazione (la parità con il
## generatore TypeScript resta intatta); le variazioni arrivano dal parametro
## `variant` (0..1) fornito dal chiamante con un RNG decorativo separato.
##
## Convenzioni:
## - ogni builder restituisce un Node2D ancorato alla base dell'oggetto
##   (l'ombra sta vicino a y=0, il corpo si sviluppa verso y negative),
##   così l'y-sort con il player risulta naturale;
## - i bagliori che devono accendersi di notte sono nel gruppo "night_glow":
##   outdoor_world ne modula l'alpha in base alla luce del giorno.

const AmbientAnim := preload("res://scripts/ambient_anim.gd")
const TREASURE_TEXTURE: Texture2D = preload("res://assets/academy-treasure.svg")
const ENCOUNTER_TEXTURE: Texture2D = preload("res://assets/academy-encounter.svg")
const OUTDOOR_SHEET: Texture2D = preload("res://assets/outdoor-world-sheet.png")
const PLAYER_SHEET: Texture2D = preload("res://assets/eli-robot-girl-sheet.png")
const ACADEMY_NATURAL_ATLAS: Texture2D = preload("res://assets/radura-academia-natural-atlas-v2.png")
const WILD_NATURAL_ATLAS: Texture2D = preload("res://assets/bosco-variabile-natural-atlas-v2.png")
const GEO_NATURAL_ATLAS: Texture2D = preload("res://assets/dorsale-geografica-natural-atlas-v2.png")
const LOGIC_NATURAL_ATLAS: Texture2D = preload("res://assets/cratere-logico-natural-atlas-v2.png")
const NATURAL_DETAIL_ATLAS: Texture2D = preload("res://assets/natural-detail-atlas-v1.png")

const NATURAL_DETAIL_CELLS := {
	"reeds": Vector2i(0, 0), "cattails": Vector2i(1, 0),
	"lilies": Vector2i(2, 0), "water_flowers": Vector2i(3, 0),
	"fern": Vector2i(0, 1), "grass": Vector2i(1, 1),
	"wildflowers": Vector2i(2, 1), "leaves": Vector2i(3, 1),
	"pebble_bank": Vector2i(0, 2), "driftwood": Vector2i(1, 2),
	"stump": Vector2i(2, 2), "stepping_stones": Vector2i(3, 2),
	"mushrooms": Vector2i(0, 3), "crystal_moss": Vector2i(1, 3),
	"glow_flowers": Vector2i(2, 3), "rune_pebbles": Vector2i(3, 3),
}

const ENCOUNTER_COLORS := {
	"times": Color("f6c85f"),
	"mental": Color("9f8cff"),
	"capital": Color("ff8f6b"),
	"physicalGeo": Color("8fe0a4"),
	"guardian": Color("ff6b7a"),
}

static var _glow_texture: Texture2D
static var _add_material: CanvasItemMaterial

static func outdoor_sprite(frame_name: String, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	var regions := {
		"tree": Rect2(0, 0, 132, 132), "pine": Rect2(140, 0, 120, 148),
		"bush": Rect2(268, 0, 124, 92), "flower": Rect2(400, 0, 132, 88),
		"rock": Rect2(540, 0, 116, 76), "crystal": Rect2(664, 0, 132, 132),
		"ruin": Rect2(804, 0, 108, 148), "lamp": Rect2(920, 0, 96, 152),
		"bridge": Rect2(0, 160, 156, 72), "pond": Rect2(164, 160, 164, 104),
		"bench": Rect2(336, 160, 132, 86), "sun": Rect2(476, 160, 104, 104),
		"dust": Rect2(588, 160, 118, 92), "wisp": Rect2(714, 160, 104, 116),
		"shadow": Rect2(826, 160, 126, 86), "beacon": Rect2(0, 284, 112, 128),
	}
	if not regions.has(frame_name):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = OUTDOOR_SHEET
	atlas.region = regions[frame_name]
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position.y = y
	sprite.scale = target_size / atlas.region.size
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

static func player_sprite(target_size: Vector2 = Vector2(58, 58)) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_SHEET
	atlas.region = Rect2(0, 0, 96, 96)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = target_size / atlas.region.size
	sprite.position = Vector2(0, -17)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

static func natural_atlas_sprite(texture: Texture2D, cell: Vector2i, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(cell.x * 362, cell.y * 362, 362, 362)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position.y = y
	sprite.scale = target_size / atlas.region.size
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

static func academy_natural_sprite(cell: Vector2i, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	return natural_atlas_sprite(ACADEMY_NATURAL_ATLAS, cell, target_size, y)

static func wild_natural_sprite(cell: Vector2i, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	return natural_atlas_sprite(WILD_NATURAL_ATLAS, cell, target_size, y)

static func geo_natural_sprite(cell: Vector2i, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	return natural_atlas_sprite(GEO_NATURAL_ATLAS, cell, target_size, y)

static func logic_natural_sprite(cell: Vector2i, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	return natural_atlas_sprite(LOGIC_NATURAL_ATLAS, cell, target_size, y)

static func natural_detail_sprite(kind: String, target_size: Vector2, y: float = 0.0) -> Sprite2D:
	if not NATURAL_DETAIL_CELLS.has(kind):
		return null
	var cell: Vector2i = NATURAL_DETAIL_CELLS[kind]
	var atlas := AtlasTexture.new()
	atlas.atlas = NATURAL_DETAIL_ATLAS
	# L'atlante AI e' intenzionalmente indipendente dalla risoluzione: il crop
	# deriva dai quattro quadranti, evitando costanti fragili nei futuri refresh.
	var cell_size := NATURAL_DETAIL_ATLAS.get_size() / 4.0
	atlas.region = Rect2(Vector2(cell) * cell_size, cell_size)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position.y = y
	sprite.scale = target_size / cell_size
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

# ---------------------------------------------------------------------------
# Risorse condivise
# ---------------------------------------------------------------------------

static func glow_texture() -> Texture2D:
	if _glow_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0.0)])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 64
		texture.height = 64
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		_glow_texture = texture
	return _glow_texture

static func add_material() -> CanvasItemMaterial:
	if _add_material == null:
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add_material = material
	return _add_material

# ---------------------------------------------------------------------------
# Primitive
# ---------------------------------------------------------------------------

static func hex_color(rgb: int) -> Color:
	return Color(
		float((rgb >> 16) & 0xFF) / 255.0,
		float((rgb >> 8) & 0xFF) / 255.0,
		float(rgb & 0xFF) / 255.0,
	)

static func circle_polygon(radius: float, segments: int = 18) -> PackedVector2Array:
	return ellipse_polygon(radius, radius, segments)

static func ellipse_polygon(rx: float, ry: float, segments: int = 18) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	return points

static func make_polygon(points: PackedVector2Array, color: Color, offset: Vector2 = Vector2.ZERO) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	polygon.position = offset
	polygon.antialiased = true
	return polygon

static func make_shadow(rx: float, ry: float, alpha: float = 0.26, y: float = 0.0) -> Polygon2D:
	return make_polygon(ellipse_polygon(rx, ry, 16), Color(0.0, 0.02, 0.04, alpha), Vector2(0, y))

static func make_glow(radius: float, color: Color, alpha: float = 0.5) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = glow_texture()
	sprite.material = add_material()
	sprite.modulate = Color(color, alpha)
	sprite.scale = Vector2.ONE * (radius / 32.0)
	return sprite

static func make_ring(radius: float, color: Color, width: float = 3.0, segments: int = 28) -> Line2D:
	var ring := Line2D.new()
	var points := circle_polygon(radius, segments)
	points.append(points[0])
	ring.points = points
	ring.width = width
	ring.default_color = color
	ring.antialiased = true
	return ring

static func attach_anim(target: Node2D, mode: String, speed: float = 1.0, strength: float = 1.0) -> void:
	var anim := AmbientAnim.new()
	anim.mode = mode
	anim.speed = speed
	anim.strength = strength
	target.add_child(anim)

static func make_sparkles(color: Color, spread_radius: float, amount: int) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = 1.8
	particles.preprocess = 1.0
	particles.local_coords = false
	particles.texture = glow_texture()
	particles.material = add_material()
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = spread_radius
	particles.direction = Vector2(0, -1)
	particles.spread = 40.0
	particles.gravity = Vector2(0, -14)
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 10.0
	particles.scale_amount_min = 0.05
	particles.scale_amount_max = 0.11
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	ramp.colors = PackedColorArray([Color(color, 0.0), Color(color, 0.9), Color(color, 0.0)])
	particles.color_ramp = ramp
	return particles

# ---------------------------------------------------------------------------
# Ostacoli
# ---------------------------------------------------------------------------

static func build_obstacle(kind: String, radius: float, rgb: int, variant: float, biome: String = "") -> Node2D:
	var root := Node2D.new()
	var color := hex_color(rgb).darkened(variant * 0.16)
	if biome == "academy":
		var academy_cell := Vector2i(-1, -1)
		if kind == "tree":
			# Quercia piena + giovane alberello: stessa grammatica, due scale.
			academy_cell = Vector2i(1, 0) if variant > 0.72 else Vector2i(0, 0)
		elif kind == "bush":
			# Siepe, aiuola fiorita e massa di girasoli evitano ripetizioni.
			academy_cell = Vector2i(2, 0) if variant < 0.38 else (Vector2i(0, 1) if variant < 0.76 else Vector2i(3, 2))
		elif kind == "rock": academy_cell = Vector2i(1, 1)
		elif kind == "mushroom": academy_cell = Vector2i(2, 1)
		elif kind == "pillar": academy_cell = Vector2i(3, 1)
		elif kind == "ruin": academy_cell = Vector2i(1, 2)
		elif kind == "crystal": academy_cell = Vector2i(1, 1)
		if academy_cell.x >= 0:
			var scale_factor := 1.85 if academy_cell == Vector2i(0, 0) else (1.52 if academy_cell == Vector2i(1, 0) else 1.78)
			var target := Vector2(radius * scale_factor, radius * scale_factor)
			root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
			var sprite := academy_natural_sprite(academy_cell, target, -target.y * 0.38)
			sprite.modulate = Color(1.0, 0.96 + variant * 0.04, 0.9 + variant * 0.1, 1.0)
			root.add_child(sprite)
			return root
	if biome == "wild":
		var wild_cell := Vector2i(-1, -1)
		if kind == "tree": wild_cell = Vector2i(0, 0)
		elif kind == "bush": wild_cell = Vector2i(3, 0)
		elif kind == "mushroom": wild_cell = Vector2i(0, 1)
		elif kind == "rock": wild_cell = Vector2i(3, 2) if variant > 0.46 else Vector2i(0, 2)
		elif kind == "pillar": wild_cell = Vector2i(0, 2)
		elif kind == "ruin": wild_cell = Vector2i(3, 1)
		elif kind == "crystal": wild_cell = Vector2i(1, 2)
		if wild_cell.x >= 0:
			var wild_target := Vector2(radius * 1.9, radius * 1.9)
			root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
			root.add_child(wild_natural_sprite(wild_cell, wild_target, -wild_target.y * 0.38))
			return root
	if biome == "geo":
		var geo_cell := Vector2i(-1, -1)
		if kind == "rock": geo_cell = Vector2i(0, 2)
		elif kind == "bush": geo_cell = Vector2i(2, 2)
		elif kind == "pillar": geo_cell = Vector2i(2, 1)
		elif kind == "crystal": geo_cell = Vector2i(1, 2)
		elif kind == "mushroom": geo_cell = Vector2i(0, 1)
		elif kind == "tree": geo_cell = Vector2i(2, 2)
		if geo_cell.x >= 0:
			var geo_target := Vector2(radius * 1.9, radius * 1.75)
			root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
			root.add_child(geo_natural_sprite(geo_cell, geo_target, -geo_target.y * 0.38))
			return root
	if biome == "logic":
		var logic_cell := Vector2i(-1, -1)
		if kind == "crystal": logic_cell = Vector2i(0, 0)
		elif kind == "pillar": logic_cell = Vector2i(2, 0)
		elif kind == "rock": logic_cell = Vector2i(3, 2)
		elif kind == "tree": logic_cell = Vector2i(2, 0)
		elif kind == "bush": logic_cell = Vector2i(3, 0)
		elif kind == "mushroom": logic_cell = Vector2i(0, 2)
		elif kind == "ruin": logic_cell = Vector2i(2, 1)
		if logic_cell.x >= 0:
			var logic_target := Vector2(radius * 1.85, radius * 1.8)
			root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
			root.add_child(logic_natural_sprite(logic_cell, logic_target, -logic_target.y * 0.38))
			return root
	var sprite_name := ""
	var target := Vector2.ZERO
	match kind:
		"tree":
			sprite_name = "pine" if variant > 0.58 else "tree"
			target = Vector2(radius * 1.65, radius * 1.85)
		"bush":
			sprite_name = "bush"
			target = Vector2(radius * 1.75, radius * 1.3)
		"crystal":
			sprite_name = "crystal"
			target = Vector2(radius * 1.65, radius * 1.65)
		"ruin":
			sprite_name = "ruin"
			target = Vector2(radius * 1.45, radius * 1.9)
		_:
			if kind == "rock":
				sprite_name = "rock"
				target = Vector2(radius * 1.85, radius * 1.25)
	if sprite_name != "":
		root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
		root.add_child(outdoor_sprite(sprite_name, target, -target.y * 0.42))
		return root
	match kind:
		"tree":
			root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
			var trunk := make_polygon(PackedVector2Array([
				Vector2(-radius * 0.13, -radius * 0.2), Vector2(radius * 0.13, -radius * 0.2),
				Vector2(radius * 0.18, radius * 0.52), Vector2(-radius * 0.18, radius * 0.52),
			]), Color(0.33, 0.23, 0.15).darkened(variant * 0.2))
			root.add_child(trunk)
			var canopy := Node2D.new()
			canopy.add_child(make_polygon(circle_polygon(radius), color.darkened(0.18), Vector2(radius * 0.08, -radius * 0.5)))
			canopy.add_child(make_polygon(circle_polygon(radius * 0.82), color, Vector2(-radius * 0.16, -radius * 0.72)))
			canopy.add_child(make_polygon(circle_polygon(radius * 0.4), color.lightened(0.22), Vector2(-radius * 0.34, -radius * 0.95)))
			root.add_child(canopy)
			attach_anim(canopy, "sway", 0.7 + variant * 0.8, 1.0)
		"bush":
			root.add_child(make_shadow(radius * 0.95, radius * 0.32, 0.22, radius * 0.28))
			root.add_child(make_polygon(circle_polygon(radius * 0.72), color.darkened(0.12), Vector2(radius * 0.3, -radius * 0.22)))
			root.add_child(make_polygon(circle_polygon(radius * 0.8), color, Vector2(-radius * 0.22, -radius * 0.3)))
			root.add_child(make_polygon(circle_polygon(radius * 0.3), color.lightened(0.25), Vector2(-radius * 0.32, -radius * 0.52)))
		"mushroom":
			root.add_child(make_shadow(radius * 0.8, radius * 0.28, 0.22, radius * 0.2))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.18, -radius * 0.35), Vector2(radius * 0.18, -radius * 0.35),
				Vector2(radius * 0.22, radius * 0.2), Vector2(-radius * 0.22, radius * 0.2),
			]), Color(0.88, 0.84, 0.74)))
			var cap := Node2D.new()
			var cap_points := PackedVector2Array()
			for i in range(13):
				var angle := PI + PI * float(i) / 12.0
				cap_points.append(Vector2(cos(angle) * radius * 0.85, sin(angle) * radius * 0.7 - radius * 0.3))
			cap.add_child(make_polygon(cap_points, color))
			cap.add_child(make_polygon(circle_polygon(radius * 0.12), Color(1, 1, 1, 0.85), Vector2(-radius * 0.3, -radius * 0.62)))
			cap.add_child(make_polygon(circle_polygon(radius * 0.09), Color(1, 1, 1, 0.75), Vector2(radius * 0.24, -radius * 0.5)))
			root.add_child(cap)
			if variant > 0.55:
				var glow := make_glow(radius * 1.3, color.lightened(0.3), 1.0)
				glow.position = Vector2(0, -radius * 0.45)
				glow.add_to_group("night_glow")
				root.add_child(glow)
		"crystal":
			root.add_child(make_shadow(radius * 0.9, radius * 0.3, 0.24, radius * 0.24))
			var glow := make_glow(radius * 2.1, color.lightened(0.25), 1.0)
			glow.position = Vector2(0, -radius * 0.5)
			glow.add_to_group("night_glow")
			root.add_child(glow)
			var shard := make_polygon(PackedVector2Array([
				Vector2(0, -radius * 1.5), Vector2(radius * 0.5, -radius * 0.4),
				Vector2(radius * 0.3, radius * 0.24), Vector2(-radius * 0.3, radius * 0.24),
				Vector2(-radius * 0.5, -radius * 0.4),
			]), color)
			root.add_child(shard)
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(0, -radius * 1.5), Vector2(radius * 0.5, -radius * 0.4), Vector2(0, -radius * 0.2),
			]), color.lightened(0.3)))
			var side := make_polygon(PackedVector2Array([
				Vector2(0, -radius * 0.72), Vector2(radius * 0.26, -radius * 0.14),
				Vector2(radius * 0.14, radius * 0.2), Vector2(-radius * 0.12, radius * 0.2),
			]), color.darkened(0.12), Vector2(radius * 0.5, 0))
			root.add_child(side)
			attach_anim(glow, "pulse", 0.9 + variant, 1.0)
		"pillar":
			root.add_child(make_shadow(radius * 0.85, radius * 0.3, 0.26, radius * 0.2))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.32, -radius * 1.35), Vector2(radius * 0.32, -radius * 1.35),
				Vector2(radius * 0.38, radius * 0.2), Vector2(-radius * 0.38, radius * 0.2),
			]), color))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.46, -radius * 1.5), Vector2(radius * 0.46, -radius * 1.5),
				Vector2(radius * 0.46, -radius * 1.25), Vector2(-radius * 0.46, -radius * 1.25),
			]), color.lightened(0.14)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.32, -radius * 1.35), Vector2(-radius * 0.14, -radius * 1.35),
				Vector2(-radius * 0.2, radius * 0.2), Vector2(-radius * 0.38, radius * 0.2),
			]), color.lightened(0.1)))
		"ruin":
			root.add_child(make_shadow(radius * 1.0, radius * 0.32, 0.26, radius * 0.22))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.3, -radius * 0.9), Vector2(radius * 0.05, -radius * 1.05),
				Vector2(radius * 0.3, -radius * 0.75), Vector2(radius * 0.36, radius * 0.2),
				Vector2(-radius * 0.36, radius * 0.2),
			]), color))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.3, -radius * 0.9), Vector2(radius * 0.05, -radius * 1.05),
				Vector2(-radius * 0.05, -radius * 0.6),
			]), color.lightened(0.16)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.2, -radius * 0.24), Vector2(radius * 0.22, -radius * 0.3),
				Vector2(radius * 0.3, radius * 0.08), Vector2(-radius * 0.12, radius * 0.14),
			]), color.darkened(0.14), Vector2(radius * 0.6, radius * 0.1)))
		_:
			# rock (default)
			root.add_child(make_shadow(radius * 1.0, radius * 0.34, 0.26, radius * 0.3))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius, radius * 0.28), Vector2(-radius * 0.5, -radius * 0.8),
				Vector2(radius * 0.6, -radius * 0.64), Vector2(radius, radius * 0.2),
				Vector2(radius * 0.3, radius * 0.42), Vector2(-radius * 0.4, radius * 0.42),
			]), color))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-radius * 0.5, -radius * 0.8), Vector2(radius * 0.6, -radius * 0.64),
				Vector2(radius * 0.05, -radius * 0.1), Vector2(-radius * 0.55, -radius * 0.16),
			]), color.lightened(0.16)))
	return root

# ---------------------------------------------------------------------------
# Prop
# ---------------------------------------------------------------------------

static func build_prop(kind: String, accent_rgb: int, variant: float, biome: String = "") -> Node2D:
	var root := Node2D.new()
	var accent := hex_color(accent_rgb)
	if biome == "academy":
		var academy_cell := Vector2i(-1, -1)
		if kind == "sign": academy_cell = Vector2i(3, 1)
		elif kind == "river": academy_cell = Vector2i(0, 2)
		elif kind == "garden": academy_cell = Vector2i(0, 1) if variant < 0.5 else Vector2i(3, 2)
		elif kind == "waterfall": academy_cell = Vector2i(1, 2)
		if academy_cell.x >= 0:
			var target := Vector2(104, 104) * (0.9 + variant * 0.16)
			root.add_child(make_shadow(34, 10, 0.22, 4))
			var sprite := academy_natural_sprite(academy_cell, target, -target.y * 0.34)
			sprite.modulate = Color(1.0, 0.97 + variant * 0.03, 0.92 + variant * 0.08, 1.0)
			root.add_child(sprite)
			return root
	if biome == "wild":
		var wild_cell := Vector2i(-1, -1)
		if kind == "garden": wild_cell = Vector2i(2, 2)
		elif kind == "camp": wild_cell = Vector2i(1, 1)
		elif kind == "waterfall": wild_cell = Vector2i(3, 1)
		if wild_cell.x >= 0:
			var wild_target := Vector2(112, 112)
			root.add_child(make_shadow(34, 10, 0.22, 4))
			root.add_child(wild_natural_sprite(wild_cell, wild_target, -36))
			return root
	if biome == "geo":
		var geo_cell := Vector2i(-1, -1)
		if kind == "river": geo_cell = Vector2i(1, 0)
		elif kind == "waterfall": geo_cell = Vector2i(2, 0)
		elif kind == "bridge": geo_cell = Vector2i(3, 0)
		elif kind == "well": geo_cell = Vector2i(1, 1)
		elif kind == "garden": geo_cell = Vector2i(2, 2)
		if geo_cell.x >= 0:
			var geo_target := Vector2(116, 110)
			root.add_child(make_shadow(36, 10, 0.22, 4))
			root.add_child(geo_natural_sprite(geo_cell, geo_target, -36))
			return root
	if biome == "logic":
		var logic_cell := Vector2i(-1, -1)
		if kind == "beacon": logic_cell = Vector2i(1, 1)
		elif kind == "arch": logic_cell = Vector2i(3, 1)
		elif kind == "garden": logic_cell = Vector2i(3, 0)
		elif kind == "well" or kind == "river": logic_cell = Vector2i(1, 2)
		elif kind == "camp": logic_cell = Vector2i(2, 1)
		if logic_cell.x >= 0:
			var logic_target := Vector2(112, 110)
			root.add_child(make_shadow(36, 10, 0.22, 4))
			root.add_child(logic_natural_sprite(logic_cell, logic_target, -36))
			return root
	var sprite_name := ""
	var target := Vector2.ZERO
	match kind:
		"lamp":
			sprite_name = "lamp"
			target = Vector2(58, 92)
		"bridge":
			sprite_name = "bridge"
			target = Vector2(112, 52)
		"river":
			sprite_name = "pond"
			target = Vector2(118, 74)
		"bench":
			sprite_name = "bench"
			target = Vector2(88, 58)
		"beacon":
			sprite_name = "beacon"
			target = Vector2(62, 74)
	if sprite_name != "":
		root.add_child(make_shadow(target.x * 0.34, target.y * 0.12, 0.24, 3))
		var sprite := outdoor_sprite(sprite_name, target, -target.y * 0.38)
		sprite.modulate = Color(1, 1, 1, 0.96)
		root.add_child(sprite)
		return root
	match kind:
		"lamp":
			root.add_child(make_shadow(8, 3.4, 0.24, 2))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-1.6, -26), Vector2(1.6, -26), Vector2(2.2, 2), Vector2(-2.2, 2),
			]), Color(0.16, 0.2, 0.24)))
			root.add_child(make_polygon(circle_polygon(4.6, 10), Color(1.0, 0.9, 0.62), Vector2(0, -28)))
			var glow := make_glow(20, Color(1.0, 0.86, 0.5), 1.0)
			glow.position = Vector2(0, -28)
			glow.add_to_group("night_glow")
			root.add_child(glow)
		"sign":
			root.add_child(make_shadow(8, 3.2, 0.22, 2))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-1.5, -18), Vector2(1.5, -18), Vector2(2, 2), Vector2(-2, 2),
			]), Color(0.36, 0.26, 0.17)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-11, -24), Vector2(11, -24), Vector2(11, -14), Vector2(-11, -14),
			]), Color(0.5, 0.38, 0.24)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-8, -21), Vector2(7, -21), Vector2(7, -19.4), Vector2(-8, -19.4),
			]), Color(0.24, 0.17, 0.1)))
		"river":
			var water := Node2D.new()
			water.rotation = variant * PI
			water.add_child(make_polygon(ellipse_polygon(36, 13, 20), Color(0.24, 0.5, 0.72, 0.8)))
			water.add_child(make_polygon(ellipse_polygon(24, 7, 16), Color(0.42, 0.72, 0.9, 0.7), Vector2(-4, -2)))
			water.add_child(make_polygon(ellipse_polygon(9, 2.6, 10), Color(0.9, 0.98, 1.0, 0.55), Vector2(6, -3)))
			root.add_child(water)
			attach_anim(water, "shimmer", 0.7, 0.4)
		"tower":
			root.add_child(make_shadow(13, 5, 0.28, 3))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-8, -36), Vector2(8, -36), Vector2(10, 3), Vector2(-10, 3),
			]), Color(0.34, 0.31, 0.4)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-11, -42), Vector2(-6, -42), Vector2(-6, -36), Vector2(-1, -36), Vector2(-1, -42),
				Vector2(4, -42), Vector2(4, -36), Vector2(11, -36), Vector2(11, -32), Vector2(-11, -32),
			]), Color(0.42, 0.38, 0.5)))
			root.add_child(make_polygon(circle_polygon(2.4, 8), accent, Vector2(0, -22)))
		"camp":
			root.add_child(make_shadow(15, 5.4, 0.24, 3))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-15, 2), Vector2(0, -20), Vector2(15, 2),
			]), Color(0.72, 0.5, 0.3)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-5, 2), Vector2(0, -8), Vector2(5, 2),
			]), Color(0.3, 0.2, 0.12)))
			var fire := make_glow(13, Color(1.0, 0.62, 0.28), 1.0)
			fire.position = Vector2(19, -2)
			fire.add_to_group("night_glow")
			root.add_child(fire)
			attach_anim(fire, "pulse", 2.2, 1.4)
		"waterfall":
			var falls := Node2D.new()
			falls.add_child(make_polygon(PackedVector2Array([
				Vector2(-7, -30), Vector2(7, -30), Vector2(9, 4), Vector2(-9, 4),
			]), Color(0.55, 0.8, 0.95, 0.75)))
			falls.add_child(make_polygon(PackedVector2Array([
				Vector2(-2.4, -30), Vector2(2.4, -30), Vector2(3, 4), Vector2(-3, 4),
			]), Color(0.85, 0.96, 1.0, 0.8)))
			root.add_child(falls)
			root.add_child(make_polygon(ellipse_polygon(13, 4.4, 12), Color(0.9, 0.98, 1.0, 0.6), Vector2(0, 6)))
			attach_anim(falls, "shimmer", 2.6, 0.5)
		"bridge":
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-22, -7), Vector2(22, -7), Vector2(22, 7), Vector2(-22, 7),
			]), Color(0.45, 0.33, 0.2)))
			for i in range(5):
				var x := -17.0 + float(i) * 8.5
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(x, -7), Vector2(x + 1.4, -7), Vector2(x + 1.4, 7), Vector2(x, 7),
				]), Color(0.32, 0.23, 0.13)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-22, -9.4), Vector2(22, -9.4), Vector2(22, -7.6), Vector2(-22, -7.6),
			]), Color(0.55, 0.42, 0.27)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-22, 7.6), Vector2(22, 7.6), Vector2(22, 9.4), Vector2(-22, 9.4),
			]), Color(0.55, 0.42, 0.27)))
		"statue":
			root.add_child(make_shadow(11, 4.4, 0.26, 3))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-9, -2), Vector2(9, -2), Vector2(11, 4), Vector2(-11, 4),
			]), Color(0.5, 0.48, 0.55)))
			root.add_child(make_polygon(ellipse_polygon(5.4, 9, 12), Color(0.62, 0.6, 0.68), Vector2(0, -12)))
			root.add_child(make_polygon(circle_polygon(3.8, 10), Color(0.68, 0.66, 0.74), Vector2(0, -24)))
		"beacon":
			root.add_child(make_shadow(8, 3.2, 0.24, 2))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-2, -30), Vector2(2, -30), Vector2(3.4, 2), Vector2(-3.4, 2),
			]), Color(0.24, 0.28, 0.36)))
			root.add_child(make_polygon(circle_polygon(4.4, 10), accent, Vector2(0, -33)))
			var beam := make_glow(24, accent, 1.0)
			beam.position = Vector2(0, -33)
			beam.add_to_group("night_glow")
			root.add_child(beam)
			attach_anim(beam, "pulse", 1.6, 1.6)
		"garden":
			root.add_child(make_polygon(ellipse_polygon(15, 6.4, 14), Color(0.16, 0.32, 0.2, 0.85)))
			var petals := [accent, Color(1, 1, 1, 0.9), Color(1.0, 0.78, 0.42), accent.lightened(0.3), Color(0.95, 0.62, 0.78)]
			for i in range(5):
				var angle := TAU * float(i) / 5.0 + variant * TAU
				var pos := Vector2(cos(angle) * 9.0, sin(angle) * 3.6 - 2.0)
				root.add_child(make_polygon(circle_polygon(2.4, 8), petals[i], pos))
		"well":
			root.add_child(make_shadow(12, 4.6, 0.26, 3))
			root.add_child(make_polygon(circle_polygon(10, 16), Color(0.48, 0.46, 0.52)))
			root.add_child(make_polygon(circle_polygon(6.4, 14), Color(0.07, 0.12, 0.2)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-11, -16), Vector2(11, -16), Vector2(11, -13.6), Vector2(-11, -13.6),
			]), Color(0.42, 0.3, 0.18)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-11, -16), Vector2(-8.6, -16), Vector2(-8.6, 0), Vector2(-11, 0),
			]), Color(0.42, 0.3, 0.18)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(8.6, -16), Vector2(11, -16), Vector2(11, 0), Vector2(8.6, 0),
			]), Color(0.42, 0.3, 0.18)))
		"arch":
			root.add_child(make_shadow(16, 5, 0.24, 3))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-14, -26), Vector2(-9, -26), Vector2(-9, 3), Vector2(-14, 3),
			]), Color(0.44, 0.4, 0.5)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(9, -26), Vector2(14, -26), Vector2(14, 3), Vector2(9, 3),
			]), Color(0.44, 0.4, 0.5)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-16, -32), Vector2(16, -32), Vector2(16, -25), Vector2(-16, -25),
			]), Color(0.52, 0.48, 0.58)))
		_:
			root.add_child(make_polygon(circle_polygon(6, 12), accent))
	return root

# ---------------------------------------------------------------------------
# Set dressing Radura Accademia (solo render, senza collisioni/interazioni)
# ---------------------------------------------------------------------------

static func build_academy_pavilion() -> Node2D:
	# Piccola aula/bottega di fondo: landmark visivo caldo che ordina il lato
	# destro della radura senza introdurre un nuovo oggetto gameplay.
	var root := Node2D.new()
	root.add_child(make_shadow(76, 22, 0.26, 12))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-58, -8), Vector2(58, -8), Vector2(52, 28), Vector2(-52, 28),
	]), Color("8f6a3e")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-54, -12), Vector2(0, -66), Vector2(58, -12), Vector2(48, 3), Vector2(-46, 3),
	]), Color("277a79")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-45, -13), Vector2(0, -54), Vector2(46, -13), Vector2(40, -5), Vector2(-40, -5),
	]), Color("3c9b8f")))
	# Fascia lignea e travi per dare una silhouette leggibile a distanza.
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-58, -11), Vector2(58, -11), Vector2(58, -6), Vector2(-58, -6),
	]), Color("c18a4e")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-44, 0), Vector2(-38, 0), Vector2(-38, 28), Vector2(-44, 28),
	]), Color("6e492d")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(36, 0), Vector2(42, 0), Vector2(42, 28), Vector2(36, 28),
	]), Color("6e492d")))
	# Porta centrale e finestre dorate, con glow attenuato alla notte.
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-13, 28), Vector2(-13, 0), Vector2(13, 0), Vector2(13, 28),
	]), Color("4d3326")))
	for window_pos in [Vector2(-34, 8), Vector2(34, 8)]:
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(-9, -8), Vector2(9, -8), Vector2(9, 9), Vector2(-9, 9),
		]), Color("ffe09a"), window_pos))
		var window_glow := make_glow(15, Color("ffd56f"), 0.42)
		window_glow.position = window_pos + Vector2(0, 0)
		window_glow.add_to_group("night_glow")
		root.add_child(window_glow)
	for flower_pos in [Vector2(-64, 27), Vector2(-52, 30), Vector2(52, 30), Vector2(64, 27)]:
		root.add_child(make_polygon(circle_polygon(5.0, 10), Color("f4b56b"), flower_pos))
		root.add_child(make_polygon(circle_polygon(3.2, 10), Color("fff2be"), flower_pos + Vector2(4, -2)))
	return root

static func build_academy_fountain() -> Node2D:
	var root := Node2D.new()
	root.add_child(make_shadow(42, 14, 0.25, 8))
	root.add_child(make_polygon(ellipse_polygon(42, 14, 24), Color("c9a35c"), Vector2(0, 7)))
	root.add_child(make_polygon(ellipse_polygon(32, 10, 24), Color("4cc6bd"), Vector2(0, 4)))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-10, 3), Vector2(10, 3), Vector2(8, -20), Vector2(-8, -20),
	]), Color("d4b477")))
	root.add_child(make_polygon(ellipse_polygon(14, 5, 20), Color("e4c980"), Vector2(0, -20)))
	var water := make_glow(22, Color("8dffe2"), 0.62)
	water.position = Vector2(0, -31)
	water.add_to_group("night_glow")
	root.add_child(water)
	attach_anim(water, "pulse", 1.2, 0.8)
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-2.5, -20), Vector2(0, -41), Vector2(2.5, -20),
	]), Color("a7ffe7", 0.84)))
	return root

static func build_academy_bridge() -> Node2D:
	var root := Node2D.new()
	root.add_child(make_shadow(48, 13, 0.22, 8))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-46, -9), Vector2(46, -9), Vector2(46, 9), Vector2(-46, 9),
	]), Color("9a6636")))
	for i in range(7):
		var x := -38.0 + float(i) * 12.7
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(x, -9), Vector2(x + 2, -9), Vector2(x + 2, 9), Vector2(x, 9),
		]), Color("6b4329")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-48, -12), Vector2(48, -12), Vector2(48, -9), Vector2(-48, -9),
	]), Color("d09a57")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-48, 9), Vector2(48, 9), Vector2(48, 12), Vector2(-48, 12),
	]), Color("d09a57")))
	return root

# ---------------------------------------------------------------------------
# Landmark
# ---------------------------------------------------------------------------

static func build_landmark(kind: String, label: String, accent_rgb: int) -> Node2D:
	var root := Node2D.new()
	var accent := hex_color(accent_rgb)
	var ground_ring := make_ring(34, Color(accent, 0.5), 2.4, 30)
	ground_ring.scale = Vector2(1, 0.42)
	ground_ring.position = Vector2(0, 8)
	root.add_child(ground_ring)
	attach_anim(ground_ring, "pulse", 0.7, 0.8)
	match kind:
		"forge":
			root.add_child(make_shadow(26, 9, 0.3, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-20, -14), Vector2(20, -14), Vector2(24, 6), Vector2(-24, 6),
			]), Color(0.24, 0.2, 0.24)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-14, -20), Vector2(6, -20), Vector2(10, -14), Vector2(-18, -14),
			]), Color(0.34, 0.3, 0.34)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(10, -40), Vector2(17, -40), Vector2(18, -14), Vector2(9, -14),
			]), Color(0.3, 0.26, 0.3)))
			var embers := make_glow(22, Color(1.0, 0.5, 0.2), 1.0)
			embers.position = Vector2(-6, -8)
			embers.add_to_group("night_glow")
			root.add_child(embers)
			attach_anim(embers, "pulse", 2.4, 1.6)
			var sparks := make_sparkles(Color(1.0, 0.62, 0.24, 0.9), 10.0, 6)
			sparks.position = Vector2(-6, -12)
			root.add_child(sparks)
		"atlasGate":
			root.add_child(make_shadow(30, 10, 0.3, 8))
			var inner := make_glow(30, accent, 0.9)
			inner.position = Vector2(0, -26)
			root.add_child(inner)
			attach_anim(inner, "pulse", 1.1, 1.2)
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-26, -44), Vector2(-18, -44), Vector2(-16, 6), Vector2(-24, 6),
			]), Color(0.42, 0.4, 0.5)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(18, -44), Vector2(26, -44), Vector2(24, 6), Vector2(16, 6),
			]), Color(0.42, 0.4, 0.5)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-30, -52), Vector2(30, -52), Vector2(30, -43), Vector2(-30, -43),
			]), Color(0.5, 0.48, 0.6)))
		"logicSpire":
			root.add_child(make_shadow(20, 7.5, 0.3, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(0, -64), Vector2(13, 6), Vector2(-13, 6),
			]), Color(0.3, 0.34, 0.52)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(0, -64), Vector2(13, 6), Vector2(2, 6),
			]), Color(0.38, 0.42, 0.62)))
			for ring_y in [-22.0, -40.0]:
				var band := make_ring(11.0 + ring_y * 0.12, Color(accent, 0.85), 2.2, 20)
				band.scale = Vector2(1, 0.34)
				band.position = Vector2(0, ring_y)
				root.add_child(band)
			var tip := make_glow(17, accent, 1.0)
			tip.position = Vector2(0, -66)
			tip.add_to_group("night_glow")
			root.add_child(tip)
			attach_anim(tip, "pulse", 1.8, 1.4)
		"ancientCore":
			root.add_child(make_shadow(24, 9, 0.32, 8))
			var aura := make_glow(36, accent, 0.8)
			aura.position = Vector2(0, -18)
			aura.add_to_group("night_glow")
			root.add_child(aura)
			root.add_child(make_polygon(circle_polygon(19, 22), Color(0.14, 0.1, 0.18), Vector2(0, -18)))
			root.add_child(make_polygon(circle_polygon(11, 18), Color(0.24, 0.16, 0.32), Vector2(0, -18)))
			var core := make_glow(11, accent.lightened(0.2), 1.0)
			core.position = Vector2(0, -18)
			root.add_child(core)
			attach_anim(core, "pulse", 1.4, 1.6)
			var orbit := Node2D.new()
			orbit.position = Vector2(0, -18)
			for i in range(3):
				var angle := TAU * float(i) / 3.0
				orbit.add_child(make_polygon(circle_polygon(2.6, 8), accent, Vector2(cos(angle), sin(angle)) * 26.0))
			root.add_child(orbit)
			attach_anim(orbit, "spin", 1.0, 1.0)
		"skyTree":
			root.add_child(make_shadow(30, 11, 0.28, 10))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-5, -26), Vector2(5, -26), Vector2(8, 8), Vector2(-8, 8),
			]), Color(0.36, 0.26, 0.18)))
			root.add_child(make_polygon(circle_polygon(30), Color(0.18, 0.42, 0.3), Vector2(3, -44)))
			root.add_child(make_polygon(circle_polygon(24), Color(0.24, 0.52, 0.36), Vector2(-8, -54)))
			root.add_child(make_polygon(circle_polygon(13), Color(0.4, 0.68, 0.46), Vector2(-16, -66)))
			for i in range(3):
				var lantern := make_glow(9, Color(0.72, 0.95, 0.78), 1.0)
				lantern.position = Vector2(-20.0 + float(i) * 16.0, -34.0 - float(i % 2) * 10.0)
				lantern.add_to_group("night_glow")
				root.add_child(lantern)
		"crystalNest":
			root.add_child(make_shadow(26, 9.4, 0.3, 8))
			var nest_glow := make_glow(38, accent, 1.0)
			nest_glow.position = Vector2(0, -14)
			nest_glow.add_to_group("night_glow")
			root.add_child(nest_glow)
			attach_anim(nest_glow, "pulse", 1.0, 1.2)
			for shard_data in [[Vector2(-13, 0), 0.24, 21.0], [Vector2(9, 2), -0.18, 26.0], [Vector2(0, -4), 0.02, 33.0]]:
				var shard := make_polygon(PackedVector2Array([
					Vector2(0, -shard_data[2]), Vector2(shard_data[2] * 0.3, -shard_data[2] * 0.25),
					Vector2(shard_data[2] * 0.18, 6), Vector2(-shard_data[2] * 0.18, 6),
					Vector2(-shard_data[2] * 0.3, -shard_data[2] * 0.25),
				]), accent.darkened(0.1), shard_data[0])
				shard.rotation = shard_data[1]
				root.add_child(shard)
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(0, -33), Vector2(9.9, -8.2), Vector2(0, -2),
			]), accent.lightened(0.3), Vector2(0, -4)))
		_:
			root.add_child(make_polygon(circle_polygon(22, 6), accent))
	var text := Label.new()
	text.text = label
	text.position = Vector2(-80, -96)
	text.custom_minimum_size = Vector2(160, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color("f2f7ff"))
	text.add_theme_constant_override("outline_size", 5)
	text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	root.add_child(text)
	return root

## Landmark canonico per bioma: mantiene la stessa scala percettiva e cambia
## solo silhouette/accento. Utile ai chunk periferici e alla scena nave.
static func build_biome_landmark(biome: String, label: String = "") -> Node2D:
	var key := biome.to_lower()
	match key:
		"academy", "radura", "radura_accademia":
			return build_landmark("skyTree", label if label != "" else "Albero della Radura", 0x8fe0a4)
		"wild", "bosco":
			return build_landmark("skyTree", label if label != "" else "Sentiero del Bosco", 0x72d39a)
		"geo", "dorsale", "dorsale_geografica":
			return build_landmark("atlasGate", label if label != "" else "Passo delle Mappe", 0x80c7ff)
		"logic", "cratere", "cratere_logico":
			return build_landmark("logicSpire", label if label != "" else "Spira del Cratere", 0xb9a2ff)
		"ruins", "rovine":
			return build_landmark("ancientCore", label if label != "" else "Nucleo delle Rovine", 0xe0a37a)
		"crystal", "cristallo":
			return build_landmark("crystalNest", label if label != "" else "Nido di Cristallo", 0x9be7ff)
		_:
			return build_landmark("ancientCore", label, 0x6be7d6)

# ---------------------------------------------------------------------------
# Interagibili
# ---------------------------------------------------------------------------

static func build_treasure(label: String) -> Node2D:
	var root := Node2D.new()
	var rare := label == "scrigno raro"
	var accent := Color("c7b8ff") if rare else Color("f6c85f")
	root.add_child(make_shadow(23, 8.4, 0.3, 20))
	var glow := make_glow(38.0 if rare else 29.0, accent, 0.55)
	glow.position = Vector2(0, -4)
	root.add_child(glow)
	attach_anim(glow, "pulse", 1.2, 1.2)
	var chest := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = TREASURE_TEXTURE
	var tex_size := TREASURE_TEXTURE.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var target := Vector2(64, 55) if rare else Vector2(56, 48)
		sprite.scale = Vector2(target.x / tex_size.x, target.y / tex_size.y)
	chest.add_child(sprite)
	root.add_child(chest)
	attach_anim(chest, "bob", 1.0, 0.8)
	var sparkles := make_sparkles(Color(accent, 0.9), 20.0, 7 if rare else 5)
	sparkles.position = Vector2(0, -8)
	root.add_child(sparkles)
	return root

static func build_encounter(kind: String, difficulty: int) -> Node2D:
	var root := Node2D.new()
	var accent: Color = ENCOUNTER_COLORS.get(kind, Color("f6c85f"))
	var guardian := kind == "guardian"
	root.add_child(make_shadow(28, 10, 0.3, 24))
	var glow := make_glow(46.0 if guardian else 34.0, accent, 0.5)
	root.add_child(glow)
	var ring := make_ring(46.0 if guardian else 38.0, Color(accent, 0.8), 4.0 if guardian else 3.0, 30)
	root.add_child(ring)
	attach_anim(ring, "pulse", 1.3 if guardian else 1.0, 1.4 if guardian else 1.0)
	var sprite := Sprite2D.new()
	sprite.texture = ENCOUNTER_TEXTURE
	var tex_size := ENCOUNTER_TEXTURE.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var side := 66.0 if guardian else 56.0
		sprite.scale = Vector2(side / tex_size.x, side / tex_size.y)
	sprite.modulate = Color(1, 1, 1).lerp(accent, 0.22)
	root.add_child(sprite)
	var pips := mini(difficulty, 7)
	for i in range(pips):
		var x := (float(i) - float(pips - 1) / 2.0) * 10.0
		root.add_child(make_polygon(circle_polygon(3.4, 8), accent, Vector2(x, -52.0 if guardian else -46.0)))
	return root

# ---------------------------------------------------------------------------
# Player
# ---------------------------------------------------------------------------

static func build_player(accent: Color) -> Node2D:
	# `accent` è la livrea = colore dell'outfit equipaggiato in bottega: tinge
	# aura, anello a terra e punta luminosa, così comprare un outfit cambia il
	# colore-firma di Eli nel mondo.
	var root := Node2D.new()
	root.add_child(make_shadow(15, 5.6, 0.32, 16))
	var ring := make_ring(15, Color(accent, 0.5), 2.0, 22)
	ring.scale = Vector2(1, 0.4)
	ring.position = Vector2(0, 15)
	root.add_child(ring)
	var aura := make_glow(27, accent, 0.16)
	aura.position = Vector2(0, 4)
	root.add_child(aura)
	var visual := Node2D.new()
	visual.name = "Visual"
	visual.add_child(player_sprite())
	var tip := make_glow(7, accent.lightened(0.3), 0.72)
	tip.position = Vector2(0, -43)
	tip.add_to_group("night_glow")
	visual.add_child(tip)
	root.add_child(visual)
	return root

# Emblema dell'accessorio equipaggiato, montato sopra la testa del player.
static func build_accessory(id: String, color: Color) -> Node2D:
	var root := Node2D.new()
	if "crown" in id or "halo" in id or "aureola" in id:
		var ring := make_ring(8, color, 2.0, 18)
		ring.scale = Vector2(1, 0.5)
		ring.position = Vector2(0, -46)
		root.add_child(ring)
		var g := make_glow(12, color, 0.6)
		g.position = Vector2(0, -46)
		g.add_to_group("night_glow")
		root.add_child(g)
	elif "visor" in id:
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(-6, -38), Vector2(6, -38), Vector2(6, -35), Vector2(-6, -35),
		]), color))
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(-4.5, -37.4), Vector2(4.5, -37.4), Vector2(4.5, -36.2), Vector2(-4.5, -36.2),
		]), color.lightened(0.4)))
	elif "wings" in id:
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(-9, -20), Vector2(-21, -27), Vector2(-16, -11),
		]), Color(color, 0.75)))
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(9, -20), Vector2(21, -27), Vector2(16, -11),
		]), Color(color, 0.75)))
	elif "scarf" in id:
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(-6, -26), Vector2(6, -26), Vector2(7, -20), Vector2(-7, -20),
		]), color))
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(3, -22), Vector2(7, -22), Vector2(6, -11), Vector2(2, -12),
		]), color.darkened(0.12)))
	else:
		var gem := make_polygon(PackedVector2Array([
			Vector2(0, -47), Vector2(3.4, -42.5), Vector2(0, -38), Vector2(-3.4, -42.5),
		]), color)
		root.add_child(gem)
		var g := make_glow(9, color, 0.6)
		g.position = Vector2(0, -42.5)
		g.add_to_group("night_glow")
		root.add_child(g)
	return root

# Compagno acquistato in bottega. Le creature (dog/cat/rabbit) hanno corpo,
# orecchie e occhio; gli altri (spark/comet/orbit/…) sono nuclei luminosi.
static func build_pet(kind: String, color: Color) -> Node2D:
	var root := Node2D.new()
	root.add_child(make_shadow(9, 3.4, 0.28, 6))
	var glow := make_glow(18, color, 0.42)
	glow.add_to_group("night_glow")
	root.add_child(glow)
	if kind == "dog" or kind == "cat" or kind == "rabbit":
		root.add_child(make_polygon(ellipse_polygon(8, 6.5, 16), color))
		root.add_child(make_polygon(circle_polygon(1.1, 8), color.lightened(0.3), Vector2(-6.5, -1)))
		var ear_h := 9.0 if kind == "rabbit" else (5.5 if kind == "cat" else 4.0)
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(2.6, -8), Vector2(4.4, -8 - ear_h), Vector2(5.8, -6.6),
		]), color.darkened(0.12)))
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(6.4, -8), Vector2(8.2, -8 - ear_h), Vector2(9.4, -6.6),
		]), color.darkened(0.12)))
		root.add_child(make_polygon(circle_polygon(5.2, 14), color.lightened(0.08), Vector2(5.4, -3.8)))
		root.add_child(make_polygon(circle_polygon(1.2, 8), Color(0.05, 0.1, 0.12), Vector2(6.8, -4.4)))
	else:
		root.add_child(make_polygon(circle_polygon(6, 16), color.lightened(0.1)))
		root.add_child(make_polygon(circle_polygon(2.4, 10), Color(1, 1, 1, 0.85), Vector2(-1.6, -1.6)))
		var ring := make_ring(9, Color(color, 0.8), 1.6, 18)
		root.add_child(ring)
		attach_anim(ring, "spin", 1.4, 1.0)
	return root

# ---------------------------------------------------------------------------
# Kit nave / apparati (solo resa visiva, nessuna logica di riparazione).
# `state` accetta: broken, ready, repaired. Il chiamante decide quando
# cambiare stato e può sostituire il nodo senza alterare il salvataggio.
# ---------------------------------------------------------------------------

static func build_apparatus_terminal(state: String = "broken", accent: Color = Color("6be7d6"), label: String = "") -> Node2D:
	var root := Node2D.new()
	root.name = "ApparatusTerminalVisual"
	var active := state == "repaired"
	var ready := state == "ready"
	var core_color := accent if active else (Color("f6c85f") if ready else Color("66777a"))
	root.add_child(make_shadow(32, 9, 0.34, 12))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-28, 7), Vector2(-22, -7), Vector2(22, -7), Vector2(28, 7),
	]), Color("203b3d")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-20, -7), Vector2(-13, -28), Vector2(13, -28), Vector2(20, -7),
	]), Color("315b59")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-12, -27), Vector2(-8, -36), Vector2(8, -36), Vector2(12, -27),
	]), Color("477c72")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-6, -24), Vector2(0, -34), Vector2(6, -24), Vector2(0, -12),
	]), core_color))
	var ring := make_ring(17, Color(core_color, 0.82), 2.2, 24)
	ring.position.y = -23
	root.add_child(ring)
	if active or ready:
		var glow := make_glow(30 if active else 22, core_color, 0.34 if active else 0.18)
		glow.position = Vector2(0, -25)
		glow.add_to_group("night_glow")
		root.add_child(glow)
		attach_anim(ring, "pulse", 0.8 if active else 0.45, 0.8)
	else:
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(-15, -17), Vector2(-5, -13), Vector2(1, -20), Vector2(10, -14),
		]), Color("1a282a")))
	if label.strip_edges() != "":
		var label_node := Label.new()
		label_node.text = label
		label_node.position = Vector2(-54, 15)
		label_node.custom_minimum_size = Vector2(108, 18)
		label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_node.add_theme_font_size_override("font_size", 11)
		label_node.add_theme_color_override("font_color", Color(0.84, 0.96, 0.92, 0.88))
		root.add_child(label_node)
	return root

static func build_ship_room_backdrop(room_id: String, accent: Color = Color("6be7d6")) -> Node2D:
	var root := Node2D.new()
	root.name = "ShipRoomBackdrop_%s" % room_id
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-420, 150), Vector2(-360, -150), Vector2(360, -150), Vector2(420, 150),
	]), Color("102a31")))
	root.add_child(make_polygon(PackedVector2Array([
		Vector2(-390, 148), Vector2(-330, 88), Vector2(330, 88), Vector2(390, 148),
	]), Color("1c4144")))
	for x in [-270.0, -90.0, 90.0, 270.0]:
		root.add_child(make_polygon(PackedVector2Array([
			Vector2(x - 3, 82), Vector2(x + 3, 82), Vector2(x + 3, -108), Vector2(x - 3, -108),
		]), Color(0.35, 0.68, 0.65, 0.18)))
	var crest := make_glow(90, accent, 0.12)
	crest.position = Vector2(0, -80)
	crest.add_to_group("night_glow")
	root.add_child(crest)
	return root
