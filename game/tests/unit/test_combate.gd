extends GutTest
## Combate 1×1: critério de pronto da Fase 1.

var rs: RulesetOp2022

## Ficha de teste criada por nós (não é do livro).
const FICHA_CULTISTA := {
	"pv": 12,
	"defesa": 12,
	"atributos": {"agi": 1, "for": 1},
	"pericias": {"luta": {"dados": 1, "bonus": 5}},
	"ataques": [{"nome": "Adaga ritual", "dano": "1d4", "margem": 19, "multiplicador": 2, "pericia": "luta", "soma_forca": true}],
}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _combatente() -> Agente:
	return Agente.criar(rs, "Mauro", "combatente",
		{"agi": 2, "for": 3, "int": 1, "pre": 1, "vig": 2},
		{"luta": "treinado", "fortitude": "treinado"})


func test_acerto_causa_dano_da_arma_mais_forca():
	var c := Combate.new(rs, Dados.new(1))
	var mauro := _combatente()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.dados.forcar([3, 9, 11, 6])  # 3 slots de FOR: maior 11 (+5 = 16 vs Def 12), dano 1d8 = 6
	var r := c.atacar(mauro, cultista, rs.arma("machado"))
	assert_true(r.acertou)
	assert_false(r.critico)
	assert_eq(r.dano, 6 + 3)
	assert_eq(cultista.pv, 12 - 9)


func test_erro_nao_causa_dano():
	var c := Combate.new(rs, Dados.new(1))
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.dados.forcar([2, 3, 4])
	var r := c.atacar(_combatente(), cultista, rs.arma("machado"))
	assert_false(r.acertou)
	assert_eq(cultista.pv, 12)


func test_critico_multiplica_os_dados():
	var c := Combate.new(rs, Dados.new(1))
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.dados.forcar([1, 1, 20, 5, 6, 7])  # machado x3: 3d8 = 18, +FOR 3
	var r := c.atacar(_combatente(), cultista, rs.arma("machado"))
	assert_true(r.critico)
	assert_eq(r.dano, 18 + 3)


func test_margem_de_ameaca_da_arma():
	var c := Combate.new(rs, Dados.new(1))
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.dados.forcar([1, 1, 19, 2, 3])  # espada margem 19, x2: 2d8 = 5
	var r := c.atacar(_combatente(), cultista, rs.arma("espada"))
	assert_true(r.critico)
	assert_eq(r.dano, 5 + 3)


func test_foco_no_ataque_gasta_pe_e_adiciona_slot():
	var c := Combate.new(rs, Dados.new(1))
	var mauro := _combatente()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.dados.forcar([1, 1, 1, 15, 4])
	var r := c.atacar(mauro, cultista, rs.arma("machado"), 1)
	assert_eq(r.teste.slots.size(), 4)
	assert_true(r.acertou)
	assert_eq(mauro.pe, mauro.pe_maximo - 1)


func test_iniciativa_ordena_do_maior_para_o_menor():
	var c := Combate.new(rs, Dados.new(1))
	var mauro := _combatente()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.adicionar(cultista)
	c.adicionar(mauro)
	# Ordem de rolagem segue a de adicionar(): cultista (1 slot) + desempate, Mauro (2 slots) + desempate.
	c.dados.forcar([3, 10, 18, 4, 10])
	c.iniciar()
	assert_eq(c.ordem[0], mauro)
	assert_eq(c.proximo_turno(), mauro)
	assert_eq(c.proximo_turno(), cultista)
	assert_eq(c.rodada, 1)
	c.proximo_turno()
	assert_eq(c.rodada, 2)


func test_combate_1x1_completo_termina_com_um_vencedor():
	# Combate inteiro com seed fixa: precisa terminar e ter um vencedor.
	var c := Combate.new(rs, Dados.new(2026))
	var mauro := _combatente()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.adicionar(mauro)
	c.adicionar(cultista)
	watch_signals(c)
	c.iniciar()
	var arma_mauro := rs.arma("machado")
	var arma_cultista: Dictionary = cultista.ataques[0]
	var turnos := 0
	while not c.encerrado and turnos < 200:
		var ser := c.proximo_turno()
		if ser == null:
			break
		if ser == mauro:
			c.atacar(mauro, cultista, arma_mauro)
		else:
			c.atacar(cultista, mauro, arma_cultista)
		turnos += 1
	assert_true(c.encerrado, "combate deveria terminar")
	assert_signal_emitted(c, "combate_encerrado")
	assert_ne(c.lado_vencedor(), "")
