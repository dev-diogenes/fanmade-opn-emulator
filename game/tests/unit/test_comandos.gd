extends GutTest
## Fase 8.1 (ADR 0007): decisões como comandos, replay determinístico e checkpoint.
## Base do online: quem parte do mesmo estado e aplica os mesmos comandos chega ao mesmo jogo.

var rs: Ruleset


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _json(v):
	return JSON.parse_string(JSON.stringify(v))


func _carreira(semente: int) -> Carreira:
	var c := Carreira.nova(rs)
	c.iniciar_missao(c.roster.duplicate(), semente)
	return c


## Encontros e investigações pendentes se resolvem pela IA (como no piloto), fora dos comandos.
func _resolver_cenas(m: Missao) -> void:
	while not m.encerrada:
		if not m.encontro_pendente.is_empty():
			var r := PilotoMissao.resolver_combate(m.ruleset, m.encontro_pendente, m.membrana)
			m.concluir_encontro(r.vencedor if r.terminou else "ameacas")
		elif not m.investigacao_pendente.is_empty():
			m.concluir_investigacao(PilotoMissao.resolver_investigacao(m))
		else:
			return


func _aplicar(m: Missao, cmd: Dictionary) -> void:
	_resolver_cenas(m)
	Comandos.aplicar_mapa(m, _json(cmd))


# --- Formato -------------------------------------------------------------------

func test_comandos_viram_json_sem_perda():
	var cmd := Comandos.novo("combate", "agredir", {"ator": 0, "alvo": 3, "foco": 1, "opcoes": {"ataque_especial": {"ataque": 5}}})
	var volta: Dictionary = _json(cmd)
	assert_eq(volta.ctx, "combate")
	assert_eq(int(volta.alvo), 3)
	assert_eq(Comandos.de_vetor(_json(Comandos.vetor(Vector2i(4, -2)))), Vector2i(4, -2))


var _aplicados: Array = []


func _aplicador_teste(cmd: Dictionary) -> Dictionary:
	_aplicados.append(cmd)
	return {"ok": true}


func test_sessao_so_aceita_a_tela_ativa():
	var s := Sessao.new()
	var aplicados := _aplicados
	s.entrar("mapa", _aplicador_teste)
	assert_false(s.enviar(Comandos.novo("combate", "mover")).ok)
	assert_true(s.enviar(Comandos.novo("mapa", "descansar")).ok)
	assert_eq(aplicados.size(), 1)
	assert_eq(s.registro.size(), 1)
	s.marcar_checkpoint({"x": 1})
	assert_eq(s.registro.size(), 0, "o checkpoint zera o registro")
	s.sair("mapa")
	assert_false(s.enviar(Comandos.novo("mapa", "descansar")).ok)


func test_mapa_valida_os_comandos():
	var m := _carreira(5).missao
	assert_true(Comandos.aplicar_mapa(m, Comandos.novo("mapa", "rolar_movimento")).ok)
	assert_false(Comandos.aplicar_mapa(m, Comandos.novo("mapa", "rolar_movimento")).ok, "não rola duas vezes")
	assert_false(Comandos.aplicar_mapa(m, Comandos.novo("mapa", "resolver_evento")).ok, "sem evento pendente")
	assert_false(Comandos.aplicar_mapa(m, Comandos.novo("mapa", "voar")).ok)


# --- Replay ---------------------------------------------------------------------

func test_missao_inteira_se_refaz_pelos_comandos():
	for semente in [3, 8]:
		var a := _carreira(semente)
		var registro: Array = []
		var rel := PilotoMissao.jogar(a.missao, 150, registro)
		assert_true(rel.encerrada)
		assert_gt(registro.size(), 10)
		var b := _carreira(semente)
		for cmd in registro:
			_aplicar(b.missao, cmd)
		_resolver_cenas(b.missao)
		assert_eq(b.missao.vitoria, a.missao.vitoria, "seed %d" % semente)
		assert_eq(b.missao.turno_mundo, a.missao.turno_mundo)
		assert_eq(Comandos.hash_missao(b.missao), Comandos.hash_missao(a.missao), "seed %d: mesmo estado no fim" % semente)


func test_checkpoint_no_meio_da_missao_continua_igual():
	var a := _carreira(11)
	var registro: Array = []
	PilotoMissao.jogar(a.missao, 150, registro)
	var meio := registro.size() / 2
	var b := _carreira(11)
	for i in meio:
		_aplicar(b.missao, registro[i])
	# Um cliente que chega agora recebe o checkpoint (a carreira inteira, como no save)
	var c := Carreira.de_dicionario(_json(b.para_dicionario()), rs)
	assert_eq(Comandos.hash_missao(c.missao), Comandos.hash_missao(b.missao), "o checkpoint reproduz o estado")
	for i in range(meio, registro.size()):
		_aplicar(b.missao, registro[i])
		_aplicar(c.missao, registro[i])
		assert_eq(Comandos.hash_missao(c.missao), Comandos.hash_missao(b.missao), "comando %d" % i)
	_resolver_cenas(b.missao)
	_resolver_cenas(c.missao)
	assert_eq(Comandos.hash_missao(c.missao), Comandos.hash_missao(a.missao))


func test_encontro_pendente_volta_com_a_mesma_seed():
	var b := _carreira(4)
	var m := b.missao
	m._preparar_encontro(m.posicao(m.agente_atual()), "emboscada", false)
	var c := Carreira.de_dicionario(_json(b.para_dicionario()), rs)
	assert_eq(int(c.missao.encontro_pendente.semente), int(m.encontro_pendente.semente))
	assert_eq(c.missao.historico.size(), m.historico.size(), "sem registro duplicado")
	assert_eq(Comandos.hash_missao(c.missao), Comandos.hash_missao(m))
	var r1 := PilotoMissao.resolver_combate(rs, m.encontro_pendente, m.membrana)
	var r2 := PilotoMissao.resolver_combate(rs, c.missao.encontro_pendente, c.missao.membrana)
	assert_eq_deep(r2, r1)


# --- Combate por comandos -----------------------------------------------------------

func _fluxo(semente: int) -> FluxoCombate:
	var m := Missao.nova(semente)
	m._preparar_encontro(m.posicao(m.agente_atual()), "celula_cultista", false)
	var f := FluxoCombate.montar(rs, m.encontro_pendente, m.membrana)
	f.iniciar()
	f.avancar_ate_decisao()
	return f


## Um jogador simples: anda até o inimigo mais perto e ataca; depois encerra o turno.
func _decisoes(f: FluxoCombate) -> Array:
	var c := f.combate
	var ser := f.decisor()
	var lista: Array = []
	var alvo := IaCombate.inimigo_mais_proximo(c, ser)
	if alvo != null and not IaCombate.pode_atacar(c, ser, alvo, f.armas[ser]):
		var destino := c.grade.aproximar(ser, alvo, ser.deslocamento_quadrados())
		if destino != c.grade.posicao(ser):
			lista.append({"acao": "mover", "celula": Comandos.vetor(destino)})
	return lista


func _comando(f: FluxoCombate, args: Dictionary) -> Dictionary:
	var cmd := Comandos.novo("combate", String(args.acao), args)
	cmd["ator"] = Comandos.ref(f.combate, f.combate.ser_atual())
	return cmd


func _jogar(f: FluxoCombate, cmd: Dictionary) -> Dictionary:
	var res := f.aplicar(cmd)
	if cmd.acao == "encerrar_turno" and res.ok:
		f.avancar_ate_decisao()
	return res


func test_combate_se_refaz_pelos_comandos():
	var a := _fluxo(21)
	var gravado: Array = []
	var passos := 0
	while a.decisor() != null and passos < 400:
		passos += 1
		var cmds: Array = []
		for d in _decisoes(a):
			cmds.append(_comando(a, d))
		for cmd in cmds:
			gravado.append({"cmd": _json(cmd), "hash": a.hash_estado()})
			_jogar(a, cmd)
		var alvo := IaCombate.inimigo_mais_proximo(a.combate, a.decisor()) if a.decisor() != null else null
		if alvo != null and IaCombate.pode_atacar(a.combate, a.decisor(), alvo, a.armas[a.decisor()]):
			var atk := _comando(a, {"acao": "agredir", "alvo": Comandos.ref(a.combate, alvo)})
			gravado.append({"cmd": _json(atk), "hash": a.hash_estado()})
			_jogar(a, atk)
		if a.decisor() != null:
			var fim := _comando(a, {"acao": "encerrar_turno"})
			gravado.append({"cmd": _json(fim), "hash": a.hash_estado()})
			_jogar(a, fim)
	assert_true(a.combate.encerrado, "o combate acaba")
	assert_gt(gravado.size(), 5)
	# Outra máquina: mesmo encontro, mesmos comandos (vindos de JSON), mesmo estado a cada decisão
	var b := _fluxo(21)
	for g in gravado:
		assert_eq(b.hash_estado(), int(g.hash), "estado antes de %s" % g.cmd.acao)
		_jogar(b, g.cmd)
	assert_true(b.combate.encerrado)
	assert_eq(b.hash_estado(), a.hash_estado())
	assert_eq(b.combate.lado_vencedor(), a.combate.lado_vencedor())


func test_combate_recusa_quem_nao_esta_na_vez():
	var f := _fluxo(22)
	var outro := -1
	for i in f.combate.participantes.size():
		if f.combate.participantes[i] != f.combate.ser_atual():
			outro = i
	var cmd := Comandos.novo("combate", "encerrar_turno", {"ator": outro})
	assert_false(f.aplicar(cmd).ok)
	assert_false(f.aplicar(Comandos.novo("combate", "agredir", {"ator": Comandos.ref(f.combate, f.combate.ser_atual()), "alvo": 99})).ok)


func test_arena_age_por_comandos():
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.semente = 3
	add_child_autofree(arena)
	await wait_seconds(0.1)
	var antes = arena.combate.ser_atual()
	assert_not_null(arena._agente_da_vez(), "a demonstração espera o jogador")
	arena._encerrar_turno()
	assert_eq(arena.sessao.registro.size(), 1)
	assert_eq(arena.sessao.registro[0].acao, "encerrar_turno")
	assert_eq(int(arena.sessao.registro[0].ator), Comandos.ref(arena.combate, antes))


func test_mapa_age_por_comandos():
	var jogo = get_node("/root/Jogo")
	var carreira_antes = jogo.carreira
	var salvar_antes: bool = jogo.salvar_automaticamente
	jogo.salvar_automaticamente = false
	jogo.carreira = _carreira(6)
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	tela._rolar()
	assert_true(jogo.carreira.missao.movimento_rolado)
	assert_eq(jogo.sessao.registro.back().acao, "rolar_movimento")
	assert_eq(jogo.sessao.contexto, "mapa")
	tela._encerrar_turno()
	assert_eq(jogo.sessao.registro.back().acao, "encerrar_turno")
	jogo.carreira = carreira_antes
	jogo.salvar_automaticamente = salvar_antes


func test_investigacao_age_por_comandos():
	var tela = load("res://scenes/investigacao.tscn").instantiate()
	add_child_autofree(tela)
	var a = tela.cena.agente_atual()
	# Relativo ao registro de antes: se um teste anterior deixou uma investigação pendente no
	# Jogo, a tela usa a sessão dele, que já traz comandos (era a falha intermitente, docs/30)
	var antes: int = tela.sessao.registro.size()
	tela._passar()
	assert_eq(tela.sessao.registro.size(), antes + 1)
	assert_eq(tela.sessao.registro.back().acao, "passar")
	assert_ne(tela.cena.agente_atual(), a, "a vez passou")
