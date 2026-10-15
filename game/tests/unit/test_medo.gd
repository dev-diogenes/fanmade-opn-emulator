extends GutTest
## Medo como ameaça (V1): Presença Perturbadora, Enigma de Medo (p.190) e a Membrana fraca.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(nex: int) -> Agente:
	return Agente.criar(rs, "Agente", "ocultista", {"agi": 1, "for": 1, "int": 2, "pre": 2, "vig": 2}, {"ocultismo": "treinado", "vontade": "treinado"}, nex)


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func test_presenca_perturbadora_usa_a_maior_criatura():
	var c := Combate.new(rs, Dados.new(1))
	var novato := _agente(5)
	var veterano := _agente(50)
	for s in [novato, veterano, _ameaca("cria_de_sangue"), _ameaca("aberracao")]:
		c.adicionar(s)
	var san := novato.san
	c.dados.forcar([4, 4, 6, 1, 1])   # Aberração (maior VD): 2d4 + 1d6 por criatura a mais; Vontade falha
	var r := c.presenca_perturbadora()
	assert_eq(novato.san, san - 14)
	assert_eq(veterano.san, veterano.san_maximo, "NEX 50% é imune à presença da Aberração")
	assert_true(r[1].imune)


func test_presenca_metade_ao_passar():
	var c := Combate.new(rs, Dados.new(1))
	var a := _agente(5)
	c.adicionar(a)
	c.adicionar(_ameaca("cria_de_sangue"))
	var san := a.san
	c.dados.forcar([5, 20, 20])
	c.presenca_perturbadora()
	assert_eq(a.san, san - 2)


func test_presenca_so_com_a_regra_ligada():
	var c := Combate.new(rs, Dados.new(1), {"presenca_perturbadora": true})
	var a := _agente(5)
	c.adicionar(a)
	c.adicionar(_ameaca("horror_carmesim"))
	c.iniciar()
	assert_lt(a.san, a.san_maximo)


func test_enigma_de_medo():
	var c := Combate.new(rs, Dados.new(1))
	var sombra := _ameaca("sombra_sussurrante")
	var a := _agente(5)
	assert_eq(sombra.elemento, "medo")
	assert_true(sombra.enigma_pendente())
	assert_eq(c.aplicar_dano(sombra, 30, "corte"), 0, "nada a fere antes do enigma")
	c.dados.forcar([1, 1])
	assert_false(c.decifrar_enigma(a, sombra).sucesso)
	c.dados.forcar([20, 20])
	assert_true(c.decifrar_enigma(a, sombra).sucesso)
	assert_false(sombra.enigma_pendente())
	assert_eq(c.aplicar_dano(sombra, 10, "corte"), 10)
	assert_null(c.decifrar_enigma(a, sombra), "já decifrado")


func test_pistas_facilitam_o_enigma():
	var c := Combate.new(rs, Dados.new(1), {"bonus_enigma": 10})
	var sombra := _ameaca("sombra_sussurrante")
	c.dados.forcar([7, 7])   # 7 + 5 = 12 contra DT 22 − 10
	assert_true(c.decifrar_enigma(_agente(5), sombra).sucesso)


func test_membrana_rompendo_ataca_a_sanidade():
	var m := Missao.nova(42)
	m.membrana.valor = 40   # Fina: ainda não ataca
	var antes: Array = m.agentes.map(func(a): return a.san)
	m.dados.forcar([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	m._ataque_a_sanidade()
	assert_eq(m.agentes.map(func(a): return a.san), antes)
	m.membrana.valor = 10   # Rompendo
	m._ataque_a_sanidade()
	for i in m.agentes.size():
		assert_lt(m.agentes[i].san, antes[i])


func test_eventos_e_encontro_de_medo():
	var m := Missao.nova(42)
	assert_false(m._evento("reflexo_errado").is_empty())
	var ids: Array = DadosJogo.ler("encontros").encontros.map(func(e): return e.id)
	assert_true("manifestacao_do_medo" in ids)
	var ids_mapa: Array = DadosJogo.ler("eventos").eventos.map(func(e): return e.id)
	assert_false("reflexo_errado" in ids_mapa, "eventos de Medo não entram no mapa gerado")
