extends Control

## Layer puramente visuale del matching. Le coppie restano pulsanti accessibili;
## questo canvas disegna la relazione senza diventare una seconda logica.

var connections: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_connections(value: Array) -> void:
	connections = value
	queue_redraw()

func _process(_delta: float) -> void:
	if not connections.is_empty():
		queue_redraw()

func _draw() -> void:
	for connection in connections:
		var left := (connection as Dictionary).get("left") as Control
		var right := (connection as Dictionary).get("right") as Control
		if not is_instance_valid(left) or not is_instance_valid(right):
			continue
		var from := left.global_position + left.size * 0.5 - global_position
		var to := right.global_position + right.size * 0.5 - global_position
		var color: Color = (connection as Dictionary).get("color", Color("8ff6d2"))
		draw_line(from, to, Color(0.01, 0.05, 0.07, 0.9), 7.0, true)
		draw_line(from, to, color, 3.0, true)
		draw_circle(from, 5.0, color)
		draw_circle(to, 5.0, color)
