class_name SubjectStationArt
extends RefCounted

## Atlante pittorico delle dodici palestre. La materia sceglie soltanto la
## regione; colore, progresso, testo e interazione restano nel runtime.

const ATLAS: Texture2D = preload("res://assets/generated/subject-stations-atlas-v1.png")

const CELLE := {
	"matematica": Vector2i(0, 0),
	"italiano": Vector2i(1, 0),
	"coding": Vector2i(2, 0),
	"inglese": Vector2i(3, 0),
	"fisica": Vector2i(0, 1),
	"musica": Vector2i(1, 1),
	"latino": Vector2i(2, 1),
	"elettronica": Vector2i(3, 1),
	"geografia": Vector2i(0, 2),
	"scienze": Vector2i(1, 2),
	"storia": Vector2i(2, 2),
	"logica": Vector2i(3, 2),
}

static func build(subject: String, completed: bool) -> Sprite2D:
	var cell: Vector2i = CELLE.get(subject, Vector2i.ZERO)
	var cell_size := ATLAS.get_size() / Vector2(4.0, 3.0)
	var region := AtlasTexture.new()
	region.atlas = ATLAS
	region.region = Rect2(Vector2(cell) * cell_size, cell_size)

	var sprite := Sprite2D.new()
	sprite.name = "SubjectStationArt"
	sprite.texture = region
	sprite.position = Vector2(0, -31)
	var scale_factor := minf(150.0 / cell_size.x, 112.0 / cell_size.y)
	sprite.scale = Vector2.ONE * scale_factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = Color.WHITE if completed else Color(0.72, 0.78, 0.78, 0.92)
	return sprite
