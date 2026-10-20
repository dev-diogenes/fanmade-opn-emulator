// Véu da Membrana (docs/08, R4): vinheta, granulação e dessaturação sobre a vista 3D.
// `intensidade` = (100 - Membrana) / 75. Com a Membrana cheia, só uma vinheta leve de maquete.
// `glitch` (docs/09, 5.3): pulso de VHS quando o paranormal se manifesta (pista, falha, ritual).
shader_type canvas_item;

uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_veu : source_color = vec4(0.32, 0.03, 0.10, 1.0);

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	// Faixas horizontais deslocadas (tracking de fita)
	float faixa = floor(uv.y * 24.0 + floor(TIME * 18.0));
	float desloca = (ruido(vec2(faixa, floor(TIME * 18.0))) - 0.5) * 0.06 * glitch;
	desloca *= step(0.6, ruido(vec2(faixa * 1.7, 3.0 + floor(TIME * 9.0))));
	uv.x += desloca;
	// Aberração cromática
	float ab = 0.006 * glitch;
	vec4 c = texture(TEXTURE, uv);
	c.r = texture(TEXTURE, uv + vec2(ab, 0.0)).r;
	c.b = texture(TEXTURE, uv - vec2(ab, 0.0)).b;
	float dist = length(UV - 0.5);
	float vinheta = smoothstep(0.38 - 0.12 * intensidade, 0.85, dist);
	c.rgb = mix(c.rgb, c.rgb * 0.2, vinheta * (0.45 + 0.4 * intensidade));
	c.rgb = mix(c.rgb, cor_veu.rgb, vinheta * intensidade * 0.5);
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(luma), intensidade * 0.35);
	// Linhas de varredura e grão
	c.rgb *= 1.0 - glitch * 0.25 * step(0.5, fract(FRAGCOORD.y * 0.5));
	float grao = ruido(floor(FRAGCOORD.xy) + fract(TIME * 7.0) * 113.0) - 0.5;
	c.rgb += grao * (0.025 + 0.08 * intensidade + 0.15 * glitch);
	COLOR = c;
}
