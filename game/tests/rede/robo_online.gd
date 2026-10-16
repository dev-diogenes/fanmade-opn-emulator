extends Node
## Teste de fumaça online com dois processos (tools/teste_online.sh): um robô joga, pelas
## telas de verdade, a vez dos agentes da própria máquina. O host hospeda e, quando o cliente
## entra, dá a ele um agente e começa a missão. No fim, cada lado imprime o hash da missão,
## e o script compara. Argumentos: -- --papel=host|cliente --porta=N --semente=N [--tarde=1]
## Com --tarde=1, o host começa sozinho e o cliente entra no meio da missão (checkpoint + replay).

var papel := "host"
var porta := 24555
var semente := 7
var tarde := false
var _investigou := false
var jogo: Node
var _espera := 0.0
var _seq_enviado := -1
var _passo_turno := {}       ## turno do combate -> passo do robô (0 andar, 1 atacar, 2 encerrar)
var _saiu_combate := -1
var _terminou := false
var _tempo := 0.0
var _enviado_em := 0.0
var _por_tela := {}          ## contexto -> comandos aplicados


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var partes := arg.trim_prefix("--").split("=")
		if partes.size() == 2:
			match partes[0]:
				"papel": papel = partes[1]
				"porta": porta = partes[1].to_int()
				"semente": semente = partes[1].to_int()
				"tarde": tarde = partes[1] == "1"
	Engine.time_scale = 20.0
	jogo = get_node("/root/Jogo")
	jogo.salvar_automaticamente = false
	jogo.sessao.comando_aplicado.connect(func(cmd, _res): _por_tela[cmd.ctx] = int(_por_tela.get(cmd.ctx, 0)) + 1)
	jogo.carreira = Carreira.nova()
	if papel == "host":
		jogo.rede.jogador_entrou.connect(_ao_entrar)
		var erro: Error = jogo.hospedar(porta)
		print("ROBO host hospedando na porta %d: %s" % [porta, error_string(erro)])
		if tarde:
			jogo.iniciar_missao(jogo.carreira.roster.duplicate(), semente)
	else:
		await get_tree().create_timer((4.0 if tarde else 0.5) * Engine.time_scale).timeout   # dá tempo ao host
		var erro: Error = jogo.entrar_em_sessao("127.0.0.1", porta, "Robo")
		print("ROBO cliente entrando: %s" % error_string(erro))


func _ao_entrar(peer: int, nome: String) -> void:
	print("ROBO host: entrou %s (peer %d)" % [nome, peer])
	var c: Carreira = jogo.carreira
	jogo.controles().definir_dono(c.roster[1], c.controles.jogadores.size() - 1)
	jogo.controles_mudaram()
	if jogo.missao != null:
		print("ROBO host: cliente entrou no meio da missão (comando %d)" % jogo.sessao.seq)
		return
	await get_tree().create_timer(0.3 * Engine.time_scale).timeout
	jogo.iniciar_missao(c.roster.duplicate(), semente)


func _process(delta: float) -> void:
	_tempo += delta / Engine.time_scale
	if _tempo > 240.0 and not _terminou:
		print("ROBO %s TEMPO ESGOTADO" % papel)
		_diagnostico()
		_terminar()
	_espera -= delta
	if _espera > 0.0 or _terminou:
		return
	_espera = 0.05 * Engine.time_scale
	var cena := get_tree().current_scene
	if cena == null or jogo.missao == null:
		return
	var m: Missao = jogo.missao
	if m.encerrada and cena.scene_file_path == "res://scenes/mapa_mundo.tscn":
		print("ROBO RESULTADO %s hash=%d vitoria=%s seq=%d dessincronias=%d turnos=%d comandos=%s" % [papel, Comandos.hash_missao(m), m.vitoria, jogo.sessao.seq, jogo.sessao.dessincronias, m.turno_mundo, _por_tela])
		_terminar()
		return
	if jogo.sessao.seq == _seq_enviado and _tempo - _enviado_em < 3.0:
		return   # esperando o comando voltar do host
	if jogo.sessao.ocupado or jogo.sessao.atrasado():
		return   # a tela ainda está animando ou alcançando
	if cena.scene_file_path == "res://scenes/mapa_mundo.tscn":
		_jogar_mapa(cena, m)
	elif cena.scene_file_path == "res://scenes/arena_teste.tscn":
		_jogar_arena(cena)
	elif cena.scene_file_path == "res://scenes/investigacao.tscn":
		_jogar_investigacao(cena)


func _enviar(cena: Node, acao: String, args: Dictionary = {}) -> void:
	_seq_enviado = jogo.sessao.seq
	_enviado_em = _tempo
	cena._enviar(acao, args)
	if jogo.sessao.modo == Sessao.HOST:
		_seq_enviado = -1   # no host o comando já foi aplicado


func _jogar_mapa(cena: Node, m: Missao) -> void:
	var a := m.agente_atual()
	if a == null or not jogo.controles().e_local(a) or not m.encontro_pendente.is_empty() or not m.investigacao_pendente.is_empty():
		return
	if not m.evento_pendente.is_empty():
		_enviar(cena, "resolver_evento")
	elif not m.movimento_rolado:
		_enviar(cena, "rolar_movimento")
	else:
		var destinos := m.destinos()
		var alvo := m.posicao(a) if destinos.is_empty() else _destino(m, a, destinos)
		if m.movimento_restante <= 0 or alvo == m.posicao(a):
			_enviar(cena, "encerrar_turno")
		else:
			_enviar(cena, "mover", {"hex": Comandos.vetor(alvo)})


## Antes do covil, passa por uma investigação (para o teste cobrir as três telas).
func _destino(m: Missao, a: Agente, destinos: Dictionary) -> Vector2i:
	var inv := Vector2i(-999, -999)
	if not _investigou:
		for h in m.mapa.celulas:
			if m.mapa.conteudo(h).get("tipo", "") == "investigacao" and (inv == Vector2i(-999, -999) or Hex.distancia(h, m.posicao(a)) < Hex.distancia(inv, m.posicao(a))):
				inv = h
	if inv == Vector2i(-999, -999):
		return PilotoMissao._escolher_destino(m, a, destinos, m.mapa.encontrar("objetivo"))
	var melhor := m.posicao(a)
	for h in destinos:
		if Hex.distancia(h, inv) < Hex.distancia(melhor, inv):
			melhor = h
	return melhor


func _jogar_arena(cena: Node) -> void:
	var f: FluxoCombate = cena.fluxo
	if f.combate.encerrado:
		if papel == "host" and _saiu_combate != f.get_instance_id():
			_saiu_combate = f.get_instance_id()
			_enviar(cena, "sair")
		return
	var ser := f.decisor()
	if ser == null or not jogo.controles().e_local(ser as Agente):
		return
	var c := f.combate
	var alvo := IaCombate.inimigo_mais_proximo(c, ser)
	var passo: int = _passo_turno.get(f.turnos, 0)
	_passo_turno[f.turnos] = passo + 1
	if passo == 0 and alvo != null and not IaCombate.pode_atacar(c, ser, alvo, f.armas[ser]):
		var destino := c.grade.aproximar(ser, alvo, ser.deslocamento_quadrados())
		if destino != c.grade.posicao(ser):
			_enviar(cena, "mover", {"celula": Comandos.vetor(destino)})
			return
	if passo <= 1 and alvo != null and IaCombate.pode_atacar(c, ser, alvo, f.armas[ser]):
		_passo_turno[f.turnos] = 2
		_enviar(cena, "agredir", {"alvo": Comandos.ref(c, alvo)})
		return
	_enviar(cena, "encerrar_turno")


func _jogar_investigacao(cena: Node) -> void:
	var inv: CenaInvestigacao = cena.cena
	_investigou = true
	if inv.encerrada:
		if papel == "host":
			_enviar(cena, "sair")
		return
	var a := inv.agente_atual()
	if a != null and jogo.controles().e_local(a):
		_enviar(cena, "passar")


func _diagnostico() -> void:
	var cena := get_tree().current_scene
	var se: Sessao = jogo.sessao
	print("ROBO %s DIAG cena=%s modo=%s contexto=%s seq=%d ocupado=%s fila=%s pedidos=%d" % [papel, cena.scene_file_path if cena else "-", se.modo, se.contexto, se.seq, se.ocupado,
		se._recebidos.map(func(e): return "%d:%s/%s" % [int(e.seq), e.ctx, e.acao]).slice(0, 5), se._pedidos.size()])
	var m: Missao = jogo.missao
	if m != null:
		var a := m.agente_atual()
		print("ROBO %s DIAG missao encerrada=%s vez=%s local=%s rolado=%s mov=%d evento=%s encontro=%s inv=%s" % [papel, m.encerrada, a.nome if a else "-", jogo.controles().e_local(a) if a else "-",
			m.movimento_rolado, m.movimento_restante, not m.evento_pendente.is_empty(), not m.encontro_pendente.is_empty(), not m.investigacao_pendente.is_empty()])
	if cena != null and cena.scene_file_path == "res://scenes/arena_teste.tscn":
		var f: FluxoCombate = cena.fluxo
		var d := f.decisor()
		print("ROBO %s DIAG combate encerrado=%s vez=%s decisor=%s turnos=%d" % [papel, f.combate.encerrado, f.combate.ser_atual().nome if f.combate.ser_atual() else "-", d.nome if d else "-", f.turnos])
	if cena != null and cena.scene_file_path == "res://scenes/investigacao.tscn":
		var inv: CenaInvestigacao = cena.cena
		print("ROBO %s DIAG investigacao encerrada=%s vez=%s" % [papel, inv.encerrada, inv.agente_atual().nome if inv.agente_atual() else "-"])
	print("ROBO %s DIAG donos=%s meu_peer=%d" % [papel, jogo.controles().para_dicionario(), jogo.controles().meu_peer])


func _terminar() -> void:
	_terminou = true
	await get_tree().create_timer(1.0 * Engine.time_scale).timeout
	jogo.rede.encerrar()
	get_tree().quit()
