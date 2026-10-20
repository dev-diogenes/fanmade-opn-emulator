extends Control
## Base da Ordem (hub entre missões) como dossiê (docs/09): abas Agentes, Arsenal, Missão
## e Jogadores. A ficha do agente, o briefing e o relatório da última missão são folhas de
## papel; o resto é a mesa escura da Ordem.

var carreira: Carreira
var _jogo: Node
var _selecionado: Agente

var _lista: ItemList
var _abas: TabContainer
var _sigilo_agente: Sigilo
var _legenda_foto: Label
var _opt_recruta: OptionButton
var _ficha: RichTextLabel
var _caixa_pendencia: VBoxContainer
var _caixa_requisicao: HFlowContainer
var _checks_itens: Dictionary = {}     ## item_id -> CheckBox
var _opt_arma: OptionButton
var _lbl_requisicao: Label
var _caixa_grupo: VBoxContainer
var _checks_grupo: Dictionary = {}     ## Agente -> CheckBox
var _donos_grupo: Dictionary = {}      ## Agente -> OptionButton (dono no co-op local)
var _caixa_jogadores: VBoxContainer
var _caixa_online: VBoxContainer
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


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	carreira = _jogo.carregar_ou_criar() if _jogo != null else Carreira.nova()
	_montar_interface()
	if not carreira.roster.is_empty():
		_selecionado = carreira.roster[0]
	_atualizar_tudo()
	if _jogo != null:
		_jogo.jogadores_mudaram.connect(_ao_mudar_jogadores)
		if _jogo.aviso_rede != "":
			_lbl_erros.text = _jogo.aviso_rede
			_jogo.aviso_rede = ""
	# Tutorial (docs/07-tutorial.md): convite ao abrir o jogo e o "?" desta tela
	Tutorial.botao_ajuda(self, "base", _alvos_do_tutorial)
	if Tutorial.convidar(self, func(): Tutorial.abrir("base", self, _alvos_do_tutorial())) == null:
		Tutorial.ao_entrar("base", self, _alvos_do_tutorial())


func _alvos_do_tutorial() -> Dictionary:
	return {"agentes": _lista, "ficha": _ficha, "requisicao": _caixa_requisicao.get_parent(), "grupo": _caixa_grupo,
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
	linha_rec.add_child(_botao("Recrutar", _recrutar))
	c1.add_child(linha_rec)
	var doc := _papel(true)
	doc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	agentes.add_child(doc)
	var hdoc := HBoxContainer.new()
	hdoc.add_theme_constant_override("separation", Tema.ESPACO_GG)
	doc.add_child(hdoc)
	var vdoc := VBoxContainer.new()
	vdoc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vdoc.add_theme_constant_override("separation", Tema.ESPACO_M)
	hdoc.add_child(vdoc)
	# Foto do agente presa na ficha (sigilo da classe, como uma polaroide)
	var foto := PanelContainer.new()
	var estilo := Tema.caixa(Color("f3efe6"), Color(0, 0, 0, 0.25), 1, 1, Vector2(8, 8))
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 5
	foto.add_theme_stylebox_override("panel", estilo)
	foto.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	foto.rotation_degrees = 3
	foto.custom_minimum_size = Vector2(170, 0)
	hdoc.add_child(foto)
	var vf := VBoxContainer.new()
	foto.add_child(vf)
	var fundo_foto := ColorRect.new()
	fundo_foto.color = Color("17141a")
	fundo_foto.custom_minimum_size = Vector2(154, 150)
	vf.add_child(fundo_foto)
	_sigilo_agente = Sigilo.new()
	_sigilo_agente.cor = Color(Tema.OURO_CLARO, 0.9)
	_sigilo_agente.espessura = 2.4
	_sigilo_agente.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sigilo_agente.offset_left = 16
	_sigilo_agente.offset_right = -16
	_sigilo_agente.offset_top = 12
	_sigilo_agente.offset_bottom = -12
	fundo_foto.add_child(_sigilo_agente)
	_legenda_foto = Label.new()
	_legenda_foto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legenda_foto.add_theme_color_override("font_color", Tema.TINTA)
	vf.add_child(_legenda_foto)
	_ficha = RichTextLabel.new()
	_ficha.bbcode_enabled = true
	_ficha.fit_content = true
	_ficha.add_theme_color_override("default_color", Tema.TINTA)
	vdoc.add_child(_ficha)
	_caixa_pendencia = VBoxContainer.new()
	_caixa_pendencia.theme = Tema.tema_papel()   # as escolhas de NEX ficam escritas na ficha
	vdoc.add_child(_caixa_pendencia)

	# --- Aba Arsenal: a gaveta de requisição
	var arsenal := VBoxContainer.new()
	arsenal.name = "Arsenal"
	arsenal.add_theme_constant_override("separation", Tema.ESPACO_M)
	_abas.add_child(arsenal)
	arsenal.add_child(_titulo("Requisição de equipamento"))
	_lbl_requisicao = Label.new()
	_lbl_requisicao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_requisicao.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	arsenal.add_child(_lbl_requisicao)
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_caixa_requisicao = HFlowContainer.new()
	_caixa_requisicao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caixa_requisicao.add_theme_constant_override("h_separation", Tema.ESPACO_GG)
	rolagem.add_child(_caixa_requisicao)
	arsenal.add_child(rolagem)
	var linha_arma := HBoxContainer.new()
	linha_arma.add_theme_constant_override("separation", Tema.ESPACO_M)
	var lbl := Label.new()
	lbl.text = "Arma empunhada:"
	linha_arma.add_child(lbl)
	_opt_arma = OptionButton.new()
	_opt_arma.custom_minimum_size = Vector2(220, 0)
	linha_arma.add_child(_opt_arma)
	var req := _botao("Requisitar", _requisitar)
	req.theme_type_variation = "BotaoPrincipal"
	linha_arma.add_child(req)
	arsenal.add_child(linha_arma)
	for item in _catalogo():
		var chk := CheckBox.new()
		chk.custom_minimum_size = Vector2(300, 0)
		chk.text = "%s%s  [cat %s, %d esp.]" % ["☠ " if item.has("maldicoes") else "", item.nome, ["0", "I", "II", "III", "IV", "V"][mini(5, int(item.get("categoria", 0)))], int(item.get("espacos", 1))]
		if item.has("maldicoes"):
			chk.tooltip_text = "Maldições: %s" % ", ".join(PackedStringArray(item.maldicoes.map(func(m): return "%s (%s) — %s" % [m.nome, m.elemento, m.descricao])))
		chk.toggled.connect(func(_v): _atualizar_armas_requisicao())
		_checks_itens[item.id] = chk
		_caixa_requisicao.add_child(chk)

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
	c3.add_child(_titulo("Opções da run"))
	_opt_modo = OptionButton.new()
	_opt_modo.add_item("Normal (2 Reforços da Ordem)")
	_opt_modo.add_item("Hardcore (morte permanente)")
	_opt_modo.item_selected.connect(func(i): carreira.opcoes.modo_morte = "normal" if i == 0 else "hardcore")
	c3.add_child(_opt_modo)
	_chk_lesoes = CheckBox.new()
	_chk_lesoes.text = "Lesões (p.184)"
	_chk_lesoes.toggled.connect(func(v): carreira.opcoes.lesoes = v)
	c3.add_child(_chk_lesoes)
	_chk_inspiracao = CheckBox.new()
	_chk_inspiracao.text = "Inspiração Resoluta (p.184)"
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
	var apagar := _botao("Nova carreira (apaga o save)", _nova_carreira)
	apagar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cj.add_child(apagar)


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
		_ficha.text = "Nenhum agente."
		return
	var rs := carreira.ruleset
	if _sigilo_agente != null:
		var cores := {"combatente": Tema.SANGUE_CLARO, "especialista": Tema.OURO_CLARO, "ocultista": Tema.ELEMENTO.energia, "mundano": Tema.PERGAMINHO}
		_sigilo_agente.semente = hash(a.id + a.nome)
		_sigilo_agente.cor = cores.get(a.classe_id, Tema.PERGAMINHO)
		_legenda_foto.text = "%s · %s" % [a.nome, rs.classe(a.classe_id).nome]
	var linhas: Array[String] = []
	linhas.append("[b]%s[/b] — %s (%s), origem %s" % [a.nome, rs.classe(a.classe_id).nome, a.trilha_id if a.trilha_id != "" else "sem trilha", rs.origem(a.origem_id).nome if a.origem_id != "" else "—"])
	linhas.append("NEX %d%%   %s (%d PP)" % [a.nex, a.patente().get("nome", "?"), a.pp])
	linhas.append("PV %d   PE %d   SAN %d   Defesa %d   Desloc. %d m" % [a.pv_maximo, a.pe_maximo, a.san_maximo, a.defesa(), int(a.deslocamento_m())])
	var attrs := PackedStringArray()
	for k in ["agi", "for", "int", "pre", "vig"]:
		attrs.append("%s %d" % [k.to_upper(), a.atributo(k)])
	linhas.append("  ".join(attrs))
	var pers := PackedStringArray()
	for p in a.pericias:
		pers.append("%s%s" % [rs.pericia(p).nome, "" if a.pericias[p] == "treinado" else " (%s)" % a.pericias[p]])
	linhas.append("[color=#6b5a48]Perícias:[/color] " + ", ".join(pers))
	var habs := PackedStringArray()
	for h in a.habilidades():
		habs.append(h.nome + ("" if h.get("implementado", false) else "*"))
	linhas.append("[color=#6b5a48]Habilidades:[/color] " + ", ".join(habs))
	if not a.poderes_paranormais.is_empty():
		var pps := PackedStringArray()
		for e in a.poderes_paranormais:
			pps.append(rs.poder_paranormal(e.id).get("nome", e.id) + ("" if String(e.get("escolha", "")) == "" else " (%s)" % e.escolha))
		linhas.append("[color=#5b2a86]Poderes paranormais:[/color] %s%s" % [", ".join(pps), "  ·  afinidade: " + a.afinidade if a.afinidade != "" else ""])
	if not a.rituais.is_empty():
		var rits := PackedStringArray()
		for rid in a.rituais:
			rits.append(rs.ritual(rid).get("nome", rid) + ("" if rs.ritual(rid).get("implementado", false) else "*"))
		linhas.append("[color=#5b2a86]Rituais:[/color] " + ", ".join(rits))
	linhas.append("[color=#6b5a48]Equipamento:[/color] %s  (%d/%d espaços)" % [", ".join(PackedStringArray(a.equipamento.map(func(i): return rs.equipamento(i).get("nome", i)))), a.espacos_usados(), a.capacidade_carga()])
	if not a.lesoes.is_empty():
		linhas.append("[color=#9a4a10]Lesões:[/color] " + ", ".join(PackedStringArray(a.lesoes)))
	linhas.append("[color=#6b5a48]* ainda sem efeito no motor[/color]")
	_ficha.text = "\n".join(linhas)
	for item_id in _checks_itens:
		_checks_itens[item_id].set_pressed_no_signal(item_id in a.equipamento)
	_atualizar_armas_requisicao()
	_lbl_requisicao.text = "Patente %s: categoria I até %d, II até %d, III até %d." % [a.patente().get("nome", "?"), int(a.patente().itens_por_categoria["1"]), int(a.patente().itens_por_categoria["2"]), int(a.patente().itens_por_categoria["3"])]
	_montar_pendencia(a)


func _atualizar_armas_requisicao() -> void:
	var atual := _selecionado.arma_id if _selecionado != null else ""
	_opt_arma.clear()
	_opt_arma.add_item("Desarmado")
	_opt_arma.set_item_metadata(0, "")
	for item_id in _checks_itens:
		if _checks_itens[item_id].button_pressed and carreira.ruleset.equipamento(item_id).tipo == "arma":
			_opt_arma.add_item(carreira.ruleset.equipamento(item_id).nome)
			_opt_arma.set_item_metadata(_opt_arma.item_count - 1, item_id)
			if item_id == atual:
				_opt_arma.select(_opt_arma.item_count - 1)


func _montar_pendencia(a: Agente) -> void:
	for filho in _caixa_pendencia.get_children():
		filho.queue_free()
	var pend := Progressao.pendencias(a)
	if pend.is_empty():
		return
	var p: Dictionary = pend[0]
	var rs := carreira.ruleset
	var titulos := {"trilha": "Escolha a trilha (NEX 10%)", "poder": "Escolha um poder de classe", "aumento": "Aumente um atributo", "ritual": "Aprenda um ritual",
		"poder_paranormal": "Escolha um poder paranormal", "afinidade": "Afinidade elemental (NEX 50%)",
		"grau": "Grau de Treinamento: escolha %d perícias" % int(p.get("quantidade", 0)), "versatilidade": "Versatilidade (NEX 50%)"}
	var lbl := _titulo("[%d pendente(s)] %s" % [pend.size(), titulos[p.tipo]])
	lbl.add_theme_color_override("font_color", Tema.SANGUE)
	_caixa_pendencia.add_child(lbl)
	if p.tipo == "grau":
		var lista := ItemList.new()
		lista.select_mode = ItemList.SELECT_MULTI
		lista.custom_minimum_size = Vector2(0, 90)
		for per in p.opcoes:
			lista.add_item(rs.pericia(per).nome)
		_caixa_pendencia.add_child(lista)
		_caixa_pendencia.add_child(_botao("Confirmar", func():
			var escolhidas: Array = []
			for i in lista.get_selected_items():
				escolhidas.append(p.opcoes[i])
			_aplicar(a, "grau", escolhidas)))
		return
	var opt := OptionButton.new()
	for o in p.opcoes:
		var nome := String(o)
		match p.tipo:
			"trilha": nome = rs.trilha(a.classe_id, o).nome
			"poder": nome = rs.poder(a.classe_id, o).nome + ("" if rs.poder(a.classe_id, o).get("implementado", false) else " *")
			"aumento": nome = String(o).to_upper()
			"ritual": nome = "%s (%dº, %s)%s" % [rs.ritual(o).nome, int(rs.ritual(o).circulo), rs.ritual(o).elemento, "" if rs.ritual(o).get("implementado", false) else " *"]
			"poder_paranormal": nome = "%s (%s)%s" % [rs.poder_paranormal(o).nome, rs.poder_paranormal(o).elemento, "" if rs.poder_paranormal(o).get("implementado", false) else " *"]
			"afinidade": nome = String(o).capitalize()
		opt.add_item(nome)
	_caixa_pendencia.add_child(opt)
	# Transcender pede um poder paranormal; outras escolhas usam o campo de texto
	var opt_para := OptionButton.new()
	if p.tipo == "poder":
		opt_para.add_item("(para Transcender) escolha o poder paranormal")
		opt_para.set_item_metadata(0, "")
		for pid in Progressao.poderes_paranormais_possiveis(a):
			opt_para.add_item(rs.poder_paranormal(pid).nome)
			opt_para.set_item_metadata(opt_para.item_count - 1, pid)
		_caixa_pendencia.add_child(opt_para)
	var extra := LineEdit.new()
	extra.placeholder_text = "Escolha extra: perícias (Treinamento) · ritual/elemento/classe:poder (poderes paranormais)"
	_caixa_pendencia.add_child(extra)
	_caixa_pendencia.add_child(_botao("Confirmar", func():
		var escolha = p.opcoes[opt.selected]
		var pares: Array = []
		if p.tipo == "poder" and escolha == "transcender":
			pares.append(opt_para.get_item_metadata(opt_para.selected) if opt_para.selected >= 0 else "")
			pares.append(extra.text.strip_edges())
		elif p.tipo == "poder_paranormal":
			pares.append(extra.text.strip_edges())
		else:
			for t in extra.text.split(",", false):
				pares.append(t.strip_edges())
		_aplicar(a, p.tipo, escolha, pares)))


func _aplicar(a: Agente, tipo: String, escolha, extra: Array = []) -> void:
	var erros := Progressao.aplicar(a, tipo, escolha, extra)
	_lbl_requisicao.text = "\n".join(erros) if not erros.is_empty() else "Escolha aplicada."
	_salvar()
	_atualizar_tudo()


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
			s += ", %+d PP, NEX %d%%→%d%%, %s%s" % [int(ag.pp), int(ag.nex_antes), int(ag.nex), ag.patente, " [color=#2f6b3f](promovido!)[/color]" if ag.promovido else ""]
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
			linhas.append("[color=#2f6b3f]%s pode ser recrutado na Base.[/color]" % nome)
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


func _recrutar() -> void:
	if _opt_recruta.item_count == 0:
		return
	var a := carreira.recrutar(_opt_recruta.get_item_metadata(_opt_recruta.selected))
	if a != null:
		_selecionado = a
	_salvar()
	_atualizar_tudo()


func _requisitar() -> void:
	if _selecionado == null:
		return
	var itens: Array = []
	for item_id in _checks_itens:
		if _checks_itens[item_id].button_pressed:
			itens.append(item_id)
	var arma: String = _opt_arma.get_item_metadata(_opt_arma.selected) if _opt_arma.selected >= 0 else ""
	var erros := carreira.requisitar(_selecionado, itens, arma)
	_lbl_requisicao.text = "\n".join(erros) if not erros.is_empty() else "Equipamento requisitado."
	_salvar()
	_atualizar_agente()


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

func _montar_online() -> void:
	for filho in _caixa_online.get_children():
		filho.queue_free()
	var rede: Rede = _jogo.rede if _jogo != null else null
	if rede == null:
		return
	if rede.eh_host():
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "Hospedando na porta %d. Endereços desta máquina: %s. Quem entrar aparece em Jogadores; escolha os donos dos agentes no grupo." % [rede.porta, ", ".join(PackedStringArray(_enderecos_locais()))]
		lbl.add_theme_color_override("font_color", Tema.INFO)
		_caixa_online.add_child(lbl)
		_caixa_online.add_child(_botao("Parar de hospedar", _parar_de_hospedar))
		return
	var linha_host := HBoxContainer.new()
	_txt_porta = LineEdit.new()
	_txt_porta.text = str(Rede.PORTA_PADRAO)
	_txt_porta.placeholder_text = "porta"
	_txt_porta.custom_minimum_size = Vector2(70, 0)
	linha_host.add_child(_txt_porta)
	linha_host.add_child(_botao("Hospedar", _hospedar))
	_caixa_online.add_child(linha_host)
	var linha_entrar := HBoxContainer.new()
	_txt_endereco = LineEdit.new()
	_txt_endereco.text = "127.0.0.1"
	_txt_endereco.placeholder_text = "IP do host"
	_txt_endereco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_entrar.add_child(_txt_endereco)
	_txt_nome = LineEdit.new()
	_txt_nome.placeholder_text = "seu nome"
	_txt_nome.custom_minimum_size = Vector2(90, 0)
	linha_entrar.add_child(_txt_nome)
	linha_entrar.add_child(_botao("Entrar", _entrar_na_sessao))
	_caixa_online.add_child(linha_entrar)


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
	_lbl_erros.text = "" if erro == OK else "Não deu para hospedar (erro %d): a porta pode estar em uso." % erro
	_atualizar_tudo()


func _parar_de_hospedar() -> void:
	_jogo.sair_da_sessao()


func _entrar_na_sessao() -> void:
	var erro: Error = _jogo.entrar_em_sessao(_txt_endereco.text.strip_edges(), _porta(), _txt_nome.text.strip_edges())
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
			_jogo.iniciar_missao(grupo)


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
	match String(op.tipo):
		"procedural":
			texto = "Um mapa novo a cada missão, com encontros, eventos e investigações sorteados."
		"campanha":
			texto = _texto_da_campanha(d)
		"comunidade":
			texto = String(d.get("descricao", ""))
			if d.has("nex_recomendado"):
				texto += "  (NEX recomendado: %d%%)" % int(d.nex_recomendado)
	if not op.erros.is_empty():
		texto += "\n[color=#a51c1c]Erros: %s[/color]" % "; ".join(PackedStringArray(op.erros))
	_txt_missao.text = texto


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


func _salvar() -> void:
	if _jogo != null:
		_jogo.salvar()
