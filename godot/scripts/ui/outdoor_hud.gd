class_name OutdoorHud
extends Control

## HUD puramente presentazionale del mondo esterno.
## Riceve OutdoorRuntimeState da gameplay e non modifica save, gate o ricompense.
## Il collegamento alla scena resta a carico dell'orchestratore dopo il gate I-01.

signal exit_requested

var runtime_state: Dictionary = {}
var _biome_label: Label
var _phase_label: Label
var _level_label: Label
var _focus_label: Label
var _apparatus_label: Label
var _mission_label: Label
var _mastery_label: Label
var _mastery_bar: ProgressBar
var _energy_label: Label
var _fragment_label: Label
var _prompt_label: Label
var _prompt_panel: PanelContainer
var _ready_badge: Label
var _top_panel: PanelContainer
var _resources_panel: PanelContainer

const SAFE_MARGIN := 18.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_top_panel):
		_layout_for_viewport()

func _ready() -> void:
	_build_ui()
	apply_runtime_state(runtime_state)

func apply_runtime_state(state: Dictionary) -> void:
	runtime_state = state.duplicate(true)
	if not is_instance_valid(_level_label):
		return
	_level_label.text = "LIVELLO %d" % int(runtime_state.get("level", 1))
	_focus_label.text = "Materia focus · %s" % _pretty(str(runtime_state.get("focusSubject", "matematica")))
	_apparatus_label.text = "Apparato · %s" % _pretty(str(runtime_state.get("apparatus", "nucleo")))
	_mission_label.text = "Missioni %d/%d" % [int(runtime_state.get("missionsDone", 0)), int(runtime_state.get("missionsRequired", 0))]
	var mastery := float(runtime_state.get("mastery", 0.0))
	var threshold := float(runtime_state.get("masteryThreshold", 0.70))
	_mastery_label.text = "Mastery %.0f%% / %.0f%%" % [mastery * 100.0, threshold * 100.0]
	_mastery_bar.value = clampf(mastery / maxf(threshold, 0.01) * 100.0, 0.0, 100.0)
	_energy_label.text = "Energia %d" % int(runtime_state.get("energy", 0))
	_fragment_label.text = "Frammenti %d" % int(runtime_state.get("fragments", 0))
	_phase_label.text = _pretty(str(runtime_state.get("phase", "giorno")))
	_ready_badge.visible = bool(runtime_state.get("ready", false))
	_ready_badge.text = "PRONTO · ESAME APPARATO"

func set_biome(label: String, accent: Color = Color("6be7d6")) -> void:
	if not is_instance_valid(_biome_label):
		return
	_biome_label.text = label
	_biome_label.add_theme_color_override("font_color", accent)

func set_prompt(message: String, accent: Color = Color("f6c85f")) -> void:
	if not is_instance_valid(_prompt_panel):
		return
	_prompt_panel.visible = message.strip_edges() != ""
	_prompt_label.text = message
	_prompt_label.add_theme_color_override("font_color", accent)

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
    vec2 p = UV - vec2(0.5);
    float edge = smoothstep(0.56, 1.04, length(p * vec2(1.0, 0.82)));
    COLOR = vec4(0.01, 0.03, 0.035, edge * 0.24);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	vignette.material = material
	add_child(vignette)

	_top_panel = PanelContainer.new()
	_top_panel.position = Vector2(SAFE_MARGIN, SAFE_MARGIN)
	_top_panel.custom_minimum_size = Vector2(352, 0)
	_top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.10, 0.11, 0.84), Color(0.42, 0.9, 0.84, 0.34)))
	add_child(_top_panel)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	_top_panel.add_child(top_box)

	var title := Label.new()
	title.text = "ELI QUEST  ·  RADURA ACCADEMIA"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("e7fff8"))
	top_box.add_child(title)
	_biome_label = Label.new()
	_biome_label.text = "Radura Accademia"
	_biome_label.add_theme_font_size_override("font_size", 14)
	top_box.add_child(_biome_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	top_box.add_child(row)
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.add_theme_color_override("font_color", Color("f6c85f"))
	row.add_child(_level_label)
	_phase_label = Label.new()
	_phase_label.add_theme_font_size_override("font_size", 14)
	_phase_label.add_theme_color_override("font_color", Color("9fc4bb"))
	row.add_child(_phase_label)
	_focus_label = Label.new()
	_focus_label.add_theme_font_size_override("font_size", 13)
	_focus_label.add_theme_color_override("font_color", Color("6be7d6"))
	top_box.add_child(_focus_label)
	_apparatus_label = Label.new()
	_apparatus_label.add_theme_font_size_override("font_size", 13)
	_apparatus_label.add_theme_color_override("font_color", Color("d9c8ff"))
	top_box.add_child(_apparatus_label)
	_mission_label = Label.new()
	_mission_label.add_theme_font_size_override("font_size", 13)
	_mission_label.add_theme_color_override("font_color", Color("f6c85f"))
	top_box.add_child(_mission_label)
	_mastery_label = Label.new()
	_mastery_label.add_theme_font_size_override("font_size", 12)
	_mastery_label.add_theme_color_override("font_color", Color("9fc4bb"))
	top_box.add_child(_mastery_label)
	_mastery_bar = ProgressBar.new()
	_mastery_bar.show_percentage = false
	_mastery_bar.custom_minimum_size = Vector2(0, 10)
	_mastery_bar.add_theme_stylebox_override("background", _bar_style(Color(0.04, 0.14, 0.14, 0.92)))
	_mastery_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.42, 0.90, 0.70, 0.90)))
	top_box.add_child(_mastery_bar)
	_ready_badge = Label.new()
	_ready_badge.visible = false
	_ready_badge.add_theme_font_size_override("font_size", 12)
	_ready_badge.add_theme_color_override("font_color", Color("f6c85f"))
	top_box.add_child(_ready_badge)

	_resources_panel = PanelContainer.new()
	_resources_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_resources_panel.position = Vector2(-208, SAFE_MARGIN)
	_resources_panel.custom_minimum_size = Vector2(190, 0)
	_resources_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.10, 0.11, 0.84), Color(0.42, 0.9, 0.84, 0.28)))
	add_child(_resources_panel)
	var resource_box := VBoxContainer.new()
	resource_box.add_theme_constant_override("separation", 3)
	_resources_panel.add_child(resource_box)
	_energy_label = Label.new()
	_energy_label.add_theme_font_size_override("font_size", 16)
	_energy_label.add_theme_color_override("font_color", Color("f6c85f"))
	resource_box.add_child(_energy_label)
	_fragment_label = Label.new()
	_fragment_label.add_theme_font_size_override("font_size", 14)
	_fragment_label.add_theme_color_override("font_color", Color("d9c8ff"))
	resource_box.add_child(_fragment_label)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_prompt_panel.position = Vector2(22, -86)
	_prompt_panel.custom_minimum_size = Vector2(360, 0)
	_prompt_panel.visible = false
	_prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.10, 0.11, 0.90), Color(0.96, 0.78, 0.36, 0.38)))
	add_child(_prompt_panel)
	_prompt_label = Label.new()
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.add_theme_font_size_override("font_size", 14)
	_prompt_panel.add_child(_prompt_label)
	_layout_for_viewport()

func _layout_for_viewport() -> void:
	if not is_instance_valid(_top_panel) or not is_instance_valid(_resources_panel):
		return
	var width := get_viewport_rect().size.x
	var compact := width < 760.0
	_top_panel.custom_minimum_size.x = minf(352.0, maxf(250.0, width - 2.0 * SAFE_MARGIN))
	_resources_panel.custom_minimum_size.x = 164.0 if compact else 190.0
	_resources_panel.position = Vector2(-_resources_panel.custom_minimum_size.x - SAFE_MARGIN, 128.0 if compact else SAFE_MARGIN)
	if is_instance_valid(_prompt_panel):
		_prompt_panel.custom_minimum_size.x = minf(360.0, maxf(240.0, width - 2.0 * SAFE_MARGIN))
		_prompt_panel.position = Vector2(SAFE_MARGIN, -86.0)

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	return style

func _bar_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(6)
	return style

func _pretty(value: String) -> String:
	return value.replace("-", " ").capitalize()
