extends Control
## Base da Ordem (hub entre missões, interface provisória):
## roster e ficha dos agentes, escolhas de NEX pendentes, requisição de equipamento
## pela patente, recrutamento, opções da run, relatório da última missão e partida.

var carreira: Carreira
var _jogo: Node
var _selecionado: Agente

var _lista: ItemList
var _opt_recruta: OptionButton
var _ficha: RichTextLabel
var _caixa_pendencia: VBoxContainer
var _caixa_requisicao: VBoxContainer
var _checks_itens: Dictionary = {}     ## item_id -> CheckBox
var _opt_arma: OptionButton
var _lbl_requisicao: Label
var _caixa_grupo: VBoxContainer
var _checks_grupo: Dictionary = {}     ## Agente -> CheckBox
var _donos_grupo: Dictionary = {}      ## Agente -> OptionButton (dono no co-op local)
var _caixa_jogadores: VBoxContainer
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


# --- Montagem ------------------------------------------------------------------

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color("101318")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 10)
	add_child(margem)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 14)
	margem.add_child(colunas)

	# Coluna 1: roster
	var c1 := _coluna(colunas, 300)
	c1.add_child(_titulo("Base da Ordem", 20))
	c1.add_child(_titulo("Agentes"))
	_lista = ItemList.new()
	_lista.custom_minimum_size = Vector2(0, 220)
	_lista.item_selected.connect(_ao_selecionar)
	c1.add_child(_lista)
	var linha_rec := HBoxContainer.new()
	_opt_recruta = OptionButton.new()
	_opt_recruta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_rec.add_child(_opt_recruta)
	linha_rec.add_child(_botao("Recrutar", _recrutar))
	c1.add_child(linha_rec)
	c1.add_child(_titulo("Última missão"))
	_relatorio = RichTextLabel.new()
	_relatorio.bbcode_enabled = true
	_relatorio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c1.add_child(_relatorio)

	# Coluna 2: ficha, pendências e requisição
	var c2 := _coluna(colunas, 420)
	_ficha = RichTextLabel.new()
	_ficha.bbcode_enabled = true
	_ficha.custom_minimum_size = Vector2(0, 230)
	c2.add_child(_ficha)
	_caixa_pendencia = VBoxContainer.new()
	c2.add_child(_caixa_pendencia)
	c2.add_child(_titulo("Requisição de equipamento"))
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_caixa_requisicao = VBoxContainer.new()
	rolagem.add_child(_caixa_requisicao)
	c2.add_child(rolagem)
	var linha_arma := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Arma empunhada:"
	linha_arma.add_child(lbl)
	_opt_arma = OptionButton.new()
	linha_arma.add_child(_opt_arma)
	linha_arma.add_child(_botao("Requisitar", _requisitar))
	c2.add_child(linha_arma)
	_lbl_requisicao = Label.new()
	_lbl_requisicao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c2.add_child(_lbl_requisicao)
	for item in _catalogo():
		var chk := CheckBox.new()
		chk.text = "%s%s  [cat %s, %d esp.]" % ["☠ " if item.has("maldicoes") else "", item.nome, ["0", "I", "II", "III", "IV", "V"][mini(5, int(item.get("categoria", 0)))], int(item.get("espacos", 1))]
		if item.has("maldicoes"):
			chk.tooltip_text = "Maldições: %s" % ", ".join(PackedStringArray(item.maldicoes.map(func(m): return "%s (%s) — %s" % [m.nome, m.elemento, m.descricao])))
		chk.toggled.connect(func(_v): _atualizar_armas_requisicao())
		_checks_itens[item.id] = chk
		_caixa_requisicao.add_child(chk)

	# Coluna 3: missão
	var c3 := _coluna(colunas, 0)
	c3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c3.add_child(_titulo("Grupo da missão (até 4)"))
	_caixa_grupo = VBoxContainer.new()
	c3.add_child(_caixa_grupo)
	c3.add_child(_titulo("Jogadores (co-op local)"))
	_caixa_jogadores = VBoxContainer.new()
	c3.add_child(_caixa_jogadores)
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
	_btn_iniciar = _botao("Iniciar missão", _iniciar)
	c3.add_child(_btn_iniciar)
	_btn_continuar = _botao("Continuar missão em andamento", _continuar)
	c3.add_child(_btn_continuar)
	_lbl_erros = Label.new()
	_lbl_erros.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_erros.add_theme_color_override("font_color", Color("f1948a"))
	c3.add_child(_lbl_erros)
	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c3.add_child(espaco)
	c3.add_child(_botao("Nova carreira (apaga o save)", _nova_carreira))


func _coluna(pai: Control, largura: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(largura, 0)
	v.add_theme_constant_override("separation", 6)
	pai.add_child(v)
	return v


func _titulo(texto: String, tamanho: int = 14) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", Color("d5d8dc") if tamanho > 14 else Color("aab7b8"))
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
	linhas.append("[color=#aab7b8]Perícias:[/color] " + ", ".join(pers))
	var habs := PackedStringArray()
	for h in a.habilidades():
		habs.append(h.nome + ("" if h.get("implementado", false) else "*"))
	linhas.append("[color=#aab7b8]Habilidades:[/color] " + ", ".join(habs))
	if not a.poderes_paranormais.is_empty():
		var pps := PackedStringArray()
		for e in a.poderes_paranormais:
			pps.append(rs.poder_paranormal(e.id).get("nome", e.id) + ("" if String(e.get("escolha", "")) == "" else " (%s)" % e.escolha))
		linhas.append("[color=#c39bd3]Poderes paranormais:[/color] %s%s" % [", ".join(pps), "  ·  afinidade: " + a.afinidade if a.afinidade != "" else ""])
	if not a.rituais.is_empty():
		var rits := PackedStringArray()
		for rid in a.rituais:
			rits.append(rs.ritual(rid).get("nome", rid) + ("" if rs.ritual(rid).get("implementado", false) else "*"))
		linhas.append("[color=#bb8fce]Rituais:[/color] " + ", ".join(rits))
	linhas.append("[color=#aab7b8]Equipamento:[/color] %s  (%d/%d espaços)" % [", ".join(PackedStringArray(a.equipamento.map(func(i): return rs.equipamento(i).get("nome", i)))), a.espacos_usados(), a.capacidade_carga()])
	if not a.lesoes.is_empty():
		linhas.append("[color=#f5b041]Lesões:[/color] " + ", ".join(PackedStringArray(a.lesoes)))
	linhas.append("[color=#7f8c8d]* ainda sem efeito no motor[/color]")
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
	lbl.add_theme_color_override("font_color", Color("f7dc6f"))
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
			s += ", %+d PP, NEX %d%%→%d%%, %s%s" % [int(ag.pp), int(ag.nex_antes), int(ag.nex), ag.patente, " [color=#58d68d](promovido!)[/color]" if ag.promovido else ""]
		linhas.append(s)
	if not carreira.memorial.is_empty():
		linhas.append("[color=#7f8c8d]Memorial: %s[/color]" % ", ".join(PackedStringArray(carreira.memorial.map(func(m): return m.nome))))
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
	if ctl.co_op():
		var dica := Label.new()
		dica.text = "Cada agente do grupo tem um dono: na vez dele, só o dispositivo desse jogador controla o jogo."
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dica.add_theme_color_override("font_color", Color("aab7b8"))
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
	if _jogo != null:
		_jogo.iniciar_missao(grupo)


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
