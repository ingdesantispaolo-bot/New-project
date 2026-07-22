extends Node2D

## Nave nativa data-driven. I sette ponti condividono una sola scena/UI; dati,
## sfondo, apparato, restauro e materie arrivano da ShipRoomCatalog.

const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")
const NORA_PORTRAIT_SCRIPT := preload("res://scripts/ui/nora_portrait.gd")

var controller: HubController
var content: ContentManager
var save: GameSaveManager
var rewards: RewardManager
var narrative: NarrativeManager
var progress_report: LocalProgressReport
var exercise_player: ExercisePlayer

var current_room_id := ShipRoomCatalog.DEFAULT_ROOM
var room_state: Dictionary = {}
var background: TextureRect
var background_material: ShaderMaterial
var room_title: Label
var room_description: Label
var nora_portrait: Control
var nora_line: Label
var level_label: Label
var status_chip: Label
var apparatus_label: Label
var requirements_label: Label
var mission_bar: ProgressBar
var mastery_bar: ProgressBar
var repair_button: Button
var restoration_label: Label
var terminal_mount: Control
var terminal_visual: Node2D
var room_buttons: Dictionary = {}
var log_dialog: AcceptDialog

func _ready() -> void:
	controller = HubController.new()
	add_child(controller)
	save = GameSaveManager.new()
	save.load_save()
	rewards = RewardManager.new(save)
	narrative = NarrativeManager.new()
	narrative.setup(save)
	progress_report = LocalProgressReport.new()
	progress_report.setup(save)
	controller.setup(save)
	controller.state_changed.connect(_apply_state)
	controller.exam_requested.connect(_start_exam)
	content = ContentManager.new()
	_build_scene()
	_build_exercise_overlay()
	var gate := controller.progression.current_gate()
	current_room_id = ShipRoomCatalog.room_for_apparatus(str(gate.get("apparatus", "nucleo")))
	_apply_state(controller.state())
	var beat := narrative.reveal_level(save.level())
	nora_line.text = str(beat.get("text", nora_line.text))
	save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_environment", "night")
		audio.call("play", "panel.open")

func _build_scene() -> void:
	var ui := CanvasLayer.new()
	ui.name = "ShipUI"
	add_child(ui)

	var screen := Control.new()
	screen.name = "ShipScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen)

	background = TextureRect.new()
	background.name = "RoomBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_material = _room_shader_material()
	background.material = background_material
	screen.add_child(background)

	var atmosphere := ColorRect.new()
	atmosphere.name = "AtmosphereVeil"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.color = Color(0.01, 0.035, 0.055, 0.18)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(atmosphere)

	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 18)
	safe.add_theme_constant_override("margin_top", 16)
	safe.add_theme_constant_override("margin_right", 18)
	safe.add_theme_constant_override("margin_bottom", 16)
	screen.add_child(safe)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	safe.add_child(layout)
	_build_header(layout)
	_build_body(layout)

func _build_header(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "ShipHeader"
	panel.custom_minimum_size.y = 84
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.065, 0.085, 0.92), Color("6be7d6"), 16))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	nora_portrait = NORA_PORTRAIT_SCRIPT.new()
	nora_portrait.custom_minimum_size = Vector2(66, 66)
	row.add_child(nora_portrait)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 1)
	row.add_child(titles)
	room_title = Label.new()
	room_title.name = "RoomTitle"
	room_title.add_theme_font_size_override("font_size", 25)
	room_title.add_theme_color_override("font_color", Color("f5fbff"))
	titles.add_child(room_title)
	room_description = Label.new()
	room_description.add_theme_font_size_override("font_size", 13)
	room_description.add_theme_color_override("font_color", Color("b9d3d7"))
	titles.add_child(room_description)
	nora_line = Label.new()
	nora_line.name = "NoraShipLine"
	nora_line.text = "NORA: Seleziona un ponte. Ogni apparato conserva una parte della rotta."
	nora_line.add_theme_font_size_override("font_size", 12)
	nora_line.add_theme_color_override("font_color", Color("8ff6d2"))
	nora_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(nora_line)

	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color("f7d37a"))
	level_label.custom_minimum_size.x = 170
	row.add_child(level_label)

	var log_button := Button.new()
	log_button.name = "ShipLogButton"
	log_button.text = "DIARIO"
	log_button.custom_minimum_size = Vector2(104, 48)
	log_button.pressed.connect(_show_ship_log)
	row.add_child(log_button)

	var back_button := Button.new()
	back_button.name = "BackToWorldButton"
	back_button.text = "TORNA AL MONDO"
	back_button.custom_minimum_size = Vector2(176, 48)
	back_button.add_theme_font_size_override("font_size", 14)
	back_button.pressed.connect(_return_to_world)
	row.add_child(back_button)

func _build_body(parent: VBoxContainer) -> void:
	var body := HBoxContainer.new()
	body.name = "ShipBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	parent.add_child(body)

	var rail := PanelContainer.new()
	rail.name = "RoomRail"
	rail.custom_minimum_size.x = 210
	rail.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.05, 0.07, 0.90), Color("315b60"), 14))
	body.add_child(rail)
	var rail_margin := MarginContainer.new()
	rail_margin.add_theme_constant_override("margin_left", 10)
	rail_margin.add_theme_constant_override("margin_top", 12)
	rail_margin.add_theme_constant_override("margin_right", 10)
	rail_margin.add_theme_constant_override("margin_bottom", 12)
	rail.add_child(rail_margin)
	var rail_box := VBoxContainer.new()
	rail_box.add_theme_constant_override("separation", 6)
	rail_margin.add_child(rail_box)
	var rail_title := Label.new()
	rail_title.text = "PONTI DEL RELITTO"
	rail_title.add_theme_font_size_override("font_size", 13)
	rail_title.add_theme_color_override("font_color", Color("8fb7bd"))
	rail_box.add_child(rail_title)
	for id in ShipRoomCatalog.ids():
		var spec := ShipRoomCatalog.room(str(id))
		var button := Button.new()
		button.name = "RoomButton_%s" % str(id)
		button.text = str(spec.get("short", id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 45
		button.toggle_mode = true
		button.pressed.connect(_select_room.bind(str(id)))
		rail_box.add_child(button)
		room_buttons[str(id)] = button
	var rail_spacer := Control.new()
	rail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail_box.add_child(rail_spacer)
	var rail_hint := Label.new()
	rail_hint.text = "Ogni ponte riunisce più materie in un solo sistema coerente."
	rail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rail_hint.add_theme_font_size_override("font_size", 11)
	rail_hint.add_theme_color_override("font_color", Color("78999f"))
	rail_box.add_child(rail_hint)

	var stage_space := Control.new()
	stage_space.name = "RoomStage"
	stage_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(stage_space)

	var card := PanelContainer.new()
	card.name = "ApparatusCard"
	card.custom_minimum_size.x = 338
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.055, 0.075, 0.94), Color("6be7d6"), 16))
	body.add_child(card)
	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 18)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_right", 18)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(card_margin)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 8)
	card_margin.add_child(card_box)
	status_chip = Label.new()
	status_chip.name = "ApparatusState"
	status_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_chip.add_theme_font_size_override("font_size", 12)
	card_box.add_child(status_chip)
	terminal_mount = Control.new()
	terminal_mount.name = "TerminalMount"
	terminal_mount.custom_minimum_size = Vector2(280, 122)
	terminal_mount.resized.connect(_position_terminal)
	card_box.add_child(terminal_mount)
	apparatus_label = Label.new()
	apparatus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apparatus_label.add_theme_font_size_override("font_size", 20)
	card_box.add_child(apparatus_label)
	restoration_label = Label.new()
	restoration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_label.add_theme_font_size_override("font_size", 11)
	card_box.add_child(restoration_label)
	requirements_label = Label.new()
	requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirements_label.add_theme_font_size_override("font_size", 13)
	requirements_label.add_theme_color_override("font_color", Color("c6dce0"))
	card_box.add_child(requirements_label)
	mission_bar = ProgressBar.new()
	mission_bar.name = "MissionProgress"
	mission_bar.show_percentage = false
	mission_bar.custom_minimum_size.y = 12
	card_box.add_child(mission_bar)
	mastery_bar = ProgressBar.new()
	mastery_bar.name = "MasteryProgress"
	mastery_bar.min_value = 0
	mastery_bar.max_value = 100
	mastery_bar.show_percentage = false
	mastery_bar.custom_minimum_size.y = 12
	card_box.add_child(mastery_bar)
	var card_spacer := Control.new()
	card_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_box.add_child(card_spacer)
	repair_button = Button.new()
	repair_button.name = "RepairButton"
	repair_button.custom_minimum_size.y = 54
	repair_button.add_theme_font_size_override("font_size", 16)
	repair_button.pressed.connect(_repair_action)
	card_box.add_child(repair_button)

func _build_exercise_overlay() -> void:
	var exercise_layer := CanvasLayer.new()
	exercise_layer.name = "ExerciseLayer"
	exercise_layer.layer = 20
	add_child(exercise_layer)
	exercise_player = EXERCISE_PLAYER_SCRIPT.new()
	exercise_player.name = "ExercisePlayer"
	exercise_player.visible = false
	exercise_player.session_finished.connect(_on_exam_finished)
	exercise_layer.add_child(exercise_player)
	log_dialog = AcceptDialog.new()
	log_dialog.name = "ShipLogDialog"
	log_dialog.title = "DIARIO DI BORDO · SOLO LOCALE"
	log_dialog.min_size = Vector2i(620, 420)
	exercise_layer.add_child(log_dialog)

func _select_room(id: String) -> void:
	if not ShipRoomCatalog.ROOMS.has(id):
		return
	current_room_id = id
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "ui.select")
		var subjects: Array = ShipRoomCatalog.room(id).get("subjects", [])
		if not subjects.is_empty():
			audio.call("play_subject", str(subjects[0]))
	_apply_state(controller.state())
	nora_line.text = "NORA: %s" % str(room_state.get("description", "Sistema in ascolto."))
	if is_instance_valid(nora_portrait):
		nora_portrait.speak(nora_line.text)

func _apply_state(state: Dictionary) -> void:
	if background == null:
		return
	room_state = ShipRoomCatalog.room(current_room_id)
	var accent := Color(str(room_state.get("accent", "6be7d6")))
	background.texture = load(str(room_state.get("texture", ""))) as Texture2D
	background_material.set_shader_parameter("accent", accent)
	room_title.text = "NAVE · %s" % str(room_state.get("label", "Ponte Centrale")).to_upper()
	room_description.text = str(room_state.get("description", ""))
	level_label.text = "LIVELLO %d\nENERGIA %d" % [save.level(), save.energy()]
	for id in room_buttons:
		var button: Button = room_buttons[id]
		button.button_pressed = str(id) == current_room_id

	var current_gate := controller.progression.current_gate()
	var gate_apparatus := str(current_gate.get("apparatus", "nucleo"))
	var room_apparatus := str(room_state.get("apparatus", "nucleo"))
	var is_current_gate := room_apparatus == gate_apparatus
	var repaired_level := int(save.data.get("apparatus", {}).get(room_apparatus, {}).get("repairedLevel", 0))
	var terminal_state := "broken"
	if is_current_gate and bool(state.get("ready", false)):
		terminal_state = "ready"
	elif not is_current_gate and repaired_level > 0:
		terminal_state = "repaired"
	_replace_terminal(terminal_state, accent, room_apparatus)

	var restoration_id := str(room_state.get("restoration", ""))
	var restored := rewards.owned(restoration_id)
	background_material.set_shader_parameter("restored", 1.0 if restored else 0.0)
	restoration_label.text = "✦ RESTAURO ATTIVO" if restored else "RESTAURO DISPONIBILE IN BOTTEGA"
	restoration_label.add_theme_color_override("font_color", Color("f7d37a") if restored else Color("809da2"))
	status_chip.text = terminal_state.to_upper()
	status_chip.add_theme_color_override("font_color", accent if terminal_state != "broken" else Color("a5b0b3"))
	apparatus_label.text = room_apparatus.replace("-", " ").to_upper()

	if is_current_gate:
		var subject := str(current_gate.get("subject", "matematica"))
		var done := save.missions_of(subject)
		var required := int(current_gate.get("missionsRequired", 1))
		var mastery := save.mastery_of(subject)
		var threshold := float(current_gate.get("masteryThreshold", 0.7))
		requirements_label.text = "%s · Missioni %d/%d\nPadronanza %.0f%% / %.0f%%" % [subject.capitalize(), done, required, mastery * 100.0, threshold * 100.0]
		mission_bar.max_value = maxi(required, 1)
		mission_bar.value = done
		mastery_bar.value = mastery * 100.0
		repair_button.text = "AVVIA ESAME FINALE" if bool(state.get("ready", false)) else "COMPLETA LE MISSIONI NEL MONDO"
		repair_button.disabled = not bool(state.get("ready", false))
	else:
		var subjects := ", ".join(PackedStringArray(room_state.get("subjects", [])))
		requirements_label.text = "Materie del ponte: %s\nApparato corrente: %s" % [subjects, gate_apparatus.replace("-", " ").capitalize()]
		mission_bar.max_value = 1
		mission_bar.value = 1 if repaired_level > 0 else 0
		mastery_bar.value = 100 if repaired_level > 0 else 0
		repair_button.text = "VAI ALL'APPARATO CORRENTE"
		repair_button.disabled = false

func _replace_terminal(state: String, accent: Color, label: String) -> void:
	if is_instance_valid(terminal_visual):
		terminal_visual.free()
	terminal_visual = OutdoorVisualFactory.build_apparatus_terminal(state, accent, "")
	terminal_visual.name = "ApparatusTerminal"
	terminal_visual.scale = Vector2(1.8, 1.8)
	terminal_mount.add_child(terminal_visual)
	call_deferred("_position_terminal")

func _position_terminal() -> void:
	if is_instance_valid(terminal_visual) and is_instance_valid(terminal_mount):
		terminal_visual.position = Vector2(terminal_mount.size.x * 0.5, terminal_mount.size.y * 0.72)

func _repair_action() -> void:
	var gate := controller.progression.current_gate()
	var target_room := ShipRoomCatalog.room_for_apparatus(str(gate.get("apparatus", "nucleo")))
	if current_room_id != target_room:
		_select_room(target_room)
		return
	controller.request_exam()

func _start_exam() -> void:
	var gate := controller.progression.current_gate()
	var subject := str(gate.get("subject", "matematica"))
	var session := content.build_final_exam(subject, save.level(), 3, null, save.mastery_of(subject), save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		nora_line.text = "NORA: Banco esame non disponibile per %s." % subject
		return
	exercise_player.visible = true
	exercise_player.start_session(session)

func _on_exam_finished(exam_result: Dictionary) -> void:
	exercise_player.visible = false
	if bool(exam_result.get("passed", false)):
		controller.progression.repair_and_advance(true)
		progress_report.record(save.level(), str(exam_result.get("subject", "matematica")), save.mastery_of(str(exam_result.get("subject", "matematica"))), 1, float(exam_result.get("seconds", 0.0)))
		save.save()
		nora_line.text = str(narrative.reveal_level(save.level()).get("text", "NORA: Apparato riparato. Una nuova rotta è disponibile."))
	else:
		progress_report.record(save.level(), str(exam_result.get("subject", "matematica")), save.mastery_of(str(exam_result.get("subject", "matematica"))), 0, float(exam_result.get("seconds", 0.0)))
		nora_line.text = "NORA: La diagnosi resta valida. Torna quando vuoi e riprova."
	save.save()
	controller.refresh()
	_apply_state(controller.state())

func _show_ship_log() -> void:
	if not is_instance_valid(log_dialog):
		return
	var report := progress_report.summary()
	var lines := PackedStringArray([
		"NORA · MEMORIA DEL RELITTO",
		str(narrative.beat_for_level(save.level())),
		"",
		"PROGRESSO LOCALE",
		"Sessioni: %d   Missioni superate: %d   Tempo attivo: %d min" % [int(report.get("sessions", 0)), int(report.get("missions", 0)), int(float(report.get("seconds", 0.0)) / 60.0)],
		"",
		"Nessun dato viene inviato in rete.",
	])
	var recent: Array = report.get("events", [])
	for index in range(maxi(0, recent.size() - 5), recent.size()):
		var event: Dictionary = recent[index]
		lines.append("L%d · %s · padronanza %.0f%%" % [int(event.get("level", 1)), str(event.get("subject", "")).capitalize(), float(event.get("mastery", 0.0)) * 100.0])
	log_dialog.dialog_text = "\n".join(lines)
	log_dialog.popup_centered()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.open")

func _return_to_world() -> void:
	save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "portalOpened")
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not exercise_player.visible:
		_return_to_world()

func _room_shader_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 accent : source_color = vec4(0.42, 0.91, 0.84, 1.0);
uniform float restored : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float edge = smoothstep(0.30, 0.78, distance(UV, vec2(0.5)));
	float pulse = (sin(TIME * 0.72) * 0.5 + 0.5) * (0.012 + restored * 0.02);
	float base_light = mix(0.62, 0.92, restored);
	vec3 color = tex.rgb * base_light;
	color += accent.rgb * pulse;
	color *= 1.0 - edge * 0.48;
	COLOR = vec4(color, tex.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 10
	return style
