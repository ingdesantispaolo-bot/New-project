class_name OutdoorChunkVisual
extends Node2D

## Rappresentazione grafica di un chunk. Due strati:
## - sfondo piatto (chunk_ground) su z_index basso, fuori dall'y-sort;
## - oggetti (ostacoli, prop, landmark, interagibili) y-sortati con il player.
## Gli interagibili sono Area2D con segnali: niente scansione per-frame lato mondo.

const INTERACTION_RADIUS := 88.0
const GROUND_SCRIPT := preload("res://scripts/chunk_ground.gd")
const TREASURE_TEXTURE: Texture2D = preload("res://assets/academy-treasure.svg")
const ENCOUNTER_TEXTURE: Texture2D = preload("res://assets/academy-encounter.svg")

var chunk: Dictionary
var world: Node

func configure(data: Dictionary, world_ref: Node) -> void:
	chunk = data
	world = world_ref
	y_sort_enabled = true
	_build_ground()
	_build_obstacles()
	_build_props()
	_build_landmarks()
	_build_treasures()
	_build_encounters()

func _local(px, py) -> Vector2:
	return Vector2(float(px) - float(chunk["worldX"]), float(py) - float(chunk["worldY"]))

func _build_ground() -> void:
	var ground := Node2D.new()
	ground.set_script(GROUND_SCRIPT)
	ground.z_index = -10
	ground.y_sort_enabled = false
	add_child(ground)
	ground.setup(chunk)

func _build_obstacles() -> void:
	for obstacle in chunk.get("obstacles", []):
		var radius := float(obstacle["r"])
		var node := Node2D.new()
		node.position = _local(obstacle["x"], obstacle["y"])
		add_child(node)

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius + 8.0
		shape.shape = circle
		body.add_child(shape)
		node.add_child(body)

		var kind := str(obstacle["kind"])
		var color := _hex_color(int(obstacle["color"]))
		if kind == "tree" or kind == "bush" or kind == "mushroom":
			# tronco/gambo + chioma
			var trunk := Polygon2D.new()
			trunk.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(4, radius), Vector2(-4, radius)])
			trunk.color = Color(0.35, 0.24, 0.16)
			node.add_child(trunk)
			var canopy := Polygon2D.new()
			canopy.polygon = _circle_polygon(radius)
			canopy.position = Vector2(0, -radius * 0.2)
			canopy.color = color
			node.add_child(canopy)
		else:
			# roccia/cristallo/pilastro/rovina: blocco sfaccettato
			var block := Polygon2D.new()
			block.polygon = _facet_polygon(radius)
			block.color = color
			node.add_child(block)

func _build_props() -> void:
	for prop in chunk.get("props", []):
		var diamond := Polygon2D.new()
		diamond.position = _local(prop["x"], prop["y"])
		diamond.polygon = PackedVector2Array([Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)])
		diamond.color = _hex_color(int(prop["color"]))
		add_child(diamond)

func _build_landmarks() -> void:
	for landmark in chunk.get("landmarks", []):
		var node := Node2D.new()
		node.position = _local(landmark["x"], landmark["y"])
		add_child(node)
		var marker := Polygon2D.new()
		marker.polygon = _circle_polygon(26.0, 6)
		marker.color = _hex_color(int(landmark["color"]))
		node.add_child(marker)
		var label := Label.new()
		label.text = str(landmark["label"])
		label.position = Vector2(-60, -52)
		label.size = Vector2(120, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("f2f7ff"))
		label.add_theme_font_size_override("font_size", 14)
		node.add_child(label)

func _build_treasures() -> void:
	for treasure in chunk.get("treasures", []):
		var node := _make_sprite_node(treasure, TREASURE_TEXTURE, Vector2(56, 48))
		_attach_interactable(node, "treasure", str(treasure["id"]), treasure)

func _build_encounters() -> void:
	for encounter in chunk.get("encounters", []):
		var node := _make_sprite_node(encounter, ENCOUNTER_TEXTURE, Vector2(56, 56))
		_attach_interactable(node, "encounter", str(encounter["id"]), encounter)

func _make_sprite_node(item: Dictionary, texture: Texture2D, target_size: Vector2) -> Node2D:
	var node := Node2D.new()
	node.position = _local(item["x"], item["y"])
	add_child(node)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	var tex_size := texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		sprite.scale = Vector2(target_size.x / tex_size.x, target_size.y / tex_size.y)
	node.add_child(sprite)
	return node

func _attach_interactable(node: Node2D, kind: String, id: String, payload: Dictionary) -> void:
	var area := Area2D.new()
	area.monitoring = true
	area.set_meta("kind", kind)
	area.set_meta("id", id)
	area.set_meta("payload", payload)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_RADIUS
	shape.shape = circle
	area.add_child(shape)
	node.add_child(area)
	if world != null:
		area.body_entered.connect(func(body): world.on_interactable_entered(area, body))
		area.body_exited.connect(func(body): world.on_interactable_exited(area, body))

func _circle_polygon(radius: float, segments: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _facet_polygon(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-radius, radius * 0.4),
		Vector2(-radius * 0.5, -radius),
		Vector2(radius * 0.6, -radius * 0.8),
		Vector2(radius, radius * 0.3),
		Vector2(radius * 0.3, radius),
		Vector2(-radius * 0.4, radius),
	])

func _hex_color(rgb: int) -> Color:
	return Color(
		float((rgb >> 16) & 0xFF) / 255.0,
		float((rgb >> 8) & 0xFF) / 255.0,
		float(rgb & 0xFF) / 255.0,
	)
