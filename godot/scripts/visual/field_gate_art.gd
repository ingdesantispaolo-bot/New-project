class_name FieldGateArt
extends RefCounted

## Due righe: ostacolo chiuso sopra, trasformato sotto. Collisione e stato non
## dipendono mai dai pixel dell'immagine.

const ATLAS: Texture2D = preload("res://assets/generated/field-gates-atlas-v1.png")
const COLONNE := {
	"tool-torch": 0,
	"tool-scythe": 1,
	"tool-lever": 2,
	"tool-lens": 3,
	"tool-bellows": 4,
}

static func build(tool_id: String, open: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "FieldGateArt"
	apply(sprite, tool_id, open)
	return sprite

static func apply(sprite: Sprite2D, tool_id: String, open: bool) -> void:
	var column := int(COLONNE.get(tool_id, 0))
	var cell_size := ATLAS.get_size() / Vector2(5.0, 2.0)
	var region := AtlasTexture.new()
	region.atlas = ATLAS
	region.region = Rect2(Vector2(column, 1 if open else 0) * cell_size, cell_size)
	sprite.texture = region
	sprite.position = Vector2(0, -13)
	var scale_factor := minf(142.0 / cell_size.x, 118.0 / cell_size.y)
	sprite.scale = Vector2.ONE * scale_factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
