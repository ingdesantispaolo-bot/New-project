class_name NoraPortrait
extends Control

## Ritratto vettoriale leggero della compagna NORA. Non possiede logica
## narrativa: visualizza soltanto le battute emesse da OutdoorGameplay.

var _time := 0.0
var _speech := 0.0
var _accent := Color("6be7d6")
var _integrity := 0.0
var _trust := 0.5
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(82, 82)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func speak(message: String) -> void:
	_speech = 1.0
	var lowered := message.to_lower()
	if "non " in lowered or "insufficiente" in lowered or "riprova" in lowered:
		_accent = Color("ff8fa0")
	elif "+" in message or "vittoria" in lowered or "ottimo" in lowered:
		_accent = Color("f6c85f")
	else:
		_accent = Color("6be7d6")
	if not _reduced_motion:
		scale = Vector2(0.88, 0.88)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	queue_redraw()

func set_livery(color: Color) -> void:
	_accent = color
	queue_redraw()

## Integrità puramente presentazionale derivata dalla riattivazione didattica
## della nave (0 frammentata → 1 pienamente ricostruita). Non decide storia,
## fiducia o progresso: rende visibile lo stato già calcolato altrove.
func set_integrity(ratio: float, use_reduced_motion: bool = false, trust: float = 0.5) -> void:
	_integrity = clampf(ratio, 0.0, 1.0)
	_trust = clampf(trust, 0.0, 1.0)
	_reduced_motion = use_reduced_motion
	set_meta("integrity", _integrity)
	set_meta("trust", _trust)
	queue_redraw()

func _process(delta: float) -> void:
	if not _reduced_motion:
		_time += delta * lerpf(0.42, 1.0, _integrity)
	_speech = maxf(0.0, _speech - delta * 0.72)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(41, 42)
	var breath := 1.0 + sin(_time * 2.4) * 0.025 * lerpf(0.2, 1.0, _integrity)
	var talk := sin(_time * 12.0) * _speech
	var trusted_accent := _accent.lerp(Color("f6c85f"), clampf((_trust - 0.5) * 0.32, 0.0, 0.16))
	var live_accent := Color("75888c").lerp(trusted_accent, 0.28 + _integrity * 0.72)
	# Aura e orbite concentriche: silhouette leggibile anche a scala Web ridotta.
	draw_circle(center, 32.0 * breath, Color(live_accent, 0.035 + _integrity * 0.07 + _speech * 0.06))
	# Gli archi si ricompongono in quattro settori al crescere dell'integrità.
	var active_sectors := clampi(1 + int(floor(_integrity * 4.0)), 1, 5)
	for sector in range(5):
		var alpha := 0.56 if sector < active_sectors else 0.09
		var start := -1.45 + TAU * float(sector) / 5.0 + _time * 0.12
		draw_arc(center, 28.0 * breath, start, start + 0.76, 12, Color(live_accent, alpha), 2.2, true)
	draw_arc(center, 23.0, 0.35 - _time * 0.24, 1.25 + TAU * _integrity - _time * 0.24, 36, Color(live_accent.lightened(0.24), 0.72), 1.5, true)
	draw_circle(center, 18.0 + talk * 0.6, Color("102e36"))
	draw_circle(center, 15.0, Color(live_accent.darkened(0.46), 0.96))
	var diamond := PackedVector2Array([
		center + Vector2(0, -13), center + Vector2(14, 0),
		center + Vector2(0, 13), center + Vector2(-14, 0),
	])
	draw_colored_polygon(diamond, Color(live_accent, 0.88))
	var lens_width := 6.0 + absf(talk) * 2.0
	draw_circle(center, lens_width, Color("07131c"))
	draw_circle(center + Vector2(-1.8, -2.0), 1.8, Color(1, 1, 1, 0.9))
	if _integrity < 0.35:
		var fracture_alpha := 0.78 * (1.0 - _integrity / 0.35)
		draw_line(center + Vector2(-11, -7), center + Vector2(-2, 0), Color("b8c9cc", fracture_alpha), 1.2)
		draw_line(center + Vector2(-2, 0), center + Vector2(4, 10), Color("b8c9cc", fracture_alpha), 1.2)
	# Satelliti che accelerano mentre NORA parla.
	var satellites := 1 + int(round(_integrity * 2.0))
	for i in range(satellites):
		var angle := _time * (0.55 + _speech * 1.4) + TAU * float(i) / 3.0
		var p := center + Vector2(cos(angle), sin(angle)) * 34.0
		draw_circle(p, 2.1 + _speech, Color(live_accent.lightened(0.25), 0.82))

