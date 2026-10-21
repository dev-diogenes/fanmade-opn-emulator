extends GutTest
## Criação na ordem e com os toques finais do livro (p.23-24, p.46-47; docs/27) e a regra
## opcional de idade variada no dossiê (p.182).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func test_faixa_pela_idade():
	assert_eq(CriacaoDossie.faixa_por_anos(rs, 10), "crianca")
	assert_eq(CriacaoDossie.faixa_por_anos(rs, 16), "adolescente")
	assert_eq(CriacaoDossie.faixa_por_anos(rs, 22), "jovem")
	assert_eq(CriacaoDossie.faixa_por_anos(rs, 30), "adulto")
	assert_eq(CriacaoDossie.faixa_por_anos(rs, 50), "maduro")
	assert_eq(CriacaoDossie.faixa_por_anos(rs, 80), "idoso")


func test_conceito_e_idade_no_primeiro_passo():
	var c := Carreira.nova()
	var d := CriacaoDossie.abrir(self, c)
	assert_eq(d._abas.get_tab_title(0), "Agente", "a ficha começa pelo conceito (①), na página Agente")
	assert_not_null(d._idade, "a idade fica no conceito")
	assert_eq(int(d.ficha.idade_anos), 22)
	assert_true(d._campos_descricao.has("conceito"), "o conceito fica na página Agente")
	# Sem a regra opcional, a idade não muda nada
	d._idade.value = 70
	assert_eq(String(d.ficha.idade), "")
	assert_eq(int(d.ficha.nex), 5)
	# Com a regra, a faixa sai da idade e muda o NEX inicial (idoso: +10%)
	d.idade_variada = true
	d._aplicar_faixa()
	assert_eq(String(d.ficha.idade), "idoso")
	assert_eq(int(d.ficha.nex), 15)
	d._idade.value = 22
	assert_eq(String(d.ficha.idade), "jovem")
	assert_eq(int(d.ficha.nex), 5)
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Habilidades e inventário")
	assert_true(d._campos_descricao.has("genero"), "o gênero, na descrição (página 2)")
	d.free()


func test_toques_finais_vao_ao_agente():
	var c := Carreira.nova()
	var ficha := {"nome": "Helena", "classe": "especialista", "origem": "academico", "nex": 5,
		"atributos": {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		"pericias_livres": ["percepcao", "intuicao", "furtividade", "tecnologia", "medicina", "atualidades", "diplomacia", "reflexos", "vontade", "ocultismo"],
		"perito": ["investigacao", "ciencias"],
		"conceito": "Perita forense curiosa.", "genero": "mulher", "idade_anos": 31, "aparencia_texto": "Óculos remendados com fita."}
	var a: Agente = c.recrutar_ficha(ficha).agente
	assert_eq(a.conceito, "Perita forense curiosa.")
	assert_eq(a.idade_anos, 31)
	var volta := Agente.de_dicionario(rs, a.para_dicionario())
	assert_eq(volta.genero, "mulher")
	assert_eq(volta.aparencia_texto, "Óculos remendados com fita.")
	var f := FichaAgente.new()
	add_child_autofree(f)
	f.mostrar(a)
	var p1: Array = f.pagina_agente.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(p1.has("Perita forense curiosa."), "o conceito na página 1")
	var p2: Array = f.pagina_habilidades.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(p2.any(func(t): return t.contains("31 anos") and t.contains("Óculos remendados")), "gênero, idade e aparência na descrição")


func test_adolescente_escolhe_beneficios_da_origem():
	var c := Carreira.nova()
	var d := CriacaoDossie.abrir(self, c)
	d.idade_variada = true
	d._idade.value = 15
	assert_eq(String(d.ficha.idade), "adolescente")
	d._redesenhar()
	var textos: Array = d._paginas["Agente"].find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.any(func(t): return t.begins_with("Benefícios da origem")), "a escolha da p.182 aparece")
	d.free()


func test_editar_descricao_depois():
	var a := Agente.criar(rs, "Helena", "especialista", {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1})
	var f := FichaAgente.new()
	f.editavel = true
	add_child_autofree(f)
	f.mostrar(a)
	var botoes: Array = f.pagina_habilidades.find_children("*", "Button", true, false).filter(func(b): return b.text == "Editar descrição")
	assert_eq(botoes.size(), 1, "na Base, a página 2 tem o botão")
	var salvou := []
	var e := EditorDescricao.abrir(self, a, func(): salvou.append(true))
	(e.campos.objetivo as LineEdit).text = "  Descobrir quem escreveu o livro.  "
	(e.campos.historico as TextEdit).text = "y".repeat(800)
	e._idade.value = 34
	e.salvar_e_fechar()
	assert_eq(a.objetivo, "Descobrir quem escreveu o livro.")
	assert_eq(a.historico.length(), Carreira.LIMITE_DESCRICAO.historico)
	assert_eq(a.idade_anos, 34)
	assert_eq(salvou, [true], "a Base salva a carreira")
	var jogo := FichaAgente.new()
	add_child_autofree(jogo)
	jogo.mostrar(a)
	assert_true(jogo.pagina_habilidades.find_children("*", "Button", true, false).filter(func(b): return b.text == "Editar descrição").is_empty(), "no jogo (F), só leitura")


func _ficha_base(d: CriacaoDossie) -> void:
	d.ficha.nome = "Helena"
	d.ficha.classe = "especialista"
	d.ficha.origem = "academico"
	d.ficha.atributos = {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1}
	d.ficha.pericias_livres = ["percepcao", "intuicao", "furtividade", "tecnologia", "medicina", "atualidades", "diplomacia", "reflexos", "vontade", "ocultismo"]
	d.ficha.perito = ["investigacao", "ciencias"]


func _sem_pre(classe: String) -> Array:
	return rs.dados.poderes_classe.poderes[classe].filter(func(p): return (p.get("pre", {}) as Dictionary).is_empty() and not p.id in CriacaoDossie.PODERES_COM_ESCOLHA).map(func(p): return String(p.id))


func test_adulto_escolhe_o_poder_da_vivencia_no_dossie():
	var d := CriacaoDossie.abrir(self, Carreira.nova())
	_ficha_base(d)
	d.idade_variada = true
	d._idade.value = 30
	assert_eq(d.poderes_esperados(), 1, "adulto: um poder a mais (p.183)")
	d.ficha.desvantagens_idade = ["catarata"]
	assert_false(d._validar().erros.is_empty(), "sem o poder, a ficha não fecha")
	d.ficha.poderes = [_sem_pre("especialista")[0]]
	assert_eq(d._validar().erros, [], "com o poder e a desvantagem, fecha")
	d.free()


func test_maduro_comeca_em_nex_10_com_trilha_e_rituais_a_mais():
	var d := CriacaoDossie.abrir(self, Carreira.nova())
	_ficha_base(d)
	d.idade_variada = true
	d._idade.value = 50
	assert_eq(int(d.ficha.nex), 10)
	d.ficha.desvantagens_idade = ["catarata", "gota"]
	d.ficha.trilha = String(rs.dados.trilhas.trilhas.especialista[0].id)
	assert_eq(d._validar().erros, [], "maduro: NEX 10%% com trilha fecha a ficha")
	d.ficha.classe = "ocultista"
	assert_eq(d.rituais_esperados(), 4, "ocultista em NEX 10%: 3 + 1 ritual")
	d.free()
