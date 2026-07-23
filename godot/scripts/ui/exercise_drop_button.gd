extends Button

signal item_dropped(source_id: String, target_id: String)

var target_id := ""
var accepted_kind := ""

func configure_target(id: String, kind: String) -> void:
	target_id = id
	accepted_kind = kind
	focus_mode = Control.FOCUS_ALL

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		not disabled
		and data is Dictionary
		and bool(data.get("eli_exercise_drag", false))
		and str(data.get("kind", "")) == accepted_kind
	)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(str(data.get("source", "")), target_id)
