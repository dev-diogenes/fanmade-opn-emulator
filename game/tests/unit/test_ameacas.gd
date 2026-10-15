extends GutTest
## Ameaças do livro (cap. 7, p.186-299): fichas, ataques x2, habilidades e orçamento de VD (p.187).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func _agente(nome: String = "Alvo") -> Agente:
	return Agente.criar(rs, nome, "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado", "fortitude": "treinado"}, 5)


func _combate(regras: Dictionary = {}) -> Combate:
	return Combate.new(rs, Dados.new(1), regras)


# --- Fichas -----------------------------------------------------------------------

func test_fichas_do_livro_carregam():
	assert_eq(rs.lista_ameacas().size(), 42)
	for a in rs.lista_ameacas():
		var info := DadosJogo.ameaca(rs, a.id)
		var amea := Ameaca.criar(rs, info.nome, info.ficha)
		assert_gt(amea.pv_maximo, 0, a.id)
		assert_true(not amea.ataques.is_empty() or amea.tem_hab("enxame"), "%s tem ataques" % a.id)
		for at in amea.ataques:
			assert_true(at.has("teste"), "%s: ataque com teste da ficha" % a.id)
		assert_eq(info.vd, int(a.vd))


func test_zumbi_de_sangue():
	var z := _ameaca("zumbi_de_sangue")
	assert_eq(z.pv_maximo, 45)
	assert_eq(z.defesa(), 17)
	assert_eq(z.resistencia("impacto"), 5)
	assert_eq(z.resistencia("sangue"), 10)
	assert_eq(z.dados_da_pericia("fortitude"), 2)
	assert_eq(z.bonus_pericia("fortitude"), 5)
	assert_true(z.criatura)
	assert_eq(z.presenca.dt, 15.0)
	var c := _combate()
	assert_eq(c.aplicar_dano(z, 10, "morte"), 20, "vulnerável a Morte")


func test_ataque_x2_numa_acao():
	var c := _combate()
	var z := _ameaca("zumbi_de_sangue")
	var alvo := _agente()
	c.adicionar(z)
	c.adicionar(alvo)
	c.acoes[z] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([15, 15, 3, 15, 15, 3])
	var r := c.agredir(z, alvo, z.ataques[0])
	assert_true(r.acertou)
	assert_eq(r.ataques_extras.size(), 1)
	assert_eq(alvo.pv, alvo.pv_maximo - 16, "duas garras de 1d6+5")


func test_ataque_furtivo_uma_vez_por_rodada():
	var c := _combate()
	var b := _ameaca("bandido")
	var alvo := _agente()
	alvo.aplicar_condicao(Ser.DESPREVENIDO)
	c.dados.forcar([15, 15, 2, 3])
	c.atacar(b, alvo, b.ataques[0])
	assert_eq(alvo.pv, alvo.pv_maximo - 7, "1d4+2 e +1d6 furtivo")
	c.dados.forcar([15, 15, 2])
	c.atacar(b, alvo, b.ataques[0])
	assert_eq(alvo.pv, alvo.pv_maximo - 11)


# --- Habilidades passivas ----------------------------------------------------------

func test_imortalidade_do_esqueleto():
	var c := _combate()
	var esq := _ameaca("esqueleto_de_lodo")
	c.adicionar(esq)
	c.dados.forcar([2])
	c.aplicar_dano(esq, 100, "corte")
	assert_true(esq.tem(Ser.POCA))
	assert_true(esq.esta_fora_de_combate())
	assert_eq(c.aplicar_dano(esq, 30, "corte"), 0, "só fogo ou Energia destroem a poça")
	c._processar_pocas()
	assert_true(esq.tem(Ser.POCA))
	c._processar_pocas()
	assert_false(esq.tem(Ser.POCA))
	assert_eq(esq.pv, 20, "volta com 20 PV")
	c.dados.forcar([1])
	c.aplicar_dano(esq, 100, "corte")
	c.aplicar_dano(esq, 1, "energia")
	assert_true(esq.tem(Ser.MORTO))


func test_enraizado_dano_extra_e_veneno():
	var c := _combate()
	var en := _ameaca("enraizado")
	var alvo := _agente()
	c.dados.forcar([15, 15, 15, 1, 1, 1, 1])
	var r := c.atacar(en, alvo, en.ataques[0])
	assert_eq(r.dano, 10 + 2, "2d8+8 de impacto mais 2d12 de Morte")
	assert_true(alvo.mods_cena.has("veneno"))
	var pv := alvo.pv
	c.dados.forcar([1, 1, 1, 1, 1, 1])
	c._inicio_de_turno_ameacas(alvo)
	assert_eq(alvo.pv, pv - 4, "falhou em Fortitude: 4d12 de Morte")
	c.dados.forcar([20, 20])
	c._inicio_de_turno_ameacas(alvo)
	assert_false(alvo.mods_cena.has("veneno"))


func test_aberracao_agarra_abocanha_e_solta():
	var c := _combate()
	var ab := _ameaca("aberracao_de_carne")
	var alvo := _agente()
	c.dados.forcar([15, 15, 15, 1, 1, 20, 20, 20, 1])
	c.atacar(ab, alvo, ab.ataques[0])
	assert_true(alvo.tem(Ser.AGARRADO))
	var pv := alvo.pv
	c.dados.forcar([2, 2, 2, 1, 1])
	c._inicio_de_turno_ameacas(ab)
	assert_eq(alvo.pv, pv - 6, "abocanhado: 3d6 de perfuração")
	c.dados.forcar([20, 1, 1, 1])
	assert_true(c.escapar(alvo))
	assert_false(alvo.tem(Ser.AGARRADO))
	assert_true(ab.mods_cena.get("agarrando", []).is_empty())


func test_succ_prende_e_solta_com_dano():
	var c := _combate()
	var succ := _ameaca("succ")
	var alvo := _agente()
	c.dados.forcar([15, 15, 15, 15, 1, 1, 1, 1])
	c.atacar(succ, alvo, succ.ataques[0])
	assert_true(alvo.tem(Ser.INCONSCIENTE))
	c.aplicar_dano(succ, 12, "balistico")
	assert_false(alvo.tem(Ser.INCONSCIENTE), "10 de dano na rodada faz o succ soltar")
	c.dados.forcar([15, 15, 15, 15, 1, 1, 1, 1])
	c.atacar(succ, alvo, succ.ataques[0])
	c._inicio_de_turno_ameacas(succ)
	assert_eq(alvo.pv, 0, "no turno seguinte do succ, a vítima vai a 0 PV")


func test_teimoso_e_ferocidade():
	var c := _combate()
	var chefe := _ameaca("chefe_de_policia")
	assert_eq(c.aplicar_dano(chefe, 40, "impacto"), 20)
	assert_eq(c.aplicar_dano(chefe, 40, "impacto"), 40, "uma vez por cena")
	var jav := _ameaca("javaporco")
	c.aplicar_dano(jav, 5, "corte")
	assert_true(jav.mods_cena.get("ferocidade", false))


func test_perturbado_implanta_confusao():
	var c := _combate()
	var pe := _ameaca("perturbado_de_energia")
	var alvo := _agente()
	var san := alvo.san
	c.dados.forcar([15, 15, 15, 15, 5, 5, 20, 20, 20, 20, 1, 4, 4, 1])
	c.atacar(pe, alvo, pe.ataques[0])
	assert_eq(alvo.san, san - 8)
	assert_true(alvo.vulneravel_a("energia"))
	assert_eq(c.aplicar_dano(alvo, 3, "energia"), 6)


func test_aceleracao_do_anarquico():
	var c := _combate()
	var an := _ameaca("anarquico_descontrolado")
	var alvo := _agente()
	c.dados.forcar([15, 15, 15, 15, 1, 1, 1, 1])
	c.atacar(an, alvo, an.ataques[0])
	c._inicio_de_turno_ameacas(alvo)
	c.acoes[alvo] = {"padrao": 1, "movimento": 1}
	var pv := alvo.pv
	c.gastar_acao(alvo, "movimento")
	assert_eq(alvo.pv, pv)
	c.dados.forcar([2, 2, 2, 2])
	c.gastar_acao(alvo, "padrao")
	assert_eq(alvo.pv, pv - 8, "movimento + padrão acelerado: 4d12 de Energia")


# --- Habilidades ativas e rituais de cultistas --------------------------------------

func test_brilho_e_fortalecimento_do_existido():
	var c := _combate()
	var ex := _ameaca("existido")
	var alvo := _agente()
	c.adicionar(ex)
	c.adicionar(alvo)
	assert_false(c.usar_habilidade(ex, "fortalecimento_paranormal").ok, "só depois de ferir com o brilho")
	var san := alvo.san
	c.dados.forcar([6, 1])
	assert_true(c.usar_habilidade(ex, "brilho_enlouquecedor").ok)
	assert_eq(alvo.san, san - 6)
	assert_false(c.usar_habilidade(ex, "brilho_enlouquecedor").ok, "uma vez por rodada")
	assert_true(c.usar_habilidade(ex, "fortalecimento_paranormal").ok)
	assert_eq(ex.efeito_ritual("dados_ataque"), 1)


func test_vulto_planta_paranoia():
	var c := _combate()
	var v := _ameaca("vulto")
	var alvo := _agente()
	c.adicionar(v)
	c.adicionar(alvo)
	c.dados.forcar([1])
	c.usar_habilidade(v, "plantar_paranoia")
	assert_true(alvo.tem(Ser.ABALADO))
	c.dados.forcar([1])
	c.usar_habilidade(v, "plantar_paranoia")
	assert_true(alvo.tem(Ser.APAVORADO))
	c.dados.forcar([15, 15, 15, 15, 3, 3, 3, 3])
	var r := c.atacar(v, alvo, v.ataques[0])
	assert_eq(r.dano, 6 + 6, "Aura Tangível: +2d6 contra quem tem medo")


func test_autodestruicao_e_granada():
	var c := _combate()
	var an := _ameaca("anarquico_descontrolado")
	var alvo := _agente()
	c.adicionar(an)
	c.adicionar(alvo)
	c.dados.forcar([1, 1, 1, 1, 1, 1, 1, 1, 1])
	assert_true(c.usar_habilidade(an, "autodestruicao").ok)
	assert_true(an.tem(Ser.MORTO))
	assert_eq(alvo.pv, alvo.pv_maximo - 8)
	var c2 := _combate()
	var el := _ameaca("policial_de_elite")
	c2.adicionar(el)
	c2.adicionar(_agente())
	assert_true(c2.usar_habilidade(el, "lanca_granadas").ok)
	assert_false(c2.usar_habilidade(el, "lanca_granadas").ok, "uma vez por cena")


func test_cultista_conjura_sem_pe():
	var c := _combate()
	var ini := _ameaca("iniciado")
	var alvo := _agente()
	assert_false(c.conjurar_ameaca(ini, "eletrocussao", alvo).ok, "não conhece")
	c.dados.forcar([1, 1, 3, 3])
	var r := c.conjurar_ameaca(ini, "decadencia", alvo)
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(alvo.pv, alvo.pv_maximo - 8, "Decadência 2d8+2 contra DT 15")


# --- Encontros e IA ---------------------------------------------------------------

func test_orcamento_de_vd():
	var lista := [{"id": "a", "vd": 40}, {"id": "b", "vd": 20}, {"id": "c", "vd": 20}]
	assert_eq(Missao.escolher_por_vd(lista, 45).map(func(x): return x.id), ["a"])
	assert_eq(Missao.escolher_por_vd(lista, 60).map(func(x): return x.id), ["a", "b"])
	assert_eq(Missao.escolher_por_vd(lista, 80).size(), 3)
	assert_eq(Missao.escolher_por_vd(lista, 5).size(), 1, "sempre ao menos a mais fraca")
	assert_eq(int(Missao.escolher_por_vd(lista, 5)[0].vd), 20)


func test_enigma_ligado_a_pergunta_do_caso():
	var c := _combate({"perguntas_respondidas": ["quem"]})
	var sombra := _ameaca("sombra_sussurrante")
	var a := Agente.criar(rs, "Rita", "ocultista", {"agi": 1, "for": 1, "int": 2, "pre": 2, "vig": 2}, {"ocultismo": "treinado"}, 5)
	c.dados.forcar([6, 6])
	assert_false(c.decifrar_enigma(a, sombra).sucesso)
	c.dados.forcar([12, 12])
	assert_true(c.decifrar_enigma(a, sombra).sucesso, "DT 22 − 5 pela pergunta respondida")
	assert_eq(_ameaca("o_que_ficou").enigma.pergunta, "o_que")


func test_ia_escolhe_a_arma():
	var c := _combate()
	c.grade = Grade.new(14, 9)
	var cap := _ameaca("capanga")
	var alvo := _agente()
	c.adicionar(cap)
	c.adicionar(alvo)
	c.grade.colocar(cap, Vector2i(0, 0))
	c.grade.colocar(alvo, Vector2i(1, 0))
	assert_eq(IaAmeaca.escolher_arma(c, cap, alvo, {}).id, "bastao")
	c.grade.remover(alvo)
	c.grade.colocar(alvo, Vector2i(5, 0))
	assert_eq(IaAmeaca.escolher_arma(c, cap, alvo, {}).id, "revolver")


func test_arena_com_ameacas_do_livro():
	var m := Missao.nova(42)
	for a in m.agentes:
		a.nex = 40
		m.posicoes[a] = m.posicao(m.agente_atual())
	m._preparar_encontro(m.posicao(m.agente_atual()), "marcas_douradas", false)
	assert_eq(m.encontro_pendente.ameacas.size(), 2)
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.config = m.encontro_pendente
	arena.autoplay = true
	arena.semente = 3
	add_child_autofree(arena)
	assert_true(arena.combate.encerrado)
