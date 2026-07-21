class_name NoraPortrait
extends Control

## Ritratto vettoriale leggero della compagna NORA. Non possiede logica
## narrativa: visualizza soltanto le battute emesse da OutdoorGameplay.

var _time := 0.0
var _speech := 0.0
var _accent := Color("6be7d6")

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
	scale = Vector2(0.88, 0.88)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	queue_redraw()

func set_livery(color: Color) -> void:
	_accent = color
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_speech = maxf(0.0, _speech - delta * 0.72)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(41, 42)
	var breath := 1.0 + sin(_time * 2.4) * 0.025
	var talk := sin(_time * 12.0) * _speech
	# Aura e orbite concentriche: silhouette leggibile anche a scala Web ridotta.
	draw_circle(center, 32.0 * breath, Color(_accent, 0.08 + _speech * 0.06))
	draw_arc(center, 28.0 * breath, -1.15 + _time * 0.18, 3.9 + _time * 0.18, 40, Color(_accent, 0.42), 2.0, true)
	draw_arc(center, 23.0, 0.35 - _time * 0.24, 5.25 - _time * 0.24, 36, Color(_accent.lightened(0.24), 0.72), 1.5, true)
	draw_circle(center, 18.0 + talk * 0.6, Color("102e36"))
	draw_circle(center, 15.0, Color(_accent.darkened(0.46), 0.96))
	var diamond := PackedVector2Array([
		center + Vector2(0, -13), center + Vector2(14, 0),
		center + Vector2(0, 13), center + Vector2(-14, 0),
	])
	draw_colored_polygon(diamond, Color(_accent, 0.88))
	var lens_width := 6.0 + absf(talk) * 2.0
	draw_circle(center, lens_width, Color("07131c"))
	draw_circle(center + Vector2(-1.8, -2.0), 1.8, Color(1, 1, 1, 0.9))
	# Satelliti che accelerano mentre NORA parla.
	for i in range(3):
		var angle := _time * (0.55 + _speech * 1.4) + TAU * float(i) / 3.0
		var p := center + Vector2(cos(angle), sin(angle)) * 34.0
		draw_circle(p, 2.1 + _speech, Color(_accent.lightened(0.25), 0.82))

