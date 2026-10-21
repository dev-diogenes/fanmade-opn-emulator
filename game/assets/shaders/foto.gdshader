// Foto 3x4 do arquivo da Ordem (docs/19): preto e branco amarelado, contraste de revelação,
// vinheta e grão parado (é uma foto, não um vídeo: nada se mexe nem pisca).
shader_type canvas_item;

uniform float sepia : hint_range(0.0, 1.0) = 0.6;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	l = clamp((l - 0.5) * 1.3 + 0.53, 0.0, 1.0);
	vec3 s = mix(vec3(l), vec3(l * 1.08, l * 0.96, l * 0.78), sepia);
	float v = smoothstep(0.9, 0.32, length(UV - 0.5));
	s *= mix(0.5, 1.0, v);
	s += (ruido(floor(FRAGCOORD.xy)) - 0.5) * 0.07;
	COLOR = vec4(s, 1.0);
}
