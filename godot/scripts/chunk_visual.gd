class_name OutdoorChunkVisual
extends Node2D

## Rappresentazione grafica di un chunk. Due strati:
## - sfondo piatto (chunk_ground) su z_index basso, fuori dall'y-sort;
## - oggetti (ostacoli, prop, landmark, interagibili) y-sortati con il player,
##   costruiti da OutdoorVisualFactory (ombre, glow, micro-animazioni).
## Gli interagibili sono Area2D con segnali: niente scansione per-frame lato mondo.
##
## Le varianti estetiche usano un RNG decorativo separato ("<id>:decor"):
## nessuna estrazione dall'RNG di generazione, la parità resta intatta.

const INTERACTION_RADIUS := 88.0
const GROUND_SCRIPT := preload("res://scripts/chunk_ground.gd")
const RNG := preload("res://scripts/deterministic_rng.gd")

var chunk: Dictionary
var world: Node

func configure(data: Dictionary, world_ref: Node) -> void:
	chunk = data
	world = world_ref
	y_sort_enabled = true
	var decor = RNG.new(str(chunk.get("id", "chunk")) + ":decor")
	_build_ground()
	_build_obstacles(decor)
	_build_props(decor)
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

func _build_obstacles(decor) -> void:
	for obstacle in chunk.get("obstacles", []):
		var radius := float(obstacle["r"])
		var node := OutdoorVisualFactory.build_obstacle(
			str(obstacle["kind"]), radius, int(obstacle["color"]), decor.next_float(), str(chunk.get("biome", "")))
		node.position = _local(obstacle["x"], obstacle["y"])
		add_child(node)

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius + 8.0
		shape.shape = circle
		body.add_child(shape)
		node.add_child(body)

func _build_props(decor) -> void:
	for prop in chunk.get("props", []):
		var node := OutdoorVisualFactory.build_prop(
			str(prop["kind"]), int(prop["color"]), decor.next_float(), str(chunk.get("biome", "")))
		node.position = _local(prop["x"], prop["y"])
		add_child(node)

func _build_landmarks() -> void:
	for landmark in chunk.get("landmarks", []):
		var node := OutdoorVisualFactory.build_landmark(
			str(landmark["kind"]), str(landmark["label"]), int(landmark["color"]))
		node.position = _local(landmark["x"], landmark["y"])
		add_child(node)

func _build_treasures() -> void:
	for treasure in chunk.get("treasures", []):
		var node := OutdoorVisualFactory.build_treasure(str(treasure.get("label", "")))
		node.position = _local(treasure["x"], treasure["y"])
		add_child(node)
		_attach_interactable(node, "treasure", str(treasure["id"]), treasure)

func _build_encounters() -> void:
	for encounter in chunk.get("encounters", []):
		var node := OutdoorVisualFactory.build_encounter(
			str(encounter.get("kind", "times")), int(encounter.get("difficulty", 1)))
		node.position = _local(encounter["x"], encounter["y"])
		add_child(node)
		_attach_interactable(node, "encounter", str(encounter["id"]), encounter)

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
