extends GutTest
## Regras opcionais Idade Variada (p.182-184), NEX 0%/Mundano (p.181-182) e Versatilidade.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _base(nex: int = 5) -> Dictionary:
	return {
		"nome": "Teste", "classe": "combatente", "origem": "lutador", "nex": nex,
		"atributos": {"agi": 1, "for": 3, "int": 1, "pre": 1, "vig": 3},
		"pericias_classe": ["luta", "fortitude"],
		"pericias_livres": ["atletismo", "intimidacao", "percepcao"],
	}


# --- Idade Variada ----------------------------------------------------------

func test_crianca():
	var f := _base()
	f.idade = "crianca"
	f.atributos = {"agi": 3, "for": 0, "int": 2, "pre": 2, "vig": 0}
	f.beneficios_origem = ["pericia:luta"]
	f.pericias_classe = ["pontaria", "reflexos"]
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	var a: Agente = r.agente
	assert_eq(a.defesa(), 10 + 3 + 2)
	assert_eq(a.bonus_pericia("reflexos"), 5 + 5)
	assert_eq(a.bonus_pericia("furtividade"), 2)
	assert_false(a.tem_habilidade("mao_pesada"), "escolheu a perícia, não o poder")


func test_crianca_comeca_com_forca_e_vigor_zero():
	var f := _base()
	f.idade = "crianca"
	f.beneficios_origem = ["poder"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())


func test_adolescente_ganha_5_pe():
	var f := _base()
	f.idade = "adolescente"
	f.atributos = {"agi": 2, "for": 0, "int": 1, "pre": 2, "vig": 3}
	f.beneficios_origem = ["pericia:luta", "poder"]
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_eq(r.agente.pe_maximo, rs.pe_max("combatente", 5, r.agente.atributos) + 5)
	assert_true(r.agente.tem_habilidade("mao_pesada"))


func test_adulto_tem_um_poder_a_mais_e_uma_desvantagem():
	var f := _base()
	f.idade = "adulto"
	f.poderes = ["golpe_pesado"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "falta a desvantagem")
	f.desvantagens_idade = ["catarata"]
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_eq(r.agente.bonus_pericia("percepcao"), 0, "treinado (+5) com Catarata (−5)")


func test_maduro_comeca_em_nex_10():
	var f := _base()
	f.idade = "maduro"
	f.desvantagens_idade = ["catarata", "tosse"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())


func test_idoso():
	var f := _base(20)
	f.idade = "idoso"
	f.trilha = "guerreiro"
	f.poderes = ["golpe_pesado"]
	f.desvantagens_idade = ["catarata", "fragil", "melancolico"]
	f.aumentos_atributo = ["agi"]
	f.pericias_livres = ["atletismo", "intimidacao", "percepcao"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "idoso não aumenta Agilidade")
	f.aumentos_atributo = ["int"]
	f.pericias_livres.append("vontade")   # INT 2 -> +1 perícia
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	var a: Agente = r.agente
	assert_eq(a.pv_maximo, 20 + 3 + 3 * (4 + 3) - 2 * 4)   # Frágil: −2 PV por NEX
	assert_eq(a.pe_maximo, 2 + 1 + 3 * (2 + 1) - 4)        # Melancólico: −1 PE por NEX


func test_desvantagens_de_pericia():
	var a := Agente.criar(rs, "A", "especialista", {"agi": 2, "for": 1, "int": 1, "pre": 2, "vig": 2})
	a.desvantagens_idade.append("rabugento")
	assert_eq(a.bonus_pericia("diplomacia"), -5)
	assert_eq(a.bonus_pericia("intimidacao"), 0)


func test_gota_causa_dano_ao_testar_agilidade():
	var a := Agente.criar(rs, "A", "especialista", {"agi": 2, "for": 1, "int": 1, "pre": 2, "vig": 2})
	a.desvantagens_idade.append("gota")
	var d := Dados.new(1)
	d.forcar([10, 10, 4])
	a.testar(d, "acrobacia", 10)
	assert_eq(a.pv, a.pv_maximo - 4)
	d.forcar([10, 10])
	a.testar(d, "intuicao", 10)
	assert_eq(a.pv, a.pv_maximo - 4, "Presença não machuca")


# --- Mundano (NEX 0%) ------------------------------------------------------

func _mundano() -> Dictionary:
	return {
		"nome": "Civil", "classe": "mundano", "origem": "academico", "nex": 0,
		"atributos": {"agi": 2, "for": 1, "int": 2, "pre": 2, "vig": 1},
		"pericias_livres": ["atualidades", "diplomacia", "percepcao"],
	}


func test_mundano_valido():
	var r := CriacaoAgente.criar(rs, _mundano())
	assert_eq(r.erros, [] as Array[String])
	var m: Agente = r.agente
	assert_eq(m.pv_maximo, 9)
	assert_eq(m.pe_maximo, 3)
	assert_eq(m.san_maximo, 8)
	assert_eq(m.limite_pe(), 0)


func test_mundano_so_tem_3_pontos_e_nao_tem_trilha():
	var f := _mundano()
	f.atributos = {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 1}
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())
	f = _mundano()
	f.trilha = "guerreiro"
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty())


func test_empenho_funciona_com_limite_zero():
	var m: Agente = CriacaoAgente.criar(rs, _mundano()).agente
	var d := Dados.new(1)
	d.forcar([8, 3])
	var r := m.testar(d, "atualidades", 15, 0, {"habilidades": ["empenho"]})
	assert_not_null(r)
	assert_eq(r.total, 8 + 5 + 2)
	assert_eq(m.pe, 2)


func test_promocao_de_mundano():
	var m: Agente = CriacaoAgente.criar(rs, _mundano()).agente
	assert_false(m.promover_de_mundano("combatente", "for", ["luta"]).is_empty(), "faltou Fortitude ou Reflexos")
	assert_eq(m.promover_de_mundano("combatente", "for", ["fortitude", "luta"]), [] as Array[String])
	assert_eq(m.classe_id, "combatente")
	assert_eq(m.nex, 5)
	assert_eq(m.atributo("for"), 2)
	assert_eq(m.pv_maximo, 8 + 1 + 12)
	assert_eq(m.pe_maximo, 1 + 2 + 1)
	assert_eq(m.san_maximo, 8 + 4)
	m.nex = 10
	m.recalcular_maximos()
	assert_eq(m.pv_maximo, 8 + 1 + 12 + (4 + 1))


func test_promocao_nao_passa_de_3():
	var m: Agente = CriacaoAgente.criar(rs, _mundano()).agente
	m.atributos["agi"] = 3
	assert_false(m.promover_de_mundano("especialista", "agi", ["crime", "furtividade", "tatica", "tecnologia", "medicina", "vontade"]).is_empty())


# --- Versatilidade ----------------------------------------------------------

func test_versatilidade_com_trilha_alheia():
	var f := _base(50)
	f.trilha = "guerreiro"
	f.aumentos_atributo = ["int", "int"]   # INT 3
	f.pericias_livres = ["atletismo", "intimidacao", "percepcao", "vontade", "crime"]
	f.graus = [["luta", "fortitude", "reflexos", "atletismo", "intimidacao"]]   # 2 + INT 3
	f.poderes = ["golpe_pesado", "artista_marcial", "incansavel"]
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "NEX 50% exige escolher a Versatilidade")
	f.versatilidade = "trilha:guerreiro"
	assert_false(CriacaoAgente.criar(rs, f).erros.is_empty(), "não pode ser a própria trilha")
	f.versatilidade = "trilha:aniquilador"
	var r := CriacaoAgente.criar(rs, f)
	assert_eq(r.erros, [] as Array[String])
	assert_true(r.agente.tem_habilidade("a_favorita"))
	assert_false(r.agente.tem_habilidade("tecnica_secreta"), "só o primeiro poder")
	assert_true(r.agente.tem_habilidade("tecnica_letal"))
