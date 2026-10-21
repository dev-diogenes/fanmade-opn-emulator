extends GutTest
## Ficha no formato da ficha oficial (docs/25): três páginas, perícias completas, Defesa com a
## conta e a página de rituais otimizada (só os conhecidos, já preenchidos).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _rituais_de_elementos_diferentes(n: int) -> Array:
	var ids: Array = []
	var vistos: Array = []
	for r in rs.dados.rituais.rituais:
		if int(r.circulo) == 1 and not String(r.elemento) in vistos:
			ids.append(String(r.id))
			vistos.append(String(r.elemento))
		if ids.size() == n:
			break
	return ids


func test_tres_paginas_como_a_oficial():
	var a := Agente.criar(rs, "Mauro", "combatente", {"agi": 1, "for": 3, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado"})
	var f := FichaAgente.new()
	add_child_autofree(f)
	f.mostrar(a)
	assert_eq(f.get_tab_count(), 3)
	assert_eq(f.get_tab_title(0), "Agente")
	assert_eq(f.get_tab_title(1), "Habilidades e inventário")
	assert_eq(f.get_tab_title(2), "Rituais")


func test_pericias_completas_e_defesa_com_a_conta():
	var a := Agente.criar(rs, "Mauro", "combatente", {"agi": 1, "for": 3, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado"})
	var f := FichaAgente.new()
	add_child_autofree(f)
	f.mostrar(a)
	var textos: Array = f.pagina_agente.find_children("*", "Label", true, false).map(func(l): return l.text)
	for p in rs.dados.pericias.pericias:
		assert_true(textos.any(func(t): return t.begins_with(String(p.nome))), "a perícia %s está na tabela" % p.nome)
	assert_true(textos.any(func(t): return t.begins_with("= ") and t.contains("AGI")), "Defesa com a conta da ficha")
	assert_true(textos.has(str(a.defesa())))


func test_rituais_otimizados():
	var a := Agente.criar(rs, "Rita", "ocultista", {"agi": 1, "for": 1, "int": 2, "pre": 3, "vig": 1})
	for rid in _rituais_de_elementos_diferentes(3):
		a.rituais.append(rid)
	var f := FichaAgente.new()
	add_child_autofree(f)
	f.mostrar(a)
	var cartoes := f.pagina_rituais.find_children("*", "PanelContainer", true, false).filter(func(p): return p.custom_minimum_size.x == 500.0)
	assert_eq(cartoes.size(), 3, "um cartão por ritual conhecido, sem cartões em branco")
	var textos: Array = f.pagina_rituais.find_children("*", "Label", true, false).map(func(l): return l.text)
	var rid: String = a.rituais[0]
	assert_true(textos.has("%dº · %d PE" % [int(rs.ritual(rid).circulo), a.custo_ritual(rid)]), "custo calculado")
	assert_true(textos.has("DT %d" % a.dt_ritual(rid)), "DT calculada")
	f.filtro_elemento = String(rs.ritual(rid).elemento)
	f.mostrar(a)
	var filtrados := f.pagina_rituais.find_children("*", "PanelContainer", true, false).filter(func(p): return p.custom_minimum_size.x == 500.0)
	assert_eq(filtrados.size(), 1, "o filtro por elemento")


func test_sem_rituais_explica():
	var a := Agente.criar(rs, "Mauro", "combatente", {"agi": 1, "for": 3, "int": 1, "pre": 1, "vig": 2})
	var f := FichaAgente.new()
	add_child_autofree(f)
	f.mostrar(a)
	var textos: Array = f.pagina_rituais.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.any(func(t): return t.begins_with("Nenhum ritual conhecido")))
