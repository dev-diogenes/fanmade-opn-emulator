// Véu da Membrana (docs/08, R4): vinheta, granulação e dessaturação sobre a vista 3D.
// `intensidade` = (100 - Membrana) / 75. Com a Membrana cheia, só uma vinheta leve de maquete.
// `glitch` (docs/09, 5.3): pulso de VHS quando o paranormal se manifesta (pista, falha, ritual).
shader_type canvas_item;

uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float grao : hint_range(0.0, 1.0) = 1.0;   // 0 = sem granulação nem vinheta (acessibilidade)
// Fotossensibilidade (docs/18, A5): velocidade das trocas de faixa e do grão do glitch.
// 1 = 18 trocas/s; 0,15 = ~2,7/s, abaixo do limite de 3 flashes por segundo.
uniform float ritmo : hint_range(0.05, 1.0) = 1.0;
// Loucura (docs/17, E6): sanidade baixa do agente da vez. A imagem respira, ondula,
// fica com um "fantasma" deslocado e pulsa em vermelho.
uniform float loucura : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_veu : source_color = vec4(0.32, 0.03, 0.10, 1.0);

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	// Faixas horizontais deslocadas (tracking de fita)
	float quadro = floor(TIME * 18.0 * ritmo);
	float faixa = floor(uv.y * 24.0 + quadro);
	float desloca = (ruido(vec2(faixa, quadro)) - 0.5) * 0.06 * glitch;
	desloca *= step(0.6, ruido(vec2(faixa * 1.7, 3.0 + floor(quadro * 0.5))));
	uv.x += desloca;
	// Ondulação e respiração da loucura
	uv += vec2(sin(uv.y * 11.0 + TIME * 1.3), cos(uv.x * 9.0 + TIME * 1.1)) * 0.0045 * loucura;
	uv = (uv - 0.5) * (1.0 - 0.012 * loucura * (0.5 + 0.5 * sin(TIME * 0.9))) + 0.5;
	// Aberração cromática
	float ab = 0.006 * glitch;
	vec4 c = texture(TEXTURE, uv);
	c.r = texture(TEXTURE, uv + vec2(ab, 0.0)).r;
	c.b = texture(TEXTURE, uv - vec2(ab, 0.0)).b;
	// Fantasma: uma segunda imagem, levemente deslocada
	vec4 fantasma = texture(TEXTURE, uv + vec2(0.012 * sin(TIME * 0.7), 0.006 * cos(TIME * 0.5)) * loucura);
	c.rgb = mix(c.rgb, fantasma.rgb, 0.28 * loucura);
	float dist = length(UV - 0.5);
	float vinheta = smoothstep(0.38 - 0.12 * intensidade, 0.85, dist);
	c.rgb = mix(c.rgb, c.rgb * 0.2, vinheta * (0.45 + 0.4 * intensidade) * grao);
	c.rgb = mix(c.rgb, cor_veu.rgb, vinheta * intensidade * 0.5);
	c.rgb = mix(c.rgb, c.rgb * vec3(1.12, 0.72, 0.8), 0.4 * loucura * (0.5 + 0.5 * sin(TIME * 1.6)));
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(luma), intensidade * 0.35);
	// Linhas de varredura e grão
	c.rgb *= 1.0 - glitch * 0.25 * step(0.5, fract(FRAGCOORD.y * 0.5));
	float ruido_grao = ruido(floor(FRAGCOORD.xy) + fract(TIME * 7.0) * 113.0) - 0.5;
	c.rgb += ruido_grao * (0.025 * grao + 0.08 * intensidade + 0.15 * glitch);
	COLOR = c;
}
