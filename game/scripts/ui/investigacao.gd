extends Control
## Cena de investigação (piloto da identidade visual, docs/09): 3D em tela cheia com HUD
## de found footage, o quadro de cortiça do caso (Tab), o grupo no canto e as ações como
## cartas (1–4). Escolher uma carta abre um bilhete com as opções; Enter confirma, Esc fecha.
## Cada agente, na sua vez, procura pistas num ponto de interesse, facilita a investigação,
## ajuda um aliado ou usa uma habilidade, até a urgência acabar.

const LARGURA_QUADRO := 470.0

var cena: CenaInvestigacao
var missao: Missao
var _jogo: Node
var _ponto := ""

var _vista: SubViewportContainer
var _visao: Investigacao3D
var _lbl_topo: Label
var _lbl_urgencia: Label
var _fita: Control
var _lbl_vez: Label
var _rec: Label
var _quadro: QuadroInvestigacao
var _quadro_aberto := true
var _btn_quadro: Button
var _grupo: HBoxContainer
var _cartoes: Dictionary = {}
var _mao: Control
var _cartas: Dictionary = {}       ## "procurar" | "facilitar" | "ajudar" | "passar" -> CartaAcao
var _carta_sel := ""
var _bilhete: PanelContainer
var _caixa_bilhete: VBoxContainer
var _relatorio: PanelContainer
var _log: RichTextLabel
var _relatorio_aberto := false
var _dica: Label
var _painel_fim: PanelContainer
var _controles: ControleLocal
var _ultimo_agente: Agente
var _tempo := 0.0
var sessao: Sessao

## Escolhas do bilhete
var _pericia := ""
var _foco := 0
var _selos: Dictionary = {}        ## "faro" | "perito" | "ecletico" | "presteza" -> bool
var _opcao_facilitar: Array = []   ## [opcao_id, pericia]
var _aliado: Agente
var _pericia_ajuda := ""


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	if _jogo != null and _jogo.missao != null and not _jogo.missao.investigacao_pendente.is_empty():
		missao = _jogo.missao
	else:
		# Demonstração: abre a cena direto (F6) com o grupo padrão.
		missao = Missao.nova(42)
		missao._preparar_investigacao(missao.mapa.encontrar("inicio"), "casa_abandonada")
	cena = missao.criar_cena_investigacao()
	sessao = _jogo.sessao if _jogo != null and _jogo.missao == missao else Sessao.new()
	sessao.entrar("investigacao", _aplicar_comando, func(): return cena.agente_atual(), func(): return Comandos.hash_investigacao(cena))
	sessao.comando_aplicado.connect(_ao_comando_aplicado)
	Entrada.configurar()
	_controles = _jogo.controles() if _jogo != null and _jogo.missao == missao else ControleLocal.padrao()
	_montar_interface()
	cena.registro.connect(func(t): _log.append_text(t + "\n"))
	cena.terminou.connect(func(_r): _painel_fim.visible = true)
	# Registro do início da cena (emitido antes da conexão)
	_log.append_text("[b]%s[/b] — urgência %s (%d rodadas).\n[i]Pista básica:[/i] %s\n" % [cena.cena.nome, String(cena.urgencia.get("nome", "")).to_lower(), cena.rodadas_max, cena.cena.pista_basica])
	_selecionar_carta("procurar")
	_atualizar()
	sessao.liberar()
	Tutorial.botao_ajuda(self, "investigacao", _alvos_do_tutorial)
	Tutorial.ao_entrar("investigacao", self, _alvos_do_tutorial())


func _alvos_do_tutorial() -> Dictionary:
	return {"cena": _vista, "procurar": _cartas.procurar, "facilitar": _cartas.facilitar, "caso": _quadro, "topo": _lbl_topo}


func _process(delta: float) -> void:
	_tempo += delta
	if _rec != null:
		var s := int(_tempo)
		_rec.text = "%s REC   00:%02d:%02d" % ["●" if int(_tempo * 2.0) % 2 == 0 else "  ", s / 60, s % 60]


# --- Interface -------------------------------------------------------------------

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Tema.fundo())

	_vista = SubViewportContainer.new()
	_vista.stretch = true
	_vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	Tema.veu(_vista)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	_vista.add_child(vp)
	_visao = Investigacao3D.new()
	vp.add_child(_visao)
	_visao.construir(cena.cena, cena.agentes)
	_vista.gui_input.connect(_entrada_3d)
	add_child(_vista)

	add_child(_Enquadramento.new())
	_montar_topo()
	_montar_quadro()
	_montar_grupo()
	_montar_mao()
	_montar_bilhete()
	_montar_relatorio()

	_dica = Label.new()
	_dica.visible = false
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_theme_stylebox_override("normal", Tema.caixa_papel(Vector2(8, 4)))
	_dica.add_theme_color_override("font_color", Tema.TINTA)
	_dica.add_theme_font_size_override("font_size", Tema.FONTE_P)
	add_child(_dica)

	_painel_fim = PanelContainer.new()
	_painel_fim.visible = false
	_painel_fim.add_theme_stylebox_override("panel", MolduraRiscada.criar(Tema.OURO_CLARO, Color(Tema.FUNDO, 0.95), Vector2(28, 22)))
	_painel_fim.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", Tema.ESPACO_G)
	_painel_fim.add_child(caixa)
	var t := Label.new()
	t.text = "Investigação encerrada"
	t.theme_type_variation = "Titulo"
	caixa.add_child(t)
	var b := Button.new()
	b.text = "Voltar ao mapa"
	b.theme_type_variation = "BotaoPrincipal"
	b.pressed.connect(_voltar)
	caixa.add_child(b)
	add_child(_painel_fim)


func _montar_topo() -> void:
	_rec = Label.new()
	_rec.position = Vector2(34, 26)
	_rec.add_theme_color_override("font_color", Tema.PERIGO)
	_rec.add_theme_font_size_override("font_size", Tema.FONTE_M)
	_rec.add_theme_constant_override("outline_size", 4)
	_rec.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	add_child(_rec)
	var topo := VBoxContainer.new()
	topo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	topo.offset_top = 18
	topo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	topo.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	_lbl_topo = Label.new()
	_lbl_topo.theme_type_variation = "Titulo"
	_lbl_topo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_topo.add_theme_font_size_override("font_size", 26)
	_lbl_topo.add_theme_constant_override("outline_size", 8)
	_lbl_topo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	topo.add_child(_lbl_topo)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", Tema.ESPACO_M)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(linha)
	_lbl_urgencia = Label.new()
	_lbl_urgencia.add_theme_constant_override("outline_size", 6)
	_lbl_urgencia.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	linha.add_child(_lbl_urgencia)
	_fita = _FitaUrgencia.new()
	linha.add_child(_fita)
	_lbl_vez = Label.new()
	_lbl_vez.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_vez.add_theme_color_override("font_color", Tema.OURO_CLARO)
	_lbl_vez.add_theme_constant_override("outline_size", 6)
	_lbl_vez.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	topo.add_child(_lbl_vez)


func _montar_quadro() -> void:
	_quadro = QuadroInvestigacao.new()
	_quadro.anchor_left = 1.0
	_quadro.anchor_right = 1.0
	_quadro.anchor_bottom = 1.0
	_quadro.offset_top = 70
	_quadro.offset_bottom = -232
	_posicionar_quadro(true)
	add_child(_quadro)
	_btn_quadro = Button.new()
	_btn_quadro.text = "Quadro (Tab)"
	_btn_quadro.anchor_left = 1.0
	_btn_quadro.anchor_right = 1.0
	_btn_quadro.offset_left = -190
	_btn_quadro.offset_right = -70
	_btn_quadro.offset_top = 22
	_btn_quadro.offset_bottom = 56
	_btn_quadro.add_theme_stylebox_override("normal", MolduraRiscada.criar())
	_btn_quadro.add_theme_stylebox_override("hover", MolduraRiscada.criar(Tema.OURO_CLARO))
	_btn_quadro.pressed.connect(_alternar_quadro)
	add_child(_btn_quadro)


func _posicionar_quadro(imediato: bool = false) -> void:
	var esquerda := -LARGURA_QUADRO - 16.0 if _quadro_aberto else 8.0
	var direita := -16.0 if _quadro_aberto else LARGURA_QUADRO + 8.0
	if imediato:
		_quadro.offset_left = esquerda
		_quadro.offset_right = direita
		return
	var tw := create_tween().set_parallel()
	tw.tween_property(_quadro, "offset_left", esquerda, 0.25).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_quadro, "offset_right", direita, 0.25).set_trans(Tween.TRANS_CUBIC)


func _alternar_quadro() -> void:
	_quadro_aberto = not _quadro_aberto
	_posicionar_quadro()


func _montar_grupo() -> void:
	_grupo = HBoxContainer.new()
	_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grupo.add_theme_constant_override("separation", Tema.ESPACO_M)
	_grupo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, Tema.ESPACO_G)
	_grupo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_grupo)
	var cores := Tema.CORES_JOGADORES
	for i in cena.agentes.size():
		var c := CartaoAgente.criar(cena.agentes[i], cores[i % cores.size()])
		c.custom_minimum_size.x = 150
		_grupo.add_child(c)
		_cartoes[cena.agentes[i]] = c


func _montar_mao() -> void:
	_mao = Control.new()
	_mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mao.anchor_left = 1.0
	_mao.anchor_right = 1.0
	_mao.anchor_top = 1.0
	_mao.anchor_bottom = 1.0
	_mao.offset_left = -4 * (CartaAcao.TAMANHO.x + 10) - 16
	_mao.offset_right = -16
	_mao.offset_top = -CartaAcao.TAMANHO.y - 46
	_mao.offset_bottom = -46
	add_child(_mao)
	var defs := [["procurar", "Procurar", "Teste de perícia num ponto", Tema.ELEMENTO.conhecimento],
		["facilitar", "Facilitar", "+2 nos testes e mais luz", Tema.OURO],
		["ajudar", "Ajudar", "Bônus para um aliado", Tema.INFO],
		["passar", "Passar", "Encerra a vez ou sai da cena", Tema.ELEMENTO.morte]]
	for i in defs.size():
		var d: Array = defs[i]
		var carta := CartaAcao.criar(d[1], d[2], i + 1, 101 + i * 37, d[3])
		carta.position = Vector2(i * (CartaAcao.TAMANHO.x + 10), 0)
		carta.size = CartaAcao.TAMANHO
		carta.pressed.connect(_selecionar_carta.bind(d[0]))
		_mao.add_child(carta)
		_cartas[d[0]] = carta


func _montar_bilhete() -> void:
	# O bilhete fica preso acima dos retratos do grupo (o agente da vez "segura" o bilhete)
	_bilhete = PanelContainer.new()
	_bilhete.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(16, 14)))
	_bilhete.anchor_top = 1.0
	_bilhete.anchor_bottom = 1.0
	_bilhete.offset_left = 16
	_bilhete.offset_right = 16 + 400
	_bilhete.offset_bottom = -128
	_bilhete.offset_top = -128
	_bilhete.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bilhete.rotation_degrees = -0.8
	_bilhete.visible = false
	add_child(_bilhete)
	_caixa_bilhete = VBoxContainer.new()
	_caixa_bilhete.add_theme_constant_override("separation", 6)
	_bilhete.add_child(_caixa_bilhete)


func _montar_relatorio() -> void:
	_relatorio = PanelContainer.new()
	_relatorio.add_theme_stylebox_override("panel", MolduraRiscada.criar(Tema.TRACO, Color(Tema.FUNDO, 0.88), Vector2(12, 8)))
	_relatorio.anchor_left = 1.0
	_relatorio.anchor_right = 1.0
	_relatorio.anchor_top = 1.0
	_relatorio.anchor_bottom = 1.0
	_relatorio.offset_left = -4 * (CartaAcao.TAMANHO.x + 10) - 16
	_relatorio.offset_right = -16
	_relatorio.offset_bottom = -8
	_relatorio.offset_top = -38
	_relatorio.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_relatorio)
	var v := VBoxContainer.new()
	_relatorio.add_child(v)
	var cab := Button.new()
	cab.flat = true
	cab.text = "▸ Relatório de campo"
	cab.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cab.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	cab.pressed.connect(func():
		_relatorio_aberto = not _relatorio_aberto
		cab.text = ("▾" if _relatorio_aberto else "▸") + " Relatório de campo"
		_log.visible = _relatorio_aberto
		_relatorio.offset_top = -300.0 if _relatorio_aberto else -38.0)
	v.add_child(cab)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.visible = false
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_log)


# --- Cartas e bilhete --------------------------------------------------------------

func _selecionar_carta(id: String) -> void:
	_carta_sel = id
	for k in _cartas:
		_cartas[k].selecionada = k == id
		_cartas[k]._subir(k == id)
	_montar_opcoes()


## Reconstrói o bilhete da carta escolhida, com as opções do agente da vez.
func _montar_opcoes() -> void:
	for filho in _caixa_bilhete.get_children():
		filho.visible = false   # some do layout já; o botão que chamou ainda pode estar emitindo o sinal
		filho.queue_free()
	var a := cena.agente_atual()
	_bilhete.visible = _carta_sel != "" and a != null and not cena.encerrada
	if not _bilhete.visible:
		return
	match _carta_sel:
		"procurar": _opcoes_procurar(a)
		"facilitar": _opcoes_facilitar(a)
		"ajudar": _opcoes_ajudar(a)
		"passar": _opcoes_passar(a)
	_bilhete.offset_top = _bilhete.offset_bottom   # encolhe; o conteúdo novo define a altura


func _titulo_bilhete(texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = "TextoPapel"
	l.add_theme_font_size_override("font_size", Tema.FONTE_G)
	var f := Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	_caixa_bilhete.add_child(l)


func _texto_bilhete(texto: String, suave: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = "TextoPapel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)
	if suave:
		l.add_theme_color_override("font_color", Color(Tema.TINTA, 0.6))
	_caixa_bilhete.add_child(l)
	return l


func _botao_papel(pai: Control, texto: String, marcado: bool, acao: Callable, alternavel: bool = true) -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = "BotaoPapel"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.toggle_mode = alternavel
	b.button_pressed = marcado
	b.pressed.connect(acao)
	pai.add_child(b)
	return b


func _confirmar(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto + "   ⏎"
	b.theme_type_variation = "BotaoPrincipal"
	b.pressed.connect(acao)
	_caixa_bilhete.add_child(b)
	return b


func _linha_foco(a: Agente) -> void:
	var maximo := a.pe_disponivel_no_turno()
	_foco = clampi(_foco, 0, maximo)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	_caixa_bilhete.add_child(h)
	var l := Label.new()
	l.text = "Foco (PE → +1d20)"
	l.theme_type_variation = "TextoPapel"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	_botao_papel(h, " − ", false, func(): _foco = maxi(0, _foco - 1); _montar_opcoes(), false).disabled = _foco <= 0
	var n := Label.new()
	n.text = "%d / %d" % [_foco, maximo]
	n.theme_type_variation = "TextoPapel"
	h.add_child(n)
	_botao_papel(h, " + ", false, func(): _foco = mini(maximo, _foco + 1); _montar_opcoes(), false).disabled = _foco >= maximo


func _selo(pai: Control, chave: String, texto: String) -> void:
	_botao_papel(pai, "✦ " + texto, _selos.get(chave, false), func(): _selos[chave] = not _selos.get(chave, false))


func _opcoes_procurar(a: Agente) -> void:
	var pt := cena.ponto(_ponto)
	_titulo_bilhete("Procurar pistas")
	var h := HBoxContainer.new()
	_caixa_bilhete.add_child(h)
	var onde := Label.new()
	onde.text = "Em: %s" % pt.get("nome", "—")
	onde.theme_type_variation = "TextoPapel"
	onde.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(onde)
	_botao_papel(h, "Próximo ponto ▸", false, _proximo_ponto, false)
	if pt.is_empty():
		_texto_bilhete("Não restam pontos de interesse.", true)
		return
	if not _pericia in pt.pericias:
		_pericia = String(pt.pericias.keys()[0])
	for per in pt.pericias:
		var bonus := a.bonus_pericia(per)
		var texto := "%s  ·  DT %d  ·  %dd20%+d%s" % [missao.ruleset.pericia(per).nome, int(pt.pericias[per]), maxi(1, a.dados_da_pericia(per)), bonus,
			"" if a.pode_usar_pericia(per) else "  (exige treino)"]
		_botao_papel(_caixa_bilhete, texto, per == _pericia, func(): _pericia = per; _montar_opcoes())
	_linha_foco(a)
	var selos := HFlowContainer.new()
	_caixa_bilhete.add_child(selos)
	if a.tem_habilidade("faro_para_pistas"):
		_selo(selos, "faro", "Faro p/ Pistas")
	if not a.perito.is_empty():
		_selo(selos, "perito", "Perito")
	if a.classe_id == "especialista":
		_selo(selos, "ecletico", "Eclético")
	for hab in ["incansavel", "pensamento_agil", "guiado_pelo_paranormal"]:
		if a.tem_habilidade(hab):
			_botao_papel(selos, "⚡ %s (2 PE)" % a.ruleset.poder(a.classe_id, hab).nome, false, _usar_extra.bind(hab), false)
	if a.tem_habilidade("na_trilha_certa"):
		_botao_papel(selos, "⚡ Na Trilha Certa", false, _trilha_certa.bind(a), false)
	_confirmar("Procurar", _procurar)


func _opcoes_facilitar(a: Agente) -> void:
	_titulo_bilhete("Facilitar a investigação")
	_texto_bilhete("+2 nos próximos testes e a cena fica mais clara.", true)
	var opcoes: Array = []
	for o in cena.cena.get("facilitar", []):
		for per in o.pericias:
			opcoes.append([o.id, per, "%s  ·  %s  ·  DT %d" % [o.texto, missao.ruleset.pericia(per).nome, int(o.pericias[per])]])
	if opcoes.is_empty():
		_texto_bilhete("Nada a facilitar nesta cena.", true)
		return
	if _opcao_facilitar.is_empty() or not opcoes.any(func(o): return o[0] == _opcao_facilitar[0] and o[1] == _opcao_facilitar[1]):
		_opcao_facilitar = [opcoes[0][0], opcoes[0][1]]
	for o in opcoes:
		_botao_papel(_caixa_bilhete, o[2], o[0] == _opcao_facilitar[0] and o[1] == _opcao_facilitar[1],
			func(): _opcao_facilitar = [o[0], o[1]]; _montar_opcoes()).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_linha_foco(a)
	if a.tem_habilidade("presteza_atletica"):
		var selos := HFlowContainer.new()
		_caixa_bilhete.add_child(selos)
		_selo(selos, "presteza", "Presteza Atlética")
	_confirmar("Facilitar", _facilitar)


func _opcoes_ajudar(a: Agente) -> void:
	_titulo_bilhete("Ajudar um aliado")
	_texto_bilhete("Teste com DT 10; se passar, o aliado ganha bônus no próximo teste.", true)
	var aliados := cena.agentes.filter(func(x): return x != a)
	if aliados.is_empty():
		_texto_bilhete("Ninguém para ajudar.", true)
		return
	if not _aliado in aliados:
		_aliado = aliados[0]
	var linha := HFlowContainer.new()
	_caixa_bilhete.add_child(linha)
	for al in aliados:
		_botao_papel(linha, al.nome, al == _aliado, func(): _aliado = al; _montar_opcoes())
	if not _pericia_ajuda in a.pericias and not a.pericias.is_empty():
		_pericia_ajuda = String(a.pericias.keys()[0])
	var pericias := HFlowContainer.new()
	_caixa_bilhete.add_child(pericias)
	for per in a.pericias:
		_botao_papel(pericias, missao.ruleset.pericia(per).nome, per == _pericia_ajuda, func(): _pericia_ajuda = per; _montar_opcoes())
	_confirmar("Ajudar %s" % _aliado.nome, _ajudar)


func _opcoes_passar(_a: Agente) -> void:
	_titulo_bilhete("Encerrar a vez")
	_texto_bilhete("Passar entrega a vez ao próximo agente. Sair da cena leva o grupo de volta ao mapa com o que descobriu.", true)
	_confirmar("Passar a vez", _passar)
	_botao_papel(_caixa_bilhete, "Sair da cena", false, _sair, false)


# --- Atualização --------------------------------------------------------------------

func _atualizar() -> void:
	var a := cena.agente_atual()
	_lbl_vez.text = _controles.faixa_da_vez(a)
	if _lbl_vez.text == "" and a != null:
		_lbl_vez.text = "Vez de %s" % a.nome
	if a != _ultimo_agente:
		_ultimo_agente = a
		_foco = 0
		_selos.clear()
		if a != null and _controles.usa_controle(a) and is_inside_tree():
			_cartas.procurar.grab_focus.call_deferred()
	_lbl_topo.text = String(cena.cena.nome).to_upper()
	_lbl_urgencia.text = "urgência %s · rodada %d de %d" % [String(cena.urgencia.get("nome", "")).to_lower(), mini(cena.rodada, cena.rodadas_max), cena.rodadas_max]
	_fita.definir(cena.rodadas_max, cena.rodada - 1)
	_lbl_urgencia.add_theme_color_override("font_color", Tema.PERIGO if cena.rodada >= cena.rodadas_max else Tema.PERGAMINHO)
	for k in _cartas:
		_cartas[k].disabled = a == null or cena.encerrada
	if _ponto != "" and not _ponto in cena.pontos_restantes:
		_ponto = ""
	if _ponto == "" and not cena.pontos_restantes.is_empty():
		_ponto = cena.pontos_restantes[0]
	for ag in _cartoes:
		_cartoes[ag].atualizar(ag == a)
	_quadro.atualizar(missao.caso)
	Tema.membrana_na_tela(_vista, missao.membrana.valor if missao.membrana != null else 100)
	_montar_opcoes()
	_visao.atualizar(cena, _ponto)


# --- Co-op local, controles e teclado (ADR 0004) --------------------------------------

## Só o dispositivo do dono do agente da vez age na cena.
func _input(evento: InputEvent) -> void:
	if TourGuiado.em_andamento():
		return
	if _controles != null and cena != null and not _controles.evento_permitido(evento, cena.agente_atual()):
		get_viewport().set_input_as_handled()


## Atalhos: 1–4 escolhem a carta, Tab abre o quadro, Enter confirma, Esc fecha o bilhete.
func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo or TourGuiado.em_andamento():
		return
	var ids := ["procurar", "facilitar", "ajudar", "passar"]
	match evento.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			_selecionar_carta(ids[evento.keycode - KEY_1])
		KEY_TAB:
			_alternar_quadro()
		KEY_ENTER, KEY_KP_ENTER:
			match _carta_sel:
				"procurar": _procurar()
				"facilitar": _facilitar()
				"ajudar": _ajudar()
				"passar": _passar()
		KEY_ESCAPE:
			_carta_sel = ""
			for k in _cartas:
				_cartas[k].selecionada = false
				_cartas[k]._subir(false)
			_bilhete.visible = false
		_:
			return
	get_viewport().set_input_as_handled()


## Troca o ponto de interesse sem o mouse (controles).
func _proximo_ponto() -> void:
	if cena.pontos_restantes.is_empty():
		return
	var i := cena.pontos_restantes.find(_ponto)
	_ponto = cena.pontos_restantes[(i + 1) % cena.pontos_restantes.size()]
	_atualizar()


# --- Ações -----------------------------------------------------------------------

func _entrada_3d(evento: InputEvent) -> void:
	if TourGuiado.em_andamento():
		return
	if evento is InputEventMouseMotion:
		_mostrar_dica(_visao.ponto_em(evento.position), evento.position)
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var pid := _visao.ponto_em(evento.position)
		if pid != "" and pid in cena.pontos_restantes:
			_ponto = pid
			_selecionar_carta("procurar")
			_atualizar()
		return
	if _visao.rig.tratar_entrada(evento):
		_vista.accept_event()


## Tooltip em papel sobre o ponto de interesse: nome e as DTs.
func _mostrar_dica(pid: String, pos: Vector2) -> void:
	var pt := cena.ponto(pid) if pid != "" else {}
	_dica.visible = not pt.is_empty()
	if not _dica.visible:
		return
	var linhas: Array[String] = [String(pt.nome)]
	if pid in cena.pontos_restantes:
		for per in pt.pericias:
			linhas.append("%s · DT %d" % [missao.ruleset.pericia(per).nome, int(pt.pericias[per])])
	else:
		linhas.append("(já vasculhado)")
	_dica.text = "\n".join(linhas)
	_dica.reset_size()
	_dica.position = pos + Vector2(18, 12)


func _procurar() -> void:
	var a := cena.agente_atual()
	if a == null or _pericia == "" or _ponto == "":
		return
	var op := {}
	if _selos.get("faro", false) and a.tem_habilidade("faro_para_pistas"):
		op["habilidades"] = ["faro_para_pistas"]
	if _selos.get("perito", false) and _pericia in a.perito:
		op["perito"] = true
	if _selos.get("ecletico", false) and a.classe_id == "especialista":
		op["ecletico"] = true
	var foco := _foco
	_foco = 0
	_enviar("procurar", {"ponto": _ponto, "pericia": _pericia, "foco": foco, "opcoes": op})


func _facilitar() -> void:
	var a := cena.agente_atual()
	if a == null or _opcao_facilitar.is_empty():
		return
	var foco := _foco
	_foco = 0
	_enviar("facilitar", {"opcao": _opcao_facilitar[0], "pericia": _opcao_facilitar[1], "foco": foco,
		"opcoes": {"presteza_atletica": _selos.get("presteza", false) and a.tem_habilidade("presteza_atletica")}})


func _ajudar() -> void:
	if _aliado == null or _pericia_ajuda == "":
		return
	_enviar("ajudar", {"aliado": Comandos.indice_na_cena(cena, _aliado), "pericia": _pericia_ajuda, "espirito_civico": true})


func _passar() -> void:
	_enviar("passar")


func _sair() -> void:
	_enviar("encerrar")


func _usar_extra(hab: String) -> void:
	_enviar("acao_extra", {"habilidade": hab})


func _trilha_certa(a: Agente) -> void:
	_enviar("trilha_certa", {"agente": Comandos.indice_na_cena(cena, a)})


func _voltar() -> void:
	if _jogo != null and _jogo.missao == missao:
		_enviar("sair")
	else:
		get_tree().reload_current_scene()


# --- Comandos (ADR 0007) ------------------------------------------------------

func _enviar(acao: String, args: Dictionary = {}) -> Dictionary:
	return sessao.enviar(Comandos.novo("investigacao", acao, args))


## Aplica um comando da cena (deste jogador ou, online, de outro) e atualiza a tela.
func _aplicar_comando(cmd: Dictionary) -> Dictionary:
	var res := Comandos.aplicar_investigacao(cena, cmd)
	match String(cmd.get("acao", "")):
		"procurar":
			if not res.ok:
				_log.append_text(Tema.bb("Não dá para fazer esse teste (treino, PE ou habilidade).", Tema.AVISO) + "\n")
			elif String(res.teste.get("pista", "")) != "":
				Tema.pulso_vhs(_vista, 0.8, 0.6)   # o paranormal "aparece" na fita
				if not _quadro_aberto:
					_alternar_quadro()
			elif not res.teste.get("sucesso", true):
				Tema.pulso_vhs(_vista, 0.35, 0.3)
		"facilitar":
			if not res.ok:
				_log.append_text(Tema.bb("Não dá para fazer esse teste.", Tema.AVISO) + "\n")
			elif res.teste.get("sucesso", false):
				_visao.iluminar()
		"ajudar":
			if not res.ok:
				_log.append_text(Tema.bb("Não dá para ajudar agora.", Tema.AVISO) + "\n")
		"sair":
			if res.ok and _jogo != null:
				_jogo.voltar_da_investigacao(res.resultado)
			return res
	_atualizar()
	return res


func _exit_tree() -> void:
	if sessao != null:
		sessao.sair("investigacao")
		if sessao.comando_aplicado.is_connected(_ao_comando_aplicado):
			sessao.comando_aplicado.disconnect(_ao_comando_aplicado)


## Comandos do mestre chegam em qualquer tela; aqui, a narração vai para o registro.
func _ao_comando_aplicado(cmd: Dictionary, res: Dictionary) -> void:
	if String(cmd.get("ctx", "")) != "mestre":
		return
	if cmd.get("acao", "") == "narrar" and res.get("ok", false):
		_log.append_text(Tema.bb("[b]Mestre:[/b] %s" % res.texto, Tema.MESTRE) + "\n")
	_atualizar()


## Cantos de enquadramento de câmera (found footage).
class _Enquadramento:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var m := 18.0
		var l := 36.0
		var c := Color(Tema.PERGAMINHO, 0.55)
		for canto in [Vector2(m, m), Vector2(size.x - m, m), Vector2(m, size.y - m), Vector2(size.x - m, size.y - m)]:
			var sx := 1.0 if canto.x < size.x / 2.0 else -1.0
			var sy := 1.0 if canto.y < size.y / 2.0 else -1.0
			draw_line(canto, canto + Vector2(l * sx, 0), c, 2.0)
			draw_line(canto, canto + Vector2(0, l * sy), c, 2.0)


## Marcas de contagem da urgência: um traço por rodada; as que já passaram ficam riscadas.
class _FitaUrgencia:
	extends Control

	var total := 4
	var usadas := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func definir(p_total: int, p_usadas: int) -> void:
		total = p_total
		usadas = clampi(p_usadas, 0, p_total)
		custom_minimum_size = Vector2(total * 12 + 8, 22)
		queue_redraw()

	func _draw() -> void:
		for i in total:
			var x := 4.0 + i * 12.0
			var cor := Color(Tema.PERGAMINHO, 0.4) if i < usadas else Tema.PERGAMINHO
			draw_line(Vector2(x, 3), Vector2(x + 1.5, 19), Color(0, 0, 0, 0.6), 4.0)
			draw_line(Vector2(x, 3), Vector2(x + 1.5, 19), cor, 2.5)
		if usadas > 0:
			draw_line(Vector2(0, 15), Vector2(usadas * 12.0 + 2.0, 6), Tema.PERIGO, 2.5)
