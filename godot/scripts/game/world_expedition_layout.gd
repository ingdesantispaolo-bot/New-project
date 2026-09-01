class_name WorldExpeditionLayout
extends RefCounted

## Macro-layout di una spedizione. Il WorldProfile continua a decidere identita',
## materia, landmark e art kit; questo strato aggiuntivo decide soltanto quanto
## territorio c'e' attorno a quei luoghi e quale sagoma ha questa visita.
##
## Lo stesso seed ricostruisce la stessa isola. Un nuovo seed crea una nuova
## spedizione senza invalidare gli id persistenti di missioni e tesori.

const MIN_EXTENT := Vector2(2440.0, 2380.0)
const MAX_EXTENT := Vector2(3060.0, 2960.0)
const VERTEX_COUNT := 16
const EDGE_SAFETY := 0.78

static func apply(profile: Dictionary, world_seed: String) -> Dictionary:
	if profile.is_empty():
		return profile
	var out := profile.duplicate(true)
	var level := int(out.get("level", 1))
	var ship: Vector2 = out.get("shipEntrance", {}).get("position", Vector2.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s::expedition-layout::%d" % [world_seed, level]))

	var minimum := MIN_EXTENT
	var maximum := MAX_EXTENT
	# Il mosaico finale usa settori piu' lontani degli altri profili.
	if level == WorldProfileCatalog.MAX_LEVEL:
		minimum += Vector2(260.0, 220.0)
		maximum += Vector2(260.0, 220.0)
	var extents := Vector2(
		snappedf(rng.randf_range(minimum.x, maximum.x), 40.0),
		snappedf(rng.randf_range(minimum.y, maximum.y), 40.0))
	var center := ship + Vector2(
		rng.randf_range(-110.0, 110.0),
		rng.randf_range(80.0, 230.0))
	var phase := rng.randf_range(-0.16, 0.16)
	var shape := PackedVector2Array()
	for index in range(VERTEX_COUNT):
		var angle := phase + TAU * float(index) / float(VERTEX_COUNT)
		# Due onde larghe danno promontori e rientranze; il jitter piccolo evita
		# punte troppo strette e mantiene la sagoma facile da percorrere.
		var broad := sin(angle * 3.0 + rng.randf_range(-0.12, 0.12)) * 0.075
		var radius := clampf(0.91 + broad + rng.randf_range(-0.055, 0.055), 0.80, 1.02)
		shape.append(center + Vector2(cos(angle) * extents.x, sin(angle) * extents.y) * radius)

	out["worldShape"] = shape
	out["worldExtents"] = extents
	out["worldCenter"] = center
	# Il codice di placement storico usa un solo semi-lato. Lo teniamo dentro
	# la parte sicura della sagoma: gli eventi non finiscono nei promontori.
	out["worldHalfExtent"] = minf(extents.x, extents.y) * EDGE_SAFETY
	out["expeditionLayout"] = {
		"seed": world_seed,
		"shape": _shape_name(rng),
		"size": _size_name(extents),
		"pocketCount": clampi(3 + int(floor((extents.x + extents.y - 4800.0) / 500.0)), 3, 5),
	}
	return out

static func _shape_name(rng: RandomNumberGenerator) -> String:
	return ["arcipelago", "valle", "promontorio", "conca"][rng.randi_range(0, 3)]

static func _size_name(extents: Vector2) -> String:
	var area_hint := extents.x * extents.y
	if area_hint < 6700000.0:
		return "raccolta"
	if area_hint > 8200000.0:
		return "vasta"
	return "ampia"

static func bounds_of(shape: PackedVector2Array) -> Rect2:
	if shape.is_empty():
		return Rect2()
	var minimum := shape[0]
	var maximum := shape[0]
	for point in shape:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)

