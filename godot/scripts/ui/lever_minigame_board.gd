class_name LeverMinigameBoard
extends Control

## Tavola vettoriale di «Fulcro!»: masso, trave, cuneo mobile e mani rendono
## leggibile la fisica senza formule né testo incorporato in immagini.

const POSIZIONI := 12

var _fulcro := 8
var _peso := 20.0
var _sollevato := false
var _urto := 0.0
var _tempo := 0.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(0, 128)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(peso: float, fulcro: int, reduced_motion: bool) -> void:
	_peso = peso
	_fulcro = clampi(fulcro, 1, POSIZIONI - 1)
	_reduced_motion = reduced_motion
	queue_redraw()

func imposta_fulcro(fulcro: int) -> void:
	_fulcro = clampi(fulcro, 1, POSIZIONI - 1)
	_sollevato = false
	queue_redraw()

func mostra_esito(sollevato: bool) -> void:
	_sollevato = sollevato
	_urto = 0.0 if _reduced_motion else 1.0
	queue_redraw()

func _process(delta: float) -> void:
	_tempo += delta
	if _urto > 0.0:
		_urto = maxf(0.0, _urto - delta * 4.5)
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 100.0 or h < 80.0:
		return
	var sinistra := 64.0
	var destra := w - 62.0
	var base_y := h * 0.72
	var fulcro_x := lerpf(sinistra, destra, float(_fulcro) / float(POSIZIONI))
	var tremore := sin(_tempo * 36.0) * 2.0 * _urto
	var alzata := 16.0 if _sollevato else 0.0
	var y_sx := base_y - alzata + tremore
	var y_dx := base_y + alzata * 0.45

	draw_rect(Rect2(18, base_y + 24, w - 36, 20), Color("261b10", 0.92), true)
	draw_line(Vector2(24, base_y + 24), Vector2(w - 24, base_y + 24), Color("9a6d38", 0.55), 2.0)
	for i in 7:
		var x := 42.0 + float(i) * (w - 84.0) / 6.0
		draw_line(Vector2(x, base_y + 26), Vector2(x - 8, base_y + 40), Color("68492c", 0.45), 1.0)

	var r := clampf(27.0 + (_peso - 14.0) * 0.22, 29.0, 48.0)
	_ellisse(Vector2(sinistra, base_y + 20), Vector2(r * 1.15, 8), Color(0, 0, 0, 0.34))
	var roccia := PackedVector2Array([
		Vector2(sinistra - r, y_sx + 3), Vector2(sinistra - r * 0.72, y_sx - r * 0.72),
		Vector2(sinistra - r * 0.15, y_sx - r), Vector2(sinistra + r * 0.72, y_sx - r * 0.66),
		Vector2(sinistra + r, y_sx + 2), Vector2(sinistra + r * 0.54, y_sx + r * 0.48),
		Vector2(sinistra - r * 0.58, y_sx + r * 0.48),
	])
	draw_colored_polygon(roccia, Color("6f756f"))
	var bordo_roccia := PackedVector2Array(roccia)
	bordo_roccia.append(roccia[0])
	draw_polyline(bordo_roccia, Color("c5c8bd", 0.72), 2.0, true)
	draw_circle(Vector2(sinistra - r * 0.22, y_sx - r * 0.36), r * 0.17, Color("aeb2a8", 0.5))
	draw_line(Vector2(sinistra + 4, y_sx - r * 0.72), Vector2(sinistra + r * 0.48, y_sx - r * 0.34), Color("4d534e", 0.65), 2.0)

	draw_line(Vector2(sinistra - 4, y_sx), Vector2(destra + 6, y_dx), Color("28180c"), 18.0, true)
	draw_line(Vector2(sinistra - 4, y_sx - 1), Vector2(destra + 6, y_dx - 1), Color("b87935"), 12.0, true)
	draw_line(Vector2(sinistra, y_sx - 4), Vector2(destra, y_dx - 4), Color("e1aa58", 0.62), 2.0, true)

	var cuneo_y := lerpf(y_sx, y_dx, inverse_lerp(sinistra, destra, fulcro_x)) + 7.0
	var cuneo := PackedVector2Array([
		Vector2(fulcro_x, cuneo_y), Vector2(fulcro_x - 18, base_y + 25), Vector2(fulcro_x + 18, base_y + 25),
	])
	draw_colored_polygon(cuneo, Color("f1c85e"))
	draw_polyline(PackedVector2Array([cuneo[0], cuneo[1], cuneo[2], cuneo[0]]), Color("fff0a8"), 2.0, true)
	draw_circle(Vector2(fulcro_x, cuneo_y + 3), 4.0, Color("fff7ca"))

	var mano := Vector2(destra, y_dx - 4)
	draw_circle(mano + Vector2(4, -12), 10.0, Color("d99464"))
	for dito in 4:
		var dx := float(dito) * 6.0 - 9.0
		draw_line(mano + Vector2(dx, -20), mano + Vector2(dx + 2, -33), Color("efb07d"), 4.0, true)
	draw_line(Vector2(destra + 34, y_dx - 38), Vector2(destra + 34, y_dx - 9), Color("ff9f62"), 4.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(destra + 26, y_dx - 16), Vector2(destra + 42, y_dx - 16), Vector2(destra + 34, y_dx - 5),
	]), Color("ff9f62"))

	if _sollevato:
		for angolo in [0.2, 0.85, 1.5, 2.15]:
			var origine := Vector2(sinistra, y_sx - r - 5)
			var direzione := Vector2(cos(angolo), -absf(sin(angolo)))
			draw_line(origine + direzione * 5.0, origine + direzione * 16.0, Color("8ff6d2"), 3.0, true)

func _ellisse(centro: Vector2, raggi: Vector2, colore: Color) -> void:
	var punti := PackedVector2Array()
	for i in 25:
		var a := TAU * float(i) / 24.0
		punti.append(centro + Vector2(cos(a) * raggi.x, sin(a) * raggi.y))
	draw_colored_polygon(punti, colore)
