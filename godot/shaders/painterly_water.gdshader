shader_type canvas_item;

uniform sampler2D water_tex : repeat_enable, filter_linear_mipmap;
uniform vec2 surface_world_origin = vec2(0.0);
uniform vec2 surface_world_size = vec2(400.0);
uniform float animation_speed = 1.0;
uniform float edge_glow_strength = 0.10;

vec2 mirror_repeat(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 local_uv = fract(uv);
	return mix(local_uv, vec2(1.0) - local_uv, mod(cell, vec2(2.0)));
}

void fragment() {
	vec2 world = surface_world_origin + UV * surface_world_size;
	vec2 drift_a = vec2(TIME * 0.0019, TIME * 0.0008) * animation_speed;
	vec2 drift_b = vec2(-TIME * 0.0011, TIME * 0.0015) * animation_speed;
	vec3 a = texture(water_tex, mirror_repeat(world / 760.0 + drift_a)).rgb;
	vec3 b = texture(water_tex, mirror_repeat(vec2(-world.y, world.x) / 1110.0 + drift_b)).rgb;
	vec3 color = mix(a, b, 0.24);
	float edge_light = smoothstep(0.78, 1.0, length(UV - vec2(0.5)) * 1.75);
	color = mix(color, vec3(0.46, 0.87, 0.74), edge_light * edge_glow_strength);
	COLOR = vec4(color * vec3(0.78, 0.92, 0.88), 0.94);
}
