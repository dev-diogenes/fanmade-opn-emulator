extends GutTest
## O arsenal do livro (docs/67): a Tabela 3.3 inteira, munição por cena, armas ágeis,
## automáticas e de recarga, escudo, itens de combate com cargas e a condição cego.

var rs: RulesetOp2022

const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}
const PERICIAS := {"luta": "treinado", "pontaria": "treinado"}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(attrs: Dictionary = ATTRS, classe := "combatente") -> Agente:
	return Agente.criar(rs, "Agente", classe, attrs, PERICIAS)


func _alvo(nome := "Alvo", pv := 100) -> Ameaca:
	return Ameaca.criar(rs, nome, {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1},
		"pericias": {"fortitude": {"dados": 1, "bonus": 0}, "reflexos": {"dados": 1, "bonus": 0}, "luta": {"dados": 1, "bonus": 0}}})


func _combate_em_grade(a: Agente, alvos: Array, posicoes: Array) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.grade = Grade.new(14, 5)
	c.adicionar(a)
	c.grade.colocar(a, posicoes[0])
	for i in alvos.size():
		c.adicionar(alvos[i])
		c.grade.colocar(alvos[i], posicoes[i + 1])
	return c


# --- Catálogo --------------------------------------------------------------------

func test_tabela_de_armas_inteira():
	assert_eq(rs.lista_armas().size(), 34, "Tabela 3.3: 12 simples, 19 táticas, 3 pesadas (p.66-67)")
	for a in rs.lista_armas():
		assert_true(a.has("empunhadura") and a.has("proficiencia") and a.has("espacos") and String(a.get("descricao", "")) != "", a.id)
	assert_eq(int(rs.arma("fuzil_de_assalto").categoria), 2)
	assert_eq(int(rs.arma("fuzil_de_precisao").categoria), 3)
	assert_eq(int(rs.arma("bazuca").categoria), 3)
	assert_eq(String(rs.arma("metralhadora").proficiencia), "armas_pesadas")
	assert_eq([int(rs.arma("revolver").margem), int(rs.arma("revolver").multiplicador)], [19, 3], "19/x3")
	assert_eq([int(rs.arma("gadanho").margem), int(rs.arma("gadanho").multiplicador)], [20, 4], "x4")


func test_todo_item_tem_pagina_e_grupo():
	for lista in [rs.protecoes(), rs.itens_gerais()]:
		for it in lista:
			assert_true(String(it.get("ref", "")).begins_with("p."), "ref: %s" % it.id)
			assert_ne(String(it.get("grupo", "")), "", "grupo: %s" % it.id)
	for id in ["balas_curtas", "balas_longas", "cartuchos", "combustivel", "flechas", "foguete", "escudo", "taser",
			"mochila_militar", "granada_de_fumaca", "camera_aura", "medidor_de_membrana", "amarras_sangue"]:
		assert_false(rs.equipamento(id).is_empty(), id)


# --- Munição (p.69) -------------------------------------------------------------------

func test_sem_municao_so_coronhada():
	var a := _agente()
	a.equipamento.append("pistola")
	a.arma_id = "pistola"
	assert_eq(a.arma().id, "coronhada")
	assert_eq(a.arma().dano, "1d4", "arma leve: 1d4")
	a.equipamento.append("balas_curtas")
	assert_eq(a.arma().id, "pistola")
	a.equipamento.append("fuzil_de_caca")
	a.arma_id = "fuzil_de_caca"
	assert_eq(a.arma().dano, "1d6", "duas mãos: 1d6")
	assert_string_contains(a.aviso_item("fuzil_de_caca"), "coronhada")


func test_pacotes_duram_cenas():
	var a := _agente()
	a.equipamento.append_array(["pistola", "balas_curtas", "fuzil_de_caca", "balas_longas", "arco", "flechas"])
	a.registrar_disparo(rs.arma("pistola"))
	a.registrar_disparo(rs.arma("fuzil_de_caca"))
	a.registrar_disparo(rs.arma("arco"))
	a.encerrar_cena()
	assert_true(a.tem_item("balas_curtas"), "balas curtas: duas cenas")
	assert_false(a.tem_item("balas_longas"), "balas longas: uma cena")
	assert_true(a.tem_item("flechas"), "flechas: a missão inteira")
	a.encerrar_cena()
	assert_true(a.tem_item("balas_curtas"), "cena sem tiro não gasta")
	a.registrar_disparo(rs.arma("pistola"))
	a.encerrar_cena()
	assert_false(a.tem_item("balas_curtas"))
	var dados_salvos := a.para_dicionario()
	assert_true(dados_salvos.has("municao_gasta"))


func test_foguete_se_gasta_no_disparo():
	var a := _agente()
	a.equipamento.append_array(["bazuca", "foguete", "foguete"])
	a.registrar_disparo(rs.arma("bazuca"))
	assert_eq(a.equipamento.count("foguete"), 1)


# --- Habilidades das armas (p.68-69) ---------------------------------------------------

func test_arma_agil_usa_agilidade():
	var a := _agente({"agi": 3, "for": 1, "int": 1, "pre": 1, "vig": 1})
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([15, 15, 15, 2])
	var r := c.atacar(a, _alvo(), rs.arma("faca"))
	assert_eq(r.teste.slots.size(), 3, "três dados da Agilidade, não um da Força")
	assert_eq(r.teste.atributo_id, "agi")
	assert_eq(r.dano, 2 + 3, "a Agilidade também no dano")


func test_rajada_troca_um_dado_por_dano():
	var a := _agente()
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([15, 3, 3, 3])
	var r := c.atacar(a, _alvo(), rs.arma("submetralhadora"), 0, {"rajada": true})
	assert_eq(r.teste.slots.size(), 1, "−1 dado")
	assert_eq(r.dano, 9, "2d6 + 1 dado")


func test_besta_recarrega_com_acao_de_movimento():
	var a := _agente()
	var alvo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(a)
	c.adicionar(alvo)
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([15, 15, 3])
	assert_not_null(c.agredir(a, alvo, rs.arma("besta")).teste)
	assert_eq(a.mods_cena.get("descarregada"), "besta")
	c.acoes[a] = {"padrao": 1, "movimento": 0}
	assert_ne(c.pode_disparar(a, rs.arma("besta")), "")
	assert_null(c.agredir(a, alvo, rs.arma("besta")).teste, "sem ação de movimento, não recarrega")
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([15, 15, 3])
	assert_not_null(c.agredir(a, alvo, rs.arma("besta")).teste)
	assert_eq(c.acoes_restantes(a).movimento, 0, "a recarga gastou o movimento")


func test_motosserra_explode_e_e_desajeitada():
	var a := _agente()
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([15, 6, 2, 3, 4])
	var r := c.atacar(a, _alvo(), rs.arma("motosserra"))
	assert_eq(r.teste.slots.size(), 1, "−1 dado no ataque")
	assert_eq(r.dano, 6 + 2 + 3 + 4 + 2, "o 6 rola mais um dado; soma a Força")


func test_espingarda_perde_metade_longe():
	var a := _agente()
	var alvo := _alvo()
	var c := _combate_em_grade(a, [alvo], [Vector2i(0, 2), Vector2i(8, 2)])
	c.dados.forcar([15, 6, 6, 6, 6])
	var r := c.atacar(a, alvo, rs.arma("espingarda"))
	assert_eq(r.dano, 12, "4d6 = 24, metade além do curto")


func test_lanca_chamas_varre_a_linha():
	var a := _agente()
	a.poderes.append("armamento_pesado")
	var alvo := _alvo("Primeiro")
	var atras := _alvo("Segundo")
	var c := _combate_em_grade(a, [alvo, atras], [Vector2i(0, 2), Vector2i(3, 2), Vector2i(5, 2)])
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([18, 18, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2])
	var r := c.agredir(a, alvo, rs.arma("lanca_chamas"))
	assert_true(r.acertou)
	assert_true(alvo.tem(Ser.EM_CHAMAS))
	assert_eq(atras.pv, 100 - 12, "o mesmo teste atinge quem está na linha")
	assert_true(atras.tem(Ser.EM_CHAMAS))


func test_bazuca_explode_no_alvo():
	var a := _agente()
	a.poderes.append("armamento_pesado")
	var alvo := _alvo("Alvo")
	var perto := _alvo("Perto")
	var c := _combate_em_grade(a, [alvo, perto], [Vector2i(0, 2), Vector2i(6, 2), Vector2i(7, 2)])
	c.dados.forcar([18, 18, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	var r := c.atacar(a, alvo, rs.arma("bazuca"))
	assert_true(r.acertou)
	assert_eq(perto.pv, 90, "a 3 m do alvo, o mesmo dano (falhou em Reflexos)")


func test_proficiencia_tatica_de_fogo():
	var a := _agente(ATTRS, "especialista")
	assert_eq(a.dados_sem_proficiencia(rs.arma("espingarda")), 2)
	a.poderes.append("balistica_avancada")
	assert_eq(a.dados_sem_proficiencia(rs.arma("espingarda")), 0, "táticas de fogo valem para a espingarda")
	assert_eq(a.dados_sem_proficiencia(rs.arma("katana")), 2, "mas não para a katana")


# --- Escudo e empunhadura (p.68 e p.72) ---------------------------------------------

func test_escudo_soma_com_arma_de_uma_mao():
	var a := _agente()
	var base := a.defesa()
	a.equipamento.append_array(["escudo", "machete"])
	a.arma_id = "machete"
	assert_eq(a.defesa(), base + 2)
	a.equipamento.append("acha")
	a.arma_id = "acha"
	assert_eq(a.defesa(), base, "arma de duas mãos: o escudo não protege")
	assert_eq(a.motivo_bloqueio("protecao_leve", ["escudo"]), "", "escudo soma com a proteção")
	assert_eq(a.motivo_bloqueio("escudo", ["escudo"], true), "Basta um.")


func test_arma_versatil_com_e_sem_escudo():
	var a := _agente()
	assert_eq(a.arma_efetiva(rs.arma("bastao")).dano, "1d8", "mão livre: duas mãos")
	a.equipamento.append("escudo")
	assert_eq(a.arma_efetiva(rs.arma("bastao")).dano, "1d6", "com escudo: uma mão")


# --- Requisição em unidades -----------------------------------------------------------

func test_municao_em_mais_de_uma_unidade():
	var a := _agente()
	assert_eq(a.motivo_bloqueio("balas_longas", ["balas_longas"], true), "", "Recruta: dois de categoria I")
	assert_string_contains(a.motivo_bloqueio("balas_longas", ["balas_longas", "balas_longas"], true), "categoria I")
	assert_eq(a.motivo_bloqueio("pistola", ["pistola"], true), "Basta um.")


func test_mochila_militar_aumenta_a_carga():
	var a := _agente()
	var cap := a.capacidade_carga()
	a.equipamento.append("mochila_militar")
	assert_eq(a.capacidade_carga(), cap + 2)
	assert_eq(a.espacos_usados(), 0, "não ocupa espaço")


# --- Itens de combate (p.75-77) -----------------------------------------------------

func test_taser_atordoa_e_a_bateria_acaba():
	var a := _agente()
	a.equipamento.append("taser")
	var alvo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([4, 1])
	var r := c.usar_item_combate(a, "taser", alvo)
	assert_true(r.ok)
	assert_eq(alvo.pv, 96)
	assert_true(alvo.tem(Ser.ATORDOADO))
	c.dados.forcar([3, 20])
	c.usar_item_combate(a, "taser", alvo)
	assert_false(a.tem_item("taser"), "dois usos")
	assert_false(c.usar_item_combate(a, "taser", alvo).ok)


func test_dardos_poem_para_dormir_e_a_caixa_recarrega():
	var a := _agente()
	a.equipamento.append_array(["pistola_de_dardos", "dardos"])
	assert_eq(a.cargas_restantes("pistola_de_dardos"), 4)
	var alvo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([15, 15, 1])
	assert_true(c.usar_item_combate(a, "pistola_de_dardos", alvo).acertou)
	assert_true(alvo.tem(Ser.INCONSCIENTE))
	assert_true(alvo.mods_cena.get("rendido", false), "pessoa dormindo é interrogada depois")
	for i in 2:
		a.usar_carga("pistola_de_dardos")
	assert_false(a.tem_item("dardos"), "a terceira carga abriu a caixa")
	assert_eq(a.cargas_restantes("pistola_de_dardos"), 1)
	assert_true(a.tem_item("pistola_de_dardos"), "a pistola fica")


func test_lanterna_ofusca_uma_vez_por_cena():
	var a := _agente()
	a.equipamento.append("lanterna_tatica")
	var alvo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	assert_true(c.usar_item_combate(a, "lanterna_tatica", alvo).ok)
	assert_true(alvo.tem(Ser.OFUSCADO))
	assert_string_contains(c.motivo_item_combate(a, "lanterna_tatica", alvo), "acostumou")


func test_amarras_so_prendem_quem_teme_o_elemento():
	var a := _agente()
	a.equipamento.append("amarras_morte")
	var pessoa := _alvo()
	assert_ne(Combate.new(rs, Dados.new(1)).motivo_item_combate(a, "amarras_morte", pessoa), "")
	var dama := Ameaca.criar(rs, "Dama", rs.ameaca("dama_de_sangue").ficha)
	assert_eq(Combate.new(rs, Dados.new(1)).motivo_item_combate(a, "amarras_morte", dama), "", "a Dama de Sangue é vulnerável a Morte")


# --- Condição cego (p.320) ------------------------------------------------------------

func test_cego_fica_desprevenido_e_perde_dados():
	var a := _agente()
	var antes := a.dados_da_pericia("acrobacia")
	a.aplicar_condicao(Ser.CEGO, 2)
	assert_true(a.tem(Ser.DESPREVENIDO))
	assert_true(a.tem(Ser.LENTO))
	assert_eq(a.dados_da_pericia("acrobacia"), antes - 2)
	a.encerrar_cena()
	assert_false(a.tem(Ser.CEGO))


func test_granada_de_fumaca_cega_sem_teste():
	var a := _agente()
	a.equipamento.append("granada_de_fumaca")
	var alvo := _alvo()
	var c := _combate_em_grade(a, [alvo], [Vector2i(0, 2), Vector2i(6, 2)])
	assert_true(c.usar_granada(a, "granada_de_fumaca", Vector2i(6, 2)).ok)
	assert_true(alvo.tem(Ser.CEGO))
