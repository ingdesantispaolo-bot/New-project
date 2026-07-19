extends Node2D

const PORTAL_POSITION := Vector2(448, 300)
const INTERACTION_DISTANCE := 88.0
const DAY_LENGTH := 120.0
const PORTAL_VISUAL := preload("res://scripts/portal_visual.gd")

var request: Dictionary
var result: Dictionary
var bridge := OutdoorSaveBridge.new()
var chunks: OutdoorChunkManager
var player: OutdoorPlayerController
var world_layer: Node2D
var day_light: CanvasModulate
var ui_layer: CanvasLayer
var feedback_label: Label
var phase_label: Label
var portal: Node2D
var camera: Camera2D
var nearby: Array = []
var day_clock := 0.0

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
	if is_instance_valid(day_light):
		var daylight := (sin(day_clock / DAY_LENGTH * TAU - PI / 2.0) + 1.0) * 0.5
		day_light.color = Color(0.48 + daylight * 0.52, 0.58 + daylight * 0.42, 0.72 + daylight * 0.28)
		if is_instance_valid(phase_label):
			phase_label.text = "Giorno" if daylight > 0.72 else "Alba" if daylight > 0.42 else "Notte"
	if is_instance_valid(player):
		chunks.update_stream(player.position)
		if is_instance_valid(camera):
			camera.position = player.position

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
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0, -20), Vector2(16, 14), Vector2(-16, 14)])
	visual.color = Color("6be7d6")
	player.add_child(visual)
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

func _create_hud() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)

	var info := VBoxContainer.new()
	info.position = Vector2(24, 24)
	info.add_theme_constant_override("separation", 6)
	root.add_child(info)
	var title := Label.new()
	title.text = "MONDO ESTERNO"
	title.add_theme_color_override("font_color", Color("e7fff8"))
	title.add_theme_font_size_override("font_size", 20)
	info.add_child(title)
	var hint := Label.new()
	hint.text = "WASD / frecce o tocca lo schermo: movimento · E: interagisci · ESC: torna a Phaser"
	hint.add_theme_color_override("font_color", Color("bcd8d0"))
	info.add_child(hint)
	phase_label = Label.new()
	phase_label.text = "Giorno"
	phase_label.add_theme_color_override("font_color", Color("f6c85f"))
	phase_label.add_theme_font_size_override("font_size", 16)
	info.add_child(phase_label)

	var exit_button := Button.new()
	exit_button.text = "Esci dal mondo"
	exit_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	exit_button.pressed.connect(_leave_world)
	root.add_child(exit_button)

	feedback_label = Label.new()
	feedback_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 28)
	feedback_label.add_theme_color_override("font_color", Color("ffffff"))
	feedback_label.add_theme_font_size_override("font_size", 16)
	root.add_child(feedback_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		player.set_touch_target(_to_world(event.position))
	elif event is InputEventScreenDrag:
		player.set_touch_target(_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player.set_touch_target(_to_world(event.position))
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		player.set_touch_target(_to_world(event.position))
	if event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("leave_portal"):
		_leave_world()

func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

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
