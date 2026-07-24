class_name WorldEnemy
extends CharacterBody2D

## Ostacolo esplorativo non punitivo: pattuglia, insegue a breve raggio e
## respinge Eli, ma non tocca energia/mastery. L'impulso lo stabilizza per alcuni
## secondi, aprendo una finestra per raggiungere il POI.

var world: Node
var anchor := Vector2.ZERO
var tier := 1
var accent := Color("ff7b72")
var enemy_name := "Sentinella"
var phase := 0.0
var stunned_until_msec := 0
var contact_ready_msec := 0
var body_shape: CollisionShape2D
var contact_area: Area2D

func setup(world_ref: Node, start: Vector2, level: int, subject: String, color: Color, index: int) -> void:
	world = world_ref
	anchor = start
	position = start
	tier = clampi(1 + floori(float(level - 1) / 6.0), 1, 4)
	accent = color
	phase = float(index) * 1.73
	enemy_name = _name_for_subject(subject, tier)
	add_to_group("world_enemy")
	_build_collision()
	_build_visual(level)

func _build_collision() -> void:
	body_shape = CollisionShape2D.new()
	body_shape.name = "EnemyBodyCollision"
	var body_circle := CircleShape2D.new()
	body_circle.radius = 22.0 + float(tier) * 2.0
	body_shape.shape = body_circle
	add_child(body_shape)
	contact_area = Area2D.new()
	contact_area.name = "EnemyContact"
	var contact_shape := CollisionShape2D.new()
	var contact_circle := CircleShape2D.new()
	contact_circle.radius = 34.0 + float(tier) * 2.0
	contact_shape.shape = contact_circle
	contact_area.add_child(contact_shape)
	contact_area.body_entered.connect(_on_body_entered)
	add_child(contact_area)

func _build_visual(level: int) -> void:
	var visual := Node2D.new()
	visual.name = "EnemyVisual"
	visual.add_child(OutdoorVisualFactory.make_shadow(20.0, 7.0, 0.38, 18.0))
	var aura := OutdoorVisualFactory.make_glow(36.0 + tier * 4.0, accent, 0.34)
	aura.add_to_group("night_glow")
	visual.add_child(aura)
	var shell_color := accent.darkened(0.34)
	match posmod(level - 1, 4):
		0:
			visual.add_child(OutdoorVisualFactory.make_polygon(
				OutdoorVisualFactory.ellipse_polygon(21, 15, 20), shell_color, Vector2(0, -7)))
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([Vector2(-29, -7), Vector2(-18, -14), Vector2(-18, 0)]), Color(accent, 0.82)))
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([Vector2(29, -7), Vector2(18, -14), Vector2(18, 0)]), Color(accent, 0.82)))
		1:
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([Vector2(0, -33), Vector2(23, -5), Vector2(0, 18), Vector2(-23, -5)]), shell_color))
		2:
			var ring := OutdoorVisualFactory.make_ring(24.0, accent, 5.0, 6)
			ring.position.y = -6
			visual.add_child(ring)
			visual.add_child(OutdoorVisualFactory.make_polygon(
				OutdoorVisualFactory.circle_polygon(15, 16), shell_color, Vector2(0, -6)))
		_:
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([
					Vector2(-23, 10), Vector2(-17, -25), Vector2(0, -34),
					Vector2(17, -25), Vector2(23, 10), Vector2(0, 19),
				]), shell_color))
	var eye := OutdoorVisualFactory.make_glow(10.0, Color.WHITE, 0.88)
	eye.position = Vector2(0, -8)
	visual.add_child(eye)
	visual.add_child(OutdoorVisualFactory.make_polygon(
		OutdoorVisualFactory.circle_polygon(3.8, 12), accent.lightened(0.28), Vector2(0, -8)))
	var tier_ring := OutdoorVisualFactory.make_ring(27.0 + tier * 2.0, Color(accent, 0.72), 2.0, 24)
	tier_ring.scale = Vector2(1.0, 0.34)
	tier_ring.position.y = 17
	visual.add_child(tier_ring)
	add_child(visual)

	var label := Label.new()
	label.name = "EnemyLabel"
	label.text = "%s · T%d" % [enemy_name.to_upper(), tier]
	label.position = Vector2(-70, -58)
	label.custom_minimum_size.x = 140
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_color", accent.lightened(0.25))
	add_child(label)

func _physics_process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now < stunned_until_msec:
		velocity = Vector2.ZERO
		return
	if modulate.a < 0.99:
		_restore()
	if world == null or not world.has_method("enemy_gameplay_active") or not bool(world.call("enemy_gameplay_active")):
		velocity = Vector2.ZERO
		return
	phase += delta * (0.75 + float(tier) * 0.08)
	var target := anchor + Vector2(cos(phase), sin(phase * 0.72)) * Vector2(92.0, 62.0)
	var player := world.get("player") as CharacterBody2D
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		if distance < 250.0 + tier * 20.0:
			target = player.global_position
	var speed := 74.0 + float(tier) * 14.0
	velocity = global_position.direction_to(target) * speed
	if global_position.distance_to(target) < 8.0:
		velocity = Vector2.ZERO
	move_and_slide()

func stun(seconds: float = 5.0) -> void:
	stunned_until_msec = Time.get_ticks_msec() + roundi(seconds * 1000.0)
	velocity = Vector2.ZERO
	body_shape.set_deferred("disabled", true)
	(contact_area.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.22, 0.18)
	tween.tween_property(self, "scale", Vector2.ONE * 0.42, 0.18)

func is_stunned() -> bool:
	return Time.get_ticks_msec() < stunned_until_msec

func _restore() -> void:
	position = anchor
	modulate.a = 1.0
	scale = Vector2.ONE
	body_shape.set_deferred("disabled", false)
	(contact_area.get_child(0) as CollisionShape2D).set_deferred("disabled", false)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or is_stunned():
		return
	var now := Time.get_ticks_msec()
	if now < contact_ready_msec:
		return
	contact_ready_msec = now + 1100
	if world != null and world.has_method("_on_enemy_contact"):
		world.call("_on_enemy_contact", self, body)

func _name_for_subject(subject: String, rank: int) -> String:
	var names := {
		"matematica": "Drone Pattern", "italiano": "Eco delle Parole",
		"coding": "Sentinella Loop", "inglese": "Warden Lessicale",
		"fisica": "Custode d'Inerzia", "musica": "Dissonanza",
		"latino": "Guardia dei Glifi", "elettronica": "Impulso Errante",
		"geografia": "Atlante Mobile", "scienze": "Spora Guardiana",
		"cittadinanza": "Arbitro Corrotto", "logica": "Paradosso",
	}
	return "%s %s" % [str(names.get(subject, "Anomalia")), ["I", "II", "III", "IV"][rank - 1]]
