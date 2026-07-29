class_name OutdoorPlayerController
extends CharacterBody2D

@export var speed := 260.0

var touch_target := Vector2.INF
## Contenitore visivo animato (assegnato da outdoor_world alla creazione):
## bob e inclinazione durante la camminata, flip orizzontale sulla direzione.
var visual: Node2D
var reduced_motion := false
var _walk_time := 0.0
var _action_until_msec := 0

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_speed := speed * (1.65 if Input.is_action_pressed("sprint") else 1.0)
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
	var direction_row := 0
	if absf(velocity.x) > absf(velocity.y):
		direction_row = 3 if velocity.x > 0.0 else 2
	elif velocity.y < -8.0:
		direction_row = 1
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
		(sprite.texture as AtlasTexture).region = Rect2(frame * 96, direction_row * 96, 96, 96)
