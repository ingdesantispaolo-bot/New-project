extends Node2D

const PORTAL_POSITION := Vector2(448, 300)
const INTERACTION_DISTANCE := 88.0
const DAY_LENGTH := 120.0
const PORTAL_VISUAL := preload("res://scripts/portal_visual.gd")

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
var ui_layer: CanvasLayer
var feedback_label: Label
var feedback_panel: PanelContainer
var phase_label: Label
var biome_label: Label
var portal: Node2D
var camera: Camera2D
var fireflies: CPUParticles2D
var nearby: Array = []
var day_clock := 0.0
var current_biome_chunk := ""

func _ready() -> void:
	request = bridge.load_request()
	result = bridge.result_from_request(request)
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
	_create_hud()
	chunks.update_stream(player.position)

func _apply_resume() -> void:
	var resume: Dictionary = request.get("resume", {})
	if resume.is_empty():
		return
	player.position = Vector2(float(resume.get("playerX", player.position.x)), float(resume.get("playerY", player.position.y)))
	day_clock = float(resume.get("dayClock", 0.0))
	if is_instance_valid(camera):
		camera.position = player.position

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
	_update_night_glow(daylight)
	if is_instance_valid(player):
		chunks.update_stream(player.position)
		if is_instance_valid(camera):
			camera.position = player.position
		if is_instance_valid(fireflies):
			fireflies.emitting = daylight < 0.45
		_update_biome_hud()

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
	var body_visual := OutdoorVisualFactory.build_player(PLAYER_ACCENT)
	player.add_child(body_visual)
	player.visual = body_visual.get_node("Visual")
	fireflies = OutdoorVisualFactory.make_sparkles(Color(1.0, 0.93, 0.62, 0.85), 560.0, 24)
	fireflies.lifetime = 5.0
	fireflies.preprocess = 3.0
	fireflies.scale_amount_min = 0.04
	fireflies.scale_amount_max = 0.08
	fireflies.add_to_group("night_glow")
	player.add_child(fireflies)
	world_layer.add_child(player)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = player.position
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

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
	title.text = "MONDO ESTERNO"
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
	var hint := Label.new()
	hint.text = "WASD / frecce o tocca lo schermo · E: interagisci · ESC: torna a Phaser"
	hint.add_theme_color_override("font_color", Color("9fc4bb"))
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
	if kind == "portal":
		_set_feedback("Portale pronto: salvataggio in corso…")
		_leave_world()
		return
	if kind == "treasure":
		var payload: Dictionary = target.get_meta("payload")
		var collected: Array = result["collectedTreasureIds"]
		if collected.has(id):
			_set_feedback("Questa cassa è già stata raccolta.")
		else:
			collected.append(id)
			result["energyEarned"] += int(payload["rewardEnergy"])
			result["fragmentsEarned"] += int(payload["rewardFragments"])
			_set_feedback("Tesoro raccolto: +%d energia, +%d frammenti" % [int(payload["rewardEnergy"]), int(payload["rewardFragments"])])
			nearby.erase(target)
			var owner_node := target.get_parent()
			if is_instance_valid(owner_node):
				owner_node.queue_free()
		return
	if kind == "encounter":
		var payload: Dictionary = target.get_meta("payload")
		var completed: Array = result["completedEncounterIds"]
		if completed.has(id):
			_set_feedback("Incontro già completato.")
			return
		# Rimbalzo a Phaser: l'incontro si gioca con il minigioco NORA. Salviamo
		# l'incontro pendente e lo stato per riprendere il mondo al ritorno.
		_set_feedback("Sfida in arrivo: torno a Phaser…")
		result["pendingEncounter"] = {
			"id": id,
			"x": int(payload["x"]), "y": int(payload["y"]), "biome": str(payload["biome"]),
			"kind": str(payload["kind"]), "label": str(payload["label"]), "enemy": str(payload["enemy"]),
			"difficulty": int(payload["difficulty"]), "reward": int(payload["reward"]),
		}
		result["resume"] = {
			"playerX": int(player.position.x), "playerY": int(player.position.y), "dayClock": day_clock,
		}
		_leave_world()
		return

func _leave_world() -> void:
	var return_url := str(request.get("returnUrl", ""))
	bridge.publish_result_and_return(result, return_url)
	get_tree().quit()

func _set_feedback(message: String) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = message
	if is_instance_valid(feedback_panel):
		feedback_panel.visible = message != ""
