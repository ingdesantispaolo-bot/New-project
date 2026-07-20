class_name OutdoorPortalVisual
extends Node2D

## Portale di uscita: piattaforma, vortice di archi rotanti, rune orbitanti,
## bagliore additivo e particelle ascendenti. Il visual è ancorato alla base
## (y-sort corretto con il player).

const PORTAL_TEXTURE: Texture2D = preload("res://assets/academy-portal.svg")
const ACCENT := Color("6be7d6")

var pulse := 0.0

func _ready() -> void:
	var glow := OutdoorVisualFactory.make_glow(66, ACCENT, 0.5)
	glow.position = Vector2(0, -14)
	glow.z_index = -1
	add_child(glow)
	OutdoorVisualFactory.attach_anim(glow, "pulse", 0.9, 1.0)
	var sparkles := OutdoorVisualFactory.make_sparkles(Color(ACCENT, 0.9), 26.0, 10)
	sparkles.position = Vector2(0, -10)
	sparkles.gravity = Vector2(0, -26)
	sparkles.lifetime = 2.2
	add_child(sparkles)

func _process(delta: float) -> void:
	pulse = fmod(pulse + delta, TAU * 8.0)
	queue_redraw()

func _draw() -> void:
	# piattaforma a terra
	draw_colored_polygon(OutdoorVisualFactory.ellipse_polygon(44, 15, 22), Color(0.05, 0.12, 0.14, 0.85))
	draw_colored_polygon(OutdoorVisualFactory.ellipse_polygon(36, 11.4, 20), Color(0.1, 0.24, 0.26, 0.9))
	# Pietre basse ai lati: il portale appartiene alla radura, non è un widget
	# sospeso. Restano pittura render-only e non interferiscono con l'Area2D.
	for stone in [Vector2(-37, 4), Vector2(-24, 10), Vector2(25, 10), Vector2(38, 4)]:
		draw_set_transform(stone, -0.12, Vector2(1.2, 0.58))
		draw_circle(Vector2.ZERO, 8.0, Color(0.46, 0.48, 0.42, 0.78))
		draw_circle(Vector2(-1.5, -1.5), 5.2, Color(0.68, 0.66, 0.52, 0.46))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var breath := 0.55 + sin(pulse * 2.0) * 0.15

	# icona centrale con respiro
	draw_set_transform(Vector2(0, -14), 0.0, Vector2.ONE * (0.76 + breath * 0.06))
	draw_texture(PORTAL_TEXTURE, -Vector2(48, 48))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# vortice: tre archi che ruotano a velocità diverse
	for i in range(3):
		var radius := 24.0 + float(i) * 7.0
		var start := pulse * (1.1 + float(i) * 0.35) + float(i) * 2.1
		draw_arc(Vector2(0, -14), radius, start, start + 3.4, 20, Color(ACCENT, 0.66 - float(i) * 0.14), 2.5 - float(i) * 0.45, true)

	# rune orbitanti
	for i in range(4):
		var angle := pulse * 0.9 + TAU * float(i) / 4.0
		var pos := Vector2(0, -14) + Vector2(cos(angle) * 37.0, sin(angle) * 14.0)
		var size := 3.4 + sin(pulse * 3.0 + float(i)) * 1.0
		draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), Color(ACCENT.lightened(0.3), 0.85))

	# etichetta
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-52, 30), "PORTALE", HORIZONTAL_ALIGNMENT_CENTER, 104, 12, 4, Color(0, 0, 0, 0.72))
	draw_string(font, Vector2(-52, 30), "PORTALE", HORIZONTAL_ALIGNMENT_CENTER, 104, 12, Color("e7fff8"))
