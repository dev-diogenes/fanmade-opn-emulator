extends GutTest
## O caçador único e persistente da Perseguição e as dicas de primeira vez (docs/74).

var _caminho_antes := ""


func before_each():
	_caminho_antes = Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_dicas.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))


func after_each():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = _caminho_antes
	Dicas.ativas = false


## Uma missão de Perseguição da carreira, com o caçador solto.
func _perseguicao(semente := 42) -> Missao:
	var m := Missao.nova(semente, null, [], {"sinal": {"subgenero": "perseguicao", "semente": semente}})
	m.aplicar_efeitos_do_culto()
	return m


func _hex_do_cacador(m: Missao) -> Vector2i:
	return m.cacador_no_mapa()


## O ponto de encontro é seguro: para o caçador ter presa, o grupo sai dele.
func _tirar_do_inicio(m: Missao) -> void:
	var inicio := m.posicao(m.agentes[0])
	var cacador_em := _hex_do_cacador(m)
	var melhor := inicio
	for v in Hex.vizinhos(inicio):
		if m.mapa.tem(v) and m.mapa.passavel(v) and m.mapa.conteudo(v).is_empty() and (melhor == inicio or Hex.distancia(v, cacador_em) > Hex.distancia(melhor, cacador_em)):
			melhor = v
	for a in m.agentes:
		m.posicoes[a] = melhor


# --- O caçador -------------------------------------------------------------------------------

func test_perseguicao_solta_o_cacador_longe_do_grupo():
	var m := _perseguicao()
	assert_false(m.cacador.is_empty())
	var h := _hex_do_cacador(m)
	assert_true(m.mapa.tem(h), "ele está no mapa")
	var lista: Array = Culto.dados_subgenero("perseguicao").cacador.por_elemento[m.caso.elemento]
	assert_eq(String(m.mapa.conteudo(h).encontro), "cacador_" + String(lista[0]), "uma criatura do elemento do caso")
	assert_eq(m._encontro(String(m.cacador.encontro)).ameacas, [lista[0]])
	assert_lte(int(m.ameaca_info(String(lista[0])).vd), 20, "começa no orçamento de um grupo novo (p.187)")
	assert_gte(Hex.distancia(h, m.posicao(m.agentes[0])), 6)


func test_classico_nao_tem_cacador():
	var m := Missao.nova(42)
	m.aplicar_efeitos_do_culto()
	assert_true(m.cacador.is_empty())


func test_alarme_falso_nao_tem_cacador():
	var m := Missao.nova(42, null, [], {"sinal": {"subgenero": "perseguicao", "alarme_falso": true}})
	m.aplicar_efeitos_do_culto()
	assert_true(m.cacador.is_empty())


func test_cacador_anda_de_dia_um_passo_e_de_noite_dois():
	var m := _perseguicao()
	_tirar_do_inicio(m)
	m.turno_mundo = 1
	assert_false(m.eh_noite())
	var antes := _hex_do_cacador(m)
	var alvo := m.posicao(m.agentes[0])
	m._cacar()
	var depois := _hex_do_cacador(m)
	assert_eq(Hex.distancia(antes, depois), 1, "de dia, um passo")
	assert_eq(m.passos_da_caca.filter(func(p): return p.de == antes).size(), 1)
	while not m.eh_noite():
		m.turno_mundo += 1
	m._cacar()
	var dele: Array = m.passos_da_caca.filter(func(p): return p.de == depois or (m.passos_da_caca.size() > 0 and p.de == m.passos_da_caca[0].para))
	assert_eq(dele.size(), 2, "de noite, dois passos")
	assert_eq(m.passos_da_caca[1].para, _hex_do_cacador(m))


func test_derrubado_volta_depois_de_tres_turnos():
	var m := _perseguicao()
	var h := _hex_do_cacador(m)
	for a in m.agentes:
		m.posicoes[a] = h
	m._contra_o_cacador = true
	m._preparar_encontro(h, String(m.mapa.conteudo(h).encontro), false)
	assert_true(m.encontro_pendente.cacador)
	m.concluir_encontro("agentes")
	assert_false(m.mapa.tem(_hex_do_cacador(m)), "some do mapa")
	assert_eq(int(m.cacador.derrotas), 1)
	assert_eq(int(m.cacador.estagio), 1, "volta um degrau acima")
	assert_eq(String(m.cacador.encontro), "cacador_" + String(m.cacador.lista[1]))
	var volta := int(m.cacador.volta_em)
	assert_eq(volta, m.turno_mundo + 3)
	assert_true(m.previsao(5).any(func(t): return t.eventos.any(func(e): return e.id == "cacador")), "a linha do tempo avisa")
	m.turno_mundo = volta
	m._cacador_volta()
	assert_true(m.mapa.tem(_hex_do_cacador(m)), "ele voltou")
	assert_eq(int(m.cacador.volta_em), -1)


func test_com_o_que_respondido_ele_some_de_vez():
	var m := _perseguicao()
	m.caso.pergunta("oque").respondida = true
	var h := _hex_do_cacador(m)
	for a in m.agentes:
		m.posicoes[a] = h
	var mem := m.membrana.valor
	m._contra_o_cacador = true
	m._preparar_encontro(h, String(m.mapa.conteudo(h).encontro), false)
	m.concluir_encontro("agentes")
	assert_true(m.cacador.banido)
	assert_eq(m.membrana.valor, mem + 3)
	m.turno_mundo += 10
	m._cacador_volta()
	m._cacar()
	assert_false(m.mapa.tem(_hex_do_cacador(m)), "não volta")


func test_fugir_do_cacador_deixa_ele_onde_a_luta_foi():
	var m := _perseguicao()
	var h := _hex_do_cacador(m)
	var alvo: Agente = m.agentes[0]
	_tirar_do_inicio(m)
	m.mapa.limpar_conteudo(h)
	m._contra_o_cacador = true
	m._preparar_encontro(m.posicao(alvo), String(m.cacador.encontro), false)   # a emboscada
	var onde: Vector2i = m.encontro_pendente.hex
	m.concluir_encontro("fuga")
	assert_true(m.mapa.conteudo(onde).get("cacador", false))


func test_cacador_vai_e_volta_no_save():
	var m := _perseguicao()
	m.cacador.derrotas = 2
	m.cacador.volta_em = 9
	var por_id := {}
	for a in m.agentes:
		por_id[a.id] = a
	var c := Missao.de_dicionario(m.ruleset, m.para_dicionario(), por_id)
	assert_eq(int(c.cacador.derrotas), 2)
	assert_eq(int(c.cacador.volta_em), 9)
	assert_eq(String(c.cacador.encontro), String(m.cacador.encontro))
	assert_false(c._encontro(String(c.cacador.encontro)).is_empty(), "o encontro dele vai nos extras")


# --- As dicas ------------------------------------------------------------------------------

func test_dicas_tem_texto_para_cada_sistema():
	var d: Dictionary = DadosJogo.ler("tutorial").dicas
	for id in ["municao", "oficina", "fobias", "subgenero", "cacador", "fuga", "cacada", "culto"]:
		assert_true(d.has(id), id)
		assert_ne(String(d[id].get("texto", "")), "")


func test_dica_aparece_uma_vez_e_some_quando_vista():
	var raiz := Control.new()
	add_child_autofree(raiz)
	assert_null(Dicas.mostrar(raiz, "fuga"), "desligadas fora do jogo de verdade (testes e sondas)")
	Dicas.ativas = true
	Dicas._nesta_execucao.clear()
	var camada := Dicas.mostrar(raiz, "fuga")
	assert_not_null(camada)
	assert_null(Dicas.mostrar(raiz, "fuga"), "uma vez por execução")
	Preferencias.marcar_dica("culto")
	assert_null(Dicas.mostrar(raiz, "culto"), "vista não volta")
	Preferencias.definir_dicas(false)
	assert_false(Dicas.pode("oficina"), "sem dicas")
	Preferencias.esquecer_dicas()
	assert_true(Dicas.pode("oficina"))
	Dicas._nesta_execucao.clear()


func test_tours_novos_tem_alvo_nas_telas():
	var d: Dictionary = DadosJogo.ler("tutorial").telas
	var alvos := {"combate": "fugir", "mapa": "caso", "investigacao": "cena"}
	for tela in alvos:
		assert_true(d[tela].passos.any(func(p): return String(p.get("alvo", "")) == alvos[tela]), tela)
	assert_true(d.base.passos.any(func(p): return String(p.texto).contains("Modificar")), "a Base fala de munição e da Oficina")
	assert_true(d.base.passos.any(func(p): return String(p.texto).contains("Enfermaria")), "e da Enfermaria")
