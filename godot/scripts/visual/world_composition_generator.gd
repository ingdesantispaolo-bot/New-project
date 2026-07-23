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
	elif level == 3:
		# Cratere: roccia modulare, minerali freddi e macchine. Nessuna massa
		# vegetale dominante: la silhouette deve leggere come canyon tecnico.
		biomes = ["logic", "crystal", "ruins"]
	elif level == 4:
		# Baia: costa, pietra salina e pochi nuclei più caldi sui moli.
		biomes = ["geo", "crystal", "academy"]
	var profile_id := str(profile.get("id", "world-%02d" % level))
	data.visual_theme = (
		"radura" if level == 1 else
		"archive" if level == 2 else
		"crater" if level == 3 else
		"signal_bay" if level == 4 else
		str(profile.get("artKit", subject))
	)
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
	elif level == 3:
		# Canyon a gradoni: tre terrazze collegate da una traccia a zig-zag.
		# Il giocatore vede fisicamente il concetto di sequenza/loop nel percorso.
		data.paths.append({
			"id": "crater-cycle-route",
			"width": 72.0,
			"points": PackedVector2Array([
				ship + Vector2(-1660, 610), ship + Vector2(-1060, 610),
				ship + Vector2(-700, 870), ship + Vector2(-120, 870),
				ship + Vector2(250, 610), ship + Vector2(920, 610),
				ship + Vector2(1320, 910), ship + Vector2(1700, 910),
			]),
		})
		data.paths.append({
			"id": "crater-inner-loop",
			"width": 56.0,
			"points": PackedVector2Array([
				ship + Vector2(-760, 1230), ship + Vector2(-300, 1040),
				ship + Vector2(280, 1080), ship + Vector2(700, 1320),
				ship + Vector2(260, 1570), ship + Vector2(-360, 1530),
				ship + Vector2(-760, 1230),
			]),
		})
	elif level == 4:
		# Porto a moli: una banchina orizzontale e tre pontili leggibili. Le
		# diramazioni incarnano messaggi inviati a destinatari diversi.
		data.paths.append({
			"id": "signal-harbour-walk",
			"width": 86.0,
			"points": PackedVector2Array([
				ship + Vector2(-1760, 720), ship + Vector2(-980, 690),
				ship + Vector2(-260, 740), ship + Vector2(480, 690),
				ship + Vector2(1180, 750), ship + Vector2(1740, 690),
			]),
		})
		for pier in [
			{"id": "west", "x": -980.0, "end": Vector2(-1280, 1500)},
			{"id": "center", "x": 120.0, "end": Vector2(240, 1610)},
			{"id": "east", "x": 1180.0, "end": Vector2(1460, 1450)},
		]:
			data.paths.append({
				"id": "signal-%s-pier" % str(pier["id"]),
				"width": 64.0,
				"points": PackedVector2Array([
					ship + Vector2(float(pier["x"]), 720),
					ship + Vector2(float(pier["x"]), 1120),
					ship + (pier["end"] as Vector2),
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
	if level == 2 or level == 3:
		# L'Archivio non riusa il fiume naturale: la separazione fra le sale è
		# resa da pavimenti sospesi, foschia e ponti di parole. Il Cratere usa
		# invece terrazze asciutte: niente laghetto naturale nel canyon tecnico.
		data.waters = []
	elif level == 4:
		# Canali marini ai bordi: il corridoio nave e i moli restano asciutti.
		data.waters = [
			{
				"id": "signal-west-channel",
				"kind": "stream",
				"width": 390.0,
				"points": PackedVector2Array([
					ship + Vector2(-1860, 360), ship + Vector2(-1700, 920),
					ship + Vector2(-1830, 1510), ship + Vector2(-1660, 2010),
				]),
			},
			{
				"id": "signal-east-channel",
				"kind": "stream",
				"width": 330.0,
				"points": PackedVector2Array([
					ship + Vector2(1840, 460), ship + Vector2(1700, 980),
					ship + Vector2(1870, 1540), ship + Vector2(1710, 2050),
				]),
			},
		]
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
	elif level == 3:
		data.identity_regions = [
			{"id": "crater-west-step", "kind": "crater_terrace", "position": ship + Vector2(-1040, 620), "radii": Vector2(520, 260), "rotation": -0.04},
			{"id": "crater-cycle-floor", "kind": "crater_cycle", "position": ship + Vector2(0, 1280), "radii": Vector2(690, 390), "rotation": 0.03},
			{"id": "crater-east-step", "kind": "crater_terrace", "position": ship + Vector2(1150, 820), "radii": Vector2(470, 250), "rotation": 0.06},
		]
		data.identity_props = [
			{"kind": "sequence_pylon", "position": ship + Vector2(-1450, 520), "variant": 0.12},
			{"kind": "sequence_pylon", "position": ship + Vector2(-680, 820), "variant": 0.36},
			{"kind": "loop_engine", "position": ship + Vector2(-350, 1360), "variant": 0.54},
			{"kind": "sequence_pylon", "position": ship + Vector2(720, 800), "variant": 0.72},
			{"kind": "gear_cluster", "position": ship + Vector2(1390, 830), "variant": 0.88},
		]
	elif level == 4:
		data.identity_regions = [
			{"id": "signal-harbour", "kind": "signal_harbour", "position": ship + Vector2(0, 720), "radii": Vector2(1720, 250), "rotation": 0.01},
			{"id": "signal-west-dock", "kind": "signal_dock", "position": ship + Vector2(-1120, 1320), "radii": Vector2(310, 330), "rotation": -0.06},
			{"id": "signal-center-dock", "kind": "signal_dock", "position": ship + Vector2(180, 1390), "radii": Vector2(340, 390), "rotation": 0.03},
			{"id": "signal-east-dock", "kind": "signal_dock", "position": ship + Vector2(1320, 1280), "radii": Vector2(300, 310), "rotation": 0.08},
		]
		data.identity_props = [
			{"kind": "signal_buoy", "position": ship + Vector2(-1490, 1010), "variant": 0.15},
			{"kind": "radio_mast", "position": ship + Vector2(-860, 660), "variant": 0.34},
			{"kind": "signal_console", "position": ship + Vector2(160, 1140), "variant": 0.52},
			{"kind": "radio_mast", "position": ship + Vector2(980, 700), "variant": 0.70},
			{"kind": "signal_buoy", "position": ship + Vector2(1510, 1070), "variant": 0.88},
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
		{"id": "hero-landmark", "position": _profile_hero_position(ship, level), "radius": 210.0},
	]
	# Mantiene il seed semanticamente visibile negli strumenti di debug senza
	# usarlo per prendere decisioni didattiche.
	data.seed = "%s::%s" % [seed, profile_id]
	return data

static func _profile_hero_position(ship: Vector2, level: int) -> Vector2:
	if level == 3:
		return ship + Vector2(0, 1280)
	if level == 4:
		return ship + Vector2(1320, 1280)
	return ship + Vector2(690, -210)
