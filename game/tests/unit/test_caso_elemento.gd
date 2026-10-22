extends GutTest
## Caso e dedução (docs/52): elemento do caso, covil e encontros do elemento, relatório em lote.


func _agente(nex: int) -> Agente:
	var a := Agente.criar(RulesetOp2022.carregar_padrao(), "A", "combatente", {"agi": 1, "for": 2, "int": 1, "pre": 1, "vig": 2}, {})
	a.nex = nex
	return a


func test_elemento_varia_e_o_briefing_so_da_os_sintomas():
	var vistos := {}
	var nomes: Array = DadosJogo.ler("casos").elementos.values().map(func(e): return String(e.nome))
	for semente in 40:
		var c := Caso.gerar(Dados.new(semente))
		vistos[c.elemento] = true
		for nome in nomes:
			assert_false(c.resumo.contains(nome), "o briefing não diz o elemento (%s)" % nome)
		assert_string_contains(c.resumo, String(DadosJogo.ler("casos").elementos[c.elemento].sintomas))
		assert_false(c.elemento_confirmado())
	assert_gte(vistos.size(), 3, "os casos variam de elemento")


func test_covil_segue_o_elemento_do_caso():
	var grupo := [_agente(5), _agente(5), _agente(5)]
	assert_eq(Missao.covil_para(grupo, "sangue").id, "covil")
	assert_eq(Missao.covil_para(grupo, "morte").id, "casa_parada")
	assert_eq(Missao.covil_para(grupo, "conhecimento").id, "arquivo_dourado")
	assert_eq(Missao.covil_para(grupo, "energia").id, "subestacao")
	assert_eq(Missao.covil_para(grupo).id, "covil", "sem elemento, como antes")
	for a in grupo:
		a.nex = 35
	assert_eq(Missao.covil_para(grupo, "morte").id, "casa_parada", "sem covil de Morte mais forte, fica o de Morte")


func test_encontros_do_mapa_e_surgimentos_seguem_o_elemento():
	for semente in [3, 11, 42]:
		var m := Missao.nova(semente)
		for h in m.mapa.celulas:
			var c := m.mapa.conteudo(h)
			if String(c.get("tipo", "")) == "encontro":
				var el := m.elemento_do_encontro(m._encontro(String(c.encontro)))
				assert_true(el == "" or el == m.caso.elemento, "semente %d: %s é do caso (%s)" % [semente, c.encontro, m.caso.elemento])
		for a in m.agentes:
			a.nex = 50
		for e in m.encontros_para_surgir(3, m.agentes):
			assert_true(m.elemento_do_encontro(e) in ["", "medo", m.caso.elemento], e.id)


func test_ciclo_dos_elementos_no_texto_do_covil():
	var m := Missao.nova(3)
	assert_eq(m.elemento_opressor("sangue"), "morte", "p.98: Morte oprime Sangue")
	assert_eq(m.elemento_opressor("morte"), "energia")
	assert_eq(m.elemento_opressor("energia"), "conhecimento")
	assert_eq(m.elemento_opressor("conhecimento"), "sangue")
	m.caso.elemento = "morte"
	assert_string_contains(m.linha_do_elemento(), "rituais de Energia têm vantagem")


func test_ficha_monta_o_relatorio():
	var caso := Caso.gerar(Dados.new(3))
	for pid in Caso.PERGUNTAS_BASE:
		caso.registrar_pista("{indicio}", pid, "t")
	var enviados := []
	var f := PainelDeducao.abrir(self, caso, "quem", func(_q, _c): pass, func(r): enviados.append(r))
	assert_true(f.em_lote())
	assert_true(f._btn_relatorio.disabled, "falta escolher o suspeito de cada pergunta")
	f.escolher(caso.sujeito.id)
	f.mostrar("oque")
	f.escolher(caso.acao.id)
	assert_true(f._btn_relatorio.disabled)
	f.mostrar("onde")
	f.escolher(caso.local.id)
	assert_false(f._btn_relatorio.disabled, "com os três, o relatório sai")
	assert_string_contains(f._barra_relatorio.text, "Quem: ")
	f.relatar()
	assert_eq(enviados, [{"quem": caso.sujeito.id, "oque": caso.acao.id, "onde": caso.local.id}])


func test_piloto_relata_quando_cada_pergunta_tem_um_suspeito():
	var caso := Caso.gerar(Dados.new(7))
	for pid in Caso.PERGUNTAS_BASE:
		caso.registrar_pista("{indicio}", pid, "t")
	assert_true(PilotoMissao.lote_para_relatar(caso, false).is_empty(), "uma pista não basta")
	var arriscado := PilotoMissao.lote_para_relatar(caso, true)
	assert_eq(arriscado.size(), 3, "arriscando, monta uma combinação")
	for pid in Caso.PERGUNTAS_BASE:
		caso.registrar_pista("{indicio}", pid, "t")
	var lote := PilotoMissao.lote_para_relatar(caso, false)
	assert_eq(lote, {"quem": caso.sujeito.id, "oque": caso.acao.id, "onde": caso.local.id})
	assert_true(caso.relatar(lote).acertou)
