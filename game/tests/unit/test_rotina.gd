extends GutTest
## A rotina da Ordem (docs/62): os sinais da rede com confiança e alarme falso (OR1), o ponto de
## encontro de fachada (OR3) e a varredura do covil (OR5).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func test_tres_sinais_um_de_cada_confianca():
	var lista := Sinais.gerar(1234)
	assert_eq(lista.size(), 3)
	var niveis: Array = lista.map(func(s): return s.confianca)
	niveis.sort()
	assert_eq(niveis, ["alta", "baixa", "media"])
	assert_eq(Sinais.gerar(1234), lista, "a mesma semente, os mesmos sinais")
	for s in lista:
		assert_ne(String(s.relato), "")
		assert_eq(s.elemento, Missao.nova(int(s.semente)).caso.elemento, "o relato é do elemento do caso que a missão vai gerar")


func test_confianca_decide_o_alarme_falso():
	var falsos_baixa := 0
	for i in 200:
		assert_false(Sinais.de(i, "alta").alarme_falso, "confiança alta nunca é alarme falso")
		if Sinais.de(i, "baixa").alarme_falso:
			falsos_baixa += 1
	assert_between(falsos_baixa, 50, 110, "confiança baixa: perto de 40% de alarmes falsos")


func test_fachada_com_senha():
	var f := Sinais.fachada(77)
	assert_ne(String(f.lugar), "")
	assert_ne(String(f.senha), "")
	assert_ne(String(f.resposta), "")
	assert_eq(Sinais.fachada(77), f)
	var script = load("res://scripts/ui/base_ordem.gd")
	var texto: String = script.briefing_procedural(Missao.previa(77), [], Sinais.de(77, "media"))
	assert_string_contains(texto, "Ponto de encontro:")
	assert_string_contains(texto, f.senha)
	assert_string_contains(texto, "Sinal:")


func _sinal_falso(semente: int) -> Dictionary:
	var s := Sinais.de(semente, "baixa")
	s.alarme_falso = true
	return s


func test_alarme_falso_tira_o_paranormal_e_se_revela_no_primeiro_lugar():
	var c := Carreira.nova(rs)
	var m := c.iniciar_missao(c.roster.duplicate(), 31, _sinal_falso(31))
	for h in m.mapa.celulas:
		var ct := m.mapa.conteudo(h)
		if String(ct.get("tipo", "")) == "encontro":
			assert_eq(m.elemento_do_encontro(m._encontro(String(ct.encontro))), "", "sem criatura no mapa")
	var h := m.mapa.encontrar("evento")
	m._entrar(m.agente_atual(), h)
	assert_eq(m.evento_pendente.evento.id, "alarme_falso")
	assert_string_contains(String(m.evento_pendente.evento.texto), String(m.sinal.explicacao))
	var nex_antes: int = m.agente_atual().nex
	m.resolver_evento(0, 0)
	assert_true(m.encerrada and m.vitoria)
	assert_true(m.alarme_confirmado)
	var r := c.encerrar_missao()
	assert_eq(int(r.pp), int(DadosJogo.ler("sinais").alarme_falso_pp), "pouco prestígio")
	assert_eq(int(r.agentes[0].nex), nex_antes, "o NEX não sobe: ninguém tocou o paranormal")


func test_alarme_falso_vai_no_save():
	var c := Carreira.nova(rs)
	var m := c.iniciar_missao(c.roster.duplicate(), 31, _sinal_falso(31))
	var por_id := {}
	for a in m.agentes_iniciais:
		por_id[a.id] = a
	var m2 := Missao.de_dicionario(rs, JSON.parse_string(JSON.stringify(m.para_dicionario())), por_id)
	assert_true(m2.alarme_falso)
	assert_eq(m2.sinal.explicacao, m.sinal.explicacao)


func _vencer_o_chefe(c: Carreira, semente: int, sinal: Dictionary = {}) -> Missao:
	var m := c.iniciar_missao(c.roster.duplicate(), semente, sinal)
	m._preparar_encontro(m.posicao(m.agentes[0]), "covil", true)
	m.concluir_encontro("agentes")
	return m


func _opcao(m: Missao, inicio: String) -> int:
	var ops := m.opcoes_do_evento()
	for i in ops.size():
		if String(ops[i].texto).begins_with(inicio):
			return i
	return -1


func test_o_chefe_cai_e_vem_a_varredura():
	var c := Carreira.nova(rs)
	var m := _vencer_o_chefe(c, 12)
	assert_false(m.encerrada, "antes de acabar, a varredura")
	assert_eq(m.evento_pendente.evento.id, "varredura")
	m.resolver_evento(0, _opcao(m, "Chamar a equipe"))
	assert_true(m.encerrada and m.vitoria)
	assert_eq(m.varredura, "equipe")
	var r := c.encerrar_missao()
	assert_true(r.detalhes_pp.has("Equipe de varredura: -2"))
	assert_false(c.eco_do_covil)


func test_varredura_malfeita_volta_na_missao_seguinte():
	var c := Carreira.nova(rs)
	var m := _vencer_o_chefe(c, 12)
	m.resolver_evento(0, _opcao(m, "Ir embora"))
	assert_eq(m.varredura, "rastro")
	c.encerrar_missao()
	assert_true(c.eco_do_covil)
	var volta := Carreira.de_dicionario(JSON.parse_string(JSON.stringify(c.para_dicionario())), rs)
	assert_true(volta.eco_do_covil, "vai no save")
	for a in c.roster:
		a.nex = 5   # sem as escolhas do NEX novo, para o grupo poder sair de novo no teste
	var m2 := c.iniciar_missao(c.roster.duplicate(), 13)
	assert_false(c.eco_do_covil, "o eco aparece uma vez")
	assert_eq(m2.membrana.valor, 95, "a Membrana já começa mais fina")
	var achou := false
	for h in m2.mapa.celulas:
		if String(m2.mapa.conteudo(h).get("evento", "")) == "eco_do_covil":
			achou = true
			assert_true(Hex.distancia(h, m2.mapa.encontrar("inicio")) in [2, 3], "perto do início")
	assert_true(achou, "o evento do que ficou no covil está no mapa")


func test_sinal_fraco_e_real_rende_mais():
	var c := Carreira.nova(rs)
	var s := Sinais.de(12, "baixa")
	s.alarme_falso = false
	var m := _vencer_o_chefe(c, 12, s)
	m.resolver_evento(0, _opcao(m, "Chamar a equipe"))
	var r := c.encerrar_missao()
	assert_true(r.detalhes_pp.has("Sinal de confiança baixa, e era real: +2"))


func test_sinais_com_relatos_diferentes_e_previa_com_sintomas():
	for base in [1, 2, 3, 4, 5, 1234]:
		var relatos: Array = Sinais.gerar(base).map(func(s): return s.relato)
		assert_eq(relatos.size(), 3)
		assert_ne(relatos[0], relatos[1])
		assert_ne(relatos[1], relatos[2])
		assert_ne(relatos[0], relatos[2])
	assert_false(String(Missao.previa(77).sinais).contains("{"), "a prévia traz os sintomas, não o marcador")


func test_a_pesquisa_desmascara_o_alarme_falso():
	var c := Carreira.nova(rs)
	var m := c.iniciar_missao(c.roster.duplicate(), 31, _sinal_falso(31))
	var r := m.ligar_pesquisa()
	assert_true(r.ok)
	assert_true(m.acao_usada, "custa a ação, como a orientação")
	assert_eq(m.evento_pendente.evento.id, "alarme_falso")
