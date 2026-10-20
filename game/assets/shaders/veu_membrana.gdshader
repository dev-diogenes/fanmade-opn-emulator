// Véu da Membrana (docs/08, R4): vinheta, granulação e dessaturação sobre a vista 3D.
// `intensidade` = (100 - Membrana) / 100. Com a Membrana cheia, só uma vinheta leve de maquete.
shader_type canvas_item;

uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_veu : source_color = vec4(0.32, 0.03, 0.10, 1.0);

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float dist = length(UV - 0.5);
	float vinheta = smoothstep(0.38 - 0.12 * intensidade, 0.85, dist);
	c.rgb = mix(c.rgb, c.rgb * 0.2, vinheta * (0.45 + 0.4 * intensidade));
	c.rgb = mix(c.rgb, cor_veu.rgb, vinheta * intensidade * 0.5);
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(luma), intensidade * 0.35);
	float grao = ruido(floor(FRAGCOORD.xy) + fract(TIME * 7.0) * 113.0) - 0.5;
	c.rgb += grao * (0.025 + 0.08 * intensidade);
	COLOR = c;
}
