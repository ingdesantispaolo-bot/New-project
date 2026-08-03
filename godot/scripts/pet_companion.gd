class_name OutdoorPetCompanion
extends Node2D

signal antic_started(antic_id: String)

const PET_ANTICS := preload("res://scripts/game/pet_antics.gd")

## Compagno equipaggiato in bottega: segue il player con smorzamento, fluttua
## e scatta una reazione festosa quando Eli raccoglie un tesoro o affronta una
## prova. Chiude il loop shopping ↔ avventura: comprare un pet lo fa comparire
## accanto a te nel mondo.

var target  # OutdoorPlayerController (untyped: accesso dinamico a .velocity)
var visual: Node2D
var offset := Vector2(-34, -6)
var _bob := 0.0
var _react := 0.0
var _reaction_delay := 0.0
var _amplitude := 1.0
var _bounce := false
var _reduced_motion := false
var _antics: Node
var _unlocked_antics: Array = []
var _antic_id := ""
var _antic_time := 0.0

func setup(
	kind: String,
	color: Color,
	follow_target,
	temperament := "vivace",
	reduced_motion := false
) -> void:
	target = follow_target
	set_temperament(temperament)
	set_reduced_motion(reduced_motion)
	visual = OutdoorVisualFactory.build_pet(kind, color)
	add_child(visual)
	_antics = PET_ANTICS.new()
	_antics.name = "PetAntics"
	add_child(_antics)
	_antics.configure([], reduced_motion)
	_antics.antic_started.connect(_on_antic_started)
	_antics.antic_finished.connect(_on_antic_finished)
	z_index = 8
	if is_instance_valid(target):
		global_position = target.global_position + offset
	_bob = randf() * TAU

func _process(delta: float) -> void:
	if not _reduced_motion:
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
		_update_antic_pose(delta)
		var lift := 0.0 if _reduced_motion else sin(_bob * 3.2) * 3.0 * _amplitude
		if _reaction_delay > 0.0:
			_reaction_delay = maxf(0.0, _reaction_delay - delta)
			if _reaction_delay <= 0.0:
				_react = 1.0
		if _react > 0.0:
			_react = maxf(0.0, _react - delta * 2.4)
			if not _reduced_motion:
				lift -= _react * 11.0 * _amplitude
				var bounce_scale := 1.0 + sin(_react * PI * 3.0) * 0.08 if _bounce else 1.0
				visual.scale = Vector2.ONE * (1.0 + _react * 0.28 * _amplitude) * bounce_scale
		else:
			visual.scale = Vector2.ONE
		visual.position.y = -14.0 + lift

func react() -> void:
	var profile := PetExpressionEngine.temperament_profile(_temperament)
	_reaction_delay = float(profile.get("delay", 0.0))
	_react = 1.0 if _reaction_delay <= 0.0 else 0.0
	if _reduced_motion:
		return
	var burst := OutdoorVisualFactory.make_sparkles(Color(1.0, 0.92, 0.6, 0.9), 9.0, 7)
	burst.one_shot = true
	burst.explosiveness = 0.8
	burst.lifetime = 1.0
	burst.position = Vector2(0, -14)
	add_child(burst)
	burst.emitting = true
	get_tree().create_timer(1.4).timeout.connect(burst.queue_free)

var _temperament := "vivace"

func set_temperament(value: String) -> void:
	_temperament = value if PetExpressionEngine.TEMPERAMENTS.has(value) else "vivace"
	var profile := PetExpressionEngine.temperament_profile(_temperament)
	_amplitude = float(profile.get("amplitude", 1.0))
	_bounce = bool(profile.get("bounce", false))

func set_reduced_motion(value: bool) -> void:
	_reduced_motion = value
	if _reduced_motion:
		_react = 0.0
		_reaction_delay = 0.0
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE
	if is_instance_valid(_antics):
		_antics.configure(_unlocked_antics, value)

func configure_antics(unlocked: Array) -> void:
	_unlocked_antics = unlocked.duplicate()
	if is_instance_valid(_antics):
		_antics.configure(_unlocked_antics, _reduced_motion)

func set_antics_blocked(value: bool) -> void:
	if is_instance_valid(_antics):
		_antics.set_blocked(value)

func _on_antic_started(antic_id: String, _duration: float) -> void:
	_antic_id = antic_id
	_antic_time = 0.0
	antic_started.emit(antic_id)

func _on_antic_finished(_finished: String) -> void:
	_antic_id = ""
	if is_instance_valid(visual):
		visual.rotation = 0.0

func _update_antic_pose(delta: float) -> void:
	if _antic_id == "" or not is_instance_valid(visual):
		return
	_antic_time += delta
	match _antic_id:
		"tail":
			visual.rotation = -0.12 if _reduced_motion else sin(_antic_time * 7.0) * 0.22
		"pose":
			visual.rotation = -0.18
		"nap":
			visual.rotation = 0.30
		"guard":
			visual.rotation = 0.08
