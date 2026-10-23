extends GutTest
## O culto na investigação e na luta (docs/73): o símbolo que só o Ocultismo traduz, a manchete
## do vilão no celular de uma testemunha e a estrutura do culto nos encontros.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _missao() -> Missao:
	var m := Missao.nova(42)
	m.extras["culto"] = true   # como numa missão procedural da carreira (docs/71)
	return m


func _cena(m: Missao, cena_id := "casa_abandonada") -> CenaInvestigacao:
	var h := m.posicao(m.agentes[0])
	m._preparar_investigacao(h, cena_id)
	return m.criar_cena_investigacao()


func _estrutura(m: Missao, id: String) -> void:
	m.caso.culto.estrutura = {"id": id}


# --- O símbolo do culto ------------------------------------------------------------------

func test_simbolo_aparece_e_so_o_ocultismo_traduz():
	var m := _missao()
	var cena := _cena(m)
	assert_true("simbolo_culto" in cena.pontos_restantes, "o símbolo está na parede")
	var p := cena.ponto("simbolo_culto")
	assert_eq(p.pericias.keys(), ["ocultismo"])
	assert_eq(String(p.responde), "quem")
	var a := cena.agente_atual()
	a.pericias.erase("ocultismo")
	assert_true(cena.procurar("simbolo_culto", "ocultismo").is_empty(), "sem treino, nem tenta")
	a.pericias["ocultismo"] = "treinado"
	var r := cena.examinar("simbolo_culto", "ocultismo")
	assert_false(r.is_empty())
	assert_true(m.caso.simbolo_traduzido)
	assert_string_contains(String(r.pista), String(m.caso.culto.nome), "o anel dá o nome do culto")
	assert_true(cena.detalhes_da_pista(cena.pistas_encontradas[-1]).has("simbolo"), "o close-up desenha o símbolo")


func test_simbolo_traduzido_nao_volta():
	var m := _missao()
	m.caso.simbolo_traduzido = true
	assert_false("simbolo_culto" in _cena(m).pontos_restantes)


func test_alarme_falso_nao_tem_simbolo():
	var m := _missao()
	m.alarme_falso = true
	assert_false("simbolo_culto" in _cena(m).pontos_restantes)


func test_simbolo_e_noticia_ficam_no_save():
	var m := _missao()
	m.caso.simbolo_traduzido = true
	m.caso.noticia = "Manchete"
	var c := Caso.de_dicionario(m.caso.para_dicionario())
	assert_true(c.simbolo_traduzido)
	assert_eq(c.noticia, "Manchete")


# --- A notícia do vilão -------------------------------------------------------------------

func test_noticia_aparece_no_primeiro_depoimento_da_missao_ligada():
	var m := _missao()
	m.sinal["vilao"] = {"ligado": true, "nome": "Fundação Teste"}
	var cena := _cena(m)
	assert_string_contains(cena.noticia, "Fundação Teste")
	var depo := ""
	for p in cena.cena.pontos:
		if p.get("depoimento", false):
			depo = String(p.id)
	assert_ne(depo, "", "a cena tem uma testemunha")
	cena._encontrar_pista(cena.agente_atual(), depo)
	assert_string_contains(String(cena.pistas_encontradas[-1].get("noticia", "")), "Fundação Teste")
	assert_string_contains(m.caso.noticia, "Fundação Teste")
	assert_eq(_cena(m).noticia, "", "uma vez por caso")


func test_missao_sem_vilao_nao_tem_noticia():
	assert_eq(_cena(_missao()).noticia, "")


# --- A estrutura do culto nos encontros ------------------------------------------------------

func _ids(lista: Array) -> Array:
	return lista.map(func(am): return String(am.id))


func _cultistas(m: Missao) -> Array:
	return [m.ameaca_info("iniciado"), m.ameaca_info("investido")]


func test_celulas_trazem_mais_cultistas_mais_fracos():
	var m := _missao()
	_estrutura(m, "celulas")
	var r := m._estrutura_nos_cultistas(_cultistas(m))
	assert_eq(_ids(r), ["iniciado", "iniciado", "iniciado"])
	assert_eq(String(r[0].ficha.culto.fuga), "metade")
	assert_false(DadosJogo.ameaca(rs, "iniciado").ficha.has("culto"), "a ficha do livro não muda")


func test_empresa_paga_um_seguranca():
	var m := _missao()
	_estrutura(m, "empresa")
	var r := m._estrutura_nos_cultistas(_cultistas(m))
	assert_eq(_ids(r), ["capanga", "investido"])
	assert_eq(String(r[0].nome), "Segurança da empresa")


func test_mente_coletiva_mascarada_nao_foge():
	var m := _missao()
	_estrutura(m, "mente_coletiva")
	var r := m._estrutura_nos_cultistas(_cultistas(m))
	assert_eq(r.size(), 3)
	assert_string_contains(String(r[0].nome), "mascarado")
	assert_eq(String(r[0].ficha.culto.fuga), "nunca")


func test_familia_tem_parentes():
	var m := _missao()
	_estrutura(m, "familia")
	var r := m._estrutura_nos_cultistas(_cultistas(m))
	assert_true(r[0].ficha.culto.familia)
	assert_string_contains(String(r[0].nome), ", ")


func test_hierarquia_marca_o_lider_depois_do_orcamento():
	var m := _missao()
	_estrutura(m, "hierarquia")
	var r := m._estrutura_nos_cultistas(_cultistas(m))
	m._marcar_lider(r)
	var lider: Array = r.filter(func(am): return am.ficha.culto.get("lider", false))
	assert_eq(lider.size(), 1)
	assert_eq(String(lider[0].id), "investido", "o mais forte manda")
	assert_string_contains(String(lider[0].nome), "líder")
	var sozinho := [m.ameaca_info("iniciado")]
	m._marcar_lider(sozinho)
	assert_false(sozinho[0].ficha.get("culto", {}).get("lider", false), "com um só, não há a quem obedecer")


func test_sem_culto_na_luta_nada_muda():
	var m := _missao()
	m.extras.erase("culto")
	_estrutura(m, "celulas")
	assert_false(m._culto_vale_na_luta())


func test_encontro_de_cultistas_recebe_o_traco():
	var m := _missao()
	_estrutura(m, "mente_coletiva")
	var h := m.mapa.encontrar("objetivo")
	m._preparar_encontro(h, "celula_cultista", false)
	var cult: Array = m.encontro_pendente.ameacas.filter(func(am): return String(am.id) in Missao.CULTISTAS)
	for am in cult:
		assert_eq(String(am.ficha.culto.fuga), "nunca")


# --- Na luta -------------------------------------------------------------------------------

func _pessoa(nome: String, culto: Dictionary) -> Ameaca:
	var a := Ameaca.criar(rs, nome, {"pv": 20, "defesa": 10, "atributos": {"agi": 1}, "culto": culto,
		"pericias": {"luta": {"dados": 1, "bonus": 0}}, "ataques": [rs.arma("faca")]})
	a.lado = "ameacas"
	return a


func _combate(seres: Array) -> Combate:
	var c := Combate.new(rs, Dados.new(1))
	c.adicionar(Agente.criar(rs, "A", "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {}))
	for s in seres:
		c.adicionar(s)
	return c


func test_fuga_pela_estrutura():
	var celula := _pessoa("Célula", {"fuga": "metade"})
	var c := _combate([celula])
	celula.pv = 10
	assert_true(IaAmeaca.deve_fugir(c, celula), "células fogem com metade")
	var mascara := _pessoa("Mascarado", {"fuga": "nunca"})
	var c2 := _combate([mascara])
	mascara.pv = 1
	assert_false(IaAmeaca.deve_fugir(c2, mascara), "a mente coletiva não foge")


func test_escolta_sem_lider_foge_com_metade():
	var lider := _pessoa("Líder", {"lider": true})
	var escolta := _pessoa("Escolta", {"escolta": true})
	var c := _combate([lider, escolta])
	escolta.pv = 10
	lider.pv = 0
	lider.aplicar_condicao(Ser.INCONSCIENTE)
	assert_true(IaAmeaca.deve_fugir(c, escolta))
	var comum := _pessoa("Comum", {})
	var c2 := _combate([comum])
	comum.pv = 10
	assert_false(IaAmeaca.deve_fugir(c2, comum), "sem traço, só com um quarto")


func test_familia_ganha_furia_quando_um_parente_cai():
	var tio := _pessoa("Tio", {"familia": true})
	var prima := _pessoa("Prima", {"familia": true})
	var c := _combate([tio, prima])
	c.aplicar_dano(tio, 50)
	assert_eq(int(prima.mods_cena.get("dados_ataque", 0)), 1)
	assert_eq(int(prima.modificar_ataque(rs.arma("faca"), tio).dados_extras), 1)
	c.aplicar_dano(tio, 5)
	assert_eq(int(prima.mods_cena.get("dados_ataque", 0)), 1, "o mesmo parente conta uma vez só")
