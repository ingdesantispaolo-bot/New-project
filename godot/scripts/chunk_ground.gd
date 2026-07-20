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
const RNG := preload("res://scripts/deterministic_rng.gd")

var chunk: Dictionary
var blotches: Array = []   # [{pos, radius, alpha}]
var speckles: Array = []   # [{pos, radius, color}]
var tufts: Array = []      # [{pos, height, color}]

func setup(data: Dictionary) -> void:
	chunk = data
	var decor = RNG.new(str(chunk.get("id", "chunk")) + ":ground")
	var size := float(chunk.get("size", 896))
	var patch: Dictionary = chunk.get("patch", {})
	var tint := _hex_color(int(patch.get("color", 0x173b36)))
	var accent := _hex_color(int(patch.get("accent", 0x6be7d6)))

	blotches.clear()
	for i in range(6):
		blotches.append({
			"pos": Vector2(decor.next_float() * size, decor.next_float() * size),
			"radius": 90.0 + decor.next_float() * 140.0,
			"alpha": 0.05 + decor.next_float() * 0.05,
		})

	speckles.clear()
	for i in range(112):
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
	for i in range(46):
		var tuft_roll := decor.next_float()
		var tuft_color := Color(accent, 0.24) if tuft_roll > 0.76 else Color(tint.lightened(0.3), 0.22)
		tufts.append({
			"pos": Vector2(12.0 + decor.next_float() * (size - 24.0), 12.0 + decor.next_float() * (size - 24.0)),
			"height": 3.0 + decor.next_float() * 6.0,
			"color": tuft_color,
		})
	queue_redraw()

func _draw() -> void:
	var size := float(chunk.get("size", 896))
	draw_texture_rect(GROUND_TEXTURE, Rect2(Vector2.ZERO, Vector2(size, size)), true)

	var patch: Dictionary = chunk.get("patch", {})
	var tint := _hex_color(int(patch.get("color", 0x173b36)))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size, size)), Color(tint, 0.28))

	for blotch in blotches:
		draw_circle(blotch["pos"], blotch["radius"], Color(tint.darkened(0.3), blotch["alpha"]))

	_draw_paths()

	for speckle in speckles:
		draw_circle(speckle["pos"], speckle["radius"], speckle["color"])

	for tuft in tufts:
		var base: Vector2 = tuft["pos"]
		var height: float = tuft["height"]
		var color: Color = tuft["color"]
		draw_line(base, base + Vector2(-1.8, -height), color, 1.3, true)
		draw_line(base + Vector2(1.0, 0), base + Vector2(2.8, -height * 0.78), color, 1.1, true)

func _draw_paths() -> void:
	var world_x := float(chunk.get("worldX", 0))
	var world_y := float(chunk.get("worldY", 0))
	var points: Array = chunk.get("pathPoints", [])
	if points.size() < 2:
		return
	var line := PackedVector2Array()
	for point in points:
		line.append(Vector2(float(point["x"]) - world_x, float(point["y"]) - world_y))
	var border := Color(0.16, 0.13, 0.08, 0.4)
	var core := Color(0.85, 0.77, 0.55, 0.34)
	# prima l'intero bordo (linea + tappi), poi l'intero nucleo: così i tappi
	# tondi ammorbidiscono i giunti senza lasciare anelli scuri sul nucleo
	draw_polyline(line, border, 16.0)
	for point in line:
		draw_circle(point, 8.0, border)
	draw_polyline(line, core, 10.0)
	for point in line:
		draw_circle(point, 5.0, core)

func _hex_color(rgb: int) -> Color:
	return Color(
		float((rgb >> 16) & 0xFF) / 255.0,
		float((rgb >> 8) & 0xFF) / 255.0,
		float(rgb & 0xFF) / 255.0,
	)
