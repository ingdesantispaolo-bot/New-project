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
	"storia": ["academy", "ruins", "geo"],
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
	elif level == 13:
		biomes = ["geo", "crystal", "ruins"]
	elif level == 14:
		biomes = ["ruins", "academy", "crystal"]
	elif level == 15:
		biomes = ["logic", "crystal", "geo"]
	elif level == 16:
		biomes = ["geo", "academy", "wild"]
	elif level == 17:
		biomes = ["geo", "crystal", "logic"]
	elif level == 18:
		biomes = ["ruins", "crystal", "academy"]
	elif level == 19:
		biomes = ["ruins", "wild", "geo"]
	elif level == 20:
		biomes = ["logic", "crystal", "geo"]
	elif level == 21:
		biomes = ["geo", "wild", "academy"]
	elif level == 22:
		biomes = ["wild", "crystal", "logic"]
	elif level == 23:
		biomes = ["ruins", "logic", "academy"]
	elif level == 24:
		# Il Cuore non appartiene più a un solo bioma: le tre famiglie visive
		# sostengono il mosaico dei dodici sistemi senza introdurre natura casuale.
		biomes = ["crystal", "logic", "ruins"]
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
		"history_threshold" if level == 11 else
		"rule_labyrinth" if level == 12 else
		"orbital_desert" if level == 13 else
		"voices_library" if level == 14 else
		"machine_city" if level == 15 else
		"language_frontier" if level == 16 else
		"force_ocean" if level == 17 else
		"sound_cathedral" if level == 18 else
		"root_necropolis" if level == 19 else
		"electromagnetic_storm" if level == 20 else
		"fractured_atlas" if level == 21 else
		"deep_biosphere" if level == 22 else
		"hall_of_eras" if level == 23 else
		"first_heart" if level == 24 else
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
		# Soglia del Tempo: una linea cronologica attraversa aree di scavo e
		# corti delle prime civiltà, mantenendo il percorso principale leggibile.
		data.paths.append({
			"id": "history-main-timeline", "width": 92.0,
			"points": PackedVector2Array([
				ship + Vector2(-1800, 740), ship + Vector2(-900, 740),
				ship + Vector2(0, 740), ship + Vector2(900, 740),
				ship + Vector2(1800, 740),
			]),
		})
		data.paths.append({
			"id": "history-source-axis", "width": 76.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 740), ship + Vector2(0, 1080),
				ship + Vector2(0, 1450), ship + Vector2(0, 1830),
			]),
		})
		for side in [-1.0, 1.0]:
			data.paths.append({
				"id": "history-excavation-%s" % ("west" if side < 0 else "east"),
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
	elif level == 13:
		# Deserto orbitale: osservatorio centrale, tre bracci di misura e due
		# archi concentrici rendono visibili angoli, frazioni e traiettorie.
		for orbital_arm in [-1.0, 0.0, 1.0]:
			data.paths.append({
				"id": "orbit-measure-arm-%d" % roundi((orbital_arm + 1.0) * 10.0),
				"width": 50.0,
				"points": PackedVector2Array([
					ship + Vector2(orbital_arm * 1480.0, 720),
					ship + Vector2(orbital_arm * 720.0, 1080),
					ship + Vector2(0, 1460),
				]),
			})
		data.paths.append({
			"id": "orbit-inner-arc", "width": 42.0,
			"points": PackedVector2Array([
				ship + Vector2(-980, 1380), ship + Vector2(-520, 1680),
				ship + Vector2(0, 1780), ship + Vector2(520, 1680),
				ship + Vector2(980, 1380),
			]),
		})
	elif level == 14:
		# Biblioteca: una spina narrativa attraversa tre camere d'eco laterali.
		data.paths.append({
			"id": "voices-story-spine", "width": 76.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 620), ship + Vector2(0, 980),
				ship + Vector2(0, 1380), ship + Vector2(0, 1830),
			]),
		})
		data.paths.append({
			"id": "voices-west-gallery", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 850), ship + Vector2(-720, 760),
				ship + Vector2(-1370, 1030), ship + Vector2(-720, 1260),
				ship + Vector2(0, 1180),
			]),
		})
		data.paths.append({
			"id": "voices-east-gallery", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 1080), ship + Vector2(720, 910),
				ship + Vector2(1390, 1190), ship + Vector2(760, 1500),
				ship + Vector2(0, 1380),
			]),
		})
	elif level == 15:
		# Città Macchina: rete ortogonale con nodi sfalsati e dorsale dati.
		for machine_lane_y in [720.0, 1120.0, 1520.0]:
			data.paths.append({
				"id": "machine-data-lane-%d" % roundi(machine_lane_y),
				"width": 54.0,
				"points": PackedVector2Array([
					ship + Vector2(-1640, machine_lane_y),
					ship + Vector2(-620, machine_lane_y),
					ship + Vector2(420, machine_lane_y),
					ship + Vector2(1640, machine_lane_y),
				]),
			})
		data.paths.append({
			"id": "machine-control-bus", "width": 66.0,
			"points": PackedVector2Array([
				ship + Vector2(-620, 620), ship + Vector2(-620, 1120),
				ship + Vector2(420, 1120), ship + Vector2(420, 1520),
				ship + Vector2(0, 1840),
			]),
		})
	elif level == 16:
		# Frontiera: un valico sinuoso attraversa tre mercati e due passaggi.
		data.paths.append({
			"id": "language-main-pass", "width": 72.0,
			"points": PackedVector2Array([
				ship + Vector2(-1700, 680), ship + Vector2(-980, 830),
				ship + Vector2(-320, 720), ship + Vector2(260, 1050),
				ship + Vector2(930, 940), ship + Vector2(1710, 1240),
			]),
		})
		data.paths.append({
			"id": "language-market-west", "width": 60.0,
			"points": PackedVector2Array([
				ship + Vector2(-980, 830), ship + Vector2(-1160, 1330),
				ship + Vector2(-620, 1630),
			]),
		})
		data.paths.append({
			"id": "language-market-east", "width": 60.0,
			"points": PackedVector2Array([
				ship + Vector2(260, 1050), ship + Vector2(520, 1460),
				ship + Vector2(1080, 1690),
			]),
		})
	elif level == 17:
		# Oceano: piattaforme collegate da tre correnti controllabili. I percorsi
		# sicuri mostrano spinta e direzione senza coprire la zona nave.
		data.paths.append({
			"id": "force-pressure-spine", "width": 64.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 620), ship + Vector2(-180, 980),
				ship + Vector2(0, 1390), ship + Vector2(0, 1840),
			]),
		})
		data.paths.append({
			"id": "force-west-current", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(-1640, 760), ship + Vector2(-980, 950),
				ship + Vector2(-420, 1320), ship + Vector2(0, 1390),
			]),
		})
		data.paths.append({
			"id": "force-east-current", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(1640, 760), ship + Vector2(1040, 1020),
				ship + Vector2(520, 1360), ship + Vector2(0, 1390),
			]),
		})
	elif level == 18:
		# Cattedrale: navata, transetto e cappelle laterali disegnano il riverbero.
		data.paths.append({
			"id": "sound-grand-nave", "width": 92.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 600), ship + Vector2(0, 980),
				ship + Vector2(0, 1420), ship + Vector2(0, 1860),
			]),
		})
		data.paths.append({
			"id": "sound-transept", "width": 76.0,
			"points": PackedVector2Array([
				ship + Vector2(-1650, 1110), ship + Vector2(-760, 1110),
				ship + Vector2(0, 1110), ship + Vector2(760, 1110),
				ship + Vector2(1650, 1110),
			]),
		})
		data.paths.append({
			"id": "sound-choir-arc", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(-1050, 1510), ship + Vector2(-520, 1710),
				ship + Vector2(0, 1810), ship + Vector2(520, 1710),
				ship + Vector2(1050, 1510),
			]),
		})
	elif level == 19:
		# Necropoli: la radice principale si ramifica verso quattro cripte.
		data.paths.append({
			"id": "root-ancestral-spine", "width": 70.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 620), ship + Vector2(-90, 1000),
				ship + Vector2(0, 1420), ship + Vector2(120, 1850),
			]),
		})
		data.paths.append({
			"id": "root-west-branch", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(-90, 1000), ship + Vector2(-720, 920),
				ship + Vector2(-1440, 1210), ship + Vector2(-1120, 1660),
			]),
		})
		data.paths.append({
			"id": "root-east-branch", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 1420), ship + Vector2(680, 1170),
				ship + Vector2(1410, 1370), ship + Vector2(1120, 1740),
			]),
		})
	elif level == 20:
		# Tempesta: triangolo di stabilizzazione e dorsali dei sensori.
		data.paths.append({
			"id": "storm-field-triangle", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(-1360, 820), ship + Vector2(0, 1540),
				ship + Vector2(1360, 820), ship + Vector2(-1360, 820),
			]),
		})
		data.paths.append({
			"id": "storm-sensor-spine", "width": 52.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 610), ship + Vector2(0, 980),
				ship + Vector2(0, 1540), ship + Vector2(0, 1880),
			]),
		})
		data.paths.append({
			"id": "storm-parallel-bus", "width": 46.0,
			"points": PackedVector2Array([
				ship + Vector2(-1600, 1210), ship + Vector2(-680, 1210),
				ship + Vector2(0, 1540), ship + Vector2(680, 1210),
				ship + Vector2(1600, 1210),
			]),
		})
	elif level == 21:
		# Atlante: quattro placche climatiche sono separate da faglie leggibili
		# e collegate da una dorsale che culmina nel pilastro tettonico.
		data.paths.append({
			"id": "atlas-tectonic-spine", "width": 68.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 610), ship + Vector2(-120, 980),
				ship + Vector2(0, 1460), ship + Vector2(140, 1870),
			]),
		})
		data.paths.append({
			"id": "atlas-west-fault", "width": 54.0,
			"points": PackedVector2Array([
				ship + Vector2(-1660, 720), ship + Vector2(-1080, 980),
				ship + Vector2(-520, 1330), ship + Vector2(0, 1460),
			]),
		})
		data.paths.append({
			"id": "atlas-east-fault", "width": 54.0,
			"points": PackedVector2Array([
				ship + Vector2(1660, 720), ship + Vector2(1080, 1020),
				ship + Vector2(520, 1330), ship + Vector2(0, 1460),
			]),
		})
	elif level == 22:
		# Biosfera: una catena energetica centrale alimenta due camere cellulari.
		data.paths.append({
			"id": "biosphere-energy-chain", "width": 66.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 620), ship + Vector2(-140, 990),
				ship + Vector2(0, 1410), ship + Vector2(0, 1860),
			]),
		})
		data.paths.append({
			"id": "biosphere-west-membrane", "width": 50.0,
			"points": PackedVector2Array([
				ship + Vector2(-1550, 820), ship + Vector2(-1020, 1080),
				ship + Vector2(-520, 1410), ship + Vector2(0, 1410),
			]),
		})
		data.paths.append({
			"id": "biosphere-east-membrane", "width": 50.0,
			"points": PackedVector2Array([
				ship + Vector2(1550, 840), ship + Vector2(1020, 1100),
				ship + Vector2(520, 1410), ship + Vector2(0, 1410),
			]),
		})
	elif level == 23:
		# Sala delle Ere: Roma e Medioevo convergono nell'archivio centrale;
		# una seconda corsia visualizza cause, conseguenze e fonti.
		data.paths.append({
			"id": "eras-chronology-axis", "width": 76.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 610), ship + Vector2(0, 1030),
				ship + Vector2(0, 1510), ship + Vector2(0, 1880),
			]),
		})
		data.paths.append({
			"id": "eras-rome-medieval-link", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(-1500, 1040), ship + Vector2(-760, 1260),
				ship + Vector2(0, 1510), ship + Vector2(760, 1260),
				ship + Vector2(1500, 1040),
			]),
		})
		data.paths.append({
			"id": "eras-sources-route", "width": 50.0,
			"points": PackedVector2Array([
				ship + Vector2(-1120, 1700), ship + Vector2(-520, 1550),
				ship + Vector2(0, 1510), ship + Vector2(520, 1550),
				ship + Vector2(1120, 1700),
			]),
		})
	elif level == 24:
		# Finale: tre firme di percorso leggibili convergono nel Cuore. I dodici
		# settori sono affidati all'underpaint e ai piloni semantici; le corsie
		# restano larghe e non trasformano la mappa in una ragnatela illeggibile.
		data.paths.append({
			"id": "heart-convergence-axis", "width": 84.0,
			"points": PackedVector2Array([
				ship + Vector2(0, 600), ship + Vector2(0, 980),
				ship + Vector2(0, 1500), ship + Vector2(0, 1980),
			]),
		})
		data.paths.append({
			"id": "heart-west-arc", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(-1680, 820), ship + Vector2(-1220, 1160),
				ship + Vector2(-720, 1430), ship + Vector2(0, 1500),
			]),
		})
		data.paths.append({
			"id": "heart-east-arc", "width": 58.0,
			"points": PackedVector2Array([
				ship + Vector2(1680, 820), ship + Vector2(1220, 1160),
				ship + Vector2(720, 1430), ship + Vector2(0, 1500),
			]),
		})
		data.paths.append({
			"id": "heart-synthesis-ring", "width": 48.0,
			"points": PackedVector2Array([
				ship + Vector2(-760, 1500), ship + Vector2(-540, 1160),
				ship + Vector2(0, 1020), ship + Vector2(540, 1160),
				ship + Vector2(760, 1500), ship + Vector2(540, 1840),
				ship + Vector2(0, 1980), ship + Vector2(-540, 1840),
				ship + Vector2(-760, 1500),
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
	if level in [2, 3, 5, 7, 11, 12, 13, 14, 15, 18, 19, 20, 21, 23, 24]:
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
	elif level == 16:
		data.waters = [{
			"id": "frontier-border-stream", "kind": "stream", "width": 240.0,
			"points": PackedVector2Array([
				ship + Vector2(-1840, 390), ship + Vector2(-1480, 920),
				ship + Vector2(-1600, 1450), ship + Vector2(-1280, 2050),
			]),
		}]
	elif level == 17:
		data.waters = [
			{"id": "force-west-abyss", "kind": "stream", "width": 480.0, "points": PackedVector2Array([
				ship + Vector2(-1900, 380), ship + Vector2(-1500, 920),
				ship + Vector2(-1740, 1450), ship + Vector2(-1320, 2080),
			])},
			{"id": "force-center-abyss", "kind": "stream", "width": 330.0, "points": PackedVector2Array([
				ship + Vector2(-560, 420), ship + Vector2(-720, 900),
				ship + Vector2(-520, 1420), ship + Vector2(-710, 2070),
			])},
			{"id": "force-east-abyss", "kind": "stream", "width": 450.0, "points": PackedVector2Array([
				ship + Vector2(1900, 400), ship + Vector2(1510, 930),
				ship + Vector2(1740, 1440), ship + Vector2(1320, 2070),
			])},
		]
	elif level == 22:
		data.waters = [{
			"id": "biosphere-luminous-flow", "kind": "stream", "width": 250.0,
			"points": PackedVector2Array([
				ship + Vector2(-1840, 420), ship + Vector2(-1480, 900),
				ship + Vector2(-1580, 1430), ship + Vector2(-1260, 2050),
			]),
		}]
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
			{"id": "history-chronology-plaza", "kind": "chronology_plaza", "position": ship + Vector2(0, 760), "radii": Vector2(1660, 300), "rotation": 0.0},
			{"id": "history-west-excavation", "kind": "excavation_court", "position": ship + Vector2(-1180, 1380), "radii": Vector2(420, 330), "rotation": -0.04},
			{"id": "history-east-archive", "kind": "source_archive", "position": ship + Vector2(1180, 1380), "radii": Vector2(420, 330), "rotation": 0.04},
		]
		data.identity_props = [
			{"kind": "source_stele", "position": ship + Vector2(-1500, 650), "variant": 0.12},
			{"kind": "timeline_relay", "position": ship + Vector2(-760, 790), "variant": 0.31},
			{"kind": "artifact_table", "position": ship + Vector2(-1050, 1390), "variant": 0.50},
			{"kind": "timeline_relay", "position": ship + Vector2(760, 780), "variant": 0.69},
			{"kind": "source_stele", "position": ship + Vector2(1500, 660), "variant": 0.88},
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
	elif level == 13:
		data.identity_regions = [
			{"id": "orbit-central-pad", "kind": "observatory_pad", "position": ship + Vector2(0, 1460), "radii": Vector2(650, 420), "rotation": 0.0},
			{"id": "orbit-west-dune", "kind": "orbit_dune", "position": ship + Vector2(-1120, 980), "radii": Vector2(470, 300), "rotation": -0.10},
			{"id": "orbit-east-dune", "kind": "orbit_dune", "position": ship + Vector2(1120, 980), "radii": Vector2(470, 300), "rotation": 0.10},
		]
		data.identity_props = [
			{"kind": "trajectory_pylon", "position": ship + Vector2(-1450, 730), "variant": 0.12},
			{"kind": "fraction_dial", "position": ship + Vector2(-760, 1050), "variant": 0.31},
			{"kind": "orbit_scope", "position": ship + Vector2(-260, 1440), "variant": 0.50},
			{"kind": "fraction_dial", "position": ship + Vector2(760, 1050), "variant": 0.69},
			{"kind": "trajectory_pylon", "position": ship + Vector2(1450, 730), "variant": 0.88},
		]
	elif level == 14:
		data.identity_regions = [
			{"id": "voices-central-gallery", "kind": "narrative_gallery", "position": ship + Vector2(0, 1220), "radii": Vector2(620, 520), "rotation": 0.0},
			{"id": "voices-west-chamber", "kind": "echo_chamber", "position": ship + Vector2(-1080, 1020), "radii": Vector2(470, 330), "rotation": -0.05},
			{"id": "voices-east-chamber", "kind": "echo_chamber", "position": ship + Vector2(1080, 1190), "radii": Vector2(470, 330), "rotation": 0.05},
		]
		data.identity_props = [
			{"kind": "voice_shelf", "position": ship + Vector2(-1440, 730), "variant": 0.12},
			{"kind": "echo_lectern", "position": ship + Vector2(-720, 980), "variant": 0.31},
			{"kind": "memory_lantern", "position": ship + Vector2(0, 1460), "variant": 0.50},
			{"kind": "echo_lectern", "position": ship + Vector2(720, 1110), "variant": 0.69},
			{"kind": "voice_shelf", "position": ship + Vector2(1440, 820), "variant": 0.88},
		]
	elif level == 15:
		data.identity_regions = [
			{"id": "machine-control-grid", "kind": "machine_grid", "position": ship + Vector2(0, 1120), "radii": Vector2(1640, 500), "rotation": 0.0},
			{"id": "machine-west-yard", "kind": "automaton_yard", "position": ship + Vector2(-1080, 1570), "radii": Vector2(430, 300), "rotation": 0.0},
			{"id": "machine-east-yard", "kind": "automaton_yard", "position": ship + Vector2(1080, 1570), "radii": Vector2(430, 300), "rotation": 0.0},
		]
		data.identity_props = [
			{"kind": "data_relay", "position": ship + Vector2(-1480, 720), "variant": 0.12},
			{"kind": "automaton_station", "position": ship + Vector2(-720, 1120), "variant": 0.31},
			{"kind": "debug_console", "position": ship + Vector2(0, 1510), "variant": 0.50},
			{"kind": "automaton_station", "position": ship + Vector2(720, 1120), "variant": 0.69},
			{"kind": "data_relay", "position": ship + Vector2(1480, 720), "variant": 0.88},
		]
	elif level == 16:
		data.identity_regions = [
			{"id": "frontier-west-market", "kind": "border_market", "position": ship + Vector2(-1050, 1280), "radii": Vector2(520, 360), "rotation": -0.06},
			{"id": "frontier-central-pass", "kind": "language_pass", "position": ship + Vector2(120, 1050), "radii": Vector2(560, 340), "rotation": 0.08},
			{"id": "frontier-east-market", "kind": "border_market", "position": ship + Vector2(1050, 1510), "radii": Vector2(520, 360), "rotation": 0.05},
		]
		data.identity_props = [
			{"kind": "passage_beacon", "position": ship + Vector2(-1460, 700), "variant": 0.12},
			{"kind": "market_stall", "position": ship + Vector2(-920, 1260), "variant": 0.31},
			{"kind": "connector_arch", "position": ship + Vector2(120, 1040), "variant": 0.50},
			{"kind": "market_stall", "position": ship + Vector2(920, 1480), "variant": 0.69},
			{"kind": "passage_beacon", "position": ship + Vector2(1480, 1240), "variant": 0.88},
		]
	elif level == 17:
		data.identity_regions = [
			{"id": "force-central-platform", "kind": "pressure_platform", "position": ship + Vector2(0, 1460), "radii": Vector2(650, 420), "rotation": 0.0},
			{"id": "force-west-shelf", "kind": "abyss_shelf", "position": ship + Vector2(-1130, 940), "radii": Vector2(430, 300), "rotation": -0.08},
			{"id": "force-east-shelf", "kind": "abyss_shelf", "position": ship + Vector2(1130, 980), "radii": Vector2(430, 300), "rotation": 0.08},
		]
		data.identity_props = [
			{"kind": "pressure_buoy", "position": ship + Vector2(-1460, 730), "variant": 0.12},
			{"kind": "current_vane", "position": ship + Vector2(-760, 1040), "variant": 0.31},
			{"kind": "ballast_station", "position": ship + Vector2(0, 1460), "variant": 0.50},
			{"kind": "current_vane", "position": ship + Vector2(760, 1060), "variant": 0.69},
			{"kind": "pressure_buoy", "position": ship + Vector2(1460, 730), "variant": 0.88},
		]
	elif level == 18:
		data.identity_regions = [
			{"id": "sound-central-nave", "kind": "sound_nave", "position": ship + Vector2(0, 1220), "radii": Vector2(620, 620), "rotation": 0.0},
			{"id": "sound-west-chapel", "kind": "resonance_chapel", "position": ship + Vector2(-1120, 1120), "radii": Vector2(430, 340), "rotation": -0.04},
			{"id": "sound-east-chapel", "kind": "resonance_chapel", "position": ship + Vector2(1120, 1120), "radii": Vector2(430, 340), "rotation": 0.04},
		]
		data.identity_props = [
			{"kind": "organ_pipe", "position": ship + Vector2(-1450, 720), "variant": 0.12},
			{"kind": "harmony_arch", "position": ship + Vector2(-720, 1100), "variant": 0.31},
			{"kind": "timbre_resonator", "position": ship + Vector2(0, 1510), "variant": 0.50},
			{"kind": "harmony_arch", "position": ship + Vector2(720, 1100), "variant": 0.69},
			{"kind": "organ_pipe", "position": ship + Vector2(1450, 720), "variant": 0.88},
		]
	elif level == 19:
		data.identity_regions = [
			{"id": "root-central-archive", "kind": "etymology_archive", "position": ship + Vector2(0, 1460), "radii": Vector2(610, 440), "rotation": 0.0},
			{"id": "root-west-crypt", "kind": "root_crypt", "position": ship + Vector2(-1120, 1180), "radii": Vector2(470, 340), "rotation": -0.05},
			{"id": "root-east-crypt", "kind": "root_crypt", "position": ship + Vector2(1120, 1320), "radii": Vector2(470, 340), "rotation": 0.05},
		]
		data.identity_props = [
			{"kind": "root_obelisk", "position": ship + Vector2(-1450, 720), "variant": 0.12},
			{"kind": "lineage_tablet", "position": ship + Vector2(-720, 1110), "variant": 0.31},
			{"kind": "crypt_lantern", "position": ship + Vector2(0, 1460), "variant": 0.50},
			{"kind": "lineage_tablet", "position": ship + Vector2(720, 1240), "variant": 0.69},
			{"kind": "root_obelisk", "position": ship + Vector2(1450, 780), "variant": 0.88},
		]
	elif level == 20:
		data.identity_regions = [
			{"id": "storm-central-array", "kind": "sensor_array", "position": ship + Vector2(0, 1510), "radii": Vector2(650, 430), "rotation": 0.0},
			{"id": "storm-west-sector", "kind": "field_sector", "position": ship + Vector2(-1120, 1030), "radii": Vector2(470, 330), "rotation": -0.06},
			{"id": "storm-east-sector", "kind": "field_sector", "position": ship + Vector2(1120, 1030), "radii": Vector2(470, 330), "rotation": 0.06},
		]
		data.identity_props = [
			{"kind": "field_tower", "position": ship + Vector2(-1450, 730), "variant": 0.12},
			{"kind": "sensor_probe", "position": ship + Vector2(-720, 1060), "variant": 0.31},
			{"kind": "surge_grounder", "position": ship + Vector2(0, 1510), "variant": 0.50},
			{"kind": "sensor_probe", "position": ship + Vector2(720, 1060), "variant": 0.69},
			{"kind": "field_tower", "position": ship + Vector2(1450, 730), "variant": 0.88},
		]
	elif level == 21:
		data.identity_regions = [
			{"id": "atlas-central-plate", "kind": "climate_plate", "position": ship + Vector2(0, 1460), "radii": Vector2(640, 430), "rotation": 0.0},
			{"id": "atlas-west-basin", "kind": "settlement_basin", "position": ship + Vector2(-1120, 1040), "radii": Vector2(470, 330), "rotation": -0.08},
			{"id": "atlas-east-basin", "kind": "settlement_basin", "position": ship + Vector2(1120, 1080), "radii": Vector2(470, 330), "rotation": 0.08},
		]
		data.identity_props = [
			{"kind": "climate_beacon", "position": ship + Vector2(-1460, 720), "variant": 0.12},
			{"kind": "fault_marker", "position": ship + Vector2(-720, 1050), "variant": 0.31},
			{"kind": "terrain_model", "position": ship + Vector2(0, 1460), "variant": 0.50},
			{"kind": "fault_marker", "position": ship + Vector2(720, 1080), "variant": 0.69},
			{"kind": "climate_beacon", "position": ship + Vector2(1460, 740), "variant": 0.88},
		]
	elif level == 22:
		data.identity_regions = [
			{"id": "biosphere-central-cell", "kind": "cell_cavern", "position": ship + Vector2(0, 1460), "radii": Vector2(650, 440), "rotation": 0.0},
			{"id": "biosphere-west-chain", "kind": "energy_chain", "position": ship + Vector2(-1120, 1080), "radii": Vector2(470, 340), "rotation": -0.06},
			{"id": "biosphere-east-chain", "kind": "energy_chain", "position": ship + Vector2(1120, 1120), "radii": Vector2(470, 340), "rotation": 0.06},
		]
		data.identity_props = [
			{"kind": "cell_pod", "position": ship + Vector2(-1450, 730), "variant": 0.12},
			{"kind": "energy_vein", "position": ship + Vector2(-720, 1080), "variant": 0.31},
			{"kind": "adaptation_spore", "position": ship + Vector2(0, 1460), "variant": 0.50},
			{"kind": "energy_vein", "position": ship + Vector2(720, 1120), "variant": 0.69},
			{"kind": "cell_pod", "position": ship + Vector2(1450, 760), "variant": 0.88},
		]
	elif level == 23:
		data.identity_regions = [
			{"id": "eras-central-archive", "kind": "era_archive", "position": ship + Vector2(0, 1510), "radii": Vector2(650, 430), "rotation": 0.0},
			{"id": "eras-roman-wing", "kind": "roman_archive", "position": ship + Vector2(-1120, 1120), "radii": Vector2(470, 340), "rotation": -0.04},
			{"id": "eras-medieval-wing", "kind": "medieval_archive", "position": ship + Vector2(1120, 1120), "radii": Vector2(470, 340), "rotation": 0.04},
		]
		data.identity_props = [
			{"kind": "roman_archive_pod", "position": ship + Vector2(-1450, 730), "variant": 0.12},
			{"kind": "causality_terminal", "position": ship + Vector2(-720, 1110), "variant": 0.31},
			{"kind": "era_beacon", "position": ship + Vector2(0, 1510), "variant": 0.50},
			{"kind": "causality_terminal", "position": ship + Vector2(720, 1110), "variant": 0.69},
			{"kind": "medieval_archive_pod", "position": ship + Vector2(1450, 730), "variant": 0.88},
		]
	elif level == 24:
		var heart_center := ship + Vector2(0, 1500)
		data.identity_regions = [{
			"id": "heart-convergence-core", "kind": "system_convergence",
			"position": heart_center, "radii": Vector2(720, 510), "rotation": 0.0,
		}]
		data.identity_props = [
			{"kind": "synthesis_anchor", "position": heart_center + Vector2(0, 470), "variant": 0.5},
			{"kind": "convergence_relay", "position": heart_center + Vector2(-520, 0), "variant": 0.2},
			{"kind": "convergence_relay", "position": heart_center + Vector2(520, 0), "variant": 0.8},
		]
		for sector_index in 12:
			var angle := -PI * 0.5 + TAU * float(sector_index) / 12.0
			var sector_offset := Vector2(cos(angle) * 1260.0, sin(angle) * 720.0)
			data.identity_regions.append({
				"id": "heart-system-sector-%02d" % (sector_index + 1),
				"kind": "system_sector",
				"position": heart_center + sector_offset,
				"radii": Vector2(340, 230),
				"rotation": angle,
				"variant": float(sector_index) / 11.0,
			})
			data.identity_props.append({
				"kind": "system_pylon",
				"position": heart_center + sector_offset * 0.78,
				"variant": float(sector_index) / 11.0,
				"systemIndex": sector_index,
			})

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
	_author_passages(data, spawn, ship)
	_author_activity_sockets(data, profile, spawn, ship)
	# Mantiene il seed semanticamente visibile negli strumenti di debug senza
	# usarlo per prendere decisioni didattiche.
	data.seed = "%s::%s" % [seed, profile_id]
	return data

## Costruisce una grammatica di LUOGHI sopra la composizione gia' autorata.
##
## Non crea coordinate indipendenti dal mondo: promuove regioni, strumenti,
## landmark, sentieri e varchi gia' presenti a possibili sedi di attivita'. In
## questo modo l'Archivio propone prove presso scaffali e sale, il Cratere presso
## macchine e terrazze, la Serra presso habitat e pod, senza scrivere ventiquattro
## tabelle parallele destinate a divergere dall'arte.
static func _author_activity_sockets(
	data: WorldCompositionData, profile: Dictionary, spawn: Vector2, ship: Vector2
) -> void:
	var sockets: Array = []
	var half_extent := float(profile.get("worldHalfExtent", 2200.0))
	var reach := float(profile.get("eventPools", {}).get("reachRadius", 1900.0))

	for region_data in data.identity_regions:
		var region: Dictionary = region_data
		var region_id := str(region.get("id", "region-%d" % sockets.size()))
		var kind := str(region.get("kind", "region"))
		var position: Vector2 = region.get("position", spawn)
		sockets.append(_activity_socket(
			"site-%s" % region_id, position, "region",
			_activity_tags(kind, "region"), region_id, 3,
			_route_depth(spawn, position, reach), "distant_signal"))

	for prop_index in range(data.identity_props.size()):
		var prop: Dictionary = data.identity_props[prop_index]
		var kind := str(prop.get("kind", "instrument"))
		var position: Vector2 = prop.get("position", spawn)
		var cluster := _nearest_region_id(data.identity_regions, position)
		sockets.append(_activity_socket(
			"instrument-%s-%d" % [kind, prop_index], position, "instrument",
			_activity_tags(kind, "instrument"), cluster, 2,
			_route_depth(spawn, position, reach), "local_clue"))

	for pocket_data in data.hero_pockets:
		var pocket: Dictionary = pocket_data
		if str(pocket.get("id", "")) != "hero-landmark":
			continue
		var position: Vector2 = pocket.get("position", spawn)
		sockets.append(_activity_socket(
			"site-hero-landmark", position, "landmark",
			["landmark", "mystery", "archive", "observation", "climax"],
			"hero-landmark", 3, _route_depth(spawn, position, reach),
			"distant_signal"))

	for crossing_index in range(data.crossings.size()):
		var crossing: Dictionary = data.crossings[crossing_index]
		var position: Vector2 = crossing.get("approach", crossing.get("position", spawn))
		sockets.append(_activity_socket(
			"site-%s" % str(crossing.get("id", "crossing-%d" % crossing_index)),
			position, "crossing",
			["crossing", "traversal", "mystery", "ordering", "measurement"],
			"passage-%d" % crossing_index, 1,
			_route_depth(spawn, position, reach), "distant_signal"))

	# I sentieri sono il tessuto connettivo fra le costellazioni. Un solo punto
	# per tracciato basta: i siti identitari restano i protagonisti, mentre questi
	# socket garantiscono un appoggio leggibile anche a profili con poche regioni.
	for path_index in range(data.paths.size()):
		var path: Dictionary = data.paths[path_index]
		var points: PackedVector2Array = path.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var middle_index := clampi(floori(float(points.size() - 1) * 0.58), 0, points.size() - 2)
		var position := points[middle_index].lerp(points[middle_index + 1], 0.5)
		# Nessun socket dentro la zona nave: quel tratto deve restare respiro e
		# orientamento, non una bacheca di esercizi appena atterrati.
		if position.distance_to(ship) < float(profile.get("shipEntrance", {}).get("safeRadius", 340.0)) + 120.0:
			continue
		var path_id := str(path.get("id", "path-%d" % path_index))
		sockets.append(_activity_socket(
			"trail-%s" % path_id, position, "trail",
			["route", "ordering", "observation", "navigation"],
			_nearest_region_id(data.identity_regions, position), 2,
			_route_depth(spawn, position, reach), "proximity"))

	# La composizione puo' oltrepassare lievemente il rettangolo giocabile con
	# underpaint e acqua. I luoghi interattivi, invece, devono restarci dentro.
	for socket_data in sockets:
		var socket: Dictionary = socket_data
		var position: Vector2 = socket["position"]
		position.x = clampf(position.x, ship.x - half_extent, ship.x + half_extent)
		position.y = clampf(position.y, ship.y - half_extent, ship.y + half_extent)
		socket["position"] = position
		data.activity_sockets.append(socket)

static func _activity_socket(
	id: String, position: Vector2, role: String, tags: Array, cluster: String,
	capacity: int, route_depth: float, visibility: String
) -> Dictionary:
	return {
		"id": id,
		"position": position,
		"role": role,
		"tags": tags.duplicate(),
		"cluster": cluster if not cluster.is_empty() else id,
		"capacity": maxi(1, capacity),
		"routeDepth": clampf(route_depth, 0.0, 1.5),
		"visibility": visibility,
	}

static func _route_depth(spawn: Vector2, position: Vector2, reach: float) -> float:
	return spawn.distance_to(position) / maxf(1.0, reach)

static func _nearest_region_id(regions: Array, position: Vector2) -> String:
	var best_id := "open-route"
	var best_distance := INF
	for region_data in regions:
		var region: Dictionary = region_data
		var center: Vector2 = region.get("position", position)
		var distance := position.distance_squared_to(center)
		if distance < best_distance:
			best_distance = distance
			best_id = str(region.get("id", best_id))
	return best_id

## Traduce il nome visivo di una regione/prop in affordance di gioco. Sono tag
## larghi, non contenuto didattico: un `sensor_probe` sa ospitare misure e grafici,
## ma non decide domanda, risposta, materia o ricompensa.
static func _activity_tags(kind: String, role: String) -> Array:
	var key := kind.to_lower()
	var tags: Array = [role, "observation"]
	if _has_any(key, ["archive", "shelf", "glyph", "stele", "tablet", "source", "voice", "root", "mosaic", "era"]):
		tags.append_array(["archive", "matching", "classification", "language", "history"])
	if _has_any(key, ["machine", "node", "piston", "rail", "circuit", "coil", "relay", "automaton", "debug", "sensor", "energy", "field", "conductor", "gate", "wall"]):
		tags.append_array(["machine", "circuit", "ordering", "sequence", "measurement"])
	if _has_any(key, ["garden", "bloom", "pod", "cell", "spore", "habitat", "symbiosis", "nursery", "bio"]):
		tags.append_array(["living", "classification", "cycle", "matching"])
	if _has_any(key, ["beacon", "buoy", "mast", "route", "contour", "map", "climate", "trajectory", "orbit", "dock"]):
		tags.append_array(["navigation", "graph", "measurement", "matching"])
	if _has_any(key, ["resonance", "tuning", "echo", "organ", "harmony", "timbre", "sound"]):
		tags.append_array(["sound", "matching", "ordering", "sequence"])
	if _has_any(key, ["plaza", "market", "forum", "courtyard", "harbour", "yard"]):
		tags.append_array(["social", "classification", "worksite"])
	if _has_any(key, ["crater", "dune", "terrace", "island", "basin", "sector", "cavern", "crypt", "chamber"]):
		tags.append_array(["field", "exploration", "measurement"])
	return _unique_strings(tags)

static func _has_any(value: String, needles: Array) -> bool:
	for needle_data in needles:
		if value.contains(str(needle_data)):
			return true
	return false

static func _unique_strings(values: Array) -> Array:
	var out: Array = []
	for value_data in values:
		var value := str(value_data)
		if not out.has(value):
			out.append(value)
	return out

## Sceglie il corso d'acqua più vicino all'asse della nave (i canali esterni
## restano confini naturali) e vi definisce un solo varco costruibile. La scena
## lega il varco al primo enigma senza spostare missioni obbligatorie.
## **Piu' di un guado per mondo.** (6 agosto 2026)
##
## Fino a oggi `data.crossings` era un array di UN elemento: la meccanica piu'
## interessante che il gioco possiede — una prova che apre fisicamente una parte
## di mappa — accadeva una volta per mondo, e il resto del girovagare era solo
## un modo di raggiungere gli esercizi.
##
## Ora si sceglie fino a tre torrenti, ordinati per vicinanza alla rotta della
## nave: il primo resta esattamente dov'era (nessun mondo cambia forma), gli
## altri aggiungono passaggi da aprire. Tre e non di piu': ogni guado chiuso e'
## una strada in meno, e una mappa con sei sbarramenti non e' da esplorare, e'
## da subire.
const GUADI_MAX := 3

static func _author_stream_crossing(data: WorldCompositionData, spawn: Vector2, ship: Vector2) -> void:
	var candidati: Array = []
	for water_data in data.waters:
		var water: Dictionary = water_data
		if str(water.get("kind", "")) != "stream":
			continue
		var points_c: PackedVector2Array = water.get("points", PackedVector2Array())
		if points_c.size() < 2:
			continue
		var middle := points_c[floori(float(points_c.size()) * 0.5)]
		var distance := absf(middle.x - ship.x) + absf(middle.y - (ship.y + 1100.0)) * 0.18
		candidati.append({"water": water, "d": distance})
	if candidati.is_empty():
		return
	# Ordine per vicinanza, stabile: il primo guado resta quello di sempre.
	candidati.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	for indice in range(mini(GUADI_MAX, candidati.size())):
		_author_single_crossing(data, spawn, Dictionary(candidati[indice])["water"], indice)

## **Sbarramenti di terra, per i mondi senza acqua.** (7 agosto 2026)
##
## Misurato: **diciotto mondi su ventiquattro non hanno torrenti**, quindi non
## avevano nessun passaggio da aprire. La meccanica piu' interessante del gioco —
## una prova che apre fisicamente una parte di mappa — viveva in sei mondi.
##
## Un guado senza acqua non esiste, ma uno SBARRAMENTO si': una frana, un
## cancello, una parete. Entra nella stessa struttura `crossings`, con
## `kind: "barrier"`, cosi' l'enigma ci si aggancia esattamente come faceva con
## l'acqua e nessuna riga a monte cambia.
##
## **Non chiude mai una strada, la allunga.** Il muro e' un segmento, non un
## anello: si puo' sempre girargli attorno. Aprirlo e' una scorciatoia, non un
## permesso — ed e' l'unico modo di rispettare la regola di tutta la mappa,
## niente che sta qui puo' fermare la progressione. Un muro che chiude davvero
## rischierebbe di isolare un POI del gate, e nessun collaudo lo scoprirebbe
## prima di un bambino.
const SBARRAMENTO_META_LARGHEZZA := 150.0

static func _author_land_barriers(data: WorldCompositionData, spawn: Vector2, ship: Vector2) -> void:
	if not data.crossings.is_empty():
		return   # dove c'e' l'acqua comanda l'acqua
	var verso := (ship - spawn)
	if verso.length() < 1.0:
		verso = Vector2.UP
	verso = verso.normalized()
	var etichette := ["la frana", "il cancello dei Primi", "la parete incisa"]
	for indice in range(GUADI_MAX):
		# Distribuiti lungo la rotta spawn->nave, a distanze diverse e con una
		# rotazione: tre muri in fila sullo stesso raggio sarebbero un corridoio.
		var direzione := verso.rotated(deg_to_rad(-34.0 + 34.0 * float(indice)))
		var centro := spawn + direzione * (760.0 + 330.0 * float(indice))
		if data.is_protected(centro, 90.0):
			continue
		if data.raw_water_weight(centro) >= 0.4:
			continue
		var tangente := Vector2(-direzione.y, direzione.x)
		data.crossings.append({
			"id": "barrier-%d" % indice,
			"kind": "barrier",
			"label": str(etichette[indice % etichette.size()]),
			"waterId": "",
			"position": centro,
			"approach": centro - direzione * 130.0,
			"tangent": tangente,
			"normal": direzione,
			"halfWidth": SBARRAMENTO_META_LARGHEZZA,
			"eventId": "",
		})

## Chiama gli sbarramenti dopo i guadi: se l'acqua c'e', vince l'acqua.
static func _author_passages(data: WorldCompositionData, spawn: Vector2, ship: Vector2) -> void:
	_author_stream_crossing(data, spawn, ship)
	_author_land_barriers(data, spawn, ship)

static func _author_single_crossing(
	data: WorldCompositionData, spawn: Vector2, selected: Dictionary, indice: int
) -> void:
	var points: PackedVector2Array = selected.get("points", PackedVector2Array())
	var segment := clampi(floori(float(points.size() - 1) * 0.5), 0, points.size() - 2)
	var a := points[segment]
	var b := points[segment + 1]
	var center := a.lerp(b, 0.5)
	var tangent := (b - a).normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	var half_width := float(selected.get("width", 200.0)) * 0.5
	var bank_a := center + normal * (half_width + 62.0)
	var bank_b := center - normal * (half_width + 62.0)
	var approach := bank_a if spawn.distance_to(bank_a) <= spawn.distance_to(bank_b) else bank_b
	if approach == bank_b:
		normal = -normal
	data.crossings.append({
		"id": "%s-crossing-%d" % [str(selected.get("id", "stream")), indice],
		"waterId": str(selected.get("id", "stream")),
		"position": center,
		"approach": approach,
		"tangent": tangent,
		"normal": normal,
		"halfWidth": half_width,
		"eventId": "",
	})

static func _profile_hero_position(ship: Vector2, level: int) -> Vector2:
	if level == 1:
		return ship + Vector2(160, 1050)
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
	if level == 13:
		return ship + Vector2(0, 1460)
	if level == 14:
		return ship + Vector2(0, 1500)
	if level == 15:
		return ship + Vector2(0, 1510)
	if level == 16:
		return ship + Vector2(120, 1520)
	if level == 17:
		return ship + Vector2(0, 1460)
	if level == 18:
		return ship + Vector2(0, 1510)
	if level == 19:
		return ship + Vector2(0, 1460)
	if level == 20:
		return ship + Vector2(0, 1510)
	if level == 21:
		return ship + Vector2(0, 1460)
	if level == 22:
		return ship + Vector2(0, 1460)
	if level == 23:
		return ship + Vector2(0, 1510)
	if level == 24:
		# Il root è alla base del landmark; il centro dell'arte cade sul nucleo
		# autorato dell'underpaint (y=1500).
		return ship + Vector2(0, 1690)
	return ship + Vector2(690, -210)
