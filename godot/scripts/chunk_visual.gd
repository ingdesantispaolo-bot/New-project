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
var composition: WorldCompositionData

func configure(data: Dictionary, world_ref: Node, lod_level: int = 0, composition_data: WorldCompositionData = null) -> void:
	chunk = data
	world = world_ref
	visual_lod = maxi(0, lod_level)
	composition = composition_data
	y_sort_enabled = true
	var decor = RNG.new(str(chunk.get("id", "chunk")) + ":decor")
	_build_ground()
	_build_global_details()
	_build_global_assemblies()
	_build_identity_props()
	if visual_lod == 0 and (composition == null or composition.protected_zones.is_empty()):
		_build_academy_set_dressing()
	_build_obstacles(decor)
	_build_props(decor)
	_build_landmarks()
	_build_treasures()
	_build_encounters()

func _build_identity_props() -> void:
	if composition == null or composition.identity_props.is_empty():
		return
	var world_origin := Vector2(float(chunk["worldX"]), float(chunk["worldY"]))
	var rect := Rect2(world_origin, Vector2(float(chunk["size"]), float(chunk["size"])))
	for prop in composition.identity_props:
		var world_pos: Vector2 = prop.get("position", Vector2.ZERO)
		if not rect.has_point(world_pos) or composition.is_protected(world_pos, 64.0):
			continue
		var kind := str(prop.get("kind", ""))
		var node := OutdoorVisualFactory.build_identity_prop(
			kind, composition.visual_theme, float(prop.get("variant", 0.5)))
		node.name = "IdentityProp_%s" % kind
		node.position = world_pos - world_origin
		add_child(node)
		if kind in [
			"archive_shelf", "archive_pillar", "archive_scriptorium",
			"sequence_pylon", "loop_engine", "gear_cluster",
			"radio_mast", "signal_console",
			"motion_piston", "rail_switch", "force_cart",
			"resonance_crystal", "tuning_pod",
			"aqueduct_pillar", "glyph_stele", "mosaic_brazier",
			"coil_tower", "circuit_node", "conductor_bridge",
		]:
			var body := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var rectangle := RectangleShape2D.new()
			var collision_sizes := {
				"archive_shelf": Vector2(118, 30),
				"archive_pillar": Vector2(52, 38),
				"archive_scriptorium": Vector2(96, 40),
				"sequence_pylon": Vector2(42, 32),
				"loop_engine": Vector2(136, 52),
				"gear_cluster": Vector2(116, 46),
				"radio_mast": Vector2(56, 34),
				"signal_console": Vector2(92, 42),
				"motion_piston": Vector2(52, 38),
				"rail_switch": Vector2(76, 34),
				"force_cart": Vector2(98, 42),
				"resonance_crystal": Vector2(72, 38),
				"tuning_pod": Vector2(84, 40),
				"aqueduct_pillar": Vector2(56, 42),
				"glyph_stele": Vector2(58, 40),
				"mosaic_brazier": Vector2(70, 38),
				"coil_tower": Vector2(54, 38),
				"circuit_node": Vector2(66, 38),
				"conductor_bridge": Vector2(108, 40),
			}
			rectangle.size = collision_sizes.get(kind, Vector2(52, 38))
			shape.shape = rectangle
			shape.position = Vector2(0, -3)
			body.add_child(shape)
			node.add_child(body)

func _build_global_assemblies() -> void:
	if composition == null:
		return
	var rect := Rect2(Vector2(float(chunk["worldX"]), float(chunk["worldY"])), Vector2(float(chunk["size"]), float(chunk["size"])))
	var points := BiomeAssemblySpawner.points_for_rect(composition, rect, visual_lod)
	var layer := Node2D.new()
	layer.name = "BiomeAssemblies"
	layer.z_index = -1
	layer.y_sort_enabled = true
	add_child(layer)
	for point in points:
		if composition.is_protected(point["position"], 78.0):
			continue
		var biome := str(point["biome"])
		var root := Node2D.new()
		root.position = point["position"] - Vector2(float(chunk["worldX"]), float(chunk["worldY"]))
		root.scale = Vector2.ONE * float(point["scale"])
		var variant := float(point["variant"])
		var spread := float(point.get("spread", 58.0))
		var archetype := int(point.get("archetype", 0))
		var phase := float(point.get("phase", 0.0))
		var main_kind := _assembly_main_kind(biome, archetype)
		var main_radius := 54.0 if main_kind == "tree" else 42.0
		root.add_child(OutdoorVisualFactory.build_obstacle(main_kind, main_radius, 0x426f4a, variant, biome))
		var offsets := _assembly_offsets(archetype, spread)
		for index in range(offsets.size()):
			var offset: Vector2 = Vector2(offsets[index]).rotated(phase)
			var child_kind := _assembly_child_kind(biome, archetype, index)
			var child_radius := 19.0 + float(index % 3) * 3.0
			var child := OutdoorVisualFactory.build_obstacle(child_kind, child_radius, 0x526b55, fmod(variant + offset.x * 0.013 + float(index) * 0.17, 1.0), biome)
			child.position = offset
			child.scale = Vector2.ONE * (0.78 + float(index % 2) * 0.12)
			root.add_child(child)
		var accent_kind := _assembly_accent_kind(biome, archetype)
		if not accent_kind.is_empty():
			var accent := OutdoorVisualFactory.natural_detail_sprite(accent_kind, Vector2(76, 62), 0.0)
			if accent != null:
				accent.position = Vector2(spread * 0.36, 38.0).rotated(phase)
				root.add_child(accent)
		layer.add_child(root)

func _build_global_details() -> void:
	if composition == null:
		return
	var world_origin := Vector2(float(chunk["worldX"]), float(chunk["worldY"]))
	var rect := Rect2(world_origin, Vector2(float(chunk["size"]), float(chunk["size"])))
	var layer := Node2D.new()
	layer.name = "HabitatDetails"
	layer.z_index = -2
	layer.y_sort_enabled = true
	add_child(layer)
	for point in BiomeDetailSpawner.points_for_rect(composition, rect, visual_lod):
		if composition.is_protected(point["position"], 46.0):
			continue
		var kind := str(point["kind"])
		var size := _detail_size(kind) * float(point.get("scale", 1.0))
		var sprite := OutdoorVisualFactory.natural_detail_sprite(kind, size, 0.0)
		if sprite == null:
			continue
		sprite.position = point["position"] - world_origin
		sprite.scale.x *= float(point.get("flip", 1.0))
		if bool(point.get("water", false)):
			sprite.modulate = Color(0.92, 1.0, 0.96, 0.94)
		layer.add_child(sprite)

func _detail_size(kind: String) -> Vector2:
	match kind:
		"reeds": return Vector2(54, 60)
		"cattails": return Vector2(58, 72)
		"lilies", "water_flowers": return Vector2(66, 48)
		"pebble_bank", "stepping_stones": return Vector2(72, 48)
		"driftwood", "stump": return Vector2(78, 60)
		"mushrooms", "crystal_moss", "glow_flowers": return Vector2(66, 64)
		_: return Vector2(58, 52)

func _assembly_offsets(archetype: int, spread: float) -> Array:
	match archetype:
		1:
			return [Vector2(-spread * 1.05, 4), Vector2(-spread * 0.42, 28), Vector2(spread * 0.30, 35), Vector2(spread * 0.92, 16)]
		2:
			return [Vector2(-spread * 0.82, 30), Vector2(-spread * 0.18, 45), Vector2(spread * 0.56, 38), Vector2(spread * 0.92, 5)]
		3:
			return [Vector2(-spread * 0.92, 12), Vector2(spread * 0.76, 25), Vector2(spread * 0.12, 50)]
		_:
			return [Vector2(-spread, 12), Vector2(spread * 0.78, 17), Vector2(-spread * 0.42, 31), Vector2(spread * 0.32, 35), Vector2(spread * 0.08, 48)]

func _assembly_main_kind(biome: String, archetype: int) -> String:
	if biome in ["academy", "wild"]:
		return "bush" if archetype == 1 else "mushroom" if biome == "wild" and archetype == 2 else "tree"
	if biome in ["geo", "ruins"]:
		return "crystal" if archetype == 3 else "rock"
	return "crystal"

func _assembly_child_kind(biome: String, archetype: int, index: int) -> String:
	if biome in ["academy", "wild"]:
		if biome == "wild" and (archetype == 2 or index == 3):
			return "mushroom"
		return "flower" if archetype == 1 and index % 2 == 0 else "bush"
	if biome in ["geo", "ruins"]:
		return "crystal" if archetype == 3 and index == 0 else "rock"
	return "crystal" if index % 2 == 0 else "rock"

func _assembly_accent_kind(biome: String, archetype: int) -> String:
	if biome == "academy":
		return ["grass", "wildflowers", "stump", "leaves"][archetype]
	if biome == "wild":
		return ["fern", "mushrooms", "driftwood", "leaves"][archetype]
	if biome in ["geo", "ruins"]:
		return ["pebble_bank", "stepping_stones", "rune_pebbles", "crystal_moss"][archetype]
	return ["rune_pebbles", "glow_flowers", "crystal_moss", "stepping_stones"][archetype]

func _local(px, py) -> Vector2:
	return Vector2(float(px) - float(chunk["worldX"]), float(py) - float(chunk["worldY"]))

func _build_ground() -> void:
	var ground := Node2D.new()
	ground.set_script(GROUND_SCRIPT)
	ground.z_index = -10
	ground.y_sort_enabled = false
	add_child(ground)
	ground.setup(chunk, visual_lod, composition)

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
		var world_pos := Vector2(float(obstacle["x"]), float(obstacle["y"]))
		var render_biome := _render_biome(world_pos, decor.next_float())
		var in_water := composition != null and composition.water_weight(world_pos) > 0.04
		var visual_kind := "rock" if in_water else str(obstacle["kind"])
		var node := OutdoorVisualFactory.build_obstacle(
			visual_kind, radius, int(obstacle["color"]), decor.next_float(), render_biome)
		node.position = _local(obstacle["x"], obstacle["y"])
		# Gameplay obstacles keep a single collision anchor, while their visuals
		# receive a small planted skirt to eliminate the scattered-sticker look.
		for index in range(2 if visual_lod == 0 else 1):
			var angle: float = decor.next_float() * TAU
			var offset: Vector2 = Vector2(cos(angle), sin(angle) * 0.55) * (radius + 18.0 + decor.next_float() * 18.0)
			var skirt_kind := "rock" if in_water else "bush" if render_biome in ["academy", "wild"] else "rock" if render_biome in ["geo", "ruins"] else "crystal"
			var skirt := OutdoorVisualFactory.build_obstacle(skirt_kind, maxf(11.0, radius * 0.42), int(obstacle["color"]), decor.next_float(), render_biome)
			skirt.position = offset
			skirt.scale = Vector2.ONE * 0.72
			node.add_child(skirt)
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
		var world_pos := Vector2(float(prop["x"]), float(prop["y"]))
		var render_biome := _render_biome(world_pos, decor.next_float())
		var kind := str(prop["kind"])
		var in_water := composition != null and composition.water_weight(world_pos) > 0.14
		var near_water := composition != null and _near_composition_water(world_pos, 92.0)
		if kind in ["bridge", "river", "waterfall"] and not near_water:
			continue
		if in_water and kind != "bridge":
			continue
		var node := OutdoorVisualFactory.build_prop(
			kind, int(prop["color"]), decor.next_float(), render_biome)
		node.position = _local(prop["x"], prop["y"])
		if in_water and kind == "bridge" and composition != null:
			node.rotation = composition.water_tangent(world_pos).angle() - PI * 0.5
		add_child(node)

func _render_biome(world_pos: Vector2, selector: float = 0.5) -> String:
	return composition.sampled_biome(world_pos, selector) if composition != null else str(chunk.get("biome", "academy"))

func _near_composition_water(world_pos: Vector2, distance: float) -> bool:
	if composition.water_weight(world_pos) > 0.04:
		return true
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		if composition.water_weight(world_pos + direction * distance) > 0.08:
			return true
	return false

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
	area.add_to_group("world_interactable")
	if kind == "encounter":
		# Contratto di navigazione C-P0: la scena individua gli incontri caricati
		# senza scandire l'intero albero e senza conoscere l'implementazione dei
		# chunk. Il gruppo scompare automaticamente quando il chunk viene scaricato.
		area.add_to_group("mission_poi")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_RADIUS
	shape.shape = circle
	area.add_child(shape)
	node.add_child(area)
	if world != null:
		area.body_entered.connect(func(body): world.on_interactable_entered(area, body))
		area.body_exited.connect(func(body): world.on_interactable_exited(area, body))
