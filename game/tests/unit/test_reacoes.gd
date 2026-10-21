extends GutTest
## Reações de defesa, dano massivo e regras opcionais (Lesões, Inspiração Resoluta).

var rs: RulesetOp2022

const FICHA_CULTISTA := {
	"pv": 30, "defesa": 12,
	"atributos": {"agi": 1, "for": 1},
	"pericias": {"luta": {"dados": 1, "bonus": 5}},
	"ataques": [{"id": "adaga", "nome": "Adaga", "dano": "1d4", "margem": 19, "multiplicador": 2, "pericia": "luta", "soma_forca": true, "ataque": "corpo_a_corpo"}],
}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _defensor() -> Agente:
	return Agente.criar(rs, "Defensor", "combatente",
		{"agi": 2, "for": 2, "int": 1, "pre": 1, "vig": 2},
		{"luta": "treinado", "fortitude": "treinado", "reflexos": "treinado"})


func test_esquiva_soma_reflexos_na_defesa():
	var c := Combate.new(rs, Dados.new(1))
	var defensor := _defensor()  # Defesa 12
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	assert_true(c.declarar_reacao(defensor, "esquiva"))
	c.dados.forcar([10])   # 10 + 5 = 15: acertaria Def 12, erra Def 17
	var r := c.atacar(cultista, defensor, cultista.ataques[0])
	assert_eq(r.reacao, "esquiva")
	assert_eq(r.teste.dt, 17)
	assert_false(r.acertou)


func test_bloqueio_da_rd_igual_ao_bonus_de_fortitude():
	var c := Combate.new(rs, Dados.new(1))
	var defensor := _defensor()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	assert_true(c.declarar_reacao(defensor, "bloqueio"))
	c.dados.forcar([15, 4])   # acerta; 1d4+1 = 5, menos RD 5
	var r := c.atacar(cultista, defensor, cultista.ataques[0])
	assert_eq(r.reacao, "bloqueio")
	assert_eq(r.dano_bruto, 5)
	assert_eq(r.dano, 0)
	assert_eq(defensor.pv, defensor.pv_maximo)


func test_bloqueio_nao_funciona_contra_ataque_a_distancia():
	var c := Combate.new(rs, Dados.new(1))
	var defensor := _defensor()
	var atirador := Agente.criar(rs, "Atirador", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {"pontaria": "treinado"})
	c.declarar_reacao(defensor, "bloqueio")
	c.dados.forcar([15, 6])   # 15 (abaixo da margem 18 da pistola), 1d12 = 6
	var r := c.atacar(atirador, defensor, rs.arma("pistola"))
	assert_eq(r.reacao, "")
	assert_eq(r.dano, 6)


func test_contra_ataque_quando_o_inimigo_erra():
	var c := Combate.new(rs, Dados.new(1))
	var defensor := _defensor()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	assert_true(c.declarar_reacao(defensor, "contra_ataque", rs.arma("faca")))
	c.dados.forcar([2, 17, 9, 3])  # cultista erra; defensor (2 slots) acerta com 17, faca 1d4 = 3
	var r := c.atacar(cultista, defensor, cultista.ataques[0])
	assert_false(r.acertou)
	assert_not_null(r.contra_ataque)
	assert_true(r.contra_ataque.acertou)
	assert_eq(cultista.pv, 30 - (3 + 2))


func test_reacao_exige_treino_e_e_uma_por_rodada():
	var c := Combate.new(rs, Dados.new(1))
	var leigo := Agente.criar(rs, "Leigo", "especialista", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1})
	assert_false(c.declarar_reacao(leigo, "esquiva"))
	var defensor := _defensor()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	assert_true(c.declarar_reacao(defensor, "esquiva"))
	c.dados.forcar([1])
	c.atacar(cultista, defensor, cultista.ataques[0])
	assert_false(c.declarar_reacao(defensor, "bloqueio"), "já reagiu nesta rodada")
	defensor.iniciar_turno()
	assert_true(c.declarar_reacao(defensor, "bloqueio"))


func test_dano_massivo_pode_derrubar():
	var c := Combate.new(rs, Dados.new(1))
	var a := _defensor()   # PV 22
	c.dados.forcar([3, 2])  # Fortitude (VIG 2): 3 + 5 = 8 vs DT 17 (15 + 2 por 10 de dano)
	c.aplicar_dano(a, 12)
	assert_eq(a.pv, 0)
	assert_true(a.tem(Ser.MORRENDO))


func test_dano_massivo_resistido():
	var c := Combate.new(rs, Dados.new(1))
	var a := _defensor()
	c.dados.forcar([14, 2])  # 14 + 5 = 19 >= 17
	c.aplicar_dano(a, 12)
	assert_eq(a.pv, a.pv_maximo - 12)


func test_lesao_no_segundo_turno_morrendo():
	var c := Combate.new(rs, Dados.new(1), {"lesoes": true})
	var a := _defensor()
	a.sofrer_dano(100)
	a.iniciar_turno()
	c._verificar_lesao(a)
	assert_eq(a.lesoes.size(), 0, "só no 2º turno")
	a.iniciar_turno()
	c.dados.forcar([4, 7, 2])  # Vigor 2 (pega 7) vs DT 10: falha; 1d6 = 2 -> Força
	c._verificar_lesao(a)
	assert_eq(a.lesoes, ["for"] as Array[String])
	assert_eq(a.atributo("for"), 1)


func test_sem_regra_de_lesoes_nada_acontece():
	var c := Combate.new(rs, Dados.new(1))
	var a := _defensor()
	a.sofrer_dano(100)
	a.iniciar_turno()
	a.iniciar_turno()
	c._verificar_lesao(a)
	assert_eq(a.lesoes.size(), 0)


func test_inspiracao_resoluta():
	var c := Combate.new(rs, Dados.new(1), {"inspiracao_resoluta": true})
	var morto := _defensor()
	var aliado := _defensor()
	var cultista := Ameaca.criar(rs, "Cultista", FICHA_CULTISTA)
	c.adicionar(morto)
	c.adicionar(aliado)
	c.adicionar(cultista)
	c.dados.forcar([20])  # Fortitude contra dano massivo: passa (20 natural)
	c.aplicar_dano(morto, 15, "", 0, cultista)
	morto.sofrer_dano(100)
	for i in 3:
		morto.iniciar_turno()
	assert_true(morto.tem(Ser.MORTO))
	c.dados.forcar([1])    # 1d10 = 1 -> Chamas da Vingança
	c._sortear_inspiracoes()
	assert_eq(c.inspiracoes_pendentes.size(), 1)
	assert_eq(c.inspiracoes_pendentes[0].efeito, "chamas_da_vinganca")
	assert_true(c.aplicar_inspiracao(0, aliado))
	assert_eq(aliado.modificar_ataque(rs.arma("faca"), cultista).bonus_ataque, 5)
	assert_eq(aliado.modificar_ataque(rs.arma("faca"), aliado).bonus_ataque, 0)
	aliado.encerrar_cena()
	assert_eq(aliado.modificar_ataque(rs.arma("faca"), cultista).bonus_ataque, 0, "dura até o fim da cena")


func test_inspiracao_resoluto_cura():
	var c := Combate.new(rs, Dados.new(1), {"inspiracao_resoluta": true})
	var morto := _defensor()
	var aliado := _defensor()
	c.adicionar(morto)
	c.adicionar(aliado)
	morto.sofrer_dano(100)
	for i in 3:
		morto.iniciar_turno()
	aliado.sofrer_dano(20)
	c.dados.forcar([7, 1, 1, 1, 1, 2, 2])  # Resoluto: 4d8+4 = 8, 2d6 = 4
	c._sortear_inspiracoes()
	c.aplicar_inspiracao(0, aliado)
	assert_eq(aliado.pv, aliado.pv_maximo - 20 + 8)


# --- Primeiros Socorros e Acalmar (p.46 e p.44) ---------------------------------------

func _socorrista() -> Agente:
	return Agente.criar(rs, "Socorrista", "especialista",
		{"agi": 1, "for": 1, "int": 2, "pre": 2, "vig": 1},
		{"medicina": "treinado", "diplomacia": "treinado"})


func test_primeiros_socorros_tira_de_morrendo():
	var c := Combate.new(rs, Dados.new(1))
	var medico := _socorrista()
	var caido := _defensor()
	c.adicionar(medico)
	c.adicionar(caido)
	caido.sofrer_dano(caido.pv)
	assert_true(caido.tem(Ser.MORRENDO))
	c.acoes[medico] = {"padrao": 1, "movimento": 1}
	assert_null(c.primeiros_socorros(medico, medico), "não socorre a si mesmo")
	c.dados.forcar([20, 20])
	var t := c.primeiros_socorros(medico, caido)
	assert_not_null(t)
	assert_eq(t.dt, 20)
	assert_true(t.sucesso)
	assert_false(caido.tem(Ser.MORRENDO))
	assert_false(caido.tem(Ser.INCONSCIENTE))
	assert_eq(caido.pv, 1)
	assert_eq(int(c.acoes_restantes(medico).padrao), 0, "gasta a ação padrão")
	# Caiu de novo na mesma cena: a DT sobe +5
	caido.sofrer_dano(5)
	assert_null(c.primeiros_socorros(medico, caido), "sem ação padrão, não dá")
	c.acoes[medico] = {"padrao": 1, "movimento": 1}
	c.dados.forcar([1, 1])
	var t2 := c.primeiros_socorros(medico, caido)
	assert_eq(t2.dt, 25, "a DT sobe +5 por vez na cena")
	assert_true(caido.tem(Ser.MORRENDO), "falhou: continua morrendo")


func test_acalmar_exige_treino_e_tira_de_enlouquecendo():
	var c := Combate.new(rs, Dados.new(1))
	var amigo := _socorrista()
	var surtando := _defensor()
	c.adicionar(amigo)
	c.adicionar(surtando)
	surtando.sofrer_dano_mental(surtando.san)
	assert_true(surtando.tem(Ser.ENLOUQUECENDO))
	c.acoes[amigo] = {"padrao": 1, "movimento": 1}
	var leigo := _defensor()
	c.acoes[leigo] = {"padrao": 1, "movimento": 1}
	assert_null(c.acalmar(leigo, surtando), "sem Diplomacia nem Religião treinada, não dá")
	c.dados.forcar([20, 20])
	var t := c.acalmar(amigo, surtando)
	assert_true(t.sucesso)
	assert_false(surtando.tem(Ser.ENLOUQUECENDO))
	assert_eq(surtando.san, 1)
	assert_eq(surtando.acalmado_na_cena, 1)
