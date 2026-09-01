extends SceneTree

func _init() -> void:
	var base := WorldProfileCatalog.profile(1)
	var first := WorldExpeditionLayout.apply(base, "spedizione-a")
	var repeated := WorldExpeditionLayout.apply(base, "spedizione-a")
	var other := WorldExpeditionLayout.apply(base, "spedizione-b")
	var shape: PackedVector2Array = first["worldShape"]

	assert(shape.size() == WorldExpeditionLayout.VERTEX_COUNT, "la sagoma deve essere organica e stabile")
	assert(shape == repeated["worldShape"], "lo stesso seed deve ricostruire la spedizione")
	assert(shape != other["worldShape"], "un nuovo seed deve cambiare la macro-mappa")
	assert(first["worldExtents"] != Vector2.ONE * WorldProfileCatalog.WORLD_HALF_EXTENT,
		"le dimensioni non devono restare il vecchio quadrato fisso")
	assert(Geometry2D.is_point_in_polygon(first["spawn"], shape), "lo spawn deve restare nella sagoma")
	assert(Geometry2D.is_point_in_polygon(first["shipEntrance"]["position"], shape), "la nave deve restare nella sagoma")
	assert(int(first["expeditionLayout"]["pocketCount"]) in [3, 4, 5], "servono pochi luoghi memorabili")
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldExpeditionLayout.apply(
			WorldProfileCatalog.profile(level), "campagna-%02d" % level)
		var level_shape: PackedVector2Array = profile["worldShape"]
		assert(Geometry2D.is_point_in_polygon(profile["spawn"], level_shape),
			"spawn fuori sagoma al mondo %d" % level)
		assert(Geometry2D.is_point_in_polygon(profile["shipEntrance"]["position"], level_shape),
			"nave fuori sagoma al mondo %d" % level)
		var composition := WorldCompositionGenerator.generate("campagna-%02d" % level, profile)
		var expected := int(profile["expeditionLayout"]["pocketCount"])
		var found := 0
		for region_data in composition.identity_regions:
			if str(Dictionary(region_data).get("id", "")).begins_with("expedition-pocket-"):
				found += 1
		assert(found == expected, "luoghi di spedizione incompleti al mondo %d: %d/%d" % [level, found, expected])

	var manager := OutdoorChunkManager.new()
	manager.configure("spedizione-a", null, first)
	var pocket_count := int(first["expeditionLayout"]["pocketCount"])
	var expedition_paths := 0
	var expedition_regions := 0
	for path_data in manager.composition.paths:
		if str(Dictionary(path_data).get("id", "")).begins_with("expedition-trail-"):
			expedition_paths += 1
	for region_data in manager.composition.identity_regions:
		if str(Dictionary(region_data).get("id", "")).begins_with("expedition-pocket-"):
			expedition_regions += 1
	assert(expedition_paths == pocket_count, "ogni scoperta deve avere un sentiero")
	assert(expedition_regions == pocket_count, "ogni scoperta deve riusare una regione dell'art kit")
	var outside := WorldExpeditionLayout.bounds_of(shape).end + Vector2(900, 900)
	var recovered := manager.clamp_to_world(outside)
	assert(manager.contains_world_point(recovered, 70.0), "il recupero deve riportare dentro la costa")
	manager.free()

	var save := GameSaveManager.new("user://world-expedition-layout-audit.json")
	var seed_a := save.begin_world_expedition("1")
	save.set_world_resume("1", Vector2(123, 456), 0.4)
	assert(save.world_expedition_seed("1") == seed_a, "un rientro deve conservare la stessa mappa")
	var seed_b := save.begin_world_expedition("1")
	assert(seed_b != seed_a, "una nuova spedizione deve ricevere un seed nuovo")
	assert(save.world_resume("1").is_empty(), "una nuova sagoma non deve riusare la vecchia posizione")
	print("World expedition layout audit OK")
	quit()
