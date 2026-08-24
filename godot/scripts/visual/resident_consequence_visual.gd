class_name ResidentConsequenceVisual
extends Node2D

## Conseguenze visibili degli archi dei residenti: puro disegno procedurale,
## nessun input e nessun vantaggio di gioco. Il pilot copre il mondo 1; gli
## altri mondi entrano solo dopo aver misurato nodi e tempo di avvio.

var resident_id := ""
var stage := 0
var high_contrast := false
var reduced_motion := false

const SUPPORTED_IDS := [
	"w01-tobia", "w01-ersilia", "w02-corinna", "w02-bruno", "w03-ruggine", "w03-sesto",
	"w04-marea", "w04-lino", "w05-gerbo", "w05-tilla", "w06-ambra", "w06-oreste",
	"w07-livia", "w07-zeno", "w08-ciro", "w08-doria", "w09-alma", "w09-remo",
	"w10-ortensia", "w10-mirta", "w11-danio", "w11-vesta", "w12-quinto", "w12-isa",
	"w13-solano", "w13-duna", "w14-elmo", "w14-ottavia", "w15-gru", "w15-pila",
	"w16-talia", "w16-marco", "w17-nerea", "w17-coral", "w18-silo", "w18-bea",
	"w19-numa", "w19-fiorina", "w20-sferza", "w20-quieto", "w21-terza", "w21-mino",
	"w22-vesca", "w22-fondo", "w23-cronia", "w23-ovidio",
]

static func supports(id: String) -> bool:
	return id in SUPPORTED_IDS

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
		"w02-corinna":
			return "function-shelves" if stage >= 2 else "function-tabs" if stage == 1 else "length-sorted-cards"
		"w02-bruno":
			return "shared-dictionary" if stage >= 2 else "word-workbench" if stage == 1 else "hidden-word-notes"
		"w03-ruggine":
			return "working-cycle" if stage >= 2 else "counted-loop" if stage == 1 else "hand-crank"
		"w03-sesto":
			return "restored-toolbox" if stage >= 2 else "remembered-gesture" if stage == 1 else "scattered-tools"
		"w04-marea":
			return "open-signal-route" if stage >= 2 else "tuned-receiver" if stage == 1 else "silent-receiver"
		"w04-lino":
			return "shared-message-flags" if stage >= 2 else "ordered-flags" if stage == 1 else "folded-flags"
		"w05-gerbo":
			return "balanced-loads" if stage >= 2 else "marked-loads" if stage == 1 else "uneven-loads"
		"w05-tilla":
			return "moving-workshop" if stage >= 2 else "ready-lever" if stage == 1 else "stalled-lever"
	return "%s:%s" % [resident_id, "shared-work" if stage >= 2 else "ordered-work" if stage == 1 else "work-in-progress"]

func _draw() -> void:
	match resident_id:
		"w01-tobia":
			_draw_tobia()
		"w01-ersilia":
			_draw_ersilia()
		"w02-corinna":
			_draw_corinna()
		"w02-bruno":
			_draw_bruno()
		"w03-ruggine":
			_draw_ruggine()
		"w03-sesto":
			_draw_sesto()
		"w04-marea":
			_draw_marea()
		"w04-lino":
			_draw_lino()
		"w05-gerbo":
			_draw_gerbo()
		"w05-tilla":
			_draw_tilla()
		_:
			_draw_general_consequence()

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

func _draw_corinna() -> void:
	var paper := Color.WHITE if high_contrast else Color("e7d7ad")
	var edge := Color.BLACK if high_contrast else Color("6a4e37")
	var accent := Color.WHITE if high_contrast else Color("82c9a1")
	draw_ellipse_shadow(Vector2(0, 24), Vector2(76, 17))
	for index in 6:
		var p := Vector2(-54 + (index % 3) * 42, -18 + (index / 3) * 33)
		draw_rect(Rect2(p, Vector2(31, 24)), paper, true)
		draw_rect(Rect2(p, Vector2(31, 24)), edge, false, 1.5)
		if stage >= 1:
			draw_rect(Rect2(p, Vector2(5, 24)), accent, true)
	if stage >= 2:
		for x in [-50.0, 0.0, 50.0]:
			draw_line(Vector2(x - 18, 19), Vector2(x + 18, 19), edge, 3.0)
			draw_circle(Vector2(x, -29), 5.0, accent)

func _draw_bruno() -> void:
	var paper := Color.WHITE if high_contrast else Color("f4dc9b")
	var edge := Color.BLACK if high_contrast else Color("70503d")
	var ink := Color.WHITE if high_contrast else Color("a78cff")
	draw_ellipse_shadow(Vector2(0, 24), Vector2(76, 17))
	for index in 5:
		var p := Vector2(-48 + index * 24, 4 - (index % 2) * 15)
		draw_rect(Rect2(p, Vector2(20, 28)), paper, true)
		draw_rect(Rect2(p, Vector2(20, 28)), edge, false, 1.4)
	if stage >= 1:
		for index in 3:
			draw_circle(Vector2(-28 + index * 28, -34), 6.0, ink)
	if stage >= 2:
		draw_rect(Rect2(-61, -49, 122, 12), ink, true)
		draw_rect(Rect2(-61, -49, 122, 12), edge, false, 2.0)

func _draw_ruggine() -> void:
	var metal := Color.WHITE if high_contrast else Color("a8b7bd")
	var edge := Color.BLACK if high_contrast else Color("3d4a52")
	var spark := Color.WHITE if high_contrast else Color("ffcb67")
	draw_ellipse_shadow(Vector2(0, 25), Vector2(78, 17))
	draw_circle(Vector2(-22, 0), 25.0, metal)
	draw_arc(Vector2(-22, 0), 25.0, 0.0, TAU, 24, edge, 3.0)
	draw_line(Vector2(-22, 0), Vector2(34, -42), edge, 6.0)
	draw_circle(Vector2(34, -42), 8.0, metal)
	if stage >= 1:
		draw_arc(Vector2(22, -5), 31.0, -0.4, 5.8, 26, spark, 3.0)
	if stage >= 2:
		for x in [-4.0, 27.0, 58.0]:
			draw_circle(Vector2(x, 10), 11.0, spark)
			draw_arc(Vector2(x, 10), 11.0, 0.0, TAU, 16, edge, 2.0)

func _draw_sesto() -> void:
	var tool := Color.WHITE if high_contrast else Color("8fc9e6")
	var edge := Color.BLACK if high_contrast else Color("35536b")
	var memory := Color.WHITE if high_contrast else Color("d9a6ff")
	draw_ellipse_shadow(Vector2(0, 25), Vector2(78, 17))
	for index in 4:
		var p := Vector2(-49 + index * 31, 6 - (index % 2) * 23)
		draw_line(p, p + Vector2(17, -16), tool, 5.0)
		draw_circle(p + Vector2(17, -16), 6.0, edge)
	if stage >= 1:
		draw_circle(Vector2(0, -38), 10.0, memory)
	if stage >= 2:
		draw_rect(Rect2(-61, -48, 122, 15), tool, true)
		draw_rect(Rect2(-61, -48, 122, 15), edge, false, 2.0)

func _draw_marea() -> void:
	var wire := Color.WHITE if high_contrast else Color("76dff5")
	var edge := Color.BLACK if high_contrast else Color("31536c")
	draw_ellipse_shadow(Vector2(0, 25), Vector2(76, 17))
	draw_rect(Rect2(-18, -10, 36, 31), edge, true)
	draw_rect(Rect2(-14, -6, 28, 23), wire, true)
	if stage >= 1:
		draw_arc(Vector2(0, 5), 35, PI * 1.18, PI * 1.82, 20, wire, 2.5)
	if stage >= 2:
		for x in [-50.0, 50.0]:
			draw_line(Vector2(0, 5), Vector2(x, -26), wire, 2.5)
			draw_circle(Vector2(x, -26), 6.0, wire)

func _draw_lino() -> void:
	var cloth := Color.WHITE if high_contrast else Color("f0bf72")
	var edge := Color.BLACK if high_contrast else Color("6d4935")
	draw_ellipse_shadow(Vector2(0, 25), Vector2(76, 17))
	for index in 4:
		var p := Vector2(-54 + index * 32, 4)
		draw_rect(Rect2(p, Vector2(22, 18)), cloth if stage > 0 else edge, true)
		if stage >= 1:
			draw_line(p + Vector2(11, 0), p + Vector2(11, -34), edge, 2.0)
	if stage >= 2:
		draw_line(Vector2(-60, -31), Vector2(60, -31), cloth, 3.0)

func _draw_gerbo() -> void:
	var load := Color.WHITE if high_contrast else Color("e7c47d")
	var edge := Color.BLACK if high_contrast else Color("5d4733")
	draw_ellipse_shadow(Vector2(0, 25), Vector2(76, 17))
	for index in 3:
		var height := 18.0 if stage == 0 and index == 1 else 28.0
		var rect := Rect2(-51 + index * 38, 18 - height, 28, height)
		draw_rect(rect, load, true)
		draw_rect(rect, edge, false, 2.0)
		if stage >= 1:
			draw_line(Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, 24), edge, 1.5)
	if stage >= 2:
		draw_line(Vector2(-60, 25), Vector2(60, 25), edge, 3.0)

func _draw_tilla() -> void:
	var metal := Color.WHITE if high_contrast else Color("b9c9d2")
	var accent := Color.WHITE if high_contrast else Color("ffcb68")
	var edge := Color.BLACK if high_contrast else Color("3d4d59")
	draw_ellipse_shadow(Vector2(0, 25), Vector2(76, 17))
	draw_rect(Rect2(-48, -5, 96, 24), metal, true)
	draw_rect(Rect2(-48, -5, 96, 24), edge, false, 2.0)
	draw_line(Vector2(-8, -5), Vector2(20, -42), edge, 5.0)
	if stage >= 1:
		draw_circle(Vector2(20, -42), 8.0, accent)
	if stage >= 2:
		for x in [-34.0, 0.0, 34.0]:
			draw_circle(Vector2(x, 28), 8.0, accent)

## Dal mondo 6 in poi il gesto e' deliberatamente comune: un banco di lavoro
## passa da materiale sparso, a materiale ordinato, a lavoro che si puo' usare
## insieme. Cambiano il colore e il ritmo per abitante, non una regola o un
## premio. I primi cinque mondi restano autoriali perche' sono quelli che il
## bambino incontra prima e deve poter riconoscere subito.
func _draw_general_consequence() -> void:
	var hue := float(abs(resident_id.hash()) % 360) / 360.0
	var fill := Color.WHITE if high_contrast else Color.from_hsv(hue, 0.42, 0.92)
	var edge := Color.BLACK if high_contrast else Color.from_hsv(hue, 0.52, 0.34)
	var accent := Color.WHITE if high_contrast else Color.from_hsv(fposmod(hue + 0.12, 1.0), 0.55, 1.0)
	draw_ellipse_shadow(Vector2(0, 24), Vector2(77, 17))
	var columns := 4
	for index in 8:
		var position := Vector2(-51 + float(index % columns) * 34, 9 - float(index / columns) * 24)
		if stage == 0:
			position += Vector2(float((index * 13) % 11) - 5.0, float((index * 7) % 9) - 4.0)
		var tile_size := Vector2(19, 15) if stage < 2 else Vector2(22, 17)
		draw_rect(Rect2(position, tile_size), fill, true)
		draw_rect(Rect2(position, tile_size), edge, false, 1.7)
		if stage >= 1:
			draw_circle(position + tile_size * 0.5, 2.5, accent)
	if stage >= 1:
		draw_line(Vector2(-62, 25), Vector2(62, 25), accent, 2.4)
	if stage >= 2:
		for column in range(columns - 1):
			var x := -41 + float(column) * 34
			draw_line(Vector2(x, -8), Vector2(x + 34, -8), accent, 2.2)
		draw_arc(Vector2(0, 1), 76, PI * 1.12, PI * 1.88, 28, accent, 2.8)

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
