extends GutTest
## Rituais e poderes do livro que ganharam efeito (docs/69): o lote de combate, os rituais de
## mapa e de caso, e os poderes de classe e de origem que cabem nos sistemas do jogo.

var rs: RulesetOp2022

const ATTRS := {"agi": 1, "for": 1, "int": 2, "pre": 2, "vig": 2}
const COMPONENTES := ["componentes_energia", "componentes_morte", "componentes_sangue", "componentes_conhecimento"]


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ocultista(rituais: Array, nex: int = 60) -> Agente:
	var a := Agente.criar(rs, "Rita", "ocultista", ATTRS, {"ocultismo": "treinado", "vontade": "treinado", "atletismo": "treinado"}, nex)
	for r in rituais:
		a.rituais.append(r)
	for c in COMPONENTES:
		a.equipamento.append(c)
	return a


func _alvo(nome := "Alvo", pv := 100, criatura := false) -> Ameaca:
	var a := Ameaca.criar(rs, nome, {"pv": pv, "defesa": 10, "criatura": criatura, "atributos": {"agi": 1, "vig": 1, "pre": 1},
		"pericias": {"fortitude": {"dados": 1, "bonus": 0}, "vontade": {"dados": 1, "bonus": 0}, "reflexos": {"dados": 1, "bonus": 0},
			"luta": {"dados": 1, "bonus": 0}}})
	a.lado = "ameacas"
	return a


func _combate(a: Agente, outros: Array = [], posicoes: Array = []) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.membrana = Membrana.carregar_padrao()
	c.adicionar(a)
	for o in outros:
		c.adicionar(o)
	if not posicoes.is_empty():
		c.grade = Grade.new(14, 7)
		c.grade.colocar(a, posicoes[0])
		for i in outros.size():
			c.grade.colocar(outros[i], posicoes[i + 1])
	return c


# --- Rituais de combate ----------------------------------------------------------------

func test_fortalecimento_sensorial():
	var a := _ocultista(["fortalecimento_sensorial"])
	var c := _combate(a, [_alvo()])
	var antes := a.dados_da_pericia("luta")
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "fortalecimento_sensorial", a).ok)
	assert_eq(a.dados_da_pericia("luta"), antes + 1)
	assert_eq(a.dados_da_pericia("percepcao"), ATTRS.pre + 1)


func test_polarizacao_e_protecao_contra_rituais():
	var a := _ocultista(["polarizacao_caotica", "protecao_contra_rituais"])
	var c := _combate(a, [_alvo()])
	c.dados.forcar([20, 20])
	c.conjurar(a, "polarizacao_caotica", a)
	assert_eq(a.resistencia("corte"), 5, "repelir: resistência 5 a dano físico")
	c.conjurar(a, "protecao_contra_rituais", a)
	assert_eq(a.resistencia("sangue"), 5, "resistência 5 a dano paranormal")
	assert_eq(a.efeito_ritual("resistencia_rituais"), 5)


func test_corpo_adaptado_ignora_o_que_se_respira():
	var a := _ocultista(["corpo_adaptado"])
	var c := _combate(a, [_alvo()])
	c.dados.forcar([20, 20])
	c.conjurar(a, "corpo_adaptado", a)
	assert_gte(a.bonus_contra(["respiracao"], "fortitude"), 50)


func test_chamas_do_caos_na_arma():
	var a := _ocultista(["chamas_do_caos"])
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([20, 20])
	c.conjurar(a, "chamas_do_caos", a)
	c.dados.forcar([15, 3, 4])
	var r := c.atacar(a, alvo, rs.arma("machete"))
	assert_eq(r.dano, 3 + 1 + 4, "1d6 + Força + 1d6 de fogo")


func test_nuvem_de_cinzas_encobre_a_area():
	var a := _ocultista(["nuvem_de_cinzas"])
	var alvo := _alvo()
	var c := _combate(a, [alvo], [Vector2i(4, 3), Vector2i(10, 3)])
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "nuvem_de_cinzas", null, "", {"celula": Vector2i(10, 3)}).ok, "alcance curto: 6 quadrados")
	assert_true(c.grade.camuflado(alvo))
	assert_false(c.grade.camuflado(a), "fora da nuvem")


func test_dissonancia_impede_rituais_e_cineraria_sobe_a_dt():
	var a := _ocultista(["dissonancia_acustica", "cineraria", "eletrocussao"])
	var c := _combate(a, [_alvo()], [Vector2i(1, 3), Vector2i(8, 3)])
	c.dados.forcar([20, 20])
	c.conjurar(a, "cineraria", null, "", {"celula": Vector2i(1, 3)})
	assert_eq(c._dt_extra_das_zonas(a), 5, "Cinerária: DT +5 dentro da névoa")
	c.dados.forcar([20, 20])
	c.conjurar(a, "dissonancia_acustica", null, "", {"celula": Vector2i(1, 3)})
	assert_string_contains(c.pode_conjurar(a, "eletrocussao", c.participantes[1]), "Dissonância")


func test_contencao_fantasmagorica_e_os_lacos():
	var a := _ocultista(["contencao_fantasmagorica"])
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([20, 20, 1])
	c.conjurar(a, "contencao_fantasmagorica", alvo)
	assert_true(alvo.tem(Ser.AGARRADO))
	assert_eq(int(alvo.mods_cena.lacos.n), 3)
	c.dados.forcar([20])
	c.escapar(alvo)
	assert_lt(int(alvo.mods_cena.get("lacos", {"n": 0}).n), 3, "Atletismo rompe laços")


func test_flagelo_de_sangue_pune_quem_ataca():
	var a := _ocultista(["flagelo_de_sangue"])
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([20, 20])
	c.conjurar(a, "flagelo_de_sangue", alvo)
	assert_true(alvo.rituais_ativos.has("flagelo_de_sangue"))
	c.acoes[alvo] = {"padrao": 1, "movimento": 1}
	var pv := alvo.pv
	c.dados.forcar([1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6])   # ataque, Fortitude falha, 10d6 = 60
	c.agredir(alvo, a, alvo.ataques[0] if not alvo.ataques.is_empty() else rs.arma("desarmado"))
	assert_eq(alvo.pv, pv - 60)
	assert_true(alvo.tem(Ser.ENJOADO))


func test_flagelo_nao_pega_em_criatura():
	var a := _ocultista(["flagelo_de_sangue"])
	var cria := _alvo("Bicho", 100, true)
	var c := _combate(a, [cria])
	c.dados.forcar([20, 20])
	c.conjurar(a, "flagelo_de_sangue", cria)
	assert_false(cria.rituais_ativos.has("flagelo_de_sangue"))


func test_esconder_dos_olhos_dura_uma_rodada():
	var a := _ocultista(["esconder_dos_olhos"])
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "esconder_dos_olhos", a).ok)
	assert_eq(c.acoes_restantes(a).padrao, 1, "execução livre")
	c.dados.forcar([20, 20, 30])
	var r := c.atacar(alvo, a, rs.arma("desarmado"))
	assert_false(r.acertou, "camuflagem total: errou")
	c._ao_iniciar_turno(a)
	assert_eq(a.efeito_ritual("invisivel"), 0, "acabou no turno seguinte")


func test_zerar_entropia_paralisa_e_o_teste_liberta():
	var a := _ocultista(["zerar_entropia"])
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([20, 20, 1])
	c.conjurar(a, "zerar_entropia", alvo)
	assert_true(alvo.tem(Ser.PARALISADO))
	c.dados.forcar([20])
	c._processar_aflicoes(alvo)
	assert_false(alvo.tem(Ser.PARALISADO))
	assert_false(alvo.rituais_ativos.has("zerar_entropia"))


func test_ancora_temporal_e_ferver_sangue():
	var a := _ocultista(["ancora_temporal", "ferver_sangue"])
	var alvo := _alvo()
	var c := _combate(a, [alvo])
	c.dados.forcar([20, 20])
	c.conjurar(a, "ancora_temporal", alvo)
	c.dados.forcar([1])
	c._processar_aflicoes(alvo)
	assert_true(alvo.tem(Ser.IMOVEL), "falhou: não se desloca neste turno")
	var pv := alvo.pv
	c.dados.forcar([20, 20, 1, 8, 8, 8, 8])
	c.conjurar(a, "ferver_sangue", alvo)
	assert_eq(alvo.pv, pv - 32, "4d8 de Sangue na hora")
	assert_true(alvo.tem(Ser.FRACO))


func test_forma_monstruosa():
	var a := _ocultista(["forma_monstruosa", "eletrocussao"])
	var c := _combate(a, [_alvo()])
	c.dados.forcar([20, 20])
	c.conjurar(a, "forma_monstruosa", a)
	assert_eq(a.pv_temporario, 30)
	assert_eq(a.efeito_ritual("ataque_corpo_a_corpo"), 5)
	assert_string_contains(c.pode_conjurar(a, "eletrocussao", c.participantes[1]), "forma monstruosa")


func test_salto_fantasma():
	var a := _ocultista(["salto_fantasma"])
	var c := _combate(a, [_alvo()], [Vector2i(1, 3), Vector2i(12, 3)])
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "salto_fantasma", null, "", {"celula": Vector2i(9, 1)}).ok)
	assert_eq(c.grade.posicao(a), Vector2i(9, 1))
	assert_eq(c.acoes_restantes(a).movimento, 0, "não age mais no turno")


func test_dissipar_ritual():
	var a := _ocultista(["dissipar_ritual", "fortalecimento_sensorial"])
	var b := _alvo()
	b.nome = "Outro"
	var c := _combate(a, [b])
	c.dados.forcar([20, 20])
	c.conjurar(a, "fortalecimento_sensorial", a)
	c.dados.forcar([20, 20, 20, 20])
	c.conjurar(a, "dissipar_ritual", a)
	assert_false(a.rituais_ativos.has("fortalecimento_sensorial"))


func test_vomitar_pestes_morde_no_turno_do_conjurador():
	var a := _ocultista(["vomitar_pestes"])
	var alvo := _alvo()
	var c := _combate(a, [alvo], [Vector2i(1, 3), Vector2i(6, 3)])
	c.dados.forcar([20, 20])
	c.conjurar(a, "vomitar_pestes", null, "", {"celula": Vector2i(6, 3)})
	assert_eq(alvo.pv, 100, "não morde na hora")
	c.dados.forcar([1, 1, 1, 1, 1, 1])
	c._processar_zonas(a)
	assert_lt(alvo.pv, 100)


func test_transfigurar_terra():
	var a := _ocultista(["transfigurar_terra"])
	var c := _combate(a, [_alvo()], [Vector2i(1, 3), Vector2i(12, 3)])
	c.dados.forcar([20, 20])
	c.conjurar(a, "transfigurar_terra", null, "", {"celula": Vector2i(6, 3)})
	assert_true(c.grade.dificil_por_efeito.has(Vector2i(6, 3)))


func test_ritual_de_mapa_nao_aparece_no_combate():
	var a := _ocultista(["terceiro_olho"])
	var c := _combate(a, [_alvo()])
	assert_string_contains(c.pode_conjurar(a, "terceiro_olho", a), "fora do combate")


# --- Rituais de mapa e de caso ---------------------------------------------------------

func _missao_com(rituais: Array) -> Array:
	var m := Missao.nova(42)
	var rita: Agente = null
	for x in m.agentes:
		if x.nome == "Rita":
			rita = x
	for r in rituais:
		rita.rituais.append(r)
	rita.equipamento.append("componentes_conhecimento")
	rita.nex = 60
	rita.pe = 30
	m.indice = m.agentes.find(rita)
	return [m, rita]


func test_terceiro_olho_da_pista_uma_vez():
	var par := _missao_com(["terceiro_olho"])
	var m: Missao = par[0]
	var rita: Agente = par[1]
	assert_true(["terceiro_olho", ""] in m.rituais_fora_de_combate(rita))
	var antes: int = m.caso.pistas.size()
	assert_false(m.conjurar_no_mapa("terceiro_olho", "", rita).is_empty())
	assert_eq(m.caso.pistas.size(), antes + 1)
	assert_false(["terceiro_olho", ""] in m.rituais_fora_de_combate(rita), "uma vez por missão")


func test_alterar_memoria_apaga_usos_da_credencial():
	var par := _missao_com(["alterar_memoria"])
	var m: Missao = par[0]
	var rita: Agente = par[1]
	m.credencial.usos = 3
	assert_false(m.conjurar_no_mapa("alterar_memoria", "", rita).is_empty())
	assert_eq(int(m.credencial.usos), 1)


func test_enfeiticar_guarda_mais_dez():
	var par := _missao_com(["enfeiticar"])
	var m: Missao = par[0]
	var rita: Agente = par[1]
	m.conjurar_no_mapa("enfeiticar", "", rita)
	assert_eq(int(m.bonus_de_ritual[rita.id].valor), 10)
	var salvo := m.para_dicionario()
	assert_true(salvo.has("bonus_de_ritual"))


# --- Poderes de classe e de origem -------------------------------------------------------

func test_tecnica_medicinal_soma_intelecto():
	var a := Agente.criar(rs, "Celeste", "especialista", {"agi": 1, "for": 1, "int": 3, "pre": 1, "vig": 1}, {}, 5)
	a.origem_id = "agente_de_saude"
	a.recalcular_maximos(true)
	assert_eq(a.bonus_cura(), 3)
	a.equipamento.append("cicatrizante")
	var c := Combate.new(rs, Dados.new(1))
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	a.pv = 1
	c.dados.forcar([1, 1])
	assert_eq(c.usar_item(a, "cicatrizante", a), 1 + 1 + 2 + 3)


func test_tanque_de_guerra():
	var a := Agente.criar(rs, "T", "combatente", ATTRS, {}, 50)
	a.equipamento.append("protecao_pesada")
	var d := a.defesa()
	var r := a.resistencia("corte")
	a.poderes.append("tanque_de_guerra")
	assert_eq(a.defesa(), d + 2)
	assert_eq(a.resistencia("corte"), r + 2)


func test_fluxo_de_poder_mantem_dois_sustentados():
	var a := _ocultista(["polarizacao_caotica", "dissonancia_acustica"], 65)
	var c := _combate(a, [_alvo()], [Vector2i(1, 3), Vector2i(12, 3)])
	c.dados.forcar([20, 20, 20, 20])
	c.conjurar(a, "polarizacao_caotica", a)
	c.conjurar(a, "dissonancia_acustica", null, "", {"celula": Vector2i(8, 3)})
	assert_false(a.rituais_ativos.has("polarizacao_caotica"), "sem o poder, um sustentado por vez")
	a.poderes.append("fluxo_de_poder")
	c.dados.forcar([20, 20])
	c.conjurar(a, "polarizacao_caotica", a)
	assert_true(a.rituais_ativos.has("polarizacao_caotica"))
	assert_eq(c._sustentados.filter(func(s): return s.conjurador == a).size(), 2)


func test_perito_em_explosivos_poupa_aliados():
	var a := Agente.criar(rs, "E", "especialista", {"agi": 1, "for": 1, "int": 2, "pre": 1, "vig": 1}, {}, 5)
	a.poderes.append("perito_em_explosivos")
	a.equipamento.append("granada_de_fragmentacao")
	var aliado := Agente.criar(rs, "Aliado", "combatente", ATTRS, {}, 5)
	var alvo := _alvo()
	var c := _combate(a, [aliado, alvo], [Vector2i(1, 3), Vector2i(6, 3), Vector2i(7, 3)])
	var pv := aliado.pv
	assert_true(c.usar_granada(a, "granada_de_fragmentacao", Vector2i(6, 3)).ok)
	assert_eq(aliado.pv, pv, "o aliado é poupado")
	assert_lt(alvo.pv, 100)


func test_impostor_troca_a_pericia_por_enganacao():
	var par := _missao_com([])
	var m: Missao = par[0]
	var rita: Agente = par[1]
	rita.origem_id = "trambiqueiro"
	assert_true(m.trocas_de_pericia(rita).has("enganacao"))
	assert_eq(int(m._poderes_no_evento(rita, "diplomacia").dados), 0)
	var esp := Agente.criar(rs, "Esp", "especialista", ATTRS, {}, 15)
	esp.poderes.append("primeira_impressao")
	assert_eq(int(m._poderes_no_evento(esp, "diplomacia").dados), 2)


func test_acalentar_devolve_sanidade():
	var a := Agente.criar(rs, "Padre", "ocultista", ATTRS, {"religiao": "treinado"}, 5)
	a.origem_id = "religioso"
	var b := Agente.criar(rs, "Aflito", "combatente", ATTRS, {}, 5)
	b.san = 0
	b.condicoes[Ser.ENLOUQUECENDO] = true
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(a)
	c.adicionar(b)
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([20, 20, 4])
	var t := c.acalmar(a, b, "religiao")
	assert_true(t.sucesso)
	assert_eq(b.san, 1 + 4 + 2, "1 de sair do enlouquecendo, e 1d6 + Presença")
