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
var visual_lod := 0

func configure(data: Dictionary, world_ref: Node, lod_level: int = 0) -> void:
	chunk = data
	world = world_ref
	visual_lod = maxi(0, lod_level)
	y_sort_enabled = true
	var decor = RNG.new(str(chunk.get("id", "chunk")) + ":decor")
	_build_ground()
	if visual_lod == 0:
		_build_academy_set_dressing()
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
	ground.setup(chunk, visual_lod)

func _build_academy_set_dressing() -> void:
	# Scenografia fissa del vertical slice: solo Node2D visuali, senza Area2D
	# o corpi fisici, così generator/parità/collisioni restano invariati.
	if str(chunk.get("biome", "")) != "academy":
		return
	if int(chunk.get("chunkX", 99)) != 0 or int(chunk.get("chunkY", 99)) != 0:
		return
	var stage := Node2D.new()
	stage.name = "AcademySetDressing"
	stage.z_index = -2
	stage.y_sort_enabled = true
	add_child(stage)

	# Il fondale hero contiene già casa, fontana e ponte con prospettiva e
	# illuminazione coerenti: non li ridisegniamo in una seconda posizione.
	# Le versioni vettoriali restano disponibili in visual_factory per futuri
	# biomi senza fondale pittorico.

	# Alberi e cespugli ai margini formano quinte naturali e incorniciano il
	# percorso senza aggiungere collisioni invisibili.
	for tree_data in [
		{"pos": Vector2(84, 140), "radius": 48.0, "variant": 0.12},
		{"pos": Vector2(278, 132), "radius": 42.0, "variant": 0.68},
		{"pos": Vector2(818, 136), "radius": 48.0, "variant": 0.36},
		{"pos": Vector2(822, 760), "radius": 46.0, "variant": 0.82},
	]:
		var tree: Node2D = OutdoorVisualFactory.build_obstacle("tree", tree_data["radius"], 0x235b3a, tree_data["variant"], "academy")
		tree.position = tree_data["pos"]
		stage.add_child(tree)
	for rock_data in [
		{"pos": Vector2(74, 625), "radius": 28.0, "variant": 0.24},
		{"pos": Vector2(330, 770), "radius": 24.0, "variant": 0.54},
		{"pos": Vector2(768, 700), "radius": 26.0, "variant": 0.74},
	]:
		var rock: Node2D = OutdoorVisualFactory.build_obstacle("rock", rock_data["radius"], 0x46545c, rock_data["variant"], "academy")
		rock.position = rock_data["pos"]
		stage.add_child(rock)

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
		var treasure_label := str(treasure.get("label", ""))
		# CompatibilitÃ  con il campo procedurale legacy: nessun tesoro comunica
		# piÃ¹ una raccolta di energia, la cassa contiene frammenti.
		if treasure_label.to_lower().contains("energia"):
			treasure_label = "scrigno frammenti"
		var node := OutdoorVisualFactory.build_treasure(treasure_label)
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
