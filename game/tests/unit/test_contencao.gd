extends GutTest
## Mais da Ordem (docs/63): a credencial de fachada que se queima (OR4), os cultistas na
## contenção da Base (OR8) e a planta com as salas que prestam serviços (OR2).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _cena(m: Missao) -> CenaInvestigacao:
	m.investigacao_pendente = {"hex": m.posicao(m.agentes[0]), "cena": "velorio", "agentes": m.agentes, "semente": 5}
	return m.criar_cena_investigacao()


func test_credencial_com_nome_inventado():
	var m := Missao.nova(42)
	assert_string_contains(String(m.credencial.nome), "Agente ")
	assert_eq(int(m.credencial.usos), 0)
	assert_eq(Missao.nova(42).credencial.nome, m.credencial.nome, "o mesmo nome em todas as máquinas")
	assert_false(String(DadosJogo.ler("sinais").credencial.orgao).contains("SCI"), "órgão inventado, não o do cânone")


func test_credencial_da_bonus_e_firma_o_depoimento():
	var m := Missao.nova(42)
	var c := _cena(m)
	var per := "diplomacia"
	assert_true(c.pode_usar_credencial(c.ponto("viuva")))
	assert_false(c.pode_usar_credencial(c.ponto("caixao")), "só vale com testemunha")
	var sem := c.prever_procurar("viuva", per)
	var com := c.prever_procurar("viuva", per, 0, {"credencial": true})
	assert_eq(int(com.bonus), int(sem.bonus) + 5)
	# Passar por pouco: sem a credencial o depoimento sairia incerto
	var face := int(com.dt) - int(com.bonus) + 1
	var fila: Array = []
	fila.resize(int(com.dados))
	fila.fill(clampi(face, 1, 20))
	c.dados.forcar(fila)
	var r := c.procurar("viuva", per, 0, {"credencial": true})
	assert_true(r.sucesso)
	assert_false(r.incerta, "diante da credencial, ninguém arrisca mentir")
	assert_eq(c.usos_credencial, 1)
	assert_eq(c.resultado().usos_credencial, 1)


func test_credencial_queima_e_a_patrulha_vem():
	var m := Missao.nova(42)
	var h := m.posicao(m.agentes[0])
	m.credencial.usos = 2
	m._somar_usos_da_credencial(1, h)
	assert_true(m.credencial.queimada)
	var patrulha := false
	for v in Hex.vizinhos(h):
		if m.mapa.tem(v) and String(m.mapa.conteudo(v).get("encontro", "")) == "patrulha":
			patrulha = true
	assert_true(patrulha, "a polícia de verdade procura os falsos agentes")
	var c := _cena(m)
	assert_false(c.pode_usar_credencial(c.ponto("viuva")), "queimada, não vale mais")
	var por_id := {}
	for a in m.agentes_iniciais:
		por_id[a.id] = a
	var m2 := Missao.de_dicionario(m.ruleset, JSON.parse_string(JSON.stringify(m.para_dicionario())), por_id)
	assert_true(m2.credencial.queimada, "vai no save")


func _missao_com_preso(c: Carreira) -> Missao:
	var m := c.iniciar_missao(c.roster.duplicate(), 7)
	m._preparar_encontro(m.posicao(m.agentes[0]), "celula_cultista", false)
	m.concluir_encontro("agentes", 1)
	return m


func test_rendido_vai_para_a_contencao():
	var c := Carreira.nova(rs)
	var m := _missao_com_preso(c)
	assert_eq(m.presos.size(), 1)
	var t := DadosJogo.ler("testemunhas")
	assert_true(String(m.presos[0].nome) in t.nomes_f + t.nomes_m, "nome de gente comum")
	m._encerrar(true)
	c.encerrar_missao()
	assert_eq(c.contencao.size(), 1)
	assert_eq(c.contencao[0].cela, "A")
	assert_eq(int(c.contencao[0].segredos), 2)
	var volta := Carreira.de_dicionario(JSON.parse_string(JSON.stringify(c.para_dicionario())), rs)
	assert_eq(volta.contencao[0].nome, c.contencao[0].nome, "vai no save")


func test_celas_cheias_transferem():
	var c := Carreira.nova(rs)
	for cela in ["A", "B", "C", "D"]:
		c.contencao.append({"nome": "X", "papel": "Cultista", "elemento": "sangue", "cela": cela, "segredos": 2, "interrogado": -1})
	var m := _missao_com_preso(c)
	m._encerrar(true)
	var r := c.encerrar_missao()
	assert_eq(c.contencao.size(), 4)
	assert_true(r.detalhes_pp.any(func(l): return String(l).contains("transferido")))


func test_interrogatorio_vale_uma_pista_na_proxima_missao():
	var c := Carreira.nova(rs)
	c.contencao.append({"nome": "Valdir", "papel": "Iniciado", "elemento": "sangue", "cela": "B", "segredos": 2, "interrogado": -1})
	var ag: Agente = c.roster[0]
	var r := c.interrogar(0, ag)
	assert_true(r.ok)
	assert_false(c.interrogar(0, ag).ok, "uma vez por visita")
	var tentativas := 0
	while not r.sucesso and tentativas < 30:
		c.missoes_concluidas += 1
		r = c.interrogar(0, ag)
		tentativas += 1
	assert_true(r.sucesso, "em algum momento ele fala")
	assert_eq(int(c.contencao[0].segredos), 1)
	assert_false(c.pista_do_preso.is_empty())
	var m := c.iniciar_missao(c.roster.duplicate(), 9)
	assert_eq(m.caso.indicios_encontrados("quem").size(), 1, "uma pista firme logo no começo")
	assert_string_contains(String(m.caso.pistas[0].texto), "cela B")
	assert_true(c.pista_do_preso.is_empty(), "vale uma vez")


func test_preso_sem_segredos_e_transferido():
	var c := Carreira.nova(rs)
	c.contencao.append({"nome": "Valdir", "papel": "Iniciado", "elemento": "sangue", "cela": "B", "segredos": 1, "interrogado": -1})
	var r := {"sucesso": false}
	for i in 30:
		r = c.interrogar(0, c.roster[0])
		if r.sucesso:
			break
		c.missoes_concluidas += 1
	assert_true(c.contencao.is_empty())
	assert_string_contains(String(r.texto), "transferido")


func test_laboratorio_verifica_um_sinal():
	var c := Carreira.nova(rs)
	var s := Sinais.de(10, "baixa")
	assert_false(c.analisar_sinal(s).ok, "sem amostra, nada")
	c.amostras = 1
	var r := c.analisar_sinal(s)
	assert_true(r.ok)
	assert_eq(r.alarme_falso, s.alarme_falso)
	assert_true(s.verificado)
	assert_eq(c.amostras, 0)


func test_planta_da_base():
	var jogo = get_node("/root/Jogo")
	var antes = jogo.carreira
	var salvar_antes: bool = jogo.salvar_automaticamente
	jogo.salvar_automaticamente = false
	jogo.carreira = Carreira.nova(rs)
	var base = load("res://scenes/base_ordem.tscn").instantiate()
	add_child_autofree(base)
	await wait_frames(2)
	assert_eq(base._abas.get_tab_title(0), "Base")
	var titulos: Array = base._aba_planta.find_children("*", "Label", true, false).map(func(l): return l.text)
	for sala in ["BAR DE FACHADA", "ESCRITÓRIO", "CENTRAL DE SINAIS", "BALCÃO DE EQUIPAMENTOS", "SALA DE OCULTISMO",
			"ENFERMARIA", "LABORATÓRIO", "CONTENÇÃO", "MEMORIAL"]:
		assert_true(titulos.has(sala), sala)
	base.ir_para_aba("Arsenal")
	assert_eq(base._abas.get_tab_title(base._abas.current_tab), "Arsenal")
	jogo.carreira = antes
	jogo.salvar_automaticamente = salvar_antes
	for n in get_tree().root.find_children("ConviteTutorial", "", true, false):
		n.queue_free()
