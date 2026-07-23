class_name WorldCompositionData
extends RefCounted

var seed := "outdoor-dev-1"
var biome_influences: Array = []
var paths: Array = []
var waters: Array = []
var hero_pockets: Array = []
## Identità visuale del profilo: il terreno può scegliere un underpaint
## specifico e le regioni/props autorate definiscono la silhouette del mondo.
## Sono dati puramente visuali e non modificano progressione o ricompense.
var visual_theme := "legacy"
var identity_regions: Array = []
var identity_props: Array = []
## Zone e corridoi autorati dal WorldProfile. Acqua e decorazioni di terreno
## possono lambirli, ma non devono rendere illeggibili ingresso nave e percorso
## sicuro spawn→nave.
var protected_zones: Array = []
var protected_corridors: Array = []

func biome_weights(world_pos: Vector2) -> Dictionary:
	var raw := {}
	var total := 0.0
	for influence in biome_influences:
		var radius := maxf(1.0, float(influence.get("radius", 1500.0)))
		var distance := world_pos.distance_to(influence["position"])
		var normalized := distance / radius
		var weight := 1.0 / pow(1.0 + normalized * normalized, 2.0)
		var id := str(influence["biome"])
		raw[id] = float(raw.get(id, 0.0)) + weight
		total += weight
	if total <= 0.0001:
		return {"academy": 1.0}
	for id in raw.keys():
		raw[id] = float(raw[id]) / total
	return raw

func dominant_biome(world_pos: Vector2) -> String:
	var weights := biome_weights(world_pos)
	var best := "academy"
	var best_weight := -1.0
	for id in weights.keys():
		if float(weights[id]) > best_weight:
			best = str(id)
			best_weight = float(weights[id])
	return best

func sampled_biome(world_pos: Vector2, selector: float) -> String:
	# Il dominante puro produceva una frontiera di props netta anche quando il
	# terreno era gia miscelato. Una selezione pesata e leggermente accentuata
	# conserva l'identita dei nuclei, ma intreccia le specie nelle ecotone.
	var weights := biome_weights(world_pos)
	var ids: Array = weights.keys()
	ids.sort()
	var sharpened_total := 0.0
	for id in ids:
		sharpened_total += pow(float(weights[id]), 2.35)
	var cursor := 0.0
	var target := clampf(selector, 0.0, 0.999999) * maxf(sharpened_total, 0.0001)
	for id in ids:
		cursor += pow(float(weights[id]), 2.35)
		if target <= cursor:
			return str(id)
	return dominant_biome(world_pos)

func blended_ground(world_pos: Vector2) -> Color:
	var weights := biome_weights(world_pos)
	var color := Color(0, 0, 0, 1)
	for id in weights.keys():
		color += Color(BiomeProfile.get_profile(str(id))["ground"], 1.0) * float(weights[id])
	color.a = 1.0
	return color

func blended_accent(world_pos: Vector2) -> Color:
	var weights := biome_weights(world_pos)
	var color := Color(0, 0, 0, 1)
	for id in weights.keys():
		color += Color(BiomeProfile.get_profile(str(id))["accent"], 1.0) * float(weights[id])
	color.a = 1.0
	return color

func distance_to_paths(world_pos: Vector2) -> float:
	var best := INF
	for path in paths:
		var points: PackedVector2Array = path.get("points", PackedVector2Array())
		for i in range(maxi(0, points.size() - 1)):
			best = minf(best, _distance_to_segment(world_pos, points[i], points[i + 1]))
	return best

func water_weight(world_pos: Vector2) -> float:
	var best := 0.0
	for water in waters:
		if str(water.get("kind", "pond")) == "stream":
			var points: PackedVector2Array = water.get("points", PackedVector2Array())
			var half_width := maxf(1.0, float(water.get("width", 180.0)) * 0.5)
			for index in range(maxi(0, points.size() - 1)):
				var normalized := _distance_to_segment(world_pos, points[index], points[index + 1]) / half_width
				best = maxf(best, 1.0 - smoothstep(0.76, 1.0, normalized))
		else:
			var center: Vector2 = water["position"]
			var radii: Vector2 = water["radii"]
			var q := (world_pos - center) / radii
			best = maxf(best, 1.0 - smoothstep(0.72, 1.0, q.length()))
	var protection := _protection_weight(world_pos)
	return clampf(best * (1.0 - protection), 0.0, 1.0)

func water_tangent(world_pos: Vector2) -> Vector2:
	var best_distance := INF
	var best_tangent := Vector2.DOWN
	for water in waters:
		if str(water.get("kind", "pond")) != "stream":
			continue
		var points: PackedVector2Array = water.get("points", PackedVector2Array())
		for index in range(maxi(0, points.size() - 1)):
			var distance := _distance_to_segment(world_pos, points[index], points[index + 1])
			if distance < best_distance:
				best_distance = distance
				best_tangent = (points[index + 1] - points[index]).normalized()
	return best_tangent

func pocket_at(world_pos: Vector2) -> Dictionary:
	for pocket in hero_pockets:
		if world_pos.distance_to(pocket["position"]) <= float(pocket["radius"]):
			return pocket
	return {}

func is_protected(world_pos: Vector2, extra_margin: float = 0.0) -> bool:
	for zone in protected_zones:
		if world_pos.distance_to(zone.get("position", Vector2.ZERO)) <= float(zone.get("radius", 0.0)) + extra_margin:
			return true
	for corridor in protected_corridors:
		var points: PackedVector2Array = corridor.get("points", PackedVector2Array())
		var width := float(corridor.get("width", 0.0)) + extra_margin
		for index in range(maxi(0, points.size() - 1)):
			if _distance_to_segment(world_pos, points[index], points[index + 1]) <= width:
				return true
	return false

func _protection_weight(world_pos: Vector2) -> float:
	var best := 0.0
	for zone in protected_zones:
		var radius := maxf(1.0, float(zone.get("radius", 0.0)))
		var distance := world_pos.distance_to(zone.get("position", Vector2.ZERO))
		best = maxf(best, 1.0 - smoothstep(radius, radius + 72.0, distance))
	for corridor in protected_corridors:
		var points: PackedVector2Array = corridor.get("points", PackedVector2Array())
		var width := maxf(1.0, float(corridor.get("width", 0.0)))
		for index in range(maxi(0, points.size() - 1)):
			var distance := _distance_to_segment(world_pos, points[index], points[index + 1])
			best = maxf(best, 1.0 - smoothstep(width, width + 54.0, distance))
	return clampf(best, 0.0, 1.0)

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return point.distance_to(a + ab * t)
