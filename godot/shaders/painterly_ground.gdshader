shader_type canvas_item;

// Painterly terrain splat. Every lookup is based on absolute world position,
// so streamed chunks remain technical containers instead of visible tiles.
uniform sampler2D academy_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D wild_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D mineral_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D magic_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D identity_tex : repeat_enable, filter_linear_mipmap;

// Quattro campi di rumore precotti (R breakup, G clearing, B understory,
// A macro), generati da scripts/build-terrain-noise-texture.mjs. Sostituiscono
// quattro `fbm()` a 4 ottave, cioe' ~64 `hash21` per fragment. Filtro lineare
// senza mipmap: la texture e' a bassa frequenza rispetto allo schermo e viene
// sempre ingrandita, quindi le mip non servirebbero e ammorbidirebbero soltanto.
uniform sampler2D noise_fields_tex : repeat_disable, filter_linear;
uniform vec2 noise_world_origin = vec2(-4096.0);
uniform vec2 noise_world_size = vec2(8192.0);

uniform vec2 surface_world_origin = vec2(0.0);
uniform vec2 surface_world_size = vec2(932.0);
uniform vec4 weights_tl = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 weights_tr = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 weights_bl = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 weights_br = vec4(1.0, 0.0, 0.0, 0.0);
uniform float detail_strength = 1.0;
uniform float identity_strength = 0.0;
uniform vec4 identity_calm_palette : source_color = vec4(0.30, 0.34, 0.24, 1.0);
uniform bool identity_unique_map = false;
// Quando la tavola identitaria copre quasi tutto il colore finale, gli otto
// campionamenti dei bioma valgono pochi punti percentuali: il ramo li salta e
// usa la media per bioma, gia' calcolata senza toccare texture. Essendo una
// uniform, la condizione e' identica per ogni fragment della draw call, quindi
// il branch e' coerente e la GPU scarta del tutto il percorso non preso.
uniform bool identity_dominant = false;
uniform vec2 identity_world_origin = vec2(-2200.0, -2200.0);
uniform vec2 identity_world_size = vec2(4400.0, 4400.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 mirror_repeat(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 local_uv = fract(uv);
	vec2 flip = mod(cell, vec2(2.0));
	return mix(local_uv, vec2(1.0) - local_uv, flip);
}

// Campionamento specchiato con mip corretto.
//
// `mirror_repeat` contiene `floor`/`fract`, quindi la UV che ne esce e'
// DISCONTINUA sui bordi di ogni cella. Se si lascia scegliere il mip alla GPU
// (che lo deduce dalle derivate della UV passata a `texture()`), sulle cuciture
// la derivata schizza e viene scelto il livello piu' basso: cuciture sfocate
// visibili e, cosa piu' costosa su GPU mobile, un accesso alla texture cache
// completamente fuori pattern.
//
// La derivata corretta e' quella della UV CONTINUA, prima dello specchiamento:
// la si calcola una volta per scala e la si passa a `textureGrad`. Lo
// specchiamento inverte il segno del gradiente in celle alterne, ma il mip
// dipende dalla magnitudine, quindi il livello resta quello giusto.
vec3 sample_mirrored(sampler2D tex, vec2 continuous_uv, vec2 ddx, vec2 ddy) {
	return textureGrad(tex, mirror_repeat(continuous_uv), ddx, ddy).rgb;
}

// Resta analitico solo il micro-dettaglio: a scala 96 unita' mondo sarebbe
// sotto-campionato dalla texture di rumore, e costa una sola `value_noise`.
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 world = surface_world_origin + UV * surface_world_size;
	vec4 top_weights = mix(weights_tl, weights_tr, UV.x);
	vec4 bottom_weights = mix(weights_bl, weights_br, UV.x);
	vec4 biome_weights = max(mix(top_weights, bottom_weights, UV.y), vec4(0.0));
	biome_weights /= max(dot(biome_weights, vec4(1.0)), 0.0001);

	// Una sola lettura al posto dei quattro fbm.
	vec4 noise_fields = texture(noise_fields_tex,
		(world - noise_world_origin) / noise_world_size);

	vec2 uv_a = world / 1280.0;
	vec2 uv_b = mat2(vec2(0.8192, 0.5736), vec2(-0.5736, 0.8192)) * world / 810.0 + vec2(0.317, 0.691);
	float breakup = smoothstep(0.27, 0.73, noise_fields.r);
	float secondary_mix = (0.14 + breakup * 0.20) * detail_strength;

	// Derivate delle UV continue, calcolate una volta per scala e riusate da
	// tutti i campionamenti specchiati (vedi `sample_mirrored`).
	vec2 ddx_a = dFdx(uv_a);
	vec2 ddy_a = dFdy(uv_a);
	vec2 ddx_b = dFdx(uv_b);
	vec2 ddy_b = dFdy(uv_b);

	// Media cromatica per bioma: nessun campionamento, serve sia come sostituto
	// del mix dei bioma sia come base della palette "calma".
	vec3 biome_calm = vec3(0.43, 0.50, 0.22) * biome_weights.x
		+ vec3(0.16, 0.29, 0.18) * biome_weights.y
		+ vec3(0.31, 0.35, 0.20) * biome_weights.z
		+ vec3(0.14, 0.20, 0.30) * biome_weights.w;

	vec3 color;
	if (identity_dominant) {
		color = biome_calm;
	} else {
		vec3 academy = mix(sample_mirrored(academy_tex, uv_a, ddx_a, ddy_a), sample_mirrored(academy_tex, uv_b, ddx_b, ddy_b), secondary_mix);
		vec3 wild = mix(sample_mirrored(wild_tex, uv_a, ddx_a, ddy_a), sample_mirrored(wild_tex, uv_b, ddx_b, ddy_b), secondary_mix);
		vec3 mineral = mix(sample_mirrored(mineral_tex, uv_a, ddx_a, ddy_a), sample_mirrored(mineral_tex, uv_b, ddx_b, ddy_b), secondary_mix);
		vec3 magic = mix(sample_mirrored(magic_tex, uv_a, ddx_a, ddy_a), sample_mirrored(magic_tex, uv_b, ddx_b, ddy_b), secondary_mix);
		color = academy * biome_weights.x + wild * biome_weights.y
			+ mineral * biome_weights.z + magic * biome_weights.w;
	}

	vec2 identity_uv = clamp(
		(world - identity_world_origin) / max(identity_world_size, vec2(1.0)),
		vec2(0.0), vec2(1.0));
	// La mappa autorata (`identity_unique_map`) e' gia' in UV continue e
	// clampate: li' le derivate automatiche vanno bene.
	vec3 identity = identity_unique_map
		? texture(identity_tex, identity_uv).rgb
		: sample_mirrored(identity_tex, uv_a, ddx_a, ddy_a);
	if (!identity_unique_map) {
		identity = mix(identity, sample_mirrored(identity_tex, uv_b, ddx_b, ddy_b), secondary_mix * 0.72);
	}
	color = mix(color, identity, clamp(identity_strength, 0.0, 1.0));
	// Maschere macro in coordinate mondo: alternano prato calmo, sottobosco e
	// tappeto fiorito su centinaia di metri senza creare rettangoli per chunk.
	vec3 calm_palette = mix(biome_calm, identity_calm_palette.rgb, clamp(identity_strength, 0.0, 1.0));
	float clearing = smoothstep(0.51, 0.69, noise_fields.g);
	float understory = smoothstep(0.58, 0.77, noise_fields.b);
	color = mix(color, calm_palette, clearing * 0.24);
	color *= 1.0 - understory * 0.055;
	float macro = noise_fields.a - 0.5;
	float micro = value_noise(world / 96.0) - 0.5;
	color *= 1.0 + macro * 0.18 + micro * 0.035 * detail_strength;
	color = mix(color, color * color * (3.0 - 2.0 * color), 0.12);
	COLOR = vec4(color, 1.0);
}
