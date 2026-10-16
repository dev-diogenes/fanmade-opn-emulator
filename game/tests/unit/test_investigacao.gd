extends GutTest
## Investigação (p.86, p.89-91): caso, cena, ações, urgência e integração com a missão.

var m: Missao
var mauro: Agente
var bianca: Agente
var rita: Agente


func before_each():
	m = Missao.nova(42)
	mauro = m.agentes[0]
	bianca = m.agentes[1]
	rita = m.agentes[2]


func _cena(grupo: Array = [], urgencia: String = "medio", membrana: Membrana = null) -> CenaInvestigacao:
	if grupo.is_empty():
		grupo = [mauro, bianca, rita]
	return CenaInvestigacao.nova(m.ruleset, Dados.new(1), m.caso, "casa_abandonada", grupo, urgencia, membrana)


# --- Caso -------------------------------------------------------------------------

func test_caso_gerado_e_perguntas():
	var c := m.caso
	assert_eq(c.perguntas.size(), 3)
	assert_false(c.formatar("{sujeito} em {local}").contains("{"))
	assert_true(c.registrar_pista("x", "onde", "teste").is_empty(), "1 de 2 pistas")
	var resp := c.registrar_pista("y", "onde", "teste")
	assert_eq(resp.id, "onde")
	assert_eq(c.resposta("onde"), c.local.nome)
	assert_eq(c.resposta("quem"), "", "ainda sem resposta")


func test_caso_ida_e_volta():
	m.caso.registrar_pista("x", "quem", "a")
	var c2 := Caso.de_dicionario(m.caso.para_dicionario())
	assert_eq(c2.para_dicionario(), m.caso.para_dicionario())


# --- Cena ---------------------------------------------------------------------------

func test_urgencia_define_as_rodadas():
	assert_eq(_cena([], "medio").rodadas_max, 4)
	assert_eq(_cena([], "muito_alto").rodadas_max, 2)


func test_procurar_pista_com_sucesso():
	var c := _cena()
	assert_eq(c.agente_atual(), mauro)
	c.dados.forcar([15])   # Mauro, Investigação destreinada (INT 1): 15 vs DT 15
	var r := c.procurar("escrivaninha", "investigacao")
	assert_true(r.sucesso)
	assert_false("escrivaninha" in c.pontos_restantes)
	assert_eq(c.pistas_encontradas.size(), 1)
	assert_eq(c.agente_atual(), bianca, "a vez passa ao próximo agente")


func test_procurar_invalido_nao_gasta_a_vez():
	var c := _cena()
	assert_true(c.procurar("escrivaninha", "ocultismo").is_empty(), "perícia não aceita neste ponto")
	assert_true(c.procurar("inexistente", "investigacao").is_empty())
	assert_eq(c.agente_atual(), mauro)


func test_tres_falhas_custam_uma_rodada():
	var c := _cena()
	c.dados.forcar([1, 1, 1, 1, 1, 1])
	c.procurar("escrivaninha", "percepcao")     # Mauro
	c.procurar("escrivaninha", "investigacao")  # Bianca (3 dados)
	c.procurar("porao", "percepcao")            # Rita (2 dados)
	assert_eq(c.falhas, 3)
	assert_eq(c.rodadas_max, 3)
	assert_eq(c.rodada, 2)


func test_facilitar_da_mais_2_aos_aliados():
	var c := _cena()
	c.dados.forcar([15, 1, 1])   # Mauro: Atletismo (FOR 3) 15 + 5 = 20 vs DT 15
	assert_true(c.facilitar("janelas", "atletismo").sucesso)
	c.dados.forcar([8, 1, 1])    # Bianca: 8 + 5 + 2 = 15 vs DT 15 (sem o bônus, falharia)
	var r := c.procurar("escrivaninha", "investigacao")
	assert_true(r.sucesso)
	assert_eq(r.teste.bonus, 5 + 2)


func test_ajudar():
	var c := _cena()
	c.dados.forcar([20])   # Mauro: Intimidação 20 + 5 = 25 vs DT 10 -> +1, +1 por 10 acima
	var r := c.ajudar(bianca, "intimidacao")
	assert_eq(r.bonus, 2)
	c.dados.forcar([6, 1, 1])
	assert_eq(c.procurar("escrivaninha", "investigacao").teste.bonus, 5 + 2)


func test_teimoso_nao_recebe_ajuda():
	bianca.desvantagens_idade.append("teimoso")
	var c := _cena()
	assert_true(c.ajudar(bianca, "intimidacao").is_empty())


func test_urgencia_estourada():
	var mem := Membrana.carregar_padrao()
	var c := _cena([], "muito_alto", mem)
	watch_signals(c)
	for i in 6:
		c.passar()
	assert_true(c.encerrada)
	assert_true(c.urgencia_estourada)
	assert_false(c.penalidade.is_empty())
	assert_signal_emitted(c, "terminou")
	assert_eq(mem.valor, 100 - 2 - 2 - 10, "duas rodadas e a urgência estourada")


func test_achar_todas_as_pistas_encerra_a_cena():
	var c := _cena()
	for ponto in ["escrivaninha", "computador", "vizinha", "porao"]:
		c.dados.forcar([20, 20, 20])
		var a := c.agente_atual()
		var per: String = {"escrivaninha": "investigacao", "computador": "investigacao", "vizinha": "intimidacao", "porao": "atletismo"}[ponto]
		c.procurar(ponto, per)
	assert_true(c.encerrada)
	assert_eq(c.pistas_encontradas.size(), 4)


func test_faro_para_pistas_so_ao_procurar():
	var c := _cena([bianca])
	c.dados.forcar([5, 1, 1])   # 5 + 5 (treinada) + 5 (Faro) = 15
	var r := c.procurar("escrivaninha", "investigacao", 0, {"habilidades": ["faro_para_pistas"]})
	assert_true(r.sucesso)
	assert_eq(bianca.pe, bianca.pe_maximo - 1)


func test_incansavel_da_acao_extra_com_forca():
	mauro.poderes.append("incansavel")
	var c := _cena()
	assert_true(c.acao_extra("incansavel"))
	c.dados.forcar([1, 1, 15])   # usa FOR 3 em vez de INT 1
	var r := c.procurar("escrivaninha", "investigacao")
	assert_eq(r.teste.slots.size(), 3)
	assert_eq(c.agente_atual(), mauro, "ainda tem a ação normal")
	assert_false(c.acao_extra("incansavel"), "uma vez por cena")


func test_distraido_perde_o_primeiro_turno():
	mauro.desvantagens_idade.append("distraido")
	var c := _cena()
	assert_eq(c.agente_atual(), bianca)


# --- Missão -------------------------------------------------------------------------

func test_mapa_tem_investigacoes():
	for semente in [1, 42, 777]:
		var mapa := GeradorMapa.gerar(semente)
		var n := 0
		for h in mapa.celulas:
			if mapa.conteudo(h).get("tipo", "") == "investigacao":
				n += 1
		assert_gt(n, 0, "seed %d" % semente)


func test_resultado_da_investigacao_na_missao():
	var h := m.posicao(mauro)
	m._preparar_investigacao(h, "casa_abandonada")
	assert_true(m.ocupado())
	assert_not_null(m.criar_cena_investigacao())
	var onde := m.caso.pergunta("onde")
	m.concluir_investigacao({"pistas": [{}, {}], "perguntas": [onde], "penalidade": {"tipo": "chefe_fortalecido"}})
	assert_false(m.ocupado())
	assert_eq(m.pistas, 2)
	assert_true(m.mapa.revelado(m.mapa.encontrar("objetivo")))
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	assert_eq(int(m.encontro_pendente.ameacas[0].ficha.pv), 54, "chefe 20% mais forte (45 -> 54)")


func test_descobrir_quem_enfraquece_e_nomeia_o_chefe():
	m._preparar_investigacao(m.posicao(mauro), "capela")
	var quem := m.caso.pergunta("quem")
	quem.respondida = true
	m.concluir_investigacao({"pistas": [], "perguntas": [quem], "penalidade": {}})
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	var chefe: Dictionary = m.encontro_pendente.ameacas[0]
	assert_eq(int(chefe.ficha.pv), 36, "20% mais fraco (45 -> 36)")
	assert_eq(chefe.nome, m.caso.sujeito.chefe_titulo)


func test_penalidade_de_encontro_deixa_ameaca_no_hex():
	var h := m.posicao(mauro)
	m._preparar_investigacao(h, "acampamento")
	m.concluir_investigacao({"pistas": [], "perguntas": [], "penalidade": {"tipo": "encontro", "encontro": "emboscada"}})
	assert_eq(m.mapa.conteudo(h).get("tipo", ""), "encontro")


func test_salvar_com_investigacao_pendente():
	var c := Carreira.nova(m.ruleset)
	var mi := c.iniciar_missao(c.roster.duplicate(), 5)
	mi._preparar_investigacao(mi.posicao(mi.agente_atual()), "capela")
	var caminho := "user://teste_investigacao.json"
	c.salvar(caminho)
	var c2 := Carreira.carregar(caminho)
	assert_eq(c2.missao.investigacao_pendente.cena, "capela")
	assert_eq(c2.missao.caso.sujeito, mi.caso.sujeito)
	assert_eq(c2.missao.investigacao_pendente.agentes.size(), 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))


func test_cena_de_investigacao_abre():
	var tela = load("res://scenes/investigacao.tscn").instantiate()
	add_child_autofree(tela)
	assert_not_null(tela.cena)
	assert_false(tela.cena.encerrada)
