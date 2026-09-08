class_name DialogueBox
extends Control

signal dialogue_closed(npc_id: String)

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
var heard_label: Label
var guidance_panel: PanelContainer
var guidance_title: Label
var guidance_label: Label
var portrait: Control
var panel: PanelContainer
var already_heard := false
var next_step := ""

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
	if is_instance_valid(guidance_panel):
		guidance_panel.add_theme_stylebox_override("panel", _guidance_style())
	_apply_read_state_colors()
	if visible and reduced_motion:
		_complete_reveal()

func show_dialogue(
	id: String,
	speaker: String,
	role: String,
	pages: Array,
	resident_stage: int = 0,
	was_already_heard: bool = false,
	student_next_step: String = ""
) -> void:
	if pages.is_empty():
		return
	npc_id = id
	screens = pages.duplicate()
	screen_index = 0
	already_heard = was_already_heard
	next_step = student_next_step.strip_edges()
	portrait.call("configure", id, speaker, resident_stage)
	speaker_label.text = speaker
	speaker_label.accessibility_name = "Parla %s" % speaker
	role_label.text = role
	heard_label.visible = already_heard
	heard_label.text = "GIÀ ASCOLTATO · RIPASSO" if already_heard else ""
	guidance_panel.visible = not next_step.is_empty()
	guidance_title.text = "DOPO IL DIALOGO · CONSIGLIO DI %s" % speaker.to_upper()
	guidance_label.text = next_step
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
	already_heard = false
	next_step = ""
	dialogue_closed.emit(closed_id)

func _show_screen() -> void:
	body_label.text = str(screens[screen_index])
	body_label.accessibility_name = body_label.text
	_apply_read_state_colors()
	revealed = float(body_label.text.length()) if reduced_motion else 0.0
	body_label.visible_characters = -1 if reduced_motion else 0
	progress_label.text = "%d/%d  ·  Tocca per %s" % [
		screen_index + 1, screens.size(),
		"continuare" if reduced_motion else "completare il testo",
	]
	set_process(not reduced_motion)

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
	panel.anchor_top = 0.50
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
	heard_label = Label.new()
	heard_label.name = "AlreadyHeard"
	heard_label.add_theme_font_size_override("font_size", 12)
	heard_label.add_theme_color_override("font_color", Color("aeb6b8"))
	heard_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heard_label.visible = false
	column.add_child(heard_label)
	body_label = Label.new()
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 19)
	body_label.add_theme_color_override("font_color", Color("e9fffa"))
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(body_label)
	guidance_panel = PanelContainer.new()
	guidance_panel.name = "StudentNextStep"
	guidance_panel.add_theme_stylebox_override("panel", _guidance_style())
	guidance_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_panel.visible = false
	column.add_child(guidance_panel)
	var guidance_column := VBoxContainer.new()
	guidance_column.add_theme_constant_override("separation", 2)
	guidance_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_panel.add_child(guidance_column)
	guidance_title = Label.new()
	guidance_title.add_theme_font_size_override("font_size", 11)
	guidance_title.add_theme_color_override("font_color", Color("f6c85f"))
	guidance_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_column.add_child(guidance_title)
	guidance_label = Label.new()
	guidance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance_label.add_theme_font_size_override("font_size", 14)
	guidance_label.add_theme_color_override("font_color", Color("d9efec"))
	guidance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_column.add_child(guidance_label)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color("8fd8d0"))
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(progress_label)

## Il grigio comunica una cosa precisa: questa stessa battuta e' gia' stata
## ascoltata. Titolo e indicazioni operative restano invece colorati, perche'
## possono ancora descrivere il prossimo passo corrente.
func _apply_read_state_colors() -> void:
	if not is_instance_valid(body_label):
		return
	var color := Color("e9fffa")
	if high_contrast:
		color = Color("c7c7c7") if already_heard else Color("ffffff")
	elif already_heard:
		color = Color("98a3a5")
	body_label.add_theme_color_override("font_color", color)
	body_label.modulate = Color(1.0, 1.0, 1.0, 0.92 if already_heard else 1.0)

func _guidance_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("080c0d") if high_contrast else Color(0.12, 0.17, 0.16, 0.92)
	style.border_color = Color.WHITE if high_contrast else Color("a88435")
	style.set_border_width_all(2 if high_contrast else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

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
