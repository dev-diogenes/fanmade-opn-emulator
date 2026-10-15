extends GutTest
## Poderes de combate implementados na Fase 1.6.

var rs: RulesetOp2022

const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}
const PERICIAS := {"luta": "treinado", "pontaria": "treinado", "fortitude": "treinado"}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(nex: int = 5, classe: String = "combatente") -> Agente:
	return Agente.criar(rs, "Agente", classe, ATTRS, PERICIAS, nex)


func _alvo(defesa: int = 10, pv: int = 100) -> Ameaca:
	return Ameaca.criar(rs, "Alvo", {"pv": pv, "defesa": defesa, "atributos": {"agi": 1},
		"pericias": {"vontade": {"dados": 1, "bonus": 0}, "luta": {"dados": 1, "bonus": 5}}})


## Combate já no turno do agente: iniciativa forçada a favor dele.
## Ordem das rolagens em iniciar(): teste único das ameaças (1 dado), depois, por participante,
## a Iniciativa do agente (2 dados) e o desempate.
func _combate(agente: Agente, outros: Array = []) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(agente)
	for o in outros:
		c.adicionar(o)
	var forcados: Array = []
	if outros.any(func(o): return not o is Agente):
		forcados.append(1)
	for s in c.participantes:
		if s is Agente:
			forcados.append_array([20, 20] if s == agente else [1, 1])
		forcados.append(10 if s == agente else 1)
	c.dados.forcar(forcados)
	c.iniciar()
	assert_eq(c.proximo_turno(), agente, "o agente age primeiro")
	return c


func test_dt_de_habilidade():
	var a := Agente.criar(rs, "A", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 3}, {}, 50)
	assert_eq(a.dt_habilidade("vig"), 23)  # exemplo do livro (p.88)


func test_desprevenido_perde_5_de_defesa():
	var alvo := _alvo(12)
	alvo.condicoes[Ser.DESPREVENIDO] = true
	assert_eq(alvo.defesa(), 7)
	alvo.condicoes[Ser.INCONSCIENTE] = true
	assert_eq(alvo.defesa(), 2, "indefeso: −10")


func test_combater_com_duas_armas():
	var a := _agente(15)
	a.poderes.append("combater_com_duas_armas")
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([15, 3, 12, 4])  # 1 slot cada (FOR 2 − 1), dano faca 3, dano machete 4
	var rs_ataques := c.agredir_com_duas_armas(a, alvo, rs.arma("faca"), rs.arma("machete"))
	assert_eq(rs_ataques.size(), 2)
	assert_eq(rs_ataques[0].teste.slots.size(), 1)
	assert_eq(rs_ataques[1].teste.slots.size(), 1)
	assert_eq(c.acoes_restantes(a).padrao, 0)


func test_duas_armas_exige_uma_leve():
	var a := _agente(15)
	a.poderes.append("combater_com_duas_armas")
	var c := _combate(a, [_alvo()])
	assert_eq(c.agredir_com_duas_armas(a, c.participantes[1], rs.arma("machado"), rs.arma("machete")).size(), 0)


func test_combate_defensivo_dura_ate_o_proximo_turno():
	var a := _agente(15)
	a.poderes.append("combate_defensivo")
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([5])  # 1 slot (2 − 1)
	var r := c.atacar(a, alvo, rs.arma("faca"), 0, {"combate_defensivo": true})
	assert_eq(r.teste.slots.size(), 1)
	assert_eq(a.defesa(), 12 + 5)
	c.dados.forcar([5])
	assert_eq(c.atacar(a, alvo, rs.arma("faca")).teste.slots.size(), 1, "a penalidade continua neste turno")


func test_ataque_extra_uma_vez_por_rodada():
	var a := _agente(40)
	a.trilha_id = "operacoes_especiais"
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	assert_null(c.ataque_extra(a, alvo, rs.arma("faca")).teste, "precisa ter atacado antes")
	c.dados.forcar([1, 1, 1, 1])
	c.agredir(a, alvo, rs.arma("faca"))
	var pe_antes := a.pe
	assert_not_null(c.ataque_extra(a, alvo, rs.arma("faca")).teste)
	assert_eq(a.pe, pe_antes - 2)
	assert_null(c.ataque_extra(a, alvo, rs.arma("faca")).teste, "uma vez por rodada")


func test_surto_de_adrenalina():
	var a := _agente(65)
	a.trilha_id = "operacoes_especiais"
	var c := _combate(a, [_alvo()])
	assert_true(c.surto_de_adrenalina(a, "padrao"))
	assert_eq(c.acoes_restantes(a).padrao, 2)
	assert_false(c.surto_de_adrenalina(a, "movimento"), "uma vez por rodada")


func test_segurar_o_gatilho_custa_cada_vez_mais():
	var a := _agente(60)
	a.poderes.append("segurar_o_gatilho")
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	var pistola := rs.arma("pistola")
	c.dados.forcar([15, 15, 3])  # acerto (2 slots), dano 3
	c.agredir(a, alvo, pistola)
	var pe_antes := a.pe
	c.dados.forcar([15, 15, 3])
	assert_true(c.segurar_o_gatilho(a, alvo, pistola).acertou)
	assert_eq(a.pe, pe_antes - 2)
	c.dados.forcar([15, 15, 3])
	c.segurar_o_gatilho(a, alvo, pistola)
	assert_eq(a.pe, pe_antes - 2 - 4)


func test_duro_de_matar_reduz_dano_nao_paranormal():
	var a := _agente(65)
	a.trilha_id = "tropa_de_choque"
	var c := Combate.new(rs, Dados.new(1))
	assert_true(c.declarar_reducao_dano(a))
	var pe_antes := a.pe
	assert_eq(c.aplicar_dano(a, 9, "corte"), 4)
	assert_eq(a.pe, pe_antes - 2)
	assert_true(c.declarar_reducao_dano(a))
	assert_eq(c.aplicar_dano(a, 9, "sangue"), 9, "paranormal só em NEX 85%")


func test_abracar_a_dor():
	var a := Agente.criar(rs, "O", "ocultista", ATTRS, {}, 40)
	a.trilha_id = "flagelador"
	var c := Combate.new(rs, Dados.new(1))
	assert_true(c.declarar_reducao_dano(a))
	assert_eq(c.aplicar_dano(a, 7, "impacto"), 3)


func test_inquebravel():
	var a := _agente(99)
	a.trilha_id = "tropa_de_choque"
	var def_inicial := a.defesa()
	a.sofrer_dano(a.pv_maximo / 2 + 1)
	assert_true(a.tem(Ser.MACHUCADO))
	assert_eq(a.defesa(), def_inicial + 5)
	assert_eq(a.resistencia("corte"), 5)
	a.sofrer_dano(1000)
	assert_true(a.tem(Ser.MORRENDO))
	assert_false(a.tem(Ser.INCONSCIENTE), "morrendo, mas ainda age")
	assert_false(a.esta_fora_de_combate())


func test_revidar_apos_bloquear():
	var a := _agente(40)
	a.trilha_id = "guerreiro"
	var inimigo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	assert_true(c.declarar_reacao(a, "bloqueio", rs.arma("faca"), true))
	var pe_antes := a.pe
	c.dados.forcar([15, 2, 18, 18, 3])  # inimigo acerta (dano 1d4=2, +FOR 1); revida: acerta, faca 3
	var r := c.atacar(inimigo, a, inimigo.ataques[0] if not inimigo.ataques.is_empty() else rs.arma("faca"))
	assert_eq(r.reacao, "bloqueio")
	assert_not_null(r.contra_ataque)
	assert_true(r.contra_ataque.acertou)
	assert_eq(a.pe, pe_antes - 2)


func test_ataque_furtivo():
	var a := Agente.criar(rs, "I", "especialista", ATTRS, {"luta": "treinado"}, 10)
	a.trilha_id = "infiltrador"
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	assert_null(c.atacar(a, alvo, rs.arma("faca"), 0, {"ataque_furtivo": true}).teste, "alvo atento")
	alvo.condicoes[Ser.DESPREVENIDO] = true
	c.dados.forcar([15, 15, 2, 5])  # acerto, faca 2, furtivo 1d6 = 5
	var r := c.atacar(a, alvo, rs.arma("faca"), 0, {"ataque_furtivo": true})
	assert_eq(r.dano, 2 + 2 + 5)
	assert_eq(r.pe_gasto, 1)
	assert_null(c.atacar(a, alvo, rs.arma("faca"), 0, {"ataque_furtivo": true}).teste, "uma vez por rodada")


func test_atirar_para_matar_da_dano_maximo_no_critico():
	var a := Agente.criar(rs, "E", "especialista", ATTRS, {"pontaria": "treinado"}, 99)
	a.trilha_id = "atirador_de_elite"
	var c := _combate(a, [_alvo()])
	c.dados.forcar([19, 3])  # 19: crítico na pistola (margem 18)
	var r := c.atacar(a, c.participantes[1], rs.arma("pistola"))
	assert_true(r.critico)
	assert_eq(r.dano, 24)  # 1d12 x2 no máximo


func test_mira_de_elite_soma_intelecto_com_balas_longas():
	var a := Agente.criar(rs, "E", "especialista", ATTRS, {"pontaria": "treinado"}, 10)
	a.trilha_id = "atirador_de_elite"
	assert_eq(a.modificar_ataque(rs.arma("fuzil_de_caca"), null).bonus_dano, 2)
	assert_eq(a.modificar_ataque(rs.arma("pistola"), null).bonus_dano, 0)


func test_gladiador_paranormal_da_pe_temporario():
	var a := Agente.criar(rs, "L", "ocultista", ATTRS, {"luta": "treinado"}, 40)
	a.trilha_id = "lamina_paranormal"
	var c := _combate(a, [_alvo()])
	c.dados.forcar([15, 15, 2])
	c.atacar(a, c.participantes[1], rs.arma("faca"))
	assert_eq(a.pe_temporario, 2)
	var pe := a.pe
	assert_true(a.gastar_pe(1))
	assert_eq(a.pe_temporario, 1, "temporários saem primeiro")
	assert_eq(a.pe, pe)


func test_mirar_e_disparo_letal():
	var a := Agente.criar(rs, "E", "especialista", ATTRS, {"pontaria": "treinado"}, 40)
	a.trilha_id = "atirador_de_elite"
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	assert_true(c.mirar(a, alvo, true))
	assert_eq(c.acoes_restantes(a).movimento, 0)
	c.dados.forcar([16, 1, 2, 2])  # 16 é crítico com a margem da pistola ampliada (18 − 2)
	var r := c.atacar(a, alvo, rs.arma("pistola"), 0, {"alvo_em_corpo_a_corpo": true})
	assert_eq(r.teste.slots.size(), 2, "mirando, ignora a penalidade por alvo em corpo a corpo")
	assert_true(r.critico)


func test_alvo_em_corpo_a_corpo_tira_um_dado_de_tiros():
	var a := _agente()
	var c := _combate(a, [_alvo()])
	c.dados.forcar([5, 1])
	assert_eq(c.atacar(a, c.participantes[1], rs.arma("pistola"), 0, {"alvo_em_corpo_a_corpo": true}).teste.slots.size(), 1)


func test_tiro_de_cobertura():
	var a := _agente(15)
	a.poderes.append("tiro_de_cobertura")
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([18, 18, 2])  # Pontaria 18+5 vs Vontade 2
	assert_true(c.tiro_de_cobertura(a, alvo, rs.arma("pistola")))
	assert_true(alvo.tem(Ser.IMOVEL))
	assert_eq(alvo.modificar_ataque({}, a).bonus_ataque, -5)
	c.proximo_turno()   # turno do alvo
	c.proximo_turno()   # volta ao agente: o efeito acaba
	assert_false(alvo.tem(Ser.IMOVEL))
	assert_eq(alvo.modificar_ataque({}, a).bonus_ataque, 0)


func test_sentido_tatico():
	var a := _agente(15)
	a.poderes.append("sentido_tatico")
	var c := _combate(a, [_alvo()])
	var defesa := a.defesa()
	assert_true(c.sentido_tatico(a))
	assert_eq(a.defesa(), defesa + 2)
	assert_eq(a.bonus_testes_resistencia(), 2)
	assert_false(c.sentido_tatico(a), "não acumula")


func test_estrategista_e_oficial_comandante():
	var cmd := _agente(99)
	cmd.trilha_id = "comandante_de_campo"
	var aliado := _agente()
	var c := _combate(cmd, [aliado, _alvo()])   # uma ameaça para o combate não acabar
	assert_true(c.estrategista(cmd, [aliado]))
	assert_eq(c.proximo_turno(), aliado)
	assert_eq(c.acoes_restantes(aliado).movimento, 2)
	c.proximo_turno()   # ameaça
	assert_eq(c.proximo_turno(), cmd)
	assert_true(c.oficial_comandante(cmd))
	assert_eq(aliado.acoes_padrao_extras, 1)


func test_inspirar_confianca_rerrola():
	var cmd := _agente(10)
	cmd.trilha_id = "comandante_de_campo"
	var aliado := _agente()
	var d := Dados.new(1)
	d.forcar([2, 3])
	var r1 := aliado.testar(d, "luta", 15)
	assert_false(r1.sucesso)
	var c := Combate.new(rs, d)
	d.forcar([12, 1])
	var r2 := c.inspirar_confianca(cmd, r1)
	assert_true(r2.sucesso)
	assert_eq(r2.total, 17)


func test_brecha_na_guarda():
	var cmd := _agente(65)
	cmd.trilha_id = "comandante_de_campo"
	var aliado := _agente()
	var alvo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	assert_null(c.brecha_na_guarda(cmd, aliado, alvo, rs.arma("faca")).teste, "ninguém feriu o alvo ainda")
	c.aplicar_dano(alvo, 5, "", 0, aliado)
	c.dados.forcar([15, 15, 2])
	assert_true(c.brecha_na_guarda(cmd, aliado, alvo, rs.arma("faca")).acertou)
	assert_null(c.brecha_na_guarda(cmd, aliado, alvo, rs.arma("faca")).teste, "uma vez por rodada")


func test_cai_dentro():
	var tropa := _agente(40)
	tropa.trilha_id = "tropa_de_choque"
	var inimigo := _alvo()
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([5])   # Vontade 5 vs DT 10 + 8 + 2 = 20
	assert_true(c.cai_dentro(tropa, inimigo))
	tropa.iniciar_turno()
	c.dados.forcar([20])
	assert_false(c.cai_dentro(tropa, inimigo))
	tropa.iniciar_turno()
	assert_false(c.cai_dentro(tropa, inimigo), "imune pelo resto da cena")


func test_posicao_de_combate():
	var a := _agente()
	a.origem_id = "mercenario"
	var c := _combate(a, [_alvo()])
	assert_true(c.posicao_de_combate(a))
	assert_eq(c.acoes_restantes(a).movimento, 2)
	assert_false(c.posicao_de_combate(a))
