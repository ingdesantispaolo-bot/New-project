class_name NpcPortrait
extends Control

var npc_id := ""
var display_name := ""
var accent := Color("6be7d6")
var stage := 0

## Il catalogo visuale segue lo stesso ID del catalogo narrativo:
## `w08-doria` -> `assets/npcs/world08/doria-v1.png`. Il caricamento resta lazy:
## in memoria entrano soltanto i tre abitanti del mondo corrente, non tutti i 69.
const PORTRAIT_REGIONS := {
	"w01-tobia": Rect2(108, 16, 148, 148),
	"w01-ersilia": Rect2(114, 18, 152, 152),
	"w01-puccio": Rect2(98, 12, 154, 154),
}

static func art_for(id: String) -> Texture2D:
	if id.begins_with("itin-"):
		# Sesto itinerante e' lo stesso personaggio incontrato nel mondo 3:
		# riusare la sua illustrazione preserva identita', volto e costume.
		if id == "itin-sesto":
			return load("res://assets/npcs/world03/sesto-v1.png") as Texture2D
		var itinerant_slug := id.trim_prefix("itin-")
		var itinerant_path := "res://assets/itinerants/%s-v1.png" % itinerant_slug
		if ResourceLoader.exists(itinerant_path):
			return load(itinerant_path) as Texture2D
		return null
	var parts := id.split("-", false, 1)
	if parts.size() != 2 or not str(parts[0]).begins_with("w"):
		return null
	var world_number := str(parts[0]).trim_prefix("w")
	var slug := str(parts[1])
	var path := "res://assets/npcs/world%s/%s-v1.png" % [world_number, slug]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func portrait_art_for(id: String) -> Texture2D:
	var source := art_for(id)
	if source == null:
		return null
	var portrait := AtlasTexture.new()
	portrait.atlas = source
	portrait.region = PORTRAIT_REGIONS.get(id, Rect2(98, 8, 188, 188))
	return portrait

func configure(id: String, label: String, resident_stage: int = 0) -> void:
	npc_id = id
	display_name = label
	stage = clampi(resident_stage, 0, 2)
	set_meta("resident_stage", stage)
	accent = _accent_for(id)
	accessibility_name = "Ritratto di %s" % label
	custom_minimum_size = Vector2(92, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center := size * Vector2(0.5, 0.48)
	var radius := minf(size.x, size.y) * 0.34
	var generated := portrait_art_for(npc_id)
	if generated != null:
		draw_circle(center, radius + 5.0, Color("10272b"))
		draw_circle(center, radius + 2.0, Color(accent, 0.24))
		var art_rect := Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
		# Tre regie del mezzo busto: composto, in movimento, aperto verso l'altro.
		# L'identità resta l'asset approvato; gesto e postura cambiano con l'arco.
		var angle: float = [-0.045, 0.035, -0.025][stage]
		var pose_scale: Vector2 = [Vector2(0.96, 0.96), Vector2(1.02, 1.02), Vector2(-1.04, 1.04)][stage]
		draw_set_transform(center, angle, pose_scale)
		draw_texture_rect(generated, Rect2(-Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_stage_gesture(center, radius)
		draw_arc(center, radius + 5.0, 0.0, TAU, 40, Color("f6c85f"), 3.0, true)
		return
	draw_circle(center + Vector2(0, radius * 0.82), radius * 0.72, Color(accent, 0.72))
	draw_circle(center, radius, Color("f2c6a0"))
	var hair := accent.darkened(0.52)
	draw_arc(center + Vector2(0, -2), radius * 0.94, PI, TAU, 24, hair, 12.0, true)
	var eye_y := center.y - radius * 0.08
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(center.x + side * radius * 0.34, eye_y), 3.2, Color("10272b"))
	draw_arc(center + Vector2(0, radius * 0.18), radius * 0.28, 0.15, PI - 0.15, 18, Color("7b3f35"), 2.6, true)
	draw_arc(center, radius + 5.0, 0.0, TAU, 40, Color("f6c85f"), 3.0, true)

func _draw_stage_gesture(center: Vector2, radius: float) -> void:
	var skin := Color("f2c6a0")
	if stage == 1:
		# Una mano al lavoro sul petto: il personaggio non è più fermo in posa.
		draw_line(center + Vector2(radius * 0.72, radius * 0.52), center + Vector2(radius * 0.24, radius * 0.12), accent.darkened(0.18), radius * 0.20, true)
		draw_circle(center + Vector2(radius * 0.20, radius * 0.10), radius * 0.105, skin)
	elif stage == 2:
		# Braccio aperto verso l'esterno: lo stadio concluso condivide, non posa.
		draw_line(center + Vector2(-radius * 0.62, radius * 0.45), center + Vector2(-radius * 1.04, -radius * 0.10), accent.darkened(0.18), radius * 0.20, true)
		draw_circle(center + Vector2(-radius * 1.07, -radius * 0.14), radius * 0.11, skin)

static func _accent_for(id: String) -> Color:
	var palette := [Color("6be7d6"), Color("f6c85f"), Color("c7b8ff"), Color("ff9c8f")]
	return palette[posmod(hash(id), palette.size())]
