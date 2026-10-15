extends GutTest
## Fase 4.8: últimas criaturas e os chefes lendários (Anjo, Aniquilação, Diabo, Deus da Morte).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func _agente(pericias: Dictionary = {}, nex: int = 50) -> Agente:
	var p := {"luta": "treinado", "fortitude": "treinado"}
	p.merge(pericias, true)
	return Agente.criar(rs, "Agente", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 2}, p, nex)


func _saco(pv: int = 1000) -> Ameaca:
	var s := Ameaca.criar(rs, "Saco", {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1}})
	s.lado = "agentes"
	return s


func _c() -> Combate:
	return Combate.new(rs, Dados.new(1))


func test_aniquilacao_resistencia_a_dano_e_enigma():
	var c := _c()
	var an := _ameaca("aniquilacao")
	var a := _agente({"ocultismo": "treinado", "religiao": "treinado", "diplomacia": "treinado"}, 99)
	assert_eq(c.aplicar_dano(an, 60, "corte"), 10, "resistência a dano 50")
	for i in 3:
		c.dados.forcar([20])
		c.decifrar_enigma(a, an)
	assert_false(an.enigma_pendente())
	assert_eq(c.aplicar_dano(an, 60, "corte"), 60)
	assert_false(an.tem_hab("tempestade_de_espinhos"))


func test_diabo_so_cede_a_morte():
	var c := _c()
	var d := _ameaca("o_diabo")
	assert_eq(c.aplicar_dano(d, 100, "corte"), 0, "imune a dano")
	assert_eq(c.aplicar_dano(d, 120, "morte"), 0)
	assert_true(d.enigma_pendente())
	c.aplicar_dano(d, 100, "morte")
	assert_false(d.enigma_pendente(), "200 de Morte acumulados")
	assert_eq(c.aplicar_dano(d, 50, "corte"), 50)
	assert_eq(c.aplicar_dano(d, 50, "sangue"), 0, "continua imune a Sangue")


func test_diabo_explode_em_sangue_e_invoca():
	var c := _c()
	var d := _ameaca("o_diabo")
	var s := _saco(5000)
	c.adicionar(d)
	c.adicionar(s)
	c.dados.forcar([15, 15, 15, 15, 15, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	var r := c.atacar(d, s, d.ataques[0])
	assert_eq(r.dano, 52 + 10, "2d10+50 e mais 10d6 de Explodir em Sangue")
	assert_true(c.usar_habilidade(d, "senhor_do_sangue").ok)
	assert_eq(c.participantes.size(), 4)
	assert_false(c.usar_habilidade(d, "senhor_do_sangue").ok, "uma vez por cena")


func test_desejos_de_sangue():
	var c := _c()
	var d := _ameaca("o_diabo")
	var a := _agente()
	var b := _agente()
	for x in [d, a, b]:
		c.adicionar(x)
	c.dados.forcar([1, 20])
	c.usar_habilidade(d, "desejos_de_sangue")
	assert_eq(a.lado, "ameacas", "em fúria, luta contra os aliados")
	assert_eq(b.lado, "agentes")
	c._fim_de_turno(a)
	assert_eq(a.lado, "agentes", "só por um turno")


func test_deus_da_morte():
	var c := _c()
	var dm := _ameaca("deus_da_morte")
	c.adicionar(dm)
	c._ao_iniciar_turno(dm)
	assert_eq(c.acoes_restantes(dm).padrao, 2, "Senhor do Tempo")
	dm.aplicar_condicao(Ser.ENJOADO)
	dm.aplicar_condicao(Ser.FRACO)
	dm.aplicar_condicao(Ser.SANGRANDO)
	c._inicio_de_turno_ameacas(dm)
	var restantes := [Ser.ENJOADO, Ser.FRACO, Ser.SANGRANDO].filter(func(cond): return dm.tem(cond))
	assert_eq(restantes.size(), 1, "encerra até duas condições")
	var a := _agente()
	a.aplicar_condicao(Ser.AGARRADO)
	a.mods_cena["agarrado_por"] = dm
	var san := a.san
	c.dados.forcar([10, 10, 10])
	assert_true(c.usar_habilidade(dm, "espiral_descendente", a).ok)
	assert_eq(a.san, maxi(0, san - 30))
	assert_true(a.tem(Ser.FRACO), "envelheceu 30 anos")
	c.aplicar_dano(dm, 250, "sangue")
	assert_false(dm.enigma_pendente())
	assert_false(dm.tem_hab("imortalidade"), "perde o Ciclo Infinito")


func test_lembrado_aura_e_silhueta():
	var c := _c()
	var l := _ameaca("lembrado")
	var a := _agente()
	c.adicionar(l)
	c.adicionar(a)
	var luta := a.dados_da_pericia("luta")
	c._inicio_de_turno_ameacas(a)
	assert_eq(a.dados_da_pericia("luta"), luta - 2, "Aura Manifestada")
	var c2 := _c()
	var si := _ameaca("silhueta")
	var b := _agente()
	c2.adicionar(si)
	c2.adicionar(b)
	assert_eq(c2.aplicar_dano(si, 50, "corte"), 20, "resistência a dano 30")
	var pv := b.pv
	c2.dados.forcar([15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	c2.atacar(b, si, rs.arma("desarmado"))
	assert_eq(b.pv, pv - 20, "tocar a silhueta: 20d12 de Conhecimento")


func test_marionete_ironia_do_destino():
	var c := _c()
	var m := _ameaca("marionete")
	var s := _saco()
	c.adicionar(m)
	c.adicionar(s)
	var forca := [15, 15, 15, 15, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
	c.dados.forcar(forca + forca)
	assert_true(c.usar_habilidade(m, "ironia_do_destino", s).ok)
	assert_true(s.tem(Ser.AGARRADO))
	var pv := s.pv
	assert_eq(c.aplicar_dano(m, 40, "balistico"), 20, "divide a dor com quem agarra")
	assert_eq(s.pv, pv - 20)


func test_reflexos_guiados():
	var c := _c()
	c.grade = Grade.new(14, 9)
	var m := _ameaca("marionete")
	var a := _agente()
	c.adicionar(m)
	c.adicionar(a)
	c.grade.colocar(m, Vector2i(5, 4))
	c.grade.colocar(a, Vector2i(1, 4))
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	var pv := a.pv
	c.dados.forcar([15, 15, 15, 15, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	assert_true(c.mover(a, Vector2i(4, 4)))
	assert_eq(a.pv, pv - 20, "chegar ao lado da marionete custa um golpe de foice")


func test_envelhecimento():
	var c := _c()
	var a := _agente()
	c._envelhecer(a, 25)
	assert_true(a.tem(Ser.FRACO))
	c._envelhecer(a, 20)
	assert_true(a.tem(Ser.DEBILITADO))
	c._envelhecer(a, 20)
	assert_true(a.tem(Ser.MORTO))
	var b := _agente()
	b.afinidade = "morte"
	c._envelhecer(b, 80)
	assert_false(b.tem(Ser.MORTO), "afinidade com a Morte protege")


func test_julgamento_do_anjo():
	var c := _c()
	var anjo := _ameaca("anjo")
	var a := _agente({}, 99)
	var pv := a.pv
	var san := a.san
	c.dados.forcar([15, 15, 15, 15, 15, 1, 1, 1, 1, 20, 20, 20, 20, 20, 1])
	c.atacar(anjo, a, anjo.ataques[0])
	assert_eq(a.pv, pv - 44)
	assert_eq(a.san, san - 22, "metade do dano de Conhecimento na mente")
	assert_true(a.tem(Ser.AGARRADO))
	assert_true(a.tem(Ser.FASCINADO))


func test_anarquico_luz_prismatica():
	var c := _c()
	var an := _ameaca("anarquico")
	var a := _agente()
	c.adicionar(an)
	c.adicionar(a)
	var pv := a.pv
	c.dados.forcar([3, 4, 4, 1, 1])
	assert_eq(c.comportamento_anarquico(an), 3)
	assert_eq(a.pv, pv - 8)
	assert_true(a.tem(Ser.ATORDOADO))


func test_estrangeiro_e_covis_lendarios():
	var c := _c()
	var e := _ameaca("estrangeiro")
	var a := _agente({"investigacao": "treinado", "ciencias": "treinado", "intuicao": "treinado"}, 99)
	for i in 3:
		c.dados.forcar([20])
		c.decifrar_enigma(a, e)
	assert_false(e.enigma_pendente())
	assert_eq(c.aplicar_dano(e, 30, "corte"), 30)
	assert_eq(c.aplicar_dano(e, 30, "conhecimento"), 0, "segue imune a Conhecimento")
	var grupo: Array = []
	for i in 4:
		grupo.append(_agente({}, 99))
	assert_eq(Missao.covil_para(grupo).id, "o_pacto", "NEX somado 396: o Diabo")
