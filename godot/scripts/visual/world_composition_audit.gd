extends SceneTree

func _init() -> void:
	var data := WorldCompositionGenerator.generate("audit-seed")
	for x in range(-3, 4):
		for y in range(-3, 4):
			var edge_x := float(x * 896)
			var edge_y := float(y * 896)
			var left := data.blended_ground(Vector2(edge_x - 0.01, edge_y + 317.0))
			var right := data.blended_ground(Vector2(edge_x + 0.01, edge_y + 317.0))
			assert(_color_delta(left, right) < 0.001, "discontinuita verticale")
			var top := data.blended_ground(Vector2(edge_x + 271.0, edge_y - 0.01))
			var bottom := data.blended_ground(Vector2(edge_x + 271.0, edge_y + 0.01))
			assert(_color_delta(top, bottom) < 0.001, "discontinuita orizzontale")
	assert(data.distance_to_paths(Vector2(448, 520)) < 10.0)
	assert(data.water_weight(Vector2(160, 520)) > 0.9)
	assert(data.water_weight(Vector2(-485, 2320)) > 0.9, "asse del fiume non campionato")
	assert(data.water_weight(Vector2(-150, 2320)) < 0.1, "alveo troppo largo")
	assert(data.water_tangent(Vector2(-485, 2320)).length() > 0.99, "tangente fiume assente")
	var hero_rect := Rect2(Vector2.ZERO, Vector2(896, 896))
	var hero_points := BiomeAssemblySpawner.points_for_rect(data, hero_rect, 0)
	var far_points := BiomeAssemblySpawner.points_for_rect(data, hero_rect, 2)
	assert(far_points.size() <= hero_points.size(), "HLOD lontano non riduce i cluster")
	assert(hero_points.size() <= 20, "budget assemblies eccessivo per chunk")
	var geo_rect := Rect2(Vector2(-896, 1792), Vector2(896, 896))
	var details := BiomeDetailSpawner.points_for_rect(data, geo_rect, 0)
	var far_details := BiomeDetailSpawner.points_for_rect(data, geo_rect, 2)
	assert(details.size() <= 80, "budget micro-dettagli eccessivo")
	assert(far_details.size() <= details.size(), "HLOD lontano non riduce i dettagli")
	var aquatic_count := 0
	for detail in details:
		if str(detail["kind"]) in ["lilies", "water_flowers"]:
			aquatic_count += 1
			assert(data.water_weight(detail["position"]) > 0.28, "dettaglio acquatico fuori alveo")
	assert(aquatic_count > 0, "habitat acquatico vuoto")
	print("Pipeline AAA audit OK - pesi, spline, fiume e habitat continui sui bordi")
	quit(0)

func _color_delta(a: Color, b: Color) -> float:
	return Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b))
