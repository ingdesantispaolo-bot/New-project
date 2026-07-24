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
const CYCLE_MACHINE_TEXTURE: Texture2D = preload("res://assets/cratere-cycle-machine-v1.png")
const RADIO_LIGHTHOUSE_TEXTURE: Texture2D = preload("res://assets/baia-radio-lighthouse-v1.png")
const MOTION_LEVER_TEXTURE: Texture2D = preload("res://assets/officine-grande-leva-v1.png")
const RESONANT_TREE_TEXTURE: Texture2D = preload("res://assets/giardino-albero-risonante-v1.png")
const GLYPH_ARCH_TEXTURE: Texture2D = preload("res://assets/rovine-arco-glifi-v1.png")
const CIRCUIT_NODE_TEXTURE: Texture2D = preload("res://assets/delta-nodo-centrale-v1.png")
const CARTOGRAPHY_TOWER_TEXTURE: Texture2D = preload("res://assets/arcipelago-torre-cartografica-v1.png")
const LIVING_DOME_TEXTURE: Texture2D = preload("res://assets/serra-cupola-vivente-v1.png")
const PACT_PALACE_TEXTURE: Texture2D = preload("res://assets/citta-palazzo-patti-v1.png")
const LABYRINTH_HEART_TEXTURE: Texture2D = preload("res://assets/labirinto-cuore-regole-v1.png")
const ORBITAL_OBSERVATORY_TEXTURE: Texture2D = preload("res://assets/deserto-osservatorio-v1.png")
const HALL_OF_VOICES_TEXTURE: Texture2D = preload("res://assets/biblioteca-sala-voci-v1.png")
const CONTROL_TOWER_TEXTURE: Texture2D = preload("res://assets/citta-torre-controllo-v1.png")
const LANGUAGE_GATE_TEXTURE: Texture2D = preload("res://assets/frontiera-porta-lingue-v1.png")
const UNDERWATER_CATHEDRAL_TEXTURE: Texture2D = preload("res://assets/oceano-cattedrale-sottomarina-v1.png")
const GRAND_ORGAN_TEXTURE: Texture2D = preload("res://assets/cattedrale-grande-organo-v1.png")
const ROOT_TREE_TEXTURE: Texture2D = preload("res://assets/necropoli-albero-radici-v1.png")
const FIELD_TOWER_TEXTURE: Texture2D = preload("res://assets/tempesta-torre-campo-v1.png")

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
	if biome == "ruins":
		var ruins_sprite: Sprite2D
		if kind == "tree": ruins_sprite = wild_natural_sprite(Vector2i(0, 0), Vector2(radius * 1.9, radius * 1.9), -radius * 0.72)
		elif kind == "bush": ruins_sprite = wild_natural_sprite(Vector2i(2, 0), Vector2(radius * 1.9, radius * 1.65), -radius * 0.62)
		elif kind == "mushroom": ruins_sprite = wild_natural_sprite(Vector2i(0, 1), Vector2(radius * 1.8, radius * 1.8), -radius * 0.68)
		elif kind == "ruin": ruins_sprite = wild_natural_sprite(Vector2i(3, 1), Vector2(radius * 2.0, radius * 1.8), -radius * 0.68)
		elif kind == "pillar": ruins_sprite = geo_natural_sprite(Vector2i(2, 1), Vector2(radius * 1.7, radius * 1.9), -radius * 0.72)
		elif kind == "crystal": ruins_sprite = logic_natural_sprite(Vector2i(1, 0), Vector2(radius * 1.8, radius * 1.85), -radius * 0.70)
		else: ruins_sprite = geo_natural_sprite(Vector2i(0, 2), Vector2(radius * 1.9, radius * 1.75), -radius * 0.66)
		root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
		root.add_child(ruins_sprite)
		return root
	if biome == "crystal":
		var crystal_cell := Vector2i(0, 0) if kind == "crystal" and variant < 0.55 else Vector2i(1, 0) if kind == "crystal" else Vector2i(2, 0) if kind in ["tree", "pillar"] else Vector2i(3, 0) if kind == "bush" else Vector2i(0, 2) if kind == "mushroom" else Vector2i(2, 1) if kind == "ruin" else Vector2i(3, 2)
		var crystal_target := Vector2(radius * 1.86, radius * 1.82)
		root.add_child(make_shadow(radius * 1.05, radius * 0.36, 0.24, radius * 0.5))
		root.add_child(logic_natural_sprite(crystal_cell, crystal_target, -crystal_target.y * 0.38))
		return root
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

## Props identitari dei WorldProfile. Sono silhouette di scena, non POI:
## nessuna logica didattica o ricompensa viene decisa qui.
static func build_identity_prop(kind: String, _theme: String, variant: float = 0.5) -> Node2D:
	var root := Node2D.new()
	match kind:
		"archive_shelf":
			root.add_child(make_shadow(72, 14, 0.36, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-66, -112), Vector2(66, -112), Vector2(61, 4), Vector2(-61, 4),
			]), Color("302a3e")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-58, -104), Vector2(57, -104), Vector2(53, -7), Vector2(-54, -7),
			]), Color("57455a")))
			for shelf_y in [-80.0, -52.0, -24.0]:
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(-60, shelf_y), Vector2(58, shelf_y),
					Vector2(58, shelf_y + 5), Vector2(-60, shelf_y + 5),
				]), Color("c09a63")))
				for index in range(7):
					var x := -52.0 + float(index) * 16.0
					var book_height := 14.0 + fmod(float(index) * 5.0 + variant * 17.0, 10.0)
					var colors := [Color("d8c69a"), Color("7585ad"), Color("9b6f83"), Color("5f9a8a")]
					root.add_child(make_polygon(PackedVector2Array([
						Vector2(x, shelf_y - book_height), Vector2(x + 10, shelf_y - book_height),
						Vector2(x + 10, shelf_y - 1), Vector2(x, shelf_y - 1),
					]), colors[(index + roundi(variant * 3.0)) % colors.size()]))
			var shelf_glow := make_glow(34, Color("8ea9ff"), 0.30)
			shelf_glow.position = Vector2(0, -54)
			shelf_glow.add_to_group("night_glow")
			root.add_child(shelf_glow)
			attach_anim(shelf_glow, "pulse", 0.75 + variant * 0.4, 0.7)
		"archive_pillar":
			root.add_child(make_shadow(31, 11, 0.34, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-22, -82), Vector2(22, -82), Vector2(18, 4), Vector2(-18, 4),
			]), Color("54566d")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-29, -91), Vector2(29, -91), Vector2(25, -78), Vector2(-25, -78),
			]), Color("8b8190")))
			for y in [-69.0, -46.0, -23.0]:
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(-11, y - 7), Vector2(0, y - 11), Vector2(11, y - 7),
					Vector2(8, y + 5), Vector2(-8, y + 5),
				]), Color(0.72, 0.78, 0.96, 0.20)))
			var page_glow := make_glow(31, Color("c8d3ff"), 0.68)
			page_glow.position = Vector2(0, -101)
			page_glow.add_to_group("night_glow")
			root.add_child(page_glow)
			attach_anim(page_glow, "pulse", 1.2 + variant * 0.4, 0.8)
			for offset in [Vector2(-28, -112), Vector2(25, -122), Vector2(5, -138)]:
				var page := make_polygon(PackedVector2Array([
					Vector2(-7, -4), Vector2(7, -3), Vector2(6, 5), Vector2(-7, 4),
				]), Color("e7dec4"), offset)
				page.rotation = (offset.x + variant * 30.0) * 0.012
				root.add_child(page)
		"archive_scriptorium":
			root.add_child(make_shadow(54, 16, 0.34, 7))
			root.add_child(make_polygon(ellipse_polygon(50, 20, 24), Color("3a3044"), Vector2(0, -8)))
			root.add_child(make_polygon(ellipse_polygon(44, 16, 24), Color("9b7652"), Vector2(0, -13)))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-36, -35), Vector2(-2, -42), Vector2(0, -15), Vector2(-34, -10),
			]), Color("e2d4ad")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(2, -42), Vector2(36, -34), Vector2(34, -10), Vector2(0, -15),
			]), Color("d4c49d")))
			var ink := make_glow(18, Color("8aa6ff"), 0.46)
			ink.position = Vector2(0, -28)
			ink.add_to_group("night_glow")
			root.add_child(ink)
			attach_anim(ink, "pulse", 0.9, 0.8)
		"number_stone":
			root.add_child(make_shadow(34, 11, 0.28, 6))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-27, -45), Vector2(-17, -59), Vector2(20, -56),
				Vector2(29, -37), Vector2(23, 4), Vector2(-23, 4),
			]), Color("59634d")))
			var count := 2 + int(floor(variant * 4.0))
			for index in range(count):
				var x := (float(index) - float(count - 1) * 0.5) * 10.0
				var bead := make_glow(9, Color("f6cf65"), 0.72)
				bead.position = Vector2(x, -28)
				bead.add_to_group("night_glow")
				root.add_child(bead)
				attach_anim(bead, "pulse", 0.7 + float(index) * 0.12, 0.55)
		"sequence_pylon":
			root.add_child(make_shadow(38, 12, 0.34, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-20, 4), Vector2(-15, -92), Vector2(15, -92), Vector2(20, 4),
			]), Color("263348")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-15, -92), Vector2(0, -110), Vector2(15, -92), Vector2(8, -78), Vector2(-8, -78),
			]), Color("56648c")))
			for index in range(4):
				var y := -72.0 + float(index) * 19.0
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(-11, y - 5), Vector2(11, y - 5), Vector2(9, y + 5), Vector2(-9, y + 5),
				]), Color("3c4968")))
				var node_glow := make_glow(11, Color("80e8ff") if index % 2 == 0 else Color("c4a8ff"), 0.66)
				node_glow.position = Vector2(0, y)
				node_glow.add_to_group("night_glow")
				root.add_child(node_glow)
				attach_anim(node_glow, "pulse", 0.75 + float(index) * 0.16 + variant * 0.2, 0.62)
		"loop_engine":
			root.add_child(make_shadow(78, 23, 0.40, 10))
			var engine := Node2D.new()
			engine.position = Vector2(0, -35)
			for radius in [58.0, 43.0, 27.0]:
				var ring := make_ring(radius, Color("95a8e8", 0.72), 5.0 if radius > 50.0 else 3.0, 36)
				ring.scale.y = 0.66
				engine.add_child(ring)
			for index in range(8):
				var angle := TAU * float(index) / 8.0
				var tooth := make_polygon(PackedVector2Array([
					Vector2(-6, -4), Vector2(6, -4), Vector2(7, 4), Vector2(-7, 4),
				]), Color("c07f62"), Vector2(cos(angle) * 62.0, sin(angle) * 41.0))
				tooth.rotation = angle
				engine.add_child(tooth)
			var core := make_glow(34, Color("75edff"), 0.92)
			core.add_to_group("night_glow")
			engine.add_child(core)
			root.add_child(engine)
			attach_anim(engine, "spin", 0.18 + variant * 0.08, 0.34)
			attach_anim(core, "pulse", 1.0, 0.85)
		"gear_cluster":
			root.add_child(make_shadow(66, 18, 0.38, 9))
			for spec in [
				{"p": Vector2(-30, -22), "r": 28.0, "c": Color("6d789c")},
				{"p": Vector2(20, -38), "r": 36.0, "c": Color("526087")},
				{"p": Vector2(35, 0), "r": 22.0, "c": Color("9b685a")},
			]:
				var gear := Node2D.new()
				gear.position = spec["p"]
				gear.add_child(make_polygon(circle_polygon(float(spec["r"]), 14), spec["c"]))
				gear.add_child(make_ring(float(spec["r"]) * 0.48, Color("1d2639"), 4.0, 24))
				root.add_child(gear)
				attach_anim(gear, "spin", 0.12 if float(spec["r"]) > 30 else -0.16, 0.30)
		"signal_buoy":
			root.add_child(make_shadow(34, 12, 0.30, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-22, 2), Vector2(-15, -46), Vector2(0, -68),
				Vector2(15, -46), Vector2(22, 2),
			]), Color("c66f5e")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-16, -36), Vector2(16, -36), Vector2(12, -22), Vector2(-12, -22),
			]), Color("e8c58a")))
			var beacon := make_glow(19, Color("9ff8e5"), 0.88)
			beacon.position = Vector2(0, -70)
			beacon.add_to_group("night_glow")
			root.add_child(beacon)
			for radius in [28.0, 42.0]:
				var wave := make_ring(radius, Color("91f4e1", 0.30), 2.0, 28)
				wave.scale.y = 0.42
				wave.position = Vector2(0, -62)
				root.add_child(wave)
				attach_anim(wave, "pulse", 0.55 + radius * 0.008, 0.58)
		"radio_mast":
			root.add_child(make_shadow(46, 13, 0.34, 7))
			for side in [-1.0, 1.0]:
				var mast := Line2D.new()
				mast.points = PackedVector2Array([Vector2(side * 24, 4), Vector2(0, -122)])
				mast.width = 4.0
				mast.default_color = Color("d0a66a")
				root.add_child(mast)
			for y: float in [-22.0, -54.0, -86.0]:
				var brace := Line2D.new()
				var width: float = 21.0 * (1.0 + y / 140.0)
				brace.points = PackedVector2Array([Vector2(-width, y), Vector2(width, y)])
				brace.width = 3.0
				brace.default_color = Color("607d83")
				root.add_child(brace)
			var mast_glow := make_glow(22, Color("ffcf85"), 0.84)
			mast_glow.position = Vector2(0, -124)
			mast_glow.add_to_group("night_glow")
			root.add_child(mast_glow)
			attach_anim(mast_glow, "pulse", 1.0 + variant * 0.3, 0.88)
		"signal_console":
			root.add_child(make_shadow(54, 15, 0.34, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-45, 2), Vector2(-38, -48), Vector2(38, -48), Vector2(45, 2),
			]), Color("35535a")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-31, -43), Vector2(31, -43), Vector2(27, -16), Vector2(-27, -16),
			]), Color("16343c")))
			for x in [-19.0, 0.0, 19.0]:
				var dot := make_glow(9, Color("8ff3df") if x <= 0 else Color("f2b176"), 0.64)
				dot.position = Vector2(x, -29)
				dot.add_to_group("night_glow")
				root.add_child(dot)
				attach_anim(dot, "pulse", 0.7 + absf(x) * 0.015, 0.55)
		"motion_piston":
			root.add_child(make_shadow(38, 12, 0.36, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-25, 3), Vector2(-21, -60), Vector2(21, -60), Vector2(25, 3),
			]), Color("31343b")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-31, -68), Vector2(31, -68), Vector2(27, -53), Vector2(-27, -53),
			]), Color("a66d48")))
			var rod := Line2D.new()
			rod.points = PackedVector2Array([Vector2(0, -61), Vector2(0, -112)])
			rod.width = 9.0
			rod.default_color = Color("d1b07b")
			root.add_child(rod)
			var cap := make_glow(17, Color("ffb25f"), 0.62)
			cap.position = Vector2(0, -112)
			cap.add_to_group("night_glow")
			root.add_child(cap)
			attach_anim(cap, "pulse", 0.8 + variant * 0.3, 0.70)
		"rail_switch":
			root.add_child(make_shadow(52, 12, 0.34, 7))
			for side in [-1.0, 1.0]:
				var rail := Line2D.new()
				rail.points = PackedVector2Array([Vector2(side * 24, 4), Vector2(side * 13, -68)])
				rail.width = 6.0
				rail.default_color = Color("997654")
				root.add_child(rail)
			var lever := Line2D.new()
			lever.points = PackedVector2Array([Vector2(0, -20), Vector2(31 if variant > 0.5 else -31, -74)])
			lever.width = 7.0
			lever.default_color = Color("d4a14e")
			root.add_child(lever)
			var grip := make_glow(14, Color("ff9f45"), 0.78)
			grip.position = lever.points[1]
			grip.add_to_group("night_glow")
			root.add_child(grip)
		"force_cart":
			root.add_child(make_shadow(58, 15, 0.36, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-49, -43), Vector2(47, -43), Vector2(38, -6), Vector2(-39, -6),
			]), Color("784d3d")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-42, -38), Vector2(39, -38), Vector2(33, -15), Vector2(-35, -15),
			]), Color("bd784b")))
			for x in [-31.0, 30.0]:
				var wheel := make_ring(13, Color("24262d"), 5.0, 18)
				wheel.position = Vector2(x, -1)
				root.add_child(wheel)
		"resonance_crystal":
			root.add_child(make_shadow(34, 11, 0.28, 7))
			var crystal_glow := make_glow(42, Color("ca9cff"), 0.54)
			crystal_glow.position = Vector2(0, -45)
			crystal_glow.add_to_group("night_glow")
			root.add_child(crystal_glow)
			for data in [[-18.0, 55.0, -0.18], [2.0, 82.0, 0.02], [22.0, 48.0, 0.20]]:
				var shard := make_polygon(PackedVector2Array([
					Vector2(0, -float(data[1])), Vector2(12, -15), Vector2(7, 4), Vector2(-7, 4), Vector2(-12, -15),
				]), Color("9577c8"), Vector2(float(data[0]), 0))
				shard.rotation = float(data[2])
				root.add_child(shard)
			attach_anim(crystal_glow, "pulse", 0.9 + variant * 0.4, 0.82)
		"tuning_pod":
			root.add_child(make_shadow(43, 13, 0.30, 7))
			root.add_child(make_polygon(ellipse_polygon(41, 19, 28), Color("543b75"), Vector2(0, -8)))
			for radius in [24.0, 39.0, 54.0]:
				var wave := make_ring(radius, Color("9fe9ff", 0.26), 2.0, 28)
				wave.scale.y = 0.40
				wave.position = Vector2(0, -24)
				root.add_child(wave)
				attach_anim(wave, "pulse", 0.62 + radius * 0.008, 0.55)
			var tone := make_glow(17, Color("efaaff"), 0.86)
			tone.position = Vector2(0, -28)
			tone.add_to_group("night_glow")
			root.add_child(tone)
		"echo_bloom":
			root.add_child(make_shadow(30, 10, 0.25, 6))
			var stem := Line2D.new()
			stem.points = PackedVector2Array([Vector2(0, 2), Vector2(0, -51)])
			stem.width = 5.0
			stem.default_color = Color("50765e")
			root.add_child(stem)
			for index in range(6):
				var angle := TAU * float(index) / 6.0
				var petal := make_polygon(ellipse_polygon(14, 7, 16), Color("c68fe1"), Vector2(cos(angle) * 17, sin(angle) * 12 - 54))
				petal.rotation = angle
				root.add_child(petal)
			var bloom_core := make_glow(13, Color("baf5ff"), 0.92)
			bloom_core.position = Vector2(0, -54)
			bloom_core.add_to_group("night_glow")
			root.add_child(bloom_core)
		"aqueduct_pillar":
			root.add_child(make_shadow(34, 12, 0.34, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-25, 4), Vector2(-20, -105), Vector2(20, -105), Vector2(25, 4),
			]), Color("ad8257")))
			for y in [-89.0, -55.0, -21.0]:
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(-22, y - 4), Vector2(22, y - 4), Vector2(20, y + 4), Vector2(-20, y + 4),
				]), Color("d2ac72")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-31, -116), Vector2(31, -116), Vector2(27, -101), Vector2(-27, -101),
			]), Color("74563f")))
		"glyph_stele":
			root.add_child(make_shadow(35, 11, 0.32, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-27, 3), Vector2(-24, -77), Vector2(-12, -93), Vector2(19, -88), Vector2(27, 3),
			]), Color("9d7654")))
			for index in range(4):
				var mark := Line2D.new()
				var y := -69.0 + float(index) * 17.0
				mark.points = PackedVector2Array([Vector2(-13, y), Vector2(11, y - 4), Vector2(3, y + 5)])
				mark.width = 2.4
				mark.default_color = Color("6da9d2")
				root.add_child(mark)
			var glyph_glow := make_glow(24, Color("77c4ef"), 0.34)
			glyph_glow.position = Vector2(0, -48)
			glyph_glow.add_to_group("night_glow")
			root.add_child(glyph_glow)
		"mosaic_brazier":
			root.add_child(make_shadow(39, 13, 0.34, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-31, 0), Vector2(-24, -38), Vector2(24, -38), Vector2(31, 0),
			]), Color("77523b")))
			for index in range(5):
				var tile := make_polygon(circle_polygon(8, 4), Color("4f83a5") if index % 2 == 0 else Color("d0a052"))
				tile.position = Vector2(-22.0 + float(index) * 11.0, -17)
				tile.rotation = PI * 0.25
				root.add_child(tile)
			var flame := make_glow(23, Color("ffac54"), 0.86)
			flame.position = Vector2(0, -49)
			flame.add_to_group("night_glow")
			root.add_child(flame)
			attach_anim(flame, "pulse", 1.4 + variant * 0.5, 1.0)
		"coil_tower":
			root.add_child(make_shadow(36, 11, 0.36, 7))
			var mast := Line2D.new()
			mast.points = PackedVector2Array([Vector2(0, 2), Vector2(0, -112)])
			mast.width = 7.0
			mast.default_color = Color("b87948")
			root.add_child(mast)
			for y in [-23.0, -48.0, -73.0, -98.0]:
				var coil := make_ring(24.0 - absf(y + 60.0) * 0.10, Color("5df3e5", 0.78), 3.0, 26)
				coil.scale.y = 0.30
				coil.position = Vector2(0, y)
				root.add_child(coil)
			var coil_glow := make_glow(21, Color("63fff0"), 0.90)
			coil_glow.position = Vector2(0, -116)
			coil_glow.add_to_group("night_glow")
			root.add_child(coil_glow)
			attach_anim(coil_glow, "pulse", 1.1 + variant * 0.3, 0.9)
		"circuit_node":
			root.add_child(make_shadow(36, 12, 0.28, 7))
			for radius in [31.0, 21.0]:
				var circuit_ring := make_ring(radius, Color("58d8cf"), 4.0, 28)
				circuit_ring.scale.y = 0.56
				circuit_ring.position = Vector2(0, -22)
				root.add_child(circuit_ring)
			var circuit_glow := make_glow(18, Color("f3a94e"), 0.92)
			circuit_glow.position = Vector2(0, -22)
			circuit_glow.add_to_group("night_glow")
			root.add_child(circuit_glow)
			attach_anim(circuit_glow, "pulse", 0.78 + variant * 0.35, 0.78)
		"conductor_bridge":
			root.add_child(make_shadow(59, 14, 0.32, 7))
			for y in [-29.0, -12.0]:
				var deck := Line2D.new()
				deck.points = PackedVector2Array([Vector2(-52, y), Vector2(52, y)])
				deck.width = 7.0
				deck.default_color = Color("8b6246")
				root.add_child(deck)
			for x in [-44.0, 0.0, 44.0]:
				var node_glow := make_glow(10, Color("63f2e8"), 0.78)
				node_glow.position = Vector2(x, -31)
				node_glow.add_to_group("night_glow")
				root.add_child(node_glow)
		"route_beacon":
			root.add_child(make_shadow(34, 11, 0.30, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-17, 3), Vector2(-13, -82), Vector2(13, -82), Vector2(17, 3),
			]), Color("ded4b8")))
			for radius in [19.0, 31.0, 43.0]:
				var route_ring := make_ring(radius, Color("65dff4", 0.34), 2.0, 28)
				route_ring.scale.y = 0.35
				route_ring.position = Vector2(0, -88)
				root.add_child(route_ring)
				attach_anim(route_ring, "pulse", 0.62 + radius * 0.008, 0.55)
			var beacon := make_glow(17, Color("69eaff"), 0.92)
			beacon.position = Vector2(0, -90)
			beacon.add_to_group("night_glow")
			root.add_child(beacon)
		"contour_plinth":
			root.add_child(make_shadow(43, 13, 0.28, 7))
			for index in range(4):
				var terrace := make_polygon(
					ellipse_polygon(42.0 - float(index) * 7.0, 18.0 - float(index) * 2.2, 28),
					Color("c8c0a2").darkened(float(index) * 0.05),
					Vector2(0, -float(index) * 10.0))
				root.add_child(terrace)
			var contour_glow := make_glow(14, Color("62d9ed"), 0.68)
			contour_glow.position = Vector2(0, -34)
			contour_glow.add_to_group("night_glow")
			root.add_child(contour_glow)
		"dock_crane":
			root.add_child(make_shadow(48, 13, 0.34, 7))
			var mast := Line2D.new()
			mast.points = PackedVector2Array([Vector2(-20, 3), Vector2(-20, -88), Vector2(39, -88)])
			mast.width = 7.0
			mast.default_color = Color("94704d")
			root.add_child(mast)
			var cable := Line2D.new()
			cable.points = PackedVector2Array([Vector2(33, -88), Vector2(33, -43)])
			cable.width = 2.0
			cable.default_color = Color("28384a")
			root.add_child(cable)
			root.add_child(make_ring(10, Color("e1b867"), 3.0, 16))
			var hook := root.get_child(root.get_child_count() - 1) as Node2D
			hook.position = Vector2(33, -39)
		"symbiosis_pod":
			root.add_child(make_shadow(38, 12, 0.26, 7))
			var pod_glow := make_glow(42, Color("72efc1"), 0.50)
			pod_glow.position = Vector2(0, -38)
			pod_glow.add_to_group("night_glow")
			root.add_child(pod_glow)
			root.add_child(make_polygon(ellipse_polygon(31, 48, 30), Color("4f9d68"), Vector2(0, -42)))
			for index in range(5):
				var angle := TAU * float(index) / 5.0
				var vein := Line2D.new()
				vein.points = PackedVector2Array([
					Vector2(0, -42), Vector2(cos(angle) * 25, sin(angle) * 37 - 42),
				])
				vein.width = 2.2
				vein.default_color = Color("d5c45f")
				root.add_child(vein)
			attach_anim(pod_glow, "pulse", 0.9 + variant * 0.3, 0.76)
		"root_arch":
			root.add_child(make_shadow(50, 14, 0.28, 7))
			for side in [-1.0, 1.0]:
				var root_line := Line2D.new()
				root_line.points = PackedVector2Array([
					Vector2(side * 42, 3), Vector2(side * 30, -55),
					Vector2(side * 11, -88), Vector2(0, -94),
				])
				root_line.width = 9.0
				root_line.default_color = Color("80613d")
				root_line.antialiased = true
				root.add_child(root_line)
			var arch_glow := make_glow(18, Color("8cf0c0"), 0.62)
			arch_glow.position = Vector2(0, -93)
			arch_glow.add_to_group("night_glow")
			root.add_child(arch_glow)
		"pollinator_lamp":
			root.add_child(make_shadow(29, 10, 0.24, 6))
			var stem := Line2D.new()
			stem.points = PackedVector2Array([Vector2(0, 3), Vector2(0, -64)])
			stem.width = 5.0
			stem.default_color = Color("456d4d")
			root.add_child(stem)
			for index in range(6):
				var angle := TAU * float(index) / 6.0
				var petal := make_polygon(ellipse_polygon(12, 5, 14), Color("efad72"), Vector2(cos(angle) * 14, sin(angle) * 9 - 67))
				petal.rotation = angle
				root.add_child(petal)
			var pollen := make_glow(15, Color("ffe16e"), 0.92)
			pollen.position = Vector2(0, -67)
			pollen.add_to_group("night_glow")
			root.add_child(pollen)
			attach_anim(pollen, "pulse", 1.1 + variant * 0.3, 0.80)
		"pact_column":
			root.add_child(make_shadow(31, 11, 0.30, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-20, 3), Vector2(-17, -93), Vector2(17, -93), Vector2(20, 3),
			]), Color("c9a675")))
			for y in [-78.0, -48.0, -18.0]:
				var civic_band := Line2D.new()
				civic_band.points = PackedVector2Array([Vector2(-14, y), Vector2(14, y)])
				civic_band.width = 4.0
				civic_band.default_color = Color("3c8791")
				root.add_child(civic_band)
			var pact_glow := make_glow(17, Color("f3c45f"), 0.76)
			pact_glow.position = Vector2(0, -98)
			pact_glow.add_to_group("night_glow")
			root.add_child(pact_glow)
		"civic_kiosk":
			root.add_child(make_shadow(47, 14, 0.30, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-39, 2), Vector2(-35, -50), Vector2(35, -50), Vector2(39, 2),
			]), Color("b38a5f")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-48, -52), Vector2(0, -76), Vector2(48, -52), Vector2(39, -42), Vector2(-39, -42),
			]), Color("b85f43")))
			for x in [-20.0, 0.0, 20.0]:
				var service_light := make_glow(8, Color("64d4d3"), 0.68)
				service_light.position = Vector2(x, -28)
				service_light.add_to_group("night_glow")
				root.add_child(service_light)
		"service_pavilion":
			root.add_child(make_shadow(58, 16, 0.32, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-52, 3), Vector2(-47, -63), Vector2(47, -63), Vector2(52, 3),
			]), Color("c8a276")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-61, -65), Vector2(0, -94), Vector2(61, -65), Vector2(50, -54), Vector2(-50, -54),
			]), Color("a95640")))
			for x in [-31.0, 0.0, 31.0]:
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(x - 8, -48), Vector2(x + 8, -48), Vector2(x + 8, -12), Vector2(x - 8, -12),
				]), Color("256975")))
		"moving_wall":
			root.add_child(make_shadow(55, 14, 0.38, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-49, 3), Vector2(-46, -105), Vector2(46, -105), Vector2(49, 3),
			]), Color("27344a")))
			for y in [-87.0, -54.0, -21.0]:
				var wall_trace := Line2D.new()
				wall_trace.points = PackedVector2Array([Vector2(-37, y), Vector2(37, y)])
				wall_trace.width = 3.0
				wall_trace.default_color = Color("65c7ed") if y != -54.0 else Color("b28cf0")
				root.add_child(wall_trace)
		"rule_node":
			root.add_child(make_shadow(35, 12, 0.28, 7))
			for radius in [31.0, 21.0]:
				var logic_ring := make_ring(radius, Color("6bcdf4"), 3.0, 8)
				logic_ring.scale.y = 0.62
				logic_ring.position = Vector2(0, -24)
				root.add_child(logic_ring)
			var rule_glow := make_glow(16, Color("b69bff"), 0.88)
			rule_glow.position = Vector2(0, -24)
			rule_glow.add_to_group("night_glow")
			root.add_child(rule_glow)
			attach_anim(rule_glow, "pulse", 0.8 + variant * 0.3, 0.75)
		"logic_gate":
			root.add_child(make_shadow(48, 14, 0.34, 7))
			for side in [-1.0, 1.0]:
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(side * 45, 3), Vector2(side * 42, -96),
					Vector2(side * 22, -96), Vector2(side * 25, 3),
				]), Color("2d3b54")))
			var gate_line := Line2D.new()
			gate_line.points = PackedVector2Array([Vector2(-32, -90), Vector2(0, -112), Vector2(32, -90)])
			gate_line.width = 7.0
			gate_line.default_color = Color("738eb8")
			root.add_child(gate_line)
			var gate_glow := make_glow(19, Color("72dfff"), 0.82)
			gate_glow.position = Vector2(0, -108)
			gate_glow.add_to_group("night_glow")
			root.add_child(gate_glow)
		"trajectory_pylon":
			root.add_child(make_shadow(32, 10, 0.30, 7))
			var trajectory_mast := Line2D.new()
			trajectory_mast.points = PackedVector2Array([Vector2(0, 3), Vector2(0, -104)])
			trajectory_mast.width = 6.0
			trajectory_mast.default_color = Color("9a744f")
			root.add_child(trajectory_mast)
			for orbit_radius in [18.0, 30.0, 42.0]:
				var orbit_band := make_ring(orbit_radius, Color("79bfff", 0.42), 2.0, 28)
				orbit_band.scale.y = 0.32
				orbit_band.position = Vector2(0, -91)
				root.add_child(orbit_band)
			var trajectory_light := make_glow(15, Color("ffd17a"), 0.90)
			trajectory_light.position = Vector2(0, -105)
			trajectory_light.add_to_group("night_glow")
			root.add_child(trajectory_light)
		"fraction_dial":
			root.add_child(make_shadow(43, 13, 0.28, 7))
			var fraction_ring := make_ring(38, Color("d49d58"), 6.0, 32)
			fraction_ring.scale.y = 0.66
			fraction_ring.position = Vector2(0, -27)
			root.add_child(fraction_ring)
			for fraction_index in range(4):
				var fraction_mark := Line2D.new()
				var fraction_angle := TAU * float(fraction_index) / 4.0
				fraction_mark.points = PackedVector2Array([
					Vector2(cos(fraction_angle) * 12, sin(fraction_angle) * 8 - 27),
					Vector2(cos(fraction_angle) * 34, sin(fraction_angle) * 23 - 27),
				])
				fraction_mark.width = 2.5
				fraction_mark.default_color = Color("83c8ff")
				root.add_child(fraction_mark)
			var fraction_core := make_glow(14, Color("ffcb6b"), 0.82)
			fraction_core.position = Vector2(0, -27)
			fraction_core.add_to_group("night_glow")
			root.add_child(fraction_core)
		"orbit_scope":
			root.add_child(make_shadow(52, 14, 0.34, 8))
			var scope_mount := Line2D.new()
			scope_mount.points = PackedVector2Array([Vector2(-24, 2), Vector2(0, -54), Vector2(31, -75)])
			scope_mount.width = 9.0
			scope_mount.default_color = Color("8c694d")
			root.add_child(scope_mount)
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-11, -84), Vector2(45, -106), Vector2(54, -83), Vector2(-4, -62),
			]), Color("54677c")))
			var lens := make_glow(20, Color("77cfff"), 0.90)
			lens.position = Vector2(48, -94)
			lens.add_to_group("night_glow")
			root.add_child(lens)
			attach_anim(lens, "pulse", 0.85 + variant * 0.3, 0.76)
		"voice_shelf":
			root.add_child(make_shadow(62, 14, 0.34, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-55, 3), Vector2(-52, -92), Vector2(52, -92), Vector2(55, 3),
			]), Color("513346")))
			for voice_shelf_y in [-70.0, -42.0, -14.0]:
				var shelf_line := Line2D.new()
				shelf_line.points = PackedVector2Array([Vector2(-48, voice_shelf_y), Vector2(48, voice_shelf_y)])
				shelf_line.width = 4.0
				shelf_line.default_color = Color("c49764")
				root.add_child(shelf_line)
			var shelf_echo := make_glow(26, Color("d99bea"), 0.38)
			shelf_echo.position = Vector2(0, -49)
			shelf_echo.add_to_group("night_glow")
			root.add_child(shelf_echo)
		"echo_lectern":
			root.add_child(make_shadow(42, 12, 0.30, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-29, 3), Vector2(-17, -55), Vector2(17, -55), Vector2(29, 3),
			]), Color("74513f")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-38, -71), Vector2(-2, -82), Vector2(0, -56), Vector2(-34, -49),
				Vector2(0, -56), Vector2(3, -82), Vector2(38, -71), Vector2(34, -49),
			]), Color("ddc99c")))
			for echo_radius in [24.0, 39.0, 54.0]:
				var echo_wave := make_ring(echo_radius, Color("dfa7f0", 0.28), 1.8, 26)
				echo_wave.scale.y = 0.30
				echo_wave.position = Vector2(0, -74)
				root.add_child(echo_wave)
				attach_anim(echo_wave, "pulse", 0.62 + echo_radius * 0.007, 0.52)
		"memory_lantern":
			root.add_child(make_shadow(28, 9, 0.24, 6))
			var lantern_post := Line2D.new()
			lantern_post.points = PackedVector2Array([Vector2(0, 3), Vector2(0, -72)])
			lantern_post.width = 5.0
			lantern_post.default_color = Color("8c6546")
			root.add_child(lantern_post)
			var memory_light := make_glow(26, Color("ffc77a"), 0.92)
			memory_light.position = Vector2(0, -82)
			memory_light.add_to_group("night_glow")
			root.add_child(memory_light)
			attach_anim(memory_light, "pulse", 0.85 + variant * 0.4, 0.75)
		"data_relay":
			root.add_child(make_shadow(34, 11, 0.34, 7))
			var relay_mast := Line2D.new()
			relay_mast.points = PackedVector2Array([Vector2(0, 3), Vector2(0, -112)])
			relay_mast.width = 7.0
			relay_mast.default_color = Color("46546b")
			root.add_child(relay_mast)
			for relay_y in [-28.0, -56.0, -84.0]:
				var relay_node := make_glow(12, Color("52f0e4"), 0.82)
				relay_node.position = Vector2(0, relay_y)
				relay_node.add_to_group("night_glow")
				root.add_child(relay_node)
			var relay_tip := make_glow(18, Color("ff6fc8"), 0.88)
			relay_tip.position = Vector2(0, -116)
			relay_tip.add_to_group("night_glow")
			root.add_child(relay_tip)
		"automaton_station":
			root.add_child(make_shadow(54, 15, 0.38, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-45, 3), Vector2(-40, -73), Vector2(40, -73), Vector2(45, 3),
			]), Color("24384c")))
			for automaton_x in [-23.0, 0.0, 23.0]:
				var automaton_eye := make_glow(10, Color("5af5e8"), 0.82)
				automaton_eye.position = Vector2(automaton_x, -45)
				automaton_eye.add_to_group("night_glow")
				root.add_child(automaton_eye)
			var automaton_bus := Line2D.new()
			automaton_bus.points = PackedVector2Array([Vector2(-34, -20), Vector2(34, -20)])
			automaton_bus.width = 4.0
			automaton_bus.default_color = Color("e36cac")
			root.add_child(automaton_bus)
		"debug_console":
			root.add_child(make_shadow(50, 14, 0.34, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-43, 3), Vector2(-36, -62), Vector2(36, -62), Vector2(43, 3),
			]), Color("25384a")))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-28, -55), Vector2(28, -55), Vector2(25, -24), Vector2(-25, -24),
			]), Color("0b1e2a")))
			for debug_index in range(4):
				var debug_line := Line2D.new()
				debug_line.points = PackedVector2Array([
					Vector2(-20, -47 + debug_index * 7), Vector2(18 - debug_index * 5, -47 + debug_index * 7),
				])
				debug_line.width = 2.0
				debug_line.default_color = Color("55f0df") if debug_index != 2 else Color("ff6aaf")
				root.add_child(debug_line)
		"passage_beacon":
			root.add_child(make_shadow(32, 10, 0.28, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-18, 3), Vector2(-14, -91), Vector2(14, -91), Vector2(18, 3),
			]), Color("b98352")))
			for beacon_color in [Color("57d7d3"), Color("efb45f"), Color("e87178")]:
				var passage_light := make_glow(12, beacon_color, 0.76)
				passage_light.position = Vector2(0, -28 - root.get_child_count() * 5)
				passage_light.add_to_group("night_glow")
				root.add_child(passage_light)
		"market_stall":
			root.add_child(make_shadow(61, 16, 0.34, 8))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-52, 3), Vector2(-46, -55), Vector2(46, -55), Vector2(52, 3),
			]), Color("9b6a43")))
			var awning_colors := [Color("d7635c"), Color("e7b655"), Color("4fa8a6")]
			for awning_index in range(5):
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(-55 + awning_index * 22, -71), Vector2(-34 + awning_index * 22, -71),
						Vector2(-38 + awning_index * 22, -51), Vector2(-51 + awning_index * 22, -51),
				]), awning_colors[awning_index % awning_colors.size()]))
		"connector_arch":
			root.add_child(make_shadow(50, 14, 0.32, 7))
			for connector_side in [-1.0, 1.0]:
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(connector_side * 45, 3), Vector2(connector_side * 41, -91),
					Vector2(connector_side * 24, -91), Vector2(connector_side * 27, 3),
				]), Color("a9774e")))
			var arch_bridge := Line2D.new()
			arch_bridge.points = PackedVector2Array([Vector2(-34, -87), Vector2(0, -112), Vector2(34, -87)])
			arch_bridge.width = 7.0
			arch_bridge.default_color = Color("d9a95e")
			root.add_child(arch_bridge)
			for connector_x in [-20.0, 0.0, 20.0]:
				var connector_light := make_glow(10, Color("61d5d2"), 0.78)
				connector_light.position = Vector2(connector_x, -91 - absf(connector_x) * 0.35)
				connector_light.add_to_group("night_glow")
				root.add_child(connector_light)
		"pressure_buoy", "current_vane", "ballast_station":
			var ocean_width := 28.0 if kind == "pressure_buoy" else 46.0 if kind == "current_vane" else 58.0
			root.add_child(make_shadow(ocean_width, 10, 0.30, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-ocean_width, 2), Vector2(-ocean_width * 0.72, -42),
				Vector2(ocean_width * 0.72, -42), Vector2(ocean_width, 2),
			]), Color("315c68")))
			var ocean_core := make_glow(18 if kind != "ballast_station" else 24, Color("55e7ec"), 0.82)
			ocean_core.position = Vector2(0, -27)
			ocean_core.add_to_group("night_glow")
			root.add_child(ocean_core)
			for ocean_band_y in [-15.0, -34.0]:
				var ocean_band := Line2D.new()
				ocean_band.points = PackedVector2Array([Vector2(-ocean_width * 0.68, ocean_band_y), Vector2(ocean_width * 0.68, ocean_band_y)])
				ocean_band.width = 3.0
				ocean_band.default_color = Color("c59557")
				root.add_child(ocean_band)
		"organ_pipe", "harmony_arch", "timbre_resonator":
			var sound_width := 26.0 if kind == "organ_pipe" else 50.0 if kind == "harmony_arch" else 39.0
			root.add_child(make_shadow(sound_width, 11, 0.31, 7))
			for sound_index in range(3):
				var pipe_height := 55.0 + float(sound_index) * 17.0 + variant * 8.0
				var pipe_x := (float(sound_index) - 1.0) * sound_width * 0.48
				root.add_child(make_polygon(PackedVector2Array([
					Vector2(pipe_x - 6, 2), Vector2(pipe_x - 5, -pipe_height),
					Vector2(pipe_x + 5, -pipe_height), Vector2(pipe_x + 6, 2),
				]), Color("c69a55") if sound_index != 1 else Color("b9b7c8")))
			var sound_resonance := make_ring(sound_width * 0.72, Color("e198ed", 0.72), 3.0, 28)
			sound_resonance.scale.y = 0.34
			sound_resonance.position = Vector2(0, -34)
			root.add_child(sound_resonance)
		"root_obelisk", "lineage_tablet", "crypt_lantern":
			var root_width := 24.0 if kind != "lineage_tablet" else 40.0
			root.add_child(make_shadow(root_width + 8.0, 11, 0.34, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-root_width, 3), Vector2(-root_width * 0.72, -65),
				Vector2(0, -82 if kind == "root_obelisk" else -65),
				Vector2(root_width * 0.72, -65), Vector2(root_width, 3),
			]), Color("66563d")))
			for root_side in [-1.0, 1.0]:
				var root_line := Line2D.new()
				root_line.points = PackedVector2Array([Vector2(root_side * root_width * 0.75, 0), Vector2(root_side * 8.0, -31), Vector2(root_side * root_width * 0.45, -60)])
				root_line.width = 4.0
				root_line.default_color = Color("b78b49")
				root.add_child(root_line)
			var ancestry_light := make_glow(14, Color("ffc56a"), 0.78)
			ancestry_light.position = Vector2(0, -42)
			ancestry_light.add_to_group("night_glow")
			root.add_child(ancestry_light)
		"field_tower", "sensor_probe", "surge_grounder":
			var field_width := 27.0 if kind == "field_tower" else 38.0 if kind == "sensor_probe" else 50.0
			root.add_child(make_shadow(field_width, 10, 0.32, 7))
			root.add_child(make_polygon(PackedVector2Array([
				Vector2(-field_width, 3), Vector2(-field_width * 0.44, -63),
				Vector2(field_width * 0.44, -63), Vector2(field_width, 3),
			]), Color("29394f")))
			for field_y in [-18.0, -40.0, -62.0]:
				var field_ring := make_ring(field_width * 0.54, Color("8f73f2", 0.82), 3.0, 24)
				field_ring.scale.y = 0.28
				field_ring.position = Vector2(0, field_y)
				root.add_child(field_ring)
			var field_core := make_glow(17, Color("62e7ff"), 0.88)
			field_core.position = Vector2(0, -42)
			field_core.add_to_group("night_glow")
			root.add_child(field_core)
		_:
			root.add_child(make_polygon(circle_polygon(18, 8), Color("6be7d6")))
	return root

static func build_landmark(kind: String, label: String, accent_rgb: int) -> Node2D:
	var root := Node2D.new()
	var accent := hex_color(accent_rgb)
	var ground_ring := make_ring(34, Color(accent, 0.5), 2.4, 30)
	ground_ring.scale = Vector2(1, 0.42)
	ground_ring.position = Vector2(0, 8)
	root.add_child(ground_ring)
	attach_anim(ground_ring, "pulse", 0.7, 0.8)
	match kind:
		"cycleMachine":
			var cycle_sprite := Sprite2D.new()
			cycle_sprite.name = "LandmarkCycleMachineArt"
			cycle_sprite.texture = CYCLE_MACHINE_TEXTURE
			cycle_sprite.position = Vector2(0, -66)
			cycle_sprite.scale = Vector2(205, 164) / CYCLE_MACHINE_TEXTURE.get_size()
			cycle_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(cycle_sprite)
			var axle := make_glow(30, accent.lightened(0.18), 0.72)
			axle.position = Vector2(0, -62)
			axle.add_to_group("night_glow")
			root.add_child(axle)
			attach_anim(axle, "pulse", 1.05, 0.84)
		"signalLighthouse":
			var lighthouse_sprite := Sprite2D.new()
			lighthouse_sprite.name = "LandmarkSignalLighthouseArt"
			lighthouse_sprite.texture = RADIO_LIGHTHOUSE_TEXTURE
			lighthouse_sprite.position = Vector2(0, -109)
			lighthouse_sprite.scale = Vector2(150, 225) / RADIO_LIGHTHOUSE_TEXTURE.get_size()
			lighthouse_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(lighthouse_sprite)
			var beam := make_polygon(PackedVector2Array([
				Vector2(0, -165), Vector2(126, -188), Vector2(126, -134),
			]), Color(1.0, 0.84, 0.48, 0.10))
			root.add_child(beam)
			var lamp := make_glow(34, Color("ffd88e"), 1.0)
			lamp.position = Vector2(0, -164)
			lamp.add_to_group("night_glow")
			root.add_child(lamp)
			attach_anim(lamp, "pulse", 1.3, 1.0)
			for radius in [44.0, 66.0, 88.0]:
				var radio_wave := make_ring(radius, Color(accent, 0.26), 2.2, 34)
				radio_wave.scale.y = 0.30
				radio_wave.position = Vector2(0, -164)
				root.add_child(radio_wave)
				attach_anim(radio_wave, "pulse", 0.55 + radius * 0.006, 0.65)
		"motionLever":
			var lever_sprite := Sprite2D.new()
			lever_sprite.name = "LandmarkMotionLeverArt"
			lever_sprite.texture = MOTION_LEVER_TEXTURE
			lever_sprite.position = Vector2(0, -101)
			lever_sprite.scale = Vector2(205, 205) / MOTION_LEVER_TEXTURE.get_size()
			lever_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(lever_sprite)
			var fulcrum := make_glow(31, Color("ffad55"), 0.78)
			fulcrum.position = Vector2(0, -69)
			fulcrum.add_to_group("night_glow")
			root.add_child(fulcrum)
			attach_anim(fulcrum, "pulse", 1.18, 0.86)
		"resonantTree":
			var tree_sprite := Sprite2D.new()
			tree_sprite.name = "LandmarkResonantTreeArt"
			tree_sprite.texture = RESONANT_TREE_TEXTURE
			tree_sprite.position = Vector2(0, -117)
			tree_sprite.scale = Vector2(185, 220) / RESONANT_TREE_TEXTURE.get_size()
			tree_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(tree_sprite)
			for radius in [42.0, 66.0, 89.0]:
				var tone_ring := make_ring(radius, Color(accent, 0.24), 2.0, 34)
				tone_ring.scale.y = 0.30
				tone_ring.position = Vector2(0, -117)
				root.add_child(tone_ring)
				attach_anim(tone_ring, "pulse", 0.63 + radius * 0.006, 0.62)
		"glyphArch":
			var arch_sprite := Sprite2D.new()
			arch_sprite.name = "LandmarkGlyphArchArt"
			arch_sprite.texture = GLYPH_ARCH_TEXTURE
			arch_sprite.position = Vector2(0, -84)
			arch_sprite.scale = Vector2(250, 167) / GLYPH_ARCH_TEXTURE.get_size()
			arch_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(arch_sprite)
			var glyph_aura := make_glow(38, Color("70bde7"), 0.46)
			glyph_aura.position = Vector2(0, -103)
			glyph_aura.add_to_group("night_glow")
			root.add_child(glyph_aura)
			attach_anim(glyph_aura, "pulse", 0.86, 0.74)
		"circuitNode":
			var node_sprite := Sprite2D.new()
			node_sprite.name = "LandmarkCircuitNodeArt"
			node_sprite.texture = CIRCUIT_NODE_TEXTURE
			node_sprite.position = Vector2(0, -116)
			node_sprite.scale = Vector2(210, 220) / CIRCUIT_NODE_TEXTURE.get_size()
			node_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(node_sprite)
			var node_core := make_glow(35, Color("5ffff0"), 0.96)
			node_core.position = Vector2(0, -103)
			node_core.add_to_group("night_glow")
			root.add_child(node_core)
			attach_anim(node_core, "pulse", 1.32, 1.0)
		"cartographyTower":
			var tower_sprite := Sprite2D.new()
			tower_sprite.name = "LandmarkCartographyTowerArt"
			tower_sprite.texture = CARTOGRAPHY_TOWER_TEXTURE
			tower_sprite.position = Vector2(0, -119)
			tower_sprite.scale = Vector2(178, 225) / CARTOGRAPHY_TOWER_TEXTURE.get_size()
			tower_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(tower_sprite)
			for radius in [46.0, 72.0, 98.0]:
				var route_wave := make_ring(radius, Color(accent, 0.24), 2.0, 34)
				route_wave.scale.y = 0.30
				route_wave.position = Vector2(0, -152)
				root.add_child(route_wave)
				attach_anim(route_wave, "pulse", 0.60 + radius * 0.006, 0.62)
		"livingDome":
			var dome_sprite := Sprite2D.new()
			dome_sprite.name = "LandmarkLivingDomeArt"
			dome_sprite.texture = LIVING_DOME_TEXTURE
			dome_sprite.position = Vector2(0, -101)
			dome_sprite.scale = Vector2(250, 180) / LIVING_DOME_TEXTURE.get_size()
			dome_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(dome_sprite)
			var life_core := make_glow(38, Color("72f0c4"), 0.70)
			life_core.position = Vector2(0, -104)
			life_core.add_to_group("night_glow")
			root.add_child(life_core)
			attach_anim(life_core, "pulse", 1.0, 0.86)
		"pactPalace":
			var palace_sprite := Sprite2D.new()
			palace_sprite.name = "LandmarkPactPalaceArt"
			palace_sprite.texture = PACT_PALACE_TEXTURE
			palace_sprite.position = Vector2(0, -103)
			palace_sprite.scale = Vector2(235, 208) / PACT_PALACE_TEXTURE.get_size()
			palace_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(palace_sprite)
			var consensus := make_glow(29, Color("f3c35d"), 0.78)
			consensus.position = Vector2(0, -111)
			consensus.add_to_group("night_glow")
			root.add_child(consensus)
			attach_anim(consensus, "pulse", 0.95, 0.80)
		"labyrinthHeart":
			var heart_sprite := Sprite2D.new()
			heart_sprite.name = "LandmarkLabyrinthHeartArt"
			heart_sprite.texture = LABYRINTH_HEART_TEXTURE
			heart_sprite.position = Vector2(0, -108)
			heart_sprite.scale = Vector2(230, 220) / LABYRINTH_HEART_TEXTURE.get_size()
			heart_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(heart_sprite)
			var logic_core := make_glow(33, Color("8edbff"), 0.90)
			logic_core.position = Vector2(0, -106)
			logic_core.add_to_group("night_glow")
			root.add_child(logic_core)
			attach_anim(logic_core, "pulse", 1.26, 0.96)
		"orbitalObservatory":
			var observatory_sprite := Sprite2D.new()
			observatory_sprite.name = "LandmarkOrbitalObservatoryArt"
			observatory_sprite.texture = ORBITAL_OBSERVATORY_TEXTURE
			observatory_sprite.position = Vector2(0, -110)
			observatory_sprite.scale = Vector2(240, 210) / ORBITAL_OBSERVATORY_TEXTURE.get_size()
			observatory_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(observatory_sprite)
			for observatory_radius in [48.0, 76.0, 104.0]:
				var observatory_orbit := make_ring(observatory_radius, Color(accent, 0.28), 2.0, 38)
				observatory_orbit.scale.y = 0.30
				observatory_orbit.position = Vector2(0, -145)
				root.add_child(observatory_orbit)
				attach_anim(observatory_orbit, "pulse", 0.58 + observatory_radius * 0.006, 0.64)
		"hallOfVoices":
			var voices_sprite := Sprite2D.new()
			voices_sprite.name = "LandmarkHallOfVoicesArt"
			voices_sprite.texture = HALL_OF_VOICES_TEXTURE
			voices_sprite.position = Vector2(0, -104)
			voices_sprite.scale = Vector2(250, 202) / HALL_OF_VOICES_TEXTURE.get_size()
			voices_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(voices_sprite)
			for voices_radius in [46.0, 70.0, 94.0]:
				var voices_echo := make_ring(voices_radius, Color("dda6f2", 0.25), 2.0, 34)
				voices_echo.scale.y = 0.32
				voices_echo.position = Vector2(0, -115)
				root.add_child(voices_echo)
				attach_anim(voices_echo, "pulse", 0.65 + voices_radius * 0.006, 0.60)
		"controlTower":
			var control_sprite := Sprite2D.new()
			control_sprite.name = "LandmarkControlTowerArt"
			control_sprite.texture = CONTROL_TOWER_TEXTURE
			control_sprite.position = Vector2(0, -122)
			control_sprite.scale = Vector2(205, 230) / CONTROL_TOWER_TEXTURE.get_size()
			control_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(control_sprite)
			var control_core := make_glow(35, Color("52f2df"), 0.92)
			control_core.position = Vector2(0, -131)
			control_core.add_to_group("night_glow")
			root.add_child(control_core)
			attach_anim(control_core, "pulse", 1.30, 0.98)
		"languageGate":
			var language_sprite := Sprite2D.new()
			language_sprite.name = "LandmarkLanguageGateArt"
			language_sprite.texture = LANGUAGE_GATE_TEXTURE
			language_sprite.position = Vector2(0, -102)
			language_sprite.scale = Vector2(245, 205) / LANGUAGE_GATE_TEXTURE.get_size()
			language_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(language_sprite)
			var exchange_core := make_glow(31, Color("62dad2"), 0.78)
			exchange_core.position = Vector2(0, -104)
			exchange_core.add_to_group("night_glow")
			root.add_child(exchange_core)
			attach_anim(exchange_core, "pulse", 0.96, 0.82)
		"underwaterCathedral":
			var cathedral_sprite := Sprite2D.new()
			cathedral_sprite.name = "LandmarkUnderwaterCathedralArt"
			cathedral_sprite.texture = UNDERWATER_CATHEDRAL_TEXTURE
			cathedral_sprite.position = Vector2(0, -133)
			cathedral_sprite.scale = Vector2(252, 252) / UNDERWATER_CATHEDRAL_TEXTURE.get_size()
			cathedral_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(cathedral_sprite)
			for current_radius in [45.0, 69.0, 93.0]:
				var current_ring := make_ring(current_radius, Color("56e6ef", 0.24), 2.2, 36)
				current_ring.scale.y = 0.28
				current_ring.position = Vector2(0, -31)
				root.add_child(current_ring)
		"grandOrgan":
			var organ_sprite := Sprite2D.new()
			organ_sprite.name = "LandmarkGrandOrganArt"
			organ_sprite.texture = GRAND_ORGAN_TEXTURE
			organ_sprite.position = Vector2(0, -139)
			organ_sprite.scale = Vector2(245, 245) / GRAND_ORGAN_TEXTURE.get_size()
			organ_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(organ_sprite)
			for echo_radius in [48.0, 72.0, 96.0]:
				var organ_echo := make_ring(echo_radius, Color("e89af2", 0.24), 2.0, 34)
				organ_echo.scale.y = 0.30
				organ_echo.position = Vector2(0, -98)
				root.add_child(organ_echo)
		"rootTree":
			var root_tree_sprite := Sprite2D.new()
			root_tree_sprite.name = "LandmarkRootTreeArt"
			root_tree_sprite.texture = ROOT_TREE_TEXTURE
			root_tree_sprite.position = Vector2(0, -138)
			root_tree_sprite.scale = Vector2(260, 260) / ROOT_TREE_TEXTURE.get_size()
			root_tree_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(root_tree_sprite)
			for root_angle in [-0.65, -0.22, 0.22, 0.65]:
				var lineage_root := Line2D.new()
				lineage_root.points = PackedVector2Array([Vector2(0, -20), Vector2(sin(root_angle) * 62.0, -1), Vector2(sin(root_angle) * 91.0, 7)])
				lineage_root.width = 5.0
				lineage_root.default_color = Color("d2a45c", 0.64)
				root.add_child(lineage_root)
		"fieldTower":
			var tower_sprite := Sprite2D.new()
			tower_sprite.name = "LandmarkFieldTowerArt"
			tower_sprite.texture = FIELD_TOWER_TEXTURE
			tower_sprite.position = Vector2(0, -145)
			tower_sprite.scale = Vector2(242, 242) / FIELD_TOWER_TEXTURE.get_size()
			tower_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			root.add_child(tower_sprite)
			for field_radius in [42.0, 68.0, 94.0]:
				var tower_field := make_ring(field_radius, Color("8f72ff", 0.30), 2.3, 36)
				tower_field.scale.y = 0.30
				tower_field.position = Vector2(0, -102)
				root.add_child(tower_field)
				attach_anim(tower_field, "pulse", 0.72 + field_radius * 0.004, 0.68)
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
	var tall_label_y := {
		"signalLighthouse": -207.0,
		"cycleMachine": -175.0,
		"motionLever": -220.0,
		"resonantTree": -241.0,
		"glyphArch": -190.0,
		"circuitNode": -237.0,
		"cartographyTower": -245.0,
		"livingDome": -206.0,
		"pactPalace": -226.0,
		"labyrinthHeart": -238.0,
		"orbitalObservatory": -232.0,
		"hallOfVoices": -225.0,
		"controlTower": -250.0,
		"languageGate": -226.0,
		"underwaterCathedral": -277.0,
		"grandOrgan": -281.0,
		"rootTree": -284.0,
		"fieldTower": -289.0,
	}
	text.position = Vector2(-90, float(tall_label_y.get(kind, -96.0)))
	text.custom_minimum_size = Vector2(180, 0)
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
