class_name SeesawMinigameBoard
extends Control

## Altalena vettoriale: pesi e distanze si vedono come oggetti, non come una
## formula. Lo spettatore cambia fra le prove, la fisica no.

var massa_sx := 2
var distanza_sx := 4
var massa_dx := 4
var distanza_dx := 4
var osservatore := 0 # 0 guarda, 1 è girato, 2 è assente
var inclinazione := 0
var _animazione := 1.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(0, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(sx: int, dsx: int, dx: int, ddx: int, chi_guarda: int, reduced_motion: bool) -> void:
	massa_sx = sx
	distanza_sx = dsx
	massa_dx = dx
	distanza_dx = ddx
	osservatore = chi_guarda
	_reduced_motion = reduced_motion
	inclinazione = 0
	_animazione = 1.0
	queue_redraw()

func imposta_distanza(destra: int) -> void:
	distanza_dx = destra
	inclinazione = 0
	queue_redraw()

func mostra_esito(esito: int) -> void:
	inclinazione = esito
	_animazione = 1.0 if _reduced_motion else 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if _animazione < 1.0:
		_animazione = minf(1.0, _animazione + delta * 4.0)
		queue_redraw()

func _draw() -> void:
	if size.x < 200.0:
		return
	var centro := Vector2(size.x * 0.5, size.y * 0.58)
	var mezzo := minf(245.0, size.x * 0.39)
	var angolo_target := float(inclinazione) * 0.105
	var angolo := lerpf(0.0, angolo_target, _morbida(_animazione))
	var direzione := Vector2(cos(angolo), sin(angolo))
	var normale := Vector2(-direzione.y, direzione.x)
	var a := centro - direzione * mezzo
	var b := centro + direzione * mezzo

	# Officina e ombra a terra.
	draw_rect(Rect2(18, size.y - 30, size.x - 36, 16), Color("22190e"), true)
	_ellisse(Vector2(centro.x, size.y - 32), Vector2(105, 9), Color(0, 0, 0, 0.28))

	# Fulcro centrale e asse di legno.
	var fulcro := PackedVector2Array([centro + Vector2(0, 4), centro + Vector2(-28, 62), centro + Vector2(28, 62)])
	draw_colored_polygon(fulcro, Color("e3bd60"))
	draw_polyline(PackedVector2Array([fulcro[0], fulcro[1], fulcro[2], fulcro[0]]), Color("fff0a8"), 2.0, true)
	draw_line(a, b, Color("25160a"), 22.0, true)
	draw_line(a - normale * 2, b - normale * 2, Color("b97936"), 15.0, true)
	draw_line(a - normale * 6, b - normale * 6, Color("e5a957", 0.66), 2.0, true)
	draw_circle(centro, 9.0, Color("f5d878"))

	# Tacche delle distanze: rendono confrontabili i due bracci.
	for d in range(1, 5):
		for segno in [-1, 1]:
			var p := centro + direzione * mezzo * float(d) / 4.6 * float(segno)
			draw_line(p - normale * 10, p + normale * 8, Color("ffe5a2", 0.62), 2.0)

	_disegna_cesta(centro - direzione * mezzo * float(distanza_sx) / 4.6, normale, massa_sx, Color("6ecfc0"))
	_disegna_cesta(centro + direzione * mezzo * float(distanza_dx) / 4.6, normale, massa_dx, Color("f1a765"))
	_disegna_osservatore(Vector2(size.x - 36, size.y - 40))

func _disegna_cesta(punto: Vector2, normale: Vector2, massa: int, colore: Color) -> void:
	var base := punto - normale * 18.0
	var larghezza := 34.0 + float(massa) * 5.0
	var cesta := Rect2(base.x - larghezza * 0.5, base.y - 29, larghezza, 29)
	draw_rect(cesta, Color(colore, 0.92), true)
	draw_rect(cesta, Color("fff2ce", 0.68), false, 2.0)
	for i in massa:
		var x := cesta.position.x + 9.0 + float(i) * (cesta.size.x - 18.0) / maxf(1.0, float(massa - 1))
		draw_circle(Vector2(x, cesta.position.y - 6), 7.0, colore.lightened(0.18))

func _disegna_osservatore(piede: Vector2) -> void:
	if osservatore == 2:
		# Impronte vuote: l'esito resta visibile anche quando nessuno è presente.
		draw_circle(piede + Vector2(-8, 0), 5.0, Color("9f8b72", 0.28))
		draw_circle(piede + Vector2(8, 0), 5.0, Color("9f8b72", 0.28))
		return
	var corpo := Color("8aa3a0", 0.9)
	draw_circle(piede + Vector2(0, -72), 14.0, Color("d89a70"))
	draw_line(piede + Vector2(0, -57), piede + Vector2(0, -20), corpo, 13.0, true)
	draw_line(piede + Vector2(0, -22), piede + Vector2(-11, 0), corpo, 7.0, true)
	draw_line(piede + Vector2(0, -22), piede + Vector2(11, 0), corpo, 7.0, true)
	var sguardo := -1.0 if osservatore == 0 else 1.0
	draw_circle(piede + Vector2(sguardo * 7.0, -75), 2.5, Color("14252a"))

func _ellisse(centro: Vector2, raggi: Vector2, colore: Color) -> void:
	var punti := PackedVector2Array()
	for i in 25:
		var a := TAU * float(i) / 24.0
		punti.append(centro + Vector2(cos(a) * raggi.x, sin(a) * raggi.y))
	draw_colored_polygon(punti, colore)

func _morbida(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
