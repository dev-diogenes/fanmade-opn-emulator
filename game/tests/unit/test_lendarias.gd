extends GutTest
## Fase 4.6: enigmas do livro (etapas, temporário, melodia), Hipnose, transformação e ameaças lendárias.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _ameaca(id: String) -> Ameaca:
	var info := DadosJogo.ameaca(rs, id)
	return Ameaca.criar(rs, info.nome, info.ficha)


func _agente(pericias: Dictionary = {}, nex: int = 50) -> Agente:
	var p := {"luta": "treinado", "fortitude": "treinado"}
	p.merge(pericias, true)
	return Agente.criar(rs, "Agente", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 2}, p, nex)


func _saco(pv: int = 1000) -> Ameaca:
	var s := Ameaca.criar(rs, "Saco", {"pv": pv, "defesa": 10, "atributos": {"agi": 1, "vig": 1}})
	s.lado = "agentes"
	return s


func _combate(regras: Dictionary = {}) -> Combate:
	return Combate.new(rs, Dados.new(1), regras)


func test_espreitador_enigma_em_etapas():
	var c := _combate()
	var esp := _ameaca("espreitador")
	var a := _agente({"enganacao": "treinado", "atletismo": "treinado"})
	assert_eq(c.aplicar_dano(esp, 50, "sangue"), 0, "imune a dano")
	assert_eq(esp.etapa_atual().texto, "Fingir dormir no escuro")
	c.dados.forcar([20])
	c.decifrar_enigma(a, esp)
	assert_true(esp.enigma_pendente(), "falta fechar a fresta")
	assert_eq(esp.etapa_atual().texto, "Fechar a fresta por onde ele saiu")
	c.dados.forcar([20])
	c.decifrar_enigma(a, esp)
	assert_false(esp.enigma_pendente())
	assert_eq(c.aplicar_dano(esp, 10, "sangue"), 20, "encurralado: vulnerável a Sangue")


func test_mulher_afogada_forma_de_sangue():
	var c := _combate()
	var m := _ameaca("mulher_afogada")
	var a := _agente({"tecnologia": "treinado", "atletismo": "treinado"})
	c.adicionar(m)
	c.adicionar(a)
	assert_true(m.na_forma_de_sangue())
	assert_eq(c.aplicar_dano(m, 30, "corte"), 10, "forma de Sangue: resistência 20")
	c._inicio_de_turno_ameacas(m)
	assert_eq(m.pv, 240, "e se refaz")
	assert_true(c.usar_habilidade(m, "afogar_em_sangue", a).ok)
	assert_true(a.tem(Ser.ASFIXIADO))
	var pv := a.pv
	c.dados.forcar([1, 1, 1, 1, 1, 1])
	assert_true(c.usar_habilidade(m, "invadir_orgaos", a).ok)
	assert_eq(a.pv, pv - 6)
	assert_true(a.tem(Ser.ENJOADO))
	c.dados.forcar([20, 20, 1, 1, 1, 1, 1, 1])
	c._inicio_de_turno_ameacas(a)
	assert_false(a.tem(Ser.ASFIXIADO), "expulsou o Sangue")
	assert_true(a.tem(Ser.FRACO), "Arrancar Sangue")
	for i in 3:
		c.dados.forcar([20])
		c.decifrar_enigma(a, m)
	assert_false(m.na_forma_de_sangue(), "forçada à forma física")
	assert_eq(c.aplicar_dano(m, 30, "corte"), 30)
	assert_false(c.usar_habilidade(m, "afogar_em_sangue", a).ok)


func test_escutado_melodia_e_copias():
	var c := _combate()
	var esc := _ameaca("escutado")
	var a := _agente({"artes": "treinado"})
	c.adicionar(esc)
	c.adicionar(a)
	watch_signals(c)
	for i in 4:
		c.rodada = i + 1
		c.dados.forcar([20])
		assert_true(c.decifrar_enigma(a, esc).sucesso, "tocar a melodia")
		c._multiplicacao_melodica(esc)
	assert_signal_emit_count(c, "ser_adicionado", 4)
	assert_eq(c.participantes.size(), 2 + 4)
	var copia: Ameaca = c.participantes[2]
	assert_eq(copia.pv_maximo, 145)
	assert_eq(c.aplicar_dano(copia, 10, "corte"), 10, "cópias não são imunes")
	assert_false(esc.enigma_pendente(), "4 rodadas seguidas de melodia")
	assert_eq(c.aplicar_dano(esc, 10, "corte"), 10)


func test_escutado_sem_melodia_zera_a_contagem():
	var c := _combate()
	var esc := _ameaca("escutado")
	var a := _agente({"artes": "treinado"})
	c.adicionar(esc)
	c.rodada = 1
	c.dados.forcar([20])
	c.tocar_melodia(a)
	c._multiplicacao_melodica(esc)
	assert_eq(int(esc.enigma.rodadas), 1)
	c.rodada = 3
	c._multiplicacao_melodica(esc)
	assert_eq(int(esc.enigma.rodadas), 0)


func test_viajante_fotografado():
	var c := _combate()
	var v := _ameaca("viajante")
	var a := _agente({"percepcao": "treinado"})
	c.adicionar(v)
	c.adicionar(a)
	c.dados.forcar([20])
	c.decifrar_enigma(a, v)
	assert_true(v.mods_cena.has("visivel_ate"))
	c.dados.forcar([20, 2, 2])
	assert_true(c.atacar(a, v, rs.arma("desarmado")).acertou, "fotografado, não há chance de errar")
	c._inicio_de_turno_ameacas(a)
	assert_false(v.mods_cena.has("visivel_ate"), "até o próximo turno de quem fotografou")
	assert_true(v.enigma_pendente(), "pode ser fotografado de novo")


func test_hipnose_do_carnical():
	var c := _combate()
	var cr := _ameaca("carnical_preto_da_morte")
	var a := _agente()
	c.adicionar(cr)
	c.adicionar(a)
	c.adicionar(_agente())   # com um só agente, hipnotizá-lo encerraria o combate
	c.dados.forcar([1])
	assert_true(c.usar_habilidade(cr, "hipnose", a).ok)
	assert_eq(a.lado, "ameacas", "luta pelo carniçal")
	c.dados.forcar([20])
	c._fim_de_turno(a)
	assert_eq(a.lado, "agentes")


func test_enpap_x_se_transforma():
	var c := _combate()
	var e := _ameaca("enpap_x")
	assert_eq(e.pv_maximo, 36, "começa como um existido")
	c.aplicar_dano(e, 100, "sangue")
	assert_eq(e.nome, "Enpap-X")
	assert_eq(e.pv, 360)
	assert_false(e.esta_fora_de_combate())
	assert_eq(int(e.ataques[0].vezes), 4, "Socão x4")


func test_anomiatico_erratico():
	var c := _combate()
	var an := _ameaca("anomiatico")
	var s := _saco()
	c.adicionar(an)
	c.adicionar(s)
	c.dados.forcar([5, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5])
	assert_eq(c.comportamento_erratico(an), [5, 6, 5] as Array[int])
	assert_true(an.tem(Ser.DESPREVENIDO))
	assert_eq(s.pv, 1000 - 30, "toque de Energia pura: 10d12+20")
	var c2 := _combate()
	c2.grade = Grade.new(20, 9)
	var an2 := _ameaca("anomiatico")
	var longe := _saco()
	c2.adicionar(an2)
	c2.adicionar(longe)
	c2.grade.colocar(an2, Vector2i(0, 0))
	c2.grade.colocar(longe, Vector2i(19, 8))
	c2.dados.forcar([6, 6, 5])
	c2.comportamento_erratico(an2)
	assert_eq(an2.resistencia("impacto"), 20, "duas ações perdidas: +20")


func test_ocioso():
	var c := _combate()
	var oc := _ameaca("ocioso")
	var a := _agente()
	var b := _agente()
	c.adicionar(oc)
	c.adicionar(a)
	c.adicionar(b)
	c._escolher_alvo_ocioso(oc)
	assert_eq(oc.mods_cena.alvo_ocioso, a)
	var pv := b.pv
	c.dados.forcar([20, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	assert_false(c.atacar(b, oc, rs.arma("desarmado")).acertou, "b não o vê")
	assert_eq(b.pv, pv, "a Retaliação é não letal (p.254, docs/46): os PV letais não caem")
	assert_eq(b.dano_nao_letal, 24, "Retaliação")
	assert_false(c.usar_habilidade(oc, "aterrorizar", b).ok, "só contra o seu alvo")
	var san := a.san
	c.dados.forcar([5, 5, 5, 5])
	assert_true(c.usar_habilidade(oc, "aterrorizar", a).ok)
	assert_eq(a.san, maxi(0, san - 30))


func test_carente_regeneracao_ferrao_e_abraco():
	var c := _combate()
	var ca := _ameaca("carente")
	var a := _agente()
	c.adicionar(ca)
	c.adicionar(a)
	c.aplicar_dano(ca, 50, "sangue")
	c._inicio_de_turno_ameacas(ca)
	assert_eq(ca.pv, 700 - 30 + 20, "cura acelerada 20")
	c.aplicar_dano(ca, 30, "energia")
	var pv := ca.pv
	c._inicio_de_turno_ameacas(ca)
	assert_eq(ca.pv, pv, "Energia desliga a regeneração")
	c.dados.forcar([1])
	assert_true(c.usar_habilidade(ca, "voce_e_minha_mamae", a).ok)
	assert_true(a.tem(Ser.PARALISADO))
	c.aplicar_dano(ca, 5, "energia")
	assert_false(a.tem(Ser.PARALISADO), "dano de Energia faz soltar")
	var s := _saco()
	c.dados.forcar([15, 15, 15, 15, 1, 1, 1])
	c.atacar(ca, s, ca.ataques[1])
	assert_true(s.tem(Ser.DEBILITADO))
	assert_true(s.tem(Ser.ENJOADO))


func test_arena_com_o_anomiatico():
	var m := Missao.nova(42)
	for a in m.agentes:
		a.nex = 99
		a.recalcular_maximos(true)
		m.posicoes[a] = m.posicao(m.agente_atual())
	m._preparar_encontro(m.posicao(m.agente_atual()), "anomalia", false)
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.config = m.encontro_pendente
	arena.autoplay = true
	arena.semente = 11
	add_child_autofree(arena)
	assert_true(arena.combate.encerrado)
