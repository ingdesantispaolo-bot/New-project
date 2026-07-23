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
	elif level == 5:
		biomes = ["logic", "ruins", "geo"]
	elif level == 6:
		biomes = ["crystal", "wild", "logic"]
	elif level == 7:
		biomes = ["ruins", "geo", "academy"]
	elif level == 8:
		biomes = ["logic", "crystal", "geo"]
	elif level == 9:
		biomes = ["geo", "academy", "crystal"]
	elif level == 10:
		biomes = ["wild", "academy", "crystal"]
	elif level == 11:
		biomes = ["academy", "ruins", "geo"]
	elif level == 12:
		biomes = ["logic", "ruins", "crystal"]
	var profile_id := str(profile.get("id", "world-%02d" % level))
	data.visual_theme = (
		"radura" if level == 1 else
		"archive" if level == 2 else
		"crater" if level == 3 else
		"signal_bay" if level == 4 else
		"motion_forge" if level == 5 else
		"resonance_garden" if level == 6 else
		"glyph_ruins" if level == 7 else
		"circuit_delta" if level == 8 else
		"charted_archipelago" if level == 9 else
		"symbiosis_greenhouse" if level == 10 else
		"civic_city" if level == 11 else
		"rule_labyrinth" if level == 12 else
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
	elif level == 5:
		# Officine: rotaia principale più due rampe. La geometria rende visibili
		# forza, pendenza e vantaggio meccanico.
		data.paths.append({
			"id": "motion-main-rail", "width": 74.0,
			"points": PackedVector2Array([
				ship + Vector2(-1780, 700), ship + Vector2(-920, 700),
				ship + Vector2(0, 760), ship + Vector2(920, 700),
				ship + Vector2(1780, 700),
			]),
		})
		data.paths.append({
			"id": "motion-west-ramp", "width": 66.0,
			"points": PackedVector2Array([
				ship + Vector2(-1180, 700), ship + Vector2(-980, 1060),
				ship + Vector2(-620, 1390), ship + Vector2(-180, 1450),
			]),
		})
		data.paths.append({
			"id": "motion-east-ramp", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(1080, 700), ship + Vector2(920, 1120),
				ship + Vector2(1280, 1510), ship + Vector2(1680, 1510),
			]),
		})
	elif level == 6:
		# Terrazze sonore: curve parallele come onde, collegate da uno stelo.
		data.paths.append({
			"id": "resonance-lower-terrace", "width": 64.0,
			"points": PackedVector2Array([
				ship + Vector2(-1760, 780), ship + Vector2(-1120, 610),
				ship + Vector2(-420, 760), ship + Vector2(240, 620),
				ship + Vector2(930, 790), ship + Vector2(1710, 650),
			]),
		})
		data.paths.append({
			"id": "resonance-upper-terrace", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(-1420, 1420), ship + Vector2(-780, 1240),
				ship + Vector2(0, 1400), ship + Vector2(760, 1210),
				ship + Vector2(1450, 1420),
			]),
		})
		data.paths.append({
			"id": "resonance-stem", "width": 48.0,
			"points": PackedVector2Array([
				ship + Vector2(-420, 760), ship + Vector2(-260, 1040),
				ship + Vector2(0, 1400),
			]),
		})
	elif level == 7:
		# Rovine urbane: cardo, decumano e piazze ad angolo retto.
		data.paths.append({
			"id": "glyph-decumanus", "width": 88.0,
			"points": PackedVector2Array([
				ship + Vector2(-1800, 730), ship + Vector2(-900, 730),
				ship + Vector2(0, 730), ship + Vector2(900, 730),
				ship + Vector2(1800, 730),
			]),
		})
		for x: float in [-960.0, 0.0, 960.0]:
			data.paths.append({
				"id": "glyph-cardo-%d" % roundi(x), "width": 58.0,
				"points": PackedVector2Array([
					ship + Vector2(x, 730), ship + Vector2(x, 1120),
					ship + Vector2(x + (120.0 if x < 0 else -120.0 if x > 0 else 0.0), 1660),
				]),
			})
	elif level == 8:
		# Delta: un anello conduttivo e tre rami collegano isole-nodo.
		data.paths.append({
			"id": "circuit-delta-loop", "width": 54.0,
			"points": PackedVector2Array([
				ship + Vector2(-1280, 740), ship + Vector2(-760, 560),
				ship + Vector2(0, 760), ship + Vector2(760, 560),
				ship + Vector2(1280, 780), ship + Vector2(920, 1320),
				ship + Vector2(0, 1480), ship + Vector2(-920, 1320),
				ship + Vector2(-1280, 740),
			]),
		})
		for branch in [
			PackedVector2Array([ship + Vector2(-760, 560), ship + Vector2(-1460, 1180), ship + Vector2(-1750, 1610)]),
			PackedVector2Array([ship + Vector2(0, 760), ship + Vector2(0, 1120), ship + Vector2(0, 1480)]),
			PackedVector2Array([ship + Vector2(760, 560), ship + Vector2(1480, 1120), ship + Vector2(1770, 1580)]),
		]:
			data.paths.append({"id": "circuit-branch-%d" % data.paths.size(), "width": 46.0, "points": branch})
	elif level == 9:
		# Arcipelago: una rotta ad anello e tre approdi rendono orientamento,
		# coordinate e collegamenti leggibili direttamente nella geografia.
		data.paths.append({
			"id": "chart-main-route", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(-1420, 730), ship + Vector2(-820, 560),
				ship + Vector2(-80, 760), ship + Vector2(700, 560),
				ship + Vector2(1430, 780), ship + Vector2(1040, 1330),
				ship + Vector2(120, 1510), ship + Vector2(-900, 1320),
				ship + Vector2(-1420, 730),
			]),
		})
		for chart_route in [
			{"id": "west", "points": PackedVector2Array([
				ship + Vector2(-820, 560), ship + Vector2(-1350, 1060),
				ship + Vector2(-1710, 1530)])},
			{"id": "center", "points": PackedVector2Array([
				ship + Vector2(-80, 760), ship + Vector2(40, 1110),
				ship + Vector2(120, 1510)])},
			{"id": "east", "points": PackedVector2Array([
				ship + Vector2(700, 560), ship + Vector2(1330, 1060),
				ship + Vector2(1710, 1510)])},
		]:
			data.paths.append({
				"id": "chart-%s-approach" % str(chart_route["id"]),
				"width": 46.0,
				"points": chart_route["points"],
			})
	elif level == 10:
		# Serra: tre anelli-habitat collegati da una nervatura centrale.
		for terrace in [
			{"id": "lower", "y": 690.0, "span": 1720.0},
			{"id": "middle", "y": 1120.0, "span": 1420.0},
			{"id": "upper", "y": 1510.0, "span": 1060.0},
		]:
			var terrace_y := float(terrace["y"])
			var span := float(terrace["span"])
			data.paths.append({
				"id": "symbiosis-%s-terrace" % str(terrace["id"]),
				"width": 58.0,
				"points": PackedVector2Array([
					ship + Vector2(-span, terrace_y), ship + Vector2(-span * 0.52, terrace_y - 150),
					ship + Vector2(0, terrace_y), ship + Vector2(span * 0.52, terrace_y - 150),
					ship + Vector2(span, terrace_y),
				]),
			})
		data.paths.append({
			"id": "symbiosis-root-spine", "width": 48.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 690), ship + Vector2(-120, 1050),
				ship + Vector2(0, 1510),
			]),
		})
	elif level == 11:
		# Città civica: decumano, cardo e piazze collegate ai servizi.
		data.paths.append({
			"id": "civic-grand-avenue", "width": 92.0,
			"points": PackedVector2Array([
				ship + Vector2(-1800, 740), ship + Vector2(-900, 740),
				ship + Vector2(0, 740), ship + Vector2(900, 740),
				ship + Vector2(1800, 740),
			]),
		})
		data.paths.append({
			"id": "civic-assembly-axis", "width": 76.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 740), ship + Vector2(0, 1080),
				ship + Vector2(0, 1450), ship + Vector2(0, 1830),
			]),
		})
		for side in [-1.0, 1.0]:
			data.paths.append({
				"id": "civic-service-%s" % ("west" if side < 0 else "east"),
				"width": 58.0,
				"points": PackedVector2Array([
					ship + Vector2(side * 900, 740), ship + Vector2(side * 1040, 1120),
					ship + Vector2(side * 1370, 1450),
				]),
			})
	elif level == 12:
		# Labirinto: circuito rettangolare e assi interni. I corridoi restano
		# percorribili, mentre i muri identitari comunicano la regola modulare.
		data.paths.append({
			"id": "rule-outer-circuit", "width": 60.0,
			"points": PackedVector2Array([
				ship + Vector2(-1450, 680), ship + Vector2(1450, 680),
				ship + Vector2(1450, 1570), ship + Vector2(-1450, 1570),
				ship + Vector2(-1450, 680),
			]),
		})
		data.paths.append({
			"id": "rule-central-axis", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 680), ship + Vector2(0, 1060),
				ship + Vector2(0, 1420), ship + Vector2(0, 1810),
			]),
		})
		for maze_cross_y in [1040.0, 1420.0]:
			data.paths.append({
				"id": "rule-cross-%d" % roundi(maze_cross_y), "width": 48.0,
				"points": PackedVector2Array([
					ship + Vector2(-1450, maze_cross_y), ship + Vector2(-620, maze_cross_y),
					ship + Vector2(0, maze_cross_y), ship + Vector2(620, maze_cross_y),
					ship + Vector2(1450, maze_cross_y),
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
	if level in [2, 3, 5, 7, 11, 12]:
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
	elif level == 6:
		data.waters = [
			{"id": "resonance-pool-west", "kind": "pond", "position": ship + Vector2(-1180, 1180), "radii": Vector2(250, 150)},
			{"id": "resonance-pool-east", "kind": "pond", "position": ship + Vector2(1180, 1050), "radii": Vector2(230, 145)},
		]
	elif level == 8:
		data.waters = [
			{"id": "circuit-west-flow", "kind": "stream", "width": 300.0, "points": PackedVector2Array([
				ship + Vector2(-1880, 360), ship + Vector2(-1540, 850),
				ship + Vector2(-1680, 1320), ship + Vector2(-1410, 1950),
			])},
			{"id": "circuit-center-flow", "kind": "stream", "width": 230.0, "points": PackedVector2Array([
				ship + Vector2(-480, 440), ship + Vector2(-620, 940),
				ship + Vector2(-420, 1480), ship + Vector2(-650, 2030),
			])},
			{"id": "circuit-east-flow", "kind": "stream", "width": 320.0, "points": PackedVector2Array([
				ship + Vector2(1820, 420), ship + Vector2(1510, 900),
				ship + Vector2(1700, 1420), ship + Vector2(1390, 1990),
			])},
		]
	elif level == 9:
		data.waters = [
			{"id": "chart-west-sea", "kind": "stream", "width": 420.0, "points": PackedVector2Array([
				ship + Vector2(-1880, 360), ship + Vector2(-1520, 860),
				ship + Vector2(-1720, 1340), ship + Vector2(-1380, 2030),
			])},
			{"id": "chart-center-sea", "kind": "stream", "width": 330.0, "points": PackedVector2Array([
				ship + Vector2(-520, 390), ship + Vector2(-720, 900),
				ship + Vector2(-480, 1400), ship + Vector2(-690, 2070),
			])},
			{"id": "chart-east-sea", "kind": "stream", "width": 390.0, "points": PackedVector2Array([
				ship + Vector2(1840, 420), ship + Vector2(1490, 890),
				ship + Vector2(1710, 1390), ship + Vector2(1370, 2010),
			])},
		]
	elif level == 10:
		data.waters = [
			{"id": "symbiosis-west-pool", "kind": "pond", "position": ship + Vector2(-1180, 1210), "radii": Vector2(260, 165)},
			{"id": "symbiosis-east-pool", "kind": "pond", "position": ship + Vector2(1180, 1050), "radii": Vector2(240, 155)},
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
	elif level == 5:
		data.identity_regions = [
			{"id": "motion-rail-yard", "kind": "motion_yard", "position": ship + Vector2(0, 720), "radii": Vector2(1700, 260), "rotation": 0.01},
			{"id": "motion-west-ramp", "kind": "motion_ramp", "position": ship + Vector2(-680, 1330), "radii": Vector2(520, 280), "rotation": -0.12},
			{"id": "motion-east-ramp", "kind": "motion_ramp", "position": ship + Vector2(1320, 1450), "radii": Vector2(430, 250), "rotation": 0.10},
		]
		data.identity_props = [
			{"kind": "motion_piston", "position": ship + Vector2(-1450, 600), "variant": 0.12},
			{"kind": "rail_switch", "position": ship + Vector2(-760, 760), "variant": 0.32},
			{"kind": "force_cart", "position": ship + Vector2(-530, 1320), "variant": 0.48},
			{"kind": "motion_piston", "position": ship + Vector2(720, 650), "variant": 0.68},
			{"kind": "rail_switch", "position": ship + Vector2(1460, 740), "variant": 0.88},
		]
	elif level == 6:
		data.identity_regions = [
			{"id": "resonance-lower-stage", "kind": "resonance_terrace", "position": ship + Vector2(-260, 720), "radii": Vector2(1480, 300), "rotation": -0.02},
			{"id": "resonance-upper-stage", "kind": "resonance_terrace", "position": ship + Vector2(0, 1390), "radii": Vector2(1050, 360), "rotation": 0.03},
			{"id": "resonance-west-grove", "kind": "resonance_grove", "position": ship + Vector2(-1280, 1260), "radii": Vector2(330, 260), "rotation": -0.08},
		]
		data.identity_props = [
			{"kind": "resonance_crystal", "position": ship + Vector2(-1510, 690), "variant": 0.10},
			{"kind": "tuning_pod", "position": ship + Vector2(-780, 610), "variant": 0.30},
			{"kind": "echo_bloom", "position": ship + Vector2(-420, 1380), "variant": 0.50},
			{"kind": "tuning_pod", "position": ship + Vector2(740, 650), "variant": 0.70},
			{"kind": "resonance_crystal", "position": ship + Vector2(1420, 780), "variant": 0.90},
		]
	elif level == 7:
		data.identity_regions = [
			{"id": "glyph-forum", "kind": "glyph_forum", "position": ship + Vector2(0, 760), "radii": Vector2(1680, 300), "rotation": 0.0},
			{"id": "glyph-west-court", "kind": "glyph_court", "position": ship + Vector2(-950, 1370), "radii": Vector2(390, 330), "rotation": -0.03},
			{"id": "glyph-east-court", "kind": "glyph_court", "position": ship + Vector2(950, 1370), "radii": Vector2(390, 330), "rotation": 0.03},
		]
		data.identity_props = [
			{"kind": "aqueduct_pillar", "position": ship + Vector2(-1500, 640), "variant": 0.12},
			{"kind": "glyph_stele", "position": ship + Vector2(-720, 790), "variant": 0.32},
			{"kind": "mosaic_brazier", "position": ship + Vector2(-920, 1320), "variant": 0.50},
			{"kind": "glyph_stele", "position": ship + Vector2(680, 780), "variant": 0.68},
			{"kind": "aqueduct_pillar", "position": ship + Vector2(1510, 650), "variant": 0.88},
		]
	elif level == 8:
		data.identity_regions = [
			{"id": "circuit-central-island", "kind": "circuit_island", "position": ship + Vector2(0, 1420), "radii": Vector2(650, 420), "rotation": 0.02},
			{"id": "circuit-west-island", "kind": "circuit_island", "position": ship + Vector2(-1160, 860), "radii": Vector2(430, 300), "rotation": -0.08},
			{"id": "circuit-east-island", "kind": "circuit_island", "position": ship + Vector2(1160, 820), "radii": Vector2(430, 300), "rotation": 0.08},
		]
		data.identity_props = [
			{"kind": "coil_tower", "position": ship + Vector2(-1450, 720), "variant": 0.12},
			{"kind": "circuit_node", "position": ship + Vector2(-820, 760), "variant": 0.32},
			{"kind": "conductor_bridge", "position": ship + Vector2(-240, 1130), "variant": 0.50},
			{"kind": "circuit_node", "position": ship + Vector2(820, 720), "variant": 0.68},
			{"kind": "coil_tower", "position": ship + Vector2(1450, 760), "variant": 0.88},
		]
	elif level == 9:
		data.identity_regions = [
			{"id": "chart-central-island", "kind": "charted_island", "position": ship + Vector2(0, 1420), "radii": Vector2(600, 390), "rotation": 0.02},
			{"id": "chart-west-island", "kind": "charted_island", "position": ship + Vector2(-1180, 840), "radii": Vector2(440, 300), "rotation": -0.10},
			{"id": "chart-east-island", "kind": "charted_island", "position": ship + Vector2(1180, 820), "radii": Vector2(440, 300), "rotation": 0.10},
		]
		data.identity_props = [
			{"kind": "route_beacon", "position": ship + Vector2(-1460, 720), "variant": 0.12},
			{"kind": "contour_plinth", "position": ship + Vector2(-790, 700), "variant": 0.31},
			{"kind": "dock_crane", "position": ship + Vector2(-260, 1160), "variant": 0.50},
			{"kind": "contour_plinth", "position": ship + Vector2(790, 690), "variant": 0.69},
			{"kind": "route_beacon", "position": ship + Vector2(1460, 730), "variant": 0.88},
		]
	elif level == 10:
		data.identity_regions = [
			{"id": "symbiosis-lower-habitat", "kind": "habitat_bed", "position": ship + Vector2(0, 720), "radii": Vector2(1500, 300), "rotation": -0.02},
			{"id": "symbiosis-upper-habitat", "kind": "habitat_bed", "position": ship + Vector2(0, 1450), "radii": Vector2(980, 370), "rotation": 0.03},
			{"id": "symbiosis-west-nursery", "kind": "greenhouse_terrace", "position": ship + Vector2(-1320, 1270), "radii": Vector2(340, 270), "rotation": -0.08},
		]
		data.identity_props = [
			{"kind": "symbiosis_pod", "position": ship + Vector2(-1480, 720), "variant": 0.12},
			{"kind": "root_arch", "position": ship + Vector2(-760, 650), "variant": 0.31},
			{"kind": "pollinator_lamp", "position": ship + Vector2(-330, 1390), "variant": 0.50},
			{"kind": "root_arch", "position": ship + Vector2(760, 660), "variant": 0.69},
			{"kind": "symbiosis_pod", "position": ship + Vector2(1460, 760), "variant": 0.88},
		]
	elif level == 11:
		data.identity_regions = [
			{"id": "civic-grand-plaza", "kind": "civic_plaza", "position": ship + Vector2(0, 760), "radii": Vector2(1660, 300), "rotation": 0.0},
			{"id": "civic-west-service", "kind": "service_court", "position": ship + Vector2(-1180, 1380), "radii": Vector2(420, 330), "rotation": -0.04},
			{"id": "civic-east-service", "kind": "service_court", "position": ship + Vector2(1180, 1380), "radii": Vector2(420, 330), "rotation": 0.04},
		]
		data.identity_props = [
			{"kind": "pact_column", "position": ship + Vector2(-1500, 650), "variant": 0.12},
			{"kind": "civic_kiosk", "position": ship + Vector2(-760, 790), "variant": 0.31},
			{"kind": "service_pavilion", "position": ship + Vector2(-1050, 1390), "variant": 0.50},
			{"kind": "civic_kiosk", "position": ship + Vector2(760, 780), "variant": 0.69},
			{"kind": "pact_column", "position": ship + Vector2(1500, 660), "variant": 0.88},
		]
	elif level == 12:
		data.identity_regions = [
			{"id": "rule-west-sector", "kind": "maze_sector", "position": ship + Vector2(-920, 1040), "radii": Vector2(520, 360), "rotation": 0.0},
			{"id": "rule-central-chamber", "kind": "logic_chamber", "position": ship + Vector2(0, 1420), "radii": Vector2(610, 420), "rotation": 0.0},
			{"id": "rule-east-sector", "kind": "maze_sector", "position": ship + Vector2(920, 1040), "radii": Vector2(520, 360), "rotation": 0.0},
		]
		data.identity_props = [
			{"kind": "moving_wall", "position": ship + Vector2(-1420, 760), "variant": 0.12},
			{"kind": "rule_node", "position": ship + Vector2(-720, 1060), "variant": 0.31},
			{"kind": "logic_gate", "position": ship + Vector2(-280, 1420), "variant": 0.50},
			{"kind": "rule_node", "position": ship + Vector2(720, 1050), "variant": 0.69},
			{"kind": "moving_wall", "position": ship + Vector2(1420, 760), "variant": 0.88},
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
	if level == 5:
		return ship + Vector2(-180, 1450)
	if level == 6:
		return ship + Vector2(0, 1400)
	if level == 7:
		return ship + Vector2(0, 1450)
	if level == 8:
		return ship + Vector2(0, 1420)
	if level == 9:
		return ship + Vector2(0, 1420)
	if level == 10:
		return ship + Vector2(0, 1400)
	if level == 11:
		return ship + Vector2(0, 1450)
	if level == 12:
		return ship + Vector2(0, 1420)
	return ship + Vector2(690, -210)
