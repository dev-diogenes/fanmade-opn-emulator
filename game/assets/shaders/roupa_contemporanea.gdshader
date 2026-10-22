shader_type spatial;
// Roupa contemporânea (docs/55): os modelos da KayKit são de fantasia, mas a textura deles é uma
// paleta de gradientes. Este shader troca as cores pelo papel de cada uma, mantendo o gradiente:
// pele vira o tom de pele do agente; cinzas claros (a armadura, a túnica) viram a roupa de cima;
// cinzas escuros, a de baixo; o resto (cabelo, couro, botões) fica, um pouco dessaturado.
// A classificação é feita em sRGB (a textura e as cores chegam cruas) e o resultado vai para o
// espaço linear no fim.

uniform sampler2D textura : filter_nearest;
uniform vec3 pele = vec3(0.85, 0.62, 0.48);
uniform vec3 roupa = vec3(0.16, 0.18, 0.2);
uniform vec3 escuro = vec3(0.12, 0.14, 0.2);
uniform vec3 tinta = vec3(1.0);
uniform float dessatura = 0.35;
uniform float cor_vira_roupa = 0.0;   // 1: as cores fortes da túnica também viram roupa
uniform float brilho = 0.32;          // luz própria leve: a miniatura não some na noite do mapa

void fragment() {
	vec3 c = texture(textura, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = mx - mn;
	vec3 o = c;
	bool e_pele = c.r > c.g && c.g > c.b && (c.r - c.b) > 0.12 && (c.r - c.b) < 0.42 && l > 0.6;
	if (l < 0.12) {
		o = c;   // olhos e contornos
	} else if (e_pele) {
		o = pele * (0.85 + 0.7 * (l - 0.78));
	} else if (sat < 0.12) {
		o = l > 0.34 ? roupa * (0.85 + (l - 0.6) * 0.9) : escuro * (0.9 + (l - 0.22) * 1.2);
	} else if (cor_vira_roupa > 0.5 && !(c.r > c.g && c.g > c.b)) {
		o = roupa * (0.85 + (l - 0.5) * 0.9);   // verde, azul, roxo da túnica
	} else {
		o = mix(c, vec3(l), dessatura);
	}
	vec3 linear = pow(clamp(o * tinta, 0.0, 1.0), vec3(2.2));
	ALBEDO = linear;
	EMISSION = linear * brilho;
	// Contorno de luz (rim) como numa miniatura pintada: as bordas acendem um pouco
	RIM = 0.35;
	RIM_TINT = 0.3;
	ROUGHNESS = 0.85;
}
