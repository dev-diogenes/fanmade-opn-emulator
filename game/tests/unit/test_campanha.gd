extends GutTest
## Fase 7: a campanha original "O Fundo da Represa" (formato, progresso na carreira,
## marcas entre missões, recrutas liberados, cenas próprias e o piloto do começo ao fim).

const ID := "o_fundo_da_represa"

var rs: Ruleset
var campanha: Dictionary


func before_all():
	rs = RulesetOp2022.carregar_padrao()
	var lida := Campanha.carregar(ID, rs)
	assert_eq(lida.erros, [] as Array[String], "a campanha do jogo valida")
	campanha = lida.definicao


func _carreira() -> Carreira:
	return Carreira.nova(rs)


func _vencer(c: Carreira, responder: Array = []) -> Dictionary:
	for p in responder:
		c.missao.caso.pergunta(p).respondida = true
	c.missao.encerrada = true
	c.missao.vitoria = true
	return c.encerrar_missao()


# --- Formato ----------------------------------------------------------------------

func test_campanha_aparece_na_lista_e_tem_quatro_missoes():
	var ids := Campanha.listar(rs).map(func(x): return x.definicao.get("id", ""))
	assert_true(ID in ids)
	assert_eq(campanha.missoes.size(), 4)
	for etapa in campanha.missoes:
		assert_eq(MissaoComunidade.validar(etapa.definicao, rs), [] as Array[String], etapa.arquivo)
		assert_ne(String(etapa.get("antes", "")), "", "%s tem texto de abertura" % etapa.arquivo)
	assert_ne(String(campanha.get("prologo", "")), "")
	assert_ne(String(campanha.get("epilogo", "")), "")


func test_missoes_da_campanha_nao_aparecem_como_missoes_da_comunidade():
	var titulos := MissaoComunidade.listar(rs).map(func(x): return x.definicao.get("titulo", ""))
	for etapa in campanha.missoes:
		assert_false(etapa.definicao.titulo in titulos)


func test_validacao_aponta_erros_da_campanha():
	var ruim := campanha.duplicate(true)
	ruim.formato = "outra"
	ruim.missoes[0].recompensas = {"recrutas": ["Ninguém"]}
	ruim.missoes[1].efeitos_de_marcas = [{"marca": "inexistente", "tipo": "voar"}]
	ruim.missoes[2].marcas = {"porque": {"id": "x"}}
	ruim.missoes[3].definicao.mapa.objetivo = [99, 99]
	var erros := " | ".join(Campanha.validar(ruim, rs))
	assert_string_contains(erros, "formato")
	assert_string_contains(erros, "recruta desconhecido \"Ninguém\"")
	assert_string_contains(erros, "a marca \"inexistente\"")
	assert_string_contains(erros, "efeito de marca desconhecido \"voar\"")
	assert_string_contains(erros, "pergunta desconhecida \"porque\"")
	assert_string_contains(erros, "Missão 4 (A Matriz)")


func test_recrutas_da_campanha_sao_fichas_validas():
	for r in campanha.recrutas:
		var res := CriacaoAgente.criar(rs, r)
		assert_not_null(res.agente, "%s: %s" % [r.nome, res.erros])


func test_enigmas_usam_ids_das_perguntas_do_caso():
	var perguntas: Array = DadosJogo.ler("casos").perguntas.map(func(p): return p.id)
	var ameacas: Dictionary = DadosJogo.ler("ameacas").ameacas.duplicate()
	for etapa in campanha.missoes:
		ameacas.merge(etapa.definicao.get("ameacas", {}))
	for id in ameacas:
		var enigma: Dictionary = ameacas[id].get("ficha", {}).get("enigma", {})
		if enigma.has("pergunta"):
			assert_true(enigma.pergunta in perguntas, "%s: pergunta \"%s\"" % [id, enigma.pergunta])


# --- Cenas próprias ------------------------------------------------------------------

func test_missao_usa_a_propria_cena_de_investigacao():
	var c := _carreira()
	var m := c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	var h := Hex.de_offset(9, 4)
	assert_eq(m.mapa.conteudo(h).get("cena", ""), "colonia_de_pescadores")
	m._preparar_investigacao(h, "colonia_de_pescadores")
	var cena := m.criar_cena_investigacao()
	assert_eq(cena.cena.nome, "Colônia de pescadores")
	assert_eq(cena.pontos_restantes.size(), 6)
	assert_eq(m.cena_info("capela").get("id", ""), "capela", "as cenas do jogo continuam valendo")
	var res := PilotoMissao.resolver_investigacao(m)
	m.concluir_investigacao(res)
	assert_true(m.mapa.conteudo(h).is_empty())


func test_validacao_de_cena_propria():
	var d: Dictionary = campanha.missoes[0].definicao.duplicate(true)
	d.cenas[0].pontos[0].responde = "porque"
	d.cenas[0].pontos[1].pericias = {"voo": 15}
	d.cenas[0].facilitar[0].pericias = {"magia": 15}
	d.mapa.conteudo.append({"em": [8, 4], "tipo": "investigacao", "cena": "nao_existe"})
	var erros := " | ".join(MissaoComunidade.validar(d, rs))
	assert_string_contains(erros, "\"responde\" deve ser")
	assert_string_contains(erros, "perícia desconhecida \"voo\"")
	assert_string_contains(erros, "perícia desconhecida \"magia\"")
	assert_string_contains(erros, "Cena de investigação desconhecida \"nao_existe\"")


func test_resumo_do_caso_vem_da_missao():
	var c := _carreira()
	var m := c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	assert_string_contains(m.caso.resumo, "Represa do Jequiri")
	assert_eq(m.caso.sujeito.chefe_titulo, "o Afogado do Cais")


# --- Progresso na carreira -------------------------------------------------------------

func test_vitoria_avanca_e_libera_recruta():
	var c := _carreira()
	var m := c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	assert_not_null(m)
	assert_eq(int(m.extras.campanha.etapa), 0)
	assert_eq(m.extras.campanha.recrutas.size(), 1)
	var rel := _vencer(c)
	assert_eq(int(c.progresso_campanha(ID).etapa), 1)
	assert_eq(rel.campanha.recrutas, ["Gilson"])
	assert_string_contains(rel.campanha.texto, "Gilson")
	assert_true(c.recrutas_disponiveis().any(func(r): return r.nome == "Gilson"))
	assert_not_null(c.recrutar("Gilson"))
	assert_false(c.recrutas_disponiveis().any(func(r): return r.nome == "Gilson"), "recrutado sai da lista")


func test_derrota_mantem_a_missao():
	var c := _carreira()
	c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	c.missao.encerrada = true
	c.missao.vitoria = false
	var rel := c.encerrar_missao()
	assert_eq(int(c.progresso_campanha(ID).etapa), 0)
	assert_false(rel.campanha.vitoria)
	assert_string_contains(rel.campanha.texto, "colônia")
	assert_true(c.recrutas_extras.is_empty())
	assert_eq(c.progresso_campanha(ID).historico.size(), 1)


func test_marcas_passam_para_as_missoes_seguintes():
	var c := _carreira()
	c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	var rel := _vencer(c, ["oque"])
	assert_eq(c.progresso_campanha(ID).marcas, ["nos_de_sete"])
	assert_eq(rel.campanha.marcas.size(), 1)
	for a in c.roster:
		PilotoMissao.resolver_pendencias(a)
	var m2 := c.iniciar_missao_campanha(c.roster.slice(0, 3), campanha, 2)
	assert_eq(m2.membrana.valor, 95, "Membrana 85 + 10 pelos laços de sete nós")
	_vencer(c, ["onde"])
	for a in c.roster:
		PilotoMissao.resolver_pendencias(a)
	var m3 := c.iniciar_missao_campanha(c.roster.slice(0, 3), campanha, 3)
	assert_true(m3.mapa.revelado(m3.mapa.encontrar("objetivo")), "a planta da usina revela a sala de controle")
	_vencer(c, ["oque"])
	for a in c.roster:
		PilotoMissao.resolver_pendencias(a)
	var m4 := c.iniciar_missao_campanha(c.roster.slice(0, 3), campanha, 4)
	assert_almost_eq(m4.modificador_chefe, -0.2, 0.001)
	assert_eq(m4.membrana.valor, 80, "Membrana 75 + 5")


func test_campanha_concluida_mostra_epilogo_e_recomeca():
	var c := _carreira()
	var p := c.progresso_campanha(ID)
	p.etapa = 3
	c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	assert_eq(c.missao.extras.campanha.titulo, "O Fundo da Represa")
	var rel := _vencer(c)
	assert_true(rel.campanha.concluida)
	assert_string_contains(rel.campanha.epilogo, "chuva")
	assert_eq(int(p.vezes), 1)
	assert_eq(Campanha.descrever_etapa(campanha, p), "Campanha concluída")
	for a in c.roster:
		PilotoMissao.resolver_pendencias(a)
	var m := c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 2)
	assert_eq(int(m.extras.campanha.etapa), 0, "recomeça do início")
	assert_eq(Campanha.descrever_etapa(campanha, p), "Missão 1 de 4: Nível Baixo")


func test_progresso_vai_no_save():
	var c := _carreira()
	c.iniciar_missao_campanha(c.roster.duplicate(), campanha, 1)
	_vencer(c, ["oque"])
	for a in c.roster:
		PilotoMissao.resolver_pendencias(a)
	c.iniciar_missao_campanha(c.roster.slice(0, 3), campanha, 5)
	var d = JSON.parse_string(JSON.stringify(c.para_dicionario()))
	var c2 := Carreira.de_dicionario(d, rs)
	assert_eq(int(c2.progresso_campanha(ID).etapa), 1)
	assert_eq(c2.progresso_campanha(ID).marcas, ["nos_de_sete"])
	assert_eq(c2.recrutas_extras.size(), 1)
	assert_not_null(c2.missao)
	assert_eq(int(c2.missao.extras.campanha.etapa), 1)
	assert_eq(c2.missao.cena_info("cemiterio_de_sao_bento").get("nome", ""), "Cemitério de São Bento")
	c2.missao.encerrada = true
	c2.missao.vitoria = true
	var rel := c2.encerrar_missao()
	assert_eq(int(c2.progresso_campanha(ID).etapa), 2)
	assert_string_contains(rel.campanha.texto, "Sarmento")


# --- Critério da Fase 7: a campanha inteira, no piloto automático -----------------------

## Grupo para a próxima missão: os 4 de maior NEX (as escolhas de NEX feitas pelo piloto).
func _grupo(c: Carreira) -> Array:
	while c.roster.size() < Carreira.MAX_GRUPO and not c.recrutas_disponiveis().is_empty():
		c.recrutar(c.recrutas_disponiveis()[0].nome)
	for a in c.roster:
		PilotoMissao.resolver_pendencias(a)
	var lista := c.roster.duplicate()
	lista.sort_custom(func(a, b): return a.nex > b.nex)
	return lista.slice(0, Carreira.MAX_GRUPO)


func _jogar_campanha(semente: int) -> Dictionary:
	var c := _carreira()
	var tentativas := []
	for i in 12:
		var p := c.progresso_campanha(ID)
		if p.concluida:
			break
		var grupo := _grupo(c)
		assert_eq(c.validar_grupo(grupo), [] as Array[String], "grupo válido")
		var m := c.iniciar_missao_campanha(grupo, campanha, semente * 100 + i)
		if m == null:
			break
		var rel := PilotoMissao.jogar(m)
		assert_eq(rel.travou, "", "seed %d, missão %d travou: %s" % [semente, int(p.etapa) + 1, rel.travou])
		assert_eq(rel.combates_sem_fim, 0)
		if not m.encerrada:
			break
		tentativas.append("%d%s" % [int(p.etapa) + 1, "✓" if m.vitoria else "✗"])
		c.encerrar_missao()
	return {"concluida": c.progresso_campanha(ID).concluida, "tentativas": tentativas, "mortos": c.memorial.size()}


func test_campanha_completa_no_piloto_automatico():
	for semente in [1, 2]:
		var r := _jogar_campanha(semente)
		gut.p("seed %d: %s (mortos: %d)" % [semente, " ".join(PackedStringArray(r.tentativas)), r.mortos])
		assert_true(r.concluida, "seed %d: a campanha termina em até 12 missões" % semente)
