class_name NpcPortrait
extends Control

var npc_id := ""
var display_name := ""
var accent := Color("6be7d6")

func configure(id: String, label: String) -> void:
	npc_id = id
	display_name = label
	accent = _accent_for(id)
	accessibility_name = "Ritratto di %s" % label
	custom_minimum_size = Vector2(92, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center := size * Vector2(0.5, 0.48)
	var radius := minf(size.x, size.y) * 0.34
	draw_circle(center + Vector2(0, radius * 0.82), radius * 0.72, Color(accent, 0.72))
	draw_circle(center, radius, Color("f2c6a0"))
	var hair := accent.darkened(0.52)
	draw_arc(center + Vector2(0, -2), radius * 0.94, PI, TAU, 24, hair, 12.0, true)
	var eye_y := center.y - radius * 0.08
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(center.x + side * radius * 0.34, eye_y), 3.2, Color("10272b"))
	draw_arc(center + Vector2(0, radius * 0.18), radius * 0.28, 0.15, PI - 0.15, 18, Color("7b3f35"), 2.6, true)
	draw_arc(center, radius + 5.0, 0.0, TAU, 40, Color("f6c85f"), 3.0, true)

static func _accent_for(id: String) -> Color:
	var palette := [Color("6be7d6"), Color("f6c85f"), Color("c7b8ff"), Color("ff9c8f")]
	return palette[posmod(hash(id), palette.size())]
