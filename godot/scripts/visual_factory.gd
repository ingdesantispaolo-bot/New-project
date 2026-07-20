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

const ENCOUNTER_COLORS := {
	"times": Color("f6c85f"),
	"mental": Color("9f8cff"),
	"capital": Color("ff8f6b"),
	"physicalGeo": Color("8fe0a4"),
	"guardian": Color("ff6b7a"),
}

static var _glow_texture: Texture2D
static var _add_material: CanvasItemMaterial

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

static func build_obstacle(kind: String, radius: float, rgb: int, variant: float) -> Node2D:
	var root := Node2D.new()
	var color := hex_color(rgb).darkened(variant * 0.16)
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

static func build_prop(kind: String, accent_rgb: int, variant: float) -> Node2D:
	var root := Node2D.new()
	var accent := hex_color(accent_rgb)
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
	var root := Node2D.new()
	root.add_child(make_shadow(15, 5.6, 0.32, 16))
	var aura := make_glow(27, accent, 0.16)
	aura.position = Vector2(0, 4)
	root.add_child(aura)
	var visual := Node2D.new()
	visual.name = "Visual"
	visual.add_child(make_polygon(ellipse_polygon(12, 15, 18), accent.darkened(0.12), Vector2(0, -2)))
	visual.add_child(make_polygon(ellipse_polygon(8, 10, 16), accent.lightened(0.1), Vector2(0, 0)))
	visual.add_child(make_polygon(circle_polygon(9, 16), accent.lightened(0.24), Vector2(0, -18)))
	visual.add_child(make_polygon(PackedVector2Array([
		Vector2(-6, -21), Vector2(6, -21), Vector2(6, -16), Vector2(-6, -16),
	]), Color(0.04, 0.1, 0.13, 0.92)))
	visual.add_child(make_polygon(PackedVector2Array([
		Vector2(-4.6, -20.2), Vector2(4.6, -20.2), Vector2(4.6, -18.6), Vector2(-4.6, -18.6),
	]), Color(0.55, 0.95, 0.9, 0.9)))
	visual.add_child(make_polygon(PackedVector2Array([
		Vector2(-0.7, -27), Vector2(0.7, -27), Vector2(0.7, -31), Vector2(-0.7, -31),
	]), accent.darkened(0.2)))
	var tip := make_glow(6, accent.lightened(0.3), 1.0)
	tip.position = Vector2(0, -32)
	visual.add_child(tip)
	root.add_child(visual)
	return root
