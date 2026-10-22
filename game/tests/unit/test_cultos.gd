extends GutTest
## Cultos em cinco eixos, o vilão que liga os casos e o subgênero da missão (docs/71).


func _semente_com(cond: Callable) -> int:
	for s in range(1, 3000):
		if cond.call(s):
			return s
	return -1


func _culto_da(s: int) -> Dictionary:
	return Caso.gerar(Dados.new(s)).culto


func test_culto_tem_os_cinco_eixos_e_sai_da_semente():
	var c := Caso.gerar(Dados.new(42))
	var culto := c.culto
	for eixo in ["elemento", "fachada", "estrutura", "metodo", "sinal"]:
		assert_true(culto.has(eixo), eixo)
	assert_eq(culto.elemento, c.elemento)
	assert_eq(Caso.gerar(Dados.new(42)).culto.nome, culto.nome, "mesma semente, mesmo culto")
	var salvo := Caso.de_dicionario(c.para_dicionario())
	assert_eq(salvo.culto.nome, culto.nome)
	var antigo := c.para_dicionario()
	antigo.erase("culto")
	assert_eq(Caso.de_dicionario(antigo).culto.nome, culto.nome, "save antigo: o culto volta igual")


func test_metodo_e_estrutura_mexem_na_missao():
	var s_tv := _semente_com(func(s): return _culto_da(s).metodo.id == "transmissoes")
	assert_gt(Membrana.carregar_padrao().valor, _com_culto(s_tv).membrana.valor, "transmissões: Membrana mais fraca")
	var s_aut := _semente_com(func(s): return _culto_da(s).metodo.id == "autoridades")
	assert_eq(int(_com_culto(s_aut).credencial.limite), int(DadosJogo.ler("sinais").credencial.limite) - 1, "a credencial se queima antes")
	var s_sac := _semente_com(func(s): return _culto_da(s).metodo.id == "sacrificios")
	assert_almost_eq(_com_culto(s_sac).modificador_chefe, 0.10, 0.001, "sacrifícios: chefe mais forte")
	assert_almost_eq(Missao.nova(s_sac).modificador_chefe, 0.0, 0.001, "sem passar pela carreira (campanha, comunidade), o culto não mexe")


func _com_culto(s: int) -> Missao:
	var m := Missao.nova(s)
	m.aplicar_efeitos_do_culto()
	return m


func test_subgenero_vale_so_na_missao():
	var m := Missao.nova(42, null, [], {"sinal": {"semente": 42, "subgenero": "ilha"}})
	assert_eq(int(m._cfg.mundo.ciclo.dia), 1, "cada turno é um dia")
	assert_eq(int(m._cfg.interludio.acoes_por_agente), 1)
	assert_eq(int(DadosJogo.ler("mapa").mundo.ciclo.dia), 3, "o mapa.json das outras missões não muda")
	var outra := Missao.nova(43)
	assert_eq(int(outra._cfg.mundo.ciclo.dia), 3)
	var p := Missao.nova(44, null, [], {"sinal": {"semente": 44, "subgenero": "perseguicao"}})
	assert_eq(int(p._cfg.mundo.caca.raio), 9)
	assert_eq(int(Culto.dados_subgenero("transmissao").membrana_por_turno), -1)


func test_sinal_traz_subgenero():
	var s := Sinais.de(77, "media")
	assert_true(s.has("subgenero"))
	assert_true(DadosJogo.ler("subgeneros").lista.has(s.subgenero))


func _missao_resolvida(c: Carreira, semente: int, sinal: Dictionary) -> Dictionary:
	var m := c.iniciar_missao(c.roster.slice(0, 3), semente, sinal)
	assert_not_null(m)
	for q in m.caso.perguntas:
		q.respondida = true
	m.encerrada = true
	m.vitoria = true
	var r := c.encerrar_missao()
	for a in c.roster:
		a.nex = 5   # sem escolhas de NEX pendentes para a próxima missão
	return r


func test_vilao_liga_os_casos_e_cai():
	var c := Carreira.nova()
	var ligadas: Array = []
	for s in range(1, 400):
		var sinal := Sinais.de(s, "alta")
		if Culto.liga_ao_vilao(s) and not sinal.alarme_falso:
			ligadas.append(sinal)
		if ligadas.size() == 3:
			break
	for sinal in ligadas:
		var r := _missao_resolvida(c, int(sinal.semente), sinal)
		assert_true(r.detalhes_pp.any(func(l): return String(l).begins_with("Recorte")))
	assert_eq(c.recortes.size(), 3)
	assert_true(c.vilao_encontrado())
	var nome: String = c.vilao.nome
	var final := c.sinal_do_vilao(999)
	assert_true(final.vilao.final)
	assert_string_contains(String(final.relato), nome)
	var r_final := _missao_resolvida(c, 999, final)
	assert_true(r_final.detalhes_pp.any(func(l): return String(l).contains("cai")))
	assert_true(c.recortes.is_empty())
	assert_eq(int(c.vilao.derrotados), 1, "um vilão novo para o próximo arco")
	var salva := Carreira.de_dicionario(c.para_dicionario())
	assert_eq(salva.vilao.nome, c.vilao.nome)


func test_missao_sem_ligacao_nao_rende_recorte():
	var c := Carreira.nova()
	var s := _semente_com(func(x): return not Culto.liga_ao_vilao(x) and not Sinais.de(x, "alta").alarme_falso)
	_missao_resolvida(c, s, Sinais.de(s, "alta"))
	assert_true(c.recortes.is_empty())
	assert_false(c.vilao.is_empty(), "o vilão já existe, nas sombras")


func test_estrutura_muda_o_que_o_preso_conta():
	var s := _semente_com(func(x): return _culto_da(x).estrutura.id == "hierarquia")
	var c := Carreira.nova()
	var m := c.iniciar_missao(c.roster.slice(0, 3), s)
	m.presos.append({"nome": "Cultista", "papel": "iniciado", "elemento": m.caso.elemento})
	m.encerrada = true
	m.vitoria = true
	c.encerrar_missao()
	assert_eq(int(c.contencao[0].segredos), int(DadosJogo.ler("sinais").contencao.segredos) + 1, "hierarquia: o preso sabe mais")
