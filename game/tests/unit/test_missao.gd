extends GutTest
## Regras da missão no mapa: movimento em slots, eventos, encontros, turno do mundo.


func _missao() -> Missao:
	return Missao.nova(42)


func test_missao_comeca_com_o_grupo_no_inicio():
	var m := _missao()
	assert_eq(m.agentes.size(), 3)
	var inicio := m.mapa.encontrar("inicio")
	for a in m.agentes:
		assert_eq(m.posicao(a), inicio)
	assert_eq(m.agente_atual(), m.agentes[0])


func test_rolar_movimento_conta_slots_acima_da_dt():
	var m := _missao()
	var mauro := m.agente_atual()   # AGI 1 + 2 extras -> 3 slots
	m.dados.forcar([15, 3, 11])
	var r := m.rolar_movimento()
	assert_eq(r.slots, [15, 3, 11])
	assert_eq(r.total, 4, "base 2 + 2 sucessos")
	assert_true(m.rolar_movimento().is_empty(), "uma rolagem por turno")
	assert_eq(m.movimento_restante, 4)
	m.encerrar_turno()
	var bianca := m.agente_atual()  # AGI 2 + 2 extras + 1 de Foco = 5 slots
	m.dados.forcar([3, 12, 20, 1, 5])
	assert_eq(m.rolar_movimento(1).total, 4)
	assert_eq(bianca.pe, bianca.pe_maximo - 1)
	assert_ne(mauro, bianca)


func test_mover_gasta_movimento_e_revela():
	var m := _missao()
	m.dados.forcar([20])
	m.rolar_movimento()
	var destinos := m.destinos()
	assert_false(destinos.is_empty())
	var alvo: Vector2i = destinos.keys()[0]
	assert_true(m.mover(alvo))
	assert_eq(m.posicao(m.agente_atual()), alvo)
	assert_true(m.mapa.revelado(alvo))
	assert_false(m.mover(Vector2i(500, 500)))


func test_evento_aplica_efeitos_e_some_do_mapa():
	var m := _missao()
	var a := m.agente_atual()
	var h := m.posicao(a) + Vector2i(1, 0)
	m.mapa.celulas[h].terreno = "campo"
	m.mapa.definir_conteudo(h, {"tipo": "evento", "evento": "ponte_podre"})
	m.movimento_rolado = true
	m.movimento_restante = 3
	assert_true(m.mover(h))
	assert_false(m.evento_pendente.is_empty())
	assert_true(m.ocupado())
	m.dados.forcar([1, 4, 1, 1])   # Atletismo: Mauro (FOR 3) rola 3 slots -> 4 + 5 = 9 < 12; 1d6 de dano = 1
	var pv := a.pv
	var r := m.resolver_evento()
	assert_false(r.sucesso)
	assert_lt(a.pv, pv)
	assert_true(m.mapa.conteudo(h).is_empty())
	assert_false(m.ocupado())


func test_encontro_monta_combate_com_aliados_proximos():
	var m := _missao()
	var a := m.agente_atual()
	var h := m.posicao(a) + Vector2i(1, 0)
	m.mapa.celulas[h].terreno = "campo"
	m.mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": "celula_cultista"})
	m.movimento_rolado = true
	m.movimento_restante = 3
	watch_signals(m)
	m.mover(h)
	assert_signal_emitted(m, "encontro_iniciado")
	var cfg := m.encontro_pendente
	assert_eq(cfg.agentes.size(), 3, "os outros dois estão a até 2 hexes e entram no combate")
	assert_eq(cfg.ameacas.size(), 1, "3 agentes de NEX 5% = orçamento de VD 15 (p.187): só a ameaça mais fraca")
	m.concluir_encontro("agentes")
	assert_true(m.mapa.conteudo(h).is_empty())
	assert_false(m.encerrada)


func test_derrota_no_hardcore_mata_e_encerra_a_missao():
	var m := Missao.nova(42, null, [], {"modo_morte": "hardcore"})
	m._preparar_encontro(m.posicao(m.agente_atual()), "emboscada", false)
	for a in m.encontro_pendente.agentes:
		a.sofrer_dano(1000)
	m.concluir_encontro("ameacas")
	assert_eq(m.mortos.size(), 3)
	assert_true(m.encerrada)
	assert_false(m.vitoria)


func test_derrota_no_modo_normal_gasta_reforcos():
	var m := Missao.nova(42)   # modo Normal: 2 Reforços da Ordem
	assert_eq(m.reforcos, 2)
	m._preparar_encontro(m.posicao(m.agente_atual()), "emboscada", false)
	for a in m.encontro_pendente.agentes:
		a.sofrer_dano(1000)
	m.concluir_encontro("ameacas")
	assert_eq(m.resgatados.size(), 2, "dois agentes resgatados")
	assert_eq(m.mortos.size(), 1, "o terceiro, sem reforço, morre")
	assert_eq(m.reforcos, 0)
	for a in m.resgatados:
		assert_false(a.tem(Ser.MORTO))
	assert_true(m.encerrada, "ninguém sobrou em campo")


func test_quem_nao_caiu_continua_a_missao():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	m._preparar_encontro(m.posicao(a), "emboscada", false)
	a.sofrer_dano(1000)
	m.concluir_encontro("ameacas")
	assert_eq(m.resgatados, [a] as Array[Agente])
	assert_eq(m.agentes.size(), 2)
	assert_false(m.encerrada)


func test_vencer_o_covil_cumpre_a_missao():
	var m := _missao()
	m.caso.elemento = "sangue"   # o covil segue o elemento do caso (docs/52)
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	assert_eq(m.encontro_pendente.ameacas[0].nome, "Horror Carmesim")
	m.concluir_encontro("agentes")
	assert_true(m.encerrada)
	assert_true(m.vitoria)


func test_turno_do_mundo_enfraquece_a_membrana_e_faz_surgir_ameacas():
	var m := _missao()
	m.membrana.valor = 60   # Instável: nível de ameaça 1
	var antes := 0
	for h in m.mapa.celulas:
		if m.mapa.conteudo(h).get("tipo", "") == "encontro":
			antes += 1
	for i in 9:   # 3 agentes x 3 turnos do mundo
		m.encerrar_turno()
	assert_eq(m.turno_mundo, 4)
	assert_eq(m.membrana.valor, 54, "−2 por turno do mundo")
	var depois := 0
	for h in m.mapa.celulas:
		if m.mapa.conteudo(h).get("tipo", "") == "encontro":
			depois += 1
	assert_eq(depois, antes + 1, "um surgimento a cada 2 turnos com a Membrana instável (no turno 3; o próximo no 5)")


func test_descanso_na_cidade():
	var m := _missao()
	var a := m.agente_atual()
	a.sofrer_dano(10)
	assert_true(m.pode_descansar(), "o início é uma cidade")
	assert_true(m.descansar())
	assert_gt(a.pv, a.pv_maximo - 10)
	assert_false(m.pode_descansar(), "uma vez por visita")


func test_combate_completo_da_missao_na_arena():
	var m := _missao()
	m._preparar_encontro(m.posicao(m.agente_atual()), "celula_cultista", false)
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.config = m.encontro_pendente
	arena.autoplay = true
	arena.semente = 5
	add_child_autofree(arena)
	assert_true(arena.combate.encerrado)
	m.concluir_encontro(arena._vencedor)
	assert_true(m.encontro_pendente.is_empty())


func test_agente_sozinho_enfrenta_no_maximo_uma_ameaca():
	var m := _missao()
	var a := m.agente_atual()
	var longe := m.posicao(a) + Vector2i(5, 0)
	for outro in m.agentes:
		if outro != a:
			m.posicoes[outro] = longe
	m._preparar_encontro(m.posicao(a), "ritual_interrompido", false)   # 3 ameaças no total
	assert_eq(m.encontro_pendente.agentes.size(), 1)
	assert_eq(m.encontro_pendente.ameacas.size(), 1)


func test_aliado_a_dois_hexes_entra_no_combate():
	var m := _missao()
	var a := m.agente_atual()
	var b: Agente = m.agentes[1]
	var c: Agente = m.agentes[2]
	m.posicoes[b] = m.posicao(a) + Vector2i(2, 0)
	m.posicoes[c] = m.posicao(a) + Vector2i(3, 0)
	m._preparar_encontro(m.posicao(a), "celula_cultista", false)
	assert_true(b in m.encontro_pendente.agentes)
	assert_false(c in m.encontro_pendente.agentes)


func _com_evento(m: Missao, evento_id: String) -> Agente:
	var a := m.agente_atual()
	var h := m.posicao(a) + Vector2i(1, 0)
	m.mapa.celulas[h].terreno = "campo"
	m.mapa.definir_conteudo(h, {"tipo": "evento", "evento": evento_id})
	m.movimento_rolado = true
	m.movimento_restante = 3
	m.mover(h)
	return a


func test_eventos_tem_varias_opcoes():
	var m := _missao()
	var a := _com_evento(m, "morador")
	var ops := m.opcoes_do_evento()
	assert_gt(ops.size(), 3, "diplomacia, intimidação, enganação, luta… e seguir em frente")
	var pericias := ops.map(func(o): return o.get("pericia", ""))
	assert_has(pericias, "intimidacao")
	if not a.pericias.has("sobrevivencia"):
		assert_does_not_have(pericias, "sobrevivencia", "a opção de caçador só aparece para quem é treinado")


func test_evento_sem_teste_so_segue_em_frente():
	var m := _missao()
	var a := _com_evento(m, "morador")
	var ops := m.opcoes_do_evento()
	var i := ops.find(ops.filter(func(o): return o.get("sem_teste", false))[0])
	var pv := a.pv
	var r := m.resolver_evento(0, i)
	assert_true(r.sucesso)
	assert_null(r.teste)
	assert_eq(a.pv, pv)
	assert_true(m.evento_pendente.is_empty())


func test_item_fora_de_combate_gasta_a_acao_do_turno():
	var m := _missao()
	var a := m.agente_atual()
	a.equipamento.append("cicatrizante")
	a.equipamento.append("cicatrizante")
	a.sofrer_dano(5)
	var pv := a.pv
	assert_has(m.itens_fora_de_combate(a), "cicatrizante")
	var r := m.usar_item_no_mapa("cicatrizante", a)
	assert_false(r.is_empty())
	assert_gt(a.pv, pv)
	assert_true(m.acao_usada)
	assert_true(m.usar_item_no_mapa("cicatrizante", a).is_empty(), "uma ação por turno")
	m.encerrar_turno()
	assert_false(m.acao_usada, "a ação volta no turno seguinte")


func test_ritual_de_cura_fora_de_combate():
	var m := _missao()
	var a := m.agente_atual()
	a.rituais.append("cicatrizacao")
	a.pe = a.pe_maximo
	var alvo: Agente = m.agentes[1]
	alvo.sofrer_dano(6)
	assert_has(m.rituais_fora_de_combate(a), ["cicatrizacao", ""])
	var pv := alvo.pv
	var pe := a.pe
	var r := m.conjurar_no_mapa("cicatrizacao", "", alvo)
	assert_false(r.is_empty(), "o aliado está no mesmo hex (toque)")
	assert_gt(alvo.pv, pv)
	assert_lt(a.pe, pe)
	assert_eq(Comandos.aplicar_mapa(m, Comandos.novo("mapa", "conjurar", {"ritual": "cicatrizacao", "forma": "", "alvo": alvo.id})).ok, false, "já usou a ação")


func test_evento_devolve_os_efeitos_para_o_desfecho():
	var m := _missao()
	var a := _com_evento(m, "ponte_podre")
	m.dados.forcar([1, 1, 1, 1, 3])   # falha no Atletismo; 1d6 de dano = 3
	var r := m.resolver_evento(0, 0)
	assert_false(r.sucesso)
	assert_eq(r.titulo, "Ponte podre")
	assert_eq(r.efeitos.size(), 1)
	assert_eq(r.efeitos[0].tipo, "dano")
	assert_string_starts_with(r.efeitos[0].texto, "−")
