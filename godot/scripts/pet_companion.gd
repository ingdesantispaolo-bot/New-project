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
var _expression_pose := "sereno"
var _expression_time := 0.0
var _expression_duration := 0.0
var _expression_mark: Node2D

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
	_expression_mark = Node2D.new()
	_expression_mark.name = "PetExpressionPose"
	_expression_mark.position = Vector2(0, -42)
	add_child(_expression_mark)

## **La freccia del Custode.** (7 agosto 2026)
##
## Segnalazione di gioco: «il pallino giallo che segue il personaggio non sembra
## significare qualcosa». Era vero — seguiva Eli e basta — e nella stessa
## segnalazione c'era anche «e' noioso girovagare senza uno scopo». Le due cose
## si rispondono a vicenda: il compagno diventa la **bussola**.
##
## Punta verso la prova non ancora fatta piu' vicina. Non ci porta e non la
## nomina: indica una direzione, e la scelta resta di Eli. Un compagno che
## decidesse la strada trasformerebbe l'esplorazione in un corridoio, che e'
## esattamente il difetto da cui veniamo.
##
## Il Custode non da' MAI vantaggi di gioco (contratto di `pet_state.gd`): una
## direzione non e' un vantaggio, e' un'informazione che la mappa gia' contiene —
## la stessa che si otterrebbe girando in tondo, ma senza la noia di girare in
## tondo.
var _freccia: Polygon2D

func _crea_freccia() -> void:
	_freccia = Polygon2D.new()
	_freccia.name = "GuideArrow"
	_freccia.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(6, 5), Vector2(0, 1), Vector2(-6, 5)])
	_freccia.color = Color(1.0, 0.86, 0.42, 0.88)
	_freccia.position = Vector2(0, -26)
	_freccia.visible = false
	add_child(_freccia)

## L'obiettivo piu' vicino fra quelli ancora aperti. `Vector2.INF` se non ce ne
## sono: a quel punto la freccia sparisce invece di puntare a caso.
func _obiettivo_piu_vicino() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.INF
	var migliore := Vector2.INF
	var distanza := INF
	for nodo in get_tree().get_nodes_in_group("world_interactable"):
		if not (nodo is Node2D):
			continue
		if bool((nodo as Node).get_meta("completed", false)):
			continue
		var d: float = target.global_position.distance_to((nodo as Node2D).global_position)
		if d < distanza:
			distanza = d
			migliore = (nodo as Node2D).global_position
	return migliore

func _aggiorna_freccia() -> void:
	if not is_instance_valid(_freccia) or not is_instance_valid(target):
		return
	var meta := _obiettivo_piu_vicino()
	if meta == Vector2.INF:
		_freccia.visible = false
		return
	# Sotto una certa distanza la freccia si spegne: sei arrivato, e una freccia
	# che punta a due passi e' rumore.
	var d: float = target.global_position.distance_to(meta)
	if d < 190.0:
		_freccia.visible = false
		return
	_freccia.visible = true
	var verso: Vector2 = meta - target.global_position
	_freccia.rotation = verso.angle() + PI * 0.5

func _process(delta: float) -> void:
	if not _reduced_motion:
		_bob += delta
	if _freccia == null:
		_crea_freccia()
	_aggiorna_freccia()
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
		_update_expression_pose(delta)
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

## Traduce il volto già deciso da PetExpressionEngine in una posa del corpo.
## Non decide eventi né utilità: è soltanto la parte visibile di C-G9.
func react_to(game_signal: String) -> void:
	_expression_pose = PetExpressionEngine.face_for(game_signal)
	_expression_time = 0.0
	_expression_duration = maxf(1.0, PetExpressionEngine.duration_of(_expression_pose))
	set_meta("expression_pose", _expression_pose)
	react()
	queue_redraw()

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

## Fa starnutire il Custode adesso, a prescindere dal turno delle combinelle
## ambientali. Vero se è partito davvero.
func force_sneeze() -> bool:
	return is_instance_valid(_antics) and str(_antics.force_sneeze()) == "sneeze"

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

func _update_expression_pose(delta: float) -> void:
	if _expression_duration <= 0.0 or not is_instance_valid(visual):
		return
	_expression_time += delta
	var phase := clampf(_expression_time / _expression_duration, 0.0, 1.0)
	if _expression_time >= _expression_duration:
		_expression_duration = 0.0
		_expression_pose = "sereno"
		set_meta("expression_pose", _expression_pose)
		queue_redraw()
		return
	if _reduced_motion:
		match _expression_pose:
			"festa", "orgoglioso": visual.rotation = -0.10
			"curioso": visual.rotation = 0.14
			"attento", "concentrato": visual.rotation = -0.04
			"incoraggiante": visual.rotation = 0.06
		return
	var pulse := sin(phase * PI)
	match _expression_pose:
		"festa":
			visual.rotation = sin(_expression_time * 8.0) * 0.18 * pulse
		"orgoglioso":
			visual.rotation = -0.12 * pulse
			visual.scale *= 1.0 + 0.16 * pulse
		"curioso":
			visual.rotation = 0.20 * pulse
		"attento", "concentrato":
			visual.rotation = sin(_expression_time * 3.0) * 0.035
			visual.position.y += 3.0 * pulse
		"incoraggiante":
			visual.rotation = sin(_expression_time * 4.5) * 0.08 * pulse

func _draw() -> void:
	if _expression_duration <= 0.0 or _expression_pose == "sereno":
		return
	var accent := Color("f6c85f")
	match _expression_pose:
		"curioso":
			draw_arc(Vector2(18, -48), 8, -0.4, 2.4, 12, accent, 2.0, true)
		"attento", "concentrato":
			draw_line(Vector2(-16, -47), Vector2(16, -47), Color("7ad7ff"), 3.0, true)
		"orgoglioso", "festa":
			for index in 5:
				var angle := TAU * float(index) / 5.0
				draw_circle(Vector2.RIGHT.rotated(angle) * 27 + Vector2(0, -15), 2.5, accent)
		"incoraggiante":
			draw_arc(Vector2(0, -16), 30, 0.25, PI - 0.25, 18, Color("8ff6d2"), 2.5, true)
