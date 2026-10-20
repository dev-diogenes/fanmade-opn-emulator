// Estática de TV entre as telas (docs/10): ruído, faixas e um brilho que some com `forca`.
shader_type canvas_item;

uniform float forca : hint_range(0.0, 1.0) = 1.0;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 celula = floor(FRAGCOORD.xy / 2.0);
	float n = ruido(celula + fract(TIME * 13.0) * 271.0);
	float faixa = smoothstep(0.0, 0.02, abs(fract(UV.y * 3.0 - TIME * 1.7) - 0.5)) * 0.25 + 0.75;
	vec3 cor = vec3(n * faixa) * vec3(0.85, 0.82, 0.9);
	float vinheta = smoothstep(0.9, 0.3, length(UV - 0.5));
	COLOR = vec4(mix(vec3(0.02, 0.01, 0.03), cor * 0.55, vinheta), forca);
}
