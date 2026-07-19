class_name OutdoorPortalVisual
extends Node2D

var pulse := 0.0
const PORTAL_TEXTURE: Texture2D = preload("res://assets/academy-portal.svg")

func _process(delta: float) -> void:
	pulse = fmod(pulse + delta, TAU)
	queue_redraw()

func _draw() -> void:
	var glow := 0.55 + sin(pulse * 2.0) * 0.15
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * (0.92 + glow * 0.08))
	draw_texture(PORTAL_TEXTURE, -Vector2(48, 48))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 52), "PORTALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e7fff8"))
