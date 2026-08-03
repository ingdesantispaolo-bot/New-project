class_name MysteryArtifact
extends Area2D

var artifact_kind := "trace"
var display_label := ""
var accent := Color("f6c85f")

func configure(kind: String, id: String, payload: Dictionary, high_contrast: bool) -> void:
	artifact_kind = kind
	display_label = str(payload.get("oggetto", payload.get("dove", "Indizio"))).capitalize()
	accent = Color.WHITE if high_contrast else (
		Color("f6c85f") if kind == "trace"
		else Color("8fd8d0") if str(payload.get("dove", "")) == "oggetto"
		else Color("c9a7ff") if str(payload.get("dove", "")) == "dialogo"
		else Color("ffad91"))
	name = "%s_%s" % [kind.capitalize(), id.replace("-", "_")]
	set_meta("kind", "mystery_%s" % kind)
	set_meta("id", id)
	set_meta("payload", payload.duplicate(true))
	add_to_group("world_interactable")
	add_to_group("mystery_artifact")
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 48.0
	collision.shape = circle
	add_child(collision)
	var label := Label.new()
	label.name = "ArtifactLabel"
	label.text = "TRACCIA" if kind == "trace" else "SEME · %s" % str(payload.get("dove", "dettaglio")).to_upper()
	label.position = Vector2(-92, 43)
	label.size = Vector2(184, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.96))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.accessibility_name = "%s, %s" % [label.text, display_label]
	add_child(label)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, 18), 30.0, Color(0.02, 0.06, 0.07, 0.86))
	if artifact_kind == "trace":
		draw_rect(Rect2(-24, -24, 48, 54), Color("ddd1a8"), true)
		for y in [-10, 0, 10]:
			draw_line(Vector2(-15, y), Vector2(15 if y != 0 else 10, y), accent, 3.0, true)
	else:
		var where := str(get_meta("payload", {}).get("dove", "dettaglio"))
		if where == "oggetto":
			draw_circle(Vector2.ZERO, 22.0, Color(accent, 0.62))
			draw_circle(Vector2.ZERO, 9.0, Color("10272b"))
		elif where == "dialogo":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-27, -18), Vector2(27, -18), Vector2(27, 14),
				Vector2(5, 14), Vector2(-7, 27), Vector2(-7, 14), Vector2(-27, 14)]),
				Color(accent, 0.72))
		else:
			draw_rect(Rect2(-22, -22, 44, 44), Color(accent, 0.58), true)
			draw_line(Vector2(-16, 16), Vector2(16, -16), Color("10272b"), 4.0, true)
	draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 28, accent, 2.5, true)
