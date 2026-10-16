extends Control
## Cena de investigação (interface provisória): visão 3D aproximada à esquerda e o painel
## de ações à direita. Cada agente, na sua vez, procura pistas num ponto de interesse,
## facilita a investigação, ajuda um aliado ou usa uma habilidade, até a urgência acabar.

var cena: CenaInvestigacao
var missao: Missao
var _jogo: Node
var _ponto := ""

var _vista: SubViewportContainer
var _visao: Investigacao3D
var _lbl_topo: Label
var _lbl_agente: Label
var _lbl_ponto: Label
var _opt_pericia: OptionButton
var _spin_foco: SpinBox
var _chk_faro: CheckBox
var _chk_perito: CheckBox
var _chk_ecletico: CheckBox
var _opt_facilitar: OptionButton
var _chk_presteza: CheckBox
var _opt_aliado: OptionButton
var _opt_pericia_ajuda: OptionButton
var _caixa_habilidades: HBoxContainer
var _caso: RichTextLabel
var _log: RichTextLabel
var _botoes_acao: Array[Button] = []
var _painel_fim: PanelContainer
var _lbl_vez: Label
var _controles: ControleLocal
var _btn_procurar: Button
var _ultimo_agente: Agente
var sessao: Sessao


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
	Entrada.configurar()
	_controles = _jogo.controles() if _jogo != null and _jogo.missao == missao else ControleLocal.padrao()
	_montar_interface()
	cena.registro.connect(func(t): _log.append_text(t + "\n"))
	cena.terminou.connect(func(_r): _painel_fim.visible = true)
	# Registro do início da cena (emitido antes da conexão)
	_log.append_text("[b]%s[/b] — urgência %s (%d rodadas).\n[i]Pista básica:[/i] %s\n" % [cena.cena.nome, String(cena.urgencia.get("nome", "")).to_lower(), cena.rodadas_max, cena.cena.pista_basica])
	_atualizar()
	sessao.liberar()


# --- Interface -------------------------------------------------------------------

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color("0b0b10")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var raiz := HBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	_vista = SubViewportContainer.new()
	_vista.stretch = true
	_vista.custom_minimum_size = Vector2(620, 0)
	_vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	_vista.add_child(vp)
	_visao = Investigacao3D.new()
	vp.add_child(_visao)
	_visao.construir(cena.cena, cena.agentes)
	_vista.gui_input.connect(_entrada_3d)
	raiz.add_child(_vista)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(rolagem)
	var p := VBoxContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("separation", 4)
	rolagem.add_child(p)

	_lbl_vez = _label(p, 18)
	_lbl_vez.add_theme_color_override("font_color", Color("f7dc6f"))
	_lbl_topo = _label(p, 16)
	_lbl_agente = _label(p)
	var lp := HBoxContainer.new()
	p.add_child(lp)
	_lbl_ponto = _label(lp)
	_lbl_ponto.add_theme_color_override("font_color", Color("76d7c4"))
	_lbl_ponto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_botao(lp, "Próximo ponto", _proximo_ponto)

	var l1 := HBoxContainer.new()
	p.add_child(l1)
	_opt_pericia = OptionButton.new()
	_opt_pericia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_pericia.clip_text = true
	l1.add_child(_opt_pericia)
	_spin_foco = SpinBox.new()
	_spin_foco.prefix = "Foco"
	l1.add_child(_spin_foco)
	var l2 := HBoxContainer.new()
	p.add_child(l2)
	_chk_faro = _check(l2, "Faro p/ Pistas")
	_chk_perito = _check(l2, "Perito")
	_chk_ecletico = _check(l2, "Eclético")
	_btn_procurar = _botao(p, "Procurar pistas", _procurar)
	_botoes_acao.append(_btn_procurar)

	_label(p).text = "Facilitar a investigação"
	var l3 := HBoxContainer.new()
	p.add_child(l3)
	_opt_facilitar = OptionButton.new()
	_opt_facilitar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_facilitar.clip_text = true
	l3.add_child(_opt_facilitar)
	_chk_presteza = _check(l3, "Presteza")
	_botoes_acao.append(_botao(p, "Facilitar", _facilitar))

	_label(p).text = "Ajudar um aliado (DT 10)"
	var l4 := HBoxContainer.new()
	p.add_child(l4)
	_opt_aliado = OptionButton.new()
	l4.add_child(_opt_aliado)
	_opt_pericia_ajuda = OptionButton.new()
	_opt_pericia_ajuda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_pericia_ajuda.clip_text = true
	l4.add_child(_opt_pericia_ajuda)
	_botoes_acao.append(_botao(p, "Ajudar", _ajudar))

	_caixa_habilidades = HBoxContainer.new()
	p.add_child(_caixa_habilidades)
	var l5 := HBoxContainer.new()
	p.add_child(l5)
	_botoes_acao.append(_botao(l5, "Passar a vez", _passar))
	_botao(l5, "Sair da cena", _sair)

	_caso = RichTextLabel.new()
	_caso.bbcode_enabled = true
	_caso.fit_content = true
	p.add_child(_caso)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 170)
	p.add_child(_log)

	_painel_fim = PanelContainer.new()
	_painel_fim.visible = false
	_painel_fim.set_anchors_preset(Control.PRESET_CENTER)
	var caixa := VBoxContainer.new()
	_painel_fim.add_child(caixa)
	var t := Label.new()
	t.text = "Investigação encerrada"
	t.add_theme_font_size_override("font_size", 24)
	caixa.add_child(t)
	var b := Button.new()
	b.text = "Voltar ao mapa"
	b.pressed.connect(_voltar)
	caixa.add_child(b)
	add_child(_painel_fim)


func _label(pai: Control, tamanho: int = 14) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tamanho)
	pai.add_child(l)
	return l


func _check(pai: Control, texto: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = texto
	pai.add_child(c)
	return c


func _botao(pai: Control, texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	pai.add_child(b)
	return b


func _atualizar() -> void:
	var a := cena.agente_atual()
	_lbl_vez.text = _controles.faixa_da_vez(a)
	_lbl_vez.visible = _lbl_vez.text != ""
	if a != _ultimo_agente:
		_ultimo_agente = a
		if a != null and _controles.usa_controle(a) and is_inside_tree():
			_btn_procurar.grab_focus.call_deferred()
	_lbl_topo.text = "%s — rodada %d de %d%s" % [cena.cena.nome, mini(cena.rodada, cena.rodadas_max), cena.rodadas_max, "" if a == null else " — vez de %s" % a.nome]
	if a != null:
		_lbl_agente.text = "%s: PE %d/%d (+%d temp.)  SAN %d/%d" % [a.nome, a.pe, a.pe_maximo, a.pe_temporario, a.san, a.san_maximo]
	for b in _botoes_acao:
		b.disabled = a == null or cena.encerrada
	if _ponto != "" and not _ponto in cena.pontos_restantes:
		_ponto = ""
	if _ponto == "" and not cena.pontos_restantes.is_empty():
		_ponto = cena.pontos_restantes[0]
	var pt := cena.ponto(_ponto)
	_lbl_ponto.text = "Ponto escolhido: %s (clique na cena para trocar)" % pt.get("nome", "—")
	_opt_pericia.clear()
	if not pt.is_empty() and a != null:
		for per in pt.pericias:
			var bonus := a.bonus_pericia(per)
			_opt_pericia.add_item("%s (DT %d) — %dd20%+d%s" % [missao.ruleset.pericia(per).nome, int(pt.pericias[per]), maxi(1, a.dados_da_pericia(per)), bonus,
				"" if a.pode_usar_pericia(per) else " (exige treino)"])
			_opt_pericia.set_item_metadata(_opt_pericia.item_count - 1, per)
	_spin_foco.max_value = a.pe_disponivel_no_turno() if a != null else 0
	_chk_faro.visible = a != null and a.tem_habilidade("faro_para_pistas")
	_chk_perito.visible = a != null and not a.perito.is_empty()
	_chk_ecletico.visible = a != null and a.classe_id == "especialista"
	_chk_presteza.visible = a != null and a.tem_habilidade("presteza_atletica")
	_opt_facilitar.clear()
	for o in cena.cena.get("facilitar", []):
		for per in o.pericias:
			_opt_facilitar.add_item("%s — %s (DT %d)" % [o.texto, missao.ruleset.pericia(per).nome, int(o.pericias[per])])
			_opt_facilitar.set_item_metadata(_opt_facilitar.item_count - 1, [o.id, per])
	_opt_aliado.clear()
	_opt_pericia_ajuda.clear()
	if a != null:
		for aliado in cena.agentes:
			if aliado != a:
				_opt_aliado.add_item(aliado.nome)
				_opt_aliado.set_item_metadata(_opt_aliado.item_count - 1, aliado)
		for per in a.pericias:
			_opt_pericia_ajuda.add_item(missao.ruleset.pericia(per).nome)
			_opt_pericia_ajuda.set_item_metadata(_opt_pericia_ajuda.item_count - 1, per)
	for filho in _caixa_habilidades.get_children():
		filho.queue_free()
	if a != null:
		for hab in ["incansavel", "pensamento_agil", "guiado_pelo_paranormal"]:
			if a.tem_habilidade(hab):
				_botao(_caixa_habilidades, a.ruleset.poder(a.classe_id, hab).nome + " (2 PE)", _usar_extra.bind(hab))
		if a.tem_habilidade("na_trilha_certa"):
			_botao(_caixa_habilidades, "Na Trilha Certa", _trilha_certa.bind(a))
	var linhas: Array[String] = ["[b]Ficha do caso[/b]  ·  %s" % missao.caso.objetivo]
	if missao.caso.resumo != "":
		linhas.append("[i][color=#aab7b8]%s[/color][/i]" % missao.caso.resumo)
	for q in missao.caso.perguntas:
		var resp := missao.caso.resposta(q.id)
		linhas.append("%s %s  [color=#aab7b8](%d/%d)[/color]%s" % ["✔" if q.respondida else "•", q.texto, mini(int(q.encontradas), int(q.pistas_necessarias)), int(q.pistas_necessarias),
			"  → [color=#f7dc6f]%s[/color]" % resp if resp != "" else ""])
	_caso.text = "\n".join(linhas)
	_visao.atualizar(cena, _ponto)


# --- Co-op local e controles (ADR 0004) ---------------------------------------------

## Só o dispositivo do dono do agente da vez age na cena.
func _input(evento: InputEvent) -> void:
	if _controles != null and cena != null and not _controles.evento_permitido(evento, cena.agente_atual()):
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
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var pid := _visao.ponto_em(evento.position)
		if pid != "" and pid in cena.pontos_restantes:
			_ponto = pid
			_atualizar()
		return
	if _visao.rig.tratar_entrada(evento):
		_vista.accept_event()


func _procurar() -> void:
	if _opt_pericia.selected < 0:
		return
	var a := cena.agente_atual()
	var per: String = _opt_pericia.get_item_metadata(_opt_pericia.selected)
	var op := {}
	if _chk_faro.visible and _chk_faro.button_pressed:
		op["habilidades"] = ["faro_para_pistas"]
	if _chk_perito.visible and _chk_perito.button_pressed and per in a.perito:
		op["perito"] = true
	if _chk_ecletico.visible and _chk_ecletico.button_pressed:
		op["ecletico"] = true
	var foco := int(_spin_foco.value)
	_spin_foco.value = 0
	_enviar("procurar", {"ponto": _ponto, "pericia": per, "foco": foco, "opcoes": op})


func _facilitar() -> void:
	if _opt_facilitar.selected < 0:
		return
	var meta: Array = _opt_facilitar.get_item_metadata(_opt_facilitar.selected)
	var foco := int(_spin_foco.value)
	_spin_foco.value = 0
	_enviar("facilitar", {"opcao": meta[0], "pericia": meta[1], "foco": foco, "opcoes": {"presteza_atletica": _chk_presteza.visible and _chk_presteza.button_pressed}})


func _ajudar() -> void:
	if _opt_aliado.selected < 0 or _opt_pericia_ajuda.selected < 0:
		return
	_enviar("ajudar", {"aliado": Comandos.indice_na_cena(cena, _opt_aliado.get_item_metadata(_opt_aliado.selected)),
		"pericia": _opt_pericia_ajuda.get_item_metadata(_opt_pericia_ajuda.selected), "espirito_civico": true})


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
				_log.append_text("[color=#e67e22]Não dá para fazer esse teste (treino, PE ou habilidade).[/color]\n")
		"facilitar":
			if not res.ok:
				_log.append_text("[color=#e67e22]Não dá para fazer esse teste.[/color]\n")
			elif res.teste.get("sucesso", false):
				_visao.iluminar()
		"ajudar":
			if not res.ok:
				_log.append_text("[color=#e67e22]Não dá para ajudar agora.[/color]\n")
		"sair":
			if res.ok and _jogo != null:
				_jogo.voltar_da_investigacao(res.resultado)
			return res
	_atualizar()
	return res


func _exit_tree() -> void:
	if sessao != null:
		sessao.sair("investigacao")
