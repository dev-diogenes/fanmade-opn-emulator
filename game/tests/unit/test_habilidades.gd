extends GutTest
## Poderes de origem, habilidades de classe e efeitos passivos.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(classe: String, origem: String, atributos: Dictionary, pericias: Dictionary = {}, nex: int = 5) -> Agente:
	var a := Agente.criar(rs, "Teste", classe, atributos, pericias, nex)
	a.origem_id = origem
	a.recalcular_maximos(true)
	return a


const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}


# --- Limite de PE e custo mínimo --------------------------------------------

func test_habilidade_no_custo_minimo_passa_do_limite_no_nex_5():
	var a := _agente("especialista", "academico", ATTRS, {"ciencias": "treinado"})
	assert_eq(a.limite_pe(), 1)
	var d := Dados.new(1)
	d.forcar([8, 3])
	var r := a.testar(d, "ciencias", 20, 0, {"habilidades": ["saber_e_poder"]})
	assert_not_null(r)
	assert_eq(r.total, 8 + 5 + 5)
	assert_eq(a.pe, a.pe_maximo - 2)


func test_habilidade_mais_foco_respeita_o_limite():
	var a := _agente("especialista", "academico", ATTRS, {"ciencias": "treinado"})
	assert_null(a.testar(Dados.new(1), "ciencias", 20, 1, {"habilidades": ["saber_e_poder"]}))
	assert_eq(a.pe, a.pe_maximo)


func test_so_uma_habilidade_por_turno_acima_do_limite():
	var a := _agente("especialista", "academico", ATTRS, {"ciencias": "treinado"})
	var d := Dados.new(1)
	assert_not_null(a.testar(d, "ciencias", 10, 0, {"habilidades": ["saber_e_poder"]}))
	assert_null(a.testar(d, "ciencias", 10, 0, {"habilidades": ["saber_e_poder"]}))
	a.iniciar_turno()
	assert_not_null(a.testar(d, "ciencias", 10, 0, {"habilidades": ["saber_e_poder"]}))


# --- Poderes de origem ------------------------------------------------------

func test_110_por_cento_nao_vale_para_ataques():
	var a := _agente("combatente", "atleta", ATTRS, {"atletismo": "treinado", "luta": "treinado"})
	assert_not_null(a.testar(Dados.new(1), "atletismo", 10, 0, {"habilidades": ["cento_e_dez_por_cento"]}))
	a.iniciar_turno()
	assert_null(a.testar(Dados.new(1), "luta", 10, 0, {"habilidades": ["cento_e_dez_por_cento"]}))


func test_faro_para_pistas_uma_vez_por_cena_e_so_ao_procurar_pistas():
	var a := _agente("especialista", "investigador", ATTRS, {"investigacao": "treinado"})
	var d := Dados.new(1)
	assert_null(a.testar(d, "investigacao", 15, 0, {"habilidades": ["faro_para_pistas"]}), "sem contexto")
	var ctx := {"habilidades": ["faro_para_pistas"], "contexto": "procurar_pistas"}
	assert_not_null(a.testar(d, "investigacao", 15, 0, ctx))
	a.iniciar_turno()
	assert_null(a.testar(d, "investigacao", 15, 0, ctx), "já usou nesta cena")
	a.encerrar_cena()
	a.iniciar_turno()
	assert_not_null(a.testar(d, "investigacao", 15, 0, ctx))


func test_passivos_de_origem():
	assert_eq(_agente("combatente", "policial", ATTRS).defesa(), 10 + 2 + 2)
	var desgarrado := _agente("combatente", "desgarrado", ATTRS, {}, 10)
	assert_eq(desgarrado.pv_maximo, rs.pv_max("combatente", 10, ATTRS) + 2)
	var vitima := _agente("ocultista", "vitima", ATTRS, {}, 20)
	assert_eq(vitima.san_maximo, rs.san_max("ocultista", 20, ATTRS) + 4)
	var cultista := _agente("ocultista", "cultista_arrependido", ATTRS)
	assert_eq(cultista.san_maximo, 20 - 10)
	var teorico := _agente("especialista", "teorico_da_conspiracao", ATTRS)
	assert_eq(teorico.resistencia("mental"), 2)


func test_universitario_dedicacao():
	var a := _agente("especialista", "universitario", ATTRS)
	assert_eq(a.pe_maximo, rs.pe_max("especialista", 5, ATTRS) + 1)
	assert_eq(a.limite_pe(), 2)
	var b := _agente("especialista", "universitario", ATTRS, {}, 15)
	assert_eq(b.pe_maximo, rs.pe_max("especialista", 15, ATTRS) + 2)


func test_eu_ja_sabia_reduz_dano_mental():
	var a := _agente("especialista", "teorico_da_conspiracao", ATTRS)
	a.sofrer_dano_mental(5)
	assert_eq(a.san, a.san_maximo - 3)


# --- Habilidades de classe --------------------------------------------------

func test_ecletico_testa_como_treinado():
	var a := _agente("especialista", "", ATTRS)
	assert_null(a.testar(Dados.new(1), "pilotagem", 10), "pilotagem exige treino")
	var d := Dados.new(1)
	d.forcar([6, 2])
	var r := a.testar(d, "pilotagem", 10, 0, {"ecletico": true})
	assert_not_null(r)
	assert_eq(r.total, 11)
	assert_eq(a.pe, a.pe_maximo - 2)


func test_ecletico_e_so_de_especialista():
	var a := _agente("combatente", "", ATTRS)
	assert_null(a.testar(Dados.new(1), "pilotagem", 10, 0, {"ecletico": true}))


func test_engenhosidade_veterano_em_nex_40():
	var a := _agente("especialista", "", ATTRS, {}, 40)
	var d := Dados.new(1)
	d.forcar([5, 5])
	var r := a.testar(d, "tatica", 10, 0, {"ecletico": true, "engenhosidade": "veterano"})
	assert_eq(r.total, 15)
	assert_eq(a.pe, a.pe_maximo - 4)
	assert_null(a.testar(Dados.new(1), "tatica", 10, 0, {"ecletico": true, "engenhosidade": "expert"}), "expert só em NEX 75%")


func test_perito_soma_o_dado_do_nivel():
	var a := _agente("especialista", "", ATTRS, {"ciencias": "treinado"})
	a.perito.append("ciencias")
	var d := Dados.new(1)
	d.forcar([7, 4, 6])   # 2 slots de INT, depois 1d6 do Perito
	var r := a.testar(d, "ciencias", 18, 0, {"perito": true})
	assert_eq(r.dados_bonus, [6])
	assert_eq(r.total, 7 + 5 + 6)
	assert_true(r.sucesso)
	assert_null(a.testar(Dados.new(1), "intuicao", 10, 0, {"perito": true}), "perícia fora do Perito")


func test_ataque_especial():
	var a := _agente("combatente", "", ATTRS, {"luta": "treinado"})
	var arma := rs.arma("machado")
	assert_eq(a.plano_ataque_especial(5, 0, arma).custo, 2)
	assert_true(a.plano_ataque_especial(10, 0, arma).is_empty(), "+10 só em NEX 25%")
	assert_true(a.plano_ataque_especial(3, 0, arma).is_empty(), "passos de 5")
	var veterano := _agente("combatente", "", ATTRS, {"luta": "treinado"}, 25)
	assert_eq(veterano.plano_ataque_especial(5, 5, arma).custo, 3)


func test_ataque_especial_no_combate():
	var a := _agente("combatente", "", ATTRS, {"luta": "treinado"})
	var alvo := Ameaca.criar(rs, "Alvo", {"pv": 50, "defesa": 30})
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([19, 3, 4])  # 19 +5 Luta +5 AE = 29: erra contra Def 30 (sem crítico: margem 20)
	var r := c.atacar(a, alvo, rs.arma("machado"), 0, {"ataque_especial": {"ataque": 5}})
	assert_eq(r.pe_gasto, 2)
	assert_eq(r.teste.total, 29)


# --- Poderes e trilhas em combate ------------------------------------------

func test_golpe_pesado_e_mao_pesada():
	var a := _agente("combatente", "lutador", ATTRS, {"luta": "treinado"}, 15)
	a.poderes.append("golpe_pesado")
	var alvo := Ameaca.criar(rs, "Alvo", {"pv": 50, "defesa": 10})
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([15, 2, 3, 5])  # acerto; 2d8 (Golpe Pesado) = 8
	var r := c.atacar(a, alvo, rs.arma("machado"))
	assert_eq(r.dano, 8 + 2 + 2)  # dados + FOR + Mão Pesada


func test_tecnica_letal_amplia_margem():
	var a := _agente("combatente", "", ATTRS, {"luta": "treinado"}, 10)
	a.trilha_id = "guerreiro"
	var alvo := Ameaca.criar(rs, "Alvo", {"pv": 50, "defesa": 10})
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([18, 2, 1, 1, 1])  # machado: margem 20 -> 18, x3
	var r := c.atacar(a, alvo, rs.arma("machado"))
	assert_true(r.critico)
	assert_eq(r.dano, 3 + 2)


func test_artista_marcial():
	var a := _agente("combatente", "", ATTRS, {"luta": "treinado"}, 15)
	a.poderes.append("artista_marcial")
	var arma := a.arma_efetiva(rs.arma("desarmado"))
	assert_eq(arma.dano, "1d6")
	assert_false(arma.nao_letal)


func test_tiro_certeiro_soma_agilidade_em_disparo():
	var a := _agente("combatente", "", ATTRS, {"pontaria": "treinado"}, 15)
	a.poderes.append("tiro_certeiro")
	assert_eq(a.modificar_ataque(rs.arma("arco"), null).bonus_dano, 2)
	assert_eq(a.modificar_ataque(rs.arma("pistola"), null).bonus_dano, 0)
