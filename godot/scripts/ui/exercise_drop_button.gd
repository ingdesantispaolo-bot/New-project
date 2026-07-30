extends Button

signal item_dropped(source_id: String, target_id: String)
signal drop_preview(active: bool)

var target_id := ""
var accepted_kind := ""
var _preview_active := false

func configure_target(id: String, kind: String) -> void:
	target_id = id
	accepted_kind = kind
	focus_mode = Control.FOCUS_ALL

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var accepted := (
		not disabled
		and data is Dictionary
		and bool(data.get("eli_exercise_drag", false))
		and str(data.get("kind", "")) == accepted_kind
	)
	if accepted != _preview_active:
		_preview_active = accepted
		modulate = Color(0.72, 1.0, 0.86) if accepted else Color.WHITE
		drop_preview.emit(accepted)
	return accepted

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_preview_active = false
	modulate = Color.WHITE
	drop_preview.emit(false)
	item_dropped.emit(str(data.get("source", "")), target_id)
