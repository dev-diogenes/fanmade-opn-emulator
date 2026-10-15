extends GutTest

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _bianca() -> Agente:
	return Agente.criar(rs, "Bianca", "especialista",
		{"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		{"investigacao": "treinado", "ciencias": "treinado", "percepcao": "treinado"})


func test_criacao_calcula_maximos():
	var b := _bianca()
	assert_eq(b.pv_maximo, 17)   # 16 + VIG 1
	assert_eq(b.pe_maximo, 6)    # 3 + PRE 3
	assert_eq(b.san_maximo, 16)
	assert_eq(b.pv, b.pv_maximo)
	assert_eq(b.defesa(), 12)


func test_teste_de_pericia_usa_atributo_base_e_grau():
	var b := _bianca()
	var d := Dados.new(1)
	d.forcar([4, 13, 8])  # INT 3 -> 3 slots
	var r := b.testar(d, "investigacao", 15)
	assert_eq(r.slots.size(), 3)
	assert_eq(r.total, 18)
	assert_true(r.sucesso)


func test_pericia_somente_treinada_bloqueia_destreinado():
	var b := _bianca()
	assert_null(b.testar(Dados.new(1), "pilotagem", 10))


func test_pe_como_foco_adiciona_um_d20_por_ponto():
	var b := _bianca()
	var d := Dados.new(1)
	d.forcar([2, 3, 4, 19])  # 3 slots de INT + 1 de Foco
	var r := b.testar(d, "investigacao", 20, 1)
	assert_eq(r.slots.size(), 4)
	assert_eq(r.escolhido, 19)
	assert_eq(b.pe, b.pe_maximo - 1)


func test_foco_respeita_limite_de_pe_por_turno():
	var b := _bianca()  # NEX 5% -> limite 1
	assert_null(b.testar(Dados.new(1), "investigacao", 10, 2))
	assert_eq(b.pe, b.pe_maximo, "não gasta PE quando o teste é recusado")
	assert_true(b.gastar_pe(1))
	assert_false(b.gastar_pe(1), "limite do turno já atingido")
	b.iniciar_turno()
	assert_true(b.gastar_pe(1), "novo turno libera o limite")


func test_dano_ate_zero_deixa_morrendo_e_tres_turnos_matam():
	var b := _bianca()
	b.sofrer_dano(9)
	assert_true(b.tem(Ser.MACHUCADO))
	b.sofrer_dano(100)
	assert_eq(b.pv, 0)
	assert_true(b.tem(Ser.MORRENDO))
	assert_true(b.tem(Ser.INCONSCIENTE))
	b.iniciar_turno()
	b.iniciar_turno()
	assert_false(b.tem(Ser.MORTO))
	b.iniciar_turno()
	assert_true(b.tem(Ser.MORTO))


func test_curar_acorda_mas_nao_estabiliza():
	var b := _bianca()
	b.sofrer_dano(100)
	b.curar(5)
	assert_false(b.tem(Ser.INCONSCIENTE))
	assert_true(b.tem(Ser.MORRENDO), "morrendo só sai com Medicina DT 20")
	b.estabilizar()
	assert_false(b.tem(Ser.MORRENDO))


func test_sanidade_perturbado_enlouquecendo_insano():
	var b := _bianca()  # SAN 16
	b.sofrer_dano_mental(9)
	assert_true(b.tem(Ser.PERTURBADO))
	b.sofrer_dano_mental(50)
	assert_true(b.tem(Ser.ENLOUQUECENDO))
	for i in 3:
		b.iniciar_turno()
	assert_true(b.tem(Ser.INSANO))
	assert_true(b.esta_fora_de_combate())


func test_subir_nex_aumenta_maximos():
	var b := _bianca()
	b.nex = 10
	b.recalcular_maximos()
	assert_eq(b.pv_maximo, 17 + 3 + 1)
	assert_eq(b.limite_pe(), 2)
