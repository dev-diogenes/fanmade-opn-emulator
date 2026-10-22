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
var _linha_tempo: HBoxContainer   ## a linha do tempo do Outro Lado (docs/53)
var _turno_visto := -1
var _painel_evento: PanelContainer
var _lbl_evento: Label
var _lbl_tipo_evento: Label   ## "EVENTO" ou, nas escolhas morais (docs/50), "ESCOLHA DIFÍCIL"
var _btn_testar: Button
var _btn_acao: Button
var _caso: PanelContainer
var _lbl_caso: RichTextLabel
var _btn_deduzir: Button
var _caixa_opcoes: VBoxContainer
var _bilhete_acao: PanelContainer
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
		_registrar("[b]Missão iniciada.[/b] O covil está em algum lugar a leste. A Membrana já começa a ceder.")
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


## Interlúdio (docs/48): a folha com quem está no hex; as escolhas viram o comando `interludio`.
func _descansar() -> void:
	if missao.pode_descansar() and not _interludio_aberto():
		PainelInterludio.abrir(self, missao, func(escolhas): _enviar("interludio", {"escolhas": escolhas}))


func _interludio_aberto() -> bool:
	return not find_children("*", "PainelInterludio", true, false).is_empty()


func _encerrar_turno() -> void:
	_enviar("encerrar_turno")


func _testar_evento(opcao: int = 0) -> void:
	_enviar("resolver_evento", {"foco": _foco.consumir(), "opcao": opcao})


## Opções do evento (docs/13): uma linha por perícia, com a DT; "seguir em frente" sem teste.
## Cada opção mostra os dados e a chance do agente da vez (docs/21, C2); a de maior chance
## ganha ★. Todas no mesmo estilo de papel: o foco do teclado não parece recomendação.
func _montar_opcoes_evento() -> void:
	for filho in _caixa_opcoes.get_children():
		if filho != _btn_testar:
			filho.queue_free()
	if _btn_testar.get_parent() != null:
		_btn_testar.get_parent().remove_child(_btn_testar)
	var a: Agente = missao.evento_pendente.get("agente")
	var ops := missao.opcoes_do_evento()
	var previsoes: Array = []
	for o in ops:
		previsoes.append({} if o.get("sem_teste", false) or a == null else a.prever_teste(String(o.pericia), int(o.dt), _foco.valor))
	var melhor := LinhaTeste.recomendada(previsoes)
	for i in ops.size():
		var o: Dictionary = ops[i]
		var b: Button = _btn_testar if i == 0 else Button.new()
		if i == 0:
			for c in b.pressed.get_connections():
				b.pressed.disconnect(c.callable)
		var texto := String(o.get("texto", ""))
		if o.get("sem_teste", false):
			b.text = "→ " + (texto if texto != "" else "Seguir em frente")
			b.theme_type_variation = "BotaoPapel"
		else:
			var per := String(o.pericia)
			var nome := String(missao.ruleset.pericia(per).get("nome", per))
			b.text = "%s%s\n   %s" % [texto if texto != "" else "Testar", "  ★" if i == melhor and ops.size() > 1 else "",
				LinhaTeste.texto(nome, previsoes[i], int(o.dt))]
			b.theme_type_variation = "BotaoPapel"
			b.tooltip_text = LinhaTeste.explicar(a, per, previsoes[i]) + ("\n★ a melhor chance de %s." % a.nome if i == melhor and a != null else "")
		b.disabled = LinhaTeste.bloqueada(previsoes[i])   # perícia que só vale treinada
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_testar_evento.bind(i))
		_caixa_opcoes.add_child(b)


## Ação do turno no mapa (docs/13): bilhete com itens e rituais, e em quem usar.
func _abrir_acao() -> void:
	if _bilhete_acao != null:
		_bilhete_acao.queue_free()
		_bilhete_acao = null
		return
	var a := missao.agente_atual()
	if a == null:
		return
	_bilhete_acao = PanelContainer.new()
	_bilhete_acao.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(16, 14)))
	_bilhete_acao.theme = Tema.tema_papel()
	_bilhete_acao.anchor_left = 1.0
	_bilhete_acao.anchor_right = 1.0
	_bilhete_acao.anchor_top = 1.0
	_bilhete_acao.anchor_bottom = 1.0
	_bilhete_acao.offset_left = -560
	_bilhete_acao.offset_right = -200
	_bilhete_acao.offset_bottom = -90
	_bilhete_acao.offset_top = -90
	_bilhete_acao.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bilhete_acao.rotation_degrees = -0.8
	add_child(_bilhete_acao)
	Som.tocar("papel")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_bilhete_acao.add_child(v)
	var t := Label.new()
	t.text = "AÇÃO DO TURNO"
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	v.add_child(t)
	var alvos := missao.alcance_de_toque()
	for item_id in missao.itens_fora_de_combate(a):
		var info := missao.ruleset.equipamento(item_id)
		for alvo in alvos:
			var b := Button.new()
			b.theme_type_variation = "BotaoPapel"
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = "%s (%d) em %s  ·  cura %s" % [info.nome, a.equipamento.count(item_id), "si" if alvo == a else alvo.nome, info.uso.cura]
			b.pressed.connect(func(): _fechar_acao(); _enviar("usar_item", {"item": item_id, "alvo": alvo.id}))
			v.add_child(b)
	for par in missao.rituais_fora_de_combate(a):
		var r := missao.ruleset.ritual(par[0])
		var pessoal := String(r.get("alcance", "")).begins_with("pessoal")
		for alvo in alvos:
			if pessoal and alvo != a:
				continue
			var b := Button.new()
			b.theme_type_variation = "BotaoPapel"
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_color_override("font_color", Color("5b2a86"))
			b.text = "✦ %s%s em %s  ·  %d PE" % [r.nome, "" if par[1] == "" else " " + par[1], "si" if alvo == a else alvo.nome, a.custo_ritual(par[0], par[1])]
			b.disabled = a.pe < a.custo_ritual(par[0], par[1])
			b.pressed.connect(func(): _fechar_acao(); _enviar("conjurar", {"ritual": par[0], "forma": par[1], "alvo": alvo.id}))
			v.add_child(b)
	var nota := Label.new()
	nota.text = "Alcance: você e quem está no mesmo hex."
	nota.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))   # docs/21: 5,5:1 no papel
	nota.add_theme_font_size_override("font_size", Tema.FONTE_P)
	v.add_child(nota)


func _fechar_acao() -> void:
	if _bilhete_acao != null:
		_bilhete_acao.queue_free()
		_bilhete_acao = null


## Ficha e inventário (F ou clique no retrato).
func _abrir_ficha(a: Agente) -> void:
	if a == null:
		return
	var usar := Callable()
	if a == missao.agente_atual() and missao.pode_agir_no_mapa():
		usar = func(item_id): _enviar("usar_item", {"item": item_id, "alvo": a.id})
	DossieAgente.abrir(self, a, usar)


# --- Comandos (ADR 0007) ------------------------------------------------------

func _enviar(acao: String, args: Dictionary = {}) -> Dictionary:
	return sessao.enviar(Comandos.novo("mapa", acao, args))


## Aplica um comando do mapa (deste jogador ou, online, de outro) e atualiza a tela.
func _aplicar_comando(cmd: Dictionary) -> Dictionary:
	# A perícia da opção do evento é lida antes: depois de resolver, o evento some
	var opcao_evento: Dictionary = {}
	if cmd.get("acao", "") == "resolver_evento" and not missao.evento_pendente.is_empty():
		var ops := missao.opcoes_do_evento()
		opcao_evento = ops[clampi(int(cmd.get("opcao", 0)), 0, ops.size() - 1)]
	var res := Comandos.aplicar_mapa(missao, cmd)
	var a := missao.agente_atual()
	_mostrar_rolagem(cmd, res, opcao_evento)
	match String(cmd.get("acao", "")):
		"rolar_movimento":
			if a != null and _controles.usa_controle(a) and not missao.destinos().is_empty():
				_cursor_ativo = true   # depois de rolar, o direcional já move o cursor
				_cursor = missao.posicao(a)
				_mapa3d.mostrar_cursor(_cursor, true)
		"deduzir":
			if res.ok:
				Som.tocar("pista" if res.deducao.acertou else "erro")
				if not res.deducao.get("ampliacao", {}).is_empty():
					Som.tocar("carimbo")   # a ficha ganha uma pergunta (docs/36)
		"relatar":
			if res.ok:
				Som.tocar("carimbo" if res.relatorio.acertou else "erro")
		"mover":
			if res.ok and a != null and missao.agentes.size() > 1 and missao.aliados_perto(a, missao.posicao(a)) == 0:
				missao._log("[color=#eda64a]⚠ %s está longe do grupo: numa luta, ninguém chega a tempo.[/color]" % a.nome)
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
	_painel_mestre.position = Vector2(280, 120)
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


## Rolagem no centro da tela (docs/13): movimento e testes de evento.
func _mostrar_rolagem(cmd: Dictionary, res: Dictionary, opcao_evento: Dictionary) -> void:
	if not res.get("ok", false) or not is_inside_tree():
		return
	match String(cmd.get("acao", "")):
		"usar_item":
			Som.tocar("clique")
		"conjurar":
			Som.tocar("ritual")
			Tema.pulso_vhs(_vista, 0.4, 0.4)
		"rolar_movimento":
			var r: Dictionary = res.get("rolagem", {})
			if not r.is_empty():
				RolagemDados.mostrar(self, "Movimento", String(r.get("atributo", "agi")), r.slots, int(r.dt),
					"%d de movimento" % int(r.total))
		"resolver_evento":
			var r: Dictionary = res.get("teste", {})
			var t = r.get("teste")
			var atraso := 0.0
			if t is ResultadoTeste:
				var per := String(opcao_evento.get("pericia", ""))
				RolagemDados.mostrar(self, missao.ruleset.pericia(per).get("nome", per), missao.ruleset.atributo_da_pericia(per),
					t.slots, t.dt, "%d %+d = %d  →  %s" % [t.escolhido, t.bonus, t.total, "SUCESSO" if t.sucesso else "FALHA"],
					RolagemDados.estados_do_teste(t), t.sucesso)
				atraso = RolagemDados.duracao_ate_resultado(t.slots.size()) + 0.6
			# Desfecho (docs/16, E1): o que aconteceu e os efeitos, depois da rolagem
			BilheteDesfecho.mostrar(self, String(r.get("titulo", "Evento")), String(r.get("texto", "")), r.get("efeitos", []),
				null if r.get("sem_teste", false) else r.get("sucesso", null), atraso)


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


## Conclusão do Caso (p.79, docs/37): a ficha do grupo é o que vale. O carimbo diz se o caso
## foi solucionado (ameaça vencida e a ficha responde o objetivo) ou só contido.
func _ao_encerrar(venceu: bool) -> void:
	var linhas := ["CONCLUSÃO DO CASO — o que a ficha do grupo responde:"]
	if missao.caso != null:
		for q in missao.caso.perguntas:
			linhas.append("%s %s%s" % ["[x]" if q.respondida else "[ ]", q.texto,
				"  — " + missao.caso.resposta(q.id) if q.respondida else ""])
	linhas.append("")
	var solucionado := missao.caso_solucionado()
	if solucionado:
		linhas.append("Caso solucionado: a ameaça caiu e a ficha responde o objetivo.")
	elif venceu:
		linhas.append("Ameaça contida, caso em aberto: falta na ficha %s" % ", ".join(PackedStringArray(missao.caso.faltam_para_solucao())).to_lower())
	linhas.append("Turno %d do mundo · Membrana %d (%s) · pistas reunidas: %d." % [missao.turno_mundo, missao.membrana.valor,
		missao.membrana.estado().get("nome", ""), missao.pistas])
	if missao.inocentes_mortos > 0:
		linhas.append("Inocentes mortos: %d." % missao.inocentes_mortos)
	var carimbo := "CASO SOLUCIONADO" if solucionado else ("AMEAÇA CONTIDA" if venceu else "MISSÃO FRACASSADA")
	_painel_fim.mostrar(carimbo, linhas, venceu, Color("a5651a") if venceu and not solucionado else Color(0, 0, 0, 0))


## A linha do tempo do Outro Lado (docs/53): um bilhete por turno do mundo que vem, com dia
## ou noite e o que se prevê (a Membrana mudando, algo surgindo, a caçada, o covil abrindo).
func _desenhar_linha_tempo() -> void:
	for f in _linha_tempo.get_children():
		f.queue_free()
	for t in missao.previsao(5):
		var p := PanelContainer.new()
		var noite: bool = t.noite
		p.add_theme_stylebox_override("panel", Tema.caixa(Color("1b2240") if noite else Color(Tema.PERGAMINHO, 0.12),
			Color("4a5a9a") if noite else Color(Tema.OURO_ESCURO, 0.6), 1, 3, Vector2(4, 2)))
		p.custom_minimum_size = Vector2(44, 0)
		p.mouse_filter = Control.MOUSE_FILTER_PASS
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)
		var cab := Label.new()
		cab.text = "%d %s" % [int(t.turno), "☾" if noite else "·"]
		cab.add_theme_font_size_override("font_size", Tema.FONTE_P - 2)
		cab.add_theme_color_override("font_color", Color("b4c3ff") if noite else Tema.TEXTO_SUAVE)
		cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(cab)
		var dicas: Array[String] = ["Turno %d do mundo, %s." % [int(t.turno), "noite" if noite else "dia"]]
		for e in t.eventos:
			var l := Label.new()
			l.text = String(e.texto)
			l.add_theme_font_size_override("font_size", Tema.FONTE_P - 3)
			l.add_theme_color_override("font_color", Tema.PERIGO if String(e.id) in ["caca", "rompe"] else Tema.AVISO)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(l)
			dicas.append(String(e.texto).capitalize())
		p.tooltip_text = "\n".join(PackedStringArray(dicas))
		_linha_tempo.add_child(p)


## O turno do mundo vira um momento (docs/53): uma faixa no meio da tela, a fita treme, as
## ameaças que caçam andam, e a noite cai ou amanhece.
func _momento_do_turno() -> void:
	for passo in missao.passos_da_caca:
		_mapa3d.mover_marcador(passo.de, passo.para)
	var noite := missao.eh_noite()
	var virou := noite != missao.eh_noite(missao.turno_mundo - 1)
	var faixa := Label.new()
	faixa.text = "TURNO %d DO MUNDO%s" % [missao.turno_mundo, ("  ·  A NOITE CAI" if noite else "  ·  AMANHECE") if virou else ("  ·  NOITE" if noite else "")]
	faixa.add_theme_font_size_override("font_size", Tema.FONTE_G + 6)
	faixa.add_theme_color_override("font_color", Color("b4c3ff") if noite else Tema.OURO_CLARO)
	faixa.add_theme_constant_override("outline_size", 8)
	faixa.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	var ft := Tema.fonte_titulo()
	if ft != null:
		faixa.add_theme_font_override("font", ft)
	faixa.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	faixa.grow_horizontal = Control.GROW_DIRECTION_BOTH
	faixa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faixa.position.y -= 120
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.modulate.a = 0.0
	add_child(faixa)
	var tw := faixa.create_tween()
	tw.tween_property(faixa, "modulate:a", 1.0, 0.35)
	tw.tween_interval(1.4)
	tw.tween_property(faixa, "modulate:a", 0.0, 0.8)
	tw.tween_callback(faixa.queue_free)
	# A noite cai com o som do elemento do caso (docs/54)
	Som.tocar("estatica" if not virou else ("el_" + missao.caso.elemento if missao.caso != null and noite else "encontro"))
	Tema.pulso_vhs(_vista, 0.35 if not virou else 0.6, 0.6)


## Ficha de suspeitos (docs/32): o relatório vira o comando `relatar` e a acusação da
## reviravolta, `deduzir` (lockstep no online, docs/52).
func abrir_deducao(pergunta_id: String = "") -> PainelDeducao:
	if missao.caso == null or PainelDeducao.aberto(self):
		return null
	var pid := pergunta_id if pergunta_id != "" else PainelDeducao.pergunta_sugerida(missao.caso)
	return PainelDeducao.abrir(self, missao.caso, pid, func(q: String, c: String):
		_enviar("deduzir", {"pergunta": q, "candidato": c}),
		func(respostas: Dictionary): _enviar("relatar", {"respostas": respostas}))


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
	if Atalhos.pressionou(evento, "ficha") and not TourGuiado.em_andamento():
		get_viewport().set_input_as_handled()
		_abrir_ficha(missao.agente_atual())
		return
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
	DialogoPapel.perguntar(self, "Arquivo do caso", texto, "Iniciar operação", func(): pass, "Fechar", false)



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
	Qualidade.vista(vp)   # MSAA e escala 3D conforme a qualidade (docs/24)
	_vista.add_child(vp)
	_mapa3d = Mapa3D.new()
	vp.add_child(_mapa3d)
	_mapa3d.construir(missao.mapa, _terrenos)
	_vista.gui_input.connect(_clicar)
	add_child(_vista)
	# Sanidade com consequência (docs/17, E6)
	add_child(Alucinacoes.criar(_vista, _mapa3d, func(): return missao.agente_atual(),
		func(): return _mapa3d.posicao_hex(missao.posicao(missao.agente_atual())) if missao.agente_atual() != null else Vector3.ZERO,
		func(): return missao.agentes))

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

	# Rastreador do caso (docs/16, E3): as perguntas, quantas pistas faltam e o covil
	_caso = PanelContainer.new()
	_caso.position = Vector2(16, 120)
	_caso.custom_minimum_size = Vector2(250, 0)
	_caso.mouse_filter = Control.MOUSE_FILTER_PASS
	_caso.tooltip_text = "O caso: cada pista revela um traço do culpado. Com elas, acuse na ficha de suspeitos."
	add_child(_caso)
	var vc := VBoxContainer.new()
	vc.add_theme_constant_override("separation", 2)
	_caso.add_child(vc)
	var tc := Label.new()
	tc.text = "O CASO"
	tc.theme_type_variation = "Subtitulo"
	vc.add_child(tc)
	_lbl_caso = RichTextLabel.new()
	_lbl_caso.bbcode_enabled = true
	_lbl_caso.fit_content = true
	_lbl_caso.scroll_active = false
	_lbl_caso.custom_minimum_size = Vector2(250, 0)
	_lbl_caso.add_theme_font_size_override("normal_font_size", Tema.FONTE_P)
	_lbl_caso.add_theme_font_size_override("bold_font_size", Tema.FONTE_P)
	vc.add_child(_lbl_caso)
	_btn_deduzir = Button.new()
	_btn_deduzir.text = "Deduzir…"
	_btn_deduzir.tooltip_text = "Abrir a ficha de suspeitos e acusar (docs/32)"
	_btn_deduzir.pressed.connect(abrir_deducao)
	vc.add_child(_btn_deduzir)

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
	# Linha do tempo do Outro Lado (docs/53): os próximos turnos do mundo, como em For The King
	_linha_tempo = HBoxContainer.new()
	_linha_tempo.add_theme_constant_override("separation", 3)
	vm.add_child(_linha_tempo)

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
	dock.offset_bottom = -14
	dock.offset_top = -14
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock)
	_slots = HBoxContainer.new()
	_slots.alignment = BoxContainer.ALIGNMENT_END
	_slots.add_theme_constant_override("separation", 6)
	_slots.visible = false   # docs/21 (C4): só a rolagem central, como no combate
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
	_foco.mudou.connect(func(_v):   # o Foco muda a chance das opções do evento
		if missao != null and not missao.evento_pendente.is_empty():
			_montar_opcoes_evento())
	hb.add_child(_foco)
	_btn_rolar = _botao("Rolar movimento", _rolar)
	_btn_rolar.theme_type_variation = "BotaoPrincipal"
	_btn_rolar.tooltip_text = "1 d20 por ponto de Agilidade; cada 11+ vale um passo"
	_btn_descansar = _botao("Interlúdio", _descansar)
	_btn_descansar.tooltip_text = "Numa vila ou no ponto de encontro, uma vez por visita"
	_btn_encerrar = _botao("Encerrar", _encerrar_turno)
	_btn_encerrar.tooltip_text = "Encerrar o turno: a vez passa ao próximo agente"
	_btn_acao = _botao("Ação", _abrir_acao)
	_btn_acao.tooltip_text = "Uma ação por turno, além do movimento: usar um item ou um ritual que não seja de ataque"
	for b in [_btn_rolar, _btn_acao, _btn_descansar, _btn_encerrar]:
		hb.add_child(b)

	# Evento: bilhete no centro da tela (cartas e pastas)
	_painel_evento = PanelContainer.new()
	_painel_evento.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(20, 16)))
	_painel_evento.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_painel_evento.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_painel_evento.grow_vertical = Control.GROW_DIRECTION_BOTH
	_painel_evento.custom_minimum_size = Vector2(500, 0)   # cabe a linha do teste com a chance (docs/21)
	_painel_evento.rotation_degrees = -1.0
	_painel_evento.visible = false
	add_child(_painel_evento)
	var ve := VBoxContainer.new()
	ve.add_theme_constant_override("separation", Tema.ESPACO_M)
	_painel_evento.add_child(ve)
	_lbl_tipo_evento = Label.new()
	_lbl_tipo_evento.text = "EVENTO"
	_lbl_tipo_evento.theme_type_variation = "TextoPapel"
	var f := Tema.fonte_titulo()
	if f != null:
		_lbl_tipo_evento.add_theme_font_override("font", f)
	ve.add_child(_lbl_tipo_evento)
	_lbl_evento = Label.new()
	_lbl_evento.theme_type_variation = "TextoPapel"
	_lbl_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ve.add_child(_lbl_evento)
	# Uma linha por opção (docs/13); o primeiro botão é o _btn_testar (foco do controle)
	_caixa_opcoes = VBoxContainer.new()
	_caixa_opcoes.add_theme_constant_override("separation", 4)
	ve.add_child(_caixa_opcoes)
	_btn_testar = _botao("Testar", _testar_evento)
	_caixa_opcoes.add_child(_btn_testar)

	# Relatório de campo recolhível, embaixo à direita
	_log = RelatorioCampo.new()
	_log.ancorar_em_cima_direita(440.0)
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
		if custo < 0 and t.get("escalavel", false):
			linhas.append("Escalável: só com um 20 nos dados de movimento (custo %d)" % int(t.get("custo_escalada", 2)))
		else:
			linhas.append("Intransponível" if custo < 0 else "Custo de movimento: %d" % custo)
		var tipo := String(missao.mapa.conteudo(h).get("tipo", ""))
		var nomes := {"encontro": "⚔ Encontro", "evento": "? Evento", "vila": "⌂ Vila (descanso)", "investigacao": "◎ Investigação",
			"objetivo": "✝ Covil", "inicio": "Ponto de partida",
			"mirante": "▲ Mirante: algo espera lá em cima"}
		if nomes.has(tipo):
			linhas.append(nomes[tipo])
		if tipo == "objetivo" and not missao.covil_aberto():
			linhas.append("Entrada escondida: responda \"Onde fica o covil?\"")
		var a := missao.agente_atual()
		if tipo in ["encontro", "objetivo"] and a != null:
			linhas.append("Entrariam na luta: %d agente(s)" % (1 + missao.aliados_perto(a, h)))
		if h in missao.destinos():
			linhas.append("Clique para ir")
			# Grupo separado (docs/42): longe de todos, a luta seria sozinho
			if a != null and missao.agentes.size() > 1 and missao.aliados_perto(a, h) == 0:
				linhas.append("⚠ Longe do grupo: se houver luta, %s luta sozinho" % a.nome)
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
	_motivos_mapa(a, ocupado)
	_btn_acao.disabled = not missao.pode_agir_no_mapa() or (missao.itens_fora_de_combate(a).is_empty() and missao.rituais_fora_de_combate(a).is_empty())
	_btn_encerrar.disabled = ocupado
	_foco.definir(_foco.valor, a.pe_disponivel_no_turno() if a != null else 0)
	_lbl_mov.text = ("Movimento restante: %d · clique num hex azul (âmbar: longe do grupo)" % missao.movimento_restante) if missao.movimento_rolado else "Role o movimento para andar."
	_desenhar_slots()
	var ev := missao.evento_pendente
	var abriu := not ev.is_empty() and not _painel_evento.visible
	_painel_evento.visible = not ev.is_empty()
	if not ev.is_empty():
		_lbl_evento.text = "%s\n\n%s" % [ev.evento.titulo, ev.evento.texto]
		# Escolha moral (docs/50): o cabeçalho avisa que nenhuma saída é de graça
		var moral: bool = ev.evento.get("moral", false)
		_lbl_tipo_evento.text = "ESCOLHA DIFÍCIL" if moral else "EVENTO"
		if moral:
			_lbl_tipo_evento.add_theme_color_override("font_color", Tema.SANGUE)
			_lbl_evento.text += "\n\nNenhuma saída é segura: estão em jogo vidas, tempo, Sanidade ou um covil mais forte."
		else:
			_lbl_tipo_evento.remove_theme_color_override("font_color")
		# Ajuda (docs/59, p.86): quem está no mesmo hex ajuda o teste
		var ajudantes: Array = missao.ajudantes_do_evento().map(func(x): return x.nome)
		if not ajudantes.is_empty():
			_lbl_evento.text += "\n\n%s %s junto: cada um testa a mesma perícia contra DT 10 e, passando, dá +1." % [
				" e ".join(PackedStringArray(ajudantes)), "está" if ajudantes.size() == 1 else "estão"]
		if abriu:
			Som.tocar("papel")
			Tema.datilografar(_lbl_evento)
			_montar_opcoes_evento()
	_barra_membrana.value = missao.membrana.valor
	Tema.membrana_na_tela(_vista, missao.membrana.valor)
	_mapa3d.clima_membrana(missao.membrana.valor)
	var prog := missao.progresso_do_caso()   # o Ato contra a Agenda (docs/53): progresso do caso, não "pistas"
	_lbl_membrana.text = "%d · %s   ·   Reforços %d   ·   Caso %d/%d" % [missao.membrana.valor, missao.membrana.estado().get("nome", ""), missao.reforcos,
		int(prog.firmes), int(prog.necessarias)]
	_lbl_membrana.tooltip_text = "Caso: pistas firmes que contam para o relatório à Ordem (duas por pergunta em aberto)."
	_desenhar_linha_tempo()
	_mapa3d.atualizar_pressagios(missao)
	_mapa3d.atualizar_rastros(missao.rastros, Tema.ELEMENTO.get(missao.caso.elemento if missao.caso != null else "sangue", Tema.SANGUE_CLARO))
	if missao.turno_mundo != _turno_visto:
		var primeiro := _turno_visto < 0
		_turno_visto = missao.turno_mundo
		_mapa3d.ciclo(missao.eh_noite(), primeiro)
		if not primeiro:
			_momento_do_turno()
	_atualizar_mestre()
	_atualizar_grupo()
	_atualizar_caso()
	_mapa3d.atualizar(missao, missao.destinos())


## Por que cada botão está apagado (docs/16, A2): o tooltip diz o motivo.
func _motivos_mapa(a: Agente, ocupado: bool) -> void:
	var evento := "Resolva o evento primeiro." if not missao.evento_pendente.is_empty() else ""
	_btn_rolar.tooltip_text = "1 d20 por ponto de Agilidade, mais 2; cada 11+ vale um passo." if not _btn_rolar.disabled else \
		(evento if evento != "" else "O movimento deste turno já foi rolado.")
	var tipo := String(missao.mapa.conteudo(missao.posicao(a)).get("tipo", "")) if a != null else ""
	_btn_descansar.tooltip_text = "Dormir, relaxar, comer, treinar, ler ou revisar o caso: duas ações por agente (p.92)." if not _btn_descansar.disabled else \
		(evento if evento != "" else ("Já descansou aqui nesta visita." if tipo in ["vila", "inicio"] else "Só dá para descansar numa vila ou no ponto de encontro."))
	var sem_recurso := a != null and missao.itens_fora_de_combate(a).is_empty() and missao.rituais_fora_de_combate(a).is_empty()
	_btn_acao.tooltip_text = "Usar um item de cura ou um ritual de cura (uma vez por turno)." if not _btn_acao.disabled else \
		(evento if evento != "" else ("A ação deste turno já foi usada." if missao.acao_usada else
		("Sem itens de cura nem rituais que funcionem fora de combate." if sem_recurso else "Indisponível agora.")))
	_btn_encerrar.tooltip_text = "A vez passa ao próximo agente." if not _btn_encerrar.disabled else evento


func _atualizar_caso() -> void:
	var c := missao.caso
	_caso.visible = c != null
	if c == null:
		return
	var linhas: Array[String] = []
	var alguma_aberta := false
	var alguma_com_pista := false
	for q in c.perguntas:
		var feitas := mini(int(q.encontradas), int(q.pistas_necessarias))
		if q.respondida:
			linhas.append(Tema.bb("✔ %s" % q.texto, Tema.cor_sucesso()) + "\n   " + Tema.bb(c.resposta(q.id), Tema.OURO_CLARO))
		else:
			alguma_aberta = true
			alguma_com_pista = alguma_com_pista or int(q.encontradas) > 0
			var marcas := "●".repeat(feitas) + "○".repeat(int(q.pistas_necessarias) - feitas)
			linhas.append("%s  %s" % [q.texto, Tema.bb(marcas, Tema.OURO)])
			# Os traços já revelados (docs/32): o jogador cruza na ficha de suspeitos
			var tracos: Array[String] = []
			for t in c.indicios_encontrados(q.id):
				tracos.append(String(Caso.indicio(t).get("rotulo", t)).to_lower())
			for t in c.indicios_duvidosos(q.id):   # depoimento incerto (docs/35)
				tracos.append(String(Caso.indicio(t).get("rotulo", t)).to_lower() + "?")
			if not tracos.is_empty():
				linhas.append("   " + Tema.bb(" · ".join(tracos), Tema.TEXTO_SUAVE))
	var rumo := missao.rumo_do_caso()   # rumo do caso (docs/53): sem pista à vista, para onde ir
	if rumo != "":
		linhas.append(Tema.bb("Sem pista à vista: há algo %s, na névoa." % rumo, Tema.AVISO))
	if c.elemento_confirmado():   # o elemento do caso (docs/52)
		linhas.append(Tema.bb("Elemento: %s" % c.nome_elemento(), Tema.ELEMENTO.get(c.elemento, Tema.OURO_CLARO)))
	_btn_deduzir.visible = alguma_aberta
	_btn_deduzir.disabled = not alguma_com_pista
	var obj := missao.mapa.encontrar("objetivo")
	var covil_visto := missao.mapa.tem(obj) and missao.mapa.revelado(obj)
	var estado_covil := "aberto: o confronto espera" if missao.covil_aberto() else ("avistado, entrada escondida" if covil_visto else "desconhecido")
	linhas.append(Tema.bb("Covil: " + estado_covil, Tema.PERIGO if missao.covil_aberto() else Tema.TEXTO_SUAVE))
	_lbl_caso.text = "\n".join(linhas)


func _atualizar_grupo() -> void:
	var vez := missao.agente_atual()
	for i in missao.agentes_iniciais.size():
		var a: Agente = missao.agentes_iniciais[i]
		var c: CartaoAgente = _cartoes.get(a)
		if c == null:
			c = CartaoAgente.criar(a, CORES_AGENTES[i % CORES_AGENTES.size()])
			c.custom_minimum_size.x = 150
			c.escolhido.connect(_abrir_ficha)
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
