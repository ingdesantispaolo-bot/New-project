class_name ThemeSceneryArt
extends RefCounted

## Vocabolario vettoriale dei quattro mondi finali. Queste forme non sono
## ostacoli e non prendono in prestito alberi, rocce o cristalli dai biomi: sono
## scenografia passante, deterministica e priva di testo.

const THEMES := ["fractured_atlas", "deep_biosphere", "hall_of_eras", "first_heart"]

const PALETTES := {
	"fractured_atlas": [Color("d7c58b"), Color("76855b"), Color("78a9b2"), Color("6a4535")],
	"deep_biosphere": [Color("49d8b0"), Color("285f68"), Color("8b78d5"), Color("baf36b")],
	"hall_of_eras": [Color("8994bb"), Color("4c5578"), Color("b28a74"), Color("e2c784")],
	"first_heart": [Color("bd8ee1"), Color("657cc2"), Color("d88776"), Color("f4cf69")],
}

const MAIN_KINDS := {
	"fractured_atlas": ["atlas_fold", "charted_spire", "meridian_fan", "torn_wayfinder"],
	"deep_biosphere": ["lumen_stalk", "spore_crown", "living_column", "root_bloom"],
	"hall_of_eras": ["era_stele", "memory_frame", "age_portal", "witness_plinth"],
	"first_heart": ["core_splinter", "first_prism", "memory_shard", "convergence_spear"],
}

const CHILD_KINDS := {
	"fractured_atlas": ["map_shard", "compass_fragment", "contour_scrap", "star_chart_chip"],
	"deep_biosphere": ["glow_pod", "spore_bulb", "root_knot", "lumen_leaf"],
	"hall_of_eras": ["broken_frame", "record_slab", "era_marker", "archive_bracket"],
	"first_heart": ["heart_fragment", "pulse_shard", "memory_chip", "core_flake"],
}

const ACCENT_KINDS := {
	"fractured_atlas": ["star_ink", "route_stitch", "latitude_sparks", "fold_marks"],
	"deep_biosphere": ["glow_filaments", "spore_drift", "root_threads", "cell_lights"],
	"hall_of_eras": ["time_ribbons", "dust_register", "frame_echo", "age_notches"],
	"first_heart": ["pulse_trace", "core_veins", "memory_orbit", "synthesis_echo"],
}

const DETAIL_KINDS := {
	"fractured_atlas": ["paper_flake", "route_stitch", "latitude_chip", "ink_constellation"],
	"deep_biosphere": ["lumen_sprout", "spore_drift", "root_threads", "cell_lights"],
	"hall_of_eras": ["era_chip", "dust_register", "frame_echo", "age_notches"],
	"first_heart": ["core_flake", "pulse_trace", "memory_orbit", "synthesis_echo"],
}

static func supports(theme: String) -> bool:
	return theme in THEMES

static func main_kind(theme: String, archetype: int) -> String:
	return _pick(MAIN_KINDS, theme, archetype)

static func child_kind(theme: String, archetype: int, index: int) -> String:
	return _pick(CHILD_KINDS, theme, archetype + index)

static func accent_kind(theme: String, archetype: int) -> String:
	return _pick(ACCENT_KINDS, theme, archetype)

static func detail_kind(theme: String, roll: float) -> String:
	var kinds: Array = DETAIL_KINDS.get(theme, [])
	if kinds.is_empty():
		return ""
	return str(kinds[clampi(floori(roll * float(kinds.size())), 0, kinds.size() - 1)])

static func _pick(table: Dictionary, theme: String, index: int) -> String:
	var kinds: Array = table.get(theme, [])
	if kinds.is_empty():
		return ""
	return str(kinds[posmod(index, kinds.size())])

static func build(kind: String, size: Vector2, variant: float, theme: String) -> Node2D:
	var root := Node2D.new()
	root.name = "ThemeScenery_%s" % kind
	root.set_meta("scenery_theme", theme)
	root.set_meta("scenery_kind", kind)
	var palette: Array = PALETTES.get(theme, PALETTES["first_heart"])
	# Figli, accenti e micro-dettagli devono restare segni piccoli. Disegnarli con
	# la complessita' di una stele principale quadruplicava il budget dei chunk.
	if maxf(size.x, size.y) <= 50.0:
		_build_small(root, kind, size, variant, theme, palette)
		return root
	match theme:
		"fractured_atlas":
			_build_atlas(root, kind, size, variant, palette)
		"deep_biosphere":
			_build_biosphere(root, kind, size, variant, palette)
		"hall_of_eras":
			_build_hall(root, kind, size, variant, palette)
		"first_heart":
			_build_heart(root, kind, size, variant, palette)
	return root

static func _build_small(root: Node2D, kind: String, size: Vector2, variant: float, theme: String, colors: Array) -> void:
	var w := size.x
	var h := size.y
	# Un micro-segno occupa un solo CanvasItem: ombre, intagli e filamenti
	# separati costavano ciascuno una draw call. Principali restano stratificati.
	if kind in Array(ACCENT_KINDS.get(theme, [])):
		var trace := Line2D.new()
		trace.points = PackedVector2Array([
			Vector2(-w * 0.42, -h * 0.18), Vector2(-w * 0.12, -h * 0.54),
			Vector2(w * 0.10, -h * (0.34 + variant * 0.18)), Vector2(w * 0.42, -h * 0.70),
		])
		trace.width = maxf(1.6, w * 0.055)
		trace.default_color = Color(colors[3], 0.88)
		trace.antialiased = true
		root.add_child(trace)
		return
	match theme:
		"fractured_atlas":
			root.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
				Vector2(-w * 0.42, -h * 0.10), Vector2(-w * 0.28, -h * 0.76),
				Vector2(w * 0.18, -h * (0.70 + variant * 0.12)), Vector2(w * 0.42, -h * 0.18),
			]), Color(colors[0], 0.88)))
		"deep_biosphere":
			var pod_color := Color(colors[0 if variant < 0.62 else 2], 0.68)
			root.add_child(OutdoorVisualFactory.make_polygon(
				_bio_pod_points(w * 0.30, h * 0.48, variant), pod_color,
				Vector2(w * (variant - 0.5) * 0.22, -h * 0.48)))
		"hall_of_eras":
			root.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
				Vector2(-w * 0.34, 0), Vector2(-w * 0.30, -h * 0.74),
				Vector2(w * 0.24, -h * 0.82), Vector2(w * 0.34, 0),
			]), Color(colors[1], 0.92)))
		"first_heart":
			root.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
				Vector2(-w * 0.32, -h * 0.16), Vector2(-w * 0.12, -h * 0.82),
				Vector2(w * 0.20, -h), Vector2(w * 0.34, -h * 0.24), Vector2(w * 0.08, 0),
			]), Color(colors[0], 0.88)))

static func _build_atlas(root: Node2D, kind: String, size: Vector2, variant: float, colors: Array) -> void:
	var w := size.x * (0.72 if kind.contains("stitch") or kind.contains("mark") else 1.0)
	var h := size.y
	var sheet := PackedVector2Array([
		Vector2(-w * 0.48, -h * 0.18), Vector2(-w * 0.30, -h * 0.88),
		Vector2(w * 0.12, -h * (0.78 + variant * 0.12)), Vector2(w * 0.48, -h * 0.44),
		Vector2(w * 0.34, -h * 0.08), Vector2(-w * 0.10, -h * 0.02),
	])
	root.add_child(OutdoorVisualFactory.make_polygon(sheet, Color(colors[0], 0.90)))
	# Pieghe e rotte sono gli accenti attorno al foglio. Duplicarle qui costava
	# due draw call per assembly proprio nella vista densa del landmark.
	# Le tre stelle sono una sola istanza GPU: restano tre segni, non tre draw call.
	var stars := MultiMeshInstance2D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	var star_mesh := QuadMesh.new()
	var star_size := maxf(3.6, w * 0.07)
	star_mesh.size = Vector2.ONE * star_size
	multimesh.mesh = star_mesh
	multimesh.instance_count = 3
	for index in range(3):
		var point := Vector2(-w * 0.18 + w * 0.20 * index, -h * (0.28 + 0.13 * ((index + floori(variant * 3.0)) % 2)))
		multimesh.set_instance_transform_2d(index, Transform2D(PI * 0.25, point))
		multimesh.set_instance_color(index, Color(colors[3], 0.95))
	stars.multimesh = multimesh
	root.add_child(stars)

static func _build_biosphere(root: Node2D, kind: String, size: Vector2, variant: float, colors: Array) -> void:
	var w := size.x
	var h := size.y
	root.add_child(OutdoorVisualFactory.make_shadow(w * 0.42, h * 0.12, 0.24, h * 0.04))
	var stem := Line2D.new()
	stem.points = PackedVector2Array([Vector2(0, 0), Vector2(-w * 0.08, -h * 0.34), Vector2(w * (variant - 0.5) * 0.18, -h * 0.82)])
	stem.width = maxf(2.0, w * 0.055)
	stem.default_color = Color(colors[1], 0.78)
	stem.antialiased = true
	root.add_child(stem)
	# Un solo alone abbraccia l'intera crescita: tre Sprite di glow e tre semi
	# interni separati costavano sei draw call senza cambiare la silhouette.
	var crown_glow := OutdoorVisualFactory.make_glow(maxf(10.0, w * 0.42), colors[0], 0.15)
	crown_glow.position = Vector2(0, -h * 0.54)
	root.add_child(crown_glow)
	for index in range(2):
		var side := -1.0 if index % 2 == 0 else 1.0
		var center := Vector2(side * w * (0.20 + 0.07 * index), -h * (0.38 + 0.28 * index))
		root.add_child(OutdoorVisualFactory.make_polygon(
			_bio_pod_points(w * 0.22, h * 0.18, fmod(variant + index * 0.37, 1.0)),
			Color(colors[2 if index == 1 else 0], 0.72), center))

static func _bio_pod_points(rx: float, ry: float, variant: float) -> PackedVector2Array:
	var lean := (variant - 0.5) * rx * 0.38
	return PackedVector2Array([
		Vector2(lean, -ry), Vector2(rx * 0.72, -ry * 0.58),
		Vector2(rx, -ry * 0.04), Vector2(rx * 0.54, ry * 0.62),
		Vector2(0, ry), Vector2(-rx * 0.62, ry * 0.48),
		Vector2(-rx, -ry * 0.12), Vector2(-rx * 0.54, -ry * 0.66),
	])

static func _build_hall(root: Node2D, kind: String, size: Vector2, variant: float, colors: Array) -> void:
	var w := size.x
	var h := size.y
	root.add_child(OutdoorVisualFactory.make_shadow(w * 0.46, h * 0.12, 0.25, h * 0.04))
	var slab := PackedVector2Array([
		Vector2(-w * 0.38, 0), Vector2(-w * 0.44, -h * 0.68),
		Vector2(-w * 0.24, -h * 0.90), Vector2(w * 0.28, -h * 0.84),
		Vector2(w * 0.42, -h * 0.62), Vector2(w * 0.36, 0),
	])
	root.add_child(OutdoorVisualFactory.make_polygon(slab, Color(colors[1], 0.96)))
	var inset := PackedVector2Array([
		Vector2(-w * 0.25, -h * 0.20), Vector2(-w * 0.27, -h * 0.62),
		Vector2(-w * 0.16, -h * 0.74), Vector2(w * 0.18, -h * 0.71),
		Vector2(w * 0.27, -h * 0.58), Vector2(w * 0.24, -h * 0.18),
	])
	root.add_child(OutdoorVisualFactory.make_polygon(inset, Color(colors[0], 0.72)))
	for index in range(3):
		var band := Line2D.new()
		var y := -h * (0.30 + index * 0.13)
		band.points = PackedVector2Array([Vector2(-w * 0.16, y), Vector2(w * (0.12 + 0.05 * ((index + floori(variant * 4.0)) % 2)), y - h * 0.015)])
		band.width = maxf(1.3, w * 0.035)
		band.default_color = Color(colors[2 if index == 1 else 3], 0.78)
		band.antialiased = true
		root.add_child(band)

static func _build_heart(root: Node2D, kind: String, size: Vector2, variant: float, colors: Array) -> void:
	var w := size.x
	var h := size.y
	root.add_child(OutdoorVisualFactory.make_shadow(w * 0.42, h * 0.12, 0.28, h * 0.04))
	var glow := OutdoorVisualFactory.make_glow(maxf(10.0, w * 0.42), colors[3], 0.13)
	glow.position = Vector2(0, -h * 0.44)
	root.add_child(glow)
	var shard := PackedVector2Array([
		Vector2(-w * 0.34, -h * 0.22), Vector2(-w * 0.16, -h * 0.82),
		Vector2(w * (variant - 0.5) * 0.12, -h), Vector2(w * 0.32, -h * 0.70),
		Vector2(w * 0.42, -h * 0.30), Vector2(w * 0.10, -h * 0.04),
	])
	root.add_child(OutdoorVisualFactory.make_polygon(shard, Color(colors[0], 0.88)))
	var inner := PackedVector2Array([
		Vector2(-w * 0.10, -h * 0.26), Vector2(-w * 0.05, -h * 0.74),
		Vector2(w * 0.12, -h * 0.65), Vector2(w * 0.18, -h * 0.32),
	])
	root.add_child(OutdoorVisualFactory.make_polygon(inner, Color(colors[1], 0.78)))
	for index in range(3):
		var vein := Line2D.new()
		var y := -h * (0.30 + index * 0.15)
		vein.points = PackedVector2Array([Vector2(-w * 0.18, y), Vector2(w * (0.02 + index * 0.07), y - h * 0.09), Vector2(w * 0.24, y - h * 0.04)])
		vein.width = maxf(1.2, w * 0.026)
		vein.default_color = Color(colors[3 if index == 1 else 2], 0.88)
		vein.antialiased = true
		root.add_child(vein)
