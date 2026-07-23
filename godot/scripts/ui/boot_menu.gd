extends Control

## Entrata nativa dell'applicazione. Questa scena possiede soltanto la UI di
## avvio: lo stato e il gameplay restano nei manager e in outdoor_world.tscn.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const BACKDROP := preload("res://assets/radura-accademia-hero-backdrop-v2.png")

var play_button: Button

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.eliScene = 'boot';")
	_build_interface()
	play_button.grab_focus()

func _build_interface() -> void:
	var background := TextureRect.new()
	background.name = "Backdrop"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BACKDROP
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.015, 0.055, 0.075, 0.58)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "TitleCard"
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 34)
	content_margin.add_theme_constant_override("margin_top", 28)
	content_margin.add_theme_constant_override("margin_right", 34)
	content_margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(content_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	content_margin.add_child(column)

	var eyebrow := Label.new()
	eyebrow.text = "ACCADEMIA DELLE MISSIONI"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("8ff6d2"))
	eyebrow.add_theme_font_size_override("font_size", 14)
	column.add_child(eyebrow)

	var title := Label.new()
	title.name = "GameTitle"
	title.text = "ELI QUEST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f7fbff"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 46)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Esplora il mondo, completa le missioni\ne ripara la nave dell'Accademia."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("d4e7e9"))
	subtitle.add_theme_font_size_override("font_size", 17)
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	column.add_child(spacer)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "GIOCA"
	play_button.custom_minimum_size = Vector2(0, 58)
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color("07181d"))
	play_button.add_theme_color_override("font_hover_color", Color("07181d"))
	play_button.add_theme_color_override("font_focus_color", Color("07181d"))
	play_button.add_theme_stylebox_override("normal", _button_style(Color("6be7d6"), Color("b8fff0")))
	play_button.add_theme_stylebox_override("hover", _button_style(Color("8ff6d2"), Color.WHITE))
	play_button.add_theme_stylebox_override("pressed", _button_style(Color("49bcae"), Color("8ff6d2")))
	play_button.add_theme_stylebox_override("focus", _focus_style())
	play_button.pressed.connect(_play)
	column.add_child(play_button)

	var hint := Label.new()
	hint.text = "Invio / Spazio per iniziare"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("9fb7bb"))
	hint.add_theme_font_size_override("font_size", 13)
	column.add_child(hint)

func _play() -> void:
	play_button.disabled = true
	play_button.text = "AVVIO…"
	get_tree().change_scene_to_file(WORLD_SCENE)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.075, 0.095, 0.94)
	style.border_color = Color(0.42, 0.91, 0.84, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 18
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.expand_margin_left = 4
	style.expand_margin_top = 4
	style.expand_margin_right = 4
	style.expand_margin_bottom = 4
	return style
