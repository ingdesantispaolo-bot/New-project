class_name BiomeAssemblySpawner
extends RefCounted

## Global blue-noise-like assembly lattice. Positions are seeded in world
## coordinates and never regenerated per chunk, so groves cross stream cells.
const CELL_SIZE := 210.0

static func points_for_rect(data: WorldCompositionData, world_rect: Rect2, lod: int = 0) -> Array:
	var points: Array = []
	var min_x := floori(world_rect.position.x / CELL_SIZE) - 1
	var max_x := ceili(world_rect.end.x / CELL_SIZE) + 1
	var min_y := floori(world_rect.position.y / CELL_SIZE) - 1
	var max_y := ceili(world_rect.end.y / CELL_SIZE) + 1
	for gy in range(min_y, max_y + 1):
		for gx in range(min_x, max_x + 1):
			var rng := OutdoorDeterministicRng.new("%s:assembly:%d:%d" % [data.seed, gx, gy])
			var pos := Vector2((gx + 0.18 + rng.next_float() * 0.64) * CELL_SIZE, (gy + 0.18 + rng.next_float() * 0.64) * CELL_SIZE)
			if not world_rect.has_point(pos):
				continue
			if data.distance_to_paths(pos) < 118.0 or data.water_weight(pos) > 0.08 or not data.pocket_at(pos).is_empty():
				continue
			var biome := data.dominant_biome(pos)
			var density := float(BiomeProfile.get_profile(biome)["density"])
			var threshold := minf(0.96, density * (0.88 if lod == 0 else 0.52))
			if rng.next_float() > threshold:
				continue
			points.append({
				"position": pos,
				"biome": biome,
				"variant": rng.next_float(),
				"scale": 0.88 + rng.next_float() * 0.38,
				"spread": 46.0 + rng.next_float() * 34.0,
				"archetype": floori(rng.next_float() * 4.0),
				"phase": rng.next_float() * TAU,
			})
	return points
