extends Node2D

## Sfondo piatto del chunk: terreno, tinta del bioma e sentieri.
## Sta su z_index basso e fuori dall'y-sort, così resta sempre dietro agli
## oggetti (ostacoli, player, interagibili) del livello superiore.

const GROUND_TEXTURE: Texture2D = preload("res://assets/academy-ground.svg")

var chunk: Dictionary

func setup(data: Dictionary) -> void:
	chunk = data
	queue_redraw()

func _draw() -> void:
	var size := float(chunk.get("size", 896))
	draw_texture_rect(GROUND_TEXTURE, Rect2(Vector2.ZERO, Vector2(size, size)), true)

	var patch: Dictionary = chunk.get("patch", {})
	var tint := _hex_color(int(patch.get("color", 0x173b36)))
	tint.a = 0.30
	draw_rect(Rect2(Vector2.ZERO, Vector2(size, size)), tint)

	var world_x := float(chunk.get("worldX", 0))
	var world_y := float(chunk.get("worldY", 0))
	var points: Array = chunk.get("pathPoints", [])
	if points.size() >= 2:
		var line := PackedVector2Array()
		for point in points:
			line.append(Vector2(float(point["x"]) - world_x, float(point["y"]) - world_y))
		draw_polyline(line, Color(0.86, 0.82, 0.6, 0.32), 12.0)

func _hex_color(rgb: int) -> Color:
	return Color(
		float((rgb >> 16) & 0xFF) / 255.0,
		float((rgb >> 8) & 0xFF) / 255.0,
		float(rgb & 0xFF) / 255.0,
	)
