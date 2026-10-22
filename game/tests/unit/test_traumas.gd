extends GutTest
## Traumas que ficam (docs/70): quem enlouqueceu na missão pode sair com fobia do elemento do
## caso; a fobia deixa abalado diante da criatura desse elemento; a Enfermaria trata, com o
## agente fora da próxima missão.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _encerrar_com_loucura(c: Carreira, a: Agente, dados_vontade: Array) -> Dictionary:
	var m := c.iniciar_missao(c.roster.slice(0, 3), 42)
	assert_not_null(m)
	a.efeitos_insanidade = [{"id": 6, "ate_o_fim": true}]
	m.encerrada = true
	m.vitoria = true
	m.dados.forcar(dados_vontade)
	return c.encerrar_missao()


func test_quem_enlouqueceu_e_falha_leva_fobia():
	var c := Carreira.nova()
	var a: Agente = c.roster[0]
	var r := _encerrar_com_loucura(c, a, [1, 1, 1, 1])
	assert_eq(a.traumas.size(), 1)
	var linha: Dictionary = r.agentes.filter(func(x): return x.nome == a.nome)[0]
	assert_string_contains(String(linha.get("trauma", "")), "Fobia")
	assert_true(a.efeitos_insanidade.is_empty(), "o efeito de insanidade some na Base; o trauma fica")


func test_vontade_alta_escapa_do_trauma():
	var c := Carreira.nova()
	var a: Agente = c.roster[0]
	_encerrar_com_loucura(c, a, [20, 20, 20, 20])
	assert_true(a.traumas.is_empty())


func test_sem_loucura_sem_trauma():
	var c := Carreira.nova()
	var a: Agente = c.roster[0]
	var m := c.iniciar_missao(c.roster.slice(0, 3), 42)
	m.encerrada = true
	m.vitoria = true
	c.encerrar_missao()
	assert_true(a.traumas.is_empty())


func test_fobia_deixa_abalado_diante_da_criatura_do_elemento():
	var a := Agente.criar(rs, "A", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {})
	a.traumas.append({"elemento": "sangue", "missao": 1})
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(a)
	c.adicionar(Ameaca.criar(rs, "Zumbi", rs.ameaca("zumbi_de_sangue").ficha))
	c.iniciar()
	assert_true(a.tem(Ser.ABALADO))
	var b := Agente.criar(rs, "B", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {})
	b.traumas.append({"elemento": "morte", "missao": 1})
	var c2 := Combate.new(rs, Dados.new(1))
	c2.adicionar(b)
	c2.adicionar(Ameaca.criar(rs, "Zumbi", rs.ameaca("zumbi_de_sangue").ficha))
	c2.iniciar()
	assert_false(b.tem(Ser.ABALADO), "outro elemento: nada")


func test_enfermaria_tira_da_missao_e_cura():
	var c := Carreira.nova()
	var a: Agente = c.roster[0]
	a.traumas.append({"elemento": "sangue", "missao": 1})
	assert_true(c.tratar(a))
	assert_true(a.em_tratamento)
	assert_false(c.validar_grupo([a]).is_empty(), "em tratamento não vai a campo")
	var outros := c.roster.filter(func(x): return x != a)
	var m := c.iniciar_missao(outros.slice(0, 2), 7)
	assert_not_null(m)
	m.encerrada = true
	m.vitoria = true
	var r := c.encerrar_missao()
	assert_false(a.em_tratamento)
	assert_true(a.traumas.is_empty(), "a fobia passou")
	assert_true(r.detalhes_pp.any(func(l): return String(l).contains("terminou o tratamento")))


func test_trauma_sobrevive_ao_save():
	var a := Agente.criar(rs, "A", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {})
	a.traumas.append({"elemento": "energia", "missao": 2})
	a.em_tratamento = true
	var b := Agente.de_dicionario(rs, a.para_dicionario())
	assert_true(b.tem_fobia("energia"))
	assert_true(b.em_tratamento)
