class_name WorldEnemy
extends CharacterBody2D

## **Le sacche di Silenzio.** Pattugliano, inseguono e respingono Eli.
##
## **Cattive sul serio dal 7 agosto 2026**, su indicazione del committente dopo
## un collaudo: «devono essere sempre piu' cattivi man mano che saliamo di
## livello». Prima erano un ostacolo puramente scenico — respingevano e basta,
## e il grado di potenza appena introdotto non serviva a niente contro di loro.
##
## Adesso il contatto **costa energia**, e la cifra e' la differenza fra quanto
## e' forte la sacca e quanto e' forte Eli:
##
##     costo = (grado della sacca − grado di Eli) × COSTO_PER_GRADO
##
## Che e' il punto di tutto il lotto precedente: **la barra della potenza serve a
## qualcosa**. Chi si allena passa in mezzo alle sacche senza pagare; chi non si
## allena le paga tutte. E siccome il grado si guadagna facendo prove, la strada
## per diventare piu' forti e' la stessa che il gioco vuole insegnare.
##
## **Non blocca mai.** Se l'energia non basta si paga quel che c'e' e si passa
## lo stesso: e' la regola di tutta la mappa — niente che sta qui puo' fermare
## la progressione. L'impulso continua a stabilizzarle, e resta la via gratuita
## per chi preferisce pensare invece di incassare.

## Quanta energia costa ogni grado di scarto. Due: un incontro sfortunato si
## assorbe, una traversata fatta di sacche no.
const COSTO_PER_GRADO := 2

var world: Node
var anchor := Vector2.ZERO
var tier := 1
var accent := Color("ff7b72")
var enemy_name := "Sbiadito"
var phase := 0.0
var stunned_until_msec := 0
var contact_ready_msec := 0
var reduced_motion := false
var body_shape: CollisionShape2D
var contact_area: Area2D
var visual: Node2D

func setup(world_ref: Node, start: Vector2, level: int, subject: String, color: Color, index: int) -> void:
	world = world_ref
	anchor = start
	position = start
	# Il grado cresce ogni TRE mondi invece che ogni sei: a ventiquattro mondi
	# la scala arriva a otto invece che a quattro, e la differenza fra il mondo 3
	# e il mondo 21 si sente. Prima due mondi lontanissimi avevano la stessa
	# sacca.
	tier = clampi(1 + floori(float(level - 1) / 3.0), 1, 8)
	accent = color
	phase = float(index) * 1.73
	enemy_name = _name_for_subject(subject, tier)
	set_meta("nature", "sacca_di_silenzio")
	set_meta("stabilized", false)
	add_to_group("world_enemy")
	_build_collision()
	_build_visual(level)

func _build_collision() -> void:
	body_shape = CollisionShape2D.new()
	body_shape.name = "EnemyBodyCollision"
	var body_circle := CircleShape2D.new()
	body_circle.radius = 22.0 + float(mini(tier, 4)) * 2.0
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
	visual = Node2D.new()
	visual.name = "EnemyVisual"
	visual.scale = Vector2.ONE * (1.06 + float(tier) * 0.055)
	visual.add_child(OutdoorVisualFactory.make_shadow(24.0, 8.0, 0.42, 20.0))
	var faded_accent := accent.lerp(Color("9299a8"), 0.68)
	var aura := OutdoorVisualFactory.make_glow(40.0 + tier * 4.0, faded_accent, 0.22)
	aura.add_to_group("night_glow")
	visual.add_child(aura)
	var shell_color := faded_accent.darkened(0.38)
	var outer_ring := OutdoorVisualFactory.make_ring(31.0 + tier * 2.0, Color(faded_accent, 0.48), 2.6, 28)
	outer_ring.scale = Vector2(1.0, 0.82)
	outer_ring.position.y = -6
	visual.add_child(outer_ring)
	for shard_index in range(3 + tier):
		var shard_angle := TAU * float(shard_index) / float(3 + tier) + phase * 0.15
		var shard := OutdoorVisualFactory.make_polygon(PackedVector2Array([
			Vector2(-4, 5), Vector2(0, -7), Vector2(4, 5), Vector2(0, 2),
		]), Color(faded_accent, 0.66))
		shard.position = Vector2(cos(shard_angle), sin(shard_angle)) * Vector2(36.0 + tier, 27.0 + tier)
		shard.rotation = shard_angle + PI * 0.5
		visual.add_child(shard)
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
	# Non e' un occhio ostile: e' un'iscrizione diventata illeggibile.
	var glyph_glow := OutdoorVisualFactory.make_glow(10.0, Color("c5cad3"), 0.46)
	glyph_glow.name = "FadedGlyphGlow"
	glyph_glow.position = Vector2(0, -8)
	visual.add_child(glyph_glow)
	visual.add_child(OutdoorVisualFactory.make_polygon(
		OutdoorVisualFactory.circle_polygon(3.8, 12), faded_accent.lightened(0.18), Vector2(0, -8)))
	visual.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
		Vector2(-11, -9), Vector2(-4, -13), Vector2(4, -13),
		Vector2(11, -9), Vector2(4, -5), Vector2(-4, -5),
	]), Color(0.02, 0.05, 0.08, 0.88)))
	visual.add_child(OutdoorVisualFactory.make_polygon(
		OutdoorVisualFactory.circle_polygon(3.2, 12), faded_accent.lightened(0.32), Vector2(0, -9)))
	for line_index in 3:
		var fragment := Line2D.new()
		fragment.name = "BrokenInscription_%d" % line_index
		fragment.width = 2.2
		fragment.default_color = Color("c7ccd4", 0.48)
		fragment.points = PackedVector2Array([
			Vector2(-13 + line_index * 2, 4 + line_index * 5),
			Vector2(-3, 4 + line_index * 5),
			Vector2(4, 3 + line_index * 5),
			Vector2(12 - line_index * 2, 4 + line_index * 5),
		])
		visual.add_child(fragment)
	var tier_ring := OutdoorVisualFactory.make_ring(27.0 + tier * 2.0, Color(accent, 0.72), 2.0, 24)
	tier_ring.scale = Vector2(1.0, 0.34)
	tier_ring.position.y = 17
	visual.add_child(tier_ring)
	add_child(visual)

	var label := Label.new()
	label.name = "EnemyLabel"
	label.text = "SBIADITO · T%d" % tier
	label.position = Vector2(-80, -76)
	label.custom_minimum_size.x = 140
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_color", accent.lightened(0.25))
	label.accessibility_name = "%s, sacca di Silenzio; l'impulso la rende leggibile" % enemy_name
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
	var speed := 74.0 + float(tier) * 11.0
	velocity = global_position.direction_to(target) * speed
	if global_position.distance_to(target) < 8.0:
		velocity = Vector2.ZERO
	move_and_slide()

func stun(seconds: float = 5.0) -> void:
	stunned_until_msec = Time.get_ticks_msec() + roundi(seconds * 1000.0)
	velocity = Vector2.ZERO
	body_shape.set_deferred("disabled", true)
	(contact_area.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	set_meta("stabilized", true)
	if reduced_motion:
		modulate = Color(0.78, 0.98, 1.0, 0.96)
		scale = Vector2.ONE * 0.96
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.78, 0.98, 1.0, 0.96), 0.18)
	tween.tween_property(self, "scale", Vector2.ONE * 0.94, 0.18)

func is_stunned() -> bool:
	return Time.get_ticks_msec() < stunned_until_msec

func _restore() -> void:
	position = anchor
	modulate = Color.WHITE
	scale = Vector2.ONE
	set_meta("stabilized", false)
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
		"matematica": "Sbiadito dei Conti", "italiano": "Sbiadito delle Parole",
		"coding": "Sbiadito dei Cicli", "inglese": "Sbiadito delle Voci",
		"fisica": "Sbiadito del Moto", "musica": "Sbiadito dei Suoni",
		"latino": "Sbiadito dei Glifi", "elettronica": "Sbiadito dei Circuiti",
		"geografia": "Sbiadito delle Mappe", "scienze": "Sbiadito delle Forme",
		"storia": "Sbiadito delle Memorie", "logica": "Sbiadito delle Regole",
	}
	var romani := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
	return "%s %s" % [str(names.get(subject, "Sbiadito")), romani[clampi(rank, 1, romani.size()) - 1]]
