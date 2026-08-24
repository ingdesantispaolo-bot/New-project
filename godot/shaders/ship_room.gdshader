shader_type canvas_item;

uniform vec4 accent : source_color = vec4(0.42, 0.91, 0.84, 1.0);
uniform float restored : hint_range(0.0, 1.0) = 0.0;
uniform float activation : hint_range(0.0, 1.0) = 0.0;
uniform float transition_burst : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float edge = smoothstep(0.30, 0.78, distance(UV, vec2(0.5)));
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float powered = smoothstep(0.0, 0.82, activation);
	float pulse = sin(TIME * (0.72 + activation * 1.4)) * 0.5 + 0.5;
	float unstable = (1.0 - smoothstep(0.05, 0.28, activation)) * activation;
	float flicker = 1.0 - unstable * (sin(TIME * 17.0) * 0.035 + 0.035);
	float base_light = mix(0.42, 0.96, powered) + restored * 0.20;
	vec3 dormant = mix(vec3(luma), tex.rgb, 0.38 + restored * 0.30);
	vec3 color = mix(dormant, tex.rgb, max(powered, restored * 0.55)) * base_light * flicker;
	float highlight = smoothstep(0.34, 0.82, luma);
	color += accent.rgb * highlight * (0.025 + powered * 0.15);
	float scan = 1.0 - smoothstep(0.0, 0.018, abs(fract(UV.y - TIME * (0.035 + activation * 0.05)) - 0.5));
	color += accent.rgb * scan * activation * 0.055;
	color += accent.rgb * pulse * (activation * 0.018 + restored * 0.055);
	float ignition = transition_burst * (1.0 - smoothstep(0.0, 0.72, distance(UV, vec2(0.5))));
	color += accent.rgb * ignition * 0.85;
	color *= 1.0 - edge * mix(0.58, 0.32, powered) * (1.0 - restored * 0.45);
	COLOR = vec4(color, tex.a);
}
