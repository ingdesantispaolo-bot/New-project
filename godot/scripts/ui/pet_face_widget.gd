class_name PetFaceWidget
extends Control

## Volto del Custode, sempre in schermo. Presentazione pura: riceve un segnale di
## gioco e mostra una faccia. Non decide l'espressione (lo fa
## `PetExpressionEngine`), non scrive nel salvataggio, non calcola nulla.
##
## Le quattordici espressioni si distinguono per **forma** — taglio degli occhi, curva
## della bocca, inclinazione delle orecchie — e non per colore: devono restare
## leggibili a contrasto elevato e per chi non distingue le tinte.
##
## Vedi docs/PET_CUSTODE.md §2.

signal cuddled
signal screen_requested

const SIZE := 76.0
const LONG_PRESS_SEC := 0.55

## Ritaglio del volto dentro le tavole 384x384. Il corpo completo continua a
## vivere nel mondo; nel ritratto serve invece leggere occhi e sorriso.
const PORTRAIT_CROPS := {
	"dog": [82.0, 0.0, 270.0, 270.0],
	"cat": [64.0, 0.0, 282.0, 282.0],
	"rabbit": [68.0, 0.0, 278.0, 278.0],
	"spark": [48.0, 28.0, 288.0, 288.0],
	"comet": [0.0, 62.0, 276.0, 276.0],
	"orbit": [32.0, 34.0, 304.0, 304.0],
	"satellite": [20.0, 26.0, 316.0, 316.0],
	"prisma": [40.0, 18.0, 296.0, 296.0],
	"luma": [40.0, 10.0, 300.0, 300.0],
	"guardiano": [42.0, 8.0, 296.0, 296.0],
	"codex": [34.0, 12.0, 308.0, 308.0],
}

var _face := "sereno"
var _resting := "sereno"
var _elapsed := 0.0
var _bond := 0.0
var _pet_name := ""
var _pet_kind := ""
var _pet_art: Texture2D
var _reaction_art: Texture2D
var _temperament := "vivace"
var _display_size := SIZE
var _primary := Color("f6c85f")
var _secondary := Color("ffe3a8")
var _amplitude := 1.0
var _reduced_motion := false
var _available: Array = []
var _pulse := 0.0
var _time := 0.0
var _press_started_msec := -1

func _ready() -> void:
	custom_minimum_size = Vector2(_display_size, _display_size + 16.0)
	# STOP e non IGNORE: il volto si accarezza al tocco. È piccolo e sta in un
	# angolo, quindi non ruba input al mondo.
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Tocca per una carezza · tieni premuto per aprire"
	set_process(true)

func set_display_size(value: float) -> void:
	_display_size = clampf(value, SIZE, 132.0)
	custom_minimum_size = Vector2(_display_size, _display_size + 16.0)
	queue_redraw()

func configure(
	pet_name: String,
	livery: Array,
	temperament: String,
	resting_face: String,
	bond_value: float,
	available_faces: Array,
	reduced_motion: bool,
	pet_kind: String = ""
) -> void:
	_pet_name = pet_name
	_pet_kind = pet_kind.trim_prefix("pet-")
	_temperament = temperament
	_pet_art = OutdoorVisualFactory.pet_art_for(_pet_kind) if not _pet_kind.is_empty() else null
	if livery.size() >= 1:
		_primary = OutdoorVisualFactory.hex_color(int(livery[0]))
	if livery.size() >= 2:
		_secondary = OutdoorVisualFactory.hex_color(int(livery[1]))
	_amplitude = float(PetExpressionEngine.temperament_profile(temperament).get("amplitude", 1.0))
	_resting = resting_face if PetExpressionEngine.is_known(resting_face) else "sereno"
	_bond = clampf(bond_value, 0.0, 1.0)
	_available = available_faces.duplicate()
	_reduced_motion = reduced_motion
	if not _available.has(_face):
		_face = _resting
	_refresh_expression_art()
	queue_redraw()

## Riceve un SEGNALE DI GIOCO, non una faccia: la traduzione è del motore, così la
## UI non può inventare espressioni né scavalcare le priorità.
func react_to(game_signal: String) -> void:
	var candidate := PetExpressionEngine.face_for_pet(game_signal, _temperament, _pet_kind)
	# Un'espressione non ancora sbloccata dal legame non si mostra mai: si ripiega
	# sul volto a riposo, senza saltare la reazione del tutto.
	if not _available.is_empty() and not _available.has(candidate):
		return
	# La carezza e' un gesto diretto: deve avere risposta immediata anche se il
	# Custode stava ancora festeggiando. Le reazioni automatiche conservano invece
	# priorita' e isteresi, cosi' il volto non sfarfalla.
	if game_signal != "cuddle" and not PetExpressionEngine.should_replace(_face, _elapsed, candidate):
		return
	_face = candidate
	_elapsed = 0.0
	_refresh_expression_art()
	if not _reduced_motion:
		_pulse = 1.0
	queue_redraw()

func current_face() -> String:
	return _face

func current_pet_kind() -> String:
	return _pet_kind

## Anteprima statica per l'album: non passa dall'isteresi perché non rappresenta
## una reazione di gioco e non modifica lo stato del Custode.
func set_preview_face(face: String) -> void:
	if not PetExpressionEngine.is_known(face):
		return
	_face = face
	_resting = face
	_elapsed = 0.0
	_reduced_motion = true
	_refresh_expression_art()
	queue_redraw()

func _refresh_expression_art() -> void:
	_reaction_art = OutdoorVisualFactory.pet_reaction_art_for(_pet_kind, _face)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		_handle_press_state(mouse.pressed)
	elif event is InputEventScreenTouch:
		_handle_press_state((event as InputEventScreenTouch).pressed)

func _handle_press_state(pressed: bool) -> void:
	accept_event()
	if pressed:
		_press_started_msec = Time.get_ticks_msec()
		return
	if _press_started_msec < 0:
		return
	var held := float(Time.get_ticks_msec() - _press_started_msec) / 1000.0
	_press_started_msec = -1
	if press_action(held) == "screen":
		screen_requested.emit()
	else:
		cuddled.emit()

static func press_action(duration_sec: float) -> String:
	return "screen" if duration_sec >= LONG_PRESS_SEC else "cuddle"

func _process(delta: float) -> void:
	_elapsed += delta
	if not _reduced_motion:
		_time += delta
		_pulse = maxf(0.0, _pulse - delta * 2.2)
	var hold := PetExpressionEngine.duration_of(_face)
	if hold > 0.0 and _elapsed >= hold and _face != _resting:
		_face = _resting
		_elapsed = 0.0
		_refresh_expression_art()
	queue_redraw()

# --- Disegno -------------------------------------------------------------------

func _draw() -> void:
	var portrait_size := _display_size
	var center := Vector2(portrait_size * 0.5, portrait_size * 0.5)
	var breath := 1.0
	if not _reduced_motion:
		breath = 1.0 + sin(_time * 2.1) * 0.018 + _pulse * 0.06 * _amplitude

	# Anello del legame: si completa lentamente e non torna mai indietro.
	draw_arc(center, portrait_size * 0.47, -PI * 0.5, -PI * 0.5 + TAU, 40, Color(0.22, 0.30, 0.32, 0.85), 3.0, true)
	if _bond > 0.0:
		draw_arc(
			center, portrait_size * 0.47, -PI * 0.5, -PI * 0.5 + TAU * _bond, 40,
			Color(_secondary, 0.95), 3.0, true)

	var radius := portrait_size * 0.36 * breath
	# Nel HUD si deve riconoscere la stessa forma che cammina accanto a Eli.
	# Nel volto Beato si usa la variante generativa della STESSA specie: il tocco
	# cambia il sorriso, non sostituisce il compagno con una mascotte generica.
	if _pet_art != null:
		draw_circle(center + Vector2(0, radius * 0.12), radius * 1.10, Color(0.01, 0.035, 0.045, 0.28))
		draw_circle(center, radius + 2.5, Color(0.02, 0.07, 0.08, 0.94))
		_draw_pet_portrait(center, radius)
		_draw_flourish(center, radius)
	else:
		# Ombra, bordo e riflesso danno volume anche nei 76 px dell'HUD.
		draw_circle(center + Vector2(0, radius * 0.12), radius * 1.10, Color(0.01, 0.035, 0.045, 0.28))
		draw_circle(center, radius + 2.5, Color(0.02, 0.07, 0.08, 0.94))
		_draw_ears(center, radius)
		draw_circle(center, radius, _primary)
		draw_circle(center - Vector2(0, radius * 0.23), radius * 0.78, _primary.lightened(0.11))
		draw_circle(center + Vector2(0, radius * 0.31), radius * 0.43, Color(_secondary, 0.42))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-radius * 0.18, -radius * 0.82),
			center + Vector2(0, -radius * 1.06),
			center + Vector2(radius * 0.12, -radius * 0.80),
		]), _secondary)
		_draw_eyes(center, radius)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-radius * 0.075, radius * 0.16),
			center + Vector2(radius * 0.075, radius * 0.16),
			center + Vector2(0, radius * 0.24),
		]), Color(0.10, 0.14, 0.15))
		_draw_mouth(center, radius)
		_draw_flourish(center, radius)

	if _pet_name != "":
		var font := ThemeDB.fallback_font
		var size := 13 if portrait_size > SIZE else 11
		var width := font.get_string_size(_pet_name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(
			font, Vector2(center.x - width * 0.5, portrait_size + 12.0), _pet_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.85, 0.95, 0.96, 0.92))

func _draw_pet_portrait(center: Vector2, radius: float) -> void:
	var active_art := _reaction_art if _reaction_art != null else _pet_art
	if active_art == null:
		return
	var art_side := radius * 2.08
	var rotation := 0.0
	var scale_factor := 1.0
	var offset := Vector2.ZERO
	match _face:
		"curioso": rotation = 0.09
		"attento", "concentrato": scale_factor = 1.035
		"orgoglioso":
			rotation = -0.045
			scale_factor = 1.055
		"incoraggiante":
			rotation = 0.035
			offset.y = 1.5
		"impicciato": rotation = 0.065
		"offeso": rotation = -0.055
		"stupito":
			rotation = -0.035
			scale_factor = 1.055
			if not _reduced_motion:
				offset.y = -sin(_time * 4.2) * 1.4
		"coraggioso":
			rotation = -0.04
			scale_factor = 1.075
			offset.y = -1.2
		"sollevato":
			rotation = 0.045
			offset.y = 1.8
		"assonnato":
			rotation = 0.075
			scale_factor = 0.98
			offset.y = 2.8
		"festa":
			scale_factor = 1.06
			if not _reduced_motion:
				rotation = sin(_time * 8.0) * 0.06
		"beato":
			var affection := PetExpressionEngine.affection_style(_temperament, _pet_kind)
			match affection:
				"esuberante":
					scale_factor = 1.07
					if not _reduced_motion:
						rotation = sin(_time * 5.0) * 0.045
				"dolce":
					rotation = 0.035
					offset.y = 1.5
				"luminoso": scale_factor = 1.045
				"composto": rotation = -0.025
	draw_set_transform(center + offset, rotation, Vector2.ONE * scale_factor)
	var local_rect := Rect2(-Vector2.ONE * art_side * 0.5, Vector2.ONE * art_side)
	draw_texture_rect_region(
		active_art, local_rect, _portrait_source_rect(),
		Color.WHITE.lerp(_primary, 0.06))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _portrait_source_rect() -> Rect2:
	var values: Array = Array(PORTRAIT_CROPS.get(_pet_kind, [36.0, 18.0, 308.0, 308.0]))
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

## Le orecchie portano metà della leggibilità: su per curiosità, indietro per
## attenzione, una sola su per l'aria di chi ha combinato qualcosa.
func _draw_ears(center: Vector2, radius: float) -> void:
	var left_angle := -0.55
	var right_angle := 0.55
	match _face:
		"curioso":
			left_angle = -0.95
			right_angle = 0.25
		"attento":
			left_angle = -0.15
			right_angle = 0.15
		"offeso":
			left_angle = -0.20
			right_angle = 0.80
		"assonnato", "sollevato":
			left_angle = -0.25
			right_angle = 0.28
		"stupito", "coraggioso":
			left_angle = -0.90
			right_angle = 0.90
		"impicciato":
			left_angle = -0.30
			right_angle = 0.95
		"festa", "orgoglioso":
			left_angle = -0.80
			right_angle = 0.80
	for angle in [left_angle, right_angle]:
		var base := center + Vector2(sin(angle), -cos(angle)) * radius * 0.86
		var tip := center + Vector2(sin(angle), -cos(angle)) * radius * 1.42
		var side := Vector2(cos(angle), sin(angle)) * radius * 0.22
		draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), _primary.darkened(0.19))
		draw_colored_polygon(PackedVector2Array([
			base - side * 0.52, tip.lerp(base, 0.24), base + side * 0.52,
		]), Color(_secondary, 0.82))

func _draw_eyes(center: Vector2, radius: float) -> void:
	var offset := radius * 0.34
	var eye_y := center.y - radius * 0.16
	var ink := Color(0.04, 0.10, 0.12)
	for direction in [-1.0, 1.0]:
		var eye := Vector2(center.x + offset * direction, eye_y)
		match _face:
			"stupito":
				draw_circle(eye, radius * 0.225, Color(_secondary, 0.96))
				draw_circle(eye, radius * 0.135, ink)
				draw_circle(eye - Vector2(radius * 0.055, radius * 0.065), radius * 0.055, Color.WHITE)
			"coraggioso":
				draw_circle(eye, radius * 0.15, ink)
				draw_circle(eye - Vector2(radius * 0.05, radius * 0.05), radius * 0.045, Color.WHITE)
				draw_line(eye + Vector2(-radius * 0.17 * direction, -radius * 0.18), eye + Vector2(radius * 0.13 * direction, -radius * 0.10), ink, 2.4)
			"sollevato":
				draw_arc(eye + Vector2(0, 1.5), radius * 0.17, PI, TAU, 10, ink, 2.2, true)
			"assonnato":
				draw_line(eye - Vector2(radius * 0.15, 0), eye + Vector2(radius * 0.15, radius * 0.035), ink, 2.2)
			"beato":
				# Occhi chiusi felici: un arco verso l'alto.
				draw_arc(eye + Vector2(0, 1.5), radius * 0.17, PI, TAU, 10, ink, 2.4, true)
			"festa":
				draw_arc(eye + Vector2(0, 3.0), radius * 0.20, PI + 0.10, TAU - 0.10, 12, ink, 2.8, true)
			"concentrato":
				draw_circle(eye, radius * 0.115, ink)
				draw_line(eye + Vector2(-radius * 0.18 * direction, -radius * 0.19), eye + Vector2(radius * 0.12 * direction, -radius * 0.10), ink, 2.3)
			"offeso":
				# Occhi chiusi e girati: una linea inclinata.
				draw_line(eye - Vector2(radius * 0.15, radius * 0.04 * direction), eye + Vector2(radius * 0.15, radius * 0.04 * direction), ink, 2.5)
			"attento":
				draw_circle(eye, radius * 0.205, Color(_secondary, 0.92))
				draw_circle(eye, radius * 0.125, ink)
				draw_circle(eye - Vector2(radius * 0.04, radius * 0.05), radius * 0.045, Color.WHITE)
			"impicciato":
				# Pupille spostate di lato: lo sguardo in camera dopo la figuraccia.
				draw_circle(eye, radius * 0.17, ink)
				draw_circle(eye + Vector2(radius * 0.08, radius * 0.02), radius * 0.05, Color.WHITE)
			"curioso":
				draw_circle(eye, radius * 0.19, Color(_secondary, 0.95))
				draw_circle(eye + Vector2(radius * 0.045, -radius * 0.035), radius * 0.105, ink)
			"orgoglioso":
				draw_arc(eye + Vector2(0, radius * 0.02), radius * 0.16, PI, TAU, 10, ink, 2.3, true)
			"incoraggiante":
				draw_circle(eye, radius * 0.16, ink)
				draw_circle(eye - Vector2(radius * 0.06, radius * 0.06), radius * 0.055, Color.WHITE)
				draw_line(eye + Vector2(-radius * 0.15, -radius * 0.19), eye + Vector2(radius * 0.10, -radius * 0.15), ink, 1.8)
			_:
				draw_circle(eye, radius * 0.15, ink)
				draw_circle(eye - Vector2(radius * 0.05, radius * 0.05), radius * 0.05, Color(1, 1, 1, 0.9))

func _draw_mouth(center: Vector2, radius: float) -> void:
	var mouth := center + Vector2(0, radius * 0.38)
	var ink := Color(0.04, 0.10, 0.12)
	match _face:
		"stupito":
			draw_circle(mouth, radius * 0.105, ink)
			draw_circle(mouth - Vector2(radius * 0.03, radius * 0.035), radius * 0.025, Color.WHITE)
		"coraggioso":
			draw_arc(mouth - Vector2(0, radius * 0.06), radius * 0.17, 0.22, PI - 0.22, 12, ink, 2.7, true)
		"sollevato":
			draw_arc(mouth - Vector2(0, radius * 0.05), radius * 0.16, 0.20, PI - 0.20, 12, ink, 2.2, true)
		"assonnato":
			draw_circle(mouth + Vector2(radius * 0.05, 0), radius * 0.07, ink)
		"festa":
			draw_circle(mouth, radius * 0.19, ink)
			draw_arc(mouth + Vector2(0, radius * 0.08), radius * 0.10, PI, TAU, 8, Color("ff8fa3"), 3.0, true)
		"orgoglioso":
			draw_arc(mouth - Vector2(0, radius * 0.10), radius * 0.24, 0.12, PI - 0.12, 12, ink, 2.7, true)
			draw_line(mouth + Vector2(radius * 0.10, radius * 0.03), mouth + Vector2(radius * 0.23, -radius * 0.05), ink, 2.0)
		"incoraggiante":
			draw_arc(mouth - Vector2(0, radius * 0.07), radius * 0.18, 0.25, PI - 0.25, 12, ink, 2.5, true)
		"sereno":
			draw_arc(mouth - Vector2(0, radius * 0.06), radius * 0.15, 0.35, PI - 0.35, 10, ink, 2.0, true)
		"beato":
			draw_arc(mouth - Vector2(radius * 0.08, radius * 0.07), radius * 0.09, 0.15, PI - 0.10, 8, ink, 2.0, true)
			draw_arc(mouth + Vector2(radius * 0.08, -radius * 0.07), radius * 0.09, 0.10, PI - 0.15, 8, ink, 2.0, true)
		"concentrato", "attento":
			draw_line(mouth - Vector2(radius * 0.12, 0), mouth + Vector2(radius * 0.12, 0), ink, 2.2)
		"offeso":
			# Broncio: la curva al contrario, ed è l'unica volta. Dura tre secondi
			# e si scioglie da sola.
			draw_arc(mouth + Vector2(0, radius * 0.14), radius * 0.16, PI + 0.35, TAU - 0.35, 10, ink, 2.0, true)
		"impicciato":
			var points := PackedVector2Array()
			for i in range(7):
				var t := float(i) / 6.0
				points.append(mouth + Vector2(lerpf(-radius * 0.18, radius * 0.18, t), sin(t * TAU) * radius * 0.05))
			draw_polyline(points, ink, 2.0)
		"curioso":
			draw_circle(mouth, radius * 0.09, ink)
			draw_circle(mouth - Vector2(radius * 0.025, radius * 0.03), radius * 0.025, Color.WHITE)
		_:
			draw_arc(mouth, radius * 0.14, 0.35, PI - 0.35, 10, ink, 2.0, true)

## Piccoli segni non essenziali: aiutano ma nessuna espressione dipende da loro.
func _draw_flourish(center: Vector2, radius: float) -> void:
	match _face:
		"stupito":
			for index in 3:
				var angle := -2.6 + float(index) * 1.25
				var sparkle := center + Vector2.RIGHT.rotated(angle) * radius * 1.23
				var arm := 3.0 + float(index % 2)
				draw_line(sparkle - Vector2(arm, 0), sparkle + Vector2(arm, 0), Color("fff1a8", 0.94), 2.0, true)
				draw_line(sparkle - Vector2(0, arm), sparkle + Vector2(0, arm), Color("fff1a8", 0.94), 2.0, true)
		"coraggioso":
			draw_arc(center + Vector2(0, radius * 0.08), radius * 1.12, -2.85, -0.30, 20, Color("8ff6d2", 0.82), 2.6, true)
			for side in [-1.0, 1.0]:
				draw_line(center + Vector2(radius * 0.78 * side, radius * 0.68), center + Vector2(radius * 1.02 * side, radius * 0.46), Color("8ff6d2", 0.72), 2.0, true)
		"sollevato":
			for index in 3:
				var width := radius * (0.38 + float(index) * 0.18)
				draw_arc(center + Vector2(0, radius * 0.62), width, 0.12, PI - 0.12, 14, Color("b9e8ff", 0.62 - index * 0.12), 1.8, true)
		"assonnato":
			var drift := 0.0 if _reduced_motion else sin(_time * 1.7) * 2.0
			_draw_sleep_z(center + Vector2(radius * 0.82 + drift, -radius * 0.72), radius * 0.12, Color("b9e8ff", 0.82))
			_draw_sleep_z(center + Vector2(radius * 1.05 + drift, -radius * 1.02), radius * 0.09, Color("d8f3ff", 0.66))
		"festa":
			if _reduced_motion:
				draw_circle(center + Vector2(radius * 1.15, -radius * 0.95), 2.6, _secondary)
				draw_circle(center - Vector2(radius * 1.15, radius * 0.95), 2.6, _secondary)
				return
			for i in range(4):
				var angle := _time * 2.4 + TAU * float(i) / 4.0
				var p := center + Vector2(cos(angle), sin(angle)) * radius * (1.30 + _pulse * 0.12)
				draw_circle(p, 2.4, Color(_secondary, 0.92))
		"beato":
			var affection := PetExpressionEngine.affection_style(_temperament, _pet_kind)
			match affection:
				"esuberante":
					for i in 3:
						var angle := -2.65 + float(i) * 0.62
						if not _reduced_motion:
							angle += sin(_time * 3.2 + i) * 0.10
						_draw_heart(center + Vector2.RIGHT.rotated(angle) * radius * 1.25, radius * 0.13, Color("ff8fa3", 0.92))
				"dolce":
					for direction in [-1.0, 1.0]:
						draw_circle(center + Vector2(radius * 0.62 * direction, radius * 0.18), radius * 0.11, Color(1.0, 0.62, 0.62, 0.46))
					_draw_heart(center + Vector2(radius * 0.92, -radius * 0.88), radius * 0.12, Color("ffb5c2", 0.88))
				"luminoso":
					draw_arc(center, radius * 1.18, -2.75, -0.38, 20, Color("7ad7ff", 0.78), 2.2, true)
					for side in [-1.0, 1.0]:
						draw_circle(center + Vector2(radius * 0.88 * side, -radius * 0.72), 2.4, Color("d8f3ff"))
				_:
					draw_circle(center + Vector2(-radius * 0.66, radius * 0.16), radius * 0.09, Color(1.0, 0.62, 0.62, 0.38))
					draw_line(center + Vector2(radius * 0.86, -radius * 0.82), center + Vector2(radius * 1.10, -radius * 1.05), _secondary, 2.0, true)
		"attento":
			# Il Custode smette di illuminarsi: la luce si abbassa dove il
			# significato è svanito.
			draw_circle(center, radius * 1.05, Color(0.02, 0.05, 0.06, 0.28))
		"curioso":
			draw_arc(
				center + Vector2(radius * 0.95, -radius * 0.85), radius * 0.20,
				-0.4, 2.2, 10, Color(_secondary, 0.9), 2.0, true)
		"concentrato":
			for side in [-1.0, 1.0]:
				draw_line(center + Vector2(radius * 0.82 * side, -radius * 0.48), center + Vector2(radius * 1.08 * side, -radius * 0.48), Color("7ad7ff", 0.82), 2.0, true)
				draw_line(center + Vector2(radius * 1.08 * side, -radius * 0.48), center + Vector2(radius * 1.08 * side, -radius * 0.18), Color("7ad7ff", 0.82), 2.0, true)
		"orgoglioso":
			for i in 3:
				var x := (float(i) - 1.0) * radius * 0.28
				draw_line(center + Vector2(x, -radius * 1.02), center + Vector2(x * 1.15, -radius * 1.28), _secondary, 2.2, true)
		"incoraggiante":
			_draw_heart(center + Vector2(radius * 0.92, -radius * 0.78), radius * 0.11, Color("8ff6d2", 0.88))
			draw_arc(center + Vector2(0, radius * 0.12), radius * 1.10, 0.30, PI - 0.30, 18, Color("8ff6d2", 0.54), 2.0, true)
		"impicciato":
			var drop := center + Vector2(radius * 0.92, -radius * 0.72)
			draw_colored_polygon(PackedVector2Array([drop + Vector2(0, -5), drop + Vector2(-3.5, 2), drop + Vector2(0, 5), drop + Vector2(3.5, 2)]), Color("7ad7ff", 0.80))
		"offeso":
			draw_arc(center + Vector2(radius * 0.92, -radius * 0.74), radius * 0.18, PI, TAU, 10, Color(_secondary, 0.72), 1.8, true)

func _draw_heart(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, size),
		center + Vector2(-size, 0),
		center + Vector2(-size * 0.70, -size * 0.72),
		center,
		center + Vector2(size * 0.70, -size * 0.72),
		center + Vector2(size, 0),
	])
	draw_colored_polygon(points, color)

func _draw_sleep_z(center: Vector2, size: float, color: Color) -> void:
	draw_line(center + Vector2(-size, -size), center + Vector2(size, -size), color, 2.0, true)
	draw_line(center + Vector2(size, -size), center + Vector2(-size, size), color, 2.0, true)
	draw_line(center + Vector2(-size, size), center + Vector2(size, size), color, 2.0, true)
