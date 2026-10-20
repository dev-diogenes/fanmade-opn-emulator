// Névoa do Outro Lado (docs/08, R5): cobre os hexes não revelados com uma bruma roxa
// que se move devagar. Usa a posição no mundo, então a névoa é contínua entre os tiles.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 cor : source_color = vec4(0.27, 0.15, 0.40, 1.0);
uniform vec4 cor_funda : source_color = vec4(0.05, 0.04, 0.08, 1.0);

varying vec3 pos_mundo;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * ruido(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = pos_mundo.xz * 0.45;
	float n = fbm(p + vec2(TIME * 0.04, TIME * 0.025));
	n = fbm(p * 1.6 + vec2(n * 2.0) - vec2(TIME * 0.03, 0.0));
	ALBEDO = mix(cor_funda.rgb, cor.rgb, smoothstep(0.35, 0.9, n));
	ALPHA = 0.85;
}
