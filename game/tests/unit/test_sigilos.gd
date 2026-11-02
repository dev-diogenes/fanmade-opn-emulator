extends GutTest
## Sigilos e cifra (docs/77): o sigilo de cada elemento e de cada ritual, o alfabeto de sigilos
## do jogo, o nome do culto escrito no anel e a tabela de letras que a Ordem guarda na carreira.


func _assinatura(linhas: Array) -> String:
	var partes: PackedStringArray = []
	for l in linhas:
		var pts: PackedStringArray = []
		for q in l:
			pts.append("%.3f,%.3f" % [q.x, q.y])
		partes.append(";".join(pts))
	return "|".join(partes)


# --- Sigilos ----------------------------------------------------------------------------------

func test_sigilo_de_elemento_e_deterministico_e_muda_com_o_elemento():
	var vistos := {}
	for el in Sigilo.ELEMENTOS:
		var a := _assinatura(Sigilo.gerar_elemento(el, 77))
		assert_eq(a, _assinatura(Sigilo.gerar_elemento(el, 77)), "%s: a mesma semente dá o mesmo sigilo" % el)
		assert_ne(a, _assinatura(Sigilo.gerar_elemento(el, 78)), "%s: outra semente, outro sigilo" % el)
		vistos[a] = el
	assert_eq(vistos.size(), Sigilo.ELEMENTOS.size(), "cada elemento tem o próprio miolo")


func test_forma_do_ritual_poe_mais_aneis():
	var indouta := Sigilo.gerar_elemento("sangue", 5, 0).size()
	var discente := Sigilo.gerar_elemento("sangue", 5, 1).size()
	var verdadeiro := Sigilo.gerar_elemento("sangue", 5, 2).size()
	assert_gt(discente, indouta)
	assert_gt(verdadeiro, discente)


func test_sigilo_de_ritual_vem_do_ritual():
	var rs := RulesetOp2022.carregar_padrao()
	var r := rs.ritual("amaldicoar_arma_conhecimento")
	var info := Sigilo.de_ritual(r, "verdadeiro")
	assert_eq(String(info.elemento), "conhecimento")
	assert_eq(int(info.forma), 2)
	assert_eq(int(info.semente), int(Sigilo.de_ritual(r).semente), "a forma não muda a semente")
	var tex := Sigilo.imagem(int(info.semente), 64, Color.WHITE, 3.0, String(info.elemento), int(info.forma))
	assert_eq(tex.get_width(), 64)


func test_sem_elemento_continua_o_sigilo_antigo():
	assert_eq(_assinatura(Sigilo.gerar_de(1987)), _assinatura(Sigilo.gerar(1987)))
	assert_eq(_assinatura(Sigilo.gerar_de(1987, "nada")), _assinatura(Sigilo.gerar(1987)))


func test_vinte_e_seis_glifos_diferentes():
	var vistos := {}
	for i in 26:
		vistos[_assinatura(Sigilo.glifo(i))] = i
	assert_eq(vistos.size(), 26)


# --- Cifra ------------------------------------------------------------------------------------

func test_cifra_normaliza_cifra_e_le():
	assert_eq(Cifra.normalizar("  Círculo  da Ação-7 "), "CIRCULO DA ACAO")
	assert_eq(Cifra.cifrar("Ab c"), [0, 1, -1, 2])
	assert_eq(Cifra.letras("Ana"), ["A", "N"])
	assert_eq(Cifra.leitura("Ana Rosa", ["A"]), "A_A ___A")
	assert_eq(Cifra.faltam("Ana Rosa", ["A", "N"]), 3)
	assert_eq(Cifra.aprender(["Z"], "Ana"), ["A", "N", "Z"])
	var de_volta := ""
	for i in Cifra.cifrar("Seita Vermelha"):
		de_volta += " " if i < 0 else Cifra.ALFABETO[i]
	assert_eq(de_volta, "SEITA VERMELHA", "cifrar e ler de volta dá o nome")


# --- O símbolo do culto e a tabela da Ordem --------------------------------------------------

func _cena(sigilos: Array) -> CenaInvestigacao:
	var m := Missao.nova(42)
	m.extras["culto"] = true
	m.sigilos_conhecidos = sigilos
	m._preparar_investigacao(m.posicao(m.agentes[0]), "casa_abandonada")
	return m.criar_cena_investigacao()


func test_tabela_da_ordem_facilita_ler_o_simbolo():
	var cena := _cena([])
	var nome := String(cena.caso.culto.nome)
	var dt_base := int(DadosJogo.ler("cultos").simbolo.pericias.ocultismo)
	var p := cena.ponto("simbolo_culto")
	assert_eq(int(p.pericias.ocultismo), dt_base, "sem tabela, a DT do livro")
	assert_false(p.pericias.has("investigacao"))
	assert_eq(Cifra.cifrar(String(p.texto_cifrado)), Cifra.cifrar(nome), "o anel escreve o nome do culto")
	var letras := Cifra.letras(nome)
	var metade := letras.slice(0, int(ceil(letras.size() / 2.0)))
	p = _cena(metade).ponto("simbolo_culto")
	assert_eq(int(p.pericias.ocultismo), dt_base - 5, "metade das letras: DT menor")
	p = _cena(letras).ponto("simbolo_culto")
	assert_true(p.pericias.has("investigacao"), "todas as letras: qualquer um lê pela tabela")
	assert_lt(int(p.pericias.ocultismo), dt_base - 5)


func test_close_up_mostra_o_anel_lido():
	var cena := _cena([])
	var a := cena.agente_atual()
	a.pericias["ocultismo"] = "treinado"
	var r := cena.examinar("simbolo_culto", "ocultismo")
	assert_false(r.is_empty())
	var d := cena.detalhes_da_pista(cena.pistas_encontradas[-1])
	assert_eq(String(d.simbolo.leitura), Cifra.normalizar(String(cena.caso.culto.nome)))
	assert_eq(int(d.simbolo.novas), Cifra.letras(String(cena.caso.culto.nome)).size(), "tudo é novo para quem não tem tabela")


func test_carreira_aprende_as_letras_e_guarda_no_save():
	var c := Carreira.nova()
	var m := c.iniciar_missao(c.roster.slice(0, 3), 42)
	assert_not_null(m)
	assert_eq(m.sigilos_conhecidos, [], "carreira nova não conhece sigilos")
	if m.caso.culto.is_empty():
		pass_test("missão sem culto")
		return
	m.caso.simbolo_traduzido = true
	m.encerrada = true
	m.vitoria = true
	var r := c.encerrar_missao()
	var nome := String(m.caso.culto.nome)
	assert_eq(c.sigilos_conhecidos, Cifra.letras(nome))
	assert_true(r.detalhes_pp.any(func(l): return String(l).begins_with("Sigilos novos")))
	var salva := Carreira.de_dicionario(c.para_dicionario())
	assert_eq(salva.sigilos_conhecidos, c.sigilos_conhecidos)
	for a in c.roster:
		a.nex = 5
	var m2 := c.iniciar_missao(c.roster.slice(0, 3), 43)
	assert_eq(m2.sigilos_conhecidos, c.sigilos_conhecidos, "a próxima missão leva a tabela")
	assert_eq(Carreira.de_dicionario(c.para_dicionario()).missao.sigilos_conhecidos, c.sigilos_conhecidos, "e o save no meio da missão também")
