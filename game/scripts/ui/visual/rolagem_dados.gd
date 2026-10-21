class_name RolagemDados
extends CanvasLayer
## Rolagem no centro da tela, como no FTK2 (docs/13): o símbolo do atributo no alto, os d20
## girando e caindo um a um (✓ ou ✗), e o resultado embaixo. Some sozinha; um clique fecha.
##   RolagemDados.mostrar(self, "Movimento", "agi", [15, 3, 11], 11, "4 de movimento")

const NOMES := {"agi": "AGILIDADE", "for": "FORÇA", "int": "INTELECTO", "pre": "PRESENÇA", "vig": "VIGOR"}
const CORES := {"agi": Color("7fd3c7"), "for": Color("e0574a"), "int": Color("e3c27a"), "pre": Color("b98ae6"), "vig": Color("6fcf8e")}
const GIRO := 0.42        ## segundos girando antes do primeiro dado cair
const ENTRE := 0.16       ## intervalo entre um dado e o próximo
const FICA := 1.5         ## quanto tempo o resultado fica na tela

var _raiz: Control
var _caixas: Array = []   ## [Label] de cada dado
var _tw: Tween


## `estados`: "sucesso" | "falha" | "neutro" por dado. Vazio = cada dado contra a DT.
static func mostrar(pai: Node, titulo: String, atributo: String, slots: Array, dt: int, resultado: String,
		estados: Array = [], sucesso_geral: Variant = null) -> RolagemDados:
	for antigo in pai.find_children("*", "RolagemDados", false, false):
		antigo.queue_free()
	var r := RolagemDados.new()
	r.name = "RolagemDados"
	pai.add_child(r)
	r._montar(titulo, atributo, slots, dt, resultado, estados, sucesso_geral)
	return r


func _montar(titulo: String, atributo: String, slots: Array, dt: int, resultado: String, estados: Array, sucesso_geral) -> void:
	layer = 70
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	var faixa := ColorRect.new()   # faixa escura atrás, de lado a lado (como no FTK2)
	faixa.color = Color(0, 0, 0, 0.55)
	faixa.anchor_right = 1.0
	faixa.anchor_top = 0.5
	faixa.anchor_bottom = 0.5
	faixa.offset_top = -120
	faixa.offset_bottom = 110
	faixa.mouse_filter = Control.MOUSE_FILTER_STOP
	faixa.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: queue_free())
	_raiz.add_child(faixa)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(v)
	var cab := HBoxContainer.new()
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_theme_constant_override("separation", 10)
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cab)
	var icone := IconeAtributo.new()
	icone.atributo = atributo
	icone.cor = CORES.get(atributo, Tema.PERGAMINHO)
	icone.custom_minimum_size = Vector2(40, 40)
	cab.add_child(icone)
	var t := Label.new()
	t.text = "%s  ·  %s" % [titulo.to_upper(), NOMES.get(atributo, atributo.to_upper())]
	t.theme_type_variation = "Titulo"
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 2)
	t.add_theme_color_override("font_color", CORES.get(atributo, Tema.OURO_CLARO))
	cab.add_child(t)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 12)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(linha)
	for i in slots.size():
		var estado: String = estados[i] if i < estados.size() else ("sucesso" if int(slots[i]) >= dt else "falha")
		var caixa := _dado(int(slots[i]), estado)
		linha.add_child(caixa)
	var res := Label.new()
	res.text = resultado
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res.add_theme_font_size_override("font_size", Tema.FONTE_G)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		res.add_theme_font_override("font", maquina)
	var cor_res := Tema.PERGAMINHO
	if sucesso_geral != null:
		cor_res = Tema.cor_sucesso() if sucesso_geral else Tema.cor_falha()
	res.add_theme_color_override("font_color", cor_res)
	res.modulate.a = 0.0
	v.add_child(res)
	var dt_lbl := Label.new()
	dt_lbl.text = "DT %d" % dt if dt > 0 else ""
	dt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dt_lbl.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	v.add_child(dt_lbl)
	_animar(res)


## Um d20: caixa que gira números e cai no valor final.
func _dado(valor: int, estado: String) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(64, 72)
	p.add_theme_stylebox_override("panel", Tema.caixa(Tema.PEDRA_CLARA, Tema.OURO_ESCURO, 2, 8, Vector2(6, 4)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 30)
	var f := Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	l.text = str(randi_range(1, 20))
	p.add_child(l)
	_caixas.append([p, l, valor, estado])
	return p


func _process(_delta: float) -> void:
	# Enquanto não caem, os números giram
	for c in _caixas:
		if not c[0].has_meta("caiu"):
			c[1].text = str(randi_range(1, 20))


func _animar(res: Label) -> void:
	_tw = create_tween()
	_tw.tween_interval(GIRO)
	for c in _caixas:
		_tw.tween_callback(_cair.bind(c))
		_tw.tween_interval(ENTRE)
	_tw.tween_property(res, "modulate:a", 1.0, 0.15)
	var ficar := Tema.duracao_resultado(FICA)
	if ficar <= 0.0:
		return   # fica até um clique (A3)
	_tw.tween_interval(ficar)
	_tw.tween_property(_raiz, "modulate:a", 0.0, 0.3)
	_tw.tween_callback(queue_free)


## Tempo até o resultado aparecer (o desfecho espera a rolagem terminar).
static func duracao_ate_resultado(qtd_dados: int) -> float:
	return GIRO + ENTRE * qtd_dados + 0.2


func _cair(c: Array) -> void:
	var p: PanelContainer = c[0]
	var l: Label = c[1]
	var estado: String = c[3]
	p.set_meta("caiu", true)
	l.text = "%d%s" % [c[2], {"sucesso": "✓", "falha": "✗"}.get(estado, "")]
	var cores := Tema.cores_slot(estado)   # dourado e sangue, ou azul e laranja (docs/18, A6)
	var fundo: Color = cores[0]
	var borda: Color = cores[1]
	var estilo := Tema.caixa(fundo, borda, 2, 8, Vector2(6, 4))
	estilo.shadow_color = Color(borda, 0.6)
	estilo.shadow_size = 10 if estado != "neutro" else 2
	p.add_theme_stylebox_override("panel", estilo)
	l.add_theme_color_override("font_color", cores[2] if estado != "neutro" else Tema.PERGAMINHO)
	p.pivot_offset = p.size / 2.0
	p.scale = Vector2.ONE * 1.35
	p.create_tween().tween_property(p, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Som.tocar("clique")


## Desenho simples do atributo: AGI asa, FOR punho, INT olho, PRE estrela, VIG coração.
class IconeAtributo:
	extends Control

	var atributo := ""
	var cor := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 2.0
		draw_arc(c, r, 0, TAU, 32, cor, 2.0, true)
		var k := r * 0.55
		match atributo:
			"agi":   # raio/asa: zigue-zague
				draw_polyline(PackedVector2Array([c + Vector2(-k, -k), c + Vector2(k * 0.2, -k * 0.1), c + Vector2(-k * 0.2, k * 0.1), c + Vector2(k, k)]), cor, 2.5, true)
			"for":   # punho: quadrado com dedos
				draw_rect(Rect2(c - Vector2(k * 0.8, k * 0.4), Vector2(k * 1.6, k * 1.1)), cor, false, 2.5)
				for i in 4:
					draw_line(c + Vector2(-k * 0.8 + i * k * 0.53, -k * 0.4), c + Vector2(-k * 0.8 + i * k * 0.53, -k * 0.85), cor, 2.0)
			"int":   # olho
				draw_arc(c + Vector2(0, k * 0.7), k * 1.2, PI * 1.2, PI * 1.8, 16, cor, 2.0, true)
				draw_arc(c - Vector2(0, k * 0.7), k * 1.2, PI * 0.2, PI * 0.8, 16, cor, 2.0, true)
				draw_circle(c, k * 0.3, cor)
			"pre":   # estrela de cinco pontas
				var pts := PackedVector2Array()
				for i in 6:
					var ang := -PI / 2.0 + i * TAU * 2.0 / 5.0
					pts.append(c + Vector2(cos(ang), sin(ang)) * k)
				draw_polyline(pts, cor, 2.0, true)
			_:       # vigor: coração
				var pts := PackedVector2Array()
				for i in 33:
					var t := TAU * i / 32.0
					var x := 16.0 * pow(sin(t), 3)
					var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
					pts.append(c + Vector2(x, y) * k / 16.0)
				draw_polyline(pts, cor, 2.0, true)


## Estados dos dados de um teste: só o que valeu fica dourado ou vermelho; os outros, neutros.
static func estados_do_teste(t: ResultadoTeste) -> Array:
	var estados: Array = []
	var marcado := false
	for v in t.slots:
		if v == t.escolhido and not marcado:
			marcado = true
			estados.append("sucesso" if t.sucesso else "falha")
		else:
			estados.append("neutro")
	return estados
