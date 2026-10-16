extends GutTest
## Fase 8.3 (ADR 0007): Modo Mestre. O mestre joga as ameaças por comando, narra, mexe na
## Membrana e no mapa; só o peer dele manda esses comandos, e todos aplicam no mesmo ponto.

var rs: Ruleset


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _json(v):
	return JSON.parse_string(JSON.stringify(v))


func _carreira_com_mestre(semente: int) -> Carreira:
	var c := Carreira.nova(rs)
	c.controles.definir_mestre(0)
	c.iniciar_missao(c.roster.duplicate(), semente)
	return c


# --- Controles e opções -----------------------------------------------------------------

func test_controles_do_mestre():
	var ctl := ControleLocal.padrao()
	assert_eq(ctl.mestre, -1)
	assert_eq(ctl.mestre_peer(), 1, "sem mestre, o host assume")
	var j := ctl.adicionar_jogador_rede(55, "Ana")
	ctl.definir_mestre(j)
	assert_eq(ctl.mestre_peer(), 55)
	assert_false(ctl.e_mestre_local(), "no host, o mestre é a Ana")
	ctl.meu_peer = 55
	assert_true(ctl.e_mestre_local())
	assert_string_contains(ctl.descricao_mestre(), "Ana")
	var volta := ControleLocal.de_dicionario(_json(ctl.para_dicionario()))
	assert_eq(volta.mestre, j)
	ctl.remover_peer(55)
	assert_eq(ctl.mestre, -1, "o mestre saiu: o host assume")
	assert_eq(ctl.mestre_peer(), 1)


func test_missao_com_mestre_espera_o_mestre_nas_ameacas():
	var c := _carreira_com_mestre(3)
	var m := c.missao
	assert_true(m.opcoes.mestre)
	m._preparar_encontro(m.posicao(m.agente_atual()), "emboscada", false)
	assert_true(m.encontro_pendente.mestre)
	var c2 := Carreira.de_dicionario(_json(c.para_dicionario()), rs)
	assert_true(c2.missao.encontro_pendente.mestre, "vale também depois de carregar")
	var sem := Carreira.nova(rs)
	sem.iniciar_missao(sem.roster.duplicate(), 3)
	assert_false(sem.missao.opcoes.mestre)


# --- Comandos do mestre -------------------------------------------------------------------

func _mestre(m: Missao, acao: String, args: Dictionary = {}) -> Dictionary:
	return Comandos.aplicar_mestre(m, _json(Comandos.novo("mestre", acao, args)))


func _hex_livre(m: Missao) -> Vector2i:
	for h in m.mapa.celulas:
		if Comandos._hex_livre(m, h):
			return h
	return Vector2i(-999, -999)


func test_comandos_do_mestre():
	var m := _carreira_com_mestre(4).missao
	assert_true(_mestre(m, "narrar", {"texto": "A porta range. [b]sozinha[/b]"}).ok)
	assert_string_contains(m.historico.back(), "A porta range. (b)sozinha(/b)")
	assert_false(_mestre(m, "narrar", {"texto": "  "}).ok)
	var antes := m.membrana.valor
	assert_true(_mestre(m, "membrana", {"valor": -5}).ok)
	assert_eq(m.membrana.valor, antes - 5)
	var livre := _hex_livre(m)
	assert_true(_mestre(m, "revelar", {"hex": Comandos.vetor(livre), "raio": 0}).ok)
	assert_true(m.mapa.revelado(livre))
	assert_false(_mestre(m, "encontro", {"hex": Comandos.vetor(livre), "id": "nao_existe"}).ok)
	assert_true(_mestre(m, "encontro", {"hex": Comandos.vetor(livre), "id": "emboscada"}).ok)
	assert_eq(m.mapa.conteudo(livre).encontro, "emboscada")
	assert_false(_mestre(m, "evento", {"hex": Comandos.vetor(livre), "id": "pegadas"}).ok, "o hex já tem conteúdo")
	assert_true(_mestre(m, "limpar", {"hex": Comandos.vetor(livre)}).ok)
	assert_true(_mestre(m, "evento", {"hex": Comandos.vetor(livre), "id": "pegadas"}).ok)
	assert_false(_mestre(m, "limpar", {"hex": Comandos.vetor(m.mapa.encontrar("objetivo"))}).ok, "o covil não some")
	var a := m.agentes[0]
	assert_true(_mestre(m, "ferir", {"agente": a.id, "valor": 5}).ok)
	assert_eq(a.pv, a.pv_maximo - 5)
	assert_true(_mestre(m, "curar", {"agente": a.id, "valor": 3}).ok)
	assert_eq(a.pv, a.pv_maximo - 2)
	var san := a.san
	assert_true(_mestre(m, "sanidade", {"agente": a.id, "valor": -2}).ok)
	assert_eq(a.san, san - 2)
	assert_false(_mestre(m, "voar").ok)


# --- Sessão: só o mestre, e na mesma tela ------------------------------------------------------

var _aplicados: Array = []


func _anotar(cmd: Dictionary) -> Dictionary:
	_aplicados.append(cmd)
	return {"ok": true}


func test_so_o_peer_do_mestre_manda():
	var host := Sessao.new()
	host.iniciar_host()
	host.validar_mestre = func(peer): return peer == 7
	host.registrar_mestre(_anotar)
	host.entrar("mapa", _anotar)
	host.liberar()
	var transmitidos: Array = []
	host.transmitir.connect(func(_n, cmd, _h): transmitidos.append(cmd))
	var recusas: Array = []
	host.recusado.connect(func(peer, _c, motivo): recusas.append([peer, motivo]))
	host.receber_pedido(3, Comandos.novo("mestre", "narrar", {"texto": "oi"}))
	host.enviar(Comandos.novo("mestre", "narrar", {"texto": "oi"}))
	assert_eq(recusas.size(), 2)
	assert_eq(recusas[0][1], "só o mestre faz isso")
	host.receber_pedido(7, Comandos.novo("mestre", "narrar", {"texto": "oi"}))
	assert_eq(transmitidos.size(), 1)
	assert_eq(transmitidos[0].tela, "mapa", "o host marca a tela em que aceitou")


func test_cliente_aplica_o_mestre_na_mesma_tela():
	_aplicados.clear()
	var cli := Sessao.new()
	cli.iniciar_cliente()
	cli.registrar_mestre(_anotar)
	cli.entrar("mapa", _anotar)
	cli.liberar()
	var cmd := Comandos.novo("mestre", "narrar", {"texto": "na arena"})
	cmd["tela"] = "combate"
	cli.receber(1, cmd, 0)
	assert_eq(_aplicados.size(), 0, "o host aceitou na arena: espera a arena")
	cli.sair("mapa")
	cli.entrar("combate", _anotar)
	cli.liberar()
	assert_eq(_aplicados.size(), 1)
	assert_eq(cli.seq, 1)


# --- Ameaças pelo mestre --------------------------------------------------------------------------

func _fluxo_com_mestre(semente: int) -> FluxoCombate:
	var m := _carreira_com_mestre(semente).missao
	m._preparar_encontro(m.posicao(m.agente_atual()), "celula_cultista", false)
	var f := FluxoCombate.montar(rs, m.encontro_pendente, m.membrana)
	f.iniciar()
	f.avancar_ate_decisao()
	return f


func _cmd(f: FluxoCombate, acao: String, args: Dictionary = {}) -> Dictionary:
	var cmd := Comandos.novo("combate", acao, args)
	cmd["ator"] = Comandos.ref(f.combate, f.combate.ser_atual())
	return _json(cmd)


func _jogar(f: FluxoCombate, cmd: Dictionary) -> Dictionary:
	var res := f.aplicar(cmd)
	if cmd.acao in ["encerrar_turno", "ia"] and res.ok:
		f.avancar_ate_decisao()
	return res


func test_mestre_joga_as_ameacas_e_o_combate_se_refaz():
	var a := _fluxo_com_mestre(31)
	assert_true(a.ameacas_pelo_mestre)
	var gravado: Array = []
	var vezes_do_mestre := 0
	var ataques_do_mestre := 0
	var passos := 0
	while a.decisor() != null and passos < 500:
		passos += 1
		var ser := a.decisor()
		var cmds: Array = []
		if ser is Ameaca:
			vezes_do_mestre += 1
			var alvo := IaCombate.inimigo_mais_proximo(a.combate, ser)
			var arma: Dictionary = a.armas[ser] if (ser as Ameaca).ataques.is_empty() else (ser as Ameaca).ataques[0]
			if alvo != null and IaCombate.pode_atacar(a.combate, ser, alvo, arma):
				cmds.append(_cmd(a, "agredir", {"alvo": Comandos.ref(a.combate, alvo), "arma": 0}))
				cmds.append(_cmd(a, "encerrar_turno"))
				ataques_do_mestre += 1
			else:
				cmds.append(_cmd(a, "ia"))
		else:
			cmds.append(_cmd(a, "ia"))   # os agentes no automático, por comando
		for cmd in cmds:
			if a.decisor() != ser:
				break
			gravado.append({"cmd": cmd, "hash": a.hash_estado()})
			_jogar(a, cmd)
	assert_true(a.combate.encerrado, "o combate acaba")
	assert_gt(vezes_do_mestre, 0, "o mestre teve vez")
	gut.p("vezes do mestre: %d, ataques escolhidos: %d" % [vezes_do_mestre, ataques_do_mestre])
	var b := _fluxo_com_mestre(31)
	for g in gravado:
		assert_eq(b.hash_estado(), int(g.hash), "antes de %s" % g.cmd.acao)
		_jogar(b, g.cmd)
	assert_eq(b.hash_estado(), a.hash_estado())


func test_sem_mestre_a_ia_joga_as_ameacas():
	var m := Missao.nova(31)
	m._preparar_encontro(m.posicao(m.agente_atual()), "celula_cultista", false)
	var f := FluxoCombate.montar(rs, m.encontro_pendente, m.membrana)
	f.iniciar()
	var ser := f.avancar_ate_decisao()
	assert_true(ser is Agente, "só agentes esperam decisão")


# --- Telas -----------------------------------------------------------------------------------------

func test_arena_mostra_os_controles_do_mestre():
	var m := _carreira_com_mestre(32).missao
	m._preparar_encontro(m.posicao(m.agente_atual()), "celula_cultista", false)
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.config = m.encontro_pendente
	arena.semente = 5
	add_child_autofree(arena)
	var viu_mestre := false
	for i in 60:
		await wait_frames(2)
		if arena.combate.encerrado:
			break
		if arena._ameaca_da_vez() != null:
			viu_mestre = true
			assert_true(arena._caixa_mestre.visible)
			assert_string_contains(arena._lbl_vez.text, "mestre")
			arena._ia_mestre()
		elif arena._agente_da_vez() != null:
			assert_false(arena._caixa_mestre.visible)
			arena._encerrar_turno()
	assert_true(viu_mestre, "a vez de uma ameaça parou para o mestre")


func test_mapa_mostra_o_painel_do_mestre():
	var jogo = get_node("/root/Jogo")
	var carreira_antes = jogo.carreira
	var salvar_antes: bool = jogo.salvar_automaticamente
	jogo.salvar_automaticamente = false
	jogo.carreira = _carreira_com_mestre(6)
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	assert_true(tela._btn_painel_mestre.visible)
	assert_true(tela._mapa3d.ver_tudo, "o mestre vê o mapa inteiro")
	assert_string_contains(tela._lbl_caso_mestre.text, "Quem:")
	tela._txt_narrar.text = "Chove forte."
	tela._narrar()
	assert_string_contains(jogo.carreira.missao.historico.back(), "Chove forte.")
	assert_eq(jogo.sessao.registro.back().ctx, "mestre")
	jogo.carreira.controles.meu_peer = 99   # outra máquina: não é o mestre
	tela._atualizar()
	assert_false(tela._btn_painel_mestre.visible)
	assert_false(tela._mapa3d.ver_tudo)
	jogo.carreira = carreira_antes
	jogo.salvar_automaticamente = salvar_antes
