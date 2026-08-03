class_name TeachingChoicePanel
extends Control

signal choice_made(option_id: String, correct: bool)

var panel: PanelContainer
var question_label: Label
var choices: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.01, 0.04, 0.06, 0.78)
	add_child(veil)
	panel = PanelContainer.new()
	panel.anchor_left = 0.14
	panel.anchor_right = 0.86
	panel.anchor_top = 0.16
	panel.anchor_bottom = 0.86
	var style := StyleBoxFlat.new()
	style.bg_color = Color("092027")
	style.border_color = Color("8fd8d0")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "RISPIEGAMELO · VERA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f6c85f"))
	column.add_child(title)
	question_label = Label.new()
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 18)
	column.add_child(question_label)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 10)
	column.add_child(choices)

func open(topic_label: String, options: Array) -> void:
	for child in choices.get_children():
		child.free()
	question_label.text = "Quale spiegazione aiuta Vera a capire davvero %s?" % topic_label.replace("-", " ")
	for raw_option in options:
		var option: Dictionary = raw_option
		var button := Button.new()
		button.text = str(option.get("cosa", option.get("id", "Spiegazione")))
		button.custom_minimum_size = Vector2(0, 70)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 16)
		var option_id := str(option.get("id", ""))
		var correct := bool(option.get("giusta", false))
		button.pressed.connect(func():
			visible = false
			choice_made.emit(option_id, correct)
		)
		choices.add_child(button)
	visible = true
	if choices.get_child_count() > 0:
		(choices.get_child(0) as Button).grab_focus()
