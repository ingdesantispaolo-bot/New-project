class_name OutdoorPlayerController
extends CharacterBody2D

## Eli cammina: la mappa non contiene più una scorciatoia motoria che cambi il
## rapporto con le sacche del Silenzio. Acqua e varchi restano fisici.

@export var speed := 260.0

var touch_target := Vector2.INF
var visual: Node2D
var reduced_motion := false
var _walk_time := 0.0
var _facing_row := 0
var _footstep_clock := 0.0

const FACING_DOWN_ROW := 0
const FACING_UP_ROW := 1
const FACING_RIGHT_ROW := 2
const FACING_LEFT_ROW := 3

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 0.0:
		velocity = input_vector * speed
		touch_target = Vector2.INF
	elif touch_target != Vector2.INF:
		var direction := global_position.direction_to(touch_target)
		velocity = direction * speed
		if global_position.distance_to(touch_target) < 8.0:
			touch_target = Vector2.INF
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_update_footsteps(delta)
	_animate(delta)

func _update_footsteps(delta: float) -> void:
	if velocity.length() <= 8.0:
		_footstep_clock = 0.0
		return
	_footstep_clock += delta
	if _footstep_clock < 0.34:
		return
	_footstep_clock = fmod(_footstep_clock, 0.34)
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		var alternation := 0.96 if posmod(floori(_walk_time), 2) == 0 else 1.04
		audio.call("play", "footstep", alternation)

func set_touch_target(target: Vector2) -> void:
	touch_target = target

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
		var frame := walk_frame if velocity.length() > 8.0 else 0
		(sprite.texture as AtlasTexture).region = Rect2(frame * 96, _facing_row * 96, 96, 96)
