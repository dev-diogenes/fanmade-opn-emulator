extends GutTest
## Fase 4.7: granadas (p.74), Aracnasita, Dama de Sangue com as sete flores, Minotauro, Kerberos e covis por NEX.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func _agente(nex: int = 50) -> Agente:
	return Agente.criar(rs, "Agente", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 2}, {"luta": "treinado", "fortitude": "treinado"}, nex)


func _saco(pv: int = 1000, lado: String = "agentes") -> Ameaca:
	var s := Ameaca.criar(rs, "Saco", {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1}})
	s.lado = lado
	return s


func _combate_com_grade() -> Array:
	var c := Combate.new(rs, Dados.new(1))
	c.grade = Grade.new(14, 9)
	var a := _agente()
	var x := _saco(100, "ameacas")
	var y := _saco(100, "agentes")
	for par in [[a, Vector2i(0, 4)], [x, Vector2i(8, 4)], [y, Vector2i(9, 4)]]:
		c.adicionar(par[0])
		c.grade.colocar(par[0], par[1])
	return [c, a, x, y]


func test_granada_de_fragmentacao():
	var cena := _combate_com_grade()
	var c: Combate = cena[0]
	var a: Agente = cena[1]
	a.equipamento.append("granada_de_fragmentacao")
	c.dados.forcar([3, 3, 3, 3, 3, 3, 3, 3, 1, 20])
	var r := c.usar_granada(a, "granada_de_fragmentacao", Vector2i(8, 4))
	assert_true(r.ok, str(r.get("erro", "")))
	assert_eq(cena[2].pv, 100 - 24)
	assert_eq(cena[3].pv, 100 - 12, "o aliado na área também é atingido (passou em Reflexos: metade)")
	assert_false(a.tem_item("granada_de_fragmentacao"), "uso único")


func test_granada_incendiaria_e_chamas():
	var cena := _combate_com_grade()
	var c: Combate = cena[0]
	var a: Agente = cena[1]
	var x: Ameaca = cena[2]
	a.equipamento.append("granada_incendiaria")
	c.dados.forcar([1, 1, 1, 1, 1, 1, 1, 20])
	c.usar_granada(a, "granada_incendiaria", Vector2i(8, 4))
	assert_true(x.tem(Ser.EM_CHAMAS))
	assert_false(cena[3].tem(Ser.EM_CHAMAS))
	var pv := x.pv
	c.dados.forcar([4])
	c._inicio_de_turno_ameacas(x)
	assert_eq(x.pv, pv - 4)
	assert_true(c.apagar_chamas(x))
	assert_false(x.tem(Ser.EM_CHAMAS))


func test_granada_de_atordoamento():
	var cena := _combate_com_grade()
	var c: Combate = cena[0]
	var a: Agente = cena[1]
	a.equipamento.append("granada_de_atordoamento")
	c.dados.forcar([1, 20])
	c.usar_granada(a, "granada_de_atordoamento", Vector2i(8, 4))
	assert_true(cena[2].tem(Ser.ATORDOADO))
	assert_true(cena[3].tem(Ser.OFUSCADO))


func test_aracnasita_so_cede_ao_fogo():
	var c := Combate.new(rs, Dados.new(1))
	var ar := _ameaca("aracnasita")
	assert_eq(c.aplicar_dano(ar, 20, "corte"), 0)
	assert_eq(c.aplicar_dano(ar, 10, "fogo"), 10)
	assert_eq(c.aplicar_dano(ar, 20, "corte"), 20, "queimada, perde a imunidade")
	c._inicio_de_turno_ameacas(ar)
	assert_eq(c.aplicar_dano(ar, 20, "corte"), 0, "até o início do próximo turno")


func test_dama_consome_e_flores_murcham():
	var c := Combate.new(rs, Dados.new(1))
	var dama := _ameaca("dama_de_sangue")
	var a := _agente()
	var corpo := _saco(10, "agentes")
	corpo._morrer()
	for s in [dama, a, corpo]:
		c.adicionar(s)
	assert_false(c.usar_habilidade(dama, "arremessar", a).ok, "a flor rosa ainda não desabrochou")
	assert_true(c.usar_habilidade(dama, "consumir").ok)
	assert_eq(int(dama.mods_cena.flores), 1)
	assert_false(c.usar_habilidade(dama, "consumir").ok, "o corpo já foi consumido")
	var pv := a.pv
	c.dados.forcar([3, 3, 1])   # o dano é rolado uma vez antes das resistências
	assert_true(c.usar_habilidade(dama, "arremessar", a).ok)
	assert_eq(a.pv, pv - 6)
	a.equipamento.append("fertilizante")
	assert_true(c.usar_contra(a, dama, "fertilizante"))
	assert_eq(int(dama.mods_cena.menos_dados.luta), 1, "flor rosa murcha: −1 dado em Luta")
	assert_false(c.usar_habilidade(dama, "arremessar", a).ok)
	dama.mods_cena["flores"] = 7
	c.aplicar_dano(dama, 10, "fogo")
	assert_true("espinhos" in dama.mods_cena.murchas, "10 de fogo num só efeito murcha a amarela")
	c.aplicar_dano(dama, 10, "corte")
	assert_eq(dama.pv_maximo, 105 - 20, "flor laranja murcha: −20 PV totais")


func test_dama_prisao_e_miasma():
	var c := Combate.new(rs, Dados.new(1))
	var dama := _ameaca("dama_de_sangue")
	var a := _agente()
	c.adicionar(dama)
	c.adicionar(a)
	dama.mods_cena["flores"] = 7
	assert_true(c.usar_habilidade(dama, "prisao_de_tentaculos", a).ok)
	assert_true(a.tem(Ser.AGARRADO))
	c.dados.forcar([3])
	assert_false(c.escapar(a), "os tentáculos têm 20 PV")
	a.mods_cena["prisao_pv"] = 1
	c.dados.forcar([3])
	assert_true(c.escapar(a))
	c.dados.forcar([20, 20, 2])
	c.usar_habilidade(dama, "miasma_fetido")
	assert_true(a.tem(Ser.ENJOADO))
	assert_eq(int(a.duracoes[Ser.ENJOADO]), 1, "passou: só 1 rodada")


func test_minotauro_crava_os_chifres():
	var c := Combate.new(rs, Dados.new(1))
	var mi := _ameaca("minotauro")
	var s := _saco()
	c.dados.forcar([15, 15, 15, 15, 15, 1, 1, 1, 1, 1, 1])
	c.atacar(mi, s, mi.ataques[1])
	assert_true(s.tem(Ser.AGARRADO))
	assert_eq(s.pv, 1000 - 26)
	c.dados.forcar([1, 1, 1, 1])
	c._fim_de_turno(s)
	assert_eq(s.pv, 1000 - 26 - 24, "no fim de cada turno da vítima, 4d12+20 de Sangue")


func test_kerberos_ataque_flexivel_e_devorar():
	var c := Combate.new(rs, Dados.new(1))
	var k := _ameaca("kerberos")
	var s := _saco(5000)
	c.adicionar(k)
	c.adicionar(s)
	c.acoes[k] = {"padrao": 1, "movimento": 1}
	var r := c.agredir(k, s, k.ataques[0])
	assert_eq(r.ataques_extras.size(), 3, "três mordidas e um disparo de espinhos")
	var presa := _saco(10)
	k.pv = 100
	c.dados.forcar([15, 15, 15, 15, 15, 1, 1, 1, 1, 1])
	c.atacar(k, presa, k.ataques[0])
	assert_true(presa.tem(Ser.MORTO), "devorado")
	assert_eq(k.pv, 105, "recupera metade dos PV da vítima")


func test_covil_muda_com_o_nex():
	var grupo: Array = []
	for i in 3:
		grupo.append(_agente(5))
	assert_eq(Missao.covil_para(grupo).id, "covil")
	for a in grupo:
		a.nex = 35
	assert_eq(Missao.covil_para(grupo).id, "jardim", "NEX somado 105")
	for a in grupo:
		a.nex = 65
	assert_eq(Missao.covil_para(grupo).id, "labirinto", "NEX somado 195")
	for a in grupo:
		a.nex = 99
	assert_eq(Missao.covil_para(grupo).id, "inferno")
