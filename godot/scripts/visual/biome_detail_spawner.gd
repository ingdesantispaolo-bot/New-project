class_name BiomeDetailSpawner
extends RefCounted

## Micro-dettagli globali, deterministici e consapevoli dell'habitat. Il reticolo
## vive in coordinate mondo: ninfee, canneti e sottobosco non si interrompono ai
## confini dei chunk e non consumano l'RNG del gameplay.
const CELL_SIZE := 132.0

static func points_for_rect(data: WorldCompositionData, world_rect: Rect2, lod: int = 0) -> Array:
	var points: Array = []
	var min_x := floori(world_rect.position.x / CELL_SIZE) - 1
	var max_x := ceili(world_rect.end.x / CELL_SIZE) + 1
	var min_y := floori(world_rect.position.y / CELL_SIZE) - 1
	var max_y := ceili(world_rect.end.y / CELL_SIZE) + 1
	for gy in range(min_y, max_y + 1):
		for gx in range(min_x, max_x + 1):
			var rng := OutdoorDeterministicRng.new("%s:detail:%d:%d" % [data.seed, gx, gy])
			var pos := Vector2((gx + 0.12 + rng.next_float() * 0.76) * CELL_SIZE, (gy + 0.12 + rng.next_float() * 0.76) * CELL_SIZE)
			if not world_rect.has_point(pos) or not data.pocket_at(pos).is_empty():
				continue
			var water := data.water_weight(pos)
			var near_water := _near_water(data, pos, 68.0)
			var path_distance := data.distance_to_paths(pos)
			var kind := ""
			if water > 0.28:
				kind = "lilies" if rng.next_float() < 0.58 else "water_flowers"
			elif near_water and path_distance > 42.0:
				var edge_roll := rng.next_float()
				kind = "reeds" if edge_roll < 0.42 else "cattails" if edge_roll < 0.72 else "pebble_bank"
			elif path_distance > 54.0:
				kind = _land_kind(data.sampled_biome(pos, rng.next_float()), rng.next_float())
			if kind.is_empty():
				continue
			var base_chance := 0.82 if water > 0.28 or near_water else 0.58
			if lod > 0:
				base_chance *= 0.45
			if rng.next_float() > base_chance:
				continue
			points.append({
				"position": pos,
				"kind": kind,
				"scale": 0.72 + rng.next_float() * 0.52,
				"flip": -1.0 if rng.next_float() < 0.5 else 1.0,
				"water": water > 0.28,
			})
	return points

static func _near_water(data: WorldCompositionData, pos: Vector2, distance: float) -> bool:
	if data.water_weight(pos) > 0.02:
		return true
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		if data.water_weight(pos + direction * distance) > 0.08:
			return true
	return false

static func _land_kind(biome: String, roll: float) -> String:
	match biome:
		"academy":
			return "grass" if roll < 0.30 else "wildflowers" if roll < 0.62 else "leaves" if roll < 0.82 else "fern"
		"wild":
			return "fern" if roll < 0.30 else "leaves" if roll < 0.54 else "mushrooms" if roll < 0.78 else "driftwood"
		"geo", "ruins":
			return "grass" if roll < 0.26 else "pebble_bank" if roll < 0.55 else "stepping_stones" if roll < 0.80 else "rune_pebbles"
		"logic", "crystal":
			return "crystal_moss" if roll < 0.40 else "glow_flowers" if roll < 0.72 else "rune_pebbles"
		_:
			return "grass"
