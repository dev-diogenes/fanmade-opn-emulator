class_name CartaoAgente
extends PanelContainer
## Retrato de um agente do grupo, fixo sobre o 3D como no FTK2 (docs/08, R3):
## nome, classe, PV, PE e SAN em barras; borda dourada na vez; apagado quando caído.

## Clique no retrato: abre a ficha e o inventário (DossieAgente).
signal escolhido(agente: Agente)

const ICONE_CLASSE := {"combatente": "⚔", "especialista": "✦", "ocultista": "☾", "mundano": "●"}

var agente: Agente
var cor := Color.WHITE
var _nome: Label
var _barras: Dictionary = {}   ## "pv" | "pe" | "san" -> ProgressBar
var _estilo: StyleBoxFlat
var _tremer := false
var _t := 0.0


static func criar(p_agente: Agente, p_cor: Color) -> CartaoAgente:
	var c := CartaoAgente.new()
	c.agente = p_agente
	c.cor = p_cor
	c._montar()
	return c


func _montar() -> void:
	custom_minimum_size = Vector2(176, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = Atalhos.com_tecla("Ficha e inventário", "ficha")
	gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			escolhido.emit(agente))
	_estilo = Tema.caixa(Color(Tema.PEDRA, 0.9), Tema.OURO_ESCURO, 2, 6, Vector2(Tema.ESPACO_M, Tema.ESPACO_M - 2))
	_estilo.border_width_left = 5
	_estilo.shadow_color = Color(0, 0, 0, 0.5)
	_estilo.shadow_size = 6
	add_theme_stylebox_override("panel", _estilo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_nome = Label.new()
	_nome.add_theme_font_size_override("font_size", Tema.FONTE_M)
	_nome.clip_text = true
	v.add_child(_nome)
	for chave in ["pv", "pe", "san"]:
		v.add_child(_linha(chave))
	atualizar(false)


func _linha(chave: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", Tema.ESPACO_P)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = chave.to_upper()
	l.custom_minimum_size = Vector2(32, 0)
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)
	l.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	h.add_child(l)
	var b := ProgressBar.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 14)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cor_barra: Color = {"pv": Tema.SANGUE_CLARO, "pe": Tema.ELEMENTO.energia, "san": Tema.INFO}[chave]
	b.add_theme_stylebox_override("fill", Tema.caixa(cor_barra.darkened(0.15), cor_barra.lightened(0.2), 1, 3, Vector2.ZERO))
	b.add_theme_stylebox_override("background", Tema.caixa(Color("0b0a0e"), Tema.OURO_ESCURO, 1, 3, Vector2.ZERO))
	h.add_child(b)
	var n := Label.new()
	n.custom_minimum_size = Vector2(44, 0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	n.add_theme_font_size_override("font_size", Tema.FONTE_P)
	h.add_child(n)
	_barras[chave] = {"barra": b, "numero": n, "titulo": l}
	return h


func atualizar(da_vez: bool) -> void:
	var icone: String = ICONE_CLASSE.get(agente.classe_id, "●")
	var caido := agente.esta_fora_de_combate()
	var perturbado := agente.tem(Ser.PERTURBADO) or agente.tem(Ser.ENLOUQUECENDO)
	_nome.text = "%s %s%s" % [icone, agente.nome, "  ✝" if caido else ""]
	# Perturbado: o rótulo SAN vira "SAN!" em vermelho (não depende só da cor do nome)
	_barras["san"].titulo.text = "SAN!" if perturbado else "SAN"
	_barras["san"].titulo.add_theme_color_override("font_color", Tema.SANGUE_CLARO.lightened(0.25) if perturbado else Tema.TEXTO_SUAVE)
	var ficha := Atalhos.com_tecla("Ficha e inventário", "ficha")
	tooltip_text = ("%s está perturbado: Sanidade abaixo da metade. %s" % [agente.nome, ficha]) if perturbado else ficha
	_nome.add_theme_color_override("font_color", Tema.SANGUE_CLARO.lightened(0.2) if perturbado else (Tema.OURO_CLARO if da_vez else Tema.PERGAMINHO))
	_tremer = perturbado and not caido
	_valor("pv", agente.pv, agente.pv_maximo)
	_valor("pe", agente.pe, agente.pe_maximo)
	_valor("san", agente.san, agente.san_maximo)
	_estilo.border_color = Tema.OURO_CLARO if da_vez else Tema.OURO_ESCURO
	_estilo.border_width_left = 5
	# A faixa da esquerda é a cor do jogador (a mesma da base da figura no 3D)
	modulate = Color(1, 1, 1, 0.5) if caido else Color.WHITE
	scale = Vector2.ONE * (1.04 if da_vez else 1.0)
	pivot_offset = size / 2.0
	queue_redraw()


func _valor(chave: String, atual: int, maximo: int) -> void:
	var b: ProgressBar = _barras[chave].barra
	b.max_value = maxi(1, maximo)
	b.value = clampi(atual, 0, maxi(1, maximo))
	_barras[chave].numero.text = "%d/%d" % [atual, maximo]


func _process(delta: float) -> void:
	# Perturbado (E6): o retrato treme de leve, como uma mão nervosa segurando a foto
	if _tremer:
		_t += delta
		rotation = sin(_t * 23.0) * 0.012 + sin(_t * 7.0) * 0.006
	elif rotation != 0.0:
		rotation = 0.0


func _draw() -> void:
	# Faixa vertical na cor do jogador, por cima da borda esquerda
	draw_rect(Rect2(Vector2(0, 4), Vector2(5, size.y - 8)), cor)
