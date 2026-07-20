extends Node2D

## Sfondo piatto del chunk: terreno, tinta del bioma, chiazze d'erba, ciuffi,
## fiori e sentieri con bordo. Sta su z_index basso e fuori dall'y-sort, così
## resta sempre dietro agli oggetti (ostacoli, player, interagibili).
##
## I dettagli decorativi usano un RNG seedato SEPARATO ("<id>:ground"): stessa
## estetica a ogni visita, nessun impatto sulla parità del generatore.
## Tutti i valori casuali sono precalcolati in setup(): _draw() deve essere
## ripetibile senza consumare RNG.

const GROUND_TEXTURE: Texture2D = preload("res://assets/academy-ground.svg")
const ACADEMY_HERO_TEXTURE: Texture2D = preload("res://assets/radura-accademia-hero-backdrop-v2.png")
const RNG := preload("res://scripts/deterministic_rng.gd")

var chunk: Dictionary
var visual_lod := 0
var blotches: Array = []   # [{pos, radius, alpha}]
var speckles: Array = []   # [{pos, radius, color}]
var tufts: Array = []      # [{pos, height, color}]
var blossom_clusters: Array = [] # [{pos, radius, color}]
var academy_focus := false
var academy_paths: Array[PackedVector2Array] = []
var academy_gardens: Array[Vector2] = []
var academy_stones: Array[Vector2] = []
var corridor_points: Array[Vector2] = []
var anchor_points: Array[Vector2] = []
var motif_points: Array[Vector2] = []

func setup(data: Dictionary, lod_level: int = 0) -> void:
	chunk = data
	visual_lod = maxi(0, lod_level)
	var decor = RNG.new(str(chunk.get("id", "chunk")) + ":ground")
	var size := float(chunk.get("size", 896))
	var patch: Dictionary = chunk.get("patch", {})
	var biome := str(chunk.get("biome", "academy"))
	var tint := _hex_color(int(patch.get("color", 0x173b36))).lerp(_biome_palette_tint(biome), 0.22)
	var accent := _hex_color(int(patch.get("accent", 0x6be7d6))).lerp(_biome_palette_accent(biome), 0.18)
	academy_focus = str(chunk.get("biome", "")) == "academy" and int(chunk.get("chunkX", 99)) == 0 and int(chunk.get("chunkY", 99)) == 0
	academy_paths.clear()
	academy_gardens.clear()
	academy_stones.clear()
	motif_points.clear()
	_prepare_composition_masks(size)
	var density := _biome_density(biome)

	blotches.clear()
	for i in range(maxi(3, roundi(6.0 * density))):
		blotches.append({
			"pos": Vector2(decor.next_float() * size, decor.next_float() * size),
			"radius": 90.0 + decor.next_float() * 140.0,
			"alpha": 0.05 + decor.next_float() * 0.05,
		})

	speckles.clear()
	var speckle_count := roundi((112.0 if visual_lod == 0 else 36.0) * density)
	for i in range(maxi(10, speckle_count)):
		var roll := decor.next_float()
		var color: Color
		var radius: float
		if roll < 0.62:
			color = Color(tint.darkened(0.25), 0.4)
			radius = 1.6 + decor.next_float() * 2.2
		elif roll < 0.9:
			color = Color(tint.lightened(0.35), 0.3)
			radius = 1.4 + decor.next_float() * 1.8
		else:
			color = Color(accent, 0.75)
			radius = 1.8 + decor.next_float() * 0.9
		speckles.append({
			"pos": Vector2(8.0 + decor.next_float() * (size - 16.0), 8.0 + decor.next_float() * (size - 16.0)),
			"radius": radius,
			"color": color,
		})

	tufts.clear()
	var tuft_count := roundi((46.0 if visual_lod == 0 else 18.0) * density)
	for i in range(maxi(6, tuft_count)):
		var tuft_roll := decor.next_float()
		var tuft_color := Color(accent, 0.24) if tuft_roll > 0.76 else Color(tint.lightened(0.3), 0.22)
		tufts.append({
			"pos": Vector2(12.0 + decor.next_float() * (size - 24.0), 12.0 + decor.next_float() * (size - 24.0)),
			"height": 3.0 + decor.next_float() * 6.0,
			"color": tuft_color,
		})

	blossom_clusters.clear()
	var blossom_count := roundi((22.0 if visual_lod == 0 else 8.0) * density)
	for i in range(maxi(3, blossom_count)):
		var blossom_roll := decor.next_float()
		var blossom_color := Color(accent, 0.68) if blossom_roll > 0.42 else Color(tint.lightened(0.46), 0.52)
		blossom_clusters.append({
			"pos": Vector2(24.0 + decor.next_float() * (size - 48.0), 24.0 + decor.next_float() * (size - 48.0)),
			"radius": 2.0 + decor.next_float() * 2.2,
			"color": blossom_color,
		})

	for i in range(4 if visual_lod == 0 else 2):
		motif_points.append(Vector2(
			56.0 + decor.next_float() * (size - 112.0),
			56.0 + decor.next_float() * (size - 112.0)))

	# Layout decorativo separato dal generatore: il chunk centrale della Radura
	# diventa una piccola scena composta (cortile, acqua, sentieri e bordi
	# naturali), mentre gli ID e le posizioni gameplay restano invariati.
	if academy_focus:
		_prepare_academy_composition(decor, size)
	queue_redraw()

func _prepare_composition_masks(size: float) -> void:
	corridor_points.clear()
	anchor_points.clear()
	var world_x := float(chunk.get("worldX", 0))
	var world_y := float(chunk.get("worldY", 0))
	for point in chunk.get("pathPoints", []):
		corridor_points.append(Vector2(float(point.get("x", 0)) - world_x, float(point.get("y", 0)) - world_y))
	for key in ["obstacles", "props", "landmarks", "treasures", "encounters"]:
		for item in chunk.get(key, []):
			anchor_points.append(Vector2(float(item.get("x", world_x)) - world_x, float(item.get("y", world_y)) - world_y))

func _biome_palette_tint(biome: String) -> Color:
	# Palette percettiva condivisa: il patch procedurale resta la base, questi
	# colori stabilizzano temperatura e leggibilità tra chunk adiacenti.
	match biome:
		"academy": return Color("5e7545")
		"wild": return Color("315f42")
		"geo": return Color("3c7864")
		"logic": return Color("3f4f78")
		"ruins": return Color("604a56")
		"crystal": return Color("4b4f8c")
		_: return Color("3d5a48")

func _biome_palette_accent(biome: String) -> Color:
	match biome:
		"academy": return Color("f2c66d")
		"wild": return Color("7fe0a7")
		"geo": return Color("79d8d0")
		"logic": return Color("b4a7ff")
		"ruins": return Color("f0a080")
		"crystal": return Color("d6c8ff")
		_: return Color("9fe0c3")

func _biome_density(biome: String) -> float:
	match biome:
		"academy": return 0.92
		"wild": return 1.18
		"geo": return 0.86
		"ruins": return 0.68
		"logic": return 0.76
		"crystal": return 0.58
		_: return 0.85

func _is_composition_clear(pos: Vector2, radius: float = 0.0) -> bool:
	for point in corridor_points:
		if pos.distance_to(point) < 58.0 + radius:
			return true
	for point in anchor_points:
		if pos.distance_to(point) < 48.0 + radius:
			return true
	return false

func _draw() -> void:
	var size := float(chunk.get("size", 896))
	# Bleed oltre il bordo tecnico: i ground adiacenti si coprono leggermente
	# e non lasciano fessure o righe di separazione a schermo.
	var bleed := 18.0
	var ground_rect := Rect2(Vector2(-bleed, -bleed), Vector2(size + bleed * 2.0, size + bleed * 2.0))
	# Underpainting del vertical slice: gli oggetti interattivi e il player
	# restano nodi separati e continuano a seguire il mondo procedurale.
	draw_texture_rect(GROUND_TEXTURE, ground_rect, true)

	var patch: Dictionary = chunk.get("patch", {})
	var biome := str(chunk.get("biome", "academy"))
	var tint := _hex_color(int(patch.get("color", 0x173b36))).lerp(_biome_palette_tint(biome), 0.22)
	var accent := _hex_color(int(patch.get("accent", 0x6be7d6))).lerp(_biome_palette_accent(biome), 0.18)
	draw_rect(Rect2(Vector2(-bleed, -bleed), Vector2(size + bleed * 2.0, size + bleed * 2.0)), Color(tint, 0.28))
	if academy_focus:
		_draw_academy_composition(size, tint)
		# Un velo leggermente trasparente lascia respirare il terreno ai bordi:
		# il fondale hero non deve sembrare una texture rettangolare incollata.
		draw_texture_rect(ACADEMY_HERO_TEXTURE, ground_rect, false, Color(1.0, 1.0, 1.0, 0.86))
		_draw_academy_focus_transition(size)
	elif biome == "academy":
		# I chunk accanto alla Radura ricevono la stessa temperatura cromatica
		# del vertical slice. In questo modo la camera può attraversare il bordo
		# senza il salto netto fra hero dorato e terreno blu-verde del prototipo.
		_draw_academy_peripheral_composition(size, tint, accent)
	else:
		_draw_biome_motif(size, tint, accent)
	if not academy_focus and _is_academy_neighbor():
		_draw_academy_neighbor_transition(size, accent)

	for blotch in blotches:
		if _is_composition_clear(blotch["pos"], blotch["radius"] * 0.35):
			continue
		draw_circle(blotch["pos"], blotch["radius"], Color(tint.darkened(0.3), blotch["alpha"]))

	# I punti di percorso restano nel contratto procedurale, ma non disegniamo
	# più linee fino ai bordi del chunk: erano percepite come una griglia visiva.
	_draw_meadow_clearing(size, tint)

	for speckle in speckles:
		if _is_composition_clear(speckle["pos"], 2.0):
			continue
		draw_circle(speckle["pos"], speckle["radius"], speckle["color"])

	for tuft in tufts:
		var base: Vector2 = tuft["pos"]
		if _is_composition_clear(base, 3.0):
			continue
		var height: float = tuft["height"]
		var color: Color = tuft["color"]
		draw_line(base, base + Vector2(-1.8, -height), color, 1.3, true)
		draw_line(base + Vector2(1.0, 0), base + Vector2(2.8, -height * 0.78), color, 1.1, true)

	for blossom in blossom_clusters:
		var blossom_pos: Vector2 = blossom["pos"]
		if _is_composition_clear(blossom_pos, 5.0):
			continue
		var blossom_radius: float = blossom["radius"]
		var blossom_color: Color = blossom["color"]
		# Tre piccoli fiori vicini creano ciuffi leggibili, non punti casuali.
		draw_circle(blossom_pos, blossom_radius, blossom_color)
		draw_circle(blossom_pos + Vector2(blossom_radius * 1.25, -blossom_radius * 0.55), blossom_radius * 0.72, blossom_color)
		draw_circle(blossom_pos + Vector2(-blossom_radius * 1.1, -blossom_radius * 0.35), blossom_radius * 0.68, blossom_color)

func _draw_academy_peripheral_composition(size: float, tint: Color, accent: Color) -> void:
	# Fascia di raccordo per i chunk non hero: colori caldi, radure morbide e
	# piccoli gruppi naturali. È solo pittura sul terreno, senza collisioni.
	draw_rect(Rect2(Vector2(-18, -18), Vector2(size + 36.0, size + 36.0)), Color(0.48, 0.54, 0.25, 0.17))
	var warm := Color(0.78, 0.62, 0.32, 0.16)
	for point in [
		Vector2(size * 0.12, size * 0.18),
		Vector2(size * 0.82, size * 0.26),
		Vector2(size * 0.22, size * 0.76),
		Vector2(size * 0.78, size * 0.82),
	]:
		if _is_composition_clear(point, 24.0):
			continue
		draw_set_transform(point, -0.12, Vector2(1.5, 0.54))
		draw_circle(Vector2.ZERO, 82.0, Color(0.28, 0.45, 0.22, 0.18))
		draw_circle(Vector2(-18, -5), 50.0, warm)
		draw_circle(Vector2(25, 6), 34.0, Color(accent, 0.10))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for petal in [Vector2(-28, -12), Vector2(-4, -20), Vector2(18, -10), Vector2(8, 12)]:
			draw_circle(point + petal, 3.2, Color(1.0, 0.84, 0.48, 0.58))
			draw_circle(point + petal + Vector2(4, -2), 2.2, Color(1.0, 0.96, 0.72, 0.48))

	# Nebbia calda sui bordi: riduce il contrasto percepito fra due superfici
	# adiacenti mentre il giocatore attraversa il raccordo.
	draw_rect(Rect2(-18, 0, 34, size), Color(0.62, 0.54, 0.28, 0.12))
	draw_rect(Rect2(size - 16, 0, 34, size), Color(0.62, 0.54, 0.28, 0.12))
	draw_rect(Rect2(0, -18, size, 34), Color(0.62, 0.54, 0.28, 0.08))
	draw_rect(Rect2(0, size - 16, size, 34), Color(0.62, 0.54, 0.28, 0.08))

func _draw_academy_focus_transition(size: float) -> void:
	# Il fondale hero è più luminoso dei chunk procedurali. Quattro fasce
	# sovrapposte, decrescenti verso il centro, trasformano il bordo tecnico in
	# una vignetta naturale senza introdurre una linea visibile.
	var edge := Color(0.09, 0.18, 0.16, 0.0)
	for i in range(5):
		var t := float(i) / 4.0
		var alpha := 0.15 - t * 0.11
		var inset := float(i) * 16.0
		edge.a = alpha
		draw_rect(Rect2(-18.0 + inset, -18.0, 18.0, size + 36.0), edge)
		draw_rect(Rect2(size - inset - 18.0, -18.0, 18.0, size + 36.0), edge)
		draw_rect(Rect2(-18.0, -18.0 + inset, size + 36.0, 18.0), edge)
		draw_rect(Rect2(-18.0, size - inset - 18.0, size + 36.0, 18.0), edge)

func _is_academy_neighbor() -> bool:
	var x := int(chunk.get("chunkX", 99))
	var y := int(chunk.get("chunkY", 99))
	return (abs(x) + abs(y)) == 1

func _draw_academy_neighbor_transition(size: float, accent: Color) -> void:
	# Solo i quattro chunk adiacenti alla Radura ricevono una fascia di
	# transizione. La tinta è confinata al bordo rivolto verso (0,0), così il
	# bioma mantiene la propria identità ma non crea una cucitura verticale.
	var x := int(chunk.get("chunkX", 99))
	var y := int(chunk.get("chunkY", 99))
	var warm := Color(0.78, 0.62, 0.32, 0.16)
	if x < 0:
		draw_rect(Rect2(size - 86.0, -18, 104, size + 36), Color(0.64, 0.55, 0.30, 0.16))
		draw_set_transform(Vector2(size - 22.0, size * 0.52), -0.1, Vector2(1.0, 0.54))
		draw_circle(Vector2.ZERO, 142.0, warm)
	elif x > 0:
		draw_rect(Rect2(-18, -18, 104, size + 36), Color(0.64, 0.55, 0.30, 0.16))
		draw_set_transform(Vector2(22.0, size * 0.52), 0.1, Vector2(1.0, 0.54))
		draw_circle(Vector2.ZERO, 142.0, warm)
	elif y < 0:
		draw_rect(Rect2(-18, size - 86.0, size + 36, 104), Color(0.64, 0.55, 0.30, 0.13))
		draw_set_transform(Vector2(size * 0.52, size - 22.0), 0.0, Vector2(1.25, 0.58))
		draw_circle(Vector2.ZERO, 142.0, warm)
	else:
		draw_rect(Rect2(-18, -18, size + 36, 104), Color(0.64, 0.55, 0.30, 0.13))
		draw_set_transform(Vector2(size * 0.52, 22.0), 0.0, Vector2(1.25, 0.58))
		draw_circle(Vector2.ZERO, 142.0, warm)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Pochi riflessi dell'accento locale fanno leggere il raccordo come un
	# bordo naturale, non come una maschera di colore uniforme.
	for i in range(5):
		var t := float(i) / 4.0
		var pos: Vector2
		if x != 0:
			pos = Vector2(size - 26.0 if x < 0 else 26.0, 116.0 + t * (size - 232.0))
		else:
			pos = Vector2(116.0 + t * (size - 232.0), size - 26.0 if y < 0 else 26.0)
		draw_circle(pos, 2.8 + fmod(float(i), 2.0), Color(accent, 0.28))

func _draw_biome_motif(size: float, tint: Color, accent: Color) -> void:
	var biome := str(chunk.get("biome", "academy"))
	for point in motif_points:
		if _is_composition_clear(point, 30.0):
			continue
		match biome:
			"academy":
				draw_set_transform(point, -0.1, Vector2(1.4, 0.55))
				draw_circle(Vector2.ZERO, 32.0, Color(0.18, 0.38, 0.21, 0.25))
				draw_circle(Vector2(-12, -3), 4.0, Color(1.0, 0.78, 0.42, 0.72))
				draw_circle(Vector2(10, 3), 3.2, Color(1.0, 0.95, 0.72, 0.65))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"wild":
				draw_set_transform(point, -0.12, Vector2(1.5, 0.58))
				draw_circle(Vector2.ZERO, 38.0, Color(0.08, 0.26, 0.16, 0.34))
				draw_circle(Vector2(16, 4), 18.0, Color(0.16, 0.40, 0.22, 0.4))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for blade in range(6):
					var base := point + Vector2(-20.0 + blade * 7.0, 8.0)
					draw_line(base, base + Vector2(-5.0 + blade * 1.5, -22.0), Color(accent, 0.52), 2.2, true)
				for berry in [Vector2(-16, -10), Vector2(4, -16), Vector2(20, -5)]:
					draw_circle(point + berry, 3.4, Color(0.68, 0.22, 0.33, 0.72))
			"geo":
				draw_set_transform(point, -0.08, Vector2(1.55, 0.62))
				draw_circle(Vector2.ZERO, 38.0, Color(0.08, 0.27, 0.28, 0.34))
				draw_circle(Vector2.ZERO, 30.0, Color(0.14, 0.52, 0.56, 0.52))
				draw_arc(Vector2.ZERO, 25.0, 0.2, 2.8, 24, Color(accent, 0.7), 3.0, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for stone in [Vector2(-28, 14), Vector2(-9, 20), Vector2(14, 16), Vector2(31, 7)]:
					draw_circle(point + stone, 5.0, Color(0.66, 0.68, 0.54, 0.58))
			"logic":
				draw_set_transform(point, 0.0, Vector2(1.0, 0.42))
				draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 6, Color(accent, 0.48), 4.0, true)
				draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 6, Color(0.58, 0.47, 0.78, 0.42), 3.0, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var diamond := PackedVector2Array([point + Vector2(0, -13), point + Vector2(13, 0), point + Vector2(0, 13), point + Vector2(-13, 0)])
				draw_colored_polygon(diamond, Color(accent, 0.22))
			"ruins":
				draw_set_transform(point, -0.1, Vector2(1.25, 0.52))
				draw_circle(Vector2.ZERO, 40.0, Color(0.11, 0.09, 0.14, 0.38))
				draw_arc(Vector2.ZERO, 31.0, 0.25, 2.45, 18, Color(0.50, 0.42, 0.48, 0.6), 8.0, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for moss in [Vector2(-21, 6), Vector2(9, 18), Vector2(25, -4)]:
					draw_circle(point + moss, 4.0, Color(0.30, 0.52, 0.30, 0.58))
			"crystal":
				var glow := Color(accent, 0.22)
				draw_circle(point, 42.0, glow)
				var crystal := PackedVector2Array([point + Vector2(0, -34), point + Vector2(18, 0), point + Vector2(0, 26), point + Vector2(-18, 0)])
				draw_colored_polygon(crystal, Color(accent, 0.42))
				var facet := PackedVector2Array([point + Vector2(0, -25), point + Vector2(9, 0), point + Vector2(0, 13)])
				draw_colored_polygon(facet, Color(0.88, 0.96, 1.0, 0.45))

func _draw_meadow_clearing(size: float, tint: Color) -> void:
	# Radura morbida al centro: lega visivamente gli elementi vicini senza
	# introdurre segmenti rettilinei o giunzioni sui bordi dei chunk.
	var center := Vector2(size * 0.5, size * 0.5)
	var clearing := Color(tint.lightened(0.16), 0.055)
	draw_set_transform(center, -0.08, Vector2(1.35, 0.62))
	draw_circle(Vector2.ZERO, size * 0.27, clearing)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _prepare_academy_composition(decor, size: float) -> void:
	# Piccoli jitter seedati impediscono che la scena sembri un template rigido,
	# ma la grammatica resta leggibile a ogni caricamento.
	var j1 := Vector2((decor.next_float() - 0.5) * 18.0, (decor.next_float() - 0.5) * 14.0)
	var j2 := Vector2((decor.next_float() - 0.5) * 16.0, (decor.next_float() - 0.5) * 12.0)
	var j3 := Vector2((decor.next_float() - 0.5) * 14.0, (decor.next_float() - 0.5) * 12.0)
	var center := Vector2(size * 0.5, size * 0.51)
	# Un anello di sentieri organici: nessun segmento segue i bordi del chunk,
	# quindi non viene percepito come griglia tecnica.
	academy_paths = [
		PackedVector2Array([
			Vector2(78, 818), Vector2(126, 738), Vector2(232, 668),
			Vector2(350, 622), center + Vector2(-48, 30), center + Vector2(18, -2),
			Vector2(628, 390), Vector2(742, 304), Vector2(820, 240),
		]),
		PackedVector2Array([
			Vector2(56, 260), Vector2(144, 278), Vector2(226, 320),
			Vector2(292, 390), center + Vector2(-48, 30),
		]),
		PackedVector2Array([
			center + Vector2(18, -2), Vector2(500, 342), Vector2(536, 242),
			Vector2(626, 176), Vector2(748, 124),
		]),
	]
	academy_gardens = [
		Vector2(118, 182) + j1, Vector2(344, 190) + j2,
		Vector2(714, 274) + j3, Vector2(762, 586) + j1,
		Vector2(284, 748) + j2,
	]
	academy_stones = [
		Vector2(136, 731), Vector2(185, 687), Vector2(254, 649), Vector2(326, 617),
		Vector2(409, 574), Vector2(484, 510), Vector2(564, 444), Vector2(645, 375),
		Vector2(720, 319), Vector2(786, 270),
	]

func _draw_academy_composition(size: float, tint: Color) -> void:
	# Un velo più caldo evita il fondale blu-verde uniforme del prototipo e
	# avvicina la Radura alla luce dorata del modello di riferimento.
	draw_rect(Rect2(Vector2(-18, -18), Vector2(size + 36.0, size + 36.0)), Color(0.52, 0.60, 0.28, 0.13))

	# Sentieri a tre strati: bordo morbido, sabbia calda e riflesso centrale.
	for path in academy_paths:
		draw_polyline(path, Color(0.16, 0.12, 0.07, 0.22), 70.0, true)
		draw_polyline(path, Color(0.76, 0.56, 0.28, 0.66), 52.0, true)
		draw_polyline(path, Color(1.0, 0.86, 0.54, 0.24), 11.0, true)

	for stone in academy_stones:
		draw_circle(stone, 7.0, Color(0.82, 0.70, 0.46, 0.34))
		draw_circle(stone + Vector2(-1.5, -1.5), 3.2, Color(1.0, 0.9, 0.66, 0.26))

	# Laghetto principale e sponda: la forma ovale è leggibile anche con la
	# camera zoomata e dà un punto focale al lato sinistro della radura.
	var pond := Vector2(192, 432)
	draw_set_transform(pond, -0.13, Vector2(1.42, 0.72))
	draw_circle(Vector2.ZERO, 118.0, Color(0.12, 0.27, 0.22, 0.38))
	draw_circle(Vector2.ZERO, 104.0, Color(0.12, 0.52, 0.53, 0.80))
	draw_circle(Vector2(-18, -22), 76.0, Color(0.27, 0.75, 0.70, 0.38))
	draw_circle(Vector2(-25, -30), 38.0, Color(0.75, 0.97, 0.76, 0.20))
	draw_arc(Vector2.ZERO, 108.0, 0.0, TAU, 48, Color(0.72, 0.72, 0.45, 0.56), 13.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for bank_pos in [Vector2(106, 408), Vector2(127, 502), Vector2(224, 533), Vector2(285, 432), Vector2(245, 348), Vector2(142, 344)]:
		draw_circle(bank_pos, 10.0, Color(0.48, 0.52, 0.34, 0.64))
		draw_circle(bank_pos + Vector2(-2, -3), 5.0, Color(0.76, 0.72, 0.48, 0.42))

	# Cortile della fontana, con anelli concentrici in pietra e acqua luminosa.
	var courtyard := Vector2(size * 0.53, size * 0.51)
	draw_set_transform(courtyard, 0.0, Vector2(1.34, 0.62))
	draw_circle(Vector2.ZERO, 96.0, Color(0.26, 0.34, 0.22, 0.20))
	draw_circle(Vector2.ZERO, 78.0, Color(0.83, 0.68, 0.38, 0.34))
	draw_circle(Vector2.ZERO, 62.0, Color(0.92, 0.77, 0.44, 0.44))
	draw_circle(Vector2.ZERO, 45.0, Color(0.18, 0.54, 0.49, 0.70))
	draw_circle(Vector2(-10, -11), 17.0, Color(0.51, 0.94, 0.77, 0.64))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(courtyard + Vector2(0, -42), 10.0, Color(0.74, 1.0, 0.80, 0.44))

	# Isole di fiori/vegetazione: masse più ampie e raggruppate al posto di
	# punti isolati. Sono solo pittura sul terreno, non nascondono collisioni.
	for garden in academy_gardens:
		draw_set_transform(garden, -0.1, Vector2(1.45, 0.54))
		draw_circle(Vector2.ZERO, 42.0, Color(0.14, 0.33, 0.20, 0.32))
		draw_circle(Vector2(-13, -4), 24.0, Color(0.30, 0.54, 0.26, 0.44))
		draw_circle(Vector2(17, 2), 22.0, Color(0.39, 0.62, 0.28, 0.38))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for petal_offset in [Vector2(-22, -10), Vector2(-4, -18), Vector2(15, -8), Vector2(7, 10)]:
			draw_circle(garden + petal_offset, 4.0, Color(0.98, 0.78, 0.42, 0.72))
			draw_circle(garden + petal_offset + Vector2(4, -2), 2.8, Color(0.98, 0.96, 0.74, 0.64))

	# Bordo foreground morbido: incornicia la scena senza creare una barriera.
	for x in range(24, int(size) - 20, 44):
		var sway := sin(float(x) * 0.035) * 8.0
		draw_circle(Vector2(float(x), size - 18.0 + sway), 19.0, Color(0.13, 0.31, 0.18, 0.34))
		draw_circle(Vector2(float(x) + 12.0, size - 33.0 + sway), 12.0, Color(0.31, 0.52, 0.24, 0.42))

func _hex_color(rgb: int) -> Color:
	return Color(
		float((rgb >> 16) & 0xFF) / 255.0,
		float((rgb >> 8) & 0xFF) / 255.0,
		float(rgb & 0xFF) / 255.0,
	)
