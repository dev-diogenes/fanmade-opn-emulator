extends GutTest
## Critério da Fase 4 (docs/02-roadmap.md): 10 seeds seguidas jogáveis sem travar.
## O piloto automático joga cada missão do começo ao fim, só com a IA.

const SEEDS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


func test_dez_seeds_seguidas_sem_travar():
	var vitorias := 0
	for semente in SEEDS:
		var m := Missao.nova(semente)
		var rel := PilotoMissao.jogar(m)
		gut.p("seed %d: %s em %d turnos do mundo, %d combate(s), %d evento(s), %d investigação(ões)" % [
			semente, "vitória" if rel.vitoria else "derrota", rel.turnos_mundo, rel.combates, rel.eventos, rel.investigacoes])
		assert_eq(rel.travou, "", "seed %d travou: %s" % [semente, rel.travou])
		assert_true(rel.encerrada, "seed %d terminou" % semente)
		assert_eq(rel.combates_sem_fim, 0, "seed %d: todo combate termina" % semente)
		if rel.vitoria:
			vitorias += 1
	gut.p("vitórias: %d de %d" % [vitorias, SEEDS.size()])


func test_combate_simulado_termina():
	var m := Missao.nova(3)
	m._preparar_encontro(m.posicao(m.agente_atual()), "emboscada", false)
	var r := PilotoMissao.resolver_combate(m.ruleset, m.encontro_pendente, m.membrana)
	assert_true(r.terminou)
	assert_true(r.vencedor in ["agentes", "ameacas", "nenhum"])


func test_agentes_no_automatico_decifram_o_enigma():
	var m := Missao.nova(4)
	for a in m.agentes:
		a.nex = 60
		a.recalcular_maximos(true)
		m.posicoes[a] = m.posicao(m.agente_atual())
	m._preparar_encontro(m.posicao(m.agente_atual()), "manifestacao_do_medo", false)
	var r := PilotoMissao.resolver_combate(m.ruleset, m.encontro_pendente, m.membrana)
	assert_true(r.terminou, "sem tentar o enigma, a Sombra Sussurrante nunca cairia")
