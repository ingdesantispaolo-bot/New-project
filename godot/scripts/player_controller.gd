class_name OutdoorPlayerController
extends CharacterBody2D

@export var speed := 260.0

var touch_target := Vector2.INF
## Contenitore visivo animato (assegnato da outdoor_world alla creazione):
## bob e inclinazione durante la camminata, flip orizzontale sulla direzione.
var visual: Node2D
var _walk_time := 0.0

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
	_animate(delta)

func set_touch_target(target: Vector2) -> void:
	touch_target = target

func _animate(delta: float) -> void:
	if visual == null:
		return
	if velocity.length() > 8.0:
		_walk_time += delta * 11.0
		visual.position.y = -absf(sin(_walk_time)) * 3.2
		visual.rotation = sin(_walk_time) * 0.05
		if absf(velocity.x) > 8.0:
			visual.scale.x = -1.0 if velocity.x < 0.0 else 1.0
	else:
		_walk_time = 0.0
		visual.position.y = lerpf(visual.position.y, 0.0, minf(10.0 * delta, 1.0))
		visual.rotation = lerpf(visual.rotation, 0.0, minf(10.0 * delta, 1.0))
