extends GutTest
## Fase 6: missões da comunidade (formato mission.json v1) e a lógica do editor.

const EXEMPLO := "res://data/missoes/a_capela_do_morro.json"

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _exemplo() -> Dictionary:
	return MissaoComunidade.ler_arquivo(EXEMPLO, rs).definicao


func test_exemplo_e_valido():
	var lido := MissaoComunidade.ler_arquivo(EXEMPLO, rs)
	assert_eq(lido.erros, [] as Array[String])
	var ids: Array = MissaoComunidade.listar(rs).map(func(x): return x.definicao.get("id", ""))
	assert_true("a_capela_do_morro" in ids, "a pasta do jogo é lida")


func test_mapa_desenhado():
	var mapa := MissaoComunidade.montar_mapa(_exemplo())
	assert_eq(mapa.colunas, 12)
	assert_eq(mapa.linhas, 8)
	assert_eq(mapa.terreno(Hex.de_offset(2, 5)), "agua")
	assert_eq(mapa.encontrar("inicio"), Hex.de_offset(0, 3))
	assert_eq(mapa.conteudo(Hex.de_offset(2, 2)).nome, "Santa Luzia do Morro")
	assert_eq(mapa.conteudo(Hex.de_offset(5, 3)).encontro, "procissao")


func test_mapa_por_semente():
	var d := {"formato": "opn-missao", "versao": 1, "titulo": "Gerada", "mapa": {"semente": 42}}
	assert_eq(MissaoComunidade.validar(d, rs), [] as Array[String])
	var mapa := MissaoComunidade.montar_mapa(d)
	var com_conteudo := 0
	for h in mapa.celulas:
		if not mapa.conteudo(h).is_empty():
			com_conteudo += 1
	assert_eq(com_conteudo, 2, "sem conteúdo procedural: só início e objetivo")
	d.mapa.conteudo_procedural = true
	mapa = MissaoComunidade.montar_mapa(d)
	com_conteudo = 0
	for h in mapa.celulas:
		if not mapa.conteudo(h).is_empty():
			com_conteudo += 1
	assert_gt(com_conteudo, 5)


func test_erros_de_validacao():
	var d := _exemplo()
	d.formato = "outro"
	d.mapa.terreno[0] = "fffxcccmmfff"
	var erros := MissaoComunidade.validar(d, rs)
	assert_true(erros.any(func(e): return "formato" in e))
	assert_true(erros.any(func(e): return "\"x\"" in e))
	d = _exemplo()
	d.mapa.conteudo.append({"em": [4, 4], "tipo": "encontro", "encontro": "nao_existe"})
	d.encontros[0].ameacas.append("fantasma")
	d.eventos[0].pericia = "danca"
	d.mapa.inicio = [2, 5]   # água
	erros = MissaoComunidade.validar(d, rs)
	assert_true(erros.any(func(e): return "nao_existe" in e))
	assert_true(erros.any(func(e): return "fantasma" in e))
	assert_true(erros.any(func(e): return "danca" in e))
	assert_true(erros.any(func(e): return "água" in e))


func test_sem_caminho_ate_o_objetivo():
	var d := {"formato": "opn-missao", "versao": 1, "titulo": "Ilha",
		"mapa": {"terreno": ["ccacc", "ccacc", "ccacc"], "inicio": [0, 1], "objetivo": [4, 1]}}
	assert_true(MissaoComunidade.validar(d, rs).any(func(e): return "caminho" in e))


func test_missao_usa_o_conteudo_proprio():
	var m := MissaoComunidade.criar_missao(_exemplo(), rs, [], {}, 5)
	assert_eq(m.posicao(m.agente_atual()), Hex.de_offset(0, 3))
	assert_eq(m.caso.sujeito.chefe_titulo, "o Sineiro")
	assert_eq(m.membrana.valor, 90)
	assert_false(m._evento("badalada").is_empty())
	assert_eq(m._encontro("procissao").nome, "Procissão da madrugada")
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	assert_eq(m.encontro_pendente.nome, "A Torre da Capela")
	assert_eq(m.encontro_pendente.ameacas[0].nome, "O Sineiro")


func test_missao_da_comunidade_joga_ate_o_fim_e_salva():
	var m := MissaoComunidade.criar_missao(_exemplo(), rs, [], {}, 11)
	var copia := Missao.de_dicionario(rs, JSON.parse_string(JSON.stringify(m.para_dicionario())), _por_id(m))
	assert_eq(copia.extras.titulo, "A Capela do Morro", "o conteúdo próprio vai no save")
	assert_false(copia._encontro("procissao").is_empty())
	var rel := PilotoMissao.jogar(m)
	assert_eq(rel.travou, "")
	assert_true(rel.encerrada)


func _por_id(m: Missao) -> Dictionary:
	var d := {}
	for i in m.agentes.size():
		m.agentes[i].id = "a%d" % i
		d[m.agentes[i].id] = m.agentes[i]
	return d


func test_surgimentos_proprios_ou_nenhum():
	var d := _exemplo()
	d.opcoes.surgimentos = "proprios"
	var m := MissaoComunidade.criar_missao(d, rs, [], {}, 3)
	var ids: Array = m.encontros_para_surgir(3, m.agentes).map(func(e): return e.id)
	assert_eq(ids, ["procissao"])
	m.extras.surgimentos = "nenhum"
	assert_true(m.encontros_para_surgir(3, m.agentes).is_empty())


func test_carreira_inicia_missao_da_comunidade():
	var car := Carreira.nova(rs)
	var m := car.iniciar_missao_comunidade(car.roster.slice(0, 3), _exemplo(), 9)
	assert_not_null(m)
	assert_eq(m.extras.id, "a_capela_do_morro")
	car.missao = null
	var ruim := _exemplo()
	ruim.titulo = ""
	assert_null(car.iniciar_missao_comunidade(car.roster.slice(0, 3), ruim, 9), "missão inválida não começa")


# --- Editor -------------------------------------------------------------------------

func test_editor_pinta_e_coloca():
	var e := EditorMissao.nova(8, 5)
	assert_eq(e.colunas(), 8)
	assert_eq(e.linhas(), 5)
	e.pintar(3, 2, "floresta")
	assert_eq(e.terreno_em(3, 2), "floresta")
	e.colocar(4, 1, {"tipo": "vila", "nome": "Vila Nova"})
	assert_eq(e.conteudo_em(4, 1).nome, "Vila Nova")
	e.colocar(4, 1, {"tipo": "encontro", "encontro": "emboscada"})
	assert_eq(e.conteudo_em(4, 1).tipo, "encontro", "um conteúdo por hex")
	e.colocar(1, 1, {"tipo": "inicio"})
	assert_eq(e.conteudo_em(1, 1).tipo, "inicio")
	e.apagar(4, 1)
	assert_true(e.conteudo_em(4, 1).is_empty())
	assert_eq(e.validar(rs), [] as Array[String])


func test_editor_eventos_redimensionar_e_gerar():
	var e := EditorMissao.nova(10, 6)
	var id := e.adicionar_evento({"titulo": "Luz na Janela", "texto": "Uma luz acende e apaga.", "pericia": "percepcao", "dt": 15,
		"sucesso": {"texto": "Você vê quem está lá.", "efeitos": [{"tipo": "revelar_raio", "valor": 3}]},
		"falha": {"texto": "Nada.", "efeitos": []}})
	assert_eq(id, "luz_na_janela")
	assert_eq(e.adicionar_evento({"titulo": "Luz na Janela"}), "luz_na_janela_2", "ids não se repetem")
	e.remover_evento("luz_na_janela_2")
	e.colocar(5, 3, {"tipo": "evento", "evento": id})
	assert_eq(e.validar(rs), [] as Array[String])
	e.remover_evento(id)
	assert_true(e.conteudo_em(5, 3).is_empty(), "remover o evento tira ele do mapa")
	e.colocar(9, 5, {"tipo": "vila"})
	e.redimensionar(6, 4)
	assert_eq(e.colunas(), 6)
	assert_true(e.conteudo_em(9, 5).is_empty())
	assert_eq(int(e.definicao.mapa.objetivo[0]), 5, "o objetivo volta para dentro do mapa")
	e.gerar_terreno(7)
	assert_ne(e.terreno_em(int(e.definicao.mapa.inicio[0]), int(e.definicao.mapa.inicio[1])), "agua")


func test_editor_abre_missao_por_semente():
	var e := EditorMissao.de_definicao({"formato": "opn-missao", "versao": 1, "titulo": "X", "mapa": {"semente": 5}})
	assert_true(e.definicao.mapa.has("terreno"))
	assert_false(e.definicao.mapa.has("semente"))
	assert_eq(e.validar(rs), [] as Array[String])


func test_ids_de_titulos():
	assert_eq(MissaoComunidade.id_de("A Capela do Morro!"), "a_capela_do_morro")
	assert_eq(MissaoComunidade.id_de("  Ação Noturna  "), "acao_noturna")
	assert_eq(MissaoComunidade.id_de("???"), "missao")
