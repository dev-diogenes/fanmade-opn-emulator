extends GutTest
## Fase 4.5: ameaças de VD alto, enxames, assassino, comandante e líder de culto (cap. 7).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func _agente(nex: int = 50) -> Agente:
	return Agente.criar(rs, "Agente", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado", "fortitude": "treinado"}, nex)


## Um alvo resistente, do lado dos agentes, para receber golpes fortes sem morrer.
func _saco(pv: int = 1000) -> Ameaca:
	var s := Ameaca.criar(rs, "Saco", {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1}})
	s.lado = "agentes"
	return s


func _combate(regras: Dictionary = {}) -> Combate:
	return Combate.new(rs, Dados.new(1), regras)


func test_mordida_mental_e_imunidade_da_sukkalgir():
	var c := _combate()
	var sk := _ameaca("sukkalgir")
	var a := _agente()
	var pv := a.pv
	var san := a.san
	c.dados.forcar([15, 15, 15, 5, 5, 1, 1, 1, 20])
	c.atacar(sk, a, sk.ataques[0])
	assert_eq(a.san, san - 10, "dano mental vai para a Sanidade")
	assert_eq(a.pv, pv)
	assert_eq(c.aplicar_dano(sk, 50, "balistico"), 0)
	assert_eq(c.aplicar_dano(sk, 50, "impacto"), 40)


func test_aura_desesperada():
	var c := _combate()
	var sk := _ameaca("sukkalgir")
	var a := _agente()
	c.adicionar(sk)
	c.adicionar(a)
	var san := a.san
	c.dados.forcar([6, 6, 1])
	c._inicio_de_turno_ameacas(a)
	assert_eq(a.san, san - 12)


func test_desespero_do_rastejador():
	var c := _combate()
	var r := _ameaca("rastejador_sombrio")
	var a := _agente()
	var pv := a.pv
	var san := a.san
	c.dados.forcar([15, 15, 15, 15, 1, 1, 1, 1, 1])
	c.atacar(r, a, r.ataques[0])
	assert_eq(a.pv, pv - 9)
	assert_eq(a.san, san - 9, "o mesmo dano, na mente")


func test_viajante_invisivel_e_devorar_memoria():
	var c := _combate()
	var v := _ameaca("viajante")
	var a := _agente()
	c.dados.forcar([20, 30])
	assert_false(c.atacar(a, v, rs.arma("desarmado")).acertou, "50% de chance de golpear o vazio")
	assert_false(c.usar_habilidade(v, "devorar_memoria", a).ok, "precisa estar agarrando")
	a.aplicar_condicao(Ser.AGARRADO)
	a.mods_cena["agarrado_por"] = v
	var san := a.san
	c.dados.forcar([6, 6, 6, 6, 1])
	assert_true(c.usar_habilidade(v, "devorar_memoria", a).ok)
	assert_eq(a.san, san - 24)


func test_carnical_instinto_mortal_e_comando():
	var c := _combate()
	var cr := _ameaca("carnical_preto_da_morte")
	var alvo := _saco(2000)
	c.adicionar(cr)
	c.adicionar(alvo)
	assert_eq(c.aplicar_dano(cr, 100, "balistico"), 0, "imune a balístico")
	cr.pv = 150
	cr._atualizar_pv()
	c.acoes[cr] = {"padrao": 1, "movimento": 1}
	var res := c.agredir(cr, alvo, cr.ataques[0])
	assert_eq(res.ataques_extras.size(), 2, "machucado: uma garra a mais")
	var a := _agente()
	c.adicionar(a)
	c.dados.forcar([1])
	assert_true(c.usar_habilidade(cr, "comando", a).ok)
	assert_true(a.tem(Ser.PASMO))


func test_tita_sede_de_sangue_e_estracalhar():
	var c := _combate()
	var t := _ameaca("tita_de_sangue")
	var alvo := _saco(1000)
	alvo.pv = 400
	alvo._atualizar_pv()
	c.dados.forcar([15, 15, 15, 15, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	var r := c.atacar(t, alvo, t.ataques[1])
	assert_eq(r.dano, 14 + 4 + 14, "mordida + Sede de Sangue (machucado) + Estraçalhar")
	assert_true(alvo.tem(Ser.SANGRANDO))
	var pv := alvo.pv
	c.dados.forcar([1, 3])
	c._inicio_de_turno_ameacas(alvo)
	assert_eq(alvo.pv, pv - 3, "sangrando: falhou em Vigor, perde 1d6 PV")


func test_mumia_faixas_da_permanencia_e_drenagem():
	var c := _combate()
	var m := _ameaca("mumia_xipofaga")
	c.adicionar(m)
	c.aplicar_dano(m, 1000, "corte")
	assert_eq(m.pv, 0)
	assert_false(m.esta_fora_de_combate(), "a 0 PV, ainda age")
	c._inicio_de_turno_ameacas(m)
	c._fim_de_turno(m)
	assert_true(m.tem(Ser.MORTO), "não se recuperou até o fim do turno seguinte")
	var m2 := _ameaca("mumia_xipofaga")
	var alvo := _saco(500)
	c.adicionar(m2)
	c.adicionar(alvo)
	m2.pv = 300
	alvo.aplicar_condicao(Ser.AGARRADO)
	alvo.mods_cena["agarrado_por"] = m2
	m2.mods_cena["agarrando"] = [alvo]
	c.dados.forcar([1, 1, 1, 1])
	c._inicio_de_turno_ameacas(alvo)
	assert_eq(alvo.pv, 500 - 34)
	assert_eq(m2.pv, 334, "recupera o que drenou")


func test_enxame():
	var c := _combate()
	var ab := _ameaca("enxame_de_abelhas")
	var a := _agente()
	c.adicionar(ab)
	c.adicionar(a)
	var pv := a.pv
	c.dados.forcar([3, 3, 1, 1])
	c._fim_de_turno(ab)
	assert_eq(a.pv, pv - 6)
	assert_true(a.tem(Ser.ENJOADO), "zumbido nauseante")
	var ratos := _ameaca("enxame_de_ratos")
	c.dados.forcar([15, 3])
	c.atacar(a, ratos, rs.arma("desarmado"))
	assert_eq(ratos.pv, 15 - 2, "metade do dano de armas")


func test_assassino_evasao_e_assassinar():
	var c := _combate()
	var ass := _ameaca("assassino")
	ass.lado = "agentes"
	var el := _ameaca("policial_de_elite")
	c.adicionar(ass)
	c.adicionar(el)
	c.dados.forcar([6, 6, 6, 6, 6, 6, 6, 6, 15, 15, 15, 15])
	c.usar_habilidade(el, "lanca_granadas", ass)
	assert_eq(ass.pv, ass.pv_maximo, "Evasão: passou em Reflexos, nenhum dano")
	var c2 := _combate()
	var assassino := _ameaca("assassino")
	var alvo := _saco()
	alvo.aplicar_condicao(Ser.DESPREVENIDO)
	assert_true(c2.usar_habilidade(assassino, "assassinar", alvo).ok)
	c2.dados.forcar([15, 15, 15, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	var r := c2.atacar(assassino, alvo, assassino.ataques[0])
	assert_eq(r.dano, 12 + 8, "furtivo dobrado: 8d6")


func test_comandante_ordens_e_sadismo():
	var c := _combate()
	var cmd := _ameaca("comandante_mercenario")
	var sold := _ameaca("soldado_de_aluguel")
	c.adicionar(cmd)
	c.adicionar(sold)
	var fort := sold.dados_da_pericia("fortitude")
	assert_true(c.usar_habilidade(cmd, "ordens").ok)
	assert_eq(sold.dados_da_pericia("fortitude"), fort + 1)
	assert_false(c.usar_habilidade(cmd, "ordens").ok, "uma vez por cena")
	var alvo := _saco()
	c.aplicar_dano(alvo, 5, "corte", 0, cmd)
	assert_true(cmd.mods_cena.get("sadismo", false))
	c.atacar(cmd, alvo, cmd.ataques[0])
	assert_false(cmd.mods_cena.has("sadismo"), "o bônus vale para o próximo ataque")


func test_lider_de_culto_conjura_area_e_sustenta_de_graca():
	var c := _combate()
	c.grade = Grade.new(14, 9)
	var lider := _ameaca("lider_de_culto")
	var a1 := _agente()
	var a2 := _agente()
	c.adicionar(lider)
	c.adicionar(a1)
	c.adicionar(a2)
	c.grade.colocar(lider, Vector2i(0, 4))
	c.grade.colocar(a1, Vector2i(6, 4))
	c.grade.colocar(a2, Vector2i(7, 4))
	var r := c.conjurar_ameaca(lider, "poeira_da_podridao", a1)
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(r.alvos.size(), 2)
	assert_eq(c.zonas().size(), 1)
	c._manter_sustentados(lider)
	assert_eq(c.zonas().size(), 1, "cultistas sustentam sem PE")


func test_surgimentos_respeitam_o_nex_do_grupo():
	var m := Missao.nova(42)
	assert_eq(m._vd_minimo({"ameacas": ["mumia_xipofaga"]}), 240)
	for e in m.encontros_para_surgir(3, m.agentes):
		assert_lte(m._vd_minimo(e), 30, "grupo de NEX 15 somado: nada acima de VD 30 (%s)" % e.id)
	for a in m.agentes:
		a.nex = 50
	var ids: Array = m.encontros_para_surgir(3, m.agentes).map(func(e): return e.id)
	assert_true("massacre" in ids, "com NEX alto, o titã pode aparecer")


func test_arena_com_ameacas_fortes():
	var m := Missao.nova(42)
	for a in m.agentes:
		a.nex = 99
		a.recalcular_maximos(true)
		m.posicoes[a] = m.posicao(m.agente_atual())
	m._preparar_encontro(m.posicao(m.agente_atual()), "alto_culto", false)
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.config = m.encontro_pendente
	arena.autoplay = true
	arena.semente = 7
	add_child_autofree(arena)
	assert_true(arena.combate.encerrado)
