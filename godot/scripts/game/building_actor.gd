class_name BuildingActor
extends Node2D

var building_id := ""
var role := ""
var stage := 0
var high_contrast := false
var reduced_motion := false
var visual: Node2D
var window_glows: Array[CanvasItem] = []

func configure(spec: Dictionary, world_stage: int, use_high_contrast: bool, use_reduced_motion: bool) -> void:
	building_id = str(spec.get("id", "building"))
	role = str(spec.get("role", "work_home"))
	high_contrast = use_high_contrast
	reduced_motion = use_reduced_motion
	name = "Building_%s" % building_id.replace("-", "_")
	set_meta("building_id", building_id)
	set_meta("building_role", role)
	set_meta("artKit", str(spec.get("artKit", "")))
	add_to_group("world_building")

	if role == "first_ruin":
		visual = Node2D.new()
		visual.name = "FirstRuinVisual"
		add_child(visual)
		_build_ruin_visual(visual)
	else:
		visual = OutdoorVisualFactory.build_academy_pavilion()
		visual.name = "PavilionVisual"
		visual.scale = Vector2.ONE * (1.12 if role == "ritrovo" else 1.0)
		add_child(visual)
		if role == "ritrovo":
			var fountain := OutdoorVisualFactory.build_academy_fountain()
			fountain.name = "RitrovoFountain"
			fountain.position = Vector2(0, 72)
			visual.add_child(fountain)

	var label := Label.new()
	label.name = "BuildingLabel"
	label.text = str(spec.get("label", "Edificio"))
	label.position = Vector2(-120, 88 if role == "ritrovo" else 50)
	label.size = Vector2(240, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE if high_contrast else Color("ffe7a0"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.accessibility_name = label.text
	add_child(label)

	_collect_window_glows(self)
	set_stage(world_stage)

func set_stage(value: int) -> void:
	stage = clampi(value, 0, 3)
	for index in window_glows.size():
		window_glows[index].visible = stage >= 2 or (stage >= 1 and index == 0)
	if is_instance_valid(visual):
		visual.modulate = Color(0.64, 0.68, 0.72) if stage == 0 else Color(0.84, 0.88, 0.91) if stage == 1 else Color.WHITE
	queue_redraw()

func _collect_window_glows(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem and child.is_in_group("night_glow"):
			window_glows.append(child as CanvasItem)
		_collect_window_glows(child)

func _build_ruin_visual(root: Node2D) -> void:
	root.add_child(OutdoorVisualFactory.make_shadow(82, 20, 0.30, 10))
	for data in [
		{"p": Vector2(-48, 12), "s": Vector2(24, 58), "r": -0.12},
		{"p": Vector2(0, -2), "s": Vector2(28, 82), "r": 0.05},
		{"p": Vector2(47, 16), "s": Vector2(22, 50), "r": 0.16},
	]:
		var stone := Polygon2D.new()
		var size: Vector2 = data["s"]
		stone.polygon = PackedVector2Array([
			Vector2(-size.x * 0.5, size.y * 0.5), Vector2(-size.x * 0.42, -size.y * 0.5),
			Vector2(size.x * 0.38, -size.y * 0.46), Vector2(size.x * 0.5, size.y * 0.5),
		])
		stone.color = Color("77817b")
		stone.position = data["p"]
		stone.rotation = float(data["r"])
		root.add_child(stone)
	var glow := OutdoorVisualFactory.make_glow(36, Color("8ff6c0"), 0.34)
	glow.name = "RuinWindowGlow"
	glow.position = Vector2(0, -34)
	glow.add_to_group("night_glow")
	root.add_child(glow)
