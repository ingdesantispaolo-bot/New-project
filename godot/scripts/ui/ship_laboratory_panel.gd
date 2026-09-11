class_name ShipLaboratoryPanel
extends Control

signal completed(room_id: String, choices: Array)
signal closed

const LABS := preload("res://scripts/game/ship_laboratories.gd")

var room_id := ""
var choices: Array = []
var spec: Dictionary = {}
var title_label: Label
var intro_label: Label
var progress_label: Label
var prompt_label: Label
var choice_box: VBoxContainer
var previous_label: Label
var result_label: Label
var close_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.003, 0.014, 0.022, 0.92)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "LaboratoryCard"
	panel.custom_minimum_size = Vector2(720, 490)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.052, 0.070, 0.99)
	style.border_color = Color("6be7d6")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var eyebrow := Label.new()
	eyebrow.text = "LABORATORIO DI STANZA · NESSUNA RISPOSTA GIUSTA"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 11)
	eyebrow.add_theme_color_override("font_color", Color("8fb7bd"))
	box.add_child(eyebrow)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color("f5fbff"))
	box.add_child(title_label)
	intro_label = Label.new()
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.add_theme_font_size_override("font_size", 13)
	intro_label.add_theme_color_override("font_color", Color("b9d3d7"))
	box.add_child(intro_label)
	previous_label = Label.new()
	previous_label.name = "PreviousReflection"
	previous_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	previous_label.add_theme_font_size_override("font_size", 11)
	previous_label.add_theme_color_override("font_color", Color("a994d6"))
	box.add_child(previous_label)
	progress_label = Label.new()
	progress_label.name = "LaboratoryProgress"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color("f7d37a"))
	box.add_child(progress_label)
	prompt_label = Label.new()
	prompt_label.name = "LaboratoryPrompt"
	prompt_label.custom_minimum_size.y = 60
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color("e7f5f4"))
	box.add_child(prompt_label)
	choice_box = VBoxContainer.new()
	choice_box.name = "LaboratoryChoices"
	choice_box.add_theme_constant_override("separation", 9)
	box.add_child(choice_box)
	result_label = Label.new()
	result_label.name = "LaboratoryResult"
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 13)
	result_label.add_theme_color_override("font_color", Color("9ff5d8"))
	result_label.visible = false
	box.add_child(result_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	close_button = Button.new()
	close_button.text = "CHIUDI IL LABORATORIO"
	close_button.custom_minimum_size.y = 46
	close_button.pressed.connect(close_panel)
	box.add_child(close_button)

func open_lab(new_room_id: String, previous: Dictionary = {}) -> void:
	spec = LABS.laboratory(new_room_id)
	if spec.is_empty():
		return
	room_id = new_room_id
	choices.clear()
	visible = true
	previous_label.text = (
		"SINTESI PRECEDENTE · %s" % str(previous.get("summary", ""))
		if bool(previous.get("completed", false)) else "NESSUNA SINTESI PRECEDENTE"
	)
	_refresh_step()

func _refresh_step() -> void:
	title_label.text = str(spec.get("title", "Laboratorio")).to_upper()
	intro_label.text = str(spec.get("intro", ""))
	result_label.visible = false
	prompt_label.visible = true
	choice_box.visible = true
	for child in choice_box.get_children():
		child.queue_free()
	var steps: Array = Array(spec.get("steps", []))
	var index := choices.size()
	if index >= steps.size():
		_finish()
		return
	progress_label.text = "DECISIONE %d / %d  ·  %s" % [
		index + 1, steps.size(), "* ".repeat(index) + "o ".repeat(steps.size() - index)]
	var step: Dictionary = steps[index]
	prompt_label.text = str(step.get("prompt", "Che cosa vuoi conservare?"))
	var options: Array = Array(step.get("options", []))
	for option_index in range(options.size()):
		var option: Dictionary = options[option_index]
		var button := Button.new()
		button.name = "LaboratoryChoice%d" % option_index
		button.text = str(option.get("label", "SCEGLI"))
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = str(option.get("meaning", ""))
		button.pressed.connect(_choose.bind(option_index))
		choice_box.add_child(button)

func _choose(index: int) -> void:
	choices.append(index)
	_refresh_step()

func _finish() -> void:
	choice_box.visible = false
	prompt_label.visible = false
	progress_label.text = "SINTESI COMPLETA · * * *"
	result_label.visible = true
	result_label.text = "%s\n\n%s" % [
		_synthesis(), str(spec.get("completion", "NORA: sintesi registrata."))]
	completed.emit(room_id, choices.duplicate())

func _synthesis() -> String:
	var meanings: Array[String] = []
	var steps: Array = Array(spec.get("steps", []))
	for index in range(mini(choices.size(), steps.size())):
		var options: Array = Array(Dictionary(steps[index]).get("options", []))
		var selected := int(choices[index])
		if selected >= 0 and selected < options.size():
			meanings.append(str(Dictionary(options[selected]).get("meaning", "")))
	return "La tua lettura: %s." % "; ".join(PackedStringArray(meanings))

func close_panel() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()
