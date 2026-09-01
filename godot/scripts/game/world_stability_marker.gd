class_name WorldStabilityMarker
extends Node2D

## Il segno fisico che un Pericolo del Mondo e' stato superato. Non si apre e
## non concede niente: esiste perche' una vittoria permanente non puo' essere
## rappresentata soltanto dall'assenza di cio' che c'era prima.

var accent := Color("8ff6d2")
var reduced_motion := false
var elapsed := 0.0

func configure(label: String, sigil: String, color: Color, prefers_reduced_motion: bool) -> void:
	name = "WorldStabilityMarker"
	accent = color
	reduced_motion = prefers_reduced_motion
	add_to_group("world_stability_marker")
	set_meta("label", label)
	set_meta("sigil", sigil)

	var caption := Label.new()
	caption.name = "StabilityCaption"
	caption.text = "ZONA STABILE\n%s" % sigil.to_upper()
	caption.position = Vector2(-145, 70)
	caption.custom_minimum_size = Vector2(290, 44)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_constant_override("outline_size", 5)
	caption.add_theme_color_override("font_color", accent.lightened(0.3))
	caption.accessibility_name = "%s superato. %s ottenuto." % [label, sigil]
	add_child(caption)
	queue_redraw()

func _process(delta: float) -> void:
	if reduced_motion:
		return
	elapsed += maxf(delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var pulse := 1.0 if reduced_motion else 1.0 + sin(elapsed * 1.8) * 0.025
	var radius := 54.0 * pulse
	draw_circle(Vector2.ZERO, radius, Color(accent, 0.10))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(accent, 0.85), 3.0, true)
	draw_arc(Vector2.ZERO, radius - 12.0, 0.0, TAU, 48, Color(accent, 0.42), 2.0, true)
	var diamond := PackedVector2Array([
		Vector2(0, -36), Vector2(36, 0), Vector2(0, 36),
		Vector2(-36, 0), Vector2(0, -36),
	])
	draw_polyline(diamond, Color(accent, 0.95), 3.0, true)
	# Quattro tacche: una per via. Restano stabili senza animazione e senza
	# dipendere dal colore.
	for index in range(4):
		var direction := Vector2.RIGHT.rotated(float(index) * PI * 0.5)
		draw_line(direction * 59.0, direction * 70.0, Color(accent, 0.9), 4.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color("fff3b0"))
