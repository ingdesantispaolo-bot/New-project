shader_type canvas_item;
render_mode unshaded;

uniform float daylight = 0.75;
uniform float clock = 0.0;
uniform float motion_factor = 1.0;
uniform vec3 biome_tint = vec3(0.42, 0.90, 0.84);

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv - vec2(0.5);
	float edge = smoothstep(0.38, 0.92, length(centered * vec2(1.0, 0.82)));
	float night = 1.0 - daylight;
	float dawn = clamp(1.0 - abs(daylight - 0.5) * 2.4, 0.0, 1.0);
	float horizon = smoothstep(0.15, 0.9, uv.y) * (1.0 - smoothstep(0.72, 1.0, uv.y));
	float animated_wave = 0.5 + 0.5 * sin((uv.x * 9.0) + (clock * 6.283) + sin(uv.y * 5.0));
	float mist_wave = mix(0.5, animated_wave, motion_factor);
	float mist = horizon * mist_wave * (0.018 + dawn * 0.035);
	vec3 night_tint = vec3(0.08, 0.13, 0.28);
	vec3 dawn_tint = vec3(1.0, 0.58, 0.28);
	vec3 tint = mix(night_tint, dawn_tint, dawn * 0.72);
	tint = mix(tint, biome_tint, 0.16);
	float alpha = (night * 0.045) + (dawn * 0.028) + (edge * 0.050) + mist;
	COLOR = vec4(tint, clamp(alpha, 0.0, 0.16));
}
