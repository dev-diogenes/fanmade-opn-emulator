extends GutTest
## Fase 8.2 (ADR 0007): a sessão em rede (validação do dono, ordem, checksum, ressincronização)
## e um host e um cliente de verdade, por ENet em localhost, jogando a mesma missão.

var rs: Ruleset
var _raizes: Array[Node] = []


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func after_each():
	for raiz in _raizes:
		if not is_instance_valid(raiz):
			continue
		var r := raiz.get_node_or_null("Rede") as Rede
		if r != null:
			r.encerrar()
		get_tree().set_multiplayer(null, raiz.get_path())
	_raizes.clear()


func _carreira(semente: int) -> Carreira:
	var c := Carreira.nova(rs)
	c.iniciar_missao(c.roster.duplicate(), semente)
	return c


func _json(v):
	return JSON.parse_string(JSON.stringify(v))


## Encontros e investigações resolvidos pela IA, igual nos dois lados (fora dos comandos).
func _resolver_cenas(m: Missao) -> void:
	while not m.encerrada:
		if not m.encontro_pendente.is_empty():
			var r := PilotoMissao.resolver_combate(m.ruleset, m.encontro_pendente, m.membrana)
			m.concluir_encontro(r.vencedor if r.terminou else "ameacas")
		elif not m.investigacao_pendente.is_empty():
			m.concluir_investigacao(PilotoMissao.resolver_investigacao(m))
		else:
			return


## Um jogador simples no mapa: resolve o evento, rola, anda para o objetivo, encerra.
func _decisao(m: Missao) -> Dictionary:
	if not m.evento_pendente.is_empty():
		return Comandos.novo("mapa", "resolver_evento")
	if not m.movimento_rolado:
		return Comandos.novo("mapa", "rolar_movimento")
	var a := m.agente_atual()
	var destinos := m.destinos()
	if destinos.is_empty() or m.movimento_restante <= 0:
		return Comandos.novo("mapa", "encerrar_turno")
	var alvo := PilotoMissao._escolher_destino(m, a, destinos, m.mapa.encontrar("objetivo"))
	if alvo == m.posicao(a):
		return Comandos.novo("mapa", "encerrar_turno")
	return Comandos.novo("mapa", "mover", {"hex": Comandos.vetor(alvo)})


func _sessao_no_mapa(s: Sessao, m: Missao, donos: ControleLocal = null) -> void:
	s.entrar("mapa", func(cmd): return Comandos.aplicar_mapa(m, cmd), func(): return m.agente_atual(), func(): return Comandos.hash_missao(m))
	if donos != null:
		s.validar_dono = func(peer, agente): return donos.peer_de(agente) == peer
	s.liberar()


# --- Sessão sem rede (fio direto) ------------------------------------------------------------

func _par(semente: int) -> Dictionary:
	var ca := _carreira(semente)
	var cb := Carreira.de_dicionario(_json(ca.para_dicionario()), rs)
	var host := Sessao.new()
	var cli := Sessao.new()
	host.iniciar_host()
	cli.iniciar_cliente()
	host.transmitir.connect(cli.receber)
	cli.pedir.connect(func(cmd): host.receber_pedido(2, cmd))
	var donos := ControleLocal.padrao()
	var j := donos.adicionar_jogador_rede(2, "Ana")
	donos.definir_dono(ca.missao.agentes[1], j)
	_sessao_no_mapa(host, ca.missao, donos)
	_sessao_no_mapa(cli, cb.missao)
	return {"host": host, "cli": cli, "mh": ca.missao, "mc": cb.missao, "ch": ca}


func test_host_so_aceita_o_dono_do_agente_da_vez():
	var p := _par(5)
	var recusas := []
	p.host.recusado.connect(func(_peer, _cmd, motivo): recusas.append(motivo))
	assert_eq(p.mh.agente_atual(), p.mh.agentes[0], "a vez é do agente do host")
	p.cli.enviar(Comandos.novo("mapa", "rolar_movimento"))
	assert_eq(recusas, ["a vez é de um agente de outro jogador"])
	assert_false(p.mh.movimento_rolado)
	assert_true(p.host.enviar(Comandos.novo("mapa", "rolar_movimento")).ok)
	assert_true(p.mh.movimento_rolado)
	assert_true(p.mc.movimento_rolado, "o cliente recebeu e aplicou")
	assert_eq(p.cli.seq, 1)
	p.host.receber_pedido(2, {"ctx": "mapa", "acao": "voar"})
	assert_eq(recusas.back(), "comando mal formado")


var _seqs: Array = []


func _anotar_seq(cmd: Dictionary) -> Dictionary:
	_seqs.append(int(cmd.seq))
	return {"ok": true}


func test_cliente_aplica_em_ordem_e_espera_a_tela():
	var cli := Sessao.new()
	cli.iniciar_cliente()
	var aplicados := _seqs
	cli.entrar("mapa", _anotar_seq)
	cli.receber(2, Comandos.novo("mapa", "encerrar_turno"), 0)
	cli.receber(1, Comandos.novo("mapa", "rolar_movimento"), 0)
	assert_eq(aplicados, [], "a tela ainda não se liberou")
	cli.liberar()
	assert_eq(aplicados, [1, 2])
	cli.receber(3, Comandos.novo("combate", "encerrar_turno"), 0)
	assert_eq(aplicados, [1, 2], "comando de combate espera a arena")
	cli.sair("mapa")
	cli.entrar("combate", _anotar_seq)
	cli.liberar()
	assert_eq(aplicados, [1, 2, 3])
	cli.receber(3, Comandos.novo("combate", "encerrar_turno"), 0)
	assert_eq(aplicados, [1, 2, 3], "repetido não aplica")


## Manda pela máquina do dono do agente da vez (o agente 1 é do cliente).
func _pelo_dono(p: Dictionary, cmd: Dictionary) -> void:
	if p.mh.agente_atual() == p.mh.agentes[1]:
		p.cli.enviar(cmd)
	else:
		p.host.enviar(cmd)


func test_dessincronia_pede_o_estado_e_o_replay_conserta():
	var p := _par(7)
	var pedidos := []
	p.cli.pedir_estado.connect(func(): pedidos.append(1))
	for i in 6:
		_pelo_dono(p, _decisao(p.mh))
		_resolver_cenas(p.mh)
		_resolver_cenas(p.mc)
	assert_eq(Comandos.hash_missao(p.mc), Comandos.hash_missao(p.mh))
	p.mc.membrana.alterar(-7, "teste")   # o cliente sai de sincronia
	_pelo_dono(p, _decisao(p.mh))
	assert_eq(pedidos.size(), 1)
	assert_eq(p.cli.dessincronias, 1)
	# Ressincronização: checkpoint do host + comandos desde então
	_resolver_cenas(p.mh)
	p.host.marcar_checkpoint(p.ch.para_dicionario())
	_pelo_dono(p, _decisao(p.mh))
	_resolver_cenas(p.mh)
	var pacote: Dictionary = _json(p.host.pacote_de_estado())
	p.cli.receber_estado(pacote)
	var nova := Carreira.de_dicionario(pacote.checkpoint, rs)
	_sessao_no_mapa(p.cli, nova.missao)
	_resolver_cenas(nova.missao)
	assert_eq(p.cli.seq, p.host.seq)
	assert_eq(Comandos.hash_missao(nova.missao), Comandos.hash_missao(p.mh), "de volta em sincronia")


func test_host_espera_a_tela_desocupar():
	var p := _par(9)
	p.host.ocupado = true
	var res: Dictionary = p.host.enviar(Comandos.novo("mapa", "rolar_movimento"))
	assert_true(res.pendente)
	assert_false(p.mh.movimento_rolado)
	p.host.liberar()
	assert_true(p.mh.movimento_rolado)
	assert_true(p.mc.movimento_rolado)


# --- ENet de verdade (host e cliente no mesmo processo) -------------------------------------

func _rede(nome: String) -> Rede:
	var raiz := Node.new()
	raiz.name = nome
	add_child_autofree(raiz)
	get_tree().set_multiplayer(SceneMultiplayer.new(), raiz.get_path())
	_raizes.append(raiz)
	var r := Rede.new()
	r.name = "Rede"
	r.ligar(Sessao.new())
	raiz.add_child(r)
	return r


func test_host_e_cliente_jogam_a_mesma_missao_por_enet():
	var porta := 30000 + randi() % 20000
	var host := _rede("Host")
	var cli := _rede("Cliente")
	var entradas: Array = []
	host.jogador_entrou.connect(func(peer, nome): entradas.append([peer, nome]))
	var pacotes: Array = []
	cli.estado_recebido.connect(func(pac): pacotes.append(pac))
	assert_eq(host.hospedar(porta), OK)
	assert_eq(cli.entrar("127.0.0.1", porta, "Ana"), OK)
	await wait_until(func(): return entradas.size() == 1, 5.0)
	assert_eq(entradas.size(), 1, "o cliente se apresentou")
	assert_eq(entradas[0][1], "Ana")
	var peer_cli: int = entradas[0][0]
	# Host: carreira com um agente do cliente; o estado vai para ele
	var ch := _carreira(12)
	ch.missao.covil_localizado = true   # o teste é da rede, não do selo do covil (docs/42)
	var donos := ControleLocal.padrao()
	donos.definir_dono(ch.missao.agentes[1], donos.adicionar_jogador_rede(peer_cli, "Ana"))
	host.sessao.marcar_checkpoint(ch.para_dicionario())
	_sessao_no_mapa(host.sessao, ch.missao, donos)
	host.enviar_estado(peer_cli, {"controles": donos.para_dicionario()})
	await wait_until(func(): return pacotes.size() == 1, 5.0)
	assert_eq(pacotes.size(), 1, "o estado chegou")
	var cc := Carreira.de_dicionario(pacotes[0].checkpoint, rs)
	var donos_cli := ControleLocal.de_dicionario(pacotes[0].controles)
	donos_cli.meu_peer = cli.meu_peer()
	assert_true(donos_cli.e_local(cc.missao.agentes[1]), "o cliente sabe qual agente é dele")
	_sessao_no_mapa(cli.sessao, cc.missao)
	assert_eq(Comandos.hash_missao(cc.missao), Comandos.hash_missao(ch.missao))
	# Cada um joga a vez dos seus agentes até a missão acabar
	var do_cliente := 0
	for i in 400:
		if ch.missao.encerrada:
			break
		var dono := donos.peer_de(ch.missao.agente_atual())
		var lado: Rede = cli if dono == peer_cli else host
		var m_lado: Missao = cc.missao if lado == cli else ch.missao
		if lado == cli:
			do_cliente += 1
		var antes := host.sessao.seq
		lado.sessao.enviar(_decisao(m_lado))
		await wait_until(func(): return host.sessao.seq > antes and cli.sessao.seq == host.sessao.seq, 5.0)
		assert_eq(cli.sessao.seq, host.sessao.seq, "comando %d chegou" % (antes + 1))
		_resolver_cenas(ch.missao)
		_resolver_cenas(cc.missao)
	assert_true(ch.missao.encerrada, "a missão acabou")
	assert_gt(do_cliente, 3, "o cliente jogou a vez do agente dele")
	assert_eq(cli.sessao.dessincronias, 0)
	assert_eq(Comandos.hash_missao(cc.missao), Comandos.hash_missao(ch.missao), "mesmo jogo nas duas máquinas")
	assert_eq(cc.missao.vitoria, ch.missao.vitoria)
	# Saída do cliente
	var saidas: Array = []
	host.jogador_saiu.connect(func(peer, _nome): saidas.append(peer))
	cli.encerrar()
	await wait_until(func(): return saidas.size() == 1, 5.0)
	assert_eq(saidas, [peer_cli])


func test_cliente_sem_host_avisa():
	var cli := _rede("Sozinho")
	var perdas: Array = []
	cli.conexao_perdida.connect(func(motivo): perdas.append(motivo))
	assert_eq(cli.entrar("127.0.0.1", 30000 + randi() % 20000, "Ana"), OK)
	await wait_until(func(): return perdas.size() == 1, 40.0)
	assert_eq(perdas.size(), 1, "sem host, a conexão falha e avisa")
	assert_false(cli.online())
