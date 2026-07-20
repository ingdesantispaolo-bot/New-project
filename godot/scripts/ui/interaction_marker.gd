class_name OutdoorInteractionMarker
extends Node2D

## Marker diegetico puramente visivo.
## Non interagisce con save, collisioni o gameplay: riceve solo un kind e un
## testo opzionale dall'orchestratore e rende riconoscibile il punto d'interesse.

@export var kind := "mission"
@export var caption := ""
@export var accent := Color("f6c85f")
@export var active := true

var _time := 0.0

const COLORS := {
	"mission": Color("f6c85f"),
	"treasure": Color("d9c8ff"),
	"apparatus": Color("6be7d6"),
	"portal": Color("9f8cff"),
	"encounter": Color("ff9b72"),
}

func _ready() -> void:
	if COLORS.has(kind):
		accent = COLORS[kind]
	z_index = 20
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	queue_redraw()

func configure(marker_kind: String, marker_caption: String = "", marker_accent: Color = Color.TRANSPARENT) -> void:
	kind = marker_kind
	caption = marker_caption
	if marker_accent != Color.TRANSPARENT:
		accent = marker_accent
	elif COLORS.has(kind):
		accent = COLORS[kind]
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var pulse := 1.0 + sin(_time * 2.4) * 0.07
	var halo_alpha := 0.10 + (sin(_time * 2.0) + 1.0) * 0.035
	# Ombra e aura a terra per ancorare il marker al mondo, senza rettangoli.
	draw_ellipse(Vector2(0, 8), Vector2(25, 9), Color(0.01, 0.03, 0.04, 0.30))
	draw_circle(Vector2.ZERO, 21.0 * pulse, Color(accent, halo_alpha))
	var ring := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		ring.append(Vector2(cos(a), sin(a)) * 19.0 * pulse)
	draw_polyline(ring, Color(accent, 0.82), 2.0, true)
	_draw_glyph()
	if caption.strip_edges() != "":
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-42, -30), caption, HORIZONTAL_ALIGNMENT_CENTER, 84, 12, Color(0.92, 0.98, 0.96, 0.92))

func _draw_glyph() -> void:
	var fill := Color(accent, 0.94)
	match kind:
		"treasure":
			draw_rect(Rect2(-9, -5, 18, 11), fill, true)
			draw_line(Vector2(-9, -5), Vector2(9, -5), Color("fff3bd"), 2.0)
			draw_circle(Vector2.ZERO, 2.2, Color("553c68"))
		"portal":
			draw_arc(Vector2.ZERO, 11, PI, TAU, 16, fill, 4.0, true)
			draw_line(Vector2(-11, 0), Vector2(-11, 8), fill, 4.0)
			draw_line(Vector2(11, 0), Vector2(11, 8), fill, 4.0)
		"apparatus":
			draw_circle(Vector2.ZERO, 8, fill)
			draw_circle(Vector2.ZERO, 3, Color("17383b"))
			draw_line(Vector2(0, -14), Vector2(0, -8), Color("eaffdb"), 2.0)
		"encounter":
			draw_circle(Vector2.ZERO, 9, fill)
			draw_circle(Vector2.ZERO, 3, Color("442c40"))
		"_":
			draw_circle(Vector2.ZERO, 8, fill)
			draw_circle(Vector2.ZERO, 3, Color("453f2e"))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
