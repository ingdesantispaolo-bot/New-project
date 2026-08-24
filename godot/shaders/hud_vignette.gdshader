shader_type canvas_item;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.55;
	float vignette = smoothstep(0.62, 1.28, d);
	COLOR = vec4(0.008, 0.02, 0.035, vignette * 0.42);
}
