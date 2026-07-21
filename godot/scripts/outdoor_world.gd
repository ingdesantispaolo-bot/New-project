extends Node2D

const PORTAL_POSITION := Vector2(448, 300)
const INTERACTION_DISTANCE := 88.0
const DAY_LENGTH := 120.0
const PORTAL_VISUAL := preload("res://scripts/portal_visual.gd")
const EXERCISE_ENERGY_COST := 3
const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")

const PLAYER_ACCENT := Color("6be7d6")
const NIGHT_TINT := Color(0.34, 0.4, 0.66)
const DAWN_TINT := Color(1.0, 0.84, 0.72)

var request: Dictionary
var result: Dictionary
var bridge := OutdoorSaveBridge.new()
var chunks: OutdoorChunkManager
var player: OutdoorPlayerController
var world_layer: Node2D
var day_light: CanvasModulate
var atmosphere_layer: CanvasLayer
var atmosphere_rect: ColorRect
var atmosphere_material: ShaderMaterial
var ui_layer: CanvasLayer
var feedback_label: Label
var feedback_panel: PanelContainer
var phase_label: Label
var biome_label: Label
var objective_label: Label
var portal: Node2D
var camera: Camera2D
var fireflies: CPUParticles2D
var pet_companion: OutdoorPetCompanion
var nearby: Array = []
var day_clock := 0.0
var current_biome_chunk := ""
var energy_label: Label
var fragment_label: Label
var reward_name_label: Label
var reward_bar: ProgressBar
var reward_remaining_label: Label
var exercise_player: ExercisePlayer
var apparatus_terminal: Area2D
var reward_cost := 0
var reward_name := ""
var gameplay: OutdoorGameplay
var runtime: Dictionary = {}
# Alias di compatibilità per audit/scene legacy; la proprietà resta di
# OutdoorGameplay e non viene duplicata.
var game_save: GameSaveManager
var progression_manager: ProgressionManager
var content_manager: ContentManager
var gain_popup_pool: Array[Label] = []

func _ready() -> void:
	request = bridge.load_request()
	result = bridge.result_from_request(request)
	gameplay = OutdoorGameplay.new()
	gameplay.name = "OutdoorGameplay"
	add_child(gameplay)
	gameplay.runtime_state_changed.connect(_on_runtime_state)
	gameplay.session_requested.connect(_on_gameplay_session_requested)
	gameplay.feedback.connect(_set_feedback)
	gameplay.enigma_progress.connect(_on_enigma_progress)
	gameplay.setup(request, result)
	game_save = gameplay.game_save
	progression_manager = gameplay.progression_manager
	content_manager = gameplay.content_manager
	world_layer = Node2D.new()
	world_layer.name = "WorldLayer"
	world_layer.y_sort_enabled = true
	add_child(world_layer)
	day_light = CanvasModulate.new()
	day_light.name = "DayNight"
	day_light.color = Color("ffffff")
	world_layer.add_child(day_light)
	chunks = OutdoorChunkManager.new()
	chunks.name = "ChunkManager"
	world_layer.add_child(chunks)
	chunks.configure(str(request.get("worldSeed", "outdoor-dev-1")), self)
	_create_player()
	_apply_resume()
	_create_portal()
	_create_apparatus_terminal()
	_create_enigma_poi()
	_create_atmosphere()
	_create_hud()
	_create_exercise_player()
	chunks.update_stream(player.position)

func _apply_resume() -> void:
	var resume: Dictionary = request.get("resume", {})
	if resume.is_empty():
		return
	var resumed := Vector2(float(resume.get("playerX", player.position.x)), float(resume.get("playerY", player.position.y)))
	player.position = chunks.clamp_to_world(resumed)
	day_clock = float(resume.get("dayClock", 0.0))
	if is_instance_valid(camera):
		camera.position = player.position

func _on_runtime_state(state: Dictionary) -> void:
	runtime = state.duplicate(true)
	_update_objective()
	_refresh_economy()

func _on_gameplay_session_requested(session: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	_set_feedback("")
	if is_instance_valid(player):
		player.set_physics_process(false)
	exercise_player.visible = true
	exercise_player.start_session(session)

func _process(delta: float) -> void:
	day_clock = fmod(day_clock + delta, DAY_LENGTH)
	var daylight := (sin(day_clock / DAY_LENGTH * TAU - PI / 2.0) + 1.0) * 0.5
	if is_instance_valid(day_light):
		# notte → giorno con transizione calda (alba/tramonto) a metà corsa
		var base := NIGHT_TINT.lerp(Color(1, 1, 1), daylight)
		var dawn_mix := clampf(1.0 - absf(daylight - 0.5) * 2.2, 0.0, 1.0)
		day_light.color = base.lerp(DAWN_TINT, dawn_mix * 0.35)
		if is_instance_valid(phase_label):
			phase_label.text = "Giorno" if daylight > 0.72 else "Alba" if daylight > 0.42 else "Notte"
	if is_instance_valid(gameplay):
		gameplay.update_phase("giorno" if daylight > 0.72 else "alba" if daylight > 0.42 else "notte")
	if is_instance_valid(atmosphere_material):
		atmosphere_material.set_shader_parameter("daylight", daylight)
		atmosphere_material.set_shader_parameter("clock", day_clock / DAY_LENGTH)
	_update_night_glow(daylight)
	if is_instance_valid(player):
		chunks.update_stream(player.position)
		if is_instance_valid(camera):
			camera.position = player.position
		if is_instance_valid(fireflies):
			fireflies.emitting = daylight < 0.45
		_update_biome_hud()

func _create_atmosphere() -> void:
	# Layer screen-space tra mondo e HUD: aggiunge profondità cromatica senza
	# modificare collisioni, z-sort o la semantica del salvataggio.
	atmosphere_layer = CanvasLayer.new()
	atmosphere_layer.name = "AtmosphereLayer"
	atmosphere_layer.layer = 1
	add_child(atmosphere_layer)
	atmosphere_rect = ColorRect.new()
	atmosphere_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	atmosphere_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float daylight = 0.75;
uniform float clock = 0.0;
uniform vec3 biome_tint = vec3(0.42, 0.90, 0.84);

void fragment() {
    vec2 uv = UV;
    vec2 centered = uv - vec2(0.5);
    float edge = smoothstep(0.38, 0.92, length(centered * vec2(1.0, 0.82)));
    float night = 1.0 - daylight;
    float dawn = clamp(1.0 - abs(daylight - 0.5) * 2.4, 0.0, 1.0);
    float horizon = smoothstep(0.15, 0.9, uv.y) * (1.0 - smoothstep(0.72, 1.0, uv.y));
    float mist_wave = 0.5 + 0.5 * sin((uv.x * 9.0) + (clock * 6.283) + sin(uv.y * 5.0));
    float mist = horizon * mist_wave * (0.018 + dawn * 0.035);
    vec3 night_tint = vec3(0.08, 0.13, 0.28);
    vec3 dawn_tint = vec3(1.0, 0.58, 0.28);
    vec3 tint = mix(night_tint, dawn_tint, dawn * 0.72);
    tint = mix(tint, biome_tint, 0.16);
    float alpha = (night * 0.095) + (dawn * 0.035) + (edge * 0.075) + mist;
    COLOR = vec4(tint, clamp(alpha, 0.0, 0.22));
}
"""
	atmosphere_material = ShaderMaterial.new()
	atmosphere_material.shader = shader
	atmosphere_rect.material = atmosphere_material
	atmosphere_layer.add_child(atmosphere_rect)

func _update_night_glow(daylight: float) -> void:
	# I bagliori (lampade, cristalli, fari…) si accendono al calare della luce.
	var alpha := clampf(0.15 + (1.0 - daylight) * 0.95, 0.15, 1.0)
	for node in get_tree().get_nodes_in_group("night_glow"):
		var canvas := node as CanvasItem
		if canvas != null:
			canvas.modulate.a = alpha

func _update_biome_hud() -> void:
	if not is_instance_valid(biome_label):
		return
	var cx := floori(player.position.x / OutdoorChunkManager.CHUNK_SIZE)
	var cy := floori(player.position.y / OutdoorChunkManager.CHUNK_SIZE)
	var id := "chunk-%d_%d" % [cx, cy]
	if id == current_biome_chunk or not chunks.loaded.has(id):
		return
	current_biome_chunk = id
	if chunks.composition != null:
		var biome := chunks.composition.dominant_biome(player.position)
		var profile := BiomeProfile.get_profile(biome)
		biome_label.text = str(profile["label"])
		var accent: Color = chunks.composition.blended_accent(player.position)
		biome_label.add_theme_color_override("font_color", accent)
		if is_instance_valid(atmosphere_material):
			atmosphere_material.set_shader_parameter("biome_tint", Vector3(accent.r, accent.g, accent.b))
		return
	var data: Dictionary = chunks.loaded[id]["data"]
	var patch: Dictionary = data.get("patch", {})
	biome_label.text = str(patch.get("label", ""))
	biome_label.add_theme_color_override("font_color", OutdoorVisualFactory.hex_color(int(patch.get("accent", 0x6be7d6))))

func _create_player() -> void:
	player = OutdoorPlayerController.new()
	player.name = "Eli"
	player.position = Vector2(448, 448)
	player.add_to_group("player")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	player.add_child(shape)
	var visual_data: Dictionary = request.get("avatarVisual", {})
	var livery := _avatar_color(visual_data.get("bodyColor", -1), PLAYER_ACCENT)
	var body_visual := OutdoorVisualFactory.build_player(livery)
	player.add_child(body_visual)
	player.visual = body_visual.get_node("Visual")
	_apply_accessory(player.visual, visual_data)
	fireflies = OutdoorVisualFactory.make_sparkles(Color(1.0, 0.93, 0.62, 0.85), 560.0, 24)
	fireflies.lifetime = 5.0
	fireflies.preprocess = 3.0
	fireflies.scale_amount_min = 0.04
	fireflies.scale_amount_max = 0.08
	fireflies.add_to_group("night_glow")
	player.add_child(fireflies)
	world_layer.add_child(player)
	_spawn_pet(visual_data)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = player.position
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

func _avatar_color(value, fallback: Color) -> Color:
	if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and int(value) >= 0:
		return OutdoorVisualFactory.hex_color(int(value))
	return fallback

func _apply_accessory(visual_node: Node2D, visual_data: Dictionary) -> void:
	var accessory = visual_data.get("accessory", null)
	if typeof(accessory) != TYPE_DICTIONARY:
		return
	var color := OutdoorVisualFactory.hex_color(int(accessory.get("color", 0x9ff5e9)))
	visual_node.add_child(OutdoorVisualFactory.build_accessory(str(accessory.get("id", "")), color))

func _spawn_pet(visual_data: Dictionary) -> void:
	var pet_data = visual_data.get("pet", null)
	if typeof(pet_data) != TYPE_DICTIONARY:
		return
	var color := OutdoorVisualFactory.hex_color(int(pet_data.get("color", 0xf6c85f)))
	pet_companion = OutdoorPetCompanion.new()
	world_layer.add_child(pet_companion)
	pet_companion.setup(str(pet_data.get("kind", "spark")), color, player)

func _create_portal() -> void:
	portal = PORTAL_VISUAL.new()
	portal.name = "ExitPortal"
	portal.position = PORTAL_POSITION
	portal.z_index = 5
	world_layer.add_child(portal)
	var area := Area2D.new()
	area.set_meta("kind", "portal")
	area.set_meta("id", "portal")
	area.set_meta("payload", {})
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_DISTANCE
	shape.shape = circle
	area.add_child(shape)
	portal.add_child(area)
	area.body_entered.connect(func(body): on_interactable_entered(area, body))
	area.body_exited.connect(func(body): on_interactable_exited(area, body))

func _create_apparatus_terminal() -> void:
	# Terminale gameplay-only: il marker e la gerarchia visiva restano a Codex.
	# L'Area2D rende comunque raggiungibile l'esame finale nella slice attuale.
	apparatus_terminal = Area2D.new()
	apparatus_terminal.name = "NucleoApparatusTerminal"
	apparatus_terminal.position = PORTAL_POSITION + Vector2(132, 0)
	apparatus_terminal.set_meta("kind", "apparatus")
	apparatus_terminal.set_meta("id", "nucleo")
	apparatus_terminal.set_meta("payload", {"apparatus": "nucleo"})
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_DISTANCE
	shape.shape = circle
	apparatus_terminal.add_child(shape)
	world_layer.add_child(apparatus_terminal)
	apparatus_terminal.body_entered.connect(func(body): on_interactable_entered(apparatus_terminal, body))
	apparatus_terminal.body_exited.connect(func(body): on_interactable_exited(apparatus_terminal, body))

func _create_enigma_poi() -> void:
	# Enigma ambientale (prototipo matematica → tema "ponte"): POI gameplay-only.
	# Come per il terminale apparato, il marker e la STRUTTURA che si costruisce
	# (rotto→ponte) restano a Codex, che si abbona a `enigma_progress` e attacca il
	# suo visual con `set_stage(built, total)` a questo nodo (gruppo "enigma_poi").
	var enigma := Area2D.new()
	enigma.name = "PonteEnigma"
	enigma.position = PORTAL_POSITION + Vector2(-148, 120)
	enigma.add_to_group("enigma_poi")
	enigma.set_meta("kind", "enigma")
	enigma.set_meta("id", "enigma-ponte-primi")
	enigma.set_meta("payload", {"subject": "matematica", "label": "il Ponte dei Primi"})
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_DISTANCE
	shape.shape = circle
	enigma.add_child(shape)
	world_layer.add_child(enigma)
	enigma.body_entered.connect(func(body): on_interactable_entered(enigma, body))
	enigma.body_exited.connect(func(body): on_interactable_exited(enigma, body))

func _create_exercise_player() -> void:
	exercise_player = EXERCISE_PLAYER_SCRIPT.new()
	exercise_player.name = "ExercisePlayer"
	exercise_player.visible = false
	exercise_player.session_finished.connect(_on_exercise_finished)
	# La costruzione dell'enigma avanza in tempo reale: inoltro il progresso alla
	# logica, che rilancia `enigma_progress` (con tema) per la resa di Codex.
	exercise_player.progress_changed.connect(gameplay.notify_progress)
	ui_layer.add_child(exercise_player)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.09, 0.12, 0.72)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.42, 0.9, 0.84, 0.25)
	return style

func _create_hud() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)

	# vignetta soft ai bordi dello schermo (sotto i pannelli HUD)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.55;
	float v = smoothstep(0.62, 1.28, d);
	COLOR = vec4(0.008, 0.02, 0.035, v * 0.42);
}
"""
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = shader
	vignette.material = vignette_material
	root.add_child(vignette)

	var info_panel := PanelContainer.new()
	info_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_panel.position = Vector2(16, 16)
	info_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(info_panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info_panel.add_child(info)
	var title := Label.new()
	title.text = "ELI QUEST  ·  RADURA ACCADEMIA"
	title.add_theme_color_override("font_color", Color("e7fff8"))
	title.add_theme_font_size_override("font_size", 19)
	info.add_child(title)
	biome_label = Label.new()
	biome_label.text = ""
	biome_label.add_theme_font_size_override("font_size", 14)
	biome_label.add_theme_color_override("font_color", PLAYER_ACCENT)
	info.add_child(biome_label)
	phase_label = Label.new()
	phase_label.text = "Giorno"
	phase_label.add_theme_color_override("font_color", Color("f6c85f"))
	phase_label.add_theme_font_size_override("font_size", 14)
	info.add_child(phase_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(300, 0)
	objective_label.add_theme_color_override("font_color", Color("f6c85f"))
	objective_label.add_theme_font_size_override("font_size", 13)
	info.add_child(objective_label)
	_update_objective()
	var hint := Label.new()
	hint.text = "WASD / frecce  ·  SHIFT: scatto  ·  E: interagisci"
	hint.add_theme_color_override("font_color", Color("9fc4bb"))
	hint.text = "WASD / frecce  ·  SHIFT: scatto  ·  E: interagisci"
	hint.add_theme_font_size_override("font_size", 12)
	info.add_child(hint)

	var exit_button := Button.new()
	exit_button.text = "Esci dal mondo"
	exit_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	exit_button.pressed.connect(_leave_world)
	root.add_child(exit_button)

	feedback_panel = PanelContainer.new()
	feedback_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	feedback_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	feedback_panel.add_theme_stylebox_override("panel", _panel_style())
	feedback_panel.visible = false
	root.add_child(feedback_panel)
	feedback_label = Label.new()
	feedback_label.add_theme_color_override("font_color", Color("ffffff"))
	feedback_label.add_theme_font_size_override("font_size", 15)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(340, 0)
	feedback_panel.add_child(feedback_label)

	_create_economy_panel(root)

func _create_economy_panel(root: Control) -> void:
	var next_reward = request.get("nextReward", null)
	if typeof(next_reward) == TYPE_DICTIONARY:
		reward_name = str(next_reward.get("name", ""))
		reward_cost = int(next_reward.get("cost", 0))

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(210, 0)
	panel.add_child(box)

	energy_label = Label.new()
	energy_label.add_theme_color_override("font_color", Color("f6c85f"))
	energy_label.add_theme_font_size_override("font_size", 16)
	box.add_child(energy_label)
	fragment_label = Label.new()
	fragment_label.add_theme_color_override("font_color", Color("c7b8ff"))
	fragment_label.add_theme_font_size_override("font_size", 14)
	box.add_child(fragment_label)
	var economy_hint := Label.new()
	economy_hint.text = "Tesori: solo frammenti · Esercizio: -%d energia" % EXERCISE_ENERGY_COST
	economy_hint.add_theme_color_override("font_color", Color("9fc4bb"))
	economy_hint.add_theme_font_size_override("font_size", 11)
	economy_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	economy_hint.custom_minimum_size = Vector2(210, 0)
	box.add_child(economy_hint)

	if reward_cost > 0:
		var sep := HSeparator.new()
		box.add_child(sep)
		reward_name_label = Label.new()
		reward_name_label.add_theme_color_override("font_color", Color("e7fff8"))
		reward_name_label.add_theme_font_size_override("font_size", 13)
		reward_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_name_label.custom_minimum_size = Vector2(210, 0)
		box.add_child(reward_name_label)
		reward_bar = ProgressBar.new()
		reward_bar.show_percentage = false
		reward_bar.max_value = 100.0
		reward_bar.custom_minimum_size = Vector2(210, 12)
		box.add_child(reward_bar)
		reward_remaining_label = Label.new()
		reward_remaining_label.add_theme_color_override("font_color", Color("9fc4bb"))
		reward_remaining_label.add_theme_font_size_override("font_size", 12)
		box.add_child(reward_remaining_label)

	_refresh_economy()

func _refresh_economy() -> void:
	if runtime.is_empty():
		return
	var current := int(runtime.get("energy", 0))
	if is_instance_valid(energy_label):
		energy_label.text = "Energia %d" % current
	if is_instance_valid(fragment_label):
		fragment_label.text = "Frammenti %d" % int(runtime.get("fragments", 0))
	if reward_cost > 0 and is_instance_valid(reward_bar):
		reward_name_label.text = "Prossimo: %s" % reward_name
		reward_bar.value = clampf(float(current) / float(reward_cost) * 100.0, 0.0, 100.0)
		var remaining := maxi(0, reward_cost - current)
		reward_remaining_label.text = ("Ti manca %d energia" % remaining) if remaining > 0 else "Puoi comprarlo!"

func _spawn_gain_popup(text: String, color: Color) -> void:
	if not is_instance_valid(player):
		return
	var label := _acquire_gain_popup()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.z_index = 70
	label.position = player.position + Vector2(-24, -50)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 44.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.set_parallel(false)
	tween.tween_callback(_release_gain_popup.bind(label))

func _acquire_gain_popup() -> Label:
	for label in gain_popup_pool:
		if is_instance_valid(label) and not label.visible:
			label.visible = true
			label.modulate = Color.WHITE
			return label
	var label := Label.new()
	label.visible = true
	gain_popup_pool.append(label)
	world_layer.add_child(label)
	return label

func _release_gain_popup(label: Label) -> void:
	if not is_instance_valid(label):
		return
	label.visible = false
	label.text = ""
	label.modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var target := _to_world(event.position)
		player.set_touch_target(target)
		_spawn_touch_ping(target)
	elif event is InputEventScreenDrag:
		player.set_touch_target(_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target := _to_world(event.position)
		player.set_touch_target(target)
		_spawn_touch_ping(target)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		player.set_touch_target(_to_world(event.position))
	if event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("leave_portal"):
		_leave_world()

func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _spawn_touch_ping(world_pos: Vector2) -> void:
	var ping := Node2D.new()
	ping.position = world_pos
	ping.z_index = 60
	ping.add_child(OutdoorVisualFactory.make_ring(16, Color(PLAYER_ACCENT, 0.9), 2.5, 22))
	OutdoorVisualFactory.attach_anim(ping, "ping", 1.0, 1.0)
	world_layer.add_child(ping)

func on_interactable_entered(area: Area2D, body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not nearby.has(area):
		nearby.append(area)
	_refresh_prompt()

func on_interactable_exited(area: Area2D, body: Node) -> void:
	if not body.is_in_group("player"):
		return
	nearby.erase(area)
	_refresh_prompt()

func _nearest() -> Area2D:
	var valid: Array = []
	var best: Area2D = null
	var best_distance := INF
	for area in nearby:
		if not is_instance_valid(area):
			continue
		valid.append(area)
		var distance := player.global_position.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	nearby = valid
	return best

func _refresh_prompt() -> void:
	var target := _nearest()
	if target == null:
		_set_feedback("")
		return
	var kind := str(target.get_meta("kind"))
	var id := str(target.get_meta("id"))
	if kind == "portal":
		_set_feedback("Premi E per attraversare il portale e tornare a Phaser")
	elif kind == "apparatus":
		_set_feedback(gameplay.apparatus_prompt())
	elif kind == "enigma":
		var payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s è già ricostruito" % str(payload.get("label", "L'enigma")).capitalize())
		else:
			_set_feedback("Premi E per ricostruire %s con gli esercizi" % str(payload.get("label", "il ponte")))
	elif kind == "treasure":
		if result["collectedTreasureIds"].has(id):
			_set_feedback("Tesoro già raccolto")
		else:
			_set_feedback("Premi E per raccogliere il tesoro")
	elif kind == "encounter":
		var payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("Incontro già completato")
		else:
			_set_feedback("Premi E per affrontare: %s" % str(payload.get("label", "incontro")))

func _interact() -> void:
	var target := _nearest()
	if target == null:
		_set_feedback("Avvicinati a un tesoro, a un incontro o al portale.")
		return
	var kind := str(target.get_meta("kind"))
	var id := str(target.get_meta("id"))
	var completed: Array = result["completedEncounterIds"]
	if kind == "portal":
		_set_feedback("Portale pronto: salvataggio in corso…")
		_leave_world()
		return
	if kind == "apparatus":
		gameplay.try_start_final_exam()
		return
	if kind == "enigma":
		var enigma_payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s è già ricostruito." % str(enigma_payload.get("label", "L'enigma")).capitalize())
			return
		gameplay.try_start_enigma(enigma_payload, id)
		return
	if kind == "treasure":
		var payload: Dictionary = target.get_meta("payload")
		var collected: Array = result["collectedTreasureIds"]
		if collected.has(id):
			_set_feedback("Questa cassa è già stata raccolta.")
		else:
			collected.append(id)
			gameplay.collect_treasure(payload)
			_update_objective()
			_set_feedback("Tesoro raccolto: +%d frammenti. L'energia si guadagna solo con gli esercizi." % int(payload["rewardFragments"]))
			_refresh_economy()
			_spawn_gain_popup("+%d frammenti" % int(payload["rewardFragments"]), Color("c7b8ff"))
			if is_instance_valid(pet_companion):
				pet_companion.react()
			nearby.erase(target)
			var owner_node := target.get_parent()
			if is_instance_valid(owner_node):
				owner_node.queue_free()
		return
	if kind == "encounter":
		var mission_payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("Incontro già completato.")
			return
		gameplay.try_start_mission(mission_payload, id)
		return


func _on_exercise_finished(exercise_result: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	exercise_player.visible = false
	if is_instance_valid(player):
		player.set_physics_process(true)
	if is_instance_valid(gameplay):
		gameplay.resolve_session(exercise_result)
	_refresh_economy()
	_refresh_prompt()

# Progresso dell'enigma: feedback testuale + popup a ogni campata (gameplay-only).
# Se Codex ha attaccato un visual della struttura (metodo `set_stage`) ai nodi del
# gruppo "enigma_poi", lo aggiorno; altrimenti resta il solo riscontro testuale.
func _on_enigma_progress(built: int, total: int, theme: String) -> void:
	for node in get_tree().get_nodes_in_group("enigma_poi"):
		if node.has_method("set_stage"):
			node.set_stage(built, total)
	if built <= 0:
		_set_feedback("Enigma avviato: costruisci %s rispondendo (%d campate)" % [theme, total])
		return
	_set_feedback("%s: %d/%d campate costruite" % [theme.capitalize(), built, total])
	_spawn_gain_popup("+1 campata", Color("8ff6c0"))

func start_final_exam() -> bool:
	return is_instance_valid(gameplay) and gameplay.try_start_final_exam()

func _leave_world() -> void:
	if is_instance_valid(gameplay):
		gameplay.publish_exit_state()
	var return_url := str(request.get("returnUrl", ""))
	bridge.publish_result_and_return(result, return_url)
	get_tree().quit()

func _set_feedback(message: String) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = message
	if is_instance_valid(feedback_panel):
		feedback_panel.visible = message != ""

func _update_objective() -> void:
	if not is_instance_valid(objective_label) or runtime.is_empty():
		return
	var subject := str(runtime.get("focusSubject", "matematica")).capitalize()
	var apparatus := str(runtime.get("apparatus", "nucleo")).replace("-", " ").capitalize()
	objective_label.text = "Livello %d / Materia %s\n%s\nMissioni %d/%d / Mastery %.0f%%/%.0f%%" % [
		int(runtime.get("level", 1)), subject, apparatus,
		int(runtime.get("missionsDone", 0)), int(runtime.get("missionsRequired", 0)),
		float(runtime.get("mastery", 0.0)) * 100.0, float(runtime.get("masteryThreshold", 0.0)) * 100.0]
