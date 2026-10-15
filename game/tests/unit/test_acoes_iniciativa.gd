extends GutTest
## Iniciativa única das ameaças, surpresa e economia de ações.

var rs: RulesetOp2022

const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(nome: String, dados_ini: int, bonus_ini: int) -> Ameaca:
	return Ameaca.criar(rs, nome, {"pv": 10, "defesa": 10, "atributos": {"agi": 1},
		"pericias": {"iniciativa": {"dados": dados_ini, "bonus": bonus_ini}}})


func test_ameacas_fazem_um_unico_teste_com_o_menor_bonus():
	var c := Combate.new(rs, Dados.new(1))
	var rapida := _ameaca("Rápida", 1, 5)
	var lenta := _ameaca("Lenta", 2, 0)
	var agente := Agente.criar(rs, "A", "combatente", ATTRS)
	c.adicionar(rapida)
	c.adicionar(lenta)
	c.adicionar(agente)
	# 1º: o teste único das ameaças usa a "Lenta" (2 dados, +0) -> 9.
	# Depois, por participante: desempate (rápida), desempate (lenta), Iniciativa do agente (2 dados) + desempate.
	c.dados.forcar([7, 9, 1, 2, 15, 3, 4])
	c.iniciar()
	assert_eq(c.iniciativas[rapida], 9)
	assert_eq(c.iniciativas[lenta], 9)
	assert_eq(c.iniciativas[agente], 15)
	assert_eq(c.ordem[0], agente)


func test_surpreendido_nao_age_na_primeira_rodada():
	var c := Combate.new(rs, Dados.new(1))
	var agente := Agente.criar(rs, "A", "combatente", ATTRS)
	var monstro := _ameaca("M", 1, 0)
	c.adicionar(agente)
	c.adicionar(monstro)
	watch_signals(c)
	c.dados.forcar([5, 1, 18, 3, 2])  # ameaça 5; desempate; agente 18 (2 dados: 18, 3); desempate
	c.iniciar([agente])
	assert_true(agente.tem(Ser.SURPREENDIDO))
	assert_eq(agente.defesa(), 12 - 5, "surpreendido fica desprevenido")
	assert_eq(c.proximo_turno(), monstro, "o agente perde a 1ª rodada")
	assert_signal_emitted_with_parameters(c, "turno_perdido", [agente, "surpreendido"])
	assert_eq(c.proximo_turno(), agente)
	assert_eq(c.rodada, 2)
	assert_false(agente.tem(Ser.SURPREENDIDO))


func test_distraido_comeca_surpreendido():
	var c := Combate.new(rs, Dados.new(1))
	var idoso := Agente.criar(rs, "Idoso", "combatente", ATTRS)
	idoso.desvantagens_idade.append("distraido")
	c.adicionar(idoso)
	c.adicionar(_ameaca("M", 1, 0))
	c.iniciar()
	assert_true(idoso.tem(Ser.SURPREENDIDO))


func _combate_um_turno(agente: Agente) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(agente)
	c.adicionar(_ameaca("M", 1, 0))
	c.dados.forcar([1, 1, 20, 20, 2])  # ameaça 1; desempate; agente 20; desempate
	c.iniciar()
	assert_eq(c.proximo_turno(), agente)
	return c


func test_acoes_padrao_movimento_e_completa():
	var agente := Agente.criar(rs, "A", "combatente", ATTRS)
	var c := _combate_um_turno(agente)
	assert_eq(c.acoes_restantes(agente), {"padrao": 1, "movimento": 1})
	assert_false(c.gastar_acao(agente, "voar"))
	assert_true(c.gastar_acao(agente, "movimento"))
	assert_true(c.gastar_acao(agente, "movimento"), "troca a padrão por movimento")
	assert_false(c.gastar_acao(agente, "movimento"))


func test_acao_completa_exige_padrao_e_movimento():
	var agente := Agente.criar(rs, "A", "combatente", ATTRS)
	var c := _combate_um_turno(agente)
	assert_true(c.gastar_acao(agente, "completa"))
	assert_eq(c.acoes_restantes(agente), {"padrao": 0, "movimento": 0})


func test_agredir_gasta_a_acao_padrao():
	var agente := Agente.criar(rs, "A", "combatente", ATTRS, {"luta": "treinado"})
	var c := _combate_um_turno(agente)
	var alvo := c.participantes[1]
	c.dados.forcar([2, 3])
	assert_not_null(c.agredir(agente, alvo, rs.arma("faca")).teste)
	assert_null(c.agredir(agente, alvo, rs.arma("faca")).teste, "sem ação padrão")


func test_iniciativa_aprimorada_e_sempre_alerta():
	var agente := Agente.criar(rs, "A", "combatente", ATTRS, {}, 99)
	agente.trilha_id = "operacoes_especiais"
	assert_eq(agente.bonus_pericia("iniciativa"), 5)
	var c := _combate_um_turno(agente)
	assert_eq(c.acoes_restantes(agente), {"padrao": 2, "movimento": 2}, "1ª rodada")
	c.proximo_turno()
	assert_eq(c.proximo_turno(), agente)
	assert_eq(c.acoes_restantes(agente), {"padrao": 1, "movimento": 1})


func test_acoes_padrao_extras_entram_no_proximo_turno():
	var agente := Agente.criar(rs, "A", "combatente", ATTRS)
	var c := _combate_um_turno(agente)
	agente.acoes_padrao_extras = 1
	c.proximo_turno()
	assert_eq(c.proximo_turno(), agente)
	assert_eq(c.acoes_restantes(agente).padrao, 2)


func test_tosse_pode_fazer_perder_o_turno():
	var c := Combate.new(rs, Dados.new(1))
	var agente := Agente.criar(rs, "A", "combatente", ATTRS)
	agente.desvantagens_idade.append("tosse")
	var monstro := _ameaca("M", 1, 0)
	c.adicionar(agente)
	c.adicionar(monstro)
	c.dados.forcar([1, 1, 20, 20, 2, 1])  # ...; tosse do agente: 1 -> perde o turno
	c.iniciar()
	watch_signals(c)
	assert_eq(c.proximo_turno(), monstro)
	assert_signal_emitted_with_parameters(c, "turno_perdido", [agente, "tosse"])
