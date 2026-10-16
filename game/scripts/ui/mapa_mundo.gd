extends Control
## Mapa-múndi da missão em 3D low poly (Mapa3D) com o painel de controle ao lado.
## O jogador rola o movimento (slots de d20), clica num hex para andar e resolve
## eventos e encontros. Câmera: roda = zoom, botão direito = girar, botão do meio
## ou WASD/setas = deslizar, Q/E = girar.

const COR_FUNDO := Color("0e1014")
const CORES_AGENTES := [Color("3d7bd9"), Color("27ae60"), Color("af7ac5"), Color("e67e22")]

var missao: Missao
var _jogo: Node
var _terrenos: Dictionary

var _vista: SubViewportContainer
var _mapa3d: Mapa3D
var _lbl_turno: Label
var _lbl_ficha: Label
var _slots: HBoxContainer
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


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	if _jogo != null:
		missao = _jogo.missao if _jogo.missao != null else _jogo.nova_missao()
	else:
		missao = Missao.nova(randi() % 1000000)
	_terrenos = DadosJogo.ler("mapa").terrenos
	Entrada.configurar()
	_controles = _jogo.controles() if _jogo != null else ControleLocal.padrao()
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
		if missao.mover(_cursor):
			_cursor_ativo = false
			_mapa3d.focar_agente(missao)
			_atualizar()
			_focar_para_controle()
		get_viewport().set_input_as_handled()
	elif _cursor_ativo and evento.is_action_pressed("cancelar"):
		_cursor_ativo = false
		_mapa3d.mostrar_cursor(_cursor, false)
		_focar_para_controle()
		get_viewport().set_input_as_handled()


# --- Ações -----------------------------------------------------------------

func _rolar() -> void:
	missao.rolar_movimento(int(_spin_foco.value))
	_spin_foco.value = 0
	_atualizar()
	var a := missao.agente_atual()
	if a != null and _controles.usa_controle(a) and not missao.destinos().is_empty():
		_cursor_ativo = true   # depois de rolar, o direcional já move o cursor
		_cursor = missao.posicao(a)
		_mapa3d.mostrar_cursor(_cursor, true)


func _descansar() -> void:
	missao.descansar()
	_atualizar()


func _encerrar_turno() -> void:
	missao.encerrar_turno()
	_atualizar()


func _testar_evento() -> void:
	missao.resolver_evento(int(_spin_foco.value))
	_spin_foco.value = 0
	_atualizar()


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
		if missao.mover(h):
			_mapa3d.focar_agente(missao)
			_atualizar()
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
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var raiz := HBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	_vista = SubViewportContainer.new()
	_vista.stretch = true
	_vista.custom_minimum_size = Vector2(680, 0)
	_vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	_vista.add_child(vp)
	_mapa3d = Mapa3D.new()
	vp.add_child(_mapa3d)
	_mapa3d.construir(missao.mapa, _terrenos)
	_vista.gui_input.connect(_clicar)
	raiz.add_child(_vista)

	var painel := VBoxContainer.new()
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.add_theme_constant_override("separation", 6)
	raiz.add_child(painel)

	_lbl_vez = Label.new()
	_lbl_vez.add_theme_font_size_override("font_size", 18)
	_lbl_vez.add_theme_color_override("font_color", Color("f7dc6f"))
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
	_lbl_evento.add_theme_color_override("font_color", Color("f7dc6f"))
	_painel_evento.add_child(_lbl_evento)
	_btn_testar = _botao("Testar", _testar_evento)
	_painel_evento.add_child(_btn_testar)
	painel.add_child(_painel_evento)

	var titulo := Label.new()
	titulo.text = "Membrana"
	titulo.add_theme_color_override("font_color", Color("aab7b8"))
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

	var legenda := Label.new()
	legenda.text = "Vermelho: encontro · amarelo: evento · azul: início · branco: vila · esfera escura: covil\nCâmera: roda = zoom, botão direito = girar, WASD = deslizar"
	legenda.add_theme_color_override("font_color", Color("7f8c8d"))
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
	caixa.add_child(_botao("Voltar à Base", _nova_missao))
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
	_lbl_membrana.text = "%d — %s
Reforços da Ordem: %d   ·   Pistas: %d" % [missao.membrana.valor, missao.membrana.estado().get("nome", ""), missao.reforcos, missao.pistas]
	_mapa3d.atualizar(missao, missao.destinos())


func _desenhar_slots() -> void:
	for filho in _slots.get_children():
		filho.queue_free()
	var mov := missao.ultimo_movimento
	if mov.is_empty():
		return
	for v in mov.slots:
		var caixa := PanelContainer.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("1e8449") if v >= int(mov.dt) else Color("4d5656")
		estilo.set_content_margin_all(5)
		caixa.add_theme_stylebox_override("panel", estilo)
		var l := Label.new()
		l.text = str(v)
		caixa.add_child(l)
		_slots.add_child(caixa)
