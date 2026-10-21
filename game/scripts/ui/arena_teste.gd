extends Control
## Combate tático na grade 3D (Arena), com HUD flutuante (docs/09): rodada e ficha no topo,
## Membrana no centro, último teste à direita, o grupo embaixo e as ações como cartas (1–5).
## Ritual e Item abrem um bilhete com as opções. Ataques fazem um close rápido no alvo.
##
## Controles: clique num ser para ver a ficha; "Mover" e clique numa célula destacada;
## "Atacar" e clique num inimigo; "Encerrar". Foco = PE gastos como +1 d20.

const COR_FUNDO := Tema.FUNDO
const COLUNAS := 14
const LINHAS := 9


## Arma de cada ser na arena
var armas: Dictionary = {}
var ruleset: RulesetOp2022
var dados: Dados
var combate: Combate
var fluxo: FluxoCombate
var sessao: Sessao
var grade: Grade
var membrana: Membrana
## true = a IA joga pelos agentes também, sem espera (usado pelo teste automático)
var autoplay := false
## Semente das rolagens (-1 = aleatória)
var semente := -1
## Configuração vinda do mapa (Jogo.combate_config); vazia = demonstração
var config: Dictionary = {}
var _vencedor := ""

var _modo := ""            ## "", "mover" ou "atacar"
var _selecionado: Ser
var _ultimo_teste: ResultadoTeste

# Nós da interface
var _vista: SubViewportContainer
var _tab3d: Tabuleiro3D
var _lbl_turno: Label
var _lbl_ficha: Label
var _slots: HBoxContainer
var _teste_desenhado = null
var _lbl_resultado: Label
var _btn_mover: Button
var _btn_atacar: Button
var _btn_encerrar: Button
var _btn_item: Button
var _btn_ritual: Button
var _btn_enigma: Button
var _btn_soltar: Button
var _btn_apagar: Button
var _btn_socorrer: Button
var _btn_manobra: MenuButton
var _chk_nl: Button
var _btn_levantar: Button
var _btn_pegar: Button
var _manobra_sel := ""   ## "agarrar", "derrubar", "desarmar" ou "empurrar" (docs/39)
var _btn_acalmar: Button
var _btn_item_combate: Button
var _lbl_vez: Label
var _controles: ControleLocal
var _cursor := Vector2i.ZERO
var _cursor_ativo := false
var _foco: PassoFoco
var _chk_ae: Button
var _mao: Control
var _cartas: Dictionary = {}
var _faixa_vez: PanelContainer     ## vez da ameaça (docs/21, C3)
var _faixa_nome: Label
var _faixa_intencao: Label
var _mao_abaixada := false
var _grupo: HBoxContainer
var _cartoes: Dictionary = {}
var _bilhete: PanelContainer
var _caixa_bilhete: VBoxContainer
var _bilhete_tipo := ""
var _ritual_sel: Array = []
var _item_sel := ""
var _barra_membrana: ProgressBar
var _lbl_membrana: Label
var _log: RelatorioCampo
var _painel_fim: RelatorioFim
var _lbl_fim: Label
var _btn_fim: Button
var _titulo_slots: Label
var _caixa_mestre: VBoxContainer
var _lbl_mestre: Label
var _opt_ataque_m: OptionButton
var _opt_hab_m: OptionButton


func _ready() -> void:
	_montar_interface()
	var jogo := get_node_or_null("/root/Jogo")
	if config.is_empty() and jogo != null and not jogo.combate_config.is_empty():
		config = jogo.combate_config
	sessao = jogo.sessao if jogo != null and not config.is_empty() else Sessao.new()
	sessao.entrar("combate", _aplicar_comando, func(): return fluxo.decisor() if fluxo != null else null, func(): return fluxo.hash_estado())
	sessao.comando_aplicado.connect(_ao_comando_aplicado)
	if not config.is_empty() and semente < 0:
		semente = int(config.get("semente", -1))
	iniciar_combate(semente if semente >= 0 else randi())
	Tutorial.botao_ajuda(self, "combate", _alvos_do_tutorial)
	Tutorial.ao_entrar("combate", self, _alvos_do_tutorial())


func _alvos_do_tutorial() -> Dictionary:
	return {"tabuleiro": _vista, "acoes": _btn_mover.get_parent(), "slots": _titulo_slots, "foco": _foco.get_parent(),
		"membrana": _barra_membrana, "encerrar": _btn_encerrar}


# --- Preparação ------------------------------------------------------------

func iniciar_combate(semente: int) -> void:
	Entrada.configurar()
	var jogo_c := get_node_or_null("/root/Jogo")
	_controles = jogo_c.controles() if jogo_c != null and not config.is_empty() else ControleLocal.padrao()
	ruleset = RulesetOp2022.carregar_padrao()
	dados = Dados.new(semente)
	var jogo := get_node_or_null("/root/Jogo")
	if not config.is_empty() and jogo != null and jogo.missao != null:
		membrana = jogo.missao.membrana   # o combate também enfraquece a Membrana da missão
	else:
		membrana = Membrana.carregar_padrao()
	membrana.estado_mudou.connect(func(e, _ant): _registrar("[color=#b98ae6]A Membrana está %s: %s[/color]" % [e.nome, e.descricao]))
	if config.is_empty():
		combate = Combate.new(ruleset, dados, {"lesoes": true, "inspiracao_resoluta": true, "presenca_perturbadora": true})
		grade = Grade.new(COLUNAS, LINHAS)
		combate.grade = grade
		combate.membrana = membrana
		_montar_mapa()
		_criar_lados()
	else:
		var montado := MontagemCombate.montar(ruleset, config, dados, membrana)
		combate = montado.combate
		grade = montado.grade
		armas = montado.armas
	fluxo = FluxoCombate.de_combate(ruleset, combate, grade, armas, membrana)
	fluxo.ia_para_agentes = autoplay
	fluxo.ameacas_pelo_mestre = bool(config.get("mestre", false)) and not autoplay
	fluxo.nova_rodada.connect(func(r): _registrar("[color=#a69b88]— Rodada %d —[/color]" % r))
	combate.registro.connect(_registrar)
	combate.ser_adicionado.connect(_ao_adicionar)
	if _tab3d != null:
		_tab3d.construir(grade, String(config.get("terreno", "")))   # o chão do hex do encontro (docs/22)
	combate.ataque_resolvido.connect(_ao_atacar)
	combate.ritual_conjurado.connect(_ao_conjurar)
	combate.combate_encerrado.connect(_ao_encerrar)
	combate.turno_perdido.connect(func(s, motivo): _registrar("%s perde o turno (%s)." % [s.nome, motivo]))
	combate.lesao_sofrida.connect(func(a, attr): _registrar("[color=#eda64a]%s sofre uma lesão: −1 %s permanente.[/color]" % [a.nome, attr.to_upper()]))
	fluxo.iniciar()
	for s in combate.participantes:
		if s is Ameaca and (s as Ameaca).enigma_pendente():
			_registrar("[color=#eda64a]Enigma de Medo — %s: %s Nada a fere até alguém decifrar (botão Decifrar).[/color]" % [s.nome, (s as Ameaca).enigma.get("texto", "")])
	var nomes := PackedStringArray()
	for s in combate.ordem:
		nomes.append("%s (%d)" % [s.nome, combate.iniciativas[s]])
	_registrar("[b]Combate iniciado.[/b] Ordem: %s" % ", ".join(nomes))
	_avancar()


func _montar_mapa() -> void:
	for y in range(1, 5):
		grade.terreno[Vector2i(6, y)] = Grade.PAREDE
	for c in [Vector2i(3, 6), Vector2i(10, 2), Vector2i(9, 6)]:
		grade.terreno[c] = Grade.COBERTURA
	for x in range(4, 9):
		grade.terreno[Vector2i(x, 7)] = Grade.DIFICIL


func _criar_lados() -> void:
	var posicoes := [Vector2i(1, 2), Vector2i(1, 5), Vector2i(2, 4)]
	var fichas: Array = DadosJogo.ler("grupo_inicial").agentes
	for k in fichas.size():
		var f: Dictionary = fichas[k]
		var r := CriacaoAgente.criar(ruleset, f)
		assert(r.agente != null, "Ficha inválida %s: %s" % [f.nome, r.erros])
		for item in f.get("equipamento", [f.arma]):
			r.agente.equipamento.append(item)
		r.agente.arma_id = f.arma
		_adicionar(r.agente, ruleset.arma(f.arma), posicoes[k % posicoes.size()])
	# Fichas de teste criadas para a arena (não são do livro).
	var cultista := {"pv": 14, "defesa": 12, "atributos": {"agi": 1, "for": 2, "vig": 1},
		"pericias": {"luta": {"dados": 1, "bonus": 5}, "vontade": {"dados": 1, "bonus": 2}}}
	var atirador := {"pv": 12, "defesa": 13, "atributos": {"agi": 2, "for": 1, "vig": 1},
		"pericias": {"pontaria": {"dados": 2, "bonus": 5}, "reflexos": {"dados": 2, "bonus": 5}}}
	var aberracao := {"pv": 30, "defesa": 14, "deslocamento": 12, "atributos": {"agi": 1, "for": 3, "vig": 3},
		"pericias": {"luta": {"dados": 2, "bonus": 8}, "fortitude": {"dados": 3, "bonus": 5}}, "resistencias": {"balistico": 2}}
	var garras := {"id": "garras", "nome": "Garras", "dano": "1d8", "margem": 19, "multiplicador": 2, "pericia": "luta", "soma_forca": true, "ataque": "corpo_a_corpo", "tipo_dano": "corte"}
	_adicionar(Ameaca.criar(ruleset, "Cultista", cultista), ruleset.arma("faca"), Vector2i(11, 1))
	_adicionar(Ameaca.criar(ruleset, "Cultista", cultista), ruleset.arma("machete"), Vector2i(12, 6))
	_adicionar(Ameaca.criar(ruleset, "Atirador", atirador), ruleset.arma("pistola"), Vector2i(13, 4))
	_adicionar(Ameaca.criar(ruleset, "Aberração", aberracao), garras, Vector2i(11, 4))


## Seres que surgem no meio do combate (cópias do escutado); a arma vem do FluxoCombate.
func _ao_adicionar(ser: Ser) -> void:
	_registrar("%s entra no combate." % ser.nome)


func _exit_tree() -> void:
	if sessao != null:
		sessao.sair("combate")
		if sessao.comando_aplicado.is_connected(_ao_comando_aplicado):
			sessao.comando_aplicado.disconnect(_ao_comando_aplicado)


## Comandos do mestre (narração, Membrana, cura…) chegam em qualquer tela.
func _ao_comando_aplicado(cmd: Dictionary, res: Dictionary) -> void:
	if String(cmd.get("ctx", "")) != "mestre":
		return
	if cmd.get("acao", "") == "narrar" and res.get("ok", false):
		_registrar("[color=#f2c6a0][b]Mestre:[/b] %s[/color]" % res.texto)
	_atualizar()


func _adicionar(ser: Ser, arma: Dictionary, pos: Vector2i) -> void:
	combate.adicionar(ser)
	grade.colocar(ser, pos)
	armas[ser] = arma


# --- Fluxo de turnos -------------------------------------------------------

## Passa para o próximo turno. Turnos da IA são jogados aqui (com uma pausa curta para
## o jogador acompanhar, exceto no autoplay). Para quando chega a vez de um agente.
## O passo a passo é o do FluxoCombate (o mesmo do piloto e da rede); aqui só entram as pausas.
## Enquanto a IA joga, a sessão fica ocupada (comandos de outros jogadores esperam); quem
## está atrasado na rede pula as pausas.
func _avancar() -> void:
	sessao.ocupado = true
	while true:
		_modo = ""
		var ser := fluxo.proximo()
		_selecionado = ser
		_atualizar()
		if ser == null:
			sessao.liberar()
			return
		if fluxo.decide_jogador(ser):
			_mostrar_faixa_vez(null)
			_focar_para_controle()
			sessao.liberar()
			return   # vez do jogador
		if not autoplay and not sessao.atrasado():
			_mostrar_faixa_vez(ser)
			await get_tree().create_timer(1.0).timeout   # tempo de ler a faixa (era 0,6)
			while TourGuiado.em_andamento() and is_inside_tree():
				await get_tree().create_timer(0.2).timeout   # a IA espera o tutorial fechar
			if not is_inside_tree():
				return
		fluxo.jogar_ia(ser)


# --- Co-op local e controles (ADR 0004) ------------------------------------

func _focar_para_controle() -> void:
	var a := _agente_da_vez()
	if a != null and _controles.usa_controle(a) and is_inside_tree() and _btn_atacar != null:
		_btn_atacar.grab_focus()


## Só o dispositivo do dono do agente da vez age. Com um controle, nos modos que pedem um
## quadrado (mover, atacar, ritual, granada…), o direcional move o cursor, A escolhe e B cancela.
func _input(evento: InputEvent) -> void:
	if _controles == null or TourGuiado.em_andamento():
		return
	if not _controles.evento_permitido(evento, _agente_da_vez()):
		get_viewport().set_input_as_handled()
		return
	if not (evento is InputEventJoypadButton or evento is InputEventJoypadMotion) or grade == null:
		return
	var agente := _agente_da_vez()
	if agente == null or _modo == "":
		_cursor_ativo = false
		return
	var dir := Entrada.direcao(evento)
	if dir != Vector2i.ZERO:
		if not _cursor_ativo:
			_cursor_ativo = true
			_cursor = grade.posicao(agente)
		_cursor = _tab3d.celula_na_direcao(_cursor, dir)
		_tab3d.mostrar_cursor(_cursor, true)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("confirmar") and _cursor_ativo:
		_cursor_ativo = false
		_clicar_celula(_cursor)
		_focar_para_controle()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("cancelar"):
		_cursor_ativo = false
		_modo = ""
		_atualizar()
		_focar_para_controle()
		get_viewport().set_input_as_handled()


func _pode_atacar(ser: Ser, alvo: Ser, arma: Dictionary) -> bool:
	return IaCombate.pode_atacar(combate, ser, alvo, arma)


# --- Ações do jogador -------------------------------------------------------

func _agente_da_vez() -> Agente:
	var s := fluxo.decisor() if fluxo != null else null
	return s as Agente if s is Agente else null   # hipnotizados jogam pela IA


# --- Comandos (ADR 0007) ------------------------------------------------------

## As ações do jogador viram comandos do ser da vez e passam pela sessão.
func _enviar(acao: String, args: Dictionary = {}) -> Dictionary:
	var cmd := Comandos.novo("combate", acao, args)
	cmd["ator"] = Comandos.ref(combate, combate.ser_atual())
	return sessao.enviar(cmd)


## Aplica um comando (deste jogador ou, online, de outro) e atualiza a tela.
func _aplicar_comando(cmd: Dictionary) -> Dictionary:
	var res := fluxo.aplicar(cmd)
	var ator := Comandos.ser(combate, cmd.get("ator", -1))
	match String(cmd.get("acao", "")):
		"mover":
			if res.ok:
				_registrar("%s se move." % ator.nome)
				for op in combate.oportunidades_pendentes:
					_registrar("%s pode fazer um ataque de oportunidade." % op.atacante.nome)
		"agredir":
			var r = res.get("ataque")
			if r != null:
				for extra in r.ataques_extras:
					_ultimo_teste = extra.teste
			if not res.ok:
				_registrar("[color=#eda64a]Ataque inválido (fora de alcance, sem ação ou PE).[/color]")
		"conjurar":
			if not res.get("ok", false):
				_registrar("[color=#eda64a]Não deu para conjurar: %s.[/color]" % res.get("erro", "?"))
		"granada":
			if not res.get("ok", false):
				_registrar("[color=#eda64a]Não deu: %s.[/color]" % res.get("erro", "?"))
		"contra":
			if not res.ok:
				_registrar("[color=#eda64a]Precisa estar ao lado da criatura (e de uma ação padrão).[/color]")
		"item":
			var nome_item: String = ruleset.equipamento(String(cmd.get("item", ""))).get("nome", "item")
			if res.ok:
				_registrar("%s usa %s em %s: +%d PV." % [ator.nome, nome_item, res.alvo.nome, int(res.cura)])
			else:
				_registrar("[color=#eda64a]Não dá para usar %s agora.[/color]" % nome_item)
		"manobra":
			if res.ok and String(cmd.get("tipo", "")) == "fintar":
				_registrar(" ".join(PackedStringArray(res.textos)))
			elif res.ok:
				_registrar("%s tenta %s: %s" % [ator.nome, String(cmd.get("tipo", "")), " ".join(PackedStringArray(res.textos))])
			else:
				_registrar("[color=#eda64a]Não dá: %s.[/color]" % res.get("erro", "?"))
		"levantar", "pegar_arma":
			if not res.ok:
				_registrar("[color=#eda64a]Sem ação de movimento.[/color]")
		"socorrer", "acalmar":
			if res.ok:
				_ultimo_teste = res.teste
				var feito := "sai de morrendo com 1 PV" if cmd.acao == "socorrer" else "volta a si com 1 SAN"
				_registrar("%s tenta %s em %s: %s" % [ator.nome, "primeiros socorros" if cmd.acao == "socorrer" else "acalmar",
					res.alvo.nome, (Tema.bb("%s %s." % [res.alvo.nome, feito], Tema.SUCESSO)) if res.teste.sucesso else Tema.bb("não deu certo.", Tema.AVISO)])
			else:
				_registrar("[color=#eda64a]Precisa estar ao lado do aliado e ter a ação padrão.[/color]")
		"decifrar":
			if res.ok:
				_ultimo_teste = res.teste
			else:
				_registrar("[color=#eda64a]Sem ação padrão para decifrar o enigma.[/color]")
		"encerrar_turno", "ia":
			if res.ok:
				_avancar()
			return res
		"sair":
			var jogo := get_node_or_null("/root/Jogo")
			if res.ok and jogo != null and not config.is_empty():
				jogo.voltar_do_combate(res.vencedor, combate.rendidos().size())
			return res
	_atualizar()
	return res


func _clicar_celula(celula: Vector2i) -> void:
	var amea := _ameaca_da_vez()
	if amea != null and _modo.begins_with("m_"):
		var alvo_m := grade.ocupante(celula)
		var modo := _modo
		_modo = ""
		match modo:
			"m_mover":
				_enviar("mover", {"celula": Comandos.vetor(celula)})
			"m_atacar":
				if alvo_m != null and alvo_m.lado != amea.lado:
					_enviar("agredir", {"alvo": Comandos.ref(combate, alvo_m), "arma": _opt_ataque_m.get_item_metadata(_opt_ataque_m.selected) if _opt_ataque_m.selected >= 0 else -1})
			"m_habilidade":
				if _opt_hab_m.selected >= 0:
					_enviar("habilidade", {"habilidade": _opt_hab_m.get_item_metadata(_opt_hab_m.selected), "alvo": Comandos.ref(combate, alvo_m), "celula": Comandos.vetor(celula)})
		_atualizar()
		return
	var agente := _agente_da_vez()
	var alvo := grade.ocupante(celula)
	if _modo == "mover" and agente != null:
		_modo = ""
		_enviar("mover", {"celula": Comandos.vetor(celula)})
	elif _modo == "granada" and agente != null:
		_modo = ""
		_enviar("granada", {"item": _item_sel, "celula": Comandos.vetor(celula)})
	elif _modo == "contra" and agente != null and alvo is Ameaca:
		_modo = ""
		_enviar("contra", {"alvo": Comandos.ref(combate, alvo), "item": _item_sel})
	elif _modo == "ritual_area" and agente != null:
		var escolha: Array = _ritual_sel
		_conjurar(agente, escolha[0], escolha[1], alvo, {"celula": celula})
		return
	elif _modo == "ritual" and agente != null and alvo != null:
		var escolha: Array = _ritual_sel
		var opcoes := {}
		var e := combate.efeito_do_ritual(escolha[0], escolha[1])
		if e.has("alvos"):
			opcoes["alvos"] = _alvos_do_lado(agente, alvo, e)
		_conjurar(agente, escolha[0], escolha[1], alvo, opcoes)
		return
	elif _modo == "manobra" and agente != null and alvo != null and alvo.lado != agente.lado:
		_modo = ""
		_enviar("manobra", {"alvo": Comandos.ref(combate, alvo), "tipo": _manobra_sel})
	elif _modo == "atacar" and agente != null and alvo != null and alvo.lado != agente.lado:
		var opcoes := {}
		if _chk_ae.button_pressed and agente.classe_id == "combatente":
			opcoes["ataque_especial"] = {"ataque": 5}
		if _chk_nl.visible and _chk_nl.button_pressed:
			opcoes["nao_letal"] = String(agente.arma().get("id", "")) != "desarmado"   # inverte o padrão
			_chk_nl.button_pressed = false
		_modo = ""
		_chk_ae.button_pressed = false
		_close(alvo, opcoes.has("ataque_especial"))
		_enviar("agredir", {"alvo": Comandos.ref(combate, alvo), "foco": _foco.consumir(), "opcoes": opcoes})
	elif alvo != null:
		_selecionado = alvo
	_atualizar()


func _ao_atacar(r: ResultadoAtaque) -> void:
	_ultimo_teste = r.teste
	var cor := "#5dade2" if r.atacante is Agente else "#ec7063"
	var txt := "[color=%s]%s[/color] → %s com %s: %s" % [cor, r.atacante.nome, r.alvo.nome, r.arma.get("nome", "?"), r.teste.descrever()]
	if r.reacao != "":
		txt += " [i](%s)[/i]" % r.reacao
	if _tab3d != null:
		_tab3d.animar_ataque(r.atacante)
	if not autoplay and is_inside_tree() and r.teste != null:
		var per := String(r.arma.get("pericia", "luta"))
		var resultado := ("%d de dano%s" % [r.dano, "  ·  CRÍTICO" if r.critico else ""]) if r.acertou else "errou"
		RolagemDados.mostrar(self, "Ataque de %s" % r.atacante.nome, ruleset.atributo_da_pericia(per), r.teste.slots, r.teste.dt,
			resultado, RolagemDados.estados_do_teste(r.teste), r.acertou)
	if r.acertou:
		txt += " → [b]%d de dano[/b]%s" % [r.dano, " [color=#e3c27a]CRÍTICO[/color]" if r.critico else ""]
		Som.tocar("golpe")
		if _tab3d != null:
			_tab3d.texto_flutuante(r.alvo, ("CRÍTICO −%d" if r.critico else "−%d") % r.dano, Tema.OURO_CLARO if r.critico else Tema.PERIGO, r.critico)
		if r.critico:
			Tema.pulso_vhs(_vista, 0.6, 0.45)
	else:
		Som.tocar("erro")
		if _tab3d != null:
			_tab3d.texto_flutuante(r.alvo, "ERROU", Tema.TEXTO_SUAVE)
	if r.pe_gasto > 0:
		txt += " (%d PE)" % r.pe_gasto
	_registrar(txt)
	if r.alvo.tem(Ser.MORRENDO):
		_registrar("[color=#e0574a]%s está morrendo![/color]" % r.alvo.nome)


## Por que cada carta está bloqueada (docs/16, A2).
func _motivos_cartas(agente: Agente, sem_padrao: bool) -> void:
	var motivos := {}
	if agente == null:
		for k in _cartas:
			motivos[k] = "Não é a vez de um agente seu."
	else:
		if sem_padrao:
			for k in ["atacar", "ritual", "item"]:
				motivos[k] = "Sem ação padrão neste turno."
		if not motivos.has("ritual") and _rituais_disponiveis(agente).is_empty():
			motivos["ritual"] = "%s não conhece rituais que possa conjurar agora." % agente.nome
		if not motivos.has("item") and not agente.tem_item("cicatrizante") and _itens_de_combate(agente).is_empty():
			motivos["item"] = "Sem itens de combate no inventário."
		if _btn_mover.disabled:
			motivos["mover"] = "Sem ação de movimento nem padrão neste turno."
	for k in _cartas:
		var carta: CartaAcao = _cartas[k]
		carta.tooltip_text = ("Bloqueado: " + String(motivos[k])) if carta.disabled and motivos.has(k) else String(carta.get_meta("dica", ""))


func _ao_conjurar(res: Dictionary) -> void:
	Som.tocar("ritual")
	if _tab3d != null and res.get("conjurador") is Ser:
		_tab3d.animar_ataque(res.conjurador, true)


func _ao_encerrar(vencedor: String) -> void:
	_vencedor = vencedor
	var texto := "VITÓRIA DA ORDEM" if vencedor == "agentes" else "OS AGENTES CAÍRAM"
	if _btn_fim != null and not config.is_empty():
		_btn_fim.text = "Voltar ao mapa"
	_registrar("[b]%s[/b]" % texto)
	if _painel_fim != null:
		var caidos := combate.participantes.filter(func(x): return x.lado != "agentes" and x.esta_fora_de_combate()).size()
		var inimigos := combate.participantes.filter(func(x): return x.lado != "agentes").size()
		var feridos := combate.participantes.filter(func(x): return x is Agente and x.esta_fora_de_combate()).size()
		var linhas := ["Confronto encerrado na rodada %d." % combate.rodada,
			"Ameaças neutralizadas: %d de %d." % [caidos, inimigos],
			"Agentes caídos: %d." % feridos,
			"Membrana ao fim do confronto: %d." % membrana.valor]
		_painel_fim.mostrar(texto, linhas, vencedor == "agentes")


func _registrar(texto: String) -> void:
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
	_tab3d = Tabuleiro3D.new()
	vp.add_child(_tab3d)
	_vista.gui_input.connect(_entrada_tabuleiro)
	add_child(_vista)
	# Sanidade com consequência (docs/17, E6)
	add_child(Alucinacoes.criar(_vista, _tab3d, func(): return _agente_da_vez(),
		func():
			var ag := _agente_da_vez()
			return _tab3d.posicao(grade.posicao(ag)) if ag != null and grade != null and grade.tem(ag) else Vector3.ZERO))

	# Topo à esquerda: rodada, vez e a ficha do ser escolhido
	var topo := PanelContainer.new()
	topo.position = Vector2(16, 14)
	topo.custom_minimum_size = Vector2(300, 0)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	var vt := VBoxContainer.new()
	vt.add_theme_constant_override("separation", 3)
	topo.add_child(vt)
	_lbl_vez = Label.new()
	_lbl_vez.add_theme_color_override("font_color", Tema.OURO_CLARO)
	vt.add_child(_lbl_vez)
	_lbl_turno = Label.new()
	_lbl_turno.theme_type_variation = "Titulo"
	_lbl_turno.add_theme_font_size_override("font_size", Tema.FONTE_G)
	vt.add_child(_lbl_turno)
	_lbl_ficha = Label.new()
	_lbl_ficha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_ficha.custom_minimum_size = Vector2(300, 0)
	_lbl_ficha.add_theme_font_size_override("font_size", Tema.FONTE_P)
	vt.add_child(_lbl_ficha)
	# Modo Mestre (Fase 8.3): só aparece na máquina do mestre, na vez de uma ameaça
	_caixa_mestre = VBoxContainer.new()
	_caixa_mestre.visible = false
	vt.add_child(_caixa_mestre)
	_lbl_mestre = Label.new()
	_lbl_mestre.add_theme_color_override("font_color", Tema.MESTRE)
	_caixa_mestre.add_child(_lbl_mestre)
	var linha_m := HBoxContainer.new()
	_caixa_mestre.add_child(linha_m)
	linha_m.add_child(_botao("Mover", _modo_mestre.bind("m_mover")))
	linha_m.add_child(_botao("IA joga", _ia_mestre))
	linha_m.add_child(_botao("Encerrar", _encerrar_mestre))
	var linha_m2 := HBoxContainer.new()
	_caixa_mestre.add_child(linha_m2)
	_opt_ataque_m = OptionButton.new()
	_opt_ataque_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_ataque_m.clip_text = true
	linha_m2.add_child(_opt_ataque_m)
	linha_m2.add_child(_botao("Atacar", _modo_mestre.bind("m_atacar")))
	var linha_m3 := HBoxContainer.new()
	_caixa_mestre.add_child(linha_m3)
	_opt_hab_m = OptionButton.new()
	_opt_hab_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_hab_m.clip_text = true
	linha_m3.add_child(_opt_hab_m)
	linha_m3.add_child(_botao("Usar", _modo_mestre.bind("m_habilidade")))

	# Topo central: a Membrana
	var mem := PanelContainer.new()
	mem.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 14)
	mem.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mem)
	var hm := HBoxContainer.new()
	hm.add_theme_constant_override("separation", Tema.ESPACO_M)
	mem.add_child(hm)
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
	_barra_membrana.max_value = 100
	_barra_membrana.show_percentage = false
	_barra_membrana.custom_minimum_size = Vector2(240, 14)
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

	# Último teste: slots de d20 no alto, à direita (o momento "vai dar o 20?")
	var teste := VBoxContainer.new()
	teste.anchor_left = 1.0
	teste.anchor_right = 1.0
	teste.offset_left = -360
	teste.offset_right = -70
	teste.offset_top = 16
	teste.alignment = BoxContainer.ALIGNMENT_BEGIN
	teste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teste.visible = false   # docs/21 (C4): a rolagem central já mostra os dados; o histórico fica no relatório
	add_child(teste)
	_titulo_slots = _titulo("Último teste")
	_titulo_slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	teste.add_child(_titulo_slots)
	_slots = HBoxContainer.new()
	_slots.alignment = BoxContainer.ALIGNMENT_END
	_slots.add_theme_constant_override("separation", 6)
	teste.add_child(_slots)
	_lbl_resultado = Label.new()
	_lbl_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_resultado.add_theme_constant_override("outline_size", 6)
	_lbl_resultado.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	teste.add_child(_lbl_resultado)

	# Cartas de ação, embaixo à direita (1–5)
	_mao = Control.new()
	_mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mao.anchor_left = 1.0
	_mao.anchor_right = 1.0
	_mao.anchor_top = 1.0
	_mao.anchor_bottom = 1.0
	var largura_carta := 118.0
	var altura_carta := 156.0
	_mao.offset_left = -5 * (largura_carta + 8) - 16
	_mao.offset_right = -16
	_mao.offset_top = -altura_carta - 60   # acima do relatório de campo (não encosta nele)
	_mao.offset_bottom = -60
	add_child(_mao)
	_montar_faixa_vez()
	# Dicas curtas (docs/19): cabem em duas linhas de 14 px; o detalhe vai no tooltip e no bilhete
	var defs := [["mover", "Mover", "Até uma célula azul", Tema.INFO, _modo_mover],
		["atacar", "Atacar", "Um inimigo marcado", Tema.SANGUE_CLARO, _modo_atacar],
		["ritual", "Ritual", "Conjurar com PE", Tema.ELEMENTO.energia, _abrir_bilhete.bind("ritual")],
		["item", "Item", "Curar ou usar item", Tema.OURO, _abrir_bilhete.bind("item")],
		["encerrar", "Encerrar", "Passa a vez", Tema.ELEMENTO.morte, _encerrar_turno]]
	for i in defs.size():
		var d: Array = defs[i]
		var carta := CartaAcao.criar(d[1], d[2], i + 1, 211 + i * 53, d[3])
		carta.custom_minimum_size = Vector2(largura_carta, altura_carta)
		carta.size = carta.custom_minimum_size
		carta._sigilo.custom_minimum_size = Vector2(0, 58)
		carta.position = Vector2(i * (largura_carta + 8), 0)
		carta.pressed.connect(d[4])
		_mao.add_child(carta)
		_cartas[d[0]] = carta
	_btn_mover = _cartas.mover
	_btn_atacar = _cartas.atacar
	_btn_ritual = _cartas.ritual
	_btn_item = _cartas.item
	_btn_encerrar = _cartas.encerrar

	# Acima das cartas: Foco, Ataque Especial e as ações de situação
	var extras := HBoxContainer.new()
	extras.anchor_left = 1.0
	extras.anchor_right = 1.0
	extras.anchor_top = 1.0
	extras.anchor_bottom = 1.0
	extras.offset_left = _mao.offset_left
	extras.offset_right = -16
	extras.offset_top = _mao.offset_top - 48
	extras.offset_bottom = _mao.offset_top - 10
	extras.alignment = BoxContainer.ALIGNMENT_END
	extras.add_theme_constant_override("separation", Tema.ESPACO_M)
	add_child(extras)
	var caixa_foco := PanelContainer.new()
	extras.add_child(caixa_foco)
	_foco = PassoFoco.criar()
	caixa_foco.add_child(_foco)
	_chk_ae = Button.new()
	_chk_ae.text = "✦ Ataque Especial (+5, 2 PE)"
	_chk_ae.toggle_mode = true
	_chk_ae.tooltip_text = "Combatente: +5 no ataque por 2 PE"
	extras.add_child(_chk_ae)
	# Foco e Ataque Especial mudam a chance mostrada nos alvos (docs/21, C2)
	_foco.mudou.connect(func(_v): _atualizar_3d())
	_chk_ae.toggled.connect(func(_v): _atualizar_3d())
	# Dano não letal (p.88): trocar o padrão da arma custa −5 (docs/40)
	_chk_nl = Button.new()
	_chk_nl.toggle_mode = true
	_chk_nl.tooltip_text = "Desacordar em vez de matar. Pessoas rendidas são interrogadas depois do combate e dão uma pista."
	extras.add_child(_chk_nl)
	_btn_enigma = _botao("Decifrar enigma", _decifrar)
	_btn_soltar = _botao("Soltar-se", _soltar)
	_btn_apagar = _botao("Apagar chamas", _apagar)
	# Primeiros Socorros e Acalmar (p.46 e p.44): aparecem quando há um aliado ao lado precisando
	_btn_socorrer = _botao("Primeiros socorros", _socorrer)
	_btn_socorrer.tooltip_text = "Medicina DT 20 (+5 por vez na cena): o aliado ao lado sai de morrendo com 1 PV. Ação padrão."
	_btn_acalmar = _botao("Acalmar", _acalmar)
	_btn_acalmar.tooltip_text = "Diplomacia ou Religião treinada, DT 20 (+5 por vez na cena): o aliado ao lado sai de enlouquecendo com 1 SAN. Ação padrão."
	# Manobras de combate (p.85-86): escolhe a manobra e depois o inimigo ao lado
	_btn_manobra = MenuButton.new()
	_btn_manobra.text = "Manobra ▾"
	_btn_manobra.flat = false
	_btn_manobra.tooltip_text = "Em vez de dano: Luta contra a Luta do alvo. Ação padrão, inimigo ao lado."
	var menu := _btn_manobra.get_popup()
	for par in [["Agarrar", "agarrar"], ["Derrubar", "derrubar"], ["Desarmar", "desarmar"], ["Empurrar", "empurrar"], ["Fintar (Enganação)", "fintar"]]:
		menu.add_item(par[0])
		menu.set_item_metadata(menu.item_count - 1, par[1])
	menu.index_pressed.connect(func(i: int): _modo_manobra(String(menu.get_item_metadata(i))))
	extras.add_child(_btn_manobra)
	_btn_levantar = _botao("Levantar-se", func(): _enviar("levantar"))
	_btn_levantar.tooltip_text = "Caído: −2 dados no corpo a corpo e só 1,5 m de deslocamento. Levantar é ação de movimento."
	_btn_pegar = _botao("Pegar a arma", func(): _enviar("pegar_arma"))
	_btn_pegar.tooltip_text = "A arma caiu aos seus pés. Pegar é ação de movimento."
	for b in [_btn_enigma, _btn_soltar, _btn_apagar, _btn_socorrer, _btn_acalmar, _btn_levantar, _btn_pegar]:
		b.theme_type_variation = "BotaoPrincipal"
		extras.add_child(b)

	# Bilhete de rituais e itens (acima dos retratos do grupo)
	_bilhete = PanelContainer.new()
	_bilhete.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(16, 14)))
	_bilhete.anchor_top = 1.0
	_bilhete.anchor_bottom = 1.0
	_bilhete.offset_left = 16
	_bilhete.offset_right = 16 + 380
	_bilhete.offset_bottom = -128
	_bilhete.offset_top = -128
	_bilhete.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bilhete.rotation_degrees = -0.8
	_bilhete.visible = false
	add_child(_bilhete)
	_caixa_bilhete = VBoxContainer.new()
	_caixa_bilhete.add_theme_constant_override("separation", 6)
	_bilhete.add_child(_caixa_bilhete)

	_log = RelatorioCampo.new()
	_log.ancorar_embaixo_direita(5 * (largura_carta + 8) - 8)
	add_child(_log)

	_painel_fim = RelatorioFim.new("Jogar de novo")
	_painel_fim.botao.pressed.connect(_reiniciar)
	_lbl_fim = _painel_fim.rotulo
	_btn_fim = _painel_fim.botao
	add_child(_painel_fim)


## Bilhete de opções de Ritual ou Item (docs/09: cartas e pastas).
func _abrir_bilhete(tipo: String) -> void:
	_bilhete_tipo = "" if _bilhete_tipo == tipo else tipo
	_montar_bilhete()


func _montar_bilhete() -> void:
	for filho in _caixa_bilhete.get_children():
		filho.visible = false
		filho.queue_free()
	var agente := _agente_da_vez()
	_bilhete.visible = _bilhete_tipo != "" and agente != null and not combate.encerrado
	for k in _cartas:
		_cartas[k].selecionada = (k == _bilhete_tipo and _bilhete.visible) or (k == _modo)
	if not _bilhete.visible:
		return
	_bilhete.offset_top = _bilhete.offset_bottom
	var titulo := Label.new()
	titulo.theme_type_variation = "TextoPapel"
	titulo.add_theme_font_size_override("font_size", Tema.FONTE_G)
	var f := Tema.fonte_titulo()
	if f != null:
		titulo.add_theme_font_override("font", f)
	_caixa_bilhete.add_child(titulo)
	if _bilhete_tipo == "ritual":
		titulo.text = "Rituais"
		var opcoes := _rituais_disponiveis(agente)
		if opcoes.is_empty():
			_texto_papel("%s não conhece rituais que possa conjurar agora." % agente.nome)
		for o in opcoes:
			var b := _botao_papel(o[2], o[0] == _ritual_sel)
			b.pressed.connect(func():
				_ritual_sel = o[0]
				_bilhete_tipo = ""
				_modo_ritual())
	else:
		titulo.text = "Itens"
		var n := agente.equipamento.count("cicatrizante")
		var cic := _botao_papel("Cicatrizante (%d) — cura você ou o aliado vizinho mais ferido" % n, false)
		cic.disabled = n == 0
		cic.pressed.connect(func():
			_bilhete_tipo = ""
			_usar_cicatrizante()
			_montar_bilhete())
		for it in _itens_de_combate(agente):
			var b := _botao_papel(it[1], false)
			b.pressed.connect(func():
				_item_sel = it[0]
				_bilhete_tipo = ""
				_modo_item())


func _texto_papel(texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = "TextoPapel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caixa_bilhete.add_child(l)


func _botao_papel(texto: String, marcado: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = "BotaoPapel"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.toggle_mode = true
	b.button_pressed = marcado
	_caixa_bilhete.add_child(b)
	return b


## [[rid, forma], forma, texto] dos rituais que o agente pode conjurar.
func _rituais_disponiveis(agente: Agente) -> Array:
	var lista: Array = []
	for rid in agente.rituais:
		var rr := ruleset.ritual(rid)
		if not rr.get("implementado", false):
			continue
		for forma in [""] + rr.get("formas", {}).keys():
			if forma != "":
				var fm: Dictionary = rr.formas[forma]
				if int(fm.get("circulo", 1)) > agente.circulo_maximo() or (fm.get("afinidade", false) and agente.afinidade != rr.elemento):
					continue
			lista.append([[rid, forma], forma, "%s%s · %d PE" % [rr.nome, "" if forma == "" else " — " + forma, agente.custo_ritual(rid, forma)]])
	return lista


## [item_id, texto] dos itens de combate (explosivos e itens contra criaturas).
func _itens_de_combate(agente: Agente) -> Array:
	var lista: Array = []
	var vistos := {}
	for item_id in agente.equipamento:
		var info := ruleset.equipamento(item_id)
		if vistos.has(item_id) or not (info.has("explosivo") or info.get("contra", "") != ""):
			continue
		vistos[item_id] = true
		lista.append([item_id, "%s (%d)" % [info.nome, agente.equipamento.count(item_id)]])
	return lista


## Close cinematográfico (docs/09, combate híbrido): a câmera aproxima do alvo por um instante.
func _close(alvo: Ser, forte: bool = false) -> void:
	if autoplay or _tab3d == null or _tab3d.rig == null or not is_inside_tree() or not grade.tem(alvo):
		return
	var rig := _tab3d.rig
	var alvo_antes := rig.alvo
	var dist_antes := rig.distancia
	rig.focar(_tab3d.posicao(grade.posicao(alvo)))
	rig.distancia = maxf(rig.distancia_min, dist_antes * 0.55)
	if forte:
		Tema.pulso_vhs(_vista, 0.7, 0.5)
	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(rig):
		rig.alvo = alvo_antes
		rig.distancia = dist_antes


func _modo_mover() -> void:
	_modo = "mover"
	_atualizar()


func _modo_manobra(tipo: String) -> void:
	_manobra_sel = tipo
	_modo = "manobra"
	_registrar("Escolha o inimigo ao lado para %s." % tipo)
	_atualizar()


func _modo_atacar() -> void:
	_modo = "atacar"
	_atualizar()


## Usa um Cicatrizante em si ou no aliado adjacente mais ferido.
func _usar_cicatrizante() -> void:
	var agente := _agente_da_vez()
	if agente == null or not agente.tem_item("cicatrizante"):
		return
	var alvo: Ser = agente
	for s in grade.seres():
		if s.lado == agente.lado and not s.tem(Ser.MORTO) and grade.estao_adjacentes(agente, s) and s.pv * agente.pv_maximo < agente.pv * s.pv_maximo:
			alvo = s
	_enviar("item", {"item": "cicatrizante", "alvo": Comandos.ref(combate, alvo)})


## Conjurar: rituais pessoais e explosões saem na hora; áreas esperam o clique no ponto;
## os outros, o clique no alvo (com vários alvos, vale o lado do alvo clicado).
func _modo_ritual() -> void:
	var agente := _agente_da_vez()
	if agente == null or _ritual_sel.is_empty():
		return
	var escolha: Array = _ritual_sel
	var e := combate.efeito_do_ritual(escolha[0], escolha[1])
	var nome: String = ruleset.ritual(escolha[0]).nome
	if e.has("area") and e.area.forma == "explosao" or (not e.has("area") and String(e.get("alcance", "")).begins_with("pessoal")):
		_conjurar(agente, escolha[0], escolha[1], agente, {})
	elif e.has("area"):
		_modo = "ritual_area"
		_registrar("Escolha o ponto de %s no tabuleiro (%s de %s m)." % [nome, e.area.forma, e.area.get("raio", e.area.get("comprimento", 0))])
	else:
		_modo = "ritual"
		_registrar("Escolha o alvo de %s no tabuleiro%s." % [nome, " (afeta os do mesmo lado em alcance)" if e.has("alvos") else ""])
	_atualizar()


## "Alvos escolhidos": os seres do lado do alvo clicado, do mais perto ao mais longe, até o limite.
func _alvos_do_lado(agente: Agente, clicado: Ser, e: Dictionary) -> Array:
	var lista: Array = []
	for s in grade.seres():
		if s.lado == clicado.lado and not s.esta_fora_de_combate():
			lista.append(s)
	lista.sort_custom(func(a, b): return grade.distancia_entre(agente, a) < grade.distancia_entre(agente, b))
	lista.erase(clicado)
	lista.push_front(clicado)
	var limite: int = int(e.alvos) if (e.alvos is int or e.alvos is float) else lista.size()
	var cat := combate._categoria(String(e.get("alcance", "")))
	return lista.filter(func(s): return combate._erro_de_alcance(agente, s, String(e.get("alcance", ""))) == "" or cat == "").slice(0, limite)


func _conjurar(_agente: Agente, rid: String, forma: String, alvo: Ser, opcoes: Dictionary) -> void:
	var op := {}
	if opcoes.has("celula"):
		op["celula"] = Comandos.vetor(opcoes.celula)
	if opcoes.has("alvos"):
		op["alvos"] = opcoes.alvos.map(func(x): return Comandos.ref(combate, x))
	_modo = ""
	if alvo != null:
		_close(alvo, true)
	_enviar("conjurar", {"ritual": rid, "forma": forma, "alvo": Comandos.ref(combate, alvo), "opcoes": op})


func _criatura_com_enigma() -> Ameaca:
	for s in combate.participantes:
		if s is Ameaca and (s as Ameaca).enigma_pendente() and not s.esta_fora_de_combate():
			return s as Ameaca
	return null


func _decifrar() -> void:
	var agente := _agente_da_vez()
	var criatura := _criatura_com_enigma()
	if agente == null or criatura == null:
		return
	_enviar("decifrar", {"alvo": Comandos.ref(combate, criatura)})


## Granadas pedem um ponto; itens contra criaturas (fertilizante…) pedem a criatura.
func _modo_item() -> void:
	var agente := _agente_da_vez()
	if agente == null or _item_sel == "":
		return
	var info := ruleset.equipamento(_item_sel)
	_modo = "granada" if info.has("explosivo") else "contra"
	_registrar("Escolha %s para %s." % ["o ponto" if _modo == "granada" else "a criatura", info.nome])
	_atualizar()


## O aliado ao lado do agente da vez com a condição (o selecionado, se for um deles).
func _aliado_ao_lado(agente: Agente, condicao: String) -> Ser:
	var achado: Ser = null
	for s in combate.participantes:
		if s is Agente and s != agente and s.tem(condicao) and not s.tem(Ser.MORTO):
			if combate.grade != null and combate.grade.tem(agente) and combate.grade.tem(s) and not combate.grade.estao_adjacentes(agente, s):
				continue
			if s == _selecionado:
				return s
			if achado == null:
				achado = s
	return achado


## Perícia para acalmar: Diplomacia ou, sem ela, Religião (p.48).
func _pericia_para_acalmar(agente: Agente) -> String:
	for p in ["diplomacia", "religiao"]:
		if agente.treinado_em(p):
			return p
	return ""


func _socorrer() -> void:
	var agente := _agente_da_vez()
	var alvo := _aliado_ao_lado(agente, Ser.MORRENDO) if agente != null else null
	if alvo != null:
		_enviar("socorrer", {"alvo": Comandos.ref(combate, alvo)})


func _acalmar() -> void:
	var agente := _agente_da_vez()
	var alvo := _aliado_ao_lado(agente, Ser.ENLOUQUECENDO) if agente != null else null
	if alvo != null:
		_enviar("acalmar", {"alvo": Comandos.ref(combate, alvo), "pericia": _pericia_para_acalmar(agente)})


func _apagar() -> void:
	if _agente_da_vez() != null:
		_enviar("apagar")


func _soltar() -> void:
	if _agente_da_vez() != null:
		_enviar("soltar")


func _encerrar_turno() -> void:
	if _agente_da_vez() != null:
		_enviar("encerrar_turno")


func _reiniciar() -> void:
	var jogo := get_node_or_null("/root/Jogo")
	if not config.is_empty() and jogo != null:
		_enviar("sair")
	else:
		get_tree().reload_current_scene()


func _titulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	return l


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	return b


func _atualizar() -> void:
	if _lbl_turno == null:
		return
	var atual := combate.ser_atual()
	var agente := _agente_da_vez()
	if combate.encerrado:
		_lbl_turno.text = "Combate encerrado — rodada %d" % combate.rodada
	elif atual != null:
		var a := combate.acoes_restantes(atual)
		_lbl_turno.text = "Rodada %d · %s" % [combate.rodada, atual.nome]
		_lbl_turno.tooltip_text = "Ações: padrão %d, movimento %d" % [a.padrao, a.movimento]
	_lbl_ficha.text = _ficha(_selecionado if _selecionado != null else atual)
	# Ações esgotadas ficam apagadas (docs/13): sem ação padrão, nada de atacar, conjurar
	# ou usar item; sem padrão nem movimento, nada de mover.
	var restam := combate.acoes_restantes(agente) if agente != null else {"padrao": 0, "movimento": 0}
	var sem_padrao := int(restam.get("padrao", 0)) <= 0
	_btn_mover.disabled = agente == null or (sem_padrao and int(restam.get("movimento", 0)) <= 0)
	_btn_atacar.disabled = agente == null or sem_padrao
	_btn_encerrar.disabled = agente == null
	_btn_ritual.disabled = agente == null or sem_padrao or _rituais_disponiveis(agente).is_empty()
	var com_enigma := _criatura_com_enigma()
	_btn_enigma.visible = com_enigma != null
	if com_enigma != null:
		_btn_enigma.text = "Tocar a melodia" if com_enigma.enigma.get("tipo", "") == "melodia" else "Enigma: %s" % com_enigma.etapa_atual().get("texto", "decifrar")
	_btn_enigma.disabled = agente == null
	_btn_soltar.visible = agente != null and agente.tem(Ser.AGARRADO)
	_btn_apagar.visible = agente != null and agente.tem(Ser.EM_CHAMAS)
	_btn_manobra.disabled = agente == null or sem_padrao
	_btn_levantar.visible = agente != null and agente.tem(Ser.CAIDO)
	_btn_pegar.visible = agente != null and agente.mods_cena.has("arma_caida")
	_btn_socorrer.visible = agente != null and _aliado_ao_lado(agente, Ser.MORRENDO) != null
	_btn_socorrer.disabled = sem_padrao
	_btn_acalmar.visible = agente != null and _pericia_para_acalmar(agente) != "" and _aliado_ao_lado(agente, Ser.ENLOUQUECENDO) != null
	_btn_acalmar.disabled = sem_padrao
	_btn_item.disabled = agente == null or sem_padrao or (not agente.tem_item("cicatrizante") and _itens_de_combate(agente).is_empty())
	_motivos_cartas(agente, sem_padrao)
	if sem_padrao and _modo in ["atacar", "manobra", "ritual", "ritual_area", "granada", "contra"]:
		_modo = ""
	_foco.definir(_foco.valor, agente.pe_disponivel_no_turno() if agente != null else 0)
	_chk_ae.visible = agente != null and agente.classe_id == "combatente"
	var arma_cac: bool = agente != null and agente.arma().get("ataque", "corpo_a_corpo") == "corpo_a_corpo"
	_chk_nl.visible = arma_cac
	if arma_cac:
		_chk_nl.text = "Golpe letal (−5)" if String(agente.arma().get("id", "")) == "desarmado" else "Golpe não letal (−5)"
	_barra_membrana.value = membrana.valor
	Tema.membrana_na_tela(_vista, membrana.valor)
	if _tab3d != null:
		_tab3d.clima_membrana(membrana.valor)
	_lbl_membrana.text = "%d — %s" % [membrana.valor, membrana.estado().get("nome", "")]
	_atualizar_mestre()
	_desenhar_slots()
	_atualizar_grupo()
	if _bilhete_tipo != "" or _bilhete.visible:
		_montar_bilhete()
	for k in _cartas:
		_cartas[k].selecionada = k == _modo or k == _bilhete_tipo
	_atualizar_3d()


func _atualizar_grupo() -> void:
	var i := 0
	var vez := combate.ser_atual()
	for s in combate.participantes:
		if not s is Agente:
			continue
		var c: CartaoAgente = _cartoes.get(s)
		if c == null:
			c = CartaoAgente.criar(s, Tema.CORES_JOGADORES[i % Tema.CORES_JOGADORES.size()])
			c.escolhido.connect(func(ag): DossieAgente.abrir(self, ag))
			c.custom_minimum_size.x = 150
			_grupo.add_child(c)
			_cartoes[s] = c
		c.visible = not s.tem(Ser.MORTO)
		if c.visible:
			c.atualizar(s == vez)
		i += 1


# --- Modo Mestre (Fase 8.3) ------------------------------------------------------

## A ameaça da vez, quando é esta máquina que decide por ela (o mestre).
# --- Vez da ameaça (docs/21, C3) --------------------------------------------------------

## Faixa no alto, abaixo da Membrana: quem age e em quem deve agir. Enquanto isso, a mão de
## cartas desce (cinco cadeados não dizem nada; a faixa diz).
func _montar_faixa_vez() -> void:
	_faixa_vez = PanelContainer.new()
	_faixa_vez.anchor_left = 0.5
	_faixa_vez.anchor_right = 0.5
	_faixa_vez.offset_top = 104
	_faixa_vez.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_faixa_vez.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faixa_vez.visible = false
	add_child(_faixa_vez)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	_faixa_vez.add_child(v)
	var sub := Label.new()
	sub.text = "VEZ DA AMEAÇA"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	sub.add_theme_font_size_override("font_size", Tema.FONTE_P)
	v.add_child(sub)
	_faixa_nome = Label.new()
	_faixa_nome.theme_type_variation = "Titulo"
	_faixa_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_faixa_nome)
	_faixa_intencao = Label.new()
	_faixa_intencao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_faixa_intencao.add_theme_font_size_override("font_size", Tema.FONTE_M)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		_faixa_intencao.add_theme_font_override("font", maquina)
	v.add_child(_faixa_intencao)


## `ser` = a ameaça que vai agir (a IA); null esconde a faixa e devolve a mão.
func _mostrar_faixa_vez(ser: Ser) -> void:
	if _faixa_vez == null:
		return
	var mostrar := ser != null and ser is Ameaca
	if mostrar:
		var cor: Color = Tema.ELEMENTO.get((ser as Ameaca).elemento, Tema.SANGUE_CLARO)
		_faixa_vez.add_theme_stylebox_override("panel", Tema.caixa(Color(Tema.FUNDO, 0.92), cor, 2, 6, Vector2(28, 8)))
		_faixa_nome.text = ser.nome.to_upper()
		_faixa_nome.add_theme_color_override("font_color", cor.lightened(0.25))
		var it := IaCombate.intencao(combate, ser, armas)
		var alvo: Ser = it.alvo
		_faixa_intencao.text = "" if alvo == null else ("→ vai atacar %s" % alvo.nome if it.acao == "atacar" else "→ avança sobre %s" % alvo.nome)
		_faixa_intencao.add_theme_color_override("font_color", Tema.PERGAMINHO)
		if not _faixa_vez.visible:
			_faixa_vez.visible = true
			_faixa_vez.modulate.a = 0.0
			_faixa_vez.create_tween().tween_property(_faixa_vez, "modulate:a", 1.0, 0.15)
	else:
		_faixa_vez.visible = false
	_abaixar_mao(mostrar)


func _abaixar_mao(abaixar: bool) -> void:
	if _mao == null or abaixar == _mao_abaixada:
		return
	_mao_abaixada = abaixar
	var d := 260.0 if abaixar else -260.0   # some inteira atrás do relatório
	# O Foco e o Ataque Especial também saem: não há o que gastar na vez da ameaça
	var extras: Control = _foco.get_parent().get_parent() if _foco != null else null
	if extras != null:
		extras.visible = not abaixar
	var tw := _mao.create_tween().set_parallel()
	tw.tween_property(_mao, "offset_top", _mao.offset_top + d, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_mao, "offset_bottom", _mao.offset_bottom + d, 0.22).set_trans(Tween.TRANS_SINE)


func _ameaca_da_vez() -> Ameaca:
	var s := fluxo.decisor() if fluxo != null else null
	return s as Ameaca if s is Ameaca and _controles != null and _controles.e_mestre_local() else null


func _atualizar_mestre() -> void:
	var amea := _ameaca_da_vez()
	_caixa_mestre.visible = amea != null
	if amea == null:
		return
	var modos := {"m_mover": "escolha o destino", "m_atacar": "escolha o alvo", "m_habilidade": "escolha o alvo ou o ponto"}
	_lbl_mestre.text = "Mestre — vez de %s%s" % [amea.nome, ("  (%s)" % modos[_modo]) if modos.has(_modo) else ""]
	var ataque_antes = _opt_ataque_m.get_item_metadata(_opt_ataque_m.selected) if _opt_ataque_m.selected >= 0 else 0
	_opt_ataque_m.clear()
	if amea.ataques.is_empty():
		_opt_ataque_m.add_item("%s (%s)" % [armas.get(amea, {}).get("nome", "Ataque"), armas.get(amea, {}).get("dano", "?")])
		_opt_ataque_m.set_item_metadata(0, -1)
	for i in amea.ataques.size():
		_opt_ataque_m.add_item("%s (%s)" % [amea.ataques[i].get("nome", "Ataque"), amea.ataques[i].get("dano", "?")])
		_opt_ataque_m.set_item_metadata(_opt_ataque_m.item_count - 1, i)
		if i == ataque_antes:
			_opt_ataque_m.select(_opt_ataque_m.item_count - 1)
	var hab_antes = _opt_hab_m.get_item_metadata(_opt_hab_m.selected) if _opt_hab_m.selected >= 0 else ""
	_opt_hab_m.clear()
	for h in amea.habilidades:
		if h.has("acao"):
			_opt_hab_m.add_item("%s (%s)" % [String(h.id).capitalize(), h.acao])
			_opt_hab_m.set_item_metadata(_opt_hab_m.item_count - 1, h.id)
			if h.id == hab_antes:
				_opt_hab_m.select(_opt_hab_m.item_count - 1)
	_opt_hab_m.get_parent().visible = _opt_hab_m.item_count > 0


func _modo_mestre(modo: String) -> void:
	if _ameaca_da_vez() != null:
		_modo = modo
		_atualizar()


func _ia_mestre() -> void:
	if _ameaca_da_vez() != null:
		_enviar("ia")


func _encerrar_mestre() -> void:
	if _ameaca_da_vez() != null:
		_enviar("encerrar_turno")


func _ficha(ser: Ser) -> String:
	if ser == null:
		return ""
	var linhas := ["%s — PV %d/%d  Defesa %d" % [ser.nome, ser.pv, ser.pv_maximo, ser.defesa()]]
	if ser is Agente:
		var a := ser as Agente
		linhas[0] = "%s · %s, NEX %d%% · Defesa %d" % [a.nome, a.ruleset.classe(a.classe_id).nome, a.nex, a.defesa()]   # PV/PE/SAN no retrato
	linhas.append("Arma: %s (%s)" % [armas[ser].get("nome", "?"), armas[ser].get("dano", "?")])
	if not ser.condicoes.is_empty():
		linhas.append("Condições: %s" % ", ".join(PackedStringArray(ser.condicoes.keys())))
	if ser is Ameaca and (ser as Ameaca).enigma_pendente():
		linhas.append("Enigma de Medo: imune a dano até alguém decifrar.")
	return "\n".join(PackedStringArray(linhas))


func _desenhar_slots() -> void:
	if _ultimo_teste == _teste_desenhado and _slots.get_child_count() > 0:
		return   # não repete a animação a cada atualização
	_teste_desenhado = _ultimo_teste
	for filho in _slots.get_children():
		filho.queue_free()
	if _ultimo_teste == null:
		_lbl_resultado.text = "—"
		return
	var marcado := false
	for i in _ultimo_teste.slots.size():
		var valor: int = _ultimo_teste.slots[i]
		var estado := "neutro"
		if valor == _ultimo_teste.escolhido and not marcado:
			marcado = true
			estado = "sucesso" if _ultimo_teste.sucesso else "falha"
		_slots.add_child(Tema.slot_d20(valor, estado, i))
	_lbl_resultado.text = "%s %d %+d = %d contra %d → %s" % [
		"pior" if _ultimo_teste.usa_pior else "maior", _ultimo_teste.escolhido, _ultimo_teste.bonus,
		_ultimo_teste.total, _ultimo_teste.dt, "SUCESSO" if _ultimo_teste.sucesso else "FALHA"]


func _entrada_tabuleiro(evento: InputEvent) -> void:
	if _tab3d == null or TourGuiado.em_andamento():
		return
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var c := _tab3d.celula_em(evento.position)
		if grade.dentro(c):
			_clicar_celula(c)
		return
	if _tab3d.rig.tratar_entrada(evento):
		_vista.accept_event()


func _unhandled_input(evento: InputEvent) -> void:
	if Atalhos.pressionou(evento, "ficha") and not autoplay:
		var ag := _agente_da_vez()
		if ag != null:
			get_viewport().set_input_as_handled()
			DossieAgente.abrir(self, ag)
			return
	# Cartas pelo teclado (1–5, remapeáveis): o mesmo que clicar, se a carta estiver liberada
	if not autoplay and not TourGuiado.em_andamento():
		for i in _mao.get_child_count():
			var carta := _mao.get_child(i) as CartaAcao
			if carta != null and Atalhos.pressionou(evento, "carta_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				if not carta.disabled:
					carta.pressed.emit()
				return
	if evento.is_action_pressed("ui_cancel") and not autoplay and not MenuPausa.aberto(self) and not TourGuiado.em_andamento():
		get_viewport().set_input_as_handled()
		if _bilhete_tipo != "" or _modo != "":
			_bilhete_tipo = ""
			_modo = ""
			_atualizar()
		else:
			MenuPausa.abrir(self)   # no meio do combate não há saída: o estado não é salvo
		return
	if _tab3d != null and _tab3d.rig != null and evento is InputEventKey and _tab3d.rig.tratar_entrada(evento):
		get_viewport().set_input_as_handled()


func _atualizar_3d() -> void:
	if _tab3d == null or _tab3d.grade == null:
		return
	var agente := _agente_da_vez()
	var destinos: Array = []
	var alvos: Array = []
	if agente != null and _modo == "mover" and combate.acoes_restantes(agente).movimento + combate.acoes_restantes(agente).padrao > 0:
		destinos = grade.destinos(agente, agente.deslocamento_quadrados())
	var chances := {}
	if agente != null and _modo == "atacar":
		var ae := 5 if _chk_ae.button_pressed and agente.classe_id == "combatente" else 0
		for s in grade.seres():
			if s.lado != agente.lado and _pode_atacar(agente, s, armas[agente]):
				alvos.append(s)
				chances[s] = combate.chance_de_acerto(agente, s, armas[agente], _foco.valor, ae)
	_tab3d.chances = chances
	var zonas: Array = []
	for z in combate.zonas():
		zonas.append({"celulas": z.celulas, "elemento": ruleset.ritual(z.ritual).elemento})
	_tab3d.atualizar(destinos, alvos, combate.ser_atual(), _selecionado, zonas)
	if _modo == "":
		_cursor_ativo = false
	_tab3d.mostrar_cursor(_cursor, _cursor_ativo)
	if _lbl_vez != null and _controles != null:
		var amea_vez = fluxo.decisor() if fluxo != null else null
		_lbl_vez.text = ("Vez de %s — %s" % [amea_vez.nome, "mestre (você)" if _controles.e_mestre_local() else "mestre"]) if amea_vez is Ameaca else _controles.faixa_da_vez(_agente_da_vez())
		_lbl_vez.visible = _lbl_vez.text != ""
