extends GutTest
## Medo no mapa (docs/53): noite, caçada com alívio, rastros, linha do tempo e rumo do caso.

var m: Missao


func before_each():
	m = Missao.nova(42)


## Um hex livre e transitável, longe do início, e outro a `dist` dele de onde dá para andar até ele.
func _par_livre(dist: int) -> Array:
	var inicio := m.mapa.encontrar("inicio")
	for x in m.mapa.celulas:
		if Hex.distancia(x, inicio) < 4 or not m.mapa.passavel(x) or not m.mapa.conteudo(x).is_empty():
			continue
		for y in Hex.area(x, dist):
			if Hex.distancia(x, y) != dist or not m.mapa.tem(y) or not m.mapa.passavel(y) or not m.mapa.conteudo(y).is_empty():
				continue
			if m._passo_para(y, x) != y:
				return [x, y]
	return []


func _noite() -> void:
	m.turno_mundo = 4   # 3 de dia, 2 de noite: o 4º turno é noite


func test_ciclo_de_dia_e_noite():
	assert_false(m.eh_noite(1))
	assert_false(m.eh_noite(3))
	assert_true(m.eh_noite(4))
	assert_true(m.eh_noite(5))
	assert_false(m.eh_noite(6), "amanhece")


func test_quem_surge_caca():
	m.membrana.valor = 60
	m._surgir_ameaca()
	var achou := false
	for h in m.mapa.celulas:
		if m.mapa.conteudo(h).get("caca", false):
			achou = true
	assert_true(achou, "a ameaça que surge é marcada para caçar")


func test_a_noite_a_ameaca_anda_ate_o_isolado_e_deixa_rastro():
	var par := _par_livre(3)
	assert_false(par.is_empty())
	var x: Vector2i = par[0]
	var y: Vector2i = par[1]
	var mauro := m.agentes[0]
	m.posicoes[mauro] = x
	m.mapa.definir_conteudo(y, {"tipo": "encontro", "encontro": "cria_solitaria", "caca": true})
	m._cacar()
	assert_false(m.mapa.conteudo(y).is_empty(), "de dia, fica onde está")
	_noite()
	m._cacar()
	assert_true(m.mapa.conteudo(y).is_empty(), "à noite, anda")
	assert_true(m.rastros.has(y), "e deixa rastro")
	var meus := m.passos_da_caca.filter(func(p): return p.de == y)   # as criaturas do mapa também caçam
	assert_eq(meus.size(), 1)
	var novo: Vector2i = meus[0].para
	assert_eq(Hex.distancia(novo, x), 2, "um passo mais perto")
	assert_true(m.mapa.conteudo(novo).get("caca", false))


func test_alcancar_comeca_o_encontro_e_o_combate_da_respiro():
	var par := _par_livre(1)
	var x: Vector2i = par[0]
	var y: Vector2i = par[1]
	var mauro := m.agentes[0]
	m.posicoes[mauro] = x
	m.mapa.definir_conteudo(y, {"tipo": "encontro", "encontro": "cria_solitaria", "caca": true})
	_noite()
	m._cacar()
	assert_false(m.encontro_pendente.is_empty(), "alcançou: começa o encontro")
	assert_eq(m.encontro_pendente.hex, x)
	assert_true(mauro in m.encontro_pendente.agentes)
	m.concluir_encontro("agentes")
	assert_eq(m.alivio, 1, "depois do pico, um turno de respiro")
	var par2 := _par_livre(3)
	m.posicoes[mauro] = par2[0]
	m.mapa.definir_conteudo(par2[1], {"tipo": "encontro", "encontro": "cria_solitaria", "caca": true})
	m._cacar()
	assert_false(m.mapa.conteudo(par2[1]).is_empty(), "no turno de alívio, nada caça")
	assert_eq(m.alivio, 0)


func test_vila_e_segura():
	var vila := m.mapa.encontrar("inicio")
	for a in m.agentes:
		m.posicoes[a] = vila
	assert_null(m._presa_perto(vila, 6), "no ponto de encontro, ninguém é presa")


func test_previsao_da_linha_do_tempo():
	m.membrana.valor = 77
	var p := m.previsao(5)
	assert_eq(p.size(), 5)
	assert_eq(int(p[0].turno), m.turno_mundo + 1)
	assert_true(p[0].eventos.any(func(e): return e.id == "membrana"), "77 -> 75: a Membrana fica instável")
	assert_true(p.any(func(t): return t.noite), "a noite aparece na linha do tempo")
	m.membrana.valor = 2
	assert_true(m.previsao(2).any(func(t): return t.eventos.any(func(e): return e.id == "rompe")))


func test_progresso_do_caso_conta_duas_por_pergunta():
	assert_eq(m.progresso_do_caso(), {"firmes": 0, "necessarias": 6})
	for i in 3:
		m.caso.registrar_pista("{indicio}", "quem", "t")
	m.caso.registrar_pista("{indicio}", "onde", "t")
	assert_eq(int(m.progresso_do_caso().firmes), 3, "quem conta até 2, onde 1")


func test_rumo_do_caso_aponta_a_nevoa():
	for h in m.mapa.celulas:
		var tipo := String(m.mapa.conteudo(h).get("tipo", ""))
		if tipo in ["investigacao", "evento"] and m.mapa.revelado(h):
			m.mapa.limpar_conteudo(h)
	var rumo := m.rumo_do_caso()
	assert_ne(rumo, "", "sem pista à vista, há um rumo")
	assert_true(rumo.begins_with("a ") or rumo.begins_with("ao ") or rumo == "por perto")
	assert_eq(Missao.direcao_em_texto(Vector2(1, 0)), "a leste")
	assert_eq(Missao.direcao_em_texto(Vector2(0, -1)), "ao norte")


func test_covil_selado_avisa_uma_vez_por_turno():
	var obj := m.mapa.encontrar("objetivo")
	var mauro := m.agentes[0]
	m._entrar(mauro, obj)
	var n := m.historico.size()
	m._entrar(mauro, obj)
	assert_eq(m.historico.size(), n, "o mesmo aviso não se repete no turno")


func test_rastros_e_alivio_no_save():
	m.rastros[Vector2i(2, 3)] = 4
	m.alivio = 1
	var por_id := {}
	for a in m.agentes_iniciais:
		por_id[a.id] = a
	var m2 := Missao.de_dicionario(m.ruleset, JSON.parse_string(JSON.stringify(m.para_dicionario())), por_id)
	assert_eq(m2.rastros, {Vector2i(2, 3): 4})
	assert_eq(m2.alivio, 1)


func test_mapa_mostra_a_linha_do_tempo_e_o_caso():
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	for c in get_tree().root.find_children("*", "", true, false):
		if c is DialogoPapel or c is TourGuiado:
			c.queue_free()
	assert_eq(tela._linha_tempo.get_child_count(), 5, "cinco turnos à frente")
	assert_string_contains(tela._lbl_membrana.text, "Caso ")
