class_name OutdoorPetCompanion
extends Node2D

## Compagno equipaggiato in bottega: segue il player con smorzamento, fluttua
## e scatta una reazione festosa quando Eli raccoglie un tesoro o affronta una
## prova. Chiude il loop shopping ↔ avventura: comprare un pet lo fa comparire
## accanto a te nel mondo.

var target  # OutdoorPlayerController (untyped: accesso dinamico a .velocity)
var visual: Node2D
var offset := Vector2(-34, -6)
var _bob := 0.0
var _react := 0.0

func setup(kind: String, color: Color, follow_target) -> void:
	target = follow_target
	visual = OutdoorVisualFactory.build_pet(kind, color)
	add_child(visual)
	z_index = 8
	if is_instance_valid(target):
		global_position = target.global_position + offset
	_bob = randf() * TAU

func _process(delta: float) -> void:
	_bob += delta
	if is_instance_valid(target):
		# il pet resta sul lato opposto alla direzione di marcia
		var side := signf(offset.x)
		if target.velocity.x > 8.0:
			side = -1.0
		elif target.velocity.x < -8.0:
			side = 1.0
		var desired: Vector2 = target.global_position + Vector2(absf(offset.x) * side, offset.y)
		global_position = global_position.lerp(desired, minf(1.0, delta * 5.0))
	if visual != null:
		var lift := sin(_bob * 3.2) * 3.0
		if _react > 0.0:
			_react = maxf(0.0, _react - delta * 2.4)
			lift -= _react * 11.0
			visual.scale = Vector2.ONE * (1.0 + _react * 0.28)
		visual.position.y = -14.0 + lift

func react() -> void:
	_react = 1.0
	var burst := OutdoorVisualFactory.make_sparkles(Color(1.0, 0.92, 0.6, 0.9), 9.0, 7)
	burst.one_shot = true
	burst.explosiveness = 0.8
	burst.lifetime = 1.0
	burst.position = Vector2(0, -14)
	add_child(burst)
	burst.emitting = true
	get_tree().create_timer(1.4).timeout.connect(burst.queue_free)
