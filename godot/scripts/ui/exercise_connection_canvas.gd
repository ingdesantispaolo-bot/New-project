extends Control

## Layer puramente visuale del matching. Le coppie restano pulsanti accessibili;
## questo canvas disegna la relazione senza diventare una seconda logica.

var connections: Array = []
var pulse_started_msec := 0
var pulse_connection_index := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_connections(value: Array) -> void:
	if value.size() > connections.size():
		pulse_connection_index = value.size() - 1
		pulse_started_msec = Time.get_ticks_msec()
	connections = value
	queue_redraw()

func _process(_delta: float) -> void:
	if not connections.is_empty():
		queue_redraw()

func _draw() -> void:
	for index in range(connections.size()):
		var connection = connections[index]
		var left := (connection as Dictionary).get("left") as Control
		var right := (connection as Dictionary).get("right") as Control
		if not is_instance_valid(left) or not is_instance_valid(right):
			continue
		var from := left.global_position + Vector2(left.size.x, left.size.y * 0.5) - global_position
		var to := right.global_position + Vector2(0.0, right.size.y * 0.5) - global_position
		var color: Color = (connection as Dictionary).get("color", Color("8ff6d2"))
		var pulse := 0.0
		if index == pulse_connection_index:
			var elapsed := float(Time.get_ticks_msec() - pulse_started_msec) / 1000.0
			pulse = maxf(0.0, 1.0 - elapsed / 0.48) * (0.65 + 0.35 * sin(elapsed * 26.0))
		draw_line(from, to, Color(0.01, 0.05, 0.07, 0.9), 7.0 + pulse * 5.0, true)
		draw_line(from, to, color.lightened(pulse * 0.35), 3.0 + pulse * 3.0, true)
		draw_circle(from, 5.0 + pulse * 5.0, color)
		draw_circle(to, 5.0 + pulse * 5.0, color)
