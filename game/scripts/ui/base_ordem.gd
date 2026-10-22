extends Control
## Base da Ordem (hub entre missões) como dossiê (docs/09): abas Agentes, Arsenal, Missão
## e Jogadores. A ficha do agente, o briefing e o relatório da última missão são folhas de
## papel; o resto é a mesa escura da Ordem.

var carreira: Carreira
var _jogo: Node
var _selecionado: Agente

var _lista: ItemList
var _abas: TabContainer
var _ficha_agente: FichaAgente   ## a ficha no formato da oficial (docs/25)
var _papel_pendencia: PanelContainer
var _opt_recruta: OptionButton
var _caixa_pendencia: VBoxContainer
var _caixa_requisicao: VBoxContainer
## Arsenal por agente (docs/64): a lista de quem se equipa, as cotas e a carga
var _lista_arsenal: VBoxContainer
var _cotas_arsenal: HBoxContainer
var _barra_carga: ProgressBar
var _lbl_carga: Label
var _lbl_aviso_arsenal: Label
var _cabecalhos_cat: Dictionary = {}   ## categoria -> Label
var _fluxos_cat: Dictionary = {}       ## categoria -> HFlowContainer das etiquetas
var _checks_itens: Dictionary = {}     ## item_id -> Button (etiqueta que liga e desliga)
## O catálogo do livro (docs/67) passa de cem itens: o arsenal mostra um grupo por vez
const GRUPOS_ARSENAL := [["arma", "Armas"], ["municao", "Munição"], ["protecao", "Proteções"], ["acessorio", "Acessórios"],
	["explosivo", "Explosivos"], ["operacional", "Operacionais"], ["paranormal", "Paranormais"], ["amaldicoado", "Amaldiçoados"],
	["contra_criatura", "Contra criaturas"], ["requisitado", "Na requisição"]]
var _filtro_arsenal := "arma"
var _botoes_filtro: Dictionary = {}   ## grupo -> Button do filtro
var _opt_arma: OptionButton
var _lbl_requisicao: Label
var _caixa_grupo: VBoxContainer
var _checks_grupo: Dictionary = {}     ## Agente -> CheckBox
var _donos_grupo: Dictionary = {}      ## Agente -> OptionButton (dono no co-op local)
var _caixa_jogadores: VBoxContainer
var _caixa_online: VBoxContainer
var _aba_memorial: ScrollContainer
var _aba_planta: Control
## A Base como lugar (docs/65): a sala 3D, o aviso da seção e o bilhete do serviço
var _sala_base: SalaBase
var _agente_na_sala: Agente
var _aviso_estacao: PanelContainer
var _lbl_estacao: Label
var _bilhete_servico: PanelContainer
var _servico_aberto := ""
var _opt_interrogador: OptionButton
var _lbl_servico: Label   ## o que a última sala fez (laboratório, contenção)
var _memorial_visto := -1   ## quantas entradas a parede mostra (só remonta quando muda)
var _txt_porta: LineEdit
var _txt_endereco: LineEdit
var _txt_nome: LineEdit
var _opt_missao: OptionButton
var _txt_missao: RichTextLabel
## Uma entrada por item da lista de missões: {tipo: "procedural"|"campanha"|"comunidade", definicao, erros}
var _opcoes_missao: Array[Dictionary] = []
var _opt_modo: OptionButton
var _chk_lesoes: CheckBox
var _chk_inspiracao: CheckBox
var _lbl_erros: Label
var _btn_iniciar: Button
var _btn_continuar: Button
var _relatorio: RichTextLabel


## Uma escolha de NEX foi aplicada (a sala de Transcender redesenha o papel dela).
signal pendencias_mudaram(agente: Agente, erros: Array)

## Semente da próxima missão procedural: o briefing mostra a região que ela gera e o
## "Iniciar missão" usa a mesma (docs/23, C7).
var semente_proxima := randi() % 1000000
## Os sinais da rede (docs/62, OR1): três casos possíveis, um de cada confiança. Escolher um
## troca a semente da próxima missão (e o briefing).
var sinais: Array = []
var sinal_escolhido := 0
var _caixa_sinais: VBoxContainer
var _botoes_sinais: Array[Button] = []


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	carreira = _jogo.carregar_ou_criar() if _jogo != null else Carreira.nova()
	sinais = Sinais.gerar(semente_proxima)
	semente_proxima = int(sinais[0].semente)
	_montar_interface()
	if not carreira.roster.is_empty():
		_selecionado = carreira.roster[0]
	_atualizar_tudo()
	_montar_memorial()
	_montar_planta()
	# E5 (docs/16): a Base abre na aba Missão, onde se monta o grupo e se começa a jogar.
	# Se algum agente tem escolha de NEX pendente, abre na aba Agentes, nele.
	ir_para_aba("Missão")
	for a in carreira.roster:
		if not Progressao.pendencias(a).is_empty():
			ir_para_aba("Agentes")
			_selecionado = a
			_atualizar_tudo()
			break
	if _jogo != null:
		_jogo.jogadores_mudaram.connect(_ao_mudar_jogadores)
		if _jogo.aviso_rede != "":
			_lbl_erros.text = _jogo.aviso_rede
			_jogo.aviso_rede = ""
	# Cerimônia de NEX e patente (docs/23, C7), uma vez por missão
	if CerimoniaNex.tem_o_que_mostrar(carreira.ultimo_relatorio):
		var cerimonia := CerimoniaNex.abrir(self, carreira)
		cerimonia.transcender.connect(func(a: Agente): Transcender.abrir(self, a))
		_salvar()
	# Tutorial (docs/07-tutorial.md): convite ao abrir o jogo e o "?" desta tela
	Tutorial.botao_ajuda(self, "base", _alvos_do_tutorial)
	if Tutorial.convidar(self, func(): Tutorial.abrir("base", self, _alvos_do_tutorial())) == null:
		Tutorial.ao_entrar("base", self, _alvos_do_tutorial())


func _alvos_do_tutorial() -> Dictionary:
	return {"agentes": _lista, "ficha": _ficha_agente, "requisicao": _caixa_requisicao.get_parent(), "grupo": _caixa_grupo,
		"jogadores": _caixa_jogadores, "missao": _opt_missao, "iniciar": _btn_iniciar}


# --- Montagem ------------------------------------------------------------------

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Tema.fundo())
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 18)
	margem.add_theme_constant_override("margin_right", 18)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_bottom", 14)
	add_child(margem)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", Tema.ESPACO_M)
	margem.add_child(corpo)

	# Cabeçalho: sigilo, título e atalhos
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", Tema.ESPACO_G)
	corpo.add_child(cab)
	var sig := Sigilo.new()
	sig.semente = 1987
	sig.cor = Tema.SANGUE_CLARO
	sig.espessura = 2.2
	sig.custom_minimum_size = Vector2(46, 46)
	cab.add_child(sig)
	var vt := VBoxContainer.new()
	vt.add_theme_constant_override("separation", 0)
	cab.add_child(vt)
	var t := _titulo("Base da Ordem", 20)
	vt.add_child(t)
	var sub := Label.new()
	sub.text = "Arquivo de agentes · uso restrito"
	sub.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	sub.add_theme_font_size_override("font_size", Tema.FONTE_P)
	vt.add_child(sub)
	var vazio := Control.new()
	vazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(vazio)
	cab.add_child(_botao("Menu principal", func(): get_tree().change_scene_to_file.call_deferred("res://scenes/titulo.tscn")))
	var lugar_ajuda := Control.new()   # o botão "?" do tutorial fica no canto
	lugar_ajuda.custom_minimum_size = Vector2(44, 0)
	cab.add_child(lugar_ajuda)

	_abas = TabContainer.new()
	_abas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(_abas)

	# --- Aba Base (docs/63, docs/65): o bar de fachada em 3D, com as salas da Ordem nos fundos
	_aba_planta = Control.new()
	_aba_planta.name = "Base"
	_aba_planta.clip_contents = true
	_abas.add_child(_aba_planta)

	# --- Aba Agentes: pastas à esquerda, a ficha como documento à direita
	var agentes := HBoxContainer.new()
	agentes.name = "Agentes"
	agentes.add_theme_constant_override("separation", Tema.ESPACO_GG)
	_abas.add_child(agentes)
	var c1 := VBoxContainer.new()
	c1.custom_minimum_size = Vector2(300, 0)
	c1.add_theme_constant_override("separation", Tema.ESPACO_M)
	agentes.add_child(c1)
	c1.add_child(_titulo("Pastas de agentes"))
	_lista = ItemList.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.item_selected.connect(_ao_selecionar)
	c1.add_child(_lista)
	var linha_rec := HBoxContainer.new()
	_opt_recruta = OptionButton.new()
	_opt_recruta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_rec.add_child(_opt_recruta)
	var recrutar := _botao("Recrutar pronto", _recrutar)
	recrutar.tooltip_text = "Traz um agente com a ficha já feita. Para montar a ficha você mesmo, use \"Criar ficha de agente\"."
	linha_rec.add_child(recrutar)
	c1.add_child(linha_rec)
	# E2 (docs/17): criar o próprio agente, ficha por ficha
	var novo := _botao("+ Criar ficha de agente", _criar_agente)
	novo.theme_type_variation = "BotaoPrincipal"
	c1.add_child(novo)
	var doc := VBoxContainer.new()
	doc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc.add_theme_constant_override("separation", Tema.ESPACO_M)
	agentes.add_child(doc)
	# Ficha no formato da ficha oficial (docs/25): Agente, Habilidades e inventário, Rituais
	_ficha_agente = FichaAgente.new()
	_ficha_agente.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ficha_agente.editavel = true   # "Editar descrição" na página 2 (docs/27)
	_ficha_agente.descricao_editada.connect(_salvar)
	doc.add_child(_ficha_agente)
	# Escolhas de NEX pendentes: um bilhete abaixo da ficha, só quando há o que escolher
	_papel_pendencia = _papel(false)
	_papel_pendencia.visible = false
	doc.add_child(_papel_pendencia)
	_caixa_pendencia = VBoxContainer.new()
	_caixa_pendencia.theme = Tema.tema_papel()
	_papel_pendencia.add_child(_caixa_pendencia)

	# --- Aba Arsenal (docs/64): a requisição de cada agente, pela patente e pela carga (p.61-63)
	var arsenal := HBoxContainer.new()
	arsenal.name = "Arsenal"
	arsenal.add_theme_constant_override("separation", Tema.ESPACO_GG)
	_abas.add_child(arsenal)
	var esquerda_a := VBoxContainer.new()
	esquerda_a.custom_minimum_size = Vector2(240, 0)
	esquerda_a.add_theme_constant_override("separation", Tema.ESPACO_P)
	arsenal.add_child(esquerda_a)
	esquerda_a.add_child(_titulo("Quem se equipa"))
	_lista_arsenal = VBoxContainer.new()
	_lista_arsenal.add_theme_constant_override("separation", Tema.ESPACO_P)
	esquerda_a.add_child(_lista_arsenal)
	var direita_a := VBoxContainer.new()
	direita_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	direita_a.add_theme_constant_override("separation", Tema.ESPACO_P)
	arsenal.add_child(direita_a)
	_lbl_requisicao = Label.new()
	_lbl_requisicao.theme_type_variation = "Subtitulo"
	direita_a.add_child(_lbl_requisicao)
	_cotas_arsenal = HBoxContainer.new()
	_cotas_arsenal.add_theme_constant_override("separation", Tema.ESPACO_M)
	direita_a.add_child(_cotas_arsenal)
	var linha_carga := HBoxContainer.new()
	linha_carga.add_theme_constant_override("separation", Tema.ESPACO_M)
	direita_a.add_child(linha_carga)
	_barra_carga = ProgressBar.new()
	_barra_carga.show_percentage = false
	_barra_carga.custom_minimum_size = Vector2(300, 14)
	_barra_carga.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha_carga.add_child(_barra_carga)
	_lbl_carga = Label.new()
	linha_carga.add_child(_lbl_carga)
	var linha_arma := HBoxContainer.new()
	linha_arma.add_theme_constant_override("separation", Tema.ESPACO_M)
	direita_a.add_child(linha_arma)
	var lbl := Label.new()
	lbl.text = "Arma empunhada:"
	linha_arma.add_child(lbl)
	_opt_arma = OptionButton.new()
	_opt_arma.custom_minimum_size = Vector2(240, 0)
	_opt_arma.item_selected.connect(func(_i): _aplicar_requisicao(_selecionado.equipamento.duplicate() if _selecionado != null else []))
	linha_arma.add_child(_opt_arma)
	_lbl_aviso_arsenal = Label.new()
	_lbl_aviso_arsenal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_aviso_arsenal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_aviso_arsenal.add_theme_color_override("font_color", Tema.AVISO)
	linha_arma.add_child(_lbl_aviso_arsenal)
	var filtros := HFlowContainer.new()
	filtros.add_theme_constant_override("h_separation", Tema.ESPACO_P)
	direita_a.add_child(filtros)
	var grupo_filtros := ButtonGroup.new()
	for g in GRUPOS_ARSENAL:
		var fb := Button.new()
		fb.toggle_mode = true
		fb.button_group = grupo_filtros
		fb.text = g[1]
		fb.button_pressed = g[0] == _filtro_arsenal
		fb.pressed.connect(func():
			_filtro_arsenal = g[0]
			_atualizar_arsenal())
		filtros.add_child(fb)
		_botoes_filtro[g[0]] = fb
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_caixa_requisicao = VBoxContainer.new()
	_caixa_requisicao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caixa_requisicao.add_theme_constant_override("separation", Tema.ESPACO_P)
	rolagem.add_child(_caixa_requisicao)
	direita_a.add_child(rolagem)
	# Os itens por categoria (p.63): a 0 é livre; as outras, pela patente
	var catalogo := _catalogo()
	for cat in 5:
		var do_cat := catalogo.filter(func(it): return clampi(int(it.get("categoria", 0)), 0, 4) == cat)
		if do_cat.is_empty():
			continue
		var cab_cat := Label.new()
		cab_cat.theme_type_variation = "Subtitulo"
		_caixa_requisicao.add_child(cab_cat)
		_cabecalhos_cat[cat] = cab_cat
		var fluxo := HFlowContainer.new()
		fluxo.add_theme_constant_override("h_separation", Tema.ESPACO_M)
		fluxo.add_theme_constant_override("v_separation", Tema.ESPACO_P)
		_caixa_requisicao.add_child(fluxo)
		_fluxos_cat[cat] = fluxo
		for item in do_cat:
			var chk := _etiqueta_item(item)
			var id := String(item.id)
			chk.toggled.connect(func(v): _marcar_item(id, v))
			chk.set_meta("grupo", _grupo_do_item(item))
			chk.set_meta("texto", chk.text)
			if Ruleset.empilhavel(item):
				_botoes_quantidade(chk, id)
			_checks_itens[id] = chk
			fluxo.add_child(chk)

	# --- Aba Missão: grupo e opções à esquerda; o briefing e o relatório em papel
	var missao_aba := HBoxContainer.new()
	missao_aba.name = "Missão"
	missao_aba.add_theme_constant_override("separation", Tema.ESPACO_GG)
	_abas.add_child(missao_aba)
	var rolagem_m := ScrollContainer.new()
	rolagem_m.custom_minimum_size = Vector2(380, 0)
	rolagem_m.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	missao_aba.add_child(rolagem_m)
	var c3 := VBoxContainer.new()
	c3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c3.add_theme_constant_override("separation", Tema.ESPACO_M)
	rolagem_m.add_child(c3)
	c3.add_child(_titulo("Grupo da missão (até 4)"))
	_caixa_grupo = VBoxContainer.new()
	c3.add_child(_caixa_grupo)
	c3.add_child(_titulo("Missão"))
	_opt_missao = OptionButton.new()
	_opt_missao.clip_text = true
	_opt_missao.item_selected.connect(func(_i): _mostrar_missao())
	c3.add_child(_opt_missao)
	# Os sinais da rede (docs/62): só na missão procedural
	_caixa_sinais = VBoxContainer.new()
	_caixa_sinais.add_theme_constant_override("separation", Tema.ESPACO_P)
	c3.add_child(_caixa_sinais)
	_caixa_sinais.add_child(_titulo("Sinais da rede"))
	var grupo_sinais := ButtonGroup.new()
	for i in sinais.size():
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = grupo_sinais
		b.button_pressed = i == sinal_escolhido
		b.text = Sinais.resumo(sinais[i])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(340, 0)
		b.tooltip_text = "Confiança %s: %s" % [sinais[i].rotulo, {"baixa": "pode ser alarme falso; se for real, rende mais prestígio.",
			"media": "às vezes é alarme falso.", "alta": "a Ordem tem certeza: é paranormal."}.get(String(sinais[i].confianca), "")]
		b.pressed.connect(func(): _escolher_sinal(i))
		_caixa_sinais.add_child(b)
		_botoes_sinais.append(b)
	c3.add_child(_titulo("Regras opcionais"))
	_opt_modo = OptionButton.new()
	_opt_modo.add_item("Normal (2 Reforços da Ordem)")
	_opt_modo.add_item("Hardcore (morte permanente)")
	_opt_modo.tooltip_text = "Normal: quem cai pode ser salvo por um Reforço da Ordem.\nHardcore: quem morre, morre."
	_opt_modo.item_selected.connect(func(i): carreira.opcoes.modo_morte = "normal" if i == 0 else "hardcore")
	c3.add_child(_opt_modo)
	_chk_lesoes = CheckBox.new()
	_chk_lesoes.text = "Lesões"
	_chk_lesoes.tooltip_text = "Quem fica morrendo por dois turnos testa Vigor; se falhar, perde um ponto de atributo para sempre."
	_chk_lesoes.toggled.connect(func(v): carreira.opcoes.lesoes = v)
	c3.add_child(_chk_lesoes)
	_chk_inspiracao = CheckBox.new()
	_chk_inspiracao.text = "Inspiração Resoluta"
	_chk_inspiracao.tooltip_text = "Quem morre em combate ainda inspira o grupo: a cada rodada, um aliado recebe um efeito sorteado."
	_chk_inspiracao.toggled.connect(func(v): carreira.opcoes.inspiracao_resoluta = v)
	c3.add_child(_chk_inspiracao)
	c3.add_child(_botao("Editor de missões", _abrir_editor))
	var direita := VBoxContainer.new()
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	direita.add_theme_constant_override("separation", Tema.ESPACO_G)
	missao_aba.add_child(direita)
	var briefing := _papel(false)
	briefing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	direita.add_child(briefing)
	var vb := VBoxContainer.new()
	briefing.add_child(vb)
	var tb := Label.new()
	tb.text = "BRIEFING"
	tb.theme_type_variation = "TextoPapel"
	var fonte := Tema.fonte_titulo()
	if fonte != null:
		tb.add_theme_font_override("font", fonte)
	vb.add_child(tb)
	_txt_missao = RichTextLabel.new()
	_txt_missao.bbcode_enabled = true
	_txt_missao.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_txt_missao.add_theme_color_override("default_color", Tema.TINTA)
	vb.add_child(_txt_missao)
	var acoes := HBoxContainer.new()
	acoes.add_theme_constant_override("separation", Tema.ESPACO_M)
	acoes.alignment = BoxContainer.ALIGNMENT_END
	direita.add_child(acoes)
	_lbl_erros = Label.new()
	_lbl_erros.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_erros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_erros.add_theme_color_override("font_color", Tema.PERIGO)
	acoes.add_child(_lbl_erros)
	_btn_continuar = _botao("Continuar missão em andamento", _continuar)
	acoes.add_child(_btn_continuar)
	_btn_iniciar = _botao("Iniciar missão", _iniciar)
	_btn_iniciar.theme_type_variation = "BotaoPrincipal"
	acoes.add_child(_btn_iniciar)
	var rel := _papel(false)
	rel.custom_minimum_size = Vector2(0, 150)
	direita.add_child(rel)
	var vr := VBoxContainer.new()
	rel.add_child(vr)
	var tr := Label.new()
	tr.text = "RELATÓRIO DA ÚLTIMA MISSÃO"
	tr.theme_type_variation = "TextoPapel"
	if fonte != null:
		tr.add_theme_font_override("font", fonte)
	vr.add_child(tr)
	_relatorio = RichTextLabel.new()
	_relatorio.bbcode_enabled = true
	_relatorio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_relatorio.add_theme_color_override("default_color", Tema.TINTA)
	vr.add_child(_relatorio)

	# --- Aba Jogadores: co-op local, online e preferências
	var jog := ScrollContainer.new()
	jog.name = "Jogadores"
	jog.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_abas.add_child(jog)
	var cj := VBoxContainer.new()
	cj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cj.add_theme_constant_override("separation", Tema.ESPACO_M)
	jog.add_child(cj)
	cj.add_child(_titulo("Jogadores (co-op local e online)"))
	# --- Aba Memorial (docs/59): a parede de memória; montada em _montar_memorial
	_aba_memorial = ScrollContainer.new()
	_aba_memorial.name = "Memorial"
	_aba_memorial.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_abas.add_child(_aba_memorial)   # a última aba, depois de Jogadores
	_caixa_jogadores = VBoxContainer.new()
	cj.add_child(_caixa_jogadores)
	cj.add_child(_titulo("Online"))
	_caixa_online = VBoxContainer.new()
	cj.add_child(_caixa_online)
	cj.add_child(_titulo("Preferências"))
	var chk_tutorial := CheckBox.new()
	chk_tutorial.text = "Perguntar sobre o tutorial ao abrir o jogo"
	chk_tutorial.button_pressed = Preferencias.perguntar_tutorial()
	chk_tutorial.toggled.connect(func(v): Preferencias.definir_perguntar_tutorial(v))
	cj.add_child(chk_tutorial)
	cj.add_child(_titulo("Leitura e acessibilidade"))
	var leitura := VBoxContainer.new()
	leitura.add_theme_constant_override("separation", Tema.ESPACO_P)
	leitura.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cj.add_child(leitura)
	MenuPausa.montar_leitura(leitura)   # os mesmos ajustes da pausa (docs/16, A1 e A3)
	cj.add_child(_titulo("Zona de perigo"))   # ação destrutiva separada das preferências (docs/21)
	var apagar := _botao("Nova carreira (apaga o save)", func():
		DialogoPapel.perguntar(self, "Nova carreira", "Isso apaga o save atual: agentes, memorial e a missão em andamento. Não dá para desfazer.", "Apagar e começar", _nova_carreira))
	apagar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cj.add_child(apagar)


## Etiqueta de evidência (Arsenal, docs/12): um cartão de papel que liga e desliga.
## Categoria e espaços como carimbo; itens amaldiçoados com ☠ e borda vermelha.
func _etiqueta_item(item: Dictionary) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(372, 76)   # três por linha, nome inteiro em até duas linhas (docs/23)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var amaldicoado := item.has("maldicoes")
	var papel := Tema.caixa_papel(Vector2(12, 8))
	papel.content_margin_left = 58   # espaço do ícone
	var marcado := Tema.caixa_papel(Vector2(12, 8))
	marcado.content_margin_left = 58
	marcado.modulate_color = Color(1.0, 0.93, 0.85)
	for estado in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(estado, papel)
	for estado in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(estado, marcado)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for cor in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(cor, Tema.SANGUE if amaldicoado else Tema.TINTA)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		b.add_theme_font_override("font", maquina)
	b.add_theme_font_size_override("font_size", Tema.FONTE_P)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	var cat: String = ["0", "I", "II", "III", "IV", "V"][mini(5, int(item.get("categoria", 0)))]
	var resumo := IconeItem.resumo(item, carreira.ruleset)
	b.text = "%s%s
cat. %s · %d esp.%s" % ["☠ " if amaldicoado else "", item.nome, cat, int(item.get("espacos", 1)), (" · " + resumo) if resumo != "" else ""]
	var efeito := IconeItem.efeito(item, carreira.ruleset)
	if amaldicoado:
		b.tooltip_text = "%s\nMaldições: %s" % [efeito, ", ".join(PackedStringArray(item.maldicoes.map(func(m): return "%s (%s) — %s" % [m.nome, m.elemento, m.descricao])))]
	else:
		b.tooltip_text = "%s — categoria %s, %d espaço(s)\n%s" % [item.nome, cat, int(item.get("espacos", 1)), efeito]
	var icone := IconeItem.tipo(item)
	b.set_meta("icone", icone)
	# Carimbo "REQUISITADO" quando marcado
	var carimbo := Label.new()
	carimbo.text = "REQUISITADO"
	carimbo.add_theme_color_override("font_color", Color(Tema.SANGUE_CLARO, 0.85))
	carimbo.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), Color(Tema.SANGUE_CLARO, 0.8), 2, 2, Vector2(4, 0)))
	carimbo.add_theme_font_size_override("font_size", 11)
	var titulo := Tema.fonte_titulo()
	if titulo != null:
		carimbo.add_theme_font_override("font", titulo)
	carimbo.position = Vector2(250, 48) if Ruleset.empilhavel(item) else Vector2(250, 40)   # longe do − e +
	carimbo.rotation_degrees = -8
	carimbo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carimbo.visible = false
	b.add_child(carimbo)
	# No draw (e não no toggled): a Base marca as etiquetas com set_pressed_no_signal
	b.draw.connect(func():
		carimbo.visible = b.button_pressed
		IconeItem.desenhar(b, icone, Vector2(30, b.size.y / 2.0), 17.0, Tema.SANGUE if amaldicoado else Color(Tema.TINTA, 0.85))
		b.draw_line(Vector2(54, 10), Vector2(54, b.size.y - 10), Color(Tema.TINTA, 0.25), 1.0)
		if amaldicoado:
			b.draw_rect(Rect2(Vector2(1, 1), b.size - Vector2(2, 2)), Color(Tema.SANGUE_CLARO, 0.8), false, 2.0))
	return b


## Folha de papel (dossiê). `carimbo` põe "CONFIDENCIAL" no canto.
func _papel(carimbo: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = Tema.tema_papel()
	p.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(22, 18)))
	if carimbo:
		var c := Label.new()
		c.text = "CONFIDENCIAL"
		c.add_theme_color_override("font_color", Color(Tema.SANGUE_CLARO, 0.75))
		c.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), Color(Tema.SANGUE_CLARO, 0.7), 2, 3, Vector2(8, 2)))
		var f := Tema.fonte_titulo()
		if f != null:
			c.add_theme_font_override("font", f)
		c.rotation_degrees = 8
		c.size_flags_horizontal = Control.SIZE_SHRINK_END
		c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(c)
	return p


func _coluna(pai: Control, largura: int, com_painel: bool = true) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(largura, 0)
	v.add_theme_constant_override("separation", 6)
	pai.add_child(Tema.painel(v) if com_painel else v)
	return v


func _titulo(texto: String, tamanho: int = 14) -> Label:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = "Titulo" if tamanho > 14 else "Subtitulo"
	if tamanho > 14:
		l.add_theme_font_size_override("font_size", tamanho + 6)
	return l


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	return b


func _grupo_do_item(item: Dictionary) -> String:
	if item.has("maldicoes"):
		return "amaldicoado"
	if String(item.get("tipo", "")) in ["arma", "protecao"]:
		return String(item.tipo)
	return String(item.get("grupo", "operacional"))


## "−" e "+" na etiqueta de munição, granadas e caixas: mais de uma unidade (p.69).
func _botoes_quantidade(etiqueta: Button, item_id: String) -> void:
	var linha := HBoxContainer.new()
	linha.name = "Quantidade"
	linha.add_theme_constant_override("separation", 2)
	linha.position = Vector2(300, 6)
	for par in [["−", -1], ["+", 1]]:
		var b := Button.new()
		b.text = par[0]
		b.custom_minimum_size = Vector2(28, 24)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "Uma unidade a menos" if par[1] < 0 else "Mais uma unidade (conta na cota e na carga)"
		var delta: int = par[1]
		b.pressed.connect(func(): _mudar_quantidade(item_id, delta))
		linha.add_child(b)
	linha.visible = false
	etiqueta.add_child(linha)


func _mudar_quantidade(item_id: String, delta: int) -> void:
	if _selecionado == null:
		return
	var lista: Array = _selecionado.equipamento.duplicate()
	if delta > 0:
		var motivo := _selecionado.motivo_bloqueio(item_id, lista, true)
		if motivo != "":
			_lbl_aviso_arsenal.text = motivo
			return
		lista.append(item_id)
	else:
		lista.erase(item_id)
	_aplicar_requisicao(lista)


func _catalogo() -> Array:
	var rs := carreira.ruleset
	var lista: Array = []
	for a in rs.lista_armas():
		lista.append(rs.equipamento(a.id))
	for p in rs.protecoes():
		lista.append(rs.equipamento(p.id))
	for i in rs.itens_gerais():
		lista.append(rs.equipamento(i.id))
	for am in rs.lista_amaldicoados():
		lista.append(rs.equipamento(am.id))   # itens amaldiçoados: a partir de Agente Especial
	return lista


# --- Atualização -----------------------------------------------------------------

func _atualizar_tudo() -> void:
	_lista.clear()
	for a in carreira.roster:
		var pend := Progressao.pendencias(a).size()
		_lista.add_item("%s — %s, NEX %d%%%s" % [a.nome, a.patente().get("nome", "?"), a.nex, "  (!)" if pend > 0 else ""])
	if _selecionado != null and _selecionado in carreira.roster:
		_lista.select(carreira.roster.find(_selecionado))
	_opt_recruta.clear()
	for r in carreira.recrutas_disponiveis():
		_opt_recruta.add_item("%s (%s)" % [r.nome, r.classe])
		_opt_recruta.set_item_metadata(_opt_recruta.item_count - 1, r.nome)
	# Grupo
	for filho in _caixa_grupo.get_children():
		filho.queue_free()
	_checks_grupo.clear()
	_donos_grupo.clear()
	var ctl := carreira.controles
	for a in carreira.roster:
		var linha := HBoxContainer.new()
		var chk := CheckBox.new()
		chk.text = a.nome
		chk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chk.button_pressed = _checks_grupo.size() < 3
		_checks_grupo[a] = chk
		linha.add_child(chk)
		var dono := OptionButton.new()
		for j in ctl.jogadores.size():
			dono.add_item("Jogador %d" % (j + 1))
		dono.select(ctl.jogador_de(a))
		dono.item_selected.connect(_definir_dono.bind(a))
		dono.visible = ctl.co_op()
		_donos_grupo[a] = dono
		linha.add_child(dono)
		_caixa_grupo.add_child(linha)
	_montar_jogadores()
	_montar_online()
	_listar_missoes()
	_opt_modo.select(0 if carreira.opcoes.get("modo_morte", "normal") == "normal" else 1)
	_chk_lesoes.set_pressed_no_signal(carreira.opcoes.get("lesoes", true))
	_chk_inspiracao.set_pressed_no_signal(carreira.opcoes.get("inspiracao_resoluta", true))
	var em_missao := carreira.missao != null
	_btn_continuar.visible = em_missao
	_btn_iniciar.disabled = em_missao
	_lbl_erros.text = "Há uma missão em andamento." if em_missao else ""
	_mostrar_relatorio()
	_atualizar_agente()


func _atualizar_agente() -> void:
	var a := _selecionado
	if a == null:
		_ficha_agente.mostrar(null)
		return
	_ficha_agente.mostrar(a)
	_atualizar_arsenal()
	_montar_pendencia(a)


func _atualizar_armas_requisicao() -> void:
	var atual := _selecionado.arma_id if _selecionado != null else ""
	_opt_arma.clear()
	_opt_arma.add_item("Desarmado")
	_opt_arma.set_item_metadata(0, "")
	for item_id in _checks_itens:
		if _selecionado != null and item_id in _selecionado.equipamento and carreira.ruleset.equipamento(item_id).tipo == "arma":
			_opt_arma.add_item(carreira.ruleset.equipamento(item_id).nome)
			_opt_arma.set_item_metadata(_opt_arma.item_count - 1, item_id)
			if item_id == atual:
				_opt_arma.select(_opt_arma.item_count - 1)


## Escolhas de NEX pendentes. `caixa`: onde montar (a Base, ou o papel da sala de
## Transcender, docs/31). Na Base, um botão leva à sala.
func _montar_pendencia(a: Agente, caixa: VBoxContainer = null) -> void:
	var na_base := caixa == null
	if na_base:
		caixa = _caixa_pendencia
	for filho in caixa.get_children():
		filho.queue_free()
	var pend := Progressao.pendencias(a)
	if na_base:
		_papel_pendencia.visible = not pend.is_empty()
	if pend.is_empty():
		return
	if na_base and _jogo != null:
		var sala := _botao("✦ Transcender na sala de %s" % a.nome, func(): Transcender.abrir(self, a))
		sala.theme_type_variation = "BotaoPrincipal"
		sala.tooltip_text = "Entre na sala do agente, ande até o sigilo (WASD) e faça as escolhas do novo NEX ali."
		caixa.add_child(sala)
	var p: Dictionary = pend[0]
	var titulos := {"trilha": "Escolha a trilha (NEX 10%)", "poder": "Escolha um poder de classe", "aumento": "Aumente um atributo", "ritual": "Aprenda um ritual",
		"poder_paranormal": "Escolha um poder paranormal", "afinidade": "Elemento da afinidade (NEX 50%): ela se firma no próximo Transcender",
		"grau": "Grau de Treinamento: escolha %d perícias" % int(p.get("quantidade", 0)), "versatilidade": "Versatilidade (NEX 50%)"}
	var lbl := _titulo("[%d pendente(s)] %s" % [pend.size(), titulos[p.tipo]])
	lbl.add_theme_color_override("font_color", Tema.SANGUE)
	caixa.add_child(lbl)
	# Tudo por seleção (docs/47): as opções e as escolhas a mais vêm das regras, nada se digita
	caixa.add_child(EscolhaNex.criar(a, p, func(tipo, escolha, extra): _aplicar(a, tipo, escolha, extra), not na_base))


func _aplicar(a: Agente, tipo: String, escolha, extra: Array = []) -> void:
	var erros := Progressao.aplicar(a, tipo, escolha, extra)
	_lbl_requisicao.text = "\n".join(erros) if not erros.is_empty() else "Escolha aplicada."
	_salvar()
	_atualizar_tudo()
	pendencias_mudaram.emit(a, erros)


func _mostrar_relatorio() -> void:
	var r := carreira.ultimo_relatorio
	if r.is_empty():
		_relatorio.text = "Nenhuma missão concluída ainda.\nMemorial: %d agente(s)." % carreira.memorial.size()
		return
	var linhas: Array[String] = ["[b]%s[/b] (missão %d, %d turnos)" % ["Missão cumprida" if r.vitoria else "Missão fracassada", int(r.missao), int(r.turnos)]]
	for l in r.detalhes_pp:
		linhas.append("  " + l)
	for ag in r.agentes:
		var s := "%s: %s" % [ag.nome, ag.situacao]
		if ag.has("pp"):
			s += ", %+d PP, NEX %d%%→%d%%, %s%s" % [int(ag.pp), int(ag.nex_antes), int(ag.nex), ag.patente, " " + Tema.bb("(promovido!)", Tema.cor_sucesso(true)) if ag.promovido else ""]
		linhas.append(s)
	var camp: Dictionary = r.get("campanha", {})
	if not camp.is_empty():
		linhas.append("")
		linhas.append("[b]%s — missão %d de %d[/b]" % [camp.titulo, int(camp.etapa), int(camp.total)])
		var texto := String(camp.get("texto", ""))
		if texto == "" and not camp.vitoria:
			texto = "A missão continua esperando: dá para tentar de novo, com o mesmo grupo ou com outro."
		if texto != "":
			linhas.append("[i]%s[/i]" % texto)
		for t in camp.get("marcas", []):
			linhas.append("[color=#7a5a12]Marca: %s[/color]" % t)
		for nome in camp.get("recrutas", []):
			linhas.append(Tema.bb("%s pode ser recrutado na Base." % nome, Tema.cor_sucesso(true)))
		if camp.get("concluida", false):
			linhas.append("[b]Epílogo[/b]")
			linhas.append("[i]%s[/i]" % camp.get("epilogo", ""))
	if not carreira.memorial.is_empty():
		linhas.append("[color=#6b5a48]Memorial: %s[/color]" % ", ".join(PackedStringArray(carreira.memorial.map(func(m): return m.nome))))
	_relatorio.text = "\n".join(linhas)


# --- Ações ---------------------------------------------------------------------

func _ao_selecionar(i: int) -> void:
	_selecionado = carreira.roster[i]
	_atualizar_agente()


func _criar_agente() -> void:
	if carreira.missao != null:
		_lbl_erros.text = "Termine a missão em andamento antes de criar agentes."
		return
	CriacaoDossie.abrir(self, carreira, func(a: Agente):
		_selecionado = a
		ir_para_aba("Agentes")
		_salvar()
		_atualizar_tudo())


func _recrutar() -> void:
	if _opt_recruta.item_count == 0:
		return
	var a := carreira.recrutar(_opt_recruta.get_item_metadata(_opt_recruta.selected))
	if a != null:
		_selecionado = a
	_salvar()
	_atualizar_tudo()


# --- Arsenal por agente (docs/64) ----------------------------------------------

## Marcar ou desmarcar um item já requisita (o que a regra não deixa nem fica marcável).
func _marcar_item(item_id: String, marcado: bool) -> void:
	if _selecionado == null:
		return
	var lista: Array = _selecionado.equipamento.duplicate()
	if marcado and not item_id in lista:
		var motivo := _selecionado.motivo_bloqueio(item_id, lista)
		if motivo != "":
			_lbl_aviso_arsenal.text = motivo
			_atualizar_arsenal()
			return
		lista.append(item_id)
	elif not marcado:
		while item_id in lista:
			lista.erase(item_id)
	_aplicar_requisicao(lista)


## Requisita a lista com a arma empunhada escolhida (a arma sai se não está mais na lista).
func _aplicar_requisicao(lista: Array) -> void:
	if _selecionado == null:
		return
	var arma: String = String(_opt_arma.get_item_metadata(_opt_arma.selected)) if _opt_arma.selected >= 0 and _opt_arma.get_item_metadata(_opt_arma.selected) != null else ""
	if arma != "" and not arma in lista:
		arma = ""
	if arma == "":
		for i in lista:   # sem arma escolhida, empunha a primeira da lista
			if carreira.ruleset.equipamento(i).get("tipo", "") == "arma":
				arma = String(i)
				break
	var erros := carreira.requisitar(_selecionado, lista, arma)
	_lbl_aviso_arsenal.text = "\n".join(erros)
	_salvar()
	_atualizar_arsenal()


## Redesenha o arsenal do agente escolhido: a lista à esquerda, as cotas da patente, a carga
## e cada item (marcado, livre ou bloqueado, com o motivo na dica).
func _atualizar_arsenal() -> void:
	var a := _selecionado
	for f in _lista_arsenal.get_children():
		f.queue_free()
	for ag in carreira.roster:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = ag == a
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s · %s\n%d/%d espaços" % [ag.nome, ag.patente().get("nome", "?"), ag.espacos_usados(), ag.capacidade_carga()]
		b.pressed.connect(func():
			_selecionado = ag
			_atualizar_tudo())
		_lista_arsenal.add_child(b)
	if a == null:
		return
	var lim: Dictionary = a.patente().get("itens_por_categoria", {})
	_lbl_requisicao.text = "Equipando %s · %s · Força %d" % [a.nome, a.patente().get("nome", "?"), a.atributo("for")]
	for f in _cotas_arsenal.get_children():
		f.queue_free()
	for cat in [1, 2, 3, 4]:
		var limite := int(lim.get(str(cat), 0))
		var usados := a.equipamento.filter(func(i): return int(carreira.ruleset.equipamento(i).get("categoria", 0)) == cat).size()
		var chip := Label.new()
		chip.text = "Cat. %s  %s" % [["", "I", "II", "III", "IV"][cat], ("%d/%d" % [usados, limite]) if limite > 0 else "—"]
		chip.add_theme_stylebox_override("normal", Tema.caixa(Color(Tema.PEDRA, 0.9), Tema.OURO if limite > 0 else Tema.OURO_ESCURO, 1, 4, Vector2(8, 2)))
		chip.add_theme_color_override("font_color", Tema.OURO_CLARO if limite > 0 else Tema.TEXTO_SUAVE)
		chip.tooltip_text = "Categoria %s: a patente %s libera %d por missão (p.62)." % [["", "I", "II", "III", "IV"][cat], a.patente().get("nome", "?"), limite]
		_cotas_arsenal.add_child(chip)
	var cap := a.capacidade_carga()
	var usado := a.espacos_usados()
	var maximo := cap * int(carreira.ruleset.regra_carga().get("maximo_multiplicador", 2))
	_barra_carga.max_value = maximo
	_barra_carga.value = usado
	_barra_carga.modulate = Tema.AVISO if usado > cap else Color.WHITE
	_lbl_carga.text = "%d/%d espaços%s" % [usado, cap, ("  ·  sobrecarregado: −5 Defesa, −3 m (até %d)" % maximo) if usado > cap else ("  ·  sobrecarga até %d" % maximo)]
	for cat in _cabecalhos_cat:
		var limite := int(lim.get(str(cat), 0))
		(_cabecalhos_cat[cat] as Label).text = "Categoria 0 · livre, só conta a carga" if cat == 0 else \
			("Categoria %s · %d por missão" % [["", "I", "II", "III", "IV"][cat], limite] if limite > 0 else "Categoria %s · a patente ainda não libera" % ["", "I", "II", "III", "IV"][cat])
	var visiveis := {}
	for g in _botoes_filtro:
		(_botoes_filtro[g] as Button).set_pressed_no_signal(g == _filtro_arsenal)
	for item_id in _checks_itens:
		var b: Button = _checks_itens[item_id]
		var marcado: bool = item_id in a.equipamento
		var motivo := "" if marcado else a.motivo_bloqueio(item_id, a.equipamento)
		var aviso := a.aviso_item(item_id)
		var qtd := a.equipamento.count(item_id)
		b.visible = String(b.get_meta("grupo", "")) == _filtro_arsenal or (_filtro_arsenal == "requisitado" and marcado)
		if b.visible:
			visiveis[b.get_parent()] = true
		b.text = String(b.get_meta("texto", b.text)) + ("  ×%d" % qtd if qtd > 1 else "")
		var botoes := b.get_node_or_null("Quantidade")
		if botoes != null:
			botoes.visible = marcado
		b.set_pressed_no_signal(marcado)
		b.disabled = motivo != ""
		b.modulate = Color(1, 1, 1, 0.45) if motivo != "" else Color.WHITE
		var base_dica := String(b.get_meta("dica", b.tooltip_text))
		b.set_meta("dica", base_dica)
		b.tooltip_text = base_dica + ("\n\nBloqueado: " + motivo if motivo != "" else "") + ("\n" + aviso if aviso != "" else "")
	for cat in _cabecalhos_cat:   # some a categoria sem etiqueta no grupo escolhido
		(_cabecalhos_cat[cat] as Label).visible = visiveis.has(_fluxos_cat[cat])
		(_fluxos_cat[cat] as Control).visible = visiveis.has(_fluxos_cat[cat])
	_atualizar_armas_requisicao()


# --- Co-op local (ADR 0004) ---------------------------------------------------

func _montar_jogadores() -> void:
	for filho in _caixa_jogadores.get_children():
		filho.queue_free()
	var ctl := carreira.controles
	var conectados := Input.get_connected_joypads()
	for j in ctl.jogadores.size():
		var linha := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "Jogador %d" % (j + 1)
		linha.add_child(lbl)
		var jog_j: Dictionary = ctl.jogadores[j]
		if jog_j.dispositivo == ControleLocal.REDE:
			var online := Label.new()
			online.text = "online: %s" % jog_j.get("nome", "?")
			online.add_theme_color_override("font_color", Tema.INFO)
			linha.add_child(online)
			_caixa_jogadores.add_child(linha)
			continue
		var disp := OptionButton.new()
		disp.add_item("Teclado e mouse")
		for k in ControleLocal.MAX_JOGADORES:
			disp.add_item("Controle %d%s" % [k + 1, "" if k in conectados else " (desconectado)"])
		var jog: Dictionary = ctl.jogadores[j]
		disp.select(0 if jog.dispositivo == ControleLocal.TECLADO else int(jog.indice) + 1)
		disp.item_selected.connect(_definir_dispositivo.bind(j))
		linha.add_child(disp)
		if j > 0:
			linha.add_child(_botao("Remover", _remover_jogador.bind(j)))
		_caixa_jogadores.add_child(linha)
	if ctl.jogadores.size() < ControleLocal.MAX_JOGADORES:
		_caixa_jogadores.add_child(_botao("+ Jogador", _adicionar_jogador))
	# Modo Mestre (Fase 8.3): com mestre, ele joga as ameaças e tem um painel no mapa
	var linha_m := HBoxContainer.new()
	var lbl_m := Label.new()
	lbl_m.text = "Mestre"
	linha_m.add_child(lbl_m)
	var opt_m := OptionButton.new()
	opt_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_m.clip_text = true
	opt_m.add_item("Sem mestre (a IA joga as ameaças)")
	for j in ctl.jogadores.size():
		opt_m.add_item(ctl.descricao(j))
	opt_m.select(ctl.mestre + 1 if ctl.mestre >= 0 else 0)
	opt_m.item_selected.connect(_definir_mestre)
	linha_m.add_child(opt_m)
	_caixa_jogadores.add_child(linha_m)
	if ctl.co_op():
		var dica := Label.new()
		dica.text = "Cada agente do grupo tem um dono: na vez dele, só o dispositivo desse jogador controla o jogo."
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dica.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
		_caixa_jogadores.add_child(dica)


func _adicionar_jogador() -> void:
	var ctl := carreira.controles
	var usados := ctl.jogadores.filter(func(j): return j.dispositivo == ControleLocal.CONTROLE).map(func(j): return int(j.indice))
	var livre := 0
	while livre in usados:
		livre += 1
	ctl.adicionar_jogador(ControleLocal.CONTROLE, livre)
	_atualizar_tudo()


func _remover_jogador(j: int) -> void:
	carreira.controles.remover_jogador(j)
	_atualizar_tudo()


func _definir_dispositivo(i: int, j: int) -> void:
	if i == 0:
		carreira.controles.definir_dispositivo(j, ControleLocal.TECLADO)
	else:
		carreira.controles.definir_dispositivo(j, ControleLocal.CONTROLE, i - 1)


func _definir_dono(j: int, a: Agente) -> void:
	carreira.controles.definir_dono(a, j)
	if _jogo != null:
		_jogo.controles_mudaram()


func _definir_mestre(i: int) -> void:
	carreira.controles.definir_mestre(i - 1)
	if _jogo != null:
		_jogo.controles_mudaram()


# --- Online (Fase 8.2) ------------------------------------------------------------

## Online por código de sala (docs/29, C8): "Criar sala" mostra um código de 10 símbolos
## (o endereço e a porta desta máquina); "Entrar na sala" pede o código e o nome. A porta e
## o IP direto ficam no "Avançado".
func _montar_online() -> void:
	for filho in _caixa_online.get_children():
		filho.queue_free()
	var rede: Rede = _jogo.rede if _jogo != null else null
	if rede == null:
		return
	if rede.eh_host():
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "Sala aberta. Passe o código para quem vai jogar; quem entrar aparece em Jogadores, e você escolhe os donos dos agentes no grupo."
		lbl.add_theme_color_override("font_color", Tema.INFO)
		_caixa_online.add_child(lbl)
		var ips := _enderecos_locais()
		ips.sort_custom(func(x, y): return CodigoSala.tipo_de_rede(x)[0] < CodigoSala.tipo_de_rede(y)[0])
		for ip in ips:
			var codigo := CodigoSala.gerar(ip, rede.porta)
			var linha := HBoxContainer.new()
			linha.add_theme_constant_override("separation", Tema.ESPACO_M)
			var c := Label.new()
			c.text = codigo
			c.add_theme_font_size_override("font_size", Tema.FONTE_G + 6)
			c.add_theme_color_override("font_color", Tema.OURO_CLARO)
			var maquina := Tema.fonte_maquina()
			if maquina != null:
				c.add_theme_font_override("font", maquina)
			c.tooltip_text = "Endereço %s, porta %d" % [ip, rede.porta]
			c.mouse_filter = Control.MOUSE_FILTER_PASS
			linha.add_child(c)
			var copiar := _botao("Copiar", func(): pass)
			copiar.pressed.connect(func():
				DisplayServer.clipboard_set(codigo)
				copiar.text = "Copiado ✓")
			linha.add_child(copiar)
			var rede_nome := Label.new()
			rede_nome.text = String(CodigoSala.tipo_de_rede(ip)[1])
			rede_nome.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
			linha.add_child(rede_nome)
			_caixa_online.add_child(linha)
		var aviso := Label.new()
		aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		aviso.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
		aviso.text = "O código vale na mesma rede (Wi-Fi da casa) ou numa VPN de jogos, como ZeroTier ou Radmin. Pela internet, abra a porta %d no roteador." % rede.porta
		_caixa_online.add_child(aviso)
		var fechar := _botao("Fechar a sala", _parar_de_hospedar)
		fechar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_caixa_online.add_child(fechar)
		return
	var linha_host := HBoxContainer.new()
	linha_host.add_theme_constant_override("separation", Tema.ESPACO_M)
	var criar := _botao("Criar sala", _hospedar)
	criar.theme_type_variation = "BotaoPrincipal"
	linha_host.add_child(criar)
	var dica := Label.new()
	dica.text = "Você hospeda; os outros entram com o código."
	dica.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	linha_host.add_child(dica)
	_caixa_online.add_child(linha_host)
	var linha_entrar := HBoxContainer.new()
	linha_entrar.add_theme_constant_override("separation", Tema.ESPACO_M)
	_txt_endereco = LineEdit.new()
	_txt_endereco.placeholder_text = "código da sala (ex.: 6A8R1-Z3K0P)"
	_txt_endereco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_txt_endereco.text_changed.connect(func(_t): _lbl_erros.text = "")
	linha_entrar.add_child(_txt_endereco)
	_txt_nome = LineEdit.new()
	_txt_nome.placeholder_text = "seu nome"
	_txt_nome.custom_minimum_size = Vector2(120, 0)
	linha_entrar.add_child(_txt_nome)
	linha_entrar.add_child(_botao("Entrar na sala", _entrar_na_sessao))
	_caixa_online.add_child(linha_entrar)
	# Avançado: a porta e o IP direto (o campo do código também aceita "IP" ou "IP:porta")
	var avancado := CheckBox.new()
	avancado.text = "Avançado: porta"
	_caixa_online.add_child(avancado)
	var linha_av := HBoxContainer.new()
	linha_av.visible = false
	_txt_porta = LineEdit.new()
	_txt_porta.text = str(Rede.PORTA_PADRAO)
	_txt_porta.custom_minimum_size = Vector2(80, 0)
	linha_av.add_child(_txt_porta)
	var nota := Label.new()
	nota.text = "Porta usada ao criar a sala. Para entrar por IP, digite \"IP\" ou \"IP:porta\" no lugar do código."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nota.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	linha_av.add_child(nota)
	_caixa_online.add_child(linha_av)
	avancado.toggled.connect(func(on): linha_av.visible = on)


func _enderecos_locais() -> Array:
	var lista: Array = []
	for ip in IP.get_local_addresses():
		if not ":" in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			lista.append(ip)
	return lista if not lista.is_empty() else ["127.0.0.1"]


func _porta() -> int:
	var p := _txt_porta.text.to_int() if _txt_porta != null else Rede.PORTA_PADRAO
	return p if p > 0 and p < 65536 else Rede.PORTA_PADRAO


func _hospedar() -> void:
	var erro: Error = _jogo.hospedar(_porta())
	_lbl_erros.text = "" if erro == OK else "Não deu para criar a sala (erro %d): a porta pode estar em uso. Troque-a no Avançado." % erro
	_atualizar_tudo()


func _parar_de_hospedar() -> void:
	_jogo.sair_da_sessao()


func _entrar_na_sessao() -> void:
	var alvo := CodigoSala.ler(_txt_endereco.text, _porta())
	if alvo.is_empty():
		_lbl_erros.text = "Código não reconhecido. Confira as 10 letras e números (o hífen é opcional)."
		return
	var erro: Error = _jogo.entrar_em_sessao(String(alvo.ip), int(alvo.porta), _txt_nome.text.strip_edges())
	if erro != OK:
		_lbl_erros.text = "Não deu para conectar (erro %d)." % erro


func _ao_mudar_jogadores() -> void:
	if is_inside_tree():
		_atualizar_tudo()


func _grupo() -> Array:
	var g: Array = []
	for a in _checks_grupo:
		if _checks_grupo[a].button_pressed:
			g.append(a)
	return g


func _iniciar() -> void:
	var grupo := _grupo()
	var erros := carreira.validar_grupo(grupo)
	if not erros.is_empty():
		_lbl_erros.text = "\n".join(erros)
		return
	var op: Dictionary = _opcoes_missao[clampi(_opt_missao.selected, 0, _opcoes_missao.size() - 1)]
	if not op.erros.is_empty():
		_lbl_erros.text = "Esta missão tem erros:\n" + "\n".join(op.erros)
		return
	if _jogo == null:
		return
	match String(op.tipo):
		"campanha":
			_jogo.iniciar_missao_campanha(grupo, op.definicao)
		"comunidade":
			_jogo.iniciar_missao_comunidade(grupo, op.definicao)
		_:
			_jogo.iniciar_missao(grupo, semente_proxima, sinais[sinal_escolhido] if not sinais.is_empty() else {})   # a região e o sinal do briefing


# --- Lista de missões: procedural, campanha (Fase 7) e comunidade (Fase 6) ---------

func _listar_missoes() -> void:
	var antes := _opt_missao.selected
	_opcoes_missao = [{"tipo": "procedural", "definicao": {}, "erros": [] as Array[String]}]
	for c in Campanha.listar(carreira.ruleset):
		_opcoes_missao.append({"tipo": "campanha", "definicao": c.definicao, "erros": c.erros})
	for m in MissaoComunidade.listar(carreira.ruleset):
		_opcoes_missao.append({"tipo": "comunidade", "definicao": m.definicao, "erros": m.erros, "caminho": m.caminho})
	_opt_missao.clear()
	for op in _opcoes_missao:
		_opt_missao.add_item(_nome_da_opcao(op))
	_opt_missao.select(clampi(antes, 0, _opt_missao.item_count - 1))
	_mostrar_missao()


func _nome_da_opcao(op: Dictionary) -> String:
	var d: Dictionary = op.definicao
	var erro := "" if op.erros.is_empty() else " (com erros)"
	match String(op.tipo):
		"campanha":
			var p := carreira.progresso_campanha(String(d.get("id", "")))
			return "Campanha: %s — %s%s" % [d.get("titulo", "?"), Campanha.descrever_etapa(d, p).to_lower() if p.concluida else Campanha.descrever_etapa(d, p).get_slice(":", 0), erro]
		"comunidade":
			return "%s%s%s" % [d.get("titulo", String(op.caminho).get_file()), "" if String(d.get("autor", "")) == "" else " — " + String(d.autor), erro]
	return "Missão procedural (mapa e caso sorteados)"


func _mostrar_missao() -> void:
	var op: Dictionary = _opcoes_missao[clampi(_opt_missao.selected, 0, _opcoes_missao.size() - 1)]
	var d: Dictionary = op.definicao
	var texto := ""
	if _caixa_sinais != null:
		_caixa_sinais.visible = String(op.tipo) == "procedural"
	match String(op.tipo):
		"procedural":
			texto = briefing_procedural(Missao.previa(semente_proxima), _grupo(), sinais[sinal_escolhido] if not sinais.is_empty() else {})
		"campanha":
			texto = _texto_da_campanha(d)
		"comunidade":
			texto = String(d.get("descricao", ""))
			if d.has("nex_recomendado"):
				texto += "  (NEX recomendado: %d%%)" % int(d.nex_recomendado)
	if not op.erros.is_empty():
		texto += "\n[color=#a51c1c]Erros: %s[/color]" % "; ".join(PackedStringArray(op.erros))
	_txt_missao.text = texto


## Escolhe um dos sinais da rede: a próxima missão passa a ser a dele.
func _escolher_sinal(i: int) -> void:
	sinal_escolhido = clampi(i, 0, sinais.size() - 1)
	semente_proxima = int(sinais[sinal_escolhido].semente)
	if sinal_escolhido < _botoes_sinais.size():
		_botoes_sinais[sinal_escolhido].button_pressed = true   # o grupo desmarca os outros; "pressed" não dispara de novo
	_mostrar_missao()


## Arquivo do caso da missão procedural (docs/23, C7), em BBCode: número, o sinal que trouxe
## o caso (docs/62), o ponto de encontro de fachada, a região, o que se sabe e o grupo.
## Estático para os testes.
static func briefing_procedural(p: Dictionary, grupo: Array, sinal: Dictionary = {}) -> String:
	var linhas := PackedStringArray()
	linhas.append("[b]ARQUIVO Nº %04d · OPERAÇÃO EM CAMPO[/b]" % int(p.numero))
	linhas.append("[color=#8e1b22]CONFIDENCIAL[/color]")
	linhas.append("")
	if not sinal.is_empty():
		linhas.append("[b]Sinal:[/b] %s, confiança %s. \"%s\"" % [sinal.fonte, sinal.rotulo, String(sinal.relato).left(1).to_upper() + String(sinal.relato).substr(1) + "."])
		var f := Sinais.fachada(int(sinal.semente))
		linhas.append("[b]Ponto de encontro:[/b] %s. Senha: \"%s\" Resposta: \"%s\"" % [f.lugar, f.senha, f.resposta])
		linhas.append("")
	linhas.append("[b]Região:[/b] %s, %d áreas no mapa." % [" e ".join(PackedStringArray(p.terrenos)), int(p.celulas)])
	var ocupacao := PackedStringArray()
	if int(p.cidades) > 0:
		ocupacao.append("%d trecho%s de cidade" % [int(p.cidades), "" if int(p.cidades) == 1 else "s"])
	if int(p.vilas) > 0:
		ocupacao.append("%d vila%s onde descansar" % [int(p.vilas), "" if int(p.vilas) == 1 else "s"])
	if not ocupacao.is_empty():
		linhas.append("[b]Gente:[/b] %s." % ", ".join(ocupacao))
	linhas.append("[b]Locais a investigar:[/b] %d. [b]Ocorrências relatadas:[/b] %d." % [int(p.investigacoes), int(p.eventos)])
	linhas.append("")
	linhas.append("[b]Sinais:[/b] %s" % p.sinais)
	linhas.append("[b]Objetivo:[/b] %s" % p.objetivo)
	if not grupo.is_empty():
		linhas.append("")
		linhas.append("[b]Agentes designados:[/b] %s." % ", ".join(PackedStringArray(grupo.map(func(a): return "%s (%s, NEX %d%%)" % [a.nome, a.classe_id, a.nex]))))
	return "\n".join(linhas)


## Ponto em que a campanha está: prólogo (na primeira missão), título, NEX e o texto de abertura.
func _texto_da_campanha(d: Dictionary) -> String:
	if d.get("missoes", []).is_empty():
		return String(d.get("descricao", ""))
	var p := carreira.progresso_campanha(String(d.get("id", "")))
	var linhas: Array[String] = []
	if p.concluida:
		linhas.append("[b]Campanha concluída[/b] (%d vez(es)). Iniciar de novo recomeça da primeira missão." % int(p.vezes))
		linhas.append("[i]%s[/i]" % d.get("epilogo", ""))
		return "\n".join(linhas)
	var i := clampi(int(p.etapa), 0, d.missoes.size() - 1)
	var md: Dictionary = d.missoes[i].get("definicao", {})
	if i == 0:
		linhas.append("[i]%s[/i]" % d.get("prologo", d.get("descricao", "")))
	linhas.append("[b]%s[/b]%s" % [Campanha.descrever_etapa(d, p), "  (NEX recomendado: %d%%)" % int(md.nex_recomendado) if md.has("nex_recomendado") else ""])
	linhas.append(String(d.missoes[i].get("antes", md.get("descricao", ""))))
	return "\n".join(linhas)


func _abrir_editor() -> void:
	if _jogo != null:
		_jogo.ir_para_editor()


func _continuar() -> void:
	if _jogo != null:
		_jogo.continuar_missao()


func _nova_carreira() -> void:
	if _jogo != null:
		carreira = _jogo.nova_carreira()
	else:
		carreira = Carreira.nova()
	_selecionado = carreira.roster[0]
	_atualizar_tudo()
	_montar_memorial()


## Vai para a aba pelo nome (as abas mudam de ordem quando entra uma nova).
func ir_para_aba(nome: String) -> void:
	for i in _abas.get_tab_count():
		if _abas.get_tab_title(i) == nome:
			_abas.current_tab = i
			return


# --- A planta da Base (docs/63, OR2) --------------------------------------------------

## A Base como lugar (docs/65): o bar de fachada em 3D, com WASD. Cada seção leva a uma aba
## do menu (que continua no topo) ou abre o bilhete do serviço por cima da cena: laboratório,
## contenção, enfermaria e sala de ocultismo. Monta a sala uma vez; depois só o bilhete.
func _montar_planta() -> void:
	if _aba_planta == null:
		return
	if _sala_base == null:
		_construir_sala_base()
	if _servico_aberto != "":
		_abrir_servico(_servico_aberto)


func _construir_sala_base() -> void:
	var vista := SubViewportContainer.new()
	vista.stretch = true
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Tema.veu(vista)
	_aba_planta.add_child(vista)
	var vp := SubViewport.new()
	Qualidade.vista(vp)
	vista.add_child(vp)
	_sala_base = SalaBase.new()
	vp.add_child(_sala_base)
	_sala_base.construir(_selecionado if _selecionado != null else (carreira.roster[0] if not carreira.roster.is_empty() else null))
	_agente_na_sala = _selecionado
	# A dica de controles, no alto
	var dica := Label.new()
	dica.text = "Ande com WASD ou as setas · E ou Enter para entrar · 1 a 9 levam direto a cada seção"
	dica.position = Vector2(16, 10)
	dica.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	dica.add_theme_constant_override("outline_size", 6)
	dica.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_aba_planta.add_child(dica)
	# O aviso da seção ao alcance, embaixo no centro
	_aviso_estacao = PanelContainer.new()
	_aviso_estacao.add_theme_stylebox_override("panel", Tema.caixa(Color(Tema.PEDRA, 0.92), Tema.OURO, 2, 6, Vector2(16, 8)))
	_aviso_estacao.anchor_left = 0.5
	_aviso_estacao.anchor_right = 0.5
	_aviso_estacao.anchor_top = 1.0
	_aviso_estacao.anchor_bottom = 1.0
	_aviso_estacao.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_aviso_estacao.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_aviso_estacao.offset_bottom = -16
	_aviso_estacao.visible = false
	_aba_planta.add_child(_aviso_estacao)
	_lbl_estacao = Label.new()
	_lbl_estacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_estacao.add_child(_lbl_estacao)
	# O bilhete do serviço, à direita
	_bilhete_servico = PanelContainer.new()
	_bilhete_servico.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(14, 12)))
	_bilhete_servico.theme = Tema.tema_papel()
	_bilhete_servico.anchor_left = 1.0
	_bilhete_servico.anchor_right = 1.0
	_bilhete_servico.offset_left = -440
	_bilhete_servico.offset_right = -16
	_bilhete_servico.offset_top = 40
	_bilhete_servico.rotation_degrees = -0.6
	_bilhete_servico.visible = false
	_aba_planta.add_child(_bilhete_servico)


## O agente chegou (ou foi levado) a uma seção e entrou: abre a aba ou o serviço dela.
func _entrar_estacao(e: Dictionary) -> void:
	if e.is_empty():
		return
	Som.tocar("papel")
	var destino := String(e.destino)
	if destino in ["Jogadores", "Agentes", "Missão", "Arsenal", "Memorial"]:
		_fechar_servico()
		ir_para_aba(destino)
	else:
		_abrir_servico(destino)


## O bilhete do serviço por cima da cena (docs/65): laboratório, contenção, enfermaria e
## sala de ocultismo, com o resultado da última ação embaixo.
func _abrir_servico(id: String) -> void:
	_servico_aberto = id
	var texto_antes := _lbl_servico.text if _lbl_servico != null else ""
	for f in _bilhete_servico.get_children():
		_bilhete_servico.remove_child(f)
		f.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	_bilhete_servico.add_child(v)
	var pendentes := carreira.roster.filter(func(a): return not Progressao.pendencias(a).is_empty())
	match id:
		"laboratorio":
			_sala_laboratorio(v)
		"contencao":
			_sala_contencao(v)
		"enfermaria":
			_sala(v, "Enfermaria", "Quem volta, volta inteiro: PV, PE e Sanidade cheios, condições e efeitos de insanidade curados.", "", Callable())
		"ocultismo":
			var b := _sala(v, "Sala de ocultismo", ("%d agente(s) com escolhas de NEX à espera." % pendentes.size()) if not pendentes.is_empty()
				else "Nenhuma escolha de NEX à espera. Os sigilos dormem.", "Transcender", func():
					if not pendentes.is_empty():
						Transcender.abrir(self, pendentes[0]))
			b.disabled = pendentes.is_empty()
	_lbl_servico = Label.new()
	_lbl_servico.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_servico.add_theme_color_override("font_color", Tema.SANGUE)
	_lbl_servico.text = texto_antes
	v.add_child(_lbl_servico)
	var fechar := Button.new()
	fechar.text = "Fechar (Esc)"
	fechar.theme_type_variation = "BotaoPapel"
	fechar.size_flags_horizontal = Control.SIZE_SHRINK_END
	fechar.pressed.connect(_fechar_servico)
	v.add_child(fechar)
	# Do lado oposto ao agente, para não cobrir a seção onde ele está
	var a_direita := _sala_base != null and _sala_base.figura.position.x > 0.5
	_bilhete_servico.anchor_left = 0.0 if a_direita else 1.0
	_bilhete_servico.anchor_right = 0.0 if a_direita else 1.0
	_bilhete_servico.offset_left = 16.0 if a_direita else -440.0
	_bilhete_servico.offset_right = 440.0 if a_direita else -16.0
	_bilhete_servico.visible = true


func _fechar_servico() -> void:
	_servico_aberto = ""
	if _bilhete_servico != null:
		_bilhete_servico.visible = false
	if _lbl_servico != null:
		_lbl_servico.text = ""


## O agente da Base anda quando a aba Base está à mostra e nada está aberto por cima.
func _process(delta: float) -> void:
	if _sala_base == null or not _aba_planta.is_visible_in_tree() or TourGuiado.em_andamento() or TourGuiado.papel_aberto(get_tree()):
		return
	if _selecionado != null and _selecionado != _agente_na_sala:
		_agente_na_sala = _selecionado
		_sala_base.trocar_agente(_selecionado)
	var entrada := Vector2.ZERO
	if not get_viewport().gui_get_focus_owner() is LineEdit:
		if Atalhos.segurando("mover_cima"): entrada.y -= 1
		if Atalhos.segurando("mover_baixo"): entrada.y += 1
		if Atalhos.segurando("mover_esquerda"): entrada.x -= 1
		if Atalhos.segurando("mover_direita"): entrada.x += 1
	var dir := Vector3.ZERO
	if entrada != Vector2.ZERO:
		var g := _sala_base.rig.giro
		dir = Vector3(cos(g), 0, -sin(g)) * entrada.x + Vector3(-sin(g), 0, -cos(g)) * -entrada.y
	_sala_base.mover(dir, delta)
	_sala_base.rig.alvo = _sala_base.figura.position.lerp(Vector3(0, 0, 0.2), 0.6)   # o salão quase inteiro à vista
	var e := _sala_base.estacao_proxima()
	_aviso_estacao.visible = not e.is_empty()
	if not e.is_empty():
		_lbl_estacao.text = "E · Entrar: %s\n%s" % [e.nome, e.texto]


func _unhandled_input(evento: InputEvent) -> void:
	if _sala_base == null or not _aba_planta.is_visible_in_tree() or TourGuiado.em_andamento() or TourGuiado.papel_aberto(get_tree()):
		return
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	var k: int = (evento as InputEventKey).keycode
	if k == KEY_ESCAPE and _servico_aberto != "":
		_fechar_servico()
	elif k == KEY_E or k == KEY_ENTER or k == KEY_KP_ENTER:
		_entrar_estacao(_sala_base.estacao_proxima())
	elif k >= KEY_1 and k <= KEY_9:
		var est: Dictionary = SalaBase.ESTACOES[k - KEY_1]
		_entrar_estacao(_sala_base.ir_para(String(est.id)))
	else:
		return
	get_viewport().set_input_as_handled()


## Um cartão de sala: nome, o que faz e, se houver, o botão do serviço.
func _sala(pai: Control, nome: String, texto: String, botao: String, acao: Callable) -> Button:
	var p := _papel(false)
	p.custom_minimum_size = Vector2(360, 150)
	pai.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	p.add_child(v)
	var t := Label.new()
	t.text = nome.to_upper()
	t.theme_type_variation = "TextoPapel"
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	v.add_child(t)
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(320, 0)
	l.add_theme_color_override("font_color", Tema.TINTA)
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(l)
	if botao == "":
		return null
	var b := Button.new()
	b.text = botao
	b.theme_type_variation = "BotaoPapel"
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(acao)
	v.add_child(b)
	return b


## Laboratório (docs/63): cada amostra diz se um dos sinais é real ou alarme falso.
func _sala_laboratorio(pai: Control) -> void:
	_sala(pai, "Laboratório", "Amostras trazidas das missões: %d. Uma amostra diz se um sinal da rede é real ou alarme falso." % carreira.amostras, "", Callable())
	var caixa: VBoxContainer = pai.get_child(pai.get_child_count() - 1).get_child(0)
	for i in sinais.size():
		var s: Dictionary = sinais[i]
		var b := Button.new()
		b.theme_type_variation = "BotaoPapel"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = ("%s: %s" % [s.fonte, "alarme falso" if s.alarme_falso else "real"]) if s.get("verificado", false) else "Analisar: %s" % s.fonte
		b.disabled = s.get("verificado", false) or carreira.amostras <= 0
		b.pressed.connect(func():
			var r := carreira.analisar_sinal(sinais[i])
			if r.ok:
				_lbl_servico.text = "Laboratório: o sinal \"%s\" %s." % [sinais[i].fonte, "é alarme falso" if r.alarme_falso else "é real"]
				_salvar()
				_atualizar_sinais()
				_montar_planta_depois())
		caixa.add_child(b)


## Contenção (docs/63): as celas de A a D, só com uma vela; um interrogatório por preso a
## cada visita, com o agente escolhido.
func _sala_contencao(pai: Control) -> void:
	_sala(pai, "Contenção", "Celas de A a D, escuras, só com uma vela: ninguém se concentra em símbolos ali." +
		("" if not carreira.contencao.is_empty() else " Nenhum preso."), "", Callable())
	var caixa: VBoxContainer = pai.get_child(pai.get_child_count() - 1).get_child(0)
	if carreira.contencao.is_empty():
		return
	_opt_interrogador = OptionButton.new()
	for a in carreira.roster:
		_opt_interrogador.add_item("Interroga: %s" % a.nome)
	caixa.add_child(_opt_interrogador)
	for i in carreira.contencao.size():
		var p: Dictionary = carreira.contencao[i]
		var b := Button.new()
		b.theme_type_variation = "BotaoPapel"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "Cela %s · %s, %s · %d segredo(s)" % [p.cela, p.nome, String(p.papel).to_lower(), int(p.segredos)]
		b.disabled = int(p.get("interrogado", -1)) == carreira.missoes_concluidas or carreira.roster.is_empty()
		b.tooltip_text = "Já interrogado nesta visita." if b.disabled else "Interrogar (Intimidação, Diplomacia ou Intuição, DT %d)." % int(DadosJogo.ler("sinais").contencao.dt)
		b.pressed.connect(func():
			var ag: Agente = carreira.roster[clampi(_opt_interrogador.selected, 0, carreira.roster.size() - 1)]
			var r := carreira.interrogar(i, ag)
			if r.get("ok", false):
				Som.tocar("pista" if r.sucesso else "erro")
				_lbl_servico.text = "Contenção: %s (%s: %s)" % [r.texto, ag.nome, r.teste.descrever() if r.teste != null else "sem treino"]
				_salvar()
				_montar_planta_depois())
		caixa.add_child(b)


## Remonta o bilhete no fim do quadro (o botão que chamou ainda está na árvore).
func _montar_planta_depois() -> void:
	await get_tree().process_frame
	_montar_planta()


## O texto dos botões de sinal na aba Missão, com o resultado do laboratório.
func _atualizar_sinais() -> void:
	for i in mini(_botoes_sinais.size(), sinais.size()):
		var s: Dictionary = sinais[i]
		_botoes_sinais[i].text = Sinais.resumo(s) + (("\nLaboratório: %s." % ("alarme falso" if s.alarme_falso else "real")) if s.get("verificado", false) else "")


## A parede de memória (docs/59): remonta só quando o memorial muda (as fotos custam).
func _montar_memorial() -> void:
	if _aba_memorial == null or carreira.memorial.size() == _memorial_visto:
		return
	_memorial_visto = carreira.memorial.size()
	for f in _aba_memorial.get_children():
		f.queue_free()
	var margem := MarginContainer.new()
	margem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, Tema.ESPACO_G)
	margem.add_child(Memorial.parede(carreira.memorial))
	_aba_memorial.add_child(margem)


func _salvar() -> void:
	if _jogo != null:
		_jogo.salvar()
