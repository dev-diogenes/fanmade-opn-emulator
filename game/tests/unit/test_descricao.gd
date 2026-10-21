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


func test_criacao_e_a_propria_ficha():
	var c := Carreira.nova()
	var d := CriacaoDossie.abrir(self, c)
	var titulos: Array = []
	for i in d._abas.get_tab_count():
		titulos.append(d._abas.get_tab_title(i))
	assert_eq(titulos, ["Agente", "Habilidades e inventário", "Rituais"], "as páginas da ficha (docs/30)")
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Habilidades e inventário")
	var campo: LineEdit = d._campos_descricao.personalidade
	campo.text = "Calada"
	campo.text_changed.emit("Calada")
	assert_eq(d.ficha.personalidade, "Calada", "o campo escreve na ficha")
	d._abas.current_tab = 0
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Habilidades e inventário")
	assert_eq((d._campos_descricao.personalidade as LineEdit).text, "Calada", "o texto sobrevive à troca de aba")
	# Revisão: a página 1 da ficha nova, com o equipamento inicial
	d.ficha.nome = "Helena"
	for k in _ficha_valida("Helena"):
		d.ficha[k] = _ficha_valida("Helena")[k]
	d._abas.current_tab = 0
	d._redesenhar()
	var pagina: Control = d._paginas["Agente"]
	assert_gt(pagina.find_children("*", "PentagonoAtributos", true, false).size(), 0, "o pentágono da ficha")
	var textos: Array = pagina.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("ATAQUES"), "a tabela de ataques, com a arma do kit")
	assert_true(textos.has("PERÍCIAS"), "a tabela de perícias para marcar")
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


func test_ficha_de_criacao_marca_pericias_e_atributos():
	var d := CriacaoDossie.abrir(self, Carreira.nova())
	d.ficha.classe = "especialista"
	d.ficha.origem = "academico"
	d.ficha.atributos = {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}
	d._redesenhar()
	var pagina: Control = d._paginas["Agente"]
	var mais: Array = pagina.find_children("*", "Button", true, false).filter(func(b): return b.text == "+" and not b.disabled and b.is_visible_in_tree())
	assert_eq(mais.size(), 5, "um + por atributo no pentágono")
	mais[0].pressed.emit()
	var soma := 0
	for k in d.ficha.atributos:
		soma += int(d.ficha.atributos[k])
	assert_eq(soma, 6, "o + sobe um atributo")
	d._marcar_pericia("crime", 0, [], 10)
	assert_true("crime" in d.ficha.pericias_livres, "clicar numa perícia livre marca o treino")
	d._marcar_pericia("crime", 0, [], 10)
	assert_false("crime" in d.ficha.pericias_livres, "e desmarca")
	var travadas: Array = d._paginas["Agente"].find_children("*", "Button", true, false).filter(func(b): return b.disabled and b.text.begins_with("☑") and b.is_visible_in_tree())
	assert_gt(travadas.size(), 0, "as perícias da origem vêm marcadas e travadas")
	d.free()
