class_name EnigmaStructureVisual
extends Node2D

## Resa esclusivamente visuale dell'enigma ambientale. Riceve soltanto
## `set_stage(built, total)` dal contratto OutdoorGameplay e non legge save,
## sessioni o progressione.

const BRIDGE_TEXTURE: Texture2D = preload("res://assets/enigma-bridge-primes-v1.png")
const GATE_TEXTURE: Texture2D = preload("res://assets/enigma-gate-language-v1.png")
const CIRCUIT_TEXTURE: Texture2D = preload("res://assets/enigma-circuit-tech-v1.png")
const CRYSTAL_TEXTURE: Texture2D = preload("res://assets/enigma-crystals-harmony-v1.png")
const REACTOR_TEXTURE: Texture2D = preload("res://assets/enigma-reactor-motion-v1.png")
const MAP_TEXTURE: Texture2D = preload("res://assets/enigma-map-stars-v1.png")
const GREENHOUSE_TEXTURE: Texture2D = preload("res://assets/enigma-greenhouse-bio-v1.png")
const NETWORK_TEXTURE: Texture2D = preload("res://assets/enigma-network-civic-v1.png")
const GRID_TEXTURE: Texture2D = preload("res://assets/enigma-grid-logic-v1.png")
const SEGMENT_COUNT := 4

var theme := "ponte"
var display_label := ""
var built := 0
var total := SEGMENT_COUNT
var _structure_texture: Texture2D
var _display_width := 152.0
var _structure_y := -32.0
var _marker_base_y := -82.0
var _accent := Color("70ead8")
var _complete := Color("f7d56b")
var _variant_tint := Color.WHITE
var _segments: Array[Sprite2D] = []
var _pips: Array[Polygon2D] = []
var _ghost: Sprite2D
var _marker: Node2D
var _marker_ring: Line2D
var _title: Label
var _completion_glow: PointLight2D
var _player: Node2D
var _elapsed := 0.0

func setup(value: String, value_label: String = "") -> void:
	theme = value if value != "" else "ponte"
	display_label = value_label.strip_edges()

func _ready() -> void:
	_structure_texture = _texture_for_theme(theme)
	_display_width = 248.0 if theme == "ponte" else 152.0
	var display_scale := _display_width / float(_structure_texture.get_width())
	_structure_y = -maxf(30.0, float(_structure_texture.get_height()) * display_scale * 0.5 + 4.0)
	_marker_base_y = _structure_y - float(_structure_texture.get_height()) * display_scale * 0.5 - 27.0
	_accent = _accent_for_theme(theme)
	_complete = _complete_for_theme(theme)
	_variant_tint = _tint_for_label(display_label)
	add_to_group("enigma_poi")
	z_index = 6
	_build_shadow_and_blueprint()
	_build_segments()
	_build_marker()
	_build_completion_glow()
	_apply_stage(false, built)
	set_process(true)

func set_stage(value: int, stage_total: int) -> void:
	var previous := built
	total = maxi(1, stage_total)
	built = clampi(value, 0, total)
	if not is_node_ready():
		return
	_apply_stage(built > previous, previous)

func _build_shadow_and_blueprint() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "StructureShadow"
	shadow.polygon = _ellipse_points(_display_width * 0.45, 18.0, 32)
	shadow.position = Vector2(0, -6)
	shadow.color = Color(0.015, 0.055, 0.06, 0.42)
	shadow.z_index = -2
	add_child(shadow)

	_ghost = Sprite2D.new()
	_ghost.name = "StructureBlueprint"
	_ghost.texture = _structure_texture
	_ghost.position = Vector2(0, _structure_y)
	_ghost.scale = Vector2.ONE * (_display_width / float(_structure_texture.get_width()))
	_ghost.modulate = Color(0.30, 0.95, 0.91, 0.19)
	_ghost.z_index = -1
	add_child(_ghost)

	# Le due spalle in pietra sono frammenti del vero asset: a stadio zero il
	# ponte appare davvero interrotto, senza rettangoli procedurali fuori stile.
	_build_abutment_slice(true)
	_build_abutment_slice(false)

func _build_abutment_slice(left: bool) -> void:
	var texture_size := _structure_texture.get_size()
	var source_width := texture_size.x * 0.098
	var source_x := 0.0 if left else texture_size.x - source_width
	var atlas := AtlasTexture.new()
	atlas.atlas = _structure_texture
	atlas.region = Rect2(source_x, 0, source_width, texture_size.y)
	var abutment := Sprite2D.new()
	abutment.name = "LeftAbutment" if left else "RightAbutment"
	abutment.texture = atlas
	abutment.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var display_scale := _display_width / texture_size.x
	abutment.scale = Vector2.ONE * display_scale
	abutment.position = Vector2((source_x + source_width * 0.5 - texture_size.x * 0.5) * display_scale, _structure_y)
	abutment.modulate = _variant_tint
	abutment.z_index = 5
	add_child(abutment)

func _build_segments() -> void:
	var texture_size := _structure_texture.get_size()
	var source_width := texture_size.x / float(SEGMENT_COUNT)
	var display_scale := _display_width / texture_size.x
	for index in range(SEGMENT_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = _structure_texture
		atlas.region = Rect2(source_width * index, 0, source_width, texture_size.y)
		var segment := Sprite2D.new()
		segment.name = "Campata%d" % (index + 1)
		segment.texture = atlas
		segment.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		segment.position = Vector2((source_width * (float(index) + 0.5) - texture_size.x * 0.5) * display_scale, _structure_y)
		segment.scale = Vector2.ONE * display_scale
		segment.set_meta("rest_position", segment.position)
		segment.set_meta("rest_scale", segment.scale)
		segment.z_index = index
		add_child(segment)
		_segments.append(segment)

func _build_marker() -> void:
	_marker = Node2D.new()
	_marker.name = "EnigmaMarker"
	_marker.position = Vector2(0, _marker_base_y)
	_marker.z_index = 20
	add_child(_marker)

	var halo := Polygon2D.new()
	halo.name = "MarkerHalo"
	halo.polygon = _ellipse_points(29.0, 15.0, 32)
	halo.color = Color(0.12, 0.58, 0.62, 0.18)
	_marker.add_child(halo)

	_marker_ring = Line2D.new()
	_marker_ring.name = "MarkerRing"
	_marker_ring.width = 2.2
	_marker_ring.default_color = _accent
	_marker_ring.antialiased = true
	_marker_ring.closed = true
	_marker_ring.points = _ellipse_points(22.0, 22.0, 32)
	_marker.add_child(_marker_ring)

	var rune := Polygon2D.new()
	rune.name = "PrimeRune"
	rune.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(11, 0), Vector2(0, 13), Vector2(-11, 0),
	])
	rune.color = Color(0.24, 0.16, 0.48, 0.94)
	_marker.add_child(rune)
	var core := Polygon2D.new()
	core.polygon = _ellipse_points(4.2, 4.2, 16)
	core.color = Color("fff2b0")
	_marker.add_child(core)

	_title = Label.new()
	_title.name = "EnigmaTitle"
	_title.position = Vector2(-110, -42)
	_title.size = Vector2(220, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 11 if theme != "ponte" else 13)
	_title.add_theme_color_override("font_color", Color("f4f1d7"))
	_title.add_theme_color_override("font_outline_color", Color(0.02, 0.07, 0.08, 0.95))
	_title.add_theme_constant_override("outline_size", 4)
	_title.modulate.a = 0.0
	_marker.add_child(_title)

	for index in range(SEGMENT_COUNT):
		var pip := Polygon2D.new()
		pip.name = "Progress%d" % (index + 1)
		pip.polygon = _ellipse_points(3.2, 3.2, 12)
		pip.position = Vector2(-15.0 + index * 10.0, 31)
		_marker.add_child(pip)
		_pips.append(pip)

func _build_completion_glow() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 0.83, 0.34, 0.58), Color(0.24, 0.91, 0.84, 0.20), Color(0, 0, 0, 0)])
	gradient.offsets = PackedFloat32Array([0.0, 0.46, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_completion_glow = PointLight2D.new()
	_completion_glow.name = "CompletionGlow"
	_completion_glow.texture = texture
	_completion_glow.energy = 0.0
	_completion_glow.texture_scale = 1.35
	_completion_glow.position = Vector2(0, -28)
	_completion_glow.blend_mode = PointLight2D.BLEND_MODE_ADD
	_completion_glow.add_to_group("night_glow")
	add_child(_completion_glow)

func _apply_stage(animate_new: bool, previous: int) -> void:
	var visible_count := clampi(ceili(float(built) / float(total) * SEGMENT_COUNT), 0, SEGMENT_COUNT)
	var previous_count := clampi(ceili(float(previous) / float(total) * SEGMENT_COUNT), 0, SEGMENT_COUNT)
	for index in range(_segments.size()):
		var segment := _segments[index]
		var should_show := index < visible_count
		segment.visible = should_show
		if not should_show:
			continue
		var rest_position: Vector2 = segment.get_meta("rest_position")
		var rest_scale: Vector2 = segment.get_meta("rest_scale")
		segment.position = rest_position
		segment.scale = rest_scale
		segment.modulate = _variant_tint
		if animate_new and index >= previous_count:
			segment.modulate = Color(1.0, 0.92, 0.58, 0.0)
			segment.position = rest_position + Vector2(0, -16)
			segment.scale = rest_scale * 0.82
			var tween := create_tween().set_parallel(true)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(segment, "position", rest_position, 0.46).set_delay(float(index - previous_count) * 0.10)
			tween.tween_property(segment, "scale", rest_scale, 0.46).set_delay(float(index - previous_count) * 0.10)
			tween.tween_property(segment, "modulate", _variant_tint, 0.30).set_delay(float(index - previous_count) * 0.10)
			_spawn_stage_sparkles(rest_position, float(index - previous_count) * 0.10)

	var complete := built >= total
	_ghost.modulate = Color(0.30, 0.95, 0.91, 0.03 if complete else 0.19)
	_completion_glow.energy = (0.18 if theme == "ponte" else 0.08) if complete else 0.0
	_marker_ring.default_color = _complete if complete else _accent
	var title := _theme_title()
	_title.text = "ENIGMA COMPLETATO" if complete else ("%s · %d/%d" % [title, built, total] if built > 0 else "ENIGMA · %s" % title)
	for index in range(_pips.size()):
		var threshold := float(index + 1) / float(_pips.size())
		_pips[index].color = _complete if float(built) / float(total) >= threshold else Color(0.42, 0.63, 0.65, 0.34)
	if complete and animate_new:
		_spawn_completion_burst()

func _spawn_stage_sparkles(local_position: Vector2, delay: float) -> void:
	var timer := get_tree().create_timer(delay)
	await timer.timeout
	if not is_inside_tree():
		return
	var particles := OutdoorVisualFactory.make_sparkles(Color(1.0, 0.84, 0.35, 0.95), 18.0, 9)
	particles.name = "CampataSparkles"
	particles.position = local_position
	particles.one_shot = true
	particles.preprocess = 0.0
	particles.emitting = true
	add_child(particles)
	get_tree().create_timer(2.2).timeout.connect(particles.queue_free)

func _spawn_completion_burst() -> void:
	var particles := OutdoorVisualFactory.make_sparkles(Color(0.48, 1.0, 0.88, 0.96), 96.0, 28)
	particles.name = "CompletionBurst"
	particles.position = Vector2(0, -30)
	particles.one_shot = true
	particles.preprocess = 0.0
	particles.emitting = true
	add_child(particles)
	get_tree().create_timer(2.6).timeout.connect(particles.queue_free)
	var tween := create_tween()
	tween.tween_property(_completion_glow, "energy", 0.42, 0.18)
	tween.tween_property(_completion_glow, "energy", 0.18 if theme == "ponte" else 0.08, 0.72)

func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(_marker):
		_marker.position.y = _marker_base_y + sin(_elapsed * 2.2) * 2.4
	if is_instance_valid(_marker_ring):
		_marker_ring.rotation = _elapsed * (0.34 if built < total else 0.18)
	if is_instance_valid(_completion_glow) and built >= total:
		var base_energy := 0.17 if theme == "ponte" else 0.075
		_completion_glow.energy = base_energy + sin(_elapsed * 2.0) * 0.018
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(_title) and is_instance_valid(_player):
		var target_alpha := 1.0 if global_position.distance_to(_player.global_position) <= 120.0 else 0.0
		_title.modulate.a = move_toward(_title.modulate.a, target_alpha, delta * 4.5)

func _texture_for_theme(value: String) -> Texture2D:
	match value:
		"porta": return GATE_TEXTURE
		"circuito": return CIRCUIT_TEXTURE
		"cristalli": return CRYSTAL_TEXTURE
		"reattore": return REACTOR_TEXTURE
		"mappa": return MAP_TEXTURE
		"serra": return GREENHOUSE_TEXTURE
		"rete": return NETWORK_TEXTURE
		"griglia": return GRID_TEXTURE
		_: return BRIDGE_TEXTURE

func _theme_title() -> String:
	if display_label != "":
		return display_label.to_upper()
	match theme:
		"porta": return "PORTA DELLE PAROLE"
		"circuito": return "CIRCUITO"
		"cristalli": return "CRISTALLI DELL'ARMONIA"
		"reattore": return "REATTORE DEI MOTI"
		"mappa": return "MAPPA STELLARE"
		"serra": return "SERRA BIO"
		"rete": return "RETE CIVICA"
		"griglia": return "GRIGLIA LOGICA"
		_: return "PONTE DEI PRIMI"

func _accent_for_theme(value: String) -> Color:
	match value:
		"porta": return Color("efbd6b")
		"circuito": return Color("59e7f2")
		"cristalli": return Color("b69aff")
		"reattore": return Color("69e3ed")
		"mappa": return Color("55dce8")
		"serra": return Color("79e69d")
		"rete": return Color("65d9ff")
		"griglia": return Color("8dc7ff")
		_: return Color("70ead8")

func _complete_for_theme(value: String) -> Color:
	match value:
		"porta": return Color("82ead4")
		"cristalli": return Color("75f0dd")
		"serra": return Color("a6f28d")
		"rete": return Color("8df2d8")
		"griglia": return Color("ffe08a")
		_: return Color("f7d56b")

func _tint_for_label(value: String) -> Color:
	var lowered := value.to_lower()
	if "segnali" in lowered:
		return Color(0.86, 0.96, 1.0)
	if "glifi" in lowered:
		return Color(0.96, 0.88, 1.0)
	if "nucleo" in lowered:
		return Color(1.0, 0.91, 0.76)
	return Color.WHITE

func _ellipse_points(radius_x: float, radius_y: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
