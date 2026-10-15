extends GutTest
## Poderes paranormais (p.114-116) e itens amaldiçoados (p.154-157).

var rs: RulesetOp2022

const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(nex: int = 5, classe: String = "combatente") -> Agente:
	return Agente.criar(rs, "Agente", classe, ATTRS, {"luta": "treinado", "fortitude": "treinado", "reflexos": "treinado", "investigacao": "treinado"}, nex)


func _com(a: Agente, poder_id: String, escolha: String = "") -> Agente:
	a.poderes_paranormais.append({"id": poder_id, "escolha": escolha})
	a.recalcular_maximos(true)
	return a


func _alvo(pv: int = 60) -> Ameaca:
	return Ameaca.criar(rs, "Alvo", {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1}})


# --- Poderes paranormais -------------------------------------------------------------

func test_resistir_a_elemento_e_afinidade():
	var a := _com(_agente(), "resistir_a_elemento", "sangue")
	assert_eq(a.resistencia("sangue"), 10)
	assert_eq(a.contagem_elemento("sangue"), 1)
	a.afinidade = "sangue"
	_com(a, "resistir_a_elemento", "sangue")
	assert_eq(a.resistencia("sangue"), 20, "a segunda escolha com afinidade dobra")


func test_pre_requisito_de_elemento():
	var a := _agente()
	assert_false(Progressao.validar_poder_paranormal(a, "precognicao", "").is_empty(), "exige Conhecimento 1")
	_com(a, "sensitivo")
	assert_eq(Progressao.validar_poder_paranormal(a, "precognicao", ""), [] as Array[String])
	var defesa := a.defesa()
	_com(a, "precognicao")
	assert_eq(a.defesa(), defesa + 2)
	assert_eq(a.bonus_pericia("diplomacia"), 5, "Sensitivo")
	assert_eq(a.bonus_pericia("fortitude"), 5 + 2, "Precognição soma nas resistências")


func test_aprender_ritual():
	var a := _agente()
	assert_false(Progressao.adicionar_poder_paranormal(a, "aprender_ritual", "invadir_mente").is_empty(), "2º círculo só em NEX 45%")
	assert_eq(Progressao.adicionar_poder_paranormal(a, "aprender_ritual", "eletrocussao"), [] as Array[String])
	assert_true(a.conhece_ritual("eletrocussao"))
	assert_eq(a.contagem_elemento("energia"), 1, "conta como poder do elemento do ritual")


func test_transcender_custa_a_sanidade_do_nex():
	var a := _agente(15)
	var san := a.san_maximo
	a.poderes.append("transcender")
	a.recalcular_maximos()
	assert_eq(a.san_maximo, san - 3, "combatente ganha 3 SAN por NEX")


func test_potencial_aprimorado_e_sangue_de_ferro():
	var a := _agente(10)
	var pe := a.pe_maximo
	var pv := a.pv_maximo
	_com(a, "potencial_aprimorado")
	_com(a, "sangue_de_ferro")
	assert_eq(a.pe_maximo, pe + 2)
	assert_eq(a.pv_maximo, pv + 4)


func test_escapar_da_morte():
	var a := _com(_agente(), "escapar_da_morte")
	a.sofrer_dano(1000)
	assert_eq(a.pv, 1)
	assert_false(a.tem(Ser.MORRENDO))
	a.sofrer_dano(1000)
	assert_eq(a.pv, 0, "uma vez por cena")


func test_escapar_da_morte_nao_vale_contra_dano_massivo():
	var a := _com(_agente(), "escapar_da_morte")
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([1, 1])   # Fortitude falha contra o dano massivo
	c.aplicar_dano(a, a.pv_maximo / 2 + 1)
	assert_eq(a.pv, 0)


func test_sangue_fervente():
	var a := _com(_agente(), "sangue_fervente")
	assert_eq(a.atributo("for"), 2)
	a.sofrer_dano(a.pv_maximo - 2)
	assert_eq(a.atributo("for"), 3, "machucado: +1 na maior entre Força e Agilidade")


func test_sangue_vivo():
	var a := _com(_agente(), "sangue_vivo")
	a.sofrer_dano(a.pv_maximo - 3)
	var c := Combate.new(rs, Dados.new(1))
	c._cura_acelerada(a)
	assert_eq(a.pv, 5)


func test_encarar_a_morte():
	var a := _com(_agente(), "encarar_a_morte")
	assert_eq(a.limite_pe(), 1)
	a.em_acao = true
	assert_eq(a.limite_pe(), 2)
	a.encerrar_cena()
	assert_eq(a.limite_pe(), 1)


func test_golpe_de_sorte():
	var a := _com(_agente(), "golpe_de_sorte")
	assert_eq(a.modificar_ataque(rs.arma("faca"), null).margem, 1)


func test_campo_protetor():
	var a := _com(_agente(), "campo_protetor")
	var c := Combate.new(rs, Dados.new(1))
	var inimigo := Ameaca.criar(rs, "Inimigo", {"pv": 10, "pericias": {"luta": {"dados": 1, "bonus": 0}}})
	assert_true(c.declarar_reacao(a, "esquiva"))
	c.dados.forcar([15])
	var r := c.atacar(inimigo, a, rs.arma("faca"))
	assert_eq(r.teste.dt, a.defesa() + a.bonus_pericia("reflexos") + 5)
	assert_eq(a.pe, a.pe_maximo - 1)


func test_anatomia_insana_com_afinidade_ignora_critico():
	var a := _com(_agente(), "anatomia_insana")
	a.afinidade = "sangue"
	_com(a, "anatomia_insana")   # 50% + 50% = imune
	var c := Combate.new(rs, Dados.new(1))
	var inimigo := Ameaca.criar(rs, "Inimigo", {"pv": 10, "pericias": {"luta": {"dados": 1, "bonus": 20}}})
	c.dados.forcar([20, 50, 2])   # 20 natural; d100 = 50 (<= 100): crítico ignorado; dano 1d4 = 2
	var r := c.atacar(inimigo, a, rs.arma("faca"))
	assert_false(r.critico)
	assert_true(r.critico_ignorado)


func test_percepcao_paranormal_rerrola():
	var a := _com(_agente(5, "especialista"), "percepcao_paranormal")
	var d := Dados.new(1)
	d.forcar([5, 7, 18])   # 2 dados (INT 2): 5 e 7; o pior (5) é rolado de novo: 18
	var r := a.testar(d, "investigacao", 20, 0, {"contexto": "procurar_pistas"})
	assert_eq(r.escolhido, 18)
	assert_true(r.sucesso)


func test_causalidade_fortuita():
	var a := _com(_agente(5, "especialista"), "causalidade_fortuita")
	var m := Missao.nova(3)
	var cena := CenaInvestigacao.nova(rs, Dados.new(1), m.caso, "casa_abandonada", [a], "medio")
	cena.dados.forcar([10, 1])   # 10 + 5 = 15 vs DT 15 − 5
	assert_true(cena.procurar("computador", "investigacao").sucesso)


func test_manipular_entropia_e_surto_temporal():
	var a := _com(_com(_com(_agente(), "golpe_de_sorte"), "afortunado"), "manipular_entropia")
	var c := Combate.new(rs, Dados.new(1))
	var r := Teste.rolar(Dados.new(2), 1, 0, 15)
	c.dados.forcar([3])
	assert_true(c.manipular_entropia(a, _alvo(), r))
	assert_eq(r.escolhido, 3)
	var b := _com(_com(_com(_agente(), "potencial_aprimorado"), "encarar_a_morte"), "surto_temporal")
	c.adicionar(b)
	c.adicionar(_alvo())
	c.dados.forcar([1, 20, 20, 10, 1])
	c.iniciar()
	c.proximo_turno()
	assert_true(c.surto_temporal(b))
	assert_eq(c.acoes_restantes(b).padrao, 2)
	assert_false(c.surto_temporal(b), "uma vez por cena")


func test_arma_de_sangue():
	var a := _com(_agente(), "arma_de_sangue")
	var alvo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(a)
	c.adicionar(alvo)
	c.dados.forcar([1, 20, 20, 10, 1])
	c.iniciar()
	c.proximo_turno()
	assert_true(c.criar_arma_de_sangue(a))
	var arma := c.arma_de_sangue(a)
	assert_eq(arma.dano, "1d6")
	c.dados.forcar([15, 15, 3])
	c.agredir(a, alvo, arma)
	a.iniciar_turno()   # zera o limite do turno para o PE extra
	c.dados.forcar([15, 15, 4])
	assert_true(c.ataque_arma_de_sangue(a, alvo).acertou)


func test_cultista_arrependido_precisa_de_poder_paranormal():
	var f := {"nome": "Ex", "classe": "ocultista", "origem": "cultista_arrependido", "nex": 5,
		"atributos": {"agi": 1, "for": 1, "int": 2, "pre": 3, "vig": 2},
		"pericias_livres": ["investigacao", "intuicao", "percepcao", "diplomacia", "atualidades", "tecnologia"],
		"rituais": ["eletrocussao", "cicatrizacao", "decadencia"]}
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())
	f.poderes_paranormais = [{"id": "resistir_a_elemento", "escolha": "morte"}]
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_eq(r.agente.resistencia("morte"), 10)


func test_transcender_na_progressao():
	var a := _agente(15)
	a.trilha_id = "guerreiro"
	assert_false(Progressao.aplicar(a, "poder", "transcender").is_empty(), "falta o poder paranormal")
	assert_eq(Progressao.aplicar(a, "poder", "transcender", ["resistir_a_elemento", "energia"]), [] as Array[String])
	assert_eq(a.resistencia("energia"), 10)
	a.nex = 50
	assert_true(Progressao.pendencias(a).any(func(p): return p.tipo == "afinidade"))
	Progressao.aplicar(a, "afinidade", "energia")
	assert_eq(a.afinidade, "energia")


func test_paranormais_salvam():
	var a := _com(_agente(), "resistir_a_elemento", "sangue")
	a.afinidade = "sangue"
	var b := Agente.de_dicionario(rs, a.para_dicionario())
	assert_eq(b.poderes_paranormais, a.poderes_paranormais)
	assert_eq(b.resistencia("sangue"), 10)


# --- Itens amaldiçoados -------------------------------------------------------------

func test_item_amaldicoado_soma_categoria():
	var e := rs.equipamento("machado_lancinante")
	assert_eq(e.tipo, "arma")
	assert_eq(e.categoria, 3, "machado (I) + 1ª maldição (II)")
	assert_eq(e.maldicoes.size(), 1)
	assert_eq(rs.equipamento("amuleto_do_carisma").categoria, 3)


func test_so_a_partir_de_agente_especial():
	var a := _agente()
	assert_false(a.validar_equipamento(["machado_lancinante"]).is_empty())
	a.pp = 50
	assert_true(a.validar_equipamento(["machado_lancinante"]).is_empty())


func test_lancinante_dano_extra():
	var a := _agente()
	a.equipamento.append("machado_lancinante")
	a.arma_id = "machado_lancinante"
	var c := Combate.new(rs, Dados.new(1))
	var alvo := _alvo()
	c.dados.forcar([15, 15, 4, 5])   # acerto; 1d8 = 4; lancinante 1d8 = 5
	var r := c.atacar(a, alvo, a.arma())
	assert_eq(r.dano, 4 + 5 + 2)


func test_predadora_dobra_a_margem():
	var a := _agente()
	a.equipamento.append("pistola_predadora")
	a.arma_id = "pistola_predadora"
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([15, 1, 3, 3])   # pistola margem 18 -> 15: crítico com 15
	var r := c.atacar(a, _alvo(), a.arma())
	assert_true(r.critico)


func test_vibrante_concede_ataque_extra():
	var a := _agente()
	a.equipamento.append("espada_vibrante")
	assert_false(a.tem_habilidade("ataque_extra"), "só com a arma empunhada")
	a.arma_id = "espada_vibrante"
	assert_true(a.tem_habilidade("ataque_extra"))


func test_protecao_cinetica_e_acessorios():
	var a := _agente()
	var defesa := a.defesa()
	a.equipamento.append("protecao_leve_cinetica")
	assert_eq(a.defesa(), defesa + 5 + 2)
	assert_eq(a.resistencia("corte"), 2)
	a.equipamento.append("amuleto_do_carisma")
	assert_eq(a.atributo("pre"), 3)
	a.equipamento.append("anel_da_vitalidade")
	var pv := a.pv_maximo
	a.recalcular_maximos()
	assert_eq(a.pv_maximo, pv + 15)


func test_bonus_iguais_de_itens_nao_acumulam():
	var a := _agente()
	a.equipamento.append("amuleto_do_carisma")
	a.equipamento.append("amuleto_do_carisma")
	assert_eq(a.atributo("pre"), 3)


func test_preco_da_maldicao():
	var a := _agente()
	a.equipamento.append("anel_da_pujanca")   # Sangue: falhar em testes de Força ou Vigor custa 2 SAN
	var san := a.san
	var d := Dados.new(1)
	d.forcar([1, 1, 1])
	var r := a.testar(d, "atletismo", 30)
	assert_false(r.sucesso)
	assert_eq(a.san, san - 2)
	d.forcar([1, 1])
	a.testar(d, "intuicao", 30)
	assert_eq(a.san, san - 2, "Presença não é atributo de Sangue")
