extends GutTest
## Testemunhas com nome e o momento da pista (docs/56).

var rs: RulesetOp2022
var m: Missao


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func before_each():
	m = Missao.nova(42)


func _cena(id: String) -> CenaInvestigacao:
	return CenaInvestigacao.nova(rs, Dados.new(5), m.caso, id, m.agentes)


func test_testemunhas_ganham_nome_aparencia_e_jeito():
	var c := _cena("velorio")
	assert_eq(c.testemunhas.size(), 2, "a viúva e o agente funerário")
	var viuva: Dictionary = c.testemunhas.viuva
	var d := DadosJogo.ler("testemunhas")
	var primeiro := String(viuva.nome).replace("Dona ", "")
	assert_true(primeiro in d.nomes_f, "a viúva tem nome de mulher")
	assert_true(String(viuva.aparencia) in d.aparencias)
	assert_true(String(viuva.jeito) in d.jeitos)
	assert_string_contains(c.ponto("viuva").nome, " · Viúva", "o nome aparece no ponto")
	var de_novo := _cena("velorio")
	assert_eq(de_novo.testemunhas.viuva.nome, viuva.nome, "a mesma semente, a mesma pessoa (online)")
	assert_eq(DadosJogo.ler("cenas_investigacao").cenas.filter(func(x): return x.id == "velorio")[0].pontos.filter(func(p): return p.id == "viuva")[0].nome, "Viúva", "os dados não mudam")


func test_o_depoimento_comeca_por_quem_fala():
	var c := _cena("velorio")
	var cleber: Agente = c.agentes[0]
	var texto := c._encontrar_pista(cleber, "viuva", false, -1, "diplomacia")
	assert_true(texto.begins_with(String(c.testemunhas.viuva.nome)))
	var achada: Dictionary = c.pistas_encontradas.back()
	assert_eq(achada.pericia, "diplomacia")
	var ouvidas: Array = c.resultado().testemunhas
	assert_eq(ouvidas.size(), 1)
	assert_eq(ouvidas[0].papel, "Viúva")


func test_detalhes_do_close_up():
	m.caso.elemento = "morte"
	var c := _cena("delegacia")
	c._encontrar_pista(c.agentes[0], "radio_viatura", false, -1, "tecnologia")
	var det: Dictionary = c.detalhes_da_pista(c.pistas_encontradas.back())
	assert_eq(det.lente, "a câmera modificada")
	assert_string_contains(det.sentido, "vulto cinzento", "a assinatura canônica da Morte na câmera (wiki)")
	assert_ne(det.rotulo, "")
	m.caso.elemento = "sangue"
	c._encontrar_pista(c.agentes[0], "boletins", false, -1, "investigacao")
	assert_string_contains(c.detalhes_da_pista(c.pistas_encontradas.back()).sentido, "carne podre")


func test_close_up_mostra_o_achado():
	var cp := CloseupPista.mostrar(self, {"titulo": "Caixão pregado", "lente": "a lanterna", "sentido": "Cheiro de cinza.",
		"texto": "Algo errado.", "rotulo": "Cheiro de carne", "duvidosa": false})
	var textos: Array = cp.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has("PISTA · CAIXÃO PREGADO"))
	assert_true(textos.has("✔ CHEIRO DE CARNE"), "o traço carimbado")
	assert_true(textos.has("Com a lanterna."))
	cp.free()


func test_testemunha_pode_sumir_a_noite():
	m.testemunhas_vistas = [{"nome": "Lurdes", "papel": "Vizinha na janela", "cena": "Casa abandonada", "sumiu": false}]
	var antes := m.membrana.valor
	var sumiu := false
	for t in range(4, 80, 5):   # toda virada para a noite
		m.turno_mundo = t
		m._sumir_testemunha()
		if m.testemunhas_vistas[0].sumiu:
			sumiu = true
			break
	assert_true(sumiu, "numa das noites, ela some")
	assert_eq(m.membrana.valor, antes - 2, "o medo se espalha: a Membrana cai 2")
	assert_string_contains(m.historico.back(), "Lurdes")


func test_com_o_caso_fechado_ninguem_some():
	m.testemunhas_vistas = [{"nome": "Lurdes", "papel": "Vizinha", "cena": "Casa", "sumiu": false}]
	m.caso.pergunta("oque").respondida = true
	for t in range(4, 80, 5):
		m.turno_mundo = t
		m._sumir_testemunha()
	assert_false(m.testemunhas_vistas[0].sumiu)


func test_testemunhas_vistas_no_save():
	m.testemunhas_vistas = [{"nome": "Tião", "papel": "Zelador", "cena": "Capela", "sumiu": true}]
	var por_id := {}
	for a in m.agentes_iniciais:
		por_id[a.id] = a
	var m2 := Missao.de_dicionario(m.ruleset, JSON.parse_string(JSON.stringify(m.para_dicionario())), por_id)
	assert_eq(m2.testemunhas_vistas[0].nome, "Tião")
	assert_true(m2.testemunhas_vistas[0].sumiu)
