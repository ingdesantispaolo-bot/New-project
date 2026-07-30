class_name OutdoorWorldPathRenderer
extends Node2D

## I sentieri appartengono alla composizione globale, non ai chunk di
## streaming. Ogni spline viene quindi renderizzata una sola volta: nessuna
## somma di alpha, nessun giunto a bulbo e nessun cambio quando un chunk entra.

const PATH_EARTH_TEXTURE: Texture2D = preload("res://assets/terrain-path-earth.png")

func configure(data: WorldCompositionData) -> void:
	name = "GlobalNavigationPaths"
	z_index = -15
	for path in data.paths:
		var source: PackedVector2Array = path.get("points", PackedVector2Array())
		if source.size() < 2:
			continue
		var width := clampf(float(path.get("width", 64.0)) * 0.39, 20.0, 29.0)
		_add_ribbon(_catmull_rom_polyline(source, 9), width, str(path.get("id", "path")), data.visual_theme)

func _add_ribbon(points: PackedVector2Array, width: float, id: String, theme: String) -> void:
	var root := Node2D.new()
	root.name = "Path_%s" % id
	var style := _path_style(theme)
	var verge := Line2D.new()
	verge.name = "SoftVerge"
	verge.points = points
	verge.width = width + 11.0
	verge.default_color = style["verge"]
	_style_line(verge)
	root.add_child(verge)
	var soil := Line2D.new()
	soil.name = "Earth"
	soil.points = points
	soil.width = width
	if bool(style["texture"]):
		soil.texture = PATH_EARTH_TEXTURE
		soil.texture_mode = Line2D.LINE_TEXTURE_TILE
	soil.default_color = style["surface"]
	_style_line(soil)
	root.add_child(soil)
	var center_wear := Line2D.new()
	center_wear.name = "CenterWear"
	center_wear.points = points
	center_wear.width = maxf(2.0, width * 0.12)
	center_wear.default_color = style["guide"]
	_style_line(center_wear)
	root.add_child(center_wear)
	add_child(root)

func _path_style(theme: String) -> Dictionary:
	# Le tavole dal mondo 19 in poi hanno superfici già molto caratterizzate:
	# una strada di terra generica sembrava incollata sopra il dipinto. Queste
	# corsie mantengono la leggibilità di navigazione usando i materiali del
	# mondo, senza aumentare geometria o draw call.
	match theme:
		"root_necropolis":
			return {"verge": Color(0.08, 0.055, 0.045, 0.25), "surface": Color(0.38, 0.28, 0.18, 0.30), "guide": Color(0.48, 0.68, 0.34, 0.18), "texture": true}
		"electromagnetic_storm":
			return {"verge": Color(0.015, 0.03, 0.11, 0.28), "surface": Color(0.12, 0.25, 0.48, 0.28), "guide": Color(0.66, 0.48, 1.0, 0.34), "texture": false}
		"fractured_atlas":
			return {"verge": Color(0.15, 0.11, 0.06, 0.24), "surface": Color(0.48, 0.42, 0.24, 0.30), "guide": Color(0.62, 0.83, 0.91, 0.22), "texture": true}
		"deep_biosphere":
			return {"verge": Color(0.015, 0.12, 0.10, 0.26), "surface": Color(0.12, 0.43, 0.31, 0.25), "guide": Color(0.48, 1.0, 0.70, 0.30), "texture": false}
		"hall_of_eras", "archive":
			return {"verge": Color(0.02, 0.045, 0.13, 0.30), "surface": Color(0.58, 0.48, 0.34, 0.26), "guide": Color(0.96, 0.70, 0.31, 0.32), "texture": false}
		"first_heart":
			return {"verge": Color(0.08, 0.06, 0.16, 0.28), "surface": Color(0.76, 0.66, 0.42, 0.22), "guide": Color(0.38, 0.93, 0.94, 0.42), "texture": false}
		_:
			return {"verge": Color(0.29, 0.29, 0.18, 0.20), "surface": Color(0.72, 0.68, 0.53, 0.60), "guide": Color(1.0, 0.91, 0.69, 0.075), "texture": true}

func _style_line(line: Line2D) -> void:
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true

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
