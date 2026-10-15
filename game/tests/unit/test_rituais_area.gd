extends GutTest
## Fase 4.3: áreas na grade, zonas persistentes, formas discente/verdadeira e condições (p.127-153, p.320).

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


func _alvo(pv: int = 60, lado: String = "ameacas", ficha_extra: Dictionary = {}) -> Ameaca:
	var ficha := {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1}}
	ficha.merge(ficha_extra, true)
	var x := Ameaca.criar(rs, "Alvo", ficha)
	x.lado = lado
	return x


func _combate(com_grade: bool = true) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.membrana = Membrana.carregar_padrao()
	if com_grade:
		c.grade = Grade.new(14, 9)
	return c


func _por(c: Combate, ser: Ser, celula: Vector2i) -> void:
	c.adicionar(ser)
	if c.grade != null:
		c.grade.colocar(ser, celula)


# --- Formas de área na grade -------------------------------------------------------

func test_formas_de_area():
	var g := Grade.new(11, 11)
	assert_eq(g.celulas_da_area("esfera", Vector2i(0, 0), Vector2i(5, 5), 6).size(), 41, "raio 6 m = 4 quadrados")
	var explosao := g.celulas_da_area("explosao", Vector2i(5, 5), Vector2i(0, 0), 6)
	assert_eq(explosao.size(), 40)
	assert_false(Vector2i(5, 5) in explosao, "a explosão não pega o centro (o conjurador)")
	assert_eq(g.celulas_da_area("linha", Vector2i(0, 0), Vector2i(3, 0), 30).size(), 10, "até a borda da grade")
	g.terreno[Vector2i(6, 0)] = Grade.PAREDE
	assert_eq(g.celulas_da_area("linha", Vector2i(0, 0), Vector2i(3, 0), 30).size(), 5, "a parede para a linha")
	g.terreno[Vector2i(5, 3)] = Grade.PAREDE
	assert_false(Vector2i(5, 2) in g.celulas_da_area("esfera", Vector2i(0, 0), Vector2i(5, 5), 6), "atrás da parede")
	var cone := g.celulas_da_area("cone", Vector2i(2, 8), Vector2i(5, 8), 4.5)
	assert_true(Vector2i(4, 8) in cone)
	assert_true(Vector2i(4, 9) in cone)
	assert_false(Vector2i(2, 9) in cone, "fora da abertura de 90°")
	assert_false(Vector2i(1, 8) in cone, "para trás")


func test_paradoxo_atinge_todos_na_esfera_com_uma_rolagem():
	var a := _ocultista(["paradoxo"], 25)
	var c := _combate()
	var x1 := _alvo()
	var x2 := _alvo()
	var amigo := _alvo(60, "agentes")
	var longe := _alvo()
	_por(c, a, Vector2i(0, 4))
	_por(c, x1, Vector2i(8, 4))
	_por(c, x2, Vector2i(9, 4))
	_por(c, amigo, Vector2i(7, 4))
	_por(c, longe, Vector2i(13, 8))
	c.dados.forcar([20, 20, 6, 6, 6, 6, 6, 6, 1, 1, 1])
	var r := c.conjurar(a, "paradoxo", null, "", {"celula": Vector2i(8, 4)})
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(r.alvos.size(), 3, "aliados na área também são atingidos")
	assert_eq(x1.pv, 24)
	assert_eq(x2.pv, 24)
	assert_eq(amigo.pv, 24)
	assert_eq(longe.pv, 60)


func test_area_precisa_de_ponto_em_alcance():
	var a := _ocultista(["paradoxo"], 25)
	var c := _combate()
	_por(c, a, Vector2i(0, 0))
	assert_eq(c.pode_conjurar(a, "paradoxo", null), "escolha o ponto da área")
	assert_eq(c.pode_conjurar(a, "paradoxo", null, "", {"celula": Vector2i(13, 8)}), "ponto fora de alcance", "médio = 12 quadrados")


func test_deflagracao_explode_ao_redor_e_verdadeira_poupa_aliados():
	var a := _ocultista(["deflagracao_de_energia"], 85)
	var c := _combate()
	var inimigo := _alvo(100)
	var amigo := _alvo(100, "agentes")
	_por(c, a, Vector2i(5, 4))
	_por(c, inimigo, Vector2i(8, 4))
	_por(c, amigo, Vector2i(4, 4))
	c.acoes[a] = {"padrao": 1, "movimento": 0}
	assert_eq(c.pode_conjurar(a, "deflagracao_de_energia", a), "precisa de uma ação completa")
	c.acoes.erase(a)
	c.dados.forcar([1, 1, 1, 1, 1, 1, 1])
	var r := c.conjurar(a, "deflagracao_de_energia", a)
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(inimigo.pv, 70, "3d10 × 10")
	assert_eq(amigo.pv, 70)
	assert_eq(a.pv, a.pv_maximo, "o conjurador não é afetado")
	a.afinidade = "energia"
	c.dados.forcar([1, 1, 1, 1, 1, 1])
	assert_true(c.conjurar(a, "deflagracao_de_energia", a, "verdadeiro").ok)
	assert_eq(inimigo.pv, 40)
	assert_eq(amigo.pv, 70, "a forma verdadeira só atinge inimigos")


func test_eletrocussao_discente_em_linha():
	var a := _ocultista(["eletrocussao"], 25)
	var c := _combate()
	var e1 := _alvo()
	var e2 := _alvo()
	var fora := _alvo()
	_por(c, a, Vector2i(1, 4))
	_por(c, e1, Vector2i(3, 4))
	_por(c, e2, Vector2i(5, 4))
	_por(c, fora, Vector2i(5, 5))
	c.dados.forcar([20, 20, 6, 6, 6, 6, 6, 6, 1, 1])
	var r := c.conjurar(a, "eletrocussao", e2, "discente")
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(r.alvos.size(), 2)
	assert_eq(e1.pv, 24)
	assert_eq(e2.pv, 24)
	assert_eq(fora.pv, 60)
	assert_false(e1.tem(Ser.VULNERAVEL), "a forma discente não deixa vulnerável")


func test_eletrocussao_verdadeira_rola_para_cada_alvo():
	var a := _ocultista(["eletrocussao"], 55)
	var c := _combate(false)
	var x1 := _alvo()
	var x2 := _alvo()
	c.dados.forcar([20, 20, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2])
	var r := c.conjurar(a, "eletrocussao", x1, "verdadeiro", {"alvos": [x1, x2]})
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(x1.pv, 60 - 8)
	assert_eq(x2.pv, 60 - 16)


func test_limite_de_alvos():
	var a := _ocultista(["definhar"], 55)
	a.afinidade = "morte"
	var c := _combate(false)
	var lista: Array = []
	for i in 6:
		lista.append(_alvo())
	assert_eq(c.pode_conjurar(a, "definhar", lista[0], "verdadeiro", {"alvos": lista}), "no máximo 5 alvo(s)")
	assert_eq(c.pode_conjurar(a, "definhar", lista[0], "verdadeiro", {"alvos": lista.slice(0, 5)}), "")


func test_forma_verdadeira_exige_afinidade():
	var a := _ocultista(["cicatrizacao"], 85)
	var c := _combate(false)
	assert_string_contains(c.pode_conjurar(a, "cicatrizacao", a, "verdadeiro"), "afinidade")
	a.afinidade = "morte"
	assert_eq(c.pode_conjurar(a, "cicatrizacao", a, "verdadeiro"), "")


func test_formas_de_buff():
	var a := _ocultista(["aprimorar_fisico", "armadura_de_sangue", "arma_atroz"], 55)
	var c := _combate(false)
	var defesa := a.defesa()
	c.dados.forcar([20, 20, 20, 20])
	assert_true(c.conjurar(a, "aprimorar_fisico", a, "discente").ok)
	assert_eq(a.atributo("for"), 3)
	assert_true(c.conjurar(a, "armadura_de_sangue", a, "discente").ok)
	assert_eq(a.defesa(), defesa + 10)
	assert_eq(a.resistencia("corte"), 5)
	a.afinidade = "sangue"
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "arma_atroz", a, "verdadeiro").ok)
	assert_eq(a.efeito_ritual("multiplicador"), 2)
	assert_eq(a.efeito_ritual("margem"), 2)


func test_decadencia_discente_vai_na_arma():
	var a := _ocultista(["decadencia"], 25)
	var c := _combate(false)
	var x := _alvo(40)
	c.dados.forcar([20, 20, 15, 2, 4, 4, 4])
	var r := c.conjurar(a, "decadencia", x, "discente")
	assert_true(r.ok, str(r.get("erro", "")))
	assert_true(r.ataque.acertou)
	assert_eq(x.pv, 40 - (2 + 1 + 12 + 3), "desarmado 1d3 + Força + 3d8+3 do ritual")


func test_odio_discente_da_ataque_adicional():
	var a := _ocultista(["odio_incontrolavel"], 25)
	var c := _combate(false)
	var x := _alvo(100)
	c.adicionar(a)
	c.adicionar(x)
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "odio_incontrolavel", a, "discente").ok)
	c.acoes[a] = {"padrao": 1, "movimento": 1}
	var r := c.agredir(a, x, rs.arma("desarmado"))
	assert_not_null(r.ataque_adicional)
	assert_not_null(r.ataque_adicional.teste)


func test_velocidade_mortal_discente_e_verdadeira_sustentada():
	var a := _ocultista(["velocidade_mortal"], 55)
	var c := _combate(false)
	var x := _alvo(30, "agentes")
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "velocidade_mortal", x, "discente").ok)
	c._ao_iniciar_turno(x)
	assert_eq(c.acoes_restantes(x).padrao, 2)
	assert_eq(c.acoes_restantes(x).movimento, 1)
	var b := _ocultista(["velocidade_mortal"], 85)
	b.afinidade = "morte"
	var y1 := _alvo(30, "agentes")
	var y2 := _alvo(30, "agentes")
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(b, "velocidade_mortal", y1, "verdadeiro", {"alvos": [y1, y2]}).ok)
	assert_true(y1.rituais_ativos.has("velocidade_mortal"))
	assert_true(y2.rituais_ativos.has("velocidade_mortal"))
	var pe := b.pe
	b.iniciar_turno()
	c._manter_sustentados(b)
	assert_eq(b.pe, pe - 1, "1 PE por turno, não por alvo")
	assert_true(y2.rituais_ativos.has("velocidade_mortal"))


# --- Zonas persistentes ------------------------------------------------------------

func test_poeira_da_podridao_sustentada():
	var a := _ocultista(["poeira_da_podridao"], 55)
	var c := _combate()
	var x := _alvo(100)
	_por(c, a, Vector2i(0, 4))
	_por(c, x, Vector2i(6, 4))
	c.dados.forcar([20, 20, 8, 8, 8, 8, 1])
	assert_true(c.conjurar(a, "poeira_da_podridao", x).ok)
	assert_eq(x.pv, 68)
	assert_true(x.tem(Ser.SEM_CURA))
	x.curar(10)
	assert_eq(x.pv, 68, "quem falha não recupera PV")
	assert_eq(c.zonas().size(), 1)
	c.dados.forcar([1, 1, 1, 1, 1])
	c._processar_zonas(a)
	assert_eq(x.pv, 64, "no início de cada turno do conjurador")
	a.pe = 0
	c._manter_sustentados(a)
	assert_true(c.zonas().is_empty(), "sem PE, a nuvem se desfaz")


func test_miasma_verdadeiro_dura_tres_rodadas_e_enjoa():
	var a := _ocultista(["miasma_entropico"], 55)
	var c := _combate()
	var x := _alvo(100)
	_por(c, a, Vector2i(0, 4))
	_por(c, x, Vector2i(6, 4))
	c.dados.forcar([20, 20, 1, 1, 1, 1, 1, 1, 1])
	assert_true(c.conjurar(a, "miasma_entropico", x, "verdadeiro").ok)
	assert_eq(x.pv, 94)
	assert_true(x.tem(Ser.ENJOADO))
	c.acoes[x] = {"padrao": 1, "movimento": 1}
	assert_true(c.gastar_acao(x, "movimento"))
	assert_eq(c.acoes_restantes(x).padrao, 0, "enjoado: só uma ação por rodada")
	c.dados.forcar([2, 2, 2, 2, 2, 2, 1])
	c._processar_zonas(x)
	assert_eq(x.pv, 82, "quem começa o turno na nuvem sofre de novo")
	for i in 3:
		c._processar_zonas(a)
	assert_true(c.zonas().is_empty())


func test_purgatorio_dobra_dano_fisico_e_prende():
	var a := _ocultista(["purgatorio"], 55)
	var c := _combate()
	var x := _alvo(60)
	var amigo := _alvo(60, "agentes")
	_por(c, a, Vector2i(0, 4))
	_por(c, x, Vector2i(4, 4))
	_por(c, amigo, Vector2i(5, 4))
	c.dados.forcar([20, 20])
	assert_true(c.conjurar(a, "purgatorio", x).ok)
	assert_eq(c.aplicar_dano(x, 10, "corte"), 20)
	assert_eq(c.aplicar_dano(amigo, 10, "corte"), 10, "só inimigos ficam vulneráveis")
	assert_eq(c.aplicar_dano(x, 10, "sangue"), 10, "só dano físico")
	c.acoes[x] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([1, 1, 1, 1, 1, 1, 1])
	assert_false(c.mover(x, Vector2i(0, 6)), "falhou em Fortitude: não sai")
	assert_eq(x.pv, 60 - 20 - 10 - 6)
	assert_eq(c.acoes_restantes(x).movimento, 0)


func test_tentaculos_agarram_esmagam_e_soltam():
	var a := _ocultista(["tentaculos_de_lodo"], 55)
	var c := _combate()
	var x := _alvo(60, "ameacas", {"pericias": {"atletismo": {"dados": 1, "bonus": 10}}})
	_por(c, a, Vector2i(0, 4))
	_por(c, x, Vector2i(6, 4))
	c.dados.forcar([20, 20, 20, 20, 1])
	assert_true(c.conjurar(a, "tentaculos_de_lodo", x).ok)
	assert_true(x.tem(Ser.AGARRADO))
	assert_eq(c.grade.custo_passo(Vector2i(5, 4), Vector2i(6, 4)), 2, "terreno difícil")
	c.acoes[x] = {"padrao": 1, "movimento": 1}
	assert_false(c.mover(x, Vector2i(7, 4)), "agarrado não se move")
	c.dados.forcar([3, 3, 3, 3])
	c._processar_zonas(a)
	assert_eq(x.pv, 48, "quem já está agarrado é esmagado")
	c.dados.forcar([20])
	assert_true(c.escapar(x))
	assert_false(x.tem(Ser.AGARRADO))


# --- Condições (p.320-321) ---------------------------------------------------------

func test_condicoes_agravam_e_penalizam():
	var a := _ocultista([])
	var dados_luta := a.dados_da_pericia("luta")
	a.aplicar_condicao(Ser.ABALADO)
	assert_eq(a.dados_da_pericia("luta"), dados_luta - 1)
	a.aplicar_condicao(Ser.ABALADO)
	assert_true(a.tem(Ser.APAVORADO))
	assert_false(a.tem(Ser.ABALADO))
	assert_eq(a.dados_da_pericia("ocultismo"), a.atributo("int") - 2)
	var b := _ocultista([])
	var defesa := b.defesa()
	b.aplicar_condicao(Ser.FATIGADO)
	b.aplicar_condicao(Ser.FATIGADO)
	assert_true(b.tem(Ser.EXAUSTO))
	assert_eq(b.defesa(), defesa - 2)
	assert_eq(b.penalidade_dados_atributo("vig"), 2)
	b.aplicar_condicao(Ser.AGARRADO)
	assert_eq(b.defesa(), defesa - 2 - 5, "agarrado fica desprevenido")


func test_criaturas_sao_imunes_a_condicoes_mentais():
	var cria := Ameaca.criar(rs, "Cria", DadosJogo.ameaca(rs, "cria_de_sangue").ficha)
	assert_true(cria.criatura)
	cria.aplicar_condicao(Ser.PASMO)
	cria.aplicar_condicao(Ser.ABALADO)
	assert_false(cria.tem(Ser.PASMO))
	assert_false(cria.tem(Ser.ABALADO))
	cria.aplicar_condicao(Ser.VULNERAVEL)
	assert_true(cria.tem(Ser.VULNERAVEL), "condições físicas valem")
	var pv := cria.pv
	cria.sofrer_dano_mental(10)
	assert_eq(cria.pv, pv, "imune a dano mental")
