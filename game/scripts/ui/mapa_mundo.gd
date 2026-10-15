extends Control
## Mapa-múndi da missão (provisório em 2D; a versão 3D low poly vem na Fase 2.4).
## Mostra o mapa hexagonal com névoa, os agentes e o que há em cada hex; o jogador
## rola o movimento (slots de d20), clica para andar e resolve eventos e encontros.

const TAMANHO_HEX := 25.0
const ORIGEM := Vector2(32, 34)
const COR_FUNDO := Color("0e1014")
const COR_NEVOA := Color("1a1d24")
const COR_BORDA := Color(0, 0, 0, 0.35)
const COR_ALCANCE := Color(0.35, 0.6, 1.0, 0.35)
const CORES_AGENTES := [Color("3d7bd9"), Color("27ae60"), Color("af7ac5"), Color("e67e22")]
const ICONES := {"inicio": "I", "vila": "V", "encontro": "!", "evento": "?", "objetivo": "X"}
const CORES_ICONES := {"inicio": Color("ecf0f1"), "vila": Color("ecf0f1"), "encontro": Color("ff6b6b"), "evento": Color("f7dc6f"), "objetivo": Color("ff2e2e")}

var missao: Missao
var _jogo: Node
var _terrenos: Dictionary

var _mapa: Control
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


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	if _jogo != null:
		missao = _jogo.missao if _jogo.missao != null else _jogo.nova_missao()
	else:
		missao = Missao.nova(randi() % 1000000)
	_terrenos = DadosJogo.ler("mapa").terrenos
	_montar_interface()
	for linha in missao.historico:
		_log.append_text(linha + "\n")
	if missao.historico.is_empty():
		_registrar("[b]Missão iniciada.[/b] O covil carmesim está em algum lugar a leste. A Membrana já começa a ceder.")
	missao.registro.connect(_registrar_sem_guardar)
	missao.encontro_iniciado.connect(_ao_encontro)
	missao.missao_encerrada.connect(_ao_encerrar)
	missao.turno_mudou.connect(func(_a): _atualizar())
	if missao.encerrada:
		_ao_encerrar(missao.vitoria)
	_atualizar()


# --- Ações -----------------------------------------------------------------

func _rolar() -> void:
	missao.rolar_movimento(int(_spin_foco.value))
	_spin_foco.value = 0
	_atualizar()


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
		var h := Hex.de_pixel(evento.position - ORIGEM, TAMANHO_HEX)
		if missao.mover(h):
			_atualizar()


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

	_mapa = Control.new()
	_mapa.custom_minimum_size = Vector2(sqrt(3.0) * TAMANHO_HEX * 16.5 + ORIGEM.x, 1.5 * TAMANHO_HEX * 10 + ORIGEM.y * 2)
	_mapa.draw.connect(_desenhar_mapa)
	_mapa.gui_input.connect(_clicar)
	raiz.add_child(_mapa)

	var painel := VBoxContainer.new()
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.add_theme_constant_override("separation", 6)
	raiz.add_child(painel)

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
	painel.add_child(_lbl_membrana)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel.add_child(_log)

	var legenda := Label.new()
	legenda.text = "I início  V vila  ! encontro  ? evento  X covil"
	legenda.add_theme_color_override("font_color", Color("7f8c8d"))
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
	_lbl_membrana.text = "%d — %s   |   Reforços da Ordem: %d   |   Pistas: %d" % [missao.membrana.valor, missao.membrana.estado().get("nome", ""), missao.reforcos, missao.pistas]
	_mapa.queue_redraw()


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


func _desenhar_mapa() -> void:
	var fonte := ThemeDB.fallback_font
	var destinos := missao.destinos()
	for h in missao.mapa.celulas:
		var centro := ORIGEM + Hex.para_pixel(h, TAMANHO_HEX)
		var pts := Hex.vertices(centro, TAMANHO_HEX - 1)
		if not missao.mapa.revelado(h):
			_mapa.draw_colored_polygon(pts, COR_NEVOA)
			continue
		var t: Dictionary = _terrenos.get(missao.mapa.terreno(h), {})
		_mapa.draw_colored_polygon(pts, Color(t.get("cor", "444444")))
		if destinos.has(h):
			_mapa.draw_colored_polygon(pts, COR_ALCANCE)
		var contorno := pts.duplicate()
		contorno.append(pts[0])
		_mapa.draw_polyline(contorno, COR_BORDA, 1.0)
		var tipo: String = missao.mapa.conteudo(h).get("tipo", "")
		if ICONES.has(tipo):
			_mapa.draw_string(fonte, centro + Vector2(-5, 6), ICONES[tipo], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CORES_ICONES[tipo])
	# Agentes (deslocados quando dividem o hex)
	var por_hex: Dictionary = {}
	for i in missao.agentes.size():
		var a: Agente = missao.agentes[i]
		if a.tem(Ser.MORTO):
			continue
		var h := missao.posicao(a)
		var n: int = por_hex.get(h, 0)
		por_hex[h] = n + 1
		var centro := ORIGEM + Hex.para_pixel(h, TAMANHO_HEX) + Vector2(-9 + 9 * n, -9 + 6 * (n % 2))
		var cor: Color = CORES_AGENTES[i % CORES_AGENTES.size()]
		if a.esta_fora_de_combate():
			cor = cor.darkened(0.6)
		_mapa.draw_circle(centro, 7, cor)
		if a == missao.agente_atual():
			_mapa.draw_arc(centro, 9, 0, TAU, 20, Color("f1c40f"), 2.0)
		_mapa.draw_string(fonte, centro + Vector2(-4, 4), a.nome.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
