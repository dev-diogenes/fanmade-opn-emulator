extends GutTest

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func test_carrega_manifesto_e_dados():
	assert_eq(rs.id, "op2022")
	assert_eq(rs.pericia("luta").atributo, "for")
	assert_eq(rs.pericia("vontade").atributo, "pre")
	assert_eq(rs.arma("pistola").margem, 18.0)


func test_bonus_por_grau():
	assert_eq(rs.bonus_grau("destreinado"), 0)
	assert_eq(rs.bonus_grau("treinado"), 5)
	assert_eq(rs.bonus_grau("veterano"), 10)
	assert_eq(rs.bonus_grau("expert"), 15)


func test_limite_de_pe_por_nex():
	assert_eq(rs.limite_pe(5), 1)
	assert_eq(rs.limite_pe(30), 6)
	assert_eq(rs.limite_pe(32), 6)
	assert_eq(rs.limite_pe(99), 20)


func test_pv_pe_san_iniciais_por_classe():
	var attrs := {"agi": 1, "for": 2, "int": 1, "pre": 2, "vig": 3}
	assert_eq(rs.pv_max("combatente", 5, attrs), 23)    # 20 + VIG
	assert_eq(rs.pe_max("combatente", 5, attrs), 4)     # 2 + PRE
	assert_eq(rs.san_max("combatente", 5, attrs), 12)
	assert_eq(rs.pv_max("ocultista", 5, attrs), 15)     # 12 + VIG
	assert_eq(rs.pe_max("ocultista", 5, attrs), 6)      # 4 + PRE
	assert_eq(rs.san_max("especialista", 5, attrs), 16)


func test_progressao_por_nex():
	var attrs := {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 2}
	# Combatente NEX 10%: 20+2 e mais (4+2) = 28
	assert_eq(rs.pv_max("combatente", 10, attrs), 28)
	# Especialista NEX 20%: SAN 16 + 3×4 = 28
	assert_eq(rs.san_max("especialista", 20, attrs), 28)
	assert_eq(rs.niveis_de_exposicao(99), 20)


func test_defesa_e_10_mais_agilidade():
	assert_eq(rs.defesa_base({"agi": 3}), 13)


func test_valida_atributos_iniciais():
	assert_true(rs.validar_atributos_iniciais({"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1}).is_empty())  # Bianca, p.25
	assert_false(rs.validar_atributos_iniciais({"agi": 4, "for": 1, "int": 1, "pre": 1, "vig": 1}).is_empty())  # acima de 3
	assert_false(rs.validar_atributos_iniciais({"agi": 0, "for": 0, "int": 3, "pre": 3, "vig": 3}).is_empty())  # dois zerados
	assert_false(rs.validar_atributos_iniciais({"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}).is_empty())  # não distribuiu
