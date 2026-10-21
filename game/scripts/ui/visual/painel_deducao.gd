class_name PainelDeducao
extends CanvasLayer
## Ficha de suspeitos (docs/32): a mesa de dedução do caso. Uma aba por pergunta; em cada
## uma, os candidatos com os 3 traços de cada. Os traços que as pistas já revelaram acendem em
## ouro, com ✔ (não só a cor); cruzar os traços é com o jogador: a carta não acende sozinha.
## Clicar num candidato pede confirmação e ACUSA: quem chama
## decide como enviar (comando de lockstep `deduzir`, na cena ou no mapa).
##   PainelDeducao.abrir(self, caso, "quem", func(pergunta, candidato): ...)

var caso: Caso
var pergunta_id := ""
var ao_acusar: Callable
var _cartas: Dictionary = {}     ## candidato_id -> Button
var _abas: Dictionary = {}       ## pergunta_id -> Button
var _corpo: VBoxContainer


static func abrir(pai: Node, p_caso: Caso, p_pergunta: String, p_ao_acusar: Callable) -> PainelDeducao:
	var d := PainelDeducao.new()
	d.caso = p_caso
	d.pergunta_id = p_pergunta if p_caso.pergunta(p_pergunta).size() > 0 else String(p_caso.perguntas[0].id)
	d.ao_acusar = p_ao_acusar
	d._montar()
	pai.add_child(d)
	return d


static func aberto(pai: Node) -> bool:
	return not pai.find_children("*", "PainelDeducao", true, false).is_empty()


## A primeira pergunta ainda aberta que já tem pista (ou a primeira aberta, ou a primeira).
static func pergunta_sugerida(p_caso: Caso) -> String:
	for q in p_caso.perguntas:
		if not q.respondida and int(q.encontradas) > 0:
			return String(q.id)
	for q in p_caso.perguntas:
		if not q.respondida:
			return String(q.id)
	return String(p_caso.perguntas[0].id) if not p_caso.perguntas.is_empty() else ""


func _montar() -> void:
	layer = 94   # abaixo do DialogoPapel (95), que confirma a acusação
	name = "PainelDeducao"
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.8)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			fechar())
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(28, 20)))
	papel.theme = Tema.tema_papel()
	papel.custom_minimum_size = Vector2(820, 0)
	papel.rotation_degrees = -0.4
	centro.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_G)
	papel.add_child(v)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(topo)
	var t := Label.new()
	t.text = "FICHA DE SUSPEITOS"
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 2)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(t)
	for q in caso.perguntas:
		var b := Button.new()
		b.theme_type_variation = "BotaoPapel"
		b.toggle_mode = true
		var curto: String = String(q.get("curto", "")) if String(q.get("curto", "")) != "" else {"quem": "Quem?", "oque": "O quê?", "onde": "Onde?"}.get(q.id, String(q.id))
		b.text = ("✔ " if q.respondida else "") + curto
		b.tooltip_text = q.texto
		var pid := String(q.id)
		b.pressed.connect(func(): mostrar(pid))
		topo.add_child(b)
		_abas[pid] = b
	_corpo = VBoxContainer.new()
	_corpo.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(_corpo)
	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(rodape)
	var regra := Label.new()
	regra.text = "Cada pista revela um traço do culpado. Duas pistas firmes diferentes deixam um só suspeito; um depoimento com ? pode estar errado. Acusar errado custa %d de Membrana e risca o suspeito." % -Caso.penalidade_palpite()
	regra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	regra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	regra.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
	regra.add_theme_font_size_override("font_size", Tema.FONTE_P)
	rodape.add_child(regra)
	var fechar_b := Button.new()
	fechar_b.theme_type_variation = "BotaoPapel"
	fechar_b.text = "Fechar   Esc"
	fechar_b.pressed.connect(fechar)
	rodape.add_child(fechar_b)
	mostrar(pergunta_id)


func mostrar(pid: String) -> void:
	pergunta_id = pid
	for id in _abas:
		(_abas[id] as Button).set_pressed_no_signal(id == pid)
	for f in _corpo.get_children():
		f.queue_free()
	_cartas.clear()
	var q := caso.pergunta(pid)
	var achados := caso.indicios_encontrados(pid)
	var enunciado := Label.new()
	enunciado.text = q.texto
	enunciado.add_theme_color_override("font_color", Tema.TINTA)
	enunciado.add_theme_font_size_override("font_size", Tema.FONTE_M)
	var negrito := Tema._fonte(Tema.ARQ_NEGRITO)
	if negrito != null:
		enunciado.add_theme_font_override("font", negrito)
	_corpo.add_child(enunciado)
	var linha := HFlowContainer.new()
	linha.add_theme_constant_override("h_separation", Tema.ESPACO_M)
	linha.add_theme_constant_override("v_separation", Tema.ESPACO_P)
	_corpo.add_child(linha)
	var rot := Label.new()
	var tem_pista: bool = not achados.is_empty() or not caso.indicios_duvidosos(pid).is_empty()
	rot.text = "Indícios:" if tem_pista else "Nenhuma pista desta pergunta ainda. Examine os pontos da cena para acusar."
	rot.add_theme_color_override("font_color", Color(Tema.TINTA, 0.8))
	linha.add_child(rot)
	for traco in achados:
		linha.add_child(_chip(traco, true))
	var duvidosos := caso.indicios_duvidosos(pid)
	for traco in duvidosos:   # depoimentos incertos (docs/35): podem ser verdade ou não
		linha.add_child(_chip(traco, false, true))
	var colunas := 3 if caso.candidatos(pid).size() > 4 else 2
	var grade := GridContainer.new()
	grade.columns = colunas
	grade.add_theme_constant_override("h_separation", Tema.ESPACO_G)
	grade.add_theme_constant_override("v_separation", Tema.ESPACO_G)
	_corpo.add_child(grade)
	var pode: bool = not q.respondida and int(q.encontradas) > 0
	var culpado := String(caso.verdadeiro(pid).get("id", "")) if q.respondida else ""
	for c in caso.candidatos(pid):
		grade.add_child(_carta(c, achados, q.get("descartados", []), pode, culpado, duvidosos))


func _carta(c: Dictionary, achados: Array, descartados: Array, pode: bool, culpado: String, duvidosos: Array = []) -> Button:
	var b := Button.new()
	b.theme_type_variation = "BotaoPapel"
	b.custom_minimum_size = Vector2(250, 90)
	b.clip_contents = true
	var riscado: bool = c.id in descartados
	b.disabled = not pode or riscado
	b.tooltip_text = "Acusar: %s" % c.nome if not b.disabled else c.nome
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 8
	v.offset_bottom = -8
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var nome := Label.new()
	nome.text = c.nome.substr(0, 1).to_upper() + c.nome.substr(1)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.add_theme_color_override("font_color", Tema.TINTA)
	nome.add_theme_font_size_override("font_size", Tema.FONTE_P + 1)
	var negrito := Tema._fonte(Tema.ARQ_NEGRITO)
	if negrito != null:
		nome.add_theme_font_override("font", negrito)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nome)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 3)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(chips)
	for t in c.indicios:
		chips.add_child(_chip(t, t in achados, t in duvidosos))
	if riscado or (culpado != "" and c.id != culpado):
		b.modulate = Color(1, 1, 1, 0.45)
	if riscado:
		_selo(b, "DESCARTADO", Tema.SANGUE)
	elif culpado == c.id:
		_selo(b, "CULPADO" if pergunta_id == "quem" else "CONFIRMADO", Tema.SANGUE_CLARO)
	var cid := String(c.id)
	b.pressed.connect(func(): _pedir_acusacao(cid, c.nome))
	_cartas[cid] = b
	return b


## Um traço como etiqueta: aceso (ouro, com ✔) se já apareceu numa pista firme; com "?"
## (âmbar) se só veio de um depoimento incerto (docs/35).
func _chip(traco: String, aceso: bool, duvidoso: bool = false) -> Label:
	var l := Label.new()
	var rotulo := String(Caso.indicio(traco).get("rotulo", traco)).to_upper()
	l.text = ("✔ " + rotulo) if aceso else (("? " + rotulo) if duvidoso else rotulo)
	l.tooltip_text = String(Caso.indicio(traco).get("texto", ""))
	if duvidoso and not aceso:
		l.tooltip_text = "Só um depoimento incerto aponta isto: pode estar errado.\n" + l.tooltip_text
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_theme_font_size_override("font_size", Tema.FONTE_P - 1)
		l.add_theme_color_override("font_color", Tema.TINTA)
		l.add_theme_stylebox_override("normal", Tema.caixa(Color(Tema.AVISO, 0.3), Color(Tema.AVISO, 0.9), 1, 2, Vector2(5, 1)))
		return l
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.add_theme_font_size_override("font_size", Tema.FONTE_P - 1)   # 13, o mínimo das cartas (docs/19)
	l.add_theme_color_override("font_color", Tema.TINTA if aceso else Color(Tema.TINTA, 0.6))
	l.add_theme_stylebox_override("normal", Tema.caixa(Color(Tema.OURO_CLARO, 0.85) if aceso else Color(0, 0, 0, 0.06),
		Color(Tema.OURO_ESCURO, 0.9) if aceso else Color(Tema.TINTA, 0.25), 1, 2, Vector2(5, 1)))
	return l


func _selo(b: Control, texto: String, cor: Color) -> void:
	var s := Label.new()
	s.text = texto
	s.add_theme_color_override("font_color", cor)
	s.add_theme_font_size_override("font_size", Tema.FONTE_P)
	var ft := Tema.fonte_titulo()
	if ft != null:
		s.add_theme_font_override("font", ft)
	s.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), Color(cor, 0.85), 2, 3, Vector2(6, 1)))
	s.rotation_degrees = -8
	s.position = Vector2(140, 54)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(s)


func _pedir_acusacao(cid: String, nome: String) -> void:
	DialogoPapel.perguntar(self, "Acusar", "Acusar %s?\nSe errar, a Membrana cai %d e o suspeito sai da lista." % [nome, -Caso.penalidade_palpite()],
		"Acusar", func(): acusar(cid))


## Envia a acusação (depois da confirmação) e fecha a ficha.
func acusar(cid: String) -> void:
	if ao_acusar.is_valid():
		ao_acusar.call(pergunta_id, cid)
	fechar()


func fechar() -> void:
	queue_free()


## Teclas: Esc fecha; as outras não passam para a tela de baixo (cartas, quadro, pausa).
## É _unhandled_key_input porque as telas tratam o Esc nessa fase, antes do _unhandled_input.
func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed:
		return
	get_viewport().set_input_as_handled()
	if (evento as InputEventKey).keycode == KEY_ESCAPE:
		fechar()
