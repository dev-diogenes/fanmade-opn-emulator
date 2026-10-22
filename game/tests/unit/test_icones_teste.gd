extends GutTest
## Os símbolos dos testes (docs/66): cada atributo e cada perícia tem o seu; a rolagem mostra o
## da perícia no cabeçalho e o do atributo em cada dado.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func test_toda_pericia_tem_simbolo_e_cor_do_atributo():
	for p in rs._pericias.values():
		var id := String(p.id)
		assert_true(IconeTeste.ATRIBUTO_DA_PERICIA.has(id), id)
		assert_eq(IconeTeste.ATRIBUTO_DA_PERICIA[id], String(p.atributo), "o atributo do livro: %s" % id)
		var i := IconeTeste.criar(id, 32)
		add_child_autofree(i)
		assert_eq(i.cor, IconeTeste.CORES[String(p.atributo)])
	await get_tree().process_frame   # desenha todos sem erro


func test_o_teste_guarda_pericia_e_atributo():
	var a := Agente.criar(rs, "Teste", "combatente", {"agi": 2, "for": 3, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado"})
	var t := a.testar(Dados.new(3), "luta", 10)
	assert_eq(t.pericia, "luta")
	assert_eq(t.atributo_id, "for")


func test_rolagem_com_pericia_e_simbolo_em_cada_dado():
	var r := RolagemDados.mostrar(self, "Ataque de Cléber", "for", [12, 5, 18], 15, "8 de dano", [], true, "luta")
	var textos: Array = r.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("ATAQUE DE CLÉBER  ·  LUTA"), "o título com a perícia")
	assert_true(textos.has("FORÇA"), "a etiqueta do atributo")
	var icones := r.find_children("*", "IconeTeste", true, false)
	assert_eq(icones.size(), 2 + 3, "o da perícia, o do atributo e um em cada dado")
	assert_eq((icones[0] as IconeTeste).chave, "luta")
	r.free()


func test_slot_do_ultimo_teste_com_atributo():
	var s := Tema.slot_d20(17, "sucesso", 0, "agi")
	add_child_autofree(s)
	assert_true((s.get_child(0) as Label).text.begins_with("17"), "o número continua o primeiro filho")
	assert_eq((s.get_child(1) as IconeTeste).chave, "agi")
