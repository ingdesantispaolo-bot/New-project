extends Control

## Superficie visuale data-driven per hotspot, grafici e circuiti. Non conosce
## risposte, mastery o ricompense: disegna soltanto il modello fornito.

var diagram_kind := ""
var model: Dictionary = {}
var background_texture: Texture2D

func configure(kind: String, data: Dictionary) -> void:
	diagram_kind = kind
	model = data.duplicate(true)
	var background_path := str(model.get("image", ""))
	background_texture = load(background_path) as Texture2D if background_path != "" and ResourceLoader.exists(background_path) else null
	custom_minimum_size = Vector2(0, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func point_position(point: Dictionary) -> Vector2:
	var normalized := Vector2(
		clampf(float(point.get("x", 0.5)), 0.05, 0.95),
		clampf(float(point.get("y", 0.5)), 0.05, 0.95)
	)
	return Vector2(normalized.x * size.x, normalized.y * size.y)

func _draw() -> void:
	var bounds := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_style_box(_panel_style(), bounds)
	match diagram_kind:
		"graph":
			_draw_graph(bounds)
		"circuit":
			_draw_circuit(bounds)
		_:
			_draw_hotspot(bounds)

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

func _draw_hotspot(bounds: Rect2) -> void:
	if background_texture != null:
		draw_texture_rect(background_texture, bounds, false)
		draw_rect(bounds, Color(0.01, 0.05, 0.07, 0.18))
		return
	var horizon := bounds.position.y + bounds.size.y * 0.62
	draw_rect(Rect2(bounds.position, Vector2(bounds.size.x, bounds.size.y * 0.62)), Color(0.06, 0.18, 0.22, 0.82))
	draw_rect(Rect2(Vector2(bounds.position.x, horizon), Vector2(bounds.size.x, bounds.end.y - horizon)), Color(0.10, 0.28, 0.24, 0.86))
	for i in range(5):
		var x := bounds.position.x + 35.0 + float(i) * bounds.size.x / 5.5
		draw_circle(Vector2(x, horizon + 30 + (i % 2) * 14), 22.0, Color(0.18, 0.42, 0.30, 0.78))

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.07, 0.09, 0.96)
	style.border_color = Color(0.42, 0.90, 0.84, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style
