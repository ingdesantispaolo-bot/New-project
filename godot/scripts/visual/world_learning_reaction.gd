class_name WorldLearningReaction
extends Node2D

## Trasformazione ambientale collegata a un evento didattico. Riceve soltanto
## avanzamento/correttezza dal consumer visuale: non calcola mastery, ricompense
## o completamenti.

var active_parts: Array[CanvasItem] = []
var completed := false

func setup(theme: String, event_kind: String, accent: Color) -> void:
	name = "LearningReaction"
	z_index = -1
	var base := OutdoorVisualFactory.make_ring(49, Color(accent.darkened(0.45), 0.48), 2.0, 28)
	base.scale = Vector2(1.0, 0.42)
	base.position = Vector2(0, 10)
	add_child(base)
	if theme == "archive":
		_build_archive(event_kind, accent)
	else:
		_build_radure(event_kind, accent)
	set_progress(0, active_parts.size(), false)

func _build_radure(event_kind: String, accent: Color) -> void:
	for index in range(5):
		var angle := lerpf(-2.72, -0.42, float(index) / 4.0)
		var part := Node2D.new()
		part.position = Vector2(cos(angle) * 46.0, sin(angle) * 19.0 + 6.0)
		var stem := Line2D.new()
		stem.points = PackedVector2Array([Vector2(0, 8), Vector2(0, -10)])
		stem.width = 2.4
		stem.default_color = Color("7fd98a")
		part.add_child(stem)
		part.add_child(OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(0, -14), Vector2(9, -6), Vector2(0, 1), Vector2(-9, -6)]),
			accent.lightened(0.16)))
		var glow := OutdoorVisualFactory.make_glow(15, accent, 0.66)
		glow.position = Vector2(0, -8)
		glow.add_to_group("night_glow")
		part.add_child(glow)
		OutdoorVisualFactory.attach_anim(glow, "pulse", 0.75 + float(index) * 0.13, 0.55)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.10

func _build_archive(event_kind: String, accent: Color) -> void:
	# Le risposte ricompongono una breve passerella di pagine, leggibile anche
	# senza testo e distinta dalla vegetazione della Radura.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-42.0 + float(index) * 21.0, 5.0 + sin(float(index) * 1.7) * 5.0)
		var page := OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(-9, -7), Vector2(9, -6), Vector2(8, 7), Vector2(-9, 6)]),
			Color("e8dfc5"))
		page.rotation = (float(index) - 2.0) * 0.055
		part.add_child(page)
		var ink := Line2D.new()
		ink.points = PackedVector2Array([Vector2(-5, -2), Vector2(4, -2), Vector2(1, 2)])
		ink.width = 1.4
		ink.default_color = Color(accent, 0.82)
		part.add_child(ink)
		var glow := OutdoorVisualFactory.make_glow(14, accent, 0.52)
		glow.add_to_group("night_glow")
		part.add_child(glow)
		OutdoorVisualFactory.attach_anim(glow, "pulse", 0.82 + float(index) * 0.10, 0.50)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.12

func set_progress(value: int, total: int, animate: bool = true) -> void:
	var ratio := clampf(float(value) / maxf(float(total), 1.0), 0.0, 1.0)
	var visible_count := ceili(ratio * float(active_parts.size()))
	for index in range(active_parts.size()):
		var part := active_parts[index]
		var should_show := index < visible_count
		if should_show and not part.visible and animate:
			part.visible = true
			part.modulate = Color(1, 1, 1, 0)
			part.scale = Vector2.ONE * 0.35
			var tween := create_tween().set_parallel(true)
			tween.tween_property(part, "modulate:a", 1.0, 0.28)
			tween.tween_property(part, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			part.visible = should_show
	completed = ratio >= 0.999

func set_complete(value: bool, animate: bool = false) -> void:
	set_progress(active_parts.size() if value else 0, active_parts.size(), animate)
