extends Control
## Mapa-múndi da missão em 3D low poly (Mapa3D) com o painel de controle ao lado.
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
var _spin_foco: SpinBox
var _btn_rolar: Button
var _btn_descansar: Button
var _btn_encerrar: Button
var _barra_membrana: ProgressBar
var _lbl_membrana: Label
var _painel_evento: VBoxContainer
var _lbl_evento: Label
var _btn_testar: Button
var _log: RichTextLabel
var _painel_fim: PanelContainer
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
	var foco := int(_spin_foco.value)
	_spin_foco.value = 0
	_enviar("rolar_movimento", {"foco": foco})


func _descansar() -> void:
	_enviar("descansar")


func _encerrar_turno() -> void:
	_enviar("encerrar_turno")


func _testar_evento() -> void:
	var foco := int(_spin_foco.value)
	_spin_foco.value = 0
	_enviar("resolver_evento", {"foco": foco})


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
	_painel_mestre.position = Vector2(12, 12)
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
	await get_tree().create_timer(1.0).timeout
	if _jogo != null and is_inside_tree():
		_jogo.ir_para_combate(config)


func _ao_investigar(_config: Dictionary) -> void:
	_atualizar()
	await get_tree().create_timer(1.0).timeout
	if _jogo != null and is_inside_tree():
		_jogo.ir_para_investigacao()


func _ao_encerrar(venceu: bool) -> void:
	_lbl_fim.text = "MISSÃO CUMPRIDA" if venceu else "MISSÃO FRACASSADA"
	_painel_fim.visible = true


func _nova_missao() -> void:
	if _jogo != null:
		_jogo.voltar_para_base()
	else:
		get_tree().reload_current_scene()


func _clicar(evento: InputEvent) -> void:
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
	if _mapa3d != null and evento is InputEventKey and _mapa3d.rig.tratar_entrada(evento):
		get_viewport().set_input_as_handled()


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

	var raiz := HBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	_vista = SubViewportContainer.new()
	_vista.stretch = true
	Tema.veu(_vista)
	_vista.custom_minimum_size = Vector2(680, 0)
	_vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	_vista.add_child(vp)
	_mapa3d = Mapa3D.new()
	vp.add_child(_mapa3d)
	_mapa3d.construir(missao.mapa, _terrenos)
	_vista.gui_input.connect(_clicar)
	# O 3D fica numa área com o HUD do grupo por cima (docs/08, R3)
	var area := Control.new()
	area.custom_minimum_size = _vista.custom_minimum_size
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vista.custom_minimum_size = Vector2.ZERO
	_vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.add_child(_vista)
	_grupo = HBoxContainer.new()
	_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grupo.add_theme_constant_override("separation", Tema.ESPACO_M)
	_grupo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, Tema.ESPACO_G)
	_grupo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	area.add_child(_grupo)
	raiz.add_child(area)

	var painel := VBoxContainer.new()
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.add_theme_constant_override("separation", 6)
	raiz.add_child(Tema.painel(painel, true))

	_lbl_vez = Label.new()
	_lbl_vez.add_theme_font_size_override("font_size", 18)
	_lbl_vez.add_theme_color_override("font_color", Tema.OURO_CLARO)
	painel.add_child(_lbl_vez)
	_lbl_turno = Label.new()
	_lbl_turno.add_theme_font_size_override("font_size", 17)
	painel.add_child(_lbl_turno)
	_lbl_ficha = Label.new()
	_lbl_ficha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(_lbl_ficha)

	_slots = HBoxContainer.new()
	painel.add_child(_slots)
	_lbl_mov = Label.new()
	painel.add_child(_lbl_mov)

	var linha_foco := HBoxContainer.new()
	painel.add_child(linha_foco)
	var lbl := Label.new()
	lbl.text = "Foco (PE → +1 d20):"
	linha_foco.add_child(lbl)
	_spin_foco = SpinBox.new()
	linha_foco.add_child(_spin_foco)

	var botoes := HBoxContainer.new()
	painel.add_child(botoes)
	_btn_rolar = _botao("Rolar movimento", _rolar)
	_btn_descansar = _botao("Descansar", _descansar)
	_btn_encerrar = _botao("Encerrar turno", _encerrar_turno)
	for b in [_btn_rolar, _btn_descansar, _btn_encerrar]:
		botoes.add_child(b)

	_painel_evento = VBoxContainer.new()
	_lbl_evento = Label.new()
	_lbl_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_evento.add_theme_color_override("font_color", Tema.OURO_CLARO)
	_painel_evento.add_child(_lbl_evento)
	_btn_testar = _botao("Testar", _testar_evento)
	_painel_evento.add_child(_btn_testar)
	painel.add_child(_painel_evento)

	var titulo := Label.new()
	titulo.text = "Membrana"
	titulo.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	painel.add_child(titulo)
	_barra_membrana = ProgressBar.new()
	_barra_membrana.custom_minimum_size = Vector2(0, 16)
	painel.add_child(_barra_membrana)
	_lbl_membrana = Label.new()
	_lbl_membrana.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(_lbl_membrana)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel.add_child(_log)

	_montar_painel_mestre(painel)

	var legenda := Label.new()
	legenda.text = "Vermelho: encontro · amarelo: evento · azul: início · branco: vila · esfera escura: covil\nCâmera: roda = zoom, botão direito = girar, WASD = deslizar"
	legenda.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	legenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(legenda)

	_painel_fim = PanelContainer.new()
	_painel_fim.visible = false
	_painel_fim.set_anchors_preset(Control.PRESET_CENTER)
	var caixa := VBoxContainer.new()
	_painel_fim.add_child(caixa)
	_lbl_fim = Label.new()
	_lbl_fim.add_theme_font_size_override("font_size", 28)
	caixa.add_child(_lbl_fim)
	var cliente: bool = _jogo != null and _jogo.rede.eh_cliente()
	caixa.add_child(_botao("Voltar ao saguão" if cliente else "Voltar à Base", _nova_missao))
	add_child(_painel_fim)


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	return b


func _atualizar() -> void:
	if _lbl_vez != null:
		_lbl_vez.text = _controles.faixa_da_vez(missao.agente_atual())
		_lbl_vez.visible = _lbl_vez.text != ""
	if _mapa3d != null and missao.destinos().is_empty():
		_cursor_ativo = false
	if _mapa3d != null:
		_mapa3d.mostrar_cursor(_cursor, _cursor_ativo)
	if _lbl_turno == null:
		return
	var a := missao.agente_atual()
	_lbl_turno.text = "Turno %d do mundo — vez de %s" % [missao.turno_mundo, a.nome if a != null else "—"]
	if a != null:
		_lbl_ficha.text = "%s (%s, NEX %d%%)\nPV %d/%d   PE %d/%d   SAN %d/%d" % [a.nome, a.classe_id, a.nex, a.pv, a.pv_maximo, a.pe, a.pe_maximo, a.san, a.san_maximo]
	var ocupado := missao.ocupado()
	_btn_rolar.disabled = ocupado or missao.movimento_rolado
	_btn_descansar.disabled = not missao.pode_descansar()
	_btn_encerrar.disabled = ocupado
	_spin_foco.max_value = a.pe_disponivel_no_turno() if a != null else 0
	_lbl_mov.text = "Movimento restante: %d" % missao.movimento_restante if missao.movimento_rolado else "Role o movimento para andar."
	_desenhar_slots()
	var ev := missao.evento_pendente
	_painel_evento.visible = not ev.is_empty()
	if not ev.is_empty():
		_lbl_evento.text = "%s — %s" % [ev.evento.titulo, ev.evento.texto]
		_btn_testar.text = "%s testa %s (DT %d)" % [ev.agente.nome, missao.ruleset.pericia(ev.evento.pericia).nome, int(ev.evento.dt)]
	_barra_membrana.value = missao.membrana.valor
	Tema.membrana_na_tela(_vista, missao.membrana.valor)
	_lbl_membrana.text = "%d — %s
Reforços da Ordem: %d   ·   Pistas: %d" % [missao.membrana.valor, missao.membrana.estado().get("nome", ""), missao.reforcos, missao.pistas]
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
