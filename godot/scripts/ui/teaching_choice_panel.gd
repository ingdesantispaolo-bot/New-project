class_name TeachingChoicePanel
extends Control

signal choice_made(option_id: String, correct: bool)
signal choice_skipped

var panel: PanelContainer
var title_label: Label
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
	title_label = Label.new()
	title_label.text = "RISPIEGAMELO · VERA"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color("f6c85f"))
	column.add_child(title_label)
	question_label = Label.new()
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 18)
	column.add_child(question_label)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 10)
	column.add_child(choices)

func open(topic_label: String, options: Array) -> void:
	open_choice(
		"RISPIEGAMELO · VERA",
		"Quale spiegazione aiuta Vera a capire davvero %s?" % topic_label.replace("-", " "),
		options)

## Una scelta qualunque, con il proprio titolo e la propria domanda.
##
## Le scelte di posizione (`StanceChoices`) passano di qui: usano `dice` come
## testo del pulsante e **non hanno una risposta giusta**, quindi `choice_made`
## porta sempre `false` come secondo argomento e chi ascolta lo ignora. Non è una
## svista: è il motivo per cui esistono, e l'audit lo verifica.
func open_choice(
	title_text: String,
	question: String,
	options: Array,
	skippable: bool = false
) -> void:
	for child in choices.get_children():
		child.free()
	title_label.text = title_text
	question_label.text = question
	for raw_option in options:
		var option: Dictionary = raw_option
		var button := Button.new()
		button.text = str(option.get("cosa", option.get("dice", option.get("id", "Spiegazione"))))
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
	if skippable:
		var skip := Button.new()
		skip.name = "SkipChoice"
		skip.text = "SALTA · NON DEVO DECIDERE ADESSO"
		skip.custom_minimum_size = Vector2(0, 48)
		skip.add_theme_font_size_override("font_size", 14)
		skip.pressed.connect(func():
			visible = false
			choice_skipped.emit()
		)
		choices.add_child(skip)
	visible = true
	if choices.get_child_count() > 0:
		(choices.get_child(0) as Button).grab_focus()
