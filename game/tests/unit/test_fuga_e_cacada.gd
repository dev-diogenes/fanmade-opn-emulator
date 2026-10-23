extends GutTest
## Fuga e caçada (docs/72) sobre o teste estendido do livro (p.86-87): o grupo foge junto,
## a pessoa quase morta e sozinha foge, e o grupo pode caçá-la depois da luta.

var rs: RulesetOp2022
const FUGA := {"atletismo": "expert", "acrobacia": "expert", "furtividade": "expert", "percepcao": "expert",
	"sobrevivencia": "expert", "tatica": "expert", "investigacao": "expert", "intimidacao": "expert"}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _rapido() -> Agente:
	return Agente.criar(rs, "Rápido", "especialista", {"agi": 5, "for": 1, "int": 1, "pre": 5, "vig": 1}, FUGA)


func _lento() -> Agente:
	return Agente.criar(rs, "Lento", "combatente", {"agi": 0, "for": 1, "int": 0, "pre": 0, "vig": 1}, {})


func _pessoa() -> Ameaca:
	var a := Ameaca.criar(rs, "Cultista", {"pv": 20, "defesa": 10, "atributos": {"agi": 1, "for": 1},
		"pericias": {"luta": {"dados": 1, "bonus": 0}}, "ataques": [rs.arma("faca")]})
	a.lado = "ameacas"
	return a


func _criatura() -> Ameaca:
	var c := Ameaca.criar(rs, "Bicho", {"pv": 60, "defesa": 10, "criatura": true, "atributos": {"agi": 1, "for": 2},
		"pericias": {"luta": {"dados": 2, "bonus": 5}}, "ataques": [rs.arma("machete")]})
	c.lado = "ameacas"
	return c


## Combate começado, na vez do primeiro agente.
func _combate(agentes: Array, ameacas: Array, regras := {}, semente := 1) -> Combate:
	var c := Combate.new(rs, Dados.new(semente), regras)
	for s in agentes + ameacas:
		c.adicionar(s)
	c.iniciar()
	while not c.ser_atual() is Agente:
		c.proximo_turno()
	return c


# --- Teste estendido -------------------------------------------------------------------

func test_teste_estendido_junta_sucessos_e_troca_de_pericia():
	var a := _rapido()
	var t := TesteEstendido.novo(15, "media", ["atletismo", "acrobacia", "furtividade"])
	assert_eq(t.exigidos, 5)
	var usadas := []
	for i in 3:
		usadas.append(String(t.testar(Dados.new(i), a).pericia))
	usadas.sort()
	assert_eq(usadas, ["acrobacia", "atletismo", "furtividade"], "não repete enquanto houver perícia nova")
	assert_eq(t.sucessos, 3, "expert com AGI 5 não falha DT 15")
	t.testar(Dados.new(9), a)
	t.testar(Dados.new(10), a)
	assert_true(t.terminou())
	assert_true(t.venceu())


func test_teste_estendido_acaba_em_tres_falhas():
	var t := TesteEstendido.novo(40, "baixa", ["atletismo"])
	var a := _lento()
	for i in 5:
		t.testar(Dados.new(i), a)
	assert_eq(t.falhas, 3)
	assert_true(t.terminou())
	assert_false(t.venceu())
	assert_eq(t.registros.size(), 3, "para no fim")


# --- Fugir -------------------------------------------------------------------------------

func test_dificuldade_pelo_perseguidor():
	assert_eq(_combate([_rapido()], [_pessoa()]).dificuldade_da_fuga(), {"dt": 15, "complexidade": "baixa"})
	assert_eq(_combate([_rapido()], [_criatura()]).dificuldade_da_fuga(), {"dt": 20, "complexidade": "media"})
	assert_eq(_combate([_rapido()], [_criatura()], {"chefe": true}).dificuldade_da_fuga(), {"dt": 25, "complexidade": "alta"})


func test_fuga_bem_sucedida_encerra_o_combate_como_fuga():
	var a := _rapido()
	var c := _combate([a, _rapido()], [_criatura()])
	var vencedores := []
	c.combate_encerrado.connect(func(v): vencedores.append(v))
	var r := c.fugir(c.ser_atual() as Agente)
	assert_true(r.ok)
	assert_true(r.fugiu, r.placar)
	assert_true(c.encerrado)
	assert_eq(c.lado_vencedor(), "fuga")
	assert_eq(vencedores, ["fuga"])


func test_fuga_falha_deixa_encurralado_e_o_perseguidor_ataca():
	var lento := _lento()
	var bicho := _criatura()
	var c := _combate([lento], [bicho], {"chefe": true})
	var golpes := []
	c.ataque_resolvido.connect(func(r): golpes.append(r))
	var r := c.fugir(lento)
	assert_true(r.ok)
	assert_false(r.fugiu, "DT 25 sem treino e com AGI 0 não passa")
	assert_false(c.encerrado and c.lado_vencedor() == "fuga")
	assert_gt(golpes.size(), 0, "cada falha deixa o bicho alcançar")
	assert_eq(golpes[0].atacante, bicho)
	if not lento.esta_fora_de_combate():
		assert_true(lento.tem(Ser.DESPREVENIDO), "encurralado")


func test_fugir_pede_a_acao_completa_e_ninguem_preso():
	var a := _rapido()
	var b := _rapido()
	var c := _combate([a, b], [_pessoa()])
	var atual := c.ser_atual() as Agente
	var outro := b if atual == a else a
	outro.aplicar_condicao(Ser.AGARRADO)
	assert_string_contains(c.motivo_fugir(atual), "preso")
	outro.condicoes.erase(Ser.AGARRADO)
	assert_eq(c.motivo_fugir(atual), "")
	c.gastar_acao(atual, "movimento")
	assert_string_contains(c.motivo_fugir(atual), "completa")


# --- A ameaça que foge e a caçada ----------------------------------------------------------

func test_pessoa_quase_morta_e_sozinha_foge():
	var p := _pessoa()
	var p2 := _pessoa()
	var c := _combate([_rapido()], [p, p2])
	p.pv = 4
	assert_false(IaAmeaca.deve_fugir(c, p), "ainda tem alguém do lado dela")
	p2.pv = 0
	p2.aplicar_condicao(Ser.INCONSCIENTE)
	assert_true(IaAmeaca.deve_fugir(c, p))
	var bicho := _criatura()
	bicho.pv = 1
	assert_false(IaAmeaca.deve_fugir(_combate([_rapido()], [bicho]), bicho), "criatura do Outro Lado não foge")
	var chefe := _pessoa()
	chefe.pv = 1
	assert_false(IaAmeaca.deve_fugir(_combate([_rapido()], [chefe], {"chefe": true}), chefe), "no covil, ninguém foge")


func test_fugitivo_encerra_a_luta_e_a_cacada_o_pega():
	var p := _pessoa()
	var c := _combate([_rapido(), _rapido()], [p])
	c.fuga_da_ameaca(p)
	assert_true(c.encerrado)
	assert_eq(c.lado_vencedor(), "agentes")
	assert_eq(c.fugitivos(), [p])
	assert_eq(c.fugitivos_escapados(), 1, "sem caçada, ele escapa")
	var r := c.cacar_fugitivo()
	assert_true(r.pegou, r.placar)
	assert_eq(c.rendidos(), [p], "vai para o interrogatório")
	assert_eq(c.fugitivos_escapados(), 0)
	assert_true(c.fugitivos().is_empty())


func test_cacada_que_falha_deixa_o_fugitivo_escapar():
	var p := _pessoa()
	var c := _combate([_lento()], [p], {}, 3)
	c.fuga_da_ameaca(p)
	var r := c.cacar_fugitivo()
	assert_false(r.pegou, r.placar)
	assert_eq(c.fugitivos_escapados(), 1)
	assert_true(c.fugitivos().is_empty(), "já foi caçado")
	assert_false(c.cacar_fugitivo().ok)


# --- No mapa --------------------------------------------------------------------------------

func _missao_em_encontro() -> Array:
	var m := Missao.nova(42)
	var h := Vector2i(-999, -999)
	for cel in m.mapa.celulas:
		if String(m.mapa.conteudo(cel).get("tipo", "")) == "encontro":
			h = cel
			break
	for a in m.agentes:
		m.posicoes[a] = h
	m._preparar_encontro(h, String(m.mapa.conteudo(h).encontro), false)
	return [m, h]


func test_fugir_deixa_o_encontro_no_mapa_e_recua_o_grupo():
	var par := _missao_em_encontro()
	var m: Missao = par[0]
	var h: Vector2i = par[1]
	var antes := m.membrana.valor
	m.concluir_encontro("fuga")
	assert_true(m.encontro_pendente.is_empty())
	assert_eq(String(m.mapa.conteudo(h).get("tipo", "")), "encontro", "o que estava ali continua lá")
	assert_eq(m.membrana.valor, antes - 2)
	for a in m.agentes:
		assert_ne(m.posicao(a), h, "o grupo recua")
		assert_eq(Hex.distancia(m.posicao(a), h), 1)


func test_fugitivo_escapado_avisa_o_culto():
	var par := _missao_em_encontro()
	var m: Missao = par[0]
	var antes := m.membrana.valor
	m.concluir_encontro("agentes", 0, 1)
	assert_eq(m.membrana.valor, antes - 2)
