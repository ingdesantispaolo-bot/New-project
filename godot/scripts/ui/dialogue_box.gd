class_name DialogueBox
extends Control

signal dialogue_closed(npc_id: String)
signal screen_changed(index: int, total: int)

const PORTRAIT := preload("res://scripts/ui/npc_portrait.gd")
const CHARACTERS_PER_SECOND := 42.0

var npc_id := ""
var screens: Array = []
var screen_index := 0
var revealed := 0.0
var high_contrast := false
var reduced_motion := false
var speaker_label: Label
var role_label: Label
var body_label: Label
var progress_label: Label
var portrait: Control
var panel: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build_ui()
	visible = false
	set_process(false)

func configure_accessibility(use_high_contrast: bool, use_reduced_motion: bool) -> void:
	high_contrast = use_high_contrast
	reduced_motion = use_reduced_motion
	if is_instance_valid(panel):
		panel.add_theme_stylebox_override("panel", _panel_style())
	if visible and reduced_motion:
		_complete_reveal()

func show_dialogue(id: String, speaker: String, role: String, pages: Array) -> void:
	if pages.is_empty():
		return
	npc_id = id
	screens = pages.duplicate()
	screen_index = 0
	portrait.call("configure", id, speaker)
	speaker_label.text = speaker
	speaker_label.accessibility_name = "Parla %s" % speaker
	role_label.text = role
	visible = true
	grab_focus()
	_show_screen()

func advance() -> void:
	if not visible:
		return
	if body_label.visible_characters >= 0 and body_label.visible_characters < body_label.text.length():
		_complete_reveal()
		return
	if screen_index + 1 < screens.size():
		screen_index += 1
		_show_screen()
		return
	close_dialogue()

func close_dialogue() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	var closed_id := npc_id
	npc_id = ""
	screens = []
	dialogue_closed.emit(closed_id)

func _show_screen() -> void:
	body_label.text = str(screens[screen_index])
	body_label.accessibility_name = body_label.text
	revealed = float(body_label.text.length()) if reduced_motion else 0.0
	body_label.visible_characters = -1 if reduced_motion else 0
	progress_label.text = "%d/%d  ·  Tocca per %s" % [
		screen_index + 1, screens.size(),
		"continuare" if reduced_motion else "completare il testo",
	]
	set_process(not reduced_motion)
	screen_changed.emit(screen_index, screens.size())

func _process(delta: float) -> void:
	if not visible or reduced_motion:
		set_process(false)
		return
	revealed = minf(float(body_label.text.length()), revealed + delta * CHARACTERS_PER_SECOND)
	body_label.visible_characters = floori(revealed)
	if body_label.visible_characters >= body_label.text.length():
		_complete_reveal()

func _complete_reveal() -> void:
	revealed = float(body_label.text.length())
	body_label.visible_characters = -1
	set_process(false)
	progress_label.text = "%d/%d  ·  Tocca per %s" % [
		screen_index + 1, screens.size(),
		"continuare" if screen_index + 1 < screens.size() else "chiudere",
	]

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		advance()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("leave_portal")) and not event.is_echo():
		advance()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.01, 0.04, 0.06, 0.12)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	panel = PanelContainer.new()
	panel.name = "DialoguePanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.58
	panel.anchor_bottom = 0.94
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	portrait = PORTRAIT.new()
	row.add_child(portrait)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color("f6c85f"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(speaker_label)
	role_label = Label.new()
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", Color("91b8ba"))
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(role_label)
	body_label = Label.new()
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 19)
	body_label.add_theme_color_override("font_color", Color("e9fffa"))
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(body_label)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color("8fd8d0"))
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(progress_label)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08191f") if high_contrast else Color(0.025, 0.09, 0.11, 0.97)
	style.border_color = Color.WHITE if high_contrast else Color("6be7d6")
	style.set_border_width_all(4 if high_contrast else 2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style
