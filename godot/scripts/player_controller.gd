class_name OutdoorPlayerController
extends CharacterBody2D

@export var speed := 260.0
## Quanto va più veloce lo scatto. Lo imposta la scena leggendo il contratto
## runtime (`sprintMultiplier`): il modulo «Passo lungo» lo alza, e qui non si sa
## niente di bottega né di acquisti.
var sprint_multiplier := 1.65

var touch_target := Vector2.INF
## Contenitore visivo animato (assegnato da outdoor_world alla creazione):
## bob e inclinazione durante la camminata, con una riga atlas per direzione.
var visual: Node2D
var reduced_motion := false
var _walk_time := 0.0
var _action_until_msec := 0
var _facing_row := 0

const FACING_DOWN_ROW := 0
const FACING_UP_ROW := 1
const FACING_RIGHT_ROW := 2
const FACING_LEFT_ROW := 3

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_speed := speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
	if input_vector.length() > 0.0:
		velocity = input_vector * move_speed
		touch_target = Vector2.INF
	elif touch_target != Vector2.INF:
		var direction := global_position.direction_to(touch_target)
		velocity = direction * move_speed
		if global_position.distance_to(touch_target) < 8.0:
			touch_target = Vector2.INF
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_animate(delta)

func set_touch_target(target: Vector2) -> void:
	touch_target = target

func play_pulse_action() -> void:
	_action_until_msec = Time.get_ticks_msec() + 360

func _animate(delta: float) -> void:
	if visual == null:
		return
	var sprite := visual.find_child("EliSprite", true, false) as Sprite2D
	if velocity.length() > 8.0:
		if absf(velocity.x) > absf(velocity.y):
			_facing_row = FACING_RIGHT_ROW if velocity.x > 0.0 else FACING_LEFT_ROW
		elif velocity.y < -8.0:
			_facing_row = FACING_UP_ROW
		else:
			_facing_row = FACING_DOWN_ROW
	if reduced_motion:
		_walk_time = 0.0
		visual.position.y = 0.0
		visual.rotation = 0.0
	elif velocity.length() > 8.0:
		_walk_time += delta * 9.5
		visual.position.y = -absf(sin(_walk_time * 0.5)) * 1.5
		visual.rotation = sin(_walk_time) * 0.025
	else:
		_walk_time = 0.0
		visual.position.y = lerpf(visual.position.y, 0.0, minf(10.0 * delta, 1.0))
		visual.rotation = lerpf(visual.rotation, 0.0, minf(10.0 * delta, 1.0))
	visual.scale.x = absf(visual.scale.x)
	if sprite != null and sprite.texture is AtlasTexture:
		var walk_frame := 1 if reduced_motion else 1 + posmod(floori(_walk_time), 4)
		var frame := 4 if Time.get_ticks_msec() < _action_until_msec else (walk_frame if velocity.length() > 8.0 else 0)
		(sprite.texture as AtlasTexture).region = Rect2(frame * 96, _facing_row * 96, 96, 96)
