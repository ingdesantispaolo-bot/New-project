class_name OutdoorChunkManager
extends Node2D

const CHUNK_SIZE := 896
const WORLD_MIN := -4
const WORLD_MAX := 3
const ACTIVE_RADIUS := 1
const CHUNK_VISUAL := preload("res://scripts/chunk_visual.gd")

var world_seed := "outdoor-dev-1"
var generator := OutdoorGenerator.new()
var loaded: Dictionary = {}
var player_position := Vector2.ZERO
var world: Node

func configure(seed: String, world_ref: Node = null) -> void:
	world_seed = seed
	world = world_ref
	y_sort_enabled = true

func update_stream(position: Vector2) -> void:
	player_position = position
	var center_x := floori(position.x / CHUNK_SIZE)
	var center_y := floori(position.y / CHUNK_SIZE)
	var required := {}
	for y in range(center_y - ACTIVE_RADIUS, center_y + ACTIVE_RADIUS + 1):
		for x in range(center_x - ACTIVE_RADIUS, center_x + ACTIVE_RADIUS + 1):
			if x < WORLD_MIN or x > WORLD_MAX or y < WORLD_MIN or y > WORLD_MAX:
				continue
			var id := "chunk-%d_%d" % [x, y]
			required[id] = true
			if not loaded.has(id):
				var visual_lod := 0 if x == center_x and y == center_y else 1
				_load_chunk(generator.generate_chunk(world_seed, x, y), visual_lod)
	var stale_ids: Array[String] = []
	for id in loaded.keys():
		if not required.has(id):
			stale_ids.append(str(id))
	for id in stale_ids:
		_unload_chunk(id)

func _load_chunk(chunk: Dictionary, visual_lod: int = 0) -> void:
	var node: OutdoorChunkVisual = CHUNK_VISUAL.new()
	node.name = str(chunk["id"])
	node.position = Vector2(chunk["worldX"], chunk["worldY"])
	add_child(node)
	node.configure(chunk, world, visual_lod)
	loaded[chunk["id"]] = {"data": chunk, "node": node}

func _unload_chunk(id: String) -> void:
	var entry: Dictionary = loaded[id]
	if is_instance_valid(entry["node"]):
		entry["node"].queue_free()
	loaded.erase(id)
