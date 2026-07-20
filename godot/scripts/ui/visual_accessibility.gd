class_name VisualAccessibility
extends RefCounted

## Policy visuali condivisibili da HUD, marker ed esercizi.
## Non cambia input, validazione o ricompense.

static func apply_motion_policy(node: CanvasItem, reduced_motion: bool) -> void:
	if not is_instance_valid(node):
		return
	node.set_meta("reduced_motion", reduced_motion)

static func accessible_color(color: Color, on_dark_background: bool = true) -> Color:
	var result := color
	if on_dark_background and result.get_luminance() < 0.42:
		result = result.lightened(0.28)
	return Color(result, color.a)

static func outline_style(fill: Color, outline: Color = Color("0b1f24"), width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	return style
