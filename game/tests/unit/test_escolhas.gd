extends GutTest
## Pacote da crítica 20 (docs/21): chance nas escolhas (C2), vez da ameaça (C3) e limpeza (C4).

var rs: RulesetOp2022

const FICHA_CULTISTA := {
	"pv": 12, "defesa": 12, "atributos": {"agi": 1, "for": 1},
	"pericias": {"luta": {"dados": 1, "bonus": 5}},
	"ataques": [{"nome": "Adaga ritual", "dano": "1d4", "margem": 19, "multiplicador": 2, "pericia": "luta", "soma_forca": true}],
}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _combatente(nome := "Cléber") -> Agente:
	return Agente.criar(rs, nome, "combatente", {"agi": 2, "for": 3, "int": 1, "pre": 1, "vig": 2},
		{"luta": "treinado", "fortitude": "treinado"})


# --- C2: chance ----------------------------------------------------------------------

func test_linha_de_teste_formata_dados_e_faixa():
	assert_eq(LinhaTeste.dados(2, 5), "2d20+5")
	assert_eq(LinhaTeste.dados(0, 0), "2d20 (o pior)+0")
	assert_eq(LinhaTeste.chance(0.64), "≈ 64% (provável)")
	assert_eq(LinhaTeste.faixa(0.9), "quase certo")
	assert_eq(LinhaTeste.faixa(0.2), "difícil")
	assert_eq(LinhaTeste.chance(-1.0), "fora de alcance")
	assert_eq(LinhaTeste.melhor([{}, {"chance": 0.3}, {"chance": 0.7}]), 2)
	var t := LinhaTeste.texto("Diplomacia", {"chance": 0.5, "dados": 1, "bonus": 0}, 15)
	assert_eq(t, "Diplomacia · 1d20+0 · DT 15 · ≈ 50% (arriscado)")


func test_previsao_bate_com_o_teste_rolado():
	var a := _combatente()
	var prev := a.prever_teste("luta", 18)
	assert_eq(int(prev.dados), 3)
	assert_eq(int(prev.bonus), a.bonus_pericia("luta"))
	var dados := Dados.new(7)
	var passou := 0
	var n := 3000
	for i in n:
		if Teste.rolar(dados, int(prev.dados), int(prev.bonus), 18).sucesso:
			passou += 1
	assert_almost_eq(float(passou) / n, float(prev.chance), 0.03, "a chance mostrada é a das regras")
	var com_foco := a.prever_teste("luta", 18, 1)
	assert_gt(float(com_foco.chance), float(prev.chance), "Foco soma um dado")
	assert_eq(int(com_foco.dados), 4)


func test_chance_de_acerto_bate_com_o_ataque():
	var c := Combate.new(rs, Dados.new(3))
	var cleber := _combatente()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	var p := c.chance_de_acerto(cleber, cultista, rs.arma("machado"))
	assert_almost_eq(p, 1.0 - pow(1.0 - 14.0 / 20.0, 3), 0.001, "3 d20 de FOR, +5 contra Defesa 12")
	var acertos := 0
	var n := 1500
	for i in n:
		cultista.pv = 12
		if c.atacar(cleber, cultista, rs.arma("machado")).acertou:
			acertos += 1
	assert_almost_eq(float(acertos) / n, p, 0.03)
	assert_gt(c.chance_de_acerto(cleber, cultista, rs.arma("machado"), 0, 5), p - 0.0001, "Ataque Especial não piora")


func test_chance_de_acerto_fora_de_alcance():
	var c := Combate.new(rs, Dados.new(1))
	c.grade = Grade.new(14, 9)
	var cleber := _combatente()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.adicionar(cleber)
	c.adicionar(cultista)
	c.grade.colocar(cleber, Vector2i(0, 0))
	c.grade.colocar(cultista, Vector2i(5, 0))
	assert_eq(c.chance_de_acerto(cleber, cultista, rs.arma("machado")), -1.0, "corpo a corpo longe")


func test_investigacao_preve_com_o_bonus_do_facilitar():
	var m := Missao.nova(42)
	m._preparar_investigacao(m.posicao(m.agente_atual()), "casa_abandonada")
	var cena := m.criar_cena_investigacao()
	var ponto: String = cena.pontos_restantes[0]
	var per: String = cena.ponto(ponto).pericias.keys()[0]
	var antes := cena.prever_procurar(ponto, per)
	assert_true(antes.has("chance"))
	cena._facilitar[cena.agente_atual()] = 2
	var depois := cena.prever_procurar(ponto, per)
	assert_eq(int(depois.bonus), int(antes.bonus) + 2, "o +2 do Facilitar entra na conta")
	var o: Dictionary = cena.cena.facilitar[0]
	assert_true(cena.prever_facilitar(o.id, o.pericias.keys()[0]).has("chance"))
	assert_eq(int(cena.prever_ajudar("percepcao").dt), int(cena._cfg.ajuda.dt))


# --- C3: vez da ameaça ---------------------------------------------------------------

func test_intencao_mira_o_mais_proximo():
	var c := Combate.new(rs, Dados.new(1))
	c.grade = Grade.new(14, 9)
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	var perto := _combatente("Rita")
	var longe := _combatente("Cléber")
	for s in [cultista, perto, longe]:
		c.adicionar(s)
	c.grade.colocar(cultista, Vector2i(0, 0))
	c.grade.colocar(perto, Vector2i(1, 0))
	c.grade.colocar(longe, Vector2i(8, 0))
	var armas := {cultista: rs.arma("desarmado")}
	c.acoes[cultista] = {"padrao": 1, "movimento": 1}   # o que o início do turno dá
	var it := IaCombate.intencao(c, cultista, armas)
	assert_eq(it.alvo, perto)
	assert_eq(it.acao, "atacar")
	c.grade.remover(perto)
	c.grade.colocar(perto, Vector2i(6, 0))
	assert_eq(IaCombate.intencao(c, cultista, armas).acao, "aproximar")


func test_faixa_da_vez_e_mao_que_desce():
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.autoplay = true
	add_child_autofree(arena)
	await wait_frames(2)
	# No autoplay a luta inteira acaba nesses quadros, e a faixa não aparece com a luta
	# encerrada (docs/72): para olhar a faixa, a luta volta a estar em andamento.
	arena.combate.encerrado = false
	var amea: Ser = null
	for s in arena.grade.seres():
		if s is Ameaca:
			amea = s
	arena._mostrar_faixa_vez(amea)
	assert_true(arena._faixa_vez.visible)
	assert_eq(arena._faixa_nome.text, amea.nome.to_upper())
	assert_true(arena._faixa_intencao.text.begins_with("→"), "diz o que a ameaça vai fazer")
	assert_true(arena._mao_abaixada)
	arena._mostrar_faixa_vez(null)
	assert_false(arena._faixa_vez.visible)
	assert_false(arena._mao_abaixada, "a mão volta na vez do jogador")


# --- C4: limpeza ----------------------------------------------------------------------

func test_ficha_sem_nota_de_desenvolvimento():
	var a := _combatente()
	var t := DossieAgente.ficha_bbcode(a)
	assert_false(t.contains("sem efeito no motor"))
	assert_false(t.contains("#6b5a48"), "rótulos com mais contraste")


func test_resumo_do_save_na_tela_de_titulo():
	var c := Carreira.nova()
	var caminho := "user://teste_resumo_save.json"
	c.salvar(caminho)
	assert_eq(Carreira.resumo_save(caminho), "3 agentes · 0 missões concluídas")
	c.iniciar_missao(c.roster.duplicate(), 3)
	c.salvar(caminho)
	assert_true(Carreira.resumo_save(caminho).contains("missão em andamento, turno 1"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
	assert_eq(Carreira.resumo_save(caminho), "")


func test_carimbo_do_fim_nao_cobre_o_botao():
	var r := RelatorioFim.new("Voltar à Base")
	add_child_autofree(r)
	r.mostrar("CASO ENCERRADO", ["Linha 1", "Linha 2"], true)
	await wait_frames(3)
	var carimbo := Rect2(r.rotulo.global_position, r.rotulo.size)
	assert_false(carimbo.intersects(r.botao.get_global_rect()), "o carimbo fica no vão ao lado do botão")


func test_selecao_no_papel_e_dourada():
	var t := Tema.criar()
	var marcado := t.get_stylebox("pressed", "BotaoPapel") as StyleBoxFlat
	assert_eq(marcado.border_color, Tema.OURO_ESCURO)
	assert_eq(t.get_color("font_pressed_color", "BotaoPapel"), Tema.TINTA)
