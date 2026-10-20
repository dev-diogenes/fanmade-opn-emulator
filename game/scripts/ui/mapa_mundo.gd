extends Control
## Mapa-múndi da missão em 3D low poly (Mapa3D), em tela cheia com HUD flutuante (docs/09):
## turno e Membrana no topo, grupo embaixo à esquerda, dock de ações no centro, evento como
## bilhete, relatório recolhível e dica de hex no hover.
## O jogador rola o movimento (slots de d20), clica num hex para andar e resolve
## eventos e encontros. Câmera: roda = zoom, botão direito = girar, botão do meio
## ou WASD/setas = deslizar, Q/E = girar.

const COR_FUNDO := Tema.FUNDO
const CORES_AGENTES := Tema.CORES_JOGADORES

var missao: Missao
var sessao: Sessao
var _jogo: Node
var _terrenos: Dictionary

var _vista: SubViewportContainer
var _mapa3d: Mapa3D
var _lbl_turno: Label
var _lbl_ficha: Label
var _slots: HBoxContainer
var _grupo: HBoxContainer
var _cartoes: Dictionary = {}   ## Agente -> CartaoAgente
var _slots_desenhados = null
var _lbl_mov: Label
var _foco: PassoFoco
var _btn_rolar: Button
var _btn_descansar: Button
var _btn_encerrar: Button
var _barra_membrana: ProgressBar
var _lbl_membrana: Label
var _painel_evento: PanelContainer
var _lbl_evento: Label
var _btn_testar: Button
var _log: RelatorioCampo
var _dica: Label
var _hex_dica := Vector2i(-999, -999)
var _painel_fim: RelatorioFim
var _lbl_fim: Label
var _lbl_vez: Label
var _controles: ControleLocal
var _cursor := Vector2i.ZERO
var _cursor_ativo := false
## Modo Mestre (Fase 8.3)
var _btn_painel_mestre: Button
var _painel_mestre: PanelContainer
var _lbl_caso_mestre: Label
var _txt_narrar: LineEdit
var _chk_hex_mestre: CheckBox
var _lbl_hex_mestre: Label
var _opt_encontro_m: OptionButton
var _opt_evento_m: OptionButton
var _opt_agente_m: OptionButton
var _spin_valor_m: SpinBox
var _hex_mestre := Vector2i(-999, -999)


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	if _jogo != null:
		missao = _jogo.missao if _jogo.missao != null else _jogo.nova_missao()
	else:
		missao = Missao.nova(randi() % 1000000)
	_terrenos = DadosJogo.ler("mapa").terrenos
	Entrada.configurar()
	_controles = _jogo.controles() if _jogo != null else ControleLocal.padrao()
	sessao = _jogo.sessao if _jogo != null else Sessao.new()
	sessao.entrar("mapa", _aplicar_comando, func(): return missao.agente_atual(), func(): return Comandos.hash_missao(missao))
	sessao.comando_aplicado.connect(_ao_comando_aplicado)
	_montar_interface()
	for linha in missao.historico:
		_log.append_text(linha + "\n")
	if missao.historico.is_empty():
		_mostrar_briefing.call_deferred()
		_registrar("[b]Missão iniciada.[/b] O covil carmesim está em algum lugar a leste. A Membrana já começa a ceder.")
	missao.registro.connect(_registrar_sem_guardar)
	missao.encontro_iniciado.connect(_ao_encontro)
	missao.investigacao_iniciada.connect(_ao_investigar)
	missao.missao_encerrada.connect(_ao_encerrar)
	missao.turno_mudou.connect(_ao_mudar_turno)
	_mapa3d.focar_agente(missao, true)
	if missao.encerrada:
		_ao_encerrar(missao.vitoria)
	_atualizar()
	sessao.liberar()
	Tutorial.botao_ajuda(self, "mapa", _alvos_do_tutorial)
	Tutorial.ao_entrar("mapa", self, _alvos_do_tutorial())


func _alvos_do_tutorial() -> Dictionary:
	return {"vez": _lbl_turno, "rolar": _btn_rolar, "mapa": _vista, "botoes": _btn_rolar.get_parent(), "membrana": _barra_membrana, "registro": _log}


func _ao_mudar_turno(_a: Agente) -> void:
	_cursor_ativo = false
	_mapa3d.focar_agente(missao)
	_atualizar()
	_focar_para_controle()


## Com um controle na vez, o foco vai para o botão principal (a navegação é pelo direcional).
func _focar_para_controle() -> void:
	var a := missao.agente_atual()
	if a != null and _controles.usa_controle(a) and is_inside_tree():
		(_btn_testar if _painel_evento.visible else _btn_rolar).grab_focus()


# --- Co-op local e controles (ADR 0004) ------------------------------------

## Só o dispositivo do dono do agente da vez controla o mapa. Com um controle: o direcional
## move o cursor pelos hexes depois de rolar o movimento, A anda até ele, B volta aos botões.
func _input(evento: InputEvent) -> void:
	if TourGuiado.em_andamento():
		return   # o tour do tutorial está aberto
	if not _controles.evento_permitido(evento, missao.agente_atual()):
		get_viewport().set_input_as_handled()
		return
	if not (evento is InputEventJoypadButton or evento is InputEventJoypadMotion):
		return
	var destinos := missao.destinos()
	var dir := Entrada.direcao(evento)
	if dir != Vector2i.ZERO and not destinos.is_empty():
		if not _cursor_ativo:
			_cursor_ativo = true
			_cursor = missao.posicao(missao.agente_atual())
		_cursor = _mapa3d.vizinho_na_direcao(_cursor, dir)
		_mapa3d.mostrar_cursor(_cursor, true)
		get_viewport().set_input_as_handled()
	elif _cursor_ativo and evento.is_action_pressed("confirmar"):
		_enviar("mover", {"hex": Comandos.vetor(_cursor)})
		get_viewport().set_input_as_handled()
	elif _cursor_ativo and evento.is_action_pressed("cancelar"):
		_cursor_ativo = false
		_mapa3d.mostrar_cursor(_cursor, false)
		_focar_para_controle()
		get_viewport().set_input_as_handled()


# --- Ações -----------------------------------------------------------------

func _rolar() -> void:
	_enviar("rolar_movimento", {"foco": _foco.consumir()})


func _descansar() -> void:
	_enviar("descansar")


func _encerrar_turno() -> void:
	_enviar("encerrar_turno")


func _testar_evento() -> void:
	_enviar("resolver_evento", {"foco": _foco.consumir()})


# --- Comandos (ADR 0007) ------------------------------------------------------

func _enviar(acao: String, args: Dictionary = {}) -> Dictionary:
	return sessao.enviar(Comandos.novo("mapa", acao, args))


## Aplica um comando do mapa (deste jogador ou, online, de outro) e atualiza a tela.
func _aplicar_comando(cmd: Dictionary) -> Dictionary:
	var res := Comandos.aplicar_mapa(missao, cmd)
	var a := missao.agente_atual()
	match String(cmd.get("acao", "")):
		"rolar_movimento":
			if a != null and _controles.usa_controle(a) and not missao.destinos().is_empty():
				_cursor_ativo = true   # depois de rolar, o direcional já move o cursor
				_cursor = missao.posicao(a)
				_mapa3d.mostrar_cursor(_cursor, true)
		"mover":
			if res.ok:
				_cursor_ativo = false
				_mapa3d.focar_agente(missao)
				_focar_para_controle()
	_atualizar()
	return res


func _exit_tree() -> void:
	if sessao != null:
		sessao.sair("mapa")
		if sessao.comando_aplicado.is_connected(_ao_comando_aplicado):
			sessao.comando_aplicado.disconnect(_ao_comando_aplicado)


## Comandos do mestre chegam em qualquer tela (a narração já entra no registro da missão).
func _ao_comando_aplicado(cmd: Dictionary, _res: Dictionary) -> void:
	if String(cmd.get("ctx", "")) == "mestre":
		_atualizar()


# --- Modo Mestre (Fase 8.3) ------------------------------------------------------

func _sou_mestre() -> bool:
	return bool(missao.opcoes.get("mestre", false)) and _controles.e_mestre_local()


func _montar_painel_mestre(painel: VBoxContainer) -> void:
	_btn_painel_mestre = _botao("Painel do mestre", func(): _painel_mestre.visible = not _painel_mestre.visible)
	painel.add_child(_btn_painel_mestre)
	_painel_mestre = PanelContainer.new()
	_painel_mestre.visible = false
	_painel_mestre.position = Vector2(16, 120)
	_painel_mestre.custom_minimum_size = Vector2(360, 0)
	add_child(_painel_mestre)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 5)
	_painel_mestre.add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Mestre (só você vê este painel e o mapa inteiro)"
	titulo.add_theme_color_override("font_color", Tema.MESTRE)
	caixa.add_child(titulo)
	_lbl_caso_mestre = Label.new()
	_lbl_caso_mestre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_caso_mestre.custom_minimum_size = Vector2(340, 0)
	caixa.add_child(_lbl_caso_mestre)
	var linha_n := HBoxContainer.new()
	caixa.add_child(linha_n)
	_txt_narrar = LineEdit.new()
	_txt_narrar.placeholder_text = "Narrar para o grupo…"
	_txt_narrar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_txt_narrar.text_submitted.connect(func(_t): _narrar())
	linha_n.add_child(_txt_narrar)
	linha_n.add_child(_botao("Narrar", _narrar))
	var linha_m := HBoxContainer.new()
	caixa.add_child(linha_m)
	linha_m.add_child(_rotulo("Membrana:"))
	linha_m.add_child(_botao("−5", _enviar_mestre.bind("membrana", {"valor": -5})))
	linha_m.add_child(_botao("+5", _enviar_mestre.bind("membrana", {"valor": 5})))
	_chk_hex_mestre = CheckBox.new()
	_chk_hex_mestre.text = "Clique no mapa escolhe o hex"
	caixa.add_child(_chk_hex_mestre)
	_lbl_hex_mestre = _rotulo("Hex: nenhum")
	caixa.add_child(_lbl_hex_mestre)
	var linha_e := HBoxContainer.new()
	caixa.add_child(linha_e)
	_opt_encontro_m = OptionButton.new()
	_opt_encontro_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_encontro_m.clip_text = true
	for e in missao.extras.get("encontros", []) + DadosJogo.ler("encontros").encontros:
		_opt_encontro_m.add_item(String(e.nome))
		_opt_encontro_m.set_item_metadata(_opt_encontro_m.item_count - 1, e.id)
	linha_e.add_child(_opt_encontro_m)
	linha_e.add_child(_botao("Pôr encontro", _por_no_hex.bind("encontro")))
	var linha_v := HBoxContainer.new()
	caixa.add_child(linha_v)
	_opt_evento_m = OptionButton.new()
	_opt_evento_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_evento_m.clip_text = true
	var ev_jogo := DadosJogo.ler("eventos")
	for e in missao.extras.get("eventos", []) + ev_jogo.eventos + ev_jogo.get("eventos_medo", []):
		_opt_evento_m.add_item(String(e.titulo))
		_opt_evento_m.set_item_metadata(_opt_evento_m.item_count - 1, e.id)
	linha_v.add_child(_opt_evento_m)
	linha_v.add_child(_botao("Pôr evento", _por_no_hex.bind("evento")))
	var linha_h := HBoxContainer.new()
	caixa.add_child(linha_h)
	linha_h.add_child(_botao("Revelar em volta", _no_hex.bind("revelar", {"raio": 2})))
	linha_h.add_child(_botao("Limpar hex", _no_hex.bind("limpar", {})))
	var linha_a := HBoxContainer.new()
	caixa.add_child(linha_a)
	_opt_agente_m = OptionButton.new()
	for a in missao.agentes:
		_opt_agente_m.add_item(a.nome)
		_opt_agente_m.set_item_metadata(_opt_agente_m.item_count - 1, a.id)
	linha_a.add_child(_opt_agente_m)
	_spin_valor_m = SpinBox.new()
	_spin_valor_m.min_value = 1
	_spin_valor_m.max_value = 50
	_spin_valor_m.value = 5
	linha_a.add_child(_spin_valor_m)
	var linha_a2 := HBoxContainer.new()
	caixa.add_child(linha_a2)
	linha_a2.add_child(_botao("Curar", _no_agente.bind("curar", 1)))
	linha_a2.add_child(_botao("Ferir", _no_agente.bind("ferir", 1)))
	linha_a2.add_child(_botao("+SAN", _no_agente.bind("sanidade", 1)))
	linha_a2.add_child(_botao("−SAN", _no_agente.bind("sanidade", -1)))


func _rotulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	return l


func _enviar_mestre(acao: String, args: Dictionary = {}) -> Dictionary:
	return sessao.enviar(Comandos.novo("mestre", acao, args))


func _narrar() -> void:
	if _txt_narrar.text.strip_edges() != "":
		_enviar_mestre("narrar", {"texto": _txt_narrar.text})
		_txt_narrar.text = ""


func _no_hex(acao: String, args: Dictionary) -> void:
	if missao.mapa.tem(_hex_mestre):
		var a := args.duplicate()
		a["hex"] = Comandos.vetor(_hex_mestre)
		_enviar_mestre(acao, a)


func _por_no_hex(tipo: String) -> void:
	var opt := _opt_encontro_m if tipo == "encontro" else _opt_evento_m
	if opt.selected >= 0:
		_no_hex(tipo, {"id": opt.get_item_metadata(opt.selected)})


func _no_agente(acao: String, sinal: int) -> void:
	if _opt_agente_m.selected >= 0:
		_enviar_mestre(acao, {"agente": _opt_agente_m.get_item_metadata(_opt_agente_m.selected), "valor": int(_spin_valor_m.value) * sinal})


func _atualizar_mestre() -> void:
	if _btn_painel_mestre == null:
		return
	var mestre := _sou_mestre()
	_btn_painel_mestre.visible = mestre
	_mapa3d.ver_tudo = mestre
	if not mestre:
		_painel_mestre.visible = false
		return
	var c := missao.caso
	_lbl_caso_mestre.text = "Quem: %s.\nO quê: %s.\nOnde: %s." % [c.sujeito.get("nome", "?"), c.acao.get("texto", "?"), c.local.get("nome", "?")] if c != null else ""
	if missao.mapa.tem(_hex_mestre):
		var cont: Dictionary = missao.mapa.conteudo(_hex_mestre)
		_lbl_hex_mestre.text = "Hex [%d, %d]: %s, %s" % [_hex_mestre.x, _hex_mestre.y, missao.mapa.terreno(_hex_mestre), cont.get("tipo", "vazio")]


func _ao_encontro(config: Dictionary) -> void:
	_atualizar()
	Som.tocar("encontro")   # algo viu o grupo: nota grave, fita falhando
	Tema.pulso_vhs(_vista, 0.9, 1.0)
	await get_tree().create_timer(1.0).timeout
	if _jogo != null and is_inside_tree():
		_jogo.ir_para_combate(config)


func _ao_investigar(_config: Dictionary) -> void:
	_atualizar()
	Som.tocar("pista")
	await get_tree().create_timer(1.0).timeout
	if _jogo != null and is_inside_tree():
		_jogo.ir_para_investigacao()


func _ao_encerrar(venceu: bool) -> void:
	var linhas := ["Operação encerrada no turno %d do mundo." % missao.turno_mundo,
		"Membrana: %d (%s)." % [missao.membrana.valor, missao.membrana.estado().get("nome", "")],
		"Pistas reunidas: %d." % missao.pistas]
	if missao.caso != null:
		for q in missao.caso.perguntas:
			linhas.append("%s %s%s" % ["[x]" if q.respondida else "[ ]", q.texto,
				"  — " + missao.caso.resposta(q.id) if q.respondida else ""])
	_painel_fim.mostrar("CASO ENCERRADO" if venceu else "MISSÃO FRACASSADA", linhas, venceu)


func _nova_missao() -> void:
	if _jogo != null:
		_jogo.voltar_para_base()
	else:
		get_tree().reload_current_scene()


func _clicar(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_mostrar_dica(evento.position)
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var h := _mapa3d.hex_em(evento.position)
		if _chk_hex_mestre != null and _chk_hex_mestre.button_pressed and _sou_mestre():
			_hex_mestre = h
			_mapa3d.mostrar_cursor(h, true)
			_atualizar()
			return
		_enviar("mover", {"hex": Comandos.vetor(h)})
		return
	if _mapa3d.rig.tratar_entrada(evento):
		_vista.accept_event()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and not MenuPausa.aberto(self) and not TourGuiado.em_andamento():
		get_viewport().set_input_as_handled()
		_pausar()
		return
	if _mapa3d != null and evento is InputEventKey and _mapa3d.rig.tratar_entrada(evento):
		get_viewport().set_input_as_handled()


## Pausa (docs/10). O mapa é salvo a cada passo: sair para a Base não perde nada.
func _pausar() -> void:
	var saidas: Array = []
	if _jogo != null and not _jogo.rede.eh_cliente():
		saidas.append(["Voltar à Base", func(): _jogo.ir_para_base(), ""])
		saidas.append(["Menu principal", func(): get_tree().change_scene_to_file.call_deferred(Jogo.CENA_TITULO), ""])
	MenuPausa.abrir(self, saidas)


## Arquivo do caso na abertura da missão (docs/10): o briefing datilografado em papel.
func _mostrar_briefing() -> void:
	var c := missao.caso
	var texto := ""
	if c != null:
		var perguntas: Array = c.perguntas.map(func(q): return "  [ ] " + String(q.texto))
		texto = "%s\n\nOBJETIVO: %s\n\nPERGUNTAS EM ABERTO:\n%s" % [c.resumo, c.objetivo, "\n".join(PackedStringArray(perguntas))]
	else:
		texto = "Uma ameaça paranormal foi detectada na região. Encontrem a origem e contenham-na."
	var d := DialogoPapel.perguntar(self, "Arquivo do caso", texto, "Iniciar operação", func(): pass, "Fechar", false)
	d.layer = 60   # o tour do tutorial (se abrir) fica por cima



func _registrar(texto: String) -> void:
	missao.historico.append(texto)
	_registrar_sem_guardar(texto)


func _registrar_sem_guardar(texto: String) -> void:
	if _log != null:
		_log.append_text(texto + "\n")


# --- Interface -------------------------------------------------------------

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Tema.fundo())

	_vista = SubViewportContainer.new()
	_vista.stretch = true
	Tema.veu(_vista)
	_vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	_vista.add_child(vp)
	_mapa3d = Mapa3D.new()
	vp.add_child(_mapa3d)
	_mapa3d.construir(missao.mapa, _terrenos)
	_vista.gui_input.connect(_clicar)
	add_child(_vista)

	# Topo à esquerda: turno, vez e a ficha curta do agente
	var topo := PanelContainer.new()
	topo.position = Vector2(16, 14)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	var vt := VBoxContainer.new()
	vt.add_theme_constant_override("separation", 2)
	topo.add_child(vt)
	_lbl_vez = Label.new()
	_lbl_vez.add_theme_color_override("font_color", Tema.OURO_CLARO)
	vt.add_child(_lbl_vez)
	_lbl_turno = Label.new()
	_lbl_turno.theme_type_variation = "Titulo"
	_lbl_turno.add_theme_font_size_override("font_size", Tema.FONTE_G)
	vt.add_child(_lbl_turno)
	_lbl_ficha = Label.new()
	_lbl_ficha.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	_lbl_ficha.add_theme_font_size_override("font_size", Tema.FONTE_P)
	vt.add_child(_lbl_ficha)

	# Topo central: a Membrana, com sigilo e estado
	var membrana := PanelContainer.new()
	membrana.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 14)
	membrana.grow_horizontal = Control.GROW_DIRECTION_BOTH
	membrana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(membrana)
	var hm := HBoxContainer.new()
	hm.add_theme_constant_override("separation", Tema.ESPACO_M)
	membrana.add_child(hm)
	var sig := Sigilo.new()
	sig.semente = 666
	sig.cor = Tema.SANGUE_CLARO
	sig.custom_minimum_size = Vector2(40, 40)
	hm.add_child(sig)
	var vm := VBoxContainer.new()
	vm.add_theme_constant_override("separation", 2)
	hm.add_child(vm)
	var tm := Label.new()
	tm.text = "MEMBRANA"
	tm.theme_type_variation = "Subtitulo"
	vm.add_child(tm)
	_barra_membrana = BarraMembrana.new()
	_barra_membrana.custom_minimum_size = Vector2(260, 14)
	_barra_membrana.show_percentage = false
	vm.add_child(_barra_membrana)
	_lbl_membrana = Label.new()
	_lbl_membrana.add_theme_font_size_override("font_size", Tema.FONTE_P)
	vm.add_child(_lbl_membrana)

	# Grupo embaixo à esquerda
	_grupo = HBoxContainer.new()
	_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grupo.add_theme_constant_override("separation", Tema.ESPACO_M)
	_grupo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, Tema.ESPACO_G)
	_grupo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_grupo)

	# Embaixo à direita: slots de d20 e o dock de ações (acima do relatório)
	var dock := VBoxContainer.new()
	dock.alignment = BoxContainer.ALIGNMENT_END
	dock.add_theme_constant_override("separation", Tema.ESPACO_M)
	dock.anchor_left = 1.0
	dock.anchor_right = 1.0
	dock.anchor_top = 1.0
	dock.anchor_bottom = 1.0
	dock.offset_left = -560
	dock.offset_right = -16
	dock.offset_bottom = -48
	dock.offset_top = -48
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock)
	_slots = HBoxContainer.new()
	_slots.alignment = BoxContainer.ALIGNMENT_END
	_slots.add_theme_constant_override("separation", 6)
	dock.add_child(_slots)
	_lbl_mov = Label.new()
	_lbl_mov.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_mov.add_theme_constant_override("outline_size", 6)
	_lbl_mov.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	dock.add_child(_lbl_mov)
	var botoes := PanelContainer.new()
	botoes.size_flags_horizontal = Control.SIZE_SHRINK_END
	dock.add_child(botoes)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", Tema.ESPACO_M)
	botoes.add_child(hb)
	_foco = PassoFoco.criar()
	hb.add_child(_foco)
	_btn_rolar = _botao("Rolar movimento", _rolar)
	_btn_rolar.theme_type_variation = "BotaoPrincipal"
	_btn_rolar.tooltip_text = "1 d20 por ponto de Agilidade; cada 11+ vale um passo"
	_btn_descansar = _botao("Descansar", _descansar)
	_btn_descansar.tooltip_text = "Só numa vila, uma vez por visita"
	_btn_encerrar = _botao("Encerrar turno", _encerrar_turno)
	for b in [_btn_rolar, _btn_descansar, _btn_encerrar]:
		hb.add_child(b)

	# Evento: bilhete no centro da tela (cartas e pastas)
	_painel_evento = PanelContainer.new()
	_painel_evento.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(20, 16)))
	_painel_evento.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_painel_evento.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_painel_evento.grow_vertical = Control.GROW_DIRECTION_BOTH
	_painel_evento.custom_minimum_size = Vector2(420, 0)
	_painel_evento.rotation_degrees = -1.0
	_painel_evento.visible = false
	add_child(_painel_evento)
	var ve := VBoxContainer.new()
	ve.add_theme_constant_override("separation", Tema.ESPACO_M)
	_painel_evento.add_child(ve)
	var te := Label.new()
	te.text = "EVENTO"
	te.theme_type_variation = "TextoPapel"
	var f := Tema.fonte_titulo()
	if f != null:
		te.add_theme_font_override("font", f)
	ve.add_child(te)
	_lbl_evento = Label.new()
	_lbl_evento.theme_type_variation = "TextoPapel"
	_lbl_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ve.add_child(_lbl_evento)
	_btn_testar = _botao("Testar", _testar_evento)
	_btn_testar.theme_type_variation = "BotaoPrincipal"
	ve.add_child(_btn_testar)

	# Relatório de campo recolhível, embaixo à direita
	_log = RelatorioCampo.new()
	_log.ancorar_embaixo_direita(544.0)
	add_child(_log)

	_dica = Label.new()
	_dica.visible = false
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_theme_stylebox_override("normal", Tema.caixa_papel(Vector2(8, 4)))
	_dica.add_theme_color_override("font_color", Tema.TINTA)
	_dica.add_theme_font_size_override("font_size", Tema.FONTE_P)
	add_child(_dica)

	var mestre := VBoxContainer.new()
	mestre.anchor_left = 1.0
	mestre.anchor_right = 1.0
	mestre.offset_left = -230
	mestre.offset_right = -70
	mestre.offset_top = 16
	add_child(mestre)
	_montar_painel_mestre(mestre)

	var cliente: bool = _jogo != null and _jogo.rede.eh_cliente()
	_painel_fim = RelatorioFim.new("Voltar ao saguão" if cliente else "Voltar à Base")
	_painel_fim.botao.pressed.connect(_nova_missao)
	_lbl_fim = _painel_fim.rotulo
	add_child(_painel_fim)


## Dica em papel sobre o hex sob o mouse: terreno, custo e o que se sabe dele.
func _mostrar_dica(pos: Vector2) -> void:
	var h := _mapa3d.hex_em(pos)
	if h == _hex_dica and _dica.visible:
		_dica.position = pos + Vector2(18, 14)
		return
	_hex_dica = h
	_dica.visible = missao.mapa.tem(h)
	if not _dica.visible:
		return
	var revelado := missao.mapa.revelado(h) or _mapa3d.ver_tudo
	var linhas: Array[String] = []
	if not revelado:
		linhas.append("Névoa do Outro Lado")
		linhas.append("Ninguém sabe o que há aqui.")
	else:
		var t: Dictionary = _terrenos.get(missao.mapa.terreno(h), {})
		var custo := int(t.get("custo", 1))
		linhas.append(String(t.get("nome", missao.mapa.terreno(h))))
		linhas.append("Intransponível" if custo < 0 else "Custo de movimento: %d" % custo)
		var tipo := String(missao.mapa.conteudo(h).get("tipo", ""))
		var nomes := {"encontro": "⚔ Encontro", "evento": "? Evento", "vila": "⌂ Vila (descanso)", "investigacao": "◎ Investigação",
			"objetivo": "✝ Covil", "inicio": "Ponto de partida"}
		if nomes.has(tipo):
			linhas.append(nomes[tipo])
		if h in missao.destinos():
			linhas.append("Clique para ir")
	_dica.text = "\n".join(linhas)
	_dica.reset_size()
	_dica.position = pos + Vector2(18, 14)


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	return b


func _atualizar() -> void:
	if _lbl_vez != null:
		_lbl_vez.text = _controles.faixa_da_vez(missao.agente_atual())
		if _lbl_vez.text == "" and missao.agente_atual() != null:
			_lbl_vez.text = "Vez de %s" % missao.agente_atual().nome
	if _mapa3d != null and missao.destinos().is_empty():
		_cursor_ativo = false
	if _mapa3d != null:
		_mapa3d.mostrar_cursor(_cursor, _cursor_ativo)
	if _lbl_turno == null:
		return
	var a := missao.agente_atual()
	_lbl_turno.text = "Turno %d do mundo" % missao.turno_mundo
	if a != null:
		_lbl_ficha.text = "%s · %s · NEX %d%%" % [a.nome, a.classe_id, a.nex]
	var ocupado := missao.ocupado()
	_btn_rolar.disabled = ocupado or missao.movimento_rolado
	_btn_descansar.disabled = not missao.pode_descansar()
	_btn_encerrar.disabled = ocupado
	_foco.definir(_foco.valor, a.pe_disponivel_no_turno() if a != null else 0)
	_lbl_mov.text = ("Movimento restante: %d · clique num hex azul" % missao.movimento_restante) if missao.movimento_rolado else "Role o movimento para andar."
	_desenhar_slots()
	var ev := missao.evento_pendente
	var abriu := not ev.is_empty() and not _painel_evento.visible
	_painel_evento.visible = not ev.is_empty()
	if not ev.is_empty():
		_lbl_evento.text = "%s\n\n%s" % [ev.evento.titulo, ev.evento.texto]
		if abriu:
			Som.tocar("papel")
			Tema.datilografar(_lbl_evento)
		_btn_testar.text = "%s testa %s (DT %d)" % [ev.agente.nome, missao.ruleset.pericia(ev.evento.pericia).nome, int(ev.evento.dt)]
	_barra_membrana.value = missao.membrana.valor
	Tema.membrana_na_tela(_vista, missao.membrana.valor)
	_lbl_membrana.text = "%d · %s   ·   Reforços %d   ·   Pistas %d" % [missao.membrana.valor, missao.membrana.estado().get("nome", ""), missao.reforcos, missao.pistas]
	_atualizar_mestre()
	_atualizar_grupo()
	_mapa3d.atualizar(missao, missao.destinos())


func _atualizar_grupo() -> void:
	var vez := missao.agente_atual()
	for i in missao.agentes_iniciais.size():
		var a: Agente = missao.agentes_iniciais[i]
		var c: CartaoAgente = _cartoes.get(a)
		if c == null:
			c = CartaoAgente.criar(a, CORES_AGENTES[i % CORES_AGENTES.size()])
			_grupo.add_child(c)
			_cartoes[a] = c
		c.visible = a in missao.agentes and not a.tem(Ser.MORTO)
		if c.visible:
			c.atualizar(a == vez)


func _desenhar_slots() -> void:
	var mov := missao.ultimo_movimento
	if mov == _slots_desenhados:   # não repete a animação a cada atualização
		return
	_slots_desenhados = mov.duplicate()
	for filho in _slots.get_children():
		filho.queue_free()
	if mov.is_empty():
		return
	for i in mov.slots.size():
		var v: int = mov.slots[i]
		_slots.add_child(Tema.slot_d20(v, "sucesso" if v >= int(mov.dt) else "falha", i))
