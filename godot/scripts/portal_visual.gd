class_name OutdoorPortalVisual
extends Node2D

## Portale di uscita: piattaforma, vortice di archi rotanti, rune orbitanti,
## bagliore additivo e particelle ascendenti. Il visual è ancorato alla base
## (y-sort corretto con il player).

const PORTAL_TEXTURE: Texture2D = preload("res://assets/academy-portal.svg")
const ACCENT := Color("6be7d6")

var pulse := 0.0
var gate_ready := false
var ship_complete := false
var apparatus_name := ""

func set_gate_state(ready: bool, apparatus: String, complete: bool = false) -> void:
	gate_ready = ready
	ship_complete = complete
	apparatus_name = apparatus.replace("-", " ").to_upper()
	queue_redraw()

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
	if gate_ready:
		# Beacon alto e leggibile anche quando il generatore corrente colloca
		# molti POI attorno all'ingresso. La futura safe-area lo renderà anche
		# spazialmente libero; questo mantiene già chiaro il richiamo.
		var beam_alpha := 0.08 + sin(pulse * 2.5) * 0.025
		draw_colored_polygon(
			PackedVector2Array([Vector2(-19, -18), Vector2(19, -18), Vector2(7, -154), Vector2(-7, -154)]),
			Color(Color("f6c85f"), beam_alpha)
		)
		draw_line(Vector2(0, -22), Vector2(0, -132), Color(Color("ffe6a0"), 0.30), 2.0, true)

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

	# L'ingresso è l'unico accesso alla nave e all'esame finale. Quando il gate è
	# pronto diventa anche il richiamo diegetico al rientro, senza creare un
	# secondo terminale nel mondo.
	var font := ThemeDB.fallback_font
	var label := "NAVE RIATTIVATA" if ship_complete else "ESAME PRONTO" if gate_ready else "INGRESSO NAVE"
	var label_color := Color("f6c85f") if gate_ready or ship_complete else Color("e7fff8")
	if gate_ready:
		var ready_breath := 0.72 + sin(pulse * 3.0) * 0.16
		draw_arc(Vector2(0, -14), 47.0, 0.0, TAU, 40, Color(Color("f6c85f"), ready_breath), 3.2, true)
	var plate := Rect2(-74, 18, 148, 31 if gate_ready and apparatus_name != "" else 18)
	draw_rect(plate, Color(0.015, 0.055, 0.065, 0.90), true)
	draw_rect(plate, Color(label_color, 0.72), false, 1.4, true)
	draw_string_outline(font, Vector2(-68, 30), label, HORIZONTAL_ALIGNMENT_CENTER, 136, 11, 4, Color(0, 0, 0, 0.78))
	draw_string(font, Vector2(-68, 30), label, HORIZONTAL_ALIGNMENT_CENTER, 136, 11, label_color)
	if gate_ready and apparatus_name != "":
		draw_string_outline(font, Vector2(-68, 44), apparatus_name, HORIZONTAL_ALIGNMENT_CENTER, 136, 9, 3, Color(0, 0, 0, 0.78))
		draw_string(font, Vector2(-68, 44), apparatus_name, HORIZONTAL_ALIGNMENT_CENTER, 136, 9, Color("ffe6a0"))
