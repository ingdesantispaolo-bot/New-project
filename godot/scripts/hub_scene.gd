extends Node2D

## Nave nativa data-driven. I sette ponti condividono una sola scena/UI; dati,
## sfondo, apparato, restauro e materie arrivano da ShipRoomCatalog.

const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")
const NORA_PORTRAIT_SCRIPT := preload("res://scripts/ui/nora_portrait.gd")
const SHIP_POWER_OVERLAY_SCRIPT := preload("res://scripts/ui/ship_power_overlay.gd")
const KNOWLEDGE_CODEX_PANEL_SCRIPT := preload("res://scripts/ui/knowledge_codex_panel.gd")
const DIALOGUE_BOX_SCRIPT := preload("res://scripts/ui/dialogue_box.gd")
const FINALE_CATALOG := preload("res://scripts/game/finale_catalog.gd")
const SISTERS_THREAD := preload("res://scripts/game/sisters_thread.gd")
const STANCE_CHOICES := preload("res://scripts/game/stance_choices.gd")
const SHIP_BRIDGE_WALKWAY_SCRIPT := preload("res://scripts/visual/ship_bridge_walkway.gd")
const PET_FACE_WIDGET_SCRIPT := preload("res://scripts/ui/pet_face_widget.gd")
const PET_SCREEN_SCRIPT := preload("res://scripts/ui/pet_screen.gd")
const SHIP_ROOM_SHADER: Shader = preload("res://shaders/ship_room.gdshader")

var controller: HubController
var content: ContentManager
var save: GameSaveManager
var rewards: RewardManager
var narrative: NarrativeManager
var progress_report: LocalProgressReport
var exercise_player: ExercisePlayer
var knowledge_codex_panel: KnowledgeCodexPanel

## I dodici colori del nucleo prismatico. Sono gli stessi con cui i mondi
## tingono la notte e con cui le palestre si riconoscono da lontano: dal
## 21 agosto 2026 la tabella e' una sola, in [[SubjectPalette]]. Perche' il
## nucleo sia il «ritratto» che la bottega promette, il colore di una materia
## deve essere lo stesso in tutti i posti in cui quella materia compare.

var current_room_id := ShipRoomCatalog.DEFAULT_ROOM
var ui_layer: CanvasLayer
var pause_menu: PauseMenuPanel
var room_state: Dictionary = {}
var background: TextureRect
var background_material: ShaderMaterial
var power_overlay: ShipPowerOverlay
var room_title: Label
var room_description: Label
var nora_portrait: Control
var pet_face: Control
var pet_screen: Control
var _pet_cuddles_this_session := 0
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
var bridge_walkway: ShipBridgeWalkway
var room_stage: Control
var room_buttons: Dictionary = {}
var room_rail_title: Label
var log_dialog: AcceptDialog
var celebration_root: Control
var celebration_flash: ColorRect
var celebration_top_bar: ColorRect
var celebration_bottom_bar: ColorRect
var celebration_panel: PanelContainer
var celebration_eyebrow: Label
var celebration_title: Label
var celebration_detail: Label
var world_map_overlay: Control
var world_map_grid: GridContainer
var world_map_summary: Label
var launch_save_override: Dictionary = {}
var release_smoke_exam_button: Button
var finale_dialogue_box: DialogueBox
var finale_sequence: Array = []
var finale_sequence_index := 0
var finale_choice_panel: Control
var finale_choice_buttons: VBoxContainer
var finale_cattedra_entries := 0
var finale_choice_committed := false
var finale_confronto_sequence: Array = []
var finale_confronto_index := 0
var finale_confronto_active := false
var finale_confronto_closing := false
var finale_confronto_skip_button: Button

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.eliScene = 'ship';")
	controller = HubController.new()
	add_child(controller)
	save = GameSaveManager.new()
	save.load_save()
	if not launch_save_override.is_empty():
		save.data = save.migrate_legacy_save(launch_save_override)
	rewards = RewardManager.new(save)
	narrative = NarrativeManager.new()
	narrative.setup(save)
	progress_report = LocalProgressReport.new()
	progress_report.setup(save)
	controller.setup(save)
	controller.state_changed.connect(_apply_state)
	controller.exam_requested.connect(_start_exam)
	content = ContentManager.new()
	# Anche l'esame della nave pesca dalle prove ancora da risolvere: un esame che
	# ripropone le domande già superate misura la memoria dell'ultima sessione.
	content.solved_by_subject = save.solved_index()
	_build_scene()
	_build_exercise_overlay()
	var gate := controller.progression.current_gate()
	current_room_id = ShipRoomCatalog.room_for_apparatus(str(gate.get("apparatus", "nucleo")))
	_apply_state(controller.runtime_state())
	var beat := narrative.reveal_level(save.level())
	nora_line.text = str(beat.get("text", nora_line.text))
	save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_environment", "night")
		audio.call("play", "panel.open")
	call_deferred("_publish_release_smoke_hub_state")

func _publish_release_smoke_hub_state() -> void:
	if not NativeWorldState.release_smoke_enabled() or not is_instance_valid(repair_button):
		return
	var rect := repair_button.get_global_rect()
	JavaScriptBridge.eval("window.__eliShipState = %s;" % JSON.stringify({
		"level": save.level(),
		"examReady": not repair_button.disabled,
		"viewportWidth": get_viewport_rect().size.x,
		"viewportHeight": get_viewport_rect().size.y,
		"repairButton": {
			"x": rect.position.x,
			"y": rect.position.y,
			"width": rect.size.x,
			"height": rect.size.y,
		},
	}))

func _build_scene() -> void:
	var ui := CanvasLayer.new()
	ui.name = "ShipUI"
	add_child(ui)
	# Tenuto: la pausa nasce quando serve e deve poterci salire sopra.
	ui_layer = ui

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
	pet_face = PET_FACE_WIDGET_SCRIPT.new()
	pet_face.name = "ShipPetFaceWidget"
	pet_face.cuddled.connect(_on_pet_cuddled)
	pet_face.screen_requested.connect(_open_pet_screen)
	row.add_child(pet_face)
	_refresh_pet_face()

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 1)
	row.add_child(titles)
	room_title = Label.new()
	room_title.name = "RoomTitle"
	room_title.add_theme_font_size_override("font_size", 22)
	room_title.add_theme_color_override("font_color", Color("f5fbff"))
	titles.add_child(room_title)
	room_description = Label.new()
	room_description.add_theme_font_size_override("font_size", 12)
	room_description.add_theme_color_override("font_color", Color("b9d3d7"))
	titles.add_child(room_description)
	nora_line = Label.new()
	nora_line.name = "NoraShipLine"
	nora_line.text = "NORA: Seleziona un ponte. Ogni apparato conserva una parte della rotta."
	nora_line.add_theme_font_size_override("font_size", 11)
	nora_line.add_theme_color_override("font_color", Color("8ff6d2"))
	nora_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(nora_line)

	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color("f7d37a"))
	level_label.custom_minimum_size.x = 96
	row.add_child(level_label)

	# **Il ritorno al menu.** (6 agosto 2026)
	#
	# Fino a oggi non esisteva: mondo → nave → mondo, e il menu principale si
	# rivedeva solo riavviando l'applicazione. Chi voleva cambiare giocatore,
	# guardare il registro dei progressi o ricominciare doveva chiudere il gioco
	# — su tablet, dove un'applicazione non si chiude quasi mai davvero, questo
	# significava «non si può».
	#
	# Sta qui e non nel mondo di proposito: la nave è la base a cui si torna da
	# ogni mondo, ed è il posto in cui ci si ferma. Un'uscita in mezzo a una
	# passeggiata sarebbe una porta di troppo accanto a una prova.
	# **Dal 21 agosto 2026 apre la pausa invece di uscire.** Il pulsante
	# prometteva gia' tre cose nel suo tooltip e ne faceva una sola: portava
	# fuori. Adesso le tre cose ci sono davvero, e sono le stesse che si
	# trovano nel mondo aperto, nello stesso ordine.
	var menu_button := Button.new()
	menu_button.name = "MainMenuButton"
	menu_button.text = "PAUSA"
	menu_button.tooltip_text = "Riavvia il mondo, cambia giocatore, torna al menu"
	menu_button.custom_minimum_size = Vector2(92, 48)
	menu_button.add_theme_font_size_override("font_size", 12)
	menu_button.pressed.connect(_apri_pausa)
	row.add_child(menu_button)

	var log_button := Button.new()
	log_button.name = "ShipLogButton"
	log_button.text = "MANUALE"
	log_button.custom_minimum_size = Vector2(92, 48)
	log_button.add_theme_font_size_override("font_size", 12)
	log_button.pressed.connect(_show_ship_log)
	row.add_child(log_button)

	var back_button := Button.new()
	back_button.name = "BackToWorldButton"
	back_button.text = "TORNA AL MONDO"
	back_button.custom_minimum_size = Vector2(140, 48)
	back_button.add_theme_font_size_override("font_size", 12)
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
	room_rail_title = Label.new()
	room_rail_title.text = "PONTI DEL RELITTO"
	room_rail_title.add_theme_font_size_override("font_size", 13)
	room_rail_title.add_theme_color_override("font_color", Color("8fb7bd"))
	rail_box.add_child(room_rail_title)
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

	room_stage = Control.new()
	room_stage.name = "RoomStage"
	room_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_stage.clip_contents = true
	room_stage.resized.connect(_position_bridge_walkway)
	body.add_child(room_stage)
	bridge_walkway = SHIP_BRIDGE_WALKWAY_SCRIPT.new()
	bridge_walkway.room_entered.connect(_on_bridge_room_entered)
	room_stage.add_child(bridge_walkway)
	var accessibility: Dictionary = save.data.get("accessibility", {}) if is_instance_valid(save) else {}
	bridge_walkway.configure({}, bool(accessibility.get("reducedMotion", false)))
	call_deferred("_position_bridge_walkway")

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
		return "o CORRENTE" if has_activity else "o CORRENTE · NUOVO"
	if level == selected:
		return "o IN VISITA"
	if level < frontier:
		return "√ COMPLETATO · RIVISITABILE"
	if level == frontier:
		return "NUOVO"
	return "SBLOCCATO"

func _travel_to_world(level: int) -> void:
	if not save.is_world_unlocked(level):
		return
	save.set_current_world(level)
	save.save()
	_hide_world_map()
	_stage_world_launch("ship-map")
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
	exercise_player.pre_synthesis_requested.connect(_start_finale_confronto)
	exercise_layer.add_child(exercise_player)
	knowledge_codex_panel = KNOWLEDGE_CODEX_PANEL_SCRIPT.new()
	knowledge_codex_panel.setup(save, content)
	exercise_layer.add_child(knowledge_codex_panel)
	pet_screen = PET_SCREEN_SCRIPT.new()
	pet_screen.name = "ShipPetScreen"
	pet_screen.closed.connect(_on_pet_screen_closed)
	pet_screen.customization_changed.connect(_on_pet_customization_changed)
	exercise_layer.add_child(pet_screen)
	var accessibility: Dictionary = save.data.get("accessibility", {})
	pet_screen.configure(
		save,
		bool(accessibility.get("highContrast", false)),
		bool(accessibility.get("reducedMotion", false)))
	log_dialog = AcceptDialog.new()
	log_dialog.name = "ShipLogDialog"
	log_dialog.title = "DIARIO DI BORDO · SOLO LOCALE"
	log_dialog.min_size = Vector2i(620, 420)
	exercise_layer.add_child(log_dialog)
	_build_finale_overlay(exercise_layer)
	if NativeWorldState.release_smoke_enabled():
		release_smoke_exam_button = Button.new()
		release_smoke_exam_button.name = "ReleaseSmokeCompleteExam"
		release_smoke_exam_button.text = "COLLAUDO · COMPLETA ESAME"
		release_smoke_exam_button.anchor_left = 0.5
		release_smoke_exam_button.anchor_right = 0.5
		release_smoke_exam_button.anchor_top = 1.0
		release_smoke_exam_button.anchor_bottom = 1.0
		release_smoke_exam_button.offset_left = -170.0
		release_smoke_exam_button.offset_right = 170.0
		release_smoke_exam_button.offset_top = -74.0
		release_smoke_exam_button.offset_bottom = -18.0
		release_smoke_exam_button.custom_minimum_size.y = 56.0
		release_smoke_exam_button.visible = false
		release_smoke_exam_button.pressed.connect(_complete_release_smoke_exam)
		exercise_layer.add_child(release_smoke_exam_button)
	_build_activation_celebration()

func _build_finale_overlay(parent: CanvasLayer) -> void:
	finale_choice_panel = Control.new()
	finale_choice_panel.name = "FinaleChoicePanel"
	finale_choice_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finale_choice_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	finale_choice_panel.visible = false
	parent.add_child(finale_choice_panel)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.005, 0.02, 0.035, 0.90)
	finale_choice_panel.add_child(veil)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.16
	panel.anchor_right = 0.84
	panel.anchor_top = 0.14
	panel.anchor_bottom = 0.86
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.045, 0.065, 0.98), Color("f7d37a"), 18))
	finale_choice_panel.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.name = "FinaleChoiceQuestion"
	title.text = str((ThirteenthCatalog.SCELTA as Dictionary).get("domanda", ""))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f7d37a"))
	column.add_child(title)
	finale_choice_buttons = VBoxContainer.new()
	finale_choice_buttons.name = "FinaleChoiceButtons"
	finale_choice_buttons.add_theme_constant_override("separation", 12)
	column.add_child(finale_choice_buttons)
	for raw_option in Array((ThirteenthCatalog.SCELTA as Dictionary).get("opzioni", [])):
		var option: Dictionary = raw_option
		var button := Button.new()
		button.text = str(option.get("titolo", option.get("id", "")))
		button.tooltip_text = str(option.get("conseguenza", ""))
		button.custom_minimum_size = Vector2(0, 72)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_on_finale_choice.bind(str(option.get("id", ""))))
		finale_choice_buttons.add_child(button)
	finale_dialogue_box = DIALOGUE_BOX_SCRIPT.new()
	finale_dialogue_box.name = "FinaleDialogueBox"
	finale_dialogue_box.dialogue_closed.connect(_on_finale_dialogue_closed)
	parent.add_child(finale_dialogue_box)
	finale_confronto_skip_button = Button.new()
	finale_confronto_skip_button.name = "FinaleConfrontoSkip"
	finale_confronto_skip_button.text = "SALTA CONVERSAZIONE"
	finale_confronto_skip_button.tooltip_text = "Prosegui direttamente al nodo di sintesi"
	finale_confronto_skip_button.anchor_left = 0.72
	finale_confronto_skip_button.anchor_right = 0.94
	finale_confronto_skip_button.anchor_top = 0.06
	finale_confronto_skip_button.anchor_bottom = 0.06
	finale_confronto_skip_button.offset_bottom = 48.0
	finale_confronto_skip_button.add_theme_font_size_override("font_size", 15)
	finale_confronto_skip_button.visible = false
	finale_confronto_skip_button.pressed.connect(_skip_finale_confronto)
	finale_dialogue_box.add_child(finale_confronto_skip_button)

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
	celebration_top_bar = ColorRect.new()
	celebration_top_bar.name = "CinematicTopBar"
	celebration_top_bar.anchor_right = 1.0
	celebration_top_bar.anchor_bottom = 0.085
	celebration_top_bar.color = Color(0.002, 0.012, 0.02, 0.0)
	celebration_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_root.add_child(celebration_top_bar)
	celebration_bottom_bar = ColorRect.new()
	celebration_bottom_bar.name = "CinematicBottomBar"
	celebration_bottom_bar.anchor_top = 0.915
	celebration_bottom_bar.anchor_right = 1.0
	celebration_bottom_bar.anchor_bottom = 1.0
	celebration_bottom_bar.color = Color(0.002, 0.012, 0.02, 0.0)
	celebration_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_root.add_child(celebration_bottom_bar)
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
	celebration_eyebrow = Label.new()
	celebration_eyebrow.text = "*  PROTOCOLLO DI RIATTIVAZIONE  *"
	celebration_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celebration_eyebrow.add_theme_font_size_override("font_size", 12)
	copy.add_child(celebration_eyebrow)
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
	_apply_state(controller.runtime_state())
	nora_line.text = "NORA: %s" % str(room_state.get("description", "Sistema in ascolto."))
	if is_instance_valid(nora_portrait):
		nora_portrait.speak(nora_line.text)

func _on_bridge_room_entered(room_id: String, _subject: String) -> void:
	_select_room(room_id)

func _position_bridge_walkway() -> void:
	if not is_instance_valid(room_stage) or not is_instance_valid(bridge_walkway):
		return
	bridge_walkway.position = room_stage.size * 0.5
	var fit := minf(room_stage.size.x / 720.0, room_stage.size.y / 460.0)
	bridge_walkway.scale = Vector2.ONE * clampf(fit * 0.94, 0.42, 1.25)

func _apply_state(state: Dictionary) -> void:
	if background == null:
		return
	_refresh_pet_face()
	room_state = ShipRoomCatalog.room(current_room_id)
	var accent := Color(str(room_state.get("accent", "6be7d6")))
	var runtime_rooms: Dictionary = state.get("rooms", {})
	var activation: Dictionary = runtime_rooms.get(current_room_id, {})
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
		var room_activation: Dictionary = runtime_rooms.get(str(id), {})
		var spec := ShipRoomCatalog.room(str(id))
		button.text = "%s  %s · %d%%" % [str(room_activation.get("short", "o")), str(spec.get("short", id)), int(room_activation.get("percent", 0))]
		button.tooltip_text = "%s — %s" % [str(spec.get("label", id)), str(room_activation.get("title", "SISTEMA INERTE"))]
		button.button_pressed = str(id) == current_room_id
	if is_instance_valid(bridge_walkway):
		bridge_walkway.set_room_states(runtime_rooms)

	var current_gate := controller.progression.current_gate()
	var campaign_complete := controller.progression.is_complete()
	if is_instance_valid(room_rail_title):
		room_rail_title.text = "SISTEMI DELLA NAVE" if campaign_complete else "PONTI DEL RELITTO"
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
	# Il restauro è l'unica spesa che cambia un luogo per sempre: se non c'è, la
	# scheda dice quanto costa invece di dire soltanto dove si compra. Un prezzo
	# è un obiettivo; «disponibile in bottega» era un'insegna.
	var restoration_item := RewardCatalog.find(restoration_id)
	restoration_label.text = "* RESTAURO ATTIVO" if restored 		else "RESTAURO · ◊ %d IN BOTTEGA" % int(restoration_item.get("cost", 0))
	restoration_label.add_theme_color_override("font_color", Color("f7d37a") if restored else Color("809da2"))
	_refresh_restoration_lights(restored, accent)
	_refresh_prismatic_portrait()
	status_chip.text = str(activation.get("title", "SISTEMA INERTE"))
	status_chip.add_theme_color_override("font_color", accent if int(activation.get("stage", 0)) > 0 else Color("a5b0b3"))
	apparatus_label.text = displayed_apparatus.replace("-", " ").to_upper()
	activation_label.text = "POTENZA DEL PONTE · %d%%" % int(activation.get("percent", 0))
	activation_label.add_theme_color_override("font_color", accent if int(activation.get("stage", 0)) > 0 else Color("84999d"))
	activation_bar.value = int(activation.get("percent", 0))
	activation_bar.add_theme_stylebox_override("background", _progress_style(Color(0.02, 0.055, 0.065, 0.92), 4))
	activation_bar.add_theme_stylebox_override("fill", _progress_style(Color(accent, 0.88), 4))
	activation_segments.text = "%s   %d/%d PARTI ATTIVE" % [str(activation.get("segments", "")), int(activation.get("completed", 0)), int(activation.get("total", 0))]

	if is_current_gate:
		var subject := ApparatusConfig.world_subject(save.level())
		var mastery := save.mastery_of(subject)
		var threshold := float(current_gate.get("masteryThreshold", 0.7))
		# La barra riassume le dodici materie: sono quelle che aprono il livello.
		# La padronanza della materia della stanza apre l'apparato.
		#
		# Si chiede alla progressione invece che a `GateReadiness` direttamente: la
		# valutazione ha bisogno del conteggio degli argomenti proponibili per
		# materia, e chi la interroga a mano lo dimentica — la copertura ripiega
		# allora sul minimo assoluto e il terminale mostra un numero più generoso
		# di quello vero.
		var core := controller.progression.readiness()
		var in_linea := ApparatusConfig.SUBJECT_CYCLE.size() - Array(core.get("missing", [])).size()
		# Già superata a questo livello: il terminale non deve mandare a rifare
		# missioni per una materia chiusa. Era la scritta che compariva, ed è
		# peggio di un pulsante spento — dice di rifare una cosa già fatta.
		var certificata := GateReadiness.certified_at_level(save, subject)
		requirements_label.text = (
			"%s · superata a questo livello\n%d materie su %d in linea" % [
				subject.capitalize(), in_linea, ApparatusConfig.SUBJECT_CYCLE.size()]
			if certificata
			else "%s · preparazione %.0f%% / %.0f%%\n%d materie su %d in linea" % [
				subject.capitalize(), mastery * 100.0, threshold * 100.0,
				in_linea, ApparatusConfig.SUBJECT_CYCLE.size()])
		mission_bar.max_value = 100
		mission_bar.value = float(core["progress"]) * 100.0
		mastery_bar.value = mastery * 100.0
		if bool(state.get("ready", false)):
			repair_button.text = "AVVIA LA SFIDA FINALE"
		elif certificata:
			repair_button.text = "APPARATO GIÀ ACCESO"
		else:
			repair_button.text = "COMPLETA LE MISSIONI NEL MONDO"
		repair_button.disabled = not bool(state.get("ready", false))
	elif campaign_complete:
		var completed_subjects := ", ".join(PackedStringArray(room_state.get("subjects", [])))
		requirements_label.text = "Materie del ponte: %s\nTutte le parti della nave sono operative" % completed_subjects
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
	var session: Dictionary
	if save.level() >= ApparatusConfig.MAX_LEVEL:
		# Il Cuore accende dodici sistemi: senza dodici stanze la prova sarebbe
		# impossibile. Meglio non aprirla e dire cosa manca.
		if not controller.progression.can_open_heart():
			var missing: Array = controller.progression.missing_apparatus_subjects()
			var names: Array = []
			for missing_subject in missing:
				names.append(str(missing_subject).capitalize())
			nora_line.text = (
				"NORA: Il Cuore accende dodici sistemi, e %d sono ancora spenti. "
				% missing.size()
				+ "Mancano: %s." % ", ".join(PackedStringArray(names)))
			return
		var mastery_by_subject: Dictionary = {}
		for system_subject in ApparatusConfig.SUBJECT_CYCLE:
			mastery_by_subject[str(system_subject)] = save.mastery_of(str(system_subject))
		session = content.build_final_transversal_exam(save.level(), null, mastery_by_subject)
	else:
		session = content.build_final_exam(subject, save.level(), 3, null, save.mastery_of(subject), save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		nora_line.text = "NORA: La sfida di %s non è ancora pronta." % subject
		return
	exercise_player.visible = true
	exercise_player.start_session(session)
	if is_instance_valid(release_smoke_exam_button):
		release_smoke_exam_button.visible = true
		JavaScriptBridge.eval("document.documentElement.dataset.eliExam = 'open';")

func _complete_release_smoke_exam() -> void:
	if not NativeWorldState.release_smoke_enabled() or not exercise_player.visible:
		return
	release_smoke_exam_button.visible = false
	JavaScriptBridge.eval("delete document.documentElement.dataset.eliExercise;")
	var subject := str(exercise_player.session.get("subject", "matematica"))
	var transversal := bool(exercise_player.session.get("transversal", false))
	var total := Array(exercise_player.session.get("nodes", [])).size()
	_on_exam_finished({
		"kind": "final_exam",
		"subject": subject,
		"correct": total if transversal else 3,
		"total": total if transversal else 3,
		"passed": true,
		"systemsResolved": Array(ApparatusConfig.SUBJECT_CYCLE).duplicate() if transversal else [],
		"synthesisResolved": transversal,
		"energyGained": 30,
		"seconds": 1.0,
		"topicStats": {},
	})

func _on_exam_finished(exam_result: Dictionary) -> void:
	exercise_player.visible = false
	# Le prove superate escono dal giro comunque, esame passato o no: è un fatto
	# dello studente, non dell'esito. Prima di ogni ramo, come nel mondo aperto.
	save.remember_solved_map(Dictionary(exam_result.get("solved", {})))
	var completed_finale := false
	var exam_passed := bool(exam_result.get("passed", false))
	if save.level() >= ApparatusConfig.MAX_LEVEL:
		exam_passed = exam_passed and bool(exam_result.get("synthesisResolved", false))
	# La stanza riparata è quella della materia che abita il mondo corrente.
	var repaired_subject := ApparatusConfig.world_subject(save.level())
	var repaired_gate := ApparatusConfig.apparatus_gate(repaired_subject, save.level())
	var repaired_room := ShipRoomCatalog.room_for_apparatus(str(repaired_gate.get("apparatus", "nucleo")))
	var state_before := controller.runtime_state()
	var activation_before: Dictionary = Dictionary(state_before.get("rooms", {})).get(repaired_room, {})
	if exam_passed:
		var advanced := controller.progression.repair_and_advance(true)
		if advanced:
			var subject := str(repaired_gate.get("subject", exam_result.get("subject", "matematica")))
			progress_report.record(int(repaired_gate.get("level", save.level())), subject, save.mastery_of(subject), 1, float(exam_result.get("seconds", 0.0)))
			save.save()
			current_room_id = repaired_room
			controller.refresh()
			var state_after := controller.runtime_state()
			_apply_state(state_after)
			var activation_after: Dictionary = Dictionary(state_after.get("rooms", {})).get(repaired_room, {})
			nora_line.text = str(narrative.reveal_level(save.level()).get("text", "NORA: Apparato riparato. Una nuova rotta è disponibile."))
			_pet_react("apparatus_repaired")
			await _play_reactivation_sequence(repaired_room, activation_before, activation_after)
			if controller.progression.is_complete():
				NoraState.sync_from_progress(save)
				completed_finale = bool(exam_result.get("synthesisResolved", false))
		else:
			nora_line.text = "NORA: Il protocollo non può essere applicato. Verifica i requisiti."
	else:
		progress_report.record(save.level(), str(exam_result.get("subject", "matematica")), save.mastery_of(str(exam_result.get("subject", "matematica"))), 0, float(exam_result.get("seconds", 0.0)))
		nora_line.text = "NORA: La diagnosi resta valida. Torna quando vuoi e riprova."
	save.save()
	controller.refresh()
	_apply_state(controller.state())
	if completed_finale:
		_start_finale_epilogue()
	if NativeWorldState.release_smoke_enabled():
		JavaScriptBridge.eval(
			"document.documentElement.dataset.eliExam = %s;" %
			JSON.stringify("passed" if exam_passed else "failed")
		)
		call_deferred("_publish_release_smoke_hub_state")

func _start_finale_epilogue() -> void:
	if not is_instance_valid(finale_dialogue_box):
		return
	finale_sequence.clear()
	finale_sequence.append_array(Array((FINALE_CATALOG.CATTEDRA as Dictionary).get("scena", [])).duplicate(true))
	# La Cattedra ha appena assegnato il posto: prima che il nome torni, la nave
	# restituisce le due posizioni prese nei mondi 22 e 23. Sono righe vere della
	# sequenza, non una notifica laterale, e ciascuna porta con sé il marcatore
	# che la rende irripetibile solo quando viene davvero chiusa.
	for choice_id in ["meridiana-riga", "tredicesimo-domanda"]:
		var echo_entry := STANCE_CHOICES.eco_entry(save.data, choice_id)
		if not echo_entry.is_empty():
			finale_sequence.append(echo_entry)
	finale_cattedra_entries = finale_sequence.size()
	finale_sequence.append_array(Array((ThirteenthCatalog.RESTITUZIONE as Dictionary).get("scena", [])).duplicate(true))
	finale_sequence_index = 0
	finale_choice_committed = false
	set_meta("finale_epilogue_phase", "cattedra")
	_show_finale_sequence_entry()

## Il confronto avviene DENTRO la prova finale, dopo i dodici sistemi e prima
## della sintesi. Non è parte dell'epilogo: non salva niente, non offre scelte e
## chiuderlo o saltarlo restituisce alla stessa sessione con lo stesso cursore.
func _start_finale_confronto() -> void:
	if finale_confronto_active:
		return
	if not is_instance_valid(finale_dialogue_box):
		exercise_player.resume_after_pre_synthesis()
		return
	finale_confronto_sequence = Array(SISTERS_THREAD.CONFRONTO).duplicate(true)
	var squad_echo := STANCE_CHOICES.eco_entry(save.data, "squadra-quaderno")
	if not squad_echo.is_empty():
		finale_confronto_sequence.append(squad_echo)
	if finale_confronto_sequence.is_empty():
		exercise_player.resume_after_pre_synthesis()
		return
	finale_confronto_index = 0
	finale_confronto_active = true
	set_meta("finale_confronto_phase", "dialogue")
	_show_finale_confronto_entry()

func _show_finale_confronto_entry() -> void:
	if not finale_confronto_active:
		return
	if finale_confronto_index >= finale_confronto_sequence.size():
		_finish_finale_confronto(false)
		return
	var entry: Dictionary = finale_confronto_sequence[finale_confronto_index]
	var speaker_id := str(entry.get("chi", ""))
	var speaker := "NORA" if speaker_id == "nora" else "Eli"
	var role := "Custode della nave" if speaker_id == "nora" else "Sorella dodicesima"
	var pages := Array(entry.get("dice", [])).duplicate()
	finale_dialogue_box.configure_accessibility(
		bool(save.data.get("accessibility", {}).get("highContrast", false)),
		bool(save.data.get("accessibility", {}).get("reducedMotion", false)))
	finale_dialogue_box.show_dialogue(speaker_id, speaker, role, pages)
	finale_confronto_skip_button.visible = true

func _skip_finale_confronto() -> void:
	if not finale_confronto_active:
		return
	_finish_finale_confronto(true)

func _finish_finale_confronto(skipped: bool) -> void:
	if not finale_confronto_active:
		return
	finale_confronto_active = false
	if is_instance_valid(finale_confronto_skip_button):
		finale_confronto_skip_button.visible = false
	if is_instance_valid(finale_dialogue_box) and finale_dialogue_box.visible:
		# `close_dialogue` emette in modo sincrono: il flag impedisce al consumer
		# dell'epilogo di scambiare questa chiusura per una riga della Cattedra.
		finale_confronto_closing = true
		finale_dialogue_box.close_dialogue()
		finale_confronto_closing = false
	if skipped:
		# Saltare salta anche l'eco: non deve inseguire il giocatore in un replay
		# futuro del finale. Rimane una scelta fatta, semplicemente non riletta.
		for entry in finale_confronto_sequence:
			_mark_stance_echo_from_entry(entry as Dictionary)
	set_meta("finale_confronto_phase", "skipped" if skipped else "complete")
	exercise_player.resume_after_pre_synthesis()

func _show_finale_sequence_entry() -> void:
	if finale_sequence_index >= finale_sequence.size():
		var narrative_state: Dictionary = save.data.get("narrative", {})
		var thirteenth_state: Dictionary = narrative_state.get("thirteenth", {})
		thirteenth_state["nameRestored"] = true
		narrative_state["thirteenth"] = thirteenth_state
		save.data["narrative"] = narrative_state
		save.save()
		set_meta("finale_epilogue_phase", "choice")
		finale_choice_panel.visible = true
		if finale_choice_buttons.get_child_count() > 0:
			(finale_choice_buttons.get_child(0) as Button).grab_focus()
		return
	if finale_sequence_index == finale_cattedra_entries:
		set_meta("finale_epilogue_phase", "restituzione")
	var entry: Dictionary = finale_sequence[finale_sequence_index]
	var speaker_id := str(entry.get("chi", ""))
	var pages := Array(entry.get("dice", [])).duplicate()
	finale_dialogue_box.configure_accessibility(
		bool(save.data.get("accessibility", {}).get("highContrast", false)),
		bool(save.data.get("accessibility", {}).get("reducedMotion", false)))
	finale_dialogue_box.show_dialogue(speaker_id, speaker_id.capitalize(), "", pages)

func _on_finale_dialogue_closed(_speaker_id: String) -> void:
	if finale_confronto_closing:
		return
	if finale_confronto_active:
		if finale_confronto_index < finale_confronto_sequence.size():
			_mark_stance_echo_from_entry(finale_confronto_sequence[finale_confronto_index])
		finale_confronto_index += 1
		_show_finale_confronto_entry()
		return
	if finale_choice_committed:
		set_meta("finale_epilogue_phase", "complete")
		return
	if finale_sequence_index < finale_sequence.size():
		_mark_stance_echo_from_entry(finale_sequence[finale_sequence_index])
	finale_sequence_index += 1
	_show_finale_sequence_entry()

func _mark_stance_echo_from_entry(entry: Dictionary) -> void:
	var choice_id := str(entry.get("stance_echo", ""))
	if choice_id == "":
		return
	STANCE_CHOICES.segna_eco_vista(save.data, choice_id)
	save.save()

func _on_finale_choice(option_id: String) -> void:
	var selected: Dictionary = {}
	for raw_option in Array((ThirteenthCatalog.SCELTA as Dictionary).get("opzioni", [])):
		var option: Dictionary = raw_option
		if str(option.get("id", "")) == option_id:
			selected = option
			break
	if selected.is_empty():
		return
	finale_choice_panel.visible = false
	var narrative_state: Dictionary = save.data.get("narrative", {})
	var thirteenth_state: Dictionary = narrative_state.get("thirteenth", {})
	thirteenth_state["finaleChoice"] = option_id
	thirteenth_state["nameRestored"] = true
	narrative_state["thirteenth"] = thirteenth_state
	save.data["narrative"] = narrative_state
	save.save()
	finale_choice_committed = true
	set_meta("finale_epilogue_phase", "choice_result")
	var pages := Array(selected.get("dice", [])).duplicate()
	pages.append(str(selected.get("conseguenza", "")))
	finale_dialogue_box.show_dialogue("tredicesimo", "tredicesimo".capitalize(), "", pages)

func _play_reactivation_sequence(room_id: String, before: Dictionary, after: Dictionary) -> void:
	if not is_instance_valid(celebration_root) or not is_instance_valid(background_material):
		return
	var spec := ShipRoomCatalog.room(room_id)
	var accent := Color(str(spec.get("accent", "6be7d6")))
	var final_activation := controller.progression.is_complete()
	var reduced := bool(save.data.get("accessibility", {}).get("reducedMotion", false))
	var cue_log: Array[String] = ["focus", "ignition", "reveal"]
	if final_activation:
		cue_log.append("finale")
	set_meta("last_milestone_kind", "finale" if final_activation else "ship_reactivation")
	set_meta("last_milestone_cues", cue_log)
	celebration_eyebrow.text = "*  CONVERGENZA DEI DODICI SISTEMI  *" if final_activation else "*  PROTOCOLLO DI RIATTIVAZIONE  *"
	celebration_title.text = "TUTTI I SISTEMI CONVERGONO" if final_activation else str(after.get("title", "SISTEMA RIATTIVATO"))
	celebration_title.add_theme_color_override("font_color", accent.lightened(0.20))
	celebration_detail.text = (
		"CUORE DEI PRIMI · 12/12 SISTEMI · NAVE A PIENA POTENZA"
		if final_activation
		else "%s · POTENZA %d%% · PARTE %d/%d" % [
			str(spec.get("label", room_id)).to_upper(),
			int(after.get("percent", 0)),
			int(after.get("completed", 0)),
			int(after.get("total", 0)),
		]
	)
	celebration_detail.add_theme_color_override("font_color", Color("d9f5ef"))
	celebration_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.035, 0.05, 0.97), accent, 18))
	celebration_root.visible = true
	celebration_flash.color = Color(accent, 0.0)
	celebration_top_bar.color.a = 0.0
	celebration_bottom_bar.color.a = 0.0
	celebration_panel.modulate = Color(1, 1, 1, 0)
	celebration_panel.scale = Vector2(0.82, 0.82)
	await get_tree().process_frame
	celebration_panel.pivot_offset = celebration_panel.size * 0.5
	background.pivot_offset = background.size * 0.5
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "ui.confirm", 0.92)

	# 1 · Messa a fuoco: un lieve push-in porta lo sguardo dal ponte al terminale.
	if not reduced:
		var focus := create_tween().set_parallel(true)
		focus.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		focus.tween_property(background, "scale", Vector2(1.035, 1.035), 0.34)
		focus.tween_property(terminal_visual, "scale", Vector2(1.96, 1.96), 0.34)
		focus.tween_property(celebration_top_bar, "color:a", 0.92, 0.28)
		focus.tween_property(celebration_bottom_bar, "color:a", 0.92, 0.28)
		focus.tween_method(_set_activation_burst, 0.0, 0.28, 0.34)
		await focus.finished
	else:
		celebration_top_bar.color.a = 0.92
		celebration_bottom_bar.color.a = 0.92

	# 2 · Accensione: luce e suono partono dall'apparato prima del cartello.
	if audio != null:
		audio.call("play", "circuit.on", 1.0 + minf(float(after.get("stage", 1)) * 0.035, 0.14))
	celebration_flash.color = Color(accent, 0.68 if not reduced else 0.28)
	_set_activation_burst(1.0)
	var ignition := create_tween().set_parallel(true)
	ignition.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	ignition.tween_property(celebration_flash, "color:a", 0.0, 0.92)
	ignition.tween_property(celebration_panel, "modulate:a", 1.0, 0.30).set_delay(0.12)
	ignition.tween_property(celebration_panel, "scale", Vector2.ONE, 0.48).set_delay(0.12)
	ignition.tween_property(terminal_visual, "scale", Vector2(1.8, 1.8), 0.62)
	ignition.tween_method(_set_activation_burst, 1.0, 0.0, 1.25)
	await ignition.finished

	# 3 · Rivelazione: il finale non è un secondo popup, ma il culmine dello
	# stesso movimento che ha acceso l'ultimo nodo.
	if final_activation:
		NoraState.sync_from_progress(save)
		celebration_title.text = "ROTTA APERTA"
		celebration_detail.text = "NAVE RIATTIVATA · NORA INTEGRA · EQUIPAGGIO PRONTO"
		nora_line.text = str(narrative.reveal_level(save.level()).get("text", NarrativeManager.FINAL_BEAT))
		if is_instance_valid(nora_portrait):
			nora_portrait.speak(nora_line.text)
		if audio != null:
			audio.call("play_event", "enigmaCompleted", 1.04)
			audio.call("play_event", "portalOpened", 0.94)
	if int(after.get("stage", 0)) > int(before.get("stage", 0)):
		if not final_activation:
			nora_line.text = "NORA: %s ha raggiunto la fase %s." % [str(spec.get("label", room_id)), str(after.get("title", "online")).to_lower()]
			if is_instance_valid(nora_portrait):
				nora_portrait.speak(nora_line.text)
	await get_tree().create_timer(1.05 if final_activation else 0.72).timeout
	var outro := create_tween().set_parallel(true)
	outro.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	outro.tween_property(celebration_panel, "modulate:a", 0.0, 0.36)
	outro.tween_property(celebration_top_bar, "color:a", 0.0, 0.42)
	outro.tween_property(celebration_bottom_bar, "color:a", 0.0, 0.42)
	outro.tween_property(background, "scale", Vector2.ONE, 0.48)
	await outro.finished
	celebration_root.visible = false
	background.scale = Vector2.ONE
	if is_instance_valid(terminal_visual):
		terminal_visual.scale = Vector2(1.8, 1.8)
	set_meta("last_milestone_complete", true)

func _set_activation_burst(value: float) -> void:
	background_material.set_shader_parameter("transition_burst", value)
	if is_instance_valid(power_overlay):
		power_overlay.burst = value

# --- La pausa ------------------------------------------------------------------
#
# **Le tre uscite, anche qui.** (21 agosto 2026) Il pannello e' [[PauseMenuPanel]]
# ed e' lo stesso del mondo aperto: stessi comandi, stesso ordine, stesso posto.
# Cambia solo che cosa vuol dire riavviare, perche' dalla nave nel mondo ci si
# entra invece di restarci.

## Aprire la pausa salva, come nel mondo: da qui si esce in tre modi e tutti e
## tre cambiano scena.
func _apri_pausa() -> void:
	if is_instance_valid(exercise_player) and exercise_player.visible:
		return
	if is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible:
		return
	if is_instance_valid(save):
		save.save()
	if not is_instance_valid(pause_menu):
		pause_menu = PauseMenuPanel.new()
		pause_menu.name = "PauseMenuPanel"
		pause_menu.riavvio_chiesto.connect(_riavvia_mondo)
		pause_menu.giocatore_scelto.connect(_cambia_giocatore)
		pause_menu.menu_chiesto.connect(_torna_al_menu)
		ui_layer.add_child(pause_menu)
	pause_menu.move_to_front()
	var mondo := save.current_world()
	var profilo := WorldProfileCatalog.profile(mondo)
	pause_menu.apri(
		_nome_del_giocatore(),
		"Nave · %s" % str(ShipRoomCatalog.room(current_room_id).get("label", "ponte")),
		"RIAVVIA IL MONDO",
		"Rientri nel mondo %d (%s) dal portale, all'ora in cui comincia. Prove superate, tesori e frammenti restano tuoi." % [
			mondo, str(profilo.get("title", ""))],
		true,
		bool(Dictionary(save.data.get("accessibility", {})).get("highContrast", false)))

func _nome_del_giocatore() -> String:
	if PlayerProfiles.has_profiles():
		return str(PlayerProfiles.active().get("name", "Giocatore 1"))
	return "Giocatore 1"

## Dalla nave, riavviare vuol dire **rientrare nel mondo dal principio**: si
## cancella dov'era rimasto e si entra. Come nel mondo aperto non tocca niente
## di quello che e' stato imparato o raccolto: un riavvio che restituisse i
## tesori sarebbe il modo piu' veloce di guadagnare frammenti che il gioco abbia.
func _riavvia_mondo() -> void:
	if is_instance_valid(save):
		save.clear_world_resume(str(save.current_world()))
		save.save()
	if is_instance_valid(pause_menu):
		pause_menu.congeda()
	_stage_world_launch("riavvio-nave")
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

## Il cambio di giocatore porta **nel mondo dell'altro bambino**, non al menu:
## due fratelli che si alternano lo fanno dieci volte in un pomeriggio, e ogni
## passaggio in piu' e' un motivo per non farlo e giocare sopra la partita
## dell'altro. La sua partita e' gia' salvata dall'apertura della pausa, e senza
## richiesta preparata il mondo legge il salvataggio del profilo attivo.
func _cambia_giocatore(id: String) -> void:
	PlayerProfiles.set_active(id)
	PlayerProfiles.touch(id)
	if is_instance_valid(pause_menu):
		pause_menu.congeda()
	NativeWorldState.stage_launch_request({})
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

## Salva e torna al menu principale.
##
## Il salvataggio esplicito PRIMA del cambio di scena non è prudenza generica:
## uscire è il momento in cui un bambino si aspetta di meno di perdere
## qualcosa, ed è anche l'unico in cui il gioco non ha un'altra occasione per
## scrivere.
func _torna_al_menu() -> void:
	if is_instance_valid(save):
		save.save()
	if is_instance_valid(pause_menu):
		pause_menu.congeda()
	get_tree().change_scene_to_file("res://scenes/boot_menu.tscn")

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

func _refresh_pet_face() -> void:
	if not is_instance_valid(pet_face) or not is_instance_valid(save):
		return
	pet_face.visible = PetState.is_granted(save)
	var accessibility: Dictionary = save.data.get("accessibility", {})
	var pet_id := rewards.equipped_id("pet") if is_instance_valid(rewards) else ""
	var pet_kind := (pet_id if not pet_id.is_empty() else "pet-spark").trim_prefix("pet-")
	pet_face.configure(
		PetState.name_of(save),
		PetState.livery(save),
		PetState.temperament(save),
		PetState.resting_face(save),
		PetState.bond(save),
		PetState.faces(save),
		bool(accessibility.get("reducedMotion", false)),
		pet_kind)

func _pet_react(game_signal: String) -> void:
	set_meta("last_pet_signal", game_signal)
	if is_instance_valid(pet_face) and pet_face.visible:
		pet_face.react_to(game_signal)

func _on_pet_cuddled() -> void:
	if not is_instance_valid(save):
		return
	if _pet_cuddles_this_session < PetState.CUDDLES_PER_SESSION:
		_pet_cuddles_this_session += 1
		PetState.register_cuddle(save)
		save.save()
		_refresh_pet_face()
	_pet_react("cuddle")

func _open_pet_screen() -> void:
	if not is_instance_valid(pet_screen) or not PetState.is_granted(save):
		return
	var accessibility: Dictionary = save.data.get("accessibility", {})
	pet_screen.configure(
		save,
		bool(accessibility.get("highContrast", false)),
		bool(accessibility.get("reducedMotion", false)))
	pet_screen.open_screen()

func _on_pet_screen_closed() -> void:
	_refresh_pet_face()

func _on_pet_customization_changed() -> void:
	_refresh_pet_face()

func _return_to_world() -> void:
	save.save()
	_stage_world_launch("ship-return")
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "portalOpened")
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

func _stage_world_launch(seed: String) -> void:
	var world_id := str(save.current_world())
	var expedition_seed := (
		save.begin_world_expedition(world_id)
		if seed in ["ship-map", "riavvio-nave"]
		else save.world_expedition_seed(world_id))
	save.save()
	var request := NativeWorldState.default_request(expedition_seed)
	request["loadLocalSave"] = false
	request["initialSave"] = save.data.duplicate(true)
	request["worldLevel"] = save.current_world()
	request["accessibility"] = Dictionary(save.data.get("accessibility", {})).duplicate(true)
	request["accessibilityExplicit"] = true
	NativeWorldState.stage_launch_request(request)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(pause_menu) and pause_menu.aperto():
		if event.is_action_pressed("ui_cancel"):
			pause_menu.chiudi()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible:
		return
	if event.is_action_pressed("ui_cancel") and not exercise_player.visible:
		if is_instance_valid(world_map_overlay) and world_map_overlay.visible:
			_hide_world_map()
		else:
			# Esc ferma il gioco, come nel mondo. Il rientro nel mondo resta il
			# suo pulsante grande, che l'audit di navigazione gia' presidia.
			_apri_pausa()
	elif not exercise_player.visible and is_instance_valid(bridge_walkway):
		if event is InputEventScreenTouch and event.pressed:
			bridge_walkway.set_touch_target(event.position)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			bridge_walkway.set_touch_target(event.position)

## **Le luci del restauro.** (14 agosto 2026)
##
## Il restauro di un ponte esisteva già nei dati (`ShipRoomCatalog.restoration`) e
## valeva 0,06 di luce nello shader: comprato, non si vedeva. Adesso pesa nello
## shader **e** accende dei fuochi nella stanza — luci calde disposte in modo
## stabile, che restano lì ogni volta che si rientra.
##
## Perché deterministiche e non casuali: un luogo restaurato che cambia forma a
## ogni visita non è un luogo restaurato, è un effetto. Il seme è l'id della
## stanza, quindi il Bio-ponte ha sempre le sue e sono sempre quelle.
##
## Non danno nessun vantaggio: non aprono, non sbloccano, non contano da nessuna
## parte. Sono la differenza fra una stanza spenta e una stanza in cui qualcuno è
## tornato ad abitare, e questo è tutto il loro lavoro.
func _refresh_restoration_lights(restored: bool, accent: Color) -> void:
	if not is_instance_valid(room_stage):
		return
	var vecchio := room_stage.get_node_or_null("RestorationLights")
	if vecchio != null:
		vecchio.queue_free()
	if not restored:
		return
	var luci := Node2D.new()
	luci.name = "RestorationLights"
	luci.z_index = -1
	room_stage.add_child(luci)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("restauro::%s" % current_room_id))
	var larghezza := maxf(room_stage.size.x, 320.0)
	var altezza := maxf(room_stage.size.y, 240.0)
	for indice in range(7):
		var punto := Vector2(
			rng.randf_range(0.10, 0.90) * larghezza,
			rng.randf_range(0.22, 0.86) * altezza)
		var alone := OutdoorVisualFactory.make_glow(
			rng.randf_range(26.0, 52.0), accent.lightened(0.25), 0.30)
		alone.position = punto
		luci.add_child(alone)
		var nucleo := OutdoorVisualFactory.make_glow(9.0, Color("fff0c4"), 0.55)
		nucleo.position = punto
		luci.add_child(nucleo)

## **Il nucleo prismatico: il ritratto promesso.** (14 agosto 2026)
##
## La sua descrizione a catalogo dice una cosa precisa — «si accende del colore
## delle materie che hai portato più avanti. È un ritratto, non una macchina» —
## e non la faceva. Costa 1600 frammenti: il pezzo più caro della nave prometteva
## l'unica cosa che nessuno aveva costruito.
##
## Adesso c'è, ed è letteralmente quello che dice: dodici luci in cerchio, una per
## materia, ognuna accesa quanto la padronanza di quella materia. Chi è forte in
## tre materie vede tre luci e nove braci; chi ha lavorato ovunque vede un cerchio
## intero. **Nessun numero, nessuna percentuale, nessuna classifica** — il divieto
## di ordinare le materie dalla peggiore alla migliore è dello stesso documento
## che governa il diario, e un ritratto non è una pagella.
##
## Non dà vantaggi, non apre niente, non conta da nessuna parte.
func _refresh_prismatic_portrait() -> void:
	if not is_instance_valid(room_stage):
		return
	var vecchio := room_stage.get_node_or_null("PrismaticPortrait")
	if vecchio != null:
		vecchio.queue_free()
	if not rewards.owned("nora-prismatic-core") or not is_instance_valid(save):
		return
	var ritratto := Node2D.new()
	ritratto.name = "PrismaticPortrait"
	room_stage.add_child(ritratto)
	var centro := Vector2(maxf(room_stage.size.x, 320.0) * 0.5, maxf(room_stage.size.y, 240.0) * 0.30)
	var raggio := 54.0
	var materie: Array = ApparatusConfig.SUBJECT_CYCLE
	for indice in materie.size():
		var materia := str(materie[indice])
		var quota := clampf(float(save.mastery_of(materia)), 0.0, 1.0)
		var angolo := TAU * float(indice) / float(materie.size()) - PI * 0.5
		var punto := centro + Vector2(cos(angolo), sin(angolo)) * raggio
		# Una brace resta accesa anche a zero: una materia mai toccata è buia, non
		# assente. Toglierla direbbe che quella parte di Eli non esiste.
		var colore: Color = SubjectPalette.colore(materia)
		var alone := OutdoorVisualFactory.make_glow(
			9.0 + quota * 13.0, colore, 0.16 + quota * 0.5)
		alone.position = punto
		ritratto.add_child(alone)

func _room_shader_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHIP_ROOM_SHADER
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
