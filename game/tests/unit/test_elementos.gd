extends GutTest
## Elementos (docs/54): cada um caça de um jeito, tem cor e presságio no mundo e som próprio.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func _agente(nome: String) -> Agente:
	var a := Agente.criar(rs, nome, "combatente", {"agi": 1, "for": 2, "int": 1, "pre": 1, "vig": 2}, {})
	a.lado = "agentes"
	return a


func _combate(criatura: String) -> Array:
	var c := Combate.new(rs, Dados.new(1))
	c.grade = Grade.new(14, 9)
	var am := _ameaca(criatura)
	var perto := _agente("Perto")
	var longe := _agente("Longe")
	for s in [am, perto, longe]:
		c.adicionar(s)
	c.grade.colocar(am, Vector2i(0, 0))
	c.grade.colocar(perto, Vector2i(1, 0))
	c.grade.colocar(longe, Vector2i(6, 0))
	return [c, am, perto, longe]


func test_sangue_e_cego_e_vai_em_quem_se_mexeu():
	var r := _combate("zumbi_de_sangue")
	var c: Combate = r[0]
	var longe: Agente = r[3]
	longe.mods_cena["moveu_na_rodada"] = c.rodada
	assert_eq(IaAmeaca.alvo_preferido(c, r[1], r[2]), longe, "o mais perto ficou parado; o de longe se mexeu")
	longe.mods_cena.erase("moveu_na_rodada")
	assert_eq(IaAmeaca.alvo_preferido(c, r[1], r[2]), r[2], "ninguém se mexeu: o mais perto")


func test_conhecimento_mira_a_mente_mais_fragil():
	var r := _combate("existido")
	var longe: Agente = r[3]
	longe.san = 1
	assert_eq(IaAmeaca.alvo_preferido(r[0], r[1], r[2]), longe)


func test_energia_escolhe_ao_acaso_igual_no_online():
	var r := _combate("anarquico")
	var c: Combate = r[0]
	var vistos := {}
	for rodada in range(1, 13):
		c.rodada = rodada
		var a := IaAmeaca.alvo_do_elemento(c, r[1], r[2])
		assert_eq(a, IaAmeaca.alvo_do_elemento(c, r[1], r[2]), "a mesma rodada, o mesmo alvo")
		vistos[a] = true
	assert_eq(vistos.size(), 2, "ao longo das rodadas, os dois viram alvo")


func test_morte_para_no_tempo_de_vez_em_quando():
	var r := _combate("esqueleto_de_lodo")
	var c: Combate = r[0]
	var paradas := 0
	for rodada in range(1, 31):
		c.rodada = rodada
		if IaAmeaca.parado_no_tempo(c, r[1]):
			paradas += 1
	assert_between(paradas, 4, 18, "mais ou menos uma rodada em cada três")
	assert_false(IaAmeaca.parado_no_tempo(c, _ameaca("zumbi_de_sangue")), "só a Morte")


func test_combate_marca_quem_se_mexeu():
	var r := _combate("zumbi_de_sangue")
	var c: Combate = r[0]
	var perto: Agente = r[2]
	var destino := Vector2i(-1, -1)
	for cel in c.grade.alcancaveis(perto, maxi(1, perto.deslocamento_quadrados())):
		if cel != c.grade.posicao(perto) and c.grade.ocupante(cel) == null:
			destino = cel
			break
	c.mover(perto, destino)   # fora de um turno não gasta ação, mas tentar se mexer já faz barulho
	assert_eq(int(perto.mods_cena.get("moveu_na_rodada", -9)), c.rodada)


func test_pressagios_e_cores_por_elemento():
	assert_eq(Tema.ESPECTRO_ENERGIA.size(), 5, "Energia é um espectro neon (wiki)")
	for el in ["sangue", "morte", "conhecimento", "energia", "medo"]:
		var p := Pecas.pressagio(el)
		assert_gt(p.get_child_count(), 0, el)
		p.free()
	var e := Pecas.pressagio("energia")
	assert_true(e.get_children().any(func(n): return n is OmniLight3D), "o poste pisca em neon")
	e.free()


func test_sons_dos_elementos():
	for el in ["sangue", "morte", "conhecimento", "energia", "medo"]:
		var w := Som.gerar("el_" + el)
		assert_gt(w.data.size(), 20000, el)


func test_mapa_poe_o_pressagio_perto_da_criatura():
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	for c in get_tree().root.find_children("*", "", true, false):
		if c is DialogoPapel or c is TourGuiado:
			c.queue_free()
	var m: Missao = tela.missao
	var alvo := Vector2i(-999, -999)
	for h in m.mapa.celulas:
		var c := m.mapa.conteudo(h)
		if String(c.get("tipo", "")) == "encontro" and m.elemento_de(String(c.encontro)) != "":
			alvo = h
			break
	assert_ne(alvo, Vector2i(-999, -999), "há uma criatura no mapa")
	m.mapa.revelar(alvo, 1)
	tela._mapa3d.atualizar_pressagios(m)
	assert_true(tela._mapa3d._pressagios.has(alvo), "o presságio aparece num vizinho revelado")
