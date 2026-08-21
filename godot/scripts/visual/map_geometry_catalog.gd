class_name MapGeometryCatalog
extends RefCounted

## Atlante vettoriale condiviso per le carte mute. I contenuti nominano una
## `mapId` e bersagli semantici; coordinate, proiezione e hit-area restano nel
## runtime. Nessun testo e nessuna risposta didattica vivono qui.
##
## Geometria Italia derivata dai dataset public domain Natural Earth:
## - ne_110m_admin_0_countries (costa e isole)
## - ne_50m_rivers_lake_centerlines (Po, semplificato 1 punto ogni 3)
## Fonte: https://www.naturalearthdata.com/ — acquisita il 2026-08-03.

const ITALY_BOUNDS := Rect2(6.40, 36.30, 12.50, 11.20)
## Natural Earth 5.1.1, Admin 0 Countries (public domain), acquisito il
## 2026-08-21 e semplificato per una carta muta a schermo intero.
const EUROPE_BOUNDS := Rect2(-25.0, 34.0, 70.0, 39.0)

static func has_map(map_id: String) -> bool:
	return map_id in ["italy", "europe"]

static func target_ids(map_id: String) -> Array:
	return Array(map_data(map_id).get("targets", {}).keys())

static func map_data(map_id: String) -> Dictionary:
	if map_id == "europe":
		return _europe_data()
	if map_id != "italy": return {}
	return {
		"bounds": ITALY_BOUNDS,
		"polygons": [
			PackedVector2Array([
				Vector2(10.44270, 46.89355), Vector2(11.04856, 46.75136),
				Vector2(11.16483, 46.94158), Vector2(12.15309, 47.11539),
				Vector2(12.37649, 46.76756), Vector2(13.80648, 46.50931),
				Vector2(13.69811, 46.01678), Vector2(13.93763, 45.59102),
				Vector2(13.14161, 45.73669), Vector2(12.32858, 45.38178),
				Vector2(12.38387, 44.88537), Vector2(12.26145, 44.60048),
				Vector2(12.58924, 44.09137), Vector2(13.52691, 43.58773),
				Vector2(14.02982, 42.76101), Vector2(15.14257, 41.95514),
				Vector2(15.92619, 41.96131), Vector2(16.16990, 41.74030),
				Vector2(15.88935, 41.54108), Vector2(16.78500, 41.17961),
				Vector2(17.51917, 40.87714), Vector2(18.37669, 40.35563),
				Vector2(18.48025, 40.16887), Vector2(18.29339, 39.81077),
				Vector2(17.73838, 40.27767), Vector2(16.86960, 40.44223),
				Vector2(16.44874, 39.79540), Vector2(17.17149, 39.42470),
				Vector2(17.05284, 38.90287), Vector2(16.63509, 38.84357),
				Vector2(16.10096, 37.98590), Vector2(15.68409, 37.90885),
				Vector2(15.68796, 38.21459), Vector2(15.89198, 38.75094),
				Vector2(16.10933, 38.96455), Vector2(15.71881, 39.54407),
				Vector2(15.41361, 40.04836), Vector2(14.99850, 40.17295),
				Vector2(14.70327, 40.60455), Vector2(14.06067, 40.78635),
				Vector2(13.62799, 41.18829), Vector2(12.88808, 41.25309),
				Vector2(12.10668, 41.70453), Vector2(11.19191, 42.35542),
				Vector2(10.51195, 42.93146), Vector2(10.20003, 43.92001),
				Vector2(9.70249, 44.03628), Vector2(8.88895, 44.36634),
				Vector2(8.42856, 44.23123), Vector2(7.85077, 43.76715),
				Vector2(7.43518, 43.69385), Vector2(7.54960, 44.12790),
				Vector2(7.00756, 44.25477), Vector2(6.74995, 45.02852),
				Vector2(7.09665, 45.33310), Vector2(6.80236, 45.70858),
				Vector2(6.84359, 45.99115), Vector2(7.27385, 45.77695),
				Vector2(7.75599, 45.82449), Vector2(8.31663, 46.16364),
				Vector2(8.48995, 46.00515), Vector2(8.96631, 46.03693),
				Vector2(9.18288, 46.44022), Vector2(9.92284, 46.31490),
				Vector2(10.36338, 46.48357), Vector2(10.44270, 46.89355),
			]),
			PackedVector2Array([
				Vector2(14.76125, 38.14387), Vector2(15.52038, 38.23116),
				Vector2(15.16024, 37.44405), Vector2(15.30990, 37.13422),
				Vector2(15.09999, 36.61999), Vector2(14.33523, 36.99663),
				Vector2(13.82673, 37.10453), Vector2(12.43100, 37.61295),
				Vector2(12.57094, 38.12638), Vector2(13.74116, 38.03497),
				Vector2(14.76125, 38.14387),
			]),
			PackedVector2Array([
				Vector2(8.70999, 40.89998), Vector2(9.21001, 41.20999),
				Vector2(9.80997, 40.50001), Vector2(9.66952, 39.17738),
				Vector2(9.21482, 39.24047), Vector2(8.80694, 38.90662),
				Vector2(8.42830, 39.17185), Vector2(8.38825, 40.37831),
				Vector2(8.16000, 40.95001), Vector2(8.70999, 40.89998),
			]),
		],
		"lines": {
			"po": PackedVector2Array([
				Vector2(7.11019, 44.70600), Vector2(7.50180, 44.79453),
				Vector2(7.67750, 45.04074), Vector2(7.97588, 45.21977),
				Vector2(8.49967, 45.16107), Vector2(8.80776, 45.05361),
				Vector2(9.50498, 45.09337), Vector2(9.65190, 45.11430),
				Vector2(9.75385, 45.10402), Vector2(9.84584, 45.08459),
				Vector2(9.96046, 45.12991), Vector2(10.15352, 45.02583),
				Vector2(10.49061, 44.93480), Vector2(10.66600, 44.98614),
				Vector2(10.87069, 45.07224), Vector2(11.31242, 45.02896),
				Vector2(11.57447, 44.90558), Vector2(12.08498, 45.01989),
				Vector2(12.37716, 44.96069), Vector2(12.52340, 44.96795),
			]),
		},
		# Ancore geografiche, mai pixel/percentuali UI. Il renderer decide la
		# proiezione e il target touch; i testi accessibili arrivano dall'esercizio.
		"targets": {
			"po": Vector2(9.96, 45.13),
			"sicily": Vector2(14.16, 37.55),
			"sardinia": Vector2(9.02, 40.05),
			# Catene e mari sono riconoscibili dalla sagoma muta; le regioni non
			# vengono esposte finché non avranno confini vettoriali verificabili.
			"alps": Vector2(10.35, 46.45),
			"apennines": Vector2(13.15, 42.45),
			"ligurian_sea": Vector2(8.25, 43.35),
			"tyrrhenian_sea": Vector2(11.45, 40.35),
			"adriatic_sea": Vector2(16.25, 43.15),
			"ionian_sea": Vector2(17.15, 38.25),
		},
	}


static func _europe_data() -> Dictionary:
	# Sagome costiere, non confini politici: il contenuto decide bersagli e
	# didattica; qui restano soltanto geografia e hit-area accessibili.
	return {
		"bounds": EUROPE_BOUNDS,
		"polygons": [
			PackedVector2Array([Vector2(-9.4,43.0),Vector2(-5.0,36.2),Vector2(0.5,42.6),Vector2(3.0,43.1),Vector2(6.0,45.0),Vector2(8.0,44.0),Vector2(7.0,46.5),Vector2(10.4,46.9),Vector2(13.8,46.5),Vector2(16.2,46.8),Vector2(18.8,45.9),Vector2(22.7,44.2),Vector2(26.3,45.1),Vector2(28.6,47.1),Vector2(30.8,46.5),Vector2(31.6,52.1),Vector2(28.2,56.2),Vector2(28.0,60.5),Vector2(31.5,62.9),Vector2(30.0,63.6),Vector2(27.0,60.0),Vector2(24.0,64.9),Vector2(19.9,68.4),Vector2(14.0,64.0),Vector2(12.0,59.4),Vector2(10.5,64.5),Vector2(5.0,62.0),Vector2(5.7,58.6),Vector2(8.5,57.1),Vector2(10.0,54.9),Vector2(6.9,53.5),Vector2(6.2,50.8),Vector2(2.7,51.2),Vector2(1.3,50.1),Vector2(-1.9,49.8),Vector2(-4.6,48.7),Vector2(-4.5,48.0),Vector2(-1.9,47.1),Vector2(-1.4,44.0),Vector2(-9.4,43.0)]),
			PackedVector2Array([Vector2(-6.2,50.0),Vector2(-5.7,51.0),Vector2(-4.2,52.3),Vector2(-5.8,53.5),Vector2(-3.1,54.6),Vector2(-4.2,58.6),Vector2(-1.1,54.6),Vector2(1.7,52.7),Vector2(1.1,51.8),Vector2(-3.6,50.2),Vector2(-6.2,50.0)]),
			PackedVector2Array([Vector2(-10.0,51.8),Vector2(-9.2,52.9),Vector2(-9.7,53.9),Vector2(-7.6,55.1),Vector2(-6.0,53.2),Vector2(-6.8,52.3),Vector2(-10.0,51.8)]),
			PackedVector2Array([Vector2(-24.3,63.7),Vector2(-21.8,64.4),Vector2(-18.7,63.5),Vector2(-14.5,65.8),Vector2(-17.8,66.0),Vector2(-22.1,65.1),Vector2(-24.3,63.7)]),
			PackedVector2Array([Vector2(8.2,40.9),Vector2(9.2,41.2),Vector2(9.8,40.5),Vector2(9.2,39.2),Vector2(8.4,39.2),Vector2(8.2,40.9)]),
			PackedVector2Array([Vector2(14.8,38.1),Vector2(15.5,38.2),Vector2(15.2,37.4),Vector2(15.1,36.6),Vector2(13.8,37.1),Vector2(12.4,37.6),Vector2(14.8,38.1)]),
		],
		"lines": {},
		"targets": {
			"italy": Vector2(12.5,42.5), "france": Vector2(2.2,46.5), "spain": Vector2(-3.7,40.1),
			"germany": Vector2(10.4,51.0), "poland": Vector2(19.0,52.0), "greece": Vector2(22.8,39.2),
			"united_kingdom": Vector2(-2.8,54.5), "ireland": Vector2(-8.0,53.2), "iceland": Vector2(-18.0,65.0),
			"norway": Vector2(10.5,62.0), "sweden": Vector2(17.5,61.0), "finland": Vector2(26.0,63.0),
			"ukraine": Vector2(31.0,49.0), "balkans": Vector2(20.0,44.0), "mediterranean": Vector2(14.0,36.0),
		},
	}
