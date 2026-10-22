extends GutTest
## Limpeza da interface (docs/57): a ★ só com chance boa, a faixa de iniciativa e o alcance por
## contorno no mapa.

var rs: RulesetOp2022

const FICHA := {"pv": 12, "defesa": 12, "atributos": {"agi": 1, "for": 1},
	"pericias": {"luta": {"dados": 1, "bonus": 5}},
	"ataques": [{"nome": "Faca", "dano": "1d4", "margem": 19, "multiplicador": 2, "pericia": "luta", "soma_forca": true}]}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func test_estrela_so_com_cinquenta_por_cento():
	assert_eq(LinhaTeste.recomendada([{"chance": 0.3}, {"chance": 0.45}]), -1, "recomendar 45% é recomendar um erro")
	assert_eq(LinhaTeste.recomendada([{"chance": 0.3}, {"chance": 0.7}]), 1)
	assert_eq(LinhaTeste.recomendada([{}, {"chance": 0.5}]), 1, "50% já leva a estrela")
	assert_eq(LinhaTeste.melhor([{"chance": 0.3}, {"chance": 0.45}]), 1, "a escolhida por padrão segue a de maior chance")


func _combate() -> Combate:
	var c := Combate.new(rs, Dados.new(3))
	c.adicionar(Agente.criar(rs, "Cléber", "combatente", {"agi": 2, "for": 3, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado"}))
	c.adicionar(Agente.criar(rs, "Rita", "ocultista", {"agi": 1, "for": 1, "int": 3, "pre": 2, "vig": 1}, {"ocultismo": "treinado"}))
	c.adicionar(Ameaca.criar(rs, "o Sacerdote Carmesim", FICHA))
	c.iniciar()
	c.proximo_turno()
	return c


func test_proximos_comeca_pela_vez_e_marca_a_rodada_seguinte():
	var c := _combate()
	var lista := c.proximos(5)
	assert_eq(lista.size(), 3, "cada ser uma vez: a faixa mostra uma volta")
	assert_eq(lista[0].ser, c.ser_atual(), "primeiro, quem age agora")
	assert_false(lista[0].nova_rodada)
	c.proximo_turno()
	lista = c.proximos(5)
	assert_eq(lista[0].ser, c.ser_atual())
	assert_true(lista[2].nova_rodada, "o primeiro da ordem já age na rodada seguinte")
	assert_eq(lista.filter(func(x): return x.nova_rodada).size(), 1, "a virada aparece uma vez")


func test_proximos_pula_os_mortos():
	var c := _combate()
	var morto: Ser = c.ordem[(c.ordem.find(c.ser_atual()) + 1) % c.ordem.size()]
	morto.condicoes[Ser.MORTO] = true
	var seres: Array = c.proximos(5).map(func(x): return x.ser)
	assert_false(morto in seres)
	assert_eq(seres.size(), 2)


func test_faixa_mostra_a_vez_e_as_cores():
	var c := _combate()
	var faixa := FaixaIniciativa.new()
	add_child_autofree(faixa)
	faixa.atualizar(c, {})
	var fichas := faixa.get_children().filter(func(n): return n is PanelContainer)
	assert_eq(fichas.size(), 3)
	assert_string_contains(fichas[0].tooltip_text, "age agora")
	var textos: Array = faixa.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.any(func(t): return String(t).contains("Sacerdote Carmesim")), "sem o artigo")
	c.encerrado = true
	faixa.atualizar(c, {})
	assert_false(faixa.visible, "combate encerrado: a faixa some")


func test_nome_curto():
	assert_eq(FaixaIniciativa.nome_curto("o Sacerdote Carmesim"), "Sacerdote Carmesim")
	assert_eq(FaixaIniciativa.nome_curto("Cultista da Seita Dourada"), "Cultista da Seita…")
	assert_eq(FaixaIniciativa.nome_curto("Cléber"), "Cléber")


func test_contorno_do_hex_e_um_anel():
	var anel := Pecas.contorno_hex(1.0, 0.1, Color.CYAN)
	var arr: Array = anel.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	assert_eq(verts.size(), 36, "6 lados, 2 triângulos cada")
	for v in verts:
		assert_between(Vector2(v.x, v.z).length(), 0.89, 1.01, "só a borda: o miolo fica vazio")
	anel.free()
