extends GutTest
## O covil e o chefe do caso (docs/58): o Enigma de Medo sorteado, a regeneração até ele ser
## resolvido, a virada na metade dos PV, a arena vestida pelo lugar e o cartão do chefe.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func test_enigma_sorteado_pela_semente():
	var m := Missao.nova(42)
	var en := m.enigma_do_chefe()
	assert_false(en.is_empty())
	var ids: Array = DadosJogo.ler("casos").enigmas_do_chefe.map(func(e): return e.id)
	assert_true(en.id in ids)
	assert_eq(Missao.nova(42).enigma_do_chefe().id, en.id, "a mesma semente, o mesmo enigma (online)")
	var vistos := {}
	for s in 40:
		var outro := Missao.nova(s).enigma_do_chefe()
		vistos[outro.id] = true
		assert_false(String(outro.texto).contains("{local}"), "o lugar entra no texto")
	assert_gt(vistos.size(), 2, "casos diferentes, enigmas diferentes")


func _covil(m: Missao) -> Dictionary:
	m._preparar_encontro(m.posicao(m.agentes[0]), "covil", true)   # o grupo todo entra no covil
	return m.encontro_pendente


func test_covil_traz_o_chefe_com_enigma_regeneracao_e_virada():
	var m := Missao.nova(42)
	var cfg := _covil(m)
	var chefe: Dictionary = cfg.ameacas[0]
	assert_true(chefe.ficha.has("enigma"))
	assert_eq(String(chefe.ficha.enigma.texto), String(m.enigma_do_chefe().texto))
	var habs: Array = chefe.ficha.habilidades.map(func(h): return h.id)
	assert_true("cura_acelerada" in habs, "ele se refaz")
	assert_true("virada" in habs, "e vira na metade dos PV")
	assert_eq(cfg.local, m.caso.local.id, "o covil é o lugar do caso")
	assert_eq(cfg.elemento_caso, "", "sem o elemento confirmado, o cartão mostra ?")
	m.caso.pergunta("oque").respondida = true
	assert_eq(_covil(m).elemento_caso, m.caso.elemento)
	assert_false(DadosJogo.ameaca(rs, String(chefe.get("id", "horror_carmesim"))).ficha.has("enigma"), "os dados do chefe não mudam")


func _combate_do_covil(m: Missao) -> Combate:
	var montado := MontagemCombate.montar(rs, _covil(m), Dados.new(7), m.membrana)
	var c: Combate = montado.combate
	c.iniciar()
	c.proximo_turno()
	return c


func _chefe(c: Combate) -> Ameaca:
	for s in c.participantes:
		if s is Ameaca and (s as Ameaca).tem_hab("virada"):
			return s
	return null


func test_resolver_o_enigma_para_a_regeneracao():
	var m := Missao.nova(42)
	var c := _combate_do_covil(m)
	var chefe := _chefe(c)
	assert_not_null(chefe)
	var cura := int(DadosJogo.ler("casos").enigma_do_chefe_regras.cura)
	chefe.pv -= 10
	c._inicio_de_turno_ameacas(chefe)
	assert_eq(chefe.pv, chefe.pv_maximo - 10 + cura, "enquanto o enigma está de pé, ele se refaz")
	c._resolver_enigma(chefe)
	assert_false(chefe.tem_hab("cura_acelerada"), "resolvido: ele para de se refazer")
	var depois := chefe.pv
	c._inicio_de_turno_ameacas(chefe)
	assert_eq(chefe.pv, depois)


func test_virada_na_metade_dos_pv():
	var m := Missao.nova(42)
	var c := _combate_do_covil(m)
	var chefe := _chefe(c)
	var agentes := c.participantes.filter(func(s): return s is Agente)
	var fragil: Agente = agentes[0]
	fragil.san = 1
	var antes := c.participantes.size()
	var viradas: Array = []
	c.virada.connect(func(s, t): viradas.append(t))
	c.aplicar_dano(chefe, chefe.pv - (chefe.pv_maximo / 2 + 1), "corte")
	assert_eq(viradas.size(), 0, "acima da metade, nada")
	c.aplicar_dano(chefe, 2, "corte")
	assert_eq(viradas.size(), 1, "na metade dos PV, a virada")
	assert_true(chefe.mods_cena.get("virou", false))
	assert_eq(c.participantes.size(), antes + 1, "a escolta surge")
	assert_true(Grade.distancia(c.grade.posicao(chefe), c.grade.posicao(fragil)) <= 1, "volta ao lado de quem está mais abalado")
	c.aplicar_dano(chefe, 1, "corte")
	assert_eq(viradas.size(), 1, "vira uma vez só")


func test_virada_muda_o_elemento_pelo_que_o_grupo_fez():
	var m := Missao.nova(42)
	var c := _combate_do_covil(m)
	assert_eq(c.elemento_da_virada(), "", "luta curta, ninguém caído: não muda")
	c.rodada = 4
	assert_eq(c.elemento_da_virada(), "morte", "a luta se arrastou: vira Morte")
	var a: Agente = c.participantes.filter(func(s): return s is Agente)[0]
	a.condicoes[Ser.MORRENDO] = true
	assert_eq(c.elemento_da_virada(), "sangue", "derrubou alguém: vira Sangue")
	var chefe := _chefe(c)
	c.aplicar_dano(chefe, chefe.pv - chefe.pv_maximo / 2, "corte")
	assert_eq(chefe.elemento, "sangue")
	assert_eq(chefe.vulnerabilidades, ["morte"], "a Morte oprime o Sangue (p.128)")
	assert_eq(c.opressor_de("energia"), "conhecimento")


func test_arena_do_covil_pelo_lugar():
	var g := Grade.new(MontagemCombate.COLUNAS, MontagemCombate.LINHAS)
	MontagemCombate._terreno(g, Dados.new(3), "campo", "escola")
	var coberturas := g.terreno.values().filter(func(t): return t == Grade.COBERTURA).size()
	assert_gt(coberturas, 4, "a escola é cheia de carteiras")
	var g2 := Grade.new(MontagemCombate.COLUNAS, MontagemCombate.LINHAS)
	MontagemCombate._terreno(g2, Dados.new(3), "campo", "frigorifico")
	assert_true(g2.terreno.values().has(Grade.PAREDE), "o frigorífico tem câmaras")
	for nome in ["banco", "carcaca", "maca", "carteira", "fardo", "lapide"]:
		var p := Pecas.peca_covil(nome)
		assert_not_null(p, nome)
		p.free()
	for local in DadosJogo.ler("casos").locais:
		assert_true(Tabuleiro3D.ESTILO_COVIL.has(local.id), "cada lugar tem seu covil: %s" % local.id)


func test_cartao_do_chefe():
	var c := CartaoChefe.apresentar(self, {"local": "a escola rural fechada", "nome": "Horror Carmesim", "elemento": "",
		"fraqueza": "", "enigma": "Ele já foi alguém."})
	var textos: Array = c.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("COVIL · A ESCOLA RURAL FECHADA"))
	assert_true(textos.has("ELEMENTO ?"), "sem confirmação, o elemento fica em aberto")
	assert_true(TourGuiado.papel_aberto(get_tree()), "o tour do combate espera a apresentação")
	c.free()
	var v := CartaoChefe.anunciar_virada(self, "Ele volta.", "morte")
	assert_true(v.find_children("*", "Label", true, false).any(func(l): return l.text == "VIRADA"))
	v.free()
