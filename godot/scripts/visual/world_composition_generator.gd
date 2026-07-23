class_name WorldCompositionGenerator
extends RefCounted

static func generate(seed: String, profile: Dictionary = {}) -> WorldCompositionData:
	if not profile.is_empty():
		return _generate_profile_composition(seed, profile)
	var data := WorldCompositionData.new()
	data.seed = seed
	# Influenze sovrapposte: i confini cadono dentro zone larghe, mai sui bordi
	# tecnici dei chunk. La Radura occupa un'ampia regione centrale.
	data.biome_influences = [
		{"biome": "academy", "position": Vector2(448, 448), "radius": 2100.0},
		{"biome": "wild", "position": Vector2(-2450, -500), "radius": 1750.0},
		{"biome": "geo", "position": Vector2(-500, 2800), "radius": 1750.0},
		{"biome": "logic", "position": Vector2(2850, -650), "radius": 1750.0},
		{"biome": "ruins", "position": Vector2(-2450, -2700), "radius": 1650.0},
		{"biome": "crystal", "position": Vector2(2700, 2650), "radius": 1650.0},
	]
	data.paths = [
		{"id": "academy-spine", "width": 72.0, "points": PackedVector2Array([Vector2(-1800, 780), Vector2(-1420, 690), Vector2(-930, 635), Vector2(-420, 780), Vector2(80, 740), Vector2(260, 710), Vector2(448, 520), Vector2(790, 430), Vector2(1120, 350), Vector2(1540, 190), Vector2(2100, 80), Vector2(2630, -210), Vector2(3200, -420)])},
		{"id": "academy-garden-spur", "width": 54.0, "points": PackedVector2Array([Vector2(90, 1030), Vector2(135, 850), Vector2(180, 650), Vector2(320, 430), Vector2(448, 360)])},
		{"id": "south-route", "width": 64.0, "points": PackedVector2Array([Vector2(460, 520), Vector2(505, 820), Vector2(475, 1160), Vector2(560, 1480), Vector2(430, 1800), Vector2(250, 2100), Vector2(-40, 2440), Vector2(-260, 2720), Vector2(-420, 3000)])},
	]
	data.waters = [
		{"id": "academy-pond", "kind": "pond", "position": Vector2(160, 520), "radii": Vector2(230, 150)},
		{"id": "geo-stream", "kind": "stream", "width": 220.0, "points": PackedVector2Array([
			Vector2(-780, 1620), Vector2(-620, 1850), Vector2(-700, 2110),
			Vector2(-485, 2320), Vector2(-390, 2580), Vector2(-520, 2820),
			Vector2(-360, 3070), Vector2(-170, 3300),
		])},
	]
	data.hero_pockets = [
		{"id": "portal", "position": Vector2(448, 300), "radius": 270.0},
		{"id": "pond", "position": Vector2(160, 520), "radius": 300.0},
		{"id": "academy-house", "position": Vector2(820, 430), "radius": 300.0},
	]
	return data

const SUBJECT_BIOMES := {
	"matematica": ["academy", "wild", "crystal"],
	"italiano": ["ruins", "wild", "academy"],
	"coding": ["logic", "crystal", "ruins"],
	"inglese": ["geo", "academy", "wild"],
	"fisica": ["geo", "logic", "crystal"],
	"musica": ["crystal", "wild", "academy"],
	"latino": ["ruins", "geo", "wild"],
	"elettronica": ["logic", "crystal", "geo"],
	"geografia": ["geo", "wild", "ruins"],
	"scienze": ["wild", "academy", "crystal"],
	"cittadinanza": ["academy", "ruins", "geo"],
	"logica": ["logic", "ruins", "crystal"],
}

static func _generate_profile_composition(seed: String, profile: Dictionary) -> WorldCompositionData:
	var data := WorldCompositionData.new()
	data.seed = seed
	var subject := str(profile.get("learningFocus", {}).get("subject", "matematica"))
	var biomes: Array = Array(SUBJECT_BIOMES.get(subject, ["academy", "wild", "crystal"]))
	var ship: Vector2 = profile.get("shipEntrance", {}).get("position", Vector2.ZERO)
	var spawn: Vector2 = profile.get("spawn", ship + Vector2(0, 1180))
	var half_extent := float(profile.get("worldHalfExtent", 2200.0))
	var level := int(profile.get("level", 1))
	if level == 2:
		# L'Archivio è vegetale nei dettagli, ma la sua massa deve restare
		# minerale/arcana: niente prato e girasoli della Radura come dominanti.
		biomes = ["ruins", "crystal", "logic"]
	var profile_id := str(profile.get("id", "world-%02d" % level))
	data.visual_theme = "radura" if level == 1 else "archive" if level == 2 else str(profile.get("artKit", subject))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s::profile-composition::%d" % [seed, level]))
	var phase := rng.randf_range(-0.35, 0.35)

	# Il profilo decide l'identità dominante; biomi secondari creano ecotoni
	# leggibili senza reintrodurre la stessa mappa multi-bioma in tutti i mondi.
	data.biome_influences = [
		{"biome": str(biomes[0]), "position": ship + Vector2(0, 360), "radius": half_extent * 0.92},
		{"biome": str(biomes[1]), "position": ship + Vector2(-half_extent * 0.72, -half_extent * 0.34).rotated(phase), "radius": half_extent * 0.62},
		{"biome": str(biomes[2]), "position": ship + Vector2(half_extent * 0.70, half_extent * 0.36).rotated(-phase), "radius": half_extent * 0.58},
	]

	var route := PackedVector2Array()
	for point in profile.get("safeRoute", []):
		route.append(point as Vector2)
	data.paths = [{
		"id": "profile-safe-route",
		"width": 82.0,
		"points": route,
	}]
	if level == 1:
		# Radura: percorso aperto e curvo che avvolge il prato centrale.
		data.paths.append({
			"id": "radura-learning-loop",
			"width": 66.0,
			"points": PackedVector2Array([
				ship + Vector2(-1460, 840), ship + Vector2(-850, 620),
				ship + Vector2(-260, 760), ship + Vector2(420, 650),
				ship + Vector2(1060, 880), ship + Vector2(1510, 620),
			]),
		})
		data.paths.append({
			"id": "radura-crystal-spur",
			"width": 48.0,
			"points": PackedVector2Array([
				ship + Vector2(-260, 760), ship + Vector2(-620, 1180),
				ship + Vector2(-980, 1450),
			]),
		})
	elif level == 2:
		# Archivio: sale collegate da assi e ponti. Il ritmo ortogonale è
		# deliberatamente opposto alla radura organica.
		data.paths.append({
			"id": "archive-gallery-axis",
			"width": 86.0,
			"points": PackedVector2Array([
				ship + Vector2(-1720, 720), ship + Vector2(-860, 720),
				ship + Vector2(0, 720), ship + Vector2(860, 720),
				ship + Vector2(1720, 720),
			]),
		})
		data.paths.append({
			"id": "archive-west-bridge",
			"width": 62.0,
			"points": PackedVector2Array([
				ship + Vector2(-860, 720), ship + Vector2(-860, 1180),
				ship + Vector2(-1180, 1510),
			]),
		})
		data.paths.append({
			"id": "archive-east-bridge",
			"width": 62.0,
			"points": PackedVector2Array([
				ship + Vector2(860, 720), ship + Vector2(860, 1160),
				ship + Vector2(1180, 1510),
			]),
		})
	else:
		# Gli altri profili mantengono una seconda arteria deterministica finché
		# ricevono la propria vertical slice nelle ondate C-P5.
		var cross_y := ship.y + 620.0 + float((level % 4) * 105)
		var bend := rng.randf_range(-260.0, 260.0)
		data.paths.append({
			"id": "profile-topology-%s" % str(profile.get("topology", "aperta")),
			"width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(-half_extent * 0.86, cross_y - ship.y + bend),
				ship + Vector2(-half_extent * 0.34, cross_y - ship.y),
				ship + Vector2(half_extent * 0.22, cross_y - ship.y - bend * 0.35),
				ship + Vector2(half_extent * 0.84, cross_y - ship.y + bend * 0.22),
			]),
		})

	# Acqua/profile dressing: sempre fuori dalla zona nave e mascherato dal
	# corridoio sicuro in WorldCompositionData.water_weight().
	if level == 2:
		# L'Archivio non riusa il fiume naturale: la separazione fra le sale è
		# resa da pavimenti sospesi, foschia e ponti di parole.
		data.waters = []
	elif level % 2 == 0:
		data.waters = [{
			"id": "profile-stream-%d" % level,
			"kind": "stream",
			"width": 180.0,
			"points": PackedVector2Array([
				ship + Vector2(-half_extent * 0.78, 310),
				ship + Vector2(-half_extent * 0.58, 720),
				ship + Vector2(-half_extent * 0.72, 1180),
				ship + Vector2(-half_extent * 0.52, 1680),
			]),
		}]
	else:
		data.waters = [{
			"id": "profile-pond-%d" % level,
			"kind": "pond",
			"position": ship + Vector2(-560, 620),
			"radii": Vector2(250, 170),
		}]

	if level == 1:
		data.identity_regions = [
			{"id": "radura-courtyard", "kind": "radura_clearing", "position": ship + Vector2(0, 720), "radii": Vector2(570, 330), "rotation": -0.05},
			{"id": "radura-crystal-garden", "kind": "radura_garden", "position": ship + Vector2(-960, 1450), "radii": Vector2(310, 190), "rotation": 0.12},
		]
		data.identity_props = [
			{"kind": "number_stone", "position": ship + Vector2(-520, 1010), "variant": 0.14},
			{"kind": "number_stone", "position": ship + Vector2(520, 980), "variant": 0.48},
			{"kind": "number_stone", "position": ship + Vector2(1050, 690), "variant": 0.82},
		]
	elif level == 2:
		data.identity_regions = [
			{"id": "archive-west-hall", "kind": "archive_room", "position": ship + Vector2(-900, 720), "radii": Vector2(430, 270), "rotation": -0.04},
			{"id": "archive-central-hall", "kind": "archive_room", "position": ship + Vector2(0, 720), "radii": Vector2(510, 300), "rotation": 0.02},
			{"id": "archive-east-hall", "kind": "archive_room", "position": ship + Vector2(900, 720), "radii": Vector2(430, 270), "rotation": 0.05},
			{"id": "archive-west-vault", "kind": "archive_room", "position": ship + Vector2(-1180, 1510), "radii": Vector2(350, 235), "rotation": 0.08},
			{"id": "archive-east-vault", "kind": "archive_room", "position": ship + Vector2(1180, 1510), "radii": Vector2(350, 235), "rotation": -0.08},
		]
		data.identity_props = [
			{"kind": "archive_shelf", "position": ship + Vector2(-1220, 520), "variant": 0.12},
			{"kind": "archive_shelf", "position": ship + Vector2(-610, 470), "variant": 0.37},
			{"kind": "archive_shelf", "position": ship + Vector2(630, 470), "variant": 0.61},
			{"kind": "archive_shelf", "position": ship + Vector2(1230, 520), "variant": 0.86},
			{"kind": "archive_pillar", "position": ship + Vector2(-1080, 1040), "variant": 0.24},
			{"kind": "archive_pillar", "position": ship + Vector2(1080, 1040), "variant": 0.74},
			{"kind": "archive_scriptorium", "position": ship + Vector2(0, 1180), "variant": 0.52},
		]

	var safe_radius := float(profile.get("shipEntrance", {}).get("safeRadius", 340.0))
	data.protected_zones = [{
		"id": "ship-entrance",
		"position": ship,
		"radius": safe_radius,
	}]
	data.protected_corridors = [{
		"id": "spawn-ship-route",
		"points": route,
		"width": 92.0,
	}]
	data.hero_pockets = [
		{"id": "portal", "position": ship, "radius": safe_radius},
		{"id": "spawn", "position": spawn, "radius": 180.0},
		{"id": "hero-landmark", "position": ship + Vector2(690, -210), "radius": 170.0},
	]
	# Mantiene il seed semanticamente visibile negli strumenti di debug senza
	# usarlo per prendere decisioni didattiche.
	data.seed = "%s::%s" % [seed, profile_id]
	return data
