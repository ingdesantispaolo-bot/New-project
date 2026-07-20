class_name OutdoorAmbientAnim
extends Node

## Micro-animazioni ambientali senza Tween: si attacca come figlio di un Node2D
## e anima il padre. Modalità:
## - "bob": oscillazione verticale (tesori, oggetti fluttuanti)
## - "pulse": pulsazione di scala (anelli incontro, fari)
## - "sway": ondeggiamento di rotazione (chiome degli alberi)
## - "spin": rotazione continua (anelli orbitali)
## - "shimmer": scintillio di alpha (cascate, superfici d'acqua)
## - "ping": espansione + dissolvenza una tantum, poi libera il padre (tocco)
##
## Solo estetica: la fase casuale usa randf() e non tocca l'RNG di generazione.

@export var mode := "bob"
@export var speed := 1.0
@export var strength := 1.0

var _time := 0.0
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE
var _target: Node2D

func _ready() -> void:
	_target = get_parent() as Node2D
	if _target == null:
		set_process(false)
		return
	if mode != "ping":
		_time = randf() * TAU
	_base_position = _target.position
	_base_scale = _target.scale

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		set_process(false)
		return
	_time += delta * speed
	match mode:
		"bob":
			_target.position.y = _base_position.y - absf(sin(_time * 2.4)) * 4.0 * strength
		"pulse":
			var s := 1.0 + sin(_time * 3.0) * 0.08 * strength
			_target.scale = _base_scale * s
		"sway":
			_target.rotation = sin(_time * 1.6) * 0.05 * strength
		"spin":
			_target.rotation += delta * speed * 0.8
		"shimmer":
			_target.modulate.a = clampf(0.62 + sin(_time * 4.2) * 0.38 * strength, 0.0, 1.0)
		"ping":
			var progress := _time / 0.6
			if progress >= 1.0:
				_target.queue_free()
				return
			_target.scale = _base_scale * (0.4 + progress * 1.3)
			_target.modulate.a = 0.9 * (1.0 - progress)
