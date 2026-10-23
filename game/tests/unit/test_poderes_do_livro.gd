extends GutTest
## Os 10 poderes de classe e os 6 de origem que faltavam (docs/76), com o efeito do livro.

var rs: RulesetOp2022
const FORTE := {"agi": 3, "for": 3, "int": 3, "pre": 3, "vig": 3}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(classe: String, poder := "", pericias := {}, origem := "") -> Agente:
	var a := Agente.criar(rs, "Agente", classe, FORTE, pericias, 20)   # NEX 20: limite de 4 PE por turno
	if poder != "":
		a.poderes.append(poder)
	if origem != "":
		a.origem_id = origem
	a.recalcular_maximos(true)
	return a


func _pessoa(arma := "faca") -> Ameaca:
	var p := Ameaca.criar(rs, "Cultista", {"pv": 30, "defesa": 10, "atributos": {"agi": 1, "for": 1},
		"pericias": {"luta": {"dados": 1, "bonus": 0}}, "ataques": [rs.arma(arma)]})
	p.lado = "ameacas"
	return p


func _combate(seres: Array) -> Combate:
	var c := Combate.new(rs, Dados.new(3))
	c.grade = Grade.new(10, 6)
	var x := 1
	for s in seres:
		c.adicionar(s)
		c.grade.colocar(s, Vector2i(x, 2))
		x += 1
		c.acoes[s] = {"padrao": 1, "movimento": 1}
	return c


# --- Combatente ------------------------------------------------------------------------------

func test_quebrar_e_golpe_demolidor():
	var a := _agente("combatente", "golpe_demolidor", {"luta": "expert"})
	a.equipamento.append("machado")
	a.arma_id = "machado"
	var p := _pessoa("bastao")
	var c := _combate([a, p])
	assert_eq(c.pode_manobrar(a, p, "quebrar"), "", "quebrar é manobra (p.95)")
	assert_eq(c.objeto_da_arma("faca"), {"rd": 10, "pv": 5}, "faca: arma leve de metal (Tabela 4.5)")
	assert_eq(c.objeto_da_arma("bastao"), {"rd": 5, "pv": 5}, "bastão: uma mão, madeira")
	var pe := a.pe
	p.mods_cena["arma_pv"] = 99   # aguenta o primeiro golpe
	c._quebrar_arma(a, p, true)
	assert_eq(a.pe, pe - 1, "Golpe Demolidor custa 1 PE")
	p.mods_cena["arma_pv"] = 1
	c.dados.forcar([8])   # machado 1d8 + For 3 = 11, menos RD 5
	c._quebrar_arma(a, p, false)
	assert_true(p.mods_cena.has("arma_quebrada"), "a 0 PV, a arma quebra")
	assert_eq(String(c.arma_em_maos(p, rs.arma("bastao")).id), "desarmado")
	assert_ne(c.pode_manobrar(a, p, "quebrar"), "", "sem arma na mão, não há o que quebrar")


func test_trocar_arma_custa_movimento_e_saque_rapido_deixa_livre():
	var a := _agente("combatente")
	a.equipamento.append_array(["faca", "machete"])
	a.arma_id = "faca"
	var c := _combate([a, _pessoa()])
	assert_true(c.trocar_arma(a, "machete").ok)
	assert_eq(int(c.acoes_restantes(a).movimento), 0, "sacar é ação de movimento (p.97)")
	assert_eq(a.arma_id, "machete")
	var b := _agente("combatente", "saque_rapido", {"iniciativa": "treinado"})
	b.equipamento.append_array(["faca", "machete"])
	b.arma_id = "faca"
	var c2 := _combate([b, _pessoa()])
	assert_true(c2.trocar_arma(b, "machete").livre)
	assert_eq(int(c2.acoes_restantes(b).movimento), 1, "Saque Rápido: livre")
	assert_false(c2.trocar_arma(b, "espada").ok, "só arma do inventário")


func test_saque_rapido_recarrega_a_besta_de_graca_uma_vez_por_rodada():
	var b := _agente("combatente", "saque_rapido", {"iniciativa": "treinado"})
	var c := _combate([b, _pessoa()])
	var besta := rs.arma("besta")
	b.mods_cena["descarregada"] = "besta"
	assert_true(c.recarga_livre(b, besta))
	assert_eq(c.pode_disparar(b, besta), "")
	b.mods_cena["recarga_livre_rodada"] = c.rodada
	assert_false(c.recarga_livre(b, besta), "uma vez por rodada")
	assert_false(c.recarga_livre(b, rs.arma("bazuca")), "a bazuca é de fogo, não de disparo")


# --- Especialista ----------------------------------------------------------------------------

func test_movimento_tatico_ignora_terreno_dificil_no_combate():
	var a := _agente("especialista", "movimento_tatico", {"atletismo": "treinado"})
	var c := _combate([a])
	for y in 6:
		c.grade.terreno[Vector2i(2, y)] = Grade.DIFICIL
	var sem := int(c.grade.alcancaveis(a, 20).get(Vector2i(3, 2), 99))
	assert_true(c.movimento_tatico(a).ok)
	var com := int(c.grade.alcancaveis(a, 20).get(Vector2i(3, 2), 99))
	assert_lt(com, sem, "o mato não dobra mais o custo")
	c._fim_de_turno(a)
	assert_false(a.mods_cena.has("movimento_tatico"), "vale até o fim do turno")


func test_movimento_tatico_no_mapa():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	a.classe_id = "especialista"
	a.poderes.append("movimento_tatico")
	assert_eq(m.motivo_poder_no_mapa(a, "movimento_tatico"), "")
	assert_true(m.usar_poder_no_mapa("movimento_tatico").ok)
	assert_true(m.pode_escalar, "dá para subir a serra")
	m.mapa.tatico = true
	for h in m.mapa.celulas:
		if m.mapa.passavel(h):
			assert_eq(m.mapa.custo(h), 1)
	m.mapa.tatico = false


func test_mochila_e_ferramenta_favorita_baixam_a_categoria():
	var a := _agente("especialista", "mochila_de_utilidades")
	assert_eq(a.categoria_do_item("lanterna_tatica"), 1)
	assert_true(a.pode_escolher_para_poder("lanterna_tatica"))
	assert_false(a.pode_escolher_para_poder("faca"), "arma não")
	a.escolhas["mochila_de_utilidades"] = "lanterna_tatica"
	assert_eq(a.categoria_do_item("lanterna_tatica"), 0)
	assert_eq(a.espacos_do_item("lanterna_tatica"), 0, "e ocupa 1 espaço a menos")
	var lista := ["bandoleira", "bloqueador_de_sinal"]   # a cota de categoria I do Recruta (2)
	assert_eq(a.motivo_bloqueio("lanterna_tatica", lista), "", "cabe: conta como categoria 0")
	var e := _agente("especialista", "", {}, "engenheiro")
	e.escolhas["ferramenta_favorita"] = "lanterna_tatica"
	assert_eq(e.categoria_do_item("lanterna_tatica"), 0)
	assert_eq(e.espacos_do_item("lanterna_tatica"), 1, "a Favorita não mexe no espaço")


func test_nerd_no_combate_mostra_as_fraquezas():
	var a := _agente("especialista", "nerd", {"atualidades": "expert"})
	var bicho := Ameaca.criar(rs, "Bicho", {"pv": 30, "defesa": 10, "criatura": true, "elemento": "sangue", "vulnerabilidades": ["morte"],
		"atributos": {"agi": 1}})
	bicho.lado = "ameacas"
	var c := _combate([a, bicho])
	var r := c.nerd(a, bicho)
	assert_true(r.ok)
	if r.sucesso:
		assert_string_contains(String(r.texto), "morte", "a vulnerabilidade aparece")
		assert_true(bicho.mods_cena.get("fraquezas_reveladas", false))
	assert_false(c.nerd(a, bicho).ok, "uma vez por cena")
	assert_string_contains(c.fraquezas_de(bicho), "vulnerável a morte")


func test_nerd_e_maos_rapidas_na_investigacao():
	var m := Missao.nova(42)
	m._preparar_investigacao(m.posicao(m.agentes[0]), "casa_abandonada")
	var cena := m.criar_cena_investigacao()
	var a := cena.agente_atual()
	a.classe_id = "especialista"
	a.nex = 20
	a.recalcular_maximos(true)
	a.poderes.append_array(["nerd", "maos_rapidas"])
	a.pericias["atualidades"] = "expert"
	a.pe = a.pe_maximo
	var r := cena.nerd()
	assert_true(r.ok)
	if r.sucesso:
		assert_eq(cena.dica_nerd, 5, "+5 no próximo procurar")
	assert_false(cena.nerd().ok, "uma vez por cena")
	cena.dica_nerd = 0
	assert_true(cena.pode_maos_rapidas(a, "crime"))
	assert_false(cena.pode_maos_rapidas(a, "investigacao"), "só Crime")
	a.pericias["crime"] = "treinado"
	var pe := a.pe
	cena.procurar("porao", "crime", 0, {"maos_rapidas": true})
	assert_eq(cena.agente_atual(), a, "o teste de Crime não gastou a ação")
	assert_eq(a.pe, pe - 1)


# --- Ocultista -------------------------------------------------------------------------------

func _ocultista(poder := "") -> Agente:
	var o := _agente("ocultista", poder, {"ocultismo": "treinado", "investigacao": "expert"})
	o.iniciar_turno()
	o.rituais.append("eletrocussao")
	o.afinidade = ""
	o.pe = o.pe_maximo
	return o


func test_camuflar_ocultismo_conjura_sem_componentes_por_mais_2_pe():
	var o := _ocultista()
	var p := _pessoa()
	var c := _combate([o, p])
	assert_string_contains(c.pode_conjurar(o, "eletrocussao", p), "componentes")
	var cam := _ocultista("camuflar_ocultismo")
	var c2 := _combate([cam, _pessoa()])
	var alvo: Ser = c2.participantes[1]
	assert_eq(cam.custo_camuflar("eletrocussao"), 2)
	assert_eq(c2.pode_conjurar(cam, "eletrocussao", alvo), "")
	var pe := cam.pe
	var r := c2.conjurar(cam, "eletrocussao", alvo)
	if r.ok:
		assert_eq(cam.pe, pe - cam.custo_ritual("eletrocussao") - 2)


func test_selo_criado_no_interludio_e_lido_no_combate():
	assert_eq(int(rs.equipamento("selo:eletrocussao").categoria), 1, "a categoria é o círculo")
	var m := Missao.nova(42)
	var o: Agente = m.agentes[0]
	o.classe_id = "ocultista"
	o.nex = 20
	o.recalcular_maximos(true)
	o.poderes.append("criar_selo")
	o.rituais.append("eletrocussao")
	o.pe = o.pe_maximo
	assert_true("eletrocussao" in m.rituais_para_selo(o))
	var pe := o.pe
	var r := m.interludio({o.id: {"acoes": ["selo"], "selo": "eletrocussao"}})
	if r.ok:
		assert_true("selo:eletrocussao" in o.equipamento)
		assert_eq(o.pe, pe - o.custo_ritual("eletrocussao"))
	# No combate: quem conhece lê sem PE e sem componentes; o selo vira cinza
	var leitor := _ocultista()
	leitor.equipamento.append("selo:eletrocussao")
	var p := _pessoa()
	var c := _combate([leitor, p])
	assert_eq(c.pode_conjurar(leitor, "eletrocussao", p, "", {"selo": "selo:eletrocussao"}), "", "o selo não pede componentes")
	var pe_l := leitor.pe
	var rc := c.conjurar(leitor, "eletrocussao", p, "", {"selo": "selo:eletrocussao"})
	assert_true(rc.ok)
	assert_eq(leitor.pe, pe_l, "sem PE")
	assert_false("selo:eletrocussao" in leitor.equipamento, "o selo se desfaz")


func test_ferramentas_paranormais():
	var o := _ocultista("ferramentas_paranormais")
	assert_eq(o.categoria_do_item("camera_aura"), 1, "categoria II vira I")
	assert_eq(o.custo_pe_do_item("camera_aura", 1), 0, "ativa sem PE")
	assert_eq(o.custo_pe_do_item("faca", 1), 1, "só item paranormal")
	var m := Missao.nova(42)
	var a := m.agente_atual()
	a.classe_id = "ocultista"
	a.poderes.append("ferramentas_paranormais")
	a.equipamento.append("scanner_sangue")
	var pe := a.pe
	assert_false(m.usar_item_de_mapa("scanner_sangue").is_empty())
	assert_eq(a.pe, pe, "o scanner não gastou PE")


func test_improvisar_componentes():
	var o := _ocultista("improvisar_componentes")
	var c := _combate([o, _pessoa()])
	var r := c.improvisar_componentes(o, "energia")
	assert_true(r.ok)
	assert_eq(int(c.acoes_restantes(o).padrao), 0, "ação completa")
	if r.sucesso:
		assert_true(o.tem_componentes("energia"))
		assert_false(o.faltam_componentes("eletrocussao"))
	assert_false(c.improvisar_componentes(o, "energia").ok, "uma vez por cena")


# --- Origens ---------------------------------------------------------------------------------

func test_vislumbres_do_passado_uma_vez_por_missao():
	var m := Missao.nova(42)
	var a := m.agente_atual()
	a.origem_id = "amnesico"
	var r := m.usar_poder_no_mapa("vislumbres")
	assert_true(r.ok)
	if r.sucesso:
		assert_between(a.pe_temporario, 1, 4, "1d4 PE temporários")
	assert_ne(m.motivo_poder_no_mapa(a, "vislumbres"), "", "uma vez por missão")


func test_magnum_opus_numa_testemunha():
	var m := Missao.nova(42)
	var a: Agente = m.agentes[0]
	a.origem_id = "artista"
	m._preparar_investigacao(m.posicao(a), "casa_abandonada")
	var cena := m.criar_cena_investigacao()
	assert_true(a in cena.magnum_opus)
	var vizinha := cena.ponto("vizinha")
	assert_true(cena.pode_magnum_opus(a, vizinha, "diplomacia"))
	assert_false(cena.pode_magnum_opus(a, vizinha, "intuicao") and rs.atributo_da_pericia("intuicao") != "pre", "só perícia de Presença")
	assert_false(cena.pode_magnum_opus(a, cena.ponto("escrivaninha"), "investigacao"), "só testemunha")
	while cena.agente_atual() != a:
		cena.passar()
	cena.procurar("vizinha", "diplomacia", 0, {"magnum_opus": true})
	assert_true(a.id in cena.magnum_opus_usado)
	m.concluir_investigacao(cena.resultado())
	assert_true(a.id in m.magnum_opus_usado, "uma vez por missão")


func test_ingrediente_secreto_dobra_o_prato():
	var m := Missao.nova(42)
	var chef: Agente = m.agentes[0]
	var outro: Agente = m.agentes[1]
	chef.origem_id = "chef"
	for x in [chef, outro]:
		x.san = 1
	var r := m.interludio({chef.id: {"acoes": ["alimentar", "relaxar"], "prato": "favorito"},
		outro.id: {"acoes": ["alimentar", "relaxar"], "prato": "favorito"}})
	assert_true(r.ok)
	var linha := String(r.linhas[1])
	assert_string_contains(linha, "Ingrediente Secreto")


func test_o_crime_compensa():
	var m := Missao.nova(42)
	m._guardar_achados([DadosJogo.ameaca(rs, "iniciado"), DadosJogo.ameaca(rs, "zumbi_de_sangue")])
	assert_eq(m.itens_achados, ["faca"], "só armas de gente")
	var c := Carreira.nova()
	var cr: Agente = c.roster[0]
	cr.origem_id = "criminoso"
	c._fechar_achados(m)
	assert_eq(c.achados, ["faca"])
	assert_eq(c.escolher_item_do_crime(cr, "faca"), "")
	assert_eq(cr.item_do_crime, "faca")
	assert_true("faca" in cr.equipamento)
	assert_true(cr.validar_equipamento(Array(cr.equipamento)).is_empty())
	assert_eq(c.escolher_item_do_crime(cr, "pistola"), "Esse item não foi achado na última missão.")
	m.agentes_iniciais.append(cr)
	c._fechar_achados(m)
	assert_eq(cr.item_do_crime, "", "só valia para uma missão")


func test_patrocinador_da_ordem_e_a_hospedagem():
	var a := _agente("combatente", "", {}, "magnata")
	assert_eq(String(a.patente().credito), "baixo")
	assert_eq(a.credito(), "medio", "um nível acima")
	var b := _agente("combatente")
	assert_eq(b.credito(), "baixo")
	var m := Missao.nova(42)
	var vila := m.mapa.encontrar("vila")
	if m.mapa.tem(vila):
		var ag: Agente = m.agentes[0]
		ag.origem_id = "magnata"
		m.posicoes[ag] = vila
		assert_eq(m.condicao_de(ag), "confortavel", "crédito médio: descanso confortável")
		var outro: Agente = m.agentes[1]
		m.posicoes[outro] = vila
		assert_eq(m.condicao_de(outro), "normal", "crédito baixo: normal")


func test_poderes_marcados_com_efeito():
	for id in ["golpe_demolidor", "saque_rapido"]:
		assert_true(rs.poder("combatente", id).get("implementado", false), id)
	for id in ["maos_rapidas", "mochila_de_utilidades", "movimento_tatico", "nerd"]:
		assert_true(rs.poder("especialista", id).get("implementado", false), id)
	for id in ["camuflar_ocultismo", "criar_selo", "ferramentas_paranormais", "improvisar_componentes"]:
		assert_true(rs.poder("ocultista", id).get("implementado", false), id)
	for o in ["amnesico", "artista", "chef", "criminoso", "engenheiro", "magnata"]:
		assert_true(rs.origem(o).poder.get("implementado", false), o)
