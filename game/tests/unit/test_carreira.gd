extends GutTest
## Carreira, patente, equipamento, progressão de NEX e salvar/carregar.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _carreira() -> Carreira:
	return Carreira.nova(rs)


func _por_nome(c: Carreira, nome: String) -> Agente:
	for a in c.roster:
		if a.nome == nome:
			return a
	return null


# --- Patente e equipamento -----------------------------------------------------

func test_patente_por_pp():
	assert_eq(rs.patente_por_pp(0).id, "recruta")
	assert_eq(rs.patente_por_pp(20).id, "operador")
	assert_eq(rs.patente_por_pp(55).id, "agente_especial")
	assert_eq(rs.patente_por_pp(250).id, "agente_de_elite")


func test_carreira_nova_tem_tres_recrutas_equipados():
	var c := _carreira()
	assert_eq(c.roster.size(), 3)
	for a in c.roster:
		assert_ne(a.id, "")
		assert_eq(a.validar_equipamento(a.equipamento), [] as Array[String], a.nome)
		assert_ne(a.arma().id, "desarmado")
	assert_eq(c.recrutas_disponiveis().size(), 3)


func test_recrutas_prontos_tem_descricao():
	var c := _carreira()
	for a in c.roster:
		assert_ne(a.conceito, "", a.nome)
		assert_ne(a.historico, "", a.nome)
		assert_gt(a.idade_anos, 0, a.nome)
	# Save antigo: o recruta sem descrição ganha a dele ao carregar
	var d := c.para_dicionario()
	for ad in d.roster:
		ad.conceito = ""
		ad.historico = ""
	var c2 := Carreira.de_dicionario(d)
	assert_ne(c2.roster[0].historico, "")


func test_limite_de_itens_pela_patente():
	var a := _por_nome(_carreira(), "Cléber")
	assert_false(a.validar_equipamento(["machado", "protecao_leve", "cicatrizante"]).is_empty(), "recruta: 2 itens de categoria I")
	assert_false(a.validar_equipamento(["protecao_pesada"]).is_empty(), "recruta não tem categoria II")
	a.pp = 20
	assert_true(a.validar_equipamento(["machado", "protecao_pesada", "cicatrizante"]).is_empty(), "operador: 3 de I e 1 de II")
	assert_false(a.validar_equipamento(["protecao_leve", "protecao_pesada"]).is_empty(), "só uma proteção")
	assert_true(a.validar_equipamento(["kit_medicina", "kit_crime", "kit_tecnologia"]).is_empty(), "categoria 0 é livre")


func test_protecao_defesa_e_resistencia():
	var a := _por_nome(_carreira(), "Cléber")
	var sem := a.defesa()
	a.equipamento.erase("protecao_leve")
	assert_eq(a.defesa(), sem - 5)
	a.pp = 20
	a.equipamento.append("protecao_pesada")
	assert_eq(a.resistencia("corte"), 2)
	assert_eq(a.bonus_pericia("acrobacia"), -5, "pesada atrapalha perícias de carga")


func test_kit_de_pericia():
	var bianca := _por_nome(_carreira(), "Bianca")
	assert_eq(bianca.bonus_pericia("medicina"), 5, "treinada, com kit")
	bianca.equipamento.erase("kit_medicina")
	assert_eq(bianca.bonus_pericia("medicina"), 0, "sem kit: −5")


func test_sobrecarga():
	var bianca := _por_nome(_carreira(), "Bianca")   # FOR 0: 2 espaços
	assert_eq(bianca.capacidade_carga(), 2)
	var defesa := bianca.defesa()
	bianca.equipamento.append("protecao_leve")
	assert_true(bianca.sobrecarregado())
	assert_eq(bianca.defesa(), defesa + 5 - 5)
	assert_eq(bianca.deslocamento_m(), 6.0)
	assert_false(bianca.validar_equipamento(["pistola", "protecao_leve", "equipamento_sobrevivencia"]).is_empty(), "passa do dobro da carga")


func test_proficiencia_de_protecao():
	var rita := _por_nome(_carreira(), "Rita")   # ocultista: sem proficiência em proteções
	var dados := rita.dados_da_pericia("acrobacia")
	rita.equipamento.append("protecao_leve")
	assert_eq(rita.dados_da_pericia("acrobacia"), dados - 2)
	assert_eq(rita.dados_da_pericia("vontade"), rita.atributo("pre"), "só Força e Agilidade")


func test_requisitar():
	var c := _carreira()
	var cleber := _por_nome(c, "Cléber")
	assert_false(c.requisitar(cleber, ["espada"], "machado").is_empty(), "arma fora do equipamento")
	assert_true(c.requisitar(cleber, ["espada", "cicatrizante"], "espada").is_empty())
	assert_eq(cleber.arma().id, "espada")


# --- Missão e relatório --------------------------------------------------------

func test_grupo_valido():
	var c := _carreira()
	assert_false(c.validar_grupo([]).is_empty())
	assert_true(c.validar_grupo(c.roster).is_empty())
	assert_not_null(c.iniciar_missao(c.roster, 7))
	assert_null(c.iniciar_missao(c.roster, 8), "já existe uma missão em andamento")


func test_vitoria_da_pp_nex_e_promocao():
	var c := _carreira()
	var grupo := c.roster.duplicate()
	var m := c.iniciar_missao(grupo, 7)
	# 4 + 4 + 3 pistas para perguntas que pedem 2: são 5 adicionais (Tabela 3.2, docs/43)
	for par in [["quem", 4], ["oque", 4], ["onde", 3]]:
		for i in par[1]:
			m.caso.registrar_pista("{indicio}", par[0], "t")
	for pid in ["quem", "oque"]:   # a ficha responde o objetivo (p.79): o caso foi solucionado
		m.caso.pergunta(pid).respondida = true
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	m.concluir_encontro("agentes")
	var r := c.encerrar_missao()
	assert_true(r.vitoria)
	assert_eq(r.pp, 10 + 2 * 5)
	var cleber := _por_nome(c, "Cléber")
	assert_eq(cleber.pp, 20)
	assert_eq(cleber.patente().id, "operador")
	assert_eq(cleber.nex, 10)
	assert_true(r.agentes[0].promovido)
	assert_null(c.missao)
	assert_eq(Progressao.pendencias(cleber)[0].tipo, "trilha")
	assert_false(c.validar_grupo([cleber]).is_empty(), "precisa escolher a trilha antes de partir")


func test_morte_vai_para_o_memorial():
	var c := _carreira()
	c.opcoes.modo_morte = "hardcore"
	var m := c.iniciar_missao(c.roster.duplicate(), 7)
	var rita := _por_nome(c, "Rita")
	m._preparar_encontro(m.posicao(rita), "emboscada", false)
	rita.sofrer_dano(1000)
	m.concluir_encontro("agentes")   # vitória, mas Rita estava a 0 PV: é socorrida
	assert_false(rita.tem(Ser.MORTO))
	m._preparar_encontro(m.posicao(rita), "emboscada", false)
	rita.condicoes[Ser.MORTO] = true   # morreu durante o combate
	m.concluir_encontro("agentes")
	assert_true(rita in m.mortos)
	m._encerrar(false)
	var r := c.encerrar_missao()
	assert_eq(c.roster.size(), 2)
	assert_eq(c.memorial[0].nome, "Rita")
	assert_eq(r.pp, -5)


# --- Progressão ------------------------------------------------------------------

func test_progressao_ate_nex_35():
	var cleber := _por_nome(_carreira(), "Cléber")
	cleber.nex = 35
	var tipos := Progressao.pendencias(cleber).map(func(p): return p.tipo)
	assert_eq(tipos, ["trilha", "poder", "poder", "aumento", "grau"])
	assert_false(Progressao.aplicar(cleber, "trilha", "inexistente").is_empty())
	assert_eq(Progressao.aplicar(cleber, "trilha", "guerreiro"), [] as Array[String])
	assert_eq(Progressao.aplicar(cleber, "poder", "golpe_pesado"), [] as Array[String])
	assert_false(Progressao.aplicar(cleber, "poder", "treinamento_em_pericia").is_empty(), "faltam as perícias")
	assert_eq(Progressao.aplicar(cleber, "poder", "treinamento_em_pericia", ["crime", "tatica"]), [] as Array[String])
	assert_eq(cleber.grau("tatica"), "treinado")
	assert_eq(Progressao.aplicar(cleber, "aumento", "vig"), [] as Array[String])
	assert_eq(cleber.atributo("vig"), 4)
	var grau: Dictionary = Progressao.pendencias(cleber)[0]
	assert_eq(grau.tipo, "grau")
	assert_eq(grau.quantidade, 3)   # 2 + INT 1
	assert_eq(Progressao.aplicar(cleber, "grau", ["luta", "fortitude", "atletismo"]), [] as Array[String])
	assert_eq(cleber.grau("luta"), "veterano")
	assert_true(Progressao.pendencias(cleber).is_empty())


# --- Salvar e carregar -------------------------------------------------------------

func test_salvar_e_carregar_carreira_com_missao():
	var caminho := "user://teste_carreira.json"
	var c := _carreira()
	var grupo := c.roster.duplicate()
	var m := c.iniciar_missao(grupo, 99)
	m.rolar_movimento()
	var destino: Vector2i = m.destinos().keys()[0] if not m.destinos().is_empty() else m.posicao(m.agente_atual())
	m.mover(destino)
	_por_nome(c, "Cléber").pp = 33
	assert_eq(c.salvar(caminho), OK)
	var c2 := Carreira.carregar(caminho)
	assert_not_null(c2)
	assert_eq(c2.roster.size(), 3)
	assert_eq(_por_nome(c2, "Cléber").pp, 33)
	assert_eq(_por_nome(c2, "Bianca").equipamento, _por_nome(c, "Bianca").equipamento)
	var m2 := c2.missao
	assert_not_null(m2)
	assert_eq(m2.mapa.para_dicionario(), m.mapa.para_dicionario())
	assert_eq(m2.membrana.valor, m.membrana.valor)
	assert_eq(m2.turno_mundo, m.turno_mundo)
	assert_eq(m2.posicao(m2.agente_atual()), m.posicao(m.agente_atual()))
	assert_eq(m2.dados.rolar(1000000), m.dados.rolar(1000000), "o gerador continua a mesma sequência")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))


func test_agente_ida_e_volta():
	var a := _por_nome(_carreira(), "Bianca")
	a.sofrer_dano(5)
	a.lesoes.append("for")
	var b := Agente.de_dicionario(rs, a.para_dicionario())
	var da := a.para_dicionario()
	var db := b.para_dicionario()
	for k in da:
		assert_eq(db[k], da[k], k)


# --- Itens em combate ------------------------------------------------------------

func test_cicatrizante():
	var rita := _por_nome(_carreira(), "Rita")
	var c := Combate.new(rs, Dados.new(1))
	var monstro := Ameaca.criar(rs, "M", {"pv": 10})
	c.adicionar(rita)
	c.adicionar(monstro)
	c.dados.forcar([1, 1, 20, 20, 1])
	c.iniciar()
	assert_eq(c.proximo_turno(), rita)
	rita.sofrer_dano(10)
	c.dados.forcar([3, 4])
	assert_eq(c.usar_item(rita, "cicatrizante", rita), 3 + 4 + 2)
	assert_false(rita.tem_item("cicatrizante"))
	assert_eq(c.usar_item(rita, "cicatrizante", rita), -1)


# --- Cena da Base ------------------------------------------------------------------

func test_cena_da_base_abre():
	var jogo = get_node("/root/Jogo")
	jogo.salvar_automaticamente = false
	var antes = jogo.carreira
	jogo.carreira = _carreira()
	var base = load("res://scenes/base_ordem.tscn").instantiate()
	add_child_autofree(base)
	assert_eq(base.carreira.roster.size(), 3)
	jogo.carreira = antes
	jogo.salvar_automaticamente = true


func test_criar_agente_pela_ficha():
	var c := Carreira.nova()
	var ficha := {"nome": "Celeste", "classe": "especialista", "origem": "academico", "nex": 5,
		"atributos": {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		"pericias_livres": ["percepcao", "intuicao", "furtividade", "tecnologia", "medicina", "atualidades", "diplomacia", "reflexos", "vontade", "ocultismo"],
		"perito": ["investigacao", "ciencias"]}
	var res := c.recrutar_ficha(ficha)
	assert_eq(res.erros, [], "ficha válida")
	assert_not_null(res.agente)
	assert_eq(res.agente.nome, "Celeste")
	assert_true(res.agente in c.roster)
	assert_false(res.agente.equipamento.is_empty(), "recebe o kit da classe")
	var de_novo := c.recrutar_ficha(ficha)
	assert_null(de_novo.agente, "nome repetido não pode")
	var ruim := c.recrutar_ficha({"nome": "X", "classe": "combatente", "origem": "academico", "nex": 5, "atributos": {"agi": 3, "for": 3, "int": 3, "pre": 3, "vig": 3}})
	assert_null(ruim.agente)
	assert_false(ruim.erros.is_empty(), "atributos acima dos pontos dão erro")



func test_sem_ficha_respondida_o_caso_fica_em_aberto():
	var c := _carreira()
	var m := c.iniciar_missao(c.roster.duplicate(), 7)
	m.caso.pergunta("quem").respondida = true
	m.inocentes_mortos = 1
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	m.concluir_encontro("agentes")
	assert_true(m.vitoria)
	assert_false(m.caso_solucionado(), "falta o quê na ficha")
	var r := c.encerrar_missao()
	assert_false(r.solucionado)
	assert_eq(r.pp, -2, "sem solução do caso; −2 pelo inocente (Tabela 3.2)")
	assert_true(r.detalhes_pp.any(func(l): return l.begins_with("Caso em aberto")))



func test_so_pistas_alem_das_necessarias_dao_pp():
	var c := _carreira()
	var m := c.iniciar_missao(c.roster.duplicate(), 7)
	for pid in ["quem", "oque"]:
		m.caso.registrar_pista("{indicio}", pid, "t")
		m.caso.registrar_pista("{indicio}", pid, "t")
		m.caso.pergunta(pid).respondida = true
	m.pistas = 9   # eventos e cenas contados no mapa: não viram PP por si
	assert_eq(m.caso.pistas_adicionais(), 0, "duas pistas por pergunta é o necessário")
	m._preparar_encontro(m.mapa.encontrar("objetivo"), "covil", true)
	m.concluir_encontro("agentes")
	var r := c.encerrar_missao()
	assert_eq(r.pp, 10, "só a solução do caso")
