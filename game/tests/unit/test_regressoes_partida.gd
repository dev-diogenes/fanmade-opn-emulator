extends GutTest
## Problemas achados jogando (docs/72). Cada teste reproduz a situação da partida.


func _algum_encontro() -> String:
	return String(DadosJogo.ler("encontros").encontros[0].id)


## Partida do dono do projeto (22/10/2026): a caça alcançou o grupo parado nas ruínas do covil
## ainda fechado; vencer a luta apagava o covil do mapa, e a missão não tinha mais como acabar.
func test_vencer_a_caca_em_cima_do_covil_nao_apaga_o_covil():
	var m := Missao.nova(42)
	var obj := m.mapa.encontrar("objetivo")
	for a in m.agentes:
		m.posicoes[a] = obj
	m._preparar_encontro(obj, _algum_encontro(), false)
	assert_false(m.encontro_pendente.is_empty())
	m.concluir_encontro("agentes")
	assert_eq(String(m.mapa.conteudo(obj).get("tipo", "")), "objetivo", "o covil continua lá")


func test_encontro_vencido_sai_do_mapa():
	var m := Missao.nova(42)
	var h := Vector2i(-999, -999)
	for c in m.mapa.celulas:
		if String(m.mapa.conteudo(c).get("tipo", "")) == "encontro":
			h = c
			break
	assert_true(m.mapa.tem(h))
	for a in m.agentes:
		m.posicoes[a] = h
	m._preparar_encontro(h, String(m.mapa.conteudo(h).encontro), false)
	m.concluir_encontro("agentes")
	assert_true(m.mapa.conteudo(h).is_empty())


## Achado nos testes de docs/72: o fim do combate apagava a marca de rendido, e a arena contava
## zero presos para o interrogatório, mesmo com o cultista desacordado sem morrer.
func test_rendido_continua_rendido_depois_da_luta():
	var rs := RulesetOp2022.carregar_padrao()
	var c := Combate.new(rs, Dados.new(1))
	var a := Agente.criar(rs, "A", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {})
	var p := Ameaca.criar(rs, "Cultista", {"pv": 5, "defesa": 10, "atributos": {"agi": 1}})
	p.lado = "ameacas"
	c.adicionar(a)
	c.adicionar(p)
	p.sofrer_dano_nao_letal(10)
	assert_true(c._verificar_fim())
	assert_eq(c.rendidos().size(), 1)
