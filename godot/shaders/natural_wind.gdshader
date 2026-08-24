shader_type canvas_item;
render_mode unshaded;

// Muove i vertici degli atlanti naturali senza nodi o `_process`.
uniform float wind_strength : hint_range(0.0, 1.0) = 1.0;
uniform float wind_phase = 0.0;

void vertex() {
	float top = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 1.25 + UV.x * 5.0 + wind_phase) * top * top * 3.0 * wind_strength;
}
