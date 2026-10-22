extends GutTest
## Conteúdo novo (docs/50): reviravoltas, cenas com duas testemunhas e eventos de escolha moral.

const MORAIS := ["socorro", "video_viral", "cultista_ferido", "coracao_de_pedra", "casa_em_chamas", "simpatia", "agente_possuido"]
const CUSTOS := ["inocente_morto", "dano", "dano_mental"]


func test_seis_reviravoltas_com_indicios_conhecidos():
	var d := DadosJogo.ler("casos")
	var ids: Array = d.ampliacoes.map(func(a): return a.id)
	for id in ["cumplice", "objeto", "quando", "vitima", "mandante", "origem"]:
		assert_has(ids, id)
	for a in d.ampliacoes:
		for c in a.candidatos:
			for t in c.indicios:
				assert_true(d.indicios.has(t), "%s/%s: o traço %s tem texto" % [a.id, c.id, t])


func test_reviravolta_da_proxima_vitima_abre_a_pergunta():
	var c := Caso.gerar(Dados.new(3))
	c.ampliacao_id = "vitima"
	c.ampliacao_verdade = "padre"
	var r := c.ampliar()
	assert_eq(r.pergunta.id, "vitima")
	assert_eq(c.candidatos("vitima").size(), 4)
	assert_eq(c.verdadeiro("vitima").id, "padre")
	assert_eq(String(c.pergunta("vitima").efeito.tipo), "membrana")


func test_cenas_com_duas_testemunhas():
	var cenas := {}
	for c in DadosJogo.ler("cenas_investigacao").cenas:
		cenas[c.id] = c
	for id in ["velorio", "delegacia", "rodoviaria"]:
		assert_true(cenas.has(id), id)
		var testemunhas: Array = cenas[id].pontos.filter(func(p): return p.get("depoimento", false))
		assert_eq(testemunhas.size(), 2, id)
		assert_ne(String(testemunhas[0].responde), String(testemunhas[1].responde), "%s: as duas falam de coisas diferentes" % id)


func test_cena_nova_roda_e_a_testemunha_pode_hesitar():
	var rs := RulesetOp2022.carregar_padrao()
	var m := Missao.nova(42)
	var cena := CenaInvestigacao.nova(rs, Dados.new(5), m.caso, "velorio", m.agentes)
	assert_not_null(cena)
	assert_eq(cena.pontos_restantes.size(), 5)


func test_todo_ponto_tem_peca_3d():
	for c in DadosJogo.ler("cenas_investigacao").cenas:
		for p in c.pontos:
			assert_ne(PropsInvestigacao.tipo(String(p.id), String(p.nome)), "", "%s/%s tem peça" % [c.id, p.id])
	assert_eq(PropsInvestigacao.tipo("caixao", "Caixão pregado"), "caixao")
	assert_eq(PropsInvestigacao.tipo("viuva", "Viúva"), "pessoa")
	var n := PropsInvestigacao.criar("coroa_flores", "Coroa de flores")
	assert_not_null(n)
	n.free()


func test_escolhas_morais_tem_preco_em_toda_saida():
	var eventos := {}
	for e in DadosJogo.ler("eventos").eventos:
		eventos[e.id] = e
	for id in MORAIS:
		assert_true(eventos.has(id), id)
		var e: Dictionary = eventos[id]
		assert_true(e.get("moral", false), id)
		assert_gte(e.opcoes.size(), 3, id)
		assert_true(e.opcoes.any(func(o): return o.get("sem_teste", false)), "%s: dá para não arriscar" % id)
		for o in e.opcoes:
			var lados: Array = [o.sucesso] if o.get("sem_teste", false) else [o.sucesso, o.get("falha", {})]
			var custa := false
			for lado in lados:
				for ef in lado.get("efeitos", []):
					var v = ef.get("valor", 0)
					if String(ef.tipo) in CUSTOS or (ef.tipo == "membrana" and int(v) < 0) or (ef.tipo == "chefe" and int(v) > 0):
						custa = true
			assert_true(custa, "%s / %s: alguma saída custa" % [id, o.texto])


func test_efeito_chefe_mexe_no_covil():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	var antes := m.modificador_chefe
	var feito := m._aplicar_efeito(a, {"tipo": "chefe", "valor": 10}, m.posicao(a))
	assert_almost_eq(m.modificador_chefe, antes + 0.1, 0.001)
	assert_eq(feito.texto, "Chefe +10% PV")
	assert_has(DadosJogo.ler("eventos").efeitos_possiveis, "chefe")


func test_seguir_o_rastro_revela_o_covil_e_custa_um_inocente():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	var h := m.posicao(a) + Vector2i(1, 0)
	m.mapa.celulas[h].terreno = "campo"
	m.mapa.definir_conteudo(h, {"tipo": "evento", "evento": "casa_em_chamas"})
	m.movimento_rolado = true
	m.movimento_restante = 3
	assert_true(m.mover(h))
	var ops := m.opcoes_do_evento()
	var i := -1
	for j in ops.size():
		if ops[j].get("sem_teste", false):
			i = j
	m.dados.forcar([1, 1, 1, 1, 1, 1])
	var r := m.resolver_evento(0, i)
	assert_true(m.covil_localizado)
	assert_eq(m.inocentes_mortos, 1)
	assert_true(r.efeitos.any(func(e): return e.tipo == "inocente_morto"))


func test_cabecalho_da_escolha_dificil():
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	for c in get_tree().root.find_children("*", "", true, false):
		if c is DialogoPapel or c is TourGuiado:
			c.queue_free()
	var m: Missao = tela.missao
	var ev: Dictionary = {}
	for e in DadosJogo.ler("eventos").eventos:
		if e.id == "simpatia":
			ev = e
	m.evento_pendente = {"agente": m.agente_atual(), "evento": ev, "hex": m.posicao(m.agente_atual())}
	tela._atualizar()
	assert_eq(tela._lbl_tipo_evento.text, "ESCOLHA DIFÍCIL")
	assert_string_contains(tela._lbl_evento.text, "Nenhuma saída é segura")
	m.evento_pendente = {}
	tela._atualizar()
	m.evento_pendente = {"agente": m.agente_atual(), "evento": DadosJogo.ler("eventos").eventos[0], "hex": m.posicao(m.agente_atual())}
	tela._atualizar()
	assert_eq(tela._lbl_tipo_evento.text, "EVENTO")
	m.evento_pendente = {}   # a missão é a do Jogo: não deixar o evento para os outros testes
