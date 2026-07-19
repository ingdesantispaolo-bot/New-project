class_name OutdoorPlayerController
extends CharacterBody2D

@export var speed := 260.0
var touch_target := Vector2.INF

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 0.0:
		velocity = input_vector * speed
	elif touch_target != Vector2.INF:
		var direction := global_position.direction_to(touch_target)
		velocity = direction * speed
		if global_position.distance_to(touch_target) < 8.0:
			touch_target = Vector2.INF
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func set_touch_target(target: Vector2) -> void:
	touch_target = target
