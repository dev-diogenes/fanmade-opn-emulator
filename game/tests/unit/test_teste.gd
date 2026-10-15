extends GutTest
## Mecânica básica de testes em slots (p.19, p.24, p.50, p.86).


func test_vale_o_maior_dado_mais_bonus():
	# Exemplo do livro (p.50): Força 3, treinado em Atletismo, dados 5, 11 e 12 -> 17.
	var d := Dados.new(1)
	d.forcar([5, 11, 12])
	var r := Teste.rolar(d, 3, 5, 15)
	assert_eq(r.slots, [5, 11, 12])
	assert_eq(r.escolhido, 12)
	assert_eq(r.total, 17)
	assert_true(r.sucesso)


func test_atributo_zero_rola_dois_e_vale_o_pior():
	# Exemplo do livro (p.86): Força 0, dados 14 e 6 -> 6.
	var d := Dados.new(1)
	d.forcar([14, 6])
	var r := Teste.rolar(d, 0, 0, 10)
	assert_true(r.usa_pior)
	assert_eq(r.slots.size(), 2)
	assert_eq(r.total, 6)
	assert_false(r.sucesso)


func test_dado_extra_tira_o_atributo_zero_da_penalidade():
	var d := Dados.new(1)
	d.forcar([9])
	var r := Teste.rolar(d, 0, 0, 5, 1)
	assert_false(r.usa_pior)
	assert_eq(r.slots, [9])


func test_penalidade_abaixo_de_zero_adiciona_dados_ao_pior():
	var d := Dados.new(1)
	d.forcar([18, 12, 7])
	var r := Teste.rolar(d, 1, 0, 5, -2)  # reserva -1 -> 3d20, pior
	assert_true(r.usa_pior)
	assert_eq(r.escolhido, 7)


func test_vinte_natural_passa_sempre():
	var d := Dados.new(1)
	d.forcar([20])
	var r := Teste.rolar(d, 1, 0, 35)
	assert_true(r.natural_20)
	assert_true(r.sucesso)


func test_empate_com_a_dt_passa():
	var d := Dados.new(1)
	d.forcar([10])
	assert_true(Teste.rolar(d, 1, 5, 15).sucesso)


func test_chance_de_passar():
	assert_almost_eq(Teste.chance_de_passar(1, 0, 11), 0.5, 0.0001)
	assert_almost_eq(Teste.chance_de_passar(2, 0, 11), 0.75, 0.0001)        # 1 - 0.5²
	assert_almost_eq(Teste.chance_de_passar(0, 0, 11), 0.25, 0.0001)        # 0.5² (pior de 2)
	assert_almost_eq(Teste.chance_de_passar(1, 0, 50), 0.05, 0.0001)        # só o 20 natural
	assert_almost_eq(Teste.chance_de_passar(1, 20, 5), 1.0, 0.0001)
