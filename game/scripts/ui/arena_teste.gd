extends Control
## Arena de Teste: primeira cena jogável. Combate tático 2D na grade, usando o motor
## de regras (CriacaoAgente, Combate, Grade, Membrana). Interface provisória, só para
## testar as regras — a apresentação 3D low poly vem depois.
##
## Controles: clique num agente/inimigo para ver a ficha; "Mover" e clique numa célula
## destacada; "Atacar" e clique num inimigo; "Encerrar turno". Foco = PE gastos como +1 d20.

const COR_FUNDO := Color("12141a")
const COLUNAS := 14
const LINHAS := 9


## Arma de cada ser na arena
var armas: Dictionary = {}
var ruleset: RulesetOp2022
var dados: Dados
var combate: Combate
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
var _turnos_jogados := 0

# Nós da interface
var _vista: SubViewportContainer
var _tab3d: Tabuleiro3D
var _lbl_turno: Label
var _lbl_ficha: Label
var _slots: HBoxContainer
var _lbl_resultado: Label
var _btn_mover: Button
var _btn_atacar: Button
var _btn_encerrar: Button
var _btn_item: Button
var _btn_ritual: Button
var _btn_enigma: Button
var _btn_soltar: Button
var _opt_ritual: OptionButton
var _spin_foco: SpinBox
var _chk_ae: CheckBox
var _barra_membrana: ProgressBar
var _lbl_membrana: Label
var _log: RichTextLabel
var _painel_fim: PanelContainer
var _lbl_fim: Label
var _btn_fim: Button


func _ready() -> void:
	_montar_interface()
	var jogo := get_node_or_null("/root/Jogo")
	if config.is_empty() and jogo != null and not jogo.combate_config.is_empty():
		config = jogo.combate_config
	if not config.is_empty() and semente < 0:
		semente = int(config.get("semente", -1))
	iniciar_combate(semente if semente >= 0 else randi())


# --- Preparação ------------------------------------------------------------

func iniciar_combate(semente: int) -> void:
	ruleset = RulesetOp2022.carregar_padrao()
	dados = Dados.new(semente)
	var jogo := get_node_or_null("/root/Jogo")
	if not config.is_empty() and jogo != null and jogo.missao != null:
		membrana = jogo.missao.membrana   # o combate também enfraquece a Membrana da missão
	else:
		membrana = Membrana.carregar_padrao()
	membrana.estado_mudou.connect(func(e, _ant): _registrar("[color=#c39bd3]A Membrana está %s: %s[/color]" % [e.nome, e.descricao]))
	var regras: Dictionary = config.get("regras", {"lesoes": true, "inspiracao_resoluta": true, "presenca_perturbadora": true})
	combate = Combate.new(ruleset, dados, regras)
	grade = Grade.new(COLUNAS, LINHAS)
	combate.grade = grade
	combate.membrana = membrana
	combate.registro.connect(_registrar)
	combate.ser_adicionado.connect(_ao_adicionar)
	if config.is_empty():
		_montar_mapa()
		_criar_lados()
	else:
		_montar_mapa_do_terreno(config.get("terreno", "campo"))
		_criar_lados_da_missao()
	if _tab3d != null:
		_tab3d.construir(grade)
	combate.ataque_resolvido.connect(_ao_atacar)
	combate.combate_encerrado.connect(_ao_encerrar)
	combate.turno_perdido.connect(func(s, motivo): _registrar("%s perde o turno (%s)." % [s.nome, motivo]))
	combate.lesao_sofrida.connect(func(a, attr): _registrar("[color=#e67e22]%s sofre uma lesão: −1 %s permanente.[/color]" % [a.nome, attr.to_upper()]))
	combate.inspiracao_disponivel.connect(_ao_inspirar)
	combate.iniciar()
	for s in combate.participantes:
		if s is Ameaca and (s as Ameaca).enigma_pendente():
			_registrar("[color=#f5b041]Enigma de Medo — %s: %s Nada a fere até alguém decifrar (botão Decifrar).[/color]" % [s.nome, (s as Ameaca).enigma.get("texto", "")])
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


## Campo de batalha a partir do terreno do hex (parâmetros "arena" em mapa.json).
func _montar_mapa_do_terreno(terreno_id: String) -> void:
	var t: Dictionary = DadosJogo.ler("mapa").terrenos.get(terreno_id, {})
	var param: Dictionary = t.get("arena", {})
	var tipos := {Grade.PAREDE: int(param.get("parede", 0)), Grade.COBERTURA: int(param.get("cobertura", 2)), Grade.DIFICIL: int(param.get("dificil", 0))}
	for tipo in tipos:
		for i in tipos[tipo]:
			# Colunas 0-1 e 12-13 ficam livres para os dois lados se posicionarem.
			var c := Vector2i(2 + dados.rolar(COLUNAS - 4) - 1, dados.rolar(LINHAS) - 1)
			if not grade.terreno.has(c):
				grade.terreno[c] = tipo


func _criar_lados_da_missao() -> void:
	var linhas_livres := [4, 2, 6, 3, 5, 1, 7]
	var i := 0
	for a in config.agentes:
		_adicionar(a, config.armas[a], Vector2i(1, linhas_livres[i % linhas_livres.size()]))
		i += 1
	i = 0
	for info in config.ameacas:
		var amea := Ameaca.criar(ruleset, info.nome, info.ficha)
		_adicionar(amea, info.arma, Vector2i(COLUNAS - 2 - (i / 7), linhas_livres[i % linhas_livres.size()]))
		i += 1


## Seres que surgem no meio do combate (cópias do escutado).
func _ao_adicionar(ser: Ser) -> void:
	var lista: Array = (ser as Ameaca).ataques if ser is Ameaca else []
	armas[ser] = lista[0] if not lista.is_empty() else ruleset.arma("desarmado")
	_registrar("%s entra no combate." % ser.nome)


func _adicionar(ser: Ser, arma: Dictionary, pos: Vector2i) -> void:
	combate.adicionar(ser)
	grade.colocar(ser, pos)
	armas[ser] = arma


# --- Fluxo de turnos -------------------------------------------------------

## Passa para o próximo turno. Turnos da IA são jogados aqui (com uma pausa curta para
## o jogador acompanhar, exceto no autoplay). Para quando chega a vez de um agente.
func _avancar() -> void:
	while true:
		_modo = ""
		if combate.encerrado or _turnos_jogados >= 500:
			_atualizar()
			return
		var rodada_antes := combate.rodada
		var ser := combate.proximo_turno()
		if combate.rodada != rodada_antes:
			membrana.registrar("rodada_combate")
			_registrar("[color=#7f8c8d]— Rodada %d —[/color]" % combate.rodada)
		_turnos_jogados += 1
		_selecionado = ser
		_atualizar()
		if ser == null:
			return
		if ser is Agente and not autoplay:
			return   # vez do jogador
		if not autoplay:
			await get_tree().create_timer(0.6).timeout
			if not is_inside_tree():
				return
		_jogar_ia(ser)


## IA simples: vai até o agente (ou inimigo) mais próximo e ataca se puder.
func _jogar_ia(ser: Ser) -> void:
	var alvo := IaAmeaca.alvo_preferido(combate, ser, _inimigo_mais_proximo(ser))
	if alvo == null:
		return
	var arma: Dictionary = armas.get(ser, ruleset.arma("desarmado"))
	if ser is Ameaca:
		if IaAmeaca.agir_antes(combate, ser as Ameaca, alvo) or combate.encerrado:
			return
		if IaAmeaca.so_se_move(ser):
			var perto := grade.aproximar(ser, alvo, ser.deslocamento_quadrados())
			if perto != grade.posicao(ser):
				combate.mover(ser, perto)
			return
		arma = IaAmeaca.escolher_arma(combate, ser, alvo, arma)
	if ser is Agente:
		for rid in (ser as Agente).rituais:
			var rr := ruleset.ritual(rid)
			if rr.get("implementado", false) and rr.efeitos[0].tipo == "dano" and not rr.efeitos[0].has("area") and combate.pode_conjurar(ser, rid, alvo) == "":
				combate.conjurar(ser, rid, alvo)
				return
	if not _pode_atacar(ser, alvo, arma):
		var limite := ser.deslocamento_quadrados()
		var destino := grade.aproximar(ser, alvo, limite)
		if arma.get("ataque", "") != "corpo_a_corpo" and grade.em_alcance(ser, alvo, arma.get("alcance", "curto")):
			destino = grade.posicao(ser)   # atirador já em alcance: não precisa andar
		if destino != grade.posicao(ser):
			combate.mover(ser, destino)
	if _pode_atacar(ser, alvo, arma) and not combate.encerrado:
		if alvo is Agente and alvo.treinado_em("reflexos"):
			combate.declarar_reacao(alvo, "esquiva")
		combate.agredir(ser, alvo, arma)


func _inimigo_mais_proximo(ser: Ser) -> Ser:
	var melhor: Ser = null
	var melhor_d := 1 << 30
	for outro in combate.participantes:
		if outro.lado == ser.lado or outro.esta_fora_de_combate() or not grade.tem(outro):
			continue
		var d := grade.distancia_entre(ser, outro)
		if d < melhor_d:
			melhor = outro
			melhor_d = d
	return melhor


func _pode_atacar(ser: Ser, alvo: Ser, arma: Dictionary) -> bool:
	if combate.acoes_restantes(ser).padrao <= 0 or (alvo.esta_fora_de_combate() and not alvo.tem(Ser.POCA)):
		return false
	if arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo":
		return grade.estao_adjacentes(ser, alvo)
	return grade.faixa_de_alcance(ser, alvo, arma.get("alcance", "curto")) != "fora" and grade.cobertura(ser, alvo) != "total"


# --- Ações do jogador -------------------------------------------------------

func _agente_da_vez() -> Agente:
	var s := combate.ser_atual()
	return s as Agente if s is Agente and not autoplay and s.lado == "agentes" else null   # hipnotizados jogam pela IA


func _clicar_celula(celula: Vector2i) -> void:
	var agente := _agente_da_vez()
	var alvo := grade.ocupante(celula)
	if _modo == "mover" and agente != null:
		if combate.mover(agente, celula):
			_registrar("%s se move." % agente.nome)
			for op in combate.oportunidades_pendentes:
				_registrar("%s pode fazer um ataque de oportunidade." % op.atacante.nome)
		_modo = ""
	elif _modo == "ritual_area" and agente != null:
		var escolha: Array = _opt_ritual.get_item_metadata(_opt_ritual.selected)
		_conjurar(agente, escolha[0], escolha[1], alvo, {"celula": celula})
		return
	elif _modo == "ritual" and agente != null and alvo != null:
		var escolha: Array = _opt_ritual.get_item_metadata(_opt_ritual.selected)
		var opcoes := {}
		var e := combate.efeito_do_ritual(escolha[0], escolha[1])
		if e.has("alvos"):
			opcoes["alvos"] = _alvos_do_lado(agente, alvo, e)
		_conjurar(agente, escolha[0], escolha[1], alvo, opcoes)
		return
	elif _modo == "atacar" and agente != null and alvo != null and alvo.lado != agente.lado:
		var opcoes := {}
		if _chk_ae.button_pressed and agente.classe_id == "combatente":
			opcoes["ataque_especial"] = {"ataque": 5}
		var r := combate.agredir(agente, alvo, armas[agente], int(_spin_foco.value), opcoes)
		for extra in r.ataques_extras:
			_ultimo_teste = extra.teste
		if r.teste == null:
			_registrar("[color=#e67e22]Ataque inválido (fora de alcance, sem ação ou PE).[/color]")
		_modo = ""
	elif alvo != null:
		_selecionado = alvo
	_atualizar()


func _ao_atacar(r: ResultadoAtaque) -> void:
	_ultimo_teste = r.teste
	var cor := "#5dade2" if r.atacante is Agente else "#ec7063"
	var txt := "[color=%s]%s[/color] → %s com %s: %s" % [cor, r.atacante.nome, r.alvo.nome, r.arma.get("nome", "?"), r.teste.descrever()]
	if r.reacao != "":
		txt += " [i](%s)[/i]" % r.reacao
	if r.acertou:
		txt += " → [b]%d de dano[/b]%s" % [r.dano, " [color=#f4d03f]CRÍTICO[/color]" if r.critico else ""]
	if r.pe_gasto > 0:
		txt += " (%d PE)" % r.pe_gasto
	_registrar(txt)
	if r.alvo.tem(Ser.MORRENDO):
		_registrar("[color=#c0392b]%s está morrendo![/color]" % r.alvo.nome)


func _ao_inspirar(morto: Agente, efeito: String) -> void:
	# Na arena, a inspiração vai para o agente vivo com menos PV.
	var melhor: Agente = null
	for s in combate.participantes:
		if s is Agente and not s.esta_fora_de_combate() and (melhor == null or s.pv < melhor.pv):
			melhor = s
	if melhor != null:
		combate.aplicar_inspiracao(combate.inspiracoes_pendentes.size() - 1, melhor)
		_registrar("[color=#bb8fce]Inspiração Resoluta de %s: %s para %s.[/color]" % [morto.nome, efeito.replace("_", " "), melhor.nome])


func _ao_encerrar(vencedor: String) -> void:
	_vencedor = vencedor
	var texto := "VITÓRIA DA ORDEM" if vencedor == "agentes" else "OS AGENTES CAÍRAM"
	if _btn_fim != null and not config.is_empty():
		_btn_fim.text = "Voltar ao mapa"
	_registrar("[b]%s[/b]" % texto)
	if _lbl_fim != null:
		_lbl_fim.text = texto
		_painel_fim.visible = true


func _registrar(texto: String) -> void:
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
	raiz.add_theme_constant_override("separation", 12)
	add_child(raiz)

	_vista = SubViewportContainer.new()
	_vista.stretch = true
	_vista.custom_minimum_size = Vector2(680, 0)
	_vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	_vista.add_child(vp)
	_tab3d = Tabuleiro3D.new()
	vp.add_child(_tab3d)
	_vista.gui_input.connect(_entrada_tabuleiro)
	raiz.add_child(_vista)

	var painel := VBoxContainer.new()
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.add_theme_constant_override("separation", 6)
	raiz.add_child(painel)

	_lbl_turno = Label.new()
	_lbl_turno.add_theme_font_size_override("font_size", 18)
	painel.add_child(_lbl_turno)

	_lbl_ficha = Label.new()
	_lbl_ficha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(_lbl_ficha)

	painel.add_child(_titulo("Último teste (slots de d20)"))
	_slots = HBoxContainer.new()
	painel.add_child(_slots)
	_lbl_resultado = Label.new()
	painel.add_child(_lbl_resultado)

	var botoes := HBoxContainer.new()
	painel.add_child(botoes)
	_btn_mover = _botao("Mover", _modo_mover)
	_btn_atacar = _botao("Atacar", _modo_atacar)
	_btn_encerrar = _botao("Encerrar turno", _encerrar_turno)
	_btn_item = _botao("Cicatrizante", _usar_cicatrizante)
	for b in [_btn_mover, _btn_atacar, _btn_item, _btn_encerrar]:
		botoes.add_child(b)
	var botoes2 := HBoxContainer.new()
	painel.add_child(botoes2)
	_btn_enigma = _botao("Decifrar enigma", _decifrar)
	_btn_soltar = _botao("Soltar-se", _soltar)
	botoes2.add_child(_btn_enigma)
	botoes2.add_child(_btn_soltar)
	var linha_ritual := HBoxContainer.new()
	painel.add_child(linha_ritual)
	_opt_ritual = OptionButton.new()
	_opt_ritual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_ritual.clip_text = true
	linha_ritual.add_child(_opt_ritual)
	_btn_ritual = _botao("Conjurar", _modo_ritual)
	linha_ritual.add_child(_btn_ritual)

	var opcoes := HBoxContainer.new()
	painel.add_child(opcoes)
	var lbl_foco := Label.new()
	lbl_foco.text = "Foco (PE → +1 d20):"
	opcoes.add_child(lbl_foco)
	_spin_foco = SpinBox.new()
	_spin_foco.min_value = 0
	_spin_foco.max_value = 0
	opcoes.add_child(_spin_foco)
	_chk_ae = CheckBox.new()
	_chk_ae.text = "Ataque Especial (+5, 2 PE)"
	opcoes.add_child(_chk_ae)

	painel.add_child(_titulo("Membrana"))
	_barra_membrana = ProgressBar.new()
	_barra_membrana.max_value = 100
	_barra_membrana.custom_minimum_size = Vector2(0, 18)
	painel.add_child(_barra_membrana)
	_lbl_membrana = Label.new()
	painel.add_child(_lbl_membrana)

	painel.add_child(_titulo("Registro"))
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel.add_child(_log)

	_painel_fim = PanelContainer.new()
	_painel_fim.visible = false
	_painel_fim.set_anchors_preset(Control.PRESET_CENTER)
	var caixa := VBoxContainer.new()
	_painel_fim.add_child(caixa)
	_lbl_fim = Label.new()
	_lbl_fim.add_theme_font_size_override("font_size", 28)
	caixa.add_child(_lbl_fim)
	_btn_fim = _botao("Jogar de novo", _reiniciar)
	caixa.add_child(_btn_fim)
	add_child(_painel_fim)


func _modo_mover() -> void:
	_modo = "mover"
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
	var cura := combate.usar_item(agente, "cicatrizante", alvo)
	if cura >= 0:
		_registrar("%s usa um Cicatrizante em %s: +%d PV." % [agente.nome, alvo.nome, cura])
	else:
		_registrar("[color=#e67e22]Não dá para usar o Cicatrizante agora.[/color]")
	_atualizar()


## Conjurar: rituais pessoais e explosões saem na hora; áreas esperam o clique no ponto;
## os outros, o clique no alvo (com vários alvos, vale o lado do alvo clicado).
func _modo_ritual() -> void:
	var agente := _agente_da_vez()
	if agente == null or _opt_ritual.selected < 0:
		return
	var escolha: Array = _opt_ritual.get_item_metadata(_opt_ritual.selected)
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


func _conjurar(agente: Agente, rid: String, forma: String, alvo: Ser, opcoes: Dictionary) -> void:
	var r := combate.conjurar(agente, rid, alvo, forma, opcoes)
	if not r.ok:
		_registrar("[color=#e67e22]Não deu para conjurar: %s.[/color]" % r.get("erro", "?"))
	_modo = ""
	_atualizar()


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
	var t := combate.decifrar_enigma(agente, criatura)
	if t != null:
		_ultimo_teste = t
	else:
		_registrar("[color=#e67e22]Sem ação padrão para decifrar o enigma.[/color]")
	_atualizar()


func _soltar() -> void:
	var agente := _agente_da_vez()
	if agente != null:
		combate.escapar(agente)
	_atualizar()


func _encerrar_turno() -> void:
	if _agente_da_vez() != null:
		_avancar()


func _reiniciar() -> void:
	var jogo := get_node_or_null("/root/Jogo")
	if not config.is_empty() and jogo != null:
		jogo.voltar_do_combate(_vencedor)
	else:
		get_tree().reload_current_scene()


func _titulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", Color("aab7b8"))
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
		_lbl_turno.text = "Rodada %d — vez de %s  (padrão %d, movimento %d)" % [combate.rodada, atual.nome, a.padrao, a.movimento]
	_lbl_ficha.text = _ficha(_selecionado if _selecionado != null else atual)
	_btn_mover.disabled = agente == null
	_btn_atacar.disabled = agente == null
	_btn_encerrar.disabled = agente == null
	_btn_item.disabled = agente == null or not agente.tem_item("cicatrizante")
	var selecionado_antes = _opt_ritual.get_item_metadata(_opt_ritual.selected) if _opt_ritual.selected >= 0 else []
	_opt_ritual.clear()
	if agente != null:
		for rid in agente.rituais:
			var rr := ruleset.ritual(rid)
			if not rr.get("implementado", false):
				continue
			for forma in [""] + rr.get("formas", {}).keys():
				if forma != "":
					var f: Dictionary = rr.formas[forma]
					if int(f.get("circulo", 1)) > agente.circulo_maximo() or (f.get("afinidade", false) and agente.afinidade != rr.elemento):
						continue
				_opt_ritual.add_item("%s%s (%d PE)" % [rr.nome, "" if forma == "" else " — " + forma, agente.custo_ritual(rid, forma)])
				_opt_ritual.set_item_metadata(_opt_ritual.item_count - 1, [rid, forma])
				if [rid, forma] == selecionado_antes:
					_opt_ritual.select(_opt_ritual.item_count - 1)
	_btn_ritual.disabled = agente == null or _opt_ritual.item_count == 0
	var com_enigma := _criatura_com_enigma()
	_btn_enigma.visible = com_enigma != null
	if com_enigma != null:
		_btn_enigma.text = "Tocar a melodia" if com_enigma.enigma.get("tipo", "") == "melodia" else "Enigma: %s" % com_enigma.etapa_atual().get("texto", "decifrar")
	_btn_enigma.disabled = agente == null
	_btn_soltar.visible = agente != null and agente.tem(Ser.AGARRADO)
	_opt_ritual.get_parent().visible = _opt_ritual.item_count > 0
	_btn_item.text = "Cicatrizante (%d)" % (agente.equipamento.count("cicatrizante") if agente != null else 0)
	_spin_foco.max_value = agente.pe_disponivel_no_turno() if agente != null else 0
	_chk_ae.visible = agente != null and agente.classe_id == "combatente"
	_barra_membrana.value = membrana.valor
	_lbl_membrana.text = "%d — %s" % [membrana.valor, membrana.estado().get("nome", "")]
	_desenhar_slots()
	_atualizar_3d()


func _ficha(ser: Ser) -> String:
	if ser == null:
		return ""
	var linhas := ["%s — PV %d/%d  Defesa %d" % [ser.nome, ser.pv, ser.pv_maximo, ser.defesa()]]
	if ser is Agente:
		var a := ser as Agente
		linhas[0] = "%s (%s, NEX %d%%) — PV %d/%d  PE %d/%d  SAN %d/%d  Defesa %d" % [a.nome, a.classe_id, a.nex, a.pv, a.pv_maximo, a.pe, a.pe_maximo, a.san, a.san_maximo, a.defesa()]
	linhas.append("Arma: %s (%s)" % [armas[ser].get("nome", "?"), armas[ser].get("dano", "?")])
	if not ser.condicoes.is_empty():
		linhas.append("Condições: %s" % ", ".join(PackedStringArray(ser.condicoes.keys())))
	if ser is Ameaca and (ser as Ameaca).enigma_pendente():
		linhas.append("Enigma de Medo: imune a dano até alguém decifrar.")
	return "\n".join(PackedStringArray(linhas))


func _desenhar_slots() -> void:
	for filho in _slots.get_children():
		filho.queue_free()
	if _ultimo_teste == null:
		_lbl_resultado.text = "—"
		return
	var marcado := false
	for valor in _ultimo_teste.slots:
		var caixa := PanelContainer.new()
		var estilo := StyleBoxFlat.new()
		var eh_escolhido := valor == _ultimo_teste.escolhido and not marcado
		if eh_escolhido:
			marcado = true
			estilo.bg_color = Color("1e8449") if _ultimo_teste.sucesso else Color("922b21")
		else:
			estilo.bg_color = Color("34495e") if not _ultimo_teste.usa_pior else Color("6e2c00")
		estilo.set_content_margin_all(6)
		caixa.add_theme_stylebox_override("panel", estilo)
		var l := Label.new()
		l.text = "d20: %d" % valor
		caixa.add_child(l)
		_slots.add_child(caixa)
	_lbl_resultado.text = "%s %d %+d = %d contra %d → %s" % [
		"pior" if _ultimo_teste.usa_pior else "maior", _ultimo_teste.escolhido, _ultimo_teste.bonus,
		_ultimo_teste.total, _ultimo_teste.dt, "SUCESSO" if _ultimo_teste.sucesso else "FALHA"]


func _entrada_tabuleiro(evento: InputEvent) -> void:
	if _tab3d == null:
		return
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var c := _tab3d.celula_em(evento.position)
		if grade.dentro(c):
			_clicar_celula(c)
		return
	if _tab3d.rig.tratar_entrada(evento):
		_vista.accept_event()


func _unhandled_input(evento: InputEvent) -> void:
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
	if agente != null and _modo == "atacar":
		for s in grade.seres():
			if s.lado != agente.lado and _pode_atacar(agente, s, armas[agente]):
				alvos.append(s)
	var zonas: Array = []
	for z in combate.zonas():
		zonas.append({"celulas": z.celulas, "elemento": ruleset.ritual(z.ritual).elemento})
	_tab3d.atualizar(destinos, alvos, combate.ser_atual(), _selecionado, zonas)
