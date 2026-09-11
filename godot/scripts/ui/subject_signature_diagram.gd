extends Control

## Plancia vettoriale condivisa dalle cinque firme di materia. Non decide mai
## se una risposta e' corretta: riceve modello e stato dall'ExercisePlayer e
## rende visibile cio' che il simulatore in ExerciseInteraction ha prodotto.

const MAP_GEOMETRY_CATALOG := preload("res://scripts/visual/map_geometry_catalog.gd")
const ExerciseInteraction := preload("res://scripts/game/exercise_interaction.gd")

var diagram_kind := ""
var model: Dictionary = {}
var state: Dictionary = {}
var high_contrast := false

func _ready() -> void:
	custom_minimum_size = Vector2(620, 270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_diagram(kind: String, value: Dictionary, contrast: bool = false) -> void:
	diagram_kind = kind
	model = value.duplicate(true)
	high_contrast = contrast
	queue_redraw()

func set_state(value: Dictionary) -> void:
	state = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_style_box(_panel_style(), bounds)
	match diagram_kind:
		"breadboard": _draw_breadboard(bounds)
		"rhythm_fill": _draw_rhythm(bounds)
		"causal_chain": _draw_causal_chain(bounds)
		"robot_grid": _draw_robot_grid(bounds)
		"blank_map": _draw_blank_map(bounds)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07181d") if not high_contrast else Color("000000")
	style.border_color = Color("4c8f91") if not high_contrast else Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func _font() -> Font:
	return ThemeDB.fallback_font

func _center_text(text: String, center: Vector2, width: float, color: Color, font_size: int = 14) -> void:
	draw_string(_font(), Vector2(center.x - width * 0.5, center.y + float(font_size) * 0.35), text,
		HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _draw_breadboard(bounds: Rect2) -> void:
	var sockets: Array = model.get("zoccoli", [])
	var node_ids: Array = []
	for raw in sockets:
		var socket := raw as Dictionary
		for key in [str(socket.get("da", "")), str(socket.get("a", ""))]:
			if not node_ids.has(key): node_ids.append(key)
	var positions: Dictionary = {}
	var center := bounds.get_center()
	var radius := Vector2(bounds.size.x * 0.34, bounds.size.y * 0.31)
	for index in node_ids.size():
		var angle := TAU * float(index) / float(maxi(1, node_ids.size())) - PI * 0.5
		positions[str(node_ids[index])] = center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
	var placements := state.get("placements", {}) as Dictionary
	var components: Dictionary = {}
	for raw in Array(model.get("componenti", [])):
		var component := raw as Dictionary
		components[str(component.get("id", ""))] = component
	for raw in sockets:
		var socket := raw as Dictionary
		var from_pos: Vector2 = positions.get(str(socket.get("da", "")), center)
		var to_pos: Vector2 = positions.get(str(socket.get("a", "")), center)
		var component_id := str(placements.get(str(socket.get("id", "")), ""))
		var occupied := component_id != ""
		draw_dashed_line(from_pos, to_pos, Color("75e6d5") if occupied else Color("46666c"), 5.0 if occupied else 3.0, 10.0)
		var middle := from_pos.lerp(to_pos, 0.5)
		if occupied:
			var component := components.get(component_id, {}) as Dictionary
			draw_circle(middle, 20.0, Color("183c42"))
			_center_text(str(component.get("simbolo", component.get("label", component_id))), middle, 76.0, Color("fff0ac"), 13)
		else:
			draw_circle(middle, 8.0, Color("ff9a78"), false, 3.0)
	for node_id in node_ids:
		var pos: Vector2 = positions[str(node_id)]
		draw_circle(pos, 18.0, Color("102e34"))
		draw_circle(pos, 18.0, Color("a6fff0"), false, 3.0)
		_center_text(str(node_id).to_upper(), pos, 62.0, Color.WHITE, 12)
	var powered := bool(state.get("powered", false))
	draw_circle(bounds.position + Vector2(bounds.size.x - 42, 38), 15.0, Color("ffe56a") if powered else Color("452d35"))

func _draw_rhythm(bounds: Rect2) -> void:
	var left := bounds.position.x + 42.0
	var right := bounds.end.x - 30.0
	var top := bounds.position.y + 72.0
	for line in range(5):
		draw_line(Vector2(left, top + line * 16.0), Vector2(right, top + line * 16.0), Color("8fb3b7"), 2.0)
	draw_line(Vector2(left, top - 8), Vector2(left, top + 72), Color("f6c85f"), 4.0)
	draw_line(Vector2(right, top - 8), Vector2(right, top + 72), Color("f6c85f"), 4.0)
	var values: Array = []
	for raw in Array(model.get("battuta", [])):
		var beat := raw as Dictionary
		values.append({"label": str(beat.get("simbolo", beat.get("label", "nota"))), "value": float(beat.get("valore", 0.0)), "fixed": true})
	var by_id: Dictionary = {}
	for raw in Array(model.get("disponibili", [])):
		var token := raw as Dictionary
		by_id[str(token.get("id", ""))] = token
	for raw_id in Array(state.get("selected", [])):
		var token := by_id.get(str(raw_id), {}) as Dictionary
		values.append({"label": str(token.get("simbolo", token.get("label", raw_id))), "value": float(token.get("valore", 0.0)), "fixed": false})
	var meter := float(model.get("metro", 1.0))
	var cursor := left + 18.0
	for value_data in values:
		var value := value_data as Dictionary
		var width := maxf(34.0, (right - left - 40.0) * float(value.get("value", 0.0)) / meter)
		var center := Vector2(cursor + width * 0.5, top + 32.0)
		draw_circle(center, 11.0, Color("b8c8ff") if bool(value.get("fixed", false)) else Color("f6c85f"))
		draw_line(center + Vector2(10, 0), center + Vector2(10, -42), Color("e7fff8"), 3.0)
		_center_text(str(value.get("label", "")), center + Vector2(0, 54), width, Color("d8fff8"), 12)
		cursor += width
	_center_text("METRO %s  ·  TOTALE %s" % [str(model.get("metroLabel", meter)), str(state.get("totalLabel", "0"))],
		bounds.position + Vector2(bounds.size.x * 0.5, 30), bounds.size.x - 40, Color("f6c85f"), 15)

func _draw_causal_chain(bounds: Rect2) -> void:
	var events: Array = model.get("eventi", [])
	var sorted := events.duplicate()
	sorted.sort_custom(func(a, b): return int((a as Dictionary).get("anno", 0)) < int((b as Dictionary).get("anno", 0)))
	var positions: Dictionary = {}
	for index in sorted.size():
		var event := sorted[index] as Dictionary
		var x := bounds.position.x + 72.0 + float(index) * (bounds.size.x - 144.0) / float(maxi(1, sorted.size() - 1))
		var y := bounds.position.y + bounds.size.y * (0.38 if index % 2 == 0 else 0.68)
		positions[str(event.get("id", ""))] = Vector2(x, y)
	for raw in Array(state.get("links", [])):
		var edge := raw as Dictionary
		_draw_arrow(positions.get(str(edge.get("da", "")), bounds.get_center()), positions.get(str(edge.get("a", "")), bounds.get_center()), Color("78efbc"))
	for event_data in sorted:
		var event := event_data as Dictionary
		var pos: Vector2 = positions[str(event.get("id", ""))]
		draw_circle(pos, 30.0, Color("18333a"))
		draw_circle(pos, 30.0, Color("f2c96d"), false, 3.0)
		_center_text(str(event.get("anno", "")), pos - Vector2(0, 5), 74, Color.WHITE, 13)
		_center_text(str(event.get("testo", "")), pos + Vector2(0, 48), 142, Color("d8fff8"), 11)

func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	var direction := from.direction_to(to)
	var start := from + direction * 34.0
	var finish := to - direction * 34.0
	draw_line(start, finish, color, 4.0)
	var normal := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([finish, finish - direction * 15.0 + normal * 7.0, finish - direction * 15.0 - normal * 7.0]), color)

func _draw_robot_grid(bounds: Rect2) -> void:
	var grid := model.get("griglia", {}) as Dictionary
	var width := int(grid.get("larghezza", 1))
	var height := int(grid.get("altezza", 1))
	var cell := minf((bounds.size.x - 90.0) / float(width), (bounds.size.y - 38.0) / float(height))
	var origin := bounds.get_center() - Vector2(cell * width, cell * height) * 0.5
	var blocked: Dictionary = {}
	for raw in Array(grid.get("ostacoli", [])): blocked[str(ExerciseInteraction._grid_point(raw))] = true
	for y in height:
		for x in width:
			var rect := Rect2(origin + Vector2(x, y) * cell, Vector2.ONE * cell)
			draw_rect(rect.grow(-2), Color("26393e") if blocked.has(str(Vector2i(x, y))) else Color("10252a"))
			draw_rect(rect.grow(-2), Color("456b70"), false, 1.0)
	var goal := ExerciseInteraction._grid_point(model.get("obiettivo", {}))
	var goal_center := origin + (Vector2(goal) + Vector2(0.5, 0.5)) * cell
	draw_circle(goal_center, cell * 0.26, Color("ffe56a"), false, 5.0)
	var trail: Array = state.get("trail", [])
	for index in range(1, trail.size()):
		var a := origin + (Vector2(trail[index - 1]) + Vector2(0.5, 0.5)) * cell
		var b := origin + (Vector2(trail[index]) + Vector2(0.5, 0.5)) * cell
		draw_line(a, b, Color("7cebd8"), 5.0)
	var robot := ExerciseInteraction._grid_point(model.get("partenza", {}))
	if not trail.is_empty(): robot = trail.back()
	var robot_center := origin + (Vector2(robot) + Vector2(0.5, 0.5)) * cell
	draw_circle(robot_center, cell * 0.27, Color("8fa7ff"))
	_center_text("R", robot_center, cell, Color("08141a"), int(cell * 0.32))
	var direction := int(state.get("direction", (model.get("partenza", {}) as Dictionary).get("direzione", 1)))
	var vectors := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	var tip: Vector2 = robot_center + (vectors[direction] as Vector2) * cell * 0.42
	draw_line(robot_center, tip, Color.WHITE, 4.0)

func _draw_blank_map(bounds: Rect2) -> void:
	var data := MAP_GEOMETRY_CATALOG.map_data(str(model.get("mapId", "")))
	if data.is_empty(): return
	var map_bounds := data.get("bounds", Rect2()) as Rect2
	var drawing := bounds.grow(-24)
	var scale_value := minf(drawing.size.x / map_bounds.size.x, drawing.size.y / map_bounds.size.y)
	var used := map_bounds.size * scale_value
	var offset := drawing.get_center() - used * 0.5
	for polygon_data in Array(data.get("polygons", [])):
		var polygon := PackedVector2Array()
		for geo in PackedVector2Array(polygon_data): polygon.append(_project_map(geo, map_bounds, offset, scale_value, used.y))
		draw_colored_polygon(polygon, Color("17383b"))
		draw_polyline(polygon, Color("7fd19b"), 2.5)
	var placements := state.get("placements", {}) as Dictionary
	var targets := data.get("targets", {}) as Dictionary
	for index in Array(model.get("ancore", [])).size():
		var raw_anchor = Array(model.get("ancore", []))[index]
		var anchor_id := str(raw_anchor.get("id", "") if raw_anchor is Dictionary else raw_anchor)
		if not targets.has(anchor_id): continue
		var anchor_pos := _project_map(targets[anchor_id], map_bounds, offset, scale_value, used.y)
		draw_circle(anchor_pos, 13.0, Color("08181d"))
		draw_circle(anchor_pos, 13.0, Color("f6c85f"), false, 3.0)
		_center_text(str(index + 1), anchor_pos, 26, Color.WHITE, 12)
	for raw in Array(model.get("etichette", [])):
		var label := raw as Dictionary
		var label_id := str(label.get("id", ""))
		if not placements.has(label_id): continue
		var anchor_id := str(placements[label_id])
		if not targets.has(anchor_id): continue
		var pos := _project_map(targets[anchor_id], map_bounds, offset, scale_value, used.y)
		draw_circle(pos, 9.0, Color("f6c85f"))
		_center_text(str(label.get("testo", label_id)), pos + Vector2(0, -18), 130, Color.WHITE, 12)
	var route: Array = state.get("route", [])
	for index in range(1, route.size()):
		if targets.has(str(route[index - 1])) and targets.has(str(route[index])):
			_draw_arrow(_project_map(targets[str(route[index - 1])], map_bounds, offset, scale_value, used.y),
				_project_map(targets[str(route[index])], map_bounds, offset, scale_value, used.y), Color("f6c85f"))

func _project_map(point: Vector2, map_bounds: Rect2, offset: Vector2, scale_value: float, used_height: float) -> Vector2:
	return offset + Vector2((point.x - map_bounds.position.x) * scale_value,
		used_height - (point.y - map_bounds.position.y) * scale_value)
