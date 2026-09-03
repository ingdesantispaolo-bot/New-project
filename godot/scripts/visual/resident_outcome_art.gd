class_name ResidentOutcomeArt
extends RefCounted

const AUTHORED_ATLAS := preload("res://assets/generated/resident-outcomes-authored-atlas-v1.png")
const SUBJECT_ATLAS := preload("res://assets/generated/resident-outcomes-subject-atlas-v1.png")

const AUTHORED_CELLS := {
	"w01-tobia": Vector2i(0, 0), "w01-ersilia": Vector2i(1, 0),
	"w02-corinna": Vector2i(2, 0), "w02-bruno": Vector2i(3, 0),
	"w03-ruggine": Vector2i(4, 0), "w03-sesto": Vector2i(0, 1),
	"w04-marea": Vector2i(1, 1), "w04-lino": Vector2i(2, 1),
	"w05-gerbo": Vector2i(3, 1), "w05-tilla": Vector2i(4, 1),
}

const SUBJECT_CELLS := {
	"matematica": Vector2i(0, 0), "italiano": Vector2i(1, 0),
	"coding": Vector2i(2, 0), "inglese": Vector2i(3, 0),
	"fisica": Vector2i(0, 1), "musica": Vector2i(1, 1),
	"latino": Vector2i(2, 1), "elettronica": Vector2i(3, 1),
	"geografia": Vector2i(0, 2), "scienze": Vector2i(1, 2),
	"storia": Vector2i(2, 2), "logica": Vector2i(3, 2),
}

static func build(resident_id: String) -> Sprite2D:
	var authored := AUTHORED_CELLS.has(resident_id)
	var texture: Texture2D = AUTHORED_ATLAS if authored else SUBJECT_ATLAS
	var grid := Vector2i(5, 2) if authored else Vector2i(4, 3)
	var cell: Vector2i = AUTHORED_CELLS.get(resident_id, Vector2i.ZERO) if authored else _subject_cell(resident_id)
	var cell_size := Vector2(float(texture.get_width()) / grid.x, float(texture.get_height()) / grid.y)
	var region := AtlasTexture.new()
	region.atlas = texture
	region.region = Rect2(Vector2(cell) * cell_size, cell_size)
	var sprite := Sprite2D.new()
	sprite.name = "GeneratedResidentOutcome"
	sprite.texture = region
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = Vector2(0, -17)
	sprite.scale = Vector2.ONE * minf(174.0 / cell_size.x, 142.0 / cell_size.y)
	sprite.z_index = 2
	sprite.set_meta("atlas_cell", cell)
	sprite.set_meta("authored_outcome", authored)
	return sprite

static func apply(sprite: Sprite2D, completed: bool, high_contrast: bool) -> void:
	if sprite != null:
		sprite.visible = completed and not high_contrast

static func _subject_cell(resident_id: String) -> Vector2i:
	var level := int(resident_id.substr(1, 2)) if resident_id.length() >= 3 else 1
	return SUBJECT_CELLS.get(ApparatusConfig.world_subject(level), Vector2i.ZERO)

