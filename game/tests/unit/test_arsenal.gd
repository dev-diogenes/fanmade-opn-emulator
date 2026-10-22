extends GutTest
## Arsenal por agente (docs/64): o que cada um pode requisitar pela patente (itens por
## categoria, p.52) e pela carga (5 espaços por Força, p.53), e a proficiência das armas.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente(forca: int, classe := "especialista") -> Agente:
	return Agente.criar(rs, "Teste", classe, {"agi": 1, "for": forca, "int": 1, "pre": 1, "vig": 1}, {})


func _da_categoria(cat: int, tipo := "") -> String:
	for lista in [rs.lista_armas(), rs.protecoes(), rs.itens_gerais()]:
		for it in lista:
			var e := rs.equipamento(it.id)
			if int(e.get("categoria", 0)) == cat and (tipo == "" or e.get("tipo", "") == tipo):
				return String(it.id)
	return ""


func test_recruta_nao_tem_categoria_dois():
	var a := _agente(2)
	var item := _da_categoria(2)
	assert_ne(item, "")
	assert_string_contains(a.motivo_bloqueio(item, []), "ainda não libera", "Recruta: só categoria I (p.52)")
	a.pp = 20   # Operador: um de categoria II
	assert_eq(a.motivo_bloqueio(item, []), "")


func test_cota_da_categoria_um():
	var a := _agente(3)
	var itens: Array = []
	for lista in [rs.lista_armas(), rs.protecoes(), rs.itens_gerais()]:
		for it in lista:
			if int(rs.equipamento(it.id).get("categoria", 0)) == 1 and rs.equipamento(it.id).get("tipo", "") != "protecao":
				itens.append(String(it.id))
	assert_gt(itens.size(), 2)
	assert_string_contains(a.motivo_bloqueio(itens[2], itens.slice(0, 2)), "Já leva 2 de 2", "Recruta: dois itens de categoria I")


func test_carga_pela_forca():
	var fraco := _agente(0)
	assert_eq(fraco.capacidade_carga(), 2, "Força 0: 2 espaços (p.53)")
	var forte := _agente(2)
	assert_eq(forte.capacidade_carga(), 10)
	var pesada := "protecao_pesada"   # 5 espaços, categoria II
	fraco.pp = 20   # Operador: a categoria não barra, só a carga
	assert_string_contains(fraco.motivo_bloqueio(pesada, []), "carga máxima", "Força 0 não leva mais de 4 espaços")
	forte.pp = 20
	assert_eq(forte.motivo_bloqueio(pesada, []), "")


func test_uma_protecao_so():
	var a := _agente(3)
	a.pp = 20
	assert_string_contains(a.motivo_bloqueio("protecao_pesada", ["protecao_leve"]), "uma proteção")


func test_arma_sem_proficiencia_avisa_e_custa_dois_dados():
	var esp := _agente(2, "especialista")
	var tatica := ""
	for it in rs.lista_armas():
		if String(rs.equipamento(it.id).get("proficiencia", "")) == "armas_taticas":
			tatica = String(it.id)
			break
	assert_ne(tatica, "")
	assert_string_contains(esp.aviso_item(tatica), "−2 dados", "especialista não é proficiente em armas táticas")
	assert_eq(esp.dados_sem_proficiencia(rs.equipamento(tatica)), 2)
	var comb := _agente(2, "combatente")
	assert_eq(comb.aviso_item(tatica), "", "combatente é proficiente (p.53)")
	assert_eq(comb.dados_sem_proficiencia(rs.equipamento(tatica)), 0)
