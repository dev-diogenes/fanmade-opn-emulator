class_name PentagonoAtributos
extends Control
## Os cinco atributos num pentágono (docs/23, C5), como na ficha de papel de OP: um círculo
## por atributo nos vértices, ligados por traços de tinta, com o valor grande no centro do
## círculo e a sigla embaixo. Atributo 0 fica tracejado (rola 2 d20 e fica com o pior).
##   var p := PentagonoAtributos.new(); p.agente = a

const ORDEM := ["agi", "int", "pre", "vig", "for"]   ## a partir do topo, em sentido horário
const SIGLAS := {"agi": "AGI", "for": "FOR", "int": "INT", "pre": "PRE", "vig": "VIG"}
const TAMANHO := Vector2(200, 210)

var agente: Agente:
	set(v):
		agente = v
		queue_redraw()


func _init() -> void:
	custom_minimum_size = TAMANHO
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = "Atributos: cada ponto é um d20 rolado nos testes (vale o maior)."


func vertices() -> Array[Vector2]:
	var c := Vector2(size.x / 2.0, size.y / 2.0 - 4)
	var r := minf(size.x, size.y) * 0.33
	var pts: Array[Vector2] = []
	for i in 5:
		pts.append(c + Vector2.UP.rotated(TAU * i / 5.0) * r)
	return pts


func _draw() -> void:
	if agente == null:
		return
	var pts := vertices()
	var tinta := Tema.TINTA
	for i in 5:
		draw_line(pts[i], pts[(i + 1) % 5], Color(tinta, 0.55), 2.0, true)
	var fonte: Font = Tema.fonte_titulo() if Tema.fonte_titulo() != null else get_theme_default_font()
	var maquina: Font = Tema.fonte_maquina() if Tema.fonte_maquina() != null else get_theme_default_font()
	for i in 5:
		var id: String = ORDEM[i]
		var valor := agente.atributo(id)
		var raio := 21.0
		draw_circle(pts[i], raio, Tema.PAPEL)
		if valor <= 0:
			for k in 12:   # círculo tracejado
				draw_arc(pts[i], raio, TAU * k / 12.0, TAU * (k + 0.5) / 12.0, 3, tinta, 2.0, true)
		else:
			draw_arc(pts[i], raio, 0, TAU, 24, tinta, 2.4, true)
		var texto := str(valor)
		var tam := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		draw_string(fonte, pts[i] + Vector2(-tam.x / 2.0, 9), texto, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, tinta)
		var sigla: String = SIGLAS[id]
		var ts := maquina.get_string_size(sigla, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(maquina, pts[i] + Vector2(-ts.x / 2.0, 38.0), sigla, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(tinta, 0.85))
