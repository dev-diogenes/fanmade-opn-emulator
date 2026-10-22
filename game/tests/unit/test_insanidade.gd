extends GutTest
## Efeito de insanidade ao ficar perturbado (p.111-113, docs/49).

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _bianca() -> Agente:
	var b := Agente.criar(rs, "Bianca", "especialista",
		{"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		{"investigacao": "treinado", "ciencias": "treinado", "percepcao": "treinado"})
	b.id = "bianca"
	b.semente_insanidade = 7
	return b


func test_tabela_tem_os_vinte_efeitos_com_texto_proprio():
	var lista := rs.efeitos_insanidade()
	assert_eq(lista.size(), 20)
	for i in 20:
		var e := rs.efeito_insanidade(i + 1)
		assert_false(String(e.get("nome", "")).is_empty(), "efeito %d tem nome" % (i + 1))
		assert_false((e.get("frases", []) as Array).is_empty(), "efeito %d tem frases" % (i + 1))


func test_ficar_perturbado_rola_um_efeito():
	var b := _bianca()   # SAN 16
	var novos := []
	b.ganhou_insanidade.connect(func(_a, e): novos.append(e))
	b.sofrer_dano_mental(7)
	assert_false(b.tem(Ser.PERTURBADO))
	assert_true(b.efeitos_insanidade.is_empty(), "na metade ainda não")
	b.sofrer_dano_mental(2)
	assert_true(b.tem(Ser.PERTURBADO))
	assert_eq(b.efeitos_insanidade.size(), 1)
	assert_eq(novos.size(), 1)
	var id := int(b.efeitos_insanidade[0].id)
	assert_between(id, 1, 20)
	assert_false(b.efeitos_insanidade[0].ate_o_fim, "temporário")
	assert_string_contains(b.linha_insanidade(b.efeitos_insanidade[0]), "1d20: %d" % id)


func test_o_1d20_e_igual_para_a_mesma_semente():
	var a := _bianca()
	var b := _bianca()
	a.sofrer_dano_mental(9)
	b.sofrer_dano_mental(9)
	assert_eq(a.efeitos_insanidade[0].id, b.efeitos_insanidade[0].id, "igual nos dois lados do online")


func test_uma_vez_por_cena_e_some_ao_sair_de_perturbado():
	var b := _bianca()
	b.sofrer_dano_mental(9)
	assert_eq(b.efeitos_insanidade.size(), 1)
	b.recuperar_sanidade(16)
	assert_false(b.tem(Ser.PERTURBADO))
	assert_true(b.efeitos_insanidade.is_empty(), "o temporário acaba quando a SAN volta")
	b.sofrer_dano_mental(9)
	assert_true(b.efeitos_insanidade.is_empty(), "só na primeira vez na cena")
	b.recuperar_sanidade(16)
	b.encerrar_cena()
	b.sofrer_dano_mental(9)
	assert_eq(b.efeitos_insanidade.size(), 1, "outra cena, outro 1d20")


func test_enlouquecer_fixa_o_efeito_ate_o_fim_da_missao():
	var b := _bianca()
	b.sofrer_dano_mental(16)
	assert_true(b.tem(Ser.ENLOUQUECENDO))
	assert_eq(b.efeitos_insanidade.size(), 1, "de uma vez: perturbado e enlouquecendo")
	assert_true(b.efeitos_insanidade[0].ate_o_fim)
	b.recuperar_sanidade(16)
	assert_false(b.tem(Ser.PERTURBADO))
	assert_eq(b.efeitos_insanidade.size(), 1, "mesmo acalmado, dura até o fim da missão")
	b.encerrar_cena()
	b.sofrer_dano_mental(9)
	assert_between(b.efeitos_insanidade.size(), 1, 2, "outra cena pode somar um segundo efeito")
	var c := Carreira.nova()
	c._restaurar(b)
	assert_true(b.efeitos_insanidade.is_empty(), "fim da missão")


func test_sem_efeito_mecanico():
	var b := _bianca()
	var d := Dados.new(1)
	d.forcar([4, 13, 8])
	var antes := b.testar(d, "investigacao", 15).total
	var defesa := b.defesa()
	b.sofrer_dano_mental(9)
	d.forcar([4, 13, 8])
	assert_eq(b.testar(d, "investigacao", 15).total, antes, "nenhuma penalidade (p.111)")
	assert_eq(b.defesa(), defesa)


func test_salva_e_carrega():
	var b := _bianca()
	b.sofrer_dano_mental(16)
	var c := Agente.de_dicionario(rs, b.para_dicionario())
	assert_eq(c.efeitos_insanidade, b.efeitos_insanidade)
	assert_eq(c.rolagens_insanidade, 1)
	assert_eq(c.semente_insanidade, 7)


func test_o_registro_do_combate_e_do_mapa_contam_o_efeito():
	var b := _bianca()
	var cb := Combate.new(rs, Dados.new(1))
	cb.adicionar(b)
	var linhas := []
	cb.registro.connect(func(t): linhas.append(t))
	b.sofrer_dano_mental(9)
	assert_eq(linhas.size(), 1)
	assert_string_contains(String(linhas[0]), "efeito de insanidade")
	var m := Missao.nova(42)
	var mauro: Agente = m.agentes[0]
	assert_eq(mauro.semente_insanidade, 42, "a semente da missão")
	mauro.sofrer_dano_mental(mauro.san_maximo / 2 + 1)
	assert_string_contains(String(m.historico.back()), mauro.nome)


func test_frases_e_nota_na_tela():
	var b := _bianca()
	b.sofrer_dano_mental(9)
	var frases := Alucinacoes.frases_do_efeito(b)
	assert_eq(frases, rs.efeito_insanidade(int(b.efeitos_insanidade[0].id)).frases)
	assert_gt(Alucinacoes.intensidade(b), 0.0)
	var n := NotaInsanidade.mostrar(self, b, b.efeitos_insanidade[0])
	var textos := n.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_has(textos, String(rs.efeito_insanidade(int(b.efeitos_insanidade[0].id)).nome))
	n.free()
