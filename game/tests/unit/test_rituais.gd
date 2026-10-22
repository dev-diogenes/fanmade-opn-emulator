extends GutTest
## Rituais (cap. 5, p.127-153): custo, DT, Custo do Paranormal, efeitos e resistência.

var rs: RulesetOp2022

const ATTRS := {"agi": 1, "for": 1, "int": 2, "pre": 2, "vig": 2}
const COMPONENTES := ["componentes_energia", "componentes_morte", "componentes_sangue", "componentes_conhecimento"]


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ocultista(rituais: Array, nex: int = 5) -> Agente:
	var a := Agente.criar(rs, "Rita", "ocultista", ATTRS, {"ocultismo": "treinado", "vontade": "treinado"}, nex)
	for r in rituais:
		a.rituais.append(r)
	for c in COMPONENTES:
		a.equipamento.append(c)
	return a


func _alvo(elemento: String = "", pv: int = 40) -> Ameaca:
	return Ameaca.criar(rs, "Alvo", {"pv": pv, "defesa": 10, "elemento": elemento, "atributos": {"agi": 1, "vig": 1}})


func _combate() -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.membrana = Membrana.carregar_padrao()
	return c


# --- Regras básicas -----------------------------------------------------------------

func test_lista_de_rituais():
	assert_gt(rs.lista_rituais().size(), 80)
	assert_eq(rs.ritual("eletrocussao").circulo, 1.0)
	assert_eq(rs.custo_base_ritual(1), 1)
	assert_eq(rs.custo_base_ritual(4), 10)
	assert_eq(rs.circulo_maximo(5), 1)
	assert_eq(rs.circulo_maximo(25), 2)


func test_custo_e_dt():
	var a := _ocultista(["eletrocussao", "invadir_mente"], 25)
	assert_eq(a.custo_ritual("eletrocussao"), 1)
	assert_eq(a.custo_ritual("invadir_mente"), 3)
	assert_eq(a.dt_ritual("eletrocussao"), 10 + 5 + 2, "10 + limite de PE + Presença (p.131)")
	a.poderes.append("especialista_em_elemento")
	a.escolhas["especialista_em_elemento"] = "energia"
	assert_eq(a.dt_ritual("eletrocussao"), 19)
	assert_eq(a.dt_ritual("invadir_mente"), 17, "outro elemento")


func test_reducoes_de_custo_nunca_abaixo_de_1():
	var a := _ocultista(["cicatrizacao"])
	a.poderes.append("ritual_predileto")
	a.escolhas["ritual_predileto"] = "cicatrizacao"
	assert_eq(a.custo_ritual("cicatrizacao"), 1)
	assert_eq(a.custo_ritual("cicatrizacao", "discente"), 2, "1 + 2 − 1")


func test_motivos_para_nao_conjurar():
	var c := _combate()
	var a := _ocultista(["eletrocussao", "invadir_mente", "armadura_de_sangue"])
	var alvo := _alvo()
	assert_ne(c.pode_conjurar(a, "decadencia", alvo), "", "não conhece")
	assert_ne(c.pode_conjurar(a, "invadir_mente", alvo), "", "2º círculo em NEX 5%")
	assert_ne(c.pode_conjurar(a, "armadura_de_sangue", alvo), "", "ritual pessoal em outro alvo")
	a.equipamento.erase("componentes_energia")
	assert_ne(c.pode_conjurar(a, "eletrocussao", alvo), "", "sem componentes")
	a.equipamento.append("componentes_energia")
	assert_eq(c.pode_conjurar(a, "eletrocussao", alvo), "")


# --- Conjuração -----------------------------------------------------------------------

func test_eletrocussao_falha_na_resistencia():
	var c := _combate()
	var a := _ocultista(["eletrocussao"])
	var alvo := _alvo()
	c.dados.forcar([20, 20, 1, 3, 4, 5])   # Custo do Paranormal: passa; Fortitude do alvo: 1; dano 3d6 = 12
	var r := c.conjurar(a, "eletrocussao", alvo)
	assert_true(r.ok)
	assert_eq(r.dano, 12)
	assert_eq(alvo.pv, 28)
	assert_true(alvo.tem(Ser.VULNERAVEL))
	assert_eq(a.pe, a.pe_maximo - 1)
	assert_eq(c.membrana.valor, 100 - 2 - 1, "ritual de 1º círculo")


func test_resistencia_reduz_a_metade_e_evita_a_condicao():
	var c := _combate()
	var a := _ocultista(["eletrocussao"])
	var alvo := _alvo()
	c.dados.forcar([20, 20, 20, 6, 6, 6])
	var r := c.conjurar(a, "eletrocussao", alvo)
	assert_eq(r.dano, 9)
	assert_false(alvo.tem(Ser.VULNERAVEL))


func test_custo_do_paranormal():
	var c := _combate()
	var a := _ocultista(["eletrocussao"])
	var san := a.san_maximo
	c.dados.forcar([1, 1, 1, 1, 1, 1])   # Ocultismo 1 + 5 = 6 vs DT 21: falha por 15
	c.conjurar(a, "eletrocussao", _alvo())
	assert_eq(a.san, san - 2, "−1 SAN e −1 SAN máxima")
	assert_eq(a.san_maximo, san - 1)
	assert_eq(a.san_perdida, 1)


func test_criatura_do_elemento_oprimido_resiste_pior():
	var c := _combate()
	var a := _ocultista(["decadencia"])
	var alvo := _alvo("sangue")   # Morte é efetiva contra Sangue
	c.dados.forcar([20, 20, 15, 12, 18, 1, 1])
	var r := c.conjurar(a, "decadencia", alvo)
	assert_true(r.teste_resistencia.usa_pior, "1 dado de Vigor − 2 = reserva −1: 3 dados, o pior")
	assert_eq(r.teste_resistencia.slots.size(), 3)


func test_cicatrizacao_cura():
	var c := _combate()
	var a := _ocultista(["cicatrizacao"])
	var aliado := Agente.criar(rs, "Cléber", "combatente", ATTRS)
	aliado.sofrer_dano(15)
	c.dados.forcar([20, 20, 1, 2, 3])   # 3d8+3 = 9
	var r := c.conjurar(a, "cicatrizacao", aliado)
	assert_eq(r.cura, 9)
	assert_eq(aliado.pv, aliado.pv_maximo - 15 + 9)


func test_armadura_de_sangue_nao_soma_com_protecao():
	var c := _combate()
	var a := _ocultista(["armadura_de_sangue"])
	var base := a.defesa()
	c.dados.forcar([20, 20])
	c.conjurar(a, "armadura_de_sangue", a)
	assert_eq(a.defesa(), base + 5)
	a.equipamento.erase("componentes_conhecimento")
	a.equipamento.erase("componentes_energia")   # para não ficar sobrecarregada (FOR 1 = 5 espaços)
	a.equipamento.append("protecao_leve")
	assert_eq(a.defesa(), base + 5, "vale a maior entre proteção (+5) e ritual (+5)")
	a.encerrar_cena()
	assert_eq(a.defesa(), base + 5, "só a proteção, depois da cena")


func test_consumir_manancial_da_pv_temporarios():
	var c := _combate()
	var a := _ocultista(["consumir_manancial"])
	c.dados.forcar([20, 20, 4, 4, 4])
	c.conjurar(a, "consumir_manancial", a)
	assert_eq(a.pv_temporario, 12)
	var pv := a.pv
	a.sofrer_dano(5)
	assert_eq(a.pv, pv)
	assert_eq(a.pv_temporario, 7)


func test_espirais_da_perdicao_e_coincidencia_forcada():
	var c := _combate()
	var a := _ocultista(["espirais_da_perdicao", "coincidencia_forcada"])
	var alvo := _alvo()
	c.dados.forcar([20, 20])
	c.conjurar(a, "espirais_da_perdicao", alvo)
	assert_eq(alvo.modificar_ataque(rs.arma("faca"), a).dados_extras, -1)
	a.iniciar_turno()
	var aliado := Agente.criar(rs, "Bianca", "especialista", ATTRS)
	var antes := aliado.bonus_pericia("investigacao")
	c.dados.forcar([20, 20])
	c.conjurar(a, "coincidencia_forcada", aliado)
	assert_eq(aliado.bonus_pericia("investigacao"), antes + 2)


func test_definhar_deixa_fatigado():
	var c := _combate()
	var a := _ocultista(["definhar"])
	var alvo := _alvo()
	var defesa := alvo.defesa()
	c.dados.forcar([20, 20, 1])
	c.conjurar(a, "definhar", alvo)
	assert_true(alvo.tem(Ser.FATIGADO))
	assert_eq(alvo.defesa(), defesa - 2)
	assert_eq(alvo.dados_da_pericia("fortitude"), 0, "fraco: −1 dado em Vigor")


func test_perturbacao_faz_perder_o_turno():
	var c := _combate()
	var a := _ocultista(["perturbacao"])
	var alvo := _alvo()
	c.adicionar(a)
	c.adicionar(alvo)
	c.dados.forcar([1, 20, 10, 1])   # Iniciativa: ameaça 1; Rita 20 (1 dado); desempates
	c.iniciar()
	assert_eq(c.proximo_turno(), a)
	c.dados.forcar([20, 20, 1])   # custo ok; Vontade do alvo falha
	c.conjurar(a, "perturbacao", alvo)
	assert_true(alvo.tem(Ser.PASMO))
	watch_signals(c)
	assert_eq(c.proximo_turno(), a, "o alvo perde o turno e a vez volta para Rita")
	assert_signal_emitted_with_parameters(c, "turno_perdido", [alvo, "pasmo"])


func test_descarnar_causa_hemorragia():
	var c := _combate()
	var a := _ocultista(["descarnar"], 25)
	var alvo := _alvo("", 100)
	c.adicionar(a)
	c.adicionar(alvo)
	c.dados.forcar([20, 20, 1, 1, 1, 1, 1, 1, 1])   # custo ok, Fortitude falha, 6d8 = 6
	c.conjurar(a, "descarnar", alvo)
	assert_false(alvo.hemorragia.is_empty())
	c.dados.forcar([1, 2, 3])   # início do turno do alvo: Fortitude falha, 2d8 = 5
	c._processar_hemorragia(alvo)
	assert_eq(alvo.pv, 100 - 6 - 5)


func test_arma_atroz_sustentada():
	var c := _combate()
	var a := _ocultista(["arma_atroz"])
	var guerreiro := Agente.criar(rs, "Cléber", "combatente", ATTRS)
	c.adicionar(a)
	c.adicionar(guerreiro)
	c.adicionar(_alvo())   # com um só lado em campo, o combate acabaria na hora
	c.dados.forcar([20, 20])
	var r := c.conjurar(a, "arma_atroz", guerreiro)
	assert_true(r.ok)
	var mods := guerreiro.modificar_ataque(rs.arma("machado"), null)
	assert_eq(mods.bonus_ataque, 2)
	assert_eq(mods.margem, 1)
	a.iniciar_turno()
	c._manter_sustentados(a)
	assert_true(guerreiro.rituais_ativos.has("arma_atroz"), "pagou 1 PE para sustentar")
	a.pe = 0
	a.iniciar_turno()
	c._manter_sustentados(a)
	assert_false(guerreiro.rituais_ativos.has("arma_atroz"), "sem PE, o ritual acaba")


func test_concentracao_com_protecao():
	var c := _combate()
	var a := _ocultista(["eletrocussao"])
	a.equipamento.append("protecao_leve")
	c.dados.forcar([1, 1])   # Vontade 1 + 5 = 6 vs DT 16
	var r := c.conjurar(a, "eletrocussao", _alvo())
	assert_false(r.ok)
	assert_eq(a.pe, a.pe_maximo - 1, "o PE se perde")


# --- Criação e progressão -----------------------------------------------------------

func _ficha_rita() -> Dictionary:
	return DadosJogo.ler("grupo_inicial").agentes[2].duplicate(true)


func test_ocultista_comeca_com_3_rituais():
	var f := _ficha_rita()
	assert_eq(CriacaoAgente.criar(rs, f).erros, [] as Array[String])
	f.rituais = ["eletrocussao"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())
	f.rituais = ["eletrocussao", "cicatrizacao", "invadir_mente"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "2º círculo em NEX 5%")


func test_ocultista_aprende_ritual_ao_subir_de_nex():
	var rita: Agente = CriacaoAgente.criar(rs, _ficha_rita()).agente
	rita.nex = 10
	var tipos := Progressao.pendencias(rita).map(func(p): return p.tipo)
	assert_true("ritual" in tipos)
	assert_eq(Progressao.aplicar(rita, "ritual", "decadencia"), [] as Array[String])
	assert_true(rita.conhece_ritual("decadencia"))


func test_rituais_salvam():
	var rita: Agente = CriacaoAgente.criar(rs, _ficha_rita()).agente
	rita.san_perdida = 2
	rita.recalcular_maximos(true)
	var copia := Agente.de_dicionario(rs, rita.para_dicionario())
	assert_eq(copia.rituais, rita.rituais)
	assert_eq(copia.san_maximo, rita.san_maximo)
