extends GutTest


func test_interpreta_expressoes():
	assert_eq(Dados.interpretar("2d6+3"), {"quantidade": 2, "faces": 6, "bonus": 3})
	assert_eq(Dados.interpretar("1d8-1"), {"quantidade": 1, "faces": 8, "bonus": -1})
	assert_eq(Dados.interpretar("d20"), {"quantidade": 1, "faces": 20, "bonus": 0})
	assert_eq(Dados.interpretar("5"), {"quantidade": 0, "faces": 0, "bonus": 5})


func test_resultados_forcados_saem_em_ordem():
	var d := Dados.new(1)
	d.forcar([3, 17, 20])
	assert_eq(d.rolar_varios(3, 20), [3, 17, 20])
	assert_false(d.tem_resultados_forcados())


func test_seed_e_reproduzivel():
	var a := Dados.new(42)
	var b := Dados.new(42)
	assert_eq(a.rolar_varios(10, 20), b.rolar_varios(10, 20))


func test_multiplicador_de_critico_multiplica_so_os_dados():
	var d := Dados.new(1)
	d.forcar([4, 5])  # 2d6 por causa do x2
	assert_eq(d.rolar_expressao("1d6+3", 2), 4 + 5 + 3)
