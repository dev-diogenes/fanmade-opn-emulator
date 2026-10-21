extends GutTest
## Descrição do agente e revisão com a ficha nova no dossiê de criação (docs/26).


func _ficha_valida(nome: String) -> Dictionary:
	return {"nome": nome, "classe": "especialista", "origem": "academico", "nex": 5,
		"atributos": {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		"pericias_livres": ["percepcao", "intuicao", "furtividade", "tecnologia", "medicina", "atualidades", "diplomacia", "reflexos", "vontade", "ocultismo"],
		"perito": ["investigacao", "ciencias"]}


func test_descricao_vai_ao_agente_e_ao_save():
	var c := Carreira.nova()
	var ficha := _ficha_valida("Helena")
	ficha["personalidade"] = "  Calada e observadora.  "
	ficha["historico"] = "x".repeat(900)
	ficha["objetivo"] = "Descobrir o que levou a irmã."
	var a: Agente = c.recrutar_ficha(ficha).agente
	assert_eq(a.personalidade, "Calada e observadora.", "sem espaços nas pontas")
	assert_eq(a.historico.length(), Carreira.LIMITE_DESCRICAO.historico, "aparado no limite")
	var volta := Agente.de_dicionario(a.ruleset, a.para_dicionario())
	assert_eq(volta.objetivo, "Descobrir o que levou a irmã.")
	var antigo := a.para_dicionario()
	antigo.erase("historico")
	assert_eq(Agente.de_dicionario(a.ruleset, antigo).historico, "", "saves antigos ficam em branco")


func test_dossie_tem_a_aba_descricao_e_a_revisao_com_a_ficha_nova():
	var c := Carreira.nova()
	var d := CriacaoDossie.abrir(self, c)
	var titulos: Array = []
	for i in d._abas.get_tab_count():
		titulos.append(d._abas.get_tab_title(i))
	assert_eq(titulos, ["Conceito", "Atributos", "Origem", "Classe", "Perícias", "Rituais", "Descrição", "Revisão"], "a ordem do livro (p.23)")
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Descrição")
	var campo: LineEdit = d._campos_descricao.personalidade
	campo.text = "Calada"
	campo.text_changed.emit("Calada")
	assert_eq(d.ficha.personalidade, "Calada", "o campo escreve na ficha")
	d._abas.current_tab = 0
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Descrição")
	assert_eq((d._campos_descricao.personalidade as LineEdit).text, "Calada", "o texto sobrevive à troca de aba")
	# Revisão: a página 1 da ficha nova, com o equipamento inicial
	d.ficha.nome = "Helena"
	for k in _ficha_valida("Helena"):
		d.ficha[k] = _ficha_valida("Helena")[k]
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Revisão")
	assert_not_null(d._revisao)
	assert_gt(d._revisao.find_children("*", "PentagonoAtributos", true, false).size(), 0, "o pentágono da ficha nova")
	var textos: Array = d._revisao.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("ATAQUES"), "a tabela de ataques, já com a arma do kit")
	d.free()


func test_ficha_mostra_a_descricao():
	var rs := RulesetOp2022.carregar_padrao()
	var a := Agente.criar(rs, "Helena", "especialista", {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1})
	a.historico = "Era bibliotecária em Santo Berço."
	var f := FichaAgente.new()
	add_child_autofree(f)
	f.mostrar(a)
	var textos: Array = f.pagina_habilidades.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("Era bibliotecária em Santo Berço."))
	assert_true(textos.has("HISTÓRICO"))
	assert_false(textos.has("PERSONALIDADE"), "campo em branco não aparece")
