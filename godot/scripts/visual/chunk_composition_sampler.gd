class_name ChunkCompositionSampler
extends RefCounted

static func sample(data: WorldCompositionData, world_rect: Rect2, spacing: float = 128.0) -> Array:
	var samples: Array = []
	var start_x := floori(world_rect.position.x / spacing)
	var end_x := ceili(world_rect.end.x / spacing)
	var start_y := floori(world_rect.position.y / spacing)
	var end_y := ceili(world_rect.end.y / spacing)
	for gy in range(start_y, end_y + 1):
		for gx in range(start_x, end_x + 1):
			var pos := Vector2(gx * spacing, gy * spacing)
			if not world_rect.has_point(pos):
				continue
			samples.append({"world": pos, "biome": data.dominant_biome(pos), "ground": data.blended_ground(pos), "accent": data.blended_accent(pos), "pathDistance": data.distance_to_paths(pos), "water": data.water_weight(pos)})
	return samples
