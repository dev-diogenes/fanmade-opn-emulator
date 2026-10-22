extends GutTest
## Contato da Pesquisa e mapa de rumores (docs/61, IN5) e o som em duas camadas (AU1).


## Missão com só a pergunta `pid` em aberto (as outras respondidas), para seguir as camadas dela.
func _missao_numa_pergunta(pid: String) -> Missao:
	var m := Missao.nova(42)
	for q in m.caso.perguntas:
		if q.id != pid:
			q.respondida = true
	return m


func test_camada_1_orienta_e_gasta_a_acao():
	var m := _missao_numa_pergunta("quem")
	var p := m.proxima_pesquisa()
	assert_eq(p.pergunta, "quem")
	assert_eq(p.camada, 1)
	var r := m.ligar_pesquisa()
	assert_true(r.ok)
	assert_true(m.acao_usada, "a orientação custa a ação do turno")
	assert_string_contains(r.texto, "quem está por trás")
	assert_string_contains(m.historico.back(), "Pesquisa")


func test_camada_1_sem_acao_nao_liga():
	var m := _missao_numa_pergunta("quem")
	m.acao_usada = true
	assert_false(m.ligar_pesquisa().ok)
	assert_false(m.pesquisa.has("quem"), "nada foi gasto")


func test_camada_2_descarta_um_errado_e_faz_ruido():
	var m := _missao_numa_pergunta("quem")
	m.ligar_pesquisa()
	m.acao_usada = false
	var antes := m._turnos_sem_surgimento
	var compat_antes := m.caso.compativeis("quem").size()
	var p := m.proxima_pesquisa()
	assert_eq(p.camada, 2)
	var r := m.ligar_pesquisa()
	assert_true(r.ok)
	var desc: Array = m.caso.pergunta("quem").descartados
	assert_eq(desc.size(), 1)
	assert_ne(desc[0], m.caso.verdadeiro("quem").id, "a Pesquisa nunca descarta o culpado")
	assert_eq(m.caso.compativeis("quem").size(), compat_antes - 1)
	assert_eq(m._turnos_sem_surgimento, antes + 1, "ruído: o surgimento chega mais cedo")
	var outra := _missao_numa_pergunta("quem")
	outra.ligar_pesquisa()
	outra.ligar_pesquisa()
	assert_eq(outra.caso.pergunta("quem").descartados, desc, "a mesma semente descarta o mesmo (online)")


func test_camada_3_da_pista_firme_e_custa_membrana():
	var m := _missao_numa_pergunta("onde")
	m.pesquisa["onde"] = 2
	var membrana := m.membrana.valor
	var firmes := m.caso.indicios_encontrados("onde").size()
	var r := m.ligar_pesquisa()
	assert_eq(r.camada, 3)
	assert_eq(m.caso.indicios_encontrados("onde").size(), firmes + 1, "um traço verdadeiro, firme")
	assert_eq(m.membrana.valor, membrana - 5)
	assert_eq(m.rumores.size(), 1, "a ficha também vira rumor no mapa")
	assert_true(m.proxima_pesquisa().is_empty(), "a Pesquisa já mandou tudo sobre a única pergunta aberta")


func test_sem_o_que_descartar_vai_direto_a_ficha():
	var m := _missao_numa_pergunta("quem")
	m.pesquisa["quem"] = 1
	var certo := String(m.caso.verdadeiro("quem").id)
	var desc: Array = []
	for c in m.caso.candidatos("quem"):
		if c.id != certo:
			desc.append(c.id)
	m.caso.pergunta("quem").descartados = desc
	assert_eq(m.proxima_pesquisa().camada, 3)


func test_regiao_dos_rumores_encolhe_e_contem_o_covil():
	var m := Missao.nova(42)
	var obj := m.mapa.encontrar("objetivo")
	assert_true(m.regiao_dos_rumores().is_empty(), "sem pistas, nada")
	var hexes: Array = m.mapa.celulas.keys()
	m._anotar_rumor(hexes[0])
	m._anotar_rumor(hexes[0])
	assert_eq(m.rumores.size(), 1, "o mesmo lugar conta uma vez")
	assert_true(m.regiao_dos_rumores().is_empty(), "uma pista não aponta lugar nenhum")
	m._anotar_rumor(hexes[1])
	var r := m.regiao_dos_rumores()
	assert_eq(r.raio, 3)
	assert_true(Hex.distancia(r.centro, obj) <= r.raio, "o covil está dentro da região")
	assert_eq(r.origens.size(), 2)
	m._anotar_rumor(hexes[2])
	m._anotar_rumor(hexes[3])
	r = m.regiao_dos_rumores()
	assert_eq(r.raio, 1, "quatro pistas: a região aperta")
	assert_true(Hex.distancia(r.centro, obj) <= 1)
	m.caso.pergunta("onde").respondida = true
	assert_true(m.regiao_dos_rumores().is_empty(), "covil localizado: o ponto de interrogação sai")


func test_pesquisa_e_rumores_no_save():
	var m := _missao_numa_pergunta("quem")
	m.ligar_pesquisa()
	m._anotar_rumor(Vector2i(2, 3))
	var por_id := {}
	for a in m.agentes_iniciais:
		por_id[a.id] = a
	var m2 := Missao.de_dicionario(m.ruleset, JSON.parse_string(JSON.stringify(m.para_dicionario())), por_id)
	assert_eq(int(m2.pesquisa.get("quem", 0)), 1)
	assert_true([2, 3] in m2.rumores)


func test_comando_pesquisa():
	var m := _missao_numa_pergunta("quem")
	var res := Comandos.aplicar_mapa(m, Comandos.novo("mapa", "pesquisa"))
	assert_true(res.ok)
	assert_eq(res.pesquisa.camada, 1)


func test_mapa_desenha_fios_e_o_ponto_de_interrogacao():
	var m := Missao.nova(42)
	var m3d := Mapa3D.new()
	add_child_autofree(m3d)
	m3d.construir(m.mapa, DadosJogo.ler("mapa").terrenos)
	var hexes: Array = m.mapa.celulas.keys()
	m._anotar_rumor(hexes[0])
	m._anotar_rumor(hexes[5])
	m3d.atualizar_rumores(m.regiao_dos_rumores())
	var rumores: Node3D = m3d.find_child("Rumores", true, false)
	assert_not_null(rumores)
	assert_eq(rumores.find_children("*", "Label3D", true, false).map(func(l): return l.text), ["?"])
	assert_gt(rumores.find_children("*", "MeshInstance3D", true, false).size(), 2, "fios tracejados e o anel")
	m3d.atualizar_rumores({})
	await get_tree().process_frame
	assert_null(m3d.find_child("Rumores", true, false))


func test_som_em_duas_camadas():
	assert_eq(Som.volume_da_realidade(0.0), -20.0, "Membrana inteira: o piano se ouve")
	assert_eq(Som.volume_da_realidade(0.7), -60.0, "o Outro Lado domina: a Realidade cala")
	assert_true(Som.volume_da_realidade(0.3) < -20.0 and Som.volume_da_realidade(0.3) > -60.0)
	assert_gt(Som.gerar("piano").data.size(), 1000)
