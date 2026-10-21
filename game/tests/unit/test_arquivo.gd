extends GutTest
## Pacote C5–C7 da crítica 20 (docs/23): Arsenal e ficha da Base, investigação mais limpa,
## briefing procedural e cerimônia de NEX.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


# --- C5 ------------------------------------------------------------------------------

func test_icone_e_efeito_dos_itens():
	assert_eq(IconeItem.tipo(rs.equipamento("faca")), "lamina")
	assert_eq(IconeItem.tipo(rs.equipamento("pistola")), "fogo")
	assert_eq(IconeItem.tipo(rs.equipamento("arco")), "arco")
	assert_eq(IconeItem.tipo(rs.equipamento("protecao_leve")), "protecao")
	assert_eq(IconeItem.tipo(rs.equipamento("cicatrizante")), "frasco")
	assert_true(IconeItem.efeito(rs.equipamento("machado"), rs).begins_with("Dano"), "arma mostra os números")
	assert_true(IconeItem.efeito(rs.equipamento("protecao_leve"), rs).begins_with("Defesa +"))


func test_pentagono_tem_cinco_vertices():
	var a := Agente.criar(rs, "Teste", "combatente", {"agi": 0, "for": 3, "int": 1, "pre": 1, "vig": 2})
	var p := PentagonoAtributos.new()
	p.agente = a
	add_child_autofree(p)
	p.size = PentagonoAtributos.TAMANHO
	await wait_frames(1)
	var v := p.vertices()
	assert_eq(v.size(), 5)
	assert_lt(v[0].y, v[2].y, "AGI no alto")


func test_ficha_da_base_em_blocos():
	var base = load("res://scenes/base_ordem.tscn").instantiate()
	add_child_autofree(base)
	await wait_frames(2)
	assert_not_null(base._pentagono.agente, "o pentágono mostra o agente escolhido")
	assert_gt(base._cabecalho_ficha.get_child_count(), 3, "nome, classe, NEX e as barras")
	assert_false(base._ficha.text.contains("PV "), "os números saem do texto: estão nas barras")
	assert_true(base._ficha.text.contains("[table=2]"), "perícias em duas colunas")
	assert_eq(base._checks_itens.values()[0].custom_minimum_size.x, 372.0, "etiquetas largas, três por linha")


# --- C6 ------------------------------------------------------------------------------

func test_pecas_pelo_tipo_do_ponto():
	assert_eq(PropsInvestigacao.tipo("computador", "Computador velho"), "tela")
	assert_eq(PropsInvestigacao.tipo("vizinha", "Vizinha na janela"), "pessoa")
	assert_eq(PropsInvestigacao.tipo("porao", "Porão trancado"), "alcapao")
	assert_eq(PropsInvestigacao.tipo("altar", "Altar raspado"), "altar")
	assert_eq(PropsInvestigacao.tipo("xyz", "Coisa"), "")
	assert_null(PropsInvestigacao.criar("xyz", "Coisa"), "sem palavra conhecida, a cena usa a peça antiga")
	var fogo := PropsInvestigacao.criar("fogueira", "Fogueira")
	add_child_autofree(fogo)
	assert_eq(fogo.find_children("*", "OmniLight3D", false, false).size(), 1, "a fogueira ilumina")


func test_investigacao_comeca_com_o_quadro_fechado_e_rotulos_so_perto():
	var inv = load("res://scenes/investigacao.tscn").instantiate()
	add_child_autofree(inv)
	await wait_frames(3)
	assert_false(inv._quadro_aberto, "a cena 3D primeiro")
	var a: Agente = inv.cena.agente_atual()
	inv._visao.figura(a).position = Vector3(100, 0, 100)
	inv._visao.atualizar_rotulos(a, "")
	for pid in inv._visao._rotulos_pontos:
		assert_false(inv._visao._rotulos_pontos[pid].visible, "longe de tudo, nenhum nome")


# --- C7 ------------------------------------------------------------------------------

func test_previa_da_missao_bate_com_a_missao():
	var p := Missao.previa(4242)
	assert_eq(p, Missao.previa(4242), "determinística")
	var m := Missao.nova(4242)
	var investigacoes := 0
	for h in m.mapa.celulas:
		if m.mapa.conteudo(h).get("tipo", "") == "investigacao":
			investigacoes += 1
	assert_eq(int(p.investigacoes), investigacoes, "a prévia descreve o mapa que a missão vai ter")
	assert_eq(int(p.celulas), m.mapa.celulas.size())


func test_briefing_nao_entrega_o_caso():
	var semente := 777
	var texto := _briefing(semente)
	assert_true(texto.contains("ARQUIVO Nº"))
	var caso := Missao.nova(semente).caso
	for parte in [String(caso.sujeito.nome), String(caso.local.nome), String(caso.acao.texto)]:
		assert_false(texto.contains(parte), "o briefing não revela: %s" % parte)


func _briefing(semente: int) -> String:
	var script = load("res://scripts/ui/base_ordem.gd")
	return script.briefing_procedural(Missao.previa(semente), [])


func test_cerimonia_de_nex_uma_vez_por_missao():
	var c := Carreira.nova()
	var a: Agente = c.roster[0]
	assert_false(CerimoniaNex.tem_o_que_mostrar({}))
	c.ultimo_relatorio = {"vitoria": true, "missao": 1, "agentes": [
		{"nome": a.nome, "id": a.id, "situacao": "voltou", "pp": 4, "nex_antes": 5, "nex": 10, "patente": "Operador", "promovido": true, "pendencias": 2},
		{"nome": "Tiago", "id": "x", "situacao": "morto"}]}
	assert_true(CerimoniaNex.tem_o_que_mostrar(c.ultimo_relatorio))
	var cer := CerimoniaNex.abrir(self, c)
	assert_eq(cer._carimbos.size(), 1, "um carimbo PROMOVIDO")
	assert_false(CerimoniaNex.tem_o_que_mostrar(c.ultimo_relatorio), "não aparece de novo")
	cer.fechar()
