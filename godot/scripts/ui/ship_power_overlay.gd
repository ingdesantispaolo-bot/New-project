class_name ShipPowerOverlay
extends Control

## Rete energetica diegetica sovrapposta alla stanza. L'intensità deriva dal
## modello didattico; `burst` è usato soltanto durante la celebrazione.

var activation := 0.0
var stage := 0
var accent := Color("6be7d6")
var burst := 0.0
var _clock := 0.0

const CIRCUITS := [
	[Vector2(0.00, 0.26), Vector2(0.18, 0.26), Vector2(0.25, 0.36), Vector2(0.44, 0.36), Vector2(0.50, 0.50)],
	[Vector2(0.00, 0.72), Vector2(0.16, 0.72), Vector2(0.25, 0.61), Vector2(0.43, 0.61), Vector2(0.50, 0.50)],
	[Vector2(1.00, 0.23), Vector2(0.83, 0.23), Vector2(0.75, 0.34), Vector2(0.58, 0.34), Vector2(0.50, 0.50)],
	[Vector2(1.00, 0.75), Vector2(0.86, 0.75), Vector2(0.74, 0.63), Vector2(0.58, 0.63), Vector2(0.50, 0.50)],
	[Vector2(0.32, 0.00), Vector2(0.32, 0.17), Vector2(0.41, 0.28), Vector2(0.50, 0.50)],
	[Vector2(0.67, 1.00), Vector2(0.67, 0.82), Vector2(0.59, 0.72), Vector2(0.50, 0.50)],
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_activation(value: float, stage_index: int, color: Color) -> void:
	activation = clampf(value, 0.0, 1.0)
	stage = clampi(stage_index, 0, 4)
	accent = color
	queue_redraw()

func _process(delta: float) -> void:
	_clock += delta
	if activation > 0.0 or burst > 0.0:
		queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var energy := clampf(activation + burst * 0.55, 0.0, 1.35)
	for circuit_index in CIRCUITS.size():
		var path := _scaled_path(CIRCUITS[circuit_index])
		var faint_alpha := 0.025 + energy * 0.055
		draw_polyline(path, Color(accent, faint_alpha), 8.0, true)
		draw_polyline(path, Color(accent, 0.06 + energy * 0.30), 1.35 + energy, true)
		for point_index in range(1, path.size() - 1):
			var point := path[point_index]
			draw_circle(point, 3.0 + energy * 2.0, Color(0.01, 0.03, 0.035, 0.82))
			draw_circle(point, 1.2 + energy * 1.5, Color(accent, 0.15 + energy * 0.55))
		if energy > 0.02:
			var travel := fmod(_clock * (0.075 + energy * 0.13) + float(circuit_index) * 0.173, 1.0)
			var pulse := _point_on_path(path, travel)
			draw_circle(pulse, 11.0 + burst * 15.0, Color(accent, 0.025 + energy * 0.08))
			draw_circle(pulse, 3.0 + energy * 3.0, Color(accent, 0.38 + minf(energy, 1.0) * 0.50))

	var core := size * 0.5
	if burst > 0.001:
		var travel := 1.0 - burst
		for spark_index in 48:
			var angle := float(spark_index) / 48.0 * TAU + sin(float(spark_index) * 4.17) * 0.18
			var distance := (42.0 + float((spark_index * 37) % 190)) * (0.22 + travel)
			var spark := core + Vector2.from_angle(angle) * distance
			var tail := spark - Vector2.from_angle(angle) * (8.0 + 25.0 * burst)
			draw_line(tail, spark, Color(accent, burst * 0.78), 1.0 + float(spark_index % 3), true)
			draw_circle(spark, 1.5 + float(spark_index % 4), Color(accent.lightened(0.28), burst))
	var core_pulse := sin(_clock * (1.4 + float(stage) * 0.35)) * 0.5 + 0.5
	draw_circle(core, 32.0 + core_pulse * 8.0 + burst * 38.0, Color(accent, energy * 0.035))
	draw_arc(core, 18.0 + core_pulse * 3.0, 0.0, TAU, 48, Color(accent, 0.08 + energy * 0.52), 1.4 + energy * 1.8, true)

func _scaled_path(source: Array) -> PackedVector2Array:
	var output := PackedVector2Array()
	for point in source:
		output.append(Vector2(point.x * size.x, point.y * size.y))
	return output

func _point_on_path(path: PackedVector2Array, ratio: float) -> Vector2:
	if path.size() < 2:
		return Vector2.ZERO
	var lengths := PackedFloat32Array()
	var total := 0.0
	for index in range(path.size() - 1):
		var length := path[index].distance_to(path[index + 1])
		lengths.append(length)
		total += length
	var target := ratio * total
	for index in lengths.size():
		if target <= lengths[index]:
			return path[index].lerp(path[index + 1], target / maxf(lengths[index], 0.001))
		target -= lengths[index]
	return path[path.size() - 1]
