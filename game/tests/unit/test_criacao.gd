extends GutTest
## Criação completa de agente: origem, classe, perícias, trilha e poderes (cap. 1).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ficha_bianca() -> Dictionary:
	# Especialista / Investigador do exemplo do livro (p.25-32), com perícias livres nossas.
	return {
		"nome": "Bianca", "classe": "especialista", "origem": "investigador", "nex": 5,
		"atributos": {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		"pericias_livres": ["atualidades", "ciencias", "diplomacia", "intuicao", "medicina",
			"pilotagem", "pontaria", "tecnologia", "vontade", "ocultismo"],
		"perito": ["ciencias", "investigacao"],
	}


func _ficha_combatente(nex: int = 5) -> Dictionary:
	return {
		"nome": "Cléber", "classe": "combatente", "origem": "lutador", "nex": nex,
		"atributos": {"agi": 1, "for": 3, "int": 1, "pre": 1, "vig": 3},
		"pericias_classe": ["luta", "fortitude"],
		# 1 + INT 1 + 1 (Luta veio da origem e da classe)
		"pericias_livres": ["atletismo", "intimidacao", "percepcao"],
	}


func test_bianca_valida():
	var r := CriacaoAgente.criar(rs, _ficha_bianca())
	assert_eq(r.erros, [] as Array[String])
	var b: Agente = r.agente
	assert_eq(b.pericias.size(), 12)
	assert_eq(b.grau("investigacao"), "treinado")
	assert_eq(b.pv_maximo, 17)
	assert_true(b.tem_habilidade("faro_para_pistas"))


func test_quantidade_de_pericias_livres():
	var f := _ficha_bianca()
	f.pericias_livres.pop_back()
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())


func test_pericia_livre_nao_repete_a_da_origem():
	var f := _ficha_bianca()
	f.pericias_livres[0] = "percepcao"
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())


func test_sobreposicao_origem_classe_da_perícia_livre_extra():
	var r := CriacaoAgente.criar(rs, _ficha_combatente())
	assert_eq(r.erros, [] as Array[String])
	assert_eq(r.agente.pericias.size(), 6)  # luta, reflexos, fortitude + 3 livres


func test_escolha_x_ou_y_da_classe():
	var f := _ficha_combatente()
	f.pericias_classe = ["luta", "pontaria", "fortitude"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())


func test_amnesico_escolhe_as_pericias_da_origem():
	var f := _ficha_combatente()
	f.origem = "amnesico"
	f.pericias_livres = ["atletismo", "intimidacao"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "sem pericias_origem")
	f.pericias_origem = ["crime", "furtividade"]
	assert_eq(CriacaoAgente.criar(rs, f).erros, [] as Array[String])


func test_trilha_obrigatoria_em_nex_10():
	var f := _ficha_combatente(10)
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())
	f.trilha = "guerreiro"
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_true(r.agente.tem_habilidade("tecnica_letal"))
	assert_false(r.agente.tem_habilidade("revidar"), "só em NEX 40%")


func test_pre_requisito_de_trilha():
	var f := _ficha_bianca()
	f.nex = 10
	f.trilha = "medico_de_campo"
	f.pericias_livres.erase("medicina")
	f.pericias_livres.append("crime")
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "Médico de Campo exige Medicina")


func test_poder_de_classe_e_pre_requisitos():
	var f := _ficha_combatente(15)
	f.trilha = "tropa_de_choque"
	f.poderes = ["reflexos_defensivos"]  # exige AGI 2
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())
	f.poderes = ["golpe_pesado"]
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_true(r.agente.tem_habilidade("golpe_pesado"))


func test_quantidade_de_poderes_pelo_nex():
	var f := _ficha_combatente(15)
	f.trilha = "guerreiro"
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "NEX 15% exige 1 poder")


func test_treinamento_em_pericia():
	var f := _ficha_combatente(15)
	f.trilha = "guerreiro"
	f.poderes = ["treinamento_em_pericia"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "faltou informar o par")
	f.treinamentos = [["crime", "tatica"]]
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_eq(r.agente.grau("tatica"), "treinado")


func test_aumento_de_atributo_e_grau_de_treinamento_em_nex_35():
	var f := _ficha_combatente(35)
	f.trilha = "guerreiro"
	f.poderes = ["golpe_pesado", "artista_marcial"]
	f.aumentos_atributo = ["int"]   # INT 2 -> +1 perícia livre
	f.pericias_livres = ["atletismo", "intimidacao", "percepcao", "vontade"]
	f.graus = [["luta", "fortitude", "reflexos", "atletismo"]]  # 2 + INT 2
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	var a: Agente = r.agente
	assert_eq(a.atributo("int"), 2)
	assert_eq(a.grau("luta"), "veterano")
	assert_eq(a.bonus_pericia("luta"), 10)


func test_poder_que_exige_escolha():
	var f := _ficha_combatente()
	f.origem = "operario"
	f.pericias_classe = ["luta", "reflexos"]
	f.pericias_livres = ["atletismo", "intimidacao"]   # 1 + INT 1, sem sobreposição
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "Ferramenta de Trabalho exige escolher a arma")
	f.escolhas = {"ferramenta_de_trabalho": "machado"}
	assert_eq(CriacaoAgente.criar(rs, f).erros, [] as Array[String])
