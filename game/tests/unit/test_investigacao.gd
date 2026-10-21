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
	var p1 := c.registrar_pista("Achado: {indicio}", "onde", "teste")
	assert_true(p1.indicio in c.local.indicios, "a pista revela um traço do local verdadeiro")
	assert_false(String(p1.texto).contains("{"), "o traço entra no texto")
	assert_false(String(p1.texto).contains(c.local.nome), "a pista não entrega a resposta")
	var p2 := c.registrar_pista("y {indicio}", "onde", "teste")
	assert_ne(p2.indicio, p1.indicio, "a segunda pista revela outro traço")
	assert_false(c.pergunta("onde").respondida, "a pergunta não se resolve sozinha (docs/32)")
	assert_eq(c.resposta("onde"), "")


# --- Dedução por indícios (docs/32) ---------------------------------------------------

func test_dois_candidatos_nunca_dividem_mais_de_um_traco():
	var d := DadosJogo.ler("casos")
	for pid in Caso.PERGUNTA_GRUPO:
		var cands := Caso.candidatos(pid)
		assert_gt(cands.size(), 2, pid)
		for i in cands.size():
			assert_eq(cands[i].indicios.size(), 3, "%s: 3 traços" % cands[i].id)
			for t in cands[i].indicios:
				assert_true(d.indicios.has(t), "traço %s descrito" % t)
			for j in range(i + 1, cands.size()):
				var comuns: Array = cands[i].indicios.filter(func(t): return t in cands[j].indicios)
				assert_lte(comuns.size(), 1, "%s e %s" % [cands[i].id, cands[j].id])


func test_duas_pistas_deixam_um_so_suspeito():
	for semente in 12:
		var c := Caso.gerar(Dados.new(semente))
		for pid in ["quem", "oque", "onde"]:
			c.registrar_pista("{indicio}", pid, "t")
			assert_true(c.compativeis(pid).size() >= 1)
			c.registrar_pista("{indicio}", pid, "t")
			var restam := c.compativeis(pid)
			assert_eq(restam.size(), 1, "semente %d, %s" % [semente, pid])
			assert_eq(restam[0].id, c.verdadeiro(pid).id)


func test_deduzir_certo_e_errado():
	var c := m.caso
	assert_false(c.deduzir("quem", c.sujeito.id).ok, "sem pista não dá para acusar")
	c.registrar_pista("{indicio}", "quem", "t")
	var errado := ""
	for cand in Caso.candidatos("quem"):
		if cand.id != c.sujeito.id:
			errado = cand.id
	var r := c.deduzir("quem", errado)
	assert_true(r.ok)
	assert_false(r.acertou)
	assert_true(errado in c.pergunta("quem").descartados, "o suspeito fica riscado")
	assert_false(c.deduzir("quem", errado).ok, "não se acusa o mesmo duas vezes")
	r = c.deduzir("quem", c.sujeito.id)
	assert_true(r.acertou)
	assert_eq(c.resposta("quem"), c.sujeito.nome)
	assert_false(c.deduzir("quem", c.sujeito.id).ok, "já resolvida")


func test_deduzir_no_mapa_aplica_efeito_e_penalidade():
	var antes := m.membrana.valor
	m.caso.registrar_pista("{indicio}", "onde", "t")
	var errado := ""
	for cand in Caso.candidatos("onde"):
		if cand.id != m.caso.local.id:
			errado = cand.id
	var r := Comandos.aplicar_mapa(m, Comandos.novo("mapa", "deduzir", {"pergunta": "onde", "candidato": errado}))
	assert_true(r.ok)
	assert_eq(m.membrana.valor, antes + Caso.penalidade_palpite(), "acusação errada custa Membrana")
	r = Comandos.aplicar_mapa(m, Comandos.novo("mapa", "deduzir", {"pergunta": "onde", "candidato": m.caso.local.id}))
	assert_true(r.deducao.acertou)
	assert_true(m.mapa.revelado(m.mapa.encontrar("objetivo")), "acertar o onde revela o covil")


func test_deduzir_na_cena_vale_ao_sair():
	var membrana := m.membrana
	var c := _cena([], "medio", membrana)
	c.caso.registrar_pista("{indicio}", "quem", "t")
	var r := Comandos.aplicar_investigacao(c, Comandos.novo("investigacao", "deduzir", {"pergunta": "quem", "candidato": m.caso.sujeito.id}))
	assert_true(r.ok and r.deducao.acertou)
	assert_eq(c.resultado().perguntas.size(), 1, "o efeito vai com o resultado da cena")
	assert_eq(c.agente_atual(), mauro, "deduzir não gasta a vez")


func test_cenas_novas_tem_ponto_para_cada_pergunta():
	var d := DadosJogo.ler("cenas_investigacao")
	for c in d.cenas:
		var perguntas := {}
		for p in c.pontos:
			perguntas[p.responde] = true
			assert_true(String(p.pista).contains("{indicio}"), "%s/%s: a pista traz um indício" % [c.id, p.id])
		assert_eq(perguntas.size(), 3, "%s responde quem, o quê e onde" % c.id)


func test_evento_com_pista_revela_um_traco():
	var h := m.posicao(mauro)
	var antes := m.caso.pistas.size()
	var feito := m._aplicar_efeito(mauro, {"tipo": "pista", "pergunta": "onde"}, h)
	assert_eq(feito.tipo, "pista")
	assert_eq(m.caso.pistas.size(), antes + 1)
	assert_true(m.caso.pistas.back().indicio in m.caso.local.indicios)
	# Sem pergunta: vai para a aberta com menos pistas
	feito = m._aplicar_efeito(mauro, {"tipo": "pista"}, h)
	assert_ne(m.caso.pistas.back().responde, "onde")


func test_save_antigo_sem_tracos_ganha_ordem():
	var d: Dictionary = JSON.parse_string(JSON.stringify(m.caso.para_dicionario()))   # cópia: o caso aponta para os dados em cache
	d.sujeito.erase("indicios")
	for q in d.perguntas:
		q.erase("ordem")
		q.erase("descartados")
	var c := Caso.de_dicionario(d)
	assert_eq(c.sujeito.indicios.size(), 3)
	assert_eq(c.pergunta("quem").ordem.size(), 3)
	assert_true(c.registrar_pista("{indicio}", "quem", "t").indicio in c.sujeito.indicios)


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


# --- Pista central (docs/14, estilo GUMSHOE) ------------------------------------------

func test_examinar_sem_treino_nao_pode():
	var c := _cena()
	assert_eq(c.agente_atual(), mauro)
	assert_false(mauro.pericias.has("investigacao"))
	assert_eq(c.custo_examinar(mauro, "escrivaninha", "investigacao"), -1, "sem treino, só procurando com teste")
	assert_true(c.examinar("escrivaninha", "investigacao").is_empty())
	assert_eq(c.agente_atual(), mauro, "pedido inválido não gasta a vez")


func test_examinar_na_dt_maior_custa_pe():
	var c := _cena()
	assert_true(mauro.pericias.has("percepcao"))
	assert_eq(c.custo_examinar(mauro, "escrivaninha", "percepcao"), 1, "DT 20: 1 PE")
	var pe := mauro.pe
	var r := c.examinar("escrivaninha", "percepcao")
	assert_false(r.is_empty())
	assert_eq(mauro.pe, pe - 1)
	assert_false("escrivaninha" in c.pontos_restantes)
	assert_eq(c.pistas_encontradas.size(), 1, "a pista central vem sem rolar dados")
	assert_eq(c.agente_atual(), bianca, "examinar gasta a ação")


func test_examinar_na_dt_simples_e_de_graca():
	var c := _cena()
	c.passar()
	assert_eq(c.agente_atual(), bianca)
	var per := c.melhor_pericia_para_examinar(bianca, "escrivaninha")
	if per == "":
		pass_test("Bianca não tem treino nas perícias da escrivaninha neste grupo")
		return
	var custo := c.custo_examinar(bianca, "escrivaninha", per)
	var pe := bianca.pe
	assert_false(Comandos.aplicar_investigacao(c, Comandos.novo("investigacao", "examinar", {"ponto": "escrivaninha", "pericia": per})).ok == false)
	assert_eq(bianca.pe, pe - custo)
	if per == "investigacao":
		assert_eq(custo, 0, "DT 15 com treino: de graça")
