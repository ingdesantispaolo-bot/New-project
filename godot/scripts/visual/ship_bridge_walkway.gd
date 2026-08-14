class_name ShipBridgeWalkway
extends Node2D

## Ponte camminabile della nave. Disegna soltanto la topologia e legge gli
## stati preparati dal controller: nessun conteggio di progressione vive qui.

signal room_entered(room_id: String, subject: String)

const PLAYER_SCRIPT := preload("res://scripts/player_controller.gd")
const SUBJECTS := [
	"matematica", "italiano", "coding", "inglese", "fisica", "musica",
	"latino", "elettronica", "geografia", "scienze", "storia", "logica",
]

var room_states: Dictionary = {}
var player: CharacterBody2D
var doors: Array[Area2D] = []
var reduced_motion := false

func configure(states: Dictionary, use_reduced_motion: bool = false) -> void:
	room_states = states.duplicate(true)
	reduced_motion = use_reduced_motion
	if doors.is_empty():
		_build_bridge()
	_refresh_door_states()
	queue_redraw()

func set_room_states(states: Dictionary) -> void:
	room_states = states.duplicate(true)
	_refresh_door_states()
	queue_redraw()

func set_touch_target(global_target: Vector2) -> void:
	if is_instance_valid(player):
		player.call("set_touch_target", to_local(global_target))

func _build_bridge() -> void:
	name = "WalkableShipBridge"
	for index in SUBJECTS.size():
		var subject := str(SUBJECTS[index])
		var top := index < 6
		var column := index if top else index - 6
		var position_x := -285.0 + float(column) * 114.0
		var position_y := -174.0 if top else 174.0
		var door := Area2D.new()
		door.name = "ShipDoor_%s" % subject.capitalize()
		door.position = Vector2(position_x, position_y)
		door.set_meta("subject", subject)
		door.set_meta("room_id", ShipRoomCatalog.room_for_subject(subject))
		door.set_meta("door_index", index)
		var shape := CollisionShape2D.new()
		shape.name = "DoorThreshold"
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(70, 42)
		shape.shape = rectangle
		door.add_child(shape)
		var label := Label.new()
		label.name = "DoorLabel"
		label.position = Vector2(-54, -18 if top else -5)
		label.size = Vector2(108, 26)
		label.text = subject.to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color("e8fbff"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		door.add_child(label)
		door.body_entered.connect(_on_door_entered.bind(door))
		add_child(door)
		doors.append(door)

	player = PLAYER_SCRIPT.new()
	player.name = "ShipPlayer"
	player.position = Vector2.ZERO
	player.set("speed", 155.0)
	player.set("reduced_motion", reduced_motion)
	var player_shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 34.0
	player_shape.shape = capsule
	player.add_child(player_shape)
	var visual := OutdoorVisualFactory.build_player(Color("6be7d6"), 0)
	visual.scale = Vector2.ONE * 0.58
	player.add_child(visual)
	player.set("visual", visual)
	add_child(player)
	_build_bounds()

func _build_bounds() -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "BridgeBounds"
	add_child(bounds)
	_add_wall(bounds, Vector2(0, -221), Vector2(720, 18))
	_add_wall(bounds, Vector2(0, 221), Vector2(720, 18))
	_add_wall(bounds, Vector2(-351, 0), Vector2(18, 460))
	_add_wall(bounds, Vector2(351, 0), Vector2(18, 460))

func _add_wall(parent: StaticBody2D, at: Vector2, wall_size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	shape.position = at
	var rectangle := RectangleShape2D.new()
	rectangle.size = wall_size
	shape.shape = rectangle
	parent.add_child(shape)

func _on_door_entered(body: Node2D, door: Area2D) -> void:
	if body != player:
		return
	room_entered.emit(str(door.get_meta("room_id", "central")), str(door.get_meta("subject", "")))

func _refresh_door_states() -> void:
	for door in doors:
		var room_id := str(door.get_meta("room_id", "central"))
		var state: Dictionary = room_states.get(room_id, {})
		door.set_meta("powered", int(state.get("stage", 0)) > 0)
		door.set_meta("activation_ratio", float(state.get("ratio", 0.0)))

func _process(_delta: float) -> void:
	if not reduced_motion:
		queue_redraw()

func _draw() -> void:
	# Sagoma unica: due file di stanze e un corridoio centrale leggibile.
	draw_rect(Rect2(-342, -212, 684, 424), Color(0.018, 0.075, 0.095, 0.93), true)
	draw_rect(Rect2(-330, -104, 660, 208), Color(0.055, 0.16, 0.18, 0.96), true)
	draw_rect(Rect2(-330, -104, 660, 208), Color("5aa9aa"), false, 3.0)
	for index in SUBJECTS.size():
		var top := index < 6
		var column := index if top else index - 6
		var x := -285.0 + float(column) * 114.0
		var y := -174.0 if top else 174.0
		var door := doors[index] if index < doors.size() else null
		var room_id := str(door.get_meta("room_id", "central")) if door != null else "central"
		var room := ShipRoomCatalog.room(room_id)
		var state: Dictionary = room_states.get(room_id, {})
		var ratio := float(state.get("ratio", 0.0))
		var accent := Color(str(room.get("accent", "6be7d6")))
		var door_color := Color(0.045, 0.095, 0.11, 0.98).lerp(accent, 0.18 + ratio * 0.52)
		var door_rect := Rect2(x - 38, y - 25, 76, 50)
		draw_rect(door_rect, door_color, true)
		draw_rect(door_rect, Color(accent, 0.42 + ratio * 0.5), false, 3.0)
		var corridor_end := Vector2(x, -104 if top else 104)
		draw_line(Vector2(x, y + (25 if top else -25)), corridor_end, Color(accent, 0.18 + ratio * 0.52), 8.0, true)
		var pulse := 0.65 if reduced_motion else 0.55 + sin(Time.get_ticks_msec() * 0.0025 + index) * 0.10
		draw_circle(Vector2(x, y + (15 if top else -15)), 4.0 + ratio * 3.0, Color(accent, pulse if ratio > 0.0 else 0.18))
	# Nodo mappa sempre raggiungibile visivamente al centro del ponte.
	draw_circle(Vector2.ZERO, 45.0, Color(0.03, 0.13, 0.15, 0.96))
	draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 40, Color("f7d37a"), 3.0, true)
	for spoke in 12:
		var angle := TAU * float(spoke) / 12.0
		draw_line(Vector2.RIGHT.rotated(angle) * 20.0, Vector2.RIGHT.rotated(angle) * 34.0, Color("f7d37a"), 2.0, true)
