extends GutTest
## Frases curtas (docs/75, AG6): o agente fala conforme o estado, sem mudar regra.

var rs: RulesetOp2022
const ATTRS := {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(nome: String, classe := "combatente") -> Agente:
	return Agente.criar(rs, nome, classe, ATTRS, {})


func _combate(seres: Array) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	for s in seres:
		c.adicionar(s)
	return c


func test_fala_pela_classe_e_pelo_estado():
	var a := _agente("Rita", "ocultista")
	var lista: Array = DadosJogo.ler("falas").estados.ferido.ocultista
	assert_true(Falas.de(a, "ferido", 0) in lista)
	var b := _agente("Cléber")
	for n in 6:   # troca o {nome}
		assert_false(Falas.de(b, "aliado_caiu", n, {"nome": "Rita"}).contains("{nome}"))
	assert_true(Falas.de(a, "fobia", 0, {"elemento": "sangue"}) in DadosJogo.ler("traumas").fobias.sangue.frases)
	assert_eq(Falas.de(a, "fobia", 0, {"elemento": "nada"}), "")


func test_cada_classe_tem_fala_em_cada_estado():
	var d: Dictionary = DadosJogo.ler("falas").estados
	for estado in ["ferido", "perturbado", "aliado_caiu"]:
		for classe in ["combatente", "especialista", "ocultista", "mundano", "geral"]:
			assert_false((d[estado].get(classe, []) as Array).is_empty(), "%s/%s" % [estado, classe])


func test_estado_mais_urgente_primeiro():
	var a := _agente("Bianca", "especialista")
	assert_eq(Falas.estado_de(a), "")
	a.pv = a.pv_maximo / 2
	assert_eq(Falas.estado_de(a), "ferido")
	a.san = a.san_maximo / 2
	assert_eq(Falas.estado_de(a), "perturbado")


func test_ferido_fala_uma_vez_por_cena():
	var a := _agente("Cléber")
	var c := _combate([a])
	var falas := []
	c.fala.connect(func(s, t): falas.append([s, t]))
	c.aplicar_dano(a, a.pv - a.pv_maximo / 2 + 1)
	assert_eq(falas.size(), 1)
	assert_eq(falas[0][0], a)
	assert_true(String(falas[0][1]) in DadosJogo.ler("falas").estados.ferido.combatente)
	c.aplicar_dano(a, 1)
	assert_eq(falas.size(), 1, "não repete na mesma cena")
	a.encerrar_cena()
	c.aplicar_dano(a, 1)
	assert_eq(falas.size(), 2, "cena nova, fala de novo")


func test_perturbado_pelo_dano_mental():
	var a := _agente("Rita", "ocultista")
	var c := _combate([a])
	var falas := []
	c.fala.connect(func(s, t): falas.append(t))
	c.aplicar_dano(a, a.san - a.san_maximo / 2, "mental")
	assert_eq(falas.size(), 1)
	assert_true(String(falas[0]) in DadosJogo.ler("falas").estados.perturbado.ocultista)


func test_aliado_caido_faz_outro_falar():
	var a := _agente("Cléber")
	var b := _agente("Bianca", "especialista")
	var c := _combate([a, b])
	var falas := []
	c.fala.connect(func(s, t): falas.append([s, t]))
	c.aplicar_dano(a, 999)
	assert_true(a.esta_fora_de_combate())
	assert_eq(falas.size(), 1)
	assert_eq(falas[0][0], b, "quem fala é o aliado de pé")
	assert_false(String(falas[0][1]).contains("{nome}"))


func test_fobia_fala_no_inicio():
	var a := _agente("Bianca", "especialista")
	a.traumas.append({"elemento": "sangue", "missao": 1})
	var bicho := Ameaca.criar(rs, "Bicho", {"pv": 30, "defesa": 10, "criatura": true, "elemento": "sangue", "atributos": {"agi": 1}})
	bicho.lado = "ameacas"
	var c := _combate([a, bicho])
	var falas := []
	c.fala.connect(func(s, t): falas.append(t))
	c.iniciar()
	assert_true(falas.size() >= 1)
	assert_true(String(falas[0]) in DadosJogo.ler("traumas").fobias.sangue.frases)


func test_no_mapa_fala_no_comeco_da_vez_e_de_novo_depois_de_curar():
	var m := Missao.nova(42)
	var falas := []
	m.fala.connect(func(a, t): falas.append([a, t]))
	var a := m.agente_atual()
	a.pv = a.pv_maximo / 2
	m._falas_no_mapa(a)
	m._falas_no_mapa(a)
	assert_eq(falas.size(), 1, "uma vez por estado")
	a.pv = a.pv_maximo
	m._falas_no_mapa(a)
	a.pv = 1
	m._falas_no_mapa(a)
	assert_eq(falas.size(), 2, "curou e se feriu de novo")


func test_sussurros_da_fobia_nas_alucinacoes():
	var a := _agente("Rita", "ocultista")
	assert_true(Alucinacoes.frases_do_efeito(a).is_empty())
	a.traumas.append({"elemento": "morte", "missao": 1})
	var frases := Alucinacoes.frases_do_efeito(a)
	for f in DadosJogo.ler("traumas").fobias.morte.frases:
		assert_true(f in frases)
