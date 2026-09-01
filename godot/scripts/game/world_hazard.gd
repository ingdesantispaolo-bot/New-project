class_name WorldHazard
extends Area2D

## Un pericolo ambientale non e' un muro: occupa spazio visivo, non spazio
## fisico. Il giocatore puo' attraversarlo in ogni fase; soltanto l'impulso
## attivo produce una conseguenza concreta.

signal exposed(hazard: Area2D, body: Node)
signal phase_changed(hazard: Area2D, phase: String)

const SAFE := "safe"
const WARNING := "warning"
const ACTIVE := "active"

const INTERACTION_RADIUS := 96.0
const DANGER_RADIUS := 76.0
const SAFE_SECONDS := 2.45
const WARNING_SECONDS := 1.0
const ACTIVE_SECONDS := 0.85
const SURGE_SAFE_SECONDS := 1.15
const SURGE_WARNING_SECONDS := 0.65
const SURGE_ACTIVE_SECONDS := 1.2

var hazard_label := "zona instabile"
var accent := Color("ffb35c")
var reduced_motion := false
var surging := false
var challenge_subject := ""
var challenge_level := 0
var threat_tier := 1
var _failure_surge_remaining := 0.0

var _elapsed := 0.0
var _state := SAFE
var _hit_this_cycle: Dictionary = {}
var _caption: Label
var _glyph: Label
var _forced_state := ""

func configure(
	identifier: String, label: String, color: Color, cost: int,
	phase_offset: float, prefers_reduced_motion: bool
) -> void:
	name = "WorldHazard_%s" % identifier
	hazard_label = label
	accent = color
	reduced_motion = prefers_reduced_motion
	_elapsed = maxf(0.0, phase_offset)
	set_meta("kind", "hazard")
	set_meta("id", identifier)
	set_meta("payload", {"cost": cost, "label": label})
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = true
	add_to_group("world_interactable")
	add_to_group("world_hazard")

	var collision := CollisionShape2D.new()
	collision.name = "InteractionAndExposureArea"
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_RADIUS
	collision.shape = circle
	add_child(collision)

	_caption = Label.new()
	_caption.name = "HazardCaption"
	_caption.text = label.to_upper()
	_caption.position = Vector2(-120, -121)
	_caption.custom_minimum_size = Vector2(240, 24)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 12)
	_caption.add_theme_constant_override("outline_size", 5)
	_caption.add_theme_color_override("font_color", accent.lightened(0.25))
	add_child(_caption)

	_glyph = Label.new()
	_glyph.name = "HazardGlyph"
	_glyph.text = "!"
	_glyph.position = Vector2(-11, -28)
	_glyph.custom_minimum_size = Vector2(22, 34)
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.add_theme_font_size_override("font_size", 30)
	_glyph.add_theme_constant_override("outline_size", 6)
	_glyph.add_theme_color_override("font_color", accent.lightened(0.25))
	add_child(_glyph)

	_update_state(true)
	queue_redraw()

func set_surging(value: bool) -> void:
	if surging == value:
		return
	var old_total := _cycle_seconds()
	var progress := fposmod(_elapsed, old_total) / old_total
	surging = value
	_elapsed = progress * _cycle_seconds()
	_update_state(true)

func mark_as_challenge(subject: String, level: int = 1, tier: int = 1) -> void:
	challenge_subject = subject
	challenge_level = clampi(level, 1, 24)
	threat_tier = clampi(tier, 1, 5)
	add_to_group("world_challenge_hazard")
	if is_instance_valid(_caption):
		_caption.text = "%s\nRISCHIO %d/5 · PROVA DI %s" % [
			hazard_label.to_upper(), threat_tier, subject.to_upper()]
		_caption.position = Vector2(-140, -145)
		_caption.custom_minimum_size = Vector2(280, 44)
		_caption.add_theme_font_size_override("font_size", 11)
	queue_redraw()

func punish_failure(seconds: float) -> void:
	var was_intensified := _is_intensified()
	var old_total := _cycle_seconds()
	var progress := fposmod(_elapsed, old_total) / old_total
	_failure_surge_remaining = maxf(_failure_surge_remaining, seconds)
	if not was_intensified:
		_elapsed = progress * _cycle_seconds()
	_update_state(true)

func failure_surge_active() -> bool:
	return _failure_surge_remaining > 0.0

func phase_name() -> String:
	return _forced_state if not _forced_state.is_empty() else _state

func force_phase_for_audit(value: String) -> void:
	_forced_state = value
	_update_state(true)

func _process(delta: float) -> void:
	if _failure_surge_remaining > 0.0:
		var old_total := _cycle_seconds()
		_failure_surge_remaining = maxf(0.0, _failure_surge_remaining - maxf(delta, 0.0))
		if _failure_surge_remaining <= 0.0 and not surging:
			var progress := fposmod(_elapsed, old_total) / old_total
			_elapsed = progress * _cycle_seconds()
	if _forced_state.is_empty():
		_elapsed += maxf(delta, 0.0)
	_update_state(false)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if phase_name() != ACTIVE:
		return
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if global_position.distance_to((body as Node2D).global_position) > DANGER_RADIUS:
			continue
		var body_id := body.get_instance_id()
		if _hit_this_cycle.has(body_id):
			continue
		_hit_this_cycle[body_id] = true
		exposed.emit(self, body)

func _update_state(force: bool) -> void:
	var next := _forced_state if not _forced_state.is_empty() else _state_at(_elapsed)
	if not force and next == _state:
		return
	var previous := _state
	if next == ACTIVE and _state != ACTIVE:
		_hit_this_cycle.clear()
	_state = next
	if is_instance_valid(_glyph):
		_glyph.text = "!" if _state == ACTIVE else "?" if not challenge_subject.is_empty() else "·" if _state == SAFE else "!"
	if previous != _state:
		phase_changed.emit(self, _state)
	queue_redraw()

func _state_at(time: float) -> String:
	var cursor := fposmod(time, _cycle_seconds())
	var safe := _safe_seconds()
	var warning := _warning_seconds()
	if cursor < safe:
		return SAFE
	if cursor < safe + warning:
		return WARNING
	return ACTIVE

func _cycle_seconds() -> float:
	return _safe_seconds() + _warning_seconds() + _active_seconds()

func _is_intensified() -> bool:
	return surging or _failure_surge_remaining > 0.0

func _difficulty_ratio() -> float:
	return clampf(float(challenge_level - 1) / 23.0, 0.0, 1.0) if challenge_level > 0 else 0.0

func _safe_seconds() -> float:
	if _is_intensified():
		return SURGE_SAFE_SECONDS
	return lerpf(SAFE_SECONDS, 1.55, _difficulty_ratio())

func _warning_seconds() -> float:
	if _is_intensified():
		return SURGE_WARNING_SECONDS
	return lerpf(WARNING_SECONDS, 0.62, _difficulty_ratio())

func _active_seconds() -> float:
	if _is_intensified():
		return SURGE_ACTIVE_SECONDS
	return lerpf(ACTIVE_SECONDS, 1.25, _difficulty_ratio())

func _draw() -> void:
	var phase := phase_name()
	var fill_alpha := 0.09
	var ring_alpha := 0.58
	var ring_color := accent
	if phase == WARNING:
		fill_alpha = 0.18
		ring_alpha = 0.88
		ring_color = Color("ffd36b")
	elif phase == ACTIVE:
		fill_alpha = 0.31
		ring_alpha = 1.0
		ring_color = Color("ff715f")
	elif phase == SAFE:
		ring_color = Color("78e3c4")

	var pulse := 1.0
	if not reduced_motion:
		pulse = 0.94 + sin(_elapsed * (6.0 if phase == ACTIVE else 3.0)) * 0.045
	draw_circle(Vector2.ZERO, DANGER_RADIUS * pulse, Color(ring_color, fill_alpha))
	draw_arc(Vector2.ZERO, DANGER_RADIUS * pulse, 0.0, TAU, 64,
		Color(ring_color, ring_alpha), 4.0, true)
	draw_arc(Vector2.ZERO, INTERACTION_RADIUS, 0.0, TAU, 64,
		Color(accent, 0.24), 2.0, true)
	# Quattro tacche rendono il bordo riconoscibile anche senza affidarsi al
	# colore (daltonismo, contrasto elevato, nebbia del mondo).
	for index in range(4):
		var direction := Vector2.RIGHT.rotated(float(index) * PI * 0.5)
		draw_line(direction * 82.0, direction * 94.0,
			Color(ring_color, ring_alpha), 4.0, true)
	if not challenge_subject.is_empty():
		var diamond_radius := 112.0 + float(threat_tier - 1) * 4.0
		var diamond := PackedVector2Array([
			Vector2(0, -diamond_radius), Vector2(diamond_radius, 0),
			Vector2(0, diamond_radius), Vector2(-diamond_radius, 0),
			Vector2(0, -diamond_radius),
		])
		draw_polyline(diamond, Color(accent, 0.82), 2.6 + threat_tier * 0.38, true)
		# Dal rischio 3 compare un secondo sigillo ruotato: i mondi avanzati si
		# riconoscono dalla silhouette anche senza leggere il numero o il colore.
		if threat_tier >= 3:
			var inner_radius := diamond_radius - 13.0
			var rotated := PackedVector2Array()
			for index in range(9):
				rotated.append(Vector2.RIGHT.rotated(PI * 0.25 + TAU * float(index) / 8.0) * inner_radius)
			draw_polyline(rotated, Color(accent, 0.36 + threat_tier * 0.07), 2.0, true)
		# Tacche di rischio: da una a cinque, stabili anche con movimento ridotto.
		var pip_spacing := 13.0
		var pip_start := -float(threat_tier - 1) * pip_spacing * 0.5
		for index in range(threat_tier):
			var center := Vector2(pip_start + float(index) * pip_spacing, diamond_radius + 13.0)
			var pip := PackedVector2Array([
				center + Vector2(0, -4), center + Vector2(4, 0),
				center + Vector2(0, 4), center + Vector2(-4, 0),
				center + Vector2(0, -4),
			])
			draw_colored_polygon(pip, Color(ring_color, 0.82))
