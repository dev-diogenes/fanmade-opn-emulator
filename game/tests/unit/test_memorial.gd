extends GutTest
## Gente que se lembra (docs/59): os adereços dos agentes (apelido, cidade natal, objeto
## pessoal), a parede de memória com a despedida e a ajuda dos colegas nos eventos do mapa.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _por_nome(c: Carreira, nome: String) -> Agente:
	for a in c.roster:
		if a.nome == nome:
			return a
	return null


func test_agentes_ganham_apelido_cidade_e_objeto():
	var c := Carreira.nova(rs)
	var d := DadosJogo.ler("pessoais")
	for a in c.roster:
		assert_true(a.apelido in d.apelidos, a.nome)
		assert_true(a.cidade in d.cidades, a.nome)
		assert_true(a.objeto in d.objetos, a.nome)
	var cleber := _por_nome(c, "Cléber")
	assert_eq(Carreira.nova(rs).roster[0].apelido, c.roster[0].apelido, "pelo nome: o mesmo em toda máquina")
	assert_eq(cleber.nome_com_apelido(), "Cléber “%s”" % cleber.apelido)
	var volta := Carreira.de_dicionario(JSON.parse_string(JSON.stringify(c.para_dicionario())), rs)
	assert_eq(_por_nome(volta, "Cléber").cidade, cleber.cidade, "vai no save")


func test_save_antigo_ganha_os_aderecos():
	var c := Carreira.nova(rs)
	var dic: Dictionary = JSON.parse_string(JSON.stringify(c.para_dicionario()))
	for ad in dic.roster:
		ad.erase("apelido")
		ad.erase("cidade")
		ad.erase("objeto")
	var volta := Carreira.de_dicionario(dic, rs)
	assert_eq(_por_nome(volta, "Rita").objeto, _por_nome(c, "Rita").objeto)


func test_memorial_guarda_o_bastante_para_a_parede():
	var c := Carreira.nova(rs)
	c.opcoes.modo_morte = "hardcore"
	var m := c.iniciar_missao(c.roster.duplicate(), 7)
	var rita := _por_nome(c, "Rita")
	m._preparar_encontro(m.posicao(rita), "emboscada", false)
	m.historico.append("[color=#e0574a]Rita cai diante do [b]cultista[/b].[/color]")
	rita.condicoes[Ser.MORTO] = true
	m.concluir_encontro("agentes")
	m._encerrar(false)
	c.encerrar_missao()
	var e: Dictionary = c.memorial[0]
	assert_eq(e.nome, "Rita")
	assert_eq(e.classe, "ocultista", "a foto")
	assert_eq(e.apelido, rita.apelido)
	assert_eq(e.lugar, m.caso.local.nome, "o lugar do caso")
	assert_ne(String(e.data), "")
	assert_false(String(e.ultimo).contains("["), "o último registro sem as marcas de cor")
	assert_string_contains(String(e.ultimo), "Rita")


func test_cartao_do_memorial():
	var e := {"nome": "Tião", "apelido": "Prego", "classe": "combatente", "aparencia": "", "tom": 0, "nex": 15,
		"patente": "Recruta", "cidade": "Mossoró (RN)", "objeto": "um isqueiro que nunca acende", "missao": 3,
		"lugar": "a escola rural fechada", "data": "2026-10-22", "causa": "morto em missão", "ultimo": "Tião segura a porta."}
	var cartao := Memorial.cartao(e)
	add_child_autofree(cartao)
	var textos: Array = cartao.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("Tião “Prego”"))
	assert_true(textos.has("Morto em missão · 22/10/2026"))
	assert_true(textos.has("Levava um isqueiro que nunca acende."))
	assert_true(textos.has("Último registro: «Tião segura a porta.»"))
	var foto: FotoAgente = cartao.find_children("*", "FotoAgente", true, false)[0]
	assert_true(foto.luto, "foto de luto, com a fita")
	assert_eq(cartao.find_children("*", "Vela", true, false).size(), 1, "e a vela acesa")
	assert_eq(Memorial.data_br("2026-10-22"), "22/10/2026")
	var vazia := Memorial.parede([])
	add_child_autofree(vazia)
	assert_true(vazia.find_children("*", "Label", true, false).any(func(l): return l.text.contains("Ninguém na parede")))


func test_colegas_no_mesmo_hex_ajudam_o_evento():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	var h := m.posicao(a)
	for x in m.agentes:
		m.posicoes[x] = h
	m.evento_pendente = {"agente": a, "evento": DadosJogo.ler("eventos").eventos[0], "hex": h}
	assert_eq(m.ajudantes_do_evento().size(), m.agentes.size() - 1, "quem está no hex ajuda")
	var longe: Agente = m.ajudantes_do_evento()[0]
	m.posicoes[longe] = h + Vector2i(9, 9)
	assert_false(longe in m.ajudantes_do_evento(), "longe, não ajuda")
	m.evento_pendente = {}


func test_ajuda_soma_por_quem_passa():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	var h := m.posicao(a)
	for x in m.agentes:
		m.posicoes[x] = h
	m.evento_pendente = {"agente": a, "evento": DadosJogo.ler("eventos").eventos[0], "hex": h}
	var ajudantes := m.ajudantes_do_evento()
	var vinte: Array = []
	vinte.resize(40)
	vinte.fill(20)
	m.dados.forcar(vinte)   # todo ajudante tira 20: passa a DT 10 com folga
	var antes := m.historico.size()
	var bonus := m._ajudar_no_evento(a, "percepcao")
	assert_true(bonus >= ajudantes.size() * 2, "+1, e +1 a cada 10 acima da DT (p.86)")
	assert_true(m.historico.slice(antes).any(func(l): return l.contains("ajuda %s" % a.nome)), "a ajuda vai para o registro")
	m.evento_pendente = {}
