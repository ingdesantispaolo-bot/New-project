class_name OutdoorAtmosphere
extends Node2D

## Atmosfera render-only: giorno/notte, foschia e particelle leggere.
## Non legge né modifica stato di gioco; il chiamante fornisce solo fase/bioma.

@export var biome := "academy"
@export_range(0.0, 1.0, 0.05) var intensity := 0.55
@export var reduced_motion := false

var _phase := "giorno"
var _mist: CPUParticles2D
var _fireflies: CPUParticles2D
var _wash: ColorRect

const BIOME_TINT := {
	"academy": Color("6be7d6"),
	"wild": Color("8fe0a4"),
	"geo": Color("80c7ff"),
	"logic": Color("b9a2ff"),
	"ruins": Color("e0a37a"),
	"crystal": Color("9be7ff"),
}

func _ready() -> void:
	_build()
	apply_phase(_phase)

func configure(new_biome: String, new_intensity: float = 0.55, motion_reduced: bool = false) -> void:
	biome = new_biome.to_lower()
	intensity = clampf(new_intensity, 0.0, 1.0)
	reduced_motion = motion_reduced
	_build()
	apply_phase(_phase)

func apply_phase(phase: String) -> void:
	_phase = phase
	var night := phase == "notte"
	var dusk := phase == "alba"
	if is_instance_valid(_mist):
		_mist.emitting = not reduced_motion and intensity > 0.05
		_mist.amount = 8 if reduced_motion else int(18.0 + intensity * 22.0)
	if is_instance_valid(_fireflies):
		_fireflies.emitting = not reduced_motion and night and intensity > 0.15
	if is_instance_valid(_wash):
		var tint: Color = BIOME_TINT.get(biome, Color("6be7d6"))
		_wash.color = Color(tint, (0.035 if not night else 0.07 if not dusk else 0.05) * intensity)

func _build() -> void:
	for child in get_children():
		child.queue_free()
	_wash = ColorRect.new()
	_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wash)
	_mist = _particles(Color("d4fff0"), 28, 5.0, 10.0)
	_mist.position = Vector2(0, 0)
	add_child(_mist)
	_fireflies = _particles(BIOME_TINT.get(biome, Color("6be7d6")), 18, 2.0, 7.0)
	_fireflies.position = Vector2(0, -20)
	add_child(_fireflies)

func _particles(color: Color, amount: int, speed_min: float, speed_max: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = 3.8
	particles.preprocess = 2.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(520, 260)
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, -2)
	particles.initial_velocity_min = speed_min
	particles.initial_velocity_max = speed_max
	particles.scale_amount_min = 0.06
	particles.scale_amount_max = 0.14
	particles.color = Color(color, 0.42)
	particles.texture = OutdoorVisualFactory.glow_texture()
	particles.material = OutdoorVisualFactory.add_material()
	return particles
