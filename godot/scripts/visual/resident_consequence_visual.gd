class_name ResidentConsequenceVisual
extends Node2D

## Conseguenze visibili degli archi dei residenti: puro disegno procedurale,
## nessun input e nessun vantaggio di gioco. Il pilot copre il mondo 1; gli
## altri mondi entrano solo dopo aver misurato nodi e tempo di avvio.

var resident_id := ""
var stage := 0
var high_contrast := false
var reduced_motion := false

static func supports(id: String) -> bool:
	return id in ["w01-tobia", "w01-ersilia"]

func configure(id: String, value: int, use_high_contrast: bool, use_reduced_motion: bool) -> void:
	resident_id = id
	high_contrast = use_high_contrast
	reduced_motion = use_reduced_motion
	name = "Consequence_%s" % id.replace("-", "_")
	set_meta("resident_id", resident_id)
	set_stage(value)

func set_stage(value: int) -> void:
	stage = clampi(value, 0, 2)
	set_meta("resident_stage", stage)
	set_meta("visual_semantic", _semantic())
	queue_redraw()

func _semantic() -> String:
	match resident_id:
		"w01-tobia":
			return "groups-of-ten" if stage >= 2 else "counting-guides" if stage == 1 else "ordinary-pile"
		"w01-ersilia":
			return "seven-beat-bread" if stage >= 2 else "noticed-rhythm" if stage == 1 else "ordinary-bread-basket"
	return ""

func _draw() -> void:
	match resident_id:
		"w01-tobia":
			_draw_tobia()
		"w01-ersilia":
			_draw_ersilia()

func _draw_tobia() -> void:
	var crystal := Color.WHITE if high_contrast else Color("84e8d4")
	var edge := Color.BLACK if high_contrast else Color("174d54")
	var tray := Color("f6d98a") if high_contrast else Color("8b633d")
	draw_ellipse_shadow(Vector2(0, 23), Vector2(76, 18))
	if stage >= 2:
		# Quattro gruppi nettamente separati. Ogni vassoio porta dieci cristalli:
		# il metodo di Tobia si vede senza una cifra, una barra o una spunta.
		for group in 4:
			var center := Vector2(-48 + (group % 2) * 64, -18 + (group / 2) * 48)
			draw_rect(Rect2(center - Vector2(28, 18), Vector2(56, 36)), Color(tray, 0.30), true)
			draw_rect(Rect2(center - Vector2(28, 18), Vector2(56, 36)), tray, false, 2.0)
			for index in 10:
				var p := center + Vector2(-20 + (index % 5) * 10, -7 + (index / 5) * 15)
				_draw_crystal(p, 4.2, crystal, edge)
	else:
		# Il mucchio di partenza è vivo e normale, non spento. Allo stadio 1
		# compaiono soltanto due guide: Tobia ha visto il metodo ma non è ancora
		# diventato il suo.
		for index in 22:
			var column := index % 7
			var row := index / 7
			var p := Vector2(-47 + column * 15 + (row % 2) * 5, 18 - row * 14)
			_draw_crystal(p, 5.0, crystal, edge)
		if stage == 1:
			draw_arc(Vector2(-24, 3), 30, PI, TAU, 18, tray, 2.5)
			draw_arc(Vector2(35, 2), 27, PI, TAU, 18, tray, 2.5)

func _draw_ersilia() -> void:
	var bread := Color.WHITE if high_contrast else Color("e9b96e")
	var crust := Color.BLACK if high_contrast else Color("7a4528")
	var rhythm := Color("fff47a") if high_contrast else Color("ffd75e")
	draw_ellipse_shadow(Vector2(0, 24), Vector2(78, 17))
	if stage >= 2:
		# Sette battiti uguali: la conta è diventata un metodo che si può mostrare
		# a un'altra persona. Nessun testo svela la tabellina.
		draw_line(Vector2(-66, 8), Vector2(66, 8), rhythm, 3.0)
		for index in 7:
			var p := Vector2(-60 + index * 20, 0 if index % 2 == 0 else -8)
			_draw_loaf(p, bread, crust)
			draw_circle(Vector2(p.x, 16), 2.8, rhythm)
		draw_arc(Vector2.ZERO, 82, PI * 1.13, PI * 1.87, 30, Color(rhythm, 0.70), 3.0)
	else:
		# Un cesto pieno è già un posto caldo. Lo stadio 1 aggiunge il primo ritmo,
		# non sottrae niente a chi non ha ancora chiuso l'arco.
		draw_arc(Vector2(0, 17), 55, 0.08, PI - 0.08, 24, crust, 5.0)
		for index in 7:
			var p := Vector2(-42 + (index % 4) * 28, 12 - (index / 4) * 19)
			_draw_loaf(p, bread, crust)
		if stage == 1:
			for index in 7:
				draw_circle(Vector2(-48 + index * 16, -31), 2.7, rhythm)

func _draw_crystal(center: Vector2, radius: float, fill: Color, edge: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius * 1.45),
		center + Vector2(radius, -radius * 0.25),
		center + Vector2(radius * 0.55, radius),
		center + Vector2(-radius * 0.55, radius),
		center + Vector2(-radius, -radius * 0.25),
	])
	draw_colored_polygon(points, fill)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, edge, 1.4, true)

func _draw_loaf(center: Vector2, fill: Color, edge: Color) -> void:
	draw_circle(center, 10.0, edge)
	draw_circle(center, 8.0, fill)
	draw_line(center + Vector2(-4, -5), center + Vector2(-1, 4), edge, 1.3)
	draw_line(center + Vector2(2, -5), center + Vector2(5, 3), edge, 1.3)

func draw_ellipse_shadow(center: Vector2, radii: Vector2) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, Color(0.02, 0.03, 0.04, 0.28))
