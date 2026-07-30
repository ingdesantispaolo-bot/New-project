class_name FinalConvergenceDisplay
extends Control

## Visuale compatto e non interattivo dell'esame trasversale. I dodici nodi
## esterni rappresentano i sistemi/materie; i cinque anelli interni sono le fasi
## del Cuore. Vive dentro ExercisePlayer, quindi resta leggibile anche su tablet.

const PALETTE := [
	Color("f5c85b"), Color("ed8878"), Color("55a8ef"), Color("63d9e6"),
	Color("777fe8"), Color("bc72e8"), Color("c7a06b"), Color("f09a44"),
	Color("70b6d2"), Color("69c59a"), Color("ebe3c5"), Color("9c82f0"),
]

var systems: Array = []
var resolved: Dictionary = {}
var synthesis_resolved := false
var synthesis_correct := false
var reduced_motion := false
var _last_resolved_system := ""
var _resolve_started_msec := 0

func setup(system_names: Array, use_reduced_motion: bool = false) -> void:
	systems = system_names.duplicate()
	resolved.clear()
	synthesis_resolved = false
	synthesis_correct = false
	reduced_motion = use_reduced_motion
	_last_resolved_system = ""
	_resolve_started_msec = 0
	custom_minimum_size = Vector2(0, 124)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(not reduced_motion)
	queue_redraw()

func resolve_system(system: String, correct: bool) -> void:
	if system == "sintesi":
		synthesis_resolved = true
		synthesis_correct = correct
	elif systems.has(system):
		resolved[system] = correct
	_last_resolved_system = system
	_resolve_started_msec = Time.get_ticks_msec()
	set_process(not reduced_motion)
	queue_redraw()

func _process(_delta: float) -> void:
	if _last_resolved_system == "":
		return
	if Time.get_ticks_msec() - _resolve_started_msec > 760:
		_last_resolved_system = ""
		set_process(false)
	queue_redraw()

func resolved_system_count() -> int:
	return resolved.size()

func heart_stage() -> int:
	if systems.is_empty():
		return 0
	return clampi(ceili(float(resolved.size()) / float(systems.size()) * 5.0), 0, 5)

func _draw() -> void:
	var center := Vector2(minf(size.x * 0.22, 128.0), 61.0)
	var radius := 48.0
	draw_circle(center, 28.0, Color("101523", 0.94))
	for phase in 5:
		var phase_color := Color("fff0ae", 0.80 if phase < heart_stage() else 0.11)
		draw_arc(center, 8.0 + float(phase) * 4.2, 0.0, TAU, 48, phase_color, 2.3, true)
	for index in systems.size():
		var angle := -PI * 0.5 + TAU * float(index) / float(maxi(1, systems.size()))
		var position := center + Vector2(cos(angle), sin(angle)) * radius
		var subject := str(systems[index])
		var is_resolved := resolved.has(subject)
		var color: Color = PALETTE[index % PALETTE.size()]
		var fill := Color(color, 0.96 if is_resolved else 0.16)
		if is_resolved and not bool(resolved[subject]):
			fill = Color(color.lerp(Color("ff9a72"), 0.38), 0.82)
		if is_resolved:
			draw_line(position, center, Color(color, 0.34), 1.7, true)
		draw_circle(position, 6.5 if is_resolved else 5.2, fill)
		draw_arc(position, 8.5, 0.0, TAU, 22, Color(color, 0.78 if is_resolved else 0.24), 1.6, true)
		if subject == _last_resolved_system and not reduced_motion:
			var elapsed := clampf(float(Time.get_ticks_msec() - _resolve_started_msec) / 760.0, 0.0, 1.0)
			var traveling := position.lerp(center, ease(elapsed, 0.65))
			draw_line(position, traveling, Color(color, 0.88 * (1.0 - elapsed)), 3.2, true)
			draw_circle(traveling, 4.8 + sin(elapsed * PI) * 2.6, Color(color, 0.92 * (1.0 - elapsed)))
			draw_arc(position, 10.0 + elapsed * 12.0, 0.0, TAU, 28, Color(color, 0.72 * (1.0 - elapsed)), 2.0, true)
	if synthesis_resolved:
		draw_circle(center, 5.0, Color("fff2bd") if synthesis_correct else Color("ffad83"))
	var text_x := maxf(205.0, size.x * 0.39)
	var title := "CONVERGENZA · %d/12 SISTEMI" % resolved.size()
	draw_string(ThemeDB.fallback_font, Vector2(text_x, 39), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f6d77d"))
	var phase_names := ["IN ATTESA", "AGGANCIO", "SINCRONIA", "MEMORIA", "COSCIENZA", "ROTTA"]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(text_x, 66),
		"CUORE · FASE %d/5 · %s" % [heart_stage(), phase_names[heart_stage()]],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color("a7e9e5"))
	var synthesis_text := "Sintesi finale pronta" if resolved.size() >= 12 and not synthesis_resolved else "Sintesi completata" if synthesis_resolved else "Completa i dodici sistemi"
	draw_string(ThemeDB.fallback_font, Vector2(text_x, 91), synthesis_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c9d4df"))
