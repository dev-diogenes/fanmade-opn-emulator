extends GutTest
## Itens paranormais de investigação e de mapa, e os itens de combate que faltavam (docs/72):
## câmera de aura, medidor, scanner, escuta, emissor; arremesso, amarras, mina e algemas.

var rs: RulesetOp2022
const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente() -> Agente:
	return Agente.criar(rs, "Agente", "especialista", ATTRS, {"luta": "treinado", "pontaria": "treinado", "ocultismo": "treinado", "tatica": "treinado"})


func _pessoa(nome := "Cultista") -> Ameaca:
	var a := Ameaca.criar(rs, nome, {"pv": 30, "defesa": 10, "atributos": {"agi": 1, "for": 1},
		"pericias": {"luta": {"dados": 1, "bonus": 0}, "reflexos": {"dados": 1, "bonus": 0}}})
	a.lado = "ameacas"
	return a


func _criatura(elemento := "sangue") -> Ameaca:
	var c := Ameaca.criar(rs, "Bicho", {"pv": 60, "defesa": 10, "criatura": true, "elemento": elemento, "vulnerabilidades": ["morte"],
		"atributos": {"agi": 1}, "pericias": {"reflexos": {"dados": 1, "bonus": 0}, "vontade": {"dados": 1, "bonus": 0}}})
	c.lado = "ameacas"
	return c


func _em_grade(a: Agente, outros: Array, pos: Array) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.grade = Grade.new(14, 7)
	c.adicionar(a)
	c.grade.colocar(a, pos[0])
	for i in outros.size():
		c.adicionar(outros[i])
		c.grade.colocar(outros[i], pos[i + 1])
	return c


# --- Câmera de aura ------------------------------------------------------------------

func test_aura_confirma_ou_desmente_o_depoimento():
	var caso := Caso.gerar(Dados.new(42))
	caso.registrar_pista("{indicio}", "quem", "teste", true, 1)   # ímpar: a testemunha se enganou
	var i := caso.depoimento_a_verificar()
	assert_eq(i, caso.pistas.size() - 1)
	var r := caso.verificar_depoimento(i)
	assert_false(r.confirmada, "o traço era de outro candidato")
	assert_true(caso.pistas[i].desmentida)
	assert_false(String(caso.pistas[i].indicio) in caso.indicios_duvidosos("quem"))
	caso.registrar_pista("{indicio}", "quem", "teste", true, 2)   # par: acertou
	var r2 := caso.verificar_depoimento(caso.depoimento_a_verificar())
	assert_true(r2.confirmada)
	assert_true(String(r2.pista.indicio) in caso.indicios_encontrados("quem"), "virou pista firme")


func test_camera_na_cena_gasta_pe_e_a_acao():
	var m := Missao.nova(42)
	var a: Agente = m.agentes[0]
	a.equipamento.append("camera_aura")
	var cena := CenaInvestigacao.nova(rs, Dados.new(1), m.caso, "casa_abandonada", [a])
	assert_string_contains(cena.motivo_fotografar(), "Nenhum depoimento")
	m.caso.registrar_pista("{indicio}", "quem", "teste", true, 3)
	var pe := a.pe
	assert_true(cena.fotografar_aura().ok)
	assert_eq(a.pe, pe - 1)


# --- Itens de mapa ---------------------------------------------------------------------

func _missao_com(item: String) -> Array:
	var m := Missao.nova(42)
	var a := m.agente_atual()
	a.equipamento.append(item)
	a.pericias["ocultismo"] = "treinado"
	a.pe = 20
	return [m, a]


func test_medidor_revela_criaturas_por_perto():
	var par := _missao_com("medidor_de_membrana")
	var m: Missao = par[0]
	var a: Agente = par[1]
	var perto := m._criaturas_perto(m.posicao(a), 4)
	var r := m.usar_item_de_mapa("medidor_de_membrana")
	assert_true(r.ok)
	for h in perto:
		assert_true(m.mapa.revelado(h))
	assert_string_contains(m.motivo_item_de_mapa(a, "medidor_de_membrana"), "ação", "uma por turno")


func test_scanner_do_elemento_do_caso_aponta_o_covil():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	var scanner := "scanner_" + m.caso.elemento
	a.equipamento.append(scanner)
	a.pe = 20
	var obj := m.mapa.encontrar("objetivo")
	m.posicoes[a] = obj
	var r := m.usar_item_de_mapa(scanner)
	assert_string_contains(String(r.texto), "covil")
	assert_true(m.mapa.revelado(obj))


func test_escuta_ajuda_a_identificar_nos_encontros():
	var par := _missao_com("escuta_de_ruidos")
	var m: Missao = par[0]
	assert_true(m.usar_item_de_mapa("escuta_de_ruidos").ok)
	assert_true(m.escuta_instalada)
	var h := Vector2i(-999, -999)
	for c in m.mapa.celulas:
		if String(m.mapa.conteudo(c).get("tipo", "")) == "encontro":
			h = c
			break
	for x in m.agentes:
		m.posicoes[x] = h
	m._preparar_encontro(h, String(m.mapa.conteudo(h).encontro), false)
	assert_eq(int(m.encontro_pendente.regras.bonus_identificar), 5)


func test_emissor_puxa_as_criaturas_do_elemento():
	var par := _missao_com("emissor_de_pulsos")
	var m: Missao = par[0]
	var a: Agente = par[1]
	var criaturas := m._criaturas_perto(m.posicao(a), 6)
	if criaturas.is_empty():
		pass_test("sem criatura perto nesta semente")
		return
	var alvo: Vector2i = criaturas[0]
	var el := m.elemento_de(String(m.mapa.conteudo(alvo).encontro))
	var antes := Hex.distancia(alvo, m.posicao(a))
	assert_true(m.usar_item_de_mapa("emissor_de_pulsos", el).ok)
	var depois := 99
	for h in m._criaturas_perto(m.posicao(a), 6, el):
		depois = mini(depois, Hex.distancia(h, m.posicao(a)))
	assert_lt(depois, antes + 1, "veio para perto (ou já estava colada)")


# --- Combate -----------------------------------------------------------------------

func test_arremessar_a_faca():
	var a := _agente()
	a.equipamento.append("faca")
	a.arma_id = "faca"
	var alvo := _pessoa()
	var c := _em_grade(a, [alvo], [Vector2i(1, 3), Vector2i(5, 3)])
	assert_lt(c.chance_de_acerto(a, alvo, a.arma()), 0.0, "de longe, a faca não alcança")
	c.dados.forcar([15, 15, 3])
	var r := c.atacar(a, alvo, a.arma(), 0, {"arremessar": true})
	assert_true(r.acertou)
	assert_eq(r.teste.pericia, "pontaria")
	assert_eq(r.dano, 3 + 2, "a Força soma no arremesso")
	assert_eq(a.mods_cena.get("arma_caida"), "faca")
	assert_false(c.pegar_arma(a), "a faca está lá longe")


func test_arremessar_o_que_nao_e_de_arremesso_custa_um_dado():
	var t := Combate.new(rs, Dados.new(1)).arma_arremessada(rs.arma("machete"))
	assert_eq(int(t.dados_ataque), -1)
	assert_eq(int(Combate.new(rs, Dados.new(1)).arma_arremessada(rs.arma("lanca")).get("dados_ataque", 0)), 0)


func test_armadilha_das_amarras_prende_a_criatura_que_teme_o_elemento():
	var a := _agente()
	a.equipamento.append("amarras_morte")
	a.pe = 10
	var bicho := _criatura()
	var c := _em_grade(a, [bicho], [Vector2i(1, 3), Vector2i(8, 3)])
	assert_true(c.preparar_armadilha(a, "amarras_morte", Vector2i(5, 3)).ok)
	assert_false(a.tem_item("amarras_morte"), "as amarras ficam no chão")
	c.acoes[bicho] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([1])
	assert_true(c.mover(bicho, Vector2i(5, 3)))
	assert_true(bicho.tem(Ser.IMOVEL))


func test_laco_das_amarras_repete_e_cobra_pe():
	var a := _agente()
	a.equipamento.append("amarras_morte")
	a.pe = 10
	var bicho := _criatura()
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(a)
	c.adicionar(bicho)
	c.dados.forcar([1])
	assert_true(c.usar_item_combate(a, "amarras_morte", bicho).ok)
	assert_true(bicho.tem(Ser.PARALISADO))
	var pe := a.pe
	c.dados.forcar([1])
	c._processar_aflicoes(bicho)
	assert_eq(a.pe, pe - 1, "manter custa 1 PE por rodada")
	assert_true(bicho.tem(Ser.PARALISADO), "falhou de novo: continua presa")
	c.dados.forcar([20])
	c._processar_aflicoes(bicho)
	assert_false(bicho.tem(Ser.PARALISADO), "passou: se solta")


func test_mina_instalar_e_detonar():
	var a := _agente()
	a.equipamento.append("mina_antipessoal")
	var alvo := _pessoa()
	var c := _em_grade(a, [alvo], [Vector2i(2, 3), Vector2i(4, 3)])
	c.dados.forcar([20, 20])
	assert_true(c.instalar_mina(a, "mina_antipessoal", Vector2i(6, 3)).instalada)
	assert_true(c.tem_mina(a))
	c.grade.colocar(a, Vector2i(2, 6))
	c.dados.forcar([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1])
	assert_true(c.detonar_mina(a).ok)
	assert_eq(alvo.pv, 30 - 24, "12d6 no cone (falhou em Reflexos)")


## Achado no playtest de docs/72: sem Tática treinada (perícia só para treinados), a mina era
## gasta numa tentativa que nem podia acontecer.
func test_mina_sem_tatica_nao_gasta_o_item():
	var a := Agente.criar(rs, "Agente", "especialista", ATTRS, {"luta": "treinado"})
	a.equipamento.append("mina_antipessoal")
	var c := _em_grade(a, [_pessoa()], [Vector2i(2, 3), Vector2i(4, 3)])
	var r := c.instalar_mina(a, "mina_antipessoal", Vector2i(6, 3))
	assert_false(r.ok)
	assert_string_contains(String(r.erro), "Tática")
	assert_true(a.tem_item("mina_antipessoal"), "o item continua na mochila")


func test_algemas():
	var a := _agente()
	a.equipamento.append("algemas")
	var cultista := _pessoa()
	var c := _em_grade(a, [cultista], [Vector2i(2, 3), Vector2i(3, 3)])
	assert_string_contains(c.motivo_algemar(a, cultista), "Agarre")
	cultista.aplicar_condicao(Ser.CAIDO)
	assert_true(c.algemar(a, cultista).algemado)
	assert_true(cultista.esta_fora_de_combate(), "algemado se rende")
	assert_true(cultista in c.rendidos(), "vai para o interrogatório")
	assert_false(a.tem_item("algemas"))
	assert_string_contains(c.motivo_algemar(a, _criatura()), "Sem algemas")
