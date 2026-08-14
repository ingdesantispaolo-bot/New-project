shader_type canvas_item;

uniform sampler2D water_tex : repeat_enable, filter_linear_mipmap;
uniform vec2 surface_world_origin = vec2(0.0);
uniform vec2 surface_world_size = vec2(400.0);
uniform float animation_speed = 1.0;
uniform float edge_glow_strength = 0.10;
uniform float surface_alpha : hint_range(0.0, 1.0) = 0.78;

vec2 mirror_repeat(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 local_uv = fract(uv);
	return mix(local_uv, vec2(1.0) - local_uv, mod(cell, vec2(2.0)));
}

// Stesso motivo del terreno: `mirror_repeat` spezza la continuita' della UV, e
// con le mipmap attive la GPU sceglierebbe il mip sbagliato sulle cuciture.
// Le derivate vanno prese sulla UV continua e passate a `textureGrad`.
vec3 sample_mirrored(sampler2D tex, vec2 continuous_uv, vec2 ddx, vec2 ddy) {
	return textureGrad(tex, mirror_repeat(continuous_uv), ddx, ddy).rgb;
}

void fragment() {
	vec2 world = surface_world_origin + UV * surface_world_size;
	vec2 drift_a = vec2(TIME * 0.0019, TIME * 0.0008) * animation_speed;
	vec2 drift_b = vec2(-TIME * 0.0011, TIME * 0.0015) * animation_speed;
	vec2 uv_a = world / 760.0 + drift_a;
	vec2 uv_b = vec2(-world.y, world.x) / 1110.0 + drift_b;
	vec3 a = sample_mirrored(water_tex, uv_a, dFdx(uv_a), dFdy(uv_a));
	vec3 b = sample_mirrored(water_tex, uv_b, dFdx(uv_b), dFdy(uv_b));
	vec3 color = mix(a, b, 0.24);
	float edge_light = smoothstep(0.78, 1.0, length(UV - vec2(0.5)) * 1.75);
	color = mix(color, vec3(0.46, 0.87, 0.74), edge_light * edge_glow_strength);
	COLOR = vec4(color * vec3(0.78, 0.92, 0.88), surface_alpha);
}
