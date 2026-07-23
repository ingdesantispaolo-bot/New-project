extends Button

## Sorgente drag accessibile: il click resta sempre disponibile per touch e
## tastiera, mentre mouse/touch con trascinamento ricevono una preview esplicita.

var drag_id := ""
var drag_kind := ""

func configure(id: String, kind: String) -> void:
	drag_id = id
	drag_kind = kind
	focus_mode = Control.FOCUS_ALL

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or drag_id == "":
		return null
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 15)
	preview.add_theme_color_override("font_color", Color("f7fbff"))
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.20, 0.22, 0.97)
	style.border_color = Color("8ff6d2")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(preview)
	set_drag_preview(panel)
	return {"eli_exercise_drag": true, "kind": drag_kind, "source": drag_id}
