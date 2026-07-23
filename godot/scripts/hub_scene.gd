extends Node2D

## Nave nativa data-driven. I sette ponti condividono una sola scena/UI; dati,
## sfondo, apparato, restauro e materie arrivano da ShipRoomCatalog.

const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")
const NORA_PORTRAIT_SCRIPT := preload("res://scripts/ui/nora_portrait.gd")
const SHIP_POWER_OVERLAY_SCRIPT := preload("res://scripts/ui/ship_power_overlay.gd")
const KNOWLEDGE_CODEX_PANEL_SCRIPT := preload("res://scripts/ui/knowledge_codex_panel.gd")

var controller: HubController
var content: ContentManager
var save: GameSaveManager
var rewards: RewardManager
var narrative: NarrativeManager
var progress_report: LocalProgressReport
var exercise_player: ExercisePlayer
var knowledge_codex_panel: KnowledgeCodexPanel

var current_room_id := ShipRoomCatalog.DEFAULT_ROOM
var room_state: Dictionary = {}
var background: TextureRect
var background_material: ShaderMaterial
var power_overlay: ShipPowerOverlay
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
var activation_label: Label
var activation_segments: Label
var activation_bar: ProgressBar
var terminal_mount: Control
var terminal_visual: Node2D
var room_buttons: Dictionary = {}
var log_dialog: AcceptDialog
var celebration_root: Control
var celebration_flash: ColorRect
var celebration_panel: PanelContainer
var celebration_title: Label
var celebration_detail: Label
var world_map_overlay: Control
var world_map_grid: GridContainer
var world_map_summary: Label

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.eliScene = 'ship';")
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

	power_overlay = SHIP_POWER_OVERLAY_SCRIPT.new()
	power_overlay.name = "ShipPowerOverlay"
	power_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(power_overlay)

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
	_build_world_map_overlay(screen)

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
	log_button.text = "MANUALE"
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
	var world_map_button := Button.new()
	world_map_button.name = "WorldMapButton"
	world_map_button.text = "MAPPA DEI MONDI"
	world_map_button.custom_minimum_size.y = 48
	world_map_button.add_theme_font_size_override("font_size", 13)
	world_map_button.add_theme_color_override("font_color", Color("f7d37a"))
	world_map_button.pressed.connect(_show_world_map)
	rail_box.add_child(world_map_button)
	for id in ShipRoomCatalog.ids():
		var spec := ShipRoomCatalog.room(str(id))
		var button := Button.new()
		button.name = "RoomButton_%s" % str(id)
		button.text = str(spec.get("short", id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 45
		button.add_theme_font_size_override("font_size", 13)
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
	activation_label = Label.new()
	activation_label.name = "ActivationPhase"
	activation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activation_label.add_theme_font_size_override("font_size", 13)
	card_box.add_child(activation_label)
	activation_bar = ProgressBar.new()
	activation_bar.name = "ShipActivationProgress"
	activation_bar.min_value = 0
	activation_bar.max_value = 100
	activation_bar.show_percentage = false
	activation_bar.custom_minimum_size.y = 9
	card_box.add_child(activation_bar)
	activation_segments = Label.new()
	activation_segments.name = "ActivationSegments"
	activation_segments.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activation_segments.add_theme_font_size_override("font_size", 11)
	activation_segments.add_theme_color_override("font_color", Color("91aeb2"))
	card_box.add_child(activation_segments)
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

func _build_world_map_overlay(screen: Control) -> void:
	world_map_overlay = Control.new()
	world_map_overlay.name = "WorldMapOverlay"
	world_map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	world_map_overlay.visible = false
	screen.add_child(world_map_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.005, 0.018, 0.028, 0.88)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	world_map_overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.06
	panel.anchor_top = 0.06
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.94
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.055, 0.075, 0.98), Color("6be7d6"), 18))
	world_map_overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "MAPPA DEI MONDI"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f5fbff"))
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseWorldMapButton"
	close.text = "CHIUDI"
	close.custom_minimum_size = Vector2(112, 48)
	close.pressed.connect(_hide_world_map)
	header.add_child(close)
	world_map_summary = Label.new()
	world_map_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	world_map_summary.add_theme_font_size_override("font_size", 13)
	world_map_summary.add_theme_color_override("font_color", Color("9fd6d4"))
	column.add_child(world_map_summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	world_map_grid = GridContainer.new()
	world_map_grid.columns = 3
	world_map_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_map_grid.add_theme_constant_override("h_separation", 10)
	world_map_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(world_map_grid)

func _show_world_map() -> void:
	if not is_instance_valid(world_map_overlay):
		return
	_refresh_world_map()
	world_map_overlay.visible = true
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.open")

func _hide_world_map() -> void:
	if is_instance_valid(world_map_overlay):
		world_map_overlay.visible = false

func _refresh_world_map() -> void:
	for child in world_map_grid.get_children():
		world_map_grid.remove_child(child)
		child.queue_free()
	var frontier := clampi(save.level(), 1, WorldProfileCatalog.MAX_LEVEL)
	var selected := save.current_world()
	world_map_summary.text = "Frontiera didattica: mondo %d · Destinazione attuale: mondo %d\nI mondi completati restano visitabili senza perdere progressi o posizione." % [frontier, selected]
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var unlocked := save.is_world_unlocked(level)
		var status := _world_map_status(level, frontier, selected, unlocked)
		var button := Button.new()
		button.name = "WorldTravel_%02d" % level
		button.text = "%02d · %s\n%s · %s" % [
			level, str(profile.get("title", "")),
			str(profile.get("learningFocus", {}).get("subject", "")).capitalize(),
			status]
		button.custom_minimum_size = Vector2(220, 76)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 12)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not unlocked
		button.tooltip_text = "%s · %s · %s" % [
			str(profile.get("terrainFamily", "")).replace("-", " "),
			str(profile.get("topology", "")).replace("-", " "),
			str(profile.get("weather", "")).replace("-", " ")]
		if unlocked:
			button.pressed.connect(_travel_to_world.bind(level))
			button.add_theme_color_override(
				"font_color",
				Color("f7d37a") if level == selected else Color("d8f8f1") if level == frontier else Color("9fc4bb"))
		world_map_grid.add_child(button)

func _world_map_status(level: int, frontier: int, selected: int, unlocked: bool) -> String:
	if not unlocked:
		return "BLOCCATO"
	var bucket: Dictionary = save.data.get("worldProgress", {}).get(str(level), {})
	var has_activity := not Array(bucket.get("completedEncounterIds", [])).is_empty() or not Array(bucket.get("collectedTreasureIds", [])).is_empty()
	if level == selected and level == frontier:
		return "◎ CORRENTE" if has_activity else "◎ CORRENTE · NUOVO"
	if level == selected:
		return "◎ IN VISITA"
	if level < frontier:
		return "✓ COMPLETATO · RIVISITABILE"
	if level == frontier:
		return "NUOVO"
	return "SBLOCCATO"

func _travel_to_world(level: int) -> void:
	if not save.is_world_unlocked(level):
		return
	save.set_current_world(level)
	save.save()
	_hide_world_map()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "portalOpened")
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

func _build_exercise_overlay() -> void:
	var exercise_layer := CanvasLayer.new()
	exercise_layer.name = "ExerciseLayer"
	exercise_layer.layer = 20
	add_child(exercise_layer)
	exercise_player = EXERCISE_PLAYER_SCRIPT.new()
	exercise_player.name = "ExercisePlayer"
	exercise_player.visible = false
	exercise_player.session_finished.connect(_on_exam_finished)
	exercise_player.learning_signal.connect(_on_nora_learning_signal)
	exercise_layer.add_child(exercise_player)
	knowledge_codex_panel = KNOWLEDGE_CODEX_PANEL_SCRIPT.new()
	knowledge_codex_panel.setup(save, content)
	exercise_layer.add_child(knowledge_codex_panel)
	log_dialog = AcceptDialog.new()
	log_dialog.name = "ShipLogDialog"
	log_dialog.title = "DIARIO DI BORDO · SOLO LOCALE"
	log_dialog.min_size = Vector2i(620, 420)
	exercise_layer.add_child(log_dialog)
	_build_activation_celebration()

func _build_activation_celebration() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ActivationCelebrationLayer"
	layer.layer = 30
	add_child(layer)
	celebration_root = Control.new()
	celebration_root.name = "ActivationCelebration"
	celebration_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	celebration_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_root.visible = false
	layer.add_child(celebration_root)
	celebration_flash = ColorRect.new()
	celebration_flash.name = "ActivationFlash"
	celebration_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	celebration_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_root.add_child(celebration_flash)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_root.add_child(center)
	celebration_panel = PanelContainer.new()
	celebration_panel.name = "ActivationMilestone"
	celebration_panel.custom_minimum_size = Vector2(590, 176)
	center.add_child(celebration_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	celebration_panel.add_child(margin)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 8)
	margin.add_child(copy)
	var eyebrow := Label.new()
	eyebrow.text = "✦  PROTOCOLLO DI RIATTIVAZIONE  ✦"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 12)
	copy.add_child(eyebrow)
	celebration_title = Label.new()
	celebration_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celebration_title.add_theme_font_size_override("font_size", 30)
	copy.add_child(celebration_title)
	celebration_detail = Label.new()
	celebration_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celebration_detail.add_theme_font_size_override("font_size", 14)
	copy.add_child(celebration_detail)

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
	var activation := ShipActivationModel.activation_for_room(save, current_room_id)
	background.texture = load(str(room_state.get("texture", ""))) as Texture2D
	background_material.set_shader_parameter("accent", accent)
	background_material.set_shader_parameter("activation", float(activation.get("ratio", 0.0)))
	if is_instance_valid(power_overlay):
		power_overlay.set_activation(float(activation.get("ratio", 0.0)), int(activation.get("stage", 0)), accent)
	if is_instance_valid(nora_portrait) and nora_portrait.has_method("set_integrity"):
		nora_portrait.call("set_integrity", _nora_integrity_ratio(), false, NoraState.trust(save))
	room_title.text = "NAVE · %s" % str(room_state.get("label", "Ponte Centrale")).to_upper()
	room_description.text = str(room_state.get("description", ""))
	level_label.text = "LIVELLO %d\nENERGIA %d" % [save.level(), save.energy()]
	for id in room_buttons:
		var button: Button = room_buttons[id]
		var room_activation := ShipActivationModel.activation_for_room(save, str(id))
		var spec := ShipRoomCatalog.room(str(id))
		button.text = "%s  %s · %d%%" % [str(room_activation.get("short", "○")), str(spec.get("short", id)), int(room_activation.get("percent", 0))]
		button.tooltip_text = "%s — %s" % [str(spec.get("label", id)), str(room_activation.get("title", "SISTEMA INERTE"))]
		button.button_pressed = str(id) == current_room_id

	var current_gate := controller.progression.current_gate()
	var campaign_complete := controller.progression.is_complete()
	var gate_apparatus := str(current_gate.get("apparatus", "nucleo"))
	var room_apparatus := str(room_state.get("apparatus", "nucleo"))
	var gate_room_id := ShipRoomCatalog.room_for_apparatus(gate_apparatus)
	var is_current_gate := not campaign_complete and current_room_id == gate_room_id
	var terminal_state := "broken"
	if is_current_gate and bool(state.get("ready", false)):
		terminal_state = "ready"
	elif int(activation.get("completed", 0)) > 0:
		terminal_state = "repaired"
	var displayed_apparatus := gate_apparatus if is_current_gate else room_apparatus
	_replace_terminal(terminal_state, accent, displayed_apparatus)

	var restoration_id := str(room_state.get("restoration", ""))
	var restored := rewards.owned(restoration_id)
	background_material.set_shader_parameter("restored", 1.0 if restored else 0.0)
	restoration_label.text = "✦ RESTAURO ATTIVO" if restored else "RESTAURO DISPONIBILE IN BOTTEGA"
	restoration_label.add_theme_color_override("font_color", Color("f7d37a") if restored else Color("809da2"))
	status_chip.text = str(activation.get("title", "SISTEMA INERTE"))
	status_chip.add_theme_color_override("font_color", accent if int(activation.get("stage", 0)) > 0 else Color("a5b0b3"))
	apparatus_label.text = displayed_apparatus.replace("-", " ").to_upper()
	activation_label.text = "POTENZA DEL PONTE · %d%%" % int(activation.get("percent", 0))
	activation_label.add_theme_color_override("font_color", accent if int(activation.get("stage", 0)) > 0 else Color("84999d"))
	activation_bar.value = int(activation.get("percent", 0))
	activation_bar.add_theme_stylebox_override("background", _progress_style(Color(0.02, 0.055, 0.065, 0.92), 4))
	activation_bar.add_theme_stylebox_override("fill", _progress_style(Color(accent, 0.88), 4))
	activation_segments.text = "%s   %d/%d NODI" % [str(activation.get("segments", "")), int(activation.get("completed", 0)), int(activation.get("total", 0))]

	if is_current_gate:
		var subject := str(current_gate.get("subject", "matematica"))
		var done := save.missions_toward_gate(subject)
		var required := int(current_gate.get("missionsRequired", 1))
		var mastery := save.mastery_of(subject)
		var threshold := float(current_gate.get("masteryThreshold", 0.7))
		requirements_label.text = "%s · Missioni %d/%d\nPadronanza %.0f%% / %.0f%%" % [subject.capitalize(), done, required, mastery * 100.0, threshold * 100.0]
		mission_bar.max_value = maxi(required, 1)
		mission_bar.value = done
		mastery_bar.value = mastery * 100.0
		repair_button.text = "AVVIA ESAME FINALE" if bool(state.get("ready", false)) else "COMPLETA LE MISSIONI NEL MONDO"
		repair_button.disabled = not bool(state.get("ready", false))
	elif campaign_complete:
		var completed_subjects := ", ".join(PackedStringArray(room_state.get("subjects", [])))
		requirements_label.text = "Materie del ponte: %s\nTutti i nodi della nave sono operativi" % completed_subjects
		mission_bar.max_value = maxi(1, int(activation.get("total", 1)))
		mission_bar.value = int(activation.get("total", 1))
		mastery_bar.value = 100
		repair_button.text = "NAVE COMPLETAMENTE RIATTIVATA"
		repair_button.disabled = true
	else:
		var subjects := ", ".join(PackedStringArray(room_state.get("subjects", [])))
		requirements_label.text = "Materie del ponte: %s\nProssimo sistema: %s" % [subjects, gate_apparatus.replace("-", " ").capitalize()]
		mission_bar.max_value = maxi(1, int(activation.get("total", 1)))
		mission_bar.value = int(activation.get("completed", 0))
		mastery_bar.value = int(activation.get("percent", 0))
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
	if controller.progression.is_complete():
		return
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
	var repaired_gate := controller.progression.current_gate()
	var repaired_room := ShipRoomCatalog.room_for_apparatus(str(repaired_gate.get("apparatus", "nucleo")))
	var activation_before := ShipActivationModel.activation_for_room(save, repaired_room)
	if bool(exam_result.get("passed", false)):
		var advanced := controller.progression.repair_and_advance(true)
		if advanced:
			var subject := str(repaired_gate.get("subject", exam_result.get("subject", "matematica")))
			progress_report.record(int(repaired_gate.get("level", save.level())), subject, save.mastery_of(subject), 1, float(exam_result.get("seconds", 0.0)))
			save.save()
			current_room_id = repaired_room
			controller.refresh()
			_apply_state(controller.state())
			var activation_after := ShipActivationModel.activation_for_room(save, repaired_room)
			nora_line.text = str(narrative.reveal_level(save.level()).get("text", "NORA: Apparato riparato. Una nuova rotta è disponibile."))
			await _play_reactivation_sequence(repaired_room, activation_before, activation_after)
		else:
			nora_line.text = "NORA: Il protocollo non può essere applicato. Verifica i requisiti."
	else:
		progress_report.record(save.level(), str(exam_result.get("subject", "matematica")), save.mastery_of(str(exam_result.get("subject", "matematica"))), 0, float(exam_result.get("seconds", 0.0)))
		nora_line.text = "NORA: La diagnosi resta valida. Torna quando vuoi e riprova."
	save.save()
	controller.refresh()
	_apply_state(controller.state())

func _play_reactivation_sequence(room_id: String, before: Dictionary, after: Dictionary) -> void:
	if not is_instance_valid(celebration_root) or not is_instance_valid(background_material):
		return
	var spec := ShipRoomCatalog.room(room_id)
	var accent := Color(str(spec.get("accent", "6be7d6")))
	celebration_title.text = str(after.get("title", "SISTEMA RIATTIVATO"))
	celebration_title.add_theme_color_override("font_color", accent.lightened(0.20))
	celebration_detail.text = "%s · POTENZA %d%% · NODO %d/%d" % [
		str(spec.get("label", room_id)).to_upper(),
		int(after.get("percent", 0)),
		int(after.get("completed", 0)),
		int(after.get("total", 0)),
	]
	celebration_detail.add_theme_color_override("font_color", Color("d9f5ef"))
	celebration_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.035, 0.05, 0.97), accent, 18))
	celebration_root.visible = true
	celebration_flash.color = Color(accent, 0.72)
	celebration_panel.modulate = Color(1, 1, 1, 0)
	celebration_panel.scale = Vector2(0.82, 0.82)
	await get_tree().process_frame
	celebration_panel.pivot_offset = celebration_panel.size * 0.5
	background_material.set_shader_parameter("transition_burst", 1.0)
	if is_instance_valid(power_overlay):
		power_overlay.burst = 1.0
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "circuit.on", 1.0 + minf(float(after.get("stage", 1)) * 0.035, 0.14))
	var intro := create_tween().set_parallel(true)
	intro.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	intro.tween_property(celebration_flash, "color:a", 0.0, 1.15)
	intro.tween_property(celebration_panel, "modulate:a", 1.0, 0.28)
	intro.tween_property(celebration_panel, "scale", Vector2.ONE, 0.52)
	intro.tween_method(_set_activation_burst, 1.0, 0.0, 1.65)
	await intro.finished
	if int(after.get("stage", 0)) > int(before.get("stage", 0)):
		nora_line.text = "NORA: %s ha raggiunto la fase %s." % [str(spec.get("label", room_id)), str(after.get("title", "online")).to_lower()]
		if is_instance_valid(nora_portrait):
			nora_portrait.speak(nora_line.text)
	await get_tree().create_timer(0.72).timeout
	var outro := create_tween()
	outro.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	outro.tween_property(celebration_panel, "modulate:a", 0.0, 0.36)
	await outro.finished
	celebration_root.visible = false

func _set_activation_burst(value: float) -> void:
	background_material.set_shader_parameter("transition_burst", value)
	if is_instance_valid(power_overlay):
		power_overlay.burst = value

func _show_ship_log() -> void:
	if not is_instance_valid(knowledge_codex_panel):
		return
	var gate := controller.progression.current_gate()
	knowledge_codex_panel.open_codex(str(gate.get("subject", "")), "", "ship")

func _nora_integrity_ratio() -> float:
	NoraState.sync_from_progress(save)
	return NoraState.integrity(save)

func _on_nora_learning_signal(signal_name: String) -> void:
	NoraState.register(save, signal_name)
	save.save()

func _return_to_world() -> void:
	save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "portalOpened")
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible:
		return
	if event.is_action_pressed("ui_cancel") and not exercise_player.visible:
		if is_instance_valid(world_map_overlay) and world_map_overlay.visible:
			_hide_world_map()
		else:
			_return_to_world()

func _room_shader_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 accent : source_color = vec4(0.42, 0.91, 0.84, 1.0);
uniform float restored : hint_range(0.0, 1.0) = 0.0;
uniform float activation : hint_range(0.0, 1.0) = 0.0;
uniform float transition_burst : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float edge = smoothstep(0.30, 0.78, distance(UV, vec2(0.5)));
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float powered = smoothstep(0.0, 0.82, activation);
	float pulse = (sin(TIME * (0.72 + activation * 1.4)) * 0.5 + 0.5);
	float unstable = (1.0 - smoothstep(0.05, 0.28, activation)) * activation;
	float flicker = 1.0 - unstable * (sin(TIME * 17.0) * 0.035 + 0.035);
	float base_light = mix(0.42, 0.96, powered) + restored * 0.06;
	vec3 dormant = mix(vec3(luma), tex.rgb, 0.38);
	vec3 color = mix(dormant, tex.rgb, powered) * base_light * flicker;
	float highlight = smoothstep(0.34, 0.82, luma);
	color += accent.rgb * highlight * (0.025 + powered * 0.15);
	float scan = 1.0 - smoothstep(0.0, 0.018, abs(fract(UV.y - TIME * (0.035 + activation * 0.05)) - 0.5));
	color += accent.rgb * scan * activation * 0.055;
	color += accent.rgb * pulse * (activation * 0.018 + restored * 0.018);
	float ignition = transition_burst * (1.0 - smoothstep(0.0, 0.72, distance(UV, vec2(0.5))));
	color += accent.rgb * ignition * 0.85;
	color *= 1.0 - edge * mix(0.58, 0.32, powered);
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

func _progress_style(fill: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	return style
