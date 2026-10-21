extends GutTest
## Poderes de classe no dossiê (docs/28): só os de pré-requisito cumprido, e as escolhas
## extras de Treinamento em Perícia, Especialista em Elemento e Ritual Predileto.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _dossie(classe: String, atributos: Dictionary) -> CriacaoDossie:
	var d := CriacaoDossie.abrir(self, Carreira.nova())
	d.ficha.nome = "Teste"
	d.ficha.classe = classe
	d.ficha.atributos = atributos
	d.idade_variada = true
	d._idade.value = 30   # adulto: um poder de classe (Vivência)
	d.ficha.desvantagens_idade = ["catarata"]
	return d


func _poderes_na_tela(d: CriacaoDossie) -> Array:
	d._abas.current_tab = CriacaoDossie.PASSOS.find("Classe")
	d._redesenhar()
	var nomes: Array = []
	for p in rs.dados.poderes_classe.poderes[String(d.ficha.classe)]:
		nomes.append(String(p.nome))
	return d._paginas["Classe"].find_children("*", "Button", true, false).map(func(b): return b.text).filter(func(t): return t in nomes)


func test_esconde_poder_sem_pre_requisito():
	var d := _dossie("combatente", {"agi": 1, "for": 1, "int": 1, "pre": 3, "vig": 3})
	var nomes: Array = _poderes_na_tela(d)
	assert_false(nomes.has(String(rs.poder("combatente", "armamento_pesado").nome)), "FOR 2 não cumprida")
	assert_false(nomes.has(String(rs.poder("combatente", "tanque_de_guerra").nome)), "exige outro poder")
	assert_false(nomes.has(String(rs.poder("combatente", "protecao_pesada").nome)), "exige NEX 30%")
	assert_true(nomes.has(String(rs.poder("combatente", "treinamento_em_pericia").nome)), "sem pré-requisito, aparece")
	d.ficha.atributos = {"agi": 1, "for": 2, "int": 1, "pre": 2, "vig": 3}
	assert_true(_poderes_na_tela(d).has(String(rs.poder("combatente", "armamento_pesado").nome)), "com FOR 2, aparece")
	d.free()


func test_poder_sai_quando_o_pre_requisito_deixa_de_valer():
	var d := _dossie("combatente", {"agi": 1, "for": 2, "int": 1, "pre": 2, "vig": 3})
	d.ficha.poderes = ["armamento_pesado"]
	d.ficha.atributos = {"agi": 1, "for": 1, "int": 1, "pre": 3, "vig": 3}
	_poderes_na_tela(d)
	assert_false("armamento_pesado" in d.ficha.poderes)
	d.free()


func test_especialista_em_elemento_e_ritual_predileto():
	var d := _dossie("ocultista", {"agi": 1, "for": 1, "int": 2, "pre": 3, "vig": 1})
	var rituais: Array = rs.dados.rituais.rituais.filter(func(r): return int(r.circulo) == 1).slice(0, 3).map(func(r): return String(r.id))
	d.ficha.rituais = rituais
	d.ficha.pericias_livres = ["ocultismo", "vontade", "intuicao", "percepcao", "religiao"]
	d.ficha.poderes = ["especialista_em_elemento"]
	assert_false(d._validar().erros.is_empty(), "sem o elemento, não fecha")
	d.ficha.escolhas["especialista_em_elemento"] = "plastico"
	assert_true(d._validar().erros.any(func(e): return e.contains("elemento inválido")))
	d.ficha.escolhas["especialista_em_elemento"] = "sangue"
	var erros: Array = d._validar().erros
	assert_false(erros.any(func(e): return e.contains("Especialista em Elemento")), "elemento válido: %s" % [erros])
	d._tirar_poder("especialista_em_elemento")
	assert_false(d.ficha.escolhas.has("especialista_em_elemento"), "tirar o poder limpa a escolha")
	d.ficha.poderes = ["ritual_predileto"]
	d.ficha.escolhas["ritual_predileto"] = "nao_conheco"
	assert_true(d._validar().erros.any(func(e): return e.contains("ritual que o agente conhece")))
	d.ficha.escolhas["ritual_predileto"] = rituais[0]
	assert_false(d._validar().erros.any(func(e): return e.contains("Ritual Predileto")))
	d.free()


func test_treinamento_em_pericia_escolhe_duas_novas():
	var d := _dossie("especialista", {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1})
	d.ficha.origem = "academico"
	d.ficha.pericias_livres = ["percepcao", "intuicao", "furtividade", "tecnologia", "medicina", "atualidades", "diplomacia", "reflexos", "vontade", "ocultismo"]
	d.ficha.perito = ["investigacao", "ciencias"]
	d.ficha.poderes = ["treinamento_em_pericia"]
	_poderes_na_tela(d)
	var nomes: Array = d._paginas["Classe"].find_children("*", "Button", true, false).map(func(b): return b.text)
	assert_false(nomes.has("Percepção"), "perícia já treinada não aparece no treinamento")
	assert_true(nomes.has("Crime"))
	d.ficha.treinamentos = [["crime", "tatica"]]
	assert_eq(d._validar().erros, [], "com as duas perícias, a ficha fecha")
	var a: Agente = d._validar().agente
	assert_true(a.treinado_em("crime") and a.treinado_em("tatica"))
	d.free()
