extends Control

## Superficie visuale data-driven per hotspot, grafici, circuiti, notazione e carte. Non conosce
## risposte, mastery o ricompense: disegna soltanto il modello fornito.

var diagram_kind := ""
var model: Dictionary = {}
var background_texture: Texture2D
var selected_id := ""
var feedback_state := ""
var feedback_started_msec := 0
var cycle_sequence: Array = []
var cycle_feedback_state := ""

func configure(kind: String, data: Dictionary) -> void:
	diagram_kind = kind
	model = data.duplicate(true)
	var background_path := str(model.get("image", ""))
	background_texture = load(background_path) as Texture2D if background_path != "" and ResourceLoader.exists(background_path) else null
	cycle_sequence = []
	cycle_feedback_state = ""
	custom_minimum_size = Vector2(0, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	if diagram_kind == "map" and not resized.is_connected(layout_map_targets):
		resized.connect(layout_map_targets)
	if diagram_kind == "hotspot" and not resized.is_connected(layout_hotspot_targets):
		resized.connect(layout_hotspot_targets)
	queue_redraw()

func _process(_delta: float) -> void:
	if selected_id != "":
		queue_redraw()

func set_feedback(id: String, state: String) -> void:
	selected_id = id
	feedback_state = state
	feedback_started_msec = Time.get_ticks_msec()
	queue_redraw()

func set_cycle_sequence(sequence: Array, state: String = "") -> void:
	cycle_sequence = sequence.duplicate()
	cycle_feedback_state = state
	feedback_started_msec = Time.get_ticks_msec()
	queue_redraw()

func cycle_anchor(index: int, total: int) -> Vector2:
	var count := maxi(3, total)
	var angle := -PI * 0.5 + TAU * float(index) / float(count)
	# Margine verticale maggiore di quello orizzontale: sotto ogni glifo vive
	# l'etichetta data-driven, che a 900×600 non deve toccare il bordo/CTA.
	return Vector2(0.52 + cos(angle) * 0.31, 0.48 + sin(angle) * 0.23)

func point_position(point: Dictionary) -> Vector2:
	var normalized := Vector2(
		clampf(float(point.get("x", 0.5)), 0.05, 0.95),
		clampf(float(point.get("y", 0.5)), 0.05, 0.95)
	)
	return Vector2(normalized.x * size.x, normalized.y * size.y)

func hotspot_anchor(target_id: String) -> Vector2:
	for entry in model.get("hotspots", []):
		var target := entry as Dictionary
		if str(target.get("id", "")) == target_id:
			var position := hotspot_position(target)
			return Vector2(position.x / maxf(size.x, 1.0), position.y / maxf(size.y, 1.0))
	return Vector2(0.5, 0.5)

func hotspot_position(target: Dictionary) -> Vector2:
	var rect := _hotspot_image_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)))
	return rect.position + Vector2(
		clampf(float(target.get("x", 0.5)), 0.0, 1.0) * rect.size.x,
		clampf(float(target.get("y", 0.5)), 0.0, 1.0) * rect.size.y
	)

func layout_hotspot_targets() -> void:
	for child in get_children():
		if child is Control and child.has_meta("hotspot_target_id"):
			var control := child as Control
			var center := hotspot_anchor(str(control.get_meta("hotspot_target_id")))
			control.anchor_left = center.x
			control.anchor_right = center.x
			control.anchor_top = center.y
			control.anchor_bottom = center.y

func _draw() -> void:
	var bounds := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_style_box(_panel_style(), bounds)
	match diagram_kind:
		"graph":
			_draw_graph(bounds)
		"circuit":
			_draw_circuit(bounds)
		"notation":
			_draw_notation(bounds)
		"map":
			_draw_map(bounds)
		"cycle":
			_draw_cycle(bounds)
		"number_line":
			_draw_number_line(bounds)
		_:
			_draw_hotspot(bounds)
	_draw_selection_feedback()

func _draw_selection_feedback() -> void:
	if diagram_kind == "cycle":
		return
	if selected_id == "":
		return
	var points: Array = (
		model.get("hotspots", [])
		if diagram_kind == "hotspot"
		else model.get("points", [])
		if diagram_kind == "graph"
		else model.get("components", [])
		if diagram_kind == "circuit"
		else model.get("symbols", []) if diagram_kind == "notation"
		else model.get("targets", [])
	)
	for point_data in points:
		var point: Dictionary = point_data
		if str(point.get("id", "")) != selected_id:
			continue
		var center := (
			_graph_feedback_position(point)
			if diagram_kind == "graph"
			else _map_target_position(str(point.get("id", "")))
			if diagram_kind == "map"
			else _notation_position(point)
			if diagram_kind == "notation"
			else hotspot_position(point)
			if diagram_kind == "hotspot" and background_texture != null
			else point_position(point)
		)
		var age := float(Time.get_ticks_msec() - feedback_started_msec) / 1000.0
		var pulse := 0.5 + 0.5 * sin(age * 12.0)
		var color := (
			Color("8ff6c0") if feedback_state == "correct"
			else Color("ff8f9b") if feedback_state == "error"
			else Color("f6c85f")
		)
		if diagram_kind == "graph":
			draw_line(Vector2(center.x, size.y - 46.0), center, Color(color, 0.42), 2.0, true)
			draw_line(Vector2(56.0, center.y), center, Color(color, 0.42), 2.0, true)
		var radius := 22.0 if diagram_kind == "map" else 30.0
		draw_circle(center, radius + pulse * 4.0, Color(color, 0.12))
		draw_arc(center, radius - 3.0 + pulse * 3.0, 0.0, TAU, 40, color, 3.0, true)
		break

func _graph_feedback_position(point: Dictionary) -> Vector2:
	var bounds := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	var origin := Vector2(bounds.position.x + 48, bounds.end.y - 38)
	var end_x := Vector2(bounds.end.x - 24, origin.y)
	var end_y := Vector2(origin.x, bounds.position.y + 24)
	return _graph_position(point, origin, end_x, end_y)

func _draw_graph(bounds: Rect2) -> void:
	var origin := Vector2(bounds.position.x + 48, bounds.end.y - 38)
	var end_x := Vector2(bounds.end.x - 24, origin.y)
	var end_y := Vector2(origin.x, bounds.position.y + 24)
	draw_line(origin, end_x, Color("b8d7dc"), 2.0)
	draw_line(origin, end_y, Color("b8d7dc"), 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(end_x.x - 70, origin.y - 9), str(model.get("xLabel", "x")), HORIZONTAL_ALIGNMENT_RIGHT, 68, 13, Color("b8d7dc"))
	draw_string(font, Vector2(origin.x + 8, end_y.y + 15), str(model.get("yLabel", "y")), HORIZONTAL_ALIGNMENT_LEFT, 80, 13, Color("b8d7dc"))
	for step in range(1, 5):
		var tx := lerpf(origin.x, end_x.x, float(step) / 5.0)
		var ty := lerpf(origin.y, end_y.y, float(step) / 5.0)
		draw_line(Vector2(tx, origin.y - 4), Vector2(tx, origin.y + 4), Color("75999f"), 1.0)
		draw_line(Vector2(origin.x - 4, ty), Vector2(origin.x + 4, ty), Color("75999f"), 1.0)
	var previous := Vector2.INF
	for point in model.get("points", []):
		var p := _graph_position(point, origin, end_x, end_y)
		if previous != Vector2.INF:
			draw_line(previous, p, Color("6be7d6"), 3.0, true)
		draw_circle(p, 6.0, Color("f6c85f"))
		previous = p

func _graph_position(point: Dictionary, origin: Vector2, end_x: Vector2, end_y: Vector2) -> Vector2:
	var x := clampf(float(point.get("x", 0.5)), 0.0, 1.0)
	var y := clampf(float(point.get("y", 0.5)), 0.0, 1.0)
	return Vector2(lerpf(origin.x, end_x.x, x), lerpf(origin.y, end_y.y, y))

func _draw_circuit(_bounds: Rect2) -> void:
	var positions: Dictionary = {}
	for component in model.get("components", []):
		var id := str((component as Dictionary).get("id", ""))
		positions[id] = point_position(component)
	for edge in model.get("connections", []):
		if not edge is Array or edge.size() < 2:
			continue
		var a: Vector2 = positions.get(str(edge[0]), Vector2.ZERO)
		var b: Vector2 = positions.get(str(edge[1]), Vector2.ZERO)
		draw_line(a, b, Color(0.10, 0.55, 0.60, 0.85), 8.0, true)
		draw_line(a, b, Color("8ff6d2"), 2.5, true)
	for component in model.get("components", []):
		var p := point_position(component)
		draw_circle(p, 24.0, Color(0.02, 0.12, 0.15, 0.98))
		draw_arc(p, 24.0, 0.0, TAU, 28, Color("f6c85f"), 2.5, true)

func _draw_notation(bounds: Rect2) -> void:
	var ink := Color("d8fff8")
	var muted := Color(0.45, 0.68, 0.70, 0.72)
	var staff_left := bounds.position.x + 46.0
	var staff_right := bounds.end.x - 18.0
	for line in range(5):
		var y := size.y * (0.68 - float(line * 2) * 0.045)
		draw_line(Vector2(staff_left, y), Vector2(staff_right, y), muted, 2.0, true)
	_draw_clef(str((model.get("staff", {}) as Dictionary).get("clef", "treble")), Vector2(staff_left + 16.0, size.y * 0.50), ink)
	for entry in model.get("symbols", []):
		var symbol := entry as Dictionary
		var center := _notation_position(symbol)
		_draw_ledger_lines(symbol, center, ink)
		match str(symbol.get("kind", "note")):
			"rest":
				_draw_rest(center, str(symbol.get("duration", "quarter")), ink)
			"accidental":
				_draw_accidental(center, str(symbol.get("accidental", "natural")), ink)
			_:
				_draw_note(center, int(symbol.get("staffStep", 0)), str(symbol.get("duration", "quarter")), ink)

func _draw_cycle(_bounds: Rect2) -> void:
	var stages: Array = model.get("stages", [])
	var positions: Dictionary = {}
	for index in stages.size():
		var stage := stages[index] as Dictionary
		positions[str(stage.get("id", ""))] = _cycle_position(index, stages.size())
	var link_color := (
		Color("8ff6c0") if cycle_feedback_state == "correct"
		else Color("ff8f9b") if cycle_feedback_state == "error"
		else Color("f6c85f")
	)
	for index in range(1, cycle_sequence.size()):
		var from: Vector2 = positions.get(str(cycle_sequence[index - 1]), Vector2.ZERO)
		var to: Vector2 = positions.get(str(cycle_sequence[index]), Vector2.ZERO)
		_draw_arrow(from, to, link_color)
	var font := ThemeDB.fallback_font
	for index in stages.size():
		var stage := stages[index] as Dictionary
		var id := str(stage.get("id", ""))
		var center: Vector2 = positions[id]
		var selected_step := cycle_sequence.find(id)
		var outline := link_color if selected_step >= 0 else Color("6baeb2")
		draw_circle(center, 27.0, Color(0.02, 0.12, 0.15, 0.98))
		draw_arc(center, 27.0, 0.0, TAU, 32, outline, 3.0 if selected_step >= 0 else 2.0, true)
		_draw_cycle_glyph(center, str(stage.get("glyph", "")), Color("d8fff8"))
		draw_string(font, center + Vector2(-55, 45), str(stage.get("label", "")), HORIZONTAL_ALIGNMENT_CENTER, 110, 12, Color("d8fff8"))
		if selected_step >= 0:
			var badge := center + Vector2(22, -22)
			draw_circle(badge, 11.0, link_color)
			draw_string(font, badge + Vector2(-7, 5), str(selected_step + 1), HORIZONTAL_ALIGNMENT_CENTER, 14, 12, Color("06272a"))

func map_anchor(target_id: String) -> Vector2:
	var geometry := model.get("geometry", {}) as Dictionary
	var geographic := (geometry.get("targets", {}) as Dictionary).get(target_id, Vector2.ZERO) as Vector2
	if size.x < 100.0 or size.y < 100.0:
		var geo_bounds: Rect2 = geometry.get("bounds", Rect2(0, 0, 1, 1))
		return Vector2(
			(geographic.x - geo_bounds.position.x) / geo_bounds.size.x,
			(geo_bounds.end.y - geographic.y) / geo_bounds.size.y
		)
	var bounds := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	var screen := _map_project(geographic, bounds)
	return Vector2(screen.x / maxf(size.x, 1.0), screen.y / maxf(size.y, 1.0))

func layout_map_targets() -> void:
	if diagram_kind != "map":
		return
	for child in get_children():
		if not child is Control or not child.has_meta("map_target_id"):
			continue
		var anchor := map_anchor(str(child.get_meta("map_target_id")))
		(child as Control).anchor_left = anchor.x
		(child as Control).anchor_right = anchor.x
		(child as Control).anchor_top = anchor.y
		(child as Control).anchor_bottom = anchor.y

func _map_target_position(target_id: String) -> Vector2:
	var anchor := map_anchor(target_id)
	return Vector2(anchor.x * size.x, anchor.y * size.y)

func _draw_map(bounds: Rect2) -> void:
	var geometry := model.get("geometry", {}) as Dictionary
	var land_fill := Color("183f3b")
	var coast := Color("9be6c7")
	for raw_polygon in geometry.get("polygons", []):
		var projected := PackedVector2Array()
		for geographic in raw_polygon as PackedVector2Array:
			projected.append(_map_project(geographic, bounds))
		if projected.size() >= 3:
			draw_colored_polygon(projected, land_fill)
			draw_polyline(projected, coast, 2.4, true)
	for line_id in (geometry.get("lines", {}) as Dictionary).keys():
		var projected := PackedVector2Array()
		for geographic in (geometry["lines"] as Dictionary)[line_id] as PackedVector2Array:
			projected.append(_map_project(geographic, bounds))
		if projected.size() >= 2:
			draw_polyline(projected, Color("72c9ff"), 4.0, true)

func _map_project(geographic: Vector2, bounds: Rect2) -> Vector2:
	var geometry := model.get("geometry", {}) as Dictionary
	var geo_bounds: Rect2 = geometry.get("bounds", Rect2(0, 0, 1, 1))
	var available := bounds.grow(-10.0)
	var scale := minf(available.size.x / geo_bounds.size.x, available.size.y / geo_bounds.size.y)
	var rendered_size := geo_bounds.size * scale
	var origin := available.get_center() - rendered_size * 0.5
	return origin + Vector2(
		(geographic.x - geo_bounds.position.x) * scale,
		(geo_bounds.end.y - geographic.y) * scale
	)

func _cycle_position(index: int, total: int) -> Vector2:
	var anchor := cycle_anchor(index, total)
	return Vector2(anchor.x * size.x, anchor.y * size.y)

func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	var direction := (to - from).normalized()
	if direction == Vector2.ZERO:
		return
	var start := from + direction * 31.0
	var end := to - direction * 31.0
	draw_line(start, end, Color(color, 0.86), 4.0, true)
	var normal := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([end, end - direction * 13.0 + normal * 7.0, end - direction * 13.0 - normal * 7.0])
	draw_colored_polygon(arrow, color)

func _draw_cycle_glyph(center: Vector2, glyph: String, ink: Color) -> void:
	match glyph:
		"sun":
			draw_circle(center, 9.0, Color("f6c85f"))
			for ray in range(8):
				var direction := Vector2.RIGHT.rotated(TAU * float(ray) / 8.0)
				draw_line(center + direction * 13.0, center + direction * 20.0, Color("f6c85f"), 2.4, true)
		"water":
			var drop := PackedVector2Array([center + Vector2(0, -19), center + Vector2(13, 5), center + Vector2(8, 15), center + Vector2(0, 19), center + Vector2(-8, 15), center + Vector2(-13, 5)])
			draw_colored_polygon(drop, Color("72c9ff"))
		"cloud", "rain":
			draw_circle(center + Vector2(-10, 1), 9.0, ink)
			draw_circle(center + Vector2(0, -6), 12.0, ink)
			draw_circle(center + Vector2(12, 1), 9.0, ink)
			draw_rect(Rect2(center + Vector2(-18, 0), Vector2(38, 9)), ink)
			if glyph == "rain":
				for x in [-10.0, 0.0, 10.0]:
					draw_line(center + Vector2(x, 12), center + Vector2(x - 4, 20), Color("72c9ff"), 2.4, true)
		"plant", "leaf":
			draw_line(center + Vector2(0, 18), center + Vector2(0, -13), Color("91dc72"), 3.0, true)
			for offset in [Vector2(-8, -4), Vector2(8, -11)]:
				draw_set_transform(center + offset, -0.45 if offset.x < 0 else 0.45, Vector2(1.45, 0.72))
				draw_circle(Vector2.ZERO, 7.0, Color("91dc72"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"air":
			for y in [-9.0, 0.0, 9.0]:
				draw_arc(center + Vector2(-4, y), 13.0, -PI * 0.55, PI * 0.25, 14, ink, 2.4, true)
		"animal":
			draw_circle(center + Vector2(0, 7), 10.0, ink)
			for offset in [Vector2(-12, -7), Vector2(-4, -13), Vector2(5, -13), Vector2(13, -7)]:
				draw_circle(center + offset, 4.5, ink)
		"soil":
			draw_rect(Rect2(center + Vector2(-18, -12), Vector2(36, 25)), Color("d4b17a"))
			for y in [-5.0, 4.0]:
				draw_line(center + Vector2(-15, y), center + Vector2(15, y), Color("72563b"), 2.0, true)
		"gear":
			draw_arc(center, 11.0, 0.0, TAU, 20, ink, 3.0, true)
			for dente in range(8):
				var d := Vector2.RIGHT.rotated(TAU * float(dente) / 8.0)
				draw_line(center + d * 12.0, center + d * 18.0, ink, 3.0, true)
		"arrow":
			draw_line(center + Vector2(-16, 0), center + Vector2(10, 0), ink, 3.0, true)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(18, 0), center + Vector2(6, -8), center + Vector2(6, 8)]), ink)
		"check":
			draw_line(center + Vector2(-13, 1), center + Vector2(-4, 11), Color("91dc72"), 3.4, true)
			draw_line(center + Vector2(-4, 11), center + Vector2(14, -11), Color("91dc72"), 3.4, true)
		"clock":
			draw_arc(center, 16.0, 0.0, TAU, 24, ink, 2.6, true)
			draw_line(center, center + Vector2(0, -10), ink, 2.6, true)
			draw_line(center, center + Vector2(7, 3), ink, 2.6, true)
		"rock":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-16, 8), center + Vector2(-8, -12), center + Vector2(9, -13),
				center + Vector2(17, 3), center + Vector2(4, 14)]), Color("9299a8"))
		"fire":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -18), center + Vector2(11, 2), center + Vector2(5, 15),
				center + Vector2(-5, 15), center + Vector2(-11, 2)]), Color("ff8f5e"))
		"pen":
			draw_line(center + Vector2(-12, 13), center + Vector2(11, -12), ink, 3.4, true)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(13, -15), center + Vector2(8, -8), center + Vector2(15, -9)]), Color("f6c85f"))
		"note":
			draw_circle(center + Vector2(-5, 10), 7.0, ink)
			draw_line(center + Vector2(2, 10), center + Vector2(2, -14), ink, 2.6, true)
			draw_line(center + Vector2(2, -14), center + Vector2(14, -10), ink, 2.6, true)
		"book":
			draw_rect(Rect2(center + Vector2(-15, -12), Vector2(30, 24)), ink, false, 2.6)
			draw_line(center + Vector2(0, -12), center + Vector2(0, 12), ink, 2.2, true)
		"question":
			draw_arc(center + Vector2(0, -5), 9.0, PI, TAU + PI * 0.4, 18, ink, 3.0, true)
			draw_line(center + Vector2(3, 3), center + Vector2(1, 8), ink, 3.0, true)
			draw_circle(center + Vector2(1, 15), 2.6, ink)
		"bolt":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(2, -18), center + Vector2(-9, 2), center + Vector2(-1, 2),
				center + Vector2(-3, 18), center + Vector2(10, -3), center + Vector2(1, -3)]), Color("f6c85f"))
		"sugar":
			var hexagon := PackedVector2Array()
			for point in range(6):
				hexagon.append(center + Vector2.RIGHT.rotated(TAU * float(point) / 6.0) * 16.0)
			draw_polyline(PackedVector2Array(Array(hexagon) + [hexagon[0]]), Color("f6c85f"), 3.0, true)
		"oxygen":
			for offset in [Vector2(-9, 4), Vector2(6, -7), Vector2(10, 10)]:
				draw_arc(center + offset, 7.0, 0.0, TAU, 18, Color("72c9ff"), 2.4, true)
		"carbon":
			draw_arc(center, 16.0, 0.0, TAU, 24, ink, 3.0, true)
			draw_circle(center + Vector2(-5, -3), 3.0, ink)
			draw_circle(center + Vector2(6, 4), 3.0, ink)
		"egg":
			draw_set_transform(center, 0.0, Vector2(0.78, 1.18))
			draw_circle(Vector2.ZERO, 13.0, Color("f6e6c8"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"larva":
			for x in [-12.0, -4.0, 4.0, 12.0]:
				draw_circle(center + Vector2(x, sin(x) * 3.0), 7.0, Color("91dc72"))
		"chrysalis":
			draw_set_transform(center, 0.18, Vector2(0.72, 1.35))
			draw_circle(Vector2.ZERO, 12.0, Color("d4b17a"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"butterfly":
			for offset in [Vector2(-9, -5), Vector2(9, -5), Vector2(-8, 9), Vector2(8, 9)]:
				draw_circle(center + offset, 8.0, Color("d7a0ff"))
			draw_line(center + Vector2(0, -12), center + Vector2(0, 16), ink, 3.0, true)

func _notation_position(symbol: Dictionary) -> Vector2:
	var anchor := notation_anchor(str(symbol.get("id", "")))
	return Vector2(anchor.x * size.x, anchor.y * size.y)

## La posizione verticale è musicale: ogni `staffStep` avanza di uno spazio o
## di una riga (0,2,4,6,8 sono le cinque righe dal basso). Quella orizzontale è
## resa: deriva dall'ordine di presentazione, mai da coordinate nel contenuto.
## La retta numerica. Tutta disegnata: una linea, le tacche, le etichette dei
## soli estremi e dei riferimenti dichiarati. Niente immagini.
##
## Perché serve: a livello 1 matematica non aveva nessun formato visuale — solo
## abbinamenti, ordinamenti e smistamenti di testo. La retta è il primo posto in
## cui un numero smette di essere un simbolo e diventa una posizione, ed è quello
## che rende visibili le frazioni, i decimali e i negativi.
func _draw_number_line(bounds: Rect2) -> void:
	var ink := Color("d8fff8")
	var y := bounds.position.y + bounds.size.y * 0.58
	var x0 := bounds.position.x + bounds.size.x * 0.10
	var x1 := bounds.position.x + bounds.size.x * 0.90
	draw_line(Vector2(x0, y), Vector2(x1, y), ink, 2.6, true)
	# Le punte: dicono che la retta continua oltre ciò che si vede.
	for verso in [-1.0, 1.0]:
		var punta := Vector2(x1 if verso > 0.0 else x0, y)
		draw_colored_polygon(PackedVector2Array([
			punta + Vector2(9.0 * verso, 0), punta + Vector2(-2.0 * verso, -6),
			punta + Vector2(-2.0 * verso, 6)]), ink)

	var minimo := float(model.get("min", 0.0))
	var massimo := float(model.get("max", 10.0))
	var passo := maxf(0.0001, float(model.get("tick", 1.0)))
	var estensione := maxf(0.0001, massimo - minimo)
	var valore := minimo
	while valore <= massimo + 0.0001:
		var frazione := (valore - minimo) / estensione
		var x := lerpf(x0, x1, frazione)
		var alta := absf(valore - minimo) < 0.0001 or absf(valore - massimo) < 0.0001
		draw_line(Vector2(x, y - (13.0 if alta else 7.0)), Vector2(x, y + (13.0 if alta else 7.0)),
			ink, 2.4 if alta else 1.6, true)
		valore += passo

	# Solo gli estremi e i riferimenti dichiarati portano un numero scritto: una
	# retta con tutte le etichette si legge come una tabella, e allora non serve.
	var font := ThemeDB.fallback_font
	for voce in Array(model.get("labels", [])):
		var etichetta := voce as Dictionary
		var v := float(etichetta.get("value", 0.0))
		var x := lerpf(x0, x1, (v - minimo) / estensione)
		var testo := str(etichetta.get("text", ""))
		draw_string(font, Vector2(x - testo.length() * 3.4, y + 32.0), testo,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("9fc4bb"))

## Posizione normalizzata di un bersaglio sulla retta.
func number_line_anchor(target_id: String) -> Vector2:
	for voce in Array(model.get("targets", [])):
		var bersaglio := voce as Dictionary
		if str(bersaglio.get("id", "")) != target_id:
			continue
		var minimo := float(model.get("min", 0.0))
		var massimo := float(model.get("max", 10.0))
		var frazione := (float(bersaglio.get("value", 0.0)) - minimo) / maxf(0.0001, massimo - minimo)
		return Vector2(lerpf(0.10, 0.90, clampf(frazione, 0.0, 1.0)), 0.58)
	return Vector2(0.5, 0.58)

func notation_anchor(symbol_id: String) -> Vector2:
	var symbols: Array = model.get("symbols", [])
	var index := 0
	var staff_step := 0
	for candidate_index in symbols.size():
		var symbol := symbols[candidate_index] as Dictionary
		if str(symbol.get("id", "")) == symbol_id:
			index = candidate_index
			staff_step = clampi(int(symbol.get("staffStep", 0)), -4, 12)
			break
	var x := 0.55 if symbols.size() <= 1 else lerpf(0.24, 0.88, float(index) / float(symbols.size() - 1))
	return Vector2(x, 0.68 - float(staff_step) * 0.045)

func _draw_clef(clef: String, center: Vector2, ink: Color) -> void:
	if clef == "bass":
		draw_arc(center + Vector2(-1, -2), 24.0, -PI * 0.55, PI * 0.55, 28, ink, 4.0, true)
		draw_circle(center + Vector2(18, -10), 3.4, ink)
		draw_circle(center + Vector2(18, 10), 3.4, ink)
		return
	# Chiave di violino stilizzata: curva e asse sono primitive, non un'immagine
	# con testo incorporato. Rimane nitida a ogni scala e costa pochi byte.
	draw_line(center + Vector2(2, -45), center + Vector2(-3, 48), ink, 3.2, true)
	draw_arc(center + Vector2(-2, 3), 20.0, -PI * 0.65, PI * 1.20, 36, ink, 3.4, true)
	draw_arc(center + Vector2(-1, -24), 12.0, PI * 0.15, PI * 1.75, 24, ink, 3.0, true)
	draw_circle(center + Vector2(-5, 15), 4.0, ink)

func _draw_ledger_lines(symbol: Dictionary, center: Vector2, ink: Color) -> void:
	if str(symbol.get("kind", "note")) != "note":
		return
	var staff_step := int(symbol.get("staffStep", 0))
	if staff_step < 0:
		for step in range(-2, staff_step - 1, -2):
			var y := (0.68 - float(step) * 0.045) * size.y
			draw_line(Vector2(center.x - 15, y), Vector2(center.x + 15, y), ink, 2.0, true)
	elif staff_step > 8:
		for step in range(10, staff_step + 1, 2):
			var y := (0.68 - float(step) * 0.045) * size.y
			draw_line(Vector2(center.x - 15, y), Vector2(center.x + 15, y), ink, 2.0, true)

func _draw_note(center: Vector2, staff_step: int, duration: String, ink: Color) -> void:
	var hollow := duration in ["whole", "half"]
	draw_set_transform(center, -0.22, Vector2(1.35, 0.78))
	if hollow:
		draw_circle(Vector2.ZERO, 8.0, Color(0.015, 0.07, 0.09, 0.98))
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, ink, 2.5, true)
	else:
		draw_circle(Vector2.ZERO, 8.0, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if duration == "whole":
		return
	var upward := staff_step < 5
	var stem_x := center.x + (9.0 if upward else -9.0)
	var stem_end := center.y - 42.0 if upward else center.y + 42.0
	draw_line(Vector2(stem_x, center.y), Vector2(stem_x, stem_end), ink, 2.6, true)
	if duration == "eighth":
		var direction := 1.0 if upward else -1.0
		draw_arc(Vector2(stem_x + direction * 9.0, stem_end + direction * 8.0), 13.0, PI * 0.75, PI * 1.45, 16, ink, 3.0, true)

func _draw_rest(center: Vector2, duration: String, ink: Color) -> void:
	if duration in ["whole", "half"]:
		var top := center.y - 4.0 if duration == "whole" else center.y
		draw_rect(Rect2(Vector2(center.x - 12, top), Vector2(24, 8)), ink)
		return
	var zig := PackedVector2Array([
		center + Vector2(5, -24), center + Vector2(-5, -7),
		center + Vector2(7, 2), center + Vector2(-5, 25),
	])
	draw_polyline(zig, ink, 4.0, true)
	if duration == "eighth":
		draw_circle(center + Vector2(7, -25), 5.0, ink)

func _draw_accidental(center: Vector2, accidental: String, ink: Color) -> void:
	if accidental == "flat":
		draw_line(center + Vector2(-4, -26), center + Vector2(-4, 24), ink, 3.0, true)
		draw_arc(center + Vector2(2, 7), 10.0, -PI * 0.55, PI * 0.55, 18, ink, 3.0, true)
		return
	if accidental == "sharp":
		for dx in [-5.0, 5.0]:
			draw_line(center + Vector2(dx, -23), center + Vector2(dx - 3, 23), ink, 2.5, true)
		for dy in [-8.0, 8.0]:
			draw_line(center + Vector2(-14, dy + 3), center + Vector2(14, dy - 3), ink, 3.0, true)
		return
	# Bequadro (natural).
	draw_line(center + Vector2(-6, -24), center + Vector2(-6, 18), ink, 2.6, true)
	draw_line(center + Vector2(6, -18), center + Vector2(6, 24), ink, 2.6, true)
	draw_line(center + Vector2(-6, -5), center + Vector2(6, -10), ink, 2.6, true)
	draw_line(center + Vector2(-6, 10), center + Vector2(6, 5), ink, 2.6, true)

func _draw_hotspot(bounds: Rect2) -> void:
	if background_texture != null:
		var image_rect := _hotspot_image_rect(bounds)
		draw_texture_rect(background_texture, image_rect, false)
		draw_rect(image_rect, Color(0.01, 0.05, 0.07, 0.12))
		return
	var horizon := bounds.position.y + bounds.size.y * 0.62
	draw_rect(Rect2(bounds.position, Vector2(bounds.size.x, bounds.size.y * 0.62)), Color(0.06, 0.18, 0.22, 0.82))
	draw_rect(Rect2(Vector2(bounds.position.x, horizon), Vector2(bounds.size.x, bounds.end.y - horizon)), Color(0.10, 0.28, 0.24, 0.86))
	for i in range(5):
		var x := bounds.position.x + 35.0 + float(i) * bounds.size.x / 5.5
		draw_circle(Vector2(x, horizon + 30 + (i % 2) * 14), 22.0, Color(0.18, 0.42, 0.30, 0.78))

func _hotspot_image_rect(bounds: Rect2) -> Rect2:
	if background_texture == null:
		return bounds
	var texture_size := background_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return bounds
	var scale := minf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var fitted := texture_size * scale
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.07, 0.09, 0.96)
	style.border_color = Color(0.42, 0.90, 0.84, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style
